# Title         : trippy.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/trippy.nix
# ----------------------------------------------------------------------------
# Network diagnostic tool combining traceroute and ping. Rows land under the sections trippy reads (`trip --print-config-template`); every
# strategy, tui, and binding default stays upstream, so only the resolver family and the theme carry rows.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # palette retained for the one hue with no semantic role: string-yellow (radius ring, current-flow label).
  inherit (config.estate.theme) roles palette;
  tomlFormat = pkgs.formats.toml {};

  trippyConfig = {
    # --- [STRATEGY]
    # The OS resolver's first answer decides the family; the upstream default tries IPv4 before IPv6 regardless of what the resolver returned.
    strategy.addr-family = "system";

    # --- [THEME_COLORS]
    # Selected chart series ride the focus fill; borders read the canonical ui.border; dialogs sit on the raised surface. trippy reads a raw
    # color as six hex digits and rejects a leading `#`.
    theme-colors = lib.mapAttrs (_: color: lib.removePrefix "#" color.hex) {
      bg-color = roles.surface.base;
      border-color = roles.ui.border;
      text-color = roles.text.primary;
      tab-text-color = roles.text.muted;
      hops-table-header-bg-color = roles.surface.raised;
      hops-table-header-text-color = roles.accent.primary;
      hops-table-row-active-text-color = roles.text.primary;
      hops-table-row-inactive-text-color = roles.text.muted;
      hops-chart-selected-color = roles.focus.active;
      hops-chart-unselected-color = roles.text.muted;
      hops-chart-axis-color = roles.text.muted;
      frequency-chart-bar-color = roles.accent.structural;
      frequency-chart-text-color = roles.text.primary;
      flows-chart-bar-selected-color = roles.focus.active;
      flows-chart-bar-unselected-color = roles.text.muted;
      flows-chart-text-current-color = palette.yellow;
      flows-chart-text-non-current-color = roles.text.muted;
      samples-chart-color = roles.accent.tertiary;
      samples-chart-lost-color = roles.state.danger;
      help-dialog-bg-color = roles.surface.raised;
      help-dialog-text-color = roles.text.primary;
      settings-dialog-bg-color = roles.surface.raised;
      settings-tab-text-color = roles.text.muted;
      settings-table-header-text-color = roles.accent.primary;
      settings-table-header-bg-color = roles.surface.raised;
      settings-table-row-text-color = roles.text.primary;
      map-world-color = roles.text.primary;
      map-radius-color = palette.yellow;
      map-selected-color = roles.focus.active;
      map-info-panel-border-color = roles.ui.border;
      map-info-panel-bg-color = roles.surface.base;
      map-info-panel-text-color = roles.text.primary;
      info-bar-bg-color = roles.surface.raised;
      info-bar-text-color = roles.text.primary;
    };
  };
in {
  home.packages = [pkgs.trippy];

  xdg.configFile."trippy/trippy.toml".source =
    tomlFormat.generate "trippy-config" trippyConfig;
}
