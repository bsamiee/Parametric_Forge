# Title         : reference-implementation/00.core/programs/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : .kiro/specs/comprehensive-tool-configuration/reference-implementation/00.core/programs/default.nix
# ----------------------------------------------------------------------------
# Reference implementation: Program configuration imports and organization
# 
# This file demonstrates the complete import structure for all program configurations
# in the Parametric Forge system. Programs are organized by implementation phases
# based on priority and complexity, following the comprehensive tool configuration
# specification.
#
# ORGANIZATION PRINCIPLES:
# - Phase 1: Essential daily-use tools (high priority, immediate impact)
# - Phase 2: System utilities and development tools (medium priority)
# - Phase 3: Specialized and advanced tools (lower priority, complex setup)
# - Existing: Previously implemented and functional configurations
#
# IMPLEMENTATION STATUS:
# All program files are created as reference implementations with comprehensive
# configuration examples. Most configurations are commented out pending home-manager
# module availability or require corresponding config files and environment variables.
#
# INTEGRATION REQUIREMENTS:
# 1. Corresponding packages must exist in 01.home/01.packages/
# 2. Environment variables should be defined in 01.home/environment.nix
# 3. Static config files should be deployed via 01.home/file-management.nix
# 4. Platform-specific overrides handled in darwin/ and nixos/ directories

{ ... }:

{
  imports = [
    # --- Phase 1: Essential Tools (High Priority) -----------------------
    # Core productivity and navigation tools for daily development workflow
    ./essential-tools.nix            # broot, mcfly configurations
    ./development-workflow.nix       # just, pre-commit, hyperfine, tokei
    ./shell-enhancements.nix         # vivid configuration
    ./file-operations.nix            # rsync, ouch configurations
    
    # --- Phase 2: System and Network Tools ------------------------------
    # System monitoring, network diagnostics, and file management tools
    ./system-monitoring.nix          # procs, bottom configurations
    ./network-tools.nix              # xh, doggo, gping configurations
    ./development-tools.nix          # shfmt, sqlfluff, fx configurations
    ./file-managers.nix              # yazi, lf configurations
    
    # --- Phase 3: Specialized Tools -------------------------------------
    # Advanced development tools and specialized applications
    ./container-tools.nix            # docker-client, colima configurations
    ./git-alternatives.nix           # gitui configuration
    ./language-tools.nix             # rustup, bacon configurations
    ./media-tools.nix                # ffmpeg configuration
    ./advanced-editors.nix           # neovim configuration
    
    # --- Existing Configurations (Already Implemented) ------------------
    # NOTE: git-tools.nix, shell-tools.nix, ssh.nix, and zsh.nix are already
    # implemented in the actual project at 01.home/00.core/programs/ and have
    # been removed from this reference implementation to avoid duplication
  ];

  # --- Implementation Notes --------------------------------------------
  # 
  # CONFIGURATION APPROACH:
  # Each program file contains comprehensive configuration examples that demonstrate
  # best practices for tool setup. Most configurations are commented out because:
  # 1. Home-manager modules don't exist for many tools yet
  # 2. Tools require static config files deployed separately
  # 3. Environment variables need to be set in environment.nix
  # 4. Some tools need manual shell integration
  #
  # ACTIVATION PROCESS:
  # To activate configurations:
  # 1. Uncomment desired program configurations
  # 2. Ensure corresponding packages are installed
  # 3. Deploy required config files via file-management.nix
  # 4. Set environment variables in environment.nix
  # 5. Add shell aliases/functions as needed
  #
  # TOOL COVERAGE:
  # This reference implementation covers 50+ tools across:
  # - Essential productivity tools (broot, mcfly, vivid)
  # - Development workflow tools (just, pre-commit, hyperfine, tokei)
  # - File operations (rsync, ouch)
  # - System monitoring (procs, bottom)
  # - Network tools (xh, doggo, gping)
  # - Development utilities (shfmt, sqlfluff, fx)
  # - File managers (yazi, lf)
  # - Container tools (docker, colima)
  # - Git alternatives (gitui)
  # - Language tools (rustup, bacon)
  # - Media processing (ffmpeg)
  # - Advanced editors (neovim)
  #
  # MAINTENANCE:
  # - Monitor home-manager for new module additions
  # - Update configurations as tools evolve
  # - Test configurations on both Darwin and NixOS
  # - Keep documentation current with implementation status
  # - Regular validation of environment variables and paths
  #
  # CUSTOMIZATION:
  # Each program file includes:
  # - Comprehensive configuration options
  # - Shell integration examples
  # - Platform-specific considerations
  # - Performance and security settings
  # - Integration with other tools
  # - TODO items for future improvements
}