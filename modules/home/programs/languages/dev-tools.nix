# Title         : dev-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/dev-tools.nix
# ----------------------------------------------------------------------------
# Language-agnostic tooling: linters, formatters, and helpers shared across
# multiple ecosystems.
{pkgs, ...}: let
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
    hurl # HTTP request/assertion runner for API probes
    grpcurl # gRPC server reflection and request CLI
    typos # Fast source and docs typo checker

    # --- .NET ---------------------------------------------------------------
    dotnet-combined
    ilspycmd # .NET assembly decompiler for NuGet API catalogues
    nuget-to-json # NuGet package metadata extraction
    roslyn-language-server # C# LSP (roslyn-ls wrapped for clean --stdio)
  ];

  # DOTNET_ROOT required for omnisharp and other SDK-discovery tools.
  # Re-evaluated on every rebuild — store path stays current.
  home.sessionVariables.DOTNET_ROOT = "${dotnet-combined}";
}
