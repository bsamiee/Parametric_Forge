# Scars

Each row is a trap the estate already paid for: the failure shape and the rule that now prevents it, anchored to the surface that enforces the rule. This ledger is the system of record for these traps — an agent that skips it re-pays the cost. Rules already stated as forward law in a sibling atlas doc are not repeated here.

## [01]-[GIT]

| [INDEX] | [TRAP]                                                           | [RULE_NOW]                                                 |
| :-----: | :--------------------------------------------------------------- | :--------------------------------------------------------- |
|  [01]   | `git reset --soft HEAD~1` ate a pushed commit                    | Inspect the commit graph before any uncertain-state reset  |
|  [02]   | `GH_TOKEN`/`GITHUB_TOKEN` shadow the keyring credential          | Strip both env vars when validating signed GitHub SSH auth |
|  [03]   | `git add --renormalize` immediately stages unrelated index state | Renormalize only inside the owning commit                  |

- [01]: recovery: an eaten push recovers by fast-forward, not reset.
- [02]: the shadowed credential carries `admin:ssh_signing_key`.
- [03]: no LFS attribute rows exist, so the filter is inert; verify with `git lfs ls-files` before push.

## [02]-[SIGNING]

`ssh-add -L` returned no 1Password identities and GitHub SSH auth silently fell back to an on-disk `id_ed25519`. The signing rail is the 1Password agent item `Forge SSH Key` in the `Personal` vault (`shell-tools/1password.nix`, `git-tools/git.nix`); local verification requires the generated `allowed_signers`. Personal 1Password reads need `env -u OP_SERVICE_ACCOUNT_TOKEN` because the service account is read-only, and SSH key import is desktop-app-only — the CLI cannot set reserved key fields.

## [03]-[DOPPLER]

| [INDEX] | [TRAP]                                                             | [RULE_NOW]                                          |
| :-----: | :----------------------------------------------------------------- | :-------------------------------------------------- |
|  [01]   | MCP `--read-only` is cosmetic relative to token scope              | The scoped service token is the auth boundary       |
|  [02]   | A pruner reaping every non-dotfile wiped a repointed cache dir     | Prune only owned snapshot families                  |
|  [03]   | `forge-mcp drift` crashed on absent/empty/malformed client configs | A parse failure is a drift finding, not a raw crash |

- [01]: read-only is default posture, not enforcement (`mcp-fleet.nix`).
- [02]: owner: `.claude/hooks/setup-env.sh`.
- [03]: crash inputs: `~/.claude.json`/`~/.codex/config.toml`; owner `mcp-launchers.nix`.

## [04]-[CONTAINER]

Colima is the Docker API / Compose / Buildx / Pulumi default and never yields `DOCKER_HOST`; Apple Container is additive behind a macOS/Xcode gate and equivalent-contract proofs (`environments/containers.nix`). A Home Manager default path move orphaned the live VM, so the live VM path is preserved, the launchd agent owns lifecycle, and the Docker current context is never set by hand. Credential stores differ across runtimes: Docker config uses helper-free inline `auths`, Apple Container uses the macOS Keychain, and OCI tools use `REGISTRY_AUTH_FILE`.

## [05]-[MCP]

| [INDEX] | [TRAP]                                                            | [RULE_NOW]                                                      |
| :-----: | :---------------------------------------------------------------- | :-------------------------------------------------------------- |
|  [01]   | Project `mcpServers` blocks shadowed the fleet with stale servers | An empty `{}` project block is inert; the global fleet governs  |
|  [02]   | `mcpServers.jupyter.env` carried a literal `JUPYTER_TOKEN`        | Carry no literal token env; the wrapper resolves the live token |
|  [03]   | Required MCP registration proves only startup/registration        | `required = true` fails startup/resume if the MCP cannot init   |
|  [04]   | Relocated LSP telemetry/plugin rows pointed at absent paths/SHAs  | Telemetry is `@forge-lsp`; dead marketplace keys are deleted    |

- [02]: the literal token overrode wrapper token-file resolution.
- [03]: tunnel health, env, and wrapper are separate axes.
- [04]: the plugin cache is materialized with `claude plugin update`.

