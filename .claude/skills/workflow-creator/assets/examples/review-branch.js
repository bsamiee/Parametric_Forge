/**
 * review-branch — pre-PR review with adversarial verification.
 *
 * Fans out one reviewer per dimension (bugs / security / tests). The moment a
 * dimension's review returns, each finding it raised is verified in parallel by
 * a cheap Sonnet agent that tries to refute it. pipeline() means a finding
 * verifies as soon as ITS review is done — no waiting for the slowest reviewer.
 *
 * Two axes, set independently: the verify stage drops to model: 'sonnet' (cheap
 * per-finding fan-out) but keeps effort: 'high' so the adversarial refute still
 * reasons hard — effort tiers the reasoning, not the model.
 *
 * Run before opening a PR:  Workflow({ name: 'review-branch' })
 */

export const meta = {
  name: 'review-branch',
  description: 'Review the current branch across dimensions, then adversarially verify each finding',
  whenToUse: 'Before opening a pull request',
  phases: [
    { title: 'Review', detail: 'one reviewer per dimension' },
    { title: 'Verify', detail: 'try to refute each finding', model: 'sonnet' },
  ],
}

// --- [CONSTANTS] -------------------------------------------------------------------------

const DIMENSIONS = [
  { key: 'bugs',     prompt: 'Find logic bugs in the files changed on this branch vs main.' },
  { key: 'security', prompt: 'Find security issues in the files changed on this branch vs main.' },
  { key: 'tests',    prompt: 'Find missing or weak test coverage in the changes on this branch.' },
]

// --- [MODELS] ----------------------------------------------------------------------------

// Structured output: each reviewer must return findings in this exact shape.
// STRICT everywhere: additionalProperties:false + every property required at every level; a conditional field is required-but-empty (''), never omitted.
const FINDINGS = {
  type: 'object',
  additionalProperties: false,
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['title', 'file', 'severity'],
        properties: {
          title: { type: 'string' },
          file: { type: 'string' },
          severity: { type: 'string', enum: ['low', 'medium', 'high'] },
        },
      },
    },
  },
}

const VERDICT = {
  type: 'object',
  additionalProperties: false,
  required: ['isReal', 'reason'],
  properties: {
    isReal: { type: 'boolean' },
    reason: { type: 'string' }, // the refutation when isReal is false; empty when confirmed
  },
}

// --- [COMPOSITION] -----------------------------------------------------------------------

const results = await pipeline(
  DIMENSIONS,
  // Stage 1 — review one dimension.
  d => agent(d.prompt, { label: `review:${d.key}`, phase: 'Review', schema: FINDINGS }),
  // Stage 2 — verify every finding from that dimension, in parallel.
  (review, d) => parallel(
    (review?.findings ?? []).map(f => () =>
      agent(
        `Adversarially verify this finding. Try hard to refute it; if you cannot, it is real.\n` +
        `Finding: ${f.title}\nFile: ${f.file}\nSeverity: ${f.severity}`,
        { label: `verify:${d.key}:${f.file}`, phase: 'Verify', model: 'sonnet', effort: 'high', schema: VERDICT },
      ).then(v => ({ ...f, dimension: d.key, verdict: v })),
    ),
  ),
)

// pipeline() returns one array per dimension → flatten, drop null slots.
const confirmed = results.flat().filter(Boolean).filter(f => f.verdict?.isReal)
log(`${confirmed.length} confirmed findings`)

return { confirmedCount: confirmed.length, confirmed }
