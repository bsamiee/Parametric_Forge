# [NIX_DOCTRINE]

Machine-surface law extending the design doctrine onto Nix modules, shell kernels packaged from Nix, Lua runtime consumers, and generated declarative config. Nix owns packages, environment, vocabulary, and generated data; every other surface consumes projections of one Nix owner.

## [01]-[USE_WHEN]

Apply when writing or reviewing Nix modules, overlays, flake composition, `writeShellApplication` bodies, Lua configuration for editor or terminal hosts, and generated KDL, TOML, JSON, or Lua config. A finding cites the card it breaks.

## [02]-[MODULES]

[OWNER_MODULES]:

- Law: One module owns one concern; typed `submodule` options admit raw config once, and every consumer reads the owner's derived projections.
- Rejected: Wrapper modules around one option, untyped attrsets, stringly booleans, consumer-side validation, mixed system and user scope, scattered `home.file` writes.
- Example: `options.shape.rows = lib.mkOption { type = lib.types.attrsOf rowType; default = {}; };`

[ROW_DISPATCH]:

- Law: Dispatch is attrset and list algebra — `lib.mapAttrs`, `lib.genAttrs`, `lib.foldl'`, row-indexed builders — and growth lands as rows on the owning surface.
- Rejected: `if`/`else` ladders per package, per-host copies, sibling `mkFooA`/`mkFooB` helpers, splitting one dispatch family across files to meet a line target.
- Example: `lib.mapAttrs (_: row: pkgs.writeShellApplication row) rows`

[OVERLAYS]:

- Law: Overlays are package-admission seams: `final: prev:` rows admit upstream packages, apply minimal derivation changes, and expose canonical names.
- Rejected: Home Manager logic inside overlays, convenience wrapper packages, package aliases hiding behavior.
- Example: `final: prev: { shape = prev.shape.overrideAttrs (old: { postPatch = (old.postPatch or "") + patch; }); }`

[PACKAGE_MANIFEST]:

- Law: Non-nixpkgs package and extension admission is a manifest row — provenance, version policy, per-platform assets and hashes, license, patch family, cache class, update engine, retention, projection — and overlays, public packages, apps, HM rosters, and extension directories are folds of the rows. Direct-package projection is the default; an overlay-override row names its dependency-graph reason. Nixpkgs-followed admissions carry no frozen version copy — the JSON projection resolves live pins from the package set.
- Rejected: Version/url/hash triples inside derivation bodies, a second hand-maintained public package list, per-app plugin updater semantics, registry-trust admission of extension corpora, overlay mutation without a named graph reason.
- Example: `packages = lib.mapAttrs (name: _: forgePkgs.${name}) (lib.filterAttrs (_: row: row.projection.package or false) manifest.packages);`

[UPSTREAM_LAYOUT_GUARDS]:

- Law: Every install step that depends on upstream layout — a strip, a wrapper target, a conditional install branch — carries an existence guard that fails the build with a named drift error; a package's layout vocabulary is single-owner, read by consumers through `passthru` projections; a kernel file is admitted only when install logic differs — a data-only delta is a manifest row.
- Rejected: Silent `rm -rf` of expected paths (drift ships a fatter output), silent-skip wrapper guards (drift ships a thinner one), consumer-side re-spelling of package subpaths, branches upstream facts prove dead, registry-derived regex alternations without `lib.escapeRegex` and an empty-set guard.
- Example: `[ -x "$runtime/$tool" ] || { echo "patch_drift: $tool missing" >&2; exit 1; }`

[COMPOSITION_ROOT]:

- Law: The flake composition root admits inputs once, and `perSystem` derives packages, apps, checks, and the formatter from one package set.
- Rejected: Duplicated per-system package attrsets, host conditionals outside `perSystem`, ad hoc system strings inside modules.
- Example: `perSystem = { pkgs, ... }: { packages = lib.genAttrs names (n: pkgs.${n}); };`

[POLICY_ROWS]:

- Law: Closed policy rows replace flag clusters; a row carries package, command, environment, service shape, lock mode, and projection behavior together.
- Rejected: Boolean option clusters, `enableX`/`useY` knobs, mode strings that downstream code reconstructs into behavior.
- Example: `policies.primary = { mutates = false; render = row: builtins.toJSON row; };`

