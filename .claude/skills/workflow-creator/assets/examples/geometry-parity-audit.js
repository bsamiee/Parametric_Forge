/**
 * geometry-parity-audit — compare each shared geometry op across the C# kernel and
 * the Python companion, then cluster the divergences into themes.
 *
 * Demonstrates a correct barrier: clustering works across the whole divergence set —
 * a theme cannot be named from one op alone — so parallel() must gather every
 * comparison before the cluster stage runs.
 *
 * Workflow({ name: 'geometry-parity-audit',
 *            args: { ops: ['curve offset', 'mesh boolean', 'surface intersect'] } })
 */

export const meta = {
    name: 'geometry-parity-audit',
    description: 'Compare each shared geometry op across the C# kernel and Python companion, cluster the divergences',
    whenToUse: 'Auditing cross-runtime parity before locking a wire contract',
    phases: [{ title: 'Enumerate ops' }, { title: 'Compare', detail: 'one agent per operation', model: 'sonnet' }, { title: 'Cluster divergences' }],
};

// --- [INPUTS] --------------------------------------------------------------------------

// Structured args: an `ops` list overrides discovery; omit it to enumerate the shared ops.
const seedOps = Array.isArray(args?.ops) ? args.ops : null;

// --- [MODELS] --------------------------------------------------------------------------

// STRICT everywhere: additionalProperties:false + every property required at every level; a conditional field is required-but-empty (''), never omitted.
const OPS = {
    type: 'object',
    additionalProperties: false,
    required: ['ops'],
    properties: {
        ops: { type: 'array', items: { type: 'string' } },
    },
};

const COMPARISON = {
    type: 'object',
    additionalProperties: false,
    required: ['op', 'diverges', 'detail', 'csharpRef', 'pythonRef'],
    properties: {
        op: { type: 'string' },
        diverges: { type: 'boolean' },
        detail: { type: 'string' }, // empty when the implementations agree
        csharpRef: { type: 'string' },
        pythonRef: { type: 'string' },
    },
};

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('Enumerate ops');
const ops =
    seedOps ??
    (
        await agent(
            'List the geometry operations implemented in BOTH libs/csharp/Rasm and ' +
                'libs/python/geometry — the ops that must agree at the wire. Return each op name.',
            { label: 'enumerate-ops', phase: 'Enumerate ops', schema: OPS },
        )
    ).ops;
log(`${ops.length} shared operation(s) to compare`);

// Barrier: clustering works across the whole divergence set, so it needs every comparison together.
const comparisons = await parallel(
    ops.map(
        (op) => () =>
            agent(
                `Compare how "${op}" is implemented in libs/csharp/Rasm versus libs/python/geometry. ` +
                    `Read both implementations. Report whether their numeric results, tolerance handling, ` +
                    `or degenerate-case behavior diverge, and cite the file:symbol on each side.`,
                { label: `compare:${op}`, phase: 'Compare', model: 'sonnet', schema: COMPARISON },
            ),
    ),
);

const divergent = comparisons.filter(Boolean).filter((c) => c.diverges);
log(`${divergent.length} of ${ops.length} operation(s) diverge`);

if (divergent.length === 0) {
    return { compared: ops.length, divergent: 0, message: 'Kernels agree across every shared op' };
}

// --- [CLUSTER_DIVERGENCES]

// Paste fan-in is small-output-only; past ~50 rows move the product to a scratch report file + receipt.
phase('Cluster divergences');
const report = await agent(
    `Here are ${divergent.length} cross-runtime geometry divergences. Cluster them into ` +
        `themes (tolerance policy, degenerate handling, numeric drift, missing case), name each ` +
        `theme, and for each say which side is the likely reference. Return a ranked briefing.\n\n` +
        divergent.map((d) => `- ${d.op}: ${d.detail}\n  C#: ${d.csharpRef}\n  Py: ${d.pythonRef}`).join('\n'),
    { label: 'cluster-divergences', phase: 'Cluster divergences' },
);

return { compared: ops.length, divergent: divergent.length, report };
