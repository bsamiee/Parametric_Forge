# Scars

Each row is a trap the estate already paid for: the failure shape and the rule that now prevents it, anchored to the surface that enforces the rule. This ledger is the system of record for these traps — an agent that skips it re-pays the cost. Rules already stated as forward law in a sibling atlas doc are not repeated here.

## [01]-[GIT]

| [INDEX] | [TRAP] | [RULE_NOW] |
| :-----: | :--- | :--- |
| [01] | `git reset --soft HEAD~1` after an uncertain commit ate a pushed commit | Inspect the commit graph before any reset near uncertain commit state; recovery from an eaten push is fast-forward, not reset |
| [02] | `GH_TOKEN`/`GITHUB_TOKEN` shadow the keyring credential carrying `admin:ssh_signing_key` | Strip both env vars when validating signed GitHub SSH auth |
| [03] | `git add --renormalize` stages immediately and captures unrelated index state | Renormalize only inside the owning commit; there are no LFS attribute rows, so the filter is inert — verify with `git lfs ls-files` before push |

## [02]-[SIGNING]

`ssh-add -L` returned no 1Password identities and GitHub SSH auth silently fell back to an on-disk `id_ed25519`. The signing rail is the 1Password agent item `Forge SSH Key` in the `Personal` vault (`shell-tools/1password.nix`, `git-tools/git.nix`); local verification requires the generated `allowed_signers`. Personal 1Password reads need `env -u OP_SERVICE_ACCOUNT_TOKEN` because the service account is read-only, and SSH key import is desktop-app-only — the CLI cannot set reserved key fields.

## [03]-[DOPPLER]

| [INDEX] | [TRAP] | [RULE_NOW] |
| :-----: | :--- | :--- |
| [01] | MCP `--read-only` is cosmetic relative to token scope | The scoped service token is the auth boundary; read-only is default posture, not enforcement (`mcp-fleet.nix`) |
| [02] | A snapshot pruner that reaped every non-dotfile destroyed unrelated files in a repointed cache dir | Prune only owned snapshot families (`.claude/hooks/setup-env.sh`) |
| [03] | `forge-mcp drift` crashed on absent, empty, or malformed `~/.claude.json`/`~/.codex/config.toml` | A parse failure is a drift finding, not a raw crash (`mcp-launchers.nix`) |

## [04]-[CONTAINER]

Colima is the Docker API / Compose / Buildx / Pulumi default and never yields `DOCKER_HOST`; Apple Container is additive behind a macOS/Xcode gate and equivalent-contract proofs (`environments/containers.nix`). A Home Manager default path move orphaned the live VM, so the live VM path is preserved, the launchd agent owns lifecycle, and the Docker current context is never set by hand. Credential stores differ across runtimes: Docker config uses helper-free inline `auths`, Apple Container uses the macOS Keychain, and OCI tools use `REGISTRY_AUTH_FILE`.

## [05]-[MCP]

| [INDEX] | [TRAP] | [RULE_NOW] |
| :-----: | :--- | :--- |
| [01] | Project-scoped `mcpServers` blocks shadowed the global fleet with stale servers | An empty `{}` project block is inert; the global fleet governs |
| [02] | `mcpServers.jupyter.env` carried a literal `JUPYTER_TOKEN`, overriding wrapper token-file resolution | Carry no literal token env; the wrapper resolves the live token |
| [03] | Required MCP registration proves only startup/registration | `required = true` fails startup/resume when the MCP cannot initialize; tunnel health, env, and wrapper are separate axes |
| [04] | Relocated LSP telemetry/plugin rows pointed at absent paths/SHAs | Telemetry is `@forge-lsp`; the plugin cache is materialized with `claude plugin update`; dead marketplace keys are deleted |

## [06]-[ZELLIJ_TERMINAL]

