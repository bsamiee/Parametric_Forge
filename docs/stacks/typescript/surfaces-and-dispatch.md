# [TYPESCRIPT_SURFACES_AND_DISPATCH]

A concern with many call shapes keeps one dense surface, never a family of shallow ones. One entrypoint absorbs every modality — key, batch, and query call shapes are one input union under one declaration whose overload signatures, ordered narrow to wide so every published signature stays reachable, give each shape its own return; plurality is proven by `NonEmptyReadonlyArray` arity rather than promised over a widened array, and pipe-versus-direct posture is one `Function.dual` definition, never a parallel pair. A closed tagged family dispatches through its own generated surface — `$match`, `$is` — or one exhaustive arm record (`Match.valueTags`, `Match.tagsExhaustive`, `Match.discriminatorsExhaustive` over a foreign field), while structural and predicate dispatch composes `Match` arms whose terminal is the architectural decision: `exhaustive` proves closure, `option` declares the unmatched residue non-failing absence, `either` hands the residue to the next stage as typed material, and a foreign thrown value triages through `Match.instanceOf` arms whose residue only `orElse` may absorb. Per-kind behavior is one mapped handler record dispatched by one generic indexed call, and cross-cutting policy attaches at the `Effect.fn` definition seam, where the pipeline states deadline, resilience, and telemetry in wrap order and every step reads the original call arguments. The named defect this page refuses is surface spam: `resolve`/`resolveMany`/`resolveByKey` siblings, arity twins, suffix families, boolean mode knobs, data-first/data-last twins, dead overloads below a wide signature, consumer-side handler reassembly, policy buried in bodies the declaration owns, and a consumer orchestrating what the owner internalizes — resolving policy, sequencing retries, or wiring telemetry at the call site: a consumer composes outcomes, never operates internals.

## [01]-[FORM_CHOOSER]

When a concern matches several rows, the most specific wins; the rail the arms return is orthogonal to the form and is read after the form is fixed.

| [INDEX] | [CONCERN_SIGNATURE]                      | [FORM]                                         | [REJECTED_FORM]                           |
| :-----: | :--------------------------------------- | :--------------------------------------------- | :---------------------------------------- |
|  [01]   | one concern, several call shapes         | overloaded declaration over one input union    | `resolve` sibling proliferation           |
|  [02]   | plural call shape must prove plurality   | `NonEmptyReadonlyArray` modality               | `batch: boolean` beside a widened array   |
|  [03]   | possibly-empty plural, proof unavailable | wide `ReadonlyArray` overload below the tuple  | batch overload widened to admit empty     |
|  [04]   | closed family, arms local, coverage owed | `$match` / `Match.exhaustive` terminal         | `orElse` fallback absorbing future tags   |
|  [05]   | partial dispatch, residue is absence     | `Match.option` terminal                        | `null` return or sentinel                 |
|  [06]   | staged dispatch, residue flows onward    | `Match.tag`/`Match.tags` arms + `Match.either` | pre-filtered parallel matchers per stage  |
|  [07]   | foreign-field discriminant on the wire   | `Match.discriminatorsExhaustive("<field>")`    | re-tag provider shape before dispatch     |
|  [08]   | foreign thrown value, classed but open   | `Match.instanceOf` ladder + `orElse` residue   | `name` string probe; `as Error` cast      |
|  [09]   | keyed static correspondence              | vocabulary row lookup                          | `Match`/`switch` arms restating the table |
|  [10]   | operator with a pipe subject             | one `Function.dual` definition                 | data-first plus curried twin pair         |
|  [11]   | per-kind behavior owned familywide       | mapped handler record, one generic dispatch    | `switch` per consumer; call-site assembly |
|  [12]   | cross-cutting policy on one function     | `Effect.fn` definition-seam pipeline           | policy hand-woven inside the body         |
|  [13]   | open structural input, no tag            | `Match.when` pattern and refinement arms       | `typeof` ladder with casts                |

## [02]-[ENTRYPOINT_COLLAPSE]

[OVERLOAD_COLLAPSE]:

