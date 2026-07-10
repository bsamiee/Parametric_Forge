# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/karabiner/default.nix
# ----------------------------------------------------------------------------
# Karabiner-Elements writable configuration staging. Karabiner rewrites its own
# store, so the target stays a real file: generate JSON, copy only on change.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfgDir = "${config.xdg.configHome}/karabiner";
  assetDir = "${cfgDir}/assets/complex_modifications";

  # Physical leader scheme projected from the chord owner: Hyper (Right
  # Command), Super (Right Option), Power (Right Shift), Caps Lock dual-role.
  chordRules = config.forge.chords.karabiner.rules;

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

  # Inert import material for the Settings UI; active rules live in karabiner.json.
  stagedAssetJson = pkgs.writeText "parametric-forge-chords.json" (builtins.toJSON {
    title = "Parametric Forge chords";
    rules = chordRules;
  });

  jq = "${pkgs.jq}/bin/jq";

  # App-owned CLI beside the running Karabiner: lints the exact rule bytes
  # before they reach the live config. Absent only before first cask install.
  karabinerCli = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli";

  # Karabiner persists GUI/runtime state into karabiner.json: root keys beyond
  # profiles (global), per-profile devices, parameters, simple_modifications,
  # fn_function_keys, complex_modifications.parameters, virtual_hid_keyboard
  # subkeys, selected, and GUI-created profiles. The declarative document owns
  # complex_modifications.rules and the declared profile identity; everything
  # else merges from the live file so activation never destroys app-owned
  # state. Declared keys win except `selected` (profile choice is GUI-owned).
  # The stage gate admits the live file only when it is structurally a
  # Karabiner document (object; profiles an array of objects): valid JSON of
  # any other shape falls to wholesale declared replacement instead of
  # killing activation mid-merge.
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

  # Atomic write-if-changed: mktemp in the target directory, compare, rename.
  stageFile = target: renderTmp: ''
    tmp="$(mktemp "${target}.XXXXXX")"
    ${renderTmp}
    chmod 600 "$tmp"
    if ! cmp -s "$tmp" "${target}" 2>/dev/null; then
      mv "$tmp" "${target}"
    else
      rm -f "$tmp"
    fi
    chmod 600 "${target}"
  '';
in {
  imports = [../chords.nix];

  # Symlinks anywhere on the config path break Karabiner change detection;
  # refuse them and stage real writable files in place.
  home.activation.ensureKarabinerConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
    refuse_symlink() {
      if [ -L "$1" ]; then
        echo "refusing symlinked Karabiner path: $1" >&2
        exit 1
      fi
    }
    refuse_symlink "${config.xdg.configHome}"
    refuse_symlink "${cfgDir}"
    mkdir -p "${assetDir}"
    refuse_symlink "${cfgDir}/assets"
    refuse_symlink "${assetDir}"
    refuse_symlink "${cfgDir}/karabiner.json"
    refuse_symlink "${assetDir}/parametric-forge-chords.json"

    if [ -x ${lib.escapeShellArg karabinerCli} ]; then
      if ! lint="$(${lib.escapeShellArg karabinerCli} --lint-complex-modifications ${stagedAssetJson} 2>&1)"; then
        echo "karabiner: chord rules failed lint: $lint" >&2
        exit 1
      fi
    fi

    ${stageFile "${cfgDir}/karabiner.json" ''
      if [ -f "${cfgDir}/karabiner.json" ] && ${jq} -e 'type == "object" and ((.profiles // []) | type == "array") and all(.profiles[]?; type == "object")' "${cfgDir}/karabiner.json" >/dev/null 2>&1; then
        ${jq} --slurpfile live "${cfgDir}/karabiner.json" '${mergeProgram}' ${karabinerJson} >"$tmp"
      else
        cat ${karabinerJson} >"$tmp"
      fi
    ''}
    ${stageFile "${assetDir}/parametric-forge-chords.json" ''
      cat ${stagedAssetJson} >"$tmp"
    ''}
  '';
}
