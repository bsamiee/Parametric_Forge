export const meta = {
    name: 'density',
    whenToUse:
        'Per-file density pass over any landed libs/ planning corpus: pass targets (file / sub-folder / package root, any number, any language mix). Runs on demand over a corpus that is already correct — it collapses shape and entry count, inlines single-caller helpers, demotes rosters to generators, rebuilds flat bodies expression-shaped, and replaces hand-rolled capability with strata composition, losing zero functionality. Roster: one plan lane, one law-pack lane per language, LOC-bounded mappers, one fixer per file, one closer.',
    description:
        'Language-agnostic per-file density engine over the libs/{csharp,python,typescript} planning corpora. args = a target path, an array of paths, or {targets} — languages mix freely, {root} retargets an isolated checkout, empty = no-op; every page derives doctrine, both .api tiers, and its member-verification rail from its owning package. Plan enumerates every design page under the targets with its real line count. Map fans LOC-bounded mappers per package, each writing one map per page — logic threads, shape census with collapse discriminants, entry/knob/helper sprawl, strata leverage, flat code, unexploited api depth, 10x growth stress, exact doctrine shards — grounded in the branch and package ARCHITECTURE.md ledgers, beside one audit-law-pack lane per landed language extracting the doctrine checklist verbatim. Pass runs ONE fixer per file (law pack + its map + its file, nothing more) executing a single ground-up density pass in place, single-file write territory, every cross-file need routed as a typed row. Close runs one drainer over the pooled rows — cross-file seam counterparts, catalog appends, index and IDEAS rows. Capability conservation is absolute: LOC and shape count fall only through stronger owners, never through deletion or extraction. Stage law lives in the prompt blocks.',
    phases: [
        {
            title: 'Plan',
            detail: 'targets expand to every design page under them with its real line count; a page-less target reports and skips',
        },
        {
            title: 'Map',
            detail: 'LOC-bounded mapper sets per package write one map per page (logic flow, shape census, strata leverage, flat code, api depth, growth stress, doctrine route), beside one audit-law-pack lane per landed language extracting the binding checklist sections verbatim into the artifact every fixer reads instead of the atlas',
        },
        {
            title: 'Pass',
            detail: 'ONE fixer per file, all concurrent under the slot scheduler: law pack + its map + its file, nothing more; shape count down through polymorphic collapse, knobs to policy values, single-caller helpers inlined, rosters demoted to generators, bodies rebuilt expression-shaped, hand-rolling replaced with strata composition, growth stress resolved, zero functionality loss; every cross-file need is a typed row, never an edit',
        },
        {
            title: 'Close',
            detail: 'one drainer over the pooled fixer rows: deferred seam counterparts repaired both ends, catalog appends landed, index and IDEAS rows applied once each, harvest folded',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const CAP = 14;
const MAP_LOC = 3400; // page tonnage per mapper — the map set a single mapper holds with full-context care

// --- [INPUTS] --------------------------------------------------------------------------

const normTarget = (t) => String(t).trim().replace(/\/+$/, '').replace(/^\/+/, '');
const langOf = (t) =>
    t.indexOf('libs/csharp') === 0 ? 'cs' : t.indexOf('libs/python') === 0 ? 'py' : t.indexOf('libs/typescript') === 0 ? 'ts' : null;
const argsIn = typeof args === 'string' && /^\s*[\[{]/.test(args) ? JSON.parse(args) : args;
const isObj = !!argsIn && typeof argsIn === 'object' && !Array.isArray(argsIn);
const rawTargets = Array.isArray(argsIn)
    ? argsIn
    : isObj && Array.isArray(argsIn.targets)
      ? argsIn.targets
      : isObj && typeof argsIn.targets === 'string'
        ? [argsIn.targets]
        : typeof argsIn === 'string' && argsIn.trim()
          ? [argsIn]
          : [];
const TARGETS = [...new Set(rawTargets.filter(Boolean).map(normTarget))].filter((t) => langOf(t));
const REJECTED = [...new Set(rawTargets.filter(Boolean).map(normTarget))].filter((t) => !langOf(t));
const ROOT_DIR =
    isObj && typeof argsIn.root === 'string' && argsIn.root.trim()
        ? argsIn.root.trim().replace(/\/+$/, '')
        : '/Users/bardiasamiee/Documents/99.Github/Rasm';
const fnv1a = (s) => {
    let h = 0x811c9dc5;
    for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193);
    return (h >>> 0).toString(16).padStart(8, '0').slice(0, 6);
};
// Prefix is THIS workflow's name, never a shared stem; ROOT_DIR joins the hash because it retargets an isolated
// checkout, so two runs over equal targets in different checkouts never share a data plane.
const SCRATCH =
    '.claude/scratch/' +
    ('density-' + TARGETS.map((t) => t.split('/').pop().toLowerCase()).join('-')).replace(/[^a-z0-9.-]+/g, '-').slice(0, 60) +
    '-' +
    fnv1a(JSON.stringify([TARGETS, ROOT_DIR]));

// --- [MODELS] --------------------------------------------------------------------------

const S = { type: 'string' };

const RECEIPT = {
    // Thin wire receipt: the lane's PRODUCT stays on disk at `report`; only status + count + headline travel inline.
    type: 'object',
    additionalProperties: false,
    required: ['ok', 'report', 'entries', 'headline', 'failure'],
    properties: { ok: { type: 'boolean' }, report: S, entries: { type: 'integer' }, headline: S, failure: S },
};

const PLAN_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['packages', 'pages', 'unresolved'],
    properties: {
        packages: { type: 'array', items: S }, // owning package roots (the path before /.planning/)
        pages: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['page', 'lines'], properties: { page: S, lines: { type: 'integer' } } },
        },
        unresolved: { type: 'array', items: S },
    },
};

const PACK_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['sections', 'summary'],
    properties: {
        sections: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['source', 'lines'],
                properties: { source: S, lines: { type: 'integer' } },
            },
        },
        summary: S,
    },
};

const DELTAS = {
    // navigation facts: what moved, as data, zero adjectives
    type: 'array',
    items: { type: 'object', additionalProperties: false, required: ['symbol', 'change'], properties: { symbol: S, change: S } },
};

const DEFERRED = {
    // the counted cross-file backlog the closer drains
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['files', 'claim'],
        properties: { files: { type: 'array', items: S }, claim: S },
    },
};

const INDEXROWS = {
    // doc = index doc, central manifest, or IDEAS.md; row = the exact row text
    type: 'array',
    items: { type: 'object', additionalProperties: false, required: ['doc', 'row'], properties: { doc: S, row: S } },
};

const HARVEST = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['altitude', 'lang', 'claim', 'anchors', 'existingClause'],
        properties: {
            altitude: { type: 'string', enum: ['stacks', 'reviewer', 'constitution', 'planning', 'readme', 'laws'] },
            lang: S,
            claim: S,
            anchors: { type: 'array', items: S },
            existingClause: S,
        },
    },
}; // doctrine nominations — generalizable lessons only

// Required-but-empty arrays are attestations: forced deltas/deferred/indexRows make "record the cross-file backlog"
// structurally checkable, never wishful prose. `collapsed` carries the shape/entry-count delta this pass exists to move.
const PASS_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'verdict', 'collapsed', 'summary', 'deltas', 'deferred', 'indexRows', 'harvest'],
    properties: {
        files: { type: 'array', items: S },
        verdict: { type: 'string', enum: ['rebuilt', 'refined', 'clean'] },
        collapsed: S,
        summary: S,
        deltas: DELTAS,
        deferred: DEFERRED,
        indexRows: INDEXROWS,
        harvest: HARVEST,
    },
};

const CLOSER_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'indexApplied', 'drained', 'rejected', 'remaining', 'harvest', 'summary'],
    properties: {
        files: { type: 'array', items: S },
        indexApplied: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['doc', 'action'], properties: { doc: S, action: S } },
        },
        drained: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['claim', 'action'], properties: { claim: S, action: S } },
        },
        rejected: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['claim', 'reason'], properties: { claim: S, reason: S } },
        },
        remaining: DEFERRED, // rows verified still-open and genuinely blocked
        harvest: HARVEST,
        summary: S,
    },
};

