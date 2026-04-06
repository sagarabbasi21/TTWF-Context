# Security & Performance Audit — TTWF Portal

**Audit Date:** 2026-04-03  
**Last Updated:** 2026-04-04  
**Scope in progress:** Module 02 — Geo Hierarchy  

---

## Critical

| # | Issue | Location | Status |
|---|-------|----------|--------|
| 1 | Hardcoded SECRET_KEY, DB password, email creds, OTP_KEY in settings | `settings/base.py:60,168-175`, `settings/env.py:2,8,16` | PENDING |
| 2 | DEBUG = True in base settings — exposes traces, queries, paths | `settings/base.py:20` | PENDING |
| 3 | JWT tokens stored in localStorage — XSS vulnerable | `frontend/src/utils/helpers/localStorage.js:1-4` | PENDING |

## High

| # | Issue | Location | Status |
|---|-------|----------|--------|
| 4 | N+1 queries in RegionListSerializer — 5 DB queries per region row | `serializers.py` RegionListSerializer | DONE — Batch eager loading via `setup_eager_loading()`, 5 total queries regardless of page size |
| 5 | Region search fires 5 separate queries per request, no length limit | `views.py` RegionViewSet | DONE — Optimized to loop + collect, added `[:200]` length cap and `[:500]` per-model cap |
| 6 | No rate limiting on OTP endpoint — brute-forceable 6-digit OTP | `authflow/views.py:26-30` | PENDING |
| 7 | Access token lifetime = 10 days (standard ~15 min), refresh = 28 days | `auth_token_config.py:3-4` | PENDING |
| 8 | Profile PIN stored in plaintext — CharField(max_length=4) | `school_management/models.py:227` | PENDING |
| 9 | No form submit loading state — double-click creates duplicates | `CreateHeirarchy.jsx` | DONE — Added `saving` state + `disabled` on all 7 save buttons |
| 10 | Sequential nested API calls in EditHeirarchy region select (N+N²) | `EditHeirarchy.jsx` handleRegionSelect | DONE — Replaced nested for-loops with `Promise.all()` at each level |
| 11 | Race conditions in cascading toggles — stale state on rapid clicks | `Create/EditHeirarchy.jsx` | DONE — Added `toggleLoading` guard on all async toggle functions |

## Medium

| # | Issue | Location | Status |
|---|-------|----------|--------|
| 12 | CSRF_TRUSTED_ORIGINS commented out for production | `settings/env.py:19-21` | PENDING |
| 13 | created_by/updated_by user IDs exposed in list serializers | `serializers.py` (all detail serializers) | PENDING |
| 14 | No API throttling configured | `settings/base.py` REST_FRAMEWORK | PENDING |
| 15 | No CSRF token injection in axios interceptor | `axios.private.js` | PENDING |
| 16 | Unsafe JWT decoding — window.atob() with no try-catch | `filterData.js:107-113` | DONE — Added try-catch, null safety in `isAccessTokenValid()` |
| 17 | Redux DevTools enabled in non-production — leaks auth state | `store.js:43` | PENDING |
| 18 | Silent error swallowing in toggle cascade catch blocks | `CreateHeirarchy.jsx:114-119` | DONE — All catch blocks now call `showError()` with descriptive message |
| 19 | Delete button has no spam protection during API call | `EditHeirarchy.jsx:116-129` | DONE — Added `deleting` guard on `handleDeleteConfirm` |
| 20 | .env file committed to source control | `frontend/.env` | PENDING |
