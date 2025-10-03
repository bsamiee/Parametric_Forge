# Title         : side.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/layouts/side.nix
# ----------------------------------------------------------------------------
# Nix-generated terminal layout for Zellij

{ config, lib, pkgs, ... }:

{
  xdg.configFile."zellij/layouts/side.kdl".text = ''
    // Title         : side.kdl
    // Author        : Bardia Samiee
    // Project       : Parametric Forge
    // License       : MIT
    // Path          : modules/home/programs/apps/zellij/layouts/side.kdl
    // ----------------------------------------------------------------------------
    // PLACEHOLDER

    layout {
        tab_template name="ui" {
            pane size=1 borderless=true {
              plugin location="zjstatus"
            }
            children
            pane size=1 borderless=true {
              plugin location="zellij:status-bar"
            }
        }
        default_tab_template {
          pane size=1 borderless=true {
            plugin location="zjstatus"
          }
          pane split_direction="vertical" {
            pane name="sidebar" {
              command "yazi"
              size    "20%"
            }
          }
          pane size=1 borderless=true {
            plugin location="zellij:status-bar"
          }
        }
    }

  '';
}
