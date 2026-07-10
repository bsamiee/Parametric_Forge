---
name: coding-bash
description: >-
    Use for Bash 5.2+/5.3 scripts, shell CLIs, entrypoints, CI jobs, cron,
    text-processing pipelines, ShellCheck remediation, and shell reviews —
    "write a shell script", "fix this bash", "make a CLI wrapper".
    Enforces strict mode, dispatch-table routing, fork-minimal primitives,
    atomic I/O, signal-safe cleanup, and pragmatic functional shell patterns.
---

# [CODING_BASH]

All code follows five governing principles:

- [FUNCTIONAL] — immutable locals, pure functions, dispatch tables, and tightly bounded mutable shell state
- [POLYMORPHIC] — one parser, one dispatcher, one logger; extend via table entries not code branches
- [PRODUCTION_HARDENED] — ERR traps, atomic I/O, signal forwarding, cleanup registries, version gating
- [FORK_MINIMAL] — `printf -v`, `$(<file)`, `EPOCHSECONDS`, fork-free `${ }` substitution (5.3), `BASH_MONOSECONDS` monotonic timing, `mapfile` over subshell patterns
- [ECOSYSTEM_FIRST] — `rg`/`fd`/`jq`/`sd`/`choose`/`mlr` over sed/grep/find/cut when available
- [EXECUTABLE_DOCTRINE] — examples and templates must pass syntax, ShellCheck, and their own self-tests

## [01]-[ROUTING]

[FOUNDATION]: every task loads [bash-scripting-guide.md](references/bash-scripting-guide.md) — primitives, strict mode, expansion, arrays.

[TASK_ROUTED]: load only when the task matches.

- [01]-[VERSION_FEATURES](references/version-features.md): 5.2/5.3 features, fork-free substitution, version gating
- [02]-[VARIABLE_FEATURES](references/variable-features.md): call stacks, namerefs, traps, process lifecycle, 5.3 vars
- [03]-[ARRAY_OPERATIONS](references/array-operations.md): set algebra, structural transforms, higher-order traversal
- [04]-[STRING_OPERATIONS](references/string-operations.md): transform pipelines, regex extraction, codecs, templates
- [05]-[FILE_OPERATIONS](references/file-operations.md): atomic writes, FD multiplexing, directory traversal
- [06]-[SCRIPT_PATTERNS](references/script-patterns.md): arg parsing, help, ERR traps, parallel, retry
- [07]-[BASH_LOGGING](references/bash-logging.md): structured logging, CI integration, tracing
- [08]-[BASH_TESTING](references/bash-testing.md): bats-core `1.13+` suites, coverage, hypothesis PBT
- [09]-[BASH_PORTABILITY](references/bash-portability.md): cross-shell compat, containers, POSIX
- [10]-[TEXT_PROCESSING_GUIDE](references/text-processing-guide.md): rg/awk/sd/jq/yq/mlr tool selection
- [11]-[VALIDATION](references/validation.md): ShellCheck codes, static analysis, CI

[EXAMPLES]: read the one matching the target archetype before writing.

- [01]-[CLI_TOOL](examples/cli-tool.sh): two-dimensional verb:resource dispatch CLI
- [02]-[DATA_PIPELINE](examples/data-pipeline.sh): file processing with jq pipelines, accumulation
- [03]-[SERVICE_WRAPPER](examples/service-wrapper.sh): container entrypoint, signal dispatch, coproc

[TEMPLATE]: scaffold a new script from [standard.template.md](templates/standard.template.md) — strict-mode header, logging, cleanup stack, traps, flag parsing, self-test.

## [02]-[PARADIGM]

