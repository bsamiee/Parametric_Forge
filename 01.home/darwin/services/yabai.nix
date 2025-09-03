# Title         : 01.home/darwin/services/yabai.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge  
# License       : MIT
# Path          : /01.home/darwin/services/yabai.nix
# ----------------------------------------------------------------------------
# Yabai window manager launchd service

{
  config,
  pkgs,
  userServiceHelpers,
  ...
}:

{
  launchd.agents.yabai = {
    enable = true;
    config = userServiceHelpers.mkLaunchdAgent {
      command = "${config.xdg.configHome}/yabai/yabairc";
      runAtLoad = true;
      keepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      processType = "Interactive";
      ThrottleInterval = 30;
      StartInterval = 300;
      environmentVariables = {
        PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        XDG_CONFIG_HOME = config.xdg.configHome;
        HOME = config.home.homeDirectory;
        SHELL = "${pkgs.zsh}/bin/zsh";
      };
    };
  };
}