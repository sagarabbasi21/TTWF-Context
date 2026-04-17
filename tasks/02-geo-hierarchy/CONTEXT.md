# Geo Hierarchy Module — Context & Gap Analysis
> Created: 2026-04-02
> Status: Analysis complete. Implementation NOT started.

---

## Current Code vs New Schema (v5) — Summary

### Hierarchy Chain Change

```
OLD (6 levels): Country → Province → City → District → Area → Cluster
NEW (5 levels): Country → Province → District → Area → Cluster

City is COMPLETELY REMOVED.
```

### Region Change

```
OLD: Region has M2M fields → countries, provinces, cities, districts
NEW: Region uses region_members table with generic (level, ref_id) approach
     Supports: country, province, district, area, cluster (5 levels, no city)
```

### Table Name Changes

| Old (Django default)       | New (v5 schema)     |
|---------------------------|---------------------|
| geo_hierarchy_country     | geo_countries       |
| geo_hierarchy_province    | geo_provinces       |
| geo_hierarchy_city        | **REMOVED**         |
| geo_hierarchy_district    | geo_districts       |
| geo_hierarchy_area        | geo_areas           |
| geo_hierarchy_cluster     | geo_clusters        |
| geo_hierarchy_region      | geo_regions         |
| geo_hierarchy_region_countries (M2M) | **REMOVED** |
| geo_hierarchy_region_provinces (M2M) | **REMOVED** |
| geo_hierarchy_region_cities (M2M)    | **REMOVED** |
| geo_hierarchy_region_districts (M2M) | **REMOVED** |
| (did not exist)           | region_members      |

---

## Backend Changes Needed

### 1. Models (`geo_hierarchy/models.py`)

**DELETE:**
- `City` model entirely

**MODIFY:**
- `District`: Change FK from `city` → `province` (FK to Province)
- All models: Add `db_table` in Meta to match v5 names (geo_countries, geo_provinces, etc.)

**MODIFY Region:**
- Remove M2M fields (countries, provinces, cities, districts)
- Create `RegionMember` model with:
  - `region` FK to Region
  - `level` CharField with choices: country, province, district, area, cluster
  - `ref_id` BigIntegerField
  - Unique constraint on (region, level, ref_id)

**No new models needed** — Country, Province, District, Area, Cluster structure stays same (just re-parenting District).

### 2. Serializers (`geo_hierarchy/serializers.py`)

**DELETE:**
- `CityListSerializer`, `CityDetailSerializer`
- All city references in other serializers

**MODIFY:**
- `DistrictListSerializer/Detail`: Remove city fields, add province fields
- `AreaListSerializer/Detail`: Verify district reference (should be ok since Area→District unchanged)
- `RegionDetailSerializer`: Change from M2M fields to RegionMember-based serialization
  - Read: Return grouped members by level
  - Write: Accept members as list of {level, ref_id}
- `HierarchyFlatSerializer`: Remove city_name/city_id fields

### 3. Views (`geo_hierarchy/views.py`)

**DELETE:**
- `CityViewSet` entirely

**MODIFY:**
- `DistrictViewSet`: Filter by `?province=X` instead of `?city=X`
- `RegionViewSet`: Update filters for new region_members structure
- `HierarchyFlatView`: Remove city from queryset, filters, search, ordering

### 4. URLs (`geo_hierarchy/urls.py`)

**DELETE:**
- `cities/` route

**MODIFY:**
- Verify all other routes still correct

### 5. Admin (`geo_hierarchy/admin.py`)

**DELETE:**
- `CityAdmin`

**MODIFY:**
- `DistrictAdmin`: Remove city filter, add province filter
- `AreaAdmin`: Remove city references
- `RegionAdmin`: Update for region_members

### 6. Seed Data

- Remove all city seed data
- Update district seeds to FK to province
- Update region seeds to use region_members

### 7. Migrations

- Fresh migrations needed (drop old, create new matching v5 schema)

---

## Frontend Changes Needed

### 1. Redux Store (`store/geoHierarchy/`)

**DELETE:**
- `fetchCities.thunk.jsx`
- `fetchMicroschools.thunk.jsx` (legacy, not used)
- All city-related state in `geoHierarchy.slice.jsx` (cities filtered/all buckets, resetCities)

**MODIFY:**
- `geoHierarchy.slice.jsx`: Remove cities state, update cascading logic
- `fetchDistricts.thunk.jsx`: Change param from `cityId` to `provinceId`
- `fetchRegions.thunk.jsx`: May need update depending on new API structure

### 2. HierarchySelector Component

**MODIFY (`components/HierarchySelector/HierarchySelector.jsx`):**
- Remove `city` from chain definition
- New chain: country → province → district → area → cluster
- Update cascading logic: Province selection → fetch Districts (was: City → Districts)
- Update Region: Now can include area and cluster (not just country/province/city/district)

