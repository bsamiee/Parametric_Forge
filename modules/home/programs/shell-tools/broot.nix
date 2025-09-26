# Title         : broot.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/broot.nix
# ----------------------------------------------------------------------------
# Tree explorer with vim-style navigation

{ config, lib, pkgs, ... }:

{
  programs.broot = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = false;

    settings = {
      modal = true; # Modal mode for vim-like navigation
      file_sum_threads_count = 4;  # Parallel threads for directory sizes
      date_time_format = "%Y-%m-%d %H:%M:%S";
      default_flags = "";
      # syntax_theme uses default MochaDark (base16 dark theme)
      icon_theme = "nerdfont";  # Matches our GeistMono Nerd Font
      content_search_max_file_size = "10MB";
      show_hidden = false;  # Toggle with 'h' in broot
      show_git_info = true;
      quit_on_last_cancel = true;  # ESC on empty pattern quits broot
      max_panels_count = 2;  # Default is 2, but explicit is better

      # Column display order (git status visible)
      cols_order = [ "mark" "git" "branch" "size" "date" "name" ];

      search_modes = {
        "<empty>" = "fuzzy name";     # Default: fuzzy search on names
        "/" = "regex name";            # /pattern: regex on names
        "c/" = "regex content";        # c/pattern: search file contents (regex only)
        "z/" = "fuzzy path";           # z/pattern: fuzzy on full paths
      };

      special_paths = {
        "/tmp" = "no-enter";
        "**/.git" = "hide";
        "**/node_modules" = "hide";
        "**/target" = "hide";
        "**/result" = "hide";          # Nix build outputs
        "**/result-*" = "hide";
      };
    };

    settings.verbs = [
      # --- File Operations --------------------------------------------------
      # Open with default system opener
      {
        invocation = "open";
        execution = "open {file}";
        shortcut = "o";
      }
      # Edit with nvim (our default editor)
      {
        invocation = "edit";
        execution = "nvim {file}";
        shortcut = "e";
        leave_broot = true;
      }
      # Open in VSCode (changed shortcut from 'c' to 'v' to avoid conflict)
      {
        invocation = "code";
        execution = "code {file}";
        shortcut = "v";
        leave_broot = true;
      }
      # Create new file
      {
        invocation = "create {new_file}";
        execution = "touch {directory}/{new_file}";
        shortcut = "cf";  # Changed from 'c' to 'cf' (create file)
      }
      # Create new directory
      {
        invocation = "mkdir {new_dir}";
        execution = "mkdir -p {directory}/{new_dir}";
        shortcut = "md";
      }
      # Move to trash (safer than rm)
      {
        invocation = "trash";
        execution = "trash {file}";
        shortcut = "dd";
      }
      # Git status on current directory
      {
        invocation = "git_status";
        execution = "git -C {directory} status";
        shortcut = "gs";
      }

      # --- Search Operations ------------------------------------------------
      # Search with ripgrep (stays in broot with results)
      {
        invocation = "rg {pattern}";
        execution = "rg --hidden --follow {pattern} {directory}";
        leave_broot = false;
      }

      # Compare files between panels
      {
        invocation = "diff_panels";
        external = "diff {file} {other-panel-file} | delta";
        shortcut = "dp";
        apply_to = "file";
      }
    ];

    # --- Appearance ---------------------------------------------------------
    # Dracula-inspired dark theme colors
    settings.skin = {
      # Core elements (using Dracula palette)
      default = "gray(15) None";              # Light gray text on dark bg
      tree = "gray(10) None";                 # Tree lines in medium gray
      file = "gray(15) None";                 # Regular files in light gray
      directory = "ansi(141) None Bold";      # Dirs in purple (Dracula purple)
      exe = "ansi(84) None";                  # Executables in green
      link = "ansi(117) None";                # Symlinks in cyan
      pruning = "gray(8) None Italic";        # Pruned branches darker
      permissions = "gray(10) None";          # Perms in medium gray
      size = "ansi(117) None";                # Size in cyan
      dates = "ansi(61) None";                # Dates in purple-blue
      sparse = "ansi(141) None";              # Sparse indicator

      # Git status colors (Dracula-style)
      git_branch = "ansi(141) None";          # Branch in purple
      git_insertions = "ansi(84) None";       # Added in green
      git_deletions = "ansi(212) None";       # Deleted in pink/red
      git_status_current = "gray(10) None";   # Current in gray
      git_status_modified = "ansi(228) None"; # Modified in yellow
      git_status_new = "ansi(84) None Bold";  # New in bold green
      git_status_ignored = "gray(8) None";    # Ignored darker
      git_status_conflicted = "ansi(212) None"; # Conflicts in red
      git_status_other = "ansi(141) None";    # Other in purple

      # UI elements
      selected_line = "None gray(4)";         # Selection bg slightly visible
      char_match = "ansi(228) None Bold";     # Match highlight in yellow
      file_error = "ansi(212) None";          # Errors in pink/red
      flag_label = "gray(12) None";           # Labels medium gray
      flag_value = "ansi(141) None Bold";     # Values in bold purple
      input = "gray(15) None";                # Input text light gray

      # Status bar (bottom)
      status_error = "gray(1) ansi(212)";     # Error bg in red
      status_job = "ansi(84) gray(3)";        # Job status green on dark
      status_normal = "gray(15) gray(3)";     # Normal status
      status_italic = "ansi(141) gray(3)";    # Italic purple on dark
      status_bold = "ansi(141) gray(3) Bold"; # Bold purple on dark
      status_code = "ansi(228) gray(3)";      # Code yellow on dark
      status_ellipsis = "gray(10) gray(3)";   # Ellipsis subtle

      # Scrollbar
      scrollbar_thumb = "gray(8) None";       # Scrollbar visible but subtle
      scrollbar_track = "gray(3) None";       # Track very dark

      # Help text
      help_paragraph = "gray(15) None";       # Help text readable
      help_bold = "ansi(141) None Bold";      # Help bold in purple
      help_italic = "ansi(141) None Italic";  # Help italic in purple
      help_code = "gray(15) gray(3)";         # Code blocks highlighted
      help_headers = "ansi(228) None Bold";   # Headers in yellow
    };
  };
}
