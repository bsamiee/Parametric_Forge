# [TROUBLESHOOTING]

Symptom-indexed misconfiguration and platform behavior; diagnosis runs `claude --debug` for match/execution traces, `/hooks` for the live configuration and its source files, and `Ctrl+O` verbose mode for hook output in the transcript.

## [01]-[SYMPTOMS]

| [INDEX] | [SYMPTOM]                         | [CAUSE]                                                 | [FIX]                                                                        |
| :-----: | :-------------------------------- | :------------------------------------------------------ | :--------------------------------------------------------------------------- |
|  [01]   | Hook not registered               | Invalid JSON (trailing commas)                          | `python3 -c "import json; json.load(open('.claude/settings.json'))"`         |
|  [02]   | Hook never fires                  | Matcher on the exact-match path when regex was intended | Add `.*` or an anchored pattern; bare `mcp__server` matches no tool          |
|  [03]   | Hook fires on the wrong tools     | Unanchored regex (`Edit.*` also hits `NotebookEdit`)    | Anchor as `^Edit$`                                                           |
|  [04]   | Hook with `if` never runs         | `if` set on a non-tool event                            | `if` binds only on tool events; remove it elsewhere                          |
|  [05]   | `permission denied`               | Script not executable                                   | `chmod +x` the script                                                        |
|  [06]   | JSON output ignored               | Exit code 2 alongside JSON                              | One approach per hook: exit 0 with JSON, or exit codes alone                 |
|  [07]   | JSON parse failure                | Shell profile text on stdout                            | Stdout carries only the JSON object                                          |
|  [08]   | Block has no effect               | Exit 1 used as the failure signal                       | Exit 1 is non-blocking; policy enforcement exits 2                           |
|  [09]   | Async hook returns nothing        | Decision fields on an async hook                        | Async hooks never decide; only `additionalContext` delivers, next turn       |
|  [10]   | Injected context surfaces to user | Context phrased as system commands                      | Phrase as factual statements; imperative framing trips injection defenses    |
|  [11]   | No desktop notification           | Writing escape sequences to `/dev/tty`                  | Return `terminalSequence` in JSON output; hooks have no controlling terminal |
|  [12]   | Windows exec-form spawn fails     | `.cmd`/`.bat` shim named as `command`                   | Spawn `node` with the script path in `args`, or use shell form               |
|  [13]   | Stale values after resume         | Mid-session `additionalContext` replays from transcript | Refresh in `SessionStart`, which re-runs on resume with `source: "resume"`   |
|  [14]   | Stop-hook loop                    | Stop hook blocks unconditionally                        | Read `stop_hook_active` from input and permit the second pass                |
|  [15]   | MCP tool hook errors at start     | `SessionStart`/`Setup` fire before servers connect      | Expect the not-connected error on first run; it is non-blocking              |

## [02]-[TIMING]

| [INDEX] | [PRESSURE]                    | [BOUND] | [RESOLUTION]                                                    |
| :-----: | :---------------------------- | :------ | :-------------------------------------------------------------- |
|  [01]   | `PermissionRequest` handlers  | <1.5s   | Keep fast or intercept at `PreToolUse` instead                  |
|  [02]   | `UserPromptSubmit` commands   | 30s cap | The event lowers the command-family default timeout             |
|  [03]   | `MessageDisplay` commands     | 10s cap | The event lowers the command-family default timeout             |
|  [04]   | Long test suites, deployments | —       | `async: true`, with `asyncRewake` when failure must wake Claude |
|  [05]   | Expensive session bootstraps  | —       | Cache computed values through `$CLAUDE_ENV_FILE`                |

## [03]-[HEADLESS_AND_REMOTE]

- CI and `-p` runs pre-approve needed permissions in settings; there is no interactive dialog to answer.
- `Setup` fires only with `--init-only`, or `--init`/`--maintenance` in `-p` mode — never on a regular session start.
- Containers mount the project as a volume so `${CLAUDE_PROJECT_DIR}` resolves; `$CLAUDE_CODE_REMOTE` distinguishes remote web from the local CLI.
- A direct stdin test reproduces any hook outside the harness: `printf '%s' '{"tool_name":"Bash","tool_input":{"command":"npm test"}}' | ./hook.sh; echo $?`.
