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
  inherit (config.estate.theme) palette;
  toml = pkgs.formats.toml {};
  rgb = c: {rgb = [c.r c.g c.b];};
  # Rows differ from tlrc's defaults (`tldr --gen-config`). A style table that names a color starts from the plain style, so the weight and
  # slant tlrc gives that element by default are restated beside the color.
  configToml = toml.generate "tlrc-config.toml" {
    cache = {
      dir = "${config.xdg.cacheHome}/tlrc";
      languages = ["en"];
    };
    output = {
      show_hyphens = true;
      compact = true;
    };
    style = {
      title = {
        color = rgb palette.magenta;
        bold = true;
      };
      description.color = rgb palette.purple;
      bullet.color = rgb palette.green;
      example.color = rgb palette.cyan;
      url = {
        color = rgb palette.orange;
        italic = true;
      };
      inline_code = {
        color = rgb palette.yellow;
        italic = true;
      };
      placeholder = {
        color = rgb palette.red;
        italic = true;
      };
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
