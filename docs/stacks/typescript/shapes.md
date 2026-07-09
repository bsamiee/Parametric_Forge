# [TYPESCRIPT_SHAPES]

A domain concept takes exactly one runtime authority — a Schema owner whose single declaration is simultaneously the value, the static type, the validator, the constructor, the codec anchor, and the derivation root. Owner-form selection is mechanical over three discriminants read in order — fallibility (the concept is itself a fault travelling the error channel), payload arity (one product or a closed case family), and wire crossing (the concept carries an encoded twin or lives and dies in-process) — after two preconditions route around the chooser: a foreign class instance is admitted by identity through `Schema.instanceOf` or `Schema.declare`, never re-modeled, and self-reference closes through a `Schema.suspend` field inside whichever form wins. The selected form owns everything downstream: the static type derives from the declaration, the wire twin derives from the encoded side, variants and projections derive from the field record, and every free surface — arbitrary, JSON contract, equivalence, pretty-printer, foreign-validator view — derives from the same AST, so one edit site moves the entire family.

The budget is objective, never a count: one rich class family replaces the interface, the DTO, the validator function, the factory, and the scattered branded scalars a naive module mints for one concept, and an owner absorbs a sibling shape the moment the two share an identity regime, an admission path, a payload timing, or a consumer. A second shape is admitted only on a genuinely distinct discriminant that changes implementation law — a new trust boundary, a new identity regime, a new wire dialect; a parallel interface beside an owner, a loose `type` alias sharing an owner's discriminants, a hand-written wire twin, a free-floating brand export, and a shape minted to name an intermediate step are rejected on sight.

## [01]-[OWNER_FORMS]

Choose the owner form before writing any field. The most specific matching row wins.

[FORM_INDEX]:

| [INDEX] | [CONCEPT_SIGNATURE]                                  | [OWNER_FORM]                            | [WIRE]            | [IDENTITY] |
| :-----: | :--------------------------------------------------- | :-------------------------------------- | :---------------- | :--------- |
|  [01]   | named product; invariants, behavior, or 2+ consumers | `Schema.Class`                          | encoded derives   | structural |
|  [02]   | field block embedded in one owner                    | inline `Schema.Struct` record           | inherited         | structural |
|  [03]   | closed case family crossing a wire                   | `Schema.Union` of tagged case owners    | per-case          | `_tag`     |
|  [04]   | closed case family, process-local                    | `Data.taggedEnum`                       | none              | `_tag`     |
|  [05]   | fault crossing a wire, logging, or joining a union   | `Schema.TaggedError`                    | encoded derives   | `_tag`     |
|  [06]   | fault living and dying in-process                    | `Data.TaggedError`                      | none              | `_tag`     |
|  [07]   | computation outcome crossing a wire                  | `Schema.Exit` / `Schema.Cause` envelope | per-channel       | `_tag`     |
|  [08]   | request carrying its own reply contract              | `Schema.TaggedRequest` case owner       | per-channel       | `_tag`     |
|  [09]   | scalar invariant                                     | brand-in-field refinement               | inherited         | value      |
|  [10]   | self-referential product or family                   | host form + `Schema.suspend` reference  | encoded derives   | structural |
|  [11]   | foreign class instance at the seam                   | `Schema.instanceOf` / `Schema.declare`  | none (`FromSelf`) | reference  |
|  [12]   | one concept, N systematic storage or wire views      | `VariantSchema.make` field family       | per-variant       | structural |
|  [13]   | patch, intake, or view of an owner                   | derived projection, never declared      | derives           | inherited  |

[OWNER_SELECTION]:
- Law: named products take `Schema.Class` regardless of wire exposure — the class costs one identifier string over the `Data.Class` form and gains decode, encode, `make` validation, and the whole derived-surface family the moment any consumer needs them; `Data.Class` and `Data.Case` are rejected product forms because a second product paradigm buys nothing the Schema form lacks.
- Law: the `Data`-versus-`Schema` split is earned only for case families, where the Schema form costs a class per case — a family that never serializes, never logs structurally, and never joins a decoded union is `Data.taggedEnum`; any family that might is declared wire-carried from the start, because a `Data.taggedEnum` cannot reach a wire and promotion rewrites every case construction site.
- Law: inside a wire-carried union, a case with behavior is `Schema.TaggedClass` and a pure-data case is `Schema.TaggedStruct` — the union mixes both freely, and behavior arriving later converts a struct case to a class case with zero consumer edits, because tag and fields are unchanged and construction rides `.make` on both forms.
- Law: a case that carries its own reply contract — payload, success, and failure schemas in one declaration — is `Schema.TaggedRequest`, and its structural `Equal` over the payload fields is the dedup identity the batching seam consumes; the declaration form is this chooser's row, while the executing surfaces — worker protocol, resolver window — are `boundaries.md`'s and `streams.md`'s.
- Law: `Schema.Struct` survives only as row [02] — an anonymous field block embedded in one owner or a single-consumer contract; a passed-around `Struct` promoted to a `Class` later re-anchors every consumer, so a concept with a name is declared as a class first, never migrated to one.
- Reject: a one-field class wrapping a scalar row [09] already refines; an `interface` or `type` alias declared beside any owner; a shape triple minted per architectural layer; a boolean-discriminated pair standing where row [03] or [04] owns the family.

