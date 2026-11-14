_: {
  imports = [
    ./environments
    ./fonts.nix
    ./theme.nix
    ./programs
    ./scripts
    ./xdg.nix
  ];

  home.preferXdgDirectories = true;

  targets.darwin.copyApps.enableChecks = false;
}
