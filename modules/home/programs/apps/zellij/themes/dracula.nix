# Title         : dracula.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/themes/dracula.nix
# ----------------------------------------------------------------------------
# Nix-generated Zellij component theme from the estate palette owner
{config, ...}: let
  inherit (config.forge.theme) palette;
  rgb = c: c.triple; # Component theme rows take decimal RGB triples
in {
  xdg.configFile."zellij/themes/dracula.kdl".text = ''
    // Title         : dracula.kdl
    // Author        : Bardia Samiee
    // Project       : Parametric Forge
    // License       : MIT
    // Path          : ~/.config/zellij/themes/dracula.kdl
    // ----------------------------------------------------------------------------
    // Zellij component theme generated from the Forge palette owner

    themes {
      "dracula" {
        text_unselected {
          base ${rgb palette.cyan}
          background ${rgb palette.current_line}
          emphasis_0 ${rgb palette.orange}
          emphasis_1 ${rgb palette.yellow}
          emphasis_2 ${rgb palette.cyan}
          emphasis_3 ${rgb palette.orange}
        }
        text_selected {
          base ${rgb palette.orange}
          background ${rgb palette.current_line}
          emphasis_0 ${rgb palette.cyan}
          emphasis_1 ${rgb palette.foreground}
          emphasis_2 ${rgb palette.foreground}
          emphasis_3 ${rgb palette.foreground}
        }
        // Inactive status ribbons: bright keys on raised surface
        ribbon_unselected {
          base ${rgb palette.foreground}
          background ${rgb palette.current_line}
          emphasis_0 ${rgb palette.cyan}
          emphasis_1 ${rgb palette.foreground}
          emphasis_2 ${rgb palette.foreground}
          emphasis_3 ${rgb palette.foreground}
        }
        // Active ribbon highlight when a mode is entered
        ribbon_selected {
          base ${rgb palette.current_line}
          background ${rgb palette.orange}
          emphasis_0 ${rgb palette.cyan}
          emphasis_1 ${rgb palette.yellow}
          emphasis_2 ${rgb palette.magenta}
          emphasis_3 ${rgb palette.comment}
        }
        table_title {
          base ${rgb palette.foreground}
          background ${rgb palette.current_line}
          emphasis_0 ${rgb palette.cyan}
          emphasis_1 ${rgb palette.yellow}
          emphasis_2 ${rgb palette.magenta}
          emphasis_3 ${rgb palette.comment}
        }
        table_cell_unselected {
          base ${rgb palette.foreground}
          background ${rgb palette.background}
          emphasis_0 ${rgb palette.comment}
          emphasis_1 ${rgb palette.cyan}
          emphasis_2 ${rgb palette.yellow}
          emphasis_3 ${rgb palette.magenta}
        }
        table_cell_selected {
          base ${rgb palette.foreground}
          background ${rgb palette.selection}
          emphasis_0 ${rgb palette.cyan}
          emphasis_1 ${rgb palette.yellow}
          emphasis_2 ${rgb palette.pink}
          emphasis_3 ${rgb palette.comment}
        }
        list_unselected {
          base ${rgb palette.foreground}
          background ${rgb palette.background}
          emphasis_0 ${rgb palette.comment}
          emphasis_1 ${rgb palette.cyan}
          emphasis_2 ${rgb palette.yellow}
          emphasis_3 ${rgb palette.magenta}
        }
        list_selected {
          base ${rgb palette.current_line}
          background ${rgb palette.cyan}
          emphasis_0 ${rgb palette.orange}
          emphasis_1 ${rgb palette.yellow}
          emphasis_2 ${rgb palette.magenta}
          emphasis_3 ${rgb palette.comment}
        }
        frame_unselected {
          base ${rgb palette.comment}
          background ${rgb palette.background}
          emphasis_0 ${rgb palette.orange}
          emphasis_1 ${rgb palette.cyan}
          emphasis_2 ${rgb palette.yellow}
          emphasis_3 ${rgb palette.magenta}
        }
        frame_selected {
          base ${rgb palette.cyan}
          background ${rgb palette.background}
          emphasis_0 ${rgb palette.green}
          emphasis_1 ${rgb palette.yellow}
          emphasis_2 ${rgb palette.magenta}
          emphasis_3 ${rgb palette.foreground}
        }
        frame_highlight {
          base ${rgb palette.magenta}
          background ${rgb palette.background}
          emphasis_0 ${rgb palette.cyan}
          emphasis_1 ${rgb palette.yellow}
          emphasis_2 ${rgb palette.foreground}
          emphasis_3 ${rgb palette.green}
        }
        exit_code_success {
          base ${rgb palette.green}
          background ${rgb palette.background}
          emphasis_0 ${rgb palette.foreground}
          emphasis_1 ${rgb palette.cyan}
          emphasis_2 ${rgb palette.yellow}
          emphasis_3 ${rgb palette.comment}
        }
        exit_code_error {
          base ${rgb palette.red}
          background ${rgb palette.background}
          emphasis_0 ${rgb palette.foreground}
          emphasis_1 ${rgb palette.cyan}
          emphasis_2 ${rgb palette.yellow}
          emphasis_3 ${rgb palette.comment}
        }
        multiplayer_user_colors {
          player_1 ${rgb palette.cyan}
          player_2 ${rgb palette.yellow}
          player_3 ${rgb palette.magenta}
          player_4 ${rgb palette.green}
          player_5 ${rgb palette.pink}
          player_6 ${rgb palette.orange}
          player_7 ${rgb palette.comment}
          player_8 ${rgb palette.red}
          player_9 ${rgb palette.purple}
          player_10 ${rgb palette.cyan}
        }
      }
    }

  '';
}
