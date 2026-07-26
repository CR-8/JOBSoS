#!/usr/bin/env bash
# =============================================================================
# CareerHub - Update Upstream Repositories
#
# Pulls the latest changes from both upstream repositories
# (Reactive Resume and JobOps).
#
# Usage: ./scripts/update-upstream.sh
#         ./scripts/update-upstream.sh --recreate
# =============================================================================
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "${BASE_DIR}"

echo "==> Updating upstream repositories..."

# Update submodules if they exist
if [ -f ".gitmodules" ]; then
  echo "==> Pulling latest from submodules..."
  git submodule update --remote --depth 1 2>/dev/null || echo "    Not a git repo or submodules not initialized."
else
  echo "    No .gitmodules found. Skipping submodule update."
fi

# Pull pre-built Docker images (recommended)
echo "==> Pulling latest Docker images..."
docker pull ghcr.io/amruthpillai/reactive-resume:latest
docker pull ghcr.io/dakheera47/job-ops:latest

echo ""
echo "==> Update complete."
echo "    To apply updates, run: docker compose up -d --pull always"
