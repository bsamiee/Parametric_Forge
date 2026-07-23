export const meta = {
    name: 'stack-ts',
    whenToUse: 'Iterative adversarial hardening of the docs/stacks/typescript code doctrine; re-run until cold passes find nothing.',
    description:
        "Adversarial HARDEN engine for the docs/stacks/typescript code doctrine. Every page is SUSPECT until it survives attack — naive, shallow, or illusory by default, rebuilt ground-up wherever the attack finds weakness — but the settled atlas roster is challenged with disqualifying evidence, never re-decided from zero. Inventory rules the real disk state and the Gate rules the file set BEFORE per-file work (structure challenge: merge/split/kill/rename only on disqualifying evidence, applies structure only) — true data dependence, kept. Then each FILE runs its own initial -> critique -> redteam pipeline, ALL files concurrent under one pool cap — the chain is the file's own stage dependence, never a corpus barrier. Critique and redteam read the LIVE corpus — the current on-disk state of every page, landed sibling hardening composed as found, a conflict resolved to the stronger form, never a revert — and edit ONLY their own file (the anti-collision rule among concurrent pipelines), reporting cross-file residuals. ONE terminal corpus agent then aligns cross-file seams, closes gaps, enforces the computation-law bodies, resolves every reported residual, and finalizes cold in one sweep. Every per-file stage and the corpus sweep carry a required-but-usually-empty harvest attestation RESTRICTED to reviewer/laws/constitution altitudes (the run authors docs/stacks/typescript, so a stacks lesson is already owned and never nominated); when the pooled nominations are non-empty, ONE terminal doctrine lander adjudicates them against docs/laws (refutation-first, land-nothing legal, never re-editing a docs/stacks/typescript page). SUPREMACY LAW: python and csharp stacks are BOTH the floor, never the ceiling. Every edit is scoped to docs/stacks/typescript. Takes no args.",
    phases: [
        {
            title: 'Inventory',
            detail: 'read-only recon: real page set in atlas order, per-page facts-only capability map — verified members, sibling seams, stacking guidance',
            model: 'opus',
        },
        {
            title: 'Gate',
            detail: '1 agent: challenge the settled atlas structure with disqualifying evidence; apply approved renames/skeletons only, never content',
        },
        {
            title: 'Harden',
            detail: 'per FILE: initial -> critique -> redteam chained within the file; all files concurrent under one pool cap; critique/redteam read the live corpus and edit only their own file',
        },
        {
            title: 'Corpus',
            detail: 'ONE terminal writer: align seams, close gaps, computation-law bodies, resolve every reported residual, finalize cold',
        },
        {
            title: 'Doctrine',
            detail: 'terminal doctrine lander, fires only on non-empty pooled harvest RESTRICTED to reviewer/laws/constitution (the run owns docs/stacks/typescript); refutation-first, land-nothing legal',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const CAP = 14;
const ROOT = 'docs/stacks/typescript';

// --- [MODELS] --------------------------------------------------------------------------

const INVENTORY_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files'],
    properties: {
        files: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['path', 'order', 'map'],
                properties: { path: { type: 'string' }, order: { type: 'integer' }, map: { type: 'string' } },
            },
        },
    },
};
const GATE_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'rationale', 'renames'],
    properties: {
        files: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['path', 'order', 'charter', 'isNew'],
                properties: { path: { type: 'string' }, order: { type: 'integer' }, charter: { type: 'string' }, isNew: { type: 'boolean' } },
            },
        },
        renames: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['from', 'to'],
                properties: { from: { type: 'string' }, to: { type: 'string' } },
            },
        },
        rationale: { type: 'string' },
    },
};
// Altitude is RESTRICTED to surfaces this run does NOT author: the run owns docs/stacks/typescript, so a stacks nomination is already landed.
const HARVEST = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['altitude', 'lang', 'claim', 'anchors', 'existingClause'],
        properties: {
            altitude: { type: 'string', enum: ['reviewer', 'constitution', 'laws'] },
            lang: { type: 'string' },
            claim: { type: 'string' },
            anchors: { type: 'array', items: { type: 'string' } },
            existingClause: { type: 'string' },
        },
    },
}; // doctrine nominations — generalizable lessons only; the terminal doctrine lander adjudicates every row

const DOCTRINE_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['landed', 'refined', 'rejected', 'files', 'summary'],
    properties: {
        landed: { type: 'array', items: { type: 'string' } },
        refined: { type: 'array', items: { type: 'string' } },
        rejected: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['claim', 'reason'],
                properties: { claim: { type: 'string' }, reason: { type: 'string' } },
            },
        },
        files: { type: 'array', items: { type: 'string' } },
        summary: { type: 'string' },
    },
};

const FIXLOG_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['file', 'verdict', 'summary', 'collapsed', 'extended', 'regions', 'harvest', 'residual_high'],
    properties: {
        file: { type: 'string' },
        verdict: { type: 'string', enum: ['rebuilt', 'refined', 'clean'] },
        collapsed: { type: 'string' },
        extended: { type: 'string' },
        regions: { type: 'array', items: { type: 'string' } },
        harvest: HARVEST,
        residual_high: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['files', 'claim'],
                properties: { files: { type: 'array', items: { type: 'string' } }, claim: { type: 'string' } },
            },
        },
        summary: { type: 'string' },
    },
};

// Required-but-possibly-empty `beyond` is an attestation: the terminal agent's own hunt ran, not only the residual list.
const CORPUS_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'resolved', 'beyond', 'rejected', 'harvest', 'summary'],
    properties: {
        files: { type: 'array', items: { type: 'string' } },
        resolved: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['claim', 'action'],
                properties: { claim: { type: 'string' }, action: { type: 'string' } },
            },
        },
        beyond: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['target', 'action'],
                properties: { target: { type: 'string' }, action: { type: 'string' } },
            },
        },
        rejected: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['claim', 'reason'],
                properties: { claim: { type: 'string' }, reason: { type: 'string' } },
            },
        },
        harvest: HARVEST,
        summary: { type: 'string' },
    },
};

// --- [DOCTRINE] ------------------------------------------------------------------------

const LAW = [
    'TARGET: docs/stacks/typescript/ is the route-owned TypeScript CODE DOCTRINE — a doc set of AGNOSTIC teaching pages that legislate how all ' +
        'project TypeScript is written. It is NOT a libs/typescript/.planning design corpus: a page teaches a coding LAW with exemplary agnostic ' +
        'snippets, never a concrete module. The README owns routing + the doctrine laws + the COLLAPSE_SCAN; each concept page owns ONE disjoint ' +
        'layer and states doctrine as fact. READ docs/stacks/typescript/README.md sections [02], [03], [05], [06] and hold them as law.',
    'LAWS — read `docs/laws/` before any durable edit (README + topology + patterns + scars; short registry pages): a topology row whose ' +
        '[SURFACE] your edits touch binds its obligated counterparts into the SAME pass, and every patterns row binds each branch it names ' +
        '(the python/csharp/typescript parity coupling is a patterns concern).',
    'SUPREMACY LAW: docs/stacks/python/ and docs/stacks/csharp/ are BOTH the floor, never the ceiling — read both READ-ONLY for the shared shape ' +
        'laws (SHAPE_BUDGET/DEEP_SURFACES/MODAL_ARITY/ANTICIPATORY_COLLAPSE/POLICY_VALUES) and page craft, then legislate PAST them wherever a ' +
        'TS-native mechanism (structural typing, literal inference, the satisfies algebra, type-level derivation, declaration merging) admits a ' +
        'stronger law than either sibling can express. A TS page that merely matches the sibling bar where TS allows more is itself a finding. The ' +
        'spellings are TypeScript`s own — never a C#/LanguageExt or Python idiom transliterated.',
    'WRITE-FULLY MANDATE, scoped to docs/stacks/typescript/** ONLY: every defect you identify you FIX NOW via Edit/Write directly in the file; the ' +
        'fix-log you return is a REPORT of edits ALREADY MADE, never a ledger or a would/should hedge. Edit ONLY files under docs/stacks/typescript/; ' +
        'reading csharp/python/standards/.api files is allowed, editing anything outside docs/stacks/typescript/ is forbidden. Leave nothing behind ' +
        'except a genuine cross-FILE defect a concurrent sibling pipeline owns — report it in residual_high; the terminal corpus agent resolves ' +
        'every reported residual in this same run.',
].join('\n');

