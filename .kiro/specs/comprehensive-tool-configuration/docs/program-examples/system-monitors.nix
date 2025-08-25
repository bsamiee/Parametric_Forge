# Title         : system-monitors.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/system-monitors.nix
# ----------------------------------------------------------------------------
# System monitoring and process management tools for enhanced system visibility
# and resource monitoring. This file provides programs/ configurations for
# monitoring tools that have home-manager module support.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- Bottom System Monitor Configuration ------------------------------
    # Modern system monitor with graphs and customizable interface (btm command)
    # Note: Bottom may have limited home-manager support
    # Most configuration done via static config files
    
    # bottom = {
    #   enable = true;
    #   
    #   # --- Display Configuration ---------------------------------------
    #   settings = {
    #     # --- Interface Layout ---------------------------------------
    #     default_widget_type = "proc"; # Default widget: proc, cpu, mem, net, disk, temp
    #     default_widget_count = 1; # Number of widgets to show initially
    #     
    #     # --- Update and Refresh Settings ----------------------------
    #     rate = 1000; # Update rate in milliseconds (1 second)
    #     left_legend = true; # Show legend on left side
    #     
    #     # --- Process Display Settings -------------------------------
    #     tree_mode = false; # Show processes in tree mode by default
    #     show_table_scroll_position = true; # Show scroll position
    #     process_command = false; # Show full command by default
    #     
    #     # --- CPU Configuration -------------------------------------
    #     cpu_left_legend = true; # Show CPU legend on left
    #     
    #     # --- Memory Configuration -----------------------------------
    #     mem_as_value = false; # Show memory as percentage by default
    #     
    #     # --- Network Configuration ---------------------------------
    #     use_old_network_legend = false; # Use new network legend format
    #     network_use_binary_prefix = false; # Use decimal prefixes (MB vs MiB)
    #     network_use_bytes = false; # Show network in bits by default
    #     
    #     # --- Temperature Configuration ------------------------------
    #     temperature_type = "celsius"; # Temperature unit: celsius, fahrenheit, kelvin
    #     
    #     # --- Disk Configuration ------------------------------------
    #     disk_filter = null; # No disk filtering by default
    #     mount_filter = null; # No mount point filtering
    #   };
    #   
    #   # --- Color Configuration ------------------------------------
    #   # Colors are typically configured via static config file
    #   # This allows for complex theme definitions
    # };
    
    # --- Procs Process Viewer Configuration ------------------------------
    # Modern process viewer with tree view, search, and color (ps replacement)
    # Note: Procs typically doesn't have home-manager module support
    # Configuration is done via static config files and environment variables
    
    # procs configuration is handled through:
    # 1. Static config file: configs/system/procs.toml
    # 2. Environment variables for default options
    # 3. Shell aliases for common usage patterns
    
    # --- Dust Directory Analyzer Configuration ---------------------------
    # Directory size analyzer with tree view (du replacement)
    # Note: Dust typically doesn't have home-manager module support
    # Configuration is minimal and done via command-line options
    
    # dust configuration is handled through:
    # 1. Environment variables for default options
    # 2. Shell aliases for common usage patterns
    # 3. Optional static config for complex filtering rules
    
    # --- DUF Disk Usage Configuration ------------------------------------
    # Disk usage viewer with visual bars and colors (df replacement)
    # Note: DUF typically doesn't have home-manager module support
    # Configuration is done via environment variables and command-line options
    
    # duf configuration is handled through:
    # 1. Environment variables for default display options
    # 2. Shell aliases for different view modes
    # 3. Optional static config for custom themes
  };
  
  # --- System Monitor Environment Integration -----------------------------
  # These tools are primarily configured through environment variables
  # and static configuration files rather than home-manager programs
  
  # Environment variables for system monitors (set in environment.nix):
  # 
  # Bottom Configuration:
  # - BOTTOM_CONFIG_DIR: XDG config directory for bottom
  # - BOTTOM_DEFAULT_OPTS: Default command-line options
  # 
  # Procs Configuration:
  # - PROCS_CONFIG_DIR: XDG config directory for procs
  # - PROCS_DEFAULT_COLUMNS: Default columns to display
  # - PROCS_COLOR: Enable colored output
  # 
  # Dust Configuration:
  # - DUST_DEFAULT_OPTS: Default options for directory analysis
  # - DUST_IGNORE_HIDDEN: Ignore hidden files by default
  # 
  # DUF Configuration:
  # - DUF_DEFAULT_OPTS: Default display options
  # - DUF_THEME: Color theme for disk usage display
  
  # --- Shell Integration and Aliases --------------------------------------
  # System monitoring tools benefit from shell aliases for common operations
  
  # Example aliases that would be defined in shell configuration:
  # 
  # Bottom Aliases:
  # - btm: bottom (default alias)
  # - btmcpu: bottom --default_widget_type cpu
  # - btmmem: bottom --default_widget_type mem
  # - btmnet: bottom --default_widget_type net
  # - btmdisk: bottom --default_widget_type disk
  # 
  # Procs Aliases:
  # - ps: procs (replace traditional ps)
  # - pst: procs --tree (tree view)
  # - psc: procs --color always (force colors)
  # - psw: procs --watch (watch mode)
  # 
  # Dust Aliases:
  # - du: dust (replace traditional du)
  # - dus: dust --reverse (sort by size)
  # - dut: dust --depth 3 (limit depth)
  # - duh: dust --apparent-size (apparent size)
  # 
  # DUF Aliases:
  # - df: duf (replace traditional df)
  # - dfa: duf --all (show all filesystems)
  # - dfj: duf --json (JSON output)
  # - dft: duf --theme dark (dark theme)
}

