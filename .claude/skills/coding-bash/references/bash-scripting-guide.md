# [BASH_SCRIPTING_GUIDE]

Bash `5.2+`/5.3 language reference: strict-mode composition, parameter-expansion chains, array and nameref data structures, and fork-free native builtins.

## [01]-[STRICT_MODE]

```bash conceptual
#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit extglob nullglob
IFS=$'\n\t'
```

| [INDEX] | [FLAG]            | [MECHANISM]                                                                           |
| :-----: | :---------------- | :------------------------------------------------------------------------------------ |
|  [01]   | `set -e`          | Exit on non-zero — IGNORED inside `&&`/`\|\|`, arithmetic, negation                   |
|  [02]   | `set -E`          | Propagate ERR trap into functions/subshells — without it, `-e` exits WITHOUT trapping |
|  [03]   | `set -u`          | Unset var is fatal — `${arr[@]}` on empty array fails (use nullglob)                  |
|  [04]   | `set -o pipefail` | Pipeline returns rightmost non-zero — `false \| true` returns 0 without it            |
|  [05]   | `inherit_errexit` | `-e` propagates INTO `$()` — `x=$(false; printf 'ran')` assigns silently without it   |
|  [06]   | `extglob`         | `+(pat)`, `?(pat)`, `!(pat)`, `@(pat)` — required for `${var%%+([[:space:]])}`        |
|  [07]   | `nullglob`        | Unmatched glob → empty (not literal) — prevents iterating `*.xyz` as string           |

`set -E` vs `set -e`: `-e` kills the script but `-E` ensures the ERR trap fires first for stack trace context. Without `-E`, function failures bypass the trap — silent exit, no diagnostics. `inherit_errexit` closes the `$()` loophole: `local -r x="$(failing_cmd)"` silently succeeds without it because subshells do NOT inherit `-e` by default.

## [02]-[BASH_5_2_5_3]

| [INDEX] | [FEATURE]         | [SYNTAX]                         | [PURPOSE]                                    |
| :-----: | :---------------- | :------------------------------- | :------------------------------------------- |
|  [01]   | Case transform    | `${var@U}` `${var@u}` `${var@L}` | Upper/ucfirst/lower (replaces `tr`)          |
|  [02]   | EPOCHSECONDS      | `${EPOCHSECONDS}`                | Integer epoch (replaces `$(date +%s)`)       |
|  [03]   | EPOCHREALTIME     | `${EPOCHREALTIME}`               | Microsecond epoch (elapsed-time diffs)       |
|  [04]   | SRANDOM           | `${SRANDOM}`                     | 32-bit cryptographic random (getentropy)     |
|  [05]   | `wait -f`         | `wait -f PID`                    | Wait even without job control (5.2+)         |
|  [06]   | Dynamic FDs       | `exec {fd}>file`                 | Kernel-assigned descriptor (no hardcoded 3)  |
|  [07]   | Fork-free sub     | `${ cmd; }`                      | Stdout capture without fork (5.3)            |
|  [08]   | REPLY sub         | `${\| cmd; }`                    | Current shell, result via REPLY (5.3)        |
|  [09]   | GLOBSORT          | `GLOBSORT=name`                  | Glob sort by name/size/mtime/nosort (5.3)    |
|  [10]   | BASH_MONOSECONDS  | `${BASH_MONOSECONDS}`            | Monotonic seconds — immune to NTP/clock skew |
|  [11]   | array_expand_once | `shopt -s array_expand_once`     | `${arr[@]}` expands once, not recursively    |
|  [12]   | lastpipe          | `shopt -s lastpipe`              | Pipeline-final cmd runs in current shell     |
|  [13]   | Loadable builtins | `enable -f ... sleep`            | Fork-free `sleep`/`seq`/`strftime` in loops  |

Fork-free command substitution (`${ cmd; }` / `${| cmd; }`) drops the fork+exec that `$(cmd)` requires, making every hot-path `$()` zero-cost.

```bash conceptual
# Fork-free substitution (5.3) — version-gate for portability
(( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 3) )) && {
    name=${ printf '%s-%s' "${prefix}" "${suffix}"; }        # stdout capture, no fork
    ${| REPLY="${prefix}-${suffix}"; }                        # REPLY assignment, no fork
}
# Loadable builtins — eliminate fork+exec for sleep/seq/strftime in tight loops (>1000 iters)
# Package: bash-builtins (Debian/Ubuntu), bash (Homebrew). Availability varies by distro.
_load_builtin() { enable -f "${BASH_LOADABLES_PATH:-/usr/lib/bash}/$1" "$1" 2>/dev/null; }
_load_builtin sleep; _load_builtin strftime    # builtin sleep/strftime now fork-free
# lastpipe: pipeline results in calling scope
shopt -s lastpipe
command | mapfile -t arr       # arr is in calling scope, not lost to subshell
```

