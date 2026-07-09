# Title         : posting.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/posting.nix
# ----------------------------------------------------------------------------
# Terminal API workspace with versionable request collections; the package row
# lives in the owner table. Theme is projected from the estate palette owner;
# collections stay mutable user state under project or XDG data directories.
{
  config,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette roles;
  yamlFormat = pkgs.formats.yaml {};

  postingConfig = {
    theme = "forge";
    load_user_themes = true;
    watch_themes = false;
    theme_directory = "${config.xdg.dataHome}/posting/themes";
    use_host_environment = false; # request variables come from explicit --env files only
  };

  forgeTheme = {
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
    # HTTP-verb semantics: read=success green, create=accent cyan,
    # mutate=attention orange (patch=warning yellow), destroy=danger red,
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
    # Rich style strings; mirrors the tmTheme editor surface (caret=primary,
    # line highlight=raised, selection=selected).
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
  xdg.configFile."posting/config.yaml".source = yamlFormat.generate "posting-config" postingConfig;
  xdg.dataFile."posting/themes/forge.yaml".source = yamlFormat.generate "posting-forge-theme" forgeTheme;
}
