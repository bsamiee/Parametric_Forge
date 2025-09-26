# Title         : fd.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/fd.nix
# ----------------------------------------------------------------------------
# Fast file finder configuration

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
  # fd doesn't have a programs.fd module - install via packages
  home.packages = [ pkgs.fd ];

  # Global ignore patterns
  xdg.configFile."fd/ignore".text = lib.concatStringsSep "\n" globalIgnorePatterns;
}
