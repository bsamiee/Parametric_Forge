# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/config.nix
# ----------------------------------------------------------------------------
# Nix-generated Zellij configuration. Leader, entry, and normal-mode chord
# rows project from the chord owner (chords.nix); mode-interior binds and
# their hint ribbons render from ONE per-mode row table, so a bind and its
# ribbon hint cannot drift apart.
{
  config,
  lib,
  ...
}: let
  inherit (config.forge.theme) palette; # Estate palette owner (modules/home/theme.nix)
  chords = config.forge.chords; # Chord-vocabulary owner (modules/home/programs/apps/chords.nix)
  pH = chords.zellij.prefix.hyper;
  inherit (chords) modes layers;

  # Shared color rows for both zjstatus instances; one palette, two surfaces.
  colorRows = lib.concatStrings (map (n: "        color_${n}    \"${palette.${n}.hex}\"\n") [
    "crust"
    "background"
    "surface"
    "current_line"
    "selection"
    "foreground"
    "subtle"
    "comment"
    "purple"
    "cyan"
    "green"
    "yellow"
    "amber"
    "orange"
    "red"
    "magenta"
    "pink"
    "blue"
  ]);

  # Hint-ribbon grammar: native macOS modifier glyphs; a layer chip (R⌘ Hyper,
  # R⌥ Super) prefixes its key group once. Both bars sit on the surface
  # elevation step; chips carry inverse text on accent fills. Keys cyan,
  # labels muted, mode chip carries the state color shared with the top bar.
  seg = c: t: "#[bg=$surface,fg=$" + c + "]" + t;
  segB = c: t: "#[bg=$surface,fg=$" + c + ",bold]" + t;
  chipOn = bgc: fgc: t: "#[bg=$" + bgc + ",fg=$" + fgc + ",bold] " + t + " " + seg "comment" " ";
  chip = c: chipOn c "background";
  pl = k: l: segB "cyan" k + seg "comment" (" " + l + "  ");
  plRows = rows: lib.concatStrings (map (x: pl x.k x.l) rows);
  sep = seg "selection" "│ ";
  done = pl "⏎" "done";

  # --- [MODE_INTERIOR_ROW_TABLE]
  # One row per bind renders BOTH the mode's KDL block and its zjstatus ribbon,
  # so a bind and its hint cannot drift. Constructors keep rows single-line:
  # bind keys kdl | bindH keys kdl [l rank]|[k l rank] (k defaults to the first
  # key) | hintRow k l rank (grouped label over adjacent binds, no bind of its
  # own) | gap row (blank line before) | mkExit key (tagged Normal exit) |
  # launchRow key plugin l rank (floating plugin body). Mode meta: header
  # (section comment), chip [c label]|[c fg label], note (input-mode text),
  # tail ("done" default | "none"). Rows render in list order into the KDL
  # block; hint rank orders the ribbon independently.
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
      chip = ["selection" "foreground" "LOCKED"];
      tail = "none";
      rows = [(bindH ["${pH} ${modes.locked.exitKey}"] ''SwitchToMode "Normal";'' ["${layers.hyper.chip}${modes.locked.exitKey}" "unlock" 10])];
    };
    tab = {
      header = "Tab Mode";
      chip = ["magenta" "TAB"];
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
      chip = ["orange" "PANE"];
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
      chip = ["cyan" "MOVE"];
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
      chip = ["purple" "RESIZE"];
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
      chip = ["yellow" "SCROLL"];
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
      chip = ["pink" "SEARCH"];
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
      chip = ["pink" "SESSION"];
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
      header = "Prompt Mode";
      chip = ["pink" "FIND"];
      note = "type query  ";
      tail = "none";
      rows = [
        ((bindH ["${pH} c" "Esc"] ''SwitchToMode "Scroll";'' ["esc" "back  " 20]) // {tag = true;})
        (bindH ["Enter"] ''SwitchToMode "Search";'' ["⏎" "search" 10])
      ];
    };
    renametab = {
      chip = ["red" "RENAME TAB"];
      note = "type name  ";
      tail = "none";
      rows = [
        (mkExit "c")
        (bindH ["Esc"] ''UndoRenameTab; SwitchToMode "Tab";'' ["esc" "undo  " 20])
        (hintRow "⏎" "done" 10)
      ];
    };
    renamepane = {
      chip = ["red" "RENAME PANE"];
      note = "type name  ";
      tail = "none";
      rows = [
        (mkExit "c")
        (bindH ["Esc"] ''UndoRenamePane; SwitchToMode "Pane";'' ["esc" "undo  " 20])
        (hintRow "⏎" "done" 10)
      ];
    };
    # Ribbon-only: prompt is a zellij UI state, never a keybind block.
    prompt = {
      chip = ["foreground" "PROMPT"];
      tail = "none";
      rows = [];
    };
    tmux = {
      header = "Tmux Mode";
      chip = ["green" "TMUX"];
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
  # KDL fold: rows render at their full emitted indentation; tagged exit rows
  # align the layer comment at byte 83; headers dash-fill to width 83.
  hyperTag = "// ${layers.hyper.name} (${layers.hyper.glyphs}) | ${layers.hyper.physical}";
  alignTag = line: line + lib.strings.replicate (lib.max 1 (82 - lib.stringLength line)) " " + hyperTag;
  headerLine = label: "      // --- ${label} " + lib.strings.replicate (69 - lib.stringLength label) "-";
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
  # Emission orders are curated vocabularies over modeTable: blocks skip the
  # ribbon-only prompt row (tmux renders at the keybind tail); the coverage
  # asserts break eval when a new mode misses either list instead of dropping
  # it silently from the KDL or the ribbon bar.
  blockOrder = ["locked" "tab" "pane" "move" "resize" "scroll" "search" "session" "entersearch" "renametab" "renamepane"];
  hintOrder = ["normal" "locked" "pane" "tab" "resize" "move" "scroll" "search" "entersearch" "session" "renametab" "renamepane" "prompt" "tmux"];
  sorted = lib.sort (a: b: a < b);
  modeBlocksKdl = assert lib.assertMsg (sorted (blockOrder ++ ["prompt" "tmux"]) == builtins.attrNames modeTable) "zellij blockOrder drifted from modeTable";
    lib.concatMapStringsSep "\n\n" modeBlock blockOrder;

  # Ribbon fold over the same rows: chip, optional input note, rank-ordered
  # hints, then the done tail. Normal mode composes from the chord owner.
  chipOf = c:
    if builtins.length c == 3
    then chipOn (builtins.elemAt c 0) (builtins.elemAt c 1) (builtins.elemAt c 2)
    else if builtins.length c == 2
    then chip (builtins.elemAt c 0) (builtins.elemAt c 1)
    else throw "zellij mode chip wants [c label] or [c fg label]: ${builtins.toJSON c}";
  ribbonOf = m:
    chipOf m.chip
    + lib.optionalString (m ? note) (seg "comment" m.note)
    + lib.concatStrings (map (x: pl (x.hint.k or (builtins.head x.keys)) x.hint.l)
      (lib.sort (a: b: a.hint.rank < b.hint.rank) (lib.filter (x: x ? hint) m.rows)))
    + lib.optionalString ((m.tail or "done") == "done") (sep + done);
  ribbons =
    lib.mapAttrs (_: ribbonOf) modeTable
    // {
      normal =
        chip "green" "NORMAL"
        + chip "magenta" layers.hyper.chip
        + plRows chords.zellij.ribbon.hyperGroup
        + chip "purple" layers.super.chip
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

        // Host web stance: server off, sharing disabled until reverse-proxy +
        // token-lifecycle rows exist (annex-gated exposure).
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

          // --- zjstatus: THE one top bar — tabs, layout, agent/quota cells, session --
          // Cells are pipe-fed by the forge-agents collector, which owns the
          // role->palette styling and ships formatted payloads; the bar renders
          // them verbatim and never polls a provider itself. WezTerm's tab bar
          // hides at one tab, so no second bar ever stacks above this one.
          zjstatus location="file:~/.config/zellij/plugins/zjstatus.wasm" {
    ${colorRows}
            format_left               "#[bg=$surface] {tabs}"
            format_center             "{swap_layout}"
            format_right              "{notifications}{pipe_agents}{pipe_quota}#[bg=$pink,fg=$background,bold] {session} "
            format_space              "#[bg=$surface]"

            // Narrow panes: hide whole parts by precedence instead of letting
            // them overlap — agent/quota cells outrank tabs and the swap label.
            format_hide_on_overlength "true"
            format_precedence         "rlc"

            pipe_agents_format        "{output}"
            pipe_agents_rendermode    "dynamic"
            pipe_quota_format         "{output}"
            pipe_quota_rendermode     "dynamic"

            // Transient toast rail: zjstatus::notify:: broadcasts (collector
            // rises, receipts push bus) render here and auto-hide. Payloads
            // are literal — urgency rides the text prefix (? input, !! fail),
            // never #[..] directives; per-urgency color stays on pipe_agents.
            // Broadcast reaches both bar instances; only this bar renders it.
            notification_format_unread           "#[bg=$amber,fg=$background,bold]  {message} "
            notification_format_no_notifications ""
            notification_show_interval           "8"

            swap_layout_format        "#[bg=$surface,fg=$purple,bold] {name} "
            swap_layout_hide_if_empty "true"

            tab_active    "#[bg=$cyan,fg=$background,bold] {name} "
            tab_normal    "#[bg=$surface,fg=$subtle] {name} "
            tab_separator " "
            tab_rename    "#[bg=$red,fg=$background,bold] {name} "

            border_enabled              "false"
            hide_frame_for_single_pane  "false"
          }

          // --- [ZJSTATUS_HINTS_BOTTOM_BAR_MODE_CHIP_ALWAYS_VISIBLE_KEY_RIBBON]
          // Same wasm, second instance; layer chips R⌘ (Hyper) and R⌥ (Super).
          zjstatus-hints location="file:~/.config/zellij/plugins/zjstatus.wasm" {
    ${colorRows}
            format_left   "{mode}"
            format_right  "#[bg=$surface,fg=$comment]${chords.zellij.hintsRight}"
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
            //  --- Simple Layer ------------------------------------------------------
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
