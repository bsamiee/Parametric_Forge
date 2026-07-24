# [SCARS]

Each row is a trap the estate already paid for: the failure shape and the rule that now forecloses it, anchored to the surface that enforces the rule. This ledger is the single system of record for these traps; a pass touching an owner re-proves the scar rows anchored to it, a row can outlive the rail it claims, and a trap whose law a gate, law page, or atlas owner absorbs moves there and leaves no copy.

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

| [INDEX] | [TRAP]                                                            | [RULE_NOW]                                                       |
| :-----: | :---------------------------------------------------------------- | :--------------------------------------------------------------- |
|  [01]   | Project `mcpServers` blocks shadowed the fleet with stale servers | Estate repositories carry no client registration; Forge governs  |
|  [02]   | `mcpServers.<name>.env` carried a literal token                   | Carry no literal token env; the wrapper resolves the live token  |
|  [03]   | Required MCP registration proves only startup/registration        | `required = true` fails startup/resume if the MCP cannot init    |
|  [04]   | Relocated LSP telemetry/plugin rows pointed at absent paths/SHAs  | Telemetry is `@forge-lsp`; dead marketplace keys are deleted     |
|  [05]   | Retained stdio writers kept abandoned fleet generations live      | Forge-owned stdio rows ride an activity lease and group reap     |
|  [06]   | An unauthenticated HTTP `401` rendered a false-green health row   | Declared OAuth joins Codex credential state with endpoint health |
|  [07]   | Parallel clients raced one rotating OAuth refresh token           | Fan-out disables unused OAuth rows; Keychain is the fixed store  |

- [02]: the literal token overrode wrapper token-file resolution.
- [03]: tunnel health, env, and wrapper are separate axes.
- [04]: the plugin cache is materialized with `claude plugin update`.
- [05]: `supervise-stdio.nix` owns the bidirectional relay, inactivity lease, and process-group reap; `mcp-fleet.nix` routes every Forge-owned stdio registration through that owner.
- [06]: `mcp-fleet.nix` declares `auth = "oauth"`; `forge-mcp doctor --network` requires Codex `o_auth` before an unauthenticated reachability probe can pass.
- [07]: `mcp_oauth_credentials_store = "keyring"` prevents backend drift; concurrent lanes omit `heptabase-mcp` unless they call it.

## [06]-[ZELLIJ_TERMINAL]

| [INDEX] | [TRAP]                                                           | [RULE_NOW]                                                          |
| :-----: | :--------------------------------------------------------------- | :------------------------------------------------------------------ |
|  [01]   | Unserialized dispatch let concurrent dispatchers dup popups      | Popup dispatch is serialized (`scripts/terminal.nix`)               |
|  [02]   | `startswith("forge-yazi.sh")` predicates matched wrong panes     | Pane identity uses exact matching                                   |
|  [03]   | An ungranted plugin in a borderless pane rendered blank forever  | Plugin grants seeded per wasm path in Zellij `permissions.kdl`      |
|  [04]   | Zellij server inherited stale env after `sessionVariables` edits | Respawn the server after session-variable changes                   |
|  [05]   | Plugin wasm WASI-deserialize panic on the pinned Zellij          | Every plugin admission needs a load proof on the pinned Zellij      |
|  [06]   | Shift `/`, `[`, `]` arrive as `?`, `{`, `}`                      | The Hyper layer binds shifted punctuation with and without Shift    |
|  [07]   | Dead sessions left orphaned `loc` processes that blocked forever | `loc` detaches stdin and deadlines its scan                         |
|  [08]   | Session names overflowed the 103-byte IPC `sun_path` cap         | Session names stay short; the byte budget is named at the minter    |
|  [09]   | Focus assertions scraped `list-clients` needlessly               | Focus is detached-mutable server state in `list-panes --all --json` |
|  [10]   | `send-keys` treated as keybind-engine input                      | It is a pane-pty write; keybind input is client-only                |

- [06]: owner: `apps/chords.nix`; the law extends to yazi — its key parser cannot represent `S-` plus non-letter chars, so shifted punctuation binds as the shifted codepoint plus the `S`-consumed sibling.
- [07]: `loc` wraps its scan with `LOC_SCAN_DEADLINE_SECONDS` and emits typed degrade output; the caller's death is what stranded it.

