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
  inherit (config.estate.theme) roles;
  toml = pkgs.formats.toml {};
  scrollbar = {
    thumb_symbol = "█";
    begin_symbol = "▲";
    end_symbol = "▼";
  };
  # pik merges this file over its embedded default table by table, so a row here differs from that default.
  configToml = toml.generate "pik-config.toml" {
    screen_size = "fullscreen";
    ignore = {
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
        inherit scrollbar;
        title.alignment = "center";
        border.style.fg = roles.accent.primary.hex;
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
      };
      process_details = {
        inherit scrollbar;
        title.alignment = "center";
        border.style.fg = roles.accent.secondary.hex;
      };
      search_bar.cursor_style = {
        fg = roles.text.primary.hex;
        bg = roles.accent.secondary.hex;
      };
      popups = {
        # Selection rides the focus fill with inverse text.
        selected_row = {
          fg = roles.text.inverse.hex;
          bg = roles.focus.active.hex;
        };
        primary.fg = roles.accent.primary.hex;
        border.style.fg = roles.state.attention.hex;
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
