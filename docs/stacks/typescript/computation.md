# [TYPESCRIPT_COMPUTATION]

Every working body between the decode seam and the rail is one expression over already-admitted values: a single-pass fold into a typed seed, a lazy `Iterable` pipeline materialized once at its tail, an index-free window and sieve algebra, a `mapAccum` Mealy step, a structural recursion destructured over its closed family, or a measured kernel that detaches an immutable result. The value crossed its boundary upstream, so the interior is total over it and never re-validates; the result composes combinators at the depth the collection modules already reach — never a `for` loop pushing into an array, an index counter the value's own structure already answers, a second pass over a sequence one seeded pass closes, or a branch ladder — a ternary or `if`/`else` arm that opens a further decision collapses into the form that owns the variation: a vocabulary row for keyed correspondence, a `Match` arm for tag and structural dispatch, `Array.partitionMap` for the verdict split — because vertical nesting in a body is the statement pyramid in expression clothing. This page owns the pure, in-process computation algebra: the shape a working body takes after its values are admitted and before its outcome rides a rail.

Six siblings own material this algebra composes as settled: a fold whose accumulator is a carrier and the abort-versus-accumulate disposition are `rails-and-effects.md`'s; the carrier discriminant and the `Stream.mapAccum` lift of the step written here are `streams.md`'s; containers, algebra instances, and the merge tables are `values.md`'s; `Match` terminals and overload surfaces are `surfaces-and-dispatch.md`'s; cross-fiber cells are `concurrency.md`'s; the kernel mark's legality and its cast algebra are `language.md`'s — this page owns when a kernel is earned and which algorithmic forms it takes. What remains is the computation algebra, and its one collapse is uniform: a multi-pass scatter folds into one seeded pass, a materialized intermediate dissolves into a lazy combinator, a hand-indexed window becomes a window operator, a two-pass verdict split becomes one partitioned sieve, a cell beside a traversal becomes a `mapAccum` step, an unbounded native recursion becomes a frontier kernel, and a hand memo map becomes a tabulation fold.

## [01]-[INDEX]

This table maps a computational shape to the form that owns it; the most specific shape wins.

| [INDEX] | [COMPUTATION]                           | [OWNING_FORM]                               | [REJECTED_FORM]                       |
| :-----: | :-------------------------------------- | :------------------------------------------ | :------------------------------------ |
|  [01]   | several quantities over one sequence    | `Array.reduce` into one readonly seed       | `sum`/`min`/`max`/`length` pass       |
|  [02]   | running or cumulative trace             | `Array.scan`, `(step, SEED)` pair           | an index loop appending each step     |
|  [03]   | multi-stage transform, large source     | lazy `Iterable` pipeline; tail materialized | a fully built array per stage         |
|  [04]   | sliding or fixed windows                | `Array.window` / `Array.chunksOf`           | `slice(i, i + n)` index stepping      |
|  [05]   | parallel or Cartesian co-iteration      | `Array.zipWith` / `Array.cartesianWith`     | nested `for` loops, a hand index pair |
|  [06]   | keyed, prefix, or breach grouping       | `Array.groupBy` and peers                   | a mutable bucket accumulator          |
|  [07]   | verdict split or `Option` harvest       | `Array.partitionMap` / `Array.getSomes`     | a filter-then-map double pass         |
|  [08]   | element-wise transform, threaded state  | `Array.mapAccum` Mealy step                 | a `let` rebound across a `map`        |
|  [09]   | closed transition system                | vocabulary rows carry `(next, emit)`        | a `switch` advancing a mutable phase  |
|  [10]   | stateful actor behind a request surface | `Machine.makeSerializable` procedure rows   | class of mutable fields, methods      |
|  [11]   | bounded recursion over a closed family  | `(leaf, join)` algebra, one traversal       | a recursive function per reduction    |
|  [12]   | input-scaled recursion depth            | frontier kernel; `Effect.iterate` rail      | native recursion past stack ceiling   |
|  [13]   | graph-shaped traversal or path cost     | `Graph.dfs` and peers                       | a hand frontier over adjacency state  |
|  [14]   | overlapping subproblems                 | tabulation fold; `Effect.cachedFunction`    | a hand memo `Map` beside the function |
|  [15]   | measured hot path                       | `MutableHashMap`/`TypedArray` draft         | ambient mutation in domain flow       |

- [01]: statistics project at read.
- [06]: grouping: `Array.groupBy` keyed, `Array.span` prefix, `Array.splitWhere` breach.
- [09]: one fold drives the rows.
- [10]: procedure rows booted scoped.
- [12]: frontier kernel walks an immutable `List` stack.
- [13]: graph walkers: `Graph.dfs`, `Graph.topo`, `Graph.dijkstra`.
- [14]: tabulation fold threads the solved table; the `Effect.cachedFunction` family memoizes.
- [15]: marked kernel drafts mutable, detaches an immutable result.

## [02]-[SEED_FOLD]

