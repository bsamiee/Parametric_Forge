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

      # --- [CLOUD_IAC]
      google-cloud-sdk
      gogcli
      gam
    ];
  };
}
