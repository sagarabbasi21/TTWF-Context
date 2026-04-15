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