[SHAPE_ECONOMY]:
- Law: absorption is the collapse test — two shapes sharing an identity regime, an admission path, a payload timing, or a consumer are one owner, the junior absorbed as a case, a variant column, a derived projection, or an embedded field block; survival demands a distinct discriminant the chooser table names, and the bare struct-shaped `interface` beside any owner is the rejected floor regardless of how many consumers it accreted.
- Law: growth lands inside the owner as a row — a field, a getter, a case, a variant column, a refinement — and the diff of the next requirement is the proof: one declaration inside the owner, consumers untouched or broken loudly at the missing arm.
- Law: a refinement shared by two owners is one `_`-prefixed interior field schema composed into both field records and exported by neither; the brand reaches consumers only through owner fields — `Shape["key"]` indexed access, instance reads — so the refinement has one edit site and zero standalone dependents.
- Law: identity is carried, not written — Schema class instances and `Data.taggedEnum` cases compare structurally under `Equal.equals` and hash by value from the declaration alone, while a `Schema.TaggedStruct` case or inline `Struct` block decodes to a plain record outside that contract — container keying selects the class form or wraps the block in `Schema.Data`; a hand-written `equals` method or an identity field added for comparison is dead surface.

## [02]-[RICH_OWNER]

The rich owner is one `Schema.Class<Self>(identifier)(fields)` declaration: the class is the value, the type, the decode anchor, and the constructor under a single name, so a consumer takes one import and never aliases, re-derives, or writes `typeof` at a call site.

[RICH_OWNER_LAW]:
- Law: brands ride fields — `Schema.NonEmptyString.pipe(Schema.pattern(/.../), Schema.brand("<key>"))` declared at the field or as the shared interior schema; the branded type exists only through the owner, and a standalone exported brand is the named defect.
- Law: every derived reading is a class getter composing the algebra the fields admit, and the algebra instance itself rides the owner as a `static` — `Anchor.byWeight` — so policy and owner arrive through one import; a free function re-deriving what a getter states, a loose comparator const beside the class, or a consumer computing either at the call site marks the missing member.
- Law: an embedded concept with its own invariants is its own class composed as a field at full depth — `Schema.NonEmptyArray(Anchor)` — never flattened into prefixed sibling fields; the inline `Struct` block is the sub-form only while the block has no behavior and no second consumer.
- Law: a field whose invariant `values.md` owns is admitted as that owner at the field — `Schema.HashMap({ key, value })`, `Schema.HashSet`, `Schema.Chunk`, `Schema.SortedSet`, `Schema.DateTimeUtc`, `Schema.Duration`, `Schema.BigDecimal`, `Schema.Redacted` — so the decoded interior holds the keyed, ordered, temporal, exact, or sealed primitive directly; a plain array or string field every consumer rebuilds into the real container is the admission the field skipped.
- Law: lineage derives, siblings never re-declare — `Owner.extend<Wider>(identifier)(fields)` widens into a subtype carrying every base field, getter, and refinement; `Owner.transformOrFail<Enriched>(identifier)(fields, { decode, encode })` derives an owner whose added fields compute from the base at decode; a second class restating base fields is the defect these two forms exist to kill.
- Law: `new Owner(...)` and `Owner.make(...)` run the filter set, so trusted interior construction proves the same invariants decode proves; raw material enters through decode at the admission seam — placement is `boundaries.md`'s — and `{ disableValidation: true }` survives only inside a kernel that already proved the invariant it skips.
- Reject: an `interface`-plus-implementation pair; a DTO type beside the class; constructor parameter properties; a `with<Field>` copy-method family restating what a successor constructor or derived projection owns.

