# Title         : mcp-launchers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mcp-launchers.nix
# ----------------------------------------------------------------------------
# MCP server launchers: one row per Home Manager-installed wrapper that resolves its upstream package at spawn (pnpm dlx for npm servers,
# uvx for Python servers) and execs the server under the client's stdio pipe. Client registration is client-owned — `claude mcp add`
# writes ~/.claude.json or the project .mcp.json, `codex mcp add` writes ~/.codex/config.toml or the project .codex/config.toml — and
# names the wrapper by its profile path. Launcher code never touches providers or credentials.
# Row fields: kind ("pnpm" | "uv" | "uv-git"), name (wrapper binary), pkg (npm/PyPI name, or GitHub owner/repo for uv-git), bin (package
# entrypoint), prelude? (shell run before exec), ensureArgs? (one-time pnpm setup verb), runtimePath? (pkgs attrs front-run onto PATH),
# platforms? (host-OS admission, default both).
{
  config,
  lib,
  pkgs,
  ...
}: let
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  hostOs =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "darwin"
    else "linux";
  rows = builtins.filter (r: builtins.elem hostOs (r.platforms or ["darwin" "linux"])) [
    {
      kind = "pnpm";
      name = "forge-hostinger-mcp";
      pkg = "hostinger-api-mcp";
      bin = "hostinger-api-mcp";
    }
    {
      # The ambient personal Doppler CLI token authenticates; every tool addresses project/config per call.
      kind = "pnpm";
      name = "forge-doppler-mcp";
      pkg = "@dopplerhq/mcp-server";
      bin = "doppler-mcp";
      prelude = ''
        export DOPPLER_TOKEN="''${DOPPLER_TOKEN:-$(${profileBin}/doppler configure get token --plain --scope /)}"
      '';
    }
    {
      # pnpm-fetched browser binaries never run on NixOS; a linux row lands with a store-built browser wiring.
      kind = "pnpm";
      name = "forge-playwright-mcp";
      pkg = "@playwright/mcp";
      bin = "playwright-mcp";
      ensureArgs = ["install-browser" "chromium"];
      platforms = ["darwin"];
    }
    {
      # Nix truth surface: nixpkgs packages plus NixOS/Home Manager/nix-darwin options from the live search index and upstream manuals.
      kind = "uv";
      name = "mcp-nixos";
      pkg = "mcp-nixos";
      bin = "mcp-nixos";
    }
    {
      # ast-grep's official MCP publishes no PyPI dist; runtimePath front-runs the estate ast-grep binary.
      kind = "uv-git";
      name = "forge-ast-grep-mcp";
      pkg = "ast-grep/ast-grep-mcp";
      bin = "ast-grep-server";
      runtimePath = ["ast-grep-upstream"];
    }
  ];
  mkPnpm = row: let
    dlx = ''
      pnpm \
        --config.loglevel=error \
        --config.prefer-online=true \
        --config.store-dir="''${XDG_DATA_HOME:-$HOME/.local/share}/pnpm/store" \
        --config.cache-dir="''${XDG_CACHE_HOME:-$HOME/.cache}/pnpm" \
        --config.state-dir="''${XDG_STATE_HOME:-$HOME/.local/state}/pnpm" \
        dlx --package=${lib.escapeShellArg "${row.pkg}@latest"} ${lib.escapeShellArg row.bin}'';
  in
    pkgs.writeShellApplication {
      inherit (row) name;
      runtimeInputs = [pkgs.nodejs-bin_26 pkgs.pnpm_11];
      text = ''
        ${row.prelude or ""}${lib.optionalString (row ? ensureArgs) "${dlx} ${lib.escapeShellArgs row.ensureArgs} >&2\n"}exec ${dlx} "$@"
      '';
    };
  # uvx owns Python tool isolation and cache reuse. `@latest` resolves PyPI currency; `--refresh` also advances git-backed tools from HEAD.
  mkUv = row:
    pkgs.writeShellScriptBin row.name ''
      set -euo pipefail
      export UV_CACHE_DIR="${config.xdg.cacheHome}/uv"
      export UV_PYTHON_DOWNLOADS=never
      export PATH="${pkgs.git}/bin:$PATH"
      ${lib.concatMapStringsSep "\n" (attr: ''export PATH="${pkgs.${attr}}/bin:$PATH"'') (row.runtimePath or [])}
      exec ${pkgs.uv}/bin/uvx --refresh --python "${pkgs.python313}/bin/python3" --from ${
        lib.escapeShellArg (
          if row.kind == "uv-git"
          then "git+https://github.com/${row.pkg}"
          else "${row.pkg}@latest"
        )
      } ${lib.escapeShellArg row.bin} "$@"
    '';
  mkLauncher = row:
    if row.kind == "pnpm"
    then mkPnpm row
    else mkUv row;
in {
  config.home.packages = map mkLauncher rows;
}
