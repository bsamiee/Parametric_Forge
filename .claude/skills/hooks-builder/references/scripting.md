# [SCRIPTING]

A command hook is a boundary kernel: read one JSON payload on stdin, admit it once into a typed shape, decide, and emit the verdict through exactly one channel. The craft is packaging it as a self-contained single-file script, admitting the payload without threading provider shapes through the body, and respecting the hot-path budget the event imposes. Rails, closed families, and the lint gate are the Python stack's owned law and hold here without restatement; this page owns only what a hook adds to them. A hook script is a boundary kernel in the stack's own sense, so the host-API primitives its role forces — `os.environ` for placeholder env, `subprocess.run` for a probe or checker, `os.getcwd` for a fallback root — are admitted at this seam under the exemption the stack grants a measured kernel; the hook carries them behind its typed admission rather than reaching for a rail wrapper, and either declares the documented per-line suppression or stands outside the host project's lint scope, never both restating the ban and silently tripping it.

## [01]-[PACKAGING]

A Python hook ships as a uv single-file script with PEP 723 inline metadata — no venv, no `requirements.txt`, dependencies resolved and cached per script. The shebang makes the file directly executable, and `chmod +x` is mandatory or the hook silently fails.

```python signature
#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
```

`msgspec` is the wire codec for payload admission; `httpx` joins it only in a transmitter or HTTP-calling hook, always wired `async: true` so a synchronous POST never stalls the loop — a transmitter that posts inline is a blocking hook mislabeled, so the dependency and the wiring travel together. `uv add <pkg> --script <file>` edits the metadata block. The exec-form config (`args` present) spawns the file without a shell, so a shell-profile echo never corrupts the JSON channel.

A PEP 723 dependency resolves and caches on first invocation — a measured multi-second cost on a cold uv cache or after a prune. That resolution is a one-time environment cost, never a per-call one, and it is paid off the hot path: a `SessionStart` or `Setup` step runs `uv run --script <hook> </dev/null` once to warm the cache before the first gating call, or the persistent-daemon forwarder amortizes it across the fleet. The hot-path budget below measures a warm interpreter; a hook that first resolves its dependencies inside a `PreToolUse` firing blows the budget by orders of magnitude, which the warm step exists to prevent.

## [02]-[ADMISSION]

The stdin JSON is the wire, admitted once into a `msgspec.Struct` at the top of the body; the interior reads typed attributes, never a `dict.get(...)` chain re-derived at each use, and never re-validates. Structs tolerate unknown fields by default, so a hook types only the few fields it reads and the rest of the payload passes through unseen. Provider shapes stop at this line — `tool_input` admits into its own struct, and the body dispatches on `tool_name` through a `match`, not a nested-`get` ladder. The decode failure routes straight to the hook's fail-closed disposition at the same seam, so no `None` ever crosses into the interior:

Unknown-field tolerance is not shape tolerance on a declared field. A field whose payload shape varies across tools or providers — `tool_response`, `str` from one tool and an object `{stdout, stderr, ...}` from most built-ins — decodes hard against a fixed type annotation: a mismatch is a `msgspec.ValidationError`, a `DecodeError` subclass that the decode-seam `except` routes to fail-closed disposition, which on an observer is a silent exit 0 that no-ops the whole hook. So a declared field of varying shape is typed `msgspec.Raw` (or a union) and normalized inside the body — decoded once past the admission seam and reduced to the scannable value the interior needs — never annotated to one shape that silently discards every other. The official payload schema documents only a subset of tool response shapes, so the shape a field takes is confirmed by empirical per-tool replay, never assumed per tool.

```python accepted
import sys

import msgspec


class ToolInput(msgspec.Struct, frozen=True):
    command: str = ""
    file_path: str = ""


class PreToolUse(msgspec.Struct, frozen=True, rename={"event": "hook_event_name"}):
    tool_name: str = ""
    tool_input: ToolInput = msgspec.field(default_factory=ToolInput)
    cwd: str = ""
    event: str = ""


def main() -> int:
    try:
        payload = msgspec.json.decode(sys.stdin.buffer.read(), type=PreToolUse)
    except msgspec.DecodeError:
        print("malformed hook payload; failing closed", file=sys.stderr)
        return 2  # gate disposition; an observer returns 0 here instead
    return decide(payload)
```

## [03]-[CHANNELS]

Exactly one channel carries the verdict, and mixing them silently drops the JSON:

