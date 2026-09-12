# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/forge-tools/default.nix
# ----------------------------------------------------------------------------
# Agent-safe Forge maintenance entrypoints: deploy rail, Homebrew pass, cleanup board, the machine doctor, acceptance choreography, and their
# scheduled agents.
{
  config,
  forgeAgent,
  host,
  lib,
  pkgs,
  ...
}: let
  tl = import ./lib.nix {inherit config lib pkgs;};
  deploy = import ./deploy.nix {inherit lib pkgs tl;};
  brew = import ./brew.nix {inherit pkgs tl;};
  cleanup = import ./cleanup.nix {inherit config lib pkgs tl;};
  doctor = import ./doctor.nix {inherit lib pkgs tl;};
  accept = import ./accept.nix {
    inherit pkgs tl;
    inherit (deploy) forgeActivationSweep forgeRedeploy;
    inherit (doctor) forgeDoctor;
  };
in {
  home.packages =
    [
      deploy.forgeRedeploy
      deploy.forgeNixMaintenance
      deploy.forgeActivationSweep
      cleanup.forgeCleanup
      doctor.forgeDoctor
      doctor.doctorCompletion
      accept.forgeAccept
    ]
    ++ lib.optional (host.os == "darwin") brew.forgeBrewMaintenance;

  # LaunchAgents stays operator-private; declared here (was a runtime chmod row) so the mode converges with every activation.
  home.activation.launchAgentsMode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    [ ! -d "$HOME/Library/LaunchAgents" ] || run chmod 700 "$HOME/Library/LaunchAgents"
  '';

  # Shared identity bundle for the scheduled agents (bundle-apps.nix): Login Items & Extensions shows one "Forge Nix Automation" row — one toggle
  # governs store maintenance, the Homebrew pass, and the orphan sweep.
  forge.bundleApps.forge-nix-automation = "Forge Nix Automation";

  # Every scheduled row shares the automation bundle identity; schedule and argv are the only per-row facts.
  launchd.agents = let
    scheduled = name: argv: schedule:
      forgeAgent {
        inherit name argv;
        bundle = "forge-nix-automation";
        StartCalendarInterval = schedule;
      };
  in {
    # Weekly off-peak cadence; the shared flock serializes against deploys.
    forge-nix-maintenance = scheduled "forge-nix-maintenance" ["${deploy.forgeNixMaintenance}/bin/forge-nix-maintenance" "--scheduled"] [
      {
        Weekday = 6;
        Hour = 12;
        Minute = 0;
      }
    ];

    # Daily pre-dawn Homebrew pass (the WezTerm nightly is a nightly); Darwin-only because Homebrew is, and AC-gated like every scheduled leg.
    forge-brew-maintenance = lib.mkIf (host.os == "darwin") (scheduled "forge-brew-maintenance" ["${brew.forgeBrewMaintenance}/bin/forge-brew-maintenance" "--scheduled"] [
      {
        Hour = 5;
        Minute = 30;
      }
    ]);

    # Hourly orphan sweep (calendar trigger for wake coalescing): evidence-gated reaping of agent-lane litter — ppid-1 tty-less orphans only;
    # kill classes are allowlisted rows, everything ambiguous stays receipt-only.
    forge-orphan-sweep = scheduled "forge-orphan-sweep" ["${cleanup.forgeCleanup}/bin/forge-cleanup" "sweep"] [{Minute = 0;}];
  };
}
