# [TYPESCRIPT_STREAMS]

Dataflow earns a `Stream` at exactly three signals: the source is unbounded or arrives over time, the consumer must observe elements before the source ends, or a window, backpressure bound, or resource lifetime shapes the flow. `Stream<A, E, R>` is the multi-valued `Effect` — the same typed error channel, the same requirement channel, chunked pull underneath — so a pipeline is one declaration whose state, windows, fan geometry, ingress policy, and batch collapse all attach as typed values on the owner, and the moment none of the three signals holds, the carrier is refused: bounded pure data folds without one, bounded effectful data traverses the rail.

Six siblings own material this page composes as settled: the `Effect` carrier algebra and `Schedule` policy values are `rails-and-effects.md`'s, `Queue`/`PubSub` mechanics and fiber ownership are `concurrency.md`'s, `Chunk` and the collection algebra are `values.md`'s, edge decode is `boundaries.md`'s, the Mealy step's shape is `computation.md`'s, and overload seams with `Match` terminals are `surfaces-and-dispatch.md`'s. What remains is this page's algebra — the carrier discriminant and its source lift, the accumulator ladder, window policy, fan geometry, the scoped ingress bridge, and the request resolver that collapses N+1 — and its one collapse is uniform: hand-rolled cursor pumps, timers, counters, buffers, tag maps, reconnect loops, and dedup caches dissolve into the declared operator that already owns the geometry.

## [01]-[DATAFLOW_CHOOSER]

A dataflow shape selects the form that owns it; the most specific shape wins.

| [INDEX] | [DATAFLOW]                            | [OWNING_FORM]                                         | [REJECTED_FORM]                         |
| :-----: | :------------------------------------ | :---------------------------------------------------- | :-------------------------------------- |
|  [01]   | bounded pure reduction, admitted data | `Chunk.reduce` fold, no carrier                       | a `Stream` over in-memory data          |
|  [02]   | bounded collection, effect/element    | `Effect.forEach` with explicit `{ concurrency }`      | hand fiber loop; stream ceremony        |
|  [03]   | unbounded, incremental, or scoped     | `Stream` pipeline into one `run*` terminal            | whole-feed materialization              |
|  [04]   | cursor-paged provider read            | `Stream.paginateChunkEffect`                          | an offset pump materializing all pages  |
|  [05]   | point read repeated on a cadence      | `Stream.repeatEffectWithSchedule`                     | a sleep loop pushing into a queue       |
|  [06]   | element-to-element state              | `Stream.mapAccum` Mealy step                          | `Ref` mutated inside `map`              |
|  [07]   | running trace of an accumulator       | `Stream.scan`, seed emitted first                     | a fold that swallows intermediates      |
|  [08]   | neighbor access or fixed lookback     | `Stream.zipWithPrevious` / `Stream.sliding`           | a hand Mealy carrying the prior element |
|  [09]   | consecutive-repeat suppression        | `Stream.changes` / `Stream.changesWith`               | a `last` cell compared inside `filter`  |
|  [10]   | count-or-latency window               | `Stream.groupedWithin(width, patience)`               | timer fiber plus mutable buffer         |
|  [11]   | budget-closed, cadence-flushed batch  | `Stream.aggregateWithin` + `Sink.foldWeighted`        | count windows over uneven payloads      |
|  [12]   | static N consumers of one source      | `Stream.broadcast(n, lag)` scoped tuple               | re-running the source per consumer      |
|  [13]   | late or dynamic consumers, one source | `Stream.share` replay window                          | re-plumbed `broadcast` per subscriber   |
|  [14]   | per-key partitioned processing        | `Stream.groupByKey` + `GroupBy.evaluate`              | keyed map of arrays, then re-stream     |
|  [15]   | heterogeneous source union            | `Stream.mergeWithTag` derived tagged merge            | hand-tagged `map` before `merge`        |
|  [16]   | keyed alignment of two sorted feeds   | `Stream.zipAllSortedByKeyWith`                        | materialize both sides and join         |
|  [17]   | callback or queue ingress             | `Stream.asyncScoped` / `Stream.fromQueue`             | listener pushing into an outer array    |
|  [18]   | stalled or failing long-lived source  | `Stream.timeoutFail` + `Stream.retry`                 | a hand reconnect loop around the source |
|  [19]   | pipeline feeding channel consumers    | `Stream.toQueue` / `Stream.toPubSub` `Take` handoff   | `runForEach` offers, end hand-signaled  |
|  [20]   | N identical lookups in one flow       | `Request.TaggedClass` + `RequestResolver.makeBatched` | per-element query — the N+1             |
|  [21]   | batch collapse, unrelated fibers      | `RequestResolver.dataLoader` wall-clock window        | same-traversal proximity as the window  |

