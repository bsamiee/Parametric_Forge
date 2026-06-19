#!/usr/bin/env bats
bats_require_minimum_version 1.13.0

setup() {
  export FORGE_PROVISION_ROOT="$BATS_TEST_TMPDIR/forge-root"
  export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
  export HOME="$BATS_TEST_TMPDIR/home"
  export TMPDIR="$BATS_TEST_TMPDIR/tmp"
  export DOCKER_CONFIG="$BATS_TEST_TMPDIR/docker-config"
  export DOCKER_HOST=""
  export DOCKER_CONTEXT=""
  export FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1
  export BATS_TEST_TIMEOUT=45
  mkdir -p "$FORGE_PROVISION_ROOT/libs/csharp" "$HOME" "$TMPDIR" "$DOCKER_CONFIG"
  touch "$FORGE_PROVISION_ROOT/pyproject.toml" "$FORGE_PROVISION_ROOT/Directory.Packages.props"
}

provision_env_json() {
  "$FORGE_PROVISION_BIN" --json env
}

mutation_lock_from_env_json() {
  jq -r --arg state "$XDG_STATE_HOME" \
    '$state + "/forge-provision/locks/project/" + .project.rootKey + "/" + .project.projectKey + "/" + .project.instance + "/mutation.lock.d"' \
    <<<"$1"
}

