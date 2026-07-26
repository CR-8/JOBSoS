#!/usr/bin/env bash
# =============================================================================
# CareerHub - Backup Script
#
# Creates a timestamped backup of:
#   - All PostgreSQL databases
#   - Docker named volumes
#   - Configuration files (.env, reverse-proxy, etc.)
#
# Usage: ./backup.sh [output-dir]
#   Default output: ./backups/
# =============================================================================
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${1:-${BASE_DIR}/backups}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${OUTPUT_DIR}/careerhub_${TIMESTAMP}"
COMPOSE_FILE="${BASE_DIR}/docker-compose.yml"
ENV_FILE="${BASE_DIR}/.env"

echo "==> CareerHub Backup (${TIMESTAMP})"
echo "    Output: ${BACKUP_DIR}"

# Validate
if [ ! -f "${COMPOSE_FILE}" ]; then
  echo "ERROR: docker-compose.yml not found at ${COMPOSE_FILE}"
  exit 1
fi

mkdir -p "${BACKUP_DIR}"

# 1. Dump PostgreSQL databases
echo "==> Backing up PostgreSQL databases..."
# Get DB names from the init script or by listing from the container
DB_NAMES=(reactive_resume jobops resume_sync authentik)
for db in "${DB_NAMES[@]}"; do
  echo "    - database: ${db}"
  docker compose -f "${COMPOSE_FILE}" exec -T postgres \
    pg_dump -U "${POSTGRES_USER:-careerhub}" -d "${db}" \
    > "${BACKUP_DIR}/${db}.sql" 2>/dev/null || echo "    WARN: could not back up ${db} (may not exist yet)"
done

# 2. Save environment config
echo "==> Saving environment..."
if [ -f "${ENV_FILE}" ]; then
  cp "${ENV_FILE}" "${BACKUP_DIR}/.env"
  echo "    .env saved"
fi

# 3. Save Traefik dynamic config
if [ -d "${BASE_DIR}/reverse-proxy/dynamic" ]; then
  cp -r "${BASE_DIR}/reverse-proxy/dynamic" "${BACKUP_DIR}/traefik-dynamic"
fi

# 4. Snapshot Docker volumes (requires root/sudo on some systems)
echo "==> Snapshotting Docker volumes..."
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
  echo "    - volume: ${vol}"
  # Use a temporary container to tar the volume
  docker run --rm -v "${vol}":/source:ro -v "${BACKUP_DIR}:/dest" alpine \
    tar czf "/dest/${vol}.tar.gz" -C /source . 2>/dev/null || echo "    WARN: could not back up volume ${vol}"
done

# 5. Summary
echo "==> Backup complete."
ls -lh "${BACKUP_DIR}"
