# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/linearmouse/default.nix
# ----------------------------------------------------------------------------
# LinearMouse owner: settings rows render to the XDG config the app hot-reloads, proven against the vendored upstream
# JSON Schema at build time; an invalid row fails the switch and never lands on disk. Schemes scope to external mice only,
# so the trackpad keeps native behavior. Generic mouse row: flat acceleration with speed on the 0-1 rail, side buttons
# lifted to universal back/forward. MX Master 3S row (Bluetooth 0x046d:0xb034): both axes ride the Accelerated lane —
# smoothed absent selects it, distance stays auto (the only normalizing mode), and the hi-res normalizer re-quantizes
# MagSpeed device units to line-steps (deltaYPt = 10pt each; one slow detent = one step, 1/3 of a native detent), keeping
# the OS velocity curve via max(raw units, accelerated CG magnitude). scrolling.acceleration multiplies every delta field;
# integer deltaY floors at max(round(A),1). scrolling.speed stays 0 — an additive pt-per-tick lane, wrong knob for rate.
# Calibration against the retired smoothed floor (60.7pt/detent vertical at response 1.6, 14.2pt/line horizontal at
# speed 0.5): vertical 4.5 = 45pt/detent (-26%), horizontal 1.8 = 18pt/line (+27%). An explicit line/px distance flips
# the normalizer to passthrough and leaks raw multiplied hi-res deltas — never set it on this row. hardwareDPI pins the
# on-device MX factory default so the tuned pointer.speed feel stays put; raising it demands a proportional speed cut.
# launchd owns login start.
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
        scrolling.acceleration = {
          vertical = 4.5;
          horizontal = 1.8;
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
