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
  # Data-lane admissions from the package manifest (CSV -> xan; relational/Parquet -> DuckDB).
  dataRoster = map (row: pkgs.${row.attr}) (manifest.rosterRows "data");
  antigravity-cli-bin-dir = "${config.home.homeDirectory}/.local/bin";
  # First-install only: the vendor installer exits on a present binary, and agy self-updates in the background during its own runs.
  install-antigravity-cli = pkgs.writeShellApplication {
    name = "install-antigravity-cli";
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
      [ -x "$binary" ] && exit 0
      mkdir -p "$target_dir"
      export PATH="$target_dir:$PATH"

      tmp="$(mktemp -d)"
      trap 'rm -rf "$tmp"' EXIT
      curl -fsSL https://antigravity.google/cli/install.sh -o "$tmp/install.sh"
      ${pkgs.bash}/bin/bash "$tmp/install.sh" --dir "$target_dir"
      test -x "$binary"
    '';
  };
in {
  # Machine-level fallback style for the shell tools; each resolves a project config ahead of these rows, so project law always wins.
  xdg.configFile = {
    # shellcheck resolves rc files from the script's directory upward, then ~/.shellcheckrc, then this file; a project rc fully shadows it. Keep
    # ~/.shellcheckrc absent — it would shadow this row.
    "shellcheckrc".text = ''
      external-sources=true
      enable=deprecate-which
    '';
  };

  # Machine editor law from the style vocabulary: nearest-first resolution means any repo-local .editorconfig fully outranks this fallback.
  home.file.".editorconfig".text = style.editorconfig;

  home = {
    activation = {
      ensureAntigravityCli = lib.hm.dag.entryAfter ["linkGeneration"] ''
        ${install-antigravity-cli}/bin/install-antigravity-cli
      '';
    };

    packages = with pkgs;
      [
        # --- [SHELL_TOOLING]
        bash # Bash 5.3+ runtime for generated scripts and explicit bash sessions
        shellcheck # POSIX shell static analysis
        shfmt # Shell formatter (let-bound house-style fallback wrapper)
        bash-language-server # Bash LSP (navigation + diagnostics via shellcheck/shfmt)

        # --- [YAML_TOML]
        yaml-language-server # YAML LSP (SchemaStore-backed validation + completion)
        taplo # TOML validator and LSP (SchemaStore-backed validation + completion)

        # --- [GENERAL_DATA_TOOLS]
        miller # CSV/TSV/JSON processor (mlr)
        qsv # High-performance CSV and tabular data toolkit
        typos # Fast source and docs typo checker

        # --- [NET]
        # No SDK and no .NET tool lands here: each repo's mise install owns the SDK its global.json pins, and a repo runs its tools through
        # `dotnet dnx <id>`. The editor's C# server is the one machine-wide .NET consumer: the nixpkgs package hosts the server DLL on its own
        # store runtime (useDotnetFromEnv wrapper over dotnetCorePackages.sdk_10_0.runtime), and project loading finds the SDK through `dotnet`
        # on PATH — the mise shim, last PATH segment.
        roslyn-ls # C# LSP: Microsoft.CodeAnalysis.LanguageServer; the server rows in apps/nvim pass --stdio, --autoLoadProjects, and the log directory

        # --- [JAVA]
        # No JDK lands here: each repo's mise install owns the JDK its project runtime row names (java.configuration.runtimes). The server runs on
        # its own store JDK and takes source roots, referenced jars, and the project JDK from the settings its client sends (apps/nvim rows).
        jdt-language-server # Java LSP: Eclipse JDT LS; the upstream `jdtls` launcher keys the workspace data dir by the cwd basename under ~/Library/Caches/jdtls

        # --- [CLOUD_IAC]
        google-cloud-sdk # Google Cloud CLI for OAuth/API bootstrap and project administration
        gws # Google Workspace CLI for scripted and batch Workspace administration
      ]
      ++ dataRoster;
  };
}