## [02]-[PIPELINE_SELECTION]

Three discriminants select the carrier — boundedness, effectfulness, incrementality — and the selection is a memory-and-latency contract, not a style: a `Stream` holds a bounded working set over an unbounded source, an `Effect.forEach` holds the whole collection and its results, a pure fold holds one accumulator. One entrypoint owns the modalities the concept genuinely serves, discriminating on the input value.

[CARRIER_SELECT]:
- Law: bounded plus pure folds without a carrier — `Chunk.reduce` over the admitted collection; bounded plus effectful traverses the rail — `Effect.forEach` with the degree explicit; unbounded, incremental, windowed, or resource-scoped dataflow is a `Stream`, the only form whose consumption is chunked pull with backpressure.
- Law: `Stream<A, E, R>` shares the rail's channels — faults are tagged values in `E`, capability rides `R` — and returns to the rail only at a terminal: `Stream.runFold` for one value, `Stream.run(sink)` for a composed consumer, `Stream.runDrain` for effects-only flow, `Stream.runForEach` for a per-element effect, and `Stream.runCollect` only at a tail already proven bounded, because it materializes the whole remainder.
- Law: one entrypoint owns batch and feed — overload signatures discriminate `Chunk` from `Stream` on the input value and conditionally return the value or the rail; seed and step are shared declarations, so the modalities cannot drift, and the overload set with its statement seam is `surfaces-and-dispatch.md`'s settled form.
- Reject: `Stream.fromIterable` wrapped around in-memory data to fold it; `Stream.runCollect` on an unbounded source; a `digestChunk`/`digestStream` twin pair; an array pushed inside `runForEach` — the fold owns accumulation.
- Boundary: `Chunk` algebra is `values.md`'s; `Effect.forEach` degrees and fiber ownership are `concurrency.md`'s — this page owns the selection between them and everything the `Stream` branch opens.

[SOURCE_LIFT]:
- Law: a cursor-paged provider lifts through `Stream.paginateChunkEffect(start, turn)` — `turn` returns `readonly [Chunk<A>, Option<Cursor>]`, the page emits before the cursor decides continuation, so the final page flows and `Option.none()` closes the feed; emission runs one step past the state, the contract `Stream.unfoldChunkEffect` cannot state, and `Stream.paginateEffect` is the single-value form.
- Law: a point read becomes a feed through `Stream.repeatEffectWithSchedule(read, policy)` — cadence is a composed `Schedule` value consumed as policy, never a sleep loop — and the poll pairs with the adjacency dedup below so downstream consumes transitions, not samples.
- Law: a long-lived feed survives its faults by re-registration — `Stream.retry(policy)` re-runs the entire stream through its acquires on each fault and resets the schedule once an element flows again, so backoff never compounds across outages — and `Stream.timeoutFail(fault, gap)` converts a stalled pull into the typed fault the policy consumes; the restart re-emits from wherever the source starts, so the resume coordinate lives in the source's own state — the cursor, the poll's high-water mark — never in a downstream dedup set.
- Reject: an offset `while` pump; `Stream.fromIterable` around a fully fetched result; a recursive effect pushing into a `Queue` as a hand-rolled feed — the constructor family already owns registration, cadence, and termination.

```typescript conceptual
import { Chunk, type Duration, type Effect, Number, type Option, Schedule, Stream } from "effect";

type Reading = { readonly key: string; readonly value: number };
type Digest = { readonly count: number; readonly total: number; readonly high: number };

const _SEED: Digest = { count: 0, total: 0, high: -Infinity };

const _folded = (digest: Digest, reading: Reading): Digest => ({
    count: digest.count + 1,
    total: digest.total + reading.value,
    high: Number.max(digest.high, reading.value),
});

function digest(readings: Chunk.Chunk<Reading>): Digest;
function digest<E, R>(readings: Stream.Stream<Reading, E, R>): Effect.Effect<Digest, E, R>;
function digest<E, R>(readings: Chunk.Chunk<Reading> | Stream.Stream<Reading, E, R>): Digest | Effect.Effect<Digest, E, R> {
    return Chunk.isChunk(readings) ? Chunk.reduce(readings, _SEED, _folded) : Stream.runFold(readings, _SEED, _folded);
}

const harvested = <Cursor, E, R>(
    start: Cursor,
    turn: (cursor: Cursor) => Effect.Effect<readonly [Chunk.Chunk<Reading>, Option.Option<Cursor>], E, R>,
): Effect.Effect<Digest, E, R> => digest(Stream.paginateChunkEffect(start, turn));

const tracked = <E, R>(probe: Effect.Effect<Reading, E, R>, cadence: Duration.DurationInput): Stream.Stream<Reading, E, R> =>
    Stream.repeatEffectWithSchedule(probe, Schedule.spaced(cadence)).pipe(Stream.changesWith((prior, next) => prior.value === next.value));

// --- [EXPORTS] --------------------------------------------------------------------------

export { digest, harvested, tracked };
export type { Digest, Reading };
```

