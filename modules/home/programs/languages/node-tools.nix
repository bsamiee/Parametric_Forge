# Title         : node-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/node-tools.nix
# ----------------------------------------------------------------------------
# Node-hosted machine tools: prettier and mermaid-cli. The Node runtime, pnpm, and the TypeScript compiler are rows of each project's mise.toml
# and package.json, never a machine package.
{
  config,
  pkgs,
  ...
}: let
  style = import ../../../style.nix;
  # prettier has no user-level config discovery, so the wrapper injects the house style only when upward discovery finds no project config
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
in {
  home.packages = [
    prettier # Code formatter (house-config fallback wrapper)
    pkgs.mermaid-cli # Mermaid CLI (mmdc) on PATH; Chromium pinned via PUPPETEER_EXECUTABLE_PATH
  ];

  xdg.configFile."prettier/prettierrc.json".text = builtins.toJSON style.prettierrc;
}
