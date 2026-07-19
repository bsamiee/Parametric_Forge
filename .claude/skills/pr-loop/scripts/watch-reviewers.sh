#!/usr/bin/env bash
# Reviewer-completion watcher — one GraphQL snapshot per tick, head-keyed per-reviewer completion predicates, tri-state classify
# (COMPLETE|RUNNING|NEVER), stall taxonomy from a soft deadline crossed with a progress-signature grace window, one terminal
# PRLOOP_VERDICT line. Read-only: never posts, resolves, or pushes — every mutation is an agent action. Predicates key only on
# review-node commit.oid + body prefix, CheckRun status/app, StatusContext state, and the Greptile footer SHA; no predicate reads
# issue-comment updated_at, so summary/walkthrough churn can never wake the agent. ONESHOT=1 runs a single tick (the pre-arm probe).
# Usage: watch-reviewers.sh <PR> --head <SHA> --reviewers <csv> [--repo <owner/repo>]
#   csv tokens: coderabbit greptile macroscope claude codex human:<login>
# Env: POLL_S=45 REVIEWER_SOFT_S=480 SLOW_GRACE_S=180 WATCH_HARD_S=1200 PRLOOP_HOME=$HOME/.claude/pr-loop ONESHOT=0
# Exit: 0 CONVERGED_WAIT · 10 HEAD_CHANGED · 20 STALL_NEVER_STARTED · 21 STALL_DIED_MIDWAY · 22 STALL_SLOW · 99 STILL_WAITING
#       (ONESHOT only) · 2 USAGE · 3 PR_GONE · 4 ERROR
set -uo pipefail

# --- [ARGS] -----------------------------------------------------------------------------
PR=${1:?usage: watch-reviewers.sh <PR> --head <SHA> --reviewers <csv> [--repo <owner/repo>]}
shift
HEAD=""
REVIEWERS=""
REPO=""
while [ "$#" -gt 0 ]; do case "$1" in
    --head)
        HEAD=$2
        shift 2
        ;;
    --reviewers)
        REVIEWERS=$2
        shift 2
        ;;
    --repo)
        REPO=$2
        shift 2
        ;;
    *)
        echo "watch-reviewers: unknown arg: $1" >&2
        exit 2
        ;;
esac done
[ -n "$HEAD" ] && [ -n "$REVIEWERS" ] || {
    echo "watch-reviewers: --head and --reviewers required" >&2
    exit 2
}
[[ "$PR" =~ ^[0-9]+$ ]] || {
    echo "watch-reviewers: PR must be numeric" >&2
    exit 2
}

POLL_S=${POLL_S:-45}
REVIEWER_SOFT_S=${REVIEWER_SOFT_S:-480}
SLOW_GRACE_S=${SLOW_GRACE_S:-180}
WATCH_HARD_S=${WATCH_HARD_S:-1200}
PRLOOP_HOME=${PRLOOP_HOME:-$HOME/.claude/pr-loop}
ONESHOT=${ONESHOT:-0}
[ -n "$REPO" ] || REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) ||
    {
        echo "watch-reviewers: cannot resolve repo" >&2
        exit 4
    }
OWNER=${REPO%/*}
NAME=${REPO#*/}
DIR="$PRLOOP_HOME/pr-$PR"
STATE="$DIR/state"
LEDGER="$DIR/ledger.json"
SNAP="$DIR/snapshot.json"
VLOG="$DIR/verdict.jsonl"
mkdir -p "$STATE" || {
    echo "watch-reviewers: cannot mkdir $STATE" >&2
    exit 4
}
ARM_AT=$(date +%s)
now() { date +%s; }
iso() { date -u +%FT%TZ; }

# --- [SNAPSHOT] -------------------------------------------------------------------------
# shellcheck disable=SC2016  # $-tokens are GraphQL variables inside a single-quoted document, never shell expansion
QUERY='query($owner:String!,$repo:String!,$pr:Int!){repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){ number headRefOid state reviewDecision mergeable mergeStateStatus
        reviews(last:50){nodes{author{login} state commit{oid} submittedAt body}}
        reviewRequests(first:20){nodes{requestedReviewer{__typename ... on User{login} ... on Bot{login}}}}
        reviewThreads(first:100){nodes{id isResolved isOutdated}}
        comments(last:30){nodes{author{login} body}}
        commits(last:1){nodes{commit{oid statusCheckRollup{state contexts(first:100){nodes{
            __typename ... on CheckRun{name status conclusion startedAt completedAt checkSuite{app{slug databaseId}}}
            ... on StatusContext{context state creator{login}}}}}}}} } } }'

