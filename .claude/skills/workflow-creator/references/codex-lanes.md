# External Lanes

A workflow routes a leg to an external model through a thin Claude wrapper, because `agent()` accepts only Claude models: codex (gpt-5.6) carries self-contained work legs — repo sweeps, audits, research, mechanical edits — and agy (Gemini) carries the read-only review lane. A codex lane IS one `codex` MCP tool call: the prompt rides a tool argument, the blocking call is the wait, and the final message returns as the tool result — no prompt files, no report polling, no launch ceremony. Dispatch law — model and effort tiers, sandbox, MCP grading, sessions — is the codex skill's; the Gemini call contract is the agy skill's; this reference carries only the workflow-level composition.

## [01]-[WRAPPER]

The wrapper runs `model: 'sonnet', effort: 'low'` with a label prefixed by the real worker — `terra:`, `sol:`, `luna:`, or `gemini:` — because the workflow UI shows the wrapper's Claude model. Its whole job is call-write-receipt:

When `forge-fleet-emit` resolves on PATH, the wrapper brackets its blocking call — `forge-fleet-emit --kind codex --model <model> --label <label> --state start` before, `--state stop` after — so the operator's live delegation roster names the real worker instead of inferring it from a process scan; a machine without the tool skips the bracket silently (`command -v forge-fleet-emit >/dev/null &&`). The same bracket serves a Gemini lane with `--kind agy`.

1. Load the tool: `ToolSearch` with `select:mcp__codex__codex`.
2. Call `codex` ONCE: the complete self-contained task as `prompt`, `model` pinned, `sandbox` by modality (`read-only` for investigation, `workspace-write` for edits), `cwd` at the repo root; effort inherits the operator config default (xhigh) — pass `config` (`{"model_reasoning_effort": "..."}`) only where the lane deviates.
3. Parse the result envelope — the MCP tool result is `{threadId, content}` where `content` holds the final-message text. Write that CONTENT text to the lane's scratch report path with the Write tool, unmodified; writing the raw envelope double-encodes every downstream read. This write re-emits the whole product as the wrapper's own output tokens (~minutes for a 40-50KB product) — acceptable at report scale; a lane whose product is far larger flips the write to the CODEX side (workspace-write, the report path its sole write scope) so the wrapper returns only the receipt.
4. Return the thin receipt `{ok, report, entries, headline, failure}` — mechanical counts and one tally headline, never a judgment or a lifted summary; add a `threadId` field when a later stage may continue the thread.

