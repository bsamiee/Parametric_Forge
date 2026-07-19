#!/usr/bin/env bash
# Convergence gate read — one GraphQL snapshot scoring the four conditions: (1) reviewDecision in {APPROVED,null}; (2) zero
# unresolved non-outdated review threads; (3) mergeable==MERGEABLE, mergeStateStatus in {CLEAN,HAS_HOOKS}, zero failing and zero
# pending check contexts where a Macroscope NEUTRAL conclusion counts as pass; (4) per expected reviewer, its positive signal at
# head (CodeRabbit review present, Greptile summary Confidence Score 5/5 with footer SHA at head, Macroscope app-900172 runs all
# COMPLETED, Claude/Codex review at head). Read-only; the caller enforces the two-consecutive-reads law before acting on met=true.
# Usage: converge.sh <PR> --head <SHA> --reviewers <csv> [--repo <owner/repo>]   (csv vocabulary matches watch-reviewers.sh)
# Emits one JSON line: {met:bool, missing:[...]} ; exit 0 met, 1 not met, 2 usage, 4 error.
set -uo pipefail

# --- [ARGS] -----------------------------------------------------------------------------
PR=${1:?usage: converge.sh <PR> --head <SHA> --reviewers <csv> [--repo <owner/repo>]}
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
        echo "converge: unknown arg: $1" >&2
        exit 2
        ;;
esac done
[ -n "$HEAD" ] && [ -n "$REVIEWERS" ] || {
    echo "converge: --head and --reviewers required" >&2
    exit 2
}
[ -n "$REPO" ] || REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || {
    echo "converge: cannot resolve repo" >&2
    exit 4
}

# shellcheck disable=SC2016  # $-tokens are GraphQL variables inside a single-quoted document, never shell expansion
SNAP=$(gh api graphql -f owner="${REPO%/*}" -f repo="${REPO#*/}" -F pr="$PR" -f query='
query($owner:String!,$repo:String!,$pr:Int!){repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){ headRefOid reviewDecision mergeable mergeStateStatus
        reviews(last:50){nodes{author{login} state commit{oid} body}}
        reviewThreads(first:100){nodes{isResolved isOutdated}}
        comments(last:30){nodes{author{login} body}}
        commits(last:1){nodes{commit{statusCheckRollup{contexts(first:100){nodes{
            __typename ... on CheckRun{name status conclusion checkSuite{app{slug databaseId}}}
            ... on StatusContext{context state}}}}}}} } } }' 2>/dev/null) || {
    echo "converge: snapshot failed" >&2
    exit 4
}

# --- [SCORE] ----------------------------------------------------------------------------
# Jq owns the whole gate; the exit code mirrors .met.
OUT=$(printf '%s' "$SNAP" | jq -c --arg H "$HEAD" --arg set "$REVIEWERS" '
    .data.repository.pullRequest
    | .reviews.nodes as $rv | .comments.nodes as $cv
    | ([.commits.nodes[-1].commit.statusCheckRollup.contexts.nodes[]?]) as $ctx
    | ($set|split(",")) as $who
    | (if .headRefOid != $H then ["head moved: \(.headRefOid[0:8]) != \($H[0:8])"] else [] end) as $m0
    | (if (.reviewDecision == "APPROVED" or .reviewDecision == null) then [] else ["reviewDecision=\(.reviewDecision)"] end) as $m1
    | ([.reviewThreads.nodes[] | select(.isResolved==false and .isOutdated==false)] | length) as $open
    | (if $open == 0 then [] else ["\($open) unresolved threads"] end) as $m2
    | ([$ctx[] | select(.__typename=="CheckRun"
          and (.conclusion // "" | IN("FAILURE","TIMED_OUT","ACTION_REQUIRED","CANCELLED","STARTUP_FAILURE")))] +
       [$ctx[] | select(.__typename=="StatusContext" and (.state | IN("FAILURE","ERROR")))] | length) as $fail
    | ([$ctx[] | select(.__typename=="CheckRun" and .status != "COMPLETED")] +
       [$ctx[] | select(.__typename=="StatusContext" and .state=="PENDING")] | length) as $pend
    | (if .mergeable=="MERGEABLE" and (.mergeStateStatus | IN("CLEAN","HAS_HOOKS")) and $fail==0 and $pend==0 then []
       else ["checks: mergeable=\(.mergeable) state=\(.mergeStateStatus) failing=\($fail) pending=\($pend)"] end) as $m3
    | ([ $who[] | . as $w
        | if $w=="coderabbit" then
            (if any($rv[]; .author.login=="coderabbitai[bot]" and .commit.oid==$H) then empty else "coderabbit: no review at head" end)
          elif $w=="greptile" then
            ([$cv[] | select(.author.login=="greptile-apps[bot]") | .body] | last // "") as $b
            | (if ($b | test("Confidence Score:\\s*5/5")) and
                  (($b | capture("Last reviewed commit:.*?/commit/(?<s>[0-9a-f]{7,40})")?.s // "") as $f
                   | $f != "" and ($H | startswith($f)))
               then empty else "greptile: not 5/5 at head" end)
          elif $w=="macroscope" then
            ([$ctx[] | select(.__typename=="CheckRun" and .checkSuite.app.databaseId==900172)]) as $ms
            | (if ($ms|length)>0 and all($ms[]; .status=="COMPLETED") then empty else "macroscope: runs incomplete" end)
          elif $w=="claude" then
            (if any($rv[]; .author.login=="claude[bot]" and .commit.oid==$H) then empty else "claude: no review at head" end)
          elif $w=="codex" then
            (if any($rv[]; .author.login=="chatgpt-codex-connector[bot]" and .commit.oid==$H) then empty else "codex: no review at head" end)
          elif ($w|startswith("human:")) then
            (if any($rv[]; .author.login==$w[6:] and .commit.oid==$H and .state=="APPROVED") then empty
             else "\($w[6:]): no approval at head" end)
          else empty end ]) as $m4
    | ($m0 + $m1 + $m2 + $m3 + $m4) as $missing
    | {met: ($missing|length==0), missing: $missing}')
printf '%s\n' "$OUT"
[ "$(jq -r '.met' <<<"$OUT")" = "true" ]