- [IMMUTABILITY]: `local -r` for all non-mutating function locals, `readonly` for module-level constants. Mutable state only for argument parsing — frozen via `readonly` in `_main` before core logic
- [DISPATCH_TABLES]: `declare -Ar` for O(1) command routing, two-dimensional `verb:resource` keyed dispatch, option metadata, validation rules, log-level gating, env contract validation (regex patterns per env var). `case/esac` reserved exclusively for glob/regex pattern matching — never conditional routing
- [PURE_FUNCTIONS]: Input via positional parameters, output via stdout or nameref (`local -n`). No global reads except `readonly` constants. Side effects isolated to `_main`, trap handlers, cleanup registries, and explicitly marked shell boundary loops
- [METADATA_DRIVEN_HELP]: `_OPT_META` with `short|long|desc|VALUE_NAME|default` entries generates `_usage` programmatically. One table entry + one `case` branch per option
- [MIDDLEWARE_COMPOSITION]: `_use()` registers middleware functions into `_MIDDLEWARE` array; `_run_with_middleware()` executes the chain before handler dispatch. Argument parsing in 3 composable phases — subcommand dispatch (O(1) table lookup), flag parsing (case/esac), positional collection
- [EXPRESSION_OVER_STATEMENT]: `${var:-default}` over if-empty checks, `${var:?message}` over assert-not-empty, `(( expr ))` over `test`, parameter expansion over external commands
- [FORK_ELIMINATION]: `printf -v var '%(%F %T)T' -1` over `$(date)`, `$(<file)` over `$(cat file)`, `EPOCHSECONDS`/`EPOCHREALTIME` over `$(date +%s)`, `mapfile` over `while read` loops, `BASH_REMATCH` over `grep -oP`
- [ATOMIC_IO]: All file writes via `mktemp` + write + `mv` (rename is atomic on same filesystem). `umask 077` before `mktemp` for sensitive data. Dynamic FDs via `exec {fd}>file`

## [03]-[CONVENTIONS]

[ECOSYSTEM_TOOL_SELECTION]: prefer the ecosystem's richer alternative when available:

| [INDEX] | [TASK]           | [PREFERRED] | [FALLBACK]         | [NEVER]               |
| :-----: | :--------------- | :---------- | :----------------- | :-------------------- |
|  [01]   | File search      | `fd`        | `find`             | `ls -R`               |
|  [02]   | Content search   | `rg`        | `grep -rn`         | `find -exec grep`     |
|  [03]   | JSON             | `jq`        | `python3 -c`       | `sed`/`awk` on JSON   |
|  [04]   | YAML             | `yq eval`   | `python3 -c`       | `sed` on YAML         |
|  [05]   | CSV/TSV          | `mlr`       | `awk -F`           | `cut` for multi-field |
|  [06]   | Stream edit      | `sd`        | `sed`              | `awk` for simple sub  |
|  [07]   | Column select    | `choose`    | `awk '{print $N}'` | `cut -d`              |
|  [08]   | Interactive JSON | `jnv`       | `jq`               | --                    |

[SELECTION_RULES]:

- Probe availability via `command -v` before use; fall back gracefully
- `rg`/`fd` integrate with `.gitignore` by default — prefer for repo-aware searches
- `jq` is mandatory for JSON — never parse JSON with sed/awk/grep
- `mlr` handles format conversion (CSV to JSON, TSV to JSON) natively
- Pipeline preference: single `awk` program over chained `grep | sed | cut`

## [04]-[CONTRACTS]

[VARIABLE_DISCIPLINE]:

- `local -r` for all non-mutating function locals. `readonly` for all module-level constants.
- Mutable state (parsed args, log level) declared at module level, frozen via `readonly` in `_main` before core logic.
- `declare -Ar` for all dispatch tables, option metadata, and lookup maps.
- `local -n` (nameref) for passing arrays to functions — never `eval` or indirect expansion.
- Nameref return channels: scalar-returning functions take result var as last arg (`_ext "$item" key`) and write via `printf -v "$2"` or `local -n` — callers pass a name, never `$()`. Multi-return via multiple namerefs (e.g., `_project_meta "$slug" name created`).
- Naming: `UPPER_SNAKE` for constants/env, `lower_snake` for locals/functions, `_` prefix for internal functions.

[CONTROL_FLOW]:

- `case/esac` for pattern matching (globs, regexes) only — never for if/elif-style routing.
- `declare -Ar` dispatch tables for command routing: `"${_DISPATCH[${cmd}]}" "${args[@]}"`. Nest for subdomains: `_CONFIG_SUBCMDS`, `_INIT_SUBCMDS`.
- `[[ ]]` over `[ ]`. `(( ))` for arithmetic. `&&`/`||` for short-circuit.
- `mapfile -t` / `readarray -d ''` over `while read` loops for collection. Streaming consumers may use `while IFS= read -r` with a comment naming the stream boundary.
- Ternary via arithmetic: `(( condition )) && action1 || action2` or `${var:+if_set}${var:-if_unset}`.
- Bounded concurrency: `wait -n -p finished_pid` with job-count gate `(( ${#jobs[@]} >= MAX_JOBS ))` — see `_run_pool` pattern in examples.
- Shell reality exceptions must be explicit: option parsing uses `case`; cleanup stacks may use a static `eval` template over shell-quoted commands; bounded counters and polling loops may mutate when the mutation is the resource protocol.

