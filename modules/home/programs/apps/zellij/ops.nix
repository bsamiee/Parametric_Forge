# Title         : ops.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/ops.nix
# ----------------------------------------------------------------------------
# Inner-ops owner: forge-zellij is ONE polymorphic command over the discriminated workspace graph (session, tab, pane, starred pane, project root,
# worktree, layout, macro, agent lane), layout live assets (record — a bare record freezes the session under its own slug — and apply, both behind a
# disposable-session parse gate), watch-with-memory monitor rows, and two read-only inspectors — state (forge-zellij-state/v2: sessions classified
# live|resurrectable with serialization freshness and the newest fabric receipt joined per session) and peek (typed single-frame pane capture over
# `subscribe`, attention-joined). Every mutating verb emits one typed kv receipt; fzf fronts the graph, state lives external (no plugin store).
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Shared dual-receipt emit fold and the F01 latest-needs fold the peek verb resolves with.
  receiptsFold = import ../../shell-tools/receipts.nix;
  attention = import ../../shell-tools/attention.nix {};

  # --- [WATCH_ROWS]
  # Monitor panels as data: viddy owns history/diff memory, gping owns latency graphs. Rows launch as floating panes, never prompt/status hot
  # paths; the command runs in the pane's own PATH (user env), not this script's closure.
  watchRows = {
    git-status = {
      cmd = "viddy --differences --interval 5 -- git status --short --branch";
      desc = "working-tree status with change memory";
    };
    git-diff = {
      cmd = "viddy --differences --interval 10 -- git diff --stat";
      desc = "diffstat with change memory";
    };
    failures = {
      cmd = "viddy --interval 30 -- forge-receipts --failures --limit 15";
      desc = "failing receipt rows across estate logs";
    };
    attention = {
      cmd = "viddy --interval 5 -- forge-zellij peek --attention --text";
      desc = "waiting agent pane tail (collector-resolved)";
    };
    drift = {
      cmd = "viddy --interval 60 -- forge-receipts --kind drift --limit 5";
      desc = "flake-input drift receipts";
    };
    net = {
      cmd = "gping 1.1.1.1 9.9.9.9";
      desc = "network latency graph";
    };
  };
  watchJson = pkgs.writeText "forge-zellij-watch.json" (builtins.toJSON watchRows);

  # Project-root ingress: one parent directory owns the estate repos; worktree rows derive from each root's git state at runtime.
  projectRootParents = ["${config.home.homeDirectory}/Documents/99.Github"];

  # Inner session identity rides the name-policy register: the outer plane (forge-workspace) attaches estate repos by slug, so the graph's project
  # arm resolves the same row — one repo never forks into basename- and slug-named sessions. Unregistered roots keep their basename.
  sessionSlugArms =
    lib.concatMapStrings (r: "          ${lib.escapeShellArg r.source}) printf '%s' ${lib.escapeShellArg r.slug} ;;\n")
    (lib.filter (r: lib.elem "zellij-session-name" r.consumers) config.forge.registers.naming);

  # Per-command fzf theme: the theme owner's shared fzf vocabulary (global fzf options stay theme-only in fzf.nix).
  fzfColorRows = config.forge.theme.projections.fzfColorRows;
  fzfBaseArgs = fzfColorRows ++ ["--border=sharp" "--layout=reverse" "--info=right" "--highlight-line" "--prompt=❯ " "--pointer=❯"];
  fzfArgsBash = "fzf_base=(\n${lib.concatMapStringsSep "\n" (a: "        ${lib.escapeShellArg a}") fzfBaseArgs}\n      )";

  watchPanel = config.programs.zellij.popupGeometry.watchPanel;

  forgeZellij = pkgs.writeShellApplication {
    name = "forge-zellij";
    runtimeInputs = [pkgs.zellij pkgs.jq pkgs.fzf pkgs.coreutils pkgs.gawk pkgs.findutils pkgs.git pkgs.bash];
    text = ''
            self="''${BASH_SOURCE[0]}"
            watch_catalog="${watchJson}"
            state_root="''${XDG_STATE_HOME:-$HOME/.local/state}/forge"
            stars_file="$state_root/zellij-stars.tsv"
            macros_file="$state_root/zellij-macros.tsv"
            recorded_dir="$state_root/zellij-layouts"
            lanes_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/forge/agent-lanes.json"
            layouts_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/zellij/layouts"
            receipt_log="''${FORGE_ZELLIJ_RECEIPT_LOG:-$HOME/Library/Logs/forge-zellij.receipts.log}"
            session="''${ZELLIJ_SESSION_NAME:-}"
            # Session routing for detached callers: verbs that target another session (peek --session) fill this vector; every zellij action
            # then rides it, so one snapshot kernel serves attached + detached.
            session_args=()
            mkdir -p "$state_root" "$recorded_dir"
            ${fzfArgsBash}

            receipt_surface="forge-zellij"
            ${receiptsFold}
            # Shared F01 latest-needs fold (attention.nix).
            att_defs=${lib.escapeShellArg attention.latestNeedsJq}
            emit_receipt() { # $1=verb $2=row_kind $3=row_id $4=action $5=result $6=exit $7=duration_ms
              local ts row
              TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
              printf -v row 'ts=%s\tverb=%s\trow_kind=%s\trow_id=%s\taction=%s\tsession_id=%s\tpane_id=%s\tcwd=%s\texit=%s\tduration_ms=%s\tresult=%s' \
                "$ts" "$1" "''${2:--}" "''${3:--}" "$4" "''${session:--}" "''${ZELLIJ_PANE_ID:--}" "$PWD" "$6" "$7" "$5"
              append_receipt "$row" \
                || printf 'forge-zellij: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
            }

            zj_json() { # zellij action "$@" --json; retry a flapping snapshot to a truthy array
              local out=""
              for _ in 1 2 3 4 5; do
                out="$(zellij "''${session_args[@]}" action "$@" --json 2>/dev/null || true)"
                if jq -e 'type == "array" and length > 0' <<<"$out" >/dev/null 2>&1; then
                  printf '%s' "$out"
                  return 0
                fi
                sleep 0.2
              done
              if jq -e 'type == "array"' <<<"$out" >/dev/null 2>&1; then printf '%s' "$out"; else echo '[]'; fi
            }

            pane_arg() { # normalize a pane reference: raw id, pane:N, star:N row_ids
              local p="''${1#pane:}"
              p="''${p#star:}"
              if [[ ! "$p" =~ ^[0-9]+$ ]]; then
                echo "not a pane row: $1" >&2
                return 64
              fi
              printf '%s' "$p"
            }

            session_name_of() { # project basename -> name-policy slug when a row claims it
              case "$1" in
      ${sessionSlugArms}          *) printf '%s' "$1" ;;
              esac
            }

            # Resurrection-with-cause fold: the newest fabric receipt per session (forge-zellij session_id + forge-workspace slug JSONL tails)
            # becomes a name -> "last: verb result ts" map, so an EXITED row says WHY it matters, not merely that it died.
            # Torn tail lines skip via fromjson? (live-appended JSONL law).
            exited_cause_map() {
              local ws_log="''${FORGE_WORKSPACE_RECEIPT_LOG:-$HOME/Library/Logs/forge-workspace.receipts.log}"
              { tail -qn 400 "''${receipt_log%.log}.jsonl" "''${ws_log%.log}.jsonl" 2>/dev/null || true; } \
                | jq -Rcn '[inputs | fromjson? | select(type == "object")
                    | {s: ((.session_id // .slug // "-") | tostring), ts: ((.ts // "") | tostring),
                       what: ((.verb // .action // "-") | tostring), result: ((.result // "-") | tostring)}
                    | select(.s != "-" and .s != "" and .ts != "")]
                  | group_by(.s) | map(max_by(.ts))
                  | map({key: .s, value: ("last: " + .what + " " + .result + " " + .ts)}) | from_entries'
            }

            # --- [DISCRIMINATED_INVENTORY_ONE_ROW_GRAMMAR]
            inventory() {
              # sessions: live and resurrectable (list-sessions exits 1 when none); jq owns escaping, the cause map enriches EXITED rows.
              (zellij list-sessions --no-formatting 2>/dev/null || true) | jq -Rc --argjson causes "$(exited_cause_map)" '
                select(length > 0)
                | (split(" ")[0]) as $name
                | (if test("EXITED") then "session-exited" else "session" end) as $kind
                | (sub("^\\S+ "; "") | gsub("[\\x00-\\x1f]"; " ")) as $detail
                | {row_id: ($kind + ":" + $name), kind: $kind, label: $name,
                   detail: (if $kind == "session-exited" and (($causes[$name] // "") != "")
                            then $detail + " — " + $causes[$name] else $detail end),
                   target: $name}'
              if [[ -n "$session" ]]; then
                zj_json list-tabs | jq -c '.[] | {row_id: ("tab:" + (.tab_id | tostring)), kind: "tab",
                  label: .name, detail: ("swap=" + (.active_swap_layout_name // "-") + (if .active then " active" else "" end)),
                  target: (.tab_id | tostring)}'
                # ONE pane snapshot feeds pane rows and star liveness: two probes could disagree mid-mutation and star a vanished pane.
                panes="$(zj_json list-panes --all)"
                jq -c '.[]? | select((.is_plugin | not) and (.exited | not))
                  | {row_id: ("pane:" + (.id | tostring)), kind: "pane",
                     label: ((.title // "") | if . == "" then "pane" else . end),
                     detail: ("tab=" + (.tab_id | tostring) + " cmd=" + ((.terminal_command // .command // "-") | .[0:40])),
                     target: (.id | tostring)}' <<<"$panes"
                if [[ -r "$stars_file" ]]; then
                  live="$(jq -c '[.[] | select(.is_plugin | not) | (.id | tostring)]' <<<"$panes")"
                  gawk -F'\t' -v s="$session" '$1 == s {printf "%s\t%s\n", $2, $3}' "$stars_file" \
                    | jq -Rc --argjson live "$live" '(split("\t")) as [$pid, $title]
                        | select($live | index($pid) != null)
                        | {row_id: ("star:" + $pid), kind: "starred-pane", label: ("★ " + $title), detail: ("pane=" + $pid), target: $pid}'
                fi
              fi
              root_parents=(${lib.escapeShellArgs projectRootParents})
              for parent in "''${root_parents[@]}"; do
                [[ -d "$parent" ]] || continue
                find "$parent" -mindepth 1 -maxdepth 1 -type d ! -name '.*' | sort | while IFS= read -r root; do
                  jq -cn --arg root "$root" \
                    '{row_id: ("project:" + ($root | split("/") | last)), kind: "project",
                      label: ($root | split("/") | last), detail: $root, target: $root}'
                  if [[ -e "$root/.git" ]]; then
                    # sub() keeps the whole path ($2 truncates at a space); the rail treats a worktree-less or odd repo as empty, not fatal.
                    (git -C "$root" worktree list --porcelain 2>/dev/null || true) | gawk '/^worktree /{sub(/^worktree /, ""); print}' \
                      | tail -n +2 \
                      | jq -Rc --arg root "$root" '(split("/") | last) as $n
                          | {row_id: ("worktree:" + $n), kind: "worktree",
                             label: (($root | split("/") | last) + "@" + $n), detail: ., target: .}'
                  fi
                done
              done
              for dir in "$layouts_dir" "$recorded_dir"; do
                [[ -d "$dir" ]] || continue
                src="$([[ "$dir" == "$recorded_dir" ]] && echo recorded || echo generated)"
                find "$dir" \( -type f -o -type l \) -name '*.kdl' ! -name '*.swap.kdl' | sort \
                  | jq -Rc --arg src "$src" '(split("/") | last | rtrimstr(".kdl")) as $n
                      | {row_id: ("layout:" + $n), kind: "layout", label: $n, detail: $src, target: .}'
              done
              if [[ -r "$macros_file" ]]; then
                gawk -F'\t' 'NF >= 2 {printf "%s\t%s\n", $1, $2}' "$macros_file" \
                  | jq -Rc '(split("\t")) as [$name, $cmd]
                      | {row_id: ("macro:" + $name), kind: "macro", label: $name, detail: $cmd, target: $cmd}'
              fi
              if [[ -r "$lanes_cache" ]]; then
                jq -c 'if type == "array" then .[] else empty end
                  | {row_id: ("lane:" + (.lane // "?")), kind: "agent-lane",
                     label: (.lane // "?"), detail: ("status=" + (.status // "?")),
                     target: ((.pane_id // "") | tostring)}' "$lanes_cache" 2>/dev/null || true
              fi
            }

            # first() stops inside jq: a head(1) sibling EPIPEs the writer under pipefail once the inventory outgrows the pipe buffer.
            row_of() { inventory | jq -cn --arg id "$1" 'first(inputs | select(.row_id == $id))'; }

            preview_row() { # $1 = row_id — read-only evidence only
              local row kind target
              row="$(row_of "$1")"
              [[ -n "$row" ]] || { printf 'no row: %s\n' "$1"; return 1; }
              # One projection per row snapshot: evidence lines plus a 0x1f kind/target tail line, split shell-side — no per-field jq forks.
              local proj
              proj="$(jq -r '(to_entries[] | "\(.key): \(.value)"), ([.kind, .target] | join("\u001f"))' <<<"$row")"
              printf '%s\n' "''${proj%$'\n'*}"
              IFS=$'\x1f' read -r kind target <<<"''${proj##*$'\n'}"
              case "$kind" in
                layout)
                  printf '\n'
                  head -25 "$target" 2>/dev/null || true
                  ;;
                project | worktree)
                  printf '\n'
                  find "$target" -mindepth 1 -maxdepth 1 2>/dev/null | gawk -F/ '{print $NF}' | sort | head -15 || true
                  ;;
              esac
            }

            # --- [VERB_DISPATCH]
            verb="''${1:-graph}"
            case "$verb" in
              --help | -h)
                printf 'Usage: forge-zellij [graph [--json]] | row ID | state | star [--pane ID] | unstar\n'
                printf '       | layout record [NAME] | layout apply NAME|PATH | watch [ROW] | watch --list\n'
                printf '       | macro add NAME CMD... | macro rm NAME | macro list\n'
                printf '       | peek [--session S] [--pane N] [--lines N] [--attention] [--text]\n'
                exit 0
                ;;

              row)
                preview_row "''${2:?row needs a row_id}"
                exit 0
                ;;

              state)
                # Read-only fabric snapshot, schema v2: sessions classify live|resurrectable and carry serialization freshness (the per-session
                # cache mtime as serialized_ts) plus the newest fabric receipt (exited_cause_map) — resurrection joined to the
                # receipts plane as one queryable envelope.
                srows="$( (zellij list-sessions --no-formatting 2>/dev/null || true) | jq -Rcn '
                  [inputs | select(length > 0)
                   | {name: (split(" ")[0]),
                      state: (if test("EXITED") then "resurrectable" else "live" end),
                      detail: (sub("^\\S+ "; "") | gsub("[\\x00-\\x1f]"; " "))}]')"
                ser_rows=""
                while IFS= read -r n; do # streaming boundary: one stat pass per session name
                  [[ -n "$n" ]] || continue
                  # Newest metadata wins across contract-version dirs (glob order is lexicographic, so version 10 would sort under version 2).
                  ts="$( (stat -c %Y "$HOME/Library/Caches/org.Zellij-Contributors.Zellij"/contract_version_*/session_info/"$n"/session-metadata.kdl 2>/dev/null || true) | sort -rn | head -1)"
                  [[ -z "$ts" ]] || ser_rows+="$n"$'\t'"$ts"$'\n'
                done < <(jq -r '.[].name' <<<"$srows")
                ser_map="$(jq -Rsc 'split("\n") | map(select(length > 0) | split("\t") | {key: .[0], value: (.[1] | tonumber)}) | from_entries' <<<"$ser_rows")"
                jq -n --arg session "''${session:--}" \
                  --argjson sessions "$(jq -c --argjson ser "$ser_map" --argjson causes "$(exited_cause_map)" \
                    'map(. + {serialized_ts: (($ser[.name] // null) | if . then todate else null end),
                              last: ($causes[.name] // null)})' <<<"$srows")" \
                  --argjson tabs "$([[ -n "$session" ]] && zj_json list-tabs || echo '[]')" \
                  --argjson panes "$([[ -n "$session" ]] && zj_json list-panes --all || echo '[]')" \
                  '{schema: "forge-zellij-state/v2", session: $session, sessions: $sessions,
                    tabs: $tabs, panes: ($panes | map(select(.is_plugin | not)))}'
                exit 0
                ;;

              peek)
                # Typed pane capture without temp files: one `subscribe` initial frame (NDJSON pane_update: viewport + scrollback, ANSI-stripped)
                # becomes a JSON envelope. --attention resolves the collector's latest attention row so "what does the waiting pane say" is one
                # command; --session targets any live session from a detached shell. Read-only inspector — no receipt, like `state`.
                shift
                peek_session="$session" peek_pane="" lines=20 render=json
                while [[ "$#" -gt 0 ]]; do
                  case "$1" in
                    --session) peek_session="''${2:?--session needs a name}"; shift ;;
                    --pane) peek_pane="''${2:?--pane needs an id}"; shift ;;
                    --lines) lines="''${2:?--lines needs a count}"; shift ;;
                    --attention)
                      att_row="$(jq -c '.attention.latest // empty' "$state_root/agent-state.json" 2>/dev/null || true)"
                      [[ -n "$att_row" ]] || att_row="$(tail -n 500 "''${FORGE_ATTENTION_FEED:-$state_root/agent-attention.jsonl}" 2>/dev/null \
                        | jq -Rcn "$att_defs latest_needs" 2>/dev/null || true)"
                      [[ -n "$att_row" ]] || { echo "peek: no attention row to resolve" >&2; exit 66; }
                      IFS=$'\x1f' read -r peek_session peek_pane < <(jq -r \
                        '[.zellij_session // "", .zellij_pane // ""] | join("\u001f")' <<<"$att_row")
                      [[ -n "$peek_session" && -n "$peek_pane" ]] \
                        || { echo "peek: latest attention row carries no zellij identity" >&2; exit 66; }
                      ;;
                    --text) render=text ;;
                    *) echo "peek: unknown argument $1" >&2; exit 64 ;;
                  esac
                  shift
                done
                case "$lines" in "" | *[!0-9]*) echo "peek: --lines must be numeric" >&2; exit 64 ;; esac
                # Session routing lands BEFORE pane resolution: a detached `peek --session S` resolves S's focused pane, not the caller's absent one.
                [[ -z "$peek_session" || "$peek_session" == "$session" ]] || session_args=(--session "$peek_session")
                if [[ -z "$peek_pane" ]]; then
                  [[ -n "$peek_session" ]] || { echo "peek needs --pane, --attention, or a Zellij session" >&2; exit 64; }
                  peek_pane="$(zj_json list-panes --all | jq -r \
                    'first(.[] | select(.is_focused and (.is_plugin | not)) | .id) // empty')"
                  [[ -n "$peek_pane" ]] || { echo "peek: no focused terminal pane" >&2; exit 66; }
                fi
                peek_pane="$(pane_arg "$peek_pane")" || exit 64
                # First NDJSON frame only: head closes the pipe after the initial pane_update; timeout backstops a dead session or renamed pane.
                frame="$({ timeout 5 zellij "''${session_args[@]}" subscribe \
                  --pane-id "terminal_$peek_pane" -s "$lines" -f json 2>/dev/null || true; } | head -n1)"
                [[ -n "$frame" ]] || { echo "peek: no frame from terminal_$peek_pane (dead session or pane?)" >&2; exit 69; }
                envelope="$(jq -c --arg session "''${peek_session:--}" --argjson n "$lines" '
                  select(.event == "pane_update")
                  | {schema: "forge-zellij-peek/v1", session: $session, pane_id, is_initial,
                     viewport, scrollback,
                     tail: ((.scrollback + .viewport) | map(sub("\\s+$"; "")) | map(select(. != "")) | .[-$n:])}' \
                  <<<"$frame" 2>/dev/null || true)"
                [[ -n "$envelope" ]] || { echo "peek: unexpected frame shape from subscribe" >&2; exit 69; }
                if [[ "$render" == text ]]; then
                  jq -r '.tail[]' <<<"$envelope"
                else
                  printf '%s\n' "$envelope"
                fi
                exit 0
                ;;

              star)
                [[ -n "$session" ]] || { echo "star requires a Zellij session" >&2; exit 1; }
                pane="''${ZELLIJ_PANE_ID:-}"
                if [[ "''${2:-}" == "--pane" ]]; then pane="''${3:?--pane needs an id}"; fi
                pane="$(pane_arg "$pane")" || exit 64
                title="$(zj_json list-panes --all \
                  | jq -r --arg id "$pane" '[.[] | select((.is_plugin | not) and ((.id | tostring) == $id))][0].title // "pane"')"
                title="''${title//[$'\t\n']/ }" # pane titles are free text; the stars store is TSV
                if ! gawk -F'\t' -v s="$session" -v p="$pane" '$1 == s && $2 == p {found = 1} END {exit !found}' "$stars_file" 2>/dev/null; then
                  TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
                  printf '%s\t%s\t%s\t%s\n' "$session" "$pane" "$title" "$ts" >>"$stars_file"
                fi
                emit_receipt star starred-pane "star:$pane" add ok 0 0
                exit 0
                ;;

              unstar)
                [[ -n "$session" ]] || { echo "unstar requires a Zellij session" >&2; exit 1; }
                pane="$(pane_arg "''${2:-''${ZELLIJ_PANE_ID:-}}")" || exit 64
                if [[ -r "$stars_file" ]]; then
                  gawk -F'\t' -v s="$session" -v p="$pane" '!($1 == s && $2 == p)' "$stars_file" >"$stars_file.tmp"
                  mv "$stars_file.tmp" "$stars_file"
                fi
                emit_receipt unstar starred-pane "star:$pane" remove ok 0 0
                exit 0
                ;;

              macro)
                # Macro rows are rail-owned, never a hand-edited TSV: add replaces an existing NAME row, rm deletes it, list projects the row set.
                sub="''${2:?macro needs add|rm|list}"
                case "$sub" in
                  add)
                    name="''${3:?macro add needs NAME}"
                    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "macro add: NAME must be [A-Za-z0-9._-]+" >&2; exit 64; }
                    shift 3
                    [[ $# -gt 0 ]] || { echo "macro add: needs a command" >&2; exit 64; }
                    cmd="$*"
                    [[ "$cmd" != *[$'\t\n']* ]] || { echo "macro add: command must not contain tab or newline" >&2; exit 64; }
                    gawk -F'\t' -v n="$name" '$1 != n' "$macros_file" 2>/dev/null >"$macros_file.tmp" || true
                    printf '%s\t%s\n' "$name" "$cmd" >>"$macros_file.tmp"
                    mv "$macros_file.tmp" "$macros_file"
                    emit_receipt macro macro "macro:$name" add ok 0 0
                    ;;
                  rm)
                    name="''${3:?macro rm needs NAME}"
                    [[ -r "$macros_file" ]] || { echo "macro rm: no macros recorded" >&2; exit 66; }
                    gawk -F'\t' -v n="$name" '$1 == n {found = 1} END {exit !found}' "$macros_file" \
                      || { echo "macro rm: unknown macro $name" >&2; exit 66; }
                    gawk -F'\t' -v n="$name" '$1 != n' "$macros_file" >"$macros_file.tmp"
                    mv "$macros_file.tmp" "$macros_file"
                    emit_receipt macro macro "macro:$name" remove ok 0 0
                    ;;
                  list)
                    if [[ -r "$macros_file" ]]; then
                      gawk -F'\t' 'NF >= 2 {printf "%s\t%s\n", $1, $2}' "$macros_file"
                    fi
                    ;;
                  *) echo "macro: add|rm|list" >&2; exit 64 ;;
                esac
                exit 0
                ;;

              layout)
                sub="''${2:?layout needs record|apply}"
                case "$sub" in
                  record)
                    # NAME defaults to the session: a bare `layout record` is the freeze verb — the live composition lands under the slug, and
                    # the workspace spawn seam picks it up next run.
                    [[ -n "$session" ]] || { echo "layout record requires a Zellij session" >&2; exit 1; }
                    name="''${3:-$session}"
                    # Dump to a trap-reaped temp beside the target: a failed re-record must never eat the prior asset under the name.
                    out="$recorded_dir/''${name}.kdl"
                    tmp_out="$recorded_dir/.gate-$$.kdl"
                    trap 'rm -f "$tmp_out"' EXIT
                    zellij action dump-layout >"$tmp_out"
                    # Parse gate: a disposable background session must accept the recorded asset before it replaces the graph row.
                    gate="forge-layout-gate-$$"
                    gate_ok="false"
                    if zellij attach --create-background "$gate" >/dev/null 2>&1; then
                      if zellij --session "$gate" action new-tab --layout "$tmp_out" >/dev/null 2>&1; then
                        sleep 0.5
                        tabs="$( (zellij --session "$gate" action query-tab-names 2>/dev/null || true) | wc -l | tr -d ' ')"
                        [[ "$tabs" -ge 2 ]] && gate_ok="true"
                      fi
                      zellij kill-session "$gate" >/dev/null 2>&1 || true
                      zellij delete-session "$gate" >/dev/null 2>&1 || true
                    fi
                    if [[ "$gate_ok" == "true" ]]; then
                      mv "$tmp_out" "$out"
                      emit_receipt layout-record layout "layout:$name" record ok 0 0
                      printf '%s\n' "$out"
                    else
                      emit_receipt layout-record layout "layout:$name" record error 1 0
                      echo "layout record: parse gate failed; asset discarded" >&2
                      exit 1
                    fi
                    ;;
                  apply)
                    ref="''${3:?layout apply needs NAME or PATH}"
                    path="$ref"
                    [[ -f "$path" ]] || path="$recorded_dir/''${ref}.kdl"
                    [[ -f "$path" ]] || path="$layouts_dir/''${ref}.kdl"
                    [[ -f "$path" ]] || { echo "layout apply: no asset for $ref" >&2; exit 66; }
                    [[ -n "$session" ]] || { echo "layout apply requires a Zellij session" >&2; exit 1; }
                    zellij action new-tab --layout "$path" --name "$(basename "$path" .kdl)"
                    emit_receipt layout-apply layout "layout:$(basename "$path" .kdl)" new-tab ok 0 0
                    ;;
                  *) echo "layout: record|apply" >&2; exit 64 ;;
                esac
                exit 0
                ;;

              watch)
                arg="''${2:-}"
                if [[ "$arg" == "--list" || -z "$arg" ]]; then
                  if [[ -z "$arg" ]]; then
                    arg="$(jq -r 'to_entries[] | [.key, .value.desc] | @tsv' "$watch_catalog" \
                      | fzf --delimiter=$'\t' --border-label='[WATCH]' --height=60% "''${fzf_base[@]}" | cut -f1)" || true
                    [[ -n "$arg" ]] || exit 0
                  else
                    jq -r 'to_entries[] | [.key, .value.desc] | @tsv' "$watch_catalog"
                    exit 0
                  fi
                fi
                jq -e --arg r "$arg" 'has($r)' "$watch_catalog" >/dev/null || { echo "watch: unknown row $arg" >&2; exit 64; }
                [[ -n "$session" ]] || { echo "watch requires a Zellij session" >&2; exit 1; }
                zellij action new-pane --floating --name " [WATCH:$arg] " \
                  -x "${watchPanel.x}" -y "${watchPanel.y}" --width "${watchPanel.width}" --height "${watchPanel.height}" \
                  --cwd "$PWD" -- forge-zellij watch-exec "$arg" >/dev/null
                emit_receipt watch monitor "watch:$arg" float-pane ok 0 0
                exit 0
                ;;

              watch-exec)
                # Monitor-pane body: run the row command and close the receipt loop with the exit transition — panels carry linkage, never bare
                # bash. The HUP/TERM trap keeps the exit receipt alive through close-pane.
                arg="''${2:?watch-exec needs a row}"
                cmd="$(jq -r --arg r "$arg" '.[$r].cmd // empty' "$watch_catalog")"
                [[ -n "$cmd" ]] || { echo "watch-exec: unknown row $arg" >&2; exit 64; }
                start="''${EPOCHREALTIME//[.,]/}"
                rc=0
                emitted=0
                finish() {
                  if [[ "$emitted" == 1 ]]; then return 0; fi
                  emitted=1
                  local end result=ok
                  end="''${EPOCHREALTIME//[.,]/}"
                  [[ "$rc" == 0 || "$rc" == 129 || "$rc" == 130 || "$rc" == 143 ]] || result=error
                  emit_receipt watch-exec monitor "watch:$arg" run "$result" "$rc" $(((end - start) / 1000))
                }
                trap 'rc=129; finish' HUP
                trap 'rc=143; finish' TERM
                bash -c "$cmd" || rc=$?
                finish
                exit "$rc"
                ;;

              graph) ;;
              *) echo "forge-zellij: unknown verb $verb" >&2; exit 64 ;;
            esac

            if [[ "''${2:-}" == "--json" ]]; then
              inventory
              exit 0
            fi

            # One inventory snapshot feeds the picker AND target resolution: a re-scan after selection could miss a vanished row and dispatch an
            # empty target. fzf reads a fully rendered list — a pick made while jq still streams EPIPEs jq and fails a valid selection.
            start="''${EPOCHREALTIME//[.,]/}"
            rc=0
            inv="$(inventory)"
            rows_tsv="$(jq -r '[.kind, .row_id, .label, .detail] | @tsv' <<<"$inv")"
            sel="$(fzf --delimiter=$'\t' --border-label='[WORKSPACE GRAPH]' --height=100% \
              --with-nth=1,3,4 --print-query \
              --preview="$self row {2}" --preview-window=right:50%:border-bold \
              --bind "ctrl-s:execute-silent($self star --pane {2})" \
              "''${fzf_base[@]}" <<<"$rows_tsv")" || rc=$?
            end="''${EPOCHREALTIME//[.,]/}"
            duration_ms=$(((end - start) / 1000))
            # fzf --print-query contract: line 1 query, line 2 selection.
            mapfile -t sel_lines <<<"$sel"
            line="''${sel_lines[1]:-}"
            if [[ "$rc" != 0 || -z "$line" ]]; then
              case "$rc" in
                0 | 1 | 130) emit_receipt graph - - cancel ok "$rc" "$duration_ms"; exit 0 ;;
                *) emit_receipt graph - - browse error "$rc" "$duration_ms"; exit "$rc" ;;
              esac
            fi
            IFS=$'\t' read -r kind row_id _ <<<"$line"
            target="$(jq -rn --arg id "$row_id" 'first(inputs | select(.row_id == $id) | .target)' <<<"$inv")"

            # Selection dispatch: total over the kind family; unreachable actions (attach from inside) degrade to printed evidence, never a nested client.
            case "$kind" in
              session | session-exited)
                if [[ -z "$session" ]]; then
                  emit_receipt graph "$kind" "$row_id" attach ok 0 "$duration_ms"
                  exec zellij attach "$target"
                fi
                emit_receipt graph "$kind" "$row_id" print ok 0 "$duration_ms"
                printf 'zellij attach %q\n' "$target"
                ;;
              tab)
                zellij action go-to-tab-by-id "$target"
                emit_receipt graph tab "$row_id" go-to-tab ok 0 "$duration_ms"
                ;;
              pane | starred-pane | agent-lane)
                # Best-effort focus: the pane may vanish between snapshot and click; a dead id must not kill the run before its receipt.
                [[ -z "$target" ]] || zellij action focus-pane-id "terminal_''${target}" >/dev/null 2>&1 || true
                emit_receipt graph "$kind" "$row_id" focus-pane ok 0 "$duration_ms"
                ;;
              project | worktree)
                if [[ -n "$session" ]]; then
                  zellij action new-tab --name "$(basename "$target")" --cwd "$target"
                  emit_receipt graph "$kind" "$row_id" new-tab ok 0 "$duration_ms"
                else
                  emit_receipt graph "$kind" "$row_id" attach-create ok 0 "$duration_ms"
                  cd "$target" && exec zellij attach --create "$(session_name_of "$(basename "$target")")"
                fi
                ;;
              layout)
                zellij action new-tab --layout "$target" --name "$(basename "$target" .kdl)"
                emit_receipt graph layout "$row_id" new-tab ok 0 "$duration_ms"
                ;;
              macro)
                zellij action new-pane --floating --name " [MACRO] " --cwd "$PWD" -- bash -c "$target" >/dev/null
                emit_receipt graph macro "$row_id" float-pane ok 0 "$duration_ms"
                ;;
            esac
    '';
  };

  # The _arguments (...) action is a literal word list — parameter references inside it never expand, so the verb row renders inline from Nix.
  watchNames = lib.attrNames watchRows;
  opsVerbs = ["graph" "row" "state" "peek" "star" "unstar" "layout" "watch" "macro"];
  opsCompletion = pkgs.writeTextDir "share/zsh/site-functions/_forge-zellij" ''
    #compdef forge-zellij
    _arguments \
      '1:verb:(${lib.concatStringsSep " " opsVerbs})' \
      '*::arg:->args'
    case "''${words[2]:-}" in
      layout) _values 'layout' record apply ;;
      watch) _values 'watch row' ${lib.concatStringsSep " " watchNames} ;;
      macro) _values 'macro' add rm list ;;
      peek) _values 'peek option' --session --pane --lines --attention --text ;;
    esac
  '';
in {
  home.packages = [forgeZellij opsCompletion];
}
