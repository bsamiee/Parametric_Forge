# Title         : init.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/init.nix
# ----------------------------------------------------------------------------
# Zsh initialization and dynamic configurations

{ config, lib, pkgs, ... }:

{
  programs.zsh.initContent = lib.mkMerge [
    # Shell options (order 100)
    (lib.mkOrder 100 ''
      # Directory navigation
      setopt AUTO_PUSHD PUSHD_IGNORE_DUPS CDABLE_VARS
    '')

    # Core completion configuration (order 200) - before plugins
    (lib.mkOrder 200 ''
      # --- Core Completion Settings ----------------------------------------
      # Disable default menu (required for fzf-tab)
      zstyle ':completion:*' menu no

      # Enable completion descriptions with formatting
      zstyle ':completion:*:descriptions' format '[%d]'

      # Case-insensitive matching
      zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'

      # Completion cache for performance
      zstyle ':completion:*' use-cache true
      zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/completion-cache"

      # Disable sorting for git checkout
      zstyle ':completion:*:git-checkout:*' sort false
    '')

    # Plugin loading (order 1200) - must be AFTER compinit
    (lib.mkOrder 1200 ''
      # Load fzf-tab FIRST (must be after compinit)
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      # Pre-export FORGIT to prevent false warning (forgit bug - checks but doesn't export)
      export FORGIT="${pkgs.zsh-forgit}/bin/git-forgit"

      # Load forgit (other variables are exported via sessionVariables in shell.nix)
      source ${pkgs.zsh-forgit}/share/zsh/zsh-forgit/forgit.plugin.zsh

      # Load you-should-use (alias reminders)
      source ${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh

      # Load zsh-completions (additional completion definitions)
      # Note: zsh-completions adds to fpath, no explicit sourcing needed
    '')

    # fzf-tab configuration (order 1300) - AFTER plugin is loaded
    (lib.mkOrder 1300 ''
      # --- fzf-tab Configuration --------------------------------------------
      # CRITICAL: Configure fzf-tab to use FZF_DEFAULT_OPTS (includes Stylix colors)
      zstyle ':fzf-tab:*' fzf-command fzf
      # Don't override FZF_DEFAULT_OPTS - let fzf-tab inherit them
      zstyle ':fzf-tab:*' fzf-flags ""

      # Switch between groups using ',' and '.'
      zstyle ':fzf-tab:*' switch-group ',' '.'

      # Continuous completion trigger for path navigation
      # Type /u/l/b and hit / to expand to /usr/local/bin
      zstyle ':fzf-tab:*' continuous-trigger '/'

      # Use tmux popup if in tmux
      zstyle ':fzf-tab:*' popup-min-size 80 12
      zstyle ':fzf-tab:*' fzf-min-height 20

      # --- Preview configurations for different commands -------------------
      # Directory completions (eza inherits its config)
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza $realpath'
      zstyle ':fzf-tab:complete:cdi:*' fzf-preview 'eza $realpath'
      zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza $realpath'
      zstyle ':fzf-tab:complete:zi:*' fzf-preview 'eza $realpath'

      # File operations (bat inherits its config)
      zstyle ':fzf-tab:complete:(cat|bat|less|more):*' fzf-preview 'bat --line-range=:100 $realpath 2>/dev/null || cat $realpath'
      zstyle ':fzf-tab:complete:(vim|nvim|vi):*' fzf-preview 'bat --line-range=:100 $realpath 2>/dev/null || head -100 $realpath'

      # Git commands
      zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --graph --color=always $word'
      zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --oneline --graph --color=always'

      # Ripgrep (shows file preview when completing filenames)
      zstyle ':fzf-tab:complete:(rg|ripgrep):*' fzf-preview '[[ -f $realpath ]] && bat --line-range=:100 $realpath'

      # Broot (br command)
      zstyle ':fzf-tab:complete:br:*' fzf-preview '[[ -d $realpath ]] && eza $realpath || bat --line-range=:100 $realpath'

      # fd (fast file finder)
      zstyle ':fzf-tab:complete:fd:*' fzf-preview '[[ -f $realpath ]] && bat --color=always $realpath || [[ -d $realpath ]] && eza $realpath'

      # Trash command
      zstyle ':fzf-tab:complete:trash:*' fzf-preview '[[ -f $realpath ]] && bat --line-range=:100 $realpath || file $realpath'

      # Atuin commands
      zstyle ':fzf-tab:complete:atuin:*' fzf-preview 'atuin --help'
      zstyle ':fzf-tab:complete:atuin-search:*' fzf-preview 'echo "Search command history with context and filters"'
      zstyle ':fzf-tab:complete:atuin-stats:*' fzf-preview 'atuin stats 2>/dev/null || echo "Show command usage statistics"'

      # Process/kill completion with process details
      zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps -p $word -o comm='
    '')

    # User customizations (order 9000)
    (lib.mkOrder 9000 ''
      # Advanced fzf completion customization per command
      _fzf_comprun() {
        local command=$1
        shift

        case "$command" in
          cd)           fzf "$@" --preview '[[ -d {} ]] && eza -la --color=always --icons --git {} || echo "Not a directory"' ;;
          export|unset) fzf "$@" --preview "eval 'echo \$'{}" ;;
          ssh)          fzf "$@" --preview 'dig +short {} 2>/dev/null || echo "No DNS record"' ;;
          kill)         fzf "$@" --preview 'ps -p {} -o comm= -o pid= -o %cpu= -o %mem= -o state= 2>/dev/null' ;;
          docker)       fzf "$@" --preview 'docker inspect {} 2>/dev/null | jq -C ".[0] | {Name, State, Image, Ports}" 2>/dev/null || docker logs --tail=20 {} 2>/dev/null' ;;
          git)          fzf "$@" --preview 'git log --oneline --graph --color=always -n 20 {} 2>/dev/null || git show --color=always {} 2>/dev/null' ;;
          man)          fzf "$@" --preview 'man {} 2>/dev/null | col -bx | bat -l man -p --color=always' ;;
          npm)          fzf "$@" --preview 'npm info {} 2>/dev/null | head -30' ;;
          brew)         fzf "$@" --preview 'brew info {} 2>/dev/null | head -20' ;;
          atuin)        fzf "$@" --preview 'echo "Modern shell history - use atuin search <query> for full-text search"' ;;
          systemctl)    fzf "$@" --preview 'systemctl status {} 2>/dev/null; echo "---"; systemctl cat {} 2>/dev/null | head -20' ;;
          # Tool integrations
          fd)           fzf "$@" --preview '[[ -f {} ]] && bat --color=always {} || [[ -d {} ]] && eza {} || file {}' ;;
          rg|ripgrep)   fzf "$@" --preview 'rg --color=always --context=3 {q} {} 2>/dev/null' ;;
          br)           fzf "$@" --preview '[[ -d {} ]] && eza --tree --level=2 {} || bat --color=always {}' ;;
          # Forgit git commands
          ga|grh|gcf)   fzf "$@" --preview 'git diff --color=always {} 2>/dev/null || git log --oneline -n 5 {} 2>/dev/null' ;;
          # Nix ecosystem
          nix)          fzf "$@" --preview 'nix show-derivation {} 2>/dev/null | jq -C . | head -50 || echo "Nix package: {}"' ;;
          *)            fzf "$@" ;;
        esac
      }
    '')
  ];
}