A body that needs several quantities from one sequence folds them in one pass into a typed seed whose fields are the running invariants. The collapse is the multi-pass scatter: `sum`, `min`, `max`, and `length` over one collection are four traversals; one `Array.reduce(values, SEED, step)` is one. The seed is the growth site — a new statistic is one field, one step line, and one merge row — and the same `(step, SEED)` pair serves the terminal fold and the running trace, so the two forms cannot drift.

[STRUCT_SEED]:
- Law: the seed is a plain readonly record, never `Data`-constructed — it is fold-local and no container consumes its identity, so construction-time `Equal`/`Hash` buys one dead allocation per element; three or more named running quantities earn the record, and a two-quantity seed stays a readonly tuple.
- Law: the fold carries raw associative accumulators — counts, sums, sums of squares, extrema — and derived statistics project at read through the `Option`-returning partial owners; a running mean or variance carried as fold state is the rejected form because it cannot combine across two partial folds.
- Law: partial folds fuse through the seed's own `Semigroup.struct` row table — the seed shape doubles as the merge table, so lane-partitioned folds combine row-by-row under `combineMany` and the fusion is recoverable from one declaration; the instance algebra is `values.md`'s, composed here.
- Reject: a `let` rebound across steps; a `sum`/`min`/`max` pass apiece over one sequence; a mutated accumulator object; a `Data.struct` seed.

[SCAN_TRACE]:
- Law: `Array.scan(values, SEED, step)` shares the fold's exact `(step, SEED)` pair and keeps every intermediate seed the fold discards — the return is `NonEmptyArray` with the seed first, so the origin's presence is a type fact, and a consumer that must not see it drops it at the read, never by patching the step; `Array.scanRight` threads the suffix trace from the right.
- Boundary: a fold whose accumulator is `Option`/`Either` or whose faults must accumulate is `rails-and-effects.md`'s carrier algebra, and the same trace over a live feed is `Stream.scan`, `streams.md`'s — this seed is a pure value, total over admitted elements.

```typescript conceptual
import * as Semigroup from "@effect/typeclass/Semigroup"
import * as NumberInstances from "@effect/typeclass/data/Number"
import { Array, Number, Option } from "effect"

type Sketch = {
  readonly count: number
  readonly total: number
  readonly squared: number
  readonly floor: number
  readonly crest: number
}

const _SEED: Sketch = { count: 0, total: 0, squared: 0, floor: Infinity, crest: -Infinity } // plain readonly seed: fold-local, no container consumes its identity, so Data construction buys nothing

const _stepped = (sketch: Sketch, load: number): Sketch => ({ // raw associative accumulators only: which field advances lives in the construction, never an if ladder
  count: sketch.count + 1,
  total: sketch.total + load,
  squared: sketch.squared + load * load,
  floor: Number.min(sketch.floor, load),
  crest: Number.max(sketch.crest, load),
})

const _merged: Semigroup.Semigroup<Sketch> = Semigroup.struct({ // the seed shape doubles as its own merge table: partial folds fuse row-by-row through the composed instance
  count: NumberInstances.SemigroupSum,
  total: NumberInstances.SemigroupSum,
  squared: NumberInstances.SemigroupSum,
  floor: NumberInstances.SemigroupMin,
  crest: NumberInstances.SemigroupMax,
})

const Sketch = {                                              // one name serves value and type: the fold family assembles on the owner, every anchor stays interior
  fold: (loads: ReadonlyArray<number>): Sketch => Array.reduce(loads, _SEED, _stepped), // several quantities, one pass: the sum/min/max/length scatter is deleted
  trace: (loads: ReadonlyArray<number>): Array.NonEmptyArray<Sketch> => Array.scan(loads, _SEED, _stepped), // the same (step, SEED) pair: the trace keeps every seed the fold discards, origin first
  fuse: (lanes: Array.NonEmptyReadonlyArray<ReadonlyArray<number>>): Sketch =>
    _merged.combineMany(Sketch.fold(Array.headNonEmpty(lanes)), Array.map(Array.tailNonEmpty(lanes), Sketch.fold)), // partitioned lanes fold independently and fuse: only raw accumulators merge
  pace: (sketch: Sketch): Option.Option<number> =>
    Number.divide(sketch.total, sketch.count),                // partiality folds once at the read: the empty fold's mean is a value, never a NaN
  spread: (sketch: Sketch): Option.Option<number> =>
    Option.map(Number.divide(sketch.squared, sketch.count), (moment) => moment - (sketch.total / sketch.count) ** 2), // derived statistics project at read: a carried mean cannot combine across partial folds
} as const

// --- [EXPORTS] --------------------------------------------------------------------------

export { Sketch }
```

## [03]-[LAZY_AND_WINDOW]

A multi-stage transform selects eager or lazy by materialization cost, and its windows never spell an index. Eager `Array` combinators own the bounded collection in hand; the `Iterable` module owns the pipeline whose source is large, generated, or consumed once — each stage an iterator over the previous, exactly one materialization at the tail. Window, chunk, co-iteration, grouping, and the verdict sieve are named operators, so the moment slice arithmetic, a nested loop, a bucket accumulator, or a filter-then-map double pass appears, an operator already owns the shape.

