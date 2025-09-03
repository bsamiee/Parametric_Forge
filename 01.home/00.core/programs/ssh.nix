# Title         : ssh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/ssh.nix
# ----------------------------------------------------------------------------
# SSH client configuration with 1Password agent integration.

{
  config,
  lib,
  myLib,
  context,
  ...
}:

{
  programs.ssh = {
    enable = true;

    # Disable default config to prevent deprecation warnings
    enableDefaultConfig = false;

    # --- Host Configurations ------------------------------------------------
    matchBlocks = {
      # Default match block with connection management settings
      "*" = {
        # Reuse SSH connections for performance
        controlMaster = "auto";
        controlPersist = "10m";
        controlPath = "${config.xdg.cacheHome}/ssh/control-%C";

        # Security settings
        hashKnownHosts = true;
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
        # 1Password agent automatically provides the correct key
      };
      "gist.github.com" = {
        hostname = "gist.github.com";
        user = "git";
      };

      # --- WezTerm SSH Domains (placeholder examples) -----------------------
      # These will be available in SSH config and can be used by WezTerm
      # Uncomment and customize as needed:

      # "dev-server" = {
      #   hostname = "dev.example.com";
      #   user = "bardiasamiee";
      #   # WezTerm will use this via SSH config
      # };

      # "staging-server" = {
      #   hostname = "staging.example.com";
      #   user = "bardiasamiee";
      # };

      # "prod-server" = {
      #   hostname = "prod.example.com";
      #   user = "bardiasamiee";
      #   forwardAgent = true;  # If needed
      # };
    };
    # --- Global SSH Client Configuration ------------------------------------
    extraConfig = lib.mkBefore ''
      # Use 1Password for all SSH keys
      IdentityAgent "${myLib.secrets.opSSHSocket context}"

      # Don't fall back to other auth methods
      IdentitiesOnly yes
      PreferredAuthentications publickey

      # Disable macOS keychain integration (1Password handles this)
      ${lib.optionalString context.isDarwin ''
        UseKeychain no
        AddKeysToAgent no
      ''}

      # Keepalive for long operations
      ServerAliveInterval 60
      ServerAliveCountMax 3

      # Security
      StrictHostKeyChecking ask
      UpdateHostKeys yes
    '';
  };
  # --- Git SSH Signing Configuration ----------------------------------------
  programs.git.extraConfig = lib.mkIf config.programs.git.enable {
    # Use SSH for commit signing
    gpg = {
      format = "ssh";
      ssh.allowedSignersFile = "~/.ssh/allowed_signers";
    };
    # Point to the SSH key file path (not raw key content)
    user.signingkey = "~/.ssh/github_sign.pub";

    # Enable commit and tag signing by default
    commit.gpgsign = true;
    tag.gpgsign = true;
  };

  # --- SSH Key Files --------------------------------------------------------
  # Note: The actual public keys and allowed_signers are fetched dynamically
  # from 1Password by the activation script in activation.nix
  # This ensures we get the actual keys, not just the references
}
