# Title         : dev-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/dev-tools.nix
# ----------------------------------------------------------------------------
# Language-agnostic tooling: linters, formatters, and helpers shared across multiple ecosystems.
{
  config,
  lib,
  pkgs,
  ...
}: let
  manifest = import ../../../../overlays/manifest.nix;
  style = import ../../../style.nix;
  # shfmt reads .editorconfig only when invoked without style flags; the wrapper injects the house style solely when the caller passes no style flag
  # and no .editorconfig governs the working tree, so project law wins. Go's flag parser accepts -flag, --flag, and both =value forms alike.
  shfmt = pkgs.writeShellApplication {
    name = "shfmt";
    text = ''
      ${style.walkUp}
      for arg in "$@"; do
        [[ "$arg" == -* ]] || continue
        flag="''${arg#-}"
        flag="''${flag#-}"
        case "$flag" in
          i | i=* | ci | ci=* | sr | sr=* | kp | kp=* | fn | fn=* | bn | bn=* | mn | mn=*)
            exec ${pkgs.shfmt}/bin/shfmt "$@"
            ;;
        esac
      done
      _walk_up .editorconfig >/dev/null && exec ${pkgs.shfmt}/bin/shfmt "$@"
      exec ${pkgs.shfmt}/bin/shfmt -i ${toString style.indent} -ci "$@"
    '';
  };

  # taplo has no user-level lookup and TAPLO_CONFIG overrides project configs; the wrapper reaches the house config only when upward discovery finds
  # no project taplo.toml and the caller passes neither flag nor env. -c* covers clap's attached and equals value forms.
  taplo = pkgs.writeShellApplication {
    name = "taplo";
    text = ''
      ${style.walkUp}
      [[ -n "''${TAPLO_CONFIG:-}" ]] && exec ${pkgs.taplo}/bin/taplo "$@"
      for arg in "$@"; do
        case "$arg" in
          -c* | --config | --config=* | --no-auto-config) exec ${pkgs.taplo}/bin/taplo "$@" ;;
        esac
      done
      _walk_up .taplo.toml taplo.toml >/dev/null && exec ${pkgs.taplo}/bin/taplo "$@"
      TAPLO_CONFIG="${config.xdg.configHome}/taplo/taplo.toml" exec ${pkgs.taplo}/bin/taplo "$@"
    '';
  };
  # Data-lane admissions from the package manifest (CSV -> xan; relational/Parquet -> DuckDB).
  dataRoster = map (row: pkgs.${row.attr}) (manifest.rosterRows "data");
  dotnet-combined = pkgs.dotnetCorePackages.combinePackages [
    pkgs.dotnet-sdk_8
    pkgs.dotnet-sdk_9
    pkgs.dotnet-sdk_10
  ];
  # dnx owns NuGet MCP-server resolution and RID selection; an unversioned package reference resolves the stable NuGet.org release at spawn, the
  # fleet's own currency contract. CLI tools never ride this lane — they are manifest rows with generated pins.
  dnxMcp = name: package:
    pkgs.writeShellScriptBin name ''
      export DOTNET_ROOT="${pkgs.dotnet-sdk_10}/share/dotnet"
      exec ${pkgs.dotnet-sdk_10}/bin/dnx ${package} --source https://api.nuget.org/v3/index.json -- "$@"
    '';
  nuget-mcp = dnxMcp "nuget-mcp" "NuGet.Mcp.Server";
  binlog-mcp = dnxMcp "binlog-mcp" "Microsoft.AITools.BinlogMcp";
  antigravity-cli-bin-dir = "${config.home.homeDirectory}/.local/bin";
  forge-install-antigravity-cli = pkgs.writeShellApplication {
    name = "forge-install-antigravity-cli";
    runtimeInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.curl
      pkgs.gnused
      pkgs.gnutar
      pkgs.gzip
      pkgs.perl
    ];
    text = ''
      target_dir="${antigravity-cli-bin-dir}"
      binary="$target_dir/agy"
      mkdir -p "$target_dir"
      export PATH="$target_dir:$PATH"

      if [ -x "$binary" ]; then
        "$binary" update >/dev/null || printf '[WARN] agy update failed; keeping existing binary\n' >&2
        exit 0
      fi

      tmp="$(mktemp -d)"
      trap 'rm -rf "$tmp"' EXIT
      curl -fsSL https://antigravity.google/cli/install.sh -o "$tmp/install.sh"
      ${pkgs.bash}/bin/bash "$tmp/install.sh" --dir "$target_dir"
      test -x "$binary"
    '';
  };