| [INDEX] | [TRAP] | [RULE_NOW] |
| :-----: | :--- | :--- |
| [01] | Unserialized popup dispatch let concurrent dispatchers create duplicate popups | Popup dispatch is serialized (`scripts/integration/`) |
| [02] | `startswith("forge-yazi.sh")` predicates matched wrong panes | Pane identity uses exact matching |
| [03] | An ungranted plugin in a borderless pane rendered blank forever | Plugin grants are seeded per wasm path in the Zellij `permissions.kdl` |
| [04] | The Zellij server inherited stale env after `sessionVariables` edits | Respawn the server after session-variable changes |
| [05] | A plugin wasm panicked on the pinned Zellij with a WASI deserialize failure | Every plugin admission needs a load proof against the pinned Zellij |
| [06] | Shift `/`, `[`, `]` arrive as `?`, `{`, `}` | The Hyper layer binds shifted punctuation with and without Shift (`apps/chords.nix`) |
| [07] | Dead sessions left orphaned `loc` processes and `loc` blocked forever when the caller died | `loc` detaches stdin and wraps its scan with `LOC_SCAN_DEADLINE_SECONDS` and typed degrade output |

## [07]-[DEPLOY]

| [INDEX] | [TRAP] | [RULE_NOW] |
| :-----: | :--- | :--- |
| [01] | A Brew failure killed Home Manager activation while `nh` printed success, so font projection never ran | `forge-redeploy` receipts capture and propagate the activation-phase exit status |
| [02] | Homebrew removed `--no-quarantine`/`--no-binaries`; the Brewfile `cask_args` killed new cask installs | The dead arg is removed; posture is carried by `HOMEBREW_CASK_OPTS` and session variables (`darwin/homebrew/`) |
| [03] | `AllSpacesAndDisplays` was a phantom wallpaper schema and PlistBuddy `Add` failed under `set -e` | The wallpaper rail uses System Events `osascript` plus an idempotence probe (`assets/wallpaper/`) |
| [04] | A `_reap` that exited `129` for every signal stranded SessionStart workers | Per-signal traps pass the signal number; HUP/INT/TERM reap resolver workers before EXIT cleanup (`.claude/hooks/setup-env.sh`) |

## [08]-[RASM]

Rasm owns the method and language-law bedrock Forge composes: campaign method and the `docs/stacks/{typescript,python}` doctrine that Forge references rather than duplicates. `docs/standards/design-doctrine.md` is byte-identical across Rasm, Forge, and Maghz; Forge adds `nix-doctrine`, Maghz adds `ops-doctrine`. The docgen master is Rasm `.claude/skills/docgen/` and mirrors propagate by copy, never tooling. Forge-owned global Git config controls LFS behavior that reaches Rasm — Rasm's tip carries zero LFS attribute rows, making the filter inert. Rasm points its machine-level scientific and provisioning executables back to Forge ownership: a shell/PATH/scientific/DB failure in Rasm is fixed in the Forge owner, never patched in Rasm.

## [09]-[MAGHZ]

Forge owns the `nixosConfigurations.maghz` host and `forge-redeploy --os nixos --host maghz`; the Maghz service plane deploys only after the host base is proven. `ssh.nix` owns the Maghz host identity and the tunnel substrate, and the Codex Postgres MCP converged from an inline `uvx` row to the Forge launcher `forge-maghz-postgres-mcp` (env key `MAGHZ_MCP__DATABASE_URI`, `required=true`) — so Codex startup depends on tunnel ordering, and `profile local|prd` is the only mode-changing entry, declared up only after service-health probes pass through the tunnel. Maghz is service-bearing (Postgres 18, Ollama, n8n, Atuin sync on loopback, Docker volumes, Doppler interpolation) and owns its own standards and `ops-doctrine`.

The cutover paid for host-base traps now folded into the host config: the first boot failed silent because initrd lacked virtio/qemu-guest support, so `nixosConfigurations.maghz` includes the qemu-guest profile and virtio initrd modules; Hostinger serves no DHCP, so the static address comes from `hosts/context.nix` with predictable interface names off and the interface `eth0`; a cross-OS switch needs `--no-reexec`, and a long remote build runs detached because a harness-killed foreground pipeline killed the first attempt mid-build. Apple Container is not a Maghz runtime until Docker API, `docker cp`, BuildKit cache, network alias, healthcheck, and named-volume contracts have equivalent owners.