## [07]-[DEPLOY]

| [INDEX] | [TRAP]                                                           | [RULE_NOW]                                                            |
| :-----: | :--------------------------------------------------------------- | :-------------------------------------------------------------------- |
|  [01]   | A Brew failure killed HM activation while `nh` printed success   | `forge-redeploy` receipts propagate activation-phase exit status      |
|  [02]   | Homebrew removed `--no-quarantine`/`--no-binaries`               | Dead arg removed; posture in `HOMEBREW_CASK_OPTS` + session vars      |
|  [03]   | `_reap` exited `129` on every signal, stranding workers          | Per-signal traps pass the signal number                               |
|  [04]   | `nix flake check` passed while the maghz toplevel eval was dead  | Both-OS static gate: darwin build AND the maghz toplevel drv eval     |
|  [05]   | A darwin-only package interpolation broke the shared home graph  | Darwin-only `pkgs.*` rides `optionalString isDarwin`                  |
|  [06]   | A dirty-tree build silently packaged without untracked new files | `git add --intent-to-add` every created file before its first build   |
|  [07]   | A single-path config projection was dead on one host OS          | Tools resolve per-OS config paths; the live probe is truth            |
|  [08]   | Configs with silently-ignored unknown keys hid schema drift      | Row spellings verify against the source structs, never key acceptance |
|  [09]   | An asserted extension toggle silently removed a UI affordance    | Asserted rows pin design law, never extension-behavior toggles        |
|  [10]   | TCC denies synthetic input; live `state.vscdb` writes clobbered  | Window UI-state mutations are operator-manual, named with the gesture |

- [01]: the killed activation meant font projection never ran.
- [02]: the Brewfile `cask_args` then killed new cask installs; owner `darwin/homebrew/`.
- [03]: HUP/INT/TERM reap resolver workers before EXIT cleanup; the stranded workers were SessionStart resolver workers (`.claude/hooks/setup-env.sh`).
- [04]: the dead reference (`forge.chords` from darwin-gated `apps/`) shipped through repeated darwin-only switches; `nix eval '.#nixosConfigurations.maghz.config.system.build.toplevel.drvPath'` is the missing half of the gate.
- [05]: a darwin-only `pkgs.*` in a both-host module throws at linux eval; an empty interpolation plus a runtime `[ -n "$tn" ]` guard is the shape.

## [08]-[SHELL_KERNELS]

| [INDEX] | [TRAP]                                                          | [RULE_NOW]                                                             |
| :-----: | :-------------------------------------------------------------- | :--------------------------------------------------------------------- |
|  [01]   | Torn JSONL tail line killed pipefail readers                    | Readers rail with `fromjson?` or explicit `\|\| true`                  |
|  [02]   | `exec` skipped the EXIT trap, leaking a mktemp per run          | Cleanup never rides an EXIT trap across `exec`                         |
|  [03]   | `du \| cut \|\| echo 0` emitted two-line values on failure      | Fallbacks come from one guarded fold, never `\|\| echo`                |
|  [04]   | Silent-skip wrapper guards shipped thinner `bin/` on drift      | A missing wrapper target fails the build with a named drift error      |
|  [05]   | Raw 0x1F bytes in jq literals read as `join("")` everywhere     | Control characters spell as their escape sequence, never raw bytes     |
|  [06]   | `if ! { a; b; c; }` suspended errexit inside the block          | Guarded multi-step blocks `&&`-chain                                   |
|  [07]   | `sd` exited 0 on zero matches; drift shipped as `state=edited`  | Self-rewriting rails assert the landed row post-edit, never pre-guard  |
|  [08]   | A sentinel strip deleted the file tail on a torn region         | Region strips fail closed on an unterminated region                    |
|  [09]   | A `jq -e .` gate admitted wrong shapes, killing a merge         | Merge-with-live gates assert document shape and fall to replace        |
|  [10]   | `lib.zipListsWith` silently dropped rows past the shorter list  | Curated-list zips pair with a capacity assertion at the owner          |
|  [11]   | A grep totality proof passed on an unrelated string literal     | Totality greps match the dispatch-arm shape, never any occurrence      |
|  [12]   | Nested `''` interpolation dropped inner-line indentation        | KDL/config fragments carry full emitted indentation, single-quoted     |
|  [13]   | Flock-serialized kicks accumulated faster than they drained     | A per-event hook caps its spawned bodies and detaches background kicks |
|  [14]   | The `loc` here-string self-deadlocked on its own pipe           | A wrapper deadlines its WHOLE body, never only its inner scan          |
|  [15]   | A >512B here-doc wedged pre-exec under pipe-buffer exhaustion   | Payload-scale data pipes from `printf` or a file, never a here-doc     |
|  [16]   | A truncated positional read folded trailing fields into one var | A positional read names every emitted field, or projects via `jq`      |

