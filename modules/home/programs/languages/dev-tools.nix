# Title         : dev-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/dev-tools.nix
# ----------------------------------------------------------------------------
# Language-agnostic tooling: linters, formatters, and helpers shared across multiple ecosystems.
{
  config,
  pkgs,
  ...
}: let
  style = import ../../../style.nix;
in {
  home = {
    file = {
      # Machine editor law from the style vocabulary: nearest-first resolution means any repo-local .editorconfig fully outranks this fallback.
      ".editorconfig".text = style.editorconfig;
      # Codex CLI ships inside ChatGPT.app and updates with it; the bundle's launcher follows this link back to its CodexCLI.app.
      ".local/bin/codex".source = config.lib.file.mkOutOfStoreSymlink "/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex";
    };

    packages = with pkgs; [
      # --- [SHELL_TOOLING]
      bash # Bash 5.3+ runtime for generated scripts and explicit bash sessions
      shellcheck # POSIX shell static analysis
      shfmt # Shell formatter
      bash-language-server # Bash LSP (navigation + diagnostics via shellcheck/shfmt)

      # --- [YAML]
      yaml-language-server # YAML LSP (SchemaStore-backed validation + completion)

      # --- [GENERAL_DATA_TOOLS]
      miller # CSV/TSV/JSON processor (mlr)
      qsv # High-performance CSV and tabular data toolkit
      typos # Fast source and docs typo checker

      # --- [NET]
      # No SDK and no .NET tool lands here: each repo's mise install owns the SDK its global.json pins, and a repo runs its tools through
      # `dotnet dnx <id>`. The editor's C# server is the one machine-wide .NET consumer: the nixpkgs package hosts the server DLL on its own
      # store runtime (useDotnetFromEnv wrapper over dotnetCorePackages.sdk_10_0.runtime), and project loading finds the SDK through `dotnet`
      # on PATH — the mise shim, first PATH segment.
      roslyn-ls # C# LSP: Microsoft.CodeAnalysis.LanguageServer; the server rows in apps/nvim pass --stdio, --autoLoadProjects, and the log directory

      # --- [CLOUD_IAC]
      google-cloud-sdk # Google Cloud CLI for OAuth/API bootstrap and project administration
      gws # Google Workspace CLI for scripted and batch Workspace administration
    ];
  };
}