- Law: one concern exposes one entrypoint; the call-shape family — by key, by batch, by query — is one input union discriminated inside one body, and each shape's return is declared by an overload signature above one wider implementation signature, so value and error channel alike follow the input shape — the sweep that cannot miss drops the fault from its overload — and the sibling family collapses into one name whose next modality lands as one overload line plus one dispatch arm, never a new export.
- Law: overloaded entrypoints use the `function` declaration form — overload signatures tolerate the wider implementation signature there, while a `const` annotated with the same call signatures checks its arrow against every signature simultaneously and forces the cast the declaration form never needs; single-signature operators stay `const` arrows, and the declaration form is earned by the overload set alone.
- Law: overload signatures order strictly narrow to wide because resolution binds the first assignable signature — the non-empty tuple above the wide `ReadonlyArray`, the richer record above its structural supertype — and the compiler never diagnoses an unreachable overload: a wide signature placed first captures every call the narrow one owns and silently degrades its return, while the dead signature below keeps promising a shape no call receives; a published signature earns its line by being reachable, and ordering is the only proof.
- Law: a public conditional-return generic — `<I extends Key | Batch<Key>>(input: I) => I extends Batch<Key> ? Batch<Row> : Row` — states the same per-shape contract, but no implementation body checks against an unresolved conditional, so it compiles only through an `as`; where overloads can carry the shapes, overloads win, and the conditional form retreats to derived type surfaces.
- Law: a concern with a lawful inverse publishes both directions from one owner — decode beside encode, pack beside unpack, acquire beside release — as members of the same assembled surface or overload set, the codec pair's single bidirectional declaration being `shapes.md`'s twin form; a free inverse export beside its forward twin is the sibling family the entrypoint already deletes, because direction is a modality of one concern, never a second concern.
- Law: discrimination reads evidence the value already carries — `Predicate.isString`, a `Predicate.hasProperty` shape probe, a `$is` tag probe — ordered so scalar and record shapes are eliminated before the collection residue, which then splits once through `Array.isNonEmptyReadonlyArray`: that refinement is typed over `ReadonlyArray`, so its true branch is the proven non-empty tuple and its false branch the unproven collection, where a raw `Array.isArray` probe narrows to mutable `Array` and forfeits the `readonly` tuple outright. A `mode` parameter beside the input restates what the value answers: the smuggled knob.
- Exemption: the `function` keyword and its single `return` are the platform seam overload syntax forces; the body stays one expression.

[MODAL_ARITY]:

- Law: the batch modality is `NonEmptyReadonlyArray` — `readonly [A, ...Array<A>]` — so plurality is a fact of the type: the batch overload returns a non-empty result derived by construction (`Array.headNonEmpty` resolves the proven head, `Effect.forEach` sweeps the tail, `[head, ...tail] as const` recombines the tuple), never a claimed plurality the interior must re-prove over a possibly-empty array.
- Law: empty is not a batch — the unproven, possibly-empty collection is its own modality one signature below the tuple, same lookup contract at the honestly weaker return with no non-empty claim, so the caller who cannot prove plurality is served without widening the batch overload to admit empty, which discards non-emptiness for every proven caller at once.
- Boundary: how the swept rail combines — abort versus accumulate — is `rails-and-effects.md`'s disposition and the declared degree is `concurrency.md`'s; this surface owns only the arity discriminant and the shape-following return.

