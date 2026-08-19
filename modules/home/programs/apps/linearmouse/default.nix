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
# number moves only with a compensating move in the other. Both scroll axes ride the smoothed engine, which emits
# continuous synthetic deltas at 120 Hz in place of quantized line-steps. An enabled smoothed axis puts the Logitech
# hi-res normalizer in passthrough and the transformer restores detent-scale input itself — 36pt per wheel detent, ~11pt
# per thumbwheel notch — so highResolutionWheel stays on, and the axis owns its preset, response, speed, acceleration,
# and inertia while ignoring scrolling.acceleration outright. Travel per event follows desiredVelocity = magnitude *
# velocityScale * (0.85 + 0.4*speed) * (1 + acceleration*accelerationGain), integrated over a blend that rises with
# preset response plus response — travel is exactly linear in that speed term, so one factor moves both axes together.
# Vertical pairs easeIn's velocityScale 24 with response 0 for the softest ramp the mode offers, 46pt per detent at
# speed 0.9; the same row at speed 0 is the density floor of the whole engine, 32pt. Horizontal takes the smooth preset
# for its 0.93 decay — the longest carry — at speed 6.5 for 65pt per notch, and past the speed ceiling of 8 the only
# remaining density lever is acceleration against the preset's 0.06 gain. bouncing false keeps synthetic momentum while
# dropping the app rubber-band phases. Viewport apps break the smoothed contract: Rhino applies its zoom scale factor per
# scroll event instead of integrating deltas, so the 120 Hz synthetic stream turns one detent into dozens of zoom steps
# and a free-spin flick into hundreds. The Rhino row ANDs app bundle with the MX device (one if-object is a conjunction;
# an array would be a disjunction, and app-only scope would drag the trackpad in) and disables both smoothed axes, which
# takes the hi-res normalizer out of passthrough so micro-ticks re-coalesce to detent-scale discrete events; vertical
# distance 1 then makes a detent exactly one line — one zoom step at Rhino's own zoom scale factor. launchd owns login
# start.
{pkgs, ...}: let
  settings = {
    "$schema" = "https://schema.linearmouse.app/0.11.4-beta.5";
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
        scrolling.smoothed = {
          vertical = {
            enabled = true;
            preset = "easeIn";
            response = 0;
            speed = 0.9;
            acceleration = 0;
            inertia = 0;
            bouncing = false;
          };
          horizontal = {
            enabled = true;
            preset = "smooth";
            response = 0.15;
            speed = 6.5;
            acceleration = 0;
            inertia = 0;
            bouncing = false;
          };
        };
      }
      {
        "if" = {
          app = "com.mcneel.rhinoceros.9";
          device = {
            vendorID = "0x046d";
            productID = "0xb034";
          };
        };
        scrolling = {
          distance.vertical = 1;
          smoothed = {
            vertical.enabled = false;
            horizontal.enabled = false;
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
