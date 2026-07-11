#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
# Async guardrail: run a slow check off the hot path; wake the session only on findings NOT in the baseline receipt, so a
# pre-existing failure never re-wakes every turn. Wire: PostToolUse (or Stop) with "async": true, "asyncRewake": true.
# The wake rides exit-2 + stderr, never additionalContext, and asyncRewake is never wired to SessionStart (#44872 context leak).
import os
import re
import subprocess
import sys
from pathlib import Path

import msgspec

CHECK: tuple[str, ...] = ("ruff", "check", "--output-format", "concise", ".")  # POLICY: the slow verification argv
FINDING = re.compile(r"^(?P<file>[^:]+):(?P<line>\d+):\d+:\s+(?P<rule>\S+)")  # POLICY: file:line:col rule extraction
TIMEOUT_S = 300  # under the 600s command-hook cap; a scan that legitimately exceeds it forks a detached harvester (integration ASYNC)


class Payload(msgspec.Struct, frozen=True):
    session_id: str = ""
    cwd: str = "."
    hook_event_name: str = ""  # asyncRewake on SessionStart leaks stale stderr into fresh context; decoded so the body can fail-safe


class Finding(msgspec.Struct, frozen=True, order=True):
    file: str
    line: int
    rule: str


def _findings(output: str, /) -> frozenset[Finding]:
    return frozenset(Finding(m["file"], int(m["line"]), m["rule"]) for line in output.splitlines() if (m := FINDING.match(line)))


def _baseline(session_id: str, /) -> Path:
    root = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "claude" / "guardrail"
    root.mkdir(parents=True, exist_ok=True)
    return root / f"{session_id or 'anon'}.json"  # session-keyed so parallel runs never share a receipt


def _load(receipt: Path, /) -> frozenset[Finding]:
    try:
        return frozenset(msgspec.json.decode(receipt.read_bytes(), type=list[Finding]))
    except OSError, msgspec.DecodeError:
        return frozenset()


def main() -> int:
    try:
        payload = msgspec.json.decode(sys.stdin.buffer.read(), type=Payload)
    except msgspec.DecodeError:
        return 0
    if payload.hook_event_name == "SessionStart":
        return 0  # never rewake at conversation start: the exit-2 stderr would inject stale check output into fresh context
    try:
        result = subprocess.run(CHECK, cwd=payload.cwd, capture_output=True, text=True, timeout=TIMEOUT_S, check=False)
    except (OSError, subprocess.SubprocessError) as failure:
        print(f"guardrail could not run: {failure}", file=sys.stderr)
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
        print(f"async guardrail: {len(regressions)} new finding(s):\n{rows}", file=sys.stderr)
        return 2  # asyncRewake surfaces this stderr as a system reminder on a later turn
    return 0


if __name__ == "__main__":
    sys.exit(main())
