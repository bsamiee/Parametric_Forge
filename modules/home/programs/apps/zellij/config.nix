# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/config.nix
# ----------------------------------------------------------------------------
# Nix-generated Zellij configuration

{ config, lib, pkgs, ... }:

let
  colors = config.programs.zellij.colors; # Use shared colors from module option
in
{
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
    default_layout              "side"
    show_startup_tips           false
    simplified_ui               true
    mouse_mode                  true
    pane_frames                 true
    session_serialization       true
    pane_viewport_serialization true
    copy_command                "pbcopy"
    scroll_buffer_size          100000

    // --- Load Plugins -----------------------------------------------------------
    load_plugins {
      // zjstatus
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
      // --- pane-picker Configuration --------------------------------------------
      zellij-pane-picker location="https://github.com/shihanng/zellij-pane-picker/releases/download/v0.6.0/zellij-pane-picker.wasm" {
        list_panes          "Super Alt Ctrl \\"
        plugin_select_down  "Down"
        plugin_select_up    "Up"
      }

      // --- zjstatus Configuration -----------------------------------------------
      zjstatus location="file:~/.config/zellij/plugins/zjstatus.wasm" {
        // --- Color Definitions
        color_background    "${colors.background.hex}"
        color_current_line  "${colors.current_line.hex}"
        color_selection     "${colors.selection.hex}"
        color_foreground    "${colors.foreground.hex}"
        color_comment       "${colors.comment.hex}"
        color_purple        "${colors.purple.hex}"
        color_cyan          "${colors.cyan.hex}"
        color_green         "${colors.green.hex}"
        color_yellow        "${colors.yellow.hex}"
        color_orange        "${colors.orange.hex}"
        color_red           "${colors.red.hex}"
        color_magenta       "${colors.magenta.hex}"
        color_pink          "${colors.pink.hex}"

        // --- Format Configuration
        format_left               "{mode} {tabs}"
        format_center             "{swap_layout}"
        format_right              "#[bg=$pink,fg=$current_line,bold] [{session}] "
        format_space              ""

        // --- Layout Display
        swap_layout_format        "#[bg=$background,fg=$cyan,bold][layout: {name}]"
        swap_layout_hide_if_empty "true"

        // --- Mode Indicators
        mode_normal "#[bg=$green,fg=$current_line,bold] [NORMAL] "
        mode_resize "#[bg=$purple,fg=$current_line,bold] [RESIZE] "
        mode_tab    "#[bg=$magenta,fg=$current_line,bold] [TABS] "
        mode_pane   "#[bg=$orange,fg=$current_line,bold] [PANES] "
        mode_scroll "#[bg=$yellow,fg=$current_line,bold] [SCROLL] "
        mode_prompt "#[bg=$foreground,fg=$current_line,bold] [PROMPT] "
        mode_search "#[bg=$pink,fg=$current_line,bold] [SEARCH] "
        mode_locked "#[bg=$selection,fg=$current_line,bold] [LOCKED] "
        mode_tmux   "#[bg=$background,fg=$green,bold] [TMUX] "

        // --- Tab Display
        tab_active    "#[bg=$cyan,fg=$current_line,bold] {name} "
        tab_normal    "#[bg=$comment,fg=$current_line,bold] {name} "
        tab_separator " "
        tab_rename    "#[bg=$red,fg=$current_line,bold] -> {name} <- "

        // --- Border Configuration
        border_enabled              "false"
        border_char                 "─"
        border_format               "#[fg=$cyan]{char}"
        border_position             "bottom"
        hide_frame_for_single_pane  "false"
      }
    }

    // --- Keybindings ------------------------------------------------------------
    // Primary Modifier:    Right Command   → Hyper (⌘⌥⌃⇧)  leader | Super Alt Ctrl Shift
    // Secondary Modifier:  Right Option    → Super (⌘⌥⌃)   leader | Super Alt Ctrl
    // Tertiary Modifier:   Right Shift     → Power (⌥⌃⇧)   leader | Alt Ctrl Shift

    keybinds clear-defaults=true {
      normal {
        // uncomment this and adjust key if using copy_on_select=false
        // bind "Super c" { Copy; }

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

        // --- Super Layer (⌘⌥⌃) | (Right Option) ---------------------------------
        bind "Super Alt Ctrl \\" {
            LaunchOrFocusPlugin "zellij-pane-picker" {
                floating            true;
                move_to_focused_tab true;
            }
        }

        bind "Super Alt Ctrl f" { ToggleFloatingPanes; }
        bind "Super Alt Ctrl n" { NewPane; }

        bind "Super Alt Ctrl [" { GoToPreviousTab; }
        bind "Super Alt Ctrl ]" { GoToNextTab; }
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
        bind "f" { SwitchToMode "EnterSearch"; SearchInput 0; }

        bind "j" "Down" { ScrollDown; }
        bind "k" "Up" { ScrollUp; }
        bind "l" "right" { PageScrollDown; }
        bind "h" "left" { PageScrollUp; }
        bind "i" { HalfPageScrollDown; }
        bind "o" { HalfPageScrollUp; }
      }

      // --- Search Mode ----------------------------------------------------------
      search {
        bind "Super Alt Ctrl Shift f" { SwitchToMode "Normal"; }                  // Hyper (⌘⌥⌃⇧) | Right Command
        bind "c" { SearchToggleOption "CaseSensitivity"; }
        bind "w" { SearchToggleOption "Wrap"; }
        bind "o" { SearchToggleOption "WholeWord"; }

        bind "n" { Search "down"; }
        bind "p" { Search "up"; }

        bind "j" "Down" { ScrollDown; }
        bind "k" "Up" { ScrollUp; }
        bind "l" "right" { PageScrollDown; }
        bind "h" "left" { PageScrollUp; }
        bind "i" { HalfPageScrollDown; }
        bind "o" { HalfPageScrollUp; }
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
