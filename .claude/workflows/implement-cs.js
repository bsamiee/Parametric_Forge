export const meta = {
    name: 'implement-cs',
    whenToUse: 'Realize open IDEAS and TASKLOG cards into design-page code fences across the C# target folders.',
    description:
        "Realize every open IDEAS/TASKLOG card across the C# target set (default: Rasm.AppHost, Rasm.Compute, Rasm.AppUi, Rasm.Persistence; any libs/csharp package via args) into deep design-page code FENCES at the docs/stacks/csharp bar, repair every ripple in-pass, and truthfully close the cards. Each target folder runs its OWN discover -> implement -> critique -> redteam chain, ALL chains concurrent under one pooled cap: a folder starts the moment its own discovery lands, a folder with no open cards no-ops after its own discovery, and a failed chain isolates without rejecting the pool. Discovery hands downstream stages navigation FACTS (paths, verified catalog members, seam targets) and never verdicts; it runs as a recon lane, writes its COMPLETE product as one on-disk report the folder's implement/critique/redteam stages read IN FULL from disk, and returns a thin receipt with the jq-extracted structural skeleton (order, card rows with verified pages, ripple classes, gates) the orchestrator's no-op/fan/ripple control flow runs on; when the skeleton proves page-disjoint card groups, the implement stage fans over them. Every stage WRITES and repairs the page-level ripples its own work exposes in the same pass — in-scope seams aligned against current disk, 1-hop out-of-scope C# counterpart fences realized directly — with BLOCKED probes and folder-local package admission inline. The redteam is each folder chain's terminal stage and sole card-status owner: it final-remediates weak realizations in place and closes only cards whose realization it verified strong on disk. Two handoffs route to the run's terminal single-writer, the central Directory.Packages.props pin and the package ARCHITECTURE.md [02]-[SEAMS] row: folder agents report exact rows, one terminal writer applies them serially. Every writing stage also nominates generalizable lessons into a required-usually-empty harvest — each stage's rows ride its own return, the critique lane's swept from its fixlog on disk by the doctrine lander (nomination transport never rides a living fold); the terminal stage is a DRAIN LOOP over the pooled deferred backlog with every critique fixlog (the redteam fold-forward is lossy even when it lands) that also applies the central pins and ARCHITECTURE seam rows and re-feeds the still-open remainder under a round cap + no-shrinkage progress gate, then one doctrine lander adjudicates the pooled harvest with every critique fixlog harvest array from disk against the docs/laws admission bar (land-nothing legal) before the run closes. C#-only. args = a target path string, an array of target paths, or empty for the defaults.",
    phases: [
        {
            title: 'Realize',
            detail: 'all folder chains concurrent under one pooled cap: discover(recon lane; navigation-facts product to disk, thin receipt + structural skeleton on the wire) -> implement(reads the discovery report from disk, fans over discovery-proven page-disjoint card groups) -> critique(ONE codex lane, write lane; fixlog to disk, receipt on the wire) -> redteam(terminal close; reads the critique fixlog from disk as refutation targets and folds its surviving ripples/pins/seams/deferred rows into its own return); a folder with no open cards no-ops after its own discovery; every writing stage re-reads current disk, repairs page-level ripples in-pass, and reports central pin rows + ARCHITECTURE.md [02]-[SEAMS] rows for the terminal single-writer instead of editing those surfaces',
        },
        {
            title: 'Pins',
            detail: 'a terminal DRAIN LOOP: one serial single-writer per round applies every reported central Directory.Packages.props pin row at the symbol anchor and every reported ARCHITECTURE.md [02]-[SEAMS] row, drains every critique fixlog (the redteam fold-forward is lossy even when it lands) and the pooled deferred backlog against live disk, and re-feeds the still-open remainder under a round cap + no-shrinkage progress gate; then one doctrine lander adjudicates the pooled harvest nominations against the docs/laws admission bar (land-nothing legal). Runs only when pins, seams, orphans, backlog, or harvest exist',
            model: 'opus',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const CAP = 14;
const IMPL_FAN = 3; // max implement agents fanned per folder, and only over discovery-proven page-disjoint card groups
const DRAIN_ROUNDS = 4; // terminal drain fixpoint cap; the no-shrinkage progress gate (no remaining shrinkage -> stop) is the real bound
const ROOT = 'libs/csharp';
const ROOT_DIR = '/Users/bardiasamiee/Documents/99.Github/Rasm'; // absolute checkout root — the resolution anchor every native + codex lane pins
const SHARED_API = 'libs/csharp/.api';
const CENTRAL = 'Directory.Packages.props';
const DEFAULT_TARGETS = ['libs/csharp/Rasm.AppHost', 'libs/csharp/Rasm.Compute', 'libs/csharp/Rasm.AppUi', 'libs/csharp/Rasm.Persistence'];
const RETRY_ATTEMPTS = 2;

// --- [INPUTS] --------------------------------------------------------------------------

const norm = (t) => {
    const s = String(t).trim();
    return s.indexOf('libs/') === 0 ? s : ROOT + '/' + s;
};
const TARGETS_RAW = Array.isArray(args)
    ? args.filter(Boolean).map(norm)
    : args && typeof args === 'object' && Array.isArray(args.targets)
      ? args.targets.filter(Boolean).map(norm)
      : typeof args === 'string' && args.trim() && args.trim().toUpperCase() !== 'ALL'
        ? [norm(args)]
        : DEFAULT_TARGETS;
// C#-only route guard: a model/user-emitted target that does not resolve under libs/csharp would dispatch the C# pipeline over a
// foreign-language folder — validate the roster with a route predicate before any lane runs, dropping (and logging) off-route entries.
const onRoute = (t) => t.indexOf(ROOT + '/') === 0;
const TARGETS = [...new Set(TARGETS_RAW.filter(onRoute))];
const OFFROUTE = [...new Set(TARGETS_RAW.filter((t) => !onRoute(t)))];
const TARGET_NAMES = TARGETS.map((t) => '`' + (t.split('/').filter(Boolean).pop() || t) + '`').join(', ');
// Per-instance scratch dir for lane report files — minted deterministically from the resolved target set (clock/randomness would break
// resume): one FLAT dir under .claude/scratch/, a human-readable basename slug with an FNV-1a tail so distinct scopes never collide.
const fnv1a = (s) => {
    let h = 0x811c9dc5;
    for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193);
    return (h >>> 0).toString(16).padStart(8, '0').slice(0, 6);
};
const SCRATCH =
    '.claude/scratch/' +
    ('implement-cs-' + TARGETS.map((t) => t.split('/').pop().toLowerCase()).join('-')).replace(/[^a-z0-9.-]+/g, '-').slice(0, 60) +
    '-' +
    fnv1a(JSON.stringify(TARGETS));

// --- [MODELS] --------------------------------------------------------------------------

// One anchor = one fact at one coordinate; interpretation never lives in an anchor row.
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

const RIPPLE_ROWS = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['from_slug', 'klass', 'to_pkg', 'to_slug'],
        properties: {
            from_slug: { type: 'string' },
            klass: { type: 'string', enum: ['in_scope', 'oos_csharp', 'cross_lang'] },
            to_pkg: { type: 'string' },
            to_slug: { type: 'string' },
        },
    },
};
const GATE_ROWS = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['blocked_slug', 'gated_by_slug', 'in_scope'],
        properties: { blocked_slug: { type: 'string' }, gated_by_slug: { type: 'string' }, in_scope: { type: 'boolean' } },
    },
};
const MALFORMED_ROWS = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['from_slug', 'raw'],
        properties: { from_slug: { type: 'string' }, raw: { type: 'string' } },
    },
};

// Per-folder discovery PRODUCT — the lane's on-disk report, read IN FULL by the folder's
// implement/critique/redteam stages: `pages` per card are disk-verified Anchors targets proving
// page-disjoint implement groups; `malformed_ripples` is a required attestation (empty = none found).
const DISCOVERY = {
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
        ripples: RIPPLE_ROWS,
        gates: GATE_ROWS,
        map: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['page', 'files', 'anchors', 'members', 'composed', 'underutilized', 'seams', 'stacking'],
                properties: {
                    page: { type: 'string' },
                    files: { type: 'array', items: { type: 'string' } }, // files the implementer must open for this row
                    anchors: { type: 'array', items: ANCHOR }, // exact coordinates backing the row's facts
                    members: { type: 'array', items: { type: 'string' } }, // verified member spellings backing `underutilized`
                    composed: { type: 'string' },
                    underutilized: { type: 'string' },
                    seams: { type: 'string' },
                    stacking: { type: 'string' },
                },
            },
        },
        malformed_ripples: MALFORMED_ROWS,
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

