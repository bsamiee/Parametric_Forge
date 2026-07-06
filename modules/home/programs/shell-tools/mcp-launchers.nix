# Title         : mcp-launchers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/mcp-launchers.nix
# ----------------------------------------------------------------------------
# Pinned npm MCP launchers: one row per server, installed once into an
# XDG-cache prefix keyed by version, exec'd locally on every later spawn — no
# per-spawn npm registry resolution. Bump a row's version to roll its server;
# `forge-mcp-outdated` reports pinned-vs-latest drift; npm output routes to
# stderr so the MCP stdio channel stays clean.
{pkgs, ...}: let
  rows = [
    {
      name = "forge-perplexity-mcp";
      pkg = "@perplexity-ai/mcp-server";
      version = "0.9.0";
      bin = "perplexity-mcp";
      prelude = "";
    }
    {
      name = "forge-tavily-mcp";
      pkg = "tavily-mcp";
      version = "0.2.20";
      bin = "tavily-mcp";
      prelude = "";
    }
    {
      name = "forge-hostinger-mcp";
      pkg = "hostinger-api-mcp";
      version = "1.2.1";
      bin = "hostinger-api-mcp";
      prelude = "";
    }
    {
      # Bare-binary name held stable: the Maghz MCP fleet spells `notebooklm-mcp`.
      name = "notebooklm-mcp";
      pkg = "notebooklm-mcp";
      version = "2.0.0";
      bin = "notebooklm-mcp";
      prelude = ''
        export NOTEBOOKLM_AI_MARKER="''${NOTEBOOKLM_AI_MARKER:-false}"
        export SESSION_TIMEOUT="''${SESSION_TIMEOUT:-3600}"
      '';
    }
  ];
  launcher = row:
    pkgs.writeShellApplication {
      inherit (row) name;
      runtimeInputs = [pkgs.nodejs];
      text = ''
        ${row.prelude}prefix="''${XDG_CACHE_HOME:-$HOME/.cache}/forge-mcp/${row.pkg}/${row.version}"
        entry="$prefix/node_modules/.bin/${row.bin}"
        if [ ! -x "$entry" ]; then
          mkdir -p "$prefix"
          npm install --prefix "$prefix" --no-audit --no-fund --loglevel=error "${row.pkg}@${row.version}" >&2
        fi
        exec "$entry" "$@"
      '';
    };
  # Rhino's package manager owns the router install; version-globbing keeps
  # client configs stable across McNeel package updates.
  rhinoRouter = pkgs.writeShellApplication {
    name = "rhino-mcp-router";
    text = ''
      base="$HOME/Library/Application Support/McNeel/Rhinoceros/packages/9.0/Rhino-MCP-Platform"
      entry="$(printf '%s\n' "$base"/*/router/osx-arm64/rhino-mcp-router | sort -V | tail -1)"
      exec "$entry" "$@"
    '';
  };
  pins = builtins.concatStringsSep "\n" (map (r: "${r.pkg}|${r.version}") rows);
  outdated = pkgs.writeShellApplication {
    name = "forge-mcp-outdated";
    runtimeInputs = [pkgs.curl pkgs.jq];
    text = ''
      rc=0
      while IFS="|" read -r pkg version; do
        latest="$(curl -fsS "https://registry.npmjs.org/$(jq -rn --arg p "$pkg" '$p|@uri')/latest" | jq -r .version)"
        if [ "$latest" != "$version" ]; then
          echo "OUTDATED $pkg pinned=$version latest=$latest"
          rc=1
        else
          echo "current  $pkg $version"
        fi
      done < <(printf '%s\n' '${pins}')
      exit "$rc"
    '';
  };
  # Weekly drift banner: Notification Center only when a pin is outdated;
  # silent when current or offline (a registry/network failure never notifies).
  outdatedNotify = pkgs.writeShellApplication {
    name = "forge-mcp-outdated-notify";
    runtimeInputs = [outdated];
    text = ''
      out="$(forge-mcp-outdated 2>&1)" && exit 0
      n="$(printf '%s\n' "$out" | grep -c '^OUTDATED' || true)"
      [ "$n" -gt 0 ] || exit 0
      /usr/bin/osascript -e "display notification \"$n MCP pin(s) behind npm latest - run forge-mcp-outdated\" with title \"Forge MCP pins\""
    '';
  };
in {
  home.packages = map launcher rows ++ [rhinoRouter outdated outdatedNotify];
  launchd.agents.forge-mcp-outdated = {
    enable = true;
    config = {
      ProgramArguments = ["${outdatedNotify}/bin/forge-mcp-outdated-notify"];
      StartCalendarInterval = [
        {
          Weekday = 1;
          Hour = 10;
          Minute = 0;
        }
      ];
      StandardOutPath = "/Users/bardiasamiee/Library/Logs/forge-mcp-outdated.log";
      StandardErrorPath = "/Users/bardiasamiee/Library/Logs/forge-mcp-outdated.log";
    };
  };
}
