#!/usr/bin/env python3
"""
Title         : tool_control.py
Author        : Bardia Samiee
Project       : Parametric Forge
License       : MIT
Path          : /01.home/00.core/configs/apps/claude/hooks/tool_control.py

Description
----------------------------------------------------------------------------
Advanced Claude hook for tool control, substitution, and security enforcement.

Implements defense-in-depth with tool substitution, command modernization,
dangerous pattern detection, and intelligent decision making. Based on proven
patterns from disler/claude-code-hooks-mastery and production implementations.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import sys
from functools import lru_cache
from typing import Final, TypedDict

class HookResponse(TypedDict, total=False):
    decision: str
    reason: str
    modifications: dict[str, str]

# --- Compiled Patterns -------------------------------------------------------
_DANGEROUS_COMPILED = [
    (re.compile(pattern, re.IGNORECASE), msg) for pattern, msg in [
        (r"rm\s+-rf\s+/", "System root deletion detected"),
        (r"rm\s+.*-[rf].*\s+~", "Home directory deletion detected"),
        (r"sudo\s+rm\s+-[rf]", "Sudo deletion detected"),
        (r":(){.*:\|:.*};:", "Fork bomb detected"),
        (r"dd\s+if=/dev/(zero|random)", "Disk overwrite detected"),
        (r"chmod\s+-R\s+777", "Dangerous permission change detected"),
        (r">\s*/etc/", "System file overwrite detected"),
        (r"curl.*\|\s*(bash|sh)", "Unsafe remote script execution detected"),
        (r"eval\s*\(", "Unsafe code evaluation detected"),
    ]
]

_PROTECTED_COMPILED = re.compile("|".join([
    r"\.env(?:\.|$)", r"package-lock\.json$", r"yarn\.lock$", r"Gemfile\.lock$",
    r"poetry\.lock$", r"\.git/", r"/etc/", r"\.ssh/"
]))

_ENV_EXAMPLE = re.compile(r"\.env\.(example|sample|template|dist)$")

# --- Tool Substitutions & Commands -------------------------------------------
TOOL_SUBSTITUTIONS: Final[dict[str, str]] = {
    "WebSearch": "mcp__perplexity-ask__perplexity_ask",
    "mcp__exa__deep_researcher_start": "mcp__perplexity-ask__perplexity_ask",
}

COMMAND_REPLACEMENTS: Final[dict[str, str]] = {
    "grep": "rg", "find": "fd", "cat": "bat", "ls": "eza", "ps": "procs",
    "top": "btm", "htop": "btm", "df": "duf", "du": "dust", "curl": "xh",
    "wget": "xh", "dig": "doggo", "ping": "gping", "diff": "delta",
    "hexdump": "hexyl", "tar": "ouch", "make": "just",
}

FILE_TOOLS = frozenset({
    "Write", "Edit", "MultiEdit", "Read", "mcp__filesystem__write_file",
    "mcp__filesystem__edit_file", "mcp__filesystem__read_file", "mcp__filesystem__move_file"
})

# --- Cached Tool Availability ------------------------------------------------
@lru_cache(maxsize=128)
def _tool_exists(tool: str) -> bool:
    return bool(shutil.which(tool))

# --- Response Helpers --------------------------------------------------------
def _modify_response(tool: str, input_data: str, reason: str | None = None) -> HookResponse:
    response = HookResponse(decision="modify", modifications={"tool": tool, "input": input_data})
    if reason:
        response["reason"] = reason
    return response

def _block_response(reason: str) -> HookResponse:
    return HookResponse(decision="block", reason=reason)

# --- Security & Modernization ------------------------------------------------
def _check_patterns(command: str) -> str | None:
    return next((msg for pattern, msg in _DANGEROUS_COMPILED if pattern.search(command)), None)

def _is_protected_file(file_path: str) -> bool:
    return bool(file_path and _PROTECTED_COMPILED.search(file_path))

def _modernize_command(command: str) -> str | None:
    for old_cmd, new_cmd in COMMAND_REPLACEMENTS.items():
        if _tool_exists(new_cmd) and (pattern := re.compile(rf'\b{re.escape(old_cmd)}\b')):
            if (modernized := pattern.sub(new_cmd, command)) != command:
                return modernized
    return None

def main() -> int:
    try:
        tool = os.environ.get("CLAUDE_TOOL_NAME", "")
        input_str = os.environ.get("CLAUDE_TOOL_INPUT", "{}")
        try:
            input_data = json.loads(input_str)
        except json.JSONDecodeError:
            return 0
        match tool:
            case t if t in TOOL_SUBSTITUTIONS:
                replacement = TOOL_SUBSTITUTIONS[t]
                response = _modify_response(replacement, input_str, f"Using {replacement} instead of {t}")
                print(json.dumps(response))
                return 0
            case t if t in FILE_TOOLS:
                if file_path := input_data.get("file_path", ""):
                    if _is_protected_file(file_path) and not _ENV_EXAMPLE.search(file_path):
                        response = _block_response(f"Access to {file_path} is restricted for security")
                        print(json.dumps(response))
                        return 0
            case "Bash":
                command = input_data.get("command", "")
                if danger := _check_patterns(command):
                    response = _block_response(f"SECURITY: {danger}")
                    print(json.dumps(response), file=sys.stderr)
                    return 2
                if modernized := _modernize_command(command):
                    input_data["command"] = modernized
                    response = _modify_response("Bash", json.dumps(input_data),
                                              f"Modernized: {command[:30]}... → {modernized[:30]}...")
                    print(json.dumps(response))
                    return 0
            case _:
                pass
        return 0
    except Exception as e:
        print(f"Hook error: {e}", file=sys.stderr)
        return 0

if __name__ == "__main__":
    sys.exit(main())
