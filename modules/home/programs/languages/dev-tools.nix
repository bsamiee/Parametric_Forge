# Title         : dev-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/dev-tools.nix
# ----------------------------------------------------------------------------
# Language-agnostic tooling: linters, formatters, and helpers shared across
# multiple ecosystems.
{
  config,
  lib,
  pkgs,
  ...
}: let
  manifest = import ../../../../overlays/manifest.nix;
  # Data-lane admissions from the package manifest (CSV -> xan; relational/Parquet -> DuckDB).
  dataRoster =
    map (row: pkgs.${row.attr})
    (lib.filter (row: row.install == "hm-roster" && row.roster == "data")
      (lib.attrValues manifest.admissions));
  dotnet-combined = pkgs.dotnetCorePackages.combinePackages [
    pkgs.dotnet-sdk_8
    pkgs.dotnet-sdk_9
    pkgs.dotnet-sdk_10
  ];
  # roslyn-ls installs the binary as Microsoft.CodeAnalysis.LanguageServer and requires an
  # explicit log directory; wrap it so consumers invoke `roslyn-language-server --stdio` directly.
  roslyn-language-server = pkgs.writeShellScriptBin "roslyn-language-server" ''
    logdir="''${TMPDIR:-/tmp}/roslyn-ls"
    mkdir -p "$logdir"
    exec ${pkgs.roslyn-ls}/bin/Microsoft.CodeAnalysis.LanguageServer \
      --logLevel Information --extensionLogDirectory "$logdir" "$@"
  '';
  nuget-mcp-server = assert lib.asserts.assertMsg (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") "nuget-mcp packages the osx-arm64 RID and requires aarch64-darwin";
    pkgs.runCommand "nuget-mcp-server-osx-arm64-1.4.15" {
      src = pkgs.fetchurl {
        url = "https://api.nuget.org/v3-flatcontainer/nuget.mcp.server.osx-arm64/1.4.15/nuget.mcp.server.osx-arm64.1.4.15.nupkg";
        sha256 = "1zl6xxb7al1pydyma4lhd0fj8an5x0fv8g4h65jh65jz5h76grf1";
      };
      nativeBuildInputs = [pkgs.unzip];
    } ''
      mkdir -p "$out"
      unzip -q "$src" -d "$out"
      chmod +x "$out/tools/net10.0/osx-arm64/NuGet.Mcp.Server"
    '';
  nuget-mcp = pkgs.writeShellScriptBin "nuget-mcp" ''
    export DOTNET_ROOT="${dotnet-combined}/share/dotnet"
    exec ${nuget-mcp-server}/tools/net10.0/osx-arm64/NuGet.Mcp.Server "$@"
  '';
  workspace-mcp-version = "1.22.0";
  workspace-mcp-package = "workspace-mcp==${workspace-mcp-version}";
  workspace-mcp-tool-dir = "${config.xdg.dataHome}/uv/forge-tools";
  workspace-mcp-bin-dir = "${config.xdg.dataHome}/uv/forge-bin";
  # One ensure body serves the wrapper and the activation hook. The tool list
  # is captured, never piped into grep -q: an early-exit grep would SIGPIPE uv
  # under pipefail and force a spurious reinstall on every launch.
  workspace-mcp-ensure = ''
    export UV_TOOL_DIR="${workspace-mcp-tool-dir}"
    export UV_TOOL_BIN_DIR="${workspace-mcp-bin-dir}"
    export UV_CACHE_DIR="${config.xdg.cacheHome}/uv"
    export UV_PYTHON_DOWNLOADS=never
    mkdir -p "$UV_TOOL_DIR" "$UV_TOOL_BIN_DIR" "$UV_CACHE_DIR"
    tool_list="$(${pkgs.uv}/bin/uv tool list --show-version-specifiers 2>/dev/null || true)"
    if [ ! -x "$UV_TOOL_BIN_DIR/workspace-mcp" ] || [[ "$tool_list" != *"workspace-mcp v${workspace-mcp-version} [required: ==${workspace-mcp-version}]"* ]]; then
      ${pkgs.uv}/bin/uv tool install --force --python "${pkgs.python313}/bin/python3" "${workspace-mcp-package}" >/dev/null
    fi
  '';
  forge-workspace-mcp = pkgs.writeShellScriptBin "forge-workspace-mcp" ''
    set -euo pipefail
    ${workspace-mcp-ensure}
    exec "$UV_TOOL_BIN_DIR/workspace-mcp" "$@"
  '';
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
      set -euo pipefail

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
  home = {
    activation.ensureWorkspaceMcpTool = lib.hm.dag.entryAfter ["linkGeneration"] workspace-mcp-ensure;

    activation.ensureAntigravityCli = lib.hm.dag.entryAfter ["linkGeneration"] ''
      ${forge-install-antigravity-cli}/bin/forge-install-antigravity-cli
    '';

    packages = with pkgs;
      [
        # --- Shell Tooling ------------------------------------------------------
        bash # Bash 5.3+ runtime for generated scripts and explicit bash sessions
        shellcheck # POSIX shell static analysis
        shfmt # Shell script formatter
        bash-language-server # Bash LSP (navigation + diagnostics via shellcheck/shfmt)

        # --- YAML ---------------------------------------------------------------
        yamlfmt # YAML formatter (Google)
        yamllint # YAML linter
        yaml-language-server # YAML LSP (SchemaStore-backed validation + completion)
        taplo # TOML formatter, validator, and LSP

        # --- JSON ---------------------------------------------------------------
        jq # Lightweight command-line JSON processor

        # --- HTML / Markup ------------------------------------------------------
        validator-nu # W3C HTML5/SVG/CSS conformance validator (vnu); backs the html-studio gate

        # --- General Data Tools -------------------------------------------------
        git-lfs # Required by Homebrew update-reset and repos with LFS-backed fixtures
        yq-go # YAML/JSON/TOML processor (yq)
        miller # CSV/TSV/JSON processor
        qsv # High-performance CSV and tabular data toolkit
        csvlens # Interactive CSV/TSV inspector
        hurl # HTTP request/assertion runner for API probes
        grpcurl # gRPC server reflection and request CLI
        typos # Fast source and docs typo checker

        # --- .NET ---------------------------------------------------------------
        dotnet-combined
        ilspycmd # .NET assembly decompiler for NuGet API catalogues
        nuget-to-json # NuGet package metadata extraction
        roslyn-language-server # C# LSP (roslyn-ls wrapped for clean --stdio)

        # --- Cloud / IaC --------------------------------------------------------
        google-cloud-sdk # Google Cloud CLI for OAuth/API bootstrap and project administration
        gws # Google Workspace CLI; scripted/batch companion to the google-workspace MCP
        forge-workspace-mcp # Google Workspace MCP wrapper pinned to a Python 3.13 uv tool environment
        pulumi # Pulumi CLI engine; Python SDK is managed per-project via uv (Maghz infra Automation API)
      ]
      ++ dataRoster
      # nuget-mcp packages the osx-arm64 RID only; Linux gains a RID row before this gate widens.
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") [nuget-mcp];

    # DOTNET_ROOT required for Roslyn and other SDK-discovery tools.
    # Re-evaluated on every rebuild — store path stays current.
    sessionVariables.DOTNET_ROOT = "${dotnet-combined}/share/dotnet";
  };
}
