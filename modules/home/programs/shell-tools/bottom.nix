{theme, ...}: let
  inherit (theme) roles palette;
in {
  programs.bottom = {
    enable = true;
    settings = {
      # --- [GENERAL_FLAGS]
      flags = {
        rate = 2000;
        table_gap = "none";
        show_table_scroll_position = true;
        disable_gpu = true;
        retention = "5m";
        battery = true;
      };

      # --- [STYLE_CONFIGURATION]
      styles = {
        widgets = {
          border_color = roles.focus.inactive.hex;
          selected_border_color = roles.focus.active.hex;
          widget_title = {
            color = roles.accent.primary.hex;
          };
          text = {
            color = roles.text.primary.hex;
          };
          selected_text = {
            color = roles.text.inverse.hex;
            bg_color = roles.focus.active.hex;
          };
          disabled_text = {
            color = roles.text.muted.hex;
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
          };
        };
        cpu = {
          all_entry_color = roles.accent.primary.hex;
          avg_entry_color = roles.accent.tertiary.hex;
          cpu_core_colors = [
            palette.green.hex
            palette.cyan.hex
            palette.yellow.hex
            palette.orange.hex
            palette.pink.hex
            palette.purple.hex
            palette.red.hex
            palette.magenta.hex
          ];
        };
        memory = {
          ram_color = roles.state.success.hex;
          swap_color = roles.state.attention.hex;
        };
        network = {
          rx_color = roles.state.success.hex;
          tx_color = roles.accent.tertiary.hex;
          rx_total_color = roles.accent.primary.hex;
          tx_total_color = roles.state.attention.hex;
        };
        battery = {
          high_battery_color = roles.state.success.hex;
          medium_battery_color = roles.state.warning.hex;
          low_battery_color = roles.state.danger.hex;
        };
      };
      # --- [PROCESS_CONFIGURATION]
      processes = {
        current_usage = true;
        default_grouped = true;
        default_memory_value = true;
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
        name_filter.list = ["devfs"];
        mount_filter = {
          list = ["^/System/Volumes/(VM|Preboot|Update|xarts|iSCPreboot|Hardware)$" "^/Volumes/Recovery$"];
          regex = true;
        };
      };
      # --- [NETWORK_GRAPH]
      network_graph = {
        use_binary_prefix = true;
        interface_filter = {
          list = ["lo0" "utun.*" "awdl0" "llw0" "anpi.*" "bridge.*" "ap1"];
          regex = true;
          whole_word = true;
        };
      };
    };
  };
}
