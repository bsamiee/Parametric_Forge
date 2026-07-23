export const meta = {
    name: 'finalize',
    whenToUse:
        'The finalization engine — the complement to rebuild: where rebuild improves and extends, finalize corrects and closes. Run it over a package (or folder subset) whose build passes have landed: deep per-file mapping of misalignments, broken or partial logic threads, split-brain, unnecessary differentiation, entry-point sprawl, and unleveraged libs-wide seams; one consolidated work dossier; per-unit implement writers under seam-ledger coordination; a critique fan piped into per-unit red-teams; one terminal sweeper; a doctrine lander.',
    description:
        'Language-agnostic finalization pass over one libs/{csharp,python,typescript} package planning corpus. args = a package root, an array of planning sub-folders, or {targets} — {root} retargets an isolated checkout, empty = no-op; the language derives from the root and selects the doctrine root pages, both .api tiers, the manifest, and the member-verification rail. Scope resolves targets to the owning package root and its per-sub-folder page units in dependency order, each page carrying its real line count; an oversize sub-folder splits under a dual ceiling — page count AND page tonnage — so no unit alone overflows a lane. Map fans two read-only lenses per unit — an interior FLOW lens (per-file logic threads end to end, partial or naive features, split-brain, differentiation, entry-point sprawl, dead ends) and an exterior SEAM lens (libs-wide boundary and wire alignment, unleveraged upstream capability, hand-rolled reimplementation, manifest and .api drift) — each writing a typed findings report; one MERGE lane consolidates every report into a single deduped, thread-joined, owner-ordered work dossier, each cross-unit thread assigned a LEAD unit so exactly one writer owns it. Implement fans ONE writer per unit under seam-ledger coordination: own blind pass first as a disk artifact, the dossier as grounding to verify and exceed, in-unit findings and first-order ripples drained in the same pass, foreign edits additive-only with the remainder deferred as typed rows; index docs and central manifests are single-writer surfaces reported as rows, never raced. Review runs per unit as a chain: a read-only critique over the implemented unit, then a red-team WRITER folding the unit implement and critique products forward — counterfactual, long-tail, next-feature diff, full cold re-review — under the same ledger law. ONE terminal sweeper then drains every deferred row, cross-unit remainder, index and manifest row, and its own governance hunt in one scoped pass. Close: a doctrine lander adjudicates pooled harvest nominations swept from wire rows, every report harvest array, and the harvest files. Stage law lives in the prompt blocks; codex lanes quota-fall to a native twin.',
    phases: [
        {
            title: 'Scope',
            detail: 'targets resolve to the owning package root and its per-sub-folder page units with real line counts, emitted in dependency order — foundations first, a launch bias only; oversize folders split under the page-count AND tonnage ceilings',
        },
        {
            title: 'Map',
            detail: 'two read-only lenses per unit segment — interior logic flow, exterior seam integration — each writing a typed findings report; one merge lane consolidates every report into the single deduped, thread-joined work dossier, each cross-unit thread assigned its LEAD unit',
        },
        {
            title: 'Implement',
            detail: 'one writer per unit under seam-ledger coordination: own blind pass first as a disk artifact, the dossier sections it owns (its unit and its lead cross-unit threads) as grounding to verify and exceed, in-unit work and first-order ripples drained in the same pass, foreign edits additive-only with typed deferred rows for the sweeper',
        },
        {
            title: 'Review',
            detail: 'per unit, pipelined the moment its implement lands: a read-only critique over the implemented unit, then a red-team writer folding the unit implement and critique products forward — counterfactual, long-tail, next-feature diff, full cold re-review — under the ledger law; then ONE terminal sweeper drains every deferred row, cross-unit remainder, and index/manifest row in one scoped pass',
        },
        {
            title: 'Close',
            detail: 'a doctrine lander adjudicates pooled harvest nominations swept from wire rows, every report harvest array, and the harvest files; landing nothing is a first-class verdict',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const CAP = 14;
const UNIT_MAX = 8; // unit segmentation ceiling beside the tonnage ceiling — map, implement, and review lanes stay page-congruent
const UNIT_LOC = 3400; // page tonnage per unit — what actually overflows a lane's context; the dual ceiling splits on either bound
const RETRY_ATTEMPTS = 2;

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
const LANG_KEYS = [...new Set(TARGETS.map(langOf))];
const LANG_KEY = LANG_KEYS.length === 1 && LANG_KEYS[0] ? LANG_KEYS[0] : null;
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
    ('finalize-' + TARGETS.map((t) => t.split('/').pop().toLowerCase()).join('-')).replace(/[^a-z0-9.-]+/g, '-').slice(0, 60) +
    '-' +
    fnv1a(JSON.stringify(TARGETS));

// --- [MODELS] --------------------------------------------------------------------------

const S = { type: 'string' };

const PLAN_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['root', 'folders'],
    properties: {
        root: S,
        folders: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['folder', 'pages'],
                properties: {
                    folder: S,
                    pages: {
                        type: 'array',
                        items: {
                            type: 'object',
                            additionalProperties: false,
                            required: ['page', 'lines'],
                            properties: { page: S, lines: { type: 'integer' } },
                        },
                    },
                },
            },
        },
    },
}; // ARRAY ORDER IS DEPENDENCY ORDER — launch bias only, nothing serializes on it; `lines` feeds the tonnage-aware unit split

const ANCHOR = {
    // One anchor = one fact at one coordinate; interpretation never lives in an anchor row.
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

const DEFERRED = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['files', 'claim'],
        properties: { files: { type: 'array', items: S }, claim: S },
    },
}; // named-blocker rows ONLY — the run fully drains; this is never a routing channel

const DELTAS = {
    // navigation facts: what moved, as data, zero adjectives
    type: 'array',
    items: { type: 'object', additionalProperties: false, required: ['symbol', 'change'], properties: { symbol: S, change: S } },
};

// Map and critique lanes share one findings product; `harvest` rides the report so the doctrine lander sweeps it from disk directly.
const FINDINGS_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['findings', 'harvest', 'coverage', 'summary'],
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
                    'kind',
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
                    // Schema-enforced key grammar — free-text keys fracture per lane and corroboration never collides into one key.
                    claimKey: { type: 'string', pattern: '^[a-z0-9_-]+(\\.[a-z0-9_-]+){3}$' },
                    target: S, // short display label for the defect
                    files: { type: 'array', items: S }, // files the consumer must open or edit first
                    kind: {
                        type: 'string',
                        enum: [
                            'underutilized',
                            'handrolled',
                            'phantom_forgotten',
                            'phantom_lie',
                            'splitbrain',
                            'differentiation',
                            'naive',
                            'partial',
                            'flow',
                            'seam',
                            'stale',
                        ],
                    },
                    grade: { type: 'string', enum: ['substantive', 'hypothetical'] }, // substantive = concrete on-disk defect; hypothetical = requires an invented implausible input
                    severity: { type: 'string', enum: ['blocker', 'major', 'minor'] }, // bound to consequence, never prose confidence
                    claim: S, // the observed defect as fact
                    anchors: { type: 'array', items: ANCHOR },
                    mechanism: S, // WHY the current form fails the doctrine/domain — factual, zero repair verbs
                    owner: S, // canonical owner that must absorb the resolution
                    reject: { type: 'array', items: S }, // forms the repair must NOT take
                    acceptance: { type: 'array', items: S }, // signals proving resolution
                },
            },
        },
        harvest: HARVEST,
        coverage: COVERAGE,
        summary: S,
    },
};

// The merge lane authors ONE content artifact — the work dossier — and returns only this thin receipt: the per-unit jump index and coverage.
const MERGE_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['index', 'coverage', 'summary'],
    properties: {
        index: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['unit', 'sections'],
                properties: { unit: S, sections: { type: 'array', items: S } }, // sections = the dossier headers carrying this unit's work items
            },
        },
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

