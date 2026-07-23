#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec", "anyio"]
# ///
# Boundary-kernel hook seam: focused one-line docstrings, a nested command scan, a boundary-admission try, fail-open telemetry, and runtime-resolved msgspec annotations are admitted.
# ruff: noqa: DOC201, PLR1702, PLW0717, S110, TC002
"""Route every hook event through a priority-banded handler registry, optionally behind a resident daemon.

Two run modes share one body: a resident daemon (`--serve`) holds the registry, its structs, and its handler
imports in-process across every firing, and a per-firing client forwards stdin over a session-scoped Unix socket,
so a fleet whose handlers carry heavy admission pays it once at load, not per call. When no daemon answers the
client runs the registry in-process, so the hook never depends on it. anyio owns both socket ends: the server's
structured task group cancels every in-flight handler on one SIGTERM and unlinks the socket, leaving no orphan
thread or stale endpoint behind.
"""

from collections.abc import Callable
from enum import IntEnum
import os
from pathlib import Path, PurePosixPath
import re
import shlex
import signal
import sys

import anyio
from anyio.abc import SocketStream
import msgspec


SOCKET_ENV = "HOOK_DISPATCH_SOCKET"  # explicit socket path override; else derived per project below
STATE_ROOT = Path(os.environ.get("CLAUDE_PLUGIN_DATA") or os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state")))
PROTECTED = frozenset((".env", ".pem", ".key", "id_rsa", "id_ed25519", "credentials"))  # POLICY: basenames a write blocks
DANGER_ROOTS = frozenset((PurePosixPath("/"), PurePosixPath(os.environ.get("HOME", "/nonexistent"))))  # POLICY: rm block tier
WRAPPERS = frozenset(("sudo", "env", "command", "nice", "nohup", "time", "xargs", "builtin", "exec"))  # peeled to reach the real argv[0]
ENV_ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")  # a leading NAME=value shell env-prefix, stripped before classifying the leaf
IFS_SUB = re.compile(r"\$\{?IFS\}?")  # $IFS de-obfuscation: a split hidden behind the field separator resolves to a space
PATCH_TARGET = re.compile(r"^\*\*\* (?:(?:Add|Update|Delete) File|Move to): (.+)$", re.MULTILINE)  # apply_patch targets incl. rename destinations
OPAQUE = "\0opaque"  # a leaf marker for an unparseable command; the safety band denies it fail-closed
CTRL = re.compile(r"[\x00-\x1f\x7f]+")  # control-char scrub for untrusted text flowing into a terminal-facing reason
MAX_PAYLOAD = 8 * 1024 * 1024  # bound the stdin read; a pathological tool_response never balloons resident memory
CLIENT_TIMEOUT = 2.0  # a wedged daemon never strands the client; on expiry the in-process fallback runs
READ_TIMEOUT = 5.0  # a client that connects but never half-closes never wedges the daemon's drain loop
RECV = 65536


class Band(IntEnum):
    """Ascending dispatch order; the first terminal DENY in band order wins."""

    SAFETY = 10
    QUALITY = 30
    ADVISORY = 60
    TELEMETRY = 90


class Code(IntEnum):
    """Hook exit codes: 0 permits, 2 blocks."""

    OK = 0
    BLOCK = 2


class ToolInput(msgspec.Struct, frozen=True):
    """The tool-call fields the safety band inspects."""

    command: str = ""
    file_path: str = ""
    notebook_path: str = ""  # NotebookEdit names its target here, never file_path

    @property
    def target(self) -> str:
        """Resolve the one written path across the file tools' divergent field names."""
        return self.file_path or self.notebook_path


class Envelope(msgspec.Struct, frozen=True, rename={"event": "hook_event_name"}):
    """The shared stdin payload, admitted once at the dispatch seam."""

    event: str = ""
    session_id: str = ""
    tool_name: str = ""
    tool_input: ToolInput = msgspec.field(default_factory=ToolInput)


class Verdict(msgspec.Struct, frozen=True):
    """A handler's ruling, serialized to the client as a Reply."""

    code: Code = Code.OK
    reason: str = ""


class Reply(msgspec.Struct, frozen=True):
    """The daemon-to-client wire; the client replays the reason and exits the code."""

    code: int = 0
    reason: str = ""


class Handler(msgspec.Struct, frozen=True):
    """One registry row: an event, its band, whether a DENY is terminal, and the verdict function."""

    event: str
    band: Band
    terminal: bool
    run: Callable[[Envelope], Verdict]


def _peel(leaf: list[str], /) -> list[str]:
    """Drop a leading NAME=value env-prefix and any command wrapper so leaf[0] is the real executable, never a decoy head."""
    index = 0
    while index < len(leaf) and (ENV_ASSIGN.match(leaf[index]) or PurePosixPath(leaf[index]).name in WRAPPERS):
        index += 1
    return leaf[index:]


def _leaves(command: str, /) -> list[list[str]]:
    """Decompose a command into per-chain argv leaves: $IFS de-obfuscation, punctuation-aware split, env/wrapper peel; opaque on a bad quote."""
    lexer = shlex.shlex(IFS_SUB.sub(" ", command), posix=True, punctuation_chars=";&|<>()\n\r")
    lexer.whitespace, lexer.whitespace_split = " \t\f\v", True  # a glued `x;rm` still splits: the operator is its own token
    out: list[list[str]] = []
    leaf: list[str] = []
    try:
        tokens = list(lexer)
    except ValueError:
        return [[OPAQUE]]  # an unbalanced quote is unclassifiable; the safety band denies it rather than admitting the bytes
    for token in tokens:
        if set(token) <= set(";&|<>()"):  # a pure chain/redirection operator ends the current leaf
            out.append(_peel(leaf))
            leaf = []
        else:
            leaf.append(token)
    out.append(_peel(leaf))
    return [row for row in out if row]


def _safety(payload: Envelope, /) -> Verdict:
    """Block danger-root rm and protected-file writes, fail-closed on the SAFETY band."""
    match payload.tool_name:
        case "Bash":
            leaves = _leaves(payload.tool_input.command)
            if any(leaf[:1] == [OPAQUE] for leaf in leaves):
                return Verdict(Code.BLOCK, "unparseable command; failing closed")  # an opaque leaf denies, never admits by omission
            targets = (t for leaf in leaves if leaf[:1] == ["rm"] for t in leaf[1:])
            hit = next((t for t in targets if not t.startswith("-") and PurePosixPath(t) in DANGER_ROOTS), "")
            return Verdict(Code.BLOCK, f"rm targets {CTRL.sub(' ', hit)}; catastrophic") if hit else Verdict()
        case "Edit" | "Write" | "NotebookEdit":
            name = PurePosixPath(payload.tool_input.target).name
            return Verdict(Code.BLOCK, f"{CTRL.sub(' ', name)} is a protected secret file") if name in PROTECTED else Verdict()
        case "apply_patch":  # targets ride the patch envelope in command, never file_path; no readable target denies fail-closed
            targets = [t.strip() for t in PATCH_TARGET.findall(payload.tool_input.command)]
            if not targets:
                return Verdict(Code.BLOCK, "apply_patch carries no readable target path; failing closed")
            hit = next((t for t in targets if PurePosixPath(t).name in PROTECTED), "")
            return Verdict(Code.BLOCK, f"apply_patch target {CTRL.sub(' ', hit)} is a protected secret file") if hit else Verdict()
        case _:
            return Verdict()


def _telemetry(payload: Envelope, /) -> Verdict:
    """Record the firing to a session log on the TELEMETRY band; never blocks."""
    log = STATE_ROOT / "claude" / "dispatch" / f"{payload.session_id or 'anon'}.jsonl"
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("ab") as sink:  # append-only; JSON encoding escapes any control byte in the payload before it lands
        sink.write(msgspec.json.encode({"event": payload.event, "tool": payload.tool_name}) + b"\n")
    return Verdict()


REGISTRY: tuple[Handler, ...] = (  # POLICY rows; a new capability is one row, ordered by band, terminal where it enforces
    Handler(event="PreToolUse", band=Band.SAFETY, terminal=True, run=_safety),
    Handler(event="PreToolUse", band=Band.TELEMETRY, terminal=False, run=_telemetry),
    Handler(event="PostToolUse", band=Band.TELEMETRY, terminal=False, run=_telemetry),
)


def dispatch(raw: bytes, /) -> Verdict:
    """Sort matching handlers by band, run each, and stop at the first terminal DENY."""
    try:
        payload = msgspec.json.decode(raw, type=Envelope)
    except msgspec.DecodeError:
        return Verdict(Code.BLOCK, "malformed dispatch payload; failing closed")  # gate rows present -> block disposition
    worst = Verdict()
    for handler in sorted((h for h in REGISTRY if h.event == payload.event), key=lambda h: h.band):
        if (verdict := handler.run(payload)).code is Code.BLOCK:
            if handler.terminal:
                return verdict
            worst = verdict
    return worst


def _socket_path() -> Path:
    """Derive the project-scoped socket path; an explicit env override wins."""
    override = os.environ.get(SOCKET_ENV)
    root = PurePosixPath(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())).name or "root"
    return Path(override) if override else STATE_ROOT / "claude" / "dispatch" / f"{root}.sock"


