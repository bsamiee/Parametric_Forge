/**
 * orchestrate-workers — decompose a task into typed units, fan the workers, re-plan from
 * receipts until the planner rules done, then integrate the seams.
 *
 * Demonstrates orchestrator-workers with re-planning: the planner is an agent because
 * decomposition is judgment (a worklist unknowable up front), workers execute only the
 * issued tasks, and each revision is a FULL typed plan built from worker receipts — never
 * worker transcripts, never a diff-shaped patch. A revision cap plus the budget guard
 * bound the loop; the terminal integrator owns whatever spans the workers.
 *
 * Workflow({ name: 'orchestrate-workers',
 *            args: 'migrate libs/python/data off the deprecated codec entrypoints' })
 */

export const meta = {
    name: 'orchestrate-workers',
    description: 'Plan a task into independent typed units, run the workers, re-plan from receipts until done, integrate the seams',
    whenToUse: 'A migration or feature whose unit list only evidence can produce, with follow-on work discovered as units land',
    phases: [{ title: 'Plan' }, { title: 'Work' }, { title: 'Integrate' }],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const MAX_REVISIONS = 3; // hard cap on re-plan rounds — the runaway backstop, never the exit

// --- [INPUTS] --------------------------------------------------------------------------

// Structured args: a plain-text task string, else a safe representative default.
const task = typeof args === 'string' && args.trim() ? args : 'migrate libs/python/data off the deprecated codec entrypoints';

// --- [MODELS] --------------------------------------------------------------------------

// STRICT everywhere: additionalProperties:false + every property required; conditional fields are required-but-empty.
// `done` rules the loop; `tasks` is empty exactly when done is true.
const PLAN = {
    type: 'object',
    additionalProperties: false,
    required: ['done', 'tasks'],
    properties: {
        done: { type: 'boolean' },
        tasks: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['id', 'file', 'instruction'],
                properties: {
                    id: { type: 'string' },
                    file: { type: 'string' }, // the unit's lead file — units are disjoint by file so workers never collide
                    instruction: { type: 'string' },
                },
            },
        },
    },
};

const WORK = {
    type: 'object',
    additionalProperties: false,
    required: ['changed', 'files', 'followOn', 'note'],
    properties: {
        changed: { type: 'boolean' },
        files: { type: 'array', items: { type: 'string' } },
        followOn: { type: 'array', items: { type: 'string' } }, // work this unit exposed but does not own; empty attests the hunt ran
        note: { type: 'string' },
    },
};

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('Plan');
let plan = await agent(
    'Decompose this task into independent units — one per file or module changeable on its own, disjoint lead files so workers never ' +
        'collide. Return the typed task list; done=false.\n\nTASK: ' +
        task,
    { label: 'plan:0', phase: 'Plan', schema: PLAN },
);

const receipts = [];
let rev = 0;
while (!plan?.done && (plan?.tasks ?? []).length && rev < MAX_REVISIONS && (!budget.total || budget.remaining() > 100_000)) {
    rev++;

    phase('Work');
    const wave = (
        await parallel(
            plan.tasks.map(
                (t) => () =>
                    agent(
                        t.instruction +
                            '\n\nUnit file: ' +
                            t.file +
                            '\nResolve every defect you touch at its cause; report follow-on work ' +
                            'you expose but do not own as followOn rows.',
                        { label: `work:${rev}:${t.id}`, phase: 'Work', schema: WORK },
                    ).then((r) => ({
                        id: t.id,
                        file: t.file,
                        ...r,
                    })),
            ),
        )
    ).filter(Boolean);
    receipts.push(...wave);
    log(`revision ${rev}: ${wave.length}/${plan.tasks.length} unit(s) landed, ${wave.flatMap((w) => w.followOn).length} follow-on(s)`);

    // Re-plan from RECEIPTS as data — a full fresh plan each round, follow-ons folded in or ruled out.
    plan = await agent(
        'Revise the plan for the task below from these worker receipts. Issue ONLY remaining or follow-on work as a complete typed task ' +
            'list; emit done=true with empty tasks when nothing remains.\n\nTASK: ' +
            task +
            '\n\nRECEIPTS: ' +
            JSON.stringify(wave),
        { label: `replan:${rev}`, phase: 'Plan', schema: PLAN },
    );
}

if (!receipts.length) return { task, revisions: rev, integrated: false, note: 'planner produced no units' };

// Workers cannot see each other's context — the terminal integrator owns whatever spans them.
phase('Integrate');
const integrated = await agent(
    'These units completed independently for the task below. Resolve every seam between them — shared shapes, naming drift, dangling ' +
        'references — and report what you aligned.\n\nTASK: ' +
        task +
        '\n\nUNITS: ' +
        JSON.stringify(receipts.map((r) => ({ id: r.id, file: r.file, files: r.files }))),
    { label: 'integrate', phase: 'Integrate' },
);

return { task, revisions: rev, units: receipts.length, done: !!plan?.done, integrated };
