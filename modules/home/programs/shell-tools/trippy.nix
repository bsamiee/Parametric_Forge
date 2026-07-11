# Title         : trippy.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/trippy.nix
# ----------------------------------------------------------------------------
# Network diagnostic tool combining traceroute and ping
{
  config,
  pkgs,
  ...
}: let
  # palette retained for the one hue with no semantic role: string-yellow (radius ring, current-flow label).
  inherit (config.forge.theme) roles palette;
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
    # Selected chart series ride the focus fill; borders read the canonical ui.border; dialogs sit on the raised surface.
    theme-colors = {
      bg-color = roles.surface.base.hex;
      border-color = roles.ui.border.hex;
      text-color = roles.text.primary.hex;
      tab-text-color = roles.text.muted.hex;
      hops-table-header-bg-color = roles.surface.raised.hex;
      hops-table-header-text-color = roles.accent.primary.hex;
      hops-table-row-active-text-color = roles.text.primary.hex;
      hops-table-row-inactive-text-color = roles.text.muted.hex;
      hops-chart-selected-color = roles.focus.active.hex;
      hops-chart-unselected-color = roles.text.muted.hex;
      hops-chart-axis-color = roles.text.muted.hex;
      frequency-chart-bar-color = roles.accent.structural.hex;
      frequency-chart-text-color = roles.text.primary.hex;
      flows-chart-bar-selected-color = roles.focus.active.hex;
      flows-chart-bar-unselected-color = roles.text.muted.hex;
      flows-chart-text-current-color = palette.yellow.hex;
      flows-chart-text-non-current-color = roles.text.muted.hex;
      samples-chart-color = roles.accent.tertiary.hex;
      samples-chart-lost-color = roles.state.danger.hex;
      help-dialog-bg-color = roles.surface.raised.hex;
      help-dialog-text-color = roles.text.primary.hex;
      settings-dialog-bg-color = roles.surface.raised.hex;
      settings-tab-text-color = roles.text.muted.hex;
      settings-table-header-text-color = roles.accent.primary.hex;
      settings-table-header-bg-color = roles.surface.raised.hex;
      settings-table-row-text-color = roles.text.primary.hex;
      map-world-color = roles.text.primary.hex;
      map-radius-color = palette.yellow.hex;
      map-selected-color = roles.focus.active.hex;
      map-info-panel-border-color = roles.ui.border.hex;
      map-info-panel-bg-color = roles.surface.base.hex;
      map-info-panel-text-color = roles.text.primary.hex;
      info-bar-bg-color = roles.surface.raised.hex;
      info-bar-text-color = roles.text.primary.hex;
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