const INDEXROWS = {
    // doc = package index doc, central manifest, or IDEAS.md; row = the exact row text — the sweeper applies each once
    type: 'array',
    items: { type: 'object', additionalProperties: false, required: ['doc', 'row'], properties: { doc: S, row: S } },
};

const IMPL_SCHEMA = {
    // Required-but-possibly-empty deferred/indexRows/harvest are attestations: nothing blocked, nothing owed, nothing generalizable.
    type: 'object',
    additionalProperties: false,
    required: ['files', 'verdict', 'collapsed', 'realized', 'deltas', 'indexRows', 'deferred', 'harvest', 'summary'],
    properties: {
        files: { type: 'array', items: S },
        verdict: { type: 'string', enum: ['fixed', 'clean'] },
        collapsed: S,
        realized: S,
        deltas: DELTAS,
        indexRows: INDEXROWS,
        deferred: DEFERRED, // out-of-bound and named-blocker rows — the unit red-team re-judges, the sweeper drains
        harvest: HARVEST,
        summary: S,
    },
};

const RT_SCHEMA = {
    // `tranches` receipts every fed product; `beyond` attests the own hunt ran; `remaining` carries out-of-bound and named-blocker rows.
    type: 'object',
    additionalProperties: false,
    required: ['files', 'resolved', 'rejected', 'beyond', 'remaining', 'indexRows', 'tranches', 'harvest', 'summary'],
    properties: {
        files: { type: 'array', items: S },
        resolved: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['target', 'action'], properties: { target: S, action: S } },
        },
        rejected: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['finding', 'reason'], properties: { finding: S, reason: S } },
        },
        beyond: {
            type: 'array',
            items: { type: 'object', additionalProperties: false, required: ['target', 'action'], properties: { target: S, action: S } },
        },
        remaining: DEFERRED,
        indexRows: INDEXROWS,
        tranches: { type: 'array', items: S }, // one receipt line per product fed — a fed product absent here is unconsumed
        harvest: HARVEST,
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

// --- [DOCTRINE] ------------------------------------------------------------------------

const LANG = {
    // LANG carries routing data and engine-parameter rows ONLY — doctrine content is reached at source, never paraphrased here.
    cs: {
        name: 'C#',
        root: 'libs/csharp',
        shared: 'libs/csharp/.api',
        manifest: 'the package `.csproj` and the central `Directory.Packages.props` block for this package',
        verify:
            '`UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api` (assay blocked or unavailable: the `.api` catalogs + the nuget MCP for feed truth + ' +
            'Context7/exa/tavily own the fallback)',
        stackLaw:
            'read these `docs/stacks/csharp/` pages IN FULL, in this exact order: `README.md`, `language.md`, `shapes.md`, ' +
            '`surfaces-and-dispatch.md`, `rails-and-effects.md`, `boundaries.md`, `algorithms.md`, `system-apis.md` — the ' +
            'complete root set, no discovery pass; the domain/ sub-folder enters only for the shards your pages touch, chosen ' +
            'through `domain/README.md`',
    },
    py: {
        name: 'Python',
        root: 'libs/python',
        shared: 'libs/python/.api',
        manifest: 'the root `pyproject.toml` rows this package consumes',
        verify:
            '`UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api resolve <pkg>` (blocked or gated: the `.api` catalogs + PyPI feed truth + ' +
            'Context7/exa/tavily own the fallback)',
        stackLaw:
            'read these `docs/stacks/python/` pages IN FULL, in this exact order: `README.md`, `language.md`, `shapes.md`, ' +
            '`surfaces-and-dispatch.md`, `iteration.md`, `rails-and-effects.md`, `concurrency.md`, `boundaries.md`, ' +
            '`algorithms.md`, `system-apis.md`, `runtime.md` — the complete root set, no discovery pass; sub-folders enter ' +
            'only where a page concern touches them',
    },
    ts: {
        name: 'TypeScript',
        root: 'libs/typescript',
        shared: 'libs/typescript/.api',
        manifest: 'the `pnpm-workspace.yaml` / package manifest rows this area consumes',
        verify:
            'the published types in node_modules (`UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api` over node_modules declarations where ' +
            'a member is novel)',
        stackLaw:
            'read these `docs/stacks/typescript/` pages IN FULL, in this exact order: `README.md`, `language.md`, ' +
            '`derivation.md`, `values.md`, `computation.md`, `shapes.md`, `surfaces-and-dispatch.md`, `rails-and-effects.md`, ' +
            '`services-and-layers.md`, `concurrency.md`, `streams.md`, `boundaries.md` — the complete root set, no discovery pass',
    },
};
const L = LANG[LANG_KEY] || LANG.cs; // inert fallback: composition no-ops before any agent call when LANG_KEY is null

// --- [SHARED_BLOCKS]

const ROOT_LAW =
    'WORKING ROOT: ' +
    ROOT_DIR +
    ' — every relative repo path in this brief resolves against this absolute root; read, write, and edit ONLY under it, never ' +
    'another checkout of the repository.';
const CONTEXT =
    ROOT_LAW +
    '\n\nRasm monorepo — ' +
    (LANG_KEY ? L.name : 'planning') +
    ' planning corpus (markdown design pages; code fences are the product). CLAUDE.md manifest law governs.';

const LAW =
    'FINALIZATION LAW — this pass corrects and CLOSES; the rebuild engine improves and extends. The targets: split-brain and ' +
    'dual paradigms unified onto ONE rail per the doctrine; unnecessary differentiation (parallel shapes, sibling name families, ' +
    'twin entries for one concept — within a page, across pages, or across folders) collapsed into the polymorphic owner IN ' +
    'PLACE, never a new file; duplication and indirection reduced; PHANTOM code adjudicated — a cited member/type/seam that does ' +
    'not exist is FORGOTTEN FUNCTIONALITY when intent evidence stands (seams, README rows, growth clauses, sibling contracts — ' +
    'realize it NOW at full depth, as if always there) or a LIE when none does (delete it); PARTIAL logic threads finished — a ' +
    'chain whose admission, owner, rail, projection, or egress end is thin, missing, or naive is extended to full capability at ' +
    'every end; entry points unified — one polymorphic entry per concern, sprawl collapsed; logic flow smoothed END-TO-END ' +
    '(admission once -> canonical owner -> unified rail -> projection -> egress; no dead ends, no rail breaches, no unreachable ' +
    'cases, no orphaned carriers); libs-wide seams LEVERAGED — an upstream capability the target hand-rolls or ignores is wired ' +
    'in, a stale seam counterpart is aligned both ends; density pushed and LOC reduced THROUGH density, never through capability ' +
    'loss. ALL capability is preserved — deletion exists only for proven lies and true duplicates, and underutilization is an ' +
    'integration defect this pass closes by wiring, never by removal.';

