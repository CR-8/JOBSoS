#!/usr/bin/env bash
# =============================================================================
# CareerHub - Restore Script
#
# Restores a previously created backup from ./backups/ directory.
# Usage: ./restore.sh <backup-dir>
#
# Example:
#   ./restore.sh ./backups/careerhub_20250128_120000
# =============================================================================
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
RESTORE_DIR="${1:-}"
COMPOSE_FILE="${BASE_DIR}/docker-compose.yml"

if [ -z "${RESTORE_DIR}" ]; then
  echo "ERROR: Usage: ./restore.sh <backup-dir>"
  echo "  Available backups:"
  ls -d "${BASE_DIR}/backups/careerhub_"* 2>/dev/null || echo "  (none found)"
  exit 1
fi

if [ ! -d "${RESTORE_DIR}" ]; then
  echo "ERROR: Backup directory not found: ${RESTORE_DIR}"
  exit 1
fi

echo "==> CareerHub Restore from $(basename "${RESTORE_DIR}")"

# 1. Stop stack
echo "==> Stopping all services..."
docker compose -f "${COMPOSE_FILE}" down

# 2. Restore Docker volumes
echo "==> Restoring Docker volumes..."
VOLUMES=(
  careerhub-postgres
  careerhub-redis
  careerhub-seaweedfs
  careerhub-authentik-db
  careerhub-authentik-media
  careerhub-authentik-certs
  careerhub-authentik-redis
  careerhub-rr-data
  careerhub-jobops-data
  careerhub-jobops-codex
  careerhub-traefik-certs
)
for vol in "${VOLUMES[@]}"; do
  TAR_FILE="${RESTORE_DIR}/${vol}.tar.gz"
  if [ -f "${TAR_FILE}" ]; then
    echo "    - volume: ${vol}"
    # Ensure volume exists
    docker volume inspect "${vol}" &>/dev/null || docker volume create "${vol}"
    docker run --rm -v "${vol}":/target -v "${RESTORE_DIR}:/source" alpine \
      tar xzf "/source/${vol}.tar.gz" -C /target
  fi
done

# 3. Restore environment config
ENV_BACKUP="${RESTORE_DIR}/.env"
if [ -f "${ENV_BACKUP}" ]; then
  echo "==> Restoring .env..."
  cp "${ENV_BACKUP}" "${BASE_DIR}/.env"
fi

# 4. Restore Traefik dynamic config
TRAEFIK_BACKUP="${RESTORE_DIR}/traefik-dynamic"
if [ -d "${TRAEFIK_BACKUP}" ]; then
  echo "==> Restoring Traefik config..."
  cp -r "${TRAEFIK_BACKUP}"/* "${BASE_DIR}/reverse-proxy/dynamic/"
fi

# 5. Start stack
echo "==> Starting services..."
docker compose -f "${COMPOSE_FILE}" up -d

# 6. Restore PostgreSQL databases
echo "==> Waiting for PostgreSQL to be healthy..."
sleep 5
docker compose -f "${COMPOSE_FILE}" exec -T postgres \
  pg_isready -U "${POSTGRES_USER:-careerhub}" --quiet || sleep 10

echo "==> Restoring PostgreSQL databases..."
DB_NAMES=(reactive_resume jobops resume_sync authentik)
for db in "${DB_NAMES[@]}"; do
  SQL_FILE="${RESTORE_DIR}/${db}.sql"
  if [ -f "${SQL_FILE}" ]; then
    echo "    - database: ${db}"
    # Drop and recreate cleanly
    docker compose -f "${COMPOSE_FILE}" exec -T postgres \
      psql -U "${POSTGRES_USER:-careerhub}" -d postgres \
      -c "DROP DATABASE IF EXISTS ${db};" \
      -c "CREATE DATABASE ${db};"
    docker compose -f "${COMPOSE_FILE}" exec -T postgres \
      psql -U "${POSTGRES_USER:-careerhub}" -d "${db}" < "${SQL_FILE}"
  fi
done

echo "==> Restore complete."
echo "    Access your platform at https://${DOMAIN:-careerhub.local}"
echo "    (If you changed DOMAIN in the restored .env, restart with: docker compose up -d)"
