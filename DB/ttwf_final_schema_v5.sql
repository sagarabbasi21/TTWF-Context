-- =============================================================================
-- TEACH THE WORLD FOUNDATION — Final PostgreSQL Schema v5
-- Finalized: 02 Apr 2026
-- Tables: 31
-- Changes from v4:
--   - country_id, province_id, district_id, region_id, area_id,
--     cluster_id, school_id removed from user_profiles
--   - django_rest_passwordreset_resetpasswordtoken added (reference only)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. GEOGRAPHIC HIERARCHY
-- Chain: geo_countries → geo_provinces → geo_districts → geo_areas → geo_clusters
-- geo_regions = Custom M2M grouping (NOT part of chain)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS geo_countries (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP WITH TIME ZONE,
    created_by  INTEGER,
    updated_by  INTEGER,
    deleted_by  INTEGER
);

CREATE TABLE IF NOT EXISTS geo_provinces (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    country_id  BIGINT NOT NULL REFERENCES geo_countries(id) ON DELETE CASCADE,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP WITH TIME ZONE,
    created_by  INTEGER,
    updated_by  INTEGER,
    deleted_by  INTEGER
);

CREATE TABLE IF NOT EXISTS geo_districts (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    province_id BIGINT NOT NULL REFERENCES geo_provinces(id) ON DELETE CASCADE,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP WITH TIME ZONE,
    created_by  INTEGER,
    updated_by  INTEGER,
    deleted_by  INTEGER
);

CREATE TABLE IF NOT EXISTS geo_areas (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    district_id BIGINT NOT NULL REFERENCES geo_districts(id) ON DELETE CASCADE,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP WITH TIME ZONE,
    created_by  INTEGER,
    updated_by  INTEGER,
    deleted_by  INTEGER
);

CREATE TABLE IF NOT EXISTS geo_clusters (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    area_id     BIGINT NOT NULL REFERENCES geo_areas(id) ON DELETE CASCADE,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP WITH TIME ZONE,
    created_by  INTEGER,
    updated_by  INTEGER,
    deleted_by  INTEGER
);

CREATE TABLE IF NOT EXISTS geo_regions (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP WITH TIME ZONE,
    created_by  INTEGER,
    updated_by  INTEGER,
    deleted_by  INTEGER
);

CREATE TABLE IF NOT EXISTS region_members (
    id          BIGSERIAL PRIMARY KEY,
    region_id   BIGINT NOT NULL REFERENCES geo_regions(id) ON DELETE CASCADE,
    level       VARCHAR(20) NOT NULL
                    CHECK (level IN ('country','province','district','area','cluster')),
    ref_id      BIGINT NOT NULL,
    UNIQUE (region_id, level, ref_id)
);


-- -----------------------------------------------------------------------------
-- 2. ROLES & PERMISSIONS
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS roles (
    id              BIGSERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT,
    approval_status VARCHAR(20) NOT NULL DEFAULT 'pending'
                        CHECK (approval_status IN ('pending','approved','rejected')),
    approved_by     INTEGER,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMP WITH TIME ZONE,
    created_by      INTEGER,
    updated_by      INTEGER,
    deleted_by      INTEGER
);

CREATE TABLE IF NOT EXISTS system_modules (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    code        VARCHAR(50) NOT NULL UNIQUE,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by  INTEGER,
    updated_by  INTEGER
);

CREATE TABLE IF NOT EXISTS module_permissions (
    id          BIGSERIAL PRIMARY KEY,
    role_id     BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    module_id   BIGINT NOT NULL REFERENCES system_modules(id) ON DELETE CASCADE,
    can_view    BOOLEAN NOT NULL DEFAULT FALSE,
    can_add     BOOLEAN NOT NULL DEFAULT FALSE,
    can_edit    BOOLEAN NOT NULL DEFAULT FALSE,
    can_delete  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by  INTEGER,
    updated_by  INTEGER,
    UNIQUE (role_id, module_id)
);


