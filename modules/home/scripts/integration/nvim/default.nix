# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/integration/nvim/default.nix
# ----------------------------------------------------------------------------
# Nvim integration scripts

{ config, lib, pkgs, ... }:

{
  # --- Reveal current nvim buffer in Yazi -----------------------------------
  home.file.".local/bin/nvim-reveal-in-yazi.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : nvim-reveal-in-yazi.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : ~/.local/bin/nvim-reveal-in-yazi.sh
      # ----------------------------------------------------------------------------
      # Called from nvim to reveal current buffer in Yazi

      # Check if sidebar mode is enabled
      SIDEBAR_ENABLED="''${YAZI_ENABLE_SIDEBAR:-true}"
      if [[ "$SIDEBAR_ENABLED" != "true" ]]; then
          echo "Reveal in Yazi only works in sidebar mode" >&2
          exit 1
      fi

      BUFFER="''${1:-$PWD}"

      # Store current pane to return to later
      CURRENT_PANE=$(${pkgs.zellij}/bin/zellij action list-clients 2>/dev/null | head -1 | awk '{print $1}' || echo "")

      # Find Yazi pane (check for sidebar or filemanager)
      for i in {1..4}; do
        # Get pane info - check if it's running yazi or named appropriately
        PANE_CMD=$(zellij-get-command.sh)
        PANE_NAME=$(${pkgs.zellij}/bin/zellij action query-tab-names 2>/dev/null | ${pkgs.gnugrep}/bin/grep -o '"name":"[^"]*"' | ${pkgs.gnused}/bin/sed 's/"name":"//;s/"//' || echo "")

        if [[ "$PANE_CMD" == *"yazi"* ]] || [[ "$PANE_NAME" == "sidebar" ]] || [[ "$PANE_NAME" == "filemanager" ]]; then
          # Found Yazi pane - use ya emit-to to reveal file (ya is separate from yazi package)
          if command -v ya &>/dev/null; then
            ya emit-to "''${YAZI_ID:-main}" reveal "$BUFFER"
          else
            echo "ya command not found - cannot reveal file" >&2
          fi
          break
        fi

        # Move to next pane
        ${pkgs.zellij}/bin/zellij action focus-next-pane
      done
    '';
  };
}
