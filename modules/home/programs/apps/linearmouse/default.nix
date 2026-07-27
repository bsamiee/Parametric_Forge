# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/linearmouse/default.nix
# ----------------------------------------------------------------------------
# LinearMouse owner: settings rows render to the XDG config the app hot-reloads, proven against the vendored upstream
# JSON Schema at build time; an invalid row fails the switch and never lands on disk. Schemes scope to external mice only,
# so the trackpad keeps native behavior, and a later row overrides an earlier one at match time. Generic mouse row lifts
# the side buttons to universal back/forward and sets pointer.acceleration 0, which collapses the macOS accel table to its
# identity curve: pointer gain is a constant 96/HIDPointerResolution points per count, free of velocity dependence, where
# pointer.speed drives HIDPointerResolution = 1/(1/1200 + speed*(1/40 - 1/1200)). Screen travel per inch is
# hardwareDPI * 96 / HIDPointerResolution, so the MX Master 3S row (Bluetooth 0x046d:0xb034) carries its own speed pinned
# to its own DPI — 3200 DPI at speed 0.0544 holds 660 pt/inch while cutting the per-count quantum to 0.21 pt, and either
# number moves only with a compensating move in the other. Both scroll axes ride the Accelerated lane — smoothed absent
# selects it, distance stays auto (the only normalizing mode), and the hi-res normalizer re-quantizes MagSpeed device
# units to detent-scale line-steps while keeping the OS velocity curve. scrolling.acceleration multiplies every delta
# field per axis: vertical 1.5 travels 15pt per slow detent, horizontal 2.5 travels 25pt per thumbwheel line-event, and
# the legacy integer line field rounds each to 2 and 3. An explicit line/px distance flips the normalizer to passthrough
# and leaks raw multiplied hi-res deltas — never set it on this row. launchd owns login start.
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
        pointer = {
          hardwareDPI = 3200;
          speed = 0.0544;
        };
        scrolling.acceleration = {
          vertical = 1.5;
          horizontal = 2.5;
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
