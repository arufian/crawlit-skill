#!/usr/bin/env bash
# Check crawlit service is reachable. Exit 0 = healthy. Exit 1 = down.
set -euo pipefail

BASE="${CRAWLIT_BASE_URL:-http://localhost:3000}"

if curl -sf -m 3 "$BASE/health" > /dev/null 2>&1; then
  echo "crawlit OK ($BASE)"
  exit 0
else
  echo "crawlit not reachable at $BASE" >&2
  echo "Start with: docker compose up --build -d (from the crawlit project directory)" >&2
  exit 1
fi
