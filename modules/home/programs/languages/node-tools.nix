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
  style = import ../../../style.nix;
  # Neither tool has user-level config discovery, so each wrapper injects the house style only when upward discovery finds no project config
  # and the caller passes none — project law always wins.
  prettierConfig = "${config.xdg.configHome}/prettier/prettierrc.json";
  # Prettier resolves config from each file's directory upward, so the probe rides --find-config-path on the last positional: option values precede
  # trailing file lists, so the last positional is a real target, never a value like the `warn` in `--log-level warn`.
  prettier = pkgs.writeShellApplication {
    name = "prettier";
    text = ''
      target=""
      for arg in "$@"; do
        case "$arg" in
          --config | --config=* | --no-config | --find-config-path) exec ${pkgs.prettier}/bin/prettier "$@" ;;
          -*) ;;
          *) target="$arg" ;;
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
      ${style.walkUp}
      # BIOME_CONFIG_PATH is the env twin of the global --config-path option and disables discovery outright; either spelling is explicit caller
      # config, so both pass through before discovery can shadow or be shadowed.
      [[ -n "''${BIOME_CONFIG_PATH:-}" ]] && exec ${pkgs.biome}/bin/biome "$@"
      for arg in "$@"; do
        case "$arg" in
          --config-path | --config-path=*) exec ${pkgs.biome}/bin/biome "$@" ;;
        esac
      done
      _walk_up biome.json biome.jsonc .biome.json .biome.jsonc >/dev/null \
        && exec ${pkgs.biome}/bin/biome "$@"
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
    pkgs.mermaid-cli # Mermaid CLI (mmdc) on PATH; Chromium pinned via PUPPETEER_EXECUTABLE_PATH
  ];

  xdg.configFile = {
    "prettier/prettierrc.json".text = builtins.toJSON style.prettierrc;
    # Full house law: formatter + JS style + organize-imports assist, so config-less directories get the same quality as project law.
    # Transient trees stay excluded even when passed explicitly (!! rows); workflow scripts are a top-level-await/return DSL no JS parser mode
    # accepts, so they stay grammar-excluded, never policy-excluded.
    "biome/biome.json".text = builtins.toJSON {
      files = {
        ignoreUnknown = true;
        includes =
          ["**"]
          ++ map (d: "!!**/${d}") style.transientDirs
          ++ ["!!**/.claude/workflows/**" "!!**/workflow-creator/assets/**"];
      };
      formatter = {
        enabled = true;
        indentStyle = "space";
        indentWidth = style.indent;
        lineWidth = style.width;
      };
      javascript.formatter = {
        quoteStyle = "single";
        semicolons = "always";
        trailingCommas = "all";
      };
      json.parser.allowComments = true;
      assist = {
        enabled = true;
        actions.source.organizeImports = "on";
      };
    };
  };
}