[LAZY_PIPELINE]:
- Law: laziness is a memory contract — `Iterable.map`/`filter`/`filterMap`/`take`/`takeWhile`/`drop`/`flatMap`/`flatten`/`dedupeAdjacent` compose without materializing and hold bounded memory over an unbounded source, `Iterable.scan` keeps the running trace lazy, and `Iterable.filterMapWhile` fuses filter, transform, and stop into one operator; the tail materializes once — `Array.fromIterable` for a collection, `Iterable.reduce` for a value — and a fully built array mid-chain re-buys the allocation laziness deleted.
- Law: production is an anamorphism — `Iterable.unfold(seed, step)` generates from a seed with `Option` termination, and `Iterable.range`/`Iterable.makeBy` name the arithmetic sources — so a `function*` generator in domain flow is a statement seam smuggled in as production.
- Reject: a `[...feed]` spread or intermediate array between stages; a hand `while` loop growing an array where `unfold` states the production; laziness over a small bounded collection already in hand — the eager combinators read shorter and allocate once.

[WINDOW_ALGEBRA]:
- Law: an index is never spelled — `Array.window(values, width)` yields every full sliding window and only full windows, `Array.chunksOf(values, width)` yields fixed pieces keeping the shorter last, and the two differ by name, never by a flag; position, where the shape genuinely carries it, is the callback's own index parameter, which every fold and map already passes.
- Law: co-iteration is a named pairing — `Array.zipWith(self, that, combine)` pairs positionally and truncates to the shorter operand, the stated semantics a caller proves length against; adjacent difference is `zipWith` against the self dropped by one, and `Array.cartesianWith(self, that, combine)` collapses the nested loop into one operator.
- Law: grouping selects by discipline — `Array.groupBy(values, key)` builds the keyed record of `NonEmptyArray` runs in one pass, `Array.span(values, predicate)` splits the satisfying prefix, `Array.splitWhere` splits at the first breach, and `Iterable.groupWith` groups adjacent runs under an equivalence; a mutable bucket object grown in a loop restates all four.
- Law: a per-element verdict never earns two passes — `Array.partitionMap(values, verdict)` routes every element through one `Either`-returning classifier into `[lefts, rights]`, `Array.separate` splits an already-classified collection, and the harvest tier `Array.getSomes`/`Array.getLefts`/`Array.getRights` collapses partial projections without a filter-then-unwrap re-walk; the harvest tier rides the `Iterable` module lazily, while the two-lane split is eager by nature — both lanes materialize, so no lazy twin exists to reach for.
- Reject: `values[index + 1]` window arithmetic; a `for i`/`for j` cross product; a run accumulator tracking a `last` variable; index-keyed objects standing where `groupBy` owns the keying; a `filter` pass re-walked by a `map` unwrapping its survivors.

