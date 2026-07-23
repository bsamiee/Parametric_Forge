export const meta = {
    name: 'rebuild',
    whenToUse:
        'The standing hostile rebuild pass for any libs/ planning corpus: pass targets (file / sub-folder / package root, any number, any language mix); it maps every .planning sub-folder, ideates per package, hostile-rebuilds every page batch concurrently at the owning-language doctrine bar, and closes with a finder fan and one terminal fixer.',
    description:
        'Language-agnostic hostile-rebuild engine over the libs/{csharp,python,typescript} planning corpora. args = a target path, an array of paths, or {targets} — languages mix freely, {root} retargets an isolated checkout, empty = no-op; every page derives doctrine, both .api tiers, casing, and its member-verification rail from its owning package. Plan expands targets to pages in dependency + seam-cohesion order under the owning-package charter. Map fans one deep-map lane and one two-tier .api inventory lane per .planning sub-folder unit — an oversize sub-folder splits into ceiling-bounded segments, so map and batch seams stay congruent — each writing a per-unit dossier the batches reuse. Ideate runs two lanes per package with disjoint charters: a corrections census (the non-binding fix addendum) and a bigger-ideas worklist (new capability beyond correction). Build packs whole sub-folder units into batches under the packing ceiling, all concurrent under one slot scheduler; per batch a doctrine-bar lens, then implement, critique (write lane, fixlog to disk), and redteam folding the critique rows forward — every writer under the own-pass-first input ladder (own blind hostile pass primary, map dossiers grounding, census addendum, ideas ambition) with libs-wide ripple authority under the four bounds and seam-ledger coordination; handoffs carry navigation facts only. Each package chain closes with one ideas-realization writer implementing the bigger-ideas worklist against its landed corpus, gated entries carded via indexRows. The spine is per-package pipelined: each package advances Map -> Ideate -> Build the moment its own inputs land, never waiting on the slowest sibling package, and Close is the one whole-run barrier. Close: a read-only finder fan and one governance finder per language, then ONE terminal fixer draining findings, the deferred backlog, and unclaimed census rows in a fixpoint loop, then two concurrent terminals — an ideas-disposition writer giving every bigger-ideas dossier entry exactly one outcome (realized on disk, carded into the owning IDEAS.md, or rejected with reason) and a doctrine lander adjudicating pooled harvest nominations. Stage law lives in the prompt blocks.',
    phases: [
        {
            title: 'Plan',
            detail: 'targets expand to the dependency-ordered, seam-cohesion-adjacent page list under each owning-package charter: existing pages rebuild, charter-demanded absences new, settled pages skip',
        },
        {
            title: 'Map',
            detail: 'per sub-folder unit segment: a deep-map lane (ownership, seams, cross-folder relevance, domain gaps — information, never code) beside a two-tier .api inventory lane, each writing the per-unit dossier the batches reuse; one audit-law-pack lane per landed language rides the wave, extracting the critique checklist sections verbatim into the scratch artifact every critique reads instead of re-assembling the atlas',
        },
        {
            title: 'Ideate',
            detail: 'per package, two disjoint lanes fired the moment that package map lanes land: the corrections census (the deduped disk-verified fix addendum) and the bigger-ideas worklist (new capability beyond correction under the value bar)',
        },
        {
            title: 'Build',
            detail: "sub-folder-packed batches, all concurrent, each package starting on its own ideate rather than the run-wide fan: per batch a doctrine-bar lens, then implement, critique (fixlog to disk), redteam folding the critique forward — every writer on the own-pass-first ladder with bounded libs-wide ripple authority and seam-ledger coordination; after the package's last batch, one ideas-realization writer implements the worklist against the landed corpus",
        },
        {
            title: 'Close',
            detail: 'a read-only finder fan and one governance finder per language over the landed corpus and seam ledger, with two consolidation lanes riding the fan concurrently — a backlog verifier pre-verifying every deferred/census/orphan row into one deduped stale-free work list, and an ideas collator statusing every bigger-ideas entry against disk into one ledger; ONE terminal fixer drains the verified work list and findings, then realizes the ledger remainder; then two concurrent terminals — an ideas-disposition writer giving every bigger-ideas entry one outcome (realized, carded into the owning IDEAS.md, or rejected with reason) and a doctrine lander adjudicating pooled harvest nominations',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const CAP = 14;
const DRAIN_ROUNDS = 4; // terminal drain fixpoint cap; the progress gate (no shrinkage -> stop) is the real bound
const BATCH_MAX = 8; // unit-segment + batch-packing ceiling; per-segment maps + census legwork carry the navigation, so a writer holds a full dense batch
const BATCH_LOC = 3400; // size ceiling beside the count ceiling: a batch's pages must also fit one review context window with room to edit — page tonnage, not page count, is what overflows a lane
const FINDER_PAGES = 8; // landed pages per close-phase finder

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
const SCRATCH =
    '.claude/scratch/' +
    ('rebuild-' + TARGETS.map((t) => t.split('/').pop().toLowerCase()).join('-')).replace(/[^a-z0-9.-]+/g, '-').slice(0, 60) +
    '-' +
    fnv1a(JSON.stringify(TARGETS));

// --- [MODELS] --------------------------------------------------------------------------

const S = { type: 'string' };
const UNDERUTIL = {
    type: 'array',
    items: { type: 'object', additionalProperties: false, required: ['catalog', 'capability'], properties: { catalog: S, capability: S } },
};

const PLAN_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['packages', 'pages', 'unresolved'],
    properties: {
        packages: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['name', 'root', 'planning', 'api', 'note'],
                properties: { name: S, root: S, planning: S, api: S, note: S },
            },
        },
        pages: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['page', 'kind', 'lines'],
                properties: { page: S, kind: { type: 'string', enum: ['new', 'rebuild'] }, lines: { type: 'integer' } },
            },
        }, // ARRAY ORDER IS DEPENDENCY + COHESION ORDER — the engine never re-sorts; `lines` feeds the size-aware packer
        unresolved: { type: 'array', items: S },
    },
};

const ANCHOR_INFO = {
    // One anchor = one fact at one coordinate; interpretation never lives in an anchor row.
    type: 'object',
    additionalProperties: false,
    required: ['path', 'line', 'role', 'note'],
    properties: {
        path: S,
        line: { type: 'integer' },
        role: { type: 'string', enum: ['state', 'ruling', 'catalog', 'counterpart', 'absence'] },
        note: S,
    },
};

const ANCHOR_DEFECT = {
    type: 'object',
    additionalProperties: false,
    required: ['path', 'line', 'role', 'note'],
    properties: {
        path: S,
        line: { type: 'integer' },
        role: { type: 'string', enum: ['defect', 'ruling', 'catalog', 'counterpart', 'absence'] },
        note: S,
    },
};

const COVERAGE = {
    type: 'object',
    additionalProperties: false,
    required: ['requested', 'read', 'skipped', 'unverified'],
    properties: {
        requested: { type: 'array', items: S },
        read: { type: 'array', items: S },
        skipped: { type: 'array', items: S },
        unverified: { type: 'array', items: S },
    },
};

const CTX_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['worklist', 'coverage', 'summary'],
    properties: {
        worklist: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['page', 'kind', 'owns', 'contextNote', 'seams', 'files', 'anchors'],
                properties: {
                    page: S,
                    kind: { type: 'string', enum: ['new', 'rebuild'] },
                    owns: S,
                    contextNote: S,
                    seams: { type: 'array', items: S },
                    files: { type: 'array', items: S }, // files the consumer must open for this entry
                    anchors: { type: 'array', items: ANCHOR_INFO },
                },
            },
        },
        coverage: COVERAGE,
        summary: S,
    },
};

const API_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['worklist', 'coverage', 'summary'],
    properties: {
        worklist: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['page', 'apiUsed', 'apiUnderutilized', 'stackingInventory', 'files', 'anchors'],
                properties: {
                    page: S,
                    apiUsed: { type: 'array', items: S },
                    apiUnderutilized: UNDERUTIL,
                    stackingInventory: S, // capability inventory as fact — catalog members + admitting concepts, never a prescribed design
                    files: { type: 'array', items: S },
                    anchors: { type: 'array', items: ANCHOR_INFO },
                },
            },
        },
        coverage: COVERAGE,
        summary: S,
    },
};

const BAR_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['findings', 'weak', 'coverage', 'summary'],
    properties: {
        findings: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['claimKey', 'page', 'law', 'severity', 'claim', 'mechanism', 'owner', 'reject', 'acceptance', 'files', 'anchors'],
                properties: {
                    claimKey: S, // <law>|<owner>|<primary symbol> — stable across lanes, never lane wording
                    page: S,
                    law: S,
                    severity: { type: 'string', enum: ['blocker', 'major', 'minor'] }, // bound to consequence, never prose confidence
                    claim: S, // the observed defect as fact
                    mechanism: S, // WHY it fails the law — factual, zero repair verbs
                    owner: S, // canonical owner that must absorb the resolution
                    reject: { type: 'array', items: S }, // forms the repair must NOT take
                    acceptance: { type: 'array', items: S }, // signals proving resolution
                    files: { type: 'array', items: S },
                    anchors: { type: 'array', items: ANCHOR_DEFECT },
                },
            },
        },
        weak: { type: 'array', items: S },
        coverage: COVERAGE,
        summary: S,
    },
};

const RECEIPT = {
    // Thin wire receipt: the lane's PRODUCT stays on disk at `report`; only status + count + headline travel inline.
    type: 'object',
    additionalProperties: false,
    required: ['ok', 'report', 'entries', 'headline', 'failure'],
    properties: { ok: { type: 'boolean' }, report: S, entries: { type: 'integer' }, headline: S, failure: S },
};

const SEAMS = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['file', 'counterpart', 'bothEnds'],
        properties: { file: S, counterpart: S, bothEnds: { type: 'boolean' } },
    },
};

const DELTAS = {
    // navigation facts: what moved, as data, zero adjectives
    type: 'array',
    items: { type: 'object', additionalProperties: false, required: ['symbol', 'change'], properties: { symbol: S, change: S } },
};

const DEFERRED = {
    // the counted backlog: second-order + live-batch-scope ripples
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['files', 'claim'],
        properties: { files: { type: 'array', items: S }, claim: S },
    },
};

const BEYOND = {
    type: 'array',
    items: { type: 'object', additionalProperties: false, required: ['catalog', 'member'], properties: { catalog: S, member: S } },
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
}; // doctrine nominations — generalizable lessons only; the terminal doctrine lander adjudicates every row

// Required-but-empty arrays are attestations: forced seamsTouched/beyondMap/indexRows/deltas/deferred/dossierPhantoms
// make "read fully / exceed the reports / repair both ends / record the backlog" structurally checkable, never wishful prose.
const FIXLOG_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: [
        'files',
        'verdict',
        'summary',
        'seamsTouched',
        'deltas',
        'deferred',
        'beyondMap',
        'indexRows',
        'harvest',
        'dossierPhantoms',
        'collapsed',
        'extended',
    ],
    properties: {
        files: { type: 'array', items: S },
        verdict: { type: 'string', enum: ['authored', 'rebuilt', 'refined', 'clean'] },
        collapsed: S,
        extended: S,
        summary: S,
        seamsTouched: SEAMS,
        deltas: DELTAS,
        deferred: DEFERRED,
        beyondMap: BEYOND,
        indexRows: INDEXROWS,
        harvest: HARVEST,
        dossierPhantoms: { type: 'array', items: S },
    },
};

const REVIEW_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'verdict', 'summary', 'seamsTouched', 'deltas', 'deferred', 'beyondMap', 'indexRows', 'harvest', 'extended'],
    properties: {
        files: { type: 'array', items: S },
        verdict: { type: 'string', enum: ['fixed', 'clean'] },
        extended: S,
        summary: S,
        seamsTouched: SEAMS,
        deltas: DELTAS,
        deferred: DEFERRED,
        beyondMap: BEYOND,
        indexRows: INDEXROWS,
        harvest: HARVEST,
    },
};

const FINDINGS_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['findings', 'coverage', 'summary'],
    properties: {
        findings: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: [
                    'claimKey',
                    'target',
                    'files',
                    'class',
                    'grade',
                    'severity',
                    'claim',
                    'anchors',
                    'mechanism',
                    'owner',
                    'reject',
                    'acceptance',
                ],
                properties: {
                    claimKey: S, // <class>|<owner>|<primary symbol or absence route> — stable across lanes, never lane wording
                    target: S, // short display label for the defect
                    files: { type: 'array', items: S }, // files the fixer must open or edit first
                    class: { type: 'string', enum: ['missing', 'wrong', 'faked', 'naive', 'drift', 'phantom'] },
                    grade: { type: 'string', enum: ['substantive', 'hypothetical'] }, // substantive = concrete on-disk defect; hypothetical = requires an invented implausible input
                    severity: { type: 'string', enum: ['blocker', 'major', 'minor'] }, // bound to consequence, never prose confidence
                    claim: S, // the observed defect as fact
                    anchors: { type: 'array', items: ANCHOR_DEFECT },
                    mechanism: S, // WHY it fails the law/doctrine — factual, zero repair verbs
                    owner: S, // canonical owner that must absorb the resolution
                    reject: { type: 'array', items: S }, // forms the repair must NOT take
                    acceptance: { type: 'array', items: S }, // signals proving resolution
                },
            },
        },
        coverage: COVERAGE,
        summary: S,
    },
};

