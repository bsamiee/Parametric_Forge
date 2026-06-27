# Title         : scientific-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/scientific-tools.nix
# ----------------------------------------------------------------------------
# Native scientific build/runtime toolchain for source-built Python packages,
# geospatial/data libraries, numerical kernels, and local provisioning probes.
{
  config,
  lib,
  pkgs,
  ...
}: let
  darwinMinVersion = pkgs.stdenv.hostPlatform.darwinMinVersion or "14.0";
  sharedLibExt = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;

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
    pdal
  ];

  aecNativeTools = with pkgs; [
    gmsh
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

  scientificRuntimeTools = with pkgs;
    [
      onnxruntime
    ]
    ++ aecNativeTools;

  companionNativeLibs =
    geoNativeLibs
    ++ numericNativeLibs
    ++ pointCloudNativeLibs;

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
  companionPkgConfigPath = lib.concatStringsSep ":" [
    (lib.makeSearchPathOutput "dev" "lib/pkgconfig" companionNativeLibs)
    (lib.makeSearchPathOutput "out" "lib/pkgconfig" companionNativeLibs)
    (lib.makeSearchPathOutput "dev" "share/pkgconfig" companionNativeLibs)
    (lib.makeSearchPathOutput "out" "share/pkgconfig" companionNativeLibs)
  ];
  companionCmakePrefixPath = lib.concatStringsSep ":" (map toString companionNativeLibs);
  forgePythonStateHome = config.xdg.stateHome;
  forgeJupyterTokenFile = "${config.xdg.configHome}/jupyter/forge-token.env";
  forgeJupyterLogDir = "${config.xdg.stateHome}/forge-jupyter/log";
  forgeJupyterTokenPrelude = ''
    token_file=${lib.escapeShellArg forgeJupyterTokenFile}
    if [ -z "''${JUPYTER_TOKEN:-}" ] && [ -f "$token_file" ]; then
      # shellcheck source=/dev/null
      . "$token_file"
    fi
    if [ -z "''${JUPYTER_TOKEN:-}" ]; then
      printf 'forge-jupyter: missing JUPYTER_TOKEN; expected %s\n' "$token_file" >&2
      exit 1
    fi
    export JUPYTER_TOKEN
  '';
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
      git rev-parse --show-toplevel 2>/dev/null || pwd -P
    }

    forge_python_root_key() {
      forge_python_root | tr -d '\n' | sha256sum | cut -c1-12
    }

    forge_python_env_default() {
      abi="$(${python}/bin/python3 -c 'import sys; print(sys.implementation.cache_tag)')"
      root_key="$(forge_python_root_key)"
      state_home=${lib.escapeShellArg forgePythonStateHome}
      printf '%s/forge-python-envs/%s/%s/${profile}\n' "$state_home" "$abi" "$root_key"
    }

    if [ -z "''${UV_PROJECT_ENVIRONMENT:-}" ]; then
      UV_PROJECT_ENVIRONMENT="$(forge_python_env_default)"
      export UV_PROJECT_ENVIRONMENT
    fi
  '';
  forgeScientificEnv = pkgs.writeShellApplication {
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

      export PKG_CONFIG_PATH="${pkgConfigPath}''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
      export CMAKE_PREFIX_PATH="${cmakePrefixPath}''${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"

      exec "$@"
    '';
  };
  forgeCompanionEnv = pkgs.writeShellApplication {
    name = "forge-companion-env";
    # Rasm's Python branch keeps a cp315 core and a cp312 companion lane for
    # native geometry/IFC and codegen packages gated below Python 3.13/3.15.
    runtimeInputs = nativeBuildTools ++ companionNativeLibs ++ [pkgs.coreutils pkgs.git pkgs.uv pkgs.python312];
    text = ''
      ${forgePythonEnvPrelude pkgs.python312 "companion"}
      export UV_PYTHON_PREFERENCE="only-system"
      export UV_PYTHON_DOWNLOADS="never"
      export MACOSX_DEPLOYMENT_TARGET="${darwinMinVersion}"
      export CC="${pkgs.clang}/bin/clang"
      export CXX="${pkgs.clang}/bin/clang++"
      export PKG_CONFIG_PATH="${companionPkgConfigPath}''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
      export CMAKE_PREFIX_PATH="${companionCmakePrefixPath}''${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
      exec "$@"
    '';
  };
  forgeScientificSync = pkgs.writeShellApplication {
    name = "forge-scientific-sync";
    runtimeInputs = [forgeScientificEnv pkgs.coreutils pkgs.git pkgs.python315 pkgs.uv];
    text = ''
      ${forgePythonEnvPrelude pkgs.python315 "scientific"}
      exec forge-scientific-env uv sync --locked --group scientific "$@"
    '';
  };
  forgeJupyterServerConfig = pkgs.writeText "forge-jupyter-server-config.py" ''
    import os

    c = get_config()
    c.IdentityProvider.token = os.environ["JUPYTER_TOKEN"]
  '';
  forgeIfcMcp = pkgs.writeShellScriptBin "forge-ifcmcp" ''
    exec ${forgeCompanionEnv}/bin/forge-companion-env uvx --from "ifcopenshell-mcp[mcp]==0.8.5" ifcmcp "$@"
  '';
  forgeJupyter = pkgs.writeShellScriptBin "forge-jupyter" ''
    ${forgeJupyterTokenPrelude}
    exec ${forgeCompanionEnv}/bin/forge-companion-env uvx \
      --from "jupyterlab==4.6.0" --with "jupyter-collaboration==4.4.1" --with "jupyter-mcp-tools==0.1.6" \
      jupyter-lab --no-browser --ServerApp.ip=127.0.0.1 --ServerApp.port=8888 \
      --ServerApp.port_retries=0 \
      --config=${lib.escapeShellArg forgeJupyterServerConfig} "$@"
  '';
  forgeJupyterMcp = pkgs.writeShellScriptBin "forge-jupyter-mcp" ''
    ${forgeJupyterTokenPrelude}
    exec ${forgeCompanionEnv}/bin/forge-companion-env uvx --from "jupyter-mcp-server==1.0.2" jupyter-mcp-server "$@"
  '';