const INFO_LAW =
    'FINDING FORM — you deliver TRUTH, never an implementation: `claim` states the observed defect; `mechanism` states WHY it ' +
    'fails the doctrine or the domain as fact; `anchors` carry one coordinate per row (role names what it proves; `note` is the ' +
    'shortest literal witness under 20 words, or empty when path+line suffice; an `absence` anchor names where the expected ' +
    'thing was searched and not found); a `defect` anchor lands ON the line implementing the mechanism — a nearby declaration ' +
    'or a blank line taxes the consumer, whose re-open of every anchor is mandatory — and every anchor path resolves on current ' +
    'disk at emit: a phantom or doubled-segment path is a dead read the consumer inherits; `owner` names the canonical owner ' +
    'that must absorb the resolution (the owning axis, roster, registry, or seam vocabulary — never a new local shape); ' +
    '`reject` lists forms the repair must not take; `acceptance` the signals proving resolution. NEVER write ' +
    'add/replace/implement/promote/delete as instruction and never sketch a fence — the writer owns the design; you own the ' +
    'constraint boundary. `claimKey` follows one mechanical grammar — <package>.<page-stem>.<owner>.<defect-slug>, exactly four ' +
    'dot-separated lowercase segments (e.g. `appui.dashboards.lttb.unwired-decimator`) — so the same defect keys identically ' +
    'from any lane by construction. `severity` binds to consequence (blocker = closure-blocking, major = correctness, minor = ' +
    'local cleanup), never prose confidence — grade honestly across all three; a report whose every finding shares one grade ' +
    'has averaged, not graded. OUTPUT BOUNDS: retention scales with the scope — keep every finding that survives the second ' +
    'pass, lead with the strongest, and 0 is legal only when that pass returns empty, `summary` then naming the probes that ' +
    'produced nothing. COVERAGE is part of the product: `requested` = assigned scope, `read` = actually full-read, ' +
    '`skipped`/`unverified` = not reached or unconfirmed — an honest skip beats a silent one.';

const SELF_CHECK =
    'SELF-VERIFY (second pass, before returning): re-derive every entry from disk — re-open each cited anchor and confirm it ' +
    'states what the entry claims, re-verify each member spelling against its catalog, trace each seam to both endpoints. ' +
    'Correct or delete any entry that fails re-confirmation; never return a guess, an assumption, a skimmed summary, or a ' +
    'vague/hedged entry. Completeness is part of correctness: after the re-read, hunt once more for what the first pass missed ' +
    '— an omitted load-bearing fact is as wrong as a false one.';

// Register fork — substance identical (burden of proof on the work, both naivety axes, no-churn); the hostile register
// measurably makes a dispatched lane over-read and probe out of territory, so the `codex` rows stay de-conflicted.
const REG = {
    claude: {
        stance:
            'STANCE — the pass is hostile: the pages were authored by ANOTHER engineer and are under adversarial review; hold ' +
            'every fence naive, partial, or illusory until it survives a real attack — the burden of proof is on the code, never ' +
            'on you. Dense, confident, package-fluent code is the PRIME suspect for hollowness: a name promising capability the ' +
            'body omits, a logic thread finished at one end only, decorative density carrying nothing. NAIVETY is a defect on ' +
            'two orthogonal axes: COVERAGE — the owner models a thin slice of its concept; APPROACH — an enumerated roster where ' +
            'one parameterized generator should generate the space. NO CHURN: an edit requires a named violated law or invariant ' +
            'and the concrete case that breaks it; a clean verdict earned by an attack that finds nothing is a first-class ' +
            'result, proven by adding nothing.',
    },
    codex: {
        stance:
            'REVIEW POSTURE — the pages are unverified work by another engineer: verify every claim a fence makes against the ' +
            'real domain and the catalogued package surface before accepting it; a prior clean verdict or confident prose is not ' +
            'evidence. NAIVETY is a defect on two orthogonal axes: COVERAGE — the owner models a thin slice of its concept; ' +
            'APPROACH — an enumerated roster where one parameterized generator should generate the space. A name promising ' +
            'capability the body omits, a logic thread finished at one end only, and a hollow confident body are the primary ' +
            'targets. NO CHURN: a finding requires a named violated law or invariant and the concrete case that breaks it; a ' +
            'clean verdict from a check that finds nothing is a first-class result.',
    },
};

const LAWS_READ =
    'LAWS: read `docs/laws/` IN FULL (README + topology + patterns + scars; short registry pages) — a topology row whose ' +
    '[SURFACE] your corrections touch binds its obligated counterparts into the SAME pass, and every patterns row binds each ' +
    'branch it names.';

const BOUNDARY =
    'BOUNDARY LAW: cross-package and cross-language wire-canonical seam names are FROZEN — repair a seam recording, never ' +
    'rename the wire. Strata hold: no downward dependency, no host-type leak into a host-neutral owner. A foreign-language ' +
    "repair holds that branch's doctrine bar (read that branch stack README before a non-trivial foreign edit).";

const PROSE =
    'PROSE + COMMENTS — apply docs/standards/style-guide.md, information-structure.md, and formatting.md; these pages and ' +
    'this block are the COMPLETE prose law for this lane. Your project instructions (AGENTS.md/CLAUDE.md) route durable ' +
    'markdown to the `docgen` skill — that route serves interactive agents and does NOT apply here: never read, load, or open ' +
    'the docgen bundle from any root. Fences comment for the next agent only: keep the canonical section-divider headers; ' +
    'beyond them zero comments, 1-2 lines only for a truly subtle invariant or boundary; no restating the code, no doc bloat.';

const RIPPLE =
    'RIPPLE BOUNDS — sibling unit writers run concurrently. Your unit pages take full rebuild authority; a first-order ripple ' +
    'OUTSIDE your unit (a seam counterpart your edit breaks or opens directly) is repaired both ends when the edit is ' +
    'ADDITIVE (add the case, row, field, operation, or counterpart) and recorded in your seam ledger; renaming, removing, or ' +
    "collapsing a foreign surface — or any edit inside another live unit's pages — is recorded in `deferred` as {files, " +
    'claim} for the terminal sweeper, never raced. Decision-carrying shared surfaces are single-writer: the package index ' +
    'docs (README.md + ARCHITECTURE.md), IDEAS.md, and the central manifests take exact rows via `indexRows` for the sweeper ' +
    'to apply once.';

const LEDGER = (tag, scopes) =>
    'SEAM LEDGER — cross-unit coordination is typed fact rows on disk, never prose. Your ledger is `' +
    SCRATCH +
    '/' +
    tag +
    '-seams.md`: append one row per cross-file event as you work — `SEAM_CHANGED | <files> | <symbol/wire fact, old -> new>`, ' +
    '`RIPPLE_REPAIRED | <files> | <fact>` (so no sibling redoes it), `SEAM_CONFLICT | <files> | <both values>` on collision ' +
    'with a landed sibling row (resolve to the stronger form; a landed sibling counterpart is COMPOSED, never re-derived or ' +
    'reverted). Before ANY edit outside your unit pages, `ls` `' +
    SCRATCH +
    '/` and read every sibling `*-seams.md` row whose files intersect yours. CONCURRENT UNIT SCOPES: ' +
    scopes;

const HARVEST_LAW =
    'HARVEST (required key, usually empty): nominate ONLY findings that generalize beyond this run — a collapse pattern ' +
    'reusable across folders, a naivety class no doctrine clause names, a review rule that catches the defect BEFORE review, a ' +
    'hard-won cross-surface coupling. Each row: altitude (stacks|reviewer|constitution|planning|readme|laws), lang, claim (the ' +
    'generalized law, one sentence, SYMBOL-FREE — every concrete spelling lives in anchors, so the lander adjudicates the law ' +
    'without re-deriving its locality), anchors (file:line evidence), existingClause (the exact clause it hardens, quoted with ' +
    'its path — or "absent" with the surfaces searched). A run-local fix never nominates; an empty array is the normal verdict ' +
    '— the doctrine lander refutes weak rows, so nominate substance, never volume.';

