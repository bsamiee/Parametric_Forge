# Title         : lua-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/lua-tools.nix
# ----------------------------------------------------------------------------
# Lua development environment and tooling.

{ pkgs, ... }:

with pkgs;
[
  # --- Lua Runtime & Package Management -------------------------------------
  lua5_4 # Standard Lua 5.4 (required for SbarLua compatibility)
  luarocks # Lua package manager

  # --- Language Server & Intelligence ---------------------------------------
  lua-language-server # LSP for Lua (sumneko/LuaLS) - provides linting & diagnostics

  # --- Code Quality Tools ---------------------------------------------------
  stylua # Opinionated Lua code formatter (most modern)
  lua54Packages.luacheck # Static analyzer and linter for Lua
]
