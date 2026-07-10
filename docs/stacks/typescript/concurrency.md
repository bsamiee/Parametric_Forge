# [TYPESCRIPT_CONCURRENCY]

Parallel work has a structural owner or it does not exist: every fiber parents to the fiber that forked it, to the `Scope` that admitted it, or — under an audited exemption — to the global scope, so an orphaned computation is unspellable rather than discouraged. Interruption is the third outcome riding `Cause`, never a value in the error channel and never a boolean flag: a deadline is a `timeout` member interrupting the loser, a shield is a masked window whose wait is restored, and compensation attaches through `Effect.onInterrupt` at the owner. Waiting is suspension on a primitive — `Deferred` handshake, `Latch` gate, `STM.check` — never a poll; channels are selected by consumption shape (`Queue` distributes, `PubSub` replicates and replays, `Mailbox` ends); shared cells are selected by invariant span (`Ref` for one cell, `SynchronizedRef` for effectful update, STM for the multi-cell commit, `TReentrantLock` for shared commits against an exclusive sweep); contention is a closed owner matrix spanning keyed, keyless, fungible, windowed, durable, and placed axes; and every fan-out declares its degree. This page owns who runs concurrently and who owns mutable state; the `Exit`/`Cause` fold, the `acquireRelease` bracket, and `Schedule` mechanics are `rails-and-effects.md`'s, channel-to-`Stream` ingress and `SubscriptionRef.changes` consumption are `streams.md`'s, the keyless memo of one computation is `computation.md`'s `Effect.cached` family, the `Persistence`/store provisioning rows are `boundaries.md`'s, and the root assembly that satisfies `Scope` and runtime services is `services-and-layers.md`'s.

## [01]-[PRIMITIVE_CHOOSER]

This table selects the owning primitive for a concurrent effect; when an effect matches several rows the most specific wins, and the ownership rows are read before the coordination rows.

| [INDEX] | [EFFECT_SIGNATURE]                         | [PRIMITIVE]                                   | [REJECTED_FORM]                            |
| :-----: | :----------------------------------------- | :-------------------------------------------- | :----------------------------------------- |
|  [01]   | child rejoins the owner, failure re-raises | `Effect.fork` + `Fiber.join`                  | `Effect.runFork` inside domain flow        |
|  [02]   | child lifetime rides a region              | `Effect.forkScoped`                           | `forkDaemon` plus a hand-tracked kill list |
|  [03]   | one live fiber per key, restart supersedes | `FiberMap.run`                                | a `Map<string, Fiber>` registry            |
|  [04]   | at most one background instance            | `FiberHandle.run`                             | an "already running" boolean flag          |
|  [05]   | homogeneous fan forked from a callback     | `FiberSet.run` / `FiberSet.makeRuntime`       | `Effect.runFork` per event                 |
|  [06]   | commit survives interrupt, wait does not   | `Effect.uninterruptibleMask` + `restore`      | `Effect.uninterruptible` over whole flow   |
|  [07]   | compensation only on interrupt             | `Effect.onInterrupt`                          | `Effect.ensuring` firing on every exit     |
|  [08]   | expiry aborts into the fault family        | `Effect.timeoutFail`                          | a `Date.now()` deadline comparison         |
|  [09]   | expiry settles as a value                  | `Effect.timeoutOption`                        | `Cause.TimeoutException` caught downstream |
|  [10]   | one-shot typed handoff                     | `Deferred`                                    | a polled `Ref` flag                        |
|  [11]   | reusable value-less gate                   | `Effect.makeLatch`                            | a `Deferred` re-made per cycle             |
|  [12]   | each value reaches exactly one taker       | `Queue.bounded`/`sliding`/`dropping`          | a `PubSub` with one subscriber             |
|  [13]   | every subscriber sees every value          | `PubSub` + scoped `subscribe`                 | offers looped over N queues                |
|  [14]   | late subscriber must see the last N        | `PubSub` `{ replay }`                         | a `Ref` snapshot beside the channel        |
|  [15]   | producer must signal done or failure       | `Mailbox`                                     | a poison-pill sentinel on a `Queue`        |
|  [16]   | in-flight bound spanning call sites        | `Effect.makeSemaphore` + `withPermits`        | a counter `Ref` incremented by hand        |
|  [17]   | one permit budget, fair across keys        | `PartitionedSemaphore.make`                   | a semaphore per key — the budget fragments |
|  [18]   | one cell, pure update, atomic report       | `Ref.modify`                                  | `Ref.get` then `Ref.set`                   |
|  [19]   | the update is itself an effect             | `SynchronizedRef.updateEffect`                | a one-permit semaphore around a `Ref`      |
|  [20]   | invariant spans cells or waits on one      | `STM.gen` + `STM.check` + `STM.commit`        | lock ordering over two `Ref`s              |
|  [21]   | shared commits, one exclusive sweep        | `TReentrantLock.withReadLock`/`withWriteLock` | a one-permit gate serializing every reader |
|  [22]   | contention on any of the six axes          | the `[06]`-`[CONTENTION_OWNERS]` matrix       | one `HashMap` doing six jobs               |
|  [23]   | fan-out over a collection                  | `{ concurrency }` on `Effect.forEach`         | the option omitted — silent serialization  |
|  [24]   | first success across redundant lanes       | `Effect.raceAll`                              | both arms settling one `Deferred`          |

## [02]-[FIBER_OWNERSHIP]

