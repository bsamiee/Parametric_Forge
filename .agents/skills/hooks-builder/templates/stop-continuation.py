#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
# Boundary-kernel hook seam: focused one-line docstrings, and a tolerant transcript decode that skips one malformed line.
# ruff:file-ignore[docstring-missing-returns, try-except-continue]
"""Own Stop/SubagentStop: end a run only on a session-scoped completion token bounded by two orthogonal loop bounds.

Reprompt adapts to run state. Wire: Stop and SubagentStop. On Codex the exit-2 block rides decision JSON via codex-adapter.sh.
Boundary kernel: os.environ admitted here. The two bounds are orthogonal — the harness stop_hook_active cap is consecutive-per-turn,
the durable counter is cumulative-across-turns; MAX_BLOCKS=0 disarms the second on purpose, so a live default arms both out of the box.
"""

from collections import deque
import contextlib
import os
from pathlib import Path
import sys

import msgspec


TOKEN_PREFIX = "TASKMASTER_DONE::"  # POLICY: the session-scoped completion sentinel; grep-exact, immune to prose drift
MAX_BLOCKS = 12  # POLICY: durable cumulative cap across the whole run; 0 disarms it and leans on the harness stop_hook_active cap of 8
CONTRACT_AGENTS: frozenset[str] = frozenset()  # POLICY: agent_types bound to the token contract; empty = every subagent is released
ASSISTANT_TYPES = frozenset(("assistant", "thinking"))  # transcript entries the token may legitimately ride; tool_result echoes are not "done"
MAX_PAYLOAD = 8 * 1024 * 1024  # bound the stdin read; a pathological payload never balloons resident memory


class Stop(msgspec.Struct, frozen=True, rename={"active": "stop_hook_active", "event": "hook_event_name"}):
    """Decoded Stop/SubagentStop hook payload."""

    session_id: str = ""
    last_assistant_message: str = ""
    transcript_path: str = ""
    agent_id: str = ""
    agent_type: str = ""
    event: str = ""
    active: bool = False


def _done(payload: Stop, /) -> bool:
    """Report task-done, layered by availability: the immediate field first, then a bounded assistant-entry scan."""
    token = f"{TOKEN_PREFIX}{payload.session_id}"
    if token in payload.last_assistant_message:
        return True
    return any(token in text for text in _assistant_texts(payload.transcript_path))  # a thinking-block token never reaches the field


def _tail(transcript_path: str, /, *, lines: int = 400) -> list[str]:
    """Read the last N transcript lines through a bounded deque so a multi-GB JSONL never loads whole; empty on OSError."""
    try:
        with Path(transcript_path).open(encoding="utf-8", errors="replace") as handle:
            return list(deque(handle, maxlen=lines))
    except OSError:
        return []


def _assistant_texts(transcript_path: str, /) -> list[str]:
    """Collect text from assistant/thinking transcript entries only; a token echoed in a tool_result is not "done"."""
    out: list[str] = []
    for line in _tail(transcript_path):
        try:
            record = msgspec.json.decode(line, type=_Entry)
        except msgspec.DecodeError:
            continue
        if record.type in ASSISTANT_TYPES:
            out.append(record.text or line)
    return out


class _Entry(msgspec.Struct, frozen=True):
    """Tolerant view over one heterogeneous transcript record."""

    type: str = ""
    text: str = ""


def _errored(tail: list[str], /) -> bool:
    """Report whether any tailed line carries an is_error marker."""
    return any('"is_error": true' in line or '"is_error":true' in line for line in tail)


def _counter(session_id: str, /) -> Path:
    """Resolve the session-keyed durable block-counter path, creating its root best-effort."""
    root = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "claude" / "stop"
    with contextlib.suppress(OSError):  # an uncreatable counter root disarms the durable bound; the live harness cap stays the fallback
        root.mkdir(parents=True, exist_ok=True)
    return root / f"{session_id or 'anon'}.count"  # session-keyed so parallel sessions never clobber each other's counter


def _bump(counter: Path, /) -> int:
    """Increment the durable block counter, returning 0 on any I/O fault so an uncaught exit 1 never breaks the very loop this guards."""
    try:
        count = int(counter.read_text(encoding="utf-8") or 0) + 1 if counter.exists() else 1
        counter.write_text(str(count), encoding="utf-8")
    except OSError, ValueError:
        return 0  # a counter fault degrades to the live stop_hook_active cap, never a non-2 exit that permits the stop
    return count


def main() -> int:
    """Run the Stop/SubagentStop decision and return the hook exit code."""
    try:
        payload = msgspec.json.decode(sys.stdin.buffer.read(MAX_PAYLOAD), type=Stop)
    except msgspec.DecodeError:
        return 0  # a malformed payload never traps the agent in a stop loop
    if payload.active or _done(payload):  # the harness cap fired or the token is present: clear state and end the turn
        _counter(payload.session_id).unlink(missing_ok=True)
        return 0
    if payload.event == "SubagentStop" and payload.agent_type not in CONTRACT_AGENTS:
        return 0  # discriminate on identity, not length: a subagent outside the contract allowlist never saw the token, release it
    counter = _counter(payload.session_id)
    count = _bump(counter)  # durable cumulative bound; an I/O fault degrades to the harness cap, never an uncaught exit 1
    if MAX_BLOCKS and count > MAX_BLOCKS:
        counter.unlink(missing_ok=True)
        return 0  # the durable cap bounds total blocks across the run, orthogonal to the consecutive-block harness cap
    preamble = "Recent tool errors were detected; resolve them before declaring done. " if _errored(_tail(payload.transcript_path)) else ""
    sys.stderr.write(f"{preamble}Task incomplete: run tests and types, then emit {TOKEN_PREFIX}{payload.session_id} when done.\n")
    return 2


if __name__ == "__main__":
    sys.exit(main())
