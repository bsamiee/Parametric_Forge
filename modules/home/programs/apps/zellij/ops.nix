# Title         : ops.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/ops.nix
# ----------------------------------------------------------------------------
# Inner-ops owner: forge-zellij is ONE polymorphic command over the
# discriminated workspace graph (session, tab, pane, starred pane, project
# root, worktree, layout, macro, agent lane), layout live assets (record/apply
# with a disposable-session parse gate), watch-with-memory monitor rows, and a
# read-only state inspector. Every mutating or probing verb emits one typed
# kv receipt; fzf fronts the graph, state lives external (no plugin store).
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette;

  # --- Watch rows -------------------------------------------------------------
  # Monitor panels as data: viddy owns history/diff memory, gping owns latency
  # graphs. Rows launch as floating panes, never prompt/status hot paths; the
  # command runs in the pane's own PATH (user env), not this script's closure.
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

  # Project-root ingress: one parent directory owns the estate repos; worktree
  # rows derive from each root's git state at runtime.
  projectRootParents = ["${config.home.homeDirectory}/Documents/99.Github"];

  # Inner session identity rides the name-policy register: the outer plane
  # (forge-workspace) attaches estate repos by slug, so the graph's project arm
  # resolves the same row — one repo never forks into basename- and slug-named
  # sessions. Unregistered roots keep their basename.
  sessionSlugArms =
    lib.concatMapStrings (r: "          ${lib.escapeShellArg r.source}) printf '%s' ${lib.escapeShellArg r.slug} ;;\n")
    (lib.filter (r: lib.elem "zellij-session-name" r.consumers) config.forge.registers.naming);

  # Per-command fzf theme projection from the palette owner (same pattern as
  # the register rail; global fzf options stay theme-only in fzf.nix).
  fzfColorRows = [
    "--color=fg:${palette.foreground.hex},fg+:${palette.background.hex},bg:${palette.background.hex},bg+:${palette.cyan.hex},selected-fg:${palette.background.hex},selected-bg:${palette.cyan.hex}"
    "--color=hl:${palette.green.hex},hl+:${palette.magenta.hex},info:${palette.comment.hex},marker:${palette.green.hex}"
    "--color=prompt:${palette.magenta.hex},spinner:${palette.green.hex},pointer:${palette.magenta.hex},header:${palette.comment.hex}"
    "--color=gutter:${palette.background.hex},border:${palette.cyan.hex},separator:${palette.pink.hex},scrollbar:${palette.pink.hex}"
    "--color=preview-fg:${palette.foreground.hex},preview-scrollbar:${palette.pink.hex},label:${palette.magenta.hex},query:${palette.foreground.hex}"
  ];
  fzfBaseArgs = fzfColorRows ++ ["--border=sharp" "--layout=reverse" "--info=right" "--highlight-line" "--prompt=❯ " "--pointer=❯"];
  fzfArgsBash = "fzf_base=(\n${lib.concatMapStringsSep "\n" (a: "        ${lib.escapeShellArg a}") fzfBaseArgs}\n      )";

  watchPanel = config.programs.zellij.popupGeometry.watchPanel;

  forgeZellij = pkgs.writeShellApplication {
    name = "forge-zellij";
    runtimeInputs = [pkgs.zellij pkgs.jq pkgs.fzf pkgs.coreutils pkgs.gawk pkgs.findutils pkgs.git pkgs.bash];
    text = ''
            # Usage: forge-zellij [graph [--json]] | row ID | state | star [--pane ID]
            #        | unstar | layout record NAME | layout apply NAME|PATH
            #        | watch [ROW] | watch --list | macro add NAME CMD... | macro rm NAME
            # watch-exec ROW is the monitor-pane body: it wraps the row command with
            # start/exit receipts so panels carry exit transitions, never bare bash.
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
            mkdir -p "$state_root" "$recorded_dir"
            ${fzfArgsBash}

            emit_receipt() { # $1=verb $2=row_kind $3=row_id $4=action $5=result $6=exit $7=duration_ms
              local ts
              TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
              mkdir -p "$(dirname "$receipt_log")"
              printf 'ts=%s\towner=forge-zellij\tverb=%s\trow_kind=%s\trow_id=%s\taction=%s\tsession_id=%s\tpane_id=%s\tcwd=%s\texit=%s\tduration_ms=%s\tresult=%s\n' \
                "$ts" "$1" "''${2:--}" "''${3:--}" "$4" "''${session:--}" "''${ZELLIJ_PANE_ID:--}" "$PWD" "$6" "$7" "$5" >>"$receipt_log"
            }

            zj_json() { # zellij action "$@" --json; retry a flapping snapshot to a truthy array
              local out=""
              for _ in 1 2 3 4 5; do
                out="$(zellij action "$@" --json 2>/dev/null || true)"
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

            # --- Discriminated inventory: one row grammar, nine kinds ----------------
            inventory() {
              # sessions: live and resurrectable (list-sessions exits 1 when none)
              (zellij list-sessions --no-formatting 2>/dev/null || true) | gawk '
                {
                  name = $1
                  kind = ($0 ~ /EXITED/) ? "session-exited" : "session"
                  detail = $0; sub(/^[^ ]+ /, "", detail)
                  gsub(/\\/, "\\\\", name); gsub(/"/, "\\\"", name)
                  gsub(/\\/, "\\\\", detail); gsub(/"/, "\\\"", detail)
                  printf "{\"row_id\":\"%s:%s\",\"kind\":\"%s\",\"label\":\"%s\",\"detail\":\"%s\",\"target\":\"%s\"}\n", kind, name, kind, name, detail, name
                }'
              if [[ -n "$session" ]]; then
                zj_json list-tabs | jq -c '.[] | {row_id: ("tab:" + (.tab_id | tostring)), kind: "tab",
                  label: .name, detail: ("swap=" + (.active_swap_layout_name // "-") + (if .active then " active" else "" end)),
                  target: (.tab_id | tostring)}'
                zj_json list-panes --all | jq -c '.[]? | select((.is_plugin | not) and (.exited | not))
                  | {row_id: ("pane:" + (.id | tostring)), kind: "pane",
                     label: ((.title // "") | if . == "" then "pane" else . end),
                     detail: ("tab=" + (.tab_id | tostring) + " cmd=" + ((.terminal_command // .command // "-") | .[0:40])),
                     target: (.id | tostring)}'
                if [[ -r "$stars_file" ]]; then
                  live="$(zj_json list-panes --all | jq -c '[.[] | select(.is_plugin | not) | (.id | tostring)]')"
                  gawk -F'\t' -v s="$session" '$1 == s {printf "%s\t%s\n", $2, $3}' "$stars_file" \
                    | while IFS=$'\t' read -r pid title; do
                        jq -cn --arg pid "$pid" --arg title "$title" --argjson live "$live" \
                          'select($live | index($pid) != null)
                           | {row_id: ("star:" + $pid), kind: "starred-pane", label: ("★ " + $title), detail: ("pane=" + $pid), target: $pid}'
                      done
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
                    git -C "$root" worktree list --porcelain 2>/dev/null | gawk '/^worktree /{print $2}' \
                      | tail -n +2 | while IFS= read -r wt; do
                        jq -cn --arg wt "$wt" --arg root "$root" \
                          '{row_id: ("worktree:" + ($wt | split("/") | last)), kind: "worktree",
                            label: (($root | split("/") | last) + "@" + ($wt | split("/") | last)),
                            detail: $wt, target: $wt}'
                      done
                  fi
                done
              done
              for dir in "$layouts_dir" "$recorded_dir"; do
                [[ -d "$dir" ]] || continue
                find "$dir" \( -type f -o -type l \) -name '*.kdl' ! -name '*.swap.kdl' | sort | while IFS= read -r f; do
                  jq -cn --arg f "$f" --arg src "$([[ "$dir" == "$recorded_dir" ]] && echo recorded || echo generated)" \
                    '{row_id: ("layout:" + ($f | split("/") | last | rtrimstr(".kdl"))), kind: "layout",
                      label: ($f | split("/") | last | rtrimstr(".kdl")), detail: $src, target: $f}'
                done
              done
              if [[ -r "$macros_file" ]]; then
                gawk -F'\t' 'NF >= 2 {printf "%s\t%s\n", $1, $2}' "$macros_file" | while IFS=$'\t' read -r name cmd; do
                  jq -cn --arg name "$name" --arg cmd "$cmd" \
                    '{row_id: ("macro:" + $name), kind: "macro", label: $name, detail: $cmd, target: $cmd}'
                done
              fi
              if [[ -r "$lanes_cache" ]]; then
                jq -c 'if type == "array" then .[] else empty end
                  | {row_id: ("lane:" + (.lane // "?")), kind: "agent-lane",
                     label: (.lane // "?"), detail: ("status=" + (.status // "?")),
                     target: ((.pane_id // "") | tostring)}' "$lanes_cache" 2>/dev/null || true
              fi
            }

            row_of() { inventory | jq -c --arg id "$1" 'select(.row_id == $id)' | head -1; }

            preview_row() { # $1 = row_id — read-only evidence only
              local row kind target
              row="$(row_of "$1")"
              [[ -n "$row" ]] || { printf 'no row: %s\n' "$1"; return 1; }
              jq -r 'to_entries[] | "\(.key): \(.value)"' <<<"$row"
              kind="$(jq -r '.kind' <<<"$row")"
              target="$(jq -r '.target' <<<"$row")"
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

            # --- Verb dispatch ---------------------------------------------------------
            verb="''${1:-graph}"
            case "$verb" in
              --help | -h)
                printf 'Usage: forge-zellij [graph [--json]] | row ID | state | star [--pane ID] | unstar\n'
                printf '       | layout record NAME | layout apply NAME|PATH | watch [ROW] | watch --list\n'
                printf '       | macro add NAME CMD... | macro rm NAME | macro list\n'
                exit 0
                ;;

              row)
                preview_row "''${2:?row needs a row_id}"
                exit 0
                ;;

              state)
                # Read-only session/pane snapshot (the forge-zellij-state graph row)
                jq -n --arg session "''${session:--}" \
                  --argjson tabs "$([[ -n "$session" ]] && zj_json list-tabs || echo '[]')" \
                  --argjson panes "$([[ -n "$session" ]] && zj_json list-panes --all || echo '[]')" \
                  --arg sessions "$(zellij list-sessions --no-formatting 2>/dev/null || true)" \
                  '{schema: "forge-zellij-state/v1", session: $session,
                    sessions: ($sessions | split("\n") | map(select(. != ""))),
                    tabs: $tabs, panes: ($panes | map(select(.is_plugin | not)))}'
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
                # Macro rows are rail-owned, never a hand-edited TSV: add replaces an
                # existing NAME row, rm deletes it, list projects the row set.
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
                    name="''${3:?layout record needs NAME}"
                    [[ -n "$session" ]] || { echo "layout record requires a Zellij session" >&2; exit 1; }
                    out="$recorded_dir/''${name}.kdl"
                    zellij action dump-layout >"$out"
                    # Parse gate: a disposable background session must accept the
                    # recorded asset before it becomes a graph row.
                    gate="forge-layout-gate-$$"
                    gate_ok="false"
                    if zellij attach --create-background "$gate" >/dev/null 2>&1; then
                      if zellij --session "$gate" action new-tab --layout "$out" >/dev/null 2>&1; then
                        sleep 0.5
                        tabs="$(zellij --session "$gate" action query-tab-names 2>/dev/null | wc -l | tr -d ' ')"
                        [[ "$tabs" -ge 2 ]] && gate_ok="true"
                      fi
                      zellij kill-session "$gate" >/dev/null 2>&1 || true
                      zellij delete-session "$gate" >/dev/null 2>&1 || true
                    fi
                    if [[ "$gate_ok" == "true" ]]; then
                      emit_receipt layout-record layout "layout:$name" record ok 0 0
                      printf '%s\n' "$out"
                    else
                      rm -f "$out"
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
                # Monitor-pane body: run the row command and close the receipt loop
                # with the exit transition — panels carry linkage, never bare bash.
                # The HUP/TERM trap keeps the exit receipt alive through close-pane.
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

            start="''${EPOCHREALTIME//[.,]/}"
            rc=0
            sel="$(inventory \
              | jq -r '[.kind, .row_id, .label, .detail] | @tsv' \
              | fzf --delimiter=$'\t' --border-label='[WORKSPACE GRAPH]' --height=100% \
                --with-nth=1,3,4 --print-query \
                --preview="$self row {2}" --preview-window=right:50%:border-bold \
                --bind "ctrl-s:execute-silent($self star --pane {2})" \
                "''${fzf_base[@]}")" || rc=$?
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
            kind="$(cut -f1 <<<"$line")"
            row_id="$(cut -f2 <<<"$line")"
            target="$(row_of "$row_id" | jq -r '.target')"

            # Selection dispatch: total over the kind family; unreachable actions
            # (attach from inside) degrade to printed evidence, never a nested client.
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
                # Best-effort focus: the pane may vanish between snapshot and
                # click; a dead id must not kill the run before its receipt.
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

  # The _arguments (...) action is a literal word list — parameter references
  # inside it never expand, so the verb row renders inline from Nix.
  watchNames = lib.attrNames watchRows;
  opsVerbs = ["graph" "row" "state" "star" "unstar" "layout" "watch" "macro"];
  opsCompletion = pkgs.writeTextDir "share/zsh/site-functions/_forge-zellij" ''
    #compdef forge-zellij
    _arguments \
      '1:verb:(${lib.concatStringsSep " " opsVerbs})' \
      '*::arg:->args'
    case "''${words[2]:-}" in
      layout) _values 'layout' record apply ;;
      watch) _values 'watch row' ${lib.concatStringsSep " " watchNames} ;;
      macro) _values 'macro' add rm list ;;
    esac
  '';
in {
  home.packages = [forgeZellij opsCompletion];
}
