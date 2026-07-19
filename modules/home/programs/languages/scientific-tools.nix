# Title         : scientific-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/scientific-tools.nix
# ----------------------------------------------------------------------------
# Native scientific build/runtime toolchain for source-built Python packages, geospatial/data libraries, numerical kernels, and local provisioning probes.
{
  config,
  forgeToolchainEnvFor,
  lib,
  pkgs,
  ...
}: let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  darwinMinVersion = pkgs.stdenv.hostPlatform.darwinMinVersion or "14.0";
  sharedLibExt = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
  llvmTools = pkgs.llvmPackages.llvm;
  openmp = pkgs.llvmPackages.openmp;
  openmpDev = lib.getDev openmp;
  openmpLib = lib.getLib openmp;
  toolchainEnv = forgeToolchainEnvFor {
    home = config.home.homeDirectory;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
  };

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
    flint
    gmp
    libiconv
    mpfr
    openmpDev
    openmpLib
    openblas
    blas
    lapack
    tbb
  ];

  columnarNativeLibs = with pkgs; [
    arrow-cpp
    crc32c
  ];

  artifactNativeLibs = with pkgs; [
    cairo
    freetype
    fribidi
    gdk-pixbuf
    ghostscript
    harfbuzz
    lcms2
    leptonica
    libheif # HEIF/HEIC input
    libjpeg_turbo
    libpng
    libtiff
    libwebp
    mupdf
    openjpeg
    pango
    qpdf
    tesseract
    vips # pyvips
    zlib
  ];

  pointCloudNativeLibs = with pkgs; [
    boost
    flann
    pdal
  ];

  # EnergyPlus/OpenStudio bind macOS only; gmsh generalizes to every host.
  aecNativeTools =
    [pkgs.gmsh]
    ++ lib.optionals isDarwin [
      pkgs.energyplus
      pkgs.openstudio
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
      flint
      gmp
      libiconv
      mpfr
      openmpDev
      openmpLib
      openblas
      flann
      tbb
      pdal
    ])
    ++ artifactNativeLibs;

  scientificRuntimeTools = with pkgs;
    [
      onnxruntime
    ]
    ++ aecNativeTools;

  energyRuntimePrelude = toolchainEnv.shellExports toolchainEnv.energyEnv;

  gfortranTool = pkgs.writeShellScriptBin "gfortran" ''
    exec ${pkgs.gfortran}/bin/gfortran "$@"
  '';

  # One search-path projection per lib set; dev outputs precede out per key.
  mkSearchPaths = libs: {
    pkgconfig = lib.concatStringsSep ":" [
      (lib.makeSearchPathOutput "dev" "lib/pkgconfig" libs)
      (lib.makeSearchPathOutput "out" "lib/pkgconfig" libs)
      (lib.makeSearchPathOutput "dev" "share/pkgconfig" libs)
      (lib.makeSearchPathOutput "out" "share/pkgconfig" libs)
    ];
    cmake = lib.concatStringsSep ":" (map toString libs);
    library = lib.makeLibraryPath libs;
  };
  scientificPaths = mkSearchPaths scientificNativeLibs;
  forgePythonStateHome = config.xdg.stateHome;
  forgePythonEnvPrelude = python: profile: ''
    forge_python_root() {
      if [ -n "''${FORGE_PROVISION_ROOT:-}" ]; then
        [ -d "$FORGE_PROVISION_ROOT" ] || {
          printf '%s: FORGE_PROVISION_ROOT is not a directory: %s\n' "${profile}" "$FORGE_PROVISION_ROOT" >&2
          exit 1
        }
        (cd "$FORGE_PROVISION_ROOT" && pwd -P)
        return
      fi
      dir="$PWD"
      while [ "$dir" != "/" ]; do
        if [ -f "$dir/pyproject.toml" ] || [ -f "$dir/uv.lock" ] || [ -x "$dir/.venv/bin/python" ]; then
          (cd "$dir" && pwd -P)
          return
        fi
        dir="''${dir%/*}"
        [ -n "$dir" ] || dir="/"
      done

      pwd -P
    }

    forge_python_root_key() {
      hash="$(printf '%s' "$(forge_python_root)" | sha256sum)"
      printf '%.12s\n' "$hash"
    }

    forge_python_env_default() {
      abi="$(${python}/bin/python3 -c 'import sys; print(sys.implementation.cache_tag)')"
      root_key="$(forge_python_root_key)"
      state_home=${lib.escapeShellArg forgePythonStateHome}
      printf '%s/forge-python-envs/%s/%s/${profile}\n' "$state_home" "$abi" "$root_key"
    }

    if [ -n "''${FORGE_PYTHON_ENVIRONMENT:-}" ]; then
      UV_PROJECT_ENVIRONMENT="$FORGE_PYTHON_ENVIRONMENT"
    else
      UV_PROJECT_ENVIRONMENT="$(forge_python_env_default)"
    fi
    export UV_PROJECT_ENVIRONMENT
  '';
  forgeScientificEnv = pkgs.writeShellApplication {
    name = "forge-scientific-env";
    # python315 comes ahead of ambient project shims so `forge-scientific-env python3` is deterministic.
    runtimeInputs = nativeBuildTools ++ fortranBuildTools ++ scientificNativeLibs ++ scientificRuntimeTools ++ [pkgs.uv pkgs.python315];
    text = ''
      export UV_PYTHON_PREFERENCE="only-system"
      export UV_PYTHON_DOWNLOADS="never"
      export PYO3_USE_ABI3_FORWARD_COMPATIBILITY="1"
      export MACOSX_DEPLOYMENT_TARGET="${darwinMinVersion}"
      ${energyRuntimePrelude}

      export CC="${pkgs.clang}/bin/clang"
      export CXX="${pkgs.clang}/bin/clang++"
      export AR="${llvmTools}/bin/llvm-ar"
      export RANLIB="${llvmTools}/bin/llvm-ranlib"
      export FC="${pkgs.gfortran}/bin/gfortran"
      export F77="$FC"
      export F90="$FC"

      ${toolchainEnv.shellExports toolchainEnv.geoEnv}

      export HDF5_PKGCONFIG_NAME="hdf5"
      export CRC32C_INSTALL_PREFIX="${pkgs.crc32c}"
      export CRC32C_PURE_PYTHON="0"

      export ARROW_HOME="${pkgs.arrow-cpp}"
      export OPENBLAS_DIR="${pkgs.openblas}"
      export OpenMP_ROOT="${openmpDev}"
      export ONNXRUNTIME_DIR="${pkgs.onnxruntime}"
      for candidate in \
        "${pkgs.onnxruntime}/lib/libonnxruntime${sharedLibExt}.${pkgs.onnxruntime.version}" \
        "${pkgs.onnxruntime}/lib/libonnxruntime.${pkgs.onnxruntime.version}${sharedLibExt}" \
        "${pkgs.onnxruntime}/lib/libonnxruntime${sharedLibExt}"
      do
        if [ -e "$candidate" ]; then
          export ONNXRUNTIME_LIB="$candidate"
          break
        fi
      done
      [ -n "''${ONNXRUNTIME_LIB:-}" ] || {
        printf 'forge-scientific-env: cannot locate ONNX Runtime shared library under %s\n' "${pkgs.onnxruntime}" >&2
        exit 1
      }

      export PKG_CONFIG_PATH="${scientificPaths.pkgconfig}''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
      export CMAKE_PREFIX_PATH="${scientificPaths.cmake}''${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
      export LIBRARY_PATH="${scientificPaths.library}''${LIBRARY_PATH:+:$LIBRARY_PATH}"
      export CFLAGS="-D_DARWIN_C_SOURCE''${CFLAGS:+ $CFLAGS}"
      export CXXFLAGS="-D_DARWIN_C_SOURCE''${CXXFLAGS:+ $CXXFLAGS}"
      export CPPFLAGS="-I${openmpDev}/include''${CPPFLAGS:+ $CPPFLAGS}"
      export LDFLAGS="-L${openmpLib}/lib''${LDFLAGS:+ $LDFLAGS}"
      export CMAKE_ARGS="-DCMAKE_C_FLAGS=-D_DARWIN_C_SOURCE -DCMAKE_CXX_FLAGS=-D_DARWIN_C_SOURCE -DOpenMP_C_FLAGS=-fopenmp -DOpenMP_CXX_FLAGS=-fopenmp -DOpenMP_C_LIB_NAMES=omp -DOpenMP_CXX_LIB_NAMES=omp -DOpenMP_omp_LIBRARY=${openmpLib}/lib/libomp${sharedLibExt}''${CMAKE_ARGS:+ $CMAKE_ARGS}"

      exec "$@"
    '';
  };
  forgeScientificSync = pkgs.writeShellApplication {
    name = "forge-scientific-sync";
    runtimeInputs = [forgeScientificEnv pkgs.coreutils pkgs.python315 pkgs.uv];
    text = ''
      ${forgePythonEnvPrelude pkgs.python315 "scientific"}
      project_root="$(forge_python_root)"
      cd "$project_root"
      forge-scientific-env uv sync --locked --no-default-groups --python "${pkgs.python315}/bin/python3" "$@"

      if [ -x "$UV_PROJECT_ENVIRONMENT/bin/python" ]; then
        crc32c_version="$("$UV_PROJECT_ENVIRONMENT/bin/python" -c 'from importlib.metadata import version; print(version("google-crc32c"))' 2>/dev/null || true)"
        if [ -n "$crc32c_version" ]; then
          forge-scientific-env uv pip install \
            --python "$UV_PROJECT_ENVIRONMENT/bin/python" \
            --no-cache \
            --no-binary google-crc32c \
            --reinstall \
            "google-crc32c==$crc32c_version"
        fi
      fi
    '';
  };
in {
  home.packages =
    [
      gfortranTool
    ]
    ++ scientificProfileNativeLibs
    ++ scientificRuntimeTools
    ++ [
      forgeScientificEnv
      forgeScientificSync
    ];
}
