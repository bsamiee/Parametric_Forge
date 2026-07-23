export const meta = {
    name: 'stack-cs',
    whenToUse: 'Harden the docs/stacks/csharp code doctrine in place to the dense per-file bar.',
    description:
        "Focused full HARDENING of the docs/stacks/csharp code doctrine — every core page AND every domain/ shard, improved in place to the same 13/10, ultra-dense, page-craft-conformant bar the python doctrine holds. The csharp set is the historical FLOOR/reference; this pass pulls it UP to that rigor: page-craft grammar (narrow index table -> deep family cards -> one agnostic snippet per region, zero duplicated demonstrations), the soft LOC density signal, extreme ADT collapse ([Union]/[SmartEnum<TKey>]/[ValueObject<T>]/[ComplexValueObject] + source-generated case families), two-weave AOP (definition-time source-gen aspects + composition-time effect transformers), LanguageExt Fin/Validation/Option/Eff rails, full parameterization/polymorphism, C# 14 on net10 to the metal. Carries the bounded interface/graph/mapping LAW extension (cross-stratum seam, graph-as-closed-family, generated mapping/equality aspects, QuikGraph/Riok.Mapperly/Generator.Equals as admitted core substrate) hardened into existing owners and a default-off gated new-core-page valve; restructure-free at heart — a hostile per-file harden. Inventory rules the ordered file set and the Gate rules the page roster BEFORE per-file work — true data dependence, kept. Then each FILE runs its own initial -> critique -> redteam pipeline, ALL files concurrent under one pool cap — the chain is the file's own stage dependence, never a corpus barrier. Critique and redteam read the LIVE corpus — the current on-disk state of every page, landed sibling hardening composed as found, a conflict resolved to the stronger form, never a revert — and edit ONLY their own file (the anti-collision rule among concurrent pipelines), reporting cross-file residuals. ONE terminal corpus agent then aligns cross-file seams, closes gaps, enforces the computation-law bodies, resolves every reported residual, and finalizes cold in one sweep. Every per-file stage and the corpus sweep carry a required-but-usually-empty harvest attestation RESTRICTED to reviewer/laws/constitution altitudes (the run authors docs/stacks/csharp, so a stacks lesson is already owned and never nominated); when the pooled nominations are non-empty, ONE terminal doctrine lander adjudicates them against docs/laws (refutation-first, land-nothing legal, never re-editing a docs/stacks/csharp page). Snippets agnostic (neutral names, no project anchor); every host/NuGet member verified via assay api with the .api-catalog/nuget-MCP/Context7/exa fallback; every edit scoped to docs/stacks/csharp (NEVER edit a python/typescript file). Takes no args.",
    phases: [
        {
            title: 'Inventory',
            detail: 'mechanical enumeration: the ordered core + domain file set from the README atlas + the domain/ router, resolved against real disk',
        },
        {
            title: 'Gate',
            detail: 'justification gate (default harden-in-place): only on an explicit cited justification + target atlas position author ONE new core page, edit the README atlas/STATE, seed the region ledger, and splice it into the ordered set',
        },
        {
            title: 'Harden',
            detail: 'per FILE: initial -> critique -> redteam chained within the file; all files concurrent under one pool cap; critique/redteam read the live corpus and edit only their own file',
        },
        {
            title: 'Corpus',
            detail: 'ONE terminal agent: align seams, close gaps, computation-law bodies, resolve every reported residual, finalize cold',
        },
        {
            title: 'Doctrine',
            detail: 'terminal doctrine lander, fires only on non-empty pooled harvest RESTRICTED to reviewer/laws/constitution (the run owns docs/stacks/csharp); refutation-first, land-nothing legal',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const CAP = 14;
const ROOT = 'docs/stacks/csharp';

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
                required: ['path', 'order'],
                properties: { path: { type: 'string' }, order: { type: 'integer' } },
            },
        },
    },
};
// Altitude is RESTRICTED to surfaces this run does NOT author: the run owns docs/stacks/csharp, so a stacks nomination is already landed.
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
const GATE_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['verdict', 'reason', 'page'],
    properties: {
        verdict: { type: 'string', enum: ['harden_in_place', 'new_page'] },
        reason: { type: 'string' },
        page: {
            type: 'object',
            additionalProperties: false,
            required: ['path', 'atlas_index', 'decision', 'justification', 'folder', 'seed_regions'],
            properties: {
                path: { type: 'string' },
                atlas_index: { type: 'integer' },
                decision: { type: 'string' },
                folder: { type: 'string' },
                justification: { type: 'string' },
                seed_regions: { type: 'array', items: { type: 'string' } },
            },
        },
    },
};
const SEED_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['path', 'verdict', 'atlas_index', 'regions'],
    properties: {
        path: { type: 'string' },
        atlas_index: { type: 'integer' },
        regions: { type: 'array', items: { type: 'string' } },
        verdict: { type: 'string', enum: ['seeded', 'aborted'] },
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
    'TARGET: docs/stacks/csharp/ is the route-owned C# CODE DOCTRINE — a doc set of AGNOSTIC teaching pages (core + a domain/ shard set) that ' +
        'legislate how all project C# is written. A page teaches a coding LAW with one exemplary agnostic snippet, never a concrete module. The README ' +
        'owns routing + the 17 named laws + the COLLAPSE_SCAN + page-craft; the domain/ README is a one-table router whose shards compose the core ' +
        'laws and never re-open them; each concept page owns ONE disjoint layer and states doctrine as fact. READ docs/stacks/csharp/README.md (its ' +
        '[DOCTRINE]/[COLLAPSE_SCAN]/[PAGE_CRAFT]/[CORPUS_LAW] sections) and the domain/README.md router and hold them as law.',
    'LAWS — read `docs/laws/` before any durable edit (README + topology + patterns + scars; short registry pages): a topology row whose ' +
        '[SURFACE] your edits touch binds its obligated counterparts into the SAME pass, and every patterns row binds each branch it names ' +
        '(the python/csharp parity coupling is a patterns concern).',
    'PARITY BAR: the PYTHON doctrine docs/stacks/python/ is the peer-rigor reference — this csharp set is pulled UP to match its page-craft, ~450 ' +
        'soft LOC density signal, extreme ADT/AOP/parameterization, and zero-duplicated-demonstration corpus law. READ docs/stacks/python/ read-only ' +
        'as the rigor benchmark; carry the SHARED density laws into C# idiom, never a Python spelling. The csharp doctrine is its own language: C# 14 ' +
        'on net10, Thinktecture generated owners + LanguageExt rails.',
    'WRITE-FULLY MANDATE, scoped to docs/stacks/csharp/** ONLY: every defect you identify you FIX NOW via Edit/Write directly in the file; the ' +
        'structured fix-log you return is a REPORT of edits ALREADY MADE, never a to-do list or a would/should hedge. Edit ONLY files under ' +
        'docs/stacks/csharp/ (NEVER a python/typescript/standards file; reading them is allowed). Leave nothing behind except a genuine cross-FILE ' +
        'defect a concurrent sibling pipeline owns — report it in residual_high; the terminal corpus agent resolves every reported residual in this ' +
        'same run.',
].join('\n');