[IMPORTS_AND_PATHS]:

- Law: Imports are topology with minimal module parameters, and store paths stay symbolic through package references until terminal projection.
- Rejected: Kitchen-sink lambda args, `with pkgs;` at file level, hardcoded executable paths, PATH-sensitive commands, string interpolation before package ownership is fixed.
- Example: `command = "${pkgs.coreutils}/bin/true"; args = lib.escapeShellArgs row.args;`

[KERNELS_AND_RECEIPTS]:

- Law: Host mutation lives in named `writeShellApplication` kernels, and every Nix-produced command emits structured receipt fields — input owner, derived path, action, status, proof surface.
- Rejected: Evaluation-time shell guessing, shell fragments spread across config, build or activation output that only prints success text.
- Example: `pkgs.writeShellApplication { name = "shape"; runtimeInputs = [ pkgs.jq ]; text = script; }`

[BOTH_OS_EVAL]:

- Law: A module the shared home graph imports evaluates on every host; a platform-only package interpolation gates at eval (`lib.optionalString pkgs.stdenv.hostPlatform.isDarwin`) with a runtime emptiness guard, and an option defined under a platform-gated import is consumed cross-platform only through an `or` default. The static gate is the pair: the darwin system build AND the NixOS toplevel drv eval — `nix flake check` alone proves neither host's toplevel.
- Rejected: Darwin-only `pkgs.*` interpolated unconditionally in a both-OS module, cross-gate option reads without a default, a switch proven on one host standing in for the other's eval.
- Example: `tn = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin "${pkgs.terminal-notifier}/bin/terminal-notifier";`

## [03]-[SHELL_KERNELS]

[KERNEL_BODIES]:

- Law: Bash performs admission, subprocess execution, locks, traps, and exit discipline; `jq` owns JSON shape, filtering, projection, and envelope assembly.
- Rejected: Large Bash decision bodies, Bash loops transforming JSON, `awk` over structured payloads, regex extraction from JSON text, mutating loops computing domain projections.
- Example: `jq -n --arg verb "$verb" --argjson ok true '{verb:$verb, ok:$ok}'`

[CATALOG_DISPATCH]:

- Law: One generated catalog drives command dispatch; a verb row declares handler, mutability, lock mode, argspec, and JSON support, and the dispatcher applies lock and admission before the handler runs. Retired spellings fault with one replacement hint.
- Rejected: `if [[ $1 == ... ]]` forests, per-verb hand parsing, verb aliases, silent env-var fallbacks, locking decided inside handler bodies.
- Example: `handler="$(jq -r --arg v "$verb" '.[]|select(.verb==$v).handler' "$catalog")"`

[ENVELOPE_RAIL]:

- Law: Exit code plus one JSON envelope is the rail; every failure uses the same shape, and envelope builders emit only sanitized booleans, kinds, names, and row metadata.
- Rejected: Text-only errors, partial JSON on success only, raw sockets, host absolute paths, DSNs, or token material in agent-facing JSON, `sed` scrub passes over arbitrary output.
- Example: `jq -n --arg code "$code" --arg detail "$detail" '{ok:false,error:{code:$code,detail:$detail}}'`

[PARAMETERIZED_INPUT]:

- Law: Environment values admit at the top, defaults are named once, paths derive once, and argv arrays build through `mapfile` or `readarray`.
- Rejected: Inline paths, unquoted command strings, user or host literals, pattern-matched absolute paths.
- Example: `mapfile -t args < <(jq -r '.args[]' "$row_file")`

[RECEIPTS_AND_LOCKS]:

- Law: State touches append one typed receipt row each — timestamp, command, target, derived identity, result — and mutation runs under one lock primitive with row-selected scope, timeout, and stale-owner recovery.
- Rejected: Generic logs as proof, prose summaries as results, opportunistic lock files, per-command lock code, lockless mutation beside locked mutation.
- Example: `exec {lock_fd}>"$lock"; flock -w "$wait_s" "$lock_fd"`

[ADMITTED_SUBPROCESS]:

