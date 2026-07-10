# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/config.nix
# ----------------------------------------------------------------------------
# Nix-generated Zellij configuration. Leader, entry, and normal-mode chord
# rows project from the chord owner (chords.nix); mode-interior binds and
# their hint ribbons are owned here as paired surfaces.
{
  config,
  lib,
  ...
}: let
  inherit (config.forge.theme) palette; # Estate palette owner (modules/home/theme.nix)
  chords = config.forge.chords; # Chord-vocabulary owner (modules/home/programs/apps/chords.nix)
  pH = chords.zellij.prefix.hyper;
  inherit (chords) modes;

  # Shared mode-interior fragments: one declaration renders identically at
  # every consuming mode block.
  exitBind = key: ''bind "${pH} ${key}" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command'';
  scrollNavKdl = lib.concatStringsSep "\n        " [
    ''bind "j" "Down" { ScrollDown; }''
    ''bind "k" "Up" { ScrollUp; }''
    ''bind "l" "Right" { PageScrollDown; }''
    ''bind "h" "Left" { PageScrollUp; }''
    ''bind "d" { HalfPageScrollDown; }''
    ''bind "u" { HalfPageScrollUp; }''
  ];

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
  plRows = rows: lib.concatStrings (map (r: pl r.k r.l) rows);
  sep = seg "selection" "│ ";
  done = pl "⏎" "done";
  ribbon = {
    normal =
      chip "green" "NORMAL"
      + chip "magenta" chords.layers.hyper.chip
      + plRows chords.zellij.ribbon.hyperGroup
      + chip "purple" chords.layers.super.chip
      + plRows chords.zellij.ribbon.superGroup;
    locked = chipOn "selection" "foreground" "LOCKED" + pl "${chords.layers.hyper.chip}${modes.locked.exitKey}" "unlock";
    pane =
      chip "orange" "PANE"
      + pl "hjkl" "focus"
      + pl "n" "new"
      + pl "d" "down"
      + pl "r" "right"
      + pl "s" "stack"
      + pl "x" "close"
      + pl "f" "full"
      + pl "e" "float"
      + pl "w" "float all"
      + pl "c" "rename"
      + pl "i" "pin"
      + pl "z" "frames"
      + sep
      + done;
    tab =
      chip "magenta" "TAB"
      + pl "[ ]" "switch"
      + pl "; '" "move"
      + pl "n" "new"
      + pl "x" "close"
      + pl "r" "rename"
      + pl "1-9" "jump"
      + pl "⇥" "toggle"
      + sep
      + done;
    resize = chip "purple" "RESIZE" + pl "hjkl" "grow" + pl "HJKL" "shrink" + pl "= -" "all" + sep + done;
    move = chip "cyan" "MOVE" + pl "hjkl" "move" + pl "m" "next" + pl "p" "prev" + sep + done;
    scroll =
      chip "yellow" "SCROLL"
      + pl "jk" "line"
      + pl "hl" "page"
      + pl "du" "half"
      + pl "e" "edit"
      + pl "s" "search"
      + pl "${chords.layers.hyper.chip}c" "bottom"
      + sep
      + done;
    search =
      chip "pink" "SEARCH"
      + pl "n p" "next prev"
      + pl "c" "case"
      + pl "w" "wrap"
      + pl "o" "word"
      + pl "jk" "scroll"
      + sep
      + done;
    entersearch = chip "pink" "FIND" + seg "comment" "type query  " + pl "⏎" "search" + pl "esc" "back  ";
    session =
      chip "pink" "SESSION"
      + pl "s" "manager"
      + pl "d" "detach"
      + pl "c" "config"
      + pl "p" "plugins"
      + pl "a" "about"
      + pl "z" "share"
      + sep
      + done;
    renametab = chip "red" "RENAME TAB" + seg "comment" "type name  " + pl "⏎" "done" + pl "esc" "undo  ";
    renamepane = chip "red" "RENAME PANE" + seg "comment" "type name  " + pl "⏎" "done" + pl "esc" "undo  ";
    prompt = chip "foreground" "PROMPT";
    tmux =
      chip "green" "TMUX"
      + pl "\\\" %" "split"
      + pl "c" "tab"
      + pl "z" "zoom"
      + pl "n p" "tab ±"
      + pl "hjkl" "focus"
      + pl "d" "detach"
      + sep
      + done;
  };
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

        // --- Core Configuration -----------------------------------------------------
        theme                       "dracula"
        default_shell               "zsh"
        default_layout              "default"
        show_startup_tips           false
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

        // --- Plugin Aliases ---------------------------------------------------------
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
            format_right              "{pipe_agents}{pipe_quota}#[bg=$pink,fg=$background,bold] {session} "
            format_space              "#[bg=$surface]"

            pipe_agents_format        "{output}"
            pipe_agents_rendermode    "dynamic"
            pipe_quota_format         "{output}"
            pipe_quota_rendermode     "dynamic"

            swap_layout_format        "#[bg=$surface,fg=$purple,bold] {name} "
            swap_layout_hide_if_empty "true"

            tab_active    "#[bg=$cyan,fg=$background,bold] {name} "
            tab_normal    "#[bg=$surface,fg=$subtle] {name} "
            tab_separator " "
            tab_rename    "#[bg=$red,fg=$background,bold] {name} "

            border_enabled              "false"
            hide_frame_for_single_pane  "false"
          }

          // --- zjstatus-hints: bottom bar — mode chip + always-visible key ribbon ----
          // Same wasm, second instance; layer chips R⌘ (Hyper) and R⌥ (Super).
          zjstatus-hints location="file:~/.config/zellij/plugins/zjstatus.wasm" {
    ${colorRows}
            format_left   "{mode}"
            format_right  "#[bg=$surface,fg=$comment]${chords.zellij.hintsRight}"
            format_space  "#[bg=$surface]"

            mode_normal       "${ribbon.normal}"
            mode_locked       "${ribbon.locked}"
            mode_pane         "${ribbon.pane}"
            mode_tab          "${ribbon.tab}"
            mode_resize       "${ribbon.resize}"
            mode_move         "${ribbon.move}"
            mode_scroll       "${ribbon.scroll}"
            mode_search       "${ribbon.search}"
            mode_enter_search "${ribbon.entersearch}"
            mode_session      "${ribbon.session}"
            mode_rename_tab   "${ribbon.renametab}"
            mode_rename_pane  "${ribbon.renamepane}"
            mode_prompt       "${ribbon.prompt}"
            mode_tmux         "${ribbon.tmux}"
            mode_default_to_mode "normal"

            border_enabled              "false"
            hide_frame_for_single_pane  "false"
          }
        }

        // --- Keybindings ------------------------------------------------------------
    ${chords.zellij.headerComment}

        keybinds clear-defaults=true {
          normal {
            //  --- Simple Layer ------------------------------------------------------
    ${chords.zellij.normalBindsKdl}
          }

          // --- Universal Bindings (Except Locked Mode) ------------------------------
          shared_except "locked" {

            // --- Hyper Layer (⌘⌥⌃⇧) | Right Command ---------------------------------
    ${chords.zellij.hyperBindsKdl}

            // --- Super Layer (⌘⌥⌃) | (Right Option) ---------------------------------
    ${chords.zellij.superBindsKdl}
          }

          // --- Locked Mode ----------------------------------------------------------
          locked {
            bind "${pH} ${modes.locked.exitKey}" { SwitchToMode "Normal"; }
          }

          // --- Tab Mode -------------------------------------------------------------
          tab {
            ${exitBind modes.tab.key}
            bind "[" "Left" { GoToPreviousTab; }
            bind "]" "Right" { GoToNextTab; }
            bind ";" { MoveTab "Left"; }
            bind "'" { MoveTab "Right"; }
            bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
            bind "n" { NewTab; }
            bind "x" { CloseTab; }
    ${lib.concatMapStrings (i: ''        bind "${toString i}" { GoToTab ${toString i}; }
      '') (lib.range 1 9)}        bind "Tab" { ToggleTab; }
          }

          // --- Pane Mode ------------------------------------------------------------
          pane {
            ${exitBind modes.pane.key}
            bind "h" "Left" { MoveFocus "Left"; }
            bind "l" "Right" { MoveFocus "Right"; }
            bind "j" "Down" { MoveFocus "Down"; }
            bind "k" "Up" { MoveFocus "Up"; }
            bind "b" { BreakPane; }
            bind "]" { BreakPaneRight; }
            bind "[" { BreakPaneLeft; }
            bind "p" { SwitchFocus; }
            bind "n" { NewPane; SwitchToMode "Normal"; }
            bind "d" { NewPane "Down"; SwitchToMode "Normal"; }
            bind "r" { NewPane "Right"; SwitchToMode "Normal"; }
            bind "s" { NewPane "stacked"; SwitchToMode "Normal"; }
            bind "x" { CloseFocus; SwitchToMode "Normal"; }
            bind "f" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
            bind "z" { TogglePaneFrames; SwitchToMode "Normal"; }
            bind "w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
            bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }
            bind "c" { SwitchToMode "RenamePane"; PaneNameInput 0;}
            bind "i" { TogglePanePinned; SwitchToMode "Normal"; }
          }

          // --- Move Mode ------------------------------------------------------------
          move {
            ${exitBind modes.move.key}
            bind "m" "Tab" { MovePane; }
            bind "p" { MovePaneBackwards; }
            bind "h" "Left" { MovePane "Left"; }
            bind "j" "Down" { MovePane "Down"; }
            bind "k" "Up" { MovePane "Up"; }
            bind "l" "Right" { MovePane "Right"; }
          }

          // --- Resize Mode ----------------------------------------------------------
          resize {
            ${exitBind modes.resize.key}
            bind "h" "Left" { Resize "Increase Left"; }
            bind "j" "Down" { Resize "Increase Down"; }
            bind "k" "Up" { Resize "Increase Up"; }
            bind "l" "Right" { Resize "Increase Right"; }
            bind "H" { Resize "Decrease Left"; }
            bind "J" { Resize "Decrease Down"; }
            bind "K" { Resize "Decrease Up"; }
            bind "L" { Resize "Decrease Right"; }
            bind "=" "+" { Resize "Increase"; }
            bind "-" { Resize "Decrease"; }
          }

          // --- Scroll Mode ----------------------------------------------------------
          scroll {
            ${exitBind modes.scroll.key}
            bind "e" { EditScrollback; SwitchToMode "Normal"; }
            bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
            bind "${pH} c" { ScrollToBottom; SwitchToMode "Normal"; }

            ${scrollNavKdl}
          }

          // --- Search Mode ----------------------------------------------------------
          search {
            ${exitBind modes.scroll.key}
            bind "${pH} c" { ScrollToBottom; SwitchToMode "Normal"; }

            bind "c" { SearchToggleOption "CaseSensitivity"; }
            bind "w" { SearchToggleOption "Wrap"; }
            bind "o" { SearchToggleOption "WholeWord"; }

            bind "n" { Search "down"; }
            bind "p" { Search "up"; }

            ${scrollNavKdl}
          }

          // --- Session Mode ---------------------------------------------------------
          session {
            ${exitBind modes.session.key}
            bind "d" { Detach; }

            bind "s" {
              LaunchOrFocusPlugin "session-manager" {
                floating true
                move_to_focused_tab true
              };
              SwitchToMode "Normal"
            }

            bind "c" {
              LaunchOrFocusPlugin "configuration" {
                floating true
                move_to_focused_tab true
              };
              SwitchToMode "Normal"
            }

            bind "p" {
              LaunchOrFocusPlugin "plugin-manager" {
                floating true
                move_to_focused_tab true
              };
              SwitchToMode "Normal"
            }

            bind "a" {
              LaunchOrFocusPlugin "zellij:about" {
                floating true
                move_to_focused_tab true
              };
              SwitchToMode "Normal"
            }

            bind "z" {
              LaunchOrFocusPlugin "zellij:share" {
                floating true
                move_to_focused_tab true
              };
              SwitchToMode "Normal"
            }
          }

          // --- Prompt Mode ----------------------------------------------------------
          entersearch {
            bind "${pH} c" "Esc" { SwitchToMode "Scroll"; }            // Hyper (⌘⌥⌃⇧) | Right Command
            bind "Enter" { SwitchToMode "Search"; }
          }

          renametab {
            bind "${pH} c" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
            bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
          }

          renamepane {
            bind "${pH} c" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
            bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
          }

          // --- General bindings -----------------------------------------------------
          shared_except "normal" "locked" {
            bind "Enter" "Esc" { SwitchToMode "Normal"; }
          }
    ${chords.zellij.entryBindsKdl}

          // --- Tmux Mode ------------------------------------------------------------
          tmux {
            bind "${pH} ${modes.tmux.key}" { Write 2; SwitchToMode "Normal"; }         // Hyper (⌘⌥⌃⇧) | Right Command
            bind "[" { SwitchToMode "Scroll"; }
            bind "\"" { NewPane "Down"; SwitchToMode "Normal"; }
            bind "%" { NewPane "Right"; SwitchToMode "Normal"; }
            bind "z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
            bind "c" { NewTab; SwitchToMode "Normal"; }
            bind "," { SwitchToMode "RenameTab"; }
            bind "p" { GoToPreviousTab; SwitchToMode "Normal"; }
            bind "n" { GoToNextTab; SwitchToMode "Normal"; }
            bind "Left" { MoveFocus "Left"; SwitchToMode "Normal"; }
            bind "Right" { MoveFocus "Right"; SwitchToMode "Normal"; }
            bind "Down" { MoveFocus "Down"; SwitchToMode "Normal"; }
            bind "Up" { MoveFocus "Up"; SwitchToMode "Normal"; }
            bind "h" { MoveFocus "Left"; SwitchToMode "Normal"; }
            bind "l" { MoveFocus "Right"; SwitchToMode "Normal"; }
            bind "j" { MoveFocus "Down"; SwitchToMode "Normal"; }
            bind "k" { MoveFocus "Up"; SwitchToMode "Normal"; }
            bind "o" { FocusNextPane; }
            bind "d" { Detach; }
            bind "Space" { NextSwapLayout; }
            bind "x" { CloseFocus; SwitchToMode "Normal"; }
          }
        }

  '';
}