```typescript conceptual
import { Array, Either, Iterable, Number, Option, Record, pipe } from "effect"

declare namespace Sieve {
  type Beat = readonly [lane: string, load: number]
}

const _laddered = (ceiling: number, floor: number): Iterable<number> =>
  Iterable.unfold(ceiling, (rung) => (rung >= floor ? Option.some([rung, rung / 2]) : Option.none())) // the anamorphism: production is a seeded combinator with Option termination, never a hand loop

const Sieve = {
  profile: (batches: Iterable<Iterable<Sieve.Beat>>, gate: number, cap: number): Record.ReadonlyRecord<string, number> =>
    pipe(
      Iterable.flatten(batches),                              // every stage is an iterator over the previous: bounded memory holds an unbounded source
      Iterable.takeWhile(([, load]) => load >= 0),            // the prefix trim: a break statement dissolved into a named bound
      Iterable.filter(([, load]) => load >= gate),
      Iterable.take(cap),
      Array.fromIterable,                                     // the one materialization, at the tail — everything above stays unevaluated until this pull
      Array.groupBy(([lane]) => lane),
      Record.map((run) => Number.sumAll(Iterable.map(run, ([, load]) => load))), // the per-lane projection stays an iterator: sumAll pulls it, no intermediate array
    ),
  mesh: (loads: ReadonlyArray<number>, ceiling: number, floor: number): {
    readonly paired: ReadonlyArray<number>
    readonly crossed: ReadonlyArray<number>
  } => ({
    paired: Array.fromIterable(Iterable.zipWith(loads, _laddered(ceiling, floor), (load, decay) => load * decay)), // positional pairing truncates at the shorter operand: the ladder bounds the take
    crossed: Array.cartesianWith(loads, Array.fromIterable(_laddered(ceiling, floor)), (load, decay) => load * decay), // the Cartesian pairing: nested for loops collapse into one operator
  }),
  pane: (loads: ReadonlyArray<number>, lens: { readonly width: number; readonly floor: number }): {
    readonly drifts: ReadonlyArray<number>
    readonly glides: ReadonlyArray<number>
    readonly paces: ReadonlyArray<number>
  } => ({
    drifts: Array.zipWith(loads, Array.drop(loads, 1), (prior, next) => next - prior), // adjacent difference: co-iteration against the self dropped by one, no index spelled
    glides: Array.map(Array.window(loads, lens.width), (pane) => Number.sumAll(pane) / lens.width), // full sliding windows only: the operator owns the bound the slice loop re-derives
    paces: Array.getSomes(Array.map(Array.chunksOf(loads, lens.width), (pane) =>
      pipe(Array.filter(pane, (load) => load >= lens.floor), (hot) => Number.divide(Number.sumAll(hot), hot.length)))), // the Option harvest is real absence: a pane with no load at the floor folds to none and leaves the lane
  }),
  sift: (beats: ReadonlyArray<Sieve.Beat>, gate: number): {
    readonly lulls: ReadonlyArray<string>
    readonly surges: ReadonlyArray<number>
  } =>
    pipe(
      Array.partitionMap(beats, ([lane, load]) => (load >= gate ? Either.right(load) : Either.left(lane))), // one traversal, two typed lanes: the verdict routes through Either, the double pass is deleted
      ([lulls, surges]) => ({ lulls, surges }),
    ),
  stage: (loads: ReadonlyArray<number>, gate: number): {
    readonly ramp: ReadonlyArray<number>
    readonly steady: ReadonlyArray<number>
    readonly spike: ReadonlyArray<number>
  } =>
    pipe(
      Array.span(loads, (load) => load < gate),               // the satisfying prefix splits by predicate, the remainder splits at first breach
      ([ramp, rest]) => pipe(Array.splitWhere(rest, (load) => load >= gate * 2), ([steady, spike]) => ({ ramp, steady, spike })),
    ),
} as const

// --- [EXPORTS] --------------------------------------------------------------------------

export { Sieve }
```

## [04]-[STATEFUL_STEP]

State that threads element-to-element is a Mealy step — one `(state, element) => [state, output]` declaration — and stateful computation has exactly three rungs: the step folded over a collection, the step's rows lifted into a vocabulary table when the state space closes, and the actor when the state must outlive one traversal and answer requests. Every rung is the same shape written once; a `let` beside a `map`, a `switch` advancing a mutable phase, and a class of mutable fields are one defect at three sizes.

[MEALY_STEP]:
- Law: `Array.mapAccum(values, seed, step)` threads the accumulator and emits per element, returning `[state, outputs]` — the carried state decouples from the emitted shape, and the step's third parameter is the index, so a hand counter beside the fold restates the signature.
- Law: the step is written once and both carriers consume it — the same declaration lifts unchanged into `Stream.mapAccum` when the data becomes incremental; the lift and its pipeline law are `streams.md`'s.
- Reject: a `let` rebound across `Array.map`; a module-level cell advanced by a traversal; a step hand-specialized per carrier.

[TRANSITION_LADDER]:
- Law: a closed transition system is a vocabulary table, not control flow — one `as const` anchor keyed by state whose rows carry `(next, emit)` per input kind, driven by one `mapAccum` reading rows — so a new phase or input is a row, never a branch; the anchor's derivation and guard mechanics are `derivation.md`'s.
- Law: scale is table composition, never state explosion — a hierarchical phase nests as a row whose payload anchors a sub-table driven by the same fold, parallel regions are independent fields of one state record each advanced by the signals it reads, and a guard is a predicate column the step consults before the row fires; the cross-product table enumerating every region combination is the rejected form.
- Law: the ladder tops at the actor, declared as procedure rows over one state — in-process, `Machine.makeWith<State, Input>()` with `Machine.procedures.make(initial)` grown by `Machine.procedures.add<Req>()(tag, handler)` on `Request.TaggedClass` rows; across a process edge, `Machine.makeSerializable({ state, input }, initialize)` with `Machine.serializable.make`/`Machine.serializable.add` on `Schema.TaggedRequest` rows — each handler `({ request, state })` returns `[reply, state]` on the rail, the initialize arrow returns its list bare because a procedure list is its own `Effect`, and `Machine.boot` yields the scoped `Actor` whose `send` serializes every request against one state on one fiber.
- Law: background work forks through the handler context, never a bare `Effect.fork` — `fork` runs an unkeyed child, `forkOne(effect, id)` starts only while no live fiber holds the id, `forkReplace(effect, id)` interrupts the incumbent and re-arms — every child dies with the actor's scope, and a forked defect is a machine defect the `Machine.retry` `Schedule` policy value re-initializes through.
- Law: recovery and durability are definition facts — retry re-entry and `boot`'s `previousState` resume through the same initialize slot carrying the last live state, the serializable actor adds `sendUnknown` for encoded ingress, and `Machine.snapshot` emits the schema-encoded `[input, state]` pair `Machine.restore` boots a successor from.
- Boundary: the actor exists because its state outlives one traversal and answers a request surface — state shared across arbitrary fibers with no request surface is `concurrency.md`'s cell selection.
- Reject: a class of mutable fields and methods; a `switch` over phases mutating an outer variable; a bare `Effect.fork` inside a handler; a reply table declared beside the `(next, emit)` rows it duplicates.

