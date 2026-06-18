# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/config.nix
# ----------------------------------------------------------------------------
# Zsh profile and login shell configurations
{config, ...}: {
  programs.zsh = {
    # Runs in .zshenv for ALL shells (login, interactive, scripts)
    # Ensures nix paths are always available, even when hm-session-vars guard triggers
    envExtra = ''
      # Ensure nix-darwin paths are in PATH (VS Code inherits guard but not PATH)
      [[ ":$PATH:" != *":/nix/var/nix/profiles/default/bin:"* ]] && \
        export PATH="/nix/var/nix/profiles/default/bin:$PATH"
      [[ ":$PATH:" != *":/run/current-system/sw/bin:"* ]] && \
        export PATH="/run/current-system/sw/bin:$PATH"
      [[ ":$PATH:" != *":/etc/profiles/per-user/${config.home.username}/bin:"* ]] && \
        export PATH="/etc/profiles/per-user/${config.home.username}/bin:$PATH"

      export DOCKER_HOST="''${DOCKER_HOST:-unix://${config.xdg.dataHome}/colima/default/docker.sock}"
      export COLIMA_HOME="''${COLIMA_HOME:-${config.xdg.dataHome}/colima}"
      export DOCKER_CONFIG="''${DOCKER_CONFIG:-${config.xdg.configHome}/docker}"
      export UV_PYTHON_PREFERENCE="''${UV_PYTHON_PREFERENCE:-only-system}"
      export UV_PYTHON_DOWNLOADS="''${UV_PYTHON_DOWNLOADS:-never}"
      export UV_CACHE_DIR="''${UV_CACHE_DIR:-${config.xdg.cacheHome}/uv}"
      export GH_CONFIG_DIR="''${GH_CONFIG_DIR:-${config.xdg.configHome}/gh}"
      export PNPM_HOME="''${PNPM_HOME:-${config.xdg.dataHome}/pnpm}"
      export PAGER="''${PAGER:-less}"
      export GH_PAGER="''${GH_PAGER:-less}"
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
