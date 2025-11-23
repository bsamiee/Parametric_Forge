# Title         : lsp.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/lsp.nix
# ----------------------------------------------------------------------------
# Language server tooling shared across language modules.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # --- Core ---------------------------------------------------------------
    nixd                                        # Modern Nix language server
    lua-language-server                         # LuaLS for Lua diagnostics & completion
    bash-language-server                        # Shell scripts
    taplo                                       # TOML (includes LSP)
    yaml-language-server                        # YAML validation & schema support
    marksman                                    # Markdown (wiki-style links, frontmatter)
    nodePackages.vscode-langservers-extracted   # HTML/CSS/JSON/ESLint via VS Code extractions
    dockerfile-language-server                  # Dockerfile syntax & completion

    # --- Python -------------------------------------------------------------
    basedpyright                                # Pyright-compatible LSP (fast, config-compatible)
    python3Packages.python-lsp-server           # Pylsp with plugins
    python3Packages.python-lsp-ruff             # Ruff integration for pylsp

    # --- Systems / Compiled -------------------------------------------------
    rust-analyzer                               # Rust
    cmake-language-server                       # CMake projects
    gopls                                       # Go toolchain LSP

    # --- Data / Markup ------------------------------------------------------
    lemminx                                     # XML/XSD support
    sqls                                        # SQL database-aware completion & linting
  ];
}
