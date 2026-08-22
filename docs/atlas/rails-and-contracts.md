# Rails and Contracts

Forge rails are `writeShellApplication` commands with shared locks and receipt-on-exit; `forge-provision` also owns a schema-versioned JSON envelope. Each command's `--help` owns usage.

## [01]-[RAIL_SET]

| [INDEX] | [RAIL]                   | [OWNS]                                                                  | [OWNER]                     |
| :-----: | :----------------------- | :---------------------------------------------------------------------- | :-------------------------- |
|  [01]   | `forge-redeploy`         | The only sanctioned activation path                                     | `forge-tools/deploy.nix`    |
|  [02]   | `forge-accept`           | Ordered post-switch proof from preflight through operator relaunch      | `forge-tools/accept.nix`    |
|  [03]   | `forge-doctor`           | Read-only machine lenses: path, launchd, parity, updates                | `forge-tools/doctor.nix`    |
|  [04]   | `forge-nix-maintenance`  | Generation trim, GC, store optimise                                     | `forge-tools/deploy.nix`    |
|  [05]   | `forge-activation-sweep` | Root-owned in-the-way HM target detection and clear                     | `forge-tools/deploy.nix`    |
|  [06]   | `forge-cleanup`          | Litter plan/apply and orphan sweep over a typed row registry            | `forge-tools/cleanup.nix`   |
|  [07]   | `forge-provision`        | Docker/Compose DB estate: envelope, locks, generations, extension apply | `overlays/forge-provision/` |
|  [08]   | `forge-mcp`              | MCP wrapper presence doctor and registration drift                      | `mcp-launchers.nix`         |

Owner paths resolve under `modules/home/programs/shell-tools/` unless the row names a repo root. `forge-browse tools` indexes every packaged estate command with its owner file and the trigger that calls for it; the same rows project to `~/.config/forge/registers/tools.json`.

## [02]-[FORGE_REDEPLOY]

Darwin builds and switches locally; NixOS check is eval-only, build proves closure, and switch runs locally on Linux or remotely through `nixos-rebuild --target-host --build-host` from Darwin. `FORGE_REDEPLOY_LOCK` serializes deploy and maintenance, every state-touching run receipts from its EXIT trap, and activation consumes the already-built store path. Cachix push failure cannot fail an already-switched deploy. `forge-tools/lib.nix` owns the tab-delimited receipt vector and the `FORGE_<NAME>_RECEIPT_LOG` override grammar.

## [03]-[FORGE_ACCEPT]

`forge-accept --list` emits the ordered step vocabulary — `preflight switch replay outputs doctor zellij terminal fleet lanes relaunch` — and `--from STEP` or `--only STEP` selects into it. `preflight` gates `switch` through the flake root, the WezTerm cask pair, `nix.custom.conf`, the activation sweep, and the deploy lock.

`replay` kickstarts the GUI secrets agent and diffs replayed key NAMES against the live GUI domain. `outputs` probes a clean-env interactive login shell for PATH single-ownership, compdump litter, and fzf warnings. `doctor` folds the `path`, `launchd`, and `parity` lenses into verdict rows, and `zellij` proves each live server postdates the generation, reaping only forge-owned zero-client sessions.

`terminal` delegates to `forge-terminal-accept.sh`. `fleet` runs `forge-mcp doctor` (wrapper presence; stateless clients own protocol health) and `forge-mcp drift`. `lanes` compares expected secret key names across shell and GUI without values, and `relaunch` emits the operator instruction rows. Rows carry `ts / step / status / detail` and close with the folded result.

## [04]-[FORGE_DOCTOR]

`forge-doctor LENS [--json]` dispatches on a catalog row naming the lens and its handler; an unlisted lens exits `64`, and every lens is read-only. One typed row stream renders both the human table and the `forge-doctor/v1` envelope, and any lens finding drift exits nonzero.

`path` classifies each PATH segment by owner (`hm`, `system`, `nix`, `homebrew`, `local`, `macos`, `app`), reports cross-owner shadows where a later segment holds a different binary, proves the `MAGIC` seed is served by the store `file` rather than the macOS one, reads CLT health and brew posture, and inventories `~/.local/bin` against a named ruling per entry — an unruled entry reports `unadjudicated`.

`launchd` reconciles the declared plists in `~/Library/LaunchAgents` with the live `launchctl` table and classifies each label through prefix triage rows; an unmatched label reports `unclassified` and demands a row. `parity` walks the generation's `home-files` against live `$HOME` (store-linked, staged-equal, missing, drifted), finds broken store links across the managed roots, and asserts the Home Manager gc-root singleton. `updates` stays observation-only — flake-input age, the last deploy receipt, Homebrew outdated counts, uv tool count — never drift-scored.

## [05]-[MAINTENANCE_AND_CLEANUP]

`forge-nix-maintenance` trims system generations to current-only (`--delete-generations old`), garbage-collects user profiles whole (`nix-collect-garbage -d`), and optimises the store under the shared `FORGE_REDEPLOY_LOCK` (scheduled nonblocking, manual waits up to 600s). `forge-activation-sweep` scans topmost root-owned entries under `.config`, `.local/share`, `.local/state` (exempting the detsys-ids client, `.hammerspoon`, and `Library/LaunchAgents`), exits `4` on findings, and `--clear` batches one `sudo` removal and rescans.