const ADVERSARIAL = [
    'ADVERSARIAL STANCE — EVERY stage (author, critique, AND red-team) is HOSTILE: assume the page is NAIVE, SHALLOW, JUNIOR, or ILLUSORY until it ' +
        'survives an aggressive attack; the burden of proof is ON THE PAGE. `finalized`, "mature", "already strong", "good enough", and a prior ' +
        '`clean` grade are REJECTED self-assessments. Default to "this page must be hardened to the strongest form the doctrine admits" and MAKE that ' +
        'harden; a no-edit verdict is earned ONLY after a genuinely aggressive attack finds nothing.',
    'ILLUSORY / FAKE content is the PRIMARY target — a snippet that READS dense (uses `[Union]`/`[SmartEnum]`/the rails, cites packages) yet ' +
        'demonstrates a THIN slice; prose that ASSERTS richness the fence lacks; a card field that decides nothing; a structurally-correct collapse ' +
        'that is semantically empty; a host/NuGet member cited but unverifiable (a PHANTOM — delete it). Treat dense, confident-looking fences with ' +
        'MORE suspicion, and DISBELIEVE every claim the page makes about itself until verified.',
    'NAIVETY is a defect on TWO orthogonal axes, both intolerable: COVERAGE — the owner models a THIN SLICE of its concept (the obvious three ' +
        'fields where the domain carries fifteen; a two-case family for a twenty-case space); APPROACH — enumerated hardcoded instances where a ' +
        'parameterized, algorithmic owner should GENERATE the space (a fixed roster of styles, patterns, or variants is seed DATA feeding ONE ' +
        'generator over named parameters, never the mechanism itself). Attack both axes in every fence and repair on sight.',
].join('\n');

const CSDOCTRINE = [
    'HOLD the README [DOCTRINE] 17 laws as fact, never restated on a concept page: [FLOW] EXPRESSION_SPINE (domain logic expression-shaped; ' +
        'dependent steps `Bind`, independent ones accumulate applicatively; the carrier selects the algebra; statements only in measured ' +
        'ref-struct/span kernels that name the exemption) + BOUNDARY_ADMISSION (raw admitted EXACTLY ONCE into an evidence-carrying owner; interior ' +
        'never re-validates or sees null/sentinel/provider shape). [SHAPE] SHAPE_BUDGET + DEEP_SURFACES + MODAL_ARITY + ANTICIPATORY_COLLAPSE + ' +
        'INTERFACE_SEAM. ' +
        '[DERIVATION] POLICY_VALUES + DERIVED_LOGIC + DERIVED_TYPES + SYMBOLIC_REFERENCE + SEMANTIC_NAMING. [MATERIAL] LIBRARY_DEPTH + ' +
        'DEFINITION_TIME_ASPECTS. [INTEGRATION] ROOT_REBUILD + ONE_HOP_RESOLUTION + COMPOSED_IMPLEMENTATION. Run the COLLAPSE_SCAN on every fence: any ' +
        'signal triggers the move — shapes sharing an identity regime, an admission path, a payload timing, or a consumer collapse into ONE owner, and ' +
        'a shape survives only on a genuinely distinct discriminant; the scan list is a FLOOR, never the complete set — any repeated structure, parallel spelling, ' +
        'or enumerable family an algebra, table, fold, or generator can own is a collapse target you find yourself.',
    'A page that demonstrates a coding law must itself obey every law it can reach; a domain shard COMPOSES the finalized core laws as settled ' +
        'material and never re-opens admission/shape/rail/dispatch/boundary decisions.',
].join('\n');

const CS_SHAPE = [
    'EXTREME SHAPE/TYPE DENSITY: one concept owns exactly ONE type as a dense closed family chosen by OWNER_CHOOSER — `[ValueObject<TKey>]` ' +
        '(invariant-bearing scalar), `[ComplexValueObject]` (N-field product), `[SmartEnum<TKey>]` (wire-keyed vocabulary) / `[SmartEnum]` keyless ' +
        '(process-local behavior), `[Union]` (closed alternatives with per-occurrence payload) / `[Union<T1,...>]` ad-hoc, `record`/`readonly record ' +
        'struct` (interior product), a frozen set/table, or a language `enum` at the seam only. KILL parallel DTOs, one-field wrappers, field-rename ' +
        'shapes, nullable-as-failure, struct-`default` ghosts, and sibling types/factories/switch-arms for one concept sharing an identity regime, ' +
        'admission path, payload timing, or consumer (collapse to ONE generated owner or a `Fold` algebra / frozen data table — a shape survives only ' +
        'on a genuinely distinct discriminant); this kill list is a floor, never the full set — hunt collapse targets beyond it.',
    'ANTICIPATORY_COLLAPSE: shape the owner for the family it WILL absorb so the next case/dimension/modality lands as ONE generated case/row/policy ' +
        'value with every consumer untouched or broken LOUDLY at compile time (total generated `Switch`, NO runtime-silent `_` arm). The exemplary ' +
        'snippet shows one owner ready to replace 10+ loose things with the growth axis visible.',
].join('\n');

const CS_INTERFACE = [
    'INTERFACE DOCTRINE (lib contracts are load-bearing seams, never loose markers): an interface is EITHER the COMPOSE/inject face — a member-bearing ' +
        'strategy/store/codec/provider contract or a BCL `IAsyncEnumerable<T>`/`IDisposable`/`IAsyncDisposable` stream/lifetime contract — paired with an ' +
        'abstract-base IMPLEMENT seam that owns the shared state + template virtuals, OR a static-abstract self-constrained contract a generic dispatches ' +
        'on (`where TSelf : IObjectFactory<TSelf,TKey,TError>`, generic-math `where T : INumber<T>`/`IFloatingPointIeee754<T>`). OWNER-VEHICLE chooser, ' +
        'decided ONCE: WE close the value-shape family + in-build consumer -> `[Union]`/`[SmartEnum]`/`[ValueObject]` + total generated `Switch`; ' +
        'concretes share state/template or a foreign base/native-handle/self-typed `new()` recursion -> abstract class at the seam; foreign/downstream ' +
        'code must implement a strategy OR a generated/catalogued family publishes across an assembly/wire boundary -> an interface FLOOR + minting ' +
        'factory + ONE polymorphic operation over the floor (consumers hold the floor; the concrete is `internal` + swappable).',
    'CROSS-STRATUM SEAM ALIGNMENT: when N sibling owners on the SAME stratum must align WITHOUT referencing one another, the floor is hosted by ONE ' +
        'type on the LOWEST shared stratum (the seam owner every sibling already depends upon), exposing a single INSTANCE-interface FLOOR (an ' +
        '`IProjection<TIn,TOut>`-shaped strategy each sibling family IMPLEMENTS, never a marker) and the minting/dispatch operation over the floor. ' +
        'Siblings align by CONTRACT — each implements the floor against its own shapes — so the seam type is the ONLY shared symbol and peers stay ' +
        'swappable with zero peer references. This is the INTERFACE_SEAM publishes-across-a-boundary vehicle turned HORIZONTAL: the floor lives below, ' +
        'the conformances live in each sibling, alignment is structural, never coupling.',
    'FOREIGN CONSTRAINT INTERFACE vs INTERNAL SWITCH (distinct seams on ONE owner): a constraint/validation contract FOREIGN or downstream code ' +
        'supplies — an `IConstraint`-shaped interface with one `Check`/`Validate` member returning `Validation<Error,T>` so independent violations ' +
        'ACCUMULATE applicatively — is a legitimate instance-interface floor, NOT the owner`s internal total generated `Switch`, which the owner CLOSES ' +
        'and never publishes. Discriminant: an OPEN extension point others plug into (constraints, projections, strategies) is an interface floor ' +
        'returning a rail; a CLOSED family the owner exhaustively dispatches is a `[Union]`/`[SmartEnum]` + `Switch`. They CO-EXIST (closed shape ' +
        'switched internally, open constraint set folded over `Validation` at the boundary); conflating them — an interface over the closed family, or a ' +
        '`Switch` over the open extension set — is the rejected form.',
    'REJECT: a member-less marker read by `is`/reflection (admissible ONLY as a generic bound `where T : IMarker`; a capability switch is an attribute ' +
        'or a generated-owner conformance); an interface over a family WE close (forfeits `Switch` totality); a `[Union]` foreign code must extend; an ' +
        'INSTANCE default-interface-method (defaults derive via `static virtual` from a minimal core — zero admitted package ships an instance DIM); a ' +
        'generic-math constraint over a carrier stopping at `IComparable`/`IEquatable`/`IFormattable` (decorative — widen to the concrete carrier); a ' +
        'heap delegate on a measured hot path where a `ref struct` visitor (`allows ref struct`, caller-owned stack) fits; an invariant generic where ' +
        '`out`/`in` removes a cast; parallel `IFooForBar` names where the type parameter or keyed service carries the modality. This law lands in README ' +
        '[SHAPE] INTERFACE_SEAM, shapes.md OWNER_CHOOSER, surfaces-and-dispatch.md (static-abstract + visitor dispatch forms), boundaries.md ' +
        '(hold-the-floor + lifetime + the cross-stratum seam floor), and rails-and-effects.md (the accumulating-`Validation` constraint fold).',
].join('\n');

