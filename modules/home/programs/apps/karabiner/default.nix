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

  mkBasicRule = {
    description,
    from,
    to,
    to_if_alone ? null,
  }: {
    inherit description;
    manipulators = [
      ({
          type = "basic";
          inherit from to;
        }
        // lib.optionalAttrs (to_if_alone != null) {inherit to_if_alone;})
    ];
  };

  # Physical leader scheme consumed by Zellij: Hyper (Right Command),
  # Super (Right Option), Power (Right Shift), plus the Caps Lock dual-role.
  chordRules = [
    (mkBasicRule {
      description = "Caps Lock → ⌘⌥ super-modifier (hold) / Caps Lock (tap)";
      from = {
        key_code = "caps_lock";
        modifiers.optional = ["any"];
      };
      to = [
        {
          key_code = "left_command";
          modifiers = ["left_option"];
        }
      ];
      to_if_alone = [
        {
          hold_down_milliseconds = 100;
          key_code = "caps_lock";
        }
      ];
    })
    (mkBasicRule {
      description = "Right Shift → Power (⌥⌃⇧) leader";
      from = {
        key_code = "right_shift";
        modifiers.optional = ["any"];
      };
      to = [
        {
          key_code = "left_option";
          modifiers = ["left_control" "left_shift"];
        }
      ];
    })
    (mkBasicRule {
      description = "Right Option → Super (⌘⌥⌃) leader";
      from = {
        key_code = "right_option";
        modifiers.optional = ["any"];
      };
      to = [
        {
          key_code = "left_control";
          modifiers = ["left_command" "left_option"];
        }
      ];
    })
    (mkBasicRule {
      description = "Right Command → Hyper (⌘⌥⌃⇧) leader";
      from = {
        key_code = "right_command";
        modifiers.optional = ["any"];
      };
      to = [
        {
          key_code = "left_shift";
          modifiers = ["left_command" "left_control" "left_option"];
        }
      ];
    })
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

  # Inert import material for the Settings UI; active rules live in karabiner.json.
  stagedAssetJson = pkgs.writeText "parametric-forge-chords.json" (builtins.toJSON {
    title = "Parametric Forge chords";
    rules = chordRules;
  });

  jq = "${pkgs.jq}/bin/jq";

  # Karabiner persists runtime state (profiles[].devices, root global) into
  # karabiner.json; merge those app-owned subtrees from the live file so the
  # declarative document owns rules without destroying GUI-side device state.
  mergeProgram = ''
    ($live[0]) as $l
    | . + (if ($l | has("global")) then {global: $l.global} else {} end)
    | .profiles |= map(
        . as $p
        | (first($l.profiles[]? | select(.name == $p.name)) // {}) as $m
        | $p + (if ($m | has("devices")) then {devices: $m.devices} else {} end)
      )
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

    ${stageFile "${cfgDir}/karabiner.json" ''
      if [ -f "${cfgDir}/karabiner.json" ] && ${jq} -e . "${cfgDir}/karabiner.json" >/dev/null 2>&1; then
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
