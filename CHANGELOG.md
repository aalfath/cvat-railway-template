# Changelog

## 2026-11-16: CVAT v2.83.0

- First release of the template: CVAT v2.83.0 (`cvat/server` and `cvat/ui` pinned by digest), OPA 1.12.2, Kvrocks 2.15.0, Railway Postgres and Redis.
- Server, workers, OPA and UI run in one container so they can share the data volume.
- First administrator is created from `CVAT_ADMIN_USERNAME` / `CVAT_ADMIN_PASSWORD` (generated).
