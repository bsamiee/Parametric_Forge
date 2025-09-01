# Title         : lua.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/lua.nix
# ----------------------------------------------------------------------------
# Lua development aliases - unified namespace for all lua-related tools

{ lib, ... }:

let
  # --- Lua Commands (dynamically prefixed with 'l') ------------------------
  luaCommands = {
    # Core execution
    u = "lua";
    j = "lua5.4"; # Future-proof: use latest stable Lua
    r = "luarocks";

    # Development environment
    dl = "nix develop .#lua";
    repl = "lua -i"; # Simple Lua REPL
    eval = "lua -e"; # Execute Lua expression

    # Code quality & formatting
    fmt = "f() { stylua \"\${@:-.}\"; }; f";
    fmtc = "f() { stylua --check \"\${@:-.}\"; }; f";
    lint = "f() { lua-language-server --check \"\${@:-.}\" 2>/dev/null || echo 'LSP linting requires editor integration'; }; f";

    # Package management
    install = "luarocks install --local";
    remove = "luarocks remove";
    list = "luarocks list";
    search = "luarocks search";
    show = "luarocks show";
    make = "luarocks make";
    path = "luarocks path";

    # Testing & coverage
    test = "busted";
    testf = "busted --filter";
    testt = "busted --tags";
    cov = "busted --coverage && luacov";

    # Project scaffolding
    init = "f() { luarocks init \"\${1:-.}\" && echo 'use flake' > .envrc && direnv allow; }; f";
    rock = "luarocks write_rockspec";

    # Smart interpreter selection
    run = "lua"; # Run Lua script

    # Documentation & help
    help = "echo 'Lua: lua.org/manual | LuaRocks: luarocks.org'";
    version = "lua -v 2>&1 && luarocks --version | head -1";
  };

in
{
  aliases = lib.mapAttrs' (name: value: {
    name = "l${name}";
    inherit value;
  }) luaCommands;
}