// Thin wire receipt + the small structural skeleton the orchestrator's control flow runs on (empty
// no-op, fan proof, gate merges, ripple classes): theses, the navigation map, anchors, and coverage
// stay on disk at `report`; skeleton rows are jq-extracted from the product, never lane judgment.
const RECEIPT = {
    type: 'object',
    additionalProperties: false,
    required: ['ok', 'report', 'entries', 'headline', 'failure', 'folder', 'order', 'tasks', 'ideas', 'ripples', 'gates', 'malformed_ripples'],
    properties: {
        ok: { type: 'boolean' },
        report: { type: 'string' },
        entries: { type: 'integer' },
        headline: { type: 'string' },
        failure: { type: 'string' },
        folder: { type: 'string' },
        order: { type: 'array', items: { type: 'string' } },
        tasks: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['slug', 'status', 'atomic', 'pages'],
                properties: {
                    slug: { type: 'string' },
                    status: { type: 'string' },
                    atomic: { type: 'boolean' },
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
                required: ['slug', 'status', 'pages'],
                properties: { slug: { type: 'string' }, status: { type: 'string' }, pages: { type: 'array', items: { type: 'string' } } },
            },
        },
        ripples: RIPPLE_ROWS,
        gates: GATE_ROWS,
        malformed_ripples: MALFORMED_ROWS,
    },
};

// Thin wire receipt for the critique lane: its FIXLOG product stays on disk at `report`.
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

// The {slug, reason} row shape shared by every card-disposition list (deferred, reopened).
const SLUG_REASON = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['slug', 'reason'],
        properties: { slug: { type: 'string' }, reason: { type: 'string' } },
    },
};

