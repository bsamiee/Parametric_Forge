# Title         : rsync.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/rsync.nix
# ----------------------------------------------------------------------------
# File synchronization and transfer utility with optimized defaults

{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.rsync ];

  # --- Rsync Configuration --------------------------------------------------
  xdg.configFile."rsync/filter" = {
    text = ''
      # System and editor artifacts
      - .DS_Store
      - Thumbs.db
      - desktop.ini
      - *.swp
      - *.swo
      - *~
      - .#*

      # Version control (protect from accidental sync)
      - .git/
      - .svn/
      - .hg/

      # Build artifacts and dependencies
      - node_modules/
      - __pycache__/
      - *.pyc
      - target/
      - dist/
      - build/
      - *.o
      - *.so
      - *.dylib

      # IDE and editor directories
      - .idea/
      - .vscode/
      - *.sublime-workspace

      # Temporary and cache
      - tmp/
      - temp/
      - cache/
      - .cache/

      # macOS specific
      - .Spotlight-V100/
      - .Trashes/
      - .fseventsd/
      - .TemporaryItems/
      - .VolumeIcon.icns

      # Security sensitive (never sync)
      - .env
      - .env.local
      - *.key
      - *.pem
      - id_rsa*
      - id_ed25519*
    '';
  };

  # --- Rsync Wrapper Scripts ------------------------------------------------
  home.file.".local/bin/rsync-safe" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Safe rsync wrapper with default filters
      exec ${pkgs.rsync}/bin/rsync --filter="merge ${config.xdg.configHome}/rsync/filter" "$@"
    '';
  };

  home.file.".local/bin/rsync-mv" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      # Enhanced move: handles directories properly that --remove-source-files doesn't

      if [ $# -lt 2 ]; then
        echo "Usage: rsync-mv SOURCE... DEST" >&2
        exit 1
      fi

      # Store arguments in array
      args=("$@")
      # Get last argument (destination)
      dest="''${args[-1]}"

      # Run rsync with remove-source-files (no sparse, no preallocate)
      ${pkgs.rsync}/bin/rsync -ahPX --remove-source-files "$@"

      # Clean up empty source directories (rsync only removes files)
      for ((i=0; i<$((''${#args[@]}-1)); i++)); do
        src="''${args[i]}"
        [ -d "$src" ] && find "$src" -type d -empty -delete 2>/dev/null || true
      done
    '';
  };
}
