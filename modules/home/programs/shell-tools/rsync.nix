# Title         : rsync.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/rsync.nix
# ----------------------------------------------------------------------------
# rsync owner: shared exclusion filter plus two packaged rails. rsync-safe.sh
# is the transparent filtered transport; rsync-mv.sh is the receipted atomic
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
      # Transparent filtered rsync: argv passes through untouched so every
      # rsync option stays reachable; only the estate filter is injected.
      filter="''${FORGE_RSYNC_FILTER:-${filterPath}}"
      exec rsync --filter="merge $filter" "$@"
    '';
  };

  rsyncMv = pkgs.writeShellApplication {
    name = "rsync-mv.sh";
    runtimeInputs = [pkgs.coreutils pkgs.findutils pkgs.jq pkgs.rsync];
    text = ''
      if (($# < 2)); then
        printf 'usage: rsync-mv.sh SOURCE... DEST\n' >&2
        exit 64
      fi

      args=("$@")
      dest="''${args[-1]}"
      sources=("''${args[@]:0:''${#args[@]}-1}")

      if [ -d "$HOME/Library/Logs" ]; then
        default_receipts="$HOME/Library/Logs/forge-rsync-mv.receipts.jsonl"
      else
        default_receipts="''${XDG_STATE_HOME:-$HOME/.local/state}/parametric-forge/rsync-mv.receipts.jsonl"
      fi
      receipts="''${FORGE_RSYNC_RECEIPTS:-$default_receipts}"

      # -ahPX --remove-source-files moves file content; --itemize-changes and
      # --info=stats2 feed the receipt; --partial-dir keeps interrupted large
      # transfers resumable instead of restarting from zero.
      stats_file="$(mktemp)"
      trap 'rm -f "$stats_file"' EXIT
      rc=0
      rsync -ahPX --remove-source-files --itemize-changes --info=stats2 \
        --partial-dir=.rsync-partial "$@" | tee "$stats_file" || rc=$?

      # rsync only removes source files; empty source directories are swept
      # here to complete move semantics.
      if [ "$rc" = 0 ]; then
        for src in "''${sources[@]}"; do
          [ -d "$src" ] && find "$src" -type d -empty -delete 2>/dev/null || true
        done
      fi

      files="$(sed -n 's/^Number of regular files transferred: //p' "$stats_file" | tr -d , | head -1)"
      bytes="$(sed -n 's/^Total transferred file size: \([0-9.,]*[KMG]*\).*/\1/p' "$stats_file" | tr -d , | head -1)"
      result=ok
      [ "$rc" = 0 ] || result=fail
      mkdir -p "$(dirname "$receipts")"
      jq -cn \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg dest "$dest" \
        --arg files "''${files:-0}" \
        --arg bytes "''${bytes:-0}" \
        --arg rc "$rc" \
        --arg result "$result" \
        '{ts: $ts, surface: "rsync-mv", sources: $ARGS.positional,
          dest: $dest, files: $files, bytes: $bytes,
          rc: ($rc | tonumber), result: $result}' \
        --args "''${sources[@]}" >>"$receipts"
      exit "$rc"
    '';
  };
in {
  home.packages = [pkgs.rsync rsyncSafe rsyncMv];

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
}
