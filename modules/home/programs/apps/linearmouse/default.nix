# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/linearmouse/default.nix
# ----------------------------------------------------------------------------
# LinearMouse owner: settings rows render to the XDG config the app hot-reloads, proven against the vendored upstream
# JSON Schema at build time — an invalid row fails the switch, never lands on disk. Schemes scope to external mice only,
# so the trackpad keeps native behavior. Generic mouse row: flat acceleration with speed on the 0-1 rail, side buttons
# lifted to universal back/forward. MX Master 3S row (Bluetooth 0x046d:0xb034): MagSpeed emits native high-resolution
# wheel deltas under highResolutionWheel, and the scheme carries NO smoothed row — any smoothed key, even
# enabled=false, flips the hi-res normalizer to passthrough and one detent scrolls a page; absent smoothed + auto
# distance selects lowResolution normalization, the correct-magnitude path. scrolling.acceleration multiplies every
# event delta (1 = native), the thumbwheel's horizontal lane rides it. hardwareDPI pins the on-device MX factory
# default so the tuned pointer.speed feel stays put; raising it demands a proportional speed cut. launchd agent owns
# start-at-login; the app's SMAppService toggle stays untouched.
{pkgs, ...}: let
  settings = {
    "$schema" = "https://schema.linearmouse.app/0.11.4-beta.3";
    schemes = [
      {
        "if".device.category = "mouse";
        pointer = {
          acceleration = 0;
          speed = 0.25;
        };
        buttons.universalBackForward = true;
      }
      {
        "if".device = {
          vendorID = "0x046d";
          productID = "0xb034";
        };
        logitech.highResolutionWheel = true;
        pointer.hardwareDPI = 1000;
        scrolling.acceleration.horizontal = 3;
      }
    ];
  };

  rendered = pkgs.writeText "linearmouse-settings.json" (builtins.toJSON settings);
  validated =
    pkgs.runCommand "linearmouse.json" {
      nativeBuildInputs = [pkgs.check-jsonschema];
    } ''
      check-jsonschema --schemafile ${./schema.json} ${rendered}
      install -m444 ${rendered} $out
    '';
in {
  xdg.configFile."linearmouse/linearmouse.json".source = validated;

  launchd.agents.linearmouse = {
    enable = true;
    config = {
      Label = "com.parametric-forge.linearmouse";
      ProgramArguments = ["/Applications/LinearMouse.app/Contents/MacOS/LinearMouse"];
      RunAtLoad = true;
      ProcessType = "Interactive";
      LimitLoadToSessionType = "Aqua";
    };
  };
}