const ADVERSARIAL = [
    'ADVERSARIAL STANCE — EVERY stage is HOSTILE: assume the page is NAIVE, SHALLOW, or ILLUSORY until it survives an aggressive attack; the burden ' +
        'of proof is ON THE PAGE. `finalized`, "mature", "already strong", "good enough", and a prior `clean` grade are REJECTED self-assessments. ' +
        'Where the attack finds weakness, rebuild that surface GROUND-UP to the strongest form the doctrine admits — never polish a weak base; a ' +
        'no-edit verdict is EARNED only by an attack that finds nothing, and never invent churn to force a verdict.',
    'ILLUSORY / FAKE content is the PRIMARY target: a snippet that READS dense yet demonstrates a THIN slice; prose that ASSERTS richness the fence ' +
        'lacks; a card field that decides nothing; a structurally-correct collapse that is semantically empty; a member cited but unverifiable (a ' +
        'PHANTOM — delete it). Treat confident-looking fences with MORE suspicion, and DISBELIEVE every claim the page makes about itself until verified.',
    'NAIVETY is a defect on TWO orthogonal axes, both intolerable: COVERAGE — the owner models a THIN SLICE of its concept (the obvious three ' +
        'fields where the domain carries fifteen; a two-case family for a twenty-case space); APPROACH — enumerated hardcoded instances where a ' +
        'parameterized, algorithmic owner should GENERATE the space (a fixed roster of styles, patterns, or variants is seed DATA feeding ONE ' +
        'generator over named parameters, never the mechanism itself).',
].join('\n');

const TS_DOCTRINE = [
    'HOLD the docs/stacks/typescript/README [02]-[DOCTRINE] laws + the [03]-[COLLAPSE_SCAN] signals as fact, never restated on a concept page. ' +
        'BOUNDARY_ADMISSION: raw is admitted EXACTLY ONCE through a Schema decode at the edge into an evidence-carrying owner; the interior never ' +
        're-validates, never sees `unknown`/`null`-as-failure/provider shape. Run the COLLAPSE_SCAN on every fence: any signal triggers the move — ' +
        'shapes sharing an identity regime, an admission path, a payload timing, or a consumer collapse into ONE owner, and a shape survives only on ' +
        'a genuinely distinct discriminant — and the signal list is a FLOOR, never the complete set: hunt collapse targets beyond it, in any repeated ' +
        'structure, parallel spelling, or enumerable family an algebra, table, fold, or generator can own.',
    'A page that demonstrates a coding law must itself obey every law it can reach — the doctrine pages are the reference implementation of the ' +
        'doctrine.',
].join('\n');

const TS_SHAPE = [
    'EXTREME SHAPE/TYPE DENSITY + ONE CANONICAL FORM (the central mandate): one concept owns exactly ONE canonical declaration — a `Schema` owner ' +
        '(class-based `Schema.Class`/`Schema.TaggedClass` or a schema value with `Schema.Schema.Type<typeof X>` derivation), a value-derived ' +
        'vocabulary table, or ONE exhaustive discriminated union — and every secondary surface DERIVES from it. SCHEMA AUTHORITY: the Schema owner ' +
        'is the single shape authority — static types derive (`Schema.Schema.Type`/`Schema.Schema.Encoded`, `X.Type` on class owners), wire twins ' +
        'derive through `Schema.transform`/encodings, NEVER a hand-declared parallel interface/DTO. ABSOLUTELY FORBIDDEN: a `const X` + `type X` + ' +
        '`typeof X` triple for ONE concept; loose `interface`/`type`-alias proliferation; `any`/`as any`/`as unknown as`; `enum` (a literal union or ' +
        'Schema literal); structural-duplicate shapes; tag-only wrappers; free-floating one-field brands (brands live INSIDE rich owners as Schema ' +
        'refinements).',
    'SHAPE BUDGET AT 20%: the doctrine drives generated code to roughly one fifth of the shape count of naive TS — one deep, rich, nested owner ' +
        '(embedded sub-schemas, class-carried methods and derivations, growth axes anticipated at 5x demand) replaces five or more loose interfaces, ' +
        'aliases, DTOs, and scattered brands. ANTICIPATORY_COLLAPSE: shape the owner for the family it WILL absorb so the next case/dimension/' +
        'modality lands as ONE declaration with every consumer broken loudly at type-check — one owner READY TO REPLACE 10+ loose things. ' +
        'Discriminated unions are EXHAUSTIVE (total dispatch via `Match.exhaustive` or a checked `never` sink, never a silent default). The ' +
        'exemplary snippet MUST show the owner at large-system scale with the growth axis visible.',
    'VALUE-DERIVED VOCABULARY: one `as const satisfies <Contract>` table is the single source of truth for a vocabulary — `satisfies` validates ' +
        'against the contract WITHOUT widening the inferred literal shape; `typeof`/`keyof typeof`/indexed-access derive the types FROM the value; ' +
        'mapped + template-literal + conditional types generate every secondary surface; a hand-written union, enum, or parallel constant a value ' +
        'table could derive is the named defect. ONE-NAME EXPORTS: a concept exports ONE name serving value and type (declaration merging, ' +
        '`Schema.Class` owners where the class IS both, const+type same-name pairing) so a consumer takes a single import and never aliases, ' +
        're-derives, or writes `typeof` at the call site.',
].join('\n');

const TS_EFFECT = [
    'EFFECT-TS IS THE RAIL (ULTRA-CRITICAL): domain logic is `Effect`-shaped — dependent steps compose with `Effect.gen`/`pipe`/`flatMap`, ' +
        'independent ones accumulate (`Effect.all` with the right concurrency/mode); ZERO `throw` in domain logic (failures are typed in the `Effect` ' +
        'error channel as a closed `Data.TaggedError` family, never a bare `Error` or a string); ZERO raw `Promise` in domain flow (lift at the ' +
        'boundary). Recovery is `Effect.catchTag`/`catchTags`, retry is `Effect.retry(Schedule)`, resource lifetime is ' +
        '`Effect.acquireRelease`/`Scope`.',
    'CROSS-CUTTING capability — retry, telemetry/spans, validation, contracts, caching, receipts — composes as Effect combinators and ' +
        '`Layer`/`Context` services woven over a THIN PURE CORE, never inline-repeated or hand-rolled; co-occurring wrappers sharing an admission ' +
        'path collapse into ONE ' +
        'combinator/Layer. BOUNDARIES are SCHEMA-FIRST: decode-don`t-validate with the `effect` `Schema` module at ingress and egress, refined owners ' +
        'carry the proof inward, and the same owner sources and sinks across consumers without interior edits.',
].join('\n');

