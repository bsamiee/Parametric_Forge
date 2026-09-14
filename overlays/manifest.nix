# Title         : manifest.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/manifest.nix
# ----------------------------------------------------------------------------
# Package-admission policy registry: rows own provenance, version policy, generated pin references, license, patch family, cache class, update
# engine, and projection for every non-nixpkgs package and every host-runtime extension family. overlays/default.nix folds
# `packages` rows into derivations; flake-modules/packages.nix folds `projection.package/app` into public outputs; HM rosters consume
# `admissions` rows via `rosterRows`. Pure data plus builtins-only accessors — no pkgs, no lib; validation runs in the overlay fold.
let
  generatedPins = builtins.fromJSON (builtins.readFile ./_sources/generated.json);
  pinAsset = pin: {
    inherit pin;
    inherit (generatedPins.${pin}.src) url;
    hash = generatedPins.${pin}.src.sha256;
  };
  pinFamily = pins: let
    versions = map (pin: generatedPins.${pin}.version) (builtins.attrValues pins);
    version = builtins.head versions;
  in
    assert builtins.all (candidate: candidate == version) versions; {
      inherit version;
      assets = builtins.mapAttrs (_: pinAsset) pins;
    };
  biomePins = pinFamily {
    aarch64-darwin = "biome-aarch64-darwin";
    aarch64-linux = "biome-aarch64-linux";
    x86_64-linux = "biome-x86_64-linux";
  };
  duckdbPins = pinFamily {
    aarch64-darwin = "duckdb-aarch64-darwin";
    aarch64-linux = "duckdb-aarch64-linux";
    x86_64-linux = "duckdb-x86_64-linux";
  };
  nodePins = let
    binaries = pinFamily {
      aarch64-darwin = "nodejs-bin_26-aarch64-darwin";
      aarch64-linux = "nodejs-bin_26-aarch64-linux";
      x86_64-linux = "nodejs-bin_26-x86_64-linux";
    };
  in
    assert binaries.version == generatedPins.design-nodejs_26.version; binaries;
  sqleanPins = pinFamily {
    aarch64-darwin = "sqlean-aarch64-darwin";
    aarch64-linux = "sqlean-aarch64-linux";
    x86_64-linux = "sqlean-x86_64-linux";
  };
  pandocPins = pinFamily {
    aarch64-darwin = "design-pandoc-aarch64-darwin";
    aarch64-linux = "design-pandoc-aarch64-linux";
    x86_64-linux = "design-pandoc-x86_64-linux";
  };
  temurinPins = pinFamily {
    aarch64-darwin = "design-temurin-aarch64-darwin";
    aarch64-linux = "design-temurin-aarch64-linux";
    x86_64-linux = "design-temurin-x86_64-linux";
  };
  veraPdfPins = pinFamily {
    aarch64-darwin = "design-verapdf-cli";
    aarch64-linux = "design-verapdf-cli";
    x86_64-linux = "design-verapdf-cli";
  };
  # `versionFrom`: a regex whose first group is the version when the publisher's release tag is path-shaped; null when the tag is already bare.
  designSource = name: versionFrom: license: homepage: description: consumers: overlayReason: let
    pin = "design-${name}";
    release = generatedPins.${pin}.version;
  in
    {
      upstream = homepage;
      inherit license homepage description consumers;
      sourcePackage = name;
      sourcePin = pin;
      version = let
        matched =
          builtins.match (
            if versionFrom == null
            then "(.*)"
            else versionFrom
          )
          release;
      in
        if matched == null
        then null
        else builtins.head matched;
      versionPolicy = "fast";
      sourceKind = "source-build";
      patchFamily = "source-substitute";
      cacheClass = "source-built-local";
      updateEngine = "nvfetcher";
      projection.overlay =
        if overlayReason == null
        then "new"
        else "override";
    }
    // (
      if overlayReason == null
      then {}
      else {inherit overlayReason;}
    );
  v = {
    openstudio = "3.11.0";
    energyplus = "26.1.0";
    osBuild = "241b8abb4d";
    epBuild = "6f2e40d102";
  };
