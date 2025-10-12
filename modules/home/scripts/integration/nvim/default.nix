# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/integration/nvim/default.nix
# ----------------------------------------------------------------------------
# Minimal Neovim integration helpers

{ config, lib, pkgs, ... }:

{
  home.file.".local/bin/forge-nvim.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : forge-nvim.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : modules/home/scripts/integration/nvim/forge-nvim.sh
      # ----------------------------------------------------------------------------
      # Launch Neovim with a session socket or forward to an existing instance

      set -euo pipefail

      SOCKET="/tmp/nvim-''${ZELLIJ_SESSION_NAME:-default}.sock"

      NVR_BIN="${pkgs.neovim-remote}/bin/nvr"

      if [ -x "$NVR_BIN" ]; then
        if "$NVR_BIN" --servername "$SOCKET" --remote-expr "1" >/dev/null 2>&1; then
          exec "$NVR_BIN" --servername "$SOCKET" "$@"
        fi
      fi

      export NVIM_LISTEN_ADDRESS="$SOCKET"
      exec ${pkgs.neovim}/bin/nvim --listen "$SOCKET" "$@"
    '';
  };
}