The wrapper never performs, edits, re-judges, softens, or relays the work itself. On a tool error the receipt carries `ok: false` and the error text in `failure`; one retry with a sharpened prompt is the wrapper's whole recovery budget. Lane law rides the tool's `developer-instructions` parameter with a task-only `prompt` (the codex skill's prompt-contract law — battery-validated as the strongest architecture); the wrapper passes both verbatim, composing neither.

QUOTA FALLBACK: usage exhaustion fails the call loudly with no partial output, so the receipt path already degrades safely — but a run that must FINISH re-dispatches the dead leg natively at the caller: the dispatch helper matches `/usage|quota|limit/i` in `failure` and re-runs the SAME task through its native branch at the role's Claude twin (terra→opus, sol→fable, luna→sonnet). The helper owns this, never the wrapper — a sonnet shell must never become the implicit executor:

```js conceptual
const laneWithFallback = (task, o) => lane(task, o).then((r) =>
    !r.ok && /usage|quota|limit/i.test(r.failure) ? lane(task, { ...o, native: true }) : r,
);
```

Two option-plumbing laws on a parameterized dispatch helper: the wrapper's `stallMs` is sized at or above the effort tier's timeout ceiling (the xhigh default holds one silent blocking call up to 1200s, max/ultra 1800s; stall enforcement has been observed to spare an agent inside a live blocking call — a 12-minute call under a 5-minute window completed — but sizing the window above the ceiling costs nothing and removes the ambiguity), and the helper option carrying a deviated codex reasoning tier is named `codexEffort`, never `effort` — the workflow linter scans every `effort:` key in the file against the agent tier vocabulary, so a codex tier in a helper-option literal fails validation even though it never reaches `agent()`.

```js conceptual
// The wrapper's own schema is the thin RECEIPT — the product body never crosses the wire;
// the blocking MCP call is legal waiting, so there is no launch receipt and no harvest loop.
const receipt = await agent(codexLane('audit-auth', task, /*writes*/ false), {
    model: 'sonnet',
    effort: 'low',
    label: 'terra:audit-auth',
    schema: RECEIPT,
});
```

## [02]-[PRODUCTS]

The heavy product goes to disk through the wrapper's Write tool and only the receipt crosses the wire — the report-file pattern in the patterns reference owns the receipt-and-roster contract and the terminal reader's consumption protocol. The codex prompt states the product shape as a prose JSON contract ("Final message: ONLY a JSON object with keys …"); the wrapper's `schema` option is the validation boundary, so schema files do not exist on this path. Failure lives in the receipt envelope, never as sentinel values inside data rows. Codex tokens are invisible to `budget.spent()` — budget-gated loops meter only their Claude lanes.

## [03]-[SCALE]

Wrapper economics rule the lane count: every wrapper is a full context spin-up (~75k tokens) regardless of effort, so a wrapper per lane pays only when the leg fills it. Short legs batch — one wrapper makes several sequential `codex` calls and returns one combined receipt, and a batched call whose task depends on an earlier call's product is the same chain: the wrapper relays the product forward mechanically, or continues the thread. A row-shaped batch collapses into a single lane whose codex session runs `spawn_agents_on_csv`; an iterative chain continues one thread through `codex-reply` with the `structuredContent.threadId` the first call returned, never re-paying the exploration cost. A chain that spans wrappers carries `threadId` as an extra receipt field — live interpolation couples the later wrapper's resume key to the earlier receipt, so a replayed run stays coherent, and a reply against a dead thread fails into the `ok: false` envelope like any tool error. Concurrent lanes are concurrent wrapper agents — each holds its own blocking call, and the workflow's own concurrency cap is the scheduler.

Concurrent `workspace-write` lanes against overlapping paths collide — partition write scopes, or keep codex lanes read-only and let one Claude writer apply the edits.

A read-only sandbox blocks `uv run` outright — uv cannot initialize its cache at `~/.cache/uv` — so a read-only lane can NEVER run repo Python tooling (assay, pytest, any `uv run` verb). A lane whose task depends on that tooling either dispatches `workspace-write` or its prompt names the non-executing fallback routes (catalogs, direct file reads) as the primary path; a prompt that instructs a read-only lane to "verify via uv run …" is instructing the impossible, and the lane's silent fallback masquerades as tool flakiness.

## [04]-[LIMITS]

A lane expected to outrun the MCP tool timeout (the codex skill names the ceiling's owner; a multi-minute high-effort call fits inside one blocking call) is the one case that still runs the detached CLI form — from the MAIN loop as a `run_in_background` Bash keeper per the codex skill's signals ladder, never inside a workflow wrapper. The first resort is splitting the leg into a `codex-reply` chain of turns that each fit the timeout; the detached escape hatch is the last.

An image-bearing leg (screenshot or diagram judgment) rides the CLI's `-i` — the MCP tool takes no image parameter — as ONE synchronous `codex exec -i <file> … </dev/null` inside the wrapper's single Bash call under the tier timeout: the blocking Bash call is the same legal wait, stdout capture is the product, and the rest of the call-write-receipt contract holds unchanged.

## [05]-[WRITER_REVIEW_LANE]

A review stage mid-chain (a critique between an implement and a red-team) can itself be a codex lane that WRITES — sol at the operator-default effort in a `workspace-write` sandbox, editing the unit's pages in place under the same review prompt a native agent takes. The composition contract that keeps the chain coherent:

- The lane's product is its fixlog (files, verdict, deltas, deferred rows, index rows) written to the lane's report path; only the thin receipt crosses the wire, so the orchestrator never re-serializes review claims.
- The NEXT Claude stage receives the fixlog as a report PATH framed as unverified prior claims ([20] handoff law), reads it in full from disk, and carries the FOLD-FORWARD DUTY: the fixlog's surviving `deferred`/`indexRows` rows are re-verified and folded into that stage's own return — the chain's terminal stage returns the unit's consolidated record, because the orchestrator cannot read the disk product itself.
- A chain whose terminal stage dies leaves an ORPHANED fixlog: the orchestrator collects `{critReport, rtLanded}` per unit and hands orphaned report paths to the run's terminal fixer to drain — a fold-forward contract with no orphan drain silently loses every row a dead stage was carrying.
- Write scopes stay disjoint by construction (the lane edits only its unit's pages); cross-unit needs ride the deferral rows, never a foreign edit.

## [06]-[GEMINI_REVIEW_LANE]

The agy lane is the third perspective in a critique or red-team stage, beside the fable/opus reviewer and a codex lane: a sonnet wrapper labeled `gemini:<label>` — the label is the only signal the real worker is Gemini, since the workflow UI shows the wrapper's Claude model — whose whole job is ONE blocking Bash call to the agy skill's wrapper:

```sh conceptual
uv run <repo>/.claude/skills/agy/scripts/agy.py prompt "<frozen-evidence review prompt>" --add-dir <evidence-dir> --timeout 5m
```

The lane is read-only by CONTRACT — agy print mode can write, so the prompt forbids edits and the wrapper treats any evidence mutation as lane failure (`ok: false`) — which is why the lane still takes no write partition, never collides with concurrent `workspace-write` lanes, and never repairs: the wrapper returns the typed findings array as its receipt (findings are small enough to cross the wire; no report file, no polling), and the consuming Claude stage adjudicates each finding against disk before applying any fix. The prompt shape — frozen evidence in, falsifiable `{severity, invariant, evidence, failure_path, minimal_fix}` findings out — and the model policy are the agy skill's law; the wrapper adds nothing beyond the call and the receipt.
