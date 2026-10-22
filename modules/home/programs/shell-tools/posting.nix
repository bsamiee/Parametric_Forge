# Title         : posting.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/posting.nix
# ----------------------------------------------------------------------------
# Terminal API workspace with versionable request collections. Theme is projected from the palette and roles of modules/home/theme.nix;
# request collections stay mutable user state.
{config, ...}: let
  inherit (config.forge.theme) palette roles;

  # User themes load from $XDG_DATA_HOME/posting/themes and request variables come from explicit --env files alone, both posting's defaults.
  postingConfig = {
    theme = "forge";
    watch_themes = false;
  };

  postingTheme = {
    name = "forge";
    primary = roles.accent.primary.hex;
    secondary = roles.accent.structural.hex;
    accent = roles.accent.secondary.hex;
    background = roles.surface.base.hex;
    surface = roles.surface.raised.hex;
    error = roles.state.danger.hex;
    success = roles.state.success.hex;
    warning = roles.state.warning.hex;
    url = {
      base = palette.cyan.hex;
      protocol = palette.magenta.hex;
    };
    syntax = {
      json_key = palette.green.hex;
      json_string = palette.yellow.hex;
      json_number = palette.purple.hex;
      json_boolean = palette.magenta.hex;
      json_null = palette.comment.hex;
    };
    # HTTP-verb semantics: read=success green, create=accent cyan, mutate=attention orange (patch=warning yellow), destroy=danger red,
    # introspection (options/head)=structural purple / muted comment.
    method = {
      get = palette.green.hex;
      post = palette.cyan.hex;
      put = palette.orange.hex;
      patch = palette.yellow.hex;
      delete = palette.red.hex;
      options = palette.purple.hex;
      head = palette.comment.hex;
    };
    # Rich style strings; mirrors the tmTheme editor surface (caret=primary, line highlight=raised, selection=selected).
    text_area = {
      gutter = roles.text.muted.hex;
      cursor = "${roles.text.inverse.hex} on ${roles.text.primary.hex}";
      cursor_line = "on ${roles.surface.raised.hex}";
      cursor_line_gutter = "${roles.text.muted.hex} on ${roles.surface.raised.hex}";
      matched_bracket = "on ${roles.surface.selected.hex}";
      selection = "on ${roles.surface.selected.hex}";
    };
  };
in {
  programs.posting = {
    enable = true;
    settings = postingConfig;
    themes.forge = postingTheme;
  };
}
