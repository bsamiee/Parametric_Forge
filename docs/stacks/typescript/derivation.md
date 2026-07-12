# [TYPESCRIPT_DERIVATION]

This page is the derivation law: every type, vocabulary, and secondary surface computes from one anchor, and a hand-written parallel is a second, unverified source of truth. The type plane is the value plane's derived shadow — one declaration anchors each correspondence; `typeof`, `keyof typeof`, indexed access, mapped generation, template literals, and conditional decomposition compute everything downstream; inference is solved once at the owner — `const` type parameters, `NoInfer`, instantiation expressions, reverse-mapped parameters — so no consumer restates what the anchor carries; and the plane's own machinery — the registry merge seam, the `unique symbol` nominal regime, `HKT.TypeLambda`, typestate — exists only where a witness proves it. Everything around the algebra is shed by kind: the stated-annotation export gate and emit seam are `language.md`'s, collection and scalar selection is `values.md`'s, Schema owners and their derived surfaces are `shapes.md`'s, and overload sets, `Match` terminals, and `Function.dual` operators are `surfaces-and-dispatch.md`'s.

## [01]-[ANCHOR_ALGEBRA]

- Anchor law: one declaration anchors each correspondence — a value anchor where runtime rows, iteration, or order exist (the `as const` table, the `as const` key tuple), a merged registry interface where the row set is contributed across modules, a type anchor where the correspondence is purely type-plane, a `const` type parameter where the caller supplies the shape, a state parameter where the fact is protocol position
- Direction law: the algebra runs three directions and closes — types derive from values, secondary types compute from primary types, and generated types govern values back through contract checks — so an anchor edit propagates as compile pressure around the whole loop; a hand parallel in any direction is the break that lets the loop drift silently
- Gate law: the stated-annotation export gate leaves an exported anchor plain `as const` — its contract homes as constrained-default guard aliases in the merged namespace, an assembled owner states a `typeof`-derived annotation over its interior anchors, and the expression-seam `satisfies` spelling survives only where no export reaches the anchor
- Placement law: a contract check rides the anchor declaration, an annotation states a public operation surface, and `as` is kernel material — each declaration fixes its form once, and a widening annotation on an anchor destroys every literal downstream
- Pre-solve law: inference is the owner's obligation — `const` type parameters, `NoInfer` check-only positions, instantiation expressions, and reverse-mapped parameters fix literals and row payloads at the declaration; a consumer writing a type argument, an `as const`, a lambda annotation the owner solves, or a re-assertion marks the owner's signature as the defect
- Posture law: distribution and variance are declared decisions — a naked conditional parameter maps a union member-wise, `[T] extends [U]` asks one question of the whole, and `in`/`out` paired with a variance struct makes variance checked and witnessed intent
- Plane law: nominal identity runs two regimes disjoint by plane — `Schema.brand` marks admitted values with decode evidence inside Schema owners, and the annotated `unique symbol` TypeId with its variance struct marks own carrier types; neither substitutes for the other, and a brand minted on the wrong plane is the defect
- Budget law: the type plane computes inside verified budgets — recursion depth, union width, and the ASCII alphabet bound decomposition; `TS2589` and `TS2590` name the overruns, and an overrun repairs as one value-level computation the type derives from, never a directive
- Fence law: `HKT.TypeLambda` quantifies over containers only and is proven by plural instances; a phantom state parameter carries compile-time protocol facts only and is witnessed or it enforces nothing

Treat the type level as computation over anchors, never as a place to author facts. Replace a hand union, a parallel constant, a mirrored interface, a re-asserted literal, or an assertion-repaired spread the moment an anchor can derive or govern it.

## [02]-[DERIVATION_CHOOSER]

Each table routes a correspondence to the form that owns it, and every `[USE]` names the spelling it deletes. Each row routes to the `[03]` contract owning its mechanism for the rule the row cannot state.

[ANCHOR_FORMS]: which declaration anchors a correspondence.

| [INDEX] | [CONCERN]                       | [USE]                                                | [REJECTED_FORM]                            |
| :-----: | :------------------------------ | :--------------------------------------------------- | :----------------------------------------- |
|  [01]   | keyed rows any export reaches   | plain `as const` anchor + merged guard hub           | hand union, annotation restating every row |
|  [02]   | keyed rows no export reaches    | `as const satisfies Record<string, Row>`             | guard ceremony despite `satisfies`         |
|  [03]   | key set: wire, order, iteration | `as const` key tuple; guarded by its elements        | keys restated at literal, `as`-cast spread |
|  [04]   | rows contributed across modules | merged registry interface; rows via `declare module` | central table every contributor edits      |
|  [05]   | governed value, literals inert  | stated `Record<GeneratedUnion, V>` annotation        | hand-synced parallel table that drifts     |
|  [06]   | pure type-plane correspondence  | `type` literal-union or template-pattern anchor      | a dead runtime table no value reads        |
|  [07]   | caller-supplied literal shape   | `const` type parameter at the owner                  | caller `as const` discipline               |
|  [08]   | own-carrier nominal identity    | annotated `unique symbol` TypeId + variance struct   | structural carrier forged by look-alikes   |
|  [09]   | protocol call order             | accumulating state parameter, structurally witnessed | runtime flag re-checked per call           |
|  [10]   | boundary shape                  | Schema owner                                         | interface plus parallel decoder pair       |

- [01]: assembled owner where companions attach.

[PROJECTION_FORMS]: how a surface derives from its anchor.

