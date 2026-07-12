#!/usr/bin/env bash
# Fleet roster renderer for the Claude Code main statusLine: one compact row for one or two external workers, then an aligned matrix for larger fleets.
# Session-scoped: a lane renders only in its owning session's pane. The discriminator is CLAUDE_CODE_SESSION_ID — claude exports it to every child, it
# equals the statusLine payload's session_id, and it survives daemonization (a detached codex reparents to launchd, so ancestry dies at pid 1; the
# inherited env does not) — read per candidate pid via ps -E. Ledger rows carry a session stamp; unstamped rows adopt by live-pid env probe or drop.
# The pgrep census memoizes in a shared TTL cache because candidates are machine-wide facts; pid session truth revalidates every tick so PID reuse
# cannot inherit a cached owner. Steady-state work is bounded ps projections plus ledger folds. Empty stdin falls back to caller session, then machine-wide.
# The awk is strictly POSIX: the raw ~/.claude/hooks mirror resolves /usr/bin/awk (no gawk on the statusline PATH) while the nix package bakes gawk.

# The raw ~/.claude mirror can inherit no Nix profile PATH. Reenter the packaged owner first, then let its dependency-private timeout bound the body.
_resolve_executable() {
    local name="$1" excluded="${2:-}" profile_user="${USER:-${LOGNAME:-}}" candidate=""
    candidate="$(command -v "$name" 2>/dev/null)" || true
    if [ -n "$candidate" ] && [ -x "$candidate" ] && { [ -z "$excluded" ] || ! [ "$candidate" -ef "$excluded" ]; }; then
        REPLY="$candidate"
        return 0
    fi
    if [ -n "$profile_user" ]; then
        candidate="/etc/profiles/per-user/${profile_user}/bin/${name}"
        if [ -x "$candidate" ] && { [ -z "$excluded" ] || ! [ "$candidate" -ef "$excluded" ]; }; then
            REPLY="$candidate"
            return 0
        fi
    fi
    candidate="${HOME}/.nix-profile/bin/${name}"
    if [ -x "$candidate" ] && { [ -z "$excluded" ] || ! [ "$candidate" -ef "$excluded" ]; }; then
        REPLY="$candidate"
        return 0
    fi
    REPLY=""
    return 1
}
if [ -z "${_FORGE_FLEET_DEADLINE:-}" ]; then
    status_bin=""
    if [ "${0##*/}" != forge-fleet-status ]; then _resolve_executable forge-fleet-status "$0" && status_bin="$REPLY"; fi
    if [ -n "$status_bin" ]; then
        "$status_bin" "$@" || true
        exit 0
    fi
    timeout_bin=""
    _resolve_executable timeout && timeout_bin="$REPLY"
    bash_bin="${BASH:-}"
    if [ -z "$bash_bin" ] || ! "$bash_bin" -c '((BASH_VERSINFO[0] >= 5))' >/dev/null 2>&1; then
        bash_bin=""
        _resolve_executable bash "${BASH:-}" && bash_bin="$REPLY"
        if [ -z "$bash_bin" ] || ! "$bash_bin" -c '((BASH_VERSINFO[0] >= 5))' >/dev/null 2>&1; then bash_bin=""; fi
    fi
    if [ -n "$timeout_bin" ] && [ -n "$bash_bin" ]; then _FORGE_FLEET_DEADLINE=1 "$timeout_bin" -k 1 3 "$bash_bin" "$0" "$@" || true; fi
    exit 0
fi

set -Eeuo pipefail
shopt -s inherit_errexit
[ -n "${FORGE_FLEET_DEBUG:-}" ] || trap 'exit 0' ERR

ledger="${FORGE_FLEET_LEDGER:-${XDG_STATE_HOME:-$HOME/.local/state}/forge/delegation.jsonl}"
scan_cache="${FORGE_FLEET_SCAN_CACHE:-$ledger.scan}"
scan_ttl="${FORGE_FLEET_SCAN_TTL:-5}"
stale="${FORGE_FLEET_STALE_SECS:-1800}"
tail_rows="${FORGE_FLEET_TAIL_ROWS:-400}"
gear="${FORGE_FLEET_GLYPH:-⛭}"
scan_re='(^|/)codex (exec|review)|(^|/)agy([[:space:]]|$)'
now="$EPOCHSECONDS"
command -v jq >/dev/null 2>&1 || exit 0
[[ "$scan_ttl" =~ ^[1-9][0-9]*$ ]] || scan_ttl=5
[[ "$stale" =~ ^[1-9][0-9]*$ ]] || stale=1800
[[ "$tail_rows" =~ ^[1-9][0-9]*$ ]] || tail_rows=400

