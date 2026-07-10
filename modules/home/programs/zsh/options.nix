# Title         : options.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/options.nix
# ----------------------------------------------------------------------------
# Zsh options and settings; completion surface is owned by completions.nix
_: {
  programs.zsh = {
    # --- [DIRECTORY_NAVIGATION]
    autocd = true;
    setOptions = ["AUTO_PUSHD" "PUSHD_IGNORE_DUPS" "CDABLE_VARS" "COMPLETE_IN_WORD"];

    # --- [SUGGESTION_HIGHLIGHTING]
    # strategy = [] suppresses the HM scalar; init.nix owns the final array post-atuin.
    autosuggestion = {
      enable = true;
      strategy = [];
    };
    # zsh-syntax-highlighting over fast-syntax-highlighting: both upstreams idle, so a swap buys no currency; HM owns z-sy-h natively at order
    # 1200. Terminal ANSI palette carries the theme tokens.
    syntaxHighlighting.enable = true;

    # --- [HISTORY]
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
