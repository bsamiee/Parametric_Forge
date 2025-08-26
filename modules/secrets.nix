# Title         : modules/secrets.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/secrets.nix
# ----------------------------------------------------------------------------
# Core secrets configuration module for 1Password integration.

{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.secrets = {
    # --- Secret References --------------------------------------------------
    vault = mkOption {
      type = types.str;
      default = "Private";
      description = "Default 1Password vault name";
    };
    references = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "1Password reference URLs (op://vault/item/field format)";
    };
    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Environment variables mapped to 1Password references";
    };
    # --- File Paths ---------------------------------------------------------
    paths = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Paths for secret-related files";
    };
  };
  # No default config needed - all secrets defined in 01.home/tokens.nix
}
