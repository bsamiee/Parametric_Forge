#!/usr/bin/env bash
# forge-edit.sh — Yazi → Zellij → Neovim handoff

set -euo pipefail

SOCKET="/tmp/nvim-${ZELLIJ_SESSION_NAME:-default}.sock"

# Focus the editor pane before sending files
zellij action focus-next-pane

if nvr --servername "$SOCKET" --remote-expr "1" >/dev/null 2>&1; then
  nvr --servername "$SOCKET" --remote-silent "$@"
else
  zellij action write-chars "nvim --listen $SOCKET $*"
  zellij action write 13
fi