const OWN_PASS = (artifact) =>
    'OWN PASS FIRST — the input ladder is binding, in order: (1) your own blind hostile pass, (2) the recon products. Rung (1) ' +
    'is the PRIMARY product and it is a DISK ARTIFACT, not a reading step: cold-read every target page from CURRENT disk and ' +
    'WRITE your own defect-and-work list to `' +
    artifact +
    '` — split-brain, differentiation, partial threads, naive owners, phantoms, flow breaks, entry-point sprawl, unleveraged ' +
    'seams — BEFORE opening any recon product. The recon may only ADD rows to that file, each tagged [recon]; reading the pages ' +
    'without writing the list is a failed rung, not a cold pass. TRIPWIRE: a diff dominated by [recon]-tagged rows has failed — ' +
    'the recon covers a MINORITY of what the work demands, and the majority of your edits must come from your own attack.';

const GIT_GROUND =
    'DELTA GROUNDING — run `git diff --stat` then `git diff -- <the pages and their seam files>` before judging; `git status` ' +
    'surfaces new files. The diff is orientation, CURRENT disk is truth — the repo can carry pre-run uncommitted work, so an ' +
    "unfamiliar hunk is verified against disk, never assumed to be this run's.";

// --- [OPERATIONS] ----------------------------------------------------------------------

// Agent-level slot scheduler: CAP agents in flight across the whole run, work-conserving backfill.
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
// Bounded re-dispatch for a dead CRITICAL lane (usage-limit or transport death): attempt-counted with a retry before each;
// the final death isolates the lane but NEVER the chain — every downstream stage still runs against current disk.
const retryLane = async (fn) => {
    for (let a = 0; a < RETRY_ATTEMPTS; a++) {
        const r = await fn();
        if (r) return r;
    }
    return null;
};
const fileTag = (label) => label.replace(/[^A-Za-z0-9_.-]+/g, '-');
const reportOf = (label) => SCRATCH + '/' + fileTag(label) + '-report.json'; // deterministic — consumers survive a dead receipt by checking the path

const laneLaw = (schema, o) =>
    (o.fix
        ? '<completion_bar>\nDone is every item in your named scope worked to its full depth with its product entry written — proof-complete, ' +
          'never effort-spent, never early. Complete every named move before yielding; do not stop at analysis or a partial edit. If the ' +
          'chosen approach resists, pick the next-best one and proceed. Re-verifying unchanged work or re-reading covered territory adds no ' +
          'evidence; move to the next deliverable instead.\n</completion_bar>\n\n<work_cadence>\nRead the stable law corpus once, first; ' +
          "then work ITEM BY ITEM — derive one item's resolution, land its edits, advance. Edits land as derived and never pool toward " +
          'the end: a scope fully materialized before its first edit forfeits its earliest findings to context compaction.\n' +
          '</work_cadence>\n\n<read_discipline>\nA stable input — a doctrine page, dossier, report, catalog — is read ONCE: extract what ' +
          'you need into your plan notes and re-open only the exact line span behind an edit, never the whole file again. Read in large ' +
          'windows (400+ lines per command), never 200-line paging. Skill bundles under any root (.claude/skills/, ~/.codex/skills/) are ' +
          'out of scope — the law in this brief is complete. Budget: at most ' +
          (o.calls || 300) +
          ' tool calls total; at the budget, land what is derived and record every remaining row in the product `deferred` field — an ' +
          'honest remainder beats a thrashing overrun.\n</read_discipline>\n\n<verification>\nAfter editing, re-read each changed file and ' +
          'confirm it is coherent and nothing it carried was lost. Fix what fails before yielding; a check you did not run is never claimed ' +
          'as run. Verification is READING: the corpus is markdown design pages — never compile, build, or run test gates against it; ' +
          'member truth rides the task-named catalog/assay rail only.\n</verification>'
        : '<context_gathering>\nTerritory: the exact files and directories the task names. Do not open files outside it; ' +
          'instruction files (.claude/, CLAUDE.md, AGENTS.md) and skill bundles under any root (.claude/skills/, ~/.codex/skills/) are ' +
          'always out of scope, and discovery commands stay scoped to the territory.\nBudget: at most ' +
          (o.calls || 60) +
          ' tool calls total. Read in small batches (a handful of files per command, line-capped); never concatenate the whole ' +
          'territory into one command - tool output truncates and the data is lost.\nStop as soon as the product is complete. ' +
          'If something is still uncertain at the budget, proceed and record the residue in coverage.unverified instead of ' +
          're-reading.\n</context_gathering>\n\n<verification>\nBefore the final message, confirm every cited spelling appears ' +
          'verbatim in the cited file; anything unconfirmed is recorded in coverage.unverified, never asserted.\n</verification>') +
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
    const report = ROOT_DIR + '/' + reportOf(label);
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
        reportOf(label) +
        ' (this repo-relative form, matching codex-lane receipts), entries = the length of the "' +
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

// QUOTA FALLBACK: a codex receipt whose failure matches usage/quota/limit re-dispatches the SAME task at the role's native
// twin; the caller owns the re-dispatch.
// The roster row carries `scope` from the ORCHESTRATOR so a lane that died before writing still names its territory exactly.
const twinOf = (m) => (/-luna/.test(m || '') ? 'sonnet' : 'opus');
const nativeLane = (task, o) =>
    agent(
        task +
            '\n\nPRODUCT TO DISK: write your COMPLETE product as one JSON file matching this schema at ' +
            (ROOT_DIR + '/' + reportOf(o.label)) +
            ' (Write tool, exactly this absolute path): ' +
            JSON.stringify(o.schema) +
            ' — then return ONLY the receipt: ok, report = ' +
            reportOf(o.label) +
            ' (this repo-relative form, matching codex-lane receipts), entries count, one-line mechanical headline, failure empty.',
        { label: o.label, phase: o.phase, model: o.nativeModel || twinOf(o.model), effort: 'high', schema: RECEIPT },
    );
