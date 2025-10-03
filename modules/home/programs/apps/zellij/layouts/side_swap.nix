# Title         : side_swap.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/layouts/side_swap.nix
# ----------------------------------------------------------------------------
# Swappable layout variants for sidebar mode with different pane configurations

{ config, lib, pkgs, ... }:

{ # FILE NAME MUST BE "X.swap.kdl" FOR ZELLIJ TO RECOGNIZE IT AS A SWAP LAYOUT
    xdg.configFile."zellij/layouts/side.swap.kdl".text = ''
    // Title         : side_swap.kdl
    // Author        : Bardia Samiee
    // Project       : Parametric Forge
    // License       : MIT
    // Path          : modules/home/programs/apps/zellij/layouts/side.swap.kdl
    // ----------------------------------------------------------------------------
    // Swappable layout variants for sidebar mode with different pane configurations

    swap_tiled_layout name="basic" {
        ui exact_panes=4 {
            pane split_direction="vertical" {
                pane name="sidebar" {
                    command "yazi"
                    size    "20%"
                }
                pane
            }
        }
    }

    swap_tiled_layout name="stacked" {
        ui min_panes=5 {
            pane split_direction="vertical" {
                pane name="sidebar" {
                    command "yazi"
                    size    "20%"
                }
                pane stacked=true { children; }
            }
        }
    }

    swap_tiled_layout name="three_column" {
        ui min_panes=5 {
            pane split_direction="vertical" {
                pane name="sidebar" {
                    command "yazi"
                    size    "20%"
                }
                pane stacked=true {
                    children;
                    size "40%"
                }
                pane split_direction="vertical" {
                    size "40%"
                }
            }
        }
    }

    swap_tiled_layout name="sidebar_closed" {
        ui min_panes=5 {
            pane split_direction="vertical" {
                pane name="sidebar" {
                    command "yazi"
                    size    "1"
                }
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