- Law: Every executable arrives through `runtimeInputs` or an absolute store path, and feature absence becomes a railed fault.
- Rejected: Calling tools undeclared in `runtimeInputs`, interactive shell functions, `which`-based discovery.
- Example: `runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.docker-client ];`

[PORTABLE_BODIES]:

- Law: A body projected to more than one OS is toolchain-owned — GNU coreutils, date, stat, and lsof come from `runtimeInputs`; time comes from shell primitives (`EPOCHSECONDS`, `printf '%(...)T'`) before any `date` fork; entrypoints that can launch under an ambient PATH guard the shell version and re-exec through the profile shell.
- Rejected: Bare `/usr/bin`, `/bin`, `/usr/sbin` tool paths outside platform-gated rows, BSD/GNU flag divergence resolved by hope, `date` forks for timestamps, version-sensitive constructs before the interpreter is proven.
- Example: `TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"`

[DELIMITED_PROJECTION]:

- Law: Multi-field vectors cross from `jq` into shell through a unit-separator join read with `IFS=$'\x1f'`; tab-delimited reads survive only when every non-terminal field is provably non-empty, because tab-IFS collapses consecutive delimiters and shifts columns.
- Rejected: `@tsv` piped into `IFS=$'\t' read` for rows with optional fields, whitespace-split reads of structured payloads, per-field `jq` forks over one snapshot.
- Example: `IFS=$'\x1f' read -r name kind detail < <(jq -r '[.name, .kind, .detail] | join("\u001f")' "$row")`

[FORK_DISCIPLINE]:

- Law: One projection per payload — a single `jq` program per JSON snapshot, a single `awk` pass per text stream; predicates project to JSON booleans through `--argjson`; descriptors allocate dynamically with `{fd}`; temps are trap-registered at creation and created beside their rename target for same-filesystem atomicity.
- Rejected: `sed | tr | head` chains per field, `grep -q` on the read end of a pipe under `pipefail`, string-built JSON booleans, hardcoded descriptor numbers, temp files in `$TMPDIR` renamed across filesystems, cleanup only on success paths, cleanup riding an EXIT trap across `exec` (the trap never fires — feed via process substitution or clean before the exec).
- Example: `read -r files bytes < <(awk '/^A:/ { a = $2 } /^B:/ { b = $2 } END { print a, b }' "$stats")`

[ERREXIT_SUSPENSION]:

- Law: `if ! { a; b; c; }` and every other errexit-suspension context runs its block unchained — a guarded multi-step block `&&`-chains its steps so a mid-block failure cannot be masked by a succeeding tail; a row producer feeding an absence-checked verifier fails on partial production.
- Rejected: Multi-statement blocks under `if !` relying on `set -e` inside, verifiers that inspect only rows that exist while the producer can drop rows silently.
- Example: `if ! { render_env && render_manifest && render_compose; }; then restore_generation; fi`

[EXPECTED_NONZERO]:

- Law: A probe whose non-zero exit is data — a no-match `grep`, `lsof` on a vanished holder, `tail` of a live-appended file mid-write — rails with an explicit `|| true` and the reader treats empty as the verdict; `jq` over live-appended JSONL admits rows through `fromjson?` so a torn tail line is skipped, never fatal.
- Rejected: An `|| true` on a mutation or one that conflates a real failure class with the expected-empty case, an unrailed probe killing the kernel under `set -e` + `pipefail`, retry loops papering over a torn read the rail admits cleanly.
- Example: `last="$(tail -1 "$feed" 2>/dev/null || true)"`

[DUAL_RECEIPTS]:

- Law: Mutating rails append a human TSV row and a JSONL sibling with identical envelope keys — `ts` and `surface` always, `result` on terminal receipts, `state` on transition receipts — and numerics enter the envelope as JSON numbers; doctor commands emit one typed row stream that renders both the human table and `--json`. A receipt trails the action it attests: multi-step rails emit `state=` transitions per landed step and `result=` only after the final step — a receipt written before its action is a standing lie under any downstream failure.
- Rejected: Human-only receipts on mutation, JSON shapes that differ from the TSV fields, quoted-string numerics, per-command envelope dialects, presentation logic forked from probe logic.
- Example: `jq -cn --arg ts "$ts" --arg surface "shape" --argjson rc "$rc" '{ts:$ts,surface:$surface,rc:$rc}' >>"${receipts%.log}.jsonl"`

