#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec"]
# ///
"""Approve a matched-safe PermissionRequest and persist a standing addRules rule, so it never re-prompts.

Approval keys on tool identity and argument shape, never a free-text command substring, and the matcher wiring
stays narrow — a .* matcher auto-clears writes the author never saw. Codex PermissionRequest accepts only
decision.behavior and fails closed on the rewrite fields, so this body strips updatedPermissions under the codex
brand; an unmatched call no-ops to the normal prompt, never a deny.
"""

import os
from pathlib import PurePosixPath
import sys

import msgspec


BRAND = os.environ.get("HOOK_PROVIDER", "claude")  # codex fails closed on updatedPermissions, so the durable rule is Claude-only
SAFE_TOOLS = frozenset(("Read", "Glob", "Grep", "NotebookRead"))  # POLICY: read-only tools cleared wholesale by identity
SAFE_BASH = frozenset(("ls", "cat", "pwd", "rg", "fd", "tree", "head", "tail", "wc", "loc"))  # POLICY: read-only argv[0]
SAFE_GIT = frozenset(("status", "log", "diff", "show", "branch", "remote"))  # POLICY: read-only git subcommands
SHELL_META = frozenset(";|&<>()$`\n\\")  # POLICY: a chain, pipe, substitution, redirection, or newline-split hides a second command
MAX_PAYLOAD = 8 * 1024 * 1024  # bound the stdin read; a pathological payload never balloons resident memory


class ToolInput(msgspec.Struct, frozen=True):
    """The Bash command field the rule builder inspects."""

    command: str = ""


class Request(msgspec.Struct, frozen=True, rename={"event": "hook_event_name"}):
    """Decoded PermissionRequest hook payload."""

    event: str = ""
    tool_name: str = ""
    tool_input: ToolInput = msgspec.field(default_factory=ToolInput)


def _rule(request: Request, /) -> tuple[str, str] | None:
    """Resolve the standing rule as (toolName, ruleContent); ruleContent empty means a whole-tool rule, None means not identity-safe."""
    if request.tool_name in SAFE_TOOLS:
        return request.tool_name, ""  # a whole-tool rule omits ruleContent downstream
    if request.tool_name != "Bash":
        return None
    command = request.tool_input.command
    if SHELL_META & set(command):  # reject before argv[0] classify: `cat x; rm -rf /` splits to a safe head yet runs a second command
        return None
    argv = command.split()
    head = PurePosixPath(argv[0]).name if argv else ""
    if head == "git" and len(argv) > 1 and argv[1] in SAFE_GIT:
        return "Bash", f"git {argv[1]}:*"  # ruleContent is the inner permission content, not the wrapped Bash(...) form
    return ("Bash", f"{head}:*") if head in SAFE_BASH else None


def _body(tool_name: str, rule_content: str, /) -> dict[str, object]:
    """Build the allow decision; the Claude dialect carries the durable rule, codex takes behavior only."""
    decision: dict[str, object] = {"behavior": "allow"}
    if BRAND != "codex":  # codex reserves updatedPermissions/updatedInput and fails closed, so omit them under that brand
        rule = {"toolName": tool_name} if not rule_content else {"toolName": tool_name, "ruleContent": rule_content}  # omit for whole-tool
        entry = {"type": "addRules", "rules": [rule], "behavior": "allow", "destination": "localSettings"}
        decision["updatedPermissions"] = [entry]
    return {"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": decision}}


def main() -> int:
    """Emit an auto-approve for an identity-safe call, else fall through to the interactive prompt."""
    try:
        request = msgspec.json.decode(sys.stdin.buffer.read(MAX_PAYLOAD), type=Request)
    except msgspec.DecodeError:
        return 0  # observer disposition: a malformed payload defers to the normal prompt, never a spurious allow
    if rule := _rule(request):
        sys.stdout.write(msgspec.json.encode(_body(*rule)).decode())
    return 0  # an unmatched call emits nothing and falls through to the interactive prompt


if __name__ == "__main__":
    sys.exit(main())
