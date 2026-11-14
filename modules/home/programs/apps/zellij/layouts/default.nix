_: {
  programs.zellij.layouts.default = ''

    layout {
        // --- [TAB_TEMPLATES]
        tab_template name="ui" {
            pane size=1 borderless=true {
                plugin location="statusbar-tabs"
            }
            children
            pane size=1 borderless=true {
                plugin location="statusbar-modes"
            }
        }

        default_tab_template {
            pane size=1 borderless=true {
                plugin location="statusbar-tabs"
            }
            pane
            pane size=1 borderless=true {
                plugin location="statusbar-modes"
            }
        }

        // --- [LAYOUTS]
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
