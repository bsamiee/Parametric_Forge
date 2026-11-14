{config, ...}: let
  inherit (config.forge.theme) projections;
  fd = "fd";
  fdFiles = "${fd} --type f --hidden --follow --exclude .git";
in {
  programs.fzf = {
    enable = true;

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
        "--preview='bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || eza --tree --level=2 --all --git-ignore --group-directories-first --color=always --icons=always {}'"
      ];
    };

    # --- [ALT_C_DIRECTORY_NAVIGATION]
    changeDirWidget = {
      command = "${fd} --type d --hidden --follow --exclude .git";
      options = [
        "--border-label='[DIRECTORIES]'"
        "--preview='eza --tree --level=2 --all --git-ignore --group-directories-first --color=always --icons=always {}'"
      ];
    };

    # --- [CTRL_R_OWNER]
    historyWidget.command = "";
  };
}
