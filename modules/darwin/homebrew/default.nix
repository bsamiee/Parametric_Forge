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
  inherit (lib) concatStringsSep mkDefault;
  activationPath = concatStringsSep ":" [
    "/etc/profiles/per-user/${config.system.primaryUser}/bin"
    "/run/current-system/sw/bin"
    "${config.homebrew.prefix}/bin"
    "${pkgs.mas}/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];

  # --- [SCHEDULED_UPDATE_POLICY_DOMT4_AUTOUPDATE]
  # Daily update+upgrade+cleanup, keychain-backed sudo askpass (pinentry-mac), notifier off (TCC denies the notification permission). The reconciler
  # regenerates the tap-owned agent whenever live state drifts from this row, so the schedule is repo-declared, never hidden operator state.
  autoupdateIntervalSeconds = 86400;
  autoupdateStartArgs = "--upgrade --cleanup --sudo --immediate --no-notify";
  autoupdateReconcile = pkgs.writeShellApplication {
    name = "forge-brew-autoupdate-reconcile";
    runtimeInputs = [pkgs.gawk];
    text = ''
      plist="$HOME/Library/LaunchAgents/com.github.domt4.homebrew-autoupdate.plist"
      updater="$HOME/Library/Application Support/com.github.domt4.homebrew-autoupdate/brew_autoupdate"

      converged() {
        if [ ! -f "$plist" ] || [ ! -x "$updater" ]; then return 1; fi
        interval="$(/usr/libexec/PlistBuddy -c 'Print :StartInterval' "$plist" 2>/dev/null || true)"
        if [ "$interval" != "${toString autoupdateIntervalSeconds}" ]; then return 1; fi
        /usr/libexec/PlistBuddy -c 'Print :RunAtLoad' "$plist" >/dev/null 2>&1 || return 1
        # One pass proves every updater marker: six required, notifier absent.
        awk '
          /--no-ask --formula/ {formula = 1}
          /--no-ask --cask/ {cask = 1}
          /brew cleanup/ {cleanup = 1}
          /SUDO_ASKPASS/ {askpass = 1}
          /HOMEBREW_CASK_OPTS/ {caskopts = 1}
          /HOMEBREW_NO_ANALYTICS/ {analytics = 1}
          /notify\.sh .+ (always|error) / {notify = 1}
          END {exit !(formula && cask && cleanup && askpass && caskopts && analytics && !notify)}
        ' "$updater"
      }

      if converged; then exit 0; fi

      # Regenerate from a clean context: the tap embeds the invoking PATH, HOMEBREW_CASK_OPTS, and HOMEBREW_NO_ANALYTICS into the updater script.
      export PATH="${config.homebrew.prefix}/bin:${config.homebrew.prefix}/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
      export HOMEBREW_CASK_OPTS="--no-quarantine"
      export HOMEBREW_NO_ANALYTICS=1
      mkdir -p "$HOME/Library/LaunchAgents"
      brew autoupdate delete >/dev/null 2>&1 || true
      brew autoupdate start ${toString autoupdateIntervalSeconds} ${autoupdateStartArgs}
    '';
  };
in {
  imports = [
    ./taps.nix
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
    # Activation stays install/metadata only; version freshness is owned by the domt4/autoupdate agent under the reconciled schedule declared above.
    onActivation = {
      autoUpdate = mkDefault true;
      cleanup = mkDefault "none";
      upgrade = mkDefault false;
      extraEnv = {
        PATH = mkDefault activationPath;
        HOMEBREW_CASK_OPTS = mkDefault "--no-quarantine"; # Brew 6 dropped the --no-quarantine flag; env is the only carrier
      };
    };

    # --- [CASK_CONFIGURATION]
    caskArgs = mkDefault {
      appdir = "/Applications";
      require_sha = false;
      no_binaries = false;
      fontdir = "~/Library/Fonts";
      colorpickerdir = "~/Library/ColorPickers";
      prefpanedir = "~/Library/PreferencePanes";
      qlplugindir = "~/Library/QuickLook";
    };
  };

  # Reconcile at login and daily at 10:00; converged runs are read-only and exit 0, logged so a failed regeneration never hides until the next
  # day. The reconciled agent keeps its upstream tap label (com.github.domt4.homebrew-autoupdate) — external job, not ours to rename.
  # nix-darwin's strict launchd schema has no AssociatedBundleIdentifiers key, so this row shows a generic Login Items entry.
  launchd.user.agents.forge-brew-autoupdate = {
    serviceConfig = {
      Label = "com.parametric-forge.forge-brew-autoupdate";
      ProgramArguments = ["${autoupdateReconcile}/bin/forge-brew-autoupdate-reconcile"];
      RunAtLoad = true;
      StartCalendarInterval = [
        {
          Hour = 10;
          Minute = 0;
        }
      ];
      ProcessType = "Background";
      StandardOutPath = "/Users/${config.system.primaryUser}/Library/Logs/forge-brew-autoupdate.log";
      StandardErrorPath = "/Users/${config.system.primaryUser}/Library/Logs/forge-brew-autoupdate.log";
    };
  };
}
