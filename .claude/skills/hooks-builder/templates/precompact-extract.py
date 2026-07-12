#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
"""Summarize the transcript into a durable handoff before compaction discards the working set.

Wire: PreCompact (Codex ships PreCompact with a trigger field, so the body ports). A companion SessionStart reloads the newest
handoff on source "resume". Emits {continue:true} + a systemMessage pointer; never blocks compaction.
"""

from collections import deque
from datetime import datetime, UTC
import os
from pathlib import Path
import sys
import time

import msgspec


TAIL_LINES = 600  # bound the transcript scan; a compacting session's JSONL can be large
KEEP_TOOLS = 5  # POLICY: how many recent tool calls and errors the summary carries
KEEP_ERRORS = 5
MAX_PAYLOAD = 8 * 1024 * 1024  # bound the stdin read; a pathological payload never balloons resident memory


class PreCompact(msgspec.Struct, frozen=True):
    """Decoded PreCompact hook payload; the wire keys are `trigger` and `custom_instructions`, matched by name."""

    session_id: str = ""
    transcript_path: str = ""
    trigger: str = "auto"  # `manual` on /compact, `auto` on the context-window threshold; msgspec binds by the exact wire name
    custom_instructions: str = ""  # the text the user typed into /compact; dropped if this field is misnamed


class ToolCall(msgspec.Struct, frozen=True):
    """One recorded tool call and its success flag."""

    name: str = ""
    ok: bool = True


class Summary(msgspec.Struct, frozen=True):
    """Durable pre-compaction handoff summary."""

    session_id: str
    trigger: str
    instructions: str
    at: str
    todo: str
    recent_tools: list[ToolCall]
    files_touched: list[str]
    errors: list[str]
    last_message: str


class Line(msgspec.Struct, frozen=True):
    """Tolerant view over one heterogeneous JSONL record."""

    type: str = ""
    tool_name: str = ""
    is_error: bool = False
    file_path: str = ""
    text: str = ""
    todos: str = ""


def _records(transcript_path: str, /) -> list[Line]:
    """Decode the bounded transcript tail into records, skipping malformed lines."""
    try:
        with Path(transcript_path).open(encoding="utf-8", errors="replace") as handle:
            raw = deque(handle, maxlen=TAIL_LINES)  # O(TAIL_LINES) memory: a multi-GB transcript never loads whole
    except OSError:
        return []
    out: list[Line] = []
    for line in raw:
        try:
            out.append(msgspec.json.decode(line, type=Line))
        except msgspec.DecodeError:
            continue  # a partial or non-record line is skipped, never fatal
    return out


def _summarize(payload: PreCompact, records: list[Line], /) -> Summary:
    """Project the transcript records into a durable handoff summary."""
    tools = [
        ToolCall(r.tool_name, not r.is_error) for r in records if r.type == "assistant" and r.tool_name
    ]  # gate on assistant so a tool_result never double-counts its call
    return Summary(
        session_id=payload.session_id,
        trigger=payload.trigger,
        instructions=payload.custom_instructions,  # a manual /compact steer the reloader honors on resume
        at=datetime.now(UTC).isoformat(),  # true UTC; a local strftime labeled Z mislabels the estate's ISO-8601 UTC ledger
        todo=next((r.todos for r in reversed(records) if r.todos), ""),
        recent_tools=tools[-KEEP_TOOLS:],
        files_touched=sorted({r.file_path for r in records if r.file_path}),
        errors=[r.text or r.tool_name for r in records if r.is_error][-KEEP_ERRORS:],
        last_message=next((r.text for r in reversed(records) if r.type == "assistant" and r.text), ""),
    )


def main() -> int:
    """Write the pre-compaction handoff and emit the continue directive."""
    try:
        payload = msgspec.json.decode(sys.stdin.buffer.read(MAX_PAYLOAD), type=PreCompact)
    except msgspec.DecodeError:
        return 0  # never block compaction on a malformed payload
    summary = _summarize(payload, _records(payload.transcript_path))
    root = Path(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())) / ".claude" / "state" / "handoff" / (payload.session_id or "anon")
    root.mkdir(parents=True, exist_ok=True)
    artifact = root / f"{time.time_ns()}.json"  # ns key: two handoffs in one second never collide (second-resolution stamps overwrite)
    tmp = artifact.with_suffix(".json.tmp")
    tmp.write_bytes(msgspec.json.encode(summary))
    tmp.replace(artifact)  # atomic publish: a killed compaction never leaves the reloader a truncated JSON
    body = {
        "continue": True,
        "systemMessage": f"handoff written to {artifact}",
        "hookSpecificOutput": {"hookEventName": "PreCompact", "additionalContext": f"pre-compaction handoff at {artifact}"},
    }
    sys.stdout.write(msgspec.json.encode(body).decode())
    return 0


if __name__ == "__main__":
    sys.exit(main())