`forge-cleanup plan|apply|sweep` drives a typed row registry over five kinds — `glob` (trash matches under a root), `age` (retention window, where the age gate is itself the live-session guard), `deadlink` (broken links only), `codex-trust` (stale trusted-project rows), and `orphan` (evidence-gated reap of ppid-1 tty-less agent litter).

`plan` writes a durable precheck receipt, `apply` re-detects live state before acting and moves rows into `~/.Trash`, and `sweep` processes only orphan rows and feeds the hourly orphan-sweep agent. Registry rows carry standing policy no first-party tool expresses: storage questions are answered on demand with `dust -d 1 -n 20 -r ~` and each tool's own prune verb — `uv cache prune`, `pnpm store prune`, `docker system prune`, `colima prune`, `mise prune --configs`, `pulumi plugin rm` — never by a duplicating row.

## [06]-[FORGE_PROVISION_ENVELOPE]

Raw source-tree execution exits `126`; the packaged command or `nix run .#forge-provision` carries the runtime closure. `schema_version` is `3`. `envelope-base.jq` owns the top-level shape, and `error-envelope.jq` preserves structural defaults on failure. `redact-message.jq` strips sensitive endpoints, paths, credentials, and tokens before output; agent-facing JSON carries only sanitized booleans and catalog metadata.

## [07]-[FORGE_PROVISION_CATALOG]

`data/commands.json` owns the verb catalog through `command-routes.jq`. Self-test binds each mutating verb to `lockMode:"mutation"`, `psql` to `lockMode:"psql-session"`, and other verbs to `lockMode:"none"`; mutation and psql sessions exclude each other. Endpoint locks are endpoint-hash scoped. Routes govern diagnostic JSON admission. Root resolution hashes `FORGE_PROVISION_ROOT` or the Git worktree into `root_key`; generations publish through an atomic `current` symlink. Catalog absence rejects a verb.

`up` is the full sequence: mutating Docker, endpoint lock, active-project cap, busy-aware ports, owned-resource assertions, compose generation, `docker compose up -d --remove-orphans --wait`, readiness, required-extension apply, generation publish, and volume-ledger render — a failed first-up preserves volumes unless `prune --owned --volumes` proves removal intent. `down` removes owned containers/networks and preserves volumes; `prune --owned` removes volumes only with `--volumes`. `check` and `apply` share one handler — `check` validates static env under no lock, `apply` runs the extension apply under mutation lock — and a missing required extension surfaces `error.code="required-extension-unavailable"`.

## [08]-[DB_CONTAINER_ESTATE]

`data/services.json` owns Postgres service images, ports, and gates. `data/postgres-extensions.json` owns required extension rows and their environment selectors. DuckDB and SQLite tool surfaces derive from their extension catalogs and probe without Docker. `overlays/manifest.nix` owns the DuckDB and SQLean binary rows; `languages/db-tools.nix` owns DB clients, and `container-tools/default.nix` owns the container estate. Each new extension or service lands as one catalog row.

## [09]-[UPDATE_SEQUENCE]

One ordered pass refreshes every currency family; each step proves through its owning gate before the next starts, and the working tree is clean before the first mutation.

| [INDEX] | [FAMILY]     | [COMMAND]                                       | [PROOF]                                                       |
| :-----: | :----------- | :---------------------------------------------- | :------------------------------------------------------------ |
|  [01]   | working tree | scoped commits, push                            | `git status` clean                                            |
|  [02]   | flake inputs | `nix flake update`                              | `forge-redeploy --build`; commit `nix: bump flake inputs (…)` |
|  [03]   | nvfetcher    | `nvfetcher -o overlays/_sources`                | build gate rides the switch                                   |
|  [04]   | activation   | `forge-redeploy --switch`                       | `forge-accept`                                                |
|  [05]   | homebrew     | full brew pass (below)                          | `brew outdated` and `brew doctor` clean                       |
|  [06]   | python venv  | `forge-scientific-env uv sync` at the repo root | dead-dylib sweep after any python/native input move           |
|  [07]   | store        | `forge-nix-maintenance`                         | single system generation, GC, optimise                        |

Flake bumps moving the Nix python invalidate the venv whole; bumps moving native libs poison cached wheels — `otool -L` over every site-packages native, each `/nix/store/*.dylib` tested, rebuilds each hit with `forge-scientific-env uv pip install --reinstall --no-cache`; a path still missing after the rebuild is a missing library row in `scientific-tools.nix`, never another rebuild.

Homebrew custody: nix-darwin's Brewfile installs missing roster entries while activation leaves metadata, versions, and unlisted packages intact. Homebrew 6 third-party entries use a fully qualified name with item-scoped `trusted = true`; official formulae and casks are intrinsically trusted. Operator maintenance runs `brew update`, formula and cask upgrades, a targeted `wezterm@nightly --greedy-latest` upgrade, `brew autoremove`, and `brew cleanup --prune=all -s`; `brew outdated` and `brew doctor` close the pass.
