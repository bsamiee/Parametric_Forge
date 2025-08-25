# Title         : 01.home/nixos/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/nixos/default.nix
# ----------------------------------------------------------------------------
# NixOS/Linux-specific home-manager configuration.

{ lib, pkgs, ... }:

{
  # --- Platform Assertion ---------------------------------------------------
  assertions = [
    {
      assertion = pkgs.stdenv.isLinux;
      message = "01.home/nixos/default.nix should only be used on Linux/NixOS systems";
    }
  ];
  # --- Linux-Specific Settings ----------------------------------------------
  # Programs will be imported from modules/programs/nixos.nix
  # Aliases will be imported from modules/aliases/nixos.nix

  # --- Systemd User Services ------------------------------------------------
  # User services can be configured here when needed

  # --- Container/VM Detection -----------------------------------------------
  home.activation.detectEnvironment = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
      echo "[Parametric Forge] Container environment detected"
    elif command -v systemd-detect-virt >/dev/null 2>&1; then
      VIRT=$(systemd-detect-virt 2>/dev/null || echo "none")
      if [ "$VIRT" != "none" ]; then
        echo "[Parametric Forge] Virtual machine detected: $VIRT"
      fi
    fi
  '';
}
