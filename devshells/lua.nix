# Title         : devshells/lua.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /devshells/lua.nix
# ----------------------------------------------------------------------------
# Lua development shell with advanced tooling.

{ pkgs, myLib, ... }:

pkgs.mkShell {
  name = "lua-dev";
  # --- Package Selection ----------------------------------------------------
  packages = with pkgs; [
    lua5_4
    lua54Packages.penlight
    lua54Packages.busted
    lua54Packages.luacov
  ];
  # --- Environment Variables ------------------------------------------------
  env = {
    LUA_PATH = "${pkgs.lua54Packages.penlight}/share/lua/5.4/?.lua;${pkgs.lua54Packages.penlight}/share/lua/5.4/?/init.lua;./?.lua;./?/init.lua";
    LUA_CPATH = "${pkgs.lua54Packages.penlight}/lib/lua/5.4/?.so;./?.so";
    BUSTED_OUTPUT_TYPE = "TAP";
    LUACOV_CONFIG = ".luacov";
    LUACOV_STATSFILE = ".luacov.stats.out";
  };
  # --- Shell Hook -----------------------------------------------------------
  shellHook = ''
    echo "═══════════════════════════════════════════════════════"
    echo "  Lua Development Environment"
    echo "═══════════════════════════════════════════════════════"
    echo ""

    ${myLib.devshell.loadSecretsIfFresh}

    echo "Core Tools:"
    echo "  lua               - Lua 5.4 interpreter"
    echo "  luarocks          - Package manager"
    echo ""
    echo "Development Tools:"
    echo "  lua-language-server - LSP for IDE integration"
    echo "  stylua            - Code formatter"
    echo "  luacheck          - Static analyzer and linter"
    echo ""
    echo "Testing Tools:"
    echo "  busted            - Unit testing framework"
    echo "  luacov            - Code coverage"
    echo ""
    echo "Quick commands:"
    echo "  stylua .          - Format all Lua files"
    echo "  stylua --check .  - Check formatting"
    echo "  luacheck .        - Lint code quality"
    echo "  busted            - Run tests"
    echo ""

    # Project detection
    if [ -f ".stylua.toml" ] || [ -f "stylua.toml" ]; then
      echo "Lua project detected (stylua config found)"
    elif [ -f "init.lua" ]; then
      echo "Neovim configuration detected"
      echo "  Test config with: nvim --headless +checkhealth +qa"
    elif [ -f "rockspec" ] || [ -f "*.rockspec" ]; then
      echo "LuaRocks project detected"
    fi
    echo ""
  '';
}
