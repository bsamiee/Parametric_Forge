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
  inherit (config.forge.theme) roles;
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
          style.fg = roles.accent.primary.hex;
        };
        row = {
          selected_symbol = "❯";
          even.fg = roles.text.primary.hex;
          # Subtle zebra striping against the raised surface.
          odd = {
            fg = roles.text.primary.hex;
            bg = roles.surface.raised.hex;
          };
          # Selection rides the focus fill with inverse text, matching every estate picker.
          selected = {
            fg = roles.text.inverse.hex;
            bg = roles.focus.active.hex;
            add_modifier = "BOLD";
          };
        };
        cell.highlighted = {
          fg = roles.state.success.hex;
          bg = roles.surface.base.hex;
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
          style.fg = roles.accent.secondary.hex;
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
        fg = roles.text.primary.hex;
        bg = roles.accent.secondary.hex;
        add_modifier = "REVERSED";
      };
      popups = {
        # Selection rides the focus fill with inverse text.
        selected_row = {
          fg = roles.text.inverse.hex;
          bg = roles.focus.active.hex;
        };
        primary.fg = roles.accent.primary.hex;
        border = {
          type = "rounded";
          style.fg = roles.state.attention.hex;
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
