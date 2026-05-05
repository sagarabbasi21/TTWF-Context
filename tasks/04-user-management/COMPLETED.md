# User Management — All Completed Work
> Last Updated: 2026-04-10

## Phase 1 — Initial Changes (2026-04-07)
- PageHeader with icon, email as User ID, Created On + Last Login columns
- City filter removed, Province cascades to District
- Sticky Cancel + Save bar on Create/Edit
- Hierarchy Placement section removed
- City removed from Regional Access columns
- Flag Sync Allow + OTP added
- Capitalize backend errors
- FormData for image upload

## Phase 2 — Fixes & Enhancements (2026-04-08)
- Profile picture: MEDIA_URL/ROOT config, URL routing, 1MB validation (frontend + backend)
- Primary hierarchy fields removed from model/serializer/views/admin/seed
- Hierarchy filtering via M2M access (not primary)
- Login: email persists on error, password clears
- Password + Confirm Password fields on Create/Edit
- Username = full email
- Eye icon on password fields (TextBox component)
- Cancel disabled during save (all pages)
- Role Maker toggle fix (bidirectional, later removed)
- last_login: set via timezone.now() on login
- User avatar in header (picture or initials)
- Profile upload button themed
- Status: tick/cross icons
- Role badge: plain text matching designation
- Edit region: All checkbox
- Phone number unique

## Phase 3 — New Pages (2026-04-09)
- MyProfile page (/my_profile) — view + limited edit
- ChangePassword page (/change_password) — force on first login
- Backend: /users/me/ and /users/change-password/ endpoints
- must_change_password model field
- Password emailed on user creation via Celery
- Login redirects to change password if must_change_password=True
- Right Sharing: searchable with 300ms debounce

## Phase 4 — Performance & Security (2026-04-10)
- Server-side ModulePerm on UserProfileViewSet
- me/change-password exempt (IsAuthenticated only)
- no_page capped at 200 results
- /users/{id}/access-tree/ — replaces 60+ cascading API calls
- /users/all-access-tree/ — replaces 7 separate API calls
- userAccessHelpers.js simplified to 2 functions using batch endpoints
- user_code race condition fix (Max aggregate)
- DB indexes on status, role, updated_at
- from_email fix for password notification

## Phase 5 — Critical Fixes (2026-04-13)
- Force password reset enforced globally via withAuth HOC (any route blocked except CHANGE_PASSWORD)
- Profile image updates reflected in header (dispatches updateAuthUser, persists to localStorage)
- Create User button hidden without can_add; DataTable edit/delete respect permissions
- Page refresh no longer flashes login (auth slice initialState hydrates from localStorage synchronously)
- MyProfile shows Access Level card: countries/provinces/districts/areas/clusters with counts (read-only)
- Auto-scroll to first validation error on submit (user forms)
- Regions now included in `/users/all-access-tree/` and `/users/{id}/access-tree/` grouped by district via RegionMember(level='district')
- Change password: fetches fresh User via get(pk=...) with save(update_fields=['password']) for atomic password-only update
- After password change: dispatches updateAuthUser({must_change_password: false}) + redirects to first accessible route

## Phase 6 — Seed Simplified (2026-04-13)
- Seed now creates ONLY Super Admin user (superadmin@ttwf.com / Admin@ttwf2026)
- Seed now creates ONLY System Admin role (full permissions)
- Removed m.ali, sarah.ahmed, usman.k users from seed
- Removed School Manager, Area Coordinator roles from seed
- Super Admin: is_superuser=True, is_staff=True, has_global_access=True, must_change_password=False
- Access M2M: all countries/provinces/districts/regions/areas/clusters granted to Super Admin
- Matching approved RoleRequest created for System Admin (workflow consistency)

## Phase 7 — Manager discussion P0/P1/P2 (2026-04-15)

