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

  # --- Base Python Environment ----------------------------------------------
  # Development-specific tools not needed globally
  pythonWithPackages = python.withPackages (
    ps: with ps; [
      # Only pip needed - poetry/uv handle the rest
      pip

      # Interactive development
      ipython
      ipdb
      icecream

      # Testing suite
      pytest
      pytest-cov
      pytest-xdist
      pytest-timeout
      pytest-mock
      hypothesis
      coverage
      faker
      freezegun

      # Code quality
      vulture
      radon

      # Profiling
      pyinstrument
    ]
  );
in
myLib.build.auto pkgs (
  pkgs.mkShell {
    name = "python-project-dev";

    # --- Package Selection --------------------------------------------------
    packages = with pkgs; [
      pythonWithPackages # Python with development packages

      # Testing & automation tools
      nox
      python3Packages.tox
      pre-commit

      # Build & distribution
      python3Packages.build
      python3Packages.twine
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

      # Project-local cache directories (all tools use .cache/)
      PRE_COMMIT_HOME = "$PWD/.cache/pre-commit";
      NOX_CACHE_DIR = "$PWD/.cache/nox";
      MYPY_CACHE_DIR = "$PWD/.cache/mypy";
      RUFF_CACHE_DIR = "$PWD/.cache/ruff";
      PYTEST_CACHEDIR = "$PWD/.cache/pytest";
      POETRY_CACHE_DIR = "$PWD/.cache/poetry";
      UV_CACHE_DIR = "$PWD/.cache/uv";
      PIP_CACHE_DIR = "$PWD/.cache/pip";
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
        echo "Project detected: pyproject.toml found"
        
        # Check for data science dependencies
        if grep -q -E "(numpy|pandas|scipy|matplotlib|scikit-learn)" pyproject.toml 2>/dev/null; then
          echo "Data science dependencies detected"
          echo "   Note: Heavy packages (numpy, pandas, etc.) are available globally"
          echo "   Use 'poetry install' to get project-specific versions if needed"
        fi

        # Dependency analysis for service recommendations
        ${myLib.devshell.detectServices}

        # Virtual environment management
        ${myLib.devshell.activatePythonVenv}

        # Development workflow hints
        echo ""
        echo "Common commands:"
        echo "   poetry install      - Install dependencies"
        echo "   pytest              - Run tests (available globally)"
        echo "   ruff check .        - Lint code"
        echo "   ruff format .       - Format code"
        echo "   mypy .              - Type check"
        echo "   pre-commit install  - Setup git hooks"
        echo "   nox                 - Run test automation"

      elif [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
        echo "Legacy Python project detected"
        echo "Consider migrating to pyproject.toml for modern tooling"

        # Basic venv setup for legacy projects
        if [ -d ".venv" ]; then
          echo "Activating virtual environment..."
          source .venv/bin/activate
        else
          echo "Create virtual environment with: python -m venv .venv && source .venv/bin/activate"
        fi

      else
        echo "General Python development environment"
        echo "Create a new project with: poetry new project-name"
      fi

      echo ""
    '';
  }
)
