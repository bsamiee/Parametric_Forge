#!/usr/bin/env bash
# Fleet roster renderer for the Claude Code main statusLine: one compact row for one or two external workers, then an aligned matrix for larger fleets.
# Native Claude subagents stay in the agent panel because their payload carries no effort truth. Emitted ledger workers fold with one process scan;
# unpinned Codex defaults are read by that scanner only when required, and report labels become OSC 8 file links where the process exposes -o.
set -Eeuo pipefail
shopt -s inherit_errexit

ledger="${FORGE_FLEET_LEDGER:-${XDG_STATE_HOME:-$HOME/.local/state}/forge/delegation.jsonl}"
stale="${FORGE_FLEET_STALE_SECS:-1800}"
tail_rows="${FORGE_FLEET_TAIL_ROWS:-400}"
gear="${FORGE_FLEET_GLYPH:-⛭}"
now="$EPOCHSECONDS"
# The statusLine payload names the coordinator session; worker lanes render machine-wide (the cross-session external-worker view), but the native task
# snapshot scopes to this session so a sibling session's in-flight count never inflates this roster. Empty sid (no payload) keeps every snapshot.
sid="$(jq -r '.session_id // ""' 2>/dev/null <<<"$(cat 2>/dev/null)" || true)"

fmt_el() {
    local s="$1"
    [[ "$s" =~ ^[0-9]+$ ]] || s=0
    if [ "$s" -lt 3600 ]; then
        printf '%d:%02d' $((s / 60)) $((s % 60))
    else printf '%d:%02dh' $((s / 3600)) $(((s % 3600) / 60)); fi
}
render_one() {
    local label="$1" model="$2" effort="$3" secs="$4" report="$5" model_width="$6" label_width="$7"
    local icon model_effort elapsed padded_label
    [ "$label" = "-" ] && label=""
    [ "$model" = "-" ] && model=""
    [ "$effort" = "-" ] && effort=""
    [ "$report" = "-" ] && report=""
    case "$model" in
        *[Tt]erra*) model="Terra" ;; *[Ss]ol*) model="Sol" ;; *[Ll]una*) model="Luna" ;; *gpt* | *GPT*) model="GPT" ;;
        *[Gg]emini*) model="Gemini" ;; *[Oo]pus*) model="Opus" ;; *[Ss]onnet*) model="Sonnet" ;; *[Ff]able*) model="Fable" ;;
    esac
    case "$model" in
        Terra | Sol | Luna | GPT) icon="⬡" ;;
        Gemini) icon="✦" ;;
        Opus | Sonnet | Fable) icon="✳" ;;
        *) icon="$gear" ;;
    esac
    model="${model:-Worker}"
    label="${label:-worker}"
    effort="${effort,,}"
    effort="${effort//[^a-z]/}"
    model_effort="${model}${effort:+·${effort}}"
    elapsed="$(fmt_el "$secs")"
    if [ "$model_width" -gt 0 ]; then printf -v model_effort '%-*s' "$model_width" "$model_effort"; fi
    if [ "$label_width" -gt 0 ]; then
        printf -v padded_label '%-*s' "$label_width" "${label:0:label_width}"
    else padded_label="${label:0:16}"; fi
    if [ -n "$report" ]; then padded_label=$'\e]8;;file://'"${report}"$'\e\\'"${padded_label}"$'\e]8;;\e\\'; fi
    printf '%s %s %s %s' "$icon" "$model_effort" "$padded_label" "$elapsed"
}

