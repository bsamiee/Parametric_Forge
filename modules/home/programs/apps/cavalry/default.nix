{
  config,
  lib,
  pkgs,
  ...
}: let
  preferences = lib.escapeShellArg "${config.home.homeDirectory}/Library/Preferences/Cavalry/preferences.json";
in {
  home.activation.setCavalryDeveloperMode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -f ${preferences} ]]; then
      updated="$(mktemp)"
      ${lib.getExe pkgs.jq} '.developerMode = {"value": true, "varType": "bool"} | .betaFeatures = {"value": true, "varType": "bool"}' ${preferences} > "$updated"
      /usr/bin/cmp -s "$updated" ${preferences} || if /usr/bin/pgrep -qx Cavalry; then noteEcho "Cavalry is running: developerMode and betaFeatures wait for the next switch"; else run cp "$updated" ${preferences}; fi
      rm -f "$updated"
    fi
  '';
}