| [INDEX] | [CONCERN]                    | [USE]                                          | [REJECTED_FORM]                                |
| :-----: | :--------------------------- | :--------------------------------------------- | :--------------------------------------------- |
|  [01]   | discriminant union           | `keyof typeof rows`; `keyof Registry`          | hand-written union                             |
|  [02]   | row and axis types           | indexed access `(typeof rows)[Kind]["axis"]`   | per-row aliases                                |
|  [03]   | tag union of a tagged family | `Family["_tag"]` distributes over the union    | hand-listed tag union                          |
|  [04]   | literal-keyed return         | indexed-access return on the generic key       | conditional return needing a cast to implement |
|  [05]   | package-carrier channel      | `Effect.Effect.Success` and peers              | hand `infer` over package types                |
|  [06]   | local-carrier channels       | one bracketed multi-clause `infer` conditional | chained single-`infer` conditionals            |
|  [07]   | union subset by pattern      | `Extract`/`Exclude` with a template pattern    | re-listed members                              |
|  [08]   | derived-surface flatten      | `Types.Simplify` at the public alias           | hand-rolled `{ [K in keyof T]: T[K] }` alias   |

- [01]: `keyof Registry` reads the merge seam.
- [05]: package carriers: `Effect.Effect.Success`, `Schema.Schema.Type`, `Context.Tag.Service`, `Layer.Layer.Success`.

[GENERATION_FORMS]: how a member family generates from anchors.

| [INDEX] | [CONCERN]                  | [USE]                                                 | [REJECTED_FORM]               |
| :-----: | :------------------------- | :---------------------------------------------------- | :---------------------------- |
|  [01]   | renamed member family      | mapped type, `as` key remap, intrinsic case operators | sibling interfaces per member |
|  [02]   | capability cross product   | template literal over union anchors                   | enumerated string constants   |
|  [03]   | row-predicate filtering    | key remap to `never` on the row's column              | a parallel filtered table     |
|  [04]   | seam-recast view           | `-readonly`/`+?`/`-?` on the same mapped clause       | a second hand-written family  |
|  [05]   | generated-union governance | contract-checked value closing the loop               | hand-synced tables that drift |
|  [06]   | consumed-union residue     | `satisfies never` on the terminal narrowing arm       | silent default, thrown guard  |

[INFERENCE_FORMS]: how the owner pre-solves what consumers otherwise repair.

| [INDEX] | [CONCERN]                    | [USE]                                                    | [REJECTED_FORM]                              |
| :-----: | :--------------------------- | :------------------------------------------------------- | :------------------------------------------- |
|  [01]   | literal retention            | `const` type parameter                                   | `as const` at every call site                |
|  [02]   | check-only position          | `NoInfer<T>`                                             | mirror generic, argument-order repair        |
|  [03]   | pre-solved generic           | instantiation expression under a semantic name           | wrapper arrow restating the signature        |
|  [04]   | per-row lambda typing        | reverse-mapped owner parameter                           | annotated handlers, call-site type arguments |
|  [05]   | tuple shape through an owner | variadic signature `readonly [...Init, Next]`            | positional overload ladder, widened arrays   |
|  [06]   | distribution posture         | naked parameter to map; `[T] extends [U]` for one answer | accidental union distribution                |
|  [07]   | variance intent              | `in`/`out` paired with the variance struct               | inference drift, phantom bivariance          |
|  [08]   | container polymorphism       | `HKT.TypeLambda` + `HKT.Kind` under typeclass constraint | per-container operator copies                |

## [03]-[DERIVATION_CONTRACTS]

Each contract fixes the placement rule its chooser rows cannot state. Snippets compose settled surfaces as supporting material; the spotlight is the derivation mechanism itself, and each contract closes on the boundary that hands the derived surface to its owning page.

[VOCABULARY_TABLE_SITE]:
- Use when: a bounded keyed domain carries behavior rows and its secondary surfaces — discriminant, projections, wire literal, returns — must stay provably consistent with it.
- Accept: interior anchors unexported — the `as const` key tuple where order, iteration, or a non-empty spread is load-bearing, the plain `as const` row table keeping every literal — and one exported owner assembling them: rows spread in, companions as properties, operations as members, the merged `declare namespace` hub carrying every derived type off the single import, the assembled owner's alias flattened through `Types.Simplify` so consumers read one record instead of a `typeof` intersection; the contract as a constrained-default guard pair inside the hub — a row guard whose default `typeof` query proves completeness and row shape, a key guard whose default discriminant proves no excess row — drift failing loudly at the alias declaration with zero widening of the anchors; `keyof typeof` discriminants; indexed row and axis projections; a conditional return derived as indexed access over the table keyed by the generic literal parameter; the tuple spread into `Schema.Literal`.
- Reject: a hand union or parallel constant beside the table; a discriminant anchored on the assembled owner — `keyof` there drags member keys into the key space, so `Kind` anchors on the interior row table; an annotation restating row literals to buy the export — the assembled owner's annotation derives as a `typeof` intersection over its interior anchors; a row-tuple anchor (`[{ kind: ... }] as const`) self-carrying its keys — lookup degrades to a linear scan and the discriminant re-derives as `(typeof rows)[number]["kind"]`, so the record owns lookup and the tuple owns order; `Object.keys` enumeration widened to `Array<string>` and asserted back when the tuple already carries the ordered key set; an `extends ?` conditional return — the checker cannot prove its body, and the cast it demands marks dispatch that belongs to the overload owner.
- Law: the guard pair is the satisfies algebra relocated to the declaration seam — a constrained default validates without widening exactly as `satisfies` does, completeness and shape ride the row guard, excess rides the key guard, and both erase; an anchor no export reaches keeps the shorter `as const satisfies` spelling at the expression seam.
- Law: the tuple spread holds `Schema.Literal`'s non-empty overload and preserves the exact literal tuple; spreading derived keys lands in the widened `ReadonlyArray` overload and demotes the schema to `SchemaClass<Kind>` — non-emptiness and order are tuple facts stated once at the anchor, never assertion repairs at the seam.
- Boundary: the stated-annotation export gate is `language.md`'s; the Schema owner that admits the wire value, and the class families vocabularies embed into, are `shapes.md`'s; dispatch composed over row lookups is `surfaces-and-dispatch.md`'s.

