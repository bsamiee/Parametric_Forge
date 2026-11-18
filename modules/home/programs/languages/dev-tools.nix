{pkgs, ...}: {
  home.packages = with pkgs; [
    # --- [SHELL_TOOLING]
    bash
    shellcheck
    shfmt

    # --- [GENERAL_DATA_TOOLS]
    qsv

    # --- [GOOGLE_WORKSPACE]
    gogcli-current
    gemini-api
    gam-current

    # --- [CONTAINER_REGISTRY]
    crane
  ];

  # --- [ANTIGRAVITY_REMOTE_CONTROL]
  programs.zsh.initContent = ''
    agy() {
      (($#)) || set -- --remote-control
      command agy "$@"
    }
  '';
}
