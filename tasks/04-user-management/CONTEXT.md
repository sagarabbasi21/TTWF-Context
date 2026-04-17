# User Management Module — Full Context
> Last Updated: 2026-04-10

## Overview
User CRUD with cascading regional access permissions, profile management, password flow, and hierarchy-based filtering.

## Backend Files
- `Backend/user_management/models.py` — UserProfile (1:1 with auth_user), M2M pivot tables for access
- `Backend/user_management/views.py` — UserProfileViewSet with me/change-password/access-tree endpoints
- `Backend/user_management/serializers.py` — List/Detail serializers
- `Backend/user_management/admin.py` — Django admin config

## Frontend Files
- `Frontend/src/pages/Users.jsx` — Listing with hierarchy filters, profile pic, tick/cross status
- `Frontend/src/pages/CreateUser.jsx` — Create with password fields, Flag Sync, regional access
- `Frontend/src/pages/EditUser.jsx` — Edit with image preview, password change, regional access
- `Frontend/src/pages/MyProfile.jsx` — Logged-in user profile (limited edit)
- `Frontend/src/pages/ChangePassword.jsx` — Force password change on first login
- `Frontend/src/utils/helpers/userAccessHelpers.js` — Batch API calls for access tree

## Key Changes Made

### Primary Hierarchy REMOVED
- All `primary_country/province/district/region/area/cluster/school` fields removed from model
- Removed from serializers, views, admin, seed data
- `location_hierarchy_display` and `location_detail_display` properties removed
- Hierarchy Placement section removed from Create/Edit User pages

### City REMOVED
- City removed from entire hierarchy chain (geo schema change)
- Province → District directly (no City in between)
- Removed from filters, cascading access, API payloads, thunks

### Listing Page (Users.jsx)
- PageHeader with icon=manage_accounts, Create User button in own bar
- Columns: User ID (Email, font-mono), Full Name (with profile pic or initials), Designation, Role (plain text), Status (tick/cross icons), Created On, Last Login
- Status: check_circle (green) / cancel (red) icons
- Hierarchy filters: Country → Province → District → Region → Area → Cluster → School (4-col grid)
- Default sort: -updated_at

### Create/Edit User
- Sticky Cancel + Save/Update bar
- Password + Confirm Password fields (Create: required, Edit: optional)
- Profile Picture: themed upload button, 1MB max (frontend + backend validation)
- Flag Sync Allow toggle + OTP field (auto-generate 6-digit, refresh button)
- Regional Access: cascading checkbox columns with All toggle
- Right Sharing: searchable dropdown with 300ms debounce (replaces full user list)
- At least one access entity required (validation)
- FormData for upload (multipart/form-data)
- Username = full email (not email prefix)
- Backend errors: username error mapped to email field

### API Endpoints
- `GET /users/` — list (paginated, search, ordering, hierarchy filters via M2M access)
- `POST /users/` — create (password emailed via Celery, must_change_password=True)
- `GET /users/{id}/` — detail
- `PUT /users/{id}/` — update
- `DELETE /users/{id}/` — soft delete + deactivate auth_user
- `GET /users/me/` — current user profile (IsAuthenticated only)
- `PUT /users/me/` — update basic info (first_name, last_name, mobile, picture)
- `POST /users/change-password/` — change password, clears must_change_password
- `GET /users/{id}/access-tree/` — full access tree in ONE response (replaces 60+ calls)
- `GET /users/all-access-tree/` — ALL hierarchy grouped (replaces 7 separate API calls)

### Security
- ModulePerm permission class on ViewSet (users module)
- me/change-password exempt (IsAuthenticated only)
- no_page capped at 200 results
- Profile picture: 1MB max + allowed types (JPEG, PNG, GIF, WebP)
- Phone number unique constraint
- Password sent via email on creation (intentional, not a link)

