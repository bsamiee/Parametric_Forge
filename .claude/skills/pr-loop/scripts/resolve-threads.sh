#!/usr/bin/env bash
# Disposition-driven thread choreography — the false-done gate, threaded replies, and ONE aliased batch resolve. Consumes the
# round's disposition.json (fixer ledger rows joined with merged.json fields: dedup_key, thread_node_id, verdict, commit_sha,
# reply_draft, author_is_bot, viewer_can_resolve). Resolve law: fixed/upgraded resolve ONLY when commit_sha is an ancestor of
# --head (a claimed fix not in the pushed head stays open and is reported, never silently resolved); pushed-back resolves only
# bot threads (a human rules their own thread); deferred stays open; verdict "stale" is a bare resolve with no reply. Requires
# repo write; viewer_can_resolve==false rows are skipped and reported.
# Usage: resolve-threads.sh --disposition <file> --head <SHA>   (thread node IDs are globally scoped; no repo arg needed)
# Emits one JSON receipt: {replied,resolved,kept_open,gate_failures[],skipped_no_write[]}
set -euo pipefail

# --- [ARGS] -----------------------------------------------------------------------------
DISP=""
HEAD=""
while [ "$#" -gt 0 ]; do case "$1" in
    --disposition)
        DISP=$2
        shift 2
        ;;
    --head)
        HEAD=$2
        shift 2
        ;;
    *)
        echo "resolve-threads: unknown arg: $1" >&2
        exit 2
        ;;
esac done
[ -n "$DISP" ] && [ -f "$DISP" ] && [ -n "$HEAD" ] || {
    echo "resolve-threads: --disposition <file> and --head required" >&2
    exit 2
}

REPLIED=0
KEPT=0
RESOLVE_IDS=()
GATE_FAILS=()
NO_WRITE=()

# --- [ROWS] -----------------------------------------------------------------------------
# Gate, reply, and collect the resolve set.
while IFS= read -r row; do
    tid=$(jq -r '.thread_node_id // ""' <<<"$row")
    verdict=$(jq -r '.verdict // ""' <<<"$row")
    key=$(jq -r '.dedup_key // ""' <<<"$row")
    [ -n "$tid" ] || continue
    if [ "$(jq -r '.viewer_can_resolve' <<<"$row")" = "false" ]; then
        NO_WRITE+=("$key")
        continue
    fi # jq // would coerce false to the default

    resolve=0
    reply=1
    case "$verdict" in
        fixed | upgraded)
            sha=$(jq -r '.commit_sha // ""' <<<"$row")
            if [ -n "$sha" ] && git merge-base --is-ancestor "$sha" "$HEAD" 2>/dev/null; then
                resolve=1
            else
                GATE_FAILS+=("$key")
                reply=0
            fi
            ;;
        pushed-back)
            [ "$(jq -r '.author_is_bot // false' <<<"$row")" = "true" ] && resolve=1
            ;;
        deferred) ;;
        stale)
            resolve=1
            reply=0
            ;;
        *) reply=0 ;;
    esac

    body=$(jq -r '.reply_draft // ""' <<<"$row")
    if [ "$reply" -eq 1 ] && [ -n "$body" ]; then
        # shellcheck disable=SC2016  # $-tokens are GraphQL variables inside a single-quoted document, never shell expansion
        gh api graphql -f tid="$tid" -f body="$body" -f query='
            mutation($tid:ID!,$body:String!){
                addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$tid,body:$body}){comment{id}}}' >/dev/null &&
            REPLIED=$((REPLIED + 1))
    fi
    if [ "$resolve" -eq 1 ]; then RESOLVE_IDS+=("$tid"); else KEPT=$((KEPT + 1)); fi
done < <(jq -c '.[]' "$DISP")

# --- [BATCH_RESOLVE] --------------------------------------------------------------------
# One aliased mutation; resolving an already-resolved thread is a no-op.
RESOLVED=0
if [ "${#RESOLVE_IDS[@]}" -gt 0 ]; then
    M=$(printf '%s\n' "${RESOLVE_IDS[@]}" |
        awk 'NF{printf "t%d:resolveReviewThread(input:{threadId:\"%s\"}){thread{id isResolved}}\n",NR-1,$0}')
    gh api graphql -f query="mutation{ $M }" >/dev/null && RESOLVED=${#RESOLVE_IDS[@]}
fi

jq -cn --argjson rp "$REPLIED" --argjson rs "$RESOLVED" --argjson ko "$KEPT" \
    --argjson gf "$(printf '%s\n' "${GATE_FAILS[@]:-}" | jq -R . | jq -s 'map(select(.!=""))')" \
    --argjson nw "$(printf '%s\n' "${NO_WRITE[@]:-}" | jq -R . | jq -s 'map(select(.!=""))')" \
    '{replied:$rp,resolved:$rs,kept_open:$ko,gate_failures:$gf,skipped_no_write:$nw}'