// The two Close consolidation products, both written pre-fixer so the terminal writer consumes FINAL lists: pre-verified work rows (stale culled with receipts,
// duplicates merged across stages) and the collated ideas ledger (every bigger-ideas dossier entry statused against current disk).
const WORK_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['live', 'culled', 'summary'],
    properties: {
        live: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['owner', 'files', 'claim', 'anchors', 'source'],
                properties: {
                    owner: S, // canonical owner that must absorb the fix — the work list groups by it
                    files: { type: 'array', items: S },
                    claim: S,
                    anchors: { type: 'array', items: ANCHOR_DEFECT },
                    source: S, // originating stage(s): impl|crit|rt|census, merged rows joined with +
                },
            },
        },
        culled: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['claim', 'receipt'], properties: { claim: S, receipt: S } },
        },
        summary: S,
    },
};

const LEDGER_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['entries', 'summary'],
    properties: {
        entries: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['idea', 'pkg', 'owner', 'status', 'anchor', 'ground'],
                properties: {
                    idea: S, // the dossier entry slug/leader, verbatim
                    pkg: S,
                    owner: S, // the owner surface the entry grows on
                    status: { type: 'string', enum: ['realized', 'unrealized', 'superseded'] },
                    anchor: S, // realized: landing coordinate; unrealized: the still-true ground; superseded: the superseding coordinate
                    ground: S, // one-line capability + demand, re-derived from current disk
                },
            },
        },
        summary: S,
    },
};

const FIXER_SCHEMA = {
    // Required-but-possibly-empty `beyond` is an attestation: the fixer's own hunt ran, not only the signal list.
    type: 'object',
    additionalProperties: false,
    required: ['files', 'indexApplied', 'resolved', 'backlogDrained', 'beyond', 'rejected', 'remaining', 'harvest', 'summary'],
    properties: {
        files: { type: 'array', items: S },
        harvest: HARVEST,
        indexApplied: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['doc', 'action'], properties: { doc: S, action: S } },
        },
        resolved: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['target', 'action'], properties: { target: S, action: S } },
        },
        backlogDrained: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['claim', 'action'], properties: { claim: S, action: S } },
        },
        beyond: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['target', 'action'], properties: { target: S, action: S } },
        },
        rejected: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['finding', 'reason'], properties: { finding: S, reason: S } },
        },
        remaining: DEFERRED, // rows verified still-open and genuinely blocked; the drain loop re-feeds them until empty or no progress
        summary: S,
    },
};

const DOCTRINE_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['landed', 'refined', 'rejected', 'files', 'summary'],
    properties: {
        landed: { type: 'array', items: S },
        refined: { type: 'array', items: S },
        rejected: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['claim', 'reason'], properties: { claim: S, reason: S } },
        },
        files: { type: 'array', items: S },
        summary: S,
    },
};