A fork is an ownership statement, not a scheduling detail: the parent selected at the fork site decides when the child dies, and the handle member selected at the observation site decides whose failure it becomes. Registries of fibers are owned surfaces, never hand-rolled maps.

[FORK_PARENT]:
- Law: `Effect.fork` parents the child to the forking fiber — the child is interrupted when the parent completes, so lifetime is an inherited fact, never a tracked variable; `Effect.forkScoped` re-parents to the `Scope` in the requirement channel and `Effect.forkIn(scope)` pins an explicit one, so a region rather than a caller ends the fiber; `Effect.forkDaemon` parents to the global scope and is admitted only where the lifetime provably exceeds every scope in the program and the disposition still reaches an observer through a channel — an unobserved daemon is the leak this page exists to prevent, and `Effect.forkAll` fans a collection under one parent decision.
- Law: the handle algebra is disposition-selected: `Fiber.join` re-raises the child's failure inside the owner and is the default rejoin; `Fiber.await` returns the `Exit` and never fails the observer — the supervision read; `Fiber.interrupt` returns only after the child's finalizers ran; `Fiber.interruptFork` returns immediately — the teardown that must not block the owner's hot path. `Fiber.joinAll`/`Fiber.awaitAll`/`Fiber.interruptAll` fold the collection forms.
- Law: `Effect.supervised` reports children to a `Supervisor.track` snapshot, `Effect.awaitAllChildren` holds the owner until transitive children settle, and `Effect.daemonChildren` re-parents every fork inside a region to the global scope — the escape is declared once at the owner, never sprinkled per fork site.
- Reject: `Effect.runFork` inside domain flow — running is the program edge's verb; `forkDaemon` by reflex; a `for` loop of joins where `Fiber.joinAll` folds it.

[HANDLE_REGISTRY]:
- Law: a fiber registry is an owned surface: `FiberHandle` owns the at-most-one slot, `FiberMap` the one-per-key family, `FiberSet` the homogeneous fan — each is `Scope`-bound at `make`, self-evicts on fiber completion, and interrupts every member when the scope closes, so a stale handle and a leaked registry are structurally impossible.
- Law: `run` on a keyed owner supersedes — the previous holder is interrupted before the replacement forks — and `{ onlyIfMissing: true }` flips supersede into dedupe, so restart-versus-join is an option value at one entrypoint, never two registry types; `join` propagates the first member failure into the owner, which makes crash-the-supervisor a one-combinator policy, `{ propagateInterruption: true }` widens that verdict so an externally interrupted member also counts as failure, and `awaitEmpty` is the quiescence read.
- Law: `FiberSet.makeRuntime<R>()` — with the `FiberMap`/`FiberHandle` twins — materializes the registry's fork as a plain function, the sanctioned spelling for a platform callback seam that must fork per event without re-entering the rail; the forks stay owned members, so the seam inherits scope-close interruption instead of leaking runtime fibers.
- Reject: `Map<string, Fiber.Fiber<void, never>>` with hand eviction; an "already running" boolean beside a fork; per-member interrupt loops where closing the owning scope already interrupts the set.

```typescript conceptual
import { Data, Effect, type Exit, Fiber, FiberHandle, FiberMap, type Scope } from "effect"

class SpawnFault extends Data.TaggedError("SpawnFault")<{ readonly key: string }> {}

type Spawned = {
  readonly enroll: (key: string, work: Effect.Effect<void, SpawnFault>) => Effect.Effect<Fiber.RuntimeFiber<void, SpawnFault>>
  readonly pulse: Effect.Effect<Exit.Exit<void, SpawnFault>>
  readonly settle: Effect.Effect<void, SpawnFault>
}

const spawned = (
  feed: Effect.Effect<void, SpawnFault>,
  sweep: Effect.Effect<void, SpawnFault>,
): Effect.Effect<Spawned, never, Scope.Scope> =>
  Effect.gen(function* () {
    const registry = yield* FiberMap.make<string, void, SpawnFault>() // keyed family: scope-bound, self-evicting
    const janitor = yield* FiberHandle.make<void, SpawnFault>()
    const feeder = yield* Effect.forkScoped(feed)                     // region-parented: the Scope, not the caller, ends it
    yield* FiberHandle.run(janitor, { onlyIfMissing: true })(sweep)   // singleton slot: a second run is a no-op, not a twin
    return {
      enroll: (key, work) => FiberMap.run(registry, key, work),       // supersede: the prior holder is interrupted first
      pulse: Fiber.await(feeder),                                     // Exit disposition: observation never fails the observer
      settle: Effect.raceFirst(FiberMap.join(registry), FiberMap.awaitEmpty(registry)).pipe(Effect.ensuring(Fiber.interruptFork(feeder))),  // join settles only on failure — the race fails on the first member, quiesces on empty; teardown never blocks
    }
  })

// --- [EXPORTS] --------------------------------------------------------------------------

export { SpawnFault, spawned }
export type { Spawned }
```

## [03]-[INTERRUPTION_RAIL]

Interruption is the third outcome — distinct from success and from every fault — and it is a rail of its own: shields are windows, deadlines are interruptions, and compensation is declared at the owner.