const recon = (taskOf, o) => {
    const task = typeof taskOf === 'function' ? taskOf : () => taskOf;
    return agent(codexPrompt(o.label, task('codex'), o.schema, o), {
        label: 'sol:' + o.label,
        phase: o.phase,
        model: 'sonnet',
        effort: 'low',
        schema: RECEIPT,
    })
        .then((r) => (r && !r.ok && /usage|quota|limit/i.test(r.failure || '') ? nativeLane(task('claude'), o) : r))
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
// Dual-ceiling split over {page, lines} rows: segment count from BOTH ceilings (page count AND tonnage), near-even LOC
// fill in order — no runt tail, and no segment whose pages alone overflow a lane's context window.
const sizeChunk = (pages) => {
    const loc = (ps) => ps.reduce((a, s) => a + s.lines, 0);
    const k = Math.max(Math.ceil(pages.length / UNIT_MAX), Math.ceil(loc(pages) / UNIT_LOC), 1);
    if (k === 1) return [pages];
    const target = loc(pages) / k;
    const out = [];
    let cur = [];
    let acc = 0;
    for (let i = 0; i < pages.length; i++) {
        const p = pages[i];
        const splitBefore =
            cur.length > 0 &&
            out.length < k - 1 &&
            pages.length - i >= k - out.length - 1 &&
            (cur.length >= UNIT_MAX || Math.abs(acc - target) <= Math.abs(acc + p.lines - target));
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

// Prompt builders — each task states only its own action; shared laws are composed by name.
const planPrompt = () =>
    [
        CONTEXT,
        'TASK: thin enumerate (read-only, do NOT edit). TARGETS (repo-relative): ' +
            JSON.stringify(TARGETS) +
            '. Each target is a package root (e.g. ' +
            L.root +
            '/<Package>) or a planning sub-folder (<root>/.planning/<Folder>). Resolve the ONE owning package root. Return root ' +
            '(the package root) and folders — one entry per planning sub-folder in scope (a package-root target expands to EVERY ' +
            'sub-folder under its .planning tree, root-level pages pooling as one `_root` entry; explicit sub-folder targets ' +
            'restrict to exactly those): {folder, pages: [{page: repo-relative *.md path, lines: its real line count from one ' +
            '`wc -l` sweep}]}. EXCLUDE ' +
            'IDEAS.md/TASKLOG.md/README.md/ARCHITECTURE.md and any _*.md campaign document. EMIT `folders` IN DEPENDENCY ORDER — ' +
            'foundations before their consumers, judged from the package README.md/ARCHITECTURE.md composition order; the engine ' +
            'launches in your emitted order and never re-sorts, and the tonnage split rides your counts — a guessed count ' +
            'corrupts the packing. Use find/ls/wc; do NOT cd.',
    ].join('\n\n');

const flowLensPrompt = (u, reg) =>
    [
        CONTEXT,
        REG[reg].stance,
        LAW,
        INFO_LAW,
        SELF_CHECK,
        'TASK: read-only INTERIOR FLOW LENS over unit ' +
            u.tag +
            ' — the pages: ' +
            u.pages.join(', ') +
            ' (investigate, do NOT edit). Read EVERY page IN FULL, top to bottom, and every sibling page each composes or is ' +
            'composed by (seam partners both directions, entry owners, vocabulary sources — full reads, never skims), and the ' +
            'package README.md + ARCHITECTURE.md at ' +
            u.root +
            '. HUNT, per file and across the unit: LOGIC THREADS traced end to end — admission -> canonical owner -> rail -> ' +
            'projection -> egress; a thread whose any end is missing, thin, or naive is a `partial` finding naming BOTH the ' +
            'strong and the weak end; `flow` (rail breaches, dead ends, unreachable cases, admission done twice or never, ' +
            'orphaned carriers); `splitbrain` (one concern spelled two ways, dual paradigms on one rail); `differentiation` ' +
            '(parallel shapes, sibling name families, twin entries one polymorphic owner should carry — including a concept a ' +
            'sibling page or folder also models); ENTRY POINTS (every entry into the unit named; sprawl where one polymorphic ' +
            'entry should discriminate is `differentiation`); `naive` (mini fields, capability-thin owners, enumerated rosters ' +
            'where a generator belongs); `phantom_forgotten` vs `phantom_lie` (a cited member/type/seam that does not exist — ' +
            'classify by intent evidence, name it); `stale` (references to renamed/moved/dead owners). Judge CURRENT disk only. ' +
            'Return the findings product; an empty census is EARNED by the full read, never a first-pass concession.',
    ].join('\n\n');

const seamLensPrompt = (u, reg) =>
    [
        CONTEXT,
        REG[reg].stance,
        LAW,
        INFO_LAW,
        SELF_CHECK,
        'TASK: read-only EXTERIOR SEAM LENS over unit ' +
            u.tag +
            ' — the pages: ' +
            u.pages.join(', ') +
            ' (investigate, do NOT edit). Ground first: the branch architecture at ' +
            L.root +
            '/.planning/ (README + ARCHITECTURE — strata and dependency law), the package README.md + ARCHITECTURE.md at ' +
            u.root +
            ', ' +
            L.manifest +
            ', and a real `ls` of BOTH .api tiers (' +
            L.shared +
            '/ AND the package .api/). Then read every unit page IN FULL and HUNT the integration axis: `seam` (a cross-page or ' +
            'cross-package boundary/wire/contract the unit composes that is misaligned, recorded at one end only, or behind the ' +
            'counterpart as it NOW stands on disk — read the foreign end, name both endpoints); `underutilized` (a catalog ' +
            'capability either tier admits for these concepts that no fence exploits, or exploits shallowly — one call where the ' +
            'surface carries a family; name the concrete member in its exact catalog spelling); `handrolled` (page logic ' +
            're-deriving what an admitted package or an upstream libs/ owner already owns — duplication pressure, name the ' +
            'owning surface); `stale` (manifest, .api anchor, or index-doc rows contradicting the pages); cross-folder ' +
            '`differentiation` (a concept this unit models that another folder also models — route to the canonical owner as ' +
            'fact). Verify every cited member via ' +
            L.verify +
            ' — never memory; a member you cannot verify is recorded in coverage.unverified, never asserted. Judge CURRENT disk ' +
            'only. Return the findings product; an empty census is EARNED by the full read.',
    ].join('\n\n');

const mergePrompt = (rosterPaths, dossier) =>
    [
        CONTEXT,
        'TASK: WORK-DOSSIER MERGE — you consolidate the map fan for the implementor; you WRITE exactly one content file, the ' +
            'work dossier. Read EVERY map report listed here IN FULL from disk (a missing or invalid file is skipped and named ' +
            'in coverage.skipped): ' +
            JSON.stringify(rosterPaths) +
            '. CONSOLIDATE: (1) DEDUPE by `claimKey` — the same key across lanes is ONE defect; merge its evidence, keep the ' +
            'strongest anchors, never restate it twice. (2) JOIN cross-unit threads — findings that are legs of ONE logic chain, ' +
            'seam, or owner story become ONE work item naming every end and every file; a chain left as scattered per-unit rows ' +
            'is a failed merge. (3) ORDER by owner then severity then dependency — shared owners, registries, and vocabulary ' +
            'sources before their consumers; blockers first within an owner. (4) PRESERVE the constraint boundary of every ' +
            'surviving item verbatim — mechanism, owner, reject, acceptance, anchors; you never add prescriptions, designs, or ' +
            'fence sketches, and you never drop a finding except as an exact duplicate (dedupe is the only legal drop — name ' +
            'each drop and its surviving key in the dossier tail). AUTHOR `' +
            dossier +
            '` as markdown: a leading CROSS-UNIT THREADS section, one section per unit for the rest, each item ID-keyed with ' +
            "its claimKey. EVERY cross-unit thread names its LEAD unit — the unit holding the thread's primary owner; the " +
            "lead unit's writer implements the whole thread, so a thread without a lead is unowned work and a defect. A " +
            'section with nothing carries the checks that proved emptiness, never a bare NONE. THE DOSSIER IS ' +
            'YOUR SOLE CONTENT ARTIFACT — return ONLY `index` (each unit mapped to the dossier section headers carrying it), ' +
            'coverage, and summary; content lives in the dossier alone, never restated on the wire.',
    ].join('\n\n');

const implementPrompt = (u, dossier, mergeOk, unitReports, isUnmapped, reg) =>
    [
        CONTEXT,
        REG[reg].stance,
        LAW,
        BOUNDARY,
        PROSE,
        RIPPLE,
        LEDGER('impl-' + fileTag(u.tag), SCOPES),
        OWN_PASS(SCRATCH + '/impl-ownpass-' + fileTag(u.tag) + '.md'),
        'READ FIRST, IN ORDER — (1) ' +
            L.stackLaw +
            '; (2) `docs/laws/` per LAWS below; (3) the repo `.editorconfig` rules for your language — every error-severity ' +
            'rule is a compile gate, and a claim contradicting one is a fiction to correct; (4) the package README.md + ' +
            'ARCHITECTURE.md and ' +
            L.manifest +
            '.',
        LAWS_READ,
        'TASK: FINALIZE unit ' +
            u.tag +
            ' IN PLACE — the pages: ' +
            u.pages.join(', ') +
            '.\nCONSUMPTION, after your own pass per OWN PASS FIRST: ' +
            (mergeOk
                ? 'the WORK DOSSIER at `' +
                  dossier +
                  '` is the consolidated recon — read YOUR unit section IN FULL and every CROSS-UNIT THREAD whose LEAD is ' +
                  'your unit (you implement the whole thread, every end); a thread led elsewhere is not yours — compose its ' +
                  'landed ends per the ledger law, never re-derive it. Spot-verify every anchor an edit builds on ' +
                  '(re-open MANDATORY — a finding already corrected on disk or whose anchors do not re-confirm is dropped with ' +
                  'its reason in `summary`, never re-fixed).'
                : "the merge lane died — your unit's raw map reports are your recon; read each IN FULL from disk, dedupe by " +
                  '`claimKey` as you read, and order by owner then severity: ' +
                  JSON.stringify(unitReports) +
                  '.') +
            (isUnmapped
                ? ' This unit is UNMAPPED (no surviving map lane): your own cold hostile read is the recon — hunt the finding ' + 'kinds yourself.'
                : '') +
            '\nEach item is a SIGNAL, not law: `mechanism`/`owner`/`reject`/`acceptance` are its constraint boundary — honor ' +
            'the owner and rejected forms, but the DESIGN is yours: implement the densest root-level resolution the boundary ' +
            'admits, never a single-point patch. Apply the finalization law to EVERY page — unify split-brain, collapse ' +
            'differentiation in place, finish every partial thread at every end, realize every phantom_forgotten at full depth, ' +
            'delete every phantom_lie, grow naive owners to the real concept, smooth flow end-to-end, wire every underutilized ' +
            'capability into its owner, replace hand-rolled logic with the owning surface, align every stale seam both ends. ' +
            'CAPABILITY-COMPLETENESS is mandatory: verify every owner body implements what its names and prose promise — a ' +
            'named-but-omitted capability is a defect closed NOW at the same bar as any finding. Verify members via ' +
            L.verify +
            ' — never memory. Return the fix-log — `files` every file edited, `deltas` every moved symbol/wire as data, ' +
            '`indexRows` the exact index/manifest/IDEAS rows the sweeper applies, `deferred` the out-of-bound and ' +
            'named-blocker rows, all exact. ' +
            HARVEST_LAW,
    ].join('\n\n');

const critiquePrompt = (u, implReport, reg) =>
    [
        CONTEXT,
        REG[reg].stance,
        LAW,
        INFO_LAW,
        SELF_CHECK,
        GIT_GROUND,
        'TASK: read-only CRITIQUE of the FINALIZED corpus, unit ' +
            u.tag +
            ' — the pages: ' +
            u.pages.join(', ') +
            ' (investigate, do NOT edit; your findings feed the unit red-team WRITER, so every finding must be actionable ' +
            'at its anchor). OWN VERDICT FIRST: derive your own defect list from the pages on CURRENT disk before consulting ' +
            'the navigation below — it changes where you look first, never what you conclude. ' +
            (implReport
                ? 'NAVIGATION: the unit implement fixlog is ON DISK at `' +
                  implReport +
                  '` — read its `files` and `deltas` rows only (locations, where you look first); its verdicts and summaries ' +
                  "are the author's self-report, not evidence."
                : 'NAVIGATION: the unit implement fixlog is absent — derive your reading order from the pages alone.') +
            ' AUDIT: every finalization-law target on every page (split-brain, differentiation, partial threads, phantoms, ' +
            'naive owners, flow, entry sprawl, unleveraged seams, hand-rolled logic, stale references) — the implementor is ' +
            'presumed to have missed things; verify what its deltas claim against disk, check every seam it touched at BOTH ' +
            'ends, and hunt what it never touched. A defect already resolved on CURRENT disk is DROPPED, never reported. ' +
            'Verify cited members via ' +
            L.verify +
            '. Return the findings product in the FINDING FORM, findings emitted in page order.',
    ].join('\n\n');

const rtUnitPrompt = (u, implReport, crit) =>
    [
        CONTEXT,
        REG.claude.stance,
        LAW,
        BOUNDARY,
        PROSE,
        RIPPLE,
        LEDGER('rt-' + fileTag(u.tag), SCOPES),
        LAWS_READ,
        GIT_GROUND,
        OWN_PASS(SCRATCH + '/rt-ownpass-' + fileTag(u.tag) + '.md'),
        'TASK: UNIT RED-TEAM (WRITER — the last corrector of unit ' +
            u.tag +
            '; only the terminal sweeper follows): full rebuild authority over the unit pages under the ripple bounds. The ' +
            'pages: ' +
            u.pages.join(', ') +
            '. Assume the implementor and the critique missed things and their claims are wrong until disk proves them; your ' +
            'own-pass attack artifact precedes every input. PRODUCT ORDER IS EXECUTION ORDER:\n' +
            (crit && crit.ok
                ? '(1) CRITIQUE REPORT — ON DISK at `' +
                  crit.report +
                  '`: read it IN FULL; group findings by `claimKey` then `owner`, blockers first. Each finding is a SIGNAL: ' +
                  're-open its anchors before editing (MANDATORY); honor `mechanism`/`owner`/`reject`/`acceptance` as the ' +
                  'constraint boundary and implement the STRONGEST resolution it admits, never a single-point patch; a finding ' +
                  'with a dead anchor, already resolved on disk, or graded `hypothetical` with no substantive re-derivation is ' +
                  'rejected with its reason.\n'
                : '(1) CRITIQUE REPORT: absent — your cold attack is the only review this unit gets.\n') +
            (implReport
                ? '(2) IMPLEMENT FIXLOG — ON DISK at `' +
                  implReport +
                  '`: read it IN FULL; its verdicts are refutation targets judged against CURRENT disk. Its surviving ' +
                  '`deferred`, `indexRows`, and `harvest` rows fold into YOUR return, re-verified and deduped — a dropped row ' +
                  'is a silent loss; an in-unit deferred row whose blocker has cleared is yours to land NOW.\n'
                : '(2) IMPLEMENT FIXLOG: absent — judge from CURRENT disk alone.\n') +
            '(3) PRE-MORTEM — beyond the reports, on your own authority: COUNTERFACTUAL on the core owners (a counterfactual ' +
            'REBUILDS with the central assumption removed — the chosen owner kind, the hand-enumerated space, the call-site ' +
            'dispatch — and where the rebuilt form is stronger, BUILD IT IN PLACE; "the current shape also works" is never a ' +
            'refutation); LONG-TAIL (empty/singular/plural/stream/malformed/concurrent/cancelled/partial-failure); the diff of ' +
            'the next feature (one row lands with every consumer untouched or loudly broken); then a FULL COLD RE-REVIEW of ' +
            'every finalization-law dimension against CURRENT disk.\n' +
            '(4) OWN HUNT: hunt PAST every signal list and fix what the fan missed inside the unit; `beyond` enumerates those ' +
            'fixes, and an empty `beyond` attests the hunt found nothing, never that it did not run.\n' +
            'Return the fix-log — `tranches` receipts each product fed; `remaining` carries out-of-bound rows and rows a named ' +
            'blocker genuinely forbids, each naming its blocker and owner; a rejected finding rides `rejected` with its disk ' +
            'fact. ' +
            HARVEST_LAW,
    ].join('\n\n');

const sweeperPrompt = (backlog, indexRows, unmapped, pages) =>
    [
        CONTEXT,
        REG.codex.stance,
        LAW,
        BOUNDARY,
        PROSE,
        LAWS_READ,
        GIT_GROUND,
        'CHECKPOINT LEDGER: `' +
            SCRATCH +
            '/sweep-checkpoint.md` — read it FIRST and skip every tranche it already receipts (an interrupted drain re-enters, ' +
            'never restarts); append one line per tranche AS EACH COMPLETES. HARVEST FILE: append each `harvest` nomination to `' +
            SCRATCH +
            '/rt-harvest.jsonl` (one JSON row per line) the moment it is minted — the doctrine lander sweeps the file, so a ' +
            'killed pass loses no nomination; your returned `harvest` carries the same rows.',
        "TASK: TERMINAL SWEEPER (WRITER — the run's LAST corrector, nothing follows you but the doctrine lander): full write " +
            'authority over the entire project — no sibling writer runs, so the expand-form bound is LIFTED: collapse, rename, ' +
            'and contract are yours, and every ripple an edit exposes is yours in the same pass. The finalized pages: ' +
            JSON.stringify(pages) +
            '. ONE scoped pass, tranche order is execution order:\n' +
            '(1) DEFERRED ROWS from every unit chain (re-verify each {files, claim} on CURRENT disk — a row disk already ' +
            'resolves is rejected with its evidence; a cleared blocker is yours to land at the root): ' +
            JSON.stringify(backlog) +
            '.\n' +
            "(2) INDEX ROWS — apply each to its owning doc exactly once, deduped semantically, keeping each doc's section " +
            'grammar; a central-manifest row hand-edits the grouped manifest at the SYMBOL anchor (never a line number): ' +
            JSON.stringify(indexRows) +
            '.\n' +
            (unmapped.length
                ? '(2b) UNMAPPED units (no surviving map lane — your own cold read over their pages, hunting the finalization-law targets): ' +
                  JSON.stringify(unmapped) +
                  '.\n'
                : '') +
            '(3) CROSS-UNIT SEAM AUDIT: read every `*-seams.md` ledger under `' +
            SCRATCH +
            '/` and verify each SEAM_CHANGED row landed BOTH ends on current disk, each SEAM_CONFLICT resolved to the stronger ' +
            'form; repair every miss.\n' +
            '(4) GOVERNANCE: verify the package README.md + ARCHITECTURE.md, IDEAS.md, ' +
            L.manifest +
            ', and the `.api` anchors truthfully reflect the finalized corpus; repair drift.\n' +
            '(5) OWN HUNT over the governance surface and any page the tranches never touched; `beyond` enumerates those ' +
            'fixes, an empty `beyond` attesting the hunt ran clean.\n' +
            'Verify members via ' +
            L.verify +
            '. Return the fix-log — `tranches` receipts each tranche; `remaining` carries ONLY rows verified still-open and ' +
            'genuinely blocked, each naming its blocker and owner; `indexRows` returns EMPTY (you applied them). ' +
            HARVEST_LAW,
    ].join('\n\n');

const doctrinePrompt = (rows, critPaths) =>
    [
        ROOT_LAW,
        'TASK: DOCTRINE LANDER — the durable-learning terminal of a finalization run. Read `docs/laws/README.md` FIRST — it ' +
            'owns the corpus admission and page-shape law; obey it over any restatement. ROUTING EMPHASIS (orders where you look ' +
            'first, never overrides the admission bar): a finalization run corrects and closes a landed corpus, so its lessons ' +
            'weigh toward planning-corpus law and reviewer rules first. Load the `docgen` skill via ' +
            'the Skill tool BEFORE any durable edit; load `mermaid-diagramming` before touching any diagram.\n' +
            "NOMINATIONS (unverified, biased toward their authors' own work — refute by default): " +
            JSON.stringify(rows) +
            '\nAlso sweep `' +
            SCRATCH +
            '/rt-harvest.jsonl` (absent = none) AND the `harvest` array of every critique and implement report at these ' +
            'deterministic paths (an absent or invalid file skips; no other agent transports these rows): ' +
            JSON.stringify(critPaths) +
            ' — dedupe them against NOMINATIONS and adjudicate them identically.\n' +
            'ADJUDICATE each row per the admission bar: cold-read its target surface IN FULL, verify its anchors on CURRENT ' +
            'disk; LAND NOTHING is a first-class verdict.\n' +
            'TOPOLOGY RE-PROOF: re-verify every `docs/laws/topology.md` row whose [SURFACE] this run touched — cull a row whose ' +
            'coupling no longer holds, land a coupling this run proved.\n' +
            'GATE: run `uv run .claude/skills/docgen/scripts/prose_gate.py <every touched .md>` and repair to zero FAILs before ' +
            'returning. Return landed/refined/rejected (each rejection with its reason)/files/summary.',
    ].join('\n\n');

// --- [COMPOSITION] ---------------------------------------------------------------------

if (REJECTED.length) log('Rejected targets outside libs/{csharp,python,typescript}: ' + REJECTED.join(', '));
if (!TARGETS.length) {
    log('No targets — pass a package root, an array of planning sub-folders, or {targets}. Empty args is a no-op.');
    return { targets: [], units: 0 };
}
if (!LANG_KEY) {
    log('Targets must live under ONE language root (libs/csharp | libs/python | libs/typescript). Got: ' + JSON.stringify(TARGETS));
    return { targets: TARGETS, units: 0 };
}

phase('Scope');
// One bounded re-attempt: a silently dead scope agent would no-op the whole run.
const planOpts = { label: 'scope', phase: 'Scope', model: 'sonnet', effort: 'low', schema: PLAN_SCHEMA };
const plan = (await slot(() => agent(planPrompt(), planOpts))) || (await slot(() => agent(planPrompt(), { ...planOpts, label: 'scope:r1' })));
const ROOT = (plan && plan.root) || TARGETS[0];
// R6 guard: model-emitted page paths are validated against the resolved root before any lane dispatches on them.
const FOLDERS = ((plan && plan.folders) || [])
    .map((f) => ({
        folder: f.folder,
        pages: (f.pages || [])
            .filter((p) => p && typeof p.page === 'string' && p.page.indexOf(ROOT + '/') === 0)
            .map((p) => ({ page: p.page, lines: Math.max(p.lines | 0, 300) })),
    }))
    .filter((f) => f.folder && f.pages.length);
const PAGES = FOLDERS.flatMap((f) => f.pages.map((p) => p.page));
// Unit = the map/implement/review granularity: one `.planning/<sub>` folder, oversize folders split under the dual
// (page-count AND tonnage) ceiling so no unit alone overflows a writer or reviewer lane.
const UNITS = FOLDERS.flatMap((f) => {
    const segs = sizeChunk(f.pages);
    return segs.map((rows, i) => {
        const name = f.folder + (segs.length > 1 ? '.' + (i + 1) : '');
        return { folder: f.folder, name, tag: ROOT.split('/').pop() + '.' + name, pages: rows.map((r) => r.page), rows, root: ROOT };
    });
});
const SCOPES = JSON.stringify(UNITS.map((u) => ({ unit: u.tag, pages: u.pages })));
log('Scope[' + LANG_KEY + ']: ' + UNITS.length + ' unit segment(s), ' + PAGES.length + ' page(s) at ' + ROOT + '; CAP=' + CAP);
if (!UNITS.length) {
    log('No pages resolved under the targets');
    return { targets: TARGETS, language: LANG_KEY, units: 0 };
}

phase('Map');
// Two codex medium-effort lenses per unit — interior flow, exterior seam — findings reports on disk, thin receipts on the wire.
const mapRoster = (
    await Promise.all(
        UNITS.flatMap((u) => [
            slot(() =>
                recon((reg) => flowLensPrompt(u, reg), {
                    label: 'map:flow:' + u.tag,
                    phase: 'Map',
                    schema: FINDINGS_SCHEMA,
                    scope: u.pages,
                    hl: { arr: 'findings', group: 'kind' },
                    codexEffort: 'medium',
                }),
            ),
            slot(() =>
                recon((reg) => seamLensPrompt(u, reg), {
                    label: 'map:seam:' + u.tag,
                    phase: 'Map',
                    schema: FINDINGS_SCHEMA,
                    scope: u.pages,
                    hl: { arr: 'findings', group: 'kind' },
                    codexEffort: 'medium',
                }),
            ),
        ]),
    )
).filter(Boolean);
const MAP_REPORTS = mapRoster.filter((r) => r.ok).map((r) => r.report);
// A unit is UNMAPPED only when BOTH its lenses died — one surviving lens still grounds it.
const mappedPages = new Set(mapRoster.filter((r) => r.ok).flatMap((r) => r.scope));
const UNMAPPED = UNITS.filter((u) => !u.pages.some((p) => mappedPages.has(p))).map((u) => ({ unit: u.tag, pages: u.pages }));
log(
    'Map: ' +
        mapRoster.filter((r) => r.ok).length +
        '/' +
        mapRoster.length +
        ' lens(es) ok, ' +
        mapRoster.filter((r) => r.ok).reduce((a, r) => a + r.entries, 0) +
        ' finding(s)' +
        (UNMAPPED.length ? ' — UNMAPPED unit(s): ' + UNMAPPED.map((x) => x.unit).join(', ') : ''),
);

// One merge lane consolidates the fan into the single work dossier; its death degrades to raw-report consumption, never blocks.
const WORK_DOSSIER = SCRATCH + '/work-dossier.md';
const merge = MAP_REPORTS.length
    ? await slot(() =>
          recon(mergePrompt(MAP_REPORTS, WORK_DOSSIER), {
              label: 'map:merge',
              phase: 'Map',
              schema: MERGE_SCHEMA,
              scope: PAGES,
              hl: { arr: 'index' },
              writes: true,
              codexEffort: 'high',
              calls: 200,
          }),
      )
    : null;
const MERGE_OK = !!(merge && merge.ok);
log(
    'Map: merge ' +
        (MERGE_OK ? 'consolidated -> ' + WORK_DOSSIER : MAP_REPORTS.length ? 'DIED — implementor consumes raw reports' : 'skipped (no ok reports)'),
);

phase('Implement');
phase('Review');
// PER-UNIT PIPELINED CHAINS — implement (write lane) -> critique (read lane) -> red-team (writer), each unit
// advancing the moment its own prior stage lands; the slot scheduler is the only cross-unit governor, the seam ledgers own
// coordination, and failure isolates per unit (a dead implement still gets its critique and red-team against current disk).
const unitReportsOf = (u) => [reportOf('map:flow:' + u.tag), reportOf('map:seam:' + u.tag)];
const chains = await Promise.all(
    UNITS.map(async (u) => {
        const isUnmapped = UNMAPPED.some((x) => x.unit === u.tag);
        const fix = await slot(() =>
            recon((reg) => implementPrompt(u, WORK_DOSSIER, MERGE_OK, unitReportsOf(u), isUnmapped, reg), {
                label: 'impl:' + u.tag,
                phase: 'Implement',
                schema: IMPL_SCHEMA,
                scope: u.pages,
                hl: { arr: 'files' },
                writes: true,
                fix: true,
            }),
        ).catch(() => null);
        const implReport = (fix && fix.ok && fix.report) || '';
        const crit = await slot(() =>
            recon((reg) => critiquePrompt(u, implReport, reg), {
                label: 'crit:' + u.tag,
                phase: 'Review',
                schema: FINDINGS_SCHEMA,
                scope: u.pages,
                hl: { arr: 'findings', group: 'kind' },
                codexEffort: 'high',
            }),
        ).catch(() => null);
        const rt = await slot(() =>
            agent(rtUnitPrompt(u, implReport, crit), {
                label: 'rt:' + u.tag,
                phase: 'Review',
                model: 'opus',
                schema: RT_SCHEMA,
            }),
        ).catch(() => null);
        return { unit: u.tag, fix, crit, rt };
    }),
);
const CRIT_PATHS = UNITS.map((u) => reportOf('crit:' + u.tag)); // deterministic — every path checked on disk regardless of receipt
const IMPL_PATHS = chains.filter((c) => c.fix && c.fix.ok).map((c) => c.fix.report);
// Red-teams fold their unit's impl deferred/indexRows forward, so aggregation reads rt first and falls back to the impl
// receipt only for a unit whose rt died (its fixlog rows would otherwise vanish — the sweeper re-reads that fixlog from disk).
const ORPHAN_IMPL = chains.filter((c) => c.fix && c.fix.ok && !c.rt).map((c) => c.fix.report);
const BACKLOG = chains.flatMap((c) => (c.rt && c.rt.remaining) || []);
const INDEX_ROWS = chains.flatMap((c) => (c.rt && c.rt.indexRows) || []);
log(
    'Chains: ' +
        chains.filter((c) => c.fix && c.fix.ok).length +
        '/' +
        UNITS.length +
        ' implement(s), ' +
        chains.filter((c) => c.crit && c.crit.ok).length +
        ' critique(s), ' +
        chains.filter((c) => c.rt).length +
        ' red-team(s) landed; ' +
        BACKLOG.length +
        ' deferred row(s), ' +
        INDEX_ROWS.length +
        ' index row(s)' +
        (ORPHAN_IMPL.length ? ' — orphaned impl fixlog(s): ' + ORPHAN_IMPL.join(', ') : ''),
);

// ONE terminal sweeper drains the cross-unit remainder in one scoped pass — deferred rows, index/manifest rows, seam-ledger
// audit, governance drift, orphaned fixlogs (fed as extra tranche rows via the backlog), and its own hunt.
const orphanRows = ORPHAN_IMPL.map((p) => ({
    files: [p],
    claim: 'orphaned implement fixlog — read IN FULL from disk; its deferred/indexRows/harvest rows are unconsumed and yours to drain',
}));
const sweepFire = (suffix) =>
    slot(() =>
        recon(() => sweeperPrompt(BACKLOG.concat(orphanRows), INDEX_ROWS, UNMAPPED, PAGES), {
            label: 'sweeper' + suffix,
            phase: 'Review',
            schema: RT_SCHEMA,
            scope: PAGES,
            hl: { arr: 'remaining' },
            writes: true,
            fix: true,
            calls: 400,
        }),
    ).catch(() => null);
const sweepOnce = await sweepFire('');
const sweep =
    sweepOnce && sweepOnce.ok
        ? sweepOnce
        : await retryLane(async () => {
              const r = await sweepFire(':r1');
              return r && r.ok ? r : null;
          });
log(
    'Sweeper: ' +
        (sweep && sweep.ok ? sweep.entries + ' row(s) remaining — ' + sweep.headline : 'DIED — checkpoint and harvest file survive on disk'),
);

phase('Close');
// The lander transports every harvest channel: inline rt rows, the sweeper/rt harvest file, and the report harvest arrays on disk.
const HARVEST_ROWS = chains.flatMap((c) => (c.rt && c.rt.harvest) || []);
const doctrine =
    HARVEST_ROWS.length || CRIT_PATHS.length || IMPL_PATHS.length
        ? await slot(() =>
              agent(doctrinePrompt(HARVEST_ROWS, CRIT_PATHS.concat(IMPL_PATHS)), {
                  label: 'doctrine',
                  phase: 'Close',
                  model: 'opus',
                  effort: 'high',
                  schema: DOCTRINE_SCHEMA,
              }),
          )
        : null;
return {
    targets: TARGETS,
    language: LANG_KEY,
    root: ROOT,
    units: UNITS.length,
    pages: PAGES.length,
    mapped: mapRoster.filter((r) => r.ok).length,
    unmapped: UNMAPPED,
    merged: MERGE_OK,
    implements: chains.filter((c) => c.fix && c.fix.ok).length,
    critiques: chains.filter((c) => c.crit && c.crit.ok).length,
    redteams: chains.filter((c) => c.rt).length,
    orphanedFixlogs: ORPHAN_IMPL,
    sweeper: sweep && {
        ok: !!sweep.ok,
        report: sweep.report || '',
        remaining: sweep.entries || 0,
        headline: sweep.headline || '',
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