// --- [DOCTRINE] ------------------------------------------------------------------------

const LANG = {
    // LANG carries routing data and engine-parameter rows ONLY — doctrine content is reached through READ_FIRST at the source, never paraphrased here.
    cs: {
        key: 'cs',
        name: 'C#',
        root: 'libs/csharp',
        stack: 'docs/stacks/csharp',
        atlas: [
            'README.md',
            'language.md',
            'shapes.md',
            'surfaces-and-dispatch.md',
            'rails-and-effects.md',
            'boundaries.md',
            'algorithms.md',
            'system-apis.md',
        ],
        casing: 'PascalCase',
        corpus: 'libs/csharp planning corpus (markdown specs of intended C# package designs)',
        strata:
            '`libs/.planning/ARCHITECTURE.md` owns the strata law (KERNEL -> AEC-DOMAIN -> APP-PLATFORM -> HOST-BOUNDARY -> APP; ' +
            'depend strictly upward; a host-neutral owner only where a non-Rhino runtime consumes the contract).',
        stackFloor:
            'docs/stacks/csharp is the FLOOR, never the ceiling — every fence pushes past it to the strongest form the doctrine ' +
            'admits; the tools/cs-analyzer gate enforces it (a true positive is architecture pressure, a false positive rule ' +
            'pressure, never a suppression).',
        apiTiers:
            'the SHARED substrate catalogs `libs/csharp/.api/*.md` (Thinktecture generated owners, LanguageExt ' +
            'rails/effects/schedules/immutable collections, QuikGraph, Mapperly and siblings) AND the folder catalogs ' +
            '`<package>/.api/*.md` — the universal Thinktecture/LanguageExt rails layered onto the domain packages, never the folder set alone.',
        verify:
            '`UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api` (assay blocked: the `.api` catalogs, ' +
            'the nuget MCP for feed truth, and Context7/exa/tavily for the official surface own the fallback)',
        vocab: '(`[Union]`/`[SmartEnum<TKey>]`/`[ValueObject]`/`Fold`/the rails)',
        slur: 'naive, surface-level code dressed in the right vocabulary',
        illusion: 'a `.api`/host member cited but never verified',
        docBloat: 'XML-doc',
        collapseInto:
            'ONE `[Union]` / `[SmartEnum<TKey>]` / `[ValueObject<T>]` / `[ComplexValueObject]` / source-generated case ' + 'family IN THE SAME FILE',
        gapPkg:
            'LIBRARY_DEPTH: an IFC schema gives a zone quantities, space boundaries, and properties the page never reads — ' +
            'stacking that full surface IS new functionality woven into the owner, not a denser spelling of the same call',
        gapDomain:
            'a BIM zone owns boundary/area/volume, per-kind attributes (a fire compartment a rating, a thermal zone a setpoint, ' +
            'a load group its combinations, an MEP system its medium/flow/pressure), adjacency/nesting topology, and ' +
            'coverage/aggregation/spatial-query operations, never a flat member-id set; a profile owns section properties, grade, ' +
            'fabrication + code-check inputs, not width/height; a durable store owns constraints, indexes, partitions, RLS, ' +
            'migration, and lifecycle, not naive columns',
        ownerGrammar:
            'a CASE in the existing closed family, a ROW or richer data on the existing smart-enum, a FIELD or a composed ' +
            '`[ValueObject]`/`[ComplexValueObject]` on the existing record, an OPERATION on the existing surface, or a POLICY_VALUE on the existing vocabulary',
        deepPkgs: 'LanguageExt/Thinktecture/MathNet/CSparse',
        body:
            'nested `Bind`/`Map` lambda towers where LINQ query syntax or one composed `Eff`/`Fin` pipeline reads flat; ' +
            '`Match(_ => unit)` and swallowed `IfFail` where a typed failure case belongs; manual loop/accumulator plumbing where ' +
            '`Fold`/`Traverse`/`Sequence`/`Partition` compose the join; helper statics and one-off records orbiting an owner',
        exhaust: 'total generated `Switch`, no silent `_` arm',
        modern: 'Latest modern C# 14 on net10',
        mechanics: '',
        fileOrg: 'apply the `docs/stacks/csharp` file-organization + section-order law',
    },
    py: {
        key: 'py',
        name: 'Python',
        root: 'libs/python',
        stack: 'docs/stacks/python',
        atlas: [
            'README.md',
            'language.md',
            'shapes.md',
            'surfaces-and-dispatch.md',
            'iteration.md',
            'rails-and-effects.md',
            'concurrency.md',
            'boundaries.md',
            'algorithms.md',
            'system-apis.md',
            'runtime.md',
        ],
        casing: 'snake_case',
        corpus: 'libs/python planning corpus (markdown specs of intended Python module designs)',
        strata: '`libs/.planning/ARCHITECTURE.md` owns the branch topology law.',
        stackFloor:
            'docs/stacks/python is the bar and docs/stacks/csharp the density/ambition FLOOR — match its richness, never import C#-shaped idioms.',
        apiTiers:
            'the SHARED/universal branch catalogs `libs/python/.api/*.md` (anyio, expression, msgspec, pydantic, ' +
            'pydantic-settings, beartype, structlog, stamina, numpy, psutil, opentelemetry-*) AND the folder catalogs ' +
            '`<package>/.api/*.md` — the shared rails layered ON TOP OF the folder domain packages, never the folder set alone.',
        verify:
            '`UV_CACHE_DIR=.cache/uv uv run --frozen python -m tools.assay api resolve <pkg>` (a gated/uninstalled ' +
            'package or a blocked assay falls back to its catalog/official surface)',
        vocab: '(`@tagged_union`/`frozendict`/`Result`/`Option`/the rails)',
        slur: 'naive, surface-level, old-style Python dressed in the right vocabulary',
        illusion: 'a `.api` member cited but never verified',
        docBloat: 'docstring',
        collapseInto: 'one closed `@tagged_union`/`Literal`/`StrEnum` family, a derived `frozendict` table, or a fold IN THE SAME FILE',
        gapPkg: 'BOTH tiers; stacking that full surface IS new functionality woven into the owner, not a denser spelling of the same call',
        gapDomain:
            'a dimension owner owns the full ISO 129-1 linear/aligned/angular/radial/diameter/ordinate/chain/baseline + ' +
            'tolerance family, not a single linear case; a layer codec owns the full ISO 13567 + NCS discipline/major/minor/status structure, not a flat string',
        ownerGrammar:
            'a CASE in the existing closed `@tagged_union`/`Literal`/`StrEnum` family, a ROW or richer data on the ' +
            'existing `frozendict` table, a FIELD on the existing `msgspec.Struct`/Pydantic model/frozen dataclass/`TypedDict`, an ' +
            'OPERATION on the existing surface, or a POLICY_VALUE on the existing vocabulary',
        deepPkgs: 'the admitted both-tier catalogs (expression/msgspec/pydantic/anyio + the folder domain packages)',
        body:
            'nested try/except and if-ladders where the `expression` Result/Option pipeline or one `match` expression reads ' +
            'flat; bare `except` and silently discarded `Result` where a typed failure case belongs; manual loop/accumulator ' +
            'plumbing where fold/traverse/partition combinators compose the join; module-level helpers and one-off aliases orbiting an owner',
        exhaust: 'total `match` + `assert_never` over the FULL case set',
        modern: 'py3.15-modern only',
        mechanics:
            'MECHANICAL EXECUTABILITY — a fence is a signature-and-implementation contract: mentally compile and type-check each ' +
            'against the real cross-page owners it imports, then hunt these defect classes at their owning doctrine sites and fix ' +
            'each by growing the existing owner: FENCE-PARSES (`language.md` CLOSED_MATCH_SITE) · MODEL-COHERENCE (README ' +
            'CORPUS_LAW) · TOTAL-DISPATCH (`shapes.md` families) · SINGLE-FACT-EVIDENCE (`rails-and-effects.md` STATE_RECEIPTS + ' +
            '`boundaries.md` BYTE_IDENTITY) · LOOP-OFFLOAD (`concurrency.md` OFFLOAD_LANE) · HANDLE-LIFETIME + BINARY-KERNEL ' +
            '(`boundaries.md` CAPSULE_OWNER) · IDENTITY-REGIME (`boundaries.md` MEMO_KEY) · TEMPLATE-SAFETY (`language.md` ' +
            'TEMPLATE_STRUCTURE_SITE) · STREAM-OVER-MATERIALIZE (`iteration.md` LAZY_COMBINATORS) · NO-EXCEPTION-HOTLOOP ' +
            '(`rails-and-effects.md` EXPRESSION_SPINE) · DERIVED-NOT-PARALLEL + PER-MODE PAYLOADS (README DERIVED_LOGIC). The ' +
            'defect definitions live at the sites; read them there.',
        fileOrg: 'apply the `docs/stacks/python` file-organization + section-order law',
    },
    ts: {
        key: 'ts',
        name: 'TypeScript',
        root: 'libs/typescript',
        stack: 'docs/stacks/typescript',
        atlas: [
            'README.md',
            'language.md',
            'derivation.md',
            'values.md',
            'computation.md',
            'shapes.md',
            'surfaces-and-dispatch.md',
            'rails-and-effects.md',
            'services-and-layers.md',
            'concurrency.md',
            'streams.md',
            'boundaries.md',
        ],
        casing: 'camelCase',
        corpus: 'libs/typescript planning corpus (markdown specs of intended TypeScript module designs)',
        strata: '`libs/.planning/ARCHITECTURE.md` owns the branch topology law.',
        stackFloor: 'docs/stacks/typescript composed in full is the bar — author ultra-advanced TS only, discarding naive idioms wholesale.',
        apiTiers:
            'the SHARED/universal `libs/typescript/.api/*.md` Effect substrate rails AND the folder catalogs ' +
            '`<folder>/.api/*.md`, cross-checked against the published node_modules types — the shared Effect ecosystem layered ' +
            'ON TOP OF the area packages, never the folder set alone.',
        verify:
            'the published types in node_modules (`UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api` over node_modules ' +
            'declarations where a member is novel)',
        vocab: '(`Schema.Class`/`TaggedClass` families, tagged unions, `Effect`/`Layer`, value-derived vocabulary tables)',
        slur: 'naive JavaScript-in-TypeScript dressed in the right vocabulary',
        illusion: '`any`/unsafe `as`/non-null `!` smuggled under a confident surface; a member cited but unverifiable against node_modules',
        docBloat: 'TSDoc',
        collapseInto:
            'ONE deep `Schema.Class`/`TaggedClass`/`TaggedError` family — embedded sub-schemas, brand-in-field ' +
            'refinements, class-carried methods and statics — or ONE tagged discriminated union + exhaustive match, IN THE SAME ' +
            'FILE; CLASS-FIRST: a module-level type alias, interface, or bare `Struct` standing where a class family could carry ' +
            'invariants, statics, and derived projections is a defect, and `Schema.Struct` survives only as an anonymous single-consumer field block',
        gapPkg:
            'BOTH tiers: the shared `libs/typescript/.api/` Effect substrate rails AND the folder domain packages, cross-checked ' +
            'against node_modules; stacking that full surface IS new functionality woven into the owner, not naive Promise/try-catch glue',
        gapDomain:
            'a chart owns scale/axis/series/interaction/annotation families and zoom/brush/tooltip/series-key operations, not ' +
            'two naive renders; a service owns retry/breaker/telemetry/validation/cache layers internally, not a bare fetch; a ' +
            'machine owns hierarchical/parallel regions, guarded transitions, timers, and history as data, not a switch ladder; ' +
            'a projection owns the full transform/diff/patch family the domain needs',
        ownerGrammar:
            'a CASE in the existing tagged discriminated union, a FIELD or embedded sub-schema on the existing ' +
            '`Schema.Class` family, an OVERLOAD or `Function.dual` twin on the existing entrypoint, a STATIC or derived ' +
            'projection on the existing class, a member on the existing `Effect.Service`, a ROW in the existing ' +
            'const-union/table, or a POLICY value on the existing vocabulary',
        deepPkgs:
            'the Effect ecosystem (`Effect`/`Layer`/`Context`/`Schema`/`Stream` + platform/experimental/cluster/workflow/sql/rpc/ai) + the area packages',
        body:
            'nested `Effect.flatMap(Effect.flatMap(...))` and pipe-inside-pipe pyramids where `Effect.gen`/`Do`/one flat pipe ' +
            'owns the sequence; `catchAll(() => Effect.void)` blanket swallows where typed `catchTag`/`catchTags` or a ruled ' +
            'ignore belongs; `flatMap` where `map` serves, manual fold/partition plumbing where ' +
            '`zipWith`/`all`/`validate`/`partition` compose the join, run-and-discard where `tap`/`tapError`/`tapBoth` belongs, ' +
            'sequential steps where `zip`/`all` with concurrency expresses the parallel join; loose module-level consts, ' +
            'aliases, and option-bags orbiting an owner instead of integrating as statics, fields, or derived projections',
        exhaust: 'exhaustive `Match.exhaustive` dispatch (or a checked `never` sink)',
        modern: 'ultra-advanced modern TS only',
        mechanics: '',
        fileOrg: 'apply the `docs/stacks/typescript` file-organization + section-order law',
    },
};