## [03]-[STATEFUL_TRANSFORM]

State that threads element-to-element lives inside the pipeline as a fold accumulator, never beside it in a cell — and the ladder is derived-first: an adjacency operator states the common shapes, the Mealy machine owns what the family cannot spell. Either way the accumulator is an immutable value the step consumes and reconstructs, so the pipeline's state is recoverable from its declaration and invisible to every other fiber by construction.

[DERIVED_ADJACENCY]:
- Law: element-adjacent state has derived owners — `Stream.zipWithPrevious` emits `[Option<A>, A]` with `Option` carrying the first element's absent predecessor, `Stream.zipWithPreviousAndNext` adds lookahead, `Stream.sliding(width)` and `Stream.slidingSize(width, step)` emit `Chunk` windows — so a `mapAccum` whose entire state is the prior element restates an operator.
- Law: `Stream.zipWithIndex` stamps position and `Stream.groupAdjacentBy(f)` chunks consecutive same-key runs as `[key, NonEmptyChunk<A>]` in constant memory — a `mapAccum` whose whole state is a counter restates the first, and `groupByKey` reached for an adjacency question pays a full keyed re-partition for the second.
- Law: `Stream.changes` suppresses consecutive repeats through `Equal.equals` — structural only for `Data`-constructed elements, reference identity for plain records — so a plain-record feed states its equivalence explicitly with `Stream.changesWith(equivalence)`.
- Reject: a `last` cell compared inside `filter`; indexing a materialized array to reach a neighbor; dedup through a `HashSet` of everything seen — `changes` is consecutive suppression, a full-history set is unbounded memory.

[MEALY_ACCUM]:
- Law: state the adjacency family cannot spell — keyed spaces, composite accumulators, output decoupled from carried state — is `Stream.mapAccum(seed, (state, element) => [state, output])`, the Mealy machine: the state never travels downstream, and a whole key space rides one immutable accumulator (`HashMap` in, `HashMap` out), so per-key memory is a fold fact, never a cell registry.
- Law: `Stream.scan(seed, step)` when every intermediate accumulator is itself the output — the running trace; it emits the seed first, so a consumer that must not see the origin states `Stream.drop(1)` at the pipe, never a patched step.
- Law: `Stream.mapAccumEffect` and `Stream.scanEffect` lift the same step onto the rail when it reads capability or fails — state threading is unchanged; the signature move is `readonly [S, A2]` becoming `Effect<readonly [S, A2], E2, R2>`.
- Reject: a `Ref` mutated inside `Stream.map` or `Stream.tap` — state the pipeline cannot see; `Stream.runFold` where downstream still consumes — the fold terminates, the scan keeps flowing; an outer `let` written from `tap`.
- Boundary: cross-fiber shared state is `concurrency.md`'s `Ref`/`STM`; the accumulator here is pipeline-local and single-fiber by construction, so reaching for a cell inside a pipeline marks state that belongs to the fold.
- Boundary: the Mealy step's `(state, element) => [state, output]` shape is `computation.md`'s law — this page owns its lift into the stream and everything the carrier adds.

```typescript conceptual
import { HashMap, Number, Option, Stream } from "effect";

type Sample = { readonly key: string; readonly value: number };
type Motion = { readonly key: string; readonly shift: number; readonly arrival: boolean };

const _advanced = (last: HashMap.HashMap<string, number>, sample: Sample): readonly [HashMap.HashMap<string, number>, Motion] => [
    HashMap.set(last, sample.key, sample.value),
    Option.match(HashMap.get(last, sample.key), {
        // the output reads the pre-write map: shift measures against the prior value, the miss is the arrival
        onNone: (): Motion => ({ key: sample.key, shift: 0, arrival: true }),
        onSome: (prior): Motion => ({ key: sample.key, shift: sample.value - prior, arrival: false }),
    }),
];

const motions = <E, R>(samples: Stream.Stream<Sample, E, R>): Stream.Stream<Motion, E, R> =>
    Stream.mapAccum(samples, HashMap.empty<string, number>(), _advanced);

const crest = <E, R>(samples: Stream.Stream<Sample, E, R>): Stream.Stream<number, E, R> =>
    Stream.scan(samples, -Infinity, (high, sample) => Number.max(high, sample.value)).pipe(
        Stream.drop(1), // the seed emits first: dropping it at the pipe aligns one peak per sample, never a patched step
    );

// --- [EXPORTS] --------------------------------------------------------------------------

export { crest, motions };
export type { Motion, Sample };
```

