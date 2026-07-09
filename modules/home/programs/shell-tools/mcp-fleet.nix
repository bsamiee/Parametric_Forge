# Title         : mcp-fleet.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/mcp-fleet.nix
# ----------------------------------------------------------------------------
# Declarative MCP fleet manifest: one row is the whole definition of a fleet
# member. mcp-launchers.nix builds wrappers from `launcher` rows; `forge-mcp
# doctor` probes rows by `probe` class under `codex.startupTimeoutSec`;
# `forge-mcp drift` validates both client registrations against rows and only
# reports — ~/.claude.json and ~/.codex/config.toml stay user/tool-owned.
# Row schema (env/header material is key NAMES only, never values):
#   name             registration key in both clients
#   transport        "stdio" | "http"
#   command/args     stdio spawn line (absolute command)
#   url/headerNames  http endpoint + Claude header-name set
#   envKeys          env key names the server consumes
#   claudeEnvNames   Claude env-block name set when it differs from envKeys
#   probe            "stdio" (probed) | "network" (probed only with --network) | "skip"
#   launcher         { names, pkg, version, bin, prelude? } => Forge-built pnpm wrapper(s)
#   codex            { required, startupTimeoutSec, toolTimeoutSec, bearerEnvVar?, headerEnv? }
#   clients          registration expectation, default [ "claude" "codex" ]
#   assertLevel      "full" (default) | "presence" for host-private rows
{
  profileBin,
  homeDir,
}: [
  {
    name = "perplexity";
    transport = "stdio";
    command = "${profileBin}/forge-perplexity-mcp";
    args = [];
    envKeys = ["PERPLEXITY_API_KEY"];
    probe = "stdio";
    launcher = {
      names = ["forge-perplexity-mcp"];
      pkg = "@perplexity-ai/mcp-server";
      version = "0.9.0";
      bin = "perplexity-mcp";
    };
    codex = {
      required = false;
      startupTimeoutSec = 20;
      toolTimeoutSec = 180;
    };
  }
  {
    name = "tavily";
    transport = "stdio";
    command = "${profileBin}/forge-tavily-mcp";
    args = [];
    envKeys = ["TAVILY_API_KEY"];
    probe = "stdio";
    launcher = {
      names = ["forge-tavily-mcp"];
      pkg = "tavily-mcp";
      version = "0.2.20";
      bin = "tavily-mcp";
    };
    codex = {
      required = false;
      startupTimeoutSec = 20;
      toolTimeoutSec = 180;
    };
  }
  {
    name = "hostinger";
    transport = "stdio";
    command = "${profileBin}/forge-hostinger-mcp";
    args = [];
    envKeys = ["HOSTINGER_API_TOKEN"];
    probe = "stdio";
    launcher = {
      names = ["forge-hostinger-mcp"];
      pkg = "hostinger-api-mcp";
      version = "1.5.1";
      bin = "hostinger-api-mcp";
    };
    codex = {
      required = false;
      startupTimeoutSec = 20;
      toolTimeoutSec = 60;
    };
  }
  {
    # Registration is the doppler-run indirection: agent-runtime/dev injects
    # DOPPLER_MCP_AGENT_TOKEN, so no ambient env key is consumed.
    name = "doppler";
    transport = "stdio";
    command = "${profileBin}/doppler";
    args = [
      "run"
      "--project"
      "agent-runtime"
      "--config"
      "dev"
      "--fallback"
      "${homeDir}/.cache/doppler/doppler-mcp.json"
      "--command"
      "DOPPLER_TOKEN=$DOPPLER_MCP_AGENT_TOKEN exec ${profileBin}/forge-doppler-mcp --read-only --project agent-runtime --config dev"
    ];
    envKeys = [];
    probe = "network";
    launcher = {
      names = ["forge-doppler-mcp"];
      pkg = "@dopplerhq/mcp-server";
      version = "1.0.5";
      bin = "doppler-mcp";
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
    command = "${profileBin}/forge-playwright-mcp";
    args = ["--isolated"];
    envKeys = [];
    probe = "stdio";
    launcher = {
      names = ["forge-playwright-mcp"];
      pkg = "@playwright/mcp";
      version = "0.0.77";
      bin = "playwright-mcp";
    };
    codex = {
      required = false;
      startupTimeoutSec = 30;
      toolTimeoutSec = 180;
    };
  }
  {
    # Registrations and the Maghz fleet spell the bare name; forge-notebooklm-mcp
    # is the canonical fleet wrapper. Browser-session backend: probed only on demand.
    name = "notebooklm";
    transport = "stdio";
    command = "${profileBin}/notebooklm-mcp";
    args = [];
    envKeys = [];
    probe = "network";
    launcher = {
      names = ["notebooklm-mcp" "forge-notebooklm-mcp"];
      pkg = "notebooklm-mcp";
      version = "2.0.0";
      bin = "notebooklm-mcp";
      prelude = ''
        export NOTEBOOKLM_AI_MARKER="''${NOTEBOOKLM_AI_MARKER:-false}"
        export SESSION_TIMEOUT="''${SESSION_TIMEOUT:-3600}"
      '';
    };
    codex = {
      required = false;
      startupTimeoutSec = 30;
      toolTimeoutSec = 180;
    };
  }
  {
    name = "postgres";
    transport = "stdio";
    command = "${profileBin}/forge-maghz-postgres-mcp";
    args = [];
    envKeys = ["MAGHZ_MCP__DATABASE_URI"];
    claudeEnvNames = [];
    probe = "network";
    codex = {
      required = true;
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
    probe = "stdio";
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
    probe = "stdio";
    codex = {
      required = false;
      startupTimeoutSec = 60;
      toolTimeoutSec = 180;
    };
  }
  {
    name = "ifc";
    transport = "stdio";
    command = "${profileBin}/forge-ifcmcp";
    args = [];
    envKeys = [];
    probe = "stdio";
    codex = {
      required = false;
      startupTimeoutSec = 120;
      toolTimeoutSec = 180;
    };
  }
  {
    name = "jupyter";
    transport = "stdio";
    command = "${profileBin}/forge-jupyter-mcp";
    args = [];
    envKeys = [];
    probe = "stdio";
    codex = {
      required = false;
      startupTimeoutSec = 60;
      toolTimeoutSec = 180;
    };
  }
  {
    name = "rhino-mcp-platform";
    transport = "stdio";
    command = "${profileBin}/rhino-mcp-router";
    args = [];
    envKeys = [];
    probe = "stdio";
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
    probe = "network";
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
    url = "https://mcp.exa.ai/mcp?tools=web_search_exa,web_fetch_exa,web_search_advanced_exa,agent_tools";
    headerNames = ["x-api-key"];
    envKeys = ["EXA_API_KEY"];
    probe = "network";
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
    probe = "network";
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
    probe = "network";
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
    probe = "network";
    codex = {
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
    probe = "network";
    codex = {
      required = false;
      startupTimeoutSec = 20;
      toolTimeoutSec = 180;
    };
  }
  {
    # Codex.app-private REPL: presence asserted, definition owned by the app.
    name = "node_repl";
    transport = "stdio";
    command = "/Applications/Codex.app/Contents/Resources/cua_node/bin/node_repl";
    args = [];
    envKeys = [];
    probe = "skip";
    clients = ["codex"];
    assertLevel = "presence";
    codex = {
      required = false;
      startupTimeoutSec = 120;
      toolTimeoutSec = 180;
    };
  }
]
