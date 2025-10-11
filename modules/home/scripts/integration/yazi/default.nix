# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/integration/yazi/default.nix
# ----------------------------------------------------------------------------
# Yazi integration helpers

{ config, lib, pkgs, ... }:

let
  fzfDefaultOpts =
    lib.concatStringsSep " " (config.programs.fzf.defaultOptions or [ ]);

  fzfDefaultOptsNonEmpty =
    fzfDefaultOpts != "";

  fzfDefaultCommand =
    config.programs.fzf.defaultCommand or "";

  fzfDefaultCommandNonEmpty =
    fzfDefaultCommand != "";
in
{
  home.file.".local/bin/yazi-zoxide-cdi.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : yazi-zoxide-cdi.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : modules/home/scripts/integration/yazi/yazi-zoxide-cdi.sh
      # ----------------------------------------------------------------------------
      # Change directory using zoxide and open in yazi

      set -euo pipefail

${lib.optionalString fzfDefaultOptsNonEmpty ''
      if [[ -z "''${FZF_DEFAULT_OPTS:-}" ]]; then
        FZF_DEFAULT_OPTS=${lib.escapeShellArg fzfDefaultOpts}
      fi

      ''}

${lib.optionalString fzfDefaultCommandNonEmpty ''
      if [[ -z "''${FZF_DEFAULT_COMMAND:-}" ]]; then
        FZF_DEFAULT_COMMAND=${lib.escapeShellArg fzfDefaultCommand}
      fi

    ''}

      export FZF_DEFAULT_OPTS FZF_DEFAULT_COMMAND

      selection="$(${pkgs.zoxide}/bin/zoxide query --interactive -- "$@" || true)"

      if [[ -z "$selection" ]]; then
        exit 0
      fi

      ${pkgs.yazi}/bin/ya cd --str "$selection"

    '';
  };
}
