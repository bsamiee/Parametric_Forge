# [H1][TROUBLESHOOTING]

Platform-specific bugs, timing issues, and configuration gotchas.

## [01]-[PLATFORM_ISSUES]

| [INDEX] | [PLATFORM] | [ISSUE]                       | [WORKAROUND]                        |
| :-----: | ---------- | ----------------------------- | ----------------------------------- |
|  [01]   | Windows    | `$CLAUDE_PROJECT_DIR` literal | Use absolute paths in command field |
|  [02]   | Windows    | PATH wiped on env append      | Use full executable paths           |
|  [03]   | Windows    | Shell expansion fails         | Write .bat wrapper scripts          |
|  [04]   | WSL        | Path translation issues       | Use `/mnt/c/` paths consistently    |
|  [05]   | Docker     | SSH key access required       | Mount SSH agent socket              |
|  [06]   | SSHFS      | Relative paths fail           | Use absolute paths only             |

### [1.1]-[WINDOWS_WORKAROUND]

```json
{
"command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/validate-spec.sh"
}
```

## [02]-[TIMING_ISSUES]

| [INDEX] | [ISSUE]                | [THRESHOLD] | [SOLUTION]                         |
| :-----: | ---------------------- | :---------: | ---------------------------------- |
|  [01]   | PermissionRequest race |    1.5s     | Keep hooks <1.5s or use PreToolUse |
|  [02]   | Duplicate execution    |      —      | Add file locking or deduplication  |
|  [03]   | SessionStart timeout   |     60s     | Cache expensive computations       |
|  [04]   | Slow network calls     |      —      | Use async or background processes  |

### [2.1]-[DEDUPLICATION_PATTERN]

```python
import fcntl, sys, contextlib
from pathlib import Path
from typing import Final

LOCK: Final = Path("/tmp/claude-hook.lock")


def _acquire_lock() -> bool:
    with contextlib.suppress(BlockingIOError):
        fcntl.flock(LOCK.open("w"), fcntl.LOCK_EX | fcntl.LOCK_NB)
        return True
    return False


_acquire_lock() or sys.exit(0)  # Another instance running
```

## [03]-[EXIT_CODE_GOTCHAS]

| [INDEX] | [CODE] | [DOCUMENTED]       | [ACTUAL]                         |
| :-----: | :----: | ------------------ | -------------------------------- |
|  [01]   |   0    | Success            | Success                          |
|  [02]   |   1    | Non-blocking error | **Blocks execution (bug #4809)** |
|  [03]   |   2    | Block              | Block action                     |
|  [04]   |   3+   | Non-blocking error | Non-blocking error               |

[CRITICAL] Use exit 0 for warnings. Exit 1 blocks despite documentation.

## [04]-[CONFIG_ISSUES]

| [INDEX] | [ISSUE]                       | [SYMPTOM]                     | [FIX]                        |
| :-----: | ----------------------------- | ----------------------------- | ---------------------------- |
|  [01]   | Trailing commas in JSON       | Hook not registered           | Validate JSON syntax         |
|  [02]   | Template variables `{{...}}`  | Variables not expanded        | Use env vars instead         |
|  [03]   | Changes after startup         | Old hooks still running       | Run `/hooks` to reload       |
|  [04]   | Missing executable permission | `permission denied` error     | `chmod +x script.py`         |
|  [05]   | Wrong shebang                 | `/usr/bin/env: bad interp`    | Use `#!/usr/bin/env python3` |
|  [06]   | /hooks shows "No hooks"       | Valid config ignored (#11544) | Check settings.json location |

## [05]-[REMOTE_EXECUTION]

| [INDEX] | [CONTEXT]         | [ISSUE]                    | [SOLUTION]                           |
| :-----: | ----------------- | -------------------------- | ------------------------------------ |
|  [01]   | SSH remote        | Hooks don't run            | Use `--dangerously-skip-permissions` |
|  [02]   | Docker            | `CLAUDE_PROJECT_DIR` wrong | Mount project as volume              |
|  [03]   | CI/CD             | No interactive approval    | Pre-approve in settings              |
|  [04]   | GitHub Codespaces | PATH issues                | Use absolute paths                   |

## [06]-[DEBUGGING]

| [INDEX] | [METHOD]           | [COMMAND]                                       |
| :-----: | ------------------ | ----------------------------------------------- |
|  [01]   | Enable debug mode  | `claude --debug`                                |
|  [02]   | List active hooks  | `/hooks`                                        |
|  [03]   | Test hook directly | `echo '{"tool_name":"Bash"}' \| python hook.py` |
|  [04]   | Check exit code    | `echo $?` after hook execution                  |
|  [05]   | View hook output   | Press `Ctrl+O` for verbose mode                 |

[REFERENCE] Validation checklist: [→validation.md§06](./validation.md#06-troubleshooting_gate)
