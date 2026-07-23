export const meta = {
    name: 'implement-py',
    whenToUse: 'Realize open IDEAS and TASKLOG cards into design-page code fences across the Python target folders.',
    description:
        "Realize every open IDEAS/TASKLOG card across the Python target set (libs/python/artifacts, compute, data, geometry, runtime) into deep design-page code FENCES at the docs/stacks/python bar (with docs/stacks/csharp as the ambition floor), repair every ripple in-pass, and truthfully close the cards. Each target folder runs its OWN discover -> implement -> critique -> redteam chain, ALL chains concurrent under one pooled cap: a folder starts the moment its own discovery lands, a folder with no open cards no-ops after its own discovery, and a failed chain isolates without rejecting the pool. Discovery hands downstream stages navigation FACTS (paths, verified members, seam targets) and never verdicts; it runs as a recon lane, lands its full navigation-facts product as one JSON report on disk under the workflow scratch dir, and returns only a thin receipt with the jq-cut structural skeleton (order, pages, ripples, gates) inline; downstream stages read the report IN FULL from disk, and when the skeleton proves page-disjoint card groups, the implement stage fans over them. Every stage WRITES and repairs the page-level ripples its own work exposes in the same pass — in-scope seams aligned against current disk, 1-hop out-of-scope same-language counterpart fences realized directly — with BLOCKED probes and folder-local package admission inline. The redteam is each folder chain's terminal stage and sole card-status owner: it final-remediates weak realizations in place and closes only cards whose realization it verified strong on disk. Two handoffs route to the run's terminal single-writer, the central pyproject.toml pin row + band marker and the target ARCHITECTURE.md [02]-[SEAMS] row: folder agents report exact rows, one terminal writer applies them serially. Every writing stage also nominates generalizable lessons into a required-usually-empty harvest — each stage's rows ride its own return, the critique lane's swept from its fixlog on disk by the doctrine lander (nomination transport never rides a living fold); the terminal stage is a DRAIN LOOP over the pooled deferred backlog and every critique fixlog (the redteam fold-forward is lossy even when it lands) that also applies the central pins and ARCHITECTURE seam rows and re-feeds the still-open remainder under a round cap + no-shrinkage progress gate, then one doctrine lander adjudicates the pooled harvest and every critique fixlog harvest array from disk against the docs/laws admission bar (land-nothing legal) before the run closes. Card-driven (it implements ideas/tasks), NOT the in-isolation api-stacking of the rebuild engine. Python-only. args = a target path string, an array of paths, or empty for the defaults. The language-wide libs/python/.planning is out of scope.",
    phases: [
        {
            title: 'Realize',
            detail: 'all folder chains concurrent under one pooled cap: discover(recon; product to disk, thin receipt + structural skeleton inline) -> implement(reads the discovery report from disk, fans over skeleton-proven page-disjoint card groups) -> critique(ONE codex lane, write; fixlog to disk, receipt on the wire) -> redteam(terminal close; reads the critique fixlog from disk as refutation targets and folds its surviving ripples/pins/seams/deferred rows into its own return); a folder with no open cards no-ops after its own discovery; every writing stage re-reads current disk, repairs page-level ripples in-pass, and reports central pin rows + ARCHITECTURE.md [02]-[SEAMS] rows for the terminal single-writer instead of editing those surfaces',
        },
        {
            title: 'Pins',
            detail: 'a terminal DRAIN LOOP: one serial single-writer per round applies every reported central pyproject.toml pin row + band marker and every reported ARCHITECTURE.md [02]-[SEAMS] row, drains every critique fixlog (the redteam fold-forward is lossy even when it lands) and the pooled deferred backlog against live disk, and re-feeds the still-open remainder under a round cap + no-shrinkage progress gate; then one doctrine lander adjudicates the pooled harvest nominations against the docs/laws admission bar (land-nothing legal). Runs only when pins, seams, orphans, backlog, or harvest exist',
            model: 'opus',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const CAP = 14;
const IMPL_FAN = 3; // max implement agents fanned per folder, and only over discovery-proven page-disjoint card groups
const DRAIN_ROUNDS = 4; // terminal drain fixpoint cap; the no-shrinkage progress gate (no remaining shrinkage -> stop) is the real bound
const RETRY_ATTEMPTS = 2;
const ROOT = 'libs/python';
const SHARED_API = 'libs/python/.api';
const CENTRAL = 'pyproject.toml';
const DEFAULT_TARGETS = ['libs/python/artifacts', 'libs/python/compute', 'libs/python/data', 'libs/python/geometry', 'libs/python/runtime'];

// --- [INPUTS] --------------------------------------------------------------------------

const norm = (t) => {
    const s = String(t).trim();
    return s.indexOf('libs/') === 0 ? s : ROOT + '/' + s;
};
const TARGETS = Array.isArray(args)
    ? args.filter(Boolean).map(norm)
    : args && typeof args === 'object' && Array.isArray(args.targets)
      ? args.targets.filter(Boolean).map(norm)
      : typeof args === 'string' && args.trim() && args.trim().toUpperCase() !== 'ALL'
        ? [norm(args)]
        : DEFAULT_TARGETS;
const TARGET_NAMES = TARGETS.map((t) => '`' + (t.split('/').filter(Boolean).pop() || t) + '`').join(', ');
// Per-instance scratch dir (the per-lane report files) — minted deterministically from the normalized target set so a resume rehydrates the same
// FLAT .claude/scratch/ dir; a human-readable basename slug with an FNV-1a tail keeps distinct target sets from ever sharing a directory.
const fnv1a = (s) => {
    let h = 0x811c9dc5;
    for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193);
    return (h >>> 0).toString(16).padStart(8, '0').slice(0, 6);
};
const SCRATCH =
    '.claude/scratch/' +
    ('implement-py-' + TARGETS.map((t) => t.split('/').pop().toLowerCase()).join('-')).replace(/[^a-z0-9.-]+/g, '-').slice(0, 60) +
    '-' +
    fnv1a(JSON.stringify(TARGETS));

// --- [MODELS] --------------------------------------------------------------------------

// Per-folder discovery PRODUCT (the on-disk report): `pages` per card are disk-verified Anchors targets proving page-disjoint implement groups;
// `malformed_ripples` is a required attestation (empty = none found); `coverage` is part of the product — requested vs actually-read scope. One
// anchor = one fact at one coordinate; interpretation never lives in an anchor row.
const ANCHOR = {
    type: 'object',
    additionalProperties: false,
    required: ['path', 'line', 'role', 'note'],
    properties: {
        path: { type: 'string' },
        line: { type: 'integer' },
        role: { type: 'string', enum: ['state', 'ruling', 'catalog', 'counterpart', 'absence'] },
        note: { type: 'string' },
    },
};
const RIPPLE_ROW = {
    type: 'object',
    additionalProperties: false,
    required: ['from_slug', 'klass', 'to_pkg', 'to_slug'],
    properties: {
        from_slug: { type: 'string' },
        klass: { type: 'string', enum: ['in_scope', 'oos_samelang', 'cross_lang'] },
        to_pkg: { type: 'string' },
        to_slug: { type: 'string' },
    },
};
const GATE_ROW = {
    type: 'object',
    additionalProperties: false,
    required: ['blocked_slug', 'gated_by_slug', 'in_scope'],
    properties: { blocked_slug: { type: 'string' }, gated_by_slug: { type: 'string' }, in_scope: { type: 'boolean' } },
};
const MALFORMED_ROW = {
    type: 'object',
    additionalProperties: false,
    required: ['from_slug', 'raw'],
    properties: { from_slug: { type: 'string' }, raw: { type: 'string' } },
};
const CARD_REF = {
    type: 'object',
    additionalProperties: false,
    required: ['slug', 'pages'],
    properties: { slug: { type: 'string' }, pages: { type: 'array', items: { type: 'string' } } },
};

const DISCOVERY_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['folder', 'order', 'tasks', 'ideas', 'ripples', 'malformed_ripples', 'gates', 'map', 'coverage'],
    properties: {
        folder: { type: 'string' },
        order: { type: 'array', items: { type: 'string' } },
        tasks: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['slug', 'status', 'pages', 'atomic', 'thesis'],
                properties: {
                    slug: { type: 'string' },
                    status: { type: 'string' },
                    atomic: { type: 'boolean' },
                    thesis: { type: 'string' },
                    pages: { type: 'array', items: { type: 'string' } },
                },
            },
        },
        ideas: {
            type: 'array',
            maxItems: 3,
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['slug', 'status', 'pages', 'thesis'],
                properties: {
                    slug: { type: 'string' },
                    status: { type: 'string' },
                    thesis: { type: 'string' },
                    pages: { type: 'array', items: { type: 'string' } },
                },
            },
        },
        ripples: { type: 'array', items: RIPPLE_ROW },
        gates: { type: 'array', items: GATE_ROW },
        map: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['page', 'files', 'anchors', 'members', 'composed', 'underutilized', 'seams', 'stacking'],
                properties: {
                    page: { type: 'string' },
                    files: { type: 'array', items: { type: 'string' } }, // files the downstream writers must open for this row
                    anchors: { type: 'array', items: ANCHOR }, // exact coordinates backing the row's facts
                    members: { type: 'array', items: { type: 'string' } }, // verified member spellings backing `underutilized`
                    composed: { type: 'string' },
                    underutilized: { type: 'string' },
                    seams: { type: 'string' },
                    stacking: { type: 'string' },
                },
            },
        },
        malformed_ripples: { type: 'array', items: MALFORMED_ROW },
        coverage: {
            type: 'object',
            additionalProperties: false,
            required: ['requested', 'read', 'skipped', 'unverified'],
            properties: {
                requested: { type: 'array', items: { type: 'string' } },
                read: { type: 'array', items: { type: 'string' } },
                skipped: { type: 'array', items: { type: 'string' } },
                unverified: { type: 'array', items: { type: 'string' } },
            },
        },
    },
};

// Thin wire receipt + mechanically-extracted skeleton: the discovery PRODUCT (statuses, theses,
// the per-page navigation map, anchors, coverage) stays on disk at `report`; only status + count + headline
// and the structural rows the orchestrator fans and seams over (order/cards/gates/ripples/malformed)
// travel inline. `cards` = {slug, pages} per open card — the page-disjointness proof, nothing more.
const RECEIPT = {
    type: 'object',
    additionalProperties: false,
    required: ['ok', 'report', 'entries', 'headline', 'failure', 'order', 'cards', 'gates', 'ripples', 'malformed'],
    properties: {
        ok: { type: 'boolean' },
        report: { type: 'string' },
        entries: { type: 'integer' },
        headline: { type: 'string' },
        failure: { type: 'string' },
        order: { type: 'array', items: { type: 'string' } },
        cards: { type: 'array', items: CARD_REF },
        gates: { type: 'array', items: GATE_ROW },
        ripples: { type: 'array', items: RIPPLE_ROW },
        malformed: { type: 'array', items: MALFORMED_ROW },
    },
};

// Thin wire receipt for the critique codex lane: its FIXLOG product stays on disk at `report`.
const LANE_RECEIPT = {
    type: 'object',
    additionalProperties: false,
    required: ['ok', 'report', 'entries', 'headline', 'failure'],
    properties: {
        ok: { type: 'boolean' },
        report: { type: 'string' },
        entries: { type: 'integer' },
        headline: { type: 'string' },
        failure: { type: 'string' },
    },
};

// Required-but-possibly-empty `ripples`/`pins`/`seams` are attestations: ripple repair ran in-pass,
// and pin + seam rows are the run's only single-writer handoffs — empty attests none arose, never a skip.
const RIPPLES = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['counterpart', 'action'],
        properties: { counterpart: { type: 'string' }, action: { type: 'string' } },
    },
};
const PINS = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['package', 'row'],
        properties: { package: { type: 'string' }, row: { type: 'string' } },
    },
};
const SEAMS = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['file', 'row'],
        properties: { file: { type: 'string' }, row: { type: 'string' } },
    },
};

