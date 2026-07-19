# [SCRIPTING]

A command hook is a boundary kernel: read one JSON payload on stdin, admit it once into a typed shape, decide, and emit the verdict through exactly one channel. Its craft is packaging it as a self-contained single-file script, admitting the payload without threading provider shapes through the body, and respecting the hot-path budget the event imposes. Rails, closed families, and the lint gate are the Python stack's owned law and hold here without restatement; this page owns only what a hook adds to them. A hook script is a boundary kernel in the stack's own sense, so the host-API primitives its role forces — `os.environ` for placeholder env, `subprocess.run` for a probe or checker, `os.getcwd` for a fallback root — are admitted at this seam under the exemption the stack grants a measured kernel; the hook carries them behind its typed admission rather than reaching for a rail wrapper, and either declares the documented per-line suppression or stands outside the host project's lint scope, never both restating the ban and silently tripping it.

## [01]-[PACKAGING]

A Python hook ships as a uv single-file script with PEP 723 inline metadata — no venv, no `requirements.txt`, dependencies resolved and cached per script. A shebang makes the file directly executable, and `chmod +x` is mandatory or the hook silently fails.

```python signature
#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
```

`msgspec` is the wire codec every hook carries; the rest of the dependency roster is drawn from the estate's admitted libraries and assumed uv-resolvable, composed at full operator depth rather than hand-rolled — `anyio` owns structured concurrency and subprocess for a resident daemon or a parallel probe fan, `httpx` owns transport for a transmitter or HTTP-calling hook (wired `async: true` so a synchronous POST never stalls the loop; a transmitter that posts inline is a blocking hook mislabeled), and `stamina` owns bounded retry. That roster splits by hot-path budget: a per-tool gate stays `msgspec`-lean because every dependency is cold-resolution cost on the loop, while an off-hot-path daemon, harness, or transmitter — whose admission amortizes at load — reaches for the richer owner, and a structured `anyio` task group cancels a wedged child or a hung probe at its deadline where a raw thread strands it. `uv add <pkg> --script <file>` edits the metadata block. Exec-form config (`args` present) spawns the file without a shell, so a shell-profile echo never corrupts the JSON channel.

A PEP 723 dependency resolves and caches on first invocation — a measured multi-second cost on a cold uv cache or after a prune. That resolution is a one-time environment cost, never a per-call one, and it is paid off the hot path: a `SessionStart` or `Setup` step runs `uv run --script <hook> </dev/null` once to warm the cache before the first gating call, or the persistent-daemon forwarder amortizes it across the fleet. A `SessionStart` hook cannot pre-warm itself, so it stays `msgspec`-lean and pushes a heavy probe dependency onto the daemon or a `Setup` step that runs ahead of it. Hot-path budget below measures a warm interpreter; a hook that first resolves its dependencies inside a `PreToolUse` firing blows the budget by orders of magnitude, which the warm step exists to prevent.

## [02]-[ADMISSION]

Stdin JSON is the wire, admitted once into a `msgspec.Struct` at the top of the body; the interior reads typed attributes, never a `dict.get(...)` chain re-derived at each use, and never re-validates. That read is bounded — `sys.stdin.buffer.read(<cap>)` — so a pathological `tool_response` never balloons resident memory, and a payload past the cap truncates into the same decode-failure seam a gate already fails closed on. Structs tolerate unknown fields by default, so a hook types only the few fields it reads and the rest of the payload passes through unseen. Provider shapes stop at this line — `tool_input` admits into its own struct, and the body dispatches on `tool_name` through a `match`, not a nested-`get` ladder. A decode failure routes straight to the hook's fail-closed disposition at the same seam, so no `None` ever crosses into the interior:

Unknown-field tolerance is not shape tolerance on a declared field. A field whose payload shape varies across tools or providers — `tool_response`, `str` from one tool and an object `{stdout, stderr, ...}` from most built-ins — decodes hard against a fixed type annotation: a mismatch is a `msgspec.ValidationError`, a `DecodeError` subclass that the decode-seam `except` routes to fail-closed disposition, which on an observer is a silent exit 0 that no-ops the whole hook. So a declared field of varying shape is typed `msgspec.Raw` (or a union) and normalized inside the body — decoded once past the admission seam and reduced to the scannable value the interior needs — never annotated to one shape that silently discards every other. An official payload schema documents only a subset of tool response shapes, so the shape a field takes is confirmed by empirical per-tool replay, never assumed per tool.

```python accepted
import sys

import msgspec

MAX_PAYLOAD = 8 * 1024 * 1024  # bound the read so a pathological tool_response never balloons resident memory


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
        payload = msgspec.json.decode(sys.stdin.buffer.read(MAX_PAYLOAD), type=PreToolUse)
    except msgspec.DecodeError:
        sys.stderr.write("malformed hook payload; failing closed\n")
        return 2  # gate disposition; an observer returns 0 here instead
    return decide(payload)
```

## [03]-[CHANNELS]

Exactly one channel carries the verdict, and mixing them silently drops the JSON:

- [EXIT_CODE]: Blunt, portable path — exit 2 with a stderr reason blocks identically on both providers across the shared tool and prompt events, and exit 0 permits with stdout empty. Untrusted text in that model-facing reason or an `additionalContext` injection is control-char scrubbed at capture, since a raw C0/C1 byte in a filename steers the rendering terminal while `msgspec` encoding keeps the JSON channel safe. Every gate and guardrail rides this unless it must rewrite or inject.
- [STDOUT_JSON]: Scalpel — exit 0 with a single JSON object on stdout, nothing else. Carries `updatedInput`, `updatedToolOutput`, `additionalContext`, and the `permissionDecision`/`decision` surfaces. Guidance and diagnostics still go to stderr; a stray print to stdout is a parse failure.

Decision is a closed vocabulary the body dispatches over — a `StrEnum` or the exit integer itself keyed from a `frozendict`, never a boolean pair the caller re-pairs to an effect. `updatedToolOutput` rewrites the result of every tool, built-in included, but a built-in validates the replacement against its output schema and silently keeps the original on a shape mismatch, so an inbound-secret redaction re-emits the tool's exact shape — a `Bash` scrub returns `{stdout, stderr, interrupted, isImage}` with the secret masked, never a bare string. A bare `decision: "block"` on Claude leaves the raw output in context — the model reads the original beside the reason — so redaction rides `updatedToolOutput`, not a block, and `updatedMCPToolOutput` is the deprecated MCP-only alias `updatedToolOutput` subsumes. Every rewrite field replaces the whole object it targets, so a rewrite spreads the full original input and overrides one key rather than emitting the changed key alone.

## [04]-[FAIL_CLOSED]

A malformed payload, an unparseable command, or a decode error is a block on a security gate and a silent exit 0 on an observer — the disposition is fixed at the seam, never left to a crash. A hook that raises exits non-zero-but-not-2, which is non-blocking, so a security check that crashes silently permits the very action it guards; catch the decode failure explicitly and route it to exit 2. A path check normalizes before comparing — `Path(p).resolve().is_relative_to(root)`, never `startswith` on the raw string, which both over- and under-matches — and normalizes every alias form the shell expands: a bare `~` and `~/` resolve to `$HOME` itself, not to `HOME/"~"`, so a `rm -rf ~` reaches the same danger-root tier as `rm -rf /`. A command check normalizes the command before matching, because raw substring matching misses `$IFS` and quote obfuscation (the command-decomposition recipe carries the normalization move), and it fails closed on the shapes it cannot read rather than admitting them: an inline interpreter one-liner (`python3 -c '<opaque>'`) is unverifiable, so it denies by default, never a keyword denylist that admits `os.system` by omission.

Two egress surfaces are the same fail-closed seam. A value written to `$CLAUDE_ENV_FILE` passes `shlex.quote` — the file is sourced into bash, so an unquoted `$()` or backtick in a branch name, path, or fetched value executes on the next Bash call; the quote is the difference between persisting data and shipping a remote-code path. A binary the hook shells is resolved absolutely or probed for identity, never invoked by bare name — a bare `fmt`, `tree`, or `find` collides with a system namesake (`/usr/bin/fmt` reflows paragraphs), so the resolved path is confirmed against the estate tool before it runs. A checker that is missing, degraded, or resolves to the wrong binary emits a visible stderr diagnostic and exits 0 for a gate that cannot revert its target, never a silent exit 0 that reads as a clean pass — the operator learns the gate did not run.

## [05]-[HOT_PATH]

`PreToolUse` and `PermissionRequest` gate the agentic loop, so their budget is under ~100ms and the matcher is narrow — a specific `tool_name`, never `.*`, which fires on every tool and taxes every turn. `SessionStart` blocks session start rather than a per-tool turn, so its ceiling is a low single-digit second budget spent once: each probe caps its subprocess timeout at a couple of seconds, the probe count stays small, and the uv cache is pre-warmed, because a large repo's `git status` or a cold resolution stalls the prompt the user is waiting on. Slow work moves off the hot path: a full test suite, a CI probe, or a deployment rides `async: true` (fire-and-forget) or `asyncRewake: true` (wakes the session on exit 2 with stderr as a system reminder). `UserPromptSubmit` and `MessageDisplay` lower the command-family timeout (the numeric owner is the config reference), so neither runs a network call inline. Expensive session bootstraps cache their computed values through `$CLAUDE_ENV_FILE` so later turns read the export rather than recomputing. Where a hook fleet's per-invocation interpreter spawn dominates the hot path, thin per-event forwarders route the payload to one persistent daemon that holds every handler, its typed structs, and its contracts in-process, so admission cost is paid once at daemon load and a fifty-handler project costs the same per call as a five-handler one. Logging rides `structlog` to a file or a transmitter carrying the failure fields (`tool_name`, `tool_use_id`, `error`, timestamp), never stdout — stdout is the decision channel, and a hook that logs there corrupts its own verdict.