// One writer/review fix-log core; the redteam is that core with the two card-status keys only it owns. logSchema(extra) composes
// them from ONE source so a field added to the core reaches every stage at once — never two literals drifting apart.
const LOG_CORE = {
    folder: { type: 'string' },
    verdict: { type: 'string', enum: ['realized', 'refined', 'clean'] },
    realized: { type: 'array', items: { type: 'string' } },
    deferred: SLUG_REASON,
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
    reopened: SLUG_REASON,
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
    ' (the `.api` catalogs, the `nuget` MCP for feed truth, and Context7/exa/tavily for the official surface own the fallback when assay is unavailable)';

const ROOT_LAW =
    'WORKING ROOT: ' +
    ROOT_DIR +
    ' — every relative repo path in this brief resolves against this absolute root; read, write, and edit ONLY under it, never another checkout of the repository.';

const LAW = [
    'Rasm monorepo, libs/csharp planning corpus (markdown specs of intended C# package designs). CLAUDE.md manifest + WORKSPACE_LAW strata govern ' +
        '(KERNEL -> AEC-DOMAIN -> APP-PLATFORM -> HOST-BOUNDARY -> APP; depend strictly upward; a host-neutral owner only where a non-Rhino runtime ' +
        'consumes the contract). The session targets are the libs/csharp packages ' +
        TARGET_NAMES +
        ', each on its canonical stratum; `Rasm.AppHost` ' +
        'is the host-neutral runtime spine `Compute`/`Persistence`/`AppUi` adapt to. Each target holds `IDEAS.md` + `TASKLOG.md` + ' +
        '`ARCHITECTURE.md` + `README.md` + `<pkg>.csproj` at the package ROOT, a deep `.api/api-*.md` capability catalog, and design pages at ' +
        '`<pkg>/.planning/<subdomain>/*.md`. Read the package-root `ARCHITECTURE.md` (sub-domain map + `[02]-[SEAMS]`), `README.md` (admitted-package ' +
        'roster), and `.api/` as the governing context and capability tier for that target. Cross-folder repair lands at seams, counterpart cards, and ' +
        'consumer sites — never by rebuilding a sibling owner interior.',
    'MANDATORY STANDARDS — docs/stacks/csharp/ is the FLOOR, not the ceiling: every fence MUST meet docs/stacks/csharp/ (README, language, shapes, ' +
        'surfaces-and-dispatch, rails-and-effects, boundaries, algorithms, system-apis) AND the specialized docs/stacks/csharp/domain/ shard(s) ' +
        'relevant to the page concern (compute, concurrency, data-interchange, diagnostics, durability, interaction, persistence, postgres, ' +
        'resilience, runtime, transport, validation, visuals), then PUSH PAST it to the objectively strongest form the doctrine admits. READ the ' +
        'relevant shard(s) and conform exactly — a hard gate enforced by the `tools/cs-analyzer` compiled-doctrine gate (a true positive is ' +
        'architecture pressure, fix the shape; a false positive is rule pressure, never a suppression). Cite only host/NuGet members confirmed via ' +
        '`UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api`' +
        FB +
        '; back bridge claims with EvidenceCertificate + reviewed ReferenceEvidence.',
    'This is IMPLEMENT, not an untied page rebuild: realize the folder SPECIFIC open IDEAS/TASKLOG cards into deep design-page FENCES. A FENCE is a ' +
        'markdown fenced code block inside a `.planning` design page — the work product itself, NEVER a `.cs`/`.py`/`.ts` source file. SCOPE per ' +
        'target: realize ALL open tasks (including `Atomic`-flagged minor tasks), then the 1-3 chosen open ideas, tasks first. Realize tied to the ' +
        'card charter (Capability/Shape/Unlocks/Anchors), mining every admitted package to full capability and crushing surface sprawl into fewer ' +
        'richer owners with zero functionality loss.',
    'WRITE-FULLY + FIX-IT-NOW: every fix you identify you MUST make NOW via Edit/Write directly in the file — the structured fix-log you return is a ' +
        'REPORT of edits ALREADY MADE, never a to-do list, a ledger, or a would/should-fix hedge. The writing is YOURS: never delegate authoring to ' +
        'another agent — a delegate may only fetch information. A cross-file ripple your edit exposes is YOURS in the ' +
        'same pass, wherever it lives: the seam counterpart on both ends, the consumer site, the stale sibling page, the 1-hop counterpart card fence ' +
        'in another libs/csharp package — repaired now and recorded in `ripples` (an empty `ripples` attests your pass exposed none, never that repair ' +
        "was skipped). TWO handoffs route to the run's terminal single-writer and are NEVER edited by a folder agent: the central `" +
        CENTRAL +
        '` ' +
        'pin (report the exact row in `pins`) and any package `ARCHITECTURE.md` `[02]-[SEAMS]` row (report {file, row} in `seams` — the ' +
        'highest-collision shared surface); every other page-level ripple stays yours, repaired distributed under the anchored-Edit discipline. If ' +
        'after real investigation a fence is already correct, say so — never invent edits to look busy.',
].join('\n');

const CARD = [
    'CARD SCHEMA: open cards live in `<pkg>/IDEAS.md` (ideas — larger conceptual capability) and `<pkg>/TASKLOG.md` (tasks — concrete targeted ' +
        'work), under section `[01]-[OPEN]`; closed cards collapse under `[02]-[CLOSED]`. A card is `[ID]-[STATUS]: <thesis>` then the bullets ' +
        '`Capability:` / `Shape:` / `Unlocks:` / `Anchors:` / `Tension:` (only when a constraint shapes it) / `Ripple:` (only on a cross-folder ' +
        'counterpart) / `Atomic:` (only on a minor task). Open statuses: `ACTIVE` (in-flight), `QUEUED` (next-up), `BLOCKED` (open but ' +
        'non-actionable). Closed: `COMPLETE` (finished) or `DROPPED` (abandoned). ALWAYS read the FULL card body (every bullet) from disk — the thesis ' +
        'alone is never enough to realize the charter.',
    'RIPPLE: `Ripple: <lang>:<pkg> [SLUG]` (or `<pkg> [SLUG]`) is a BIDIRECTIONAL cross-folder link — the counterpart card in the named pkg carries ' +
        'the mirror slug, and ripples are PART of scope, repaired in the pass that exposes them, never handed to a later stage. Three classes: ' +
        'IN-SCOPE (counterpart is another session target — its own pipeline realizes its card; you align your half of the seam to the counterpart ' +
        'page as it NOW stands on disk, and the later-landing side owns the final alignment), OUT-OF-SCOPE C# (counterpart in a non-target ' +
        "libs/csharp package — YOU realize the 1-hop counterpart card fence and align the seam on both ends in the same pass; the ripple's scope is " +
        "that counterpart card and its seam, not the foreign folder's other cards), CROSS-LANGUAGE / LIB-WIDE (`libs/.planning`, `libs/typescript`, " +
        "`libs/python` — outside this C#-only run's language rail; land your half stating the wire contract, and the card stays open unless it is " +
        'complete on your half alone).',
    'PROBE FREELY (nothing gates probing): EVERY agent in EVERY phase may — and should — probe to verify reality at any time, for ANY card or design ' +
        'decision, not only `[BLOCKED]` ones — `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api resolve|query` over host DLLs / NuGet to ' +
        'confirm any member or signature; Rhino WIP (never Rhino 8) via the rhino-mcp skill or tools/rhino-bridge for live host/GH behavior; ' +
        '`UV_CACHE_DIR=.cache/uv uv run python -m tools.assay ' +
        'provision check` (+ tools/assay/README.md) for a native/scientific/database/provisioning band. tools/assay is under concurrent construction: ' +
        'when an assay invocation fails, the probe obligation stands and reroutes — the `.api` catalogs, the `nuget` MCP for feed truth, ' +
        'Context7/exa/tavily for the official surface — and a blocker provable ONLY through downed assay is a legitimate out-of-run blocker, never a ' +
        'faked resolution. A `[BLOCKED]` card is REALIZED this turn whenever a probe resolves its blocker OR its gating work is in scope; a blocker ' +
        'is genuinely legitimate ONLY when it depends on work outside this run.',
    'PACKAGE ADMISSION (only when a card genuinely needs a not-yet-admitted package): do the folder-local parts NOW — add `<PackageReference ' +
        'Include="..."/>` WITHOUT a version to `<pkg>/<pkg>.csproj`, add the package to the correct group in `<pkg>/README.md`, and author ' +
        '`<pkg>/.api/api-<pkg>.md` from `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api`' +
        FB +
        '. The central repo-root `' +
        CENTRAL +
        '` has exactly ONE in-run ' +
        'writer: report the exact `<PackageVersion Include="..." Version="..."/>` row in `pins` and never edit that file yourself. Never a per-folder ' +
        'version manifest; never re-pin a version outside `' +
        CENTRAL +
        '`.',
    'CARD CLOSURE (the folder red-team ONLY — implement and critique NEVER change card status): a genuinely-complete card moves to its file ' +
        '`[02]-[CLOSED]` section as a collapsed one-liner `[ID]-[COMPLETE]: <one-line disposition>; Ripple: <pkg> [SLUG]` (or `[DROPPED]: <reason>`); ' +
        'report the owning `<pkg>/ARCHITECTURE.md` `[02]-[SEAMS]` row as {file, row} in `seams` ONLY when a real cross-folder seam landed (for a ' +
        "shared entry the owning-stratum folder's row wins — `Rasm.Persistence` owns durable-store seams, `Rasm.AppHost` owns host-neutral contract " +
        "seams); the run's terminal single-writer applies it, never you. A ripple-carrying card closes COMPLETE only when its seam is verified landed " +
        'on BOTH ends on current disk; close only `strong` cards and honestly re-open the rest.',
].join('\n');

const BARHUNT = [
    'BAR — a high-value IMPLEMENT leaves every owner capturing the FULL capability of every package it admits, every sprawl collapsed into one ' +
        'denser owner with NO capability lost, and every fence transcription-complete against the verified `.api`. The critique guards capability ' +
        'conservation, charter completeness, and density; the red-team attacks every fence for a surface that could still collapse, a thin wrapper, a ' +
        'silent functionality drop during a refactor, a missed package capability, or a framework violation, and fixes each in place.',
    'HUNT (at implement, critique, and red-team alike, from multiple facets): UNDER-CAPTURED CAPABILITY — an admitted package whose `.api` and code ' +
        'expose capability no owner exploits is a named gap, closed by deepening a fence or adding one. SURFACE SPRAWL — parallel ' +
        'types/enums/methods/near-duplicate shapes collapse into one parameterized owner in the C# collapse vocabulary ' +
        '(`[Union]`/`[SmartEnum<TKey>]`/`[ValueObject<T>]`/`[ComplexValueObject]`/source-generated case family/`Fold` algebra/frozen table) with no ' +
        'functionality removed. RAIL UNIFICATION — one entrypoint family per rail, one closed `Expected` fault family per package, total generated ' +
        '`Switch`. OPTIMIZATION — correctness first, then allocation/span/SoA layout/dispatch shape/algorithmic complexity, not only line-count. NEW ' +
        'WORK SURFACED — api gaps, stronger packages, and tasks the implementation exposes are realized the same turn (extend the canonical owner ' +
        'first, never a parallel surface).',
    'NAIVETY (two axes, both intolerable): COVERAGE — the owner models a thin slice of its concept (the obvious three fields where the domain ' +
        'carries fifteen; a two-case family for a twenty-case domain); APPROACH — enumerated hardcoded instances where a parameterized, algorithmic ' +
        'owner should generate the space (a fixed roster of styles/patterns/variants is seed DATA feeding one generator over named parameters, NEVER ' +
        'the mechanism itself). Every enumerated collapse-signal list in this prompt is a FLOOR, never the complete set: any repeated structure, ' +
        'parallel spelling, or enumerable family an algebra, table, fold, or generator can own is a collapse target you find yourself. A discovery ' +
        '`map` row in the worklist is an initial pointer, never a ceiling — re-read the pages in full and exceed it; a map never licenses a skim.',
].join('\n');

const ULTRA = [
    'OPERATIVE DOCTRINE — the 16 named laws of docs/stacks/csharp/README.md, held as fact: [FLOW] EXPRESSION_SPINE (domain logic is ' +
        'expression-shaped; dependent steps `Bind` monadically, independent ones accumulate applicatively; the carrier, never a flag, selects the ' +
        'algebra; statements survive only in measured `ref struct`/span kernels that name the exemption) + BOUNDARY_ADMISSION (raw admitted EXACTLY ' +
        'ONCE into an evidence-carrying owner; interior never re-validates or sees null/sentinel/provider shape). [SHAPE] SHAPE_BUDGET (one concept ' +
        'owns ONE type; variants are cases in one closed family) + DEEP_SURFACES + MODAL_ARITY (one entrypoint owns every modality, discriminating on ' +
        'input shape) + ANTICIPATORY_COLLAPSE (shape the owner for the family it will absorb). [DERIVATION] POLICY_VALUES + DERIVED_LOGIC + ' +
        'DERIVED_TYPES + SYMBOLIC_REFERENCE + SEMANTIC_NAMING. [MATERIAL] LIBRARY_DEPTH + DEFINITION_TIME_ASPECTS. [INTEGRATION] ROOT_REBUILD (weave ' +
        'new capability into the owner as if always present; no shims/aliases/[Obsolete]/migration layers) + ONE_HOP_RESOLUTION + ' +
        'COMPOSED_IMPLEMENTATION.',
    'ULTRA-ADVANCED COLLAPSE MANDATE: parallel types / sibling factory methods / repeated switch arms / single-call private helpers sharing an ' +
        'identity regime, an admission path, a payload timing, or a consumer COLLAPSE into ONE polymorphic owner IN THE SAME FILE via `[Union]` / ' +
        '`[Union<T1,...>]` ad-hoc / `[SmartEnum<TKey>]` / `[SmartEnum]` keyless / `[ValueObject<T>]` / `[ComplexValueObject]` / source-generated case ' +
        'families / `Fold` algebra / frozen data tables — a shape survives only on a genuinely distinct discriminant; never extract a new file to ' +
        'reduce LOC, never delete capability. Capability exits through FEW dense unified entry points — one polymorphic entry per rail discriminating ' +
        'on input shape (single|batch|stream absorbed by input detection, forward and inverse directions on one surface), variation living in input ' +
        'shape, policy values, and table rows, never parallel exports or modality-named siblings; the surface narrows by absorption, never by omission.',
    'LIFECYCLE SPINE (BOUNDARY_ADMISSION): every fence flows raw -> admit ONCE (generated factory + validation partial admits/rejects; one rail ' +
        'bridge lifts the generated outcome into `Fin<T>` / `Validation<Error,T>`; `Option<T>` carries absence; exceptions convert at the owning ' +
        'boundary only) -> canonical owner -> unified rail -> projection -> egress. Interior code never re-validates, never sees `null`-as-failure, ' +
        'sentinels, or provider shapes; parameterize BOTH ingress AND egress so the same owner sources and sinks across many consumers without ' +
        'interior edits.',
    'ULTRA-STACK CAPABILITY: BOTH `.api` tiers are enumerated IN FULL with a real listing from disk (`ls`/`fd`, never memory) and mined to operator ' +
        'depth — the shared substrate tier `' +
        SHARED_API +
        '/` (Thinktecture, MathNet, CSparse, QuikGraph, Mapperly, and the other cross-package ' +
        'catalogs) AND the folder tier `' +
        ROOT +
        '/<Package>/.api/` (the curated, integration-shaped domain surface) — with the universal ' +
        'Thinktecture (generated domain shape) / LanguageExt (rails, effects, schedules, immutable collections) rails and full docs/stacks/csharp ' +
        'doctrine, with MathNet / CSparse owning numeric algorithms. There is NO fixed package count: compose EVERY relevant host API + admitted NuGet ' +
        'package + catalog member into single dense owners woven as ONE rail (source-generated owners, `Fold` algebra, data tables), ALWAYS layering ' +
        'the universal Thinktecture/LanguageExt rails onto the domain packages, NOT flat one-shot per-API uses. Use the DEEPEST ' +
        'operator/combinator/generated surface each package itself reaches (LIBRARY_DEPTH); an admitted capability the concept admits but no owner ' +
        'exploits is a DEFECT you close, and a cited member you cannot verify via `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api`' +
        FB +
        ' is a PHANTOM you delete or ' +
        'correct, never leave standing; reject surface-level subsets, BCL-first reflexes, and thin rename wrappers.',
    'PRESERVE all capability (densify, never delete functionality): capability is improved or extended, NEVER dropped for lack of a current ' +
        'consumer — zero consumers never lowers the bar; planned consumers are real design pressure. Where a fence is already dense, deepen; where ' +
        'it is flat/naive, rebuild ground-up. Never regress correctness or boundary/strata law.',
].join('\n');

const PATLAW = [
    'C# PATTERN LAW: model the domain precisely — NEVER weak/unbounded/erased types where the language can express the domain; NEVER exception ' +
        'control flow in domain logic (use the LanguageExt typed rails / ROP and the route recovery patterns); NEVER imperative branching where a ' +
        'bounded vocabulary, frozen table, generated `Switch`, match, or `Fold` owns the variation; NEVER mutable accumulation for domain transforms ' +
        '(use immutable folds, projections, collection combinators). Total generated `Switch` with compile-time exhaustiveness (a new case breaks ' +
        'every dispatch site — NEVER a runtime-silent `_` arm). Typed algorithm receipts (NEVER a generic `IReceipt`/ledger) when fields carry ' +
        'route/status/sampling/solver/spectral/mesh/extraction/benchmark/host evidence. The fault type is a CLOSED `[Union]` family deriving from ' +
        '`Expected` (a bare exception or a generic untyped `Error` for a multi-cause domain is a defect).',
    'Latest stable C# 14 on `net10.0` to the metal (`Nullable enable`, NRT enforced): primary constructors, collection expressions with spread, ' +
        '`params` collections (incl. `params ReadOnlySpan<T>`), list/slice/relational/logical pattern matching, switch expressions, `required` ' +
        'members, `file`-scoped types, `field` accessors, extension blocks (`extension(Receiver)`) and extension operators, generic math / static ' +
        'abstract+virtual interface members, `with` expressions, `nameof` with unbound generics, `System.Threading.Lock`, raw string + `u8` literals ' +
        'where they fit. Treat analyzer diagnostics as architecture pressure (fix true positives, refine false positives, no ceremony suppressions). ' +
        'Apply the docs/stacks/csharp file-organization and section-order law (`[Union]`/`[SmartEnum]`/`[ValueObject]` and generated case families ' +
        'stay inside the declaring owner block; canonical section order TYPES -> CONSTANTS -> MODELS -> ERRORS -> SERVICES -> OPERATIONS -> ' +
        'COMPOSITION -> EXPORTS).',
    'Keep conventions IDENTICAL across every package; place each package on its canonical stratum and depend strictly upward; geometry/mesh/IFC meet ' +
        'at the wire with one owner per runtime; never leak a host type into a host-neutral owner. SEMANTIC_NAMING: one canonical bounded-context term ' +
        'per concept (one word default, three the ceiling); arity/filter/provider/modality live in request shape, case, or policy row, never parallel ' +
        '`Get`/`GetMany`/`GetBy<Key>`/`List`/`Search` names; ONE_HOP_RESOLUTION (no alias chains, forwarding helpers, or util shells).',
].join('\n');

const BOUNDARIES =
    'BOUNDARY LAW: keep every package owner strictly in its lane and on its stratum; geometry/mesh/IFC meet at the wire with one ' +
    'owner per runtime; internal code uses canonical names and shapes with mapping only at the edge; never introduce a downward dependency or leak ' +
    'a host type into a host-neutral owner. Cross-folder repair is seam-shaped: align counterparts, consumer sites, and counterpart cards — a ' +
    'concern owned twice across a runtime, a folder mixing unrelated concerns, or coupling to a sibling owner INTERIOR (vs its seam/wire) is a defect.';

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
    'BACKTICK ALL CODE: wrap every symbol, type, field, method, operator, package ID, path, command, flag, and literal value in backticks. Name the ' +
        'exact member/type/rail in backticks instead of paraphrasing behavior. Trimming prose MUST NOT reduce technical density or remove design content.',
].join('\n');

