# Title         : config_files.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/files/config_files.nix
# ----------------------------------------------------------------------------
# XDG config file deployments

{ lib, pkgs, ... }:

{
  xdg.configFile = {
    # --- System Tools -------------------------------------------------------
    # fastfetch, bat, ripgrep, fd, eza, etc.

    # --- Application Related ------------------------------------------------
    # yazi, wezterm, etc.

    # --- Development Tools --------------------------------------------------
    # git, language configs, formatters

    # --- Container Runtime --------------------------------------------------
    # docker, colima, podman

    # --- Window Management --------------------------------------------------
    # yabai, skhd, borders, hammerspoon

    # --- 1Password Secret Template ------------------------------------------
    "op/env.template".text = ''
      # 1Password Secret References (auto-generated)
      GITHUB_TOKEN="op://Tokens/Github Token/token"
      GITHUB_CLASSIC_TOKEN="op://Tokens/Classic Github Token/token"
      PERPLEXITY_API_KEY="op://Tokens/Perplexity API Key/api key"
      CACHIX_AUTH_TOKEN="op://Tokens/Cachix Token/token"
      TAVILY_API_KEY="op://Tokens/Tavily API Key/api key"
      EXA_API_KEY="op://Tokens/Exa API Key/api key"
    '';
  };
}
