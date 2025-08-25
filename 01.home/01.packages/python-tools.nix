# Title         : python-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/python-tools.nix
# ----------------------------------------------------------------------------
# Python development environment and scientific computing tools.

{ pkgs, ... }:

with pkgs;
[
  # --- Python Toolchain -----------------------------------------------------
  python313 # Python 3.13
  pipx # Install Python apps in isolated environments
  poetry # Python dependency management
  ruff # Fast Python linter/formatter
  uv # Fast Python package installer and resolver
  mypy # Static type checker
  basedpyright # Type checker for Python (better than pyright)

  # --- Python Development Utilities -----------------------------------------
  cookiecutter # Project template tool
  python3Packages.black # Python code formatter
  python3Packages.pytest # Testing framework
  python3Packages.rich # Rich text formatting
  python3Packages.typer # CLI creation library
  python3Packages.pydantic # Data validation
  python3Packages.httpx # Modern HTTP client
  python3Packages.numpy # Numerical computing
]
