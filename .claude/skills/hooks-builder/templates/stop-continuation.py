#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
# Stop/SubagentStop owner: a run ends only on a session-scoped completion token, bounded by two orthogonal loop bounds, with a
# reprompt that adapts to run state. Wire: Stop and SubagentStop. On Codex the exit-2 block rides decision JSON via codex-adapter.sh.
# Boundary kernel: os.environ admitted here. The two bounds are orthogonal — the harness stop_hook_active cap is consecutive-per-turn,
# the durable counter is cumulative-across-turns; MAX_BLOCKS=0 disarms the second on purpose, so a live default arms both out of the box.
import os
import sys
from pathlib import Path

import msgspec

TOKEN_PREFIX = "TASKMASTER_DONE::"  # POLICY: the session-scoped completion sentinel; grep-exact, immune to prose drift
MAX_BLOCKS = 12  # POLICY: durable cumulative cap across the whole run; 0 disarms it and leans on the harness stop_hook_active cap of 8
CONTRACT_AGENTS: frozenset[str] = frozenset()  # POLICY: agent_types bound to the token contract; empty = every subagent is released
ASSISTANT_TYPES = frozenset(("assistant", "thinking"))  # transcript entries the token may legitimately ride; tool_result echoes are not "done"


class Stop(msgspec.Struct, frozen=True, rename={"active": "stop_hook_active", "event": "hook_event_name"}):
    session_id: str = ""
    last_assistant_message: str = ""
    transcript_path: str = ""
    agent_id: str = ""
    agent_type: str = ""
    event: str = ""
    active: bool = False


def _done(payload: Stop, /) -> bool:  # layered by availability: the immediate field first, then a bounded assistant-entry scan
    token = f"{TOKEN_PREFIX}{payload.session_id}"
    if token in payload.last_assistant_message:
        return True
    return any(token in text for text in _assistant_texts(payload.transcript_path))  # a thinking-block token never reaches the field


def _tail(transcript_path: str, /, *, lines: int = 400) -> list[str]:
    try:
        return Path(transcript_path).read_text(encoding="utf-8", errors="replace").splitlines()[-lines:]
    except OSError:
        return []


def _assistant_texts(transcript_path: str, /) -> list[str]:  # only assistant/thinking entries; a token echoed in a tool_result is not "done"
    out: list[str] = []
    for line in _tail(transcript_path):
        try:
            record = msgspec.json.decode(line, type=_Entry)
        except msgspec.DecodeError:
            continue
        if record.type in ASSISTANT_TYPES:
            out.append(record.text or line)
    return out


class _Entry(msgspec.Struct, frozen=True):  # tolerant view over one heterogeneous transcript record
    type: str = ""
    text: str = ""


def _errored(tail: list[str], /) -> bool:
    return any('"is_error": true' in line or '"is_error":true' in line for line in tail)


def _counter(session_id: str, /) -> Path:
    root = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "claude" / "stop"
    root.mkdir(parents=True, exist_ok=True)
    return root / f"{session_id or 'anon'}.count"  # session-keyed so parallel sessions never clobber each other's counter


def main() -> int:
    try:
        payload = msgspec.json.decode(sys.stdin.buffer.read(), type=Stop)
    except msgspec.DecodeError:
        return 0  # a malformed payload never traps the agent in a stop loop
    if payload.active or _done(payload):  # the harness cap fired or the token is present: clear state and end the turn
        _counter(payload.session_id).unlink(missing_ok=True)
        return 0
    if payload.event == "SubagentStop" and payload.agent_type not in CONTRACT_AGENTS:
        return 0  # discriminate on identity, not length: a subagent outside the contract allowlist never saw the token, release it
    counter = _counter(payload.session_id)
    count = int(counter.read_text() or 0) + 1 if counter.exists() else 1
    if MAX_BLOCKS and count > MAX_BLOCKS:
        counter.unlink(missing_ok=True)
        return 0  # the durable cap bounds total blocks across the run, orthogonal to the consecutive-block harness cap
    counter.write_text(str(count))
    preamble = "Recent tool errors were detected; resolve them before declaring done. " if _errored(_tail(payload.transcript_path)) else ""
    print(f"{preamble}Task incomplete: run tests and types, then emit {TOKEN_PREFIX}{payload.session_id} when done.", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
