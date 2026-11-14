{
  config,
  pkgs,
  ...
}: {
  home = {
    file.".local/bin/codex".source = config.lib.file.mkOutOfStoreSymlink "/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex";

    packages = with pkgs; [
      # --- [SHELL_TOOLING]
      bash
      shellcheck
      shfmt

      # --- [GENERAL_DATA_TOOLS]
      qsv

      # --- [GOOGLE_WORKSPACE]
      gogcli-current
      gam-current
    ];
  };

  # --- [ANTIGRAVITY_REMOTE_CONTROL]
  programs.zsh.initContent = ''
    agy() {
      (($#)) || set -- --remote-control
      command agy "$@"
    }
  '';
}