const TS_CORE_LOGIC = [
    'WORLD-CLASS ALGORITHMIC BODIES: every body that does real work is expression-shaped — a naive imperative `for`/`while` with mutable accumulation ' +
        'or an intermediate array where a combinator pipeline or fold expresses it is a DEFECT. Compose the `ReadonlyArray`/`Array`/`Iterable` ' +
        'combinator surface at depth (`reduce`/`flatMap`/`map`/`filter`/`zip`/`groupBy`/`partition`/`scan` — the Effect `Array`/`Chunk`/`Stream` ' +
        'operators, never an ad-hoc loop), or an `Effect`/`Stream` pipeline for effectful traversal (`Effect.forEach`/`Effect.reduce`/`Stream.run*` at ' +
        'the right concurrency); exhaustive dispatch (`Match.exhaustive`, satisfies-checked handler records, or a checked `never` sink) replaces ' +
        'imperative branching; `const`-asserted readonly data + structural pattern dispatch replace mutable scans. NO mutable accumulation in domain ' +
        'flow, NO intermediate array a fold would fuse, NO imperative loop where a total combinator expresses it.',
].join('\n');

const PARAM_POLY = [
    'HEAVY PARAMETERIZATION, ZERO HARDCODING/FRAGILE LOGIC, FULL POLYMORPHISM. ONE entrypoint owns every modality — `T | Iterable<T>` (or the ' +
        'Schema-discriminated request) normalized ONCE at the head, discriminating on input SHAPE, never a name suffix or a `mode`/`batch`/`strict` ' +
        'boolean knob (KNOB_TEST: delete each parameter; if the value reconstructs what it carried, it was a knob to collapse). OVERLOAD COLLAPSE: ' +
        'one entrypoint owns every call modality through overload signatures or a discriminated input union; arity twins and suffix families are the ' +
        'named defect. DUAL ENTRIES: an operator serves pipe and direct call through `Function.dual` data-first/data-last signatures — one function, ' +
        'both call shapes, never a parallel pair.',
    'Configuration enters as ONE behavior-carrying value — a literal-union member, a tagged variant, a frozen policy record (POLICY_VALUES) — never ' +
        'a flag set the body re-derives. A `timeout`/`retry`/`deadline` is an Effect aspect/`Schedule`, never a signature param. Cases sharing ' +
        'generative structure are DERIVED from one primary record/table, never enumerated arms. Capability exits through FEW dense unified entry ' +
        'points — one polymorphic entry per rail discriminating on input shape (single|batch|stream absorbed by input detection, forward and inverse ' +
        'directions on one surface), variation living in input shape, policy values, and table rows, never parallel exports or modality-named ' +
        'siblings; the surface narrows by absorption, never by omission.',
].join('\n');

const TS_LANG = [
    'BLEEDING-EDGE TypeScript ONLY (latest stable): `satisfies`, `const` type parameters, `NoInfer`, instantiation expressions, variance ' +
        'annotations (`in`/`out`), template-literal types, `using`/`await using` for disposables, the `infer`/conditional/mapped-type toolkit at ' +
        'full power. INLINE COMPOSITION: wrapping, injection, and decoration attach at the owner declaration (pipe composition at definition, HOF ' +
        'wrapping inline, satisfies-checked handler/method records), never as loose intermediate consts, separate helper declarations, or ' +
        'consumer-side reassembly; const type parameters, `NoInfer`, and instantiation expressions pre-solve inference at the owner so consumers ' +
        'never re-instantiate generics or re-assert literals. `import type`/`export type` stay explicit; value vs type imports never blur. ZERO ' +
        '`any`, `as any`, `as unknown as`, `@ts-ignore`/`@ts-expect-error`-without-reason, `enum`, `namespace`-as-scope, or `throw` in domain logic; ' +
        '`unknown` only at a boundary immediately decoded by a Schema.',
    'EXPORT LAW: a module NEVER exports inline at a declaration site — declarations are authored unexported and the file ends with ONE ' +
        '`// --- [EXPORTS]` block (`export { A, B }` + `export type { T, U }`) carrying the complete public surface; the one-name value/type merge ' +
        'and minimal-surface laws still hold — the exports block declares the surface, never widens it. An in-body `export const`/`export type`/' +
        '`export declare namespace` is the named defect. EXPORT-SURFACE COLLAPSE: the exports block is itself a collapse target — sibling exports ' +
        'serving one concept merge into ONE polymorphic export: modality (single/batch/stream) discriminates INSIDE on input shape, variants ride ' +
        'overloads/`Function.dual`, and companion types/helpers ride the SAME name via declaration merging (namespace merge: `Owner.Config`, ' +
        '`Owner.Outcome`) or the class owner — a consumer imports one canonical name and reaches everything. The bar is 1-2 exports per module, one ' +
        'per genuinely disjoint concept; a fold/type derivable from an exported owner is attached to it, never exported beside it; export names are ' +
        'the bounded context`s canonical semantic word, never suffix families. THE MECHANISM (done properly, never naively): interior anchors stay ' +
        'unexported (the key tuple, the row table); the ONE exported owner ASSEMBLES them — rows spread in, companion values as properties (the ' +
        'wire schema, the key tuple), operations as members with their inference intact — while a `declare namespace` type hub on the same name ' +
        'carries every derived type; derived discriminants keep anchoring on the INTERIOR row table (`keyof typeof rows`), never on the assembled ' +
        'owner where member keys would pollute the key space — the naive merge that breaks `keyof` derivation is the named trap.',
    'NOMINAL invariants ride Schema-refined brands INSIDE rich owners, so an interior function cannot be handed a raw primitive — never a ' +
        'free-floating one-field brand alias. No `const`+`type`+`typeof` triple for one concept (ONE canonical owner, derive the rest). Keep every ' +
        'choice CONSISTENT across the whole corpus so it reads as ONE unified, ultra-advanced shape system, never a patchwork.',
].join('\n');