// The counted backlog: cards a folder chain could not realize, drained by the terminal loop and re-fed as `remaining`.
const DEFERRED = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['files', 'claim'],
        properties: { files: { type: 'array', items: { type: 'string' } }, claim: { type: 'string' } },
    },
};

// Doctrine nominations — generalizable lessons only; the terminal doctrine lander adjudicates every row.
const HARVEST = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['altitude', 'lang', 'claim', 'anchors', 'existingClause'],
        properties: {
            altitude: { type: 'string', enum: ['stacks', 'reviewer', 'constitution', 'planning', 'readme', 'laws'] },
            lang: { type: 'string' },
            claim: { type: 'string' },
            anchors: { type: 'array', items: { type: 'string' } },
            existingClause: { type: 'string' },
        },
    },
};

// ONE fix-log core serves every writing stage (implement, critique, redteam); a stage adds only the keys its charter earns —
// twin literals drift, one composer never does. `reopened` and `deferred` share the {slug, reason} row.
const SLUG_REASON = {
    type: 'object',
    additionalProperties: false,
    required: ['slug', 'reason'],
    properties: { slug: { type: 'string' }, reason: { type: 'string' } },
};
const LOG_CORE = {
    folder: { type: 'string' },
    verdict: { type: 'string', enum: ['realized', 'refined', 'clean'] },
    realized: { type: 'array', items: { type: 'string' } },
    deferred: { type: 'array', items: SLUG_REASON },
    collapsed: { type: 'string' },
    ripples: RIPPLES,
    pins: PINS,
    seams: SEAMS,
    harvest: HARVEST,
    summary: { type: 'string' },
};
const logSchema = (extra) => ({
    type: 'object',
    additionalProperties: false,
    required: Object.keys(LOG_CORE).concat(Object.keys(extra)),
    properties: Object.assign({}, LOG_CORE, extra),
});
const FIXLOG_SCHEMA = logSchema({});
const REDTEAM_SCHEMA = logSchema({
    closed: {
        type: 'array',
        items: {
            type: 'object',
            additionalProperties: false,
            required: ['slug', 'disposition', 'strength'],
            properties: {
                slug: { type: 'string' },
                disposition: { type: 'string', enum: ['complete', 'dropped'] },
                strength: { type: 'string', enum: ['strong', 'partial', 'weak'] },
            },
        },
    },
    reopened: { type: 'array', items: SLUG_REASON },
});

const PIN_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['applied', 'seam_rows_applied', 'rejected', 'remaining', 'harvest', 'summary'],
    properties: {
        applied: { type: 'array', items: { type: 'string' } },
        harvest: HARVEST,
        seam_rows_applied: { type: 'array', items: { type: 'string' } },
        rejected: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['target', 'reason'],
                properties: { target: { type: 'string' }, reason: { type: 'string' } },
            },
        },
        remaining: DEFERRED, // rows verified still-open and genuinely blocked; the drain loop re-feeds them until empty or no progress
        summary: { type: 'string' },
    },
};

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

// --- [DOCTRINE] ------------------------------------------------------------------------

const FB =
    ' (the `.api` catalogs, Context7/exa/tavily for the official surface, and the `nuget` MCP for NuGet-side members own the fallback when assay is unavailable)';

const LAW = [
    'Rasm monorepo, libs/python planning corpus (markdown specs of intended Python module designs). CLAUDE.md manifest + WORKSPACE_LAW strata ' +
        'govern. The session targets are the libs/python package folders ' +
        TARGET_NAMES +
        '. Each holds `IDEAS.md` ' +
        '+ `TASKLOG.md` + `ARCHITECTURE.md` + `README.md` at its package ROOT, design pages at `<folder>/.planning/<subdomain>/*.md`, and a ' +
        'folder-specific `.api/*.md` catalog. The language-wide `libs/python/.planning` is OUT of scope this run. Read the package-root ' +
        '`ARCHITECTURE.md` (sub-domain map + `[02]-[SEAMS]`) and `README.md` (admitted-package roster) as governing context. Cross-folder repair ' +
        'lands at seams, counterpart cards, and consumer sites — never by rebuilding a sibling owner interior.',
    'STANDARD: docs/stacks/python/ is the route-owned law ' +
        '(README/language/shapes/surfaces-and-dispatch/rails-and-effects/algorithms/iteration/concurrency/boundaries/runtime/system-apis) — author ' +
        'Python as dense, polymorphic, and rich as that bar admits; docs/stacks/csharp/ is the density/ambition FLOOR (match its richness, never ' +
        'import C#-shaped idioms). READ the operative docs/stacks/python pages and conform exactly. Cite ONLY members confirmed in the .api catalogs; ' +
        'verify any novel member via `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api`' +
        FB +
        '.',
    'This is IMPLEMENT, not the in-isolation api-stacking rebuild: realize the folder SPECIFIC open IDEAS/TASKLOG cards into deep design-page ' +
        'FENCES. A FENCE is a markdown fenced code block inside a `.planning` design page — the work product itself, NEVER a `.py` source file. SCOPE ' +
        'per target: realize ALL open tasks (including `Atomic`-flagged minor tasks), then the 1-3 chosen open ideas, tasks first. Realize tied to the ' +
        'card charter (Capability/Shape/Unlocks/Anchors), composing the right admitted capability and crushing surface sprawl into fewer richer owners ' +
        'with zero functionality loss.',
    'TWO-TIER .api: every fence draws on BOTH the shared/universal catalogs at `' +
        SHARED_API +
        '/*.md` (anyio, expression, msgspec, pydantic, ' +
        'pydantic-settings, beartype, structlog, stamina, numpy, psutil, opentelemetry-*, protobuf, grpcio, and siblings — the disk listing owns the ' +
        'roster) AND the folder-specific catalogs at ' +
        '`<folder>/.api/*.md`. The shared tier is SHARED capability you MUST consider and compose to realize the card properly — never re-derive by ' +
        'hand or settle for a thin folder-only subset; layer the shared rails (expression `Result`/`Option`, msgspec/pydantic discriminated models, ' +
        'beartype validation, stamina retry, structlog + opentelemetry spans, anyio structured concurrency) ON TOP OF the folder-specific domain ' +
        'packages. This is implement (use the capability the card needs), not rebuild (max-stack every catalog for its own sake).',
    'WRITE-FULLY + FIX-IT-NOW: every fix you identify you MUST make NOW via Edit/Write directly in the file — the structured fix-log you return is a ' +
        'REPORT of edits ALREADY MADE, never a to-do list, a ledger, or a would/should-fix hedge. The writing is YOURS: never delegate authoring to ' +
        'another agent — a delegate may only fetch information. A cross-file ripple your edit exposes is YOURS in the ' +
        'same pass, wherever it lives: the seam counterpart on both ends, the consumer site, the stale sibling page, the 1-hop counterpart card fence ' +
        'in another libs/python folder — repaired now and recorded in `ripples` (an empty `ripples` attests your pass exposed none, never that repair ' +
        "was skipped). TWO handoffs route to the run's terminal single-writer and are NEVER edited by a folder agent: the central `" +
        CENTRAL +
        '` ' +
        'pin (report the exact row + band marker in `pins`) and any target `ARCHITECTURE.md` `[02]-[SEAMS]` row (report {file, row} in `seams` — the ' +
        'highest-collision shared surface); every other page-level ripple stays yours, repaired distributed under the anchored-Edit discipline. If ' +
        'after real investigation a fence is already correct, say so — never invent edits to look busy.',
].join('\n');

const CARD = [
    'CARD SCHEMA: open cards live in the target `IDEAS.md` (ideas — larger conceptual capability) and `TASKLOG.md` (tasks — concrete targeted work), ' +
        'under section `[01]-[OPEN]`; closed cards collapse under `[02]-[CLOSED]`. A card is `[ID]-[STATUS]: <thesis>` then the bullets `Capability:` ' +
        '/ `Shape:` / `Unlocks:` / `Anchors:` / `Tension:` (only when a constraint shapes it) / `Ripple:` (only on a cross-folder counterpart) / ' +
        '`Atomic:` (only on a minor task). Open statuses: `ACTIVE` / `QUEUED` / `BLOCKED`. Closed: `COMPLETE` / `DROPPED`. ALWAYS read the FULL card ' +
        'body (every bullet) from disk — the thesis alone is never enough to realize the charter.',
    'RIPPLE: `Ripple: <lang>:<pkg> [SLUG]` (or `<pkg> [SLUG]`) is a BIDIRECTIONAL cross-folder link — the counterpart card in the named pkg carries ' +
        'the mirror slug, and ripples are PART of scope, repaired in the pass that exposes them, never handed to a later stage. Three classes: ' +
        'IN-SCOPE (counterpart is another Python session target — its own pipeline realizes its card; you align your half of the seam to the ' +
        'counterpart page as it NOW stands on disk, and the later-landing side owns the final alignment), OUT-OF-SCOPE SAME-LANGUAGE (counterpart in ' +
        'a non-target libs/python folder — YOU realize the 1-hop counterpart card fence and align the seam on both ends in the same pass; the ' +
        "ripple's scope is that counterpart card and its seam, not the foreign folder's other cards), CROSS-LANGUAGE / LIB-WIDE (`libs/csharp`, " +
        "`libs/typescript`, `libs/python/.planning`, `libs/.planning` — outside this Python-only run's language rail; land your half stating the " +
        'wire contract, and the card stays open unless it is complete on your half alone).',
    'PROBE FREELY (nothing gates probing): EVERY agent in EVERY phase may — and should — probe to verify reality at any time, for ANY card or design ' +
        'decision, not only `[BLOCKED]` ones — `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api resolve|query` over Python distributions / ' +
        'host DLLs / NuGet / node_modules to confirm any member; `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay provision check` ' +
        '(+ `pyproject.toml` + tools/assay/README.md) for a ' +
        'native/scientific/database/provisioning band (sanitized Rasm evidence — direct `forge-provision` is Forge-level debugging, not the normal ' +
        'entry); Rhino WIP (never Rhino 8) via the rhino-mcp skill or tools/rhino-bridge for live host behavior. tools/assay is under concurrent ' +
        'construction: when an assay invocation fails, the probe obligation stands and reroutes — the `.api` catalogs, Context7/exa/tavily for the ' +
        'official surface, the `nuget` MCP for NuGet-side members — and a blocker provable ONLY through downed assay is a legitimate out-of-run ' +
        'blocker, never a faked resolution. A `[BLOCKED]` card is REALIZED this turn whenever a probe resolves its blocker OR its gating work is in ' +
        'scope; a blocker is genuinely legitimate ONLY when it depends on work outside this run.',
    'PACKAGE ADMISSION (only when a card genuinely needs a not-yet-admitted package): the new dependency is exactly ONE of three bands, which ' +
        'decides the central `' +
        CENTRAL +
        '` marker AND the install/reflect path — (a) pure-Python wheel -> installs to `.venv`; (b) ' +
        'scientific/native (numpy/scipy-class, C/C++/Fortran build) -> NOT in `.venv`, the `forge-scientific-*` env, decided via `UV_CACHE_DIR=' +
        '.cache/uv uv run python -m tools.assay provision check` (the package own wheel/build metadata via Context7/PyPI evidence decides the band ' +
        "when assay is unavailable); (c) companion-band -> pinned with a `; python_version<'3.15'` marker. Do the folder-local parts NOW — add the " +
        'package to the correct group in the target `README.md` and author the target `.api/<package>.md` from `UV_CACHE_DIR=.cache/uv uv run ' +
        'python -m tools.assay api`' +
        FB +
        '. The central repo-root ' +
        '`' +
        CENTRAL +
        '` has exactly ONE in-run writer: report the exact dependency row + band marker in `pins` and never edit that file yourself. ' +
        'Never a per-folder `' +
        CENTRAL +
        '`.',
    'CARD CLOSURE (the folder red-team ONLY — implement and critique NEVER change card status): a genuinely-complete card moves to its file ' +
        '`[02]-[CLOSED]` section as a collapsed one-liner `[ID]-[COMPLETE]: <one-line disposition>; Ripple: <pkg> [SLUG]` (or `[DROPPED]: <reason>`); ' +
        "report the target `ARCHITECTURE.md` `[02]-[SEAMS]` row as {file, row} in `seams` ONLY when a real cross-folder seam landed; the run's " +
        'terminal single-writer applies it, never you. A ripple-carrying card closes COMPLETE only when its seam is verified landed on BOTH ends on ' +
        'current disk; close only `strong` cards and honestly re-open the rest.',
].join('\n');