```typescript conceptual
import { Array, Data, Effect, HashMap, Predicate } from "effect";

type Key = string;
type Row = { readonly key: Key; readonly rank: number; readonly label: string };
type Sweep = { readonly floor: number };
type Batch<A> = Array.NonEmptyReadonlyArray<A>;
type Ledger = HashMap.HashMap<Key, Row>;

class Missing extends Data.TaggedError("Missing")<{ readonly key: Key }> {}

const _fetched = (ledger: Ledger, key: Key): Effect.Effect<Row, Missing> => Effect.mapError(HashMap.get(ledger, key), () => new Missing({ key }));

const _swept = (ledger: Ledger, sweep: Sweep): ReadonlyArray<Row> => Array.filter(HashMap.values(ledger), (row) => row.rank >= sweep.floor);

function resolved(ledger: Ledger, input: Key): Effect.Effect<Row, Missing>;
function resolved(ledger: Ledger, input: Batch<Key>): Effect.Effect<Batch<Row>, Missing>;
function resolved(ledger: Ledger, input: ReadonlyArray<Key>): Effect.Effect<ReadonlyArray<Row>, Missing>;
function resolved(ledger: Ledger, input: Sweep): Effect.Effect<ReadonlyArray<Row>>;
function resolved(
    ledger: Ledger,
    input: Key | Batch<Key> | ReadonlyArray<Key> | Sweep,
): Effect.Effect<Row | Batch<Row> | ReadonlyArray<Row>, Missing> {
    return Predicate.isString(input)
        ? _fetched(ledger, input)
        : Predicate.hasProperty(input, "floor")
          ? Effect.succeed(_swept(ledger, input))
          : Array.isNonEmptyReadonlyArray(input)
            ? Effect.zipWith(
                  _fetched(ledger, Array.headNonEmpty(input)),
                  Effect.forEach(Array.tailNonEmpty(input), (key) => _fetched(ledger, key), { concurrency: "inherit" }),
                  (head, tail) => [head, ...tail] as const,
                  { concurrent: true },
              )
            : Effect.forEach(input, (key) => _fetched(ledger, key), { concurrency: "inherit" });
}

// --- [EXPORTS] --------------------------------------------------------------------------

export { Missing, resolved };
export type { Batch, Key, Ledger, Row, Sweep };
```

## [03]-[MATCH_TERMINAL]

[TERMINAL_SELECTION]:

- Law: the `Match` terminal is an architecture decision made by what the unmatched residue means: `Match.exhaustive` is the only terminal for a closed family the module owns — a missing arm is a compile error, so a new tag breaks every dispatch site; `Match.option` declares the residue non-failing absence; `Match.either` keeps the residue as typed material — the left channel carries the narrowed leftover union, so staged dispatch threads stages through `Either` and the next stage's input type is the proof of what remains; `Match.orElse` is lawful only over genuinely open input, because on a closed family the fallback silently absorbs every future tag the exhaustive terminal surfaces; `Match.orElseAbsurd` throws and is rejected outright.
- Law: `Match.withReturnType<Ret>()` composes immediately after `Match.type`/`Match.value` and before the first arm, so every arm is checked against the contract at the arm; placed later it only validates the accumulated union, and a misfit surfaces at the terminal instead of at the offending arm.
- Law: `Match.tag` subtracts exactly and its leading segment is variadic — one arm carries several tags and receives their extracted union; literal and type-refinement patterns subtract the matched shape from the residue, while bare boolean predicates admit without subtracting, so the residue the terminal sees is computed arm by arm and the `either` left type is read, not asserted.
- Law: several structural patterns share one arm through `Match.whenOr`, a conjunction demands `Match.whenAnd`, and a complement arm rides `Match.not` — the hand-written `||`-predicate arm is the deleted spelling: a bare predicate admits without subtracting and forfeits the pattern's payload narrowing.
- Law: structural probes spell as the shipped atoms — `Match.string`, `Match.number`, `Match.boolean`, `Match.bigint`, `Match.symbol`, `Match.date`, `Match.record`, `Match.defined`, `Match.null`, `Match.undefined`, `Match.nonEmptyString`, `Match.is("<value-a>", "<value-b>")` — each a refinement that subtracts, standalone or as a field pattern; the hand lambda restating an atom is a bare predicate, so its arm handles the shape yet leaves it in the residue.

[FOREIGN_TRIAGE]:

- Law: a foreign thrown value crosses the FFI seam as `unknown` and triages through `Match.when(Match.instanceOf(Ctor), arm)` arms into the closed fault family, each arm receiving `InstanceType<Ctor>`; `Match.instanceOf` is a `SafeRefinement` that subtracts nothing from the residue — `instanceof` cannot prove static coverage, a cross-realm instance failing the check its static type passes — so the triage matcher never reaches `exhaustive`, `Match.orElse` is lawful here by the terminal law's own grant over genuinely open input, and the residue arm mints the family's quarantine case.
- Reject: `Match.instanceOfUnsafe`, which subtracts `InstanceType<Ctor>` and deletes the fallback arm the runtime can still reach; a `name` string probe or an `as Error` cast admitting what the ladder proves.
- Boundary: the conversion that consumes this triage — the `catch` slot of `Effect.try`/`Effect.tryPromise` — is `rails-and-effects.md`'s carrier embedding; this page owns the dispatch that types the caught value.

