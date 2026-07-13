# Title         : toolchain-env.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/common/toolchain-env.nix
# ----------------------------------------------------------------------------
# Shared PATH vectors and toolchain env factory installed as the forgeToolchainEnvFor module argument; session, launchd,
# and zsh owners call it with their own home/username/cache context.
{
  host,
  lib,
  pkgs,
  ...
}: {
  _module.args.forgeToolchainEnvFor = {
    home,
    username,
    xdgCacheHome,
    xdgConfigHome ? "${home}/.config", # XDG default; session/resilient/launchd owners pass their scope's configHome, PATH-only callers inherit.
  }: let
    isDarwin = host.os == "darwin"; # OS branch keys on the static host context, never on pkgs (fixpoint safety).
    # Only provisioned directories: useUserPackages replaces ~/.nix-profile with /etc/profiles; cargo/go user bins return once provisioned.
    userPathEntries =
      [
        "${home}/.local/bin"
        "${home}/bin"
        "${home}/.dotnet/tools"
        "/etc/profiles/per-user/${username}/bin"
        "/run/current-system/sw/bin"
        "/nix/var/nix/profiles/default/bin"
      ]
      ++ lib.optionals isDarwin [
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
        "/Applications/Rhino 8.app/Contents/Resources/bin"
      ];
    fallbackPathEntries = [
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ];
    pythonEnv =
      {
        PYTEST_CACHE_DIR = "${xdgCacheHome}/pytest";
        RUFF_CACHE_DIR = "${xdgCacheHome}/ruff";
        PYLINTHOME = "${xdgCacheHome}/pylint";
        NOX_CACHE_DIR = "${xdgCacheHome}/nox";
        UV_CACHE_DIR = "${xdgCacheHome}/uv";
        UV_PYTHON_PREFERENCE = "only-system";
        UV_PYTHON_DOWNLOADS = "never";
        PYTHONDONTWRITEBYTECODE = "1";
        CRC32C_INSTALL_PREFIX = "${pkgs.crc32c}";
      }
      // lib.optionalAttrs isDarwin {
        MACOSX_DEPLOYMENT_TARGET = pkgs.stdenv.hostPlatform.darwinMinVersion or "14.0";
      };
    geoEnv = {
      GDAL_CONFIG = "${pkgs.gdal}/bin/gdal-config";
      GDAL_DATA = "${pkgs.gdal}/share/gdal";
      GEOS_CONFIG = "${pkgs.geos}/bin/geos-config";
      PROJ_DATA = "${pkgs.proj}/share/proj";
      PROJ_DIR = "${pkgs.proj}";
      PROJ_INCDIR = "${pkgs.proj.dev}/include";
      PROJ_LIB = "${pkgs.proj}/share/proj";
      PROJ_LIBDIR = "${pkgs.proj}/lib";
    };
    # EnergyPlus/OpenStudio are macOS-only (operator ruling); Linux hosts get an empty energy row, so downstream folds and exports stay
    # polymorphic. Layout facts fold from each package's manifest-derived runtimeEnv; the session EXE keys re-point at the env-exporting wrappers.
    energyEnv = lib.optionalAttrs isDarwin (
      pkgs.energyplus.runtimeEnv
      // pkgs.openstudio.runtimeEnv
      // {
        ENERGYPLUS_EXE = lib.getExe pkgs.energyplus;
        OPENSTUDIO_EXE = lib.getExe pkgs.openstudio;
      }
    );
    shellExports = env:
      lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg (toString value)}") env
      );
    # Nix chrome-headless-shell for headless render (mmdc/puppeteer, the mermaid validator); one owner feeds login-shell and launchd surfaces so a
    # GUI-spawned agent never falls to an unpinned browser. The bare Mach-O shell never registers with LaunchServices, so a render failure never
    # raises the macOS "quit unexpectedly" dialog; the full Chrome-for-Testing .app aborts at _RegisterApplication when spawned headless from an
    # agent shell and is never a valid headless pin.
    headlessShellBrowsers = pkgs.playwright-driver.browsers.override {
      withChromium = false;
      withChromiumHeadlessShell = true;
      withFfmpeg = false;
      withFirefox = false;
      withWebkit = false;
    };
    chromiumShell =
      if isDarwin
      then "chrome-headless-shell-mac-arm64/chrome-headless-shell"
      else "chrome-headless-shell-linux64/chrome-headless-shell";
    # One class-partitioned env owner feeding the session (home.sessionVariables), the .zshenv resilient floor, and the launchd GUI surfaces.
    # `all` rows land byte-identical everywhere so an interactive shell and a Dock-launched agent never resolve divergent pager/config env;
    # `session` rows are interactive-only (man/bat). Homebrew constants fold in darwin-only. A new cross-surface var is one `all` row.
    envByClass = {
      all =
        {
          PAGER = "less";
          GH_PAGER = "delta";
          GIT_PAGER = "delta";
          LESS = "-RFX";
          GH_CONFIG_DIR = "${xdgConfigHome}/gh";
          CLOUDSDK_CONFIG = "${xdgConfigHome}/gcloud";
          WORKSPACE_MCP_CREDENTIALS_DIR = "${xdgCacheHome}/workspace-mcp";
          GOOGLE_WORKSPACE_CLI_CONFIG_DIR = "${xdgConfigHome}/gws";
          GOOGLE_WORKSPACE_PROJECT_ID = "workspace-mcp-500605";
          MAGHZ_REMOTE_HOST = "31.97.131.41";
          MAGHZ_REMOTE_USER = "maghz-agent";
          MAGHZ_REMOTE_WORKROOT = "/home/maghz-agent/maghz";
        }
        // lib.optionalAttrs isDarwin {
          HOMEBREW_PREFIX = "/opt/homebrew";
          HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
          HOMEBREW_REPOSITORY = "/opt/homebrew";
        };
      session = {
        BAT_PAGER = "less -RFXK"; # -X fixes macOS Terminal.app clearing
        MANROFFOPT = "-c";
        MANPAGER = "env BATMAN_IS_BEING_MANPAGER=yes bash ${pkgs.bat-extras.batman}/bin/batman"; # static batman export-env, no per-shell fork
      };
    };
    # Never-clobber floor: shells whose parent scrubbed the env behind __HM_SESS_VARS_SOURCED recover the `all` rows; the fold owns the :- idiom.
    resilientFloorExports = lib.concatStrings (
      lib.mapAttrsToList (name: value: ''
        export ${name}="''${${name}:-${value}}"
      '')
      envByClass.all
    );
  in {
    inherit
      energyEnv
      geoEnv
      pythonEnv
      resilientFloorExports
      shellExports
      userPathEntries
      ;

    launchdPathEntries = userPathEntries ++ fallbackPathEntries;
    scientificSessionEnv = pythonEnv // geoEnv // energyEnv;
    sessionEnv = envByClass.all // envByClass.session;
    launchdEnv = envByClass.all;
    puppeteerExecutablePath = "${headlessShellBrowsers}/chromium_headless_shell-${pkgs.playwright-driver.browsersJSON."chromium-headless-shell".revision}/${chromiumShell}";
  };
}
