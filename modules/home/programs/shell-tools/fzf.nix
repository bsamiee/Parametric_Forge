{
  config,
  lib,
  theme,
  ...
}: let
  inherit (theme) projections;
  fd = "fd --hidden --follow";
  fdFiles = "${fd} --type f";
  fdDirs = "${fd} --type d";
  share = "${config.programs.fzf.package}/share/fzf";
in {
  # --- [ZSH_WIDGETS]
  programs.zsh.initContent = lib.mkOrder 910 ''
    if [[ -o zle && -t 0 ]]; then
      source ${share}/key-bindings.zsh
      source ${share}/completion.zsh
    fi

    _fzf_compgen_path() {
      ${fd} . "$1"
    }

    _fzf_compgen_dir() {
      ${fdDirs} . "$1"
    }
  '';

  programs.fzf = {
    enable = true;
    enableZshIntegration = false;

    # --- [DEFAULT_CONFIGURATION]
    defaultCommand = fdFiles;

    defaultOptions =
      projections.fzfColorRows
      ++ [
        "--border=sharp"
        "--prompt='❯ '"
        "--marker='✓'"
        "--pointer='❯'"
        "--scrollbar=│"
        "--info=right"
        "--highlight-line"
        "--height=80%"
        "--layout=reverse"
        "--preview-window=border-bold"
        "--bind=ctrl-k:preview-page-up"
        "--bind=ctrl-j:preview-page-down"
      ];

    # --- [CTRL_T_FILE_SELECTION]
    fileWidget = {
      command = fdFiles;
      options = [
        "--border-label='[FILES]'"
        "--preview='bat --color=always --style=numbers --line-range=:500 {}'"
      ];
    };

    # --- [ALT_C_DIRECTORY_NAVIGATION]
    changeDirWidget = {
      command = fdDirs;
      options = [
        "--border-label='[DIRECTORIES]'"
        "--preview='eza --tree --level=2 --all --git-ignore --group-directories-first --color=always --icons=always {}'"
      ];
    };

    # --- [CTRL_R_OWNER]
    historyWidget.command = "";
  };
}
