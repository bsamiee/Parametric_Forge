# [VERIFICATION]

A hook is proven by replaying an exact-format payload on its stdin and asserting on the exit code or the stdout JSON — the harness never enters the loop. Replay is language-agnostic, subprocess-cheap, and CI-able, and it doubles as an audit tool for any third-party hook before it is trusted. Discipline is testing the block path, the allow path, and the malformed path together, since a gate that permits by crashing looks correct on the happy replay alone.

## [01]-[FIXTURE_REPLAY]

Pipe a fixture payload into the executable and read the exit code. A gate returns 2 on the dangerous fixture, 0 on the benign one, and 2 again on malformed input:

```bash test-only
printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' | ./pretooluse-gate.py; echo "block -> $?"
printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"npm test"}}' | ./pretooluse-gate.py; echo "allow -> $?"
printf '%s' 'not json at all' | ./pretooluse-gate.py; echo "malformed -> $?"
```

A stdout-JSON hook asserts on the parsed object instead — `... | ./session-context.py | jq -e '.hookSpecificOutput.additionalContext'`. That fixture is the same shape both providers deliver, so one replay set covers a dual-provider body; append `turn_id` to a fixture to prove the Codex overlay is ignored harmlessly.

## [02]-[THE_CASES]

Every hook carries these fixtures, and a gate carries dangerous cases paired against benign look-alikes, because a missed attack and a false alarm are the same failure:

- [BLOCK]: Payload the hook exists to stop returns exit 2 with a non-empty stderr reason.
- [ALLOW]: Benign look-alike returns 0 — `git checkout -b feature` against `git checkout -- file`, `myenvironment.txt` against `.env`, a path inside the sandbox against one that escapes it.
- [MALFORMED]: Non-JSON, an empty payload, and a payload missing the field the hook reads all hit the fail-closed path — a gate blocks, an observer exits 0.
- [OBFUSCATED]: `rm${IFS}-rf${IFS}/`, a quoted `"rm" -rf`, and a `bash -c 'rm -rf /'` wrapper prove the command-normalization move before matching (the command-decomposition recipe carries it).
- [LOOP]: A `Stop` fixture with `stop_hook_active: true` proves the continuation hook permits the second pass rather than livelocking.

## [03]-[RED_TEAM_HARNESS]

A single harness runs any hook against a fixture corpus and asserts the exit code, so it audits an external or gist hook without reading its source and regression-tests an owned hook on every edit. It runs in two modes — a spawned subprocess for real-world fidelity, an in-process call for a fast inner loop — and CI runs both so the fast path never diverges from spawn behavior. Each row reports `RULE`, `CASE`, `EXPECTED`, and `ACTUAL`, naming the offending policy on a miss.

That corpus is disciplined by pairing, not volume: every dangerous fixture ships with its benign twin, a benign fixture that blocks is the same defect class as a dangerous fixture that passes, and a merge gate binds the corpus to the rulebook — a new or changed policy row lands only with its paired fixture. Its runnable harness is the redteam-harness example, and the discipline generalizes past `PreToolUse`: a `SessionStart` injector replays with its `additionalContext` asserted, a `Stop` continuation replays with `stop_hook_active` set, so every event class carries the same audit.

## [04]-[TIMING_AND_RACES]

| [INDEX] | [PRESSURE]                          | [RESOLUTION]                                                                      |
| :-----: | :---------------------------------- | :-------------------------------------------------------------------------------- |
|  [01]   | `PermissionRequest` handlers        | ~100ms budget; keep it hot-path fast or intercept at `PreToolUse`                 |
|  [02]   | `UserPromptSubmit`/`MessageDisplay` | The event lowers the command-family timeout; the numbers are the config reference |
|  [03]   | Long test suites, deployments       | `async: true`, with `asyncRewake` when failure must wake the session              |
|  [04]   | Expensive session bootstraps        | Cache computed values through `$CLAUDE_ENV_FILE`                                  |

An async hook is proven by asserting it returns immediately and that its `additionalContext` arrives on the next turn, not the current one; a `PreToolUse` hot-path hook is timed against the ~100ms budget with `hyperfine` on the replay. A statistical multi-iteration run flags a hook drifting over budget or a `UserPromptSubmit` hook nearing the 10k-character context limit before it degrades every turn.

## [05]-[SYMPTOMS]

Three surfaces diagnose a live hook: `/hooks` browses every configured hook read-only — event, matcher, type, full command, and source (`User`, `Project`, `Local`, `Plugin`, `Session`, `Built-in`); `claude --debug` traces matching and execution; and `Ctrl+O` verbose mode shows hook output in the transcript. A hook is invisible in the transcript unless it exits non-zero, so a silent rewrite or block is the hardest class to diagnose — these three surfaces are how it is seen.

| [INDEX] | [SYMPTOM]                         | [CAUSE]                                   | [FIX]                                                 |
| :-----: | :-------------------------------- | :---------------------------------------- | :---------------------------------------------------- |
|  [01]   | Hook not registered               | Invalid JSON, a trailing comma            | Parse-check the settings file                         |
|  [02]   | Hook never fires                  | Exact-match path where regex was intended | Add `.*` or anchor; a bare `mcp__server` matches none |
|  [03]   | Hook fires on the wrong tools     | Unanchored `Edit.*` hits `NotebookEdit`   | Anchor as `^Edit$`                                    |
|  [04]   | Hook with `if` never runs         | `if` set on a non-tool event              | `if` binds only on tool events; else remove           |
|  [05]   | `permission denied`               | Script not executable                     | `chmod +x` the script                                 |
|  [06]   | JSON output ignored               | Exit code 2 alongside JSON                | JSON or exit codes, never both                        |
|  [07]   | JSON parse failure                | Shell-profile text on stdout              | Use exec form; stdout carries only the JSON object    |
|  [08]   | Block has no effect               | Exit 1 used as the failure signal         | Exit 1 is non-blocking; policy enforcement exits 2    |
|  [09]   | Async hook returns nothing        | Decision fields on an async hook          | It emits only `additionalContext`, next turn          |
|  [10]   | Injected context surfaces to user | Context phrased as a system command       | Phrase as a factual statement, not an imperative      |
|  [11]   | No desktop notification           | Escape sequence written to `/dev/tty`     | Return `terminalSequence` in JSON output              |
|  [12]   | Windows exec-form spawn fails     | `.cmd`/`.bat` shim named as `command`     | Spawn `node`, script path in `args`, or shell form    |
|  [13]   | Stale values after resume         | Mid-session `additionalContext` replays   | Refresh in `SessionStart` on resume                   |
|  [14]   | Stop-hook livelock                | Stop hook blocks unconditionally          | Read `stop_hook_active`; permit the second pass       |
|  [15]   | MCP tool hook errors at start     | `SessionStart`/`Setup` fire pre-connect   | The not-connected error on first run is non-blocking  |
|  [16]   | Codex hook skipped                | Untrusted hook SHA, or a `prompt` handler | Trust through `/hooks`; use a `command` handler       |

CI and `-p` runs pre-approve needed permissions in settings, so there is no interactive dialog; `Setup` fires only with `--init-only` or `--init`/`--maintenance` in `-p` mode, never on a regular start. Containers mount the project as a volume so `${CLAUDE_PROJECT_DIR}` resolves, and `$CLAUDE_CODE_REMOTE` distinguishes remote web from the local CLI.
