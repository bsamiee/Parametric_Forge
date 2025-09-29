# Title         : trippy.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/trippy.nix
# ----------------------------------------------------------------------------
# Modern network diagnostic tool combining traceroute and ping

{ config, lib, pkgs, ... }:

# Dracula theme color reference
# background    #15131F
# current_line  #2A2640
# selection     #44475a
# foreground    #F8F8F2
# comment       #7A71AA
# purple        #A072C6
# cyan          #94F2E8
# green         #50FA7B
# yellow        #F1FA8C
# orange        #F97359
# red           #ff5555
# magenta       #d82f94
# pink          #E98FBE

let
  tomlFormat = pkgs.formats.toml { };

  trippyConfig = {
    # --- Tracing Configuration ----------------------------------------------
    addr-family = "system";
    max-ttl = 64;
    icmp-extensions = false;

    # --- TUI Configuration --------------------------------------------------
    tui-max-samples = 256;
    tui-max-flows = 64;

    # --- Dracula Theme Configuration ----------------------------------------
    theme-colors = {
      bg-color = "#15131F";
      border-color = "#44475a";
      text-color = "#F8F8F2";
      tab-text-color = "#7A71AA";
      hops-table-header-bg-color = "#2A2640";
      hops-table-header-text-color = "#94F2E8";
      hops-table-row-active-text-color = "#F8F8F2";
      hops-table-row-inactive-text-color = "#7A71AA";
      hops-chart-selected-color = "#50FA7B";
      hops-chart-unselected-color = "#7A71AA";
      hops-chart-axis-color = "#7A71AA";
      frequency-chart-bar-color = "#A072C6";
      frequency-chart-text-color = "#F8F8F2";
      flows-chart-bar-selected-color = "#50FA7B";
      flows-chart-bar-unselected-color = "#7A71AA";
      flows-chart-text-current-color = "#F1FA8C";
      flows-chart-text-non-current-color = "#7A71AA";
      samples-chart-color = "#E98FBE";
      samples-chart-lost-color = "#ff5555";
      help-dialog-bg-color = "#2A2640";
      help-dialog-text-color = "#F8F8F2";
      settings-dialog-bg-color = "#2A2640";
      settings-tab-text-color = "#7A71AA";
      settings-table-header-text-color = "#94F2E8";
      settings-table-header-bg-color = "#2A2640";
      settings-table-row-text-color = "#F8F8F2";
      map-world-color = "#F8F8F2";
      map-radius-color = "#F1FA8C";
      map-selected-color = "#50FA7B";
      map-info-panel-border-color = "#44475a";
      map-info-panel-bg-color = "#15131F";
      map-info-panel-text-color = "#F8F8F2";
      info-bar-bg-color = "#2A2640";
      info-bar-text-color = "#F8F8F2";
    };

    # --- Key Bindings -------------------------------------------------------
    bindings = [
      { command = "toggle-help"; keys = "h"; }
      { command = "toggle-help-alt"; keys = "?"; }
      { command = "toggle-settings"; keys = "s"; }
      { command = "toggle-settings-tui"; keys = "t"; }
      { command = "toggle-settings-trace"; keys = "T"; }
      { command = "toggle-settings-dns"; keys = "r"; }
      { command = "toggle-settings-geoip"; keys = "g"; }
      { command = "toggle-settings-bindings"; keys = "b"; }
      { command = "toggle-settings-theme"; keys = "y"; }
      { command = "toggle-settings-columns"; keys = "o"; }
      { command = "next-hop"; keys = "down,j"; }
      { command = "previous-hop"; keys = "up,k"; }
      { command = "next-trace"; keys = "right,l"; }
      { command = "previous-trace"; keys = "left,H"; }
      { command = "next-hop-address"; keys = ".,>"; }
      { command = "previous-hop-address"; keys = ","; }
      { command = "address-mode-ip"; keys = "i"; }
      { command = "address-mode-host"; keys = "n"; }
      { command = "address-mode-both"; keys = "B"; }
      { command = "toggle-freeze"; keys = "ctrl+f"; }
      { command = "toggle-chart-maximized"; keys = "m"; }
      { command = "chart-zoom-in"; keys = "="; }
      { command = "chart-zoom-out"; keys = "-"; }
      { command = "clear-trace-data"; keys = "ctrl+r"; }
      { command = "clear-dns-cache"; keys = "ctrl+k"; }
      { command = "clear-selection"; keys = "esc"; }
      { command = "toggle-as-info"; keys = "z"; }
      { command = "toggle-hop-details"; keys = "d"; }
      { command = "quit"; keys = "q"; }
    ];
  };
in
{
  home.packages = [ pkgs.trippy ];

  xdg.configFile."trippy/trippy.toml".source =
    tomlFormat.generate "trippy-config" trippyConfig;
}
