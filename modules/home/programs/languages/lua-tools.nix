# Title         : lua-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/lua-tools.nix
# ----------------------------------------------------------------------------
# Lua development environment and tooling.
{
  lib,
  pkgs,
  ...
}: let
  style = import ../../../style.nix;
  # stylua reads $XDG_CONFIG_HOME/stylua/stylua.toml only under
  # --search-parent-directories; the wrapper pins the flag so project configs
  # keep winning while the house style becomes the machine floor.
  stylua = pkgs.writeShellApplication {
    name = "stylua";
    text = ''
      for arg in "$@"; do
        case "$arg" in
          -s | --search-parent-directories | --config-path | --config-path=*)
            exec ${pkgs.stylua}/bin/stylua "$@"
            ;;
        esac
      done
      exec ${pkgs.stylua}/bin/stylua --search-parent-directories "$@"
    '';
  };
in {
  home.packages = [
    # --- [LUA_RUNTIME_PACKAGE_MANAGEMENT]
    pkgs.lua5_4 # Standard Lua 5.4 (required for SbarLua compatibility)
    pkgs.luarocks # Lua package manager

    # --- [CODE_QUALITY_TOOLS]
    stylua # Opinionated Lua formatter (house-config floor via -s)
    pkgs.lua54Packages.luacheck # Static analyzer and linter for Lua
    pkgs.lua-language-server # Lua LSP (navigation, diagnostics, completion)
  ];

  xdg.configFile."stylua/stylua.toml".text = ''
    indent_type = "Spaces"
    indent_width = ${toString style.indent}
    column_width = ${toString style.width}
  '';

  # luacheck's documented fallback lane is --default-config, resolved on macOS
  # from Application Support, never XDG; a project .luacheckrc suppresses it.
  home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    "Library/Application Support/Luacheck/.luacheckrc".text = ''
      max_line_length = ${toString style.width}
    '';
  };
}
