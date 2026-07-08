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
  inherit (config.forge.theme) palette;
  tomlFormat = pkgs.formats.toml {};
  # termcfg style strings: "fg=<hex>,bg=<hex>,attr=<token|token...>"
  fg = c: "fg=${c.hex}";

  jnvConfig = {
    no_hint = false;

    editor = {
      on_focus = {
        edit_mode = "Insert";
        word_break_chars = lib.stringToCharacters " !\"#$%&'()*+,-./:;<=>?@[\\]^`{|}~";
        prefix = "󰅂 ";
        prefix_style = fg palette.magenta;
        active_char_style = "fg=${palette.background.hex},bg=${palette.foreground.hex}";
        inactive_char_style = "";
      };
      on_defocus = {
        prefix = "󰅂 ";
        prefix_style = "fg=${palette.comment.hex},attr=dim";
        active_char_style = "attr=dim";
        inactive_char_style = "attr=dim";
      };
    };

    json = {
      max_streams = 1000;
      stream = {
        indent = 2;
        curly_brackets_style = fg palette.cyan;
        square_brackets_style = fg palette.cyan;
        key_style = fg palette.green;
        string_value_style = fg palette.yellow;
        number_value_style = fg palette.orange;
        boolean_value_style = fg palette.magenta;
        null_value_style = fg palette.comment;
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
        active_item_style = "fg=${palette.background.hex},bg=${palette.cyan.hex}";
        inactive_item_style = fg palette.foreground;
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
  # dirs-crate config location on macOS; the XDG path is never consulted.
  home.file."Library/Application Support/jnv/config.toml".source =
    tomlFormat.generate "jnv-config" jnvConfig;
}