```typescript conceptual
import { Schema, type Types } from "effect";

const _kinds = ["narrow", "level", "broad"] as const; // interior key anchor: order, iteration, and non-emptiness are tuple facts stated once
const _rows = {
    // interior row anchor: plain as const keeps every literal; the hub guards carry its contract
    narrow: { ceiling: 2, weight: 5, wire: 429 },
    level: { ceiling: 24, weight: 3, wire: 425 },
    broad: { ceiling: 96, weight: 1, wire: 503 },
} as const;
const _wire: Schema.Literal<Tier.Kinds> = Schema.Literal(..._kinds); // the tuple spread holds the non-empty overload; derived keys would demote to SchemaClass<Kind>

declare namespace Tier {
    // merged type hub: every derived type qualifies off the single import
    type Kinds = typeof _kinds;
    type Kind = keyof typeof _rows; // anchored on the interior table: keyof the assembled owner would drag member keys into the key space
    type Row = (typeof _rows)[Kind];
    type Ceiling<K extends Kind = Kind> = (typeof _rows)[K]["ceiling"];
    type Contract = Record<Kinds[number], { readonly ceiling: number; readonly weight: number; readonly wire: number }>;
    type Shape = Types.Simplify<
        typeof _rows & { readonly kinds: Kinds; readonly wire: Schema.Literal<Kinds>; readonly ceiling: <K extends Kind>(kind: K) => Ceiling<K> }
    >; // Simplify flattens the assembled intersection at the public alias; the typeof chain stays interior
    type _Rows<T extends Contract = typeof _rows> = T; // row guard: a missing key or wrong axis shape fails this default at declaration
    type _Keys<K extends keyof Contract = Kind> = K; // key guard: an excess table row fails here — closure in both directions, zero widening
}

const Tier: Tier.Shape = {
    // one exported owner assembles rows, companions, and operations; the annotation derives, never restates
    ..._rows,
    kinds: _kinds,
    wire: _wire,
    ceiling: <K extends Tier.Kind>(kind: K): Tier.Ceiling<K> => _rows[kind].ceiling, // conditional return by indexed access: the checker proves the body
};

const _cap: 2 = Tier.ceiling("narrow"); // checked witness: the row's literal projects, never the axis union
const _order: "narrow" = Tier.kinds[0]; // order rides the owner as an anchor fact; no consumer re-lists keys

// --- [EXPORTS] --------------------------------------------------------------------------

export { Tier };
```

[REGISTRY_MERGE_SITE]:
- Use when: a row set must accept contributions from modules the owner never imports — capability rows, codec rows, handler rows landing from feature modules — while the union, projections, and governance still derive at the owner.
- Accept: one open `interface Registry` merged with its `declare namespace` hub under one exported name — the one sanctioned open interface in the corpus; contributor rows injected as `declare module "<owner-specifier>"` blocks at the declaring module, one row per contribution; `keyof Registry` deriving the union across every contribution with no central edit; indexed access `Registry[K]["axis"]` projecting per-contribution literals; the constrained-default guard re-validating the merged whole, so a malformed row in any contributing module fails at the owner's declaration.
- Reject: a second open interface anywhere — openness is this seam's monopoly, and a shape that merely wants fields is a closed owner; augmentation aimed at any module other than the declaring one; a central table contributors edit — the seam exists so contribution is a new file's row, never a shared-file edit; a registry whose every row one module contributes — a closed `as const` table wearing the open form.
- Law: the guard pair survives the seam — interface merging is program-wide, the constrained default re-checks the merged whole on every compilation, so the open seam keeps closed-table governance: row shape rides the constraint, and the union stays derived.
- Law: the registry is type-plane only — the paired runtime row arrives by registration at the composition graph, never a mutable module-level table; `services-and-layers.md` owns registration.
- Boundary: `declare module` augmentation capturing a foreign package's codec quirk is `boundaries.md`'s; this seam owns own-registry row contribution only.

```typescript conceptual
interface Registry {
    // the one sanctioned open interface: the row set is open, the row shape is not
    readonly narrow: { readonly weight: 5; readonly admit: (raw: string) => boolean };
}

interface Registry {
    // a contributor's row: from its own module, this block is declare module "<owner-specifier>"
    readonly broad: { readonly weight: 1; readonly admit: (raw: string) => boolean };
}

declare namespace Registry {
    // the hub merges onto the interface: one exported name carries rows, contract, and derived types
    type Kind = keyof Registry; // derives across every contribution; no central list to edit
    type Row = { readonly weight: number; readonly admit: (raw: string) => boolean };
    type Weight<K extends Kind = Kind> = Registry[K]["weight"];
    type _Rows<T extends Record<Kind, Row> = Registry> = T; // merged-whole guard: a malformed row in any contributing module fails here
}

const rank = <K extends Registry.Kind>(kind: K, registry: Registry): Registry.Weight<K> => registry[kind].weight;

const _w: 5 = rank("narrow", { narrow: { weight: 5, admit: (raw) => raw.length > 0 }, broad: { weight: 1, admit: () => true } });

// --- [EXPORTS] --------------------------------------------------------------------------

export { rank };
export type { Registry };
```

