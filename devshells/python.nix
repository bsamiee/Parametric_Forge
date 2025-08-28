# Title         : devshells/python.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /devshells/python.nix
# ----------------------------------------------------------------------------
# Project-specific Python development environment with intelligent setup.

{ pkgs, myLib, ... }:

let
  # --- Default Python Version -----------------------------------------------
  python = pkgs.python313; # Can be overridden per project
in
myLib.build.auto pkgs (
  pkgs.mkShell {
    name = "python-project-dev";

    # --- Package Selection --------------------------------------------------
    packages = [
      python # Specific Python version for this project
    ];
    # --- Environment Variables ----------------------------------------------
    env = {
      PYTHON_VERSION = python.version;
      UV_PYTHON = "${python}/bin/python";
      POETRY_PYTHON = "${python}/bin/python";
      PYTHONPATH = "$PWD/src:$PWD/libs:$PWD/tests:\${PYTHONPATH:-}";
      PYTHONUNBUFFERED = "1";
      PYTHONUTF8 = "1";
      PYTHONPROFILEIMPORTTIME = "1";
      PYTHONWARNINGS = "default";
      PRE_COMMIT_HOME = "$PWD/.cache/pre-commit";
      NOX_CACHE_DIR = "$PWD/.cache/nox";
    };
    # --- Shell Hook ---------------------------------------------------------
    shellHook = ''
      echo "═══════════════════════════════════════════════════════"
      echo "  Python ${python.version} Project Development Environment"
      echo "═══════════════════════════════════════════════════════"
      echo ""
      echo "Project Setup:"
      echo "  Python: ${python}/bin/python"
      echo "  Cache:  .cache/ (project-local)"
      echo "  Venv:   .venv/ (project-local)"
      echo ""

      ${myLib.devshell.loadSecretsIfFresh}

      ${myLib.devshell.checkGlobalTools [
        {
          cmd = "poetry";
          name = "Poetry";
          install = "nix profile install nixpkgs#poetry";
        }
        {
          cmd = "ruff";
          name = "Ruff";
          install = "nix profile install nixpkgs#ruff";
        }
        {
          cmd = "uv";
          name = "UV";
          install = "nix profile install nixpkgs#uv";
        }
      ]}

      # Smart project detection and setup
      if [ -f "pyproject.toml" ]; then
        echo "📦 Project detected: pyproject.toml found"

        # Dependency analysis for service recommendations
        ${myLib.devshell.detectServices}

        # Virtual environment management
        ${myLib.devshell.activatePythonVenv}

        # Development workflow hints
        echo ""
        echo "🚀 Common commands:"
        echo "   poetry install    - Install dependencies"
        echo "   poetry run pytest - Run tests"
        echo "   poetry run ruff   - Lint code (if ruff installed globally)"
        echo "   pre-commit install - Setup git hooks (if pre-commit installed globally)"

      elif [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
        echo "📦 Legacy Python project detected"
        echo "💡 Consider migrating to pyproject.toml for modern tooling"

        # Basic venv setup for legacy projects
        if [ -d ".venv" ]; then
          echo "🐍 Activating virtual environment..."
          source .venv/bin/activate
        else
          echo "💡 Create virtual environment with: python -m venv .venv && source .venv/bin/activate"
        fi

      else
        echo "📁 General Python development environment"
        echo "💡 Create a new project with: poetry new project-name"
      fi

      echo ""
    '';
  }
)
