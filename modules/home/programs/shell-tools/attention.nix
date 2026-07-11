# Title         : attention.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/attention.nix
# ----------------------------------------------------------------------------
# Attention-vocabulary owner beside forge-agents: ONE urgency ladder, the display-time projection, the kv-grain receipt parser, the
# normalized event-spine projection, and the standing-alert predicate rows. The forge-agents collector folds these into bar cells
# and notifications; the forge-receipts query plane folds the same defs into its SQL corpus and live push bus — one
# vocabulary, many renderers. jq fragments compose into consumer programs; alert predicates judge the LAST parsed receipt row of their kind.
{sshHosts ? {}}: let
  # Spine vocabulary: ONE ordered column vector derives the jq projection (spineJq) and the DuckDB schema clause (spineColumnsSql); every column lands
  # VARCHAR — scalars stringified so a thin or single-kind corpus can never split a column's inferred type (an all-null column infers JSON and kills
  # COALESCE). The default arm is the stringify fold `(.col | s)`; non-default columns override in the expression vocabulary; session_id is the join
  # key: zellij session name, else the emitter's own session id. A new column is one vector entry, plus an override row only when it computes.
  spineColumns = ["kind" "ts" "source" "surface" "event" "verb" "result" "state" "status" "session_id" "urgency" "raw"];
  spineExpr = {
    kind = ''((.kind // "-") | tostring)'';
    ts = "(.ts | s | iso_ts)";
    session_id = ''((.zellij_session | select(. != null and . != "")) // .session_id | s)'';
    urgency = "urgency";
    raw = "($row | tojson)";
  };
  columnOf = c: "${c}: ${spineExpr.${c} or "(.${c} | s)"}";
in {
  # Urgency is derived at the fold, never stored by emitters: failure-shaped fields -> high, a needs-input event -> input, everything else -> info.
  urgencyJq = ''
    def urgency:
      if ((.result // "ok") != "ok")
         or ((.status // "" | tostring) | test("(?i)fail"))
         or ((.state // "" | tostring) | IN("failed", "down", "error"))
         or ((.deployed // "") == "drift")
      then "high"
      elif (.event // "") == "Notification" then "input"
      else "info" end;
  '';

  # Display-time projection over the theme owner's timeDisplay rows ({sameDay, dated} strftime grammar): stored stamps stay ISO UTC, human
  # renders fold this def instead of re-spelling it; a malformed stamp passes through untouched. Callers apply the rows at interpolation.
  dispTsJq = td: ''
    def disp_ts: . as $t
      | try ((strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) as $e
        | if ($e | strflocaltime("%Y-%m-%d")) == (now | strflocaltime("%Y-%m-%d"))
          then ($e | strflocaltime("${td.sameDay}"))
          else ($e | strflocaltime("${td.dated}")) end)
        catch $t;
  '';

  # kv-grain TSV row -> object, numerics restored as JSON numbers (the same numeric law the receipts.nix emit fold applies on the JSONL side).
  kvJq = ''
    def kv_row:
      split("\t")
      | map(select(test("^[^=]+=")) | capture("^(?<key>[^=]+)=(?<value>.*)$"))
      | map(.value |= (tonumber? // .))
      | from_entries;
  '';

  # Normalized event spine: the FIXED column set every SQL verb binds against, derived from the spine vocabulary; the full source row rides `raw`
  # JSON text for kind-specific extraction, one json_extract_string(raw, ...) per kind-specific field the fixed columns do not carry.
  spineJq = ''
    def spine:
      def s: if . == null then null else tostring end;
      def iso_ts: if . != null and test("^[0-9]{8}T[0-9]{6}Z$")
        then "\(.[0:4])-\(.[4:6])-\(.[6:8])T\(.[9:11]):\(.[11:13]):\(.[13:15])Z"
        else . end;
      . as $row
      | {${builtins.concatStringsSep ",\n         " (map columnOf spineColumns)}};
  '';

  # DuckDB read_json `columns` clause from the same vector: a declared schema, never inference — an all-null column on a filtered or thin
  # corpus otherwise infers JSON and poisons every COALESCE over the column downstream.
  spineColumnsSql = builtins.concatStringsSep ", " (map (c: "${c}: 'VARCHAR'") spineColumns);

  # Session-grain dedupe key: session_id, widened by terminal identity when the emitter carried none ("-"), so two anonymous sessions on
  # different ttys can never clear each other's lifecycle state. Every per-session fold groups on this key, never on raw session_id.
  sessionKeyJq = ''
    def session_key:
      if (.session_id // "-") == "-" then "-\(.tty // "")\(.zellij_pane // "")" else .session_id end;
  '';

  # Latest needs-input row over a raw feed stream (jq -Rn + inputs): the one spelling of "which session waits newest" — focus, peek, and
  # answer fallbacks all fold this instead of re-deriving it. Hook rows only: a bell row winning max_by must never mask a waiter. Composes
  # after sessionKeyJq.
  latestNeedsJq = ''
    def latest_needs:
      [inputs | fromjson? | select(type == "object") | select((.source // "hook") == "hook")]
      | [group_by(session_key)[] | max_by(.ts) | select(.event == "Notification")]
      | max_by(.ts) // empty;
  '';

  # Standing-alert rows: a condition read from the latest receipt of a kind, active until a newer row clears it — estate state, not a windowed event.
  # A new alert class is one row; the collector resolves kind -> path through the receipt registry and renders every active row in the same bar cell.
  # Tunnel and mount rows derive from the same ssh host registry the receipt registry folds, so both sides stay row-consistent by construction.
  alertRows =
    [
      {
        source = "drift";
        kind = "drift";
        pred = ''(.deployed // "") == "drift"'';
        label = "estate drift";
      }
    ]
    ++ map (name: {
      source = "tunnel";
      kind = "tunnel-${name}";
      pred = ''(.state // "up") != "up"'';
      label = "tunnel ${name} down";
    }) (builtins.attrNames sshHosts)
    ++ builtins.concatLists (builtins.attrValues (builtins.mapAttrs (
        name: h:
          map (m: {
            source = "mount";
            kind = "mount-${name}-${m.name}";
            pred = ''(.state // "mounted") != "mounted"'';
            label = "mount ${name}-${m.name} down";
          }) (h.mounts or [])
      )
      sshHosts));
}