```typescript
import { Array, Option, Order, Schema } from "effect"

const _Key = Schema.NonEmptyString.pipe(                      // interior refinement: the brand reaches consumers only as Shape["key"], never a standalone export
  Schema.pattern(/^[a-z][a-z0-9-]*$/),
  Schema.brand("<key>"),
)

class Anchor extends Schema.Class<Anchor>("Anchor")({
  axis: Schema.Literal("<axis-a>", "<axis-b>"),
  weight: Schema.Number.pipe(Schema.between(0, 1)),
}) {
  static readonly byWeight: Order.Order<Anchor> = Order.mapInput(Order.number, (anchor: Anchor) => anchor.weight)
}

class Shape extends Schema.Class<Shape>("Shape")({
  key: _Key,
  rank: Schema.Int.pipe(Schema.between(0, 9)),
  anchors: Schema.NonEmptyArray(Anchor),                      // non-emptiness is a type fact: Array.max below is total, no fallback arm
  note: Schema.optionalWith(Schema.NonEmptyString, { as: "Option" }),
}) {
  get strongest(): Anchor {
    return Array.max(this.anchors, Anchor.byWeight)
  }
  get caption(): string {
    return Option.match(this.note, {
      onNone: () => this.key,
      onSome: (note) => `${this.key}: ${note}`,
    })
  }
}

class Sealed extends Shape.extend<Sealed>("Sealed")({
  seal: Schema.UUID,
}) {
  get receipt(): string {
    return `${this.caption}#${this.seal}`
  }
}

// --- [EXPORTS] --------------------------------------------------------------------------

export { Anchor, Sealed, Shape }
```

[RECURSIVE_OWNER]:
- Law: a self-referential field closes through `Schema.suspend((): Schema.Schema<Owner, OwnerEncoded> => Owner)` — the lazy reference breaks the module-initialization cycle an eager mention would crash, and the return annotation is mandatory because inference cannot fix a type that mentions itself.
- Law: the suspend annotation is the one sanctioned hand-stated encoded twin — an interior `interface OwnerEncoded` exists solely to state what inference cannot close, stays unexported, and `typeof Owner.Encoded` remains the twin every consumer reads; everywhere else the hand-declared twin stays the named defect.
- Law: a family whose cases contain the family is the same form threaded through the member — the recursive arm of the `Schema.Union` is the suspended owner, and folds over the tree are getters on the case classes, total by construction.
- Reject: an eager self-reference (`ReferenceError` at module load); `Schema.Any` standing where the suspended reference belongs; a depth-limited copy family — `Shape1`, `Shape2` — unrolling what one suspended owner closes.

```typescript
import { Array, Schema } from "effect"

class Leaf extends Schema.TaggedClass<Leaf>()("Leaf", {
  key: Schema.NonEmptyString,
  weight: Schema.NonNegative,
}) {}

interface GroupEncoded {
  readonly _tag: "Group"
  readonly key: string
  readonly members: ReadonlyArray<typeof Leaf.Encoded | GroupEncoded>
}

class Group extends Schema.TaggedClass<Group>()("Group", {
  key: Schema.NonEmptyString,
  members: Schema.Array(Schema.Union(Leaf, Schema.suspend((): Schema.Schema<Group, GroupEncoded> => Group))),
}) {
  get span(): number {
    return Array.reduce(this.members, 0, (total, member) => total + (member._tag === "Leaf" ? 1 : member.span))
  }
}

// --- [EXPORTS] --------------------------------------------------------------------------

