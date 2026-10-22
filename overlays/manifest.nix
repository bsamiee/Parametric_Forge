# Title         : manifest.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/manifest.nix
# ----------------------------------------------------------------------------
# Package registry: rows own the generated pin reference, version, derivation metadata, and projection of every non-nixpkgs package, beside
# the host-runtime extension rows. overlays/default.nix folds `packages` rows into derivations; flake-modules/packages.nix folds
# `projection.package/app` into public outputs. Pure data plus builtins-only accessors — no pkgs, no lib.
let
  generatedPins = builtins.fromJSON (builtins.readFile ./_sources/generated.json);
  # A tarball pin hashes the unpacked tree (nvfetcher prefetches with --unpack), so the overlay fetches it as an unpacked fixed-output source.
  pinAsset = pin:
    {
      inherit pin;
      inherit (generatedPins.${pin}.src) url;
      hash = generatedPins.${pin}.src.sha256;
    }
    // (
      if generatedPins.${pin}.src.type == "tarball"
      then {fetch = "zip";}
      else {}
    );
  # `versionFrom`: a regex whose first group is the version when the publisher's release tag is path-shaped; null when the tag is already bare.
  designSource = name: versionFrom: let
    pin = "design-${name}";
  in {
    sourcePackage = name;
    sourcePin = pin;
    version = builtins.head (builtins.match (
        if versionFrom == null
        then "(.*)"
        else versionFrom
      )
      generatedPins.${pin}.version);
  };
  # EnergyPlus and OpenStudio asset names carry a build hash, so each pin's release tag is `v<version>/<asset>` and the bare version is the
  # tag's; the wrapper names below carry it.
  v = builtins.mapAttrs (_: pin: builtins.head (builtins.match "v([0-9.]+)/.*" generatedPins.${pin}.version)) {
    openstudio = "openstudio-aarch64-darwin";
    energyplus = "energyplus-aarch64-darwin";
  };