### P0 (permissions + account integrity)
- **BUG-20 / BUG-21 / BUG-22 (TASK-063, TASK-064, TASK-065)** `withAuth.jsx` `ROUTE_MODULE_MAP` entries upgraded from strings to `{module, action}` tuples. Create routes require `can_add`, edit routes require `can_edit`. Holidays added to map. `Drawer.jsx` NAV item for Holidays gained `moduleCode: 'holidays'`. `Donors.jsx` Add button + DataTable `isEditable`/`isDeletable` bound to `authUser.permissions.donors`.
- **BUG-29 (TASK-067)** `UserProfile.soft_delete` now mirrors `user.is_active=False`. New `authflow.authentication.StrictJWTAuthentication` rejects soft-deleted users. Axios response interceptor clears tokens + redirects on 401 codes (`user_inactive|user_deleted|user_not_found`).

### P1 (validation + UX)
- **CHG-03 / BUG-32 (TASK-069 / TASK-090)** Access mandatory till cluster (school optional) unless `has_global_access`. `CreateUser.jsx`, `EditUser.jsx`, `UserDetailSerializer.validate` all enforce in order country → province → district → area → cluster.
- **CHG-04 / BUG-26 (TASK-070 / TASK-086)** Soft-delete renames auth_user.username, auth_user.email, user_profile.mobile_number with `__deleted_<timestamp>` suffix to free the values. Employee ID stays globally unique. `validate_email` / `validate_username` use `__iexact`.
- **CHG-07 (TASK-072)** Shared password rules — `Backend/user_management/validators.py` + `Frontend/src/utils/helpers/passwordRules.js`. Wired in CreateUser, EditUser, MyProfile, ChangePassword, `/users/change-password/`.
- **CHG-11 (TASK-076)** `_set_regional_access(scoped=True)` on Edit User — only mutates M2M rows within LI user's access scope. EU's extra access preserved. Super admin / `has_global_access` bypasses scope.
- **BUG-06 (TASK-078)** Distinct `inactive_account` login error for `is_active=False` / soft-deleted / `status!='active'`.
- **BUG-09 (TASK-079)** `_absolute_picture_url` returns absolute URL only when request host ≠ localhost.
- **BUG-13 (TASK-081)** Duplicate email error now reads "A user with this email already exists."
- **BUG-18 (TASK-083)** `toggleAllForLevel` in CreateUser + EditUser invokes per-item cascading toggle on Select-All so child columns populate.
- **BUG-23 (TASK-084)** App.jsx bootstrap: single `GET /users/me/` merges fresh permissions into Redux after token hydration. No polling.
- **BUG-27 (TASK-087)** ChangePassword maps backend `detail` containing "current password" to `fieldErrors.current_password`.
- **BUG-30 (TASK-088)** EditUser with `has_global_access=True` auto-populates all hierarchy IDs + groups via `fetchAndSelectAll()`.
- **BUG-31 (TASK-089)** EditUser `loadData` replaced cascading per-level fetches with single `loadUserAccess(userId)` batch call.

### P2 (UI polish + features)
- **CHG-06 (TASK-092)** Phone field strips non-digits, caps at 11 chars, regex `^03\d{9}$` on submit. Backend `phone_regex_validator` mirrors.
- **CHG-12 (TASK-093)** MyProfile optional new/confirm password fields. Backend `/users/me/` PUT accepts `new_password` with shared validator.
- **BUG-05 (TASK-095)** `Select` component label style unified with TextBox. Status / Flag Sync / Profile Picture / OTP / Right Sharing labels migrated in CreateUser + EditUser.
- **BUG-07 (TASK-096)** CascadingAccessColumn per-item row wrapped in `<label>` — native label semantics make text click toggle checkbox.
- **BUG-12 (TASK-098)** Profile picture uploader full-width (`bg-gray-50 border-gray-200 py-3`) matching TextBox height.
- **BUG-19 (TASK-100)** DataTable Actions `<th>` gained explicit `text-white`.
- **BUG-33 (TASK-102)** CreateUser + EditUser email regex check before submit.

### Pending migrations
- `user_management/0003_userprofile_must_change_password_and_more.py` (already applied in earlier phase)
- No new schema migrations this phase — soft-delete rename is row-level, no DDL changes.

## Phase 8 — UAT Round 2 fixes (2026-04-17)

