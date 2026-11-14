{
  config,
  lib,
  pkgs,
  ...
}: let
  readers = {
    "com.apple.dock" = "/usr/bin/killall Dock";
    "com.apple.finder" = "/usr/bin/killall Finder";
    "com.apple.controlcenter" = "/usr/bin/killall ControlCenter";
    pbs = "/System/Library/CoreServices/pbs -update";
  };
  rendered = domain: lib.removePrefix "${config.home.homeDirectory}/" "${config.xdg.stateHome}/forge/defaults/${domain}.plist";
  plist = lib.generators.toPlist {escape = true;};
in {
  imports = [
    ./input.nix
    ./interface.nix
    ./system.nix
  ];

  options.forge.groupDefaults = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
    default = {};
    description = "App-group suite defaults, suite -> keys; each suite imports into its group container's plist every switch.";
  };

  config = {
    home.file = lib.mapAttrs' (domain: _:
      lib.nameValuePair (rendered domain) {
        text = plist (lib.filterAttrs (_: v: v != null) ((config.targets.darwin.defaults.${domain} or {}) // (config.targets.darwin.currentHostDefaults.${domain} or {})));
      })
    readers;

    home.activation = {
      rereadDefaults = lib.hm.dag.entryAfter ["setDarwinDefaults"] (lib.concatStrings (lib.mapAttrsToList (domain: command: ''
          if ! cmp -s "''${oldGenPath:-/dev/null}/home-files/${rendered domain}" "$newGenPath/home-files/${rendered domain}"; then
            run ${command}
          fi
        '')
        readers));

      setGroupDefaults = lib.hm.dag.entryAfter ["writeBoundary"] (lib.concatStrings (lib.mapAttrsToList (suite: keys: ''
          run /usr/bin/defaults import ${lib.escapeShellArg "${config.home.homeDirectory}/Library/Group Containers/${suite}/Library/Preferences/${suite}"} ${pkgs.writeText "${suite}.plist" (plist keys)}
        '')
        config.forge.groupDefaults));

      # --- [SCREEN_CAPTURE_HINTS]
      screenCaptureHints = lib.hm.dag.entryAfter ["writeBoundary"] ''
        approvals="$HOME/Library/Group Containers/group.com.apple.replayd/ScreenCaptureApprovals.plist"
        if [ -f "$approvals" ]; then
          changed=0
          while IFS= read -r client; do
            keypath="$(printf '%s' "$client" | /usr/bin/sed 's/\./\\./g').kScreenCapturePrivacyHintDate"
            if [ "$(/usr/bin/plutil -extract "$keypath" raw -o - "$approvals")" != 4000-01-01T00:00:00Z ]; then
              run /usr/bin/plutil -replace "$keypath" -date 4000-01-01T00:00:00Z "$approvals"
              changed=1
            fi
          done < <(/usr/bin/plutil -convert xml1 -o - "$approvals" | /usr/bin/xmllint --xpath '/plist/dict/key/text()' -)
          if [ "$changed" = 1 ] && /usr/bin/pgrep -qx replayd; then
            run /usr/bin/killall -9 replayd
          fi
        fi
      '';
    };
  };
}
