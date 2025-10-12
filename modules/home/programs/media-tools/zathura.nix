# Title         : zathura.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/zathura.nix
# ----------------------------------------------------------------------------
# Zathura document viewer with vi-like keybindings and Dracula theme

{ config, lib, pkgs, ... }:

# Dracula theme color reference
# background    #15131F
# current_line  #2A2640
# selection     #44475A
# foreground    #F8F8F2
# comment       #6272A4
# purple        #A072C6
# cyan          #94F2E8
# green         #50FA7B
# yellow        #F1FA8C
# orange        #F97359
# red           #FF5555
# magenta       #d82f94
# pink          #E98FBE

{
  programs.zathura = {
    enable = true;

    # --- Display Options ----------------------------------------------------
    options = {
      # Dracula theme colors
      default-bg = "#15131F";
      default-fg = "#F8F8F2";
      statusbar-bg = "#2A2640";
      statusbar-fg = "#94F2E8";
      inputbar-bg = "#2A2640";
      inputbar-fg = "#F1FA8C";
      notification-bg = "#15131F";
      notification-fg = "#50FA7B";
      notification-error-bg = "#15131F";
      notification-error-fg = "#FF5555";
      notification-warning-bg = "#15131F";
      notification-warning-fg = "#F1FA8C";
      highlight-color = "#F1FA8C";
      highlight-active-color = "#50FA7B";
      completion-bg = "#2A2640";
      completion-fg = "#F8F8F2";
      completion-group-bg = "#44475A";
      completion-group-fg = "#F8F8F2";
      completion-highlight-bg = "#50FA7B";
      completion-highlight-fg = "#15131F";

      # Recolor options for night reading
      recolor = false;
      recolor-lightcolor = "#15131F";         # Background when recolored
      recolor-darkcolor = "#F8F8F2";          # Text when recolored
      recolor-reverse-video = true;             # Better contrast
      recolor-keephue = false;                  # Convert to grayscale

      # Display options
      adjust-open = "best-fit";                 # Auto-fit on open
      pages-per-row = 1;                        # Single page view
      scroll-page-aware = true;                 # Smooth scrolling
      scroll-full-overlap = 0.01;               # Slight overlap when scrolling
      scroll-step = 40;                         # Scroll step size
      zoom-min = 10;                            # Minimum zoom level
      zoom-max = 1000;                          # Maximum zoom level
      zoom-step = 10;                           # Zoom step size

      # Behavior
      selection-clipboard = "clipboard";        # Copy to system clipboard
      window-title-basename = true;             # Show basename in title
      statusbar-basename = true;                # Show basename in statusbar
      database = "sqlite";                      # Enable database for bookmarks

      # SyncTeX support (libsynctex included in nixpkgs zathura by default)
      synctex = true;                                     # Enable SyncTeX support
      synctex-editor-command = "nvim +%{line} %{input}";  # Editor for inverse search

      # Interface
      guioptions = "sv";                        # Show statusbar and vertical scrollbar
    };

    # --- Key Mappings -------------------------------------------------------
    mappings = {
      # Navigation
      "h" = "scroll left";
      "j" = "scroll down";
      "k" = "scroll up";
      "l" = "scroll right";
      "gg" = "goto 1";
      "G" = "goto -1";
      "^" = "goto 1";
      "$" = "goto -1";

      # Page navigation
      "J" = "navigate next";
      "K" = "navigate previous";
      "<C-d>" = "scroll half-down";
      "<C-u>" = "scroll half-up";
      "<C-f>" = "scroll full-down";
      "<C-b>" = "scroll full-up";

      # Zoom and fit
      "=" = "zoom in";
      "-" = "zoom out";
      "0" = "zoom reset";
      "a" = "adjust_window best-fit";
      "s" = "adjust_window width";
      "w" = "adjust_window width";

      # View modes
      "d" = "toggle_page_mode";
      "r" = "rotate";
      "R" = "reload";
      "i" = "recolor";                           # Toggle recolor mode
      "I" = "recolor";                           # Force recolor on

      # Search
      "/" = "search forward";
      "?" = "search backward";
      "n" = "search next";
      "N" = "search previous";

      # Bookmarks
      "m" = "mark_add";
      "'" = "mark_evaluate";

      # Clipboard and selection
      "y" = "copy_link";
      "Y" = "copy_uri";

      # Quit
      "q" = "quit";
      "<C-c>" = "abort";

      # Fullscreen
      "F11" = "toggle_fullscreen";
      "f" = "toggle_fullscreen";

      # Tab navigation (for multiple documents)
      "gt" = "tab_navigate next";
      "gT" = "tab_navigate previous";
      "<C-t>" = "tab_create";
      "<C-w>" = "tab_close";
    };

    # --- Additional Configuration -------------------------------------------
    extraConfig = ''
      # Custom commands and advanced settings

      # Enable text selection with mouse
      set selection-notification true

      # Smooth scroll configuration
      set scroll-hstep 40

      # Link handling
      set link-zoom true
      set link-hadjust true

      # Page layout for dual-page documents
      set first-page-column 1

      # Performance optimizations
      set render-loading true
      set render-loading-bg "#2A2640"
      set render-loading-fg "#6272A4"
    '';
  };
}
