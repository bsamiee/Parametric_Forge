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
      /usr/bin/cmp -s "$updated" ${preferences} || run cp "$updated" ${preferences}
      rm -f "$updated"
    fi
  '';
}
