# Secrets and Services

Secret custody is partitioned into classes, each with one origin, one movement path, and one consumer boundary; a token that crosses its boundary is the defect the partition prevents. Read mechanics belong to the secrets skill; topology mutation belongs to `services/topology.ts` and its driver.

## [01]-[CUSTODY_CLASSES]

| [INDEX] | [CLASS]                    | [ORIGIN]                                             | [MOVEMENT]              | [BOUNDARY]        |
| :-----: | :------------------------- | :--------------------------------------------------- | :---------------------- | :---------------- |
|  [01]   | User CLI Doppler token     | `doppler login` ambient auth                         | `env -u` strip          | one CLI identity  |
|  [02]   | Config service token       | Pulumi `doppler.ServiceToken` row                    | `driver.ts --reveal`    | read-only grant   |
|  [03]   | IaC admin token            | `op://Tokens/DOPPLER_IAC_TOKEN/token`                | `op read`, else ambient | driver child only |
|  [04]   | GitHub IaC PAT             | `op://Tokens/GITHUB_TOKEN/token`                     | `op read`, else ambient | provider env only |
|  [05]   | MCP Doppler access         | Doppler CLI auth or `agent-runtime/dev` secret       | explicit process fetch  | read-only tool    |
|  [06]   | 1Password personal custody | `Forge SSH Key` in the `Personal` vault              | 1Password agent         | public key only   |

- [01]: User CLI Doppler token: one local CLI identity, never serialized into receipts or client configs.
- [02]: Config service token: output secret `token:<project>/<config>/<name>`, revealed on demand through `driver.ts outputs <name> --reveal`; each read-only grant stays bound to one config.
- [03]: IaC admin token: `op read` unless ambient `DOPPLER_TOKEN` exists, injected as Pulumi Automation env; only the driver child process receives the unwrapped token.
- [04]: GitHub IaC PAT: `op read` unless ambient `GITHUB_TOKEN` exists, injected into `@pulumi/github`; provider env only, repository resources stay protected.
- [05]: MCP Doppler access: `posting.nix` fetches its process environment explicitly, while the fleet launcher resolves the ambient personal CLI token; `--read-only` filters the toolset to GET endpoints, and token scope remains the API-side boundary.
- [06]: 1Password personal custody: 1Password SSH agent socket and `op-ssh-sign`; private key never enters repo files, only the public key and allowed signer are projected.

## [02]-[LOCAL_SESSION_CUSTODY]

Home Manager resolves `~/.config/op/env.template` through `op inject` during activation and publishes `~/.config/hm-op-session.sh` mode 600. Interactive shells source that cache through `forge-session-secrets.sh`; `gui-op-secrets` projects the same names into the launchd GUI domain for newly spawned applications. Process-specific Doppler consumers fetch their own material with an explicit project and config at their execution boundary.

## [03]-[SERVICES_IAC]

`services/` owns the Doppler topology and GitHub settings as typed Pulumi rows over `@pulumiverse/doppler`, `@pulumi/github`, and `@pulumi/pulumi` — not per-repo YAML. Topology rows cover the Doppler and GitHub resource families; `estate.ts` folds them into resources. An `origin: "adopt"` row imports an existing resource only under `--adopt`; an `origin: "mint"` row creates fresh. The driver is `node driver.ts preview|up|refresh [--adopt] [--target=...]`, `outputs [name] [--reveal]`, and `scopes apply|doctor|strict`; Pulumi state is a local file backend under XDG state with a passphrase secrets provider.

Directory scopes replace `doppler.yaml`: `scopes apply` runs `doppler configure set` per declared directory and removes stray scope rows under the scope root. The declared bindings map the `Parametric_Forge`, `Maghz`, and `Rasm` directories to their config; the owning rows in `topology.ts` are the system of record for which config a directory resolves.

## [04]-[SSH_GIT_SIGNING]

`hm-op-session.sh` is generated during activation by `op inject` from `~/.config/op/env.template` and published mode 600 for shell and GUI consumption. SSH auth serves only `Forge SSH Key` from the `Personal` vault through the 1Password agent, and `ssh.nix` sets the Darwin `IdentityAgent` to the stable 1Password socket. Git signing uses SSH format with `key::<publicKey>`, `op-ssh-sign`, and an `allowed_signers` generated from the same public key — signing and verification are the 1Password agent item, not an on-disk key.

## [05]-[TUNNELS]

One `vpsTunnels.maghz` row in `ssh.nix` projects the interactive SSH host, transport-only tunnel host, launchd or systemd tunnel agent, and loopback forwards. Forwards carry named services and their probe class: `pg` uses `pg_isready`, `http` uses a GET path, and bind-only `none` skips service probing. One row owns the complete service-to-port map.

## [06]-[GITHUB_AS_CODE]

GitHub repository settings are Pulumi rows adopting live `gh`-applied state across the `Parametric_Forge`, `Rasm`, and `Maghz` repositories. Merge hygiene is `allowMergeCommit=false`, `allowSquashMerge=true`, `allowRebaseMerge=true`, `deleteBranchOnMerge=true`, with wiki disabled. `main-guard` rulesets are active branch rulesets on `~DEFAULT_BRANCH` with non-fast-forward and deletion protection. The rows in `topology.ts`/`estate.ts` are the source of truth; a `gh` change made outside them drifts until the next adopt.
