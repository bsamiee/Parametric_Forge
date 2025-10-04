# Title         : ripgrep.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/ripgrep.nix
# ----------------------------------------------------------------------------
# Fast recursive search configuration

{ config, lib, pkgs, ... }:

# Dracula theme color reference
# background    #15131F
# current_line  #2A2640
# selection     #44475A
# foreground    #F8F8F2
# comment       #6272A4
# purple        #A072C6
# cyan          #94F2E8
# green         #50FA7B
# yellow        #F1FA8C
# orange        #F97359
# red           #FF5555
# magenta       #d82f94
# pink          #E98FBE

let
  ripgrepConfig = [
    # --- Search Behavior ----------------------------------------------------
    "--smart-case"
    "--hidden"
    "--follow"
    "--max-columns=150"
    "--max-columns-preview"
    "--sort=path"                     # Deterministic output (useful for scripts/tests)
    "--line-number"                   # Show line numbers (essential for code navigation)
    "--trim"                          # Remove trailing whitespace from output
    "--no-messages"                   # Suppress file access error messages
    "--search-zip"                    # Search compressed files (gzip, bzip2, xz, lz4, zstd, brotli)
    "--ignore-file-case-insensitive"  # macOS case-insensitive filesystem support
    "--engine=auto"                   # Use PCRE2 only when needed (lookaround/backreferences)
    "--hyperlink-format=vscode"       # Clickable paths in WezTerm → VSCode
    "--one-file-system"               # Don't cross mount points (Nix store safety)

    # --- Performance --------------------------------------------------------
    "--threads=0"
    "--dfa-size-limit=1G"            # Increase DFA cache for large pattern files
    "--mmap"                         # Use memory-mapped I/O for large files

    # --- Visual formatting --------------------------------------------------
    # Path: Cyan
    "--colors=path:fg:117"         # ANSI 117 = Dracula cyan (#94F2E8)
    "--colors=path:style:bold"

    # Line/Column numbers: Comment gray
    "--colors=line:fg:8"           # ANSI 8 = Dracula comment (#6272A4)
    "--colors=column:fg:8"         # Keep consistent with line

    # Match: Green
    "--colors=match:fg:84"         # ANSI 84 = Dracula green (#50FA7B)
    "--colors=match:style:bold"

    # --- Type Definitions ---------------------------------------------------
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

    # Lock files (useful for dependency audits)
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

    # --- Global Exclusions --------------------------------------------------
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
  home.packages = [ pkgs.ripgrep ];
  xdg.configFile."ripgrep/config".text = lib.concatStringsSep "\n" ripgrepConfig;
}