```typescript conceptual
import { Machine } from "@effect/experimental"
import { Array, Duration, Effect, type ParseResult, pipe, Schedule, Schema, type Scope } from "effect"

const _PHASES = ["idle", "live", "halted"] as const           // interior key anchors: wire order and non-emptiness are tuple facts, and the guards tie the table to them
const _SIGNALS = ["pulse", "fault", "reset"] as const
const _VERDICTS = ["opened", "held", "tripped", "closed"] as const

const _rows = {                                               // interior row anchor: rows carry (next, emit), a new phase or signal is a row, never a branch
  idle: {
    pulse: { next: "live", emit: "opened" },
    fault: { next: "halted", emit: "tripped" },
    reset: { next: "idle", emit: "held" },
  },
  live: {
    pulse: { next: "live", emit: "held" },
    fault: { next: "halted", emit: "tripped" },
    reset: { next: "idle", emit: "closed" },
  },
  halted: {
    pulse: { next: "halted", emit: "held" },
    fault: { next: "halted", emit: "held" },
    reset: { next: "idle", emit: "closed" },
  },
} as const

declare namespace Transit {
  type Phase = (typeof _PHASES)[number]
  type Signal = (typeof _SIGNALS)[number]
  type Verdict = (typeof _VERDICTS)[number]
  type Row = (typeof _rows)[Phase][Signal]
  type Setup = { readonly origin: Phase; readonly watch: Duration.DurationInput; readonly cool: Duration.DurationInput }
  type Shape = typeof _rows & {
    readonly step: (phase: Phase, signal: Signal) => readonly [Phase, Verdict]
    readonly drive: (origin: Phase, signals: ReadonlyArray<Signal>) => [Phase, ReadonlyArray<Verdict>]
    readonly boot: (setup: Setup, signals: ReadonlyArray<Signal>) => Effect.Effect<{ readonly verdicts: ReadonlyArray<Verdict>; readonly landed: Phase }, ParseResult.ParseError, Scope.Scope>
  }
  type _Rows<T extends { readonly [P in Phase]: { readonly [S in Signal]: { readonly next: Phase; readonly emit: Verdict } } } = typeof _rows> = T // row guard: every phase covers every signal with a member verdict; a keyof-derived Signal would silently shrink to the common keys
  type _Keys<K extends Phase = keyof typeof _rows> = K        // key guard: an excess phase row fails here — closure in both directions
}

const _Phase = Schema.Literal(..._PHASES)                     // the tuple spread holds the non-empty overload: derived keys would demote the schema to the widened array
const _Signal = Schema.Literal(..._SIGNALS)
const _Setup = Schema.Struct({ origin: _Phase, watch: Schema.Duration, cool: Schema.Duration })

class Feed extends Schema.TaggedRequest<Feed>()("Feed", {
  failure: Schema.Never,
  success: Schema.Literal(..._VERDICTS),
  payload: { signal: _Signal },
}) {}

class Poll extends Schema.TaggedRequest<Poll>()("Poll", {
  failure: Schema.Never,
  success: _Phase,
  payload: {},
}) {}

const _machine = Machine.makeSerializable({ state: _Phase, input: _Setup }, (input, previous) =>
  Machine.serializable.make(previous ?? input.origin).pipe(   // reboot and retry resume through the same slot: previousState carries the last live state, and the list is its own Effect
    Machine.serializable.add(Feed, ({ forkOne, forkReplace, request, send, state }) =>
      Effect.gen(function* () {
        const row = _rows[state][request.signal]
        yield* forkReplace(row.next === "live" ? Effect.delay(send(new Feed({ signal: "fault" })), input.watch) : Effect.void, "watch") // every transition re-arms or disarms the deadline: the incumbent watcher is interrupted, live phases arm a timed self-fault
        yield* (row.next === "halted" ? forkOne(Effect.delay(send(new Feed({ signal: "reset" })), input.cool), "revive") : Effect.void) // at most one pending revive: forkOne skips while the keyed fiber lives, so stacked faults cannot stack resets
        return [row.emit, row.next] as const                  // the same (next, emit) row drives the actor: the reply is the emission, the state advances
      })),
    Machine.serializable.add(Poll, ({ state }) => Effect.succeed([state, state] as const)), // a new request is one procedure row against the same state, never a second actor
  ),
).pipe(Machine.retry(Schedule.recurs(3)))                     // a defect re-initializes from the last state: recovery is a policy value on the definition

const Transit: Transit.Shape = {                              // one export assembles rows and drivers under a stated annotation: keyof stays anchored on the interior table, so member keys never pollute the key space
  ..._rows,
  step: (phase, signal) => pipe(_rows[phase][signal], (row) => [row.next, row.emit] as const), // the Mealy shape: carried state decouples from emitted verdict — the exact step Stream.mapAccum lifts unchanged
  drive: (origin, signals) => Array.mapAccum(signals, origin, Transit.step), // one traversal threads the phase and emits per element; no let advances beside a map
  boot: (setup, signals) =>
    Effect.gen(function* () {
      const actor = yield* Machine.boot(_machine, { origin: setup.origin, watch: Duration.decode(setup.watch), cool: Duration.decode(setup.cool) })
      const verdicts = yield* Effect.forEach(signals, (signal) => actor.send(new Feed({ signal })))
      const frozen = yield* Machine.snapshot(actor)           // the snapshot is the schema-encoded [input, state] pair
      const revived = yield* Machine.restore(_machine, frozen) // a second life resumes exactly where the first froze: durability is a definition fact
      return { verdicts, landed: yield* revived.send(new Poll()) }
    }),
}

// --- [EXPORTS] --------------------------------------------------------------------------

export { Transit }
```

