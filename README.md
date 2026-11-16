# CVAT on Railway

A Railway template for [CVAT](https://github.com/cvat-ai/cvat) (Computer Vision Annotation Tool), the open-source tool for labelling images and video for computer-vision datasets.

It deploys **CVAT v2.83.0** from the official images, pinned by version and digest:

| Service | Built from | What it runs | Volume |
|---|---|---|---|
| `CVAT` | `cvat/` in this repo (`cvat/server:v2.83.0`, `cvat/ui:v2.83.0`, `openpolicyagent/opa:1.12.2-static`) | Django API server, all RQ workers (import, export, chunks, annotation, webhooks, quality reports, consensus, notifications, cleaning), the OPA policy engine, and the web UI behind one nginx on `PORT` | `/home/django/data` |
| `Kvrocks` | `kvrocks/` in this repo (`apache/kvrocks:2.15.0`) | On-disk Redis-compatible cache for media chunks | `/var/lib/kvrocks` |
| `Postgres` | Railway's PostgreSQL | Main database | Railway-managed |
| `Redis` | Railway's Redis | Job queues and in-memory cache | Railway-managed |

Upstream runs the server and each worker as separate containers that share one data volume. Railway volumes can't be shared between services, so this template runs them all in one container under supervisord, using CVAT's own start scripts and settings.

## Variables

Everything is generated or wired by reference; the deploy asks nothing.

| Service | Variable | Value |
|---|---|---|
| CVAT | `CVAT_ADMIN_USERNAME` | `admin` (first administrator, created once on first boot) |
| CVAT | `CVAT_ADMIN_PASSWORD` | generated secret: read it in the CVAT service's **Variables** tab |
| CVAT | `DJANGO_SECRET_KEY` | generated secret |
| CVAT | `CVAT_POSTGRES_*` | references to the Postgres service |
| CVAT | `CVAT_REDIS_INMEM_*` | references to the Redis service |
| CVAT | `CVAT_REDIS_ONDISK_*` | references to the Kvrocks service |
| CVAT | `PORT` | `8080` |
| Kvrocks | `KVROCKS_PASSWORD` | generated secret |

The administrator is created only when no user with that name exists. Changing `CVAT_ADMIN_PASSWORD` later does not change the password; use CVAT's own "change password" page or `/admin`.

Optional: `CVAT_SERVER_PROCESSES` sets the number of API server processes (default 2). Email is not configured, so CVAT sends no password-reset emails; an administrator can reset passwords at `/admin`. The analytics stack (ClickHouse, Vector, Grafana) and serverless auto-annotation (Nuclio) are not included: Nuclio needs Docker access, which Railway does not offer.

## Updates

The template builds from this repo's `main` branch. When the pinned CVAT version is bumped here, Railway shows deployers an "update available" notice, and they choose when to apply it. Read `CHANGELOG.md` before you apply an update: CVAT runs its database migrations on start, and downgrades are not supported. Back up the Postgres database and the CVAT volume first.

## Local run

```sh
docker build -t cvat-railway cvat && docker build -t kvrocks-railway kvrocks
```

Then run them with Postgres and Redis and the variables above (see upstream's `docker-compose.yml` for the reference setup).

## License

The wrapper files in this repo are MIT-licensed. CVAT is MIT-licensed by CVAT.ai Corporation.