## [04]-[WINDOWING]

A window is a pair of policy values — a `Sink` deciding what closes a batch, a `Schedule` deciding when one may emit — so every batching behavior is declared at the pipe and none is a timer fiber racing a mutable buffer.

[WINDOW_POLICY]:
- Law: `Stream.groupedWithin(width, patience)` owns count-or-latency windows — whichever bound trips first flushes, so a lull never strands a partial page; bare `Stream.grouped(width)` is legal only where latency is provably irrelevant, because a slowed source stalls its tail forever.
- Law: `Stream.aggregateWithin(sink, schedule)` separates the two policies — the sink closes a batch by its own algebra, the schedule paces emission — and divides the pipeline into two asynchronous islands: upstream feeds the sink on one fiber while downstream pulls aggregates on another, so aggregation continues between pulls.
- Law: `Stream.transduce(sink)` re-applies the sink with no schedule — pure structural aggregation; `Stream.rechunk(n)` when only chunk size changes, not meaning.
- Law: a prefix with its own consumer is `Stream.peel(sink)` — a scoped `Effect` settling the sink's value and returning the remainder as a live stream, so a header-then-body feed is one declaration with nothing re-read; `Stream.branchAfter(n, f)` routes the remainder by the first `n` elements when the prefix is a routing decision, not a value.
- Law: cadence arrives as a composed `Schedule` value — `Schedule.fixed` for wall-clock cadence, `Schedule.spaced` for pause-after-emit; the policy algebra is `rails-and-effects.md`'s, consumed here as a value.

[WEIGHTED_SINK]:
- Law: `Sink.foldWeighted({ initial, maxCost, cost, body })` closes a window by budget — `cost` prices each element against the running state, so byte, row, and unit budgets replace count guesses over uneven payloads; the fold state is the batch itself and the budget is a parameter, never a constant inside the body.
- Law: `Sink.foldWeightedDecompose` when one element can exceed the budget — `decompose` splits it into simpler elements instead of emitting an over-budget batch, and an indivisible element crosses the threshold by the sink's own stated fallback.
- Use: `Sink.fold`/`Sink.foldUntil`/`Sink.collectAllN` for predicate and count closure; `Sink.zip` and `Sink.race` keep composed consumers one `Sink` value so the terminal `Stream.run(sink)` receives one consumer.
- Reject: count-only batching of variable-size payloads; a byte counter threaded through `mapAccum` to fake a weighted window; a flush raced against a hand timer.

```typescript conceptual
import { Chunk, type Duration, Function, Schedule, Sink, Stream } from "effect";

type Entry = { readonly key: string; readonly payload: string };
type Parcel = { readonly entries: Chunk.Chunk<Entry>; readonly weight: number };
type Window = { readonly budget: number; readonly cadence: Duration.DurationInput };

const _EMPTY: Parcel = { entries: Chunk.empty(), weight: 0 };

const _packed = (budget: number): Sink.Sink<Parcel, Entry, Entry> =>
    Sink.foldWeighted({
        initial: _EMPTY,
        maxCost: budget,
        cost: (_, entry) => entry.payload.length,
        body: (parcel, entry) => ({
            entries: Chunk.append(parcel.entries, entry),
            weight: parcel.weight + entry.payload.length,
        }),
    });

const parcels: {
    (window: Window): <E, R>(entries: Stream.Stream<Entry, E, R>) => Stream.Stream<Parcel, E, R>;
    <E, R>(entries: Stream.Stream<Entry, E, R>, window: Window): Stream.Stream<Parcel, E, R>;
} = Function.dual(
    2,
    <E, R>(entries: Stream.Stream<Entry, E, R>, window: Window): Stream.Stream<Parcel, E, R> =>
        Stream.aggregateWithin(entries, _packed(window.budget), Schedule.fixed(window.cadence)), // the window is one policy value: a third axis lands as a field, never a new parameter
);

// --- [EXPORTS] --------------------------------------------------------------------------

export { parcels };
export type { Entry, Parcel, Window };
```

## [05]-[FAN_GEOMETRY]

