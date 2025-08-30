#!/usr/bin/env python3
# ruff: noqa: T201, S110, BLE001, PLR0912, EXE001
"""
Title         : unified_logger.py
Author        : Bardia Samiee
Project       : Parametric Forge
License       : MIT
Path          : /01.home/00.core/configs/apps/claude/hooks/unified_logger.py

Description
----------------------------------------------------------------------------
Unified logging hook for all Claude Code hook events.

Consolidates logging patterns from claude-code-hooks-mastery repository
into a single file. Handles all hook events (SessionStart, UserPromptSubmit,
PreToolUse, PostToolUse, PreCompact, Stop, SubagentStop) with simple JSON
logging and optional security checks.

Usage: Called by Claude Code for any hook event via CLAUDE_HOOK_EVENT env var.
"""

import contextlib
import functools
import json
import os
import re
import sys
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Any, Protocol, TypedDict


# --- Type Definitions -------------------------------------------------------
class ToolInput(TypedDict, total=False):
    """Type definition for tool input data."""
    command: str
    file_path: str


class LogEntry(TypedDict):
    """Type definition for log entry data."""
    event: str
    timestamp: str | None


@dataclass(frozen=True, slots=True)
class SecurityResult:
    """Result of security checks."""
    blocked: bool
    reason: str = ""


class HookEvent(Enum):
    """Enumeration of supported hook events."""
    SESSION_START = "sessionstart"
    USER_PROMPT_SUBMIT = "userpromptsubmit"
    PRE_TOOL_USE = "pretooluse"
    POST_TOOL_USE = "posttooluse"
    PRE_COMPACT = "precompact"
    STOP = "stop"
    SUBAGENT_STOP = "subagentstop"
    UNKNOWN = "unknown"


# --- Configuration ----------------------------------------------------------
LOG_DIR = Path(os.environ.get("XDG_CACHE_HOME", "~/.cache")).expanduser() / "claude" / "logs"


@functools.cache
def _compile_security_patterns() -> tuple[tuple[re.Pattern[str], ...], tuple[re.Pattern[str], ...]]:
    """Compile security patterns once for performance."""
    dangerous = [
        r"rm\s+-rf?\s+/",
        r"rm\s+-rf?\s+\*",
        r"rm\s+-rf?\s+~",
        r">\s*/dev/sd[a-z]\d*",
        r"dd\s+.*of=/dev/",
    ]
    blocked_files = [
        r"\.env$",
        r"\.env\.local$",
        r"\.env\.production$",
    ]
    return (
        tuple(re.compile(pattern, re.IGNORECASE) for pattern in dangerous),
        tuple(re.compile(pattern, re.IGNORECASE) for pattern in blocked_files)
    )


# --- Core Functions ---------------------------------------------------------
@contextlib.contextmanager
def _safe_json_file(file_path: Path, mode: str = "r"):
    """Safe JSON file operations with error handling.

    Yields:
        File handle or None if operation fails.
    """
    try:
        with file_path.open(mode, encoding="utf-8") as f:
            yield f
    except OSError:
        yield None


@functools.lru_cache(maxsize=128)
def _load_existing_logs(file_path: Path) -> list[dict[str, Any]]:
    """Load existing logs with caching."""
    if not file_path.exists():
        return []

    with _safe_json_file(file_path) as f:
        if f is None:
            return []
        if content := f.read().strip():
            try:
                logs: list[dict[str, Any]] | dict[str, Any] = json.loads(content)
                return logs if isinstance(logs, list) else [logs]
            except json.JSONDecodeError:
                pass
    return []


def log_event(event_name: str, data: dict[str, Any]) -> None:
    """Log event data to JSON file."""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_file = LOG_DIR / f"{event_name.lower()}.json"

    # Clear cache for this file to get fresh data
    _load_existing_logs.cache_clear() if log_file.exists() else None
    existing_logs = _load_existing_logs(log_file)
    existing_logs.append(data)

    with _safe_json_file(log_file, "w") as f:
        if f is not None:
            json.dump(existing_logs, f, indent=2, ensure_ascii=False)


def read_stdin_json() -> dict[str, Any] | None:
    """Read and parse JSON from stdin."""
    try:
        return json.loads(data) if (data := sys.stdin.read().strip()) else None
    except (json.JSONDecodeError, OSError):
        return None


# --- Security System --------------------------------------------------------
def _check_patterns(text: str, patterns: tuple[re.Pattern[str], ...]) -> bool:
    """Check if text matches any security patterns."""
    return any(pattern.search(text) for pattern in patterns)


def check_security(tool_input: ToolInput) -> SecurityResult:
    """Unified security check for tool input."""
    dangerous_patterns, blocked_file_patterns = _compile_security_patterns()

    # Check dangerous commands
    if command := tool_input.get("command"):
        if _check_patterns(command, dangerous_patterns):
            return SecurityResult(blocked=True, reason="Dangerous command detected")
        if _check_patterns(command, blocked_file_patterns) and ".sample" not in command:
            return SecurityResult(blocked=True, reason="Blocked file access in command")

    # Check file path access
    if (
        (file_path := tool_input.get("file_path"))
        and not file_path.endswith(".sample")
        and _check_patterns(file_path, blocked_file_patterns)
    ):
        return SecurityResult(blocked=True, reason="Blocked file access detected")

    return SecurityResult(blocked=False)


# --- Event Handlers ---------------------------------------------------------
class HookHandler(Protocol):
    """Protocol for hook event handlers."""
    def __call__(self, data: dict[str, Any]) -> bool | None:
        """Call the hook handler with data."""
        ...


