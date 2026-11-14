_: {
  imports = [
    ./environments
    ./fonts.nix
    ./theme.nix
    ./programs
    ./xdg.nix
  ];

  home.preferXdgDirectories = true;

  targets.darwin.copyApps.enableChecks = false;
}
