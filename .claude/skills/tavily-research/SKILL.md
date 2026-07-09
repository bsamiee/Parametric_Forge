---
name: tavily-research
description: >-
  Comprehensive AI-powered research with citations via the Tavily CLI: a structured report
  grounded in web sources, taking 30-120 seconds. Use for deep research, detailed reports,
  comparisons, market analysis, or literature review — "research", "investigate", "analyze
  in depth", "compare X vs Y", "what does the market look like for" — whenever multi-source
  synthesis with explicit citations is the deliverable. Quick fact-finding and filtered
  lookups belong to tavily-dynamic-search.
allowed-tools: Bash(uvx *)
---

# [TAVILY_RESEARCH]

AI-powered deep research that gathers sources, analyzes them, and returns a cited report in 30-120 seconds. Invocation rides `uvx --from tavily-cli tvly research …` with ambient `TAVILY_API_KEY`; the tavily-dynamic-search skill owns the family invocation law.

## [01]-[USAGE]

```bash
# Basic research (waits for completion)
uvx --from tavily-cli tvly research "competitive landscape of AI code assistants"

# Pro model for comprehensive analysis
uvx --from tavily-cli tvly research "electric vehicle market analysis" --model pro

# Stream results in real time
uvx --from tavily-cli tvly research "AI agent frameworks comparison" --stream

# Save report to file
uvx --from tavily-cli tvly research "fintech consolidation" --model pro -o fintech-report.md

# JSON output for agents; stdin query
uvx --from tavily-cli tvly research "quantum computing breakthroughs" --json
echo "query" | uvx --from tavily-cli tvly research - --json
```

## [02]-[OPTIONS]

| [INDEX] | [OPTION]            | [EFFECT]                                        |
| :-----: | :------------------ | :----------------------------------------------- |
|  [01]   | `--model`           | `mini`, `pro`, or `auto` (default)              |
|  [02]   | `--stream`          | Stream results in real time                     |
|  [03]   | `--no-wait`         | Return `request_id` immediately (async)         |
|  [04]   | `--output-schema`   | Path to a JSON schema for structured output     |
|  [05]   | `--citation-format` | `numbered`, `mla`, `apa`, `chicago`             |
|  [06]   | `--poll-interval`   | Seconds between status checks (default 10)      |
|  [07]   | `--timeout`         | Max wait seconds (default 600)                  |
|  [08]   | `-o, --output`      | Save output to file                             |
|  [09]   | `--json`            | Structured JSON output                          |

## [03]-[MODEL_SELECTION]

| [INDEX] | [MODEL] | [OWNS]                                   | [LATENCY]  |
| :-----: | :------ | :---------------------------------------- | :--------- |
|  [01]   | `mini`  | Single-topic, targeted research           | ~30s       |
|  [02]   | `pro`   | Comprehensive multi-angle analysis        | ~60-120s   |
|  [03]   | `auto`  | API-chosen by query complexity            | Varies     |

A "what does X do" question rides `mini`; an "X vs Y vs Z" or "best way to" question rides `pro`. `--output-schema` binds the report to a custom JSON shape when a machine consumes it.

## [04]-[ASYNC]

Long-running research starts detached and polls separately:

```bash
uvx --from tavily-cli tvly research "topic" --no-wait --json          # returns request_id
uvx --from tavily-cli tvly research status <request_id> --json
uvx --from tavily-cli tvly research poll <request_id> --json -o result.json
```

Quick facts route to tavily-dynamic-search; a self-directed corpus build over one site routes to tavily-crawl.
