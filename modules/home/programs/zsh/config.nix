# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/config.nix
# ----------------------------------------------------------------------------
# Zsh .zshenv env floor: PATH-neutral nix/Homebrew metadata and the never-clobber session-variable fallback.

{
  config,
  forgeToolchainEnvFor,
  lib,
  ...
}: let
  toolchainEnv = forgeToolchainEnvFor {
    home = config.home.homeDirectory;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
  };
  # Never-clobber .zshenv floor mirroring the session-variable rows: shells whose parent scrubbed the env behind __HM_SESS_VARS_SOURCED still
  # recover these. A new resilient var is one row; the fold owns the :- idiom.
  fallbackEnv = {
    GH_CONFIG_DIR = "${config.xdg.configHome}/gh";
    CLOUDSDK_CONFIG = "${config.xdg.configHome}/gcloud";
    WORKSPACE_MCP_CREDENTIALS_DIR = "${config.xdg.cacheHome}/workspace-mcp";
    GOOGLE_WORKSPACE_CLI_CONFIG_DIR = "${config.xdg.configHome}/gws";
    GOOGLE_WORKSPACE_PROJECT_ID = "workspace-mcp-500605";
    MAGHZ_REMOTE_HOST = "31.97.131.41";
    MAGHZ_REMOTE_USER = "maghz-agent";
    MAGHZ_REMOTE_WORKROOT = "/home/maghz-agent/maghz";
    PAGER = "less";
    GH_PAGER = "delta";
    GIT_PAGER = "delta";
    LESS = "-RFX";
  };
  fallbackExports =
    lib.concatMapStrings
    (name: ''
      export ${name}="''${${name}:-${fallbackEnv.${name}}}"
    '')
    (lib.attrNames fallbackEnv);
in {
  programs.zsh = {
    # Runs in .zshenv for ALL shells (login, interactive, scripts, zellij panes). PATH has ONE owner: home.sessionPath via hm-session-vars; no writers here.
    envExtra = ''
      if [[ -o interactive && -z "''${TERM:-}" ]]; then
        export TERM="dumb"
      fi

      # Nix daemon profile without PATH authority: non-login panes get NIX_* certs/profiles; PATH restore keeps home.sessionPath the single owner
      # and the sourced-guard makes the /etc/zshrc login pass a no-op.
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

      ${toolchainEnv.shellExports toolchainEnv.scientificSessionEnv}
      ${fallbackExports}
    '';
  };
}
