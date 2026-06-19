bats_require_minimum_version 1.5.0

setup() {
  export RASM_ROOT="$BATS_TEST_TMPDIR/rasm-root"
  export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
  export RASM_PROVISION_ALLOW_EPHEMERAL_PORTS=1
  mkdir -p "$RASM_ROOT/libs/csharp"
  touch "$RASM_ROOT/pyproject.toml" "$RASM_ROOT/Directory.Packages.props"
}

provision_env_json() {
  "$RASM_PROVISION_BIN" --json env
}

write_lock_owner() {
  local lock="$1"
  local pid="$2"
  local command="$3"
  local service="${4:-}"
  local token="bats-token"
  mkdir -p "$lock"
  chmod 700 "$lock"
  printf '%s\n' "$token" >"$lock/token"
  {
    printf 'pid=%s\n' "$pid"
    printf 'host=%s\n' "${HOSTNAME:-unknown}"
    printf 'started_at=2026-01-01T00:00:00Z\n'
    printf 'last_heartbeat_epoch=%s\n' "$(date +%s)"
    printf 'token=%s\n' "$token"
    printf 'command=%s\n' "$command"
    [[ -z "$service" ]] || printf 'service=%s\n' "$service"
  } >"$lock/owner"
  chmod 600 "$lock/token" "$lock/owner"
}

@test "rejects incompatible json modes without stderr" {
  run --separate-stderr "$RASM_PROVISION_BIN" --json --diagnostic-json self-test
  [ "$status" -eq 2 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and .error.code == "usage"' <<<"$output" >/dev/null
}

@test "rejects retired self-test alias" {
  run --separate-stderr "$RASM_PROVISION_BIN" --json --self-test
  [ "$status" -eq 2 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and (.error.message | contains("--self-test"))' <<<"$output" >/dev/null
}

@test "rejects psql under json mode before docker work" {
  run --separate-stderr "$RASM_PROVISION_BIN" --json psql timescale
  [ "$status" -eq 2 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and .command == "psql" and (.error.message | contains("does not support JSON"))' <<<"$output" >/dev/null
}

@test "rejects duplicate prune json flag before docker work" {
  run --separate-stderr "$RASM_PROVISION_BIN" --json prune --owned --json
  [ "$status" -eq 2 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and .command == "prune" and (.error.message | contains("both globally and locally"))' <<<"$output" >/dev/null
  [ ! -e "$RASM_ROOT/.artifacts" ]
}

@test "handled prune failure emits exactly one json envelope" {
  run --separate-stderr "$RASM_PROVISION_BIN" --json prune --owned
  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  [ "$(jq -s 'length' <<<"$output")" -eq 1 ]
  jq -e '.schemaVersion == 2 and .command == "prune" and .ok == false' <<<"$output" >/dev/null
}

@test "active psql session blocks lifecycle mutation before docker work" {
  env_json="$(provision_env_json)"
  project="$(jq -r '.project' <<<"$env_json")"
  root="$(jq -r '.rootFingerprint' <<<"$env_json")"
  sleep 60 &
  owner_pid="$!"
  session="$XDG_STATE_HOME/rasm-provision/sessions/$root-$project-timescale-bats.lock"
  write_lock_owner "$session" "$owner_pid" psql timescale

  run --separate-stderr "$RASM_PROVISION_BIN" --json down
  kill "$owner_pid" 2>/dev/null || true
  wait "$owner_pid" 2>/dev/null || true

  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  [ "$(jq -s 'length' <<<"$output")" -eq 1 ]
  jq -e '.ok == false and (.error.message | contains("active psql session blocks lifecycle mutation"))' <<<"$output" >/dev/null
}

@test "active lifecycle mutation blocks new psql session before docker work" {
  env_json="$(provision_env_json)"
  project="$(jq -r '.project' <<<"$env_json")"
  lock="$RASM_ROOT/.artifacts/provisioning/rasm/.locks/$project.lock.d"
  bash -c 'while :; do sleep 1; done' rasm-provision &
  owner_pid="$!"
  write_lock_owner "$lock" "$owner_pid" down

  run --separate-stderr "$RASM_PROVISION_BIN" psql timescale -- -c "select 1"
  kill "$owner_pid" 2>/dev/null || true
  wait "$owner_pid" 2>/dev/null || true

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"another rasm-provision mutating command is active"* ]]
}

@test "self-test proves schema and packaged coreutils behavior" {
  run --separate-stderr "$RASM_PROVISION_BIN" --json self-test
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '.schemaVersion == 2 and .checks.gnuCoreutils == true' <<<"$output" >/dev/null
}

@test "help omits retired command names" {
  run --separate-stderr "$RASM_PROVISION_BIN" --help
  [ "$status" -eq 0 ]
  [[ "$output" != *"psql-timescale"* ]]
  [[ "$output" != *"psql-search"* ]]
  [[ "$output" != *"psql-pgduckdb"* ]]
  [[ "$output" != *"rasm-spike-stack"* ]]
}

@test "extension catalog includes metadata owned by rows" {
  run --separate-stderr "$RASM_PROVISION_BIN" --json extensions
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '
    [.extensions[] | select(
      .service == "timescale"
      and .extension == "pg_cron"
      and .required == true
      and .createOnVerify == true
      and .preloadRequired == true
      and .requiresSharedPreload == true
      and .backgroundWorker == true
      and .sourcePackage != null
      and .createPolicy == "verify-create"
    )] | length == 1
  ' <<<"$output" >/dev/null
}

@test "plan json is sanitized and read-only" {
  run --separate-stderr "$RASM_PROVISION_BIN" --json plan
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '
    .ok == true
    and .command == "plan"
    and .plan.composeYaml == "redacted"
    and .portPolicy.seedFingerprint != null
    and (.portPolicy.seed? == null)
    and (.auth.agentPromptRequired == false)
  ' <<<"$output" >/dev/null
  [[ "$output" != *POSTGRES_PASSWORD* ]]
  [[ "$output" != *DOCKER_CONFIG* ]]
  [ ! -e "$RASM_ROOT/.artifacts" ]
}

@test "doctor exposes sanitized runtime facts" {
  run --separate-stderr "$RASM_PROVISION_BIN" --json doctor
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '
    .runtime.rasmProvision.schemaVersion == 2
    and (.runtime.jq.present == true)
    and (.runtime.listenerProbeMethod | type == "string")
    and (.docker.hostConfig.credentialHelperPresent | type == "boolean")
    and (.docker.hostConfig | has("path") | not)
  ' <<<"$output" >/dev/null
  [[ "$output" != *"docker.sock"* ]]
  [[ "$output" != *"DOCKER_CONFIG"* ]]
}