## [06]-[ZELLIJ_TERMINAL]

| [INDEX] | [TRAP]                                                           | [RULE_NOW]                                                       |
| :-----: | :--------------------------------------------------------------- | :--------------------------------------------------------------- |
|  [01]   | Unserialized dispatch let concurrent dispatchers dup popups      | Popup dispatch is serialized (`scripts/terminal.nix`)            |
|  [02]   | `startswith("forge-yazi.sh")` predicates matched wrong panes     | Pane identity uses exact matching                                |
|  [03]   | An ungranted plugin in a borderless pane rendered blank forever  | Plugin grants seeded per wasm path in Zellij `permissions.kdl`   |
|  [04]   | Zellij server inherited stale env after `sessionVariables` edits | Respawn the server after session-variable changes                |
|  [05]   | Plugin wasm WASI-deserialize panic on the pinned Zellij          | Every plugin admission needs a load proof on the pinned Zellij   |
|  [06]   | Shift `/`, `[`, `]` arrive as `?`, `{`, `}`                      | The Hyper layer binds shifted punctuation with and without Shift |
|  [07]   | Dead sessions left orphaned `loc` processes that blocked forever | `loc` detaches stdin and deadlines its scan                      |
|  [08]   | Session names overflowed the 103-byte IPC `sun_path` cap         | Session names stay short; the byte budget is named at the minter |

- [06]: owner: `apps/chords.nix`.
- [07]: `loc` wraps its scan with `LOC_SCAN_DEADLINE_SECONDS` and emits typed degrade output; the caller's death is what stranded it.

## [07]-[DEPLOY]

| [INDEX] | [TRAP]                                                          | [RULE_NOW]                                                        |
| :-----: | :-------------------------------------------------------------- | :---------------------------------------------------------------- |
|  [01]   | A Brew failure killed HM activation while `nh` printed success  | `forge-redeploy` receipts propagate activation-phase exit status  |
|  [02]   | Homebrew removed `--no-quarantine`/`--no-binaries`              | Dead arg removed; posture in `HOMEBREW_CASK_OPTS` + session vars  |
|  [03]   | `AllSpacesAndDisplays` was a phantom wallpaper schema           | Wallpaper rail uses System Events `osascript` + idempotence probe |
|  [04]   | `_reap` exited `129` on every signal, stranding workers         | Per-signal traps pass the signal number                           |
|  [05]   | `nix flake check` passed while the maghz toplevel eval was dead | Both-OS static gate: darwin build AND the maghz toplevel drv eval |
|  [06]   | A darwin-only package interpolation broke the shared home graph | Darwin-only `pkgs.*` rides `optionalString isDarwin`              |

- [01]: the killed activation meant font projection never ran.
- [02]: the Brewfile `cask_args` then killed new cask installs; owner `darwin/homebrew/`.
- [03]: PlistBuddy `Add` failed under `set -e`; owner `assets/wallpaper/`.
- [04]: HUP/INT/TERM reap resolver workers before EXIT cleanup; the stranded workers were SessionStart resolver workers (`.claude/hooks/setup-env.sh`).
- [05]: the dead reference (`forge.chords` from darwin-gated `apps/`) shipped through repeated darwin-only switches; `nix eval '.#nixosConfigurations.maghz.config.system.build.toplevel.drvPath'` is the missing half of the gate.
- [06]: `terminal-notifier` in `shell-tools/` (imported by both hosts) throws at linux eval; an empty interpolation plus a runtime `[ -n "$tn" ]` guard is the shape.

## [08]-[SHELL_KERNELS]

| [INDEX] | [TRAP]                                                              | [RULE_NOW]                                                        |
| :-----: | :------------------------------------------------------------------ | :---------------------------------------------------------------- |
|  [01]   | Torn JSONL tail line killed pipefail readers                        | Readers rail with `fromjson?` or explicit `\|\| true`             |
|  [02]   | `exec` skipped the EXIT trap, leaking a mktemp per run              | Cleanup never rides an EXIT trap across `exec`                    |
|  [03]   | `du \| cut \|\| echo 0` emitted two-line values on failure          | Fallbacks come from one guarded fold, never `\|\| echo`           |
|  [04]   | Silent-skip wrapper guards shipped thinner `bin/` on upstream drift | A missing wrapper target fails the build with a named drift error |
|  [05]   | Raw 0x1F bytes in jq literals read as `join("")` everywhere         | Control characters spell as escapes (`\u001f`), never raw bytes   |