// One row per bigger-ideas dossier entry — the total-disposition attestation: an idea the run never
// realized either lands as an IDEAS.md card or dies with a recorded reason, never with the scratch dir.
const IDEAS_DISP_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['entries', 'files', 'summary'],
    properties: {
        entries: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['idea', 'outcome', 'where', 'reason'],
                properties: {
                    idea: S, // the dossier entry slug/leader
                    outcome: { type: 'string', enum: ['realized', 'carded', 'rejected'] },
                    where: S, // realized: the landing page anchor; carded: the IDEAS.md (or existing card) that carries it
                    reason: S, // rejected only; empty otherwise
                },
            },
        },
        files: { type: 'array', items: S },
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
const laneLaw = (schema, o) =>
    (o.fix
        ? '<persistence>\nComplete every named move before yielding; do not stop at analysis or a partial edit. If the chosen ' +
          'approach resists, pick the next-best one and proceed. Return without an applied edit only if the territory genuinely ' +
          'admits none.\n</persistence>\n\n<work_cadence>\nRead the stable law corpus once, first; then work ITEM BY ITEM — ' +
          "derive one item's findings, land its edits, advance. Edits land as derived and never pool toward the end: a batch " +
          'fully materialized before its first edit forfeits its earliest findings to context compaction.\n</work_cadence>' +
          '\n\n<read_discipline>\nA stable input — a doctrine page, dossier, census, catalog, charter — is read ONCE: extract ' +
          'what you need into your plan notes and re-open only the exact line span behind an edit, never the whole file again. ' +
          'Read in large windows (400+ lines per command), never 200-line paging. Your context compacts on a long lane; only ' +
          'plan notes, the seam ledger, and landed edits survive it — a fact left only in context is lost. Budget: at most ' +
          (o.calls || 300) +
          ' tool calls total; at the budget, land what is derived and record every remaining row in the product `deferred` ' +
          'field — an honest remainder beats a thrashing overrun.\n</read_discipline>' +
          '\n\n<verification>\nAfter editing, re-read each changed file and confirm it is coherent ' +
          'and nothing it carried was lost. Fix what fails before yielding. Verification is READING: the corpus is markdown ' +
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
          '</verification>') +
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
    const report = ROOT_DIR + '/' + base + '-report.json';
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
    return (
        'DISPATCH ROLE: a delegate performs the complete TASK below through one supervised lane run; never perform, edit, judge, soften, ' +
        'summarize, or relay the work yourself. (1) Write the LANE LAW block below VERBATIM to ' +
        lane +
        '/law.md and the TASK block below VERBATIM to ' +
        lane +
        '/task.md, composing neither. ' +
        (authored
            ? 'Delete any leftover file at ' + report + ' with one Bash rm -f (a stale product there passes the verify probe as a false success). '
            : '') +
        '(2) Run ONE Bash call with run_in_background true: ' +
        LANE_SCRIPT +
        ' --task ' +
        lane +
        '/task.md --law ' +
        lane +
        '/law.md --dir ' +
        lane +
        ' --cwd ' +
        ROOT_DIR +
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
        ' (4) Verify with one Bash call: jq -e . ' +
        report +
        ' >/dev/null — a nonzero exit means a missing or malformed product; on a miss re-derive the product once from the lane ' +
        'events.jsonl (jq -rs to the last agent_message item text, Write that), re-probe, and a second miss returns ok=false with the ' +
        'probe output. (5) Return ok=true, report=' +
        base +
        '-report.json (this repo-relative form, matching codex-lane receipts), entries = the length of the "' +
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
// the mapping) — the caller owns the re-dispatch. The roster row carries `scope` from the
// ORCHESTRATOR (never the lane's self-report) so a failed lane's unmapped territory is exact even when the lane died before writing anything.
const twinOf = (m) => (/-terra/.test(m || '') ? 'opus' : /-luna/.test(m || '') ? 'sonnet' : 'fable');
const nativeLane = (task, o) => {
    const report = SCRATCH + '/' + fileTag(o.label) + '-report.json';
    return agent(
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
    // o.native forces the native branch (the deep-map lane rides it).
    const task = typeof taskOf === 'function' ? taskOf : () => taskOf;
    const wrapper = {
        label: (o.model && o.model.indexOf('-terra') >= 0 ? 'terra:' : 'sol:') + o.label,
        phase: o.phase,
        model: 'sonnet',
        effort: 'low',
        schema: RECEIPT,
    };
    return (
        !o.native
            ? agent(codexPrompt(o.label, task('codex'), o.schema, o), wrapper).then((r) =>
                  r && !r.ok && /usage|quota|limit/i.test(r.failure || '') ? nativeLane(task('claude'), o) : r,
              )
            : nativeLane(task('claude'), o)
    ).then((r) => ({
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
// Dual-ceiling split: segment count from BOTH ceilings (page count AND page tonnage), then near-even LOC fill in
// order — no runt tail, and no segment whose pages alone overflow a review lane's context window.
const sizeChunk = (pages) => {
    const loc = (ps) => ps.reduce((a, s) => a + s.lines, 0);
    const k = Math.max(Math.ceil(pages.length / BATCH_MAX), Math.ceil(loc(pages) / BATCH_LOC), 1);
    if (k === 1) return [pages];
    const target = loc(pages) / k;
    const out = [];
    let cur = [];
    let acc = 0;
    for (let i = 0; i < pages.length; i++) {
        const p = pages[i];
        // Boundary BEFORE the page when the segment sits nearer target without it — the overshooting page starts
        // the next segment instead of heaping onto this one; guards keep every later segment fillable.
        const splitBefore =
            cur.length > 0 &&
            out.length < k - 1 &&
            pages.length - i >= k - out.length - 1 &&
            (cur.length >= BATCH_MAX || Math.abs(acc - target) <= Math.abs(acc + p.lines - target));
        if (splitBefore) {
            out.push(cur);
            cur = [];
            acc = 0;
        }
        cur.push(p);
        acc += p.lines;
    }
    if (cur.length) out.push(cur);
    return out;
};
const pkgOf = (p) => p.split('/.planning/')[0]; // package = the write-partition key (index docs live at its root)
const subOf = (p) => {
    // Sub-folder = the map/batch granularity unit: one mapper pair and one batch-ownership seam per `.planning/<sub>`; root-level pages pool as '_root'.
    const rest = p.split('/.planning/')[1] || '';
    return rest.includes('/') ? rest.split('/')[0] : '_root';
};
const Lof = (pkg) => LANG[langOf(pkg)] || LANG.cs;
// Scratch paths follow one grammar: SCRATCH + '/' + fileTag(<label>) + '-<artifact>'. Seam ledgers key on the batch tag; dossiers key on their recon lane label
const scratchBase = (pkg, i) => SCRATCH + '/' + fileTag(pkg.split('/').pop() + ':b' + i);
const dossierPath = (lensLabel) => SCRATCH + '/' + fileTag(lensLabel) + '-dossier.md';
const normalizePages = (pl) => {
    // Preserves plan emission order (dependency + cohesion order); dedupe by page, first wins.
    // `lines` feeds the size-aware packer; a `new` page (0 on disk) packs at a typical authored weight.
    const seen = new Set();
    const out = [];
    for (const p of (pl && pl.pages) || []) {
        if (!p || !p.page || seen.has(p.page)) continue;
        seen.add(p.page);
        out.push({ page: p.page, kind: p.kind === 'new' ? 'new' : 'rebuild', lines: Math.max(p.lines | 0, 500) });
    }
    return out;
};

const navOf = (logs) => {
    // Navigation handoff: FACTS ONLY — files, symbol deltas, seam rows, backlog. Never verdicts, summaries, or adjectives.
    const rows = logs.filter(Boolean);
    return {
        files: [...new Set(rows.flatMap((r) => r.files || []))],
        deltas: rows.flatMap((r) => r.deltas || []),
        seams: rows.flatMap((r) => r.seamsTouched || []),
        deferred: rows.flatMap((r) => r.deferred || []),
    };
};

// --- [SHARED_BLOCKS]

// Every rigor law appears exactly once, here; stages compose subsets. Block order in prompts: stable per-language law first (byte-identical across a
// batch's stages), batch-variable material second, the stage task + output contract LAST — nothing load-bearing mid-prompt.
const ROOT_LAW =
    'WORKING ROOT: ' +
    ROOT_DIR +
    ' — every relative repo path in this brief resolves against this absolute root; read, write, and edit ONLY under it, never ' +
    'another checkout of the repository.';
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

const BUILD_LAW = (L) =>
    'BUILD LAW — buildout over removal, always; removal authority covers ONE case, the PHANTOM (a cited member that does not ' +
    'exist). An underutilized catalog, orphan-looking admission, or weak fence is an INTEGRATION target: the capability lands as ' +
    L.ownerGrammar +
    ' — inside the existing owner, reshaped as if always carried — or is wired into its owning sibling page in the same pass. ' +
    'Never a parallel type, a sibling shape, or flat appended code; never extract a file to cut LOC; never regress capability. ' +
    'A NEW page is admitted on one ground only: a genuinely new owner the domain demands that no existing owner can absorb, ' +
    'authored in the TARGET package and wired into the folder seam owners — never as extraction relief. Structural collapse and ' +
    'CAPABILITY completeness are orthogonal — a fully collapsed owner can still model a naive slice; close both. Every extension ' +
    'cites one gap source: PACKAGE — an admitted member the concept admits but the page ignores (' +
    L.gapPkg +
    '); DOMAIN — an attribute, metric, sub-kind, relationship, state, or operation the real concept demands (' +
    L.gapDomain +
    '); CONSUMER — a contract a sibling or downstream owner will require. A genuinely needed NEW external package is admitted ' +
    'additively: author its README registry row and `.api` catalog yourself; report its central-manifest row in `indexRows`. ' +
    'Byte-count is a weak proxy — assess each owner against its full domain and both-tier surface regardless of size, and model ' +
    'it for FIVE TIMES today\'s cases, fields, and consumers: a thin slice built "for now" is the COVERAGE defect by definition. ' +
    'CHANNEL LAW — a canary/beta/pre-release channel is admissible where the bleeding edge genuinely adds capability, judged on ' +
    'capability delta, maintenance signal, and integration merit, pinned exact with the typing posture recorded in the catalog.';

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

const RIPPLE_LAW =
    'RIPPLE LAW — every fix you identify you make NOW via Edit/Write; the fix-log reports edits already made, never a to-do, ' +
    'a ledger, or a would/should hedge. The writing is YOURS — a delegate may only fetch information. Ripple authority is ' +
    'LIBS-WIDE (any file under libs/, any language, corrective AND generative) under four bounds that are evidence, never ' +
    'radius. (1) EVIDENCE — an out-of-scope edit traces to a resolvable anchor: a seam-ledger row, a consumer anchor, an index ' +
    'claim, or a wire row in the branch ARCHITECTURE.md [02]-[SEAMS] ledger; an anchorless edit is drift, forbidden. ' +
    '(2) EXPAND-FORM — a foreign edit made while sibling batches run is ADDITIVE only (add the case, row, field, operation, or ' +
    'counterpart); renaming, removing, or collapsing a foreign surface is recorded in `deferred` for the terminal fixer, never ' +
    'raced. Wire-canonical names stay frozen; a foreign-language counterpart is repaired at ITS branch doctrine bar (read that ' +
    'branch stack README before a non-trivial foreign edit) with surgical anchored edits, never a foreign-interior rebuild. ' +
    '(3) DEPTH — a first-order ripple (your edit broke or opened it directly) is repaired both ends now and recorded in ' +
    "`seamsTouched`; a second-order ripple or a counterpart inside a concurrent batch's scope is recorded in `deferred` as " +
    '{files, claim} — the fixer drains the backlog this run; nothing drops silently. (4) DECISION/PROPAGATION — ' +
    'decision-carrying shared surfaces are single-writer: the owning-package index docs (ARCHITECTURE.md + README.md at the ' +
    'path before `/.planning/`), IDEAS.md, and the central manifests take exact rows via `indexRows` for the terminal fixer to ' +
    'apply once; distributing an already-ruled contract is yours. GENERATIVE openings: a capability your work opens elsewhere ' +
    'is realized NOW when it lands in expand-form owner grammar on an existing owner; an opening demanding a new owner outside ' +
    'the target package lands as a fully-specified IDEAS row via `indexRows`, never a vague note.';

const CURRENT_STATE =
    'CURRENT STATE — sibling batches land work concurrently with yours. Your own pass already reads each target page fresh ' +
    'from CURRENT disk; before an edit whose correctness depends on a sibling page, re-open the specific SPAN of that sibling ' +
    'it composes or ripples into — never a whole-file re-read; landed sibling work is picked up as found, never assumed ' +
    'from the dossier snapshot (dossiers ground verified `.api` extracts, never sibling page state). A seam counterpart a ' +
    'sibling landed is COMPOSED, not re-derived; a conflict resolves to the stronger form, never a revert.';

const LEDGER = (base, scopes) =>
    'SEAM LEDGER — cross-batch coordination is typed fact rows on disk, never prose. Your batch ledger is `' +
    base +
    '-seams.md`: append one row per cross-file event as you work — `SEAM_CHANGED | <files> | <symbol/wire fact, old -> new>` ' +
    'when a shared name, signature, or contract you own moves; `RIPPLE_REPAIRED | <files> | <fact>` when you repair a ' +
    'counterpart, so no sibling redoes it; `SEAM_CONFLICT | <files> | <both values>` on collision with a landed sibling row ' +
    '(resolve to the stronger form per CURRENT STATE). Before ANY edit outside your batch pages, `ls` `' +
    SCRATCH +
    '/` and read every sibling `*-seams.md` row whose files intersect yours — a RIPPLE_REPAIRED row is work you do NOT redo, a ' +
    'SEAM_CHANGED row a contract you compose. Rows are facts, zero adjectives. CONCURRENT BATCH SCOPES (a counterpart inside ' +
    "another live batch's scope is recorded in `deferred`, never edited): " +
    scopes;

const PROSE_COMMENTS = (L) =>
    'PROSE + COMMENTS — apply docs/standards/style-guide.md, information-structure.md, and formatting.md. The page is a design ' +
    'spec: lead each section with the controlling contract, one idea per paragraph, close on the consequence; no provenance, ' +
    'narration, freshness disclaimers, or hedges. Backtick every symbol, type, field, function, operator, package ID, path, ' +
    'command, flag, and literal; name the exact member over paraphrased behavior; trimming never reduces technical density. ' +
    'Fences comment for the next agent only: keep the canonical section-divider headers; beyond them zero comments, 1-2 lines ' +
    'only for a truly subtle invariant or boundary; no restating the code, no ' +
    L.docBloat +
    ' bloat.';

const INFO_LAW =
    'You provide INFORMATION, never prescriptions: exact disk anchors, the current shape at each site, seam endpoints both ' +
    'sides, verified member spellings, gaps. The implement agent decides how to build; an entry that says what to write ' +
    'instead of what is true is a defect. ENTRY FORM: prose fields carry fact; `anchors` carry one coordinate per row (role ' +
    'names what it proves; `note` is the shortest literal witness under 20 words, or empty when path+line suffice; an ' +
    '`absence` anchor names where the expected thing was searched and not found); `files` lists what the consumer must open. ' +
    'An underutilized-capability entry is INVENTORY: verified members, usage anchors, the admitting concept — composition is ' +
    "the implement agent's call. COVERAGE is part of the product: `requested` = assigned scope, `read` = actually full-read, " +
    '`skipped`/`unverified` = not reached — an honest skip beats a silent one.';

const EVIDENCE_LAW =
    'FINDING FORM — you deliver TRUTH, never an implementation: `claim` states the observed defect; `mechanism` states WHY it ' +
    'fails the law as fact; `anchors` carry one coordinate per row (role names what it proves; `note` is the shortest literal ' +
    'witness under 20 words, or empty when path+line suffice; an `absence` anchor names where the expected thing was searched ' +
    'and not found); `owner` names the canonical owner that must absorb the resolution (the owning axis, roster, registry, or ' +
    'seam vocabulary — never a new local shape); `reject` lists forms the repair must not take; `acceptance` the signals ' +
    'proving resolution. NEVER write add/replace/implement/promote/delete as instruction — the writer owns the design, you the ' +
    'constraint boundary. `claimKey` is identical for the same defect regardless of lane or wording. `severity` binds to ' +
    'consequence (blocker = run-blocking, major = corpus correctness, minor = local cleanup), never prose confidence. OUTPUT ' +
    'BOUNDS: the finding count follows the territory, never a target — a typical page yields 0-2 retained findings and a clean ' +
    'page yields none; 0 across the whole scope only when the second hostile pass returns empty, `summary` then naming the ' +
    'probes that produced nothing; never manufacture a finding to fill a count, never delete a confirmed one to trim one. ' +
    'COVERAGE is part of the product: `requested` = assigned scope, `read` = actually full-read, ' +
    '`skipped`/`unverified` = not reached or unconfirmed — an honest skip beats a silent one.';

const HARVEST_LAW =
    'HARVEST (required key, usually empty): nominate ONLY findings that generalize beyond this batch — a collapse pattern ' +
    'reusable across folders, a naivety class no doctrine clause names, a review rule that catches the defect BEFORE review, a ' +
    'hard-won cross-surface coupling. Each row: altitude (stacks|reviewer|constitution|planning|readme|laws), lang, claim (the ' +
    'generalized law, one sentence), anchors (file:line evidence), existingClause (the exact clause it hardens, quoted with its ' +
    'path — or "absent" with the surfaces searched). A batch-local fix never nominates; an empty array is the normal verdict — ' +
    'the doctrine lander refutes weak rows, so nominate substance, never volume.';

const OWN_PASS =
    'OWN PASS FIRST — the input ladder is binding, in order: (1) your own blind hostile pass, (2) the map dossiers, (3) the ' +
    'corrections census, (4) the bigger-ideas worklist. Rung (1) is the PRIMARY product: cold-read every target page from ' +
    'CURRENT disk and derive your own defect list, collapse targets, naivety kills, body rebuilds, and design rulings BEFORE ' +
    'opening any recon report, census, or worklist. Rungs (2)-(4) ground, extend, and widen YOUR pass — they never scope, ' +
    'substitute for, or cap it. TRIPWIRE: a pass whose diff maps one-to-one onto the recon rows has failed — the recon covers a ' +
    'MINORITY of what the rebuild demands, and the majority of your edits must come from your own attack.';

const CORRECTIONS = (path) =>
    path
        ? 'CORRECTIONS CENSUS (ladder rung 3) — `' +
          path +
          '` carries the folder-wide fix census consolidated from the map lanes, sectioned per sub-folder: drift, phantoms, ' +
          'catalog-true spelling repairs, seam and wire mismatches, wiring gaps. ADDITIONAL, never the plan: after your own pass, ' +
          'land every row that intersects your pages (re-verified on disk — a row disk already resolves is dropped) and leave ' +
          'foreign rows alone; the terminal fixer drains the remainder. A pass that only lands census rows has failed OWN PASS FIRST.'
        : '';

const IDEAS = (path) =>
    path
        ? 'BIGGER-IDEAS WORKLIST (ladder rung 4) — `' +
          path +
          '` carries per-sub-folder capability AMBITIONS: new dimensions, modalities, families, and operations the domain admits ' +
          'BEYOND correction. Read the entries covering your pages IN FULL, spot-verify each against current disk, and build the ' +
          'STRONGEST form it points toward or a stronger one you see. An idea disk already realizes, or the doctrine forbids, is ' +
          'dropped; an idea you decline is not a defect. Ambition and information, never a prescription, a design, or a ceiling.'
        : '';

const readFirst = (L, pkg, dossiers) =>
    [
        'READ FIRST, IN ORDER, BEFORE ANY EDIT — no fence is judged before this read lands.',
        '(1) DOCTRINE — enumerate `' +
            L.stack +
            '/` with a real `ls` (never memory), then read the README and EVERY root page it routes IN FULL in the README ' +
            '[01]-[ATLAS] order — never a partial, skim, grep-jump, or section-sample; a root page absent from the atlas is ' +
            'still mandatory law. The README [02]-[DOCTRINE] laws, the [03]-[COLLAPSE_SCAN] table, OWNER_CHOOSER (`shapes.md` ' +
            '[01]), RAIL_CHOOSER (`rails-and-effects.md` [01]), and the aspect two-weave (`surfaces-and-dispatch.md` AND ' +
            '`rails-and-effects.md`) are binding law AT THE SOURCE — read it there, hold it as fact, conform every fence to it; ' +
            'a summary never substitutes for the read.',
        L.key === 'cs'
            ? '(1b) Enumerate `docs/stacks/csharp/domain/` with a real `ls` through its router README, then read every shard ' +
              'the page concerns touch — chosen from the enumerated set, never from memory; shard conformance is a hard gate.'
            : '',
        '(1c) ANALYZER LAW — read the repo `.editorconfig` rules for your language: every `error`-severity rule is a COMPILE ' +
            'GATE (`dotnet_style_namespace_match_folder = true:error` means namespace ALWAYS equals folder path); a claim ' +
            'contradicting an error-level analyzer rule is a FICTION to correct, never law to compose.',
        '(1d) LAWS — read `docs/laws/` IN FULL (README + topology + patterns + scars; short registry pages): a topology row ' +
            'whose [SURFACE] your edits touch binds its obligated counterparts into the SAME pass, and every patterns row binds each branch it names.',
        '(2) .API — `ls` BOTH catalog tiers in full — the shared substrate `' +
            L.root +
            '/.api/` AND the folder `' +
            pkg +
            '/.api/` — then read every catalog relevant to these pages, layering the shared rails (' +
            L.deepPkgs +
            ') ON TOP OF the folder domain packages, never the folder set alone.',
        dossiers
            ? 'The grounding dossiers for this batch — `' +
              dossiers +
              '` — carry verified two-tier extracts: Tier-1 verbatim member/seam extracts with `file:line` anchors (read fully; ' +
              'SPOT-VERIFY the anchors — a fake anchor goes in `dossierPhantoms`), Tier-2 pointer rows (path + one-line scope) ' +
              'for the long tail — resolve a pointer with a real read the moment an edit touches its territory, never guess past ' +
              'it. Hunt PAST both lanes — members composed beyond them are enumerated in `beyondMap`. Absent or stale, run the ' +
              'full two-tier `ls`+read yourself.'
            : '',
        '(3) SCOPE — read the owning-package charter (ARCHITECTURE.md + README.md + IDEAS.md) as the INTENT authority for what ' +
            'each page owns and which pages are settled. A charter-settled page is out of scope; every page in your batch is ' +
            'rebuilt to the strongest form the doctrine admits.',
    ]
        .filter(Boolean)
        .join('\n');

const reconBlock = (roster, unmapped) =>
    'RECON REPORTS (ladder rung 2) — the lens products are ON DISK as JSON report files; the receipts below are navigation, ' +
    'never the product. CONSUMPTION, after your own cold pass per OWN PASS FIRST: (a) UNMAPPED territory below (a dead lens) ' +
    'gets your own cold read — that lens dimension over your pages is yours to derive; (b) read every ok report IN FULL from ' +
    'disk, grounding lenses before the bar defect lens, clustering entries by page; (c) anchors are jump coordinates — re-open ' +
    "every anchor behind an edit (MANDATORY); navigation-only entries re-verify only when touched; (d) a bar finding's " +
    '`mechanism`/`owner`/`reject`/`acceptance` are its constraint boundary — honor the owner and rejected forms, but the ' +
    'DESIGN is yours. The reports POINT; you VERIFY and EXCEED them: compose every `apiUsed` catalog at full operator depth, ' +
    'stack every `apiUnderutilized` {catalog, capability} INTO the owning page as a case, row, field, or operation, close ' +
    'every bar finding at its law, and independently confirm no other admitted catalog (either tier) is missing. Members ' +
    'composed beyond the reports are enumerated in `beyondMap` — an empty `beyondMap` attests the reports were genuinely ' +
    'complete, never a license to treat them as a ceiling.\nROSTER: ' +
    JSON.stringify(roster) +
    '\nUNMAPPED: ' +
    JSON.stringify(unmapped);

const GIT_GROUND =
    'DELTA GROUNDING — run `git diff --stat` then `git diff -- <your batch pages and their seam files>` before judging; ' +
    '`git status` surfaces new files. The diff is orientation, CURRENT disk is truth — the repo can carry pre-run uncommitted ' +
    "work, so an unfamiliar hunk is verified against disk, never assumed to be this run's.";

const HUNT =
    'HUNT CLASSES: missing (an owner, case, field, seam counterpart, or capability the charter or landed design demands with ' +
    'no counterpart on disk), wrong (landed but contradicting doctrine, charter, or analyzer law), faked (prose asserts what ' +
    'the fence body omits, a name promising capability the body lacks), naive (a thin slice of the concept, an underutilized ' +
    'admitted package, either naivety axis), drift (two landed surfaces disagreeing — page vs sibling vs index doc vs manifest ' +
    'vs .api), phantom (a cited member, page, or anchor that does not exist). Every finding carries a file anchor, names the ' +
    'law or catalog member it violates, and is graded `substantive` (concrete on current disk) or `hypothetical` (real only ' +
    'under an invented, implausible input). Verify cited external members against the .api catalogs; never trust page prose ' +
    'about itself.';

const preamble = (L, batch, dossiers, ideate, scopes, roster, unmapped, reg) =>
    [CONTEXT(L), REG[reg].stance(L), OWN_PASS, BUILD_LAW(L), BODY(L), VERIFY(L), RIPPLE_LAW, CURRENT_STATE, PROSE_COMMENTS(L)]
        .concat(L.mechanics ? [L.mechanics] : [])
        .concat([
            readFirst(L, pkgOf(batch[0].page), dossiers),
            LEDGER(scratchBase(pkgOf(batch[0].page), batch[0].i || 0), scopes),
            reconBlock(roster, unmapped),
        ])
        .concat(ideate && ideate.fix ? [CORRECTIONS(ideate.fix)] : [])
        .concat(ideate && ideate.idea ? [IDEAS(ideate.idea)] : []);

// Prompt builders — each task states only its own action; shared checks are referenced by name.
const planPrompt = () =>
    [
        ROOT_LAW,
        'Rasm monorepo — the libs/{csharp,python,typescript} planning corpora (markdown design specs). ' +
            "Targets may mix languages; each page's owning package derives its own doctrine downstream.",
        'TASK: thin enumerate + classify (read-only, do NOT edit). TARGETS (repo-relative): ' +
            JSON.stringify(TARGETS) +
            '. The OWNING PACKAGE of a page is the path before `/.planning/`. EXPAND with a real recursive listing per target ' +
            '— run find <target-or-its-.planning-tree> -name *.md; a design page lives INSIDE the .planning tree, so a ' +
            'package-root ls alone NEVER proves an empty page set. Validate against `libs/.planning/planning-targets.md` (a ' +
            'mis-scoped or renamed target is reported in `unresolved`; a deliberately page-less target skips silently). Return ' +
            '`packages` (one entry per owning package: {name, root, planning, api}). PAGES: expand each target — a ROOT to ' +
            'every design page under its planning tree, a SUB-FOLDER to every page under it, a FILE to itself; union + dedup; ' +
            'exclude IDEAS.md/TASKLOG.md/README.md/ARCHITECTURE.md. Each page row carries `lines` = its real line count ' +
            '(one `wc -l` sweep over the listing; 0 for a `new` page absent on disk) — the engine packs batches by tonnage, ' +
            'so a guessed count corrupts the packing.',
        'SCOPE LAW — the owning-package charter (ARCHITECTURE.md + README.md + IDEAS.md) owns scope: every existing design ' +
            'page under the targets enters as `rebuild`; a page the charter demands but disk lacks enters as `new`; a ' +
            'charter-settled page is SKIPPED, never re-litigated.',
        'EMIT `pages` IN DEPENDENCY + COHESION ORDER — grouped by sub-folder, foundations before consumers, pages sharing an ' +
            'owner, seam, or wire contract ADJACENT within their group (the engine batches contiguous runs of your order, so ' +
            'adjacency keeps coupled pages inside one writer); alphabetical only as the final tiebreak. The engine never re-sorts.',
        'TOOLCHAIN WARM-UP (before returning): run `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api --help` once — ' +
            "it builds the workspace uv cache every downstream lane's member-verification rail rides, so no lane pays the cold " +
            'environment latency or misreads it as a broken rail.',
    ].join('\n\n');

const correctionsPrompt = (L, pkg, mapIndex, dossier) =>
    [
        ROOT_LAW,
        CONTEXT(L),
        'TASK: CORRECTIONS CENSUS AUTHOR for `' +
            pkg +
            '` — read-only over the corpus; you WRITE exactly one file, the census dossier. The Map phase produced per-SUB-FOLDER ' +
            'deep-map and two-tier .api inventory dossiers; read EVERY dossier listed here IN FULL: ' +
            JSON.stringify(mapIndex),
        'AUTHOR `' +
            dossier +
            '` — one markdown census, a section per sub-folder. Consolidate every CORRECTION the map lanes surfaced or your own ' +
            'verification finds: drift between surfaces (page vs sibling vs index doc vs manifest vs .api), phantom members, ' +
            'catalog-true spelling repairs, seam and wire mismatches, contradicted analyzer law, and WIRING GAPS (an uncomposed ' +
            'admitted member the page concept plainly demands). Each row: the owning page, the exact `file:line` anchor, the ' +
            'defect as fact, and the catalog or doctrine coordinate proving it. DEDUPE across dossiers; VERIFY each row on ' +
            'current disk before writing it — a row disk already resolves is dropped. FORBIDDEN: new-capability ambitions (the ' +
            'ideas lane owns them — a row that widens what the package IS is dropped here, not diluted into a fix), ' +
            'prescriptions, fence sketches, removal framing.',
        REG.claude.selfCheck,
        'Return ONLY the receipt: ok, report = the census path (repo-relative), entries = the row count, a one-line headline, failure empty.',
    ].join('\n\n');

const ideasPrompt = (L, pkg, mapIndex, dossier) =>
    [
        ROOT_LAW,
        CONTEXT(L),
        'TASK: BIGGER-IDEAS AUTHOR for `' +
            pkg +
            '` — read-only over the corpus; you WRITE exactly one file, the ideas dossier. The Map phase produced per-SUB-FOLDER ' +
            'deep-map and two-tier .api inventory dossiers; read EVERY dossier listed here IN FULL, then the package charter ' +
            '(ARCHITECTURE.md + README.md + IDEAS.md) and the pages your ideas grow on: ' +
            JSON.stringify(mapIndex),
        'AUTHOR `' +
            dossier +
            '` — one markdown dossier, a section per sub-folder and a terminal CROSS-FOLDER section. Every entry is a NEW ' +
            'capability the domain admits and the corpus lacks — a new dimension, modality, family, case class, operation ' +
            'family, generator over an enumerated space, or cross-boundary enablement that widens what the package IS — ' +
            'grounded in real domain demand (' +
            L.gapDomain +
            ') and the admitted two-tier package depth. VALUE BAR — the census/ideas partition is severity of imagination, not ' +
            'anchor quality: a stale label, wrong spelling, dropped wire column, or single uncomposed member is a CORRECTION ' +
            'and drops here; an entry earns its row by naming capability whose absence a domain expert would call a gap in the ' +
            'PRODUCT, not a defect in the prose. Name the owner it grows on, the domain or catalog ground, the anchor, and WHY ' +
            'it widens the package — never the resulting code, a fence sketch, or a ruled shape. CROSS-FOLDER: an idea whose ' +
            'value crosses the package boundary names BOTH ends and the seam it rides.',
        "SECOND-PASS CULL (before returning): re-open every entry's anchor on disk; delete any entry disk already realizes, " +
            'any correction in disguise, and any entry whose value you cannot state as a concrete new capability of a named ' +
            'owner. Boldness is never the cull criterion — the cull removes false and small entries, never ambitious ones; few ' +
            'large ideas beat many verified trivia.',
        REG.claude.selfCheck,
        'Return ONLY the receipt: ok, report = the dossier path (repo-relative), entries = the idea count, a one-line headline, failure empty.',
    ].join('\n\n');

const ctxLensPrompt = (L, batch, dossier, reg) =>
    [
        CONTEXT(L),
        REG[reg].stance(L),
        INFO_LAW,
        REG[reg].selfCheck,
        REG[reg].antiAnchor(L),
        readFirst(L, pkgOf(batch[0].page), ''),
        REG[reg].ctx(batch.length) +
            batch.map((p) => p.page + ' [' + p.kind + ']').join(', ') +
            '. For a rebuild page read the page IN FULL; for a `new` page read its concept in the owning-package charter and ' +
            'its nearest siblings. Read the folder at large — the sibling pages each composes and the index docs — as full-file ' +
            'reads. For EACH page return: `owns` (the ONE ownership boundary sentence — which owner/vocabulary/concern THIS page ' +
            'owns versus its siblings, so no two concurrent writers author the same polymorphic surface), `contextNote` (sibling ' +
            'owners/seams composed, folder position, folder-wide gaps routed here, DOMAIN gaps — attributes, sub-kinds, ' +
            'states, relationships, operations the real concept demands that the page omits, as named gaps), `seams` (every ' +
            'cross-page and cross-package symbol/wire/consumer edge, both endpoints named). CROSS-PACKAGE RELEVANCE: also mine ' +
            'what the OTHER packages hold that is relevant to each page — kernel and sibling-package owners it composes or its ' +
            'concept plainly touches, imports, consumer sites, ripple targets both ends — as verified anchors in ' +
            '`seams`/`anchors`, so a writer NAVIGATES (trust, then verify at the anchor) instead of exploring; relevance is ' +
            'fact, never a suggested change. Each entry also carries `files` and typed `anchors` per the entry form. GROUNDING DOSSIER: write `' +
            dossier +
            '` — Tier-1: the branch ARCHITECTURE.md [02]-[SEAMS] rows covering these pages quoted verbatim with `file:line` ' +
            'anchors, folder-context and charter-intent anchors; Tier-2: pointer rows (path + one line) for every sibling page ' +
            'composed. FORBIDDEN: doctrine digests, removal framing, unanchored claims, prescriptive designs. Return worklist + coverage.',
    ].join('\n\n');

const apiLensPrompt = (L, batch, dossier, reg) =>
    [
        CONTEXT(L),
        REG[reg].stance(L),
        VERIFY(L),
        INFO_LAW,
        REG[reg].selfCheck,
        REG[reg].antiAnchor(L),
        REG[reg].api(batch.length) +
            batch.map((p) => p.page + ' [' + p.kind + ']').join(', ') +
            '. `ls` BOTH catalog tiers in full — the shared substrate `' +
            L.root +
            '/.api/` AND the folder `' +
            pkgOf(batch[0].page) +
            '/.api/` — read every catalog relevant to these pages and DIFF the complete admitted inventory against the whole folder: ' +
            REG[reg].apiVerify +
            ' — a capability no page exploits is a named integration gap ROUTED to EVERY page whose concept admits it, never ' +
            'one "best" owner alone. SINGLE-CONSUMER EXPANSION: a package with a catalog at ANY tier consumed by only ONE page ' +
            'is expansion pressure on its siblings — name the package, its unexploited members in exact spellings, and each ' +
            'candidate page. Discovery has ZERO removal authority: an underutilized catalog is always a buildout target, never ' +
            'removal evidence. DEPTH GRADING: a composed member counts as underutilized when the usage is shallow — one call ' +
            'where the surface carries a family, a default-arg call where the policy axis matters, a scalar use of a ' +
            'batch/stream-capable member; grade used-but-shallow with the same {catalog, capability} rows as unused. For EACH ' +
            'page return `apiUsed`, `apiUnderutilized` ({catalog, capability}: exact catalog-anchored spelling + integration ' +
            "shape as fact), `stackingInventory` (capability names + the doctrine patterns the page's concept admits, as " +
            'inventory fact — never a prescribed design), `files` and typed `anchors` per the entry form. Verify every cited member via ' +
            L.verify +
            '; never list a phantom. GROUNDING DOSSIER: write `' +
            dossier +
            '` — Tier-1: quoted `.api` member blocks with `file:line` anchors for every cited member and the real `ls` ' +
            'inventories of both tiers; Tier-2: pointer rows (catalog path + one-line scope) for the remainder. FORBIDDEN: ' +
            'doctrine digests, unanchored claims, prescriptive designs. Return worklist + coverage.',
    ].join('\n\n');

const barLensPrompt = (L, batch, reg) =>
    [
        CONTEXT(L),
        REG[reg].stance(L),
        EVIDENCE_LAW,
        REG[reg].selfCheck,
        REG[reg].antiAnchor(L),
        REG[reg].bar(batch.length) +
            batch.map((p) => p.page + ' [' + p.kind + ']').join(', ') +
            '. Enumerate `' +
            L.stack +
            '/` with a real `ls` and read the README and EVERY root page it routes IN FULL — never a partial, skim, grep-jump, ' +
            'section-sample, or line-count-as-read; a grep-sampled doctrine is a skipped read your coverage must report' +
            (L.key === 'cs' ? ' (and the domain/ shards these pages touch)' : '') +
            '; then read each target page IN FULL and ' +
            REG[reg].barAttack(L) +
            ' where doctrine is not followed AND where a doctrine law applies more deeply for a stronger form: collapse signals ' +
            'ungathered, owner forms weaker than the discriminants demand, rails split or dual-paradigm, knobs where policy ' +
            'values belong, naive bodies below the admitted combinator surface, ' +
            L.docBloat +
            ' bloat, file-organization drift, both naivety axes. Return per-page `findings` in the FINDING FORM — `law` names ' +
            'the doctrine law at its source, `claimKey` = <law>|<owner>|<primary symbol>, typed `anchors` at exact coordinates — ' +
            'and `weak` (pages whose overall verdict is weak). Findings name the law and the defect, NEVER the resulting code — ' +
            'the implement agent rules every design.',
    ].join('\n\n');

const implementPrompt = (L, batch, dossiers, ideate, scopes, roster, unmapped) =>
    preamble(L, batch, dossiers, ideate, scopes, roster, unmapped, 'claude')
        .concat([
            'TASK: HOSTILE IMPLEMENT of these ' +
                batch.length +
                ' pages IN PLACE, each per its kind: ' +
                batch.map((p) => p.page + ' [' + p.kind + ']').join(', ') +
                '.\n' +
                'kind=`new`: GROUND-UP AUTHOR the page (it may open a new sub-folder) to the full doctrine + domain-complete ' +
                'capability bar, in the code-fence-first form of its mature siblings, wired into the folder entry/receipt seam ' +
                'owners. kind=`rebuild`: HOSTILE GROUND-UP REBUILD in place. Before authoring EACH page, restate in one line the ' +
                'owner it holds, the seams and frozen wire names it must honor, and the doctrine laws that bind it — then build ' +
                'against that restatement. Construct in LIFECYCLE order — admit raw once, canonical owner by OWNER_CHOOSER, ' +
                'stacked rail/aspect over a thin pure core, projection, egress, BOTH ingress and egress parameterized; collapse parallel shapes into ' +
                L.collapseInto +
                "; one polymorphic entrypoint per modality. COMPOSE the reports' `apiUsed` at full operator depth, STACK every " +
                '`apiUnderutilized` into the owner, CLOSE every bar finding at its law, CONFIRM no other admitted catalog is ' +
                'missing, and CLOSE the concept capability gaps per BUILD LAW. Then the remaining ladder rungs: land every ' +
                'CORRECTIONS CENSUS row intersecting your pages, and realize the BIGGER-IDEAS entries your pages own at the strongest form disk admits. ' +
                L.modern +
                '; ' +
                L.fileOrg +
                '; high-signal all-backticked prose. Return the fix-log — `deltas` carries every moved symbol/wire as data, ' +
                '`deferred` the backlog rows, both exact. ' +
                HARVEST_LAW,
        ])
        .join('\n\n');

// Critique read law — the audit's binding checklist names its laws, so doctrine reads scope to those sites instead of the
// full-atlas writer ladder; dossiers and recon reports demote to on-disk navigation. Telemetry ground: the full ladder
// overflows the lane window before the first edit and every compaction re-buys the reads.
const CRIT_READ = (L, pkg, dossiers, roster, unmapped, pack) =>
    'READ LAW — scoped at-source reads; each stable input is read ONCE per the lane read discipline. ' +
    '(1) DOCTRINE' +
    (pack
        ? ': the audit law pack `' +
          pack +
          '` carries every binding checklist section VERBATIM with its source anchor — read it IN FULL in large windows; a ' +
          'doctrine page at source opens only when a defect turns on law outside the pack'
        : ', scoped to the audit: `' +
          L.stack +
          '/README.md` [02]-[DOCTRINE] laws + the [03]-[COLLAPSE_SCAN] table, OWNER_CHOOSER (`shapes.md` [01]), RAIL_CHOOSER + ' +
          'boundary conversion (`rails-and-effects.md` [01]-[02]), the aspect two-weave sections (`surfaces-and-dispatch.md` AND ' +
          '`rails-and-effects.md`), and the file-organization law — each read at its site before judging against it; another ' +
          'doctrine page opens only when a defect turns on it') +
    (L.key === 'cs' ? ', and a `docs/stacks/csharp/domain/` shard only when your pages touch its concern' : '') +
    '. (2) TARGETS: your batch pages from CURRENT disk, one at a time per the cadence below. ' +
    '(3) GROUNDING ON DISK — navigation, never mandatory reading: the map dossiers (`' +
    dossiers +
    '`) carry verified two-tier member/seam extracts (consult to verify a member or seam fast); the recon reports point at ' +
    'defects the implement pass already worked (spot-check against disk, never re-derive). ROSTER: ' +
    JSON.stringify(roster) +
    ' UNMAPPED (your own cold read owns these): ' +
    JSON.stringify(unmapped) +
    '. (4) `.api` CATALOGS (`' +
    L.root +
    '/.api/`, `' +
    pkg +
    '/.api/`) open only at the member blocks your pages cite or compose; a disputed spelling resolves via ' +
    L.verify +
    '. OUT OF SCOPE: instruction files (CLAUDE.md, AGENTS.md, `.claude/` config), skill bundles including `docgen` (the ' +
    'PROSE block above carries the standards route), the repo-root README, and any strata or ' +
    'topology hunt — the law above is complete, and a name this brief states is never searched for on disk.';

const critiquePrompt = (L, batch, dossiers, ideate, scopes, roster, unmapped, nav, reg, pack) =>
    [CONTEXT(L), REG[reg].stance(L), BUILD_LAW(L), BODY(L), VERIFY(L), RIPPLE_LAW, CURRENT_STATE, PROSE_COMMENTS(L)]
        .concat(L.mechanics ? [L.mechanics] : [])
        .concat([
            CRIT_READ(L, pkgOf(batch[0].page), dossiers, roster, unmapped, pack),
            LEDGER(scratchBase(pkgOf(batch[0].page), batch[0].i || 0), scopes),
        ])
        .concat(ideate && ideate.fix ? [CORRECTIONS(ideate.fix)] : [])
        .concat([
            'NAVIGATION (facts from the pass that landed these pages — locations only, no assessments; it changes where you look ' +
                'FIRST, never what you conclude): ' +
                JSON.stringify(nav),
            GIT_GROUND,
            REG[reg].audit +
                batch.map((p) => p.page).join(', ') +
                '. FORM YOUR OWN VERDICT FIRST and work PAGE BY PAGE: cold-read a page from CURRENT disk, derive its defects, ' +
                'repair them in place, then advance — pooled unlanded findings degrade at context compaction, so a page closes ' +
                'before the next opens; consult NAVIGATION only after your own pass on a page, to reach its touched seams fast. ' +
                'Audit every fence against the ' +
                'doctrine read at source, never a summary; repair every hit now — a fix, never a ledger note; a cross-file hit is ' +
                'yours per RIPPLE LAW. Your mandate is PREDICATE-POSITIVE: verify each required law holds, cite the clause, ' +
                'repair every miss.\n' +
                '- COLLAPSE_SCAN: run the README [03] table on every fence — any signal triggers the move; shapes sharing an ' +
                'identity regime, admission path, payload timing, or consumer collapse into ONE owner, and a shape survives only ' +
                'on a genuinely distinct discriminant; the table is a FLOOR you hunt past.\n' +
                '- OWNER_CHOOSER (`shapes.md` [01]): re-derive every shape from the 5 discriminants — admission, identity regime, ' +
                'variant arity, payload timing, openness — and replace any non-discriminant-correct owner; kill every parallel ' +
                'DTO, one-field wrapper, field-rename shape, and null/default ghost.\n' +
                '- KNOB_TEST: delete each parameter — where the value reconstructs it, collapse the knob to a policy value or ' +
                'input-shape discriminant; move every timeout/retry/deadline off the signature onto the carrier or a ' +
                'composition-time aspect.\n' +
                '- ASPECTS (`surfaces-and-dispatch.md` AND `rails-and-effects.md`), RAILS + closed-fault + accumulate-vs-abort ' +
                '(`rails-and-effects.md` [01]), STRATA/MEMBERS (' +
                L.modern +
                '; both .api tiers maximized per VERIFY; ' +
                L.fileOrg +
                '): audit each at its owning page.\n' +
                '- SEAM ALIGNMENT: every cross-page symbol the batch composes is checked against the sibling owner as it NOW ' +
                'stands on disk — a landed counterpart is composed, a signature mismatch corrects at the weaker end, a conflict ' +
                'resolves to the stronger form, never a revert.\n' +
                '- CAPABILITY-COMPLETENESS + ILLUSION: verify the body implements what names and prose promise; close any ' +
                'admitted capability the owner omits per BUILD LAW; attack both naivety axes.\n' +
                'Return the batched fix-log — `deltas` and `deferred` exact. ' +
                HARVEST_LAW,
        ])
        .join('\n\n');

const redteamPrompt = (L, batch, dossiers, ideate, scopes, roster, unmapped, nav, crit) =>
    preamble(L, batch, dossiers, ideate, scopes, roster, unmapped, 'claude')
        .concat([
            'NAVIGATION (locations only, no assessments): ' + JSON.stringify(nav),
            crit && crit.ok
                ? 'PRIOR CLAIMS (UNVERIFIED): the critique fixlog is ON DISK at ' +
                  crit.report +
                  ' — read it IN FULL; its edits and verdicts are refutation targets judged against CURRENT disk, never a ' +
                  'settled record. FOLD-FORWARD DUTY: its surviving `seamsTouched`, `deltas`, `deferred`, `beyondMap`, ' +
                  '`indexRows`, and `harvest` rows fold into YOUR return, re-verified against current disk and deduped — your ' +
                  "fix-log is the batch's consolidated record; a dropped critique row is a silent loss."
                : 'PRIOR CLAIMS: the critique lane did not land — your cold attack is the only review this batch gets; judge ' +
                  'from CURRENT disk alone.',
            GIT_GROUND,
            'TASK: ADVERSARIAL ARCHITECT RED-TEAM; fix EACH page in place: ' +
                batch.map((p) => p.page).join(', ') +
                '. Assume the author and critique missed things and their claims are wrong until disk proves them. FORM YOUR ' +
                'OWN ATTACK FIRST — cold-read each page from CURRENT disk before consulting the claims. Your mandate is ' +
                'PREDICATE-NEGATIVE — a pre-mortem, never a second conformance audit:\n' +
                '(A) COUNTERFACTUAL on the core owner/algebra/dispatch — does a denser owner (' +
                L.collapseInto +
                '), a derived table, a parameterized generator over the enumerated space, or a deeper admitted-package ' +
                'primitive (' +
                L.deepPkgs +
                ') collapse the whole fence? A fundamentally stronger design is built, never defended against. ' +
                '(B) ANTICIPATORY_COLLAPSE — compute the diff of the next feature: the next case/dimension/modality lands as ' +
                'one row with every consumer untouched or loudly broken (' +
                L.exhaust +
                '). (C) LONG-TAIL — empty/singular/plural/stream/malformed/concurrent/cancelled/partial-failure/version-skew; ' +
                'accumulate-vs-abort correct for the real boundary; ingress AND egress parameterized. (D) BOUNDARY/STRATA — ' +
                'grade every concern against `libs/.planning/ARCHITECTURE.md` and the branch ARCHITECTURE.md [02]-[SEAMS] ' +
                'ledger (read the ledger, never a summary): a concern owned twice, a downward dependency, a host-type leak, or ' +
                'coupling to a sibling interior is fixed both ends per RIPPLE LAW. (E) SPRAWL + PHANTOMS — hand-re-derived ' +
                'package capability, flat code below the operator depth the packages reach, a phantom member (delete), a thin ' +
                'wrapper; and the inverse: an edit this run made that ADDED surface where doctrine demands collapse is ' +
                'regression you rebuild denser. (F) CAPABILITY-COMPLETENESS + ILLUSION per STANCE and BUILD LAW. ' +
                "(G) GENERATIVE — the capability this batch's work opens at other levels or languages per RIPPLE LAW: realize " +
                'owner-grammar openings now, land new-owner openings as fully-specified IDEAS rows via `indexRows`. Then a FULL ' +
                'COLD RE-REVIEW of every conformance dimension by name — COLLAPSE_SCAN, OWNER_CHOOSER, KNOB_TEST, ASPECTS, ' +
                'RAILS, ' +
                L.modern +
                ', ' +
                L.fileOrg +
                ', both-tier .api maximization, prose + comment hygiene — each judged against CURRENT disk. VERIFY every PRIOR ' +
                'CLAIMS seam landed BOTH ends; make any missed repair yourself. Return the batched fix-log — `deltas` and ' +
                '`deferred` exact. ' +
                HARVEST_LAW,
        ])
        .join('\n\n');

const ideasRealizePrompt = (L, pkg, ideaPath, scopes) =>
    [
        CONTEXT(L),
        REG.claude.stance(L),
        BUILD_LAW(L),
        BODY(L),
        VERIFY(L),
        RIPPLE_LAW,
        CURRENT_STATE,
        PROSE_COMMENTS(L),
        readFirst(L, pkg, ''),
        LEDGER(scratchBase(pkg, 'ideas'), scopes),
        'TASK: IDEAS REALIZATION for `' +
            pkg +
            "` — the package's batches have landed; you implement its bigger-ideas worklist against the CURRENT corpus. Read `" +
            ideaPath +
            '` IN FULL. Per entry, in dossier order, exactly one outcome: (1) REALIZED-PRIOR — current disk already carries ' +
            'the capability fully or in a stronger form: record the landing anchor, never re-build. (2) IMPLEMENTED-NOW — disk ' +
            "admits the entry: build it at the strongest form the doctrine allows, in the owning pages' existing form, growth " +
            'as cases, rows, fields, and operations on existing owners, seams aligned both ends per RIPPLE LAW. (3) CARDED — ' +
            'gated on a decision, a provenance-bound data source, or a frozen wire: one fully-specified card row via ' +
            '`indexRows` targeting the owning IDEAS.md, naming the gate. (4) DECLINED — the value claim fails re-derivation ' +
            'against current disk: the reason rides `summary`. Ambition is the charter here and truth outranks it: never ' +
            'fabricate provenance-bound data, never unfreeze a wire, never force a gated ruling. Return the fix-log — ' +
            '`deltas` exact, `deferred` for cross-batch ripples, cards via `indexRows`. ' +
            HARVEST_LAW,
    ].join('\n\n');

const finderPrompt = (L, pages, i, seams, reg) =>
    [
        CONTEXT(L),
        HUNT,
        EVIDENCE_LAW,
        REG[reg].selfCheck,
        GIT_GROUND,
        REG[reg].finder(i) +
            ' The run just landed a hostile rebuild over these pages: ' +
            JSON.stringify(pages) +
            '. ' +
            REG[reg].finderStance +
            'Read each page IN FULL fresh from CURRENT disk, with the sibling owners each composes and every .api catalog its ' +
            'fences cite (both tiers) — understand what the run changed before judging it. Hunt the classes above across the ' +
            'slice. SMOOTHING: additionally hunt cross-page duplication and split-brain — two pages (or a page and a sibling ' +
            'owner) modeling one concept in parallel shapes, a concern split across pages that one owner should hold, a collapse ' +
            'the run left ungathered — each a `drift` or `naive` finding routed to the canonical owner. SEAM SIGNALS (verify ' +
            'BOTH ends on current disk; an end missing on disk is a finding): ' +
            JSON.stringify(seams) +
            '. STALE DISCARD: judge only CURRENT disk — a defect already resolved, at either end of a seam, is DROPPED, never ' +
            'reported. Findings are INFORMATION for the terminal fixer: name the defect, the law or catalog member it violates, ' +
            'the exact anchor, and the grade — never the resulting code, a fence sketch, or a ruled design. Return typed ' +
            'anchored graded findings.',
    ].join('\n\n');

const govFinderPrompt = (L, pkgs, pages, rows, reg) =>
    [
        CONTEXT(L),
        HUNT,
        EVIDENCE_LAW,
        REG[reg].selfCheck,
        REG[reg].gov +
            " Audit the owning packages' index surface end to end for these packages: " +
            JSON.stringify(pkgs) +
            " — each package's README.md and ARCHITECTURE.md (at the path before `/.planning/`), its central manifest rows, and " +
            'its `.api/` anchors — against the landed page set: ' +
            JSON.stringify(pages) +
            '. A disagreement between any two surfaces is a `drift` finding; a claim about a landed page is verified against the ' +
            'page on CURRENT disk, never against the claim. PENDING INDEX ROWS — the terminal fixer applies these after you; a ' +
            'gap these rows already close is DROPPED, not reported: ' +
            JSON.stringify(rows) +
            '. Return typed anchored graded findings.',
    ].join('\n\n');

const backlogVerifierPrompt = (rows, orphans, census, reg) =>
    [
        ROOT_LAW,
        'Rasm monorepo — the libs/ planning corpora. A hostile rebuild just landed; its build stages deferred cross-scope work ' +
            'as typed rows, and the corrections censuses carry folder-wide rows the writers only partially claimed.',
        'TASK: BACKLOG VERIFIER (read-only over the corpus; investigate, do NOT edit). Re-verify every candidate row below ' +
            'against CURRENT disk and return the consolidated work list the terminal fixer consumes — final, deduped, stale-free.',
        'DEFERRED ROWS (build stages): ' + JSON.stringify(rows),
        orphans.length
            ? 'ORPHANED CRITIQUE FIXLOGS (read each IN FULL from disk; their surviving deferred rows join the candidate pool): ' +
              JSON.stringify(orphans)
            : '',
        'CORRECTIONS CENSUS dossiers (read each IN FULL; every row joins the candidate pool): ' + JSON.stringify(census),
        'PER CANDIDATE: open the named files on CURRENT disk. A row disk already resolves is CULLED with the resolving anchor ' +
            'as its receipt. Rows naming the same defect across sources MERGE into one row carrying every anchor and a joined ' +
            'source tag. A survivor states the defect as FACT with owner, files, and typed anchors — information and constraint ' +
            'boundary, never a prescribed fix. Group survivors by owner: shared owners and registries before consumers.',
        REG[reg].selfCheck,
    ]
        .filter(Boolean)
        .join('\n\n');

const ideasCollatorPrompt = (sets, reg) =>
    [
        ROOT_LAW,
        'Rasm monorepo — the libs/ planning corpora. The Ideate phase authored one bigger-ideas dossier per package; the build ' +
            'stages realized entries at their own discretion.',
        'TASK: IDEAS COLLATOR (read-only over the corpus; investigate, do NOT edit). Read every dossier IN FULL — ' +
            JSON.stringify(sets) +
            ' — and status EVERY entry against CURRENT disk into one collated ledger: realized (the run landed the capability ' +
            'fully or in a form at least as strong — anchor the landing), unrealized (still valuable and absent — re-derive the ' +
            'ground from current disk, never copy the stale dossier anchor), or superseded (current disk carries a stronger ' +
            'form or the doctrine forbids it — anchor the superseding fact). The dossiers are PRE-RUN snapshots; every judgment ' +
            're-derives from disk. Entries stay ambition and information — never a prescription or a ruled design — and the ' +
            'ledger is TOTAL: one row per dossier entry, none dropped.',
        REG[reg].selfCheck,
    ].join('\n\n');

const fixerPrompt = (langs, roster, unmapped, rows, backlog, failed, pages, orphans, census, round, work, ideasLedger) =>
    [
        ROOT_LAW,
        round
            ? 'DRAIN ROUND ' +
              round +
              ' — every backlog row below was verified STILL-OPEN by the prior round; the index rows, finder reports, and orphan ' +
              'fixlogs are already consumed. Fix each row at its root NOW; a row you genuinely cannot land carries its named ' +
              'blocker and owner in `remaining`.'
            : '',
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
                .join('\n'),
        HUNT,
        'CATALOG-APPEND LAW — a page-attested member that verifies against the real surface but lacks a row in the owning ' +
            '`.api` catalog closes by appending the catalog row; stripping a TRUE page attestation to match a lagging catalog ' +
            'is the rejected form.',
        'DELEGATION — three sanctioned shapes, every fixlog row still yours and no delegate nesting further: ' +
            '(a) READ-ONLY verification fan — bulk anchor re-opens behind rejections, member spot-checks, seam both-end reads, ' +
            'returning verdicts. (b) RULED TRANSCRIPTION — edits you have already decided to exact old->new text (index-row ' +
            'application on non-index files, symbol propagation, spelling repairs) fan to scoped delegates carrying the precise ' +
            'file+anchor+replacement spec — zero judgment left, zero corpus re-reading needed, and you spot-check each landing. ' +
            '(c) DISJOINT CLUSTERS — when the verified work list is large and partitions into disjoint-file clusters of ' +
            'judgment work, full-context writer delegates take whole clusters: each receives its cluster rows and ' +
            'the artifact paths it needs, composes its language doctrine in full before writing (a writer without the doctrine ' +
            'read never writes), and holds a write scope disjoint from yours and each other. A work list spanning multiple ' +
            'packages partitions at the package boundary by DEFAULT — dispatch one delegate per package (cap four, remainder ' +
            'packages pooled onto the nearest-language delegate) the moment the list is read, not after your own pass stalls; ' +
            'rows crossing a package boundary, and every collapse or rename, stay YOURS. The owning-package index docs, ' +
            'IDEAS.md, and the central manifests never delegate. A delegated row counts resolved ONLY after you verify its ' +
            'edits on current disk; a delegate that landed nothing returns the row to your own hands in the same round — a ' +
            'row parked in `remaining` on unverified delegate work is a fabricated blocker. Write delegates ride the Agent ' +
            'tool with an explicit landing contract, never a fire-and-forget CLI dispatch.',
        GIT_GROUND,
        "TASK: TERMINAL FIX (WRITER — the run's LAST agent, nothing follows you): full write authority over the landed corpus, " +
            'libs-wide ripple authority with the expand-form bound LIFTED (collapse, rename, and contract are yours now that no ' +
            "sibling writer runs), and the run's SOLE writer for the owning-package index docs (ARCHITECTURE.md + README.md), " +
            'IDEAS.md, and the central manifests. Landed pages: ' +
            JSON.stringify(pages) +
            '.\n' +
            '(1) INDEX ROWS: apply every reported row to its owning doc exactly once — dedupe semantically identical rows, keep ' +
            "each doc's section grammar, verify every landed page is truthfully reflected; a central-manifest row hand-edits the " +
            'grouped manifest at the SYMBOL anchor (never a line number), preserving label-group order; an IDEAS row lands as a ' +
            'fully-specified card in the named IDEAS.md: ' +
            JSON.stringify(rows) +
            '.\n' +
            (work
                ? '(2) VERIFIED WORK DOSSIER — ON DISK at ' +
                  work +
                  ': every build-stage deferred row, census row, and orphaned-fixlog row pre-verified against current disk by ' +
                  'the backlog verifier — stale culled with receipts, duplicates merged, survivors grouped by owner. Read it IN ' +
                  'FULL; every live row is yours: re-open its anchors before the edit (freshness stays yours), fix at root or ' +
                  'reject with reason. Spot-check a sample of the culled receipts; never re-litigate the culled set.\n'
                : '(2) DEFERRED BACKLOG (second-order and cross-batch ripples — re-verify each {files, claim} on current disk, fix ' +
                  'what holds, reject what disk already resolved): ' +
                  JSON.stringify(backlog) +
                  '.\n' +
                  '(2b) ORPHANED CRITIQUE FIXLOGS (batches whose redteam never landed, so these rows were never folded forward — read ' +
                  "each IN FULL from disk, drain the seam/deferred/index rows under the same law, and fold each fixlog's surviving " +
                  'harvest rows into your own `harvest` return, re-verified and deduped): ' +
                  JSON.stringify(orphans) +
                  '.\n' +
                  '(2c) CORRECTIONS CENSUS dossiers (the writers landed only the rows intersecting their own pages — read each IN ' +
                  'FULL; every row NOT already resolved on current disk is yours: land it at its root or reject with reason): ' +
                  JSON.stringify(census) +
                  '.\n') +
            '(3) FINDER REPORTS — products ON DISK as JSON report files; the ROSTER receipts are navigation, never the product. ' +
            "CONSUMPTION, in order: (a) UNMAPPED scope is your direct-hunt queue — a failed finder's territory gets your own " +
            'cold read first; (b) read every ok report IN FULL from disk, governance finders before page slices — group findings ' +
            'by `claimKey` (the same key across lanes is ONE defect with corroborating evidence) and order work by `severity` ' +
            'then `owner` (shared owners and registries before consumers, cross-folder seams before local prose); (c) each ' +
            'finding is a SIGNAL, not law: re-open its anchors before editing — anchors behind an edit, cited members, seams, ' +
            'and manifest rows re-verify MANDATORY; (d) `mechanism`/`owner`/`reject`/`acceptance` are the constraint boundary — ' +
            'honor the owner and rejected forms, but the DESIGN is yours: implement the STRONGEST resolution the boundary ' +
            'admits, never a single-point patch, landing the denser root-level reconstruction where the implied fix is weak; a ' +
            'finding with a dead anchor, already resolved on disk, or graded `hypothetical` with no substantive re-derivation is ' +
            'rejected with reason. UNMAPPED: ' +
            JSON.stringify(unmapped) +
            ' ROSTER: ' +
            JSON.stringify(roster) +
            '.\n' +
            '(4) OWN HUNT: hunt PAST the signal list — the hunt classes over the landed pages and governance surface — and fix ' +
            'what the finders missed; `beyond` enumerates those fixes, and an empty `beyond` attests the hunt found nothing, ' +
            'never that it did not run.\n' +
            (ideasLedger
                ? '(5) IDEAS REMAINDER — the collated ideas ledger ON DISK at ' +
                  ideasLedger +
                  ' statuses every bigger-ideas entry against current disk. After the defect drain, realize each unrealized ' +
                  'entry at the strongest form disk admits under the ambition law: an entry you decline is not a defect, ' +
                  'provenance-bound data is never fabricated, and the ideas-disposition writer rules final outcomes after you.\n'
                : '') +
            'Every ripple an edit exposes is YOURS in the same pass — seam counterparts both ends, consumer sites, index docs, ' +
            "manifest rows, .api anchors; wire-canonical names stay frozen; a foreign-language repair holds that branch's " +
            'doctrine bar. FAILED PAGES (reported, not landed — never author them here; correct any claim that pretends they ' +
            'landed): ' +
            JSON.stringify(failed) +
            '. Return the final fixlog — `remaining` carries ONLY rows verified still-open and genuinely blocked, each naming ' +
            'its blocker and owner; a row disk already resolved is culled with proof in `rejected`, and an empty `remaining` ' +
            'attests the drain closed. ' +
            HARVEST_LAW,
    ]
        .filter(Boolean)
        .join('\n\n');

const dispositionPrompt = (sets, pages, ledgerPath) =>
    [
        ROOT_LAW,
        'Rasm monorepo — the libs/ planning corpora. The run just landed a hostile rebuild over these pages: ' + JSON.stringify(pages) + '.',
        ledgerPath
            ? 'NAVIGATION: the collated ideas ledger ON DISK at ' +
              ledgerPath +
              ' statuses every entry as of its pre-fixer collation — the fixer may have realized more since, so it routes your ' +
              'reading order and nothing else; every outcome re-derives from CURRENT disk.'
            : '',
        'TASK: IDEAS DISPOSITION (WRITER — the sole IDEAS.md author at this point of the run). The Ideate phase produced one ' +
            'bigger-ideas dossier per package — ambition worklists the batch writers realized at their own discretion. Read every ' +
            'dossier IN FULL: ' +
            JSON.stringify(sets) +
            '. Every entry ends in exactly ONE outcome; a silently dropped idea is the defect this stage exists to prevent. The ' +
            'dossiers are PRE-RUN snapshots — their anchors are stale; every judgment and every landed claim re-derives from ' +
            'CURRENT disk, never from the snapshot.',
        '(1) REALIZED — open the owner pages the entry names on CURRENT disk; the run landed the capability (fully, or partially ' +
            'in a form at least as strong as the entry points toward): record outcome realized with the landing anchor.',
        '(2) REJECTED — current disk supersedes the entry, the doctrine or an architecture boundary forbids it, or its value ' +
            'claim does not survive re-derivation against the landed corpus: record outcome rejected with the reason.',
        '(3) CARDED — the entry remains genuinely valuable and unrealized: author it as a fully-formed card in the owning ' +
            "surface's `[1]-[OPEN]`, deduped against the cards already there (an existing card covering it is outcome carded " +
            'with `where` naming that card). A folder-owned idea lands in the owning package IDEAS.md; an idea coupling two ' +
            'same-language packages lands in the branch `libs/<lang>/.planning/IDEAS.md`; a cross-language idea lands in ' +
            '`libs/.planning/IDEAS.md`. Card form per the authoring standard: a bracketed slug leader with bullets carrying the ' +
            'capability, what it unlocks, and the gap or technique it draws on — ambition and information, never a prescription, ' +
            'a fence sketch, or a ruled design.',
        '(4) POOL HYGIENE — where an outcome touches an existing IDEAS.md open card (a realized entry an open card covers: the ' +
            'card moves to `[2]-[CLOSED]` with a one-line disposition; a carded entry an open card already covers: dedupe onto ' +
            "that card), reconcile the card in the same pass. Cards the run's entries never touch stay untouched.",
        'Return entries (one row per dossier entry — the disposition is TOTAL), files (every IDEAS.md edited), summary.',
    ]
        .filter(Boolean)
        .join('\n\n');

// --- [COMPOSITION] ---------------------------------------------------------------------

if (REJECTED.length) log('Rejected targets outside libs/{csharp,python,typescript}: ' + REJECTED.join(', '));
if (!TARGETS.length) {
    log('No targets — pass a target path, an array of paths, or {targets}. Empty args is a no-op.');
    return { targets: [], total: 0 };
}

phase('Plan');
const plan = await slot(() => agent(planPrompt(), wopts('plan', 'Plan', 'opus', PLAN_SCHEMA)));
const PAGES = normalizePages(plan);
const UNRESOLVED = (plan && plan.unresolved) || [];
if (UNRESOLVED.length) log('Unresolved targets (mis-scoped or renamed): ' + UNRESOLVED.join(', '));
const LANGS_IN = [...new Set(PAGES.map((p) => langOf(p.page)).filter(Boolean))];
log(
    'Plan: ' +
        PAGES.length +
        ' pages (' +
        PAGES.filter((p) => p.kind === 'new').length +
        ' new, ' +
        PAGES.filter((p) => p.kind === 'rebuild').length +
        ' rebuild) across ' +
        LANGS_IN.join('+') +
        '; CAP=' +
        CAP +
        ', BATCH_MAX=' +
        BATCH_MAX,
);
if (!PAGES.length) {
    log('No pages resolved under the targets');
    return { targets: TARGETS, total: 0 };
}

// Static run topology — the unit split, batch packing, and cross-batch scope ledger derive from page paths
// alone, before any lane runs, so every package chain launches against the full SCOPES map.
const PKGS = [...new Set(PAGES.map((p) => pkgOf(p.page)))];
// An oversize sub-folder splits into SEGMENTS under the dual ceiling (page count AND LOC tonnage) here, once — map lanes and
// batches both consume the segmented units, so every batch's dossiers cover exactly its pages, the mapper fan scales with the
// writer fan, and no unit's pages alone can overflow a downstream review lane's context window.
const UNITS = PKGS.flatMap((pkg) => {
    const pkgPages = PAGES.filter((p) => pkgOf(p.page) === pkg);
    return [...new Set(pkgPages.map((p) => subOf(p.page)))].flatMap((sub) => {
        const pages = pkgPages.filter((p) => subOf(p.page) === sub);
        const segs = sizeChunk(pages);
        return segs.map((seg, i) => {
            const name = sub + (segs.length > 1 ? '.' + (i + 1) : '');
            return { pkg, sub, name, key: pkg + '|' + name, tag: pkg.split('/').pop() + '.' + name, pages: seg };
        });
    });
});
// Batch composition packs WHOLE sub-folder units (in plan order) up to BATCH_MAX, splitting only an oversize unit — a batch's
// ownership seam then aligns with its map dossiers instead of slicing across sub-folders; a batch carries its source units so
// its dossier roster is exact, never re-derived from page paths.
const packBatches = (units, max) => {
    const out = [];
    let cur = [];
    let n = 0;
    let l = 0;
    for (const u of units) {
        const ul = u.pages.reduce((a, p) => a + p.lines, 0);
        if (cur.length && (n + u.pages.length > max || l + ul > BATCH_LOC)) {
            out.push(cur);
            cur = [];
            n = 0;
            l = 0;
        }
        cur.push(u);
        n += u.pages.length;
        l += ul;
    }
    if (cur.length) out.push(cur);
    return out;
};
const BATCHES = PKGS.flatMap((pkg) =>
    packBatches(
        UNITS.filter((u) => u.pkg === pkg),
        BATCH_MAX,
    ).map((units, i) => ({ pkg, i, units, pages: units.flatMap((u) => u.pages) })),
);
const SCOPES = JSON.stringify(BATCHES.map((b) => ({ batch: b.pkg.split('/').pop() + ':b' + b.i, pages: b.pages.map((p) => p.page) })));

// AUDIT LAW PACKS — one per landed language, compiled ONCE and reused by every critique lane: the audit checklist's
// binding sections extracted VERBATIM with source anchors into one scratch artifact, read in a few large windows
// instead of re-assembled from the atlas per batch. Verbatim extraction keeps the at-source law intact — the pack IS
// the source text, never a summary. A dead pack lane falls back to at-source scoped reads in CRIT_READ.
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
                    codexEffort: 'low',
                    model: 'gpt-5.6-terra',
                },
            ),
        ),
    ).catch(() => null);
}

phase('Map');
phase('Ideate');
phase('Build');
// PER-PACKAGE PIPELINE — Map, Ideate, and Build are package-local stages, never run barriers: a package's
// ideate fires the moment ITS unit lanes land and its batch chains the moment its ideate lands, so no
// package waits on a sibling's slowest lane. Every agent carries its explicit phase label, the slot
// scheduler is the only cross-package governor, SCOPES + the seam ledger own cross-batch coordination,
// and Close is the one whole-run barrier.
// Corpus map ONCE per SUB-FOLDER unit, reused by every batch touching that unit: a native deep-map lane (context/seams)
// beside a two-tier .api inventory lane PER `.planning/<sub>` — package-level mapping dilutes depth on a large
// package and starves the batches of per-page grounding. Products are per-unit dossiers + reports on disk; receipts on the wire.
const unitMap = {};
const mapUnit = async (u) => {
    const L = Lof(u.pkg);
    const unitPages = u.pages.map((p) => Object.assign({}, p, { i: 0 }));
    const scope = unitPages.map((p) => p.page);
    const tag = u.tag;
    const ctxDossier = dossierPath('map:ctx:' + tag);
    const apiDossier = dossierPath('map:api:' + tag);
    const [ctx, api] = await Promise.all([
        slot(() =>
            recon(
                (reg) => ctxLensPrompt(L, unitPages, ctxDossier, reg),
                ropts('map:ctx:' + tag, 'Map', CTX_SCHEMA, scope, { arr: 'worklist', group: 'kind' }, { native: true, nativeModel: 'opus' }),
            ),
        ),
        slot(() =>
            recon(
                (reg) => apiLensPrompt(L, unitPages, apiDossier, reg),
                ropts('map:api:' + tag, 'Map', API_SCHEMA, scope, { arr: 'worklist' }, { writes: true, model: 'gpt-5.6-terra' }),
            ),
        ),
    ]);
    unitMap[u.key] = { ctx, api, ctxDossier, apiDossier };
};
// TWO lanes per owning package with disjoint charters: a corrections census (the fix addendum the batches land as rung 3)
// and a bigger-ideas worklist (the capability ambition, rung 4). One merged log regresses to a fixlog and the ambition dies.
// Either lane absent (dead map or dead ideate), the executors run without that rung.
const pkgIdeate = {};
const ideatePkg = async (pkg) => {
    const L = Lof(pkg);
    const tag = pkg.split('/').pop();
    const mapIndex = UNITS.filter((u) => u.pkg === pkg)
        .map((u) => ({
            sub: u.name,
            deepMap: (unitMap[u.key].ctx?.ok && unitMap[u.key].ctxDossier) || null,
            inventory: (unitMap[u.key].api?.ok && unitMap[u.key].apiDossier) || null,
        }))
        .filter((r) => r.deepMap || r.inventory);
    if (!mapIndex.length) {
        pkgIdeate[pkg] = { fix: '', idea: '' };
        return;
    }
    const fixDossier = dossierPath('ideate:fix:' + tag);
    const ideaDossier = dossierPath('ideate:idea:' + tag);
    const [fix, idea] = await Promise.all([
        slot(() => agent(correctionsPrompt(L, pkg, mapIndex, fixDossier), wopts('ideate:fix:' + tag, 'Ideate', 'opus', RECEIPT))),
        slot(() => agent(ideasPrompt(L, pkg, mapIndex, ideaDossier), wopts('ideate:idea:' + tag, 'Ideate', 'fable', RECEIPT))),
    ]);
    pkgIdeate[pkg] = { fix: (fix && fix.ok && fixDossier) || '', idea: (idea && idea.ok && ideaDossier) || '' };
    log(
        'Ideate ' +
            tag +
            ': ' +
            (pkgIdeate[pkg].fix ? (fix.entries || 0) + ' correction(s)' : 'no census') +
            ' + ' +
            (pkgIdeate[pkg].idea ? (idea.entries || 0) + ' bigger-idea(s)' : 'no ideas'),
    );
};

// Per batch, the chain: page-scoped bar lens (judgment-weighted, like the close finders), implement, critique,
// redteam — ctx/api grounding reused from the owning unit dossiers.
const runBatch = async (b) => {
    const tag = b.pkg.split('/').pop() + ':b' + b.i;
    const L = Lof(b.pkg);
    const batch = b.pages.map((p) => Object.assign({}, p, { i: b.i }));
    const pageScope = batch.map((p) => p.page);
    // ctx + api grounding come from the Map lanes (per-unit-segment, reused); only the page-scoped bar lens runs per batch.
    const pms = b.units.map((u) => unitMap[u.key]).filter(Boolean);
    const bar = await slot(() =>
        recon(
            (reg) => barLensPrompt(L, batch, reg),
            ropts(
                'recon:bar:' + tag,
                'Build',
                BAR_SCHEMA,
                pageScope,
                { arr: 'findings', group: 'severity' },
                {
                    codexEffort: 'medium',
                },
            ),
        ),
    );
    const roster = pms
        .flatMap((m) => [m.ctx, m.api])
        .concat([bar])
        .filter(Boolean);
    // A failed Map lane carries its WHOLE unit as scope; intersect with this batch so cold-read stays on its own pages.
    const unmapped = roster
        .filter((r) => !r.ok)
        .flatMap((r) => (r.scope || []).filter((sc) => pageScope.includes(sc)).map((sc) => ({ lane: r.lane, scope: sc })));
    if (unmapped.length)
        log(
            tag +
                ' — FAILED lens(es): ' +
                roster
                    .filter((r) => !r.ok)
                    .map((r) => r.lane)
                    .join(', '),
        );
    const dossiers = pms
        .flatMap((m) => [m.ctx && m.ctx.ok && m.ctxDossier, m.api && m.api.ok && m.apiDossier])
        .filter(Boolean)
        .join('`, `');
    const ideate = pkgIdeate[b.pkg] || { fix: '', idea: '' };
    const fix = await slot(() =>
        agent(implementPrompt(L, batch, dossiers, ideate, SCOPES, roster, unmapped), wopts('impl:' + tag, 'Build', 'fable', FIXLOG_SCHEMA)),
    );
    if (!fix) return { pkg: b.pkg, pages: b.pages, fix: null, crit: null, rt: null }; // failure isolation: a dead implement skips its reviews
    // Critique: a write lane running the full conformance audit in place;
    // fixlog to disk, receipt on the wire; the redteam reads the fixlog from disk and folds its rows forward.
    // The critique preamble drops the IDEAS rung (idea: '') — an in-place conformance audit consumes the census,
    // never the ambition worklist; ambition realization is the implement's rung 4 and the redteam's mandate (G).
    const packR = LAWPACK[L.key] ? await LAWPACK[L.key] : null;
    const pack = packR && packR.ok ? lawPackPath(L.key) : '';
    // Critique nav trims to {files, seams}: deltas/deferred are the implement's own edits the audit re-derives from disk.
    const critNav = (() => {
        const n = navOf([fix]);
        return { files: n.files, seams: n.seams };
    })();
    const crit = await slot(() =>
        recon(
            (reg) => critiquePrompt(L, batch, dossiers, { fix: ideate.fix, idea: '' }, SCOPES, roster, unmapped, critNav, reg, pack),
            ropts('crit:' + tag, 'Build', REVIEW_SCHEMA, pageScope, { arr: 'files' }, { writes: true, fix: true, nativeModel: 'fable' }),
        ),
    );
    const critR = crit && crit.ok ? crit : null;
    const rt = await slot(() =>
        agent(
            redteamPrompt(L, batch, dossiers, ideate, SCOPES, roster, unmapped, navOf([fix]), critR),
            wopts('rt:' + tag, 'Build', 'fable', REVIEW_SCHEMA),
        ),
    );
    return { pkg: b.pkg, pages: b.pages, fix, crit: critR, rt };
};
const built = (
    await Promise.all(
        PKGS.map(async (pkg) => {
            try {
                const pkgUnits = UNITS.filter((u) => u.pkg === pkg);
                await Promise.all(pkgUnits.map(mapUnit));
                const live = pkgUnits.filter((u) => {
                    const m = unitMap[u.key] || {};
                    return (m.ctx && m.ctx.ok) || (m.api && m.api.ok);
                }).length;
                log('Map ' + pkg.split('/').pop() + ': ' + pkgUnits.length + ' unit segment(s) mapped; ' + live + ' with a live dossier');
                await ideatePkg(pkg);
                const out = (
                    await Promise.all(
                        BATCHES.filter((b) => b.pkg === pkg)
                            .map(runBatch)
                            .map((p) => p.catch(() => null)),
                    )
                ).filter(Boolean);
                // Per-package IDEAS REALIZATION: one writer after the package's last batch implements the bigger-ideas
                // worklist against the landed corpus — realization gets a dedicated context instead of starving behind
                // defect work; gated entries route to IDEAS.md as cards via indexRows; Close audits the remainder.
                const ideaPath = (pkgIdeate[pkg] && pkgIdeate[pkg].idea) || '';
                if (ideaPath && out.some((d) => d.fix)) {
                    const realize = await slot(() =>
                        agent(
                            ideasRealizePrompt(Lof(pkg), pkg, ideaPath, SCOPES),
                            wopts('ideas:' + pkg.split('/').pop(), 'Build', 'fable', FIXLOG_SCHEMA),
                        ),
                    );
                    if (realize) out.push({ pkg, pages: [], fix: realize, crit: null, rt: null });
                }
                return out;
            } catch (e) {
                log('Package chain FAILED (' + pkg + '): ' + ((e && e.message) || e));
                return [];
            }
        }),
    )
).flat();
const CENSUS_PATHS = PKGS.map((pkg) => pkgIdeate[pkg] && pkgIdeate[pkg].fix).filter(Boolean);
const LANDED = built.filter((d) => d.fix).flatMap((d) => d.pages.map((p) => p.page));
// FAILED covers both a dead implement (a batch entry with no fix) and a dead package chain (pages in no entry).
const FAILED = PAGES.map((p) => p.page).filter((pg) => !LANDED.includes(pg));
// The critique fixlog lives on disk; the redteam folds its rows into its own return, so aggregation
// reads fix + rt only. A batch whose redteam died leaves the critique fixlog ORPHANED for the fixer.
const ROWS = built.flatMap((d) => ((d.fix && d.fix.indexRows) || []).concat((d.rt && d.rt.indexRows) || []));
const SEAM_ROWS = built.flatMap((d) => ((d.fix && d.fix.seamsTouched) || []).concat((d.rt && d.rt.seamsTouched) || []));
const BACKLOG = built.flatMap((d) => ((d.fix && d.fix.deferred) || []).concat((d.rt && d.rt.deferred) || []));
const ORPHANS = built.filter((d) => d.crit && !d.rt).map((d) => d.crit.report);
log(
    'Build: ' +
        LANDED.length +
        '/' +
        PAGES.length +
        ' pages landed across ' +
        BATCHES.length +
        ' batch(es); ' +
        SEAM_ROWS.length +
        ' seam row(s), ' +
        BACKLOG.length +
        ' deferred backlog row(s)' +
        (FAILED.length ? ' — FAILED (reported, run continues): ' + FAILED.join(', ') : ''),
);
if (!LANDED.length) {
    log('Nothing landed — no close to run');
    return { targets: TARGETS, batches: BATCHES.length, landed: 0, failed: FAILED };
}

phase('Close');
const LANDED_LANGS = [...new Set(LANDED.map((p) => langOf(p)).filter(Boolean))];
const finderTasks = LANDED_LANGS.flatMap((k) => {
    const langPages = LANDED.filter((p) => langOf(p) === k);
    const langSeams = SEAM_ROWS.filter((s) => langOf(s.file) === k || langOf(s.counterpart) === k);
    return chunk(langPages, FINDER_PAGES)
        .map((pages, i) => ({ gov: false, lang: k, pages, seams: langSeams, i }))
        .concat([{ gov: true, lang: k, pkgs: [...new Set(langPages.map(pkgOf))], pages: langPages }]);
});
// Two consolidation lanes ride the finder fan CONCURRENTLY: the backlog verifier turns every deferred, census,
// and orphaned-fixlog candidate into ONE pre-verified work list (stale culled with receipts, duplicates merged),
// and the ideas collator statuses every bigger-ideas entry against current disk into ONE ledger — the fixer then
// consumes final lists and the disposition writer rules outcomes, neither re-litigating the pool.
const IDEA_SETS = PKGS.map((pkg) => ({ pkg, path: (pkgIdeate[pkg] && pkgIdeate[pkg].idea) || '' })).filter((r) => r.path);
const [found, work, ledger] = await Promise.all([
    Promise.all(
        finderTasks.map((t) =>
            slot(() =>
                // Finders are terminal-consumed (the fixer re-verifies anchors but never re-hunts the coverage),
                // so the fan runs at a judgment-weighted effort.
                t.gov
                    ? recon(
                          (reg) => govFinderPrompt(LANG[t.lang], t.pkgs, t.pages, ROWS, reg),
                          ropts(
                              'finder:gov:' + t.lang,
                              'Close',
                              FINDINGS_SCHEMA,
                              t.pkgs,
                              { arr: 'findings', group: 'class' },
                              {
                                  codexEffort: 'medium',
                              },
                          ),
                      )
                    : recon(
                          (reg) => finderPrompt(LANG[t.lang], t.pages, t.i, t.seams, reg),
                          ropts(
                              'finder:' + t.lang + ':s' + t.i,
                              'Close',
                              FINDINGS_SCHEMA,
                              t.pages,
                              { arr: 'findings', group: 'class' },
                              {
                                  codexEffort: 'medium',
                              },
                          ),
                      ),
            ).catch(() => null),
        ),
    ).then((r) => r.filter(Boolean)),
    BACKLOG.length || ORPHANS.length || CENSUS_PATHS.length
        ? slot(() =>
              recon(
                  (reg) => backlogVerifierPrompt(BACKLOG, ORPHANS, CENSUS_PATHS, reg),
                  ropts(
                      'verify:backlog',
                      'Close',
                      WORK_SCHEMA,
                      [],
                      { arr: 'live', group: 'source' },
                      {
                          codexEffort: 'medium',
                      },
                  ),
              ),
          ).catch(() => null)
        : null,
    IDEA_SETS.length
        ? slot(() =>
              recon(
                  (reg) => ideasCollatorPrompt(IDEA_SETS, reg),
                  ropts(
                      'collate:ideas',
                      'Close',
                      LEDGER_SCHEMA,
                      [],
                      { arr: 'entries', group: 'status' },
                      {
                          codexEffort: 'medium',
                      },
                  ),
              ),
          ).catch(() => null)
        : null,
]);
const WORK = (work && work.ok && work.report) || ''; // the pre-verified work list on disk; '' falls back to the raw sets
const IDEAS_LEDGER = (ledger && ledger.ok && ledger.report) || '';
const FOUND = found.filter((f) => f.ok).reduce((a, f) => a + f.entries, 0);
const UNMAPPED = found.filter((f) => !f.ok).flatMap((f) => f.scope.map((sc) => ({ lane: f.lane, scope: sc })));
log(
    'Close: ' +
        FOUND +
        ' finding(s) across ' +
        found.filter((f) => f.ok).length +
        '/' +
        found.length +
        ' finder(s)' +
        (UNMAPPED.length
            ? ' — FAILED: ' +
              found
                  .filter((f) => !f.ok)
                  .map((f) => f.lane)
                  .join(', ')
            : '') +
        '; ' +
        ROWS.length +
        ' index row(s) + ' +
        BACKLOG.length +
        ' backlog row(s) pending',
);
// Terminal DRAIN LOOP: one serial closer per round takes the full residual set, verifies every
// row against live disk (freshness is its duty — no concurrent writers, no collisions), fixes at root,
// and loops until the set is empty; a round without shrinkage stops the loop with the blocked set final.
let fixer = null;
let fixerHarvest = [];
let residuals = WORK ? [] : BACKLOG;
let orphanQueue = WORK ? [] : ORPHANS;
let lastOpen = Infinity;
for (let round = 0; round < DRAIN_ROUNDS; round++) {
    fixer = await slot(() =>
        agent(
            fixerPrompt(
                LANDED_LANGS,
                round ? [] : found,
                round ? [] : UNMAPPED,
                round ? [] : ROWS,
                residuals,
                FAILED,
                LANDED,
                orphanQueue,
                round || WORK ? [] : CENSUS_PATHS,
                round,
                round ? '' : WORK,
                round ? '' : IDEAS_LEDGER,
            ),
            wopts(round ? 'fixer:r' + round : 'fixer', 'Close', 'fable', FIXER_SCHEMA),
        ),
    );
    if (!fixer) break; // dead round: the fed-in residual and orphan sets survive to the run return, never zeroed by a lost closer
    fixerHarvest = fixerHarvest.concat(fixer.harvest || []);
    const open = fixer.remaining || [];
    orphanQueue = [];
    residuals = open;
    if (!open.length || open.length >= lastOpen) break;
    lastOpen = open.length;
}
// TERMINAL PAIR — two disjoint-surface writers run concurrently after the drain loop closes.
// IDEAS DISPOSITION (the sole IDEAS.md author now that the fixer is done) gives every bigger-ideas dossier
// entry exactly one outcome — realized on disk, carded into the owning IDEAS.md, or rejected with reason —
// so no idea silently evaporates with the scratch dir. DOCTRINE LANDER is the run's durable-learning
// terminal — pooled harvest nominations adjudicated against the live doctrine surfaces; refutation-first,
// land-nothing legal, admission law owned by docs/laws.
const HARVEST_ROWS = built.flatMap((d) => ((d.fix && d.fix.harvest) || []).concat((d.rt && d.rt.harvest) || [])).concat(fixerHarvest);
const [ideas, doctrine] = await Promise.all([
    IDEA_SETS.length
        ? slot(() => agent(dispositionPrompt(IDEA_SETS, LANDED, IDEAS_LEDGER), wopts('ideas:disposition', 'Close', 'fable', IDEAS_DISP_SCHEMA)))
        : null,
    HARVEST_ROWS.length
        ? slot(() =>
              agent(
                  'TASK: DOCTRINE LANDER — the durable-learning terminal of this run. Read `docs/laws/README.md` ' +
                      'FIRST — it owns the corpus admission and page-shape law; obey it over any restatement. Load ' +
                      'the `docgen` skill via the Skill tool BEFORE any durable edit; load ' +
                      '`mermaid-diagramming` before touching any diagram. ' +
                      "NOMINATIONS (unverified, biased toward their authors' own work — refute by default): " +
                      JSON.stringify(HARVEST_ROWS) +
                      '\nADJUDICATE each row per the admission bar: cold-read its target surface IN FULL, verify its anchors on ' +
                      'CURRENT disk; LAND NOTHING is a first-class verdict. A landing takes the target surface at its OWN form and ' +
                      'bar: refine-over-add per the admission ladder (harden the existing clause before extending a page before ' +
                      'minting one); a TRUE nomination weakly stated lands at its strongest true generalization — the nominator ' +
                      'phrasing is a draft, never the ceiling; and a `stacks` landing conforms to the page-craft grammar — where ' +
                      'the lesson is code-shaped it hardens the owning family card and its snippet or fence exemplar, never a ' +
                      'prose bullet appended to a fence-taught region.\n' +
                      'TOPOLOGY RE-PROOF: re-verify every `docs/laws/topology.md` row whose [SURFACE] this run touched — cull a row ' +
                      'whose coupling no longer holds, land a coupling this run proved.\n' +
                      'GATE: run `uv run .claude/skills/docgen/scripts/prose_gate.py <every touched .md>` and repair to zero FAILs ' +
                      'before returning. Return landed/refined/rejected (each rejection with its reason)/files/summary.',
                  wopts('doctrine', 'Close', 'fable', DOCTRINE_SCHEMA),
              ),
          )
        : null,
]);
return {
    targets: TARGETS,
    languages: LANDED_LANGS,
    batches: BATCHES.length,
    landed: LANDED.length,
    failed: FAILED,
    ideas: ideas && {
        entries: (ideas.entries || []).length,
        realized: (ideas.entries || []).filter((e) => e.outcome === 'realized').length,
        carded: (ideas.entries || []).filter((e) => e.outcome === 'carded').length,
        rejected: (ideas.entries || []).filter((e) => e.outcome === 'rejected').length,
        files: ideas.files || [],
        summary: ideas.summary,
    },
    seamRows: SEAM_ROWS.length,
    backlog: BACKLOG.length,
    findings: FOUND,
    failedFinders: found.filter((f) => !f.ok).map((f) => f.lane),
    residuals,
    fixer: fixer && {
        files: (fixer.files || []).length,
        indexApplied: (fixer.indexApplied || []).length,
        resolved: (fixer.resolved || []).length,
        backlogDrained: (fixer.backlogDrained || []).length,
        beyond: (fixer.beyond || []).length,
        rejected: (fixer.rejected || []).length,
        summary: fixer.summary,
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
