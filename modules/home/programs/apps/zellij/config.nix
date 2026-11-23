{
  lib,
  pkgs,
  theme,
  chords,
  host,
  ...
}: let
  inherit (theme) roles;

  pH = chords.zellij.prefix.hyper;
  inherit (chords) modes layers;

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
      chip = "LOCKED";
      tail = "none";
      rows = [(bindH ["${pH} ${modes.locked.exitKey}"] ''SwitchToMode "Normal";'' ["${layers.hyper.chip}${modes.locked.exitKey}" "unlock" 10])];
    };
    tab = {
      header = "Tab Mode";
      chip = "TAB";
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
        ]
        ++ map (i:
          if i == 1
          then bindH ["1"] "GoToTab 1;" ["1-9" "jump" 60]
          else bind [(toString i)] "GoToTab ${toString i};") (lib.range 1 9)
        ++ [(bindH ["Tab"] "ToggleTab;" ["⇥" "toggle" 70])];
    };
    pane = {
      header = "Pane Mode";
      chip = "PANE";
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
        (bind ["Shift z"] ''ToggleBars; SwitchToMode "Normal";'')
      ];
    };
    move = {
      header = "Move Mode";
      chip = "MOVE";
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
      chip = "RESIZE";
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
      chip = "SCROLL";
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
      chip = "SEARCH";
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
      chip = "SESSION";
      rows = [
        (mkExit modes.session.key)
        (bindH ["d"] "Detach;" ["detach" 20])
        (bindH ["i"] ''ToggleSessionCard; SwitchToMode "Normal";'' ["inbox" 3])
        (bindH [chords.zellij.next.key] "${chords.zellij.next.kdl} SwitchToMode \"Normal\";" ["next" 5])
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
      chip = "FIND";
      note = "type query";
      tail = "none";
      rows = [
        (bindH ["Ctrl c" "Esc"] ''SwitchToMode "Scroll";'' ["esc" "back" 20])
        (bindH ["Enter"] ''SwitchToMode "Search";'' ["⏎" "search" 10])
      ];
    };
    renametab = {
      chip = "RENAME TAB";
      note = "type name";
      tail = "none";
      rows = [
        (bind ["Ctrl c"] ''SwitchToMode "Normal";'')
        (bindH ["Esc"] ''UndoRenameTab; SwitchToMode "Tab";'' ["esc" "undo" 20])
        (hintRow "⏎" "done" 10)
      ];
    };
    renamepane = {
      chip = "RENAME PANE";
      note = "type name";
      tail = "none";
      rows = [
        (bind ["Ctrl c"] ''SwitchToMode "Normal";'')
        (bindH ["Esc"] ''UndoRenamePane; SwitchToMode "Pane";'' ["esc" "undo" 20])
        (hintRow "⏎" "done" 10)
      ];
    };
    prompt = {
      chip = "PROMPT";
      tail = "none";
      rows = [];
    };
    tmux = {
      header = "Tmux Mode";
      chip = "TMUX";
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
  blockOrder = ["locked" "tab" "pane" "move" "resize" "scroll" "search" "session" "entersearch" "renametab" "renamepane"];
  modeBlocksKdl = lib.concatMapStringsSep "\n\n" modeBlock blockOrder;

  # --- [STATUSBAR_DATA]
  rsStr = builtins.toJSON;
  rsHex = color: "0x${lib.removePrefix "#" color.hex}";
  variants = {
    normal = "Normal";
    locked = "Locked";
    resize = "Resize";
    pane = "Pane";
    tab = "Tab";
    scroll = "Scroll";
    entersearch = "EnterSearch";
    search = "Search";
    renametab = "RenameTab";
    renamepane = "RenamePane";
    renamesession = "RenameSession";
    session = "Session";
    move = "Move";
    prompt = "Prompt";
    tmux = "Tmux";
  };
  barLayers = {
    hyper = roles.accent.secondary;
    super = roles.accent.structural;
  };
  layerRs = n: "pub const ${lib.toUpper n}: Layer = Layer { mark: ${rsStr layers.${n}.chip}, color: ${rsHex barLayers.${n}}, name: ${rsStr (lib.toLower layers.${n}.name)} };";
  hintRs = h: "(${rsStr h.k}, ${rsStr h.l}, ${lib.boolToString (h.k == chords.zellij.sheetKey)})";
  groupRs = g: "Group { layer: ${g.layer or "None"}, joined: ${lib.boolToString (g.joined or false)}, hints: &[${lib.concatMapStringsSep ", " hintRs g.hints}] }";
  groupsOf = name: m:
    if name == "normal"
    then [
      {
        layer = "Some(&HYPER)";
        hints = chords.zellij.ribbon.hyperGroup;
      }
      {
        layer = "Some(&SUPER)";
        hints = chords.zellij.ribbon.superGroup;
      }
    ]
    else if name == "locked"
    then [
      {
        layer = "Some(&HYPER)";
        joined = true;
        hints = [
          {
            k = modes.locked.exitKey;
            l = "unlock";
          }
        ];
      }
    ]
    else [
      {
        hints = map (x: {
          k = lib.replaceStrings ["\\\""] ["\""] (x.hint.k or (builtins.head x.keys));
          inherit (x.hint) l;
        }) (lib.sort (a: b: a.hint.rank < b.hint.rank) (lib.filter (x: x ? hint) (m.rows or [])));
      }
    ];
  ribbonRs = name: m: let
    fill = roles.mode.${name};
    label =
      if fill.hex == roles.surface.selected.hex
      then roles.text.primary
      else roles.text.inverse;
  in "        InputMode::${variants.${name}} => Ribbon { chip: ${rsStr m.chip}, fill: ${rsHex fill}, label: ${rsHex label}, note: ${rsStr (m.note or "")}, groups: &[${lib.concatMapStringsSep ", " groupRs (groupsOf name m)}], done: ${lib.boolToString ((m.tail or "done") == "done")} },";
  ribbonModes =
    modeTable
    // {
      normal = {
        chip = "NORMAL";
        tail = "none";
      };
      renamesession = {
        chip = "RENAME SESSION";
        note = "type name";
        tail = "none";
      };
    };
  statusbarData = pkgs.writeText "statusbar-data.rs" ''
    pub const PALETTE: Palette = Palette {
        surface: ${rsHex roles.surface.surface},
        fg: ${rsHex roles.text.primary},
        muted: ${rsHex roles.text.muted},
        subtle: ${rsHex roles.text.subtle},
        selected: ${rsHex roles.surface.selected},
        inverse: ${rsHex roles.text.inverse},
        focus: ${rsHex roles.accent.primary},
        session: ${rsHex roles.accent.secondary},
        run: ${rsHex roles.inbox.working},
        idle: ${rsHex roles.state.info},
        need: ${rsHex roles.inbox.needs_you},
        fail: ${rsHex roles.inbox.failed},
    };
    ${layerRs "hyper"}
    ${layerRs "super"}
    pub const NEXT_KEY: &str = ${rsStr chords.zellij.next.key};
    pub const NEXT_CHORD: &str = ${rsStr "${pH} ${chords.zellij.next.key}"};
    pub const NEXT_MODES: &[InputMode] = &[${lib.concatMapStringsSep ", " (v: "InputMode::${v}") (lib.attrValues (removeAttrs variants ["locked"]))}];
    pub const fn ribbon(mode: InputMode) -> Ribbon {
        match mode {
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList ribbonRs ribbonModes)}
        }
    }
  '';
in {
  imports = [../chords.nix];
  _module.args.statusbarData = statusbarData;

  programs.zellij.extraConfig = ''

        // --- [CORE_CONFIGURATION]
        theme                         "dracula"
        default_shell                 "${host.user.shell}"
        post_command_discovery_hook   "echo ${host.user.shell}"
        show_startup_tips             false
        show_release_notes            false
        simplified_ui                 true
        auto_layout                   false
        visual_bell                   false
        mouse_hover_tips              false
        pane_frame_style              "full"
        stacked_pane_list             false
        serialize_pane_viewport       true
        scrollback_lines_to_serialize 5000
        scroll_buffer_size            100000

        // --- [PANE_ENVIRONMENT]
        env {
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

          // --- [STATUSBAR]
          statusbar-top location="file:~/.config/zellij/plugins/statusbar.wasm" {
            role "top"
          }
          statusbar-bottom location="file:~/.config/zellij/plugins/statusbar.wasm" {
            role "bottom"
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
