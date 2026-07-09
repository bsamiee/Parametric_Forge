/**
 * api-contract-drift-detector — find where a shared wire type has drifted between
 * the C# producer and its host-free consumers, then open one consolidated PR.
 *
 * The three branches couple only at the wire: C# is the producer, libs/python/data
 * and libs/typescript/interchange are the host-free consumers. A wire type is in
 * sync only when all three agree on its field set, names, optionality, and codes.
 * This fans out one checker per shared wire type — each agent reads the C# producer
 * shape and both consumer mirrors and reports any divergence. The parallel() call
 * is a genuine barrier: the consolidated drift PR has to touch every divergence at
 * once, so it needs the full set of results before it can run — a barrier is correct.
 *
 * Workflow({ name: 'api-contract-drift-detector',
 *            args: { types: ['MeshPayload', 'IfcEntityRef', 'UnitSystem'] } })
 */

export const meta = {
  name: 'api-contract-drift-detector',
  description: 'Check each shared wire type across the C# producer and its Python/TypeScript consumers and open a draft PR for any drift',
  whenToUse: 'Auditing wire-contract parity across the tri-language platform before a release',
  phases: [
    { title: 'List wire types' },
    { title: 'Check', detail: 'one agent per wire type', model: 'sonnet' },
    { title: 'Open PR' },
  ],
}

// --- [INPUTS] ----------------------------------------------------------------------------

// `args` arrives as structured data. An object with a `types` list overrides the discovery step; nothing passed lets the kernel enumerate the shared wire types.
const seedTypes = Array.isArray(args?.types) ? args.types : null

// --- [MODELS] ----------------------------------------------------------------------------

// STRICT everywhere: additionalProperties:false + every property required at every level; a conditional field is required-but-empty ('' / []), never omitted.
const TYPES = {
  type: 'object',
  additionalProperties: false,
  required: ['types'],
  properties: {
    types: { type: 'array', items: { type: 'string' } },
  },
}

const DRIFT = {
  type: 'object',
  additionalProperties: false,
  required: ['type', 'hasDrift', 'summary', 'producerRef', 'consumerRefs', 'fix'],
  properties: {
    type: { type: 'string' },
    hasDrift: { type: 'boolean' },
    summary: { type: 'string' },       // empty when hasDrift is false
    producerRef: { type: 'string' },
    consumerRefs: { type: 'array', items: { type: 'string' } },
    fix: { type: 'string' },           // corrected consumer-side snippet, empty when in sync
  },
}

// --- [COMPOSITION] -----------------------------------------------------------------------

phase('List wire types')
const { types } = seedTypes
  ? { types: seedTypes }
  : await agent(
      'List every wire type that crosses the platform boundary — the contracts the ' +
      'C# producer emits and that BOTH libs/python/data and libs/typescript/interchange ' +
      'decode. Return each type name.',
      { label: 'list-wire-types', phase: 'List wire types', schema: TYPES },
    )
log(`${types.length} shared wire type(s) to check`)

// Fan out — one checker per wire type, all at once. Barrier on purpose: the PR stage edits every divergence together, so it needs the full set of results.
const checks = await parallel(types.map(wt => () =>
  agent(
    `Check the wire type "${wt}" for drift across the three branches. Read the C# producer ` +
    `shape, then libs/python/data and libs/typescript/interchange where the consumers decode ` +
    `it. Report whether field names, optionality, enum codes, or ordering have diverged from ` +
    `the producer, cite the file:symbol on each side, and if drift exists give a corrected ` +
    `consumer-side snippet.`,
    { label: `check:${wt}`, phase: 'Check', model: 'sonnet', schema: DRIFT },
  ),
))

const drifted = checks.filter(Boolean).filter(c => c.hasDrift)
log(`${drifted.length} of ${types.length} wire type(s) drifted`)

if (drifted.length === 0) {
  return { checked: types.length, drifted: 0, message: 'Wire contracts are in sync across all three branches' }
}

// --- [OPEN_PR]

// Paste fan-in is small-output-only (drift set bounded by the wire-type roster); past
// ~50 rows the product moves to a scratch report file + receipt — the patterns reference report-file shape.
phase('Open PR')
await agent(
  `Open ONE draft pull request that realigns every drifted wire type to its C# producer ` +
  `shape — the producer is the reference, only the consumer mirrors change. For each type ` +
  `below, apply the corrected snippet on the cited consumer side and keep the C# producer ` +
  `untouched. Title the PR for the wire-contract drift it closes:\n\n` +
  drifted.map(d =>
    `### ${d.type}\n${d.summary}\nProducer (reference): ${d.producerRef}\n` +
    `Consumers: ${d.consumerRefs.join(', ')}\n${d.fix}`,
  ).join('\n\n'),
  { label: 'open-pr', phase: 'Open PR' },
)

return { checked: types.length, drifted: drifted.length, types: drifted }