## [05]-[STRUCTURAL_RECURSION]

A computation over a recursive structure is one algebra applied by one traversal: a `(leaf, join)` pair serves every reduction over the closed family, and depth selects the execution form — native recursion to data depth, the frontier kernel or the rail past it — never the algebra. When the structure is a graph rather than a tree, the traversal itself is owned: the walker families delete the hand frontier.

[CATAMORPHISM]:
- Law: one `(leaf, join)` algebra value serves every reduction — sum, depth, flatten, render are algebra rows, never a recursive function per reduction — and the traversal threads children through the same public surface; the fold rides tag refinement because the record dispatch's carrier reduction strands the bare `R` its arms return, the `Unify` mechanics `surfaces-and-dispatch.md` owns.
- Law: native recursion is legal only to data depth — a structure admitted at bounded fan-in and height reads freely, and input-scaled or adversarial depth forfeits the form, because the JS call stack is a fixed platform ceiling no flag, option, or worker size raises.
- Exemption: the frontier kernel is this page's statement-bearing seam, licensed by that fixed ceiling — an immutable `List` work stack rebound each turn, `expand` frames sliding a `combine` marker beneath a branch's children and a second immutable stack carrying results until the marker joins them — so the traversal is iterative exactly where native recursion overflows; the mark's legality is `language.md`'s.
- Law: an effectful step at depth rides the rail's own trampoline — `Effect.iterate(initial, { while, body })` advances a state heap-bound, `Effect.loop` collects per step, and `Effect.suspend` defers a recursive definition so constructing the effect does not itself recurse.
- Reject: a recursion or `Match` pipeline re-authored per reduction over a family one algebra value already serves; a depth flag threaded through signatures; a result array mutated by a recursive helper; a raised stack budget standing where the frontier folds.

```typescript conceptual
import { Array, Effect, Either, List, Number, Option } from "effect"

type Limb =
  | { readonly _tag: "tip"; readonly load: number }
  | { readonly _tag: "fork"; readonly limbs: ReadonlyArray<Limb> }

declare namespace Limb {
  type Algebra<R> = { readonly tip: (load: number) => R; readonly fork: (parts: ReadonlyArray<R>) => R } // the companion rides the owner's one name: a consumer imports Limb and reaches the algebra contract
}

type _Frame = { readonly _tag: "expand"; readonly limb: Limb } | { readonly _tag: "combine"; readonly arity: number }

const _massed: Limb.Algebra<number> = { tip: (load) => load, fork: Number.sumAll }
const _spanned: Limb.Algebra<number> = { tip: () => 1, fork: (parts) => 1 + Array.reduce(parts, 0, Number.max) } // depth is an algebra row beside mass: a new reduction is one value, never a second traversal

const Limb = {
  fold: <R>(limb: Limb, algebra: Limb.Algebra<R>): R =>       // the bare-parameter fold rides tag refinement: one (leaf, join) value serves every reduction
    limb._tag === "tip"
      ? algebra.tip(limb.load)
      : algebra.fork(Array.map(limb.limbs, (child) => Limb.fold(child, algebra))),
  fathom: <R>(root: Limb, algebra: Limb.Algebra<R>): R => {   // BOUNDARY ADAPTER: frontier kernel — the fixed JS call-stack ceiling licenses this statement seam; the rebound Lists never escape
    let frames: List.List<_Frame> = List.of<_Frame>({ _tag: "expand", limb: root })
    let results: List.List<R> = List.empty<R>()
    while (List.isCons(frames)) {
      const head: _Frame = frames.head
      frames = frames.tail
      if (head._tag === "combine") {
        const [parts, rest] = List.splitAt(results, head.arity)
        results = List.cons(algebra.fork(List.toArray(parts)), rest)
      } else if (head.limb._tag === "tip") {
        results = List.cons(algebra.tip(head.limb.load), results)
      } else {
        frames = Array.reduce(                                // a combine marker slides beneath the children; consing in order resolves the last child first, so joined parts read left-to-right
          head.limb.limbs,
          List.cons<_Frame>({ _tag: "combine", arity: head.limb.limbs.length }, frames),
          (acc, limb) => List.cons<_Frame>({ _tag: "expand", limb }, acc),
        )
      }
    }
    return List.unsafeHead(results)                           // sanctioned read: the loop invariant leaves exactly one result on the stack
  },
  assay: (limb: Limb): { readonly depth: number; readonly mass: number } =>
    ({ depth: Limb.fold(limb, _spanned), mass: Limb.fathom(limb, _massed) }), // one algebra family, both executors: admission evidence selects fold or frontier, and the reduction never changes
  plumb: (limb: Limb): Effect.Effect<number> =>
    limb._tag === "tip"
      ? Effect.succeed(limb.load)
      : Effect.suspend(() => Effect.map(Effect.forEach(limb.limbs, Limb.plumb), Number.sumAll)), // suspend defers construction: the recursion unfolds one level per fiber step, heap-bound like iterate
} as const

const chased = <S, E, R>(seed: S, advance: (state: S) => Effect.Effect<Option.Option<S>, E, R>): Effect.Effect<S, E, R> =>
  Effect.map(
    Effect.iterate<Either.Either<S, S>, R, E>(Either.right(seed), { // the rail is the trampoline and the carrier is the loop flag: Right advances heap-bound, Left is the settled state — no hand cursor record, no boolean
      while: Either.isRight,
      body: (cursor) =>
        Effect.map(advance(Either.merge(cursor)), Option.match({
          onNone: () => Either.left(Either.merge(cursor)),
          onSome: (state) => Either.right(state),
        })),
    }),
    Either.merge,
  )

// --- [EXPORTS] --------------------------------------------------------------------------

export { Limb, chased }
```

