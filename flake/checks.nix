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
              ];
            }
            ''
              cd $src
              echo "Running Nix quality validation..."
              echo "  Note: Run 'nix fmt' first to apply formatting and basic fixes"

              # Validation-only checks (formatting handled by treefmt)
              statix check . || exit 1
              deadnix --fail --no-underscore . || exit 1

              echo "Nix code quality checks passed" > $out
            '';

        # --- Language Quality Checks -------------------------------------------
        language-quality =
          pkgs.runCommand "language-quality-check"
            {
              src = ./..;
              nativeBuildInputs = with pkgs; [
                shellcheck # Shell script analysis
                yamllint # YAML validation
                taplo # TOML validation
                jq # JSON validation
                stylua # Lua format validation
                luajitPackages.luacheck # Lua linting
              ];
            }
            ''
              cd $src
              echo "Running language quality validation..."
              echo "  Note: Run 'nix fmt' first to apply formatting"

              # Shell Scripts - validation only (formatting handled by treefmt)
              find . -name "*.sh" -type f | while read -r script; do
                echo "  Shell: $script"
                shellcheck -S warning "$script" || exit 1
              done

              # YAML files - validation only (formatting handled by treefmt)
              find . -name "*.yml" -o -name "*.yaml" -type f | while read -r file; do
                echo "  YAML: $file"
                # Use project's yamllint config to match formatter expectations
                yamllint -c ./01.home/00.core/configs/formatting/.yamllint.yml "$file" || exit 1
              done


              # TOML files - validation (formatting handled by treefmt)
              find . -name "*.toml" -type f | while read -r file; do
                echo "  TOML: $file"
                taplo check "$file" || exit 1
              done

              # JSON files - validation (formatting handled by treefmt)
              find . -name "*.json" -type f | while read -r file; do
                echo "  JSON: $file"
                jq empty "$file" || exit 1
              done

              # Lua files - validation using project configs
              find . -name "*.lua" -type f | while read -r file; do
                echo "  Lua: $file"
                stylua --config-path ./01.home/00.core/configs/languages/.stylua.toml --check "$file" || exit 1
                luacheck --config ./01.home/00.core/configs/languages/.luacheckrc "$file" || exit 1
              done

              echo "Language quality checks passed" > $out
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