[SHIELDED_WINDOW]:
- Law: interruption travels `Cause`, never `E` — `Effect.catchAll` cannot see it, no fault case represents it, and a "cancelled" domain fault may be minted only where an `Exit` folds at the boundary, a fold `rails-and-effects.md` owns.
- Law: the shield is a masked window, not a mode: `Effect.uninterruptibleMask((restore) => ...)` keeps the commit shielded while `restore` re-opens the wait, so external interrupts and deadlines land exactly in the window designed to absorb them; a bare `Effect.uninterruptible` over a composed flow is the unbounded shield that silently disables cancellation, and `Effect.interruptible` inside a mask is the same claim made without the mask's discipline.
- Law: `Effect.onInterrupt` attaches interrupt-only compensation at the owner declaration; `Effect.ensuring` fires on every exit and `Effect.onExit` folds the disposition — the exit class the cleanup must see selects the combinator, never a flag inspected inside one catch-all finalizer.
- Reject: a cancelled flag polled in the body; `AbortController` threaded through domain flow — the signal converts once at the platform seam (`boundaries.md`); catching the interrupt to return a value.

[DEADLINE_FAMILY]:
- Law: a deadline interrupts the loser — it is a `timeout` member composed at the owner, never a `Date.now()` comparison or a deadline parameter threaded inward; the expiry disposition selects the member: `Effect.timeout` fails with `Cause.TimeoutException`, `Effect.timeoutFail` mints the domain fault at the seam, `Effect.timeoutOption` settles expiry as `Option.none`, and `Effect.timeoutTo` folds both arms into one carrier in a single declaration.
- Law: an uninterruptible interior outlives its deadline by design — the timeout on a shielded region waits, which is correct and is the reason the shield must be minimal; where the deadline must settle on time regardless, `Effect.disconnect` severs the interior onto its own fiber so the owner's clock is honored while the shielded work finishes in background.
- Reject: `Cause.TimeoutException` caught downstream where `timeoutFail` mints the typed fault at the owner; racing a hand-rolled `Effect.sleep` against work a `timeout` member already owns.

```typescript conceptual
import { Data, type Duration, Effect, type Option } from "effect"

class ExpiredFault extends Data.TaggedError("ExpiredFault")<{ readonly stage: string }> {}

const committed = <A, E, R>(options: {
  readonly claim: Effect.Effect<A, E, R>
  readonly persist: (row: A) => Effect.Effect<void, E, R>
  readonly vacate: Effect.Effect<void, never, R>
  readonly budget: Duration.DurationInput
}): Effect.Effect<A, E | ExpiredFault, R> =>
  Effect.uninterruptibleMask((restore) =>
    restore(
      options.claim.pipe(Effect.timeoutFail({ onTimeout: () => new ExpiredFault({ stage: "<claim>" }), duration: options.budget })),
    ).pipe(
      Effect.onInterrupt(() => options.vacate),                            // interrupt-only compensation for the abandoned wait
      Effect.flatMap((row) => options.persist(row).pipe(Effect.as(row))),  // shielded commit: runs to completion once the claim lands
    ),
  )

const flushed = <A, E, R>(drain: Effect.Effect<A, E, R>, patience: Duration.DurationInput): Effect.Effect<Option.Option<A>, E, R> =>
  drain.pipe(Effect.uninterruptible, Effect.disconnect, Effect.timeoutOption(patience))  // deadline settles on time; the shielded drain finishes in background

// --- [EXPORTS] --------------------------------------------------------------------------

export { ExpiredFault, committed, flushed }
```

## [04]-[COORDINATION_TOPOLOGY]

Fibers coordinate through typed primitives whose topology is fixed at construction: the handshake is one-shot and typed both ways, the channel's consumption shape, capacity policy, and replay window are declared where it is built, and the permit is the only cross-site concurrency bound.

[HANDSHAKE_SIGNAL]:
- Law: a one-shot typed handoff is a `Deferred<A, E>` — `Deferred.await` suspends every taker, `Deferred.succeed`/`Deferred.fail` settle exactly once and report a late settle as a `false` return, never an error; readiness that carries evidence rides the success value, the failing arm is typed, and `Deferred.poll` reads without suspending.
- Law: `Deferred.complete` memoizes one evaluation of its effect across all takers; `Deferred.completeWith` hands each taker the unevaluated effect — per-taker evaluation is a semantic choice made at the settle site, not an optimization accident discovered later.
- Law: a value-less reusable gate is `Effect.makeLatch` — `whenOpen` gates a section, `open` releases every waiter and stays open, `close` re-arms, and `release` pulses the current waiters through without opening, the one-cycle admission `open` otherwise makes permanent; a set-once gate that carries a value is a `Deferred`, never a `Latch` beside a `Ref`.
- Reject: a `Ref` flag polled under `Effect.repeat`; a `Queue` of one sentinel standing for a handshake.

[CHANNEL_SELECT]:
- Law: topology is consumption shape: `Queue` distributes — each value reaches exactly one taker, the work-distribution channel with `take`/`takeAll`/`takeBetween` on the drain side; `PubSub` replicates — every subscriber's scoped `PubSub.subscribe` dequeue sees every `publish`, and unsubscription is the subscriber's scope closing, never a removal call; `Mailbox` (`@experimental`) is the single-consumer channel that ends — `offer`/`end`/`fail` on the producer side, `takeAll`/`takeN` returning `[Chunk, done]` on the consumer side — so producer completion and producer failure arrive typed at the drain seam, never as a sentinel value.
- Law: capacity policy is fixed at construction: `bounded` suspends the producer — backpressure as the default contract; `sliding` drops oldest for freshest-wins feeds; `dropping` refuses newest for first-wins admission; `unbounded` is admitted only with a bound proven at the producer. `{ replay: n }` on any `PubSub` constructor hands a late subscriber the last `n` published values before live delivery — the catch-up window is construction policy, so a `Ref` snapshot maintained beside the channel restates what the channel already replays. `Mailbox.into` runs a producer into the channel — success ends it, failure fails it — collapsing the hand-written match at every producer edge; draining a channel as a pipeline is `streams.md`'s ingress.
- Reject: a `PubSub` with one subscriber standing for a `Queue`; `Queue.shutdown` as a completion signal — it interrupts takers and carries no verdict; a poison-pill value where `Mailbox.end` is the verdict; a replayed `PubSub` standing for durable history — replay is a warm-up window, not a log.