[GENERATED_SURFACE_SITE]:
- Use when: a member family corresponds to an anchor generatively — renamed handler names, capability matrices, filtered projections — so the family's size tracks the anchor's, never a hand count.
- Accept: mapped types with `as` key remapping and the intrinsic case operators `Capitalize`, `Uncapitalize`, `Uppercase`, `Lowercase`; template-literal cross products multiplying union anchors; row-predicate filtering by remapping the excluded key to `never`; modifier algebra on the same mapped clause — `-readonly` strips and `+?`/`-?` recast presence, so a type-seam view derives with zero second family; `Extract` and `Exclude` over template patterns for subsets; the governed value closing the loop under a stated `Record<GeneratedUnion, V>` annotation — the mapped domain demands completeness, the fresh-literal check rejects excess, the binding exports, and a new anchor row breaks it loudly at compile time; the consumed-union residue `(x satisfies never)` in the terminal arm of a narrowing chain — `never` assigns to every return type, so the arm compiles exactly while the chain consumes the whole union.
- Reject: sibling interfaces restating a family member by member; enumerated string constants a template cross product derives; a parallel filtered table beside its anchor; a generated family over members that merely rhyme — generation encodes a real correspondence, never a coincidence of spelling.
- Law: the mapped parameter correlates name and payload — `(typeof Anchor)[K]` keeps each generated member row-precise where a hand-written family blurs every payload to the union.
- Law: governance is two-sided — the stated `Record` annotation closes data completeness and excess at a binding, and `satisfies never` closes consumption completeness at an expression; the same residue proof is the closing line of a sanctioned statement kernel's `default` arm.
- Law: a governed value whose row literals are inert rides the stated annotation and exports; a governed value whose literals feed derived types is itself an anchor and takes the vocabulary owner's guard form.
- Law: generation is type-plane — a key the runtime must compute crosses at a value, because runtime case conversion widens to `string` and cannot index a generated record; a family the runtime addresses by key anchors as table rows instead.
- Boundary: domain shape variants, partial views, and wire projections derive on the Schema owner in `shapes.md`; `Match.exhaustive` is the residue proof's combinator form and `surfaces-and-dispatch.md`'s; kernel legality is `language.md`'s.

```typescript conceptual
import type { Effect } from "effect";

const Signal = {
    open: { grade: "state", retain: true },
    frame: { grade: "burst", retain: false },
    close: { grade: "state", retain: true },
} as const;

declare namespace Signal {
    type Verb = "emit" | "drain"; // type anchor: only the type plane reads it, so a value tuple here would be a dead runtime table
    type Kind = keyof typeof Signal;
    type Row = { readonly grade: "state" | "burst"; readonly retain: boolean };
    type _Rows<T extends Record<Kind, Row> = typeof Signal> = T; // self-keyed row guard: the open table proves shape against its own key set
    type Wake = { readonly [K in Kind as `on${Capitalize<K>}`]: (row: (typeof Signal)[K]) => Effect.Effect<void> }; // remapped family: K correlates each generated name to its row-precise payload
    type Staged = { -readonly [K in keyof Wake]+?: Wake[K] }; // modifier algebra: one clause recasts the family as a mutable partial staging view
    type Retained = { readonly [K in Kind as (typeof Signal)[K]["retain"] extends true ? K : never]: (typeof Signal)[K] }; // filtering is remap-to-never on the row's own column
    type Grant = `${Kind}:${Verb}`; // cross product: |Kind| x |Verb| literals from two anchors, zero listed
    type Drain = Extract<Grant, `${string}:drain`>; // subset by template pattern, never a re-listed union
}

const quota: Record<Signal.Grant, number> = {
    // governed value: the stated annotation demands all six grants, rejects any excess, and exports
    "open:emit": 8,
    "open:drain": 2,
    "frame:emit": 64,
    "frame:drain": 16,
    "close:emit": 8,
    "close:drain": 2,
};

const toll = (grade: Signal.Row["grade"]): number =>
    // consumption governance: the terminal arm carries the residue proof
    grade === "state" ? 1 : grade === "burst" ? 4 : (grade satisfies never); // a third grade fails to compile here, never at runtime

const _drain: Signal.Drain = "frame:drain"; // checked witness over the generated subset

// --- [EXPORTS] --------------------------------------------------------------------------

export { quota, Signal, toll };
```