[GRAPH_CONSUMPTION]:
- Law: when the structure is a graph the frontier is never hand-rolled — `Graph.dfs`/`Graph.bfs`/`Graph.dfsPostOrder`/`Graph.topo` return walkers consumed as iterables through `Graph.values`/`Graph.indices`/`Graph.entries`, so traversal order is a named read; `Graph` is `@experimental`, an admission fact the pin owns.
- Law: path, condensation, and rendering questions are owner reads — `Graph.dijkstra`/`Graph.astar`/`Graph.bellmanFord` return `Option` of a `PathResult` carrying `path`, `distance`, and `costs`, `Graph.floydWarshall` answers all pairs, `Graph.stronglyConnectedComponents`/`Graph.isAcyclic` answer condensation, and `Graph.toMermaid`/`Graph.toGraphViz` project the same owner to a diagram — a hand Dijkstra over adjacency state or a hand-walked serializer restates the family.
- Boundary: graph construction, the `Graph.mutate` write discipline, and `Trie` prefix reads are `values.md`'s owners — this page owns only the algorithmic consumption.

```typescript conceptual
import { Array, Graph, Option } from "effect"

const charted = (plan: Graph.DirectedGraph<string, number>, source: Graph.NodeIndex, target: Graph.NodeIndex): {
  readonly stages: ReadonlyArray<string>
  readonly span: Option.Option<number>
  readonly knots: ReadonlyArray<ReadonlyArray<Graph.NodeIndex>>
  readonly drawn: string
} => ({
  stages: Array.fromIterable(Graph.values(Graph.topo(plan))), // traversal order is a walker read, never a hand frontier over adjacency state
  span: Option.map(Graph.dijkstra(plan, { source, target, cost: (toll) => toll }), (path) => path.distance),
  knots: Array.filter(Graph.stronglyConnectedComponents(plan), (component) => component.length > 1), // the condensation read: every nontrivial component is a cycle to dissolve
  drawn: Graph.toMermaid(plan),                               // the diagram is a projection read of the same owner
})

// --- [EXPORTS] --------------------------------------------------------------------------

export { charted }
```

## [06]-[MEMO_AND_KERNEL]

No pure memoization combinator ships, and that absence is the law: a pure recurrence with overlapping subproblems tabulates bottom-up as a fold that threads its solved table, effectful memoization rides an owned combinator family, and a mutation kernel exists only where measurement indicts the fold. The hand memo `Map`, the module-level cache object, and the unmarked hot loop are three spellings of one defect.

