# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/layouts/default.nix
# ----------------------------------------------------------------------------
# Editor-first Zellij layout; Yazi lives in an on-demand floating popup only
_: {
  xdg.configFile."zellij/layouts/default.kdl".text = ''
    // Title         : default.kdl
    // Author        : Bardia Samiee
    // Project       : Parametric Forge
    // License       : MIT
    // Path          : modules/home/programs/apps/zellij/layouts/default.kdl
    // ----------------------------------------------------------------------------
    // Editor-first layout with floating lazygit; Yazi popup arrives via keybind

    layout {
        // --- Pane Templates ---------------------------------------------------------
        pane_template name="lazygit" start_suspended=true {
            command         "lazygit"
            x               "10%"
            y               "5%"
            width           "80%"
            height          "80%"
        }

        // Self-registering Neovim server; owns the tab's editor socket registry
        pane_template name="editor" {
            command         "forge-nvim.sh"
        }

        // --- Tab Templates ----------------------------------------------------------
        // Universal top zjstatus bar and bottom compact-bar (tooltip surface)
        tab_template name="ui" {
            pane size=1 borderless=true {
                plugin location="zjstatus"
            }
            children
            pane size=1 borderless=true {
                plugin location="compact-bar"
            }
        }

        default_tab_template hide_floating_panes=true {
            floating_panes {
                lazygit
            }
            pane size=1 borderless=true {
                plugin location="zjstatus"
            }
            pane name=" [EDITOR] " {
                editor
            }
            pane size=1 borderless=true {
                plugin location="compact-bar"
            }
        }

        // --- Layouts ----------------------------------------------------------------
        // Pane counts include the two bars from the ui template
        swap_tiled_layout name="[DEFAULT]" {
            ui exact_panes=3 {
                pane name=" [EDITOR] " {
                    editor
                }
            }
        }

        swap_tiled_layout name="[TWO_COLUMNS]" {
            ui min_panes=4 {
                pane split_direction="vertical" {
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
            ui min_panes=4 {
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

        swap_tiled_layout name="[GRID]" {
            ui min_panes=6 {
                pane split_direction="horizontal" {
                    pane split_direction="vertical" {
                        pane name=" [EDITOR] " {
                            editor
                        }
                        pane
                    }
                    pane split_direction="vertical" {
                        pane stacked=true {
                            children
                        }
                        pane
                    }
                }
            }
        }
    }

  '';
}
