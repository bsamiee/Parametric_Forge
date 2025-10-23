# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/config.nix
# ----------------------------------------------------------------------------
# Zsh profile and login shell configurations

{ config, lib, pkgs, ... }:

{
  programs.zsh = {
    profileExtra = ''
      # --- PATH initialization (order 50) -----------------------------------------

      if [[ -d "/Applications/Rhino 8.app/Contents/Resources/bin" ]]; then
        export PATH="/Applications/Rhino 8.app/Contents/Resources/bin:$PATH"
      fi

      # Nix (Determinate Nix)
      if [[ -d "/nix/var/nix/profiles/default/bin" ]]; then
        export PATH="/nix/var/nix/profiles/default/bin:$PATH"
      fi

      # Homebrew (Darwin)
      if [[ -d "/opt/homebrew/bin" ]]; then
        export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
      fi

      # .NET 8 for Rhino (versioned homebrew formula)
      if [[ -d "/opt/homebrew/opt/dotnet@8/bin" ]]; then
        export PATH="/opt/homebrew/opt/dotnet@8/bin:$PATH"
      fi

      # Nix daemon sourcing for Determinate Nix
      if [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
        source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
      fi
    '';

    loginExtra = ''
      # Commands to run on login go here
    '';

    logoutExtra = ''
      # Commands to run on logout go here
    '';
  };
}
