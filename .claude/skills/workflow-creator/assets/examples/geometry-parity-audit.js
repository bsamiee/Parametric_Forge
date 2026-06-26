/**
 * geometry-parity-audit — find where the C# geometry kernel and the Python
 * companion disagree, then cluster the divergences into themes.
 *
 * Rasm runs two host-free geometry stacks that must agree at the wire: the C#
 * `Rasm` kernel and the Python `geometry` companion. This fans out one agent per
 * shared operation (curve offset, mesh boolean, surface intersect, …) to compare
 * the two implementations, then clusters every divergence it found. The
 * parallel() call is a genuine barrier: clustering needs every comparison at once
 * — you cannot name a theme from one operation alone — so a barrier is correct.
 *
 * Workflow({ name: 'geometry-parity-audit',
 *            args: { ops: ['curve offset', 'mesh boolean', 'surface intersect'] } })
 */

export const meta = {
  name: 'geometry-parity-audit',
  description: 'Compare each shared geometry op across the C# kernel and Python companion, cluster the divergences',
  whenToUse: 'Auditing cross-runtime parity before locking a wire contract',
  phases: [
    { title: 'Enumerate ops' },
    { title: 'Compare', detail: 'one agent per operation', model: 'haiku' },
    { title: 'Cluster divergences' },
  ],
}

const OPS = {
  type: 'object',
  required: ['ops'],
  properties: {
    ops: { type: 'array', items: { type: 'string' } },
  },
}

const COMPARISON = {
  type: 'object',
  required: ['op', 'diverges'],
  properties: {
    op: { type: 'string' },
    diverges: { type: 'boolean' },
    detail: { type: 'string' },
    csharpRef: { type: 'string' },
    pythonRef: { type: 'string' },
  },
}

// `args` arrives as structured data. An object with an `ops` list overrides the
// discovery step; nothing passed lets the kernel enumerate the shared ops itself.
const seedOps = Array.isArray(args?.ops) ? args.ops : null

phase('Enumerate ops')
const ops = seedOps ?? (await agent(
  'List the geometry operations implemented in BOTH libs/csharp/Rasm and ' +
  'libs/python/geometry — the ops that must agree at the wire. Return each op name.',
  { label: 'enumerate-ops', phase: 'Enumerate ops', schema: OPS },
)).ops
log(`${ops.length} shared operation(s) to compare`)

// Compare each op independently. Barrier on purpose — the clustering step works
// across the WHOLE set of divergences, so it needs every comparison together.
const comparisons = await parallel(ops.map(op => () =>
  agent(
    `Compare how "${op}" is implemented in libs/csharp/Rasm versus libs/python/geometry. ` +
    `Read both implementations. Report whether their numeric results, tolerance handling, ` +
    `or degenerate-case behavior diverge, and cite the file:symbol on each side.`,
    { label: `compare:${op}`, phase: 'Compare', model: 'haiku', schema: COMPARISON },
  ),
))

const divergent = comparisons.filter(Boolean).filter(c => c.diverges)
log(`${divergent.length} of ${ops.length} operation(s) diverge`)

if (divergent.length === 0) {
  return { compared: ops.length, divergent: 0, message: 'Kernels agree across every shared op' }
}

phase('Cluster divergences')
const report = await agent(
  `Here are ${divergent.length} cross-runtime geometry divergences. Cluster them into ` +
  `themes (tolerance policy, degenerate handling, numeric drift, missing case), name each ` +
  `theme, and for each say which side is the likely reference. Return a ranked briefing.\n\n` +
  divergent.map(d => `- ${d.op}: ${d.detail}\n  C#: ${d.csharpRef}\n  Py: ${d.pythonRef}`).join('\n'),
  { label: 'cluster-divergences', phase: 'Cluster divergences' },
)

return { compared: ops.length, divergent: divergent.length, report }
