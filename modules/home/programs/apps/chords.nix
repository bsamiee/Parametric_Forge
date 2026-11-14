{lib, ...}: let
  # --- [ROW_GRAMMAR]
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
      power = ["Power" "Right Shift" "R⇧" 10 "right_shift" "left_option" ["left_control" "left_shift"]];
    });
  layersByRank = dir: lib.sort (a: b: dir a.rank b.rank) (lib.attrValues layers);

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
    ["i" "ToggleSessionCard;" null ["attention inbox" 104]]
    ["n" "GoToNextAttention;" null ["next pane that needs you" 106]]
    ["[" "PreviousSwapLayout;" null ["swap layout prev/next" "Hyper [ / Hyper ]" 100]]
    ["]" "NextSwapLayout;"]
    {
      t = [cheatsheetKey null null ["cheatsheet" 120]];
      body = cheatsheetBody;
    }
  ];

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

  bindRows = {
    hyper = hyperRows;
    super = superRows;
  };

  forgotExtras = map (row ["rank" "label" "display"]) [
    [230 "editor" "code <path> / code -g <file>:<line>"]
    [270 "loc report" "loc <path>"]
    [280 "folder map" "tree <path>"]
    [290 "deploy" "redeploy build / switch"]
    [300 "http" "GET/POST/PUT -> xh"]
  ];

  # --- [WEZTERM_OUTER_LAYER]
  weztermModGlyph = lib.listToAttrs (map (m: lib.nameValuePair m.wez m.glyph) modVocab);
  weztermDisplay = row: let
    glyphs = lib.concatMapStrings (m: weztermModGlyph.${m}) (lib.reverseList (lib.splitString "|" row.mods));
    keyLabel =
      if lib.stringLength row.key == 1
      then lib.toUpper row.key
      else row.key;
  in "${glyphs}${keyLabel}";
  mkWez = t: let
    r = row ["id" "key" "mods" "label" "frank" "flabel" "fdisplay"] t;
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
    ["copy" "c" "CMD" "copy"]
    ["paste" "v" "CMD" "paste"]
    ["spawn-window" "n" "CMD" "new window"]
    ["quit" "q" "CMD" "quit wezterm"]
    ["hide-app" "h" "CMD" "hide app"]
    ["minimize" "m" "CMD" "minimize"]
    ["font-inc" "=" "CMD" "font size +"]
    ["font-dec" "-" "CMD" "font size -"]
    ["font-reset" "0" "CMD" "font size reset"]
    ["reload" "r" "CMD" "reload config"]
    ["palette" "p" "CMD|SHIFT" "wezterm palette" 310]
    ["quick-select" "Space" "CMD|SHIFT" "wezterm quick select" 320]
    ["launcher" "l" "CMD|SHIFT" "wezterm launcher" 330]
    ["char-select" "u" "CMD|SHIFT" "wezterm unicode picker" 340]
    ["debug-overlay" "d" "CMD|SHIFT" "wezterm debug overlay" 350]
    ["workspace-switch" "o" "CMD|SHIFT" "wezterm workspace switch" 360]
    ["workspace-new" "n" "CMD|SHIFT" "wezterm workspace new" 365]
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
    lib.concatMapStringsSep " · " (l: "${l.chip} ${lib.toLower l.name}")
    (lib.sort (a: b: a.rank > b.rank) (map (n: layers.${n}) (lib.attrNames bindRows)))
    + " ";
in {
  _module.args.chords = {
    inherit layers modes;
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
}
