# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/integration/zellij/default.nix
# ----------------------------------------------------------------------------
# Zellij integration utility scripts
{pkgs, ...}: {
  home.file.".local/bin/forge-yazi.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : forge-yazi.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : modules/home/scripts/integration/zellij/forge-yazi.sh
      # ----------------------------------------------------------------------------
      # Yazi wrapper that sets forge-edit.sh as the editor

      set -euo pipefail

      EDITOR='forge-edit.sh' ${pkgs.yazi}/bin/yazi "''${1:-$(pwd)}"

    '';
  };

  home.file.".local/bin/forge-edit.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : forge-edit.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : modules/home/scripts/integration/zellij/forge-edit.sh
      # ----------------------------------------------------------------------------
      # Opens files in nvim using nvr by running it in the editor pane

      set -euo pipefail

      # Create socket path based on Zellij session
      SOCKET="/tmp/nvim-''${ZELLIJ_SESSION_NAME:-default}.sock"

      # Focus the editor pane (next to yazi)
      ${pkgs.zellij}/bin/zellij action focus-next-pane

      # Check if nvim is already running by trying to connect
      if ${pkgs.neovim-remote}/bin/nvr --servername "$SOCKET" --remote-expr "1" >/dev/null 2>&1; then
        # Nvim is running, just send the files
        ${pkgs.neovim-remote}/bin/nvr --servername "$SOCKET" --remote-silent "$@"
      else
        # Nvim not running, start it in the pane with the files
        ${pkgs.zellij}/bin/zellij action write-chars "${pkgs.neovim}/bin/nvim --listen \$SOCKET \$*"
        ${pkgs.zellij}/bin/zellij action write 13  # Enter key
      fi

    '';
  };
}
