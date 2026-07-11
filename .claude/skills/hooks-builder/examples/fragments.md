# [FRAGMENTS]

Advanced logic moves inside a hook — the specific technique, not a whole hook. Each fragment names what it does, when it earns its place, the code, and the failure mode it prevents. The accepted half drops into a template or a live body unchanged.

## [01]-[COMMAND_DECOMPOSITION]

A security matcher decomposes a command into leaf argv lists before classifying, because a raw substring or regex over one collapsed string cannot tell a safe form from a dangerous one that spells the same bytes. De-obfuscation, a quote-aware split on shell operators with an unquoted newline treated as `;`, command-substitution and backtick descent, leading `NAME=value` env-prefix and wrapper stripping, and clustered-flag shell/interpreter descent turn one string into the leaves a per-`argv` classifier judges.

- Earns its place when: the hook blocks shell commands and an attacker or a confused model can wrap, quote, chain, newline-split, env-prefix, substitute, or nest the same call many ways.
- Prevents: `rm${IFS}-rf${IFS}/`, `"rm" -rf /`, `echo ok && rm -rf /`, `echo hi` + newline + `rm -rf /`, `FOO=bar rm -rf /`, `bash -lc 'rm -rf /'`, `echo $(rm -rf /)`, and a backtick `rm -rf /` all slipping a naive `"rm -rf" in command` check that leaf decomposition exposes.

