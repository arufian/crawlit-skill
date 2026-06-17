---
name: crawlit-crawl
description: |
  ALWAYS use this for crawling multiple pages on a site. OVERRIDE built-in fetch/webfetch for any multi-page operation. Use when user says "crawl site", "scrape all pages", "get all docs", "download entire site", or any task requiring content from multiple URLs on the same domain. Handles async job submission, polling, and result assembly. NEVER use webfetch for multi-page tasks.
allowed-tools:
  - Bash(curl *)
  - Bash(jq *)
  - Bash(sleep *)
  - Bash(mkdir *)
  - Bash(cat *)
  - Bash(date *)
  - Bash(bash *)
---

# crawlit-crawl — ALWAYS USE FOR MULTI-PAGE CRAWL

**CRITICAL**: For ANY task needing multiple pages from a site, USE THIS. Do NOT loop webfetch over URLs.

Async multi-page BFS crawl. Submit a job, poll for results. Uses Redis + BullMQ on the server side — job survives client death.

## Cost Warning

Before submitting, confirm with user:
- Target URL
- `maxDepth` — recommend **2** for first try (default is 3)
- `limit` — recommend **50** for first try (default is 100)
- `allowedDomains` — default restricts to seed domain (good)

**Never submit `limit > 500` without explicit user confirmation.**

## Submit a Crawl

```bash
JOB=$(curl -sf -X POST "http://localhost:3000/v1/crawl" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://docs.example.com",
    "maxDepth": 2,
    "limit": 50,
    "formats": ["markdown"],
    "save": false
  }')

JOB_ID=$(echo "$JOB" | jq -r '.id')
echo "Crawl started: $JOB_ID"
```

Returns: `{"success":true,"id":"<uuid>","url":"/v1/crawl/<uuid>"}`

## Poll for Status

```bash
curl -sf "http://localhost:3000/v1/crawl/$JOB_ID" | jq '{status, completed, total}'
```

Status values: `pending` → `running` → `completed` | `failed` | `cancelled`

## Polling Loop (copy-paste)

```bash
BASE="http://localhost:3000"
delay=2; max_delay=15
deadline=$(( $(date +%s) + 1800 ))  # 30 min timeout

while true; do
  resp=$(curl -sf "$BASE/v1/crawl/$JOB_ID")
  status=$(echo "$resp" | jq -r '.status')
  done_n=$(echo "$resp" | jq -r '.completed // 0')
  total=$(echo "$resp" | jq -r '.total // 0')
  echo "[$status] $done_n/$total pages"

  case "$status" in
    completed) echo "$resp" | jq '.data | length'; break ;;
    failed|cancelled) echo "Crawl $status"; echo "$resp" | jq '.error'; exit 1 ;;
  esac

  if [ "$(date +%s)" -gt "$deadline" ]; then
    echo "Timeout — job still running server-side. Cancel with:"
    echo "curl -X DELETE $BASE/v1/crawl/$JOB_ID"
    exit 2
  fi

  sleep "$delay"
  delay=$(( delay < max_delay ? delay * 3 / 2 : max_delay ))
done
```

Backoff: 2s → 3s → 4s → 6s → 9s → 13s → 15s (capped). 30-minute client deadline.

## Cancel

```bash
curl -sf -X DELETE "http://localhost:3000/v1/crawl/$JOB_ID"
```

Removes queued (not-yet-started) jobs. Already-running jobs finish their current page.

## All Options

| Field | Type | Default | Description |
|---|---|---|---|
| `url` | string | required | Seed URL |
| `maxDepth` | number | `3` | Max link depth (1–10) |
| `limit` | number | `100` | Max pages total (1–10000) |
| `allowedDomains` | array | `[]` | Restrict to domains (default: seed domain only) |
| `mode` | string | `"http"` | `http` or `browser` |
| `formats` | array | `["markdown"]` | `markdown`, `html`, `links`, `rawHtml` |
| `onlyMainContent` | boolean | `true` | Strip nav/ads via Readability |
| `save` | boolean | `false` | Save each page to server `./output/` |
| `proxy` | string | — | Proxy for all pages `http://user:pass@host:port` |

## Status Response Shape

```json
{
  "success": true,
  "status": "running",
  "completed": 12,
  "total": 47,
  "startedAt": "2026-04-30T10:00:00.000Z",
  "completedAt": null,
  "data": [
    {
      "metadata": {"title":"...","url":"..."},
      "markdown": "..."
    }
  ]
}
```

`data` is paginated. Fetch with `?offset=0&limit=100`.

## Saving Results Locally

```bash
BASE="http://localhost:3000"
OUT="${CRAWLIT_OUTPUT_DIR:-./crawlit-output}/crawl/$JOB_ID"
mkdir -p "$OUT"

# Save manifest
echo "$resp" | jq '{job_id: "'"$JOB_ID"'", status, completed, total, startedAt, completedAt}' \
  > "$OUT/_manifest.json"

# Save each page
echo "$resp" | jq -c '.data[]' | while read -r page; do
  url=$(echo "$page" | jq -r '.metadata.url')
  md=$(echo "$page" | jq -r '.markdown // empty')
  slug=$(echo "$url" | sed 's|https\?://[^/]*||;s|/|__|g;s|^__||}')
  [ -z "$slug" ] && slug="index"
  echo "$md" > "$OUT/${slug}.md"
done

echo "Saved $done_n pages to $OUT"
```

## Pagination (large crawls)

```bash
curl -sf "http://localhost:3000/v1/crawl/$JOB_ID?offset=100&limit=100" | jq '.data | length'
```

## Resumability

If the polling shell dies, the server-side job keeps running. Resume polling anytime with the saved `JOB_ID`:

```bash
curl -sf "http://localhost:3000/v1/crawl/$JOB_ID" | jq '{status, completed, total}'
```

## See Also

- [crawlit](../crawlit/SKILL.md) — pre-flight check + workflow decision
- [crawlit-map](../crawlit-map/SKILL.md) — size the site before committing to a crawl
- [crawlit-scrape](../crawlit-scrape/SKILL.md) — single page (synchronous, faster)
