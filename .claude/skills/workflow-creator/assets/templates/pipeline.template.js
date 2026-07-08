// pipeline.template.js — run each item through ordered stages, no barrier between.
// Topology: each item advances the moment IT is ready. The default multi-stage shape.
// Replace the TODOs, rename the file to <your-name>.js, drop it in .claude/workflows/.

export const meta = {
  name: 'TODO-pipeline',                              // required — the workflow's name
  whenToUse: 'TODO: when a reader should pick this',  // optional
  description: 'TODO: one line — what this produces', // required — shown in the permission dialog
  phases: [{ title: 'Stage1' }, { title: 'Stage2' }], // optional — progress groups (see the phase option below)
}

// --- [INPUTS] ----------------------------------------------------------------------------

// `args` arrives as structured data — an array stays an array, read it directly.
const items = Array.isArray(args) && args.length ? args : ['TODO item one', 'TODO item two']

// --- [MODELS] ----------------------------------------------------------------------------
const STAGE1_SCHEMA = {
  type: 'object',
  additionalProperties: false, // STRICT: required must list every property — codex --output-schema rejects anything less
  required: ['result'],
  properties: { result: { type: 'string' } },
}

// --- [COMPOSITION] -----------------------------------------------------------------------

// pipeline(items, stage1, stage2, ...) — each stage callback gets
// (prevResult, originalItem, index). There is NO barrier between stages:
// item A can be in Stage2 while item B is still in Stage1.
// effort: 'low' fits a mechanical classify/extract first stage; let the later
// stage inherit the session tier for the heavier reasoning over its result
// (effort guidance: references/api-reference.md).
const out = await pipeline(
  items,

  // Stage 1 — runs once per item.
  (item, _orig, i) =>
    agent(`TODO: first-stage instruction. Item:\n\n${item}`,
          { label: `s1:${i + 1}`, phase: 'Stage1', schema: STAGE1_SCHEMA, effort: 'low' }),

  // Stage 2 — receives Stage 1's result for the same item.
  (prev, item, i) =>
    agent(`TODO: second-stage instruction.\nItem: ${item}\nStage 1 said: ${prev?.result}`,
          { label: `s2:${i + 1}`, phase: 'Stage2' }),
)

// A stage that throws drops that item to null — filter before using.
return { done: out.filter(Boolean) }