[INFERENCE_PRESOLVE_SITE]:
- Use when: an owner accepts literal-bearing arguments whose precision downstream types consume — plans, routes, step tuples, keyed selections.
- Accept: a `const` type parameter so caller literals and tuples arrive narrow with zero call-site ceremony; `NoInfer` on every position that checks against another position's inference instead of driving it; an instantiation expression pre-solving a package generic once at the owner under a semantic name — on an exported binding the applied generic rides the annotation as `typeof` over the instantiation, never a restated signature; a variadic-tuple signature — `readonly [...Steps, Next]` — flowing tuple shape through the owner with every literal position preserved, leading or trailing rest patterns replacing a positional overload ladder; derived return fields projecting the inferred literal shape.
- Reject: caller `as const` discipline — unenforceable and lost at the first refactor; a mirror type parameter added to repair inference order; a wrapper arrow restating a whole signature to pin one type argument — the instantiation expression pins it with no body; a call site writing a type argument the owner's signature should have fixed; index arithmetic re-deriving a position the variadic pattern states — `steps[steps.length - 1]` demands the cast the pattern never needs; an exported call-result binding — its type exists only by inference, so it fails the stated-annotation gate, and a proof or staging binding stays interior instead.
- Law: one position drives inference and every other position checks — `NoInfer` moves the error to the wrong argument instead of silently widening the inference the right argument produced.
- Law: pre-solving is not renaming — the instantiation expression changes the type surface by monomorphizing the generic to the domain shape, and the binding carries the domain role's semantic name; a binding that changes neither type nor name is the deleted hop.
- Boundary: data-first/data-last pairing on a pre-solved operator is `surfaces-and-dispatch.md`'s.

```typescript conceptual
import { Array } from "effect";

type Step = { readonly lane: "bulk" | "live"; readonly take: number }; // the lane union lives in the field: consumers project Step["lane"], never a parallel alias

const plan = <const Steps extends ReadonlyArray<Step>>( // const parameter: caller literals arrive narrow with zero as const at any call site
    steps: Steps,
    fuse: NoInfer<Steps[number]["lane"]>, // check-only position: steps alone drives inference; fuse validates against the plan's own lanes
): { readonly steps: Steps; readonly fuse: Steps[number]["lane"] } => ({ steps, fuse });

const extend = <const Steps extends ReadonlyArray<Step>, const Next extends Step>(steps: Steps, next: Next): readonly [...Steps, Next] => [
    ...steps,
    next,
]; // variadic flow: the spread proves the tuple; index arithmetic would demand a cast

const nextStep: typeof Array.head<Step> = Array.head; // instantiation expression rides the annotation: the package generic pre-solved once under a semantic name

const _run = plan(
    [
        { lane: "live", take: 2 },
        { lane: "bulk", take: 5 },
    ],
    "live",
);

const _fuse: "bulk" | "live" = _run.fuse; // the owner solved inference; consumers never re-instantiate or re-assert

const _tail: 1 = extend(_run.steps, { lane: "bulk", take: 1 })[2]["take"]; // every literal position survives the variadic combinator

// @ts-expect-error "bulk" is a lane, but not one of this plan's lanes
const _drift = plan([{ lane: "live", take: 2 }], "bulk");

// --- [EXPORTS] --------------------------------------------------------------------------

export { extend, nextStep, plan };
export type { Step };
```

[REVERSE_MAPPED_SITE]:
- Use when: an owner takes a keyed record of rows whose payloads relate within each row — a seed and the step that consumes it, a config and its handler — and every lambda must arrive typed with zero call-site ceremony.
- Accept: one reverse-mapped parameter — `{ readonly [K in keyof T]: Cell<T[K]> }` over a bare `T extends Record<string, unknown>` — so the caller's object literal solves `T` key by key; exactly one non-function site per row at depth 1 driving the row's inference, every function site at depth 2 consuming the solved payload contextually; returns projecting `T[K]` by indexed access so the checker proves the body; per-row precision at the projection — a keyed read returns its row's payload, never the cross-row union.
- Reject: a `const` type parameter on a reverse-mapped owner — a literal-pinned seed forbids the step from producing new values of the row's type, so rows widen deliberately and literal retention stays with the presolve owner; lambda parameter annotations restating what the sibling site already solves; a row whose only `T[K]` occurrence hides under a second function layer — inference strands the row at `unknown` and every consumer widens; a call-site type argument.
- Law: the relation holds at depth 2 — `T[K]` reaches each row through at most one property step before the function layer: one shallow value site drives, any number of function sites consume; burying the driving site breaks the reverse map, and the repair lifts one value position to depth 1, never annotates lambdas.
- Boundary: `satisfies`-checked handler records and `Match` dispatch over these rows are `surfaces-and-dispatch.md`'s; this contract owns the inference mechanics.

```typescript conceptual
declare namespace lattice {
    // the row contract rides the operation's own merged hub: one export serves both planes
    type Cell<A> = { readonly seed: A; readonly step: (state: A, tick: number) => A };
}

const lattice = <T extends Record<string, unknown>>(
    cells: { readonly [K in keyof T]: lattice.Cell<T[K]> }, // reverse-mapped parameter: the caller's object literal solves T key by key
): { readonly at: <K extends keyof T>(key: K, tick: number) => T[K] } => ({
    at: (key, tick) => cells[key].step(cells[key].seed, tick), // indexed access keeps the body checker-proven; no cast survives here
});

const _grid = lattice({
    count: { seed: 0, step: (n, tick) => n + tick }, // n: number — the depth-1 seed drives, the depth-2 lambda consumes contextually
    label: { seed: "<value-a>", step: (s) => s.trim() }, // s: string — per-row solve; rows widen deliberately so the step can refill them
    open: { seed: false, step: (b) => !b },
});

const _n: number = _grid.at("count", 3);

// @ts-expect-error the payload is solved per key, never the cross-row union
const _cross: string = _grid.at("count", 3);

// --- [EXPORTS] --------------------------------------------------------------------------

export { lattice };
```