const CS_AOP = [
    'TWO-WEAVE AOP: definition-time concerns (admission, identity, dispatch, serialization, grammar, logging) attach via attribute-directed SOURCE ' +
        'GENERATION in the fixed generator-owned order; composition-time concerns attach as effect transformers in author order — retry as ' +
        '`Schedule`-driven `IO<T>.Retry`/`Prelude.retry`, recovery as named catch combinators (`@catch`/`catchOf`/`CatchM` composed via `|`), resource ' +
        'lifetime as `Bracket`/`BracketIO`/`Finally`; the two weaves meet at EXACTLY ONE seam, the admission rail bridge. Co-occurring wrappers ' +
        'sharing an admission path collapse into ONE aspect; an aspect NEVER raises into domain flow; inline-repeated concerns and sibling helper methods are defects.',
    'MAPPING + EQUALITY are DEFINITION-TIME generated aspects, never hand-written: an owner<->DTO/proto/wire projection is emitted by Riok.Mapperly ' +
        '(a `[Mapper]` partial-producing source-generator; members verified via assay api, else the api-mapperly catalog), and structural equality + ' +
        'the content-key ride EITHER the ' +
        'Thinktecture generated owner`s value semantics (`[ValueObject]`/`[ComplexValueObject]`) OR Generator.Equals (`[Equatable]`) for shapes ' +
        'Thinktecture does not own — a class-root `[Union]` node/edge type that otherwise SURRENDERS generated equality is the canonical case. A ' +
        'hand-rolled `Equals`/`GetHashCode`, a field-by-field hand mapper, or a runtime-reflection projector is the rejected form. These join ' +
        'admission/identity/dispatch/serialization in the fixed generator-owned order; the content-key aspect is the SAME canonical byte-codec the ' +
        'graph law addresses content by, never a second hashing path.',
].join('\n');

const CS_RAILS = [
    'RAILS (RAIL_CHOOSER, narrowest carrier chosen ONCE at admission): `Option<T>` absence, `Fin<T>` synchronous fallibility, `Validation<Error,T>` ' +
        'independent accumulated faults, `Eff<RT,T>` runtime capability, `IO<T>` deferred boundary work, `Schedule` retry, ' +
        '`Seq<T>`/`Arr<T>`/`HashMap<K,V>` immutable traversal. The fault type is a CLOSED `[Union]` family deriving from `Expected` (a bare exception ' +
        'or a generic untyped `Error` for a multi-cause domain is a defect; recovery identity via `Is`/`HasCode`/`IsType<E>`, never `==`); ' +
        'accumulate-vs-abort correct (`Apply`/`&`/`.Traverse` for independents, `Bind`/`.TraverseM`/query expressions for dependents); total generated ' +
        '`Switch` with compile-time exhaustiveness; `.Fold`/`.Traverse`/`.Choose` with the mandatory `.As()` re-anchor; NO exception control flow in ' +
        'domain logic, NO mutable accumulation.',
].join('\n');

const CS_CORE_LOGIC = [
    'WORLD-CLASS ALGORITHMIC BODIES: every body that does real work is expression-shaped at full operator depth — a naive `for`/`foreach` with ' +
        'mutable accumulation, a hand-rolled index counter, or an intermediate materialized list where a deferred pipeline or fold expresses it is a ' +
        'DEFECT. Compose deferred LINQ at depth (`Aggregate`/`SelectMany`/`Zip`/`Chunk`/`GroupBy`/`Scan`) or a LanguageExt ' +
        '`.Fold`/`.FoldBack`/`.Traverse`/`.Choose` over the carrier; a measured hot path is a `ref struct`/`Span<T>` kernel named at the ' +
        'EXPRESSION_SPINE exemption (vectorized via `TensorPrimitives`/`Vector<T>` where the shape admits); collection expressions + spread, ' +
        'list/slice/relational/logical patterns, and switch-expression dispatch over a closed family replace imperative branching. NO mutable ' +
        'accumulation in domain flow, NO intermediate sequence a fold would fuse, NO LINQ over a measured hot loop where a span kernel is the faster owner.',
].join('\n');

