# Title         : tooling.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/tooling.nix
# ----------------------------------------------------------------------------
# Developer shell and formatting surfaces.
_: {
  perSystem = {
    config,
    forgePkgs,
    lib,
    ...
  }: let
    style = import ../modules/style.nix;
    # Repo law files are the single source: the biome row carries biome.json's bytes, its treefmt excludes are the same file's negation rows, and the
    # ruff row projects pyproject [tool.ruff] — a value changed in the law file busts the treefmt cache and lands in the row with zero edits here.
    biomeLaw = builtins.fromJSON (builtins.readFile ../biome.json);
    biomeExcludes = map (lib.removePrefix "!") (builtins.filter (lib.hasPrefix "!") biomeLaw.files.includes);
    ruffLaw = (fromTOML (builtins.readFile ../pyproject.toml)).tool.ruff;
    # SQL dialect is a per-file fact; each row binds its files to a generated config projected from the style vocabulary. sqruff discovery is
    # cwd-only, so the explicit --config keeps rows hermetic inside the sandboxed check.
    sqruffRow = dialect: includes: {
      command = "${forgePkgs.sqruff}/bin/sqruff";
      options = [
        "--config"
        (toString (forgePkgs.writeText "sqruff-${dialect}" (style.sql "sqruff" dialect)))
        "fix"
      ];
      inherit includes;
    };
  in {
    # Repository-maintenance shell: formatter plus flake proof/update helpers. Machine tooling (git, shellcheck, shfmt, LSPs) is Home Manager-owned.
    devShells.default = forgePkgs.mkShell {
      packages = [
        config.formatter
        forgePkgs.deadnix
        forgePkgs.statix
        forgePkgs.nix-fast-build
        forgePkgs.nix-init
        forgePkgs.nix-output-monitor
        forgePkgs.nix-update
        forgePkgs.nixpkgs-review
        forgePkgs.nurl
      ];
    };

    formatter = forgePkgs.writeShellApplication {
      name = "forge-fmt";
      runtimeInputs = [config.treefmt.build.wrapper];
      text = ''
        args=()
        for arg in "$@"; do
          if [[ "$arg" == "--check" ]]; then
            args+=("--ci")
          else
            args+=("$arg")
          fi
        done
        exec treefmt "''${args[@]}"
      '';
    };

    treefmt = {
      flakeCheck = false;
      projectRootFile = "flake.nix";
      # Rows carry the house style (4-space indent, 150 width) explicitly: the sandboxed formatting check cannot see machine-level XDG tool configs.
      programs = {
        alejandra.enable = true;
        # The repo-root biome.json is the single law for treefmt, the PATH wrapper, and the VSCode extension. The row must carry its bytes:
        # treefmt-nix always pins --config-path, which disables biome's own root discovery, and an out-of-row config never busts the cache.
        biome = {
          enable = true;
          formatCommand = "format";
          settings = biomeLaw;
        };
      };
      settings.formatter = {
        # biome.json's negation rows verbatim, so treefmt never offers biome the paths its own config ignores (an all-ignored batch is a biome error, not a no-op).
        biome.excludes = biomeExcludes;
        # --isolated makes the row hermetic: identical bytes with or without the machine-level XDG ruff config the sandboxed check cannot see.
        ruff-format = {
          command = "${forgePkgs.ruff}/bin/ruff";
          options = [
            "format"
            "--isolated"
            "--line-length"
            (toString ruffLaw.line-length)
            "--target-version"
            ruffLaw.target-version
            "--config"
            "preview = ${lib.boolToString ruffLaw.preview}"
            "--config"
            "format.skip-magic-trailing-comma = ${lib.boolToString ruffLaw.format.skip-magic-trailing-comma}"
            "--config"
            ''format.line-ending = "${ruffLaw.format.line-ending}"''
            "--config"
            "format.docstring-code-format = ${lib.boolToString ruffLaw.format.docstring-code-format}"
          ];
          includes = ["*.py" "*.pyi"];
        };
        # The style vocabulary is the single law; its bytes ride the row so the sandboxed check needs no XDG config and the treefmt cache busts
        # whenever the law changes. pnpm owns its lockfile pair and rewrites both in its own layout.
        yamlfmt = {
          command = "${forgePkgs.yamlfmt}/bin/yamlfmt";
          options = ["-conf" (toString (forgePkgs.writeText "yamlfmt-conf" style.yamlfmt))];
          includes = ["*.yaml" "*.yml"];
          excludes = ["pnpm-workspace.yaml" "pnpm-lock.yaml"];
        };
        shfmt = {
          command = "${forgePkgs.shfmt}/bin/shfmt";
          options = ["-w" "-i" (toString style.indent) "-ci"];
          includes = ["*.sh"];
        };
        # Leading * crosses directories in treefmt globs; a bare `duckdb-*.sql` anchors at the tree root and matches nothing nested. No sqlite
        # row: sqruff's sqlite dialect rewrites virtual-table module arguments (float[2] -> float [2]), which extensions parse verbatim, so
        # sqlite SQL stays formatter-unowned until that dialect matures, and fmt's sql classification skips the same basenames.
        sqruff-postgres = sqruffRow "postgres" ["*postgres*.sql"];
        sqruff-duckdb = sqruffRow "duckdb" ["*duckdb-*.sql"];
        # Workflow-DSL scripts ride prettier's babel parser (biome's grammar rejects top-level await/return); config bytes from the style owner.
        prettier-workflow = {
          command = "${forgePkgs.prettier}/bin/prettier";
          options = [
            "--log-level"
            "warn"
            "--config"
            (toString (forgePkgs.writeText "prettierrc.json" (builtins.toJSON style.prettierrc)))
            "--write"
          ];
          includes = style.workflowScriptGlobs;
        };
        # stylua discovery is cwd/upward only; the row carries the house style so the sandboxed check needs no repo-root config file.
        stylua = {
          command = "${forgePkgs.stylua}/bin/stylua";
          options = ["--indent-type" "Spaces" "--indent-width" (toString style.indent) "--column-width" (toString style.width)];
          includes = ["*.lua"];
        };
      };
    };
  };
}
