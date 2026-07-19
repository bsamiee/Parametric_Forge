#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
# Focused one-line docstrings carry no Returns section at the boundary-kernel hook seam.
# ruff: noqa: DOC201
"""Own PostToolUse: recover MODE from the payload shape, formatting a file event and redacting a tool-output event.

A file event formats through the estate `fmt` router then gates on `fmt --check`; a tool-output event redacts secrets.
Wire: PostToolUse matcher "Edit|Write|NotebookEdit|Bash|Read|Grep|WebFetch".
Boundary kernel: subprocess/shutil.which are admitted here. tool_response is typed Raw because its shape varies per tool (str for
some, object {stdout,stderr,...} for most built-ins), so it is normalized in-body, never decoded against a single declared shape.
"""

from enum import auto, StrEnum
from pathlib import Path
import re
import shutil
import subprocess
import sys

import msgspec


WRITE_TOOLS = frozenset(("Edit", "Write", "NotebookEdit"))  # POLICY: tools that mutate a file; only these route to FORMAT
REDACT_TOOLS = frozenset(("Bash", "Read", "Grep", "WebFetch"))  # POLICY: tools whose output is scanned for secrets
SECRET = re.compile(r"sk-ant-[A-Za-z0-9_-]{16,}|ghp_[A-Za-z0-9]{36}|AKIA[A-Z0-9]{16}|xox[baprs]-[A-Za-z0-9-]{10,}")  # POLICY
CHECK_OVERLAY: dict[str, tuple[str, ...]] = {".py": ("ruff", "check")}  # POLICY: linter beyond `fmt`, where format != lint
TIMEOUT_S = 30
MAX_PAYLOAD = 8 * 1024 * 1024  # bound the stdin read; a pathological payload never balloons resident memory
FMT = next((p for p in (shutil.which("fmt"),) if p and p != "/usr/bin/fmt"), "")  # estate router only; never the macOS reflow namesake


class Mode(StrEnum):
    """Operating mode recovered from the payload shape."""

    FORMAT = auto()
    REDACT = auto()
    SKIP = auto()


class ToolInput(msgspec.Struct, frozen=True):
    """File-tool input fields."""

    file_path: str = ""
    notebook_path: str = ""  # NotebookEdit names its target here, never file_path

    @property
    def target(self) -> str:
        """Resolve the one written path across the file tools' divergent field names."""
        return self.file_path or self.notebook_path


class PostToolUse(msgspec.Struct, frozen=True):
    """Decoded PostToolUse hook payload."""

    tool_name: str = ""
    tool_input: ToolInput = msgspec.field(default_factory=ToolInput)
    tool_response: msgspec.Raw = msgspec.field(default_factory=msgspec.Raw)  # shape varies per tool; normalized in-body, not decoded


def _mode(payload: PostToolUse, /) -> Mode:
    """Recover the operating mode from tool identity, never file_path alone: a Read carries a path yet must never be formatted."""
    if payload.tool_name in WRITE_TOOLS and payload.tool_input.target and Path(payload.tool_input.target).is_file():
        return Mode.FORMAT
    return Mode.REDACT if payload.tool_name in REDACT_TOOLS else Mode.SKIP


def _run(argv: tuple[str, ...], /) -> subprocess.CompletedProcess[str] | None:
    """Run a tool, returning None on a missing or hung binary so it never blocks a completed edit."""
    try:
        return subprocess.run(argv, capture_output=True, text=True, timeout=TIMEOUT_S, check=False)
    except OSError, subprocess.SubprocessError:
        return None  # a missing or hung tool never blocks a completed edit


def _format(target: Path, /) -> int:
    """Format a file through the estate router, then gate on check and surface a failing diagnostic."""
    if not FMT:  # a degraded/absent checker emits a visible diagnostic, never a silent exit 0 that fakes a clean gate
        sys.stderr.write("gate skipped: estate fmt router unavailable on PATH\n")
        return 0
    _run((FMT, str(target)))  # the router owns every suffix; a per-language checker overlay survives only where lint != format
    gate = _run((*overlay, str(target))) if (overlay := CHECK_OVERLAY.get(target.suffix)) else _run((FMT, "--check", str(target)))
    if gate is None:
        sys.stderr.write(f"gate skipped: checker for {target.suffix} did not run\n")
        return 0
    if gate.returncode != 0:
        sys.stderr.write("\n".join((gate.stdout or gate.stderr).splitlines()[:8]) + "\n")
        return 2
    return 0


def _mask(match: re.Match[str], /) -> str:
    """Mask a matched secret, keeping the last four chars so the model can still correlate references."""
    return f"[REDACTED …{match.group()[-4:]}]"


def _scrub(value: object, /) -> tuple[object, int]:
    """Redact secrets across a decoded tool_response, preserving its exact shape so updatedToolOutput matches the tool schema."""
    if isinstance(value, str):
        return SECRET.subn(_mask, value)
    if isinstance(value, list):
        items = [_scrub(item) for item in value]
        return [item for item, _ in items], sum(hits for _, hits in items)
    if isinstance(value, dict):
        pairs = {key: _scrub(item) for key, item in value.items()}
        return {key: item for key, (item, _) in pairs.items()}, sum(hits for _, hits in pairs.values())
    return value, 0


def _redact(payload: PostToolUse, /) -> int:
    """Rewrite secret-bearing output in place through updatedToolOutput; a bare decision:block leaves the raw secret in context."""
    try:
        original: object = msgspec.json.decode(payload.tool_response)
    except msgspec.DecodeError:
        return 0  # an unparseable tool_response carries no scannable text; never block a completed call on it
    scrubbed, hits = _scrub(original)  # shape-preserving: a built-in ignores a mismatched replacement, so the scrub keeps the schema
    if hits:
        body = {"hookSpecificOutput": {"hookEventName": "PostToolUse", "updatedToolOutput": scrubbed}}
        sys.stdout.write(msgspec.json.encode(body).decode())
    return 0


def main() -> int:
    """Decode stdin and dispatch to the mode owner; a malformed payload never blocks a completed call."""
    try:
        payload = msgspec.json.decode(sys.stdin.buffer.read(MAX_PAYLOAD), type=PostToolUse)
    except msgspec.DecodeError:
        return 0  # observer role: a malformed payload never blocks a completed tool call
    match _mode(payload):
        case Mode.FORMAT:
            return _format(Path(payload.tool_input.target))
        case Mode.REDACT:
            return _redact(payload)
        case Mode.SKIP:
            return 0


if __name__ == "__main__":
    sys.exit(main())
