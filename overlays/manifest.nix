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
  # A source row rebuilds a nixpkgs recipe at the pinned release: `sourcePackage` names the recipe, the pin's asset replaces its source.
  designSource = name: let
    pin = "design-${name}";
  in {
    sourcePackage = name;
    asset = pinAsset pin;
    inherit (generatedPins.${pin}) version;
  };
  # EnergyPlus and OpenStudio asset names carry a build hash, so each pin's release tag is `v<version>/<asset>` and the bare version is the
  # tag's; the wrapper names below carry it.
  v = builtins.mapAttrs (_: pin: builtins.head (builtins.match "v([^/]+)/.*" generatedPins.${pin}.version)) {
    openstudio = "openstudio-aarch64-darwin";
    energyplus = "energyplus-aarch64-darwin";
  };
in {
  # A row named after a nixpkgs attr overrides it and re-keys every package above it off the binary cache; a `-current` row is a new attr
  # beside nixpkgs', which only its own consumers read.
  packages = {
    nvfetcher = {
      asset = pinAsset "nvfetcher";
      inherit (generatedPins.nvfetcher) version;
    };
    rclone = {
      sourcePackage = "rclone";
      asset = pinAsset "rclone";
      inherit (generatedPins.rclone) version;
      vendorHash = "sha256-+08M76VSLYFZjblRMFXg925k0qOzW25By0YyeIOLNo4=";
    };
    ocrmypdf = {
      pythonPackages =
        builtins.mapAttrs (_: pin: {
          asset = pinAsset pin;
          inherit (generatedPins.${pin}) version;
        }) {
          ocrmypdf = "ocrmypdf";
          pikepdf = "ocr-pikepdf";
          pydantic = "ocr-pydantic";
          pydantic-core = "ocr-pydantic-core";
          pypdfium2 = "ocr-pypdfium2";
        };
      ctypesgenHash = "sha256-2+JEjAWGK1lCPeLX4BAIiIXlQo7+OgZ8oh6plwfrHuY=";
    };
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
    # The font projection and every typography consumer render the current Geist release, whose Mono ligatures nixpkgs' copy lacks.
    geist-font = designSource "geist-font";
    # The script fallback chain and the design apps render the current SIL release, which nixpkgs lags.
    scheherazade-new = designSource "scheherazade-new";
    # A new attr beside nixpkgs' harfbuzz: an override re-keys pango, libass, libraqm, and every package above them off the binary cache.
    # `sourceOverride` feeds the recipe's own flags: the experimental vector and GPU libraries carry hb-vector and libharfbuzz-gpu.
    harfbuzz-current =
      designSource "harfbuzz"
      // {
        sourceOverride = {
          withVector = true;
          withGPU = true;
        };
      };
    mupdf = designSource "mupdf";
    # nixpkgs trails the fonttools release line by several minors. The row rebuilds the top-level application attr, which no package in the
    # system closure reads; python3Packages.fonttools and everything built on it stay on the binary cache.
    fonttools = designSource "fonttools";
    # A new attr beside nixpkgs' librsvg, which GTK, ImageMagick, and ffmpeg link and which trails the stable series: the artifact-tools row
    # reads rsvg-convert from it. The build drops introspection and the pixbuf loader, which serve the linking packages alone.
    librsvg-current =
      designSource "librsvg"
      // {
        sourceOverride = {
          withIntrospection = false;
          withPixbufLoader = false;
        };
      };

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
      description = "Current veraPDF conformance inspection on the current Temurin Java runtime";
      homepage = "https://verapdf.org/";
      mainProgram = "verapdf";
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

    # nixpkgs source-builds watchexec behind the upstream release line; the override routes the shell-tools row through the official release
    # tarball, which carries the binary, man page, and completions.
    watchexec = {
      version = generatedPins.watchexec-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "watchexec-aarch64-darwin";
      license = "asl20";
      description = "Executes commands in response to file modifications";
      homepage = "https://watchexec.github.io/";
      mainProgram = "watchexec";
    };

    zellij-unwrapped = {
      version = generatedPins.zellij-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "zellij-aarch64-darwin";
      license = "mit";
      description = "Terminal workspace with batteries included";
      homepage = "https://zellij.dev/";
      mainProgram = "zellij";
    };

    # A new attr beside nixpkgs' duckdb, which is a library its dependents link and trails the upstream major: the shell-tools row reads the
    # official CLI release, whose tarball holds the one executable.
    duckdb-current = {
      version = generatedPins.duckdb-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "duckdb-aarch64-darwin";
      license = "mit";
      description = "In-process analytical SQL database CLI";
      homepage = "https://duckdb.org/";
      mainProgram = "duckdb";
    };

    sqlean = {
      version = generatedPins.sqlean-aarch64-darwin.version;
      # The flat release zip has no top directory to strip.
      assets.aarch64-darwin = pinAsset "sqlean-aarch64-darwin" // {stripRoot = false;};
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
          rev = "2cfa9fea761e507b62a09daa1d8bef440a40265c";
          hash = "sha256-RgrMNW5GJ+WaJnioj2DfAWdBw6fxQezNJEYV4tqroSo=";
          license = "mit";
          permissions = ["broadcast-input-active-tab" "clipboard-paste" "window-frame-overrides"];
          surface = "runtime"; # direct store-path dofile (fetched trees are not git repos; plugin.require cannot clone them); toggle chord guarded by the deck
          apply = "apply_to_config";
        };
      };
    };
    zellij-plugins = {
      # One release wasm per row into ~/.config/zellij/plugins: a row with `attr` resolves in nixpkgs zellijPlugins, a row with url/hash pins an
      # upstream release nixpkgs omits; `permissions` seeds the grant cache.
      source = "nixpkgs:zellijPlugins | fetchurl";
      rows = {
        zjstatus = {
          attr = "zjstatus";
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
    models = let
      whisperCpp = "https://huggingface.co/ggerganov/whisper.cpp/resolve/5359861c739e955e79d9a303bcbc70fb988958b1";
    in {
      # One weight file per row into $XDG_DATA_HOME/models (media-tools/models.nix), named as upstream names it and fetched from `base` at
      # the revision that holds it. whisper.cpp and ffmpeg load a model by path and ship none.
      source = "fetchurl";
      rows = {
        "ggml-base.en-q5_1.bin" = {
          base = whisperCpp;
          hash = "sha256-S69w3Q18Qke6K4H6/ZwBAFrHfC+e8GTgDc8ZXQ4v3S8=";
          license = "MIT"; # English speech, 60 MB: the fastest model for clean narration
        };
        "ggml-small.en-q5_1.bin" = {
          base = whisperCpp;
          hash = "sha256-v9/0iU3Ldrv2R9ViY+oqlmRUI/FmkXb0hEob+OR4rTA=";
          license = "MIT"; # English speech, 190 MB
        };
        "ggml-large-v3-turbo-q5_0.bin" = {
          base = whisperCpp;
          hash = "sha256-OUIhcJzVrR9AxG5gMcphvOiJMebgiMGIKUxtWlX/p+I=";
          license = "MIT"; # Every language whisper knows, 574 MB
        };
        "ggml-silero-v6.2.0.bin" = {
          base = "https://huggingface.co/ggml-org/whisper-vad/resolve/9ffd54a1e1ee413ddf265af9913beaf518d1639b";
          hash = "sha256-KqJpt4XutTqCmDogUB3ffB2cSOM6tjpBORrGyff7aYc=";
          license = "MIT"; # Silero voice-activity detection for `whisper-cli --vad -vm` and whisper-vad-speech-segments
        };
        "cb.rnnn" = {
          base = "https://raw.githubusercontent.com/GregorR/rnnoise-models/3eee541a283fd3b8f81b85b1748e3b9ccbefa04d/conjoined-burgers-2018-08-28";
          hash = "sha256-8TV8Tlvp3uhGe+rUht/O0tdbZAwmrQtZT6fxAjIjcdk=";
          license = "public-domain"; # RNNoise speech denoiser for ffmpeg's arnndn filter (`arnndn=m=<path>`); upstream states the weights carry no copyright
        };
      };
    };
  };
}