[CONDITIONAL_DECOMPOSITION_SITE]:
- Use when: a type computes from another type's structure — channel extraction, literal-pattern parsing, whole-shape questions over unions.
- Accept: shipped extractors first — `Effect.Effect.Success`, `Effect.Effect.Error`, `Effect.Effect.Context`, `Schema.Schema.Type`, `Schema.Schema.Encoded`, `Context.Tag.Service`, `Layer.Layer.Success` — so a hand `infer` over a package carrier re-derives what the package already exports; one bracketed multi-clause conditional for local carriers, every channel extracted in a single match with `infer ... extends` constraints inline; naked-parameter distribution only as the deliberate member-wise map; tail-position recursion with an accumulator parameter for bounded literal-pattern decomposition.
- Reject: chained single-`infer` conditionals where one clause extracts every channel; a naked conditional that must answer once for the whole — `boolean` splits to `true | false` and `never` distributes to nothing, so an undeclared posture is a latent bug, not a style choice; recursion that wraps its own result — pending work stacks toward the depth gate that the tail form elides; a directive over `TS2589` or `TS2590` — the overrun is the architecture finding, not the noise.
- Law: `infer M extends Realm` narrows inside the clause — the constraint participates in the match itself, and a failed constraint selects the false branch; a post-filter conditional after an unconstrained `infer` is the rejected two-step spelling.
- Law: budgets are form-selected — the tail-position accumulator evaluates to roughly 800 iterations before the depth gate where the self-wrapping form holds roughly 40, so the accumulator buys a 20x budget; a template cross product carries to roughly 10^4 members before the union gate; type-level parsing or arithmetic over domain data re-derives what the value level owns, and the repair is one value computation whose result the type level derives from the anchor.
- Law: decomposition is ASCII-bounded — a single-step `infer` split advances by UTF-16 code unit under TS6 `tsc6` and by code point under TS7 `tsc`, so a literal beyond ASCII has no parity-stable decomposition; alphabets past ASCII split at the value level, and the type derives from that computation's anchor.
- Boundary: exhaustive dispatch over an extracted union is `surfaces-and-dispatch.md`'s; variance declaration and witness on public carriers is the nominal-carrier contract's.

```typescript conceptual
import type { Effect } from "effect";

type Realm = "doc" | "layer"; // type anchor: no runtime row exists, so the union itself anchors the correspondence
type Verb = "pull" | "push";

type Flow<Cmd, Row> = {
    readonly push: (cmd: Cmd) => Effect.Effect<void, RangeError>;
    readonly tail: Effect.Effect<Row>;
};

const _row: Effect.Effect.Success<Flow<string, number>["tail"]> = 3; // shipped extractor first: the package exports its channel projections, and a hand infer over a package carrier re-derives them

type Parse<R> = R extends `${infer M extends Realm}/${infer V extends Verb}` // multi-clause infer: every channel extracts in one conditional, constraints inside the match
    ? { readonly realm: M; readonly verb: V }
    : never;

type _Split = Parse<"doc/pull" | "layer/push">; // naked parameter distributes: a union maps per member, two records out

type _Channel = _Split["verb"]; // indexed access distributes over the union: every member's column collects into "pull" | "push"

type Facet<H> = [H] extends [(cmd: infer C) => Effect.Effect<infer _A, infer E>] // bracketed posture: one answer over the whole shape, never a per-member split
    ? { readonly cmd: C; readonly fault: E }
    : never;

type _Probe = Facet<Flow<`${Realm}/${Verb}`, number>["push"]>; // { cmd: "doc/pull" | "doc/push" | "layer/pull" | "layer/push"; fault: RangeError }

type Trail<S extends string, Acc extends ReadonlyArray<string> = []> = S extends `${infer Head}/${infer Rest}` // accumulator in tail position: each step is final, so elimination buys the 800-step budget
    ? Trail<Rest, [...Acc, Head]>
    : readonly [...Acc, S];

const _deep: Trail<"doc/pull/live/burst"> = ["doc", "pull", "live", "burst"]; // checked witness over the decomposed tuple

// --- [EXPORTS] --------------------------------------------------------------------------

export type { Facet, Flow, Parse, Realm, Trail, Verb };
```

[CONTAINER_KIND_SITE]:
- Use when: one combinator must serve many containers — the same enrichment over `Option`, `ReadonlyArray`, and an own container, written once.
- Accept: an own `HKT.TypeLambda` implementor per own container, whose single `readonly type` line states how the container consumes `this["Target"]` — interface-declared by necessity, since a `this` type resolves only in an interface, and with the registry seam it is one of this layer's two interface sites; combinator signatures over `HKT.Kind<F, In, Out2, Out1, Target>` constrained by the `@effect/typeclass` vocabulary — `Covariant` and its siblings — with `In`, `Out2`, and `Out1` threading ambient channels and `Target` as the mapped slot; shipped instances from `@effect/typeclass/data/Option` and `@effect/typeclass/data/Array`; one own instance per own container, its dual `map` paired with the `covariant.imap` derivation.
- Reject: an HKT combinator with one instance — an ordinary generic wearing a lambda; domain variation carried on `F` — vocabulary rows and tagged families own domain axes, the lambda owns containers only; a local functor-shaped interface shadowing the typeclass vocabulary; container abstraction no call site swaps.
- Law: the fence is plural instantiation — the lambda earns existence when combinator call sites apply distinct instances; when every call site names one container, the combinator collapses into that container's module and the lambda dies.
- Boundary: which container a domain value rides, and the instance merge algebra over `struct` and `tuple` composition, are `values.md`'s.

