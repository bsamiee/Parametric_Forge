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
    # Nix Chrome-for-Testing for headless render (mmdc/puppeteer, the mermaid validator); one owner feeds login-shell and launchd surfaces so a
    # GUI-spawned agent never falls to an unpinned browser.
    chromiumShell =
      if isDarwin
      then "chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"
      else "chrome-linux/chrome";
  in {
    inherit
      energyEnv
      geoEnv
      pythonEnv
      shellExports
      userPathEntries
      ;

    launchdPathEntries = userPathEntries ++ fallbackPathEntries;
    scientificSessionEnv = pythonEnv // geoEnv // energyEnv;
    puppeteerExecutablePath = "${pkgs.playwright-driver.browsers-chromium}/chromium-${pkgs.playwright-driver.browsersJSON.chromium.revision}/${chromiumShell}";
  };
}
