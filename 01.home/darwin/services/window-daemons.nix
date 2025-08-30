# Title         : 01.home/darwin/services/window-daemons.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/darwin/services/window-daemons.nix
# ----------------------------------------------------------------------------
# Window management daemon services for macOS.

{ pkgs, myLib, ... }:

{
  launchd.agents = {
    yabai = {
      enable = true;
      config = myLib.launchd.mkLaunchdAgent pkgs {
        command = "/opt/homebrew/bin/yabai";
        label = "Yabai";
        runAtLoad = true;
        keepAlive = true;
      };
    };

    skhd = {
      enable = true;
      config = myLib.launchd.mkLaunchdAgent pkgs {
        command = "/opt/homebrew/bin/skhd";
        label = "SKHD";
        runAtLoad = true;
        keepAlive = true;
      };
    };

    sketchybar = {
      enable = true;
      config = myLib.launchd.mkLaunchdAgent pkgs {
        command = "/opt/homebrew/bin/sketchybar";
        label = "SketchyBar";
        runAtLoad = true;
        keepAlive = true;
      };
    };
  };
}
