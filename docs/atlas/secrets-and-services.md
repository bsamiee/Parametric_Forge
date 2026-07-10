# Secrets and Services

Secret custody is partitioned into classes, each with one origin, one movement path, and one consumer boundary; a token that crosses its boundary is the defect the partition prevents. Read mechanics belong to the secrets skill; topology mutation belongs to `services/topology.ts` and its driver.

## [01]-[CUSTODY_CLASSES]

| [INDEX] | [CLASS]                    | [ORIGIN]                                             | [MOVEMENT]              | [BOUNDARY]        |
| :-----: | :------------------------- | :--------------------------------------------------- | :---------------------- | :---------------- |
|  [01]   | User CLI Doppler token     | `doppler login` ambient auth                         | `env -u` strip          | one CLI identity  |
|  [02]   | Config service token       | Pulumi `doppler.ServiceToken` row                    | `driver.ts --reveal`    | read-only grant   |
|  [03]   | IaC admin token            | `op://Tokens/DOPPLER_IAC_TOKEN/token`                | `op read`, else ambient | driver child only |
|  [04]   | GitHub IaC PAT             | `op://Tokens/Github Token/token`                     | `op read`, else ambient | provider env only |
|  [05]   | MCP Doppler token          | `agent-runtime/dev` secret `DOPPLER_MCP_AGENT_TOKEN` | `doppler run` wrap      | wrapper-scoped    |
|  [06]   | 1Password personal custody | `Forge SSH Key` in the `Personal` vault              | 1Password agent         | public key only   |

- [01]: User CLI Doppler token: stripped with `env -u DOPPLER_TOKEN` during the multi-source hook fetch; one CLI identity, never serialized into receipts or client configs.
- [02]: Config service token: output secret `token:<project>/<config>/<name>`, revealed once via `driver.ts outputs <name> --reveal` and consumed by the hook `TOKEN_ENV_VAR` lane; read-only grant, a failed token retries ambient once and reports failure by name, never value.
- [03]: IaC admin token: `op read` unless ambient `DOPPLER_TOKEN` exists, injected as Pulumi Automation env; only the driver child process receives the unwrapped token.
- [04]: GitHub IaC PAT: `op read` unless ambient `GITHUB_TOKEN` exists, injected into `@pulumi/github`; provider env only, repository resources stay protected.
- [05]: MCP Doppler token: outer `doppler run` injects it inside the wrapper, inner `forge-doppler-mcp --read-only --project agent-runtime --config dev` narrows the surface; no `envKeys` on the row, the token never leaves the wrapper, and read-only is default posture, not the auth boundary.
- [06]: 1Password personal custody: 1Password SSH agent socket and `op-ssh-sign`; private key never enters repo files, only the public key and allowed signer are projected.

## [02]-[DOPPLER_PULL_RAIL]

The SessionStart hook `.claude/hooks/setup-env.sh` is the estate's secret ingress. `DOPPLER_SOURCES` rows have shape `project:config:snapshot[:TOKEN_ENV_VAR]`; an empty token segment means ambient CLI auth, a present one names the config-service-token env var. Each source resolves in a background worker that writes an outcome/keys/age/auth/reason meta, downloads against the config with a snapshot `--fallback`, and decodes JSON with `jq` assigned literally — secret bytes are never sourced or evaluated. The resolved keys land in the mandatory mode-600 `CLAUDE_ENV_FILE`; the receipt at the cache path carries source verdicts, key counts, stale/dead states, and unresolved key names, never values.

Two knobs change the rail: `CLAUDE_DOPPLER_OFFLINE=1` forces `--fallback-only`, and `CLAUDE_SECRET_BACKEND=transition` re-arms the `~/.config/hm-op-session.sh` 1Password fill for unset keys (default backend is `doppler`). The GUI lane is separate: `gui-op-secrets` sources backend-dispatched session material and writes key values into the launchd GUI domain with `launchctl setenv`, so GUI-launched Codex/Claude inherit tokens shells already have — its replay manifest stores key names only.

## [03]-[SERVICES_IAC]

`services/` owns the Doppler topology and GitHub settings as typed Pulumi rows over `@pulumiverse/doppler`, `@pulumi/github`, and `@pulumi/pulumi` — not per-repo YAML. Topology rows cover the Doppler and GitHub resource families; `estate.ts` folds them into resources. An `origin: "adopt"` row imports an existing resource only under `--adopt`; an `origin: "mint"` row creates fresh. The driver is `node driver.ts preview|up|refresh [--adopt] [--target=...]`, `outputs [name] [--reveal]`, and `scopes apply|doctor|strict`; Pulumi state is a local file backend under XDG state with a passphrase secrets provider.

Directory scopes replace `doppler.yaml`: `scopes apply` runs `doppler configure set` per declared directory and removes stray scope rows under the scope root. The declared bindings map the `Parametric_Forge`, `Maghz`, and `Rasm` directories to their config; the owning rows in `topology.ts` are the system of record for which config a directory resolves.

## [04]-[SSH_GIT_SIGNING]

`secretBackend = "doppler"` in `1password.nix` flips the CLI/TUI/GUI lanes to the Doppler-first session cache; `transition` re-arms the 1Password fallback. `hm-op-session.sh` is generated during activation by `op inject` from `~/.config/op/env.template` and published mode 600. SSH auth serves only `Forge SSH Key` from the `Personal` vault through the 1Password agent, and `ssh.nix` sets the Darwin `IdentityAgent` to the stable 1Password socket. Git signing uses SSH format with `key::<publicKey>`, `op-ssh-sign`, and an `allowed_signers` generated from the same public key — signing and verification are the 1Password agent item, not an on-disk key.

## [05]-[TUNNELS]

One `vpsTunnels.maghz` row in `ssh.nix` projects the interactive SSH host, the transport-only tunnel host, the launchd/systemd tunnel agent, and the loopback forwards. The forwards carry named services, each with a probe class (`pg` via `pg_isready`, `http` via a GET path, or bind-only `none` that is never service-probed); the row owns the service-to-port map. The `postgres` forward (probe `pg`) is load-bearing beyond loopback convenience: the Codex Postgres MCP is `required=true`, so its startup depends on the tunnel reaching `state=up`. A down forward breaks the MCP gate, not just the port.

## [06]-[GITHUB_AS_CODE]

GitHub repository settings are Pulumi rows adopting live `gh`-applied state across the `Parametric_Forge`, `Rasm`, and `Maghz` repositories. Merge hygiene is `allowMergeCommit=false`, `allowSquashMerge=true`, `allowRebaseMerge=true`, `deleteBranchOnMerge=true`, with wiki disabled. `main-guard` rulesets are active branch rulesets on `~DEFAULT_BRANCH` with non-fast-forward and deletion protection. The rows in `topology.ts`/`estate.ts` are the source of truth; a `gh` change made outside them drifts until the next adopt.
