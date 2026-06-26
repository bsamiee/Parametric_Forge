// loop.template.js — keep spawning agents until a goal is met.
// Topology: unknown count · accumulate until a target, or until the budget is low.
// Replace the TODOs, rename the file to <your-name>.js, drop it in .claude/workflows/.

export const meta = {
  name: 'TODO-loop',
  whenToUse: 'TODO: when a reader should pick this',  // optional
  description: 'TODO: one line — what this produces',
  phases: [{ title: 'Collect' }],
}

const RESULT_SCHEMA = {
  type: 'object',
  required: ['items'],
  properties: {
    items: { type: 'array', items: { type: 'string' } },
  },
}

phase('Collect')
const collected = []

// CHOOSE ONE STOP CONDITION — never leave a loop unbounded.
//
// (a) Fixed target:
//        while (collected.length < 10) { ... }
//
// (b) Budget-scaled — depth follows the user's "+500k"-style token target.
//     The `budget.total &&` guard is REQUIRED: with no target set,
//     budget.remaining() is Infinity and the loop runs to the 1000-agent cap.
//
// (c) Convergence — stop when the work runs dry or a check passes, always with
//     a hard round cap as a backstop. Two shapes, both needing the MAX_ROUNDS guard:
//        let dry = 0
//        while (dry < 2 && round < MAX_ROUNDS) { ...; if (empty) dry++; else dry = 0 }
//        do { round++; ...; if (passed) break } while (round < MAX_ROUNDS)
//
// effort: 'low' suits a mechanical collect/discovery round; raise it if each
// round demands real reasoning (effort guidance: references/api-reference.md).
while (budget.total && budget.remaining() > 50_000 && collected.length < 200) {
  const r = await agent(
    'TODO: instruction. Do not repeat anything already found below.\n\n'
    + JSON.stringify(collected),
    { schema: RESULT_SCHEMA, effort: 'low' })

  collected.push(...(r?.items ?? []))
  log(`${collected.length} collected · ${Math.round(budget.remaining() / 1000)}k tokens left`)
}

return { collected }
