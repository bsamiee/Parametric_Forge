# Title         : suggestions.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/mac-tools/suggestions.nix
# ----------------------------------------------------------------------------
# Siri Suggestions per-application owner. macOS 27 carries no global switch for suggestion harvesting: suggestd admits an app's CoreSpotlight
# and user-activity donations into ProactiveHarvesting and PersonalizationPortrait unless com.apple.suggestions SiriCanLearnFromAppBlacklist
# names its bundle identifier ("Learn from this application"), and AppCanShowSiriSuggestionsBlacklist is the sibling "Show Siri Suggestions in
# application" row; both are the rows the Siri pane's App Access sheet writes. The lists gate suggestd alone: spotlightknowledged embeds the
# same donations whatever they hold. The rows are a set of installed applications, so a static plist row cannot own them: the agent folds
# every application Spotlight indexes into both lists, keeps every identifier already listed (uninstalled apps, sheet edits), and posts the
# sheet's change notification, which reloads the admission and portrait lists in place.
{
  config,
  launchdAgent,
  pkgs,
  ...
}: let
  domain = "com.apple.suggestions";
  keys = ["SiriCanLearnFromAppBlacklist" "AppCanShowSiriSuggestionsBlacklist"];
  command = pkgs.writeShellApplication {
    name = "suggestion-blocklist";
    runtimeInputs = [pkgs.coreutils pkgs.jq];
    text = ''
      declare -A installed=()
      while IFS= read -r -d "" row; do
        id=''${row##* kMDItemCFBundleIdentifier = }
        [[ $id == "(null)" ]] || installed[$id]=1
      done < <(/usr/bin/mdfind -0 -attr kMDItemCFBundleIdentifier 'kMDItemContentType == "com.apple.application-bundle"')
      ((''${#installed[@]})) || { echo 'Spotlight returned no application bundles' >&2; exit 1; }
      snapshot=$(mktemp)
      trap 'rm -f "$snapshot"' EXIT
      /usr/bin/defaults export ${domain} "$snapshot"
      listed() {
        if /usr/bin/plutil -type "$1" "$snapshot" >/dev/null 2>&1; then
          /usr/bin/plutil -extract "$1" json -o - "$snapshot" | jq -r '.[]'
        fi
      }
      changed=0
      for key in ${toString keys}; do
        mapfile -t present < <(listed "$key" | sort -u)
        mapfile -t merged < <({ listed "$key"; printf '%s\n' "''${!installed[@]}"; } | sort -u)
        if [[ "''${merged[*]}" != "''${present[*]}" ]]; then
          /usr/bin/defaults write ${domain} "$key" -array "''${merged[@]}"
          printf '%s: %s -> %s bundle identifiers\n' "$key" "''${#present[@]}" "''${#merged[@]}"
          changed=1
        fi
      done
      ((changed == 0)) || /usr/bin/notifyutil -p ${domain}.settingsChanged
    '';
  };
in {
  home.packages = [command];

  # --- [SUGGESTION_BLOCKLIST]
  # RunAtLoad folds the list at each login and on the switch that (re)loads the agent; WatchPaths refolds it when an install or removal changes
  # an Applications root, so a new app never starts out learned from.
  launchd.agents.suggestion-blocklist = launchdAgent {
    name = "suggestion-blocklist";
    argv = ["${command}/bin/suggestion-blocklist"];
    RunAtLoad = true;
    WatchPaths = ["/Applications" "${config.home.homeDirectory}/Applications"];
  };
}
