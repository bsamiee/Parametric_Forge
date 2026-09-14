# Rails and Contracts

Forge rails ship as `writeShellApplication` commands; `forge-provision` also owns a schema-versioned JSON envelope. Each command's `--help` owns usage.

## [01]-[RAIL_SET]

| [INDEX] | [RAIL]            | [OWNS]                                                                  | [OWNER]                          |
| :-----: | :---------------- | :---------------------------------------------------------------------- | :------------------------------- |
|  [01]   | `forge-redeploy`  | The only sanctioned activation path                                     | `shell-tools/forge-redeploy.nix` |
|  [02]   | `forge-provision` | Docker/Compose DB estate: envelope, locks, generations, extension apply | `overlays/forge-provision/`      |

Owner paths resolve under `modules/home/programs/shell-tools/` unless the row names a repo root.

## [02]-[FORGE_REDEPLOY]

`forge-redeploy --check-only|--build|--switch` gates on `nix flake check` and the per-host toplevel build before any activation. Darwin builds and switches locally; NixOS check is eval-only, build proves closure, and switch runs locally on Linux or remotely through `nixos-rebuild --target-host --build-host` from Darwin. Activation consumes the already-built store path, and Cachix push failure cannot fail an already-switched deploy.

## [03]-[FORGE_PROVISION_ENVELOPE]

Raw source-tree execution exits `126`; the packaged command or `nix run .#forge-provision` carries the runtime closure. `schema_version` is `3`. `envelope-base.jq` owns the top-level shape, and `error-envelope.jq` preserves structural defaults on failure. `redact-message.jq` strips sensitive endpoints, paths, credentials, and tokens before output; agent-facing JSON carries only sanitized booleans and catalog metadata.

## [04]-[FORGE_PROVISION_CATALOG]

`data/commands.json` owns the verb catalog through `command-routes.jq`. Self-test binds each mutating verb to `lockMode:"mutation"`, `psql` to `lockMode:"psql-session"`, and other verbs to `lockMode:"none"`; mutation and psql sessions exclude each other. Endpoint locks are endpoint-hash scoped. Routes govern diagnostic JSON admission. Root resolution hashes `FORGE_PROVISION_ROOT` or the Git worktree into `root_key`; generations publish through an atomic `current` symlink. Catalog absence rejects a verb.

`up` is the full sequence: endpoint lock, active-project cap, busy-aware ports, owned-resource assertions, compose generation, `docker-compose up -d --remove-orphans --wait`, readiness, required-extension apply, generation publish, and volume-ledger render; a failed first-up preserves volumes. `down` removes owned containers and networks, keeping volumes; `prune --owned` removes volumes only with `--volumes`. `check` validates static env unlocked, `apply` runs the extension apply under the mutation lock, and a missing required extension surfaces `error.code="required-extension-unavailable"`.

## [05]-[DB_CONTAINER_ESTATE]

`data/services.json` owns Postgres service images, ports, and gates. `data/postgres-extensions.json` owns required extension rows and their environment selectors. DuckDB and SQLite tool surfaces derive from their extension catalogs and probe without Docker. `overlays/manifest.nix` owns the DuckDB and SQLean binary rows; `languages/db-tools.nix` owns DB clients, and `container-tools/default.nix` owns the container estate. Each new extension or service lands as one catalog row.

## [06]-[UPDATE_SEQUENCE]

One ordered pass refreshes every currency family; each step proves through its owning gate before the next starts, and the working tree is clean before the first mutation.

| [INDEX] | [FAMILY]     | [COMMAND]                                       | [PROOF]                                                       |
| :-----: | :----------- | :---------------------------------------------- | :------------------------------------------------------------ |
|  [01]   | working tree | scoped commits, push                            | `git status` clean                                            |
|  [02]   | flake inputs | `nix flake update`                              | `forge-redeploy --build`; commit `nix: bump flake inputs (…)` |
|  [03]   | nvfetcher    | `nix develop -c nvfetcher -o overlays/_sources` | build gate rides the switch                                   |
|  [04]   | activation   | `forge-redeploy --switch`                       | generation advances under `readlink /run/current-system`      |
|  [05]   | homebrew     | `brew update && brew upgrade`                   | `brew outdated --greedy` empty, nightly stamp current         |
|  [06]   | store        | `nix-collect-garbage -d`, `nix store optimise`  | single system generation, GC, optimise                        |

Flake bumps moving a native library poison the wheels a project's uv built against the old store path: `otool -L` over the venv's site-packages natives, each `/nix/store/*.dylib` tested, and `uv pip install --reinstall --no-cache` per hit from the project's own shell; a path still missing after the rebuild is a missing library row in `scientific-tools.nix`, never another rebuild.

Homebrew custody: nix-darwin's Brewfile installs missing roster entries while activation leaves versions and unlisted packages intact. Third-party entries use a fully qualified name with item-scoped `trusted = true`; official formulae and casks are intrinsically trusted. Homebrew currency runs `brew update`, upgrades, the `wezterm@nightly --greedy-latest` refresh (a `:latest` cask never reads outdated), `brew autoremove`, and `brew cleanup --prune=all -s`.
