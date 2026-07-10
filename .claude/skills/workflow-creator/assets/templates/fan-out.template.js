// fan-out.template.js — research/process a known list in parallel, then synthesize.
// Topology: independent units · one pass each · barrier before the synthesis step.
// Replace the TODOs, rename the file to <your-name>.js, drop it in .claude/workflows/.

export const meta = {
    name: 'TODO-fan-out', // required — the workflow's name
    description: 'TODO: one line — what this produces', // required — shown in the permission dialog
    whenToUse: 'TODO: when a reader should pick this', // optional
    phases: [{ title: 'Work' }, { title: 'Synthesize' }],
};

// --- [INPUTS] --------------------------------------------------------------------------

// The unit of work. Pass a real list as the Workflow `args`, or hardcode one. `args` arrives as structured data — an array stays an array, read it directly.
const items = Array.isArray(args) && args.length ? args : ['TODO item one', 'TODO item two'];

// --- [MODELS] --------------------------------------------------------------------------

// Structured output — the subagent is forced to return an object matching this.
const ITEM_SCHEMA = {
    type: 'object',
    additionalProperties: false, // STRICT: required must list every property — codex --output-schema rejects anything less
    required: ['summary', 'points'], // STRICT: every property listed in required (conditional = required-but-empty) — codex --output-schema 400s otherwise
    properties: {
        summary: { type: 'string' },
        points: { type: 'array', items: { type: 'string' } },
    },
};

// --- [COMPOSITION] ---------------------------------------------------------------------

// PHASE 1 — one fresh-context subagent per item, all at once. parallel() is a barrier: it waits for every thunk. Note the shape — () => agent(...), a thunk.
// Pin each agent to the phase via the option (concurrent calls would otherwise race on the global phase()). effort: 'low' suits a mechanical per-item pass;
// drop it for a judgement-heavy worker (effort guidance: references/api.md).
phase('Work');
log(`Processing ${items.length} item(s)...`);
const results = await parallel(
    items.map(
        (item, i) => () =>
            agent(`TODO: instruction for one item. Item:\n\n${item}`, { label: `item-${i + 1}`, phase: 'Work', schema: ITEM_SCHEMA, effort: 'low' }),
    ),
);

// parallel()/pipeline() leave null in skipped/failed slots — always filter.
const clean = results.map((r, i) => (r ? { item: items[i], ...r } : null)).filter(Boolean);
log(`${clean.length}/${items.length} returned usable results.`);

// PHASE 2 — one synthesis agent. It is a fresh context: it never saw the workers. It learns the results only because we paste them into its prompt.
// Paste fan-in is the SMALL-output shape; past ~50 rows the product moves to a run-scratch report file + thin receipt — the patterns reference report-file shape.

// --- [SYNTHESIZE]
phase('Synthesize');
const report = await agent('TODO: instruction — combine the results below into one deliverable.\n\n' + JSON.stringify(clean, null, 2));

return { count: clean.length, report };