const CS_GRAPH = [
    'GRAPH-AS-CLOSED-FAMILY (the domain-graph law, DISTRIBUTED across shapes.md / algorithms.md / boundaries.md, never a standalone page, never ' +
        're-taught): a domain graph is a PROPERTY GRAPH whose every edge kind is ONE neutral edge-algebra `[Union]` over a small closed verb set ' +
        '(compose / assign / associate / connect / void-shaped, each carrying a typed payload) AND ONE `Generic(wireName, relating, related, attrs)` ' +
        'passthrough case for the open tail, so no foreign relation is dropped and the foreign relationship TAXONOMY never leaks into the neutral ' +
        'owner; the node is ONE `[Union]` over the entity family keyed in a map, and the consumer-facing aggregate is a DERIVED FOLD over the reachable ' +
        'subgraph, NEVER a second stored record. N typed per-relation classes mirroring a foreign schema is the rejected form (a `[03]-[COLLAPSE_SCAN]` ' +
        'trigger: cases mirror a foreign taxonomy -> neutral algebra + `Generic` passthrough). shapes.md OWNS the node/edge union via OWNER_CHOOSER.',
    'PHASE SPLIT + INCIDENCE (algorithms.md / system-apis.md COLLECTIONS_AND_IDENTITY): the graph has TWO phases behind one surface — a persistent ' +
        '`HashMap`/`ImmutableDictionary` WORKING graph for O(log n) structural-sharing mutation, baked ONCE via `ToFrozenDictionary()` into a `Frozen*` ' +
        'READ SNAPSHOT carrying a memoized INCIDENCE INDEX (node -> incident edges) so traversal is O(degree) not O(E); QuikGraph owns the graph view + ' +
        'traversal/topology algorithms over the snapshot. The bake is the one-way working->snapshot transition; mutating a snapshot or rebuilding the ' +
        'index per query is the rejected form, and the two collection cards JOIN as two PHASES of one structure rather than spawning a parallel card. ' +
        'CONTENT ADDRESSING is ALREADY OWNED: graph identity + structural diff COMPOSE boundaries.md BYTE_IDENTITY (one canonical byte-codec per ' +
        'identity domain, the memo key in MEMO_KEY) and system-apis.md INTEGRITY/IDENTITY_POLICY — reuse that ONE codec VERBATIM for both key-mint and ' +
        'diff; a second hashing/serialization path or a fresh content-addressing card is the rejected form. The rooted graph id is a NEUTRAL kernel ' +
        'value; any foreign/wire id is a boundary attribute, never the kernel key.',
].join('\n');

const PARAM_POLY = [
    'HEAVY PARAMETERIZATION, ZERO HARDCODING/FRAGILE LOGIC, FULL POLYMORPHISM. ONE entrypoint owns every modality, discriminating on input SHAPE ' +
        '(`params ReadOnlySpan<T>`, request union, case), never a name suffix or a `bool`/`mode`/`batch` knob (KNOB_TEST: delete each parameter; if ' +
        'the value reconstructs what it carried, it was a knob — collapse a flag into a policy value or input-shape discriminant; move ' +
        '`timeout`/`retry`/`deadline`/`CancellationToken` off the signature onto the carrier or a composition-time aspect). Configuration enters as ' +
        'ONE behavior-carrying value (smart-enum row, union case, frozen table — POLICY_VALUES), never flag sets the body re-derives; cases sharing ' +
        'structure are DERIVED (one primary correspondence, secondaries derived) — never enumerated arms. Capability exits through FEW dense unified ' +
        'entry points — one polymorphic entry per rail discriminating on input shape (single|batch|stream absorbed by input detection, forward and ' +
        'inverse directions on one surface), variation living in input shape, policy values, and table rows, never parallel exports or modality-named ' +
        'siblings; the surface narrows by absorption, never by omission.',
].join('\n');

const CS14 = [
    'LATEST STABLE C# 14 on net10 to the metal (`Nullable enable`, NRT enforced): primary constructors, collection expressions with spread, `params` ' +
        'collections (incl. `params ReadOnlySpan<T>`), list/slice/relational/logical patterns, switch expressions, `required` members, `file`-scoped ' +
        'types, `field` accessors, extension blocks (`extension(Receiver)`) and extension operators, generic math / static abstract+virtual interface ' +
        'members, `with` expressions, `System.Threading.Lock`, raw string + `u8` literals where they fit. Apply the docs/stacks/csharp ' +
        'file-organization + section-order law: `[Union]`/`[SmartEnum]`/`[ValueObject]` + generated case families stay inside the declaring owner ' +
        'block; canonical order TYPES -> CONSTANTS -> MODELS -> ERRORS -> SERVICES -> OPERATIONS -> COMPOSITION -> EXPORTS; one generated case / ' +
        'static entry per physical line; preserve generated-case + smart-enum semantic order.',
].join('\n');

const CS_SUBSTRATE = [
    'STACK CAPABILITY, ULTRA-STACKED: enumerate BOTH `.api` tiers with a REAL ls/fd listing from disk, never memory — the central `libs/csharp/.api/` ' +
        'substrate catalogs (api-thinktecture-runtime-extensions, api-quikgraph, api-mapperly, api-generator-equals, api-mathnet-numerics, api-csparse, ' +
        'every sibling catalog the page concern touches) and, for a domain shard, the per-folder `libs/csharp/<Package>/.api/` host/NuGet catalogs ' +
        'its concern composes — and MINE them to OPERATOR DEPTH (read-only material; edits stay scoped to docs/stacks/csharp). The universals are ' +
        'Thinktecture.Runtime.Extensions (generated domain shape) + LanguageExt.Core ' +
        '(rails, effects, schedules, immutable collections; catalog-less — assay api is its evidence, and when assay is blocked or unavailable the ' +
        'nuget MCP `get_package_context` + Context7/exa/tavily over the official LanguageExt surface own the fallback), with QuikGraph (graph traversal/topology + ' +
        'graph algorithms), Riok.Mapperly (generated ' +
        'owner<->DTO/proto/wire mapping), and Generator.Equals (generated structural equality + content-key for shapes Thinktecture does not own, e.g. ' +
        'class-root `[Union]` node/edge types) as ADMITTED CORE substrate integrated ground-up the SAME way and NAMED in the README [02] LIBRARY_DEPTH ' +
        'law beside MathNet/CSparse (hand-rolled graph traversal, field-by-field mapping, or `Equals`/`GetHashCode` is the rejected form), layered ' +
        'onto the BCL; MathNet/CSparse own numeric algorithms where relevant. Compose EVERY relevant member into single dense owners woven as ONE rail ' +
        '(source-generated owners, `Fold` algebra, data tables), ALWAYS layering ' +
        'Thinktecture/LanguageExt/QuikGraph/Riok.Mapperly/Generator.Equals onto the domain surface, NOT flat one-shot ' +
        'per-API uses. Use the DEEPEST operator/combinator/generated surface each library reaches (LIBRARY_DEPTH); an admitted capability the concept ' +
        'admits but NO owner exploits is a DEFECT this pass closes; reject surface-level subsets, BCL-first reflexes, and thin rename wrappers. Cite ' +
        'ONLY host/NuGet members confirmed via `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api` (verified-local beats any catalog line on ' +
        'conflict; assay blocked or ' +
        'unavailable: the `.api` catalogs, the nuget MCP for feed truth, and Context7/exa/tavily for the official surface own the fallback) — a member ' +
        'you cannot verify through ANY of these rails is a phantom to delete.',
].join('\n');

const PAGECRAFT = [
    'PAGE-CRAFT LAW (README [PAGE_CRAFT]): page grammar is a NARROW index table, then deep FAMILY CARDS, then ONE agnostic snippet beside the rule ' +
        'it proves; the page ends at its last card. CARD ECONOMY: cards are few, deep, evidence-dense; near-peer cards MERGE until each owns a ' +
        'decision cluster; a card line carries exactly ONE decision; a `Use`/`Accept`/`Reject`/`Law`/`Boundary` field appears only where it decides ' +
        'something. REJECT columns are LOAD-BEARING: every `Use` names the spelling/wrapper/local pattern it DELETES. CODE NAMES BEFORE PROSE: every ' +
        'member named is verified against the package before written; a nameable surface spelled as prose is a defect. ZERO META: no provenance, ' +
        'source trace, release narration, process state, or tool context — any such block POISONS every downstream generation. The README is the only ' +
        'file that carries a Markdown link; the domain/ README is a one-table router.',
].join('\n');

