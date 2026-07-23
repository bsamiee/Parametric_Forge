/**
 * review-branch — pre-PR review with adversarial verification.
 *
 * Demonstrates pipeline (no barrier): each finding verifies the moment ITS review
 * returns, never waiting for the slowest reviewer. Model and effort are independent
 * axes — verify drops the model tier yet keeps effort: 'high', so the refute
 * still reasons hard; effort tiers the reasoning, not the model.
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
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const DIMENSIONS = [
    { key: 'bugs', prompt: 'Find logic bugs in the files changed on this branch vs main.' },
    { key: 'security', prompt: 'Find security issues in the files changed on this branch vs main.' },
    { key: 'tests', prompt: 'Find missing or weak test coverage in the changes on this branch.' },
];

// --- [MODELS] --------------------------------------------------------------------------

// STRICT: additionalProperties:false + every property required; a conditional field is required-but-empty (''), never omitted.
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
};

const VERDICT = {
    type: 'object',
    additionalProperties: false,
    required: ['isReal', 'reason'],
    properties: {
        isReal: { type: 'boolean' },
        reason: { type: 'string' }, // the refutation when isReal is false; empty when confirmed
    },
};

// --- [COMPOSITION] ---------------------------------------------------------------------

const results = await pipeline(
    DIMENSIONS,
    // Stage 1 — review one dimension.
    (d) => agent(d.prompt, { label: `review:${d.key}`, phase: 'Review', schema: FINDINGS }),
    // Stage 2 — verify every finding from that dimension, in parallel.
    (review, d) =>
        parallel(
            (review?.findings ?? []).map(
                (f) => () =>
                    agent(
                        `Adversarially verify this finding. Try hard to refute it; if you cannot, it is real.\n` +
                            `Finding: ${f.title}\nFile: ${f.file}\nSeverity: ${f.severity}`,
                        { label: `verify:${d.key}:${f.file}`, phase: 'Verify', model: 'sonnet', effort: 'high', schema: VERDICT },
                    ).then((v) => ({ ...f, dimension: d.key, verdict: v })),
            ),
        ),
);

// pipeline() returns one array per dimension → flatten, drop null slots.
const confirmed = results
    .flat()
    .filter(Boolean)
    .filter((f) => f.verdict?.isReal);
log(`${confirmed.length} confirmed findings`);

return { confirmedCount: confirmed.length, confirmed };
