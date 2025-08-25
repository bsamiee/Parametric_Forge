# Title         : shell-enhancements.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/shell-enhancements.nix
# ----------------------------------------------------------------------------
# Shell enhancement tools for improved command-line productivity and user experience.
# This file provides fully commented configuration examples for shell tools that
# enhance navigation, history, and visual feedback in terminal environments.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- Smart Shell History with Neural Network Ranking -----------------
    # mcfly provides intelligent command history search using machine learning
    # to rank commands based on usage patterns, directory context, and recency
    mcfly = {
      enable = true;
      
      # --- Core Configuration ---------------------------------------------
      # Key binding for history search (default: Ctrl+R)
      keyScheme = "vim"; # Options: "emacs" (default), "vim"
      
      # --- Neural Network Settings ---------------------------------------
      # Configure the machine learning aspects of command ranking
      fuzzy = true; # Enable fuzzy matching for command search
      
      # --- Interface Configuration ---------------------------------------
      # Customize the search interface appearance and behavior
      interfaceView = "TOP"; # Options: "TOP", "BOTTOM"
      results = 10; # Number of results to show (default: 10)
      
      # --- Integration Settings -------------------------------------------
      # Shell integration and environment setup
      enableZshIntegration = true; # Automatically integrate with zsh
      enableBashIntegration = true; # Also support bash if needed
      
      # --- Privacy and Data Settings ------------------------------------
      # Control data collection and storage behavior
      # McFly stores command history locally with privacy-focused defaults
    };
    
    # --- Interactive File Tree Explorer -----------------------------------
    # broot provides a tree-view file navigator with search and navigation
    # Note: This is a partial programs/ configuration - also needs configs/
    broot = {
      enable = true;
      
      # --- Core Navigation Settings --------------------------------------
      # Configure basic navigation and display behavior
      enableZshIntegration = true; # Add 'br' command to zsh
      enableBashIntegration = true; # Also support bash
      
      # --- Modal Configuration -------------------------------------------
      # broot operates in different modes for different tasks
      modal = true; # Enable modal interface (recommended)
      
      # --- Integration with Other Tools -----------------------------------
      # Configure how broot interacts with other system tools
      settings = {
        # --- Display Configuration ------------------------------------
        show_hidden = false; # Hide dotfiles by default (toggle with 'h')
        show_dates = true; # Show file modification dates
        show_sizes = true; # Show file sizes in tree view
        show_git_info = true; # Show git status indicators
        
        # --- Search Configuration -------------------------------------
        content_search_max_file_size = "10MB"; # Limit for content search
        
        # --- Performance Settings ------------------------------------
        max_panels_count = 2; # Maximum number of panels (default: 2)
        
        # --- Color and Theme Configuration ----------------------------
        # Colors are configured via the static config file in configs/
        # This programs/ config handles behavioral settings only
        
        # --- Keyboard Shortcuts Configuration ------------------------
        # Custom key bindings are defined in the static config file
        # This ensures complex key mappings are properly maintained
      };
    };
  };
  
  # --- Environment Variable Integration ------------------------------------
  # These tools integrate with environment variables defined in environment.nix
  # for XDG compliance and enhanced functionality
  
  # McFly Configuration:
  # - MCFLY_KEY_SCHEME: Set via programs.mcfly.keyScheme above
  # - MCFLY_FUZZY: Set via programs.mcfly.fuzzy above
  # - MCFLY_RESULTS: Set via programs.mcfly.results above
  # - MCFLY_INTERFACE_VIEW: Set via programs.mcfly.interfaceView above
  
  # Broot Configuration:
  # - BR_INSTALL: Handled automatically by home-manager
  # - Additional environment variables set in environment.nix for XDG compliance
}

# Implementation Notes:
# 
# 1. McFly Integration:
#    - Automatically replaces default Ctrl+R history search
#    - Learns from usage patterns to improve command suggestions
#    - Stores data in XDG-compliant directories
#    - No additional static configuration files needed
# 
# 2. Broot Integration:
#    - Requires additional static configuration in configs/apps/broot.hjson
#    - The 'br' command provides cd functionality after navigation
#    - Complex key bindings and themes handled via static config
#    - Integrates with git status and file type detection
# 
# 3. Shell Integration:
#    - Both tools automatically integrate with zsh via home-manager
#    - Shell completion and key bindings are handled automatically
#    - Environment variables are set automatically by home-manager
# 
# 4. XDG Compliance:
#    - McFly: Stores data in $XDG_DATA_HOME/mcfly/
#    - Broot: Config in $XDG_CONFIG_HOME/broot/, data in $XDG_DATA_HOME/broot/
#    - Both tools respect XDG Base Directory specification
# 
# 5. Performance Considerations:
#    - McFly has minimal impact on shell startup time
#    - Broot tree scanning is optimized for large directories
#    - Both tools cache data for improved performance
# 
# 6. Platform Compatibility:
#    - Both tools work identically on macOS and Linux
#    - No platform-specific configuration needed
#    - File system differences handled automatically
# 
# 7. Future Enhancements:
#    - TODO: Consider adding custom McFly training data
#    - TODO: Evaluate broot plugin system for additional functionality
#    - TODO: Add integration with other file managers if needed