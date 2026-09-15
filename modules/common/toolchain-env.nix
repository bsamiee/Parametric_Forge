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
    xdgDataHome ? "${home}/.local/share", # Same convention: the shim-farm segment reads it, so a PATH-only caller inherits the XDG default.
    xdgStateHome ? "${home}/.local/state", # Same convention: the interactive history rows read it.
  }: let
    isDarwin = host.os == "darwin"; # OS branch keys on the static host context, never on pkgs (fixpoint safety).
    # Only provisioned directories: useUserPackages replaces ~/.nix-profile with /etc/profiles; cargo/go user bins return once provisioned.
    userPathEntries =
      [
        "${home}/.local/bin"
        "${home}/bin"
        "/etc/profiles/per-user/${username}/bin"
        "/run/current-system/sw/bin"
        "/nix/var/nix/profiles/default/bin"
      ]
      ++ lib.optionals isDarwin [
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
        "/Applications/RhinoBETA.app/Contents/Resources/bin"
      ];
    fallbackPathEntries = [
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ];
    # Last segment of every vector by construction, behind the macOS directories too: the mise shim farm serves only the per-repo toolchains
    # Nix does not ship — the .NET SDK a global.json pins — because every Nix-owned binary resolves ahead of it and a shim for a name Nix does
    # not own (pip3) never shadows the system copy outside a project. `mise activate` lives in .zshrc and resolves tools from the shell's
    # directory, so a non-interactive login shell, a launchd agent, and a GUI app (VS Code resolves its environment with `zsh -ilc` from `/`)
    # get no project tool from it; the farm is the one route those processes have, and each shim resolves the version from its caller's directory.
    # Home Manager prepends home.sessionPath to the inherited PATH, so the session vector carries the macOS directories explicitly ahead of the
    # farm; the inherited copies behind it are duplicates, never a different owner.
    shimPathEntries = ["${xdgDataHome}/mise/shims"];
    pathEntries = userPathEntries ++ fallbackPathEntries ++ shimPathEntries;
    # ctypes/dlopen consumers (weasyprint's gobject/pango/harfbuzz/fontconfig chain, python-magic's libmagic, pyvips's libvips/gobject/glib)
    # resolve their dylibs by bare name at runtime, outside any build env. One linked lib tree behind DYLD_FALLBACK_LIBRARY_PATH serves them;
    # dyld consults the fallback only after every standard location, so system libraries keep precedence. getLib pins each member's lib output:
    # multi-output members otherwise contribute their default output, which for glib and pango carries no dylibs at all. The row rides the
    # scientific set because the .zshenv floor re-exports that set in every shell: exec of a SIP-protected binary (/bin/bash, /usr/bin/env)
    # purges every DYLD_* variable, and a child shell behind the inherited __HM_SESS_VARS_SOURCED guard never re-sources hm-session-vars.
    runtimeDylibEnv = pkgs.buildEnv {
      name = "forge-runtime-dylibs";
      paths = map lib.getLib [pkgs.file pkgs.fontconfig pkgs.glib pkgs.harfbuzz pkgs.pango pkgs.vips];
      pathsToLink = ["/lib"];
    };
    pythonEnv =
      {
        MPLCONFIGDIR = "${xdgCacheHome}/matplotlib"; # macOS default is ~/.matplotlib; the directory holds font and tex caches, no rc file

        UV_PYTHON_PREFERENCE = "only-system";
        UV_PYTHON_DOWNLOADS = "never";
        PYTHONDONTWRITEBYTECODE = "1";

        # Machine libraries a project's source builds read, each row the search key the build system documents and each value a store reference:
        # pkg-config .pc files (pyicu: icu-i18n and icu-uc; h5py: hdf5; pi-heif: libheif), the CMake package configs find_package(Arrow),
        # find_package(Eigen3), and find_package(PDAL) locate (pyarrow, small-gicp — which otherwise downloads Eigen at configure — and
        # python-pdal), the compiler's own header and library search for a build that includes <librdkafka/rdkafka.h> and links -lrdkafka with
        # no pkg-config (confluent-kafka), and the FindOpenMP prefix small-gicp reaches through find_package's <PackageName>_ROOT environment
        # lookup (CMP0074) — one prefix joining the omp.h dev output with the libomp lib output, since either split output alone answers only
        # find_path or only find_library.
        PKG_CONFIG_PATH = lib.makeSearchPathOutput "dev" "lib/pkgconfig" [pkgs.icu pkgs.hdf5 pkgs.libheif];
        CMAKE_PREFIX_PATH = lib.concatStringsSep ":" (map toString [pkgs.arrow-cpp pkgs.eigen pkgs.pdal]);
        CPATH = "${lib.getDev pkgs.rdkafka}/include";
        LIBRARY_PATH = "${lib.getLib pkgs.rdkafka}/lib";
        OpenMP_ROOT = "${pkgs.symlinkJoin {
          name = "openmp-prefix";
          paths = [(lib.getDev pkgs.llvmPackages.openmp) (lib.getLib pkgs.llvmPackages.openmp)];
        }}";
        CRC32C_INSTALL_PREFIX = "${pkgs.crc32c}";
      }
      // lib.optionalAttrs isDarwin {
        DYLD_FALLBACK_LIBRARY_PATH = "${runtimeDylibEnv}/lib";
      };
    # PROJ 9.1 renamed PROJ_LIB to PROJ_DATA and every reader here (libproj, pyproj, rasterio) consults PROJ_DATA first, so the old name carries no row.
    geoEnv = {
      GDAL_CONFIG = "${pkgs.gdal}/bin/gdal-config";
      GDAL_DATA = "${pkgs.gdal}/share/gdal";
      GEOS_CONFIG = "${pkgs.geos}/bin/geos-config";
      PROJ_DATA = "${pkgs.proj}/share/proj";
      PROJ_DIR = "${pkgs.proj}";
      PROJ_INCDIR = "${pkgs.proj.dev}/include";
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
    puppeteerExecutablePath = "${headlessShellBrowsers}/chromium_headless_shell-${pkgs.playwright-driver.browsersJSON."chromium-headless-shell".revision}/${chromiumShell}";
    # One class-partitioned env owner feeding the session (home.sessionVariables), the .zshenv resilient floor, and the launchd GUI surfaces.
    # `all` rows land byte-identical everywhere so an interactive shell and a Dock-launched agent never resolve divergent pager/config env;
    # `session` rows are interactive-only (man/bat/info/sqlite). Every row moves a tool off a non-XDG default or names a fact its config file
    # cannot: gh, gcloud, gws, bat, starship, and WezTerm already read the XDG paths, git's pager is the delta git integration, gh's pager is
    # its own config key. A new cross-surface var is one `all` row.
    envByClass = {
      all = {
        PAGER = "less";
        LESS = "-RFX";
        DOPPLER_CONFIG_DIR = "${xdgConfigHome}/doppler"; # .doppler.yaml, fallback/, and metadata; the default is ~/.doppler
        GOOGLE_WORKSPACE_PROJECT_ID = "workspace-mcp-500605";
        # pnpm's home directory, where `pnpm add -g` lands packages and their bin links; the macOS default is ~/Library/pnpm. pnpm itself is a
        # project's mise.toml row, this row is data only.
        PNPM_HOME = "${xdgDataHome}/pnpm";
        # mmdc/puppeteer and the mermaid validator launch this pin from a login shell and from a GUI-spawned agent alike.
        PUPPETEER_EXECUTABLE_PATH = puppeteerExecutablePath;
      };
      session =
        {
          BAT_PAGER = "less -RFXK"; # -X fixes macOS Terminal.app clearing
          MANROFFOPT = "-c";
          MANPAGER = "env BATMAN_IS_BEING_MANPAGER=yes bash ${pkgs.bat-extras.batman}/bin/batman"; # static batman export-env, no per-shell fork
          SQLITE_HISTORY = "${xdgStateHome}/sqlite/history"; # sqlite3's default is ~/.sqlite_history
        }
        // lib.optionalAttrs isDarwin {
          # The one `brew shellenv` row PATH resolution does not cover: macOS manpath derives /opt/homebrew/share/man from /opt/homebrew/bin,
          # GNU info reads INFOPATH alone; the trailing colon appends info's built-in directories.
          INFOPATH = "/opt/homebrew/share/info:";
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
      puppeteerExecutablePath
      resilientFloorExports
      shellExports
      ;

    sessionPathEntries = pathEntries;
    launchdPathEntries = pathEntries;
    scientificSessionEnv = pythonEnv // geoEnv // energyEnv;
    sessionEnv = envByClass.all // envByClass.session;
    launchdEnv = envByClass.all;
  };
}
