# Title         : 00.system/nixos/containers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/nixos/containers.nix
# ----------------------------------------------------------------------------
# Container-specific NixOS configuration overrides.

{ lib, pkgs, ... }:

{
  # --- Container-Specific Overrides -----------------------------------------
  boot.isContainer = true;
  hardware.enableRedistributableFirmware = false;
  networking = {
    useDHCP = false;
    useHostResolvConf = lib.mkDefault true;
  };
  services.openssh.enable = lib.mkForce false;
  environment.systemPackages = lib.mkForce (
    with pkgs;
    [
      vim
      git
      curl
    ]
  );
}
