# Title         : pik.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/pik.nix
# ----------------------------------------------------------------------------
# pik (Process Interactive Kill): fuzzy process finder and killer; config is generator-owned and lands where pik resolves it per OS —
# ~/Library/Application Support on macOS, $XDG_CONFIG_HOME/pik on Linux.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette;
  toml = pkgs.formats.toml {};
  configToml = toml.generate "pik-config.toml" {
    screen_size = "fullscreen";
    ignore = {
      threads = true;
      other_users = false;
      # macOS system trees, systemd services, and kernel worker classes.
      paths = [
        "^/System/.*"
        "^/usr/libexec/.*"
        "^/nix/store/.*/systemd.*"
        ".*kworker.*"
        ".*ksoftirqd.*"
      ];
    };
    ui = {
      icons = "nerd_font_v3";
      process_table = {
        title = {
          alignment = "center";
          position = "top";
        };
        border = {
          type = "rounded";
          style.fg = palette.cyan.hex;
        };
        row = {
          selected_symbol = "▶";
          even.fg = palette.foreground.hex;
          # Subtle zebra striping against the current-line surface.
          odd = {
            fg = palette.foreground.hex;
            bg = palette.current_line.hex;
          };
          selected = {
            fg = palette.background.hex;
            bg = palette.cyan.hex;
            add_modifier = "BOLD";
          };
        };
        cell.highlighted = {
          fg = palette.green.hex;
          bg = palette.background.hex;
        };
        scrollbar = {
          track_symbol = "│";
          thumb_symbol = "█";
          begin_symbol = "▲";
          end_symbol = "▼";
          margin = {
            horizontal = 0;
            vertical = 1;
          };
        };
      };
      process_details = {
        title = {
          alignment = "center";
          position = "top";
        };
        border = {
          type = "rounded";
          style.fg = palette.magenta.hex;
        };
        scrollbar = {
          track_symbol = "│";
          thumb_symbol = "█";
          begin_symbol = "▲";
          end_symbol = "▼";
          margin = {
            horizontal = 0;
            vertical = 1;
          };
        };
      };
      search_bar.cursor_style = {
        fg = palette.foreground.hex;
        bg = palette.magenta.hex;
        add_modifier = "REVERSED";
      };
      popups = {
        selected_row = {
          fg = palette.selection.hex;
          bg = palette.cyan.hex;
        };
        primary.fg = palette.cyan.hex;
        border = {
          type = "rounded";
          style.fg = palette.orange.hex;
        };
      };
    };
  };
in {
  home.packages = [pkgs.pik];

  home.file = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    "Library/Application Support/pik/config.toml".source = configToml;
  };
  xdg.configFile = lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
    "pik/config.toml".source = configToml;
  };
}
