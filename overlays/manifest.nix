let
  generatedPins = builtins.fromJSON (builtins.readFile ./_sources/generated.json);
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
  designSource = name: let
    pin = "design-${name}";
  in {
    sourcePackage = name;
    asset = pinAsset pin;
    inherit (generatedPins.${pin}) version;
  };
  v = builtins.mapAttrs (_: pin: builtins.head (builtins.match "v([^/]+)/.*" generatedPins.${pin}.version)) {
    openstudio = "openstudio-aarch64-darwin";
    energyplus = "energyplus-aarch64-darwin";
    gam = "gam-aarch64-darwin";
  };
in {
  packages = {
    nvfetcher-current = {
      asset = pinAsset "nvfetcher";
      inherit (generatedPins.nvfetcher) version;
    };
    git-current = {
      sourcePackage = "git";
      asset = pinAsset "git";
      inherit (generatedPins.git) version;
    };
    rsync-current = {
      sourcePackage = "rsync";
      asset = pinAsset "rsync";
      inherit (generatedPins.rsync) version;
    };
    yt-dlp-current = {
      sourcePackage = "yt-dlp";
      asset = pinAsset "yt-dlp";
      inherit (generatedPins.yt-dlp) version;
    };
    gallery-dl-current = {
      sourcePackage = "gallery-dl";
      asset = pinAsset "gallery-dl";
      inherit (generatedPins.gallery-dl) version;
    };
    ocrmypdf-current = {
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
    vl-convert = {
      version = generatedPins.vl-convert-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "vl-convert-aarch64-darwin";
      license = "bsd3";
      description = "Vega and Vega-Lite spec export to SVG, PNG, JPEG, and PDF";
      homepage = "https://github.com/vega/vl-convert";
      mainProgram = "vl-convert";
    };
    fontspector = {
      version = generatedPins.fontspector-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "fontspector-aarch64-darwin";
      license = "asl20";
      description = "OpenType font quality checks with universal, OpenType, and Google Fonts profiles";
      homepage = "https://github.com/fonttools/fontspector";
      mainProgram = "fontspector";
    };
    diffenator3 = {
      version = generatedPins.diffenator3-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "diffenator3-aarch64-darwin";
      license = "asl20";
      description = "Font version comparison over tables, kerning, glyphs, and rendered words";
      homepage = "https://github.com/googlefonts/diffenator3";
      mainProgram = "diffenator3";
    };
    fontc-current = {
      version = generatedPins.fontc-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "fontc-aarch64-darwin";
      license = "asl20";
      description = "Font compiler from UFO, Glyphs, and designspace sources";
      homepage = "https://github.com/googlefonts/fontc";
      mainProgram = "fontc";
    };
    fontforge-current.patches = [
      {
        rev = "fbc4114e1af657b0889f78d24f70c4d56937d189";
        hash = "sha256-ALyD7faiy1RuOXyTTG+U+ab+9w4KA6bVZOGXrK6WqGA=";
      }
      {
        rev = "763b8fc6d05815282b83f9668d23cd2fe58e310a";
        hash = "sha256-q+HQoEldmaWfWwUbEkadQCHotGARuArIxfFfEH4k6Zc=";
      }
    ];
    fontheight-cli = {
      asset = pinAsset "fontheight-cli";
      inherit (generatedPins.fontheight-cli) version;
      license = "asl20";
      description = "Vertical extents a font reaches on shaped words of each language";
      homepage = "https://github.com/googlefonts/fontheight";
      mainProgram = "fontheight";
    };
    scheherazade-new-current = designSource "scheherazade-new";
    harfbuzz-current =
      designSource "harfbuzz"
      // {
        sourceOverride = {
          withVector = true;
          withGPU = true;
          withRaster = true;
          withCairo = true;
          withIcu = true;
        };
      };
    mupdf-current = designSource "mupdf";
    fonttools-current = designSource "fonttools";
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
      license = "mpl20";
      description = "Current veraPDF conformance inspection on the current Temurin Java runtime";
      homepage = "https://verapdf.org/";
      mainProgram = "verapdf";
    };

    mise-current = {
      version = generatedPins.mise-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "mise-aarch64-darwin";
      license = "mit";
      description = "mise runtime manager: per-project toolchains, env, and tasks";
      homepage = "https://mise.jdx.dev/";
      mainProgram = "mise";
    };

    hostinger = {
      version = generatedPins.hostinger-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "hostinger-aarch64-darwin";
      license = "mit";
      description = "Hostinger API command-line client for VPS, DNS, domains, mail, and hosting";
      homepage = "https://github.com/hostinger/api-cli";
      mainProgram = "hostinger";
    };

    swift-section = {
      version = generatedPins.swift-section-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "swift-section-aarch64-darwin";
      license = "mit";
      description = "Swift interface, type metadata, and Objective-C declarations of a Mach-O file or dyld shared cache";
      homepage = "https://github.com/MxIris-Reverse-Engineering/MachOSwiftSection";
      mainProgram = "swift-section";
    };

    ifcconvert = {
      version = generatedPins.ifcconvert-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "ifcconvert-aarch64-darwin" // {stripRoot = false;};
      license = "lgpl3Plus";
      description = "IFC geometry to glTF, OBJ, SVG, and STEP";
      homepage = "https://ifcopenshell.org";
      mainProgram = "IfcConvert";
    };

    retoc = {
      version = generatedPins.retoc-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "retoc-aarch64-darwin";
      license = "mit";
      description = "Unreal IoStore container listing, verification, and unpacking";
      homepage = "https://github.com/trumank/retoc";
      mainProgram = "retoc";
    };

    ipsw-current = {
      version = generatedPins.ipsw-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "ipsw-aarch64-darwin";
      license = "mit";
      description = "Mach-O, dyld shared cache, code signature, asset catalog, plist, and crash log reader";
      homepage = "https://github.com/blacktop/ipsw";
      mainProgram = "ipsw";
    };

    macmon-current = {
      version = generatedPins.macmon-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "macmon-aarch64-darwin" // {stripRoot = false;};
      license = "mit";
      description = "Apple Silicon CPU, GPU, ANE, power, disk, network, and battery monitor without sudo";
      homepage = "https://github.com/vladkens/macmon";
      mainProgram = "macmon";
    };

    mq = {
      version = generatedPins.mq-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "mq-aarch64-darwin";
      license = "mit";
      description = "jq-style queries and edits over Markdown structure";
      homepage = "https://mqlang.org/";
      mainProgram = "mq";
    };

    curl-impersonate-current = {
      version = generatedPins.curl-impersonate-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "curl-impersonate-aarch64-darwin" // {stripRoot = false;};
      license = "mit";
      description = "curl build that sends browser TLS and HTTP/2 fingerprints";
      homepage = "https://github.com/lexiforest/curl-impersonate";
      mainProgram = "curl-impersonate";
    };

    gemini-api = {
      version = generatedPins.gemini-api-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "gemini-api-aarch64-darwin";
      license = "asl20";
      description = "Gemini Interactions API command-line client for generation, media analysis, files, and managed agents";
      homepage = "https://github.com/google-gemini/gemini-api-cli";
      mainProgram = "gemini-api";
    };

    pdfm-mcp = {
      version = generatedPins.pdfm-mcp-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "pdfm-mcp-aarch64-darwin";
      license = "mit";
      description = "Parallels Desktop MCP server for VM power, guest exec, input, screen capture, snapshots, and settings";
      homepage = "https://github.com/Parallels/pdfm-mcp";
      mainProgram = "pdfm-mcp";
    };

    bambu = {
      version = generatedPins.bambu-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "bambu-aarch64-darwin";
      license = "mit";
      description = "Bambu Lab printer command-line client over LAN for slicing, preflight, print control, and monitoring";
      homepage = "https://github.com/voska/bambu";
      mainProgram = "bambu";
    };

    tscli-current = {
      version = generatedPins.tscli-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "tscli-aarch64-darwin";
      license = "mit";
      description = "Tailscale HTTP API command-line client for devices, keys, policy, and services";
      homepage = "https://github.com/jaxxstorm/tscli";
      mainProgram = "tscli";
    };

    officecli-current = {
      version = generatedPins.officecli-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "officecli-aarch64-darwin";
      license = "asl20";
      description = "Reads, queries, edits, and renders Word, Excel, and PowerPoint files";
      homepage = "https://github.com/iOfficeAI/OfficeCLI";
      mainProgram = "officecli";
    };

    gam-current = {
      version = v.gam;
      assets.aarch64-darwin = pinAsset "gam-aarch64-darwin";
      license = "asl20";
      description = "Google Workspace administration command-line client";
      homepage = "https://github.com/GAM-team/GAM";
      mainProgram = "gam";
    };

    yq-go-current = {
      version = generatedPins.yq-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "yq-aarch64-darwin";
      license = "mit";
      description = "YAML, JSON, XML, CSV, TOML, and properties processor";
      homepage = "https://mikefarah.gitbook.io/yq/";
      mainProgram = "yq";
    };

    dua-current = {
      version = generatedPins.dua-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "dua-aarch64-darwin";
      license = "mit";
      description = "Disk usage analyzer";
      homepage = "https://github.com/Byron/dua-cli";
      mainProgram = "dua";
    };

    coderabbit = {
      version = generatedPins.coderabbit-aarch64-darwin.version;
      assets.aarch64-darwin = pinAsset "coderabbit-aarch64-darwin";
      license = "unfree";
      description = "CodeRabbit AI review of local Git changes, with NDJSON findings in agent mode";
      homepage = "https://docs.coderabbit.ai/cli";
      mainProgram = "coderabbit";
    };

    powershell-current = {
      sourcePackage = "powershell";
      asset = pinAsset "powershell-aarch64-darwin";
      inherit (generatedPins.powershell-aarch64-darwin) version;
      modules = {
        ExchangeOnlineManagement = {
          asset = pinAsset "exchange-online-management";
          inherit (generatedPins.exchange-online-management) version;
        };
        MicrosoftTeams = {
          asset = pinAsset "microsoft-teams-module";
          inherit (generatedPins.microsoft-teams-module) version;
        };
        "PnP.PowerShell" = {
          asset = pinAsset "pnp-powershell";
          inherit (generatedPins.pnp-powershell) version;
        };
      };
    };

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
      assets.aarch64-darwin = pinAsset "sqlean-aarch64-darwin" // {stripRoot = false;};
      license = "mit";
      projection.package = true;
      description = "Bundled SQLite extension libraries from SQLean";
      homepage = "https://github.com/nalgeon/sqlean";
    };

    openstudio = {
      version = v.openstudio;
      assets.aarch64-darwin = pinAsset "openstudio-aarch64-darwin";
      license = "bsd3";
      runtime = {
        root = "opt/openstudio";
        shebangDirs = ["bin"];
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

  extensions = {
    zellij-plugins = {
      source = "fetchurl";
      rows = {
        zellij_forgot = {
          url = "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm";
          hash = "sha256-MRlBRVGdvcEoaFtFb5cDdDePoZ/J2nQvvkoyG6zkSds=";
          license = "MIT";
          permissions = ["ReadApplicationState" "ChangeApplicationState"];
        };
      };
    };
    duckdb-extensions = {
      source = "fetchurl";
      rows = {
        spatial = pinAsset "duckdb-spatial-aarch64-darwin" // {load = true;};
        excel = pinAsset "duckdb-excel-aarch64-darwin" // {load = true;};
        httpfs = pinAsset "duckdb-httpfs-aarch64-darwin";
        sqlite_scanner = pinAsset "duckdb-sqlite-scanner-aarch64-darwin";
        fts = pinAsset "duckdb-fts-aarch64-darwin";
      };
    };
    npm-tools = {
      source = "npx";
      rows = {
        "@adobe/aio-cli" = {
          inherit (generatedPins.aio-cli) version;
          commands = ["aio"];
          license = "Apache-2.0";
        };
        "@aredotna/cli" = {
          inherit (generatedPins.aredotna-cli) version;
          commands = ["arena"];
          license = "MIT";
        };
        "@electron/asar" = {
          inherit (generatedPins.electron-asar) version;
          commands = ["asar"];
          license = "MIT";
        };
        "@firefox-devtools/profiler-cli" = {
          inherit (generatedPins.firefox-profiler-cli) version;
          commands = ["profiler-cli" "pq"];
          license = "MPL-2.0";
        };
        "@gltf-transform/cli" = {
          inherit (generatedPins.gltf-transform-cli) version;
          commands = ["gltf-transform"];
          license = "MIT";
        };
        "@nexrender/cli" = {
          inherit (generatedPins.nexrender-cli) version;
          commands = ["nexrender-cli"];
          license = "MIT";
        };
        "@n8n/cli" = {
          inherit (generatedPins.n8n-cli) version;
          commands = ["n8n-cli"];
          license = "SUL-1.0";
        };
        "@pnp/cli-microsoft365" = {
          inherit (generatedPins.m365-cli) version;
          commands = ["m365"];
          license = "MIT";
        };
        "@tavily/cli" = {
          inherit (generatedPins.tavily-cli) version;
          commands = ["tvly"];
          license = "MIT";
        };
        bambu-printer-mcp = {
          inherit (generatedPins.bambu-printer-mcp) version;
          commands = ["bambu-printer-mcp"];
          license = "GPL-2.0";
          env.BAMBU_MODEL = "h2d";
        };
        cf = {
          inherit (generatedPins.cloudflare-cf) version;
          commands = ["cf"];
          license = "Apache-2.0";
        };
        chrome-devtools-mcp = {
          inherit (generatedPins.chrome-devtools-mcp) version;
          commands = ["chrome-devtools-mcp" "chrome-devtools"];
          license = "Apache-2.0";
        };
        ctx7 = {
          inherit (generatedPins.ctx7) version;
          commands = ["ctx7"];
          license = "MIT";
        };
        hyperframes = {
          inherit (generatedPins.hyperframes) version;
          commands = ["hyperframes"];
          license = "Apache-2.0";
          env.HYPERFRAMES_NO_TELEMETRY = "1";
        };
        mcp-remote = {
          inherit (generatedPins.mcp-remote) version;
          commands = ["mcp-remote"];
          license = "MIT";
        };
      };
    };
    uv-tools = {
      source = "uvx";
      rows = {
        afdko = {
          inherit (generatedPins.afdko) version;
          commands = ["spot" "tx" "otfautohint" "makeotf" "ttxn" "sfntdiff"];
          license = "Apache-2.0";
        };
        fontmake = {
          inherit (generatedPins.fontmake) version;
          extras = ["pathops"];
          commands = ["fontmake"];
          license = "Apache-2.0";
        };
        foundrytools-cli = {
          inherit (generatedPins.foundrytools-cli) version;
          commands = ["ftcli"];
          license = "MIT";
        };
        glyphsLib = {
          inherit (generatedPins.glyphslib) version;
          commands = ["glyphs2ufo" "ufo2glyphs"];
          license = "Apache-2.0";
        };
        hyperglot = {
          inherit (generatedPins.hyperglot) version;
          commands = ["hyperglot" "hyperglot-data" "hyperglot-report"];
          license = "Apache-2.0";
        };
        nanoemoji = {
          inherit (generatedPins.nanoemoji) version;
          commands = ["nanoemoji"];
          license = "Apache-2.0";
        };
        youseedee = {
          inherit (generatedPins.youseedee) version;
          commands = ["youseedee"];
          license = "Apache-2.0";
        };
        notebooklm-py = {
          inherit (generatedPins.notebooklm-py) version;
          extras = ["browser" "cookies" "headless" "mcp"];
          commands = ["notebooklm" "notebooklm-mcp"];
          license = "MIT";
        };
        opentimelineio = {
          inherit (generatedPins.opentimelineio) version;
          withPackages = map (pin: "${pin}==${generatedPins.${pin}.version}") ["otio-fcp-adapter" "otio-fcpx-xml-adapter" "otio-aaf-adapter"];
          commands = ["otiotool" "otioconvert" "otiocat" "otiostat" "otiopluginfo"];
          license = "Apache-2.0";
        };
        py-aep = {
          inherit (generatedPins.py-aep) version;
          commands = ["aep-inspect" "aep-compare" "aep-validate" "aep-visualize"];
          license = "MIT";
        };
        ifcquery = {
          inherit (generatedPins.ifcquery) version;
          commands = ["ifcquery"];
          license = "LGPL-3.0-or-later";
        };
        psd-tools = {
          inherit (generatedPins.psd-tools) version;
          commands = ["psd-tools"];
          license = "MIT";
        };
        psd2svg = {
          inherit (generatedPins.psd2svg) version;
          commands = ["psd2svg"];
          license = "MIT";
        };
        pymobiledevice3 = {
          inherit (generatedPins.pymobiledevice3) version;
          commands = ["pymobiledevice3"];
          license = "GPL-3.0-or-later";
        };
        trafilatura = {
          inherit (generatedPins.trafilatura) version;
          commands = ["trafilatura"];
          license = "Apache-2.0";
        };
      };
    };
    models = let
      whisperCpp = "https://huggingface.co/ggerganov/whisper.cpp/resolve/5359861c739e955e79d9a303bcbc70fb988958b1";
    in {
      source = "fetchurl";
      rows = {
        "ggml-base.en-q5_1.bin" = {
          base = whisperCpp;
          hash = "sha256-S69w3Q18Qke6K4H6/ZwBAFrHfC+e8GTgDc8ZXQ4v3S8=";
          license = "MIT";
        };
        "ggml-small.en-q5_1.bin" = {
          base = whisperCpp;
          hash = "sha256-v9/0iU3Ldrv2R9ViY+oqlmRUI/FmkXb0hEob+OR4rTA=";
          license = "MIT";
        };
        "ggml-large-v3-turbo-q5_0.bin" = {
          base = whisperCpp;
          hash = "sha256-OUIhcJzVrR9AxG5gMcphvOiJMebgiMGIKUxtWlX/p+I=";
          license = "MIT";
        };
        "ggml-silero-v6.2.0.bin" = {
          base = "https://huggingface.co/ggml-org/whisper-vad/resolve/9ffd54a1e1ee413ddf265af9913beaf518d1639b";
          hash = "sha256-KqJpt4XutTqCmDogUB3ffB2cSOM6tjpBORrGyff7aYc=";
          license = "MIT";
        };
        "cb.rnnn" = {
          base = "https://raw.githubusercontent.com/GregorR/rnnoise-models/3eee541a283fd3b8f81b85b1748e3b9ccbefa04d/conjoined-burgers-2018-08-28";
          hash = "sha256-8TV8Tlvp3uhGe+rUht/O0tdbZAwmrQtZT6fxAjIjcdk=";
          license = "public-domain";
        };
      };
    };
  };
}
