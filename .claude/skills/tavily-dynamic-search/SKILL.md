---
name: tavily-dynamic-search
description: >-
    Programmatic web search with context isolation: search the web, filter results in a local
    Python process, and let only curated print() output enter the context window. The default
    skill for web research. Triggered by "search for", "look up", "find", "research", "what's
    the latest on", or any query needing current web information, and by "search and filter",
    "find the important parts", or "extract the key details". Deep cited reports belong to
    tavily-research; pulling known URLs belongs to tavily-extract; indexed library and
    framework documentation belongs to context7-mcp.
allowed-tools: Bash(uvx *), Bash(python3 *), Bash(uv run *), Bash(jq *)
---

# [TAVILY_DYNAMIC_SEARCH]

Search the web, filter results, and extract content so that raw search data never enters the context window — only curated `print()` output comes back. A raw search with full page content returns hundreds of kilobytes of navigation, cookie banners, and boilerplate; processed inside a Python sandbox, the same query lands as one to three kilobytes of pure signal. The Python process is the sandbox: variables hold the raw data, `print()` is the only channel into context, and the filtering logic is written fresh per query.

Every `tvly` command runs as `uvx --from tavily-cli tvly …` — uv resolves and caches the CLI on first use, and auth reads the ambient `TAVILY_API_KEY` with no install step and no `tvly login`. This law covers the whole tavily family; the sibling skills compose it by name.

## [01]-[CORE_RULE]

Never run `tvly` as a bare command; always process output through Python so the context intake stays chosen, not inherited.

```bash rejected
uvx --from tavily-cli tvly search "quantum error correction" --json
```

```bash accepted
uvx --from tavily-cli tvly search "quantum error correction" --json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for r in data['results']:
    print(f'[{r[\"score\"]:.2f}] {r[\"title\"]}')
    print(f'  {r[\"url\"]}')
"
```

## [02]-[JSON_SCHEMAS]

Filtering code binds to these shapes.

`tvly search --json`:

```json template
{
    "query": "string",
    "answer": "string | null",
    "results": [
        {
            "url": "string",
            "title": "string",
            "content": "string (snippet, ~500-1500 chars)",
            "score": 0.0,
            "raw_content": "string | null (full page, only with --include-raw-content)"
        }
    ],
    "response_time": 0.0
}
```

`tvly extract --json`:

```json output-only
{
    "results": [
        {
            "url": "string",
            "title": "string",
            "raw_content": "string (full page markdown)",
            "images": []
        }
    ],
    "failed_results": [],
    "response_time": 0.0
}
```

## [03]-[EXECUTION_MODES]

Two building blocks compose freely: `tvly search` returns titles, URLs, snippets, and scores, with full pages under `--include-raw-content markdown`; `tvly extract` fetches full content for specific URLs already identified.

- [PIPE]: Simple filters of three to five lines pipe `tvly` output into `python3 -c`.
- [HEREDOC]: Anything more complex rides a single-quoted heredoc — one Bash call, clean multi-line Python, no escaping, no temp files. The default for most tasks.
- [SCRIPT]: A file on disk only when the same script runs across multiple turns; one-shot code is a heredoc, never a scratch file. Data saved for later turns belongs on disk; code does not.

```bash template
python3 << 'PYEOF'
import json, subprocess
raw = subprocess.check_output(
    ['uvx', '--from', 'tavily-cli', 'tvly', 'search', 'query', '--json'],
    stderr=subprocess.DEVNULL
)
data = json.loads(raw)
for r in data['results']:
    print(f"[{r['score']:.2f}] {r['title']}")
    print(f"  {r['url']}")
PYEOF
```

## [04]-[MULTI_TURN]

Open-ended research explores before it extracts: save raw results to a scratch file, triage titles, then write targeted extraction against what the triage revealed. The file is the persistent state between turns; the raw content never enters context. Known-keyword factual queries stay single-turn.

Turn one — search, save, triage:

```bash template
python3 << 'PYEOF'
import json, subprocess

raw = subprocess.check_output(
    ['uvx', '--from', 'tavily-cli', 'tvly', 'search', 'solid-state battery mass production 2026',
     '--include-raw-content', 'markdown', '--max-results', '8', '--json'],
    stderr=subprocess.DEVNULL
)
data = json.loads(raw)

with open('/tmp/tavily_results.json', 'w') as f:
    json.dump(data, f)

print(f'{len(data["results"])} results saved to /tmp/tavily_results.json\n')
for i, r in enumerate(data['results']):
    print(f'[{i}] [{r["score"]:.2f}] {r["title"][:90]}')
    print(f'    {r["url"]}')
    print(f'    {r["content"][:150]}')
    print()
PYEOF
```

