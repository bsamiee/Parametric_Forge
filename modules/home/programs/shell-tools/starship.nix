# Title         : starship.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/starship.nix
# ----------------------------------------------------------------------------
# Prompt themed from the estate palette owner
{
  config,
  lib,
  ...
}: {
  programs.starship = {
    enable = true;
    enableTransience = false;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      # --- [GLOBAL_CONFIGURATION]
      palette = "dracula";
      add_newline = true;
      scan_timeout = 50; # File-scan budget (ms); prompt never blocks on large trees
      command_timeout = 800; # Command budget (ms); slow git/tool calls get cut, not awaited

      # --- [DRACULA_COLOR_PALETTE]
      palettes.dracula = lib.mapAttrs (_: c: c.hex) config.forge.theme.palette;

      # --- [PROMPT_FORMAT]
      # Left-side prompt (contextual information)
      format = lib.concatStrings [
        "$os"
        "$username"
        "$hostname"
        "$directory"
        "$vcs"
        "$nodejs"
        "$python"
        "$rust"
        "$golang"
        "$docker_context"
        "$nix_shell"
        "$line_break"
        "$character"
      ];

      # Right-side prompt: operational telemetry.
      right_format = lib.concatStrings [
        "$status"
        "$cmd_duration"
        "$jobs"
        "$shell"
        "$kubernetes"
        "$time"
      ];

      continuation_prompt = " ";

      # --- [CORE_MODULES]
      username = {
        style_user = "foreground";
        style_root = "red";
        format = "\\[[$user]($style)\\]";
        disabled = false;
        show_always = false; # Only show when SSH or root
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
        truncate_to_repo = true; # Show path relative to git root

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
          Linux = " ";
          Macos = " ";
          NixOS = " ";
          Unknown = " ";
        };
      };

      # --- [GIT_MODULES]
      # vcs composes the git payload with one repo-detection pass per prompt; git_metrics stays out (per-draw diff cost).
      vcs = {
        disabled = false;
        order = ["git"];
        git_modules = "$git_branch$git_state$git_status";
      };

      git_branch = {
        symbol = " ";
        format = "\\[[$symbol$branch]($style)\\]";
        style = "magenta";
        truncation_length = 20;
        truncation_symbol = "…";
        only_attached = false;
        always_show_remote = false;
        ignore_branches = [];
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
        style = "amber"; # pending/attention is the warning hue, never string-yellow
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

      # --- [PROGRAMMING_LANGUAGES]
      nodejs = {
        format = "\\[[$symbol($version)]($style)\\]";
        version_format = "v$major.$minor.$patch";
        symbol = " ";
        style = "green";
        disabled = false;
        not_capable_style = "red";
        detect_extensions = ["js" "mjs" "cjs" "ts" "mts" "cts"];
        detect_files = ["package.json" ".node-version" ".nvmrc"];
        detect_folders = ["node_modules"];
      };

      python = {
        format = "\\[[$symbol$pyenv_prefix($version)($virtualenv)]($style)\\]";
        version_format = "v$major.$minor.$patch";
        symbol = " ";
        style = "yellow";
        pyenv_prefix = "pyenv ";
        pyenv_version_name = false;
        detect_extensions = ["py"];
        detect_files = [".python-version" "Pipfile" "pyproject.toml" "requirements.txt"];
        detect_folders = ["__pycache__" ".venv" "venv"];
      };

      rust = {
        format = "\\[[$symbol($version)]($style)\\]";
        version_format = "v$major.$minor.$patch";
        symbol = "󱘗 ";
        style = "orange";
        detect_extensions = ["rs"];
        detect_files = ["Cargo.toml" "Cargo.lock"];
        detect_folders = [];
      };

      golang = {
        format = "\\[[$symbol($version)]($style)\\]";
        version_format = "v$major.$minor.$patch";
        symbol = "󰟓 ";
        style = "cyan";
        detect_extensions = ["go"];
        detect_files = ["go.mod" "go.sum" "go.work"];
        detect_folders = ["vendor"];
      };

      # --- [SYSTEM_INFORMATION]
      docker_context = {
        format = "\\[[$symbol$context]($style)\\]";
        style = "cyan";
        symbol = " ";
        only_with_files = true;
        disabled = false;
        detect_extensions = [];
        detect_files = ["docker-compose.yml" "docker-compose.yaml" "compose.yml" "compose.yaml" "Dockerfile"];
        detect_folders = [];
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

      # --- [OPERATIONAL_MODULES_RIGHT_PROMPT]
      # Exit truth: pipestatus-aware, renders only on failure.
      status = {
        disabled = false;
        format = "\\[[$symbol$status]($style)\\]";
        symbol = "✘ ";
        style = "red";
        pipestatus = true;
        pipestatus_format = "\\[[$pipestatus]($style)\\]";
        pipestatus_separator = "|";
        recognize_signal_code = true;
        map_symbol = false;
      };

      cmd_duration = {
        min_time = 2000;
        format = "\\[[󱎫 $duration]($style)\\]";
        style = "amber";
        show_milliseconds = false;
        show_notifications = true;
        min_time_to_notify = 45000;
      };

      jobs = {
        format = "\\[[$symbol$number]($style)\\]";
        symbol = "✦ ";
        style = "cyan";
        number_threshold = 1;
        symbol_threshold = 1;
      };

      # Shell identity only when NOT zsh (nested bash/fish/nu/sh sessions).
      shell = {
        disabled = false;
        format = "(\\[[$indicator]($style)\\])";
        style = "comment";
        zsh_indicator = "";
        bash_indicator = "bash";
        fish_indicator = "fish";
        nu_indicator = "nu";
        unknown_indicator = "sh";
      };

      # Context-gated: visible only where kube work is provable (manifests, chart/kustomize roots, or an explicit KUBECONFIG); prod contexts go red.
      kubernetes = {
        disabled = false;
        format = "\\[[󱃾 $context( \\($namespace\\))]($style)\\]";
        style = "purple";
        detect_files = ["skaffold.yaml" "helmfile.yaml" "Chart.yaml" "kustomization.yaml"];
        detect_folders = ["k8s" "kubernetes" "manifests"];
        detect_env_vars = ["KUBECONFIG"];
        contexts = [
          {
            context_pattern = ".*(prod|prd).*";
            style = "red";
          }
        ];
      };

      time = {
        disabled = false;
        format = "[$time]($style)";
        style = "dimmed comment";
        time_format = "%T";
        utc_time_offset = "local";
      };
    };
  };
}
