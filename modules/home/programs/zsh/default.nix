{lib, ...}: {
  imports = [
    ./init.nix
    ./completions.nix
    ./plugins.nix
    ./options.nix
    ./config.nix
    ../../aliases
  ];

  options.forge.shell = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = "/bin/zsh";
    description = "The one interactive zsh every terminal, multiplexer, and rail spawn runs.";
  };

  config.programs.zsh = {
    enable = true;
    package = null;
  };
}
