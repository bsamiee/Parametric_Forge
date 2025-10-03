# Title         : jnv.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/jnv.nix
# ----------------------------------------------------------------------------
# Interactive JSON filter using jaq (built-in replacement for jq)

{ config, lib, pkgs, ... }:

# Dracula theme color reference
# background    #15131F
# current_line  #2A2640
# selection     #44475a
# foreground    #F8F8F2
# comment       #7A71AA
# purple        #A072C6
# cyan          #94F2E8
# green         #50FA7B
# yellow        #F1FA8C
# orange        #F97359
# red           #ff5555
# magenta       #d82f94
# pink          #E98FBE

let
  tomlFormat = pkgs.formats.toml { };

  jnvConfig = {
    no_hint = false;

    editor = {
      mode = "Insert";
      word_break_chars = " \t\n!\"#$%&'()*+,-./:;<=>?@[\\]^`{|}~";
      prefix = "󰅂 ";
      prefix_style = {
        fg = "#d82f94";  # magenta
        bold = false;
      };
      active_char_style = {
        fg = "#F8F8F2";  # foreground
        bg = "#15131F";  # background
        bold = false;
      };
      inactive_char_style = {
        fg = "#F8F8F2";  # foreground
        bg = "#15131F";  # background
        bold = false;
      };
    };

    json = {
      max_streams = 1000;
      indent = "  ";
      brackets = {
        style = {
          fg = "#94F2E8";  # cyan
          bold = false;
        };
      };
      key = {
        style = {
          fg = "#50FA7B";  # green
          bold = false;
        };
      };
      string_value = {
        style = {
          fg = "#F1FA8C";  # yellow
          bold = false;
        };
      };
      number_value = {
        style = {
          fg = "#F97359";  # orange
          bold = false;
        };
      };
      null_value = {
        style = {
          fg = "#7A71AA";  # comment
          bold = false;
        };
      };
      boolean_value = {
        style = {
          fg = "#d82f94";  # magenta
          bold = false;
        };
      };
    };

    completion = {
      lines = 10;
      cursor = " ";
      active_item = {
        style = {
          fg = "#15131F";  # background
          bg = "#94F2E8";  # cyan
          bold = false;
        };
      };
      inactive_item = {
        style = {
          fg = "#F8F8F2";  # foreground
          bg = "#15131F";  # background
          bold = false;
        };
      };
      search_chunk_size = 100;
    };

    keybinds = {
      app = {
        exit = "Ctrl+C";
        copy_query = "Ctrl+Q";
        copy_json = "Ctrl+O";
        switch_mode_up = "Shift+Up";
        switch_mode_down = "Shift+Down";
      };
      editor = {
        accept_suggestion = "Tab";
        move_cursor_left = "Left";
        move_cursor_right = "Right";
        move_to_line_start = "Ctrl+A";
        move_to_line_end = "Ctrl+E";
        delete_char_backward = "Backspace";
        clear_line = "Ctrl+U";
        move_word_backward = "Alt+B";
        move_word_forward = "Alt+F";
        delete_word_backward = "Ctrl+W";
        delete_word_forward = "Alt+D";
      };
      suggestion = {
        next = "Tab";
        previous = "Up";
      };
      json = {
        move_up = "Up";
        move_down = "Down";
        move_up_alt = "Ctrl+K";
        move_down_alt = "Ctrl+J";
        move_to_last = "Ctrl+H";
        move_to_first = "Ctrl+L";
        toggle_fold = "Enter";
        expand_all = "Ctrl+P";
        collapse_all = "Ctrl+N";
      };
    };

    reactivity_control = {
      query_debounce_duration_ms = 300;
      resize_debounce_duration_ms = 100;
      spinner_interval_ms = 100;
    };
  };
in
{
  home.packages = [ pkgs.jnv ];
  xdg.configFile."jnv/config.toml".source = tomlFormat.generate "jnv-config" jnvConfig;
}