# Run ledger — <workflow-name>

Written the moment `Workflow` returns; updated on every resume or restart. Lives in the session scratchpad (harness temp dir), never the repo. A plain resume works only in the session that launched the run — a lost run ID means re-running the whole job; crossing a session boundary takes the journal transplant (recovery reference).

This ledger is NOT the journal. That journal (`journal.jsonl`, in the transcript dir below) is the runtime's automatic cache of agent results — it does the resuming. This file is only the record of the run ID to pass to `resumeFromRunId`. Resume needs the run ID and the launched `scriptPath` (both returned by the launch); the journal path is never built by hand.

## Run identity

- Workflow: <workflow-name>
- Scope / args: <scope-or-args, or "none">
- Run ID: <wf\_...>
- Launched scriptPath: <abs-path-to-the-.js-that-was-launched>
- Transcript dir: <~/.claude/projects/.../subagents/workflows/wf\_<id>/ — holds journal.jsonl>
- Run scratch: <.claude/scratch/<workflow-name>-<slug>-<hash>/ — the per-instance dir minted from normalized args; lane report files; a continuation script rebuilds completed stages from these and the journal's `result` records>

## Resume / restart (same session only)

- Resume: `Workflow({ scriptPath: "<launched scriptPath>", resumeFromRunId: "<wf_...>" })`
- Resume replays every cached `agent()` call up to the first whose key changed; only that call onward re-runs live.
- Cache key per call = `(prompt, schema, model, isolation, agentType)`. `label`, `phase`, and `effort` are not in the key.
- Do NOT edit the launched script while resumable — the resume becomes a full re-run from the edit.
- Resume requires `resumeFromRunId` AND the same session; a bare re-invocation, or a new session, starts fresh from zero (cross-session: transplant the old `journal.jsonl` into the new session's `wf_<id>` directory BEFORE the first in-session read — recovery reference).
- Verify every resume immediately: fresh `started` records belong only to the next pending stage; a burst of new `started` records for completed work is a key mismatch — stop and diff against the bytes that ran.
- Ledger lost? Its run ID is also in `/workflows` and is the `wf_<id>` directory name under the transcript dir — recover it there, then resume.

## Expected shape (sanity check on resume)

- Phases / agent count: <e.g. discover -> work[pool N] -> reconcile; ~N agents>
- Return value: <what the workflow returns>

## Status log

- <marker>: launched
- <marker>: resumed from <wf\_...> after <reason>
