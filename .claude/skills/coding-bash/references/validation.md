# [VALIDATION]

## [01]-[VALIDATION_PIPELINE]

Validation is sequential — each gate must pass before the next runs. `bash -n` catches unclosed quotes, missing `done`/`fi`, and heredoc mismatches, but CANNOT detect unquoted expansions, unused variables, or unreachable code. ShellCheck fills the semantic gap. Tests prove runtime behavior. Coverage quantifies untested surface.

| [INDEX] | [GATE]       | [COMMAND]                                     | [CATCHES]                          | [MISSES]                  |
| :-----: | :----------- | :-------------------------------------------- | :--------------------------------- | :------------------------ |
|  [01]   | Syntax       | `bash -n script.sh`                           | Parse err, unclosed blocks         | Semantic+runtime defects  |
|  [02]   | Static: err  | `shellcheck -S error -s bash script.sh`       | Unquoted `$@`, parse-adjacent      | Style/info-level patterns |
|  [03]   | Static: full | `shellcheck -s bash script.sh`                | All 4 severity levels              | Runtime/integration bugs  |
|  [04]   | Unit tests   | `bats tests/`                                 | Functional regressions, edge cases | Untested paths            |
|  [05]   | Coverage     | `kcov --include-path=. coverage/ bats tests/` | Dead code, untested branches       | Semantic correctness      |
|  [06]   | Quality gate | Exit 1 on coverage < threshold                | Enforcement                        | —                         |

## [02]-[CRITICAL_SC_CODES]

[SC2086]:
Unquoted `$var` undergoes word splitting AND pathname globbing. An input containing `* /etc/passwd` expands to every file in CWD plus `/etc/passwd`. Under `rm`, this is arbitrary file deletion. SC2086 is classified "info" because quoting is occasionally intentionally omitted (arithmetic contexts, `[[ ]]` RHS patterns) — the severity does NOT reflect the risk. Treat every SC2086 as a potential injection vector until proven safe.

[SC2155]:
`local v=$(cmd)` masks the exit code of `cmd`. Under `set -e`, a failing command inside the subshell is silently swallowed because `local` itself returns 0. Its fix — `local v; v=$(cmd)` — exposes the real exit code to `errexit`. This interaction between `set -Eeuo pipefail` and declare-assign is the most common source of silent failures in strict-mode scripts.

[SC2329]:
Functions defined but never invoked in the file. Dispatch-table patterns legitimately define functions referenced via `"${_DISPATCH[$cmd]}"` — ShellCheck cannot trace this indirection. Suppress with `# shellcheck disable=SC2329` on dispatch-target functions, with a justification comment referencing the dispatch table.

[SC2330]:
BusyBox `sh` implements `[[ ]]` but omits glob pattern matching on the RHS. `[[ $1 == https:* ]]` silently fails or behaves unpredictably. Use `case` for portable glob matching.

[SC2331]:
`[ -a file ]` is ambiguous: unary `-a` tests existence, but binary `-a` is logical AND (`[ expr1 -a expr2 ]`). `-e` is the unambiguous POSIX existence test. Replace all unary `-a` with `-e`.

[SC2332]:
`[ ! -o braceexpand ]` parses as `[ "!" ] -o [ "braceexpand" ]` — two non-empty strings OR'd, always true. Fix with `[[ ! -o opt ]]` (where `-o` is a unary option test) or `! [ -o opt ]` (external negation).

[SC2164]:
`cd dir` silently continues in the original directory when `dir` is missing. Under `set -e`, `cd` failure DOES trigger `errexit` — but compound commands (`cd dir && do_work`) mask this. Always use `cd dir || exit 1` for explicit intent, or `cd dir || die "..."` with the project's fatal-error function.

[SC2046]:
`$(cmd)` without quotes undergoes word splitting and globbing — same injection class as SC2086 but with the added risk that `cmd`'s output is attacker-influenced. Filenames with spaces, glob characters, or IFS-matching bytes cause silent data corruption.

## [03]-[SC_CODE_REFERENCE]