in {
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

    file."Applications/Forge Jupyter.app/Contents/Info.plist".text = ''
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

    activation = {
      registerForgeJupyterApp = lib.hm.dag.entryAfter ["linkGeneration"] ''
        app="$HOME/Applications/Forge Jupyter.app"
        lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
        if [ -d "$app" ] && [ -x "$lsregister" ]; then
          "$lsregister" -f "$app" || true
        fi
      '';

      ensureForgeJupyterToken = lib.hm.dag.entryAfter ["linkGeneration"] ''
        token_file=${lib.escapeShellArg forgeJupyterTokenFile}
        tmp_file="$token_file.tmp.$$"
        mkdir -p "$(dirname "$token_file")"
        if [ ! -s "$token_file" ]; then
          token="$(${pkgs.openssl}/bin/openssl rand -hex 32)"
          ( umask 077; printf 'export JUPYTER_TOKEN=%s\n' "$token" >"$tmp_file" )
          chmod 600 "$tmp_file"
          mv -f "$tmp_file" "$token_file"
        fi
        chmod 600 "$token_file"
      '';

      ensureForgeJupyterLogDir = lib.hm.dag.entryAfter ["linkGeneration"] ''
        ${pkgs.coreutils}/bin/install -d -m 700 ${lib.escapeShellArg forgeJupyterLogDir}
      '';

      registerJupyterScientificKernel = lib.hm.dag.entryAfter ["linkGeneration"] ''
        sci_env=$(${pkgs.findutils}/bin/find ${lib.escapeShellArg "${forgePythonStateHome}/forge-python-envs"} -maxdepth 3 -type d -name scientific 2>/dev/null | ${pkgs.coreutils}/bin/head -n 1)
        if [ -n "$sci_env" ] && [ -x "$sci_env/bin/python" ]; then
          "$sci_env/bin/python" -m ipykernel install --user --name forge-scientific --display-name "Python 3.15 (forge-scientific)" 2>/dev/null || true
        fi
      '';
    };
  };

  launchd.agents.forge-jupyter = {
    enable = true;
    config = {
      ProgramArguments = ["${forgeJupyter}/bin/forge-jupyter"];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      StandardOutPath = "${forgeJupyterLogDir}/out.log";
      StandardErrorPath = "${forgeJupyterLogDir}/err.log";
      AssociatedBundleIdentifiers = ["com.parametric-forge.forge-jupyter"];
    };
  };
}