```typescript conceptual
import * as covariant from "@effect/typeclass/Covariant";
import * as ArrayInstances from "@effect/typeclass/data/Array";
import * as OptionInstances from "@effect/typeclass/data/Option";
import { Function, type HKT, Option } from "effect";

type Ranked<out A> = {
    // an own container earns an own lambda; the variance annotation travels with it
    readonly rank: number;
    readonly value: A;
};

interface RankedTypeLambda extends HKT.TypeLambda {
    readonly type: Ranked<this["Target"]>; // the one line a lambda owns: how the container consumes its Target
}

const _map = Function.dual<<A, B>(f: (a: A) => B) => (self: Ranked<A>) => Ranked<B>, <A, B>(self: Ranked<A>, f: (a: A) => B) => Ranked<B>>(
    2,
    (self, f) => ({ rank: self.rank, value: f(self.value) }),
);

const RankedCovariant: covariant.Covariant<RankedTypeLambda> = { map: _map, imap: covariant.imap<RankedTypeLambda>(_map) };

const brace =
    <F extends HKT.TypeLambda>(
        F: covariant.Covariant<F>,
    ): (<R, O, E>(self: HKT.Kind<F, R, O, E, number>) => HKT.Kind<F, R, O, E, { readonly value: number; readonly even: boolean }>) =>
    (self) =>
        F.map(self, (value) => ({ value, even: value % 2 === 0 })); // one combinator, every container: the instance is the only per-container cost

const _braced = brace(OptionInstances.Covariant)(Option.some(3)); // Option.Option<{ value: number; even: boolean }>
const _rows = brace(ArrayInstances.Covariant)([1, 2, 3]); // ReadonlyArray<{ value: number; even: boolean }>
const _ranked = brace(RankedCovariant)({ rank: 1, value: 3 }); // Ranked<{ value: number; even: boolean }>

// --- [EXPORTS] --------------------------------------------------------------------------

export { brace, RankedCovariant };
export type { Ranked, RankedTypeLambda };
```

[NOMINAL_CARRIER_SITE]:
- Use when: an own carrier type — a feed, a handle, a resource cell — must not unify with structural look-alikes, and its type parameters need declared, witnessed variance.
- Accept: the annotated `unique symbol` pair — `const FeedTypeId: unique symbol = Symbol.for("<scope>/Feed")` with the same-name `type FeedTypeId = typeof FeedTypeId` — the symbol is the nominal key and `Symbol.for` holds one identity across module instances; the carrier keyed by `[FeedTypeId]` holding a variance struct, one row per parameter at its true variance — `Types.Contravariant<Cmd>`, `Types.Covariant<Row>`, `Types.Invariant` where reads meet writes — paired with `in`/`out` on the parameter list; cast-free runtime witnesses — `Function.constVoid` inhabits a contravariant row and `(_: never) => _` a covariant row; assignability then follows declared variance, so a carrier of narrower commands and wider rows flows where the wider carrier is demanded.
- Reject: `Schema.brand` reached for carrier identity — the brand marks admitted values at the decode seam inside Schema owners and carries parse evidence, never carrier identity; a TypeId minted for a domain shape a Schema owner admits — the same defect from the other plane; a variance struct omitting a parameter — the omitted parameter erases from comparison exactly like an unwitnessed typestate parameter, and instantiations unify; a string-literal brand field as the key — two modules spelling one string forge each other, where `unique symbol` identity cannot collide.
- Law: the struct is the witness and the annotation is the check — `in`/`out` declare intent the compiler verifies against inference, and the struct rows make the same variance structural so it survives assignability on its own; the two disagree only when one is wrong, and the error lands at the declaration.
- Law: module-instance identity is two-plane — `Symbol.for` holds the runtime key while the `unique symbol` declaration holds the type identity, and a runtime companion the carrier must hold once across duplicated module loads — an intern table, a registry cell — anchors as `GlobalValue.globalValue(FeedTypeId, () => value)` keyed by the same symbol; the admission is identity, never state: a `globalValue` holding what a Layer owns is a module-level live instance under a global key, and capability still enters through the requirement channel.
- Boundary: brand-in-field refinements on admitted values are `shapes.md`'s; the `TypeLambda` an own carrier needs to ride typeclass combinators is this page's container contract.

```typescript conceptual
import { Function, type Types } from "effect";

const FeedTypeId: unique symbol = Symbol.for("<scope>/Feed"); // annotated unique symbol: Symbol.for holds one nominal key across module instances
type FeedTypeId = typeof FeedTypeId;

type Feed<in Cmd, out Row> = {
    // in/out declare intent the compiler checks; the struct below witnesses it structurally
    readonly [FeedTypeId]: {
        readonly _Cmd: Types.Contravariant<Cmd>; // one struct row per parameter at its true variance; an omitted row erases from comparison
        readonly _Row: Types.Covariant<Row>;
    };
    readonly push: (cmd: Cmd) => void;
    readonly tail: () => Row;
};

const feed = <Cmd, Row>(push: (cmd: Cmd) => void, tail: () => Row): Feed<Cmd, Row> => ({
    [FeedTypeId]: { _Cmd: Function.constVoid, _Row: (_: never) => _ }, // cast-free witnesses: constVoid inhabits the contravariant row, the never-arrow the covariant one
    push,
    tail,
});

const _wide: Feed<"live", string> = feed<"bulk" | "live", "<value-a>">(Function.constVoid, () => "<value-a>"); // declared variance pays: narrower commands, wider rows

declare const _twin: { readonly push: (cmd: string) => void; readonly tail: () => number };

// @ts-expect-error a structural twin without the symbol key never unifies with the carrier
const _forged: Feed<string, number> = _twin;

// --- [EXPORTS] --------------------------------------------------------------------------

export { feed, FeedTypeId };
export type { Feed };
```