const AGNOSTIC_SNIPPETS = [
    'AGNOSTIC SNIPPET LAW (style-guide [PLACEHOLDER_LAW]): every snippet compiles under C# 14 with legal NEUTRAL identifiers — ' +
        '`Shape`/`RefinedShape`/`Variant`/`PRIMARY`/`Field`/`KEY`/`Row`/`ROW_A`/`TABLE`/`SELECTED` — and placeholder strings (`"<value-a>"`) appear ' +
        'ONLY inside literals. NO project, host, repo, customer, pricing, or business-domain noun anchors a snippet; a domain noun is context poison.',
    'CORPUS-WIDE ZERO duplicated snippet demonstrations: each snippet exercises a surface region NO OTHER snippet in the corpus (core + domain/) ' +
        'shows — the region is its spotlight; finalized surfaces composed as supporting material occupy no region and duplicate nothing. A duplicated ' +
        'region is repaired by ROUTING to its owner, never by re-teaching. Snippets are doctrine-exemplary at full operator depth, ~3-4x denser than ' +
        'ordinary code, at the scale a large system takes (admission + dispatch + rail + policy in one fence with the growth axis visible).',
].join('\n');

const OPINIONATED = [
    'HEAVILY-OPINIONATED PROJECT DOCTRINE, NOT a language survey. ZERO table-stakes is tolerated, ever: a card or snippet teaching something a ' +
        'competent C# developer already knows — rather than an opinionated, dense, project-specific CHOICE — is a DEFECT to delete or densify. No ' +
        'net-casting to "cover the language"; cover only the opinionated decisions the projects need, each at 13/10.',
    'LOC budget ~450 is a SOFT pressure signal toward DENSIFICATION, NOT a hard gate. The real metric is per-card and per-snippet density: every ' +
        'card and every snippet world-class, zero filler. NEVER strip snippet whitespace, remove design content, or fragment a coherent concept to hit ' +
        'a number; a coherent dense concept (e.g. the algorithms monolith) may exceed 450 when every card and snippet earns its place. A split is ' +
        'justified ONLY by concept disjointness, never by line count. HARDENING: capability is IMPROVED or EXTENDED, never dropped — zero current ' +
        'consumers never lowers the capability bar; deletion is lawful only for table-stakes, duplicated-region, phantom, or decorative content, ' +
        'never for a density number.',
    'ANTI-PROLIFERATION (default = harden what exists): this pass DENSIFIES and CORRECTS existing cards/snippets in place; it does NOT grow the card ' +
        'count to look thorough. A NEW card is added ONLY to close a genuinely-OMITTED opinionated capability NO existing card owns, and every addition ' +
        'cites its ONE source (a verified package member, a doctrine law, or a consumer contract). A card that restates a neighbor, splits one decision ' +
        'across two cards, or projects a speculative future case with no cite is FILLER to delete, not author. A new core PAGE is a RARE gated ' +
        'exception, never a default move: a law delta lands as in-place hardening of its owning page unless the justification gate returned an explicit ' +
        'new-page verdict with a target atlas position. Rising card/snippet/page COUNT is a defect signal absent a cited omitted capability — the bar is ' +
        'density per card, not cards per page.',
    'ALREADY-OWNED, DO NOT RE-AUTHOR (the top spam traps): CONTENT-ADDRESSING / byte-identity is TRIPLE-OWNED by boundaries.md BYTE_IDENTITY + ' +
        'system-apis.md INTEGRITY + system-apis.md IDENTITY_POLICY (and the durability/data-interchange domain shards for persisted artifacts) — the ' +
        'graph/content-key law COMPOSES these owners and ROUTES to them, NEVER re-teaches a canonical-byte/hash/quantization card. The INTERFACE-SEAM ' +
        'form is fully owned by README INTERFACE_SEAM + shapes.md OWNER_CHOOSER + surfaces-and-dispatch.md type-level dispatch + boundaries.md the ' +
        'floor; the cross-stratum delta is at most ONE appended consequence clause, not a restated seam card. The accumulating-`Validation` constraint ' +
        'rail is owned by rails-and-effects.md VALIDATION_MONOID + domain/validation.md. The mutate->freeze collection owners exist in system-apis.md ' +
        'COLLECTIONS_AND_IDENTITY and the memo key in boundaries.md MEMO_KEY — the phase-split harden JOINS the existing cards. Re-authoring any of ' +
        'these as fresh cards is the defect this pass most often commits — route to the owner instead.',
].join('\n');

const STYLE_PROSE = [
    'PROSE QUALITY — apply docs/standards/style-guide.md: lead each section with the controlling rule/contract; one idea per paragraph; close on the ' +
        'consequence or boundary. Cut hedges (`may`/`might`/`probably`/`generally`/`where possible`/`if needed`), provenance, process narration, and ' +
        'report framing. Prefer a table, a typed signature block, or a tight bullet wherever it carries the design better than a paragraph. Prose that ' +
        'ASSERTS capability the fence lacks is a defect, not content. BACKTICK every symbol, type, field, member, operator, package ID, path, command, ' +
        'and literal value; name the exact member instead of paraphrasing behavior.',
].join('\n');

const COMMENTS =
    'COMMENT HYGIENE: code fences are agent-facing. KEEP the canonical section-divider headers (`// --- [UPPERCASE_LABEL]` ' +
    'dash-fill). Beyond dividers, comment ONLY where intent is not already obvious from names, types, and signatures: default ZERO comments; at most ' +
    '1 line where a comment genuinely earns its place; 1-2 lines only for a truly subtle invariant or boundary. No narration, no restating the code, ' +
    'no XML-doc bloat, no task/process/review comments.';

const CURRENT_STATE =
    'CURRENT STATE — sibling pages are being hardened concurrently by their own file pipelines, each at its own stage. Before ' +
    'any edit, re-read the CURRENT on-disk state of the README and every corpus page your page cross-references; landed sibling hardening is ' +
    'composed AS FOUND, never assumed settled. A conflict between your page and a landed sibling resolves to the STRONGER form, never a revert. ' +
    'You EDIT ONLY your own file while pipelines run — the anti-collision rule; a genuinely cross-file defect is a residual_high the terminal ' +
    'corpus agent resolves in this same run, never a sibling edit.';

const HARVEST_LAW =
    'HARVEST (required key, usually empty): this run AUTHORS the docs/stacks/csharp corpus, so a stacks-altitude lesson is already owned by ' +
    'the run and is NEVER nominated. Nominate ONLY a lesson that lands at an altitude this run does NOT own — reviewer (a diff-checkable ' +
    'review rule that would have caught a defect BEFORE review), constitution (a most-sessions CLAUDE.md/AGENTS.md behavioral fact), or laws ' +
    '(a cross-surface coupling or cross-branch pattern discovered the hard way). Each row: altitude (reviewer|constitution|laws), lang, claim ' +
    '(the generalized law, one sentence, SYMBOL-FREE — every concrete spelling lives in anchors, so the lander adjudicates the law without ' +
    're-deriving its locality), anchors (file:line evidence), existingClause (the exact reviewer/laws/constitution clause it would ' +
    'harden, quoted with its path — or "absent" with the surfaces searched). A page-local fix never nominates; an empty array is the normal ' +
    'verdict — the terminal doctrine lander refutes weak rows, so nominate substance, never volume.';

