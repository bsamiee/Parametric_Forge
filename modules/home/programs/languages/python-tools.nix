# Title         : python-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/python-tools.nix
# ----------------------------------------------------------------------------
# Python development environment - Canonical Python 3.15 installation.
{
  lib,
  pkgs,
  ...
}: let
  python = pkgs.python315;
  projectPython = name:
    lib.hiPrio (pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [pkgs.uv];
      text = ''
        _find_project_root() {
          local dir="$PWD"

          while [[ "$dir" != "/" ]]; do
            if [[ -f "$dir/pyproject.toml" || -f "$dir/uv.lock" || -f "$dir/.python-version" || -d "$dir/.venv" ]]; then
              printf '%s\n' "$dir"
              return 0
            fi

            dir="''${dir%/*}"
            [[ -n "$dir" ]] || dir="/"
          done

          return 1
        }

        _main() {
          if [[ "''${FORGE_PYTHON_SHIM_BYPASS:-}" == "1" || "''${FORGE_PYTHON_SHIM_ACTIVE:-}" == "1" ]]; then
            export UV_PYTHON_PREFERENCE="only-system"
            export UV_PYTHON_DOWNLOADS="never"
            exec "${python}/bin/${name}" "$@"
          fi

          local project_root
          if project_root="$(_find_project_root)"; then
            export UV_PYTHON_PREFERENCE="only-system"
            export UV_PYTHON_DOWNLOADS="never"
            if [[ -n "''${UV_PROJECT_ENVIRONMENT:-}" ]]; then
              if [[ "$UV_PROJECT_ENVIRONMENT" = /* ]]; then
                if [[ -x "$UV_PROJECT_ENVIRONMENT/bin/python" ]]; then
                  exec "$UV_PROJECT_ENVIRONMENT/bin/python" "$@"
                fi
              elif [[ -x "$project_root/$UV_PROJECT_ENVIRONMENT/bin/python" ]]; then
                exec "$project_root/$UV_PROJECT_ENVIRONMENT/bin/python" "$@"
              fi
            fi
            if [[ -x "$project_root/.venv/bin/python" ]]; then
              exec "$project_root/.venv/bin/python" "$@"
            fi

            export FORGE_PYTHON_SHIM_ACTIVE=1
            exec uv --project "$project_root" run python "$@"
          fi

          export UV_PYTHON_PREFERENCE="only-system"
          export UV_PYTHON_DOWNLOADS="never"
          exec "${python}/bin/${name}" "$@"
        }

        _main "$@"
      '';
    });
in {
  home.packages = with pkgs; [
    # --- Python Runtime (Canonical Source) ----------------------------------
    (projectPython "python")
    (projectPython "python3")
    python315 # Python 3.15

    # --- Python Tooling -----------------------------------------------------
    ruff # Fast Python linter/formatter
    uv # Fast Python package installer and resolver
    ty # Astral type checker / language server
    basedpyright # Static type/API surface validation
  ];
}