# Implementation Notes:
# 
# 1. System Monitor Configuration Strategy:
#    - Most system monitors have limited or no home-manager support
#    - Configuration is primarily through static files and environment variables
#    - Shell aliases are crucial for usability and muscle memory
# 
# 2. Static Configuration Files Needed:
#    - configs/system/bottom.toml - Bottom system monitor configuration
#    - configs/system/procs.toml - Procs process viewer configuration
#    - configs/system/dust.toml - Dust directory analyzer configuration (if supported)
#    - configs/system/duf.yaml - DUF disk usage configuration (if supported)
# 
# 3. Environment Variable Requirements:
#    - XDG compliance for config and cache directories
#    - Default options for consistent behavior
#    - Color and theme settings for visual consistency
#    - Performance tuning options for large systems
# 
# 4. Shell Integration Requirements:
#    - Aliases to replace traditional Unix tools (ps, du, df, top)
#    - Functions for complex monitoring workflows
#    - Completion integration where available
#    - Integration with other system tools
# 
# 5. Performance Considerations:
#    - Update rates should balance responsiveness with CPU usage
#    - Large process lists may require filtering or pagination
#    - Network monitoring can be resource-intensive
#    - Disk scanning should respect system load
# 
# 6. Platform Differences:
#    - macOS: Different process information and system APIs
#    - Linux: More detailed system information available
#    - Temperature monitoring varies by platform
#    - Disk information format differences
# 
# 7. Integration with Other Tools:
#    - Process monitoring integrates with kill, killall commands
#    - Disk monitoring integrates with file managers
#    - Network monitoring integrates with network diagnostic tools
#    - System monitoring integrates with alerting and logging
# 
# 8. Security Considerations:
#    - Process information may contain sensitive data
#    - Network monitoring may reveal internal network structure
#    - Disk usage may expose directory structures
#    - Consider privacy implications of monitoring data
# 
# 9. Accessibility Features:
#    - Color schemes for color-blind users
#    - High contrast themes for visibility
#    - Keyboard navigation for screen readers
#    - Text-based output modes for automation
# 
# 10. Future Enhancements:
#     - TODO: Create custom bottom layouts for different use cases
#     - TODO: Develop procs column configurations for different workflows
#     - TODO: Integrate system monitors with alerting systems
#     - TODO: Create monitoring dashboards for development environments
# 
# 11. Troubleshooting Integration:
#     - System monitors should integrate with logging systems
#     - Process information should link to debugging tools
#     - Resource usage should correlate with performance metrics
#     - Historical data should be available for trend analysis
# 
# 12. Documentation Requirements:
#     - Document common monitoring workflows and patterns
#     - Provide troubleshooting guides for performance issues
#     - Create reference guides for system monitor features
#     - Document integration with other development tools