[TYPESTATE_SITE]:
- Use when: the legality of a call depends on protocol position — a terminal operation forbidden until every slot is set, a transition forbidden after it fires — and the runtime holds no state to check it.
- Accept: one state parameter accumulating filled keys through `Exclude`-constrained transitions, so a refill fails at the key constraint; the terminal operation demanding completion structurally — its parameter typed at the full record, never a conditional return; `Record.singleton` composing the accumulated record — a generic computed key in an object literal widens to a string index, so the package construction carries what the checker cannot type; `@ts-expect-error` proof tokens pinning each forbidden call as rejected.
- Reject: a phantom parameter carrying ordinary domain data — a value the program reads at runtime is a field on its owner, never a type argument; an unreferenced state parameter — an unused type parameter does not participate in assignability, so every instantiation unifies and the protocol it claims is unenforced; a runtime flag re-checking what the state parameter proves; a conditional-return terminal whose implementation needs the cast.
- Law: the witness law — a protocol parameter is witnessed structurally in a real position or through a `Types.Invariant` variance slot; unwitnessed state erases from comparison and enforces nothing.
- Law: the subtraction law — each transition subtracts its key from the open set and intersects it into the filled record, so the protocol is order-free, refills are compile errors, and completion is exactly the spent key set.
- Boundary: a builder whose product is a domain shape terminates at the Schema owner in `shapes.md`; runtime acquire/release ordering is `rails-and-effects.md`'s.

```typescript conceptual
import { Record } from "effect";

type Slots = { readonly route: string; readonly limit: number; readonly lane: "bulk" | "live" };

type Draft<Filled extends Partial<Slots>> = {
    // Filled is witnessed structurally by state; an unreferenced parameter would enforce nothing
    readonly state: Filled;
    readonly slot: <K extends Exclude<keyof Slots, keyof Filled>>(key: K, value: Slots[K]) => Draft<Filled & Record.ReadonlyRecord<K, Slots[K]>>;
};

const draft = <Filled extends Partial<Slots>>(state: Filled): Draft<Filled> => ({
    state,
    slot: (key, value) => draft({ ...state, ...Record.singleton(key, value) }), // the package construction carries the generic single-key record the checker cannot type
});

const seal = (complete: Draft<Slots>): Slots => complete.state; // completion is demanded by the parameter type, never by a conditional return needing a cast

const _staged = draft({}).slot("route", "<value-a>").slot("limit", 8);

// @ts-expect-error the protocol forbids refilling a slot
const _twice = _staged.slot("route", "<value-b>");

// @ts-expect-error seal demands every slot; "lane" is missing
const _early = seal(_staged);

const _sealed: Slots = seal(_staged.slot("lane", "live")); // the order-free protocol closes only when the key set is spent

// --- [EXPORTS] --------------------------------------------------------------------------

export { draft, seal };
export type { Draft, Slots };
```

## [04]-[ABSTRACTION_COLLAPSE_TESTS]

Use these tests before keeping a form the derivation layer already owns.

[PARALLEL_RESTATEMENT]:
- Smell: a hand union tracks a table's keys, an interface mirrors a derivable type, a second constant restates rows another declaration carries, an exported anchor's annotation restates every row, a central table collects rows other modules contribute, or a value ungoverned by the type plane drifts unchecked beside its generated union.
- Collapse: derive — `keyof typeof`, indexed access, mapped generation, template cross product, or the shipped extractor — home the contract as the namespace guard pair, open the row set through the registry seam when contribution crosses modules, and govern the value under the generated union's stated annotation.
- Done when: every secondary surface computes from its anchor, every governed value breaks on anchor growth, and deleting the parallel changes no meaning anywhere.

[CALL_SITE_RESIDUE]:
- Smell: consumers write `as const`, type arguments, or literal re-assertions, annotate lambda parameters a sibling site already solves, re-derive a union the owner already carries, aim `Parameters`/`ReturnType` at an owner's export, or a call-result binding sits in the exports block.
- Collapse: `const` type parameters, `NoInfer` check-only positions, instantiation expressions, and reverse-mapped parameters at the owner; the owner's merged namespace carries the type a consumer otherwise re-derives; proofs and staging bindings stay interior.
- Done when: call sites carry values only, and the owner's signature is the only place inference is described.

[TYPE_PLANE_OVERREACH]:
- Smell: type-level parsing or arithmetic re-derives a value fact, a recursive conditional wraps its own result toward the depth gate, a decomposition consumes an alphabet past ASCII, a directive silences `TS2589` or `TS2590`, or a conditional return needs a cast to implement.
- Collapse: compute at the value level and derive the type from the anchor; rewrite the recursion with a tail-position accumulator; move provable returns to indexed access and dispatch to the overload owner.
- Done when: every conditional body is checker-proven, and no directive or cast spans a derivation.

[UNWITNESSED_ABSTRACTION]:
- Smell: an HKT combinator every call site applies to one container, a state parameter that is unused or carries domain data, a variance struct missing a parameter's row, a TypeId minted for a shape a Schema owner admits, or a registry whose every row one module contributes.
- Collapse: the ordinary generic or the container's own module; a structural or `Types.Invariant` witness, or a field on the owning shape; the completed struct; `Schema.brand` at the decode seam; the closed `as const` table.
- Done when: every lambda has plural instances at real call sites, every state parameter is witnessed and protocol-only, and every nominal or open form carries its witness.
