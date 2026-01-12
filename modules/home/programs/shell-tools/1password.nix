# Title         : 1password.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/1password.nix
# ----------------------------------------------------------------------------
# 1Password: Shell Plugins (gh), biometric CLI auth, token injection on rebuild
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.shell-plugins.hmModules.default];

  # --- Shell Plugins: Biometric auth for supported CLIs ------------------------
  # NOTE: gh is intentionally excluded - it uses PAT token via GH_TOKEN env var
  # This ensures gh works in non-interactive contexts (Claude Code, CI, scripts)
  programs._1password-shell-plugins = {
    enable = true;
    plugins = []; # Add other CLIs here if needed (e.g., pkgs.aws-cli)
  };

  # --- Environment: Biometric unlock for CLI ----------------------------------
  home.sessionVariables = {
    OP_BIOMETRIC_UNLOCK_ENABLED = "true";
  };

  # --- Setup: op config directory -----------------------------------------------
  # Run BEFORE writeBoundary (validation phase) - safe for idempotent directory creation
  home.activation.ensure1PasswordDirs = lib.hm.dag.entryBefore ["writeBoundary"] ''
    mkdir -p "${config.xdg.configHome}/op"
    chmod 700 "${config.xdg.configHome}/op"
  '';

  # --- Secret Template: API keys for op inject -----------------------------------
  xdg.configFile."op/env.template".text = ''
    # API Keys - resolved during rebuild via "op inject"
    # IMPORTANT: export keyword ensures child processes inherit these variables
    # Update this list when adding new tokens to your 1Password vault

    # CLI tools and APIs
    # NOTE: ANTHROPIC_API_KEY intentionally excluded - use Claude Code OAuth instead
    # Projects needing API key auth should configure it locally
    export GREPTILE_TOKEN="op://Tokens/GREPTILE_TOKEN/token"
    export RHINO_TOKEN="op://Tokens/RHINO_TOKEN/token"
    export EXA_API_KEY="op://Tokens/Exa API Key/token"
    export PERPLEXITY_API_KEY="op://Tokens/Perplexity Sonar API Key/token"
    export TAVILY_API_KEY="op://Tokens/Tavily Auth Token/token"
    export SONAR_TOKEN="op://Tokens/SONAR_TOKEN/token"
    export CACHIX_AUTH_TOKEN="op://Tokens/Cachix Auth Token - Parametric Forge/token"
    export HOSTINGER_TOKEN="op://Tokens/HOSTINGER_TOKEN/token"
    export CONTEXT7_API_KEY="op://Tokens/CONTEXT7_API_KEY/token"

    # GitHub CLI (gh prefers GH_TOKEN, GITHUB_TOKEN is fallback for other tools)
    export GH_TOKEN="op://Tokens/Github Token/token"
    export GITHUB_TOKEN="op://Tokens/Github Token/token"

    # GitHub Projects (Classic PAT required - fine-grained PATs don't support Projects API)
    export GH_PROJECTS_TOKEN="op://Tokens/GH_PROJECTS_TOKEN/token"
  '';

  # --- Activation Hook: Generate token cache during rebuild ----------------------
  # CRITICAL: Must run AFTER linkGeneration to ensure template file exists
  # linkGeneration writes xdg.configFile entries after writeBoundary
  home.activation.injectSecretsFromVault = lib.hm.dag.entryAfter ["linkGeneration"] ''
    cache_file="$HOME/.config/hm-op-session.sh"
    template_file="$HOME/.config/op/env.template"

    # Fail loudly if template missing (indicates DAG ordering bug)
    if [[ ! -f "$template_file" ]]; then
      echo "ERROR: Template file not found: $template_file" >&2
      echo "This indicates a home-manager activation ordering issue." >&2
      exit 1
    fi

    # Create cache file with resolved tokens from 1Password
    echo "Injecting secrets from 1Password vault..." >&2
    mkdir -p "$(dirname "$cache_file")"
    if ${pkgs._1password-cli}/bin/op inject -f -i "$template_file" -o "$cache_file"; then
      chmod 600 "$cache_file"
      echo "✓ Tokens cached to $cache_file" >&2
    else
      echo "⚠ Warning: op inject failed - 1Password may not be authenticated. Run: op signin" >&2
      # Create empty file so zsh doesn't fail on source
      touch "$cache_file"
      chmod 600 "$cache_file"
    fi
  '';
}
