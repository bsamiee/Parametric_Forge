# Title         : no_side.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/layouts/no_side.nix
# ----------------------------------------------------------------------------
# Zellij layout with fullscreen Yazi file manager

{ config, lib, pkgs, ... }:

{
  xdg.configFile."zellij/layouts/no_side.kdl".text = ''
    // Title         : no_side.kdl
    // Author        : Bardia Samiee
    // Project       : Parametric Forge
    // License       : MIT
    // Path          : modules/home/programs/apps/zellij/layouts/no_side.kdl
    // ----------------------------------------------------------------------------
    // Zellij layout with fullscreen Yazi file manager

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
            pane name="filemanager" {
              command "yazi"
              size    "100%"
            }
          }
          pane size=1 borderless=true {
            plugin location="zellij:status-bar"
          }
        }
    }

  '';
}