const TS_CITATION = [
    'CITATION / LIBRARY DEPTH: the TS substrate is the Effect ecosystem (`effect` — Schema/Match/Data/Stream/Layer included — `@effect/platform`, ' +
        'and the admitted Effect packages) — mine each to its FULL advanced surface (the deep ' +
        'combinator/Schema/Layer/Stream/Schedule operators) and STACK them as ONE dense rail, never a flat one-shot per-API use or a `Promise`/' +
        'BCL-first reflex. Layer the Schema boundary + the Effect rail + the service `Layer`s together.',
    'ULTRA-STACKING: enumerate BOTH .api tiers IN FULL with a real listing — libs/typescript/.api/ (the substrate catalogs) and every ' +
        'libs/typescript/<folder>/.api/ — and mine them to OPERATOR DEPTH; an admitted capability the concept admits but no owner exploits is a ' +
        'DEFECT to close. Cite ONLY members that exist — verify novel members against the installed packages via `UV_CACHE_DIR=.cache/uv uv run ' +
        'python -m tools.assay api` over node_modules, and when assay is blocked via the installed `.d.ts` read directly, the .api ' +
        'catalogs, and Context7/exa/tavily against the official package docs, never memory; a member you cannot verify is a PHANTOM to delete. Use ' +
        'the DEEPEST primitive each package reaches (LIBRARY_DEPTH); flat code below that operator depth is surface sprawl.',
    'ECOSYSTEM-DEPTH MANDATE: `effect` and `@effect/experimental` carry far more than any doctrine currently uses — the installed .d.ts module ' +
        'roster (node_modules/effect/dist/dts/, node_modules/@effect/experimental/dist/dts/) is the coverage checklist: a module or combinator ' +
        'family with doctrine-grade decision weight that no page exploits is a COVERAGE gap you close on the owning page; the same law holds for ' +
        'every admitted satellite (@effect/platform*, rpc, cli, sql, opentelemetry, printer, ai). Surface-level use of a deep package is the same ' +
        'defect as omission.',
    'COVERAGE FLOORS (research-verified against the installed packages; each names capability the corpus must own a law for — verify the law ' +
        'exists on the owning page or close the gap; a floor is a floor, never the set): effect core — `ExecutionPlan` tiered failover as one ' +
        'value; the `Effect.cached`/`cachedWithTTL`/`cachedInvalidateWithTTL`/`cachedFunction`/`once` keyless memo family; ' +
        '`Effect.iterate`/`loop` + `when`/`unless` + `matchEffect`/`matchCauseEffect` closing statement kernels; `Schema.suspend` recursive ' +
        'owners, `Schema.Exit`/`Cause`/`Defect` outcome transport, `Schema.Config`, `attachPropertySignature`, `declare`/`instanceOf` foreign ' +
        'admission, the annotations discipline; `Stream.paginateEffect` pagination, `repeatEffectWithSchedule` polling, `changes`/`sliding`/' +
        '`zipWithPrevious`; `Schedule.resetAfter` reconnect correctness, `andThen` phase change, `CurrentIterationMetadata`, calendar gates; ' +
        '`Graph` (dijkstra/astar/topo/SCC/toMermaid) + `Trie` prefix owners; the resource-cell quartet `RcRef`/`ScopedRef`/`Resource`/' +
        '`ScopedCache` completing the contention axis; `RequestResolver.contextFromServices`/`batchN`/`aroundRequests`/`fromEffectTagged`; the ' +
        'lazy `Iterable` middle tier + `Array` long-tail sieves (`partitionMap`/`getSomes`/`window`/`mapAccum`); `Layer.scopedDiscard` ' +
        'registration law + `Layer.annotateLogs`/`span`; `Config.unwrap` nested records + `Config.branded`; the integration primitives ' +
        '`Effectable.Class`/`Streamable.Class`/`Unify.unify`/`GlobalValue.globalValue`/`Pipeable`/`Inspectable`/`PrimaryKey`; ' +
        '`Match.instanceOf` FFI triage + `Cause.squash`/`prettyErrors` forensics; `PartitionedSemaphore` fairness, `PubSub` replay, `HashRing` ' +
        'placement; the `Micro` BAN (one carrier, one runtime) and the `Effect.Do`/`bind` REJECT (gen is the sole do-notation). experimental — ' +
        '`Machine` as the runtime FSM owner (tagged request procedures, `forkOne` supervision, `snapshot`/`restore`, retry-as-Schedule; the ' +
        'award-grade state-machine exemplar); `ChannelSchema` as the GENERAL wire codec (MsgPack/Ndjson demote to rows); ' +
        '`RequestResolver.dataLoader`/`persisted`; `PersistedCache`+`Persistence` as the durable contention axis; `Reactivity` keyed ' +
        'invalidation; the store-backed `RateLimiter` vs in-process row. platform — `HttpIncomingMessage` as the one ingress-decode owner; ' +
        '`HttpTraceContext` propagation codecs; `Effectify.effectify`; `Transferable.Collector`; `KeyValueStore.layerSchema`. rpc — the protocol ' +
        'x serialization vocabulary matrix. opentelemetry — the `Otlp.layer` export seam sentence. TS7 type plane — reverse-mapped inference ' +
        'owners (per-row contextual typing, zero call-site ceremony; relation depth 2 keeps rows shallow); the `unique symbol` TypeId + ' +
        'variance-struct phantom brand regime (disjoint from Schema.brand by plane); overload ordering strictly narrow->wide with the ' +
        'dead-signature ban (first-match resolution silently mis-dispatches — verified); the numeric type-plane budgets (~800 tail / ~40 non-tail ' +
        'iterations, 10^4 template axes; TS2589/TS2590 are architecture pressure — move to the value level, never suppress); the registry merge ' +
        'seam (the ONE sanctioned open interface: contributors inject rows via `declare module` at the declaring module); `satisfies never` ' +
        'kernel residue proof; ASCII-bounded type-level string decomposition (Corsa/Strada code-point divergence); variadic-tuple owner ' +
        'combinators; `import defer` as boot-edge-only vocabulary; class-interface merging gated to the implanting seam. ADMISSION FACTS: ' +
        '`ExecutionPlan`/`PartitionedSemaphore`/`HashRing`/`Graph` carry @experimental tags — laws state it. ANTI-FABRICATION (confirmed absent ' +
        'in the installed releases — never cite): `RequestResolver.grouped`, `RequestResolver.setDelay`, `Record.upsert`, `Schedule.both`, ' +
        '`Layer.parent`, `DateTime.zonedNow`, `Runtime.enableRuntimeMetrics`.',
].join('\n');

const PAGECRAFT = [
    'PAGE-CRAFT LAW (README [05]-[PAGE_CRAFT]): page grammar is a NARROW index table, then deep FAMILY CARDS, then the region snippet beside the ' +
        'rule it proves; the page ends at its last card. CARD ECONOMY: cards are few, deep, evidence-dense; near-peer cards MERGE until each owns a ' +
        'decision cluster; a card line carries exactly ONE decision; a `Use`/`Accept`/`Reject`/`Law`/`Boundary` field appears only where it decides ' +
        'something — a field that decides nothing is DELETED, not filled. Tables enumerate, cards legislate (rows stay atomic, no prose cramming, no ' +
        'links in cells).',
    'REJECT columns are LOAD-BEARING: every `Use` names the spelling, wrapper, or local pattern it DELETES (a junior TS reflex — `any`, an `enum`, a ' +
        'hand-thrown error, a const+type+typeof triple, a hand-declared wire twin — is exactly what a Reject names). CODE NAMES BEFORE PROSE: every ' +
        'member a card or snippet names is verified against the installed package before written; a nameable surface spelled as prose is a defect. ' +
        'ZERO META: no provenance, source trace, release narration, process state, or tool/skill context — any such block POISONS every downstream ' +
        'generation that loads the page.',
].join('\n');

const AGNOSTIC_SNIPPETS = [
    'AGNOSTIC SNIPPET LAW (style-guide [07]-[PLACEHOLDER_LAW]): every snippet COMPILES under the active TypeScript surface with legal NEUTRAL ' +
        'identifiers — `Shape`/`RefinedShape`/`Variant`/`PRIMARY`/`Field`/`KEY`/`Row`/`ROW_A`/`TABLE`/`SELECTED` — and placeholder strings ' +
        '(`"<value-a>"`) appear ONLY inside literals. NO project, repo, host, customer, pricing, deployment, or business-domain noun anchors a ' +
        'snippet; a domain noun is context poison.',
    'CORPUS-WIDE ZERO duplicated snippet demonstrations: each snippet exercises a surface region NO OTHER snippet in the corpus shows — the region ' +
        'is its spotlight; finalized surfaces composed as supporting material occupy no region and duplicate nothing. A duplicated region is repaired ' +
        'by ROUTING to its owner, never by re-teaching. Snippets are doctrine-exemplary at full operator depth, ~3-4x denser than ordinary code, at ' +
        'the scale a large system takes (admission + dispatch + rail + policy in one fence with the growth axis visible).',
].join('\n');

