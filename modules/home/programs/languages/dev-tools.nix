{pkgs, ...}: {
  home.packages = with pkgs; [
    # --- [SHELL_TOOLING]
    bash
    shellcheck
    shfmt

    # --- [GENERAL_DATA_TOOLS]
    qsv

    # --- [GOOGLE_WORKSPACE]
    gogcli
    gemini-api
    gam-current

    # --- [DEVICES_AND_VMS]
    bambu
    pdfm-mcp

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
