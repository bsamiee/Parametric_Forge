# Rails and Contracts

The Forge rails are `writeShellApplication` commands with fixed contracts: shared locks, receipt-on-exit, and — for `forge-provision` — a schema-versioned JSON envelope. Usage routes to each command's `--help`.

## [01]-[RAIL_SET]

| [INDEX] | [RAIL]                   | [OWNS]                                                                  | [OWNER]                         |
| :-----: | :----------------------- | :---------------------------------------------------------------------- | :------------------------------ |
|  [01]   | `forge-redeploy`         | The only sanctioned activation path                                     | `shell-tools/forge-tools.nix`   |
|  [02]   | `forge-accept`           | Ordered post-switch proof across secrets, terminal, MCP fleet, tunnels  | `shell-tools/forge-tools.nix`   |
|  [03]   | `forge-nix-maintenance`  | Generation trim, GC, store optimise                                     | `shell-tools/forge-tools.nix`   |
|  [04]   | `forge-activation-sweep` | Root-owned in-the-way HM target detection and clear                     | `shell-tools/forge-tools.nix`   |
|  [05]   | `forge-cleanup`          | Litter plan/apply and orphan sweep over a typed row registry            | `shell-tools/forge-tools.nix`   |
|  [06]   | `forge-provision`        | Docker/Compose DB estate: envelope, locks, generations, extension apply | `overlays/forge-provision/`     |
|  [07]   | `forge-mcp`              | MCP wrapper presence doctor, drift, and pin currency                    | `shell-tools/mcp-launchers.nix` |

## [02]-[FORGE_REDEPLOY]

Darwin builds and switches locally; NixOS check is eval-only, build proves closure, and switch runs locally on Linux or remotely through `nixos-rebuild --target-host --build-host` from Darwin. The invariants: the deploy/maintenance lock is shared through `FORGE_REDEPLOY_LOCK`; a state-touching run emits its receipt on the EXIT trap even on failure; activation uses the already-built store path, never a second evaluation; and a Cachix push failure must not fail an already-switched deploy. One state-touching run emits one tab-delimited receipt carrying mode/os/host, eval/build/activate timings, to-build and to-fetch counts, diff lines, and result — the field vector is owned by `forge-tools.nix`.

## [03]-[FORGE_ACCEPT]

`forge-accept --list` emits the ordered step vocabulary; `--from STEP` and `--only STEP` select into it. Ordering is contractual: `preflight` gates `switch` through the flake root, WezTerm cask, `nix.custom.conf`, activation sweep, and deploy lock; `maghz` evaluates each declared tunnel receipt. `fleet` runs `forge-mcp doctor` (wrapper presence; stateless clients own protocol health) and `forge-mcp drift`; `lanes` compares expected secret key names across CLI, TUI, and GUI without values. Rows carry `ts / step / status / detail` and close with the folded result.

## [04]-[MAINTENANCE_SWEEP]

`forge-nix-maintenance` trims system generations to current-only (`--delete-generations old`), garbage-collects user profiles whole (`nix-collect-garbage -d`), and optimises the store under the shared `FORGE_REDEPLOY_LOCK` (scheduled nonblocking, manual waits up to 600s). `forge-activation-sweep` scans topmost root-owned entries under `.config`, `.local/share`, `.local/state` (exempting the detsys-ids client, `.hammerspoon`, and `Library/LaunchAgents`), exits `4` on findings, and `--clear` batches one `sudo` removal and rescans. `forge-cleanup plan|apply|sweep` drives a typed row registry (`mode`, `glob`, `path`, `orphan` kinds); `apply` re-detects live state before acting and moves rows into `~/.Trash`, `sweep` processes only orphan rows and feeds the hourly orphan-sweep agent.

## [05]-[FORGE_PROVISION_ENVELOPE]

Raw source-tree execution is rejected with exit `126`; the packaged command or `nix run .#forge-provision` is required, and it brings its own `coreutils`/`docker`/`jq`/`duckdb`/`sqlite-forge` runtime closure. `schema_version` is `3`, the single emitter contract. The JSON envelope top-level shape is owned by `overlays/forge-provision/jq/envelope-base.jq`, and error envelopes preserve `schemaVersion`/`command`/`ok:false`/`warnings`/`error` with empty structural defaults via `error-envelope.jq`. The load-bearing sanitization contract: `auth` reports `credential:"managed-hidden"` and `agentPromptRequired:false`, DSNs are redacted, and the script plus `redact-message.jq` strip sockets, Docker config paths, credential-helper names, DSN passwords, mount paths, host absolute paths, and GitHub/Slack tokens before printing. Agent-facing JSON is sanitized booleans and catalog metadata only.

## [06]-[FORGE_PROVISION_CATALOG]

