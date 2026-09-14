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
  pkgs,
  ...
}: let
  # palette retained for the one hue with no semantic role: string-yellow (radius ring, current-flow label).
  inherit (config.forge.theme) roles palette;
  tomlFormat = pkgs.formats.toml {};

  trippyConfig = {
    # --- [STRATEGY]
    # The OS resolver's first answer decides the family; the upstream default tries IPv4 before IPv6 regardless of what the resolver returned.
    strategy.addr-family = "system";

    # --- [THEME_COLORS]
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
  };
in {
  home.packages = [pkgs.trippy];

  xdg.configFile."trippy/trippy.toml".source =
    tomlFormat.generate "trippy-config" trippyConfig;
}
