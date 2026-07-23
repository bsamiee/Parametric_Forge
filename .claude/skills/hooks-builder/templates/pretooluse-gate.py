#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
# Boundary-kernel hook seam: fail-closed broad-except, focused one-line docstrings, and POLICY danger-root literals, never temp-file creation.
# ruff: noqa: BLE001, DOC201, S108
"""Gate a PreToolUse call: admit once, decompose each command to leaves, dispatch per argv[0] on a semantic table, fail closed by construction.

Wire: PreToolUse matcher "Bash|Edit|Write|NotebookEdit" (Codex "Bash|apply_patch"). The POLICY tables are the edit surface.
Boundary kernel: os.environ/os.getcwd/subprocess are admitted here per the scripting boundary-kernel carve-out. The ASK stdout-JSON
branch is Claude-only dialect; under Codex the adapter maps it, so a dual-provider wiring routes this body through codex-adapter.sh.
"""

from collections.abc import Callable
from enum import StrEnum
import os
from pathlib import Path, PurePosixPath
import re
import shlex
import sys

import msgspec


_IFS = re.compile(r"\$\{IFS[^}]*\}|\$IFS")  # de-obfuscate rm${IFS}-rf${IFS}/ and $IFS-split forms before lexing
_ENV_ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")  # a leading NAME=value env-prefix is stripped before the argv[0] command
_DOLLAR_SUB = re.compile(r"\$\(")  # command-substitution open; the matching close is scanned with paren depth
_BACKTICK = re.compile(r"`([^`]*)`")  # backtick substitution; the inner command executes and is descended like $(...)
CTRL = re.compile(r"[\x00-\x1f\x7f]+")  # scrub control chars from untrusted text before it reaches a terminal-facing reason
_PATCH_TARGET = re.compile(r"^\*\*\* (?:(?:Add|Update|Delete) File|Move to): (.+)$", re.MULTILINE)  # apply_patch envelope target paths

HOME = PurePosixPath(os.environ.get("HOME", "/nonexistent"))
WRAPPERS = frozenset(("sudo", "doas", "env", "command", "nice", "nohup", "stdbuf", "timeout", "xargs"))
SHELLS = frozenset(("sh", "bash", "zsh", "dash", "ksh"))
INTERPRETERS = frozenset(("python", "python3", "node", "ruby", "perl"))
PROTECTED = frozenset((".env", ".pem", ".key", "credentials", "id_rsa", "id_ed25519"))  # POLICY: protected basenames
DANGER_ROOTS = frozenset((PurePosixPath("/"), HOME))  # POLICY: rm targets that block outright
TEMP_ROOTS = (PurePosixPath("/tmp"), PurePosixPath("/var/tmp"))  # POLICY: rm targets that always allow
BLOCKED_ARGV: dict[str, str] = {"dd": "raw disk write", "mkfs": "filesystem format", "shred": "irreversible wipe"}  # POLICY
MAX_PAYLOAD = 8 * 1024 * 1024  # bound the stdin read; a pathological payload never balloons resident memory


class Verdict(StrEnum):
    """Permission verdict for a tool call."""

    ALLOW = "allow"
    DENY = "deny"
    ASK = "ask"


class Ruling(msgspec.Struct, frozen=True):
    """Verdict paired with its reason."""

    verdict: Verdict = Verdict.ALLOW
    reason: str = ""


class ToolInput(msgspec.Struct, frozen=True):
    """Tool-call input fields across Bash and file tools."""

    command: str = ""
    file_path: str = ""
    notebook_path: str = ""  # NotebookEdit names its target here, never file_path
    old_string: str = ""
    new_string: str = ""
    content: str = ""

    @property
    def target(self) -> str:
        """Resolve the one edited path across the file tools' divergent field names."""
        return self.file_path or self.notebook_path


class PreToolUse(msgspec.Struct, frozen=True, rename={"event": "hook_event_name"}):
    """Decoded PreToolUse hook payload."""

    tool_name: str = ""
    tool_input: ToolInput = msgspec.field(default_factory=ToolInput)
    cwd: str = ""  # the sandbox root, certified on both providers' stdin; the env var is Claude-only and falls back to os.getcwd()
    event: str = ""


