# [SCRIPTING]

A command hook is a boundary kernel: read one JSON payload on stdin, admit it once into a typed shape, decide, and emit the verdict through exactly one channel. The craft is packaging it as a self-contained single-file script, admitting the payload without threading provider shapes through the body, and respecting the hot-path budget the event imposes. Rails, closed families, and the lint gate are the Python stack's owned law and hold here without restatement; this page owns only what a hook adds to them.

## [01]-[PACKAGING]

A Python hook ships as a uv single-file script with PEP 723 inline metadata — no venv, no `requirements.txt`, dependencies resolved and cached per script. The shebang makes the file directly executable, and `chmod +x` is mandatory or the hook silently fails.

```python signature
#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
```

`msgspec` is the wire codec for payload admission; `httpx` joins it only in a transmitter or HTTP-calling hook, paired with `async: true` so network latency never stalls the loop. `uv add <pkg> --script <file>` edits the metadata block. The exec-form config (`args` present) spawns the file without a shell, so a shell-profile echo never corrupts the JSON channel.

## [02]-[ADMISSION]

The stdin JSON is the wire, admitted once into a `msgspec.Struct` at the top of the body; the interior reads typed attributes, never a `dict.get(...)` chain re-derived at each use, and never re-validates. A struct with `forbid_unknown_fields=False` tolerates the many payload fields a given hook ignores while typing the few it reads. Provider shapes stop at this line — `tool_input` admits into its own struct, and the body dispatches on `tool_name` through a `match`, not a nested-`get` ladder.

```python accepted
import sys

import msgspec


class ToolInput(msgspec.Struct, frozen=True):
    command: str = ""
    file_path: str = ""


class PreToolUse(msgspec.Struct, frozen=True, rename={"event": "hook_event_name"}):
    tool_name: str
    tool_input: ToolInput
    cwd: str = ""
    event: str = ""


def admit() -> PreToolUse | None:
    try:
        return msgspec.json.decode(sys.stdin.buffer.read(), type=PreToolUse)
    except (msgspec.DecodeError, msgspec.ValidationError):
        return None
```

## [03]-[CHANNELS]

Exactly one channel carries the verdict, and mixing them silently drops the JSON:

- [EXIT_CODE]: The blunt, portable path — exit 2 with a stderr reason blocks and behaves identically on both providers, exit 0 permits. Stderr is the model-facing reason; stdout stays empty. Every gate and guardrail rides this unless it must rewrite or inject.
- [STDOUT_JSON]: The scalpel — exit 0 with a single JSON object on stdout, nothing else. Carries `updatedInput`, `updatedToolOutput`, `additionalContext`, and the `permissionDecision`/`decision` surfaces. Guidance and diagnostics still go to stderr; a stray print to stdout is a parse failure.

The decision is a closed vocabulary the body dispatches over — a `StrEnum` or the exit integer itself keyed from a `frozendict`, never a boolean pair the caller re-pairs to an effect.

## [04]-[FAIL_CLOSED]

A malformed payload, an unparseable command, or a decode error is a block on a security gate and a silent exit 0 on an observer — the disposition is fixed at the seam, never left to a crash. A hook that raises exits non-zero-but-not-2, which is non-blocking, so a security check that crashes silently permits the very action it guards; catch the decode failure explicitly and route it to exit 2. A path check normalizes before comparing — `Path(p).resolve().is_relative_to(root)`, never `startswith` on the raw string, which both over- and under-matches — and a command check normalizes the command before matching, because raw substring matching misses `$IFS` and quote obfuscation (the fragments example carries the normalization move).

## [05]-[HOT_PATH]

`PreToolUse` and `PermissionRequest` gate the agentic loop, so their budget is under ~100ms and the matcher is narrow — a specific `tool_name`, never `.*`, which fires on every tool and taxes every turn. Slow work moves off the hot path: a full test suite, a CI probe, or a deployment rides `async: true` (fire-and-forget) or `asyncRewake: true` (wakes the session on exit 2 with stderr as a system reminder). `UserPromptSubmit` caps at 30 seconds and `MessageDisplay` at 10, so neither runs a network call inline. Expensive session bootstraps cache their computed values through `$CLAUDE_ENV_FILE` so later turns read the export rather than recomputing. Logging goes to a file or a transmitter, never stdout — stdout is the decision channel, and a hook that logs there corrupts its own verdict.
