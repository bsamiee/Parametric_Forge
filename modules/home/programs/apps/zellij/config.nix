# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/config.nix
# ----------------------------------------------------------------------------
# Nix-generated Zellij configuration
{
  config,
  lib,
  ...
}: let
  inherit (config.forge.theme) palette; # Estate palette owner (modules/home/theme.nix)

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
  # carries the state color shared with the top bar.
  seg = c: t: "#[bg=$background,fg=$" + c + "]" + t;
  segB = c: t: "#[bg=$background,fg=$" + c + ",bold]" + t;
  chip = c: t: "#[bg=$" + c + ",fg=$current_line,bold] " + t + " " + seg "comment" " ";
  lay = c: t: "#[bg=$" + c + ",fg=$current_line,bold] " + t + " " + seg "comment" " ";
  pl = k: l: segB "cyan" k + seg "comment" (" " + l + "  ");
  sep = seg "selection" "│ ";
  done = pl "⏎" "done";
  ribbon = {
    normal =
      chip "green" "NORMAL"
      + lay "magenta" "R⌘"
      + pl "p" "pane"
      + pl "t" "tab"
      + pl "r" "resize"
      + pl "m" "move"
      + pl "s" "scroll"
      + pl "o" "session"
      + pl "g" "lock"
      + pl "/" "sheet"
      + lay "purple" "R⌥"
      + pl "y" "files"
      + pl "n" "pane"
      + pl "f" "float"
      + pl "\\\\" "jump"
      + pl "[ ]" "tab ±";
    locked = chip "selection" "LOCKED" + pl "R⌘l" "unlock";
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
      + pl "R⌘c" "bottom"
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

        // --- Load Plugins -----------------------------------------------------------
        // zjstatus and compact-bar render from layout panes; only pane-picker needs
        // a background start for cross-tab pane tracking.
        load_plugins {
          zellij-pane-picker
        }

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
          // --- pane-picker Configuration --------------------------------------------
          zellij-pane-picker location="file:~/.config/zellij/plugins/zellij-pane-picker.wasm" {
            // Empty disables the plugin's global rebind; its KDL template breaks on "\" keys.
            // Launch stays on the explicit LaunchOrFocusPlugin bind in keybinds.
            list_panes          ""
            plugin_select_down  "Down"
            plugin_select_up    "Up"
          }

          // --- zjstatus: top bar — navigation identity (tabs, layout, session) -------
          zjstatus location="file:~/.config/zellij/plugins/zjstatus.wasm" {
    ${colorRows}
            format_left               " {tabs}"
            format_center             "{swap_layout}"
            format_right              "#[bg=$pink,fg=$current_line,bold] {session} "
            format_space              "#[bg=$background]"

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
            format_right  "#[bg=$background,fg=$comment]R⌘ hyper · R⌥ super "
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
        // Primary Modifier:    Right Command   → Hyper (⌘⌥⌃⇧)  leader | Super Alt Ctrl Shift
        // Secondary Modifier:  Right Option    → Super (⌘⌥⌃)   leader | Super Alt Ctrl
        // Tertiary Modifier:   Right Shift     → Power (⌥⌃⇧)   leader | Alt Ctrl Shift

        keybinds clear-defaults=true {
          normal {
            //  --- Simple Layer ------------------------------------------------------
            bind "Super t" {            // Create new tab without entering tab mode
              NewTab;
              SwitchToMode "Normal";
            }
            bind "Super w" {            // Close pane without entering pane mode
              CloseFocus;
              SwitchToMode "Normal";
            }
          }

          // --- Universal Bindings (Except Locked Mode) ------------------------------
          shared_except "locked" {

            // --- Hyper Layer (⌘⌥⌃⇧) | Right Command ---------------------------------
            bind "Super Alt Ctrl Shift g" { SwitchToMode "Locked"; }
            bind "Super Alt Ctrl Shift q" { Quit; }
            bind "Super Alt Ctrl Shift [" { PreviousSwapLayout; }
            bind "Super Alt Ctrl Shift ]" { NextSwapLayout; }
            bind "Super Alt Ctrl Shift /" {
              LaunchOrFocusPlugin "zellij-forgot" {
                "LOAD_ZELLIJ_BINDINGS" "false"
                "lock" "Hyper g"
                "unlock (locked)" "Hyper l"
                "pane mode" "Hyper p"
                "tab mode" "Hyper t"
                "resize mode" "Hyper r"
                "scroll mode" "Hyper s"
                "session mode" "Hyper o"
                "move mode" "Hyper m"
                "tmux mode" "Hyper b"
                "swap layout prev/next" "Hyper [ / Hyper ]"
                "quit zellij" "Hyper q"
                "cheatsheet" "Hyper /"
                "new tab" "Super t"
                "close pane" "Super w"
                "yazi popup" "Super Alt Ctrl y"
                "pane picker" "Super Alt Ctrl \\"
                "previous/next tab" "Super Alt Ctrl [ / ]"
                "new pane" "Super Alt Ctrl n"
                "toggle floating panes" "Super Alt Ctrl f"
                "move focus" "Super Alt Ctrl h/j/k/l"
                "resize" "Super Alt Ctrl = / -"
                "pane group toggle/mark" "Super Alt Ctrl p / g"
                "editor" "nv / vim -> nvim"
                "file manager" "y -> yazi popup (Super Alt Ctrl y)"
                "git ui" "lazygit float (pane mode w)"
                "json explore" "jqi -> jnv"
                "loc report" "loc <path>"
                "folder map" "tree <path>"
                "deploy" "forge-redeploy --check-only / --build / --switch"
                "http" "GET/POST/PUT -> xh"
                floating true
                move_to_focused_tab true
              };
              SwitchToMode "Normal"
            }

            // --- Super Layer (⌘⌥⌃) | (Right Option) ---------------------------------
            bind "Super Alt Ctrl \\" {
                LaunchOrFocusPlugin "zellij-pane-picker" {
                    floating            true;
                    move_to_focused_tab true;
                }
            }
            bind "Super Alt Ctrl [" { GoToPreviousTab; }
            bind "Super Alt Ctrl ]" { GoToNextTab; }

            bind "Super Alt Ctrl f" { ToggleFloatingPanes; }
            bind "Super Alt Ctrl n" { NewPane; }
            // In-place dispatcher: leaves floating visibility readable, then toggles
            // the per-tab Yazi popup (create / show+focus / hide).
            bind "Super Alt Ctrl y" {
              Run "forge-yazi.sh" "toggle" {
                in_place true
                close_on_exit true
              }
            }

            bind "Super Alt Ctrl h" "Super Alt Ctrl Left" { MoveFocusOrTab "Left"; }
            bind "Super Alt Ctrl l" "Super Alt Ctrl Right" { MoveFocusOrTab "Right"; }
            bind "Super Alt Ctrl j" "Super Alt Ctrl Down" { MoveFocus "Down"; }
            bind "Super Alt Ctrl k" "Super Alt Ctrl Up" { MoveFocus "Up"; }
            bind "Super Alt Ctrl =" "Super Alt Ctrl +" { Resize "Increase"; }
            bind "Super Alt Ctrl -" { Resize "Decrease"; }
            bind "Super Alt Ctrl p" { TogglePaneInGroup; }
            bind "Super Alt Ctrl g" { ToggleGroupMarking; }
          }

          // --- Locked Mode ----------------------------------------------------------
          locked {
            bind "Super Alt Ctrl Shift l" { SwitchToMode "Normal"; }
          }

          // --- Tab Mode -------------------------------------------------------------
          tab {
            bind "Super Alt Ctrl Shift t" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
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
            bind "Super Alt Ctrl Shift p" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
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
            bind "Super Alt Ctrl Shift m" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
            bind "m" "Tab" { MovePane; }
            bind "p" { MovePaneBackwards; }
            bind "h" "Left" { MovePane "Left"; }
            bind "j" "Down" { MovePane "Down"; }
            bind "k" "Up" { MovePane "Up"; }
            bind "l" "Right" { MovePane "Right"; }
          }

          // --- Resize Mode ----------------------------------------------------------
          resize {
            bind "Super Alt Ctrl Shift r" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
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
            bind "Super Alt Ctrl Shift s" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
            bind "e" { EditScrollback; SwitchToMode "Normal"; }
            bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
            bind "Super Alt Ctrl Shift c" { ScrollToBottom; SwitchToMode "Normal"; }

            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "l" "right" { PageScrollDown; }
            bind "h" "left" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
          }

          // --- Search Mode ----------------------------------------------------------
          search {
            bind "Super Alt Ctrl Shift s" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
            bind "Super Alt Ctrl Shift c" { ScrollToBottom; SwitchToMode "Normal"; }

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
            bind "Super Alt Ctrl Shift o" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
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
            bind "Super Alt Ctrl Shift c" "Esc" { SwitchToMode "Scroll"; }            // Hyper (⌘⌥⌃⇧) | Right Command
            bind "Enter" { SwitchToMode "Search"; }
          }

          renametab {
            bind "Super Alt Ctrl Shift c" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
            bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
          }

          renamepane {
            bind "Super Alt Ctrl Shift c" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
            bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
          }

          // --- General bindings -----------------------------------------------------
          shared_except "normal" "locked" {
            bind "Enter" "Esc" { SwitchToMode "Normal"; }
          }
          shared_except "pane" "locked" {
            bind "Super Alt Ctrl Shift p" { SwitchToMode "Pane"; }
          }
          shared_except "resize" "locked" {
            bind "Super Alt Ctrl Shift r" { SwitchToMode "Resize"; }
          }
          shared_except "scroll" "locked" {
            bind "Super Alt Ctrl Shift s" { SwitchToMode "Scroll"; }
          }
          shared_except "session" "locked" {
            bind "Super Alt Ctrl Shift o" { SwitchToMode "Session"; }
          }
          shared_except "tab" "locked" {
            bind "Super Alt Ctrl Shift t" { SwitchToMode "Tab"; }
          }
          shared_except "move" "locked" {
            bind "Super Alt Ctrl Shift m" { SwitchToMode "Move"; }
          }
          shared_except "tmux" "locked" {
            bind "Super Alt Ctrl Shift b" { SwitchToMode "Tmux"; }
          }

          // --- Tmux Mode ------------------------------------------------------------
          tmux {
            bind "Super Alt Ctrl Shift b" { Write 2; SwitchToMode "Normal"; }         // Hyper (⌘⌥⌃⇧) | Right Command
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
