# Title         : stacked.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/layouts/stacked.nix
# ----------------------------------------------------------------------------
# Zellij layout with stacked panes and lazygit floating pane
_: {
  xdg.configFile."zellij/layouts/stacked.kdl".text = ''
    // Title         : stacked.kdl
    // Author        : Bardia Samiee
    // Project       : Parametric Forge
    // License       : MIT
    // Path          : modules/home/programs/apps/zellij/layouts/stacked.kdl
    // ----------------------------------------------------------------------------
    // Zellij layout with pure stacked panes (yazi, editor, lazygit)

    layout {
        // --- Pane Templates -----------------------------------------------------
        pane_template name="lazygit" {
            command         "lazygit"
        }

        pane_template name="yazi" {
            command         "forge-yazi.sh"
        }

        pane_template name="editor" {
            // Keep empty, opens default shell and allows scripts to inject editor when needed
        }

        // --- Tab Templates ------------------------------------------------------
        // Applies a universal top/bottom status bar to all tabs with stacked layout
        default_tab_template {
            pane size=1 borderless=true {
                plugin location="zjstatus"
            }
            children
            pane size=1 borderless=true {
                plugin location="zellij:status-bar"
            }
        }

        // --- Starting Tab -------------------------------------------------------
        // Single stacked pane - editor expanded by default
        tab {
            pane stacked=true {
                pane name=" [YAZI] " {
                    yazi
                }
                pane name=" [EDITOR] " expanded=true {
                    editor
                }
                pane name=" [LAZYGIT] " {
                    lazygit
                }
            }
        }

        // --- Layouts ------------------------------------------------------------
        // All layouts are single stacked pane with different expanded states
        // +2 to pane count: 2 status bars
        swap_tiled_layout name=" [EDITOR] " {
            tab min_panes=5 {
                pane stacked=true {
                    pane name=" [YAZI] " {
                        yazi
                    }
                    pane name=" [EDITOR] " expanded=true {
                        editor
                    }
                    pane name=" [LAZYGIT] " {
                        lazygit
                    }
                    children
                }
            }
        }

        swap_tiled_layout name=" [YAZI] " {
            tab min_panes=5 {
                pane stacked=true {
                    pane name=" [YAZI] " expanded=true {
                        yazi
                    }
                    pane name=" [EDITOR] " {
                        editor
                    }
                    pane name=" [LAZYGIT] " {
                        lazygit
                    }
                    children
                }
            }
        }

        swap_tiled_layout name=" [GIT] " {
            tab min_panes=5 {
                pane stacked=true {
                    pane name=" [YAZI] " {
                        yazi
                    }
                    pane name=" [EDITOR] " {
                        editor
                    }
                    pane name=" [LAZYGIT] " expanded=true {
                        lazygit
                    }
                    children
                }
            }
        }

        swap_tiled_layout name=" [TERMINAL] " {
            tab min_panes=5 {
                pane stacked=true expanded=true {
                    pane name=" [YAZI] " {
                        yazi
                    }
                    pane name=" [EDITOR] " {
                        editor
                    }
                    pane name=" [LAZYGIT] " {
                        lazygit
                    }
                    children
                }
            }
        }
    }

  '';
}
