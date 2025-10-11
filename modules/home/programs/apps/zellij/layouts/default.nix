# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/layouts/default.nix
# ----------------------------------------------------------------------------
# Zellij layout with yazi file manager, editor, and lazygit floating pane

{ config, lib, pkgs, ... }:

{
    xdg.configFile."zellij/layouts/default.kdl".text = ''
    // Title         : default.kdl
    // Author        : Bardia Samiee
    // Project       : Parametric Forge
    // License       : MIT
    // Path          : modules/home/programs/apps/zellij/layouts/default.kdl
    // ----------------------------------------------------------------------------
    // Zellij layout with yazi file manager, nvim editor, and lazygit floating

    layout {
        // --- Pane Templates ---------------------------------------------------------
        pane_template name="lazygit" start_suspended=true {
            command         "lazygit"
            x               "10%"
            y               "5%"
            width           "80%"
            height          "80%"
        }

        pane_template name="yazi" {
            command         "forge-yazi.sh"
        }

        pane_template name="editor" {
            // Keep empty, opens default shell and allows scripts to inject editor when needed
        }

        // --- Tab Templates ----------------------------------------------------------
        // Applies a universal top/bottom status bar and yazi sidebar to all tabs
        default_tab_template hide_floating_panes=true {
            floating_panes {
                lazygit
            }
            pane size=1 borderless=true {
                plugin location="zjstatus"
            }
            pane split_direction="vertical" {
                pane name=" [YAZI] " {
                    yazi
                    size    "20%"
                }
                children
            }
            pane size=1 borderless=true {
                plugin location="zellij:status-bar"
            }
        }

        // --- Starting Tab -----------------------------------------------------------
        // Will automatically trigger "[DEFAULT]" layout with an editor pane that takes 80% of the space
        tab {
            pane split_direction="vertical" {
                pane name=" [EDITOR] " {
                    editor
                }
            }
        }

        // --- Layouts ----------------------------------------------------------------
        // All layouts have +3 to the pane count, inherited from default_tab_template and a suspended lazygit floating pane
        swap_tiled_layout_name=" [DEFAULT] " {
            tab exact_panes=4 {
                pane split_direction="vertical" {
                    pane name=" [EDITOR] " {
                        editor
                    }
                }
            }
        }

        swap_tiled_layout_name=" [TWO_COLUMNS] " {
            tab min_panes=5 {
                pane split_direction="vertical" {
                    pane name=" [EDITOR] " {
                        editor
                        size    "50%"
                    }
                    pane stacked=true {
                        children
                        size    "50%"
                    }
                }
            }
        }

        swap_tiled_layout_name=" [TWO_ROWS] " {
            tab min_panes=5 {
                pane split_direction="horizontal" {
                    pane name=" [EDITOR] " {
                        editor
                        size    "50%"
                    }
                    pane stacked=true {
                        children
                        size    "50%"
                    }
                }
            }
        }

        swap_tiled_layout_name=" [GRID] " {
            tab min_panes=7 {
                pane split_direction="horizontal" {
                    pane split_direction="vertical" size="50%" {
                        pane name=" [EDITOR] " size="50%"
                        pane
                    }
                    pane split_direction="vertical" size="50%" {
                        pane stacked=true size="50%" { children }
                        pane
                    }
                }
            }
        }

        swap_tiled_layout_name=" [STACKED] " {
            tab min_panes=5 {
                pane split_direction="vertical" {
                    pane name=" [EDITOR] " {
                        editor
                        children
                    }
                }
            }
        }

        swap_tiled_layout_name=" [SIDEBAR_CLOSED] " {
            tab min_panes=5 {
                pane split_direction="vertical" {
                    pane name=" [YAZI] " {
                        yazi
                        size    "1"
                    }
                    pane name=" [EDITOR] " {
                        editor
                        size    "50%"
                    }
                    pane stacked=true {
                        children
                        size    "50%"
                    }
                }
            }
        }
    }

    '';
}