[ERROR_HANDLING]:

- `set -Eeuo pipefail` + `shopt -s inherit_errexit` in every script. No exceptions.
- ERR trap with `BASH_COMMAND`, `BASH_LINENO`, `FUNCNAME` context. Stack trace for multi-level call chains.
- `_CLEANUP_STACK` LIFO registry invoked by EXIT trap. `_CLEANING` guard prevents re-entrant execution on cascading signals.
- Exit codes: 0=success, 1=general error, 2=usage error. Custom codes in `EX_*` constants.
- `_die()` for fatal errors (log + exit). `_die_usage()` for argument errors (log + hint + exit 2).
- Timing rule: `BASH_MONOSECONDS` (`5.3+`) for elapsed-time durations — monotonic, immune to NTP drift, zero forks. `EPOCHREALTIME` only for absolute timestamps and microsecond-precision benchmarks (`_bench()` shape: `(end_s - start_s) * 1000000 + 10#end_us - 10#start_us`). See `references/version-features.md` for version-safe `BASH_MONOSECONDS` / `EPOCHREALTIME` fallback dispatch.

[LOGGING_ARCHITECTURE]:

- `declare -Ar _LOG_EMIT=([json]=_log_json [text]=_log_text_emit)` — format resolved once at startup via `readonly _LOG_EMITTER="${_LOG_EMIT[${LOG_FORMAT:-text}]}"`.
- `_log()` gates on `_LOG_LEVELS` numeric threshold, then dispatches via `"${_LOG_EMITTER}"` — zero branching per call.
- JSON emitter: `jq -nc --arg` for injection-safe serialization with `EPOCHREALTIME` microsecond timestamps and optional W3C trace context fields.
- `FUNCNAME` offset accounts for `_info` -> `_log` -> `_LOG_EMITTER` call chain depth (typically `FUNCNAME[3]`, `BASH_LINENO[2]`).

[SURFACE]:

- `_` prefix for all internal functions. Public surface = `_main` entry point only.
- One dispatch table per concern — extend by adding entries, not code branches.
- No utility/helper files — colocate all logic in the script. `source` only for test frameworks.
- `--self-test` flag runs embedded smoke tests and exits — validates dispatch tables, config parsing, and key pure functions.
- ~350 LOC scrutiny threshold — investigate compression via dispatch tables and awk programs, not file splitting.

[RESOURCES]:

- Temporary files: `mktemp` + `_register_cleanup "rm -f -- $(printf '%q' "${tmp}")"` or equivalent static quoted cleanup template. Work directories: `mktemp -d` with `SRANDOM` in path for uniqueness.
- Signal forwarding for PID 1: trap TERM/INT, `kill -"${sig}" "${_CHILD_PID}"`, exit with signal code (143/130). Guard on `(( _CHILD_PID > 0 ))`.
- On 5.3, `BASH_TRAPSIG` enables a unified signal handler with dispatch-table routing by signal number.
- `GLOBSORT` controls glob ordering (e.g., `-mtime` for newest-first file discovery).
- Retry: `_retry_exec max delay max_delay cmd...` — exponential backoff `delay=$(( delay * 2 > max_delay ? max_delay : delay * 2 ))` with `SRANDOM` jitter.
- Env contracts: `declare -Ar _ENV_CONTRACT=([VAR]='^regex$')` validated at startup — dispatch table over env vars, regex per key.
- Health endpoint: `socat TCP-LISTEN:${port},reuseaddr,fork SYSTEM:"printf 'HTTP/1.1 200 OK\r\n...'"` backgrounded with cleanup registration.
- W3C tracing: parse `TRACEPARENT` via `BASH_REMATCH`, generate via `printf -v TRACE_ID '%08x%08x%08x%08x' "${SRANDOM}"...`, export for child propagation.

## [05]-[ANTI_PATTERNS]

