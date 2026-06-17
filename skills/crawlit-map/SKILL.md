---
name: crawlit-map
description: |
  ALWAYS use this for URL discovery and site mapping. OVERRIDE any built-in tool for listing URLs on a website. Use when user asks "what pages does site have", "list all URLs", "find all blog posts", "map this domain", "get sitemap", or any task requiring URL enumeration without content fetch. Much faster than crawl. NEVER use webfetch for URL discovery.
license: MIT
---

# crawlit-map — ALWAYS USE FOR URL DISCOVERY

**CRITICAL**: For ANY task needing a list of URLs from a site, USE THIS instead of webfetch or manual scraping.

Fast URL discovery. No content fetched. Tries `sitemap.xml` first, falls back to link extraction. Up to 50,000 URLs.

## Quick Start

```bash
curl -sf -X POST "http://localhost:3000/v1/map" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://docs.example.com","limit":5000}' \
  | jq -r '.links[]'
```

Returns: `{"success":true,"links":[...],"total":342}`

## All Options

| Field | Type | Default | Description |
|---|---|---|---|
| `url` | string | required | Seed URL |
| `limit` | number | `5000` | Max URLs (1–50000) |
| `includeSubdomains` | boolean | `false` | Also return `*.seed-domain.com` URLs |

## Common Patterns

**Count URLs:**
```bash
curl -sf -X POST "http://localhost:3000/v1/map" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}' | jq '.total'
```

**Filter by path prefix:**
```bash
curl -sf -X POST "http://localhost:3000/v1/map" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}' | jq -r '.links[]' | grep '/blog/'
```

**Save URL list:**
```bash
HOST="docs.example.com"
TS=$(date +%Y%m%d-%H%M%S)
OUT="${CRAWLIT_OUTPUT_DIR:-./crawlit-output}/map"
mkdir -p "$OUT"
curl -sf -X POST "http://localhost:3000/v1/map" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"https://$HOST\",\"limit\":5000}" \
  | jq -r '.links[]' > "$OUT/${HOST}-${TS}.txt"
echo "Saved: $OUT/${HOST}-${TS}.txt ($(wc -l < "$OUT/${HOST}-${TS}.txt") URLs)"
```

**Feed top N URLs into scrape loop:**
```bash
curl -sf -X POST "http://localhost:3000/v1/map" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}' \
  | jq -r '.links[]' | head -10 | while read -r url; do
    curl -sf -X POST "http://localhost:3000/v1/scrape" \
      -H "Content-Type: application/json" \
      -d "{\"url\":\"$url\",\"formats\":[\"markdown\"]}" \
      | jq -r '.data.markdown'
  done
```

**Include subdomains:**
```bash
curl -sf -X POST "http://localhost:3000/v1/map" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com","limit":5000,"includeSubdomains":true}' \
  | jq '.total'
```

## Using Map to Plan a Crawl

Before running `crawlit-crawl`, map first to size the job:

```bash
TOTAL=$(curl -sf -X POST "http://localhost:3000/v1/map" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://docs.example.com"}' | jq '.total')
echo "Site has $TOTAL URLs"
# If $TOTAL < 200: crawl all with limit=$TOTAL
# If $TOTAL > 200: crawl subset or filter paths first
```

## Limitations

- Sitemap-sourced URLs may be stale (not reflecting recent pages)
- Link extraction from seed page only covers links on that one page (not deep links)
- No page content returned — use `crawlit-scrape` for content

## See Also

- [crawlit](../crawlit/SKILL.md) — pre-flight check + workflow decision
- [crawlit-scrape](../crawlit-scrape/SKILL.md) — get content for a URL found via map
- [crawlit-crawl](../crawlit-crawl/SKILL.md) — bulk content from many pages