- [01]: owners: the `forge-agents` quota lanes and attention fold (`shell-tools/mcp-launchers.nix`).
- [02]: owner: `overlays/sqlite-forge/`; proven live — `trap ... EXIT; exec true` prints nothing.
- [04]: owners: `overlays/energyplus/`, `overlays/openstudio/`; wrapper text generates Nix-side (`placeholder "out"` + `lib.escapeShellArg`), never as runtime heredocs.

## [09]-[FORMATTERS]

Placeholder-bearing templates are formatter poison: the treefmt sqruff lane rewrote `||` to `| |` and lowercased `__FORGE_SERVICE_SQL__` inside live provisioning SQL, breaking `apply`/`check`/`up` for every service. Templates carrying substitution placeholders use a formatter-unowned extension (`.sql.tpl`), and the consuming self-test asserts the placeholders and the absence of mangle signatures (`overlays/forge-provision/`).

## [10]-[ATTENTION]

| [INDEX] | [TRAP]                                                   | [RULE_NOW]                                               |
| :-----: | :------------------------------------------------------- | :------------------------------------------------------- |
|  [01]   | `osascript` notification clicks opened Script Editor     | Notifications post via `terminal-notifier`; clicks route |
|  [02]   | Attention count trusted stale hook rows: 4 tabs, 4 waits | `needs_input` joins live idle lanes, one per pane        |

- [01]: the click executes `forge-agents focus` — zellij pane focus, pty-to-host-app ancestry resolution, receipt per lane (`shell-tools/mcp-launchers.nix`).
- [02]: the join normalizes `ps` short/long tty forms and dedupes `unique_by(.tty)`; a session whose latest event is `Notification` but whose lane is busy already got its answer.

## [11]-[RASM]

Rasm owns the method and language-law bedrock Forge composes: campaign method and the `docs/stacks/{typescript,python}` doctrine that Forge references rather than duplicates. `docs/standards/design-doctrine.md` is byte-identical across Rasm, Forge, and Maghz; Forge adds `nix-doctrine`, Maghz adds `ops-doctrine`. The docgen master is Rasm `.claude/skills/docgen/` and mirrors propagate by copy, never tooling. Forge-owned global Git config controls LFS behavior that reaches Rasm — Rasm's tip carries zero LFS attribute rows, making the filter inert. Rasm points its machine-level scientific and provisioning executables back to Forge ownership: a shell/PATH/scientific/DB failure in Rasm is fixed in the Forge owner, never patched in Rasm.

## [12]-[MAGHZ]

Forge owns the `nixosConfigurations.maghz` host and `forge-redeploy --os nixos --host maghz`; the Maghz service plane deploys only after the host base is proven. `ssh.nix` owns the Maghz host identity and the tunnel substrate, and the Codex Postgres MCP converged from an inline `uvx` row to the Forge launcher `forge-maghz-postgres-mcp` (env key `MAGHZ_MCP__DATABASE_URI`, `required=true`) — so Codex startup depends on tunnel ordering, and `profile local|prd` is the only mode-changing entry, declared up only after service-health probes pass through the tunnel. Maghz is service-bearing (Postgres 18, Ollama, n8n, Atuin sync on loopback, Docker volumes, Doppler interpolation) and owns its own standards and `ops-doctrine`.

The cutover paid for host-base traps now folded into the host config: the first boot failed silent because initrd lacked virtio/qemu-guest support, so `nixosConfigurations.maghz` includes the qemu-guest profile and virtio initrd modules; Hostinger serves no DHCP, so the static address comes from `hosts/context.nix` with predictable interface names off and the interface `eth0`; a cross-OS switch needs `--no-reexec`, and a long remote build runs detached because a harness-killed foreground pipeline killed the first attempt mid-build. Apple Container is not a Maghz runtime until Docker API, `docker cp`, BuildKit cache, network alias, healthcheck, and named-volume contracts have equivalent owners.