## [03]-[PARAMETER_EXPANSION]

```bash conceptual
# --- defaults and guards ---
${var:-default}              # Default if unset/empty
${var:=default}              # Assign default if unset/empty
${var:?error}                # Exit with error if unset/empty
${var:+alt}                  # Use alt if set and non-empty

# --- stripping and slicing ---
${var#pat}  ${var##pat}      # Remove prefix (shortest/longest)
${var%pat}  ${var%%pat}      # Remove suffix (shortest/longest)
${var/pat/rep}               # Replace first
${var//pat/rep}              # Replace all
${var:off:len}               # Substring
${#var}                      # Length

# --- case transformation (5.2+) ---
${var^^}  ${var,,}           # Uppercase/lowercase all
${var^}   ${var,}            # Uppercase/lowercase first char
${var@U}  ${var@L}           # Uppercase/lowercase all (@ operator form)
${var@u}                     # Uppercase first char only

# --- introspection ---
${var@Q}                     # Shell-quoted (safe for re-eval)
${var@A}                     # Assignment form (declare -r var='value')
${var@a}                     # Attribute flags (r=readonly, a=array, A=assoc)

# --- nested expansion chains ---
# file="/path/to/file.backup.tar.gz"
${file##*/}                  # file.backup.tar.gz (basename)
${file%.*}                   # /path/to/file.backup.tar (strip one ext)
${file%%.*}                  # /path/to/file (strip all extensions)
${file%/*}                   # /path/to (dirname)

# Chain expansions to compose transforms:
local -r raw="  Hello World  "
local -r trimmed="${raw##+([[:space:]])}"          # Left-trim (requires extglob)
local -r clean="${trimmed%%+([[:space:]])}"        # Right-trim
local -r slug="${clean// /-}"                      # Spaces to hyphens
local -r lower="${slug@L}"                         # Lowercase: hello-world
# Pattern substitution on arrays (bulk transform, no loop)
local -ra files=("a.log" "b.log" "c.log")
printf '%s\n' "${files[@]/#/backup/}"              # Prefix: backup/a.log ...
printf '%s\n' "${files[@]/%.log/.bak}"             # Suffix swap: a.bak ...
```

## [04]-[BRANCHING]

| [INDEX] | [PATTERN]                                     | [STYLE]                   |
| :-----: | :-------------------------------------------- | :------------------------ |
|  [01]   | `${var:-default}` `${var:+alt}` `${var:?err}` | Parameter expansion       |
|  [02]   | `(( count > 0 )) && action`                   | Arithmetic guard          |
|  [03]   | `[[ "$var" == pat ]] && action \|\| other`    | Pattern guard             |
|  [04]   | `case/esac`                                   | Multi-branch pattern only |
|  [05]   | `declare -Ar TABLE=(...); "${TABLE[$k]}"`     | O(1) dispatch table       |

```bash conceptual
# case/esac: ONLY for pattern matching (globs, extglobs, regex)
case "${file}" in
    *.tar.@(gz|bz2|xz)) _extract_archive "${file}" ;;
    *.@(json|yaml))      _parse_config "${file}" ;;
    *)                   _die "Unsupported: ${file}" ;;
esac
# Dispatch table and arithmetic: see [07]-[DATA_STRUCTURES], [08]-[ARITHMETIC]
```

## [05]-[VARIABLES_AND_ARRAYS]

