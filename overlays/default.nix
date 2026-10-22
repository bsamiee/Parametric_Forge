# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/default.nix
# ----------------------------------------------------------------------------
# Row-folded package projection over overlays/manifest.nix: one binary-release template consumes asset rows; opt-runtime rows (energyplus,
# openstudio) share one recipe folding row-owned layout, env, and wrapper facts; the sqlite-extended shell kernel generates from its row's profile data;
# patch rows override upstream packages with row-owned facts.
final: prev: let
  manifest = import ./manifest.nix;
  generatedSources = import ./_sources/generated.nix {
    inherit (prev) fetchurl fetchgit fetchFromGitHub dockerTools;
  };
  inherit (prev) lib;
  system = prev.stdenv.hostPlatform.system;

  # A zip asset (a manual row's choice, or a tarball pin) is an unpacked fixed-output source whose hash is `nix-prefetch-url --unpack`:
  # the single release directory is stripped, and the extracted tree survives every stdenv move. Flat pins keep nvfetcher's fetchurl.
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

  # Prebuilt trees install as a link farm into their unpacked source, so the input-addressed derivation holds links and wrappers alone.
  linkTree = src: dst: ''lndir -silent ${src} ${dst}'';

  # Env vocabulary of an opt-runtime row projected at a root: names bind to the runtime root or to root-relative subpaths.
  runtimeEnvAt = row: root:
    lib.genAttrs row.runtime.env.roots (_: root)
    // lib.mapAttrs (_: sub: "${root}/${sub}") row.runtime.env.paths;

  # One derivation template for every binary-release row; recipes carry only the install kernel and unpack facts,
  # with finalAttrs threaded through for passthru projections.
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

  # Shared opt-runtime recipe: the release tree lands under $out/<root>, each wrapper exports the row env before exec, and passthru.runtimeEnv serves
  # session-env consumers the same vocabulary at the installed root. makeWrapper refuses a target the release layout lacks, so upstream layout
  # drift fails the build instead of shipping a thinner bin/.
  optRuntime = {
    row,
    finalAttrs,
    ...
  }: let
    root = "${placeholder "out"}/${row.runtime.root}";
    installWrapper = name: target: ''
      makeWrapper ${lib.escapeShellArg "${root}/${target}"} "$out/bin/${name}" ${
        lib.concatStringsSep " " (lib.mapAttrsToList (var: value: "--set ${var} ${lib.escapeShellArg value}") (runtimeEnvAt row root))
      }
    '';
  in {
    nativeBuildInputs = [prev.bash prev.lndir prev.makeWrapper];
    # The runtime root is a link farm into the unpacked source; only what patchShebangs rewrites (a named directory, or the top-level
    # scripts of `.`) is a real copy, so a nixpkgs move re-keys links and wrappers instead of a gigabyte tree.
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
    passthru.runtimeEnv = runtimeEnvAt row "${finalAttrs.finalPackage}/${row.runtime.root}";
  };

  recipes = {
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
    # The universal flat package's gzip cpio payload holds `op`; completions generate from the installed binary.
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
    # Flat single-binary release: no archive, the fetched file IS the tool.
    biome = _: {
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        install -Dm755 "$src" "$out/bin/biome"
        runHook postInstall
      '';
    };
    # Release tarball: the binary and its man page. Completions generate from the installed binary (they resolve usage-cli on PATH at
    # completion time, as the generated scripts do everywhere); the nixpkgs self-update marker keeps `mise self-update` a typed refusal
    # on a store-owned binary, so the update path stays the pin.
    mise = _: {
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
    # Release tarball, pinned unpacked: the binary, its man page, and the shipped completions.
    watchexec = _: {
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
    # Library-only release: a flat zip of extension modules with no top directory and no CLI binary.
    sqlean = _: {
      nativeBuildInputs = [prev.unzip];
      sourceRoot = ".";
      installPhase = ''
        runHook preInstall
        install -Dm644 -t "$out/lib" ./*${prev.stdenv.hostPlatform.extensions.sharedLibrary}
        runHook postInstall
      '';
    };
    # Release zip: one executable with the V8 runtime linked in, under a single bin/ directory the unpacked pin strips. A layout move fails the
    # build loudly, never a bin/ that lost its tool.
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

  # Source rows rebuild a nixpkgs recipe at the pinned release, its tests left to upstream and Hydra: the pin replaces `srcs` where the recipe
  # unpacks a list (fonts), else `src`, and `sourceOverride` row data feeds the recipe's own flags.
  sourceRecipes = {
    # 1.28.5 grew a cmark-gfm row inside the Makerules section nixpkgs' Darwin system-deps patch lifts out of its Linux branch; the same lift
    # rebased onto the pinned tree replaces it, and nixpkgs' C++ wrap patch still applies as shipped.
    mupdf = old: {
      patches = [./mupdf-darwin-system-deps.patch (prev.path + "/pkgs/by-name/mu/mupdf/fix-cpp-build.patch")];
      postInstall = lib.replaceStrings [old.version] [manifest.packages.mupdf.version] old.postInstall;
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
  # Every binary-release attr derives from the recipes table: a next platform runtime or wrapped release is one manifest
  # row plus one recipe row, never a new output attr or kernel file.
  lib.mapAttrs mkBinaryRelease recipes
  // lib.mapAttrs mkSourceRelease (lib.filterAttrs (_: row: row ? sourcePackage) manifest.packages)
  // {
    # SQLite shell kernel generated from the manifest row: base modules load on every profile, profile rows add extras, `all` derives as their union.
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

          # exec skips EXIT traps, so the init script rides a process-substitution fd instead of a temp file a trap must reap.
          exec sqlite3 -init <(
            printf '.load ${final.sqlean}/lib/%s${ext}\n' "''${modules[@]}"
            printf '.load %s\n' '${final.sqlite-vec}/lib/vec0${ext}' '${final.libspatialite}/lib/mod_spatialite${ext}'
          ) "$@"
        '';
      };
  }