-- -----------------------------------------------------------------------------
-- 3. AUTH USER (Django default — skip if already exists)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS auth_users (
    id              SERIAL PRIMARY KEY,
    username        VARCHAR(150) NOT NULL UNIQUE,
    first_name      VARCHAR(150) NOT NULL DEFAULT '',
    last_name       VARCHAR(150) NOT NULL DEFAULT '',
    email           VARCHAR(254) NOT NULL DEFAULT '',
    password        VARCHAR(128) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    is_staff        BOOLEAN NOT NULL DEFAULT FALSE,
    is_superuser    BOOLEAN NOT NULL DEFAULT FALSE,
    last_login      TIMESTAMP WITH TIME ZONE,
    date_joined     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);


-- -----------------------------------------------------------------------------
-- 4. DJANGO PASSWORD RESET (Reference only — managed by Django package)
--    Package: django-rest-passwordreset
--    Do NOT manually create — Django migrations handle this
-- -----------------------------------------------------------------------------

-- CREATE TABLE IF NOT EXISTS django_rest_passwordreset_resetpasswordtoken (
--     id          SERIAL PRIMARY KEY,
--     key         VARCHAR(64) NOT NULL UNIQUE,
--     user_id     INTEGER NOT NULL REFERENCES auth_users(id) ON DELETE CASCADE,
--     created_at  TIMESTAMP WITH TIME ZONE NOT NULL,
--     ip_address  INET,
--     user_agent  VARCHAR(256) NOT NULL DEFAULT ''
-- );


-- -----------------------------------------------------------------------------
-- 5. USER PROFILES
-- Notes:
--   - Hierarchy IDs removed (country_id, province_id, district_id,
--     region_id, area_id, cluster_id, school_id)
--   - Primary location handled via user_*_accesses tables
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_profiles (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             INTEGER NOT NULL UNIQUE REFERENCES auth_users(id) ON DELETE CASCADE,
    employee_id         VARCHAR(50) UNIQUE,
    mobile              VARCHAR(20),
    designation         VARCHAR(150),
    gender              VARCHAR(10) CHECK (gender IN ('male','female','other')),
    profile_picture     VARCHAR(500),
    role_id             BIGINT REFERENCES roles(id) ON DELETE SET NULL,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    sync_allow          BOOLEAN NOT NULL DEFAULT FALSE,
    grant_global_access BOOLEAN NOT NULL DEFAULT FALSE,
    otp                 VARCHAR(10),
    otp_created_at      TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMP WITH TIME ZONE,
    created_by          INTEGER,
    updated_by          INTEGER,
    deleted_by          INTEGER
);


-- -----------------------------------------------------------------------------
-- 6. USER REGIONAL ACCESS
-- Rows only inserted when grant_global_access = FALSE
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_country_accesses (
    id          BIGSERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES auth_users(id) ON DELETE CASCADE,
    country_id  BIGINT NOT NULL REFERENCES geo_countries(id) ON DELETE CASCADE,
    UNIQUE (user_id, country_id)
);

CREATE TABLE IF NOT EXISTS user_province_accesses (
    id          BIGSERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES auth_users(id) ON DELETE CASCADE,
    province_id BIGINT NOT NULL REFERENCES geo_provinces(id) ON DELETE CASCADE,
    UNIQUE (user_id, province_id)
);

CREATE TABLE IF NOT EXISTS user_district_accesses (
    id          BIGSERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES auth_users(id) ON DELETE CASCADE,
    district_id BIGINT NOT NULL REFERENCES geo_districts(id) ON DELETE CASCADE,
    UNIQUE (user_id, district_id)
);

CREATE TABLE IF NOT EXISTS user_region_accesses (
    id          BIGSERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES auth_users(id) ON DELETE CASCADE,
    region_id   BIGINT NOT NULL REFERENCES geo_regions(id) ON DELETE CASCADE,
    UNIQUE (user_id, region_id)
);

CREATE TABLE IF NOT EXISTS user_area_accesses (
    id          BIGSERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES auth_users(id) ON DELETE CASCADE,
    area_id     BIGINT NOT NULL REFERENCES geo_areas(id) ON DELETE CASCADE,
    UNIQUE (user_id, area_id)
);