```bash conceptual
readonly MAX_RETRIES=3                              # Module-level: UPPER, readonly
local -r base_dir="/opt"                            # Function-level: lowercase, local -r
local -n ref=$1                                     # Nameref: alias to caller's variable
printf -v timestamp '%(%F %T)T' -1                  # Assign timestamp (no subshell)

# --- indexed arrays ---
local -ra items=("one" "two" "three")
"${items[0]}" "${items[@]}" "${#items[@]}" "${!items[@]}"  # element, all, count, indices

# --- collection ---
mapfile -t lines < file.txt                         # File into array (replaces while-read)
mapfile -d '' -t files < <(fd -e txt --print0)      # Null-delimited (safe for spaces)

# --- associative arrays ---
declare -Ar map=([k1]="v1" [k2]="v2")
"${map[k1]}" "${!map[@]}" [[ -v map[k1] ]]          # Access, keys, existence check

# --- bulk array transforms (no loops) ---
"${items[@]/#/prefix-}"                             # Prefix every element
"${items[@]/%/.log}"                                # Suffix every element

# --- variable introspection ---
declare -p arr map 2>/dev/null                      # Debug dump (type-aware)
"${!APP_@}"                                         # List all vars with prefix APP_

# --- NO_COLOR compliance (https://no-color.org) ---
# NO_COLOR existence test — any value including empty disables color
local -r _nc="${NO_COLOR+set}"
[[ -z "${_nc}" ]] && [[ -t 2 ]] && _enabled=1       # Respect spec before tput

# --- env contract validation (declare -Ar as schema) ---
declare -Ar _ENV=([SERVICE_NAME]='^[a-zA-Z][a-zA-Z0-9_-]+$' [DB_URL]='.+')
local var pat; for var in "${!_ENV[@]}"; do
    pat="${_ENV[${var}]}"; [[ -v "${var}" ]] || _die "Missing: ${var}"
    [[ "${!var}" =~ ${pat} ]] || _die "Invalid ${var}='${!var}'"
done

# --- non-blocking stdin detection ---
read -t 0 && read -r piped_input                    # Check if stdin has data

# --- dynamic file descriptor allocation ---
exec {fd}>"${lock_file}"                            # Kernel assigns next free FD
flock -n "${fd}" || _die "Already running"
exec {fd}>&-                                        # Release FD
```

[CONTROLLED_GLOBAL_MUTATION]: `declare -g` is the single escape hatch. Use exclusively for config loading; validate key names against `^[A-Za-z_][A-Za-z_0-9]*$` before `declare -g "${key}=${value}"`.

## [06]-[NAMEREFS]

```bash conceptual
# Return scalar via nameref (zero-fork alternative to $(subshell))
_compute() {
    local -n _result=$1
    _result="$(expensive_operation)"                # Assigns directly into caller's variable
}
local output; _compute output; printf '%s\n' "${output}"
# Return array via nameref (null-delimited for safe filenames)
_collect() {
    local -n _out=$1
    readarray -d '' -t _out < <(fd -e sh --print0)
}
local -a scripts; _collect scripts
# Higher-order: apply function to each element via nameref
_apply() {
    local -r func="$1"; local -n _items=$2
    local item; for item in "${_items[@]}"; do "${func}" "${item}"; done
}
# Pseudo-generic accumulator: builds result into caller's variable
_reduce() {
    local -r func="$1"; local -n _acc=$2; local -n _src=$3
    local item; for item in "${_src[@]}"; do "${func}" _acc "${item}"; done
}
```

[NAMEREF_GOTCHAS]:
- [NAME_COLLISION]: `local -n ref=ref` is undefined; same-name shadowing causes self-reference. Convention: `_` prefix on all nameref locals (`_result`, `_out`, `_items`).
- [ARRAY_CONSTRAINT]: `local -na` is invalid. Namerefs CAN reference arrays (`local -n _arr=my_array; ${_arr[@]}`), but cannot be declared as arrays.
- [SCOPE]: Namerefs resolve at the call site's scope, not the declaration site — this is why they work for returning values up the call stack.

## [07]-[DATA_STRUCTURES]

```bash conceptual
# Dispatch table: see [04]-[BRANCHING]
# Associative set (O(1) membership test)
declare -Ar VALID_EXTS=([txt]=1 [log]=1 [csv]=1)
[[ -v VALID_EXTS["${ext}"] ]] || _die "Unsupported: ${ext}"
# Option metadata table (declarative help generation)
declare -Ar _OPT_META=(
    [h]="-h|--help|Show help||"
    [v]="-v|--verbose|Verbose output||"
    [o]="-o|--output|Output file|PATH|stdout"
)
# Parse: IFS='|' read -r short long desc value_name default <<< "${_OPT_META[${key}]}"
# BASH_REMATCH for inline parsing (zero forks, replaces rg -oP / awk)
[[ "${line}" =~ ^([0-9-]+)[[:space:]]([A-Z]+)[[:space:]](.+)$ ]] && {
    local -r date="${BASH_REMATCH[1]}" level="${BASH_REMATCH[2]}" msg="${BASH_REMATCH[3]}"
}
# IFS splitting (zero forks, replaces cut / awk -F for simple delimiters)
IFS='|' read -r pattern msg level <<< "${check_def}"
IFS=, read -ra fields <<< "${csv_line}"
# Deduplication via associative set
declare -A _seen=()
# [PARADIGM:loop] — iterative mutation of seen-set has no declarative equivalent in bash
for item in "${items[@]}"; do
    [[ -v _seen["${item}"] ]] && continue
    _seen["${item}"]=1; _process "${item}"
done
# Stack (LIFO) — array-based, O(1) push/pop (cleanup registry pattern)
declare -a _stack=()
_stack+=("value")                                    # Push
local -r top="${_stack[-1]}"; unset '_stack[-1]'     # Pop
# Queue (FIFO) — index-based, O(1) enqueue/dequeue
declare -a _queue=(); declare -i _q_head=0
_queue+=("value")                                    # Enqueue
local -r front="${_queue[_q_head]}"; (( _q_head++ )) # Dequeue
```

