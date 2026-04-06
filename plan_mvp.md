# MVP Plan — Teach The World Foundation Dashboard
> Created: 2026-03-31
> Based on: DB v2 schema + Estimation Excel + UI mockups

---

## What is MVP?

The system's core purpose is:
1. Register schools, devices, and students across a geographic hierarchy
2. Track student attendance and learning sessions from tablets
3. Manage users and roles for admin access

MVP = minimum set of features for the system to **actually run in the field** — schools registered, students enrolled, devices syncing, attendance recording.

---

## MVP Scope

### IN — Must Ship

| # | Module | Reason | Effort |
|---|--------|--------|--------|
| 1 | **Auth (Email Login)** | Can't use system without login | Low — small change from username→email |
| 2 | **Geo Hierarchy** | Everything else (schools, users, filters) depends on this | Medium — City removal is breaking change |
| 3 | **Role Management** | Needed before creating any users | Low — mostly done |
| 4 | **User Management** | Admin users must exist to operate system | Medium — city refs to remove |
| 5 | **School Management** | Core entity — devices/students hang off schools | Medium — new fields + working days |
| 6 | **Device Management** | Tablets need to be registered before sync | Low — mostly done |
| 7 | **Shift Management** | Needed to create student profiles | Low — mostly done |
| 8 | **Profile Management** | student_profiles (device × shift) needed for student enrollment | Low — model change |
| 9 | **Student Management** | Core entity — no students = no attendance data | Medium — new fields |
| 10 | **Attendance Listing** | View attendance records from device sync | Medium |
| 11 | **Donor Management** | Needed to link projects → schools | Low — mostly done |
| 12 | **Project Management** | Schools are assigned to projects | Low — mostly done |

### OUT — Defer to v1.1

| Module | Why Deferred |
|--------|-------------|
| Holidays Management | New feature, complex (calendar + entries), not blocking core flow |
| Hybrid Hierarchy (Regions) | Complex M2M logic, not required for basic school/student ops |
| Logs Management (IT Support) | Nice to have, not blocking anything |
| Dashboard Changes | Enhancement — basic dashboard already exists |
| Mobile App changes | Separate track, after web portal stable |

---

## MVP Module Breakdown

### 1. Auth — Email Login
**Change**: `authflow` → login with `email` field instead of `username`
- Backend: Override `CustomTokenObtainPairView` to authenticate by email
- Frontend: Login form label/field stays same, just payload changes
- **Deliverable**: User can log in with email + password

---

### 2. Geo Hierarchy
**Change**: Remove City, restructure to Country→Province→District→Area→Cluster

**Backend (`geo_hierarchy` app):**
- Delete `City` model
- `District` now FKs to `Province` (not City)
- `Area` FKs to `District` (unchanged logic, just parent changes)
- Update serializers, views, URLs
- New `Region` model uses `region_members` table (level + ref_id)

**Frontend:**
- Remove City dropdown from all hierarchy selectors
- Update cascading dropdowns: Province → District (was Province → City → District)
- Update Redux `geoHierarchy` slice (remove cities)
- Affected pages: Hierarchy Management, School create/edit, User create/edit, all filter panels

**Deliverable**: 5-level hierarchy CRUD works, no City references anywhere

---

### 3. Role Management
**Change**: Minimal — mostly works already
- Verify `system_modules` table matches new modules (add Holidays, Logs entries)
- No structural change needed

**Deliverable**: Roles with permissions grid work as-is

---

### 4. User Management
**Change**: Remove City, add `flag_sync_allow`

**Backend (`user_management` app):**
- Remove `primary_city`, `access_cities` fields from `UserProfile`
- Remove `CityUser` pivot model and `user_city_access` table
- Add `flag_sync_allow` boolean field
- Update serializers

**Frontend:**
- Remove City from primary assignment dropdowns
- Remove City from regional access multi-select
- Add `flag_sync_allow` toggle on user form

**Deliverable**: Create/edit users with correct 5-level hierarchy assignment

---

