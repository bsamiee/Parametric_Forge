---
name: tavily-extract
description: >-
    Extract clean markdown or text from specific URLs via the Tavily CLI, up to 20 URLs per
    call, including JavaScript-rendered pages, with query-focused chunking for targeted
    retrieval. Use when one or more URLs are already in hand and their content is the need —
    "extract", "grab the content from", "pull the text from", "get the page at", "read this
    webpage". Finding pages without a URL belongs to tavily-dynamic-search; bulk extraction
    across a whole site belongs to tavily-crawl.
allowed-tools: Bash(uvx *)
---

# [TAVILY_EXTRACT]

Extract clean, LLM-optimized content from URLs already identified. Invocation rides `uvx --from tavily-cli tvly extract …` with ambient `TAVILY_API_KEY`; the tavily-dynamic-search skill owns the family invocation law.

## [01]-[USAGE]

```bash template
# Single URL
uvx --from tavily-cli tvly extract "https://example.com/article" --json

# Multiple URLs (max 20 per call; batch larger lists)
uvx --from tavily-cli tvly extract "https://example.com/page1" "https://example.com/page2" --json

# Query-focused extraction — relevant chunks only, not full pages
uvx --from tavily-cli tvly extract "https://example.com/docs" --query "authentication API" --chunks-per-source 3 --json

# JS-heavy pages
uvx --from tavily-cli tvly extract "https://app.example.com" --extract-depth advanced --json

# Save to file
uvx --from tavily-cli tvly extract "https://example.com/article" -o article.md
```

## [02]-[OPTIONS]

| [INDEX] | [OPTION]              | [EFFECT]                                                                      |
| :-----: | :-------------------- | :---------------------------------------------------------------------------- |
|  [01]   | `--query`             | Rerank chunks by relevance to this query                                      |
|  [02]   | `--chunks-per-source` | Chunks per URL, 1-5 (requires `--query`)                                      |
|  [03]   | `--extract-depth`     | `basic` (default) or `advanced` for JS-rendered SPAs, dynamic content, tables |
|  [04]   | `--format`            | `markdown` (default) or `text`                                                |
|  [05]   | `--include-images`    | Include image URLs                                                            |
|  [06]   | `--timeout`           | Max wait, 1-60 seconds                                                        |
|  [07]   | `-o, --output`        | Save output to file                                                           |
|  [08]   | `--json`              | Structured JSON output                                                        |

## [03]-[LANE_SELECTION]

- `basic` depth runs first; `advanced` binds only when content comes back missing — it is slower and costs more.
- `--query` plus `--chunks-per-source` returns only relevant chunks; full pages are the exception, not the default, when the result feeds an agent.
- A search that already ran with `--include-raw-content` carries the content; the extract step is skipped, not repeated.
- Site-wide needs route to tavily-crawl; URL discovery on a known site routes to tavily-map.
