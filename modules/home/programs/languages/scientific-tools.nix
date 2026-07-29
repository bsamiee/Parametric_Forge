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

  # KTX-Software builds portably under plain CMake; nixpkgs still caps meta.platforms at linux, so the lift is
  # the entire darwin admission. Carries libktx + ktx.h for the pyktx cffi link and the ktx/ktx2check/toktx CLIs.
  ktxTools = pkgs.ktx-tools.overrideAttrs (prev: {
    meta = prev.meta // {platforms = lib.platforms.unix;};
  });

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
    icu # PyICU sdist: pkg-config icu-i18n/icu-uc, dev+out outputs ride the search-path projection
    ktxTools # pyktx cffi glue links an installed libktx off LIBRARY_PATH
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
      ktxTools # KTX2 encode seam: the ktx/ktx2check/toktx CLIs spawned by the Rasm C# and python branches; TS consumes the produced bytes
      onnxruntime
    ]
    ++ aecNativeTools;

  energyRuntimePrelude = toolchainEnv.shellExports toolchainEnv.energyEnv;

  # gfortran rejects clang's --ld-path linker selector, so the wrapper strips it: the global LDFLAGS shim
  # below stays clang-scoped while Fortran links fall through to the toolchain ld.
  gfortranTool = pkgs.writeShellScriptBin "gfortran" ''
    args=()
    for arg in "$@"; do
      case "$arg" in
        --ld-path=*) ;;
        *) args+=("$arg") ;;
      esac
    done
    exec ${pkgs.gfortran}/bin/gfortran "''${args[@]}"
  '';

  # Apple ld64 rejects the -Wl,--start-group/--end-group pairs CMake emits for compiler-ID ^Clang (rhino3dm's
  # vendored draco); the shim drops the two flags and execs the toolchain ld.
  ldGroupFilter = pkgs.writeShellScriptBin "forge-ld-group-filter" ''
    args=()
    for arg in "$@"; do
      case "$arg" in
        --start-group | --end-group) ;;
        *) args+=("$arg") ;;
      esac
    done
    exec "$("${pkgs.clang}/bin/clang" -print-prog-name=ld)" "''${args[@]}"
  '';

  # Uncached nixpkgs python modules (manifest row forge-python-overlay-env) bridge into a uv venv through one .pth projection: `build` realizes
  # the env behind an XDG-state GC root, `link` writes the venv .pth at that stable path (a rebuild moves the symlink, never the .pth), `status`
  # proves the roster imports inside the venv. NIX_PYTHONPATH/sitecustomize dies inside a venv — the base interpreter's site-packages leaves
  # sys.path — so the .pth is the one mechanism surviving every invocation with zero env coupling. The Determinate profile prepend mirrors the
  # forge-tools storePath policy: every nix call resolves the daemon-matched client.
  pythonOverlayRow = (import ../../../../overlays/manifest.nix).packages.forge-python-overlay-env;
  pythonOverlayTool = pkgs.writeShellApplication {
    name = "forge-python-overlay";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      export PATH="/nix/var/nix/profiles/default/bin:$PATH"
      verb="''${1:-status}"
      venv="''${2:-}"
      forge_root="''${FORGE_ROOT:-$HOME/Documents/99.Github/Parametric_Forge}"
      state_root="''${XDG_STATE_HOME:-$HOME/.local/state}/forge"
      out_link="$state_root/python-overlay"
      site_rel="lib/python${pkgs.python315.pythonVersion}/site-packages"
      pth_rel="$site_rel/forge-overlay.pth"
      TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
      receipt() { printf 'ts=%s tool=forge-python-overlay action=%s status=%s %s\n' "$ts" "$verb" "$1" "$2"; }
      need_venv() {
        if [ -z "$venv" ] || [ ! -d "$venv/$site_rel" ]; then
          receipt fail "reason=venv-site-missing venv=''${venv:-unset}"
          exit 2
        fi
      }
      case "$verb" in
        build)
          mkdir -p "$state_root"
          nix build "$forge_root#forge-python-overlay-env" --out-link "$out_link"
          receipt ok "env=$(readlink "$out_link") gcroot=$out_link"
          ;;
        link)
          need_venv
          if [ ! -d "$out_link/$site_rel" ]; then
            receipt fail "reason=env-unbuilt hint='forge-python-overlay build'"
            exit 2
          fi
          printf '%s\n' "$out_link/$site_rel" >"$venv/$pth_rel"
          receipt ok "pth=$venv/$pth_rel target=$out_link/$site_rel"
          ;;
        unlink)
          need_venv
          rm -f "$venv/$pth_rel"
          receipt ok "pth=$venv/$pth_rel state=removed"
          ;;
        status)
          env_state="unbuilt"
          if [ -e "$out_link" ]; then env_state="$(readlink "$out_link")"; fi
          if [ -z "$venv" ]; then
            receipt ok "env=$env_state"
          else
            need_venv
            pth_state="absent"
            if [ -f "$venv/$pth_rel" ]; then pth_state="$(cat "$venv/$pth_rel")"; fi
            if "$venv/bin/python" -c 'import ${lib.concatStringsSep ", " pythonOverlayRow.probeImports}' 2>/dev/null; then
              receipt ok "env=$env_state pth=$pth_state imports=ok"
            else
              receipt warn "env=$env_state pth=$pth_state imports=fail"
              exit 1
            fi
          fi
          ;;
        *)
          receipt fail "reason=unknown-verb usage='build | link <venv> | unlink <venv> | status [<venv>]'"
          exit 2
          ;;
      esac
    '';
  };

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
  forgeScientificEnv = pkgs.writeShellApplication {
    name = "forge-scientific-env";
    # python315 comes ahead of ambient project shims so `forge-scientific-env python3` is deterministic.
    runtimeInputs = nativeBuildTools ++ fortranBuildTools ++ scientificNativeLibs ++ scientificRuntimeTools ++ [pkgs.uv pkgs.python315];
    text = ''
      export UV_PYTHON_PREFERENCE="only-system"
      export UV_PYTHON_DOWNLOADS="never"
      export PYO3_USE_ABI3_FORWARD_COMPATIBILITY="1"
      export MACOSX_DEPLOYMENT_TARGET="${darwinMinVersion}"

      # Build-parallelism governor: uv fans package builds while each build fans compiler jobs, so an upgrade
      # sweep on a wheel-less interpreter multiplies into a compile storm. Caps hold the product near the core
      # count; a caller's explicit value wins. Meson/ninja builds ignore the job caps and stay bounded only by
      # the outer uv fan.
      cores="$(getconf _NPROCESSORS_ONLN)"
      builds=$((cores / 5)); [ "$builds" -ge 2 ] || builds=2
      jobs=$((cores / 3)); [ "$jobs" -ge 2 ] || jobs=2
      export UV_CONCURRENT_BUILDS="''${UV_CONCURRENT_BUILDS:-$builds}"
      export CARGO_BUILD_JOBS="''${CARGO_BUILD_JOBS:-$jobs}"
      export CMAKE_BUILD_PARALLEL_LEVEL="''${CMAKE_BUILD_PARALLEL_LEVEL:-$jobs}"
      export MAKEFLAGS="''${MAKEFLAGS:--j$jobs}"
      ${energyRuntimePrelude}

      export CC="${pkgs.clang}/bin/clang"
      export CXX="${pkgs.clang}/bin/clang++"
      export AR="${llvmTools}/bin/llvm-ar"
      export RANLIB="${llvmTools}/bin/llvm-ranlib"
      export FC="${gfortranTool}/bin/gfortran"
      export F77="$FC"
      export F90="$FC"

      ${toolchainEnv.shellExports toolchainEnv.geoEnv}

      export HDF5_PKGCONFIG_NAME="hdf5"
      export CRC32C_INSTALL_PREFIX="${pkgs.crc32c}"
      export CRC32C_PURE_PYTHON="0"

      export ARROW_HOME="${pkgs.arrow-cpp}"
      export OPENBLAS_DIR="${pkgs.openblas}"
      export OpenMP_ROOT="${openmpDev}"

      # pyktx setup.py reads all three: it links libktx by name and refuses to build without a version literal.
      export LIBKTX_VERSION="${ktxTools.version}"
      export LIBKTX_INCLUDE_DIR="${ktxTools}/include"
      export LIBKTX_LIB_DIR="${ktxTools}/lib"

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
      ${lib.optionalString isDarwin ''
        # rhino3dm: route links through the ld group-filter shim; grpcio: vendored c-ares needs arpa/nameser.h,
        # absent from every nixpkgs apple-sdk — -idirafter appends the system SDK headers last, after Nix includes.
        export LDFLAGS="$LDFLAGS --ld-path=${ldGroupFilter}/bin/forge-ld-group-filter"
        if sdk_path="$(/usr/bin/xcrun --show-sdk-path 2>/dev/null)"; then
          export CPPFLAGS="$CPPFLAGS -idirafter $sdk_path/usr/include"
        fi
      ''}
      export CMAKE_ARGS="-DCMAKE_C_FLAGS=-D_DARWIN_C_SOURCE -DCMAKE_CXX_FLAGS=-D_DARWIN_C_SOURCE -DOpenMP_C_FLAGS=-fopenmp -DOpenMP_CXX_FLAGS=-fopenmp -DOpenMP_C_LIB_NAMES=omp -DOpenMP_CXX_LIB_NAMES=omp -DOpenMP_omp_LIBRARY=${openmpLib}/lib/libomp${sharedLibExt}''${CMAKE_ARGS:+ $CMAKE_ARGS}"

      exec "$@"
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
      pythonOverlayTool
    ];
}
