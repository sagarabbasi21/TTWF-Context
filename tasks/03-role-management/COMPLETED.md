# Role Management — All Completed Work
> Last Updated: 2026-04-10

## Phase 1 — Basic CRUD (2026-04-07)
- Sticky Save/Cancel on Create/Edit pages
- PageHeader with icon, title, subtitle matching HTML mockups
- Backend search/sort on approval_status, approved_by, description
- Description tooltip (30 chars) on listing
- Capitalize backend errors
- Delete shows actual backend error
- Excel export with permissions
- Sorting on all columns
- Role Maker ↔ Add bidirectional toggle (later removed)

## Phase 2 — Maker-Checker Workflow (2026-04-09)
- Model: rejection_reason → remarks (generic), pending_data JSONField, default pending
- Views: create→pending, update→pending_data for approved, approve/reject endpoints
- Serializers: created_by_name, remarks, pending_data, RoleApprovalSerializer
- Login response includes user permissions map
- Frontend Roles.jsx: tabs based on permissions (viewer/maker/checker/both)
- ReviewRole.jsx: diff view (old vs new), approve/reject with remarks
- CreateRole/EditRole: notifications updated for pending workflow
- Email to checkers on role create via Celery
- Role Maker special permission removed, replaced by Roles can_add
- Seed: role_maker inactive, role_checker active
- HTML mockup: UI-HTMLs/roles-maker-checker.html with 4 scenarios

## Phase 3 — Performance & Security (2026-04-10)
- Server-side permission checks: ModulePerm on RoleViewSet, IsRoleChecker on approve/reject
- bulk_create + transaction.atomic on approve
- DB indexes: approval_status, created_by, updated_at
- SerializerMethodField → direct source= on serializers
- Modules cached in Redux (fetched once, reused across pages)
- SystemModuleViewSet filters by is_active=True only

## Phase 4 — role_requests Table + Approval Refactor (2026-04-13)
- NEW table `role_requests`: tracks every create/update request separately
  - Fields: role FK, action_type (create/update), payload JSON, status (pending/approved/rejected), created_by, approved_by, remarks
  - Indexes: (role, status), (status, -created_at), created_by
- Removed `pending_data` and `remarks` fields from Role model
- Create flow: POST /roles/ creates Role (approval_status=pending) + RoleRequest(action=create, payload, status=pending). Role.module_permissions empty until approved.
- Update flow: PUT /roles/{id}/ creates RoleRequest(action=update, payload, status=pending). Role fields unchanged. Blocked if another pending request exists.
- Approve: applies payload to Role (name, description, bulk_create permissions). Role.approval_status=approved. RoleRequest.status=approved.
- Reject: RoleRequest.status=rejected. If CREATE rejected → Role.approval_status=rejected. If UPDATE rejected → Role goes back to approved (previous state still valid).
- `request.user != request.created_by` check prevents self-approval (covers: maker who created, or checker with maker rights who updated).
- New endpoints:
  - `GET/POST /roles/requests/` — direct list of role requests
  - `POST /roles/requests/{id}/approve|reject/` — act on specific request
  - `POST /roles/{id}/approve|reject/` — backward-compatible, acts on latest pending request for that role
- Frontend ReviewRole: reads `role.latest_request.payload` for diff view, `latest_request.remarks` for history, `latest_request.created_by` for own-role check
- Frontend Roles listing: status column uses `latest_request_remarks` for rejection reason tooltip
- Frontend EditRole: pre-fills form from `latest_request.payload` when pending (newly-created roles show pending data in form)

## Phase 5 — Frontend Permission Visibility (2026-04-13)
- Roles listing: Create button hidden without `can_add`, DataTable actions respect `can_edit`/`can_delete`
- Permission auto-link: Role Checker ON → Roles `can_view` ON; Roles `can_view` OFF → Checker OFF
- Approval logic UI: "updated_by" also blocked from approving (maker/checker with maker rights can't approve own edits)
