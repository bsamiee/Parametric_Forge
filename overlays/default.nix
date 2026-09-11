# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/default.nix
# ----------------------------------------------------------------------------
# Row-folded package projection over overlays/manifest.nix: one binary-release template consumes asset rows; opt-runtime rows (energyplus,
# openstudio) share one recipe folding row-owned layout, env, and wrapper facts; the sqlite-forge shell kernel generates from its row's profile data;
# patch rows override upstream packages with row-owned facts; forge-provision is the one hand-authored kernel directory. Vocabulary validation runs
# here and is forced by the forge-package-manifest build.
final: prev: let
  manifest = import ./manifest.nix;
  generatedSources = import ./_sources/generated.nix {
    inherit (prev) fetchurl fetchgit fetchFromGitHub dockerTools;
  };
  inherit (prev) lib;
  system = prev.stdenv.hostPlatform.system;
  voc = manifest.vocabulary;

  checkRow = name: row:
    assert lib.assertMsg (lib.elem row.sourceKind voc.sourceKinds) "${name}: sourceKind '${row.sourceKind}' outside vocabulary";
    assert lib.assertMsg (lib.elem row.patchFamily voc.patchFamilies) "${name}: patchFamily '${row.patchFamily}' outside vocabulary";
    assert lib.assertMsg (lib.elem row.cacheClass voc.cacheClasses) "${name}: cacheClass '${row.cacheClass}' outside vocabulary";
    assert lib.assertMsg (lib.elem row.updateEngine voc.updateEngines) "${name}: updateEngine '${row.updateEngine}' outside vocabulary";
    assert lib.assertMsg (lib.elem row.versionPolicy voc.versionPolicies) "${name}: versionPolicy '${row.versionPolicy}' outside vocabulary";
    assert lib.assertMsg (lib.elem row.retention voc.retentionPolicies) "${name}: retention '${row.retention}' outside vocabulary";
    assert lib.assertMsg (!(row.projection ? overlay) || lib.elem row.projection.overlay voc.overlayModes) "${name}: projection.overlay '${row.projection.overlay or ""}' outside vocabulary";
    assert lib.assertMsg (lib.licenses ? ${row.license}) "${name}: license '${row.license}' not a lib.licenses key";
    assert lib.assertMsg (lib.all (f: row ? ${f}) ["description" "homepage"]) "${name}: package row missing description/homepage — every admission identifies what it admits and where it came from";
    assert lib.assertMsg ((row.projection.overlay or null) != "override" || row ? overlayReason) "${name}: overlay-override projection requires overlayReason";
    assert lib.assertMsg (!(row ? runtime) || lib.all (f: row.runtime ? ${f}) ["root" "shebangDirs" "env" "wrappers"]) "${name}: runtime spec missing root/shebangDirs/env/wrappers";
    # A source-build row names one generated pin, or — where the publisher emits a per-OS source tree — one pin per system under `sourcePins`;
    # both spellings resolve in `generatedSources`, so neither can name a pin nvfetcher never wrote.
    assert lib.assertMsg (!(row.updateEngine == "nvfetcher" && row.sourceKind == "source-build")
      || (row ? sourcePin && generatedSources ? ${row.sourcePin})
      || (row ? sourcePins && lib.all (pin: generatedSources ? ${pin}) (lib.attrValues row.sourcePins)))
    "${name}: nvfetcher source-build requires a generated sourcePin or a sourcePins map whose every member resolves";
    assert lib.assertMsg (!(row.updateEngine == "nvfetcher" && row.sourceKind != "source-build") || (row ? assets && lib.all (a: a ? pin && generatedSources ? ${a.pin}) (lib.attrValues row.assets)))
    "${name}: nvfetcher binary assets require generated pins"; row;

  checkAdmission = name: row:
    assert lib.assertMsg (lib.elem row.install voc.installModes) "${name}: install '${row.install}' outside vocabulary";
    assert lib.assertMsg (lib.elem row.roster voc.rosters) "${name}: roster '${row.roster}' outside vocabulary";
    assert lib.assertMsg (lib.elem row.updateEngine voc.updateEngines) "${name}: updateEngine '${row.updateEngine}' outside vocabulary";
    assert lib.assertMsg (lib.elem row.completion voc.completionKinds) "${name}: completion '${row.completion}' outside vocabulary";
    assert lib.assertMsg (lib.elem row.themeCarrier voc.themeCarriers) "${name}: themeCarrier '${row.themeCarrier}' outside vocabulary";
    assert lib.assertMsg (!(row ? completionArgs) || row.completion == "native") "${name}: completionArgs requires completion = \"native\"";
    # Attr absence is nixpkgs drift (rename/removal) or a typo, never a platform fact — nixpkgs attrs exist on every platform; fail loud.
    assert lib.assertMsg (prev ? ${row.attr}) "${name}: attr '${row.attr}' absent from the package set (nixpkgs drift or typo)"; row;

  # Lane admission contract: a row missing a required field fails the ledger build; each lane's `requiredFields` vocabulary is executable here.
  checkExtensionLane = lane: def:
    def
    // {
      rows =
        lib.mapAttrs (
          name: row:
            assert lib.assertMsg (lib.all (f: row ? ${f}) (def.requiredFields or []))
            "${lane}.${name}: row missing required fields (${lib.concatStringsSep " " (lib.filter (f: !(row ? ${f})) (def.requiredFields or []))})"; row
        )
        def.rows;
    };

  rowOf = name: checkRow name manifest.packages.${name};
  assetOf = name: row:
    row.assets.${system}
    or (throw "${name}: no asset row for ${system} (declared: ${lib.concatStringsSep " " (builtins.attrNames row.assets)})");
  # Generated sources retain nvfetcher's fetch semantics; manual rows select fetchzip for unpacked hashes or fetchurl for flat hashes.
  # A release archive lays its payload at the root and keeps the default; a source tarball owns its version directory and strips by row fact.
  srcOf = a:
    if a ? pin
    then generatedSources.${a.pin}.src
    else if (a.fetch or "url") == "zip"
    then
      prev.fetchzip {
        inherit (a) url hash;
        stripRoot = a.stripRoot or false;
      }
    else prev.fetchurl {inherit (a) url hash;};

  # Env vocabulary of an opt-runtime row projected at a root: names bind to the runtime root, root-relative subpaths, or the row version.
  runtimeEnvAt = row: root:
    lib.genAttrs row.runtime.env.roots (_: root)
    // lib.mapAttrs (_: sub: "${root}/${sub}") row.runtime.env.paths
    // lib.genAttrs row.runtime.env.version (_: row.version);

  # One derivation template for every binary-release row; recipes carry only the install kernel and unpack facts,
  # with finalAttrs threaded through for passthru projections.
  mkBinaryRelease = name: recipe: let
    row = rowOf name;
    a = assetOf name row;
  in
    prev.stdenvNoCC.mkDerivation (finalAttrs:
      {
        pname = name;
        inherit (row) version;
        src = srcOf a;
        dontConfigure = true;
        dontBuild = true;
        meta =
          {
            inherit (row) description homepage;
            license = lib.licenses.${row.license};
            platforms = builtins.attrNames row.assets;
          }
          // lib.optionalAttrs (row ? mainProgram) {inherit (row) mainProgram;};
      }
      // recipe {inherit row a finalAttrs;});

  # Shared opt-runtime recipe: the release tree lands under $out/<root>, each wrapper exports the row env before exec, and passthru.runtimeEnv serves
  # session-env consumers the same vocabulary at the installed root. A missing tool is upstream layout drift (patch_drift);
  # fail the build loudly, never ship a silently thinner bin/.
  optRuntime = {
    row,
    finalAttrs,
    ...
  }: let
    root = "${placeholder "out"}/${row.runtime.root}";
    wrapperText = target:
      lib.concatLines (
        ["#!${lib.getExe prev.bash}" "set -euo pipefail"]
        ++ lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") (runtimeEnvAt row root)
        ++ [''exec "${root}/${target}" "$@"'']
      );
    installWrapper = name: target: ''
      [ -x ${lib.escapeShellArg "${root}/${target}"} ] || {
        echo "${finalAttrs.pname}: expected tool '${target}' missing from the release layout" >&2
        exit 1
      }
      printf '%s' ${lib.escapeShellArg (wrapperText target)} >"$out/bin/${name}"
      chmod 0755 "$out/bin/${name}"
    '';
  in {
    nativeBuildInputs = [prev.bash];
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/${dirOf row.runtime.root}"
      cp -R . "$out/${row.runtime.root}"
      ${lib.concatMapStringsSep "\n" (d: ''patchShebangs "$out/${row.runtime.root}/${d}"'') row.runtime.shebangDirs}

      ${lib.concatStrings (lib.mapAttrsToList installWrapper row.runtime.wrappers)}
      runHook postInstall
    '';
    passthru.runtimeEnv = runtimeEnvAt row "${finalAttrs.finalPackage}/${row.runtime.root}";
  };

  recipes = {
    utiluti = _: {
      dontUnpack = true;
      nativeBuildInputs = [prev.xar prev.pbzx prev.cpio];
      installPhase = ''
        runHook preInstall
        xar -xf "$src"
        [ -f utiluti.pkg/Payload ] || { echo "utiluti: package payload layout changed" >&2; exit 1; }
        mkdir extracted
        pbzx -n utiluti.pkg/Payload | (cd extracted && cpio -idm)
        [ -x extracted/usr/local/bin/utiluti ] || { echo "utiluti: executable absent" >&2; exit 1; }
        [ -f extracted/usr/local/share/man/man1/utiluti.1 ] || { echo "utiluti: manual absent" >&2; exit 1; }
        install -Dm755 extracted/usr/local/bin/utiluti "$out/bin/utiluti"
        install -Dm644 extracted/usr/local/share/man/man1/utiluti.1 "$out/share/man/man1/utiluti.1"
        runHook postInstall
      '';
    };
    pandoc-current = _: {
      nativeBuildInputs = [prev.unzip] ++ lib.optional prev.stdenv.hostPlatform.isLinux prev.autoPatchelfHook;
      buildInputs = lib.optionals prev.stdenv.hostPlatform.isLinux [prev.gmp prev.zlib prev.stdenv.cc.cc.lib];
      installPhase = ''
        runHook preInstall
        [ -x bin/pandoc ] || { echo "pandoc: release executable layout changed" >&2; exit 1; }
        [ -d share/man ] || { echo "pandoc: release manual layout changed" >&2; exit 1; }
        mkdir -p "$out"
        cp -R bin share "$out/"
        runHook postInstall
      '';
    };
    verapdf-current = _: {
      dontUnpack = true;
      dontStrip = true;
      nativeBuildInputs = [prev.makeWrapper];
      installPhase = ''
        runHook preInstall
        install -Dm644 "$src" "$out/share/verapdf.jar"
        makeWrapper ${lib.getExe final.temurin-jre-current} "$out/bin/verapdf" --add-flags "-Dapp.home=$out/bin -jar $out/share/verapdf.jar"
        runHook postInstall
      '';
      doInstallCheck = true;
      nativeInstallCheckInputs = [prev.versionCheckHook];
      versionCheckProgram = "${placeholder "out"}/bin/verapdf";
    };
    temurin-jre-current = {finalAttrs, ...}: {
      nativeBuildInputs = [prev.makeWrapper] ++ lib.optional prev.stdenv.hostPlatform.isLinux prev.autoPatchelfHook;
      buildInputs = lib.optionals prev.stdenv.hostPlatform.isLinux [
        prev.alsa-lib
        prev.cups
        prev.fontconfig
        prev.freetype
        prev.libx11
        prev.libxext
        prev.libxi
        prev.libxrender
        prev.libxtst
        prev.zlib
        prev.stdenv.cc.cc.lib
      ];
      dontStrip = true;
      installPhase = ''
        runHook preInstall
        runtime=${
          if prev.stdenv.hostPlatform.isDarwin
          then "Contents/Home"
          else "."
        }
        [ -x "$runtime/bin/java" ] || { echo "temurin: JRE release layout changed" >&2; exit 1; }
        mkdir -p "$out/lib/openjdk" "$out/bin"
        cp -R "$runtime/". "$out/lib/openjdk/"
        makeWrapper "$out/lib/openjdk/bin/java" "$out/bin/java"
        runHook postInstall
      '';
      passthru.home = "${finalAttrs.finalPackage}/lib/openjdk";
    };
    # Flat single-binary release: no archive, the fetched file IS the tool.
    biome = _: {
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        install -Dm755 "$src" "$out/bin/biome"
        runHook postInstall
      '';
    };
    duckdb = _: {
      nativeBuildInputs = [prev.unzip];
      sourceRoot = ".";
      installPhase = ''
        runHook preInstall
        install -Dm755 duckdb "$out/bin/duckdb"
        runHook postInstall
      '';
    };
    # Stripped release tree: the unpacked directory holds exactly the one binary.
    ruff = _: {
      installPhase = ''
        runHook preInstall
        install -Dm755 ruff "$out/bin/ruff"
        runHook postInstall
      '';
    };
    # Library-only release: upstream ships extension modules, no CLI binary; an unmatched glob fails the install loudly on layout drift.
    sqlean = _: {
      installPhase = ''
        runHook preInstall
        install -Dm644 -t "$out/lib" ./*${prev.stdenv.hostPlatform.extensions.sharedLibrary}
        runHook postInstall
      '';
    };
    nodejs-bin_26 = {a, ...}: {
      pname = "nodejs-bin";
      sourceRoot = a.dir;
      nativeBuildInputs = lib.optionals prev.stdenv.hostPlatform.isLinux [
        prev.autoPatchelfHook
        prev.stdenv.cc.cc.lib
      ];
      # pnpm-only rail: npm/npx never reach the installed output (Node 26 dropped corepack from the distribution). A missing strip target is upstream
      # layout drift (patch_drift); fail the build loudly, never ship a silently fatter output.
      installPhase = let
        stripRows = ["bin/npm" "bin/npx" "lib/node_modules/npm"];
      in ''
        runHook preInstall
        mkdir -p "$out"
        cp -R . "$out"
        ${lib.concatMapStringsSep "\n" (row: ''
            [ -e "$out/${row}" ] || [ -L "$out/${row}" ] || {
              echo "nodejs-bin: expected strip target '${row}' missing from the release layout" >&2
              exit 1
            }
            rm -rf "$out/${row}"
          '')
          stripRows}
        runHook postInstall
      '';
    };
    energyplus = optRuntime;
    openstudio = optRuntime;
  };

  # OCP is the one python-overlay member nixpkgs carries no attr for, so the overlay mints it and the roster then takes it by name like every
  # sibling. The release publishes the generated binding tree per OS; the row's pin family keys by system and the host picks its own.
  ocpRow = rowOf "cadquery-ocp";
  ocpSource = generatedSources.${ocpRow.sourcePins.${system}}.src;

  # --- [CCACHE_LANE]
  # ccache rides the deep C++ builds as a CMake launcher rather than through ccacheStdenv: no stdenv reconstruction, it survives
  # buildPythonPackage (which takes no stdenv argument), and no other package's derivation hash moves. The cache dir is root:nixbld 0770 —
  # machine prep, one mkdir+chown. Iteration rebuilds with a frozen dep closure hit ~95-99%; a dep bump still pays full price by construction,
  # since the dependency store hash rides every compile line.
  ccacheEnv = {
    CCACHE_DIR = "/nix/var/cache/ccache";
    CCACHE_UMASK = "007";
    CCACHE_MAXSIZE = "60G";
    # Nix canonicalizes every store file to mtime 1, so ccache's default compiler_check (mtime+size) cannot tell two clang builds apart.
    CCACHE_COMPILERCHECK = "content";
    # reproducible-builds.sh exports -frandom-seed=<first 10 chars of $out>; unhandled, it drives the hit rate to zero on every rebuild.
    CCACHE_SLOPPINESS = "random_seed";
    CCACHE_NOHASHDIR = "1";
  };
  withCcache = drv:
    drv.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [prev.ccache];
      cmakeFlags = (old.cmakeFlags or []) ++ ["-DCMAKE_C_COMPILER_LAUNCHER=ccache" "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache"];
      env =
        (old.env or {})
        // ccacheEnv
        // {
          # Pin the reproducible-builds seed to package identity so the flag stops moving; it must ride the derivation env — the hook fires
          # before any phase.
          NIX_OUTPATH_USED_AS_RANDOM_SEED = old.pname or old.name;
        };
      # $NIX_BUILD_TOP is per-build, so the base dir can only be spelled inside the builder.
      preConfigure =
        (old.preConfigure or "")
        + ''
          export CCACHE_BASEDIR="$NIX_BUILD_TOP"
        '';
    });

  betaPolicy = (rowOf "forge-python-overlay-env").betaSet;

  # Removed-C-API shim for the beta interpreter: the macro expands to an immediately-invoked lambda holding the referent only across the call, which is
  # exactly the borrowed-reference contract PyWeakref_GetObject carried, and yields Py_None for an expired referent as that call did. It rides a
  # `-include` ahead of Python.h, so no roster member carries a patched call site and an upstream port to PyWeakref_GetRef retires it silently.
  betaCApiShim = prev.writeText "python315-capi-shim.h" ''
    #define PyWeakref_GetObject(ref)                     \
        ([](PyObject *_shimRef) -> PyObject * {          \
            PyObject *_shimObj = nullptr;                \
            (void)PyWeakref_GetRef(_shimRef, &_shimObj); \
            Py_XDECREF(_shimObj);                        \
            return _shimObj ? _shimObj : Py_None;        \
        }((ref)))
  '';

  # Native members of the beta closure take their escapes at the top level: the failing instance is an `.override` descendant reached through vtk, and an
  # overrideAttrs seated on the top-level attr survives every hop while the python-set lane never reaches it. The exported config pins the interpreter
  # the member itself built against, which is the only version its consumers can satisfy and the one cmake's own version list ends before; deriving the
  # pin in the builder keeps every interpreter flavor of the member self-consistent. A member exporting no such call is upstream drift — fail loudly.
  betaNativeMember = name:
    prev.${name}.overrideAttrs (old: {
      doCheck = false;
      postInstall =
        (old.postInstall or "")
        + ''
          pin=$(python3 -c 'import sys; print("%s.%s" % sys.version_info[:2])' 2>/dev/null || true)
          if [ -n "$pin" ]; then
            configs=$(grep -rl 'find_package(Python3 ' "$out/lib/cmake")
            [ -n "$configs" ] || {
              echo "${name}: exported cmake config issues no find_package(Python3 …); the version pin has no target" >&2
              exit 1
            }
            for config in $configs; do
              substituteInPlace "$config" --replace-fail 'find_package(Python3 ' "find_package(Python3 $pin EXACT "
            done
          fi
        '';
    });

  # Beta-set lane folded from the forge-python-overlay-env row: the escapes ride the two builders, so every package in the beta set inherits them and
  # a wider module roster never mints a per-package override, while the shim rides only its row roster and leaves every other member's hash alone.
  # Every other interpreter's set passes through untouched, keeping its cache hits.
  betaSetLane = _pyFinal: pyPrev: let
    escapes = betaPolicy.env // lib.optionalAttrs betaPolicy.dropChecks {doCheck = false;};
    wrap = build: args:
      build (
        if lib.isFunction args
        then (finalAttrs: args finalAttrs // escapes)
        else args // escapes
      );
    shim = name:
      pyPrev.${name}.overrideAttrs (old: {
        env = (old.env or {}) // {NIX_CFLAGS_COMPILE = "${old.env.NIX_CFLAGS_COMPILE or ""} -include ${betaCApiShim}";};
      });
  in
    lib.optionalAttrs (pyPrev.python.pythonVersion == betaPolicy.pythonVersion) ({
        buildPythonPackage = wrap pyPrev.buildPythonPackage;
        buildPythonApplication = wrap pyPrev.buildPythonApplication;
      }
      // lib.genAttrs betaPolicy.capiShimMembers shim);

  # NuGet global-tool fold: buildDotnetGlobalTool installs the pinned nupkg under the SDK-10 host and wraps the executable through useDotnetFromEnv,
  # so the `dotnet` on PATH (the estate's combined SDK) serves at runtime and the build SDK is only the fallback host. NuGet serves one immutable
  # nupkg per id+version from every endpoint, so the generated pin's hash proves the builder's own fetch.
  nugetRows = lib.filterAttrs (_: row: row.sourceKind == "nuget-tool") manifest.packages;
  mkNugetTool = name: _: let
    row = rowOf name;
  in
    prev.buildDotnetGlobalTool {
      pname = name;
      nugetName = row.nugetId;
      inherit (row) version;
      nugetHash = row.assets.any.hash;
      # Both rows name SDK 10: the builder's callPackage default would otherwise seat the nixpkgs default SDK as the fallback host closure.
      dotnet-sdk = prev.dotnetCorePackages.sdk_10_0;
      dotnet-runtime = prev.dotnetCorePackages.sdk_10_0;
      executables = name;
      meta = {
        inherit (row) description homepage;
        license = lib.licenses.${row.license};
        mainProgram = name;
      };
    };
  gcloudRow = rowOf "google-cloud-sdk";
  pnpmRow = rowOf "pnpm_11";
  astGrepRow = rowOf "ast-grep-upstream";
  astGrepSource = generatedSources.${astGrepRow.sourcePin};
  jsonschemaRow = rowOf "protoc-gen-jsonschema";
  jsonschemaSource = generatedSources.${jsonschemaRow.sourcePin};
  sourceRecipes = {
    nodejs-slim_26 = old: {
      # The native builder's test closes over its original version; keep the test tied to the selected source runtime.
      passthru =
        (removeAttrs old.passthru ["updateScript"])
        // {
          tests =
            old.passthru.tests
            // {
              version = prev.testers.testVersion {
                package = final.nodejs-slim_26;
                version = "v${final.nodejs-slim_26.version}";
              };
            };
        };
    };
    imagemagick = old: {
      configureFlags = (old.configureFlags or []) ++ ["--enable-hdri=yes" "--with-quantum-depth=16" "--with-lcms=yes"];
      postInstallCheck =
        (old.postInstallCheck or "")
        + ''
          features="$($out/bin/magick -version)"
          [[ "$features" == *Q16-HDRI* && "$features" == *lcms* ]] || { echo "ImageMagick: required Q16-HDRI/LCMS support absent" >&2; exit 1; }
        '';
    };
    harfbuzz = old: {
      # Nix enables auto features; retain the GPU library without the optional interactive demo's OpenGL window stack.
      mesonFlags = (map (flag: lib.replaceStrings ["-Dgraphite="] ["-Dgraphite2="] flag) (old.mesonFlags or [])) ++ [(lib.mesonEnable "gpu_demo" false)];
    };
    poppler-utils-current = old: let
      testData = generatedSources.${(rowOf "poppler-utils-current").testDataPin}.src;
      testFonts = final.makeFontsConf {
        fontDirectories = [(final.noto-fonts.override {variants = ["Noto Sans"];}) final.noto-fonts-cjk-sans-static];
        impureFontDirectories = [];
        includes = [];
      };
    in {
      # The sole old nixpkgs patch is merged in 26.09; HarfBuzz is now required for font subsetting.
      patches = [];
      buildInputs = old.buildInputs ++ [final.harfbuzz];
      # The new font-subsetting checks require August's form fixture and explicit Latin/Japanese fallback fonts.
      preConfigure = lib.replaceStrings [(toString old.passthru.testData)] [(toString testData)] old.preConfigure;
      # Nixpkgs' consumer tests close over its top-level Poppler. Retaining them here would test 26.06 while presenting the result as 26.09 coverage.
      passthru = (removeAttrs old.passthru ["tests" "updateScript"]) // {inherit testData;};
      disallowedReferences = map (ref:
        if ref == old.passthru.testData
        then testData
        else ref)
      old.disallowedReferences;
      preCheck =
        (old.preCheck or "")
        + ''
          export FONTCONFIG_FILE=${testFonts}
          export XDG_CACHE_HOME="$TMPDIR/fontconfig-cache"
          mkdir -p "$XDG_CACHE_HOME"
        '';
    };
    qpdf = old: {
      # Completion checks require bind/compgen/progcomp; stdenv's stripped Bash is not an interactive shell.
      nativeCheckInputs = (old.nativeCheckInputs or []) ++ [final.bashInteractive final.zsh];
      cmakeFlags = (old.cmakeFlags or []) ++ ["-DREQUIRE_SHELLS=ON"];
      preCheck =
        (old.preCheck or "")
        + ''
          export PATH=${lib.makeBinPath [final.bashInteractive final.zsh]}:$PATH
        '';
    };
    mupdf = old: {
      postInstall = lib.replaceStrings [old.version] [(rowOf "mupdf").version] old.postInstall;
    };
  };
  mkSourceRelease = name: _: let
    row = rowOf name;
    source = generatedSources.${row.sourcePin};
    base =
      if name == "imagemagick"
      then prev.imagemagick.override {lcms2Support = true;}
      else prev.${row.sourcePackage};
  in
    base.overrideAttrs (old:
      {
        inherit (row) version;
        inherit (source) src;
        passthru = removeAttrs (old.passthru or {}) ["updateScript"];
      }
      // (sourceRecipes.${name} or (_: {})) old);
in
  # Every binary-release attr derives from the recipes table: a next platform runtime or wrapped release is one manifest
  # row plus one recipe row, never a new output attr or kernel file.
  lib.mapAttrs mkBinaryRelease recipes
  // lib.mapAttrs mkSourceRelease (lib.filterAttrs (_: row: row ? sourcePackage) manifest.packages)
  // lib.mapAttrs mkNugetTool nugetRows
  // lib.genAttrs betaPolicy.nativeMembers betaNativeMember
  // {
    vega-cli = prev.vega-cli.override {
      buildNpmPackage = prev.buildNpmPackage.override {nodejs = final.nodejs_26;};
    };
    # nixpkgs 1.8.12 derives the install rpath by gluing CMAKE_INSTALL_PREFIX (dev) onto the already-absolute ALEMBIC_LIB_INSTALL_DIR (lib),
    # stamping a dev-prefixed LC_RPATH into the lib dylib; that back-reference closes a dev<->lib output cycle Darwin's registration refuses, felling
    # the whole vtk/openusd/OCP chain above it. Every load command already resolves by absolute store path, so the rpath is dead weight and fixup
    # deletes it — against the versioned name, loudly, so an upstream layout change fails the build instead of shipping the cycle back.
    alembic = prev.alembic.overrideAttrs (old: {
      postFixup =
        (old.postFixup or "")
        + lib.optionalString prev.stdenv.hostPlatform.isDarwin ''
          install_name_tool -delete_rpath "$dev/$lib/lib" "$lib/lib/libAlembic.${old.version}.dylib"
        '';
    });
    ast-grep-upstream = prev.ast-grep.overrideAttrs (old: {
      inherit (astGrepSource) version src;
      cargoDeps = prev.rustPlatform.importCargoLock astGrepSource.cargoLock."Cargo.lock";
      passthru = removeAttrs (old.passthru or {}) ["updateScript"];
    });
    # Go plugin with no protoc linkage: buildGoModule over the generated pin, one subpackage, the row's meta. vendorHash is the one hand-kept
    # value — nvfetcher cannot derive a Go vendor hash — and it re-keys on every pin advance.
    protoc-gen-jsonschema = prev.buildGoModule {
      pname = "protoc-gen-jsonschema";
      inherit (jsonschemaRow) version;
      inherit (jsonschemaSource) src;
      vendorHash = "sha256-1ticxBOa3GSsIGhlNqqS5EbT51mspVHaG/DBBpe5ypU=";
      subPackages = ["cmd/protoc-gen-jsonschema"];
      env.CGO_ENABLED = 0;
      # patchFamily source-substitute: protoplugin prints `Version()` on --version, which reads `(devel)` from a non-VCS build; seat the pin.
      postPatch = ''
        substituteInPlace internal/protoschema/protoschema.go \
          --replace-fail 'return "devel"' 'return "${jsonschemaRow.version}"' \
          --replace-fail 'ok && buildInfo != nil && buildInfo.Main.Version != ""' 'ok && buildInfo != nil && buildInfo.Main.Version != "" && buildInfo.Main.Version != "(devel)"'
      '';
      meta = {
        inherit (jsonschemaRow) description homepage mainProgram;
        license = lib.licenses.${jsonschemaRow.license};
      };
    };
    carbon-now-cli = prev.carbon-now-cli.overrideAttrs (old: {
      # patchFamily source-substitute: Node 26 rejects `assert { type: 'json' }`. No existence guard — an upstream layout or syntax change must fail
      # the build loudly (patch_drift), never ship an unpatched binary.
      postInstall =
        (old.postInstall or "")
        + ''
          substituteInPlace "$out/lib/node_modules/carbon-now-cli/dist/cli.js" \
            --replace-fail "assert { type: 'json' }" "with { type: 'json' }"
        '';
      # Update-notifier policy row: self-mutating configstore state is disabled at admission, never left as unowned config litter.
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [prev.makeBinaryWrapper];
      postFixup =
        (old.postFixup or "")
        + ''
          wrapProgram "$out/bin/carbon-now" --set NO_UPDATE_NOTIFIER 1
        '';
    });
    # Binary CLI overlays carry a release tree, not the crate/source layout the matching python distributions patch and build from, so each
    # python package pins back to its nixpkgs source-built lineage: duckdb is harlequin's engine.
    pythonPackagesExtensions =
      (prev.pythonPackagesExtensions or [])
      ++ [
        (_pyFinal: pyPrev:
          {
            duckdb = pyPrev.duckdb.override {inherit (prev) duckdb;};
            ruff = pyPrev.ruff.override {inherit (prev) ruff;};
          }
          # patchFamily darwin-install-name: upstream links the extension module against @rpath/libcurl-impersonate.4.dylib and seats no LC_RPATH, so
          # every import dies at dlopen and takes yt-dlp and mpv down with it. Seat the provider's lib dir; the row retires when nixpkgs links it.
          // lib.optionalAttrs (prev.stdenv.hostPlatform.isDarwin && pyPrev ? curl-cffi) {
            curl-cffi = pyPrev.curl-cffi.overrideAttrs (old: {
              postFixup =
                (old.postFixup or "")
                + ''
                  wrapper="$out/${pyPrev.python.sitePackages}/curl_cffi/_wrapper.abi3.so"
                  [ -f "$wrapper" ] || {
                    echo "curl-cffi: expected extension module missing from the release layout" >&2
                    exit 1
                  }
                  install_name_tool -add_rpath ${prev.curl-impersonate}/lib "$wrapper"
                '';
            });
          })
        betaSetLane
        # OCP lane: 639 generated translation units compiled as one pybind11 module against the nixpkgs OCCT the row's version pin matches, and
        # against the same VTK the overlay already builds for this interpreter, so the module and its renderer share one VTK. Only the beta
        # interpreter's set carries it, since every other flavor resolves the module from a published wheel.
        (_pyFinal: pyPrev:
          lib.optionalAttrs (pyPrev.python.pythonVersion == betaPolicy.pythonVersion) {
            cadquery-ocp = withCcache (pyPrev.buildPythonPackage {
              pname = "cadquery-ocp";
              inherit (ocpRow) version;
              src = ocpSource;
              format = "other";
              nativeBuildInputs = [prev.cmake prev.ninja pyPrev.pybind11];
              # The generated tree binds IVtk/IVtkOCC, OCCT's VTK bridge, so the kernel builds with its VTK integration against the same VTK the
              # module links — one VTK per process, per the row's shared-renderer law.
              buildInputs = [
                (withCcache (prev.opencascade-occt.override {
                  withVtk = true;
                  inherit (pyPrev) vtk;
                }))
                prev.fmt
                # The kernel builds USE_RAPIDJSON, and its RWGltf writer headers include rapidjson directly, so the header set rides every
                # consumer compile line.
                prev.rapidjson
                prev.tbb_2022
                pyPrev.vtk
              ];
              dontUseCmakeConfigure = false;
              # The generated tree names its own module directory, which cmake installs into; the wheelless `other` format then needs the
              # site-packages root spelled for it.
              cmakeFlags = [
                "-DPYTHON_SP_DIR=${placeholder "out"}/${pyPrev.python.sitePackages}"
                "-DCMAKE_BUILD_TYPE=Release"
                # cmake's own FindPython version list ends before the beta interpreter, so a bare `find_package(Python ...)` searches for
                # interpreter names it never enumerates. Naming the interpreter hands it the version instead of asking it to guess one.
                "-DPython_EXECUTABLE=${pyPrev.python.pythonOnBuildForHost.interpreter}"
              ];
              # pybind11 3.x asserts the GIL is held on every inc/dec-ref. OCP parks each registered exception in a function-local static whose
              # destructor runs after Py_Finalize, which trips that assert at interpreter shutdown and aborts the process. Leaking the static is the
              # upstream-correct shape for a translator that must outlive teardown, and it retires the moment upstream moves to py::set_error.
              postPatch = ''
                substituteInPlace OCP_specific.inc \
                  --replace-fail "static py::exception<CppException> ex;" \
                    "static py::exception<CppException> &ex = *new py::exception<CppException>();"
              '';
              pythonImportsCheck = ["OCP"];
              meta = {
                inherit (ocpRow) description homepage;
                license = lib.licenses.${ocpRow.license};
              };
            });
          })
      ];
    forge-package-manifest = prev.writeTextFile {
      name = "forge-package-manifest";
      destination = "/share/forge/manifest.json";
      text = builtins.toJSON {
        inherit (manifest) vocabulary;
        extensions = lib.mapAttrs checkExtensionLane manifest.extensions;
        # Nixpkgs-followed package rows carry no frozen version copy; the ledger resolves the live pin from the package set, mirroring admissions.
        packages =
          lib.mapAttrs (
            name: row:
              checkRow name row
              // lib.optionalAttrs (row.sourceKind == "nixpkgs") {
                resolved = {
                  version = prev.${name}.version or null;
                  state = "current";
                };
              }
          )
          manifest.packages;
        # Admission pins resolve live from the package set — never frozen copies. Platform support is a meta.platforms fact (availableOn), not attr
        # presence; checkAdmission already made a missing attr a loud failure.
        admissions =
          lib.mapAttrs (
            name: row:
              checkAdmission name row
              // {
                resolved =
                  if lib.meta.availableOn prev.stdenv.hostPlatform prev.${row.attr}
                  then {
                    version = prev.${row.attr}.version or null;
                    state = "current";
                  }
                  else {
                    version = null;
                    state = "unsupported_platform";
                  };
              }
          )
          manifest.admissions;
      };
    };
    forge-provision = final.callPackage ./forge-provision {};
    # Reached only through legacyPackages and built on demand by forge-python-overlay — never by the system closure or the qa package smoke; the
    # build verb pushes the realized closure to the forge cache (manifest cacheClass), so a GC, a rollback, or a sibling darwin host substitutes
    # instead of repaying the vtk/openusd/OCP compile.
    forge-python-overlay-env = final.python315.withPackages (ps: map (m: ps.${m}) (rowOf "forge-python-overlay-env").modules);
    google-cloud-sdk =
      if gcloudRow.assets ? ${system}
      then
        prev.google-cloud-sdk.overrideAttrs (_old: {
          inherit (gcloudRow) version;
          src = srcOf gcloudRow.assets.${system};
          doInstallCheck = true;
          installCheckPhase = ''
            export HOME=$(mktemp -d)

            gcloud_version="$($out/bin/gcloud version --format json | ${prev.jq}/bin/jq -r '."Google Cloud SDK"')"
            test "$gcloud_version" = "${gcloudRow.version}"

            gsutil_version="$($out/bin/gsutil version | sed -n 's/^gsutil version: //p')"
            expected_gsutil_version="$(cat "$out/google-cloud-sdk/platform/gsutil/VERSION")"
            test "$gsutil_version" = "$expected_gsutil_version"
          '';
        })
      else prev.google-cloud-sdk;
    pnpm = final.pnpm_11;
    pnpm_11 = prev.pnpm_11.overrideAttrs (old: {
      inherit (pnpmRow) version;
      src = srcOf pnpmRow.assets.any;
      # patchFamily shebang-retarget: nixpkgs nodejs-slim aborts on a libuv kqueue EINTR assertion at Darwin teardown; Node 26 exits clean.
      postFixup =
        (old.postFixup or "")
        + ''
          for entry in "$out"/libexec/pnpm/bin/pnpm.{cjs,mjs} "$out"/libexec/pnpm/bin/pnpx.{cjs,mjs}; do
            sed -i "1s|^#!.*/node$|#!${final.nodejs-bin_26}/bin/node|" "$entry"
          done
        '';
    });
    # `rust-bin` arrives from the rust-overlay extension the flake composes ahead of this fold; an unpinnable version fails eval at the channel
    # manifest, and the profile row selects the component set.
    rust-toolchain = let
      row = rowOf "rust-toolchain";
    in
      prev.rust-bin.stable.${row.version}.${row.profile};
    # SQLite shell kernel generated from the manifest row: base modules load on every profile, profile rows add extras, `all` derives as their union.
    sqlite-forge = let
      row = rowOf "sqlite-forge";
      ext = prev.stdenv.hostPlatform.extensions.sharedLibrary;
      profiles =
        row.shell.profiles
        // {all = lib.unique (lib.concatLists (lib.attrValues row.shell.profiles));};
      arm = name: mods: "  ${name}) ${lib.optionalString (mods != []) "modules+=(${toString mods}) "};;";
    in
      final.writeShellApplication {
        name = "sqlite-forge";
        runtimeInputs = [final.sqlite-interactive];
        text = ''
          profile="''${SQLITE_FORGE_PROFILE:-safe}"
          modules=(${toString row.shell.baseModules})
          case "$profile" in
          ${lib.concatLines (lib.mapAttrsToList arm profiles)}  *)
              printf 'sqlite-forge: unknown SQLITE_FORGE_PROFILE=%s; expected one of: ${toString (lib.attrNames profiles)}\n' "$profile" >&2
              exit 2
              ;;
          esac

          # exec skips EXIT traps, so the init script rides a process-substitution fd instead of a temp file a trap must reap.
          exec sqlite3 -init <(
            printf '.load ${final.sqlean}/lib/%s${ext}\n' "''${modules[@]}"
            printf '.load %s\n' '${final.sqlite-vec}/lib/vec0${ext}' '${final.libspatialite}/lib/mod_spatialite${ext}'
          ) "$@"
        '';
      };
  }
