# Title         : essential-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/essential-tools.nix
# ----------------------------------------------------------------------------
# Essential navigation and productivity tools: broot (directory navigator) and
# mcfly (shell history search). These tools enhance daily workflow efficiency
# with smart directory navigation and intelligent command history management.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- Broot Directory Navigator ----------------------------------------
    # Interactive directory tree navigator with fuzzy search and file operations
    # Provides a visual tree interface for navigating complex directory structures
    # TODO: Implement when home-manager adds broot module support
    # Currently requires manual configuration via configs/navigation/broot/
    
    # broot = {
    #   enable = true;
    #   
    #   # --- Core Navigation Settings ------------------------------------
    #   settings = {
    #     # Default view configuration
    #     default_flags = "h";  # Show hidden files by default
    #     
    #     # --- File Operations -----------------------------------------
    #     # Enable file operations (copy, move, delete)
    #     show_selection_mark = true;
    #     
    #     # --- Search Configuration ------------------------------------
    #     # Fuzzy search settings for file and directory matching
    #     content_search_max_file_size = "10MB";
    #     
    #     # --- Integration Settings ------------------------------------
    #     # Shell integration for directory changes
    #     modal = false;  # Non-modal interface for better workflow
    #   };
    #   
    #   # --- Custom Verbs (Commands) -----------------------------------
    #   # Define custom commands for file operations
    #   verbs = [
    #     {
    #       invocation = "edit";
    #       key = "F4";
    #       execution = "$EDITOR {file}";
    #       apply_to = "file";
    #     }
    #     {
    #       invocation = "create {subpath}";
    #       execution = "$EDITOR {directory}/{subpath}";
    #       apply_to = "directory";
    #     }
    #   ];
    #   
    #   # --- Shell Integration ----------------------------------------
    #   enableBashIntegration = true;
    #   enableZshIntegration = true;
    #   enableFishIntegration = true;
    # };

    # --- McFly Shell History Search ------------------------------------
    # Intelligent shell history search with context-aware suggestions
    # Replaces Ctrl-R with a more powerful history search interface
    # TODO: Implement when home-manager adds mcfly module support
    # Currently requires manual shell integration and environment variables
    
    # mcfly = {
    #   enable = true;
    #   
    #   # --- Search Configuration ------------------------------------
    #   # Fuzzy search factor (0 = exact match, 2 = very fuzzy)
    #   fuzzy = 2;
    #   
    #   # --- Interface Settings --------------------------------------
    #   # Number of results to display
    #   results = 50;
    #   
    #   # Interface position (TOP or BOTTOM)
    #   interfaceView = "BOTTOM";
    #   
    #   # Key binding scheme (emacs or vim)
    #   keyScheme = "emacs";
    #   
    #   # --- Display Options -----------------------------------------
    #   # Disable the selection menu for faster navigation
    #   disableMenu = false;
    #   
    #   # Light mode for light terminal themes
    #   lightMode = false;
    #   
    #   # --- History Management --------------------------------------
    #   # Maximum number of history entries to maintain
    #   historyLimit = 10000;
    #   
    #   # Sort order for search results
    #   resultsSort = "LAST_RUN";
    #   
    #   # --- Shell Integration --------------------------------------
    #   enableBashIntegration = true;
    #   enableZshIntegration = true;
    #   enableFishIntegration = true;
    # };
  };

  # --- Environment Variables for Manual Configuration -------------------
  # These environment variables configure the tools until home-manager modules
  # are available. They should be moved to environment.nix in actual implementation.
  
  # Broot configuration directory (XDG compliant)
  # BR_INSTALL = "${config.xdg.configHome}/broot";
  # BROOT_CONFIG_DIR = "${config.xdg.configHome}/broot";
  
  # McFly configuration (XDG compliant data directory)
  # MCFLY_KEY_SCHEME = "emacs";
  # MCFLY_FUZZY = "2";
  # MCFLY_RESULTS = "50";
  # MCFLY_RESULTS_SORT = "LAST_RUN";
  # MCFLY_INTERFACE_VIEW = "BOTTOM";
  # MCFLY_DISABLE_MENU = "FALSE";
  # MCFLY_LIGHT = "FALSE";
  # MCFLY_HISTORY_LIMIT = "10000";
  
  # --- Integration Notes -----------------------------------------------
  # 1. Broot requires config files in configs/navigation/broot/conf.hjson
  # 2. McFly database stored in $XDG_DATA_HOME/mcfly/history.db
  # 3. Both tools require shell integration scripts for optimal functionality
  # 4. File management entries needed for broot config deployment
  # 5. Package dependencies: broot, mcfly in packages/core.nix or similar
  
  # --- TODO: Future Improvements --------------------------------------
  # 1. Monitor home-manager for native module support
  # 2. Create comprehensive broot verb definitions for file operations
  # 3. Integrate with existing git workflow tools
  # 4. Add custom themes for both tools matching system color scheme
  # 5. Consider integration with other file managers (yazi, lf)
}