Fan-out multiplies consumers of one pull; fan-in funds one consumer from many sources. Both are declared geometry — scoped effects, derived unions, keyed alignment — so a source never re-runs per consumer and a merge never hand-tags what the operator derives.

[FAN_OUT]:
- Law: a statically known consumer count is `Stream.broadcast(n, lag)` — a scoped `Effect` yielding a `TupleOf<N, Stream>` that destructures into named branches, with `lag` also taking `{ capacity, strategy, replay }` — `[06]`'s buffer vocabulary plus the newcomer window; the driver advances at most the lag ahead of the slowest consumer, so branches are consumed concurrently — draining one branch to completion before starting the next deadlocks the driver at the lag bound.
- Law: dynamically attaching consumers are `Stream.share({ capacity, replay, idleTimeToLive, strategy })` — one upstream run shared by late subscribers under the same buffer vocabulary, `replay` handing newcomers the recent window, `idleTimeToLive` keeping the upstream warm across a subscriber gap.
- Law: keyed partition is `Stream.groupByKey(f, { bufferSize })` piped to `GroupBy.evaluate((key, run) => ...)` — every key gets its own sub-stream, groups run in parallel and merge nondeterministically, and an unconsumed group deadlocks the producer at `bufferSize`: evaluate every group, narrow with `GroupBy.filter`, or cap with `GroupBy.first(n)`.
- Law: when the per-key work is one effect per element, `Stream.mapEffect(f, { key, bufferSize })` is the same partition fused — per-key order preserved, keys concurrent — so the sub-stream machinery is earned only by a group that needs its own pipeline.
- Law: a two-way predicate split is `Stream.partition(predicate, { bufferSize })` — a scoped pair `[excluded, satisfying]`, refinement-aware so the satisfying branch narrows its element type.
- Reject: running the source once per consumer; folding into a keyed map of arrays and re-streaming per key; `broadcast` where consumers attach after the fact — `share` owns that lifetime.

[FAN_IN]:
- Law: same-shape sources merge with `Stream.merge(that, { haltStrategy })` — termination is the explicit policy `"left" | "right" | "both" | "either"`, never the accidental default; many sources are `Stream.mergeAll(streams, { concurrency })`, and redundant equivalent feeds are `Stream.raceAll(...feeds)` — the first to emit wins and the losers are interrupted, so a raced source must already own its teardown.
- Law: different-shape sources merge with `Stream.mergeWithTag(record, { concurrency })` — the emitted tagged union derives from the record's keys, so the record is the vocabulary table, a hand-written union or pre-merge `map`-tagging restates what the operator computes, and dispatch lands as one `Match.valueTags` record.
- Law: two feeds sorted by distinct keys align with `Stream.zipAllSortedByKeyWith({ other, onSelf, onOther, onBoth, order })` — a constant-space keyed join total over all three presence cases; the caller owes distinct sorted keys, the operator's named precondition, and `Stream.zipLatest` pairs by arrival time, not key — choosing it for keyed data is the named confusion.
- Boundary: `Match.valueTags` mechanics are `surfaces-and-dispatch.md`'s; `Order` instances are `values.md`'s — both compose here as values.

