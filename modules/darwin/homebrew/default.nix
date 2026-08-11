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

  # --- [AUTOUPDATE_SCHEDULE]
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
        # One pass proves every updater marker present and the notifier absent.
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
      # Brew 6 refuses external commands from untrusted taps; trust is per-machine state (trust.json), so a fresh host needs the grant re-minted.
      brew trust --tap domt4/autoupdate >/dev/null
      brew autoupdate delete >/dev/null 2>&1 || true
      brew autoupdate start ${toString autoupdateIntervalSeconds} ${autoupdateStartArgs}
    '';
  };

  # --- [ROW_CONVERGENCE]
  # Brew 6 `bundle` fetches, prints per-item checkmarks, and exits 0 while installing nothing — not even taps (scars.md [07]-[11]) — so
  # activation converges the declared rows itself with direct installs. On a converged system every row degrades to a fast presence check.
  brewConverge = pkgs.writeShellApplication {
    name = "forge-brew-converge";
    text = ''
      export PATH="${activationPath}"
      export HOMEBREW_CASK_OPTS="--no-quarantine"
      export HOMEBREW_NO_ANALYTICS=1
      rc=0
      ${lib.concatMapStringsSep "\n" (t: ''brew tap | grep -qx "${t}" || brew tap "${t}" || { echo "forge-brew-converge: tap ${t} failed" >&2; rc=1; }'') (map (t: t.name) config.homebrew.taps)}
      for f in ${lib.escapeShellArgs (map (b: b.name) config.homebrew.brews)}; do
        brew list --formula "$f" >/dev/null 2>&1 || brew install --formula "$f" || { echo "forge-brew-converge: formula $f failed" >&2; rc=1; }
      done
      for c in ${lib.escapeShellArgs (map (c: c.name) config.homebrew.casks)}; do
        brew list --cask "$c" >/dev/null 2>&1 || brew install --cask "$c" || { echo "forge-brew-converge: cask $c failed" >&2; rc=1; }
      done
      ${lib.concatMapStringsSep "\n" (id: ''mas list | awk '{print $1}' | grep -qx "${toString id}" || mas install ${toString id} || { echo "forge-brew-converge: mas ${toString id} failed" >&2; rc=1; }'') (lib.attrValues config.homebrew.masApps)}
      exit "$rc"
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

    # Brew 6 silently skips new cask installs when the Brewfile carries cask_args (scars.md [07]-[02]): no caskArgs row, every declared value
    # is the Homebrew default, and posture rides HOMEBREW_CASK_OPTS above.
  };

  # Converge runs as the primary user (brew refuses root); extraActivation is the free nix-darwin hook — postActivation is security-owned.
  system.activationScripts.extraActivation.text = ''
    sudo -u ${config.system.primaryUser} --set-home ${brewConverge}/bin/forge-brew-converge
  '';

  # Converged runs are read-only and exit 0, logged so a failed regeneration never hides until the next day. The reconciled agent keeps
  # its upstream tap label (com.github.domt4.homebrew-autoupdate) — an upstream-owned identifier renamed only upstream, never here. nix-darwin's
  # strict launchd schema has no AssociatedBundleIdentifiers key, so this row shows a generic Login Items entry.
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

  # WezTerm nightly is a :latest cask the domt4 updater never boards (blanket --greedy would drag every auto-updating cask with it), so a
  # dedicated row owns its daily advance. Bundle swap under a running terminal is safe — live sessions hold the open binary and the operator
  # relaunches on their own schedule.
  launchd.user.agents.forge-wezterm-nightly = {
    serviceConfig = {
      Label = "com.parametric-forge.forge-wezterm-nightly";
      ProgramArguments = ["${config.homebrew.prefix}/bin/brew" "upgrade" "--cask" "wezterm@nightly" "--greedy-latest"];
      EnvironmentVariables = {
        HOMEBREW_CASK_OPTS = "--no-quarantine";
        HOMEBREW_NO_ANALYTICS = "1";
      };
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