// --- [OPERATIONS] ----------------------------------------------------------------------

// Agent-level slot scheduler: CAP agents in flight across ALL batch chains, work-conserving backfill the moment a slot frees.
const makeSlots = (cap) => {
    let active = 0;
    const waiters = [];
    return async (fn) => {
        if (active >= cap) await new Promise((res) => waiters.push(res));
        active++;
        try {
            return await fn();
        } finally {
            active--;
            const next = waiters.shift();
            if (next) next();
        }
    };
};
const slot = makeSlots(CAP);
const wopts = (label, phase, model, schema, over) => Object.assign({ label, phase, model, effort: 'high', schema }, over);
const ropts = (label, phase, schema, scope, hl, over) => Object.assign({ label, phase, schema, scope, hl }, over);

const fileTag = (label) => label.replace(/[^A-Za-z0-9_.-]+/g, '-');
// Read/write discipline, split from the output contract so BOTH dispatch paths carry it: a natively executed lane needs
// the same territory bound, budget, and verification duty as a dispatched one, and inlining it only in the codex prompt
// left every native lane running unbounded.
const laneDiscipline = (o) =>
    o.fix
        ? '<persistence>\nComplete every named move before yielding; do not stop at analysis or a partial edit. If the chosen ' +
          'approach resists, pick the next-best one and proceed. Return without an applied edit only if the territory genuinely ' +
          'admits none.\n</persistence>\n\n<work_cadence>\nRead the stable law corpus once, first; then work ITEM BY ITEM — ' +
          "derive one item's findings, land its edits, advance. Edits land as derived and never pool toward the end: a batch " +
          'fully materialized before its first edit forfeits its earliest findings to context compaction.\nA [rebuild] page ' +
          'lands SECTION BY SECTION, one write per top-level section, each section composed whole before it is written — ' +
          'never a hunk-crawl of twenty micro-patches against one page. Your own written text is authoritative: never ' +
          're-open a span you authored this turn to re-locate an anchor, and never re-read a page mid-rebuild.\n</work_cadence>' +
          '\n\n<read_discipline>\nA stable input — a doctrine page, dossier, census, catalog, charter — is read ONCE: extract ' +
          'what you need into your plan notes and re-open only the exact line span behind an edit, never the whole file again. ' +
          'Read in large windows (400+ lines per command), never 200-line paging. Your context compacts on a long lane; only ' +
          'plan notes, the seam ledger, and landed edits survive it — a fact left only in context is lost. Budget: at most ' +
          (o.calls || 300) +
          ' tool calls total; at the budget, land what is derived and record every remaining row in the product `deferred` ' +
          'field — an honest remainder beats a thrashing overrun.\n</read_discipline>' +
          '\n\n<verification>\nOnce a page takes its LAST edit, re-read it ONCE end to end and confirm it is coherent ' +
          'and nothing it carried was lost — one verification pass per page, never between edits. Fix what fails ' +
          'before yielding. Verification is READING: the corpus is markdown ' +
          'design pages — never compile, build, run analyzers, or execute test gates against it; member truth rides the ' +
          'task-named catalog/assay rail only.\n</verification>'
        : '<context_gathering>\nTerritory: the exact files and directories the task names. Do not open files outside it; ' +
          'instruction files (.claude/, CLAUDE.md, AGENTS.md) and skill bundles are always out of scope for a read/review ' +
          'lane, and discovery commands stay scoped to the territory — never `rg --files` or `tree` from the repo root.' +
          '\nBudget: at most ' +
          (o.calls || 60) +
          ' tool calls total. Read in small batches (a handful of files per command, line-capped); never concatenate the whole ' +
          'territory into one command - tool output truncates and the data is lost.\nStop as soon as the product is complete. ' +
          'If something is still uncertain at the budget, proceed and record the residue in the product gap/unverified field ' +
          'instead of re-reading.\n</context_gathering>\n\n<verification>\nBefore the final message, confirm every cited ' +
          'spelling appears verbatim in the cited file; anything unconfirmed is recorded as a gap, never asserted.\n' +
          '</verification>';