```typescript conceptual
import { type Duration, Effect, GroupBy, Match, Order, type Scope, Stream } from "effect";

type Sample = { readonly key: string; readonly value: number };
type Pulse = { readonly key: string; readonly beat: number };
type Ledger = { readonly observed: number; readonly expected: number };

const _KEYED = { bufferSize: 64 } as const satisfies { bufferSize: number };

const totals = <E, R>(samples: Stream.Stream<Sample, E, R>): Stream.Stream<readonly [string, number], E, R> =>
    samples.pipe(
        Stream.groupByKey((sample) => sample.key, _KEYED),
        GroupBy.evaluate((key, run) =>
            run.pipe(
                Stream.scan(0, (total, sample) => total + sample.value),
                Stream.map((total) => [key, total] as const),
            ),
        ),
    );

const staged = <E>(
    samples: Stream.Stream<Sample, E>,
    drain: {
        readonly live: (sample: Sample) => Effect.Effect<void>;
        readonly audit: (total: readonly [string, number]) => Effect.Effect<void>;
    },
    lag: number,
): Effect.Effect<void, E, Scope.Scope> =>
    Effect.gen(function* () {
        const [hot, keyed] = yield* Stream.broadcast(samples, 2, lag);
        yield* Effect.all(
            [Stream.runForEach(hot, drain.live), Stream.runForEach(totals(keyed), drain.audit)],
            { concurrency: "unbounded", discard: true }, // both branches drain concurrently: finishing one before starting the next parks the driver at the lag bound
        );
    });

const published = <E>(
    samples: Stream.Stream<Sample, E>,
    window: { readonly depth: number; readonly linger: Duration.DurationInput },
): Effect.Effect<Stream.Stream<readonly [string, number], E>, never, Scope.Scope> =>
    Stream.share(totals(samples), { capacity: window.depth, replay: 1, idleTimeToLive: window.linger });

const fused = <E1, R1, E2, R2>(
    samples: Stream.Stream<Sample, E1, R1>,
    pulses: Stream.Stream<Pulse, E2, R2>,
): Stream.Stream<number, E1 | E2, R1 | R2> =>
    Stream.map(
        Stream.mergeWithTag({ pulse: pulses, sample: samples }, { concurrency: "unbounded" }),
        Match.valueTags({
            pulse: ({ value }) => value.beat,
            sample: ({ value }) => value.value,
        }),
    );

const reconciled = <E1, R1, E2, R2>(
    observed: Stream.Stream<readonly [string, number], E1, R1>,
    expected: Stream.Stream<readonly [string, number], E2, R2>,
): Stream.Stream<[string, Ledger], E1 | E2, R1 | R2> =>
    Stream.zipAllSortedByKeyWith(observed, {
        other: expected,
        onSelf: (only): Ledger => ({ observed: only, expected: 0 }),
        onOther: (only): Ledger => ({ observed: 0, expected: only }),
        onBoth: (seen, owed): Ledger => ({ observed: seen, expected: owed }),
        order: Order.string,
    });

// --- [EXPORTS] --------------------------------------------------------------------------

export { fused, published, reconciled, staged, totals };
export type { Ledger, Pulse, Sample };
```

## [06]-[INGRESS_BACKPRESSURE]

The seam between a push world and pull geometry is a bridge with an explicit buffer policy: the subscription is a scoped acquisition whose teardown rides the `Scope`, and every rate decision — suspend, shed, shape — is a typed value at the pipe, never an implicit unbounded queue.

[SCOPED_BRIDGE]:
- Law: a callback provider becomes a stream through `Stream.asyncScoped(register, policy)` — the registration is a scoped acquisition, so `Effect.acquireRelease` inside owns subscribe and unsubscribe as one bracket and teardown fires on completion, failure, and interruption alike; `emit.single`/`emit.chunk`/`emit.fail`/`emit.end` are the seam's admitted crossings, and the listener maps provider faults into the tagged family before emitting, so the error channel stays typed at the seam.
- Law: the bridge family discriminates on registration lifetime — `Stream.asyncScoped` when registration acquires, `Stream.asyncPush` when emission throughput dominates (its `single`/`chunk` return `boolean`, never a promise, and its shed strategies are `"dropping" | "sliding"` — push cannot suspend the producer), `Stream.asyncEffect` only when registration acquires nothing.
- Law: a queue or pubsub handoff is `Stream.fromQueue(dequeue, { shutdown: true })` or `Stream.fromPubSub` — a shut-down queue already ends the stream, and `shutdown: true` adds the reverse coupling: the stream's own end shuts the queue down, so the consumer's teardown releases the producer's channel; the `Queue` itself is `concurrency.md`'s owner, arriving here as a value, and a cell's `SubscriptionRef.changes` arrives as the same already-typed feed.
- Law: the pull side admits through the same family — `Stream.fromAsyncIterable(iterable, onError)` types the iterator's thrown junk at the seam, `Stream.fromEventListener(target, type, { bufferSize })` owns registration and removal on the stream's own lifetime — and egress mirrors ingress: `Stream.toQueue({ capacity, strategy })` and `Stream.toPubSub(capacity)` run the feed into a channel as a scoped background fiber whose `Take` envelopes carry end and failure typed, so a hand `runForEach` offer loop re-invents the envelope and drops the verdict.
- Exemption: the provider's push callbacks are the platform-forced statement seam — emissions are `void`-discarded inside the listener, the one place the pipeline cannot be an expression.
- Reject: a listener pushing into an outer array; `asyncEffect` where the registration subscribes — teardown would have no owner; an unsubscribe deferred to a consumer's cleanup instead of the bridge's own bracket.

