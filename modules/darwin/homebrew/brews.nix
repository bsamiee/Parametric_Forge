# Title         : brews.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/brews.nix
# ----------------------------------------------------------------------------
# Homebrew CLI tools and formulae
_: {
  homebrew.brews = [
    # --- System Utilities ---------------------------------------------------
    "defaultbrowser" # CLI tool for setting default browser
    "tag" # macOS file tagging CLI
    "blueutil" # Bluetooth management
    "dotnet@8" # .NET 8 runtime for Rhino 8 rhinocode

    # --- Window Management Tools --------------------------------------------
    "koekeishiya/formulae/yabai"
    "koekeishiya/formulae/skhd"
    "FelixKratz/formulae/borders"

    # --- Language Servers (LSP) ---------------------------------------------
    "lua-language-server" # Lua
    "bash-language-server" # Bash
    "taplo" # TOML
    "yaml-language-server" # YAML
    "marksman" # Markdown
    "vscode-langservers-extracted" # HTML/CSS/JSON/ESLint
    "dockerfile-language-server" # Dockerfile
    "basedpyright" # Python
    "typescript-language-server" # TypeScript/JavaScript
    "rust-analyzer" # Rust
    "cmake-language-server" # CMake
    "gopls" # Go
    "sql-language-server" # SQL (Homebrew; replaces sqls)

    # --- Media Tools --------------------------------------------------------
    # "handbrake" # CLI video transcoder

    # --- Server Tools -------------------------------------------------------
    "webhook" # HTTP endpoint for triggering scripts (adnanh/webhook)
  ];
}
