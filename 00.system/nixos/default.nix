# Title         : 00.system/nixos/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/nixos/default.nix
# ----------------------------------------------------------------------------
# Base NixOS system configuration for VMs and physical hosts.

{
  config,
  lib,
  pkgs,
  context,
  ...
}:

{
  # --- Imports --------------------------------------------------------------
  imports = [
    ../default.nix
  ];
  # --- System & State -------------------------------------------------------
  system.stateVersion = "25.05";

  # --- Bootloader -----------------------------------------------------------
  boot = lib.mkIf (!config.boot.isContainer or false) {
    loader.systemd-boot.enable = lib.mkDefault true;
    loader.efi.canTouchEfiVariables = lib.mkDefault true;
  };
  # --- File Systems ---------------------------------------------------------
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  # --- Activation Script ----------------------------------------------------
  system.activationScripts.parametricForge = {
    text = ''
      echo ""
      echo "╔══════════════════════════════════════════════════════════════════════╗"
      echo "║                      Parametric Forge Activation                     ║"
      echo "╚══════════════════════════════════════════════════════════════════════╝"
      echo "  Platform: Linux (${context.arch})"
      echo "  User: ${context.user}"
      echo "  Home: ${context.userHome}"
      echo "  Hostname: ${config.networking.hostName}"
      echo "════════════════════════════════════════════════════════════════════════"
      echo ""
    '';
  };
  # --- Networking -----------------------------------------------------------
  networking = {
    hostName = lib.mkDefault "parametric-forge";
    networkmanager.enable = lib.mkDefault true;
  };
  # --- Programs -------------------------------------------------------------
  programs.zsh.enable = true;

  # --- Services -------------------------------------------------------------
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PermitRootLogin = lib.mkDefault "no";
      PasswordAuthentication = lib.mkDefault false;
    };
  };
  # --- User Management ------------------------------------------------------
  users.users.${context.user} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
  };
}
