_: {
  programs.tmux = {
    enable = true;
    sensibleOnTop = false;
    escapeTime = 0;
    historyLimit = 100000;
    terminal = "tmux-256color";
    extraConfig = ''
      set -s extended-keys on
      set -g status off
      set -g window-size manual
      set -g remain-on-exit on
      set-environment -gu ZELLIJ
      set-environment -gu ZELLIJ_PANE_ID
      set-environment -gu ZELLIJ_SESSION_NAME
    '';
  };
}
