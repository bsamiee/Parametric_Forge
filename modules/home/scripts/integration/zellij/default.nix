# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/integration/zellij/default.nix
# ----------------------------------------------------------------------------
# Zellij integration utility scripts

{ config, lib, pkgs, ... }:

{
  # --- Toggle sidebar mode --------------------------------------------------
  home.file.".local/bin/zellij-toggle-sidebar.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : zellij-toggle-sidebar.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : ~/.local/bin/zellij-toggle-sidebar.sh
      # ----------------------------------------------------------------------------
      # Toggle between sidebar and no-sidebar layouts, emit events to Yazi clients

      set -euo pipefail

      CURRENT_MODE="sidebar"
      if LAYOUT_OUTPUT="$(${pkgs.zellij}/bin/zellij action dump-layout 2>/dev/null)"; then
        if printf "%s" "$LAYOUT_OUTPUT" | ${pkgs.ripgrep}/bin/rg -q "pane name=\"sidebar\""; then
          CURRENT_MODE="sidebar"
        elif printf "%s" "$LAYOUT_OUTPUT" | ${pkgs.ripgrep}/bin/rg -q "pane name=\"filemanager\""; then
          CURRENT_MODE="filemanager"
        fi
      fi

      case "$CURRENT_MODE" in
        sidebar)
          NEXT_MODE="filemanager"
          ${pkgs.zellij}/bin/zellij action switch-layout "no_side"
          ;;
        filemanager)
          NEXT_MODE="sidebar"
          ${pkgs.zellij}/bin/zellij action switch-layout "side"
          ;;
        *)
          NEXT_MODE="sidebar"
          ${pkgs.zellij}/bin/zellij action switch-layout "side"
          ;;
      esac

      if [[ -x "${pkgs.yazi}/bin/ya" ]]; then
        ${pkgs.yazi}/bin/ya pub layout --str "$NEXT_MODE" >/dev/null 2>&1 || true
        ${pkgs.yazi}/bin/ya pub-to sidebar layout --str "$NEXT_MODE" >/dev/null 2>&1 || true
        ${pkgs.yazi}/bin/ya pub-to filemanager layout --str "$NEXT_MODE" >/dev/null 2>&1 || true
      fi

      echo "Sidebar mode: $NEXT_MODE"
    '';
  };
}