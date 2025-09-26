# Title         : state_xdg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/xdg/state_xdg.nix
# ----------------------------------------------------------------------------
# XDG_STATE_HOME directory structure

{ config, lib, ... }:

{
  home.activation.createStateDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # State directories for persistent runtime data

    # --- Shell History & State ----------------------------------------------
    mkdir -pm 755 "${config.xdg.stateHome}/zsh"         # ZSH history
    mkdir -pm 755 "${config.xdg.stateHome}/bash"        # Bash history
    mkdir -pm 755 "${config.xdg.stateHome}/less"        # Less history

    # --- System State -------------------------------------------------------
    mkdir -pm 755 "${config.xdg.stateHome}/logs"        # Application logs
    mkdir -pm 755 "${config.xdg.stateHome}/nix"         # Nix profiles
  '';
}
