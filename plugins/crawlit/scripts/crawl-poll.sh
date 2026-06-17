#!/usr/bin/env bash
# Poll a crawlit crawl job until completed, failed, or timeout.
# Usage: crawl-poll.sh <job-id> [timeout-seconds]
# Output: final JSON response on stdout. Progress on stderr.
set -euo pipefail

JOB_ID="${1:?Usage: crawl-poll.sh <job-id> [timeout-seconds]}"
TIMEOUT="${2:-1800}"

BASE="${CRAWLIT_BASE_URL:-http://localhost:3000}"

delay=2
max_delay=15
deadline=$(( $(date +%s) + TIMEOUT ))

while true; do
  resp=$(curl -sf "$BASE/v1/crawl/$JOB_ID")
  status=$(echo "$resp" | jq -r '.status')
  done_n=$(echo "$resp" | jq -r '.completed // 0')
  total=$(echo "$resp" | jq -r '.total // 0')

  echo "[$status] $done_n/$total pages" >&2

  case "$status" in
    completed)
      echo "$resp"
      exit 0
      ;;
    failed|cancelled)
      echo "Crawl $status" >&2
      echo "$resp" | jq -r '.error // "unknown error"' >&2
      exit 1
      ;;
  esac

  if [ "$(date +%s)" -gt "$deadline" ]; then
    echo "" >&2
    echo "Polling timeout after ${TIMEOUT}s — job still running server-side." >&2
    echo "To cancel: curl -X DELETE $BASE/v1/crawl/$JOB_ID" >&2
    echo "To resume: $0 $JOB_ID" >&2
    exit 2
  fi

  sleep "$delay"
  next=$(( delay * 3 / 2 ))
  delay=$(( next < max_delay ? next : max_delay ))
done