## [04]-[LUA_CONSUMERS]

[PROJECTION_CONSUMER]:

- Law: Lua consumes Nix-generated vocabulary modules as typed tables and owns only editor or terminal runtime behavior; installation, paths, generated constants, and config files stay with Nix.
- Rejected: Private palettes, duplicated key rows, `io.open` parsing of generated text at startup, cross-tool doctrine or package lists defined in Lua.
- Example: `local palette = require("palette")`

[SETUP_OWNERS]:

- Law: One plugin or host surface gets one dense setup owner with row-derived command, key, and projection groups.
- Rejected: Many files each toggling one plugin field, scattered `setup` calls for one concern.
- Example: `require("shape").setup({ modes = modes, actions = actions })`

[TABLE_DISPATCH]:

- Law: Tables map modes, keys, actions, formatters, and callbacks; loops apply host APIs once, and closed mode families enumerate every supported case so an unknown mode faults at setup.
- Rejected: `if` ladders over mode strings, repeated keymap calls with copied opts, default fallthrough callbacks, partial action maps.
- Example: `for _, row in ipairs(rows) do vim.keymap.set(row.mode, row.key, row.action, row.opts) end`

[HOST_APIS]:

- Law: Host-native builders, setup tables, callback contracts, and state abstractions carry their own semantics; local code composes policy rows on top.
- Rejected: Reimplementing host semantics in Lua wrappers, manual globals tracking toggle state, autocmd stacks duplicating plugin lifecycle.
- Example: `local config = wezterm.config_builder()`

[BUILD_ONCE_CALLBACKS]:

- Law: Host callback-registration APIs (`wezterm.action_callback` and peers) register permanently per call — every action and handler builds once per config generation as a row projection; per-press choice logic lives inside the once-registered callback.
- Rejected: Callback construction inside press, open, or event bodies (each call leaks a registration), palette or selector entries rebuilt per invocation.
- Example: `local pick = wezterm.action_callback(function(win, pane) choose(rows, win, pane) end)`

[GENERATED_TABLE_FIDELITY]:

- Law: A Lua consumer of a Nix row table indexes the generated table directly, and every highlight group or host identifier a projection binds is verified against the plugin's real names from source.
- Rejected: Hand-written key mirrors of generated tables (the two-edit diff returns), theme roles bound to guessed group names (the binding fails silently forever), identity fields restated beside the row that derives them, kernel jq programs enumerating vocabulary keys instead of deriving via `to_entries`.
- Example: `for ft, row in pairs(rows) do lint.linters_by_ft[ft] = row.linters end`

[DETERMINISTIC_STARTUP]:

- Law: Packages and plugins arrive from Nix; Lua startup is deterministic and side-effect-light.
- Rejected: Runtime package installation, network fetches, bootstrap managers inside config.
- Example: `require("plugins.primary")`

## [05]-[GENERATED_CONFIG]

[PROJECTION_ONLY]:

- Law: Generated config is projection, never primary truth: one Nix owner declares vocabulary and policies, and generated files are terminal egress with deterministic ordering.
- Rejected: Hand-maintained JSON, TOML, or KDL beside equivalent Nix rows, comments restating source doctrine, generation history, or freshness notes inside generated files.
- Example: `xdg.configFile."shape/config.toml".source = (pkgs.formats.toml {}).generate "shape" cfg;`

[STRUCTURED_GENERATORS]:

- Law: Formats with a native generator use it; string templates survive only for host grammars generators cannot express, with every interpolated value typed and escaped before interpolation.
- Rejected: JSON or TOML through heredocs, manual quote escaping by convention, KDL fragments with repeated literals.
- Example: `(pkgs.formats.json {}).generate "shape" { rows = cfg.rows; }`

[ROW_RENDER_POLICY]:

