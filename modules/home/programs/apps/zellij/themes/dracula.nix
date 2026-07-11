# Title         : dracula.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/themes/dracula.nix
# ----------------------------------------------------------------------------
# Nix-generated Zellij component theme from the estate palette owner. One row per component:
# [ base background emphasis_0 emphasis_1 emphasis_2 emphasis_3 ] as palette role names; the renderer is one fold over the rows.
{
  config,
  lib,
  ...
}: let
  inherit (config.forge.theme) palette;
  rgb = role: palette.${role}.triple; # Component theme rows take decimal RGB triples
  slots = ["base" "background" "emphasis_0" "emphasis_1" "emphasis_2" "emphasis_3"];
  components = [
    ["text_unselected" ["cyan" "current_line" "orange" "yellow" "cyan" "orange"]]
    ["text_selected" ["orange" "current_line" "cyan" "foreground" "foreground" "foreground"]]
    ["ribbon_unselected" ["foreground" "current_line" "cyan" "foreground" "foreground" "foreground"]]
    ["ribbon_selected" ["current_line" "orange" "cyan" "yellow" "magenta" "comment"]] # Highlighted when a mode is entered.
    ["table_title" ["foreground" "current_line" "cyan" "yellow" "magenta" "comment"]]
    ["table_cell_unselected" ["foreground" "background" "comment" "cyan" "yellow" "magenta"]]
    ["table_cell_selected" ["foreground" "selection" "cyan" "yellow" "pink" "comment"]]
    ["list_unselected" ["foreground" "background" "comment" "cyan" "yellow" "magenta"]]
    ["list_selected" ["current_line" "cyan" "orange" "yellow" "magenta" "comment"]]
    ["frame_unselected" ["comment" "background" "orange" "cyan" "yellow" "magenta"]]
    ["frame_selected" ["cyan" "background" "green" "yellow" "magenta" "foreground"]]
    ["frame_highlight" ["magenta" "background" "cyan" "yellow" "foreground" "green"]]
    ["exit_code_success" ["green" "background" "foreground" "cyan" "yellow" "comment"]]
    ["exit_code_error" ["red" "background" "foreground" "cyan" "yellow" "comment"]]
  ];
  playerRoles = ["cyan" "yellow" "magenta" "green" "pink" "orange" "comment" "red" "purple" "cyan"];
  renderComponent = pair: let
    name = builtins.elemAt pair 0;
    roleRows = builtins.elemAt pair 1;
  in
    # zipListsWith truncates to the shorter list: a mis-arity row drops or invents emphasis slots silently, so arity gates at eval.
    assert lib.assertMsg (builtins.length roleRows == builtins.length slots) "zellij theme ${name}: one role per slot (${toString (builtins.length slots)})"; ''
      ${name} {
      ${lib.concatStrings (lib.zipListsWith (slot: role: "      ${slot} ${rgb role}\n") slots roleRows)}    }'';
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
        ${lib.concatMapStringsSep "\n    " renderComponent components}
        multiplayer_user_colors {
    ${lib.concatStrings (lib.imap1 (i: role: "          player_${toString i} ${rgb role}\n") playerRoles)}        }
      }
    }

  '';
}
