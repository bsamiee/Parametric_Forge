export const meta = {
    name: 'rebuild-alt',
    whenToUse:
        'Hostile rebuild pass for any libs/ planning corpus: pass targets (file / sub-folder / package root, any number, any language mix); it maps every .planning sub-folder, ideates per package on ONE ideas author (per-sub-folder power-idea dossiers and one package-wide dossier), hostile-rebuilds every page batch concurrently through twin half-scope writer chains at the owning-language doctrine bar, closes with a finder fan, package-fanned fixers, per-package ideas-implementers, and one terminal sweeper. Roster: recon/deep-map lanes, two-tier .api lanes, twin implement + critique halves, twin redteams, ideas author, census/realize/disposition/doctrine lanes.',
    description:
        "Language-agnostic hostile-rebuild engine over the libs/{csharp,python,typescript} planning corpora. args = a target path, an array of paths, or {targets} — languages mix freely, {root} retargets an isolated checkout, empty = no-op; every page derives doctrine, both .api tiers, casing, and its member-verification rail from its owning package. Plan expands targets to pages in dependency + seam-cohesion order under the owning-package charter. Map fans one deep-map lane and one two-tier .api inventory lane per .planning sub-folder unit — an oversize sub-folder splits into ceiling-bounded segments, so map and batch seams stay congruent — each writing a per-unit dossier the batches reuse. Ideate runs two lanes per package: a corrections census (the non-binding fix addendum) and ONE ideas author writing one dossier PER .planning sub-folder (folder-grain power ideas — new capability families ultra-stacking both .api tiers) and one package-wide dossier (broader cross-folder ambitions, each naming its owner pages) — one author, internally coherent, zero duplication between grains. Build packs whole sub-folder units into batches under the packing ceiling, all concurrent under one slot scheduler; per batch a doctrine-bar lens, then ONE LOC-balanced half partition drives twin half-scope chains — implement, critique, redteam per half, each chain folding its own on-disk fixlogs forward — every writer under the own-pass-first input ladder with libs-wide ripple authority under the four bounds and seam-ledger coordination; a half consumes its units' per-folder ideas dossiers with the package-wide entries its pages own. Each package chain closes with one ideas-realization writer implementing the residual idea pool against the landed corpus, gated entries carded via indexRows. The spine is per-package pipelined; Close is a whole-run barrier. Close: a read-only finder fan with one governance finder per language, a backlog verifier consolidating every deferred/census/orphan row into one package-keyed pre-verified work list, and an ideas collator statusing every idea entry against disk — then ONE fixer PER PACKAGE concurrently drains its package's work rows, findings, and package-doc index rows, each chaining into a per-package ideas-implementer realizing its unrealized ledger entries; ONE terminal sweeper then drains cross-package rows, central-manifest edits, per-fixer remainders, and failed territories in one scoped pass; two concurrent terminals follow — an ideas-disposition writer giving every idea entry exactly one outcome (realized on disk, carded into the owning IDEAS.md, or rejected with reason) and a doctrine lander adjudicating pooled harvest nominations. Stage law lives in the prompt blocks.",
    phases: [
        {
            title: 'Plan',
            detail: 'targets expand to the dependency-ordered, seam-cohesion-adjacent page list under each owning-package charter: existing pages rebuild, charter-demanded absences new, settled pages skip',
        },
        {
            title: 'Map',
            detail: 'per sub-folder unit segment: a deep-map lane (ownership, seams, cross-folder relevance, domain gaps — information, never code) beside a two-tier .api inventory lane, each writing the per-unit dossier the batches reuse; one audit-law-pack lane per landed language rides the wave, extracting the doctrine checklist sections verbatim into the scratch artifact every lane reads instead of re-assembling the atlas',
        },
        {
            title: 'Ideate',
            detail: 'per package, fired the moment that package map lanes land: sharded corrections censuses (the deduped disk-verified fix addendum, one lane per few sub-folders) and ONE ideas author writing one per-sub-folder power-idea dossier per .planning folder and one package-wide dossier of broader owner-named ambitions — one author, internally coherent, no entry duplicated across grains; an idea no existing owner can absorb lands as a [NEW_PAGE] entry, and a genuinely new territory as a wide-dossier [NEW_FOLDER] roster (3+ pages at guidance depth), both realization-only — batch writers skip them, the package realization writer implements or the disposition cards them, and run-authored pages join the finder and fixer fans',
        },
        {
            title: 'Build',
            detail: "sub-folder-packed batches, all concurrent, each package starting on its own ideate rather than the run-wide fan: per batch a doctrine-bar lens, then ONE LOC-balanced half partition drives twin half-scope chains — implement, critique, redteam per half, each folding its own on-disk fixlogs forward — every writer on the own-pass-first ladder with bounded libs-wide ripple authority and seam-ledger coordination, consuming its units' per-folder ideas with the package-wide entries its pages own; after the package's last batch, one ideas-realization writer implements the residual idea pool against the landed corpus",
        },
        {
            title: 'Close',
            detail: "a read-only finder fan with one governance finder per language over the landed corpus and seam ledger, with two consolidation lanes riding the fan concurrently — a backlog verifier pre-verifying every deferred/census/orphan row into one package-keyed stale-free work list, and an ideas collator statusing every idea entry against disk into one ledger; then ONE fixer per package concurrently drains its package's rows, findings, and package-doc index rows, chaining into a per-package ideas-implementer for the unrealized ledger entries; ONE terminal sweeper drains cross-package rows, central-manifest edits, per-fixer remainders, and failed territories in one scoped pass; then two concurrent terminals — the ideas-disposition writer giving every idea entry one outcome and the doctrine lander adjudicating pooled harvest nominations and the fixer fixlogs' harvest rows read from disk",
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const CAP = 14;
const BATCH_MAX = 8; // unit-segment + batch-packing ceiling; per-segment maps + census legwork carry the navigation, so a writer holds a full dense batch
const BATCH_LOC = 3400; // size ceiling beside the count ceiling: a batch's pages must also fit one review context window with room to edit — page tonnage, not page count, is what overflows a lane
const FINDER_PAGES = 8; // landed pages per close-phase finder
const CENSUS_SUBS = 4; // sub-folders per corrections-census shard; one lane each keeps row verification deep

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
// Prefix is THIS workflow's name, never a shared stem: `rebuild.js` mints its dir the same way, so a bare `rebuild-`
// prefix collides both runs over one directory — including the APPEND-ONLY seam ledgers that carry cross-batch
// coordination. ROOT_DIR joins the hash because it is what retargets an isolated checkout: two runs over equal targets
// in different checkouts are different runs and must never share a data plane.
const SCRATCH =
    '.claude/scratch/' +
    ('rebuild-alt-' + TARGETS.map((t) => t.split('/').pop().toLowerCase()).join('-')).replace(/[^a-z0-9.-]+/g, '-').slice(0, 60) +
    '-' +
    fnv1a(JSON.stringify([TARGETS, ROOT_DIR]));

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
// One row per ambition entry a writer met — the traceability rung the Close collator and disposition writer read instead
// of reconstructing realization from disk alone; a claimed-but-unrecorded idea is how an ambition dies silently.
const IDEAS_WORKED = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['idea', 'outcome', 'where'],
        properties: {
            idea: S, // the dossier entry slug, verbatim
            outcome: { type: 'string', enum: ['landed', 'deepened', 'declined', 'unrealized'] },
            where: S, // landed/deepened: the page anchor carrying it; declined: why the entry does not survive disk
        },
    },
};

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
        'ideasWorked',
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
        ideasWorked: IDEAS_WORKED,
    },
};

const REVIEW_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'verdict', 'summary', 'seamsTouched', 'deltas', 'deferred', 'beyondMap', 'indexRows', 'harvest', 'extended', 'ideasWorked'],
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
        ideasWorked: IDEAS_WORKED,
    },
};

