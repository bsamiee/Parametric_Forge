# Title         : rsync.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/rsync.nix
# ----------------------------------------------------------------------------
# rsync owner: shared exclusion filter plus two packaged rails. rsync-safe.sh is the transparent filtered transport; rsync-mv.sh is the atomic
# move (rsync cannot remove source directories, only files).
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

  rsyncMv = pkgs.writeShellApplication {
    name = "rsync-mv.sh";
    runtimeInputs = [pkgs.coreutils pkgs.findutils pkgs.rsync];
    text = ''
      if (($# < 2)); then
        printf 'usage: rsync-mv.sh SOURCE... DEST\n' >&2
        exit 64
      fi

      args=("$@")
      sources=("''${args[@]:0:''${#args[@]}-1}")

      # -aPX --remove-source-files moves file content; --partial-dir keeps interrupted large transfers resumable instead of restarting from zero.
      rc=0
      rsync -aPX --remove-source-files --itemize-changes --partial-dir=.rsync-partial "$@" || rc=$?

      # rsync only removes source files; the emptied source directories are swept here to complete move semantics, and one that stays (find
      # exits 0 over a directory it left populated) is a failed move like any other step.
      if [ "$rc" = 0 ]; then
        for src in "''${sources[@]}"; do
          [ ! -d "$src" ] || { find "$src" -type d -empty -delete && [ ! -d "$src" ]; } || rc=$?
        done
      fi

      exit "$rc"
    '';
  };
in {
  home.packages = [pkgs.rsync rsyncSafe rsyncMv];

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
