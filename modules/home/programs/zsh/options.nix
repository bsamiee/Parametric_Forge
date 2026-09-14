# Title         : options.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/options.nix
# ----------------------------------------------------------------------------
# Zsh shell options, zle variables, history, and the two highlighting plugins bound to the estate palette through their own style variables.
{config, ...}: let
  inherit (config.forge.theme) roles palette;
  fg = c: "fg=${c.hex}";
in {
  programs.zsh = {
    # --- [DIRECTORY_NAVIGATION]
    autocd = true;
    setOptions = ["AUTO_PUSHD" "PUSHD_IGNORE_DUPS" "CDABLE_VARS" "COMPLETE_IN_WORD"];

    # --- [ZLE_VARIABLES]
    # Shell-scoped rows at the top of .zshrc (never exported): zle's keymap timeout and the autosuggestion plugin's pre-source knobs. Manual
    # rebind binds the widgets once at the first prompt, after every wrapper (syntax highlighting sources at 1200) has landed.
    localVariables = {
      KEYTIMEOUT = 200;
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = 20;
      ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
    };

    # --- [SUGGESTION_HIGHLIGHTING]
    # strategy = [] suppresses the HM line; init.nix owns the strategy after atuin's init. The suggestion reads in the muted text tier.
    autosuggestion = {
      enable = true;
      strategy = [];
      highlight = fg roles.text.muted;
    };
    # zsh-syntax-highlighting over fast-syntax-highlighting: both upstreams idle, so a swap buys no currency. Styles follow the theme's syntax
    # scope table (function green, keyword pink, string yellow, variable blue, punctuation subtle, comment muted) through ZSH_HIGHLIGHT_STYLES.
    syntaxHighlighting = {
      enable = true;
      styles = {
        unknown-token = "${fg roles.state.danger},bold";
        reserved-word = fg roles.accent.tertiary;
        alias = fg roles.state.success;
        suffix-alias = fg roles.state.success;
        global-alias = fg roles.state.success;
        builtin = fg roles.state.success;
        function = fg roles.state.success;
        command = fg roles.state.success;
        precommand = "${fg roles.state.success},underline";
        hashed-command = fg roles.state.success;
        autodirectory = "${fg roles.accent.primary},underline";
        path = "${fg roles.text.primary},underline";
        globbing = fg roles.accent.structural;
        history-expansion = fg roles.accent.structural;
        command-substitution-delimiter = fg roles.text.subtle;
        process-substitution-delimiter = fg roles.text.subtle;
        back-quoted-argument-delimiter = fg roles.text.subtle;
        single-hyphen-option = fg roles.text.subtle;
        double-hyphen-option = fg roles.text.subtle;
        single-quoted-argument = fg palette.yellow;
        double-quoted-argument = fg palette.yellow;
        dollar-quoted-argument = fg palette.yellow;
        dollar-double-quoted-argument = fg roles.state.info;
        back-double-quoted-argument = fg roles.state.info;
        back-dollar-quoted-argument = fg roles.state.info;
        assign = fg roles.state.info;
        redirection = fg roles.text.subtle;
        commandseparator = fg roles.text.subtle;
        comment = fg roles.text.muted;
        arg0 = fg roles.state.success;
      };
    };

    # --- [HISTORY]
    # Zsh's own file feeds the inline suggestions; Atuin owns search. State, not config, so it lives under XDG_STATE_HOME.
    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 50000;
      save = 50000;
      expireDuplicatesFirst = true;
    };
  };
}
