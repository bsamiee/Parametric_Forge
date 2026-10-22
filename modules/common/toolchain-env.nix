# Title         : toolchain-env.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/common/toolchain-env.nix
# ----------------------------------------------------------------------------
# Shared PATH vectors and toolchain env factory installed as the toolchainEnvFor module argument; session, launchd,
# and zsh owners call it with their own home/username/cache context.
{
  lib,
  pkgs,
  ...
}: {
  _module.args.toolchainEnvFor = {
    home,
    username,
    xdgCacheHome,
    xdgConfigHome ? "${home}/.config", # XDG default; session/resilient/launchd owners pass their scope's configHome, PATH-only callers inherit.
    xdgDataHome ? "${home}/.local/share", # Same convention: the shim segment reads it, so a PATH-only caller inherits the XDG default.
    xdgStateHome ? "${home}/.local/state", # Same convention: the interactive history rows read it.
  }: let
    # The operator-installed Rhino bundle no cask owns: its bin directory joins the PATH vector, and its default handler rows read the bundle path.
    rhinoApp = "/Applications/RhinoBETA.app";
    # Only provisioned directories: useUserPackages replaces ~/.nix-profile with /etc/profiles; cargo/go user bins return once provisioned.
    userPathEntries = [
      "${home}/.local/bin"
      "/etc/profiles/per-user/${username}/bin"
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
      "${rhinoApp}/Contents/Resources/bin"
    ];
    fallbackPathEntries = [
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ];
    # First segment of every vector, as mise documents for processes without `mise activate`: a login shell, a launchd agent, a GUI app, and a
    # process its multiplexer starts without a shell resolve a project's pinned tool from the caller's directory, and outside a project a shim
    # whose tool has no version there execs the next copy on PATH. A shell that applies `mise hook-env` (zsh at startup, every Claude Code
    # command through CLAUDE_ENV_FILE) drops this segment and puts a project's install paths first.
    shimPathEntries = ["${xdgDataHome}/mise/shims"];
    pathEntries = shimPathEntries ++ userPathEntries ++ fallbackPathEntries;
    # macOS default is ~/.matplotlib; the directory holds font and tex caches, no rc file
    pythonEnv.MPLCONFIGDIR = "${xdgCacheHome}/matplotlib";
    # Runtime data for the geo CLI roster: PROJ 9.1 renamed PROJ_LIB to PROJ_DATA, which libproj consults first, so the old name carries no row.
    # The Nix PROJ_DATA ships no datum grids; PROJ_NETWORK streams them from cdn.proj.org into the XDG data cache (300 MB cap).
    geoEnv = {
      PROJ_DATA = "${pkgs.proj}/share/proj";
      PROJ_NETWORK = "ON";
    };
    # EnergyPlus/OpenStudio layout facts fold from each package's manifest-derived runtimeEnv.
    energyEnv = pkgs.energyplus.runtimeEnv // pkgs.openstudio.runtimeEnv;
    # One class-partitioned env owner feeding the session (home.sessionVariables), the .zshenv never-clobber floor, and the launchd GUI surfaces.
    # `all` rows land byte-identical everywhere so an interactive shell and a Dock-launched agent never resolve divergent pager/config env;
    # `session` rows are interactive-only (man/bat/info/sqlite/node). Every row moves a tool off a non-XDG default or names a fact its config file
    # cannot: gh, gcloud, gws, bat, starship, and WezTerm already read the XDG paths, git's pager is the delta git integration, gh's pager is
    # its own config key. A new cross-surface var is one `all` row.
    # One font root list feeds fontconfig's fonts.conf (media.nix) and Typst, which reads no fontconfig; the design store is operator-owned.
    fontDirectories = [
      "/System/Library/Fonts"
      "/Library/Fonts"
      "${home}/Library/Fonts"
      "${home}/Library/Application Support/design-tools/fonts"
    ];
    envByClass = {
      all = {
        PAGER = "less";
        LESS = "-RFX";
        GOOGLE_WORKSPACE_PROJECT_ID = "workspace-mcp-500605";
        # fontconfig consumers (fc-*, magick, vips text, gs, Pango) and Typst each resolve fonts through one of these two rows on every surface.
        FONTCONFIG_FILE = "${xdgConfigHome}/fontconfig/fonts.conf";
        TYPST_FONT_PATHS = lib.concatStringsSep ":" fontDirectories;
        QSV_CACHE_DIR = "${xdgCacheHome}/qsv"; # qsv validate and dynamicEnum lookups; the default is ~/.qsv-cache
        # npm's cache, the Pulumi CLI home (plugins, workspaces, credentials, logs), and Doppler's login and scope store default to ~/.npm,
        # ~/.pulumi, and ~/.doppler. An editor's type acquisition runs npm from the GUI domain and a Pulumi or Doppler run starts outside a
        # login shell, a project's [env] row wins through the floor.
        npm_config_cache = "${xdgCacheHome}/npm";
        PULUMI_HOME = "${xdgDataHome}/pulumi";
        DOPPLER_CONFIG_DIR = "${xdgConfigHome}/doppler";
        # CPython mirrors bytecode under the prefix in place of __pycache__ beside each source, a project's [env] row wins through the floor
        PYTHONPYCACHEPREFIX = "${xdgCacheHome}/python";
        # Claude Code restores the PATH its session-start shell snapshot captured in every Bash command, then runs this file: hook-env reverts the
        # launch shell's mise diff and applies the current directory's tools and [env] rows, so each command sees mise state as it is now. The
        # body names mise through that PATH and holds no store path, so every generation carries the same file and an inherited value stays
        # current; under zsh, a no-op compdef makes the guard in mise's completion block skip compinit.
        CLAUDE_ENV_FILE = builtins.toFile "mise-hook-env.sh" ''
          if [ -n "''${ZSH_VERSION:-}" ]; then
            (( $+functions[compdef] )) || compdef() { :; }
            eval "$(mise hook-env -s zsh)"
          else
            eval "$(mise hook-env -s bash)"
          fi
        '';
      };
      session = {
        BAT_PAGER = "less -RFXK"; # -X fixes macOS Terminal.app clearing
        MANPAGER = "env BATMAN_IS_BEING_MANPAGER=yes bash ${pkgs.bat-extras.batman}/bin/batman"; # static batman export-env, no per-shell fork
        SQLITE_HISTORY = "${xdgStateHome}/sqlite/history"; # sqlite3's default is ~/.sqlite_history
        NODE_REPL_HISTORY = "${xdgStateHome}/node_repl_history"; # the node REPL's default is ~/.node_repl_history
        # The one `brew shellenv` row PATH resolution does not cover: macOS manpath derives /opt/homebrew/share/man from /opt/homebrew/bin,
        # GNU info reads INFOPATH alone; the trailing colon appends info's built-in directories.
        INFOPATH = "/opt/homebrew/share/info:";
      };
    };
    # Never-clobber floor: a row exports only where the caller left it unset or empty, so a scoped value (`doppler run`, a project's [env])
    # survives every zsh child, and a shell whose parent scrubbed the env behind __HM_SESS_VARS_SOURCED recovers it; the fold owns the :- idiom.
    floorExports = env:
      lib.concatStrings (
        lib.mapAttrsToList (name: value: ''
          export ${name}="''${${name}:-${toString value}}"
        '')
        env
      );
  in {
    inherit
      floorExports
      fontDirectories
      rhinoApp
      ;

    sessionPathEntries = pathEntries;
    launchdPathEntries = pathEntries;
    scientificSessionEnv = pythonEnv // geoEnv // energyEnv;
    sessionEnv = envByClass.all // envByClass.session;
    launchdEnv = envByClass.all;
  };
}
