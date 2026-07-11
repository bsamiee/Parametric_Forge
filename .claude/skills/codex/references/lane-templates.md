# Lane Templates

The canonical prompt architecture for a codex work lane, battery-validated: lane law rides `developer-instructions` (or the `developer_instructions` config key on CLI lanes), the user `prompt` carries only the task instance, and the output contract sits LAST in the developer message. The prompt-contract law in SKILL.md [06] governs both templates; this reference carries the reusable text.

## [01]-[RECON]

Read-only investigation lane. `developer-instructions`:

```text template
<context_gathering>
Territory: <the exact files/dirs the lane may open>. Do not open files outside it, including skill or instruction files.
Budget: at most <N> tool calls total. Read in small batches (a handful of files per command, line-capped); never concatenate the whole territory into one command - tool output truncates and the data is lost.
Stop as soon as the product is complete. If something is still uncertain at the budget, proceed and record it in coverage.unverified instead of re-reading.
</context_gathering>

<verification>
Before the final message, confirm every cited spelling appears verbatim in the cited file; move anything unconfirmed into coverage.unverified.
</verification>

<output_contract>
Your final message is a single JSON object with exactly this shape:
<SHAPE with coverage{requested,read,skipped,unverified}>
- JSON only: no prose before or after it, no code fences, no markdown.
- Every key shown is required.
- Use null for a value you could not determine and [] for an empty list; never guess.
</output_contract>
```

`prompt`: the concrete task only — territory paths, per-entry field semantics, product kinds.

The load-bearing choices: the territory clause names skill and instruction files explicitly (lanes without it probe them); the budget caps TOTAL tool calls with the anti-aggregation sentence (a per-file read cap makes the lane concatenate the territory into one truncating command, collapsing completeness by an order of magnitude — the budget's speed and discipline gains survive only with this phrasing); the escape hatch converts residual uncertainty into `coverage.unverified` rows instead of re-reads; the contract's null clause is what separates honest nulls from filler.

## [02]-[WRITE]

Workspace-write fix lane. The role split and output contract carry the recon lane's evidence base; the persistence and post-edit verification blocks are the standing law for every lane that edits durable artifacts in place.

`developer-instructions`:

```text template
<persistence>
Complete every named move before yielding; do not stop at analysis or a partial edit. If the chosen approach resists, pick the next-best one and proceed. Return without an applied edit only if the territory genuinely admits none.
</persistence>

<verification>
After editing, re-read each changed file and confirm it is coherent and nothing it carried was lost. Fix what fails before yielding.
</verification>

<output_contract>
Your final message is a single JSON object with exactly this shape:
{"edits":[{"file":"<path>","move":"<move-kind>","description":"<string>"}], <task-specific keys>, "summary":"<string>"}
- JSON only: no prose before or after it, no code fences, no markdown.
- Every key shown is required.
- Use null for a value you could not determine and [] for an empty list; never guess.
</output_contract>
```

`prompt`: the concrete task — the writable directory stated as the whole world, the moves, and "edit only files inside <dir>; touch no other path".

## [03]-[EXCLUSIONS]

What never enters either template:

- Per-file read caps and "read each file at most once" phrasing — the aggregation collapse above.
- Intensifier stacks, hostile-stance paragraphs, and multi-law prose blocks — zero depth gain, doubled tokens and latency, and out-of-territory probing; a lane takes de-conflicted, task-scoped law, never the estate register verbatim.
- Restatement of codex defaults (persistence-by-default, `apply_patch` fluency, exploration) — conflict risk against the shipped system prompt.
- Chain-of-thought scaffolding and plan-narration preambles — early-stop risk on codex.
- Broad write authority in a sandboxed write lane — the writable directory is the lane's whole world; cross-territory obligations belong to the caller.