### Performance
- access-tree endpoint: 1 API call replaces 60+ cascading calls
- all-access-tree endpoint: 1 API call replaces 7 separate calls
- DB indexes: status, role, updated_at, (status + created_at)
- user_code generation: Max aggregate (race condition fix)
- Hierarchy filter: M2M access-based (not primary hierarchy)
- .distinct() on M2M filtered queries

### Model Fields (UserProfile)
- user (1:1 FK to auth_user)
- user_code (auto-generated USR-XXXX)
- employee_id (unique)
- profile_picture (ImageField, upload_to='profile_pictures/')
- mobile_number (unique, max 15, regex validated)
- designation, gender, status (active/inactive)
- role (FK to Role, PROTECT)
- must_change_password (Boolean, default True)
- has_global_access (Boolean)
- M2M access: countries, provinces, districts, regions, areas, clusters, schools (via pivot tables)

### Login Flow
- Email-based auth (not username)
- last_login updated on successful login
- Permissions map returned in login response
- profile_picture URL returned in login response
- must_change_password check → redirect to /change_password
- Soft-deleted or inactive profiles blocked from login

### Header (PageHeader)
- Shows user profile picture or initials
- Shows user name from auth state
- Clickable → navigates to /my_profile
- Date memoized, React.memo wrapper

---

## Changes — 2026-04-15 (Manager discussion P1 batch)

### Validation & auth
- **CHG-03 / BUG-32** Access levels mandatory till cluster (school optional). `CreateUser.jsx` + `EditUser.jsx` + `UserDetailSerializer.validate` all enforce country → province → district → area → cluster when `has_global_access=false`. Global bypass intact.
- **CHG-04 / BUG-26** Email/mobile reusable after soft-delete. `UserProfile.soft_delete` renames `auth_user.username`, `auth_user.email` and `user_profile.mobile_number` with `__deleted_<timestamp>` suffix to clear hard unique constraints. Employee ID stays globally unique. `validate_email` / `validate_username` use `__iexact` against active users.
- **CHG-07** Shared password rules: `Backend/user_management/validators.py` + `Frontend/src/utils/helpers/passwordRules.js`. Wired in CreateUser, EditUser, MyProfile, ChangePassword (FE + BE).
- **BUG-06** Inactive/soft-deleted user login returns `inactive_account` code with message "User is inactive. Please contact administrator." Wrong password / missing email still returns `no_active_account`.
- **BUG-13** Duplicate-email error now says "A user with this email already exists." (mapped from username unique constraint).
- **BUG-27** `ChangePassword.jsx` surfaces `err.response.data.detail` containing "current password" on the current-password field.

### Permissions
- **BUG-23** `App.jsx` bootstrap: single `GET /users/me/` after hydration merges fresh permissions into Redux via `updateAuthUser`. No polling. Backend `/users/me/` now returns `permissions` + `must_change_password` alongside profile.
- **CHG-10 / BUG-24** Role dropdown filter: `fetchRoles({approvedOnly:true})` — backend accepts `?approved_only=true` on `/roles/`.
- **CHG-11** Partial M2M save: `_set_regional_access(scoped=True)` only mutates rows within LI's access scope. EU's extra access preserved. Super admin / has_global_access bypasses scope.

### Edit User performance & UX
- **BUG-30** EditUser with `has_global_access=True` auto-populates all hierarchy IDs + groups via `fetchAndSelectAll()` so every node renders checked.
- **BUG-31** EditUser `loadData` uses `loadUserAccess(userId)` batch endpoint instead of cascading per-level fetches (replaces ~60 API calls with 1).
- **BUG-18** `toggleAllForLevel` in CreateUser + EditUser now invokes per-item `toggleAcc*` so Select-All at province/district/area/cluster cascades fetch of child items.
- **BUG-09** Profile picture URL: `_absolute_picture_url` returns absolute URL only when host is not localhost (prevents baking "localhost" into URLs served to UAT frontend).

### MyProfile / Change Password
- **CHG-12** (not in this batch — P2) MyProfile change password fields still pending.
