# Codex Lanes

A workflow routes a self-contained leg (repo sweep, audit, research, mechanical edit) to codex (gpt-5.6) through a thin Claude wrapper, because `agent()` accepts only Claude models. The lane IS one `codex` MCP tool call: the prompt rides a tool argument, the blocking call is the wait, and the final message returns as the tool result — no prompt files, no report polling, no launch ceremony. Dispatch law — model and effort tiers, sandbox, MCP grading, sessions — is the codex skill's; this reference carries only the workflow-level composition.

## [01]-[WRAPPER]

The wrapper runs `model: 'sonnet', effort: 'low'` with a label prefixed by the real worker — `terra:`, `sol:`, or `luna:` — because the workflow UI shows the wrapper's Claude model. Its whole job is call-write-receipt:

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

Wrapper economics rule the lane count: every wrapper is a full context spin-up regardless of effort, so a wrapper per lane pays only when the leg fills it. Short legs batch — one wrapper makes several sequential `codex` calls and returns one combined receipt; a row-shaped batch collapses into a single lane whose codex session runs `spawn_agents_on_csv`; an iterative chain continues one thread through `codex-reply` with the `structuredContent.threadId` the first call returned, never re-paying the exploration cost. Concurrent lanes are concurrent wrapper agents — each holds its own blocking call, and the workflow's own concurrency cap is the scheduler.

Concurrent `workspace-write` lanes against overlapping paths collide — partition write scopes, or keep codex lanes read-only and let one Claude writer apply the edits.

## [04]-[LIMITS]

A lane expected to outrun the MCP tool timeout is the one case that still runs the detached CLI form — from the MAIN loop as a `run_in_background` Bash keeper per the codex skill's signals ladder, never inside a workflow wrapper. Splitting the leg into `codex-reply` turns that each fit the timeout is the first resort; the detached escape hatch is the last.