[PERMIT_DISCIPLINE]:
- Law: a concurrency bound spanning call sites is `Effect.makeSemaphore` — `withPermits(k)` brackets acquire and release around the section on success, failure, and interrupt alike; the permit count is a cost model, so a double-weight section takes `withPermits(2)` against the same semaphore rather than a second semaphore per weight class; `withPermitsIfAvailable` is the load-shed arm settling `Option.none` under saturation, and `resize` retunes the bound live.
- Law: `PartitionedSemaphore.make<K>({ permits })` (`@experimental`) shares one permit budget across keyed partitions and serves waiting partitions round-robin — `fair.withPermits(key, n)` brackets exactly like the flat form while a saturated hot key cannot starve quiet keys; both naive alternatives are wrong on the same axis: a semaphore per key fragments the budget, one flat semaphore lets arrival order starve a tenant.
- Reject: a counter `Ref` incremented by hand; bare `take`/`release` pairs where `withPermits` brackets them; a semaphore standing where the bound belongs to one fan-out's `{ concurrency }` option.

```typescript conceptual
import { Array, type Chunk, Data, Deferred, Effect, Mailbox, PartitionedSemaphore, type Scope } from "effect"

class MintFault extends Data.TaggedError("MintFault")<{ readonly at: string }> {}

type Drained = { readonly expected: number; readonly rows: Chunk.Chunk<string>; readonly sealed: boolean }

const _FLOW = { intake: 16, permits: 4, degree: 8 } as const               // one policy row: channel depth, cross-site permit budget, local fan degree

const bridged = (
  claims: ReadonlyArray<readonly [lane: string, key: string]>,
  mint: (key: string) => Effect.Effect<string, MintFault>,
): Effect.Effect<Drained, MintFault, Scope.Scope> =>
  Effect.gen(function* () {
    const box = yield* Mailbox.make<string, MintFault>({ capacity: _FLOW.intake, strategy: "suspend" })  // backpressure declared at construction
    const bound = yield* Deferred.make<number>()
    const fair = yield* PartitionedSemaphore.make<string>({ permits: _FLOW.permits })  // one budget; waiting lanes served round-robin — no hot-lane starvation

    yield* Effect.gen(function* () {
      const admitted = Array.dedupeWith(claims, ([, keyA], [, keyB]) => keyA === keyB) // the plan settles inside the producer fiber
      yield* Deferred.succeed(bound, admitted.length)                      // handshake carries evidence the consumer cannot reconstruct from its own inputs
      yield* Effect.forEach(admitted, ([lane, key]) => fair.withPermits(lane, 1)(mint(key)).pipe(Effect.tap((row) => box.offer(row))), {
        concurrency: _FLOW.degree,                                         // the local fan degree; the permit budget is the cross-site bound
        discard: true,
      })
    }).pipe(
      Mailbox.into(box),                                                   // success ends the channel, failure fails it — no sentinel
      Effect.forkScoped,
    )

    const expected = yield* Deferred.await(bound)                          // suspends until the producer's plan exists — never a polled flag
    const [rows, sealed] = yield* box.takeN(expected)                      // producer failure surfaces here, typed as MintFault
    return { expected, rows, sealed }
  })

// --- [EXPORTS] --------------------------------------------------------------------------

export { MintFault, bridged }
export type { Drained }
```

## [05]-[SHARED_STATE]

Shared mutation is a cell with an owner: the update shape selects the cell, and an invariant that spans cells moves the cells into one transaction rather than adding a lock beside them.

[CELL_SELECT]:
- Law: `Ref` owns one cell under pure update — `Ref.modify` returns the report and commits the update in one atomic step, the take-a-ticket form; `SynchronizedRef.updateEffect`/`modifyEffect` serialize writers whose update is itself an effect; `SubscriptionRef` adds `changes` for observers — the stream is consumed under `streams.md`'s law; one composite immutable value in one `Ref` beats two cells guarded by discipline, because the composite commits as a unit.
- Law: `Ref.get` followed by `Ref.set` is a torn read-modify-write under contention — the pair collapses into `update`/`modify` without exception, and `getAndUpdate`/`updateAndGet` select which side of the transition the caller sees.
- Boundary: per-fiber state — a view inherited at fork and isolated across siblings — is no shared cell: it rides `Context.Reference`, `services-and-layers.md`'s ambient tier, and a shared `Ref` partitioned by fiber identity to fake locality is the named confusion.
- Reject: a one-permit semaphore around a `Ref` where `SynchronizedRef` owns serialization; module-level mutable state; a `let` captured by concurrent closures.

