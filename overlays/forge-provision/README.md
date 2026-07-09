# [FORGE_PROVISION]

`forge-provision` owns local PostgreSQL provisioning on this machine: it mints per-project Docker Compose stacks, binds them to loopback, and answers every provisioning question through one schema-v3 JSON contract. Entry is the packaged command — `forge-provision <verb>` or `nix run .#forge-provision -- <verb>`; the script rejects source-tree execution, and consumer repos route through their own provision rail.

## [01]-[VERB_CONTRACT]

`data/commands.json` is the dispatch catalog: verb, handler, argspec, JSON capability, `mutates`, `lockMode`, and `--diagnostic-json` admission per row; `forge-provision help` renders it live.

- The mutating set is exactly `up`, `down`, `prune`, `apply`; each runs under the mutation lock and every other verb makes no durable write to the repo, the Docker runtime, or lock state beyond stale-lock recovery.
- `prune` binds to `--owned` and touches only resources labeled by this root, project, and instance; `--volumes` extends removal to owned data volumes, otherwise volumes survive every lifecycle verb including `down`.
- `psql` opens a session-capable client inside an owned service container: database writes are the operator's, provisioning state stays untouched, and the session lock blocks lifecycle mutation for its duration.
- `verify` and the `psql-<service>` forms are retired spellings; dispatch rejects them with a usage error, never an alias.
- Every verb is noninteractive and agent-first: no host `sudo`, no keychain prompt, no database password prompt, and no Docker credential helper — public images pull through an anonymous `DOCKER_CONFIG` the command provisions itself.

## [02]-[JSON_CONTRACT]

`--json` emits one schema-v3 envelope per invocation: `schemaVersion`, `command`, `ok`, `warnings`, `error`, `project`, `auth`, `portPolicy`, `services`, `ports`, `resources`, `artifacts`, `extensions`, `tools`. Failures emit the same envelope with `ok: false` and a populated `error` row, exit code preserved; `project` appears once identity resolution has succeeded.

- Envelopes carry sanitized runtime booleans, kinds, and catalog metadata only; sockets, Docker config paths, credential helper names, DSN passwords, mount paths, and host absolute paths never enter agent-facing JSON, and `redact_message` scrubs every error string.
- `--diagnostic-json` is admitted only for `doctor`, `paths`, and `inventory`; it adds redaction-marker fields, never raw values.
- `extensions.catalog` rows pass through `data/postgres-extensions.json`, `data/duckdb-extensions.json`, and `data/sqlite-extensions.json` unmodified; PostgreSQL rows additionally carry computed gate fields; the catalog files are the system of record for extension metadata.

## [03]-[IDENTITY]

- The provision root resolves from `FORGE_PROVISION_ROOT` or the enclosing Git worktree; `root_key` is the first twelve hex digits of the root path hash.
- The project key is `FORGE_PROVISION_PROJECT` when set (slug-validated), otherwise `<root-slug>-<root_key>`; `FORGE_PROVISION_INSTANCE` (default `default`) separates concurrent stacks of one project.
- The Compose project name is `forge-<project_key>-<instance>`, hash-truncated past 63 characters; every owned container, volume, and network carries the `dev.bsamiee.forge-provision.*` label set, and ownership assertions refuse any resource whose labels disagree.

## [04]-[STATE_AND_LOCKS]

- Durable artifacts live under `<root>/.artifacts/provisioning/forge/<project_key>/<instance>`: immutable generation directories, a `current` symlink published atomically after readiness and required-extension proof, `volume-ledger.json`, and the anonymous Docker config.
- Locks live under `${XDG_STATE_HOME:-~/.local/state}/forge-provision/locks`, project-scoped and endpoint-scoped; `lock_path` mints every location.
- One lock primitive (`lock_acquire`, `lock_recover_dead`, `lock_release_owned`) drives all four modes — `mutation`, `psql-session`, `port`, `endpoint` — with per-mode rows for owner metadata, heartbeat, and dead-owner liveness testing; stale locks recover only on the same host with a matching token, and ownerless directories expire after `FORGE_PROVISION_LOCK_TTL_SECONDS`.
- Mutation and psql sessions exclude each other in both directions; port and endpoint locks nest inside the mutation scope during `up`.

## [05]-[SERVICES_AND_PORTS]

`data/services.json` is the service catalog: image, host, container port, database name and user, volume mount, preload set, and enable gate per row. Compose rendering, DSNs, health checks, and readiness probes all read these rows.

- Published ports bind to the row's loopback host only; remote and non-Colima Docker endpoints are rejected on macOS unless `FORGE_PROVISION_ALLOW_NON_COLIMA_DOCKER=1`.
- Port policy `auto` derives a deterministic block from the endpoint, root, and project hash inside `FORGE_PROVISION_PORT_RANGE`, subtracting OS ephemeral ranges and `FORGE_PROVISION_PORT_EXCLUDE`; a published manifest pins ports across runs, and Docker bind conflicts retry the next deterministic block.
- Explicit ports come from `FORGE_PROVISION_PORT_BASE` or the full per-service `*_PORT` set; a partial set is a usage error.

## [06]-[EXTENSIONS]

PostgreSQL server extensions are Docker-owned by this command: `check` probes, `apply` and `up` create the admitted set inside the containers, and a failed required row blocks generation publish.

- `pgduckdb` is a whole service gated by `FORGE_PROVISION_PGDUCKDB=1`; `pg_cron` and `vectorscale` creation are row-gated behind `FORGE_PROVISION_PG_CRON=1` and `FORGE_PROVISION_VECTORSCALE=1`; every gate default is off.
- `tools` probes the host-side DuckDB and SQLite Forge surfaces against their catalogs without touching Docker.

## [07]-[ENVIRONMENT]

| [INDEX] | [VARIABLE]                                                                     | [OWNS]                                                         |
| :-----: | :----------------------------------------------------------------------------- | :------------------------------------------------------------- |
|  [01]   | `FORGE_PROVISION_ROOT`                                                         | Provision root override; otherwise the Git worktree resolves   |
|  [02]   | `FORGE_PROVISION_PROJECT` / `FORGE_PROVISION_INSTANCE`                         | Project key override and instance separation                   |
|  [03]   | `FORGE_PROVISION_AUTH`                                                         | `auto-root` (generated secret file) or `trust-loopback`        |
|  [04]   | `FORGE_PROVISION_PORT_POLICY` / `_PORT_RANGE` / `_PORT_EXCLUDE` / `_PORT_BASE` | Port allocation policy surface                                 |
|  [05]   | `FORGE_PROVISION_PGDUCKDB` / `_PG_CRON` / `_VECTORSCALE`                       | Analytics service gate; pg_cron and vectorscale creation gates |
|  [06]   | `FORGE_PROVISION_TIMESCALE_*` / `_SEARCH_*` / `_PGDUCKDB_*`                    | Per-service image and port overrides from `services.json` rows |
|  [07]   | `FORGE_PROVISION_LOCK_WAIT_SECONDS` / `_LOCK_TTL_SECONDS`                      | Lock acquisition deadline and stale-lock expiry                |
|  [08]   | `FORGE_PROVISION_COMPOSE_PARALLEL_LIMIT` / `_MAX_ACTIVE_PROJECTS`              | Compose parallelism and machine-wide project cap               |
|  [09]   | `FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS` / `_ALLOW_NON_COLIMA_DOCKER`           | Safety-gate overrides, default off                             |
|  [10]   | `FORGE_PROVISION_SHARE`                                                        | Packaged catalog share-directory override; packaging-internal  |
