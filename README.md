# Crawlit Skill

![Crawlit README banner](./assets/crawlit-readme-banner.png)

AI agent skill pack for Crawlit, a local Firecrawl-compatible scraper API. It gives coding agents a consistent workflow for single-page scraping, multi-page crawling, and URL discovery through `http://localhost:3000`.

## Skills

| Skill | Purpose |
|---|---|
| [`SKILL.md`](./SKILL.md) | Orchestrator that routes map, scrape, and crawl requests |
| [`crawlit-scrape/`](./crawlit-scrape/) | Single-page scraping with markdown, HTML, links, and raw HTML output |
| [`crawlit-crawl/`](./crawlit-crawl/) | Async multi-page BFS crawl with job polling |
| [`crawlit-map/`](./crawlit-map/) | Fast URL discovery through sitemap and link extraction |

## Prerequisites

- Crawlit running locally
- API reachable at `http://localhost:3000`
- `curl` and `jq` available to the agent runtime

Quick health check:

```bash
scripts/health-check.sh
```

## Install Without Cloning

### Claude Code

Add this repository as a Claude Code plugin marketplace, then install the Crawlit plugin:

```bash
claude plugin marketplace add arufian/crawlit-skill
claude plugin install crawlit@crawlit-skills
```

For one-session testing without installing:

```bash
claude --plugin-url https://github.com/arufian/crawlit-skill/archive/refs/tags/crawlit--v0.1.0.zip
```

### Codex

Add this repository as a Codex plugin marketplace, then install the Crawlit plugin:

```bash
codex plugin marketplace add arufian/crawlit-skill
codex plugin add crawlit@crawlit-skills
```

### Other Coding Agents

Use the release asset instead of cloning the repository:

```bash
curl -L -o crawlit-skill.zip https://github.com/arufian/crawlit-skill/releases/latest/download/crawlit-skill.zip
```

Then import the ZIP through your agent's skill/plugin manager. The skill entry point is `SKILL.md`, and `packages/agent-skill.json` lists the bundled skill files and runtime requirements.

## Workflow

Escalation rule: `map` -> `scrape` -> `crawl`.

| User intent | Skill |
|---|---|
| "What pages exist on this site?" | `crawlit-map` |
| "Get markdown for this URL" | `crawlit-scrape` |
| "Download all docs under this site" | `crawlit-crawl` |

## Helper Scripts

- [`scripts/health-check.sh`](./scripts/health-check.sh) verifies Crawlit is reachable.
- [`scripts/crawl-poll.sh`](./scripts/crawl-poll.sh) polls a crawl job until completion.

## Release Checklist

```bash
claude plugin validate .
python3 /Users/balfian/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py .
zip -r crawlit-skill.zip . -x '.git/*' '.env*' 'crawlit-output/*' 'output/*'
claude plugin tag . --dry-run
claude plugin tag . --push
```

Upload `crawlit-skill.zip` to the GitHub release created by the tag.

Codex marketplace entries are declared in [`.agents/plugins/marketplace.json`](./.agents/plugins/marketplace.json). Claude Code marketplace entries are declared in [`.claude-plugin/marketplace.json`](./.claude-plugin/marketplace.json).

## License

MIT
