/**
 * implement-and-review — implement a feature, then loop review-and-fix.
 *
 * Implement once, then review. If the review fails, fix the listed issues and
 * review again — up to 3 rounds. The loop lives in JavaScript, so unlike a
 * hand-orchestrated chat it physically cannot forget to re-review.
 *
 * Workflow({ name: 'implement-and-review', args: 'collapse the duplicate mesh codecs in libs/csharp/Rasm into one [Union]' })
 */

export const meta = {
  name: 'implement-and-review',
  whenToUse: 'Implement a task, then loop an adversarial reviewer over it until it passes or hits a round cap.',
  description: 'Implement a feature, then loop review-and-fix until the review passes',
  phases: [
    { title: 'Implement' },
    { title: 'Review' },
    { title: 'Fix' },
  ],
}

// The reviewer must answer two things: did it pass, and if not, what is wrong.
const REVIEW = {
  type: 'object',
  required: ['passed', 'issues'],
  properties: {
    passed: { type: 'boolean' },
    issues: { type: 'array', items: { type: 'string' } },
  },
}

// `args` arrives as structured data. This workflow expects a plain-text task
// string; anything else falls back to the default.
const task = typeof args === 'string' && args.trim() ? args : 'collapse the duplicate mesh codecs in libs/csharp/Rasm into one [Union]'
const MAX_ROUNDS = 3 // hard cap — every loop in a workflow needs one.

phase('Implement')
await agent(`Implement ${task}. Make the change in the codebase.`, { label: 'implement' })

let review
let round = 0

do {
  round++

  // The reviewer is a fresh-context agent — it never saw the implementer's
  // reasoning, so it grades the diff on its merits instead of rubber-stamping.
  phase('Review')
  review = await agent(
    `Review the current uncommitted changes for: ${task}. List concrete, specific issues.`,
    { label: `review:round-${round}`, schema: REVIEW },
  )

  if (review.passed) {
    log(`Review passed on round ${round}`)
    break
  }

  log(`Round ${round}: ${review.issues.length} issue(s) — fixing`)
  phase('Fix')
  await agent(
    `Fix these review issues in the codebase:\n${review.issues.map(i => `- ${i}`).join('\n')}`,
    { label: `fix:round-${round}` },
  )
} while (round < MAX_ROUNDS)

return {
  passed: review.passed,
  rounds: round,
  remainingIssues: review.passed ? [] : review.issues,
}
