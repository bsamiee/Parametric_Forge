# Title         : tlrc.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/tlrc.nix
# ----------------------------------------------------------------------------
# Official tldr client written in Rust. Config is generator-owned and lands where tlrc resolves it per OS:
# ~/Library/Application Support on macOS (the XDG path is never consulted there), $XDG_CONFIG_HOME on Linux.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette;
  toml = pkgs.formats.toml {};
  rgb = c: {rgb = [c.r c.g c.b];};
  style = color: extra:
    {
      inherit color;
      background = "default";
      bold = false;
      underline = false;
      italic = false;
      dim = false;
      strikethrough = false;
    }
    // extra;
  configToml = toml.generate "tlrc-config.toml" {
    cache = {
      dir = "${config.xdg.cacheHome}/tlrc";
      mirror = "https://github.com/tldr-pages/tldr/releases/latest/download";
      auto_update = true;
      max_age = 336;
      languages = ["en"];
    };
    output = {
      show_title = true;
      platform_title = false;
      show_hyphens = true;
      example_prefix = "- ";
      compact = true;
      raw_markdown = false;
    };
    indent = {
      title = 2;
      description = 2;
      bullet = 2;
      example = 4;
    };
    style = {
      title = style (rgb palette.magenta) {bold = true;};
      description = style (rgb palette.purple) {};
      bullet = style (rgb palette.green) {};
      example = style (rgb palette.cyan) {};
      url = style (rgb palette.orange) {italic = true;};
      inline_code = style (rgb palette.yellow) {italic = true;};
      placeholder = style (rgb palette.red) {italic = true;};
    };
  };
in {
  home.packages = [pkgs.tlrc];

  home.file = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    "Library/Application Support/tlrc/config.toml".source = configToml;
  };
  xdg.configFile = lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
    "tlrc/config.toml".source = configToml;
  };
}
