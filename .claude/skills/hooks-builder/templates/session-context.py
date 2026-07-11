#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
# SessionStart owner: inject only dynamic state that a gated probe produces, capture the session_id->{tty,pane} routing row a
# shared-worktree estate needs, persist a scalar cache. Wire: SessionStart matcher "startup|resume|clear|compact". Inject nothing silent.
# Boundary kernel: os.environ/subprocess admitted here. Every $CLAUDE_ENV_FILE value passes shlex.quote — the file is sourced into
# bash, so an unquoted $()/backtick in a branch, path, or fetched value would execute. Probes run in ctx.cwd and stay cheap; SessionStart blocks startup.
import os
import shlex
import subprocess
import sys
from collections.abc import Callable
from pathlib import Path

import msgspec

TAG = "repo_state"
PREVIEW_CAP = 10_000  # over this, additionalContext writes to a file and passes a preview plus path


class SessionStart(msgspec.Struct, frozen=True):
    session_id: str = ""
    cwd: str = "."
    source: str = "startup"
    agent_type: str = ""


class Probe(msgspec.Struct, frozen=True):
    label: str
    argv: tuple[str, ...]
    predicate: Callable[[SessionStart], bool]
    priority: int = 100


def _worktree(ctx: SessionStart, /) -> bool:
    return _run(("git", "-C", ctx.cwd, "rev-parse", "--is-inside-work-tree")) == "true"


PROBES: tuple[Probe, ...] = (  # POLICY: gated dynamic-state rows; {cwd} resolves to ctx.cwd so gate and probe share one root
    Probe("branch", ("git", "-C", "{cwd}", "branch", "--show-current"), _worktree, 10),
    Probe("status", ("git", "-C", "{cwd}", "status", "--short"), _worktree, 20),
)


def _run(argv: tuple[str, ...], /) -> str:
    try:
        return subprocess.run(argv, capture_output=True, text=True, timeout=2, check=False).stdout.strip()  # cap: SessionStart blocks startup
    except OSError, subprocess.SubprocessError:
        return ""


def _persist(key: str, value: str, /) -> None:  # shlex.quote neutralizes $()/backticks so a ref value cannot inject when sourced
    if (env_file := os.environ.get("CLAUDE_ENV_FILE")) and value:
        with Path(env_file).open("a", encoding="utf-8") as sink:
            sink.write(f"export {key}={shlex.quote(value)}\n")


def _route(ctx: SessionStart, /) -> None:  # payload carries no tty/pane; read them from this child's own runtime, key by session_id
    if not ctx.session_id:
        return
    pane = next((v for k in ("WEZTERM_PANE", "ZELLIJ_PANE_ID", "TMUX_PANE", "KITTY_WINDOW_ID", "TERM_SESSION_ID") if (v := os.environ.get(k))), "")
    tty = _run(("ps", "-o", "tty=", "-p", str(os.getppid())))
    row = {"session_id": ctx.session_id, "tty": "" if tty in {"?", "??"} else tty, "pane": pane}  # a hook has no controlling tty; ? is not identity
    registry = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "claude" / "routing"
    registry.mkdir(parents=True, exist_ok=True)
    (registry / f"{ctx.session_id}.json").write_bytes(msgspec.json.encode(row))


def _inject(context: str, /) -> None:
    if len(context) > PREVIEW_CAP:
        sink = Path(os.environ.get("TMPDIR", "/tmp")) / f"session-context-{os.getpid()}.txt"
        sink.write_text(context, encoding="utf-8")
        context = f"{context[:PREVIEW_CAP]}\n… full context at {sink}"
    sys.stdout.write(msgspec.json.encode({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": context}}).decode())


def main() -> int:
    try:
        ctx = msgspec.json.decode(sys.stdin.buffer.read(), type=SessionStart)
    except msgspec.DecodeError:
        return 0  # routing/injection failure exits 0 so telemetry never blocks the harness
    _route(ctx)
    lines = {
        probe.label: out
        for probe in sorted(PROBES, key=lambda p: p.priority)
        if probe.predicate(ctx) and (out := _run(tuple(a.replace("{cwd}", ctx.cwd) for a in probe.argv)))
    }
    _persist("SESSION_BRANCH", lines.get("branch", ""))
    if lines:  # inject nothing when no row fires — the empty-state line is pure context pollution
        _inject(f"<{TAG}>\n" + "\n".join(f"{label}: {value}" for label, value in lines.items()) + f"\n</{TAG}>")
    return 0


if __name__ == "__main__":
    sys.exit(main())