[STATE_VIOLATIONS]:

- MUTABLE STATE: `let`/global mutation outside `declare -g` config loading. Use `local -r`/`readonly`; freeze parsed args in `_main`.
- FORK IN HOT PATH: `$(date)`, `$(cat file)`, `$(wc -l < file)` in loops. Use `printf -v`, `$(<file)`, `EPOCHSECONDS`, `mapfile`.

[CONTROL_FLOW_VIOLATIONS]:

- IMPERATIVE DISPATCH: `if/elif/else` chain for command routing. Use `declare -Ar` dispatch table + O(1) lookup.
- WHILE-READ COLLECTION: `while IFS= read -r line` loop to build arrays. Use `mapfile -t arr < <(cmd)`.
- UNMARKED STREAM LOOP: `while read` without a streaming-boundary comment. Streaming consumers are valid; collection loops are not.
- NAKED WRITE: Direct `>` or `>>` for output files. Use `mktemp` + `mv` atomic pattern.

[SAFETY_VIOLATIONS]:

- HARDCODED FD: `exec 3>file` with literal FD numbers. Use `exec {fd}>file` for safe dynamic allocation.
- UNQUOTED EXPANSION: `$var` without quotes. Always `"${var}"` — exceptions only in `(( ))` arithmetic.
- EVAL INJECTION: `eval "$user_string"` with untrusted input. Only static cleanup/capture templates over shell-quoted values are allowed; otherwise use `declare -Ar` dispatch or `case/esac` pattern match.
- ECHO OVER PRINTF: `echo -e`/`echo -n` for formatted output. Use `printf` — portable, no ambiguity, format strings.

[ORGANIZATION_VIOLATIONS]:

- UTILITY EXTRACTION: `lib/utils.sh`, `common.sh` helper files. Colocate all logic in the script.
- RANDOM OVER SRANDOM: `$RANDOM` for security-relevant randomness (temp names, jitter, tokens). Use `$SRANDOM` (cryptographic entropy).

## [06]-[VALIDATION_GATE]

- Required: `bash -n script.sh` (syntax check), ShellCheck `0.11.0+` clean (static analysis).
- Required for executable examples: run `--self-test` when present.
- Reject completion when strict mode, readonly discipline, ShellCheck compliance, or example self-tests are not satisfied.

## [07]-[SKILL_EVAL_PROMPTS]

- Explicit invocation: "Using coding-bash, refactor this .sh CLI into dispatch-table Bash 5.3 style with self-tests."
- Implicit invocation: "Review this deployment script for ShellCheck, strict mode, cleanup, and streaming-loop issues."
- Noisy context: "Ignore CI chatter and only audit the Bash entrypoint."
- Negative control: "Only write PostgreSQL DDL." Expected: do not load Bash references unless shell code appears.
- Compliance checks: output loads only relevant references, avoids command thrash, avoids helper files, preserves marked shell-reality exceptions, and runs `bash -n`, ShellCheck, and `--self-test` when applicable.

## [08]-[FIRST_CLASS_TOOLS]

| [INDEX] | [TOOL]       | [VER]    | [PROVIDES]                                 |
| :-----: | :----------- | :------- | :----------------------------------------- |
|  [01]   | `bash`       | 5.2+/5.3 | Shell runtime, builtins, `${ }` (5.3)      |
|  [02]   | `shellcheck` | 0.11.0+  | Static analysis, SC codes                  |
|  [03]   | `bats-core`  | 1.13+    | Test framework, TAP output                 |
|  [04]   | `kcov`       | 43+      | Coverage instrumentation                   |
|  [05]   | `rg`         | 15+      | Content search, `.gitignore`-aware         |
|  [06]   | `fd`         | 10+      | File search, `.gitignore`-aware            |
|  [07]   | `jq`         | 1.8+     | JSON processing, streaming, `trim`, `skip` |
|  [08]   | `yq`         | 4.46+    | YAML processing                            |
|  [09]   | `mlr`        | 6+       | CSV/TSV/JSON format transforms             |
|  [10]   | `sd`         | 1+       | Stream editing (sed replacement)           |
|  [11]   | `choose`     | 1.3+     | Column selection (cut replacement)         |
|  [12]   | `gawk`       | 5.3+     | Text processing, inline programs           |