const OPINIONATED = [
    'HEAVILY-OPINIONATED PROJECT DOCTRINE, NOT a language survey. ZERO table-stakes is tolerated, ever: a card or snippet teaching something a ' +
        'competent TypeScript developer already knows — rather than an opinionated, dense, project-specific CHOICE — is a DEFECT to delete or densify. ' +
        'No net-casting to "cover the language"; cover only the opinionated decisions the projects need, each at 13/10.',
    'LOC affordance: 350-400 per page, 450 only where truly earned. Density comes from card COMPLEXITY, never card/snippet spam — a new card only ' +
        'where a real decision cluster justifies it, placed per page craft. NEVER strip snippet whitespace, remove design content, or fragment a ' +
        'coherent concept to hit a number; a split is justified ONLY by concept disjointness, never by line count.',
    'EXEMPLAR FENCES: where a page`s layer admits it, at least one fence reads as an award-grade implementation — the meat-and-bones code a ' +
        'world-class engineer would study (a Machine-backed state machine, a fused fold pipeline, a request-batched resolver, a derivation tower) — ' +
        'never a toy slice; the algorithmic-bodies page owns the deepest of these and later pages compose it.',
].join('\n');

const STYLE_PROSE = [
    'PROSE QUALITY — apply docs/standards/style-guide.md: lead each section with the controlling rule/contract; one idea per paragraph; close on the ' +
        'consequence or boundary. Cut hedges (`may`/`might`/`probably`/`generally`/`where possible`/`if needed`), provenance, process narration, and ' +
        'report framing. Prefer a table, a typed signature block, or a tight bullet wherever it carries the design better than a paragraph. Prose that ' +
        'ASSERTS capability the fence lacks is a defect, not content.',
    'BACKTICK ALL CODE: wrap every symbol, type, field, function, operator, package ID, path, command, flag, and literal value in a code span; name ' +
        'the exact member instead of paraphrasing behavior. Trimming prose MUST NOT reduce technical density or remove design content.',
].join('\n');

const COMMENTS =
    'COMMENT HYGIENE: code fences are agent-facing. KEEP the canonical section-divider headers (`// --- [UPPERCASE_LABEL]` ' +
    'dash-fill). Beyond dividers, comment ONLY where intent is not already obvious from names, types, and signatures: default ZERO comments; at most ' +
    '1 line where a comment genuinely earns its place; 1-2 lines only for a truly subtle invariant or boundary. No narration, no restating the code, ' +
    'no TSDoc bloat, no task/process/review comments.';

const CURRENT_STATE =
    'CURRENT STATE — sibling pages are being hardened concurrently by their own file pipelines, each at its own stage. Before ' +
    'any edit, re-read the CURRENT on-disk state of the README and every corpus page your page cross-references; landed sibling hardening is ' +
    'composed AS FOUND, never assumed settled. A conflict between your page and a landed sibling resolves to the STRONGER form, never a revert. ' +
    'You EDIT ONLY your own file while pipelines run — the anti-collision rule; a genuinely cross-file defect is a residual_high the terminal ' +
    'corpus agent resolves in this same run, never a sibling edit.';

const HARVEST_LAW =
    'HARVEST (required key, usually empty): this run AUTHORS the docs/stacks/typescript corpus, so a stacks-altitude lesson is already owned by ' +
    'the run and is NEVER nominated. Nominate ONLY a lesson that lands at an altitude this run does NOT own — reviewer (a diff-checkable review ' +
    'rule that would have caught a defect BEFORE review), constitution (a most-sessions CLAUDE.md/AGENTS.md behavioral fact), or laws (a ' +
    'cross-surface coupling or cross-branch pattern discovered the hard way). Each row: altitude (reviewer|constitution|laws), lang, claim (the ' +
    'generalized law, one sentence), anchors (file:line evidence), existingClause (the exact reviewer/laws/constitution clause it would harden, ' +
    'quoted with its path — or "absent" and the surfaces searched). A page-local fix never nominates; an empty array is the normal verdict — ' +
    'the terminal doctrine lander refutes weak rows, so nominate substance, never volume.';

const DOCTRINE = [
    LAW,
    '',
    ADVERSARIAL,
    '',
    TS_DOCTRINE,
    '',
    TS_SHAPE,
    '',
    TS_EFFECT,
    '',
    TS_CORE_LOGIC,
    '',
    PARAM_POLY,
    '',
    TS_LANG,
    '',
    TS_CITATION,
    '',
    PAGECRAFT,
    '',
    AGNOSTIC_SNIPPETS,
    '',
    OPINIONATED,
    '',
    STYLE_PROSE,
    '',
    COMMENTS,
].join('\n');

// --- [OPERATIONS] ----------------------------------------------------------------------

// The single scheduler for every agent-bearing task in the run: CAP tasks in flight.
const pool = async (items, cap, worker) => {
    const out = new Array(items.length);
    let next = 0;
    const run = async () => {
        while (next < items.length) {
            const i = next++;
            out[i] = await worker(items[i], i);
        }
    };
    await Promise.all(Array.from({ length: Math.min(cap, items.length) }, () => run()));
    return out;
};
const nameOf = (p) => (p.indexOf(ROOT + '/') === 0 ? p.slice(ROOT.length + 1) : p);

// Workers see the ordered path list + their OWN charter only — never sibling charters, renames, or the gate rationale.
const archLine = (paths, charter) =>
    '\nSETTLED ATLAS (ordered paths; an initial pointer, never a ceiling — re-read everything from disk, it ' +
    'never licenses a skim):\n' +
    JSON.stringify(paths) +
    (charter ? '\nTHIS PAGE`S CHARTER (honor it; siblings honor their own): ' + charter : '');

const authorPrompt = (page, paths, charter) =>
    [
        DOCTRINE,
        '',
        HARVEST_LAW,
        '',
        'TASK: INITIAL STAGE — ADVERSARIAL HARDEN-REBUILD of ' +
            page +
            ' to the ULTRA-DENSE ' +
            'TypeScript doctrine bar; you own THIS file alone (siblings are mid-pipeline in their own concurrent hardens — do not read or edit them; ' +
            'corpus composition belongs to critique/redteam and the terminal corpus agent). Attack the page as naive/shallow/illusory; wherever the attack ' +
            'lands, rebuild that ' +
            'surface GROUND-UP to 13/10 — never polish a weak ' +
            'base. Read the page, the README atlas + doctrine (binding law), the python + csharp stacks (the FLOOR, ' +
            'READ-ONLY), the style-guide, and verify members against the Effect ecosystem (assay api over node_modules; assay unavailable — the installed ' +
            '`.d.ts` directly + the .api catalogs + Context7/exa/tavily). Construct in ' +
            'BOUNDARY_ADMISSION lifecycle order (Schema decode at the edge); collapse parallel shapes into ONE canonical owner with every secondary ' +
            'surface DERIVED — and KILL every const+type+typeof triple, loose interface/type-alias spam, hand-declared wire twin, free-floating brand, ' +
            '`any`, `enum`, and hand-thrown error; weave cross-cutting concerns as Effect combinators/Layers over a thin pure core; parameterize fully; ' +
            'one polymorphic entrypoint per modality with dual data-first/data-last signatures where the operator warrants both. ' +
            'CAPABILITY-COMPLETENESS IS MANDATORY, NOT OPTIONAL: every owner you author implements what its names and prose promise — a ' +
            'named-but-omitted capability (a case, field, operation, or derivation the concept admits and a card claims) is a defect you close ' +
            'NOW at the same bar as any finding, never a stub dressed as finished. Make every snippet ' +
            'AGNOSTIC (neutral names), compiling, ~3-4x denser than ordinary code, one owner ready to replace 10+ loose things with the growth axis ' +
            'visible. Cut every table-stakes card/snippet. Apply page-craft + style/comment hygiene. Report `collapsed`, `extended`, and the page`s ' +
            'spotlight `regions`. Return residual_high {files:[...], claim}.' +
            archLine(paths, charter),
    ].join('\n');

