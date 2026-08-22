# Title         : mcp-fleet.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mcp-fleet.nix
# ----------------------------------------------------------------------------
# Declarative MCP fleet manifest: one row is the whole definition of a fleet member. mcp-launchers.nix builds wrappers from `launcher` rows;
# `forge-mcp doctor` asserts every declared wrapper resolves on PATH; `forge-mcp drift` validates both client registrations against rows,
# reconciles only the owned MCP maps into the user/tool-owned client files, and reports drift without touching unrelated client state.
# Row schema (env/header material is key NAMES only, never values):
#   name             registration key in both clients
#   transport        "stdio" | "http"
#   command/args     stdio spawn line (absolute command)
#   url/headerNames  http endpoint + Claude header-name set
#   envKeys          env key names the server consumes
#   claudeEnvNames   Claude env-block name set when it differs from envKeys
#   launcher         { kind, names, pkg, bin, prelude?, ensureArgs?, source?, runtimePath?, constraints? }
#                    => Forge-built wrapper(s); kind selects the ecosystem runner — "pnpm", "uv", or "uv-git". Every spawn resolves the
#                    upstream release; source names a git repository for uv-git. runtimePath names pkgs attrs front-run onto the wrapper PATH;
#                    constraints are uv `--with` compatibility bounds for transitive dependencies whose upstream specification is incomplete
#   codex            { required, startupTimeoutSec, toolTimeoutSec, auth?, bearerEnvVar?, headerEnv?, toolsApprovalMode? }
#                    toolsApprovalMode projects codex `default_tools_approval_mode` — "approve" marks a pure information-retrieval server whose
#                    unannotated tools headless `codex exec` (approval: never) may call; write-capable servers never carry it (MCP runs unsandboxed)
#   clients          registration expectation, default [ "claude" "codex" ]
#   platforms        host-OS admission, default [ "darwin" "linux" ]; mcp-launchers.nix filters rows to the running host, so every launcher
#                    build, projection, and drift lane sees only spawnable rows
#   assertLevel      "full" (default) | "presence" for host-private rows
#   doctor           named companion checks: the Forge launcher name IS the row. Field: execs (companion binaries that must resolve on PATH)
{profileBin}: [
  {
    name = "hostinger";
    transport = "stdio";
    command = "${profileBin}/forge-hostinger-mcp";
    args = [];
    envKeys = ["HOSTINGER_API_TOKEN"];
    launcher = {
      kind = "pnpm";
      names = ["forge-hostinger-mcp"];
      pkg = "hostinger-api-mcp";
      bin = "hostinger-api-mcp";
    };
    codex = {
      required = false;
      startupTimeoutSec = 20;
      toolTimeoutSec = 60;
    };
  }
  {
    # One local lens over every Doppler scope: the ambient personal CLI token authenticates, every tool addresses project/config per call,
    # and --read-only filters the exposed toolset to GET endpoints — token scope remains the API-side boundary.
    name = "doppler";
    transport = "stdio";
    command = "${profileBin}/forge-doppler-mcp";
    args = ["--read-only"];
    envKeys = [];
    launcher = {
      kind = "pnpm";
      names = ["forge-doppler-mcp"];
      pkg = "@dopplerhq/mcp-server";
      bin = "doppler-mcp";
      prelude = ''
        export DOPPLER_TOKEN="''${DOPPLER_TOKEN:-$(${profileBin}/doppler configure get token --plain --scope /)}"
      '';
    };
    codex = {
      required = false;
      startupTimeoutSec = 30;
      toolTimeoutSec = 180;
    };
  }
  {
    name = "playwright";
    transport = "stdio";
    platforms = ["darwin"]; # pnpm-fetched browser binaries never run on NixOS; a linux row lands with a store-built browser wiring
    command = "${profileBin}/forge-playwright-mcp";
    # --browser chromium selects the MCP-managed browser build; the "chrome" channel delegates to the separately managed Google Chrome.app.
    args = ["--isolated" "--browser" "chromium" "--caps=vision,pdf"];
    envKeys = [];
    launcher = {
      kind = "pnpm";
      names = ["forge-playwright-mcp"];
      pkg = "@playwright/mcp";
      bin = "playwright-mcp";
      ensureArgs = ["install-browser" "chromium"];
    };
    codex = {
      required = false;
      startupTimeoutSec = 30;
      toolTimeoutSec = 180;
    };
  }
  {
    name = "google-workspace";
    transport = "stdio";
    command = "${profileBin}/forge-workspace-mcp";
    args = ["--tool-tier" "extended"];
    envKeys = ["GOOGLE_OAUTH_CLIENT_ID" "GOOGLE_OAUTH_CLIENT_SECRET" "WORKSPACE_MCP_CREDENTIALS_DIR"];
    launcher = {
      kind = "uv";
      names = ["forge-workspace-mcp"];
      pkg = "workspace-mcp";
      bin = "workspace-mcp";
    };
    codex = {
      required = false;
      startupTimeoutSec = 60;
      toolTimeoutSec = 180;
    };
  }
  {
    name = "nuget";
    transport = "stdio";
    command = "${profileBin}/nuget-mcp";
    args = [];
    envKeys = [];
    codex = {
      required = false;
      startupTimeoutSec = 60;
      toolTimeoutSec = 180;
    };
  }
  {
    # Nix truth surface: nixpkgs packages plus NixOS/Home Manager/nix-darwin options from the live search index and upstream manuals.
    name = "nixos";
    transport = "stdio";
    command = "${profileBin}/mcp-nixos";
    args = [];
    envKeys = [];
    launcher = {
      kind = "uv";
      names = ["mcp-nixos"];
      pkg = "mcp-nixos";
      bin = "mcp-nixos";
    };
    codex = {
      required = false;
      startupTimeoutSec = 30;
      toolTimeoutSec = 180;
      toolsApprovalMode = "approve";
    };
  }
  {
    # Structural code search: ast-grep's official MCP (dump_syntax_tree, test_match_code_rule, find_code, find_code_by_rule); pure retrieval, so
    # headless codex may call it. Upstream publishes no PyPI dist; runtimePath front-runs the estate ast-grep binary.
    name = "ast-grep";
    transport = "stdio";
    command = "${profileBin}/forge-ast-grep-mcp";
    args = [];
    envKeys = [];
    doctor = {
      execs = ["ast-grep"];
    };
    launcher = {
      kind = "uv-git";
      names = ["forge-ast-grep-mcp"];
      pkg = "sg-mcp";
      bin = "ast-grep-server";
      source = "ast-grep/ast-grep-mcp";
      runtimePath = ["ast-grep-upstream"];
      # MCP 2.x removed the mcp.server.fastmcp layer sg-mcp imports; upstream leaves the dependency unbounded, so a fresh resolve breaks at import.
      # Delete this bound when upstream absorbs MCP 2.x.
      constraints = ["mcp<2"];
    };
    codex = {
      required = false;
      startupTimeoutSec = 60;
      toolTimeoutSec = 180;
      toolsApprovalMode = "approve";
    };
  }
  {
    # The vendor router runs directly under the client's stdio pipe — it spawns a Rhino host on demand, adopts a user-started session through
    # its own slot lifecycle, and exits with client stdin EOF. mcp-launchers.nix builds the wrapper.
    name = "rhino-mcp-platform";
    transport = "stdio";
    platforms = ["darwin"];
    command = "${profileBin}/rhino-mcp-router";
    args = ["--default-version" "9"];
    envKeys = [];
    doctor = {
      execs = ["forge-rhino-up"];
    };
    codex = {
      required = false;
      startupTimeoutSec = 20;
      toolTimeoutSec = 180;
    };
  }
  {
    name = "github";
    transport = "http";
    url = "https://api.githubcopilot.com/mcp/";
    headerNames = ["Authorization"];
    envKeys = ["GH_PROJECTS_TOKEN"];
    codex = {
      required = true;
      startupTimeoutSec = 25;
      toolTimeoutSec = 180;
      bearerEnvVar = "GH_PROJECTS_TOKEN";
    };
  }
  {
    name = "exa";
    transport = "http";
    url = "https://mcp.exa.ai/mcp";
    headerNames = ["x-api-key"];
    envKeys = ["EXA_API_KEY"];
    codex = {
      required = false;
      startupTimeoutSec = 20;
      toolTimeoutSec = 180;
      headerEnv = {"x-api-key" = "EXA_API_KEY";};
    };
  }
  {
    name = "context7";
    transport = "http";
    url = "https://mcp.context7.com/mcp";
    headerNames = ["Authorization"];
    envKeys = ["CONTEXT7_API_KEY"];
    codex = {
      required = true;
      startupTimeoutSec = 20;
      toolTimeoutSec = 180;
      bearerEnvVar = "CONTEXT7_API_KEY";
    };
  }
  {
    name = "greptile";
    transport = "http";
    url = "https://api.greptile.com/mcp";
    headerNames = ["Authorization"];
    envKeys = ["GREPTILE_API_KEY"];
    codex = {
      required = false;
      startupTimeoutSec = 20;
      toolTimeoutSec = 180;
      bearerEnvVar = "GREPTILE_API_KEY";
    };
  }
  {
    name = "heptabase-mcp";
    transport = "http";
    url = "https://api.heptabase.com/mcp";
    headerNames = [];
    envKeys = [];
    codex = {
      auth = "oauth";
      required = false;
      startupTimeoutSec = 20;
      toolTimeoutSec = 180;
    };
  }
  {
    name = "openaiDeveloperDocs";
    transport = "http";
    url = "https://developers.openai.com/mcp";
    headerNames = [];
    envKeys = [];
    codex = {
      required = false;
      startupTimeoutSec = 20;
      toolTimeoutSec = 180;
    };
  }
  {
    name = "claudeCodeDocs";
    transport = "http";
    url = "https://code.claude.com/docs/mcp";
    headerNames = [];
    envKeys = [];
    codex = {
      required = false;
      startupTimeoutSec = 20;
      toolTimeoutSec = 180;
    };
  }
  {
    # ChatGPT.app-private Computer Use bridge: presence asserted, definition owned by the app/plugin projection.
    name = "computer-use";
    transport = "stdio";
    platforms = ["darwin"];
    command = "./Codex Computer Use.app/Contents/SharedSupport/SkyComputerUseClient.app/Contents/MacOS/SkyComputerUseClient";
    args = ["mcp"];
    envKeys = [];
    clients = ["codex"];
    assertLevel = "presence";
    codex = {
      required = false;
      startupTimeoutSec = 120;
      toolTimeoutSec = 180;
    };
  }
  {
    # ChatGPT.app-private REPL: presence asserted, definition owned by the app.
    name = "node_repl";
    transport = "stdio";
    platforms = ["darwin"];
    command = "/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node_repl";
    args = [];
    envKeys = [];
    clients = ["codex"];
    assertLevel = "presence";
    codex = {
      required = false;
      startupTimeoutSec = 120;
      toolTimeoutSec = 180;
    };
  }
]