export { Group, Leaf }
```

## [03]-[TAGGED_FAMILIES]

A closed family is one owner under one name; the `_tag` is simultaneously the runtime discriminant, the wire discriminant, and the dispatch key, so exactly one spelling of case identity exists.

[CASE_FAMILIES]:
- Use: `type Variant = Data.TaggedEnum<{...}>` plus `const Variant: Data.TaggedEnum.Constructor<Variant> = Data.taggedEnum<Variant>()` — the same name serves the union type, the case constructors, `$is`, and `$match`, so declaration, construction, guarding, dispatch, and typing are one import.
- Law: case payloads are `readonly` fields and a payload-free case is `{}`; constructors carry structural equality, so family members compare by value with no identity ceremony.
- Law: a generic family rides `Data.TaggedEnum.WithGenerics` with a definition interface — never a hand-parameterized union restating the case algebra per type argument.
- Law: a wire-carried family is `Schema.Union` over tagged case owners bound to one same-name `const`-plus-`type` pair, and the member set is the single growth site — a new case is one class plus the union row, with every exhaustive consumer breaking loudly until its arm exists.
- Law: a foreign wire that ships its cases untagged gains the discriminant at the declaration — each member pipes `Schema.attachPropertySignature("_tag", "<case>")` inside the union, the key exists only on the decoded side, and encode drops it, so the interior dispatches one tagged family while the wire stays as the provider ships it.
- Law: vocabulary literals spread from the value anchor — `Schema.Literal(..._Stage)` derives the schema arm from the same `as const` table the type level derives from, so the vocabulary has one row set and zero parallel spellings; the tuple-overload mechanics are `derivation.md`'s.
- Boundary: `$match` is the family's carried dispatch surface; terminal selection between exhaustive, option, and either forms is `surfaces-and-dispatch.md`'s.
- Reject: sibling schemas per case with no union owner; a string-typed `status` field where a case family owns the states; a `kind` field beside `_tag`; a class hierarchy dispatched by `instanceof`.

[FAULT_DECLARATION]:
- Use: `Schema.TaggedError<Self>()(tag, fields)` for a fault that crosses a wire, logs structurally, or joins a decoded union — one class is the fault value, the fault schema, and the `_tag` catch key, and the instance is yieldable on the rail.
- Law: the in-process fault is `Data.TaggedError("<tag>")<Fields>` — the same `_tag` catch key and yieldable instance at zero codec cost; the wire test is the one case families answer, and promotion to the Schema form rewrites only the declaration, because `new Fault({ ... })` construction is identical on both.
- Law: fields carry evidence as data — the refused key, the stage, retryability, severity — typed so policy reads them; `message` is a derived `override get` computed from fields and never a stored field, because a message field is denormalized evidence that drifts from what the fields prove.
- Boundary: fault-family architecture — the family-per-surface partition, reason discriminants, policy folds, catch routing — is `rails-and-effects.md`'s; this page owns the declaration form.
- Reject: `class Fault extends Error`; evidence baked into message strings; a fault union assembled from untagged shapes.

```typescript
import { Schema } from "effect"

const _Stage = ["<stage-a>", "<stage-b>", "<stage-c>"] as const // interior vocabulary: consumers read ShapeFault["stage"], so the row set has one edit site

const Opened = Schema.TaggedStruct("Opened", {
  key: Schema.NonEmptyString,
  at: Schema.DateTimeUtc,
})

class Closed extends Schema.TaggedClass<Closed>()("Closed", {
  key: Schema.NonEmptyString,
  at: Schema.DateTimeUtc,
  total: Schema.NonNegative,
}) {
  get summary(): string {
    return `${this.key}=${this.total}`
  }
}

const Journal: Schema.Union<[typeof Opened, typeof Closed]> = Schema.Union(Opened, Closed)
type Journal = typeof Journal.Type

const _Ping = Schema.Struct({ at: Schema.Number }).pipe(Schema.attachPropertySignature("_tag", "Ping"))
const _Pong = Schema.Struct({ at: Schema.Number, echo: Schema.NonEmptyString }).pipe(Schema.attachPropertySignature("_tag", "Pong"))

const Beat: Schema.Union<[typeof _Ping, typeof _Pong]> = Schema.Union(_Ping, _Pong) // the attached _tag exists only decoded: encode drops it, the wire stays as the provider ships it
type Beat = typeof Beat.Type

class ShapeFault extends Schema.TaggedError<ShapeFault>()("ShapeFault", {
  key: Schema.NonEmptyString,
  stage: Schema.Literal(..._Stage),
  retryable: Schema.Boolean,
}) {
  override get message(): string {
    return `<${this.stage}> refused ${this.key}`
  }
}

// --- [EXPORTS] --------------------------------------------------------------------------

export { Beat, Journal, ShapeFault }
```

## [04]-[ABSENCE]

The interior never meets `?:`, `undefined`, or `null`: `Schema.optionalWith(S, { as: "Option" })` is the sole absence spelling on a decoded field — total `Option<A>` on the type side, optional on the encoded side — and every wire dialect folds into that one interior shape at the declaration.

[ABSENCE_LAW]:
- Law: the options row selects the wire dialect, never the interior type — `{ as: "Option", nullable: true }` folds absent-or-null to none, with `onNoneEncoding: () => Option.some(null)` when the wire demands an explicit null on write; `{ as: "Option", exact: true }` when key absence alone spells absence; `Schema.OptionFromNullOr(S)` when the key is always present and null is the absence value. Four dialects, one `Option<A>` field.
- Law: `{ default: () => value }` versus `as: "Option"` is ownership of the fallback — default when the owner fixes the value and no consumer distinguishes absent from defaulted; `Option` when the consumer decides; a defaulted field is total and plain in the interior, and `Option.getOrElse` repeating one fallback across consumers marks a default that belonged in the declaration.
- Law: absence with a cause is a tagged family — `Option.none()` carries zero evidence, so the moment two causes of absence exist the field is a case family whose cases carry their cause, and `Option` survives only as the cause-free projection the owner carries as a member — attached to the family constructor, never exported beside it, and one-directional: the family sheds cause down to `Option`, never rebuilds from it, because a shed cause cannot be recovered.
- Reject: bare `Schema.optional` (leaks `| undefined` into the decoded type); `Schema.NullOr` on a domain field; sentinel values standing for absence; a boolean `has`-twin beside a nullable field.

```typescript
import { Data, Option, Schema } from "effect"