[MEMO_OWNERS]:
- Law: the pure recurrence tabulates — one fold over the ordered subproblem space threading the solved table as its seed, a `Chunk` for dense keys because `Chunk.append` grows amortized where an array rebuild copies per rung, a `HashMap` for sparse ones — the structural dual of a memo with no cache identity, no eviction, and no stack growth, so the deep dynamic program is a fold, never a stack-bound recursion.
- Law: effectful memoization is one family selected by lifetime policy — `Effect.cachedFunction(f)` memoizes per argument under structural `Equal` with an `Equivalence` as the optional second parameter, `Effect.cached` defers and memoizes one result for the flow's life, `Effect.cachedWithTTL(self, ttl)` expires it so the first pull after the window recomputes, `Effect.cachedInvalidateWithTTL(self, ttl)` returns the memo paired with its invalidate effect so staleness is forced on evidence rather than waited out, and `Effect.once` runs at most once and replays `void` — each returns the memoized surface inside `Effect`, so the cache lives exactly as long as the flow that built it and the window is a `Duration` policy value.
- Boundary: keyed concurrent caching under capacity and TTL policy is `Cache.make`, `concurrency.md`'s contention owner — reached for when concurrent misses must collapse, never when a pure table folds.
- Reject: a hand memo `Map` beside the function; a captured mutable operand the key omits; a module-level cache object outliving every flow that reads it; a TTL spelled as a stored timestamp compared in the body.

[KERNEL_EARN]:
- Law: the earn test is sequential — fold first, measure, then mark: a kernel exists only where a measured hot path indicts the fold's allocation or dispatch cost, or where a platform contract forces statements; a kernel kept after its measurement pressure disappears reverts to the fold.
- Law: the draft is scoped and the return detaches — `MutableHashMap` batches structural-keyed writes, `MutableList` the append lane, a `TypedArray` the numeric lane — and the kernel returns an immutable projection with no live reference escaping; the mark's legality and the cast algebra inside it are `language.md`'s.
- Reject: a `Map` or object cache in domain flow; a `TypedArray` view escaping its kernel; mutation justified by style where no measurement exists.

```typescript conceptual
import { Array, Chunk, type Duration, Effect, HashMap, MutableHashMap, Number, Option, pipe } from "effect"

const _BASE: Chunk.Chunk<number> = Chunk.of(1)                // the solved table's origin row: one path reaches zero

const Memo = {
  tally: (target: number, strides: ReadonlyArray<number>): number =>
    pipe(
      Array.reduce(Array.range(1, target), _BASE, (table, rung) => // tabulation is the fold dual of the memo: the solved table threads as the seed — Chunk appends amortized, no cache identity, no stack growth
        Chunk.append(table, Number.sumAll(Array.filterMap(strides, (stride) => (stride <= rung ? Chunk.get(table, rung - stride) : Option.none()))))),
      Chunk.get(target),                                      // the read is total by construction: an out-of-range target folds to the empty count
      Option.getOrElse(() => 0),
    ),
  survey: <E, R>(keys: ReadonlyArray<string>, probe: (key: string) => Effect.Effect<number, E, R>): Effect.Effect<ReadonlyArray<number>, E, R> =>
    Effect.flatMap(Effect.cachedFunction(probe), (memoed) => Effect.forEach(keys, memoed)), // effectful memo is an owned combinator: repeated keys probe once under structural Equal
  prime: <A, E, R>(mint: Effect.Effect<A, E, R>, ttl: Duration.DurationInput): Effect.Effect<readonly [A, A, A], E, R> =>
    Effect.gen(function* () {
      const [warm, spoil] = yield* Effect.cachedInvalidateWithTTL(mint, ttl) // the memo ships beside its invalidate effect, and the window is a Duration policy value
      const first = yield* warm
      const second = yield* warm                              // inside the window the memo replays: one execution serves both pulls
      yield* spoil                                            // staleness is forced on evidence, never waited out: the next pull recomputes
      return [first, second, yield* warm] as const
    }),
} as const

const Kernel = {
  bin: (loads: ReadonlyArray<number>, lens: { readonly width: number; readonly slots: number }): {
    readonly bins: ReadonlyArray<number>
    readonly peak: number
  } => {                                                      // BOUNDARY ADAPTER: measured bincount kernel — the typed-array draft and the fused peak detach immutable at the return
    const draft = new Float64Array(lens.slots)
    let peak = 0
    for (const load of loads) {
      const slot = Math.min(Math.max(Math.trunc(load / lens.width), 0), lens.slots - 1)
      const risen = draft[slot]! + 1                          // sanctioned assertion: the clamp above is the bound evidence the checker cannot carry
      draft[slot] = risen
      peak = risen > peak ? risen : peak
    }
    return { bins: Array.fromIterable(draft), peak }          // the draft never escapes: the return is an immutable projection
  },
  rank: (lanes: ReadonlyArray<string>): HashMap.HashMap<string, number> => { // BOUNDARY ADAPTER: measured tally kernel — batch keyed writes against one draft, detached immutable
    const draft = MutableHashMap.empty<string, number>()
    for (const lane of lanes) {
      MutableHashMap.modifyAt(draft, lane, Option.match({ onNone: () => Option.some(1), onSome: (count) => Option.some(count + 1) }))
    }
    return HashMap.fromIterable(draft)                        // the draft dies here: consumers receive the persistent owner, never the mutable reference
  },
} as const

// --- [EXPORTS] --------------------------------------------------------------------------

export { Kernel, Memo }
```
