# Title         : system-monitoring.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/system-monitoring.nix
# ----------------------------------------------------------------------------
# System monitoring tools: procs (modern ps replacement) and bottom (system monitor).
# These tools provide enhanced system visibility with modern interfaces, better
# performance, and more intuitive output formatting than traditional tools.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- Procs Process Monitor -----------------------------------------
    # Modern replacement for ps with better formatting and filtering capabilities
    # Provides colored output, tree view, and advanced process information
    # TODO: No home-manager module available - requires config file
    
    # procs = {
    #   enable = true;
    #   
    #   # --- Core Configuration --------------------------------------
    #   settings = {
    #     # --- Display Configuration ---------------------------
    #     # Default columns to display
    #     columns = [
    #       "pid"
    #       "user"
    #       "separator"
    #       "tty"
    #       "usage_cpu"
    #       "usage_mem"
    #       "separator"
    #       "state"
    #       "separator"
    #       "command"
    #     ];
    #     
    #     # --- Color Configuration -----------------------------
    #     # Color scheme for different process states
    #     color = {
    #       mode = "auto";      # auto, always, disable
    #       theme = "dark";     # dark, light, auto
    #     };
    #     
    #     # --- Tree View Settings ------------------------------
    #     # Process tree display options
    #     tree = {
    #       symbols = {
    #         vertical = "│";
    #         horizontal = "─";
    #         up_and_right = "└";
    #         vertical_and_right = "├";
    #       };
    #     };
    #     
    #     # --- Paging Configuration ----------------------------
    #     # Pager settings for long output
    #     pager = {
    #       mode = "auto";      # auto, always, disable
    #       command = "less -R"; # Pager command with color support
    #     };
    #     
    #     # --- Search and Filter Settings ----------------------
    #     # Default search behavior
    #     search = {
    #       case_sensitive = false;
    #       regex = false;
    #       negate = false;
    #     };
    #   };
    #   
    #   # --- Custom Themes -----------------------------------
    #   # Define custom color themes for different use cases
    #   themes = {
    #     parametric = {
    #       # Custom theme matching system colors
    #       colors = {
    #         header = "bold blue";
    #         process_running = "green";
    #         process_sleeping = "white";
    #         process_zombie = "red";
    #         cpu_high = "red";
    #         cpu_medium = "yellow";
    #         cpu_low = "green";
    #         memory_high = "red";
    #         memory_medium = "yellow";
    #         memory_low = "green";
    #       };
    #     };
    #   };
    #   
    #   # --- Shell Integration ----------------------------------
    #   # Create convenient aliases for common operations
    #   aliases = {
    #     "ps" = "procs";
    #     "pst" = "procs --tree";
    #     "psc" = "procs --sortd cpu";
    #     "psm" = "procs --sortd mem";
    #     "psu" = "procs --user $(whoami)";
    #   };
    # };

    # --- Bottom System Monitor ------------------------------------
    # Cross-platform system monitor with customizable interface
    # Provides real-time CPU, memory, disk, network, and process monitoring
    # TODO: No home-manager module available - requires config file
    
    # bottom = {
    #   enable = true;
    #   
    #   # --- Core Configuration --------------------------------------
    #   settings = {
    #     # --- General Settings --------------------------------
    #     # Basic application behavior
    #     flags = {
    #       hide_avg_cpu = false;
    #       dot_marker = false;
    #       temperature_type = "celsius";
    #       rate = 1000;  # Update rate in milliseconds
    #       left_legend = false;
    #       current_usage = false;
    #       group_processes = false;
    #       case_sensitive = false;
    #       whole_word = false;
    #       regex = false;
    #       basic = false;
    #       default_time_value = 60000;  # Default time range (60 seconds)
    #       time_delta = 15000;  # Time delta for zoom (15 seconds)
    #       hide_time = false;
    #       autohide_time = false;
    #     };
    #     
    #     # --- Color Configuration -----------------------------
    #     # Color scheme for the interface
    #     colors = {
    #       table_header_color = "LightBlue";
    #       all_cpu_color = "Red";
    #       avg_cpu_color = "Green";
    #       cpu_core_colors = [
    #         "LightMagenta"
    #         "LightYellow" 
    #         "LightCyan"
    #         "LightGreen"
    #         "LightBlue"
    #         "LightRed"
    #       ];
    #       ram_color = "LightMagenta";
    #       swap_color = "LightYellow";
    #       arc_color = "LightCyan";
    #       gpu_core_colors = [
    #         "LightGreen"
    #         "LightBlue"
    #         "LightRed"
    #         "LightCyan"
    #       ];
    #       rx_color = "LightCyan";
    #       tx_color = "LightGreen";
    #       widget_title_color = "Gray";
    #       border_color = "Gray";
    #       highlighted_border_color = "LightBlue";
    #       text_color = "Gray";
    #       selected_text_color = "Black";
    #       selected_bg_color = "LightBlue";
    #       high_battery_color = "green";
    #       medium_battery_color = "yellow";
    #       low_battery_color = "red";
    #     };
    #     
    #     # --- Layout Configuration ----------------------------
    #     # Widget layout and positioning
    #     row = [
    #       {
    #         ratio = 30;
    #         child = [
    #           { type = "cpu"; }
    #         ];
    #       }
    #       {
    #         ratio = 40;
    #         child = [
    #           {
    #             ratio = 50;
    #             child = [
    #               { type = "mem"; }
    #             ];
    #           }
    #           {
    #             ratio = 50;
    #             child = [
    #               { type = "net"; }
    #             ];
    #           }
    #         ];
    #       }
    #       {
    #         ratio = 30;
    #         child = [
    #           { type = "proc"; default = true; }
    #         ];
    #       }
    #     ];
    #     
    #     # --- Disk Configuration ------------------------------
    #     # Disk monitoring settings
    #     disk_filter = {
    #       is_list_ignored = true;
    #       list = [
    #         "/dev/loop"
    #         "/snap"
    #       ];
    #       regex = true;
    #       case_sensitive = false;
    #       whole_word = false;
    #     };
    #     
    #     # --- Temperature Configuration -----------------------
    #     # Temperature sensor settings
    #     temp_filter = {
    #       is_list_ignored = true;
    #       list = [
    #         "cpu_thermal"
    #         "wifi"
    #       ];
    #       regex = false;
    #       case_sensitive = false;
    #       whole_word = false;
    #     };
    #   };
    #   
    #   # --- Key Bindings ------------------------------------
    #   # Custom key bindings for navigation and control
    #   keyBindings = {
    #     # Navigation
    #     up_key = "k";
    #     down_key = "j";
    #     left_key = "h";
    #     right_key = "l";
    #     
    #     # Process control
    #     kill_key = "dd";
    #     quit_key = "q";
    #     
    #     # View control
    #     help_key = "?";
    #     search_key = "/";
    #     filter_key = "f";
    #     
    #     # Time control
    #     zoom_in_key = "+";
    #     zoom_out_key = "-";
    #     reset_zoom_key = "=";
    #   };
    # };
  };

  # --- Environment Variables for Manual Configuration -------------------
  # These environment variables configure the tools until home-manager modules
  # are available. They should be moved to environment.nix in actual implementation.
  
  # Procs configuration (XDG compliant)
  # PROCS_CONFIG = "${config.xdg.configHome}/procs/config.toml";
  
  # Bottom configuration (XDG compliant)
  # BOTTOM_CONFIG_PATH = "${config.xdg.configHome}/bottom/bottom.toml";
  
  # --- Integration Notes -----------------------------------------------
  # 1. Procs requires config.toml in configs/system/procs/config.toml
  # 2. Bottom requires bottom.toml in configs/system/bottom/bottom.toml
  # 3. Both tools support custom themes and color schemes
  # 4. Shell aliases provide convenient shortcuts for common operations
  # 5. Package dependencies: procs, bottom in packages/sysadmin.nix
  # 6. Consider integration with system monitoring automation
  
  # --- Shell Aliases for Manual Configuration -------------------------
  # These aliases provide convenient shortcuts until programs modules are available
  
  # Procs aliases
  # alias ps='procs'
  # alias pst='procs --tree'
  # alias psc='procs --sortd cpu'
  # alias psm='procs --sortd mem'
  # alias psu='procs --user $(whoami)'
  # alias psk='procs --keyword'
  
  # Bottom aliases
  # alias btm='bottom'
  # alias htop='bottom'  # Replace htop with bottom
  # alias top='bottom'   # Replace top with bottom
  
  # --- TODO: Future Improvements --------------------------------------
  # 1. Create custom themes matching system color scheme
  # 2. Integrate with system alerting and monitoring automation
  # 3. Add configuration profiles for different monitoring scenarios
  # 4. Create wrapper scripts for common monitoring tasks
  # 5. Integrate with logging and metrics collection systems
  # 6. Add support for remote system monitoring
  # 7. Consider integration with container and service monitoring
  
  # --- Usage Examples ------------------------------------------------
  # Common usage patterns for these tools:
  
  # Procs examples:
  # procs                          # List all processes
  # procs --tree                   # Show process tree
  # procs --sortd cpu              # Sort by CPU usage
  # procs --user $(whoami)         # Show only user processes
  # procs firefox                  # Search for firefox processes
  # procs --or --uid 0 --ppid 1    # Complex filtering
  
  # Bottom examples:
  # bottom                         # Start system monitor
  # bottom --basic                 # Basic mode (less resource intensive)
  # bottom --rate 2000             # Update every 2 seconds
  # bottom --celsius               # Show temperature in Celsius
  # bottom --group                 # Group processes by name
}