const laneLaw = (schema, o) =>
    laneDiscipline(o) +
    '\n\n<output_contract>\nYour final message is a single JSON object with exactly this shape: ' +
    JSON.stringify(schema) +
    '\n- JSON only: no prose before or after it, no code fences, no markdown.\n- Every key shown is required.\n' +
    '- Use null for a value you could not determine and [] for an empty list; never guess.\n</output_contract>';
// Sandbox decides authorship: a read-only delegate cannot write, so --out materializes the product; a writing delegate lands its own.
const LANE_SCRIPT = ROOT_DIR + '/.claude/skills/codex/scripts/codex-lane.sh';
const flagsOf = (o) =>
    [o.model && '--model ' + o.model, o.codexEffort && '--effort ' + o.codexEffort, o.web && '--web']
        .filter(Boolean)
        .map((f) => ' ' + f)
        .join('');
const codexPrompt = (label, task, schema, o) => {
    const base = SCRATCH + '/' + fileTag(label);
    const root = ROOT_DIR;
    const report = root + '/' + base + '-report.json';
    const lane = report + '.lane';
    const authored = !!o.writes;
    const sandbox = authored ? 'workspace-write' : 'read-only';
    const taskFull =
        task +
        (authored
            ? '\n\nREPORT FILE (final act): before returning your final message, write that COMPLETE final-message JSON verbatim to ' +
              report +
              ' yourself.'
            : '');
    // Stale purge BEFORE the lane: SCRATCH derives from targets alone, so a prior run over the same targets left its report here.
    // A lane that dies without writing leaves that file in place, the probe passes it, and a dead run's product is consumed as this
    // run's — the one failure this whole receipt path cannot otherwise detect.
    return (
        'DISPATCH ROLE: a delegate performs the complete TASK below through one supervised lane run; never perform, edit, judge, soften, ' +
        'summarize, or relay the work yourself. (1) Write the LANE LAW block below VERBATIM to ' +
        lane +
        '/law.md and the TASK block below VERBATIM to ' +
        lane +
        '/task.md, composing neither, then delete any leftover report with one Bash call: rm -f ' +
        report +
        " — a stale file from a prior run over these targets otherwise passes the verify probe as this run's product. " +
        '(2) Run ONE Bash call with run_in_background true: ' +
        LANE_SCRIPT +
        ' --task ' +
        lane +
        '/task.md --law ' +
        lane +
        '/law.md --dir ' +
        lane +
        ' --cwd ' +
        root +
        ' --sandbox ' +
        sandbox +
        flagsOf(o) +
        (authored ? '' : ' --out ' + report) +
        '; the harness re-invokes you when the lane exits — Read ' +
        lane +
        '/receipt.json then, never a polling loop. Recovery is two-branch and ONCE-only — the whole budget: a receipt reason "crash" ' +
        'alone (the session persisted on disk) overwrites the task file with "continue and complete the lane, then land the receipt" and ' +
        're-runs the same command plus --resume <the receipt thread_id>; any other failed receipt (max-timeout, turn-failed, ' +
        'refusal) re-runs the same command untouched. (3) ' +
        (authored
            ? 'The delegate lands the product itself at ' + report + ' as its final act.'
            : 'The lane lands the product at ' + report + ' via --out.') +
        " (4) Verify with one Bash call: jq -e '." +
        o.hl.arr +
        "' " +
        report +
        ' >/dev/null — probe that contract key, never bare parseability, which any wrong-shaped JSON passes; on a miss re-derive the ' +
        'product once from the lane events.jsonl (jq -rs to the last agent_message item text, Write that), re-probe, and a second miss ' +
        'returns ok=false with the probe output. (5) Return ok=true, report=' +
        base +
        '-report.json, entries = the length of the "' +
        o.hl.arr +
        '" array in the product, headline="<entries> ' +
        o.hl.arr +
        (o.hl.group ? ' | <' + o.hl.group + ' tallies>' : '') +
        ' | top: <most frequent first file or none>", and failure empty. On a failed receipt return ok=false, entries=0, report and ' +
        'headline empty, and failure equal to the receipt reason and failure text VERBATIM.\n\nLANE LAW:\n\n' +
        laneLaw(schema, o) +
        '\n\nTASK:\n\n' +
        taskFull
    );
};

// QUOTA FALLBACK: a codex receipt whose failure matches usage/quota/limit re-dispatches the SAME task natively at the role's native twin (twinOf owns
// the mapping) — the caller owns the re-dispatch, the wrapper never executes work itself. The roster row carries `scope` from the
// ORCHESTRATOR (never the lane's self-report) so a failed lane's unmapped territory is exact even when the lane died before writing anything.
const twinOf = (m) => (/-luna/.test(m || '') ? 'sonnet' : 'opus');
const nativeLane = (task, o) => {
    const report = SCRATCH + '/' + fileTag(o.label) + '-report.json';
    return agent(
        laneDiscipline(o) +
            '\n\n' +
            task +
            '\n\nPRODUCT TO DISK: write your COMPLETE product as one JSON file matching this schema at ' +
            (ROOT_DIR + '/' + report) +
            ' (Write tool, exactly this absolute path): ' +
            JSON.stringify(o.schema) +
            ' — then return ONLY the receipt: ok, report = ' +
            report +
            ' (this repo-relative form, matching codex-lane receipts), entries count, one-line mechanical headline, failure empty.',
        { label: o.label, phase: o.phase, model: o.nativeModel || twinOf(o.model), effort: 'high', schema: RECEIPT },
    );
};

const recon = (taskOf, o) => {
    const task = typeof taskOf === 'function' ? taskOf : () => taskOf;
    const wrapper = {
        label: (o.model && o.model.indexOf('-terra') >= 0 ? 'terra:' : 'sol:') + o.label,
        phase: o.phase,
        model: 'sonnet',
        effort: 'low',
        schema: RECEIPT,
    };
    // `native` runs the lane on the estate model directly — no dispatch wrapper or transport hop; the executing agent IS the
    // reader. Chosen per lane by product weight: an artifact every downstream writer reads in full, or a judgment the run
    // never re-derives, earns the stronger reader; navigation legwork stays dispatched. Receipt shape is identical either way.
    return (o.native ? nativeLane(task('claude'), o) : agent(codexPrompt(o.label, task('codex'), o.schema, o), wrapper))
        .then((r) => (r && !r.ok && !o.native && /usage|quota|limit/i.test(r.failure || '') ? nativeLane(task('claude'), o) : r))
        .then((r) => ({
            lane: o.label,
            scope: o.scope || [],
            ok: !!(r && r.ok && r.report),
            report: (r && r.report) || '',
            entries: (r && r.entries) || 0,
            headline: (r && r.headline) || '',
            failure: (r && r.failure) || (r ? '' : 'lane died'),
        }));
};