type Presence = Data.TaggedEnum<{
  Held: { readonly value: string }
  Redacted: { readonly until: number }
  Withdrawn: { readonly reason: string }
}>
const _Presence = Data.taggedEnum<Presence>()
const Presence: Data.TaggedEnum.Constructor<Presence> & {
  readonly revealed: (presence: Presence) => Option.Option<string>
} = {
  ..._Presence,
  revealed: (presence) =>
    _Presence.$match(presence, {
      Held: ({ value }) => Option.some(value),
      Redacted: () => Option.none(),
      Withdrawn: () => Option.none(),
    }),
}

class Slot extends Schema.Class<Slot>("Slot")({
  label: Schema.optionalWith(Schema.NonEmptyString, {
    as: "Option",
    nullable: true,
    onNoneEncoding: () => Option.some(null),
  }),
  alias: Schema.optionalWith(Schema.NonEmptyString, { as: "Option", exact: true }),
  weight: Schema.optionalWith(Schema.Number, { default: () => 1 }),
  tint: Schema.OptionFromNullOr(Schema.NonEmptyString),
}) {
  get title(): string {
    return Option.getOrElse(
      Option.orElse(this.label, () => this.alias),
      () => "<untitled>",
    )
  }
}

// --- [EXPORTS] --------------------------------------------------------------------------

export { Presence, Slot }
```

## [05]-[WIRE_TWINS]

The wire twin derives: `typeof Owner.Encoded` is the wire type, `Schema.encodedSchema(Owner)` materializes it as a schema, and a hand-declared wire interface beside an owner is the named defect. Divergence between wire and domain lands inside the owner declaration, graded by severity.

[WIRE_TWIN_LAW]:
- Law: spelling divergence is a field-level rename — `Schema.propertySignature(S).pipe(Schema.fromKey("<foreign-name>"))` inside the field record, so the decoded side carries canonical names, the encoded side carries the foreign spelling, and no parallel rename map or mapping layer exists.
- Law: structural divergence is one bidirectional declaration — `Schema.transform(From, To, { strict: true, decode, encode })` when total, `Schema.transformOrFail` returning `ParseResult.succeed` or `ParseResult.fail(new ParseResult.Type(ast, actual, "<why>"))` when partial; both directions declare at one site, and the `To` side's own refinements re-prove after the mapping runs, so a transform moves spelling and structure but never restates validation.
- Law: `Schema.parseJson(Owner)` fuses `JSON.parse` and `JSON.stringify` into the codec — raw JSON string to owner is one decode and owner to string is one encode; a `JSON.parse` call beside a decode is the named defect, and the fused schema composes anywhere a schema does.
- Law: every derived twin rides the owner as a `static` — `Owner.FromPacked`, `Owner.FromJson`, `Owner.Outcome` — with its type companion on the owner's merged `declare namespace` (`Owner.Wire` as `typeof Owner.Encoded`), so the whole wire vocabulary travels the owner's single import; a codec const or a prefixed `<Owner>Wire` alias exported beside the class is the scatter the static kills.
- Boundary: decode and encode execution — `Schema.decodeUnknown` placement, `ParseError` lifting — is `boundaries.md`'s; this page owns the twin's declaration.
- Reject: hand-written `toWire`/`fromWire` method pairs; a codec class beside an owner; two one-directional transforms for one twin; a version branch inside the owner where a read-boundary migration owns it.

[OUTCOME_TRANSPORT]:
- Law: a computation outcome crossing a wire is `Schema.Exit({ success, failure, defect })` — success carries the owner, failure carries the fault family, `Schema.Defect` normalizes thrown junk into transportable form, and the decoded side is a real `Exit.Exit<A, E>` a consumer folds with the ordinary outcome algebra; a hand-rolled `{ ok: boolean }` envelope re-invents that fold untyped.
- Law: `Schema.Cause({ error, defect })` transports the failure tree alone — interruption, defects, and composed failures survive the wire, so a remote failure reconstructs with its forensic structure intact instead of flattening to a message string.
- Law: the `FromSelf` twins — `Schema.ExitFromSelf`, `Schema.CauseFromSelf` — compose inside owners whose encoded side stays in-process; the plain forms own the JSON-bound envelope.
- Reject: a fault serialized as its `message` string; a bespoke result union restating what `Exit` already algebrizes.

```typescript
import { ParseResult, Schema } from "effect"

