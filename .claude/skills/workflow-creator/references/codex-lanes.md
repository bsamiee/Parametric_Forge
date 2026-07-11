# External Lanes

A workflow routes a leg to an external model through a thin Claude wrapper, because `agent()` accepts only Claude models: codex (gpt-5.6) carries self-contained work legs — repo sweeps, audits, research, mechanical edits — and agy (Gemini) carries the read-only review lane. A codex lane IS one `codex` MCP tool call: the prompt rides a tool argument, the blocking call is the wait, and the final message returns as the tool result — no prompt files, no report polling, no launch ceremony. Dispatch law — model and effort tiers, sandbox, MCP grading, sessions — is the codex skill's; the Gemini call contract is the agy skill's; this reference carries only the workflow-level composition.

## [01]-[WRAPPER]

The wrapper runs `model: 'sonnet', effort: 'low'` with a label prefixed by the real worker — `terra:`, `sol:`, `luna:`, or `gemini:` — because the workflow UI shows the wrapper's Claude model. Its whole job is call-write-receipt:

When `forge-fleet-emit` resolves on PATH, the wrapper brackets its blocking call — `forge-fleet-emit --kind codex --model <model> --label <label> --state start` before, `--state stop` after — so the operator's live delegation roster names the real worker instead of inferring it from a process scan; a machine without the tool skips the bracket silently (`command -v forge-fleet-emit >/dev/null &&`). The same bracket serves a Gemini lane with `--kind agy`.

1. Load the tool: `ToolSearch` with `select:mcp__codex__codex`.
2. Call `codex` ONCE: the complete self-contained task as `prompt`, `model` pinned, `sandbox` by modality (`read-only` for investigation, `workspace-write` for edits), `cwd` at the repo root, effort via `config` (`{"model_reasoning_effort": "high"}`).
3. Write the returned product VERBATIM to the lane's scratch report path with the Write tool.
4. Return the thin receipt `{ok, report, entries, headline, failure}` — mechanical counts and one tally headline, never a judgment or a lifted summary.

The wrapper never performs, edits, re-judges, softens, or relays the work itself. On a tool error the receipt carries `ok: false` and the error text in `failure`; one retry with a sharpened prompt is the wrapper's whole recovery budget.

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

## [04]-[LIMITS]

A lane expected to outrun the MCP tool timeout (the codex skill names the ceiling's owner; a multi-minute high-effort call fits inside one blocking call) is the one case that still runs the detached CLI form — from the MAIN loop as a `run_in_background` Bash keeper per the codex skill's signals ladder, never inside a workflow wrapper. The first resort is splitting the leg into a `codex-reply` chain of turns that each fit the timeout; the detached escape hatch is the last.

An image-bearing leg (screenshot or diagram judgment) rides the CLI's `-i` — the MCP tool takes no image parameter — as ONE synchronous `codex exec -i <file> … </dev/null` inside the wrapper's single Bash call under the tier timeout: the blocking Bash call is the same legal wait, stdout capture is the product, and the rest of the call-write-receipt contract holds unchanged.

## [05]-[GEMINI_REVIEW_LANE]

The agy lane is the third perspective in a critique or red-team stage, beside the fable/opus reviewer and a codex lane: a sonnet wrapper labeled `gemini:<label>` — the label is the only signal the real worker is Gemini, since the workflow UI shows the wrapper's Claude model — whose whole job is ONE blocking Bash call to the agy skill's wrapper:

```sh conceptual
uv run <repo>/.claude/skills/agy/scripts/agy.py prompt "<frozen-evidence review prompt>" --add-dir <evidence-dir> --timeout 5m
```

The lane is read-only by CONTRACT — agy print mode can write, so the prompt forbids edits and the wrapper treats any evidence mutation as lane failure (`ok: false`) — which is why the lane still takes no write partition, never collides with concurrent `workspace-write` lanes, and never repairs: the wrapper returns the typed findings array as its receipt (findings are small enough to cross the wire; no report file, no polling), and the consuming Claude stage adjudicates each finding against disk before applying any fix. The prompt shape — frozen evidence in, falsifiable `{severity, invariant, evidence, failure_path, minimal_fix}` findings out — and the model policy are the agy skill's law; the wrapper adds nothing beyond the call and the receipt.