const chunk = (arr, n) => {
    const o = [];
    for (let i = 0; i < arr.length; i += n) o.push(arr.slice(i, i + n));
    return o;
};
const pkgOf = (p) => p.split('/.planning/')[0]; // package = the index-doc owner and the mapper-fan partition key
const Lof = (pkg) => LANG[langOf(pkg)] || LANG.cs;
const pkgTag = (pkg) => (langOf(pkg) || 'x') + '.' + pkg.split('/').pop();
// LOC-balanced fill: a mapper set holds page tonnage, never page count — one 3000-line page is its own set.
const locChunk = (rows, cap) => {
    const out = [];
    let cur = [];
    let acc = 0;
    for (const r of rows) {
        if (cur.length && acc + r.lines > cap) {
            out.push(cur);
            cur = [];
            acc = 0;
        }
        cur.push(r);
        acc += r.lines;
    }
    if (cur.length) out.push(cur);
    return out;
};

// --- [SHARED_BLOCKS]

const ROOT_LAW =
    'WORKING ROOT: ' +
    ROOT_DIR +
    ' — every relative repo path in this brief resolves against this absolute root; read, write, and edit ONLY under it, never ' +
    'another checkout of the repository. SEARCH FLAGS: `rg` recurses by default, and `-r` is its REPLACE flag — `rg -rn <pat> <dir>` ' +
    'parses as replacement `n` and prints `n` for every match, so a garbled result is your own flag error and NEVER evidence of ' +
    'absence; a search returning nothing re-runs in its correct form before any conclusion rests on the emptiness.';
const CONTEXT = (L) => ROOT_LAW + '\n\nRasm monorepo — ' + L.corpus + '. ' + L.strata + ' ' + L.stackFloor;

// Register table — one row set per EXECUTING model, keyed by recon()'s dispatch branch. Substance is identical across rows (burden of proof on the
// work, both naivety axes, illusion hunting, no-churn, second-pass self-verify, findings-never-designs); only phrasing forks: claude carries the
// estate hostile register, codex the same demands de-conflicted and neutral — probe-measured: the hostile register makes a codex lane over-read,
// probe out of territory, and spend more input tokens for equal output (the codex skill's prompt-contract law). Register-neutral rows (selfCheck,
// antiAnchor) live once as shared constants — a forked copy is a drift bill with no probe evidence behind it.
const SELF_CHECK =
    'SELF-VERIFY (second pass, before returning): re-derive every entry from disk — re-open each cited anchor and confirm it ' +
    'states what the entry claims, re-verify each member spelling against its catalog, trace each seam to both endpoints. ' +
    'Correct or delete any entry that fails re-confirmation; never return a guess, an assumption, a skimmed summary, or a ' +
    'vague/hedged entry. Completeness is part of correctness: after the re-read, hunt once more for what the first pass missed ' +
    '— an omitted load-bearing fact is as wrong as a false one.';
const ANTI_ANCHOR = (L) =>
    'ANTI-ANCHOR LAW: your report and dossier carry FINDINGS, never designs — quality defects graded against the doctrine read at source (name the law and the ' +
    L.stack +
    ' pattern whose application would most deeply transform the page — the collapse, the owner form, the rail — never the ' +
    'resulting code) and capability inventory in catalog-anchored spellings; a fence sketch, a prescribed shape, or a pre-ruled ' +
    'design ANCHORS and WEAKENS the rebuild and is a defect — the implement agent rules every design.';
const REG = {
    claude: {
        stance: (L) =>
            'STANCE — every pass is hostile: author, critique, and red-team alike. The pages were authored by ANOTHER engineer ' +
            'and are under adversarial review; hold every fence naive, shallow, or illusory until it survives a real attack — ' +
            'the burden of proof is on the code, never on you. "Mature", "already strong", "good enough", and a prior clean ' +
            'verdict are rejected self-assessments — most of this corpus is ' +
            L.slur +
            '. Dense, confident, package-fluent code is the PRIME suspect for hollowness: disbelieve every claim a fence makes ' +
            'about itself and verify it against the real domain and the catalogued package surface. NAIVETY is a defect on two ' +
            'orthogonal axes: COVERAGE — the owner models a thin slice of its concept (a 2-case family for a 20-case domain, ' +
            'three fields where the concept carries fifteen); APPROACH — an enumerated roster where one parameterized generator ' +
            'should GENERATE the space (the roster demotes to seed DATA over named parameters). ILLUSORY code is the primary target: doctrine vocabulary ' +
            L.vocab +
            ', cited packages, confident prose, hollow body — a phantom (' +
            L.illusion +
            '), a name promising capability the body omits, decorative density carrying nothing, a stub dressed as a finished ' +
            'design. Every collapse-signal list in these prompts is a FLOOR, never the complete set. NO CHURN: an edit requires ' +
            'a named violated law or invariant and the concrete case that breaks it — no reproduction, no edit; a clean verdict ' +
            'earned by an attack that finds nothing is a first-class result, proven by adding nothing.',
        selfCheck: SELF_CHECK,
        antiAnchor: ANTI_ANCHOR,
        ctx: (n) =>
            'TASK: HOSTILE READ-ONLY CONTEXT + SEAM LENS over these ' +
            n +
            ' pages — read-only is the only concession; the hunt is as adversarial as every writing pass (investigate, do NOT ' +
            'edit): ',
        api: (n) => 'TASK: HOSTILE READ-ONLY TWO-TIER STACKING LENS over these ' + n + ' pages (investigate, do NOT edit): ',
        apiVerify:
            'DISBELIEVE the pages — prose claiming a package is ' +
            'composed is verified against the fence body; attack every admitted catalog (both tiers) for the members, combinators, ' +
            'generated surfaces, and native pipelines the concept ADMITS but no fence exploits',
        bar: (n) => 'TASK: HOSTILE READ-ONLY DOCTRINE-BAR ATTACK over these ' + n + ' pages (investigate, do NOT edit): ',
        barAttack: (L) =>
            'attack its quality against the doctrine AT SOURCE — EXTREMELY adversarial: the page is presumed ' +
            L.slur +
            ' until proven otherwise. Hunt',
        finder: (i) => 'TASK: HOSTILE READ-ONLY FINDER, slice ' + i + ' (investigate, do NOT edit).',
        finderStance: 'The landed corpus is presumed defective until your attack finds nothing. ',
        gov: 'TASK: HOSTILE READ-ONLY GOVERNANCE FINDER (investigate, do NOT edit).',
        audit: 'TASK: HOSTILE DOCTRINAL-CONFORMANCE + CAPABILITY AUDIT; fix EACH page in place: ',
    },
    codex: {
        stance: (L) =>
            'REVIEW POSTURE — the pages are unverified work by another engineer: verify every claim a fence makes against the ' +
            'real domain and the catalogued package surface before accepting it; a prior clean verdict or confident prose is ' +
            'not evidence. NAIVETY is a defect on two orthogonal axes: COVERAGE — the owner models a thin slice of its concept ' +
            '(a 2-case family for a 20-case domain, three fields where the concept carries fifteen); APPROACH — an enumerated ' +
            'roster where one parameterized generator should GENERATE the space (the roster demotes to seed DATA over named ' +
            'parameters). ILLUSORY code is the primary target: doctrine vocabulary ' +
            L.vocab +
            ', cited packages, confident prose, hollow body — a phantom (' +
            L.illusion +
            '), a name promising capability the body omits, a stub dressed as a finished design. Every collapse-signal list in ' +
            'these prompts is a floor, never the complete set. NO CHURN: an edit requires a named violated law or invariant and ' +
            'the concrete case that breaks it; a clean verdict from a check that finds nothing is a first-class result.',
        selfCheck: SELF_CHECK,
        antiAnchor: ANTI_ANCHOR,
        ctx: (n) => 'TASK: read-only CONTEXT + SEAM LENS over these ' + n + ' pages (investigate, do NOT edit): ',
        api: (n) => 'TASK: read-only TWO-TIER STACKING LENS over these ' + n + ' pages (investigate, do NOT edit): ',
        apiVerify:
            'verify prose claiming a package is composed against the fence body — never accept the ' +
            'claim; check every admitted catalog (both tiers) for the members, combinators, generated surfaces, and native ' +
            'pipelines the concept ADMITS but no fence exploits',
        bar: (n) => 'TASK: read-only DOCTRINE-BAR review over these ' + n + ' pages (investigate, do NOT edit): ',
        barAttack: () => 'assess its quality against the doctrine AT SOURCE — treat the page as unproven until verified. Report',
        finder: (i) => 'TASK: read-only FINDER, slice ' + i + ' (investigate, do NOT edit).',
        finderStance: 'Verify the landed corpus independently; treat what the run reports about itself as unproven. ',
        gov: 'TASK: read-only GOVERNANCE FINDER (investigate, do NOT edit).',
        audit: 'TASK: DOCTRINAL-CONFORMANCE + CAPABILITY AUDIT; fix EACH page in place: ',
    },
};
const BODY = (L) =>
    'FENCE-BODY LAW — the interior of every fence is judged at the same bar as its shapes; a correct owner ' +
    'carrying a naive body is a defect. Rebuilt on sight: ' +
    L.body +
    '. The optimal body is dense, flat, ' +
    'expression-shaped, and reads as one algebra — the admitted combinator surface is the material, never hand-rolled ' +
    'control flow, nesting, or extraction to loose helpers.';