const BARHUNT = [
    'BAR — a high-value IMPLEMENT leaves every owner capturing the capability the card needs from the packages it admits, every sprawl collapsed ' +
        'into one denser owner with NO capability lost, and every fence transcription-complete against the verified `.api`. The critique guards ' +
        'capability conservation, charter completeness, and density; the red-team attacks every fence for a surface that could still collapse, a thin ' +
        'wrapper, a silent functionality drop during a refactor, a missed package capability the card needs, or a framework violation, and fixes each ' +
        'in place.',
    'HUNT (at implement, critique, and red-team alike): UNDER-CAPTURED CAPABILITY — an admitted package whose `.api` and code expose capability the ' +
        'CARD needs but no owner exploits is a gap, closed by deepening a fence. SURFACE SPRAWL — parallel types/functions/near-duplicate shapes ' +
        'collapse into one parameterized owner (closed family / `@tagged_union` / derived `frozendict` table / fold / stacked aspect) with no ' +
        'functionality removed. RAIL UNIFICATION — one entrypoint family per rail, one closed fault vocabulary per domain, total `match` + ' +
        '`assert_never`. OPTIMIZATION — correctness first, then allocation/vectorization (numpy)/dispatch shape/algorithmic complexity, not only ' +
        'line-count. NEW WORK SURFACED — api gaps and tasks the implementation exposes are realized the same turn.',
    'NAIVETY — a defect on two orthogonal axes, both intolerable at every stage: COVERAGE — the owner models a thin slice of its concept (the ' +
        'obvious three fields where the domain carries fifteen; a two-case family for a twenty-case domain); APPROACH — enumerated hardcoded ' +
        'instances where a parameterized algorithmic owner should generate the space (a fixed roster of styles/patterns/variants is seed DATA ' +
        'feeding ONE generator over named parameters, never the mechanism itself). Rebuild the owner to the generative form on either hit. COLLAPSE ' +
        'FREEDOM: every enumerated collapse-signal list in this prompt is a FLOOR, never the complete set — any repeated structure, parallel ' +
        'spelling, or enumerable family an algebra, table, fold, or generator can own is a collapse target you find yourself.',
].join('\n');

// Native-only hostile stance — composed by the implement + red-team prompts, NEVER by the critique lane (the estate
// hostile register makes that lane over-probe out of territory; the critique carries its de-conflicted register in developer-instructions).
const STANCE =
    'STANCE — hold every fence naive, shallow, or illusory until it survives a real attack; the burden of proof is on the code, never on ' +
    'you. Dense, confident, package-fluent work is the PRIME suspect for hollowness — a name promising capability the body omits, ' +
    'decorative density carrying nothing, a stub dressed as a finished design. "Mature", "already strong", and a prior clean verdict are ' +
    'rejected self-assessments; verify every claim a fence makes about itself against the real domain and the catalogued package surface.';

const ULTRA = [
    'OPERATIVE DOCTRINE: docs/stacks/python/ is the route-owned law — READ `README.md` (the 16 laws + the COLLAPSE_SCAN), `shapes.md` ' +
        '(OWNER_CHOOSER + the lifecycle), `surfaces-and-dispatch.md` (dispatch forms + ASPECTS), and `rails-and-effects.md` (rail/effect law) before ' +
        'realizing, and hold every fence to them as fact. docs/stacks/csharp/ is the density/ambition FLOOR — match its richness, never import ' +
        'C#-shaped idioms.',
    'LIFECYCLE SPINE (BOUNDARY_ADMISSION): every fence flows `Raw -> Payload -> Canonical owner -> Rail -> Projection -> Egress`. Raw material is ' +
        'admitted EXACTLY ONCE into an evidence-carrying owner (Pydantic/`TypedDict` payload at ingress); interior code never re-validates, never sees ' +
        '`None`-as-failure, sentinels, or provider shapes; egress projects outward (`msgspec.Struct` wire) from the canonical owner. Parameterize BOTH ' +
        'ingress AND egress so the same owner sources and sinks across many providers/apps without touching its interior.',
    'SHAPE LAW: one concept owns exactly ONE type (SHAPE_BUDGET) — variants are cases in one closed family, never sibling types; one rich ' +
        'polymorphic surface over many shallow (DEEP_SURFACES); the owner is shaped for the family it will ABSORB (ANTICIPATORY_COLLAPSE) so the next ' +
        'case/dimension/modality lands as ONE declaration with every consumer untouched or broken loudly at type-check. Choose each owner by the ' +
        'OWNER_CHOOSER discriminants — admission (trusted/untrusted), identity regime (value/tag/key/reference), variant arity ' +
        '(one/closed-family/open), payload timing (def-time/runtime), openness (closed/semi/open) -> the right owner among `TypedDict`, Pydantic, ' +
        '`msgspec.Struct`, frozen dataclass, rich class, `StrEnum`/`Literal`, `sentinel`, `Option`/`Result`, `frozendict`/`Map`/`tuple`, `Protocol`. A ' +
        'misplaced shape traces to one mis-answered discriminant.',
    'ASPECT-FIRST (DEFINITION_TIME_ASPECTS): every CROSS-CUTTING capability — retry, telemetry/spans, validation, contracts, memoization, ' +
        'registration, receipts, fault rails — is a SIGNATURE- and RAIL-PRESERVING decorator (inline `**P` + `functools.wraps`) that materializes ' +
        'policy, STACKS in deterministic order (bottom-up at definition, top-down at call), and NEVER raises into domain flow (a failing aspect ' +
        'returns the rail `Error`). Co-occurring wrappers sharing an admission path collapse into ONE parameterized aspect factory. Code reads as STACKED ' +
        'DECORATORS over a thin pure core, never inline-repeated concerns or sibling helper functions; the domain transform itself stays a pure ' +
        'function/fold.',
    'DERIVATION + ARITY: cases sharing generative structure are DERIVED — one primary `frozendict` correspondence declared, every secondary map ' +
        'derived from it (DERIVED_LOGIC), or a fold/comprehension — never enumerated arms. Configuration enters as ONE behavior-carrying value ' +
        '(vocabulary member, tagged variant, frozen policy table), never flag sets the body re-derives (POLICY_VALUES). ONE entrypoint owns every ' +
        'modality (singular/plural/batch/stream), discriminating on the INPUT SHAPE (`T | Iterable[T]` normalized once at the head), never a name ' +
        'suffix or a `mode`/`batch` knob (MODAL_ARITY); a `timeout`/`retry`/`deadline` is an aspect or an `anyio` scope, never a signature param ' +
        '(KNOB_TEST). Capability exits through FEW dense unified entry points — one polymorphic entry per rail discriminating on input shape ' +
        '(single|batch|stream absorbed by input detection, forward and inverse directions on one surface), variation living in input shape, policy ' +
        'values, and table rows, never parallel exports or modality-named siblings; the surface narrows by absorption, never by omission.',
    'RAILS (rails-and-effects): the narrowest carrier that states the outcome, chosen ONCE at admission — `Option[T]` non-failing absence, ' +
        '`Result[T, E]` typed fallibility, `effect.result` do-notation for sequential `bind`, `Block`/`Map` immutable traversal, an `anyio` task group ' +
        'as the failure boundary (NEVER `asyncio.gather`), `stamina.retry` as the decorator (never a sleep-loop). The fault type `E` is a CLOSED ' +
        'vocabulary — `Literal` set, `StrEnum`, or `@tagged_union` family — NEVER a bare `str` for a multi-cause domain. Accumulate-vs-abort is a ' +
        'correctness decision fixed at the boundary: `map2`/accumulating-fold for independent operands (a `bind` chain over independents reports only ' +
        'the first failure), `bind` short-circuit for dependent steps. Cancellation is not failure; resource cleanup is `AsyncExitStack` + a shielded ' +
        'scope.',
    'STACK .api CAPABILITY: ENUMERATE BOTH catalog tiers IN FULL with a real listing (`ls`/`fd` of the shared `' +
        SHARED_API +
        '/*.md` AND the ' +
        'folder-specific `<folder>/.api/*.md`, from disk, never memory), then mine every catalog the card touches to OPERATOR DEPTH and compose the ' +
        'capability into single dense operations woven as ONE rail, layering the shared rails (expression `Result`/`Option`, msgspec/pydantic ' +
        'discriminated models, beartype validation, stamina retry, structlog + opentelemetry spans, anyio structured concurrency) ON TOP OF the ' +
        'folder-specific domain packages — e.g. `msgspec dec_hook` -> pydantic discriminated union -> stamina `retry_context` -> opentelemetry span ' +
        'around the domain op — NOT flat one-shot per-library uses. Use the DEEPEST primitive each package itself reaches (LIBRARY_DEPTH). An ' +
        'admitted capability the card charter needs that no owner exploits is a DEFECT the pass closes by deepening a fence; a cited member that ' +
        'cannot be verified in the catalogs or via `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api`' +
        FB +
        ' is a PHANTOM the pass deletes or corrects on sight. (Implement ' +
        'composes the capability the card needs; it does not max-stack every catalog for its own sake — that is rebuild.)',
    'PRESERVE all capability (densify, never delete functionality): capability is improved or extended, NEVER dropped for lack of a current ' +
        'consumer — zero consumers never lowers the bar; planned consumers are real design pressure. Where a fence is already dense, deepen; where ' +
        'it is flat/naive, rebuild ground-up. Never regress correctness or boundary law.',
].join('\n');

const PATLAW = [
    'PY-VERSION LAW: target Python 3.15 on the full modern band (3.11/3.12/3.13/3.14/3.15) — advanced patterns ONLY, zero legacy idioms, IDENTICAL ' +
        'conventions across every folder and package.',
    'NEVER write `from __future__ import annotations`. NEVER use legacy typing: use PEP 585 builtin generics (`list[T]`, `dict[K, V]`, `tuple[...]`, ' +
        '`set[T]`) NOT `typing.List/Dict/Tuple/Set`; PEP 604 unions (`X | None`, `A | B`) NOT `Optional`/`Union`; PEP 695 type parameters (`class ' +
        'C[T]:`, `def f[T](...)`, `type Alias[T] = ...`) NOT `TypeVar` + `Generic`. Use `Self`, `override`, `TypeIs`/`TypeGuard`, `assert_never`, ' +
        '`ReadOnly`, `TypedDict` + `NotRequired`/`Required`, `LiteralString`, `enum.StrEnum`/`IntEnum`, and `@dataclass(slots=True, frozen=True)` or ' +
        '`msgspec.Struct`/pydantic models where each best fits.',
    'PAYLOADS — NEWEST FORM: ingress payloads are static `TypedDict` contracts with `closed=True` or `extra_items=T` and per-key ' +
        '`Required[]`/`NotRequired[]`/`ReadOnly[T]`, admitted through a module-level `TypeAdapter`, with `Unpack[TypedDict]` at root keyword ' +
        'entrypoints (never forwarded through interiors); extension bands fold into `frozendict`/tuple evidence at materialization, and ' +
        '`msgspec.Struct(frozen=True)` owns wire/egress. NO `dict[str, Any]` bags, homogeneous `**kwargs`, or `Mapping[str, object]` payloads.',
    'FROZENDICT (py3.15 builtin): `from builtins import frozendict` is the owner for immutable map rows, dispatch/policy TABLES (one primary ' +
        '`frozendict[K, tuple[...]]`, secondary maps derived from it), payload `extra_items` extension bands, and immutable evidence — REJECT ' +
        '`MappingProxyType`, a module-level mutable `dict` used as a table, tuple-pair pseudo-maps, and mutate-then-freeze. Prefer total ' +
        '`match`/structural pattern matching over if-chains, walrus where it tightens, `assert_never` on closed unions, and PEP 750 t-strings / PEP ' +
        '749 deferred annotations where relevant. Keep every choice CONSISTENT across folders so the corpus reads as one ultra-advanced codebase.',
].join('\n');

