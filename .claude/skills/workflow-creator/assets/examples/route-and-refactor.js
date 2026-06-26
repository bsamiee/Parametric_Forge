/**
 * route-and-refactor — classify each changed file by language, dispatch it to the
 * matching language-specialist, run the specialists in parallel, then report.
 *
 * Rasm is one tri-language platform: the C# branch (`libs/csharp/Rasm*`) is the
 * Rhino/GH2 producer, Python (`libs/python/*`) is the host-free compute companion,
 * TypeScript (`libs/typescript/*`) is the host-free web/edge platform, and SQL is the
 * persistence dialect under the TS Postgres store (`libs/typescript/services/persistence`).
 * Each language has a DIFFERENT canonical refactor doctrine, so one generic "clean this
 * up" prompt is mediocre on all four. This routes each changed file to its own specialist
 * via a dispatch table — a ROUTES row per class, a plain-JS discriminant on the file
 * extension — then fans the specialists out.
 *
 * The dispatch table IS the pattern: adding a language is one ROUTES row, never a
 * branch threaded through the body. An unroutable file (a `.md`, a `.json`) returns
 * null from the thunk and falls out at `.filter(Boolean)` instead of hitting a wrong
 * specialist. The mechanical SQL row runs on Haiku; the rest inherit the session model.
 *
 * Workflow({ name: 'route-and-refactor',
 *            args: ['libs/csharp/Rasm.Compute/Solver.cs',
 *                   'libs/typescript/interchange/src/wire.ts',
 *                   'libs/python/geometry/offset.py',
 *                   'libs/typescript/services/persistence/migrations/0007_idempotency.sql'] })
 */

export const meta = {
  name: 'route-and-refactor',
  description: 'Classify each changed file by language and route it to the matching refactor specialist, then report',
  whenToUse: 'A cross-language change set where each file needs its own language doctrine, not one generic pass',
  phases: [
    { title: 'Refactor', detail: 'one specialist per file, routed by language' },
    { title: 'Report' },
  ],
}

// The result every specialist returns, whatever the language. Small and required-tight.
const REFACTOR = {
  type: 'object',
  required: ['file', 'changed'],
  properties: {
    file: { type: 'string' },
    changed: { type: 'boolean' },     // false when the file was already canonical
    summary: { type: 'string' },      // what was collapsed/rewritten, or why nothing was
    deferred: { type: 'array', items: { type: 'string' } }, // cross-file follow-ups, if any
  },
}

// One row per language class: the specialist prompt for a file, and the model it runs on.
// The three judgement-heavy rows omit `model` — an omitted/undefined model inherits the
// session model, the capable default. Only the mechanical SQL rewrite drops to Haiku.
const ROUTES = {
  cs: {
    prompt: f =>
      `Refactor ${f} to the C# doctrine in docs/stacks/csharp: collapse parallel types, ` +
      `sibling factories, and repeated switch arms into a Thinktecture [Union]/[SmartEnum], ` +
      `and replace exception control flow with LanguageExt Fin/Eff rails. Densify in place; ` +
      `do not extract helper files. Report what collapsed and any cross-file follow-up.`,
  },
  ts: {
    prompt: f =>
      `Refactor ${f} to the TypeScript doctrine in coding-ts: replace thrown errors with ` +
      `typed Effect error channels, model variants as exhaustive discriminated unions, and ` +
      `move boundary parsing to Schema. No any, no enum, no throw. Report what changed and ` +
      `any cross-file follow-up.`,
  },
  py: {
    prompt: f =>
      `Refactor ${f} to the Python doctrine in coding-python: rewrite mutable accumulation as ` +
      `expression-style folds and comprehensions, route failures through a typed Result rail, ` +
      `and tighten the type annotations. Report what changed and any cross-file follow-up.`,
  },
  sql: {
    model: 'haiku',
    prompt: f =>
      `Rewrite ${f} set-algebraically per coding-pg: push filters into the query, replace ` +
      `row-by-row logic with set operations, and pin invariants at the schema level. Report ` +
      `what changed and any cross-file follow-up.`,
  },
}

// Plain-JS classifier — the discriminant is the file extension. Returns the ROUTES
// key, or null for a file no specialist owns.
const classify = f =>
  f.endsWith('.cs')  ? 'cs'
  : f.endsWith('.ts') || f.endsWith('.tsx') ? 'ts'
  : f.endsWith('.py') ? 'py'
  : f.endsWith('.sql') ? 'sql'
  : null

// `args` arrives as structured data — a list of changed paths stays a list, read it
// directly. Nothing passed falls back to a representative cross-language change set.
const changed = Array.isArray(args) && args.length
  ? args
  : [
      'libs/csharp/Rasm.Compute/Solver.cs',
      'libs/typescript/interchange/src/wire.ts',
      'libs/python/geometry/offset.py',
      'libs/typescript/services/persistence/migrations/0007_idempotency.sql',
    ]

phase('Refactor')
log(`${changed.length} changed file(s) to route`)

// Fan out one specialist per file. This is fan-out (the fan-out template skeleton),
// not a dedup barrier: the specialists are independent and only the terminal Report
// stage needs them together. The dispatch table is threaded into each thunk — the
// classifier picks the ROUTES row, an unroutable file returns null.
const results = await parallel(changed.map(f => () => {
  const route = ROUTES[classify(f)]
  return route
    ? agent(route.prompt(f), { label: `refactor:${f}`, phase: 'Refactor', model: route.model, schema: REFACTOR })
    : null
}))

// Unroutable files and failed slots are both null — one filter clears both.
const done = results.filter(Boolean)
const touched = done.filter(r => r.changed)
log(`${done.length}/${changed.length} routed · ${touched.length} file(s) changed`)

if (touched.length === 0) {
  return { routed: done.length, changed: 0, message: 'Every routed file was already canonical' }
}

// One terminal synthesis agent — a fresh context that never saw the specialists. It
// learns the outcomes only from the paste, and owns the cross-file follow-ups no
// single specialist could resolve alone.
phase('Report')
const report = await agent(
  `These per-file refactors landed across the tri-language workspace. Write a review ` +
  `briefing: group the changes by language, flag any cross-file follow-up a specialist ` +
  `deferred, and call out any seam where two branches must stay aligned at the wire.\n\n` +
  JSON.stringify(touched, null, 2),
  { label: 'report', phase: 'Report' },
)

return { routed: done.length, changed: touched.length, report }
