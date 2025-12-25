# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/layouts/default.nix
# ----------------------------------------------------------------------------
# Zellij layout with yazi file manager, editor, and lazygit floating pane
_: {
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
        // Applies a universal top/bottom status bar to all tabs
        tab_template name="ui" {
            pane size=1 borderless=true {
                plugin location="zjstatus"
            }
            children
            pane size=1 borderless=true {
                plugin location="zellij:status-bar"
            }
        }

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
            }
            pane size=1 borderless=true {
                plugin location="zellij:status-bar"
            }
        }

        // --- Layouts ----------------------------------------------------------------
        // All layouts have +2 to the pane count, inherited from default_tab_template and a suspended lazygit floating pane
        swap_tiled_layout name="[DEFAULT]" {
            ui exact_panes=4 {
                pane split_direction="vertical" {
                    pane name=" [YAZI] " {
                        yazi
                        size    "20%"
                    }
                    pane name=" [EDITOR] " {
                        editor
                    }
                }
            }
        }

        swap_tiled_layout name="[TWO_COLUMNS]" {
            ui min_panes=5 {
                pane split_direction="vertical" {
                    pane name=" [YAZI] " {
                        yazi
                        size    "20%"
                    }
                    pane name=" [EDITOR] " {
                        editor
                    }
                    pane stacked=true {
                        children
                    }
                }
            }
        }

        swap_tiled_layout name="[TWO_ROWS]" {
            ui min_panes=5 {
                pane split_direction="vertical" {
                    pane name=" [YAZI] " {
                        yazi
                        size    "20%"
                    }
                    pane split_direction="horizontal" {
                        pane name=" [EDITOR] " {
                            editor
                        }
                        pane stacked=true {
                            children
                        }
                    }
                }
            }
        }

        swap_tiled_layout name="[GRID]" {
            ui min_panes=7 {
                pane split_direction="vertical" {
                    pane name=" [YAZI] " {
                        yazi
                        size    "20%"
                    }
                    pane split_direction="vertical" {
                        pane split_direction="horizontal" {
                            pane name=" [EDITOR] " {
                                editor
                            }
                            pane
                        }
                    }
                    pane split_direction="vertical" {
                        pane split_direction="horizontal" {
                            pane stacked=true {
                                children
                            }
                            pane
                        }
                    }
                }
            }
        }
    }

  '';
}
