# Title         : 01.home/darwin/services/sketchybar.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/darwin/services/sketchybar.nix
# ----------------------------------------------------------------------------
# SketchyBar launchd service with proper startup sequencing

{
  config,
  pkgs,
  userServiceHelpers,
  ...
}:

{
  launchd.agents.sketchybar = {
    enable = true;
    config = userServiceHelpers.mkLaunchdAgent {
      command = "${pkgs.sketchybar}/bin/sketchybar";
      arguments = [ "--config" "${config.xdg.configHome}/sketchybar/sketchybarrc" ];
      runAtLoad = true;
      keepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      processType = "Interactive";
      ThrottleInterval = 30;
      environmentVariables = {
        PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";
        XDG_CONFIG_HOME = config.xdg.configHome;
        HOME = config.home.homeDirectory;
      };
    };
  };
}