class GradeFault extends Schema.TaggedError<GradeFault>()("GradeFault", {
  key: Schema.NonEmptyString,
  retryable: Schema.Boolean,
}) {}

class Grade extends Schema.Class<Grade>("Grade")({
  key: Schema.propertySignature(Schema.NonEmptyString).pipe(Schema.fromKey("grade_key")),
  score: Schema.propertySignature(Schema.Int.pipe(Schema.between(0, 100))).pipe(Schema.fromKey("grade_score")),
}) {
  get passed(): boolean {
    return this.score >= 60
  }
  static readonly FromPacked: Schema.transformOrFail<typeof Schema.NonEmptyString, typeof Grade> = Schema.transformOrFail(Schema.NonEmptyString, Grade, {
    strict: true,
    decode: (packed, _, ast) => {
      const at = packed.lastIndexOf("@")
      return at < 0
        ? ParseResult.fail(new ParseResult.Type(ast, packed, "<missing-separator>"))
        : ParseResult.succeed({
            grade_key: packed.slice(0, at),
            grade_score: Number(packed.slice(at + 1)), // a garbage score is not the transform's problem: Schema.Int re-proves on the decoded side
          })
    },
    encode: (wire) => ParseResult.succeed(`${wire.grade_key}@${wire.grade_score}`),
  })
  static readonly FromJson: Schema.SchemaClass<Grade, string> = Schema.parseJson(Grade)
  static readonly Outcome: Schema.Exit<typeof Grade, typeof GradeFault, typeof Schema.Defect> = Schema.Exit({
    success: Grade,
    failure: GradeFault,
    defect: Schema.Defect,
  })
}

declare namespace Grade {
  type Wire = typeof Grade.Encoded
  type Outcome = Schema.Schema.Type<typeof Grade.Outcome>
}

// --- [EXPORTS] --------------------------------------------------------------------------

export { Grade, GradeFault }
```

## [06]-[VARIANT_DERIVATION]

When one concept systematically projects into N storage or wire views, the variant axis is data: `VariantSchema.make({ variants, defaultVariant })` yields a field-family kit — `Class`, `Field`, `FieldOnly`, `FieldExcept`, `fieldFromKey`, `fieldEvolve`, `Union`, `extract` — and one declaration emits every variant schema.

[VARIANT_FAMILY]:
- Law: per-field modality declares where a field exists — a plain schema field rides every variant, `Field({ "<variant>": S })` enumerates, `FieldOnly("<variant>")(S)` restricts, `FieldExcept("<variant>")(S)` subtracts; a generated column is `FieldOnly` on read variants, a secret is `FieldExcept` on egress variants, and the field record is the single site stating the whole matrix.
- Law: the class decodes the default variant and carries every variant as a same-name static — `Row.insert`, `Row.json` — with `extract(Row, "<variant>")` as the computed access when the variant is selected at runtime; a new variant is one tuple entry plus the per-field rows it changes, never a new shape, and a loose `const` re-binding a variant static is the beside-export defect.
- Law: the kit's derived tier keeps the matrix data — `fieldFromKey(field, { "<variant>": "<wire-key>" })` respells one variant's encoded key where dialects disagree, `fieldEvolve` maps an existing field family into a successor per variant, and the kit's `Union` assembles a tagged family whose per-variant member unions ride the union value as variant-named statics — so a second field family hand-derived from the first is the parallel-shape defect.
- Law: a value the system produces unless the caller decides is `VariantSchema.Overrideable(from, to, { generate, decode })` on the write variant — `generate` folds the caller's `Option` (`onNone` produces on the rail, `onSome` accepts), construction marks intent with `VariantSchema.Override(value)`, and read variants stay plain — generate-unless-overridden semantics live in the field record, never in a nullable column patched at call sites.
- Law: `VariantSchema` ships from `@effect/experimental` under the central-manifest pin; every use stays behind the owner class, so a release move lands at one declaration and no consumer imports the package surface directly.
- Law: a hand-declared per-variant struct family is the named defect — N parallel shapes restating one concept, each a drift site the field family makes structurally impossible.
- Boundary: the systematic axis belongs here; a one-off view derives through the projection forms of the derived-surfaces section, and a `pick`/`omit` chain rebuilding what a variant matrix states is the inverted choice.
- Reject: variant divergence handled by optional fields on one wide shape; a secret scrubbed at egress call sites instead of subtracted at the field; a write-side default re-implemented as a nullable column.

```typescript
import { VariantSchema } from "@effect/experimental"
import { DateTime, Effect, Option, Redacted, Schema } from "effect"

