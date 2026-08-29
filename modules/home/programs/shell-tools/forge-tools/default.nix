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

  launchd.agents = {
    # Weekly off-peak cadence; the shared flock serializes against deploys.
    forge-nix-maintenance = tl.mkAgent "forge-nix-maintenance" {
      StartCalendarInterval = [
        {
          Weekday = 6;
          Hour = 12;
          Minute = 0;
        }
      ];
    } ["${deploy.forgeNixMaintenance}/bin/forge-nix-maintenance" "--scheduled"];

    # Daily pre-dawn Homebrew pass (the WezTerm nightly is a nightly); Darwin-only because Homebrew is, and AC-gated like every scheduled leg.
    forge-brew-maintenance = lib.mkIf (host.os == "darwin") (tl.mkAgent "forge-brew-maintenance" {
      StartCalendarInterval = [
        {
          Hour = 5;
          Minute = 30;
        }
      ];
    } ["${brew.forgeBrewMaintenance}/bin/forge-brew-maintenance" "--scheduled"]);

    # Hourly orphan sweep (calendar trigger for wake coalescing): evidence-gated reaping of agent-lane litter — ppid-1 tty-less orphans only;
    # kill classes are allowlisted rows, everything ambiguous stays receipt-only.
    forge-orphan-sweep = tl.mkAgent "forge-orphan-sweep" {StartCalendarInterval = [{Minute = 0;}];} ["${cleanup.forgeCleanup}/bin/forge-cleanup" "sweep"];
  };
}
