# Title         : file-managers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/file-managers.nix
# ----------------------------------------------------------------------------
# Terminal file manager configurations for enhanced file navigation and management.
# This file provides programs/ configurations for file managers that have
# home-manager module support, with static configurations handled separately.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- Yazi File Manager Configuration ----------------------------------
    # Modern terminal file manager with async operations and image preview
    # Note: Yazi may not have full home-manager module support yet
    # This is a template for when/if home-manager support is added
    
    # yazi = {
    #   enable = true;
    #   
    #   # --- Core Configuration -------------------------------------------
    #   # Basic file manager behavior and appearance
    #   settings = {
    #     # --- Display Settings -----------------------------------------
    #     show_hidden = false; # Hide dotfiles by default (toggle with '.')
    #     show_symlink = true; # Show symbolic link indicators
    #     
    #     # --- Preview Configuration ------------------------------------
    #     preview = {
    #       image = true; # Enable image preview (requires supported terminal)
    #       video = false; # Disable video preview for performance
    #       max_width = 600; # Maximum preview width in pixels
    #       max_height = 900; # Maximum preview height in pixels
    #     };
    #     
    #     # --- Performance Settings ------------------------------------
    #     async_io = true; # Enable asynchronous I/O operations
    #     cache_size = "100MB"; # Cache size for file operations
    #   };
    #   
    #   # --- Key Bindings Configuration ---------------------------------
    #   # Custom key mappings for file operations
    #   keymap = {
    #     # Navigation keys
    #     "h" = "parent"; # Go to parent directory
    #     "l" = "enter"; # Enter directory or open file
    #     "j" = "down"; # Move down in list
    #     "k" = "up"; # Move up in list
    #     
    #     # File operations
    #     "dd" = "cut"; # Cut selected files
    #     "yy" = "copy"; # Copy selected files
    #     "pp" = "paste"; # Paste files
    #     "x" = "delete"; # Delete selected files
    #   };
    #   
    #   # --- Shell Integration ------------------------------------------
    #   enableZshIntegration = true; # Add shell functions for directory changing
    # };
    
    # --- Ranger File Manager Configuration --------------------------------
    # Feature-rich Python-based terminal file manager
    # Note: Ranger typically requires extensive static configuration
    # This shows the programs/ portion if home-manager support exists
    
    # ranger = {
    #   enable = true;
    #   
    #   # --- Core Configuration -------------------------------------------
    #   settings = {
    #     # --- Display Configuration -----------------------------------
    #     preview_files = true; # Enable file preview pane
    #     preview_directories = true; # Show directory contents in preview
    #     collapse_preview = true; # Collapse preview for small terminals
    #     
    #     # --- File Operations -----------------------------------------
    #     use_preview_script = true; # Use external preview scripts
    #     preview_images = true; # Enable image preview
    #     preview_images_method = "kitty"; # Image preview method
    #     
    #     # --- Interface Settings --------------------------------------
    #     draw_borders = true; # Draw borders around panes
    #     dirname_in_tabs = true; # Show directory name in tabs
    #     mouse_enabled = true; # Enable mouse support
    #     
    #     # --- Performance Settings -----------------------------------
    #     max_history_size = 20; # Maximum directory history
    #     max_console_history_size = 50; # Maximum command history
    #   };
    #   
    #   # --- Shell Integration ------------------------------------------
    #   enableZshIntegration = true; # Add 'ranger-cd' function to zsh
    # };
    
    # --- LF File Manager Configuration ------------------------------------
    # Lightweight and fast terminal file manager inspired by ranger
    # Note: LF may have limited home-manager support
    # Most configuration typically done via static config files
    
    # lf = {
    #   enable = true;
    #   
    #   # --- Core Configuration -------------------------------------------
    #   settings = {
    #     # --- Display Settings -----------------------------------------
    #     hidden = false; # Hide dotfiles by default
    #     preview = true; # Enable preview pane
    #     drawbox = true; # Draw boxes around panes
    #     icons = true; # Show file type icons
    #     
    #     # --- Behavior Settings ---------------------------------------
    #     ignorecase = true; # Case-insensitive search
    #     smartcase = true; # Smart case matching
    #     wrapscan = true; # Wrap search at end of list
    #     
    #     # --- Performance Settings -----------------------------------
    #     period = 10; # Update interval in seconds
    #     scrolloff = 10; # Keep cursor away from edges
    #   };
    #   
    #   # --- Commands Configuration ------------------------------------
    #   # Custom commands for file operations
    #   commands = {
    #     # Archive extraction
    #     extract = "ouch decompress \"$f\"";
    #     
    #     # Archive creation
    #     compress = "ouch compress \"$fx\" archive.tar.gz";
    #     
    #     # Git operations
    #     git_status = "git status";
    #     git_log = "git log --oneline";
    #   };
    #   
    #   # --- Shell Integration ------------------------------------------
    #   enableZshIntegration = true; # Add 'lfcd' function for directory changing
    # };
  };
  
  # --- Implementation Notes ----------------------------------------------
  # 
  # File Manager Configuration Strategy:
  # 
  # 1. Home-Manager Support Status:
  #    - Most terminal file managers have limited or no home-manager support
  #    - Configuration is typically done via static config files
  #    - This file provides templates for when/if support is added
  # 
  # 2. Current Implementation Approach:
  #    - Use static configuration files in configs/apps/ directory
  #    - Deploy configurations via file-management.nix
  #    - Set environment variables in environment.nix for XDG compliance
  # 
  # 3. Static Configuration Files Needed:
  #    - configs/apps/yazi.toml - Yazi configuration
  #    - configs/apps/ranger/rc.conf - Ranger configuration
  #    - configs/apps/lf/lfrc - LF configuration
  #    - configs/apps/nnn/nnnrc - NNN configuration (if used)
  # 
  # 4. Environment Variables Required:
  #    - YAZI_CONFIG_HOME - XDG config directory for Yazi
  #    - RANGER_LOAD_DEFAULT_RC - Control default config loading
  #    - LF_ICONS - Icon definitions for LF
  #    - NNN_OPTS - Options for NNN file manager
  # 
  # 5. Shell Integration:
  #    - All file managers need shell functions for directory changing
  #    - Functions typically named: yazi-cd, ranger-cd, lfcd, nnn-cd
  #    - Integration handled via shell configuration files
  # 
  # 6. Preview Dependencies:
  #    - Image preview: kitty, wezterm, or compatible terminal
  #    - Video preview: ffmpegthumbnailer, mediainfo
  #    - Document preview: pandoc, poppler-utils
  #    - Archive preview: ouch, tar, unzip
  # 
  # 7. Performance Considerations:
  #    - Image preview can be resource-intensive
  #    - Large directory scanning may be slow
  #    - Cache configuration important for responsiveness
  # 
  # 8. Platform Differences:
  #    - macOS: Different preview tools and file associations
  #    - Linux: More preview options and integration possibilities
  #    - Terminal compatibility varies by platform
  # 
  # 9. Integration with Other Tools:
  #    - Git integration for repository status
  #    - Archive tool integration (ouch, tar, zip)
  #    - Editor integration for file editing
  #    - Image viewer integration for media files
  # 
  # 10. Future Implementation:
  #     - Monitor home-manager for file manager module additions
  #     - Implement static configurations first
  #     - Migrate to programs/ configuration when available
  #     - Test integration with existing shell and editor configurations
}

# Template Usage Instructions:
# 
# 1. Check home-manager documentation for current file manager support
# 2. Uncomment and adapt relevant sections when support becomes available
# 3. Ensure corresponding packages are installed via packages/*.nix files
# 4. Create static configuration files in configs/apps/ directory
# 5. Add environment variables to environment.nix for XDG compliance
# 6. Deploy static configs via file-management.nix
# 7. Test shell integration and directory changing functionality
# 8. Verify preview functionality works with terminal emulator
# 9. Document any platform-specific requirements or limitations
# 10. Update this template as home-manager support evolves