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
{
  config,
  lib,
  ...
}: let
  # --- Physical layers --------------------------------------------------------
  # Karabiner rewrites right-hand modifiers into leader stacks; zellij consumes
  # each stack as the derived `zellij` modifier set. Power carries no zellij
  # binds by design: it passes through to terminal apps (yazi owns it).
  # WezTerm claims NO layer: its outer-terminal keys live in the typed
  # weztermRows vocabulary below, so every leader chord passes to zellij
  # untouched. `rank` orders the emitted karabiner rule document; `display`
  # overrides the cheatsheet chord prefix (defaults to the zellij prefix).
  # Glyphs, the zellij prefix, the kitty CSI-u bitmask, and the WezTerm glyph
  # map all derive from the karabiner `to` row through the modifier
  # vocabulary — one source per layer, one glyph owner per modifier (`wez` is
  # the WezTerm mods-string spelling of the same physical modifier).
  modVocab = [
    {
      kc = "left_command";
      word = "Super";
      wez = "CMD";
      glyph = "⌘";
      bit = 8;
    }
    {
      kc = "left_option";
      word = "Alt";
      wez = "ALT";
      glyph = "⌥";
      bit = 2;
    }
    {
      kc = "left_control";
      word = "Ctrl";
      wez = "CTRL";
      glyph = "⌃";
      bit = 4;
    }
    {
      kc = "left_shift";
      word = "Shift";
      wez = "SHIFT";
      glyph = "⇧";
      bit = 1;
    }
  ];
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
    ) {
      hyper = {
        name = "Hyper";
        physical = "Right Command";
        chip = "R⌘";
        rank = 30;
        display = "Hyper";
        from = "right_command";
        to = {
          key_code = "left_shift";
          modifiers = ["left_command" "left_control" "left_option"];
        };
      };
      super = {
        name = "Super";
        physical = "Right Option";
        chip = "R⌥";
        rank = 20;
        from = "right_option";
        to = {
          key_code = "left_control";
          modifiers = ["left_command" "left_option"];
        };
      };
      power = {
        name = "Power";
        physical = "Right Shift";
        chip = "R⇧";
        rank = 10;
        from = "right_shift";
        to = {
          key_code = "left_option";
          modifiers = ["left_control" "left_shift"];
        };
      };
    };
  layersByRank = dir: lib.sort (a: b: dir a.rank b.rank) (lib.attrValues layers);

  # One manipulator grammar owns every karabiner rule: leader rewrites and the
  # Caps Lock dual-role are rows; `alone` adds the tap arm.
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

  # Leader-role documentation block derived from the ranked layer rows: ASCII
  # fields pad by byte width, glyph fields pad by modifier count (display
  # width), so a new layer lands aligned with zero curated padding. Every
  # fragment line carries its full emitted indentation; consumers interpolate
  # at their template's indent anchor.
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
  # lines), gap (blank line before), label (register label when no forgot/
  # ribbon row carries one), forgot {label, display?, rank}, ribbon
  # {label, key?, rank}, id (exports the row as zellij.ids.<id> {key, mods}
  # for runtime chord injection). Display strings derive from layer prefixes
  # unless a curated grouping overrides them.
  # Floating-popup Run bodies render geometry from the zellij popup-geometry
  # owner (programs.zellij.popupGeometry), never inline percent literals.
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
  hyperRows = [
    {
      keys = [modes.locked.key];
      kdl = ''SwitchToMode "Locked";'';
      label = "locked mode";
      forgot = {
        label = "lock";
        rank = 10;
      };
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
    {
      # Which-key sheet: the body interpolates forgotKdl, which reads only the
      # forgot metadata of these rows — laziness keeps the knot well-founded.
      keys = [cheatsheetKey];
      body = cheatsheetBody;
      forgot = {
        label = "cheatsheet";
        rank = 120;
      };
    }
  ];

  # Normal-mode simple layer: bare macOS Command chords zellij receives because
  # WezTerm full-passes them (no default keybinds; weztermRows claims neither).
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
      body = runFloat ["forge-yazi.sh" "toggle"] popupGeometry.dispatcher;
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
    {
      gap = true;
      keys = ["b"];
      body = runFloat ["forge-browse"] popupGeometry.browse;
      forgot = {
        label = "register browser";
        rank = 160;
      };
      ribbon = {
        label = "browse";
        rank = 40;
      };
    }
    {
      keys = ["s"];
      body = runFloat ["forge-zellij" "graph"] popupGeometry.graph;
      forgot = {
        label = "workspace graph";
        rank = 162;
      };
      ribbon = {
        label = "graph";
        rank = 45;
      };
    }
    {
      keys = ["w"];
      body = runFloat ["forge-zellij" "watch"] popupGeometry.watchPicker;
      # Cheatsheet-only discoverability: the ribbon stays inside ~160 columns,
      # so watch carries no ribbon chip.
      forgot = {
        label = "watch panels";
        rank = 164;
      };
    }
  ];

  # Layer-keyed bind vocabulary: every per-layer projection — KDL binds,
  # cheatsheet rows, ids, register rows, ribbon hint chips — folds over this
  # attrset, so a new leader layer is one `layers` row plus one entry here.
  bindRows = {
    hyper = hyperRows;
    super = superRows;
  };

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
  ];

  # --- WezTerm outer layer ------------------------------------------------------
  # Typed outer-terminal rows: WezTerm claims native left-Command chords plus
  # the CMD|SHIFT overlay/deck layer and pass-through-aware CTRL pane nav; the
  # wezterm owner projects them into generated key rows (rows.lua), `action` is
  # the semantic id its dispatch table resolves. `destructive` rows confirm
  # before acting; `forgot` rows surface in the cheatsheet; every leader chord
  # still passes to zellij untouched.
  weztermModGlyph = lib.listToAttrs (map (m: lib.nameValuePair m.wez m.glyph) modVocab);
  weztermDisplay = row: let
    glyphs = lib.concatMapStrings (m: weztermModGlyph.${m}) (lib.reverseList (lib.splitString "|" row.mods));
    keyLabel =
      if lib.stringLength row.key == 1
      then lib.toUpper row.key
      else row.key;
  in "${glyphs}${keyLabel}";
  weztermRows = [
    # Native macOS vocabulary (left Command).
    {
      id = "copy";
      key = "c";
      mods = "CMD";
      action = "copy";
      label = "copy";
      class = "native";
    }
    {
      id = "paste";
      key = "v";
      mods = "CMD";
      action = "paste";
      label = "paste";
      class = "native";
    }
    {
      id = "spawn-window";
      key = "n";
      mods = "CMD";
      action = "spawn-window";
      label = "new window";
      class = "native";
    }
    {
      id = "quit";
      key = "q";
      mods = "CMD";
      action = "quit";
      label = "quit wezterm";
      class = "native";
    }
    {
      id = "hide-app";
      key = "h";
      mods = "CMD";
      action = "hide-app";
      label = "hide app";
      class = "native";
    }
    {
      id = "minimize";
      key = "m";
      mods = "CMD";
      action = "minimize";
      label = "minimize";
      class = "native";
    }
    {
      id = "font-inc";
      key = "=";
      mods = "CMD";
      action = "font-inc";
      label = "font size +";
      class = "native";
    }
    {
      id = "font-dec";
      key = "-";
      mods = "CMD";
      action = "font-dec";
      label = "font size -";
      class = "native";
    }
    {
      id = "font-reset";
      key = "0";
      mods = "CMD";
      action = "font-reset";
      label = "font size reset";
      class = "native";
    }
    {
      id = "reload";
      key = "r";
      mods = "CMD";
      action = "reload";
      label = "reload config";
      class = "native";
    }
    # Overlay layer: native pickers and diagnostics.
    {
      id = "palette";
      key = "p";
      mods = "CMD|SHIFT";
      action = "palette";
      label = "wezterm palette";
      class = "overlay";
      forgot.rank = 310;
    }
    {
      id = "quick-select";
      key = "Space";
      mods = "CMD|SHIFT";
      action = "quick-select";
      label = "wezterm quick select";
      class = "overlay";
      forgot.rank = 320;
    }
    {
      id = "launcher";
      key = "l";
      mods = "CMD|SHIFT";
      action = "launcher";
      label = "wezterm launcher";
      class = "overlay";
      forgot.rank = 330;
    }
    {
      id = "char-select";
      key = "u";
      mods = "CMD|SHIFT";
      action = "char-select";
      label = "wezterm unicode picker";
      class = "overlay";
      forgot.rank = 340;
    }
    {
      id = "debug-overlay";
      key = "d";
      mods = "CMD|SHIFT";
      action = "debug-overlay";
      label = "wezterm debug overlay";
      class = "overlay";
      forgot.rank = 350;
    }
    # Command deck: workspace router and guarded broadcast.
    {
      id = "workspace-switch";
      key = "o";
      mods = "CMD|SHIFT";
      action = "workspace-switch";
      label = "wezterm workspace switch";
      class = "deck";
      forgot.rank = 360;
    }
    {
      id = "workspace-new";
      key = "n";
      mods = "CMD|SHIFT";
      action = "workspace-new";
      label = "wezterm workspace new";
      class = "deck";
      forgot.rank = 365;
    }
    {
      id = "sync-toggle";
      key = "e";
      mods = "CMD|SHIFT";
      action = "sync-toggle";
      label = "wezterm sync panes";
      class = "deck";
      destructive = true;
      forgot.rank = 370;
    }
    # Pass-through-aware pane nav: Neovim window motion inside nvim panes,
    # raw bytes into zellij panes, WezTerm pane motion in plain splits.
    {
      id = "nav-left";
      key = "h";
      mods = "CTRL";
      action = "nav-left";
      label = "pane nav left";
      class = "nav";
      forgot = {
        rank = 380;
        label = "wezterm pane nav";
        display = "⌃H/J/K/L (plain splits)";
      };
    }
    {
      id = "nav-down";
      key = "j";
      mods = "CTRL";
      action = "nav-down";
      label = "pane nav down";
      class = "nav";
    }
    {
      id = "nav-up";
      key = "k";
      mods = "CTRL";
      action = "nav-up";
      label = "pane nav up";
      class = "nav";
    }
    {
      id = "nav-right";
      key = "l";
      mods = "CTRL";
      action = "nav-right";
      label = "pane nav right";
      class = "nav";
    }
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

  # --- Neovim editor domain table ---------------------------------------------
  # One editor chord vocabulary keyed by domain; the nvim module projects it
  # into lua/forge/chords.lua. `action` carries a native command string; `fn`
  # names a row in the editor dispatch table (nvim config/keymaps.lua binds
  # both). Plugin README maps never leak in: every editor chord is a row here.
  nvimDomains = {
    files = [
      {
        keys = "<leader>ff";
        fn = "pick_files";
        desc = "Find files";
      }
      {
        keys = "<leader>fr";
        fn = "pick_recent";
        desc = "Recent files";
      }
      {
        keys = "<leader>fb";
        fn = "pick_buffers";
        desc = "Pick buffer";
      }
    ];
    search = [
      {
        keys = "<leader>sg";
        fn = "pick_grep";
        desc = "Live grep";
      }
      {
        keys = "<leader>sw";
        fn = "pick_grep_word";
        mode = ["n" "x"];
        desc = "Grep word/selection";
      }
      {
        keys = "<leader>sr";
        fn = "pick_resume";
        desc = "Resume last picker";
      }
      {
        keys = "<leader>sh";
        fn = "pick_help";
        desc = "Help pages";
      }
      {
        keys = "<leader>sk";
        fn = "pick_keymaps";
        desc = "Keymaps";
      }
    ];
    buffers = [
      {
        keys = "<leader>bn";
        action = "<cmd>bnext<cr>";
        desc = "Next buffer";
      }
      {
        keys = "<leader>bp";
        action = "<cmd>bprevious<cr>";
        desc = "Previous buffer";
      }
      {
        keys = "<leader>bb";
        action = "<cmd>e #<cr>";
        desc = "Switch to other buffer";
      }
      {
        keys = "<leader>bd";
        fn = "bufdelete";
        desc = "Delete buffer";
      }
      {
        keys = "<A-w>";
        fn = "bufdelete";
        desc = "Delete buffer";
      }
      {
        keys = "<leader>ba";
        fn = "bufdelete_all";
        desc = "Delete all buffers";
      }
      {
        keys = "<leader>bo";
        fn = "bufdelete_other";
        desc = "Delete other buffers";
      }
      {
        keys = "<leader>bz";
        fn = "zen";
        desc = "Toggle zen mode";
      }
    ];
    diagnostics = [
      {
        keys = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<cr>";
        desc = "Diagnostics (Trouble)";
      }
      {
        keys = "<leader>xb";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
        desc = "Buffer diagnostics (Trouble)";
      }
      {
        keys = "<leader>xs";
        action = "<cmd>Trouble symbols toggle focus=false<cr>";
        desc = "Symbols (Trouble)";
      }
      {
        keys = "<leader>xq";
        action = "<cmd>Trouble qflist toggle<cr>";
        desc = "Quickfix (Trouble)";
      }
      {
        keys = "<leader>xl";
        action = "<cmd>Trouble loclist toggle<cr>";
        desc = "Location list (Trouble)";
      }
    ];
    lsp = [
      {
        keys = "gd";
        fn = "lsp_definitions";
        desc = "Goto definition";
      }
      {
        keys = "gr";
        fn = "lsp_references";
        desc = "References";
      }
      {
        keys = "gI";
        fn = "lsp_implementations";
        desc = "Goto implementation";
      }
      {
        keys = "gy";
        fn = "lsp_type_definitions";
        desc = "Goto type definition";
      }
      {
        keys = "<leader>cs";
        fn = "lsp_symbols";
        desc = "Document symbols";
      }
      {
        keys = "<leader>cS";
        fn = "lsp_workspace_symbols";
        desc = "Workspace symbols";
      }
      {
        keys = "<leader>cr";
        fn = "lsp_rename";
        desc = "Rename symbol";
      }
      {
        keys = "<leader>ca";
        fn = "code_action";
        mode = ["n" "x"];
        desc = "Code action";
      }
      {
        keys = "<leader>cf";
        fn = "format";
        mode = ["n" "x"];
        desc = "Format buffer/range";
      }
    ];
    estate = [
      {
        keys = "<leader>ee";
        fn = "pick_estate";
        desc = "Nix estate actions";
      }
    ];
    refactor = [
      {
        keys = "<leader>rr";
        fn = "grug_open";
        mode = ["n" "x"];
        desc = "Search and replace (grug-far)";
      }
      {
        keys = "<leader>rw";
        fn = "grug_word";
        desc = "Replace word under cursor";
      }
    ];
    tasks = [
      {
        keys = "<leader>tt";
        action = "<cmd>OverseerToggle<cr>";
        desc = "Task list (overseer)";
      }
      {
        keys = "<leader>tr";
        action = "<cmd>OverseerRun<cr>";
        desc = "Run task (overseer)";
      }
    ];
    git = [
      {
        keys = "<leader>gb";
        fn = "git_blame_line";
        desc = "Blame line";
      }
      {
        keys = "<leader>gB";
        fn = "git_browse";
        mode = ["n" "x"];
        desc = "Open repo in browser";
      }
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

  # --- Projections ----------------------------------------------------------------
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

  # KEY IDENTITY: a Shift-carrying layer receives shifted punctuation as the
  # SHIFTED character, so its binds emit that glyph both with and without the
  # Shift modifier listed; letter keys and Shift-free layers pass through.
  # The map is total over the ANSI shifted row: any future punctuation bind
  # on a Shift layer renders correctly instead of silently never firing.
  shiftedGlyph = {
    "`" = "~";
    "1" = "!";
    "2" = "@";
    "3" = "#";
    "4" = "$";
    "5" = "%";
    "6" = "^";
    "7" = "&";
    "8" = "*";
    "9" = "(";
    "0" = ")";
    "-" = "_";
    "=" = "+";
    "[" = "{";
    "]" = "}";
    "\\" = "|";
    ";" = ":";
    "'" = "\"";
    "," = "<";
    "." = ">";
    "/" = "?";
  };
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

  # Id-tagged rows export {key, mods} (kitty CSI-u bitmask from the layer row)
  # so runtime consumers inject the REAL chord bytes without hand-duplicating
  # the vocabulary.
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

  # --- Register projection ----------------------------------------------------
  # Typed chord rows for the register rail: every consumer's chords in one
  # vocabulary — chord_id, consumer, physical_layer, mods, key, label, action,
  # scope (the KDL mode block or OS/app plane the claim is active in), toggle
  # (re-press of the same chord exits the mode), projection_path, rendered
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
  # The unlock chord lives only in the locked block (config.nix consumes
  # modes.locked.exitKey); without this row the register misses a live bind.
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
    ++ nvimRegRows;

  # Intra-consumer conflict ledger: every emitted (consumer, chord) claim must
  # be unique; shift-glyph expansion rides the same bindKeys the KDL uses.
  # WezTerm claims carry their modifier set — the outer layer stacks CMD and
  # CMD|SHIFT chords on the same letters by design.
  dupesOf = xs: lib.attrNames (lib.filterAttrs (_: c: c > 1) (lib.foldl' (acc: x: acc // {${x} = (acc.${x} or 0) + 1;}) {} xs));
  claims = lib.concatMap (r:
    map (c: "${r.consumer}|${c}")
    (
      if r.consumer == "zellij"
      then lib.concatMap (bindKeys r.mods) (lib.splitString "," r.key)
      else if r.consumer == "wezterm"
      then ["${r.mods} ${r.key}"]
      else [r.key]
    ))
  register;
  conflictClaims = dupesOf claims;
  conflictIds = dupesOf (map (r: r.chord_id) register);
  # listToAttrs keeps the first occurrence: a duplicate injection id would
  # shadow silently without this guard.
  conflictInjectionIds = dupesOf (lib.concatMap (rows: lib.concatMap (r: lib.optional (r ? id) r.id) rows) (lib.attrValues bindRows));
in {
  options.forge.chords = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      inherit layers modes register;
      nvim.rows = nvimRows;
      wezterm.rows = weztermRows;
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
      # zipListsWith truncates: a layer past the role vocabulary would vanish
      # from the headerComment silently instead of landing misdocumented.
      assertion = builtins.length (lib.attrValues layers) <= builtins.length headerRoles;
      message = "forge.chords: ${toString (builtins.length (lib.attrValues layers))} layers exceed the ${toString (builtins.length headerRoles)}-row headerRoles vocabulary; extend headerRoles.";
    }
  ];
}
