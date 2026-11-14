{config, ...}: let
  inherit (config.forge.theme) roles palette;
  fg = c: "fg=${c.hex}";
in {
  programs.zsh = {
    # --- [DIRECTORY_NAVIGATION]
    autocd = true;
    setOptions = ["AUTO_PUSHD" "PUSHD_IGNORE_DUPS" "CDABLE_VARS" "COMPLETE_IN_WORD"];

    # --- [ZLE_VARIABLES]
    localVariables = {
      KEYTIMEOUT = 200;
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = 20;
      ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
    };

    # --- [SUGGESTION_HIGHLIGHTING]
    autosuggestion = {
      enable = true;
      strategy = [];
      highlight = fg roles.text.muted;
    };
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
    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 50000;
      save = 50000;
      expireDuplicatesFirst = true;
    };
  };
}
