# Workflow Throughput

Parallelization economics inside one workflow — wall-clock math, concurrency shaping, load balancing, waiting discipline — and the laws governing several workflows in flight at once.

## [01]-[ECONOMICS]

Barrier choice is the one authors get wrong, so make it explicit:

- `pipeline(items, stage1, stage2, …)` is the default for multi-stage work. There is no barrier between stages — item A runs stage 3 while item B is still in stage 1. Wall-clock equals the slowest single item's whole chain, never the sum of the slowest stage at each step.
- `parallel(thunks)` is a barrier: it waits for every task before returning. Reach for it ONLY when a stage genuinely needs the ENTIRE previous result set in hand — dedup across all findings, a merge, a count-based early-exit. "Cleaner code" and "the stages feel separate" are not reasons — a pipeline models separate stages fine, and a barrier wastes every fast item's idle time waiting on the slowest.

Smell test: `await parallel(...)`, then a plain transform (`flat`/`map`/`filter`) with no cross-item dependency, then another `parallel(...)` — that middle transform does not need the barrier; make it a pipeline stage. When in doubt, `pipeline`.

## [02]-[CONCURRENCY]

Runtime queues work beyond its available agent slots. Every open-ended loop carries its own input-derived bound or budget guard.

For a large list of long multi-stage chains, `parallel()` enqueues all N at once and leans on the limiter; a bounded pool holds a true steady state of at most `cap` chains — what heavy multi-minute chains want:

```js conceptual
const pool = async (items, cap, worker) => {
    const out = new Array(items.length);
    let next = 0;
    const run = async () => {
        while (next < items.length) {
            const i = next++;
            out[i] = await worker(items[i], i).catch(() => null); // one throw would reject the whole pool
        }
    };
    await Promise.all(Array.from({ length: Math.min(cap, items.length) }, () => run()));
    return out;
};
const done = (await pool(pages, cap, (p) => processPage(p))).filter(Boolean);
```

Every member of a hand-built fan carries its own `.catch(() => null)`. `agent()` throws — budget exhaustion, the lifetime cap — and `Promise.all` rejects wholesale on the first throw, discarding every sibling that already finished. Null-on-failure is `parallel()`'s guarantee alone (api reference); a slot or pool fan buys it per member or loses a whole wave's completed work to one dead lane.

Slot the agents, never the chains, when chains have uneven stage widths. That pool above holds at most `cap` CHAINS; a chain whose current stage is one agent still occupies a whole slot, and a chain that bursts several concurrent agents in one stage overshoots the cap. Moving the semaphore to the individual `agent()` call — each call acquires a slot, chains launch freely via `Promise.all` — keeps the true in-flight agent count exactly at cap with work-conserving backfill. Its cost is FIFO ordering across stages; throughput is unchanged because the cap stays saturated:

```js conceptual
const makeSlots = (cap) => {
    let active = 0;
    const waiters = [];
    return async (fn) => {
        if (active >= cap) await new Promise((res) => waiters.push(res));
        active++;
        try {
            return await fn();
        } finally {
            active--;
            const next = waiters.shift();
            if (next) next();
        }
    };
};
const slot = makeSlots(cap);
const guard = (p) => p.catch(() => null); // per-member, or one throw discards every finished sibling
await Promise.all(
    batches.map(async (b) => {
        const [a, c] = await Promise.all([guard(slot(() => agent(lensA(b)))), guard(slot(() => agent(lensB(b))))]);
        const impl = await guard(slot(() => agent(implPrompt(b, a, c)))); // chain continues per batch
    }),
);
```

`parallel()` stays correct for a small fixed fan-out that needs a barrier; reach for the pool only at the large-corpus scale `parallel()` serves less well.

## [03]-[UNITS]

Work unit is the dominant lever on total agent count, and it is a design choice. A fixed N-stage cycle run per COARSE unit (a directory) costs `N × directories`; the same cycle per FINE unit (a file) costs `N × files` — often an order of magnitude more. Pick the unit by the coherence boundary the work genuinely needs (does a stage have to see the whole directory at once, or only one file?), and push cross-unit reconciliation into a later fold (patterns reference, the reconcile shape) rather than shrinking the unit to chase completeness.

When per-item outputs are themselves a corpus too large to combine in one prompt, reduce tree-wise — fold the outputs in batches with `agent()`, then fold those partial reduces again, until one result remains — never concatenate every output into a single synthesis call that itself overflows context.

Bounded buckets — balance by WORK, never count, and cap atomicity at the fair share. When heterogeneous clusters must consolidate into at most N agents, two packer defects each recreate the same doubled long pole:

- A count-balanced packer overloads bucket 0: descending count-sort drops the largest connected component into the first empty bucket, then count-parity tops that bucket up while it already holds the largest distinct-file union — an agent's load is the files it must read and reconcile, never how many claims it carries.
- UNBOUNDED cluster atomicity — worse and easier to miss: on an interlinked corpus, union-find by shared file fuses nearly every claim into ONE connected component, and a clusters-never-split packer hands one agent nearly everything while its siblings finish in minutes.

Atomicity is a BUDGET, never an absolute: component-atomic while a cluster fits the fair share (`totalWork / n`); above that, sub-shard the component FILE-atomically — rows sharing a lead file never split, the hard edit-collision floor — and accept the cross-shard seams; the verify or terminal stage owns them. Two concurrent shards of one component may share a secondary page, so shard-carrying prompts edit shared pages with surgical anchored Edits only, re-reading and re-applying on conflict — never a whole-file rewrite. Log per-bucket weights so the long pole is visible, never silent:

```js conceptual
const clusterWork = (c) => {
    const files = new Set();
    for (const r of c) for (const f of r.files ?? []) files.add(f);
    return files.size * 2 + c.length;
};
// Atomicity budget: a component over the fair share sub-shards by lead file — same-lead-file
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

That budget also rules POOL-per-cluster shapes (one agent per atomic cluster under a cap): shard with `cap = ceil(totalWork / POOL_CAP)` before the pool, or the giant component lands on one agent. That heaviest atomic cluster still bounds the wall-clock — irreducible — but weight-greedy stops topping it up. This same law orders an UNPACKED pool: heterogeneous clusters under a cap smaller than the cluster count launch heaviest-first, so the long pole starts in the first wave. Fixed-size `chunk(pages, N)` batches of homogeneous items need none of this — uniform items balance by construction.

## [04]-[DISCIPLINE]

- Label and phase every concurrent call. Set the `phase` option inside `pipeline`/`parallel` stages — concurrent calls otherwise race on the global `phase()` and land in the wrong group. Labels follow a stable grammar (`verify:${file}`, `t${tier}:${id}`): they name agents in `/workflows`, key dry-run `--fixtures`, and identify lanes in a harvest roster; relabeling never invalidates the resume cache.
- No agent idles. A supervised CLI lane stays inside one backgrounded Bash call; the harness re-invokes its wrapper when the process exits, and the wrapper reads the receipt.
- Repeated mechanics are staged artifacts, never prose. Write reused checks, promotions, and validations once as executable scripts; verbal re-derivation makes each lane a fresh failure point.
- `isolation: 'worktree'` costs startup and disk, so it serves only overlapping parallel write scopes; disjoint scopes need none.
- Non-default checkouts isolate through path authority. Mint one absolute root, state it in every lane prompt, derive native products from it, and pin CLI lanes to the same `cwd`.
- Native lanes inherit the parent session's full tool surface, and every tool definition spends the lane's context before its first turn. A heavy native fan-out of mechanical lanes routes through `agentType` pointing at a `.claude/agents/` definition with a minimal `tools:` field (Bash/Read/Grep/Edit for a mechanical lane) so each lane starts lean; Codex lanes inherit the CLI configuration.

## [05]-[CROSS_RUN]

- Concurrent runs coexist freely — each owns its run directory and journal, and the instance-minted scratch (patterns reference, the scratch convention) forks per args set, so even two runs of ONE script over different targets never share a data plane.
- Launch same-script runs serially because concurrent invocations can misdeliver `args`. Give every workflow an early guard — `if (!required) return { skipped: true, reason }` — so a dropped argument becomes an explicit no-op.
- A launch into territory adjacent to a LIVE writer carries the seam law. When a new agent's territory shares a file with an agent still running — or with that agent's uncommitted output — the new agent's prompt names the foreign content FROZEN (never edit, move, or reformat it), sequences the shared file LAST with a mandatory full re-read immediately before the first edit, and restricts that file to surgical Edit operations — one full-file Write clobbers the sibling.
- A sibling's territory breach observed mid-flight is adjudicated at its receipt, never by intervening in a live run.
- Grant permissions before a long parallel run — subagent permission inheritance is the api reference's sandbox law, and one un-granted call stalls the whole fan.
- Host singletons serialize. Agents sharing one external mutable resource — a live app instance, a database, a port — contend invisibly; a narrow real run (api reference) is what surfaces the serialization before the full fan does.
- `budget.spent()` pools across the main loop and every workflow in the turn — parallel runs drain one shared target.