The verb catalog is `data/commands.json`, loaded through `command-routes.jq`. The mutability partition is a self-test invariant: `up`, `down`, `prune`, `apply` use `lockMode:"mutation"`, `psql` uses `lockMode:"psql-session"`, all others `lockMode:"none"` — self-test enforces that a mutating command implies mutation lock and mutation lock implies a mutating command. Mutation and psql sessions exclude each other; port and endpoint locks are endpoint-hash scoped and acquired during `up`. `--json` and `--diagnostic-json` are mutually exclusive, and `--diagnostic-json` is admitted only for verbs whose route admits it. Root resolves from `FORGE_PROVISION_ROOT` or the Git worktree (refusing symlink roots), hashes to a 12-hex `root_key`, and composes the project cap as `forge-<project_key>-<instance>`; generations publish through an atomic `current` symlink that refuses a non-symlink target. An unlisted verb is rejected.

`up` is the full sequence: mutating Docker, endpoint lock, active-project cap, busy-aware ports, owned-resource assertions, compose generation, `docker compose up -d --remove-orphans --wait`, readiness, required-extension apply, generation publish, and volume-ledger render — a failed first-up preserves volumes unless `prune --owned --volumes` proves removal intent. `down` removes owned containers/networks and preserves volumes; `prune --owned` removes volumes only with `--volumes`. `check` and `apply` share one handler — `check` validates static env under no lock, `apply` runs the extension apply under mutation lock — and a missing required extension surfaces `error.code="required-extension-unavailable"`.

## [07]-[DB_CONTAINER_ESTATE]

The service catalog `data/services.json` is the system of record for the three Postgres services `timescale`, `search`, and `pgduckdb`; images and ports are env-overridable (`FORGE_PROVISION_TIMESCALE_IMAGE`, `FORGE_PROVISION_*_PORT`), and `pgduckdb` is gated by `FORGE_PROVISION_PGDUCKDB=0`. Required extensions live in `data/postgres-extensions.json` with the global row `pg_trgm`; the gated required rows `pg_cron` (`FORGE_PROVISION_PG_CRON=0`) and `vectorscale` (`FORGE_PROVISION_VECTORSCALE=0`) are opt-out env knobs, not prose. DuckDB and SQLite tool surfaces are catalog-driven from `data/duckdb-extensions.json` and `data/sqlite-extensions.json` and probe without Docker. The DuckDB and SQLean binaries are manifest-pinned rows in `overlays/manifest.nix` built through `overlays/default.nix`; the DB client estate is rostered in `languages/db-tools.nix`, and the container/K8s/OCI estate in `container-tools/default.nix`. A new extension or service is a catalog row, never a code change.

## [08]-[UPDATE_SEQUENCE]

One ordered pass refreshes every currency family; each step proves through its owning gate before the next starts, and the working tree is clean before the first mutation.

| [INDEX] | [FAMILY]     | [COMMAND]                                       | [PROOF]                                                       |
| :-----: | :----------- | :---------------------------------------------- | :------------------------------------------------------------ |
|  [01]   | working tree | scoped commits, push                            | `git status` clean                                            |
|  [02]   | flake inputs | `nix flake update`                              | `forge-redeploy --build`; commit `nix: bump flake inputs (…)` |
|  [03]   | nvfetcher    | `nvfetcher -o overlays/_sources`                | build gate rides the switch                                   |
|  [04]   | MCP pins     | `forge-mcp outdated` then `forge-mcp advance`   | advance owns its build gate and commit                        |
|  [05]   | activation   | `forge-redeploy --switch`                       | `forge-accept`                                                |
|  [06]   | homebrew     | full brew pass (below)                          | `brew outdated` and `brew doctor` clean                       |
|  [07]   | python venv  | `forge-scientific-env uv sync` at the repo root | dead-dylib sweep after any python/native input move           |
|  [08]   | store        | `forge-nix-maintenance`                         | single system generation, GC, optimise                        |

Flake bumps moving the Nix python invalidate the venv whole; bumps moving native libs poison cached wheels — `otool -L` over every site-packages native, each `/nix/store/*.dylib` tested, rebuilds each hit with `forge-scientific-env uv pip install --reinstall --no-cache`; a path still missing after the rebuild is a missing library row in `scientific-tools.nix`, never another rebuild.

Homebrew custody: nix declares the roster (`casks.nix`/`brews.nix`) and installs at activation, but never upgrades or uninstalls (`onActivation.upgrade = false`, `cleanup = "none"`); ad-hoc installs remain free. Version currency rides the autoupdate agent daily and the full pass on demand — `brew update && brew upgrade && brew upgrade --cask && brew autoremove && brew cleanup --prune=all -s` — with `brew autoremove` and `brew cleanup` owning dead-dependency and cache pruning.
