# Title         : chords.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/chords.nix
# ----------------------------------------------------------------------------
# Single chord-vocabulary owner: physical leader layers, zellij leader binds, mode table, which-key rows, ribbon hints, and per-consumer register
# rows are ONE parameterized table projected into karabiner JSON, zellij KDL, zellij-forgot content, and WezTerm rows.lua. A new bind is one
# row here; consumers never hand-duplicate chords.
{lib, ...}: let
  # --- [ROW_GRAMMAR]
  # Positional tuples zip against a field schema: a short tuple drops trailing fields and null skips a slot.
  row = fields: t: lib.filterAttrs (_: v: v != null) (lib.listToAttrs (lib.zipListsWith lib.nameValuePair fields t));
  sub = long: short: t:
    row (
      if builtins.length t == 3
      then long
      else short
    )
    t;
  mkForgot = sub ["label" "display" "rank"] ["label" "rank"];
  mkRibbon = sub ["label" "key" "rank"] ["label" "rank"];

  # --- [PHYSICAL_LAYERS]
  # Karabiner rewrites right-hand modifiers into leader stacks; zellij consumes each stack as the derived modifier set.
  # WezTerm claims no layer — its outer keys live in weztermRows.
  # Glyphs, the zellij prefix, and the WezTerm glyph map all derive from the karabiner `to`
  # row through this vocabulary; `rank` orders the emitted rule document, `display` overrides the cheatsheet prefix.
  modVocab = map (row ["kc" "word" "wez" "glyph"]) [
    ["left_command" "Super" "CMD" "⌘"]
    ["left_option" "Alt" "ALT" "⌥"]
    ["left_control" "Ctrl" "CTRL" "⌃"]
    ["left_shift" "Shift" "SHIFT" "⇧"]
  ];
  mkLayer = t: let
    r = row ["name" "physical" "chip" "rank" "from" "toKey" "toMods" "display"] t;
  in
    (removeAttrs r ["toKey" "toMods"])
    // {
      to = {
        key_code = r.toKey;
        modifiers = r.toMods;
      };
    };
  layers =
    lib.mapAttrs (
      _: l: let
        mods = lib.filter (m: lib.elem m.kc ([l.to.key_code] ++ l.to.modifiers)) modVocab;
        zellij = lib.concatMapStringsSep " " (m: m.word) mods;
      in
        l
        // {
          inherit mods zellij;
          glyphs = lib.concatMapStrings (m: m.glyph) mods;
          display = l.display or zellij;
        }
    ) (lib.mapAttrs (_: mkLayer) {
      hyper = ["Hyper" "Right Command" "R⌘" 30 "right_command" "left_shift" ["left_command" "left_control" "left_option"] "Hyper"];
      super = ["Super" "Right Option" "R⌥" 20 "right_option" "left_control" ["left_command" "left_option"]];
    });
  layersByRank = dir: lib.sort (a: b: dir a.rank b.rank) (lib.attrValues layers);

  # One manipulator grammar owns every karabiner rule: leader rewrites and the Caps Lock dual-role are rows; `alone` adds the tap arm.
  mkKarabinerRule = r: {
    inherit (r) description;
    manipulators = [
      ({
          type = "basic";
          from = {
            key_code = r.from;
            modifiers.optional = ["any"];
          };
          to = [r.to];
        }
        // lib.optionalAttrs (r ? alone) {to_if_alone = [r.alone];})
    ];
  };
  capsRule = mkKarabinerRule {
    description = "Caps Lock → ⌘⌥ super-modifier (hold) / Caps Lock (tap)";
    from = "caps_lock";
    to = {
      key_code = "left_command";
      modifiers = ["left_option"];
    };
    alone = {
      hold_down_milliseconds = 100;
      key_code = "caps_lock";
    };
  };

  # Leader-role documentation block derived from the ranked layer rows: ASCII fields pad by byte width, glyph fields by modifier count, so a new
  # layer lands aligned with zero curated padding; every fragment line carries its full emitted indentation.
  headerRoles = ["Primary" "Secondary" "Tertiary" "Quaternary"];
  headerComment = let
    rows = layersByRank (a: b: a > b);
    roles = headerRoles;
    pad = n: lib.strings.replicate (lib.max 0 n) " ";
    padTo = w: s: s + pad (w - lib.stringLength s);
    roleW = 2 + lib.foldl' lib.max 0 (map (r: lib.stringLength "${r} Modifier:") (lib.take (builtins.length rows) roles));
    physW = 3 + lib.foldl' lib.max 0 (map (l: lib.stringLength l.physical) rows);
    maxG = lib.foldl' lib.max 0 (map (l: builtins.length l.mods) rows);
    maxN = lib.foldl' lib.max 0 (map (l: lib.stringLength l.name) rows);
    line = role: l:
      "    // "
      + padTo roleW "${role} Modifier:"
      + padTo physW l.physical
      + "→ ${l.name} (${l.glyphs})"
      + pad ((maxG - builtins.length l.mods) + (maxN - lib.stringLength l.name) + 2)
      + "leader | ${l.zellij}";
  in
    lib.concatStringsSep "\n" (lib.zipListsWith line roles rows);

  # --- [MODE_TABLE]
  # One row per zellij mode reachable from a Hyper leader key; entryOrder and ribbonOrder are curated presentation sequences over the same rows.
  modes = lib.mapAttrs (_: row ["key" "ribbon" "rank" "exitKey"]) {
    pane = ["p" "pane" 30];
    tab = ["t" "tab" 40];
    resize = ["r" "resize" 50];
    scroll = ["s" "scroll" 60];
    session = ["o" "session" 70];
    move = ["m" "move" 80];
    tmux = ["b" null 90];
    locked = ["g" "lock" null "l"];
  };
  entryOrder = ["pane" "resize" "scroll" "session" "tab" "move" "tmux"];
  ribbonOrder = ["pane" "tab" "resize" "move" "scroll" "session" "locked"];

  # --- [BIND_ROWS]
  # Bind tuple: [keys kdl label forgot ribbon] — keys is one key or an alias list, forgot/ribbon are [label rank] or [label display|key rank].
  # An attrset escape carries the tuple as `t` plus verbatim extras: body (multi-line KDL at emitted indentation) XOR kdl, gap (blank line
  # before).
  mkBind = spec: let
    base =
      if lib.isList spec
      then {t = spec;}
      else spec;
    r = row ["keys" "kdl" "label" "forgot" "ribbon"] base.t;
  in
    (removeAttrs base ["t"])
    // (removeAttrs r ["keys" "forgot" "ribbon"])
    // {keys = lib.toList r.keys;}
    // lib.optionalAttrs (r ? forgot) {forgot = mkForgot r.forgot;}
    // lib.optionalAttrs (r ? ribbon) {ribbon = mkRibbon r.ribbon;};
  hyperRows = map mkBind [
    [modes.locked.key ''SwitchToMode "Locked";'' "locked mode" ["lock" 10]]
    ["[" "PreviousSwapLayout;" null ["swap layout prev/next" "Hyper [ / Hyper ]" 100]]
    ["]" "NextSwapLayout;"]
    {
      # Which-key sheet: the body interpolates forgotKdl, which reads only the forgot metadata of these rows — laziness keeps the knot well-founded.
      t = [cheatsheetKey null null ["cheatsheet" 120]];
      body = cheatsheetBody;
    }
  ];

  # Normal-mode layer: macOS Command chords zellij receives because WezTerm full-passes them (no default keybinds; weztermRows claims neither).
  normalRows = map (t: let
    r = row ["key" "action" "comment" "forgot"] t;
  in
    r // {forgot = mkForgot r.forgot;}) [
    ["t" "NewTab;" "Create new tab without entering tab mode" ["new tab" 130]]
    ["w" "CloseFocus;" "Close pane without entering pane mode" ["close pane" 140]]
  ];

  superRows = map mkBind [
    ["[" "GoToPreviousTab;" null ["previous/next tab" "Super Alt Ctrl [ / ]" 170] ["tab ±" "[ ]" 50]]
    ["]" "GoToNextTab;"]
    {
      t = ["f" "ToggleFloatingPanes;" null ["toggle floating panes" 190] ["float" 30]];
      gap = true;
    }
    ["n" "NewPane;" null ["new pane" 180] ["pane" 20]]
    {
      t = [["h" "Left"] ''MoveFocusOrTab "Left";'' null ["move focus" "Super Alt Ctrl h/j/k/l" 200]];
      gap = true;
    }
    [["l" "Right"] ''MoveFocusOrTab "Right";'']
    [["j" "Down"] ''MoveFocus "Down";'']
    [["k" "Up"] ''MoveFocus "Up";'']
    [["=" "+"] ''Resize "Increase";'' null ["resize" "Super Alt Ctrl = / -" 210]]
    ["-" ''Resize "Decrease";'']
    ["p" "TogglePaneInGroup;" null ["pane group toggle/mark" "Super Alt Ctrl p / g" 220]]
    ["g" "ToggleGroupMarking;"]
  ];

  # Layer-keyed bind vocabulary: every per-layer projection folds over this attrset, so a new leader layer is one `layers` row plus one entry here.
  bindRows = {
    hyper = hyperRows;
    super = superRows;
  };

  # Which-key rows with no chord of their own: command vocabulary surfaced in the cheatsheet beside the chords.
  forgotExtras = map (row ["rank" "label" "display"]) [
    [230 "editor" "code <path> / code -g <file>:<line>"]
    [260 "json explore" "jqi -> jnv"]
    [270 "loc report" "loc <path>"]
    [280 "folder map" "tree <path>"]
    [290 "deploy" "redeploy build / switch"]
    [300 "http" "GET/POST/PUT -> xh"]
  ];

  # --- [WEZTERM_OUTER_LAYER]
  # Typed outer-terminal rows: native left-Command chords, the CMD|SHIFT overlay/deck layer, and pass-through-aware CTRL pane nav; the wezterm
  # owner projects them into rows.lua and `id` doubles as the dispatch action. Tuple tail is [frank flabel fdisplay destructive]: forgot
  # label/display default from the row, `destructive` rows confirm before acting, and every leader chord still passes to zellij untouched.
  weztermModGlyph = lib.listToAttrs (map (m: lib.nameValuePair m.wez m.glyph) modVocab);
  weztermDisplay = row: let
    glyphs = lib.concatMapStrings (m: weztermModGlyph.${m}) (lib.reverseList (lib.splitString "|" row.mods));
    keyLabel =
      if lib.stringLength row.key == 1
      then lib.toUpper row.key
      else row.key;
  in "${glyphs}${keyLabel}";
  mkWez = t: let
    r = row ["id" "key" "mods" "label" "class" "frank" "flabel" "fdisplay" "destructive"] t;
  in
    (removeAttrs r ["frank" "flabel" "fdisplay"])
    // {action = r.id;}
    // lib.optionalAttrs (r ? frank) {
      forgot = lib.filterAttrs (_: v: v != null) {
        rank = r.frank;
        label = r.flabel or null;
        display = r.fdisplay or null;
      };
    };
  weztermRows = map mkWez [
    # Native macOS vocabulary (left Command).
    ["copy" "c" "CMD" "copy" "native"]
    ["paste" "v" "CMD" "paste" "native"]
    ["spawn-window" "n" "CMD" "new window" "native"]
    ["quit" "q" "CMD" "quit wezterm" "native"]
    ["hide-app" "h" "CMD" "hide app" "native"]
    ["minimize" "m" "CMD" "minimize" "native"]
    ["font-inc" "=" "CMD" "font size +" "native"]
    ["font-dec" "-" "CMD" "font size -" "native"]
    ["font-reset" "0" "CMD" "font size reset" "native"]
    ["reload" "r" "CMD" "reload config" "native"]
    # Overlay layer: native pickers and diagnostics.
    ["palette" "p" "CMD|SHIFT" "wezterm palette" "overlay" 310]
    ["quick-select" "Space" "CMD|SHIFT" "wezterm quick select" "overlay" 320]
    ["launcher" "l" "CMD|SHIFT" "wezterm launcher" "overlay" 330]
    ["char-select" "u" "CMD|SHIFT" "wezterm unicode picker" "overlay" 340]
    ["debug-overlay" "d" "CMD|SHIFT" "wezterm debug overlay" "overlay" 350]
    # Command deck: workspace router, guarded broadcast.
    ["workspace-switch" "o" "CMD|SHIFT" "wezterm workspace switch" "deck" 360]
    ["workspace-new" "n" "CMD|SHIFT" "wezterm workspace new" "deck" 365]
    ["sync-toggle" "e" "CMD|SHIFT" "wezterm sync panes" "deck" 370 null null true]
    # Pass-through-aware pane nav: raw bytes into zellij panes, WezTerm pane motion in plain splits.
    ["nav-left" "h" "CTRL" "pane nav left" "nav" 380 "wezterm pane nav" "⌃H/J/K/L (plain splits)"]
    ["nav-down" "j" "CTRL" "pane nav down" "nav"]
    ["nav-up" "k" "CTRL" "pane nav up" "nav"]
    ["nav-right" "l" "CTRL" "pane nav right" "nav"]
  ];
  weztermForgot =
    lib.concatMap (
      r:
        lib.optional (r ? forgot) {
          rank = r.forgot.rank;
          label = r.forgot.label or r.label;
          display = r.forgot.display or (weztermDisplay r);
        }
    )
    weztermRows;

  # --- [PROJECTIONS]
  # Every table string emitted inside a KDL quoted string passes through this.
  kdlEsc = lib.replaceStrings ["\\" "\""] ["\\\\" "\\\""];
  cheatsheetKey = "/";

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
        rank = 20;
        label = "unlock (locked)";
        display = "${layers.hyper.display} ${modes.locked.exitKey}";
      }
    ]
    ++ map (m: {
      inherit (modes.${m}) rank;
      label = "${m} mode";
      display = "${layers.hyper.display} ${modes.${m}.key}";
    }) (lib.filter (m: modes.${m} ? rank) (lib.attrNames modes));

  forgotRows =
    lib.sort (a: b: a.rank < b.rank)
    (modeForgot
      ++ lib.concatLists (lib.mapAttrsToList (n: forgotOf layers.${n}.display) bindRows)
      ++ map (r: r.forgot // {display = "Super ${r.key}";}) normalRows
      ++ forgotExtras
      ++ weztermForgot);

  forgotKdl =
    lib.concatMapStringsSep "\n"
    (r: "            \"${kdlEsc r.label}\" \"${kdlEsc r.display}\"")
    forgotRows;

  # KEY IDENTITY: a Shift-carrying layer receives shifted punctuation as the SHIFTED character, so its binds emit that glyph both with and without the
  # Shift modifier listed; letter keys and Shift-free layers pass through. The map is total over the ANSI shifted row.
  shiftedGlyph = let
    plain = ["`" "1" "2" "3" "4" "5" "6" "7" "8" "9" "0" "-" "=" "[" "]" "\\" ";" "'" "," "." "/"];
    shifted = ["~" "!" "@" "#" "$" "%" "^" "&" "*" "(" ")" "_" "+" "{" "}" "|" ":" "\"" "<" ">" "?"];
  in
    lib.listToAttrs (lib.zipListsWith lib.nameValuePair plain shifted);
  stripShift = prefix: lib.concatStringsSep " " (lib.filter (w: w != "Shift") (lib.splitString " " prefix));
  bindKeys = prefix: k:
    if lib.hasInfix "Shift" prefix && shiftedGlyph ? ${k}
    then ["${prefix} ${kdlEsc shiftedGlyph.${k}}" "${stripShift prefix} ${kdlEsc shiftedGlyph.${k}}"]
    else ["${prefix} ${kdlEsc k}"];

  renderBind = prefix: row: let
    keysStr = lib.concatMapStringsSep " " (s: "\"${s}\"") (lib.concatMap (bindKeys prefix) row.keys);
  in
    lib.concatStrings [
      (lib.optionalString (row.gap or false) "\n")
      (
        if row ? body
        then "        bind ${keysStr} {\n${row.body}\n        }"
        else "        bind ${keysStr} { ${row.kdl} }"
      )
    ];

  cheatsheetBody = lib.concatStringsSep "\n" [
    "          LaunchOrFocusPlugin \"zellij-forgot\" {"
    "            \"LOAD_ZELLIJ_BINDINGS\" \"false\""
    forgotKdl
    "            floating true"
    "            move_to_focused_tab true"
    "          };"
    "          SwitchToMode \"Normal\""
  ];

  bindsKdl = lib.mapAttrs (n: lib.concatMapStringsSep "\n" (renderBind layers.${n}.zellij)) bindRows;

  renderNormal = r:
    lib.concatStringsSep "\n" [
      "        bind \"Super ${r.key}\" {            // ${r.comment}"
      "          ${r.action}"
      "          SwitchToMode \"Normal\";"
      "        }"
    ];
  normalBindsKdl = lib.concatMapStringsSep "\n" renderNormal normalRows;

  entryBindsKdl = lib.concatMapStringsSep "\n" (m:
    lib.concatStringsSep "\n" [
      "      shared_except \"${m}\" \"locked\" {"
      "        bind \"${layers.hyper.zellij} ${modes.${m}.key}\" { SwitchToMode \"${lib.strings.toSentenceCase m}\"; }"
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

  # Ribbon hint chips for the layers that carry bind rows, rank-descending.
  hintsRight =
    lib.concatMapStringsSep " · " (l: "${l.chip} ${lib.toLower l.name}")
    (lib.sort (a: b: a.rank > b.rank) (map (n: layers.${n}) (lib.attrNames bindRows)))
    + " ";

  # --- [REGISTER_PROJECTION]
  # Typed chord rows for the register rail: every consumer's chords in one vocabulary — chord_id, consumer,
  # physical_layer, mods, key, label, action, scope (the KDL mode block or OS/app plane the claim is active in),
  # toggle (re-press exits the mode), projection_path, and rendered evidence.
  zjRegRow = layer: row: {
    chord_id = "zellij:${lib.toLower layer.name}:${builtins.head row.keys}";
    consumer = "zellij";
    physical_layer = layer.name;
    mods = layer.zellij;
    key = lib.concatStringsSep "," row.keys;
    label = row.label or row.forgot.label or row.ribbon.label or row.kdl or "bound action";
    action = row.kdl or row.body or "";
    scope = "shared_except locked";
    projection_path = ".config/zellij/config.kdl";
    rendered = renderBind layer.zellij row;
  };
  modeRegRows =
    map (m: {
      chord_id = "zellij:hyper:${modes.${m}.key}";
      consumer = "zellij";
      physical_layer = layers.hyper.name;
      mods = layers.hyper.zellij;
      key = modes.${m}.key;
      label = "${m} mode";
      action = "SwitchToMode \"${lib.strings.toSentenceCase m}\";";
      scope = "shared_except ${m} locked";
      toggle = true;
      projection_path = ".config/zellij/config.kdl";
      rendered = "bind \"${layers.hyper.zellij} ${modes.${m}.key}\" { SwitchToMode \"${lib.strings.toSentenceCase m}\"; }";
    })
    entryOrder;
  # The unlock chord lives only in the locked block (config.nix consumes modes.locked.exitKey); without this row the register misses a live bind.
  lockedExitRow = {
    chord_id = "zellij:hyper:${modes.locked.exitKey}";
    consumer = "zellij";
    physical_layer = layers.hyper.name;
    mods = layers.hyper.zellij;
    key = modes.locked.exitKey;
    label = "unlock (locked mode)";
    action = "SwitchToMode \"Normal\";";
    scope = "locked";
    projection_path = ".config/zellij/config.kdl";
    rendered = "bind \"${layers.hyper.zellij} ${modes.locked.exitKey}\" { SwitchToMode \"Normal\"; }";
  };
  register =
    lib.concatLists (lib.mapAttrsToList (n: map (zjRegRow layers.${n})) bindRows)
    ++ map (r: {
      chord_id = "zellij:normal:${r.key}";
      consumer = "zellij";
      physical_layer = "none";
      mods = "Super";
      label = r.forgot.label or r.comment;
      inherit (r) key action;
      scope = "normal";
      projection_path = ".config/zellij/config.kdl";
      rendered = renderNormal r;
    })
    normalRows
    ++ modeRegRows
    ++ [
      lockedExitRow
      {
        chord_id = "karabiner:caps_lock";
        consumer = "karabiner";
        physical_layer = "Caps Lock";
        mods = "";
        key = "caps_lock";
        label = "⌘⌥ super-modifier (hold) / Caps Lock (tap)";
        action = builtins.toJSON capsRule.manipulators;
        scope = "os";
        projection_path = ".config/karabiner/karabiner.json";
        rendered = builtins.toJSON capsRule;
      }
    ]
    ++ map (l: {
      chord_id = "karabiner:${l.from}";
      consumer = "karabiner";
      physical_layer = l.physical;
      mods = "";
      key = l.from;
      label = "${l.physical} → ${l.name} (${l.glyphs}) leader";
      action = builtins.toJSON l.to;
      scope = "os";
      projection_path = ".config/karabiner/karabiner.json";
      rendered = builtins.toJSON l.to;
    }) (lib.attrValues layers)
    ++ map (r: {
      chord_id = "wezterm:${r.id}";
      consumer = "wezterm";
      physical_layer = "none";
      inherit (r) mods key label action;
      scope =
        if r.class == "nav"
        then "app passthrough:zellij"
        else "app";
      projection_path = ".config/wezterm/rows.lua";
      rendered = weztermDisplay r;
    })
    weztermRows;
in {
  options.forge.chords = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      inherit layers modes register;
      wezterm.rows = weztermRows;
      karabiner.rules =
        [capsRule]
        ++ map (l:
          mkKarabinerRule {
            description = "${l.physical} → ${l.name} (${l.glyphs}) leader";
            inherit (l) from to;
          }) (layersByRank (a: b: a < b));
      zellij = {
        inherit headerComment normalBindsKdl entryBindsKdl hintsRight;
        hyperBindsKdl = bindsKdl.hyper;
        superBindsKdl = bindsKdl.super;
        prefix = lib.mapAttrs (_: l: l.zellij) layers;
        ribbon = {
          hyperGroup = ribbonHyperGroup;
          superGroup = ribbonSuperGroup;
        };
      };
    };
    description = "Chord-vocabulary owner: leader layers, zellij binds, which-key, ribbon, and register rows.";
  };
}
