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
      [[ ":$PATH:" != *":/etc/profiles/per-user/${config.home.username}/bin:"* ]] && \
        export PATH="/etc/profiles/per-user/${config.home.username}/bin:$PATH"
      [[ ":$PATH:" != *":/run/current-system/sw/bin:"* ]] && \
        export PATH="/run/current-system/sw/bin:$PATH"
      [[ ":$PATH:" != *":/nix/var/nix/profiles/default/bin:"* ]] && \
        export PATH="/nix/var/nix/profiles/default/bin:$PATH"

      # fnm (Fast Node Manager) — .zshenv ensures all zsh processes get node on PATH
      # (Claude Code MCP servers, VS Code tasks, scripts, not just interactive shells)
      [[ -z "$FNM_MULTISHELL_PATH" ]] && [[ -x /opt/homebrew/bin/fnm ]] && \
        eval "$(/opt/homebrew/bin/fnm env --use-on-cd --version-file-strategy=recursive)"
    '';

    profileExtra = ''
      # --- PATH initialization -------------------------------------------------
      # Rhino and language toolchain paths are managed declaratively in environments/shell.nix

      # Nix (Determinate Nix)
      if [[ -d "/nix/var/nix/profiles/default/bin" ]]; then
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
