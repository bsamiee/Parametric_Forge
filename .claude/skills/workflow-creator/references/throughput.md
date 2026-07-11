# Workflow Throughput

Parallelization economics inside one workflow — wall-clock math, concurrency shaping, load balancing, waiting discipline — and the laws governing several workflows in flight at once.

## [01]-[ECONOMICS]

The barrier decision is the one authors get wrong, so make it explicit:

- `pipeline(items, stage1, stage2, …)` is the default for multi-stage work. There is no barrier between stages — item A runs stage 3 while item B is still in stage 1. Wall-clock equals the slowest single item's whole chain, never the sum of the slowest stage at each step.
- `parallel(thunks)` is a barrier: it waits for every task before returning. Reach for it ONLY when a stage genuinely needs the ENTIRE previous result set in hand — dedup across all findings, a merge, a count-based early-exit. "Cleaner code" and "the stages feel separate" are not reasons — a pipeline models separate stages fine, and a barrier wastes every fast item's idle time waiting on the slowest.

Smell test: `await parallel(...)`, then a plain transform (`flat`/`map`/`filter`) with no cross-item dependency, then another `parallel(...)` — that middle transform does not need the barrier; make it a pipeline stage. When in doubt, `pipeline`.

## [02]-[CONCURRENCY]

The runtime runs up to 16 agents at once (fewer on machines with few CPU cores) and queues the excess — passing 100 thunks to `parallel()` is legal, ~16 run at a time, all 100 finish. The 1000-agent lifetime cap throws; every open-ended loop carries its own counter or budget guard long before it. A run that schedules past 25 agents or projects past 1.5 million tokens raises the advisory large-workflow warning (api reference).

For a large list of long multi-stage chains, `parallel()` enqueues all N at once and leans on the limiter; a bounded pool holds a true steady state of at most `cap` chains — what heavy multi-minute chains want:

```js conceptual
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const pool = async (items, cap, worker) => {
    const out = new Array(items.length);
    let next = 0;
    let gate = Promise.resolve(); // serialized launch gate
    const launch = () => {
        gate = gate.then(() => sleep(1500));
        return gate;
    };
    const run = async () => {
        while (next < items.length) {
            const i = next++;
            await launch();
            out[i] = await worker(items[i], i);
        }
    };
    await Promise.all(Array.from({ length: Math.min(cap, items.length) }, () => run()));
    return out;
};
const done = (await pool(pages, 10, (p) => processPage(p))).filter(Boolean);
```

The `launch()` gate spaces the roll-out: each worker awaits the shared gate before starting a job, so launches sit one stagger interval apart and the pool ramps to `cap` gradually — identically on a fresh run and on a cache-replaying resume. Tune `cap` and the stagger to the work's weight; ~10 concurrent and ~1500 ms suit heavy multi-stage agents.

Slot the agents, never the chains, when chains have uneven stage widths. The pool above holds at most `cap` CHAINS; a chain whose current stage is one agent still occupies a whole slot, and a chain that bursts several concurrent agents in one stage overshoots the cap. Moving the semaphore to the individual `agent()` call — each call acquires a slot, chains launch freely via `Promise.all` — keeps the true in-flight agent count exactly at cap with work-conserving backfill. The cost is FIFO ordering across stages; throughput is unchanged because the cap stays saturated:

```js conceptual
const makeSlots = (cap) => {
    let active = 0;
    let gate = Promise.resolve();
    const waiters = [];
    const stagger = () => {
        gate = gate.then(() => sleep(1500));
        return gate;
    };
    return async (fn) => {
        if (active >= cap) await new Promise((res) => waiters.push(res));
        active++;
        await stagger();
        try {
            return await fn();
        } finally {
            active--;
            const next = waiters.shift();
            if (next) next();
        }
    };
};
const slot = makeSlots(14);
await Promise.all(
    batches.map(async (b) => {
        const [a, c] = await Promise.all([slot(() => agent(lensA(b))), slot(() => agent(lensB(b)))]);
        const impl = await slot(() => agent(implPrompt(b, a, c))); // chain continues per batch
    }),
);
```

