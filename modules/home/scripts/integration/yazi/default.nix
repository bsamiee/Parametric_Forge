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
      # Determine which Yazi layout (sidebar vs filemanager) is active by inspecting Zellij

      set -euo pipefail

      DEFAULT_MODE="sidebar"
      CURRENT_MODE="''$DEFAULT_MODE"

      if command -v ${pkgs.zellij}/bin/zellij >/dev/null 2>&1; then
        if LAYOUT_OUTPUT="$(${pkgs.zellij}/bin/zellij action dump-layout 2>/dev/null)"; then
          if printf "%s" "''$LAYOUT_OUTPUT" | ${pkgs.ripgrep}/bin/rg -q "pane name=\"sidebar\""; then
            CURRENT_MODE="sidebar"
          elif printf "%s" "''$LAYOUT_OUTPUT" | ${pkgs.ripgrep}/bin/rg -q "pane name=\"filemanager\""; then
            CURRENT_MODE="filemanager"
          fi
        fi
      fi

      printf "%s\n" "''$CURRENT_MODE"
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
      # Open file in nvim using RPC when available, fallback to spawning a new pane

      set -euo pipefail

      if [[ ''$# -lt 1 ]]; then
        echo "Usage: yazi-open-nvim.sh <path>" >&2
        exit 1
      fi

      REALPATH_BIN=${pkgs.coreutils}/bin/realpath
      if [[ -x "''$REALPATH_BIN" ]]; then
        FILE="$(''$REALPATH_BIN "''$1")"
      else
        FILE="''$1"
      fi
      DIR_PATH=$(dirname -- "''$FILE")
      NVIM_ADDR="''${XDG_RUNTIME_DIR:-/tmp}/nvim-''${ZELLIJ_SESSION_NAME:-main}.sock"
      NVIM_BIN="${pkgs.neovim}/bin/nvim"

      read -r YAZI_CLIENT <<< "$(yazi-current-client.sh 2>/dev/null || echo sidebar)"
      IN_ZELLIJ=false
      if [[ -n "''${ZELLIJ_SESSION_NAME:-}" ]]; then
        IN_ZELLIJ=true
      fi

      remote_open=false
      if [[ -n "''$NVIM_ADDR" && -S "''$NVIM_ADDR" ]]; then
        if command -v "''$NVIM_BIN" >/dev/null 2>&1; then
          if "''$NVIM_BIN" --server "''$NVIM_ADDR" --remote "''$FILE" >/dev/null 2>&1; then
            remote_open=true
          fi
        fi
      fi

      if ''$remote_open; then
        if [[ -n "''$DIR_PATH" ]]; then
          ESCAPED_DIR=''${DIR_PATH//\\/\\\\}
          ESCAPED_DIR=''${ESCAPED_DIR//"/\"}
          REMOTE_CMD="<C-\\><C-N>:execute \"lcd \" .. fnameescape(\"''$ESCAPED_DIR\")<CR>"
          "''$NVIM_BIN" --server "''$NVIM_ADDR" --remote-send "''$REMOTE_CMD" >/dev/null 2>&1 || true
        fi

        if ''$IN_ZELLIJ; then
          if zellij-find-nvim.sh; then
            zellij-move-pane-top.sh 3
          fi

          if [[ "''$YAZI_CLIENT" == "filemanager" ]]; then
            ${pkgs.zellij}/bin/zellij action focus-previous-pane >/dev/null 2>&1 || true
            ${pkgs.zellij}/bin/zellij action close-pane >/dev/null 2>&1 || true
          fi
        fi
        exit 0
      fi

      if ''$IN_ZELLIJ; then
        if ${pkgs.git}/bin/git -C "''$DIR_PATH" rev-parse --show-toplevel &>/dev/null; then
          TAB_NAME=$(basename "$(${pkgs.git}/bin/git -C "''$DIR_PATH" rev-parse --show-toplevel)")
        else
          TAB_NAME=$(basename "''$DIR_PATH")
        fi

        ${pkgs.zellij}/bin/zellij action new-pane --direction right --cwd "''$DIR_PATH" --name "editor" -- ${pkgs.neovim}/bin/nvim "''$FILE"
        ${pkgs.zellij}/bin/zellij action rename-tab "''$TAB_NAME"
      else
        cd "''$DIR_PATH"
        exec ${pkgs.neovim}/bin/nvim "''$FILE"
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
      if [[ "''$YAZI_CLIENT" != "sidebar" ]]; then
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

      TARGET_PATH="''$1"
      if [[ -z "''$TARGET_PATH" ]]; then
        echo "Usage: yazi-open-dir.sh <path>" >&2
        exit 1
      fi

      REALPATH_BIN=${pkgs.coreutils}/bin/realpath
      if [[ -x "''$REALPATH_BIN" ]]; then
        TARGET_PATH="$(''$REALPATH_BIN "''$TARGET_PATH")"
      fi

      if [[ -d "''$TARGET_PATH" ]]; then
        TARGET_DIR="''$TARGET_PATH"
      else
        TARGET_DIR=$(dirname -- "''$TARGET_PATH")
      fi

      ${pkgs.zellij}/bin/zellij action new-pane --direction right --cwd "''$TARGET_DIR" -- zsh
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

      FILE="''$1"

      # Determine target client dynamically (sidebar preferred, fallback to filemanager)
      CLIENT_ID=$(yazi-current-client.sh 2>/dev/null || true)
      [[ -z "''$CLIENT_ID" ]] && CLIENT_ID="sidebar"

      YA_BIN=${pkgs.yazi}/bin/ya

      # Use ya pub-to to send reveal command to Yazi instance
      if [[ -x "''$YA_BIN" ]]; then
          "''$YA_BIN" pub-to "''$CLIENT_ID" reveal --str "''$FILE" >/dev/null 2>&1 || true
          ${pkgs.zellij}/bin/zellij action focus-left >/dev/null 2>&1 || true
      else
          echo "ya command not found - cannot reveal file" >&2
          exit 1
      fi
    '';
  };

}
