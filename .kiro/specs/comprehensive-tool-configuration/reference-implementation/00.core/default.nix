# Title         : reference-implementation/00.core/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : .kiro/specs/comprehensive-tool-configuration/reference-implementation/00.core/default.nix
# ----------------------------------------------------------------------------
# Reference implementation: Core configuration module aggregator
# This file demonstrates proper import structure for core configurations

{ ... }:

{
  imports = [
    # --- Program Configurations -----------------------------------------
    ./programs                       # All declarative program configurations
    
    # --- Static Configuration Files -------------------------------------
    # Static configs are deployed via file-management.nix, not imported here
    # The configs/ directory contains template files for reference
  ];
}