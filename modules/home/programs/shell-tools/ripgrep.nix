# Title         : ripgrep.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/ripgrep.nix
# ----------------------------------------------------------------------------
# Fast recursive search configuration

{ config, lib, pkgs, ... }:

let
  # Ripgrep configuration - each line is a single argument
  ripgrepConfig = [
    # Search behavior
    "--smart-case"
    "--hidden"
    "--follow"
    "--max-columns=150"
    "--max-columns-preview"
    "--sort=path"                  # Deterministic output (useful for scripts/tests)
    "--trim"                       # Remove trailing whitespace from output

    # Performance
    "--threads=0"

    # Visual formatting (ANSI colors matching Stylix theme)
    "--colors=path:style:bold"
    "--colors=path:fg:blue"
    "--colors=line:fg:green"
    "--colors=match:style:bold"
    "--colors=match:fg:white"
    "--colors=match:bg:magenta"

    # Type definitions
    # Nix ecosystem
    "--type-add=nix:*.nix"
    "--type-add=nix:flake.lock"

    # Documentation files
    "--type-add=docs:*.{md,markdown,rst,txt,adoc,org}"
    "--type-add=docs:README*"
    "--type-add=docs:LICENSE*"
    "--type-add=docs:CHANGELOG*"
    "--type-add=docs:CONTRIBUTING*"

    # Shell scripts (extends built-in sh type)
    "--type-add=shell:*.{sh,bash,zsh,fish}"
    "--type-add=shell:*.{bashrc,zshrc}"

    # Config files (extends built-in config type)
    "--type-add=config:*.{toml,yaml,yml}"
    "--type-add=config:*.{env,env.*}"
    "--type-add=config:.*rc"
    "--type-add=config:Dockerfile*"
    "--type-add=config:docker-compose*.{yml,yaml}"

    # Global exclusions (respects .gitignore by default)
    "--glob=!.git/"
    "--glob=!node_modules/"
    "--glob=!target/"
    "--glob=!dist/"
    "--glob=!build/"
    "--glob=!*.swp"
    "--glob=!*.swo"
    "--glob=!.DS_Store"
  ];
in
{
  # ripgrep doesn't have a programs.ripgrep module - install via packages
  home.packages = [ pkgs.ripgrep ];

  # Create ripgrep config file
  xdg.configFile."ripgrep/config".text = lib.concatStringsSep "\n" ripgrepConfig;
}