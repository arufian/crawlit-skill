---
name: crawlit-scrape
description: |
  ALWAYS use this for ANY single web page content fetch. OVERRIDE built-in webfetch/fetch. Use when user mentions any URL, says "get content", "fetch page", "read website", "look up online", "download page", or any web search query requiring a specific URL. Returns clean markdown, html, links, or rawHtml from any URL. Supports browser mode for JS-heavy sites. This is the PREFERRED tool over webfetch for all URL fetching tasks.
allowed-tools:
  - Bash(curl *)
  - Bash(jq *)
  - Bash(mkdir *)
  - Bash(cat *)
---

# crawlit-scrape — ALWAYS USE FOR SINGLE PAGE FETCH

**CRITICAL**: For ANY task fetching a single web page, USE THIS instead of built-in `webfetch` or `fetch`.

Single page → clean markdown (or html/links/rawHtml). Returns immediately (synchronous).

## Quick Start

```bash
curl -sf -X POST "http://localhost:3000/v1/scrape" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com","formats":["markdown"]}' \
  | jq -r '.data.markdown'
```

## Mode Selection

The default `auto` mode fetches over plain HTTP and switches to the stealth browser by itself when the page is a JS app shell or a bot wall. You rarely need to set `mode`.

| Situation | Mode |
|---|---|
| Default — let Crawlit decide | omit `mode` (`"auto"`) |
| Must never launch a browser (fastest) | `"mode":"http"` |
| Content still missing in auto | `"mode":"browser"` + `"waitFor":2000` or `"waitForSelector":"..."` |
| Need to click/scroll/type first | `actions` (implies browser) |

The `x-crawlit-source` response header says what was used: `http`, `browser`, or `cache`.

## Many URLs at Once

Use `/v1/batch/scrape` instead of looping — one request, up to 100 URLs scraped in parallel. Takes every scrape option.

```bash
curl -sf -X POST "http://localhost:3000/v1/batch/scrape" \
  -H "Content-Type: application/json" \
  -d '{"urls":["https://example.com","https://books.toscrape.com/"],"formats":["markdown"]}' \
  | jq -r '.data[] | "## \(.url)\n\(.markdown // ("ERROR: " + .error))\n"'
```

Failed URLs come back with `success: false` and `error`; the others still succeed.

## All Options

| Field | Type | Default | Description |
|---|---|---|---|
| `url` | string | required | Target URL |
| `formats` | array | `["markdown"]` | `markdown`, `html`, `links`, `rawHtml` |
| `onlyMainContent` | boolean | `true` | Strip nav/ads via Readability |
| `mode` | string | `"auto"` | `auto`, `http`, or `browser` |
| `waitFor` | number | — | ms to wait after page load (implies browser) |
| `waitForSelector` | string | — | CSS selector to wait for (implies browser) |
| `actions` | array | — | Click/scroll/type sequence (implies browser) |
| `proxy` | string | — | Proxy URL `http://user:pass@host:port` |
| `save` | boolean | `false` | Save markdown to server's `./output/` dir |
| `extract` | object | — | LLM structured extraction (see below) |
| `skipCache` | boolean | `false` | Bypass Redis cache |
| `timeout` | number | `30000` | Request timeout in ms (1000–60000) |

## Common Recipes

**Main content only (strip nav/footer):**
```json
{"url":"https://example.com","formats":["markdown"],"onlyMainContent":true}
```

**Browser mode with JS wait:**
```json
{"url":"https://example.com","mode":"browser","waitFor":2000,"formats":["markdown"]}
```

**Click button then scrape:**
```json
{
  "url": "https://example.com",
  "mode": "browser",
  "actions": [
    {"type":"click","selector":"#load-more"},
    {"type":"wait","delay":1000},
    {"type":"scroll"}
  ],
  "formats": ["markdown"]
}
```

**Get markdown + links together:**
```json
{"url":"https://example.com","formats":["markdown","links"]}
```

**LLM structured extraction:**
```json
{
  "url": "https://news.ycombinator.com",
  "formats": ["markdown"],
  "extract": {
    "prompt": "Extract the top 5 story titles and their point counts",
    "schema": {
      "type": "object",
      "properties": {
        "stories": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "title": {"type":"string"},
              "points": {"type":"number"}
            }
          }
        }
      }
    }
  }
}
```

**Skip cache (force fresh fetch):**
```json
{"url":"https://example.com","skipCache":true}
```

## Output Handling

Save to local disk (client-side):

```bash
OUT="${CRAWLIT_OUTPUT_DIR:-./crawlit-output}/scrape"
HOST=$(echo "$URL" | sed 's|https\?://||;s|/.*||')
PATH_PART=$(echo "$URL" | sed 's|https\?://[^/]*||;s|/|__|g;s|^__||')
mkdir -p "$OUT/$HOST"
curl -sf -X POST "http://localhost:3000/v1/scrape" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"$URL\",\"formats\":[\"markdown\"]}" \
  | jq -r '.data.markdown' > "$OUT/$HOST/${PATH_PART:-index}.md"
echo "Saved: $OUT/$HOST/${PATH_PART:-index}.md"
```

For multiple formats (response is JSON when >1 format):
```bash
RESP=$(curl -sf -X POST "$BASE/v1/scrape" ... -d '{"url":"...","formats":["markdown","links"]}')
echo "$RESP" | jq -r '.data.markdown' > page.md
echo "$RESP" | jq '.data.links' > page.links.json
```

## Response Shape

```json
{
  "success": true,
  "data": {
    "metadata": { "title": "...", "description": "...", "url": "...", "statusCode": 200 },
    "markdown": "# Page Title\n\n...",
    "html": "<article>...</article>",
    "links": ["https://..."],
    "extract": { "...": "..." },
    "savedTo": "/app/output/example.com/index.md"
  }
}
```

## See Also

- [crawlit](../SKILL.md) — orchestrator with pre-flight check + workflow decision
- [crawlit-crawl](../crawlit-crawl/SKILL.md) — for multiple pages (async BFS)
- [crawlit-map](../crawlit-map/SKILL.md) — URL discovery without content