// RT_SCHEMA = REVIEW_SCHEMA + the `armed` attestation: the redteam lists every mandated file it read IN FULL. Telemetry
// ground: a review lane truncates enumeration ladders (finished rts touched docs/stacks 1-5 times against a ~15-file mandate and
// landed a uniform token edit pair); a required attestation makes the arming structurally checkable, never wishful prose.
const RT_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: REVIEW_SCHEMA.required.concat(['armed']),
    properties: Object.assign({}, REVIEW_SCHEMA.properties, { armed: { type: 'array', items: S } }),
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
    // `unreached` is the completeness attestation: this lane consumes the WHOLE run's deferred, census, and orphan pool
    // under one budget, and a row it never opened is otherwise indistinguishable from a row that never existed — the
    // engine re-feeds the raw sets when this array is non-empty, so an honest remainder costs nothing and silence costs the row.
    required: ['live', 'culled', 'unreached', 'summary'],
    properties: {
        unreached: { type: 'array', items: S },
        live: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['pkg', 'owner', 'files', 'claim', 'anchors', 'source'],
                properties: {
                    pkg: S, // owning package root (path before /.planning/) when every file sits under one package; '' for a cross-package row — the fixer fan partitions on this key
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
          'and nothing it carried was lost — one verification pass per page, never between edits. Fix what fails before yielding. ' +
          'Verification is READING: the corpus is markdown ' +
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
        // Stale purge BEFORE the lane run: SCRATCH derives from targets alone, so a prior run over the same targets left its
        // reports here. A lane that dies without writing leaves that file in place, the probe passes it, and a dead run's
        // product is consumed as this run's — the one failure this whole receipt path cannot otherwise detect.
        '/task.md, composing neither. Delete any leftover report with one Bash call: rm -f ' +
        report +
        " — a stale file from a prior run over these targets otherwise passes step (4) as this run's product. " +
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
        " (4) Verify with one Bash call: jq -e '." +
        o.hl.arr +
        "' " +
        report +
        ' >/dev/null — probe that contract key, never bare parseability, which any wrong-shaped JSON passes; on a miss re-derive the ' +
        'product once from the lane events.jsonl (jq -rs to the last agent_message item text, Write that), re-probe, and a second miss ' +
        'returns ok=false with the probe output. (5) Return ok=true, report=' +
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
// Package tag carries its LANGUAGE: basenames collide across branches (`libs/python/data` and `libs/typescript/data` both
// reduce to `data`), and targets mix languages freely while package chains run concurrently — an un-namespaced tag puts two
// live lanes on one report, dossier, and seam ledger, corrupting contents while every orchestrator key still looks distinct.
const pkgTag = (pkg) => (langOf(pkg) || 'x') + '.' + pkg.split('/').pop();
const scratchBase = (pkg, i) => SCRATCH + '/' + fileTag(pkgTag(pkg) + ':b' + i);
const dossierPath = (lensLabel) => SCRATCH + '/' + fileTag(lensLabel) + '-dossier.md';
const normalizePages = (pl) => {
    // Preserves plan emission order (dependency + cohesion order); dedupe by page, first wins.
    // `lines` feeds the size-aware packer; a `new` page (0 on disk) packs at a typical authored weight.
    const seen = new Set();
    const out = [];
    for (const p of (pl && pl.pages) || []) {
        if (!p || !p.page || seen.has(p.page)) continue;
        seen.add(p.page);
        // Floor applies to a `new` page ALONE (0 on disk, packed at a typical authored weight); flooring a real count
        // packs and chunks every short page as 500 lines, inflating segment tonnage against the dual ceiling.
        const kind = p.kind === 'new' ? 'new' : 'rebuild';
        out.push({ page: p.page, kind, lines: kind === 'new' ? Math.max(p.lines | 0, 500) : Math.max(p.lines | 0, 1) });
    }
    return out;
};

// LOC-balanced two-way split for the twin redteam halves: each half carries roughly half the batch tonnage,
// so a redteam holds half the load its single-writer ancestor carried; a one-page batch stays whole.
const halve = (pages) => {
    if (pages.length < 2) return [pages];
    const total = pages.reduce((a, p) => a + p.lines, 0);
    let best = 1;
    let bestDiff = Infinity;
    let acc = 0;
    for (let i = 0; i < pages.length - 1; i++) {
        acc += pages[i].lines;
        const diff = Math.abs(acc - total / 2);
        if (diff < bestDiff) {
            bestDiff = diff;
            best = i + 1;
        }
    }
    return [pages.slice(0, best), pages.slice(best)];
};
// Half chains share one partition across implement/critique/redteam, so each half's fixlog stream is disjoint —
// no cross-half merge exists; half records aggregate directly.

// --- [SHARED_BLOCKS]

// Every rigor law appears exactly once, here; stages compose subsets. Block order in prompts: stable per-language law first (byte-identical across a
// batch's stages), batch-variable material second, the stage task + output contract LAST — nothing load-bearing mid-prompt.
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

const CORRECTIONS = (paths) =>
    paths && paths.length
        ? 'CORRECTIONS CENSUS (ladder rung 3) — the census dossiers covering your pages: `' +
          paths.join('`, `') +
          '` — the fix census consolidated from the map lanes, sectioned per sub-folder: drift, phantoms, ' +
          'catalog-true spelling repairs, seam and wire mismatches, wiring gaps. ADDITIONAL, never the plan: after your own pass, ' +
          'land every row that intersects your pages (re-verified on disk — a row disk already resolves is dropped) and leave ' +
          'foreign rows alone; the terminal fixer drains the remainder. A pass that only lands census rows has failed OWN PASS FIRST.'
        : '';

const IDEAS = (subFiles, wide) =>
    subFiles.length || wide
        ? 'IDEAS WORKLISTS (ladder rung 4) — capability AMBITIONS beyond correction, in two grains from one author. ' +
          (subFiles.length
              ? 'YOUR FOLDER FILES (read each IN FULL): `' +
                subFiles.join('`, `') +
                '` — folder-grain power ideas for pages in your scope: spot-verify each entry against current disk and build ' +
                'the STRONGEST form it points toward or a stronger one you see. '
              : '') +
          (wide
              ? 'PACKAGE-WIDE FILE (read IN FULL): `' +
                wide +
                '` — broader ambitions, each naming its owner pages. Realize ONLY the entries naming one of YOUR pages as ' +
                'owner; an entry owned elsewhere is not yours — never build it and never ledger it, since its owner files ' +
                'that row and a duplicate from every half that merely read the file buries the one that acted. '
              : '') +
          'An entry marked [NEW_PAGE] or [NEW_FOLDER] is OUT OF SCOPE for every batch writer — never author it, never note ' +
          'it; the package realization writer owns it. An idea disk already realizes, or the doctrine forbids, is dropped; an ' +
          'idea you decline is not a defect. Ambition and information, never a prescription, a design, or a ceiling. ' +
          'LEDGER DUTY: every entry YOU OWN gets exactly one `ideasWorked` row — every folder-file entry, and every wide ' +
          'entry naming one of your pages — `landed` with the page anchor carrying it, ' +
          '`deepened` with the anchor when a prior pass left it shallow and you rebuilt it to strength, ' +
          '`declined` with what on disk or in doctrine defeats it, or `unrealized` when it survives but your pass did not ' +
          'reach it. Silence is the one forbidden outcome: an unrecorded entry is indistinguishable downstream from an idea ' +
          'that never existed, and the terminal disposition can only card what a ledger row names.'
        : '';

// Critique's ambition rung: an AUDIT charter, never a realization one — the critique proves what the implement claimed and
// deepens what it landed shallow, while an untouched entry is recorded for the redteam and realization writer, never authored here.
const IDEAS_AUDIT = (subFiles, wide) =>
    subFiles.length || wide
        ? 'IDEAS AUDIT — the implement lane worked the same ambition pool you now read: `' +
          subFiles.concat(wide ? [wide] : []).join('`, `') +
          '`. Read every entry owning one of YOUR pages, then grade its realization ON DISK against three outcomes. LANDED AT ' +
          'STRENGTH: the page carries the capability at the depth the entry names — confirm and move on. LANDED SHALLOW: the ' +
          'page gestures at the capability with a thin spelling, a single case where the entry names a family, a knob where it ' +
          'names a dimension, or prose asserting what no shape carries — you REBUILD it to the strongest form the entry points ' +
          'toward or a stronger one you see, exactly as you repair any conformance defect. ABSENT: no counterpart exists — ' +
          'record it in your report as an unrealized row naming the entry and its owner page, and author NOTHING; the redteam ' +
          'and the package realization writer own it. A shallow realization is a QUALITY DEFECT of the same class as a doctrine ' +
          'violation and is repaired under the same authority, never merely reported. [NEW_PAGE] and [NEW_FOLDER] entries stay ' +
          'out of scope: never author, never grade, never note. LEDGER DUTY: every entry you grade gets exactly one ' +
          '`ideasWorked` row — `landed` (the implement realized it at strength, anchor named), `deepened` (you rebuilt a ' +
          'shallow realization, anchor named), `declined` (disk or doctrine defeats it), or `unrealized` (absent, left for the ' +
          'realization writer). Your grade is the first independent read of the ambition pool against disk, so an ungraded ' +
          'entry strands the disposition writer with the implement self-report alone.'
        : '';

const readFirst = (L, pkg, dossiers) =>
    [
        'READ FIRST, IN ORDER, BEFORE ANY EDIT — no fence is judged before this read lands.',
        '(1) DOCTRINE — read these `' +
            L.stack +
            '/` pages IN FULL, each in this exact order: ' +
            L.atlas.map((f) => '`' + f + '`').join(', ') +
            ' — never a partial, skim, grep-jump, or section-sample; this list is the complete root set, no discovery pass ' +
            'needed. The README [02]-[DOCTRINE] laws, the [03]-[COLLAPSE_SCAN] table, OWNER_CHOOSER (`shapes.md` ' +
            '[01]), RAIL_CHOOSER (`rails-and-effects.md` [01]), and the aspect two-weave (`surfaces-and-dispatch.md` AND ' +
            '`rails-and-effects.md`) are binding law AT THE SOURCE — read it there, hold it as fact, conform every fence to it; ' +
            'a summary never substitutes for the read.',
        L.key === 'cs'
            ? '(1b) Read `docs/stacks/csharp/domain/README.md` (the shard router), then read every shard it routes that the ' +
              'page concerns touch — chosen from the router, never from memory; shard conformance is a hard gate.'
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

// preamble serves the redteam only (implement carries its own assembly): RT_READ replaces the full-atlas readFirst ladder —
// named files a terminal-review lane actually executes, enforced by the `armed` attestation.
const preamble = (L, batch, dossiers, ideate, scopes, roster, unmapped, reg, lbase, pack) =>
    [CONTEXT(L), REG[reg].stance(L), OWN_PASS, BUILD_LAW(L), BODY(L), VERIFY(L), RIPPLE_LAW, CURRENT_STATE, PROSE_COMMENTS(L)]
        .concat(L.mechanics ? [L.mechanics] : [])
        .concat([
            RT_READ(L, pkgOf(batch[0].page), dossiers, pack),
            LEDGER(lbase || scratchBase(pkgOf(batch[0].page), batch[0].i || 0), scopes),
            reconBlock(roster, unmapped),
        ])
        .concat(ideate ? [CORRECTIONS(ideate.fixFiles || [])].filter(Boolean) : [])
        .concat(ideate ? [IDEAS(ideate.ideaSubFiles || [], ideate.ideaWide || '')].filter(Boolean) : []);

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
            '`packages` (one entry per owning package: {name, root, planning, api, note} — `note` carries the one-line scope ' +
            'fact a downstream lane needs and is empty when none applies). PAGES: expand each target — a ROOT to ' +
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
        "SCRATCH HYGIENE (before returning): this run's scratch dir is `" +
            SCRATCH +
            '` — its name derives from the targets, so a prior run over the same targets left artifacts there. When the dir ' +
            'pre-exists, delete its stale cross-run seam ledgers: `rm -f ' +
            ROOT_DIR +
            '/' +
            SCRATCH +
            '/*-seams.md` — dossiers and reports are per-lane overwritten by this run, but seam ledgers APPEND, and a stale ' +
            "row from a dead run poisons this run's cross-batch coordination. Delete nothing else.",
        'TOOLCHAIN WARM-UP (before returning): run `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api --help` once — ' +
            "it builds the workspace uv cache every downstream lane's member-verification rail rides, so no lane pays the cold " +
            'environment latency or misreads it as a broken rail.',
    ].join('\n\n');

const correctionsPrompt = (L, pkg, mapIndex, dossier, subs) =>
    [
        ROOT_LAW,
        CONTEXT(L),
        'TASK: CORRECTIONS CENSUS AUTHOR for `' +
            pkg +
            '`, sub-folder territory ' +
            JSON.stringify(subs) +
            ' — read-only over the corpus; you WRITE exactly one file, the census dossier for YOUR territory (sibling census ' +
            'lanes own the other sub-folders; never census a foreign folder). The Map phase produced per-SUB-FOLDER ' +
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

const ideasPrompt = (L, pkg, mapIndex, subRows, widePath) =>
    [
        ROOT_LAW,
        CONTEXT(L),
        'TASK: IDEAS AUTHOR for `' +
            pkg +
            '` — read-only over the corpus; you WRITE exactly ' +
            (subRows.length + 1) +
            ' files, the idea dossiers below, nothing else. The Map phase produced per-SUB-FOLDER deep-map and two-tier .api ' +
            'inventory dossiers; read EVERY dossier listed here IN FULL, then the package charter (ARCHITECTURE.md + ' +
            'README.md + IDEAS.md) and the pages your ideas grow on: ' +
            JSON.stringify(mapIndex),
        'TWO GRAINS, ONE AUTHOR — you write the whole pool in one pass so it is internally coherent: an idea lands in ' +
            'exactly ONE file, never duplicated, diluted, or split across grains; the wide grain is NOT a union, summary, or ' +
            'rollup of the folder grain.',
        'FOLDER GRAIN — one dossier per `.planning` sub-folder (`_root` pools the root-level pages): ' +
            JSON.stringify(subRows) +
            ". Every entry is folder-grain POWER — an impressive new capability the folder's own domain admits and the corpus " +
            'lacks: a new dimension, modality, family, case class, operation family, or generator over an enumerated space, ' +
            'grounded in real domain demand (' +
            L.gapDomain +
            ') and ULTRA-STACKING the admitted two-tier .api depth — capability the catalogs carry at operator depth that no ' +
            'fence exploits is prime idea ground, composed INTO existing owners as new functionality, never a denser spelling ' +
            'of the same call. Each entry names the owner page it grows on, the domain or catalog ground, the anchor, and WHY ' +
            'it widens the folder — never the resulting code, a fence sketch, or a ruled shape. Every file is written even ' +
            'when its folder yields little; a folder with zero surviving entries gets its file with a one-line clean verdict.',
        'PACKAGE-WIDE GRAIN — write `' +
            widePath +
            '`: broader ambitions whose value spans folders or widens what the package IS — cross-folder enablements, ' +
            "package-level dimensions, seam-riding capabilities. An idea that fits inside one folder belongs in that folder's " +
            'file, not here. EVERY wide entry names its OWNER PAGES explicitly (the pages that must absorb it) — batch writers ' +
            'claim wide entries by owner page, so an owner-less entry is unimplementable and forbidden; an idea whose value ' +
            'crosses the package boundary names BOTH ends and the seam it rides.',
        'NEW SURFACES — an idea is never forced onto the existing corpus. A capability no existing owner can absorb lands as ' +
            "a `[NEW_PAGE <path>]` entry: in the owning folder's dossier when the page belongs to an existing sub-folder, in " +
            "the wide dossier when it belongs to none; the entry names the page's ownership boundary (what it owns versus its " +
            'siblings), the key owner families and vocabularies it is expected to carry, its seams both ends, and the domain ' +
            'or catalog ground. A genuinely high-value capability gap demanding its own territory lands as a wide-dossier ' +
            '`[NEW_FOLDER <path>]` entry: the folder charter in one sentence, WHY the package demands it, and a roster of AT ' +
            'LEAST THREE pages — a two-page folder is not a folder — each roster row carrying the page name, its ownership ' +
            "boundary, expected owner families, and seams, at the guidance depth of the existing folders' page set: enough " +
            'that an implementing agent never guesses location, charter, or seam, never the full build-out. Every ' +
            '[NEW_PAGE]/[NEW_FOLDER] entry states in its body: REALIZATION-ONLY — batch writers skip this entry; the package ' +
            'realization writer implements it or the disposition writer cards it. The grain is YOUR judgment, neither forced ' +
            'nor suppressed: imagine the package complete and shipped as a professional library for its real domain — a ' +
            'capability a domain expert would expect and find missing earns its surface at the grain that fits the missing ' +
            "territory's size: growth on an existing owner for what an owner admits, a [NEW_PAGE] for a concern no page owns, " +
            'a [NEW_FOLDER] for a whole missing domain — obvious gaps and nuanced advanced ones alike, judged future-facing ' +
            'with zero naive gaps tolerated; the census of real gaps rules the count.',
        'VALUE BAR — the census/ideas partition is severity of imagination, not anchor quality: a stale label, wrong ' +
            'spelling, dropped wire column, or single uncomposed member is a CORRECTION and drops here; an entry earns its row ' +
            'by naming capability whose absence a domain expert would call a gap in the PRODUCT, not a defect in the prose.',
        "SECOND-PASS CULL (before returning): re-open every entry's anchor on disk; delete any entry disk already realizes, " +
            'any correction in disguise, any entry duplicated across two files, and any entry whose value you cannot state as ' +
            'a concrete new capability of a named owner. Boldness is never the cull criterion — the cull removes false and ' +
            'small entries, never ambitious ones; few large ideas beat many verified trivia.',
        REG.claude.selfCheck,
        'Return ONLY the receipt: ok, report = the package-wide dossier path (repo-relative), entries = the TOTAL idea count ' +
            'across all files, a one-line headline tallying entries per file, failure empty.',
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
            'owners/seams composed, folder position, folder-wide gaps routed here, and DOMAIN gaps — attributes, sub-kinds, ' +
            'states, relationships, operations the real concept demands that the page omits, as named gaps), `seams` (every ' +
            'cross-page and cross-package symbol/wire/consumer edge, both endpoints named). CROSS-PACKAGE RELEVANCE: also mine ' +
            'what the OTHER packages hold that is relevant to each page — kernel and sibling-package owners it composes or its ' +
            'concept plainly touches, imports, consumer sites, ripple targets both ends — as verified anchors in ' +
            '`seams`/`anchors`, so a writer NAVIGATES (trust, then verify at the anchor) instead of exploring; relevance is ' +
            'fact, never a suggested change. Each entry also carries `files` and typed `anchors` per the entry form. ' +
            'DECLARATION SURFACE — mine what a writer must MATCH to compile against these pages, as fact at its anchor: the ' +
            "namespace each page's owners declare and the exact spelling of every namespace its fences import; which " +
            'declarations are visible without an import versus reached through one; the alias, extern-alias, or ' +
            'static-import a cited surface requires; and the stratum each page sits in per `libs/.planning/ARCHITECTURE.md` ' +
            'with the DIRECTION its dependencies run — a page importing downward, or reaching a sibling interior where a ' +
            'recorded seam exists, is a named fact at both anchors. A writer that has to rediscover a namespace spells it ' +
            'wrong or invents a parallel one.\nGROUNDING DOSSIER: write `' +
            dossier +
            '` under these five headings verbatim, in this order, no renaming and no additions — downstream lanes reach ' +
            'your rows by heading, so a renamed section reads as an absent one: `## [01]-[PAGE_OWNERSHIP]` (one row per ' +
            'page: its ownership boundary, its stratum, and the sibling owners it composes — the anti-collision surface two ' +
            'concurrent writers read first), `## [02]-[SEAM_LEDGER]` (the branch ARCHITECTURE.md [02]-[SEAMS] rows covering ' +
            'these pages quoted VERBATIM with `file:line` anchors, each row naming BOTH endpoints and which end each page ' +
            'owns), `## [03]-[DECLARATION_SURFACE]` (the namespace, import, and visibility rows above, at anchors), ' +
            '`## [04]-[DOMAIN_GAPS]` (per page, the attributes, sub-kinds, states, relationships, and operations the real ' +
            'concept demands that the page omits — named as gaps, never as designs), `## [05]-[TIER_2_POINTERS]` (path + ' +
            'one-line scope for every sibling page composed and every cross-package consumer, the long tail a writer ' +
            'resolves with a real read when an edit reaches it).\nDEPTH BAR — this dossier is MANDATORY full reading for ' +
            'every writer that touches these pages, so an omitted seam is a seam nobody repairs and a missing ownership row ' +
            'is two writers authoring one surface. Every page in scope gets a row under [01] and [04] even when its verdict ' +
            'is thin; every seam names both ends; a folder-level summary standing where per-page rows belong is an ' +
            'incomplete pass your `coverage` must report. FORBIDDEN: verified `.api` member catalogs and package-capability ' +
            'inventory — the two-tier stacking lens owns that surface entirely and a duplicate here forks it; also doctrine ' +
            'digests, removal framing, unanchored claims, prescriptive designs. Return worklist + coverage.',
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
            'one "best" owner alone. FULL-TIER TRIAGE: you hold the complete two-tier `ls` inventory — every catalog in it ' +
            'gets TWO independent verdicts, never one: PRESENCE — COMPOSED (a page uses it) or FOREIGN (one word, no ' +
            'elaboration) — and, for every COMPOSED catalog, DEPTH — SATURATED (the pages exploit the members their concepts ' +
            'admit) or EXPANSION (admitted depth no fence reaches, landing as {catalog, capability} rows routed to the ' +
            'admitting pages). COMPOSED NEVER BLOCKS EXPANSION: presence proves one member was called, never that the surface ' +
            'is exhausted, and the richest rows this lens produces come from catalogs already composed at one member while a ' +
            'whole family goes unused; a FOREIGN catalog whose concepts the folder admits carries EXPANSION rows too. A ' +
            'COMPOSED catalog carrying no DEPTH verdict is an incomplete read your coverage must report, and a folder-wide ' +
            '"EXPANSION rows: none" is a claim you owe per-catalog proof for — name each COMPOSED catalog and the exhausted ' +
            'family earning its SATURATED verdict, or the claim is a skipped grading pass. The famous rails are never the ceiling — ' +
            'the long tail of both tiers is where unexploited packages hide, and a domain-adjacent folder catalog with zero ' +
            'fence use is the highest-value row this lens produces. SINGLE-CONSUMER EXPANSION: a package with a catalog at ' +
            'ANY tier consumed by only ONE page is expansion pressure on its siblings — name the package, its unexploited ' +
            'members in exact spellings, and each candidate page. Discovery has ZERO removal authority: an underutilized ' +
            'catalog is always a buildout target, never removal evidence. DEPTH GRADING: a composed member counts as underutilized when the usage is shallow — one call ' +
            'where the surface carries a family, a default-arg call where the policy axis matters, a scalar use of a ' +
            'batch/stream-capable member; grade used-but-shallow with the same {catalog, capability} rows as unused. For EACH ' +
            'page return `apiUsed`, `apiUnderutilized` ({catalog, capability}), `stackingInventory` (capability names + the ' +
            "doctrine patterns the page's concept admits, as inventory fact — never a prescribed design), `files`, and " +
            'typed `anchors` per the entry form. ROW CONTENT LAW — signal density over row count: each `capability` string ' +
            'carries (1) the exact member spellings at operator depth — the specific overloads, combinators, generated ' +
            'surfaces, and parameter axes the catalog holds, never a bare package name; (2) the page fact proving the gap — ' +
            "what the fence does today at its anchor; (3) the admitting concept — WHY this page's domain demands the " +
            "capability. What to compose is stated as available fact; HOW to compose it is the implement agent's ruling — a " +
            'code sketch, signature proposal, or prescribed shape is a defect. Three deep rows a writer can act on outrank ' +
            'ten thin package mentions. Verify every cited member via ' +
            L.verify +
            '; never list a phantom. GROUNDING DOSSIER: write `' +
            dossier +
            '` — Tier-1: quoted `.api` member blocks with `file:line` anchors for every cited member and the real `ls` ' +
            'inventories of both tiers; NEGATIVE_SPACE: one row per EXPANSION-verdict catalog — the catalog, the admitting ' +
            'folder concept, and the zero-use evidence — so the unexploited-package sweep is auditable, never implied; ' +
            'Tier-2: pointer rows (catalog path + one-line scope) for the FOREIGN remainder. SKELETON — these five headings ' +
            'verbatim, in this order, no renaming and no additions: `## [01]-[TIER_1_INVENTORIES]`, ' +
            '`## [02]-[TIER_1_MEMBER_BLOCKS]`, `## [03]-[NEGATIVE_SPACE]`, `## [04]-[TIER_2_FOREIGN]`, ' +
            '`## [05]-[VERIFICATION]`; downstream lanes reach your rows by heading, so a renamed section reads as an absent ' +
            'one. FORBIDDEN: doctrine digests, unanchored claims, prescriptive designs. Return worklist + coverage.',
    ].join('\n\n');

const barLensPrompt = (L, batch, reg, pack) =>
    [
        CONTEXT(L),
        REG[reg].stance(L),
        EVIDENCE_LAW,
        REG[reg].selfCheck,
        REG[reg].antiAnchor(L),
        REG[reg].bar(batch.length) +
            batch.map((p) => p.page + ' [' + p.kind + ']').join(', ') +
            '. DOCTRINE GROUND: ' +
            (pack
                ? 'the audit law pack `' +
                  pack +
                  '` carries every binding checklist section VERBATIM with its source anchor — read it IN FULL in large ' +
                  'windows FIRST; a doctrine page at source opens only when a finding turns on law outside the pack'
                : 'read these `' +
                  L.stack +
                  '/` pages IN FULL, in this exact order: ' +
                  L.atlas.map((f) => '`' + f + '`').join(', ') +
                  ' — never a partial, skim, grep-jump, section-sample, or line-count-as-read; this list is the complete ' +
                  'root set, no discovery pass needed') +
            (L.key === 'cs' ? ' (with the `docs/stacks/csharp/domain/` shards these pages touch, routed through `domain/README.md`)' : '') +
            '. Then read each target page IN FULL and ' +
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

// TWIN HALF law for the implement/critique halves — the redteam carries its own variant with the fold-forward duty.
const TWIN = (sibling, half) =>
    sibling.length
        ? 'TWIN HALF — this batch runs as TWO concurrent half-scope writers; you are half ' +
          half +
          ' and own ONLY the pages the TASK names. The sibling half is a LIVE CONCURRENT WRITER over: ' +
          JSON.stringify(sibling.map((p) => p.page)) +
          ' — an edit inside its pages is recorded in `deferred`, never raced; its seam-ledger rows compose per the ledger law.'
        : '';

// Implement read law — the authoring twin of CRIT_READ: the law pack carries the binding checklist verbatim so a write
// lane never buys the full-atlas ladder before its first edit (the ladder overflows a lane window and every compaction
// re-buys the reads); dossiers stay MANDATORY grounding — the implement is the author, not an auditor.
const IMPL_READ = (L, pkg, dossiers, pack) =>
    'READ LAW — authoring-grade scoped reads; each stable input is read ONCE per the lane read discipline. ' +
    '(1) DOCTRINE' +
    (pack
        ? ': the audit law pack `' +
          pack +
          '` carries every binding checklist section VERBATIM with its source anchor — read it IN FULL, in at most three ' +
          'large windows, FIRST. The pack REPLACES the atlas: never `tree` or `loc` the doctrine tree, never re-read a stack ' +
          'README or root page wholesale beside it; a doctrine page opens only at the exact section a named design decision ' +
          'requires, when that law is outside the pack'
        : ', scoped at-source: `' +
          L.stack +
          '/README.md` [02]-[DOCTRINE] laws + the [03]-[COLLAPSE_SCAN] table, OWNER_CHOOSER (`shapes.md` [01]), RAIL_CHOOSER + ' +
          'boundary conversion (`rails-and-effects.md` [01]-[02]), the aspect two-weave sections (`surfaces-and-dispatch.md` ' +
          'AND `rails-and-effects.md`), and the file-organization law — each read at its site before authoring against it') +
    (L.key === 'cs' ? ', with the `docs/stacks/csharp/domain/` shards these pages touch, chosen through the router README, never from memory' : '') +
    '. (2) ANALYZER + LAWS: the repo `.editorconfig` error-severity rules for your language are compile gates (a claim ' +
    'contradicting one is a fiction to correct); read `docs/laws/README.md` + `docs/laws/topology.md` — a topology row whose ' +
    '[SURFACE] your edits touch binds its obligated counterparts into the SAME pass. ' +
    '(3) GROUNDING DOSSIERS' +
    (dossiers
        ? ' (MANDATORY full reads): `' +
          dossiers +
          '` — Tier-1 verified two-tier extracts with `file:line` anchors (SPOT-VERIFY; a fake anchor goes in ' +
          '`dossierPhantoms`), Tier-2 pointer rows resolved with a real read the moment an edit touches their territory, ' +
          'never guessed past.'
        : ': absent — run the two-tier `ls`+read yourself over both `.api` tiers before authoring.') +
    ' (4) SCOPE: the owning-package charter (ARCHITECTURE.md + README.md + IDEAS.md at `' +
    pkg +
    '`) is the intent authority for what each page owns; a charter-settled page is out of scope. ' +
    '(5) `.api` CATALOGS: `ls` BOTH tiers once — `' +
    L.root +
    '/.api/` AND `' +
    pkg +
    '/.api/` — then open catalogs at the member blocks your pages compose, layering the shared rails (' +
    L.deepPkgs +
    ') on top of the folder domain packages; a disputed spelling resolves via ' +
    L.verify +
    '. OUT OF SCOPE: instruction files (CLAUDE.md, AGENTS.md, `.claude/` config), skill bundles under ANY root ' +
    '(`.claude/skills/`, `~/.codex/skills/` — the PROSE block above carries the complete register law; the docgen bundle is ' +
    'never opened), the repo-root README, and any strata or topology hunt beyond the named files — the law above is ' +
    'complete, and a name this brief states is never searched for on disk.';

// Redteam read law — the terminal-review twin of IMPL_READ: every read is a NAMED file, never an enumeration ladder
// (telemetry: a review lane executes a named concrete file and silently truncates a "read EVERY page the ls returns" mandate);
// the `armed` return field is the enforcement — a file not listed there was not read.
const RT_READ = (L, pkg, dossiers, pack) =>
    'READ LAW — terminal-review arming, executed BEFORE any judgment; every file below is a NAMED MANDATORY full read, and ' +
    'your `armed` return field lists the exact paths you read IN FULL — a file absent from `armed` was not read, and an ' +
    'arming below this named set is a failed pass. ' +
    '(1) DOCTRINE' +
    (pack
        ? ': the audit law pack `' +
          pack +
          '` carries every binding checklist section VERBATIM with source anchors — read it IN FULL in large windows FIRST; ' +
          'a doctrine page at source opens when an attack dimension turns on law outside the pack'
        : ': `' +
          L.stack +
          '/README.md` IN FULL, OWNER_CHOOSER (`shapes.md` [01]), RAIL_CHOOSER + boundary conversion (`rails-and-effects.md` ' +
          '[01]-[02]), the aspect two-weave sections (`surfaces-and-dispatch.md` AND `rails-and-effects.md`), and the ' +
          'file-organization law — each at source') +
    (L.key === 'cs' ? ', with every `docs/stacks/csharp/domain/` shard the pages touch, chosen through the router README' : '') +
    '. (2) LAWS: `docs/laws/README.md` + `docs/laws/topology.md` + `docs/laws/patterns.md` IN FULL — a topology row whose ' +
    '[SURFACE] your edits touch binds its counterparts into this pass; the repo `.editorconfig` error-severity rules for ' +
    'your language are compile gates. ' +
    '(3) STRATA: `libs/.planning/ARCHITECTURE.md` and the branch ARCHITECTURE.md [02]-[SEAMS] ledger — mandate (D) judges ' +
    'against these read at source, never a summary. ' +
    '(4) `.api`: `ls` BOTH tiers — `' +
    L.root +
    '/.api/` AND `' +
    pkg +
    '/.api/` — then read EVERY catalog your pages cite or compose IN FULL; a disputed spelling resolves via ' +
    L.verify +
    ' (5) CHARTER: the owning-package ARCHITECTURE.md + README.md + IDEAS.md at `' +
    pkg +
    '`. (6) GROUNDING' +
    (dossiers
        ? ': the dossiers `' + dossiers + '` carry verified extracts — spot-verify every anchor behind an edit.'
        : ': dossiers absent — derive grounding from the reads above.') +
    ' OUT OF SCOPE: instruction files (CLAUDE.md, AGENTS.md, `.claude/` config), skill bundles under ANY root ' +
    '(`.claude/skills/`, `~/.codex/skills/`), the repo-root README.';

const implementPrompt = (L, batch, dossiers, ideate, scopes, roster, unmapped, pack, reg, sibling, half, lbase) =>
    [CONTEXT(L), REG[reg].stance(L), OWN_PASS, BUILD_LAW(L), BODY(L), VERIFY(L), RIPPLE_LAW, CURRENT_STATE, PROSE_COMMENTS(L)]
        .concat(L.mechanics ? [L.mechanics] : [])
        .concat([TWIN(sibling || [], half)].filter(Boolean))
        .concat([
            IMPL_READ(L, pkgOf(batch[0].page), dossiers, pack),
            LEDGER(lbase || scratchBase(pkgOf(batch[0].page), batch[0].i || 0), scopes),
            reconBlock(roster, unmapped),
        ])
        .concat(ideate ? [CORRECTIONS(ideate.fixFiles || [])].filter(Boolean) : [])
        .concat(ideate ? [IDEAS(ideate.ideaSubFiles || [], ideate.ideaWide || '')].filter(Boolean) : [])
        .concat([
            'TASK: ' +
                (reg === 'claude' ? 'HOSTILE IMPLEMENT' : 'IMPLEMENT') +
                ' of these ' +
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
                'CORRECTIONS CENSUS row intersecting your pages, and realize the IDEAS entries your pages own — your folder ' +
                'files in full, wide entries only where a page of yours is the named owner — at the strongest form disk admits. ' +
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
// overflows a lane window before the first edit and every compaction re-buys the reads.
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
    '. OUT OF SCOPE: instruction files (CLAUDE.md, AGENTS.md, `.claude/` config), skill bundles under ANY root ' +
    '(`.claude/skills/`, `~/.codex/skills/` — the PROSE block above carries the complete register law), the repo-root ' +
    'README, and any strata or topology hunt — the law above is complete, and a name this brief states is never searched for on disk.';

const critiquePrompt = (L, batch, dossiers, ideate, scopes, roster, unmapped, implReport, reg, pack, sibling, half, lbase) =>
    [CONTEXT(L), REG[reg].stance(L), BUILD_LAW(L), BODY(L), VERIFY(L), RIPPLE_LAW, CURRENT_STATE, PROSE_COMMENTS(L)]
        .concat(L.mechanics ? [L.mechanics] : [])
        .concat([TWIN(sibling || [], half)].filter(Boolean))
        .concat([
            CRIT_READ(L, pkgOf(batch[0].page), dossiers, roster, unmapped, pack),
            LEDGER(lbase || scratchBase(pkgOf(batch[0].page), batch[0].i || 0), scopes),
        ])
        .concat(ideate ? [CORRECTIONS(ideate.fixFiles || [])].filter(Boolean) : [])
        .concat(ideate ? [IDEAS_AUDIT(ideate.ideaSubFiles || [], ideate.ideaWide || '')].filter(Boolean) : [])
        .concat([
            implReport
                ? 'NAVIGATION — the implement fixlog is ON DISK at ' +
                  implReport +
                  ': read its `files` and `seamsTouched` rows only (locations — where you look FIRST, never what you conclude); ' +
                  "its verdicts and summaries are the author's self-report, not evidence."
                : 'NAVIGATION: the implement fixlog is absent — derive your reading order from the batch pages alone.',
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
                'resolves to the stronger form, never a revert. Grade the OWNERSHIP the seam implies against the branch ' +
                'ARCHITECTURE.md [02]-[SEAMS] ledger read at source: a concern owned twice, a page reaching into a sibling ' +
                'interior where a recorded seam belongs, or a concern scattered across folders is repaired at the owning end ' +
                'or recorded as a seam row — the terminal reviewer grades strata depth, so yours is the ownership question ' +
                'the pages in front of you answer.\n' +
                '- CAPABILITY-COMPLETENESS + ILLUSION: verify the body implements what names and prose promise; close any ' +
                'admitted capability the owner omits per BUILD LAW; attack both naivety axes.\n' +
                'Return the batched fix-log — `deltas` and `deferred` exact. ' +
                HARVEST_LAW,
        ])
        .join('\n\n');

const redteamPrompt = (L, batch, sibling, half, dossiers, ideate, scopes, roster, unmapped, implReport, crit, lbase, pack) =>
    preamble(L, batch, dossiers, ideate, scopes, roster, unmapped, 'claude', lbase, pack)
        .concat([
            sibling.length
                ? 'TWIN HALF — this batch runs as TWO concurrent half-scope chains (implement -> critique -> redteam); you ' +
                  'are the terminal reviewer of half ' +
                  half +
                  ' and own ONLY the pages the TASK names. The sibling chain is a LIVE CONCURRENT WRITER over: ' +
                  JSON.stringify(sibling.map((p) => p.page)) +
                  ' — an edit inside its pages is recorded in `deferred`, never raced; its seam-ledger rows compose per the ' +
                  "ledger law. The implement and critique fixlogs below are YOUR half's chain — fold their surviving rows " +
                  'forward IN FULL; the sibling chain folds its own.'
                : '',
            implReport
                ? 'IMPLEMENT FIXLOG (UNVERIFIED): ON DISK at ' +
                  implReport +
                  ' — read it IN FULL; its `files`/`deltas`/`seamsTouched` rows are navigation (where to look first), its ' +
                  'verdicts refutation targets judged against CURRENT disk, never a settled record. FOLD-FORWARD DUTY: its ' +
                  'surviving `seamsTouched`, `deltas`, `deferred`, `beyondMap`, `indexRows`, and `harvest` rows fold into ' +
                  'YOUR return IN FULL, re-verified against current disk and deduped.'
                : 'IMPLEMENT FIXLOG: absent — judge from CURRENT disk alone.',
            crit && crit.ok
                ? 'PRIOR CLAIMS (UNVERIFIED): the critique fixlog is ON DISK at ' +
                  crit.report +
                  ' — read it IN FULL; its edits and verdicts are refutation targets judged against CURRENT disk, never a ' +
                  'settled record. FOLD-FORWARD DUTY: its surviving `seamsTouched`, `deltas`, `deferred`, `beyondMap`, ' +
                  '`indexRows`, and `harvest` rows fold into YOUR return IN FULL, re-verified against current disk and ' +
                  "deduped — your fix-log is this half chain's consolidated record; a dropped fixlog row is a silent loss."
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
                'CLAIMS seam landed BOTH ends; make any missed repair yourself. DEPTH FLOOR: every dimension (A)-(G) runs ' +
                'against EVERY page before any return — a pass that lands a token pair of edits without exhausting the ' +
                'dimensions has failed; edit count follows what the attack finds (a genuinely clean page after a full attack ' +
                'is a first-class verdict, a shallow attack is not). Return the batched fix-log — `deltas` and `deferred` ' +
                'exact, `armed` the exact paths read in full per the READ LAW. ' +
                HARVEST_LAW,
        ])
        .join('\n\n');

const ideasRealizePrompt = (L, pkg, ideaFiles, scopes, pack) =>
    [
        CONTEXT(L),
        REG.claude.stance(L),
        BUILD_LAW(L),
        BODY(L),
        VERIFY(L),
        RIPPLE_LAW,
        CURRENT_STATE,
        PROSE_COMMENTS(L),
        IMPL_READ(L, pkg, '', pack),
        LEDGER(scratchBase(pkg, 'ideas'), scopes),
        'TASK: IDEAS REALIZATION for `' +
            pkg +
            "` — the package's batches have landed; you implement its residual idea pool against the CURRENT corpus. Read " +
            'EVERY idea dossier IN FULL — the per-folder files, then the package-wide file: `' +
            ideaFiles.join('`, `') +
            '`. Then group every entry by the OWNER PAGE it grows on and drain PAGE BY PAGE — a page opens once, takes all of ' +
            'its entries in one composed pass, and closes before the next opens; entry order inside a page is yours. Dossier ' +
            'order is authoring order, never work order: draining it entry-major re-opens the same page three and four times ' +
            'and re-buys its context on every return. Per entry, exactly one outcome: (1) REALIZED-PRIOR — current disk already carries ' +
            'the capability fully or in a stronger form: record the landing anchor, never re-build. (2) IMPLEMENTED-NOW — disk ' +
            "admits the entry: build it at the strongest form the doctrine allows, in the owning pages' existing form, growth " +
            'as cases, rows, fields, and operations on existing owners, seams aligned both ends per RIPPLE LAW. You are the ' +
            "run's SOLE author for [NEW_PAGE] and [NEW_FOLDER] entries: a grounded [NEW_PAGE] is authored ground-up at the " +
            'doctrine bar in the code-fence-first form of its mature siblings, wired both ends into the seams its entry names, ' +
            'its index-doc rows via `indexRows`; a grounded [NEW_FOLDER] is authored COMPLETE — every roster page at that same ' +
            'bar — or not at all: a partial folder is forbidden, and a folder you cannot complete is CARDED whole. (3) CARDED — ' +
            'gated on a decision, a provenance-bound data source, or a frozen wire: one fully-specified card row via ' +
            '`indexRows` targeting the owning IDEAS.md, naming the gate. (4) DECLINED — the value claim fails re-derivation ' +
            'against current disk: the reason rides `summary`. Ambition is the charter here and truth outranks it: never ' +
            'fabricate provenance-bound data, never unfreeze a wire, never force a gated ruling. LEDGER DUTY: every entry ' +
            'you touch gets exactly one `ideasWorked` row, the outcome above mapped onto the row vocabulary — REALIZED-PRIOR ' +
            'and IMPLEMENTED-NOW are `landed` (a prior-pass entry you rebuilt from shallow to strength is `deepened`), ' +
            'CARDED is `unrealized` with `where` naming the card, DECLINED is `declined`. Your ledger is the ONLY record of ' +
            'this pass: your product returns over the wire, so an entry you leave unrecorded reaches the collator and the ' +
            'disposition as an idea nobody ever read. Return the fix-log — ' +
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
            ? 'ORPHANED FIXLOGS (implement/critique fixlogs whose redteam halves never landed — read each IN FULL from disk; ' +
              'their surviving deferred rows join the candidate pool): ' +
              JSON.stringify(orphans)
            : '',
        'CORRECTIONS CENSUS dossiers (read each IN FULL; every row joins the candidate pool): ' + JSON.stringify(census),
        'PER CANDIDATE: open the named files on CURRENT disk. A row disk already resolves is CULLED with the resolving anchor ' +
            'as its receipt. Rows naming the same defect across sources MERGE into one row carrying every anchor and a joined ' +
            'source tag. A survivor states the defect as FACT with owner, files, and typed anchors — information and constraint ' +
            'boundary, never a prescribed fix. PKG KEY: each survivor carries `pkg` = the owning package root (the path before ' +
            '`/.planning/`) when EVERY file and ripple endpoint of the row sits under that one package, and `pkg` = "" when the ' +
            'row crosses packages, touches a central manifest, or lives in a branch-level doc — the fixer fan partitions on ' +
            'this key, so a mis-keyed row lands with the wrong writer. Group survivors by pkg, then owner: shared owners and ' +
            'registries before consumers.',
        "COMPLETENESS — you consume the whole run's pool under one budget, so exhausting it before the budget is the normal " +
            'outcome, never the assumed one. Every candidate ends in exactly one place: `live`, `culled` with its receipt, or ' +
            '`unreached` naming the row and its source. A row that reaches none of the three is deleted evidence — the engine ' +
            're-feeds the raw sets to the fixers precisely so an honest `unreached` costs nothing, while a silent drop removes ' +
            'the row from the run. Order the drain by leverage so the rows most likely to matter clear first: cross-package ' +
            'and shared-owner rows, then per-package rows, then local prose.',
        REG[reg].selfCheck,
    ]
        .filter(Boolean)
        .join('\n\n');

const ideasCollatorPrompt = (sets, wireRows, reg) =>
    [
        ROOT_LAW,
        'Rasm monorepo — the libs/ planning corpora. The Ideate phase authored per-sub-folder and package-wide idea dossiers ' +
            'per package; the build stages realized entries at their own discretion.',
        'TASK: IDEAS COLLATOR (read-only over the corpus; investigate, do NOT edit). Read every dossier IN FULL — per ' +
            'package, the per-folder files then the package-wide file: ' +
            JSON.stringify(sets) +
            ' — and status EVERY entry against CURRENT disk into one collated ledger: realized (the run landed the capability ' +
            'fully or in a form at least as strong — anchor the landing), unrealized (still valuable and absent — re-derive the ' +
            'ground from current disk, never copy the stale dossier anchor), or superseded (current disk carries a stronger ' +
            'form or the doctrine forbids it — anchor the superseding fact). The dossiers are PRE-RUN snapshots; every judgment ' +
            're-derives from disk. Entries stay ambition and information — never a prescription or a ruled design — and the ' +
            'ledger is TOTAL: one row per dossier entry, none dropped.',
        'WRITER LEDGERS (navigation, never evidence) — the build writers recorded what they met as `ideasWorked` rows in ' +
            'their fixlogs under `' +
            SCRATCH +
            "/`: `jq -s '[.[].ideasWorked[]?]' " +
            SCRATCH +
            '/impl-*-report.json ' +
            SCRATCH +
            '/crit-*-report.json` collates them in one call. The terminal reviewers and the per-package realization writers ' +
            'return over the wire and write NO report file, so their rows reach you only here — carrying the deepest ' +
            'realization work of the run: ' +
            JSON.stringify(wireRows) +
            '. A row tells you WHERE to look first and which entries a writer ' +
            'claims to have declined; it never settles status — a `landed` row over a page that does not carry the capability ' +
            'is status `unrealized`, and an entry no row mentions is statused from disk exactly like every other. Absent or ' +
            'malformed ledgers change nothing: disk is the only evidence.',
        REG[reg].selfCheck,
    ].join('\n\n');

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
const FINDING_CONSUMPTION =
    'each finding is a SIGNAL, not law: re-open its anchors before editing — anchors behind an edit, cited members, seams, ' +
    'and manifest rows re-verify MANDATORY; `mechanism`/`owner`/`reject`/`acceptance` are the constraint boundary — honor ' +
    'the owner and rejected forms, but the DESIGN is yours: implement the STRONGEST resolution the boundary admits, never a ' +
    'single-point patch, landing the denser root-level reconstruction where the implied fix is weak; a finding with a dead ' +
    'anchor, already resolved on disk, or graded `hypothetical` with no substantive re-derivation is rejected with reason. ' +
    'Group findings by `claimKey` (the same key across lanes is ONE defect with corroborating evidence) and order work by ' +
    '`severity` then `owner`.';

// SLICE FIXER — the Close drain fans over LOC-balanced PAGE slices, not packages: the run arrives with every work row
// typed and naming its exact files, so a package-grain partition throws that resolution away and collapses to ONE
// writer whenever a run targets one package. Territory is this lane's page set; concurrency law is Build's, proven at
// fourteen live writers — sibling scopes declared, seam ledger on disk, expand-form bound on foreign pages, `deferred`
// for anything a live sibling owns. Index docs are the one surface no slice may write: two slices inside one package
// would both target its ARCHITECTURE.md, so every slice EMITS `indexRows` and the terminal sweeper applies them once.
const sliceFixerPrompt = (L, tag, pages, siblings, roster, unmapped, work, backlog, orphans, censusPaths, failed, lbase) =>
    [
        ROOT_LAW,
        BAR_LINES([L.key]),
        HUNT,
        CATALOG_APPEND,
        SOLO_LAW,
        PROSE_COMMENTS(L),
        SCOPE_BOUND,
        CURRENT_STATE,
        LEDGER(lbase, JSON.stringify(siblings)),
        GIT_GROUND,
        'TASK: SLICE FIXER `' +
            tag +
            '` (WRITER) — full write authority over YOUR PAGES and libs-wide ripple authority for rows anchored in them, ' +
            'with the expand-form bound LIFTED inside your own pages (collapse, rename, and contract are yours there). ' +
            'YOUR PAGES: ' +
            JSON.stringify(pages) +
            '.\nTERRITORY BOUND — sibling slices are LIVE CONCURRENT WRITERS over the pages listed in the ledger block ' +
            'above. Inside your pages you rule. Outside them: a first-order ripple your edit opens is repaired NOW in ' +
            'EXPAND-FORM only (add the case, row, field, operation, or counterpart) and recorded in `seamsTouched`; a ' +
            "rename, removal, or collapse of a foreign surface, and ANY edit inside a live sibling's pages, is recorded " +
            'in `remaining` with its blocker and never raced. A row demanding a central manifest, a branch-level doc, or ' +
            'an index doc is NOT yours — blocker `sweeper`.\n' +
            '(1) INDEX ROWS — you APPLY NONE. The owning-package ARCHITECTURE.md, README.md, and IDEAS.md are ' +
            'decision-carrying single-writer surfaces your siblings share, so every index or IDEAS row your work demands ' +
            'returns as an exact `indexRows` row for the sweeper to apply once. Emitting the row IS the work; writing the ' +
            'doc is the collision.\n' +
            (work
                ? '(2) VERIFIED WORK DOSSIER — ON DISK at ' +
                  work +
                  ': pre-verified rows, each naming its `files`. Read it IN FULL; every live row whose files sit in YOUR ' +
                  'PAGES is yours — re-open its anchors before the edit (freshness stays yours), fix at root or reject ' +
                  'with reason. A row whose files sit in a sibling slice is NOT yours and gets no edit and no note; a ' +
                  'cross-package (pkg="") row is the sweeper\'s. Spot-check a sample of the culled receipts; never ' +
                  're-litigate the culled set. That dossier is the CONSOLIDATED SPINE, never the whole pool: the verifier ' +
                  'works one budget over the entire run, so the raw sets below are the unconsolidated remainder and every ' +
                  'row of theirs intersecting your pages — neither live nor culled there — is yours to re-verify and ' +
                  'drain under the same law. Dedupe against the dossier first; a row it already carries is worked once.\n'
                : '') +
            '(2a) DEFERRED BACKLOG rows intersecting your pages (re-verify each {files, claim} on current disk, fix what ' +
            'holds, reject what disk already resolved): ' +
            JSON.stringify(backlog) +
            '.\n' +
            (orphans && orphans.length
                ? '(2b) ORPHANED FIXLOGS (implement/critique fixlogs whose redteam never landed — read each IN FULL from ' +
                  'disk; drain the seam/deferred rows intersecting your pages, return their index rows via `indexRows`, ' +
                  'fold surviving harvest rows into your `harvest` return): ' +
                  JSON.stringify(orphans) +
                  '.\n'
                : '') +
            (censusPaths && censusPaths.length
                ? '(2c) CORRECTIONS CENSUS shards — `' +
                  censusPaths.join('`, `') +
                  '` (read each IN FULL; every row over YOUR PAGES not already resolved on current disk is yours: land it ' +
                  'at its root or reject with reason).\n'
                : '') +
            '(3) FINDER REPORTS — products ON DISK as JSON report files; the ROSTER receipts are navigation, never the ' +
            'product. Read every ok report IN FULL from disk, governance finders first; drain the findings whose files ' +
            'sit in YOUR PAGES — a finding over a sibling slice is not yours. ' +
            FINDING_CONSUMPTION +
            " A failed finder's territory intersecting your pages gets your own cold read. UNMAPPED: " +
            JSON.stringify(unmapped) +
            ' ROSTER: ' +
            JSON.stringify(roster) +
            '.\n' +
            '(4) OWN HUNT: hunt PAST the signal list — the hunt classes over YOUR PAGES — and fix what the finders ' +
            'missed; `beyond` enumerates those fixes, and an empty `beyond` attests the hunt found nothing, never that it ' +
            'did not run.\n' +
            'Wire-canonical names stay frozen. FAILED PAGES (reported, not landed — never author them here; correct any ' +
            'claim that pretends they landed): ' +
            JSON.stringify(failed) +
            '. Return the fixlog — `indexRows` carries every index/IDEAS row your work demands, `remaining` ONLY rows ' +
            'verified still-open that are blocked or outside your territory bound, each naming its blocker and owner; a ' +
            'row disk already resolved is culled with proof in `rejected`. ' +
            HARVEST_LAW,
    ].join('\n\n');

// Per-package ideas implementer — chained AFTER the package fixer so no two writers share the package; realizes the
// unrealized ledger remainder with a dedicated context instead of starving behind defect work. Declines are not
// defects — the disposition writer rules final outcomes and owns all IDEAS.md carding.
const ideasImplementPrompt = (L, pkg, ledgerPath, ideaFiles, pack) =>
    [
        CONTEXT(L),
        BUILD_LAW(L),
        BODY(L),
        VERIFY(L),
        PROSE_COMMENTS(L),
        IMPL_READ(L, pkg, '', pack),
        'TASK: IDEAS IMPLEMENTER for `' +
            pkg +
            '` — the defect drain for this package is closed; you realize its unrealized idea entries against CURRENT disk. ' +
            (ledgerPath
                ? 'The collated ideas ledger ON DISK at `' +
                  ledgerPath +
                  '` statuses every entry; your work list is its entries with pkg = `' +
                  pkg +
                  '` and status `unrealized` — re-derive each against current disk (the collation predates the fixer fan).'
                : 'No ledger landed — read the package idea dossiers IN FULL and status every entry against current disk ' +
                  'yourself: `' +
                  ideaFiles.join('`, `') +
                  '`.') +
            ' Group your work list by the OWNER PAGE each entry grows on and drain PAGE BY PAGE — a page opens once, takes all ' +
            'of its entries in one composed pass, and closes before the next opens. Per entry, exactly one outcome: ' +
            'REALIZED-NOW — disk admits it: build the STRONGEST form the doctrine allows, in ' +
            "the owning pages' existing form, growth as cases, rows, fields, and operations on existing owners, seams aligned " +
            'both ends. A `[NEW_PAGE]` or `[NEW_FOLDER]` entry still unrealized at this point is YOURS on the same terms the ' +
            'Build realization writer held — a grounded new page is authored ground-up at the doctrine bar in its mature ' +
            "siblings' form and wired both ends into the seams its entry names, a new folder is authored COMPLETE or not at " +
            'all, and either lands its index rows via `indexRows`; no writer follows you for that entry, so declining one you ' +
            'could ground cards a capability the run could have built. DECLINED — gated on a decision, a provenance-bound ' +
            'data source, a frozen wire, or a value claim that ' +
            'fails re-derivation: record the entry and reason in `summary`, edit nothing — the disposition writer cards it. ' +
            'Never fabricate provenance-bound data, never unfreeze a wire, never force a gated ruling. LEDGER DUTY: every ' +
            'entry on your work list gets exactly one `ideasWorked` row — REALIZED-NOW is `landed` with the page anchor ' +
            '(`deepened` where you rebuilt a shallow prior realization), DECLINED is `declined` with the gate or the failed ' +
            'value claim. You are the LAST realizer before disposition, so a row you omit leaves that entry statused from ' +
            'stale collation alone. Return the fixlog — ' +
            '`deltas` exact, `deferred` for ripples outside the package. ' +
            HARVEST_LAW,
    ].join('\n\n');

// The terminal sweeper — ONE scoped pass, the run's last corpus writer before the disposition/doctrine pair: slice
// remainders, dead-slice pages, cross-package rows, the central manifests no slice may touch, and EVERY index row —
// the slice fan emits index rows and applies none, so this lane is the single writer that lands them.
const sweeperPrompt = (
    langs,
    fixerReports,
    deadPages,
    work,
    indexRows,
    backlogGlobal,
    orphansGlobal,
    censusGlobal,
    roster,
    unmapped,
    failed,
    pages,
) =>
    [
        ROOT_LAW,
        BAR_LINES(langs),
        HUNT,
        CATALOG_APPEND,
        SOLO_LAW,
        PROSE_COMMENTS(langs),
        SCOPE_BOUND,
        GIT_GROUND,
        "TASK: TERMINAL SWEEPER (WRITER — the run's LAST corpus agent; only the ideas-disposition and doctrine " +
            'terminals follow, on disjoint surfaces, so any corpus defect you leave meets no further writer this run): ' +
            'full write authority, libs-wide ripple authority with the expand-form bound ' +
            "LIFTED, and the run's SOLE writer for the central manifests and every cross-package or branch-level doc. ONE " +
            'scoped pass — drain the named sets below, nothing else re-litigates. Landed pages: ' +
            JSON.stringify(pages) +
            '.\n' +
            '(1) SLICE FIXLOGS — ON DISK: ' +
            JSON.stringify(fixerReports) +
            ': read each IN FULL. Every `remaining` row was verified still-open by its slice — fix each at its root now ' +
            '(rows tagged `sweeper` are exactly the out-of-bound work reserved for you). Every `indexRows` row a slice ' +
            'emitted is YOURS to apply: the slices deliberately wrote no index doc, so these rows exist nowhere else and ' +
            "are lost if you skip them. Fold each fixlog's harvest rows into your `harvest` return, re-verified and deduped.\n" +
            (deadPages.length
                ? "(2) DEAD SLICE PAGES — these pages' slice fixer never landed, so their whole drain is yours: " +
                  JSON.stringify(deadPages) +
                  ' — the work-dossier rows, census rows, orphaned fixlogs, and finder findings over them drain under the ' +
                  'same law as (1), and their index rows were never emitted, so derive them yourself.\n'
                : '') +
            "(3) INDEX ROWS — the run's complete pending set, package and global alike; you are their SOLE writer. Apply " +
            'each to its owning doc exactly once (the package ARCHITECTURE.md + README.md + IDEAS.md at the path before ' +
            '`/.planning/`, the branch-level docs, the central manifests), dedupe semantically identical rows across ' +
            "slices, keep each doc's section grammar, and verify every landed page is truthfully reflected; a " +
            'central-manifest row hand-edits the grouped manifest at the SYMBOL anchor (never a line number), preserving ' +
            'label-group order: ' +
            JSON.stringify(indexRows) +
            '.\n' +
            (work
                ? '(4) CROSS-PACKAGE WORK — the verified work dossier ON DISK at ' +
                  work +
                  ': rows with pkg="" are yours; re-open anchors before each edit, fix at root or reject with reason. That ' +
                  'dossier is the CONSOLIDATED SPINE, never the whole pool — the verifier works one budget over the entire ' +
                  'run, so the raw sets below are the unconsolidated remainder and every cross-package row of theirs the ' +
                  'dossier carries neither live nor culled is yours, deduped against it first.\n' +
                  '(4a) CROSS-PACKAGE BACKLOG (re-verify each {files, claim} on current disk): ' +
                  JSON.stringify(backlogGlobal) +
                  '.\n' +
                  (orphansGlobal.length ? '(4b) UNCLAIMED ORPHANED FIXLOGS: ' + JSON.stringify(orphansGlobal) + '.\n' : '') +
                  (censusGlobal.length ? '(4c) UNCLAIMED CENSUS DOSSIERS: ' + JSON.stringify(censusGlobal) + '.\n' : '')
                : '(4) CROSS-PACKAGE BACKLOG (re-verify each {files, claim} on current disk): ' +
                  JSON.stringify(backlogGlobal) +
                  '.\n' +
                  (orphansGlobal.length ? '(4b) UNCLAIMED ORPHANED FIXLOGS: ' + JSON.stringify(orphansGlobal) + '.\n' : '') +
                  (censusGlobal.length ? '(4c) UNCLAIMED CENSUS DOSSIERS: ' + JSON.stringify(censusGlobal) + '.\n' : '')) +
            '(5) FINDER REPORTS — read every ok report from disk and drain ONLY the findings under no live package territory ' +
            '(cross-libs files, branch docs, dead territories). ' +
            FINDING_CONSUMPTION +
            ' UNMAPPED: ' +
            JSON.stringify(unmapped) +
            ' ROSTER: ' +
            JSON.stringify(roster) +
            '.\n' +
            '(6) OWN HUNT over the governance surface — branch ARCHITECTURE.md seam ledgers, central manifests, cross-package ' +
            'seams — `beyond` enumerates those fixes; an empty `beyond` attests the hunt found nothing, never that it did not ' +
            'run.\n' +
            'Every ripple an edit exposes is YOURS in the same pass; wire-canonical names stay frozen; a foreign-language ' +
            "repair holds that branch's doctrine bar. FAILED PAGES (reported, not landed — never author them here; correct " +
            'any claim that pretends they landed): ' +
            JSON.stringify(failed) +
            '. Return the final fixlog — `remaining` carries ONLY rows verified still-open and genuinely blocked, each naming ' +
            'its blocker and owner; an empty `remaining` attests the run closed. ' +
            HARVEST_LAW,
    ]
        .filter(Boolean)
        .join('\n\n');

const dispositionPrompt = (sets, pages, ledgerPath, wireRows, implReports) =>
    [
        ROOT_LAW,
        'Rasm monorepo — the libs/ planning corpora. The run just landed a hostile rebuild over these pages: ' + JSON.stringify(pages) + '.',
        ledgerPath
            ? 'NAVIGATION: the collated ideas ledger ON DISK at ' +
              ledgerPath +
              ' statuses every entry as of its pre-fixer collation — the fixer may have realized more since, so it routes your ' +
              'reading order and nothing else; every outcome re-derives from CURRENT disk.'
            : '',
        'WRITER LEDGERS (navigation, never evidence) — every realizing lane recorded what it met as `ideasWorked` rows. ' +
            'The wire-only lanes (terminal reviewers, per-package realization writers) carry theirs here: ' +
            JSON.stringify(wireRows || []) +
            '. The batch writers left theirs on disk under `' +
            SCRATCH +
            "/`: `jq -s '[.[].ideasWorked[]?]' " +
            SCRATCH +
            '/impl-*-report.json ' +
            SCRATCH +
            '/crit-*-report.json' +
            (implReports && implReports.length ? ' ' + implReports.join(' ') : '') +
            '` collates them in one call — the ideas-implementer reports are the LATEST realization pass, later than the ' +
            'collated ledger. A row routes your reading; it never settles an outcome, and an entry no row mentions is judged ' +
            'from disk exactly like every other.',
        'TASK: IDEAS DISPOSITION (WRITER — the sole IDEAS.md author at this point of the run). The Ideate phase produced ' +
            'per-sub-folder and package-wide idea dossiers per package — ambition worklists the batch writers, per-package ' +
            'realization writers, and ideas implementers realized at their own discretion. Read every dossier IN FULL, per ' +
            'package the per-folder files then the package-wide file: ' +
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

// Static run topology — the unit split and batch packing derive from page paths alone, before any lane runs, so every
// package chain launches against a settled batch map; only the LIVE-scope view over it narrows as batches close.
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
            return { pkg, sub, name, key: pkg + '|' + name, tag: pkgTag(pkg) + '.' + name, pages: seg };
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
// LIVE scopes, computed per writer at prompt-build time — the ledger law calls these "another LIVE batch's scope" and
// makes every listed page defer-only. A static whole-run snapshot keeps finished batches listed forever, so the run's
// last writers defer against siblings that closed hours earlier: coverage the fixers must re-drain, and the largest
// single inflator of the deferred backlog. A batch drops out the moment its half chains settle.
const DONE_BATCHES = new Set();
const scopesFor = (selfTag) =>
    JSON.stringify(
        BATCHES.map((b) => ({ batch: pkgTag(b.pkg) + ':b' + b.i, pages: b.pages.map((p) => p.page) })).filter(
            (r) => r.batch !== selfTag && !DONE_BATCHES.has(r.batch),
        ),
    );

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
        // Native: the pack REPLACES the doctrine atlas for every implement, critique, and redteam lane in the run,
        // so a section it silently truncates or paraphrases is law the whole run never sees — verbatim relocation
        // reads cheap and fails invisibly, which is exactly the shape that earns the stronger reader, not a cheaper one.
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
phase('Ideate');
phase('Build');
// PER-PACKAGE PIPELINE — Map, Ideate, and Build are package-local stages, never run barriers: a package's
// ideate fires the moment ITS unit lanes land and its batch chains the moment its ideate lands, so no
// package waits on a sibling's slowest lane. Every agent carries its explicit phase label, the slot
// scheduler is the only cross-package governor, live batch scopes + the seam ledger own cross-batch coordination,
// and Close is the one whole-run barrier.
// Corpus map ONCE per SUB-FOLDER unit, reused by every batch touching that unit: a deep-map lane (context/seams)
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
                // Native: this dossier is MANDATORY full reading for every implement, critique, and redteam lane touching
                // the unit, so its depth caps what those writers can navigate — the run's highest-leverage read artifact.
                ropts('map:ctx:' + tag, 'Map', CTX_SCHEMA, scope, { arr: 'worklist', group: 'kind' }, { writes: true, native: true, calls: 110 }),
            ),
        ).catch(() => null),
        slot(() =>
            recon(
                (reg) => apiLensPrompt(L, unitPages, apiDossier, reg),
                // Judgment work, not navigation: the two-tier diff, depth grading, and full-tier triage; medium effort —
                // the products are typed rows. Its ctx sibling stays navigation (seams/ownership).
                ropts('map:api:' + tag, 'Map', API_SCHEMA, scope, { arr: 'worklist' }, { writes: true, codexEffort: 'medium', calls: 80 }),
            ),
        ).catch(() => null),
    ]);
    unitMap[u.key] = { ctx, api, ctxDossier, apiDossier };
};
// TWO lanes per owning package with disjoint charters: a corrections census (the fix addendum the batches land as
// rung 3) and ONE ideas author (the capability ambition, rung 4) writing one dossier per sub-folder and the
// package-wide dossier — a single author keeps the pool internally coherent across both grains. One merged log regresses
// to a fixlog and the ambition dies. Either lane absent (dead map or dead ideate), the executors run without that rung.
const pkgIdeate = {};
const ideatePkg = async (pkg) => {
    const L = Lof(pkg);
    const tag = pkgTag(pkg);
    const subs = [...new Set(PAGES.filter((p) => pkgOf(p.page) === pkg).map((p) => subOf(p.page)))];
    const subRows = subs.map((sub) => ({ sub, path: dossierPath('ideate:idea:' + tag + ':' + sub) }));
    const widePath = dossierPath('ideate:idea:' + tag + ':_wide');
    const mapIndexOf = (group) =>
        UNITS.filter((u) => u.pkg === pkg && group.includes(u.sub))
            .map((u) => ({
                sub: u.name,
                // `|| {}` keeps a dead map lane a MISSING DOSSIER, never a TypeError that converts it into a dead package chain.
                deepMap: ((unitMap[u.key] || {}).ctx?.ok && unitMap[u.key].ctxDossier) || null,
                inventory: ((unitMap[u.key] || {}).api?.ok && unitMap[u.key].apiDossier) || null,
            }))
            .filter((r) => r.deepMap || r.inventory);
    const mapIndex = mapIndexOf(subs);
    if (!mapIndex.length) {
        pkgIdeate[pkg] = { fixBySub: {}, ideaBySub: {}, ideaWide: '' };
        return;
    }
    // Census shards by unit count — one lane per CENSUS_SUBS sub-folders, disjoint territories: a single census
    // over a large package verifies shallowly at the tail; per-shard depth keeps every row disk-verified. Cross-shard
    // dupes are rare (corrections are folder-local) and the Close backlog verifier merges them anyway.
    const shards = chunk(subs, CENSUS_SUBS).map((group, i, all) => ({
        group,
        path: dossierPath('ideate:fix:' + tag + (all.length > 1 ? ':s' + (i + 1) : '')),
        label: 'ideate:fix:' + tag + (all.length > 1 ? ':s' + (i + 1) : ''),
    }));
    const [idea, ...fixes] = await Promise.all(
        // Every member is guarded: a REJECTION here (not merely an ok=false receipt) rejects the Promise.all, throws out of
        // ideatePkg, and lands in the package catch BEFORE the batch fan — costing the package every batch, not its ideas.
        [
            slot(() => agent(ideasPrompt(L, pkg, mapIndex, subRows, widePath), wopts('ideate:idea:' + tag, 'Ideate', 'fable', RECEIPT))).catch(
                () => null,
            ),
        ].concat(
            shards.map((s) =>
                slot(() => agent(correctionsPrompt(L, pkg, mapIndexOf(s.group), s.path, s.group), wopts(s.label, 'Ideate', 'opus', RECEIPT))).catch(
                    () => null,
                ),
            ),
        ),
    );
    const ideaOk = !!(idea && idea.ok);
    const fixBySub = {};
    shards.forEach((s, i) => {
        if (fixes[i] && fixes[i].ok) for (const sub of s.group) fixBySub[sub] = s.path;
    });
    pkgIdeate[pkg] = {
        fixBySub,
        ideaBySub: ideaOk ? Object.fromEntries(subRows.map((r) => [r.sub, r.path])) : {},
        ideaWide: (ideaOk && widePath) || '',
    };
    log(
        'Ideate ' +
            tag +
            ': ' +
            fixes.filter((f) => f && f.ok).length +
            '/' +
            shards.length +
            ' census shard(s), ' +
            fixes.reduce((a, f) => a + ((f && f.ok && f.entries) || 0), 0) +
            ' correction(s) + ' +
            (ideaOk ? (idea.entries || 0) + ' idea(s) across ' + (subRows.length + 1) + ' dossier(s)' : 'no ideas'),
    );
};

// Per batch: a page-scoped bar lens (judgment-weighted, like the close finders), then ONE LOC-balanced half partition
// drives twin half-scope chains — implement -> critique -> redteam per half, each half a fully independent
// chain over half the batch tonnage (focus per file over thrash), the SAME partition across all three stages so fixlog
// routing is exact: a half's redteam folds ITS half's implement + critique fixlogs, nothing crosses. Failure isolates
// per half — a dead implement fails only its half's pages. Isolation covers REJECTION as well as an ok=false receipt:
// every lane await in the chain is `.catch`-guarded, since an unguarded rejection escapes runBatch and discards BOTH
// half records, stranding a sibling whose fixlogs already landed on disk. Ctx/api grounding reused from the owning unit dossiers.
const runBatch = async (b) => {
    const tag = pkgTag(b.pkg) + ':b' + b.i;
    const L = Lof(b.pkg);
    const batch = b.pages.map((p) => Object.assign({}, p, { i: b.i }));
    const pageScope = batch.map((p) => p.page);
    const pms = b.units.map((u) => unitMap[u.key]).filter(Boolean);
    // Law pack resolves BEFORE the bar lens — every lane in the batch reads it in place of the atlas ladder.
    const packR = LAWPACK[L.key] ? await LAWPACK[L.key] : null;
    const pack = packR && packR.ok ? lawPackPath(L.key) : '';
    const bar = await slot(() =>
        recon(
            (reg) => barLensPrompt(L, batch, reg, pack),
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
    ).catch(() => null);
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
    const ideateP = pkgIdeate[b.pkg] || { fixBySub: {}, ideaBySub: {}, ideaWide: '' };
    const halves = halve(batch);
    const halfRecords = await Promise.all(
        halves.map(async (half, hi) => {
            const sibling = halves.length > 1 ? halves[1 - hi] : [];
            const halfTag = tag + (halves.length > 1 ? '.h' + (hi + 1) : '');
            const halfScope = half.map((p) => p.page);
            const halfUnmapped = unmapped.filter((u) => halfScope.includes(u.scope));
            // Grounding scopes to the half: only the dossiers and idea files of the sub-folders its pages touch.
            const halfSubs = [...new Set(half.map((p) => subOf(p.page)))];
            const dossiers = b.units
                .filter((u) => halfSubs.includes(u.sub))
                .map((u) => unitMap[u.key])
                .filter(Boolean)
                .flatMap((m) => [m.ctx && m.ctx.ok && m.ctxDossier, m.api && m.api.ok && m.apiDossier])
                .filter(Boolean)
                .join('`, `');
            const ideate = {
                fixFiles: [...new Set(halfSubs.map((s) => (ideateP.fixBySub || {})[s]).filter(Boolean))],
                ideaSubFiles: halfSubs.map((s) => ideateP.ideaBySub[s]).filter(Boolean),
                ideaWide: ideateP.ideaWide,
            };
            const lbase = scratchBase(b.pkg, b.i) + (halves.length > 1 ? '-h' + (hi + 1) : '');
            // Implement: write lane — fixlog product on disk, receipt on the wire; the half's critique and
            // redteam read the fixlog from disk.
            const fix = await slot(() =>
                recon(
                    (reg) => implementPrompt(L, half, dossiers, ideate, scopesFor(tag), roster, halfUnmapped, pack, reg, sibling, hi + 1, lbase),
                    ropts('impl:' + halfTag, 'Build', FIXLOG_SCHEMA, halfScope, { arr: 'files' }, { writes: true, fix: true }),
                ),
            ).catch(() => null);
            if (!fix || !fix.ok) return { pkg: b.pkg, pages: half, fix, crit: null, rt: null }; // failure isolation: a dead implement skips its half's reviews
            const implReport = fix.report;
            // Critique: write lane running the full conformance audit in place over the half. It reads the
            // ambition pool under an AUDIT charter, not a realization one — grading what the implement landed and
            // deepening a shallow realization, while an absent entry is recorded for the redteam and realization writer.
            const crit = await slot(() =>
                recon(
                    (reg) =>
                        critiquePrompt(
                            L,
                            half,
                            dossiers,
                            ideate,
                            scopesFor(tag),
                            roster,
                            halfUnmapped,
                            implReport,
                            reg,
                            pack,
                            sibling,
                            hi + 1,
                            lbase + '-crit',
                        ),
                    ropts('crit:' + halfTag, 'Build', REVIEW_SCHEMA, halfScope, { arr: 'files' }, { writes: true, fix: true }),
                ),
            ).catch(() => null);
            const critR = crit && crit.ok ? crit : null;
            // Redteam: terminal reviewer for the half, folding its half's implement + critique fixlogs forward.
            const rt = await slot(() =>
                agent(
                    redteamPrompt(
                        L,
                        half,
                        sibling,
                        hi + 1,
                        dossiers,
                        ideate,
                        scopesFor(tag),
                        roster,
                        halfUnmapped,
                        implReport,
                        critR,
                        lbase + '-rt',
                        pack,
                    ),
                    wopts('rt:' + halfTag, 'Build', 'opus', RT_SCHEMA),
                ),
            ).catch(() => null);
            return { pkg: b.pkg, pages: half, fix, crit: critR, rt };
        }),
    );
    // Both half chains have settled — this batch's pages stop being live territory for every writer that starts after it.
    DONE_BATCHES.add(tag);
    return halfRecords;
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
                )
                    .filter(Boolean)
                    .flat();
                // Per-package IDEAS REALIZATION: one writer after the package's last batch implements the residual idea
                // pool (per-folder + package-wide dossiers) against the landed corpus — realization gets a dedicated
                // context instead of starving behind defect work; gated entries route to IDEAS.md as cards via indexRows;
                // Close audits the remainder.
                const ideateP = pkgIdeate[pkg] || { ideaBySub: {}, ideaWide: '' };
                const ideaFiles = Object.values(ideateP.ideaBySub || {}).concat(ideateP.ideaWide ? [ideateP.ideaWide] : []);
                if (ideaFiles.length && out.some((d) => d.fix && d.fix.ok)) {
                    const pkR = LAWPACK[Lof(pkg).key] ? await LAWPACK[Lof(pkg).key] : null;
                    const realize = await slot(() =>
                        agent(
                            ideasRealizePrompt(Lof(pkg), pkg, ideaFiles, scopesFor(''), pkR && pkR.ok ? lawPackPath(Lof(pkg).key) : ''),
                            wopts('ideas:' + pkgTag(pkg), 'Build', 'opus', FIXLOG_SCHEMA),
                        ),
                    );
                    // The realize fixlog rides the rt slot: aggregation reads rows from d.rt only (implement receipts are thin),
                    // and the realize writer is native, so its rows travel inline like a half redteam record.
                    if (realize) out.push({ pkg, pages: [], fix: null, crit: null, rt: realize });
                }
                return out;
            } catch (e) {
                log('Package chain FAILED (' + pkg + '): ' + ((e && e.message) || e));
                return [];
            }
        }),
    )
).flat();
const CENSUS_BY_PKG = Object.fromEntries(
    PKGS.map((pkg) => [pkg, [...new Set(Object.values((pkgIdeate[pkg] && pkgIdeate[pkg].fixBySub) || {}))]]).filter((r) => r[1].length),
);
const CENSUS_PATHS = Object.values(CENSUS_BY_PKG).flat();
const LANDED = built.filter((d) => d.fix && d.fix.ok).flatMap((d) => d.pages.map((p) => p.page));
// FAILED covers both a dead implement half (a record whose receipt is not ok) and a dead package chain (pages in no record).
const FAILED = PAGES.map((p) => p.page).filter((pg) => !LANDED.includes(pg));
// Implement and critique fixlogs live on disk (lane receipts are thin); each half's redteam folds its own chain's
// fixlogs forward, so aggregation reads rt only. A half whose redteam died leaves both its fixlogs ORPHANED for the fixers.
const ROWS = built.flatMap((d) => (d.rt && d.rt.indexRows) || []);
const SEAM_ROWS = built.flatMap((d) => (d.rt && d.rt.seamsTouched) || []);
const BACKLOG = built.flatMap((d) => (d.rt && d.rt.deferred) || []);
// Ledger rows of the WIRE-ONLY lanes: redteams and per-package realization writers are native agents whose product never
// lands as a report file, so the collator's on-disk impl/crit scrape cannot see them. Carried inline to both ideas terminals.
const IDEAS_WIRE_ROWS = built.flatMap((d) => (d.rt && d.rt.ideasWorked) || []);
const ORPHANS = built.filter((d) => d.fix && d.fix.ok && !d.rt).flatMap((d) => [d.fix.report, d.crit && d.crit.report].filter(Boolean));
const ORPHANS_BY_PKG = {};
for (const d of built.filter((x) => x.fix && x.fix.ok && !x.rt))
    ORPHANS_BY_PKG[d.pkg] = (ORPHANS_BY_PKG[d.pkg] || []).concat([d.fix.report, d.crit && d.crit.report].filter(Boolean));