class Roots(msgspec.Struct, frozen=True):
    """Sandbox roots for one call: pure-lexical for canonicalization, symlink-resolved for file-tool checks."""

    pure: PurePosixPath
    real: Path


def _sandbox(cwd: str, /) -> Roots:
    """Derive the sandbox from the payload cwd; the env var serves only a payload that omits it, never as the primary root."""
    base = cwd or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
    return Roots(PurePosixPath(base), Path(base).resolve())


def _canonical(target: str, roots: Roots, /) -> PurePosixPath:
    """Resolve ~/.. against project and home roots without touching the filesystem."""
    raw = target.replace("$HOME", str(HOME)).replace("${HOME}", str(HOME))  # noqa: RUF027 — literal shell tokens, not f-strings
    expanded = str(HOME) if raw in {"~", "~/"} else (str(HOME) + raw[1:] if raw.startswith("~/") else raw)  # bare ~ -> HOME
    path = PurePosixPath(expanded) if expanded.startswith("/") else roots.pure / expanded
    stack: list[str] = []
    for part in path.parts:
        stack.pop() if part == ".." and stack[1:] else None if part in {".", ".."} else stack.append(part)
    return PurePosixPath(*stack)


def _escapes(path: str, roots: Roots, /) -> bool:
    """Report whether a path escapes the sandbox; real-resolve follows symlinks out, pure-canon covers a missing path."""
    target = Path(path) if Path(path).is_absolute() else roots.real / path
    return not (target.resolve().is_relative_to(roots.real) and _canonical(path, roots).is_relative_to(roots.pure))


def _subs(command: str, /) -> tuple[str, list[str]]:
    """Lift backtick and $(...) substitution bodies out of a command; each executes and is descended."""
    inner: list[str] = _BACKTICK.findall(command)  # backtick bodies, collected before the outer command is lexed
    stripped, i = _BACKTICK.sub(" ", command), 0
    while (hit := _DOLLAR_SUB.search(stripped, i)) is not None:  # scan a balanced $(...), tolerating nesting
        depth, j = 1, hit.end()
        while j < len(stripped) and depth:
            depth += (stripped[j] == "(") - (stripped[j] == ")")
            j += 1
        inner.append(stripped[hit.end() : j - 1])
        i = j
    return stripped, inner


def _leaves(command: str, /, *, depth: int = 0) -> list[list[str]]:
    """Decompose a command into argv leaves via quote-aware split, sub descent, wrapper strip, and shell/interp descent."""
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
    """Peel env-prefixes and wrappers, then descend a shell -c or inline interpreter command into leaves."""
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


def _flag_operand(argv: list[str], letter: str, /) -> str:
    """Return the operand after a short flag carrying letter, clustered or not."""
    return next((argv[i + 1] for i, t in enumerate(argv) if t.startswith("-") and not t.startswith("--") and letter in t and i + 1 < len(argv)), "")


def _classify_rm(argv: list[str], roots: Roots, /) -> Ruling:
    """Rule on an rm invocation by recursion/force flags against danger, temp, and project roots."""
    flags = "".join(t[1:] for t in argv if t.startswith("-") and not t.startswith("--"))
    targets = [t for t in argv[1:] if not t.startswith("-")]
    if not ({"r", "f"} & set(flags) or "--recursive" in argv or "--force" in argv):
        return Ruling()
    for target in targets:
        if any(ch in target for ch in "$`*"):
            return Ruling(Verdict.DENY, f"rm target {CTRL.sub(' ', target)!r} is dynamic or globbed; unverifiable")
        canon = _canonical(target, roots)
        if canon in DANGER_ROOTS or canon == roots.pure:
            return Ruling(Verdict.DENY, f"rm -rf targets {CTRL.sub(' ', str(canon))}; catastrophic")
        if not any(canon.is_relative_to(root) for root in (*TEMP_ROOTS, roots.pure)):
            return Ruling(Verdict.ASK, f"rm -rf {CTRL.sub(' ', str(canon))} lands outside project and temp roots")
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


