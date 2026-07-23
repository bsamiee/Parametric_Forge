# Title         : mcp-fleet.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mcp-fleet.nix
# ----------------------------------------------------------------------------
# Declarative MCP fleet manifest: one row is the whole definition of a fleet member. mcp-launchers.nix builds wrappers from `launcher` rows;
# `forge-mcp doctor` probes rows by `probe` class under `codex.startupTimeoutSec`; `forge-mcp drift` validates both client registrations against
# rows, reconciles only the owned MCP maps into the user/tool-owned client files, and reports drift without touching unrelated client state.
# Row schema (env/header material is key NAMES only, never values):
#   name             registration key in both clients
#   transport        "stdio" | "http"
#   command/args     stdio spawn line (absolute command)
#   url/headerNames  http endpoint + Claude header-name set
#   envKeys          env key names the server consumes
#   claudeEnvNames   Claude env-block name set when it differs from envKeys
#   probe            "stdio" (probed) | "network" (probed only with --network) | "skip"
#   launcher         { names, pkg, version, bin, prelude?, upstream, updateEngine, idleSeconds? }
#                    => Forge-built pnpm wrapper(s); upstream/updateEngine are
#                    manifest extension-family fields (`forge-mcp outdated` observes); idleSeconds
#                    overrides the supervised idle lease (default toolTimeoutSec+300) for heavy no-session servers
#   codex            { required, startupTimeoutSec, toolTimeoutSec, auth?, bearerEnvVar?, headerEnv?, toolsApprovalMode? }
#                    toolsApprovalMode projects codex `default_tools_approval_mode` — "approve" marks a pure information-retrieval server whose
#                    unannotated tools headless `codex exec` (approval: never) may call; write-capable servers never carry it (MCP runs unsandboxed)
#   clients          registration expectation, default [ "claude" "codex" ]
#   assertLevel      "full" (default) | "presence" for host-private rows
#   doctor           named probe-family checks beyond initialize: the Forge
#                    launcher name IS the probe row. Field: execs (companion
#                    binaries that must resolve on PATH)
{
  profileBin,
  homeDir,
  sshBin,
}: let
  # The supervisor counts protocol BYTES as activity and a live client renews the lease, so idleSeconds bounds only abandoned generations;
  # every row binds it explicitly (lease = codex.toolTimeoutSec + 300 via rec, matching the launcher-wrapper default) and the script's
  # generic fallback never governs a fleet row.
  mkSupervised = {
    cmd,
    args ? [],
    idleSeconds,
  }: {
    command = "${profileBin}/forge-supervise-stdio";
    args = ["--idle-seconds" (toString idleSeconds) cmd] ++ args;
  };
