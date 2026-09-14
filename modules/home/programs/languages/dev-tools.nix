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
  antigravity-cli-bin-dir = "${config.home.homeDirectory}/.local/bin";
  # First-install only: the vendor installer exits on a present binary, and agy self-updates in the background during its own runs.
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

        # --- [GENERAL_DATA_TOOLS]
        yq-go # YAML/JSON/TOML processor (yq)
        miller # CSV/TSV/JSON processor (mlr)
        qsv # High-performance CSV and tabular data toolkit
        typos # Fast source and docs typo checker

        # --- [NET]
        # No SDK and no .NET tool lands here: each repo's mise install owns the SDK its global.json pins, and a repo runs its tools through
        # `dotnet dnx <id>`. The editor's C# server is the one machine-wide .NET consumer: the nixpkgs package hosts the server DLL on its own
        # store runtime (useDotnetFromEnv wrapper over dotnetCorePackages.sdk_10_0.runtime), and project loading finds the SDK through `dotnet`
        # on PATH — the mise shim, last PATH segment.
        roslyn-ls # C# LSP: Microsoft.CodeAnalysis.LanguageServer; the server rows in apps/nvim pass --stdio, --autoLoadProjects, and the log directory

        # --- [CLOUD_IAC]
        google-cloud-sdk # Google Cloud CLI for OAuth/API bootstrap and project administration
        gws # Google Workspace CLI for scripted and batch Workspace administration
        pulumi # Pulumi CLI engine; Python SDK is managed per-project via uv
      ]
      ++ dataRoster;
  };
}
