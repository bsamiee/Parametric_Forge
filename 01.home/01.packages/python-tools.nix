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

  # --- Core Libraries -------------------------------------------------------
  python3Packages.rich # Rich text formatting
  python3Packages.typer # CLI creation library
  python3Packages.pydantic # Data validation
  python3Packages.httpx # Modern HTTP client
  python3Packages.anyio # Async I/O abstraction
  python3Packages.aiofiles # Async file operations
  python3Packages.structlog # Structured logging
  python3Packages.tenacity # Retry logic
  python3Packages.watchdog # File system monitoring
  python3Packages.orjson # Fast JSON serialization

  # --- Data Science Stack ---------------------------------------------------
  python3Packages.numpy # Numerical computing
  python3Packages.pandas # Data analysis
  python3Packages.scipy # Scientific computing
  python3Packages.sympy # Symbolic mathematics
  python3Packages.polars # Fast DataFrame library
  python3Packages.pyarrow # Apache Arrow integration
  python3Packages.geopandas # Geospatial data
  python3Packages.dask # Parallel computing
  python3Packages.xarray # N-D labeled arrays

  # --- Notebook & Visualization ---------------------------------------------
  python3Packages.nbconvert # Convert Jupyter notebooks - For nbpreview.yazi
  python3Packages.jupyter-core # Core Jupyter functionality
  python3Packages.matplotlib # Plotting library
  python3Packages.plotly # Interactive plots
  python3Packages.seaborn # Statistical visualization

  # --- Web & API Development ------------------------------------------------
  python3Packages.fastapi # Modern web framework
  python3Packages.uvicorn # ASGI server
  python3Packages.sqlalchemy # SQL toolkit
  python3Packages.alembic # Database migrations

  # --- Data Processing & Parsing --------------------------------------------
  python3Packages.beautifulsoup4 # HTML/XML parsing
  python3Packages.lxml # XML processing
  python3Packages.pyyaml # YAML parsing
  python3Packages.tomlkit # TOML manipulation
  python3Packages.jsonschema # JSON validation
  python3Packages.openpyxl # Excel files
  python3Packages.pillow # Image processing
  python3Packages.duckdb # Analytical SQL

  # --- Security & Serialization ---------------------------------------------
  python3Packages.cryptography # Cryptographic recipes
  python3Packages.msgpack # Binary serialization
  python3Packages.cbor2 # CBOR format

  # --- CLI & TUI Development ------------------------------------------------
  python3Packages.textual # Terminal UI framework
  python3Packages.prompt-toolkit # Interactive CLIs

  # --- System & Integration -------------------------------------------------
  python3Packages.psutil # System utilities
  python3Packages.python-dateutil # Date handling
]
