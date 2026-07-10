# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/layouts/default.nix
# ----------------------------------------------------------------------------
# Shell-first Zellij layout; editor and Yazi arrive on demand via the rail

{config, ...}: let
  lazygitPopup = config.programs.zellij.popupGeometry.lazygit;
in {
  xdg.configFile."zellij/layouts/default.kdl".text = ''
    // Title         : default.kdl
    // Author        : Bardia Samiee
    // Project       : Parametric Forge
    // License       : MIT
    // Path          : modules/home/programs/apps/zellij/layouts/default.kdl
    // ----------------------------------------------------------------------------
    // Shell-first layout with floating lazygit; nvim spawns via forge-edit rail

    layout {
        // --- [PANE_TEMPLATES]
        pane_template name="lazygit" start_suspended=true {
            command         "lazygit"
            x               "${lazygitPopup.x}"
            y               "${lazygitPopup.y}"
            width           "${lazygitPopup.width}"
            height          "${lazygitPopup.height}"
        }

        // --- [TAB_TEMPLATES]
        // Top zjstatus: tabs/layout/session. Bottom zjstatus-hints: mode + key ribbon.
        tab_template name="ui" {
            pane size=1 borderless=true {
                plugin location="zjstatus"
            }
            children
            pane size=1 borderless=true {
                plugin location="zjstatus-hints"
            }
        }

        default_tab_template hide_floating_panes=true {
            floating_panes {
                lazygit
            }
            pane size=1 borderless=true {
                plugin location="zjstatus"
            }
            pane
            pane size=1 borderless=true {
                plugin location="zjstatus-hints"
            }
        }

        // --- [LAYOUTS]
        // Pane counts include the two bars from the ui template
        swap_tiled_layout name="[DEFAULT]" {
            ui exact_panes=3 {
                pane
            }
        }

        swap_tiled_layout name="[TWO_COLUMNS]" {
            ui min_panes=4 {
                pane split_direction="vertical" {
                    pane
                    pane stacked=true {
                        children
                    }
                }
            }
        }

        swap_tiled_layout name="[TWO_ROWS]" {
            ui min_panes=4 {
                pane split_direction="horizontal" {
                    pane
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
                        pane
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