# A terminal has no status payload. The sentinel byte rejects an oversized producer, while EOF or the one-second guard retains a bounded partial read.
max_payload=1048576
payload="" read_rc=1
if ! [ -t 0 ]; then
    read_rc=0
    LC_ALL=C IFS= read -r -t 1 -N "$((max_payload + 1))" payload || read_rc=$?
    [ "$read_rc" -ne 0 ] || payload=""
fi
sid=""
[ -n "$payload" ] && sid="$(printf '%s' "$payload" | jq -r '.session_id // ""' 2>/dev/null || true)"
[ -n "$sid" ] || sid="${CLAUDE_CODE_SESSION_ID:-}"

canon_model() { # one model-vocabulary owner: any provider spelling -> roster title; unknown spellings pass through, "-"/empty clear to "".
    case "$1" in
        *[Tt]erra*) REPLY="Terra" ;; *[Ss]ol*) REPLY="Sol" ;; *[Ll]una*) REPLY="Luna" ;; *gpt* | *GPT*) REPLY="GPT" ;;
        *[Gg]emini*) REPLY="Gemini" ;; *[Oo]pus*) REPLY="Opus" ;; *[Ss]onnet*) REPLY="Sonnet" ;; *[Ff]able*) REPLY="Fable" ;;
        - | "") REPLY="" ;;
        *) REPLY="$1" ;;
    esac
}
pid_sid() { # REPLY = the live pid's inherited CLAUDE_CODE_SESSION_ID (own-uid env via ps -E), "" when unreadable or absent; memoized per pid.
    REPLY=""
    IFS= read -r REPLY < <(ps -Eww -o command= -p "$1" 2>/dev/null | awk '
      { for (i = 1; i <= NF; i++) if ($i ~ /^CLAUDE_CODE_SESSION_ID=[^[:space:]]+$/) { sid = $i; sub(/^[^=]*=/, "", sid) } }
      END { print sid }') || true
    pid_session["$1"]="$REPLY"
}
pid_is_live() { # A recorded pid is live only while ps still exposes a non-zombie process; memoization also collapses repeated ledger rows.
    local pid="$1" state=""
    if [ -n "${pid_liveness[$pid]+x}" ]; then
        [ "${pid_liveness[$pid]}" -eq 1 ]
        return
    fi
    IFS= read -r state < <(ps -ww -o state= -p "$pid" 2>/dev/null) || true
    state="${state#"${state%%[![:space:]]*}"}"
    if [ -n "$state" ] && [ "${state:0:1}" != Z ]; then
        pid_liveness["$pid"]=1
        return 0
    fi
    pid_liveness["$pid"]=0
    return 1
}
adopt() { # $1=row session stamp ("-" = unstamped) $2=pid ("-" = absent): stamped rows match sid; unstamped adopt by live-pid env truth, else drop.
    local rsid="$1" pid="$2"
    [ -z "$sid" ] && return 0
    [ "$rsid" = "$sid" ] && return 0
    { [ "$rsid" = "-" ] && [ "$pid" != "-" ]; } || return 1
    if [ -n "${pid_session[$pid]+x}" ]; then REPLY="${pid_session[$pid]}"; else pid_sid "$pid"; fi
    [ "$REPLY" = "$sid" ]
}
fmt_el() { # elapsed grammar shared with forge-fleet-row's elx: minutes always two digits (07:44), hours unpadded with minute pad (1:07h).
    local s="$1"
    [[ "$s" =~ ^[0-9]+$ ]] || s=0
    if [ "$s" -lt 3600 ]; then
        printf '%02d:%02d' $((s / 60)) $((s % 60))
    else printf '%d:%02dh' $((s / 3600)) $(((s % 3600) / 60)); fi
}
render_one() { # rows arrive with the model already canonical and label defaulted, so this only maps icon, pads, and wraps OSC 8 report links.
    local label="$1" model="$2" effort="$3" secs="$4" report="$5" model_width="$6" label_width="$7"
    local icon model_effort elapsed padded_label pad
    [ "$effort" = "-" ] && effort=""
    [ "$report" = "-" ] && report=""
    case "$model" in
        Terra | Sol | Luna | GPT) icon="⬡" ;;
        Gemini) icon="✦" ;;
        Opus | Sonnet | Fable) icon="✳" ;;
        *) icon="$gear" ;;
    esac
    effort="${effort,,}"
    effort="${effort//[^a-z]/}"
    model_effort="${model}${effort:+·${effort}}"
    elapsed="$(fmt_el "$secs")"
    # printf %-*s pads by bytes, so the multibyte "·" would shear the column grid; pad by character count instead.
    if [ "$model_width" -gt "${#model_effort}" ]; then printf -v pad '%*s' $((model_width - ${#model_effort})) '' && model_effort+="$pad"; fi
    if [ "$label_width" -gt 0 ]; then
        padded_label="${label:0:label_width}"
        if [ "$label_width" -gt "${#padded_label}" ]; then printf -v pad '%*s' $((label_width - ${#padded_label})) '' && padded_label+="$pad"; fi
    else padded_label="${label:0:16}"; fi
    if [ -n "$report" ]; then padded_label=$'\e]8;;file://'"${report}"$'\e\\'"${padded_label}"$'\e]8;;\e\\'; fi
    printf '%s %s %s %s' "$icon" "$model_effort" "$padded_label" "$elapsed"
}

# --- scan census: pgrep candidates share a TTL cache; each cached pid's session revalidates so a recycled pid never inherits the prior process owner.
declare -A pid_session=() pid_liveness=()
declare -a cands=()
fresh=0
if [ -s "$scan_cache" ]; then
    while IFS=$'\t' read -r a _; do
        if [ "$fresh" -eq 0 ]; then
            [[ "$a" =~ ^[0-9]+$ ]] && [ "$now" -ge "$a" ] && [ $((now - a)) -lt "$scan_ttl" ] || break
            fresh=1
        else
            [[ "$a" =~ ^[1-9][0-9]*$ ]] || continue
            cands+=("$a")
            pid_sid "$a"
        fi
    done <"$scan_cache" 2>/dev/null || true
fi
if [ "$fresh" -eq 0 ]; then
    cands=()
    while read -r p; do
        [[ "$p" =~ ^[0-9]+$ ]] || continue
        pid_sid "$p"
        cands+=("$p")
    done < <(pgrep -f "$scan_re" 2>/dev/null || true)
    {
        printf '%s\n' "$now"
        for p in "${cands[@]}"; do printf '%s\n' "$p"; done
    } >"$scan_cache.$$" 2>/dev/null && mv -f "$scan_cache.$$" "$scan_cache" 2>/dev/null || rm -f "$scan_cache.$$" 2>/dev/null || true
fi

# --- ledger fold: live lanes (last-write-wins per wid, live state, inside the stale window) session-gated through adopt, plus the snapshot tail count.
# fromjson? drops malformed or torn lines so one bad row never blanks the roster; every empty field travels as "-" because tab-IFS collapses empties.
declare -a rows=()
declare -A seen_pid=()
task_tail=0
if [ -s "$ledger" ]; then
    while IFS=$'\t' read -r tag label model effort start pid rsid; do
        case "$tag" in
            W)
                [[ "$start" =~ ^[0-9]+$ ]] || continue
                { [ "$pid" = "-" ] || [[ "$pid" =~ ^[1-9][0-9]*$ ]]; } || continue
                adopt "$rsid" "$pid" || continue
                if [ "$pid" != "-" ]; then
                    pid_is_live "$pid" || continue
                    seen_pid["$pid"]=1
                fi
                canon_model "$model"
                [ "$label" = "-" ] && label="worker"
                rows+=("$label"$'\t'"${REPLY:-Worker}"$'\t'"$effort"$'\t'"$((now - start))"$'\t-')
                ;;
            C) task_tail="$label" ;;
        esac
    done < <(tail -n "$tail_rows" "$ledger" 2>/dev/null | jq -Rrn --argjson now "$now" --argjson stale "$stale" --arg sid "$sid" '
        [inputs | fromjson? | select((.t | type) == "number")] as $r
        | ($r | map(select(.ev == "snapshot" and ($sid == "" or .session_id == $sid)
            and $now >= .t and ($now - .t) < $stale)) | max_by(.t)) as $snap
        | ($r | map(select(.ev == "worker" and .kind != "subagent" and (.wid | type) == "string"))
            | group_by([(.session_id // "-"), .wid])
            | map(. as $g | (max_by(.t)) as $l | {label: $l.label, model: $l.model,
                effort: ([$g[] | .effort // empty] | last), start: ([$g[] | .t] | min), last: $l.t, state: $l.state,
                pid: ([$g[] | .pid // empty] | last), sid: ([$g[] | .session_id // empty] | map(select(. != "-")) | last)})
            | map(select(IN(.state; "running", "started", "stream", "waiting") and $now >= .last and ($now - .last) < $stale))
            | sort_by(.start)) as $live
        | ($live[] | "W\t\((.label // "-"))\t\((.model // "-"))\t\((.effort // "-"))\t\(.start)\t\((.pid // "-"))\t\((.sid // "-"))"),
          ((($snap.tasks // []) | map(select(.type != "subagent")) | length) | "C\t\(.)\t-\t-\t0\t-\t-")' 2>/dev/null)
fi

# --- process scan: session-adopted census pids not already declared by emit enter one ps batch; zombie rows drop while detached ppid=1 workers remain
# valid. The awk resolves label, model, effort, elapsed seconds, and -o report path. Codex resolution mirrors codex's own precedence: cmdline flags win,
# then --profile (~/.codex/<name>.config.toml), then config.toml for any axis still unset; each file opens at most once per render.
declare -a scan_pids=()
for p in "${cands[@]}"; do
    [ -n "${seen_pid[$p]:-}" ] && continue
    if [ -n "$sid" ] && [ "${pid_session[$p]:-}" != "$sid" ]; then continue; fi
    scan_pids+=("$p")
done
if [ "${#scan_pids[@]}" -gt 0 ]; then
    printf -v scan_pid_list '%s,' "${scan_pids[@]}"
    scan_pid_list="${scan_pid_list%,}"
    while IFS=$'\t' read -r _ label model effort secs report; do
        canon_model "$model"
        rows+=("${label:0:22}"$'\t'"${REPLY:-Worker}"$'\t'"$effort"$'\t'"$secs"$'\t'"$report")
    done < <(ps -ww -o pid=,state=,ppid=,etime=,command= -p "$scan_pid_list" 2>/dev/null | awk -v conf="$HOME/.codex" -v cwd="$PWD" '
    BEGIN { q = sprintf("%c", 39); config = conf "/config.toml" }
    function option(cmd, flag,    rest, first, stop) {
      if (!match(cmd, "(^|[[:space:]])" flag "[[:space:]]+")) return ""
      rest = substr(cmd, RSTART + RLENGTH); first = substr(rest, 1, 1)
      if (first == "\"" || first == q) {
        rest = substr(rest, 2); stop = index(rest, first); return stop ? substr(rest, 1, stop - 1) : rest
      }
      sub(/[[:space:]].*$/, "", rest); return rest
    }
    function clean(value,    n, part) {
      gsub(/[\\"]/, "", value); gsub(q, "", value); n = split(value, part, "-"); return part[n]
    }
    function effort_of(cmd,    value) {
      if (!match(cmd, "model_reasoning_effort[[:space:]]*=[[:space:]]*[" q "\"]?[[:alpha:]]+[" q "\"]?")) return ""
      value = substr(cmd, RSTART, RLENGTH); sub(/^.*=[[:space:]]*/, "", value); return tolower(clean(value))
    }
    function read_toml(file, pfx,    line, value) {
      while ((getline line < file) > 0) {
        if (kv[pfx "model"] == "" && match(line, /^model[[:space:]]*=[[:space:]]*"[^"]+"/)) {
          value = substr(line, RSTART, RLENGTH); sub(/^[^"]*"/, "", value); sub(/"$/, "", value); kv[pfx "model"] = value
        }
        if (kv[pfx "effort"] == "" && match(line, /^model_reasoning_effort[[:space:]]*=[[:space:]]*"[[:alpha:]]+"/)) {
          value = substr(line, RSTART, RLENGTH); sub(/^[^"]*"/, "", value); sub(/"$/, "", value); kv[pfx "effort"] = tolower(value)
        }
      }
      close(file)
    }
    function load_defaults() {
      if (defaults_loaded) return
      defaults_loaded = 1
      read_toml(config, "d:")
    }
    function load_profile(name) {
      if (name in prof_loaded) return
      prof_loaded[name] = 1
      read_toml(conf "/" name ".config.toml", "p:" name ":")
    }
    function absolute(path) {
      if (path == "") return "-"
      if (substr(path, 1, 1) == "/") return path
      if (substr(path, 1, 2) == "~/") return ENVIRON["HOME"] substr(path, 2)
      return cwd "/" path
    }
    { pid = $1; state = $2; ppid = $3; et = $4; cmd = $0
      if (substr(state, 1, 1) == "Z") next
      sub(/^[[:space:]]*[0-9]+[[:space:]]+[^[:space:]]+[[:space:]]+[0-9]+[[:space:]]+[^[:space:]]+[[:space:]]+/, "", cmd)
      isagy = (cmd ~ /(^|\/)agy([[:space:]]|$)/); iscx = (cmd ~ /(^|\/)codex (exec|review)/)
      if (!isagy && !iscx) next
      effort = effort_of(cmd); report = option(cmd, "-o")
      if (isagy) {
        model = "gemini"; label = "agy"
        if (match(cmd, /(^|[[:space:]])--model[[:space:]]+[^()]*\([[:alpha:]]+\)/)) {
          effort = substr(cmd, RSTART, RLENGTH); sub(/^.*\(/, "", effort); sub(/\).*$/, "", effort); effort = tolower(effort)
        }
      } else {
        model = option(cmd, "-m"); if (model == "") model = option(cmd, "--model")
        pname = option(cmd, "--profile")
        if (pname != "" && (model == "" || effort == "")) {
          load_profile(pname)
          if (model == "") model = kv["p:" pname ":model"]
          if (effort == "") effort = kv["p:" pname ":effort"]
        }
        if (model == "" || effort == "") {
          load_defaults()
          if (model == "") model = kv["d:model"]
          if (effort == "") effort = kv["d:effort"]
        }
        label = "codex"
      }
      model = clean(model); if (model == "") model = isagy ? "gemini" : "gpt"
      if (model !~ /^(terra|sol|luna|gemini|flash|pro)$/ && model !~ /^gpt/) model = isagy ? "gemini" : "gpt"
      if (report != "") { l = report; sub(/.*\//, "", l); sub(/\.[^.]*$/, "", l); if (l != "") label = l }
      d = 0; h = 0; mm = 0; e = et; if (match(e, /-/)) { d = substr(e, 1, RSTART - 1); e = substr(e, RSTART + 1) }
      k = split(e, tp, ":"); if (k == 3) { h = tp[1]; mm = tp[2]; s = tp[3] } else if (k == 2) { mm = tp[1]; s = tp[2] } else s = tp[1]
      printf "%s\t%s\t%s\t%s\t%d\t%s\n", pid, label, model, (effort == "" ? "-" : effort), (((d * 24 + h) * 60 + mm) * 60 + s), absolute(report)
    }')
fi

if [ "${#rows[@]}" -eq 0 ]; then
    [ "$task_tail" -gt 0 ] && printf '%s %d task%s\n' "$gear" "$task_tail" "$([ "$task_tail" -eq 1 ] || printf s)"
    exit 0
fi

# --- render: longest-running first; one or two workers stay inline, while larger fleets become a six-worker aligned matrix with overflow in the tail.
mapfile -t rows < <(printf '%s\n' "${rows[@]}" | sort -t$'\t' -k4,4nr)
if [ "${#rows[@]}" -gt 6 ] || [ "$task_tail" -gt 0 ]; then
    shown=$((${#rows[@]} < 5 ? ${#rows[@]} : 5))
else shown="${#rows[@]}"; fi
tail_n=$(((${#rows[@]} - shown) + task_tail))
if [ "${#rows[@]}" -le 2 ]; then
    parts=()
    for ((i = 0; i < shown; i++)); do
        IFS=$'\t' read -r label model effort secs report < <(printf '%s\n' "${rows[i]}")
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
    IFS=$'\t' read -r label model effort _ _ < <(printf '%s\n' "${rows[i]}")
    [ "$effort" = "-" ] && effort=""
    width=${#model}
    [ -n "$effort" ] && width=$((width + ${#effort} + 1))
    [ "$width" -gt "$model_width" ] && model_width="$width"
    width=${#label}
    [ "$width" -gt "$label_width" ] && label_width="$width"
done
[ "$label_width" -gt 22 ] && label_width=22
for ((i = 0; i < shown; i++)); do
    IFS=$'\t' read -r label model effort secs report < <(printf '%s\n' "${rows[i]}")
    render_one "$label" "$model" "$effort" "$secs" "$report" "$model_width" "$label_width"
    printf '\n'
done
[ "$tail_n" -gt 0 ] && printf '%s %d task%s\n' "$gear" "$tail_n" "$([ "$tail_n" -eq 1 ] || printf s)"
exit 0