const COMMENTS =
    'COMMENT HYGIENE: code fences are agent-facing — comment for the next agent, never as a tutorial. KEEP the canonical ' +
    'section-divider headers (language-comment marker + space + `---` + bracketed `[UPPERCASE_LABEL]` + dash-fill). Beyond dividers, comment ONLY ' +
    'where intent is not already obvious from names, types, and signatures: default to ZERO comments on self-evident code; at most 1 line where a ' +
    'comment genuinely earns its place; 1-2 lines only for a truly subtle invariant, contract, or boundary. NO restating the code, no narration, no ' +
    'task/process/session/history/proof/review comments, no XML-doc bloat. Densify names and types so comments are rarely needed; cut every ' +
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
    '`absence` anchor names where the expected thing was searched and not found); `files` lists what the implementer must open for the row. ' +
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
// Bounded re-dispatch for a dead CRITICAL lane (usage-limit or transport death — the lane resolved null/!ok): attempt-counted with a
// retry sized to a limit reset, and the final death isolates the lane, NEVER the chain — every downstream
// stage still runs against current disk. `fn` returns the live product or null; a persisting null returns null to the caller.
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
        // write lanes author their own report (final act); the wrapper only verifies.
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
// The discovery lane routes here: a recon mapping lane — recon law, never fix —
// with a native-twin fallback on quota exhaustion. The row carries `scope` from the ORCHESTRATOR (never the
// lane's self-report) so a failed lane's territory is exact even when the lane died before writing anything.
const discoveryReceipt = (base) =>
    '(5) Read the product at the report path for the mechanical orchestration data. Return ok=true, report=' +
    base +
    '-report.json, entries=(tasks.length + ideas.length), headline="<entries> cards | <tasks.length>t+<ideas.length>i | ' +
    'ripples:<ripples.length> | gates:<gates.length> | map:<map.length>", failure empty, and copy folder, order, ' +
    'tasks[{slug,status,atomic,pages}], ideas[{slug,status,pages}], ripples, gates, and malformed_ripples verbatim from the product. On ' +
    'a failed receipt return ok=false, entries=0, report, headline, and folder empty, every structural array empty, and failure ' +
    'equal to the receipt reason and failure text VERBATIM.';
const discoveryTail = (report) =>
    '\n\nPRODUCT TO DISK: write your COMPLETE product as one JSON file matching this schema at ' +
    report +
    ' (Write tool, absolute path under the repo root): ' +
    JSON.stringify(DISCOVERY) +
    ' — then return ONLY the receipt + skeleton: ok, report path, entries = open card count, one-line ' +
    'mechanical headline, failure empty, and folder/order/tasks/ideas/ripples/gates/malformed_ripples transcribed from the ' +
    'product (task rows reduced to slug/status/atomic/pages, idea rows to slug/status/pages — theses, map, and coverage stay on disk).';
const recon = (task, o) => {
    const opts = { ...o, model: 'gpt-5.6-terra', writes: !!o.writes, receipt: discoveryReceipt, nativeTail: discoveryTail, wire: RECEIPT };
    return agent(codexPrompt(o.label, task, DISCOVERY, opts), {
        label: 'terra:' + o.label,
        phase: o.phase,
        model: 'sonnet',
        effort: 'low',
        schema: RECEIPT,
    })
        .then((r) => (r && !r.ok && /usage|quota|limit/i.test(r.failure || '') ? nativeLane(task, opts) : r))
        .then((r) => ({
            scope: o.scope || [],
            ok: !!(r && r.ok && r.report),
            report: (r && r.report) || '',
            entries: (r && r.entries) || 0,
            headline: (r && r.headline) || '',
            failure: (r && r.failure) || (r ? '' : 'lane died'),
            folder: (r && r.folder) || '',
            order: (r && r.order) || [],
            tasks: (r && r.tasks) || [],
            ideas: (r && r.ideas) || [],
            ripples: (r && r.ripples) || [],
            gates: (r && r.gates) || [],
            malformed_ripples: (r && r.malformed_ripples) || [],
        }));
};
const folderName = (p) => p.split('/').filter(Boolean).pop() || p;

// Critique lane: one blocking supervised Codex CLI process at the operator-default tier — a FIX lane
// (persistence + post-edit verification law), FIXLOG product to disk, thin receipt on the wire; a quota fallback restores
// the native twin writing the same product to the same path.
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
    const cards = [...(t.tasks || []), ...(t.ideas || [])].filter((c) => inOrder.has(c.slug));
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

const groupSeq = (t, g) =>
    JSON.stringify(
        {
            order: t.order.filter((x) => g.slugs.indexOf(x) >= 0),
            tasks: t.tasks.filter((c) => g.slugs.indexOf(c.slug) >= 0),
            ideas: t.ideas.filter((c) => g.slugs.indexOf(c.slug) >= 0),
            ripples: t.ripples.filter((r) => g.slugs.indexOf(r.from_slug) >= 0),
            gates: t.gates.filter((x) => g.slugs.indexOf(x.blocked_slug) >= 0),
            pages: g.pages, // the group's disjoint page set — the report's map rows for these pages are the group's own
        },
        null,
        1,
    );
