# Title         : 1password.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/1password.nix
# ----------------------------------------------------------------------------
# 1Password: Shell Plugins (gh), biometric CLI auth, token injection on rebuild

{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.shell-plugins.hmModules.default ];

  # --- Shell Plugins: GitHub CLI with biometric auth ---------------------------
  programs._1password-shell-plugins = {
    enable = true;
    plugins = [ pkgs.gh ];
  };

  # --- Environment: Biometric unlock for CLI ----------------------------------
  home.sessionVariables = {
    OP_BIOMETRIC_UNLOCK_ENABLED = "true";
  };

  # --- Setup: op config directory -----------------------------------------------
  home.activation.ensure1PasswordDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.xdg.configHome}/op"
    chmod 700 "${config.xdg.configHome}/op"
  '';

  # --- Secret Template: API keys for op inject -----------------------------------
  xdg.configFile."op/env.template".text = ''
    # API Keys - resolved during rebuild via "op inject"
    # Update this list when adding new tokens to your 1Password vault

    # CLI tools and APIs
    RHINO_TOKEN="op://Tokens/RHINO_TOKEN/token"
    EXA_API_KEY="op://Tokens/Exa API Key/token"
    PERPLEXITY_API_KEY="op://Tokens/Perplexity Sonar API Key/token"
    TAVILY_API_KEY="op://Tokens/Tavily Auth Token/token"
    CACHIX_AUTH_TOKEN="op://Tokens/Cachix Auth Token - Parametric Forge/token"
    GITHUB_TOKEN="op://Tokens/Github Token/token"
  '';

  # --- Activation Hook: Generate token cache during rebuild ----------------------
  home.activation.injectSecretsFromVault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cache_file="$HOME/.config/hm-op-session.sh"
    template_file="$HOME/.config/op/env.template"

    # Create cache file with resolved tokens from 1Password
    if [[ -f "$template_file" ]]; then
      echo "Injecting secrets from 1Password vault..." >&2
      mkdir -p "$(dirname "$cache_file")"
      if ${pkgs._1password-cli}/bin/op inject -f -i "$template_file" -o "$cache_file"; then
        chmod 600 "$cache_file"
        echo "✓ Tokens cached to $cache_file" >&2
      else
        echo "⚠ Warning: op inject failed - 1Password may not be authenticated. Run: op signin" >&2
        # Create empty file so zsh doesn't fail
        touch "$cache_file"
        chmod 600 "$cache_file"
      fi
    fi
  '';
}
