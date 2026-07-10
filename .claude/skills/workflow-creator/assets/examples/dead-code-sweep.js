/**
 * dead-code-sweep — remove unreferenced C#/Python/TS symbols round by round until a
 * clean sweep turns up nothing.
 *
 * Demonstrates loop-until-dry: a file::symbol seen-set dedups across rounds, each
 * removal runs in its own worktree (two symbols can collapse into one owner and
 * collide) under a self-reverting proof gate, and a dry-streak plus round cap
 * terminate the loop even as removals expose more dead code underneath.
 *
 * Workflow({ name: 'dead-code-sweep', args: { scope: 'libs/csharp/Rasm' } })
 */

export const meta = {
    name: 'dead-code-sweep',
    description:
        'Sweep a scope for unreferenced C#/Python/TS symbols round by round, removing each under its proof gate, until a clean sweep turns up nothing',
    whenToUse: 'Pruning dead code across the tri-language libs before a release or a large refactor',
    phases: [{ title: 'Find' }, { title: 'Remove', detail: 'one self-reverting agent per dead symbol' }],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const DRY_STREAK = 2; // stop after this many empty rounds in a row
const MAX_ROUNDS = 8; // hard cap so the loop always terminates

// --- [INPUTS] --------------------------------------------------------------------------

// Structured args — read `scope` directly; default to all libs.
const scope = args?.scope ?? 'libs';

// --- [MODELS] --------------------------------------------------------------------------

// STRICT everywhere: additionalProperties:false + every property required at every level; a conditional field is required-but-empty (''), never omitted.
const DEAD = {
    type: 'object',
    additionalProperties: false,
    required: ['items'],
    properties: {
        items: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['file', 'symbol', 'kind'],
                properties: {
                    file: { type: 'string' },
                    symbol: { type: 'string' },
                    kind: { type: 'string', enum: ['type', 'member', 'function', 'import', 'binding'] },
                },
            },
        },
    },
};

const REMOVAL = {
    type: 'object',
    additionalProperties: false,
    required: ['file', 'symbol', 'removed', 'note'],
    properties: {
        file: { type: 'string' },
        symbol: { type: 'string' },
        removed: { type: 'boolean' }, // false = the proof gate failed, edit reverted
        note: { type: 'string' }, // the revert reason; empty on a clean removal
    },
};

// --- [COMPOSITION] ---------------------------------------------------------------------

const seen = new Set(); // file::symbol of every candidate already handled, across rounds
const removed = [];

let emptyRounds = 0;
let round = 0;

while (emptyRounds < DRY_STREAK && round < MAX_ROUNDS) {
    round++;

    phase('Find');
    const { items } = await agent(
        `Round ${round}. Use the assay code rail (\`uv run python -m tools.assay code ...\`) to find ` +
            `unreferenced symbols under ${scope} across libs/csharp, libs/python and libs/typescript: ` +
            `C# internal/private types and members with no call site, Python functions and imports with ` +
            `no use, TS exports and bindings imported nowhere. Skip anything host-bound or wire-facing. ` +
            `Return file, symbol and kind for each.`,
        { label: `find:round-${round}`, phase: 'Find', schema: DEAD, effort: 'low' },
    );

    // Dedup via the seen set: a symbol handled in any earlier round never triggers a second removal.
    const fresh = (items ?? []).filter((it) => {
        const key = `${it.file}::${it.symbol}`;
        return seen.has(key) ? false : (seen.add(key), true);
    });

    if (fresh.length === 0) {
        emptyRounds++;
        log(`Round ${round}: clean (${emptyRounds}/${DRY_STREAK} empty rounds)`);
        continue;
    }

    emptyRounds = 0;
    log(`Round ${round}: ${fresh.length} new dead symbol(s) found`);

    // Worktree per removal: two can collapse into the same canonical owner and collide; each runs the
    // owner's proof gate and self-reverts on failure, so a bad removal cannot land.
    phase('Remove');
    const outcomes = await parallel(
        fresh.map(
            (it) => () =>
                agent(
                    `Remove the unreferenced ${it.kind} "${it.symbol}" from ${it.file}, collapsing ` +
                        `into the canonical owner per CLAUDE.md rather than leaving a gap. Then run that owner's ` +
                        `proof gate (the assay rail for its language). If anything fails, revert the edit and report ` +
                        `removed=false with the reason.`,
                    { label: `remove:${it.symbol}`, phase: 'Remove', schema: REMOVAL, isolation: 'worktree' },
                ),
        ),
    );

    removed.push(...outcomes.filter(Boolean).filter((o) => o.removed));
}

return { scope, rounds: round, removedCount: removed.length, removed };