const { Class, Field, FieldExcept, FieldOnly, fieldFromKey } = VariantSchema.make({
  variants: ["select", "insert", "json"],
  defaultVariant: "select",
})

const _RevisedWithNow = VariantSchema.Overrideable(Schema.String, Schema.DateTimeUtcFromSelf, {
  generate: Option.match({
    onNone: () => Effect.map(DateTime.now, DateTime.formatIso),
    onSome: (stamp) => Effect.succeed(DateTime.formatIso(stamp)),
  }),
  decode: Schema.DateTimeUtc,
})

class Row extends Class<Row>("Row")({
  id: FieldOnly("select", "json")(Schema.Int),                // generated column: absent from the insert wire by declaration
  key: Schema.NonEmptyString,
  secret: FieldExcept("json")(Schema.Redacted(Schema.String)), // subtracted at the field: no json egress site can leak it
  revised: fieldFromKey(
    Field({
      select: Schema.DateTimeUtc,
      insert: _RevisedWithNow,
      json: Schema.DateTimeUtc,
    }),
    { insert: "revised_at" },                                 // per-variant wire spelling: the insert dialect alone respells the key
  ),
}) {
  static backdated(stamp: DateTime.Utc, key: string, secret: string): typeof Row.insert.Type {
    return Row.insert.make({
      key,
      secret: Redacted.make(secret),
      revised: VariantSchema.Override(stamp),
    })
  }
}

// --- [EXPORTS] --------------------------------------------------------------------------

export { Row }
```

## [07]-[FOREIGN_ADMISSION]

A foreign class is admitted by identity, never re-modeled: `Schema.instanceOf` and `Schema.declare` extend the AST to values the schema world does not construct, and the admission is complete only when the declaration carries the annotations that keep every derived surface total.

[FOREIGN_OWNERS]:
- Use: `Schema.instanceOf(Ctor, { identifier, arbitrary, pretty })` admits a constructor-carrying foreign class — the schema is `FromSelf`: type and encoded side are both the live instance, so no wire twin exists and the value never pretends to serialize; deletes the interface hand-mirroring a foreign class's fields.
- Law: a foreign value with no reachable constructor takes the guard form `Schema.declare((input: unknown): input is Shape => ..., annotations)`; the parameterized form `Schema.declare(typeParameters, { decode, encode }, annotations)` owns foreign containers over schema type parameters and is the form the shipped `*FromSelf` containers are built on.
- Law: derivation totality is bought at the declaration — `Arbitrary.make` and `Pretty.make` throw `Missing annotation` at first derivation over a bare declaration, while `Schema.equivalence` silently falls back to `Equal.equals`, which on a foreign instance that never implanted `Equal` is reference identity; the loud pair polices itself, the silent one is the audit line, so a foreign owner is admitted with its annotation set complete or not at all.
- Law: a foreign class the ecosystem already owns is taken from the shelf — `Schema.URLFromSelf`, `Schema.Uint8ArrayFromSelf`, `Schema.DateFromSelf`, `Schema.DateTimeUtcFromSelf` — and re-declaring one is the wrapper defect.
- Law: a foreign instance crosses a wire only through a composed twin — `Schema.transform` from an encodable schema onto the `FromSelf` owner, declared once beside it; absent that twin the foreign value is process-bound by construction.
- Reject: `Schema.Unknown` smuggling a foreign instance past the seam; a standalone `is`-guard function beside a schema that owns it; an `as` cast where the declaration proves identity.

```typescript
import { Arbitrary, FastCheck, Pretty, Schema } from "effect"

declare class Handle {
  readonly id: number
  constructor(id: number)
}

const HandleFromSelf = Schema.instanceOf(Handle, {           // a first-class AST citizen: composes as a field, joins unions, feeds every derived surface
  identifier: "HandleFromSelf",
  arbitrary: () => (fc) => fc.integer({ min: 1 }).map((id) => new Handle(id)),
  pretty: () => (handle) => `Handle(${handle.id})`,
})

const _sample: FastCheck.Arbitrary<Handle> = Arbitrary.make(HandleFromSelf)
const _shown: (handle: Handle) => string = Pretty.make(HandleFromSelf)

// --- [EXPORTS] --------------------------------------------------------------------------