`parallel()` stays correct for a small fixed fan-out that needs a barrier; reach for the pool only at the large-corpus scale `parallel()` serves less well.

## [03]-[UNITS]

The work unit is the dominant lever on total agent count, and it is a design choice. A fixed N-stage cycle run per COARSE unit (a directory) costs `N × directories`; the same cycle per FINE unit (a file) costs `N × files` — often an order of magnitude more. Pick the unit by the coherence boundary the work genuinely needs (does a stage have to see the whole directory at once, or only one file?), and push cross-unit reconciliation into a later fold (patterns reference, the reconcile shape) rather than shrinking the unit to chase completeness.

When per-item outputs are themselves a corpus too large to combine in one prompt, reduce tree-wise — fold the outputs in batches with `agent()`, then fold those partial reduces again, until one result remains — never concatenate every output into a single synthesis call that itself overflows context.

Bounded buckets — balance by WORK, never count, and cap atomicity at the fair share. When heterogeneous clusters must consolidate into at most N agents, two packer defects each recreate the same 2x-plus long pole. First, a count-balanced packer overloads bucket 0: descending count-sort drops the largest connected component into the first empty bucket, then count-parity tops that bucket up while it already holds the largest distinct-file union — an agent's load is the files it must read and reconcile, never how many claims it carries. Second — worse and easier to miss — UNBOUNDED cluster atomicity: on an interlinked corpus, union-find by shared file fuses nearly every claim into ONE connected component, and a clusters-never-split packer hands one agent nearly everything while its siblings finish in minutes. Atomicity is a BUDGET, never an absolute: component-atomic while a cluster fits the fair share (`totalWork / n`); above that, sub-shard the component FILE-atomically — rows sharing a lead file never split (the hard edit-collision floor) — and accept the cross-shard seams deliberately, because the verify or terminal stage owns them. Two concurrent shards of one component may share a secondary page, so shard-carrying prompts add: edit pages a sibling may share with surgical anchored Edits only, re-reading and re-applying on an edit conflict — never a whole-file rewrite. Log per-bucket weights so the long pole is visible, never silent:

```js conceptual
const clusterWork = (c) => {
    const files = new Set();
    for (const r of c) for (const f of r.files ?? []) files.add(f);
    return files.size * 2 + c.length;
};
// The atomicity budget: a component over the fair share sub-shards by lead file — same-lead-file
// rows stay together; heaviest groups first-fit into shards under the cap; an oversized
// same-file group stands alone (the floor).
const shardOversized = (clusters, cap) =>
    clusters.flatMap((c) => {
        if (clusterWork(c) <= cap) return [c];
        const byFile = new Map();
        for (const r of c) {
            const k = (r.files ?? [])[0] ?? '~';
            if (!byFile.has(k)) byFile.set(k, []);
            byFile.get(k).push(r);
        }
        const shards = [];
        for (const g of [...byFile.values()].sort((a, b) => clusterWork(b) - clusterWork(a))) {
            const t = shards.find((s) => clusterWork(s.concat(g)) <= cap);
            if (t) t.push(...g);
            else shards.push([...g]);
        }
        return shards;
    });
const packClusters = (clusters, n) => {
    const cap = Math.max(1, Math.ceil(clusters.reduce((w, c) => w + clusterWork(c), 0) / n));
    const shards = shardOversized(clusters, cap);
    if (shards.length <= n) return shards; // one agent per shard — balanced by construction
    const buckets = Array.from({ length: n }, () => ({ work: 0, rows: [] }));
    for (const c of shards.slice().sort((a, b) => clusterWork(b) - clusterWork(a))) {
        let mi = 0;
        for (let i = 1; i < n; i++) if (buckets[i].work < buckets[mi].work) mi = i;
        buckets[mi].rows.push(...c);
        buckets[mi].work += clusterWork(c);
    }
    return buckets.filter((b) => b.rows.length).map((b) => b.rows);
};
const buckets = packClusters(clusters, RECON_CAP);
log('bucket work [' + buckets.map(clusterWork).join(', ') + ']'); // no silent long pole
```