# --- ledger fold: live workers (last-write-wins per wid, in a LIVE state, within the stale window) as TSV, plus the native snapshot task tail count.
declare -a rows=()
declare -A seen_pid=()
task_tail=0
if [ -s "$ledger" ]; then
    while IFS=$'\t' read -r tag label model effort start pid; do
        case "$tag" in
            W)
                rows+=("$label"$'\t'"$model"$'\t'"$effort"$'\t'"$((now - start))"$'\t-')
                [ "$pid" != "-" ] && seen_pid["$pid"]=1
                ;;
            C) task_tail="$label" ;;
        esac
    done < <(tail -n "$tail_rows" "$ledger" 2>/dev/null | jq -rn --argjson now "$now" --argjson stale "$stale" --arg sid "$sid" '
        [inputs] as $r
        | ($r | map(select(.ev == "worker"))) as $w
        | ($r | map(select(.ev == "snapshot" and ($sid == "" or .session_id == $sid))) | max_by(.t)) as $snap
        | ($w | map(select(.kind != "subagent")) | group_by(.wid)
            | map(max_by(.t) as $l | {label: $l.label, model: $l.model,
                effort: (map(select(.effort != null)) | last.effort),
                start: (map(.t) | min), last: $l.t, state: $l.state, pid: $l.pid})
            | map(select((.state as $s | ["running", "started", "stream", "waiting"] | index($s)) != null and ($now - .last) < $stale))
            | sort_by(.start)) as $live
        | ($live[] | "W\t\((.label // "-"))\t\((.model // "-"))\t\((.effort // "-"))\t\(.start)\t\((.pid // "-"))"),
          ((($snap.tasks // []) | map(select(.type != "subagent")) | length) | "C\t\(.)\t-\t-\t-\t-")' 2>/dev/null)
fi

# --- process scan: one ps|awk pass resolves every undeclared codex/agy lane. The awk process opens config.toml at most once and only after observing an
# unpinned Codex command. Rows already declared by forge-fleet-emit are dropped by pid, so emitted truth always wins without double-counting.
while IFS=$'\t' read -r pid label model effort secs report; do
    [ -n "${seen_pid[$pid]:-}" ] && continue
    rows+=("${label:0:22}"$'\t'"$model"$'\t'"$effort"$'\t'"$secs"$'\t'"$report")
done < <(ps -axww -o pid=,etime=,command= 2>/dev/null | awk -v me="$$" -v ppid="$PPID" -v config="$HOME/.codex/config.toml" -v cwd="$PWD" '
    function option(cmd, flag,    rest, first, stop) {
      if (!match(cmd, "(^|[[:space:]])" flag "[[:space:]]+")) return ""
      rest = substr(cmd, RSTART + RLENGTH); first = substr(rest, 1, 1)
      if (first == "\"" || first == sprintf("%c", 39)) {
        rest = substr(rest, 2); stop = index(rest, first); return stop ? substr(rest, 1, stop - 1) : rest
      }
      sub(/[[:space:]].*$/, "", rest); return rest
    }
    function clean(value,    n, part) {
      gsub(/[\\\"]/, "", value); gsub(/\047/, "", value); n = split(value, part, "-"); return part[n]
    }
    function effort_of(cmd,    value) {
      if (!match(cmd, /model_reasoning_effort[[:space:]]*=[[:space:]]*[\047\"]?[[:alpha:]]+[\047\"]?/)) return ""
      value = substr(cmd, RSTART, RLENGTH); sub(/^.*=[[:space:]]*/, "", value); return tolower(clean(value))
    }
    function load_defaults(    line, value) {
      if (defaults_loaded) return
      defaults_loaded = 1
      while ((getline line < config) > 0) {
        if (default_model == "" && match(line, /^model[[:space:]]*=[[:space:]]*"[^"]+"/)) {
          value = substr(line, RSTART, RLENGTH); sub(/^[^"]*"/, "", value); sub(/"$/, "", value); default_model = value
        }
        if (default_effort == "" && match(line, /^model_reasoning_effort[[:space:]]*=[[:space:]]*"[[:alpha:]]+"/)) {
          value = substr(line, RSTART, RLENGTH); sub(/^[^"]*"/, "", value); sub(/"$/, "", value); default_effort = tolower(value)
        }
      }
      close(config)
    }
    function absolute(path) {
      if (path == "") return "-"
      if (substr(path, 1, 1) == "/") return path
      if (substr(path, 1, 2) == "~/") return ENVIRON["HOME"] substr(path, 2)
      return cwd "/" path
    }
    { pid = $1; et = $2; cmd = $0; sub(/^[[:space:]]*[0-9]+[[:space:]]+[^[:space:]]+[[:space:]]+/, "", cmd)
      isagy = (cmd ~ /(^|\/)agy([[:space:]]|$)/); iscx = (cmd ~ /(^|\/)codex (exec|review)/)
      if ((!isagy && !iscx) || pid == me || pid == ppid) next
      effort = effort_of(cmd); report = option(cmd, "-o")
      if (isagy) {
        model = "gemini"; label = "agy"
        if (match(cmd, /(^|[[:space:]])--model[[:space:]]+[^()]*\([[:alpha:]]+\)/)) {
          effort = substr(cmd, RSTART, RLENGTH); sub(/^.*\(/, "", effort); sub(/\).*$/, "", effort); effort = tolower(effort)
        }
      } else {
        model = option(cmd, "-m"); if (model == "") model = option(cmd, "--model")
        profile = option(cmd, "--profile")
        if (model == "" && profile == "") { load_defaults(); model = default_model; if (effort == "") effort = default_effort }
        label = "codex"
      }
      model = clean(model); if (model == "") model = isagy ? "gemini" : "gpt"
      if (model !~ /^(terra|sol|luna|gemini|flash|pro)$/ && model !~ /^gpt/) model = isagy ? "gemini" : "gpt"
      if (report != "") { l = report; sub(/.*\//, "", l); sub(/\.[^.]*$/, "", l); if (l != "") label = l }
      d = 0; h = 0; mm = 0; e = et; if (match(e, /-/)) { d = substr(e, 1, RSTART - 1); e = substr(e, RSTART + 1) }
      k = split(e, tp, ":"); if (k == 3) { h = tp[1]; mm = tp[2]; s = tp[3] } else if (k == 2) { mm = tp[1]; s = tp[2] } else s = tp[1]
      printf "%s\t%s\t%s\t%s\t%d\t%s\n", pid, label, model, (effort == "" ? "-" : effort), (((d * 24 + h) * 60 + mm) * 60 + s), absolute(report)
    }')

[ "${#rows[@]}" -eq 0 ] && {
    [ "$task_tail" -gt 0 ] && printf '%s %d tasks\n' "$gear" "$task_tail"
    exit 0
}

# --- render: longest-running first; one or two workers stay inline, while larger fleets become a six-worker aligned matrix with overflow in the tail.
mapfile -t rows < <(printf '%s\n' "${rows[@]}" | sort -t$'\t' -k4,4nr)
if [ "${#rows[@]}" -gt 6 ] || [ "$task_tail" -gt 0 ]; then
    shown=$((${#rows[@]} < 5 ? ${#rows[@]} : 5))
else shown="${#rows[@]}"; fi
tail_n=$(((${#rows[@]} - shown) + task_tail))
if [ "${#rows[@]}" -le 2 ]; then
    parts=()
    for ((i = 0; i < shown; i++)); do
        IFS=$'\t' read -r label model effort secs report <<<"${rows[i]}"
        parts+=("$(render_one "$label" "$model" "$effort" "$secs" "$report" 0 0)")
    done
    line="${parts[0]}"
    for ((i = 1; i < ${#parts[@]}; i++)); do line+=" · ${parts[i]}"; done
    if [ "$tail_n" -gt 0 ]; then line+=" · ${tail_n} task$([ "$tail_n" -eq 1 ] || printf s)"; fi
    printf '%s\n' "$line"
    exit 0
fi

model_width=0 label_width=16
for ((i = 0; i < shown; i++)); do
    IFS=$'\t' read -r label model effort _ _ <<<"${rows[i]}"
    case "$model" in
        *[Tt]erra*) model="Terra" ;; *[Ss]ol*) model="Sol" ;; *[Ll]una*) model="Luna" ;; *gpt* | *GPT*) model="GPT" ;;
        *[Gg]emini*) model="Gemini" ;; *[Oo]pus*) model="Opus" ;; *[Ss]onnet*) model="Sonnet" ;; *[Ff]able*) model="Fable" ;;
    esac
    [ "$effort" = "-" ] && effort=""
    width=${#model}
    [ -n "$effort" ] && width=$((width + ${#effort} + 1))
    [ "$width" -gt "$model_width" ] && model_width="$width"
    width=${#label}
    [ "$width" -gt "$label_width" ] && label_width="$width"
done
[ "$label_width" -gt 22 ] && label_width=22
for ((i = 0; i < shown; i++)); do
    IFS=$'\t' read -r label model effort secs report <<<"${rows[i]}"
    render_one "$label" "$model" "$effort" "$secs" "$report" "$model_width" "$label_width"
    printf '\n'
done
[ "$tail_n" -gt 0 ] && printf '%s %d task%s\n' "$gear" "$tail_n" "$([ "$tail_n" -eq 1 ] || printf s)"
