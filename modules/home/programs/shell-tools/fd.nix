# Title         : fd.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/fd.nix
# ----------------------------------------------------------------------------
# The estate noise-pattern taxonomy: `dirs` are directory names, `files` are file globs, `text` is the rendered gitignore-grammar projection
# watchexec consumes verbatim; fd consumes `dirText` only — traversal prunes noise directories while file discovery stays exhaustive. The fd
# binary is a project's mise.toml row; this file owns the ignore file every fd reads and the taxonomy other consumers project.
# Narrower per-surface policies (ripgrep search, eza tree prune, rsync filter) stay consumer-owned.
{
  config,
  lib,
  ...
}: {
  options.forge.ignoreEstate = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    description = "Noise-pattern taxonomy: dirs (names, no slash), files (globs), text (full projection), dirText (directory-only projection).";
    default = rec {
      text = lib.concatStringsSep "\n" (map (d: "${d}/") dirs ++ files);
      dirText = lib.concatStringsSep "\n" (map (d: "${d}/") dirs);
      dirs = [
        # Version control
        ".git"
        ".svn"
        ".hg"
        # Build artifacts
        "target"
        "dist"
        "build"
        "out"
        "_build"
        "__pycache__"
        # Dependencies
        "node_modules"
        "vendor"
        ".bundle"
        # IDE and editor
        ".idea"
        ".vscode"
        # macOS system
        ".Spotlight-V100"
        ".Trashes"
        ".fseventsd"
        ".AppleDouble"
        # Linux system
        ".Trash-*"
        "lost+found"
        # Cache
        ".cache"
        ".direnv"
        ".pytest_cache"
        ".ruff_cache"
      ];
      files = [
        # Build artifacts
        "*.o"
        "*.pyc"
        # Editor litter
        "*.swp"
        "*.swo"
        "*~"
        # macOS system
        ".DS_Store"
        ".VolumeIcon.icns"
        ".LSOverride"
        "Thumbs.db"
        # Cache and temporary
        "*.tmp"
        "*.log"
        ".coverage"
        ".envrc.cache"
        # Nix
        "result"
        "result-*"
        # Disk images and VMs
        "*.iso"
        "*.dmg"
        "*.img"
        "*.vmdk"
        "*.vdi"
        "*.vhd"
        "*.qcow2"
      ];
    };
  };

  config.xdg.configFile."fd/ignore".text = config.forge.ignoreEstate.dirText;
}
