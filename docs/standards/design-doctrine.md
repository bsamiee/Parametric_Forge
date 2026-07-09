# [DESIGN_DOCTRINE]

Universal design law for every executable surface: one outcome carrier per computation, one dispatch owner per concern, admitted substrate over reimplementation, variation as data, one boundary crossing, growth by absorption, and executable vocabularies. Each language stack expresses these laws in its own idiom; the laws bind regardless of language.

## [01]-[USE_WHEN]

Apply when writing or reviewing any executable surface — domain logic, boundary adapters, CLIs, configuration programs, schema, infrastructure code — and when adjudicating a design finding against repo doctrine. A finding cites the law it breaks.

## [02]-[RAILS]

A computation chooses one outcome carrier at admission and threads it unchanged to the egress seam. Dependence composes monadically, independence composes applicatively, and the carrier selects the abort, accumulation, absence, context, deferral, lifetime, and retry algebra for the whole flow.

- Rejected: Thrown control flow in domain logic, sentinel-as-failure, boolean status flags, mid-pipeline carrier collapse, dual error paradigms in one surface, first-failure sequencing over independent operands that owe accumulated evidence.
- Accepted: One rail per operation, boundary conversion once, a closed typed fault vocabulary, an absence carrier only for non-failing absence, applicative accumulation for independent validation, collapse only at host, wire, process, UI, or persistence edges.

```typescript conceptual
pipe(Schema.decodeUnknown(Shape)(raw), Effect.flatMap(Shape.run), Effect.map(Receipt.from))
```

## [03]-[DISPATCH]

A concern exposes one polymorphic dispatch surface. Verb, arity, direction, carrier, and modality are discriminants of the input value or the owner family, never sibling names or mode flags, and the consumer composes the returned rail without orchestrating internals.

- Rejected: `get`/`getMany`/`getById` siblings, `create`/`update` function pairs, per-arity overload families, forward/inverse sibling owners, boolean mode knobs, nested dispatch where one joint pattern, table, fold, or owner row states the decision.
- Accepted: One entrypoint per concern, a closed request family for verbs, input-shape discrimination for arity, total match over closed families, vocabulary lookup for keyed correspondences, open extension only at a true foreign or plugin seam.

```csharp conceptual
request.Switch(open: x => ledger.Open(x), amend: x => ledger.Amend(x), close: x => ledger.Close(x));
```

## [04]-[STACKING]

Admitted libraries, platform APIs, generated surfaces, and ecosystem algebras are first-class implementation material; local code composes at the deepest operator level the admitted owner provides.

- Rejected: Hand-rolled reimplementation, provider rename wrappers, helper shells, standard-library reflex where a richer admitted package owns the invariant, consumer-side reassembly of retry, telemetry, codec, validation, derivation, or storage behavior.
- Accepted: Native combinators, generated dispatch, schema derivation, algebra instances, codecs, schedulers, and boundary APIs used directly; provider capability internalized behind the owning local surface only where that preserves provider depth and stops downstream rediscovery.

```python conceptual
catch(exception=OSError)(Path.copy_into)(source, target, **policy).map_error(Fault.io)
```

## [05]-[PARAMETERIZATION]

Variation is data: literals, flags, routes, retries, schedules, codecs, thresholds, directions, and provider choices become policy values, vocabulary rows, algebra instances, derived maps, or carrier swaps. Behavior lives with the vocabulary row that selects it.

- Rejected: Stringly constants, repeated literal-only functions, boolean parameter branches, caller knobs restating input shape, timeout and retry tails on every call, scattered constants mirroring one table, aliases forcing two-hop resolution.
- Accepted: One declarative row per variation, derived logic over enumerated arms, typed evidence on inputs and outputs, symbols and discriminants derived from the owner rather than re-spelled.

```typescript conceptual
const Route = { PRIMARY: { schedule, run } } as const satisfies Record<string, RouteRow>
```

## [06]-[BOUNDARY]

Foreign material crosses once at the seam that first sees it; after admission the interior is total over owned values, typed rails, receipts, policies, and effects. Provider types and exceptions are named only at the seam.

- Rejected: Interior re-validation, leaked provider shapes, raw handles, raw promises, ambient globals, direct driver imports past the seam, parse-reserialize identity, scattered environment reads, broad exception capture as normal control flow.
- Accepted: Decode, validate, marshal, catch, project, and lift exactly once into an evidence-carrying owner; closed fault and state families minted at admission; absence projected into an option only where cause changes no action; encode and project only at egress.

```python conceptual
catch(exception=ValidationError)(Adapter.validate_python)(raw).map_error(Fault.validation)
```

## [07]-[DENSITY]

Capability grows by absorption into the canonical owner: new behavior lands as a case, field, row, policy value, fold, or dispatch arm inside the existing owner, so public surface and file count grow sublinearly. Few deep surfaces beat many shallow ones, and an API break that improves the collapse is taken with every call site updated in the same change.

- Rejected: One-method classes, function and file proliferation, compatibility shims, obsolete aliases, barrel re-exports, forwarding helpers, parallel types sharing identity, admission, payload timing, and consumer.
- Accepted: Owners shaped for the family they absorb, the root owner rebuilt as if the capability always existed, the full domain modeled with consumer count never a design axis.

```csharp conceptual
[Union] public abstract partial record Request { /* a verb is one case, never a sibling method */ }
```

## [08]-[VOCABULARY]

A bounded vocabulary is an executable owner: one declaration carries identity, behavior, policy, derivation anchors, symbolic references, and dispatch totality, and every secondary surface derives from the row set. A new member breaks stale total dispatch mechanically.

- Rejected: Bare enums with external switches, hand-written unions parallel to table keys, string token routing, duplicate constants across schemas, fixtures, handlers, and docs, message-collapsed faults, semantic aliases for one concept.
- Accepted: One vocabulary declaration per concept, rows carrying behavior and policy, secondary types, schemas, maps, handlers, and codecs derived from the rows, canonical bounded-context names throughout.

```python conceptual
ROUTE: frozendict[Route, Policy] = frozendict({Route.PRIMARY: Policy(step=run, attempts=5)})
```
