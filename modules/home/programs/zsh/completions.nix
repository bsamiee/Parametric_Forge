# Title         : completions.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/completions.nix
# ----------------------------------------------------------------------------
# Completion owner: the fpath surface (profile and package site-functions, Homebrew's on Darwin), one fingerprint-keyed compinit that never
# rescans per shell, data-driven zstyle rows, and the fzf-tab completion UI. Every completion file ships with its package: the Nix profile
# holds _atuin, _op, _zellij, and the rest; Homebrew's site-functions holds _wezterm and _container.
{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette projections;

  # Package rows whose share/zsh/site-functions precede compinit on fpath.
  completionPackages = [pkgs.zsh-completions];
  siteFunctions =
    map (p: "${p}/share/zsh/site-functions") completionPackages
    ++ ["/etc/profiles/per-user/${config.home.username}/share/zsh/site-functions"]
    ++ lib.optional (host.os == "darwin") "/opt/homebrew/share/zsh/site-functions";

  # Dump key: the pre-compinit fpath surface — completion packages, sourced-plugin srcs, and the profile package set. The per-user profile
  # site-functions dir is pinned into the 400 row below: a dump baked by a degraded-env shell (NIX_PROFILES without /etc/profiles/per-user)
  # otherwise permanently misses home.packages completions under compinit -C. Any change retires every old dump at activation; compinit -C
  # rebuilds once per fingerprint, never per shell.
  fingerprint = builtins.substring 0 12 (builtins.hashString "sha256"
    (builtins.toJSON (map toString (completionPackages
      ++ map (p: p.src) config.programs.zsh.plugins
      ++ config.home.packages))));

  cacheDir = "${config.xdg.cacheHome}/zsh";

  # File-kind completion colors: theme truecolor per type, consumed by both zsh complist and fzf-tab's colorize path. A new file kind is one row.
  tc = c: "38;2;${toString c.r};${toString c.g};${toString c.b}";
  listColors = lib.concatStringsSep ":" [
    "di=1;${tc palette.cyan}"
    "ln=${tc palette.magenta}"
    "or=${tc palette.red}"
    "mi=${tc palette.red}"
    "ex=${tc palette.green}"
    "so=${tc palette.yellow}"
    "pi=${tc palette.yellow}"
    "bd=${tc palette.yellow}"
    "cd=${tc palette.yellow}"
    "su=${tc palette.orange}"
    "sg=${tc palette.orange}"
    "tw=${tc palette.orange}"
    "ow=${tc palette.orange}"
    "st=${tc palette.orange}"
  ];

  # zstyle rows: `value` lands verbatim after the key. Completion behavior and the fzf-tab UI are one vocabulary.
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
      value = "'${listColors}'";
    }
    {
      context = ":fzf-tab:*";
      key = "fzf-flags";
      # fzf-tab clears FZF_DEFAULT_OPTS for its child fzf, so the completion UI carries the theme owner's fzf color vocabulary itself.
      value = lib.concatStringsSep " " ([
          "--height=80%"
          "--layout=reverse"
          "--border=sharp"
          "--highlight-line"
          "--prompt='❯ '"
          "--pointer='❯'"
          "--marker='✓'"
        ]
        ++ projections.fzfColorRows);
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

  # Activation: retire dumps from earlier fingerprints and the pre-fingerprint generations that dumped into ZDOTDIR.
  dumpRetirement = pkgs.writeShellApplication {
    name = "forge-zsh-compdump-retire";
    runtimeInputs = [pkgs.coreutils pkgs.findutils];
    text = ''
      cache_dir=${lib.escapeShellArg cacheDir}
      mkdir -p "$cache_dir"
      find "$cache_dir" -maxdepth 1 -name 'zcompdump-*' ! -name '*-${fingerprint}*' -delete
      rm -f ${lib.escapeShellArg config.programs.zsh.dotDir}/.zcompdump*
    '';
  };
in {
  home.activation.forgeZshCompletions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${dumpRetirement}/bin/forge-zsh-compdump-retire
  '';

  programs.zsh = {
    # -C trusts the fingerprint-keyed dump: activation owns invalidation, so no interactive shell ever pays the fpath rescan or compaudit walk.
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
        # --- [FPATH_PREINIT]
        export ZSH_COMPDUMP="${cacheDir}/zcompdump-''${ZSH_VERSION}-${fingerprint}"
        fpath=(${lib.concatMapStringsSep " " (d: "\"${d}\"") siteFunctions} $fpath)
      '')

      (lib.mkOrder 550 ''
        # --- [ZSTYLE_ROWS]
        ${zstyleLines}
      '')

      (lib.mkOrder 580 ''
        # --- [FZF_TAB_SOURCE]
        # No use-fzf-default-opts: global FZF_DEFAULT_OPTS previews stay out of completion; the fzf-flags row above is the whole completion-UI
        # surface. Sourced before fzf's own init (910) so fzf captures fzf-tab's ^I widget as fzf_default_completion: plain Tab lands in fzf-tab,
        # the ** trigger keeps fzf path completion.
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      '')
    ];
  };
}
