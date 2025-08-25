#!/usr/bin/env python3
"""
Title         : tool_control.py
Author        : Bardia Samiee
Project       : Parametric Forge
License       : MIT
Path          : /01.home/02.assets/ai/claude/hooks/tool_control.py

Description
----------------------------------------------------------------------------
Simple tool blocker and substitution.

Provides intelligent tool blocking and substitution for Claude's tool usage,
replacing legacy tools with modern alternatives and blocking unsafe operations.
Handles both web search replacements and shell command modernization.
"""
from __future__ import annotations

import json
import os
import sqlite3
import sys
from pathlib import Path
from typing import Any, Final


# --- Configuration -----------------------------------------------------------
SUBSTITUTIONS: Final[dict[str, str]] = {
    # Web/search replacements
    "WebSearch": "mcp__perplexity-ask__perplexity_ask",
    "mcp__exa__deep_researcher_start": "mcp__perplexity-ask__perplexity_ask",
    # Shell command replacements with modern tools
    "grep": "rg",  # ripgrep (ultra-fast)
    "find": "fd",  # fd (respects .gitignore)
    "cat": "bat",  # bat (syntax highlighting)
    "ls": "eza",  # eza (git integration, icons)
    "ps": "procs",  # procs (tree, search, color)
    "top": "btm",  # bottom (graphs)
    "htop": "btm",  # bottom
    "df": "duf",  # duf (visual bars)
    "du": "dust",  # dust (tree view)
    "curl": "xh",  # xh (intuitive syntax)
    "wget": "xh",  # xh
    "dig": "doggo",  # doggo (colors, DoH/DoT)
    "ping": "gping",  # gping (real-time graphs)
    "cd": "z",  # zoxide (smart jumper)
    "diff": "delta",  # delta (syntax-aware)
    "hexdump": "hexyl",  # hexyl (colorful)
    "tar": "ouch",  # ouch (universal archive)
    "make": "just",  # just (modern task runner)
}

BLOCKED: Final[frozenset[str]] = frozenset({
    "WebSearch",
    "mcp__filesystem__write_file",
    "mcp__filesystem__edit_file",
    "mcp__filesystem__move_file",
})


# --- Core Functions ---------------------------------------------------------
def create_response(
    decision: str, reason: str | None = None, modifications: dict[str, Any] | None = None
) -> dict[str, Any]:
    """Create a hook response.

    Args:
        decision: The decision type (approve, block, modify)
        reason: Optional reason for the decision
        modifications: Optional modifications for modify decision

    Returns:
        Hook response dictionary
    """
    response: dict[str, Any] = {"decision": decision, "intervention_required": False}
    if reason:
        response["reason"] = reason
    if modifications:
        response["modifications"] = modifications
    return response


def get_validation_errors(session: str) -> str | None:
    """Get validation errors from database."""
    db = Path.home() / ".claude" / "data" / "memory.db"
    if not (db.exists() and session):
        return None
    try:
        with sqlite3.connect(db) as conn:
            query = ("SELECT json_extract(params,'$.errors') FROM commands WHERE "
                     "cmd='validation_error' AND json_extract(params,'$.session_id')=? "
                     "ORDER BY id DESC LIMIT 1")
            cur = conn.execute(query, (session,))
            return row[0] if (row := cur.fetchone()) else None
    except (sqlite3.Error, TypeError):
        return None


def main() -> int:
    """Main entry point for the tool control hook."""
    tool = os.environ.get("CLAUDE_TOOL_NAME", "")
    input_data = os.environ.get("CLAUDE_TOOL_INPUT", "{}")
    session = os.environ.get("SESSION", os.environ.get("CLAUDE_SESSION_ID", ""))

    # File editing tools that need validation checks
    file_tools = {"Write", "Edit", "MultiEdit", "NotebookEdit",
                  "mcp__filesystem__write_file", "mcp__filesystem__edit_file",
                  "mcp__filesystem__create_directory", "mcp__filesystem__move_file"}

    # Check validation blocking for file operations
    if tool in file_tools and (errors := get_validation_errors(session)):
        match tool:
            case "Edit" | "MultiEdit" | "mcp__filesystem__edit_file":
                # Allow fixing the file with errors
                try:
                    if (fp := json.loads(input_data).get("file_path", "")) and fp in errors:
                        response = create_response("approve")
                        print(json.dumps(response))  # noqa: T201
                        return 0
                except json.JSONDecodeError:
                    pass
            case _:
                pass  # Will block below
        # Block file operations when validation errors exist
        response = create_response("block", f"Fix validation errors first:\n{errors}")
        print(json.dumps(response), file=sys.stderr)  # noqa: T201
        return 2

    # Main tool decision logic
    match tool:
        case t if t in BLOCKED:
            response = create_response("block", f"Use alternatives to {tool}")
            exit_code = 2
        case t if t in SUBSTITUTIONS:
            response = create_response("modify", f"Using {SUBSTITUTIONS[tool]} instead",
                {"tool": SUBSTITUTIONS[tool], "input": input_data})
            exit_code = 0
        case _:
            response = create_response("approve")
            exit_code = 0

    print(json.dumps(response))  # noqa: T201
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
