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
    ...
  }: let
    # SQL dialect is a per-file fact; each row binds its files to a generated
    # config carrying the house style. sqruff discovery is cwd-only, so the
    # explicit --config keeps rows hermetic inside the sandboxed check.
    sqruffRow = dialect: includes: {
      command = "${forgePkgs.sqruff}/bin/sqruff";
      options = [
        "--config"
        (toString (forgePkgs.writeText "sqruff-${dialect}" ''
          [sqruff]
          dialect = ${dialect}
          max_line_length = 150

          [sqruff:indentation]
          tab_space_size = 4
        ''))
        "fix"
      ];
      inherit includes;
    };
  in {
    # Repository-maintenance shell: formatter plus flake proof/update helpers.
    # Machine tooling (git, shellcheck, shfmt, LSPs) is Home Manager-owned.
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
      # Rows carry the house style (4-space indent, 150 width) explicitly:
      # the formatting flake check runs sandboxed, where the machine-level
      # XDG tool configs are invisible.
      programs = {
        alejandra.enable = true;
        # The repo-root biome.json is the single law for treefmt, the PATH
        # wrapper, and the VSCode extension. The row must carry its bytes:
        # treefmt-nix always pins --config-path, which disables biome's own
        # root discovery, and an out-of-row config never busts the cache.
        biome = {
          enable = true;
          formatCommand = "format";
          settings = builtins.fromJSON (builtins.readFile ../biome.json);
        };
      };
      settings.formatter = {
        # Workflow scripts carry top-level return/await forms the Workflow
        # runtime accepts but JS module parsers reject; the harness rewrites
        # settings JSON in its own layout on every permission mutation.
        biome.excludes = [
          ".claude/workflows/**"
          ".claude/skills/workflow-creator/assets/**"
          ".claude/settings.json"
          ".claude/settings.local.json"
        ];
        # --isolated makes the row hermetic: identical bytes with or without
        # the machine-level XDG ruff config the sandboxed check cannot see.
        ruff-format = {
          command = "${forgePkgs.ruff}/bin/ruff";
          options = [
            "format"
            "--isolated"
            "--line-length"
            "150"
            "--target-version"
            "py315"
            "--config"
            "preview = true"
            "--config"
            "format.skip-magic-trailing-comma = true"
            "--config"
            ''format.line-ending = "lf"''
            "--config"
            "format.docstring-code-format = true"
          ];
          includes = ["*.py" "*.pyi"];
        };
        # The style vocabulary (modules/style.nix) is the single law; its
        # bytes ride the row so the sandboxed check needs no XDG config and
        # the treefmt cache busts whenever the law changes. pnpm owns its
        # lockfile pair and rewrites both in its own layout.
        yamlfmt = {
          command = "${forgePkgs.yamlfmt}/bin/yamlfmt";
          options = ["-conf" (toString (forgePkgs.writeText "yamlfmt-conf" (import ../modules/style.nix).yamlfmt))];
          includes = ["*.yaml" "*.yml"];
          excludes = ["pnpm-workspace.yaml" "pnpm-lock.yaml"];
        };
        shfmt = {
          command = "${forgePkgs.shfmt}/bin/shfmt";
          options = ["-w" "-i" "4" "-ci"];
          includes = ["*.sh"];
        };
        sqruff-postgres = sqruffRow "postgres" ["*postgres*.sql"];
        sqruff-duckdb = sqruffRow "duckdb" ["duckdb-*.sql"];
        sqruff-sqlite = sqruffRow "sqlite" ["sqlite-*.sql"];
        # stylua discovery is cwd/upward only; the row carries the house style
        # so the sandboxed check needs no repo-root config file.
        stylua = {
          command = "${forgePkgs.stylua}/bin/stylua";
          options = ["--indent-type" "Spaces" "--indent-width" "4" "--column-width" "150"];
          includes = ["*.lua"];
        };
      };
    };
  };
}