```typescript conceptual
import { Data, Either, Function, Match, type Option, pipe } from "effect";

type Wire =
    | { readonly _tag: "Packet"; readonly body: string }
    | { readonly _tag: "Ack"; readonly seq: number }
    | { readonly _tag: "Nack"; readonly seq: number; readonly cause: string };

const settled: (wire: Wire) => Either.Either<number, Extract<Wire, { _tag: "Packet" }>> = pipe(
    Match.type<Wire>(),
    Match.withReturnType<number>(),
    Match.tag("Ack", "Nack", ({ seq }) => seq),
    Match.either,
);

const measured = (wire: Wire): number => Either.match(settled(wire), { onLeft: ({ body }) => body.length, onRight: Function.identity });

type Probe = { readonly channel: string; readonly score: number } | { readonly raw: string };

const scored: (probe: Probe) => Option.Option<number> = pipe(
    Match.type<Probe>(),
    Match.withReturnType<number>(),
    Match.when({ raw: Match.nonEmptyString }, ({ raw }) => raw.length),
    Match.when({ score: (value: number) => value >= 0.8 }, ({ score }) => score),
    Match.option,
);

class Malformed extends Data.TaggedError("Malformed")<{ readonly detail: string }> {}
class Bounds extends Data.TaggedError("Bounds")<{ readonly detail: string }> {}
class Alien extends Data.TaggedError("Alien")<{ readonly detail: string }> {}

const triaged: (caught: unknown) => Malformed | Bounds | Alien = pipe(
    Match.type<unknown>(),
    Match.when(Match.instanceOf(SyntaxError), (fault) => new Malformed({ detail: fault.message })),
    Match.when(Match.instanceOf(RangeError), (fault) => new Bounds({ detail: fault.message })),
    Match.orElse((residue) => new Alien({ detail: String(residue) })),
);

// --- [EXPORTS] --------------------------------------------------------------------------

export { Alien, Bounds, Malformed, measured, scored, settled, triaged };
export type { Probe, Wire };
```

## [04]-[FAMILY_DISPATCH]

[GENERATED_SURFACE]:

- Law: a `Data.taggedEnum` family dispatches through its own generated surface — `$match` is the total record dispatch, data-first inside generic operations so the family's type parameters stay bound, and `$is` is the reusable refinement every filter and find site narrows through; a `_tag ===` comparison restated per site re-derives what the family already generated.
- Law: a generic family's `taggedEnum` surface is module-interior dispatch vocabulary — the `WithGenerics` factory-call `const` is kind-polymorphic and has no nameable annotation, and the annotation gate reaches the merged name even when only the type is exported, so the constructor lives `_`-prefixed while the family's static type exports under the clean name; dispatch operations export annotated, and a non-generic family exports its constructor under `Data.TaggedEnum.Constructor<Family>` as `shapes.md`'s owner form.
- Law: `$match` computes its result through `Unify`, which reduces registered carriers and strands a bare type parameter — a generic operation's arms settle into `Option`, `Either`, `Effect`, or a concrete shape and the owner folds the carrier at its own seam, while a fold that must return the bare parameter rides `$is` narrowing instead of the record dispatch; outside the generated surface the same reduction is explicit — `Unify.unify` wraps a hand-branched lambda whose arms build sibling instantiations of one carrier and the declaration infers the single unified carrier, the repair living at the owner, never an annotation restated per call site.

[RECORD_FORMS]:

- Law: `Match.valueTags(value, arms)` is the immediate exhaustive record dispatch over an already-held union value — no matcher value is built for a one-shot — and its arm record types excess or misspelled keys `never`, the compile pressure every record form carries.
- Law: `Match.tagsExhaustive(arms)` closes the pipeline as the record terminal over a `_tag` family no generator owns — wire unions, fault classes — and `Match.discriminatorsExhaustive("<field>")(arms)` is the same total record over a family whose discriminant is a foreign field name, dispatching the provider shape without re-tagging it first.
- Law: the record arms stay open — `Match.tags(arms)` adds one handler per covered tag and subtracts exactly its key set, `Match.discriminators("<field>")(arms)` the same over a foreign discriminant — so a staged dispatch keeps record economy across many tags and its residue still reaches `Match.either`/`Match.option`; three or more `Match.tag` arms in one stage collapse into the record arm.
- Law: record form versus pipeline: the record forms (`$match`, `Match.valueTags`, `Match.tagsExhaustive`, `Match.discriminatorsExhaustive`) serve a closed family whose arms are all local — coverage read at a glance; the `Match.type` pipeline builds the reusable dispatch value and serves arms that mix tag, structural, and predicate patterns or a terminal other than exhaustive; `Match.value` opens the same pipeline over one already-held value and earns its matcher only when arms exceed what `valueTags` states in place; `Match.typeTags` restates the `tagsExhaustive` pipeline as a second reusable spelling and is the rejected twin — one concept, one form.
- Boundary: a `Match` whose arms each return a static row restates a keyed table — a keyed correspondence dispatches through the vocabulary lookup the table already is; `Match` owns structural and predicate dispatch on non-keyed shapes.

```typescript conceptual
import { Array, Data, Effect, Match, Number, Option, pipe, Unify } from "effect";

type Signal<A> = Data.TaggedEnum<{
    readonly Live: { readonly value: A };
    readonly Degraded: { readonly value: A; readonly cause: string };
    readonly Halted: { readonly cause: string };
}>;

interface SignalDefinition extends Data.TaggedEnum.WithGenerics<1> {
    readonly taggedEnum: Signal<this["A"]>;
}

const _Signal = Data.taggedEnum<SignalDefinition>(); // interior constructor: the annotation gate reaches the merged name, so only the type exports

const carried = <A>(signal: Signal<A>, fallback: A): A =>
    Option.getOrElse(
        _Signal.$match(signal, {
            // generic arms settle into Option: Unify reduces the carrier where a bare A would strand
            Live: ({ value }) => Option.some(value),
            Degraded: ({ value }) => Option.some(value),
            Halted: () => Option.none(),
        }),
        () => fallback,
    );

const causes = <A>(signals: ReadonlyArray<Signal<A>>): ReadonlyArray<string> =>
    Array.map(Array.filter(signals, _Signal.$is("Halted")), ({ cause }) => cause);

type Frame =
    | { readonly kind: "data"; readonly bytes: number }
    | { readonly kind: "end"; readonly total: number }
    | { readonly kind: "halt"; readonly cause: string };

class Skew extends Data.TaggedError("Skew")<{ readonly size: number }> {}

const _sized: (frame: Frame) => number = pipe(
    Match.type<Frame>(),
    Match.discriminatorsExhaustive("kind")({
        data: ({ bytes }) => bytes,
        end: ({ total }) => total,
        halt: ({ cause }) => cause.length,
    }),
);

const _gated = Unify.unify(
    (
        size: number, // inferred (size: number) => Effect.Effect<number, Skew>: the branch union collapses at the owner
    ) => (size >= 0 ? Effect.succeed(size) : Effect.fail(new Skew({ size }))),
);

const framed = (frame: Frame): Effect.Effect<number, Skew> => _gated(_sized(frame));

type Pulse = { readonly _tag: "Beat"; readonly at: number } | { readonly _tag: "Rest"; readonly span: number };

const spaced: (pulse: Pulse) => number = pipe(
    // the reusable record dispatch: the pipeline terminal earns the matcher value
    Match.type<Pulse>(),
    Match.tagsExhaustive({ Beat: ({ at }) => at, Rest: ({ span }) => span }),
);

const idled = (pulses: ReadonlyArray<Pulse>): number =>
    // one-shot record dispatch over a held value: no matcher value is built
    Number.sumAll(Array.map(pulses, (pulse) => Match.valueTags(pulse, { Beat: () => 0, Rest: ({ span }) => span })));

// --- [EXPORTS] --------------------------------------------------------------------------

export { carried, causes, framed, idled, Skew, spaced };
export type { Frame, Pulse, Signal };
```

