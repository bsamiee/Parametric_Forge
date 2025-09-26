# Title         : secrets.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/secrets.nix
# ----------------------------------------------------------------------------
# Secret token reference definitions (safe to commit)

{ config, ... }:

let
  # Define secret references
  secretRefs = {
    # API Tokens
    githubToken = "op://Tokens/Github Token/token";
    githubClassicToken = "op://Tokens/Github Classic Token/token";
    cachixAuthToken = "op://Tokens/Cachix Auth Token - Parametric Forge/token";
    tavilyAuthToken = "op://Tokens/Tavily Auth Token/token";
    perplexityApiKey = "op://Tokens/Perplexity Sonar API Key/token";
    exaApiKey = "op://Tokens/Exa API Key/token";

    # SSH Keys
    sshAuthKey = "op://Tokens/Github Authentication key/public key";
    sshSigningKey = "op://Tokens/Github Signing Key/public key";
  };
in
{
  # Export environment variables with 1Password references, these will be resolved by op-run when needed
  home.sessionVariables = {
    GITHUB_TOKEN = secretRefs.githubToken;
    GITHUB_CLASSIC_TOKEN = secretRefs.githubClassicToken;
    PERPLEXITY_API_KEY = secretRefs.perplexityApiKey;
    CACHIX_AUTH_TOKEN = secretRefs.cachixAuthToken;
    TAVILY_API_KEY = secretRefs.tavilyAuthToken;
    EXA_API_KEY = secretRefs.exaApiKey;
  };
}
