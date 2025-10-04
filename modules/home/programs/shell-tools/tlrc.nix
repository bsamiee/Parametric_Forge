# Title         : tlrc.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/tlrc.nix
# ----------------------------------------------------------------------------
# Official tldr client written in Rust

{ config, lib, pkgs, ... }:

let
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
    color = { rgb = [255, 66, 180] }  # #FF42B4 (magenta)
    background = "default"
    bold = true
    underline = false
    italic = false
    dim = false
    strikethrough = false

    [style.description]
    color = { rgb = [189, 147, 249] }  # #A072C6 (purple)
    background = "default"
    bold = false
    underline = false
    italic = false
    dim = false
    strikethrough = false

    [style.bullet]
    color = { rgb = [80, 250, 123] }  # #50FA7B (green)
    background = "default"
    bold = false
    underline = false
    italic = false
    dim = false
    strikethrough = false

    [style.example]
    color = { rgb = [164, 255, 255] }  # #a4ffff (cyan)
    background = "default"
    bold = false
    underline = false
    italic = false
    dim = false
    strikethrough = false

    [style.url]
    color = { rgb = [234, 195, 148] }  # #EAC394 (orange)
    background = "default"
    bold = false
    underline = false
    italic = true
    dim = false
    strikethrough = false

    [style.inline_code]
    color = { rgb = [241, 250, 140] }  # #F1FA8C (yellow)
    background = "default"
    bold = false
    underline = false
    italic = true
    dim = false
    strikethrough = false

    [style.placeholder]
    color = { rgb = [255, 85, 85] }  # #FF5555 (red)
    background = "default"
    bold = false
    underline = false
    italic = true
    dim = false
    strikethrough = false
  '';
in
{
  home.packages = [ pkgs.tlrc ];
  xdg.configFile."tlrc/config.toml".text = tlrcConfig;
}