[ATOMIC_COMMIT]:
- Law: an invariant spanning cells is one STM transaction: `TRef`/`TMap`/`TQueue` cells composed in `STM.gen` commit atomically at `STM.commit` — conflicting transactions re-run automatically, so the torn write and the lock-order deadlock are unspellable, and the STM body is pure by type: an effect cannot enter the transaction.
- Law: `STM.check` suspends the transaction until a participating cell changes and the predicate holds — wait-until-condition without a poll loop, with `STM.retry` as the raw suspend beneath it; the predicate closes over values already read in the same transaction, and the re-run re-reads them.
- Law: `TSemaphore.make(permits)` puts the permit itself inside the transaction — `TSemaphore.acquire` composed in `STM.gen` joins the cell updates in one all-or-nothing commit, which no `Effect`-level semaphore can express, and `TSemaphore.withPermits`/`withPermitsScoped` remain the bracketed `Effect`-level forms.
- Law: `TReentrantLock` names shared-versus-exclusive, never who reads — the exclusive side (`withWriteLock`) owns a section that spans multiple commits or a non-STM effect, the shared side (`withReadLock`) brackets the single commits that must not interleave it, `readLock`/`writeLock` are the `Scope`-bound acquisitions, and reentrancy lets a holder re-enter its own lock; a single commit takes the shared side only to be excludable by that section, never for its own atomicity, because a transaction is already atomic alone.
- Reject: two `Ref`s updated in sequence under a shared invariant; lock-ordering discipline where a transaction owns the cells; polling a cell for a threshold `STM.check` suspends on; an exclusive lock over a pure snapshot-then-remove — one `TMap.removeIf` transaction owns that, and the lock is earned by the non-STM effect between the commits.

```typescript conceptual
import { Chunk, Effect, Number, Ref, STM, TMap, TReentrantLock, TRef, TSemaphore } from "effect"

type Claim = readonly [slot: string, weight: number]
type Ledger = { readonly peak: number; readonly admitted: number; readonly swept: number }

const balanced = (
  claims: ReadonlyArray<Claim>,
  ceiling: number,
  work: (slot: string, ticket: number) => Effect.Effect<void>,
  retire: (slots: ReadonlyArray<string>) => Effect.Effect<void>,
): Effect.Effect<Ledger> =>
  Effect.gen(function* () {
    const load = yield* STM.commit(TRef.make(0))
    const crest = yield* STM.commit(TRef.make(0))
    const plan = yield* STM.commit(TMap.empty<string, number>())
    const scans = yield* STM.commit(TSemaphore.make(2))
    const shape = yield* STM.commit(TReentrantLock.make)
    const tickets = yield* Ref.make(0)

    const admit = ([slot, weight]: Claim): Effect.Effect<void> =>
      STM.commit(
        STM.gen(function* () {
          yield* TSemaphore.acquire(scans)                           // permit joins the cell updates in ONE commit — no permit held across a retry
          const held = yield* TRef.get(load)
          yield* STM.check(() => held + weight <= ceiling)           // suspends until a cell changes; the re-run re-reads, never polls
          yield* TRef.set(load, held + weight)
          yield* TRef.update(crest, (peak) => Number.max(peak, held + weight))
          yield* TMap.set(plan, slot, weight)                        // four cells, one commit: a torn write is unspellable
        }),
      ).pipe(TReentrantLock.withReadLock(shape))                     // shared side: single commits hold it together, so the sweep observes a quiescent plan
    const vacate = ([slot, weight]: Claim): Effect.Effect<void> =>
      STM.commit(STM.all([TSemaphore.release(scans), TRef.update(load, (held) => held - weight), TMap.set(plan, slot, 0)])).pipe(
        Effect.asVoid,
        TReentrantLock.withReadLock(shape),
      )

    const leased = (claim: Claim): Effect.Effect<void> =>
      Ref.modify(tickets, (next) => [next, next + 1] as const).pipe( // single cell: the report and the update commit together
        Effect.flatMap((ticket) =>
          Effect.acquireUseRelease(admit(claim), () => work(claim[0], ticket), () => vacate(claim))), // release fires only after admit commits: an ensuring here would vacate an interrupted wait that never acquired
      )

    yield* Effect.forEach(claims, leased, { concurrency: "unbounded", discard: true })  // the ceiling and the permits, not the degree, bound the fan
    const settled = yield* STM.commit(STM.gen(function* () {
      return { peak: yield* TRef.get(crest), admitted: Chunk.size(yield* TMap.toChunk(plan)) }
    })).pipe(TReentrantLock.withReadLock(shape))
    const swept = yield* Effect.gen(function* () {
      const rows = yield* STM.commit(TMap.toChunk(plan))
      const spent = Chunk.toReadonlyArray(Chunk.map(Chunk.filter(rows, ([, weight]) => weight === 0), ([slot]) => slot))
      yield* retire(spent)                                           // the non-STM effect between the commits — the reason this section is a lock, not one removeIf transaction
      yield* STM.commit(STM.forEach(spent, (slot) => TMap.remove(plan, slot)))
      return spent.length
    }).pipe(TReentrantLock.withWriteLock(shape))                     // exclusive side: snapshot, retire, remove as one section — no shared holder re-admits a slot mid-sweep
    return { peak: settled.peak, admitted: settled.admitted, swept }
  })

// --- [EXPORTS] --------------------------------------------------------------------------

export { balanced }
export type { Claim, Ledger }
```

## [06]-[CONTENTION_OWNERS]

Contention is a closed owner matrix: keyed, keyless, fungible, windowed, durable, and placed axes each have exactly one owning surface, and the policy that tunes each owner is a value declared beside it, never arithmetic spread through call sites. `Cache` starts where a key discriminates callers — the keyless memo of one computation is `computation.md`'s `Effect.cached` family, never a one-key cache.