const discoverPrompt = (folder) =>
    [
        LAW,
        '',
        CARD,
        '',
        INFO_LAW,
        '',
        'TASK: DISCOVER + SEQUENCE + MAP the open work of the single session target `' +
            folder +
            '` (the full session target set, for ripple ' +
            'classification only: ' +
            JSON.stringify(TARGETS) +
            "). DISCOVERY is the reconnaissance this folder's downstream chain stands on — " +
            'full reads, never skims, never memory. FIRST enumerate from the source of truth with a REAL listing ' +
            '(`ls`/`fd`, never recall): BOTH `.api` tiers (`' +
            SHARED_API +
            '/` and `' +
            folder +
            '/.api/`), the doctrine inventory ' +
            '(`docs/stacks/csharp/` core + `domain/` shards), and the target folder at large (`.planning/**` pages, `ARCHITECTURE.md`, `README.md`, the ' +
            'csproj). THEN read IN FULL: `' +
            folder +
            '/IDEAS.md` + `' +
            folder +
            '/TASKLOG.md` (every card body, every bullet — the thesis alone is ' +
            'never enough), every design page an open card names, and the folder at large (the remaining `.planning/**` pages with `ARCHITECTURE.md` + ' +
            '`README.md`) — seams, staleness, and unexploited capability hide in pages no card names. Resolve scope against real disk state: a named ' +
            'page, pkg, or slug you cannot find on disk is recorded (map row or malformed_ripples), never assumed. Return: (1) folder — echo ' +
            '`' +
            folder +
            '` exactly; (2) tasks — EVERY open card in `TASKLOG.md` (status ACTIVE/QUEUED/BLOCKED; carry the Atomic flag); (3) ideas — the ' +
            '1-3 MOST actionable open cards in `IDEAS.md` (tasks-first doctrine: pick at most 3, the ones whose Anchors are most settled and whose ' +
            'ripples land on in-scope targets), HARD CAP 3; on EVERY task/idea row also return pages — the repo-relative design pages under ' +
            '`' +
            folder +
            "/.planning/**` the card's `Anchors:` name and you VERIFIED exist on disk (empty when none verify): these rows prove " +
            'page-disjoint card groups; (4) order — ONE sequenced slug list, ALL tasks first in dependency order (a card whose Anchors reference another ' +
            'card output comes after it), then the chosen ideas; (5) ripples — for EVERY card carrying a `Ripple:` field, one row {from_slug, klass, ' +
            'to_pkg, to_slug}: klass=`in_scope` if to_pkg is one of the session targets, `oos_csharp` if it is another libs/csharp package, `cross_lang` ' +
            'if it points at `libs/.planning` / `libs/typescript` / `libs/python`; (6) gates — for any [BLOCKED] card, {blocked_slug, gated_by_slug, ' +
            'in_scope} where in_scope is true iff the gating work is itself an open card in one of the session targets (that card becomes actionable ' +
            'this run once its gate lands); (7) map — one row per design page the open cards target, AND one row per ripple-counterpart page ' +
            "(the design page a `Ripple:` row's counterpart card names in its own folder — read it and anchor its seam surface, so the writers " +
            'reach every counterpart hot instead of cold-hunting it): {page, files: every file (the page, its cited ' +
            "catalogs, its seam counterparts) the implementer must open for this row, anchors: exact coordinates backing the row's facts per the ROW " +
            'FORM law, members: the exact verified member spellings backing underutilized, each verified against its owning `.api` catalog (verified ' +
            'members ONLY — a member you cannot verify is a phantom and is NEVER listed; exact spellings and locations, never judgment wording), ' +
            'composed: the capability the page already composes, underutilized: catalog-anchored member FACTS the page does not yet compose, seams: the ' +
            'contextual cross-page/cross-folder seams the page meets, stacking: how the catalog capability stacks into the realization}. The map ' +
            'carries NAVIGATION FACTS — paths, verified member locations, seam targets — never verdicts; downstream agents treat it as an initial ' +
            'pointer, never a ceiling, and it licenses no skim; (8) coverage — the honesty ledger per the ROW FORM law. Also return malformed_ripples ' +
            'for any `Ripple:` line you cannot parse into a pkg+slug, or whose counterpart slug you cannot locate in the named pkg. Return the ' +
            'structured product ONLY; edit nothing.',
    ].join('\n');
const implementPrompt = (folder, seq, report, note, ownpass) =>
    [
        DOCTRINE,
        '',
        OWN_PASS(ownpass),
        '',
        'TASK: IMPLEMENT — realize the open cards of `' +
            folder +
            '` into deep design-page FENCES at the ULTRA bar. The sequenced worklist (slugs, ' +
            'ripple rows, gates; theses and the navigation map live in the discovery report on disk; read each FULL card body from ' +
            '`' +
            folder +
            '/IDEAS.md` + `' +
            folder +
            '/TASKLOG.md`, never the thesis alone):\n' +
            seq +
            '\nTHEN (ladder rung 2) READ the DISCOVERY REPORT at `' +
            report +
            '` IN FULL from disk — full card theses with the per-page navigation map ({page, files, anchors, members, composed, underutilized, ' +
            'seams, stacking}) and the lane `coverage`; its rows are FACTS with jump-coordinate anchors, never verdicts or ceilings — spot-verify what ' +
            'you build on, re-open every anchor behind an edit, hunt past the map on your own authority, and give any `skipped`/`unverified` coverage ' +
            'entry your own cold read. THEN READ: ' +
            'each card full body; every design page the card names under `' +
            folder +
            '/.planning/**`; the sibling pages it seams to, at their CURRENT ' +
            'on-disk state; the package-root `ARCHITECTURE.md` + `README.md`; docs/stacks/csharp/ core + the relevant domain/ shard(s) for the card ' +
            'concern; BOTH `.api` tiers in full — `' +
            SHARED_API +
            '/` + `' +
            folder +
            '/.api/api-*.md`, enumerated by real listing, never memory — with ' +
            'the admitted packages; and verify any novel host/NuGet member via `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api`' +
            FB +
            '. Realize EVERY card in `order` ' +
            '(all tasks incl. Atomic, then the ideas) into deep fences in the `' +
            folder +
            '` design pages, in LIFECYCLE order (admit raw ONCE through a ' +
            'generated factory + validation partial -> lift into the canonical owner the OWNER_CHOOSER discriminants select -> weave every cross-cutting ' +
            'concern as a definition-time source-generated aspect or composition-time effect transformer over a thin pure core -> compose through ONE ' +
            'unified `Fin`/`Validation`/`Option`/`Eff` rail with total generated `Switch` -> project + egress, BOTH ingress and egress parameterized). ' +
            'Collapse parallel shapes into one `[Union]`/`[SmartEnum<TKey>]`/`[ValueObject<T>]`/`[ComplexValueObject]`/source-generated case family in the ' +
            'SAME file; drive cases with a `Fold` algebra or a frozen table; one polymorphic entrypoint per modality. ' +
            'CAPABILITY-COMPLETENESS IS MANDATORY, NOT OPTIONAL: for every owner you author, the body implements what its names and ' +
            'prose promise — a named-but-omitted capability is a defect you close NOW, at the same bar as any bar finding, never a ' +
            'follow-up. Resolve any [BLOCKED] card inline ' +
            '(probe via `assay api`' +
            FB +
            ' / Forge band / Rhino WIP). RIPPLES ARE YOURS: repair every ripple your cards carry in this same pass per the ' +
            'RIPPLE law — align each in-scope seam to the counterpart page as it NOW stands on disk, realize each 1-hop out-of-scope C# counterpart card ' +
            'fence and align both ends, land your half of each cross-language seam stating the wire contract — and record each repair in `ripples`. ' +
            'PACKAGE ADMISSION per the card law: folder-local parts NOW, the central `' +
            CENTRAL +
            '` row reported in `pins`, never edited; a landed ' +
            "cross-folder seam's `ARCHITECTURE.md` `[02]-[SEAMS]` row reported in `seams`, never edited. Do NOT close any card — the folder red-team " +
            'owns card status. Modern C# 14 / net10 to the metal, high-signal prose all-backticked, comment hygiene, fix-in-place (read-then-extend, ' +
            'preserve capability). Return verdict + realized slugs + deferred (any card you could not realize, with reason) + collapsed (before->after ' +
            'counts) + ripples + pins + seams + harvest + summary. ' +
            HARVEST_LAW +
            (note ? '\n' + note : ''),
    ].join('\n');

