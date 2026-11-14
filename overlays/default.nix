final: prev: let
  manifest = import ./manifest.nix;
  generatedSources = import ./_sources/generated.nix {
    inherit (prev) fetchurl fetchgit fetchFromGitHub dockerTools;
  };
  inherit (prev) lib;
  system = prev.stdenv.hostPlatform.system;

  srcOf = a:
    if (a.fetch or "url") == "zip"
    then
      prev.fetchzip {
        inherit (a) url hash;
        stripRoot = a.stripRoot or true;
        extension = a.extension or null;
      }
    else if a ? pin
    then generatedSources.${a.pin}.src
    else prev.fetchurl {inherit (a) url hash;};

  linkTree = src: dst: ''lndir -silent ${src} ${dst}'';

  runtimeEnvAt = row: root:
    lib.genAttrs row.runtime.env.roots (_: root)
    // lib.mapAttrs (_: sub: "${root}/${sub}") row.runtime.env.paths;

  mkBinaryRelease = name: recipe: let
    row = manifest.packages.${name};
    a = row.assets.${system};
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

  optRuntime = {row, ...}: let
    root = "${placeholder "out"}/${row.runtime.root}";
    installWrapper = name: target: ''
      makeWrapper ${lib.escapeShellArg "${root}/${target}"} "$out/bin/${name}" ${
        lib.concatStringsSep " " (lib.mapAttrsToList (var: value: "--set ${var} ${lib.escapeShellArg value}") (runtimeEnvAt row root))
      }
    '';
  in {
    nativeBuildInputs = [prev.bash prev.lndir prev.makeWrapper];
    dontUnpack = true;
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/${row.runtime.root}"
      ${linkTree ''"$src"'' ''"$out/${row.runtime.root}"''}
      ${lib.concatMapStringsSep "\n" (d:
        if d == "."
        then ''
          find "$src" -maxdepth 1 -type f -print0 | while IFS= read -r -d "" file; do
            [ "$(head -c 2 "$file")" = '#!' ] || continue
            rm -f "$out/${row.runtime.root}/$(basename "$file")"
            cp "$file" "$out/${row.runtime.root}/"
          done
          chmod -R u+w "$out/${row.runtime.root}"
          patchShebangs "$out/${row.runtime.root}"
        ''
        else ''
          rm -r "$out/${row.runtime.root}/${d}"
          cp -R "$src/${d}" "$out/${row.runtime.root}/${d}"
          chmod -R u+w "$out/${row.runtime.root}/${d}"
          patchShebangs "$out/${row.runtime.root}/${d}"
        '')
      row.runtime.shebangDirs}

      ${lib.concatStrings (lib.mapAttrsToList installWrapper row.runtime.wrappers)}
      runHook postInstall
    '';
    passthru.runtimeEnvAt = profile: runtimeEnvAt row "${profile}/${row.runtime.root}";
  };

  cliRelease = {
    binary,
    completion ? null,
    man ? null,
    versionArg ? "--version",
    unpack ? true,
  }: {row, ...}:
    {
      nativeBuildInputs = [prev.installShellFiles];
      installPhase = ''
        runHook preInstall
        install -Dm755 ${binary} "$out/bin/${row.mainProgram}"
        ${lib.optionalString (man != null) "installManPage ${man}"}
        ${lib.optionalString (completion != null) ''
          export HOME="$TMPDIR"
          installShellCompletion --cmd ${row.mainProgram} \
            --bash <("$out/bin/${row.mainProgram}" ${completion} bash) \
            --fish <("$out/bin/${row.mainProgram}" ${completion} fish) \
            --zsh <("$out/bin/${row.mainProgram}" ${completion} zsh)
        ''}
        runHook postInstall
      '';
      doInstallCheck = true;
      nativeInstallCheckInputs = [prev.versionCheckHook];
      versionCheckProgram = "${placeholder "out"}/bin/${row.mainProgram}";
      versionCheckProgramArg = versionArg;
      versionCheckKeepEnvironment = "HOME";
    }
    // (
      if unpack
      then {sourceRoot = ".";}
      else {dontUnpack = true;}
    );

  recipes = {
    gogcli-current = cliRelease {
      binary = "gog";
      completion = "completion";
    };
    hostinger = cliRelease {
      binary = "hostinger";
      completion = "completion";
      man = "manpages/*.1";
      versionArg = "version";
    };
    gh-current = cliRelease {
      binary = ''"$src/bin/gh"'';
      completion = "completion -s";
      man = ''"$src"/share/man/man1/*.1'';
      unpack = false;
    };
    nh-current = cliRelease {
      binary = ''"$src"'';
      unpack = false;
    };
    atuin-current = cliRelease {
      binary = ''"$src/atuin"'';
      completion = "gen-completions --shell";
      unpack = false;
    };
    mq = cliRelease {
      binary = ''"$src"'';
      completion = "completion";
      unpack = false;
    };
    tscli-current = cliRelease {binary = "tscli";};
    officecli-current = cliRelease {
      binary = ''"$src"'';
      unpack = false;
    };
    curl-impersonate-current = _: {
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        install -Dm755 -t "$out/bin" "$src"/curl*
        runHook postInstall
      '';
      doInstallCheck = true;
      nativeInstallCheckInputs = [prev.versionCheckHook];
      versionCheckProgram = "${placeholder "out"}/bin/curl-impersonate";
    };
    gam-current = _: {
      dontUnpack = true;
      dontFixup = true;
      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin" "$out/lib"
        cp -R "$src" "$out/lib/gam7"
        ln -s "$out/lib/gam7/gam" "$out/bin/gam"
        runHook postInstall
      '';
    };
    yq-go-current = cliRelease {
      binary = "yq_darwin_arm64";
      completion = "completion";
      man = "yq.1";
    };
    sqruff-current = cliRelease {binary = "sqruff";};
    oha-current = cliRelease {
      binary = ''"$src"'';
      completion = "--completions";
      unpack = false;
    };
    dua-current = cliRelease {
      binary = "*/dua";
      completion = "completions";
    };
    hurl-current = _: {
      nativeBuildInputs = [prev.installShellFiles];
      installPhase = ''
        runHook preInstall
        install -Dm755 -t "$out/bin" bin/hurl bin/hurlfmt
        installManPage man/man1/*.1.gz
        installShellCompletion --cmd hurl --bash completions/hurl.bash --fish completions/hurl.fish --zsh completions/_hurl
        installShellCompletion --cmd hurlfmt --bash completions/hurlfmt.bash --fish completions/hurlfmt.fish --zsh completions/_hurlfmt
        runHook postInstall
      '';
      doInstallCheck = true;
      nativeInstallCheckInputs = [prev.versionCheckHook];
      versionCheckProgram = "${placeholder "out"}/bin/hurl";
    };
    utiluti = _: {
      dontUnpack = true;
      nativeBuildInputs = [prev.xar prev.pbzx prev.cpio];
      installPhase = ''
        runHook preInstall
        xar -xf "$src"
        mkdir extracted
        pbzx -n utiluti.pkg/Payload | (cd extracted && cpio -idm)
        install -Dm755 extracted/usr/local/bin/utiluti "$out/bin/utiluti"
        install -Dm644 extracted/usr/local/share/man/man1/utiluti.1 "$out/share/man/man1/utiluti.1"
        runHook postInstall
      '';
    };
    _1password-cli-current = _: {
      dontUnpack = true;
      dontStrip = true;
      nativeBuildInputs = [prev.installShellFiles prev.xar prev.cpio];
      installPhase = ''
        runHook preInstall
        xar -xf "$src"
        gzip -dc op.pkg/Payload | cpio -i
        install -Dm755 op "$out/bin/op"
        export HOME="$TMPDIR"
        installShellCompletion --cmd op \
          --bash <("$out/bin/op" completion bash) \
          --fish <("$out/bin/op" completion fish) \
          --zsh <("$out/bin/op" completion zsh)
        runHook postInstall
      '';
      doInstallCheck = true;
      nativeInstallCheckInputs = [prev.versionCheckHook];
      versionCheckProgram = "${placeholder "out"}/bin/op";
    };
    pandoc-current = _: {
      dontUnpack = true;
      nativeBuildInputs = [prev.lndir];
      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin" "$out/share"
        ${linkTree ''"$src/bin"'' ''"$out/bin"''}
        ${linkTree ''"$src/share"'' ''"$out/share"''}
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
        makeWrapper ${lib.getExe prev.temurin-jre-bin-27} "$out/bin/verapdf" --add-flags "-Dapp.home=$out/bin -jar $out/share/verapdf.jar"
        runHook postInstall
      '';
      doInstallCheck = true;
      nativeInstallCheckInputs = [prev.versionCheckHook];
      versionCheckProgram = "${placeholder "out"}/bin/verapdf";
    };
    biome-current = _: {
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        install -Dm755 "$src" "$out/bin/biome"
        runHook postInstall
      '';
    };
    mise-current = _: {
      nativeBuildInputs = [prev.installShellFiles];
      installPhase = ''
        runHook preInstall
        install -Dm755 bin/mise "$out/bin/mise"
        installManPage man/man1/mise.1
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME" "$out/lib/mise"
        touch "$out/lib/mise/.disable-self-update"
        installShellCompletion --cmd mise \
          --bash <("$out/bin/mise" completion bash) \
          --fish <("$out/bin/mise" completion fish) \
          --zsh <("$out/bin/mise" completion zsh)
        runHook postInstall
      '';
    };
    watchexec-current = _: {
      dontUnpack = true;
      nativeBuildInputs = [prev.installShellFiles];
      installPhase = ''
        runHook preInstall
        install -Dm755 "$src/watchexec" "$out/bin/watchexec"
        installManPage "$src/watchexec.1"
        installShellCompletion --cmd watchexec \
          --bash "$src/completions/bash" \
          --fish "$src/completions/fish" \
          --zsh "$src/completions/zsh"
        runHook postInstall
      '';
      doInstallCheck = true;
      nativeInstallCheckInputs = [prev.versionCheckHook];
      versionCheckProgram = "${placeholder "out"}/bin/watchexec";
    };
    duckdb-current = _: {
      sourceRoot = ".";
      installPhase = ''
        runHook preInstall
        install -Dm755 duckdb "$out/bin/duckdb"
        runHook postInstall
      '';
      doInstallCheck = true;
      nativeInstallCheckInputs = [prev.versionCheckHook];
      versionCheckProgram = "${placeholder "out"}/bin/duckdb";
    };
    sqlean = _: {
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        install -Dm644 -t "$out/lib" "$src"/*${prev.stdenv.hostPlatform.extensions.sharedLibrary}
        runHook postInstall
      '';
    };
    vl-convert = _: {
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        install -Dm755 "$src/vl-convert" "$out/bin/vl-convert"
        runHook postInstall
      '';
      doInstallCheck = true;
      nativeInstallCheckInputs = [prev.versionCheckHook];
      versionCheckProgram = "${placeholder "out"}/bin/vl-convert";
    };
    energyplus = optRuntime;
    openstudio = optRuntime;
  };

  sourceRecipes = {
    mupdf-current = old: {
      patches = [./mupdf-darwin-system-deps.patch (prev.path + "/pkgs/by-name/mu/mupdf/fix-cpp-build.patch")];
      postInstall = lib.replaceStrings [old.version] [manifest.packages.mupdf-current.version] old.postInstall;
    };
    fonttools-current = old: let
      extras = prev.python3Packages.fonttools.optional-dependencies;
    in {
      propagatedBuildInputs = old.propagatedBuildInputs ++ extras.woff ++ extras.unicode;
    };
    librsvg-current = _: {
      cargoDeps = prev.rustPlatform.importCargoLock generatedSources.design-librsvg.cargoLock."Cargo.lock";
    };
    resvg-current = _: {
      cargoDeps = prev.rustPlatform.importCargoLock generatedSources.resvg.cargoLock."Cargo.lock";
    };
    powershell-current = old: {
      nativeBuildInputs = old.nativeBuildInputs ++ [prev.unzip];
      postInstall = lib.concatStrings (lib.mapAttrsToList (name: module: ''
          mkdir -p "$out/share/powershell/Modules/${name}"
          unzip -q ${srcOf module.asset} -d "$out/share/powershell/Modules/${name}/${module.version}" -x "_rels/*" "package/*" "[[]Content_Types].xml" "*.nuspec"
        '')
        manifest.packages.powershell-current.modules);
    };
    rsync-current = old: {
      buildInputs = old.buildInputs ++ [prev.libidn2];
    };
  };
  mkSourceRelease = name: row: let
    src = srcOf row.asset;
  in
    (prev.${row.sourcePackage}.override (row.sourceOverride or {})).overrideAttrs (old:
      {
        inherit (row) version;
        doCheck = false;
        doInstallCheck = false;
        passthru = removeAttrs (old.passthru or {}) ["updateScript"];
      }
      // (
        if old ? srcs
        then {srcs = [src];}
        else {inherit src;}
      )
      // (sourceRecipes.${name} or (_: {})) old);
in
  lib.mapAttrs mkBinaryRelease recipes
  // lib.mapAttrs mkSourceRelease (lib.filterAttrs (_: row: row ? sourcePackage) manifest.packages)
  // {
    nvfetcher-current = prev.haskell.lib.overrideCabal prev.nvfetcher (_: {
      inherit (manifest.packages.nvfetcher-current) version;
      src = srcOf manifest.packages.nvfetcher-current.asset;
    });
    ocrmypdf-current = let
      row = manifest.packages.ocrmypdf-current;
      python = prev.python3.override {
        packageOverrides = pythonFinal: pythonPrev: let
          overrides = {
            ocrmypdf = old: {
              build-system = [pythonFinal.hatchling];
              nativeCheckInputs = old.nativeCheckInputs ++ [pythonFinal.numpy];
              postPatch =
                (old.postPatch or "")
                + ''
                  substituteInPlace tests/test_plugin_manager.py \
                    --replace-fail "monkeypatch.setattr(ocrmypdf.builtin_plugins, '__path__', [])" \
                    "monkeypatch.setattr(pkgutil, 'iter_modules', lambda *args, **kwargs: iter(()))"
                '';
            };
            pikepdf = old: {
              nativeCheckInputs = old.nativeCheckInputs ++ old.optional-dependencies.pdfa ++ [pythonFinal.pytest-timeout];
            };
            pydantic = old: {
              patches = [];
              nativeCheckInputs = old.nativeCheckInputs ++ [prev.python3Packages.pytest-examples];
            };
            pydantic-core = old: {
              cargoDeps = prev.rustPlatform.importCargoLock generatedSources.ocr-pydantic-core.cargoLock."pydantic-core/Cargo.lock";
              passthru =
                old.passthru
                // {
                  tests =
                    old.passthru.tests
                    // {
                      pytest = pythonFinal.pydantic-core.overridePythonAttrs {doCheck = true;};
                    };
                };
            };
            pypdfium2 = old: let
              release = builtins.fromJSON (builtins.readFile generatedSources.ocr-pypdfium2.extract."autorelease/record.json");
              ctypesgen = prev.fetchFromGitHub {
                owner = "pypdfium2-team";
                repo = "ctypesgen";
                rev = release.ctypesgen;
                hash = row.ctypesgenHash;
              };
            in {
              postPatch = ''
                mkdir -p deps
                ln -s ${ctypesgen} deps/ctypesgen
              '';
              passthru = old.passthru // {inherit ctypesgen;};
            };
          };
        in
          lib.mapAttrs (name: source:
            pythonPrev.${name}.overridePythonAttrs (old:
              {
                inherit (source) version;
                src = (srcOf source.asset) // {tag = lib.removeSuffix ".tar.gz" (baseNameOf source.asset.url);};
                meta =
                  old.meta
                  // lib.optionalAttrs (old.meta ? changelog) {
                    changelog = lib.replaceStrings [old.version] [source.version] old.meta.changelog;
                  };
              }
              // (overrides.${name} or (_: {})) old))
          row.pythonPackages;
      };
    in
      python.pkgs.toPythonApplication python.pkgs.ocrmypdf;
    sqlite-extended = let
      row = manifest.packages.sqlite-extended;
      ext = prev.stdenv.hostPlatform.extensions.sharedLibrary;
      profiles =
        row.shell.profiles
        // {all = lib.unique (lib.concatLists (lib.attrValues row.shell.profiles));};
      arm = name: mods: "  ${name}) ${lib.optionalString (mods != []) "modules+=(${toString mods}) "};;";
    in
      final.writeShellApplication {
        name = "sqlite-extended";
        runtimeInputs = [final.sqlite-interactive];
        text = ''
          profile="''${SQLITE_EXTENDED_PROFILE:-safe}"
          modules=(${toString row.shell.baseModules})
          case "$profile" in
          ${lib.concatLines (lib.mapAttrsToList arm profiles)}  *)
              printf 'sqlite-extended: unknown SQLITE_EXTENDED_PROFILE=%s; expected one of: ${toString (lib.attrNames profiles)}\n' "$profile" >&2
              exit 2
              ;;
          esac

          exec sqlite3 -init <(
            printf '.load ${final.sqlean}/lib/%s${ext}\n' "''${modules[@]}"
            printf '.load %s\n' '${final.sqlite-vec}/lib/vec0${ext}' '${final.libspatialite}/lib/mod_spatialite${ext}'
          ) "$@"
        '';
      };
  }
