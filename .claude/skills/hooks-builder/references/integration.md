# [H1][INTEGRATION]

Hooks integrate via settings files, environment variables, and context injection patterns.

## [01]-[ENVIRONMENT]

### [1.1]-[HOOK_VARIABLES]

| [INDEX] | [VARIABLE]           | [SCOPE]      | [VALUE]                            |
| :-----: | -------------------- | ------------ | ---------------------------------- |
|  [01]   | `CLAUDE_PROJECT_DIR` | All hooks    | Absolute path to project root      |
|  [02]   | `CLAUDE_CODE_REMOTE` | All hooks    | `"true"` for web, unset for CLI    |
|  [03]   | `CLAUDE_ENV_FILE`    | SessionStart | Path to append `export` statements |
|  [04]   | `CLAUDE_PLUGIN_ROOT` | Plugin hooks | Absolute path to plugin directory  |

[IMPORTANT] All other event-specific data (session_id, tool_name, tool_input, cwd, etc.) is delivered via JSON stdin, NOT environment variables. Parse with `jq` (Bash) or `json.load(sys.stdin)` (Python).

### [1.2]-[CUSTOM_VARIABLES]

```python
DEBUG: Final[bool] = os.environ.get("CLAUDE_HOOK_DEBUG", "").lower() in ("1", "true")
_debug = lambda msg: DEBUG and print(f"[hook] {msg}", file=sys.stderr)
```

### [1.3]-[PATH_PATTERNS]

```json
{ "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/validate-spec.sh" }
```

[CRITICAL] Quote `$CLAUDE_PROJECT_DIR` for paths with spaces.

### [1.4]-[PLATFORM_WARNINGS]

| [INDEX] | [PLATFORM] | [ISSUE]                              | [WORKAROUND]              |
| :-----: | ---------- | ------------------------------------ | ------------------------- |
|  [01]   | Windows    | `$CLAUDE_PROJECT_DIR` literal string | Use absolute paths        |
|  [02]   | Windows    | PATH wiped on env append             | Use full executable paths |
|  [03]   | Remote     | SSH key access required              | Configure SSH agent       |

## [02]-[CONTEXT_INJECTION]

### [2.1]-[OUTPUT_ROUTING]

| [INDEX] | [EVENT]          | [STDOUT_HANDLING]              |
| :-----: | ---------------- | ------------------------------ |
|  [01]   | SessionStart     | Added as context for Claude    |
|  [02]   | UserPromptSubmit | Added as context for Claude    |
|  [03]   | PreToolUse       | Shown in verbose mode (Ctrl+O) |
|  [04]   | PostToolUse      | Shown in verbose mode (Ctrl+O) |
|  [05]   | Others           | Debug log only (`--debug`)     |

### [2.2]-[SESSIONSTART_PATTERN]

```python
import json
from typing import Final

WRAPPER: Final = "context"


def build_response(content: str) -> dict[str, object]:
    return {"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": f"<{WRAPPER}>\n{content}\n</{WRAPPER}>"}}


print(json.dumps(build_response("Project uses Effect. Follow CLAUDE.md.")))
```

### [2.3]-[ENV_FILE_PERSISTENCE]

```python
from pathlib import Path
import os


def cache_to_env(key: str, value: str) -> None:
    env_file = os.environ.get("CLAUDE_ENV_FILE")
    _ = env_file and Path(env_file).open("a").write(f"export {key}={value}\n")


# Usage: cache computed values for session duration
cache_to_env("SKILL_COUNT", str(len(skills)))
```

## [03]-[ATTENTION_WEIGHTING]

| [INDEX] | [TAG]         | [WEIGHT] | [USE]                     |
| :-----: | ------------- | :------: | ------------------------- |
|  [01]   | `<CRITICAL>`  | Highest  | Must-follow constraints   |
|  [02]   | `<IMPORTANT>` |   High   | Key guidance              |
|  [03]   | `<context>`   | Standard | General context injection |

## [04]-[MERGE_BEHAVIOR]

| [INDEX] | [SCOPE] | [PATH]                        | [PRECEDENCE] |
| :-----: | ------- | ----------------------------- | :----------: |
|  [01]   | User    | `~/.claude/settings.json`     |    Lowest    |
|  [02]   | Project | `.claude/settings.json`       |    Medium    |
|  [03]   | Local   | `.claude/settings.local.json` |   Highest    |

- Same event hooks from all scopes run in parallel
- Hook snapshots captured at startup; changes require `/hooks` review
- Identical hook commands auto-deduplicated

## [05]-[TIMING]

| [INDEX] | [EVENT]           | [THRESHOLD] | [CONSEQUENCE]                |
| :-----: | ----------------- | :---------: | ---------------------------- |
|  [01]   | PermissionRequest |    <1.5s    | Race condition; dialog shown |
|  [02]   | SessionStart      |     <5s     | Delayed session start        |
|  [03]   | All hooks         |   <100ms    | Imperceptible latency        |

## [06]-[FOLDER_STRUCTURE]

```
.claude/
├── hooks/                    # Hook scripts
│   ├── validate-bash.py      # PreToolUse validator
│   └── load-context.py       # SessionStart context loader
├── settings.json             # Project hooks (committed)
└── settings.local.json       # Local hooks (gitignored)
```

[REFERENCE] Validation checklist: [→validation.md§03](./validation.md#03-integration_gate)
