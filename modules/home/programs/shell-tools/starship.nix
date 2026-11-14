{
  config,
  lib,
  ...
}: let
  inherit (config.forge.theme) roles palette icons projections;

  glyph = lib.mapAttrs (_: c: builtins.fromJSON ''"\u${c}"'') {
    ellipsis = "EA7C";
    github = "EA84";
    dotnet = "E77F";
  };
  m = lib.mapAttrs (_: r: lib.escape ["$"] (lib.removePrefix "[" (lib.removeSuffix "]" r.ascii))) roles.git;
  badges = projections.contextBadges;
  badgeRole = b: lib.last (lib.splitString "." b.role);
in {
  programs.starship = {
    enable = true;
    validateFiles.config = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      # --- [GLOBAL_CONFIGURATION]
      palette = "forge";
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
        "$jobs"
        "$cmd_duration"
        "$status"
        "$line_break"
        "$character"
      ];

      # --- [SEMANTIC_ROLE_PALETTE]
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
        info = roles.state.info.hex;
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
        style_user = "primary";
        style_root = "bold danger";
        format = "[$user]($style) ";
      };

      hostname = {
        ssh_symbol = "${badges.remote.glyph} ";
        style = "bold ${badgeRole badges.remote}";
        format = "[$ssh_symbol$hostname]($style) ";
      };

      container = {
        symbol = "${badges.container.glyph} ";
        style = "bold ${badgeRole badges.container}";
        format = "[$symbol$name]($style) ";
      };

      directory = {
        truncation_symbol = "${glyph.ellipsis}/";
        read_only = " 󰌾";
        read_only_style = "danger";
        style = "accent";
        before_repo_root_style = "muted";
        repo_root_style = "bold accent";
        substitutions."~/Developer" = "${glyph.github} ";
      };

      # --- [GIT_MODULES]
      vcs = {
        order = ["git"];
        git_modules = "$git_branch$git_commit$git_state$git_status";
      };

      git_branch = {
        style = "bold accent2";
        truncation_length = 24;
        truncation_symbol = "..";
        only_attached = true;
        format = "[$branch]($style) ";
      };

      git_commit = {
        tag_disabled = false;
        tag_symbol = " #";
        style = "bold attention";
        format = "[@$hash$tag]($style) ";
      };

      git_state.style = "attention";

      git_status = {
        format = "([\\[ ](muted)$all_status$ahead_behind[\\]](muted) )";
        conflicted = "[${m.conflict}$count ](bold accent2)";
        stashed = "[${m.stashed}$count ](muted)";
        deleted = "[${m.deleted}$count ](danger)";
        renamed = "[${m.renamed}$count ](structural)";
        modified = "[${m.modified}$count ](info)";
        typechanged = "[${m.typechange}$count ](info)";
        staged = "[${m.staged}$count ](success)";
        untracked = "[${m.untracked}$count ](success)";
        ahead = "[${m.ahead}$count ](accent)";
        behind = "[${m.behind}$count ](accent)";
        diverged = "[${m.ahead}$ahead_count ${m.behind}$behind_count ](accent)";
      };

      # --- [CONTEXT_MODULES]
      nix_shell = {
        symbol = "${icons.process.nix} ";
        style = "structural";
        format = "[$symbol$state( $name)]($style) ";
      };

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
      };

      dotnet = {
        symbol = "${glyph.dotnet} ";
        style = "structural";
        version_format = "v\${major}";
        format = "[$symbol]($style)[($version)](subtle) ";
      };

      # --- [TELEMETRY_MODULES]
      jobs = {
        symbol = "${icons.alphabet.running.glyph} ";
        style = "accent";
        number_threshold = 1;
      };

      cmd_duration = {
        style = "warning";
        format = "[󱎫 $duration]($style) ";
      };

      status = {
        disabled = false;
        symbol = "${icons.alphabet.failure.glyph} ";
        style = "bold danger";
        pipestatus = true;
        pipestatus_format = "[\\[$symbol$pipestatus\\]]($style) ";
        pipestatus_segment_format = "[$status]($style)";
        format = "[\\[$symbol$status( $common_meaning)( $signal_name)\\]]($style) ";
      };
    };
  };
}