- [EXIT_CODE]: The blunt, portable path — exit 2 with a stderr reason blocks, and on the shared tool and prompt events it behaves identically on both providers; exit 0 permits. Stderr is the model-facing reason; stdout stays empty. Every gate and guardrail rides this unless it must rewrite or inject.
- [STDOUT_JSON]: The scalpel — exit 0 with a single JSON object on stdout, nothing else. Carries `updatedInput`, `updatedToolOutput`, `additionalContext`, and the `permissionDecision`/`decision` surfaces. Guidance and diagnostics still go to stderr; a stray print to stdout is a parse failure.

The decision is a closed vocabulary the body dispatches over — a `StrEnum` or the exit integer itself keyed from a `frozendict`, never a boolean pair the caller re-pairs to an effect. `updatedToolOutput` is dropped for built-in tools (Bash, Read, Grep, WebFetch), so an inbound-secret redaction on their output never rewrites in place — the working lane blocks with `decision: "block"` and a redacted summary as the reason, which keeps the raw secret out of the next model turn even though the replacement seam is inert. Every rewrite field replaces the whole object it targets, so a rewrite spreads the full original input and overrides one key rather than emitting the changed key alone.

## [04]-[FAIL_CLOSED]

A malformed payload, an unparseable command, or a decode error is a block on a security gate and a silent exit 0 on an observer — the disposition is fixed at the seam, never left to a crash. A hook that raises exits non-zero-but-not-2, which is non-blocking, so a security check that crashes silently permits the very action it guards; catch the decode failure explicitly and route it to exit 2. A path check normalizes before comparing — `Path(p).resolve().is_relative_to(root)`, never `startswith` on the raw string, which both over- and under-matches — and normalizes every alias form the shell expands: a bare `~` and `~/` resolve to `$HOME` itself, not to `HOME/"~"`, so a `rm -rf ~` reaches the same danger-root tier as `rm -rf /`. A command check normalizes the command before matching, because raw substring matching misses `$IFS` and quote obfuscation (the fragments example carries the normalization move), and it fails closed on the shapes it cannot read rather than admitting them: an inline interpreter one-liner (`python3 -c '<opaque>'`) is unverifiable, so it denies by default, never a keyword denylist that admits `os.system` by omission.

Two egress surfaces are the same fail-closed seam. A value written to `$CLAUDE_ENV_FILE` passes `shlex.quote` — the file is sourced into bash, so an unquoted `$()` or backtick in a branch name, path, or fetched value executes on the next Bash call; the quote is the difference between persisting data and shipping a remote-code path. A binary the hook shells is resolved absolutely or probed for identity, never invoked by bare name — a bare `fmt`, `tree`, or `find` collides with a system namesake (`/usr/bin/fmt` reflows paragraphs), so the resolved path is confirmed against the estate tool before it runs. A checker that is missing, degraded, or resolves to the wrong binary emits a visible stderr diagnostic and exits 0 for a gate that cannot revert its target, never a silent exit 0 that reads as a clean pass — the operator learns the gate did not run.

## [05]-[HOT_PATH]

`PreToolUse` and `PermissionRequest` gate the agentic loop, so their budget is under ~100ms and the matcher is narrow — a specific `tool_name`, never `.*`, which fires on every tool and taxes every turn. `SessionStart` blocks session start rather than a per-tool turn, so its ceiling is a low single-digit second budget spent once: each probe caps its subprocess timeout at a couple of seconds, the probe count stays small, and the uv cache is pre-warmed, because a large repo's `git status` or a cold resolution stalls the prompt the user is waiting on. Slow work moves off the hot path: a full test suite, a CI probe, or a deployment rides `async: true` (fire-and-forget) or `asyncRewake: true` (wakes the session on exit 2 with stderr as a system reminder). `UserPromptSubmit` and `MessageDisplay` lower the command-family timeout (the numeric owner is the config reference), so neither runs a network call inline. Expensive session bootstraps cache their computed values through `$CLAUDE_ENV_FILE` so later turns read the export rather than recomputing. Where a hook fleet's per-invocation interpreter spawn dominates the hot path, thin per-event forwarders route the payload to one persistent daemon that holds every handler, its typed structs, and its contracts in-process, so admission cost is paid once at daemon load and a fifty-handler project costs the same per call as a five-handler one. Logging rides `structlog` to a file or a transmitter carrying the failure fields (`tool_name`, `tool_use_id`, `error`, timestamp), never stdout — stdout is the decision channel, and a hook that logs there corrupts its own verdict.
