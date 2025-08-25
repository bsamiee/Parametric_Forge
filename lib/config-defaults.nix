# Title         : lib/config-defaults.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /lib/config-defaults.nix
# ----------------------------------------------------------------------------
# Defines a pure function that returns the default project configuration.

{
  isDarwin ? false,
}:

{
  # --- Package Suites -------------------------------------------------------
  packageSuites = {
    core.enable = true;
    nixTools.enable = true;
    sysadmin.enable = false;
    development = {
      python = {
        enable = false;
        global = false;
      };
      rust = {
        enable = false;
        global = false;
      };
      node = {
        enable = false;
        global = false;
      };
      lua = {
        enable = false;
        global = false;
      };
    };
    tools = {
      devops.enable = false;
      media.enable = false;
      macos.enable = isDarwin;
      ai.enable = false;
    };
  };

  # --- Integrations ---------------------------------------------------------
  integrations = {
    onePassword = {
      sshAgent = false;
      secrets = false;
    };
    cachix = false;
  };

  # --- Git Configuration ----------------------------------------------------
  gitConfig = {
    username = "";
    email = "";
  };

  # --- System Configuration -------------------------------------------------
  system = {
    timezone = "America/Chicago"; # US Central Time (Houston)
  };
}
