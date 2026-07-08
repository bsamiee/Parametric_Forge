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
  projectRootFunction = ''
    _find_project_root() {
      local dir="$PWD"

      while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/pyproject.toml" || -f "$dir/uv.lock" || -x "$dir/.venv/bin/python" ]]; then
          printf '%s\n' "$dir"
          return 0
        fi

        dir="''${dir%/*}"
        [[ -n "$dir" ]] || dir="/"
      done

      return 1
    }
  '';
  projectPython = name:
    lib.hiPrio (pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [pkgs.uv];
      text = ''
        ${projectRootFunction}

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
  projectTool = name: package:
    lib.hiPrio (pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [pkgs.uv];
      text = ''
        ${projectRootFunction}

        _resolve_project_tool() {
          local project_root="$1"

          if [[ -n "''${UV_PROJECT_ENVIRONMENT:-}" ]]; then
            if [[ "$UV_PROJECT_ENVIRONMENT" = /* && -x "$UV_PROJECT_ENVIRONMENT/bin/${name}" ]]; then
              printf '%s\n' "$UV_PROJECT_ENVIRONMENT/bin/${name}"
              return 0
            fi
            if [[ -x "$project_root/$UV_PROJECT_ENVIRONMENT/bin/${name}" ]]; then
              printf '%s\n' "$project_root/$UV_PROJECT_ENVIRONMENT/bin/${name}"
              return 0
            fi
          fi

          if [[ -x "$project_root/.venv/bin/${name}" ]]; then
            printf '%s\n' "$project_root/.venv/bin/${name}"
            return 0
          fi

          return 1
        }

        ${lib.optionalString (name == "mypy") ''
          _fallback_env() {
            if [[ -z "''${MYPY_CACHE_DIR:-}" ]]; then
              export MYPY_CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/mypy"
            fi
          }
        ''}

        _main() {
          local active_var="FORGE_PYTHON_TOOL_SHIM_ACTIVE_${name}"

          if [[ "''${FORGE_PYTHON_TOOL_SHIM_BYPASS:-}" == "1" || "''${!active_var:-}" == "1" ]]; then
            exec "${package}/bin/${name}" "$@"
          fi

          local project_root
          local tool_path
          if project_root="$(_find_project_root)"; then
            export UV_PYTHON_PREFERENCE="only-system"
            export UV_PYTHON_DOWNLOADS="never"
            export "$active_var=1"
            if tool_path="$(_resolve_project_tool "$project_root")"; then
              exec "$tool_path" "$@"
            fi
            exec uv --project "$project_root" run "${name}" "$@"
          fi

          export UV_PYTHON_PREFERENCE="only-system"
          export UV_PYTHON_DOWNLOADS="never"
          ${lib.optionalString (name == "mypy") ''
          _fallback_env
        ''}
          exec "${package}/bin/${name}" "$@"
        }

        _main "$@"
      '';
    });
  # nixpkgs mypy trails majors behind PyPI; the machine fallback resolves the newest mypy through uv's tool cache.
  mypyLatest = pkgs.writeShellApplication {
    name = "mypy";
    runtimeInputs = [pkgs.uv];
    text = ''
      exec uv tool run mypy "$@"
    '';
  };
in {
  home.packages = with pkgs; [
    # --- Python Runtime (Canonical Source) ----------------------------------
    (projectPython "python")
    (projectPython "python3")
    python315 # Python 3.15

    # --- Python Tooling -----------------------------------------------------
    (projectTool "ruff" ruff) # Fast Python linter/formatter
    uv # Fast Python package installer and resolver
    (projectTool "ty" ty) # Astral type checker / language server
    (projectTool "mypy" mypyLatest) # Strict secondary type gate; project venv first, uv-tool newest fallback
  ];
}