- [01]: owner: the `forge-receipts` json-grain readers (`shell-tools/browsers.nix`).
- [02]: owner: the `sqlite-forge` kernel in `overlays/default.nix`; proven live — `trap ... EXIT; exec true` prints nothing.
- [04]: owner: the opt-runtime recipe in `overlays/default.nix` (energyplus, openstudio); wrapper text generates Nix-side (`placeholder "out"` + `lib.escapeShellArg`), never as runtime heredocs.
- [14]: bash 5.3 backs every sub-64K here-doc and here-string with an anonymous pipe the writer holds both ends of, filled before `exec`; under pipe-KVA exhaustion the buffer falls to 512 bytes and the pre-exec write blocks forever with no reader to deliver EOF, each wedged body deepening the exhaustion that wedges the next. The cure is two-sided — payload-scale data pipes from `printf` to a live reader or a file, and the wrapper's whole body re-execs under `timeout`.

## [09]-[FORMATTERS]

shfmt parses bare hyphenated associative-array subscripts as arithmetic and rewrites `[a-b]` to `[a - b]`, silently corrupting dispatch tables — every literal subscript in a `.sh` surface is quoted. Placeholder-bearing templates are formatter poison: the treefmt sqruff lane rewrote `||` to `| |` and lowercased `__FORGE_SERVICE_SQL__` inside live provisioning SQL, breaking `apply`/`check`/`up` for every service. Templates carrying substitution placeholders use a formatter-unowned extension (`.sql.tpl`), and the consuming self-test asserts the placeholders and the absence of mangle signatures (`overlays/forge-provision/`).

## [10]-[REMOTE_MOUNT]

| [INDEX] | [TRAP]                                                            | [RULE_NOW]                                                        |
| :-----: | :---------------------------------------------------------------- | :---------------------------------------------------------------- |
|  [01]   | Backend drop left rclone a zombie NFS server, ejected receiptless | Health loop probes process/device/statfs; a failed verdict drains |
|  [02]   | Reaping rclone under a held volume raised the interrupted dialog  | Drain detaches the volume first, reaps the NFS server second      |
|  [03]   | A stale rclone survives its supervisor across agent bounces       | Startup reaps stale rclone by `--volname` before serving twice    |
|  [04]   | Idle SFTP pool expiry re-handshook per statfs; one RST = dialog   | `idle_timeout=0` pins one warm session for the mount's lifetime   |

- Owner: `shell-tools/ssh.nix` `mountSupervisor`; an external clean unmount also exits rclone (rc=0), so `cause=rclone-exited` and `cause=ejected` are two receipts of one recovery arm.
- WezTerm nightly fronts `default_ssh_auth_sock` with a per-process proxy (`~/.local/share/wezterm/agent.<pid>`); panes see the proxy, and `ssh-add -l` through it must list the 1Password identity — the proxy, not the raw socket path, is the propagation proof.

## [11]-[MAGHZ_HOST]

The NixOS cutover to `nixosConfigurations.maghz` paid for host-base traps now folded into the host config: the first boot failed silent because initrd lacked virtio/qemu-guest support, so the host carries the qemu-guest profile and virtio initrd modules; Hostinger serves no DHCP, so the static address comes from `hosts/context.nix` with predictable interface names off and the interface `eth0`; a cross-OS switch needs `--no-reexec`, and a long remote build runs detached because a harness-killed foreground pipeline killed the first attempt mid-build.
