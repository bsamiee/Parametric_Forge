# Title         : shell-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/shell-tools.nix
# ----------------------------------------------------------------------------
# Modern shell tool integrations and enhancements.

{
  config,
  ...
}:

{
  programs = {
    # --- Nix Index ----------------------------------------------------------
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    # --- Starship Prompt ----------------------------------------------------
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = builtins.fromTOML (builtins.readFile ../configs/apps/starship.toml);
    };

    # --- FZF (Fuzzy Finder) -------------------------------------------------
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        # Official Dracula theme colors from draculatheme.com/fzf
        "--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9"
        "--color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9"
        "--color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6"
        "--color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"
      ];
    };

    # --- Zoxide (Smart Directory Jumper) ------------------------------------
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    # --- Direnv (Directory Environment) -------------------------------------
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };

    # --- Eza (ls replacement) -----------------------------------------------
    eza = {
      enable = true;
      enableZshIntegration = false; # Custom aliases defined elsewhere
      git = true;
      icons = "auto";
    };

    # --- Bat (cat replacement) ----------------------------------------------
    bat = {
      enable = true;
      config = {
        theme = "Dracula";
        style = "numbers,changes";
      };
    };

    # --- Ripgrep (grep replacement) -----------------------------------------
    ripgrep = {
      enable = true;
      arguments = [
        "--smart-case"
        "--hidden"
        "--glob=!.git/*"
      ];
    };

    # --- Fd (find replacement) ----------------------------------------------
    fd = {
      enable = true;
      hidden = true; # Search hidden files by default
      ignores = [
        ".git/"
        "node_modules/"
        "target/"
        ".direnv/"
      ];
    };

    # --- McFly (smart shell history) ----------------------------------------
    mcfly = {
      enable = true;
      enableZshIntegration = true;
      keyScheme = "vim"; # Use vim keybindings
      interfaceView = "BOTTOM"; # Show at bottom of screen
      fuzzySearchFactor = 2; # Enable fuzzy search with moderate weight
      enableLightTheme = false; # Dark theme to match our setup
    };

    # --- Bottom (resource monitor) ------------------------------------------
    bottom = {
      enable = true;
      settings = {
        flags = {
          avg_cpu = true;
          temperature_type = "c";
          rate = 1000;
          left_legend = false;
          current_usage = true;
          group_processes = true;
        };
        colors = {
          # Widget colors
          table_header_color = "#8be9fd"; # Cyan
          widget_title_color = "#bd93f9"; # Purpl
          border_color = "#6272a4"; # Comment
          highlighted_border_color = "#ff79c6"; # Pink
          # Graph colors
          graph_color = "#50fa7b"; # Green
        };
      };
    };

    # --- Broot (interactive tree) -------------------------------------------
    broot = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        modal = true; # Use vim-like modal interface
        # Dracula theme skin
        skin = {
          # Status line
          status_normal_fg = "#f8f8f2"; # Foreground
          status_normal_bg = "#44475a"; # Current Line
          status_error_fg = "#ff5555"; # Red
          status_error_bg = "#282a36"; # Background
          # Tree colors
          tree_fg = "#f8f8f2"; # Foreground
          selected_line_bg = "#44475a"; # Current Line
          permissions_fg = "#6272a4"; # Comment
          # Progress bars
          size_bar_full_bg = "#50fa7b"; # Green
          size_bar_void_bg = "#282a36"; # Background
          # File type colors
          directory_fg = "#8be9fd"; # Cyan
          exe_fg = "#50fa7b"; # Green
          link_fg = "#ff79c6"; # Pink
          # Input and UI
          input_fg = "#8be9fd"; # Cyan
          flag_value_fg = "#f1fa8c"; # Yellow
          table_border_fg = "#6272a4"; # Comment
          code_fg = "#f1fa8c"; # Yellow
          # Additional Dracula colors
          file_fg = "#f8f8f2"; # Normal files
          pruning_fg = "#ff5555"; # Red for pruned/excluded
          # Git status colors
          git_status_new_fg = "#50fa7b"; # Green
          git_status_modified_fg = "#ffb86c"; # Orange
          git_status_deleted_fg = "#ff5555"; # Red
        };
        verbs = [
          # File operations
          { invocation = "edit"; shortcut = "e"; execution = "$EDITOR {file}"; }
          { invocation = "view"; shortcut = "v"; execution = "bat {file}"; }
          { invocation = "create {subpath}"; execution = "$EDITOR {directory}/{subpath}"; leave_broot = false; }
          # Git operations
          { invocation = "git_diff"; shortcut = "gd"; execution = "git diff {file}"; }
          { invocation = "git_status"; shortcut = "gs"; execution = "git status {directory}"; }
          { invocation = "git_log"; shortcut = "gl"; execution = "git log {file}"; }
          # Navigation shortcuts
          { invocation = "home"; key = "ctrl-h"; execution = ":focus ~"; }
          { invocation = "root"; key = "ctrl-r"; execution = ":focus /"; }
          { invocation = "parent"; shortcut = "p"; execution = ":parent"; }
          # Directory operations
          { invocation = "mkdir {subpath}"; shortcut = "md"; execution = "mkdir -p {directory}/{subpath}"; leave_broot = false; }
          { invocation = "cd"; key = "alt-enter"; execution = "cd {directory}"; from_shell = true; }
          # Copy to other panel
          { invocation = "copy_to_panel"; shortcut = "cpp"; execution = "cp -r {file} {other-panel-directory}"; apply_to = "any"; }
          { invocation = "move_to_panel"; shortcut = "mvp"; execution = "mv {file} {other-panel-directory}"; apply_to = "any"; }
        ];
      };
    };
  };
}
