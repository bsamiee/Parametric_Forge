# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/sqlite-forge/default.nix
# ----------------------------------------------------------------------------
# SQLite shell with Forge-owned native extension profiles.
{
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
    runtimeInputs = [sqlite-interactive];
    text = ''
      profile="''${SQLITE_FORGE_PROFILE:-safe}"
      modules=(regexp uuid stats text time crypto math)
      case "$profile" in
        safe) ;;
        extended) modules+=(define vsv fuzzy ipaddr) ;;
        fileio) modules+=(fileio) ;;
        all) modules+=(define vsv fuzzy ipaddr fileio) ;;
        *)
          printf 'sqlite-forge: unknown SQLITE_FORGE_PROFILE=%s; expected safe, extended, fileio, or all\n' "$profile" >&2
          exit 2
          ;;
      esac

      # exec skips EXIT traps, so the init script rides a process-substitution
      # fd instead of a temp file a trap would have to reap.
      exec sqlite3 -init <(
        printf '.load ${sqleanLibDir}/%s${sharedLibExt}\n' "''${modules[@]}"
        printf '.load %s\n' '${sqliteVecLib}' '${spatialiteLib}'
      ) "$@"
    '';
  }