| [INDEX] | [CODE]   | [SEV] | [ISSUE]                     | [FIX]                                     |
| :-----: | :------- | :---- | :-------------------------- | :---------------------------------------- |
|  [01]   | `SC2086` | info  | Unquoted variable           | `"${var}"`                                |
|  [02]   | `SC2046` | warn  | Unquoted `$()`              | `"$(cmd)"` or `mapfile -t arr < <(cmd)`   |
|  [03]   | `SC2155` | warn  | `local v=$(cmd)` masks `$?` | `local v; v=$(cmd)`                       |
|  [04]   | `SC2164` | warn  | `cd` without guard          | `cd dir \| exit 1`                        |
|  [05]   | `SC2068` | error | Unquoted `$@`               | `"$@"`                                    |
|  [06]   | `SC2329` | warn  | Unused function             | Remove, call, or disable (dispatch-table) |
|  [07]   | `SC2006` | style | Backticks                   | `$(cmd)`                                  |
|  [08]   | `SC2116` | style | Useless echo `$(echo $v)`   | `$v` directly                             |
|  [09]   | `SC2162` | info  | `read` without `-r`         | `IFS= read -r line`                       |

## [04]-[SHELLCHECKRC]

```bash template
# .shellcheckrc — paradigm-aligned defaults
shell=bash
# Enable optional checks that align with immutability/safety paradigm
enable=require-variable-braces
enable=add-default-case
enable=check-unassigned-uppercase
enable=avoid-nullary-conditions
# SC2329: dispatch-table functions are called via associative-array indirection;
# ShellCheck cannot trace "${_DISPATCH[$cmd]}" — suppress project-wide
disable=SC2329
```

[SHELLCHECK_YML]: (for CI matrix configuration):

```yaml template
# .github/linters/.shellcheck.yml (alternative to .shellcheckrc for CI)
shell: bash
enable:
    - require-variable-braces
    - add-default-case
    - check-unassigned-uppercase
disable:
    - SC2329
severity: style
```

## [05]-[DIRECTIVES]

```bash conceptual
# Correct: justification explains WHY suppression is safe
# shellcheck disable=SC2086  # $flags intentionally word-split for multi-flag expansion
printf '%s\n' $flags
# Correct: dispatch-table function called via "${_DISPATCH[cmd]}"
# shellcheck disable=SC2329
_cmd_deploy() { ... }
# Correct: source path resolved at runtime from config
# shellcheck source=/dev/null
source "${_PLUGIN_DIR}/${plugin}.sh"
# Block suppression for controlled scope
# shellcheck disable=SC2086
{
    cmd $flag1 $flag2 $flag3
}
```

Directive reference:

| [INDEX] | [DIRECTIVE]                                   | [PURPOSE]                    |
| :-----: | :-------------------------------------------- | :--------------------------- |
|  [01]   | `# shellcheck disable=SC2086`                 | Suppress next command        |
|  [02]   | `# shellcheck disable=SC2086,SC2046`          | Multi-code, single directive |
|  [03]   | `# shellcheck shell=bash`                     | Override shebang detection   |
|  [04]   | `# shellcheck source=./lib.sh`                | Resolve dynamic source       |
|  [05]   | `# shellcheck source=/dev/null`               | Skip unresolvable source     |
|  [06]   | `# shellcheck enable=require-variable-braces` | Enable optional check inline |

## [06]-[IDIOMATIC_PATTERNS]

| [INDEX] | [PATTERN]                               | [ELIMINATES]           | [REPLACES]                 |
| :-----: | :-------------------------------------- | :--------------------- | :------------------------- |
|  [01]   | `mapfile -t arr < <(cmd)`               | SC2207 (unquoted arr)  | `arr=( $(cmd) )`           |
|  [02]   | `readarray -d '' -t f < <(fd --print0)` | SC2207, word splitting | `for f in $(find …)`       |
|  [03]   | `[[ -v MAP["$k"] ]]`                    | SC2086 in `[ ]`        | `[ -n "${MAP[$k]:-}" ]`    |
|  [04]   | `printf -v ts '%(%F)T' -1`              | SC2046 from `$(date)`  | `ts=$(date +%F)`           |
|  [05]   | `local v; v=$(cmd)`                     | SC2155 masked exit     | `local v=$(cmd)`           |
|  [06]   | `[[ "$v" =~ pat ]] && BASH_REMATCH[1]`  | SC2046 from grep       | `$(echo "$v" \| rg -oP …)` |

