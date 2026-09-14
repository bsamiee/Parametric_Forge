# Title         : terminal-lib.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/terminal-lib.nix
# ----------------------------------------------------------------------------
# Shared vocabulary for the terminal rail: pane-identity jq predicates, the bounded-retry and process-deadline owners, the admitted-snapshot
# kernel, the DDS client-id projection, and the runtime-root derivation. Every terminal.nix kernel reads these single bindings.
{lib}: let
  # One popup-identity vocabulary — production dispatch and caller dismissal share this exact jq row predicate. terminal_command is the spawn command (invoked_with), so exec inside the pane never breaks rediscovery.
  yaziPopupIdentity = ''(.is_plugin | not) and (.exited | not) and ((.is_floating // false) or (.is_suppressed // false)) and ((.title // "") == " [YAZI] ") and ((.terminal_command // .command // "") == "forge-yazi.sh")'';

  # One self-row vocabulary: (panes snapshot, $self) -> this pane's row; every kernel resolves its own pane through this exact projection.
  selfRow = ''[.[] | select((.is_plugin | not) and ((.id | tostring) == $self))][0]'';

  # One live-row vocabulary: (panes snapshot, $id, $tab) -> count of live terminal rows with that id in that tab; the registry-hit gate joins
  # registry rows to live panes through this exact predicate.
  liveInTab = ''[.[] | select((.is_plugin | not) and ((.id | tostring) == $id) and (.tab_id == $tab) and (.exited | not))] | length'';

  # One bounded-retry owner: every startup race, RPC probe, DDS bind wait, and snapshot flap in the rail polls through this single loop.
  retrySh = ''
    _retry() { # $1 tries, $2 interval, $3.. simple command; truthy on first success
      local -i _n="$1"
      local _iv="$2"
      shift 2
      while ((_n-- > 0)); do
        if "$@"; then return 0; fi
        ((_n)) && sleep "$_iv"
      done
      return 1
    }
  '';

  # One process-deadline owner: each entrypoint supplies its public environment knob and bounds; the active sentinel derives from that knob so
  # validation, recursion prevention, and timeout re-exec retain one grammar without weakening script-specific diagnostics.
  deadlineGuardSh = {
    environment,
    default,
    maximum,
    killGrace,
    errorContext,
  }: let
    active = "_${lib.removeSuffix "_SECONDS" environment}_ACTIVE";
  in ''
    if [[ -z "''${${active}:-}" ]]; then
      deadline="''${${environment}:-${toString default}}"
      if [[ ! "$deadline" =~ ^[1-9][0-9]{0,2}$ || "$deadline" -gt ${toString maximum} ]]; then
        printf '${errorContext}: ${environment} must be an integer from 1 through ${toString maximum}\n' >&2
        exit 2
      fi
      ${active}=1 exec timeout -k ${toString killGrace} "$deadline" "$0" "$@"
    fi
  '';

  # One admitted-snapshot kernel: list-panes flaps transiently against a busy session; every reader retries to a non-empty array and, when `self` is
  # set, waits until that freshly spawned pane appears, so a partial snapshot never licenses work in tab 0. Interpolate after retrySh.
  panesSnapshotSh = listCmd: ''
    # shellcheck disable=SC2329  # invoked through _retry
    _panes_probe() {
      panes="$(${listCmd} 2>/dev/null || true)"
      printf '%s\n' "$panes" | jq -e --arg self "''${self:-}" '
        type == "array" and length > 0
        and (($self == "") or ((${selfRow}) as $row
          | ($row != null) and (($row.tab_id | type) == "number") and (($row.exited // false) | not)))' >/dev/null 2>&1
    }
    # shellcheck disable=SC2034  # production dispatchers consume the verdict; snapshot-printer callers consume only panes
    panes_snapshot_ok="false"
    if _retry 5 0.2 _panes_probe; then
      # shellcheck disable=SC2034  # production dispatchers consume the verdict; snapshot-printer callers consume only panes
      panes_snapshot_ok="true"
    else
      panes="[]"
    fi
  '';

  # One DDS client-id derivation: (session, pane_id) -> deterministic 6-digit id; the popup body and dispatcher both pipe
  # `printf '%s:%s' session pane` through this exact projection.
  cidPipeline = ''cksum | gawk '{ print ($1 % 899999) + 100000 }' '';

  # One runtime-root derivation for every rail script: RPC sockets, the dispatch lock, surfaced markers, and DDS state live in a
  # canonical per-user private namespace. Every destructive target is admitted only as a strict descendant of this root.
  runtimeBaseSh = ''
    runtime_base_raw="''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}/forge-edit"
    mkdir -p "$runtime_base_raw"
    runtime_base="$(realpath -- "$runtime_base_raw")"
    chmod go-rwx "$runtime_base"
    _runtime_child() {
      local _child
      _child="$(realpath -m -- "$runtime_base/$1")"
      if [[ "$_child" != "$runtime_base/"* ]]; then
        printf 'terminal rail: path escapes runtime root: %s\n' "$1" >&2
        return 75
      fi
      printf '%s\n' "$_child"
    }
    # shellcheck disable=SC2329  # only wrappers that admit external registry paths invoke this shared projection
    _runtime_contains() {
      local _candidate
      _candidate="$(realpath -m -- "$1")"
      [[ "$_candidate" == "$runtime_base/"* ]]
    }
  '';
in {
  inherit yaziPopupIdentity selfRow liveInTab retrySh deadlineGuardSh panesSnapshotSh cidPipeline runtimeBaseSh;
}