## [05]-[DUAL_ENTRY]

[DUAL_DEFINITION]:

- Law: an operator whose first data-first parameter is a pipe subject publishes both postures from one `Function.dual` definition — the data-first body is the single implementation, the `const` annotated with the two call signatures is the published contract, and the parallel curried twin or the consumer adapter lambda `(value) => operator(value, argument)` is the deleted pair.
- Law: the call-signature annotation carries what the body cannot state for the data-last side — the flowing generics and channel unions — and it is simultaneously the explicit export annotation the compiler demands, so one spelling serves contract, gate, and both postures; the `dual<DataLast, DataFirst>` type-argument spelling restates both parameter lists away from the declaration and survives only where no `const` annotation exists.
- Law: posture and modality are orthogonal axes — input modality lives in the entrypoint's input union, posture is one dual over the settled data-first shape; constructors and admission factories have no subject and never dual.

[DISCRIMINANT_SELECTION]:

- Law: arity discriminates when every call shape has a distinct length — `Function.dual(2, body)` routes the two-argument call to data-first; a trailing optional or variadic parameter collides the lengths, so the discriminant becomes a predicate over the first argument — `(args) => Array.isArray(args[0])`, `(args) => Effect.isEffect(args[0])`, a `Predicate.isTagged` probe — answering only whether the first argument is the subject, never selecting behavior: behavior routed through the discriminant is the boolean knob smuggled into the calling convention.
- Law: the predicate reads `IArguments` — the raw call — so it is total over both postures, including the zero-argument data-last call, where `args[0]` is `undefined` and must answer false.

```typescript conceptual
import { Array, Data, Effect, Function, Order } from "effect";

type Row = { readonly key: string; readonly rank: number };

class Ceiling extends Data.TaggedError("Ceiling")<{ readonly rank: number; readonly limit: number }> {}

const _BY_RANK: Order.Order<Row> = Order.mapInput(Order.number, (row: Row) => row.rank);

const gated: {
    (limit: number): <E, R>(self: Effect.Effect<Row, E, R>) => Effect.Effect<Row, Ceiling | E, R>;
    <E, R>(self: Effect.Effect<Row, E, R>, limit: number): Effect.Effect<Row, Ceiling | E, R>;
} = Function.dual(
    2,
    <E, R>(self: Effect.Effect<Row, E, R>, limit: number): Effect.Effect<Row, Ceiling | E, R> =>
        Effect.filterOrFail(
            self,
            (row) => row.rank <= limit,
            (row) => new Ceiling({ rank: row.rank, limit }),
        ),
);

const ranked: {
    (order?: Order.Order<Row>): (self: ReadonlyArray<Row>) => ReadonlyArray<Row>;
    (self: ReadonlyArray<Row>, order?: Order.Order<Row>): ReadonlyArray<Row>;
} = Function.dual(
    (args) => Array.isArray(args[0]),
    (self: ReadonlyArray<Row>, order: Order.Order<Row> = _BY_RANK): ReadonlyArray<Row> => Array.sort(self, order),
);

const swept = (
    probe: (key: string) => Effect.Effect<Row, Ceiling>,
    keys: ReadonlyArray<string>,
    limit: number,
): Effect.Effect<ReadonlyArray<Row>, Ceiling> =>
    Effect.map(
        Effect.forEach(keys, (key) => probe(key).pipe(gated(limit)), { concurrency: "inherit" }), // pipe posture: the operator follows its live subject, no adapter lambda
        ranked(), // zero-argument data-last call: args[0] is undefined, the predicate answers false, the default order applies
    );

// --- [EXPORTS] --------------------------------------------------------------------------

export { Ceiling, gated, ranked, swept };
export type { Row };
```

## [06]-[HANDLER_RECORD]

[RECORD_CONTRACT]:

- Law: per-kind behavior is one record at the owner, keyed by the vocabulary and checked against one mapped contract — `{ readonly [K in Kind]: (payload: Payload[K]) => Rail }` — and dispatch is one generic indexed call, `_HANDLERS[kind](payload)`: the mapped annotation is what resolves the indexed access to a single correlated signature, so the per-kind payload flows through without casts.
- Law: annotation versus `satisfies` is adjudicated by the record's consumer — the record backing a correlated generic dispatch is annotated with its mapped contract, because `satisfies` keeps the inferred per-row function types and the generic indexed call then faces a union of signatures it cannot satisfy; the vocabulary table whose row literals feed derivation takes the anchor form instead, its contract check placed by export reach, because widening is the thing being prevented.
- Law: a new kind is one vocabulary row, one payload field, and one handler row — the mapped contract turns the missing handler into a compile error at the record while every consumer stays untouched; the diff of the next kind never leaves the owner.
- Law: the record and its dispatch publish as one assembled vocabulary owner — interior rows spread in, the dispatch member beside them, companion types on the merged hub — so a consumer imports one name and reaches rows, payloads, receipts, and dispatch; a loose dispatch operation exported beside its table is the split this form deletes.
- Reject: consumer-side reassembly — a call site assembling its own record over exported loose handlers, a `switch` over kinds repeated per consumer, an `Object.keys` iteration re-deriving what `Kind` already is.
- Boundary: the assembled owner's interior anchor, guard pair, and member-pollution trap are `derivation.md`'s vocabulary site; this page owns the handler contract and the dispatch member it publishes.

[INLINE_ATTACHMENT]:

- Law: composition attaches at the row — each handler's admission, guard, and projection compose inside its own row value, and shared per-kind policy is a column on the vocabulary row the handler reads, so behavior variation is data the table already owns, never a wrapper stack applied after the record exists.
- Law: a method record on an owner object is the same law — the object is contract-annotated or `satisfies`-checked at its declaration and never assembled field-by-field afterward; a record built by staged mutation forfeits the missing-key compile error that is the record's reason to exist.

```typescript conceptual
import { Data, Effect } from "effect";

const _rows = {
    // interior row anchor: the discriminant and guards anchor here, never on the assembled owner
    open: { weight: 1, label: "<label-a>" },
    amend: { weight: 2, label: "<label-b>" },
    close: { weight: 4, label: "<label-c>" },
} as const;

declare namespace ROUTE {
    type Kind = keyof typeof _rows; // keyof the assembled owner would drag submit into the kind space
    type Row = { readonly weight: number; readonly label: string };
    type Payload = {
        readonly open: { readonly key: string };
        readonly amend: { readonly key: string; readonly delta: number };
        readonly close: { readonly key: string; readonly seal: string };
    };
    type Receipt = { readonly kind: Kind; readonly weight: number; readonly note: string };
    type Shape = typeof _rows & { readonly submit: <K extends Kind>(kind: K, payload: Payload[K]) => Effect.Effect<Receipt, Refused> };
    type _Rows<T extends Record<Kind, Row> = typeof _rows> = T; // row guard: a malformed or missing row fails at the declaration with zero widening
    type _Slots<K extends Kind = keyof Payload> = K; // key guard: a payload slot outside the vocabulary fails here
}

class Refused extends Data.TaggedError("Refused")<{ readonly kind: ROUTE.Kind; readonly cause: string }> {}

const _receipt = (kind: ROUTE.Kind, note: string): ROUTE.Receipt => ({ kind, weight: _rows[kind].weight, note: `${_rows[kind].label}:${note}` }); // the handler reads its row's policy columns through one projection

const _HANDLERS: { readonly [K in ROUTE.Kind]: (payload: ROUTE.Payload[K]) => Effect.Effect<ROUTE.Receipt, Refused> } = {
    open: ({ key }) => Effect.succeed(_receipt("open", key)),
    amend: ({ key, delta }) =>
        delta === 0 ? Effect.fail(new Refused({ kind: "amend", cause: "<zero-delta>" })) : Effect.succeed(_receipt("amend", `${key}+${delta}`)),
    close: ({ key, seal }) => Effect.succeed(_receipt("close", `${key}:${seal}`)),
};

const ROUTE: ROUTE.Shape = {
    // one exported owner assembles rows and dispatch: a consumer imports ROUTE and reaches everything
    ..._rows,
    submit: (kind, payload) => _HANDLERS[kind](payload), // the generic indexed call rides the contextual signature; the mapped contract keeps it cast-free
};

const _spent: Effect.Effect<ROUTE.Receipt, Refused> = ROUTE.submit("amend", { key: "<key-a>", delta: 2 });

// @ts-expect-error the payload follows the kind: a close seal cannot ride an amend submit
const _drift = ROUTE.submit("amend", { key: "<key-a>", seal: "<seal-a>" });

// --- [EXPORTS] --------------------------------------------------------------------------

export { Refused, ROUTE };
```

