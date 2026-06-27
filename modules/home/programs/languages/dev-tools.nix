# Title         : dev-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/dev-tools.nix
# ----------------------------------------------------------------------------
# Language-agnostic tooling: linters, formatters, and helpers shared across
# multiple ecosystems.
{
  lib,
  pkgs,
  ...
}: let
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
in {
  home.packages = with pkgs; [
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
    nuget-mcp

    # --- Cloud / IaC --------------------------------------------------------
    pulumi # Pulumi CLI engine; Python SDK is managed per-project via uv (Maghz infra Automation API)
  ];

  # DOTNET_ROOT required for Roslyn and other SDK-discovery tools.
  # Re-evaluated on every rebuild — store path stays current.
  home.sessionVariables.DOTNET_ROOT = "${dotnet-combined}/share/dotnet";
}
