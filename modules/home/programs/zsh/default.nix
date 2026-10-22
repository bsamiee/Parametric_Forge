# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/default.nix
# ----------------------------------------------------------------------------
# Zsh configuration orchestrator: Nix supplies the configuration (these dotfiles, nix-darwin's /etc/zsh*), never the binary.
{lib, ...}: {
  imports = [
    ./init.nix
    ./completions.nix
    ./plugins.nix
    ./options.nix
    ./config.nix
    ../../aliases
  ];

  # One zsh for every launcher: Apple's /bin/zsh is the account's login shell, sealed under SIP, updated with the OS, and runnable before the
  # /nix volume mounts; every spawn that names a shell reads this path.
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
