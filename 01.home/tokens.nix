# Title         : 01.home/tokens.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/tokens.nix
# ----------------------------------------------------------------------------
# Secret token reference definitions (safe to commit).

{ config, ... }:

{
  # --- Combined Secrets Configuration ---------------------------------------
  secrets = {
    # --- Secret File Paths --------------------------------------------------
    paths = {
      template = "${config.xdg.configHome}/op/env.template";
      cache = "${config.xdg.cacheHome}/op/env.cache";
    };

    # --- User Secret Definitions --------------------------------------------
    references = {
      # --- Core Tokens ------------------------------------------------------
      githubToken = "op://Tokens/Github Token/token";
      githubClassicToken = "op://Tokens/Github Classic Token/token";
      cachixAuthToken = "op://Tokens/Cachix Auth Token - Parametric Forge/token";
      tavilyAuthToken = "op://Tokens/Tavily Auth Token/token";
      # --- SSH Keys ---------------------------------------------------------
      # Authentication key for GitHub (used for git operations)
      sshAuthKey = "op://Tokens/Github Authentication key/public key";
      # Signing key for GitHub (used for commit/tag signing)
      sshSigningKey = "op://Tokens/Github Signing Key/public key";

      # Additional API keys (uncomment as needed)
      # openaiKey = "op://Tokens/openai-api-key/credential";
      # anthropicKey = "op://Tokens/anthropic-api-key/credential";
      # huggingfaceToken = "op://Tokens/huggingface/token";

      # Cloud providers
      # awsAccessKeyId = "op://${config.secrets.vault}/aws/access-key-id";
      # awsSecretAccessKey = "op://${config.secrets.vault}/aws/secret-access-key";
      # gcpServiceAccount = "op://${config.secrets.vault}/gcp/service-account";
      # azureClientSecret = "op://${config.secrets.vault}/azure/client-secret";

      # Database URLs
      # postgresUrl = "op://${config.secrets.vault}/postgres/url";
      # redisUrl = "op://${config.secrets.vault}/redis/url";
      # mongoUrl = "op://${config.secrets.vault}/mongodb/url";

      # Service tokens
      # dockerhubToken = "op://${config.secrets.vault}/dockerhub/token";
      # npmToken = "op://${config.secrets.vault}/npm/token";
      # pypiToken = "op://${config.secrets.vault}/pypi/token";
      # cargoToken = "op://${config.secrets.vault}/crates-io/token";
    };

    # --- Environment Variable Mappings --------------------------------------
    environment = {
      # Core environment variables (these will be available in shell)
      GITHUB_TOKEN = config.secrets.references.githubToken;
      GITHUB_CLASSIC_TOKEN = config.secrets.references.githubClassicToken;
      CACHIX_AUTH_TOKEN = config.secrets.references.cachixAuthToken;
      TAVILY_API_KEY = config.secrets.references.tavilyAuthToken;

      # Additional API keys (uncomment as needed)
      # OPENAI_API_KEY = config.secrets.references.openaiKey;
      # ANTHROPIC_API_KEY = config.secrets.references.anthropicKey;
      # HUGGING_FACE_HUB_TOKEN = config.secrets.references.huggingfaceToken;

      # AWS_ACCESS_KEY_ID = config.secrets.references.awsAccessKeyId;
      # AWS_SECRET_ACCESS_KEY = config.secrets.references.awsSecretAccessKey;
      # GOOGLE_APPLICATION_CREDENTIALS = config.secrets.references.gcpServiceAccount;
      # AZURE_CLIENT_SECRET = config.secrets.references.azureClientSecret;

      # DATABASE_URL = config.secrets.references.postgresUrl;
      # REDIS_URL = config.secrets.references.redisUrl;
      # MONGODB_URI = config.secrets.references.mongoUrl;

      # DOCKER_AUTH_TOKEN = config.secrets.references.dockerhubToken;
      # NPM_TOKEN = config.secrets.references.npmToken;
      # PYPI_TOKEN = config.secrets.references.pypiToken;
      # CARGO_REGISTRY_TOKEN = config.secrets.references.cargoToken;
    };
  };
}
