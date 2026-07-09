# Title         : process-compose.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/process-compose.nix
# ----------------------------------------------------------------------------
# Non-container process orchestration for project-local service meshes; the
# package row lives in the owner table. Placement rationale: container-tools
# owns the container/Kubernetes axis, launchd owns durable machine services,
# and process-compose is a general foreground workflow runner whose
# process-compose.yaml files are always project-owned — so shell-tools owns it.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette roles;
  yamlFormat = pkgs.formats.yaml {};

  # theme.yaml backs the TUI "Custom Style" selector entry.
  forgeStyle.style = {
    body = {
      fgColor = roles.text.primary.hex;
      bgColor = roles.surface.base.hex;
      secondaryTextColor = roles.text.muted.hex;
      tertiaryTextColor = roles.accent.primary.hex;
      borderColor = roles.surface.selected.hex;
    };
    stat_table = {
      keyFgColor = roles.accent.structural.hex;
      valueFgColor = roles.text.primary.hex;
      bgColor = roles.surface.base.hex;
      logoColor = roles.accent.secondary.hex;
    };
    proc_table = {
      fgColor = roles.text.primary.hex;
      fgWarning = roles.state.warning.hex;
      fgPending = roles.text.muted.hex;
      fgCompleted = roles.state.success.hex;
      fgError = roles.state.danger.hex;
      bgColor = roles.surface.base.hex;
      headerFgColor = roles.accent.primary.hex;
    };
    help = {
      fgColor = roles.text.primary.hex;
      keyColor = roles.accent.primary.hex;
      hlColor = roles.state.success.hex;
      buttonBgColor = palette.comment.hex;
      categoryFgColor = roles.accent.structural.hex;
    };
    dialog = {
      fgColor = roles.text.primary.hex;
      bgColor = roles.surface.raised.hex;
      contrastBgColor = roles.surface.overlay.hex;
      attentionBgColor = roles.state.attention.hex;
      buttonFgColor = roles.text.inverse.hex;
      buttonBgColor = palette.comment.hex;
      buttonFocusFgColor = roles.text.inverse.hex;
      buttonFocusBgColor = roles.accent.primary.hex;
      labelFgColor = roles.state.warning.hex;
      fieldFgColor = roles.text.primary.hex;
      fieldBgColor = roles.surface.selected.hex;
    };
  };
in {
  xdg.configFile."process-compose/theme.yaml".source = yamlFormat.generate "process-compose-theme" forgeStyle;

  # settings.yaml is TUI-mutated state (theme/sort auto-save); seed the custom
  # style selection once, never overwrite later user edits.
  home.activation.seedProcessComposeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    settings="${config.xdg.configHome}/process-compose/settings.yaml"
    if [ ! -f "$settings" ]; then
      run mkdir -p "${config.xdg.configHome}/process-compose"
      run sh -c "printf 'theme: Custom Style\n' > \"$settings\""
    fi
  '';
}