async def _handle(stream: SocketStream, /) -> None:
    """Drain one connection's payload, dispatch it, reply, and close."""
    async with stream:
        buffer = bytearray()
        try:
            with anyio.fail_after(READ_TIMEOUT):  # a half-open client never blocks the drain past the deadline
                while len(buffer) < MAX_PAYLOAD:
                    buffer += await stream.receive(RECV)
        except anyio.EndOfStream:
            pass  # the client half-closes its write end, so EndOfStream marks a complete payload
        except TimeoutError:
            return  # a client that connected but never half-closed is dropped, leaving the daemon responsive
        verdict = dispatch(bytes(buffer))
        await stream.send(msgspec.json.encode(Reply(code=int(verdict.code), reason=verdict.reason)))


async def _serve() -> None:
    """Bind once, hold the registry in-process, and tear down cleanly on a signal."""
    path = _socket_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.unlink(missing_ok=True)  # a stale socket from a dead daemon blocks bind; reclaim it before listening
    listener = await anyio.create_unix_listener(path)
    try:
        async with anyio.create_task_group() as group:
            _ = group.start_soon(_await_signal, group.cancel_scope)
            await listener.serve(_handle)  # structured: a signal cancels the scope, and every in-flight handler with it
    finally:
        await listener.aclose()
        path.unlink(missing_ok=True)  # no orphan endpoint survives the daemon


