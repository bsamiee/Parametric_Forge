# Title         : terminal.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/layouts/terminal.nix
# ----------------------------------------------------------------------------
# Nix-generated terminal layout for Zellij

{ config, lib, pkgs, ... }:

{
  xdg.configFile."zellij/layouts/terminal.kdl".text = ''
    // Title         : terminal.kdl
    // Author        : Bardia Samiee
    // Project       : Parametric Forge
    // License       : MIT
    // Path          : modules/home/programs/apps/zellij/layouts/terminal.kdl
    // ----------------------------------------------------------------------------
    // Standard terminal layout with integrated status bar at top

    layout {
        default_tab_template {
            pane size=2 borderless=true {
                plugin location="zjstatus"
            }
            children  // Main panes appear below the status bar
        }
    }

  '';
}