const BOUNDARIES =
    'BOUNDARY LAW: keep every folder owner strictly in its lane; internal code uses canonical names and shapes with mapping only at ' +
    'the edge; respect the dependency direction of the workspace strata. Cross-folder repair is seam-shaped: align counterparts, consumer sites, ' +
    'and counterpart cards — a concern owned twice across a runtime, a folder mixing unrelated concerns, or coupling to a sibling owner INTERIOR ' +
    '(vs its wire/seam) is a defect.';

const CURRENT =
    'CURRENT STATE — sibling folder pipelines land work concurrently with yours. Before ANY edit, re-read the CURRENT on-disk state ' +
    'of your pages AND every sibling page your pages compose or ripple into; landed sibling work is composed as found, never assumed from the ' +
    'discovery map. A seam counterpart a sibling pipeline landed is COMPOSED, not re-derived; a conflict between your design and a landed sibling ' +
    'resolves to the STRONGER form, never a revert. Edit any potentially shared page with surgical anchored Edits only — re-read and re-apply on an ' +
    'edit conflict, never a whole-file rewrite.';

const PROSE = [
    'PROSE QUALITY — apply docs/standards/style-guide.md. The page is a design SPEC: high-signal prose ONLY. Lead each section with the controlling ' +
        'rule/contract; one idea per paragraph; close on the consequence or boundary. Cut noise: no provenance, process narration, freshness ' +
        'disclaimers, report framing, or empty hedges (may/might/probably/generally/where possible). Trim walls of explanation to the load-bearing ' +
        'contract, and prefer a table, a typed signature block, or a tight bullet wherever it carries the design better than a paragraph.',
    'BACKTICK ALL CODE: wrap every symbol, type, field, function, operator, package ID, path, command, flag, and literal value in backticks. Name ' +
        'the exact member/type/rail in backticks instead of paraphrasing behavior. Trimming prose MUST NOT reduce technical density or remove design ' +
        'content.',
].join('\n');

const COMMENTS =
    'COMMENT HYGIENE: code fences are agent-facing — comment for the next agent, never as a tutorial. KEEP the canonical ' +
    'section-divider headers (language-comment marker + space + `---` + bracketed `[UPPERCASE_LABEL]` + dash-fill). Beyond dividers, comment ONLY ' +
    'where intent is not already obvious from names, types, and signatures: default to ZERO comments on self-evident code; at most 1 line where a ' +
    'comment genuinely earns its place; 1-2 lines only for a truly subtle invariant, contract, or boundary. NO restating the code, no narration, no ' +
    'task/process/session/history/proof/review comments, no docstring bloat. Densify names and types so comments are rarely needed; cut every ' +
    'low-value comment.';

const LAWS =
    'LAWS — read `docs/laws/` IN FULL (README + topology + patterns + scars; short registry pages) before any edit: a topology row whose ' +
    '[SURFACE] your edits touch binds its obligated counterparts into the SAME pass, and every patterns row binds each branch it names.';

const HARVEST_LAW =
    'HARVEST (required key, usually empty): nominate ONLY findings that generalize beyond this folder — a collapse pattern reusable across ' +
    'folders, a naivety class no doctrine clause names, a review rule that would have caught a defect BEFORE review, a cross-surface coupling ' +
    'discovered the hard way. Each row: altitude (stacks|reviewer|constitution|planning|readme|laws), lang, claim (the generalized law, one ' +
    'sentence), anchors (file:line evidence), existingClause (the exact doctrine or reviewer clause it would harden, quoted with its path — or ' +
    '"absent" with the surfaces searched). A card-local fix never nominates; an empty array is the normal verdict — the terminal doctrine ' +
    'lander refutes weak rows, so nominate substance, never volume.';

const DOCTRINE = [LAW, '', LAWS, '', CARD, '', BARHUNT, '', ULTRA, '', PATLAW, '', BOUNDARIES, '', CURRENT, '', PROSE, '', COMMENTS].join('\n');

const GROUPNOTE =
    "CONCURRENT CARD GROUP: sibling implement agents realize this folder's OTHER page-disjoint card groups concurrently. Realize " +
    "ONLY the cards in your worklist (the report's `map` rows for pages outside your `pages` list are context, never your work); touch any shared " +
    "folder surface (README.md, a page outside your group's anchored pages, a sibling folder page) with surgical anchored Edits only, re-read and " +
    're-applied on conflict.';

const INFO_LAW =
    'You provide INFORMATION, never prescriptions: exact disk locations and anchors, the current shape at each page, verified member ' +
    'spellings, seam endpoints, gaps. Downstream stages decide how to build; a map row that tells them what to write instead of what is true is a ' +
    'defect. ROW FORM: `composed`/`underutilized`/`seams`/`stacking` are prose facts; `members` carries exact verified spellings; `anchors` carry ' +
    'one coordinate per row (role names what it proves; `note` is the shortest literal witness under 20 words, or empty when path+line suffice; an ' +
    '`absence` anchor names where the expected thing was searched and not found); `files` lists what the downstream writers must open for the row. ' +
    'COVERAGE is part of the product: `requested` = your assigned scope, `read` = what you actually full-read, `skipped`/`unverified` = what you ' +
    'did not reach — an honest skip beats a silent one.';

// OWN-PASS-FIRST ladder (rung 1 is a disk artifact): each writing/review stage cold-derives its own defect list to a
// stage-distinct scratch file before the discovery report opens, so the report grounds and widens the pass, never anchors it.
const OWN_PASS = (artifact) =>
    'OWN PASS FIRST — the input ladder is binding, in order: (1) your own blind independent pass, (2) the discovery report. Rung ' +
    '(1) is the PRIMARY product and a DISK ARTIFACT, never a reading step: cold-read every open card body and the design pages it ' +
    'names from CURRENT disk and WRITE your own defect-and-ambition list to `' +
    artifact +
    '` — collapse targets, naivety kills, under-captured capability, and every charter clause the fences must deliver — BEFORE ' +
    'opening the discovery report. The report may only ADD rows to that file, each tagged [recon]; reading the pages without ' +
    'writing the list is a failed rung, not a cold pass. TRIPWIRE: a diff dominated by [recon]-tagged rows has failed — the ' +
    'report is navigation facts covering a MINORITY of what the work demands, and the majority of edits come from your own attack.';

// --- [OPERATIONS] ----------------------------------------------------------------------
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
// Bounded re-dispatch for a dead CRITICAL writer (usage-limit or transport death): attempt-counted, retry;
// the final death isolates the lane but NEVER the chain — every downstream stage still runs against current disk.
const retryLane = async (fn) => {
    for (let a = 0; a < RETRY_ATTEMPTS; a++) {
        const r = await fn();
        if (r) return r;
    }
    return null;
};

