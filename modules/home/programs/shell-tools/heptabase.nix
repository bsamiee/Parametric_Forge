# Title         : heptabase.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/heptabase.nix
# ----------------------------------------------------------------------------
# Durable Heptabase CLI wrapper backed by the Homebrew-managed app bundle; Darwin-only — the desktop runtime it execs exists nowhere else.
{
  lib,
  pkgs,
  ...
}: let
  heptabaseCli = pkgs.writeShellApplication {
    name = "heptabase";
    text = ''
      runtime="/Applications/Heptabase.app/Contents/MacOS/Heptabase"
      cli_script="/Applications/Heptabase.app/Contents/Resources/cli/cli.cjs"

      if [ ! -x "$runtime" ]; then
        printf 'heptabase: missing desktop runtime: %s\n' "$runtime" >&2
        printf 'heptabase: install or redeploy the existing Homebrew cask: heptabase\n' >&2
        exit 127
      fi

      if [ ! -f "$cli_script" ]; then
        printf 'heptabase: missing bundled CLI script: %s\n' "$cli_script" >&2
        printf 'heptabase: reinstall or redeploy the existing Homebrew cask: heptabase\n' >&2
        exit 127
      fi

      export ELECTRON_RUN_AS_NODE=1
      export heptabaseCliRuntimePath="$runtime"
      export heptabaseCliScriptPath="$cli_script"
      exec "$runtime" "$cli_script" "$@"
    '';
  };
in {
  home.packages = lib.optional pkgs.stdenv.hostPlatform.isDarwin heptabaseCli;
}
