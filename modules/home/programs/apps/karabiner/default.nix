{
  applications,
  config,
  lib,
  pkgs,
  chords,
  ...
}: let
  cfgDir = "${config.xdg.configHome}/karabiner";

  inChrome = [
    {
      type = "frontmost_application_if";
      bundle_identifiers = ["^${lib.escapeRegex applications.chrome.id}$"];
    }
  ];
  bound = description: key: modifiers: command: conditions: {
    inherit description;
    manipulators = [
      {
        type = "basic";
        from = {
          key_code = key;
          modifiers.mandatory = modifiers;
        };
        to = [{shell_command = command;}];
        inherit conditions;
      }
    ];
  };
  raycast = command: "/usr/bin/open 'raycast://extensions/${command}'";

  chordRules =
    chords.karabiner.rules
    ++ [
      (bound "Chrome: Cmd+Shift+U copies the page URL" "u" ["command" "shift"]
        ''/usr/bin/osascript -e 'tell application id "${applications.chrome.id}" to set the clipboard to (URL of active tab of front window as text)' ''
        inChrome)
      (bound "Chrome: Cmd+T opens the Raycast Chrome command bar" "t" ["command"] (raycast "Codely/google-chrome/new-tab") inChrome)
      (bound "Chrome: Cmd+Shift+A searches tabs, history, and bookmarks in Raycast" "a" ["command" "shift"] (raycast "Codely/google-chrome/search-all") inChrome)
      (bound "Opt+Cmd+N opens a Little Chrome window" "n" ["command" "option"] (raycast "tompenguin/little-chrome/open-little-chrome") [])
    ];

  karabinerJson = pkgs.writeText "karabiner.json" (builtins.toJSON {
    profiles = [
      {
        name = "Default profile";
        selected = true;
        complex_modifications.rules = chordRules;
        virtual_hid_keyboard.keyboard_type_v2 = "ansi";
      }
    ];
  });

  mergeProgram = ''
    ($live[0]) as $l
    | (.profiles | map(.name)) as $names
    | ($l | del(.profiles)) + .
    | .profiles = (.profiles | map(
        . as $p
        | (first($l.profiles[]? | select(.name == $p.name)) // {}) as $m
        | $m + $p
        | .complex_modifications = (($m.complex_modifications // {}) + $p.complex_modifications)
        | .virtual_hid_keyboard = (($m.virtual_hid_keyboard // {}) + $p.virtual_hid_keyboard)
        | (if $m | has("selected") then .selected = $m.selected else . end)
      ))
      + [$l.profiles[]? | select(.name as $n | $names | index($n) | not)]
  '';
  target = "${cfgDir}/karabiner.json";

  stageConfig = pkgs.writeShellApplication {
    name = "stage-karabiner-config";
    runtimeInputs = [pkgs.coreutils pkgs.diffutils pkgs.jq];
    text = ''
      mkdir -p "${cfgDir}"
      tmp="$(mktemp "${target}.XXXXXX")"
      trap 'rm -f "$tmp"' EXIT
      if [ -f "${target}" ] && jq -e 'type == "object" and ((.profiles // []) | type == "array") and all(.profiles[]?; type == "object")' "${target}" >/dev/null 2>&1; then
        jq --slurpfile live "${target}" '${mergeProgram}' ${karabinerJson} >"$tmp"
      else
        cat ${karabinerJson} >"$tmp"
      fi
      if ! cmp -s "$tmp" "${target}"; then
        mv "$tmp" "${target}"
      fi
      chmod 600 "${target}"
    '';
  };
in {
  imports = [../chords.nix];

  home.activation.ensureKarabinerConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${stageConfig}/bin/stage-karabiner-config
  '';
}
