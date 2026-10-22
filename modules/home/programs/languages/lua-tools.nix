# Title         : lua-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/lua-tools.nix
# ----------------------------------------------------------------------------
# Lua development environment and tooling.
{pkgs, ...}: {
  home.packages = [
    # --- [LUA_RUNTIME]
    pkgs.lua5_4 # Lua 5.4 runtime

    # --- [CODE_QUALITY_TOOLS]
    pkgs.stylua # Opinionated Lua formatter
    pkgs.lua-language-server # Lua LSP (navigation, diagnostics, completion)
  ];
}
