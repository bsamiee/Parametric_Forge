# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/default.nix
# ----------------------------------------------------------------------------
# Package aggregator with conditional imports based on user preferences.

{
  lib,
  pkgs,
  config,
  context ? null,
  ...
}:

let
  # Platform detection
  isDarwin = context.isDarwin or pkgs.stdenv.isDarwin;

  # Get configuration from the module system (already merged with defaults)
  cfg = config.configuration.settings;
  packageSuites = cfg.packageSuites or { };

  # --- Consolidated Package Imports (single evaluation) ---------------------
  # Import all package modules once, then conditionally use them
  allPackageModules = {
    core = import ./core.nix { inherit pkgs; };
    nixTools = import ./nix-tools.nix { inherit pkgs; };
    devTools = import ./dev-tools.nix { inherit pkgs; };
    sysadmin = import ./sysadmin.nix { inherit pkgs; };
    devops = import ./devops.nix {
      inherit pkgs lib;
      kubernetes = false;
    };
    media = import ./media-tools.nix { inherit pkgs; };
    macos = import ./macos-tools.nix { inherit pkgs; };
    aiTools = import ./ai-tools.nix { inherit pkgs; };
    python = import ./python-tools.nix { inherit pkgs; };
    rust = import ./rust-tools.nix { inherit pkgs; };
    node = import ./node-tools.nix { inherit pkgs; };
    lua = import ./lua-tools.nix { inherit pkgs; };
  };

  # --- Conditional Package Selection (using cached imports) -----------------
  # Core packages (always enabled)
  corePackages = allPackageModules.core;
  inherit (allPackageModules) nixTools devTools;

  # Conditional package collections
  sysadminTools = lib.optionals (packageSuites.sysadmin.enable or true) allPackageModules.sysadmin;
  devopsTools = lib.optionals (packageSuites.tools.devops.enable or true) allPackageModules.devops;
  mediaTools = lib.optionals (packageSuites.tools.media.enable or false) allPackageModules.media;
  macosTools = lib.optionals (isDarwin && (packageSuites.tools.macos.enable or isDarwin)) allPackageModules.macos;
  aiTools = lib.optionals (packageSuites.tools.ai.enable or false) allPackageModules.aiTools;

  # Development language tools (conditional based on interface config)
  pythonTools = lib.optionals (packageSuites.development.python.enable or true) allPackageModules.python;
  rustTools = lib.optionals (packageSuites.development.rust.enable or true) allPackageModules.rust;
  nodeTools = lib.optionals (packageSuites.development.node.enable or true) allPackageModules.node;
  luaTools = lib.optionals (packageSuites.development.lua.enable or true) allPackageModules.lua;

in
{
  home.packages = lib.flatten [
    # --- Core Packages (always included) ------------------------------------
    corePackages
    nixTools
    devTools

    # --- Conditional Packages -----------------------------------------------
    sysadminTools
    devopsTools
    mediaTools
    macosTools
    aiTools

    # --- Development Languages (conditional) --------------------------------
    pythonTools
    rustTools
    nodeTools
    luaTools
  ];

  # Interface configuration loaded successfully
}
