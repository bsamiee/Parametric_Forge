#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
"""Inject context from a data-driven nudge table decoded from nudges.json, never a code literal.

Each nudge row keys on a target field with match and exclude regex arrays and a priority, so a new nudge is a
data drop that edits no code. Each fires cheaply-dismissibly — a false fire costs a few ignored tokens, a miss
costs a correction loop — and injects additionalContext reading as a factual statement, never an out-of-band
imperative that trips injection defenses. Wire: UserPromptSubmit (or any injecting event); the table path is
HOOK_NUDGES or .claude/nudges.json under the project root.
"""

import os
from pathlib import Path
import re
import sys

import msgspec


TABLE_PATH = os.environ.get("HOOK_NUDGES") or f"{os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd())}/.claude/nudges.json"
MAX_PAYLOAD = 8 * 1024 * 1024  # bound the stdin read; a pathological prompt never balloons resident memory


class ToolInput(msgspec.Struct, frozen=True):
    """The Bash command field a command-target nudge matches against."""

    command: str = ""


class Payload(msgspec.Struct, frozen=True, rename={"event": "hook_event_name"}):
    """The injecting-event fields a nudge target selects among."""

    event: str = ""
    prompt: str = ""
    tool_name: str = ""
    agent_type: str = ""
    tool_input: ToolInput = msgspec.field(default_factory=ToolInput)


class Nudge(msgspec.Struct, frozen=True):
    """One table row; target selects the haystack, exclude carves the exception a single pattern cannot."""

    target: str  # prompt | tool_name | agent_type | command
    match: tuple[str, ...]
    text: str
    exclude: tuple[str, ...] = ()
    priority: int = 100


def _haystacks(payload: Payload, /) -> dict[str, str]:
    """Admit the payload once into the field a nudge target selects."""
    return {"prompt": payload.prompt, "tool_name": payload.tool_name,
            "agent_type": payload.agent_type, "command": payload.tool_input.command}


def fired(payload: Payload, rows: tuple[Nudge, ...], /) -> list[str]:
    """Return the priority-ordered nudge texts whose target matches and no exclude vetoes."""
    field = _haystacks(payload)
    return [row.text for row in sorted(rows, key=lambda r: r.priority)
            if (hay := field.get(row.target, "")) and any(re.search(p, hay) for p in row.match)
            and not any(re.search(x, hay) for x in row.exclude)]


def load(path: str, /) -> tuple[Nudge, ...]:
    """Load the nudge table from disk; a missing or malformed file injects nothing."""
    try:
        return tuple(msgspec.json.decode(Path(path).read_bytes(), type=list[Nudge]))
    except (OSError, msgspec.DecodeError):
        return ()


def main() -> int:
    """Inject the fired nudges as additionalContext, or nothing when none fire."""
    try:
        payload = msgspec.json.decode(sys.stdin.buffer.read(MAX_PAYLOAD), type=Payload)
    except msgspec.DecodeError:
        return 0  # an injector observes: a malformed payload injects nothing rather than failing the prompt
    if hits := fired(payload, load(TABLE_PATH)):
        body = {"hookSpecificOutput": {"hookEventName": payload.event or "UserPromptSubmit",
                                       "additionalContext": "\n".join(hits)}}
        sys.stdout.write(msgspec.json.encode(body).decode())
    return 0


if __name__ == "__main__":
    sys.exit(main())