## [08]-[ARITHMETIC]

```bash conceptual
# Ternary assignment
(( exit_code = failures > 0 ? EX_ERR : EX_OK ))
# Boolean coercion (non-zero → 1, zero → 0)
(( is_verbose = LOG_LEVEL <= 1 ))
(( has_errors = error_count > 0 ))
# Compound multi-assignment (comma operator)
(( total += count, errors += rc > 0, pct = total ? errors * 100 / total : 0 ))
# Increment/decrement without subshell
(( retry_count++ ))
(( remaining-- ))
# Bitwise (flags, permissions)
(( flags = READ | WRITE ))                           # Combine
(( flags & EXEC )) && _run "${cmd}"                  # Test
# Arithmetic guard (replaces if-then)
(( ${#arr[@]} > 0 )) || _die "Empty array"
(( BASH_VERSINFO[0] >= 5 )) || _die "Bash 5+ required"
# Elapsed time (microsecond precision, no fork)
local -r t0="${EPOCHREALTIME}"
_expensive_operation
local -r t1="${EPOCHREALTIME}"
local -r us=$(( (${t1%.*} - ${t0%.*}) * 1000000 + 10#${t1#*.} - 10#${t0#*.} ))
```

## [09]-[BUILTIN_PERFORMANCE]

| [INDEX] | [NEED]          | [EXTERNAL_FORK]              | [BASH_NATIVE_ZERO_FORK]                            |
| :-----: | :-------------- | :--------------------------- | :------------------------------------------------- |
|  [01]   | Field extract   | `printf \| rg -oP`           | `[[ "$v" =~ pat ]] && ${BASH_REMATCH[1]}`          |
|  [02]   | Split delimiter | `printf \| cut -d,`          | `IFS=, read -ra parts <<< "$v"`                    |
|  [03]   | Membership      | `printf \| rg -Fxq`          | `declare -Ar SET=([k]=1); [[ -v SET["$v"] ]]`      |
|  [04]   | Dispatch        | case chain                   | `declare -Ar MAP=([a]=fn_a); "${MAP[$v]}"`         |
|  [05]   | Array from cmd  | `while read; arr+=(); done`  | `mapfile -t arr < <(cmd)`                          |
|  [06]   | Dedup           | `sort -u`                    | `declare -A seen; [[ -v seen["$k"] ]] && continue` |
|  [07]   | Timestamp       | `ts=$(date '+%F %T')`        | `printf -v ts '%(%F %T)T' -1`                      |
|  [08]   | Epoch           | `date +%s`                   | `${EPOCHSECONDS}`                                  |
|  [09]   | Elapsed us      | `date +%s` before/after      | `${EPOCHREALTIME}` diff                            |
|  [10]   | File read       | `data=$(cat file)`           | `data=$(<file)`                                    |
|  [11]   | Pipe avoidance  | `echo "$x" \| cmd`           | `cmd <<< "${x}"`                                   |
|  [12]   | Locale bypass   | --                           | `LC_ALL=C rg 'pattern' file`                       |
|  [13]   | Wait for job    | `wait $pid`                  | `wait -f $pid` (no job control needed)             |
|  [14]   | Debug dump      | manual printf                | `declare -p var` (type-aware)                      |
|  [15]   | Secure random   | `od -An -tu4 /dev/urandom`   | `${SRANDOM}` (32-bit, getentropy)                  |
|  [16]   | Case transform  | `tr '[:lower:]' '[:upper:]'` | `${var@U}` / `${var@L}`                            |