### 5. School Management
**Changes**: Many new fields, dynamic school types, working days

**Backend (`school_management` app):**
- Update `School` model: remove `city`, add `school_id`, `sef_code`, `launch_date`, `closure_date`, `google_map_url`, `latitude`, `longitude`, `district_id`, `region_id`
- Change `type` from choices → FK to `SchoolType` model (new)
- Add `SchoolWorkingDay` model (new)
- Update serializers and views

**Frontend:**
- Remove City from school form hierarchy selector
- Add new fields: SEF code, launch/closure dates, Google map URL, lat/lng
- Add Working Days section (checkboxes: Mon–Sat)
- School type dropdown now loaded from API

**Deliverable**: Full school CRUD with new schema

---

### 6. Device Management
**Change**: Minimal — mostly works
- Verify device model aligns with v2 schema (tablet_id, otp fields)
- `sync_status` field validation

**Deliverable**: Device registration + OTP generation works

---

### 7. Shift Management
**Change**: None structural — works as-is
- Verify school-bound shifts still work post-school model changes

**Deliverable**: Shifts CRUD per school

---

### 8. Profile Management
**Change**: `student_profiles` is now devices × shifts cartesian product (auto-generated)
- Backend: Auto-create profiles when device+shift combination is set up
- Remove manual profile creation (was manual before)
- Update `Profile` model → `StudentProfile` with `device_id` + `shift_id` unique constraint

**Deliverable**: Profiles auto-created per device-shift pair

---

### 9. Student Management
**Changes**: New fields, link to student_profiles

**Backend:**
- Add `student_uid` (auto-gen), `profile_image`, `date_of_birth`, `reason_for_inactive`
- `profile_id` FK now points to `student_profiles`
- Update serializers

**Frontend:**
- Add DOB picker, profile image upload
- Add reason_for_inactive dropdown (shown only when status = inactive)
- Students listing: add **Shift** and **Assigned Device** columns

**Deliverable**: Full student CRUD + updated listing

---

### 10. Attendance Listing
**Change**: New `attendance_sessions` model (replaces old Session-based)
- Backend: New model with `student_id`, `profile_id`, `login_time`, `logout_time`, `date`
- `time_spent` calculated on-the-fly (logout - login)
- Remove old `logs_management` Session/SubjectLog models
- Frontend: Attendance page reads from new endpoint

**Deliverable**: Attendance records visible, filterable by date/school/student

---

### 11. Donor Management
**Change**: None — already works
- Verify `donor_name` field name matches v2 (`name` vs `donor_name`)

**Deliverable**: Donor CRUD works

---

### 12. Project Management
**Change**: None structural
- Verify `project_id` auto-gen format matches v2

**Deliverable**: Project CRUD + donor linking works

---

## MVP Definition of Done

- [ ] User can log in with email
- [ ] Geo hierarchy (5 levels, no City) fully manageable
- [ ] Roles and permissions configurable
- [ ] Users creatable with hierarchy assignment
- [ ] Schools creatable with new fields + working days
- [ ] Devices registered and OTP generated
- [ ] Shifts manageable per school
- [ ] Student profiles auto-created from device+shift
- [ ] Students creatable with all new fields
- [ ] Attendance sessions visible in listing
- [ ] Donors and Projects manageable
- [ ] No City references anywhere in UI or backend

---

## What Comes After MVP (v1.1)

1. **Holidays Management** — Calendar + entries CRUD with hierarchy assignment
2. **Hybrid Hierarchy (Regions)** — Custom M2M region grouping
3. **IT Support Logs** — device_logs read-only view
4. **Dashboard Refresh** — Updated stat cards + charts for new schema
5. **Mobile App** — Fixes, shifts listing, user sync, guest login

---

## Estimated Module Order for MVP

```
Week 1:  Auth (email) → Geo Hierarchy → Role Management
Week 2:  User Management → Donor + Project Management
Week 3:  School Management → Device + Shift + Profile Management
Week 4:  Student Management → Attendance Listing
Week 5:  Integration testing + staging deploy
```
