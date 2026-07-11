# Title         : ripgrep.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/ripgrep.nix
# ----------------------------------------------------------------------------
# Fast recursive search configuration
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette;
  ripgrepConfig = [
    # --- [SEARCH_BEHAVIOR]
    # Output-mutating flags (trim, column truncation) live in the interactive rg alias — the config applies to every invocation and piped
    # output must stay verbatim; line numbers need no row because rg enables them on TTY output itself.
    "--smart-case"
    "--hidden"
    "--follow"
    "--no-messages" # Suppress file access error messages
    "--search-zip" # Search inside compressed archives
    "--ignore-file-case-insensitive" # macOS case-insensitive filesystem support
    "--engine=auto" # Use PCRE2 only when needed (lookaround/backreferences)
    "--hyperlink-format=vscode" # Clickable paths in WezTerm → VSCode
    "--one-file-system" # Don't cross mount points (Nix store safety)

    # --- [PERFORMANCE]
    "--dfa-size-limit=1G" # Increase DFA cache for large pattern files

    # --- [VISUAL_FORMATTING]
    # Truecolor RGB triples from the palette tokens
    "--colors=path:fg:${palette.cyan.csv}"
    "--colors=path:style:bold"
    "--colors=line:fg:${palette.comment.csv}"
    "--colors=column:fg:${palette.comment.csv}"
    "--colors=match:fg:${palette.green.csv}"
    "--colors=match:style:bold"

    # --- [TYPE_DEFINITIONS]
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

    # Data formats
    "--type-add=data:*.{json,jsonc,json5,yaml,yml,toml}"

    # Lock files
    "--type-add=lock:*lock.json"
    "--type-add=lock:*lock.yaml"
    "--type-add=lock:Cargo.lock"
    "--type-add=lock:flake.lock"

    # Log files
    "--type-add=log:*.{log,logs}"

    # Build systems
    "--type-add=build:Makefile*"
    "--type-add=build:*.{mk,cmake,bazel,BUILD}"
    "--type-add=proto:*.proto"
    "--type-add=headers:*.{h,hpp,hxx,hh}"

    # --- [GLOBAL_EXCLUSIONS]
    # Only .git/ — with --hidden it would otherwise flood every search; all other repo noise is gitignore-owned so explicit targets stay honest.
    "--glob=!.git/"
  ];
in {
  home.packages = [pkgs.ripgrep];
  xdg.configFile."ripgrep/config".text = lib.concatStringsSep "\n" ripgrepConfig;
}