CREATE TABLE IF NOT EXISTS user_cluster_accesses (
    id          BIGSERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES auth_users(id) ON DELETE CASCADE,
    cluster_id  BIGINT NOT NULL REFERENCES geo_clusters(id) ON DELETE CASCADE,
    UNIQUE (user_id, cluster_id)
);

CREATE TABLE IF NOT EXISTS user_school_accesses (
    id          BIGSERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES auth_users(id) ON DELETE CASCADE,
    school_id   BIGINT NOT NULL,
    UNIQUE (user_id, school_id)
);


-- -----------------------------------------------------------------------------
-- 7. DONORS & PROJECTS
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS donors (
    id               BIGSERIAL PRIMARY KEY,
    name             VARCHAR(200) NOT NULL,
    type             VARCHAR(50)
                         CHECK (type IN ('Individual','Corporate','NGO','Organization')),
    email            VARCHAR(254),
    mobile           VARCHAR(20),
    physical_address TEXT,
    description      TEXT,
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at       TIMESTAMP WITH TIME ZONE,
    created_by       INTEGER,
    updated_by       INTEGER,
    deleted_by       INTEGER
);

CREATE TABLE IF NOT EXISTS projects (
    id           BIGSERIAL PRIMARY KEY,
    project_code VARCHAR(50) NOT NULL UNIQUE,
    name         VARCHAR(200) NOT NULL,
    status       VARCHAR(30) NOT NULL DEFAULT 'active',
    start_date   DATE NOT NULL,
    end_date     DATE,
    description  TEXT,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMP WITH TIME ZONE,
    created_by   INTEGER,
    updated_by   INTEGER,
    deleted_by   INTEGER
);

CREATE TABLE IF NOT EXISTS project_donors (
    id          BIGSERIAL PRIMARY KEY,
    project_id  BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    donor_id    BIGINT NOT NULL REFERENCES donors(id) ON DELETE CASCADE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (project_id, donor_id)
);


-- -----------------------------------------------------------------------------
-- 8. SCHOOL TYPES (dynamic)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS school_types (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP WITH TIME ZONE,
    created_by  INTEGER,
    updated_by  INTEGER,
    deleted_by  INTEGER
);


-- -----------------------------------------------------------------------------
-- 9. SCHOOLS
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS schools (
    id              BIGSERIAL PRIMARY KEY,
    school_code     VARCHAR(50) NOT NULL UNIQUE,
    name            TEXT NOT NULL,
    school_type_id  BIGINT REFERENCES school_types(id) ON DELETE SET NULL,
    sef_code        VARCHAR(50),
    status          VARCHAR(20) NOT NULL DEFAULT 'active',
    launch_date     DATE,
    closure_date    DATE,
    google_map_url  VARCHAR(500),
    latitude        NUMERIC(9,7),
    longitude       NUMERIC(9,7),
    country_id      BIGINT REFERENCES geo_countries(id)  ON DELETE SET NULL,
    province_id     BIGINT REFERENCES geo_provinces(id)  ON DELETE SET NULL,
    district_id     BIGINT REFERENCES geo_districts(id)  ON DELETE SET NULL,
    region_id       BIGINT REFERENCES geo_regions(id)    ON DELETE SET NULL,
    area_id         BIGINT REFERENCES geo_areas(id)      ON DELETE SET NULL,
    cluster_id      BIGINT REFERENCES geo_clusters(id)   ON DELETE SET NULL,
    project_id      BIGINT REFERENCES projects(id)       ON DELETE SET NULL,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMP WITH TIME ZONE,
    created_by      INTEGER,
    updated_by      INTEGER,
    deleted_by      INTEGER
);

ALTER TABLE user_school_accesses
    ADD CONSTRAINT fk_user_school_accesses_school
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;

CREATE TABLE IF NOT EXISTS school_working_days (
    id          BIGSERIAL PRIMARY KEY,
    school_id   BIGINT NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    day_name    VARCHAR(10) NOT NULL
                    CHECK (day_name IN ('monday','tuesday','wednesday','thursday','friday','saturday','sunday')),
    is_working  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (school_id, day_name)
);