async def _await_signal(scope: anyio.CancelScope, /) -> None:
    """Cancel the serve scope on the first SIGINT or SIGTERM."""
    with anyio.open_signal_receiver(signal.SIGINT, signal.SIGTERM) as signals:
        async for _sig in signals:
            scope.cancel()
            return


async def _forward(raw: bytes, /) -> Reply | None:
    """Hand the payload to the daemon, or return None when none answers within the deadline."""
    try:
        with anyio.fail_after(CLIENT_TIMEOUT):
            stream = await anyio.connect_unix(_socket_path())
            async with stream:
                await stream.send(raw)
                await stream.send_eof()  # half-close so the daemon's drain loop sees a complete payload
                buffer = bytearray()
                try:
                    while True:
                        buffer += await stream.receive(RECV)
                except anyio.EndOfStream:
                    pass
                return msgspec.json.decode(bytes(buffer), type=Reply)
    except OSError, TimeoutError, anyio.BrokenResourceError, msgspec.DecodeError:
        return None  # no daemon, a wedged one, or a broken reply -> the in-process fallback keeps the hook self-sufficient


def main() -> int:
    """Serve on `--serve`, else forward to the daemon and fall back to in-process dispatch."""
    if "--serve" in sys.argv[1:]:
        anyio.run(_serve)
        return 0
    raw = sys.stdin.buffer.read(MAX_PAYLOAD)
    reply = anyio.run(_forward, raw) or Reply(code=int((verdict := dispatch(raw)).code), reason=verdict.reason)
    if reply.reason:
        sys.stderr.write(f"{reply.reason}\n")
    return reply.code


if __name__ == "__main__":
    sys.exit(main())
