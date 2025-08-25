# Title         : lib/detection.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /lib/detection.nix
# ----------------------------------------------------------------------------
# Platform and environment detection utilities.

{ lib }:

rec {
  # --- Platform Detection ---------------------------------------------------
  isDarwin = system: lib.hasSuffix "darwin" system;
  isLinux = system: lib.hasSuffix "linux" system;
  isAarch64 = system: lib.hasPrefix "aarch64" system;
  isX86_64 = system: lib.hasPrefix "x86_64" system;

  # --- System Parsing -------------------------------------------------------
  getSystemArch = system: lib.elemAt (lib.splitString "-" system) 0;
  getSystemPlatform = system: lib.elemAt (lib.splitString "-" system) 1;

  # --- Cached Expensive Checks ----------------------------------------------
  # WSL detection - evaluated once and reused
  isWSLSystem = builtins.pathExists /proc/sys/fs/binfmt_misc/WSLInterop;

  # --- Context Cache --------------------------------------------------------
  # Pre-computed contexts for known systems (avoids repeated parsing)
  contextTemplates = {
    "aarch64-darwin" = {
      arch = "aarch64";
      platform = "darwin";
      isDarwin = true;
      isLinux = false;
      isAarch64 = true;
      isX86_64 = false;
      isWSL = false;
      configName = "default";
    };
    "x86_64-darwin" = {
      arch = "x86_64";
      platform = "darwin";
      isDarwin = true;
      isLinux = false;
      isAarch64 = false;
      isX86_64 = true;
      isWSL = false;
      configName = "x86_64";
    };
    "x86_64-linux" = {
      arch = "x86_64";
      platform = "linux";
      isDarwin = false;
      isLinux = true;
      isAarch64 = false;
      isX86_64 = true;
      isWSL = isWSLSystem;
      configName = "vm";
    };
    "aarch64-linux" = {
      arch = "aarch64";
      platform = "linux";
      isDarwin = false;
      isLinux = true;
      isAarch64 = true;
      isX86_64 = false;
      isWSL = false;
      configName = "vm";
    };
  };

  # --- Context Detection ----------------------------------------------------
  detectContext =
    system: user:
    # Use cached template if available, otherwise compute
    if contextTemplates ? ${system} then
      contextTemplates.${system}
      // {
        inherit system user;
        userHome = if contextTemplates.${system}.isDarwin then "/Users/${user}" else "/home/${user}";
      }
    else
      # Fallback for unknown systems (preserves extensibility)
      let
        arch = getSystemArch system;
        platform = getSystemPlatform system;
        linux = isLinux system;
      in
      {
        inherit
          system
          arch
          platform
          user
          ;
        isDarwin = isDarwin system;
        isLinux = linux;
        isAarch64 = isAarch64 system;
        isX86_64 = isX86_64 system;
        isWSL = linux && isWSLSystem;
        userHome = if isDarwin system then "/Users/${user}" else "/home/${user}";
        configName =
          if isDarwin system then
            if isAarch64 system then "default" else "x86_64"
          else if isLinux system then
            "vm"
          else
            "unknown";
      };

  # --- Environment Detection ------------------------------------------------
  isContainer =
    pkgs: pkgs.stdenv.hostPlatform.isLinux && (builtins.pathExists /.dockerenv || builtins.pathExists /run/.containerenv);
  isVM = pkgs: pkgs.stdenv.hostPlatform.isLinux && (builtins.pathExists /proc/vz || builtins.pathExists /proc/xen);
  isWSL = pkgs: pkgs.stdenv.hostPlatform.isLinux && isWSLSystem;
}