| [INDEX] | [CONTENTION_SIGNATURE]                | [OWNER]                       | [LIFETIME_POLICY]                                               |
| :-----: | :------------------------------------ | :---------------------------- | :-------------------------------------------------------------- |
|  [01]   | keyed value memoized, misses collapse | `Cache.make`                  | `capacity` + `timeToLive`; `makeWith` folds TTL from the `Exit` |
|  [02]   | keyed value surviving restart         | `PersistedCache.make`         | `timeToLive` folds request and `Exit`; `storeId` names the band |
|  [03]   | keyed resource, refcounted holders    | `RcMap.make`                  | `idleTimeToLive` after last release; `capacity` faults typed    |
|  [04]   | keyed resource cache, lookup acquires | `ScopedCache.make`            | `capacity` + `timeToLive`; eviction runs the entry's release    |
|  [05]   | fungible members, checkout and return | `Pool.make`/`makeWithTTL`     | `min`/`max`, `targetUtilization`, TTL anchored by strategy      |
|  [06]   | per-key pool family                   | `KeyedPool.makeWithTTLBy`     | per-key size and TTL rows                                       |
|  [07]   | keyless resource, shared by demand    | `RcRef.make`                  | refcount + `idleTimeToLive`                                     |
|  [08]   | keyless dependency, swapped live      | `ScopedRef.fromAcquire`       | `set` acquires the successor, then releases the displaced       |
|  [09]   | keyless snapshot on a cadence         | `Resource.auto`/`manual`      | `Schedule`-paced or `refresh`-verb renewal                      |
|  [10]   | throughput window, one process        | `RateLimiter.make`            | `limit`/`interval`/`algorithm` policy row                       |
|  [11]   | quota shared across processes         | `RateLimiter` Tag + `consume` | store-backed window; `onExceeded` `"delay"`/`"fail"`            |
|  [12]   | key-to-member placement               | `HashRing.make` + `add`       | weighted ring; membership change re-homes minimally             |

[KEYED_LIFETIME]:
- Law: the keyed axis selects on what the key resolves to — a memoized value, a keyed resource, or a fungible member — and each resolution has exactly one owner: `Cache.make({ capacity, timeToLive, lookup })` memoizes values and collapses concurrent misses on one key into one in-flight lookup — the stampede is structurally impossible, not guarded — and `Cache.makeWith` folds the TTL from the lookup's `Exit`, so a failed lookup lingers seconds while a hit lingers minutes inside one owner.
- Law: keyed resources split by holder discipline: `RcMap.make({ lookup, idleTimeToLive })` refcounts — `RcMap.get` is a scoped acquisition, the resource releases `idleTimeToLive` after the last holder, and the `capacity` variant widens the error channel with `Cause.ExceededCapacityException` so saturation is a typed fault, never a silent drop; `ScopedCache.make` evicts — its `Lookup` runs under the cache's own `Scope`, the entry is a resource whose eviction runs its release, and `get` is itself scoped so a live holder pins the entry.
- Law: fungible members ride `Pool.make({ acquire, size, concurrency, targetUtilization })`, growing to `Pool.makeWithTTL` with `{ min, max, timeToLive, timeToLiveStrategy }` — `Pool.get` is the scoped checkout whose release returns the member, `concurrency` bounds the holders sharing one member, `targetUtilization` sets the load fraction that triggers growth toward `max`, `"creation"` versus `"usage"` anchors the TTL clock — and `KeyedPool.makeWithTTLBy` is the per-key pool family with per-key size and TTL rows.
- Law: staleness policy is member-selected: `refresh` replaces in place with no eviction gap, `invalidate` evicts now, `invalidateAll` drops the population, `Pool.invalidate` retires a broken member for replacement, and `RcMap.invalidate`/`RcMap.touch` evict a keyed resource ahead of its idle clock or re-arm it — verbs ride their owners, never a parallel cache per staleness mode.
- Law: contention evidence is the owner's own read — `cacheStats` carries hits, misses, and size, `entryStats(key)` the per-entry view, `size` and `contains(key)` the live population — so saturation and hit-rate telemetry consume the owner's counters, and a tally `Ref` maintained beside the cache restates evidence the owner already carries.
- Law: the durable row is `PersistedCache.make({ storeId, lookup, timeToLive, inMemoryCapacity, inMemoryTTL })` from `@effect/experimental` — the key is a `Schema.TaggedRequest`-shaped owner satisfying `PrimaryKey` and `Schema.WithResult`, so success and failure both encode through the key's own result schemas and a persisted failure replays typed; `timeToLive(request, exit)` folds both dispositions, the in-memory tier fronts the store, and the `Persistence.ResultPersistence` provisioning rows are `boundaries.md`'s.
- Reject: a `HashMap` plus hand TTL arithmetic; a `Cache` holding connections — values are returned, resources are released; a free-list array with manual checkout; a one-key `Cache` standing where `Effect.cachedWithTTL` owns the memo.

[SINGLETON_SHARE]:
- Law: the keyless axis completes the matrix: `RcRef.make({ acquire, idleTimeToLive })` is the refcounted share — `RcRef.get` is a scoped acquisition, the first holder acquires lazily, the count returning to zero starts the idle clock, and `RcRef.invalidate` forces re-acquisition — demand decides the lifetime, no caller owns it.
- Law: `ScopedRef.fromAcquire(acquire)` is the swap-in-place cell — `get` never fails because the cell always holds a live value, and `set(acquire)` acquires the successor then releases the displaced value's resources only after the swap commits, so consumers never observe a torn dependency; live reconfiguration is a `set`, never a teardown-and-rebuild of the consumers.
- Law: `Resource.manual(acquire)` renews on the explicit `Resource.refresh` verb; `Resource.auto(acquire, policy)` paces renewal on a `Schedule` — the policy paces, it does not retry: the cell stores the acquisition's `Exit`, so a failed first build is typed at every `Resource.get`, while a failed later `refresh` keeps the last good value, surfaces the fault to its caller, and under `auto` ends the renewal loop — resilience composes into the `acquire` itself, never onto the policy.
- Reject: a module-level singleton with a refresh method; a `SynchronizedRef` holding a connection whose release nobody owns; polled re-acquisition where `auto` already paces it.

