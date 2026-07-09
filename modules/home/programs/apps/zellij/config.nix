# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/config.nix
# ----------------------------------------------------------------------------
# Nix-generated Zellij configuration; every chord row projects from the chord
# owner (modules/home/programs/apps/chords.nix), never hand-duplicated here.
{
  config,
  lib,
  ...
}: let
  inherit (config.forge.theme) palette; # Estate palette owner (modules/home/theme.nix)
  chords = config.forge.chords; # Chord-vocabulary owner (modules/home/programs/apps/chords.nix)
  pH = chords.zellij.prefix.hyper;
  inherit (chords) modes;

  # Shared color rows for both zjstatus instances; one palette, two surfaces.
  colorRows = lib.concatStrings (map (n: "        color_${n}    \"${palette.${n}.hex}\"\n") [
    "background"
    "current_line"
    "selection"
    "foreground"
    "comment"
    "purple"
    "cyan"
    "green"
    "yellow"
    "orange"
    "red"
    "magenta"
    "pink"
  ]);

  # Hint-ribbon grammar: native macOS modifier glyphs; a layer chip (R⌘ Hyper,
  # R⌥ Super) prefixes its key group once. Keys cyan, labels muted, mode chip
  # carries the state color shared with the top bar. Normal-mode rows project
  # from the chord owner; mode-internal rows document the literal mode bodies.
  seg = c: t: "#[bg=$background,fg=$" + c + "]" + t;
  segB = c: t: "#[bg=$background,fg=$" + c + ",bold]" + t;
  chip = c: t: "#[bg=$" + c + ",fg=$current_line,bold] " + t + " " + seg "comment" " ";
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
    locked = chip "selection" "LOCKED" + pl "${chords.layers.hyper.chip}${modes.locked.exitKey}" "unlock";
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
        pane_viewport_serialization true
        copy_command                "pbcopy"
        scroll_buffer_size          100000

        // Host web stance: server off, sharing disabled until reverse-proxy +
        // token-lifecycle rows exist (annex-gated exposure).
        web_server                  ${lib.boolToString config.programs.zellij.web.server}
        web_sharing                 "${config.programs.zellij.web.sharing}"

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

          // --- zjstatus: top bar — navigation identity (tabs, layout, session) -------
          // Agent/quota cells are pipe-fed by the forge-agents collector; the
          // bar renders cached text and never polls a provider itself.
          zjstatus location="file:~/.config/zellij/plugins/zjstatus.wasm" {
    ${colorRows}
            format_left               " {tabs}"
            format_center             "{swap_layout}"
            format_right              "{pipe_agents}{pipe_quota}#[bg=$pink,fg=$current_line,bold] {session} "
            format_space              "#[bg=$background]"

            pipe_agents_format        "#[bg=$background,fg=$orange,bold] {output} "
            pipe_agents_rendermode    "static"
            pipe_quota_format         "#[bg=$background,fg=$comment] {output} "
            pipe_quota_rendermode     "static"

            swap_layout_format        "#[bg=$background,fg=$yellow,bold] {name} "
            swap_layout_hide_if_empty "true"

            tab_active    "#[bg=$cyan,fg=$current_line,bold] {name} "
            tab_normal    "#[bg=$background,fg=$comment] {name} "
            tab_separator " "
            tab_rename    "#[bg=$red,fg=$current_line,bold] {name} "

            border_enabled              "false"
            hide_frame_for_single_pane  "false"
          }

          // --- zjstatus-hints: bottom bar — mode chip + always-visible key ribbon ----
          // Same wasm, second instance; layer chips R⌘ (Hyper) and R⌥ (Super).
          zjstatus-hints location="file:~/.config/zellij/plugins/zjstatus.wasm" {
    ${colorRows}
            format_left   "{mode}"
            format_right  "#[bg=$background,fg=$comment]${chords.zellij.hintsRight}"
            format_space  "#[bg=$background]"

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
            bind "${pH} ${modes.tab.key}" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
            bind "[" "Left" { GoToPreviousTab; }
            bind "]" "Right" { GoToNextTab; }
            bind ";" { MoveTab "Left"; }
            bind "'" { MoveTab "Right"; }
            bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
            bind "n" { NewTab; }
            bind "x" { CloseTab; }
            bind "1" { GoToTab 1; }
            bind "2" { GoToTab 2; }
            bind "3" { GoToTab 3; }
            bind "4" { GoToTab 4; }
            bind "5" { GoToTab 5; }
            bind "6" { GoToTab 6; }
            bind "7" { GoToTab 7; }
            bind "8" { GoToTab 8; }
            bind "9" { GoToTab 9; }
            bind "Tab" { ToggleTab; }
          }

          // --- Pane Mode ------------------------------------------------------------
          pane {
            bind "${pH} ${modes.pane.key}" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
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
            bind "${pH} ${modes.move.key}" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
            bind "m" "Tab" { MovePane; }
            bind "p" { MovePaneBackwards; }
            bind "h" "Left" { MovePane "Left"; }
            bind "j" "Down" { MovePane "Down"; }
            bind "k" "Up" { MovePane "Up"; }
            bind "l" "Right" { MovePane "Right"; }
          }

          // --- Resize Mode ----------------------------------------------------------
          resize {
            bind "${pH} ${modes.resize.key}" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
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
            bind "${pH} ${modes.scroll.key}" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
            bind "e" { EditScrollback; SwitchToMode "Normal"; }
            bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
            bind "${pH} c" { ScrollToBottom; SwitchToMode "Normal"; }

            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "l" "right" { PageScrollDown; }
            bind "h" "left" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
          }

          // --- Search Mode ----------------------------------------------------------
          search {
            bind "${pH} ${modes.scroll.key}" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
            bind "${pH} c" { ScrollToBottom; SwitchToMode "Normal"; }

            bind "c" { SearchToggleOption "CaseSensitivity"; }
            bind "w" { SearchToggleOption "Wrap"; }
            bind "o" { SearchToggleOption "WholeWord"; }

            bind "n" { Search "down"; }
            bind "p" { Search "up"; }

            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "l" "right" { PageScrollDown; }
            bind "h" "left" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
          }

          // --- Session Mode ---------------------------------------------------------
          session {
            bind "${pH} ${modes.session.key}" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
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
