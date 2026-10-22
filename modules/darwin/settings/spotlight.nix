# Title         : spotlight.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/settings/spotlight.nix
# ----------------------------------------------------------------------------
# Spotlight's Data-volume exclusion set, Forge owning the whole set. It reconciles through the Metadata.framework calls System Settings'
# Search Privacy list makes: each call restarts mds, so the list is read once and every change runs in its own process; an added row leaves
# that tree's entries in the store, so any addition erases and rebuilds the Data volume index. Raycast name search keeps covering excluded
# trees through its own indexer; its Content Search follows Spotlight's scope.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.home-manager.users.${config.system.primaryUser}.home) homeDirectory;
  # Search Privacy rows: Forge-owned roots and app-state trees that hold nothing searched by path. Hidden folders, /private, and
  # ~/Library/Caches are never indexed and take no row. Every row names a path that always exists: the exclusion list omits missing paths.
  exclusions = map (row: "${homeDirectory}/${row}") [
    "Developer"
    "Library/Application Support"
    "Library/Developer/Xcode/DerivedData"
    "Library/Logs"
    "Library/WebKit"
  ];
  # No argument prints the live list one path per line; `<path> <0|1>` sets one row.
  exclusion = pkgs.writeText "spotlight-exclusion.js" ''
    ObjC.import('CoreServices');
    ObjC.bindFunction('_MDCopyExclusionList', ['id', []]);
    ObjC.bindFunction('_MDSetExclusion', ['int', ['id', 'int']]);
    function run([path, excluded]) {
      if (path === undefined) return ObjC.deepUnwrap($._MDCopyExclusionList()).join('\n');
      const status = $._MDSetExclusion($(path), Number(excluded));
      if (status !== 0) throw new Error('_MDSetExclusion ' + path + ' ' + excluded + ': ' + status);
    }
  '';
in {
  system.activationScripts.postActivation.text = ''
    spotlight=(/usr/bin/osascript -l JavaScript ${exclusion})
    declare -A excluded=()
    while IFS= read -r path; do [[ -z $path ]] || excluded[$path]=1; done < <("''${spotlight[@]}")
    added=0
    for path in ${lib.escapeShellArgs exclusions}; do
      if [[ -n ''${excluded[$path]-} ]]; then unset 'excluded[$path]'; else "''${spotlight[@]}" "$path" 1 >/dev/null; added=1; fi
    done
    for path in "''${!excluded[@]}"; do "''${spotlight[@]}" "$path" 0 >/dev/null; done
    ((added == 0)) || /usr/bin/mdutil -E /System/Volumes/Data >/dev/null
  '';
}
