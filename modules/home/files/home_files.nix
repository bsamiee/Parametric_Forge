# Title         : home_files.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/files/home_files.nix
# ----------------------------------------------------------------------------
# Non-XDG home directory dotfiles

{ lib, pkgs, ... }:

{
  home.file = {
    # --- Root Dotfiles ------------------------------------------------------
    # Tools that require configs at $HOME root
    # .digrc, .sqliterc, .tldrrc, etc.

    # --- Language Tool Configs ----------------------------------------------
    # .rustfmt.toml, .cargo-deny.toml, etc.

    # --- Formatter Configs --------------------------------------------------
    # .prettierrc, .stylua.toml, .editorconfig, etc.

    # --- Container Configs --------------------------------------------------
    # .dockerignore, etc.
  };
}
