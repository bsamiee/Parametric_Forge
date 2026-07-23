#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
# Boundary-kernel hook seam: focused one-line docstrings, and POLICY temp-root classification literals, never temp-file creation.
# ruff: noqa: DOC201, S108
"""Own SessionStart: inject only dynamic state a gated probe produces, capture the routing row, persist a scalar cache.

Capture the session_id->{tty,pane} routing row a shared-worktree estate needs. Wire: SessionStart matcher "startup|resume|clear|compact". Inject nothing silent.
Boundary kernel: os.environ/subprocess admitted here. Every $CLAUDE_ENV_FILE value passes shlex.quote — the file is sourced into
bash, so an unquoted $()/backtick in a branch, path, or fetched value would execute. Probes run in ctx.cwd and stay cheap; SessionStart blocks startup.
"""

from collections.abc import Callable
import os
from pathlib import Path
import shlex
import subprocess
import sys

import msgspec


TAG = "repo_state"
PREVIEW_CAP = 10_000  # over this, additionalContext writes to a file and passes a preview plus path
MAX_PAYLOAD = 8 * 1024 * 1024  # bound the stdin read; a pathological payload never balloons resident memory


class SessionStart(msgspec.Struct, frozen=True):
    """Decoded SessionStart hook payload."""

    session_id: str = ""
    cwd: str = "."
    source: str = "startup"
    agent_type: str = ""


class Probe(msgspec.Struct, frozen=True):
    """Gated dynamic-state probe row."""

    label: str
    argv: tuple[str, ...]
    predicate: Callable[[SessionStart], bool]
    priority: int = 100
    cap: int = 512  # POLICY: per-row output ceiling; PREVIEW_CAP bounds the whole block, so without this one churning row eats it


def _worktree(ctx: SessionStart, /) -> bool:
    """Report whether ctx.cwd is inside a git work tree."""
    return _run(("git", "-C", ctx.cwd, "rev-parse", "--is-inside-work-tree")) == "true"


PROBES: tuple[Probe, ...] = (  # POLICY: gated dynamic-state rows; {cwd} resolves to ctx.cwd so gate and probe share one root
    Probe("branch", ("git", "-C", "{cwd}", "branch", "--show-current"), _worktree, 10, 128),
    Probe("status", ("git", "-C", "{cwd}", "status", "--short"), _worktree, 20, 1024),  # a dirty tree is bounded, never a full churn dump
)


def _run(argv: tuple[str, ...], /) -> str:
    """Run a capped probe, returning its stripped stdout or an empty string on failure."""
    try:
        return subprocess.run(argv, capture_output=True, text=True, timeout=2, check=False).stdout.strip()  # cap: SessionStart blocks startup
    except OSError, subprocess.SubprocessError:
        return ""


def _clip(text: str, cap: int, /) -> str:
    """Bound one probe's contribution within its policy ceiling, marker included, cutting on a line edge so a truncated row never reads as data."""
    if len(text) <= cap:
        return text
    marker = f"\n… clipped at {cap} chars"
    body = text[: max(cap - len(marker), 0)]
    return "\n".join(body.splitlines()[:-1] or [body]) + marker


def _persist(key: str, value: str, /) -> None:
    """Append an exported scalar to the env file; shlex.quote neutralizes $()/backticks so a ref value cannot inject when sourced."""
    if (env_file := os.environ.get("CLAUDE_ENV_FILE")) and value:
        with Path(env_file).open("a", encoding="utf-8") as sink:
            sink.write(f"export {key}={shlex.quote(value)}\n")


def _route(ctx: SessionStart, /) -> None:
    """Persist the session routing row; payload carries no tty/pane, so read them from this child's own runtime, keyed by session_id."""
    if not ctx.session_id:
        return
    pane = next((v for k in ("WEZTERM_PANE", "ZELLIJ_PANE_ID", "TMUX_PANE", "KITTY_WINDOW_ID", "TERM_SESSION_ID") if (v := os.environ.get(k))), "")
    tty = _run(("ps", "-o", "tty=", "-p", str(os.getppid())))
    row = {"session_id": ctx.session_id, "tty": "" if tty in {"?", "??"} else tty, "pane": pane}  # a hook has no controlling tty; ? is not identity
    registry = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "claude" / "routing"
    registry.mkdir(parents=True, exist_ok=True)
    (registry / f"{ctx.session_id}.json").write_bytes(msgspec.json.encode(row))


def _inject(context: str, /) -> None:
    """Emit additionalContext, spilling to a file with a preview above the cap."""
    if len(context) > PREVIEW_CAP:
        sink = Path(os.environ.get("TMPDIR", "/tmp")) / f"session-context-{os.getpid()}.txt"
        sink.write_text(context, encoding="utf-8")
        context = f"{context[:PREVIEW_CAP]}\n… full context at {sink}"
    sys.stdout.write(msgspec.json.encode({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": context}}).decode())


def main() -> int:
    """Route the session, run gated probes, persist the branch cache, and inject collected state."""
    try:
        ctx = msgspec.json.decode(sys.stdin.buffer.read(MAX_PAYLOAD), type=SessionStart)
    except msgspec.DecodeError:
        return 0  # routing/injection failure exits 0 so telemetry never blocks the harness
    _route(ctx)
    lines = {
        probe.label: out
        for probe in sorted(PROBES, key=lambda p: p.priority)
        if probe.predicate(ctx) and (out := _clip(_run(tuple(a.replace("{cwd}", ctx.cwd) for a in probe.argv)), probe.cap))
    }
    _persist("SESSION_BRANCH", lines.get("branch", ""))
    if lines:  # inject nothing when no row fires — the empty-state line is pure context pollution
        _inject(f"<{TAG}>\n" + "\n".join(f"{label}: {value}" for label, value in lines.items()) + f"\n</{TAG}>")
    return 0


if __name__ == "__main__":
    sys.exit(main())
