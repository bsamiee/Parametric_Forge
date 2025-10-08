# Title         : starship.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/starship.nix
# ----------------------------------------------------------------------------
# Dracula themed customizable prompt for any shell

{ config, lib, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    # Home-manager handles ZSH integration automatically

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      # --- Global Configuration ---------------------------------------------
      palette = "dracula";                    # Use Dracula color palette
      add_newline = true;                     # Blank line between prompts
      scan_timeout = 20;                      # Timeout for scanning files (ms) - optimized
      command_timeout = 500;                  # Timeout for commands (ms)
      follow_symlinks = true;                 # Follow symlinks to check git repos

      # --- Dracula Color Palette --------------------------------------------
      palettes.dracula = {
        background = "#15131F";
        current_line = "#2A2640";
        selection = "#44475A";
        foreground = "#F8F8F2";
        comment = "#6272A4";
        purple = "#A072C6";
        cyan = "#94F2E8";
        green = "#50FA7B";
        yellow = "#F1FA8C";
        orange = "#F97359";
        red = "#FF5555";
        magenta = "#d82f94";
        pink = "#E98FBE";
      };

      # --- Prompt Format ----------------------------------------------------
      # Left-side prompt (contextual information)
      format = lib.concatStrings [
        "$os"
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_state"
        "$git_status"
        "$git_metrics"
        "$nodejs"
        "$python"
        "$rust"
        "$golang"
        "$docker_context"
        "$nix_shell"
        "$line_break"
        "$status"
        "$container"
        "$shell"
        "$character"
      ];

      # Right-side prompt (session metadata)
      right_format = lib.concatStrings [
        "$memory_usage"
        "$jobs"
        "$cmd_duration"
        "$time"
      ];

      # Continuation prompt for incomplete commands
      continuation_prompt = " ";

      # --- Core Modules -----------------------------------------------------
      username = {
        style_user = "foreground";
        style_root = "red";
        format = "\\[[$user]($style)\\]";
        disabled = false;
        show_always = false;                # Only show when SSH or root
      };

      hostname = {
        ssh_only = true;
        ssh_symbol = " ";
        format = "\\[[$ssh_symbol$hostname]($style)\\]";
        style = "red";
        disabled = false;
      };

      directory = {
        style = "cyan";
        format = "[$path]($style)[$read_only]($read_only_style) ";
        home_symbol = "~";
        read_only = " 󰌾";
        read_only_style = "red";
        truncation_length = 3;
        truncation_symbol = "…/";
        truncate_to_repo = true;             # Show path relative to git root

        substitutions = {
          "Documents" = "󰈙";
          "Downloads" = "󰇚";
          "Music" = "󰝚";
          "Pictures" = "󰋩";
          "Videos" = "󰕧";
        };
      };

      character = {
        success_symbol = "[](green)";
        error_symbol = "[](red)";
        vimcmd_symbol = "[](green)";
        vimcmd_visual_symbol = "[](yellow)";
        vimcmd_replace_symbol = "[](magenta)";
        vimcmd_replace_one_symbol = "[](magenta)";
        format = "$symbol ";
      };

      os = {
        format = "[$symbol]($style) ";
        style = "cyan";
        disabled = false;
        symbols = {
          Alpaquita = " ";
          Alpine = " ";
          AlmaLinux = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CachyOS = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Kali = " ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          Nobara = " ";
          OpenBSD = "󰈺 ";
          openSUSE = " ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          RockyLinux = " ";
          Redox = "󰀘 ";
          Solus = "󰠳 ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Void = " ";
          Windows = "󰍲 ";
        };
      };

      # --- Git Modules ------------------------------------------------------
      git_branch = {
        symbol = " ";
        format = "\\[[$symbol$branch]($style)\\]";
        style = "magenta";
        truncation_length = 20;
        truncation_symbol = "…";
        only_attached = false;
        always_show_remote = false;
        ignore_branches = [ ];
      };

      git_state = {
        format = "\\[[$state( $progress_current/$progress_total)]($style)\\]";
        style = "orange";
        rebase = "REBASING";
        merge = "MERGING";
        revert = "REVERTING";
        cherry_pick = "CHERRY-PICKING";
        bisect = "BISECTING";
        am = "AM";
        am_or_rebase = "AM/REBASE";
      };

      git_status = {
        format = "(\\[[$all_status$ahead_behind]($style)\\])";
        style = "yellow";
        conflicted = "= ";
        ahead = "⇡ $count";
        behind = "⇣ $count";
        diverged = "⇕⇡ $ahead_count ⇣ $behind_count";
        up_to_date = "";
        untracked = " $count";
        stashed = "󰜰 $count";
        modified = " $count ";
        staged = " $count ";
        renamed = " $count ";
        deleted = " $count ";
        typechanged = "~ $count ";
        ignore_submodules = false;
      };

      git_metrics = {
        added_style = "green";
        deleted_style = "red";
        only_nonzero_diffs = true;
        format = "\\[[+$added]($added_style) [-$deleted]($deleted_style)\\]";
        disabled = false;
      };

      # --- Programming Languages --------------------------------------------
      nodejs = {
        format = "\\[[$symbol($version)]($style)\\]";
        version_format = "v$major.$minor.$patch";
        symbol = " ";
        style = "green";
        disabled = false;
        not_capable_style = "red";
        detect_extensions = [ "js" "mjs" "cjs" "ts" "mts" "cts" ];
        detect_files = [ "package.json" ".node-version" ".nvmrc" ];
        detect_folders = [ "node_modules" ];
      };

      python = {
        format = "\\[[$symbol$pyenv_prefix($version)($virtualenv)]($style)\\]";
        version_format = "v$major.$minor.$patch";
        symbol = " ";
        style = "yellow";
        pyenv_prefix = "pyenv ";
        pyenv_version_name = false;
        detect_extensions = [ "py" ];
        detect_files = [ ".python-version" "Pipfile" "pyproject.toml" "requirements.txt" ];
        detect_folders = [ "__pycache__" ".venv" "venv" ];
      };

      lua = {
        format = "\\[[$symbol($version)]($style)\\]";
        version_format = "v$major.$minor.$patch";
        symbol = "󰢱 ";
        style = "cyan";
        lua_binary = "lua";
        disabled = false;
        detect_extensions = [ "lua" ];
        detect_files = [ ".lua-version" ];
        detect_folders = [ "lua" ];
      };

      rust = {
        format = "\\[[$symbol($version)]($style)\\]";
        version_format = "v$major.$minor.$patch";
        symbol = "󱘗 ";
        style = "orange";
        detect_extensions = [ "rs" ];
        detect_files = [ "Cargo.toml" "Cargo.lock" ];
        detect_folders = [ ];
      };

      golang = {
        format = "\\[[$symbol($version)]($style)\\]";
        version_format = "v$major.$minor.$patch";
        symbol = "󰟓 ";
        style = "cyan";
        detect_extensions = [ "go" ];
        detect_files = [ "go.mod" "go.sum" "go.work" ];
        detect_folders = [ "vendor" ];
      };

      # --- System Information -----------------------------------------------
      docker_context = {
        format = "\\[[$symbol$context]($style)\\]";
        style = "cyan";
        symbol = " ";
        only_with_files = true;
        disabled = false;
        detect_extensions = [ ];
        detect_files = [ "docker-compose.yml" "docker-compose.yaml" "compose.yml" "compose.yaml" "Dockerfile" ];
        detect_folders = [ ];
      };

      nix_shell = {
        format = "\\[[$symbol$state( ($name))]($style)\\]";
        symbol = " ";
        style = "purple";
        impure_msg = "[impure](red)";
        pure_msg = "[pure](green)";
        unknown_msg = "";
        disabled = false;
        heuristic = false;
      };

      memory_usage = {
        disabled = false;
        threshold = 75;
        format = "[$symbol[$ram( | $swap)]($style)]";
        style = "dimmed comment";
        symbol = "󰍛 ";
      };

      cmd_duration = {
        min_time = 2000;
        format = " took [$duration]($style)";
        style = "yellow";
        show_milliseconds = false;
        show_notifications = false;
        min_time_to_notify = 45000;
      };

      # --- Optional Modules -------------------------------------------------
      jobs = {
        threshold = 1;
        symbol_threshold = 1;
        number_threshold = 2;
        format = "[$symbol$number]($style)";
        symbol = "󰒓 ";
        style = "purple";
      };

      time = {
        disabled = false;
        format = "[$time]($style)";
        style = "dimmed comment";
        time_format = "%T";
        utc_time_offset = "local";
      };

      status = {
        style = "red";
        symbol = " ";
        success_symbol = "";
        format = "[$symbol$common_meaning$signal_name$maybe_int]($style) ";
        map_symbol = true;
        disabled = true;                     # Character module handles success/error
      };

      # --- Performance Settings ---------------------------------------------
      package = {
        disabled = false;                    # Re-enabled for development workflows
        display_private = false;             # Hide private package versions
      };
    };
  };
}
