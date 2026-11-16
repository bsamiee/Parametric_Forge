{
  lib,
  theme,
  ...
}: let
  inherit (theme) roles palette;
  c = {
    bg = roles.surface.base;
    surface = roles.surface.surface;
    selected = roles.surface.selected;
    fg = roles.text.primary;
    subtle = roles.text.subtle;
    muted = roles.text.muted;
    inverse = roles.text.inverse;
    focus = roles.accent.primary;
    accent2 = roles.accent.secondary;
    need = roles.inbox.needs_you;
    run = roles.inbox.working;
    idle = roles.state.info;
    fail = roles.inbox.failed;
    done = roles.inbox.done;
  };
  slots = ["base" "background" "emphasis_0" "emphasis_1" "emphasis_2" "emphasis_3"];
  components = [
    ["text_unselected" ["subtle" "bg" "need" "run" "idle" "accent2"]]
    ["text_selected" ["fg" "selected" "need" "run" "idle" "accent2"]]
    ["ribbon_unselected" ["fg" "surface" "need" "run" "idle" "accent2"]]
    ["ribbon_selected" ["inverse" "focus" "need" "run" "idle" "accent2"]]
    ["ribbon_hover" ["fg" "selected" "need" "run" "idle" "accent2"]]
    ["table_title" ["fg" "bg" "focus" "run" "idle" "accent2"]]
    ["table_cell_unselected" ["fg" "bg" "subtle" "focus" "idle" "accent2"]]
    ["table_cell_selected" ["fg" "selected" "focus" "run" "idle" "accent2"]]
    ["list_unselected" ["fg" "bg" "subtle" "focus" "idle" "accent2"]]
    ["list_selected" ["fg" "selected" "focus" "run" "idle" "accent2"]]
    ["frame_unselected" ["muted" "bg" "need" "run" "idle" "accent2"]]
    ["frame_selected" ["focus" "bg" "need" "run" "idle" "accent2"]]
    ["frame_highlight" ["accent2" "bg" "need" "accent2" "idle" "run"]]
    ["exit_code_success" ["done" "bg" "fg" "focus" "idle" "subtle"]]
    ["exit_code_error" ["fail" "bg" "fg" "focus" "idle" "subtle"]]
  ];
  players = [palette.cyan palette.yellow palette.magenta palette.green palette.pink palette.orange palette.comment palette.red palette.purple palette.blue];
  renderComponent = pair: ''
    ${builtins.elemAt pair 0} {
    ${lib.concatStrings (lib.zipListsWith (slot: role: "      ${slot} ${c.${role}.triple}\n") slots (builtins.elemAt pair 1))}    }'';
in {
  programs.zellij.themes.dracula = ''

    themes {
      "dracula" {
        ${lib.concatMapStringsSep "\n    " renderComponent components}
        multiplayer_user_colors {
    ${lib.concatStrings (lib.imap1 (i: color: "          player_${toString i} ${color.triple}\n") players)}        }
      }
    }

  '';
}
