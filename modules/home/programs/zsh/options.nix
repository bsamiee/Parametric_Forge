# Title         : options.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/options.nix
# ----------------------------------------------------------------------------
# Zsh options and settings
_: {
  programs.zsh = {
    # --- Directory Navigation -----------------------------------------------
    autocd = true;

    # --- Completion ---------------------------------------------------------
    enableCompletion = true;
    # Single stable dump under XDG cache; ZSH_COMPDUMP is exported pre-compinit in init.nix.
    completionInit = ''
      autoload -U compinit
      compinit -d "$ZSH_COMPDUMP"
    '';
    # strategy = [] suppresses the HM scalar; init.nix owns the final array post-atuin.
    autosuggestion = {
      enable = true;
      strategy = [];
    };
    syntaxHighlighting.enable = true;

    # --- History ------------------------------------------------------------
    # Fallback history config (Atuin overrides when enabled)
    history = {
      size = 50000;
      save = 50000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
    };
  };
}
