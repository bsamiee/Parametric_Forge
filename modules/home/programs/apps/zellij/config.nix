{
  config,
  lib,
  pkgs,
  toolchainEnvFor,
  ...
}: let
  inherit (config.forge.theme) roles;
  inherit
    (toolchainEnvFor {
      home = config.home.homeDirectory;
      inherit (config.home) username;
      xdgCacheHome = config.xdg.cacheHome;
      xdgConfigHome = config.xdg.configHome;
      xdgDataHome = config.xdg.dataHome;
      xdgStateHome = config.xdg.stateHome;
    })
    pathEntries
    ;

  # --- [INBOX_COUNT]
  inboxCount = pkgs.writeShellApplication {
    name = "zellij-inbox-count";
    runtimeInputs = [config.programs.zellij.package pkgs.jq];
    text = ''
      while read -r session; do
        zellij --session "$session" action list-panes --json --all 2>/dev/null || true
      done < <(zellij list-sessions --short --no-formatting) \
        | jq -rs '
          [.[][] | select(.is_plugin | not) | .attention | select(.muted != true) | .status] as $states
          | [["NeedsYou", "need you"], ["Working", "running"]]
          | map(. as [$state, $label] | ($states | map(select(. == $state)) | length) | select(. > 0) | "\(.) \($label)")
          | select(length > 0)
          | "◉ " + join(" · ")
        '
    '';
  };
  chords = config.forge.chords;
  pH = chords.zellij.prefix.hyper;
  inherit (chords) modes layers;

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
    // lib.mapAttrs' (n: c: lib.nameValuePair "inbox_${n}" c) roles.inbox
    // lib.mapAttrs' (n: c: lib.nameValuePair "mode_${n}" c) roles.mode;
  colorRows = lib.concatStrings (lib.mapAttrsToList (n: c: "        color_${n}    \"${c.hex}\"\n") zjVars);

  seg = c: t: "#[bg=$surface,fg=$" + c + "]" + t;
  segB = c: t: "#[bg=$surface,fg=$" + c + ",bold]" + t;
  chipOn = bgc: fgc: t: "#[bg=$" + bgc + ",fg=$" + fgc + ",bold] " + t + " " + seg "muted" " ";
  chip = c: chipOn c "inverse";
  pl = k: l: segB "accent" k + seg "muted" (" " + l + "  ");
  plRows = rows: lib.concatStrings (map (x: pl x.k x.l) rows);
  sep = seg "selected" "│ ";
  done = pl "⏎" "done";

  # --- [MODE_INTERIOR_ROW_TABLE]
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
    (gap (bindH ["["] "ScrollToPreviousPrompt;" ["[ ]" "prompt" 70]))
    (bind ["]"] "ScrollToNextPrompt;")
    (bindH ["m"] "SelectCommandAtScrollPosition;" ["select" 80])
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
          (bindH ["u"] ''MuteTab; SwitchToMode "Normal";'' ["mute" 80])
          (bindH ["s"] ''ToggleActiveSyncTab; SwitchToMode "Normal";'' ["sync" 90])
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
        (bindH ["v"] ''WatchPane; SwitchToMode "Normal";'' ["watch" 130])
        (bindH ["u"] ''MutePane; SwitchToMode "Normal";'' ["mute" 140])
        (bind ["g"] ''IgnorePaneOutput; SwitchToMode "Normal";'')
        (bind [";"] "FocusLastPane;")
        (bindH ["a"] ''NewFloatingPane; SwitchToMode "Normal";'' ["new float" 85])
        (bind ["Shift f"] ''ToggleFocusNoUiFullscreen; SwitchToMode "Normal";'')
        (bind ["Shift s"] ''ToggleStackListOrientation; SwitchToMode "Normal";'')
        (bind ["Shift z"] ''ToggleBars; SwitchToMode "Normal";'')
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
          (bindH ["Ctrl c"] ''ScrollToBottom; SwitchToMode "Normal";'' ["⌃c" "bottom" 60])
          (bindH ["c"] ''CopyLastCommandOutput; SwitchToMode "Normal";'' ["copy output" 65])
        ]
        ++ navRows
        ++ [
          (hintRow "jk" "line" 10)
          (hintRow "hl" "page" 20)
          (hintRow "du" "half" 30)
        ];
    };
    search = {
      header = "Search Mode";
      chip = ["mode_search" "SEARCH"];
      rows =
        [
          (mkExit modes.scroll.key)
          (bind ["Ctrl c"] ''ScrollToBottom; SwitchToMode "Normal";'')
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
        (bindH ["r"] ''SwitchToMode "RenameSession"; SessionNameInput 0;'' ["rename" 22])
        (bindH ["i"] ''ToggleSessionCard; SwitchToMode "Normal";'' ["inbox" 3])
        (bindH ["n"] ''GoToNextAttention; SwitchToMode "Normal";'' ["next" 5])
        (bindH ["u"] ''MuteSession; SwitchToMode "Normal";'' ["mute" 7])
        (bindH ["Tab"] ''ToggleSession; SwitchToMode "Normal";'' ["⇥" "last" 8])
        (bindH ["Left"] ''GoToPreviousSession; SwitchToMode "Normal";'' ["← →" "history" 9])
        (bind ["Right"] ''GoToNextSession; SwitchToMode "Normal";'')
        (launchRow "s" "session-manager" "manager" 10)
        (launchRow "l" "zellij:layout-manager" "layouts" 25)
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
        (bindH ["Ctrl c" "Esc"] ''SwitchToMode "Scroll";'' ["esc" "back" 20])
        (bindH ["Enter"] ''SwitchToMode "Search";'' ["⏎" "search" 10])
      ];
    };
    renametab = {
      chip = ["mode_renametab" "RENAME TAB"];
      note = "type name";
      tail = "none";
      rows = [
        (bind ["Ctrl c"] ''SwitchToMode "Normal";'')
        (bindH ["Esc"] ''UndoRenameTab; SwitchToMode "Tab";'' ["esc" "undo" 20])
        (hintRow "⏎" "done" 10)
      ];
    };
    renamepane = {
      chip = ["mode_renamepane" "RENAME PANE"];
      note = "type name";
      tail = "none";
      rows = [
        (bind ["Ctrl c"] ''SwitchToMode "Normal";'')
        (bindH ["Esc"] ''UndoRenamePane; SwitchToMode "Pane";'' ["esc" "undo" 20])
        (hintRow "⏎" "done" 10)
      ];
    };
    renamesession = {
      chip = ["mode_renamesession" "RENAME SESSION"];
      note = "type name";
      tail = "none";
      rows = [
        (bind ["Ctrl c"] ''SwitchToMode "Normal";'')
        (bindH ["Esc"] ''UndoRenameSession; SwitchToMode "Session";'' ["esc" "undo" 20])
        (hintRow "⏎" "done" 10)
      ];
    };
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
  blockOrder = ["locked" "tab" "pane" "move" "resize" "scroll" "search" "session" "entersearch" "renametab" "renamepane" "renamesession"];
  hintOrder = ["normal" "locked" "pane" "tab" "resize" "move" "scroll" "search" "entersearch" "session" "renametab" "renamepane" "renamesession" "prompt" "tmux"];
  modeBlocksKdl = lib.concatMapStringsSep "\n\n" modeBlock blockOrder;

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
    renamesession = "rename_session";
  };
  modeHintLines = lib.concatMapStringsSep "\n" (m: let
    n = "mode_${zjModeName.${m} or m}";
  in "        ${n}${lib.strings.replicate (lib.max 1 (20 - lib.stringLength n)) " "}\"${ribbons.${m}}\"")
  hintOrder;
