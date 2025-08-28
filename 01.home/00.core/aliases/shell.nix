# Title         : shell.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/shell.nix
# ----------------------------------------------------------------------------
# Shell scripting development aliases - unified namespace for shell tools

{ lib, ... }:

let
  # --- Shell Commands (dynamically prefixed with 's') ----------------------
  shellCommands = {
    # Core formatting & linting
    fmt = "f() { shfmt -ci -i 4 -w \"\${@:-.}\"; }; f";
    lint = "f() { shellcheck \"\${@:-.}\"; }; f";
    lintf = "f() { echo 'Note: shellcheck cannot auto-fix, showing diff format:' && shellcheck -f diff \"\${@:-*.sh}\"; }; f";

    # Shell execution with error handling
    run = "f() { set -euo pipefail; \"\$@\"; }; f";
    trace = "f() { set -x; \"\$@\"; set +x; }; f";
    check = "f() { bash -n \"\${@:-*.sh}\"; }; f";

    # Development utilities
    find = "f() { shfmt -f \"\${1:-.}\"; }; f";
    simplify = "f() { shfmt -s -ci -i 4 -w \"\${@:-.}\"; }; f";

    # Documentation & help
    help = "echo 'Shell tools: shellcheck.net | github.com/mvdan/sh'";
    version = "shellcheck --version | head -2 && shfmt --version";
  };

in
{
  aliases = lib.mapAttrs' (name: value: {
    name = "s${name}";
    inherit value;
  }) shellCommands;
}