const critiquePrompt = (page, paths, charter) =>
    [
        DOCTRINE,
        '',
        CURRENT_STATE,
        '',
        HARVEST_LAW,
        '',
        'TASK: CRITIQUE STAGE — HOSTILE DOCTRINAL-CONFORMANCE AUDIT + FIX IN PLACE of ' +
            page +
            '. ULTRA-HARSH, UNAGREEABLE: assume a violation ' +
            'exists in EVERY fence; trust NOTHING the prose claims; "good enough" rejected. CORPUS AWARENESS: read the README + EVERY file under ' +
            'docs/stacks/typescript/ from CURRENT disk so your judgments are corpus-aware (vocabulary consistency, region overlap, altitude) per ' +
            'CURRENT STATE — you EDIT ONLY ' +
            page +
            '. Also read the python + csharp stacks ' +
            '(the floor), the style-guide, and verify members via assay api (assay unavailable: the installed `.d.ts` / the .api catalogs / ' +
            'Context7/exa/tavily). Run the MECHANICAL checklist LINE-BY-LINE and REPAIR every hit ' +
            'in place — every hit a fix, never a note; the checklist is a FLOOR, never the complete audit: hunt doctrinal defects past it:',
        '(1) COLLAPSE_SCAN signals (shapes sharing an identity regime, admission path, payload timing, or consumer collapse into ONE owner; a shape ' +
            'survives only on a genuinely distinct discriminant): sibling names -> one polymorphic entrypoint; arity variants -> input-shape discrimination or ' +
            'overloads; literal-only differences -> a POLICY_VALUE; boolean selecting bodies -> derived/policy; one-hop function -> delete; parallel ' +
            'dispatch arms -> a satisfies-checked record/table or fold; types sharing fields -> one closed family; recurring wrappers -> one ' +
            'combinator/Layer — a FLOOR: hunt collapse targets beyond it. (2) ONE-CANONICAL-FORM + SCHEMA AUTHORITY -> replace any non-canonical owner; ' +
            'ELIMINATE every const+type+typeof triple (derive via `Schema.Schema.Type`/`typeof`), every hand-declared wire twin (derive via ' +
            '`Schema.transform`), loose interface/type-alias proliferation, tag-only wrappers, free-floating brands, and any hand-written union a value ' +
            'table could derive — sweep the WHOLE page for every loose const/type and collapse each into its owning rich declaration, including the ' +
            'exports block per EXPORT-SURFACE COLLAPSE. (3) KNOB_TEST -> collapse boolean/mode/strict knobs to policy values or input-shape; move ' +
            '`timeout`/`retry`/`deadline` to an Effect aspect/`Schedule`.',
        '(4) EFFECT RAIL + SCHEMA BOUNDARY -> domain logic is `Effect`-shaped; ZERO `throw`/raw `Promise` in domain flow; failures are a closed ' +
            'tagged-error family in the error channel; recovery via `catchTag(s)`, retry via `Schedule`, resources via `acquireRelease`/`Scope`; ' +
            'boundaries decode-not-validate with the `effect` Schema module; cross-cutting concerns are combinators/Layers, never inline. (5) TYPES -> ' +
            'ZERO `any`/`as any`/`as unknown as`/`enum`/`namespace`-as-scope; `unknown` only at a Schema boundary; refined owners carry invariants ' +
            'inward; exhaustive dispatch via `Match.exhaustive`/checked `never` sink; inference pre-solved at the owner (const type params, `NoInfer`, ' +
            'instantiation expressions — a consumer forced to alias, re-instantiate, or `typeof` is a defect); `import type` discipline; latest TS only. ' +
            '(6) CITATION/DEPTH -> mine the Effect ecosystem to full depth and STACK it; every member verified (delete phantoms); no flat single-API use ' +
            'below the operator depth the packages reach.',
        '(7) AGNOSTIC snippet law -> compiles, neutral names, no business noun, large-system scale. (8) PAGE GRAMMAR + card economy + load-bearing ' +
            'reject columns (each `Use` names the junior reflex it deletes). (9) ALTITUDE / NO RE-TEACH -> route any mechanic a finalized prior page owns. ' +
            '(10) ZERO META + style + comments. (11) UNIFIED SHAPE SYSTEM -> this page`s shapes are CONSISTENT with the sibling pages as they NOW stand ' +
            '(one corpus-wide ' +
            'shape vocabulary, not a patchwork). (12) CAPABILITY-COMPLETENESS + NAIVETY + ILLUSION + TABLE-STAKES -> close any capability the ' +
            'Effect surface or the real concept admits that the owner OMITS (case/row/field/operation) with a cite — COVERAGE naivety; rebuild any ' +
            'enumerated roster of hardcoded instances into ONE generator over named parameters with the roster as seed data — APPROACH naivety; delete ' +
            'any table-stakes/decorative/speculative card or snippet. EDIT to fix every hit. Report `extended` and `regions`. Return residual_high ' +
            '{files:[...], claim}.' +
            archLine(paths, charter),
    ].join('\n');

