#!/usr/bin/env python3
"""
Title         : ui_prompt_helper.py
Author        : Bardia Samiee
Project       : Parametric Forge
License       : MIT
Path          : /01.home/00.core/configs/apps/claude/hooks/ui_prompt_helper.py

Description
----------------------------------------------------------------------------
Lightweight UI prompt detection for Claude Code UserPromptSubmit hook.

This hook detects UI/UX-related prompts and suggests taking a screenshot,
but keeps the actual screenshot capture as a separate manual command for
performance and user control.
"""
# ruff: noqa: T201, TRY300

import json
import sys


# Focused UI detection patterns
UI_KEYWORDS = [
    "ui", "interface", "design", "layout", "visual", "screenshot", "screen",
    "mockup", "wireframe", "accessibility", "responsive", "mobile"
]

UI_ACTIONS = [
    "analyze", "review", "improve", "fix", "create", "build", "implement"
]


def detect_ui_request(prompt: str) -> bool:
    """Simple, fast UI prompt detection."""
    prompt_lower = prompt.lower()

    # Direct UI keywords or Action + UI context
    return (
        any(keyword in prompt_lower for keyword in UI_KEYWORDS) or
        (any(action in prompt_lower for action in UI_ACTIONS) and
         any(keyword in prompt_lower for keyword in UI_KEYWORDS))
    )


def main() -> int:
    """Main entry point for UI prompt helper hook."""
    try:
        hook_data = json.loads(sys.stdin.read())
        prompt = hook_data.get("prompt", "")

        if detect_ui_request(prompt):
            suggestion = """💡 UI/UX Request Detected

Consider taking a screenshot for visual analysis:
• Type `/screenshot` for immediate capture and analysis
• Type `/screenshot accessibility` for accessibility-focused review
• Type `/screenshot responsive` for mobile/responsive analysis

This will capture your current screen and provide the visual context needed for comprehensive UI/UX guidance."""

            response = {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": suggestion
                }
            }
            print(json.dumps(response))

        return 0

    except (json.JSONDecodeError, KeyError):
        return 0


if __name__ == "__main__":
    sys.exit(main())
