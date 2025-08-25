# Title         : file-managers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/file-managers.nix
# ----------------------------------------------------------------------------
# Terminal file managers: yazi (modern file manager) and lf (lightweight file manager).
# These tools provide efficient file navigation, preview capabilities, and
# customizable interfaces for terminal-based file management workflows.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- Yazi Modern File Manager ----------------------------------
    # Feature-rich terminal file manager with async I/O and modern UI
    # Provides file preview, bulk operations, and extensive customization
    # TODO: No home-manager module available - requires config files
    
    # yazi = {
    #   enable = true;
    #   
    #   # --- Core Configuration --------------------------------------
    #   settings = {
    #     # --- Manager Settings --------------------------------
    #     # File manager behavior and appearance
    #     manager = {
    #       # Layout configuration
    #       layout = [ 1 4 3 ];  # Ratio for parent:current:preview panes
    #       sort_by = "alphabetical";  # alphabetical, created, modified, size
    #       sort_sensitive = false;    # Case sensitive sorting
    #       sort_reverse = false;      # Reverse sort order
    #       sort_dir_first = true;     # Directories first
    #       linemode = "none";         # none, size, permissions, mtime
    #       show_hidden = false;       # Show hidden files
    #       show_symlink = true;       # Show symlink indicators
    #       scrolloff = 5;             # Lines to keep visible when scrolling
    #     };
    #     
    #     # --- Preview Settings --------------------------------
    #     # File preview configuration
    #     preview = {
    #       # Image preview
    #       image_filter = "triangle";  # lanczos3, triangle, catmull_rom
    #       image_quality = 75;         # JPEG quality for image preview
    #       
    #       # Text preview
    #       max_width = 600;            # Maximum preview width
    #       max_height = 900;           # Maximum preview height
    #       cache_dir = "${config.xdg.cacheHome}/yazi";
    #       
    #       # Preview protocols
    #       ueberzug_scale = 1.0;       # Ueberzug scaling factor
    #       ueberzug_offset = [ 0 0 0 0 ]; # Ueberzug offset [x, y, w, h]
    #     };
    #     
    #     # --- Opener Configuration ----------------------------
    #     # File opening associations
    #     opener = {
    #       # Text files
    #       edit = [
    #         { run = "$EDITOR \"$@\""; block = true; for = "unix"; }
    #       ];
    #       
    #       # Image files
    #       open = [
    #         { run = "open \"$@\""; desc = "Open"; for = "macos"; }
    #         { run = "xdg-open \"$@\""; desc = "Open"; for = "linux"; }
    #       ];
    #       
    #       # Archive files
    #       extract = [
    #         { run = "ouch decompress \"$@\""; desc = "Extract"; }
    #       ];
    #       
    #       # Media files
    #       play = [
    #         { run = "mpv \"$@\""; desc = "Play"; }
    #       ];
    #     };
    #     
    #     # --- File Type Associations -------------------------
    #     # MIME type to opener mappings
    #     open = {
    #       # Text files
    #       "text/*" = "edit";
    #       "application/json" = "edit";
    #       "application/x-ndjson" = "edit";
    #       
    #       # Archives
    #       "application/zip" = "extract";
    #       "application/gzip" = "extract";
    #       "application/x-tar" = "extract";
    #       "application/x-bzip2" = "extract";
    #       "application/x-7z-compressed" = "extract";
    #       
    #       # Images
    #       "image/*" = "open";
    #       
    #       # Videos
    #       "video/*" = "play";
    #       
    #       # Audio
    #       "audio/*" = "play";
    #     };
    #   };
    #   
    #   # --- Key Bindings ------------------------------------
    #   # Custom key bindings for navigation and operations
    #   keymap = {
    #     # Navigation
    #     "k" = "arrow -1";
    #     "j" = "arrow 1";
    #     "h" = "leave";
    #     "l" = "enter";
    #     
    #     # File operations
    #     "o" = "open";
    #     "O" = "open --interactive";
    #     "e" = "open --interactive";
    #     
    #     # Selection
    #     "<Space>" = "toggle";
    #     "v" = "visual_mode";
    #     "V" = "visual_mode --unset";
    #     
    #     # Copy/Move/Delete
    #     "y" = "yank";
    #     "x" = "cut";
    #     "p" = "paste";
    #     "P" = "paste --force";
    #     "d" = "remove";
    #     "D" = "remove --permanently";
    #     
    #     # Directory operations
    #     "a" = "create";
    #     "r" = "rename";
    #     ";" = "shell";
    #     ":" = "shell --block";
    #     
    #     # Search and filter
    #     "/" = "search fd";
    #     "?" = "search rg";
    #     "f" = "filter";
    #     
    #     # View options
    #     "s" = "sort";
    #     "." = "hidden toggle";
    #     "z" = "zoom";
    #   };
    #   
    #   # --- Theme Configuration -----------------------------
    #   # Color scheme and visual appearance
    #   theme = {
    #     # File type colors
    #     filetype = {
    #       rules = [
    #         { mime = "image/*"; fg = "yellow"; }
    #         { mime = "video/*"; fg = "magenta"; }
    #         { mime = "audio/*"; fg = "cyan"; }
    #         { mime = "application/zip"; fg = "red"; }
    #         { mime = "application/gzip"; fg = "red"; }
    #         { mime = "application/x-tar"; fg = "red"; }
    #         { name = "*.md"; fg = "blue"; }
    #         { name = "*.nix"; fg = "blue"; }
    #         { name = "*.rs"; fg = "red"; }
    #         { name = "*.py"; fg = "green"; }
    #         { name = "*.js"; fg = "yellow"; }
    #         { name = "*.ts"; fg = "blue"; }
    #       ];
    #     };
    #     
    #     # UI colors
    #     manager = {
    #       cwd = { fg = "cyan"; };
    #       hovered = { fg = "white"; bg = "blue"; };
    #       preview_hovered = { underline = true; };
    #       find_keyword = { fg = "yellow"; italic = true; };
    #       find_position = { fg = "magenta"; bg = "reset"; italic = true; };
    #       marker_selected = { fg = "lightgreen"; bg = "lightgreen"; };
    #       marker_copied = { fg = "lightyellow"; bg = "lightyellow"; };
    #       marker_cut = { fg = "lightred"; bg = "lightred"; };
    #       tab_active = { fg = "lightblue"; };
    #       tab_inactive = { fg = "darkgray"; };
    #       border_symbol = "│";
    #       border_style = { fg = "gray"; };
    #     };
    #   };
    # };

    # --- LF Lightweight File Manager ------------------------------
    # Minimalist terminal file manager inspired by ranger
    # Provides fast navigation with customizable commands and previews
    # TODO: No home-manager module available - requires config file
    
    # lf = {
    #   enable = true;
    #   
    #   # --- Core Configuration --------------------------------------
    #   settings = {
    #     # --- General Settings --------------------------------
    #     # Basic file manager behavior
    #     hidden = false;           # Show hidden files
    #     ignorecase = true;        # Case insensitive search
    #     ignoredia = true;         # Ignore diacritics in search
    #     drawbox = true;           # Draw borders around panes
    #     icons = true;             # Show file type icons
    #     number = false;           # Show line numbers
    #     relativenumber = false;   # Show relative line numbers
    #     findlen = 1;              # Minimum length for find command
    #     scrolloff = 5;            # Lines to keep visible when scrolling
    #     tabstop = 4;              # Tab width for preview
    #     wrapscan = true;          # Wrap around in search
    #     
    #     # --- Preview Settings --------------------------------
    #     # File preview configuration
    #     preview = true;           # Enable file preview
    #     previewer = "~/.config/lf/preview.sh";  # Preview script
    #     cleaner = "~/.config/lf/clean.sh";      # Preview cleaner script
    #     
    #     # --- Shell Settings ----------------------------------
    #     # Shell integration and commands
    #     shell = "bash";           # Shell to use for commands
    #     shellopts = "-eu";        # Shell options
    #     ifs = "\\n";              # Internal field separator
    #     filesep = "\\n";          # File separator for selections
    #   };
    #   
    #   # --- Commands ----------------------------------------
    #   # Custom commands for file operations
    #   commands = {
    #     # --- File Operations ---------------------------------
    #     # Basic file manipulation commands
    #     "open" = ''
    #       ''${{
    #         case $(file --mime-type -Lb $f) in
    #           text/*) $EDITOR $fx;;
    #           image/*) open $f;;
    #           video/*) mpv $f;;
    #           audio/*) mpv $f;;
    #           application/pdf) open $f;;
    #           *) for f in $fx; do $OPENER $f > /dev/null 2> /dev/null & done;;
    #         esac
    #       }}
    #     '';
    #     
    #     "mkdir" = ''
    #       ''${{
    #         printf "Directory Name: "
    #         read ans
    #         mkdir $ans
    #       }}
    #     '';
    #     
    #     "mkfile" = ''
    #       ''${{
    #         printf "File Name: "
    #         read ans
    #         touch $ans
    #       }}
    #     '';
    #     
    #     # --- Archive Operations ------------------------------
    #     "extract" = ''
    #       ''${{
    #         case $f in
    #           *.tar.bz2)   tar xjf $f   ;;
    #           *.tar.gz)    tar xzf $f   ;;
    #           *.bz2)       bunzip2 $f   ;;
    #           *.rar)       unrar x $f   ;;
    #           *.gz)        gunzip $f    ;;
    #           *.tar)       tar xf $f    ;;
    #           *.tbz2)      tar xjf $f   ;;
    #           *.tgz)       tar xzf $f   ;;
    #           *.zip)       unzip $f     ;;
    #           *.Z)         uncompress $f;;
    #           *.7z)        7z x $f      ;;
    #           *)           echo "Unsupported format" ;;
    #         esac
    #       }}
    #     '';
    #     
    #     # --- Git Integration ---------------------------------
    #     "git_branch" = ''
    #       ''${{
    #         git branch | fzf | xargs git checkout
    #         lf -remote "send $id reload"
    #       }}
    #     '';
    #     
    #     "git_log" = ''
    #       git log --oneline --decorate --graph | less
    #     '';
    #   };
    #   
    #   # --- Key Bindings ------------------------------------
    #   # Custom key bindings for navigation and operations
    #   keybindings = {
    #     # --- Navigation --------------------------------------
    #     "h" = "updir";
    #     "j" = "down";
    #     "k" = "up";
    #     "l" = "open";
    #     
    #     # --- File Operations ---------------------------------
    #     "o" = "open";
    #     "e" = "$EDITOR $f";
    #     "i" = "$PAGER $f";
    #     
    #     # --- Directory Operations ----------------------------
    #     "a" = "mkfile";
    #     "A" = "mkdir";
    #     "r" = "rename";
    #     "d" = "delete";
    #     
    #     # --- Selection and Clipboard -------------------------
    #     "<space>" = "toggle";
    #     "y" = "copy";
    #     "x" = "cut";
    #     "p" = "paste";
    #     "c" = "clear";
    #     
    #     # --- Search and Filter -------------------------------
    #     "/" = "search";
    #     "?" = "search-back";
    #     "n" = "search-next";
    #     "N" = "search-prev";
    #     "f" = "find";
    #     "F" = "find-back";
    #     
    #     # --- View Options ------------------------------------
    #     "." = "set hidden!";
    #     "s" = "set info size";
    #     "t" = "set info time";
    #     
    #     # --- Archive Operations ------------------------------
    #     "X" = "extract";
    #     
    #     # --- Git Integration ---------------------------------
    #     "gb" = "git_branch";
    #     "gl" = "git_log";
    #   };
    # };
  };

  # --- Environment Variables for Manual Configuration -------------------
  # These environment variables configure the tools until home-manager modules
  # are available. They should be moved to environment.nix in actual implementation.
  
  # Yazi configuration (XDG compliant)
  # YAZI_CONFIG_HOME = "${config.xdg.configHome}/yazi";
  # YAZI_FILE_ONE = "${config.xdg.runtimeDir}/yazi-file-one";
  
  # LF configuration (XDG compliant)
  # LF_CONFIG_HOME = "${config.xdg.configHome}/lf";
  
  # Common file manager environment variables
  # EDITOR = "${pkgs.neovim}/bin/nvim";
  # PAGER = "${pkgs.less}/bin/less -R";
  # OPENER = if pkgs.stdenv.isDarwin then "open" else "xdg-open";
  
  # --- Integration Notes -----------------------------------------------
  # 1. Yazi requires yazi.toml, keymap.toml, theme.toml in configs/file-managers/yazi/
  # 2. LF requires lfrc config file in configs/file-managers/lf/lfrc
  # 3. Both tools benefit from preview scripts for different file types
  # 4. Integration with system file associations and default applications
  # 5. Package dependencies: yazi, lf in packages/sysadmin.nix or core.nix
  # 6. Consider integration with other terminal tools (fzf, ripgrep, etc.)
  
  # --- Shell Integration for Manual Configuration ---------------------
  # These functions provide shell integration until programs modules are available
  
  # Yazi shell integration function
  # function y() {
  #   local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  #   yazi "$@" --cwd-file="$tmp"
  #   if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
  #     cd -- "$cwd"
  #   fi
  #   rm -f -- "$tmp"
  # }
  
  # LF shell integration function
  # function lf() {
  #   local tmp="$(mktemp -t "lf-cwd.XXXXXX")"
  #   command lf -last-dir-path="$tmp" "$@"
  #   if [ -f "$tmp" ]; then
  #     local dir="$(cat "$tmp")"
  #     rm -f "$tmp"
  #     if [ -d "$dir" ] && [ "$dir" != "$(pwd)" ]; then
  #       cd "$dir"
  #     fi
  #   fi
  # }
  
  # --- TODO: Future Improvements --------------------------------------
  # 1. Create comprehensive preview scripts for different file types
  # 2. Set up custom themes matching system color scheme
  # 3. Integrate with cloud storage and remote file systems
  # 4. Add support for file operations with progress indicators
  # 5. Create custom commands for development workflows
  # 6. Integrate with version control systems (git, etc.)
  # 7. Add support for file tagging and organization systems
  # 8. Consider integration with backup and synchronization tools
  
  # --- Usage Examples ------------------------------------------------
  # Common usage patterns for these tools:
  
  # Yazi examples:
  # yazi                           # Start file manager in current directory
  # yazi /path/to/directory        # Start in specific directory
  # yazi --cwd-file=/tmp/cwd       # Save current directory to file
  # y                              # Use shell integration function
  
  # LF examples:
  # lf                             # Start file manager in current directory
  # lf /path/to/directory          # Start in specific directory
  # lf -last-dir-path=/tmp/dir     # Save last directory to file
  # lf -command "set hidden"       # Start with hidden files shown
  
  # Common operations in both:
  # j/k or ↓/↑                     # Navigate up/down
  # h/l or ←/→                     # Navigate parent/child directories
  # Space                          # Select/toggle files
  # y/x/p                          # Copy/cut/paste operations
  # d                              # Delete selected files
  # r                              # Rename file/directory
  # /                              # Search files
  # .                              # Toggle hidden files
}