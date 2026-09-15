# Title         : rsync.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/rsync.nix
# ----------------------------------------------------------------------------
# rsync owner: shared exclusion filter plus the packaged filtered transport rsync-safe.sh. A move that removes emptied source directories is
# `rclone move --delete-empty-src-dirs` (aliases/core.nix `rcmv`).
{
  config,
  pkgs,
  ...
}: let
  filterPath = "${config.xdg.configHome}/rsync/filter";

  rsyncSafe = pkgs.writeShellApplication {
    name = "rsync-safe.sh";
    runtimeInputs = [pkgs.rsync];
    text = ''
      # Transparent filtered rsync: argv passes through untouched so every rsync option stays reachable; only the estate filter is injected.
      filter="''${FORGE_RSYNC_FILTER:-${filterPath}}"
      exec rsync --filter="merge $filter" "$@"
    '';
  };
in {
  home.packages = [pkgs.rsync rsyncSafe];

  # --- [RSYNC_CONFIGURATION]
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
}
