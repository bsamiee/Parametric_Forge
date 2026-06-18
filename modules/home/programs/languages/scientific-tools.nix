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
    clang
    pkg-config
    cmake
    ninja
    meson
    rustc
    cargo
    maturin
  ];

  fortranBuildTools = with pkgs; [
    gfortran
  ];

  geoNativeLibs = with pkgs; [
    gdal
    hdf5
    geos
    proj
    netcdf
  ];

  numericNativeLibs = with pkgs; [
    eigen
    openblas
    blas
    lapack
  ];

  columnarNativeLibs = with pkgs; [
    arrow-cpp
  ];

  artifactNativeLibs = with pkgs; [
    cairo
    freetype
    fribidi
    gdk-pixbuf
    harfbuzz
    lcms2
    libjpeg_turbo
    libpng
    libtiff
    libwebp
    mupdf
    openjpeg
    pango
    qpdf
    zlib
  ];

  pointCloudNativeLibs = with pkgs; [
    boost
    pdal
  ];

  scientificNativeLibs =
    geoNativeLibs
    ++ numericNativeLibs
    ++ columnarNativeLibs
    ++ artifactNativeLibs
    ++ pointCloudNativeLibs;

  scientificProfileNativeLibs =
    geoNativeLibs
    ++ columnarNativeLibs
    ++ (with pkgs; [
      eigen
      openblas
      pdal
    ])
    ++ artifactNativeLibs;

  scientificRuntimeTools = with pkgs; [
    onnxruntime
  ];

  gfortranTool = pkgs.writeShellScriptBin "gfortran" ''
    exec ${pkgs.gfortran}/bin/gfortran "$@"
  '';

  pkgConfigPath = lib.concatStringsSep ":" [
    (lib.makeSearchPathOutput "dev" "lib/pkgconfig" scientificNativeLibs)
    (lib.makeSearchPathOutput "out" "lib/pkgconfig" scientificNativeLibs)
    (lib.makeSearchPathOutput "dev" "share/pkgconfig" scientificNativeLibs)
    (lib.makeSearchPathOutput "out" "share/pkgconfig" scientificNativeLibs)
  ];

  cmakePrefixPath = lib.concatStringsSep ":" (map toString scientificNativeLibs);
in {
  home.packages =
    [
      gfortranTool
    ]
    ++ scientificProfileNativeLibs
    ++ scientificRuntimeTools
    ++ [
      (pkgs.writeShellApplication {
        name = "forge-scientific-env";
        # python315 is pinned ahead of the ambient project-venv shim so `forge-scientific-env python3` is the deterministic
        # canonical scientific interpreter (matching UV_PYTHON_PREFERENCE=only-system), not whichever project owns the cwd.
        runtimeInputs = nativeBuildTools ++ fortranBuildTools ++ scientificNativeLibs ++ scientificRuntimeTools ++ [pkgs.uv pkgs.python315];
        text = ''
          export UV_PYTHON_PREFERENCE="only-system"
          export UV_PYTHON_DOWNLOADS="never"
          export MACOSX_DEPLOYMENT_TARGET="${darwinMinVersion}"

          export CC="${pkgs.clang}/bin/clang"
          export CXX="${pkgs.clang}/bin/clang++"
          export FC="${pkgs.gfortran}/bin/gfortran"
          export F77="$FC"
          export F90="$FC"

          export GDAL_CONFIG="${pkgs.gdal}/bin/gdal-config"
          export GEOS_CONFIG="${pkgs.geos}/bin/geos-config"
          export GDAL_DATA="${pkgs.gdal}/share/gdal"
          export PROJ_DIR="${pkgs.proj}"
          export PROJ_INCDIR="${pkgs.proj.dev}/include"
          export PROJ_LIBDIR="${pkgs.proj}/lib"
          export PROJ_DATA="${pkgs.proj}/share/proj"

          export HDF5_PKGCONFIG_NAME="hdf5"

          export ARROW_HOME="${pkgs.arrow-cpp}"
          export OPENBLAS_DIR="${pkgs.openblas}"
          export ONNXRUNTIME_DIR="${pkgs.onnxruntime}"
          if [ -e "${pkgs.onnxruntime}/lib/libonnxruntime.${pkgs.onnxruntime.version}.dylib" ]; then
            export ONNXRUNTIME_LIB="${pkgs.onnxruntime}/lib/libonnxruntime.${pkgs.onnxruntime.version}.dylib"
          else
            export ONNXRUNTIME_LIB="${pkgs.onnxruntime}/lib/libonnxruntime.dylib"
          fi

          export PKG_CONFIG_PATH="${pkgConfigPath}''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
          export CMAKE_PREFIX_PATH="${cmakePrefixPath}''${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"

          exec "$@"
        '';
      })
    ];
}
