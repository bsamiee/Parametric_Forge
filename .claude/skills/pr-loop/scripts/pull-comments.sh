#!/usr/bin/env bash
# Four-surface PR feedback pull to disk — reviews, inline review comments, issue comments, review threads (the only carrier of
# resolution state). Read-only; deterministic and re-runnable. Threads ride GraphQL with the fixer anchor fields (subjectType,
# originalLine, startLine, diffSide, pullRequestReview join, authorAssociation); merge-comments.py joins the four snapshots.
# Usage: pull-comments.sh <PR> --dir <workdir> [--repo <owner/repo>]
# Writes: reviews.json inline.json issue.json threads.json head.txt ; prints one receipt line with per-surface counts.
set -euo pipefail

# --- [ARGS] -----------------------------------------------------------------------------
PR=${1:?usage: pull-comments.sh <PR> --dir <workdir> [--repo <owner/repo>]}
shift
DIR=""
REPO=""
while [ "$#" -gt 0 ]; do case "$1" in
    --dir)
        DIR=$2
        shift 2
        ;;
    --repo)
        REPO=$2
        shift 2
        ;;
    *)
        echo "pull-comments: unknown arg: $1" >&2
        exit 2
        ;;
esac done
[ -n "$DIR" ] || {
    echo "pull-comments: --dir required" >&2
    exit 2
}
[[ "$PR" =~ ^[0-9]+$ ]] || {
    echo "pull-comments: PR must be numeric" >&2
    exit 2
}
[ -n "$REPO" ] || REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
mkdir -p "$DIR"

# --- [PULL] -----------------------------------------------------------------------------
HEAD=$(gh api "repos/$REPO/pulls/$PR" --jq .head.sha)
printf '%s\n' "$HEAD" >"$DIR/head.txt"
gh api "repos/$REPO/pulls/$PR/reviews?per_page=100" --paginate | jq -s 'flatten' >"$DIR/reviews.json"
gh api "repos/$REPO/pulls/$PR/comments?per_page=100" --paginate | jq -s 'flatten' >"$DIR/inline.json"
gh api "repos/$REPO/issues/$PR/comments?per_page=100" --paginate | jq -s 'flatten' >"$DIR/issue.json"
# shellcheck disable=SC2016  # $-tokens are GraphQL variables inside a single-quoted document, never shell expansion
gh api graphql --paginate -F owner="${REPO%/*}" -F repo="${REPO#*/}" -F pr="$PR" -f query='
query($owner:String!,$repo:String!,$pr:Int!,$endCursor:String){
    repository(owner:$owner,name:$repo){ pullRequest(number:$pr){
        reviewThreads(first:100, after:$endCursor){
            pageInfo{ hasNextPage endCursor }
            nodes{ id isResolved isOutdated isCollapsed viewerCanResolve
                path line startLine originalLine originalStartLine diffSide subjectType
                comments(first:1){ nodes{ databaseId author{login} authorAssociation body url
                    pullRequestReview{ databaseId state } } } } } } } }' |
    jq -s '[.[].data.repository.pullRequest.reviewThreads.nodes[]]' >"$DIR/threads.json"

jq -n --arg d "$DIR" --arg h "$HEAD" \
    --argjson rv "$(jq 'length' "$DIR/reviews.json")" --argjson il "$(jq 'length' "$DIR/inline.json")" \
    --argjson ic "$(jq 'length' "$DIR/issue.json")" --argjson th "$(jq 'length' "$DIR/threads.json")" \
    -c '{dir:$d,head:$h,reviews:$rv,inline:$il,issue:$ic,threads:$th}'
