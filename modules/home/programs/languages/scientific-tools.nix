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
  host,
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

  companionNativeLibs =
    geoNativeLibs
    ++ numericNativeLibs
    ++ pointCloudNativeLibs;

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
  companionPaths = mkSearchPaths companionNativeLibs;
  forgePythonStateHome = config.xdg.stateHome;
  forgeJupyterTokenFile = "${config.xdg.configHome}/jupyter/forge-token.env";
  forgeJupyterPort = 8888;
  forgeJupyterRootDir = "${config.xdg.stateHome}/forge-jupyter/root";
  forgeJupyterTokenPrelude = ''
    token_file=${lib.escapeShellArg forgeJupyterTokenFile}
    if [ -z "''${JUPYTER_TOKEN:-}" ] && [ -f "$token_file" ]; then
      # Typed extraction, never source: a mutable file must not reach the parser. First-match-quit sed; head's early exit SIGPIPEs sed under pipefail.
      JUPYTER_TOKEN="$(sed -n '/^export JUPYTER_TOKEN=/{s///p;q;}' "$token_file")"
    fi
    if [ -z "''${JUPYTER_TOKEN:-}" ]; then
      printf 'forge-jupyter: missing JUPYTER_TOKEN; expected %s\n' "$token_file" >&2
      exit 1
    fi
    export JUPYTER_TOKEN
  '';
  forgeJupyterRootPrelude = ''
    export FORGE_PROVISION_ROOT=${lib.escapeShellArg forgeJupyterRootDir}
  '';
  # Shared supervised stdio lane (relay-cat + group reap): uvx pythons that ignore stdin EOF (jupyter-mcp-server) strand under a hard-killed OR
  # reconnecting MCP client; the relay ties the server subtree to client liveness through the stdin pipe itself.
  superviseStdio = import ../shell-tools/supervise-stdio.nix;
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
  forgeCompanionEnv = pkgs.writeShellApplication {
    name = "forge-companion-env";
    # Companion tasks run on Python 3.12 for IFC and hosted code-generation tools that ship there.
    runtimeInputs = nativeBuildTools ++ companionNativeLibs ++ [pkgs.coreutils pkgs.uv pkgs.python312];
    text = ''
      ${forgePythonEnvPrelude pkgs.python312 "companion"}
      export UV_PYTHON_PREFERENCE="only-system"
      export UV_PYTHON_DOWNLOADS="never"
      export MACOSX_DEPLOYMENT_TARGET="${darwinMinVersion}"
      ${energyRuntimePrelude}
      export CC="${pkgs.clang}/bin/clang"
      export CXX="${pkgs.clang}/bin/clang++"
      export AR="${llvmTools}/bin/llvm-ar"
      export RANLIB="${llvmTools}/bin/llvm-ranlib"
      export PKG_CONFIG_PATH="${companionPaths.pkgconfig}''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
      export CMAKE_PREFIX_PATH="${companionPaths.cmake}''${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
      export LIBRARY_PATH="${companionPaths.library}''${LIBRARY_PATH:+:$LIBRARY_PATH}"
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

      if [ -x "$UV_PROJECT_ENVIRONMENT/bin/python" ] && "$UV_PROJECT_ENVIRONMENT/bin/python" -c 'import ipykernel' 2>/dev/null; then
        root_key="$(forge_python_root_key)"
        project_name="$(basename "$project_root")"
        "$UV_PROJECT_ENVIRONMENT/bin/python" -m ipykernel install --user \
          --name "forge-scientific-$root_key" \
          --display-name "Python 3.15 (forge-scientific: $project_name)"
      fi
    '';
  };
  forgeJupyterServerConfig = pkgs.writeText "forge-jupyter-server-config.py" ''
    import os

    c = get_config()
    c.IdentityProvider.token = os.environ["JUPYTER_TOKEN"]
    # MCP WebSockets remain connected for the client lifetime, so connected idle kernels must remain eligible; busy kernels retain compute ownership.
    c.MappingKernelManager.cull_idle_timeout = 3600
    c.MappingKernelManager.cull_interval = 300
    c.MappingKernelManager.cull_busy = False
    c.MappingKernelManager.cull_connected = True
  '';
  forgeIfcMcp = pkgs.writeShellApplication {
    name = "forge-ifcmcp";
    text = ''
      export FORGE_STDIO_IDLE_SECONDS=180
      ${superviseStdio ''${forgeCompanionEnv}/bin/forge-companion-env uvx --python "${pkgs.python312}/bin/python3" --from "ifcopenshell-mcp[mcp]==0.8.5" ifcmcp''}
    '';
  };
  # writeShellApplication: the token prelude runs sed under launchd/systemd minimal PATH, so the tool arrives via runtimeInputs, never ambient lookup.
  forgeJupyter = pkgs.writeShellApplication {
    name = "forge-jupyter";
    runtimeInputs = [pkgs.gnused];
    text = ''
      ${forgeJupyterTokenPrelude}
      ${forgeJupyterRootPrelude}
      exec ${forgeCompanionEnv}/bin/forge-companion-env uvx --python "${pkgs.python312}/bin/python3" \
        --from "jupyterlab==4.6.1" --with "jupyter-collaboration==4.4.1" --with "jupyter-mcp-tools==0.1.6" \
        jupyter-lab --no-browser --ServerApp.ip=127.0.0.1 --ServerApp.port=${toString forgeJupyterPort} \
        --ServerApp.port_retries=0 \
        --config=${lib.escapeShellArg forgeJupyterServerConfig} "$@"
    '';
  };
  forgeJupyterMcp = pkgs.writeShellApplication {
    name = "forge-jupyter-mcp";
    runtimeInputs = [pkgs.gnused];
    text = ''
      ${forgeJupyterTokenPrelude}
      ${forgeJupyterRootPrelude}
      # Connector defaults owned here so both MCP fleets carry no per-client env.
      export JUPYTER_URL="''${JUPYTER_URL:-http://127.0.0.1:${toString forgeJupyterPort}}"
      export ALLOW_IMG_OUTPUT="''${ALLOW_IMG_OUTPUT:-true}"
      export FORGE_STDIO_IDLE_SECONDS=180 # thin bridge to the persistent JupyterLab LaunchAgent; reap fast, the kernel server survives
      ${superviseStdio ''${forgeCompanionEnv}/bin/forge-companion-env uvx --python "${pkgs.python312}/bin/python3" --from "jupyter-mcp-server==1.0.3" jupyter-mcp-server --transport stdio --start-new-runtime false''}
    '';
  };