def _classify_git(argv: list[str], _roots: Roots, /) -> Ruling:
    """Rule on a git invocation whose subcommand plus flags would discard work."""
    sub = next((t for t in argv[1:] if not t.startswith("-")), "")
    fragments = GIT_BLOCK.get(sub, ())
    return (
        Ruling(Verdict.DENY, f"git {CTRL.sub(' ', sub)} {CTRL.sub(' ', ' '.join(argv[2:]))} discards work")
        if any(f in argv[2:] for f in fragments)
        else Ruling()
    )


ANALYZERS: dict[str, Callable[[list[str], Roots], Ruling]] = {"rm": _classify_rm, "git": _classify_git}  # POLICY: argv[0] -> analyzer


def _classify(argv: list[str], roots: Roots, /) -> Ruling:
    """Dispatch one argv leaf to its analyzer, denying opaque interpreters and blocked commands."""
    if argv[0] == "\0interp":
        return Ruling(Verdict.DENY, "inline interpreter one-liner is opaque; denied by default")  # fail-closed, never a keyword denylist
    if analyzer := ANALYZERS.get(PurePosixPath(argv[0]).name):
        return analyzer(argv, roots)
    name = PurePosixPath(argv[0]).name
    return Ruling(Verdict.DENY, BLOCKED_ARGV[name]) if name in BLOCKED_ARGV else Ruling()


def _bash(tool_input: ToolInput, roots: Roots, /) -> Ruling:
    """Rule on a Bash tool call by its first non-allow leaf."""
    return next((r for leaf in _leaves(tool_input.command) if (r := _classify(leaf, roots)).verdict is not Verdict.ALLOW), Ruling())


def _file(tool_input: ToolInput, roots: Roots, /) -> Ruling:
    """Rule on a file tool call against protected basenames and sandbox escape."""
    name = PurePosixPath(tool_input.target).name
    if name in PROTECTED:
        return Ruling(Verdict.DENY, f"{CTRL.sub(' ', name)} is a protected secret file")
    return Ruling(Verdict.DENY, "path escapes the project sandbox") if _escapes(tool_input.target, roots) else Ruling()


def _apply_patch(tool_input: ToolInput, roots: Roots, /) -> Ruling:
    """Rule on an apply_patch call by sandbox-checking each target in the patch envelope; no readable target denies fail-closed."""
    targets = [t.strip() for t in _PATCH_TARGET.findall(tool_input.command or tool_input.content)]
    if not targets:
        return Ruling(Verdict.DENY, "apply_patch carries no readable target path; denied by default")  # never an empty file_path allow
    hit = next((t for t in targets if PurePosixPath(t).name in PROTECTED or _escapes(t, roots)), "")
    return Ruling(Verdict.DENY, f"apply_patch target {CTRL.sub(' ', hit)} is protected or escapes the sandbox") if hit else Ruling()


def _decide(payload: PreToolUse, /) -> Ruling:
    """Route a payload to its per-tool ruling under the payload-derived sandbox; apply_patch reads its target from the patch body."""
    roots = _sandbox(payload.cwd)
    match payload.tool_name:
        case "Bash":
            return _bash(payload.tool_input, roots)
        case "Edit" | "Write" | "NotebookEdit":
            return _file(payload.tool_input, roots)
        case "apply_patch":
            return _apply_patch(payload.tool_input, roots)
        case _:
            return Ruling()


def main() -> int:
    """Decode stdin, decide, and emit the verdict via exit code and hook JSON."""
    try:
        payload = msgspec.json.decode(sys.stdin.buffer.read(MAX_PAYLOAD), type=PreToolUse)
        ruling = _decide(payload)
    except Exception as failure:  # fail closed by construction: any parse, decode, or analysis fault denies
        sys.stderr.write(f"gate failed closed: {failure}\n")
        return 2
    if ruling.verdict is Verdict.DENY:
        sys.stderr.write(f"{ruling.reason}\n")
        return 2
    if ruling.verdict is Verdict.ASK:
        body = {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": ruling.reason}}
        sys.stdout.write(msgspec.json.encode(body).decode())
    return 0


if __name__ == "__main__":
    sys.exit(main())