[FLOW_POLICY]:
- Law: buffer policy is one typed value — `{ capacity, strategy: "suspend" | "dropping" | "sliding" }` read as a decision table: `"suspend"` backpressures the producer, `"dropping"` sheds the newest, `"sliding"` sheds the oldest — and `{ capacity: "unbounded" }` is a stated decision, never a default; `Stream.buffer` also decouples producer and consumer onto separate fibers, so inserting it is a concurrency decision, not a cache.
- Law: rate shaping is `Stream.throttle({ cost, units, duration, burst, strategy })` — a declared token bucket where `"shape"` delays and `"enforce"` drops, `cost` prices a whole chunk (`Chunk.size` for per-element pricing), and `burst` prices the allowance above steady state; `Stream.debounce(duration)` owns quiescence — emit only after input pauses — and `Stream.schedule(policy)` paces per element on a `Schedule` value, cadence where `throttle` prices volume.
- Reject: a hand token bucket around `mapEffect`; sleep-loop pacing; shedding via a mutable counter inside `filter`.

```typescript conceptual
import { Chunk, Data, type Duration, Effect, Stream } from "effect";

class FeedFault extends Data.TaggedError("FeedFault")<{ readonly reason: string }> {}

type Feed<A> = {
    readonly subscribe: (push: (value: A) => void, stop: (reason: string) => void) => () => void;
};
type Tempo = {
    readonly intake: number;
    readonly lag: number;
    readonly rate: { readonly units: number; readonly per: Duration.DurationInput; readonly burst: number };
};

const tempered = <A>(feed: Feed<A>, tempo: Tempo): Stream.Stream<A, FeedFault> =>
    Stream.asyncScoped<A, FeedFault>(
        (emit) =>
            Effect.acquireRelease(
                Effect.sync(() =>
                    feed.subscribe(
                        (value) => void emit.single(value),
                        (reason) => void emit.fail(new FeedFault({ reason })),
                    ),
                ),
                (unsubscribe) => Effect.sync(unsubscribe),
            ),
        { bufferSize: tempo.intake, strategy: "sliding" },
    ).pipe(
        Stream.buffer({ capacity: tempo.lag, strategy: "suspend" }),
        Stream.throttle({ cost: Chunk.size, units: tempo.rate.units, duration: tempo.rate.per, burst: tempo.rate.burst, strategy: "shape" }),
    );

// --- [EXPORTS] --------------------------------------------------------------------------

export { FeedFault, tempered };
export type { Feed, Tempo };
```

## [07]-[BATCHING]

N identical lookups inside one flow are one declared request family and one resolver: call sites stay singular, the collapse is structural, and no `getMany` twin, dedup map, or hand-assembled page query survives beside the family.

[REQUEST_FAMILY]:
- Law: the lookup is a class extending `Request.TaggedClass("<tag>")<Success, Error, Fields>` — one name serving value, type, constructor, and identity: structural `Equal` over the fields is what deduplicates two requests for the same key, so the fields carry exactly the identity, and success and failure types are declared once at the family, never re-stated at call sites.
- Law: the class owner absorbs its derivations as statics — the resolver factory, its combinator stack, and the windowed consumer live on the request class, so the module exports one name and the family cannot scatter.
- Law: one `RequestResolver.makeBatched((requests) => ...)` receives the whole window as a `NonEmptyArray` and must settle every request — `Request.completeEffect` per hit, `Request.fail` per miss, and a provider-level fault fans out to every request in the window; an unsettled request suspends its caller forever, the resolver's stated contract.
- Reject: a `getMany` twin beside `get`; a hand `Map` of in-flight promises as a dedup cache; a resolver rebuilt per call site.

[RESOLVER_ALGEBRA]:
- Law: batch windows group by resolver identity, so the resolver is built once and travels as a value — a capability-consuming resolver bakes its services at construction through `RequestResolver.contextFromServices(...tags)`, yielding a context-free (`R = never`) identity-stable resolver; `Effect.provide` wrapped around each call site re-mints identity and defeats the window.
- Law: a tagged request family shares one resolver through `RequestResolver.fromEffectTagged<Family>()({ ... })` — each handler receives its tag's whole window and answers positionally, index `i` resolving request `i`, so the family grows by a tag and a handler row, never a sibling resolver.
- Law: window shape is combinator algebra at the owner — `RequestResolver.batchN(n)` caps width, `RequestResolver.aroundRequests(before, after)` brackets every window with both effects receiving the request array and `after` also receiving `before`'s result, the evidence pair a timing bracket rides, and `RequestResolver.dataLoader(resolver, { window, maxBatchSize })` trades same-traversal collapse for a wall-clock window that batches across unrelated fibers — a scoped acquisition over a context-free resolver.
- Law: `RequestResolver.persisted(resolver, { storeId, timeToLive })` adds a durable result store keyed by the request's schema identity — the family upgrades to `Schema.TaggedRequest` so results serialize, and `timeToLive` folds the request and its `Exit` into the retention window, so hits and misses age separately; `dataLoader` and `persisted` ride `@effect/experimental`, the admission the manifest pin owns.
- Boundary: the `Persistence.ResultPersistence` backing arrives as a Layer — the durable-cache axis is `concurrency.md`'s.