in [
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
      upstream = "npm:@perplexity-ai/mcp-server";
      updateEngine = "npm-registry";
    };
    codex = {
      required = false;
      startupTimeoutSec = 20;
      toolTimeoutSec = 600;
      toolsApprovalMode = "approve";
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
      upstream = "npm:hostinger-api-mcp";
      updateEngine = "npm-registry";
    };
    codex = {
      required = false;
      startupTimeoutSec = 20;
      toolTimeoutSec = 60;
    };
  }
  {
    # Registration is the doppler-run indirection: agent-runtime/dev injects DOPPLER_MCP_AGENT_TOKEN, so no ambient env key is consumed.
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
      upstream = "npm:@dopplerhq/mcp-server";
      updateEngine = "npm-registry";
    };
    codex = {
      required = false;
      startupTimeoutSec = 30;
      toolTimeoutSec = 180;
    };
  }
  rec {
    # Maghz VPS read-only secret lens: the scoped service token resolves only inside the remote host/container boundary.
    name = "doppler-remote";
    transport = "stdio";
    inherit
      (mkSupervised {
        cmd = sshBin;
        args = [
          "maghz"
          ''DOPPLER_TOKEN="$(doppler configure get token --plain --scope /srv/maghz)" docker exec -i -e DOPPLER_TOKEN maghz-mcp /opt/mcp/bin/doppler-mcp --read-only --project maghz --config prd_host''
        ];
        idleSeconds = codex.toolTimeoutSec + 300;
      })
      command
      args
      ;
    envKeys = [];
    probe = "network";
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
    args = ["--isolated" "--caps=vision,pdf"];
    envKeys = [];
    probe = "stdio";
    launcher = {
      names = ["forge-playwright-mcp"];
      pkg = "@playwright/mcp";
      version = "0.0.78";
      bin = "playwright-mcp";
      upstream = "npm:@playwright/mcp";
      updateEngine = "npm-registry";
      idleSeconds = 180; # heavy chromium subtree reaps fast once its client generation is abandoned, no persistent session to preserve
    };
    codex = {
      required = false;
      startupTimeoutSec = 30;
      toolTimeoutSec = 180;
    };
  }
  {
    # Registrations and the Maghz fleet spell the bare name; forge-notebooklm-mcp is the canonical fleet wrapper.
    # Browser-session backend: probed only on demand.
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
      upstream = "npm:notebooklm-mcp";
      updateEngine = "npm-registry";
      prelude = ''
        export NOTEBOOKLM_AI_MARKER="''${NOTEBOOKLM_AI_MARKER:-false}"
        export SESSION_TIMEOUT="''${SESSION_TIMEOUT:-3600}"
      '';
    };
    codex = {
      required = false;
      startupTimeoutSec = 30;
      toolTimeoutSec = 600;
    };
  }
  rec {
    name = "google-workspace";
    transport = "stdio";
    inherit
      (mkSupervised {
        cmd = "${profileBin}/forge-workspace-mcp";
        args = ["--tool-tier" "extended"];
        idleSeconds = codex.toolTimeoutSec + 300;
      })
      command
      args
      ;
    envKeys = ["GOOGLE_OAUTH_CLIENT_ID" "GOOGLE_OAUTH_CLIENT_SECRET" "WORKSPACE_MCP_CREDENTIALS_DIR"];
    probe = "stdio";
    codex = {
      required = false;
      startupTimeoutSec = 60;
      toolTimeoutSec = 180;
    };
  }
  rec {
    name = "nuget";
    transport = "stdio";
    inherit
      (mkSupervised {
        cmd = "${profileBin}/nuget-mcp";
        idleSeconds = codex.toolTimeoutSec + 300;
      })
      command
      args
      ;
    envKeys = [];
    probe = "stdio";
    codex = {
      required = false;
      startupTimeoutSec = 60;
      toolTimeoutSec = 180;
    };
  }
  rec {
    # Nix truth surface: nixpkgs packages plus NixOS/Home Manager/nix-darwin options from the live search index and upstream manuals;
    # pure retrieval, so headless codex may call it. Binary is the nixpkgs mcp-nixos package installed by mcp-launchers.nix.
    name = "nixos";
    transport = "stdio";
    inherit
      (mkSupervised {
        cmd = "${profileBin}/mcp-nixos";
        idleSeconds = codex.toolTimeoutSec + 300;
      })
      command
      args
      ;
    envKeys = [];
    probe = "stdio";
    codex = {
      required = false;
      startupTimeoutSec = 30;
      toolTimeoutSec = 180;
      toolsApprovalMode = "approve";
    };
  }
  {
    # Lifecycle-gated wrapper: the vendor router spawns only while Rhino 9 WIP runs; otherwise a stdio shim serves one rhino_status tool that
    # instructs start-then-reconnect. mcp-launchers.nix owns the gate.
    name = "rhino-mcp-platform";
    transport = "stdio";
    command = "${profileBin}/rhino-mcp-router";
    args = ["--default-version" "9"];
    envKeys = [];
    probe = "stdio";
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
    probe = "network";
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
    probe = "network";
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
    command = "./Codex Computer Use.app/Contents/SharedSupport/SkyComputerUseClient.app/Contents/MacOS/SkyComputerUseClient";
    args = ["mcp"];
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