assert_no_litter() {
  [ ! -e "$FORGE_PROVISION_ROOT/.artifacts" ]
  [ ! -e "$XDG_STATE_HOME/forge-provision" ]
  [ ! -e "$DOCKER_CONFIG/config.json" ]
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
  run --separate-stderr "$FORGE_PROVISION_BIN" --json --diagnostic-json self-test
  [ "$status" -eq 2 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and .error.code == "usage"' <<<"$output" >/dev/null
}

@test "rejects retired self-test alias" {
  run --separate-stderr "$FORGE_PROVISION_BIN" --json --self-test
  [ "$status" -eq 2 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and (.error.message | contains("--self-test"))' <<<"$output" >/dev/null
}

@test "rejects psql under json mode before docker work" {
  run --separate-stderr "$FORGE_PROVISION_BIN" --json psql timescale
  [ "$status" -eq 2 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and .command == "psql" and (.error.message | contains("does not support JSON"))' <<<"$output" >/dev/null
}

@test "rejects duplicate prune json flag before docker work" {
  run --separate-stderr "$FORGE_PROVISION_BIN" --json prune --owned --json
  [ "$status" -eq 2 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and .command == "prune" and (.error.message | contains("both globally and locally"))' <<<"$output" >/dev/null
  [ ! -e "$FORGE_PROVISION_ROOT/.artifacts" ]
}

@test "global json form works for read-only schema-v3 verbs" {
  for verb in env plan extensions paths doctor ports inventory status self-test; do
    run --separate-stderr "$FORGE_PROVISION_BIN" --json "$verb"
    [ "$status" -eq 0 ]
    [ "$stderr" = "" ]
    jq -e --arg verb "$verb" '.schemaVersion == 3 and .command == $verb' <<<"$output" >/dev/null
    assert_no_litter
  done
}

@test "diagnostic json stays redacted for paths and doctor" {
  run --separate-stderr "$FORGE_PROVISION_BIN" --diagnostic-json paths
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '.schemaVersion == 3 and .command == "paths" and all(.generated[]; has("path") | not) and all(.generated[]; .pathRedacted == true)' <<<"$output" >/dev/null
  [[ "$output" != *"$FORGE_PROVISION_ROOT"* ]]
  assert_no_litter

  run --separate-stderr "$FORGE_PROVISION_BIN" --diagnostic-json doctor
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '.schemaVersion == 3 and .command == "doctor" and .diagnostic.dockerEndpointRedacted == true and .diagnostic.dockerPathRedacted == true' <<<"$output" >/dev/null
  [[ "$output" != *"$FORGE_PROVISION_ROOT"* ]]
  [[ "$output" != *"docker.sock"* ]]
  assert_no_litter
}

@test "diagnostic json is allowlisted before lifecycle work" {
  run --separate-stderr "$FORGE_PROVISION_BIN" --diagnostic-json up
  [ "$status" -eq 2 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and .command == "up" and (.error.message | contains("doctor, paths, and inventory"))' <<<"$output" >/dev/null
  [ ! -e "$FORGE_PROVISION_ROOT/.artifacts" ]
}

@test "handled prune failure emits exactly one json envelope" {
  run --separate-stderr "$FORGE_PROVISION_BIN" --json prune --owned
  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  [ "$(jq -s 'length' <<<"$output")" -eq 1 ]
  jq -e '.schemaVersion == 3 and .command == "prune" and .ok == false' <<<"$output" >/dev/null
}

@test "local json flag is active before lifecycle lock acquisition" {
  env_json="$(provision_env_json)"
  lock="$(mutation_lock_from_env_json "$env_json")"
  bash -c 'while :; do sleep 1; done' forge-provision &
  owner_pid="$!"
  write_lock_owner "$lock" "$owner_pid" up

  run --separate-stderr "$FORGE_PROVISION_BIN" down --json
  kill "$owner_pid" 2>/dev/null || true
  wait "$owner_pid" 2>/dev/null || true

  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  [ "$(jq -s 'length' <<<"$output")" -eq 1 ]
  jq -e '.ok == false and .command == "down" and (.error.message | contains("mutating command is active"))' <<<"$output" >/dev/null
}

@test "mutating static validation failures clean empty provisioning parents" {
  run --separate-stderr env FORGE_PROVISION_AUTH=invalid "$FORGE_PROVISION_BIN" --json up
  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  [ "$(jq -s 'length' <<<"$output")" -eq 1 ]
  jq -e '.ok == false and .command == "up" and (.error.message | contains("FORGE_PROVISION_AUTH"))' <<<"$output" >/dev/null
  [ ! -e "$FORGE_PROVISION_ROOT/.artifacts" ]
}

@test "invalid and symlinked roots are redacted and leave no litter" {
  bad_root="$BATS_TEST_TMPDIR/missing-root"
  run --separate-stderr env FORGE_PROVISION_ROOT="$bad_root" "$FORGE_PROVISION_BIN" --json env
  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  [[ "$output" != *"$bad_root"* ]]
  jq -e '.ok == false and .error.code == "error"' <<<"$output" >/dev/null

  root_link="$BATS_TEST_TMPDIR/root-link"
  ln -s "$FORGE_PROVISION_ROOT" "$root_link"
  run --separate-stderr env FORGE_PROVISION_ROOT="$root_link" "$FORGE_PROVISION_BIN" --json env
  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  [[ "$output" != *"$root_link"* ]]
  jq -e '.ok == false and (.error.message | contains("symlinked FORGE_PROVISION_ROOT"))' <<<"$output" >/dev/null
  assert_no_litter
}

@test "active psql session blocks lifecycle mutation before docker work" {
  env_json="$(provision_env_json)"
  sleep 60 &
  owner_pid="$!"
  session="$(jq -r --arg state "$XDG_STATE_HOME" '$state + "/forge-provision/locks/project/" + .project.rootKey + "/" + .project.projectKey + "/" + .project.instance + "/session/timescale-bats.lock.d"' <<<"$env_json")"
  write_lock_owner "$session" "$owner_pid" psql timescale

  run --separate-stderr "$FORGE_PROVISION_BIN" --json down
  kill "$owner_pid" 2>/dev/null || true
  wait "$owner_pid" 2>/dev/null || true

  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  [ "$(jq -s 'length' <<<"$output")" -eq 1 ]
  jq -e '.ok == false and (.error.message | contains("active psql session blocks lifecycle mutation"))' <<<"$output" >/dev/null
}

@test "active lifecycle mutation blocks new psql session before docker work" {
  env_json="$(provision_env_json)"
  lock="$(mutation_lock_from_env_json "$env_json")"
  bash -c 'while :; do sleep 1; done' forge-provision &
  owner_pid="$!"
  write_lock_owner "$lock" "$owner_pid" down

  run --separate-stderr "$FORGE_PROVISION_BIN" psql timescale -- -c "select 1"
  kill "$owner_pid" 2>/dev/null || true
  wait "$owner_pid" 2>/dev/null || true

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"another forge-provision mutating command is active"* ]]
}

@test "self-test proves schema and packaged coreutils behavior" {
  run --separate-stderr "$FORGE_PROVISION_BIN" --json self-test
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '.schemaVersion == 3 and .checks.gnuCoreutils == true' <<<"$output" >/dev/null
}

@test "help omits retired command names" {
  run --separate-stderr "$FORGE_PROVISION_BIN" --help
  [ "$status" -eq 0 ]
  [[ "$output" != *"psql-timescale"* ]]
  [[ "$output" != *"psql-search"* ]]
  [[ "$output" != *"psql-pgduckdb"* ]]
  [[ "$output" != *"forge-spike-stack"* ]]
}

@test "extension catalog includes metadata owned by rows" {
  run --separate-stderr env FORGE_PROVISION_PG_CRON=1 "$FORGE_PROVISION_BIN" --json extensions
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '
    [.extensions[] | select(
      .service == "timescale"
      and .extension == "pg_cron"
      and .required == true
      and .createOnApply == true
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
      and .loadPolicy == "apply-create"
      and .createPolicy == "apply-create"
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
  run --separate-stderr env FORGE_PROVISION_PGDUCKDB=1 "$FORGE_PROVISION_BIN" --json extensions
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

@test "extension catalog includes DuckDB and SQLite tool-surface rows" {
  run --separate-stderr "$FORGE_PROVISION_BIN" --json extensions
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '
    any(.extensions[];
	      .service == "duckdb"
	      and .extension == "ducklake"
	      and .kind == "tool-extension"
	      and .surface == "duckdb"
      and .database == "duckdb"
      and .admission == "catalog-only"
      and .loadPolicy == "catalog-only"
    )
	    and any(.extensions[];
	      .service == "duckdb"
	      and .extension == "postgres_scanner"
	      and (.aliases | index("postgres"))
	    )
	    and any(.extensions[];
	      .service == "sqlite"
	      and .extension == "sqlite-vec"
	      and .kind == "tool-extension"
	      and .surface == "sqlite-forge"
	      and .database == "sqlite"
	      and .admission == "loaded-by-sqlite-forge"
	      and .loadName == "vec0"
	      and .probeFunction == "vec_version"
	    )
	  ' <<<"$output" >/dev/null
  [ ! -e "$FORGE_PROVISION_ROOT/.artifacts" ]
}

@test "port override contracts reject partial and duplicate active modes" {
  run --separate-stderr env FORGE_PROVISION_TIMESCALE_PORT=15432 "$FORGE_PROVISION_BIN" --json env
  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and (.error.message | contains("ambiguous port configuration"))' <<<"$output" >/dev/null
  assert_no_litter

  run --separate-stderr env FORGE_PROVISION_TIMESCALE_PORT=15432 FORGE_PROVISION_SEARCH_PORT=15432 "$FORGE_PROVISION_BIN" --json env
  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and (.error.message | contains("conflicts"))' <<<"$output" >/dev/null
  assert_no_litter
}

@test "explicit ephemeral opt-in permits high auto port range" {
  run --separate-stderr env FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1 FORGE_PROVISION_PORT_RANGE=65000-65010 "$FORGE_PROVISION_BIN" --json env
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '.portPolicy.range == "65000-65010" and (.services.timescale.port >= 65000)' <<<"$output" >/dev/null
  assert_no_litter
}

@test "pg cron catalog is scheduler-profile gated" {
  run --separate-stderr env FORGE_PROVISION_PG_CRON=0 "$FORGE_PROVISION_BIN" --json extensions
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '
    [.extensions[] | select(
      .service == "timescale"
      and .extension == "pg_cron"
      and .required == false
      and .createOnApply == false
      and .probeKind == "scheduler"
    )] | length == 1
  ' <<<"$output" >/dev/null
}

@test "plan json is sanitized and read-only" {
  run --separate-stderr "$FORGE_PROVISION_BIN" --json plan
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
  [ ! -e "$FORGE_PROVISION_ROOT/.artifacts" ]
}

@test "auto port allocation uses enabled service count" {
  run --separate-stderr env FORGE_PROVISION_PORT_RANGE=25010-25011 "$FORGE_PROVISION_BIN" --json plan
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '
    .services.timescale.port == 25010
    and .services.search.port == 25011
    and .services.pgduckdb.enabled == false
    and .services.pgduckdb.portSource == "disabled-default"
  ' <<<"$output" >/dev/null

  run --separate-stderr env FORGE_PROVISION_PORT_RANGE=25010-25011 FORGE_PROVISION_PGDUCKDB=1 "$FORGE_PROVISION_BIN" --json plan
  [ "$status" -ne 0 ]
  [ "$stderr" = "" ]
  jq -e '.ok == false and (.error.message | contains("no usable auto port blocks"))' <<<"$output" >/dev/null
}

@test "trust-loopback json env keeps connection strings redacted" {
  run --separate-stderr env FORGE_PROVISION_AUTH=trust-loopback "$FORGE_PROVISION_BIN" --json env
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  [[ "$output" != *"postgres://postgres@127.0.0.1"* ]]
  jq -e '.FORGE_PROVISION_TIMESCALE_DSN | contains("***")' <<<"$output" >/dev/null
}

@test "text plan does not point missing generated secrets at dev null" {
  run --separate-stderr "$FORGE_PROVISION_BIN" plan
  [ "$status" -eq 0 ]
  [[ "$output" != *"/dev/null"* ]]
  [[ "$output" == *"<generated-by-up>"* ]]
  [ ! -e "$FORGE_PROVISION_ROOT/.artifacts" ]
}

@test "doctor exposes sanitized runtime facts" {
  run --separate-stderr "$FORGE_PROVISION_BIN" --json doctor
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  jq -e '
    .runtime.forgeProvision.schemaVersion == 3
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

  run --separate-stderr env PATH="$BATS_TEST_TMPDIR/bin:$PATH" DOCKER_CONTEXT=missing "$FORGE_PROVISION_BIN" --json doctor
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
  [ ! -e "$FORGE_PROVISION_ROOT/.artifacts" ]
}
