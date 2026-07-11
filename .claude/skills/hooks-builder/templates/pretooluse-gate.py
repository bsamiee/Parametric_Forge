#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
# PreToolUse gate: admit once, decompose each command to leaves, dispatch per argv[0] on a semantic table, fail closed by
# construction. Wire: PreToolUse matcher "Bash|Edit|Write" (Codex "Bash|apply_patch"). The POLICY tables are the edit surface.
# Boundary kernel: os.environ/os.getcwd/subprocess are admitted here per the scripting boundary-kernel carve-out. The ASK stdout-JSON
# branch is Claude-only dialect; under Codex the adapter maps it, so a dual-provider wiring routes this body through codex-adapter.sh.
import os
import re
import shlex
import sys
from collections.abc import Callable
from enum import StrEnum
from pathlib import Path, PurePosixPath

import msgspec

_IFS = re.compile(r"\$\{IFS[^}]*\}|\$IFS")  # de-obfuscate rm${IFS}-rf${IFS}/ and $IFS-split forms before lexing
_ENV_ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")  # a leading NAME=value env-prefix is stripped before the argv[0] command
_DOLLAR_SUB = re.compile(r"\$\(")  # command-substitution open; the matching close is scanned with paren depth
_BACKTICK = re.compile(r"`([^`]*)`")  # backtick substitution; the inner command executes and is descended like $(...)

PROJECT_ROOT = PurePosixPath(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))
PROJECT_REAL = Path(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())).resolve()  # symlink-resolved root for file-tool checks
HOME = PurePosixPath(os.environ.get("HOME", "/nonexistent"))
WRAPPERS = frozenset(("sudo", "doas", "env", "command", "nice", "nohup", "stdbuf", "timeout", "xargs"))
SHELLS = frozenset(("sh", "bash", "zsh", "dash", "ksh"))
INTERPRETERS = frozenset(("python", "python3", "node", "ruby", "perl"))
PROTECTED = frozenset((".env", ".pem", ".key", "credentials", "id_rsa", "id_ed25519"))  # POLICY: protected basenames
DANGER_ROOTS = frozenset((PurePosixPath("/"), HOME))  # POLICY: rm targets that block outright
TEMP_ROOTS = (PurePosixPath("/tmp"), PurePosixPath("/var/tmp"))  # POLICY: rm targets that always allow
BLOCKED_ARGV: dict[str, str] = {"dd": "raw disk write", "mkfs": "filesystem format", "shred": "irreversible wipe"}  # POLICY


class Verdict(StrEnum):
    ALLOW = "allow"
    DENY = "deny"
    ASK = "ask"


class Ruling(msgspec.Struct, frozen=True):
    verdict: Verdict = Verdict.ALLOW
    reason: str = ""


class ToolInput(msgspec.Struct, frozen=True):
    command: str = ""
    file_path: str = ""
    old_string: str = ""
    new_string: str = ""
    content: str = ""


class PreToolUse(msgspec.Struct, frozen=True, rename={"event": "hook_event_name"}):
    tool_name: str = ""
    tool_input: ToolInput = msgspec.field(default_factory=ToolInput)
    event: str = ""


def _canonical(target: str, /) -> PurePosixPath:  # resolve ~/.. against roots without touching the filesystem
    raw = target.replace("$HOME", str(HOME)).replace("${HOME}", str(HOME))
    expanded = str(HOME) if raw in {"~", "~/"} else (str(HOME) + raw[1:] if raw.startswith("~/") else raw)  # bare ~ -> HOME
    path = PurePosixPath(expanded) if expanded.startswith("/") else PROJECT_ROOT / expanded
    stack: list[str] = []
    for part in path.parts:
        stack.pop() if part == ".." and stack[1:] else None if part in {".", ".."} else stack.append(part)
    return PurePosixPath(*stack)


def _escapes(path: str, /) -> bool:  # a real resolve follows symlinks out of the sandbox; the pure canon covers a missing path
    target = Path(path) if Path(path).is_absolute() else PROJECT_REAL / path
    return not (target.resolve().is_relative_to(PROJECT_REAL) and _canonical(path).is_relative_to(PROJECT_ROOT))


def _subs(command: str, /) -> tuple[str, list[str]]:  # lift `...` and $(...) bodies out; each executes and is descended
    inner: list[str] = []
    stripped = _BACKTICK.sub(lambda m: (inner.append(m.group(1)), " ")[1], command)
    out, i = [], 0
    while (hit := _DOLLAR_SUB.search(stripped, i)) is not None:  # scan a balanced $(...), tolerating nesting
        start, depth, j = hit.end(), 1, hit.end()
        while j < len(stripped) and depth:
            depth += (stripped[j] == "(") - (stripped[j] == ")")
            j += 1
        out.append(stripped[hit.start() : j])
        inner.append(stripped[start : j - 1])
        i = j
    return stripped, inner


def _leaves(command: str, /, *, depth: int = 0) -> list[list[str]]:  # quote-aware split, sub descent, wrapper strip, shell/interp descent
    stripped, inner = _subs(command)  # a substitution body executes; descend it before lexing the outer command
    out: list[list[str]] = [leaf for body in inner if depth < 8 for leaf in _leaves(body, depth=depth + 1)]
    lexer = shlex.shlex(_IFS.sub(" ", stripped), posix=True, punctuation_chars=";&|<>()\n\r")
    lexer.whitespace, lexer.whitespace_split = " \t\f\v", True  # newline is punctuation, not whitespace, so it separates a chain
    argv: list[str] = []
    for token in lexer:  # a ValueError on unbalanced quotes propagates to the fail-closed seam
        if token in {";", "&&", "||", "|", "&", "(", ")"} or (token and all(c in ";&|\n" for c in token)):  # newline == ;
            out += _resolve(argv, depth=depth) if argv else []
            argv = []
        else:
            argv.append(token)
    return out + (_resolve(argv, depth=depth) if argv else [])


