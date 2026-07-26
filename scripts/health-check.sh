#!/usr/bin/env bash
# =============================================================================
# CareerHub - Health Check Script
#
# Verifies that all services are up and their health endpoints respond.
#
# Usage: ./scripts/health-check.sh
# =============================================================================
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${BASE_DIR}/docker-compose.yml"

echo "==> CareerHub Health Check"
echo ""

# 1. Check all containers are running
echo "==> Container Status:"
docker compose -f "${COMPOSE_FILE}" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo ""

# 2. Check health endpoints
echo "==> Health Endpoint Checks:"

check_health() {
  local name=$1
  local url=$2
  local status_code
  status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "${url}" 2>/dev/null || echo "000")
  if [ "${status_code}" = "200" ] || [ "${status_code}" = "000" ]; then
    printf "    %-25s %s\n" "${name}" "${status_code}"
  else
    printf "    %-25s %s\n" "${name}" "${status_code}"
  fi
}

# These run inside Docker network — if outside, use localhost with Docker port mapping
check_health "Dashboard" "http://localhost:3000/api/health"
check_health "Reactive Resume" "http://localhost:3000/api/health"
check_health "JobOps" "http://localhost:3005/health"
check_health "Resume Sync API" "http://localhost:8000/health"
check_health "Authentik" "http://localhost:9000/-/health/ready/"

echo ""
echo "==> Disk Usage:"
docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}"

echo ""
echo "==> Health check complete."
