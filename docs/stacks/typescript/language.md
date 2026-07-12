# [TYPESCRIPT_LANGUAGE]

TypeScript on the dual compiler floor — TS7 `tsc` and TS6 `tsc6` in parity — is the active language surface, and this page is the legality law: what a legal file, import, export, annotation, merge, and statement is before any type or value is designed. The type plane erases at emit, so every construct is either fully erased or plain JavaScript — emit-bearing syntax is banned outright, the public surface is one terminal exports block that reads without inference, absence and index trust are spelled exactly, deferred evaluation is boot-edge vocabulary, declaration merging asserts only what a machine discharges, and statements survive only at named seams — the marked kernel, the boot edge, an owning page's platform exemption. Everything above legality is shed by kind: type-level derivation rides `derivation.md`, value primitives and identity ride `values.md`, the kernel's earn test and algorithmic forms ride `computation.md`, shape authority rides `shapes.md`, call-surface collapse rides `surfaces-and-dispatch.md`, the carrier rides `rails-and-effects.md`, capability wiring rides `services-and-layers.md`, and edge admission rides `boundaries.md`.

`tsconfig.base.json` owns the compiler-flag facts. This page names a flag only where it changes the form a source file may assume.

## [01]-[ACTIVE_SURFACE]

- Compiler floor: TS7 `tsc` and TS6 `tsc6` under one flag set — a construct is legal when both accept it, and TS7 `tsc` diagnostic codes are the ones doctrine cites
- Module law: every file is a module under `moduleDetection: "force"`; a specifier names a real file with its real `.ts` extension; resolution rides the package exports map; every side-effect specifier resolves (`TS2882` otherwise); the value-plane import graph is a DAG and a domain module's top level is declaration space
- Syntax law: erased syntax only — `enum`, runtime `namespace`, constructor parameter properties, and `import =`/`export =` are `TS1294` at compile; decorators are legal JavaScript and still never appear — wrapping attaches through `pipe` at the owner declaration, never through a second composition channel
- Import law: emit is verbatim — nothing elides by inference, so type-only traffic is spelled at every import and export; deferral is two distinct forms — `import defer` postpones evaluation at the boot edge, the boundary loader postpones loading at its seam
- Merge law: declaration merging is one-directional evidence — a type-only `declare namespace` merged on a value asserts nothing about runtime and merges freely; a same-name `interface` merged onto a `class` asserts implanted members and is legal only at the implanting seam
- Export law: declarations are authored unexported and the file ends at one `// --- [EXPORTS]` block — `export { ... }` plus `export type { ... }` — so the tail is the whole public surface; every exported name carries its annotation, the interior is `_`-prefixed, and no default export, re-export, or barrel exists
- Absence law: `?:`, `| undefined`, and the unproven index are three distinct type-seam facts with three distinct spellings; the read spelling carries key provenance — dot proves a declared key, bracket marks index trust; domain absence is `Option`
- Statement law: statements, `throw`, mutation, `as`, and `!` live only at `// BOUNDARY ADAPTER` sites, and load-order statements only at the boot edge; this page sanctions the in-process kernel. `Effect.gen` bindings are the rail's do-notation, never statement residue, and a platform-forced statement seam is legal only under its owning page's named exemption

Treat source as idiomatic erased-syntax TypeScript, never a compatibility layer. Replace an emit-bearing form, a declaration-site export, an inference-hidden signature, a pass-through re-export, a parallel import pair, or an assertion-repaired read the moment the active surface carries the concept in one form.

## [02]-[CANONICAL_CHOOSER]

Each table routes a concern to the legal form that owns it, and every `[USE]` names the spelling it deletes. Rows the compiler already forces are omitted — the chooser legislates the decision the flags leave open, never the error catalog. Each group routes to its `[03]` placement card for the rule a row cannot state.

[MODULE_AND_IMPORT_FORMS]: how a file consumes another surface.