-- -----------------------------------------------------------------------------
-- 10. SHIFTS & DEVICES
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS shifts (
    id          BIGSERIAL PRIMARY KEY,
    school_id   BIGINT NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name        VARCHAR(100) NOT NULL,
    start_time  TIME NOT NULL,
    end_time    TIME NOT NULL,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP WITH TIME ZONE,
    created_by  INTEGER,
    updated_by  INTEGER,
    deleted_by  INTEGER
);

CREATE TABLE IF NOT EXISTS devices (
    id              BIGSERIAL PRIMARY KEY,
    school_id       BIGINT NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    tablet_id       VARCHAR(50),
    otp             VARCHAR(10),
    otp_created_at  TIMESTAMP WITH TIME ZONE,
    last_sync_at    TIMESTAMP WITH TIME ZONE,
    sync_status     VARCHAR(20) DEFAULT 'pending'
                        CHECK (sync_status IN ('synced','pending','failed')),
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMP WITH TIME ZONE,
    created_by      INTEGER,
    updated_by      INTEGER,
    deleted_by      INTEGER
);

CREATE TABLE IF NOT EXISTS student_profiles (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    password    VARCHAR(4) NOT NULL,
    device_id   BIGINT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    shift_id    BIGINT NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by  INTEGER,
    updated_by  INTEGER,
    UNIQUE (device_id, shift_id)
);


-- -----------------------------------------------------------------------------
-- 11. STUDENTS
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS students (
    id                  BIGSERIAL PRIMARY KEY,
    student_uid         VARCHAR(50) NOT NULL UNIQUE,
    name                TEXT NOT NULL,
    profile_image       VARCHAR(500),
    date_of_birth       DATE,
    admission_date      DATE,
    gender              VARCHAR(10) CHECK (gender IN ('male','female','other')),
    status              VARCHAR(20) NOT NULL DEFAULT 'active'
                            CHECK (status IN ('active','inactive')),
    reason_for_inactive VARCHAR(50)
                            CHECK (reason_for_inactive IN (
                                'dropped_out','transferred','relocation',
                                'health','financial','completed','other'
                            )),
    school_id           BIGINT REFERENCES schools(id) ON DELETE SET NULL,
    student_profile_id  BIGINT REFERENCES student_profiles(id) ON DELETE SET NULL,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMP WITH TIME ZONE,
    created_by          INTEGER,
    updated_by          INTEGER,
    deleted_by          INTEGER
);


-- -----------------------------------------------------------------------------
-- 12. ATTENDANCE SESSIONS
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS attendance_sessions (
    id                  BIGSERIAL PRIMARY KEY,
    student_id          BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    student_profile_id  BIGINT NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    login_time          TIMESTAMP WITH TIME ZONE NOT NULL,
    logout_time         TIMESTAMP WITH TIME ZONE,
    date                DATE NOT NULL,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);


-- -----------------------------------------------------------------------------
-- 13. HOLIDAY CALENDARS
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS holiday_calendars (
    id              BIGSERIAL PRIMARY KEY,
    name            VARCHAR(200) NOT NULL,
    assigned_level  VARCHAR(20)
                        CHECK (assigned_level IN ('country','province','district','region','area','cluster','school')),
    ref_id          BIGINT,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMP WITH TIME ZONE,
    created_by      INTEGER,
    updated_by      INTEGER,
    deleted_by      INTEGER
);

CREATE TABLE IF NOT EXISTS holiday_entries (
    id           BIGSERIAL PRIMARY KEY,
    calendar_id  BIGINT NOT NULL REFERENCES holiday_calendars(id) ON DELETE CASCADE,
    name         VARCHAR(200) NOT NULL,
    start_date   DATE NOT NULL,
    end_date     DATE NOT NULL,
    no_of_days   INTEGER NOT NULL DEFAULT 1,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by   INTEGER,
    updated_by   INTEGER
);


-- -----------------------------------------------------------------------------
-- 14. DEVICE LOGS
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS device_logs (
    id              BIGSERIAL PRIMARY KEY,
    device_id       BIGINT REFERENCES devices(id) ON DELETE SET NULL,
    school_id       BIGINT REFERENCES schools(id) ON DELETE SET NULL,
    user_id         INTEGER REFERENCES auth_users(id) ON DELETE SET NULL,
    activity_type   VARCHAR(20)
                        CHECK (activity_type IN ('login','logout','sync','failed_sync')),
    sync_status     VARCHAR(20),
    log_datetime    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);