in rec {
  vocabulary = {
    sourceKinds = ["source-build" "binary-archive" "npm-tarball" "github-release" "nixpkgs" "repo"];
    patchFamilies = ["none" "darwin-install-name" "auto-patchelf" "auto-patchelf-npm-tool-strip" "shebang-retarget" "source-substitute"];
    cacheClasses = ["forge-cache-hit" "source-built-local" "binary-only-local"];
    updateEngines = ["nvfetcher" "manual" "nixpkgs-follows"];
    versionPolicies = ["fast" "slow-scientific" "nixpkgs" "repo-owned"];
    overlayModes = ["new" "override"]; # projection.overlay values; package/app/default are boolean projection fields
    installModes = ["hm-roster" "ca1" "landed"]; # roster-installed | CA-1 owns installation/projection | owned by a config module
    rosters = ["data" "git" "monitors" "proof" "picker"];
    completionKinds = ["native" "landed" "none"]; # tool/package provides | owner config module wires | no completion surface
    themeCarriers = ["ansi" "env" "none" "tape" "toml"]; # how the admission consumes the estate palette
    rowStates = ["current" "unsupported_platform"]; # ledger `resolved.state` values; a build-time drift is a failed build, never a ledger row
  };

  # Overlay/package rows. `projection.overlay = "override"` requires `overlayReason` — overlay mutation transitively overrides consumer
  # dependencies and re-keys fixed-output hashes; "new" attrs are inert.
  packages = {
    nodejs-slim_26 = (designSource "nodejs_26" null "mit" "https://nodejs.org/" "Current Node 26 build runtime for native npm packages" ["media-tools:vega-cli"] "Vega's native Canvas build requires the current Node source headers and nixpkgs npm hooks; the public Node executable remains the existing binary owner") // {sourcePackage = "nodejs-slim_26";};
    vega-cli = {
      upstream = "nixpkgs:vega-cli";
      versionPolicy = "nixpkgs";
      sourceKind = "nixpkgs";
      license = "bsd3";
      patchFamily = "none";
      cacheClass = "source-built-local";
      updateEngine = "nixpkgs-follows";
      projection.overlay = "override";
      overlayReason = "Vega's Canvas addon and its CLI are built and run through the selected Node 26 runtime";
      consumers = ["media-tools"];
      description = "Vega chart export to editable SVG, PDF, and PNG";
      homepage = "https://vega.github.io/vega/";
      mainProgram = "vg2svg";
    };
    imagemagick = designSource "imagemagick" null "asl20" "https://imagemagick.org/" "ICC-aware raster processing with Q16-HDRI" ["media-tools" "media-environment"] "the palette and image workflows require the current ICC converter with its complete existing delegate closure";
    fontconfig = designSource "fontconfig" null "bsd2" "https://fontconfig.org/" "Shared font discovery for native renderers" ["scientific-tools" "media-environment"] "Fontconfig, ImageMagick, Pango and PDF renderers must consume the same current font-discovery engine and configuration";
    geist-font = designSource "geist-font" null "ofl" "https://github.com/vercel/geist-font" "Current Geist and Geist Mono desktop font programs" ["fonts-catalog" "font-manifest"] "the native font projection and every typography consumer must use the current official release with corrected Mono ligature behavior";
    harfbuzz = designSource "harfbuzz" null "mit" "https://harfbuzz.github.io/" "OpenType shaping and font subsetting" ["scientific-tools" "media-tools" "font-manifest"] "the current shaping library is shared by the renderers, Poppler subsetting, and the complete command-line tool variant";
    poppler-utils-current =
      (designSource "poppler" null "gpl2Plus" "https://poppler.freedesktop.org/" "Current PDF inspection, extraction and rasterization utilities" ["media-tools"] null)
      // {
        sourcePackage = "poppler-utils";
        testDataPin = "design-poppler-test-data";
      };
    mupdf = designSource "mupdf" null "agpl3Plus" "https://mupdf.com/" "PDF document inspection and rendering engine" ["scientific-tools"] "the command-line and scientific PDF consumers share the current document engine";
    qpdf = designSource "qpdf" null "asl20" "https://qpdf.sourceforge.io/" "Lossless structural PDF transformations" ["scientific-tools"] "all publication PDF transformations use the current parser and writer";
    ghostscript = designSource "ghostscript" "gs[0-9]+/ghostscript-(.*)\\.tar\\.xz" "agpl3Plus" "https://ghostscript.com/" "PostScript and PDF interpreter" ["scientific-tools"] "the selected PostScript and PDF conversion workflows require the current interpreter";

    utiluti = {
      upstream = "github:scriptingosx/utiluti";
      version = generatedPins.design-utiluti.version;
      assets.aarch64-darwin = pinAsset "design-utiluti";
      versionPolicy = "fast";
      sourceKind = "binary-archive";
      license = "asl20";
      patchFamily = "none";
      cacheClass = "binary-only-local";
      updateEngine = "nvfetcher";
      projection.overlay = "new";
      consumers = ["mac-tools"];
      description = "Native macOS file and URL application associations";
      homepage = "https://github.com/scriptingosx/utiluti";
      mainProgram = "utiluti";
    };

    pandoc-current = {
      upstream = "github:jgm/pandoc";
      inherit (pandocPins) version assets;
      versionPolicy = "fast";
      sourceKind = "binary-archive";
      license = "gpl2Plus";
      patchFamily = "auto-patchelf";
      cacheClass = "binary-only-local";
      updateEngine = "nvfetcher";
      projection.overlay = "new";
      consumers = ["media-tools"];
      description = "Universal document converter";
      homepage = "https://pandoc.org/";
      mainProgram = "pandoc";
    };

    verapdf-current = {
      upstream = "https://artifactory.openpreservation.org/artifactory/vera-dev/org/verapdf/apps/cli/";
      inherit (veraPdfPins) version assets;
      versionPolicy = "fast";
      sourceKind = "binary-archive";
      license = "mpl20"; # The unmodified upstream JAR retains the alternative GPLv3+ license and third-party notices.
      patchFamily = "none";
      cacheClass = "binary-only-local";
      updateEngine = "nvfetcher";
      projection.overlay = "new";
      consumers = ["media-tools"];
      description = "Current veraPDF conformance inspection with a private Java runtime";
      homepage = "https://verapdf.org/";
      mainProgram = "verapdf";
    };

    temurin-jre-current = {
      upstream = "github:adoptium/temurin26-binaries";
      version = builtins.substring 4 (builtins.stringLength temurinPins.version) temurinPins.version;
      inherit (temurinPins) assets;
      versionPolicy = "fast";
      sourceKind = "binary-archive";
      license = "gpl2Only"; # OpenJDK also grants the Classpath exception; its original legal files ship with the runtime.
      patchFamily = "auto-patchelf";
      cacheClass = "binary-only-local";
      updateEngine = "nvfetcher";
      projection.overlay = "new";
      consumers = ["media-tools:verapdf-current"];
      description = "Private current Temurin Java runtime for veraPDF";
      homepage = "https://adoptium.net/";
      mainProgram = "java";
    };

    biome = {
      upstream = "github:biomejs/biome";
      inherit (biomePins) version assets;
      versionPolicy = "fast";
      sourceKind = "github-release";
      # Linux rows pin the musl static builds: they run on NixOS with no interpreter or patchelf dependency; glibc assets would need auto-patchelf.
      license = "mit";
      patchFamily = "none";
      cacheClass = "binary-only-local";
      updateEngine = "nvfetcher";
      projection.overlay = "override";
      overlayReason = "nixpkgs source-builds biome behind the upstream release line; the attr override routes every consumer (node-tools wrapper, fmt router) through the official release binary";
      consumers = ["node-tools" "fmt"];
      description = "Biome formatter, linter, and LSP for the web toolchain";
      homepage = "https://biomejs.dev/";
      mainProgram = "biome";
    };

    duckdb = {
      upstream = "github:duckdb/duckdb";
      inherit (duckdbPins) version assets;
      versionPolicy = "fast";
      sourceKind = "github-release";
      license = "mit";
      patchFamily = "none";
      cacheClass = "binary-only-local";
      updateEngine = "nvfetcher";
      projection = {
        overlay = "override";
        package = true;
        app = true;
      };
      overlayReason = "the top-level attr becomes the upstream binary CLI for every consumer; pythonPackagesExtensions pins python duckdb (Harlequin engine) back to the nixpkgs source-built lineage the header-less binary cannot satisfy";
      consumers = ["db-tools" "forge-provision" "pythonPackages.duckdb"];
      description = "DuckDB command line client";
      homepage = "https://duckdb.org/";
      mainProgram = "duckdb";
    };

    nodejs-bin_26 = {
      upstream = "https://nodejs.org/dist";
      inherit (nodePins) version;
      versionPolicy = "fast";
      sourceKind = "binary-archive";
      assets = {
        aarch64-darwin =
          nodePins.assets.aarch64-darwin
          // {
            dir = "node-v${nodePins.version}-darwin-arm64";
          };
        aarch64-linux =
          nodePins.assets.aarch64-linux
          // {
            dir = "node-v${nodePins.version}-linux-arm64";
          };
        x86_64-linux =
          nodePins.assets.x86_64-linux
          // {
            dir = "node-v${nodePins.version}-linux-x64";
          };
      };
      license = "mit";
      patchFamily = "auto-patchelf-npm-tool-strip"; # Linux ELF admission plus pnpm-only npm/npx removal; corepack left the Node 26 distribution
      cacheClass = "binary-only-local";
      updateEngine = "nvfetcher";
      projection.overlay = "new";
      consumers = ["node-tools" "pnpm_11"];
      description = "Node.js official binary distribution";
      homepage = "https://nodejs.org/";
      mainProgram = "node";
    };

    pnpm_11 = {
      upstream = "npm:pnpm";
      version = generatedPins.pnpm_11.version;
      versionPolicy = "fast";
      sourceKind = "npm-tarball";
      assets.any = pinAsset "pnpm_11";
      license = "mit";
      # The builder seats its `nodejs-slim` argument into the entry shebangs; the override seats nodejs-bin_26 there because nixpkgs nodejs-slim
      # aborts on a libuv kqueue EINTR assertion at Darwin teardown and Node 26 exits clean.
      patchFamily = "shebang-retarget";
      cacheClass = "forge-cache-hit";
      updateEngine = "nvfetcher";
      projection.overlay = "override";
      overlayReason = "nixpkgs aliases `pnpm` to this attr, so the override routes every consumer through the pinned 11 line riding nodejs-bin_26";
      consumers = ["node-tools"];
      description = "Fast, disk-space-efficient Node package manager";
      homepage = "https://pnpm.io/";
      mainProgram = "pnpm";
    };

    sqlean = {
      upstream = "github:nalgeon/sqlean";
      inherit (sqleanPins) version assets;
      versionPolicy = "fast";
      sourceKind = "github-release";
      license = "mit";
      patchFamily = "none";
      cacheClass = "binary-only-local";
      updateEngine = "nvfetcher";
      projection = {
        overlay = "new";
        package = true; # package-only: extension library set consumed by sqlite-forge
      };
      consumers = ["sqlite-forge" "db-tools"];
      description = "Bundled SQLite extension libraries from SQLean";
      homepage = "https://github.com/nalgeon/sqlean";
    };

    ast-grep-upstream = {
      upstream = "github:ast-grep/ast-grep";
      version = generatedPins.ast-grep-upstream.version;
      sourcePin = "ast-grep-upstream";
      versionPolicy = "fast";
      sourceKind = "source-build";
      license = "mit";
      patchFamily = "none";
      cacheClass = "source-built-local";
      updateEngine = "nvfetcher";
      projection = {
        overlay = "new";
        package = true;
      };
      consumers = ["shell-tools" "grug-far"];
      description = "Structural code search and rewriting CLI";
      homepage = "https://ast-grep.github.io/";
      mainProgram = "ast-grep";
    };

    carbon-now-cli = {
      upstream = "nixpkgs:carbon-now-cli";
      versionPolicy = "nixpkgs";
      sourceKind = "nixpkgs";
      license = "mit";
      patchFamily = "source-substitute"; # Node 26 rejects `assert { type: 'json' }` import syntax; patched to `with`
      cacheClass = "source-built-local";
      updateEngine = "nixpkgs-follows";
      projection.overlay = "override";
      overlayReason = "patch-only override of the nixpkgs package; update-notifier configstore state is disabled at admission (CA-9 residue policy)";
      consumers = ["carbon"];
      description = "Terminal-driven source-code image renderer";
      homepage = "https://github.com/mixn/carbon-now-cli";
      mainProgram = "carbon-now";
    };

    openstudio = {
      upstream = "github:NatLabRockies/OpenStudio";
      version = v.openstudio;
      build = v.osBuild;
      versionPolicy = "slow-scientific";
      sourceKind = "github-release";
      assets.aarch64-darwin = {
        url = "https://github.com/NatLabRockies/OpenStudio/releases/download/v${v.openstudio}/OpenStudio-${v.openstudio}%2B${v.osBuild}-Darwin-arm64.tar.gz";
        hash = "sha256-t/hZA44pYjcf8eEv/lCSNfAafVT2MfBLRY37XXvjZGQ=";
      };
      license = "bsd3";
      patchFamily = "none";
      cacheClass = "binary-only-local";
      updateEngine = "manual";
      projection.overlay = "new";
      # Opt-runtime spec: the shared overlay recipe folds these layout, env, and wrapper facts into the derivation; a next platform
      # runtime is one row, never a new kernel file.
      runtime = {
        root = "opt/openstudio";
        shebangDirs = ["bin"];
        env = {
          roots = ["OPENSTUDIO_ROOT" "OPENSTUDIO_DIR"];
          paths = {
            OPENSTUDIO_EXE = "bin/openstudio";
            OPENSTUDIO_RUBY_ROOT = "Ruby";
            OPENSTUDIO_PYTHON_ROOT = "Python";
            OPENSTUDIO_RADIANCE_ROOT = "Radiance";
            OPENSTUDIO_ENERGYPLUSDIR = "EnergyPlus";
          };
          version = ["OPENSTUDIO_VERSION"];
        };
        wrappers = {
          openstudio = "bin/openstudio";
          openstudio-install-utility = "bin/install_utility";
        };
      };
      consumers = ["scientific-tools"];
      description = "OpenStudio SDK and CLI for whole-building energy modeling";
      homepage = "https://openstudio.net";
      mainProgram = "openstudio";
    };

    energyplus = {
      upstream = "github:NatLabRockies/EnergyPlus";
      version = v.energyplus;
      build = v.epBuild;
      versionPolicy = "slow-scientific";
      sourceKind = "github-release";
      assets.aarch64-darwin = {
        url = "https://github.com/NatLabRockies/EnergyPlus/releases/download/v${v.energyplus}/EnergyPlus-${v.energyplus}-${v.epBuild}-Darwin-macOS13-arm64.tar.gz";
        hash = "sha256-fy7EJeZ/XXHGaORQTbGxDZHcTYy4Aumo7nDE8CpG03k=";
      };
      license = "bsd3";
      patchFamily = "none";
      cacheClass = "binary-only-local";
      updateEngine = "manual";
      projection.overlay = "new";
      runtime = {
        root = "opt/energyplus";
        shebangDirs = ["."];
        env = {
          roots = ["ENERGYPLUSDIR" "ENERGYPLUS_DIR"];
          paths = {ENERGYPLUS_EXE = "energyplus";};
          version = ["ENERGYPLUS_VERSION"];
        };
        wrappers = {
          energyplus = "energyplus";
          "energyplus-${v.energyplus}" = "energyplus";
          runenergyplus = "runenergyplus";
          runepmacro = "runepmacro";
          runreadvars = "runreadvars";
          EPMacro = "EPMacro";
          ExpandObjects = "ExpandObjects";
          ConvertInputFormat = "ConvertInputFormat";
          "ConvertInputFormat-${v.energyplus}" = "ConvertInputFormat";
        };
      };
      consumers = ["scientific-tools"];
      description = "Whole building energy simulation runtime";
      homepage = "https://energyplus.net";
      mainProgram = "energyplus";
    };

    forge-provision = {
      upstream = "repo:overlays/forge-provision";
      versionPolicy = "repo-owned";
      sourceKind = "repo";
      sourceInputs = ["overlays/forge-provision"]; # fileset whose change re-keys the derivation
      license = "mit";
      patchFamily = "none";
      cacheClass = "source-built-local";
      updateEngine = "manual";
      projection = {
        overlay = "new";
        package = true;
        app = true;
        default = true;
      };
      kernel = true;
      consumers = ["scripts" "nvim"];
      description = "Local PostgreSQL provisioning rail for the estate";
      homepage = "https://github.com/bardiasamiee/Parametric_Forge";
      mainProgram = "forge-provision";
    };

    sqlite-forge = {
      upstream = "repo:overlays";
      versionPolicy = "repo-owned";
      sourceKind = "repo";
      license = "mit";
      patchFamily = "none";
      cacheClass = "source-built-local";
      updateEngine = "manual";
      projection = {
        overlay = "new";
        package = true;
        app = true;
      };
      # Shell-kernel data: base modules load on every profile, a profile row adds extras, and `all` derives in the fold as the union of every row.
      shell = {
        baseModules = ["regexp" "uuid" "stats" "text" "time" "crypto" "math"];
        profiles = {
          safe = [];
          extended = ["define" "vsv" "fuzzy" "ipaddr"];
          fileio = ["fileio"];
        };
      };
      consumers = ["db-tools" "forge-provision"];
      description = "SQLite shell kernel preloading the SQLean module profiles";
      homepage = "https://github.com/bardiasamiee/Parametric_Forge";
      mainProgram = "sqlite-forge";
    };
  };

  # CLI tool admissions (ADMISSION_IS_A_ROW): nixpkgs-sourced tools whose pin follows the flake input — rows carry no frozen version copy; the JSON
  # projection resolves the live version from the package set at build time. `chords` are candidate DATA for the CA-1 register; projection is CA-1's.
  # `install`: hm-roster (a roster group below consumes it) | ca1 (CA-1 owns installation and projection) | landed (already owned by a config module).
  admissions = {
    xan = {
      attr = "xan";
      roster = "data";
      install = "hm-roster";
      capability = "CSV lane: SIMD parser, expression language, frequency/plot tooling; routing: CSV -> xan, relational/Parquet -> DuckDB";
      updateEngine = "nixpkgs-follows";
      completion = "native";
      completionArgs = ["completions" "zsh"]; # package ships no file; the shell-tools roster materializes `_xan` from this argv
      themeCarrier = "ansi";
      proof = "xan --version";
      chords = ["inspect" "sample" "aggregate" "join"];
    };
    mergiraf = {
      attr = "mergiraf";
      roster = "git";
      install = "hm-roster";
      capability = "structural merge driver; registered in git config, inert until a repo opts in via gitattributes `merge=mergiraf`";
      updateEngine = "nixpkgs-follows";
      completion = "none";
      themeCarrier = "none";
      proof = "mergiraf --version";
      chords = ["semantic-merge" "conflict-resolve"];
    };
    git-cliff = {
      attr = "git-cliff";
      roster = "git";
      install = "hm-roster";
      capability = "template-driven changelog from conventional commits; config under the repo owner";
      updateEngine = "nixpkgs-follows";
      completion = "native";
      themeCarrier = "none";
      proof = "git-cliff --version";
      chords = ["changelog"];
    };
    viddy = {
      attr = "viddy";
      roster = "monitors";
      install = "hm-roster";
      capability = "watch-with-memory: history, diff highlight, pager, search; CA-5 floating-pane monitor rows consume it — never prompt/status hot paths";
      updateEngine = "nixpkgs-follows";
      completion = "none";
      themeCarrier = "ansi";
      proof = "viddy --version";
      chords = ["monitor"];
    };
    presenterm = {
      attr = "presenterm";
      roster = "proof";
      install = "hm-roster";
      capability = "Markdown terminal slides; rides the CA-12 terminal-native proof lane; theme projection + media closure policy land there";
      updateEngine = "nixpkgs-follows";
      completion = "none";
      themeCarrier = "toml";
      proof = "presenterm --version";
      chords = ["present"];
    };
    vhs = {
      attr = "vhs";
      roster = "proof";
      install = "hm-roster";
      capability = "terminal demos as .tape source -> GIF/video/frames; prompt/theme/font/pane geometry are frozen build inputs (CA-12 proof lane)";
      updateEngine = "nixpkgs-follows";
      completion = "native";
      themeCarrier = "tape";
      proof = "vhs --version";
      chords = ["record" "render"];
    };
    fzf = {
      attr = "fzf";
      roster = "picker";
      install = "landed"; # shell-tools/fzf.nix owns installation and theme
      capability = "disposable one-shot browse/act; watch-class browsers stay on fzf via timer-driven reload binds";
      capabilityFloor = "0.73"; # `every(N)` reload binds; --listen sockets stay unvalidated (CA-1 socket security row)
      updateEngine = "nixpkgs-follows";
      completion = "landed";
      themeCarrier = "env";
      proof = "fzf --version";
      chords = [];
    };
  };

  # One roster fold serves every HM consumer: rows for one roster group whose installation this manifest owns; consumers map their package set over it.
  rosterRows = roster:
    builtins.filter (row: row.install == "hm-roster" && row.roster == roster)
    (builtins.attrValues admissions);

  # Host-runtime extension registries: package-like assets consumed by a host. One family, per-lane sources; CA-4/5/6/7 admit plugin rows here, each
  # carrying the security fields named in the vocabulary. `requiredFields` is the lane's admission contract: the ledger fold rejects any row missing
  # one, so an under-specified admission fails the build, never lands silent.
  extensions = {
    wezterm-plugins = {
      source = "fetchFromGitHub"; # file:// store-path loads only (CA-4 consumes)
      requiredFields = ["license" "permissions"];
      rows = {
        sync-panes = {
          owner = "annie444";
          repo = "sync-panes.wez";
          rev = "1fe41d994df9dcb86fd6c469d39754d7917befe3";
          hash = "sha256-AP20DyGQlOHMi8mw3pgZWg3KLEbyjj5PQWL61p41Pfk=";
          license = "mit";
          permissions = ["broadcast-input-active-tab" "clipboard-paste" "window-frame-overrides"];
          surface = "runtime"; # direct store-path dofile (fetched trees are not git repos; plugin.require cannot clone them); toggle chord guarded by the deck
          apply = "apply_to_config";
        };
        wezterm-types = {
          owner = "DrKJeff16";
          repo = "wezterm-types";
          rev = "cc55e88946cb326ea930631b4b03754410eb0436"; # v4.3.0-1
          hash = "sha256-H3EL4/UWFipnVJPSS/NsX+AOm3KKn8kQhQ0PfP6wj2k=";
          license = "mit";
          permissions = ["none"]; # LuaCATS annotations only; never loaded at runtime
          surface = "luals"; # .luarc.json workspace library for the wezterm config tree
          apply = "none";
        };
      };
    };
    zellij-plugins = {
      source = "fetchurl"; # one release wasm per row, hash-pinned into ~/.config/zellij/plugins; `permissions` seeds the grant cache (CA-7 consumes)
      requiredFields = ["url" "hash" "license" "permissions"];
      rows = {
        zjstatus = {
          url = "https://github.com/dj95/zjstatus/releases/download/v0.23.0/zjstatus.wasm";
          hash = "sha256-4AaQEiNSQjnbYYAh5MxdF/gtxL+uVDKJW6QfA/E4Yf8=";
          license = "MIT";
          permissions = ["ReadApplicationState" "ChangeApplicationState" "RunCommands"];
        };
        zellij_forgot = {
          url = "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm";
          hash = "sha256-MRlBRVGdvcEoaFtFb5cDdDePoZ/J2nQvvkoyG6zkSds=";
          license = "MIT";
          permissions = ["ReadApplicationState" "ChangeApplicationState"];
        };
      };
    };
    yazi-plugins = {
      # kebab-case <name>.yazi dirs with main.lua entrypoints (CA-5 consumes): a row with `attr` resolves in nixpkgs yaziPlugins, a row with
      # owner/repo/rev/hash pins an upstream tree nixpkgs omits.
      source = "nixpkgs:yaziPlugins | fetchFromGitHub";
      requiredFields = ["license"];
      rows = {
        augment-command = {
          owner = "hankertrix";
          repo = "augment-command.yazi";
          rev = "dd2d6cf07f81cef543e37883352e30b91634ec86";
          hash = "sha256-sB2t3Gg+WdPG6OE8pD6VovD+x9nN21Jn8XydZZdTqCg=";
          license = "AGPL-3.0"; # semantic command layer: open/quit/tab/paste/archive/scroll behaviors
        };
        full-border = {
          attr = "full-border";
          license = "MIT";
        };
        toggle-pane = {
          attr = "toggle-pane";
          license = "MIT";
        };
        jump-to-char = {
          attr = "jump-to-char";
          license = "MIT";
        };
        mount = {
          attr = "mount";
          license = "MIT";
        };
        piper = {
          attr = "piper";
          license = "MIT";
        };
        git = {
          attr = "git";
          license = "MIT";
        };
        smart-filter = {
          attr = "smart-filter";
          license = "MIT";
        };
        mime-ext = {
          attr = "mime-ext";
          license = "MIT";
        };
        duckdb = {
          attr = "duckdb";
          license = "MIT";
        };
        zoom = {
          attr = "zoom";
          license = "MIT";
        };
      };
    };
    nvim-plugins = {
      source = "nixpkgs:vimPlugins"; # HM programs.neovim pack deployment; store-owned, runtime fetch unspellable (CA-6 consumes)
      requiredFields = ["attr" "license"];
      rows = {
        dracula-vim = {
          attr = "dracula-vim";
          license = "MIT";
        };
        snacks-nvim = {
          attr = "snacks-nvim";
          license = "Apache-2.0";
        };
        nvim-treesitter = {
          attr = "nvim-treesitter";
          license = "Apache-2.0"; # main branch; one compat unit with the neovim pin, tree-sitter-cli floor, parsers, queries
        };
        nvim-treesitter-textobjects = {
          attr = "nvim-treesitter-textobjects";
          license = "Apache-2.0"; # select/move/swap over the treesitter captures
        };
        gitsigns-nvim = {
          attr = "gitsigns-nvim";
          license = "MIT"; # gutter git state reading the theme's git glyph rows
        };
        lualine-nvim = {
          attr = "lualine-nvim";
          license = "MIT"; # statusline
        };
        # hmts-nvim stays unadmitted: 1.3.0 crashes on Neovim 0.12 + nvim-treesitter main (LanguageTree parent API drift) against real Forge
        # files; re-admits only on an upstream compatibility release.
        conform-nvim = {
          attr = "conform-nvim";
          license = "MIT"; # formatter orchestration over Forge-owned binaries
        };
        nvim-lint = {
          attr = "nvim-lint";
          license = "GPL-3.0-only"; # non-LSP diagnostic lane (deadnix/statix/shellcheck/ruff/yamllint/actionlint/zizmor/hadolint/typos)
        };
        grug-far-nvim = {
          attr = "grug-far-nvim";
          license = "MIT"; # rg + ast-grep search/replace workbench
        };
        render-markdown-nvim = {
          attr = "render-markdown-nvim";
          license = "MIT"; # in-buffer agent-doc rendering
        };
        overseer-nvim = {
          attr = "overseer-nvim";
          license = "MIT"; # task graph over mise/just/npm
        };
        trouble-nvim = {
          attr = "trouble-nvim";
          license = "Apache-2.0"; # the one diagnostics/references surface
        };
      };
    };
  };
}
