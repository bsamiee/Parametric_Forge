# Title         : secrets.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/secrets.nix
# ----------------------------------------------------------------------------
# Secret token reference definitions (safe to commit)

{ config, pkgs, ... }:

let
  envTemplate = "${config.xdg.configHome}/op/env.template";
  withSecrets = pkgs.writeShellApplication {
    name = "with-secrets";
    text = ''
      set -euo pipefail
      if [ ! -f "${envTemplate}" ]; then
        echo "with-secrets: missing ${envTemplate}" >&2
        exit 1
      fi
      exec op run --env-file "${envTemplate}" -- "$@"
    '';
  };
in {
  # Provide a wrapper to inject secrets on-demand instead of exporting unresolved references globally
  home.packages = [ with-secrets ];

  home.sessionVariables = {
    OP_DEFAULT_ENV_FILE = envTemplate;
  };
}
