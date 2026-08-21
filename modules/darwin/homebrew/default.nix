# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/default.nix
# ----------------------------------------------------------------------------
# Homebrew configuration and aggregator
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
  receiptsFold = import ../../common/receipts.nix;
  brewMaintenance = pkgs.writeShellApplication {
    name = "forge-brew-maintenance";
    runtimeInputs = [pkgs.coreutils pkgs.jq];
    text = ''
      # Each Homebrew child starts from an explicit environment because the GUI launchd domain carries interactive-session state.
      brew_env=(
        /usr/bin/env -i
        HOME="/Users/${config.system.primaryUser}"
        USER="${config.system.primaryUser}"
        LOGNAME="${config.system.primaryUser}"
        XDG_CONFIG_HOME="/Users/${config.system.primaryUser}/.config"
        PATH="${config.homebrew.prefix}/bin:${config.homebrew.prefix}/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
        HOMEBREW_CLEANUP_MAX_AGE_DAYS=3
        HOMEBREW_NO_ANALYTICS=1
        HOMEBREW_NO_AUTO_UPDATE=1
        HOMEBREW_NO_EMOJI=1
        HOMEBREW_NO_ENV_HINTS=1
        HOMEBREW_NO_INSTALL_CLEANUP=1
      )
      brew="${config.homebrew.prefix}/bin/brew"
      action=maintain
      receipt_log="/Users/${config.system.primaryUser}/Library/Logs/forge-brew-maintenance.receipts.log"
      receipt_surface="forge-brew-maintenance"
      ${receiptsFold}

      emit_receipt() {
        rc=$?
        trap - EXIT
        status=ok
        ((rc == 0)) || status=fail
        TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
        append_receipt "$(printf 'ts=%s\towner=%s\tderived_path=%s\taction=%s\tstatus=%s\tproof=%s\tresult=%s' \
          "$ts" "nix-darwin.homebrew" "$brew" "$action" "$status" "brew-exit-$rc" "$status")" \
          || printf 'forge-brew-maintenance: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
        exit "$rc"
      }
      trap emit_receipt EXIT

      if (( $# == 1 )) && [[ $1 == "--wezterm-nightly" ]]; then
        action=upgrade-wezterm-nightly
        "''${brew_env[@]}" "$brew" upgrade --cask wezterm@nightly --greedy-latest --no-ask --no-quit
        exit 0
      fi
      if (( $# != 0 )); then
        action=reject-invalid-arguments
        printf 'usage: forge-brew-maintenance [--wezterm-nightly]\n' >&2
        exit 2
      fi

      "''${brew_env[@]}" "$brew" update
      "''${brew_env[@]}" "$brew" upgrade --formula --no-ask
      "''${brew_env[@]}" "$brew" upgrade --cask --no-ask --no-quit
      "''${brew_env[@]}" "$brew" autoremove
      "''${brew_env[@]}" "$brew" cleanup
    '';
  };
in {
  imports = [
    ./brews.nix
    ./casks.nix
  ];

  homebrew = {
    enable = mkDefault true;

    # --- [MAC_APP_STORE]
    masApps = {
      Drafts = 1435957248;
    };

    # --- [GLOBAL_SETTINGS]
    global = {
      autoUpdate = mkDefault true; # Manual brew ops refresh tap metadata natively
      brewfile = mkDefault false; # Brewfile managed via Nix, not brew
    };

    # --- [ACTIVATION_BEHAVIOR]
    # Activation installs missing roster rows without coupling a system switch to application upgrades or operator-owned removals.
    onActivation = {
      autoUpdate = mkDefault true;
      cleanup = mkDefault "none";
      upgrade = mkDefault false;
      extraEnv = {
        HOMEBREW_NO_ANALYTICS = mkDefault "1";
        HOMEBREW_NO_ENV_HINTS = mkDefault "1";
      };
    };
  };

  # Native Homebrew commands own the daily lifecycle; nix-darwin's Brewfile remains the sole roster installer.
  launchd.user.agents.forge-brew-maintenance = {
    serviceConfig = {
      Label = "com.parametric-forge.forge-brew-maintenance";
      ProgramArguments = ["${brewMaintenance}/bin/forge-brew-maintenance"];
      RunAtLoad = false;
      StartCalendarInterval = [
        {
          Hour = 10;
          Minute = 0;
        }
      ];
      ProcessType = "Background";
      StandardOutPath = "/Users/${config.system.primaryUser}/Library/Logs/forge-brew-maintenance.log";
      StandardErrorPath = "/Users/${config.system.primaryUser}/Library/Logs/forge-brew-maintenance.log";
    };
  };

  # WezTerm nightly needs its own greedy-latest pass; blanket greedy upgrades would also board every self-updating cask.
  launchd.user.agents.forge-wezterm-nightly = {
    serviceConfig = {
      Label = "com.parametric-forge.forge-wezterm-nightly";
      ProgramArguments = ["${brewMaintenance}/bin/forge-brew-maintenance" "--wezterm-nightly"];
      RunAtLoad = false;
      StartCalendarInterval = [
        {
          Hour = 10;
          Minute = 30;
        }
      ];
      ProcessType = "Background";
      StandardOutPath = "/Users/${config.system.primaryUser}/Library/Logs/forge-wezterm-nightly.log";
      StandardErrorPath = "/Users/${config.system.primaryUser}/Library/Logs/forge-wezterm-nightly.log";
    };
  };
}