[BATCH_GEOMETRY]:
- Law: call sites are `Effect.request(new <Req>({ ... }), resolver)` and the collapse is structural — `Effect.forEach(keys, ..., { batching: true })` funnels the whole traversal into one resolver window, while `Effect.withRequestBatching` and `Effect.withRequestCaching` scope the policy as rail transformers, caching deduplicating repeated keys across the flow.
- Law: in stream geometry the window is declared upstream — `Stream.groupedWithin(width, patience)` pages the key feed by count or latency, one batched `Effect.forEach` runs per page under `Stream.mapEffect` with `{ concurrency }` lanes, and `Stream.flattenIterables` restores element flow; width, patience, and lanes ride one `as const satisfies` policy row.
- Boundary: the resolver's provider call is `boundaries.md`'s seam — material is decoded before the resolver distributes it; this page owns only the collapse geometry.

```typescript conceptual
import { dataLoader } from "@effect/experimental/RequestResolver";
import { Array, Clock, Data, type Duration, Effect, HashMap, Option, Request, RequestResolver, type Scope, Stream } from "effect";

type Shape = { readonly id: string; readonly rank: number };

class LookupFault extends Data.TaggedError("LookupFault")<{
    readonly id: string;
    readonly reason: "absent" | "feed";
}> {}

type Page = (ids: ReadonlyArray<string>) => Effect.Effect<HashMap.HashMap<string, Shape>, LookupFault>;

const _WINDOW = { width: 64, patience: "50 millis", lanes: 4 } as const satisfies {
    width: number;
    patience: Duration.DurationInput;
    lanes: number;
};

class Lookup extends Request.TaggedClass("Lookup")<Shape, LookupFault, { readonly id: string }> {
    static readonly resolved = (page: Page): RequestResolver.RequestResolver<Lookup> =>
        RequestResolver.makeBatched((requests: Array.NonEmptyArray<Lookup>) =>
            page(Array.map(requests, (request) => request.id)).pipe(
                Effect.flatMap((rows) =>
                    Effect.forEach(
                        requests,
                        (request) =>
                            Request.completeEffect(
                                request,
                                Option.match(HashMap.get(rows, request.id), {
                                    onNone: () => Effect.fail(new LookupFault({ id: request.id, reason: "absent" })),
                                    onSome: Effect.succeed,
                                }),
                            ),
                        { discard: true },
                    ),
                ),
                Effect.catchAll(() =>
                    // a provider fault settles the whole window: an unsettled request suspends its caller forever
                    Effect.forEach(requests, (request) => Request.fail(request, new LookupFault({ id: request.id, reason: "feed" })), {
                        discard: true,
                    }),
                ),
            ),
        ).pipe(
            RequestResolver.batchN(_WINDOW.width),
            RequestResolver.aroundRequests(
                // before's result feeds after: the bracket carries the window's own timing evidence
                (window) => Effect.zipLeft(Clock.currentTimeMillis, Effect.annotateCurrentSpan("window.size", window.length)),
                (_, opened) => Effect.flatMap(Clock.currentTimeMillis, (closed) => Effect.annotateCurrentSpan("window.millis", closed - opened)),
            ),
        );

    static readonly windowed = (page: Page): Effect.Effect<RequestResolver.RequestResolver<Lookup>, never, Scope.Scope> =>
        dataLoader(Lookup.resolved(page), { window: _WINDOW.patience, maxBatchSize: _WINDOW.width });

    static readonly hydrated = <E, R>(
        ids: Stream.Stream<string, E, R>,
        resolver: RequestResolver.RequestResolver<Lookup>,
    ): Stream.Stream<Shape, E | LookupFault, R> =>
        ids.pipe(
            Stream.groupedWithin(_WINDOW.width, _WINDOW.patience),
            Stream.mapEffect(
                (batch) =>
                    Effect.forEach(batch, (id) => Effect.request(new Lookup({ id }), resolver), {
                        batching: true,
                    }).pipe(Effect.withRequestCaching(true)),
                { concurrency: _WINDOW.lanes },
            ),
            Stream.flattenIterables,
        );
}

// --- [EXPORTS] --------------------------------------------------------------------------

export { Lookup, LookupFault };
export type { Page, Shape };
```