[THROUGHPUT_WINDOW]:
- Law: a single runtime's throughput bound is a scoped `RateLimiter.make({ limit, interval, algorithm })` owner — `"token-bucket"` smooths calls across the interval and absorbs bursts against accumulated tokens, `"fixed-window"` enforces hard per-interval quotas — and the algorithm is a policy row selected by the provider's contract, not a tuning afterthought; the limiter attaches at the owner declaration so every call site inherits the window.
- Law: cost composes over the limited effect — `limiter(task).pipe(RateLimiter.withCost(n))` retunes the tokens the limiter charges, and a weight class is a pre-composed lane, `Function.compose(limiter, RateLimiter.withCost(n))`, never a second limiter per weight; `withCost` inside the task body prices the call after the tokens were already taken, the silent misfire. Permits bound concurrency, windows bound throughput, and conflating the two is the named selection error.
- Law: the cross-process row is the `@effect/experimental` `RateLimiter` service Tag — `consume({ key, window, limit, algorithm, onExceeded, tokens })` decides per call with a runtime key and `makeWithRateLimiter` lifts the same options row into an effect transformer, the window spans every process sharing the `RateLimiterStore` (the Redis store ships as `RateLimiter/Redis.layerStore`, provisioned at `boundaries.md`'s seam), `onExceeded: "delay"` suspends the caller while `"fail"` surfaces `RateLimitExceeded` carrying `retryAfter`/`limit`/`remaining` evidence a recovery `Schedule` honors; one runtime's egress takes the scoped in-process owner, a fleet's shared quota takes the store-backed service.
- Reject: `Effect.sleep` pacing between calls; a semaphore standing for a rate window; `withCost` inside the limited task; per-call-site limiter construction where one scoped owner is the window.

[SHARD_PLACEMENT]:
- Law: placement precedes contention: `HashRing.make({ baseWeight })` with `add`/`addMany({ weight })` (`@experimental`) owns key-to-member placement over members implementing `PrimaryKey` — `[PrimaryKey.symbol]()` returns the stable identity string — and `HashRing.get(ring, key)` routes a key to its member with minimal re-homing on membership change, `HashRing.getShards(ring, count)` deals a balanced shard family, and `weight` skews share proportionally; the ring selects which owner, then the selected owner's own contention discipline takes over.
- Law: write discipline: `add`/`addMany`/`remove` mutate the ring in place and return it — the ring is build-then-read, so membership change builds a fresh ring and swaps it through the owning cell, never mutates a ring concurrent readers hold; `get`/`getShards` return `undefined` only when no weighted member is enrolled, so the read converts through `Option.fromNullable` at the seam into the typed fault and an unpopulated ring is an admission failure, never a per-read branch.
- Reject: `hash(key) % members.length` — every membership change re-homes everything; a hand-maintained range-to-member map; sharing one ring across fibers while mutating it.

```typescript conceptual
import { Array, Cache, Data, Duration, Effect, Exit, HashRing, Option, PrimaryKey, RateLimiter, RcMap, Resource, Schedule, type Scope } from "effect"

class Member extends Data.Class<{ readonly slot: string; readonly share: number }> implements PrimaryKey.PrimaryKey {
  [PrimaryKey.symbol]() {
    return this.slot
  }
}

class Adrift extends Data.TaggedError("Adrift")<{ readonly key: string }> {}

const _PLANE = {
  verdicts: { capacity: 512, cost: 2, fresh: Duration.minutes(5), faulted: Duration.seconds(20) },
  sessions: { idleTimeToLive: Duration.seconds(45) },
  egress: { limit: 90, interval: Duration.minutes(1), algorithm: "token-bucket" },
  cadence: Duration.seconds(30),
} as const satisfies {
  readonly verdicts: { readonly capacity: number; readonly cost: number; readonly fresh: Duration.Duration; readonly faulted: Duration.Duration }
  readonly sessions: { readonly idleTimeToLive: Duration.Duration }
  readonly egress: RateLimiter.RateLimiter.Options
  readonly cadence: Duration.Duration
}

type Placed<A, E, S> = {
  readonly verdict: (key: string) => Effect.Effect<A, Adrift | E>
  readonly session: (key: string) => Effect.Effect<S, Adrift | E, Scope.Scope>
  readonly rehome: Effect.Effect<void, E>
}

const placed = <A, E, S, R>(
  pull: Effect.Effect<ReadonlyArray<Member>, E, R>,
  mint: (key: string, at: Member) => Effect.Effect<A, E, R>,
  open: (at: Member) => Effect.Effect<S, E, R>,
): Effect.Effect<Placed<A, E, S>, never, Scope.Scope | R> =>
  Effect.gen(function* () {
    const roster = yield* Resource.auto(                               // schedule-paced snapshot: pull arrives resilience-composed — a failed auto-refresh ends the cadence
      pull.pipe(Effect.map((nodes) => Array.reduce(nodes, HashRing.make<Member>(), (ring, node) => HashRing.add(ring, node, { weight: node.share })))),
      Schedule.spaced(_PLANE.cadence),                                 // the ring mutates in place, so every refresh builds a fresh one — readers hold the swapped snapshot
    )
    const limit = yield* RateLimiter.make(_PLANE.egress)
    const sessions = yield* RcMap.make({ lookup: open, ..._PLANE.sessions })
    const home = (key: string): Effect.Effect<Member, Adrift | E> =>
      Resource.get(roster).pipe(
        Effect.flatMap((ring) =>
          Option.match(Option.fromNullable(HashRing.get(ring, key)), { // undefined only with no weighted member enrolled — a typed fault, not a per-read branch
            onNone: () => Effect.fail(new Adrift({ key })),
            onSome: Effect.succeed,
          }),
        ),
      )
    const verdicts = yield* Cache.makeWith({
      capacity: _PLANE.verdicts.capacity,
      lookup: (key: string) => home(key).pipe(Effect.flatMap((at) => limit(mint(key, at)).pipe(RateLimiter.withCost(_PLANE.verdicts.cost)))),  // cost rides the LIMITED effect
      timeToLive: (exit) => (Exit.isSuccess(exit) ? _PLANE.verdicts.fresh : _PLANE.verdicts.faulted),  // faults expire fast, hits linger
    })
    return {
      verdict: (key: string) => verdicts.get(key),                     // concurrent misses on one key collapse to one lookup
      session: (key: string) => home(key).pipe(Effect.flatMap((at) => RcMap.get(sessions, at))),  // placement first, then refcounted acquisition
      rehome: Resource.refresh(roster).pipe(Effect.andThen(verdicts.invalidateAll)),  // membership moved: re-pull now, drop every stale verdict
    }
  })

// --- [EXPORTS] --------------------------------------------------------------------------

export { Adrift, Member, placed }
export type { Placed }
```

## [07]-[DEGREE_AND_RACE]

Fan-out degree and racing are declared decisions on the combinator, never emergent behavior: an unstated degree is a silent serialization, and a race is a statement about which settlement wins and what happens to the loser.

[EXPLICIT_DEGREE]:
- Law: every fan-out declares its degree — `{ concurrency: N | "unbounded" | "inherit" }` on `Effect.forEach`/`Effect.all`; the omitted option executes sequentially, so the absent knob is itself a decision made silently, and `"unbounded"` is a written claim that a downstream owner — semaphore, limiter, pool — carries the real bound.
- Law: `"inherit"` parameterizes the owner: the fan-out reads the fiber's budget and `Effect.withConcurrency` sets it at the boundary — degree becomes configuration one root composes, consumers never re-assert it per call, and a `degree` parameter threaded through signatures re-states what the fiber already carries; `{ discard: true }` drops result assembly when the fan-out is effect-only.
- Reject: `Promise.all` at domain altitude; a fork-per-item loop where `forEach` owns the fan; per-call degree literals where one boundary owns the budget.

[RACE_SELECT]:
- Law: the race member is selected by what settles it: `Effect.race` — first success wins and the loser is interrupted; `Effect.raceAll` — first success across a collection, the hedge over redundant lanes; `Effect.raceFirst` — first completion wins including failure, the fail-fast pairing; `Effect.raceWith` — the general finisher fold whose `onSelfDone`/`onOtherDone` receive the `Exit` and the other fiber, selected when the loser's disposition is itself material.
- Law: losers are interrupted, so a raced effect is admissible only when its teardown is already owned by a bracket or scope — racing un-bracketed acquisition leaks on every losing arm, and the hedge's cost is the loser's finalizers running to completion.
- Reject: `Promise.race` at the seam; a hand-rolled first-wins where both arms settle one `Deferred` — `race` already owns loser interruption; a race against `Effect.sleep` where the deadline family owns expiry.

```typescript conceptual
import { Array, Effect, type Exit, Fiber } from "effect"

const hedged = <A, E, R>(
  lanes: ReadonlyArray<(key: string) => Effect.Effect<A, E, R>>,
  keys: ReadonlyArray<string>,
): Effect.Effect<ReadonlyArray<A>, E, R> =>
  Effect.forEach(keys, (key) => Effect.raceAll(Array.map(lanes, (lane) => lane(key))), { concurrency: "inherit" }) // degree deferred: the fiber's budget decides, no parameter re-states it

const staged = <A, E, R>(
  lanes: ReadonlyArray<(key: string) => Effect.Effect<A, E, R>>,
  keys: ReadonlyArray<string>,
  budget: number,
): Effect.Effect<ReadonlyArray<A>, E, R> =>
  hedged(lanes, keys).pipe(Effect.withConcurrency(budget)) // the boundary owns the budget; the owner stays degree-agnostic

const shadowed = <A, E, R, R2>(
  live: Effect.Effect<A, E, R>,
  probe: Effect.Effect<A, E, R>,
  note: (exit: Exit.Exit<A, E>) => Effect.Effect<void, never, R2>,
): Effect.Effect<A, E, R | R2> =>
  Effect.raceWith(live, probe, {
    onSelfDone: (exit, other) => Fiber.interruptFork(other).pipe(Effect.andThen(exit)), // live wins: the shadow dies without blocking
    onOtherDone: (exit, self) => note(exit).pipe(Effect.andThen(Fiber.join(self))),     // shadow settles first: record it, keep waiting on live
  })

// --- [EXPORTS] --------------------------------------------------------------------------

export { hedged, shadowed, staged }
```
