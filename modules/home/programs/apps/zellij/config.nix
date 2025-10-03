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

    // --- Core configuration -----------------------------------------------------
    theme               "dracula"
    default_shell       "zsh"
    default_layout      "terminal"
    simplified_ui       true
    mouse_mode          true
    pane_frames         true
    show_startup_tips   false
    copy_command        "pbcopy"
    scroll_buffer_size  100000

    // --- Load plugins -----------------------------------------------------------
    load_plugins {
      // zjstatus
      zjstatus-hints
      zellij-pane-picker
    }

    // --- Plugin aliases ---------------------------------------------------------
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

      // --- zjstatus configuration -----------------------------------------------
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
        format_left   "{mode} {tabs}"
        format_center ""
        format_right  "{pipe_zjstatus_hints}"
        format_space  ""
        pipe_zjstatus_hints_format "{output}"

        // --- Mode Indicators
        mode_normal "#[bg=$green,fg=$background] [NORMAL] "
        mode_resize "#[bg=$purple,fg=$background] [RESIZE] "
        mode_tab "#[bg=$magenta,fg=$background] [TABS] "
        mode_pane "#[bg=$orange,fg=$background] [PANES] "
        mode_scroll "#[bg=$yellow,fg=$background] [SCROLL] "
        mode_locked "#[bg=$selection,fg=$background] [LOCKED] "
        mode_prompt "#[bg=$foreground,fg=$background] [PROMPT] "
        mode_search "#[bg=$pink,fg=$background] [SEARCH] "

        // --- Tab Display
        tab_normal    "#[bg=$comment,fg=$background] {name} "
        tab_active    "#[bg=$cyan,fg=$background] {name} "
        tab_separator " "

        // --- Border Configuration
        border_enabled  "false"
        border_char     "─"
        border_format   "#[fg=$cyan]{char}"
        border_position "bottom"
        hide_frame_for_single_pane "false"
      }

      // --- zjstatus-hints configuration -----------------------------------------
      zjstatus-hints location="file:~/.config/zellij/plugins/zjstatus-hints.wasm" {
        pipe_name "zjstatus_hints"
        hide_in_base_mode false
      }

      // --- pane-picker configuration --------------------------------------------
      zellij-pane-picker location="file:~/.config/zellij/plugins/zellij-pane-picker.wasm" {
        list_panes          "Alt Tab"
        plugin_select_down  "Down"
        plugin_select_up    "Up"
      }
    }

    // --- Keybindings ------------------------------------------------------------
    keybinds {
      normal {
        bind "Alt y" {
          LaunchOrFocusPlugin "zellij-pane-picker" {
            floating true
            move_to_focused_tab true
          }
        }
      }
    }

  '';
}
