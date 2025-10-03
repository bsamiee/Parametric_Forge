# Title         : lua-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/lua-tools.nix
# ----------------------------------------------------------------------------
# Lua development environment and tooling.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # --- Lua Runtime & Package Management -----------------------------------
    lua5_4                  # Standard Lua 5.4 (required for SbarLua compatibility)
    luarocks                # Lua package manager

    # --- Code Quality Tools -------------------------------------------------
    stylua                  # Opinionated Lua code formatter (most modern)
    lua54Packages.luacheck  # Static analyzer and linter for Lua
  ];
}