// critiquePrompt feeds the codex critique lane (+ native twin): neutral stance — hostile register degrades
// codex, safe for the twin; the hostile pass is redteam (native).
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
            '\nThe discovery report at `' +
            report +
            '` carries ' +
            'the navigation map from disk — facts with anchors, never verdicts; consult it for verified members, seam targets, and coverage gaps, and ' +
            'it licenses no skim.\nREAD the realized pages, the sibling pages at their ' +
            'CURRENT on-disk state, docs/stacks/csharp/ core + the relevant domain/ shard(s), and BOTH `.api` tiers by real listing — `' +
            SHARED_API +
            '/` ' +
            'substrate + `' +
            folder +
            '/.api/` — with the universal Thinktecture/LanguageExt rails. Run these MECHANICAL checklists line-by-line as a ' +
            'FLOOR you hunt past, never the complete audit, and REPAIR every hit in place (a fix, never a ledger note):',
        '(1) COLLAPSE_SCAN — apply the move for any signal (shapes sharing an identity regime, an admission path, a payload timing, or a consumer ' +
            'collapse into ONE owner; a shape survives only on a genuinely distinct discriminant): sibling prefix/suffix names -> one modality-polymorphic ' +
            'entrypoint; same return rail differing only by arity -> input-shape discrimination; functions differing only by a literal -> parameterize the ' +
            'literal as a POLICY_VALUE; a `bool`/`mode`/`batch` parameter selecting two bodies -> one derived body or policy value; a method calling ' +
            'exactly one other -> delete the hop (ONE_HOP_RESOLUTION); parallel dispatch arms repeating structure -> a `Fold` algebra or frozen table ' +
            '(DERIVED_LOGIC); several types sharing fields for one concept -> one closed family; a `Get`/`GetMany`/`GetBy<Key>`/`List`/`Search` family -> ' +
            'one input-keyed polymorphic operation; a wrapper renaming a package API -> use the package surface directly (LIBRARY_DEPTH); parallel ' +
            'types / sibling factories / repeated switch arms / single-call helpers sharing an identity regime, admission path, payload timing, or ' +
            'consumer -> ONE `[Union]` / `[SmartEnum<TKey>]` / `[ValueObject<T>]` / ' +
            '`[ComplexValueObject]` / source-generated case family IN THE SAME FILE. These signals are a FLOOR, never the complete set — hunt past them.',
        '(2) OWNER_CHOOSER — for EVERY shape re-derive the owner from the 5 discriminants (admission, identity regime, variant arity, payload timing, ' +
            'openness), most-specific wins: invariant-bearing scalar -> `[ValueObject<TKey>]`; N-field one-concept product no discriminator -> ' +
            '`[ComplexValueObject]`; bounded vocabulary wire-keyed identity -> `[SmartEnum<TKey>]`; bounded vocabulary process-local behavior -> ' +
            '`[SmartEnum]` keyless; closed alternatives per-occurrence payload -> `[Union]`; one value over 2-5 unrelated types -> `[Union<T1,...>]` ' +
            'ad-hoc; interior product no invariant -> `record`/`readonly record struct`; combinable capability set -> a frozen set; cross-product/external ' +
            'policy key -> a frozen table; foreign wire enum / ABI bits / kernel ordinal -> a language `enum` AT THE SEAM ONLY. Kill every parallel DTO, ' +
            'one-field wrapper, field-rename shape, nullable-as-failure, and struct-`default` ghost.',
        '(3) KNOB_TEST — removal: delete each parameter; if the value reconstructs what it carried it was a knob -> collapse a ' +
            '`bool`/`mode`/`strict`/`batch` flag into a policy value or input-shape discriminant; a nullable flag tail -> one `Option<ContextRecord>`; the ' +
            'single optional form is `Option<T> x = default` consumed via `IfNone(canonical)`; move every `timeout`/`retry`/`deadline`/`CancellationToken` ' +
            'OFF the signature onto the carrier or a composition-time effect aspect.',
        '(4) ASPECTS — definition-time concerns (admission, identity, dispatch, serialization, grammar, logging) attach via attribute-directed SOURCE ' +
            'GENERATION in the fixed generator order; composition-time concerns attach as effect transformers in author order — retry as `Schedule`-driven ' +
            '`IO<T>.Retry(Schedule)`/`Prelude.retry`, recovery as named catch combinators (`@catch`/`catchOf`/`CatchM` composed via `|`), resource ' +
            'lifetime as `Bracket`/`BracketIO`/`Finally`; the two weaves meet at EXACTLY ONE seam, the admission rail bridge. Co-occurring wrappers ' +
            'sharing an admission path collapse into ONE aspect; an aspect NEVER raises into domain flow; deterministic stacking order verified. ' +
            'Inline-repeated concerns and sibling helper methods are defects.',
        '(5) RAILS — RAIL_CHOOSER, the narrowest carrier chosen ONCE at admission: `Option<T>` absence, `Fin<T>` synchronous fallibility, ' +
            '`Validation<Error,T>` independent accumulated faults, `Eff<RT,T>` runtime capability, `IO<T>` deferred boundary work, `Schedule` retry ' +
            'policy, `Seq<T>`/`Arr<T>`/`HashMap<K,V>` immutable traversal/lookup; the fault type is a CLOSED `[Union]` family deriving from `Expected` (a ' +
            'bare exception or generic untyped `Error` for a multi-cause domain is a defect; recovery identity via `Is`/`HasCode`/`IsType<E>`, never ' +
            '`==`); accumulate-vs-abort disposition correct (`Apply`/`&`/`.Traverse` for independents, `Bind`/`.TraverseM`/query for dependents); total ' +
            'generated `Switch` (NO `_` arm hiding a case); `.Fold`/`.Traverse`/`.Choose` with the mandatory `.As()` re-anchor; NO exception control flow ' +
            'in domain logic, NO mutable accumulation.',
        '(6) STRATA/MEMBERS/MODERN — strata correctness (depend strictly upward; NO downward dependency, NO host-type leak into a host-neutral owner; ' +
            'geometry/mesh/IFC meet at the wire with one owner per runtime); cite ONLY host/NuGet members confirmed in a `.api` catalog (verify novel ' +
            'members via `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api`' +
            FB +
            '; an unverifiable cited member is a PHANTOM — delete or correct it); latest modern C# 14 on ' +
            'net10 (primary ctors, collection expressions, `params` collections, list/relational/logical patterns, switch expressions, `required` ' +
            'members, `file` types, `field` accessors, extension blocks, generic math, static abstract members); FULL docs/stacks/csharp + the relevant ' +
            'domain/ shard conformance; BOTH `.api` tiers (`' +
            SHARED_API +
            '/` substrate + the folder catalogs) AND the universal Thinktecture/LanguageExt ' +
            'rails maximized to operator depth; the `tools/cs-analyzer` doctrine-gate clean.',
        '(7) CHARTER-COMPLETENESS — for EVERY card in the worklist, verify the realized fences GENUINELY fulfill its `Capability`/`Shape`/`Unlocks` ' +
            '(read the full card from disk): a missing modality, an unrealized `Shape` clause, a stubbed/placeholder fence, or a capability the card ' +
            'promises but the fences do not deliver is a DEFECT — realize it NOW. A card whose fences are thin against its charter is not done. Attack ' +
            'BOTH naivety axes per card: COVERAGE — fences modeling a thin slice of the domain the charter names — widen to the full concept; APPROACH — ' +
            'an enumerated roster of hardcoded instances where ONE parameterized generator should own the space — demote the roster to seed data feeding ' +
            'that generator.',
        '(8) SEAMS — check every cross-page and cross-folder symbol these cards compose against the counterpart as it NOW stands on disk: a signature ' +
            'mismatch corrects at the weaker end, a conflict resolves to the stronger form, never a revert; a seam counterpart or consumer site your fix ' +
            'exposes is repaired in this same pass wherever it lives, recorded in `ripples` (a package `ARCHITECTURE.md` `[02]-[SEAMS]` row change is ' +
            'reported in `seams` for the terminal single-writer, never edited directly).',
        'Also enforce the docs/stacks/csharp file-organization + section-order law, cross-package convention consistency, and prose + comment hygiene. ' +
            'FIX every hit NOW wherever it lives per WRITE-FULLY; report any central `' +
            CENTRAL +
            '` row in `pins`. Return verdict + realized + deferred ' +
            '+ collapsed + ripples + pins + seams + harvest + summary. ' +
            HARVEST_LAW,
    ].join('\n');

