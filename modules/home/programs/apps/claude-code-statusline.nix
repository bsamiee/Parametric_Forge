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

      # Single jq call extracts all needed fields (7 invocations → 1)
      read -r cwd model duration_ms ctx_current ctx_size < <(
        ${pkgs.jq}/bin/jq -r '[
          .workspace.current_dir,
          (.model.display_name // .model.model_id // "unknown" | ascii_downcase | capture("(?<m>sonnet|opus|haiku)") | .m // "unknown"),
          (.cost.total_duration_ms // 0),
          ((.context_window.current_usage // {}) | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)),
          (.context_window.context_window_size // 0)
        ] | @tsv'
      )

      # Dracula palette (true color) - $'...' interprets escapes at definition
      declare -A c=(
        [cyan]=$'\033[38;2;148;242;232m'    [magenta]=$'\033[38;2;216;47;148m'
        [yellow]=$'\033[38;2;241;250;140m'  [green]=$'\033[38;2;80;250;123m'
        [red]=$'\033[38;2;255;85;85m'       [orange]=$'\033[38;2;249;115;89m'
        [purple]=$'\033[38;2;160;114;198m'  [pink]=$'\033[38;2;233;143;190m'
        [reset]=$'\033[0m'
      )

      # Directory (truncate to basename if path > 35 chars)
      dir_path="''${cwd/#$HOME/~}"
      (( ''${#dir_path} > 35 )) && dir_path="...''${cwd##*/}"

      # Git segment: branch, worktree indicator, file counts, sync status
      git_segment=""
      if git -C "$cwd" rev-parse --git-dir &>/dev/null; then
        branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null) || branch="?"

        # Worktree detection (linked worktrees have .git as file, not directory)
        wt="" git_root="$cwd"
        while [[ "$git_root" != "/" && ! -e "$git_root/.git" ]]; do git_root="''${git_root%/*}"; done
        [[ -f "$git_root/.git" ]] && wt="@wt"

        # Count staged/modified/untracked in single awk pass
        read -r stg mod unt < <(
          git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null \
          | ${pkgs.gawk}/bin/awk '
              /^[MARCD]/  { stg++ }
              /^.[MD]/    { mod++ }
              /^\?\?/     { unt++ }
              END { print stg+0, mod+0, unt+0 }
            '
        )

        # Ahead/behind using bash string ops (no cut subprocess)
        sync=""
        if ab=$(git -C "$cwd" --no-optional-locks rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null); then
          behind="''${ab%%	*}" ahead="''${ab##*	}"  # tab-separated
          (( behind > 0 )) && sync+="''${c[purple]}↓$behind''${c[reset]}"
          (( ahead > 0 ))  && sync+="''${c[purple]}↑$ahead''${c[reset]}"
        fi

        # Compose changes bracket
        changes=""
        (( stg > 0 )) && changes+="''${c[green]}+$stg''${c[reset]}"
        (( mod > 0 )) && changes+="''${c[yellow]}~$mod''${c[reset]}"
        (( unt > 0 )) && changes+="''${c[red]}?$unt''${c[reset]}"
        [[ -n "$sync" ]] && changes+="$sync"

        git_segment="[''${c[magenta]}$branch$wt''${c[reset]}]"
        [[ -n "$changes" ]] && git_segment+="[$changes]"
      fi

      # Session duration (show only if >= 1 minute)
      time_segment=""
      if (( duration_ms >= 60000 )); then
        mins=$((duration_ms / 60000)) hrs=$((mins / 60)) mins=$((mins % 60))
        (( hrs > 0 )) \
          && time_segment="[''${c[pink]}''${hrs}h''${mins}m''${c[reset]}]" \
          || time_segment="[''${c[pink]}''${mins}m''${c[reset]}]"
      fi

      # Context usage (color by threshold)
      ctx_segment=""
      if (( ctx_size > 0 )); then
        pct=$((ctx_current * 100 / ctx_size))
        color=$( (( pct > 80 )) && echo red || { (( pct > 60 )) && echo yellow || echo green; } )
        ctx_segment="[''${c[$color]}$pct%%''${c[reset]}]"
      fi

      printf "[''${c[cyan]}%s''${c[reset]}]%s%s%s[''${c[orange]}%s''${c[reset]}]" \
        "$dir_path" "$git_segment" "$time_segment" "$ctx_segment" "$model"
    '';
  };
}
