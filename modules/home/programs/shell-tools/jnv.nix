# Title         : jnv.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/jnv.nix
# ----------------------------------------------------------------------------
# Interactive JSON filter using jaq (built-in replacement for jq)
{
  config,
  lib,
  pkgs,
  ...
}: let
  # palette retained for the one hue with no semantic role: JSON string values ride the estate string-yellow (syntaxScopes String).
  inherit (config.forge.theme) roles palette;
  tomlFormat = pkgs.formats.toml {};
  # termcfg style strings: "fg=<hex>,bg=<hex>,attr=<token|token...>"
  fg = c: "fg=${c.hex}";

  jnvConfig = {
    no_hint = false;

    editor = {
      on_focus = {
        edit_mode = "Insert";
        word_break_chars = lib.stringToCharacters " !\"#$%&'()*+,-./:;<=>?@[\\]^`{|}~";
        prefix = "❯ ";
        prefix_style = fg roles.accent.secondary;
        active_char_style = "fg=${roles.text.inverse.hex},bg=${roles.text.primary.hex}";
        inactive_char_style = "";
      };
      on_defocus = {
        prefix = "❯ ";
        prefix_style = "fg=${roles.text.muted.hex},attr=dim";
        active_char_style = "attr=dim";
        inactive_char_style = "attr=dim";
      };
    };

    json = {
      max_streams = 1000;
      stream = {
        indent = 2;
        curly_brackets_style = fg roles.accent.primary;
        square_brackets_style = fg roles.accent.primary;
        key_style = fg roles.state.success;
        string_value_style = fg palette.yellow;
        number_value_style = fg roles.state.attention;
        boolean_value_style = fg roles.accent.secondary;
        null_value_style = fg roles.text.muted;
        active_item_attribute = "bold";
        inactive_item_attribute = "dim";
        overflow_mode = "Wrap";
      };
    };

    completion = {
      search_result_chunk_size = 100;
      search_load_chunk_size = 50000;
      listbox = {
        lines = 10;
        cursor = "❯ ";
        # Selection rides the focus fill with inverse text, matching every estate picker.
        active_item_style = "fg=${roles.text.inverse.hex},bg=${roles.focus.active.hex}";
        inactive_item_style = fg roles.text.primary;
      };
    };

    keybinds = {
      exit = ["Ctrl+C"];
      copy_query = ["Ctrl+Q"];
      copy_result = ["Ctrl+O"];
      switch_mode = ["Shift+Up" "Shift+Down"];
      on_editor = {
        backward = ["Left"];
        forward = ["Right"];
        move_to_head = ["Ctrl+A"];
        move_to_tail = ["Ctrl+E"];
        move_to_previous_nearest = ["Alt+B"];
        move_to_next_nearest = ["Alt+F"];
        erase = ["Backspace"];
        erase_all = ["Ctrl+U"];
        erase_to_previous_nearest = ["Ctrl+W"];
        erase_to_next_nearest = ["Alt+D"];
        completion = ["Tab"];
        on_completion = {
          up = ["Up"];
          down = ["Down" "Tab"];
        };
      };
      on_json_viewer = {
        up = ["Up" "Ctrl+K" "ScrollUp"];
        down = ["Down" "Ctrl+J" "ScrollDown"];
        move_to_head = ["Ctrl+L"];
        move_to_tail = ["Ctrl+H"];
        toggle = ["Enter"];
        expand = ["Ctrl+P"];
        collapse = ["Ctrl+N"];
      };
    };

    reactivity_control = {
      query_debounce_duration = "300ms";
      resize_debounce_duration = "100ms";
      spin_duration = "100ms";
    };
  };
in {
  home.packages = [pkgs.jnv];
  # dirs-crate config resolution: ~/Library/Application Support on macOS (the XDG path is never consulted there), $XDG_CONFIG_HOME on Linux.
  home.file = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    "Library/Application Support/jnv/config.toml".source = tomlFormat.generate "jnv-config" jnvConfig;
  };
  xdg.configFile = lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
    "jnv/config.toml".source = tomlFormat.generate "jnv-config" jnvConfig;
  };
}
