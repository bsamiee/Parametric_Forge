# Title         : starship.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/starship.nix
# ----------------------------------------------------------------------------
# Prompt themed from the estate palette owner. One $fill-composed top line (context left, telemetry right) over a bare pointer line; every
# segment is a round-paren conditional group so inactive modules vanish gap-free. Enclosure law: the branch is a bare WORD in its role color;
# brackets wrap discrete marker clusters (the git-status readout, exit status) as ONE outer pair around space-separated `<marker><count>`
# tokens; parens wrap transient operations (rebase/merge). Git markers project from the theme vocabulary's ASCII register (roles.git .ascii);
# the transient profile collapses scrollback prompts via zsh/init.nix.
{
  config,
  lib,
  ...
}: let
  inherit (config.forge.theme) roles palette icons projections;

  # BMP private-use glyphs mint from codepoint escapes: the harness edit path strips raw 3-byte PUA literals, so rows
  # land as \uXXXX through fromJSON. Supplementary-plane glyphs (U+F0000+) survive writes and stay literal below.
  glyph = lib.mapAttrs (_: c: builtins.fromJSON ''"\u${c}"'') {
    ellipsis = "EA7C"; # codicon ellipsis
    github = "EA84"; # codicon github
    dotnet = "E77F"; # devicon dotnet
  };
  # Bare marker chars: the ascii twins shed their own brackets inside the cluster's one outer pair; format-string
  # metachars ($ for the stash marker) ride behind starship's backslash escape.
  m = lib.mapAttrs (_: r: lib.escape ["$"] (lib.removePrefix "[" (lib.removeSuffix "]" r.ascii))) roles.git;
  badges = projections.contextBadges;
  badgeRole = b: lib.last (lib.splitString "." b.role); # dotted theme path -> forge palette token (leaf names match)
