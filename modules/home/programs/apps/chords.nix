# Title         : chords.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/chords.nix
# ----------------------------------------------------------------------------
# Single chord-vocabulary owner: physical leader layers, zellij leader binds,
# mode table, which-key rows, and hint-ribbon rows are ONE parameterized table
# projected into karabiner JSON, zellij keybind KDL, and zellij-forgot content.
# A new bind is one row here; consumers never hand-duplicate chords.
{lib, ...}: let
  # --- Physical layers --------------------------------------------------------
  # Karabiner rewrites right-hand modifiers into leader stacks; zellij consumes
  # each stack as the concrete modifier set named in `zellij`. Power carries no
  # zellij binds by design: it passes through to terminal apps (yazi owns it).
  # WezTerm claims NO layer: its outer-terminal keys live on native left-Command
  # chords only (keys.lua), so every leader chord passes to zellij untouched.
  # `rank` orders the emitted karabiner rule document.
  layers = {
    hyper = {
      name = "Hyper";
      glyphs = "⌘⌥⌃⇧";
      physical = "Right Command";
      chip = "R⌘";
      rank = 30;
      from = "right_command";
      to = {
        key_code = "left_shift";
        modifiers = ["left_command" "left_control" "left_option"];
      };
      zellij = "Super Alt Ctrl Shift";
    };
    super = {
      name = "Super";
      glyphs = "⌘⌥⌃";
      physical = "Right Option";
      chip = "R⌥";
      rank = 20;
      from = "right_option";
      to = {
        key_code = "left_control";
        modifiers = ["left_command" "left_option"];
      };
      zellij = "Super Alt Ctrl";
    };
    power = {
      name = "Power";
      glyphs = "⌥⌃⇧";
      physical = "Right Shift";
      chip = "R⇧";
      rank = 10;
      from = "right_shift";
      to = {
        key_code = "left_option";
        modifiers = ["left_control" "left_shift"];
      };
      zellij = "Alt Ctrl Shift";
    };
  };

  # Caps Lock dual-role sits beside the leader layers in the karabiner document.
  capsRule = {
    description = "Caps Lock → ⌘⌥ super-modifier (hold) / Caps Lock (tap)";
    manipulators = [
      {
        type = "basic";
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
      }
    ];
  };

  # Leader-role documentation block: vocabulary interpolates from the layer
  # table; only the inter-field padding stays curated per row (glyph display
  # widths defeat programmatic alignment). Every fragment line carries its full
  # emitted indentation; consumers interpolate at their template's indent anchor.
  headerComment = lib.concatStringsSep "\n" [
    "    // Primary Modifier:    ${layers.hyper.physical}   → ${layers.hyper.name} (${layers.hyper.glyphs})  leader | ${layers.hyper.zellij}"
    "    // Secondary Modifier:  ${layers.super.physical}    → ${layers.super.name} (${layers.super.glyphs})   leader | ${layers.super.zellij}"
    "    // Tertiary Modifier:   ${layers.power.physical}     → ${layers.power.name} (${layers.power.glyphs})   leader | ${layers.power.zellij}"
  ];

  # --- Mode table ---------------------------------------------------------------
  # One row per zellij mode reachable from a Hyper leader key. `rank` orders the
  # which-key sheet; `ribbon` labels the normal-mode hint ribbon; `entryOrder`
  # and `ribbonOrder` are curated presentation sequences over the same rows.
  modes = {
    pane = {
      key = "p";
      ribbon = "pane";
      rank = 30;
    };
    tab = {
      key = "t";
      ribbon = "tab";
      rank = 40;
    };
    resize = {
      key = "r";
      ribbon = "resize";
      rank = 50;
    };
    scroll = {
      key = "s";
      ribbon = "scroll";
      rank = 60;
    };
    session = {
      key = "o";
      ribbon = "session";
      rank = 70;
    };
    move = {
      key = "m";
      ribbon = "move";
      rank = 80;
    };
    tmux = {
      key = "b";
      rank = 90;
    };
    locked = {
      key = "g";
      exitKey = "l";
      ribbon = "lock";
    };
  };
  entryOrder = ["pane" "resize" "scroll" "session" "tab" "move" "tmux"];
  ribbonOrder = ["pane" "tab" "resize" "move" "scroll" "session" "locked"];

  # --- Bind rows ----------------------------------------------------------------
  # Row schema: keys (aliases share one row), kdl (single-line body) XOR body
  # (verbatim multi-line KDL at emitted indentation), pre (verbatim comment
  # lines), gap (blank line before), forgot {label, display?, rank}, ribbon
  # {label, key?, rank}, id (exports the row as zellij.ids.<id> {key, mods}
  # for runtime chord injection). Display strings derive from layer prefixes
  # unless a curated grouping overrides them.
  hyperRows = [
    {
      keys = [modes.locked.key];
      kdl = ''SwitchToMode "Locked";'';
    }
    {
      keys = ["q"];
      kdl = "Quit;";
      forgot = {
        label = "quit zellij";
        rank = 110;
      };
    }
    {
      keys = ["["];
      kdl = "PreviousSwapLayout;";
      forgot = {
        label = "swap layout prev/next";
        display = "Hyper [ / Hyper ]";
        rank = 100;
      };
    }
    {
      keys = ["]"];
      kdl = "NextSwapLayout;";
    }
  ];

  # Normal-mode simple layer: bare macOS Command chords zellij receives because
  # WezTerm full-passes them (no default keybinds; keys.lua claims neither).
  normalRows = [
    {
      key = "t";
      action = "NewTab;";
      comment = "Create new tab without entering tab mode";
      forgot = {
        label = "new tab";
        rank = 130;
      };
    }
    {
      key = "w";
      action = "CloseFocus;";
      comment = "Close pane without entering pane mode";
      forgot = {
        label = "close pane";
        rank = 140;
      };
    }
  ];

  superRows = [
    {
      keys = ["["];
      kdl = "GoToPreviousTab;";
      forgot = {
        label = "previous/next tab";
        display = "Super Alt Ctrl [ / ]";
        rank = 170;
      };
      ribbon = {
        key = "[ ]";
        label = "tab ±";
        rank = 50;
      };
    }
    {
      keys = ["]"];
      kdl = "GoToNextTab;";
    }
    {
      gap = true;
      keys = ["f"];
      kdl = "ToggleFloatingPanes;";
      forgot = {
        label = "toggle floating panes";
        rank = 190;
      };
      ribbon = {
        label = "float";
        rank = 30;
      };
    }
    {
      keys = ["n"];
      kdl = "NewPane;";
      forgot = {
        label = "new pane";
        rank = 180;
      };
      ribbon = {
        label = "pane";
        rank = 20;
      };
    }
    {
      pre = lib.concatStringsSep "\n" [
        "        // Floating dispatcher: toggles the per-tab Yazi popup (create /"
        "        // show+focus / hide). Never in_place: an attached client on 0.44.3"
        "        // strands exited in-place panes and their suppressed hosts."
      ];
      id = "yaziToggle";
      keys = ["y"];
      body = lib.concatStringsSep "\n" [
        "          Run \"forge-yazi.sh\" \"toggle\" {"
        "            floating true"
        "            close_on_exit true"
        "            x \"45%\""
        "            y \"45%\""
        "            width \"10%\""
        "            height \"10%\""
        "          }"
      ];
      forgot = {
        label = "yazi popup";
        rank = 150;
      };
      ribbon = {
        label = "files";
        rank = 10;
      };
    }
    {
      gap = true;
      keys = ["h" "Left"];
      kdl = ''MoveFocusOrTab "Left";'';
      forgot = {
        label = "move focus";
        display = "Super Alt Ctrl h/j/k/l";
        rank = 200;
      };
    }
    {
      keys = ["l" "Right"];
      kdl = ''MoveFocusOrTab "Right";'';
    }
    {
      keys = ["j" "Down"];
      kdl = ''MoveFocus "Down";'';
    }
    {
      keys = ["k" "Up"];
      kdl = ''MoveFocus "Up";'';
    }
    {
      keys = ["=" "+"];
      kdl = ''Resize "Increase";'';
      forgot = {
        label = "resize";
        display = "Super Alt Ctrl = / -";
        rank = 210;
      };
    }
    {
      keys = ["-"];
      kdl = ''Resize "Decrease";'';
    }
    {
      keys = ["p"];
      kdl = "TogglePaneInGroup;";
      forgot = {
        label = "pane group toggle/mark";
        display = "Super Alt Ctrl p / g";
        rank = 220;
      };
    }
    {
      keys = ["g"];
      kdl = "ToggleGroupMarking;";
    }
  ];

  # Which-key rows with no chord of their own: command vocabulary surfaced in
  # the cheatsheet beside the chords.
  forgotExtras = [
    {
      rank = 230;
      label = "editor";
      display = "nv / vim -> nvim";
    }
    {
      rank = 240;
      label = "file manager";
      display = "y -> yazi popup (Super Alt Ctrl y)";
    }
    {
      rank = 250;
      label = "git ui";
      display = "lazygit float (pane mode w)";
    }
    {
      rank = 260;
      label = "json explore";
      display = "jqi -> jnv";
    }
    {
      rank = 270;
      label = "loc report";
      display = "loc <path>";
    }
    {
      rank = 280;
      label = "folder map";
      display = "tree <path>";
    }
    {
      rank = 290;
      label = "deploy";
      display = "forge-redeploy --check-only / --build / --switch";
    }
    {
      rank = 300;
      label = "http";
      display = "GET/POST/PUT -> xh";
    }
    # WezTerm outer layer (native left-Cmd chords, keys.lua): surfaced here so
    # the cheatsheet owns discoverability for the whole terminal stack.
    {
      rank = 310;
      label = "wezterm palette";
      display = "⇧⌘P";
    }
    {
      rank = 320;
      label = "wezterm quick select";
      display = "⇧⌘Space";
    }
    {
      rank = 330;
      label = "wezterm launcher";
      display = "⇧⌘L";
    }
    {
      rank = 340;
      label = "wezterm unicode picker";
      display = "⇧⌘U";
    }
    {
      rank = 350;
      label = "wezterm debug overlay";
      display = "⇧⌘D";
    }
  ];

  # --- Projections ----------------------------------------------------------------
  # Every table string emitted inside a KDL quoted string passes through this.
  kdlEsc = lib.replaceStrings ["\\" "\""] ["\\\\" "\\\""];
  cheatsheetKey = "/";
  cap = s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;

  forgotOf = prefix: rows:
    lib.concatMap (
      r:
        lib.optional (r ? forgot) {
          inherit (r.forgot) label rank;
          display = r.forgot.display or "${prefix} ${builtins.head r.keys}";
        }
    )
    rows;

  modeForgot =
    [
      {
        rank = 10;
        label = "lock";
        display = "${layers.hyper.name} ${modes.locked.key}";
      }
      {
        rank = 20;
        label = "unlock (locked)";
        display = "${layers.hyper.name} ${modes.locked.exitKey}";
      }
    ]
    ++ map (m: {
      inherit (modes.${m}) rank;
      label = "${m} mode";
      display = "${layers.hyper.name} ${modes.${m}.key}";
    }) (lib.filter (m: modes.${m} ? rank) (lib.attrNames modes));

  cheatsheetForgot = {
    rank = 120;
    label = "cheatsheet";
    display = "${layers.hyper.name} ${cheatsheetKey}";
  };

  forgotRows =
    lib.sort (a: b: a.rank < b.rank)
    (modeForgot
      ++ [cheatsheetForgot]
      ++ forgotOf layers.hyper.name hyperRows
      ++ map (r: r.forgot // {display = "Super ${r.key}";}) normalRows
      ++ forgotOf layers.super.zellij superRows
      ++ forgotExtras);

  forgotKdl =
    lib.concatMapStringsSep "\n"
    (r: "            \"${kdlEsc r.label}\" \"${kdlEsc r.display}\"")
    forgotRows;

  # KEY IDENTITY: a Shift-carrying layer receives shifted punctuation as the
  # SHIFTED character, so its binds emit that glyph both with and without the
  # Shift modifier listed; letter keys and Shift-free layers pass through.
  shiftedGlyph = {
    "/" = "?";
    "[" = "{";
    "]" = "}";
    "\\" = "|";
  };
  stripShift = prefix: lib.concatStringsSep " " (lib.filter (w: w != "Shift") (lib.splitString " " prefix));
  bindKeys = prefix: k:
    if lib.hasInfix "Shift" prefix && shiftedGlyph ? ${k}
    then ["${prefix} ${shiftedGlyph.${k}}" "${stripShift prefix} ${shiftedGlyph.${k}}"]
    else ["${prefix} ${kdlEsc k}"];

  renderBind = prefix: row: let
    keysStr = lib.concatMapStringsSep " " (s: "\"${s}\"") (lib.concatMap (bindKeys prefix) row.keys);
  in
    lib.concatStrings [
      (lib.optionalString (row.gap or false) "\n")
      (lib.optionalString (row ? pre) (row.pre + "\n"))
      (
        if row ? body
        then "        bind ${keysStr} {\n${row.body}\n        }"
        else "        bind ${keysStr} { ${row.kdl} }"
      )
    ];

  cheatsheetBind = lib.concatStringsSep "\n" [
    "        bind ${lib.concatMapStringsSep " " (s: "\"${s}\"") (bindKeys layers.hyper.zellij cheatsheetKey)} {"
    "          LaunchOrFocusPlugin \"zellij-forgot\" {"
    "            \"LOAD_ZELLIJ_BINDINGS\" \"false\""
    forgotKdl
    "            floating true"
    "            move_to_focused_tab true"
    "          };"
    "          SwitchToMode \"Normal\""
    "        }"
  ];

  hyperBindsKdl =
    lib.concatMapStringsSep "\n" (renderBind layers.hyper.zellij) hyperRows
    + "\n"
    + cheatsheetBind;

  superBindsKdl = lib.concatMapStringsSep "\n" (renderBind layers.super.zellij) superRows;

  normalBindsKdl = lib.concatMapStringsSep "\n" (r:
    lib.concatStringsSep "\n" [
      "        bind \"Super ${r.key}\" {            // ${r.comment}"
      "          ${r.action}"
      "          SwitchToMode \"Normal\";"
      "        }"
    ])
  normalRows;

  entryBindsKdl = lib.concatMapStringsSep "\n" (m:
    lib.concatStringsSep "\n" [
      "      shared_except \"${m}\" \"locked\" {"
      "        bind \"${layers.hyper.zellij} ${modes.${m}.key}\" { SwitchToMode \"${cap m}\"; }"
      "      }"
    ])
  entryOrder;

  # Hint-ribbon rows for normal mode: the two leader groups in curated order.
  ribbonHyperGroup =
    map (m: {
      k = modes.${m}.key;
      l = modes.${m}.ribbon;
    })
    ribbonOrder
    ++ [
      {
        k = cheatsheetKey;
        l = "sheet";
      }
    ];
  ribbonSuperGroup =
    map (r: {
      k = r.ribbon.key or (kdlEsc (builtins.head r.keys));
      l = r.ribbon.label;
    }) (lib.sort (a: b: a.ribbon.rank < b.ribbon.rank)
      (builtins.filter (r: r ? ribbon) superRows));

  hintsRight =
    "${layers.hyper.chip} ${lib.toLower layers.hyper.name}"
    + " · ${layers.super.chip} ${lib.toLower layers.super.name} ";

  # Kitty CSI-u modifier field for a zellij prefix (bitmask + 1); id-tagged
  # rows export {key, mods} so runtime consumers inject the REAL chord bytes
  # without hand-duplicating the vocabulary.
  csiMods = prefix:
    lib.foldl' (a: w:
      a
      + {
        Super = 8;
        Alt = 2;
        Ctrl = 4;
        Shift = 1;
      }
      .${
        w
      })
    1 (lib.splitString " " prefix);
  bindIds = layer: rows:
    lib.concatMap (
      r:
        lib.optional (r ? id) {
          name = r.id;
          value = {
            key = builtins.head r.keys;
            mods = csiMods layer.zellij;
          };
        }
    )
    rows;
  ids = lib.listToAttrs (bindIds layers.hyper hyperRows ++ bindIds layers.super superRows);
in {
  options.forge.chords = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      inherit layers modes;
      karabiner.rules =
        [capsRule]
        ++ map (l: {
          description = "${l.physical} → ${l.name} (${l.glyphs}) leader";
          manipulators = [
            {
              type = "basic";
              from = {
                key_code = l.from;
                modifiers.optional = ["any"];
              };
              to = [l.to];
            }
          ];
        }) (lib.sort (a: b: a.rank < b.rank) (lib.attrValues layers));
      zellij = {
        inherit headerComment hyperBindsKdl superBindsKdl normalBindsKdl entryBindsKdl hintsRight ids;
        prefix = lib.mapAttrs (_: l: l.zellij) layers;
        ribbon = {
          hyperGroup = ribbonHyperGroup;
          superGroup = ribbonSuperGroup;
        };
      };
    };
    description = "Chord-vocabulary owner: leader layers, zellij binds, which-key and ribbon rows.";
  };
}
