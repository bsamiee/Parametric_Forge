# Title         : lib/devshell-helpers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /lib/devshell-helpers.nix
# ----------------------------------------------------------------------------
# Practical helper functions for development shells.

{ lib }:

rec {
  # --- Secret Cache Loading -------------------------------------------------
  # Check and source 1Password cache if fresh (used in all devshells)
  loadSecretsIfFresh = ''
    if [ -f "$OP_ENV_CACHE" ] && [ -z "$(find "$OP_ENV_CACHE" -mmin +5 2>/dev/null)" ]; then
      source "$OP_ENV_CACHE"
      echo "  ✓ Loaded 1Password secrets from cache"
    elif [ -f "$OP_ENV_TEMPLATE" ] && command -v op >/dev/null 2>&1; then
      echo "  💡 Load secrets with: op-cache-refresh (then re-enter shell)"
    fi
  '';

  # --- Tool Availability Checks ---------------------------------------------
  # Check if required global tools are available
  checkGlobalTools =
    tools:
    lib.concatStringsSep "\n" (
      map (tool: ''
        if ! command -v ${tool.cmd} &> /dev/null; then
          echo "  ⚠️  ${tool.name} not found - install with: ${tool.install}"
        fi
      '') tools
    );

  # --- Virtual Environment Detection ----------------------------------------
  # Python venv activation helper
  activatePythonVenv = ''
    if [ -d ".venv" ]; then
      echo "🐍 Activating virtual environment..."
      source .venv/bin/activate
      echo "   Virtual environment: $(python --version) in .venv/"
    elif [ -f "pyproject.toml" ]; then
      echo "💡 Create virtual environment with: poetry install"
    fi
  '';

  # --- Service Detection from Dependencies ----------------------------------
  # Detect services needed based on dependency files
  detectServices = ''
    NEEDS_POSTGRES=""
    NEEDS_REDIS=""
    NEEDS_DOCKER=""

    # Check Python dependencies
    if [ -f "pyproject.toml" ]; then
      grep -q -E "(asyncpg|psycopg|sqlalchemy|alembic)" pyproject.toml 2>/dev/null && NEEDS_POSTGRES="true"
      grep -q -E "(redis|celery|aiocache|arq)" pyproject.toml 2>/dev/null && NEEDS_REDIS="true"
    fi

    # Check Rust dependencies
    if [ -f "Cargo.toml" ]; then
      grep -q -E "(sqlx|diesel|postgres|tokio-postgres)" Cargo.toml 2>/dev/null && NEEDS_POSTGRES="true"
      grep -q -E "(redis|bb8-redis)" Cargo.toml 2>/dev/null && NEEDS_REDIS="true"
    fi

    # Check Node dependencies
    if [ -f "package.json" ]; then
      grep -q -E "(pg|postgres|sequelize|typeorm|prisma)" package.json 2>/dev/null && NEEDS_POSTGRES="true"
      grep -q -E "(redis|ioredis|bull|bullmq)" package.json 2>/dev/null && NEEDS_REDIS="true"
    fi

    # Check for Docker Compose
    [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] && NEEDS_DOCKER="true"

    if [ -n "$NEEDS_POSTGRES" ] || [ -n "$NEEDS_REDIS" ] || [ -n "$NEEDS_DOCKER" ]; then
      echo ""
      echo "🔧 Services detected in dependencies:"
      [ -n "$NEEDS_POSTGRES" ] && echo "   • PostgreSQL (database dependencies found)"
      [ -n "$NEEDS_REDIS" ] && echo "   • Redis (cache/queue dependencies found)"
      [ -n "$NEEDS_DOCKER" ] && echo "   • Docker services (compose file found)"
      echo "   💡 Configure services in docker-compose.yml or use global services"
    fi
  '';
}