def _create_log_entry(event_type: str, data: dict[str, Any], extra: dict[str, Any] | None = None) -> dict[str, Any]:
    """Create standardized log entry."""
    entry = {"event": event_type, "timestamp": data.get("timestamp")}
    if extra:
        entry.update(extra)
    return entry


def handle_session_start(data: dict[str, Any]) -> None:
    """Handle SessionStart hook event."""
    log_event("session_start", _create_log_entry("SessionStart", data, {
        "user_id": data.get("user_id"),
        "session_id": data.get("session_id"),
        "project_path": data.get("project_path"),
    }))


def handle_user_prompt_submit(data: dict[str, Any]) -> None:
    """Handle UserPromptSubmit hook event."""
    prompt = data.get("prompt", "")
    log_event("user_prompt_submit", _create_log_entry("UserPromptSubmit", data, {
        "prompt_length": len(prompt),
        "prompt_preview": prompt[:100] + "..." if len(prompt) > 100 else prompt,
        "has_attachments": bool(data.get("attachments")),
    }))


def handle_pre_tool_use(data: dict[str, Any]) -> bool:
    """Handle PreToolUse hook event. Returns True if should block."""
    tool_input = data.get("tool_input", {})
    security_result = check_security(tool_input)

    log_event("pre_tool_use", _create_log_entry("PreToolUse", data, {
        "tool_name": data.get("tool_name", ""),
        "tool_input": tool_input,
        "blocked": security_result.blocked,
        "block_reason": security_result.reason,
    }))

    return security_result.blocked


def handle_post_tool_use(data: dict[str, Any]) -> None:
    """Handle PostToolUse hook event."""
    log_event("post_tool_use", _create_log_entry("PostToolUse", data, {
        "tool_name": data.get("tool_name", ""),
        "tool_input": data.get("tool_input", {}),
        "tool_output": data.get("tool_output", "")[:500] or "",
        "success": data.get("success", True),
    }))


def handle_pre_compact(data: dict[str, Any]) -> None:
    """Handle PreCompact hook event."""
    log_event("pre_compact", _create_log_entry("PreCompact", data, {
        "token_count": data.get("token_count"),
        "message_count": data.get("message_count"),
    }))


def handle_stop(data: dict[str, Any]) -> None:
    """Handle Stop hook event."""
    log_event("stop", _create_log_entry("Stop", data, {
        "reason": data.get("reason", ""),
        "session_duration": data.get("session_duration"),
    }))


def handle_subagent_stop(data: dict[str, Any]) -> None:
    """Handle SubagentStop hook event."""
    log_event("subagent_stop", _create_log_entry("SubagentStop", data, {
        "subagent_name": data.get("subagent_name", ""),
        "reason": data.get("reason", ""),
    }))


# --- Event Processing -------------------------------------------------------
def _infer_event_type(data: dict[str, Any]) -> HookEvent:
    """Infer event type from data structure."""
    if "tool_name" in data:
        return HookEvent.POST_TOOL_USE if "tool_output" in data else HookEvent.PRE_TOOL_USE
    if "prompt" in data:
        return HookEvent.USER_PROMPT_SUBMIT
    return HookEvent.UNKNOWN


def _enrich_data(data: dict[str, Any]) -> dict[str, Any]:
    """Enrich data with environment context using walrus operator."""
    data.update({
        "timestamp": data.get("timestamp") or os.environ.get("CLAUDE_TIMESTAMP"),
        "session_id": data.get("session_id") or os.environ.get("CLAUDE_SESSION_ID"),
        "project_path": data.get("project_path") or os.environ.get("CLAUDE_PROJECT_DIR"),
        "tool_name": data.get("tool_name") or os.environ.get("CLAUDE_TOOL_NAME"),
        "tool_input": data.get("tool_input") or os.environ.get("CLAUDE_TOOL_INPUT", "{}"),
    })

    # Parse tool_input if string
    if isinstance(tool_input := data.get("tool_input"), str):
        try:
            data["tool_input"] = json.loads(tool_input)
        except json.JSONDecodeError:
            data["tool_input"] = {}

    return data


def _create_block_response() -> dict[str, Any]:
    """Create standardized block response."""
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": "Tool use blocked by security check",
            "blocked": True,
        }
    }


# --- Main Entry Point -------------------------------------------------------
def main() -> int:
    """Main entry point for unified logging hook."""
    # Get event type and data
    if hook_event_str := os.environ.get("CLAUDE_HOOK_EVENT", "").lower():
        event_type = HookEvent(hook_event_str) if hook_event_str in [e.value for e in HookEvent] else HookEvent.UNKNOWN
        data = read_stdin_json() or {}
    elif data := read_stdin_json():
        event_type = _infer_event_type(data)
    else:
        return 0

    # Enrich with environment context
    data = _enrich_data(data)

    # Process event using match/case
    try:
        match event_type:
            case HookEvent.SESSION_START:
                handle_session_start(data)
            case HookEvent.USER_PROMPT_SUBMIT:
                handle_user_prompt_submit(data)
            case HookEvent.PRE_TOOL_USE:
                if handle_pre_tool_use(data):
                    print(json.dumps(_create_block_response()))
                    return 2  # Exit code 2 blocks tool execution
            case HookEvent.POST_TOOL_USE:
                handle_post_tool_use(data)
            case HookEvent.PRE_COMPACT:
                handle_pre_compact(data)
            case HookEvent.STOP:
                handle_stop(data)
            case HookEvent.SUBAGENT_STOP:
                handle_subagent_stop(data)
            case HookEvent.UNKNOWN:
                log_event("unknown", {"event": event_type.value, "data": data})
    except Exception:
        pass  # Silent fail - don't break hook execution

    return 0


if __name__ == "__main__":
    sys.exit(main())
