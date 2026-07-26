#!/usr/bin/env bash
# =============================================================================
# CareerHub - First-time Setup Script
#
# Clones upstream repositories as git submodules, prepares .env,
# and starts the stack.
#
# Usage: ./scripts/setup.sh
# =============================================================================
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "${BASE_DIR}"

echo "==> CareerHub Setup"
echo ""

# 1. Check Docker
if ! command -v docker &>/dev/null; then
  echo "ERROR: Docker is not installed. Install Docker first: https://docs.docker.com/engine/install/"
  exit 1
fi

# 2. Clone submodules (upstream repos)
if [ -f ".gitmodules" ]; then
  echo "==> Initializing upstream submodules..."
  git submodule init 2>/dev/null || echo "    Not a git repository; skipping submodule init."
  git submodule update --depth 1 2>/dev/null || echo "    Skipping submodule checkout (repos will be cloned on first build)."
fi

# 3. Prepare .env from example
if [ ! -f ".env" ]; then
  echo "==> Creating .env from .env.example..."
  cp .env.example .env
  echo "    IMPORTANT: Edit .env with your secrets before continuing."
  echo "    Run: nano .env"
else
  echo "==> .env already exists, skipping."
fi

# 4. Create backup directory placeholder
mkdir -p backups

echo ""
echo "==> Setup complete."
echo "    Next steps:"
echo "      1. Edit .env with your own secrets"
echo "      2. Run: docker compose up -d"
echo "      3. Run: docker compose logs -f"
