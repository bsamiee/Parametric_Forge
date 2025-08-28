# Title         : dev-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/dev-tools.nix
# ----------------------------------------------------------------------------
# Development tool aliases - unified namespace for config file formatters and linters

{ lib, ... }:

let
  # --- Dev Tool Commands (dynamically prefixed with 'd') -------------------
  devCommands = {
    # TOML tools
    tomlfmt = "f() { taplo fmt \"\${@:-.}\"; }; f";
    tomllint = "f() { taplo check \"\${@:-.}\"; }; f";

    # YAML tools
    yamlfmt = "f() { yamlfmt \"\${@:-.}\"; }; f";
    yamllint = "f() { yamllint \"\${@:-.}\"; }; f";

    # Development environment
    dl = "nix develop .#default";

    # Quality assurance workflows
    fmt = "f() { echo 'Formatting TOML...' && taplo fmt . && echo 'Formatting YAML...' && yamlfmt .; }; f";
    lint = "f() { echo 'Linting TOML...' && taplo check . && echo 'Linting YAML...' && yamllint .; }; f";

    # Documentation & help
    help = "echo 'TOML: taplo.tamasfe.dev | YAML: yamllint.readthedocs.io'";
    version = "taplo --version && yamlfmt --version && yamllint --version";
  };

in
{
  aliases = lib.mapAttrs' (name: value: {
    name = "d${name}";
    inherit value;
  }) devCommands;
}
