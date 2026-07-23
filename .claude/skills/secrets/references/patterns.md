# [PATTERNS]

Consumption shapes for secret material that is not process-env shaped, and the plan envelope that bounds design.

## [01]-[TEMPLATES]

`doppler secrets substitute <template>` renders Go `text/template` against the scoped config and writes stdout; `--output <file>` binds only where the target owner requires a durable file.

- `{{.KEY}}` interpolates a value; `{{if .OPTIONAL_KEY}}...{{end}}` guards a key that a config carries conditionally.
- `{{tojson .KEY}}` stringifies multiline material — private keys, certificates — into valid JSON/YAML scalars.
- `{{fromjson .KEY}}` expands a structured secret value into template-addressable fields.

```text
host: {{.API_HOST}}
key: {{tojson .PRIVATE_KEY}}
```

## [02]-[MOUNTS]

`doppler run --project <p> --config <c> --mount <path> [--mount-template <template>] [--mount-max-reads <n>] -- <cmd>` writes secrets to an ephemeral file and exposes its path as `DOPPLER_CLI_SECRETS_PATH`; nothing enters the process environment.

- Fit: tools that demand a config-file path — server launchers, file-only CLIs.
- `--mount-template` renders through the template engine before mounting, replacing any substitute-to-disk step.
- `--mount-max-reads <n>` caps file reads; `0` is unlimited.

## [03]-[MULTI_COMMAND]

Shell operators require the quoted `--command` form:

```bash template
doppler run --project <p> --config <c> --command='<preflight> && exec <process>; <cleanup>'
```

Command chains are generated inside owned wrappers — Nix rows, driver code — never assembled from freeform input.

## [04]-[MCP_ROW]

Fleet rows run the server through a doppler-run indirection: the outer run injects the MCP service token from its own config, and the inner server authenticates with that token.

```text
doppler run --project <token-project> --config <token-config> --fallback <snapshot> \
  --command 'DOPPLER_TOKEN=$<SECRET_NAME> exec forge-doppler-mcp --read-only --project <p> --config <c>'
```

- `--read-only` and the project/config flags narrow the exposed tool surface; the token's grants are the enforcement.
- Write-capable MCP binds only in an explicit operator session with a short-lived scoped token.

## [05]-[PLAN_GATES]

`PLAN_GATES` rejects every capability the active subscription withholds. Live entitlement proof owns each admission. `RBAC` and `Integration Access Scoping` bind Team and Enterprise; `Custom Roles` binds Enterprise or the Team add-on.
