#!/usr/bin/env python3
"""
Title         : screenshot.py
Author        : Bardia Samiee
Project       : Parametric Forge
License       : MIT
Path          : /01.home/00.core/configs/apps/claude/tools/screenshot.py

Description
----------------------------------------------------------------------------
Simple, focused screenshot tool for Claude Code visual analysis.

Features:
- XDG-compliant storage in cache directory
- Automatic Claude context injection
- Clean, single-purpose implementation
"""
# ruff: noqa: T201

import argparse
import datetime
import os
from pathlib import Path

from PIL import ImageGrab


def get_screenshot_dir() -> Path:
    """Get XDG-compliant screenshot directory."""
    xdg_cache = os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))
    screenshot_dir = Path(xdg_cache) / "claude" / "screenshots"
    screenshot_dir.mkdir(parents=True, exist_ok=True)
    return screenshot_dir


def take_screenshot(context: str = "ui") -> Path:
    """Take screenshot and return path."""
    screenshot_dir = get_screenshot_dir()
    timestamp = datetime.datetime.now(datetime.UTC).strftime("%Y%m%d_%H%M%S")
    filepath = screenshot_dir / f"{context}_{timestamp}.png"

    screenshot = ImageGrab.grab()
    screenshot.save(filepath, "PNG", optimize=True)

    return filepath


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Screenshot tool for Claude Code")
    parser.add_argument("-c", "--context", default="manual", help="Screenshot context")
    parser.add_argument("--cleanup", type=int, metavar="N", help="Keep only N latest screenshots")

    args = parser.parse_args()

    if args.cleanup:
        screenshot_dir = get_screenshot_dir()
        screenshots = sorted(screenshot_dir.glob("*.png"), key=lambda p: p.stat().st_mtime, reverse=True)

        if len(screenshots) > args.cleanup:
            for screenshot in screenshots[args.cleanup:]:
                screenshot.unlink()
            print(f"Cleaned up {len(screenshots) - args.cleanup} old screenshots")
        return

    # Take screenshot
    filepath = take_screenshot(args.context)
    size_kb = filepath.stat().st_size // 1024

    print(f"Screenshot saved: {filepath}")
    print(f"Size: {size_kb}KB")


if __name__ == "__main__":
    main()
