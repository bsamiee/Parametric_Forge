# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/config.nix
# ----------------------------------------------------------------------------
# Zsh profile and login shell configurations
{
  config,
  forgeToolchainEnvFor,
  ...
}: let
  toolchainEnv = forgeToolchainEnvFor {
    home = config.home.homeDirectory;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
  };
in {
  programs.zsh = {
    # Runs in .zshenv for ALL shells (login, interactive, scripts, zellij panes).
    # PATH has ONE owner: home.sessionPath via hm-session-vars; no writers here.
    envExtra = ''
      if [[ -o interactive && -z "''${TERM:-}" ]]; then
        export TERM="dumb"
      fi

      # Nix daemon profile without PATH authority: non-login panes get NIX_*
      # certs/profiles; PATH restore keeps home.sessionPath the single owner and
      # the sourced-guard makes the /etc/zshrc login pass a no-op.
      if [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
        _forge_prenix_path="$PATH"
        source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        export PATH="$_forge_prenix_path"
        unset _forge_prenix_path
      fi

      # Homebrew metadata without PATH authority; membership guards block nested growth.
      if [[ -x "/opt/homebrew/bin/brew" ]]; then
        export HOMEBREW_PREFIX="/opt/homebrew"
        export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
        export HOMEBREW_REPOSITORY="/opt/homebrew"
        [[ ":''${MANPATH:-}:" != *":/opt/homebrew/share/man:"* ]] && \
          export MANPATH="/opt/homebrew/share/man''${MANPATH+:$MANPATH}:"
        [[ ":''${INFOPATH:-}:" != *":/opt/homebrew/share/info:"* ]] && \
          export INFOPATH="/opt/homebrew/share/info:''${INFOPATH:-}"
      fi

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
  };
}
