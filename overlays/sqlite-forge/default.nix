# Title         : sqlite-forge/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/sqlite-forge/default.nix
# ----------------------------------------------------------------------------
# SQLite shell with Forge-owned native extension profiles.
{
  coreutils,
  libspatialite,
  sqlite-interactive,
  sqlite-vec,
  sqlean,
  stdenv,
  writeShellApplication,
}: let
  sharedLibExt = stdenv.hostPlatform.extensions.sharedLibrary;
  sqleanLibDir = "${sqlean}/lib";
  sqliteVecLib = "${sqlite-vec}/lib/vec0${sharedLibExt}";
  spatialiteLib = "${libspatialite}/lib/mod_spatialite${sharedLibExt}";
in
  writeShellApplication {
    name = "sqlite-forge";
    runtimeInputs = [
      coreutils
      sqlite-interactive
    ];
    text = ''
      rc="$(mktemp "''${TMPDIR:-/tmp}/sqlite-forge.XXXXXX")"
      cleanup() { rm -f -- "$rc"; }
      trap cleanup EXIT INT TERM

      profile="''${SQLITE_FORGE_PROFILE:-safe}"
      case "$profile" in
        safe) modules=(regexp uuid stats text time crypto math) ;;
        extended) modules=(regexp uuid stats text time crypto math define vsv fuzzy ipaddr) ;;
        fileio) modules=(regexp uuid stats text time crypto math fileio) ;;
        all) modules=(regexp uuid stats text time crypto math define vsv fuzzy ipaddr fileio) ;;
        *)
          printf 'sqlite-forge: unknown SQLITE_FORGE_PROFILE=%s; expected safe, extended, fileio, or all\n' "$profile" >&2
          exit 2
          ;;
      esac

      {
        printf '%s\n' '-- SQLite Forge extension profile'
        for module in "''${modules[@]}"; do
          printf '.load ${sqleanLibDir}/%s${sharedLibExt}\n' "$module"
        done
        printf '.load ${sqliteVecLib}\n'
        printf '.load ${spatialiteLib}\n'
      } >"$rc"

      exec sqlite3 -init "$rc" "$@"
    '';
  }
