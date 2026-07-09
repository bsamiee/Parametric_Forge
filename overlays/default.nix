# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/default.nix
# ----------------------------------------------------------------------------
# Row-folded package projection over overlays/manifest.nix: one binary-release
# template consumes asset rows; patch rows override upstream packages with
# row-owned facts; hand-authored kernels (forge-provision, openstudio,
# energyplus, sqlite-forge) take their row as an argument. Vocabulary
# validation runs here and is forced by the forge-package-manifest build.
final: prev: let
  manifest = import ./manifest.nix;
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
    assert lib.assertMsg ((row.projection.overlay or null) != "override" || row ? overlayReason) "${name}: overlay-override projection requires overlayReason"; row;

  checkAdmission = name: row:
    assert lib.assertMsg (lib.elem row.install voc.installModes) "${name}: install '${row.install}' outside vocabulary";
    assert lib.assertMsg (lib.elem row.roster voc.rosters) "${name}: roster '${row.roster}' outside vocabulary";
    assert lib.assertMsg (lib.elem row.updateEngine voc.updateEngines) "${name}: updateEngine '${row.updateEngine}' outside vocabulary";
    assert lib.assertMsg (lib.elem row.completion voc.completionKinds) "${name}: completion '${row.completion}' outside vocabulary";
    assert lib.assertMsg (lib.elem row.themeCarrier voc.themeCarriers) "${name}: themeCarrier '${row.themeCarrier}' outside vocabulary";
    assert lib.assertMsg (!(row ? completionArgs) || row.completion == "native") "${name}: completionArgs requires completion = \"native\"";
    # Attr absence is nixpkgs drift (rename/removal) or a typo, never a
    # platform fact — nixpkgs attrs exist on every platform; fail loud.
    assert lib.assertMsg (prev ? ${row.attr}) "${name}: attr '${row.attr}' absent from the package set (nixpkgs drift or typo)"; row;

  # Lane admission contract: a row missing a required field fails the ledger
  # build; `extensionSecurityFields`-class vocabularies are executable here.
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

  # Launcher extension rows project live from the fleet manifest owner into
  # the ledger; placeholder args — only family fields cross, never spawn lines.
  fleetLauncherRows = lib.listToAttrs (map (
      r:
        assert lib.assertMsg (lib.elem r.launcher.updateEngine voc.updateEngines) "${r.name}: launcher updateEngine '${r.launcher.updateEngine}' outside vocabulary";
          lib.nameValuePair r.name {inherit (r.launcher) pkg version upstream updateEngine;}
    ) (lib.filter (r: r ? launcher) (import ../modules/home/programs/shell-tools/mcp-fleet.nix {
      profileBin = "";
      homeDir = "";
    })));

  rowOf = name: checkRow name manifest.packages.${name};
  assetOf = name: row:
    row.assets.${system}
    or (throw "${name}: no asset row for ${system} (declared: ${lib.concatStringsSep " " (builtins.attrNames row.assets)})");
  # Hash origin rides the asset row: fetch="zip" hashes the unpacked NAR
  # (fetchzip), default hashes the flat file (fetchurl).
  srcOf = a:
    if (a.fetch or "url") == "zip"
    then
      prev.fetchzip {
        inherit (a) url hash;
        stripRoot = false;
      }
    else prev.fetchurl {inherit (a) url hash;};

  # One derivation template for every binary-release row; recipes carry only
  # the install kernel and unpack facts.
  mkBinaryRelease = name: recipe: let
    row = rowOf name;
    a = assetOf name row;
  in
    prev.stdenvNoCC.mkDerivation ({
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
      // recipe {inherit row a;});

  recipes = {
    duckdb = _: {
      nativeBuildInputs = [prev.unzip];
      sourceRoot = ".";
      installPhase = ''
        runHook preInstall
        install -Dm755 duckdb "$out/bin/duckdb"
        runHook postInstall
      '';
    };
    sqlean = _: {
      installPhase = ''
        runHook preInstall
        mkdir -p "$out/lib" "$out/bin"
        install -Dm644 -t "$out/lib" ./*${prev.stdenv.hostPlatform.extensions.sharedLibrary}
        if [ -f sqlean ]; then
          install -Dm755 sqlean "$out/bin/sqlean"
        elif [ -f sqlite3 ]; then
          install -Dm755 sqlite3 "$out/bin/sqlean-sqlite3"
        fi
        runHook postInstall
      '';
    };
    nodejs-bin_26 = {a, ...}: {
      pname = "nodejs-bin";
      sourceRoot = a.dir;
      # pnpm-only rail: npm/npx/corepack never reach the installed output.
      installPhase = let
        stripRows = ["bin/npm" "bin/npx" "bin/corepack" "lib/node_modules/npm" "lib/node_modules/corepack"];
      in ''
        runHook preInstall
        mkdir -p "$out"
        cp -R . "$out"
        ${lib.concatMapStringsSep "\n" (row: ''rm -rf "$out/${row}"'') stripRows}
        runHook postInstall
      '';
    };
  };

  gcloudRow = rowOf "google-cloud-sdk";
  pnpmRow = rowOf "pnpm_11";
in {
  carbon-now-cli = prev.carbon-now-cli.overrideAttrs (old: {
    # patchFamily source-substitute: Node 26 rejects `assert { type: 'json' }`.
    # No existence guard — an upstream layout or syntax change must fail the
    # build loudly (patch_drift), never ship an unpatched binary.
    postInstall =
      (old.postInstall or "")
      + ''
        substituteInPlace "$out/lib/node_modules/carbon-now-cli/dist/cli.js" \
          --replace-fail "assert { type: 'json' }" "with { type: 'json' }"
      '';
    # Update-notifier policy row: self-mutating configstore state is
    # disabled at admission, never left as unowned config litter.
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [prev.makeBinaryWrapper];
    postFixup =
      (old.postFixup or "")
      + ''
        wrapProgram "$out/bin/carbon-now" --set NO_UPDATE_NOTIFIER 1
      '';
  });
  duckdb = mkBinaryRelease "duckdb" recipes.duckdb;
  # The CLI overlay above has no source tree or pythonHash; python duckdb
  # (harlequin's engine) keeps the nixpkgs source-built duckdb lineage.
  pythonPackagesExtensions =
    (prev.pythonPackagesExtensions or [])
    ++ [
      (_pyFinal: pyPrev: {
        duckdb = pyPrev.duckdb.override {inherit (prev) duckdb;};
      })
    ];
  energyplus = prev.callPackage ./energyplus {row = rowOf "energyplus";};
  forge-package-manifest = prev.writeTextFile {
    name = "forge-package-manifest";
    destination = "/share/forge/manifest.json";
    text = builtins.toJSON {
      inherit (manifest) vocabulary;
      extensions = lib.mapAttrs checkExtensionLane (manifest.extensions
        // {
          mcp-launchers = manifest.extensions.mcp-launchers // {rows = fleetLauncherRows;};
        });
      # Nixpkgs-followed package rows carry no frozen version copy; the ledger
      # resolves the live pin from the package set, mirroring admissions.
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
      # Admission pins resolve live from the package set — never frozen copies.
      # Platform support is a meta.platforms fact (availableOn), not attr
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
  nodejs-bin_26 = mkBinaryRelease "nodejs-bin_26" recipes.nodejs-bin_26;
  openstudio = prev.callPackage ./openstudio {row = rowOf "openstudio";};
  pnpm = final.pnpm_11;
  pnpm_11 = prev.pnpm_11.overrideAttrs (old: {
    inherit (pnpmRow) version;
    src = srcOf pnpmRow.assets.any;
    # patchFamily shebang-retarget: nixpkgs nodejs-slim aborts on a libuv
    # kqueue EINTR assertion at Darwin teardown; Node 26 exits clean.
    postFixup =
      (old.postFixup or "")
      + ''
        for entry in "$out"/libexec/pnpm/bin/pnpm.{cjs,mjs} "$out"/libexec/pnpm/bin/pnpx.{cjs,mjs}; do
          sed -i "1s|^#!.*/node$|#!${final.nodejs-bin_26}/bin/node|" "$entry"
        done
      '';
  });
  sqlite-forge = final.callPackage ./sqlite-forge {};
  sqlean = mkBinaryRelease "sqlean" recipes.sqlean;
}