const redteamPrompt = (folder, seq, report, critReport, critOk, ownpass) =>
    [
        DOCTRINE,
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
            'PRIOR CLAIMS (UNVERIFIED): the critique fixlog is ON DISK at `' +
            critReport +
            '`' +
            (critOk
                ? ''
                : ' (its wrapper receipt died, but the lane writes the fixlog before any ceiling can kill the call — the path is DETERMINISTIC, so ' +
                  'check it FIRST; absent or unparseable on disk, your cold attack is the only review this folder gets, judged from CURRENT disk alone)') +
            ' — read it IN FULL from disk; its edits and verdicts are refutation targets you judge against CURRENT disk, never a settled record. ' +
            'FOLD-FORWARD DUTY: its surviving `ripples`, `pins`, `seams`, and `deferred` rows are folded into YOUR return (re-verified ' +
            "against current disk, deduped) — your return is the folder's consolidated record. Its `harvest` rows are NOT yours to fold: the doctrine " +
            'lander sweeps every critique fixlog from disk directly — nomination transport never rides a living fold.' +
            '\nThe discovery report at `' +
            report +
            '` carries the navigation ' +
            'map from disk — facts with anchors, never verdicts; consult it for verified members, seam targets, and coverage gaps, and it licenses no ' +
            'skim.\nREAD BOTH `.api` tiers by real listing — `' +
            SHARED_API +
            '/` ' +
            'substrate + `' +
            folder +
            '/.api/` — with the universal Thinktecture/LanguageExt rails, the sibling pages at their CURRENT on-disk state, ' +
            'docs/stacks/csharp/ + the relevant domain/ shard. Attack from every direction and REPAIR every defect in place — no soft-pedalling, no ' +
            'could/should, a fix never a ledger.',
        'PRIMARY LENS — fundamental design, multi-faceted: (A) COUNTERFACTUAL on the core owner/algebra/dispatch — a counterfactual ' +
            'REBUILDS the design with its central assumption removed, never merely questions it: name the assumption the current shape ' +
            'stands on (the chosen owner kind, the hand-enumerated space, the call-site dispatch, the hand-rolled kernel), derive the ' +
            'form the fence takes WITHOUT it — a denser owner ' +
            '(`[Union]`/`[SmartEnum<TKey>]`/`[ValueObject<T>]`/`[ComplexValueObject]`/source-generated family), a data table, or a DEEPER ' +
            'admitted-package primitive (LanguageExt/Thinktecture/MathNet/CSparse) — and where the rebuilt form is stronger, BUILD IT IN ' +
            'PLACE; a stronger design once seen is never defended against, and "the current shape also works" is not a refutation. An ' +
            'enumerated roster of hardcoded variants where a parameterized generator should own the space is an APPROACH defect — demote ' +
            'the roster to seed data feeding ONE generator. (B) ANTICIPATORY_COLLAPSE — compute the DIFF OF THE NEXT FEATURE: when the next ' +
            'case/dimension/knob/modality/provider arrives, does it land as ONE case/row/policy value with every consumer untouched or broken LOUDLY at ' +
            'compile time (total generated `Switch`, no silent `_`)? If it would touch multiple sites, reshape so the growth axis is a case, row, policy ' +
            'value, or carrier swap. (C) LONG-TAIL + DOMAIN COMPLETENESS — attack every input/output/edge/failure mode (empty, singular, plural, stream, ' +
            'malformed, concurrent, cancelled, partial-failure, version-skew); COVERAGE naivety — an owner modeling the obvious thin slice of its concept ' +
            'where the domain carries far more — is a defect: widen to the full concept; is the accumulate-vs-abort disposition correct for the REAL boundary; ' +
            'are BOTH ingress AND egress parameterized so this owner sources and sinks across hundreds of consumers without interior edits? (D) STRATA + ' +
            'BOUNDARY-INTEGRITY — a downward dependency, a host-type leak into a host-neutral owner, a concern owned twice in a runtime, a folder mixing ' +
            'concerns, geometry/mesh/IFC not meeting at ONE wire owner per runtime, coupling to a sibling owner INTERIOR (vs its seam/wire), OR a sibling ' +
            'planning page left STALE by this folder change even when no ripple card names it (ports/boundaries/wires/seams drift) is a defect: fix it ' +
            'NOW wherever it lives — the stale sibling page, the seam counterpart, the consumer site — and record the repair in `ripples` (a package ' +
            '`ARCHITECTURE.md` `[02]-[SEAMS]` row change is reported in `seams` for the terminal single-writer, never edited directly). (E) ' +
            'SURFACE-SPRAWL-IN-TIME — an admitted package whose `.api` or the universal rails expose capability the fence re-derives by hand, flat code ' +
            'below the operator depth the packages reach, a phantom `.api`/host member, or a thin wrapper: collapse to package depth, verify every cited ' +
            'member (via `assay api`' +
            FB +
            '), and DELETE or correct every phantom.',
        'ALSO — FULL COLD ADVERSARIAL RE-REVIEW (every time, NOT only on a structural restructure): re-attack every conformance dimension with fresh ' +
            'hostile eyes, trusting nothing the prior passes claimed — the COLLAPSE_SCAN signals, OWNER_CHOOSER per shape, the KNOB_TEST per param, the ' +
            'two-weave ASPECT taxonomy, rail + closed-`Expected`-fault discipline, charter-completeness per card, strata correctness, modern-C# 14 typing, ' +
            'docs/stacks/csharp + domain-shard conformance, `.api` + Thinktecture/LanguageExt maximization, the `tools/cs-analyzer` doctrine-gate, and ' +
            'prose/comment hygiene — and fix every defect. Even absent a structural rebuild, the fences must end objectively denser, more correct, and ' +
            'more powerful than the critique left them; if the strongest form is genuinely already present, prove it by finding nothing — never invent ' +
            'churn.',
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
        ROOT_LAW,
        round
            ? 'DRAIN ROUND ' +
              round +
              ' — the backlog rows below were verified STILL-OPEN by the prior round; fix each at its root NOW, and a row you genuinely cannot ' +
              'land carries its named blocker and owner in `remaining`. Every other tranche re-arrives in full so a dead or partial prior round ' +
              'loses nothing — the checkpoint ledger is the consumption truth: skip every tranche it receipts, drain the rest.'
            : '',
        LAW,
        '',
        PROSE,
        '',
        'CHECKPOINT LEDGER: `' +
            SCRATCH +
            '/pins-checkpoint.md` — read it FIRST and skip every tranche it already receipts (an interrupted drain re-enters, never restarts); ' +
            'append one line per tranche AS EACH COMPLETES (the pin applies, the seam-row applies, each critique fixlog drained, the backlog block). ' +
            'HARVEST FILE: append each `harvest` nomination to `' +
            SCRATCH +
            '/pins-harvest.jsonl` (one JSON row per line) the moment it is minted — the doctrine lander sweeps the file, so a killed round loses no ' +
            'nomination; your returned `harvest` carries the same rows.',
        "TASK: TERMINAL SINGLE-WRITER + BACKLOG DRAIN — you are the run's SOLE writer for the repo-root `" +
            CENTRAL +
            '` and for every package `ARCHITECTURE.md` `[02]-[SEAMS]` section, and its LAST agent. TRANCHE ORDER IS EXECUTION ORDER — apply the ' +
            'prerequisite pins (1) and seam rows (2) before draining the capability backlog (4), since a deferred card may need a pin landed first; ' +
            'never demote the backlog behind mechanical dedupe beyond that genuine dependency.\n' +
            [
                pins.length
                    ? '(1) PINS: apply each reported row exactly once — hand-edit the grouped manifest at the SYMBOL anchor (never a line number), ' +
                      'preserving label-group and alphabetical order, deduping semantically identical rows; verify each package + version via the ' +
                      '`nuget` MCP or `UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api`' +
                      FB +
                      ' before applying; confirm the owning `<pkg>.csproj` carries the versionless `<PackageReference/>` and the folder README/.api ' +
                      'rows landed, repairing a missing folder-local part in place: ' +
                      JSON.stringify(pins, null, 1) +
                      '.'
                    : '',
                seams.length
                    ? "(2) SEAM ROWS: upsert each reported {file, row} into the named file's `[02]-[SEAMS]` section exactly once, preserving the " +
                      "section's row format and order and deduping semantically identical rows; a missing file or absent `[02]-[SEAMS]` section " +
                      'rejects the row: ' +
                      JSON.stringify(seams, null, 1) +
                      '.'
                    : '',
                orphans.length
                    ? '(3) CRITIQUE FIXLOGS — every critique fixlog on disk (the redteam fold-forward is lossy transport even when it lands); the ' +
                      'paths are deterministic, so one absent on disk is skipped with a one-line note in `summary`, never an error — read each present ' +
                      'file IN FULL and apply its pin and seam rows under the same law as the reported rows above (a row a live redteam already landed ' +
                      "disk-resolves and drops). Its `harvest` rows are the doctrine lander's to sweep, never yours to fold: " +
                      JSON.stringify(orphans) +
                      '.'
                    : '',
                backlog.length
                    ? '(4) BACKLOG DRAIN (deferred cards the folder chains could not realize — the capability tranche: re-verify each {files, claim} ' +
                      'on CURRENT disk, realize any whose gate landed this run in a sibling folder now that every chain has closed, reject what disk ' +
                      'already resolved): ' +
                      JSON.stringify(backlog, null, 1) +
                      '.'
                    : '',
                'Reject any unverifiable or malformed row as {target, reason} — never apply it silently. Return applied + seam_rows_applied + rejected ' +
                    '+ summary, and `remaining` carrying ONLY backlog rows verified still-open on current disk and genuinely blocked, each claim naming ' +
                    'its blocker and owner; a row disk already resolved is culled with proof in `rejected`, and an empty `remaining` attests the drain ' +
                    'closed. ' +
                    HARVEST_LAW,
            ]
                .filter(Boolean)
                .join('\n'),
    ]
        .filter(Boolean)
        .join('\n');

