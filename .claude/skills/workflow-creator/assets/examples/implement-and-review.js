/**
 * implement-and-review — implement a feature, then loop review-and-fix.
 *
 * The review loop lives in JavaScript, so unlike a hand-orchestrated chat it cannot
 * forget to re-review: a failing review feeds its issues back to a fix, up to 3 rounds.
 *
 * Workflow({ name: 'implement-and-review', args: 'collapse the duplicate mesh codecs in libs/csharp/Rasm into one [Union]' })
 */

export const meta = {
    name: 'implement-and-review',
    whenToUse: 'Implement a task, then loop an adversarial reviewer over it until it passes or hits a round cap.',
    description: 'Implement a feature, then loop review-and-fix until the review passes',
    phases: [{ title: 'Implement' }, { title: 'Review' }, { title: 'Fix' }],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const MAX_ROUNDS = 3; // hard cap — every loop in a workflow needs one.

// --- [INPUTS] --------------------------------------------------------------------------

// Structured args: a plain-text task string, else the default.
const task = typeof args === 'string' && args.trim() ? args : 'collapse the duplicate mesh codecs in libs/csharp/Rasm into one [Union]';

// --- [MODELS] --------------------------------------------------------------------------

// STRICT: additionalProperties:false + every property required; issues is required-but-empty on a pass.
const REVIEW = {
    type: 'object',
    additionalProperties: false,
    required: ['passed', 'issues'],
    properties: {
        passed: { type: 'boolean' },
        issues: { type: 'array', items: { type: 'string' } },
    },
};

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('Implement');
await agent(`Implement ${task}. Make the change in the codebase.`, { label: 'implement' });

let review;
let round = 0;

do {
    round++;

    // Fresh-context reviewer — it never saw the implementer's reasoning, so it grades the diff on merits, not rubber-stamps.
    phase('Review');
    review = await agent(`Review the current uncommitted changes for: ${task}. List concrete, specific issues.`, {
        label: `review:round-${round}`,
        schema: REVIEW,
    });

    if (review.passed) {
        log(`Review passed on round ${round}`);
        break;
    }

    log(`Round ${round}: ${review.issues.length} issue(s) — fixing`);
    phase('Fix');
    await agent(`Fix these review issues in the codebase:\n${review.issues.map((i) => `- ${i}`).join('\n')}`, { label: `fix:round-${round}` });
} while (round < MAX_ROUNDS);

return {
    passed: review.passed,
    rounds: round,
    remainingIssues: review.passed ? [] : review.issues,
};
