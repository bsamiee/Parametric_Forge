# Title         : dracula.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/themes/dracula.nix
# ----------------------------------------------------------------------------
# Nix-generated Dracula theme for Zellij

{ config, lib, pkgs, ... }:

let
  colors = config.programs.zellij.colors;                     # Use shared colors from module option
  rgb = c: "${toString c.r} ${toString c.g} ${toString c.b}"; # Helper to format RGB values for theme definition
in
{
  xdg.configFile."zellij/themes/dracula.kdl".text = ''
    // Title         : dracula.kdl
    // Author        : Bardia Samiee
    // Project       : Parametric Forge
    // License       : MIT
    // Path          : modules/home/programs/apps/zellij/dracula.kdl
    // ----------------------------------------------------------------------------
    // Zellij theme matching the custom Parametric Forge Dracula palette

    // --- Color Definitions ------------------------------------------------------
    // Define color variables for zjstatus plugin (these use hex values)
    color_background    "${colors.background.hex}"  // (${toString colors.background.r}, ${toString colors.background.g}, ${toString colors.background.b})
    color_current_line  "${colors.current_line.hex}"  // (${toString colors.current_line.r}, ${toString colors.current_line.g}, ${toString colors.current_line.b})
    color_selection     "${colors.selection.hex}"  // (${toString colors.selection.r}, ${toString colors.selection.g}, ${toString colors.selection.b})
    color_foreground    "${colors.foreground.hex}"  // (${toString colors.foreground.r}, ${toString colors.foreground.g}, ${toString colors.foreground.b})
    color_comment       "${colors.comment.hex}"  // (${toString colors.comment.r}, ${toString colors.comment.g}, ${toString colors.comment.b})
    color_purple        "${colors.purple.hex}"  // (${toString colors.purple.r}, ${toString colors.purple.g}, ${toString colors.purple.b})
    color_cyan          "${colors.cyan.hex}"  // (${toString colors.cyan.r}, ${toString colors.cyan.g}, ${toString colors.cyan.b})
    color_green         "${colors.green.hex}"  // (${toString colors.green.r}, ${toString colors.green.g}, ${toString colors.green.b})
    color_yellow        "${colors.yellow.hex}"  // (${toString colors.yellow.r}, ${toString colors.yellow.g}, ${toString colors.yellow.b})
    color_orange        "${colors.orange.hex}"  // (${toString colors.orange.r}, ${toString colors.orange.g}, ${toString colors.orange.b})
    color_red           "${colors.red.hex}"  // (${toString colors.red.r}, ${toString colors.red.g}, ${toString colors.red.b})
    color_magenta       "${colors.magenta.hex}"  // (${toString colors.magenta.r}, ${toString colors.magenta.g}, ${toString colors.magenta.b})
    color_pink          "${colors.pink.hex}"  // (${toString colors.pink.r}, ${toString colors.pink.g}, ${toString colors.pink.b})

    // --- Theme Definition -------------------------------------------------------
    // Zellij themes require RGB decimal values (not hex or variables)
    themes {
      "dracula" {
        text_unselected {
          base ${rgb colors.cyan}                 // Color of "CTRL" on left side of status bar
          background ${rgb colors.current_line}   // BG of left side mod (CTRL) and space between left/right, AND the background of <x> when in a MODE
          emphasis_0 ${rgb colors.orange}         // Color of "ALT" on right side of status bar - Match with ribbon selected background
          emphasis_1 ${rgb colors.yellow}         // UNKNOWN
          emphasis_2 ${rgb colors.cyan}           // Color of secondary key characters when in a "mode" like PANE or TAB <x> <y>
          emphasis_3 ${rgb colors.orange}         // UNKNOWN
        }
        text_selected {
          base ${rgb colors.orange}               // Color of text that is highlighted/selected and bottom left helper text when selecting something
          background ${rgb colors.current_line}   // Selecte text highliter color (background of it)
          emphasis_0 ${rgb colors.cyan}           // UNKNOWN
          emphasis_1 ${rgb colors.foreground}     // UNKNOWN
          emphasis_2 ${rgb colors.foreground}     // UNKNOWN
          emphasis_3 ${rgb colors.foreground}     // UNKNOWN
        }
        // Inactive status ribbons (LOCK / TAB labels)
        ribbon_unselected {
          base ${rgb colors.foreground}           // Color of all ribbon text and <> indicators (not the characters inside <>) both default+active modes
          background ${rgb colors.current_line}   // Background fill of the ribbon text blocks when in DEFAULT mode NOT an active mode
          emphasis_0 ${rgb colors.cyan}           // Color of primary key character when in default state <x> <y> etc...
          emphasis_1 ${rgb colors.foreground}     // UNKNOWN
          emphasis_2 ${rgb colors.foreground}     // UNKNOWN
          emphasis_3 ${rgb colors.foreground}     // UNKNOWN
        }
        // Active ribbon highlight when entering a mode (e.g., PANE mode)
        ribbon_selected {
          base ${rgb colors.current_line}         // Text color of PANE or TAB when in a mode + bar background (small portion)
          background ${rgb colors.orange}         // Background of primary key character when in a "mode" like PANE or TAB <p> <t>
          emphasis_0 ${rgb colors.cyan}           // Color of primary key character when in a "mode" like PANE or TAB <p> <t>
          emphasis_1 ${rgb colors.yellow}         // UNKNOWN
          emphasis_2 ${rgb colors.magenta}        // UNKNOWN
          emphasis_3 ${rgb colors.comment}        // UNKNOWN
        }
        table_title {
          base ${rgb colors.foreground}
          background ${rgb colors.current_line}
          emphasis_0 ${rgb colors.cyan}
          emphasis_1 ${rgb colors.yellow}
          emphasis_2 ${rgb colors.magenta}
          emphasis_3 ${rgb colors.comment}
        }
        table_cell_unselected {
          base ${rgb colors.foreground}
          background ${rgb colors.background}
          emphasis_0 ${rgb colors.comment}
          emphasis_1 ${rgb colors.cyan}
          emphasis_2 ${rgb colors.yellow}
          emphasis_3 ${rgb colors.magenta}
        }
        table_cell_selected {
          base ${rgb colors.foreground}
          background ${rgb colors.selection}
          emphasis_0 ${rgb colors.cyan}
          emphasis_1 ${rgb colors.yellow}
          emphasis_2 ${rgb colors.pink}
          emphasis_3 ${rgb colors.comment}
        }
        list_unselected {
          base ${rgb colors.foreground}
          background ${rgb colors.background}
          emphasis_0 ${rgb colors.comment}
          emphasis_1 ${rgb colors.cyan}
          emphasis_2 ${rgb colors.yellow}
          emphasis_3 ${rgb colors.magenta}
        }
        list_selected {
          base ${rgb colors.current_line}
          background ${rgb colors.cyan}
          emphasis_0 ${rgb colors.orange}
          emphasis_1 ${rgb colors.yellow}
          emphasis_2 ${rgb colors.magenta}
          emphasis_3 ${rgb colors.comment}
        }
        frame_unselected {
          base ${rgb colors.comment}
          background ${rgb colors.background}
          emphasis_0 ${rgb colors.orange}
          emphasis_1 ${rgb colors.cyan}
          emphasis_2 ${rgb colors.yellow}
          emphasis_3 ${rgb colors.magenta}
        }
        frame_selected {
          base ${rgb colors.cyan}
          background ${rgb colors.background}
          emphasis_0 ${rgb colors.green}
          emphasis_1 ${rgb colors.yellow}
          emphasis_2 ${rgb colors.magenta}
          emphasis_3 ${rgb colors.foreground}
        }
        frame_highlight {
          base ${rgb colors.magenta}
          background ${rgb colors.background}
          emphasis_0 ${rgb colors.cyan}
          emphasis_1 ${rgb colors.yellow}
          emphasis_2 ${rgb colors.foreground}
          emphasis_3 ${rgb colors.green}
        }
        exit_code_success {
          base ${rgb colors.green}
          background ${rgb colors.background}
          emphasis_0 ${rgb colors.foreground}
          emphasis_1 ${rgb colors.cyan}
          emphasis_2 ${rgb colors.yellow}
          emphasis_3 ${rgb colors.comment}
        }
        exit_code_error {
          base ${rgb colors.red}
          background ${rgb colors.background}
          emphasis_0 ${rgb colors.foreground}
          emphasis_1 ${rgb colors.cyan}
          emphasis_2 ${rgb colors.yellow}
          emphasis_3 ${rgb colors.comment}
        }
        multiplayer_user_colors {
          player_1 ${rgb colors.cyan}
          player_2 ${rgb colors.yellow}
          player_3 ${rgb colors.magenta}
          player_4 ${rgb colors.green}
          player_5 ${rgb colors.pink}
          player_6 ${rgb colors.orange}
          player_7 ${rgb colors.comment}
          player_8 ${rgb colors.red}
          player_9 ${rgb colors.purple}
          player_10 ${rgb colors.cyan}
        }
      }
    }

  '';
}
