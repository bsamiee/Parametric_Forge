---
name: tavily-map
description: >-
  Discover and list all URLs on a website without extracting content, via the Tavily CLI —
  faster than crawling, returns URLs only. Use to find a specific page on a large site, list
  site structure, or locate where something lives on a domain — "map the site", "find the URL
  for", "what pages are on", "list all pages", "site structure". Essential when the site is
  known but the exact page is not; pair with tavily-extract for the content. Bulk content
  across many pages belongs to tavily-crawl.
allowed-tools: Bash(uvx *)
---

# [TAVILY_MAP]

Discover URLs on a website with no content extraction — the reconnaissance step before extracting or crawling. Invocation rides `uvx --from tavily-cli tvly map …` with ambient `TAVILY_API_KEY`; the tavily-dynamic-search skill owns the family invocation law.

## [01]-[USAGE]

```bash
# Discover all URLs
uvx --from tavily-cli tvly map "https://docs.example.com" --json

# Natural-language filtering
uvx --from tavily-cli tvly map "https://docs.example.com" --instructions "Find API docs and guides" --json

# Filter by path
uvx --from tavily-cli tvly map "https://example.com" --select-paths "/blog/.*" --limit 500 --json

# Deep map
uvx --from tavily-cli tvly map "https://example.com" --max-depth 3 --limit 200 --json
```

## [02]-[OPTIONS]

| [INDEX] | [OPTION]                                 | [EFFECT]                                     |
| :-----: | :--------------------------------------- | :------------------------------------------- |
|  [01]   | `--max-depth`                            | Levels deep, 1-5 (default 1)                 |
|  [02]   | `--max-breadth`                          | Links per page (default 20)                  |
|  [03]   | `--limit`                                | Max URLs to discover (default 50)            |
|  [04]   | `--instructions`                         | Natural-language guidance for URL discovery  |
|  [05]   | `--select-paths` / `--exclude-paths`     | Comma-separated path regex include/exclude   |
|  [06]   | `--select-domains` / `--exclude-domains` | Comma-separated domain regex include/exclude |
|  [07]   | `--allow-external` / `--no-external`     | Include or drop external-domain links        |
|  [08]   | `--timeout`                              | Max wait, 10-150 seconds                     |
|  [09]   | `-o, --output`                           | Save output to file                          |
|  [10]   | `--json`                                 | Structured JSON output                       |

## [03]-[MAP_THEN_EXTRACT]

Map finds the right page, extract pulls it — cheaper than crawling an entire site when only a few pages matter:

```bash
# Step 1: locate the authentication docs
uvx --from tavily-cli tvly map "https://docs.example.com" --instructions "authentication" --json

# Step 2: extract the specific page found
uvx --from tavily-cli tvly extract "https://docs.example.com/api/authentication" --json
```

`--instructions` covers semantic filtering where path patterns fall short. Content for many pages at once routes to tavily-crawl; pages on an unknown site route to tavily-dynamic-search first.
