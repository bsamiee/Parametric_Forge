# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/linearmouse/default.nix
# ----------------------------------------------------------------------------
# LinearMouse owner: settings rows render to the XDG config the app hot-reloads, proven against the vendored upstream
# JSON Schema at build time; an invalid row fails the switch and never lands on disk. Schemes scope to external mice only,
# so the trackpad keeps native behavior. Generic mouse row: flat acceleration with speed on the 0-1 rail, side buttons
# lifted to universal back/forward. MX Master 3S row (Bluetooth 0x046d:0xb034): MagSpeed emits native high-resolution
# wheel deltas under highResolutionWheel; both axes ride the Linear smoothed curve. High response removes input lag, zero
# adaptive gain prevents amplified flicks, and zero inertia selects the shortest Linear tail. Per-click travel scales with
# the engine's speedBoost = 0.85 + 0.4*speed, so vertical speed 0 is the density floor (~7% under the prior 0.15) — presets
# are travel-equalized (lower velocityScale pairs with longer decay), so no preset swap cuts density further without
# changing feel. Horizontal rides above the floor: the MX thumbwheel under-travels at the minimum boost. Smoothed axes
# own their speed, acceleration, and inertia; plain scrolling acceleration never reaches them. The hi-res normalizer passes
# smoothed axes through, then the transformer restores detent-scale input from device units and the Logitech multiplier.
# bouncing=false keeps synthetic momentum but omits app rubber-band phases. hardwareDPI pins the on-device MX factory
# default so the tuned pointer.speed feel stays put; raising it demands a proportional speed cut. launchd owns login start.
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
        scrolling.smoothed = {
          vertical = {
            enabled = true;
            preset = "linear";
            response = 1.6;
            speed = 0;
            acceleration = 0;
            inertia = 0;
            bouncing = false;
          };
          horizontal = {
            enabled = true;
            preset = "linear";
            response = 2.0;
            speed = 0.5;
            acceleration = 0;
            inertia = 0;
            bouncing = false;
          };
        };
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
      ProgramArguments = ["/usr/bin/open" "-gj" "/Applications/LinearMouse.app"];
      RunAtLoad = true;
      ProcessType = "Interactive";
      LimitLoadToSessionType = "Aqua";
    };
  };
}
