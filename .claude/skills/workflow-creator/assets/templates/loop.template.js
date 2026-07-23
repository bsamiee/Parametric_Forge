// loop.template.js — keep spawning agents until a goal is met.
// Topology: unknown count · accumulate until a target, or until the budget is low.
// Replace the TODOs, rename the file to <your-name>.js, drop it in .claude/workflows/.

export const meta = {
    name: 'TODO-loop',
    whenToUse: 'TODO: when a reader should pick this', // optional
    description: 'TODO: one line — what this produces',
    phases: [{ title: 'Collect' }],
};

// --- [MODELS] --------------------------------------------------------------------------

const RESULT_SCHEMA = {
    type: 'object',
    additionalProperties: false, // STRICT: required must list every property — codex --output-schema rejects anything less
    required: ['items'],
    properties: {
        items: { type: 'array', items: { type: 'string' } },
    },
};

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('Collect');
const collected = [];

// Compose the stop guards the run needs — count target, budget, dry streak, progress gate — and always keep a hard cap; the stop
// table, the guard spellings, and the drive-to-zero progress law are the patterns reference loops + reconcile shapes. This
// `!budget.total ||` form suits a loop carrying other stops; a PURELY budget-driven one takes `budget.total &&`. effort: 'low'
// suits a mechanical collect round; raise it when a round demands real reasoning. The dedup paste below grows per round — small-output-only; a heavy
// accumulator moves to a run-scratch report file + receipt (the report-file shape; scratch dir instance-minted per the scratch convention).

const seen = new Set();
let dry = 0;
while (dry < 2 && collected.length < 200 && (!budget.total || budget.remaining() > 50_000)) {
    const r = await agent('TODO: instruction. Do not repeat anything already found below.\n\n' + JSON.stringify(collected), {
        schema: RESULT_SCHEMA,
        effort: 'low',
    });

    // The seen-set is the dedup spine: yield measures genuinely NEW work, so a dry streak means the corpus is exhausted.
    const fresh = (r?.items ?? []).filter((x) => !seen.has(x));
    fresh.forEach((x) => {
        seen.add(x);
        collected.push(x);
    });
    dry = fresh.length === 0 ? dry + 1 : 0;
    log(`+${fresh.length} new · ${collected.length} collected · dry streak ${dry}`);
}

return { collected };
