# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/config.nix
# ----------------------------------------------------------------------------
# Zsh profile and login shell configurations
{
  config,
  lib,
  pkgs,
  ...
}: let
  toolchainEnv = import ../../../common/toolchain-env.nix {
    inherit lib pkgs;
    home = config.home.homeDirectory;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
    xdgDataHome = config.xdg.dataHome;
  };
in {
  programs.zsh = {
    # Runs in .zshenv for ALL shells (login, interactive, scripts)
    # Ensures nix paths are always available, even when hm-session-vars guard triggers
    envExtra = ''
      if [[ -o interactive && -z "''${TERM:-}" ]]; then
        export TERM="dumb"
      fi

      # Ensure Forge session paths exist when GUI-launched shells miss Home Manager session vars.
      for _forge_path in \
        ${lib.concatMapStringsSep " \\\n        " lib.escapeShellArg (lib.reverseList toolchainEnv.userPathEntries)}
      do
        [[ ":$PATH:" != *":$_forge_path:"* ]] && export PATH="$_forge_path:$PATH"
      done
      unset _forge_path

      export DOCKER_HOST="''${DOCKER_HOST:-unix://${config.xdg.dataHome}/colima/default/docker.sock}"
      export COLIMA_HOME="''${COLIMA_HOME:-${config.xdg.dataHome}/colima}"
      export DOCKER_CONFIG="''${DOCKER_CONFIG:-${config.xdg.configHome}/docker}"
      ${toolchainEnv.shellExports toolchainEnv.scientificSessionEnv}
      export GH_CONFIG_DIR="''${GH_CONFIG_DIR:-${config.xdg.configHome}/gh}"
      export CLOUDSDK_CONFIG="''${CLOUDSDK_CONFIG:-${config.xdg.configHome}/gcloud}"
      export WORKSPACE_MCP_CREDENTIALS_DIR="''${WORKSPACE_MCP_CREDENTIALS_DIR:-${config.xdg.cacheHome}/workspace-mcp}"
      export GOOGLE_WORKSPACE_CLI_CONFIG_DIR="''${GOOGLE_WORKSPACE_CLI_CONFIG_DIR:-${config.xdg.configHome}/gws}"
      export GOOGLE_WORKSPACE_PROJECT_ID="''${GOOGLE_WORKSPACE_PROJECT_ID:-workspace-mcp-500605}"
      export MAGHZ_REMOTE_HOST="''${MAGHZ_REMOTE_HOST:-31.97.131.41}"
      export MAGHZ_REMOTE_USER="''${MAGHZ_REMOTE_USER:-maghz-agent}"
      export MAGHZ_REMOTE_WORKROOT="''${MAGHZ_REMOTE_WORKROOT:-/home/maghz-agent/maghz}"
      export PNPM_HOME="''${PNPM_HOME:-${config.xdg.dataHome}/pnpm}"
      export PAGER="''${PAGER:-less}"
      export GH_PAGER="''${GH_PAGER:-delta}"
      export GIT_PAGER="''${GIT_PAGER:-delta}"
      export LESS="''${LESS:--RFX}"

    '';

    profileExtra = ''
      # --- PATH initialization -------------------------------------------------
      # Rhino and language toolchain paths are managed declaratively in environments/shell.nix

      # Nix (Determinate Nix)
      if [[ -d "/nix/var/nix/profiles/default/bin" ]]; then
        [[ ":$PATH:" != *":/nix/var/nix/profiles/default/bin:"* ]] && \
          export PATH="/nix/var/nix/profiles/default/bin:$PATH"
      fi

      # Homebrew (Darwin) - full shellenv equivalent with PATH appended (Nix stays first)
      if [[ -x "/opt/homebrew/bin/brew" ]]; then
        export HOMEBREW_PREFIX="/opt/homebrew"
        export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
        export HOMEBREW_REPOSITORY="/opt/homebrew"
        [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]] && export PATH="$PATH:/opt/homebrew/bin"
        [[ ":$PATH:" != *":/opt/homebrew/sbin:"* ]] && export PATH="$PATH:/opt/homebrew/sbin"
        export MANPATH="/opt/homebrew/share/man''${MANPATH+:$MANPATH}:"
        export INFOPATH="/opt/homebrew/share/info:''${INFOPATH:-}"
      fi

      # Nix daemon sourcing for Determinate Nix
      if [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
        source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
      fi
    '';

    loginExtra = ''
      # Commands to run on login go here
    '';

    logoutExtra = ''
      # Commands to run on logout go here
    '';
  };
}
