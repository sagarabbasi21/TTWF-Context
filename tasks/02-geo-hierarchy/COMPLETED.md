# Geo Hierarchy — Completed Work
> Last Updated: 2026-04-10

## Changes Made
- City removed from entire hierarchy chain
- Province → District directly
- All pages/components/thunks updated to skip City
- Schools.jsx: City filter and column removed
- Users.jsx: City filter removed
- CreateUser/EditUser: City removed from access columns
- fetchDistricts thunk: filters by province (not city)
- userAccessHelpers: City cascade removed
- Hierarchy creation: All checkbox on region columns (Create + Edit)
- Heading color: text-heading (#1A497F) via tailwind config
- Hierarchy dropdowns filtered by user access (filter_access=true param)
- Backend: BaseGeoViewSet._get_access_filter() per ViewSet
- All 6 thunks pass filter_access=true
- Duplicate BaseGeoViewSet definition fixed
- Duplicate ClusterViewSet queryset removed
- ModulePerm permission class added to BaseGeoViewSet (module_code='hierarchy')
- PageHeader icon=account_tree on all 3 hierarchy pages

## Phase 6 — Manager discussion P0/P1/P2 (2026-04-15)

### P0
- **BUG-14 / BUG-28 (TASK-061, TASK-066)** `BaseGeoViewSet.get_queryset` — access filter applied unconditionally for non-superuser, non-global-access users. `filter_access=true` query param now harmless no-op. `HierarchyFlatView.get_queryset` filters by `access_clusters`. `RegionViewSet._get_access_filter` uses `access_regions`.
- **BUG-16 (TASK-062)** `BaseGeoViewSet.destroy` added guard: `instance.accessible_by_users.filter(user__is_active=True, deleted_at__isnull=True).count()` blocks with 400 + count when any active user has it in their M2M.

### P1
- **Default ordering** → `Meta.ordering = ['-updated_at', 'name']` on all 6 models; migration `0002_alter_*_options` applied.
- **CHG-08 (TASK-073)** `BaseGeoViewSet.perform_create` auto-adds new entity to creator's `access_{level}` M2M unless creator has global access. `user_access_attr` defined on all 6 viewsets.
- **BUG-11 (TASK-080)** `HierarchyFlatView` accepts `?cluster=<id>` filter. Frontend `HeirarchyListing.jsx` forwards `filters.cluster`.

### P2
- **CHG-02 (TASK-091)** `RegionDetailSerializer.validate_members` requires at least one district-level member. Area change in listing filters already leaves region dropdown alone (childrenOf map).
- **BUG-10 (TASK-097)** Filter placeholder uses explicit plural map — `All Countries` / `Provinces` / `Districts` etc.
- **CHG-13 (TASK-094)** `Select` component gained `searchable` prop. `HierarchySelector` enables it in edit mode. `EditHierarchy` region-select also searchable.
- **BUG-15 / BUG-25 (TASK-099 / TASK-101)** `DeleteModal` strips HTML from label, truncates to 60 chars + title tooltip, uses `break-words`.

### Pending migrations
- `geo_hierarchy/0002_alter_area_options_alter_cluster_options_and_more.py` — default ordering change.
