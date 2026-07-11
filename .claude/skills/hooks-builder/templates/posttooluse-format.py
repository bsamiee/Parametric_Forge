#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
# PostToolUse owner: MODE recovered from the payload shape. A file event formats through the estate `fmt` router then gates on
# `fmt --check`; a tool-output event redacts secrets. Wire: PostToolUse matcher "Edit|Write|MultiEdit|Bash|Read|Grep|WebFetch".
# Boundary kernel: subprocess/shutil.which are admitted here. tool_response is typed Raw because its shape varies per tool (str for
# some, object {stdout,stderr,...} for most built-ins), so it is normalized in-body, never decoded against a single declared shape.
import re
import shutil
import subprocess
import sys
from enum import StrEnum, auto
from pathlib import Path

import msgspec

REDACT_TOOLS = frozenset(("Bash", "Read", "Grep", "WebFetch"))  # POLICY: tools whose text output is scanned for secrets
SECRET = re.compile(r"sk-ant-[A-Za-z0-9_-]{16,}|ghp_[A-Za-z0-9]{36}|AKIA[A-Z0-9]{16}|xox[baprs]-[A-Za-z0-9-]{10,}")  # POLICY
CHECK_OVERLAY: dict[str, tuple[str, ...]] = {".py": ("ruff", "check")}  # POLICY: linter beyond `fmt`, where format != lint
TIMEOUT_S = 30
FMT = next((p for p in (shutil.which("fmt"),) if p and p != "/usr/bin/fmt"), "")  # estate router only; never the macOS reflow namesake


class Mode(StrEnum):
    FORMAT = auto()
    REDACT = auto()
    SKIP = auto()


class ToolInput(msgspec.Struct, frozen=True):
    file_path: str = ""


class PostToolUse(msgspec.Struct, frozen=True):
    tool_name: str = ""
    tool_input: ToolInput = msgspec.field(default_factory=ToolInput)
    tool_response: msgspec.Raw = msgspec.field(default_factory=msgspec.Raw)  # shape varies per tool; normalized in-body, not decoded


def _mode(payload: PostToolUse, /) -> Mode:
    if payload.tool_input.file_path and Path(payload.tool_input.file_path).is_file():
        return Mode.FORMAT
    return Mode.REDACT if payload.tool_name in REDACT_TOOLS else Mode.SKIP


def _run(argv: tuple[str, ...], /) -> subprocess.CompletedProcess[str] | None:
    try:
        return subprocess.run(argv, capture_output=True, text=True, timeout=TIMEOUT_S, check=False)
    except OSError, subprocess.SubprocessError:
        return None  # a missing or hung tool never blocks a completed edit


def _format(target: Path, /) -> int:
    if not FMT:  # a degraded/absent checker emits a visible diagnostic, never a silent exit 0 that fakes a clean gate
        print("gate skipped: estate fmt router unavailable on PATH", file=sys.stderr)
        return 0
    _run((FMT, str(target)))  # the router owns every suffix; a per-language checker overlay survives only where lint != format
    gate = _run((*overlay, str(target))) if (overlay := CHECK_OVERLAY.get(target.suffix)) else _run((FMT, "--check", str(target)))
    if gate is None:
        print(f"gate skipped: checker for {target.suffix} did not run", file=sys.stderr)
        return 0
    if gate.returncode != 0:
        print("\n".join((gate.stdout or gate.stderr).splitlines()[:8]), file=sys.stderr)
        return 2
    return 0


def _text(raw: msgspec.Raw, /) -> str:  # normalize any tool_response shape to one scannable string before the secret scan
    try:
        obj = msgspec.json.decode(raw)
    except msgspec.DecodeError:
        return ""
    return obj if isinstance(obj, str) else msgspec.json.encode(obj).decode()


def _redact(payload: PostToolUse, /) -> int:  # updatedToolOutput is dropped for built-in tools, so block-and-summarize
    scrubbed, hits = SECRET.subn(lambda m: f"[REDACTED …{m.group()[-4:]}]", _text(payload.tool_response))
    if hits:
        body = {"decision": "block", "reason": f"{hits} secret(s) redacted from {payload.tool_name} output:\n{scrubbed[:2000]}"}
        sys.stdout.write(msgspec.json.encode(body).decode())
    return 0


def main() -> int:
    try:
        payload = msgspec.json.decode(sys.stdin.buffer.read(), type=PostToolUse)
    except msgspec.DecodeError:
        return 0  # observer role: a malformed payload never blocks a completed tool call
    match _mode(payload):
        case Mode.FORMAT:
            return _format(Path(payload.tool_input.file_path))
        case Mode.REDACT:
            return _redact(payload)
        case Mode.SKIP:
            return 0


if __name__ == "__main__":
    sys.exit(main())