const VERIFY = (L) =>
    'VERIFY — cite only members confirmed via ' +
    L.verify +
    '; a member you cannot verify is a phantom to delete, and a page-attested member that VERIFIES but has no catalog row ' +
    'lands as an appended row in the owning `.api` catalog in the same pass — the catalog is the estate verification surface, ' +
    'and a page-only attestation re-litigates the same member every future run. Mine BOTH .api tiers to operator depth: ' +
    L.apiTiers +
    ' An admitted capability the concept admits that no owner exploits is a defect to close.';
// Polymorphic on input shape: one language row for a package-scoped lane, an array of language keys for the cross-package
// terminals — only the doc-bloat term forks, so the law itself is authored once.
const PROSE_COMMENTS = (L) =>
    'PROSE + COMMENTS — apply docs/standards/style-guide.md, information-structure.md, and formatting.md; these pages and this ' +
    'block are the COMPLETE prose law for this lane. Your project instructions (AGENTS.md/CLAUDE.md) route durable markdown to ' +
    'the `docgen` skill — that route serves interactive agents and does NOT apply here: never read, load, or open the docgen ' +
    'bundle from any root. The page is a design ' +
    'spec: lead each section with the controlling contract, one idea per paragraph, close on the consequence; no provenance, ' +
    'narration, freshness disclaimers, or hedges. Backtick every symbol, type, field, function, operator, package ID, path, ' +
    'command, flag, and literal; name the exact member over paraphrased behavior; trimming never reduces technical density. ' +
    'Fences comment for the next agent only: keep the canonical section-divider headers; beyond them zero comments, 1-2 lines ' +
    'only for a truly subtle invariant or boundary; no restating the code, no ' +
    (Array.isArray(L) ? L.map((k) => LANG[k].docBloat).join('/') : L.docBloat) +
    ' bloat.';

// Territory bound for the terminal writers: they carry no READ LAW block of their own, so without this a lane editing
// markdown design pages with no stated prose register goes and loads one — the docgen bundle, measured at four files
// before a repair landed. Instruction files and skill bundles are never inputs to a corpus writer under any root.
const SCOPE_BOUND =
    'OUT OF SCOPE: instruction files (CLAUDE.md, AGENTS.md, `.claude/` config), skill bundles under ANY root ' +
    '(`.claude/skills/`, `~/.codex/skills/` — the PROSE block above is the complete register law for this lane, and the ' +
    'docgen bundle is never opened), and the repo-root README. Discovery stays inside the territory this brief names — ' +
    'never `rg --files` or `tree` from the repo root, and a name this brief states is never searched for on disk.';
const INFO_LAW =
    'You provide INFORMATION, never prescriptions: exact disk anchors, the current shape at each site, seam endpoints both ' +
    'sides, verified member spellings, gaps. The implement agent decides how to build; an entry that says what to write ' +
    'instead of what is true is a defect. ENTRY FORM: prose fields carry fact; `anchors` carry one coordinate per row (role ' +
    'names what it proves; `note` is the shortest literal witness under 20 words, or empty when path+line suffice; an ' +
    '`absence` anchor names where the expected thing was searched and not found); `files` lists what the consumer must open. ' +
    'An underutilized-capability entry is INVENTORY: verified members, usage anchors, the admitting concept — composition is ' +
    "the implement agent's call. COVERAGE is part of the product: `requested` = assigned scope, `read` = actually full-read, " +
    '`skipped`/`unverified` = not reached — an honest skip beats a silent one.';
const HARVEST_LAW =
    'HARVEST (required key, usually empty): nominate ONLY findings that generalize beyond this batch — a collapse pattern ' +
    'reusable across folders, a naivety class no doctrine clause names, a review rule that catches the defect BEFORE review, a ' +
    'hard-won cross-surface coupling. Each row: altitude (stacks|reviewer|constitution|planning|readme|laws), lang, claim (the ' +
    'generalized law, one sentence), anchors (file:line evidence), existingClause (the exact clause it hardens, quoted with its ' +
    'path — or "absent" with the surfaces searched). A batch-local fix never nominates; an empty array is the normal verdict — ' +
    'the doctrine lander refutes weak rows, so nominate substance, never volume.';
const BAR_LINES = (langs) =>
    'Rasm monorepo — the libs/ planning corpora. Per-language doctrine bars:\n' +
    langs
        .map(
            (k) =>
                '- ' +
                LANG[k].name +
                ': ' +
                LANG[k].stack +
                '/ read at source; ' +
                LANG[k].modern +
                '; ' +
                LANG[k].fileOrg +
                '; verify members via ' +
                LANG[k].verify +
                '.',
        )
        .join('\n');
const CATALOG_APPEND =
    'CATALOG-APPEND LAW — a page-attested member that verifies against the real surface but lacks a row in the owning ' +
    '`.api` catalog closes by appending the catalog row; stripping a TRUE page attestation to match a lagging catalog ' +
    'is the rejected form.';
const SOLO_LAW =
    'SOLO LAW — you work ALONE: every verification, edit, and fixlog row is yours; no delegation of any form. Order the ' +
    'drain by leverage — shared owners, registries, and index surfaces before consumers, cross-folder seams before ' +
    'local prose — and land each row fully (edit + both-end ripple + verification) before opening the next.';

// Prompt builders — each task states only its own action; shared checks are referenced by name.
const planPrompt = () =>
    [
        ROOT_LAW,
        'Rasm monorepo — the libs/{csharp,python,typescript} planning corpora (markdown design specs). Targets may mix ' +
            "languages; each page's owning package derives its own doctrine downstream.",
        'TASK: thin enumerate (read-only, do NOT edit). TARGETS (repo-relative): ' +
            JSON.stringify(TARGETS) +
            '. The OWNING PACKAGE of a page is the path before `/.planning/`. EXPAND with a real recursive listing per ' +
            'target — run find <target-or-its-.planning-tree> -name *.md; a design page lives INSIDE the .planning tree, so ' +
            'a package-root ls alone NEVER proves an empty page set. PAGES: expand each target — a ROOT to every design page ' +
            'under its planning tree, a SUB-FOLDER to every page under it, a FILE to itself; union + dedup; exclude ' +
            'IDEAS.md/TASKLOG.md/README.md/ARCHITECTURE.md. Each page row carries `lines` = its real line count (one `wc -l` ' +
            'sweep over the listing) — the engine packs mapper sets by tonnage, so a guessed count corrupts the packing. ' +
            'Return `packages` (one entry per owning package root) and `pages`. A mis-scoped or renamed target is reported ' +
            'in `unresolved`; a deliberately page-less target skips silently.',
        "SCRATCH HYGIENE (before returning): this run's scratch dir is `" +
            SCRATCH +
            '` — its name derives from the targets, so a prior run over the same targets left artifacts there. When the dir ' +
            'pre-exists, delete its stale maps: `rm -f ' +
            ROOT_DIR +
            '/' +
            SCRATCH +
            "/*-map.md` — a stale map from a dead run is read as this run's navigation by the fixer handed its path. Delete nothing else.",
        'TOOLCHAIN WARM-UP (before returning): run `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api --help` once — ' +
            "it builds the workspace uv cache every downstream lane's member-verification rail rides, so no lane pays the " +
            'cold-environment latency or misreads it as a broken rail.',
    ].join('\n\n');