## [07]-[ASPECT_SEAM]

[SEAM_PLACEMENT]:

- Law: cross-cutting policy attaches at the `Effect.fn` definition seam — `Effect.fn("<span>")(body, ...pipeline)` — where the name opens a traced span per call and `Effect.fn("<span>", options)` stamps `Tracer.SpanOptions` on the same declaration, the body is the unit an outer retry re-runs, and every pipeline step wraps the whole declaration, so deadline, resilience, and annotation are recoverable by reading the declaration tail; policy woven inside the body, or re-added by a wrapper at the call site, stops being recoverable from the declaration and is the rejected placement.
- Law: every pipeline step receives the original call arguments after the effect — `(effect, ...args)` — so policy parameterizes on the call without threading arguments through the body or closing over module state: a deadline fault carrying the argument's key, log annotation carrying the call's inputs.
- Law: the seam splits by attempt scope — a concern that must observe one attempt composes before the retry step; a concern that must observe the whole call composes after it; the exported annotation on the seam's `const` states the full fault union the stack produces, readable without opening the body.
- Use: `Effect.fnUntraced` where span allocation is a measured cost on a hot path — the same seam and pipeline, no tracer.
- Reject: the nameless `Effect.fn(body)` overload — it opens an `"<anonymous>"` span with propagation disabled, paying the span while losing the seam's identity; the seam is named or it is `Effect.fnUntraced`.
- Boundary: `Schedule` composition algebra, the fault-family taxonomy, and telemetry semantics are `rails-and-effects.md`'s; this page owns only where the policy value attaches and the order it stacks.

[PIPELINE_ORDER]:

- Law: pipeline order is wrap order — the first step is innermost, each later step encloses everything before it — so both resilience geometries are spellable and the declaration states which was chosen; which budget each geometry buys is `rails-and-effects.md`'s layering law, consumed here as settled.
- Law: retry policy is a value — one `Schedule` composed once at the module and referenced by the seam — refined by `while`/`until` on the fault tag so only the transient family re-drives; a hand-rolled retry loop, or a schedule rebuilt inline per declaration, dissolves the policy the value form makes auditable.

```typescript conceptual
import { Data, Effect, Predicate, Schedule } from "effect";

type Quote = { readonly key: string; readonly grade: number };

class Flap extends Data.TaggedError("Flap")<{ readonly key: string }> {}
class Lapse extends Data.TaggedError("Lapse")<{ readonly key: string }> {}

const _PULSE = Schedule.exponential("80 millis").pipe(Schedule.jittered, Schedule.intersect(Schedule.recurs(4)));

const _graded = (key: string): Effect.Effect<Quote, Flap> =>
    key.length === 0 ? Effect.fail(new Flap({ key })) : Effect.succeed({ key, grade: key.length * 8 });

const quoted: (key: string, ceiling: number) => Effect.Effect<Quote, Flap | Lapse> = Effect.fn("<span-a>")(
    function* (key: string, ceiling: number) {
        const quote = yield* _graded(key);
        return quote.grade <= ceiling ? quote : yield* new Flap({ key });
    },
    (effect, key) => Effect.timeoutFail(effect, { duration: "250 millis", onTimeout: () => new Lapse({ key }) }),
    Effect.retry({ schedule: _PULSE, while: Predicate.isTagged("Flap") }),
    (effect, key, ceiling) => Effect.annotateLogs(effect, { key, ceiling }),
);

// --- [EXPORTS] --------------------------------------------------------------------------

export { Flap, Lapse, quoted };
export type { Quote };
```
