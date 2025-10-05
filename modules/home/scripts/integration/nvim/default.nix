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

      # Detect target client dynamically
      CLIENT_ID=$(yazi-current-client.sh 2>/dev/null || true)
      [[ -z "$CLIENT_ID" ]] && CLIENT_ID="sidebar"

      BUFFER="''${1:-$PWD}"

      # Store current pane to return to later
      CURRENT_PANE=$(${pkgs.zellij}/bin/zellij action list-clients 2>/dev/null | head -1 | awk '{print $1}' || echo "")

      # Find Yazi pane (check for sidebar or filemanager)
      for i in {1..4}; do
        # Get pane info - check if it's running yazi or named appropriately
        PANE_CMD=$(zellij-get-command.sh)
        PANE_NAME=$(${pkgs.zellij}/bin/zellij action query-tab-names 2>/dev/null | ${pkgs.gnugrep}/bin/grep -o '"name":"[^"]*"' | ${pkgs.gnused}/bin/sed 's/"name":"//;s/"//' || echo "")

        if [[ "$PANE_CMD" == *"yazi"* ]] || [[ "$PANE_NAME" == "sidebar" ]] || [[ "$PANE_NAME" == "filemanager" ]]; then
          # Found Yazi pane - use ya pub-to to reveal file
          if command -v ya &>/dev/null; then
            ya pub-to "$CLIENT_ID" reveal --str "$BUFFER"
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

  # --- Use Yazi as file picker for Nvim -------------------------------------
  home.file.".local/bin/nvim-yazi-picker.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : nvim-yazi-picker.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : ~/.local/bin/nvim-yazi-picker.sh
      # ----------------------------------------------------------------------------
      # Use Yazi as a file picker and open selected file in nvim

      # Create temporary file for Yazi output
      tmp="$(mktemp -t yazi-picker.XXXXXX)"

      # Launch Yazi in a floating pane with chooser-file option
      ${pkgs.zellij}/bin/zellij action new-pane --floating -- ${pkgs.yazi}/bin/yazi --chooser-file="$tmp"

      # Wait for Yazi to exit and check if a file was selected
      if [[ -s "$tmp" ]]; then
        selected=$(cat "$tmp")
        if [[ -n "$selected" && -f "$selected" ]]; then
          # Open the selected file in nvim
          ${pkgs.neovim}/bin/nvim "$selected"
        else
          echo "Selected path is not a valid file: $selected" >&2
        fi
      else
        echo "No file selected" >&2
      fi

      # Clean up temporary file
      rm -f "$tmp"
    '';
  };
}
