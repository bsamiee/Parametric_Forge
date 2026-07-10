# Title         : chords.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/chords.nix
# ----------------------------------------------------------------------------
# Single chord-vocabulary owner: physical leader layers, zellij leader binds, mode table, which-key rows, ribbon hints, and per-consumer register
# rows are ONE parameterized table projected into karabiner JSON, zellij KDL, zellij-forgot content, WezTerm rows.lua, nvim chords.lua, and the
# VS Code keybindings sentinel tail. A new bind is one row here; consumers never hand-duplicate chords.
{
  config,
  lib,
  ...
}: let
  # --- [ROW_GRAMMAR]
  # Positional tuples zip against a field schema: a short tuple drops trailing fields, null skips a slot, and an oversized tuple faults —
  # zipListsWith would truncate silently otherwise.
  row = fields: t:
    lib.throwIf (builtins.length t > builtins.length fields)
    "chords row ${builtins.toJSON t} exceeds schema [${lib.concatStringsSep " " fields}]"
    (lib.filterAttrs (_: v: v != null) (lib.listToAttrs (lib.zipListsWith lib.nameValuePair fields t)));
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
  # Karabiner rewrites right-hand modifiers into leader stacks; zellij consumes each stack as the derived modifier set. Power carries no zellij
  # binds (yazi owns it) and WezTerm claims no layer — its outer keys live in weztermRows. Glyphs, the zellij prefix, the kitty CSI-u bitmask,
  # and the WezTerm glyph map all derive from the karabiner `to` row through this vocabulary; `rank` orders the emitted rule document, `display`
  # overrides the cheatsheet prefix.
  modVocab = map (row ["kc" "word" "wez" "glyph" "bit"]) [
    ["left_command" "Super" "CMD" "⌘" 8]
    ["left_option" "Alt" "ALT" "⌥" 2]
    ["left_control" "Ctrl" "CTRL" "⌃" 4]
    ["left_shift" "Shift" "SHIFT" "⇧" 1]
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
          csi = lib.foldl' (a: m: a + m.bit) 1 mods;
          display = l.display or zellij;
        }
    ) (lib.mapAttrs (_: mkLayer) {
      hyper = ["Hyper" "Right Command" "R⌘" 30 "right_command" "left_shift" ["left_command" "left_control" "left_option"] "Hyper"];
      super = ["Super" "Right Option" "R⌥" 20 "right_option" "left_control" ["left_command" "left_option"]];
      power = ["Power" "Right Shift" "R⇧" 10 "right_shift" "left_option" ["left_control" "left_shift"]];
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
  # An attrset escape carries the tuple as `t` plus verbatim extras: body (multi-line KDL at emitted indentation) XOR kdl, pre (emitted comment
  # lines), gap (blank line before), id (exports zellij.ids.<id> {key, mods} for runtime chord injection). Floating Run bodies render geometry
  # from the zellij popup-geometry owner, never inline percent literals.
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
  popupGeometry = config.programs.zellij.popupGeometry;
  runFloat = cmdWords: g:
    lib.concatStringsSep "\n" [
      "          Run ${lib.concatMapStringsSep " " (w: "\"${w}\"") cmdWords} {"
      "            floating true"
      "            close_on_exit true"
      "            x \"${g.x}\""
      "            y \"${g.y}\""
      "            width \"${g.width}\""
      "            height \"${g.height}\""
      "          }"
    ];
  hyperRows = map mkBind [
    [modes.locked.key ''SwitchToMode "Locked";'' "locked mode" ["lock" 10]]
    ["q" "Quit;" null ["quit zellij" 110]]
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
      t = ["y" null null ["yazi popup" 150] ["files" 10]];
      id = "yaziToggle";
      body = runFloat ["forge-yazi.sh" "toggle"] popupGeometry.dispatcher;
      pre = lib.concatStringsSep "\n" [
        "        // Floating dispatcher: toggles the per-tab Yazi popup (create /"
        "        // show+focus / hide). Never in_place: an attached client on 0.44.3"
        "        // strands exited in-place panes and their suppressed hosts."
      ];
    }
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
    {
      t = ["b" null null ["register browser" 160] ["browse" 40]];
      gap = true;
      body = runFloat ["forge-browse"] popupGeometry.browse;
    }
    {
      t = ["s" null null ["workspace graph" 162] ["graph" 45]];
      body = runFloat ["forge-zellij" "graph"] popupGeometry.graph;
    }
    {
      # Cheatsheet-only discoverability: the ribbon stays inside ~160 columns.
      t = ["w" null null ["watch panels" 164]];
      body = runFloat ["forge-zellij" "watch"] popupGeometry.watchPicker;
    }
  ];

  # Layer-keyed bind vocabulary: every per-layer projection folds over this attrset, so a new leader layer is one `layers` row plus one entry here.
  bindRows = {
    hyper = hyperRows;
    super = superRows;
  };

  # Which-key rows with no chord of their own: command vocabulary surfaced in the cheatsheet beside the chords.
  forgotExtras = map (row ["rank" "label" "display"]) [
    [230 "editor" "nv / vim -> nvim"]
    [240 "file manager" "y -> yazi popup (Super Alt Ctrl y)"]
    [250 "git ui" "lazygit float (pane mode w)"]
    [260 "json explore" "jqi -> jnv"]
    [270 "loc report" "loc <path>"]
    [280 "folder map" "tree <path>"]
    [290 "deploy" "forge-redeploy --check-only / --build / --switch"]
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
    # Command deck: workspace router, attention router, guarded broadcast.
    ["workspace-switch" "o" "CMD|SHIFT" "wezterm workspace switch" "deck" 360]
    ["workspace-new" "n" "CMD|SHIFT" "wezterm workspace new" "deck" 365]
    ["attention-focus" "a" "CMD|SHIFT" "jump to waiting agent" "deck" 368]
    ["sync-toggle" "e" "CMD|SHIFT" "wezterm sync panes" "deck" 370 null null true]
    # Pass-through-aware pane nav: Neovim window motion inside nvim panes, raw bytes into zellij panes, WezTerm pane motion in plain splits.
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

  # --- [NEOVIM_EDITOR_DOMAIN_TABLE]
  # One editor chord vocabulary keyed by domain; the nvim module projects it into lua/forge/chords.lua. `<cmd>…` targets land as native command
  # strings, bare names as dispatch-table fns (keymaps.lua binds both); mode defaults to ["n"]. Plugin README maps never leak in.
  mkNvim = t: let
    r = row ["keys" "target" "desc" "mode"] t;
  in
    (removeAttrs r ["target"])
    // (
      if lib.hasPrefix "<cmd>" r.target
      then {action = r.target;}
      else {fn = r.target;}
    );
  nvimDomains = lib.mapAttrs (_: map mkNvim) {
    files = [
      ["<leader>ff" "pick_files" "Find files"]
      ["<leader>fr" "pick_recent" "Recent files"]
      ["<leader>fb" "pick_buffers" "Pick buffer"]
    ];
    search = [
      ["<leader>sg" "pick_grep" "Live grep"]
      ["<leader>sw" "pick_grep_word" "Grep word/selection" ["n" "x"]]
      ["<leader>sr" "pick_resume" "Resume last picker"]
      ["<leader>sh" "pick_help" "Help pages"]
      ["<leader>sk" "pick_keymaps" "Keymaps"]
    ];
    buffers = [
      ["<leader>bn" "<cmd>bnext<cr>" "Next buffer"]
      ["<leader>bp" "<cmd>bprevious<cr>" "Previous buffer"]
      ["<leader>bb" "<cmd>e #<cr>" "Switch to other buffer"]
      ["<leader>bd" "bufdelete" "Delete buffer"]
      ["<A-w>" "bufdelete" "Delete buffer"]
      ["<leader>ba" "bufdelete_all" "Delete all buffers"]
      ["<leader>bo" "bufdelete_other" "Delete other buffers"]
      ["<leader>bz" "zen" "Toggle zen mode"]
    ];
    diagnostics = [
      ["<leader>xx" "<cmd>Trouble diagnostics toggle<cr>" "Diagnostics (Trouble)"]
      ["<leader>xb" "<cmd>Trouble diagnostics toggle filter.buf=0<cr>" "Buffer diagnostics (Trouble)"]
      ["<leader>xs" "<cmd>Trouble symbols toggle focus=false<cr>" "Symbols (Trouble)"]
      ["<leader>xq" "<cmd>Trouble qflist toggle<cr>" "Quickfix (Trouble)"]
      ["<leader>xl" "<cmd>Trouble loclist toggle<cr>" "Location list (Trouble)"]
    ];
    lsp = [
      ["gd" "lsp_definitions" "Goto definition"]
      ["gr" "lsp_references" "References"]
      ["gI" "lsp_implementations" "Goto implementation"]
      ["gy" "lsp_type_definitions" "Goto type definition"]
      ["<leader>cs" "lsp_symbols" "Document symbols"]
      ["<leader>cS" "lsp_workspace_symbols" "Workspace symbols"]
      ["<leader>cr" "lsp_rename" "Rename symbol"]
      ["<leader>ca" "code_action" "Code action" ["n" "x"]]
      ["<leader>cf" "format" "Format buffer/range" ["n" "x"]]
    ];
    estate = [
      ["<leader>ee" "pick_estate" "Nix estate actions"]
    ];
    refactor = [
      ["<leader>rr" "grug_open" "Search and replace (grug-far)" ["n" "x"]]
      ["<leader>rw" "grug_word" "Replace word under cursor"]
    ];
    tasks = [
      ["<leader>tt" "<cmd>OverseerToggle<cr>" "Task list (overseer)"]
      ["<leader>tr" "<cmd>OverseerRun<cr>" "Run task (overseer)"]
    ];
    git = [
      ["<leader>gb" "git_blame_line" "Blame line"]
      ["<leader>gB" "git_browse" "Open repo in browser" ["n" "x"]]
    ];
  };
  nvimRows =
    lib.concatLists
    (lib.mapAttrsToList
      (domain: rows: map (r: r // {inherit domain;} // {mode = r.mode or ["n"];}) rows)
      nvimDomains);
  nvimMods = keys:
    if lib.hasPrefix "<leader>" keys
    then "Leader"
    else if lib.hasPrefix "<A-" keys
    then "Alt"
    else "";
  nvimRegRows =
    map (r: {
      chord_id = "nvim:${r.domain}:${r.keys}";
      consumer = "nvim";
      physical_layer = "none";
      mods = nvimMods r.keys;
      key = r.keys;
      label = r.desc;
      action = r.action or r.fn;
      scope = "editor:${lib.concatStringsSep "," r.mode}";
      projection_path = ".config/nvim/lua/forge/chords.lua";
      rendered = builtins.toJSON r;
    })
    nvimRows;

  # --- [VSCODE_EDITOR_ROWS]
  # One nav vocabulary drives terminal AND editor: the weztermRows nav class is the source and each editor twin derives per row — a new direction is one
  # wezterm row whose VS Code twin lands with it or breaks loudly on a missing dispatch arm. `!terminalFocus` keeps the terminal raw so zellij under it
  # navigates as under wezterm; `shadows` names the displaced mac editor default. Layer chords sit on 4-modifier combos VS Code ships none for; the
  # sentinel tail keeps hand rows alive (HM's keybindings option writes a read-only symlink); a non-nav bind is one extra-lane tuple, `args` its command payload.
  vscodeNavCommand = {
    nav-left = "workbench.action.navigateLeft";
    nav-down = "workbench.action.navigateDown";
    nav-up = "workbench.action.navigateUp";
    nav-right = "workbench.action.navigateRight";
  };
  vscodeNavShadows = {
    nav-down = "editor.action.joinLines";
    nav-up = "deleteAllRight";
    nav-right = "notebook.centerActiveCell";
  };
  vscodeRows =
    map (r:
      {
        key = "ctrl+${r.key}";
        command = vscodeNavCommand.${r.action};
        when = "!terminalFocus";
        label = "focus ${lib.removePrefix "nav-" r.action} (workbench plane)";
        mirror = "wezterm:${r.id}";
      }
      // lib.optionalAttrs (vscodeNavShadows ? ${r.action}) {shadows = vscodeNavShadows.${r.action};})
    (builtins.filter (r: r.class == "nav") weztermRows)
    ++ map (row ["key" "command" "when" "label" "mirror" "shadows" "args"]) [];
  # Projection-ready keybinding objects: exactly the fields VS Code reads.
  vscodeBindOf = r:
    {inherit (r) key command;}
    // lib.optionalAttrs (r ? when) {inherit (r) when;}
    // lib.optionalAttrs (r ? args) {inherit (r) args;};
  vscodeRegRows = map (r:
    {
      chord_id = "vscode:${r.key}";
      consumer = "vscode";
      physical_layer = "none";
      mods = "";
      inherit (r) key label;
      action = r.command;
      scope = "editor:${r.when or "global"}";
      projection_path = "Library/Application Support/Code/User/keybindings.json";
      rendered = builtins.toJSON (vscodeBindOf r);
    }
    // lib.optionalAttrs (r ? mirror) {inherit (r) mirror;}
    // lib.optionalAttrs (r ? shadows) {inherit (r) shadows;})
  vscodeRows;

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

  # KEY IDENTITY: a Shift-carrying layer receives shifted punctuation as the SHIFTED character, so its binds emit that glyph both with and
  # without the Shift modifier listed; letter keys and Shift-free layers pass through. The map is total over the ANSI shifted row,
  # capacity-asserted at the zip.
  shiftedGlyph = let
    plain = ["`" "1" "2" "3" "4" "5" "6" "7" "8" "9" "0" "-" "=" "[" "]" "\\" ";" "'" "," "." "/"];
    shifted = ["~" "!" "@" "#" "$" "%" "^" "&" "*" "(" ")" "_" "+" "{" "}" "|" ":" "\"" "<" ">" "?"];
  in
    lib.throwIf (builtins.length plain != builtins.length shifted)
    "chords shiftedGlyph rows diverge: ${toString (builtins.length plain)} plain vs ${toString (builtins.length shifted)} shifted"
    (lib.listToAttrs (lib.zipListsWith lib.nameValuePair plain shifted));
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
      (lib.optionalString (row ? pre) (row.pre + "\n"))
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

  # Id-tagged rows export {key, mods} (kitty CSI-u bitmask from the layer row) so runtime consumers inject the REAL chord bytes
  # without hand-duplicating the vocabulary.
  bindIds = layer: rows:
    lib.concatMap (
      r:
        lib.optional (r ? id) {
          name = r.id;
          value = {
            key = builtins.head r.keys;
            mods = layer.csi;
          };
        }
    )
    rows;
  ids = lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (n: bindIds layers.${n}) bindRows));

  # --- [REGISTER_PROJECTION]
  # Typed chord rows for the register rail: every consumer's chords in one vocabulary — chord_id, consumer, physical_layer, mods, key, label,
  # action, scope (the KDL mode block or OS/app plane the claim is active in), toggle (re-press exits the mode), projection_path, rendered
  # evidence, and CSI-u injection where exported.
  zjRegRow = layer: row:
    {
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
    }
    // lib.optionalAttrs (row ? id) {injection = ids.${row.id};};
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
        then "app passthrough:nvim,zellij"
        else "app";
      projection_path = ".config/wezterm/rows.lua";
      rendered = weztermDisplay r;
    })
    weztermRows
    ++ nvimRegRows
    ++ vscodeRegRows;

  # Intra-consumer conflict ledger: every emitted (consumer, chord) claim must be unique; shift-glyph expansion rides the same bindKeys the KDL
  # uses, the WezTerm outer layer stacks CMD and CMD|SHIFT on the same letters by design, and a vscode claim is key+when (disjoint when-contexts
  # are legal).
  dupesOf = xs: lib.attrNames (lib.filterAttrs (_: c: c > 1) (lib.foldl' (acc: x: acc // {${x} = (acc.${x} or 0) + 1;}) {} xs));
  claims = lib.concatMap (r:
    map (c: "${r.consumer}|${c}")
    (
      if r.consumer == "zellij"
      then lib.concatMap (bindKeys r.mods) (lib.splitString "," r.key)
      else if r.consumer == "wezterm"
      then ["${r.mods} ${r.key}"]
      else if r.consumer == "vscode"
      then ["${r.key}|${r.scope}"]
      else [r.key]
    ))
  register;
  conflictClaims = dupesOf claims;
  conflictIds = dupesOf (map (r: r.chord_id) register);
  # listToAttrs keeps the first occurrence: a duplicate injection id would shadow silently without this guard.
  conflictInjectionIds = dupesOf (lib.concatMap (rows: lib.concatMap (r: lib.optional (r ? id) r.id) rows) (lib.attrValues bindRows));
in {
  options.forge.chords = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      inherit layers modes register;
      nvim.rows = nvimRows;
      wezterm.rows = weztermRows;
      vscode.binds = map vscodeBindOf vscodeRows;
      karabiner.rules =
        [capsRule]
        ++ map (l:
          mkKarabinerRule {
            description = "${l.physical} → ${l.name} (${l.glyphs}) leader";
            inherit (l) from to;
          }) (layersByRank (a: b: a < b));
      zellij = {
        inherit headerComment normalBindsKdl entryBindsKdl hintsRight ids;
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

  config.assertions = [
    {
      assertion = conflictClaims == [];
      message = "forge.chords: conflicting chord claims: ${lib.concatStringsSep ", " conflictClaims}";
    }
    {
      assertion = conflictIds == [];
      message = "forge.chords: duplicate chord_id rows: ${lib.concatStringsSep ", " conflictIds}";
    }
    {
      assertion = conflictInjectionIds == [];
      message = "forge.chords: duplicate injection ids: ${lib.concatStringsSep ", " conflictInjectionIds}";
    }
    {
      # zipListsWith truncates: a layer past the role vocabulary would vanish from the headerComment silently instead of landing misdocumented.
      assertion = builtins.length (lib.attrValues layers) <= builtins.length headerRoles;
      message = "forge.chords: ${toString (builtins.length (lib.attrValues layers))} layers exceed the ${toString (builtins.length headerRoles)}-row headerRoles vocabulary; extend headerRoles.";
    }
  ];
}