export { HandleFromSelf }
```

## [08]-[DERIVED_SURFACES]

Every free surface derives from the owner's AST, and every ad-hoc view derives from the owner's field record; a hand-maintained parallel of either is the named defect.

[DERIVED_INSTANCES]:
- Law: the derivation set is `Arbitrary.make(Owner)` yielding a `FastCheck.Arbitrary<Owner>`, `JSONSchema.make(Owner)` yielding a `JSONSchema.JsonSchema7Root`, `Pretty.make(Owner)`, `Schema.equivalence(Owner)` yielding an `Equivalence.Equivalence<Owner>`, `Schema.is(Owner)` as the derived guard, and `Schema.standardSchemaV1(Owner)` as the one view handed to foreign validation consumers — a hand-written generator, printer, comparator, guard, JSON contract, or parallel validator beside an owner restates what the AST already proves.
- Law: field refinements are what keep derived surfaces truthful — `between`, `maxLength`, `pattern`, and brands flow into generation and contract emission, so a refinement skipped at the field surfaces downstream as a lying arbitrary and an under-constrained contract.
- Law: derived instances are `_`-prefixed interior consts at the owner module, exported only on cross-module demand — the owner is the export; its derivations are its interior.

[ANNOTATIONS]:
- Law: identity is positional on class owners — `Schema.Class<Self>("<identifier>")` — and `.annotations({ identifier })` on schema values; `JSONSchema.make` keys `$defs` by it and parse issues name it, so an owner without identity emits anonymous contracts and unattributable failures.
- Law: parse forensics attach at the declaration — a field-level `Schema.annotations({ message })` owns the refusal text where the filter lives, `parseIssueTitle` scopes the owner's issue headline, and `decodingFallback` declares read-side degradation as policy — recovery visible at the owner, never a `try`/`catch` at call sites.
- Law: `jsonSchema`, `arbitrary`, `pretty`, and `equivalence` annotations override derivation only where a filter cannot express the bound — a constraint expressible as `between`/`maxLength`/`pattern` rides the field, and every derived surface stays truthful for free; `title`/`description`/`examples` are contract documentation earned by wire-published owners.
- Reject: refusal text assembled at call sites; a documentation file restating what owner annotations emit; an `arbitrary` override standing where a filter states the bound.

[PROJECTIONS]:
- Law: a projection re-anchors on the field record — `Schema.Struct(Owner.fields)` then `Schema.pick(...)`, `Schema.omit(...)`, `Schema.partialWith({ exact: true })`, `Schema.extend(...)` — because the class node is a transformation and its projections derive from its fields, not from the class itself.
- Law: a patch is `omit` of identity then `partialWith({ exact: true })` — absent means unchanged, the exact form emits `?:` without `| undefined`, and a patch that can address a different aggregate or spell set-to-undefined is a wrong shape, not a caller error.
- Law: a projection never gains authority — it carries no field the owner lacks, and a value reaching a wire outside any owner field marks a missing owner field, not a projection to widen.
- Law: a projection with a second consumer rides the owner as a `static` with its type on the owner's merged namespace — `Owner.Patch`, `Owner.Badge` — so one import carries the owner and every view; a prefixed sibling export is the scatter, and a single-use projection derives at its use site and is stored nowhere.
- Reject: a hand-declared patch or request interface; `Schema.partial` where the exact form is meant; a stored projection type restating what a one-line derivation states at the use site.

```typescript
import { Arbitrary, Either, type Equivalence, FastCheck, JSONSchema, Pretty, Schema } from "effect"

class Member extends Schema.Class<Member>("Member")({
  key: Schema.UUID,
  label: Schema.NonEmptyString.pipe(
    Schema.maxLength(64),
    Schema.annotations({ message: () => ({ message: "<why-refused>", override: false }) }),
  ),
  score: Schema.Number.pipe(
    Schema.between(0, 1),
    Schema.annotations({ decodingFallback: () => Either.right(0) }),
  ),
}, {
  title: "<title-a>",
  parseIssueTitle: () => "<issue-scope>",
}) {
  static readonly Patch = Schema.Struct(Member.fields).pipe(
    Schema.omit("key"),
    Schema.partialWith({ exact: true }),
  )
  static readonly Badge = Schema.Struct(Member.fields).pipe(Schema.pick("key", "label"))
}

declare namespace Member {
  type Patch = Schema.Schema.Type<typeof Member.Patch>
  type Badge = Schema.Schema.Type<typeof Member.Badge>
}

const _cohort: FastCheck.Arbitrary<Member> = Arbitrary.make(Member) // eight surfaces off one declaration — Patch, Badge, and this six-instance cluster — every one moves when a field moves
const _same: Equivalence.Equivalence<Member> = Schema.equivalence(Member)
const _shown: (member: Member) => string = Pretty.make(Member)
const _contract: JSONSchema.JsonSchema7Root = JSONSchema.make(Member)
const _isMember = Schema.is(Member)
const _standard = Schema.standardSchemaV1(Member)

// --- [EXPORTS] --------------------------------------------------------------------------

export { Member }
```
