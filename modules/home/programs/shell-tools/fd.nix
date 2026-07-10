# Title         : fd.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/fd.nix
# ----------------------------------------------------------------------------
# Fast file finder plus the estate noise-pattern taxonomy: `dirs` are directory names, `files` are file globs, `text` is the rendered gitignore-grammar
# projection fd and watchexec consume verbatim. Narrower per-surface policies (ripgrep search, eza tree prune, rsync filter) stay consumer-owned.

{
  config,
  lib,
  pkgs,
  ...
}: let
  fdWithHidden = pkgs.symlinkJoin {
    name = "fd-hidden-${pkgs.fd.version}";
    paths = [pkgs.fd];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/bin/fd" --add-flags '--hidden'
    '';
  };
in {
  options.forge.ignoreEstate = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    description = "Noise-pattern taxonomy: dirs (names, no slash), files (globs), text (rendered ignore-file projection).";
    default = rec {
      text = lib.concatStringsSep "\n" (map (d: "${d}/") dirs ++ files);
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

  config = {
    home.packages = [fdWithHidden];
    xdg.configFile."fd/ignore".text = config.forge.ignoreEstate.text;
  };
}