| [INDEX] | [CONCERN]                        | [USE]                                                | [REJECTED_FORM]                               |
| :-----: | :------------------------------- | :--------------------------------------------------- | :-------------------------------------------- |
|  [01]   | type-only specifier              | `import type { Shape } from "<specifier>"`           | a value import kept live for type positions   |
|  [02]   | mixed specifier                  | one statement, inline `type` specifiers              | a value line and a type line on one specifier |
|  [03]   | package namespace                | one named root binding under its canonical name      | per-member cherry-picking, alias drift        |
|  [04]   | shadowed global                  | `globalThis.<Name>` at the FFI seam                  | renaming the module binding to spare a global |
|  [05]   | load-time effect                 | side-effect import leading a boot-edge module        | registration import inside a domain module    |
|  [06]   | qualified type via erased import | `Shape.Field` type access through the erased binding | importing the value side for one type name    |
|  [07]   | data-file import                 | `with { type: "json" }` ingress feeding decode seam  | a JSON binding trusted as domain shape        |
|  [08]   | deferred module load             | boundary loader; the promise converts at its seam    | bare `import()` or `require` in domain flow   |
|  [09]   | deferred module evaluation       | `import defer * as Name` leading a boot-edge module  | hand-rolled lazy-init singleton, cold path    |

[EXPORT_SURFACE_FORMS]: how a module declares its public surface.

| [INDEX] | [CONCERN]                  | [USE]                                             | [REJECTED_FORM]                                   |
| :-----: | :------------------------- | :------------------------------------------------ | :------------------------------------------------ |
|  [01]   | public surface site        | one terminal `// --- [EXPORTS]` block             | `export` riding body declarations, default export |
|  [02]   | value-bearing name         | `export { Shape }` — one entry, every meaning     | a value entry plus a parallel type entry per name |
|  [03]   | pure-type name             | `export type { Shape }` in the block              | a type smuggled through the value statement       |
|  [04]   | companion type family      | type-only `declare namespace` merged on the owner | prefixed sibling type exports                     |
|  [05]   | value-keyed type           | same-name `const` plus `type` pair                | a `<Name>Kind` alias beside its const             |
|  [06]   | single-signature operation | annotated arrow `const`, listed in the block      | hoisted `function` statement, inferred signature  |
|  [07]   | interior symbol            | `_`-prefixed, absent from the block               | exported helper, promotion alias                  |
|  [08]   | package entry point        | exports-map subpath; consumers import the owner   | `export ... from` pass-through, `export *`        |
|  [09]   | public type surface        | `type` alias or the owner's merged companion      | exported `interface` open to remote merge         |
|  [10]   | machine-implanted members  | same-name `interface` by its class, implant seam  | a merge promising members nothing implants        |

[ERASURE_REPLACEMENT_FORMS]: the legal form for each banned emit-bearing construct.

| [INDEX] | [CONCERN]                | [USE]                                              | [REJECTED_FORM]                            |
| :-----: | :----------------------- | :------------------------------------------------- | :----------------------------------------- |
|  [01]   | closed vocabulary        | `as const` table with a one-name derived type      | `enum`, `const enum`                       |
|  [02]   | value-and-type grouping  | the module itself; type-only `declare namespace`   | runtime `namespace`, instantiated module   |
|  [03]   | constructor-owned fields | generated owner heritage carrying the field record | constructor parameter properties           |
|  [04]   | foreign-module binding   | ESM `import` with interop pinned at the FFI seam   | `import <name> = require(...)`, `export =` |

[STRICTNESS_CONSEQUENCE_FORMS]: the spelling each strictness fact forces open.