### Security & Access
- **TASK-105** User listing filtered by LI user's cluster-level access. Non-global users only see users with overlapping clusters.
- **TASK-106** PasswordHistory model (db_table=password_history). `PASSWORD_HISTORY_COUNT=3` in settings. Blocks reuse of last N passwords on all change flows (change-password, MyProfile PUT, create user stores initial). Migration 0006 applied.
- **TASK-107** Unknown URLs redirect to first accessible route via catch-all `<Route path="*">` in React Router.

### Performance
- **TASK-110** New `/users/{id}/edit-context/` merged endpoint returns user detail + selected access + available hierarchy (scoped to LI user) + approved roles in ONE call. EditUser.jsx refactored to single API call on mount.
- **TASK-111** Roles page tabs lazy-loaded: Queue fetches on first tab click only, History already on-demand.

### Email & Notifications
- **TASK-108** User creation email includes dynamic login URL from `settings.SERVER_ADDR`.
- Role email tasks: `notify_checkers_role_created` excludes creator email; new `notify_checkers_role_updated` task sent on role update, excludes updater.

### UI Polish
- **TASK-103** MyProfile profile picture uploader unified with full-width pattern.
- **TASK-104** CreateRole/EditRole: `scrollToFirstError` added with field ID map.
- **TASK-109** Region access column deduplicates by region ID, shows member districts as sub-text.
- **TASK-112** Phone validation message: "Phone number must start with 03 and be exactly 11 digits" (FE + BE).
- **TASK-113** Select Role placeholder option disabled (not submittable).
- **TASK-114** DataTable `<th>` explicit `bg-primary` per cell to prevent white flash.
- **TASK-115** DeleteModal: description from Roles listing already stripped/truncated by existing fix.

### Hierarchy Edit
- Long country name: Select button label truncated, edit/delete buttons `shrink-0`.

### Pending migrations
- `user_management/0006_alter_userprofile_mobile_number_passwordhistory.py` — PasswordHistory table + mobile max_length=50.

## Phase 9 — Country master + Phone validation + District removal (2026-04-19)

### Model
- **CountryMaster** — new table `country_master` with `iso_code` (PK), `name`, `dial_code`, `flag`, `is_active`. Seeded with ~195 countries via `seed_countries` management command.
- **UserProfile.country** — nullable FK to CountryMaster. Set on user create/edit.
- **phone_regex_validator** relaxed to generic `^\+?[0-9]{7,20}$` — actual country-specific validation done at serializer level using `phonenumbers` library.
- **All migrations consolidated** — single `0001_initial.py` per app (some 0002 for circular FK).

### Backend
- **New endpoint:** `GET /api/v1/master/countries/` — returns all active countries (unpaginated).
- **`validate_phone_for_country(iso, phone)`** in `validators.py` uses `phonenumbers.parse(phone, iso)` + `is_valid_number()`.
- **UserDetailSerializer.validate()** calls phone validator with selected country's iso_code.
- **Libraries:** `phonenumbers==8.13.26` (Python), `react-phone-number-input` (npm — not actually used; custom country dropdown preferred per manager).
- **UserProfileViewSet.get_queryset**: district query param removed from user listing.
- **UserDetailSerializer**: `access_district_ids` field removed, district not in CHG-03 level check, `country_name` + `country_dial_code` read-only fields added.

### Frontend
- **CreateUser / EditUser** refactored:
  - Country dropdown (from `/master/countries/`) as first field in profile grid. Default `'PK'` on create; `user.country || 'PK'` on edit.
  - Country iso_code sent as `country` field in payload.
  - Phone regex check removed client-side (server validates).
  - District fully removed (state, handlers, column, payload).
  - Access grid: **Row 1** = Country/Province/Region/Area (4 cols), **Row 2** = Cluster/School (4-col grid, 2 populated).
  - Province cascade fetches regions + areas directly (`?province=X`, skipping district).
  - Shared `CascadingAccessColumn` + `deduplicateRegionGroups` imported from `components/AccessLevel` (inline duplicate removed from both files).
- **MyProfile Access Level card**: districts row replaced with regions.
- **userAccessHelpers.loadUserAccess + fetchAndSelectAll**: response no longer includes district groups/ids (backend dropped them).