const redteamPrompt = (page, paths, charter) =>
    [
        DOCTRINE,
        '',
        CURRENT_STATE,
        '',
        HARVEST_LAW,
        '',
        'TASK: RED-TEAM STAGE — ADVERSARIAL ARCHITECT ATTACK + FIX IN PLACE of ' +
            page +
            ' — the LAST and MOST AGGRESSIVE per-file stage. Red-team is ' +
            'critique AND MORE; the burden of proof is ON THE PAGE; trust NOTHING the prior stages claimed. CORPUS AWARENESS: read the README + EVERY ' +
            'file under docs/stacks/typescript/ from CURRENT disk per CURRENT STATE — you EDIT ONLY ' +
            page +
            '. Open the Effect ecosystem, ' +
            'the python + csharp stacks (the floor), the style-guide. Attack and REPAIR in place — no soft-pedalling, a fix never a ledger:',
        'LENSES: (A) COUNTERFACTUAL on the core teaching shape — a counterfactual REBUILDS the design with its central assumption removed, ' +
            'never merely questions it: name the assumption the fence stands on (the chosen owner kind, the hand-enumerated space, the ' +
            'call-site dispatch, the shallow Effect use), derive the form the page takes WITHOUT it — a denser canonical owner (a richer ' +
            'Schema class family, a value-derived vocabulary table, an exhaustive DU) or a DEEPER Effect primitive — and where the rebuilt ' +
            'form is stronger, BUILD IT IN PLACE; a stronger design once seen is never defended against, and "the current shape also works" ' +
            'is not a refutation. (B) ANTICIPATORY_COLLAPSE — does ' +
            'the next case/variant land as ONE declaration with consumers broken loudly at type-check? reshape so the growth axis is a case/row/policy ' +
            'value. (C) CORPUS-WIDE UNIFICATION + DUPLICATION — is this page`s shape vocabulary IDENTICAL in spirit to every sibling as it NOW stands ' +
            '(one unified system, ' +
            'zero patchwork), and does any snippet re-demonstrate a region a sibling owns (route it)? (D) SHAPE-BUDGET + EFFECT MAXIMIZATION — hunt EVERY ' +
            'residual loose interface/type-alias, every const+type+typeof triple, every hand-declared wire twin, every consumer-side re-derivation an ' +
            'owner should pre-solve, every `any`/`enum`/`throw`/raw `Promise`, every non-Schema boundary, every inline cross-cutting concern, and ' +
            'rebuild it to the canonical owner / Effect rail / Schema boundary; push more functionality into combinators/Layers over a thinner pure ' +
            'core. (E) DEPTH + PHANTOMS -> flat code below the Effect operator depth (collapse to package depth); a phantom member (delete it). (F) ' +
            'SUPREMACY — where a sibling-stack law has a TS-native stronger form (value derivation, inference pre-solving, declaration merging, dual ' +
            'signatures), the page must legislate the STRONGER form; matching the floor where TS allows more is a finding you fix. (G) ' +
            'CAPABILITY-COMPLETENESS + NAIVETY + LONG-TAIL + ILLUSION + TABLE-STAKES -> attack the long tail of the concept: the edge cases, failure ' +
            'modes, and family members a thin slice ignores; name an omitted capability with a cite and extend the owner in place (COVERAGE naivety); ' +
            'rebuild any enumerated roster of hardcoded instances into ONE generator over named parameters, roster as seed data (APPROACH naivety); ' +
            'delete table-stakes/decorative/speculative content.',
        'ALSO — FULL COLD ADVERSARIAL RE-REVIEW: re-attack every critique dimension with fresh hostile eyes. The page must end objectively denser, MORE ' +
            'capable, more agnostic-compliant, more bleeding-edge, and PART OF ONE UNIFIED SHAPE SYSTEM more than the critique left it; if the strongest ' +
            'form is genuinely present, prove it by finding nothing — never invent churn. Report `extended` and `regions`. Return residual_high ' +
            '{files:[...], claim}.' +
            archLine(paths, charter),
    ].join('\n');

const corpusPrompt = (ordered, residuals, failed) =>
    [
        DOCTRINE,
        '',
        HARVEST_LAW,
        '',
        'THE SETTLED ATLAS (order):\n' + JSON.stringify(ordered, null, 1),
        '',
        'TASK: TERMINAL CORPUS SWEEP (WRITER — no agent edits a docs/stacks/typescript page after you; the per-file pipelines are done and every page is on ' +
            'CURRENT disk). Read the README first, then every atlas page IN FULL in atlas order — the order IS the implementation chain: each page ' +
            'composes every earlier page`s law as settled material, so walk the chain and attack every seam where a later page restates, contradicts, or ' +
            'under-uses an earlier owner. WRITE every fix in place via Edit/Write across ANY page under ' +
            ROOT +
            '/ — a finding is a fix, never a note. ' +
            'The sweep owns FIVE mandates at once:',
        '(1) ALIGN — the corpus as ONE body: one unified shape vocabulary across all pages (identical spellings for shared rails, owners, fault ' +
            'families, policy forms); zero duplicated snippet regions corpus-wide (each fence exercises a region no other fence shows — repair by ' +
            'routing to the owning page, never by re-teaching); altitude (each page owns ONLY its layer; later atlas pages compose earlier law as ' +
            'settled supporting material, never restate it); the README atlas table, routing rows, and law groups match the on-disk corpus exactly. ' +
            '(2) GAP-CLOSE — every COVERAGE FLOOR and CONTENT MANDATE has an owning law on the right page and every fence demonstrates the mandates its ' +
            'layer admits (satisfies tables, one-name exports + the exports block, inline injection/wrapping, overload/dual entries, inference ' +
            'pre-solving, nested Schema owners); enforce the EXPORT LAW and EXPORT-SURFACE COLLAPSE in every snippet corpus-wide; spot-verify named ' +
            'members (assay api, or the installed `.d.ts` + the .api catalogs + Context7/exa/tavily when assay is unavailable) and delete phantoms. ' +
            '(3) COMPUTATION-LAW BODIES — the algorithmic-bodies page legislates every working body in the corpus: audit EVERY fence on EVERY page ' +
            'against its law — seed folds over mutable accumulation, scan for running traces, lazy Iterable pipelines materialized once at the tail, ' +
            'window/zip/groupBy co-iteration, `Array.mapAccum` stateful steps, Match-driven structural recursion, tabulation-as-fold memoization, ' +
            'kernels only where EARNED beside their named Exemption — and rebuild any body below that bar in place; a fence whose body computation law ' +
            'would rewrite is a defect on ITS page, whatever the page`s own layer. ' +
            '(4) RESIDUALS — the cross-file residuals below are SIGNALS the per-file pipelines reported, not law: re-verify each on CURRENT disk (a later ' +
            'sibling pipeline may already have resolved it); implement the STRONGEST resolution — the denser root-level reconstruction where the implied ' +
            'fix is weak or a single-point patch; a residual factually wrong or already resolved on disk is rejected with reason. RESIDUALS: ' +
            JSON.stringify(residuals) +
            ' ' +
            '(5) FINALIZE — the terminal cold read as a first reader with fresh hostile eyes: fix every residual weakness, hedge, meta line, thin card, ' +
            'or under-dense fence; density within the LOC affordance without card/snippet spam; hunt PAST the residual list on your own authority — ' +
            '`beyond` enumerates those fixes, and an empty `beyond` attests your hunt found nothing, never that it did not run. FAILED PAGES (their ' +
            'pipeline died — the page left the run un-hardened; give it the full harden here as part of this sweep): ' +
            JSON.stringify(failed) +
            '. ' +
            'Return files, resolved, beyond, rejected, summary.',
    ].join('\n');

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('Inventory');
const inv = await agent(
    'TASK: DISCOVERY — the read-only reconnaissance grounding every downstream stage; read-only is its ONLY concession. ' +
        'Enumerate from the SOURCE OF TRUTH, never memory: fd/ls the real page set under ' +
        ROOT +
        ' and BOTH .api tiers (libs/typescript/.api/ and ' +
        'every libs/typescript/<folder>/.api/), and parse ' +
        ROOT +
        '/README.md [01]-[ATLAS]. Read every existing page IN FULL and the README at ' +
        'large; resolve scope against real disk state. Return every CONCEPT page as a row {path (repo-relative, e.g. ' +
        ROOT +
        '/shapes.md), order ' +
        '(atlas position, integer)}, EXCLUDING README.md and any page that does not exist on disk. Per page the product is a capability MAP, not a ' +
        'verdict: `map` = composed capability + underutilized capability with CONCRETE members (verified against the .api catalogs/node_modules only — ' +
        'never list a phantom) + contextual seams to sibling pages + stacking guidance — facts only, never a weak/strong assessment. The map is an ' +
        'initial pointer, never a ceiling — downstream stages re-read and exceed it; it never licenses a skim. Use fd/find/read; do not cd; do not edit.',
    { label: 'inventory', phase: 'Inventory', schema: INVENTORY_SCHEMA, model: 'opus', effort: 'high' },
);
const invFiles = ((inv && inv.files) || []).filter((f) => f && f.path && f.path.indexOf('/.reports/') < 0).sort((a, b) => a.order - b.order);
log('Inventory: ' + invFiles.length + ' TS doctrine pages under ' + ROOT + '; CAP=' + CAP);

