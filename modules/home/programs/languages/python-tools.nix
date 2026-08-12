# Title         : python-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/python-tools.nix
# ----------------------------------------------------------------------------
# Canonical Python 3.15 development environment.
{
  config,
  lib,
  pkgs,
  ...
}: let
  style = import ../../../style.nix;
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
          export UV_PYTHON_PREFERENCE="only-system"
          export UV_PYTHON_DOWNLOADS="never"

          if [[ "''${FORGE_PYTHON_SHIM_BYPASS:-}" == "1" ]]; then
            exec "${python}/bin/${name}" "$@"
          fi

          # Materialized environments only: an unsynced locked project falls through to the store
          # interpreter. An implicit `uv run` here deadlocks against any external uv holding the
          # project lock (uv sync's interpreter discovery execs this shim) and lets incidental
          # callers (node-gyp probing python3) trigger a full dependency materialization;
          # provisioning is explicit via `uv sync`.
          local project_root
          if project_root="$(_find_project_root)"; then
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
          fi

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
          export UV_PYTHON_PREFERENCE="only-system"
          export UV_PYTHON_DOWNLOADS="never"

          if [[ "''${FORGE_PYTHON_TOOL_SHIM_BYPASS:-}" == "1" ]]; then
            exec "${package}/bin/${name}" "$@"
          fi

          # Materialized environments only: an unsynced project falls through to the store binary,
          # which still reads the project's [tool.*] law from the working tree. An implicit
          # `uv run` here blocks on the project lock during syncs and materializes the full
          # dependency set as a side effect; provisioning is explicit via `uv sync`.
          local project_root
          local tool_path
          if project_root="$(_find_project_root)"; then
            if tool_path="$(_resolve_project_tool "$project_root")"; then
              exec "$tool_path" "$@"
            fi
          fi

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
  # Machine-level fallback style: ruff and mypy resolve their XDG user config only when upward discovery finds no project config, so project law
  # always wins and ad-hoc scripts inherit the house style. ty needs no user row — strictness is project law and its user-level config merges rather
  # than yields. uv needs no user row — its defaults (managed pythons, automatic downloads) already are the
  # house policy, and a row restating defaults is dead config.
  xdg.configFile = {
    "ruff/ruff.toml".text = ''
      # Ad-hoc contexts have no project root; without this row `ruff check` drops a .ruff_cache into the working directory.
      cache-dir = "${config.xdg.cacheHome}/ruff"

      preview = true
      line-length = ${toString style.width}
      indent-width = ${toString style.indent}

      [format]
      line-ending = "lf"
      docstring-code-format = true
      skip-magic-trailing-comma = true

      [lint]
      select = ["E4", "E7", "E9", "F", "B", "I", "SIM", "UP", "RUF"]

      # The formatter owns trailing commas; default-true here fights skip-magic-trailing-comma and warns on every format run.
      [lint.isort]
      split-on-trailing-comma = false
    '';
    "mypy/config".text = ''
      [mypy]
      pretty = true
    '';
  };

  home.packages = with pkgs; [
    # --- [PYTHON_RUNTIME_CANONICAL_SOURCE]
    (projectPython "python")
    (projectPython "python3")
    python315

    # --- [PYTHON_TOOLING]
    (projectTool "ruff" ruff) # Fast Python linter/formatter
    uv # Fast Python package installer and resolver
    (projectTool "ty" ty) # Astral type checker / language server
    (projectTool "mypy" mypyLatest) # Strict secondary type gate; project venv first, uv-tool newest fallback
  ];
}
