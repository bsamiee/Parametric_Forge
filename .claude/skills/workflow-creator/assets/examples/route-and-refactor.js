/**
 * route-and-refactor — classify each changed file by language, dispatch it to the
 * matching language-specialist, run the specialists in parallel, then report.
 *
 * Demonstrates dispatch-table fan-out: a ROUTES row per language class, a plain-JS
 * discriminant on the file extension. Adding a language is one row, never a branch
 * threaded through the body; an unroutable file returns null and falls out at
 * `.filter(Boolean)` instead of hitting a wrong specialist.
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
    phases: [{ title: 'Refactor', detail: 'one specialist per file, routed by language' }, { title: 'Report' }],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

// One row per language class. An omitted model inherits the session default; only the mechanical SQL row drops to Sonnet.
const ROUTES = {
    cs: {
        prompt: (f) =>
            `Refactor ${f} to the C# doctrine in docs/stacks/csharp: collapse parallel types, ` +
            `sibling factories, and repeated switch arms into a Thinktecture [Union]/[SmartEnum], ` +
            `and replace exception control flow with LanguageExt Fin/Eff rails. Densify in place; ` +
            `do not extract helper files. Report what collapsed and any cross-file follow-up.`,
    },
    ts: {
        prompt: (f) =>
            `Refactor ${f} to the TypeScript doctrine in docs/stacks/typescript/: replace thrown errors with ` +
            `typed Effect error channels, model variants as exhaustive discriminated unions, and ` +
            `move boundary parsing to Schema. No any, no enum, no throw. Report what changed and ` +
            `any cross-file follow-up.`,
    },
    py: {
        prompt: (f) =>
            `Refactor ${f} to the Python doctrine in docs/stacks/python: rewrite mutable accumulation as ` +
            `expression-style folds and comprehensions, route failures through a typed Result rail, ` +
            `and tighten the type annotations. Report what changed and any cross-file follow-up.`,
    },
    sql: {
        model: 'sonnet',
        prompt: (f) =>
            `Rewrite ${f} set-algebraically per coding-pg: push filters into the query, replace ` +
            `row-by-row logic with set operations, and pin invariants at the schema level. Report ` +
            `what changed and any cross-file follow-up.`,
    },
};

// --- [MODELS] --------------------------------------------------------------------------

// STRICT: additionalProperties:false + every property required; conditional fields are required-but-empty ('' / []).
const REFACTOR = {
    type: 'object',
    additionalProperties: false,
    required: ['file', 'changed', 'summary', 'deferred'],
    properties: {
        file: { type: 'string' },
        changed: { type: 'boolean' }, // false when the file was already canonical
        summary: { type: 'string' }, // what was collapsed/rewritten, or why nothing was
        deferred: { type: 'array', items: { type: 'string' } }, // cross-file follow-ups; empty attests none
    },
};

// --- [OPERATIONS] ----------------------------------------------------------------------

// Returns the ROUTES key, or null for a file no specialist owns — the null falls out at the filter.
const classify = (f) =>
    f.endsWith('.cs') ? 'cs' : f.endsWith('.ts') || f.endsWith('.tsx') ? 'ts' : f.endsWith('.py') ? 'py' : f.endsWith('.sql') ? 'sql' : null;

// --- [COMPOSITION] ---------------------------------------------------------------------

// args arrives as structured data — read the list directly; the fallback is a representative cross-language set.
const changed =
    Array.isArray(args) && args.length
        ? args
        : [
              'libs/csharp/Rasm.Compute/Solver.cs',
              'libs/typescript/interchange/src/wire.ts',
              'libs/python/geometry/offset.py',
              'libs/typescript/services/persistence/migrations/0007_idempotency.sql',
          ];

phase('Refactor');
log(`${changed.length} changed file(s) to route`);

// Fan-out, not a dedup barrier: the specialists are independent, only the terminal Report stage needs them together.
const results = await parallel(
    changed.map((f) => () => {
        const route = ROUTES[classify(f)];
        return route ? agent(route.prompt(f), { label: `refactor:${f}`, phase: 'Refactor', model: route.model, schema: REFACTOR }) : null;
    }),
);

// Unroutable files and failed slots are both null — one filter clears both.
const done = results.filter(Boolean);
const touched = done.filter((r) => r.changed);
log(`${done.length}/${changed.length} routed · ${touched.length} file(s) changed`);

if (touched.length === 0) {
    return { routed: done.length, changed: 0, message: 'Every routed file was already canonical' };
}

// Fresh-context synthesis agent — learns the outcomes only from the paste. Paste fan-in is
// small-output-only; a change set past ~50 files moves each result to a scratch report file + receipt.

// --- [REPORT]
phase('Report');
const report = await agent(
    `These per-file refactors landed across the tri-language workspace. Write a review ` +
        `briefing: group the changes by language, flag any cross-file follow-up a specialist ` +
        `deferred, and call out any seam where two branches must stay aligned at the wire.\n\n` +
        JSON.stringify(touched, null, 2),
    { label: 'report', phase: 'Report' },
);

return { routed: done.length, changed: touched.length, report };
