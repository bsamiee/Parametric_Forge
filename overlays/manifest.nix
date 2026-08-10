# Title         : manifest.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/manifest.nix
# ----------------------------------------------------------------------------
# Package-admission policy registry: rows own provenance, version policy, generated pin references, license, patch family, cache class, update
# engine, retention, and projection for every non-nixpkgs package and every host-runtime extension family. overlays/default.nix folds
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
  nodePins = pinFamily {
    aarch64-darwin = "nodejs-bin_26-aarch64-darwin";
    aarch64-linux = "nodejs-bin_26-aarch64-linux";
    x86_64-linux = "nodejs-bin_26-x86_64-linux";
  };
  sqleanPins = pinFamily {
    aarch64-darwin = "sqlean-aarch64-darwin";
    aarch64-linux = "sqlean-aarch64-linux";
    x86_64-linux = "sqlean-x86_64-linux";
  };
  v = {
    openstudio = "3.11.0";
    energyplus = "26.1.0";
    gcloud = "575.0.1";
    ruff = "0.16.2";
    rust = "1.97.1";
    osBuild = "241b8abb4d";
    epBuild = "6f2e40d102";
  };
in rec {
  vocabulary = {
    sourceKinds = ["source-build" "binary-archive" "npm-tarball" "github-release" "extension-bundle" "nixpkgs" "repo"];
    patchFamilies = ["none" "darwin-install-name" "auto-patchelf" "auto-patchelf-npm-tool-strip" "shebang-retarget" "npm-tool-strip" "source-substitute"];
    cacheClasses = ["upstream-cached" "forge-cache-hit" "source-built-local" "binary-only-local" "platform-unsupported" "intentionally-uncached"];
    updateEngines = ["nvfetcher" "manual" "nixpkgs-follows" "npm-registry" "pypi" "git-head"];
    versionPolicies = ["fast" "slow-scientific" "nixpkgs" "repo-owned"];
    overlayModes = ["new" "override"]; # projection.overlay values; package/app/default are boolean projection fields
    installModes = ["hm-roster" "ca1" "landed"]; # roster-installed | CA-1 owns installation/projection | owned by a config module
    rosters = ["data" "git" "monitors" "proof" "picker"];
    completionKinds = ["native" "landed" "none"]; # tool/package provides | owner config module wires | no completion surface
    themeCarriers = ["ansi" "env" "none" "tape" "toml"]; # how the admission consumes the estate palette
    rowStates = ["current" "no_upstream_release" "hash_mismatch" "unsupported_platform" "patch_drift" "license_drift" "cache_miss" "consumer_conflict"];
    retentionPolicies = ["git-history" "ledger"]; # superseded pins resurrect from repo history unless a generated ledger holds them
  };

  # Overlay/package rows. `projection.overlay = "override"` requires `overlayReason` — overlay mutation transitively overrides consumer
  # dependencies and re-keys fixed-output hashes; "new" attrs are inert.
  packages = {
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
      retention = "git-history";
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
      retention = "git-history";
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
      retention = "git-history";
      projection.overlay = "new";
      consumers = ["node-tools" "pnpm_11" "mcp-launchers"];
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
      patchFamily = "shebang-retarget"; # nixpkgs nodejs-slim aborts on a libuv kqueue EINTR assertion at Darwin teardown; Node 26 exits clean
      cacheClass = "forge-cache-hit";
      updateEngine = "nvfetcher";
      retention = "git-history";
      projection.overlay = "override";
      overlayReason = "the `pnpm` attr routes every consumer through the 11 line riding nodejs-bin_26";
      consumers = ["node-tools" "mcp-launchers"];
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
      retention = "git-history";
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
      retention = "git-history";
      projection = {
        overlay = "new";
        package = true;
      };
      consumers = ["shell-tools" "grug-far"];
      description = "Structural code search and rewriting CLI";
      homepage = "https://ast-grep.github.io/";
      mainProgram = "ast-grep";
    };

    google-cloud-sdk = {
      upstream = "https://dl.google.com/dl/cloudsdk/channels/rapid";
      version = v.gcloud;
      versionPolicy = "fast";
      sourceKind = "binary-archive";
      assets.aarch64-darwin = {
        url = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${v.gcloud}-darwin-arm.tar.gz";
        hash = "sha256-YWtMiLjw4Gjo21arhjKd5Ip2kqqLsmz7IqYZm2oCclU=";
      };
      license = "free"; # ToS-bound vendor SDK; nixpkgs carries the same license class
      patchFamily = "none";
      cacheClass = "binary-only-local";
      updateEngine = "manual";
      retention = "git-history";
      projection.overlay = "override";
      overlayReason = "nixpkgs lags the rapid channel on aarch64-darwin; other platforms keep the nixpkgs package (consumer policy)";
      consumers = ["dev-tools" "gws"];
      description = "Google Cloud SDK command line tools";
      homepage = "https://cloud.google.com/sdk";
      mainProgram = "gcloud";
    };

    ruff = {
      upstream = "github:astral-sh/ruff";
      version = v.ruff;
      versionPolicy = "fast";
      sourceKind = "github-release";
      # Each release tarball unpacks to a ruff-<triple>/ directory holding the single binary, so the asset hash covers the stripped tree.
      assets = let
        asset = triple: hash: {
          url = "https://github.com/astral-sh/ruff/releases/download/${v.ruff}/ruff-${triple}.tar.gz";
          fetch = "zip";
          stripRoot = true;
          inherit hash;
        };
      in {
        aarch64-darwin = asset "aarch64-apple-darwin" "sha256-77f0LSuIoxz+9CMAy9V1FRNc036iLT1e97T37ZiGCZc=";
        aarch64-linux = asset "aarch64-unknown-linux-musl" "sha256-UFKzCSYepL9vpYN9IsIW3SjJ1xdH0pwKEyR4bOm2yqs=";
        x86_64-linux = asset "x86_64-unknown-linux-musl" "sha256-0USNs/z1hbOePY/H+EyFduSKYoEc2P2Nz0sQ+a8Scwc=";
      };
      license = "mit";
      patchFamily = "none";
      cacheClass = "binary-only-local";
      updateEngine = "manual";
      retention = "git-history";
      projection.overlay = "override";
      overlayReason = "every estate pyproject asserts a ruff required-version floor and refuses to run below it; the pinned nixpkgs ruff sits under that floor, so the attr override raises the treefmt row, the fmt router, the nvim diagnostic lane, and the installed profile as one; pythonPackagesExtensions pins the python ruff distribution back to the nixpkgs source-built lineage the release tree cannot patch";
      consumers = ["python-tools" "fmt" "tooling" "nvim" "pythonPackages.ruff"];
      description = "Ruff Python linter and formatter";
      homepage = "https://docs.astral.sh/ruff/";
      mainProgram = "ruff";
    };

    # A new attr, never an override of `rustc`/`cargo`: those re-key rustPlatform and source-rebuild every rust package in the set. rust-overlay
    # owns the per-platform asset set and its hashes from upstream's channel manifests; the row owns the pinned channel version, which the
    # scientific lane needs above the nixpkgs toolchain — current sdists declare `rust-version` floors that toolchain sits under.
    rust-toolchain = {
      upstream = "https://static.rust-lang.org/dist";
      version = v.rust;
      versionPolicy = "fast";
      sourceKind = "binary-archive";
      license = "asl20"; # dual MIT/Apache-2.0 upstream; the row records the least-permissive member
      patchFamily = "none";
      cacheClass = "binary-only-local";
      updateEngine = "manual";
      retention = "git-history";
      projection.overlay = "new";
      profile = "minimal"; # rustc, cargo, rust-std — the sdist lane compiles and links, it never lints or formats
      consumers = ["scientific-tools"];
      description = "Pinned stable Rust toolchain for the native Python build lane";
      homepage = "https://www.rust-lang.org/";
      mainProgram = "rustc";
    };

    carbon-now-cli = {
      upstream = "nixpkgs:carbon-now-cli";
      versionPolicy = "nixpkgs";
      sourceKind = "nixpkgs";
      license = "mit";
      patchFamily = "source-substitute"; # Node 26 rejects `assert { type: 'json' }` import syntax; patched to `with`
      cacheClass = "source-built-local";
      updateEngine = "nixpkgs-follows";
      retention = "git-history";
      projection.overlay = "override";
      overlayReason = "patch-only override of the nixpkgs package; update-notifier configstore state is disabled at admission (CA-9 residue policy)";
      consumers = ["carbon"];
      description = "Terminal-driven source-code image renderer";
      homepage = "https://github.com/mixn/carbon-now-cli";
      mainProgram = "carbon-now";
    };

    # Uncached-by-design python-module lane: nixpkgs python modules a uv venv cannot take from PyPI (no cp315 wheel, no sdist). The overlay fold
    # builds python315.withPackages over `modules`; the forge-python-overlay kernel (scientific-tools.nix) realizes it on demand behind an
    # XDG-state GC root and projects one .pth into a consumer venv. Never projection.package and never home.packages — the qa build smoke and
    # every switch would otherwise source-build the whole uncached closure.
    forge-python-overlay-env = {
      upstream = "nixpkgs:python315Packages";
      versionPolicy = "nixpkgs";
      sourceKind = "nixpkgs";
      license = "tost"; # openusd; vtk rides bsd3 — the row records the least-permissive member
      patchFamily = "none";
      cacheClass = "intentionally-uncached";
      updateEngine = "nixpkgs-follows";
      retention = "git-history";
      projection.overlay = "new";
      modules = ["vtk" "pyvista" "openusd"]; # python315Packages attrs folded into the env
      probeImports = ["vtk" "pyvista" "pxr"]; # import spellings `forge-python-overlay status <venv>` proves inside a linked venv
      # CPython 3.15 is a beta interpreter, so the whole module set carries two upstream escapes the overlay fold owns once. Upstream suites assert
      # 3.14-era diagnostics and clocks (parso, exceptiongroup, pure-eval, tornado, time-machine, hypothesis, mypy, zlib-ng all fail their own
      # checkPhase here); dropping doCheck also drops nativeCheckInputs, pruning the test-only tail out of the uncached closure. PyO3 <= 0.27 refuses
      # any interpreter past 3.14 outright (pydantic-core, rpds-py) and names the stable-ABI forward-compat escape in its own error text.
      betaSet = {
        pythonVersion = "3.15";
        dropChecks = true;
        env.PYO3_USE_ABI3_FORWARD_COMPATIBILITY = "1";
        # cmake members of the closure reach stdenv.mkDerivation, never the python builders the escapes wrap, so their escapes name them here. Both
        # ride one upstream fact: cmake's FindPython3 version list ends at 3.14, so `find_package(Python3 COMPONENTS Development)` — carrying no
        # Interpreter component to derive a version from — resolves nothing under the beta interpreter. catalyst issues exactly that call in the config
        # it exports, so its own ctest suite loses 22 of 40 sub-builds and every consumer dies at configure, taking adios2, vtk, and the env with it.
        nativeMembers = ["catalyst"];
        # 3.15 removes PyWeakref_GetObject, deprecated since 3.13. The members below still call it — openusd's tf holds four call sites across
        # pyIdentity.cpp, pyFunction.h, and pyWeakObject.cpp — so a compile-time shim restores the borrowed-reference contract over PyWeakref_GetRef.
        capiShimMembers = ["openusd"];
      };
      consumers = ["scientific-tools"];
      description = "python315 module env exposed to uv venvs through forge-python-overlay";
      homepage = "https://nixos.org/";
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
      retention = "git-history";
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
      retention = "git-history";
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
      retention = "git-history";
      projection = {
        overlay = "new";
        package = true;
        app = true;
        default = true;
      };
      kernel = true;
      consumers = ["scripts" "nvim" "Rasm tools/assay"];
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
      retention = "git-history";
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
    television = {
      attr = "television";
      roster = "picker";
      install = "ca1"; # CA-1 owns installation + generated channels; this row is the admission + pin authority
      capability = "durable semantic channels (host polymorphism law); no Ctrl-R/Ctrl-T collisions with fzf/atuin/zoxide";
      updateEngine = "nixpkgs-follows";
      completion = "native";
      themeCarrier = "toml";
      proof = "tv --version";
      chords = [];
    };
    gum = {
      attr = "gum";
      roster = "picker";
      install = "ca1";
      capability = "scalar prompts only (ledger 03); never a browser host";
      updateEngine = "nixpkgs-follows";
      completion = "native";
      themeCarrier = "env";
      proof = "gum --version";
      chords = [];
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
  # carrying the security fields named in the vocabulary. Empty row sets are lanes with a declared source and no vetted admission yet. `requiredFields`
  # is the lane's admission contract: the ledger fold rejects any row missing one, so an under-specified admission fails the build, never lands silent.
  extensions = {
    zellij-wasm = {
      source = "fetchFromGitHub"; # pinned derivations + declarative permission-grant rows (CA-5 consumes)
      requiredFields = ["license" "permissions"];
      rows = {};
    };
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
    yazi-plugins = {
      source = "nixpkgs:yaziPlugins"; # kebab-case <name>.yazi dirs with main.lua entrypoints (CA-5 consumes)
      requiredFields = ["attr" "license"];
      rows = {
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
    mcp-launchers = {
      source = "npm-registry";
      owner = "modules/home/programs/shell-tools/mcp-fleet.nix"; # launcher rows carry upstream + updateEngine family fields
      requiredFields = ["pkg" "version" "upstream" "updateEngine"];
      rows = {};
    };
  };
}
