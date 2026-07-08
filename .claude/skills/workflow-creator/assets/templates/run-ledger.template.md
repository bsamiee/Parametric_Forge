# Run ledger — <workflow-name>

Write this the moment `Workflow` returns; update it on every resume or restart. Keep it in
the session scratchpad (harness temp dir), never the repo. A plain resume works only in the session that launched
the run — losing the run ID means re-running the whole job; crossing a session boundary takes
the journal transplant (api-reference §11).

This ledger is NOT the journal. The journal (`journal.jsonl`, in the transcript dir below) is
the runtime's automatic cache of agent results — it does the resuming. This file is only your
record of the run ID to pass to `resumeFromRunId`. Resume needs the run ID + the launched
`scriptPath` (both returned by the launch); you never build the journal path by hand.

## Run identity
- Workflow: <workflow-name>
- Scope / args: <scope-or-args, or "none">
- Run ID: <wf_...>
- Launched scriptPath: <abs-path-to-the-.js-that-was-launched>
- Transcript dir: <~/.claude/projects/.../subagents/workflows/wf_<id>/ — holds journal.jsonl>
- Run scratch: <.claude/scratch/<workflow-name>/ — lane report files; a continuation script
  rebuilds completed stages from these plus the journal's `result` records>

## Resume / restart (same session only)
- Resume: `Workflow({ scriptPath: "<launched scriptPath>", resumeFromRunId: "<wf_...>" })`
- Resume replays every cached `agent()` call up to the first whose key changed; only that
  call onward re-runs live.
- Cache key per call = `(prompt, schema, model, isolation, agentType)`. `label`, `phase`,
  `effort`, and `stallMs` are NOT in the key.
- Do NOT edit the launched script while resumable, or the resume becomes a full re-run.
- Resume requires `resumeFromRunId` AND the same session; a bare re-invocation, or a new
  session, starts fresh from zero (cross-session: transplant the old `journal.jsonl` into the
  new session's `wf_<id>` directory first — api-reference §11).
- Lost this ledger? The run ID is also in `/workflows` and is the `wf_<id>` directory name
  under the transcript dir — recover it there, then resume. (The ledger is just a convenience.)

## Expected shape (sanity check on resume)
- Phases / agent count: <e.g. discover -> work[pool N] -> reconcile; ~N agents>
- Return value: <what the workflow returns>

## Status log
- <marker>: launched
- <marker>: resumed from <wf_...> after <reason>
