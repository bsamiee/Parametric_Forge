# Title         : scientific-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/scientific-tools.nix
# ----------------------------------------------------------------------------
# Native scientific build/runtime toolchain for source-built Python packages,
# geospatial/data libraries, numerical kernels, and local spike probes.
{
  lib,
  pkgs,
  ...
}: let
  darwinMinVersion = pkgs.stdenv.hostPlatform.darwinMinVersion or "14.0";

  nativeBuildTools = with pkgs; [
    gfortran
    pkg-config
    cmake
    ninja
    meson
    rustc
    cargo
    maturin
  ];

  scientificNativeLibs = with pkgs; [
    gdal
    hdf5
    geos
    proj
    netcdf
    arrow-cpp
    openblas
    blas
    lapack
  ];

  scientificProfileNativeLibs = with pkgs; [
    gdal
    hdf5
    geos
    proj
    netcdf
    arrow-cpp
    openblas
  ];

  scientificRuntimeTools = with pkgs; [
    onnxruntime
  ];

  pkgConfigPath = lib.concatStringsSep ":" [
    (lib.makeSearchPathOutput "dev" "lib/pkgconfig" scientificNativeLibs)
    (lib.makeSearchPathOutput "out" "lib/pkgconfig" scientificNativeLibs)
    (lib.makeSearchPathOutput "dev" "share/pkgconfig" scientificNativeLibs)
    (lib.makeSearchPathOutput "out" "share/pkgconfig" scientificNativeLibs)
  ];

  cmakePrefixPath = lib.concatStringsSep ":" (map toString scientificNativeLibs);
in {
  home.packages =
    nativeBuildTools
    ++ scientificProfileNativeLibs
    ++ scientificRuntimeTools
    ++ [
      (pkgs.writeShellApplication {
        name = "forge-scientific-env";
        runtimeInputs = nativeBuildTools ++ scientificNativeLibs ++ scientificRuntimeTools ++ [pkgs.uv];
        text = ''
          export UV_NO_MANAGED_PYTHON="1"
          export UV_PYTHON_DOWNLOADS="never"
          export MACOSX_DEPLOYMENT_TARGET="${darwinMinVersion}"

          export CC="${pkgs.gfortran}/bin/gcc"
          export CXX="${pkgs.gfortran}/bin/g++"
          export FC="${pkgs.gfortran}/bin/gfortran"
          export F77="$FC"
          export F90="$FC"

          export GDAL_CONFIG="${pkgs.gdal}/bin/gdal-config"
          export GEOS_CONFIG="${pkgs.geos}/bin/geos-config"
          export GDAL_DATA="${pkgs.gdal}/share/gdal"
          export PROJ_DATA="${pkgs.proj}/share/proj"

          export HDF5_LIBDIR="${pkgs.hdf5}/lib"
          export HDF5_INCLUDEDIR="${pkgs.hdf5.dev}/include"
          export HDF5_PKGCONFIG_NAME="hdf5"
          export HDF5_DIR="${pkgs.hdf5}"

          export ARROW_HOME="${pkgs.arrow-cpp}"
          export OPENBLAS_DIR="${pkgs.openblas}"
          export ONNXRUNTIME_DIR="${pkgs.onnxruntime}"
          export ONNXRUNTIME_LIB="${pkgs.onnxruntime}/lib/libonnxruntime.${pkgs.onnxruntime.version}.dylib"

          export PKG_CONFIG_PATH="${pkgConfigPath}''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
          export CMAKE_PREFIX_PATH="${cmakePrefixPath}''${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"

          exec "$@"
        '';
      })
    ];
}
