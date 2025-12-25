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
    autosuggestion.enable = true;
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