phase('Gate');
// The gate receives facts only — path, order, capability map — never the inventory's weak/strong verdict (an assessment, not evidence).
const gateRows = invFiles.map((f) => ({ path: f.path, order: f.order, map: f.map }));
const arch = await agent(
    [
        DOCTRINE,
        '',
        'TASK: ATLAS STRUCTURE CHALLENGE GATE (structure only — no content authoring). The atlas roster is ' +
            'SETTLED law; a structural change (merge, split, kill, rename, add) requires DISQUALIFYING evidence — a page provably thin/table-stakes with ' +
            'no densification path, two pages provably owning one layer, a genuinely disjoint uncovered layer — never taste. Read the README atlas + ' +
            'doctrine, every page from disk, and the inventory maps below. Default outcome: the standing roster unchanged. Where evidence disqualifies: ' +
            'apply ONLY the structure — `git mv` each rename; create a skeleton file (H1 `# [<TOKEN>]` + one-line lead + `## [1]-[INDEX]` stub) for each ' +
            'genuinely new page; update the README atlas table to match; author NO content (the Harden pipelines realize content per charter). A merge/kill ' +
            'DROPS no capability: route every law the retired page owns into the absorbing page charter so the pipelines realize the absorption — zero ' +
            'current consumers never lowers the bar, and a kill without a named absorber is forbidden. Edit ONLY ' +
            'under ' +
            ROOT +
            '/. Return the FINAL ordered file set {path, order, charter, isNew}, renames, rationale.\nINVENTORY:\n' +
            JSON.stringify(gateRows),
    ].join('\n'),
    { label: 'gate', phase: 'Gate', schema: GATE_SCHEMA, effort: 'high' },
);
const archFiles = ((arch && arch.files) || []).filter((f) => f && f.path).sort((a, b) => a.order - b.order);
const charters = new Map(archFiles.map((f) => [f.path, f.charter]));
const ordered = archFiles.length ? archFiles.map((f) => f.path) : invFiles.map((f) => f.path);
log(
    'Gate: settled atlas = ' +
        ordered.length +
        ' pages' +
        (arch && arch.renames && arch.renames.length ? ' (' + arch.renames.length + ' structural changes)' : ' (roster unchanged)'),
);
if (!ordered.length) {
    log('No pages resolved — nothing to harden');
    return { workflow: 'stack-ts', root: ROOT, total: 0 };
}

// Per-file pipeline: initial -> critique -> redteam chain WITHIN the file only; the pool is the sole scheduler across files.
phase('Harden');
const results = (
    await pool(ordered, CAP, async (page) => {
        const init = await agent(authorPrompt(page, ordered, charters.get(page)), {
            label: 'initial:' + nameOf(page),
            phase: 'Harden',
            schema: FIXLOG_SCHEMA,
            effort: 'high',
        });
        if (!init) return { page, failed: true, logs: [] }; // failure isolation: a dead initial skips its file's reviews; the run continues
        const crit = await agent(critiquePrompt(page, ordered, charters.get(page)), {
            label: 'critique:' + nameOf(page),
            phase: 'Harden',
            schema: FIXLOG_SCHEMA,
            effort: 'high',
        });
        const rt = await agent(redteamPrompt(page, ordered, charters.get(page)), {
            label: 'redteam:' + nameOf(page),
            phase: 'Harden',
            schema: FIXLOG_SCHEMA,
            effort: 'high',
        });
        return { page, failed: false, logs: [init, crit, rt].filter(Boolean) };
    })
).filter(Boolean);
const FAILED = results.filter((r) => r.failed).map((r) => r.page);
const norm = (x, page) => ({ files: x.files && x.files.length ? x.files : [page], claim: x.claim });
const RESIDUALS = [
    ...new Map(
        results
            .flatMap((r) => r.logs.flatMap((l) => (l.residual_high || []).map((x) => norm(x, r.page))))
            .map((r) => [r.files.slice().sort().join(',') + '|' + r.claim, r]),
    ).values(),
];
log(
    'Harden: ' +
        (results.length - FAILED.length) +
        '/' +
        ordered.length +
        ' file pipelines complete; ' +
        RESIDUALS.length +
        ' cross-file residual(s)' +
        (FAILED.length ? ' — FAILED (routed to the corpus sweep): ' + FAILED.join(', ') : ''),
);

phase('Corpus');
const corpus = await agent(corpusPrompt(ordered, RESIDUALS, FAILED), {
    label: 'corpus',
    phase: 'Corpus',
    model: 'fable',
    effort: 'high',
    schema: CORPUS_SCHEMA,
});

// DOCTRINE LANDER: the run's durable-learning terminal — pooled harvest from every per-file stage + the corpus sweep,
// RESTRICTED to reviewer/laws/constitution (this run owns docs/stacks/typescript); refutation-first, land-nothing legal.
phase('Doctrine');
const HARVEST_ROWS = results.flatMap((r) => (r.logs || []).flatMap((l) => (l && l.harvest) || [])).concat((corpus && corpus.harvest) || []);
const doctrine = HARVEST_ROWS.length
    ? await agent(
          'TASK: DOCTRINE LANDER — the durable-learning terminal of this run. Read `docs/laws/README.md` ' +
              'FIRST — it owns the corpus admission and page-shape law; obey it over any restatement. Load ' +
              'the `docgen` skill via the Skill tool BEFORE any durable edit; load ' +
              '`mermaid-diagramming` before touching any diagram. This run AUTHORED the docs/stacks/typescript corpus — ' +
              'adjudicate ONLY reviewer/laws/constitution nominations and NEVER edit a docs/stacks/typescript page; a ' +
              'stacks-altitude nomination is already owned by the run and is rejected. ' +
              "NOMINATIONS (unverified, biased toward their authors' own work — refute by default): " +
              JSON.stringify(HARVEST_ROWS) +
              '\nADJUDICATE each row per the admission bar: cold-read its target surface IN FULL, verify its anchors on ' +
              'CURRENT disk; LAND NOTHING is a first-class verdict.\n' +
              'TOPOLOGY RE-PROOF: re-verify every `docs/laws/topology.md` row whose [SURFACE] this run touched — cull a row ' +
              'whose coupling no longer holds, land a coupling this run proved.\n' +
              'GATE: run `uv run .claude/skills/docgen/scripts/prose_gate.py <every touched .md>` and repair to zero FAILs ' +
              'before returning. Return landed/refined/rejected (each rejection with its reason)/files/summary.',
          { label: 'doctrine', phase: 'Doctrine', model: 'fable', effort: 'high', schema: DOCTRINE_SCHEMA },
      )
    : null;

return {
    workflow: 'stack-ts',
    root: ROOT,
    settled: arch,
    ordered: ordered,
    total: ordered.length,
    failed: FAILED,
    residuals: RESIDUALS.length,
    corpus: corpus && {
        files: (corpus.files || []).length,
        resolved: (corpus.resolved || []).length,
        beyond: (corpus.beyond || []).length,
        rejected: (corpus.rejected || []).length,
        summary: corpus.summary,
    },
    doctrine: doctrine && {
        nominated: HARVEST_ROWS.length,
        landed: (doctrine.landed || []).length,
        refined: (doctrine.refined || []).length,
        rejected: (doctrine.rejected || []).length,
        files: doctrine.files || [],
        summary: doctrine.summary,
    },
};
