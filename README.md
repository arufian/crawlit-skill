# Crawlit Skill

![Crawlit README banner](./assets/crawlit-readme-banner.png)

AI agent skill pack for [Crawlit](https://github.com/arufian/Crawlit), a local Firecrawl-compatible scraper API. See the Crawlit web page at [labs.arufian.dev/crawlit](https://labs.arufian.dev/crawlit/). This skill gives coding agents a consistent workflow for single-page scraping, multi-page crawling, and URL discovery through `http://localhost:3000`.

## Skills

| Skill | Purpose |
|---|---|
| [`SKILL.md`](./SKILL.md) | Orchestrator that routes map, scrape, and crawl requests |
| [`crawlit-scrape/`](./crawlit-scrape/) | Single-page scraping with markdown, HTML, links, and raw HTML output |
| [`crawlit-crawl/`](./crawlit-crawl/) | Async multi-page BFS crawl with job polling |
| [`crawlit-map/`](./crawlit-map/) | Fast URL discovery through sitemap and link extraction |

## Prerequisites

- [Crawlit](https://github.com/arufian/Crawlit) running locally
- Crawlit web page: [labs.arufian.dev/crawlit](https://labs.arufian.dev/crawlit/)
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
claude --plugin-url https://github.com/arufian/crawlit-skill/archive/refs/tags/crawlit--v0.1.1.zip
```

### Codex

Add this repository as a Codex plugin marketplace, then install the Crawlit plugin:

```bash
codex plugin marketplace add arufian/crawlit-skill
codex plugin add crawlit@crawlit-skills
```

### Agent Skills CLI

```bash
gh skill install arufian/crawlit-skill skills/crawlit --agent codex --scope user
```

Use a different `--agent` value for other supported coding agents, for example:

```bash
gh skill install arufian/crawlit-skill skills/crawlit --agent opencode --scope user
gh skill install arufian/crawlit-skill skills/crawlit --agent claude-code --scope user
gh skill install arufian/crawlit-skill skills/crawlit --agent cursor --scope user
```

Preview before installing:

```bash
gh skill preview arufian/crawlit-skill skills/crawlit
```

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
gh skill publish --dry-run
claude plugin tag . --dry-run
claude plugin tag . --push
```

Codex marketplace entries are declared in [`.agents/plugins/marketplace.json`](./.agents/plugins/marketplace.json). Claude Code marketplace entries are declared in [`.claude-plugin/marketplace.json`](./.claude-plugin/marketplace.json).

## License

MIT
