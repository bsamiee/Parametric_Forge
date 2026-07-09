# Title         : completions.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/completions.nix
# ----------------------------------------------------------------------------
# Completion owner: generator rows written atomically at activation, one
# fingerprint-keyed compinit that never rescans per shell, data-driven zstyle
# rows, and the fzf-tab completion UI. A new completion is a row here.
{
  config,
  lib,
  pkgs,
  ...
}: let
  brewPrefix = "/opt/homebrew";

  # Generator rows: `version` is the staleness key — a Nix store path for
  # store-owned tools, a runtime probe for host apps. `gate` skips a row when
  # the host binary is absent.
  generators = [
    {
      name = "zellij";
      version = "${pkgs.zellij}";
      command = "${pkgs.zellij}/bin/zellij setup --generate-completion zsh";
    }
    {
      name = "atuin";
      version = "${pkgs.atuin}";
      command = "${pkgs.atuin}/bin/atuin gen-completions --shell zsh";
    }
    {
      name = "op";
      version = "${pkgs._1password-cli}";
      command = "${pkgs._1password-cli}/bin/op completion zsh";
    }
    {
      name = "wezterm";
      version = "$(${brewPrefix}/bin/wezterm --version)";
      command = "${brewPrefix}/bin/wezterm shell-completion --shell zsh";
      gate = "[[ -x ${brewPrefix}/bin/wezterm ]]";
    }
  ];

  # Package rows whose share/zsh/site-functions precede compinit on fpath.
  completionPackages = [pkgs.zsh-completions];

  # Dump key: any change to the completion file set retires every old dump at
  # activation; compinit -C rebuilds once per fingerprint, never per shell.
  fingerprint =
    builtins.substring 0 12 (builtins.hashString "sha256"
      (builtins.toJSON (map (g: g.version) generators ++ map toString completionPackages)));

  compDir = "${config.xdg.dataHome}/zsh/completions";
  verDir = "${config.xdg.dataHome}/zsh/.completion-versions";
  cacheDir = "${config.xdg.cacheHome}/zsh";

  # zstyle rows: `value` lands verbatim after the key. Completion behavior,
  # carapace bridge spacing, and fzf-tab UI are one vocabulary.
  styles = [
    {
      context = ":completion:*";
      key = "matcher-list";
      value = "'m:{[:lower:][:upper:]}={[:upper:][:lower:]}'";
    }
    {
      context = ":completion:*";
      key = "use-cache";
      value = "true";
    }
    {
      context = ":completion:*";
      key = "cache-path";
      value = "\"$XDG_CACHE_HOME/zsh/zcompcache\"";
    }
    {
      context = ":completion:*";
      key = "menu";
      value = "no";
    }
    {
      context = ":completion:*";
      key = "group-name";
      value = "''";
    }
    {
      context = ":completion:*:descriptions";
      key = "format";
      value = "'[%d]'";
    }
    {
      context = ":completion:*";
      key = "accept-exact-dirs";
      value = "true";
    }
    {
      context = ":completion:*";
      key = "special-dirs";
      value = "true";
    }
    {
      context = ":completion:*";
      key = "squeeze-slashes";
      value = "true";
    }
    {
      context = ":completion:*";
      key = "list-colors";
      value = "\${(s.:.)LS_COLORS}";
    }
    {
      context = ":carapace:*";
      key = "nospace";
      value = "true";
    }
    {
      context = ":fzf-tab:*";
      key = "fzf-flags";
      value = "--height=80% --layout=reverse --border=sharp";
    }
    {
      context = ":fzf-tab:*";
      key = "fzf-pad";
      value = "4";
    }
    {
      context = ":fzf-tab:*";
      key = "switch-group";
      value = "'<' '>'";
    }
    {
      context = ":fzf-tab:complete:(cd|__zoxide_z):*";
      key = "fzf-preview";
      value = "'eza -1 --color=always --icons=always $realpath'";
    }
    {
      context = ":fzf-tab:complete:(ls|eza|bat|cat|nvim|vim|code):*";
      key = "fzf-preview";
      value = "'[[ -d $realpath ]] && eza -la --color=always --icons=always $realpath || bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null'";
    }
    {
      context = ":fzf-tab:complete:kill:*";
      key = "fzf-preview";
      value = "'ps -p $word -o pid,ppid,stat,command 2>/dev/null'";
    }
    {
      context = ":fzf-tab:complete:(-parameter-|-brace-parameter-|export|unset|expand):*";
      key = "fzf-preview";
      value = "'echo \${(P)word}'";
    }
  ];

  zstyleLines = lib.concatMapStringsSep "\n" (r: "zstyle '${r.context}' ${r.key} ${r.value}") styles;

  # Activation writer: atomic per-row regeneration keyed on `version`, then
  # retirement of dumps from earlier completion file sets.
  completionWriter = pkgs.writeShellApplication {
    name = "forge-zsh-completions";
    runtimeInputs = [pkgs.coreutils pkgs.findutils];
    text = ''
      comp_dir=${lib.escapeShellArg compDir}
      ver_dir=${lib.escapeShellArg verDir}
      cache_dir=${lib.escapeShellArg cacheDir}
      mkdir -p "$comp_dir" "$ver_dir" "$cache_dir"

      regen() {
        local name="$1" version="$2" tmp
        shift 2
        local ver_file="$ver_dir/$name"
        if [[ -f "$comp_dir/_$name" && -f "$ver_file" && "$(<"$ver_file")" == "$version" ]]; then
          return 0
        fi
        tmp="$(mktemp "$comp_dir/.forge-$name.XXXXXX")"
        if "$@" >"$tmp" 2>/dev/null; then
          mv -f "$tmp" "$comp_dir/_$name"
          printf '%s\n' "$version" >"$ver_file"
        else
          rm -f "$tmp"
        fi
      }

      ${lib.concatMapStringsSep "\n" (
          g:
            if g ? gate
            then "if ${g.gate}; then\n        regen ${g.name} \"${g.version}\" ${g.command}\n      fi"
            else "regen ${g.name} \"${g.version}\" ${g.command}"
        )
        generators}

      # One owner: files outside the generator table are retired litter.
      managed=" ${lib.concatMapStringsSep " " (g: g.name) generators} "
      for f in "$comp_dir"/_*; do
        [[ -e "$f" ]] || continue
        name="''${f##*/_}"
        if [[ "$managed" != *" $name "* ]]; then
          rm -f "$f" "$ver_dir/$name"
        fi
      done

      find "$cache_dir" -maxdepth 1 -name 'zcompdump-*' ! -name '*-${fingerprint}*' -delete
    '';
  };
