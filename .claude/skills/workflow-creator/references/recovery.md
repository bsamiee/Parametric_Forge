# Run Recovery

Stop, resume, transplant, and reconstruct workflow runs without losing completed work. Completed work is never lost: every agent's result is journaled the instant it finishes, so a pause or stop only ever discards agents still in flight, which re-run on resume. The expensive failure is operator-made — a resumable run re-run from zero.

## [01]-[CONTROLS]

A run is a background task. The tool call returns a run ID immediately; progress streams to `/workflows`; a `<task-notification>` lands in the conversation on completion.

| [INDEX] | [ACTION]  | [MECHANISM]                                                                                      |
| :-----: | :-------- | :------------------------------------------------------------------------------------------------ |
|  [01]   | Pause     | `p` in `/workflows` — the gentle hold, nothing discarded                                         |
|  [02]   | Stop      | `x` with focus on the run, or `TaskStop` programmatically; completed agents stay cached          |
|  [03]   | Restart one agent | `r` on the selected running agent — without stopping the run                            |
|  [04]   | Resume    | `p` in `/workflows`, or `Workflow({ scriptPath, resumeFromRunId })`                              |

Stop a still-running prior run before relaunching its script. Never kill a live session or server to force a workflow's hand — fix and redeploy, then let the owner restart on its own schedule.

## [02]-[JOURNAL]

The journal is the cache. Each run owns a directory under `~/.claude/projects/<project>/<session>/subagents/workflows/wf_<id>/`, and `journal.jsonl` inside it is the resume cache. Every `agent()` call appends a `{type:"started", key, agentId}` record when it begins and a `{type:"result", key, agentId, result}` record carrying the validated result when it finishes. The `key` is `v2:<sha256>` over the call's prompt plus its `schema`/`model`/`isolation`/`agentType` — never `label`/`phase`/`effort`/`stallMs`. Each agent's full transcript is a separate `agent-<id>.jsonl`; the journal — never the transcripts — is what resume reads, and the runtime writes it automatically.

Resume replays the journal by key: `Workflow({ scriptPath, resumeFromRunId })` re-executes the deterministic script and, per `agent()` call, recomputes the key — a `result` record returns instantly with no model call; a `started`-only record (in-flight at the stop) or no record runs live. Same script + same `args` = a full cache hit; an edited script replays every unchanged call before the edit.

## [03]-[RESUME]

Resume is one specific call, and each of these mistakes silently turns it into a fresh run:

- No `resumeFromRunId`. A bare `Workflow({ scriptPath })` or `Workflow({ name })` is a NEW run with an empty journal — it never consults a prior run's cache. The most common cause of an unexpected restart.
- A different session. The journal lives under the launching session's directory; a plain resume from a new session (or after a process restart) finds an empty journal and re-runs from zero. Recover with the transplant at [05].
- A changed cache key from the top. Editing the script, or changing the `args` that feed the first agent's prompt, changes its key, misses the cache there, and re-runs from that point. Do not edit a launched script while its run is resumable — edit only to intentionally re-run from the changed call onward (the iteration loop).
- An unstable launch source. Launch from a stable on-disk `scriptPath` so the exact bytes that ran stay on disk to replay against; an inline `script` string leaves nothing stable to resume from.

The run ledger makes the first rule reliable: the moment `Workflow` returns, write a small file in the session scratchpad (harness temp dir, never the repo) holding the run ID, the launched `scriptPath`, the `args`, and the exact resume command — copy `assets/templates/run-ledger.template.md` and update it on every resume or restart. The ledger is not the journal: the journal is the runtime's automatic result cache that DOES the resuming; the ledger is the one-line note of the run ID a later turn passes back. A lost run ID is recoverable in-session — the launch tool result prints it, the completion notification repeats it, `/workflows` lists every run, and the run directory is literally named `wf_<id>` — so a missing ledger is inconvenient, never fatal, within the session.

## [04]-[VERIFY]

Resume-cache keys are unstable across sessions, across harness builds, and for concurrently-staggered sibling calls across any stop/resume — the first-launched call of a fan-out keeps its key, staggered siblings rehash. So verify every resume immediately: classify the fresh `started` records against their agent transcripts' task lines; the only correct outcome is the next pending stage. A burst of new `started` records for already-completed work means a key mismatch — an edited script, changed `args`, or a rehashed sibling — so stop the run and diff against the bytes that ran.

Stop a run re-executing cached work the moment drift is confirmed; otherwise stop only at stage boundaries (journal `result` count equals the stage's agent total), so the journal holds complete stages a continuation script reconstructs cleanly.

## [05]-[TRANSPLANT]

The cache key is content-addressed with no session component, so a journal moves between sessions intact as long as the script bytes and `args` are unchanged. Cross-session there is ONE transplant window: the journal must land in the new session's run directory before the FIRST in-session read of that run ID — only the first read is honored, and records appended or rewritten after it fail internal validation and are ignored.

1. If the new session already relaunched the workflow, stop that run first (`TaskStop`) — a resume call adopts the old run ID and creates `wf_<id>` under the new session even when it finds no journal there.
2. Locate both run directories under `~/.claude/projects/<project>/<session>/subagents/workflows/wf_<id>/` — the old session's holds the populated `journal.jsonl`.
3. Back up the new directory's `journal.jsonl` if one exists, then concatenate old journal + new journal into the new directory's `journal.jsonl`. Resume matches `result` records by key; duplicate or stale `started` records are inert.
4. Resume with `Workflow({ scriptPath, resumeFromRunId: 'wf_<id>' })` — unchanged calls return cached, only genuinely-unfinished calls run live.
5. Run the [04] verification before walking away.

The transplant carries only the result cache; per-agent transcripts stay in the old directory and are not needed. When the script or `args` HAVE changed, the transplant still replays every call before the first edit; for a diverged script, fall back to the continuation script at [06].

## [06]-[CONTINUATION]

Recover a failed, cancelled, or quit run with a CONTINUATION SCRIPT, never journal surgery: copy the workflow, delete the completed stages, reconstruct their outputs from the journal's `result` records, bake them in as a data literal, and launch as a NEW run.

```js
// --- [INPUTS] --------------------------------------------------------------------------
// Stage 1 completed in wf_a1b2c3; its outputs reconstructed from the journal's `result`
// records and baked in as a literal. The body below is the original stage 2 onward, unchanged.
const stage1 = [
  { lane: 's0', report: '.claude/scratch/rebuild/gov-s0-report.json', entries: 14 },
  { lane: 's1', report: '.claude/scratch/rebuild/api-s1-report.json', entries: 9 },
]
```

Author every workflow for this recovery from day one: each stage writes its product to a disk file and returns a `{path, summary}` receipt, so any stage is re-enterable at zero cache dependence — the receipt roster IS the data literal a continuation script bakes in, and the product files are already on disk. A workflow whose stages hand heavy products through memory alone is unrecoverable past its own run.

## [07]-[TRUTH]

Receipts are claims; disk artifacts are truth. An agent's failure report is not ground truth: before re-running or discarding a lane, check its deterministic artifact paths — product file present and valid, process liveness, stderr tail. Forced returns (a stall abort, no-progress enforcement) file FALSE failures while the real work completes; a stale leftover artifact reads as FALSE success — hence the stale-purge law in the patterns reference. Design every lane so its truth is checkable from disk alone, and reconcile the roster against disk before acting on it.