in {
  # A row named after a nixpkgs attr overrides it and re-keys every package above it off the binary cache; a `-current` row is a new attr
  # beside nixpkgs', which only its own consumers read.
  packages = {
    # Vega's own headless renderer: V8 and the Vega/Vega-Lite JS are linked into one executable, so the chart-export role carries no Node
    # source build and no browser. nixpkgs ships python3Packages.vl-convert-python only, never the CLI, so the attr is new.
    vl-convert = {
      version = generatedPins.vl-convert-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "vl-convert-aarch64-darwin";
      license = "bsd3";
      description = "Vega and Vega-Lite spec export to SVG, PNG, JPEG, and PDF";
      homepage = "https://github.com/vega/vl-convert";
      mainProgram = "vl-convert";
    };
    # New attrs beside nixpkgs' imagemagick and qpdf: an override re-keys vips, yazi, fastfetch, pikepdf, and every package above them off the cache.
    imagemagick-current = designSource "imagemagick" null;
    # The font projection and every typography consumer render the current Geist release, whose Mono ligatures nixpkgs' copy lacks.
    geist-font = designSource "geist-font" null;
    # The script fallback chain and the design apps render the current SIL release, which nixpkgs lags.
    scheherazade-new = designSource "scheherazade-new" null;
    # A new attr beside nixpkgs' harfbuzz: an override re-keys pango, libass, libraqm, and every package above them off the binary cache.
    harfbuzz-current = designSource "harfbuzz" null;
    poppler-utils-current =
      designSource "poppler" null
      // {
        sourcePackage = "poppler-utils";
        testDataPin = "design-poppler-test-data";
      };
    mupdf = designSource "mupdf" null;
    qpdf-current = designSource "qpdf" null;
    ghostscript = designSource "ghostscript" "gs[0-9]+/ghostscript-(.*)\\.tar\\.xz";

    utiluti = {
      version = generatedPins.design-utiluti.version;
      assets.aarch64-darwin = pinAsset "design-utiluti";
      license = "asl20";
      description = "Native macOS file and URL application associations";
      homepage = "https://github.com/scriptingosx/utiluti";
      mainProgram = "utiluti";
    };

    pandoc-current = {
      version = generatedPins.design-pandoc-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "design-pandoc-aarch64-darwin";
      license = "gpl2Plus";
      description = "Universal document converter";
      homepage = "https://pandoc.org/";
      mainProgram = "pandoc";
    };

    # A new attr beside nixpkgs' _1password-cli, which trails the 1Password release line; its one consumer reads it, so nothing else re-keys.
    _1password-cli-current = {
      version = generatedPins."1password-cli-aarch64-darwin".version;
      assets.aarch64-darwin = pinAsset "1password-cli-aarch64-darwin";
      license = "unfree";
      description = "1Password command-line tool";
      homepage = "https://developer.1password.com/docs/cli/";
      mainProgram = "op";
    };

    verapdf-current = {
      version = generatedPins.design-verapdf-cli.version;
      assets.aarch64-darwin = pinAsset "design-verapdf-cli";
      license = "mpl20"; # The unmodified upstream JAR retains the alternative GPLv3+ license and third-party notices.
      description = "Current veraPDF conformance inspection with a private Java runtime";
      homepage = "https://verapdf.org/";
      mainProgram = "verapdf";
    };

    temurin-jre-current = let
      release = generatedPins.design-temurin-aarch64-darwin.version;
    in {
      version = builtins.substring 4 (builtins.stringLength release) release;
      # The Adoptium URL carries no file extension; fetchzip picks its unpacker by extension, so the asset names the archive format.
      assets.aarch64-darwin = pinAsset "design-temurin-aarch64-darwin" // {extension = "tar.gz";};
      license = "gpl2Only"; # OpenJDK also grants the Classpath exception; its original legal files ship with the runtime.
      description = "Private current Temurin Java runtime for veraPDF";
      homepage = "https://adoptium.net/";
      mainProgram = "java";
    };

    # nixpkgs source-builds biome behind the upstream release line; the override routes the treefmt row through the official release binary.
    biome = {
      version = generatedPins.biome-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "biome-aarch64-darwin";
      license = "mit";
      description = "Biome formatter, linter, and LSP for the web toolchain";
      homepage = "https://biomejs.dev/";
      mainProgram = "biome";
    };

    # nixpkgs source-builds mise behind the upstream release line; the override routes programs.mise and the zsh activation line through the
    # official release binary.
    mise = {
      version = generatedPins.mise-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "mise-aarch64-darwin";
      license = "mit";
      description = "mise runtime manager: per-project toolchains, env, and tasks";
      homepage = "https://mise.jdx.dev/";
      mainProgram = "mise";
    };

    sqlean = {
      version = generatedPins.sqlean-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "sqlean-aarch64-darwin";
      license = "mit";
      projection.package = true; # package-only: extension library set consumed by sqlite-extended
      description = "Bundled SQLite extension libraries from SQLean";
      homepage = "https://github.com/nalgeon/sqlean";
    };

    openstudio = {
      version = v.openstudio;
      assets.aarch64-darwin = pinAsset "openstudio-aarch64-darwin";
      license = "bsd3";
      # Opt-runtime spec: the shared overlay recipe folds these layout, env, and wrapper facts into the derivation; a next platform
      # runtime is one row, never a new kernel file.
      runtime = {
        root = "opt/openstudio";
        shebangDirs = ["bin"];
        # OpenStudio reads none of its layout from the environment; the one name is the session's route to the bundled Radiance binaries,
        # which land on no PATH.
        env = {
          roots = [];
          paths = {OPENSTUDIO_RADIANCE_ROOT = "Radiance";};
        };
        wrappers = {
          openstudio = "bin/openstudio";
          openstudio-install-utility = "bin/install_utility";
        };
      };
      description = "OpenStudio SDK and CLI for whole-building energy modeling";
      homepage = "https://openstudio.net";
      mainProgram = "openstudio";
    };

    energyplus = {
      version = v.energyplus;
      assets.aarch64-darwin = pinAsset "energyplus-aarch64-darwin";
      license = "bsd3";
      runtime = {
        root = "opt/energyplus";
        shebangDirs = ["."];
        # runenergyplus, runepmacro, and runreadvars read ENERGYPLUS_DIR and fall back to /usr on macOS without it.
        env = {
          roots = ["ENERGYPLUS_DIR"];
          paths = {};
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
      description = "Whole building energy simulation runtime";
      homepage = "https://energyplus.net";
      mainProgram = "energyplus";
    };

    sqlite-extended = {
      projection = {
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
    };
  };

  # Host-runtime extension registries: package-like assets consumed by a host. One family, per-lane sources; each host module reads its lane's rows.
  extensions = {
    wezterm-plugins = {
      source = "fetchFromGitHub"; # file:// store-path loads only
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
      source = "fetchurl"; # one release wasm per row, hash-pinned into ~/.config/zellij/plugins; `permissions` seeds the grant cache
      rows = {
        zjstatus = {
          inherit (pinAsset "zjstatus") url hash;
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
      # kebab-case <name>.yazi dirs with main.lua entrypoints: a row with `attr` resolves in nixpkgs yaziPlugins, a row with
      # owner/repo/rev/hash pins an upstream tree nixpkgs omits.
      source = "nixpkgs:yaziPlugins | fetchFromGitHub";
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
      source = "nixpkgs:vimPlugins"; # HM programs.neovim pack deployment; store-owned, runtime fetch unspellable
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
        nvim-lint = {
          attr = "nvim-lint";
          license = "GPL-3.0-only"; # non-LSP diagnostic lane (deadnix/statix/shellcheck/hadolint/typos)
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
