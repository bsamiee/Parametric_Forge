# Title         : 00.system/darwin/darwin.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/darwin.nix
# ----------------------------------------------------------------------------
# Core Darwin system-level configuration.

{
  context,
  lib,
  ...
}:

{
  # --- Primary User ---------------------------------------------------------
  system.primaryUser = context.user;

  # --- System Configuration -------------------------------------------------
  system = {
    stateVersion = 6;
    startup.chime = null; # null=unset, true=enable, false=disable
  };

  # --- Programs -------------------------------------------------------------
  programs.zsh.enable = true;

  # --- Environment ----------------------------------------------------------
  # Intel Macs need /usr/local/bin prioritized for Homebrew
  environment.systemPath = lib.mkIf context.isX86_64 (lib.mkBefore [ "/usr/local/bin" ]);
}
