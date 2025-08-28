#!/usr/bin/env python3
"""
Title         : file_cleanup.py
Author        : Bardia Samiee
Project       : Parametric Forge
License       : MIT
Path          : /01.home/00.core/configs/apps/claude/hooks/file_cleanup.py

Description
----------------------------------------------------------------------------
Smart file formatter hook - applies appropriate formatters to modified files.

This hook automatically formats files after Claude edits them, using the
appropriate formatter for each file type (ruff, prettier, etc.).
It leverages Claude's CLAUDE_FILE_PATHS environment variable and returns
structured JSON responses for better control flow.
"""

from __future__ import annotations

import functools
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Final, Protocol, TypedDict


# --- Configuration ----------------------------------------------------------
FILE_TOOLS: Final[frozenset[str]] = frozenset({
    "Edit",
    "MultiEdit",
    "Write",
    "NotebookEdit",
    "mcp__filesystem__edit_file",
    "mcp__filesystem__write_file",
    "mcp__filesystem__create_directory",
})

FORMATTERS: Final[dict[str, list[str]]] = {
    ".py": ["ruff", "format", "--quiet"],
    ".rs": ["rustfmt", "--edition", "2021", "--quiet"],
    ".nix": ["nixfmt"],
    ".sh": ["shfmt", "-w", "-i", "2"],
    ".json": ["jq", ".", "-M", "--tab"],
    ".toml": ["taplo", "format", "--option", "indent_string=  "],
}

PRETTIER_CONFIG: Final[dict[str, dict[str, str]]] = {
    ".js": {"parser": "babel"},
    ".jsx": {"parser": "babel"},
    ".mjs": {"parser": "babel"},
    ".cjs": {"parser": "babel"},
    ".json": {"parser": "json"},
    ".json5": {"parser": "json5"},
    ".css": {"parser": "css"},
    ".scss": {"parser": "scss"},
    ".less": {"parser": "less"},
    ".html": {"parser": "html"},
    ".md": {"parser": "markdown"},
    ".mdx": {"parser": "mdx"},
    ".yaml": {"parser": "yaml"},
    ".yml": {"parser": "yaml"},
    ".ts": {},
    ".tsx": {},
}

PRETTIER_EXTENSIONS: Final[frozenset[str]] = frozenset(PRETTIER_CONFIG.keys())
NULL_BYTE: Final[bytes] = b"\0"


class Result(TypedDict):
    """Result of file formatting operation."""

    file: str
    success: bool
    message: str


class Formatter(Protocol):
    """Protocol for file formatter functions."""

    def __call__(self, file_path: Path) -> tuple[bool, str]:
        """Format a file and return success status and message."""
        ...


# --- Core Functions ---------------------------------------------------------
def get_file_paths_from_env() -> list[Path]:
    """Get file paths from Claude's environment variable."""
    return [Path(p.strip()) for p in os.environ.get("CLAUDE_FILE_PATHS", "").split() if p.strip()]


def extract_file_paths(tool_input: str) -> list[Path]:
    """Extract file paths from tool input JSON."""
    try:
        if data := json.loads(tool_input):
            for field in ("file_path", "path", "notebook_path"):
                if field in data and isinstance(data[field], str):
                    return [Path(data[field])]
    except (json.JSONDecodeError, TypeError):
        pass
    return []


@functools.cache
def check_command_exists(command: str) -> bool:
    """Check if a command exists in the system PATH."""
    return shutil.which(command) is not None


def run_formatter(cmd: list[str], file_path: Path, *, use_stdin: bool = False) -> tuple[bool, str]:
    """Run formatter command and handle errors."""
    try:
        if use_stdin:
            content = file_path.read_text(encoding="utf-8")
            if (
                result := subprocess.run(cmd, check=False, input=content, capture_output=True, text=True, timeout=10)
            ).returncode == 0:
                if result.stdout != content:
                    file_path.write_text(result.stdout, encoding="utf-8")
                    return True, f"Formatted with {cmd[0]}: {file_path.name}"
                return True, f"Already formatted: {file_path.name}"
            return False, f"{cmd[0]} failed: {result.stderr[:100]}"
        if (
            result := subprocess.run([*cmd, str(file_path)], check=False, capture_output=True, text=True, timeout=10)
        ).returncode == 0:
            return True, f"Formatted with {cmd[0]}: {file_path.name}"
        return False, f"{cmd[0]} failed: {result.stderr[:100]}"
    except (subprocess.TimeoutExpired, OSError) as e:
        return False, f"{cmd[0]} error: {str(e)[:100]}"


