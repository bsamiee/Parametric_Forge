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

@test "global json form works for read-only schema-v2 verbs" {
  for verb in env plan extensions doctor ports inventory status self-test; do
    run --separate-stderr "$RASM_PROVISION_BIN" --json "$verb"
    [ "$status" -eq 0 ]
    [ "$stderr" = "" ]
    jq -e --arg verb "$verb" '.schemaVersion == 2 and .command == $verb' <<<"$output" >/dev/null
  done
}

@test "diagnostic json is allowlisted before lifecycle work" {
  run --separate-stderr "$RASM_PROVISION_BIN" --diagnostic-json up
  [ "$status" -eq 2 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and .command == "up" and (.error.message | contains("doctor, paths, and inventory"))' <<<"$output" >/dev/null
  [ ! -e "$RASM_ROOT/.artifacts" ]
}

@test "handled prune failure emits exactly one json envelope" {
  run --separate-stderr "$RASM_PROVISION_BIN" --json prune --owned
  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  [ "$(jq -s 'length' <<<"$output")" -eq 1 ]
  jq -e '.schemaVersion == 2 and .command == "prune" and .ok == false' <<<"$output" >/dev/null
}

@test "local json flag is active before lifecycle lock acquisition" {
  env_json="$(provision_env_json)"
  project="$(jq -r '.project' <<<"$env_json")"
  lock="$RASM_ROOT/.artifacts/provisioning/rasm/.locks/$project.lock.d"
  bash -c 'while :; do sleep 1; done' rasm-provision &
  owner_pid="$!"
  write_lock_owner "$lock" "$owner_pid" up

  run --separate-stderr "$RASM_PROVISION_BIN" down --json
  kill "$owner_pid" 2>/dev/null || true
  wait "$owner_pid" 2>/dev/null || true

  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  [ "$(jq -s 'length' <<<"$output")" -eq 1 ]
  jq -e '.ok == false and .command == "down" and (.error.message | contains("mutating command is active"))' <<<"$output" >/dev/null
}

@test "mutating static validation failures clean empty provisioning parents" {
  run --separate-stderr env RASM_PROVISION_AUTH=invalid "$RASM_PROVISION_BIN" --json up
  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  [ "$(jq -s 'length' <<<"$output")" -eq 1 ]
  jq -e '.ok == false and .command == "up" and (.error.message | contains("RASM_PROVISION_AUTH"))' <<<"$output" >/dev/null
  [ ! -e "$RASM_ROOT/.artifacts" ]
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
  run --separate-stderr env RASM_PROVISION_PG_CRON=1 "$RASM_PROVISION_BIN" --json extensions
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
      and .sourceRoute != null
      and .nixStatus != null
      and .probeKind == "scheduler"
      and .capabilityRank == "required"
      and .externalAccess == "none"
      and .restartClass == "shared-preload"
      and .serviceProfile == "timescale"
      and .loadPolicy == "verify-create"
      and .createPolicy == "verify-create"
    )] | length == 1
  ' <<<"$output" >/dev/null
  jq -e '
    all(.extensions[];
      has("sourceRoute")
      and has("sourceKind")
      and has("nixStatus")
      and has("probeKind")
      and has("capabilityRank")
      and has("externalAccess")
      and has("restartClass")
      and has("serviceProfile")
      and has("loadPolicy")
    )
  ' <<<"$output" >/dev/null
  [[ "$output" != *"nix/store"* ]]
  [[ "$output" != *"docker.sock"* ]]
}

@test "service-specific extension source routes match service images" {
  run --separate-stderr env RASM_PROVISION_PGDUCKDB=1 "$RASM_PROVISION_BIN" --json extensions
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '
    any(.extensions[];
      .service == "search"
      and .extension == "vector"
      and .sourceRoute == "image:paradedb/paradedb"
      and .sourceKind == "image"
    )
  ' <<<"$output" >/dev/null
}

@test "pg cron catalog is scheduler-profile gated" {
  run --separate-stderr env RASM_PROVISION_PG_CRON=0 "$RASM_PROVISION_BIN" --json extensions
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '
    [.extensions[] | select(
      .service == "timescale"
      and .extension == "pg_cron"
      and .required == false
      and .createOnVerify == false
      and .probeKind == "scheduler"
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

@test "auto port allocation uses enabled service count" {
  run --separate-stderr env RASM_PROVISION_PORT_RANGE=25010-25011 "$RASM_PROVISION_BIN" --json plan
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '
    .services.timescale.port == 25010
    and .services.search.port == 25011
    and .services.pgduckdb.enabled == false
    and .services.pgduckdb.portSource == "disabled-default"
  ' <<<"$output" >/dev/null

  run --separate-stderr env RASM_PROVISION_PORT_RANGE=25010-25011 RASM_PROVISION_PGDUCKDB=1 "$RASM_PROVISION_BIN" --json plan
  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and (.error.message | contains("no usable auto port blocks"))' <<<"$output" >/dev/null
}

@test "trust-loopback json env keeps connection strings redacted" {
  run --separate-stderr env RASM_PROVISION_AUTH=trust-loopback "$RASM_PROVISION_BIN" --json env
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  [[ "$output" != *"postgres://postgres@127.0.0.1"* ]]
  jq -e '.RASM_TIMESCALE_DSN | contains("***")' <<<"$output" >/dev/null
}

@test "text plan does not point missing generated secrets at dev null" {
  run --separate-stderr "$RASM_PROVISION_BIN" plan
  [ "$status" -eq 0 ]
  [[ "$output" != *"/dev/null"* ]]
  [[ "$output" == *"<generated-by-up>"* ]]
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

@test "broken explicit docker context degrades to sanitized doctor policy" {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat >"$BATS_TEST_TMPDIR/bin/docker" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "context" && "$2" == "inspect" ]]; then
  exit 1
fi
exit 125
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/docker"

  run --separate-stderr env PATH="$BATS_TEST_TMPDIR/bin:$PATH" DOCKER_CONTEXT=missing "$RASM_PROVISION_BIN" --json doctor
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '
    .ok == true
    and .docker.policy.status == "rejected"
    and .docker.policy.reason == "explicit Docker context cannot be inspected"
    and .docker.endpointKind == "unknown"
  ' <<<"$output" >/dev/null
  [[ "$output" != *"docker.sock"* ]]
  [[ "$output" != *"/Users/"* ]]
  [ ! -e "$RASM_ROOT/.artifacts" ]
}