snapshot() {
    local resp tmp
    resp=$(gh api graphql -f owner="$OWNER" -f repo="$NAME" -F pr="$PR" -f query="$QUERY" 2>/dev/null) || return 1
    printf '%s' "$resp" | jq -e '.data.repository.pullRequest' >/dev/null 2>&1 || return 1
    tmp=$(mktemp "$DIR/.snap.XXXXXX")
    if ! { printf '%s' "$resp" | jq '.data.repository.pullRequest' >"$tmp" && mv "$tmp" "$SNAP"; }; then
        rm -f "$tmp"
        return 1
    fi
}

# --- [CLASSIFY] -------------------------------------------------------------------------
# One reviewer against $SNAP -> "<STATE> <SIG>"; jq owns the predicate, bash routes the csv token.
classify() {
    jq -r --arg who "$1" --arg H "$HEAD" '
        . as $pr | ($pr.reviews.nodes) as $rv
        | ([$pr.commits.nodes[-1].commit.statusCheckRollup.contexts.nodes[]?]) as $ctx
        | ($pr.comments.nodes) as $cv
        | ($pr.reviewRequests.nodes // []) as $req
        | def revq($login): [$rv[]|select(.author.login==$login)];
          def atHead($login): any($rv[]; .author.login==$login and .commit.oid==$H);
          def reqd($login): any($req[]; (.requestedReviewer.login // "")==$login);
        ( if $who=="coderabbit" then
            (if (any($rv[]; .author.login=="coderabbitai[bot]" and .commit.oid==$H
                    and (.body|test("^\\*\\*Actionable comments posted:"))))
                or (any($ctx[]; .__typename=="StatusContext" and .context=="CodeRabbit" and .state=="SUCCESS"))
              then "COMPLETE"
            elif (any($cv[]; .author.login=="coderabbitai[bot]" and (.body|test("review in progress by coderabbit\\.ai"))))
                or (any($ctx[]; .__typename=="StatusContext" and .context=="CodeRabbit" and .state=="PENDING"))
              then "RUNNING" else "NEVER" end) as $s
            | "\($s) cr:\((revq("coderabbitai[bot]")|length)):\(if any($cv[]; .author.login=="coderabbitai[bot]"
                and (.body|test("review in progress by coderabbit\\.ai"))) then 1 else 0 end)"
          elif $who=="greptile" then
            ([$ctx[]|select(.__typename=="CheckRun" and .name=="Greptile Review" and .checkSuite.app.slug=="greptile-apps")]) as $g
            | ([$cv[]|select(.author.login=="greptile-apps[bot]")|.body
                |capture("Last reviewed commit:.*?/commit/(?<s>[0-9a-f]{7,40})")?.s]|map(select(.!=null))|first // "") as $foot
            | (if (any($g[]; .status=="COMPLETED")) or (($foot!="") and (($H|startswith($foot)) or ($foot|startswith($H[0:7]))))
                then "COMPLETE"
               elif (($g|length)>0) or ($foot!="") then "RUNNING" else "NEVER" end) as $s
            | "\($s) gt:\(($g[0].status)//"-"):\(if $foot=="" then "-" else $foot[0:8] end)"
          elif $who=="macroscope" then
            ([$ctx[]|select(.__typename=="CheckRun" and .checkSuite.app.databaseId==900172)]) as $m
            | (if ($m|length)>0 and all($m[]; .status=="COMPLETED") then "COMPLETE"
               elif ($m|length)>0 then "RUNNING" else "NEVER" end) as $s
            | "\($s) ms:\([$m[].status]|sort|join(","))"
          elif ($who=="claude" or $who=="codex") then
            ({"claude":"claude[bot]","codex":"chatgpt-codex-connector[bot]"}[$who]) as $login
            | (if atHead($login) then "COMPLETE"
               elif ((revq($login)|length)>0) or reqd($login) then "RUNNING" else "NEVER" end) as $s
            | "\($s) \($login):\((revq($login)|length)):\((((revq($login)|last).commit.oid) // "-")[0:8])"
          elif ($who|startswith("human:")) then
            ($who[6:]) as $login
            | (if any($rv[]; .author.login==$login and .commit.oid==$H and .state!="PENDING") then "COMPLETE"
               elif reqd($login) or ((revq($login)|length)>0) then "RUNNING" else "NEVER" end) as $s
            | "\($s) \($login):\((revq($login)|length)):\((((revq($login)|last).commit.oid) // "-")[0:8])"
          else "NEVER \($who):unknown" end )' "$SNAP"
}

# --- [EMIT] -----------------------------------------------------------------------------
# Sole stdout — one verdict line plus a verdict.jsonl row; Monitor wakes here.
emit() {
    local code=$1 verdict=$2 table=$3
    jq -cn --argjson c "$code" --arg v "$verdict" --arg h "$HEAD" --argjson tbl "$table" --arg ts "$(iso)" \
        '{ts:$ts,exit:$c,verdict:$v,head:$h,reviewers:$tbl}' | tee -a "$VLOG" | sed 's/^/PRLOOP_VERDICT /'
}

# --- [POLL] -----------------------------------------------------------------------------
# One tick: snapshot, head-guard, classify all, update ledger, decide terminal.
poll() {
    snapshot || return 4
    local pr_state live
    pr_state=$(jq -r '.state' "$SNAP")
    live=$(jq -r '.headRefOid' "$SNAP")
    [ "$pr_state" = "OPEN" ] || {
        emit 3 PR_GONE "[]"
        return 3
    }
    [ "$live" = "$HEAD" ] || {
        emit 10 HEAD_CHANGED "[]"
        return 10
    }

    [ -f "$LEDGER" ] || printf '{"reviewers":{},"explicit_triggers":{}}' >"$LEDGER"
    local t all_complete=1 any_never=0 any_died=0 any_slow=0 table="[]"
    t=$(now)
    IFS=',' read -ra SET <<<"$REVIEWERS"
    for who in "${SET[@]}"; do
        local out st sig prev_sig prev_fsr changed_at ltmp cls past_soft
        out=$(classify "$who")
        st=${out%% *}
        sig=${out#* }
        prev_sig=$(jq -r --arg w "$who" '.reviewers[$w].sig // ""' "$LEDGER")
        prev_fsr=$(jq -r --arg w "$who" '.reviewers[$w].first_seen_running_at // 0' "$LEDGER")
        changed_at=$(jq -r --arg w "$who" '.reviewers[$w].sig_changed_at // 0' "$LEDGER")
        [ "$sig" = "$prev_sig" ] || changed_at=$t
        if [ "$st" = "RUNNING" ] && [ "$prev_fsr" -eq 0 ]; then prev_fsr=$t; fi
        ltmp=$(mktemp "$DIR/.ledger.XXXXXX")
        if ! { jq --arg w "$who" --arg s "$sig" --arg st "$st" --argjson fsr "$prev_fsr" --argjson ca "$changed_at" \
            '.reviewers[$w]={state:$st,sig:$s,first_seen_running_at:$fsr,sig_changed_at:$ca}' \
            "$LEDGER" >"$ltmp" && mv "$ltmp" "$LEDGER"; }; then
            rm -f "$ltmp"
        fi
        cls="$st"
        if [ "$st" != "COMPLETE" ]; then
            all_complete=0
            past_soft=0
            [ $((t - ARM_AT)) -ge "$REVIEWER_SOFT_S" ] && past_soft=1
            if [ "$past_soft" -eq 1 ]; then
                if [ "$prev_fsr" -eq 0 ] && [ "$st" = "NEVER" ]; then
                    cls=NEVER_STARTED
                    any_never=1
                elif [ $((t - changed_at)) -lt "$SLOW_GRACE_S" ]; then
                    cls=SLOW
                    any_slow=1
                else
                    cls=DIED_MIDWAY
                    any_died=1
                fi
            fi
        fi
        table=$(jq -cn --argjson tbl "$table" --arg w "$who" --arg c "$cls" '$tbl+[{reviewer:$w,class:$c}]')
    done
    TABLE_LAST=$table # visible to the ONESHOT entry so the pre-arm probe reports per-reviewer state

    if [ "$all_complete" -eq 1 ]; then
        emit 0 CONVERGED_WAIT "$table"
        return 0
    fi
    local elapsed=$((t - ARM_AT))
    if [ "$elapsed" -ge "$WATCH_HARD_S" ] ||
        { [ "$elapsed" -ge "$REVIEWER_SOFT_S" ] && { [ "$any_never" -eq 1 ] || [ "$any_died" -eq 1 ] || [ "$any_slow" -eq 1 ]; }; }; then
        if [ "$any_never" -eq 1 ]; then
            emit 20 STALL_NEVER_STARTED "$table"
            return 20
        elif [ "$any_died" -eq 1 ]; then
            emit 21 STALL_DIED_MIDWAY "$table"
            return 21
        else
            emit 22 STALL_SLOW "$table"
            return 22
        fi
    fi
    return 100 # not terminal — keep polling (internal, never an exit code)
}

# --- [ENTRY] ----------------------------------------------------------------------------
TABLE_LAST="[]"
if [ "$ONESHOT" = "1" ]; then
    poll
    rc=$?
    [ "$rc" -eq 100 ] && {
        emit 99 STILL_WAITING "$TABLE_LAST"
        rc=99
    }
    exit "$rc"
fi
while :; do
    poll
    rc=$?
    case "$rc" in
        100 | 4) sleep "$POLL_S" ;; # not terminal, or a transient snapshot error — retry next tick, never wake the agent
        *) exit "$rc" ;;
    esac
done
