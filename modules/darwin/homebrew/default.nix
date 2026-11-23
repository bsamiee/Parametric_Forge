{
  config,
  lib,
  pkgs,
  host,
  ...
}: let
  inherit (lib) mkDefault;
  brewfile = "homebrew/Brewfile";
  user = config.system.primaryUser;
  # Casks that replace themselves under a running app: greedy rows plus nightly/daily channels.
  freshCasks = map (cask: cask.name) (lib.filter (cask: cask.greedy == true || builtins.match ".*@(nightly|daily)" cask.name != null) config.homebrew.casks);
in {
  imports = [./casks.nix];

  # --- [ENVIRONMENT]
  environment = {
    etc = {
      ${brewfile}.text = config.homebrew.brewfile;
      "homebrew/brew.env".text = ''
        HOMEBREW_BUNDLE_FILE=/etc/${brewfile}
        HOMEBREW_XDG_CONFIG_HOME=${config.home-manager.users.${config.system.primaryUser}.xdg.configHome}
        HOMEBREW_UPDATE_TO_TAG=1
        HOMEBREW_FORCE_API_AUTO_UPDATE=1
        HOMEBREW_NO_ANALYTICS=1
        HOMEBREW_NO_ENV_HINTS=1
        HOMEBREW_NO_EMOJI=1
        HOMEBREW_NO_ASK=1
        HOMEBREW_CLEANUP_MAX_AGE_DAYS=3
        HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=1
        HOMEBREW_UPGRADE_GREEDY_CASKS=${toString (map (cask: lib.last (lib.splitString "/" cask.name)) (lib.filter (cask: cask.greedy == true) config.homebrew.casks))}
      '';
    };
  };

  # --- [STALE_APP_RESTART]
  # A running app whose code hash differs from its bundle on disk was replaced underneath
  # itself; macOS then refuses its TCC and notification grants until it relaunches.
  system.activationScripts.postActivation.text = ''
    uid=$(/usr/bin/id -u ${user})
    for app in $(/usr/bin/sudo -u ${user} -H ${config.homebrew.prefix}/bin/brew info --cask --json=v2 ${lib.escapeShellArgs freshCasks} \
      | ${lib.getExe pkgs.jq} -r '.casks[].artifacts[] | .app? // empty | .[0] | strings'); do
      bundle="/Applications/$app"
      exe=$(/usr/bin/plutil -extract CFBundleExecutable raw "$bundle/Contents/Info.plist" 2>/dev/null) || continue
      pid=$(/usr/bin/pgrep -o -f "^$bundle/Contents/MacOS/$exe") || continue
      running=$(/usr/bin/codesign -dvvv "$pid" 2>&1 | /usr/bin/grep '^CDHash=')
      disk=$(/usr/bin/codesign -dvvv "$bundle" 2>&1 | /usr/bin/grep '^CDHash=')
      [ "$running" = "$disk" ] && continue
      echo "restarting $app: running code no longer matches its bundle" >&2
      /bin/launchctl asuser "$uid" /usr/bin/sudo -u ${user} /usr/bin/nohup /bin/sh -c \
        '/usr/bin/osascript -e "quit app \"$1\""; while /bin/kill -0 "$2" 2>/dev/null; do /bin/sleep 0.5; done; /usr/bin/open "$1"' \
        sh "$bundle" "$pid" >/dev/null 2>&1 &
    done
  '';

  homebrew = {
    enable = mkDefault true;

    taps = [
      {
        name = "bsamiee/parametric-forge";
        clone_target = host.flakeRoot;
        trusted = true;
      }
      "rive-app/tap"
    ];

    # --- [ACTIVATION_BEHAVIOR]
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      extraEnv.HOMEBREW_AUTO_UPDATE_SECS = "0";
    };
  };
}
