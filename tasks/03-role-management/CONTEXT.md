# Role Management Module — Full Context
> Last Updated: 2026-04-13

## Overview
Role management with CRUD, permission grid, maker-checker approval workflow (with full request history tracking), and Excel export.

## Backend Files
- `Backend/role_management/models.py` — Role, SystemModule, ModulePermission, RoleRequest models
- `Backend/role_management/views.py` — RoleViewSet, RoleRequestViewSet, SystemModuleViewSet
- `Backend/role_management/serializers.py` — List/Detail/Approval/Request serializers
- `Backend/role_management/tasks.py` — Celery task: notify_checkers_role_created
- `Backend/role_management/urls.py` — registers /roles/, /roles/modules/, /roles/requests/

## Frontend Files
- `Frontend/src/pages/Roles.jsx` — Listing with tabs (Roles / Approval Queue)
- `Frontend/src/pages/CreateRole.jsx` — Create role form, sticky bar
- `Frontend/src/pages/EditRole.jsx` — Edit role, pre-fills form from pending request payload when exists
- `Frontend/src/pages/ReviewRole.jsx` — Checker approval page with diff view (current vs pending)
- `Frontend/src/components/RoleForm/PermissionGrid.jsx` — Reusable permission grid with Excel export
- `Frontend/src/store/roles/` — Redux slice + fetchRoles thunk

## Models

### Role
- name (unique, max 100)
- description (max 500)
- approval_status (pending/approved/rejected, default pending) — reflects latest request state
- approved_by (FK User, nullable)
- is_active
- module_permissions (M2M via ModulePermission) — active/approved permissions only
- Indexes: approval_status, created_by, -updated_at, (approval_status, created_by)

### RoleRequest (NEW)
Each create/update action creates a separate request entry:
- role (FK Role)
- action_type (create/update)
- payload (JSON: { name, description, module_permissions: [...] })
- status (pending/approved/rejected, default pending)
- approved_by (FK User, nullable)
- remarks (reason for approval/rejection)
- created_by / updated_by (from TimestampedModel)
- Indexes: (role, status), (status, -created_at), created_by

### ModulePermission
Pivot: (role, module) unique. Flags: can_view, can_add, can_edit, can_delete.

## Key Behaviors

### Maker-Checker Workflow
- **Maker** = user with Roles module `can_add` permission
- **Checker** = user with Role Checker special permission + Roles `can_view` (auto-linked)
- **Role Maker** special permission is LEGACY — kept in seed as inactive (is_active=False)

### Create Flow
1. Maker submits POST /roles/ with name, description, module_permissions
2. Role row created (approval_status=pending, no module_permissions yet)
3. RoleRequest(action=create, payload={...}, status=pending) created
4. Checker notification email sent via Celery
5. On approve: payload applied to Role (name, desc, bulk_create perms). Role.approval_status=approved. RoleRequest.status=approved.
6. On reject: Role.approval_status=rejected (unusable). RoleRequest.status=rejected.

### Update Flow (approved role)
1. Maker submits PUT /roles/{id}/ with new values
2. Backend checks: if any pending RoleRequest exists → 400 error "pending approval exists"
3. Else: RoleRequest(action=update, payload={...}, status=pending) created
4. Role.approval_status=pending BUT module_permissions UNCHANGED (previous approved state still active)
5. On approve: payload applied to Role. Role.approval_status=approved.
6. On reject: Role.approval_status goes back to approved (previous state valid). RoleRequest.status=rejected.

### Self-Approval Prevention
- `RoleRequest.created_by != request.user` check in approve/reject
- Creator (maker) OR updater (checker-with-maker-rights who edited) cannot approve their own request

### Tab Visibility (Roles.jsx)
- **Viewer only** (`can_view` only): no tabs, approved roles only, no create/edit/delete
- **Maker only** (`can_add`): no tabs, all roles with status badges, create+edit+delete enabled
- **Checker only** (`role_checker`): two tabs — Roles (approved) + Approval Queue (pending+rejected, NOT created/updated by self)
- **Both**: two tabs — Roles (all + own pending/rejected) + Approval Queue (others' requests only)

### Permission Auto-linking (PermissionGrid)
- Role Checker ON → Roles `can_view` auto-ON
- Roles `can_view` OFF → Role Checker auto-OFF
- Role Maker special permission is inactive; `can_add` on Roles module is the maker flag

### API Endpoints

**Role management:**
- `GET /api/v1/roles/` — list (paginated, search, ordering)
- `GET /api/v1/roles/?queue=true` — approval queue (roles with pending requests not created by current user)
- `POST /api/v1/roles/` — create (creates Role + RoleRequest)
- `GET /api/v1/roles/{id}/` — detail (includes `latest_request` object)
- `PUT /api/v1/roles/{id}/` — update (creates new RoleRequest, blocks if pending exists)
- `DELETE /api/v1/roles/{id}/` — soft delete (blocks if assigned to users)
- `POST /api/v1/roles/{id}/approve/` — approve latest pending request (backward-compat)
- `POST /api/v1/roles/{id}/reject/` — reject latest pending request with reason (backward-compat)
- `GET /api/v1/roles/modules/` — active system modules only

**Request management (new):**
- `GET /api/v1/roles/requests/` — list all role requests (filterable)
- `GET /api/v1/roles/requests/?queue=true` — pending requests not created by current user
- `GET /api/v1/roles/requests/?status=pending&role={id}` — filter
- `GET /api/v1/roles/requests/{id}/` — detail
- `POST /api/v1/roles/requests/{id}/approve/` — approve specific request
- `POST /api/v1/roles/requests/{id}/reject/` — reject specific request with reason

### Security
- `ModulePerm` permission class on RoleViewSet (checks roles module can_view/add/edit/delete per action)
- `IsRoleChecker` permission class on approve/reject actions
- Login response includes user permissions map
- Server-side validation enforces all rules

### Excel Export
- PermissionGrid has Excel button — exports all modules with View/Add/Edit/Delete columns
- Role name in first row + sheet tab name

### Seed Data
- Only one role: `System Admin` (full permissions on all modules)
- Legacy `role_maker` system module kept inactive (is_active=False)
- `role_checker` active
- Matching approved RoleRequest created for System Admin role (consistency with workflow)

## Migration Notes
When migrating production:
1. Create `role_requests` table
2. Remove `pending_data` and `remarks` columns from `roles`
3. Ensure existing approved roles have a matching RoleRequest(action=create, status=approved) for listing consistency (handled by seed for fresh DB; manual script needed for existing prod data)
4. Migration `0004_rolerequest_previous_payload.py` adds JSONField (nullable) — no data backfill needed.

## Changes — 2026-04-15 P1 batch
- **CHG-05** Pending-role edit allowed: `RoleSerializer.update` overwrites existing pending `RoleRequest.payload` instead of returning 400.
- **CHG-09** Request History: `RoleRequest.previous_payload` JSONField captures the approved state at submission. `GET /api/v1/roles/{id}/history/` returns approved+rejected requests (newest first). `Roles.jsx` has a third tab "Request History" for checkers.
- **CHG-01** Permission auto-link: `PermissionGrid.togglePerm` cascades add/edit/delete ⇒ view=true; view OFF ⇒ a/e/d=false. Role Checker toggle still auto-syncs with `roles.can_view`.
- **BUG-04 / BUG-17** Same cascade as CHG-01; backend `RoleSerializer.validate_module_permissions` rejects `role_checker.view && !roles.can_view`.
- **CHG-10 / BUG-24** `GET /roles/?approved_only=true` filter; `fetchRoles({approvedOnly:true})` used by `CreateUser`/`EditUser`.
