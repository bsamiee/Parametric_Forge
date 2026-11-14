{
  lib,
  theme,
  ...
}: let
  inherit (theme) roles palette;

  trippyConfig = {
    # --- [TRIPPY]
    trippy.unprivileged = true;

    # --- [STRATEGY]
    strategy.addr-family = "system";

    # --- [THEME_COLORS]
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
  programs.trippy = {
    enable = true;
    forceUserConfig = false;
    settings = trippyConfig;
  };
}