-- -----------------------------------------------------------------------------
-- 15. USER VISITS LOG
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_visits (
    id          BIGSERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES auth_users(id) ON DELETE SET NULL,
    url         VARCHAR(500),
    action      VARCHAR(20) NOT NULL
                    CHECK (action IN ('login','logout','click','search','filter','download')),
    element     VARCHAR(200),
    ip_address  INET,
    user_agent  TEXT,
    visited_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);


-- -----------------------------------------------------------------------------
-- 16. OPERATION LOGS (Audit trail)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS operation_logs (
    id              BIGSERIAL PRIMARY KEY,
    user_id         INTEGER REFERENCES auth_users(id) ON DELETE SET NULL,
    table_name      VARCHAR(100) NOT NULL,
    record_id       BIGINT NOT NULL,
    action          VARCHAR(10) NOT NULL
                        CHECK (action IN ('create','update','delete')),
    previous_data   JSONB,
    new_data        JSONB,
    operated_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);


-- -----------------------------------------------------------------------------
-- INDEXES
-- -----------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_geo_provinces_country     ON geo_provinces(country_id);
CREATE INDEX IF NOT EXISTS idx_geo_districts_province    ON geo_districts(province_id);
CREATE INDEX IF NOT EXISTS idx_geo_areas_district        ON geo_areas(district_id);
CREATE INDEX IF NOT EXISTS idx_geo_clusters_area         ON geo_clusters(area_id);
CREATE INDEX IF NOT EXISTS idx_region_members_region     ON region_members(region_id);

CREATE INDEX IF NOT EXISTS idx_schools_cluster           ON schools(cluster_id);
CREATE INDEX IF NOT EXISTS idx_schools_project           ON schools(project_id);
CREATE INDEX IF NOT EXISTS idx_schools_school_type       ON schools(school_type_id);

CREATE INDEX IF NOT EXISTS idx_shifts_school             ON shifts(school_id);
CREATE INDEX IF NOT EXISTS idx_devices_school            ON devices(school_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_device   ON student_profiles(device_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_shift    ON student_profiles(shift_id);

CREATE INDEX IF NOT EXISTS idx_students_school           ON students(school_id);
CREATE INDEX IF NOT EXISTS idx_students_uid              ON students(student_uid);
CREATE INDEX IF NOT EXISTS idx_students_profile          ON students(student_profile_id);

CREATE INDEX IF NOT EXISTS idx_attendance_student        ON attendance_sessions(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date           ON attendance_sessions(date);
CREATE INDEX IF NOT EXISTS idx_attendance_profile        ON attendance_sessions(student_profile_id);

CREATE INDEX IF NOT EXISTS idx_user_profiles_user        ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role        ON user_profiles(role_id);
CREATE INDEX IF NOT EXISTS idx_module_perms_role         ON module_permissions(role_id);

CREATE INDEX IF NOT EXISTS idx_device_logs_device        ON device_logs(device_id);
CREATE INDEX IF NOT EXISTS idx_device_logs_datetime      ON device_logs(log_datetime);
CREATE INDEX IF NOT EXISTS idx_holiday_entries_calendar  ON holiday_entries(calendar_id);

CREATE INDEX IF NOT EXISTS idx_user_visits_user          ON user_visits(user_id);
CREATE INDEX IF NOT EXISTS idx_user_visits_visited_at    ON user_visits(visited_at);

CREATE INDEX IF NOT EXISTS idx_operation_logs_table      ON operation_logs(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_operation_logs_user       ON operation_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_operation_logs_operated   ON operation_logs(operated_at);

-- =============================================================================
-- END OF SCHEMA — 30 Custom Tables + 1 Django Built-in Reference = 31 Total
-- NOTE: django_rest_passwordreset_resetpasswordtoken is managed by Django
--       migrations — do NOT manually create it
-- =============================================================================