def _resolve(argv: list[str], /, *, depth: int) -> list[list[str]]:
    changed = True
    while changed and argv:  # peel any interleaving of leading NAME=value env-prefixes and wrappers-with-options
        changed = False
        while argv and _ENV_ASSIGN.match(argv[0]):  # a bare env-prefix has no wrapper; strip it before argv[0] resolves
            argv, changed = argv[1:], True
        while argv and argv[0] in WRAPPERS:  # drop the wrapper, then its options, assignments, and positional durations
            argv, changed = argv[1:], True
            while argv and (argv[0].startswith("-") or "=" in argv[0] or argv[0].isdigit()):
                argv = argv[1:]
    if not argv:
        return []
    if depth < 8 and argv[0] in SHELLS and (inner := _flag_operand(argv, "c")):  # -c, -lc, -ec, clustered: any shell flag carrying c
        return _leaves(inner, depth=depth + 1)
    if argv[0] in INTERPRETERS and (_flag_operand(argv, "c") or _flag_operand(argv, "e")):
        return [["\0interp"]]  # an inline interpreter one-liner is opaque; classify fail-closed, never scan its body for keywords
    return [argv]


def _flag_operand(argv: list[str], letter: str, /) -> str:  # the operand after a short flag carrying `letter`, clustered or not
    return next((argv[i + 1] for i, t in enumerate(argv) if t.startswith("-") and not t.startswith("--") and letter in t and i + 1 < len(argv)), "")


def _classify_rm(argv: list[str], /) -> Ruling:
    flags = "".join(t[1:] for t in argv if t.startswith("-") and not t.startswith("--"))
    targets = [t for t in argv[1:] if not t.startswith("-")]
    if not ({"r", "f"} & set(flags) or "--recursive" in argv or "--force" in argv):
        return Ruling()
    for target in targets:
        if any(ch in target for ch in "$`*"):
            return Ruling(Verdict.DENY, f"rm target {target!r} is dynamic or globbed; unverifiable")
        canon = _canonical(target)
        if canon in DANGER_ROOTS or canon == PROJECT_ROOT:
            return Ruling(Verdict.DENY, f"rm -rf targets {canon}; catastrophic")
        if not any(canon.is_relative_to(root) for root in (*TEMP_ROOTS, PROJECT_ROOT)):
            return Ruling(Verdict.ASK, f"rm -rf {canon} lands outside project and temp roots")
    return Ruling()


GIT_BLOCK: dict[str, tuple[str, ...]] = {  # POLICY: subcommand -> flag fragments that destroy work
    "checkout": ("--", "-f", "--force"),
    "reset": ("--hard",),
    "clean": ("-f", "-fd", "-fdx"),
    "push": ("--force", "-f"),
    "branch": ("-D",),
    "stash": ("drop", "clear"),
    "rebase": ("--abort",),
}


def _classify_git(argv: list[str], /) -> Ruling:
    sub = next((t for t in argv[1:] if not t.startswith("-")), "")
    fragments = GIT_BLOCK.get(sub, ())
    return Ruling(Verdict.DENY, f"git {sub} {' '.join(argv[2:])} discards work") if any(f in argv[2:] for f in fragments) else Ruling()


ANALYZERS: dict[str, Callable[[list[str]], Ruling]] = {"rm": _classify_rm, "git": _classify_git}  # POLICY: argv[0] -> analyzer


def _classify(argv: list[str], /) -> Ruling:
    if argv[0] == "\0interp":
        return Ruling(Verdict.DENY, "inline interpreter one-liner is opaque; denied by default")  # fail-closed, never a keyword denylist
    if analyzer := ANALYZERS.get(PurePosixPath(argv[0]).name):
        return analyzer(argv)
    name = PurePosixPath(argv[0]).name
    return Ruling(Verdict.DENY, BLOCKED_ARGV[name]) if name in BLOCKED_ARGV else Ruling()


def _bash(tool_input: ToolInput, /) -> Ruling:
    return next((r for leaf in _leaves(tool_input.command) if (r := _classify(leaf)).verdict is not Verdict.ALLOW), Ruling())


def _file(tool_input: ToolInput, /) -> Ruling:
    name = PurePosixPath(tool_input.file_path).name
    if name in PROTECTED:
        return Ruling(Verdict.DENY, f"{name} is a protected secret file")
    return Ruling(Verdict.DENY, "path escapes the project sandbox") if _escapes(tool_input.file_path) else Ruling()


def _decide(payload: PreToolUse, /) -> Ruling:
    match payload.tool_name:
        case "Bash":
            return _bash(payload.tool_input)
        case "Edit" | "Write" | "MultiEdit" | "apply_patch":
            return _file(payload.tool_input)
        case _:
            return Ruling()


def main() -> int:
    try:
        payload = msgspec.json.decode(sys.stdin.buffer.read(), type=PreToolUse)
        ruling = _decide(payload)
    except Exception as failure:  # fail closed by construction: any parse, decode, or analysis fault denies
        print(f"gate failed closed: {failure}", file=sys.stderr)
        return 2
    if ruling.verdict is Verdict.DENY:
        print(ruling.reason, file=sys.stderr)
        return 2
    if ruling.verdict is Verdict.ASK:
        body = {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": ruling.reason}}
        sys.stdout.write(msgspec.json.encode(body).decode())
    return 0


if __name__ == "__main__":
    sys.exit(main())
