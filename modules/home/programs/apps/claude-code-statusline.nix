# Title         : claude-code-statusline.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/claude-code-statusline.nix
# ----------------------------------------------------------------------------
# Claude Code CLI statusline configuration (matches Starship bracket style)
{pkgs, ...}: {
  home.file.".claude/statusline-command.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      input=$(cat)
      cwd=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.workspace.current_dir')

      # Extract model short name (sonnet/opus/haiku)
      model_raw=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.model.display_name // .model.model_id // "unknown"')
      model=$(echo "$model_raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/.*(sonnet|opus|haiku).*/\1/')

      # Dracula palette (true color)
      cyan="\033[38;2;148;242;232m"     # #94F2E8
      magenta="\033[38;2;216;47;148m"   # #d82f94
      yellow="\033[38;2;241;250;140m"   # #F1FA8C
      green="\033[38;2;80;250;123m"     # #50FA7B
      red="\033[38;2;255;85;85m"        # #FF5555
      orange="\033[38;2;249;115;89m"    # #F97359
      reset="\033[0m"

      # Directory (truncate to last 2 segments if long)
      dir_path="''${cwd/#$HOME/~}"
      [[ ''${#dir_path} -gt 35 ]] && dir_path="...''${cwd##*/}"

      # Git branch + status
      git_segment=""
      if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
        branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null || echo "?")
        git_status=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null || true)

        mod=$(echo "$git_status" | grep -c '^ M' || true)
        stg=$(echo "$git_status" | grep -c '^[MARCD]' || true)
        unt=$(echo "$git_status" | grep -c '^??' || true)

        changes=""
        [[ $stg -gt 0 ]] && changes="''${changes}''${green}+''${reset}"
        [[ $mod -gt 0 ]] && changes="''${changes}''${yellow}~''${reset}"
        [[ $unt -gt 0 ]] && changes="''${changes}''${red}?''${reset}"

        git_segment="[''${magenta} $branch''${reset}]"
        [[ -n "$changes" ]] && git_segment="''${git_segment}[$changes]"
      fi

      # Context usage
      ctx_segment=""
      usage=$(echo "$input" | ${pkgs.jq}/bin/jq '.context_window.current_usage // empty')
      if [[ -n "$usage" ]]; then
        current=$(echo "$usage" | ${pkgs.jq}/bin/jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
        size=$(echo "$input" | ${pkgs.jq}/bin/jq '.context_window.context_window_size')
        pct=$((current * 100 / size))

        [[ $pct -gt 80 ]] && c="$red" || { [[ $pct -gt 60 ]] && c="$yellow" || c="$green"; }
        ctx_segment="[''${c}$pct%%''${reset}]"
      fi

      # Model segment
      model_segment="[''${orange}$model''${reset}]"

      printf "[''${cyan}$dir_path''${reset}]''${git_segment}''${ctx_segment}''${model_segment}"
    '';
  };
}