[ENV_CONTRACT_VALIDATION]: Declare-once, validate-all pattern from container entrypoints:

```bash conceptual
declare -Ar _ENV_CONTRACT=([SERVICE_NAME]='^[a-zA-Z][a-zA-Z0-9_-]+$' [SERVICE_CMD]='.+')
_validate_env() {
    local var pattern; for var in "${!_ENV_CONTRACT[@]}"; do
        pattern="${_ENV_CONTRACT[${var}]}"
        [[ -v "${var}" ]] || _die "Missing required env: ${var}"
        [[ "${!var}" =~ ${pattern} ]] || _die "Invalid ${var}='${!var}' (expected: ${pattern})"
    done
}
```

Eliminates per-variable `[[ -z ]]` chains. Contract is data (the map), not code. `${!var}` indirect expansion reads the variable named by `$var`. Regex in `_ENV_CONTRACT` values validates shape at the boundary.

[EMBEDDED_SELF_TEST_GATE]: Assert helpers for dispatch-table scripts:

```bash conceptual
_assert_eq()    { [[ "$1" == "$2" ]] || _die "ASSERT ${FUNCNAME[1]}:${BASH_LINENO[0]}: '${1}' != '${2}'"; }
_assert_match() { [[ "$1" =~ $2 ]]  || _die "ASSERT ${FUNCNAME[1]}:${BASH_LINENO[0]}: '${1}' !~ '${2}'"; }
```

Inline assertions with automatic caller location via `FUNCNAME[1]`/`BASH_LINENO[0]`. Use in `_self_test()` to validate dispatch table integrity, nameref output functions, and env contract parsing without external test frameworks.

## [07]-[STRICT_MODE_INTERACTIONS]

`set -Eeuo pipefail` + `shopt -s inherit_errexit` creates constraints that ShellCheck assumes may not be active:

| [INDEX] | [INTERACTION]            | [STRICT_MODE_BEHAVIOR]                          | [SC_IMPLICATION]                         |
| :-----: | :----------------------- | :---------------------------------------------- | :--------------------------------------- |
|  [01]   | `local v=$(failing_cmd)` | `local` returns 0, masks failure — no `errexit` | SC2155 = silent-failure bug, not style   |
|  [02]   | `cd dir` no guard        | `errexit` fires in simple cmd; compound masks   | SC2164 still warranted                   |
|  [03]   | `cmd1 \| cmd2`           | `pipefail` exposes `cmd1` failure               | SC2312 (subshell exit) becomes relevant  |
|  [04]   | `$(cmd)` in `[[ ]]`      | `inherit_errexit` propagates into cmd sub       | Failures inside `[[ $(cmd) ]]` now fatal |
|  [05]   | `$@` unquoted + `set -u` | `set -u` catches unset but NOT empty `$@`       | SC2068 still required — `"$@"` always    |

## [08]-[CI_INTEGRATION]

```yaml template
# .github/workflows/shell-quality.yml
name: Shell Quality Gate
on: [pull_request]

jobs:
    validate:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4
            - name: Syntax check
              run: |
                  find . -name '*.sh' -print0 | xargs -0 -n1 bash -n
            - uses: ludeeus/action-shellcheck@2.0.0
              with:
                  severity: style
                  shellcheck_version: v0.11.0
                  scandir: '.'
                  additional_files: '*.bash'
            - name: Install bats + kcov
              run: |
                  sudo apt-get install -y kcov
                  npm install -g bats bats-support bats-assert
            - name: Unit tests with coverage
              run: |
                  kcov --include-path=. coverage/ bats tests/
            - name: Coverage gate
              run: |
                  pct="$(jq -r '.percent_covered' coverage/bats/coverage.json)"
                  awk -v p="${pct}" 'BEGIN { exit (p < 80) ? 1 : 0 }' || {
                    printf 'Coverage %s%% below 80%% threshold\n' "${pct}" >&2
                    exit 1
                  }
```

ShellCheck exit codes:

| [INDEX] | [CODE] | [MEANING]                    |
| :-----: | :----: | :--------------------------- |
|  [01]   |  `0`   | Clean                        |
|  [02]   |  `1`   | Issues at/above severity     |
|  [03]   |  `2`   | Parse errors                 |
|  [04]   |  `3`   | Bad options or missing files |
