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
