# [KERNELS]

Machine-surface law extending `design.md` onto shell kernels: `writeShellApplication` bodies packaged from Nix and the standalone `.sh` surfaces. Apply when writing or reviewing any shell body; a finding cites the card it breaks.

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
