/**
 * planning-card-triage — realize the open planning cards that matter most.
 *
 * Each Rasm package owns a pool of IDEAS/TASK cards under its `.planning/`. This
 * pulls the open cards for a scope, keeps only those at or above a priority
 * threshold (default 'high'), then realizes and verifies each one. The threshold
 * filter is one line of ordinary JavaScript between the two agent stages.
 *
 * Workflow({ name: 'planning-card-triage',
 *            args: { scope: 'libs/csharp/Rasm.Bim', minPriority: 'high' } })
 */

export const meta = {
  name: 'planning-card-triage',
  whenToUse: 'Pull the open planning cards for a scope, keep the high-priority ones, and realize plus verify each.',
  description: 'Pull open planning cards for a scope, realize the ones at/above a priority, verify each',
  phases: [
    { title: 'Pull cards' },
    { title: 'Realize', detail: 'one agent per card' },
    { title: 'Verify' },
  ],
}

const CARDS = {
  type: 'object',
  required: ['cards'],
  properties: {
    cards: {
      type: 'array',
      items: {
        type: 'object',
        required: ['id', 'title', 'priority'],
        properties: {
          id: { type: 'string' },
          title: { type: 'string' },
          priority: { type: 'string', enum: ['low', 'medium', 'high', 'critical'] },
          file: { type: 'string' },
        },
      },
    },
  },
}

const VERDICT = {
  type: 'object',
  required: ['realized'],
  properties: {
    realized: { type: 'boolean' },
    note: { type: 'string' },
  },
}

// `args` arrives as structured data — read fields directly, default the omitted case.
const scope = args?.scope ?? 'libs'
const minPriority = args?.minPriority ?? 'high'
const RANK = { low: 0, medium: 1, high: 2, critical: 3 }
const floor = RANK[minPriority] ?? RANK.high

phase('Pull cards')
// Mechanical discovery — run the rail, read the cards back. Tier the reasoning down.
const { cards } = await agent(
  `Use the assay code rail (\`uv run python -m tools.assay code ...\`) to find every OPEN ` +
  `IDEAS/TASK card under ${scope}/**/.planning/. For each, return its id, title, priority, and file.`,
  { label: 'pull-cards', phase: 'Pull cards', schema: CARDS, effort: 'low' },
)

// Plain JavaScript — keep only the cards at or above the priority floor.
const top = cards.filter(c => (RANK[c.priority] ?? 0) >= floor)
log(`${top.length} of ${cards.length} card(s) are ${minPriority}+`)

if (top.length === 0) {
  return { realized: 0, message: `No open cards under ${scope} are ${minPriority} or above` }
}

const results = await pipeline(
  top,
  // Stage 1 — realize the card in the codebase, following the package's standards.
  card => agent(
    `Realize this planning card in ${scope}, extending the canonical owner per CLAUDE.md.\n` +
    `Card ${card.id} [${card.priority}]: ${card.title}\nSource: ${card.file ?? '(unknown)'}`,
    { label: `realize:${card.id}`, phase: 'Realize' },
  ),
  // Stage 2 — verify the realization, then mark the card done. Adversarial
  // completeness judgment, so tier the reasoning up.
  (_done, card) => agent(
    `Verify the realization of card ${card.id} ("${card.title}") is complete and matches the ` +
    `card's charter. Run the package's owner-scoped proof gate. If complete, remove the done card.`,
    { label: `verify:${card.id}`, phase: 'Verify', schema: VERDICT, effort: 'high' },
  ).then(v => ({ card: card.id, priority: card.priority, ...v })),
)

const realized = results.filter(Boolean).filter(r => r.realized)
return { candidates: top.length, realized: realized.length, results: results.filter(Boolean) }