| [INDEX] | [CONCERN]                    | [USE]                                            | [REJECTED_FORM]                                  |
| :-----: | :--------------------------- | :----------------------------------------------- | :----------------------------------------------- |
|  [01]   | key whose presence varies    | `?:` under exact-optional semantics              | `?: T \| undefined` blur                         |
|  [02]   | always-present key, no value | `T \| undefined` spelled in the type             | `?:` on a key that always exists                 |
|  [03]   | exact-optional construction  | conditional spread `...(guard && { key })`       | a `key: undefined` write, post-build delete      |
|  [04]   | proven-key read              | key typed `keyof typeof Table`; total access     | membership re-check, `!` repair                  |
|  [05]   | open-index read              | bracket read lifted to `Option` at the seam      | `!` assertion on the unproven cell               |
|  [06]   | key-provenance spelling      | dot on declared key, bracket on signature member | uniform dot; signature widened to spare brackets |
|  [07]   | side-effect specifier        | resolving specifier; assets declare module shape | unresolvable registration import, silent trust   |
|  [08]   | builtin iterator input       | collection combinator over the iterable          | hand `.next()` stepping that trusts `.value`     |

## [03]-[LANGUAGE_FORM_CONTRACTS]

Each contract fixes the placement rule the chooser row cannot state. Snippets compose settled doctrine as supporting material; the spotlight is the legality form itself, and each contract closes on the boundary that hands the value to its owning page.

[COMPILER_PARITY_SITE]:
- Law: TS7 `tsc` is the conformance authority — when `tsc` and `tsc6` disagree, `tsc` decides which behavior was specified and its diagnostic codes are the ones doctrine cites; the same rejection may surface under sibling codes across the floor, and the repair lands at the shape until both compilers accept it.
- Law: divergence concentrates where inference runs deepest — unbounded conditional recursion, implicit-instantiation blowups, inference-dependent export types; value-anchored types and annotation-explicit exports present both checkers with shallow, decidable obligations, which is why this corpus legislates them.
- Law: the directive channel is not a repair surface — a suppression converts a compile-time fact into a runtime surprise, so a diagnostic is repaired at the shape it indicts; `@ts-expect-error` is a proof token asserting an intended illegality where a surface must prove a form rejected, never a silencer over live code.
- Reject: `@ts-nocheck` and `@ts-ignore` in any file; a `@ts-expect-error` spanning a live finding or a compiler disagreement; a type only one checker resolves — collapse it to the form both prove.

