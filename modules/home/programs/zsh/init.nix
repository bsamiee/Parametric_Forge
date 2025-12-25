# Title         : init.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/init.nix
# ----------------------------------------------------------------------------
# Zsh initialization - configuration only, plugins loaded by home-manager
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkBefore ''
      # --- Completion cache -------------------------------------------------------
      command mkdir -p -- "${config.xdg.cacheHome}/zsh"
      export ZSH_COMPDUMP="${config.xdg.cacheHome}/zsh/zcompdump-''${ZSH_VERSION}"

      # --- Load injected secrets (populated once at login by launchd) -----------
      [[ -f "$HOME/.config/hm-op-session.sh" ]] && source "$HOME/.config/hm-op-session.sh"

      # --- FZF Configuration -------------------------------------------------------
      # Custom completion functions
      _fzf_compgen_path() {
        fd --hidden --follow --exclude .git . "$1"
      }

      _fzf_compgen_dir() {
        fd --type d --hidden --follow --exclude .git . "$1"
      }

      # --- Tool Integration -------------------------------------------------------
      # Batman man page integration
      eval "$(${pkgs.bat-extras.batman}/bin/batman --export-env)"

      # fnm (Fast Node Manager) - prepends managed node to PATH
      eval "$(fnm env --use-on-cd)"

      # pnpm via fnm's npm (corepack removed - unreliable with fnm)
      # Run once manually if missing: npm install -g pnpm

      # Note: 1Password Shell Plugins (gh, aws, etc.) handled by programs._1password-shell-plugins
      # Note: SSH agent configured via ssh.nix IdentityAgent directive

    '')

    (lib.mkOrder 400 ''
      # --- Custom Completions (before compinit) -----------------------------------
      # Add custom completions directory to fpath
      mkdir -p "${config.xdg.dataHome}/zsh/completions"
      fpath=("${config.xdg.dataHome}/zsh/completions" $fpath)

      # Generate native completions for tools not covered by carapace
      if [[ ! -f "${config.xdg.dataHome}/zsh/completions/_zellij" ]]; then
        ${pkgs.zellij}/bin/zellij setup --generate-completion zsh > "${config.xdg.dataHome}/zsh/completions/_zellij"
      fi

      if [[ ! -f "${config.xdg.dataHome}/zsh/completions/_wezterm" ]]; then
        wezterm shell-completion --shell zsh > "${config.xdg.dataHome}/zsh/completions/_wezterm"
      fi

      if [[ ! -f "${config.xdg.dataHome}/zsh/completions/_atuin" ]]; then
        ${pkgs.atuin}/bin/atuin gen-completions --shell zsh > "${config.xdg.dataHome}/zsh/completions/_atuin"
      fi

      if [[ ! -f "${config.xdg.dataHome}/zsh/completions/_op" ]]; then
        ${pkgs._1password-cli}/bin/op completion zsh > "${config.xdg.dataHome}/zsh/completions/_op"
      fi
    '')

    (lib.mkOrder 550 ''
      # --- Completion zstyle configuration ----------------------------------------
      zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
      zstyle ':completion:*' use-cache true
      zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
      zstyle ':completion:*' menu no
      zstyle ':completion:*:git:*' group-name ""
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':carapace:*' nospace true  # Better spacing behavior
    '')

    (lib.mkOrder 600 ''
      # --- fzf-tab configuration (after carapace loads) ---------------------------
      zstyle ':fzf-tab:*' use-fzf-default-opts yes
      zstyle ':fzf-tab:*' fzf-pad 4
      zstyle ':fzf-tab:*' switch-group '<' '>'
      zstyle ':fzf-tab:*' fzf-flags --height=80%  # Explicitly set height (not inherited)
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
      zstyle ':fzf-tab:complete:kill:*' fzf-preview 'ps aux | grep -w $word'
      zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'systemctl status $word'
    '')

    (lib.mkOrder 650 ''
      # --- FZF Keybindings (suppress read-only option errors) --------------------
      # FZF 0.67.0 tries to restore the read-only 'zle' option, causing harmless
      # errors. Suppress stderr to keep output clean; FZF keybindings still register.
      if [[ $options[zle] = on ]]; then
        source <(fzf --zsh 2>/dev/null)
      fi
    '')

    (lib.mkOrder 700 ''
      # --- Atuin History Initialization (explicit, after FZF) -------------------
      # Ensures Atuin's keybindings register properly after FZF's initialization.
      # FZF's environment is stable at this point, so Atuin's widgets and key
      # bindings will be registered correctly in a clean state.
      if [[ $options[zle] = on ]]; then
        eval "$(${pkgs.atuin}/bin/atuin init zsh)"
      fi
    '')

    ''
      # --- Shell Options (these run after everything) -----------------------------
      setopt AUTO_PUSHD PUSHD_IGNORE_DUPS CDABLE_VARS

      # Keep npm invocations consistent without extra wrapper logic
      alias npm=pnpm

    ''
  ];
}
