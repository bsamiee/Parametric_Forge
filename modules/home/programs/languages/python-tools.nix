# Title         : python-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/python-tools.nix
# ----------------------------------------------------------------------------
# Python development environment - Canonical Python 3.14 installation.
{pkgs, ...}: {
  home.packages = with pkgs; [
    # --- Python Runtime (Canonical Source) ----------------------------------
    python314 # Python 3.14.0

    # --- Python Tooling -----------------------------------------------------
    ruff # Fast Python linter/formatter
    uv # Fast Python package installer and resolver
  ];
}