const lawPackPath = (k) => SCRATCH + '/lawpack-' + k + '.md';
const lawPackPrompt = (L, pack) =>
    [
        ROOT_LAW,
        'TASK: AUDIT LAW PACK COMPILER for ' +
            L.name +
            ' — read-only over `' +
            L.stack +
            '/`; you WRITE exactly one file, the pack. Extract VERBATIM — never paraphrase, summarize, or annotate — each ' +
            'block under a `## [SOURCE: <path> <section-heading>]` header: the README [02]-[DOCTRINE] laws and the ' +
            '[03]-[COLLAPSE_SCAN] table; OWNER_CHOOSER (`shapes.md` [01]); RAIL_CHOOSER and the boundary-conversion law ' +
            '(`rails-and-effects.md` [01] and [02]); the aspect two-weave sections (`surfaces-and-dispatch.md` AND ' +
            '`rails-and-effects.md`); and the file-organization + section-order law. Locate each section, then extract with ' +
            'exact line-range reads — the pack is source text relocated, byte-true.',
        'WRITE the pack to `' + pack + '`. Return sections (one row per extracted block: source anchor + line count) and summary.',
    ].join('\n\n');
// Density phase prompts — the terminal per-file pass. The mapper is the fixers' ENTIRE navigation (each fixer reads only
// the law pack, its map, and its file), so mapper omissions are skipped fixes; the closer is the phase's only cross-file writer.
const densityMapPrompt = (L, pkg, set) =>
    [
        ROOT_LAW,
        CONTEXT(L),
        REG.claude.stance(L),
        INFO_LAW,
        REG.claude.selfCheck,
        REG.claude.antiAnchor(L),
        'TASK: DENSITY MAPPER for `' +
            pkg +
            '` — read-only over the corpus; you WRITE one map file per target page, nothing else. The rebuild landed; your ' +
            'maps arm the terminal per-file density fixers, each of which reads ONLY the audit law pack, its map, and its own ' +
            "file — your map is that fixer's entire navigation, so an omitted entry is a skipped fix and a wrong anchor a " +
            'wasted lane. TARGETS (page -> map path): ' +
            JSON.stringify(set.map((s) => ({ page: s.page, map: s.map }))),
        'GROUND FIRST, at source: `libs/.planning/ARCHITECTURE.md`; the branch `' +
            L.root +
            '/.planning/ARCHITECTURE.md` with its [02]-[SEAMS] ledger; the package ARCHITECTURE.md + README.md at `' +
            pkg +
            '`; then BOTH `.api` tiers (`' +
            L.root +
            '/.api/`, `' +
            pkg +
            '/.api/`) at the catalogs the target pages compose.',
        'PER PAGE, write its map with exactly these sections: (a) LOGIC_FLOW — every logic thread end to end (ingress -> ' +
            'transform -> egress) as fact, naming each thread that is partial, dead-ended, split across owners, duplicated, ' +
            'or a split-brain (one concept modeled twice in parallel shapes). (b) SHAPE_CENSUS — every type, object, shape, ' +
            'record, and public entry the page declares, each with its true discriminant: parallel shapes sharing an ' +
            'identity regime, admission path, payload timing, or consumer are COLLAPSE candidates (name the surviving owner ' +
            'and the discriminant that would justify survival); entry-point sprawl where one polymorphic entry could ' +
            'discriminate on input shape; knobs whose value reconstructs from the input or belongs as a policy value; ' +
            'single-caller helpers whose only consumer is one call site; enumerated rosters where a parameterized generator ' +
            'should generate the space. (c) STRATA_LEVERAGE — capability the page hand-rolls that a lower-stratum owner, ' +
            'sibling owner, or admitted package already carries: the owning member or page at its verified anchor, the ' +
            'hand-rolled span at its anchor, both ends named. (d) FLAT_CODE — fences below the admitted combinator surface (' +
            L.body +
            '), each with exact anchors and the doctrine law it fails. (e) API_DEPTH — both-tier catalog members the page ' +
            'concept admits that no fence exploits, exact spellings verified via ' +
            L.verify +
            '. (f) GROWTH_STRESS — where the next 10x of cases, fields, modalities, or consumers breaks the page: the owner ' +
            'whose next case costs a scattered edit instead of one row, the dispatch a new modality cannot enter, the ' +
            'surface that multiplies instead of absorbing. (g) DOCTRINE_ROUTE — ' +
            (L.key === 'cs' ? 'the exact `docs/stacks/csharp/domain/` shards this page touches (through `domain/README.md`), and ' : '') +
            'any doctrine section beyond the audit law pack the fixer must honor, named exactly; empty when the pack suffices. ' +
            'Information, never prescriptions: anchors, current shapes, discriminants, verified spellings — the fixer rules ' +
            'every design.',
        'Return ONLY the receipt: ok, report = the first map path (repo-relative), entries = pages mapped, a one-line ' + 'headline, failure empty.',
    ].join('\n\n');

const densityFixPrompt = (L, page, mapPath, pack, reg) =>
    [
        CONTEXT(L),
        REG[reg].stance(L),
        BODY(L),
        VERIFY(L),
        PROSE_COMMENTS(L),
        'READ LAW — four named inputs, nothing else. (1) DOCTRINE: ' +
            (pack
                ? 'the audit law pack `' +
                  pack +
                  '` IN FULL, in large windows, FIRST — it carries every binding checklist section verbatim with source anchors'
                : 'scoped at-source — `' +
                  L.stack +
                  '/README.md` [02]-[DOCTRINE] + [03]-[COLLAPSE_SCAN], OWNER_CHOOSER (`shapes.md` [01]), RAIL_CHOOSER ' +
                  '(`rails-and-effects.md` [01]), and the file-organization law') +
            '. (2) YOUR MAP: ' +
            (mapPath
                ? '`' +
                  mapPath +
                  '` IN FULL — sections (a) LOGIC_FLOW, (b) SHAPE_CENSUS, (c) STRATA_LEVERAGE, (d) FLAT_CODE, ' +
                  '(e) API_DEPTH, (f) GROWTH_STRESS, (g) DOCTRINE_ROUTE.'
                : 'absent — derive those seven dimensions yourself from the file and the package ARCHITECTURE.md.') +
            ' (3) YOUR FILE from CURRENT disk, IN FULL. (4) ONLY the exact anchors the map names — a strata counterpart ' +
            'span, a catalog member block, a DOCTRINE_ROUTE section. OUT OF SCOPE: everything else — no atlas crawl, no ' +
            'charter read, no instruction files, no discovery commands beyond the named paths.',
        'TASK: SINGLE-FILE DENSITY PASS on `' +
            page +
            '` — one pass, in place, ground-up where the attack finds bloat; this is your ONLY writable file. ' +
            '(a) SHAPE COLLAPSE — merge every parallel shape the SHAPE_CENSUS names into ' +
            L.collapseInto +
            ': the type/object/shape count goes DOWN with zero functionality loss; a shape survives only on a genuinely ' +
            'distinct discriminant (COLLAPSE_SCAN + OWNER_CHOOSER in the law pack rule the merge). ' +
            '(b) SURFACE REDUCTION — collapse entry-point sprawl into one polymorphic entry per modality discriminating on ' +
            'input shape; collapse each knob into a policy value or input-shape discriminant (KNOB_TEST); inline every ' +
            'single-caller helper into its caller where the extraction carries no reuse or boundary; demote every enumerated ' +
            'roster to seed DATA under one parameterized generator over named parameters. ' +
            '(c) BODY SOPHISTICATION — rebuild every flat-code hit into the admitted combinator surface per the law pack: ' +
            'dense, expression-shaped, algorithmically driven logic that reads as one algebra, never hand-rolled control ' +
            'flow. (d) STRATA COMPOSITION — replace hand-rolled capability with composition of the mapped lower-stratum or ' +
            'package owner: the call site collapses onto the owner and the hand-rolled span deletes; STACK the API_DEPTH ' +
            'members into existing owners where the fence plainly admits them. (e) THREADS — complete or collapse every ' +
            'partial, dead, duplicated, or split-brain logic thread the map names. (f) GROWTH — resolve every GROWTH_STRESS ' +
            'entry so the next 10x of cases, fields, modalities, and consumers lands as rows, cases, and policy values on ' +
            'existing owners, never as new surfaces beside them. (g) CAPABILITY CONSERVATION is absolute — never delete ' +
            'functionality, never extract to a new file; LOC and shape count fall only through stronger owners. ' +
            'The map is SIGNAL, not law: re-verify each entry against the file before acting, hunt past it within your ' +
            'file, and drop any entry disk already resolves. TERRITORY: edits land in `' +
            page +
            '` ONLY — every cross-file need (a seam counterpart end, a `.api` catalog append, an index or IDEAS row) is a ' +
            '`deferred` {files, claim} or `indexRows` row for the density closer, never an edit. Return the fix-log — ' +
            '`deltas` exact, `collapsed` naming the shape/entry-count delta, `verdict` clean when a full pass lands nothing. ' +
            HARVEST_LAW,
    ].join('\n\n');

