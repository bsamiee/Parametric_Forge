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
        format_right              "#[bg=$current_line,fg=$yellow,bold] [{session}] "
        format_space              ""

        // --- Layout Display
        swap_layout_format        "#[bg=$current_line,fg=$cyan][layout: {name}]"
        swap_layout_hide_if_empty "true"

        // --- Mode Indicators
        mode_normal "#[bg=$current_line,fg=$green,bold] [NORMAL] "
        mode_resize "#[bg=$current_line,fg=$purple,bold] [RESIZE] "
        mode_tab    "#[bg=$current_line,fg=$magenta,bold] [TABS] "
        mode_pane   "#[bg=$current_line,fg=$orange,bold] [PANES] "
        mode_scroll "#[bg=$current_line,fg=$yellow,bold] [SCROLL] "
        mode_locked "#[bg=$current_line,fg=$selection,bold] [LOCKED] "
        mode_prompt "#[bg=$current_line,fg=$foreground,bold] [PROMPT] "
        mode_search "#[bg=$current_line,fg=$pink,bold] [SEARCH] "

        // --- Tab Display
        tab_active    "#[bg=$current_line,fg=$cyan] {name} "
        tab_normal    "#[bg=$current_line,fg=$comment] {name} "
        tab_separator " "

        // --- Border Configuration
        border_enabled              "false"
        border_char                 "─"
        border_format               "#[fg=$cyan]{char}"
        border_position             "bottom"
        hide_frame_for_single_pane  "false"
      }

      // --- pane-picker Configuration --------------------------------------------
      zellij-pane-picker location="file:~/.config/zellij/plugins/zellij-pane-picker.wasm" {
        list_panes          "Ctrl Alt Super Tab"
        plugin_select_down  "Down"
        plugin_select_up    "Up"
      }

    }

    // --- Keybindings ------------------------------------------------------------
    // Primary modifier   (Hyper)   : Ctrl Alt Shift Super  -> right Command
    // Secondary modifier (Super)   : Ctrl Alt Super        -> right Option
    keybinds clear-defaults=true {
      normal {
        // uncomment this and adjust key if using copy_on_select=false
        // bind "Ctrl Alt Super c" { Copy; }

        bind "Ctrl Alt Super Tab" {
          LaunchOrFocusPlugin "zellij-pane-picker" {
            floating            true
            move_to_focused_tab true
          }
        }
        // Super (⌘⌃⌥) + T → toggle sidebar layout
        bind "Ctrl Alt Super t" {
          Run "zellij-toggle-sidebar.sh"
        }
        // Hyper (⌘⌃⌥⇧) + L → launch workspace selector
        bind "Ctrl Alt Shift Super l" {
          LaunchOrFocusPlugin "file:~/.config/zellij/plugins/zellij-workspace.wasm" {
            floating true
            replace_current_session false
            debug false
          }
        }
      }
      locked {
        bind "Ctrl Alt Shift Super g" { SwitchToMode "Normal"; }
      }
      // Hyper layer (primary modifier)
      resize {
        bind "Ctrl Alt Shift Super n" { SwitchToMode "Normal"; }
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
      // Hyper layer (primary modifier)
      pane {
        bind "Ctrl Alt Shift Super p" { SwitchToMode "Normal"; }
        bind "h" "Left" { MoveFocus "Left"; }
        bind "l" "Right" { MoveFocus "Right"; }
        bind "j" "Down" { MoveFocus "Down"; }
        bind "k" "Up" { MoveFocus "Up"; }
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
      // Hyper layer (primary modifier)
      move {
        bind "Ctrl Alt Shift Super h" { SwitchToMode "Normal"; }
        bind "n" "Tab" { MovePane; }
        bind "p" { MovePaneBackwards; }
        bind "h" "Left" { MovePane "Left"; }
        bind "j" "Down" { MovePane "Down"; }
        bind "k" "Up" { MovePane "Up"; }
        bind "l" "Right" { MovePane "Right"; }
      }
      // Hyper layer (primary modifier)
      tab {
        bind "Ctrl Alt Shift Super t" { SwitchToMode "Normal"; }
        bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
        bind "h" "Left" "Up" "k" { GoToPreviousTab; }
        bind "l" "Right" "Down" "j" { GoToNextTab; }
        bind "n" { NewTab; SwitchToMode "Normal"; }
        bind "x" { CloseTab; SwitchToMode "Normal"; }
        bind "s" { ToggleActiveSyncTab; SwitchToMode "Normal"; }
        bind "b" { BreakPane; SwitchToMode "Normal"; }
        bind "]" { BreakPaneRight; SwitchToMode "Normal"; }
        bind "[" { BreakPaneLeft; SwitchToMode "Normal"; }
        bind "1" { GoToTab 1; SwitchToMode "Normal"; }
        bind "2" { GoToTab 2; SwitchToMode "Normal"; }
        bind "3" { GoToTab 3; SwitchToMode "Normal"; }
        bind "4" { GoToTab 4; SwitchToMode "Normal"; }
        bind "5" { GoToTab 5; SwitchToMode "Normal"; }
        bind "6" { GoToTab 6; SwitchToMode "Normal"; }
        bind "7" { GoToTab 7; SwitchToMode "Normal"; }
        bind "8" { GoToTab 8; SwitchToMode "Normal"; }
        bind "9" { GoToTab 9; SwitchToMode "Normal"; }
        bind "Tab" { ToggleTab; }
      }
      // Hyper layer (primary modifier)
      scroll {
        bind "Ctrl Alt Shift Super s" { SwitchToMode "Normal"; }
        bind "e" { EditScrollback; SwitchToMode "Normal"; }
        bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
        bind "Ctrl Alt Shift Super c" { ScrollToBottom; SwitchToMode "Normal"; }
        bind "j" "Down" { ScrollDown; }
        bind "k" "Up" { ScrollUp; }
        bind "Ctrl Alt Shift Super f" "PageDown" "Right" "l" { PageScrollDown; }
        bind "Ctrl Alt Shift Super b" "PageUp" "Left" "h" { PageScrollUp; }
        bind "d" { HalfPageScrollDown; }
        bind "u" { HalfPageScrollUp; }
        // uncomment this and adjust key if using copy_on_select=false
        // bind "Ctrl Alt Super c" { Copy; }
      }
      // Hyper layer (primary modifier)
      search {
        bind "Ctrl Alt Shift Super s" { SwitchToMode "Normal"; }
        bind "Ctrl Alt Shift Super c" { ScrollToBottom; SwitchToMode "Normal"; }
        bind "j" "Down" { ScrollDown; }
        bind "k" "Up" { ScrollUp; }
        bind "Ctrl Alt Shift Super f" "PageDown" "Right" "l" { PageScrollDown; }
        bind "Ctrl Alt Shift Super b" "PageUp" "Left" "h" { PageScrollUp; }
        bind "d" { HalfPageScrollDown; }
        bind "u" { HalfPageScrollUp; }
        bind "n" { Search "down"; }
        bind "p" { Search "up"; }
        bind "c" { SearchToggleOption "CaseSensitivity"; }
        bind "w" { SearchToggleOption "Wrap"; }
        bind "o" { SearchToggleOption "WholeWord"; }
      }
      // Hyper layer (primary modifier)
      entersearch {
        bind "Ctrl Alt Shift Super c" "Esc" { SwitchToMode "Scroll"; }
        bind "Enter" { SwitchToMode "Search"; }
      }
      // Hyper layer (primary modifier)
      renametab {
        bind "Ctrl Alt Shift Super c" { SwitchToMode "Normal"; }
        bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
      }
      // Hyper layer (primary modifier)
      renamepane {
        bind "Ctrl Alt Shift Super c" { SwitchToMode "Normal"; }
        bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
      }
      // Hyper layer (primary modifier)
      session {
        bind "Ctrl Alt Shift Super o" { SwitchToMode "Normal"; }
        bind "Ctrl Alt Shift Super s" { SwitchToMode "Scroll"; }
        bind "d" { Detach; }
        bind "w" {
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
        bind "s" {
          LaunchOrFocusPlugin "zellij:share" {
            floating true
            move_to_focused_tab true
          };
          SwitchToMode "Normal"
        }
      }
      // Hyper layer (primary modifier)
      tmux {
        bind "[" { SwitchToMode "Scroll"; }
        bind "Ctrl Alt Shift Super b" { Write 2; SwitchToMode "Normal"; }
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
      // Super layer (secondary modifier)
      // Super layer (secondary modifier)
      shared_except "locked" {
        bind "Ctrl Alt Shift Super g" { SwitchToMode "Locked"; }
        bind "Ctrl Alt Shift Super q" { Quit; }
        bind "Ctrl Alt Super f" { ToggleFloatingPanes; }
        bind "Ctrl Alt Super n" { NewPane; }
        bind "Ctrl Alt Super i" { MoveTab "Left"; }
        bind "Ctrl Alt Super o" { MoveTab "Right"; }
        bind "Ctrl Alt Super h" "Ctrl Alt Super Left" { MoveFocusOrTab "Left"; }
        bind "Ctrl Alt Super l" "Ctrl Alt Super Right" { MoveFocusOrTab "Right"; }
        bind "Ctrl Alt Super j" "Ctrl Alt Super Down" { MoveFocus "Down"; }
        bind "Ctrl Alt Super k" "Ctrl Alt Super Up" { MoveFocus "Up"; }
        bind "Ctrl Alt Super =" "Ctrl Alt Super +" { Resize "Increase"; }
        bind "Ctrl Alt Super -" { Resize "Decrease"; }
        bind "Ctrl Alt Super [" { PreviousSwapLayout; }
        bind "Ctrl Alt Super ]" { NextSwapLayout; }
        bind "Ctrl Alt Super p" { TogglePaneInGroup; }
        bind "Ctrl Alt Super Shift p" { ToggleGroupMarking; }
      }
      // general bindings (no modifier change needed)
      shared_except "normal" "locked" {
        bind "Enter" "Esc" { SwitchToMode "Normal"; }
      }
      shared_except "pane" "locked" {
        bind "Ctrl Alt Shift Super p" { SwitchToMode "Pane"; }
      }
      shared_except "resize" "locked" {
        bind "Ctrl Alt Shift Super n" { SwitchToMode "Resize"; }
      }
      shared_except "scroll" "locked" {
        bind "Ctrl Alt Shift Super s" { SwitchToMode "Scroll"; }
      }
      shared_except "session" "locked" {
        bind "Ctrl Alt Shift Super o" { SwitchToMode "Session"; }
      }
      shared_except "tab" "locked" {
        bind "Ctrl Alt Shift Super t" { SwitchToMode "Tab"; }
      }
      shared_except "move" "locked" {
        bind "Ctrl Alt Shift Super h" { SwitchToMode "Move"; }
      }
      shared_except "tmux" "locked" {
        bind "Ctrl Alt Shift Super b" { SwitchToMode "Tmux"; }
      }
    }

  '';
}
