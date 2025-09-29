# Title         : xh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/xh.nix
# ----------------------------------------------------------------------------
# Friendly and fast HTTP client (HTTPie reimplementation in Rust)

{ config, lib, pkgs, ... }:

# Dracula theme color reference
# background    #15131F
# current_line  #2A2640
# selection     #44475a
# foreground    #F8F8F2
# comment       #7A71AA
# purple        #A072C6
# cyan          #94F2E8
# green         #50FA7B
# yellow        #F1FA8C
# orange        #F97359
# red           #ff5555
# magenta       #d82f94
# pink          #E98FBE

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