in {
  programs.starship = {
    enable = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      # --- [GLOBAL_CONFIGURATION]
      palette = "forge";
      scan_timeout = 30; # File-scan budget (ms); context detection never blocks on large trees
      command_timeout = 500; # Module budget (ms); a slow module is dropped for one render, never awaited (vcs measures ~28ms dirty in this repo)
      continuation_prompt = "[❯](muted) ";
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$container"
        "$directory"
        "$vcs"
        "$fill"
        "$nix_shell"
        "$python"
        "$nodejs"
        "$dotnet"
        "$kubernetes"
        "$jobs"
        "$cmd_duration"
        "$status"
        "$line_break"
        "$character"
      ];

      # Scrollback law: past prompts collapse to HH:MM + pointer via this profile; the zsh hook swaps PROMPT on
      # zle-line-finish, so the collapsed line keeps exactly the pointer color the live prompt showed. Time rides the
      # left prompt — zle never paints RPROMPT during the finish repaint, so an rtransient profile cannot land.
      profiles.transient = "$time$character";

      # --- [SEMANTIC_ROLE_PALETTE]
      # Styles reference the estate roles by intent, never raw hue names; `syntax` carries string-yellow, the one hue
      # with no semantic role. Only tokens a module style consumes get a row.
      palettes.forge = {
        primary = roles.text.primary.hex;
        subtle = roles.text.subtle.hex;
        muted = roles.text.muted.hex;
        accent = roles.accent.primary.hex;
        accent2 = roles.accent.secondary.hex;
        structural = roles.accent.structural.hex;
        success = roles.state.success.hex;
        warning = roles.state.warning.hex;
        attention = roles.state.attention.hex;
        danger = roles.state.danger.hex;
        syntax = palette.yellow.hex;
      };

      # --- [CORE_MODULES]
      fill.symbol = " ";

      character = {
        success_symbol = "[❯](bold success)";
        error_symbol = "[❯](bold danger)";
        vimcmd_symbol = "[❮](bold success)";
        vimcmd_visual_symbol = "[❮](bold syntax)";
        vimcmd_replace_symbol = "[❮](bold accent2)";
        vimcmd_replace_one_symbol = "[❮](bold accent2)";
      };

      username = {
        show_always = false; # Renders only for root or over SSH
        style_user = "primary";
        style_root = "bold danger";
        format = "[$user]($style) ";
      };

      # Remote-host badge binds the shared context vocabulary (projections.contextBadges.remote) — wezterm's domain
      # strip and the yazi header read the same row, so a VPS file carries one identical badge on every surface.
      hostname = {
        ssh_only = true;
        ssh_symbol = "${badges.remote.glyph} ";
        style = "bold ${badgeRole badges.remote}";
        format = "[$ssh_symbol$hostname]($style) ";
      };

      # In-container badge (contextBadges.container): native detection fires only inside a linux container rootfs
      # (/run/.containerenv, /.dockerenv) — the macOS host never renders it; edits that die with the rootfs are the stakes.
      container = {
        symbol = "${badges.container.glyph} ";
        style = "bold ${badgeRole badges.container}";
        format = "[$symbol$name]($style) ";
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        truncation_symbol = "${glyph.ellipsis}/";
        home_symbol = "~";
        read_only = " 󰌾";
        read_only_style = "danger";
        style = "accent";
        before_repo_root_style = "muted"; # Ancestors dim, repo name carries the weight
        repo_root_style = "bold accent";
        repo_root_format = "[$before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
        format = "[$path]($style)[$read_only]($read_only_style) ";
        substitutions."~/Documents/99.Github" = "${glyph.github} ";
      };

      # --- [GIT_MODULES]
      # vcs composes the git payload with one repo-detection pass per prompt; four cooperating modules own one concern
      # each — branch identity, detached hash, in-progress operation, counted tree state. git_metrics is deliberately
      # absent: line churn is a passive magnitude meter, redundant with the file counts, banned from standing chrome.
      vcs = {
        disabled = false;
        order = ["git"];
        git_modules = "$git_branch$git_commit$git_state$git_status";
      };

      # Branch is a WORD: the name renders as text in its role color on every branch — trunk included — because the
      # word IS the information; no suppression, no symbol, ASCII truncation on the rare over-long name.
      git_branch = {
        style = "bold accent2";
        truncation_length = 24;
        truncation_symbol = "..";
        only_attached = true; # Detached HEAD hands the slot to git_commit
        format = "[$branch]($style) ";
      };

      git_commit = {
        only_detached = true;
        tag_disabled = false;
        tag_symbol = " #";
        style = "bold attention";
        format = "[@$hash$tag]($style) ";
      };

      # Transient in-progress operation: parens per the enclosure law, plain weight — self-clearing, never an anchor.
      git_state = {
        style = "attention";
        format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
      };

      # One outer bracket, semiotic marker grammar: the cluster reads `main [ ~69 +10 ?12 ^3 ]` — each state is a
      # space-terminated `<marker><count>` token whose marker char is the theme vocabulary's ASCII register, and one
      # muted bracket pair (symmetric inner padding) encloses the whole readout. Color collapses to four meaning-bins —
      # staged=success (index, ready), worktree=subtle (the marker distinguishes state), conflict=bold danger (the sole
      # alarm on the line), sync topology=accent — with stash receding on the muted text tier alongside the brackets.
      # Clean renders nothing and the paren group vanishes gap-free.
      git_status = {
        format = "([\\[ ](muted)$all_status$ahead_behind[\\]](muted) )";
        conflicted = "[${m.conflict}$count ](bold danger)";
        stashed = "[${m.stashed}$count ](muted)";
        deleted = "[${m.deleted}$count ](subtle)";
        renamed = "[${m.renamed}$count ](subtle)";
        modified = "[${m.modified}$count ](subtle)";
        typechanged = "[${m.typechange}$count ](subtle)";
        staged = "[${m.staged}$count ](success)";
        untracked = "[${m.untracked}$count ](subtle)";
        ahead = "[${m.ahead}$count ](accent)";
        behind = "[${m.behind}$count ](accent)";
        diverged = "[${m.ahead}$ahead_count ${m.behind}$behind_count ](accent)";
      };

      # --- [CONTEXT_MODULES]
      nix_shell = {
        symbol = "${icons.process.nix} ";
        style = "structural";
        heuristic = false;
        format = "[$symbol$state( $name)]($style) ";
      };

      # direnv is deliberately absent: the binary ships nowhere in the estate (nix-direnv rides the unratified adoption
      # menu), so the blocked/denied footgun row could never fire; it returns as one row with that adoption.
      # Toolchain hierarchy: the symbol keeps its brand hue, the version tail dims to subtle — static facts recede
      # under the live git state.
      python = {
        symbol = "${icons.process.python} ";
        style = "syntax";
        version_format = "v\${major}.\${minor}";
        format = "[$symbol]($style)[($version)](subtle)[( \\($virtualenv\\))](subtle) ";
        detect_extensions = ["py"];
        detect_files = [".python-version" "Pipfile" "pyproject.toml" "requirements.txt"];
        detect_folders = ["__pycache__" ".venv" "venv"];
      };

      nodejs = {
        symbol = "${icons.process.node} ";
        style = "success";
        not_capable_style = "danger";
        version_format = "v\${major}";
        format = "[$symbol]($style)[($version)](subtle) ";
        detect_extensions = ["js" "mjs" "cjs" "ts" "mts" "cts"];
        detect_files = ["package.json" ".node-version" ".nvmrc"];
        detect_folders = ["node_modules"];
      };

      dotnet = {
        symbol = "${glyph.dotnet} ";
        style = "structural";
        version_format = "v\${major}";
        format = "[$symbol]($style)[($version)](subtle) ";
      };

      # docker_context is deliberately absent: the estate exports DOCKER_HOST=unix://... (colima) into every session,
      # and starship hard-hides the module for unix-socket contexts — the row could never render on either host.
      # Context-gated: visible only where kube work is provable in the directory (manifests, chart/kustomize roots);
      # prod contexts go danger. No detect_env_vars row — scan config present makes it dead (Option::or short-circuits),
      # and the estate exports KUBECONFIG globally, so an env gate would carry zero directory signal anyway.
      kubernetes = {
        disabled = false;
        symbol = "󱃾 ";
        style = "structural";
        detect_files = ["skaffold.yaml" "helmfile.yaml" "Chart.yaml" "kustomization.yaml"];
        detect_folders = ["k8s" "kubernetes" "manifests"];
        format = "[$symbol$context( \\($namespace\\))]($style) ";
        contexts = [
          {
            context_pattern = ".*(prod|prd).*";
            style = "bold danger";
          }
        ];
      };

      # --- [TELEMETRY_MODULES]
      jobs = {
        symbol = "${icons.alphabet.running.glyph} ";
        style = "accent";
        number_threshold = 1;
        symbol_threshold = 1;
        format = "[$symbol$number]($style) ";
      };

      cmd_duration = {
        min_time = 2000;
        style = "warning";
        show_notifications = true;
        min_time_to_notify = 45000;
        format = "[󱎫 $duration]($style) ";
      };

      # Exit truth in the marker register: a discrete atomic event earns the brackets — code plus meaning ([X 130 INT],
      # [X 127 NOTFOUND]); pipelines surface every stage ([X 0|1]) through the segment projection.
      status = {
        disabled = false;
        symbol = "${icons.alphabet.failure.glyph} ";
        style = "bold danger";
        recognize_signal_code = true;
        map_symbol = false;
        pipestatus = true;
        pipestatus_separator = "|";
        pipestatus_format = "[\\[$symbol$pipestatus\\]]($style) ";
        pipestatus_segment_format = "[$status]($style)";
        format = "[\\[$symbol$status( $common_meaning)( $signal_name)\\]]($style) ";
      };

      # Rendered only through the transient profile: scrollback rows carry the estate display-time grammar.
      time = {
        disabled = false;
        style = "muted";
        time_format = projections.timeDisplay.sameDay;
        format = "[$time]($style) ";
      };
    };
  };
}
