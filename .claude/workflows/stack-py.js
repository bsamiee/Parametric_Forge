export const meta = {
    name: 'stack-py',
    whenToUse: 'Harden the docs/stacks/python code doctrine in place across the whole settled corpus.',
    description:
        "Full-stack hardening of the docs/stacks/python CODE DOCTRINE — the standing python-stack harden engine (peer to stack-cs and stack-ts), run whenever to push the whole settled corpus (the core concept pages and any sub-folder shard set present on disk) to the 13/10 ultra-dense bar. NOT a from-scratch build and NOT a restructure: the file set is settled and admits no new-page valve here — a structure decision routes through a rebuild campaign, never this harden (hence no Gate phase). Each FILE runs its own initial -> critique -> redteam pipeline; ALL files run concurrently under one pool cap — the chain is the file's own stage dependence, never a corpus barrier. Every stage is HOSTILE: the page is naive/shallow/illusory until it survives an aggressive attack, the burden of proof on the page. CRITIQUE is the mechanical line-by-line doctrinal-conformance audit (COLLAPSE_SCAN, OWNER_CHOOSER, KNOB_TEST, AOP, rails, py3.15/payloads, citation tier, agnostic snippet law, page-craft, altitude, zero-meta, capability-completeness) fixed in place; REDTEAM is critique AND MORE — counterfactual on the core teaching shape, anticipatory-collapse of the next case, corpus-wide duplication, AOP + shape-budget maximization, substrate-depth + phantoms, a full cold adversarial re-review. Critique and redteam read the LIVE corpus — the current on-disk state of every page, landed sibling hardening composed as found, a conflict resolved to the stronger form, never a revert — and edit ONLY their own file (the anti-collision rule among concurrent pipelines), reporting cross-file residuals. ONE terminal corpus agent then aligns cross-file seams, closes gaps, enforces the computation-law bodies, resolves every reported residual, and finalizes cold in one sweep. Every per-file stage and the corpus sweep carry a required-but-usually-empty harvest attestation RESTRICTED to reviewer/laws/constitution altitudes (the run authors docs/stacks/python, so a stacks lesson is already owned and never nominated); when the pooled nominations are non-empty, ONE terminal doctrine lander adjudicates them against docs/laws (refutation-first, land-nothing legal, never re-editing a docs/stacks/python page). The csharp doc set is the read-only FLOOR/reference; snippets agnostic; every cited member verified against the .api catalogs (novel members via assay api with its Context7/exa fallback); every edit scoped to docs/stacks/python. Takes no args.",
    phases: [
        {
            title: 'Inventory',
            detail: 'mechanical enumeration: the ordered settled file set from the README atlas + any sub-folder routers, resolved against real disk',
        },
        {
            title: 'Harden',
            detail: 'per FILE: initial -> critique -> redteam chained within the file; all files concurrent under one pool cap; critique/redteam read the live corpus and edit only their own file',
        },
        {
            title: 'Corpus',
            detail: 'ONE terminal corpus agent: align seams, close gaps, computation-law bodies, resolve every reported residual, finalize cold',
        },
        {
            title: 'Doctrine',
            detail: 'terminal doctrine lander fires only on non-empty pooled harvest RESTRICTED to reviewer/laws/constitution (the run owns docs/stacks/python); refutation-first, land-nothing legal',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const CAP = 14;
const ROOT = 'docs/stacks/python';

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
// Altitude is RESTRICTED to surfaces this run does NOT author: the run owns docs/stacks/python, so a stacks nomination is already landed.
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
    'TARGET: docs/stacks/python/ is the route-owned Python CODE DOCTRINE — a doc set of AGNOSTIC teaching pages (the core concept pages and any ' +
        'sub-folder shard set present on disk) that legislate how all project Python is written. It is NOT a libs/python/.planning design corpus: a page ' +
        'teaches a coding LAW with one exemplary agnostic snippet, never a concrete module. The README owns routing + the 17 doctrine laws + the ' +
        'COLLAPSE_SCAN + page-craft; a sub-folder README, where one exists on disk, is a one-table router whose shards compose the core laws and never ' +
        're-open them; each concept page owns ONE disjoint layer and states doctrine as fact. READ docs/stacks/python/README.md sections [02]-[DOCTRINE], ' +
        '[03]-[COLLAPSE_SCAN], [05]-[PAGE_CRAFT], [06]-[CORPUS_LAW] + any sub-folder routers on disk and hold them as law.',
    'LAWS — read `docs/laws/` before any durable edit (README + topology + patterns + scars; short registry pages): a topology row whose ' +
        '[SURFACE] your edits touch binds its obligated counterparts into the SAME pass, and every patterns row binds each branch it names ' +
        '(the python/csharp parity coupling is a patterns concern).',
    'QUALITY BAR: the PYTHON stack is the highest-rigor stack in the repo; docs/stacks/csharp/ (the README + shapes + surfaces-and-dispatch + the ' +
        'domain/ shards) is the read-only FLOOR/reference — NEVER edit a csharp file. Mirror its DENSITY — SHAPE_BUDGET, DEEP_SURFACES, MODAL_ARITY, ' +
        'ANTICIPATORY_COLLAPSE (one owner ready to replace 10+ loose things), POLICY_VALUES, OWNER_CHOOSER — in pure-Python idiom and push PAST it to ' +
        'the strongest form Python admits; NEVER import a C#/LanguageExt spelling (`[Union]`, `Fin`, `SmartEnum`) into a Python page. The csharp set ' +
        'is a floor for how dense the Python set must read, never how it must be spelled.',
    'WRITE-FULLY MANDATE, scoped to docs/stacks/python/** ONLY: every defect you identify you FIX NOW via Edit/Write directly in the file; the ' +
        'structured fix-log you return is a REPORT of edits ALREADY MADE, never a to-do list, a ledger, or a would/should hedge. Edit ONLY files under ' +
        'docs/stacks/python/; reading csharp/standards/.api files is allowed, editing anything outside docs/stacks/python/ is forbidden. Leave nothing ' +
        'behind except a genuine cross-FILE defect a concurrent sibling pipeline owns — report it in residual_high; the terminal corpus agent resolves ' +
        'every reported residual in this same run.',
].join('\n');

const ADVERSARIAL = [
    'ADVERSARIAL STANCE — EVERY stage (author, critique, AND red-team) is HOSTILE: assume the page is NAIVE, SHALLOW, JUNIOR, or ILLUSORY until it ' +
        'survives an aggressive attack; the burden of proof is ON THE PAGE, never on you. A `finalized` state marker, "mature", "already strong", ' +
        '"good enough", and a prior `clean` grade are REJECTED self-assessments. Default to "this page is naive and must be rebuilt to the strongest ' +
        'form the doctrine admits" and MAKE that rebuild; a no-edit verdict is earned ONLY after a genuinely aggressive attack finds nothing.',
    'ILLUSORY / FAKE content is the PRIMARY target — the MOST dangerous content is what PRETENDS to be advanced: a snippet that READS dense and ' +
        'confident (uses `@tagged_union`/`frozendict`/the rails, cites packages) yet demonstrates a THIN slice; prose that ASSERTS richness the fence ' +
        'does not contain; a card field (`Use`/`Accept`/`Reject`/`Law`/`Boundary`) that decides nothing; a structurally-correct collapse that is ' +
        'semantically empty; a `.api` member cited but unverifiable (a PHANTOM — delete it). Treat dense, confident-looking fences with MORE ' +
        'suspicion, not less, and DISBELIEVE every claim the page makes about itself until verified.',
    'NAIVETY is a defect on TWO orthogonal axes, both intolerable: COVERAGE — the owner models a THIN SLICE of its concept (the obvious three ' +
        'fields where the domain carries fifteen; a two-case family for a twenty-case space); APPROACH — enumerated hardcoded instances where a ' +
        'parameterized, algorithmic owner should GENERATE the space (a fixed roster of styles, patterns, or variants is seed DATA feeding ONE ' +
        'generator over named parameters, never the mechanism itself). Attack both axes in every fence and repair on sight.',
    'CRITIQUE vs RED-TEAM (hold the distinction): CRITIQUE is the MECHANICAL, line-by-line doctrinal-conformance audit — run every checklist signal ' +
        'across every fence and FIX each hit in place. RED-TEAM is critique AND MORE — the LAST, MOST AGGRESSIVE pass that re-runs the entire critique ' +
        'with fresh hostile eyes AND adds the architect lenses (counterfactual on the core shape, anticipatory-collapse of the next case, corpus-wide ' +
        'duplication, AOP + shape-budget maximization, substrate-depth + phantoms, capability-completeness). Neither is a ledger of notes: both EDIT ' +
        'the page; the page must end objectively denser, more capable, and more doctrine-compliant than each stage found it.',
].join('\n');

const PYDOCTRINE17 = [
    'HOLD the README [02]-[DOCTRINE] 17 laws as fact, never restated on a concept page: [FLOW] EXPRESSION_SPINE (domain logic is expression-shaped; ' +
        'dependent steps `bind`, independent ones accumulate; statements survive only in a measured kernel that names the exemption) + ' +
        'BOUNDARY_ADMISSION (`Raw -> Payload -> Canonical owner -> Rail -> Projection -> Egress`; raw admitted EXACTLY ONCE into an evidence-carrying ' +
        'owner; interior never re-validates or sees `None`-as-failure/sentinel/provider shape). [SHAPE] SHAPE_BUDGET + DEEP_SURFACES + MODAL_ARITY + ' +
        'ANTICIPATORY_COLLAPSE. [DERIVATION] POLICY_VALUES + DERIVED_LOGIC + DERIVED_TYPES + SYMBOLIC_REFERENCE + SEMANTIC_NAMING. [MATERIAL] ' +
        'LIBRARY_DEPTH + DEFERRED_IMPORTS + DEFINITION_TIME_ASPECTS. [INTEGRATION] ROOT_REBUILD + ONE_HOP_RESOLUTION + COMPOSED_IMPLEMENTATION.',
    'RUN the README [03]-[COLLAPSE_SCAN] 12-signal table on every fence: any signal triggers the collapse move — shapes sharing an identity regime, ' +
        'an admission path, a payload timing, or a consumer collapse into ONE owner, and a shape survives only on a genuinely distinct discriminant. ' +
        'Every enumerated collapse/kill list in this doctrine is a FLOOR, never the complete set: any repeated structure, parallel spelling, or ' +
        'enumerable family an algebra, table, fold, or generator can own is a collapse target you hunt down yourself, listed or not. A page that ' +
        'demonstrates a coding law must itself obey every law it can reach.',
].join('\n');

const SHAPE_ADT = [
    'EXTREME SHAPE/TYPE DENSITY (the central mandate): one concept owns exactly ONE type as a dense CLOSED-FAMILY ADT — `@tagged_union` / `Literal` ' +
        'set / `StrEnum` / `msgspec.Struct` / frozen dataclass / `frozendict` table — chosen by the OWNER_CHOOSER 5 discriminants (admission, identity ' +
        'regime, variant arity, payload timing, openness). KILL on sight: loose 1-2-field classes, parallel DTOs, field-rename wrappers, tag-only ' +
        'shapes, and sibling module constants/types for one concept sharing an identity regime, admission path, payload timing, or consumer (collapse ' +
        'to one `frozendict`/`StrEnum`/closed family — a shape survives only on a genuinely distinct discriminant). No loose/weak type or ' +
        'constant spam survives.',
    'ANTICIPATORY_COLLAPSE: shape the owner for the family it WILL absorb so the next case/dimension/modality lands as ONE declaration with every ' +
        'consumer untouched or broken loudly at type-check — one owner READY TO REPLACE 10+ loose things. The exemplary snippet MUST show the owner at ' +
        'that scale with the growth axis visible, not an isolated minimum.',
].join('\n');

const AOP_FIRST = [
    'FULL AOP (ULTRA-CRITICAL): every CROSS-CUTTING concern — retry, telemetry/spans, validation, contracts, memoization, registration, receipts, ' +
        'fault rails — is OUR OWN signature- AND rail-preserving decorator (inline `**P` + `functools.wraps`) STACKED over a THIN PURE CORE; it ' +
        'materializes policy, stacks in deterministic order, and NEVER raises into domain flow (a failing aspect returns the rail `Error`). The domain ' +
        'transform itself stays a pure function/fold under the stack.',
    'AOP is NOT merely applying `@beartype`/`@msgspec` decorators — though `beartype` (contracts) and `msgspec` (struct/codec) MUST be fully ' +
        'integrated. It means our code SHAPED TOWARD decorators: MAXIMIZE how much functionality is expressed AS stacked decorators; co-occurring ' +
        'wrappers sharing an admission path collapse into ONE parameterized aspect factory; a page reads as stacked decorators over a pure core, ' +
        'never inline-repeated concerns or sibling helper functions. A concern open-coded where a decorator belongs is a defect.',
].join('\n');

const PARAM_POLY = [
    'HEAVY PARAMETERIZATION, ZERO HARDCODING/FRAGILE LOGIC, FULL POLYMORPHISM. ONE entrypoint owns every modality — `T | Iterable[T]` normalized ' +
        'ONCE at the head, discriminating on input SHAPE (type/tag/pattern/arity), never a name suffix or a `mode`/`batch`/`strict` knob (KNOB_TEST: ' +
        'delete each parameter; if the value reconstructs what it carried, it was a knob to collapse).',
    'Configuration enters as ONE behavior-carrying value — a vocabulary member, a tagged variant, a frozen policy table (POLICY_VALUES) — never a ' +
        'flag set the body re-derives. A `timeout`/`retry`/`deadline` is an aspect or an `anyio` scope, never a signature param. Cases sharing ' +
        'generative structure are DERIVED from one primary `frozendict` correspondence (DERIVED_LOGIC), never enumerated arms. Capability exits ' +
        'through FEW dense unified entry points — one polymorphic entry per rail discriminating on input shape (single|batch|stream absorbed by input ' +
        'detection, forward and inverse directions on one surface), variation living in input shape, policy values, and table rows, never parallel ' +
        'exports or modality-named siblings; the surface narrows by absorption, never by omission.',
].join('\n');

const CORE_LOGIC = [
    'WORLD-CLASS ALGORITHMIC BODIES (the function-body mandate, owner = iteration.md): every body that does real work is expression-shaped at full ' +
        'operator depth — a naive `for`-loop with mutable accumulation, a hand-rolled index counter, a `while`-mutator, or an intermediate materialized ' +
        'list where a fused form expresses it is a DEFECT. Collapse multi-accumulator scans into ONE `functools.reduce`/`itertools.accumulate` over a ' +
        'tuple/struct seed; fuse comprehensions and generators (no intermediate lists); reach the FULL `itertools`/`functools` combinator surface ' +
        '(`accumulate`/`groupby`/`pairwise`/`chain.from_iterable`/`product`/`starmap`/`takewhile`/`tee`/`islice`/`batched`/`compress` + ' +
        '`reduce`/`cache`/`partial`/`singledispatch`); walrus where it fuses test+bind; index/window/slice algebra and `zip(strict=True)` over manual ' +
        'indexing; structural `match` as data-shape dispatch; recursion or divide-and-conquer where it reads cleaner than iteration.',
    'ALTITUDE: iteration.md owns the NON-carrier, NON-numeric pure-computation algebra; rails-and-effects owns carrier-threading folds ' +
        '(`Block.fold`/`traverse`/`sequence`/`partition`); algorithms.md owns numeric folds. A body re-deriving line-by-line what a deeper ' +
        'composed form states once is surface-sprawl-in-time. Every snippet body across the corpus obeys this and composes iteration.md as settled ' +
        'supporting material, never re-teaching it.',
].join('\n');

const ASYNC_DEPTH = [
    'STRUCTURED-CONCURRENCY DEPTH (wherever a page touches async): one `anyio` failure boundary, NEVER naive `asyncio`. Task fan-out is a task group ' +
        'with a typed child carrier; cancellation is scope-based (`fail_after`/`move_on_after`/`current_effective_deadline`, level-triggered, ' +
        '`get_cancelled_exc_class()` re-raised under `CancelScope(shield=True)`, never railed into a `Result.Error`); offload is a `frozendict[Lane, ' +
        'Offload]` table over `to_thread`/`to_interpreter`/`to_process` + `CapacityLimiter`; a `BaseExceptionGroup` is partitioned via `except*` and ' +
        'reduced through the rail fault monoid; memory object streams + sync primitives own producer/consumer handoff; teardown is `AsyncExitStack` + a ' +
        'shielded close. Retry is `stamina` (`AsyncRetryingCaller`/`retry_context` + `RetryHook` spans) over raised transients only — never a loop.',
    'REJECT on sight: `asyncio.gather`/`create_task`/`wait_for`/`sleep`, `ThreadPoolExecutor`/`ProcessPoolExecutor` on the loop, bare `try`/`finally` ' +
        'teardown, wall-clock sleep in tests (use `trio` `MockClock(autojump_threshold=0)`/`wait_all_tasks_blocked`). The `trio` backend is the proven ' +
        'seam; a transport rail (`asyncssh` `SSHClientConnection.run(check=True)`) is a rail-CONSUMER example, never the subject of a core page. Stack ' +
        'the async surface at full depth — flat single-await code below the structured-concurrency operator depth is a defect.',
].join('\n');

const PAYLOAD_TAXONOMY = [
    'PAYLOAD TAXONOMY (closed, MINIMAL, each pushed PAST the limit — `frozendict` is ONE member, NEVER the default): the payload shape is chosen by ' +
        'discriminant, never settled on one form. EDGE keyword ingress -> closed `TypedDict` (`closed=True`/`extra_items=T`, per-key ' +
        '`Required`/`NotRequired`/`ReadOnly`) via a module-level `TypeAdapter`, `Unpack[TypedDict]` only at root entrypoints. UNTRUSTED ingress -> a ' +
        '`pydantic` model at the edge (discriminated unions via `Field(discriminator=...)`, `Annotated` `AfterValidator`/`WrapValidator`, ' +
        '`model_validator`, `TypeAdapter.validate_python`/`validate_json`). STRUCTURED domain payload -> `@tagged_union` `case()` carrying per-case ' +
        'data. WIRE/egress -> `msgspec.Struct(frozen=True)` at full depth (`tag`/`tag_field` tagged unions, `array_like=True`, `forbid_unknown_fields`, ' +
        '`msgspec.Meta` constraints). DEFERRED octets -> `msgspec.Raw`. IMMUTABLE table/evidence/extension-band -> `frozendict`.',
    'Each shape is mined to its DEEPEST API form and the family stays MINIMAL — adding a parallel shape for one concept is a defect, and so is forcing ' +
        'one shape (a `dict[str, Any]` bag, a `MappingProxyType`, a mutate-then-freeze, a tuple-pair pseudo-map, homogeneous `**kwargs`) where the ' +
        'discriminant selects another. Owners: shapes.md owns the taxonomy + admission, boundaries.md owns the wire/octet seam.',
].join('\n');

const PY315 = [
    'BLEEDING-EDGE Python 3.15 ONLY: PEP 585 builtin generics, PEP 604 unions, PEP 695 type parameters (`class C[T]`, `def f[T]`, `type Alias[T] = ' +
        '...`). NEVER `from __future__ import annotations`; NEVER legacy `typing.List`/`Optional`/`Union`/`TypeVar`+`Generic`. Use ' +
        '`Self`/`override`/`TypeIs`/`assert_never`/`ReadOnly`/`LiteralString`, total `match` + `assert_never` over closed unions, walrus where it ' +
        'tightens.',
    'PAYLOADS — newest form: ingress payloads are closed `TypedDict` (`closed=True` or `extra_items=T`, per-key `Required`/`NotRequired`/`ReadOnly`) ' +
        'admitted through a module-level `TypeAdapter`, with `Unpack[TypedDict]` at root keyword entrypoints (never forwarded through interiors); ' +
        '`msgspec.Struct(frozen=True)` owns wire/egress. `frozendict` (py3.15 builtin) owns immutable map rows, dispatch/policy TABLES, and evidence — ' +
        'REJECT `MappingProxyType`, a module-level mutable `dict` used as a table, tuple-pair pseudo-maps, mutate-then-freeze, `dict[str, Any]` bags, ' +
        'and homogeneous `**kwargs`.',
].join('\n');

const APISTACK_SUBSTRATE = [
    'CITATION TIER (load-bearing, doctrine-specific): the SHARED substrate catalogs — `expression`, `pydantic`, `pydantic-settings`, `beartype`, ' +
        '`msgspec`, `anyio`, `structlog`, `stamina`, `numpy`, `psutil`, `opentelemetry-*`, `protobuf`, `grpcio` — are cited by EVERY page. ENUMERATE ' +
        'the catalog set IN FULL with a real `ls`/`fd` listing at every stage — the catalog root is docs/stacks/python/.api/ when present, else the ' +
        'language-wide libs/python/.api/ — never a memory-recalled roster. A CORE page cites ONLY this shared substrate. A sub-folder SHARD (a domain/ ' +
        'or numerics/ page, where such a router exists on disk) cites the shared substrate AND the package-cluster tier (the `.api/` catalogs for ' +
        'the packages its concept composes) — a numerics shard ' +
        'additionally STACKS its scientific cluster at the deepest dense/sparse/iterative/structured primitives its concern reaches — and NOTHING ' +
        'outside its declared cluster. Mine BOTH tiers to their FULL advanced surface and STACK them as ONE dense rail — `expression` rails + ' +
        '`msgspec`/`pydantic` models + `beartype` contracts + `stamina` retry + `structlog`+OTel spans + `anyio` concurrency layered together, never ' +
        'flat one-shot per-library uses.',
    'Cite ONLY members confirmed in the actual .api catalog file; a member you cannot verify is a PHANTOM to delete (verify novel members via ' +
        '`UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api`; assay blocked or unavailable, the package`s official surface via Context7/exa/tavily owns the fallback). An ' +
        'admitted capability the concept admits but NO owner exploits is a DEFECT the pass closes in place, ' +
        'citing the exact member. A domain/numerics shard composes the FINALIZED core laws as settled material (it never re-opens ' +
        'admission/shape/rail/dispatch/boundary decisions the core owns) and owns ONE closed vocabulary for its axis. Use the DEEPEST primitive each ' +
        'package reaches (LIBRARY_DEPTH); flat code below that operator depth is surface sprawl.',
].join('\n');

const PAGECRAFT = [
    'PAGE-CRAFT LAW (README [05]-[PAGE_CRAFT]): page grammar is a NARROW index table, then deep FAMILY CARDS, then ONE agnostic snippet beside the ' +
        'rule it proves; the page ends at its last card. CARD ECONOMY: cards are few, deep, evidence-dense; near-peer cards MERGE until each owns a ' +
        'decision cluster; a card line carries exactly ONE decision; a `Use`/`Accept`/`Reject`/`Law`/`Boundary` field appears only where it decides ' +
        'something — a field that decides nothing is DELETED, not filled. Tables enumerate, cards legislate (rows stay atomic, no prose cramming, no ' +
        'links in cells).',
    'REJECT columns are LOAD-BEARING: every `Use` names the spelling, wrapper, or local pattern it DELETES. CODE NAMES BEFORE PROSE: every member a ' +
        'card or snippet names is verified against the installed package before it is written; a nameable surface spelled as prose is a defect. ZERO ' +
        'META: no provenance, source trace, release narration, process state, freshness disclaimer, or tool/skill context — any such block POISONS ' +
        'every downstream generation that loads the page; a stale `capture-pending`/`research` block is deleted. A sub-folder (domain/, numerics/) present ' +
        'on disk carries its own one-table README router (pages compose root laws, never re-open them).',
].join('\n');

const AGNOSTIC_SNIPPETS = [
    'AGNOSTIC SNIPPET LAW (style-guide [07]-[PLACEHOLDER_LAW]): every snippet COMPILES under Python 3.15 with legal NEUTRAL identifiers — ' +
        '`Shape`/`RefinedShape`/`Variant`/`PRIMARY`/`Field`/`KEY`/`Row`/`ROW_A`/`TABLE`/`SELECTED` — and placeholder strings (`"<value-a>"`) appear ' +
        'ONLY inside literals. NO project, repo, host, customer, pricing, deployment, or business-domain noun anchors a snippet; a domain noun is ' +
        'context poison. (A shard page teaches a coding-axis or numerical LAW agnostically; it is NOT a concrete module or solver ' +
        'for one problem.)',
    'CORPUS-WIDE ZERO duplicated snippet demonstrations: each snippet exercises a surface region NO OTHER snippet in the corpus shows — the region ' +
        'is its spotlight; finalized surfaces composed as supporting material occupy no region and duplicate nothing. A duplicated region is repaired ' +
        'by ROUTING to its owner (compose it as supporting material), never by re-teaching. Snippets are doctrine-exemplary at full operator depth, ' +
        '~3-4x denser than ordinary code, at the scale a large system takes (admission + dispatch + rail + policy in one fence with the growth axis ' +
        'visible).',
].join('\n');

const OPINIONATED = [
    'HEAVILY-OPINIONATED PROJECT DOCTRINE, NOT a language survey. ZERO table-stakes is tolerated, ever: a card or snippet teaching something a ' +
        'competent Python developer already knows — rather than an opinionated, dense, project-specific CHOICE — is a DEFECT to delete or densify. No ' +
        'net-casting to "cover the language"; cover only the opinionated decisions the projects need, each at 13/10.',
    'LOC budget ~450 is a SOFT pressure signal toward DENSIFICATION, NOT a hard gate. The real metric is per-card and per-snippet density: every ' +
        'card and every snippet world-class, zero filler. NEVER strip snippet whitespace, remove design content, or fragment a coherent concept to hit ' +
        'a number; a coherent dense concept may exceed 450 when every card and snippet earns its place (the csharp algorithms.md monolith is the ' +
        'precedent). A split is justified ONLY by concept disjointness, never by line count. HARDENING: capability is IMPROVED or EXTENDED, never ' +
        'dropped — zero current consumers never lowers the capability bar; deletion is lawful only for table-stakes, duplicated-region, phantom, or ' +
        'decorative content, never for a density number.',
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
    'COMMENT HYGIENE + FILE ORGANIZATION: code fences are agent-facing. Do NOT use section-divider headers in snippets (NO `# --- ' +
    '[LABEL] ---` lines and NO standalone `[LABEL]` section-header comments — they add LOC without value); organize PURELY by the canonical ' +
    'declaration ORDER (CLAUDE.md [08]-[FILE_ORGANIZATION]: imports + `TYPE_CHECKING` -> types -> constants -> models -> errors -> services -> ' +
    'operations -> composition -> exports; types before classes; owner blocks + dependency clusters kept intact; the Python overlay puts runtime ' +
    'decoders/registries/tables AFTER the symbols they inspect; runtime/dependency order wins so every fence loads top-to-bottom), and strip any ' +
    'existing divider/section-label line. Beyond that, comment ONLY where intent is not already obvious from names, types, and signatures: default ' +
    'ZERO comments; at most 1 line where a comment genuinely earns its place. No narration, no restating the code, no docstring bloat, no ' +
    'task/process/review comments.';

const CURRENT_STATE =
    'CURRENT STATE — sibling pages are being hardened concurrently by their own file pipelines, each at its own stage. Before ' +
    'any edit, re-read the CURRENT on-disk state of the README and every corpus page your page cross-references; landed sibling hardening is ' +
    'composed AS FOUND, never assumed settled. A conflict between your page and a landed sibling resolves to the STRONGER form, never a revert. ' +
    'You EDIT ONLY your own file while pipelines run — the anti-collision rule; a genuinely cross-file defect is a residual_high the terminal ' +
    'corpus agent resolves in this same run, never a sibling edit.';

const HARVEST_LAW =
    'HARVEST (required key, usually empty): this run AUTHORS the docs/stacks/python corpus, so a stacks-altitude lesson is already owned by ' +
    'the run and is NEVER nominated. Nominate ONLY a lesson that lands at an altitude this run does NOT own — reviewer (a diff-checkable ' +
    'review rule that would have caught a defect BEFORE review), constitution (a most-sessions CLAUDE.md/AGENTS.md behavioral fact), or laws ' +
    '(a cross-surface coupling or cross-branch pattern discovered the hard way). Each row: altitude (reviewer|constitution|laws), lang, claim ' +
    '(the generalized law, one sentence, SYMBOL-FREE — every concrete spelling lives in anchors, so the lander adjudicates the law without ' +
    're-deriving its locality), anchors (file:line evidence), existingClause (the exact reviewer/laws/constitution clause it would ' +
    'harden, quoted with its path — or "absent" and the surfaces searched). A page-local fix never nominates; an empty array is the normal ' +
    'verdict — the terminal doctrine lander refutes weak rows, so nominate substance, never volume.';

const DOCTRINE = [
    LAW,
    '',
    ADVERSARIAL,
    '',
    PYDOCTRINE17,
    '',
    SHAPE_ADT,
    '',
    AOP_FIRST,
    '',
    PARAM_POLY,
    '',
    CORE_LOGIC,
    '',
    ASYNC_DEPTH,
    '',
    PY315,
    '',
    PAYLOAD_TAXONOMY,
    '',
    APISTACK_SUBSTRATE,
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
            ' to the ULTRA-DENSE Python doctrine bar; you own THIS file alone ' +
            '(siblings are mid-pipeline in their own concurrent hardens — do not read or edit them; corpus composition belongs to critique/redteam and the ' +
            'terminal corpus agent). DISBELIEVE the page — ' +
            'assume every fence is naive, junior, or illusory until proven 13/10, and treat dense confident-looking content as a prime suspect for ' +
            'hollow/decorative complexity. Read the page, the README atlas + doctrine sections + any sub-folder routers on disk, ' +
            'the csharp density FLOOR (READ-ONLY), the style-guide, and the .api catalogs it composes — enumerate BOTH tiers per ' +
            'the CITATION TIER law (a core page mines the SHARED substrate; a domain/numerics shard mines the substrate AND its declared package cluster ' +
            '— STACK them; VERIFY every cited member, delete phantoms). Construct in BOUNDARY_ADMISSION lifecycle order; collapse parallel shapes into ONE ' +
            'dense closed-family ADT chosen by OWNER_CHOOSER; express every cross-cutting concern as a stacked signature+rail-preserving decorator over a ' +
            'thin pure core (FULL AOP); parameterize fully, one polymorphic entrypoint per modality; py3.15-modern only. Make the exemplary snippet AGNOSTIC ' +
            '(neutral names, no domain noun), compiling, ~3-4x denser than ordinary code, showing one owner ready to replace 10+ loose things with the ' +
            'growth axis visible. A domain/numerics shard COMPOSES the finalized core laws as settled material and never re-opens them. CAPABILITY-COMPLETENESS IS ' +
            'MANDATORY, NOT OPTIONAL: the body of every owner the fence teaches implements what its names and prose promise — a named-but-omitted ' +
            'capability is a defect you close NOW, at the same bar as any other finding. Cut every ' +
            'table-stakes card/snippet; cut every loose 1-2-field type and constant-spam cluster by collapsing it into one owner. Apply the page-craft ' +
            'grammar (narrow index table -> deep cards -> one snippet per region) and the style/comment hygiene. Report what you collapsed (count ' +
            'before->after) in `collapsed`, what capability you extended (each addition + its cited source) in `extended`, and this page`s spotlight snippet ' +
            'REGIONS in `regions`. verdict is `rebuilt` unless the page genuinely survived untouched. Return residual_high — each a {files:[every ' +
            'repo-relative path the cross-file fix spans], claim} for any CROSS-FILE item you cannot fix from this one file.',
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
            '. You are an ULTRA-HARSH, UNAGREEABLE auditor: assume a violation ' +
            'exists in EVERY fence until you prove otherwise, trust NOTHING the author or the prose claims, and "good enough"/"mature" is rejected ' +
            'outright. CORPUS AWARENESS: read the README + EVERY file under docs/stacks/python/ from CURRENT disk so your judgments are corpus-aware ' +
            '(vocabulary consistency, region overlap, altitude) per CURRENT STATE — you EDIT ONLY ' +
            page +
            '. Read the page, the README doctrine ' +
            'sections, its sibling pages, the csharp reference, the style-guide, and the .api catalogs it ' +
            'composes. Run these MECHANICAL checklists line-by-line and REPAIR every hit in place (a fix, never a ledger note); the checklists are a ' +
            'FLOOR you hunt past, never the boundary of the audit:',
        '(1) COLLAPSE_SCAN — apply the move for any of the README [03] 12 signals (shapes sharing an identity regime, admission path, payload timing, ' +
            'or consumer collapse into ONE owner; a shape survives only on a genuinely distinct discriminant): sibling prefix/suffix -> one ' +
            'modality-polymorphic entrypoint; same rail differing by arity -> input-shape discrimination; a get/get_many/get_by family -> one input-keyed ' +
            'entrypoint; functions differing only by a literal -> parameterize as a POLICY_VALUE; a bool selecting two bodies -> one derived body/policy ' +
            'value; a function calling exactly one other -> delete the hop; a class exposing one public method -> module function/fold; parallel dispatch ' +
            'arms -> a `frozendict` table/fold; several types sharing fields -> one closed family; sibling constants sharing one concept -> one `frozendict`/`StrEnum`; a ' +
            'package-rename wrapper -> use the surface directly; co-occurring wrappers sharing an admission path -> one aspect factory. These 12 signals are a FLOOR — hunt ' +
            'collapse targets past them.',
        '(2) OWNER_CHOOSER — re-derive EVERY shape from the 5 discriminants and replace any non-discriminant-correct owner; KILL every parallel DTO, ' +
            'one-field wrapper, field-rename class, tag-only shape, and `None`-as-failure. (3) KNOB_TEST — delete each parameter; collapse any ' +
            '`strict`/`mode`/`batch` flag into a policy value or input-shape discriminant; move every `timeout`/`retry`/`deadline` off the signature into ' +
            'an aspect or `anyio` scope.',
        '(4) ASPECTS / AOP — every cross-cutting concern is a signature+rail-preserving STACKED decorator over a pure core that never raises into domain ' +
            'flow; co-occurring wrappers sharing an admission path collapse into one aspect factory; `beartype`/`msgspec` integrated; inline-repeated concerns and sibling ' +
            'helpers are defects. (5) RAILS — narrowest carrier chosen once; the fault type is a CLOSED `Literal`/`StrEnum`/`@tagged_union` (a bare `str` ' +
            'fault for a multi-cause domain is a defect); accumulate-vs-abort correct (`map2`/fold for independents, `bind` for dependents); NO `asyncio`, ' +
            'NO hand-rolled retry loop, NO `None`-as-failure, NO exception control flow in domain logic.',
        '(6) PY315 / PAYLOADS / FROZENDICT / PEP — closed `TypedDict` via module-level `TypeAdapter` with `Unpack` at root entrypoints; `frozendict` ' +
            'owns tables/evidence (no `MappingProxyType`/dict-table/tuple-pairs/`dict[str,Any]`); PEP 585/604/695 only, no `from __future__`, no legacy ' +
            'typing; total `match` + `assert_never`. (7) CITATION TIER — a CORE page cites ONLY the shared substrate; a DOMAIN/numerics shard cites the ' +
            'substrate AND its declared package cluster; EVERY cited member verified against the actual catalog (delete phantoms); the full advanced ' +
            'surface is STACKED, not a thin subset.',
        '(8) AGNOSTIC SNIPPET LAW — every snippet compiles, uses neutral structural names, placeholders only inside literals, NO domain/repo/host noun; ' +
            'the snippet shows the form at large-system scale with the growth axis visible. (9) PAGE GRAMMAR + CARD ECONOMY — narrow index table -> deep ' +
            'cards -> one snippet per region -> page ends at last card; card fields earned (delete a field that decides nothing); near-peer cards merged; ' +
            'every `Use` names what it deletes. (10) ALTITUDE / NO RE-TEACH — prose re-teaching a mechanic owned by a finalized prior page (or, for a ' +
            'shard, a core law) is repaired by routing to the owner.',
        '(11) ZERO META + STYLE + COMMENTS — no provenance/process/release/tool context (a stale `capture-pending`/`research` block is deleted); ' +
            'style-guide prose law applied; all code backticked; comment hygiene clean. (12) CAPABILITY-COMPLETENESS + ILLUSION — verify the body ' +
            'implements what names/prose promise; close any capability the substrate/cluster surface, the real concept, or a consumer contract admits that ' +
            'the owner OMITS (a case/row/field/operation), citing its source; reject speculative padding, decorative ceremony, and any TABLE-STAKES ' +
            'card/snippet (delete or densify it).',
        'EDIT the page to fix every hit. Report what you extended in `extended` and the page`s snippet REGIONS in `regions`. Return residual_high — each ' +
            'a {files:[...], claim} for any CROSS-FILE item you cannot fix here.',
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
            '. You are the LAST and MOST AGGRESSIVE per-file stage: assume the author ' +
            'and critique missed things and that the chosen design is naive or illusory until PROVEN the strongest, the burden of proof ON THE PAGE. ' +
            'Red-team is critique AND MORE. CORPUS AWARENESS: read the README + EVERY file under docs/stacks/python/ from CURRENT disk per CURRENT ' +
            'STATE — you EDIT ONLY ' +
            page +
            '. Open the .api catalogs it composes, the sibling pages, the README doctrine, the csharp reference, and ' +
            'the style-guide. Attack from every direction and REPAIR every defect in place — no soft-pedalling, a fix never a ledger.',
        'PRIMARY LENSES, multi-faceted: (A) COUNTERFACTUAL on the page`s core TEACHING shape — a counterfactual REBUILDS the design with its central ' +
            'assumption removed, never merely questions it: name the assumption the fence stands on (the chosen owner kind, the hand-enumerated space, ' +
            'the call-site dispatch, the hand-rolled body), derive the form the page takes WITHOUT it — a denser owner, the `fold`/derived `frozendict` ' +
            'table, a parameterized generator over the enumerated space, a DEEPER substrate/cluster primitive — and where the rebuilt form is stronger, ' +
            'BUILD IT IN PLACE; never defend the incumbent, and "the current shape also works" is not a refutation. (B) ANTICIPATORY_COLLAPSE — compute the DIFF ' +
            'OF THE NEXT case/dimension/modality: does it land as ONE declaration with every consumer untouched or broken loudly at type-check? If it ' +
            'would touch multiple sites, reshape so the growth axis is a case/row/policy value, and the snippet SHOWS one owner ready to replace 10+ loose ' +
            'things.',
        '(C) CORPUS-WIDE DUPLICATION — attack this page`s snippet regions against the corpus as it NOW stands: any snippet re-demonstrating a region ' +
            'another page owns is ROUTED to its owner (composed as supporting material), never re-taught. (D) AOP + SHAPE-BUDGET MAXIMIZATION — ' +
            'counterfactually ' +
            'attack how much MORE functionality could be expressed as stacked decorators over a thinner pure core, and whether any loose type/constant ' +
            'cluster could collapse into one closed family; push PAST the critique`s bar. (E) ALTITUDE + SUBSTRATE-DEPTH + PHANTOMS + CITATION-TIER — a ' +
            'mechanic owned by a finalized prior or a core law (route it); flat code below substrate/cluster operator depth (collapse to package depth); a ' +
            'phantom .api member (delete it); a page reaching the wrong .api tier (route out). (F) CAPABILITY-COMPLETENESS + LONG-TAIL + ILLUSION + ' +
            'TABLE-STAKES — name an omitted capability, edge case, or failure-mode row with a cite and extend the owner in place; delete any ' +
            'table-stakes/decorative/speculative card or snippet.',
        'ALSO — FULL COLD ADVERSARIAL RE-REVIEW (every time): re-attack every critique dimension (1-12) with fresh hostile eyes, trusting nothing the ' +
            'prior stages claimed. Even absent a structural rebuild the page must end objectively denser, MORE capable, more agnostic-compliant, and more ' +
            'opinionated than the critique left it; if the strongest form is genuinely already present, prove it by finding nothing — never invent churn. ' +
            'Report what you extended in `extended` and the page`s REGIONS in `regions`. Return residual_high — each a {files:[...], claim} for a ' +
            'CROSS-FILE item you cannot fix from one file.',
    ].join('\n');

const corpusPrompt = (ordered, residuals, failed) =>
    [
        DOCTRINE,
        '',
        HARVEST_LAW,
        '',
        'THE SETTLED ATLAS (order):\n' + JSON.stringify(ordered, null, 1),
        '',
        'TASK: TERMINAL CORPUS SWEEP (WRITER — no agent edits a docs/stacks/python page after you; the per-file pipelines are done and every page is on ' +
            'CURRENT disk). Read the README first, then every atlas page IN FULL in order; WRITE every fix in place via Edit/Write across ANY page under ' +
            ROOT +
            '/ — a finding is a fix, never a note. The sweep owns FIVE mandates at once:',
        '(1) ALIGN — the corpus as ONE body: one unified shape vocabulary across all pages (identical spellings for shared rails, owners, fault ' +
            'families, policy forms); zero duplicated snippet regions corpus-wide (repair by routing to the owning page, never by re-teaching); altitude ' +
            '(each page owns ONLY its layer; later atlas pages compose earlier law as settled supporting material, never restate it; a domain/numerics ' +
            'shard composes the finalized core laws and never re-opens admission/shape/rail/dispatch/boundary decisions the core owns); the README atlas ' +
            'table, any sub-folder routers on disk, routing rows, region ledger, and law groups match the on-disk corpus exactly.',
        '(2) GAP-CLOSE — every COVERAGE FLOOR, CONTENT MANDATE, and capability-completeness law the doctrine blocks state has an owning law on the ' +
            'right page and every fence demonstrates the mandates its layer admits (closed-family ADTs, the stacked-AOP decorator weave, the ' +
            'narrowest-carrier rails, the py3.15 payload taxonomy, the CITATION-TIER substrate stacking); close every gap IN PLACE on the owning page; ' +
            'spot-verify named members against the .api catalogs and delete phantoms.',
        '(3) COMPUTATION-LAW BODIES — iteration.md legislates every working body in the corpus: audit EVERY fence on EVERY page against its law — ' +
            'multi-accumulator scans collapsed into ONE `functools.reduce`/`itertools.accumulate` over a tuple/struct seed, comprehensions and ' +
            'generators fused with no intermediate lists, the full `itertools`/`functools` combinator surface reached, index/window/slice algebra + ' +
            '`zip(strict=True)` over manual indexing, structural `match` as data-shape dispatch, walrus where it fuses test+bind — and rebuild any body ' +
            'below that bar in place; a fence whose body the computation law would rewrite is a defect on ITS page, whatever the page`s own layer ' +
            '(carrier-threading folds stay with rails-and-effects and numeric folds with algorithms.md per the ALTITUDE law).',
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

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('Inventory');
const inv = await agent(
    'INVENTORY — pure mechanical enumeration, read-only. Resolve the ordered page set against REAL disk state, never ' +
        'memory: read ' +
        ROOT +
        '/README.md [01]-[ATLAS] for the core page order, THEN every sub-folder README router it references (e.g. ' +
        ROOT +
        '/domain/README.md, ' +
        ROOT +
        '/numerics/README.md if present) for each sub-folder`s page order, and run a real fd/find listing of every .md ' +
        'under ' +
        ROOT +
        ' — routers own ORDER, disk owns EXISTENCE. Return every CONCEPT page that exists on disk as {path (repo-relative, e.g. ' +
        ROOT +
        '/shapes.md), order (global integer: core pages first in atlas order, then each sub-folder`s pages in its router order)}, EXCLUDING ' +
        'every README.md and the entire .reports/ workspace. Enumerate and order — nothing else: no page reading, no capability maps, no verdicts ' +
        '(every downstream stage re-reads the full pages from disk). Use fd/ls, reading ONLY the README routers; do not cd; do not edit ' +
        'anything.',
    { label: 'inventory', phase: 'Inventory', schema: INVENTORY_SCHEMA, model: 'sonnet', effort: 'low' },
);
const ordered = ((inv && inv.files) || [])
    .filter((f) => f && f.path && f.path.indexOf('/.reports/') < 0)
    .sort((a, b) => a.order - b.order)
    .map((f) => f.path);
log('Inventory: ' + ordered.length + ' python doctrine pages to harden; CAP=' + CAP);
if (!ordered.length) {
    log('No pages resolved — nothing to harden');
    return { workflow: 'stack-py', root: ROOT, total: 0 };
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
// RESTRICTED to reviewer/laws/constitution (this run owns docs/stacks/python); refutation-first, land-nothing legal.
phase('Doctrine');
const HARVEST_ROWS = results.flatMap((r) => (r.logs || []).flatMap((l) => (l && l.harvest) || [])).concat((corpus && corpus.harvest) || []);
const doctrine = HARVEST_ROWS.length
    ? await agent(
          'TASK: DOCTRINE LANDER — the durable-learning terminal of this run. Read `docs/laws/README.md` ' +
              'FIRST — it owns the corpus admission and page-shape law; obey it over any restatement. Load ' +
              'the `docgen` skill via the Skill tool BEFORE any durable edit; load ' +
              '`mermaid-diagramming` before touching any diagram. This run AUTHORED the docs/stacks/python corpus — adjudicate ' +
              'ONLY reviewer/laws/constitution nominations and NEVER edit a docs/stacks/python page; a stacks-altitude nomination ' +
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
    workflow: 'stack-py',
    root: ROOT,
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
