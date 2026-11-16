_: {
  programs.zellij.layouts.default = ''

    layout {
        default_tab_template {
            pane size=1 borderless=true {
                plugin location="statusbar-top"
            }
            children
            pane size=1 borderless=true {
                plugin location="statusbar-bottom"
            }
        }
    }

  '';
}
