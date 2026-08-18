#!/usr/bin/env bash
# Start Crawlit with Docker Compose and wait until its health endpoint responds.
set -euo pipefail

start_crawlit_server() {
  local build=0
  local timeout="${CRAWLIT_START_TIMEOUT:-30}"
  local base="${CRAWLIT_BASE_URL:-http://localhost:3000}"

  while (($# > 0)); do
    case "$1" in
      --build)
        build=1
        ;;
      -h|--help)
        echo "Usage: start-server.sh [--build]"
        echo "  --build  rebuild Crawlit image before starting"
        return 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        return 2
        ;;
    esac
    shift
  done

  if ((build)); then
    docker compose up --build -d
  else
    docker compose up -d
  fi

  local deadline=$((SECONDS + timeout))
  until curl -sf -m 3 "$base/health" >/dev/null 2>&1; do
    if ((SECONDS >= deadline)); then
      echo "crawlit failed to become healthy at $base within ${timeout}s" >&2
      return 1
    fi
    sleep 1
  done

  echo "crawlit started ($base)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  start_crawlit_server "$@"
fi
