---
name: secrets
description: Estate secret custody and consumption over Doppler and 1Password — scoped CLI reads, directory-scope resolution, the SessionStart pull rail, service-token custody classes, secret-file templating and mounts, and the read-only Doppler MCP row. Use when reading or wiring secrets, minting or routing tokens, debugging missing session env keys, rendering secret-bearing config files, or touching doppler/op surfaces. Topology mutation — projects, configs, tokens, scopes — belongs to services/topology.ts and its driver, never to ad-hoc CLI calls or per-repo files.
---

# [SECRETS]

Doppler is the single secret backend; 1Password is transitional root custody and the IaC bootstrap broker. The sanctioned Doppler surfaces on this machine: `services/topology.ts` (the only topology owner — projects, environments, configs, service tokens, and directory scopes as IaC rows), the `doppler` CLI (secret-value reads and writes against declared configs), the SessionStart hook (the only consumption rail), and `~/.doppler` (CLI-owned config and fallback state).

## [01]-[ROUTING]

- [01]-[PATTERNS](references/patterns.md): deep pattern doctrine — template rendering, mounts, multi-command wrappers, the MCP row shape, and plan-gated features.

## [02]-[RESOLUTION]

- The CLI config dir is `~/.doppler`; directory scopes live in `~/.doppler/.doppler.yaml`, written by `doppler configure set` through the driver's `scopes apply`, never by hand. A repo-local `doppler.yaml` is vendor setup guidance, not the estate scope owner; the estate carries none.
- Precedence, highest first: a service token's embedded project/config, runtime flags, environment variables (`DOPPLER_TOKEN`, `DOPPLER_PROJECT`, `DOPPLER_CONFIG`, `DOPPLER_CONFIG_DIR`, `DOPPLER_PASSPHRASE`), then config-file scope — exact directory match before nearest ancestor.
- Agents pass `--project`/`--config` explicitly; env carries only token custody and hook mode switches. An ambient `DOPPLER_TOKEN` outranks flags and represents one config; strip it with `env -u DOPPLER_TOKEN` when fetching more than one source.

## [03]-[CLI]

| [INDEX] | [TASK]                            | [COMMAND]                                                                                  |
| :-----: | :-------------------------------- | :----------------------------------------------------------------------------------------- |
|  [01]   | Binary and version proof          | `doppler --version`                                                                        |
|  [02]   | Effective options, token stripped | `doppler configure debug --json \| jq 'with_entries(.value \|= del(.token))'`              |
|  [03]   | Every scope row, token stripped   | `doppler configure --all --json \| jq 'with_entries(.value \|= del(.token))'`              |
|  [04]   | One directory's scope             | `doppler configure get project config --scope <dir> --json`                                |
|  [05]   | Set a scope row                   | `doppler configure set project=<p> config=<c> --scope <dir>`                               |
|  [06]   | Unset a scope row                 | `doppler configure unset project config --scope <dir>`                                     |
|  [07]   | Key inventory                     | `doppler secrets download --project <p> --config <c> --no-file --format json \| jq 'keys'` |
|  [08]   | Inject env into a process         | `doppler run --project <p> --config <c> --command '<cmd>'`                                 |
|  [09]   | Render a template                 | `doppler secrets substitute <template>`                                                    |

- One directory's scope: keys land as `enclave.project`, `enclave.config`.
- Set a scope row: driver-owned; scope `/` stays untouched.

Secret downloads pipe to `jq 'keys'` or `jq 'length'`; configure reads strip the root CLI token with `del(.token)` — a bare `configure debug` or `configure --all` prints it. Receipts, transcripts, and logs carry key names and counts, never values or tokens.

## [04]-[PULL_RAIL]

The SessionStart hook (`.claude/hooks/setup-env.sh`, canonical in Parametric_Forge, byte-identical in every repo copy) is the only consumption rail.

- `DOPPLER_SOURCES` rows carry the shape `project:config:snapshot[:TOKEN_ENV_VAR]`; each row resolves independently and in parallel. A live fetch rewrites its encrypted snapshot under `~/.cache/doppler`; a failed fetch serves the snapshot; a dead row is loud and names the keys it owes.
- `TOKEN_ENV_VAR` names a config-scoped service token; an empty or unset segment means ambient CLI auth. A degraded token attempt retries ambient once and blames the token in the receipt.
- `CLAUDE_DOPPLER_OFFLINE=1` forces fallback-only fetches. `CLAUDE_DOPPLER_STALE_DAYS` (default 14) marks aged snapshots `STALE` in the receipt.
- Under `CLAUDE_SECRET_BACKEND=transition` the 1Password cache fills only keys still unset — Doppler wins per key. The `doppler` backend value retires the fill.
- JSON dumps are parsed with `jq` and assigned literally, so secret bytes never reach a shell parser. The receipt lands at `~/.cache/forge-secrets/receipt`, key names only.

## [05]-[CUSTODY]

| [INDEX] | [CLASS]                          | [CUSTODY]                             | [USE]                           |
| :-----: | :------------------------------- | :------------------------------------ | :------------------------------ |
|  [01]   | User CLI token                   | Keychain login, root `/` scope        | Operator local work             |
|  [02]   | Config-scoped service token      | Hook `TOKEN_ENV_VAR` rows             | Hook and runtime reads          |
|  [03]   | IaC admin token                  | `op://Tokens/DOPPLER_IAC_TOKEN/token` | Topology writes via Pulumi only |
|  [04]   | MCP token                        | Injected as `DOPPLER_TOKEN`           | Read-only agent MCP             |
|  [05]   | Provider PATs (GitHub and peers) | Secret values inside configs          | Consumed through the pull rail  |

- User CLI token: never enters op, files, or scope rows.
- Config-scoped service token: minted by topology rows; static Developer-plan tokens are revoked and reminted, never rotated in place.
- IaC admin token: brokered by `services/driver.ts`.
- MCP token: injected inside the fleet row's doppler-run indirection; the token's grants are the boundary — `--read-only --project --config` narrow the tool surface, never access.
- Provider PATs: never topology identity.

## [06]-[OP_BOUNDARY]

- Bootstrap brokering: `services/driver.ts` reads the Pulumi passphrase from `op://Tokens/PULUMI_FORGE_SERVICES/password` and the IaC token from `op://Tokens/DOPPLER_IAC_TOKEN/token`; ambient `PULUMI_CONFIG_PASSPHRASE` / `DOPPLER_TOKEN` short-circuit op.
- `1password.nix` emits the mode-600 transition cache `~/.config/hm-op-session.sh`; `CLAUDE_SECRET_BACKEND` selects `transition` or `doppler`.
- An exported `OP_SERVICE_ACCOUNT_TOKEN` pins `op` to service-account vaults; personal-vault operations run `env -u OP_SERVICE_ACCOUNT_TOKEN op <verb>`.

## [07]-[LAW]

- A new project lands as project/config rows in `topology.ts` plus a directory scope row, then `pulumi up`; the repo carries zero Doppler files and its agents resolve through scope plus hook automatically. Retiring a project deletes its rows.
- GitHub Actions secret sync stays rejected until a workflow consumer exists: each sync spends one of five Developer-plan slots, sync cannot import existing GitHub values, and webhooks own future redeploy triggers.
- Rendered secret material is ephemeral: `--mount`/`--mount-template` over durable renders; a plaintext file binds only where the target owner requires one.
