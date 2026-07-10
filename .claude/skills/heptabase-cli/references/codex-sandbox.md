# Codex Sandbox Troubleshooting

The Heptabase CLI talks to the running desktop app through a local server. Codex
may need permission to run `heptabase` outside its workspace sandbox so the CLI
can reach that local server.

## [01]-[COMMON_SYMPTOM]

```json output-only
{
    "error": "Heptabase started, but the CLI server is not ready yet. Ensure CLI is enabled..."
}
```

First, retry the command outside the sandbox. In Codex, request escalation for
`heptabase` commands when the tool supports it.

If it still fails, ask the user to make sure the desktop app has CLI enabled at
`Settings > AI Features`.

For a persistent `workspace-write` setup, ask the user to add this to
`~/.codex/config.toml`:

```toml copy-safe
[sandbox_workspace_write]
network_access = true
```

Restart Codex and retry the command.
