#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
# Focused one-line docstrings carry no Returns section at the boundary-kernel hook seam.
# ruff:file-ignore[docstring-missing-returns]
"""Run a slow check off the hot path; wake the session only on findings not in the baseline receipt.

A pre-existing failure never re-wakes every turn. Wire: PostToolUse (or Stop) with "async": true, "asyncRewake": true.
The wake rides exit-2 + stderr, never additionalContext, and asyncRewake is never wired to SessionStart: the wake injects a prior run's stale output as current context.
"""

import os
from pathlib import Path
import re
import subprocess
import sys

import msgspec


CHECK: tuple[str, ...] = ("ruff", "check", "--output-format", "concise", ".")  # POLICY: the slow verification argv
FINDING = re.compile(r"^(?P<file>[^:]+):(?P<line>\d+):\d+:\s+(?P<rule>\S+)")  # POLICY: file:line:col rule extraction
TIMEOUT_S = 300  # under the 600s command-hook cap; a scan that legitimately exceeds it forks a detached harvester (integration ASYNC)
MAX_PAYLOAD = 8 * 1024 * 1024  # bound the stdin read; a pathological payload never balloons resident memory


class Payload(msgspec.Struct, frozen=True):
    """Decoded async-guardrail hook payload."""

    session_id: str = ""
    cwd: str = "."
    hook_event_name: str = ""  # asyncRewake on SessionStart leaks stale stderr into fresh context; decoded so the body can fail-safe


class Finding(msgspec.Struct, frozen=True, order=True):
    """One ruff finding: file, line, rule."""

    file: str
    line: int
    rule: str


def _findings(output: str, /) -> frozenset[Finding]:
    """Parse ruff concise output into a set of findings."""
    return frozenset(Finding(m["file"], int(m["line"]), m["rule"]) for line in output.splitlines() if (m := FINDING.match(line)))


def _baseline(session_id: str, /) -> Path:
    """Resolve the session-keyed baseline-receipt path, creating its root."""
    root = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "claude" / "guardrail"
    root.mkdir(parents=True, exist_ok=True)
    return root / f"{session_id or 'anon'}.json"  # session-keyed so parallel runs never share a receipt


def _load(receipt: Path, /) -> frozenset[Finding]:
    """Load the acknowledged findings set, empty on missing or malformed receipt."""
    try:
        return frozenset(msgspec.json.decode(receipt.read_bytes(), type=list[Finding]))
    except OSError, msgspec.DecodeError:
        return frozenset()


def main() -> int:
    """Run the guardrail check and return the hook exit code."""
    try:
        payload = msgspec.json.decode(sys.stdin.buffer.read(MAX_PAYLOAD), type=Payload)
    except msgspec.DecodeError:
        return 0
    if payload.hook_event_name == "SessionStart":
        return 0  # never rewake at conversation start: the exit-2 stderr would inject stale check output into fresh context
    try:
        result = subprocess.run(CHECK, cwd=payload.cwd, capture_output=True, text=True, timeout=TIMEOUT_S, check=False)
    except (OSError, subprocess.SubprocessError) as failure:
        sys.stderr.write(f"guardrail could not run: {failure}\n")
        return 0  # an unrunnable check is not a failing check; never wake on infrastructure noise
    current = _findings(result.stdout + result.stderr)
    receipt = _baseline(payload.session_id)
    acknowledged = _load(receipt)
    regressions = sorted(current - acknowledged)
    receipt.write_bytes(
        msgspec.json.encode(sorted(acknowledged | current))
    )  # monotonic acknowledged-set: a flaky finding that vanishes then reappears never re-wakes
    if regressions:
        rows = "\n".join(f"{f.file}:{f.line} {f.rule}" for f in regressions)
        sys.stderr.write(f"async guardrail: {len(regressions)} new finding(s):\n{rows}\n")
        return 2  # asyncRewake surfaces this stderr as a system reminder on a later turn
    return 0


if __name__ == "__main__":
    sys.exit(main())