in {
  # Machine-level fallback style for the YAML pair. yamlfmt walks the working tree upward for a project .yamlfmt before touching
  # $XDG_CONFIG_HOME/yamlfmt/.yamlfmt; yamllint discovery rides YAMLLINT_CONFIG_FILE behind project-local .yamllint files, so project law always wins.
  xdg.configFile = {
    # shellcheck resolves rc files from the script's directory upward, then ~/.shellcheckrc, then this file; a project rc fully shadows it. Keep
    # ~/.shellcheckrc absent — it would shadow this row.
    "shellcheckrc".text = ''
      external-sources=true
      enable=deprecate-which
    '';
    # taplo has no user-level lookup and TAPLO_CONFIG overrides project configs; only the wrapper above may reference this file.
    "taplo/taplo.toml".text = ''
      # Estate law: every pyproject.toml carries hand-aligned comment columns across its dependency arrays; no formatter
      # route touches it. Vendored trees stay out of any repo-wide sweep.
      exclude = ["**/pyproject.toml", "**/node_modules/**"]

      [formatting]
      indent_string = "${style.indentString}"
      column_width = ${toString style.width}
      allowed_blank_lines = 2
      reorder_keys = false
    '';
    # Projected from the style vocabulary; the treefmt row reads the same value, so every yamlfmt consumer shares one source.
    "yamlfmt/.yamlfmt".text = style.yamlfmt;
    "yamllint/config".text = ''
      extends: default

      # yamlfmt owns shape: its sequence-item nesting is engine-fixed and no indentation rule can describe it, so the linter cedes that dimension.
      rules:
        line-length:
          max: ${toString style.width}
          level: warning
        indentation: disable
        document-start: disable
        truthy:
          check-keys: false
    '';
  };

  # Machine editor law from the style vocabulary: nearest-first resolution means any repo-local .editorconfig fully outranks this fallback.
  home.file.".editorconfig".text = style.editorconfig;

  home = {
    activation = {
      ensureAntigravityCli = lib.hm.dag.entryAfter ["linkGeneration"] ''
        ${forge-install-antigravity-cli}/bin/forge-install-antigravity-cli
      '';
    };

    packages = with pkgs;
      [
        # --- [SHELL_TOOLING]
        bash # Bash 5.3+ runtime for generated scripts and explicit bash sessions
        shellcheck # POSIX shell static analysis
        shfmt # Shell formatter (let-bound house-style fallback wrapper)
        bash-language-server # Bash LSP (navigation + diagnostics via shellcheck/shfmt)

        # --- [YAML]
        yamlfmt # YAML formatter (Google)
        yamllint # YAML linter
        yaml-language-server # YAML LSP (SchemaStore-backed validation + completion)
        taplo # TOML formatter/validator/LSP (let-bound house-config fallback wrapper)

        # --- [JSON]
        jq # Lightweight command-line JSON processor

        # --- [HTML_MARKUP]
        validator-nu # W3C HTML5/SVG/CSS conformance validator (vnu); backs the html-studio gate

        # --- [GENERAL_DATA_TOOLS]
        git-lfs # Required by Homebrew update-reset and repos with LFS-backed fixtures
        yq-go # YAML/JSON/TOML processor (yq)
        miller # CSV/TSV/JSON processor
        qsv # High-performance CSV and tabular data toolkit
        csvlens # Interactive CSV/TSV inspector
        hurl # HTTP request/assertion runner for API probes
        typos # Fast source and docs typo checker

        # --- [PROTOBUF]
        protobuf # protoc; buf drives its built-in csharp generator and ships none of its own
        grpc # grpc_csharp_plugin the C# service row runs (grpc_python_plugin rides the same derivation)
        grpcurl # gRPC server reflection and request CLI
        protoc-gen-jsonschema # JSON Schema 2020-12 emitter over the descriptor graph (overlay source-build); buf's `local:` row resolves it bare on PATH

        # --- [NET]
        # Global tools resolve the combined SDK on PATH at runtime (overlay nuget-tool rows), so a project's global.json governs every invocation
        # and no repo carries a .config/dotnet-tools.json of its own; `dotnet <verb>` reaches each `dotnet-<verb>` through PATH.
        dotnet-combined
        csharpier # C# formatter; reads project .csharpierrc/.editorconfig
        dotnet-ef # EF Core design-time CLI (migrations, scaffold, dbcontext optimize); overlay row rides the EF patch line
        dotnet-outdated # NuGet dependency currency report and upgrade over Directory.Packages.props
        dotnet-trace # EventPipe trace collect/convert (speedscope, chromium)
        dotnet-counters # live EventCounter/Meter monitor for a running process
        dotnet-dump # process dump capture and SOS analysis
        dotnet-gcdump # GC heap dump capture and report
        dotnet-coverage # coverage collect/merge/convert; on Apple Silicon `collect` needs --include-files (static), dynamic instrumentation is x64-only
        reportgenerator # coverage report renderer over cobertura/lcov (HTML, badges, markdown summaries)
        dotnet-stryker # mutation testing over the Microsoft.Testing.Platform runner
        sharpfuzz # coverage-guided fuzzing instrumentation for .NET assemblies
        ilspycmd # .NET assembly decompiler for NuGet API catalogues (overlay row: release nupkg)
        nuget-to-json # NuGet package metadata extraction
        roslyn-ls # C# LSP: Microsoft.CodeAnalysis.LanguageServer; the server rows in apps/nvim pass --stdio, --autoLoadProjects, and the log directory

        # --- [CLOUD_IAC]
        google-cloud-sdk # Google Cloud CLI for OAuth/API bootstrap and project administration
        gws # Google Workspace CLI; scripted/batch companion to the google-workspace MCP
        pulumi # Pulumi CLI engine; Python SDK is managed per-project via uv
      ]
      ++ dataRoster
      ++ [nuget-mcp binlog-mcp];

    # DOTNET_ROOT required for Roslyn and other SDK-discovery tools; re-evaluated on every rebuild, store path stays current.
    sessionVariables.DOTNET_ROOT = "${dotnet-combined}/share/dotnet";
  };
}