// Codex dispatch: the wrapper runs one blocking supervised CLI process and writes its content
// to the lane report, and returns mechanical orchestration data. Lane law rides developer-instructions
// (role split, battery-validated); the prompt carries only the task; the output contract sits LAST.
const fileTag = (label) => label.replace(/[^A-Za-z0-9_.-]+/g, '-');
const laneLaw = (schema, o) =>
    (o.fix
        ? '<completion_bar>\nDone is every card and page in your named scope worked to full depth with its fixlog row written — ' +
          'proof-complete, never effort-spent, never early. Complete every named move before yielding; do not stop at analysis or a ' +
          'partial edit. If the chosen approach resists, pick the next-best one and proceed; a move the territory genuinely admits ' +
          'no edit for returns as a deferred row naming its blocker. Your layer is review-and-repair of the named scope: a finding ' +
          'outside it lands as a typed deferred row, never an edit — and re-verifying unchanged work or re-reading covered ' +
          'territory adds no evidence; move to the next deliverable instead.\n</completion_bar>\n\n<verification>\nAfter editing, ' +
          're-read each changed file and confirm it is coherent and nothing it carried was lost. Fix what fails before yielding; a ' +
          'check you did not run is never claimed as run.\n</verification>'
        : '<context_gathering>\nTerritory: the exact files and directories the task names. Do not open files outside it, ' +
          'including skill or instruction files (.claude/, CLAUDE.md, AGENTS.md).\nBudget: at most ' +
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
const LANE_SCRIPT = '/Users/bardiasamiee/Documents/99.Github/Rasm/.claude/skills/codex/scripts/codex-lane.sh';
const flagsOf = (o) =>
    [o.model && '--model ' + o.model, o.codexEffort && '--effort ' + o.codexEffort, o.web && '--web']
        .filter(Boolean)
        .map((f) => ' ' + f)
        .join('');
const codexPrompt = (label, task, schema, o) => {
    const base = SCRATCH + '/' + fileTag(label);
    const root = '/Users/bardiasamiee/Documents/99.Github/Rasm';
    const report = root + '/' + base + '-report.json';
    const lane = report + '.lane';
    const authored = !!o.writes;
    const sandbox = authored ? 'workspace-write' : 'read-only';
    return [
        'DISPATCH ROLE: a delegate performs the complete TASK below through one supervised lane run; never perform, edit, judge, ' +
            'soften, summarize, or relay the work yourself.',
        '(1) Write the LANE LAW block below VERBATIM to ' +
            lane +
            '/law.md and the TASK block below VERBATIM to ' +
            lane +
            '/task.md, composing neither.' +
            (authored
                ? ' Delete any leftover file at ' +
                  report +
                  ' with one Bash rm -f (a stale product there passes the verify probe as a false success).'
                : ''),
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
            '/receipt.json then, never a polling loop. Recovery is two-branch and ONCE-only — the whole budget: a receipt reason ' +
            '"crash" alone (the session persisted on disk) overwrites the task file with "continue and complete the lane, then land ' +
            'the receipt" and re-runs the same command plus --resume <the receipt thread_id>; any other failed receipt (' +
            'turn failure or refusal) re-runs the same command untouched.',
        '(3) ' +
            (authored
                ? 'The delegate lands the product itself at ' + report + ' as its final act.'
                : 'The lane lands the product at ' + report + ' via --out.') +
            ' (4) Verify with one Bash call: jq -e . ' +
            report +
            ' >/dev/null — a nonzero exit means a missing or malformed product; on a miss re-derive the product once from the lane ' +
            'events.jsonl (jq -rs to the last agent_message item text, Write that), re-probe, and a second miss returns ok=false with ' +
            'the probe output.',
        o.receipt(base),
        'LANE LAW:\n\n' + laneLaw(schema, o),
        // writes lanes author their own report (final act); the wrapper only verifies.
        'TASK:\n\n' +
            task +
            (authored
                ? '\n\nREPORT FILE (final act): before returning your final message, write that COMPLETE final-message JSON verbatim to ' +
                  report +
                  ' yourself.'
                : ''),
    ].join('\n\n');
};
const twinOf = (m) => (/-terra/.test(m || '') ? 'opus' : /-luna/.test(m || '') ? 'sonnet' : 'fable');
const nativeLane = (task, o) =>
    agent(task + o.nativeTail(SCRATCH + '/' + fileTag(o.label) + '-report.json'), {
        label: o.label,
        phase: o.phase,
        model: o.nativeModel || twinOf(o.model),
        effort: 'high',
        schema: o.wire,
    });
// The discovery lane (a mapping lane — recon law, never fix), with
// the native twin as the quota fallback. The row carries `scope` from the ORCHESTRATOR (never the lane's
// self-report) so a failed lane's territory is exact even when the lane died before writing anything.
const discoveryReceipt = (base) =>
    '(5) Read the product at the report path for the mechanical orchestration data. Return ok=true, report=' +
    base +
    '-report.json, entries=(tasks.length + ideas.length), headline="<entries> open cards | <status tallies>", failure empty, and copy ' +
    'order, cards=(tasks + ideas projected to {slug,pages}), gates, ripples, and malformed from malformed_ripples verbatim from the ' +
    'product. On a failed receipt return ok=false, entries=0, report and headline empty, every structural array empty, and failure ' +
    'equal to the receipt reason and failure text VERBATIM.';
const discoveryTail = (report) =>
    '\n\nPRODUCT TO DISK: write your COMPLETE product as one JSON file matching this schema at ' +
    report +
    ' (Write tool, absolute path under the repo root): ' +
    JSON.stringify(DISCOVERY_SCHEMA) +
    ' — then return ONLY the receipt: ok, report path, entries = open tasks + ideas count, ' +
    'one-line mechanical headline (card count + status counts), failure empty, order, cards ({slug, pages} per open ' +
    'card), gates, ripples, and malformed (= malformed_ripples) transcribed exactly from the product.';
const recon = (task, o) => {
    const opts = { ...o, model: o.model || 'gpt-5.6-terra', writes: !!o.writes, receipt: discoveryReceipt, nativeTail: discoveryTail, wire: RECEIPT };
    return agent(codexPrompt(o.label, task, DISCOVERY_SCHEMA, opts), {
        label: 'terra:' + o.label,
        phase: o.phase,
        model: 'sonnet',
        effort: 'low',
        schema: RECEIPT,
    })
        .then((r) => (r && !r.ok && /usage|quota|limit/i.test(r.failure || '') ? nativeLane(task, opts) : r))
        .then((r) => ({
            lane: o.label,
            scope: o.scope || [],
            ok: !!(r && r.ok && r.report),
            report: (r && r.report) || '',
            entries: (r && r.entries) || 0,
            headline: (r && r.headline) || '',
            failure: (r && r.failure) || (r ? '' : 'lane died'),
            order: (r && r.order) || [],
            cards: (r && r.cards) || [],
            gates: (r && r.gates) || [],
            ripples: (r && r.ripples) || [],
            malformed: (r && r.malformed) || [],
        }));
};
const folderName = (p) => p.split('/').filter(Boolean).pop() || p;

// Critique lane: one blocking supervised Codex CLI process — a FIX lane
// (persistence + post-edit verification law), FIXLOG product to disk, thin receipt on the wire; a quota fallback
// restores the native twin writing the same product to the same path.
const critiqueReceipt = (base) =>
    '(5) Read the product at the report path for the mechanical orchestration data. Return ok=true, report=' +
    base +
    '-report.json, entries=the length of the product["realized"] array, headline="<entries> realized | verdict <verdict>", and failure ' +
    'empty. On a failed receipt return ok=false, entries=0, report and headline empty, and failure equal to the receipt reason and failure text VERBATIM.';
const critiqueTail = (report) =>
    '\n\nPRODUCT TO DISK: write your COMPLETE fix-log as one JSON file matching this schema at ' +
    report +
    ' (Write tool, absolute path under the repo root): ' +
    JSON.stringify(FIXLOG_SCHEMA) +
    ' — then return ONLY the receipt: ok, report path, entries = realized count, one-line mechanical headline, failure empty.';
const solLane = (task, o) => {
    const opts = { ...o, writes: true, fix: true, receipt: critiqueReceipt, nativeTail: critiqueTail, wire: LANE_RECEIPT };
    return agent(codexPrompt(o.label, task, FIXLOG_SCHEMA, opts), {
        label: 'sol:' + o.label,
        phase: o.phase,
        model: 'sonnet',
        effort: 'low',
        schema: LANE_RECEIPT,
    })
        .then((r) => (r && !r.ok && /usage|quota|limit/i.test(r.failure || '') ? nativeLane(task, opts) : r))
        .then((r) => ({
            ok: !!(r && r.ok && r.report),
            report: (r && r.report) || '',
            entries: (r && r.entries) || 0,
            headline: (r && r.headline) || '',
            failure: (r && r.failure) || (r ? '' : 'lane died'),
        }))
        .catch(() => ({ ok: false, report: '', entries: 0, headline: '', failure: 'lane died' }));
};

// Page-disjointness is PROVEN, never assumed: every ordered card must carry >=1 verified page, gate pairs merge, and
// components pack heaviest-first into <= IMPL_FAN buckets without splitting.
const cardGroups = (t) => {
    const inOrder = new Set(t.order || []);
    const cards = (t.cards || []).filter((c) => inOrder.has(c.slug));
    if (cards.length < 2 || cards.some((c) => !(c.pages && c.pages.length))) return null;
    const parent = new Map();
    const seed = (k) => {
        if (!parent.has(k)) parent.set(k, k);
    };
    const find = (k) => {
        let r = k;
        while (parent.get(r) !== r) r = parent.get(r);
        return r;
    };
    const union = (a, b) => {
        seed(a);
        seed(b);
        const ra = find(a);
        const rb = find(b);
        if (ra !== rb) parent.set(ra, rb);
    };
    for (const c of cards) {
        seed('s:' + c.slug);
        for (const p of c.pages) union('s:' + c.slug, 'p:' + p);
    }
    for (const g of t.gates || [])
        if (inOrder.has(g.blocked_slug) && inOrder.has(g.gated_by_slug)) union('s:' + g.blocked_slug, 's:' + g.gated_by_slug);
    const comps = new Map();
    for (const c of cards) {
        const r = find('s:' + c.slug);
        if (!comps.has(r)) comps.set(r, { slugs: [], pages: new Set() });
        const g = comps.get(r);
        g.slugs.push(c.slug);
        for (const p of c.pages) g.pages.add(p);
    }
    if (comps.size < 2) return null;
    const sorted = [...comps.values()].sort((a, b) => b.pages.size - a.pages.size || (a.slugs[0] < b.slugs[0] ? -1 : 1));
    const buckets = Array.from({ length: Math.min(IMPL_FAN, sorted.length) }, () => ({ slugs: [], pages: [] }));
    for (const c of sorted) {
        const b = buckets.reduce((m, x) => (x.pages.length < m.pages.length ? x : m));
        b.slugs.push(...c.slugs);
        b.pages.push(...c.pages);
    }
    return buckets;
};

const groupSeq = (t, g) => {
    const s = new Set(g.slugs);
    return JSON.stringify(
        {
            order: (t.order || []).filter((x) => s.has(x)),
            cards: (t.cards || []).filter((c) => s.has(c.slug)),
            ripples: (t.ripples || []).filter((r) => s.has(r.from_slug)),
            gates: (t.gates || []).filter((x) => s.has(x.blocked_slug)),
            pages: g.pages, // the group's disjoint page set — the report's map rows for these pages are the group's own
        },
        null,
        1,
    );
};
const discoverPrompt = (folder) =>
    [
        LAW,
        '',
        CARD,
        '',
        INFO_LAW,
        '',
        'TASK: DISCOVER + SEQUENCE + MAP the open work of the single Python session target `' +
            folder +
            '` (the full session target set, for ripple ' +
            'classification only: ' +
            JSON.stringify(TARGETS) +
            "). You are the read-only reconnaissance this folder's downstream chain stands on, and " +
            'read-only is your ONLY concession: every row you return is grounded in REAL DISK STATE, never memory. FIRST enumerate with a real listing ' +
            '(`ls`/`fd`, from the source of truth): the target folder at large, its `.planning/**` pages, its `.api/*.md` catalogs, the shared ' +
            '`' +
            SHARED_API +
            '/*.md` tier, and the `docs/stacks/python/` doctrine inventory — resolve the target against what actually exists (a ' +
            'missing folder, card file, or section is a finding to report, never a gap to paper over). THEN read `' +
            folder +
            '/IDEAS.md` + ' +
            '`' +
            folder +
            '/TASKLOG.md` IN FULL — every open card body, every bullet — open the counterpart card file of every `Ripple:` to locate the ' +
            "mirror slug ON DISK, and FULL-READ the design pages each open card's `Anchors:` name — ground order, gates, and every klass call in real " +
            'page state, never card text alone. Return: (1) folder — echo `' +
            folder +
            '` exactly; (2) tasks — EVERY open card in `TASKLOG.md` (status ' +
            'ACTIVE/QUEUED/BLOCKED; carry the Atomic flag); (3) ideas — the 1-3 MOST actionable open cards in `IDEAS.md` (tasks-first doctrine: at most ' +
            '3, the ones whose Anchors are most settled and whose ripples land on in-scope targets), HARD CAP 3; on EVERY task/idea row also return ' +
            'pages — the repo-relative design pages under `' +
            folder +
            "/.planning/**` the card's `Anchors:` name and you VERIFIED exist on disk " +
            '(empty when none verify): these rows prove page-disjoint card groups; (4) order — ONE sequenced slug list, ALL tasks first in dependency ' +
            'order then the chosen ideas; (5) ripples — for EVERY card carrying a `Ripple:` field, one row {from_slug, klass, to_pkg, to_slug}: ' +
            'klass=`in_scope` if to_pkg is one of the session targets, `oos_samelang` if it is another libs/python folder, `cross_lang` if it points at ' +
            '`libs/csharp` / `libs/typescript` / `libs/python/.planning` / `libs/.planning`; (6) gates — for any [BLOCKED] card, {blocked_slug, ' +
            'gated_by_slug, in_scope} where in_scope is true iff the gating work is itself an open card in one of the session targets; (7) map — one ' +
            'row per design page the open cards target, AND one row per ripple-counterpart page ' +
            "(the design page a `Ripple:` row's counterpart card names in its own folder — read it and anchor its seam surface, so the writers " +
            'reach every counterpart hot instead of cold-hunting it): {page, files: every file (the page, its cited ' +
            "catalogs, its seam counterparts) the downstream writers must open for this row, anchors: exact coordinates backing the row's facts per " +
            'the ROW FORM law, members: the exact verified member spellings backing underutilized, each verified against its owning `.api` catalog or ' +
            'via `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api`' +
            FB +
            ' (verified members ONLY — a member you cannot verify is a phantom and is NEVER listed; exact spellings and locations, never judgment ' +
            'wording), composed: the capability the page already composes, underutilized: catalog-anchored member FACTS the page does not yet compose, ' +
            'seams: the contextual cross-page/cross-folder seams the page meets, stacking: how the catalog capability stacks into the realization}. ' +
            'The map carries NAVIGATION FACTS — paths, verified member locations, seam targets — never verdicts; downstream agents treat it as an ' +
            'initial pointer, never a ceiling, and it licenses no skim; (8) coverage — the honesty ledger per the ROW FORM law. Also return ' +
            'malformed_ripples for any `Ripple:` line you cannot parse into a pkg+slug, or whose counterpart slug you cannot locate on disk. Classify ' +
            'from the FULL card body against the real files — never from the thesis, never from memory; list only slugs, files, and gates you verified ' +
            'on disk, never a phantom. Carry each task/idea row ' +
            "`thesis` as a one-line charter hook: the charter's composed capability and the concrete " +
            'verified `.api` members it stacks (exact spellings, each with its owning catalog) — navigation facts only, never a verdict on the current ' +
            'fence state. Your product is a MAP of navigation facts — paths, verified member locations, seam targets — and it is an initial pointer, ' +
            'never a ceiling: downstream agents re-read everything and it licenses no skim. Return the structured map ONLY; edit nothing.',
    ].join('\n');

const implementPrompt = (folder, seq, note, report, ownpass) =>
    [
        DOCTRINE,
        '',
        STANCE,
        '',
        OWN_PASS(ownpass),
        '',
        'TASK: IMPLEMENT — realize the open cards of `' +
            folder +
            '` into deep design-page FENCES at the doctrine bar. The sequenced worklist (slugs + ' +
            'ripple map; read each FULL card body from `' +
            folder +
            '/IDEAS.md` + `' +
            folder +
            '/TASKLOG.md`, never the thesis alone):\n' +
            seq +
            "\nDISCOVERY REPORT: the folder's full navigation-facts product — per-card status + `thesis` charter hooks naming verified `.api` member " +
            'spellings with owning catalogs, ripple/gate grounding, the per-page navigation map ({page, files, anchors, members, composed, ' +
            'underutilized, seams, stacking}), and the lane `coverage` — is ON DISK at `' +
            report +
            '`: read it IN FULL from disk as ladder rung 2 (your own pass precedes it); its rows are FACTS with jump-coordinate anchors, never ' +
            'verdicts or ceilings — spot-verify what you ' +
            'build on, re-open every anchor behind an edit, hunt past the map on your own authority, and give any `skipped`/`unverified` coverage ' +
            'entry your own cold read.\nREAD: ' +
            'each card full body; every design page the card names under `' +
            folder +
            '/.planning/**`; the sibling pages it seams to, at their CURRENT ' +
            'on-disk state; the package-root `ARCHITECTURE.md` + `README.md`; the operative docs/stacks/python/ pages (docs/stacks/csharp/ as the ambition ' +
            'floor); BOTH .api tiers — the shared `' +
            SHARED_API +
            '/*.md` AND the folder `' +
            folder +
            '/.api/*.md` (stack them, the shared rails ' +
            'layered onto the folder packages); and verify any novel member via `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api`' +
            FB +
            '. Realize EVERY card in ' +
            '`order` (all tasks incl. Atomic, then the ideas) into deep fences in the `' +
            folder +
            '` design pages, in LIFECYCLE order (admit raw ONCE ' +
            'into a typed `TypedDict`/Pydantic payload -> materialize into the canonical owner the OWNER_CHOOSER discriminants select -> weave every ' +
            'cross-cutting concern (retry/telemetry/validation/contracts/memo/receipts) as a STACKED signature+rail-preserving aspect over a thin pure ' +
            'core -> compose the domain transform through ONE unified `Result`/`Option` rail with total `match` -> project + `msgspec.Struct` egress, ' +
            'BOTH ingress and egress parameterized). Collapse parallel shapes into one closed family/ADT (`@tagged_union`); drive cases with a derived ' +
            '`frozendict` table or fold; one polymorphic entrypoint per modality (`T | Iterable[T]` normalized once). ' +
            'CAPABILITY-COMPLETENESS IS MANDATORY, NOT OPTIONAL: for every owner you author, the body implements what its names and ' +
            'prose promise — a named-but-omitted capability is a defect you close NOW, at the same bar as any bar finding, never a ' +
            'follow-up. py3.15-modern only (PEP ' +
            '585/604/695, `frozendict` builtin, newest payload forms; NO `from __future__ import annotations`, NO legacy typing, NO ' +
            '`asyncio`/`None`-as-failure). Resolve any [BLOCKED] card inline (assay api for members' +
            FB +
            '; `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay provision ' +
            'check` for native/scientific/provisioning bands). RIPPLES ARE YOURS: repair every ripple your cards carry in this same pass per the RIPPLE ' +
            'law — align each in-scope seam to the counterpart page as it NOW stands on disk, realize each 1-hop out-of-scope same-language counterpart ' +
            'card fence and align both ends, land your half of each cross-language seam stating the wire contract — and record each repair in `ripples`. ' +
            'PACKAGE ADMISSION per the card law: decide the band, folder-local parts NOW, the central `' +
            CENTRAL +
            '` row + band marker reported in ' +
            "`pins`, never edited; a landed cross-folder seam's `ARCHITECTURE.md` `[02]-[SEAMS]` row reported in `seams`, never edited. Do NOT close " +
            'any card — the folder red-team owns card status. High-signal prose all-backticked, comment hygiene, fix-in-place (read-then-extend, ' +
            'preserve capability). Return verdict + realized slugs + deferred (any card you could not realize, with reason) + collapsed (before->after ' +
            'counts) + ripples + pins + seams + harvest + summary. ' +
            HARVEST_LAW +
            (note ? '\n' + note : ''),
    ].join('\n');

// critiquePrompt feeds the critique codex lane (+ its native twin): neutral stance — the hostile register degrades
// that lane, safe for the twin; the hostile pass is redteam (native).
const critiquePrompt = (folder, seq, report, ownpass) =>
    [
        DOCTRINE,
        '',
        OWN_PASS(ownpass),
        '',
        'TASK: DOCTRINAL-CONFORMANCE AUDIT + CHARTER-COMPLETENESS + FIX IN PLACE across `' +
            folder +
            '`. Verify every fence against the doctrine before accepting it — a fence is unproven until checked, and ' +
            'confident-looking prose is not evidence it conforms. The cards realized this turn (read each ' +
            'FULL body from `' +
            folder +
            '/IDEAS.md` + `' +
            folder +
            '/TASKLOG.md`):\n' +
            seq +
            '\nThe discovery navigation-facts report at `' +
            report +
            '` (on disk) carries per-card charter hooks and the per-page navigation map — facts with jump-coordinate anchors, never verdicts; ' +
            'consult it for verified members, seam targets, and coverage gaps (it licenses no skim), ' +
            'then audit against CURRENT disk only.\nREAD the realized pages under `' +
            folder +
            '/.planning/**`, ' +
            'the sibling pages at their CURRENT on-disk state, the operative docs/stacks/python/ pages, and BOTH .api tiers (shared `' +
            SHARED_API +
            '` + ' +
            'folder `' +
            folder +
            '/.api`). Run these MECHANICAL checklists line-by-line and REPAIR every hit in place (a fix, never a ledger note); the ' +
            'checklists are a FLOOR you hunt past, never the complete audit:',
        '(1) COLLAPSE_SCAN — apply the move for any signal (shapes sharing an identity regime, an admission path, a payload timing, or a ' +
            'consumer collapse into ONE owner; a shape survives only on a genuinely distinct discriminant): sibling prefix/suffix names -> one ' +
            'modality-polymorphic entrypoint; same return rail differing only by arity -> input-shape discrimination; a `get`/`get_many`/`get_by_id` ' +
            'family -> one input-keyed entrypoint; functions differing only by a literal -> parameterize the literal as policy; a bool parameter selecting ' +
            'two bodies -> one derived body or policy value; a function calling exactly one other -> delete the hop; a class exposing one public method -> ' +
            'module function or fold-on-owner; parallel dispatch arms repeating structure -> a `frozendict` table or fold algebra; several types sharing ' +
            'fields for one concept -> one closed family; sibling module constants sharing one concept -> one `frozendict`/`StrEnum`; a wrapper renaming a ' +
            'package API -> use the package surface directly; co-occurring wrappers sharing an admission path -> one parameterized aspect factory. These signals are a ' +
            'FLOOR — hunt collapse targets past them.',
        '(2) OWNER_CHOOSER — for EVERY shape re-derive the owner from the 5 discriminants (admission, identity regime, variant arity, payload timing, ' +
            'openness); if it is not the discriminant-correct owner (`TypedDict`/Pydantic/`msgspec.Struct`/frozen dataclass/rich ' +
            'class/`StrEnum`/`Literal`/`sentinel`/`Option`/`Result`/`frozendict`/`Map`/`tuple`/`Protocol`), replace it. Kill every parallel DTO, one-field ' +
            'wrapper, field-rename class, tag-only shape, and `None`-as-failure.',
        '(3) KNOB_TEST — delete each parameter: if the value already encodes what it carried, it was a knob — collapse a `strict: bool`/`mode`/`batch` ' +
            'flag into a policy value or input-shape discriminant, and move every `timeout`/`retry`/`deadline` out of the signature into an aspect or ' +
            '`anyio` scope.',
        '(4) ASPECTS — every cross-cutting concern (retry/telemetry/validation/contracts/memo/registration/receipts) MUST be a signature+rail-preserving ' +
            'STACKED decorator that never raises into domain flow; co-occurring wrappers sharing an admission path collapse into one aspect factory; deterministic stacking ' +
            'order verified. Inline-repeated concerns and sibling helper functions are defects.',
        '(5) RAILS — narrowest carrier chosen once; the fault type is a CLOSED `Literal`/`StrEnum`/`@tagged_union` (a bare `str` fault for a multi-cause ' +
            'domain is a defect); accumulate-vs-abort disposition correct (`map2`/fold for independents, `bind` for dependents); NO `asyncio`, NO ' +
            'hand-rolled retry loop, NO `None`-as-failure, NO exception control flow in domain logic.',
        '(6) PAYLOADS/FROZENDICT/PEP — payloads are `closed=`/`extra_items=` `TypedDict` via a module-level `TypeAdapter` with `Unpack[TypedDict]` at ' +
            'root entrypoints; `frozendict` (builtin) owns tables/evidence (no `MappingProxyType`/dict-table/tuple-pairs); PEP 585/604/695 only, no `from ' +
            '__future__ import annotations`, no legacy typing; total `match` + `assert_never`.',
        '(7) CHARTER-COMPLETENESS — for EVERY card in the worklist, verify the realized fences GENUINELY fulfill its `Capability`/`Shape`/`Unlocks` ' +
            '(read the full card from disk): a missing modality, an unrealized `Shape` clause, a stubbed/placeholder fence, or a capability the card ' +
            'promises but the fences do not deliver is a DEFECT — realize it NOW. A card whose fences are thin against its charter is not done. Hunt ' +
            'BOTH naivety axes per card: COVERAGE (a thin slice of the charter concept) and APPROACH (a hardcoded roster where ONE parameterized ' +
            'generator should own the space); rebuild to the generative form on either hit.',
        '(8) SEAMS — check every cross-page and cross-folder symbol these cards compose against the counterpart as it NOW stands on disk: a signature ' +
            'mismatch corrects at the weaker end, a conflict resolves to the stronger form, never a revert; a seam counterpart or consumer site your fix ' +
            'exposes is repaired in this same pass wherever it lives, recorded in `ripples` (a target `ARCHITECTURE.md` `[02]-[SEAMS]` row change is ' +
            'reported in `seams` for the terminal single-writer, never edited directly).',
        'Also enforce both-tier `.api` use (a thin folder-only subset ignoring the shared rails the card needs is a defect), cross-folder convention ' +
            'consistency, and prose + comment hygiene. FIX every hit NOW wherever it lives per WRITE-FULLY; report any central `' +
            CENTRAL +
            '` row in ' +
            '`pins`. Return verdict + realized + deferred + collapsed + ripples + pins + seams + harvest + summary. ' +
            HARVEST_LAW,
    ].join('\n');

const redteamPrompt = (folder, seq, report, critReport, critOk, ownpass) =>
    [
        DOCTRINE,
        '',
        STANCE,
        '',
        OWN_PASS(ownpass),
        '',
        'TASK: ADVERSARIAL ARCHITECT RED-TEAM + FIX IN PLACE + TERMINAL CLOSE across `' +
            folder +
            '`. You are the LAST and MOST AGGRESSIVE pass: ' +
            'assume the author and critique missed things and that the chosen design is not the strongest until proven, with the burden of proof ON THE ' +
            'DESIGN. The cards realized this turn (read each FULL body):\n' +
            seq +
            '\n' +
            'PRIOR CLAIMS (UNVERIFIED): the critique fixlog at `' +
            critReport +
            '`' +
            (critOk
                ? ''
                : ' (its wrapper receipt died, but the write lane writes the fixlog to disk itself — CHECK THE ' +
                  'PATH FIRST; absent or unparseable, your cold attack is the only review this folder gets: judge from CURRENT disk alone)') +
            ' — read it IN FULL from disk; its edits and verdicts are refutation targets you judge against CURRENT disk, never a settled ' +
            'record. FOLD-FORWARD DUTY: its surviving `ripples`, `pins`, `seams`, and `deferred` rows fold into YOUR return ' +
            "(re-verified against current disk, deduped) — your return is the folder's consolidated record. Its `harvest` rows are NOT yours to " +
            'fold: the doctrine lander sweeps every critique fixlog from disk directly — nomination transport never rides a living fold.' +
            '\nThe discovery navigation-facts report at `' +
            report +
            '` (on disk) carries per-card charter hooks and the per-page navigation map — facts with jump-coordinate anchors, never verdicts; ' +
            'consult it for verified members, seam targets, and coverage gaps — ' +
            'a pointer for your attack, never evidence of health.\nOpen BOTH .api tiers (shared `' +
            SHARED_API +
            '` + folder ' +
            '`' +
            folder +
            '/.api`), the sibling pages at their CURRENT on-disk state, and the operative docs/stacks/python/ pages. Attack from every ' +
            'direction and REPAIR every defect in place — no soft-pedalling, no could/should, a fix never a ledger.',
        'PRIMARY LENS — fundamental design, multi-faceted / multi-dimensional / multi-directional: (A) COUNTERFACTUAL on the core ' +
            'owner/algebra/dispatch — a counterfactual REBUILDS the design with its central assumption removed, never merely questions ' +
            'it: name the assumption the current shape stands on (the chosen owner kind, the hand-enumerated space, the call-site ' +
            'dispatch, the hand-rolled kernel), derive the form the fence takes WITHOUT it — a denser owner, a fold/derived-table ' +
            'algebra, or a DEEPER admitted-package primitive — and where the rebuilt form is stronger, BUILD IT IN PLACE; a stronger ' +
            'design once seen is never defended against, and "the current shape also works" is not a refutation. ' +
            '(B) ANTICIPATORY_COLLAPSE — compute the DIFF OF THE NEXT FEATURE: when the next case/dimension/knob/modality/provider arrives, ' +
            'does it land as ONE declaration with every consumer untouched (or broken loudly at type-check)? If it would touch multiple sites, reshape so ' +
            'the growth axis is a case, row, policy value, or carrier swap. (C) LONG-TAIL + MULTI-DIMENSIONAL — attack every input/output/edge/failure ' +
            'mode (empty, singular, plural, stream, malformed, concurrent, cancelled, partial-failure, version-skew); is the accumulate-vs-abort ' +
            'disposition correct for the REAL boundary; are BOTH ingress AND egress parameterized so this owner sources and sinks across many apps without ' +
            'interior edits? (D) BOUNDARY-INTEGRITY — a concern owned twice in a runtime, a folder mixing concerns, a concern scattered across folders, ' +
            'coupling to a sibling owner INTERIOR (vs its wire/seam), OR a sibling planning page left STALE by this folder change even when no ripple card ' +
            'names it (ports/boundaries/wires/seams drift) is a defect: fix it NOW wherever it lives — the stale sibling page, the seam counterpart, the ' +
            'consumer site — and record the repair in `ripples` (a target `ARCHITECTURE.md` `[02]-[SEAMS]` row change is reported in `seams` for the ' +
            'terminal single-writer, never edited directly). (E) SURFACE-SPRAWL-IN-TIME — an admitted package whose `.api` exposes capability the ' +
            'card needs but the fence re-derives by hand, flat code below the operator depth the packages reach, a phantom `.api` member, or a thin ' +
            'wrapper: collapse to package depth and verify the member exists (via `assay api`' +
            FB +
            ').',
        'ALSO — FULL COLD ADVERSARIAL RE-REVIEW (every time, NOT only on a structural restructure): re-attack every conformance dimension with fresh ' +
            'hostile eyes, trusting nothing the prior passes claimed — the COLLAPSE_SCAN signals, OWNER_CHOOSER per shape, the KNOB_TEST per param, the ' +
            'ASPECT taxonomy, rail + closed-fault-vocabulary discipline, charter-completeness per card, BOTH naivety axes (COVERAGE thin-slice; ' +
            'APPROACH roster-where-a-generator-should-own-the-space), payload/`frozendict`/PEP conformance, both-tier ' +
            '`.api` use, py3.15-modern typing, and prose/comment hygiene — and fix every defect. Even absent a structural rebuild, the fences must end ' +
            'objectively denser, more correct, and more powerful than the critique left them; if the strongest form is genuinely already present, prove it ' +
            'by finding nothing — never invent churn.',
        'TERMINAL CLOSE — you are `' +
            folder +
            "`'s LAST stage and the SOLE owner of its card status. For EVERY card in scope this run, re-read its " +
            'FULL body and the realized fences on CURRENT disk, then ADVERSARIALLY VERIFY — the fences are naive until they survive your attack, a prior ' +
            'pass verdict a rejected self-assessment — that they genuinely fulfill the card `Capability`/`Shape`/`Unlocks` against the verified `.api` ' +
            '(verify novel members via `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api`' +
            FB +
            '). FINAL-remediate any weak or partial realization in place NOW, then ' +
            'assign each card a strength: `strong` (every charter clause delivered, fences transcription-complete against the verified `.api`), `partial` ' +
            '(most delivered, a clause still thin), `weak` (charter not met). CLOSE only `strong` cards per the CARD CLOSURE law; a ripple card whose ' +
            'seam you cannot verify landed on BOTH ends on current disk stays OPEN with that reason; honestly RE-OPEN every card you cannot bring to ' +
            '`strong`, with a one-line reason (a real out-of-run or cross-language dependency). The orchestrator DEMOTES any card closed below `strong`, ' +
            'so never inflate. Return verdict + realized + deferred + collapsed + ripples + pins + seams + harvest + closed [{slug, disposition, ' +
            'strength}] + reopened [{slug, reason}] + summary. ' +
            HARVEST_LAW,
    ].join('\n');

const pinPrompt = (pins, seams, orphans, backlog, round) =>
    [
        round
            ? 'DRAIN ROUND ' +
              round +
              ' — every tranche below re-arrives in FULL; the checkpoint ledger is the consumption truth, so skip every tranche it already ' +
              'receipts (an interrupted drain re-enters, never restarts) and drain the rest. The backlog rows were verified STILL-OPEN by the ' +
              'prior round; realize or repair each at its root NOW, and a row you genuinely cannot land carries its named blocker and owner in `remaining`.'
            : '',
        LAW,
        '',
        PROSE,
        '',
        'CHECKPOINT LEDGER: `' +
            SCRATCH +
            '/pins-checkpoint.md` — read it FIRST and skip every tranche it already receipts; append one line per tranche AS EACH ' +
            'COMPLETES (each critique fixlog drained, the backlog block, the pin apply, the seam apply). HARVEST FILE: append each ' +
            '`harvest` nomination to `' +
            SCRATCH +
            '/pins-harvest.jsonl` (one JSON row per line) the moment it is minted — the doctrine lander sweeps the file, so a killed ' +
            'round loses no nomination; your returned `harvest` carries the same rows.',
        "TASK: TERMINAL SINGLE-WRITER + BACKLOG DRAIN — you are the run's SOLE writer for the repo-root `" +
            CENTRAL +
            '` and for every target `ARCHITECTURE.md` `[02]-[SEAMS]` section, and its LAST agent. TRANCHE ORDER IS EXECUTION ORDER — the ' +
            'critique-fixlog drain and backlog card realization (the substantive tranches) precede the mechanical pin + seam application by ' +
            'design; never demote them behind the manifest edits, and the checkpoint ledger re-feeds any tranche a truncated round left ' +
            'unreceipted, so ordering by value costs no durability.\n' +
            [
                orphans.length
                    ? '(1) CRITIQUE FIXLOGS — every critique fixlog, folded-forward or orphaned (a live redteam folds judgment-lossy and a ' +
                      'dead one folds nothing); the paths are DETERMINISTIC, so one absent on disk is skipped with a one-line note in `summary`, ' +
                      'never an error. Read each present file IN FULL, apply its pin and seam rows under the same law as the reported rows below, ' +
                      'and drain its surviving seam/deferred/index rows still open (a row a live redteam already landed disk-resolves and drops). ' +
                      "Its `harvest` rows are the doctrine lander's to sweep, never yours to fold: " +
                      JSON.stringify(orphans) +
                      '.'
                    : '',
                backlog.length
                    ? '(2) BACKLOG DRAIN (deferred cards the folder chains could not realize — re-verify each {files, claim} on CURRENT disk, ' +
                      'realize any whose gate landed this run in a sibling folder now that every chain has closed, reject what disk already ' +
                      'resolved): ' +
                      JSON.stringify(backlog, null, 1) +
                      '.'
                    : '',
                pins.length
                    ? '(3) PINS — apply each reported dependency row + band marker exactly once, preserving the existing group/marker order and ' +
                      'deduping semantically identical rows; verify each package, version, and band before applying — pure-Python wheel vs ' +
                      'scientific/native (`UV_CACHE_DIR=.cache/uv uv run python -m tools.assay provision check`; the package wheel/build metadata via Context7/PyPI ' +
                      "evidence when assay is unavailable) vs companion-band `; python_version<'3.15'` marker; confirm the folder README group " +
                      'and `.api/<package>.md` catalog landed, repairing a missing folder-local part in place: ' +
                      JSON.stringify(pins, null, 1) +
                      '.'
                    : '',
                seams.length
                    ? "(4) SEAM ROWS — upsert each reported {file, row} into the named file's `[02]-[SEAMS]` section exactly once, preserving the " +
                      "section's row format and order and deduping semantically identical rows; a missing file or absent `[02]-[SEAMS]` section " +
                      'rejects the row: ' +
                      JSON.stringify(seams, null, 1) +
                      '.'
                    : '',
                'Reject any unverifiable or malformed row as {target, reason} — never apply it silently. Return applied + seam_rows_applied + ' +
                    'rejected + summary, and `remaining` carrying ONLY backlog rows verified still-open on current disk and genuinely blocked, ' +
                    'each claim naming its blocker and owner; a row disk already resolved is culled with proof in `rejected`, and an empty ' +
                    '`remaining` attests the drain closed. ' +
                    HARVEST_LAW,
            ]
                .filter(Boolean)
                .join('\n'),
    ]
        .filter(Boolean)
        .join('\n');

const doctrinePrompt = (rows, orphans) =>
    'TASK: DOCTRINE LANDER — the durable-learning terminal of this run. Read `docs/laws/README.md` FIRST — it ' +
    'owns the corpus admission and page-shape law; obey it over any restatement. Load the `docgen` skill via ' +
    'the Skill tool BEFORE any durable edit; ' +
    'load `mermaid-diagramming` before touching any diagram. ' +
    "NOMINATIONS (unverified, biased toward their authors' own work — refute by default): " +
    JSON.stringify(rows) +
    '\nAlso sweep `' +
    SCRATCH +
    '/pins-harvest.jsonl` (absent = none): rows there missing from NOMINATIONS are nominations too — a killed terminal-drain round reaches ' +
    'you only through that file.' +
    '\nAlso read the `harvest` array of every critique fixlog at these deterministic paths (an absent or invalid file skips; no other agent ' +
    'transports these rows): ' +
    JSON.stringify(orphans) +
    ' — dedupe them against NOMINATIONS and adjudicate them identically.' +
    '\nADJUDICATE each row per the admission bar: cold-read its target surface IN FULL, verify its anchors on ' +
    'CURRENT disk; LAND NOTHING is a ' +
    'first-class verdict.\nTOPOLOGY RE-PROOF: re-verify every `docs/laws/topology.md` row whose [SURFACE] this run touched — cull a row whose ' +
    'coupling no longer holds, land a coupling this run proved.\nGATE: run `uv run .claude/skills/docgen/scripts/prose_gate.py <every touched ' +
    '.md>` and repair to zero FAILs before returning. Return landed/refined/rejected (each rejection with its reason)/files/summary.';

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('Realize');
log('Pooling ' + TARGETS.length + ' folder chain(s) at CAP=' + CAP);
const runFolder = async (target) => {
    const tag = folderName(target);
    try {
        const t = await recon(discoverPrompt(target), { label: 'discover:' + tag, phase: 'Realize', scope: [target] });
        if (!t.ok) return { folder: target, failed: true, empty: false, logs: [], red: null, cross_lang: [], malformed: [], error: t.failure }; // failed lanes filter on ok, never a sentinel string
        const cross = t.ripples
            .filter((rp) => rp.klass === 'cross_lang')
            .map((rp) => tag + ' [' + rp.from_slug + '] -> ' + rp.to_pkg + ' [' + rp.to_slug + ']');
        const malformed = t.malformed;
        if (!t.cards.length) return { folder: target, failed: false, empty: true, logs: [], red: null, cross_lang: cross, malformed };
        log(tag + ': discovery ' + t.headline + ' | report: ' + t.report);
        const seq = JSON.stringify({ order: t.order, cards: t.cards, ripples: t.ripples, gates: t.gates }, null, 1);
        const groups = cardGroups(t);
        // Each implement writer is CRITICAL — its death loses landed fences — so a dead lane earns the attempt-counted retry.
        let impls;
        if (groups) {
            log(
                tag +
                    ': implement fan over ' +
                    groups.length +
                    ' page-disjoint group(s); page weights ' +
                    groups.map((g) => g.pages.length).join('/'),
            );
            impls = (
                await parallel(
                    groups.map((g, gi) => async () => {
                        const fire = (suffix) =>
                            agent(
                                implementPrompt(target, groupSeq(t, g), GROUPNOTE, t.report, SCRATCH + '/ownpass-impl-' + tag + '-g' + gi + '.md'),
                                {
                                    label: 'implement:' + tag + ':g' + gi + suffix,
                                    phase: 'Realize',
                                    schema: FIXLOG_SCHEMA,
                                    model: 'fable',
                                    effort: 'high',
                                },
                            );
                        return (await fire('')) || (await retryLane(() => fire(':r1')));
                    }),
                )
            ).filter(Boolean);
        } else {
            const fire = (suffix) =>
                agent(implementPrompt(target, seq, '', t.report, SCRATCH + '/ownpass-impl-' + tag + '.md'), {
                    label: 'implement:' + tag + suffix,
                    phase: 'Realize',
                    schema: FIXLOG_SCHEMA,
                    model: 'fable',
                    effort: 'high',
                });
            const one = (await fire('')) || (await retryLane(() => fire(':r1')));
            impls = one ? [one] : [];
        }
        // CHAIN CONTINUATION: a dead implement NEVER severs the reviews — the critique's conformance audit and the red-team's
        // pre-mortem still improve the pages as they stand on disk; the seq worklist stays their target and navigation arrives empty.
        if (!impls.length) log(tag + ': implement lane(s) died after retry — critique + red-team run against current disk');
        // Critique: fixlog to disk, receipt on the wire. The report path is DETERMINISTIC (orchestrator-computed), so a dead
        // receipt never severs the fold — the write lane writes its fixlog to disk itself, and the
        // red-team + terminal single-writer verify the path on disk instead of trusting the receipt `ok`.
        const critReport = SCRATCH + '/' + fileTag('critique:' + tag) + '-report.json';
        const crit = await solLane(critiquePrompt(target, seq, t.report, SCRATCH + '/ownpass-crit-' + tag + '.md'), {
            label: 'critique:' + tag,
            phase: 'Realize',
        });
        const critOk = !!(crit && crit.ok);
        const fireRt = (suffix) =>
            agent(redteamPrompt(target, seq, t.report, critReport, critOk, SCRATCH + '/ownpass-rt-' + tag + '.md'), {
                label: 'redteam:' + tag + suffix,
                phase: 'Realize',
                schema: REDTEAM_SCHEMA,
                model: 'fable',
                effort: 'high',
            });
        const red = (await fireRt('')) || (await retryLane(() => fireRt(':r1')));
        return {
            folder: target,
            failed: !impls.length && !red, // failure isolation: only when NO writer landed — a live review alone still counts as work
            empty: false,
            logs: [...impls, red].filter(Boolean),
            red,
            critReport, // deterministic path, always — the terminal sweep survives a dead critique receipt
            cross_lang: cross,
            malformed,
        };
    } catch (e) {
        return {
            folder: target,
            failed: true,
            empty: false,
            logs: [],
            red: null,
            cross_lang: [],
            malformed: [],
            error: String((e && e.message) || e),
        }; // failure isolation: one thrown chain never rejects the pool
    }
};
const done = (await pool(TARGETS, CAP, runFolder)).filter(Boolean);
const failed = done.filter((r) => r.failed).map((r) => r.folder);
const emptyFolders = done.filter((r) => r.empty).map((r) => r.folder);
const active = done.filter((r) => !r.failed && !r.empty);
const crossLang = done.flatMap((r) => r.cross_lang || []);
const deferred = done.flatMap((r) => r.logs.flatMap((l) => (l.deferred || []).map((d) => ({ folder: r.folder, slug: d.slug, reason: d.reason }))));
const ripplesRepaired = done.flatMap((r) => r.logs.flatMap((l) => l.ripples || []));
const pinsReported = [...new Map(done.flatMap((r) => r.logs.flatMap((l) => l.pins || [])).map((p) => [p.package + '|' + p.row, p])).values()];
const seamsReported = [...new Map(done.flatMap((r) => r.logs.flatMap((l) => l.seams || [])).map((s) => [s.file + '|' + s.row, s])).values()];
let closed_count = 0;
const reopened = [];
for (const r of done) {
    for (const c of (r.red && r.red.closed) || []) {
        if (c.disposition === 'complete' && c.strength !== 'strong')
            reopened.push({ folder: r.folder, slug: c.slug, reason: 'demoted: strength=' + c.strength });
        else closed_count++;
    }
    for (const ro of (r.red && r.red.reopened) || []) reopened.push({ folder: r.folder, slug: ro.slug, reason: ro.reason });
}
log(
    'Realize: ' +
        active.length +
        '/' +
        TARGETS.length +
        ' folder(s) realized (' +
        emptyFolders.length +
        ' empty); ' +
        closed_count +
        ' cards closed, ' +
        reopened.length +
        ' re-open/demoted; ' +
        ripplesRepaired.length +
        ' ripple repair(s); ' +
        pinsReported.length +
        ' pin(s) + ' +
        seamsReported.length +
        ' seam row(s) reported' +
        (failed.length ? '; failed: ' + failed.join(', ') : ''),
);

// --- [PINS]

// EVERY critique fixlog on disk (not only orphaned ones): the redteam fold-forward is lossy even when it lands, so the
// terminal single-writer re-verifies each against current disk and drops what a live fold already landed.
const ORPHANS = done.map((r) => r.critReport || '').filter(Boolean);
// The deferred cards a folder chain could not realize become the drain backlog in {files, claim} form.
const BACKLOG = deferred.map((d) => ({ files: [], claim: d.folder + ' [' + d.slug + ']: ' + d.reason }));
// Terminal DRAIN LOOP: one serial single-writer per round. Every round re-receives the FULL tranche set (pins, seam rows,
// every critique fixlog, the still-open backlog) — the disk checkpoint ledger is the consumption truth, so a receipted tranche
// skips and a dead/partial round loses nothing; only the backlog narrows round over round. The lane is CRITICAL (a dead terminal
// loses the pin apply + backlog drain), so it earns retryLane; a round cap + no-shrinkage progress gate bound the loop.
const PINS_NEEDED = pinsReported.length || seamsReported.length || ORPHANS.length || BACKLOG.length;
let pinlog = null;
let pinHarvest = [];
let residuals = BACKLOG;
let lastOpen = Infinity;
if (PINS_NEEDED) {
    phase('Pins');
    for (let round = 0; round < DRAIN_ROUNDS; round++) {
        const fire = (suffix) =>
            agent(pinPrompt(pinsReported, seamsReported, ORPHANS, residuals, round), {
                label: (round ? 'pins:r' + round : 'pins') + suffix,
                phase: 'Pins',
                schema: PIN_SCHEMA,
                model: 'opus',
                effort: 'high',
            });
        pinlog = (await fire('')) || (await retryLane(() => fire(':a1')));
        if (!pinlog) break; // dead round after retries: the fed-in sets survive to the run return; every disk tranche stays checkpoint-re-enterable
        pinHarvest = pinHarvest.concat(pinlog.harvest || []);
        const open = pinlog.remaining || [];
        residuals = open;
        if (!open.length || open.length >= lastOpen) break;
        lastOpen = open.length;
    }
}
// DOCTRINE LANDER: the run's durable-learning terminal — pooled harvest nominations adjudicated against the live docs/laws
// surfaces; refutation-first, land-nothing legal. A DEAD terminal drain still fires it (the killed round's per-round nominations
// live only in the harvest jsonl the lander sweeps), and critique fixlogs on disk fire it too — the lander is those arrays' ONLY
// transport, so a zero-wire-nomination run with a live drain still lands critique nominations.
const HARVEST_ROWS = done.flatMap((r) => r.logs.flatMap((l) => l.harvest || [])).concat(pinHarvest);
let doctrine = null;
if (HARVEST_ROWS.length || ORPHANS.length || (PINS_NEEDED && !pinlog)) {
    phase('Pins');
    doctrine = await agent(doctrinePrompt(HARVEST_ROWS, ORPHANS), {
        label: 'doctrine',
        phase: 'Pins',
        schema: DOCTRINE_SCHEMA,
        model: 'fable',
        effort: 'high',
    });
}

return {
    root: ROOT,
    targets: TARGETS,
    realized_folders: active.map((r) => r.folder),
    empty_folders: emptyFolders,
    realize_failed: failed,
    deferred,
    ripples_repaired: ripplesRepaired.length,
    closed_count,
    reopened,
    pins: {
        reported: pinsReported.length,
        seams_reported: seamsReported.length,
        applied: (pinlog && pinlog.applied) || [],
        seam_rows_applied: (pinlog && pinlog.seam_rows_applied) || [],
        rejected: (pinlog && pinlog.rejected) || [],
    },
    residuals,
    doctrine: doctrine && {
        nominated: HARVEST_ROWS.length,
        landed: (doctrine.landed || []).length,
        refined: (doctrine.refined || []).length,
        rejected: (doctrine.rejected || []).length,
        files: doctrine.files || [],
        summary: doctrine.summary,
    },
    cross_language: crossLang,
    malformed_ripples: done.flatMap((r) => r.malformed || []),
};
