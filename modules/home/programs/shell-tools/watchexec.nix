# Title         : watchexec.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/watchexec.nix
# ----------------------------------------------------------------------------
# File watcher and command executor with intelligent filtering

{ config, lib, pkgs, ... }:

let
  globalIgnorePatterns = [
    # Version Control
    ".git/"
    ".svn/"
    ".hg/"

    # Build Artifacts
    "target/"
    "dist/"
    "build/"
    "out/"
    "_build/"
    "*.o"
    "*.pyc"
    "__pycache__/"

    # Dependencies
    "node_modules/"
    "vendor/"
    ".bundle/"

    # IDE & Editor
    ".idea/"
    ".vscode/"
    "*.swp"
    "*.swo"
    "*~"

    # macOS System
    ".DS_Store"
    ".Spotlight-V100/"
    ".Trashes/"
    ".fseventsd/"
    ".VolumeIcon.icns"
    ".AppleDouble/"
    ".LSOverride"
    "Thumbs.db"

    # Linux System
    ".Trash-*/"
    "lost+found/"

    # Cache & Temporary
    "*.tmp"
    "*.log"
    ".cache/"
    ".direnv/"
    ".coverage"
    ".envrc.cache"
    ".pytest_cache/"
    ".mypy_cache/"
    ".ruff_cache/"

    # Nix
    "result"
    "result-*"

    # Large Files (disk images, VMs)
    "*.iso"
    "*.dmg"
    "*.img"
    "*.vmdk"
    "*.vdi"
    "*.vhd"
    "*.qcow2"
  ];
in
{
  home.packages = [ pkgs.watchexec ];
  xdg.configFile."watchexec/ignore".text = lib.concatStringsSep "\n" globalIgnorePatterns;
}
