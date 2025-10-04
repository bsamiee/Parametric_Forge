# Title         : no_side_swap.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/layouts/no_side_swap.nix
# ----------------------------------------------------------------------------
# Swappable layout variants for fullscreen mode without sidebar

{ config, lib, pkgs, ... }:

{ # FILE NAME MUST BE "X.swap.kdl" FOR ZELLIJ TO RECOGNIZE IT AS A SWAP LAYOUT
  xdg.configFile."zellij/layouts/no_side.swap.kdl".text = ''
    // Title         : no_side.swap.kdl
    // Author        : Bardia Samiee
    // Project       : Parametric Forge
    // License       : MIT
    // Path          : modules/home/programs/apps/zellij/layouts/no_side.swap.kdl
    // ----------------------------------------------------------------------------
    // Swappable layout variants for fullscreen mode without sidebar

    swap_tiled_layout name="basic" {
        ui exact_panes=2 {
            pane split_direction="vertical" {
                pane name="yazi" {
                    command "yazi" "--client-id" "filemanager"
                    size    "100%"
                }
            }
        }
    }

    swap_tiled_layout name="stacked" {
        ui min_panes=3 {
            pane stacked=true {
                children;
            }
        }
    }

    swap_tiled_layout name="two_column" {
        ui min_panes=3 {
            pane split_direction="vertical" {
                pane stacked=true {
                    children;
                    size "50%"
                }
                pane split_direction="vertical" {
                    size "50%"
                }
            }
        }
    }

  '';
}
