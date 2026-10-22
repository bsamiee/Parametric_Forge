# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/karabiner/default.nix
# ----------------------------------------------------------------------------
# Karabiner-Elements writable config staging: Karabiner rewrites its own store, so the target stays a real file — generate JSON, copy only on change.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfgDir = "${config.xdg.configHome}/karabiner";

  # Physical leader scheme projected from the chord owner: Hyper (Right Command), Super (Right Option), Power (Right Shift), Caps Lock dual-role.
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

  jq = "${pkgs.jq}/bin/jq";

  # Karabiner writes its own GUI and runtime state back into karabiner.json, so the declarative document owns only complex_modifications.rules and the
  # declared profile identity; every other key merges from the live file and activation never destroys app-owned state. Declared keys win except
  # `selected`, which stays GUI-owned. The stage gate merges only when the live file is structurally a Karabiner document (object; profiles an array
  # of objects); any other JSON shape falls to wholesale declared replacement instead of killing activation mid-merge.
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
in {
  imports = [../chords.nix];

  # Symlinks on the config path break Karabiner change detection, so a real writable file is staged in place: atomic write-if-changed
  # (mktemp in the target directory, compare, rename).
  home.activation.ensureKarabinerConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
    mkdir -p "${cfgDir}"
    tmp="$(mktemp "${target}.XXXXXX")"
    if [ -f "${target}" ] && ${jq} -e 'type == "object" and ((.profiles // []) | type == "array") and all(.profiles[]?; type == "object")' "${target}" >/dev/null 2>&1; then
      ${jq} --slurpfile live "${target}" '${mergeProgram}' ${karabinerJson} >"$tmp"
    else
      cat ${karabinerJson} >"$tmp"
    fi
    chmod 600 "$tmp"
    if ! cmp -s "$tmp" "${target}" 2>/dev/null; then
      mv "$tmp" "${target}"
    else
      rm -f "$tmp"
    fi
    chmod 600 "${target}"
  '';
}
