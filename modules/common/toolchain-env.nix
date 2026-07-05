{
  lib,
  pkgs,
  home,
  username,
  xdgCacheHome,
  xdgDataHome,
}: let
  userPathEntries = [
    "${home}/.nix-profile/bin"
    "${home}/.local/bin"
    "${home}/bin"
    "${home}/.dotnet/tools"
    "${xdgDataHome}/cargo/bin"
    "${xdgDataHome}/go/bin"
    "/etc/profiles/per-user/${username}/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
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
  pythonEnv = {
    PYTEST_CACHE_DIR = "${xdgCacheHome}/pytest";
    RUFF_CACHE_DIR = "${xdgCacheHome}/ruff";
    PYLINTHOME = "${xdgCacheHome}/pylint";
    NOX_CACHE_DIR = "${xdgCacheHome}/nox";
    UV_CACHE_DIR = "${xdgCacheHome}/uv";
    UV_PYTHON_PREFERENCE = "only-system";
    UV_PYTHON_DOWNLOADS = "never";
    PYTHONDONTWRITEBYTECODE = "1";
    CRC32C_INSTALL_PREFIX = "${pkgs.crc32c}";
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
  energyEnv = {
    ENERGYPLUSDIR = "${pkgs.energyplus}/opt/energyplus";
    ENERGYPLUS_DIR = "${pkgs.energyplus}/opt/energyplus";
    ENERGYPLUS_EXE = "${pkgs.energyplus}/bin/energyplus";
    ENERGYPLUS_VERSION = pkgs.energyplus.version;
    OPENSTUDIO_ROOT = "${pkgs.openstudio}/opt/openstudio";
    OPENSTUDIO_DIR = "${pkgs.openstudio}/opt/openstudio";
    OPENSTUDIO_EXE = "${pkgs.openstudio}/bin/openstudio";
    OPENSTUDIO_VERSION = pkgs.openstudio.version;
    OPENSTUDIO_RADIANCE_ROOT = "${pkgs.openstudio}/opt/openstudio/Radiance";
    OPENSTUDIO_ENERGYPLUSDIR = "${pkgs.openstudio}/opt/openstudio/EnergyPlus";
  };
  shellExports = env:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg (toString value)}") env
    );
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
}
