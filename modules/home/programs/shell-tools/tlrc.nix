# Title         : tlrc.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/tlrc.nix
# ----------------------------------------------------------------------------
# Official tldr client written in Rust
{
  config,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette;
  rgb = c: "{ rgb = [${toString c.r}, ${toString c.g}, ${toString c.b}] }";
  tlrcConfig = ''
    [cache]
    # XDG-compliant cache directory (overrides macOS default)
    dir = "${config.xdg.cacheHome}/tlrc"
    mirror = "https://github.com/tldr-pages/tldr/releases/latest/download"
    auto_update = true
    max_age = 336
    languages = ["en"]  # English only (faster lookups)

    [output]
    show_title = true
    platform_title = false
    show_hyphens = true
    example_prefix = "- "
    compact = true
    raw_markdown = false

    [indent]
    title = 2
    description = 2
    bullet = 2
    example = 4

    [style.title]
    color = ${rgb palette.magenta}
    background = "default"
    bold = true
    underline = false
    italic = false
    dim = false
    strikethrough = false

    [style.description]
    color = ${rgb palette.purple}
    background = "default"
    bold = false
    underline = false
    italic = false
    dim = false
    strikethrough = false

    [style.bullet]
    color = ${rgb palette.green}
    background = "default"
    bold = false
    underline = false
    italic = false
    dim = false
    strikethrough = false

    [style.example]
    color = ${rgb palette.cyan}
    background = "default"
    bold = false
    underline = false
    italic = false
    dim = false
    strikethrough = false

    [style.url]
    color = ${rgb palette.orange}
    background = "default"
    bold = false
    underline = false
    italic = true
    dim = false
    strikethrough = false

    [style.inline_code]
    color = ${rgb palette.yellow}
    background = "default"
    bold = false
    underline = false
    italic = true
    dim = false
    strikethrough = false

    [style.placeholder]
    color = ${rgb palette.red}
    background = "default"
    bold = false
    underline = false
    italic = true
    dim = false
    strikethrough = false
  '';
in {
  home.packages = [pkgs.tlrc];
  xdg.configFile."tlrc/config.toml".text = tlrcConfig;
}
