# Title         : sketchybar-daemon.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/darwin/services/sketchybar-daemon.nix
# ----------------------------------------------------------------------------
# SketchyBar ecosystem LaunchD services for enhanced macOS status bar.

{
  lib,
  pkgs,
  context,
  userServiceHelpers,
  config,
  ...
}:

let
  # --- Service Helper Functions ---------------------------------------------
  inherit (userServiceHelpers) mkResilientService;

  # --- Dracula Color Scheme -------------------------------------------------
  draculaColors = {
    active = "0xffbd93f9";    # Purple (matches bordersrc)
    inactive = "0xff6272a4";  # Comment
    width = "4.0";
  };

in

lib.mkIf context.isDarwin {
  # --- SketchyBar System Stats Provider ------------------------------------
  launchd.agents."org.nixos.sketchybar-system-stats" = {
    enable = true;
    config = mkResilientService pkgs {
      command = "${pkgs.sketchybar-system-stats}/bin/sketchybar-system-stats";
      arguments = [
        "--cpu" "usage"
        "--memory" "ram_usage"
        "--disk" "usage"
        "--interval" "2"
      ];
      environmentVariables = {
        PATH = "/opt/homebrew/bin:/run/current-system/sw/bin:/usr/bin:/bin";
        HOME = config.home.homeDirectory;
      };
      workingDirectory = config.home.homeDirectory;
      logBaseName = "${config.xdg.stateHome}/logs/sketchybar-system-stats";
      runAtLoad = true;
      nice = 5; # Higher priority for system stats
      processType = "Background";
      # Wait for SketchyBar to be running
      keepAlive = {
        SuccessfulExit = false;
        Crashed = true;
      };
      ThrottleInterval = 5;
      ExitTimeOut = 10;
    };
  };

  # --- JankyBorders Window Border Service ----------------------------------
  launchd.agents."org.nixos.jankyborders" = {
    enable = true;
    config = mkResilientService pkgs {
      command = "/opt/homebrew/bin/borders";
      arguments = [
        "active_color=${draculaColors.active}"
        "inactive_color=${draculaColors.inactive}"
        "width=${draculaColors.width}"
      ];
      environmentVariables = {
        PATH = "/opt/homebrew/bin:/run/current-system/sw/bin:/usr/bin:/bin";
        HOME = config.home.homeDirectory;
      };
      workingDirectory = config.home.homeDirectory;
      logBaseName = "${config.xdg.stateHome}/logs/jankyborders";
      runAtLoad = true;
      nice = 10; # Lower priority than system stats
      processType = "Background";
      # Resilient restart configuration
      keepAlive = {
        SuccessfulExit = false;
        Crashed = true;
      };
      ThrottleInterval = 10;
      ExitTimeOut = 15;
    };
  };

}