def format_with_prettier(file_path: Path) -> tuple[bool, str]:
    """Format file with Prettier using appropriate parser."""
    if not check_command_exists("prettier"):
        return False, "prettier not found"

    suffix = file_path.suffix.lower()
    config = PRETTIER_CONFIG.get(suffix, {})
    cmd = ["prettier", "--write"]

    if "parser" in config:
        cmd.extend(["--parser", config["parser"]])

    return run_formatter(cmd, file_path)


def strip_trailing_whitespace(file_path: Path) -> bool:
    """Strip trailing whitespace from text files."""
    try:
        if (content := file_path.read_bytes()) and NULL_BYTE not in content[:8192]:
            text = content.decode("utf-8")
            if (cleaned := "\n".join(line.rstrip() for line in text.splitlines())) and not cleaned.endswith("\n"):
                cleaned += "\n"
            if text != cleaned:
                file_path.write_text(cleaned, encoding="utf-8")
                return True
    except (UnicodeDecodeError, OSError):
        pass
    return False


def format_file(file_path: Path) -> tuple[bool, str]:
    """Format a file using the appropriate formatter."""
    if not file_path.exists() or not file_path.is_file():
        return False, f"File not found: {file_path}"

    suffix = file_path.suffix.lower()
    formatted, message = False, ""

    match suffix:
        case ext if ext in PRETTIER_EXTENSIONS:
            formatted, message = format_with_prettier(file_path)
        case ext if ext in FORMATTERS:
            formatter_cmd = FORMATTERS[ext]
            if not check_command_exists(formatter_cmd[0]):
                message = f"{formatter_cmd[0]} not found"
            else:
                use_stdin = formatter_cmd[0] == "jq"
                formatted, message = run_formatter(formatter_cmd, file_path, use_stdin=use_stdin)
        case _:
            pass

    if strip_trailing_whitespace(file_path):
        if formatted:
            message = f"{message} + whitespace stripped"
        else:
            formatted, message = True, f"Whitespace stripped: {file_path.name}"
    elif not formatted:
        message = f"No changes needed for {file_path.name}"

    return formatted, message


def main() -> int:
    """Main entry point for the PostToolUse hook."""
    tool_name = os.environ.get("CLAUDE_TOOL_NAME", "")
    tool_input = os.environ.get("CLAUDE_TOOL_INPUT", "{}")
    
    # Log to file for debugging (optional)
    debug_mode = os.environ.get("CLAUDE_HOOK_DEBUG", "").lower() == "true"
    if debug_mode:
        with open("/tmp/claude_file_cleanup.log", "a") as f:
            f.write(f"Tool: {tool_name}\n")

    if tool_name not in FILE_TOOLS:
        return 0

    file_paths = (
        get_file_paths_from_env()
        or extract_file_paths(tool_input)
        or ([Path(sys.argv[1])] if len(sys.argv) > 1 else [])
    )

    if not file_paths:
        return 0

    results: list[Result] = []
    for file_path in file_paths:
        success, message = format_file(file_path)
        results.append({"file": str(file_path), "success": success, "message": message})

    success_count = sum(1 for r in results if r["success"])

    if success_count > 0 or any(r["message"] != f"No formatter for {Path(r['file']).suffix} files" for r in results):
        context = (
            f"✨ Formatted {success_count}/{len(file_paths)} files"
            if success_count > 0
            else f"⚠️ Formatting issues: {next(r['message'] for r in results if not r['success'])}"
        )

        response = {
            "hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": context, "results": results}
        }
        print(json.dumps(response))

    return 0


if __name__ == "__main__":
    sys.exit(main())