### 3. Pages

**HeirarchyListing.jsx:**
- Remove City column from table
- Remove City from filter dropdowns
- Update Regions tab: Show area and cluster pills (new in region_members)

**CreateHeirarchy.jsx:**
- Remove "Add City" section entirely
- Update "Add District" cascading: Country → Province → District name (was: Country → Province → City → District)
- Update "Add Area" cascading: Country → Province → District → Area (was: Country → Province → City → District → Area)
- Update "Add Cluster" cascading: Remove City from cascade
- Update "Add Region": 5-column checkboxes (Countries, Provinces, Districts, Areas, Clusters — no Cities)

**EditHeirarchy.jsx:**
- Remove city from HierarchySelector levels
- Update region edit to support area and cluster members

### 4. UI Mockups Reference

**hierarchy-listing.html** — already shows 5 levels (no City):
- Filters: Country, Province, District, Area, Cluster
- Table: Country, Province, District, Area, Cluster
- Regions tab: Region Name, Countries, Provinces, Districts, Clusters (no Cities but in mockup it shows Cities column which needs to be ignored)

**hierarchy-management.html** — already shows 5 levels (no City):
- Sections: Add Country, Add Province, Add District, Add Area, Add Cluster
- Region: 5-column checkboxes (Countries, Provinces, Districts, Areas, Clusters)

---

## Cross-App Impact

### school_management
- School model has `cluster` FK — unchanged
- School model has `region` FK — unchanged
- School serializers reference `city_name` — MUST REMOVE
- School model/form had city field — MUST REMOVE

### user_management
- **v5 schema removes ALL hierarchy FKs from user_profiles** (no more primary_country, primary_city, etc.)
- User regional access via `user_*_accesses` tables — city table REMOVED
- `CityUser` pivot model — DELETE
- `access_cities` M2M — DELETE
- All city references in serializers/views — DELETE

> NOTE: user_management changes are part of Module 04, not this module.
> For this module, just update geo_hierarchy app. Cross-app cleanup tracked separately.

---

## Questions / Decisions Needed

None currently — scope is clear from schema v5 and mockups.

---

## Implementation Order (suggested)

1. Update models (remove City, re-parent District, new RegionMember)
2. Create fresh migrations
3. Update serializers (remove city, update region)
4. Update views (remove CityViewSet, update filters)
5. Update URLs (remove cities route)
6. Update admin
7. Update seed data
8. Frontend: Update Redux store (remove cities)
9. Frontend: Update HierarchySelector component
10. Frontend: Update pages (Listing, Create, Edit)

---

## Changes — 2026-04-15 (Manager discussion follow-up)

### Default listing order (`tasks/CHG` — off-tracker)
- All 6 geo models: `Meta.ordering = ['-updated_at', 'name']` (was `['name']`). Migration `0002_alter_*_options` applied.
- `HierarchyFlatView.VALID_ORDER_FIELDS` adds `updated_at`, `created_at`; default `-updated_at`.
- `RegionViewSet.get_queryset` custom-order block allows `updated_at`/`created_at`; default `-updated_at`.
- Frontend `HeirarchyListing.jsx`: initial `hSortBy=updated_at`, `hSortDir=desc`; `rSortBy/rSortDir` same.

### Access-filter enforced unconditionally — BUG-14 / BUG-28 (TASK-061, TASK-066)
- `BaseGeoViewSet.get_queryset`: filter applied on EVERY authenticated request unless `user.is_superuser` OR `profile.has_global_access`. `filter_access=true` param is now redundant (safe no-op).
- `RegionViewSet` gained `_get_access_filter` using `access_regions` M2M.
- `HierarchyFlatView.get_queryset` filters by `access_clusters` for non-global users.
- Effect: listings, object GET, PUT, DELETE all respect access M2M via `get_object()` → 404 for out-of-scope IDs.

### Delete block — BUG-16 (TASK-062)
- `BaseGeoViewSet.destroy` adds a new guard:
  ```python
  user_count = instance.accessible_by_users.filter(
      user__is_active=True, deleted_at__isnull=True,
  ).count()
  ```
  Blocks deletion with 400 and count when any active user has the entity in their access M2M. Runs after child-count and region-member checks. Applies to all 6 levels because reverse related_name `accessible_by_users` exists on every hierarchy model.

### Still pending (next batches)
- CHG-02 Region-dropdown behaviour (area change ≠ region refilter)
- CHG-08 Auto-add created entity to creator's M2M
- CHG-13 Searchable dropdown on Edit Hierarchy
- BUG-10 "All Countrys" typo, BUG-11 Cluster filter, BUG-15 Delete popup overflow