in {
  imports = [../chords.nix];

  programs.zellij.extraConfig = ''

        // --- [CORE_CONFIGURATION]
        theme                         "dracula"
        default_shell                 "${config.forge.shell}"
        post_command_discovery_hook   "true"
        show_startup_tips             false
        show_release_notes            false
        simplified_ui                 true
        pane_frame_style              "full"
        stacked_pane_list             false
        serialize_pane_viewport       true
        scrollback_lines_to_serialize 5000
        scroll_buffer_size            100000

        // --- [PANE_ENVIRONMENT]
        env {
          PATH "${lib.concatStringsSep ":" pathEntries}"
          TERM "xterm-256color"
          COLORTERM "truecolor"
        }

        // --- [ATTENTION]
        attention {
          track_commands true
          tray_badge_colors {
    ${lib.concatStrings (lib.mapAttrsToList (n: c: "        ${n} \"${c.hex}\"\n") roles.inbox)}      }
        }

        // --- [PLUGIN_ALIASES]
        plugins {
          zellij-forgot location="file:~/.config/zellij/plugins/zellij_forgot.wasm"

          // --- [ZJSTATUS_TOP_BAR]
          zjstatus location="file:~/.config/zellij/plugins/zjstatus.wasm" {
    ${colorRows}
            format_left               "{tabs}"
            format_center             "{swap_layout}"
            format_right              "{command_inbox}#[bg=$accent2,fg=$inverse,bold] {session} "

            command_inbox_command           "${lib.getExe inboxCount}"
            command_inbox_format            "#[fg=$inbox_needs_you,bold]{stdout} "
            command_inbox_interval          "10"
            command_inbox_hideonemptystdout "true"

            format_hide_on_overlength "true"
            format_precedence         "rlc"

            swap_layout_format        "#[fg=$structural,bold] {name} "
            swap_layout_hide_if_empty "true"

            tab_active    "#[bg=$focus_active,fg=$inverse,bold] TAB [{index}] "
            tab_normal    "#[fg=$focus_inactive] TAB [{index}] "
            tab_separator " "
            tab_rename    "#[bg=$mode_renametab,fg=$inverse,bold] TAB [{index}] {name} "
          }

          // --- [ZJSTATUS_HINTS_BOTTOM_BAR_MODE_CHIP_ALWAYS_VISIBLE_KEY_RIBBON]
          zjstatus-hints location="file:~/.config/zellij/plugins/zjstatus.wasm" {
    ${colorRows}
            format_left   "{mode}"
            format_right  "#[bg=$surface,fg=$muted]${chords.zellij.hintsRight}"
            format_space  "#[bg=$surface]"

            format_hide_on_overlength "true"
            format_precedence         "lrc"

    ${modeHintLines}
            mode_default_to_mode "normal"
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