The same budget applies to POOL-per-cluster shapes (one agent per atomic cluster under a concurrency cap): shard with `cap = ceil(totalWork / POOL_CAP)` before the pool, or the giant component still lands on one agent. The heaviest atomic cluster still bounds the wall-clock — irreducible — but weight-greedy stops topping it up. The same law orders an UNPACKED pool: heterogeneous clusters under a cap smaller than the cluster count launch heaviest-first, so the long pole starts in the first wave instead of extending the tail. Fixed-size `chunk(pages, N)` batches of homogeneous items need none of this — uniform items balance by construction.

## [04]-[DISCIPLINE]

- Label and phase every concurrent call. Set the `phase` option inside `pipeline`/`parallel` stages — concurrent calls otherwise race on the global `phase()` and land in the wrong group. Labels follow a stable grammar (`verify:${file}`, `t${tier}:${id}`): they name agents in `/workflows`, key dry-run `--fixtures`, and identify lanes in a harvest roster; relabeling never invalidates the resume cache.
- No agent idles — a live blocking call is the only legal wait. An agent waiting INSIDE one running tool call (a blocking `codex` MCP call, a long build in one Bash call) is working; an agent waiting BETWEEN calls on out-of-band state (a detached process, another lane, a file appearing) is a design error — background tasks never notify a workflow subagent, and idle no-op calls trip no-progress enforcement into a forced FALSE return; `stallMs` does not license idling.
- A wait no single call can hold restructures as: the agent returns a receipt → the orchestrator holds time (`await new Promise(r => setTimeout(r, ms))` — the orchestrator's one clock) → a fresh short-lived agent runs the next check round.
- Repeated mechanics are staged artifacts, never prose. Any step executed more than once across rounds or lanes (checks, promotions, validations) is written ONCE as an executable script and executed verbatim thereafter. Each fresh agent re-deriving mechanics from prose is an independent chance to botch them; across N rounds a botch is guaranteed — a mis-expanded pgrep pattern silently declares live lanes dead.
- `stallMs` is a stall override, never a wait license: raise it for a legitimately slow single agent (a long build inside one call), never to let an agent poll.
- `isolation: 'worktree'` costs ~200-500 ms plus disk per agent. Use it only when parallel agents mutate files and otherwise collide; disjoint write scopes make it unnecessary.
- Native lanes inherit the parent session's FULL tool + MCP surface, and every tool definition spends the lane's context before its first turn. A heavy native fan-out of mechanical lanes routes through `agentType` pointing at a `.claude/agents/` definition with a minimal `tools:` field (Bash/Read/Grep/Edit for a mechanical lane) so each lane starts lean; codex lanes already solve this through the codex skill's graded MCP selection.

## [05]-[CROSS_RUN]

- Concurrent runs of DIFFERENT scripts coexist freely — each owns its run directory, journal, and scratch namespace.
- Launch same-script runs one call at a time. Three parallel `Workflow` invocations of one scriptPath in a single batch misdeliver `args`: two runs receive them, the third receives empty `args` and skips on its own validation. Launch same-scriptPath runs sequentially, and give every workflow an early guard — `if (!required) return { skipped: true, reason }` — so the failure mode is a 6 ms no-op instead of a silent mis-run.
- A launch into territory adjacent to a LIVE writer carries the seam law. When a new agent's territory shares a file with an agent still running — or with that agent's uncommitted output — the new agent's prompt names the foreign content FROZEN (never edit, move, or reformat it), sequences the shared file LAST with a mandatory full re-read immediately before the first edit, and restricts that file to surgical Edit operations — one full-file Write clobbers the sibling.
- A sibling's territory breach observed mid-flight is adjudicated at its receipt, never by intervening in a live run.
- Grant permissions before a long parallel run. Subagents run in `acceptEdits` mode and inherit the session tool allowlist; a non-allowlisted shell, web, or MCP call surfaces a mid-run permission prompt and stalls the run until answered.
- Host singletons serialize. Agents sharing one external mutable resource — a live app instance, a database, a port — contend invisibly; a narrow real run (api reference) is what surfaces the serialization before the full fan does.
- `budget.spent()` pools across the main loop and every workflow in the turn — parallel runs drain one shared target. Codex lanes are invisible to it; budget-gated loops meter only their Claude lanes.
