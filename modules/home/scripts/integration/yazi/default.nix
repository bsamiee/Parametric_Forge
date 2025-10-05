# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/integration/yazi/default.nix
# ----------------------------------------------------------------------------
# Yazi integration scripts

{ config, lib, pkgs, ... }:

{
  # --- Detect active Yazi client id -----------------------------------------
  home.file.".local/bin/yazi-current-client.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : yazi-current-client.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : ~/.local/bin/yazi-current-client.sh
      # ----------------------------------------------------------------------------
      # Determine which Yazi client id is currently active (sidebar vs filemanager)

      set -euo pipefail

      if command -v pgrep >/dev/null 2>&1 && pgrep -f 'yazi --client-id sidebar' >/dev/null 2>&1; then
        echo "sidebar"
        exit 0
      fi

      if command -v pgrep >/dev/null 2>&1 && pgrep -f 'yazi --client-id filemanager' >/dev/null 2>&1; then
        echo "filemanager"
        exit 0
      fi

      # Fallback detection when pgrep is unavailable
      if ps aux | ${pkgs.gnugrep}/bin/grep -F "yazi --client-id sidebar" | ${pkgs.gnugrep}/bin/grep -v grep >/dev/null 2>&1; then
        echo "sidebar"
        exit 0
      fi

      if ps aux | ${pkgs.gnugrep}/bin/grep -F "yazi --client-id filemanager" | ${pkgs.gnugrep}/bin/grep -v grep >/dev/null 2>&1; then
        echo "filemanager"
        exit 0
      fi

      # Default to sidebar when no process matches; callers should handle fallback
      echo "sidebar"
      exit 0
    '';
  };

  # --- Open nvim with smart pane reuse and tab naming -----------------------
  home.file.".local/bin/yazi-open-nvim.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : yazi-open-nvim.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : ~/.local/bin/yazi-open-nvim.sh
      # ----------------------------------------------------------------------------
      # Open file in nvim with smart pane reuse and tab naming

      FILE="$1"
      WORKING_DIR=$(dirname "$FILE")

      # Detect which Yazi instance is active (defaults to sidebar when absent)
      YAZI_CLIENT=$(yazi-current-client.sh 2>/dev/null || true)
      [[ -z "$YAZI_CLIENT" ]] && YAZI_CLIENT="sidebar"

      # Try to find existing nvim pane using utility
      if zellij-find-nvim.sh; then
          # Found nvim - move to top of stack first
          zellij-move-pane-top.sh 3
          # Now send commands to open file
          ${pkgs.zellij}/bin/zellij action write 27  # ESC key
          ${pkgs.zellij}/bin/zellij action write-chars ":cd $WORKING_DIR"
          ${pkgs.zellij}/bin/zellij action write 13  # Enter key
          ${pkgs.zellij}/bin/zellij action write-chars ":e $FILE"
          ${pkgs.zellij}/bin/zellij action write 13  # Enter key

          # In full-screen mode (filemanager client), close Yazi after opening file
          if [[ "$YAZI_CLIENT" == "filemanager" ]]; then
              ${pkgs.zellij}/bin/zellij action focus-previous-pane
              ${pkgs.zellij}/bin/zellij action close-pane
          fi
      else
          # Create new nvim pane with smart tab naming
          if ${pkgs.git}/bin/git rev-parse --show-toplevel &>/dev/null; then
              TAB_NAME=$(basename "$(${pkgs.git}/bin/git rev-parse --show-toplevel)")
          else
              TAB_NAME=$(basename "$PWD")
          fi
          ${pkgs.zellij}/bin/zellij action new-pane --direction right --name "editor" -- ${pkgs.neovim}/bin/nvim "$FILE"
          ${pkgs.zellij}/bin/zellij action rename-tab "$TAB_NAME"
      fi
    '';
  };

  # --- Focus nvim pane in Zellij --------------------------------------------
  home.file.".local/bin/yazi-focus-nvim.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : yazi-focus-nvim.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : ~/.local/bin/yazi-focus-nvim.sh
      # ----------------------------------------------------------------------------
      # Focus nvim pane via Zellij

      # Only operate when the sidebar client is active
      YAZI_CLIENT=$(yazi-current-client.sh 2>/dev/null || true)
      if [[ "$YAZI_CLIENT" != "sidebar" ]]; then
          echo "Focus nvim only works when the sidebar layout is active" >&2
          exit 1
      fi

      # Find and focus nvim, then move to top
      if zellij-find-nvim.sh; then
          zellij-move-pane-top.sh 3
      else
          echo "No nvim pane found" >&2
          exit 1
      fi
    '';
  };

  # --- Open directory in new Zellij pane ------------------------------------
  home.file.".local/bin/yazi-open-dir.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : yazi-open-dir.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : ~/.local/bin/yazi-open-dir.sh
      # ----------------------------------------------------------------------------
      # Open directory in new Zellij pane

      ${pkgs.zellij}/bin/zellij action new-pane --direction right -- zsh -c "cd '$1' && exec zsh"
    '';
  };

  # --- Reveal file in Yazi sidebar ------------------------------------------
  home.file.".local/bin/yazi-reveal.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : yazi-reveal.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : ~/.local/bin/yazi-reveal.sh
      # ----------------------------------------------------------------------------
      # Reveal file in Yazi sidebar using ya IPC

      FILE="$1"

      # Determine target client dynamically (sidebar preferred, fallback to filemanager)
      CLIENT_ID=$(yazi-current-client.sh 2>/dev/null || true)
      [[ -z "$CLIENT_ID" ]] && CLIENT_ID="sidebar"

      # Use ya pub-to to send reveal command to Yazi instance
      if command -v ya &>/dev/null; then
          ya pub-to "$CLIENT_ID" reveal --str "$FILE"
          ${pkgs.zellij}/bin/zellij action focus-left
      else
          echo "ya command not found - cannot reveal file" >&2
          exit 1
      fi
    '';
  };

}
