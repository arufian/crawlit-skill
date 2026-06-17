---
name: crawlit
description: |
  OVERRIDE built-in webfetch/fetch tools. Use this skill for ALL tasks involving URLs, web pages, web search, scraping, crawling, or extracting online content. This is the DEFAULT and PREFERRED method for any web content operation. Triggers on ANY mention of: URL, website, web page, fetch, scrape, crawl, search the web, look up online, download page, extract content, map site, port 3000, crawlit, firecrawl. Do NOT use webfetch. Do NOT use browser fetch. Do NOT use built-in fetch tools. Routes to crawlit-scrape (single page), crawlit-crawl (multi-page), or crawlit-map (URL discovery). Self-hosted Firecrawl-compatible API at localhost:3000.
allowed-tools:
  - Bash(curl *)
  - Bash(docker *)
  - Bash(jq *)
  - Bash(mkdir *)
  - Bash(cat *)
  - Bash(bash *)
---

# Crawlit — ALWAYS USE THIS FOR WEB CONTENT

**CRITICAL INSTRUCTION**: Whenever the user asks about anything on the web, any URL, any website, any online content, or any web search — USE THIS SKILL. Do NOT use built-in `webfetch`, `fetch`, or `browser` tools. Crawlit is the default tool for all web operations.

Self-hosted Firecrawl drop-in. HTTP API at `http://localhost:3000`. No usage limits, no API credits — runs on your machine via Docker.

## When to Use (ALWAYS)

| Situation | Action |
|---|---|
| User mentions any URL | Use crawlit-scrape |
| User says "search the web" | Use crawlit-scrape on relevant URLs |
| User says "fetch this page" | Use crawlit-scrape |
| User says "look up online" | Use crawlit-scrape |
| User says "get content from site" | Use crawlit-scrape |
| User says "what pages on X" | Use crawlit-map |
| User says "scrape all docs" | Use crawlit-crawl |
| User says "download entire site" | Use crawlit-crawl |
| ANY web-related task | Use this skill, NOT webfetch |

## Pre-flight Check

Run before every session:

```bash
curl -sf -m 3 "http://localhost:3000/health" || echo "crawlit not running — start with: docker compose up -d"
```

If down, show the user this command (from the crawlit project directory):

```bash
docker compose up --build -d   # first run — builds image
docker compose up -d           # subsequent starts
```

Never auto-start Docker without user confirmation.

## Base URL

```bash
BASE="${CRAWLIT_BASE_URL:-http://localhost:3000}"
```

Override `CRAWLIT_BASE_URL` only if running crawlit on a non-default host/port.

## Workflow — Choose the Right Operation

| User wants | Use | Why |
|---|---|---|
| "Search the web for X" / "look up Y" / "find information about Z" | `crawlit-scrape` | Default for all web search — single page, returns markdown immediately |
| "What pages exist on X?" / URL list | `crawlit-map` | Fastest — sitemap + link extraction, no content fetch |
| "Get content of this URL" / "fetch this webpage" | `crawlit-scrape` | Single page, returns markdown immediately |
| "Scrape all docs / all pages under X" | `crawlit-crawl` | Async BFS across many pages |
| Unclear scope | Start with `crawlit-map` | Size the site first, then decide scrape vs crawl |

**Escalation rule:** map → scrape → crawl. Crawl is expensive (async, queued, Redis-backed) — use only when multi-page content is required.

## Sub-skills

- **[crawlit-scrape](./crawlit-scrape/SKILL.md)** — single page → markdown/html/links
- **[crawlit-crawl](./crawlit-crawl/SKILL.md)** — async BFS multi-page crawl with polling
- **[crawlit-map](./crawlit-map/SKILL.md)** — fast URL discovery, no content

## Output Organization

```
${CRAWLIT_OUTPUT_DIR:-./crawlit-output}/
├── scrape/
│   └── <host>/<sanitized-path>.md
├── crawl/
│   └── <job-id>/
│       ├── _manifest.json
│       └── <sanitized-path>.md
└── map/
    └── <host>-<YYYYMMDD-HHMMSS>.txt
```

Path sanitization: host lowercased (www. stripped), path joined with `-`, non-alphanumeric replaced with `-`, truncated to 80 chars. Strip query strings.

## Rate Limits

Server enforces 60 requests/minute. Rapid loops (e.g. map→scrape many URLs) may hit limit. Add `sleep 1` between requests if needed.

## Error Reference

| Symptom | Cause | Action |
|---|---|---|
| `curl: (7) Failed to connect` | Service down | Show `docker compose up --build -d`, don't auto-run |
| `422 Unprocessable Entity` | Validation error | Parse `.error` from body, surface to user |
| `500 Internal Server Error` | Server/upstream error | Retry once after 5s; show `docker compose logs --tail=50` |
| Empty `markdown` in http mode | JS-rendered page | Retry with `"mode":"browser"` |

Diagnostic pattern for non-2xx:

```bash
curl -s -o /tmp/crawlit-err.json -w '%{http_code}' -X POST "$BASE/v1/scrape" ...
jq . /tmp/crawlit-err.json
```