in {
  home.activation.forgeZshCompletions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${completionWriter}/bin/forge-zsh-completions
  '';

  programs.zsh = {
    enableCompletion = true;
    # -C trusts the fingerprint-keyed dump: activation owns invalidation, so
    # no interactive shell ever pays the fpath rescan or compaudit walk.
    completionInit = ''
      autoload -U compinit
      compinit -C -d "$ZSH_COMPDUMP"
      {
        if [[ ! -f "$ZSH_COMPDUMP.zwc" || "$ZSH_COMPDUMP" -nt "$ZSH_COMPDUMP.zwc" ]]; then
          zcompile "$ZSH_COMPDUMP"
        fi
      } &!
    '';

    initContent = lib.mkMerge [
      (lib.mkOrder 400 ''
        # --- Completion fpath + fingerprint-keyed dump (before compinit) ----------
        command mkdir -p -- "${cacheDir}"
        export ZSH_COMPDUMP="${cacheDir}/zcompdump-''${ZSH_VERSION}-${fingerprint}"
        fpath=("${compDir}" ${lib.concatMapStringsSep " " (p: "${p}/share/zsh/site-functions") completionPackages} $fpath)
      '')

      (lib.mkOrder 550 ''
        # --- Completion + fzf-tab zstyle rows (rendered from the style table) -----
        ${zstyleLines}
      '')

      (lib.mkOrder 580 ''
        # --- fzf-tab (after compinit at 570, before widget wrappers at 700+) ------
        # No use-fzf-default-opts: global FZF_DEFAULT_OPTS previews stay out of
        # completion; the fzf-flags row above is the whole completion-UI surface.
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      '')
    ];
  };
}
