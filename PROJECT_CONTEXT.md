# Teach The World Foundation — Project Context
> Last Updated: 2026-03-31
> Status: **Context building done. Code not started yet.**

---

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Backend | Django + DRF | 4.1.4 / 3.14.0 |
| Auth | SimpleJWT | 5.2.2 |
| Frontend | React + Redux Toolkit | 18.2.0 / 1.9.1 |
| Styling | Tailwind CSS | 3.2.4 |
| HTTP | Axios | 1.2.1 |
| Forms | Formik + Yup | 2.2.9 |
| Database | PostgreSQL (prod) / SQLite (dev) | — |
| Task Queue | Celery + RabbitMQ | 5.2.7 |

---

## Folder Structure

```
eTeamGithub/
├── DjangoApp/              Backend (Django project: teach_the_world_dashboard)
├── ReactApp/               Frontend (React 18, Redux, Tailwind)
├── DB/
│   └── ttwf_final_schema_v2.sql   ← NEW TARGET SCHEMA (28 tables, finalized 31 Mar 2026)
├── UI-HTMLs/               New UI mockups (Tailwind) — reference for new features
├── Estimation/
│   └── Project Plan.xlsx   Implementation plan (step-by-step order)
└── PROJECT_CONTEXT.md      ← This file
```

---

## Django Apps (Current)

| App | Purpose |
|-----|---------|
| `authflow` | JWT login/logout/refresh/blacklist |
| `school_management` | Schools, Students, Devices, Shifts, Profiles, StudentActivities |
| `geo_hierarchy` | Country→Province→City→District→Area→Cluster + Region |
| `role_management` | Roles, SystemModules, ModulePermissions |
| `user_management` | UserProfile + 8 M2M regional access pivot tables |
| `donor_management` | Donors |
| `project_management` | Projects, ProjectDonors |
| `logs_management` | Sessions, SubjectLog, SubjectCompetency *(to be replaced)* |
| `competency_mapping` | LearningOutcome, Standard, Course, CourseDistribution *(defer decision)* |

---

## Key Architectural Decisions (Confirmed)

1. **DB Strategy**: Fresh start on PostgreSQL with `DB/ttwf_final_schema_v2.sql` — no old data migration
2. **Auth**: JWT stays same, but login changes from **username → email**
3. **logs_management app**: Old `Session/SubjectLog/SubjectCompetency` models will be **replaced** by new `attendance_sessions` table
4. **competency_mapping**: Decision deferred — assess when we reach school/student sections
5. **City Level**: **REMOVED** from geo hierarchy entirely

---

## BREAKING CHANGES vs Current Code (DB v2 vs Old Code)

### 1. Geo Hierarchy — City Removed
- **Old chain**: Country → Province → City → District → Area → Cluster (6 levels)
- **New chain**: Country → Province → District → Area → Cluster (5 levels)
- **Affected**: `geo_hierarchy` models, `user_management` (remove city FKs + `user_city_access` table), school models, all React hierarchy forms/dropdowns

### 2. New Tables (not in current Django)
| Table | Purpose |
|-------|---------|
| `school_types` | Dynamic school types (replaces hardcoded choices) |
| `school_working_days` | Which days school operates |
| `attendance_sessions` | Login/logout based attendance (replaces old sessions) |
| `holiday_calendars` | Holiday calendar entity |
| `holiday_entries` | Individual holiday entries per calendar |
| `device_logs` | IT Support login/logout/sync activity logs |
| `region_members` | M2M junction for Region (level + ref_id generic pointer) |
| `student_profiles` | Auto-generated devices × shifts cartesian product |

### 3. School Model Changes
- **Removed**: `city_id` FK
- **Added**: `school_id` (auto-gen), `sef_code`, `launch_date`, `closure_date`, `google_map_url`, `latitude`, `longitude`, `district_id` FK, `region_id` FK
- **Changed**: `type` (hardcoded choices → FK to `school_types`)
- **New related table**: `school_working_days`

### 4. Student Model Changes
- **Added**: `student_uid`, `profile_image`, `date_of_birth`, `reason_for_inactive` (7 choices: dropped_out/transferred/relocation/health/financial/completed/other)
- `profile_id` now FK to `student_profiles` (device+shift combo)

### 5. User Profile Changes
- **Removed**: `primary_city_id`, `user_city_access` pivot table
- **Added**: `flag_sync_allow` (boolean)
- **Renamed**: `mobile_number` → `mobile`

---

## Implementation Order (from Estimation/Project Plan.xlsx)

### Web Portal

| Step | Module | Key Notes |
|------|--------|-----------|
| 1 | DB Design + Auth Module | Email login, JWT stays same |
| 2 | Hierarchy Management | Country→Province→**District**→Area→Cluster (no City) |
| 3 | Role Management | Mostly done, minor changes |
| 4 | User Management | Remove city refs, add flag_sync_allow |
| — | *Staging Deploy* | |
| 5 | Donor Management | Mostly done |
| 6 | Projects Management | Mostly done |
| 7 | Holidays Management | NEW: holiday_calendars + holiday_entries, full CRUD |
| 8 | Hybrid Hierarchy (Regions) | Custom M2M via region_members table (NOT FK chain) |
| 9 | School Management | school_types, working_days, lat/lng, sef_code |
| 10 | Device Management | Mostly done |
| 11 | Profile Management | student_profiles = devices × shifts |
| 12 | Shift Management | Mostly done |
| — | *Staging Deploy* | |
| 13 | Student Management | student_uid, DOB, profile_image, reason_for_inactive |
| 14 | Attendance Listing | attendance_sessions based |
| — | *Testing + Bugs* | |
| 15 | Logs Management | IT Support device_logs (Activity/Change/Error logs) |
| 16 | Dashboard Changes | Stats/charts update |

### Mobile Application (after Web Portal)
1. Fixes and Changes
2. Shifts listing
3. User Sync Functionality
4. Guest login for student

---

## New Frontend Pages Needed

| Route | Page | Status |
|-------|------|--------|
| `/holidays` | Holidays listing with hierarchy filters | Not built |
| `/holidays/create` | Create holiday calendar + add rows | Not built |
| `/holidays/edit/:id` | Edit holiday | Not built |
| `/logs` | IT Support Logs (read-only) | Not built |

## Existing Frontend Pages Needing Updates

| Page | Change Needed |
|------|--------------|
| Hierarchy forms | Remove City dropdown, update District to be under Province |
| School creation/edit | Remove city field, add working days, sef_code, lat/lng |
| User create/edit | Remove city primary/access fields |
| Students listing | Add Shift + Assigned Device columns |
| Students creation | Add DOB, profile_image, reason_for_inactive |
| Sidebar/nav | Add Holidays and Logs menu items |

---

## UI Mockup Files (UI-HTMLs/)

| File | Covers |
|------|--------|
| `holidays.html` | Holidays listing page |
| `create-holiday.html` | Create holiday form (dynamic rows) |
| `logs.html` | IT Support Logs page |
| `students.html` | Updated students listing (Shift + Device columns) |
| `students-creation.html` | Updated student form |
| `school-creation.html` | Updated school form |
| `hierarchy-management.html` | Country/Province/District/Area/Cluster (no City) |
| `create-new-user.html` | Updated user form |
| All others | Reference for styling updates |

---

## Where We Left Off

**Date**: 2026-03-31
**Status**: Context/planning phase complete. **Code not started yet.**
**Next Step**: Start from Step 1 — DB schema implementation + Auth email login change.

When resuming, read this file first, then check git log for any commits made.
