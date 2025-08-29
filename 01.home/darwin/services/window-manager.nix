{ myLib, ... }:

{
  launchd.agents = {
    yabai = {
      enable = true;
      config = myLib.launchd.mkUserAgent {
        command = "/opt/homebrew/bin/yabai";
        label = "Yabai";
        runAtLoad = true;
        keepAlive = true;
      };
    };

    skhd = {
      enable = true;
      config = myLib.launchd.mkUserAgent {
        command = "/opt/homebrew/bin/skhd";
        label = "SKHD";
        runAtLoad = true;
        keepAlive = true;
      };
    };

    sketchybar = {
      enable = true;
      config = myLib.launchd.mkUserAgent {
        command = "/opt/homebrew/bin/sketchybar";
        label = "SketchyBar";
        runAtLoad = true;
        keepAlive = true;
      };
    };
  };
}