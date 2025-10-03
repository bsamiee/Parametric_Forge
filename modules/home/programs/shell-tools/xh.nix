# Title         : xh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/xh.nix
# ----------------------------------------------------------------------------
# Friendly and fast HTTP client (HTTPie reimplementation in Rust)

{ config, lib, pkgs, ... }:

let
  jsonFormat = pkgs.formats.json { };

  xhConfig = {
    default_options = [
      "--style=fruity"       # Dark theme (Dracula-adjacent)
      "--print=hbH"          # Headers, body, request Headers
      "--follow"             # Follow redirects by default
      "--timeout=30"         # 30 second timeout
    ];
  };
in
{
  home.packages = [ pkgs.xh ];
  xdg.configFile."xh/config.json".source = jsonFormat.generate "xh-config" xhConfig;
}
