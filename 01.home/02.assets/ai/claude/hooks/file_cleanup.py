#!/usr/bin/env python3
"""
Title         : file_cleanup.py
Author        : Bardia Samiee
Project       : Parametric Forge
License       : MIT
Path          : /01.home/02.assets/ai/claude/hooks/file_cleanup.py

Description
----------------------------------------------------------------------------
Minimal post-tool file cleanup hook - strips trailing whitespace.

This hook automatically cleans up files after Claude edits them, removing
trailing whitespace and ensuring consistent line endings. It runs after
file modification tools and only processes supported file extensions.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any, Final

# --- Configuration ----------------------------------------------------------
FILE_TOOLS: Final[frozenset[str]] = frozenset({
    "Edit",
    "MultiEdit",
    "Write",
    "mcp__filesystem__edit_file",
    "mcp__filesystem__write_file",
})

CLEANUP_EXTENSIONS: Final[frozenset[str]] = frozenset({
    ".py",
    ".sh",
    ".nix",
    ".js",
    ".ts",
    ".rs",
    ".md",
    ".json",
    ".yaml",
    ".yml",
    ".toml",
})

# --- Core Functions ---------------------------------------------------------
def extract_file_paths(tool_name: str, tool_input: str) -> list[Path]:
    """Extract file paths from tool input.

    Args:
        tool_name: Name of the Claude tool being used
        tool_input: JSON string containing tool input parameters

    Returns:
        List of Path objects extracted from the tool input
    """
    paths: list[Path] = []

    try:
        data: dict[str, Any] = json.loads(tool_input)
    except (json.JSONDecodeError, TypeError):
        return paths

    # Extract file path from known field names
    for field in ("file_path", "path"):
        if field in data:
            value: Any = data[field]
            if isinstance(value, str):
                paths.append(Path(value))
                break

    return paths


def strip_trailing_whitespace(file_path: Path) -> bool:
    """Strip trailing whitespace from file.

    Args:
        file_path: Path to the file to clean

    Returns:
        True if file was modified, False otherwise
    """
    if not file_path.exists() or not file_path.is_file():
        return False

    if file_path.suffix not in CLEANUP_EXTENSIONS:
        return False

    try:
        original_content: str = file_path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return False

    # Split into lines, preserving line endings
    lines: list[str] = original_content.splitlines(keepends=True)

    # Strip trailing whitespace from each line, preserving original line endings
    cleaned_lines: list[str] = []
    for line in lines:
        if line.endswith("\r\n"):
            cleaned_lines.append(line.rstrip() + "\r\n")
        elif line.endswith("\n"):
            cleaned_lines.append(line.rstrip() + "\n")
        else:
            cleaned_lines.append(line.rstrip())

    # Remove trailing empty lines but preserve at least one if file had content
    original_had_content = bool(cleaned_lines)
    original_line_ending = "\r\n" if original_content.find("\r\n") != -1 else "\n"

    while cleaned_lines and not cleaned_lines[-1].strip():
        cleaned_lines.pop()

    # Ensure file ends properly - add single newline if file had content
    if original_had_content and cleaned_lines:
        if not cleaned_lines[-1].endswith(("\n", "\r\n")):
            cleaned_lines[-1] += original_line_ending
    elif original_had_content and not cleaned_lines:
        # File had content but was all whitespace - keep single newline with original style
        cleaned_lines = [original_line_ending]

    cleaned_content: str = "".join(cleaned_lines)

    # Only write if content changed
    if original_content != cleaned_content:
        try:
            file_path.write_text(cleaned_content, encoding="utf-8")
            return True
        except OSError:
            return False

    return False


def main() -> int:
    """Main entry point for the cleanup hook.

    Returns:
        Exit code (0 for success)
    """
    tool_name: str = os.environ.get("CLAUDE_TOOL_NAME", "")
    tool_input: str = os.environ.get("CLAUDE_TOOL_INPUT", "{}")

    # Extract and clean files
    cleaned_count: int = 0
    file_paths: list[Path] = extract_file_paths(tool_name, tool_input)
    
    # If no file paths from tool input, check if we have a direct file argument
    if not file_paths and len(sys.argv) > 1:
        # Direct invocation with file path - clean the specified file
        file_paths = [Path(sys.argv[1])]
    
    # If still no paths and we're not in hook mode, skip processing
    if not file_paths and tool_name not in FILE_TOOLS:
        return 0

    for file_path in file_paths:
        if strip_trailing_whitespace(file_path):
            cleaned_count += 1
            # Log to stderr for memory.sh to capture
            print(f"✨ Cleaned: {file_path}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