```python accepted
import re
import shlex

_IFS = re.compile(r"\$\{IFS[^}]*\}|\$IFS")
_ENV = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")  # a leading NAME=value env-prefix precedes the real argv[0]
_TICK = re.compile(r"`([^`]*)`")
_WRAPPERS = frozenset(("sudo", "env", "command", "nice", "nohup", "timeout", "xargs"))
_SHELLS = frozenset(("sh", "bash", "zsh", "dash"))
_INTERP = frozenset(("python", "python3", "node", "ruby", "perl"))


def _subs(command: str, /) -> tuple[str, list[str]]:  # lift `...` and $(...) bodies; each executes and is descended
    inner: list[str] = []
    stripped = _TICK.sub(lambda m: (inner.append(m.group(1)), " ")[1], command)
    i = 0
    while (hit := stripped.find("$(", i)) != -1:  # scan a balanced $(...) tolerating nesting
        depth, j = 1, hit + 2
        while j < len(stripped) and depth:
            depth += (stripped[j] == "(") - (stripped[j] == ")")
            j += 1
        inner.append(stripped[hit + 2 : j - 1])
        i = j
    return stripped, inner


def leaves(command: str, /, *, depth: int = 0) -> list[list[str]]:  # a ValueError on unbalanced quotes propagates to fail-closed
    stripped, inner = _subs(command)
    out = [leaf for body in inner if depth < 8 for leaf in leaves(body, depth=depth + 1)]
    lexer = shlex.shlex(_IFS.sub(" ", stripped), posix=True, punctuation_chars=";&|<>()\n\r")
    lexer.whitespace, lexer.whitespace_split = " \t\f\v", True  # newline is punctuation, so it separates a chain
    argv: list[str] = []
    for token in lexer:
        if token in {";", "&&", "||", "|", "&", "(", ")"} or (token and all(c in ";&|\n" for c in token)):
            out += _resolve(argv, depth=depth) if argv else []
            argv = []
        else:
            argv.append(token)
    return out + (_resolve(argv, depth=depth) if argv else [])


def _resolve(argv: list[str], /, *, depth: int) -> list[list[str]]:
    changed = True
    while changed and argv:  # peel interleaved leading env-prefixes and wrappers before the real command surfaces
        changed = False
        while argv and _ENV.match(argv[0]):
            argv, changed = argv[1:], True
        while argv and argv[0] in _WRAPPERS:
            argv, changed = argv[1:], True
    if not argv:
        return []
    if depth < 8 and argv[0] in _SHELLS and (inner := _flag(argv, "c")):  # -c, -lc, -ec, clustered
        return leaves(inner, depth=depth + 1)  # analyze the inner command, not the outer bash
    if argv[0] in _INTERP and (_flag(argv, "c") or _flag(argv, "e")):
        return [["\0interp"]]  # an inline one-liner is opaque; the classifier denies it, never scans its body
    return [argv]


def _flag(argv: list[str], letter: str, /) -> str:  # operand after a short flag carrying `letter`, clustered or not
    return next((argv[i + 1] for i, t in enumerate(argv) if t.startswith("-") and not t.startswith("--") and letter in t and i + 1 < len(argv)), "")
```

## [02]-[JSON_SCALPEL]

Exit-0 stdout JSON rewrites a value rather than blocking — `updatedInput` before the tool runs, a redacted summary after — so the agent proceeds on a corrected input or a scrubbed result instead of a hard stop. A rewrite spreads the full original `tool_input` and overrides exactly one key, because `updatedInput` replaces the entire input object; emitting the changed key alone drops the tool's other arguments and corrupts the call.

- Earns its place when: the right move is to fix the call, not refuse it — sandbox a stray path, redact a secret, steer without an error frame.
- Prevents: a rewrite that drops `old_string`/`new_string` from an `Edit`, and an inbound redaction that trusts `updatedToolOutput` on a built-in tool where replacement is silently dropped.

```python accepted
import re
import sys

import msgspec

_SECRET = re.compile(r"sk-ant-[A-Za-z0-9_-]{16,}|ghp_[A-Za-z0-9]{36}|AKIA[A-Z0-9]{16}")


def sandbox_write(tool_input: dict[str, object], sandbox: str, /) -> None:  # PreToolUse: spread the full input, override one key
    name = str(tool_input.get("file_path", "")).rsplit("/", 1)[-1]
    body = {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow", "updatedInput": {**tool_input, "file_path": f"{sandbox}/{name}"}}}
    sys.stdout.write(msgspec.json.encode(body).decode())


def redact_output(tool_response: str, /) -> None:  # PostToolUse: updatedToolOutput drops for built-ins, so block-and-summarize
    scrubbed, hits = _SECRET.subn(lambda m: f"[REDACTED …{m.group()[-4:]}]", tool_response)
    if hits:
        body = {"decision": "block", "reason": f"{hits} secret(s) redacted:\n{scrubbed[:2000]}"}
        sys.stdout.write(msgspec.json.encode(body).decode())
```

## [03]-[ASYNC_REWAKE]

A slow guardrail runs off the hot path under `asyncRewake`, letting the triggering action proceed and waking the session later only if the check fails — exit 2 surfaces stderr as a system reminder on a subsequent turn. The wake rides exit-2 and stderr, never `additionalContext`, and `asyncRewake` is never wired to `SessionStart`, where the wake payload leaks its raw JSON into the terminal prompt.

- Earns its place when: the verification is authoritative but slow (a full suite, a CI probe, a deploy smoke test) and blocking the loop for it stalls every turn.
- Prevents: a synchronous 30-second check on `PostToolUse` that pauses the agent on every edit, and a fire-and-forget check whose failure is never surfaced.

```python accepted
import subprocess
import sys

# Config carries "async": true, "asyncRewake": true — the process already returned; this exit only rewakes.
result = subprocess.run(("npm", "test", "--silent"), capture_output=True, text=True, timeout=300, check=False)
if result.returncode != 0:
    print("\n".join(result.stdout.splitlines()[-12:]), file=sys.stderr)
    raise SystemExit(2)  # wakes the session; never additionalContext, never on SessionStart
raise SystemExit(0)
```

## [04]-[COMPLETION_TOKEN]

A `Stop` hook keys completion on a session-scoped token the assistant emits — detected on `last_assistant_message` first, then on a bounded scan restricted to assistant and thinking transcript entries — and bounds the loop by two orthogonal caps so a token emitted in a thinking block is not missed and a run cannot block forever. The two bounds are independent: the harness `stop_hook_active` cap counts consecutive blocks and resets at every turn boundary, while a durable session-keyed counter counts cumulative blocks across turns; a live default arms both, and `0` on the durable counter disarms the second on purpose, never as a silent default. The transcript lags the current turn (it is flushed asynchronously), so the field is authoritative and the entry scan is a lagging fallback, never the reverse.

- Earns its place when: a run must loop until an objective is provably met and the completion signal has to survive automation, resume, and a thinking-block emission.
- Prevents: the double-block livelock, the fragility of inferring "done" from free-text, a missed token that never reached `last_assistant_message`, and a false completion from a token echoed inside a `tool_result` that a raw-line grep counts as done.

```python accepted
from pathlib import Path

import msgspec

_ASSISTANT = frozenset(("assistant", "thinking"))  # entries the token may ride; a tool_result echo is not "done"


class _Entry(msgspec.Struct, frozen=True):  # tolerant view over one heterogeneous transcript record
    type: str = ""
    text: str = ""


def done(token: str, last_message: str, transcript_path: str, /) -> bool:  # layered by availability: field first, entry fallback
    if token in last_message:
        return True
    try:
        tail = Path(transcript_path).read_text(encoding="utf-8", errors="replace").splitlines()[-400:]
    except OSError:
        return False
    for line in tail:  # scan only assistant/thinking entries so a quoted echo never false-completes
        try:
            entry = msgspec.json.decode(line, type=_Entry)
        except msgspec.DecodeError:
            continue
        if entry.type in _ASSISTANT and token in (entry.text or line):
            return True
    return False
```

## [05]-[PRIORITY_REGISTRY]

One executable routes every event through a priority-banded handler registry, so a fleet registers few settings entries and a new capability is one handler row. Each handler declares a `matches` predicate, a `handle` verdict, an integer priority band, and a `terminal` flag; the dispatcher sorts ascending, runs the matches, and short-circuits at the first terminal `DENY`.

- Earns its place when: several handlers compose on one event (a safety gate, a quality check, an advisory nudge) and per-event scripts fork the payload model and the logger.
- Prevents: settings-file sprawl, the merge conflicts of N near-identical entries, and the drift of a single-handler router that cannot compose an ordered chain. Where per-invocation interpreter spawn dominates, the same registry relocates behind a Unix-socket daemon so admission cost is paid once at load.

```python accepted
import sys
from collections.abc import Callable

import msgspec


class Envelope(msgspec.Struct, frozen=True):
    hook_event_name: str = ""


class Handler(msgspec.Struct, frozen=True):
    event: str
    priority: int  # 10-20 safety, 25-35 quality, 56-79 advisory, 100+ logging
    terminal: bool
    run: Callable[[bytes], int]  # matches and handles; returns an exit code, 2 = DENY


REGISTRY: tuple[Handler, ...] = (...)  # POLICY rows; a new capability is one row


def dispatch(raw: bytes, /) -> int:
    try:
        event = msgspec.json.decode(raw, type=Envelope).hook_event_name
    except msgspec.DecodeError:
        return 0
    for handler in sorted((h for h in REGISTRY if h.event == event), key=lambda h: h.priority):
        if (code := handler.run(raw)) == 2 and handler.terminal:
            return 2  # short-circuit at the first terminal DENY
    return 0


if __name__ == "__main__":
    sys.exit(dispatch(sys.stdin.buffer.read()))
```

## [06]-[NUDGE_ARTIFACT]

Context injection is a loaded artifact, not a code literal: nudge rows decode from a `nudges.json` at body top, each keyed by a `match_target` with `match` and `exclude` regex arrays, a priority, and either an inject-text arm or a named handler. A new nudge is a data drop, and each fires cheaply-dismissibly so a false fire costs a few ignored tokens while a miss costs a correction loop.

- Earns its place when: injection rules multiply, each new one must land as data not code, and misfires must be cheap.
- Prevents: a Python edit per nudge, a single-pattern rule that cannot carve an exception, and context bloat from unconditional injection.

```python accepted
import re
from pathlib import Path

import msgspec


class ToolInput(msgspec.Struct, frozen=True):
    command: str = ""


class NudgeInput(msgspec.Struct, frozen=True):
    prompt: str = ""
    tool_name: str = ""
    agent_type: str = ""
    tool_input: ToolInput = msgspec.field(default_factory=ToolInput)


class Nudge(msgspec.Struct, frozen=True):
    target: str  # prompt | tool_name | agent_type | command
    match: tuple[str, ...]
    exclude: tuple[str, ...] = ()
    text: str = ""
    priority: int = 100


def fired(payload: NudgeInput, rows: tuple[Nudge, ...], /) -> list[str]:
    fields = {"prompt": payload.prompt, "tool_name": payload.tool_name, "agent_type": payload.agent_type, "command": payload.tool_input.command}
    hits = [n for n in sorted(rows, key=lambda n: n.priority) if (hay := fields[n.target]) and any(re.search(p, hay) for p in n.match) and not any(re.search(x, hay) for x in n.exclude)]
    return [n.text for n in hits]


def load(path: str, /) -> tuple[Nudge, ...]:  # the table is data on disk; a new nudge edits no code
    try:
        return tuple(msgspec.json.decode(Path(path).read_bytes(), type=list[Nudge]))
    except (OSError, msgspec.DecodeError):
        return ()
```

## [07]-[TELEMETRY_CHAIN]

A transmitter hook chains after the policy hook on the same event, so the gate decides and the transmitter forwards without touching the verdict. The envelope hoists the hot query keys flat beside the raw payload for a private sink, or wraps them in a CloudEvents 1.0 shape for a shared bus; either way `async: true` wiring, a short timeout, a broad exception swallow, and an unconditional exit 0 keep a dead collector from gating the loop.

- Earns its place when: a multi-agent fleet needs an event stream (a dashboard, a registry, an attention feed) that must never gate the loop.
- Prevents: policy and telemetry entangled in one hook where a logging failure blocks a tool call, an opaque payload the store cannot query, and a non-`HTTPError` httpx exception (`InvalidURL`, `CookieConflict`, `StreamError`) escaping a two-type catch to exit non-zero and block the loop. Codex emits OTel metrics through its own `[otel]` exporter, so a Codex transmitter carries the synchronous stream, not duplicate metrics.

```python accepted
import sys
from datetime import UTC, datetime
from time import time_ns

import httpx
import msgspec


class Event(msgspec.Struct, frozen=True):
    hook_event_name: str = ""
    session_id: str = ""
    tool_name: str = ""


def cloudevent(event: Event, raw: bytes, source: str, /) -> dict[str, object]:  # standard bus: hot keys flat, raw payload in data
    return {"specversion": "1.0", "type": f"com.parametric-forge.hook.{event.hook_event_name}", "source": source,
            "id": f"{event.session_id}-{time_ns()}", "time": datetime.now(UTC).isoformat(),  # true UTC, never a local strftime tagged Z
            "sessionid": event.session_id, "toolname": event.tool_name, "data": msgspec.json.decode(raw)}


raw = sys.stdin.buffer.read()  # wired second in the event array with async: true; non-blocking by construction
try:
    payload = msgspec.json.decode(raw, type=Event)
    httpx.post("http://127.0.0.1:4000/events", json=cloudevent(payload, raw, "codex"), timeout=2.0)
except Exception:  # noqa: BLE001 — telemetry is advisory; every fault, incl. non-HTTPError httpx types, swallows to a guaranteed exit 0
    pass
raise SystemExit(0)
```

## [08]-[RED_TEAM_HARNESS]

One harness runs any hook against a paired fixture corpus in two modes — a spawned subprocess for fidelity and an in-process call for speed — and reports each row as `RULE`/`CASE`/`EXPECTED`/`ACTUAL`, naming the offending policy on a miss. Every dangerous fixture ships its benign twin, and a new policy row lands only with its paired fixture.

- Earns its place when: a hook enforces security and both misses (a dangerous payload that passes) and false alarms (a benign payload that blocks) must be caught, and a foreign hook must be audited before it is trusted.
- Prevents: shipping a gate proven only on the happy path, a rulebook that outgrows its corpus, and trusting a copied gist hook whose behavior was never exercised.

```python test-only
import subprocess
import sys


def _bash(cmd: str, /) -> str:
    return '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":' + f'{cmd!r}' + "}}"


CASES: tuple[tuple[str, str, int], ...] = (  # (rule, payload, expected): 2 blocks, 0 allows; every attack carries its benign twin
    ("rm-root", _bash("rm -rf /"), 2),
    ("rm-obfusc", _bash("rm${IFS}-rf${IFS}/"), 2),
    ("rm-build", _bash("rm -rf ./build"), 0),  # twin: a scoped rm allows
    ("newline-chain", _bash("echo hi\nrm -rf /"), 2),  # unquoted newline is a chain operator
    ("newline-benign", _bash("echo hi\necho ok"), 0),  # twin: benign newline-separated commands allow
    ("env-prefix", _bash("FOO=bar rm -rf /"), 2),  # leading NAME=value stripped before argv[0]
    ("env-benign", _bash("FOO=bar npm test"), 0),  # twin: env-prefixed benign command allows
    ("shell-cluster", _bash("bash -lc 'rm -rf /'"), 2),  # clustered -lc/-ec, not only -c
    ("shell-benign", _bash("bash -lc 'npm test'"), 0),  # twin: clustered-flag benign inner allows
    ("cmd-subst", _bash("echo $(rm -rf /)"), 2),  # $(...) body executes, so descend it
    ("backtick-subst", _bash("echo `rm -rf /`"), 2),  # backtick body executes, so descend it
    ("subst-benign", _bash("echo $(git rev-parse HEAD)"), 0),  # twin: benign substitution allows
    ("interp-opaque", _bash('python3 -c \'import os;os.system("rm -rf /")\''), 2),  # opaque one-liner denies by default
    ("tilde-home", _bash("rm -rf ~"), 2),  # bare ~ resolves to $HOME, a danger root
    ("git-safe", _bash("git checkout -b feat"), 0),  # twin: safe git call allows
    ("malformed", "not json", 2),
)


def audit(hook: str, /) -> int:
    rows = [(rule, expected, subprocess.run([hook], input=payload, capture_output=True, text=True, check=False).returncode) for rule, payload, expected in CASES]
    misses = [(rule, exp, act) for rule, exp, act in rows if exp != act]
    for rule, exp, act in misses:
        print(f"MISS {rule}: expected {exp}, got {act}", file=sys.stderr)
    return 1 if misses else 0


if __name__ == "__main__":
    raise SystemExit(audit(sys.argv[1]))
```

## [09]-[PERMISSION_AUTO_APPROVE]

A `PermissionRequest` hook approves a matched-safe call and persists a standing rule through `updatedPermissions`, so the same call auto-approves for the rest of the session or across sessions instead of re-prompting. The durable rule is an `addRules` `PermissionUpdate` entry with a `localSettings` destination; a `setMode` entry switches the session mode instead. The matcher stays narrow — a broad matcher auto-clears file writes and shell commands.

- Earns its place when: a repetitive safe operation (a read-only probe, a scoped `git` call) prompts every invocation and one clearance settles it.
- Prevents: a permission-prompt storm on a known-safe call, and the Codex trap of reaching for the rewrite fields — Codex `PermissionRequest` accepts only `decision.behavior` and fails closed on `updatedPermissions`/`updatedInput`, so the durable rule is Claude-only and the adapter strips it.

```python accepted
import sys

import msgspec


def auto_approve(tool_name: str, rule_content: str, /) -> None:  # PermissionRequest: allow now, persist a standing rule
    entry = {"type": "addRules", "rules": [{"toolName": tool_name, "ruleContent": rule_content}], "behavior": "allow", "destination": "localSettings"}
    body = {"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": {"behavior": "allow", "updatedPermissions": [entry]}}}
    sys.stdout.write(msgspec.json.encode(body).decode())  # setMode {"type":"setMode","mode":"acceptEdits","destination":"session"} switches mode; Codex takes behavior only
```

## [10]-[DURABLE_STATE]

A hook that must remember across invocations writes session-keyed state to a durable directory, reads it on the next firing, and clears it on completion — a read-modify-write keyed on `session_id` so parallel sessions on one shared worktree never clobber each other. A one-time computation caches an `export` line into `$CLAUDE_ENV_FILE`; durable state that survives a plugin update rides `$CLAUDE_PLUGIN_DATA`.

- Earns its place when: a control-flow hook counts, dedupes, or carries a receipt across turns, or a bootstrap computes a value once that later turns reread.
- Prevents: a counter two parallel sessions clobber, a recomputed bootstrap on every turn, and state lost to a plugin update.

```python accepted
import os
from pathlib import Path

import msgspec


class State(msgspec.Struct):
    count: int = 0
    seen: set[str] = msgspec.field(default_factory=set)


def _path(session_id: str, /) -> Path:
    root = Path(os.environ.get("CLAUDE_PLUGIN_DATA") or os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "claude" / "hook"
    root.mkdir(parents=True, exist_ok=True)
    return root / f"{session_id or 'anon'}.json"  # session-keyed: no shared filename across parallel sessions


def bump(session_id: str, turn_id: str, /) -> State:  # read-modify-write; idempotent by turn_id against a double firing
    path = _path(session_id)
    state = msgspec.json.decode(path.read_bytes(), type=State) if path.exists() else State()
    if turn_id not in state.seen:
        state.count += 1
        state.seen.add(turn_id)
        path.write_bytes(msgspec.json.encode(state))
    return state
```
