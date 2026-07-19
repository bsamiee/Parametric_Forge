# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/config.nix
# ----------------------------------------------------------------------------
# Nix-generated Zellij configuration: leader, entry, and normal-mode chord rows project from the chord owner (chords.nix); mode-interior binds and
# their hint ribbons render from ONE per-mode row table, so a bind and its ribbon hint cannot drift apart.
{
  config,
  lib,
  ...
}: let
  inherit (config.forge.theme) roles; # Estate palette owner (modules/home/theme.nix): semantic roles
  chords = config.forge.chords; # Chord-vocabulary owner (modules/home/programs/apps/chords.nix)
  pH = chords.zellij.prefix.hyper;
  inherit (chords) modes layers;

  # zjstatus variable vocabulary for both instances: role-named tokens derived from the theme owner — the bar reads semantic roles
  # (surface steps, text tiers, accents, states, focus pair, mode ladder), never a raw palette hue.
  zjVars =
    {
      base = roles.surface.base;
      surface = roles.surface.surface;
      raised = roles.surface.raised;
      selected = roles.surface.selected;
      text = roles.text.primary;
      subtle = roles.text.subtle;
      muted = roles.text.muted;
      inverse = roles.text.inverse;
      accent = roles.accent.primary;
      accent2 = roles.accent.secondary;
      structural = roles.accent.structural;
      focus_active = roles.focus.active;
      focus_inactive = roles.focus.inactive;
    }
    // lib.mapAttrs' (n: c: lib.nameValuePair "state_${n}" c) roles.state
    // lib.mapAttrs' (n: c: lib.nameValuePair "mode_${n}" c) roles.mode;
  colorRows = lib.concatStrings (lib.mapAttrsToList (n: c: "        color_${n}    \"${c.hex}\"\n") zjVars);

  # Hint-ribbon grammar: native macOS modifier glyphs; a layer chip (R⌘ Hyper, R⌥ Super) prefixes its key group once. The mode ribbon sits on the
  # surface elevation step (the top bar recedes onto base); chips carry inverse text on their mode/accent fill. Keys accent, labels muted; the renderer owns all padding.
  seg = c: t: "#[bg=$surface,fg=$" + c + "]" + t;
  segB = c: t: "#[bg=$surface,fg=$" + c + ",bold]" + t;
  chipOn = bgc: fgc: t: "#[bg=$" + bgc + ",fg=$" + fgc + ",bold] " + t + " " + seg "muted" " ";
  chip = c: chipOn c "inverse";
  pl = k: l: segB "accent" k + seg "muted" (" " + l + "  ");
  plRows = rows: lib.concatStrings (map (x: pl x.k x.l) rows);
  sep = seg "selected" "│ ";
  done = pl "⏎" "done";

  # --- [MODE_INTERIOR_ROW_TABLE]
  # One row per bind renders BOTH the mode's KDL block and its zjstatus ribbon, so a bind and its hint cannot drift; constructors keep rows single-line.
  # The hint tuple is [l rank] or [k l rank] with k defaulting to the first key; hintRow is a grouped label over adjacent binds with no bind of its own,
  # gap prefixes a blank line, mkExit tags a Normal exit, and launchRow floats a plugin body. Mode meta: header is a section comment, chip is [c label]
  # or [c fg label], note is input-mode text, tail is "done" (default) or "none"; rows render in list order, hint rank orders the ribbon independently.
  bind = keys: kdl: {inherit keys kdl;};
  hintOf = h:
    if builtins.length h == 3
    then {
      k = builtins.elemAt h 0;
      l = builtins.elemAt h 1;
      rank = builtins.elemAt h 2;
    }
    else if builtins.length h == 2
    then {
      l = builtins.elemAt h 0;
      rank = builtins.elemAt h 1;
    }
    else throw "zellij hint tuple wants [l rank] or [k l rank]: ${builtins.toJSON h}";
  bindH = keys: kdl: h: {
    inherit keys kdl;
    hint = hintOf h;
  };
  hintRow = k: l: rank: {hint = {inherit k l rank;};};
  gap = row: row // {gap = true;};
  mkExit = key: (bind ["${pH} ${key}"] ''SwitchToMode "Normal";'') // {tag = true;};
  launchRow = key: plugin: l: rank:
    gap (bindH [key] "" [l rank])
    // {
      body = lib.concatStringsSep "\n" [
        "          LaunchOrFocusPlugin \"${plugin}\" {"
        "            floating true"
        "            move_to_focused_tab true"
        "          };"
        "          SwitchToMode \"Normal\""
      ];
    };
  navRows = [
    (gap (bind ["j" "Down"] "ScrollDown;"))
    (bind ["k" "Up"] "ScrollUp;")
    (bind ["l" "Right"] "PageScrollDown;")
    (bind ["h" "Left"] "PageScrollUp;")
    (bind ["d"] "HalfPageScrollDown;")
    (bind ["u"] "HalfPageScrollUp;")
  ];
  modeTable = {
    locked = {
      header = "Locked Mode";
      chip = ["mode_locked" "text" "LOCKED"];
      tail = "none";
      rows = [(bindH ["${pH} ${modes.locked.exitKey}"] ''SwitchToMode "Normal";'' ["${layers.hyper.chip}${modes.locked.exitKey}" "unlock" 10])];
    };
    tab = {
      header = "Tab Mode";
      chip = ["mode_tab" "TAB"];
      rows =
        [
          (mkExit modes.tab.key)
          (bindH ["[" "Left"] "GoToPreviousTab;" ["[ ]" "switch" 10])
          (bind ["]" "Right"] "GoToNextTab;")
          (bindH [";"] ''MoveTab "Left";'' ["; '" "move" 20])
          (bind ["'"] ''MoveTab "Right";'')
          (bindH ["r"] ''SwitchToMode "RenameTab"; TabNameInput 0;'' ["rename" 50])
          (bindH ["n"] "NewTab;" ["new" 30])
          (bindH ["x"] "CloseTab;" ["close" 40])
        ]
        ++ map (i:
          if i == 1
          then bindH ["1"] "GoToTab 1;" ["1-9" "jump" 60]
          else bind [(toString i)] "GoToTab ${toString i};") (lib.range 1 9)
        ++ [(bindH ["Tab"] "ToggleTab;" ["⇥" "toggle" 70])];
    };
    pane = {
      header = "Pane Mode";
      chip = ["mode_pane" "PANE"];
      rows = [
        (mkExit modes.pane.key)
        (bindH ["h" "Left"] ''MoveFocus "Left";'' ["hjkl" "focus" 10])
        (bind ["l" "Right"] ''MoveFocus "Right";'')
        (bind ["j" "Down"] ''MoveFocus "Down";'')
        (bind ["k" "Up"] ''MoveFocus "Up";'')
        (bind ["b"] "BreakPane;")
        (bind ["]"] "BreakPaneRight;")
        (bind ["["] "BreakPaneLeft;")
        (bind ["p"] "SwitchFocus;")
        (bindH ["n"] ''NewPane; SwitchToMode "Normal";'' ["new" 20])
        (bindH ["d"] ''NewPane "Down"; SwitchToMode "Normal";'' ["down" 30])
        (bindH ["r"] ''NewPane "Right"; SwitchToMode "Normal";'' ["right" 40])
        (bindH ["s"] ''NewPane "stacked"; SwitchToMode "Normal";'' ["stack" 50])
        (bindH ["x"] ''CloseFocus; SwitchToMode "Normal";'' ["close" 60])
        (bindH ["f"] ''ToggleFocusFullscreen; SwitchToMode "Normal";'' ["full" 70])
        (bindH ["z"] ''TogglePaneFrames; SwitchToMode "Normal";'' ["frames" 120])
        (bindH ["w"] ''ToggleFloatingPanes; SwitchToMode "Normal";'' ["float all" 90])
        (bindH ["e"] ''TogglePaneEmbedOrFloating; SwitchToMode "Normal";'' ["float" 80])
        (bindH ["c"] ''SwitchToMode "RenamePane"; PaneNameInput 0;'' ["rename" 100])
        (bindH ["i"] ''TogglePanePinned; SwitchToMode "Normal";'' ["pin" 110])
      ];
    };
    move = {
      header = "Move Mode";
      chip = ["mode_move" "MOVE"];
      rows = [
        (mkExit modes.move.key)
        (bindH ["m" "Tab"] "MovePane;" ["next" 20])
        (bindH ["p"] "MovePaneBackwards;" ["prev" 30])
        (bindH ["h" "Left"] ''MovePane "Left";'' ["hjkl" "move" 10])
        (bind ["j" "Down"] ''MovePane "Down";'')
        (bind ["k" "Up"] ''MovePane "Up";'')
        (bind ["l" "Right"] ''MovePane "Right";'')
      ];
    };
    resize = {
      header = "Resize Mode";
      chip = ["mode_resize" "RESIZE"];
      rows = [
        (mkExit modes.resize.key)
        (bindH ["h" "Left"] ''Resize "Increase Left";'' ["hjkl" "grow" 10])
        (bind ["j" "Down"] ''Resize "Increase Down";'')
        (bind ["k" "Up"] ''Resize "Increase Up";'')
        (bind ["l" "Right"] ''Resize "Increase Right";'')
        (bindH ["H"] ''Resize "Decrease Left";'' ["HJKL" "shrink" 20])
        (bind ["J"] ''Resize "Decrease Down";'')
        (bind ["K"] ''Resize "Decrease Up";'')
        (bind ["L"] ''Resize "Decrease Right";'')
        (bindH ["=" "+"] ''Resize "Increase";'' ["= -" "all" 30])
        (bind ["-"] ''Resize "Decrease";'')
      ];
    };
    scroll = {
      header = "Scroll Mode";
      chip = ["mode_scroll" "SCROLL"];
      rows =
        [
          (mkExit modes.scroll.key)
          (bindH ["e"] ''EditScrollback; SwitchToMode "Normal";'' ["edit" 40])
          (bindH ["s"] ''SwitchToMode "EnterSearch"; SearchInput 0;'' ["search" 50])
          (bindH ["${pH} c"] ''ScrollToBottom; SwitchToMode "Normal";'' ["${layers.hyper.chip}c" "bottom" 60])
        ]
        ++ navRows
        ++ [
          (hintRow "jk" "line" 10)
          (hintRow "hl" "page" 20)
          (hintRow "du" "half" 30)
        ];
    };
    # Search exits on the scroll entry chord: the pair toggles as one surface.
    search = {
      header = "Search Mode";
      chip = ["mode_search" "SEARCH"];
      rows =
        [
          (mkExit modes.scroll.key)
          (bind ["${pH} c"] ''ScrollToBottom; SwitchToMode "Normal";'')
          (gap (bindH ["c"] ''SearchToggleOption "CaseSensitivity";'' ["case" 20]))
          (bindH ["w"] ''SearchToggleOption "Wrap";'' ["wrap" 30])
          (bindH ["o"] ''SearchToggleOption "WholeWord";'' ["word" 40])
          (gap (bindH ["n"] ''Search "down";'' ["n p" "next prev" 10]))
          (bind ["p"] ''Search "up";'')
        ]
        ++ navRows
        ++ [(hintRow "jk" "scroll" 50)];
    };
    session = {
      header = "Session Mode";
      chip = ["mode_session" "SESSION"];
      rows = [
        (mkExit modes.session.key)
        (bindH ["d"] "Detach;" ["detach" 20])
        (launchRow "s" "session-manager" "manager" 10)
        (launchRow "c" "configuration" "config" 30)
        (launchRow "p" "plugin-manager" "plugins" 40)
        (launchRow "a" "zellij:about" "about" 50)
        (launchRow "z" "zellij:share" "share" 60)
      ];
    };
    entersearch = {
      header = "Find Mode";
      chip = ["mode_entersearch" "FIND"];
      note = "type query";
      tail = "none";
      rows = [
        ((bindH ["${pH} c" "Esc"] ''SwitchToMode "Scroll";'' ["esc" "back" 20]) // {tag = true;})
        (bindH ["Enter"] ''SwitchToMode "Search";'' ["⏎" "search" 10])
      ];
    };
    renametab = {
      chip = ["mode_renametab" "RENAME TAB"];
      note = "type name";
      tail = "none";
      rows = [
        (mkExit "c")
        (bindH ["Esc"] ''UndoRenameTab; SwitchToMode "Tab";'' ["esc" "undo" 20])
        (hintRow "⏎" "done" 10)
      ];
    };
    renamepane = {
      chip = ["mode_renamepane" "RENAME PANE"];
      note = "type name";
      tail = "none";
      rows = [
        (mkExit "c")
        (bindH ["Esc"] ''UndoRenamePane; SwitchToMode "Pane";'' ["esc" "undo" 20])
        (hintRow "⏎" "done" 10)
      ];
    };
    # Ribbon-only: prompt is a zellij UI state, never a keybind block.
    prompt = {
      chip = ["mode_prompt" "PROMPT"];
      tail = "none";
      rows = [];
    };
    tmux = {
      header = "Tmux Mode";
      chip = ["mode_tmux" "TMUX"];
      rows = [
        ((bind ["${pH} ${modes.tmux.key}"] ''Write 2; SwitchToMode "Normal";'') // {tag = true;})
        (bind ["["] ''SwitchToMode "Scroll";'')
        (bindH ["\\\""] ''NewPane "Down"; SwitchToMode "Normal";'' ["\\\" %" "split" 10])
        (bind ["%"] ''NewPane "Right"; SwitchToMode "Normal";'')
        (bindH ["z"] ''ToggleFocusFullscreen; SwitchToMode "Normal";'' ["zoom" 30])
        (bindH ["c"] ''NewTab; SwitchToMode "Normal";'' ["tab" 20])
        (bind [","] ''SwitchToMode "RenameTab";'')
        (bind ["p"] ''GoToPreviousTab; SwitchToMode "Normal";'')
        (bindH ["n"] ''GoToNextTab; SwitchToMode "Normal";'' ["n p" "tab ±" 40])
        (bind ["Left"] ''MoveFocus "Left"; SwitchToMode "Normal";'')
        (bind ["Right"] ''MoveFocus "Right"; SwitchToMode "Normal";'')
        (bind ["Down"] ''MoveFocus "Down"; SwitchToMode "Normal";'')
        (bind ["Up"] ''MoveFocus "Up"; SwitchToMode "Normal";'')
        (bindH ["h"] ''MoveFocus "Left"; SwitchToMode "Normal";'' ["hjkl" "focus" 50])
        (bind ["l"] ''MoveFocus "Right"; SwitchToMode "Normal";'')
        (bind ["j"] ''MoveFocus "Down"; SwitchToMode "Normal";'')
        (bind ["k"] ''MoveFocus "Up"; SwitchToMode "Normal";'')
        (bind ["o"] "FocusNextPane;")
        (bindH ["d"] "Detach;" ["detach" 60])
        (bind ["Space"] "NextSwapLayout;")
        (bind ["x"] ''CloseFocus; SwitchToMode "Normal";'')
      ];
    };
  };

  # --- [RENDERERS]
  # KDL fold: rows render at their full emitted indentation; tagged exit rows align the layer comment at byte 83; headers dash-fill to width 83.
  hyperTag = "// ${layers.hyper.name} (${layers.hyper.glyphs}) | ${layers.hyper.physical}";
  alignTag = line: line + lib.strings.replicate (lib.max 1 (82 - lib.stringLength line)) " " + hyperTag;
  headerLine = label: "      // --- ${label} " + lib.strings.replicate (lib.max 0 (69 - lib.stringLength label)) "-";
  renderRow = row: let
    keysStr = lib.concatMapStringsSep " " (k: "\"${k}\"") row.keys;
    line = "        bind ${keysStr} { ${row.kdl} }";
  in
    lib.optionalString (row.gap or false) "\n"
    + (
      if row ? body
      then "        bind ${keysStr} {\n${row.body}\n        }"
      else if row.tag or false
      then alignTag line
      else line
    );
  modeBlock = name: let
    m = modeTable.${name};
  in
    lib.concatStringsSep "\n" (
      lib.optional (m ? header) (headerLine m.header)
      ++ ["      ${name} {"]
      ++ [(lib.concatMapStringsSep "\n" renderRow (lib.filter (x: x ? keys) m.rows))]
      ++ ["      }"]
    );
  # Emission orders are curated vocabularies over modeTable: blocks skip the ribbon-only prompt row (tmux renders at the keybind tail); the coverage
  # asserts break eval when a new mode misses either list instead of dropping it silently from the KDL or the ribbon bar.
  blockOrder = ["locked" "tab" "pane" "move" "resize" "scroll" "search" "session" "entersearch" "renametab" "renamepane"];
  hintOrder = ["normal" "locked" "pane" "tab" "resize" "move" "scroll" "search" "entersearch" "session" "renametab" "renamepane" "prompt" "tmux"];
  sorted = lib.sort (a: b: a < b);
  modeBlocksKdl = assert lib.assertMsg (sorted (blockOrder ++ ["prompt" "tmux"]) == builtins.attrNames modeTable) "zellij blockOrder drifted from modeTable";
    lib.concatMapStringsSep "\n\n" modeBlock blockOrder;

  # Ribbon fold over the same rows: chip, optional input note, rank-ordered hints, then the done tail. Normal mode composes from the chord owner.
  chipOf = c:
    if builtins.length c == 3
    then chipOn (builtins.elemAt c 0) (builtins.elemAt c 1) (builtins.elemAt c 2)
    else if builtins.length c == 2
    then chip (builtins.elemAt c 0) (builtins.elemAt c 1)
    else throw "zellij mode chip wants [c label] or [c fg label]: ${builtins.toJSON c}";
  ribbonOf = m:
    chipOf m.chip
    + lib.optionalString (m ? note) (seg "muted" (m.note + "  "))
    + lib.concatStrings (map (x: pl (x.hint.k or (builtins.head x.keys)) x.hint.l)
      (lib.sort (a: b: a.hint.rank < b.hint.rank) (lib.filter (x: x ? hint) m.rows)))
    + lib.optionalString ((m.tail or "done") == "done") (sep + done);
  ribbons =
    lib.mapAttrs (_: ribbonOf) modeTable
    // {
      normal =
        chip "mode_normal" "NORMAL"
        + chip "accent2" layers.hyper.chip
        + plRows chords.zellij.ribbon.hyperGroup
        + chip "structural" layers.super.chip
        + plRows chords.zellij.ribbon.superGroup;
    };
  zjModeName = {
    entersearch = "enter_search";
    renametab = "rename_tab";
    renamepane = "rename_pane";
  };
  modeHintLines = assert lib.assertMsg (sorted hintOrder == sorted (["normal"] ++ builtins.attrNames modeTable)) "zellij hintOrder drifted from modeTable";
    lib.concatMapStringsSep "\n" (m: let
      n = "mode_${zjModeName.${m} or m}";
    in "        ${n}${lib.strings.replicate (18 - lib.stringLength n) " "}\"${ribbons.${m}}\"")
    hintOrder;
in {
  imports = [../chords.nix];

  xdg.configFile."zellij/config.kdl".text = ''
        // Title         : config.kdl
        // Author        : Bardia Samiee
        // Project       : Parametric Forge
        // License       : MIT
        // Path          : modules/home/programs/apps/zellij/config.kdl
        // ----------------------------------------------------------------------------
        // Core Zellij options referencing the shared Parametric Forge theme

        // --- [CORE_CONFIGURATION]
        theme                       "dracula"
        default_shell               "zsh"
        default_layout              "default"
        show_startup_tips           false
        show_release_notes          false
        simplified_ui               true
        mouse_mode                  true
        pane_frames                 true
        session_serialization       true
        serialize_pane_viewport     true
        copy_command                "pbcopy"
        scroll_buffer_size          100000

        // Host web stance: server off, sharing disabled until reverse-proxy + token-lifecycle rows exist (annex-gated exposure).
        web_server                  false
        web_sharing                 "disabled"

        // --- [PLUGIN_ALIASES]
        plugins {
          configuration location="zellij:configuration"
          compact-bar location="zellij:compact-bar"
          tab-bar location="zellij:tab-bar"
          status-bar location="zellij:status-bar"
          strider location="zellij:strider"
          plugin-manager location="zellij:plugin-manager"
          session-manager location="zellij:session-manager"
          about location="zellij:about"
          filepicker location="zellij:strider" {
            cwd "/"
          }
          welcome-screen location="zellij:session-manager" {
            welcome_screen true
          }
          zellij-forgot location="file:~/.config/zellij/plugins/zellij_forgot.wasm"

          // --- [ZJSTATUS_TOP_BAR]
          // Native zjstatus widgets only: tab labels index-projected (TAB [N]), the swap-layout name, and the session identity ({session}). {name}
          // survives only in the rename cell as live typing feedback. WezTerm's tab bar hides at one tab, so no second bar ever stacks above this one.
          // format_left starts at column 0 so the active-tab fill aligns with the pane frame edge. Receding cells (space, normal tab, swap label) carry
          // no bg escape so they inherit WezTerm's translucent default background and blend into the body; only the active-tab and session chips set an
          // explicit fill and read solid (text_background_opacity holds them opaque) — the session chip carries accent2 (magenta), one grammar with TAB.
          zjstatus location="file:~/.config/zellij/plugins/zjstatus.wasm" {
    ${colorRows}
            format_left               "{tabs}"
            format_center             "{swap_layout}"
            format_right              "#[bg=$accent2,fg=$inverse,bold] {session} "
            format_space              ""

            // Narrow panes: hide whole parts by precedence instead of letting them overlap — the session cell outranks tabs and the swap label.
            format_hide_on_overlength "true"
            format_precedence         "rlc"

            swap_layout_format        "#[fg=$structural,bold] {name} "
            swap_layout_hide_if_empty "true"

            tab_active    "#[bg=$focus_active,fg=$inverse,bold] TAB [{index}] "
            tab_normal    "#[fg=$focus_inactive] TAB [{index}] "
            tab_separator " "
            tab_rename    "#[bg=$mode_renametab,fg=$inverse,bold] TAB [{index}] {name} "

            border_enabled              "false"
            hide_frame_for_single_pane  "false"
          }

          // --- [ZJSTATUS_HINTS_BOTTOM_BAR_MODE_CHIP_ALWAYS_VISIBLE_KEY_RIBBON]
          // Same wasm, second instance; layer chips R⌘ (Hyper) and R⌥ (Super).
          zjstatus-hints location="file:~/.config/zellij/plugins/zjstatus.wasm" {
    ${colorRows}
            format_left   "{mode}"
            format_right  "#[bg=$surface,fg=$muted]${chords.zellij.hintsRight}"
            format_space  "#[bg=$surface]"

            // Narrow panes: the mode ribbon outranks the layer legend.
            format_hide_on_overlength "true"
            format_precedence         "lrc"

    ${modeHintLines}
            mode_default_to_mode "normal"

            border_enabled              "false"
            hide_frame_for_single_pane  "false"
          }
        }

        // --- [KEYBINDINGS]
    ${chords.zellij.headerComment}

        keybinds clear-defaults=true {
          normal {
            // --- [SIMPLE_LAYER]
    ${chords.zellij.normalBindsKdl}
          }

          // --- [UNIVERSAL_BINDINGS_EXCEPT_LOCKED_MODE]
          shared_except "locked" {

            // --- [HYPER_LAYER_RIGHT_COMMAND]
    ${chords.zellij.hyperBindsKdl}

            // --- [SUPER_LAYER_RIGHT_OPTION]
    ${chords.zellij.superBindsKdl}
          }

    ${modeBlocksKdl}

          // --- [GENERAL_BINDINGS]
          shared_except "normal" "locked" {
            bind "Enter" "Esc" { SwitchToMode "Normal"; }
          }
    ${chords.zellij.entryBindsKdl}

    ${modeBlock "tmux"}
        }

  '';
}
