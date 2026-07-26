# CareerHub

**Unified Self-Hosted Career Management Platform**

CareerHub integrates [Reactive Resume](https://github.com/AmruthPillai/Reactive-Resume) (resume builder) and [JobOps](https://github.com/DaKheera47/job-ops) (job application tracker) into a single, cohesive platform behind one reverse proxy with shared authentication — without modifying or forking either upstream project.

## Architecture

```
Internet
   │
   ▼
┌─────────────────────────────────────────────────────────┐
│  Traefik (Reverse Proxy / TLS)          Ports 80, 443   │
│  ────────────────────────────────────────────────────── │
│  /           → CareerHub Dashboard (Next.js 15)         │
│  /resume     → Reactive Resume      (resume builder)    │
│  /jobs       → JobOps               (job tracker)       │
│  /api/*      → Resume Sync API      (FastAPI bridge)    │
│  /auth/*     → Authentik            (SSO provider)      │
└─────────────────────────────────────────────────────────┘
   │           │           │           │           │
   ▼           ▼           ▼           ▼           ▼
┌──────┐ ┌──────────┐ ┌───────┐ ┌────────────┐ ┌──────────┐
│ Dash │ │ Reactive │ │JobOps │ │Resume Sync │ │Authentik │
│board │ │ Resume   │ │       │ │API         │ │          │
└──────┘ └──────────┘ └───────┘ └────────────┘ └──────────┘
   │           │           │           │           │
   ▼           ▼           ▼           ▼           ▼
┌─────────────────────────────────────────────────────────┐
│  PostgreSQL ──── separate databases per application     │
│  Redis  ──────── shared cache (separate logical DBs)    │
│  rr_data volume ─ local filesystem storage for uploads  │
└─────────────────────────────────────────────────────────┘
```

### Design Principles

| Principle | Practice |
|---|---|
| **No forks** | Both upstream repos are consumed as-is via pre-built Docker images |
| **No shared tables** | Each application owns its own database or schema |
| **API-first integration** | The Resume Sync API talks to upstream apps via their HTTP APIs, never directly touching their databases |
| **Upgrade-safe** | Pulling new upstream images is the only step required to update |
| **SSO native** | Reactive Resume supports OIDC natively; Authentik handles identity |
| **AI-ready** | The Resume Sync API has reserved endpoints returning 501 for future AI capabilities |

## Prerequisites

-   **Docker** 24+ and **Docker Compose** v2.20+
-   **Git**
-   A domain name pointing to your server (or local DNS for `careerhub.local`)

## Quick Start

```bash
git clone https://github.com/CR-8/JOBSoS.git careerhub
cd careerhub

cp .env.example .env

# Edit .env with your own secrets and domain
nano .env

docker compose up -d
```

**First-time setup:**
1. Open `https://<your-domain>` — the Dashboard loads.
2. Complete Authentik bootstrapping: visit `/auth` and log in with the bootstrap credentials from `.env`.
3. Create OIDC applications in Authentik for both the Dashboard and Reactive Resume (see [Authentication](#authentication)).
4. Sign into Reactive Resume via the SSO provider.

## Environment Variables

See `.env.example` for the complete list. Key variables:

| Variable | Description | Required |
|---|---|---|
| `DOMAIN` | Public domain (e.g., `careerhub.example.com`) | Yes |
| `POSTGRES_PASSWORD` | PostgreSQL superuser password | Yes |
| `RR_AUTH_SECRET` | Reactive Resume auth secret (`openssl rand -hex 32`) | Yes |
| `RR_ENCRYPTION_SECRET` | Reactive Resume encryption secret (`openssl rand -hex 32`) | Yes |
| `AUTHENTIK_SECRET_KEY` | Authentik secret key (`openssl rand -hex 32`) | Yes |
| `AUTHENTIK_BOOTSTRAP_PASSWORD` | Authentik admin password | Yes |
| `AUTHENTIK_BOOTSTRAP_TOKEN` | Authentik bootstrap API token | Yes |
| `SYNC_JWT_SECRET` | Resume Sync API JWT secret | Yes |
| `RR_OIDC_CLIENT_SECRET` | OIDC client secret for Reactive Resume | Yes |
| `DASHBOARD_OIDC_CLIENT_SECRET` | OIDC client secret for Dashboard | Yes |
| `ACME_EMAIL` | Email for Let's Encrypt notifications | Yes |

> **Security**: Never commit your `.env` file. All secrets should be at least 32 characters. Use `openssl rand -hex 32` to generate them.

## Services

| Service | Base Image | Exposed | Health Endpoint |
|---|---|---|---|
| Traefik | `traefik:v3.2` | 80, 443 | Built-in ping |
| PostgreSQL | `postgres:17-alpine` | Internal | `pg_isready` |
| Redis | `redis:7-alpine` | Internal | `redis-cli ping` |
| Authentik Server | `ghcr.io/goauthentik/server` | Internal | `/health/ready/` |
| Authentik Worker | `ghcr.io/goauthentik/server` | Internal | celery inspect |
| Reactive Resume | `ghcr.io/amruthpillai/reactive-resume` | Internal | `/api/health` |
| JobOps | `ghcr.io/dakheera47/job-ops` | Internal | `/health` |
| Resume Sync API | Custom (FastAPI) | Internal | `/health` |
| Dashboard | Custom (Next.js 15) | Internal | `/api/health` |

### To build from source instead of using pre-built images

The upstream repositories are tracked as git submodules under `services/`. If you prefer to build instead of pulling images:

1. Initialize submodules:
   ```bash
   git submodule update --init --depth 1
   ```
2. In `docker-compose.yml`, uncomment the `build:` sections and comment the `image:` lines for the services you want to build.

## Authentication

CareerHub uses [Authentik](https://goauthentik.io/) as its Single Sign-On provider.

### Reactive Resume OIDC Setup

Reactive Resume natively supports OpenID Connect (OIDC). To connect it to Authentik:

1. Open Authentik admin at `https://<domain>/auth`.
2. Create a **Provider**:
   - Type: **OAuth2/OpenID Provider**
   - Name: `Reactive Resume`
   - Client ID: `reactive-resume` (must match `RR_OIDC_CLIENT_ID` in `.env`)
   - Client Secret: (must match `RR_OIDC_CLIENT_SECRET` in `.env`)
   - Redirect URIs: `https://<domain>/resume/api/auth/callback`
   - Scopes: `openid profile email`
3. Create an **Application**:
   - Name: `Reactive Resume`
   - Slug: `reactive-resume`
   - Provider: select the one created above
4. Save.

### Dashboard OIDC Setup

1. Create a second **Provider**:
   - Type: **OAuth2/OpenID Provider**
   - Name: `CareerHub Dashboard`
   - Client ID: `dashboard` (must match `DASHBOARD_OIDC_CLIENT_ID` in `.env`)
   - Client Secret: (must match `DASHBOARD_OIDC_CLIENT_SECRET` in `.env`)
   - Redirect URIs: `https://<domain>/api/auth/callback`
   - Scopes: `openid profile email`
2. Create an **Application**:
   - Name: `CareerHub Dashboard`
   - Slug: `dashboard`
   - Provider: select the one created above
3. Save.

### JobOps Authentication

JobOps does **not** support OIDC natively. It uses HTTP Basic Auth (`BASIC_AUTH_USER`/`BASIC_AUTH_PASSWORD`) and JWT sessions. CareerHub bridges this by:

-   Routing `/jobs` through Traefik, which can be configured with Authentik's **Forward Auth** to add an extra authentication layer.
-   Documenting the JobOps credentials so you can log in separately.

> **Future improvement**: Authentik's Outpost/Proxy Provider can sit in front of JobOps for unified auth. This is documented in the Authentik docs as "Proxy Provider."

## Resume Sync API

The `resume-sync-api` is a FastAPI service that bridges Reactive Resume and JobOps without touching either application's database.

### Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Health check |
| `GET` | `/resumes` | List all synced resumes |
| `GET` | `/resume/{id}` | Get resume metadata |
| `POST` | `/resume/sync/{id}` | Sync a resume to JobOps |
| `POST` | `/resume/default` | Set the default resume |
| `POST` | `/resume/tailor` | *Not implemented — 501* |
| `POST` | `/resume/cover-letter` | *Not implemented — 501* |
| `POST` | `/resume/ats-score` | *Not implemented — 501* |
| `POST` | `/resume/job-match` | *Not implemented — 501* |

The `501` endpoints are reserved for future AI integration. The API contract and routing are already in place; only the business logic needs to be implemented.

### Resume Workflow

1. Create/upload your master resume in Reactive Resume (at `/resume`).
2. The Resume Sync API discovers the resume via Reactive Resume's API.
3. When you create a job application in JobOps (at `/jobs`), the API associates the selected resume version with that application.
4. Your application history always knows which resume version was used.

### Application Workflow

1. Create a job lead in JobOps.
2. Paste the job description.
3. Select a resume.
4. Application is created with the resume version linked.
5. Update status (Applied → Interview → Offer / Rejected).

## Deployment

### Production Deployment

For a production deployment:

```bash
# On your server
git clone https://github.com/CR-8/JOBSoS.git
cd careerhub
cp .env.example .env
nano .env  # Set DOMAIN and all secrets

docker compose up -d
docker compose logs -f
```

### TLS / HTTPS

Traefik automatically provisions Let's Encrypt certificates using the ACME TLS challenge. Ensure:

1. `DOMAIN` resolves to your server's public IP.
2. Port 443 is reachable from the internet.
3. `ACME_EMAIL` is a valid email address.

### Security Considerations

- Change all default passwords in `.env` before exposing to the internet.
- Traefik's API dashboard is enabled (`api.insecure=true`) but only accessible internally. Disable it in production by removing the `--api.insecure=true` flag.
- Authentik's bootstrap password should be changed after first login.
- JobOps Basic Auth credentials travel over the internal Docker network. They are not exposed externally.

## Updating Upstream Projects

Both Reactive Resume and JobOps provide pre-built Docker images. Updating is straightforward:

```bash
# Pull the latest images
docker compose pull

# Recreate containers with new images
docker compose up -d

# Clean up old images
docker image prune -a
```

Run `./scripts/update-upstream.sh` for a guided update.

If you need to track upstream source changes:

```bash
git submodule update --remote
```

Then rebuild (if building from source) with `docker compose build`.

## Backup

```bash
./backup.sh
```

Creates a timestamped directory in `./backups/` containing:

- PostgreSQL dumps for all databases
- Docker volume snapshots (`.tar.gz`)
- `.env` configuration
- Traefik dynamic configuration

Automate with cron:

```bash
0 3 * * * /path/to/careerhub/backup.sh /path/to/backups
```

## Restore

```bash
./restore.sh ./backups/careerhub_20250620_143000
```

Stops all services, restores volumes and databases, then restarts.

## Troubleshooting

> The container names below (`careerhub-postgres`, etc.) apply to the Traefik deployment (`docker-compose.yml`). The Coolify deployment (`docker-compose.coolify.yml`) uses a `careerhub-cf-*` prefix instead (e.g. `careerhub-cf-postgres`, `careerhub-cf-reactive-resume`) to avoid name collisions if both stacks ever run on the same host.

| Symptom | Likely Cause | Solution |
|---|---|---|
| Dashboard loads but `/resume` is blank | Reactive Resume still starting | Wait 30s, check logs: `docker logs careerhub-reactive-resume` |
| `/jobs` returns 401 | JobOps auth misconfigured | Check `JOBOPS_AUTH_USER` / `JOBOPS_AUTH_PASSWORD` in `.env` |
| Authentik login fails | Bootstrap token mismatch | Regenerate `AUTHENTIK_BOOTSTRAP_TOKEN` and restart |
| TLS certificate not issued | DNS not propagated | Ensure your domain resolves to the server's IP |
| "Cannot connect to Postgres" | DB not initialized | Check `docker logs careerhub-postgres` |
| Reactive Resume shows empty OAuth button | OIDC provider not created in Authentik | Follow [Authentication](#authentication) section |
| Resume Sync API 500 errors | Reactive Resume API unreachable | Ensure Reactive Resume is healthy (`docker logs careerhub-reactive-resume`) |
| Volume mount permission errors | SELinux/AppArmor | Set `security_opt: ["no-new-privileges:true"]` or disable SELinux for Docker volumes |
| Docker Compose version error | Docker Compose < 2.20 | Upgrade Docker: `apt install docker-compose-plugin` |

## Known Limitations

1.  **JobOps does not natively support OIDC.** It uses HTTP Basic Auth and JWT. The platform routes around this by keeping JobOps on its own auth domain within the Traefik network. See [Authentication](#authentication) for details.
2.  **JobOps uses SQLite**, not PostgreSQL. This is an upstream design choice. The JobOps SQLite database lives in a Docker volume and is backed up as a volume snapshot.
3.  **Reactive Resume's self-hosted API is not fully documented for external consumption.** The Resume Sync API uses best-effort HTTP calls to Reactive Resume's internal API. Some integration points may require upstream API additions.
4.  **No automatic user provisioning across services.** Each application has its own user model. Authentik provides SSO at the auth layer, but user metadata is not synchronized across applications.
5.  **Reactive Resume uploads live on a single local volume (`rr_data`).** There's no built-in Cloudinary support in Reactive Resume — it only supports S3-compatible object storage or local filesystem. This deployment uses local filesystem storage, so back up the `rr_data` volume like any other stateful volume.

## Future Roadmap

### AI Integration (design completed, not implemented)

The Resume Sync API has reserved endpoints for:

- **Resume Tailoring** (`POST /resume/tailor`) — Tailor a resume to a specific job description
- **Cover Letter Generation** (`POST /resume/cover-letter`) — Generate cover letters
- **ATS Scoring** (`POST /resume/ats-score`) — Score resume against job description for ATS fit
- **Job Match Percentage** (`POST /resume/job-match`) — Calculate compatibility between resume and JD

All return `501 Not Implemented`. To implement, plug in an LLM (OpenAI, Claude, local Ollama) into the Resume Sync API without changing the architecture.

### Planned Enhancements

| Feature | Stage | Notes |
|---|---|---|
| Authentik Proxy Provider for JobOps | Planned | Eliminates separate JobOps login |
| Dashboard analytics widgets | Planned | Consume job statistics from JobOps API |
| Resume version diffing | Planned | Show changes between resume versions |
| Email notification integration | Planned | Alerts for application status changes |
| Multi-user support | Planned | RBAC via Authentik groups |

## Repository Structure

```
careerhub/
├── docker-compose.yml               # Main orchestration
├── .env.example                     # Environment template
├── .gitmodules                      # Git submodules for upstream repos
├── backup.sh                        # Backup script
├── restore.sh                       # Restore script
├── LICENSE                          # MIT License
├── README.md                        # This file
├── dashboard/                       # Next.js 15 dashboard
│   ├── Dockerfile
│   ├── package.json
│   ├── next.config.js
│   ├── tailwind.config.js
│   ├── app/
│   ├── components/
│   └── lib/
├── resume-sync-api/                 # FastAPI integration service
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/
├── reverse-proxy/                   # Traefik dynamic config
│   └── dynamic/
├── configs/                         # Service configurations
│   ├── postgres/
│   └── redis/
├── scripts/                         # Utility scripts
│   ├── setup.sh
│   ├── update-upstream.sh
│   └── health-check.sh
└── services/                        # Upstream repos (git submodules)
    ├── reactive-resume/             # https://github.com/AmruthPillai/Reactive-Resume
    └── jobops/                      # https://github.com/DaKheera47/job-ops
```

## Upgrading CareerHub

Since CareerHub is an integration layer, upgrading means:

1. **Pull new upstream Docker images** — `docker compose pull`
2. **Pull new CareerHub code** — `git pull`
3. **Recreate containers** — `docker compose up -d`

No database migrations are needed unless explicitly noted in release notes. The Resume Sync API has its own SQLAlchemy-managed schema that evolves independently.

## License

This project (the integration layer) is licensed under the MIT License.

- Reactive Resume is MIT licensed.
- JobOps is AGPLv3 + Commons Clause licensed.