const doctrinePrompt = (rows, orphans) =>
    ROOT_LAW +
    '\n\nTASK: DOCTRINE LANDER — the durable-learning terminal of this run. Read `docs/laws/README.md` FIRST — it ' +
    'owns the corpus admission and page-shape law; obey it over any restatement. Load the `docgen` skill via ' +
    'the Skill tool BEFORE any durable edit; ' +
    'load `mermaid-diagramming` before touching any diagram. ' +
    "NOMINATIONS (unverified, biased toward their authors' own work — refute by default): " +
    JSON.stringify(rows) +
    '\nAlso sweep `' +
    SCRATCH +
    '/pins-harvest.jsonl` (absent = none): rows there missing from NOMINATIONS are nominations too — a killed terminal drain round reaches ' +
    'you only through that file.' +
    '\nAlso read the `harvest` array of every critique fixlog at these deterministic paths (an absent or invalid file skips; no other agent ' +
    'transports these rows): ' +
    JSON.stringify(orphans) +
    ' — dedupe them against NOMINATIONS and adjudicate them identically.' +
    '\nADJUDICATE each row per the admission bar: cold-read its target surface IN FULL, verify its anchors on CURRENT disk; LAND NOTHING is a ' +
    'first-class verdict.\nTOPOLOGY RE-PROOF: re-verify every `docs/laws/topology.md` row whose [SURFACE] this run touched — cull a row whose ' +
    'coupling no longer holds, land a coupling this run proved.\nGATE: run `uv run .claude/skills/docgen/scripts/prose_gate.py <every touched ' +
    '.md>` and repair to zero FAILs before returning. Return landed/refined/rejected (each rejection with its reason)/files/summary.';

// --- [COMPOSITION] ---------------------------------------------------------------------

if (OFFROUTE.length) log('Dropped off-route target(s) — this run is C#-only (libs/csharp): ' + OFFROUTE.join(', '));
if (!TARGETS.length)
    return {
        root: ROOT,
        targets: [],
        note: 'no libs/csharp targets — pass a libs/csharp package path, an array, or empty for the defaults',
        offroute: OFFROUTE,
    };

phase('Realize');
log('Pooling ' + TARGETS.length + ' folder chain(s) at CAP=' + CAP);
const runFolder = async (target) => {
    const tag = folderName(target);
    try {
        // Discovery severs the WHOLE folder chain on death (no worklist, no downstream): bounded re-dispatch with a retry before
        // the isolation verdict. recon() always resolves an object, so the retry gates on `.ok`, not truthiness.
        let t = await recon(discoverPrompt(target), { label: 'discover:' + tag, phase: 'Realize', scope: [target] });
        if (!t.ok) {
            const rt = await retryLane(async () => {
                const r = await recon(discoverPrompt(target), { label: 'discover:' + tag + ':a1', phase: 'Realize', scope: [target] });
                return r && r.ok ? r : null;
            });
            if (rt) t = rt;
        }
        // A failed lane is {ok:false, failure:<stderr tail>} — the chain isolates on `ok`, never on a sentinel payload.
        if (!t.ok) return { folder: target, failed: true, empty: false, logs: [], red: null, cross_lang: [], malformed: [], error: t.failure };
        const report = t.report;
        const cross = t.ripples
            .filter((rp) => rp.klass === 'cross_lang')
            .map((rp) => tag + ' [' + rp.from_slug + '] -> ' + rp.to_pkg + ' [' + rp.to_slug + ']');
        const malformed = t.malformed_ripples;
        if (!(t.tasks.length || t.ideas.length))
            return { folder: target, failed: false, empty: true, logs: [], red: null, cross_lang: cross, malformed };
        const seq = JSON.stringify({ order: t.order, tasks: t.tasks, ideas: t.ideas, ripples: t.ripples, gates: t.gates }, null, 1);
        const groups = cardGroups(t);
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
                        // Each page-disjoint group is landed work: a dead group earns the bounded retry before it is lost.
                        const fire = (suffix) =>
                            agent(implementPrompt(target, groupSeq(t, g), report, GROUPNOTE, SCRATCH + '/ownpass-impl-' + tag + '-g' + gi + '.md'), {
                                label: 'implement:' + tag + ':g' + gi + suffix,
                                phase: 'Realize',
                                schema: FIXLOG_SCHEMA,
                                model: 'fable',
                                effort: 'high',
                            });
                        return (await fire('')) || (await retryLane(() => fire(':r1')));
                    }),
                )
            ).filter(Boolean);
        } else {
            const fire = (suffix) =>
                agent(implementPrompt(target, seq, report, '', SCRATCH + '/ownpass-impl-' + tag + '.md'), {
                    label: 'implement:' + tag + suffix,
                    phase: 'Realize',
                    schema: FIXLOG_SCHEMA,
                    model: 'fable',
                    effort: 'high',
                });
            const one = (await fire('')) || (await retryLane(() => fire(':r1')));
            impls = one ? [one] : [];
        }
        // CHAIN CONTINUATION: a dead implement never severs the reviews — the critique's conformance audit and the redteam's
        // pre-mortem (both fix-in-place) still improve the pages as they stand on disk, and the redteam is the folder's SOLE
        // card-status owner; navigation simply arrives empty and the reviews realize the unrealized cards themselves.
        if (!impls.length) log(tag + ': implement produced nothing after retries — critique + redteam run against current disk');
        // Critique: fixlog to disk, receipt on the wire; the redteam folds its rows forward, but that fold is lossy transport,
        // so every critique fixlog is also swept by the terminal single-writer, re-verified against disk (a landed row drops). The
        // critique report path is DETERMINISTIC — the critique lane writes the fixlog before its wrapper ceiling can kill the call, so a
        // dead receipt never severs the fold: downstream consumers check the path on disk, never trust `ok`.
        const critReport = SCRATCH + '/' + fileTag('critique:' + tag) + '-report.json';
        const crit = await solLane(critiquePrompt(target, seq, report, SCRATCH + '/ownpass-crit-' + tag + '.md'), {
            label: 'critique:' + tag,
            phase: 'Realize',
        });
        // Terminal close + sole card-status owner: a dead redteam loses every close for the folder, so it earns the retry.
        const rfire = (suffix) =>
            agent(redteamPrompt(target, seq, report, critReport, crit.ok, SCRATCH + '/ownpass-rt-' + tag + '.md'), {
                label: 'redteam:' + tag + suffix,
                phase: 'Realize',
                schema: REDTEAM_SCHEMA,
                model: 'fable',
                effort: 'high',
            });
        const red = (await rfire('')) || (await retryLane(() => rfire(':r1')));
        return {
            folder: target,
            failed: false,
            empty: false,
            impl_failed: !impls.length,
            logs: [...impls, red].filter(Boolean),
            red,
            critReport,
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
const implFailed = active.filter((r) => r.impl_failed).map((r) => r.folder); // implement died but the reviews ran against current disk
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
        (implFailed.length ? '; implement-dead (reviews ran): ' + implFailed.join(', ') : '') +
        (failed.length ? '; failed: ' + failed.join(', ') : ''),
);

// --- [PINS]

// EVERY critique fixlog on disk (not only orphaned ones): the redteam fold-forward is lossy even when it lands, so the
// terminal single-writer re-verifies each against current disk and drops what a live fold already landed.
const ORPHANS = done.map((r) => r.critReport || '').filter(Boolean);
// The deferred cards a folder chain could not realize become the drain backlog in {files, claim} form.
const BACKLOG = deferred.map((d) => ({ files: [], claim: d.folder + ' [' + d.slug + ']: ' + d.reason }));
// Terminal DRAIN LOOP: one serial single-writer per round. Every round re-receives the FULL tranche set — the reported pins,
// seam rows, and every critique fixlog re-arrive each round, gated by the disk CHECKPOINT LEDGER (receipted tranches skip, the rest
// drain), so a dead or partial round starves nothing; only the deferred backlog narrows via `remaining`. The terminal writer earns
// the retry (its death would lose the pin/seam applies), a round cap and a no-shrinkage gate bound the loop, and the
// blocked remainder rides the run return.
let pinlog = null;
let pinHarvest = [];
let residuals = BACKLOG;
let lastOpen = Infinity;
const DRAIN_RAN = !!(pinsReported.length || seamsReported.length || ORPHANS.length || BACKLOG.length);
if (DRAIN_RAN) {
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
        if (!pinlog) break; // dead round after retries: the residual set survives to the run return; every disk tranche stays checkpoint-re-enterable
        pinHarvest = pinHarvest.concat(pinlog.harvest || []);
        const open = pinlog.remaining || [];
        residuals = open;
        if (!open.length || open.length >= lastOpen) break;
        lastOpen = open.length;
    }
}
// DOCTRINE LANDER: the run's durable-learning terminal — pooled harvest nominations adjudicated against the live docs/laws
// surfaces; refutation-first, land-nothing legal, admission law owned by docs/laws. A dead terminal drain (its harvest reaches
// the lander only through the pins-harvest.jsonl the prompt sweeps) still fires it, and critique fixlogs on disk fire it too —
// the lander is those arrays' ONLY transport, so a zero-wire-nomination run with a live fixer still lands critique nominations.
const HARVEST_ROWS = done.flatMap((r) => r.logs.flatMap((l) => l.harvest || [])).concat(pinHarvest);
let doctrine = null;
if (HARVEST_ROWS.length || ORPHANS.length || (DRAIN_RAN && !pinlog)) {
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
    implement_failed: implFailed,
    realize_failed: failed,
    offroute: OFFROUTE,
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
