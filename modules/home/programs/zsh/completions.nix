{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette projections;

  completionPackages = [pkgs.zsh-completions pkgs.nix-zsh-completions];
  siteFunctions =
    map (p: "${p}/share/zsh/site-functions") completionPackages
    ++ [
      "/etc/profiles/per-user/${config.home.username}/share/zsh/site-functions"
      "/opt/homebrew/share/zsh/site-functions"
    ];

  fingerprint =
    builtins.substring 0 12 (builtins.hashString "sha256"
      (builtins.toJSON (map toString (completionPackages ++ config.home.packages))));

  cacheDir = "${config.xdg.cacheHome}/zsh";

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
      context = ":fzf-tab:complete:(ls|eza|bat|cat|vim|code):*";
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
in {
  programs.zsh = {
    completionInit = ''
      autoload -U compinit
      compinit -C -d "$ZSH_COMPDUMP"
      if [[ ! -f $ZSH_COMPDUMP.zwc || $ZSH_COMPDUMP -nt $ZSH_COMPDUMP.zwc ]]; then
        {
          setopt extended_glob
          zcompile "$ZSH_COMPDUMP"
          rm -f -- ${cacheDir}/zcompdump-''${ZSH_VERSION}-*~$ZSH_COMPDUMP*(N)
        } &!
      fi
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
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      '')
    ];
  };
}