[MODULE_FORM_SITE]:
- Use when: a file states its imports — every file is a module, so this is every file's first decision, and the one-name merge decided here is what the exports block later carries.
- Accept: one import statement per specifier — `import type` when the module is consumed only in type positions, inline `type` specifiers when one specifier serves both planes; named root bindings consumed as namespaces under their canonical names; a side-effect import only in a boot-edge module, leading the file because its execution order is program order, and only naming a specifier that resolves — `noUncheckedSideEffectImports` turns the registration edge into a checked claim, so a mistyped specifier is `TS2882` at compile, never a registration that silently never ran; `import defer * as Name from "<specifier>"` likewise boot-edge-only, and the namespace is the only legal binding — named and default defer forms are `TS18059` and `TS18058`; a top-level statement or top-level `await` likewise boot-edge-only — `await` there forces every importer's evaluation async, so it never appears below the entry; qualified type access (`Shape.Field`) through an erased binding.
- Reject: a value line and a type line splitting one specifier; a value import consumed only in type positions — verbatim emit keeps it as a live load; alias rebinding to spare a shadowed global; a side-effect import, top-level statement, top-level `await`, or `import defer` inside a domain module — the top level is declaration space, registration is Layer material, and deferral moves the deferred module's effects to an arbitrary first-touch site, an execution-order statement smuggled into declaration space; bare `require` and `import()` in domain flow — deferred loading is a boundary loader whose promise converts at its owning seam; an inline `import("<specifier>").Shape` type annotation where an erased import binding owns the name; a data-file import consumed as its inferred shape — the attribute-carried binding is raw ingress and crosses the decode seam before domain use; an unresolvable asset specifier trusted or suppressed — the module shape is declared at the FFI seam so the import resolves; `declare global`, ambient declarations, and triple-slash references; module augmentation anywhere but its two owned seams — own-registry row contribution at the declaring module (`derivation.md`'s) and foreign quirk capture at the engine owner (`boundaries.md`'s) — a surface changes at its owner, never by remote merge.
- Law: a root namespace binding deliberately shadows its global namesake on the value plane only — `Array.map` is the package's, a bare type position still resolves the global type, so `ReadonlyArray<string>` and `Array<number>` keep their built-in meaning, and the global value is reachable as `globalThis.<Name>` at the FFI seam; one file reads both planes with zero aliases.
- Law: one name serves the value and its companion types through declaration merging — a same-name `const`-plus-`type` pair, a class owner, or a type-only `declare namespace` merged onto a `const`, `type`, or function declaration — so a consumer takes one import and never aliases, re-derives, or writes `typeof` at a call site.
- Law: `import defer` postpones evaluation, never loading — the module graph still loads and links eagerly, and a deferred subgraph carrying top-level `await` evaluates eagerly regardless; the boot edge owns the lever because first-touch evaluation is execution order, and a cold load rides the boundary loader instead.
- Law: the value-plane import graph is a DAG — a cycle is split ownership and its repair moves the shared declaration to its owner, never defers the read behind a lazy accessor; a cycle whose every edge is `import type` erases to no cycle at all, so type-plane back-references are free exactly where value edges are illegal.
- Boundary: which package a specifier may name is the exports-map edge; this site owns the statement forms inside one legal file.

```typescript conceptual
import { Array, type Duration, Option, Order, pipe } from "effect"; // one statement per specifier: inline type specifiers ride the named list; Array shadows the global value plane deliberately
import type { Frame } from "./frame.ts"; // type-only module: the whole statement erases; Frame stays reachable in type positions
import { type Gauge, admit } from "./gauge.ts";

const Lens = { width: 16, cadence: "spaced" } as const;

declare namespace Lens {
    // type-only companion merged on the owner; ambient members export implicitly
    type Spread = {
        readonly lead: Gauge;
        readonly hold: Duration.Duration; // qualified type through the inline-erased specifier; no second import statement
        readonly frame: Frame;
    };
}

const spread = (labels: ReadonlyArray<string>, hold: Duration.Duration, frame: Frame): Option.Option<Lens.Spread> =>
    // bare type positions still resolve the global: ReadonlyArray stays built-in under the effect Array binding
    pipe(
        labels,
        Array.take(Lens.width), // the merged name read on the value plane: const rows and companion types travel together
        Array.map((label, rank) => admit(rank, label)),
        Array.sort(Order.mapInput(Order.number, (gauge: Gauge) => gauge.rank)),
        Array.head,
        Option.map((lead) => ({ lead, hold, frame })), // and on the type plane: the return speaks Lens.Spread off the same single import
    );

// --- [EXPORTS] --------------------------------------------------------------------------

export { Lens, spread }; // one entry carries every meaning of Lens: the const value and the merged namespace types
```

[DEEP_MODULE_SITE]:
- Use when: a module lays out its public surface — the terminal exports block, the two-export budget, the `_`-prefixed interior, and the annotation each export carries.
- Accept: declarations authored unexported, then one `// --- [EXPORTS]` block closing the file — `export { ... }` for names with a value side, `export type { ... }` for pure-type names; one owner export plus at most one operation-family export; every exported single-signature operation an annotated arrow `const` (`TS9007`-clean); every exported const stating its type or standing as a self-describing `as const` literal (`TS9010`-clean); interior `_`-declarations carrying no annotation burden while only bodies consume them; companion types riding the owner's merged namespace.
- Reject: any `export` keyword on a body declaration — the block is the only export site; `export default` — the surface is named; a re-export statement (`export ... from`, `export *`, `export type ... from`) — a name leaves only its owning module and entry points are exports-map subpaths, never authored index modules; a hoisted `function` statement for a single-signature operation — operations are annotated arrow consts, read in declaration order and never rebindable, and the overload-set entrypoint is the one `function` declaration `surfaces-and-dispatch.md` licenses; an exported `interface` — an open merge seam any consumer file can augment, so a closed public type is a `type` alias or the owner's merged companion, and `interface` survives only as a foreign-contract mirror at the FFI seam, the implanting-seam merge beside its class, the registry merge seam's one open interface, or the `this`-typed heritage implementor a package extension point demands; an exported `_`-symbol; a promotion alias `const Shape = _shape`; an exported signature speaking a `_`-type — the type a public signature names is public under the owner's one name, never leaked and never parallel-restated; a hand-written public union restating an interior table's keys — the table the surface speaks becomes the exported owner instead; a single-caller `_`-function — inline it, since a `_`-function earns existence at two call sites, as a named policy value, or as the marked kernel.
- Law: one block entry exports every meaning its name carries — the const value, the same-name `type`, the merged namespace family, a class's constructor and instance type — so the one-name law is mechanical: merge first, list once; `export type { ... }` exists only for names with no value side, and the block declares the surface, never widens it.
- Law: the annotation boundary is mechanical — declaration emit is syntactic, so a checker-computed export type trips at the export site no matter where the `export` keyword sits: bare `as const` and entity-name heritage emit clean, while `satisfies` on the anchor (`TS9010`, even under `as const`), call-expression owner heritage (`TS9021`), and a derivation-rooted composition value — a contract assembly, derived projection, or variant extraction whose type is the checker's computation (`TS9010`) — do not.
- Law: the carve is manifest surface — the `TS9007`/`TS9010`/`TS9021` gate binds exactly the declaration-emitting projects, so a checker-computed export form is legal where no declaration emits; on an emitting surface the vocabulary contract homes in the owner's merged companion — a default-parameter row guard beside the anchor — keeping the literal inference and the contract both, while a widened table annotation, duplicated field annotations, or a demoted owner is the rejected repair.
- Law: interior types are free — a `_`-declaration's checker-computed type costs nothing while no exported signature speaks it; the moment a public signature needs its keys, the declaration itself goes public under one name.
- Boundary: package subpaths and per-runtime entry points are manifest surface; this site owns the shape of one module.

```typescript conceptual
import { Array, Option, Order, pipe } from "effect";

const Band = {
    // public vocabulary: bare `as const` emits clean; the contract check homes below, not in a satisfies clause
    tight: { ceiling: 4, weight: 3 },
    steady: { ceiling: 16, weight: 2 },
    loose: { ceiling: 64, weight: 1 },
} as const;

declare namespace Band {
    type Kind = keyof typeof Band;
    type Row = (typeof Band)[Kind];
    type _Rows<T extends Record<Kind, { readonly ceiling: number; readonly weight: number }> = typeof Band> = T; // row guard: satisfies on the anchor is TS9010 under declaration emit; the merged companion carries the contract and the anchor keeps its literals
}

const _byCeiling = Order.mapInput(Order.reverse(Order.number), (kind: Band.Kind) => Band[kind].ceiling); // interior policy value: _-prefixed, checker-computed, annotation-free

const widest = (kinds: ReadonlyArray<Band.Kind>): Option.Option<Band.Row> =>
    // public signatures speak Band.*, never a _-type; the return annotation is the surface
    pipe(
        kinds,
        Array.sort(_byCeiling),
        Array.head,
        Option.map((kind) => Band[kind]),
    );

// --- [EXPORTS] --------------------------------------------------------------------------

export { Band, widest }; // the tail is the whole surface: one owner, one operation, nothing else leaves
```

[ERASABLE_SURFACE_SITE]:
- Use when: a concept reaches for one of the four emit-bearing forms the compiler bans as `TS1294` — `enum`, runtime `namespace`, constructor parameter properties, `import =`/`export =` — or for a declaration merge that asserts runtime members.
- Accept: the `as const` value table with a one-name derived type as the vocabulary form — the runtime half is one object literal, the type half derives on the same name; the module itself as the only value-grouping surface, with type-only `declare namespace` merging companions; the generated owner whose heritage carries the field record — `Data.Class<Fields>` entity-name heritage stays declaration-legal — so construction and the field set ride one declaration; ESM `import`/`export` only, with foreign-module interop pinned at the FFI seam.
- Reject: a static-member class grouping values as a namespace substitute; enum semantics rebuilt as a frozen bag beside a hand-written parallel union; a hand class whose constructor body only assigns declared fields — that class is a generated-owner candidate; a `const enum` expectation of inlined members — erasure leaves no construct to inline; a same-name `interface` merged onto a `class` with no implanting machine behind it — the checker trusts the promised members unverified; a merge dodging a member the class body could author.
- Law: erasure is the foundation of every law on this page — a file's runtime semantics are its JavaScript with types deleted, so each construct is either fully erased or fully runtime; the four banned forms are the only type-plane syntax carrying emit semantics, and each replacement splits cleanly into a plain runtime value and a derived type companion.
- Law: the class-interface merge is gated to the implanting seam — a same-name `interface` beside a `class` asserts instance members the class body never authors, which is legal exactly where a machine discharges the promise: generated-owner heritage whose constructor types what its prototype installs (`Data.Class`, `Effectable.Class`, `Streamable.Class` — implanting the `Pipeable` `.pipe` and `Inspectable` `toJSON`/`[NodeInspectSymbol]` surfaces off the shared prototype, the canonical members a body never writes) or a prototype implant the same module performs at its FFI seam; anywhere else the merge fabricates evidence — an `as`-grade assertion moved to the declaration plane, invisible at every call site.
- Boundary: the derivation algebra the vocabulary table feeds is `derivation.md`'s, and the TypeId and variance-struct regime that legitimately rides same-name merging is `derivation.md`'s; the generated owner's identity semantics are `values.md`'s, and which owner form a domain product takes is `shapes.md`'s chooser; FFI prototype-implant mechanics are `boundaries.md`'s; this site owns which declaration form is legal.

```typescript conceptual
import { Data } from "effect";

const Phase = { draft: 0, sealed: 1, retired: 2 } as const; // the enum replacement: one object literal at runtime, ordinals as readable rows
type Phase = keyof typeof Phase; // same-name pair: the type is the const's key space; one name serves both planes

class Seal extends Data.Class<{ readonly key: Phase; readonly rank: (typeof Phase)[Phase] }> {} // the parameter-property replacement: entity-name heritage carries the field record, declaration-legal

const _minted: Seal = new Seal({ key: "sealed", rank: Phase.sealed }); // both replacements construct: key demands the type plane, rank reads the value plane's ordinal row

// --- [EXPORTS] --------------------------------------------------------------------------

export { Phase, Seal }; // Phase is one entry, value and type; Seal is one entry, constructor and instance type
```

[STRICTNESS_CONSEQUENCE_SITE]:
- Use when: a type-seam shape or a read must state absence precisely — exact-optional and unchecked-index semantics make absent-key, empty-cell, and unproven-index three distinct facts with three distinct spellings.
- Accept: `?:` for a key whose presence varies — writing `undefined` into it is `TS2375`, so presence changes only by inclusion or omission, and construction rides the conditional spread `...(guard && { key })`; `T | undefined` for a cell that always exists but may hold nothing; a read keyed by `keyof typeof Table` — membership rides the key type and the access is total; dot access only on declared keys — `noPropertyAccessFromIndexSignature` makes dot over a signature member `TS4111`; an open `string` index read lifted from `| undefined` into `Option` at the read seam.
- Reject: `?: T | undefined` stating both facts on one key — a shape that needs two answers states two keys or two facts deliberately; `!` repair of an unproven read outside the kernel; a guard re-checking a key its type already proves; a signature widened or a key promoted only to spare the bracket spelling; hand `.next()` stepping that trusts `.value` — builtin iterator results union `undefined`, and the collection combinator owns iteration.
- Law: the three spellings answer one question each — may the key be missing (`?:`), may the present cell be empty (`| undefined`), is the index proven (`keyof typeof` against the lifted open read) — and the flag set turns every mis-spelling into a compile error, so absence semantics are structural, never conventional.
- Law: the read spelling carries key provenance — a dot read compiles only against a declared key while a bracket read marks index trust and unions `undefined` under unchecked-index semantics, so declared and open keys stay legible at every read site with no comment and no convention.
- Law: these forms live at the type-level seam — option bags, platform payloads, interop cells; a domain shape's absence is `Option` admitted at the Schema owner, and a type-seam bag never crosses into domain flow carrying `undefined`.
- Boundary: the `Option` lift combinators are `values.md` material; Schema absence admission is `shapes.md`'s; this site owns the spelling and the read posture.

```typescript conceptual
import { Option } from "effect";

const Grade = { low: 0, mid: 5, high: 9 } as const;
type Grade = keyof typeof Grade;

declare namespace overlay {
    type Ledger = { readonly floor: number; readonly [band: string]: number }; // one declared key beside an open band: provenance decides each read's spelling
    type Patch = {
        // type-seam bag: domain absence is Option at the Schema owner, never these spellings
        readonly label?: string; // ?: answers "may the key be missing"; a label: undefined write is TS2375
        readonly probe: string | undefined; // | undefined answers "may the present cell be empty"; the key always exists
        readonly floor: number;
    };
}

const overlay = (ledger: overlay.Ledger, band: Grade, key: string, label: string | undefined): overlay.Patch => ({
    probe: label,
    floor: Option.getOrElse(Option.fromNullable(ledger[key]), () => ledger.floor + Grade[band]), // dot proves the declared key; the bracket read is index trust lifted at the seam — dot on the band is TS4111
    ...(label !== undefined && { label }), // presence rides the conditional spread: include the key or omit it, never write undefined
});

// --- [EXPORTS] --------------------------------------------------------------------------

export { Grade, overlay }; // overlay is one entry: the operation and its merged payload types travel under one name
```

[KERNEL_EXEMPTION_SITE]:
- Use when: a measured hot path or a platform contract is faster or forced as statements — the `_`-prefixed kernel marked `// BOUNDARY ADAPTER` is the sanctioned in-process site for statements, `throw`, mutation, `as`, and `!`.
- Accept: loops and mutable accumulators confined to one kernel whose result detaches immutable; `!` where a loop bound or scan invariant is the evidence the checker cannot carry under unchecked-index semantics; `as unknown` pinning an `any`-producing platform API — the pinned value exists only to cross the decode seam; a platform throw crossing the kernel signature only into the owning rail conversion; a `catch` binding narrowed from `unknown` before anything leaves the kernel.
- Reject: a statement loop outside a marked kernel; an accumulator escaping as live state; `as` or `!` in expression-shaped flow — evidence belongs in the key type, the decode seam, or the declaration; a kernel throw consumed by anything but the conversion seam; an authored throw signaling an input condition — input rejection is a returned value, and a kernel throw is a platform's own or an unreachable-default defect; a `using`/`await using` declaration standing in for resource lifetime — brackets are rail material at the owning seam; the mark on ordinary logic a fold expresses without measurement pressure.
- Law: the kernel is closed — it admits values, emits an immutable value, leaks no mutable reference, and carries the mark on its first line so the exemption is recoverable from the declaration; above the kernel's signature everything stays expression-shaped.
- Law: the kernel's cast algebra is one-directional — `any` pins to `unknown`, a proven index asserts to its element, a platform union narrows to its witnessed member; a cast that widens evidence or invents a shape the kernel never proved is illegal even here.
- Boundary: the conversion combinators that lift a kernel throw are `rails-and-effects.md`'s; worker and marshal statement seams are `boundaries.md`'s; this site owns the in-process compute kernel.
- Boundary: the kernel's earn test — fold first, measure, then mark — and its algorithmic forms are `computation.md`'s; this site owns the mark's legality and its cast algebra.

```typescript conceptual
import { type Cause, Effect } from "effect";

const _parse = (text: string): unknown => JSON.parse(text) as unknown; // BOUNDARY ADAPTER: any-pin — the platform any never escapes; the parse throw exits only into the conversion below

const _spans = (bytes: Uint8Array, mark: number): ReadonlyArray<readonly [number, number]> => {
    // BOUNDARY ADAPTER: measured scan kernel — mutation dies at the return
    const spans: Array<readonly [number, number]> = [];
    let open = -1;
    for (let index = 0; index < bytes.length; index += 1) {
        const byte = bytes[index]!; // sanctioned assertion: the loop bound is the evidence the checker cannot carry
        if (byte === mark && open < 0) open = index;
        else if (byte === mark) {
            spans.push([open, index] as const);
            open = -1;
        }
    }
    return spans; // the accumulator detaches immutable; no mutable reference leaves the kernel
};

const admit = (
    text: string,
    bytes: Uint8Array,
): Effect.Effect<{ readonly shape: unknown; readonly spans: ReadonlyArray<readonly [number, number]> }, Cause.UnknownException> =>
    Effect.try(() => ({ shape: _parse(text), spans: _spans(bytes, 0x1e) })); // the kernel throw converts at the owning seam; above this line everything is expression-shaped

// --- [EXPORTS] --------------------------------------------------------------------------

export { admit };
```

## [04]-[ABSTRACTION_COLLAPSE_TESTS]

Use these tests before keeping a form the legality layer already owns.

[SYNTAX_EMULATION]:
- Smell: a static-only class groups values, a frozen bag emulates enum ordinals beside a hand union, or a constructor body only assigns declared fields.
- Collapse: the `as const` table with its one-name derived type, the module as the grouping surface, the generated owner heritage.
- Done when: every banned-form emulation is a derived-companion table or a generated owner, and no hand union parallels a key space.

[EXPORT_SPRAWL]:
- Smell: an `export` keyword rides a body declaration, a module exports three or more names, an `_`-symbol or unowned name appears in the block, or a type restates another export's interior.
- Collapse: move every export into the terminal block, merge companion types into the owner's one name, inline single-caller helpers, delete pass-through re-exports, and move a second concept to its own module.
- Done when: the tail block is the entire surface — one owner plus at most one operation family, each entry annotated and each meaning merged — and the interior is invisible.

[LOAD_TIME_EXECUTION]:
- Smell: a domain module executes at load — a top-level statement or `await`, a registration import, an `import defer` binding, a data binding trusted as domain shape, or a value cycle broken by deferring a read.
- Collapse: the boot edge owns execution order and the deferral lever, a data import crosses the decode seam, capability rides the Layer graph, and ownership moves to break the cycle.
- Done when: every domain top level is declaration space and the value-plane import graph is a DAG.

[ASSERTION_RESIDUE]:
- Smell: `!`, `as`, or a swallowed `catch` sits in expression-shaped flow, a directive spans a strictness or parity finding, or a same-name `interface` merge promises members nothing implants.
- Collapse: move the proof into the key type, the decode seam, or the declaration; author the member on the class or route the promise to its implanting machine; confine what survives to the marked kernel.
- Done when: every assertion site sits inside a `// BOUNDARY ADAPTER` kernel with its local evidence, and every merged member traces to the machine that installs it.

[IMPORT_NOISE]:
- Smell: two import statements share a specifier, a binding aliases a shadowed global, or a value import serves only type positions.
- Collapse: one statement per specifier with inline `type` specifiers, the canonical binding with `globalThis.<Name>` at the seam, `import type` for the fully erased statement.
- Done when: imports state their erasure truthfully and no alias renames a canonical module binding.
