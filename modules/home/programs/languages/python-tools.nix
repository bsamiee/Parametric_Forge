# Title         : python-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/python-tools.nix
# ----------------------------------------------------------------------------
# Machine Python 3.15 interpreter and tools: nvim's provider and Forge's own scripts. A project's mise.toml and uv.lock own the interpreter and
# tools inside its tree — `mise activate` sources the uv venv ahead of these, and `uv run` reaches it from a non-interactive caller.
{
  config,
  pkgs,
  ...
}: let
  style = import ../../../style.nix;
  # nixpkgs mypy trails majors behind PyPI; the machine mypy resolves the newest release through uv's tool cache.
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
  # than yields. uv needs no config file: its interpreter policy (UV_PYTHON_PREFERENCE, UV_PYTHON_DOWNLOADS) is the pythonEnv session row set
  # of modules/common/toolchain-env.nix.
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
      # Ad-hoc contexts have no project root; without this row mypy drops a .mypy_cache into the working directory.
      cache_dir = ${config.xdg.cacheHome}/mypy
      pretty = true
    '';
  };

  home.packages = with pkgs; [
    # --- [PYTHON_RUNTIME_CANONICAL_SOURCE]
    python315

    # --- [PYTHON_TOOLING]
    ruff # Fast Python linter/formatter
    uv # Fast Python package installer and resolver
    ty # Astral type checker / language server
    mypyLatest # Strict secondary type gate at the newest release
  ];
}
