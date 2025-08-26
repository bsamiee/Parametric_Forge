# Title         : flake/checks.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /flake/checks.nix
# ----------------------------------------------------------------------------
# Fast quality checks and validation

_:

let
  nixSource = builtins.filterSource (
    path: type:
    let
      baseName = baseNameOf path;
      isNixFile = type == "regular" && builtins.match ".*\\.nix$" baseName != null;
      isDirectory = type == "directory";
      isRelevantDir = !(builtins.substring 0 1 baseName == "." || baseName == "result");
    in
    isNixFile || (isDirectory && isRelevantDir)
  ) ./..;
in
{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      checks = {
        # --- Nix Quality ----------------------------------------------------
        nix-quality =
          pkgs.runCommand "nix-quality-check"
            {
              src = nixSource;
              nativeBuildInputs = with pkgs; [
                statix
                deadnix
                nixpkgs-fmt
              ];
            }
            ''
              cd $src
              echo "Running Nix quality checks..."

              statix check . || exit 1
              deadnix --fail --no-underscore . || exit 1
              nixpkgs-fmt --check . 2>/dev/null || echo "  ⚠ Some formatting issues (non-blocking)"

              echo "Nix code quality checks passed" > $out
            '';

        # --- Shell Scripts --------------------------------------------------
        shell-scripts =
          pkgs.runCommand "shell-scripts-check"
            {
              src = ./..;
              nativeBuildInputs = [ pkgs.shellcheck ];
            }
            ''
              cd $src
              echo "Checking shell scripts..."

              for script in setup.sh scripts/*.sh; do
                if [ -f "$script" ]; then
                  echo "  Checking: $script"
                  shellcheck -S warning "$script" || exit 1
                fi
              done

              echo "Shell script checks passed" > $out
            '';
        # --- Package Smoke Test ---------------------------------------------
        packages-smoke =
          pkgs.runCommand "packages-smoke-test"
            {
              nativeBuildInputs = [
                self'.packages.forge-bootstrap
                self'.packages.check-system
              ];
            }
            ''
              forge-bootstrap --help > /dev/null || exit 1
              command -v check-system > /dev/null || exit 1
              echo "Package smoke test passed" > $out
            '';
        # --- Flake Structure ------------------------------------------------
        flake-structure =
          pkgs.runCommand "flake-structure-check"
            {
              src = ./..;
              nativeBuildInputs = [ pkgs.jq ];
            }
            ''
              cd $src
              echo "Checking flake structure..."

              for dir in flake lib modules 00.system 01.home; do
                if [ ! -d "$dir" ]; then
                  echo "  ✗ Missing critical directory: $dir"
                  exit 1
                fi
              done

              for file in flake.nix flake.lock CLAUDE.md; do
                if [ ! -f "$file" ]; then
                  echo "  ✗ Missing critical file: $file"
                  exit 1
                fi
              done

              echo "Flake structure check passed" > $out
            '';
      };
    };
}
