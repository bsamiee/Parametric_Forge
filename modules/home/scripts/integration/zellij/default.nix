# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/integration/zellij/default.nix
# ----------------------------------------------------------------------------
# Zellij integration utility scripts

{ config, lib, pkgs, ... }:

{
  # --- Get running command in current Zellij pane ---------------------------
  home.file.".local/bin/zellij-get-command.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : zellij-get-command.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : ~/.local/bin/zellij-get-command.sh
      # ----------------------------------------------------------------------------
      # Get the running command in current Zellij pane

      # Use zellij list-clients to get the running command
      # Format: extract everything after the first two fields (client and session)
      ${pkgs.zellij}/bin/zellij action list-clients 2>/dev/null | \
        ${pkgs.gnused}/bin/sed -n '2p' | \
        ${pkgs.gawk}/bin/awk '{$1=$2=""; print $0}' | \
        ${pkgs.findutils}/bin/xargs || echo ""
    '';
  };

  # --- Find nvim in Zellij panes --------------------------------------------
  home.file.".local/bin/zellij-find-nvim.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : zellij-find-nvim.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : ~/.local/bin/zellij-find-nvim.sh
      # ----------------------------------------------------------------------------
      # Search through Zellij panes to find nvim instance

      # Search up to 4 panes for nvim
      for i in {1..4}; do
        CMD=$(zellij-get-command.sh)

        # Check if command contains nvim/vim or is from nix store
        if [[ "$CMD" == *"nvim"* ]] || [[ "$CMD" == *"vim"* ]] || [[ "$CMD" == */nix/store/*nvim* ]]; then
          exit 0  # Found nvim/vim
        fi

        # Move to next pane
        ${pkgs.zellij}/bin/zellij action focus-next-pane
      done

      # Not found in any pane
      exit 1
    '';
  };

  # --- Move current pane to top position ------------------------------------
  home.file.".local/bin/zellij-move-pane-top.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : zellij-move-pane-top.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : ~/.local/bin/zellij-move-pane-top.sh
      # ----------------------------------------------------------------------------
      # Move current pane to top position

      # Number of steps to move up (default: 3)
      STEPS="''${1:-3}"

      # Move pane up specified number of times
      for ((i=0; i<$STEPS; i++)); do
        ${pkgs.zellij}/bin/zellij action move-pane up
      done
    '';
  };

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
      # Toggle between sidebar and no-sidebar layouts

      CURRENT="''${YAZI_ENABLE_SIDEBAR:-true}"

      if [[ "$CURRENT" == "true" ]]; then
          export YAZI_ENABLE_SIDEBAR="false"
          ${pkgs.zellij}/bin/zellij action switch-layout "no_side"
      else
          export YAZI_ENABLE_SIDEBAR="true"
          ${pkgs.zellij}/bin/zellij action switch-layout "side"
      fi

      # Update the environment for child processes
      echo "Sidebar mode: $YAZI_ENABLE_SIDEBAR"
    '';
  };
}