const densityCloserPrompt = (langs, reports) =>
    [
        ROOT_LAW,
        BAR_LINES(langs),
        CATALOG_APPEND,
        SOLO_LAW,
        PROSE_COMMENTS(langs),
        SCOPE_BOUND,
        "TASK: DENSITY CLOSER (WRITER — the run's final agent). The per-file density fixers were single-file territories; " +
            'every cross-file need they met is a typed row in their fixlogs, ON DISK: ' +
            JSON.stringify(reports) +
            '. Read each IN FULL. (1) Drain every `deferred` row — re-verify on CURRENT disk, repair seam counterparts both ' +
            'ends, land catalog appends, fix at root; a row disk already resolves is culled with proof in `rejected`. ' +
            '(2) Apply every `indexRows` row to its owning doc exactly once — you are the sole index/IDEAS.md writer at this ' +
            'point; an IDEAS row lands as a fully-specified card, deduped against the cards already there. (3) Fold each ' +
            "fixlog's harvest rows into your `harvest` return, re-verified and deduped. Return the final fixlog — `remaining` " +
            'carries ONLY rows verified still-open and genuinely blocked, each naming its blocker and owner. ' +
            HARVEST_LAW,
    ].join('\n\n');

// --- [COMPOSITION] ---------------------------------------------------------------------

if (REJECTED.length) log('Rejected targets outside libs/{csharp,python,typescript}: ' + REJECTED.join(', '));
if (!TARGETS.length) {
    log('No targets — pass a target path, an array of paths, or {targets}. Empty args is a no-op.');
    return { targets: [], total: 0 };
}

phase('Plan');
const plan = await slot(() => agent(planPrompt(), wopts('plan', 'Plan', 'opus', PLAN_SCHEMA))).catch(() => null);
const seen = new Set();
const PAGES = ((plan && plan.pages) || [])
    .filter((p) => p && p.page && !seen.has(p.page) && seen.add(p.page))
    .map((p) => ({ page: p.page, lines: Math.max(p.lines | 0, 1) }));
const UNRESOLVED = (plan && plan.unresolved) || [];
if (UNRESOLVED.length) log('Unresolved targets (mis-scoped or renamed): ' + UNRESOLVED.join(', '));
if (!PAGES.length) {
    log('No pages resolved under the targets');
    return { targets: TARGETS, pages: 0 };
}
const PKGS = [...new Set(PAGES.map((p) => pkgOf(p.page)))];
const LANGS_IN = [...new Set(PAGES.map((p) => langOf(p.page)).filter(Boolean))];
log('Plan: ' + PAGES.length + ' page(s) across ' + PKGS.length + ' package(s) / ' + LANGS_IN.join('+') + '; CAP=' + CAP);

// AUDIT LAW PACKS — one per landed language, compiled ONCE and reused by every fixer: the checklist's binding sections
// extracted VERBATIM with source anchors into one artifact, read in a few large windows instead of the full atlas per
// file. Native, because the pack REPLACES the atlas for every fixer — a section it truncates is law no fixer ever sees.
const LAWPACK = {};
for (const k of LANGS_IN) {
    LAWPACK[k] = slot(() =>
        recon(
            () => lawPackPrompt(LANG[k], lawPackPath(k)),
            ropts(
                'lawpack:' + k,
                'Map',
                PACK_SCHEMA,
                [],
                { arr: 'sections' },
                {
                    writes: true,
                    native: true,
                    calls: 60,
                },
            ),
        ),
    ).catch(() => null);
}

phase('Map');
// One map per page, written by LOC-bounded per-package mapper sets. The map is the fixer's ENTIRE navigation, so a
// mapper set is sized by page tonnage and its coverage is asserted per FILE, never per set — one ok boolean over a
// multi-page set would send a missing page's fixer to a dead path with no fallback.
const densityMapOf = (page) => SCRATCH + '/' + fileTag('map:' + page) + '-map.md';
const MAP_SETS = PKGS.flatMap((pkg) =>
    locChunk(
        PAGES.filter((p) => pkgOf(p.page) === pkg).map((p) => ({ page: p.page, lines: p.lines, map: densityMapOf(p.page) })),
        MAP_LOC,
    ).map((set, i) => ({ pkg, i, set })),
);
const mappedPages = new Set();
await Promise.all(
    MAP_SETS.map((s) =>
        slot(() => agent(densityMapPrompt(Lof(s.pkg), s.pkg, s.set), wopts('map:' + pkgTag(s.pkg) + ':' + s.i, 'Map', 'opus', RECEIPT)))
            .then((r) => {
                if (r && r.ok && (r.entries || 0) >= s.set.length) for (const row of s.set) mappedPages.add(row.page);
            })
            .catch(() => null),
    ),
);
log('Map: ' + mappedPages.size + '/' + PAGES.length + ' page(s) mapped across ' + MAP_SETS.length + ' mapper set(s)');

phase('Pass');
// ONE fixer per file, all concurrent under the slot scheduler. Territory is the single file; every cross-file need
// returns as a typed row for the closer, so no two fixers can ever contend and no ledger is needed.
const passes = (
    await Promise.all(
        PAGES.map((p) => p.page).map((page) =>
            slot(async () => {
                const L = Lof(pkgOf(page));
                const pkR = LAWPACK[L.key] ? await LAWPACK[L.key] : null;
                return recon(
                    (reg) => densityFixPrompt(L, page, mappedPages.has(page) ? densityMapOf(page) : '', pkR && pkR.ok ? lawPackPath(L.key) : '', reg),
                    ropts(
                        'pass:' + page.replace(/^libs\//, ''),
                        'Pass',
                        PASS_SCHEMA,
                        [page],
                        { arr: 'files' },
                        { writes: true, fix: true, calls: 200 },
                    ),
                );
            }).catch(() => null),
        ),
    )
).filter(Boolean);
const REPORTS = passes.filter((f) => f.ok && f.report).map((f) => f.report);
const FAILED = passes.filter((f) => !f.ok).flatMap((f) => f.scope || []);
log('Pass: ' + REPORTS.length + '/' + PAGES.length + ' file pass(es) landed' + (FAILED.length ? ' — FAILED: ' + FAILED.join(', ') : ''));

phase('Close');
const close = REPORTS.length
    ? await slot(() =>
          recon(
              () => densityCloserPrompt(LANGS_IN, REPORTS),
              ropts('closer', 'Close', CLOSER_SCHEMA, [], { arr: 'remaining' }, { writes: true, fix: true, calls: 300 }),
          ),
      ).catch(() => null)
    : null;
const closeOk = !!(close && close.ok);
if (REPORTS.length && !closeOk) log('Closer ABSENT — cross-file rows, catalog appends, and index rows are UNDRAINED this run');
log('Close: ' + (closeOk ? 'landed, ' + (close.entries || 0) + ' row(s) remaining' : 'absent'));

return {
    targets: TARGETS,
    languages: LANGS_IN,
    packages: PKGS.length,
    pages: PAGES.length,
    mapped: mappedPages.size,
    filePasses: REPORTS.length,
    failed: FAILED,
    reports: REPORTS,
    closer: (closeOk && close.report) || '',
    remaining: (closeOk && close.entries) || 0,
    headline: (closeOk && close.headline) || '',
};