// Run-authored NEW pages — the realization writer's [NEW_PAGE]/[NEW_FOLDER] output rides its inline rt-record `files` —
// join the finder fan and the package-fixer territories, so a fresh page meets the same attack machinery as a
// rebuilt one; index docs and foreign-package files are excluded.
const INDEX_DOC_RE = /(README|ARCHITECTURE|IDEAS|TASKLOG)\.md$/;
// Source is the REALIZATION records alone (`pages: []` — the rt slot they share with 28 redteams), never every rt record:
// a redteam's `files` is every page it edited under libs-wide RIPPLE authority, so a rippled sibling would enter here as a
// run-authored page and take a full fixer pass it was never scoped for. Paths normalize first — a lane may answer
// absolutely, and every routing predicate below is prefix-anchored, so an un-normalized absolute path drops silently.
const relPath = (f) =>
    String(f)
        .replace(ROOT_DIR + '/', '')
        .replace(/^\/+/, '');
const NEW_PAGES = [...new Set(built.filter((d) => d.rt && !(d.pages || []).length).flatMap((d) => (d.rt.files || []).map(relPath)))].filter(
    (f) => f.includes('/.planning/') && f.endsWith('.md') && !INDEX_DOC_RE.test(f) && !LANDED.includes(f) && PKGS.includes(pkgOf(f)),
);
const LANDED_ALL = LANDED.concat(NEW_PAGES);
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
// Languages derive from LANDED_ALL, matching what the fan actually slices: a page entering only through NEW_PAGES in a
// language with zero rebuilt pages would otherwise reach the fixer fan while no finder ever audits it.
const LANDED_LANGS = [...new Set(LANDED_ALL.map((p) => langOf(p)).filter(Boolean))];
const finderTasks = LANDED_LANGS.flatMap((k) => {
    const langPages = LANDED_ALL.filter((p) => langOf(p) === k);
    const langSeams = SEAM_ROWS.filter((s) => langOf(s.file) === k || langOf(s.counterpart) === k);
    return chunk(langPages, FINDER_PAGES)
        .map((pages, i) => ({ gov: false, lang: k, pages, seams: langSeams, i }))
        .concat([{ gov: true, lang: k, pkgs: [...new Set(langPages.map(pkgOf))], pages: langPages }]);
});
// Two consolidation lanes ride the finder fan CONCURRENTLY: the backlog verifier turns every deferred, census,
// and orphaned-fixlog candidate into ONE pre-verified work list (stale culled with receipts, duplicates merged),
// and the ideas collator statuses every bigger-ideas entry against current disk into ONE ledger — the fixer then
// consumes final lists and the disposition writer rules outcomes, neither re-litigating the pool.
const IDEA_SETS = PKGS.map((pkg) => {
    const ip = pkgIdeate[pkg] || { ideaBySub: {}, ideaWide: '' };
    return { pkg, paths: Object.values(ip.ideaBySub || {}).concat(ip.ideaWide ? [ip.ideaWide] : []) };
}).filter((r) => r.paths.length);
const [found, work, ledger] = await Promise.all([
    Promise.all(
        finderTasks.map((t) =>
            slot(
                () =>
                    // Finders are terminal-consumed (the fixer re-verifies anchors but never re-hunts the coverage),
                    // so the fan runs one tier up at a judgment-weighted effort.
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
                                      native: true,
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
                                      native: true,
                                  },
                              ),
                          ),
                // A REJECTED finder degrades to a failed-lane record, never to null: `found` is what mints UNMAPPED, and
                // UNMAPPED is the only thing that hands a dead finder's slice to a fixer as its own cold read. Nulling the
                // lane drops its territory from coverage silently, while an ok=false receipt keeps the mandate alive.
            ).catch(() => ({
                lane: t.gov ? 'finder:gov:' + t.lang : 'finder:' + t.lang + ':s' + t.i,
                scope: t.gov ? t.pkgs : t.pages,
                ok: false,
                report: '',
                entries: 0,
                headline: '',
                failure: 'lane rejected',
            })),
        ),
    ).then((r) => r.filter(Boolean)),
    BACKLOG.length || ORPHANS.length || CENSUS_PATHS.length
        ? slot(() =>
              recon(
                  (reg) => backlogVerifierPrompt(BACKLOG, ORPHANS, CENSUS_PATHS, reg),
                  // Budget scales with the pool: this lane alone re-verifies every deferred, census, and orphan row in the
                  // run, and the default read budget truncates it into silent loss well before the candidate set is spent.
                  ropts(
                      'verify:backlog',
                      'Close',
                      WORK_SCHEMA,
                      [],
                      { arr: 'live', group: 'source' },
                      {
                          native: true,
                          calls: 240,
                      },
                  ),
              ),
          ).catch(() => null)
        : null,
    IDEA_SETS.length
        ? slot(() =>
              recon(
                  (reg) => ideasCollatorPrompt(IDEA_SETS, IDEAS_WIRE_ROWS, reg),
                  ropts(
                      'collate:ideas',
                      'Close',
                      LEDGER_SCHEMA,
                      [],
                      { arr: 'entries', group: 'status' },
                      {
                          native: true,
                          calls: 120,
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
// PACKAGE-FANNED DRAIN: one fixer per landed package, ALL concurrent — territories are path-disjoint by
// construction (out-of-bound rows return tagged `sweeper`, never edited), so no single closer pools the whole run's
// residuals. Each package chains its ideas implementer AFTER its fixer, keeping same-package writers serial while
// packages stay parallel. ONE terminal sweeper then drains the remainders, dead territories, global index rows, and
// cross-package work in one scoped pass — the drain loop is gone; `remaining` after the sweep is the run residual.
const FIXED_PKGS = [...new Set(LANDED_ALL.map(pkgOf))];
const rowPkgOf = (doc) => FIXED_PKGS.find((p) => doc === p || doc.indexOf(p + '/') === 0) || '';
const backlogPkgOf = (row) => {
    const ps = [...new Set((row.files || []).map(rowPkgOf))];
    return ps.length === 1 && ps[0] ? ps[0] : '';
};
// SLICE-FANNED DRAIN — the partition is LOC-balanced PAGE slices, never packages: every work row arrives typed and
// naming its files, so a package grain discards that resolution and degenerates to ONE writer on a single-package run.
// Slices are computed from the page list the orchestrator holds; each lane filters its own rows off disk, because the
// work dossier and finder products are files whose contents never cross the wire. Concurrency law is Build's — sibling
// scopes declared, seam ledger, expand-form bound, `deferred` for a live sibling's pages. Index docs belong to none of
// them: rows accumulate and the sweeper applies them once.
const CLOSE_LOC = 2600; // page tonnage per slice — a drain lane reads AND edits, so it holds less than a review lane
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
const pageLines = Object.fromEntries(PAGES.map((p) => [p.page, p.lines]));
// Slices never straddle a package: one language bar, one charter, one `.api` tier per lane, and a package's index rows
// stay attributable. Within a package the split is pure tonnage.
const SLICES = FIXED_PKGS.flatMap((pkg) =>
    locChunk(
        LANDED_ALL.filter((p) => pkgOf(p) === pkg).map((p) => ({ page: p, lines: pageLines[p] || 500 })),
        CLOSE_LOC,
    ).map((set, i) => ({ pkg, i, tag: pkgTag(pkg) + ':s' + i, pages: set.map((r) => r.page) })),
);
const SLICE_SCOPES = SLICES.map((s) => ({ slice: s.tag, pages: s.pages }));
log('Close drain: ' + SLICES.length + ' slice(s) across ' + FIXED_PKGS.length + ' package(s), all concurrent');
const sliceRuns = await Promise.all(
    SLICES.map((s) =>
        slot(() =>
            recon(
                () =>
                    sliceFixerPrompt(
                        Lof(s.pkg),
                        s.tag,
                        s.pages,
                        SLICE_SCOPES.filter((r) => r.slice !== s.tag),
                        found,
                        UNMAPPED,
                        WORK,
                        BACKLOG.filter((row) => (row.files || []).some((f) => s.pages.includes(f))),
                        ORPHANS_BY_PKG[s.pkg] || [],
                        CENSUS_BY_PKG[s.pkg] || [],
                        FAILED,
                        scratchBase(s.pkg, 'close' + s.i),
                    ),
                ropts('fixer:' + s.tag, 'Close', FIXER_SCHEMA, s.pages, { arr: 'remaining' }, { writes: true, fix: true, calls: 260 }),
            ),
        ).catch(() => null),
    ),
);
const FIXER_REPORTS = sliceRuns.map((r) => r && r.ok && r.report).filter(Boolean);
// A slice whose lane died leaves its pages undrained; the sweeper owns them, keyed by page rather than by package.
const DEAD_SLICES = SLICES.filter((s, i) => !(sliceRuns[i] && sliceRuns[i].ok));
const DEAD_PKGS = [...new Set(DEAD_SLICES.map((s) => s.pkg))];
const DEAD_PAGES = DEAD_SLICES.flatMap((s) => s.pages);
// Ideas implementers run AFTER the whole fan, one per package and concurrent among themselves: they are path-disjoint
// by package, and running them behind the barrier keeps them off pages a live slice still owns.
const ideasRuns = await Promise.all(
    FIXED_PKGS.map(async (pkg) => {
        const L = Lof(pkg);
        const ideateP = pkgIdeate[pkg] || { ideaBySub: {}, ideaWide: '' };
        const ideaFiles = Object.values(ideateP.ideaBySub || {}).concat(ideateP.ideaWide ? [ideateP.ideaWide] : []);
        if (!ideaFiles.length && !IDEAS_LEDGER) return null;
        const pkR = LAWPACK[L.key] ? await LAWPACK[L.key] : null;
        return slot(() =>
            recon(
                () => ideasImplementPrompt(L, pkg, IDEAS_LEDGER, ideaFiles, pkR && pkR.ok ? lawPackPath(L.key) : ''),
                ropts('ideas-impl:' + pkgTag(pkg), 'Close', FIXLOG_SCHEMA, [pkg], { arr: 'files' }, { writes: true, fix: true }),
            ),
        ).catch(() => null);
    }),
);
const IDEAS_IMPL_REPORTS = ideasRuns.map((r) => r && r.ok && r.report).filter(Boolean);
log(
    'Close drain: ' +
        FIXER_REPORTS.length +
        '/' +
        SLICES.length +
        ' slice fixer(s) + ' +
        IDEAS_IMPL_REPORTS.length +
        ' ideas implementer(s) landed' +
        (DEAD_SLICES.length ? ' — dead slice territory: ' + DEAD_SLICES.map((s) => s.tag).join(', ') : ''),
);
const sweep = await slot(() =>
    recon(
        () =>
            sweeperPrompt(
                LANDED_LANGS,
                // Ideas-implementer fixlogs ride the same set: that lane is instructed to emit `deferred` rows for ripples
                // OUTSIDE its package, and the sweeper is the run's only writer authorized to land them.
                FIXER_REPORTS.concat(IDEAS_IMPL_REPORTS),
                DEAD_PAGES,
                WORK,
                // ALL index rows, not the global remainder: the slice fan applies none, so package-scoped rows reach
                // their doc only here. Slice-emitted rows ride the fixlogs the sweeper reads in (1).
                ROWS,
                BACKLOG.filter((row) => !backlogPkgOf(row)),
                DEAD_PKGS.flatMap((p) => ORPHANS_BY_PKG[p] || []),
                DEAD_PKGS.flatMap((p) => CENSUS_BY_PKG[p] || []),
                found,
                UNMAPPED,
                FAILED,
                LANDED_ALL,
            ),
        ropts('sweeper', 'Close', FIXER_SCHEMA, [], { arr: 'remaining' }, { writes: true, fix: true, calls: 400 }),
    ),
).catch(() => null);
const sweepOk = !!(sweep && sweep.ok);
// A dead sweeper collapses to openCount 0 — byte-identical to a clean sweep, and the sweeper's own contract reads an
// empty `remaining` as proof the run closed. Log it, so the run return is never read as an attestation nobody made.
if (!sweepOk) log('Sweeper ABSENT — cross-package rows, global index rows, and fixer remainders are UNDRAINED this run');
const openCount = (sweepOk && sweep.entries) || 0;
const fixerReports = FIXER_REPORTS.concat(IDEAS_IMPL_REPORTS).concat(sweepOk && sweep.report ? [sweep.report] : []);
// TERMINAL PAIR — two disjoint-surface writers run concurrently after the drain loop closes.
// IDEAS DISPOSITION (the sole IDEAS.md author now that the fixer is done) gives every bigger-ideas dossier
// entry exactly one outcome — realized on disk, carded into the owning IDEAS.md, or rejected with reason —
// so no idea silently evaporates with the scratch dir. DOCTRINE LANDER is the run's durable-learning
// terminal — pooled harvest nominations adjudicated against the live doctrine surfaces; refutation-first,
// land-nothing legal, admission law owned by docs/laws.
// Fixer harvest rows live in the on-disk fixer fixlogs (thin receipts carry no rows) — the doctrine lander reads them there.
const HARVEST_ROWS = built.flatMap((d) => (d.rt && d.rt.harvest) || []);
const [ideas, doctrine] = await Promise.all([
    IDEA_SETS.length
        ? slot(() =>
              agent(
                  // LANDED_ALL, never LANDED: the run-authored pages are exactly the [NEW_PAGE]/[NEW_FOLDER] realizations
                  // this stage must rule on, so a census omitting them biases every such entry toward carded or rejected.
                  dispositionPrompt(IDEA_SETS, LANDED_ALL, IDEAS_LEDGER, IDEAS_WIRE_ROWS, IDEAS_IMPL_REPORTS),
                  wopts('ideas:disposition', 'Close', 'opus', IDEAS_DISP_SCHEMA),
              ),
          )
        : null,
    HARVEST_ROWS.length || fixerReports.length
        ? slot(() =>
              agent(
                  'TASK: DOCTRINE LANDER — the durable-learning terminal of this run. Read `docs/laws/README.md` ' +
                      'FIRST — it owns the corpus admission and page-shape law; obey it over any restatement. Load ' +
                      'the `docgen` skill via the Skill tool BEFORE any durable edit; load ' +
                      '`mermaid-diagramming` before touching any diagram. ' +
                      (fixerReports.length
                          ? 'FIXER FIXLOGS ON DISK (read each; its `harvest` rows join the nomination pool below at the same ' +
                            'refute-by-default bar): ' +
                            JSON.stringify(fixerReports) +
                            '\n'
                          : '') +
                      "NOMINATIONS (unverified, biased toward their authors' own work — refute by default): " +
                      JSON.stringify(HARVEST_ROWS) +
                      '\nADJUDICATE each row per the admission bar: cold-read its target surface IN FULL, verify its anchors on ' +
                      'CURRENT disk; LAND NOTHING is a first-class verdict. A landing takes the target surface at its OWN form and ' +
                      'bar: refine-over-add per the admission ladder the router states; a TRUE nomination weakly stated lands ' +
                      'at its strongest true generalization — the nominator ' +
                      'phrasing is a draft, never the ceiling; and a `stacks` landing conforms to the page-craft grammar — where ' +
                      'the lesson is code-shaped it hardens the owning family card and its snippet or fence exemplar, never a ' +
                      'prose bullet appended to a fence-taught region.\n' +
                      'TOPOLOGY RE-PROOF: re-verify every `docs/laws/topology.md` row whose [SURFACE] this run touched — cull a row ' +
                      'whose coupling no longer holds, land a coupling this run proved.\n' +
                      'GATE: run `uv run .claude/skills/docgen/scripts/prose_gate.py <every touched .md>` and repair to zero FAILs ' +
                      'before returning. Return landed/refined/rejected (each rejection with its reason)/files/summary.',
                  wopts('doctrine', 'Close', 'opus', DOCTRINE_SCHEMA),
              ),
          )
        : null,
]);

return {
    targets: TARGETS,
    languages: LANDED_LANGS,
    batches: BATCHES.length,
    landed: LANDED.length,
    newPages: NEW_PAGES.length,
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
    residuals: openCount, // count of still-open rows; the rows themselves live in the sweeper report on disk
    close: {
        slices: SLICES.length,
        sliceFixers: FIXER_REPORTS.length,
        deadSlices: DEAD_SLICES.map((s) => s.tag),
        ideasImplementers: IDEAS_IMPL_REPORTS.length,
        reports: fixerReports,
        remaining: openCount,
        headline: (sweepOk && sweep.headline) || '',
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
