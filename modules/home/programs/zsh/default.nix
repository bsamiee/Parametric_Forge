_: {
  imports = [
    ./init.nix
    ./completions.nix
    ./plugins.nix
    ./options.nix
    ./config.nix
    ../../aliases
  ];

  programs.zsh = {
    enable = true;
    package = null;
  };
}
