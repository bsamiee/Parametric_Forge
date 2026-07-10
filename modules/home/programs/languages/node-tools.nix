# Title         : node-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/node-tools.nix
# ----------------------------------------------------------------------------
# Node.js runtime and package tooling.
{
  config,
  pkgs,
  ...
}: let
  # Neither tool has user-level config discovery, so each wrapper injects the
  # house style only when upward discovery finds no project config and the
  # caller passes none — project law always wins.
  prettierConfig = "${config.xdg.configHome}/prettier/prettierrc.json";
  prettier = pkgs.writeShellApplication {
    name = "prettier";
    text = ''
      target=""
      for arg in "$@"; do
        case "$arg" in
          --config | --config=* | --no-config | --find-config-path) exec ${pkgs.prettier}/bin/prettier "$@" ;;
          -*) ;;
          *) [[ -n "$target" ]] || target="$arg" ;;
        esac
      done
      if [[ -n "$target" ]] && ! ${pkgs.prettier}/bin/prettier --find-config-path "$target" >/dev/null 2>&1; then
        exec ${pkgs.prettier}/bin/prettier --config "${prettierConfig}" "$@"
      fi
      exec ${pkgs.prettier}/bin/prettier "$@"
    '';
  };
  biomeConfigDir = "${config.xdg.configHome}/biome";
  biome = pkgs.writeShellApplication {
    name = "biome";
    text = ''
      # BIOME_CONFIG_PATH is the env twin of the global --config-path option and
      # disables discovery outright; either spelling is explicit caller config,
      # so both pass through before discovery can shadow or be shadowed.
      [[ -n "''${BIOME_CONFIG_PATH:-}" ]] && exec ${pkgs.biome}/bin/biome "$@"
      for arg in "$@"; do
        case "$arg" in
          --config-path | --config-path=*) exec ${pkgs.biome}/bin/biome "$@" ;;
        esac
      done
      dir="$PWD"
      while [[ -n "$dir" ]]; do
        for name in biome.json biome.jsonc .biome.json .biome.jsonc; do
          if [[ -f "$dir/$name" ]]; then
            exec ${pkgs.biome}/bin/biome "$@"
          fi
        done
        dir="''${dir%/*}"
      done
      BIOME_CONFIG_PATH="${biomeConfigDir}" exec ${pkgs.biome}/bin/biome "$@"
    '';
  };
in {
  home.packages = [
    pkgs.nodejs-bin_26 # Official Node 26 Darwin binary, npm/npx/corepack stripped in-overlay
    pkgs.pnpm_11 # Sole package-manager verb on PATH; major-pinned for store-format stability
    prettier # Code formatter (house-config fallback wrapper)
    biome # TS/JS/JSON/CSS formatter+linter (house-config fallback wrapper)
    pkgs.tailwindcss # Utility-first CSS framework
    pkgs.typescript-go # TypeScript 7 (`typescript@7` upstream identity); nixpkgs still ships the dev snapshot as `tsgo` — a package-drift row until stable TS7 packaging lands
    pkgs.dts-lsp # TypeScript declaration navigation for API catalogue work
    pkgs.mermaid-cli # Mermaid CLI (mmdc) on PATH; Chromium pinned via PUPPETEER_EXECUTABLE_PATH in languages.nix
  ];

  xdg.configFile = {
    "prettier/prettierrc.json".text = builtins.toJSON {
      tabWidth = 4;
      printWidth = 150;
    };
    # Full Rasm-grade house law: formatter + JS style + organize-imports
    # assist, so config-less directories get the same quality as project law.
    "biome/biome.json".text = builtins.toJSON {
      files.ignoreUnknown = true;
      formatter = {
        enabled = true;
        indentStyle = "space";
        indentWidth = 4;
        lineWidth = 150;
      };
      javascript.formatter = {
        quoteStyle = "single";
        semicolons = "always";
        trailingCommas = "all";
      };
      assist = {
        enabled = true;
        actions.source.organizeImports = "on";
      };
    };
  };
}
