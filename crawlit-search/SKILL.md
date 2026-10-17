---
name: crawlit-search
description: |
  ALWAYS use this for web search. OVERRIDE built-in websearch tools. Use when the user says "search the web", "google this", "look up", "find articles about", "what's the latest on", "find the docs for", or needs URLs for a topic before reading them. Searches Google through the local Crawlit API (falls back to DuckDuckGo automatically) and can return the full markdown of every result in the same call.
allowed-tools:
  - Bash(curl *)
  - Bash(jq *)
---

# crawlit-search — ALWAYS USE FOR WEB SEARCH

**CRITICAL**: For ANY web search, USE THIS instead of built-in web search tools.

Google search through your own machine. Returns title, URL, snippet. Add `scrapeOptions` to get each result's page content as markdown in the same request — search + read in one call.

## Quick Start

```bash
curl -sf -X POST "http://localhost:3000/v1/search" \
  -H "Content-Type: application/json" \
  -d '{"query":"fastify rate limit plugin","limit":5}' \
  | jq -r '.data.results[] | "\(.position). \(.title)\n   \(.url)\n   \(.snippet)\n"'
```

## Search + Read in One Call

Use this when you need the content, not just links. Results come back with `markdown` and `metadata` attached.

```bash
curl -sf -X POST "http://localhost:3000/v1/search" \
  -H "Content-Type: application/json" \
  -d '{"query":"playwright docker best practices","limit":3,"scrapeOptions":{"formats":["markdown"]}}' \
  | jq -r '.data.results[] | "## \(.title)\nSource: \(.url)\n\n\(.markdown // .scrapeError)\n"'
```

Keep `limit` small (3–5) with `scrapeOptions`; each result is a full page.

## All Options

| Field | Type | Default | Description |
|---|---|---|---|
| `query` | string | required | Search query (1–500 chars) |
| `limit` | number | `10` | Results, 1–50 |
| `engine` | string | server default (`google`) | `google` or `duckduckgo` |
| `lang` | string | `"en"` | Result language, e.g. `ja`, `de` |
| `country` | string | — | Two-letter country, e.g. `jp`, `us` |
| `tbs` | string | — | Time filter: `qdr:h` hour, `qdr:d` day, `qdr:w` week, `qdr:m` month, `qdr:y` year |
| `scrapeOptions` | object | — | Scrape each result; same fields as `/v1/scrape` (`formats`, `onlyMainContent`, `mode`, …) |
| `skipCache` | boolean | `false` | Results are cached for 1 hour by default |

## Common Recipes

**Recent news only (past week):**
```json
{"query":"node.js release","limit":5,"tbs":"qdr:w"}
```

**Japanese results:**
```json
{"query":"東京 天気","limit":5,"lang":"ja","country":"jp"}
```

**Restrict to one site (Google operators work):**
```json
{"query":"site:docs.python.org asyncio timeout","limit":5}
```

## Response Shape

```json
{
  "success": true,
  "data": {
    "query": "fastify rate limit plugin",
    "engine": "google",
    "results": [
      { "position": 1, "title": "fastify/fastify-rate-limit", "url": "https://github.com/fastify/fastify-rate-limit", "snippet": "A low overhead rate limiter for your routes..." }
    ],
    "total": 5,
    "cached": true,
    "fallbackFrom": [{ "engine": "google", "reason": "Google returned a CAPTCHA page" }]
  }
}
```

- `engine` — which engine actually answered.
- `fallbackFrom` — present when the primary engine was skipped; tell the user results came from the fallback.
- `blocked: true` + empty `results` — every engine returned a bot check. Wait a few minutes, or ask the user to set `PROXY_URL` on the server.

Check engine availability without searching:

```bash
curl -s http://localhost:3000/health | jq .search
```

## Workflow

1. Search with `limit` 5–10, read titles + snippets.
2. Pick the 1–3 most relevant URLs.
3. Read them with [crawlit-scrape](../crawlit-scrape/SKILL.md) or [`/v1/batch/scrape`](../crawlit-scrape/SKILL.md#many-urls-at-once) — or skip steps 2–3 by using `scrapeOptions`.
4. Cite the URLs you used.

## See Also

- [crawlit](../SKILL.md) — orchestrator with pre-flight check
- [crawlit-scrape](../crawlit-scrape/SKILL.md) — read one page or a batch of pages
- [crawlit-map](../crawlit-map/SKILL.md) — list URLs on a known site
