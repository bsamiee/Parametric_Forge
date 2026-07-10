# Title         : trippy.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/trippy.nix
# ----------------------------------------------------------------------------
# Modern network diagnostic tool combining traceroute and ping
{
  config,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette;
  tomlFormat = pkgs.formats.toml {};

  trippyConfig = {
    # --- [TRACING_CONFIGURATION]
    addr-family = "system";
    max-ttl = 64;
    icmp-extensions = false;

    # --- [TUI_CONFIGURATION]
    tui-max-samples = 256;
    tui-max-flows = 64;

    # --- [THEME_CONFIGURATION_ESTATE_PALETTE_TOKENS]
    theme-colors = {
      bg-color = palette.background.hex;
      border-color = palette.selection.hex;
      text-color = palette.foreground.hex;
      tab-text-color = palette.comment.hex;
      hops-table-header-bg-color = palette.current_line.hex;
      hops-table-header-text-color = palette.cyan.hex;
      hops-table-row-active-text-color = palette.foreground.hex;
      hops-table-row-inactive-text-color = palette.comment.hex;
      hops-chart-selected-color = palette.green.hex;
      hops-chart-unselected-color = palette.comment.hex;
      hops-chart-axis-color = palette.comment.hex;
      frequency-chart-bar-color = palette.purple.hex;
      frequency-chart-text-color = palette.foreground.hex;
      flows-chart-bar-selected-color = palette.green.hex;
      flows-chart-bar-unselected-color = palette.comment.hex;
      flows-chart-text-current-color = palette.yellow.hex;
      flows-chart-text-non-current-color = palette.comment.hex;
      samples-chart-color = palette.pink.hex;
      samples-chart-lost-color = palette.red.hex;
      help-dialog-bg-color = palette.current_line.hex;
      help-dialog-text-color = palette.foreground.hex;
      settings-dialog-bg-color = palette.current_line.hex;
      settings-tab-text-color = palette.comment.hex;
      settings-table-header-text-color = palette.cyan.hex;
      settings-table-header-bg-color = palette.current_line.hex;
      settings-table-row-text-color = palette.foreground.hex;
      map-world-color = palette.foreground.hex;
      map-radius-color = palette.yellow.hex;
      map-selected-color = palette.green.hex;
      map-info-panel-border-color = palette.selection.hex;
      map-info-panel-bg-color = palette.background.hex;
      map-info-panel-text-color = palette.foreground.hex;
      info-bar-bg-color = palette.current_line.hex;
      info-bar-text-color = palette.foreground.hex;
    };

    # --- [KEY_BINDINGS]
    bindings = [
      {
        command = "toggle-help";
        keys = "h";
      }
      {
        command = "toggle-help-alt";
        keys = "?";
      }
      {
        command = "toggle-settings";
        keys = "s";
      }
      {
        command = "toggle-settings-tui";
        keys = "t";
      }
      {
        command = "toggle-settings-trace";
        keys = "T";
      }
      {
        command = "toggle-settings-dns";
        keys = "r";
      }
      {
        command = "toggle-settings-geoip";
        keys = "g";
      }
      {
        command = "toggle-settings-bindings";
        keys = "b";
      }
      {
        command = "toggle-settings-theme";
        keys = "y";
      }
      {
        command = "toggle-settings-columns";
        keys = "o";
      }
      {
        command = "next-hop";
        keys = "down,j";
      }
      {
        command = "previous-hop";
        keys = "up,k";
      }
      {
        command = "next-trace";
        keys = "right,l";
      }
      {
        command = "previous-trace";
        keys = "left,H";
      }
      {
        command = "next-hop-address";
        keys = ".,>";
      }
      {
        command = "previous-hop-address";
        keys = ",";
      }
      {
        command = "address-mode-ip";
        keys = "i";
      }
      {
        command = "address-mode-host";
        keys = "n";
      }
      {
        command = "address-mode-both";
        keys = "B";
      }
      {
        command = "toggle-freeze";
        keys = "ctrl+f";
      }
      {
        command = "toggle-chart-maximized";
        keys = "m";
      }
      {
        command = "chart-zoom-in";
        keys = "=";
      }
      {
        command = "chart-zoom-out";
        keys = "-";
      }
      {
        command = "clear-trace-data";
        keys = "ctrl+r";
      }
      {
        command = "clear-dns-cache";
        keys = "ctrl+k";
      }
      {
        command = "clear-selection";
        keys = "esc";
      }
      {
        command = "toggle-as-info";
        keys = "z";
      }
      {
        command = "toggle-hop-details";
        keys = "d";
      }
      {
        command = "quit";
        keys = "q";
      }
    ];
  };
in {
  home.packages = [pkgs.trippy];

  xdg.configFile."trippy/trippy.toml".source =
    tomlFormat.generate "trippy-config" trippyConfig;
}