in
  {
    home = {
      packages =
        [
          gfortranTool
        ]
        ++ scientificProfileNativeLibs
        ++ scientificRuntimeTools
        ++ [
          forgeCompanionEnv
          forgeScientificEnv
          forgeScientificSync
          forgeIfcMcp
          forgeJupyter
          forgeJupyterMcp
        ];

      file = lib.optionalAttrs isDarwin {
        "Applications/Forge Jupyter.app/Contents/Info.plist".text = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>CFBundleIdentifier</key>
            <string>com.parametric-forge.forge-jupyter</string>
            <key>CFBundleName</key>
            <string>Forge Jupyter</string>
            <key>CFBundleDisplayName</key>
            <string>Forge Jupyter</string>
            <key>CFBundleVersion</key>
            <string>1</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>LSUIElement</key>
            <true/>
            <key>LSBackgroundOnly</key>
            <true/>
          </dict>
          </plist>
        '';
      };

      activation =
        lib.optionalAttrs isDarwin {
          registerForgeJupyterApp = lib.hm.dag.entryAfter ["linkGeneration"] ''
            app="$HOME/Applications/Forge Jupyter.app"
            lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
            if [ -d "$app" ] && [ -x "$lsregister" ]; then
              "$lsregister" -f "$app" || true
            fi
          '';
        }
        // {
          ensureForgeJupyterToken = lib.hm.dag.entryAfter ["linkGeneration"] ''
            token_file=${lib.escapeShellArg forgeJupyterTokenFile}
            mkdir -p "$(dirname "$token_file")"
            if [ ! -s "$token_file" ]; then
              # mktemp in the target directory: unpredictable name, same-filesystem rename.
              tmp_file="$(umask 077; mktemp "$token_file.XXXXXX")"
              printf 'export JUPYTER_TOKEN=%s\n' "$(${pkgs.openssl}/bin/openssl rand -hex 32)" >"$tmp_file"
              chmod 600 "$tmp_file"
              mv -f "$tmp_file" "$token_file"
            fi
            chmod 600 "$token_file"
          '';

          ensureForgeJupyterRootDir = lib.hm.dag.entryAfter ["linkGeneration"] ''
            ${pkgs.coreutils}/bin/install -d -m 700 ${lib.escapeShellArg forgeJupyterRootDir}
          '';
        };
    };

    # Persistent Jupyter rides a supervisor on both hosts: launchd on Darwin, a lingering systemd user service on Linux.
    # KeepAlive implies launch-at-load; Interactive classification exempts user-facing kernel compute from Background throttling per launchd.plist(5).
    launchd.agents.forge-jupyter = {
      enable = true;
      config = {
        Label = "com.parametric-forge.forge-jupyter";
        ProgramArguments = ["${forgeJupyter}/bin/forge-jupyter"];
        WorkingDirectory = forgeJupyterRootDir;
        EnvironmentVariables = {
          FORGE_PROVISION_ROOT = forgeJupyterRootDir;
        };
        KeepAlive = true;
        ThrottleInterval = 30;
        ProcessType = "Interactive";
        AbandonProcessGroup = false;
        ExitTimeOut = 30;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/forge-jupyter.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/forge-jupyter.log";
        AssociatedBundleIdentifiers = ["com.parametric-forge.forge-jupyter"];
      };
    };
  }
  # Static host gate: top-level attr names must never depend on pkgs (fixpoint).
  // lib.optionalAttrs (host.os == "nixos") {
    systemd.user.services.forge-jupyter = {
      Unit.Description = "Forge JupyterLab (loopback, token-gated)";
      Service = {
        ExecStart = "${forgeJupyter}/bin/forge-jupyter";
        WorkingDirectory = forgeJupyterRootDir;
        Environment = ["FORGE_PROVISION_ROOT=${forgeJupyterRootDir}"];
        Restart = "always";
        RestartSec = 30;
      };
      Install.WantedBy = ["default.target"];
    };
  }
