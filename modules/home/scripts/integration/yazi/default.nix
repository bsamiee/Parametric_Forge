# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/integration/yazi/default.nix
# ----------------------------------------------------------------------------
# Yazi integration scripts

{ config, lib, pkgs, ... }:

{
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

      # Check sidebar mode for different behavior
      SIDEBAR_ENABLED="''${YAZI_ENABLE_SIDEBAR:-true}"

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

          # In no-sidebar mode, close Yazi after opening file
          if [[ "$SIDEBAR_ENABLED" != "true" ]]; then
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

      # Check if sidebar mode is enabled
      SIDEBAR_ENABLED="''${YAZI_ENABLE_SIDEBAR:-true}"
      if [[ "$SIDEBAR_ENABLED" != "true" ]]; then
          echo "Focus nvim only works in sidebar mode" >&2
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

  # --- Open directory in new Zellij pane --------------------------------------
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

  # --- Reveal file in Yazi sidebar -------------------------------------------
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

      # Check if running inside Yazi (YAZI_ID is set by Yazi itself)
      if [[ -z "$YAZI_ID" ]]; then
          echo "Not running inside Yazi - YAZI_ID not set" >&2
          exit 1
      fi

      # Use ya emit-to to send reveal command to Yazi instance
      if command -v ya &>/dev/null; then
          ya emit-to "$YAZI_ID" reveal "$FILE"
          ${pkgs.zellij}/bin/zellij action focus-left
      else
          echo "ya command not found - cannot reveal file" >&2
          exit 1
      fi
    '';
  };

}
