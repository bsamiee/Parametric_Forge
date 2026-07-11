# Title         : bottom.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/bottom.nix
# ----------------------------------------------------------------------------
# Resource monitor themed from the estate palette owner
{config, ...}: let
  # palette retained for the categorical per-core / per-GPU rainbows — a chromatic spectrum wants stable distinct hues, not semantic roles.
  inherit (config.forge.theme) roles palette;
in {
  programs.bottom = {
    enable = true;
    settings = {
      # --- [GENERAL_FLAGS]
      flags = {
        # Display Performance
        temperature_type = "c";
        rate = 2000;
        table_gap = "none";
        disable_click = false;
        show_table_scroll_position = true;
        disable_gpu = true;

        # Data & Performance
        retention = "5m";
        time_delta = 15000;

        # Initial View
        default_widget_type = "process";
        default_widget_count = 1;
        expanded = false;
        basic = false;
        use_old_network_legend = false;
        battery = true;
      };

      # --- [STYLE_CONFIGURATION]
      styles = {
        widgets = {
          # Focus pair owns the widget-frame active/inactive derivation: the selected frame reads focus.active, every other frame reads inactive.
          border_color = roles.focus.inactive.hex;
          selected_border_color = roles.focus.active.hex;
          widget_title = {
            color = roles.accent.primary.hex;
          };
          table_header = {
            color = roles.accent.primary.hex;
            bold = true;
          };
          text = {
            color = roles.text.primary.hex;
          };
          # Selection rides the focus fill with inverse text.
          selected_text = {
            color = roles.text.inverse.hex;
            bg_color = roles.focus.active.hex;
          };
          disabled_text = {
            color = roles.text.muted.hex;
          };
          thread_text = {
            color = roles.accent.structural.hex;
            bold = false;
          };
        };
        tables = {
          headers = {
            color = roles.accent.primary.hex;
            bold = true;
          };
        };
        graphs = {
          graph_color = roles.surface.selected.hex;
          legend_text = {
            color = roles.accent.primary.hex;
            bold = false;
          };
        };
        cpu = {
          all_entry_color = roles.accent.primary.hex;
          avg_entry_color = roles.accent.tertiary.hex;
          cpu_core_colors = [
            palette.green.hex # Core 0
            palette.cyan.hex # Core 1
            palette.yellow.hex # Core 2
            palette.orange.hex # Core 3
            palette.pink.hex # Core 4
            palette.purple.hex # Core 5
            palette.red.hex # Core 6
            palette.magenta.hex # Core 7+
          ];
        };
        memory = {
          ram = roles.state.success.hex;
          swap = roles.state.attention.hex;
          cache = roles.accent.primary.hex;
          arc = roles.accent.structural.hex;
          gpu_colors = [
            palette.pink.hex # GPU 0
            palette.cyan.hex # GPU 1
            palette.green.hex # GPU 2
            palette.orange.hex # GPU 3
          ];
        };
        network = {
          rx = roles.state.success.hex;
          tx = roles.accent.tertiary.hex;
          rx_total = roles.accent.primary.hex;
          tx_total = roles.state.attention.hex;
        };
        battery = {
          high_battery = roles.state.success.hex; # Healthy (50%+)
          medium_battery = roles.state.warning.hex; # Caution (10-50%) — warning role (amber)
          low_battery = roles.state.danger.hex; # Critical (<10%)
        };
      };
      # --- [PROCESS_CONFIGURATION]
      processes = {
        current_usage = true;
        default_grouped = true;
        default_tree = false;
        default_memory_value = true;
        case_sensitive = false;
        whole_word = false;
        regex = false;
        process_command = false;
        disable_advanced_kill = false;
        columns = [
          "PID"
          "Name"
          "CPU%"
          "Mem%"
          "User"
          "State"
        ];
      };
      # --- [DISK_CONFIGURATION]
      disk = {
        columns = ["Disk" "Mount" "Used%" "Free" "R/s" "W/s"];
        name_filter = {
          is_list_ignored = true;
          list = ["/dev/loop*" "devfs" "devtmpfs" "tmpfs" "overlay" "run"];
          regex = true;
          case_sensitive = false;
          whole_word = false;
        };
        mount_filter = {
          is_list_ignored = true;
          list = ["/boot" "/boot/efi" "/var/snap" "/var/lib/docker"];
          regex = false;
          case_sensitive = false;
          whole_word = false;
        };
      };
      # --- [TEMPERATURE_CONFIGURATION]
      # macOS withholds temperature sensors from bottom.
      temperature = {
        sensor_filter = {
          is_list_ignored = true;
          list = [];
          regex = false;
          case_sensitive = false;
          whole_word = false;
        };
      };
      # --- [MEMORY_GRAPH_CONFIGURATION]
      memory_graph = {
        cache_memory = true;
      };
      # --- [NETWORK_GRAPH]
      network_graph = {
        use_binary_prefix = true;
        use_bytes = false;
        use_log = false;
        interface_filter = {
          is_list_ignored = true;
          list = ["lo" "lo0"];
          regex = false;
          case_sensitive = false;
          whole_word = true;
        };
      };
      # --- [CPU_CONFIGURATION]
      cpu = {
        default = "all";
        hide_avg_cpu = false;
        left_legend = false;
      };
    };
  };
}
