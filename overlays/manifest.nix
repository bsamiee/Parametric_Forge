# Title         : manifest.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/manifest.nix
# ----------------------------------------------------------------------------
# Package-admission row registry: one row owns provenance, version policy,
# per-platform assets and hashes, license, patch family, cache class, update
# engine, retention, and projection for every non-nixpkgs package and every
# host-runtime extension family. overlays/default.nix folds `packages` rows
# into derivations; flake-modules/packages.nix folds `projection.package/app`
# into public outputs; HM rosters consume `admissions` rows via `rosterRows`.
# Pure data plus builtins-only accessors — no pkgs, no lib; validation runs in
# the overlay fold.
let
  v = rec {
    duckdb = "1.5.4";
    nodejs = "26.5.0";
    pnpm = "11.10.0";
    sqlean = "0.28.3";
    openstudio = "3.11.0";
    energyplus = "26.1.0";
    gcloud = "575.0.1";
    osBuild = "241b8abb4d";
    epBuild = "6f2e40d102";
    duckdbBase = "https://github.com/duckdb/duckdb/releases/download/v${duckdb}";
    sqleanBase = "https://github.com/nalgeon/sqlean/releases/download/${sqlean}";
  };
in rec {
  vocabulary = {
    sourceKinds = ["source-build" "binary-archive" "npm-tarball" "github-release" "extension-bundle" "nixpkgs" "repo"];
    patchFamilies = ["none" "darwin-install-name" "auto-patchelf" "shebang-retarget" "npm-tool-strip" "source-substitute"];
    cacheClasses = ["upstream-cached" "forge-cache-hit" "source-built-local" "binary-only-local" "platform-unsupported" "intentionally-uncached"];
    updateEngines = ["nix-update" "nvfetcher" "npins" "manual" "nixpkgs-follows" "npm-registry"];
    engineVerbs = ["update" "advance" "build"]; # bump revisions | move upstream ref only | prove the locked set builds
    versionPolicies = ["fast" "slow-scientific" "nixpkgs" "repo-owned"];
    overlayModes = ["new" "override"]; # projection.overlay values; package/app/default are boolean projection fields
    installModes = ["hm-roster" "ca1" "landed"]; # roster-installed | CA-1 owns installation/projection | owned by a config module
    rosters = ["data" "git" "monitors" "proof" "picker"];
    completionKinds = ["native" "landed" "none"]; # tool/package provides | owner config module wires | no completion surface
    themeCarriers = ["ansi" "env" "none" "tape" "toml"]; # how the admission consumes the estate palette
    rowStates = ["current" "no_upstream_release" "hash_mismatch" "unsupported_platform" "patch_drift" "license_drift" "cache_miss" "consumer_conflict"];
    retentionPolicies = ["git-history" "ledger"]; # superseded pins resurrect from repo history unless a generated ledger holds them
    extensionSecurityFields = ["publisher" "registry" "native_code" "postinstall_behavior" "secret_touching" "host_permissions" "runtime_write_policy" "mutable_paths"];
  };

  # Overlay/package rows. `projection.overlay = "override"` requires
  # `overlayReason` — overlay mutation transitively overrides consumer
  # dependencies and re-keys fixed-output hashes; "new" attrs are inert.
  packages = {
    duckdb = {
      upstream = "github:duckdb/duckdb";
      version = v.duckdb;
      versionPolicy = "fast";
      sourceKind = "github-release";
      assets = {
        aarch64-darwin = {
          url = "${v.duckdbBase}/duckdb_cli-osx-universal.zip";
          hash = "sha256-xdjLYNfVzra7lPzlrkoXzIFtsZwhtrteDSNIs7IkA1k=";
        };
        aarch64-linux = {
          url = "${v.duckdbBase}/duckdb_cli-linux-arm64.zip";
          hash = "sha256-N38D+58Xq1p48o+CnL/LUzPairPC0HiPJ2lPgd937Sk=";
        };
        x86_64-linux = {
          url = "${v.duckdbBase}/duckdb_cli-linux-amd64.zip";
          hash = "sha256-Hy+nJPsFSz2+Gpy9E95bdpl9hQ5wh+x2K6iNsE4BgM8=";
        };
      };
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
      version = v.nodejs;
      versionPolicy = "fast";
      sourceKind = "binary-archive";
      assets = {
        aarch64-darwin = {
          url = "https://nodejs.org/dist/v${v.nodejs}/node-v${v.nodejs}-darwin-arm64.tar.xz";
          hash = "sha256-SCMdYgTspr4T5sUYTf3/odZK2IiANkzCz7GY+HLLKxM=";
          dir = "node-v${v.nodejs}-darwin-arm64";
        };
        x86_64-linux = {
          url = "https://nodejs.org/dist/v${v.nodejs}/node-v${v.nodejs}-linux-x64.tar.xz";
          hash = "sha256-n2GVKPHbXdxB3M9UIRBm+0IijWmhVnM8acudbMkuNYw=";
          dir = "node-v${v.nodejs}-linux-x64";
        };
        aarch64-linux = {
          url = "https://nodejs.org/dist/v${v.nodejs}/node-v${v.nodejs}-linux-arm64.tar.xz";
          hash = "sha256-A23wtJZi67NQ61bxysYDaZsentHiYD7hKf79pHNHkDA=";
          dir = "node-v${v.nodejs}-linux-arm64";
        };
      };
      license = "mit";
      patchFamily = "npm-tool-strip"; # pnpm-only rail: npm/npx/corepack never reach the installed output
      cacheClass = "binary-only-local";
      updateEngine = "nvfetcher";
      retention = "git-history";
      projection.overlay = "new";
      consumers = ["node-tools" "pnpm_11"];
      description = "Node.js official binary distribution";
      homepage = "https://nodejs.org/";
      mainProgram = "node";
    };

    pnpm_11 = {
      upstream = "npm:pnpm";
      version = v.pnpm;
      versionPolicy = "fast";
      sourceKind = "npm-tarball";
      assets.any = {
        url = "https://registry.npmjs.org/pnpm/-/pnpm-${v.pnpm}.tgz";
        hash = "sha512-C3+LmAYAMZBMAX46QesYehbUDuuCm5XE+MsDaBdh/Eq1PdIZEVubRH9NzhoFohR2RGHn03AzkqnzL5URzoyGyA==";
      };
      license = "mit";
      patchFamily = "shebang-retarget"; # nixpkgs nodejs-slim aborts on a libuv kqueue EINTR assertion at Darwin teardown; Node 26 exits clean
      cacheClass = "forge-cache-hit";
      updateEngine = "nvfetcher";
      retention = "git-history";
      projection.overlay = "override";
      overlayReason = "the `pnpm` attr routes every consumer through the 11 line riding nodejs-bin_26";
      consumers = ["node-tools" "mcp-launchers"];
    };

    sqlean = {
      upstream = "github:nalgeon/sqlean";
      version = v.sqlean;
      versionPolicy = "fast";
      sourceKind = "github-release";
      assets = {
        aarch64-darwin = {
          url = "${v.sqleanBase}/sqlean-macos-arm64.zip";
          fetch = "zip";
          hash = "sha256-G8qhU4xCuw0qXQhkkJqvV0dbDiuow4BwVXeQsOxaeFo=";
        };
        aarch64-linux = {
          url = "${v.sqleanBase}/sqlean-linux-arm64.zip";
          fetch = "zip";
          hash = "sha256-B02nNIeQFSF8oQU3uUf5R/qvta8NgFyrQO63KJVOix8=";
        };
        x86_64-linux = {
          url = "${v.sqleanBase}/sqlean-linux-x64.zip";
          fetch = "zip";
          hash = "sha256-vyon1pZ7i+sjrONSq9PkJ7vC2tFHfFNNw8qp0ng0Pdw=";
        };
      };
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
      updateEngine = "nvfetcher";
      retention = "git-history";
      projection.overlay = "override";
      overlayReason = "nixpkgs lags the rapid channel on aarch64-darwin; other platforms keep the nixpkgs package (consumer policy)";
      consumers = ["dev-tools" "gws"];
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
      consumers = ["carbon.nix"];
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
      kernel = true; # hand-authored derivation kernel; the row owns version/asset facts
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
      kernel = true;
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
      consumers = ["forge-tools" "Rasm tools/assay"];
    };

    sqlite-forge = {
      upstream = "repo:overlays/sqlite-forge";
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
      kernel = true;
      consumers = ["db-tools"];
    };
  };

  # CLI tool admissions (ADMISSION_IS_A_ROW): nixpkgs-sourced tools whose pin
  # follows the flake input — rows carry no frozen version copy; the JSON
  # projection resolves the live version from the package set at build time.
  # `chords` are candidate DATA for the CA-1 register; projection is CA-1's.
  # `install`: hm-roster (a roster group below consumes it) | ca1 (CA-1 owns
  # installation and projection) | landed (already owned by a config module).
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

  # One roster fold serves every HM consumer: rows for one roster group whose
  # installation this manifest owns; consumers map their package set over it.
  rosterRows = roster:
    builtins.filter (row: row.install == "hm-roster" && row.roster == roster)
    (builtins.attrValues admissions);

  # Host-runtime extension registries: package-like assets consumed by a host.
  # One family, per-lane sources; CA-4/5/6/7 admit plugin rows here, each
  # carrying the security fields named in the vocabulary. Empty row sets are
  # lanes with a declared source and no vetted admission yet. `requiredFields`
  # is the lane's admission contract: the ledger fold rejects any row missing
  # one, so an under-specified admission fails the build, never lands silent.
  extensions = {
    vscode = {
      source = "nix-vscode-extensions"; # Marketplace/OpenVSX generated registry; admission is per-row vetting, never registry trust
      forbiddenLanes = ["homebrew-brewfile-vscode"]; # extension presence never splits across Homebrew and the declared source
      liveState = "user-managed extensions dir; a drift row until rows are vetted (per-row security fields required)";
      requiredFields = vocabulary.extensionSecurityFields;
      rows = {};
    };
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
        # hmts-nvim admission reverted: 1.3.0 crashes on Neovim 0.12 +
        # nvim-treesitter main (LanguageTree parent API drift) against real
        # Forge files; re-admits only on an upstream compatibility release.
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