- Law: Config rows carry their own render policy — kind, location, permissions, command, style — and renderers are pure folds over named, sorted rows.
- Rejected: One giant template with special-case interpolations, stateful render accumulation, order dependent on attrset accident.
- Example: `lib.concatMapStringsSep "\n" render (lib.sortOn (r: r.name) rows)`

[SELF_REWRITING_TARGETS]:

- Law: A generated config for an app that rewrites its own file merges by ownership class — declared keys win, app-persisted keys survive, unknown roots pass through — and the activation lints the exact staged bytes with the app's own validator before they reach the live file, failing the switch with a named error.
- Rejected: Enumerated `has()` preservation lists (a clobber list waiting for the app's next persisted key), wholesale replacement of a live file carrying operator GUI state, staging unvalidated bytes into a config whose schema error yields a silently dead surface.
- Example: `jq -s '(.[0] | del(.profiles)) + { profiles: mergedProfiles }' "$live" "$staged"`

[TOKEN_OWNERS]:

- Law: Theme, color, and keybinding vocabularies have one owner each; palette roles, ANSI projections, chord rows, labels, and every per-app rendering derive from it.
- Rejected: Private hex values in app configs, chord rows copied between KDL, Lua, and shell, label drift between UI and action.
- Example: `renderBind = r: ''bind "${r.key}" { ${r.action} }'';`

[TYPED_EDGE]:

- Law: Config schemas are typed at the Nix edge — `strMatching`, `enum`, `attrsOf submodule`, `listOf`, package path values — before any rendering.
- Rejected: Arbitrary strings accepted for percent geometry, enum modes, colors, or command names.
- Example: `type = lib.types.strMatching "^[0-9]+%$";`

[SHARED_ROW_FEEDS]:

- Law: One row owner feeds both generated config and derived script arguments, and file locations belong to XDG or Home Manager owners.
- Rejected: CLI flags hardcoded in shell while config renders from different literals, scripts writing configs into `$HOME` at runtime, interactive grants as runtime setup.
- Example: `args = lib.escapeShellArgs [ row.x row.y row.width row.height ];`

## [06]-[SERVICE_AGENTS]

[AGENT_IDENTITY]:

- Law: Repo-owned launchd jobs carry an explicit estate label under one reverse-DNS prefix and log stdout and stderr to one log root per surface; jobs generated by upstream modules or taps keep their generator's label. Identity follows the generator that owns the plist.
- Rejected: Mixed label namespaces across repo-owned jobs, generator-default labels on repo-owned rows, per-job log destinations, stderr-only logging, log files under cache or state directories.
- Example: `Label = "com.<estate>.<agent>"; StandardOutPath = "~/Library/Logs/<estate>-<agent>.log";`

[AGENT_LIFECYCLE]:

- Law: `KeepAlive = true` implies launch-at-load, so the pair never coexists; every row declares `ProcessType` (`Background` for schedulers and supervisors, `Interactive` for user-facing compute); scheduled work uses calendar triggers for wake coalescing; the writer of a state change kickstarts its consumer; intentional shutdown of a keep-alive agent is `bootout`, and an agent whose TERM handler tears down real state pins `ExitTimeOut` past its worst-case drain — the 20-second default SIGKILLs the teardown mid-flight and orphans the state it supervises.
- Rejected: `RunAtLoad` beside `KeepAlive = true`, rows without `ProcessType`, `StartInterval` for wall-clock schedules, `WatchPaths` as an event source, in-band stop commands against keep-alive supervisors, default `ExitTimeOut` on agents owning slow-drain teardowns.
- Example: `KeepAlive = true; ThrottleInterval = 30; ProcessType = "Background";`

[DUAL_OS_ROWS]:

- Law: One row registry projects both supervisors — launchd agents on Darwin, lingering systemd user services on Linux — running the identical packaged body; launchd attributes stay platform-gated, and both OS toplevels evaluate green as the gate for every row change.
- Rejected: Darwin-only service definitions for dual-OS capabilities, forked supervisor bodies per platform, top-level attribute names depending on `pkgs` inside the platform gate.
- Example: `launchd.agents = lib.mapAttrs' mkAgent rows;` beside `systemd.user.services = lib.mapAttrs' mkService rows;`
