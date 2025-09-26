# Title         : home_xdg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/xdg/home_xdg.nix
# ----------------------------------------------------------------------------
# Non-XDG home directory structure

{ config, lib, ... }:

{
  home.activation.createHomeDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Non-XDG compliant directories that must exist

    # --- SSH ----------------------------------------------------------------
    mkdir -pm 700 "${config.home.homeDirectory}/.ssh"
    mkdir -pm 700 "${config.home.homeDirectory}/.ssh/sockets"

    # --- Local binaries -----------------------------------------------------
    mkdir -pm 755 "${config.home.homeDirectory}/.local/bin"
    mkdir -pm 755 "${config.home.homeDirectory}/bin"
  '';
}
