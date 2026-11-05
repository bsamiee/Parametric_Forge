# Title         : toolchain-env.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/common/toolchain-env.nix
# ----------------------------------------------------------------------------
# The one PATH vector and toolchain env factory installed as the toolchainEnvFor module argument; the system environment, the GUI launchd
# replay, and the zsh floor call it with their own home/username/XDG context.
{
  lib,
  pkgs,
  ...
}: {
  _module.args.toolchainEnvFor = {
    home,
    username,
    xdgCacheHome,
    xdgConfigHome ? "${home}/.config", # XDG default; env and PATH owners pass their scope's configHome, font-only callers inherit.
    xdgDataHome ? "${home}/.local/share", # Same convention: the shim segment reads it.
    xdgStateHome ? "${home}/.local/state", # Same convention: the interactive history rows read it.
  }: let
    # Rhino's command directory, the link default-applications.nix keeps on the installed bundle: nix-darwin writes this vector unquoted into
    # set-environment, so a bundle name with a space cannot be an entry, and the bundle's scripts locate it from their own directory, so the
    # link is the directory rather than each script.
    rhinoBin = "${xdgDataHome}/rhino/bin";
    # Only provisioned directories: useUserPackages replaces ~/.nix-profile with /etc/profiles; cargo/go user bins return once provisioned.
    userPathEntries = [
      "${home}/.local/bin"
      "/etc/profiles/per-user/${username}/bin"
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
      "/opt/homebrew/bin"
      rhinoBin
      # carapace's zsh snippet prepends this directory unless PATH already holds it; listing it here keeps the vector the one PATH owner.
      "${xdgConfigHome}/carapace/bin"
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
    # whose tool has no version there execs the next copy on PATH. A shell that applies mise (zsh at startup, every Claude Code command
    # through its user settings) drops this segment and puts a project's install paths first.
    shimPath = "${xdgDataHome}/mise/shims";
    pathEntries = [shimPath] ++ userPathEntries ++ fallbackPathEntries;
    # EnergyPlus/OpenStudio layout facts fold from each package's manifest-derived runtimeEnv.
    energyEnv = pkgs.energyplus.runtimeEnv // pkgs.openstudio.runtimeEnv;
    # One class-partitioned env owner: `all` rows feed nix-darwin's set-environment (every zsh and bash), the .zshenv never-clobber floor, and the
    # GUI launchd replay, byte-identical everywhere so a shell of any kind and a Dock-launched agent never resolve divergent editor/pager/config env;
    # `session` rows are interactive-only (man/bat/info/sqlite/node). Every row moves a tool off a non-XDG default or names a fact its config file
    # cannot: gh, gcloud, gws, bat, starship, and WezTerm already read the XDG paths, git's pager is the delta git integration, gh's pager is
    # its own config key. A new cross-surface var is one `all` row. No row configures a language toolchain, package manager, or build tool: a
    # repository's own files and mise [env] own how its builds, checks, and tests behave.
    # One font root list feeds fontconfig's fonts.conf (media.nix) and Typst, which reads no fontconfig; the design store is operator-owned.
    fontDirectories = [
      "/System/Library/Fonts"
      "/Library/Fonts"
      "${home}/Library/Fonts"
      "${home}/Library/Application Support/design-tools/fonts"
    ];
    envByClass = {
      all = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        PAGER = "less";
        LESS = "-RFX";
        GOOGLE_WORKSPACE_PROJECT_ID = "workspace-mcp-500605";
        # fontconfig consumers (fc-*, magick, vips text, gs, Pango) and Typst each resolve fonts through one of these two rows on every surface.
        FONTCONFIG_FILE = "${xdgConfigHome}/fontconfig/fonts.conf";
        TYPST_FONT_PATHS = lib.concatStringsSep ":" fontDirectories;
        QSV_CACHE_DIR = "${xdgCacheHome}/qsv"; # qsv validate and dynamicEnum lookups; the default is ~/.qsv-cache
        # Doppler's login and scope store defaults to ~/.doppler, and a Doppler run starts outside a login shell
        DOPPLER_CONFIG_DIR = "${xdgConfigHome}/doppler";
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
      rhinoBin
      ;

    inherit pathEntries shimPath;
    # Rows every surface carries: set-environment for every shell kind, the GUI launchd domain, and the .zshenv floor; the session class is
    # interactive-only and stays in Home Manager.
    sharedEnv = energyEnv // envByClass.all;
    sessionEnv = envByClass.session;
  };
}