Context receives a few hundred tokens of titles and snippets; the full page content sits on disk untouched.

Turn two — extract against the triage, with filtering logic written for this query:

```bash template
python3 << 'PYEOF'
import json

data = json.load(open('/tmp/tavily_results.json'))

for i in [0, 2, 5]:
    r = data['results'][i]
    raw = r.get('raw_content', '') or ''
    if not raw:
        continue

    print(f'## {r["title"]}')
    print(f'URL: {r["url"]}\n')

    for para in raw.split('\n\n'):
        para = para.strip()
        if len(para) > 80 and any(kw in para.lower() for kw in
                ['toyota', 'quantumscape', 'samsung', 'commercializ', 'production']):
            print(para)
            print()

    print('---\n')
PYEOF
```

Later turns chase leads the same way — re-search with sharper terms or `--include-domains`, extract a specific URL, keep appending data to disk while context stays lean:

```bash template
python3 << 'PYEOF'
import json, subprocess

raw = subprocess.check_output(
    ['uvx', '--from', 'tavily-cli', 'tvly', 'extract', 'https://example.com/article', '--json'],
    stderr=subprocess.DEVNULL
)
data = json.loads(raw)
content = data['results'][0].get('raw_content', '')

with open('/tmp/page_detail.txt', 'w') as f:
    f.write(content)

for line in content.split('\n'):
    if any(kw in line.lower() for kw in ['timeline', '2026', '2027', 'mass production']):
        print(line.strip())
PYEOF
```

## [05]-[FILTERING_LAW]

The Python written per query is the filtering logic; there are no fixed templates.

- [TRIAGE_FIRST]: Inspect titles and scores before fetching full pages; blind extraction floods disk and wastes calls.
- [MATCH_THE_QUERY]: A financial query filters for numbers and financial terms, a technical query for code blocks and specifications, a news query for dates and quotes.
- [STRUCTURAL_FLOOR]: Lines under roughly 50-80 characters are usually navigation; headings plus their following paragraphs carry the signal — starting points, adapted to what the page shows.
- [ERROR_RAILS]: Pages 404, extractions time out; `try/except` with `continue` skips failures without killing the pass.
- [TOKEN_BUDGET]: Target 150-600 printed tokens per source; a page printing thousands of characters is under-filtered unless it carries a critical data table.

A multi-angle pass runs several queries in one heredoc, deduplicates by URL, sorts by score, and prints one indexed triage — the shape in [04]-[MULTI_TURN] extends directly.

## [06]-[OPTIONS]

| [INDEX] | [OPTION]                      | [EFFECT]                                            |
| :-----: | :---------------------------- | :-------------------------------------------------- |
|  [01]   | `--max-results`               | Result count, 0-20 (default 5)                      |
|  [02]   | `--depth`                     | `ultra-fast`, `fast`, `basic` (default), `advanced` |
|  [03]   | `--topic`                     | `general`, `news`, `finance`                        |
|  [04]   | `--time-range`                | `day`, `week`, `month`, `year`                      |
|  [05]   | `--start-date` / `--end-date` | Absolute date bounds, `YYYY-MM-DD`                  |
|  [06]   | `--include-domains`           | Comma-separated allowlist                           |
|  [07]   | `--exclude-domains`           | Comma-separated blocklist                           |
|  [08]   | `--include-raw-content`       | Full page content, `markdown` or `text`             |
|  [09]   | `--include-answer`            | AI answer, `basic` or `advanced`                    |
|  [10]   | `--chunks-per-source`         | Chunks per source on `advanced`/`fast` depth        |
|  [11]   | `--country`                   | Boost results from a country                        |

## [07]-[JQ_FALLBACK]

When `python3` is unavailable, `jq` covers simple lookups only — no multi-step search-then-extract, no complex filtering:

```bash template
uvx --from tavily-cli tvly search "query" --json 2>/dev/null | jq '[.results[] | select(.score > 0.5) | {title, url, content}]'
```
