#!/usr/bin/env sh
# Title         : run-yabai.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/yabai/run-yabai.sh
# ----------------------------------------------------------------------------
# Purpose: Robust wrapper to invoke yabai from LaunchAgents (skhd, etc.)
# - Ensures a sane PATH for Homebrew/Nix installs
# - Resolves absolute yabai binary without guessing, using command -v and fallbacks
# - Passes all arguments through to yabai

set -eu

# --- path setup -------------------------------------------------------------
# Build a conservative PATH that covers Homebrew (arm/intel), Nix, and system
PATH="/opt/homebrew/bin:/usr/local/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
export PATH

# --- binary resolution ------------------------------------------------------
find_bin() {
  name="$1"
  # Prefer command -v when available from PATH
  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
    return 0
  fi
  # Fallback common locations (Apple Silicon, Intel Homebrew, Nix)
  for cand in \
    "/opt/homebrew/bin/$name" \
    "/usr/local/bin/$name" \
    "/run/current-system/sw/bin/$name"; do
    [ -x "$cand" ] && { echo "$cand"; return 0; }
  done
  # Last resort: just echo name (lets shell error clearly if not found)
  echo "$name"
}

# --- execution --------------------------------------------------------------
YABAI_BIN="$(find_bin yabai)"
exec "$YABAI_BIN" "$@"

