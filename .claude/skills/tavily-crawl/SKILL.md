---
name: tavily-crawl
description: >-
    Crawl websites and extract content from many pages via the Tavily CLI, with depth and
    breadth control, path filtering, semantic instructions, and per-page markdown files on
    disk. Use to crawl a site, download documentation, extract an entire docs section, or
    bulk-extract pages — "crawl", "get all the pages", "download the docs", "extract everything
    under /docs", "bulk extract". Single known URLs belong to tavily-extract; URL discovery
    without content belongs to tavily-map.
allowed-tools: Bash(uvx *)
---

# [TAVILY_CRAWL]

Crawl a website and extract content from every discovered page, optionally saving each page as a local markdown file. Invocation rides `uvx --from tavily-cli tvly crawl …`; the tavily-dynamic-search skill owns the family invocation law.

## [01]-[USAGE]

```bash template
# Basic crawl
uvx --from tavily-cli tvly crawl "https://docs.example.com" --json

# Save each page as a markdown file
uvx --from tavily-cli tvly crawl "https://docs.example.com" --output-dir ./docs/

# Deeper crawl with limits
uvx --from tavily-cli tvly crawl "https://docs.example.com" --max-depth 2 --limit 50 --json

# Filter to specific paths
uvx --from tavily-cli tvly crawl "https://example.com" --select-paths "/api/.*,/guides/.*" --exclude-paths "/blog/.*" --json

# Semantic focus — relevant chunks, not full pages
uvx --from tavily-cli tvly crawl "https://docs.example.com" --instructions "Find authentication docs" --chunks-per-source 3 --json
```

## [02]-[OPTIONS]

| [INDEX] | [OPTION]                                 | [EFFECT]                                         |
| :-----: | :--------------------------------------- | :----------------------------------------------- |
|  [01]   | `--max-depth`                            | Levels deep, 1-5 (default 1)                     |
|  [02]   | `--max-breadth`                          | Links per page (default 20)                      |
|  [03]   | `--limit`                                | Total pages cap (default 50)                     |
|  [04]   | `--instructions`                         | Natural-language guidance for semantic focus     |
|  [05]   | `--chunks-per-source`                    | Chunks per page, 1-5 (requires `--instructions`) |
|  [06]   | `--extract-depth`                        | `basic` (default) or `advanced`                  |
|  [07]   | `--format`                               | `markdown` (default) or `text`                   |
|  [08]   | `--select-paths` / `--exclude-paths`     | Comma-separated path regex include/exclude       |
|  [09]   | `--select-domains` / `--exclude-domains` | Comma-separated domain regex include/exclude     |
|  [10]   | `--allow-external` / `--no-external`     | Include or drop external-domain links            |
|  [11]   | `--include-images`                       | Include images                                   |
|  [12]   | `--timeout`                              | Max wait, 10-150 seconds                         |
|  [13]   | `-o, --output`                           | Save JSON output to file                         |
|  [14]   | `--output-dir`                           | Save each page as a `.md` file in this directory |
|  [15]   | `--json`                                 | Structured JSON output                           |

## [03]-[LANE_SELECTION]

- [AGENTIC]: Results feeding an LLM always ride `--instructions` plus `--chunks-per-source` — relevant chunks instead of full pages, no context explosion.
- [COLLECTION]: Data collection to disk rides `--output-dir` without `--chunks-per-source` — full pages as markdown files.

```bash template
uvx --from tavily-cli tvly crawl "https://docs.example.com" --instructions "API authentication" --chunks-per-source 3 --json
uvx --from tavily-cli tvly crawl "https://docs.example.com" --max-depth 2 --output-dir ./docs/
```

## [04]-[SCOPE_CONTROL]

- A crawl starts conservative — `--max-depth 1`, `--limit 20` — and scales only after the shape of the site is known; `--limit` always binds to prevent runaway crawls.
- `--select-paths` narrows to the section that matters before depth grows.
- A tavily-map pass first reveals site structure when the target section is uncertain; a few specific pages route to tavily-extract instead of a crawl.