const DOCTRINE = [
    LAW,
    '',
    ADVERSARIAL,
    '',
    CSDOCTRINE,
    '',
    CS_SHAPE,
    '',
    CS_INTERFACE,
    '',
    CS_AOP,
    '',
    CS_RAILS,
    '',
    CS_CORE_LOGIC,
    '',
    CS_GRAPH,
    '',
    PARAM_POLY,
    '',
    CS14,
    '',
    CS_SUBSTRATE,
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

const authorPrompt = (page) =>
    [
        DOCTRINE,
        '',
        HARVEST_LAW,
        '',
        'TASK: HOSTILE HARDEN of ' +
            page +
            ' to the ULTRA-DENSE C# doctrine bar; you own THIS file alone ' +
            '(siblings are mid-pipeline in their own concurrent hardens — do not read or edit them; corpus composition belongs to critique/redteam and the ' +
            'terminal corpus agent). DISBELIEVE the page — ' +
            'assume the fence is naive, junior, or illusory until proven 13/10, and treat dense confident-looking content as a prime suspect for ' +
            'hollow/decorative complexity. Read the page, the README atlas + doctrine + the domain/README router, the PYTHON doctrine (the ' +
            'read-only rigor benchmark), the style-guide, and VERIFY every cited host/NuGet member via `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api` (assay blocked or ' +
            'unavailable: the `.api` catalogs, the nuget MCP for feed truth, and Context7/exa/tavily for the official surface own the fallback). Construct ' +
            'in BOUNDARY_ADMISSION lifecycle order; collapse parallel shapes into ONE generated closed-family owner chosen by ' +
            'OWNER_CHOOSER; weave every cross-cutting concern as a definition-time source-gen aspect or a composition-time effect transformer over a thin ' +
            'pure core (two-weave AOP); parameterize fully; one polymorphic entrypoint per modality; C# 14 / net10 to the metal. Make the exemplary snippet ' +
            'AGNOSTIC (neutral names, no project noun), compiling, ~3-4x denser than ordinary code, one owner ready to replace 10+ loose things with the ' +
            'growth axis visible. CAPABILITY-COMPLETENESS IS MANDATORY, NOT OPTIONAL: the body of every owner the fence teaches implements what its ' +
            'names and prose promise — a named-but-omitted capability is a defect you close NOW, at the same bar as any other finding. Cut every ' +
            'table-stakes card/snippet and every loose type/constant cluster. Apply page-craft + section-order + ' +
            'style/comment hygiene. Report `collapsed` (count before->after), `extended` (each addition + cited source), and the page`s spotlight `regions`. ' +
            'verdict is `rebuilt` unless the page genuinely survived untouched. Return residual_high — {files:[...], claim} for any CROSS-FILE item.',
    ].join('\n');

const critiquePrompt = (page) =>
    [
        DOCTRINE,
        '',
        CURRENT_STATE,
        '',
        HARVEST_LAW,
        '',
        'TASK: HOSTILE DOCTRINAL-CONFORMANCE AUDIT + FIX IN PLACE of ' +
            page +
            '. ULTRA-HARSH, UNAGREEABLE: assume a violation exists in EVERY fence; ' +
            'trust NOTHING the prose claims; "good enough"/"mature" rejected. CORPUS AWARENESS: read the README + EVERY file under docs/stacks/csharp/ ' +
            'from CURRENT disk so your judgments are corpus-aware (vocabulary consistency, region overlap, altitude) per CURRENT STATE — you EDIT ONLY ' +
            page +
            '. Read the page, the README doctrine + domain router, the sibling pages, the ' +
            'python rigor benchmark, the style-guide, and verify members via assay api (fallback when blocked: the `.api` catalogs + the nuget MCP + ' +
            'Context7/exa/tavily). REPAIR every hit in place: (1) COLLAPSE_SCAN signals (shapes sharing an identity regime, admission path, payload ' +
            'timing, or consumer collapse into ONE owner; a shape survives only on a genuinely distinct ' +
            'discriminant); (2) OWNER_CHOOSER per shape — replace any non-discriminant-correct owner, kill parallel DTOs/one-field wrappers/field-rename ' +
            'shapes/nullable-as-failure/`default`-ghosts; (3) KNOB_TEST — collapse flags to policy values/input-shape, move ' +
            '`timeout`/`retry`/`CancellationToken` to the carrier/aspect; (4) TWO-WEAVE AOP — definition-time source-gen vs composition-time effect ' +
            'transformers, one seam, no inline-repeated concerns; (5) RAILS — narrowest carrier, closed `Expected` `[Union]` fault, accumulate-vs-abort ' +
            'correct, total generated `Switch` (no silent `_`), no exception control flow; (6) C# 14/net10 + file-organization section-order; (7) the ' +
            'admitted substrate (Thinktecture/LanguageExt/QuikGraph/Mapperly/Generator.Equals) stacked to operator depth + every member verified (delete ' +
            'phantoms); (8) AGNOSTIC snippet law; (9) PAGE GRAMMAR + card ' +
            'economy + load-bearing reject columns; (10) ALTITUDE / no re-teach (a domain shard composes the core, never re-opens it); (11) ZERO META + ' +
            'style + comments; (12) CAPABILITY-COMPLETENESS + illusion + TABLE-STAKES + BOTH NAIVETY AXES — close an omitted capability in place with a ' +
            'cite; rebuild a COVERAGE thin-slice to the real breadth of its concept; collapse an APPROACH roster into ONE generator over seed rows; delete ' +
            'any table-stakes/decorative/speculative card. The 12 checks are a FLOOR, never the complete audit — hunt past them and repair every defect ' +
            'the list does not name. EDIT to fix every hit. Report `extended` and `regions`. Return residual_high {files:[...], claim}.',
    ].join('\n');

const redteamPrompt = (page) =>
    [
        DOCTRINE,
        '',
        CURRENT_STATE,
        '',
        HARVEST_LAW,
        '',
        'TASK: ADVERSARIAL ARCHITECT RED-TEAM + FIX IN PLACE of ' +
            page +
            ' — the LAST and MOST AGGRESSIVE per-file stage; red-team is critique AND ' +
            'MORE; the burden of proof is ON THE PAGE; trust nothing the prior stages claimed. CORPUS AWARENESS: read the README + EVERY file under ' +
            'docs/stacks/csharp/ from CURRENT disk per CURRENT STATE — you EDIT ONLY ' +
            page +
            '. Open the admitted substrate catalogs + the ' +
            'host/NuGet surface, the ' +
            'sibling pages, the README doctrine, the python rigor benchmark, the style-guide. Attack and REPAIR in place: (A) COUNTERFACTUAL on the core ' +
            'shape — a counterfactual REBUILDS the design with its central assumption removed, never merely questions it: name the assumption the ' +
            'fence stands on (the chosen owner kind, the hand-enumerated space, the call-site dispatch, the hand-rolled kernel), derive the form the ' +
            'page takes WITHOUT it — a denser generated owner / `Fold` algebra / data table / a parameterized generator over the enumerated space / a ' +
            'DEEPER admitted-substrate primitive — and where the rebuilt form is stronger, BUILD IT IN PLACE; a stronger design once seen is never ' +
            'defended against, and "the current shape also works" is not a refutation. (B) ANTICIPATORY_COLLAPSE — does the next case/provider land as ' +
            'ONE generated case/row with consumers broken LOUDLY at compile ' +
            'time? reshape so the growth axis is a case/row/policy value. (C) CORPUS-WIDE DUPLICATION — route any snippet re-demonstrating a region a ' +
            'core/sibling/domain page owns. (D) AOP + SHAPE-BUDGET MAXIMIZATION — push more into source-gen aspects + effect transformers over a thinner ' +
            'pure core; collapse any loose cluster into one generated family. (E) STRATA + SUBSTRATE-DEPTH + PHANTOMS — flat code below the operator depth ' +
            'the admitted substrate reaches (collapse to depth); a phantom member (delete it); a domain shard re-opening a core law (route it). (F) ' +
            'CAPABILITY-COMPLETENESS + ILLUSION + LONG-TAIL + BOTH NAIVETY AXES — name an omitted capability with a cite and extend the owner in place; ' +
            'attack the long tail (the fault rail, the empty/degenerate case, the boundary value the taught law must survive); rebuild a COVERAGE ' +
            'thin-slice to the real breadth of its concept; collapse an APPROACH roster into ONE generator over seed rows; delete ' +
            'table-stakes/decorative/speculative content. ALSO a FULL COLD ADVERSARIAL RE-REVIEW of every critique dimension. The page must end ' +
            'objectively denser, more capable, more agnostic-compliant; if the strongest form is genuinely present, find nothing — never invent churn. ' +
            'Report `extended` and `regions`. Return residual_high {files:[...], claim}.',
    ].join('\n');

const corpusPrompt = (ordered, residuals, failed) =>
    [
        DOCTRINE,
        '',
        HARVEST_LAW,
        '',
        'THE SETTLED ATLAS (order):\n' + JSON.stringify(ordered, null, 1),
        '',
        'TASK: TERMINAL CORPUS SWEEP (WRITER — no agent edits a docs/stacks/csharp page after you; the per-file pipelines are ' +
            'done and every page is on ' +
            'CURRENT disk). Read the README first, then every atlas page IN FULL in order; WRITE every fix in place via Edit/Write across ANY page under ' +
            ROOT +
            '/ — a finding is a fix, never a note. The sweep owns FIVE mandates at once:',
        '(1) ALIGN — the corpus as ONE body: one unified shape vocabulary across all pages (identical spellings for shared rails, generated owners, ' +
            'fault families, policy forms); zero duplicated snippet regions corpus-wide (repair by routing to the owning page, never by re-teaching); ' +
            'altitude (each page owns ONLY its layer; later atlas pages compose earlier law as settled supporting material, never restate it; a domain ' +
            'shard composes the finalized core laws and never re-opens admission/shape/rail/dispatch/boundary decisions the core owns); the README atlas ' +
            'table, the domain/ router, routing rows, region ledger, and law groups match the on-disk corpus exactly.',
        '(2) GAP-CLOSE — every COVERAGE FLOOR, CONTENT MANDATE, and capability-completeness law the doctrine blocks state has an owning law on the ' +
            'right page and every fence demonstrates the mandates its layer admits (generated closed-family owners, the two-weave AOP, the LanguageExt ' +
            'rails, the interface/graph seam law, the CS_SUBSTRATE stacking); close every gap IN PLACE on the owning page; spot-verify named host/NuGet ' +
            'members via assay api (fallback when blocked: the `.api` catalogs + the nuget MCP + Context7/exa/tavily) and delete phantoms.',
        '(3) COMPUTATION-LAW BODIES — the algorithmic-bodies law legislates every working body in the corpus: audit EVERY fence on EVERY page against ' +
            'it — deferred LINQ at depth (`Aggregate`/`SelectMany`/`Zip`/`Chunk`/`GroupBy`/`Scan`) or LanguageExt `.Fold`/`.FoldBack`/`.Traverse`/' +
            '`.Choose` over the carrier in place of mutable accumulation, collection expressions + list/slice/relational/logical patterns + ' +
            'switch-expression dispatch over closed families in place of imperative branching, `ref struct`/`Span<T>` kernels ONLY where EARNED at the ' +
            'named EXPRESSION_SPINE exemption — and rebuild any body below that bar in place; a fence whose body the computation law would rewrite is a ' +
            'defect on ITS page, whatever the page`s own layer.',
        '(4) RESIDUALS — the cross-file residuals below are SIGNALS the per-file pipelines reported, not law: re-verify each on CURRENT disk (a later ' +
            'sibling pipeline may already have resolved it); implement the STRONGEST resolution — the denser root-level reconstruction where the implied ' +
            'fix is weak, short-sighted, or a single-point patch; a residual factually wrong or already resolved on disk is rejected with reason. ' +
            'RESIDUALS: ' +
            JSON.stringify(residuals),
        '(5) FINALIZE — the terminal cold read as a first reader with fresh hostile eyes: fix every residual weakness, hedge, meta line, thin card, or ' +
            'under-dense fence; density within the soft ~450 LOC signal without card/snippet spam; hunt PAST the residual list on your own authority — ' +
            '`beyond` enumerates those fixes, and an empty `beyond` attests your hunt found nothing, never that it did not run. FAILED PAGES (their ' +
            'pipeline died — the page left the run un-hardened; give it the full harden here as part of this sweep): ' +
            JSON.stringify(failed) +
            '. ' +
            'Return files, resolved, beyond, rejected, summary.',
    ].join('\n');

const gatePrompt = (ordered) =>
    [
        DOCTRINE,
        '',
        'TASK: JUSTIFICATION GATE (default-off new-page valve). Diff the doctrine blocks above against the ON-DISK README laws + atlas: every law, ' +
            'mandate, or substrate elevation this doctrine legislates that the README has NOT yet landed is a live DELTA — the known candidates are (1) the ' +
            'CROSS-STRATUM interface seam + foreign-constraint-vs-internal-switch forms in the interface law, (2) GRAPH-AS-CLOSED-FAMILY (node/edge ' +
            'neutral-algebra union + derived-fold aggregate + phase split + ALREADY-OWNED content addressing), (3) the mapping/equality generated-aspect ' +
            'clause in the two-weave AOP law and the QuikGraph/Riok.Mapperly/Generator.Equals substrate elevation — and each counts ONLY to the extent ' +
            'the README has not landed it (a landed delta is settled, never re-adjudicated). For EACH live delta decide its owner. DEFAULT and TIE go to ' +
            'harden_in_place: a delta lands as IN-PLACE hardening of an EXISTING owner page — the interface + graph facets DISTRIBUTE across shapes.md ' +
            '(node/edge union, OWNER_CHOOSER), surfaces-and-dispatch.md (dispatch over the seam), boundaries.md (the floor + content key), algorithms.md ' +
            '(the phase split + QuikGraph traversal); the mapping/equality facet folds into the definition-time weave those pages instantiate; ' +
            'content-addressing is ALREADY triple-owned and MUST route, never spawn a page. Return verdict=new_page for AT MOST ONE delta and ONLY if you ' +
            'can prove ALL of: (a) it is a DISJOINT coding-law layer NO atlas decision [01]-[07] already owns — cite EACH [01]-[07] decision and show why ' +
            'none fits; (b) it cannot be carried as cards inside an existing page without re-teaching that page`s disjoint layer; (c) you can name a precise ' +
            'target atlas_index + reader-DECISION label + folder. A new page is a structural commitment (it renumbers the whole downstream atlas and ' +
            're-finalizes every later page), not a thoroughness gesture: if ANY of (a)-(c) is weak, return harden_in_place. The ONLY plausible candidate on ' +
            'current evidence is a combinatorial GRAPH-ALGORITHM layer (topology/connectivity/traversal) that algorithms.md`s numeric charter provably ' +
            'cannot absorb — and even that is likely a package/domain concern, not agnostic doctrine. Read ' +
            ROOT +
            '/README.md ([01]-[ATLAS], ' +
            '[02]-[DOCTRINE], [05]-[PAGE_CRAFT], [06]-[CORPUS_LAW]) and the candidate owner pages. Current ordered atlas file set:\n' +
            JSON.stringify(ordered, null, 1) +
            '\nReturn verdict, reason, and (only for new_page) page {path, atlas_index, decision, folder, ' +
            'justification, seed_regions}.',
    ].join('\n');

const seedPrompt = (page) =>
    [
        DOCTRINE,
        '',
        'TASK: SEED a JUSTIFIED new core doctrine page at ' +
            page.path +
            ' (reader-decision "' +
            (page.decision || '') +
            '", target atlas index ' +
            page.atlas_index +
            '). The justification gate cleared it: ' +
            (page.justification || '') +
            '. (1) AUTHOR a page-craft-conformant skeleton + ' +
            'initial REAL content at ' +
            page.path +
            ' — narrow index table, then deep family cards, then ONE agnostic snippet per region; the page ends ' +
            'at its last card; states doctrine as fact, ZERO meta. (2) EDIT ' +
            ROOT +
            '/README.md [01]-[ATLAS]: insert the row at index ' +
            page.atlas_index +
            ', RENUMBER every downstream [INDEX] label, add the [READ] link (the README is the ONLY file that links), set this row [STATE] to `partial` (it ' +
            'gains authority only when the cold-grade gate later flips it to finalized). (3) PRE-SEED the region-ledger row for its claimed regions (' +
            JSON.stringify(page.seed_regions || []) +
            ') per CORPUS_LAW (snippet rows are written before code exists). Edit ONLY under ' +
            ROOT +
            '/. Return ' +
            '{path, atlas_index, regions, verdict:`seeded`}; return verdict:`aborted` and leave the corpus UNTOUCHED if on closer read the page is NOT a ' +
            'disjoint layer after all.',
    ].join('\n');

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('Inventory');
const inv = await agent(
    'INVENTORY — pure mechanical enumeration, read-only. Resolve the ordered page set against REAL disk state, never ' +
        'memory: run a real find/ls listing of every page under ' +
        ROOT +
        ', read ' +
        ROOT +
        '/README.md [01]-[ATLAS] for the core order and the ' +
        ROOT +
        '/domain/README.md router for the shard order — routers own ORDER, disk owns EXISTENCE (a page on disk absent from the atlas/router ' +
        'still returns, ordered after its section). Return every CONCEPT page that exists on disk as {path (repo-relative), order (global integer: ' +
        'core pages first in atlas order, then the domain/ shards in the domain router order)}, EXCLUDING every README.md and the entire .reports/ ' +
        'workspace. Enumerate and order — nothing else: no page reading, no capability maps, no verdicts (every downstream stage re-reads the full ' +
        'pages from disk). Use find/ls and reading ONLY the README routers; do not cd; do not edit anything.',
    { label: 'inventory', phase: 'Inventory', schema: INVENTORY_SCHEMA, model: 'sonnet', effort: 'low' },
);
const ordered = ((inv && inv.files) || [])
    .filter((f) => f && f.path && f.path.indexOf('/.reports/') < 0)
    .sort((a, b) => a.order - b.order)
    .map((f) => f.path);
log('Inventory: ' + ordered.length + ' csharp doctrine pages (core + domain) to harden; CAP=' + CAP);
if (!ordered.length) {
    log('No pages resolved — nothing to harden');
    return { workflow: 'stack-cs', root: ROOT, total: 0 };
}

phase('Gate');
const gate = await agent(gatePrompt(ordered), { label: 'gate', phase: 'Gate', schema: GATE_SCHEMA, effort: 'high' });
if (gate && gate.verdict === 'new_page' && gate.page && gate.page.path) {
    const seed = await agent(seedPrompt(gate.page), {
        label: 'seed:' + nameOf(gate.page.path),
        phase: 'Gate',
        schema: SEED_SCHEMA,
        effort: 'high',
    });
    if (seed && seed.path && seed.verdict === 'seeded') {
        const at = Math.max(0, Math.min(ordered.length, (gate.page.atlas_index || ordered.length + 1) - 1));
        ordered.splice(at, 0, seed.path);
        log('Gate: new core page seeded -> ' + seed.path + ' at atlas index ' + gate.page.atlas_index);
    } else {
        log('Gate: seed aborted -> harden-in-place');
    }
} else {
    log('Gate: harden-in-place (no new core page justified)');
}

// Per-file pipeline: initial -> critique -> redteam chain WITHIN the file only; the pool is the sole scheduler across files.
phase('Harden');
const results = (
    await pool(ordered, CAP, async (page) => {
        const init = await agent(authorPrompt(page), {
            label: 'initial:' + nameOf(page),
            phase: 'Harden',
            schema: FIXLOG_SCHEMA,
            effort: 'high',
        });
        if (!init) return { page, failed: true, logs: [] }; // failure isolation: a dead initial skips its file's reviews; the run continues
        const crit = await agent(critiquePrompt(page), {
            label: 'critique:' + nameOf(page),
            phase: 'Harden',
            schema: FIXLOG_SCHEMA,
            effort: 'high',
        });
        const rt = await agent(redteamPrompt(page), {
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
// RESTRICTED to reviewer/laws/constitution (this run owns docs/stacks/csharp); refutation-first, land-nothing legal.
phase('Doctrine');
const HARVEST_ROWS = results.flatMap((r) => (r.logs || []).flatMap((l) => (l && l.harvest) || [])).concat((corpus && corpus.harvest) || []);
const doctrine = HARVEST_ROWS.length
    ? await agent(
          'TASK: DOCTRINE LANDER — the durable-learning terminal of this run. Read `docs/laws/README.md` ' +
              'FIRST — it owns the corpus admission and page-shape law; obey it over any restatement. Load ' +
              'the `docgen` skill via the Skill tool BEFORE any durable edit; load ' +
              '`mermaid-diagramming` before touching any diagram. This run AUTHORED the docs/stacks/csharp corpus — adjudicate ' +
              'ONLY reviewer/laws/constitution nominations and NEVER edit a docs/stacks/csharp page; a stacks-altitude nomination ' +
              'is already owned by the run and is rejected. ' +
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
    workflow: 'stack-cs',
    root: ROOT,
    ordered: ordered,
    total: ordered.length,
    gate: (gate && gate.verdict) || 'harden_in_place',
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
