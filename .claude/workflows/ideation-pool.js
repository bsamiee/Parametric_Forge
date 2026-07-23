export const meta = {
    name: 'ideation-pool',
    description:
        'Build the four-altitude IDEAS/TASKLOG card estate to the depth slice-implement.js ingests: a disk-derived folder roster plus a git-history admitted-package roster, one codex sol dossier per folder/branch/cross tier, one fable card writer per folder streaming off its own dossier (typed per-axis verdicts make thin output a visible lane failure), a per-language fable landing same-branch ripple counterparts, dedup, and the language-root pair, one cross-libs fable landing cross-language ripples both ends plus the coherence pass, streaming single-writer package admissions per central manifest, and a terminal audit proving no-silent-drops, decomposition, per-folder verdicts, and docgen-zero. args = {camp: absolute campaign home (required), scope?: folder subset, base?: pre-campaign commit-ish}; products land under camp/ideation/.',
    whenToUse: 'After an implementation campaign empties the OPEN pools, to rebuild card depth before the next slice-implement run',
    phases: [
        { title: 'Roster', detail: 'folder roster with open-card counts from disk; git-history admitted-package roster via a read-only sol lane' },
        {
            title: 'Map',
            detail: 'per-folder, per-branch, and cross-libs codex sol dossiers (pages, cards, two-tier .api mining, axis gaps, strata) and one opus adjacent-package research lane per branch',
        },
        {
            title: 'Ideate',
            detail: 'one fable card writer per folder off its own dossier: goal template answered axis by axis, ideas decomposed',
            model: 'fable',
        },
        {
            title: 'Language',
            detail: 'per-branch fable: ripple counterparts landed, cross-folder dedup, language-root pair, structural breadth',
            model: 'fable',
        },
        {
            title: 'Cross',
            detail: 'one fable: libs/.planning pair, cross-language ripples both ends, coherence over all four altitudes',
            model: 'fable',
        },
        { title: 'Admit', detail: 'full admission chain per collected package need, deduped, single-writer per central manifest' },
        {
            title: 'Audit',
            detail: 'mandate [08] proof: roster exploitation, idea decomposition, per-folder pool verdicts, docgen-zero, leader compat',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const REPO = '/Users/bardiasamiee/Documents/99.Github/Rasm';
const CAP = 14;
const SHORT = { csharp: 'cs', python: 'py', typescript: 'ts', cross: 'x' };
const LANGS = [
    { key: 'csharp', root: 'libs/csharp', manifest: 'Directory.Packages.props', registry: 'nuget' },
    { key: 'python', root: 'libs/python', manifest: 'pyproject.toml', registry: 'pypi' },
    { key: 'typescript', root: 'libs/typescript', manifest: 'pnpm-workspace.yaml', registry: 'npm' },
];
// Engine-neutral depth/ambition axes — the HOW-DEEP dimensions every folder answers regardless of capability family.
const DEPTH_AXES = [
    'coverage-depth', // does the owner model the full concept or a thin slice
    'approach-genericity', // parameterized generator vs enumerated hardcoded instances
    'api-folder', // folder-tier .api capability stacked to operator depth
    'api-branch', // branch-tier .api substrate stacked to operator depth
    'strata-leverage', // lower-stratum owners composed vs re-derived
    'cross-language', // wire counterpart carried vs missing
    'ecosystem-reach', // admitted-package capability made newly possible
    'reference-gap', // distance to the real-world reference systems for the domain
    'structural', // new page / sub-folder / stub the folder demands
];
// Theme axes come from the mandate, never the engine: the mandate [03] goal template names the capability-family axes.
const AXES = DEPTH_AXES;

// --- [INPUTS] --------------------------------------------------------------------------

// Tool-boundary normalization: the Workflow tool's untyped args input can deliver a JSON-encoded string.
const ARGS = (() => {
    if (typeof args === 'string') {
        try {
            return JSON.parse(args) || {};
        } catch {
            return {};
        }
    }
    return args && typeof args === 'object' ? args : {};
})();
const CAMP = typeof ARGS.camp === 'string' && ARGS.camp.trim() ? ARGS.camp.trim().replace(/\/+$/, '') : '';
const SCOPE = Array.isArray(ARGS.scope)
    ? ARGS.scope.filter(Boolean).map(String)
    : typeof ARGS.scope === 'string' && ARGS.scope.trim()
      ? [ARGS.scope.trim()]
      : [];
const BASE = typeof ARGS.base === 'string' && ARGS.base.trim() ? ARGS.base.trim() : '';
// Per-folder map-focus overlays come from the campaign, never the engine — a hardest-look override is an args.focus row.
const FOCUS = ARGS.focus && typeof ARGS.focus === 'object' ? ARGS.focus : {};
const OUT = CAMP + '/ideation';
const MANDATE = CAMP + '/ideation-pool-mandate.md';
const HANDOFF = CAMP + '/HANDOFF.md';

// --- [MODELS] --------------------------------------------------------------------------

const ROSTERD = {
    type: 'object',
    additionalProperties: false,
    required: ['mandateFound', 'folders', 'note'],
    properties: {
        mandateFound: { type: 'boolean' },
        folders: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['path', 'language', 'openIdeas', 'openTasks'],
                properties: {
                    path: { type: 'string' },
                    language: { type: 'string', enum: ['csharp', 'python', 'typescript', 'cross'] },
                    openIdeas: { type: 'integer' },
                    openTasks: { type: 'integer' },
                },
            },
        },
        note: { type: 'string' },
    },
};

const RECEIPT = {
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

const AXISR = {
    type: 'object',
    additionalProperties: false,
    required: ['axis', 'verdict', 'evidence'],
    properties: {
        axis: { type: 'string' },
        verdict: { type: 'string', enum: ['carded', 'evidence-complete'] },
        evidence: { type: 'string' },
    },
};

const RIPPLE = {
    type: 'object',
    additionalProperties: false,
    required: ['counterpartFolder', 'thesis', 'originCard', 'seamKind', 'seamLabel'],
    properties: {
        counterpartFolder: { type: 'string' },
        thesis: { type: 'string' },
        originCard: { type: 'string' },
        seamKind: { type: 'string' },
        seamLabel: { type: 'string' },
    },
};

const PKG_ROW = {
    type: 'object',
    additionalProperties: false,
    required: ['package', 'language', 'reason'],
    properties: { package: { type: 'string' }, language: { type: 'string' }, reason: { type: 'string' } },
};

const IDEATER = {
    type: 'object',
    additionalProperties: false,
    required: [
        'folder',
        'ok',
        'report',
        'ideasAdded',
        'tasksAdded',
        'axes',
        'rippleRequests',
        'packageNeeds',
        'filesTouched',
        'docgenClean',
        'headline',
        'failure',
    ],
    properties: {
        folder: { type: 'string' },
        ok: { type: 'boolean' },
        report: { type: 'string' },
        ideasAdded: { type: 'integer' },
        tasksAdded: { type: 'integer' },
        axes: { type: 'array', items: AXISR },
        rippleRequests: { type: 'array', items: RIPPLE },
        packageNeeds: { type: 'array', items: PKG_ROW },
        filesTouched: { type: 'array', items: { type: 'string' } },
        docgenClean: { type: 'boolean' },
        headline: { type: 'string' },
        failure: { type: 'string' },
    },
};

const LANGR = {
    type: 'object',
    additionalProperties: false,
    required: [
        'language',
        'ok',
        'report',
        'ripplesLanded',
        'ripplesDeclined',
        'duplicatesCollapsed',
        'ideasAdded',
        'tasksAdded',
        'crossRequests',
        'packageNeeds',
        'filesTouched',
        'docgenClean',
        'headline',
        'failure',
    ],
    properties: {
        language: { type: 'string' },
        ok: { type: 'boolean' },
        report: { type: 'string' },
        ripplesLanded: { type: 'integer' },
        ripplesDeclined: { type: 'integer' },
        duplicatesCollapsed: { type: 'integer' },
        ideasAdded: { type: 'integer' },
        tasksAdded: { type: 'integer' },
        crossRequests: { type: 'array', items: RIPPLE },
        packageNeeds: { type: 'array', items: PKG_ROW },
        filesTouched: { type: 'array', items: { type: 'string' } },
        docgenClean: { type: 'boolean' },
        headline: { type: 'string' },
        failure: { type: 'string' },
    },
};

const CROSSR = {
    type: 'object',
    additionalProperties: false,
    required: [
        'ok',
        'report',
        'ideasAdded',
        'tasksAdded',
        'ripplesLanded',
        'ripplesDeclined',
        'orphansRepaired',
        'duplicatesCollapsed',
        'grainRepairs',
        'rosterCardsAdded',
        'packageNeeds',
        'filesTouched',
        'docgenClean',
        'headline',
        'failure',
    ],
    properties: {
        ok: { type: 'boolean' },
        report: { type: 'string' },
        ideasAdded: { type: 'integer' },
        tasksAdded: { type: 'integer' },
        ripplesLanded: { type: 'integer' },
        ripplesDeclined: { type: 'integer' },
        orphansRepaired: { type: 'integer' },
        duplicatesCollapsed: { type: 'integer' },
        grainRepairs: { type: 'integer' },
        rosterCardsAdded: { type: 'integer' },
        packageNeeds: { type: 'array', items: PKG_ROW },
        filesTouched: { type: 'array', items: { type: 'string' } },
        docgenClean: { type: 'boolean' },
        headline: { type: 'string' },
        failure: { type: 'string' },
    },
};

const ADMITR = {
    type: 'object',
    additionalProperties: false,
    required: ['package', 'language', 'ok', 'admitted', 'report', 'filesTouched', 'headline', 'failure'],
    properties: {
        package: { type: 'string' },
        language: { type: 'string' },
        ok: { type: 'boolean' },
        admitted: { type: 'boolean' },
        report: { type: 'string' },
        filesTouched: { type: 'array', items: { type: 'string' } },
        headline: { type: 'string' },
        failure: { type: 'string' },
    },
};

const AUDITR = {
    type: 'object',
    additionalProperties: false,
    required: [
        'ok',
        'report',
        'rosterEntries',
        'rosterUnexploited',
        'undecomposed',
        'thinFolders',
        'altitudeThin',
        'docgenFailures',
        'headline',
        'failure',
    ],
    properties: {
        ok: { type: 'boolean' },
        report: { type: 'string' },
        rosterEntries: { type: 'integer' },
        rosterUnexploited: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['package', 'language'],
                properties: { package: { type: 'string' }, language: { type: 'string' } },
            },
        },
        undecomposed: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['file', 'card'],
                properties: { file: { type: 'string' }, card: { type: 'string' } },
            },
        },
        thinFolders: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['folder', 'reason'],
                properties: { folder: { type: 'string' }, reason: { type: 'string' } },
            },
        },
        altitudeThin: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['folder', 'reason'],
                properties: { folder: { type: 'string' }, reason: { type: 'string' } },
            },
        },
        docgenFailures: { type: 'array', items: { type: 'string' } },
        headline: { type: 'string' },
        failure: { type: 'string' },
    },
};

// --- [DOCTRINE] ------------------------------------------------------------------------

const PATH_LAW =
    'Every path you write, cite, or pass is ABSOLUTE from ' +
    REPO +
    ' — never a relative path or bare basename; a relative product path mints a stray directory, a named campaign defect. Every product of ' +
    'yours lands under ' +
    OUT +
    '.';

const GIT_LAW =
    'Git is READ-ONLY in this lane: log/show/diff only. Never stage, commit, stash, restore, or mutate working-tree state; libs/ and ' +
    '.planning/ paths never enter any git write command regardless of instruction.';

const MANDATE_LAW =
    'Read ' +
    MANDATE +
    ' IN FULL before any other read — it is this lane law and is never acted on from a paraphrase; then read ' +
    HANDOFF +
    ' sections [01] and [02] for the campaign laws the mandate presumes.';

const POOL_LAW =
    'Pool depth IS the deliverable: open cards are the feed slice-implement.js ingests, and an empty or thin OPEN pool is a defect ' +
    'unless page-level evidence proves folder-completeness. Answer both the engine DEPTH axes ' +
    JSON.stringify(DEPTH_AXES) +
    ' and every capability-family axis the mandate [03] goal template names, axis by axis against this folder own domain: a missing ' +
    'plausible axis is a card; a covered axis is an evidence row, never a filler card. Return exactly one axes row per DEPTH axis — ' +
    'verdict "carded" with the card ids as evidence, or "evidence-complete" with the page-level proof — and one row per mandate-named ' +
    'theme axis the folder domain admits; an inadmissible mandate axis is omitted, never forced hollow, and a hollow evidence row is a ' +
    'named defect the terminal audit surfaces. CATALOG ALIGNMENT — a folder-tier .api catalogue is minted only for a package the ' +
    'substrate tier does NOT carry; the substrate tier is read FIRST, and a substrate-carried package is REGISTERED for the folder ' +
    '(folder README registry + owning project manifest) never re-catalogued — a redirecting or duplicating folder-tier .api file is a ' +
    'named defect. A card touching a package admission carries the full bi-directional touch-point set as its scope: central manager ' +
    'row, project manifest, branch README registry, folder README registry, owning .api tier.';

const SEED_LAW =
    'SEED SOURCES — every open idea traces to at least one NAMED source beyond this folder own pages, cited in the idea body; a folder ' +
    'whose entire OPEN idea pool traces only to its own pages is altitude-thin, a named audit defect. Required source classes, each a ' +
    'generator not merely a gap: (a) BOTH .api TIERS as capability fuel — an admitted member no fence composes ADMITS a new owner-family; ' +
    'name the member and the family it seeds. (b) SIBLING-FOLDER SEAMS — every settled strata edge is a capability a neighbor exposes ' +
    'this folder could consume or deepen. (c) BRANCH STRATA MAP — a lower-stratum owner this folder RE-DERIVES is a ' +
    'collapse-into-composition idea; an upward capability the strata admit that no folder carries is a new-owner idea. (d) ' +
    'CROSS-LANGUAGE COUNTERPART — a capability a peer runtime carries at the wire that this folder lacks is a counterpart idea, authored ' +
    'here as origin with the ripple landing in the peer. (e) ADMITTED-PACKAGE ECOSYSTEM — what each admitted package makes NEWLY ' +
    'POSSIBLE, never what pages already mention. (f) REAL-WORLD REFERENCE SYSTEM — the production systems that own this folder domain, ' +
    'named in the adjacent map [REFERENCES] rows; the capability gap against them is the folder moonshot idea. MOONSHOT: at least one ' +
    'idea per non-complete folder is estate-altitude — a cross-folder or cross-stratum move, or a [REFERENCES]-gap close — and MAY ' +
    'assume downstream realization; a pool of only folder-local moves is altitude-thin.';

const OWNER_LAW =
    'OWNER-FIRST — the branch map [OWNERS] rows pre-arbitrate the owner of every cross-folder capability family per the ' +
    'one-owner-per-runtime strata law, the owner homed at the lowest stratum every consumer references. A family the map assigns to ' +
    'ANOTHER folder is authored THERE: emit a rippleRequests row naming that folder, never a same-thesis card here — an accidental twin ' +
    'is a named defect. A family assigned to YOU is yours as origin. An unassigned family you judge yours states the stratum ground in ' +
    'the idea body.';

const CARD_LAW =
    'Card grammar is a wire contract with the implement workflow discovery: an open card lands inside the [01]-[OPEN] section of the owning ' +
    'IDEAS.md or TASKLOG.md exactly per that file embedded source-only template, its leader at COLUMN ZERO as [ID]-[ACTIVE|QUEUED|BLOCKED]: ' +
    '<thesis> — downstream discovery greps that exact leader shape, so an indented or dash-prefixed leader is an invisible card. IDs continue ' +
    'the file existing series; every open card names its exact landing file(s) by repo-relative path; a "(none)" placeholder is deleted when ' +
    'the first card lands; Atomic flags minor scope on tasks; Ripple rides ONLY the counterpart card of a cross-folder pair or a same-folder ' +
    'prerequisite, naming the origin as its template prescribes and prefixed follows/precedes/mirrors when build order is load-bearing. ' +
    'CLOSED/DROPPED cards are rulings — never re-opened, re-litigated, or deleted. Every open idea decomposes into ' +
    'same-folder TASKLOG tasks in the same pass — an open idea with no open task is a defect. Ideas are the BIG moves: ambitious, ' +
    'non-derivative, never filler minted to satisfy a count, and they may ASSUME downstream realization; tasks are specific — they map, find, ' +
    'and pin the where/what. A BLOCKED card carries an Arms: line naming the exact observable that flips it actionable; a probe, research, ' +
    'or member-pin card carries a Route: line — the ordered verification path (an assay api member target, ' +
    'a .api catalog, a live doc, a seam-owner page) — the implement plan lane decomposes exactly those lines. No versions in cards; no ' +
    'python-version floors, gates, or markers anywhere; an obsolete surface encountered inside your write territory is deleted outright. ' +
    'A card names a member, owner, or landing anchor under one of two frames, never blurred: an EXISTING anchor verified against its ' +
    'owner-truth route this pass (an .api catalog row for an external member, the owning design-page fence for a Rasm member) — or an ' +
    'ASSUMED-future anchor the card explicitly marks (Assumes: <anchor>) for a downstream slice to mint. An unverified member asserted ' +
    'as existing is the stale-claim/phantom defect. A cross-folder landing is ASSUMED unless its counterpart card and mirrored seam land ' +
    'this pass.';

const RIPPLE_LAW =
    'A cross-folder pair is split custody: author the ORIGIN card in your files (no Ripple line) and return the counterpart as a ' +
    'rippleRequests row {counterpartFolder (absolute folder path), thesis (the counterpart card thesis), originCard ("FILE [ID]"), ' +
    'seamKind (the [SEAMS] edge kind), seamLabel (the edge label)} — never edit a counterpart folder yourself; the language and cross ' +
    'lanes land counterparts carrying the Ripple line that names your origin. A landed counterpart is a TWO-ENDED SEAM: the same pass ' +
    'writes the mirrored [SEAMS] edge into the ARCHITECTURE.md of BOTH endpoint folders with identical [KIND] and label and opposed ' +
    'direction — an origin edge without its counterpart, or a kind/label mismatch, is the seam-mirror defect. A Ripple line naming a ' +
    'counterpart with no mirrored edge is an orphan, not a landing.';

const PKG_LAW =
    'A package a card composes that is absent from its central manifest is NEVER installed or manifest-edited by you: return it as a ' +
    'packageNeeds row {package, language, reason} — a serialized admission lane owns the full mandate [06] chain, and cards may assume the ' +
    'admission lands.';

const DOCGEN_LAW =
    'Run the docgen gate script at ' +
    REPO +
    '/.claude/skills/docgen/scripts/prose_gate.py (invocation per its --help) over every .md file you touched, repaired to zero FAIL before ' +
    'returning; docgenClean is true only from a clean final run.';

const MAP_ROLE =
    'You are a read-only recon mapper for the Rasm planning corpus ideation pool.\nTreat the task-named territory as read territory.\n' +
    'Edit nothing.\nRun git in read-only form only (log, show, diff); never stage or commit.';

const MAP_VERIFY =
    '<verification>\nRe-open every source anchor cited by a settled row.\nMatch every cited member by exact textual spelling.\nTreat a ' +
    'substring, fuzzy match, or paraphrase as unverified.\nVerify each absence claim against the complete census boundary its row names.\n' +
    'Re-run any probe that returned nothing in a second form before recording an absence.\nRemove any settled row whose evidence fails ' +
    're-confirmation.\nRecord the removed claim and failed probe in [COVERAGE].\n</verification>';

// --- [OPERATIONS] ----------------------------------------------------------------------

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
const guard = (p) => p.catch(() => null);
const sum = (xs, f) => xs.reduce((a, x) => a + (f(x) || 0), 0);
const slugOf = (s) =>
    String(s)
        .toLowerCase()
        .replace(/[^a-z0-9.-]+/g, '-');
const fid = (f) => (SHORT[f.language] || 'xx') + '-' + slugOf(f.path.replace(/\/+$/, '').split('/').pop());
const keyOf = (r) => r.counterpartFolder + '|' + r.originCard + '|' + r.thesis;
const sortRows = (rows) =>
    [...new Map(rows.map((r) => [keyOf(r), r])).values()].sort((a, b) => (keyOf(a) < keyOf(b) ? -1 : keyOf(a) > keyOf(b) ? 1 : 0));
const langOf = (p) => {
    const s = String(p || '');
    const hit = LANGS.find((L) => s.startsWith(REPO + '/' + L.root + '/') || s.startsWith(L.root + '/'));
    return hit ? hit.key : null;
};
const planningRootOf = (f) => f.path + '/.planning';
const apiTiersOf = (f) => f.path + '/.api and ' + REPO + '/libs/' + f.language + '/.api';
const focusKeyOf = (f) => Object.keys(FOCUS).find((k) => f.path.endsWith(k)) || '';
const memoryClause = (f) =>
    f.language === 'csharp'
        ? ' plus the memory index at /Users/bardiasamiee/.claude/projects/-Users-bardiasamiee-Documents-99-Github-Rasm/memory/MEMORY.md — open ' +
          'every reference_* entry naming a surface this folder composes (RhinoCommon, GH2, Eto, LanguageExt, Thinktecture, or any other ' +
          'surface the folder pulls in) —'
        : '';
const mapClause = (r) =>
    r && r.ok
        ? 'at ' +
          r.report +
          ' IN FULL from disk as grounding to verify and exceed — its rows are signals, never law; re-verify each anchor before use.'
        : '— NONE landed for this territory; your own full read replaces it.';
const rosterClause = (r) =>
    r && r.ok
        ? 'the campaign package roster at ' + r.report + ' (read the [ROSTER] rows IN FULL)'
        : 'the campaign package roster — its lane FAILED; derive admitted-package facts from the central manifests and .api tiers yourself';
const adjClause = (r) =>
    r && r.ok
        ? 'at ' +
          r.report +
          ' — its [CANDIDATES] rows are verified-existing research material a card may base on, returning the package as a packageNeeds row ' +
          'for the admission lane to live-verify; never a manifest edit, never treated as already admitted; its [REFERENCES] rows name the ' +
          'real-world systems each folder is measured against and seed the folder moonshot idea'
        : '— NONE landed for this branch; base package needs on your own domain reasoning, the admission lane verifies';
const bmapClause = (r) =>
    r && r.ok
        ? 'at ' + r.report + ' — read its [OWNERS] rows IN FULL from disk; they pre-arbitrate every cross-folder capability family per the strata law'
        : '— NONE landed for this branch; derive owner assignments from the branch ARCHITECTURE.md strata law yourself';

const mapLaw = (gather, sections) =>
    '<role>\n' +
    MAP_ROLE +
    '\n</role>\n\n<completion_bar>\nDone requires one complete markdown map as the final message.\nObservable completion requires every ' +
    'output-contract section in order, an on-disk source and anchor for every settled row, and [COVERAGE] accounting for every required ' +
    'read.\nExclude unverified claims from settled sections; place each in [COVERAGE] with the failed probe.\nProvide information only — ' +
    'locations, members, gaps as facts — never prescriptions, designs, or card text.\n</completion_bar>\n\n<context_gathering>\n' +
    gather +
    '\nUse at most 80 tool calls across discovery and verification.\nCount every tool invocation against the single budget.\nRead in small ' +
    'batches that preserve complete output.\nDo not concatenate the territory into one command.\nReserve enough calls to re-open every cited ' +
    'anchor during verification.\nWhen the remaining budget is required for verification, route unresolved discovery to [COVERAGE] instead ' +
    'of re-reading.\n</context_gathering>\n\n' +
    MAP_VERIFY +
    '\n\n<output_contract>\nReturn one markdown document with nothing before or after it.\nUse exactly these H2 sections in this order.\n' +
    'Add no other H2 section.\n\n' +
    sections.map((s) => '## [' + s[0] + ']\nUse one "- " row per entry shaped as: ' + s[1] + '.\n').join('\n') +
    '\nUse "- none" when a section has no qualifying rows.\nKeep every row factual and anchored.\nDo not prescribe changes.\n</output_contract>';

const FSECTIONS = [
    ['PAGES', 'page: <absolute path> | loc: <line count> | charter: <one-line owner statement from the page lead>'],
    [
        'CARDS',
        'file: <absolute IDEAS.md or TASKLOG.md path> | id: <card id> | status: <ACTIVE|QUEUED|BLOCKED|COMPLETE|DROPPED> | thesis: <leader text>',
    ],
    [
        'UNEXPLOITED',
        'member: <exact name> | tier: <folder|branch> | catalog: <absolute .api path and anchor> | admits: <folder concept admitting it> | ' +
            'absence-boundary: <pages and cards checked>',
    ],
    ['AXES', 'axis: <axis key> | state: <covered|partial|absent> | evidence: <absolute path and anchor, or the probes that returned nothing>'],
    ['STRATA', 'seam: <origin -> target> | state: <wired|unwired> | evidence: <absolute path and anchor>'],
    [
        'STRUCTURAL',
        'verdict: <new-file|new-subfolder|stub-folder|none> | where: <absolute path> | ground: <capability demanding it, the folder file count ' +
            'against the mandate 4+ stub law, and the 2+ non-eponymous sibling-page rule status>',
    ],
    ['COVERAGE', 'status: read|skipped|unverified | source: <absolute path and anchor when present> | reason: <observable evidence or failed probe>'],
];

const BSECTIONS = [
    ['PAGES', 'folder: <absolute package folder path> | pages: <count under its .planning> | subfolders: <domain sub-folder names or none>'],
    [
        'SUBSTRATE',
        'member: <exact name> | catalog: <absolute branch .api path and anchor> | admits: <branch concept admitting it> | absence-boundary: <folders checked>',
    ],
    ['CARDS', 'file: <absolute language-root IDEAS.md or TASKLOG.md path> | id: <card id> | status: <status> | thesis: <leader text>'],
    ['BREADTH', 'folder: <absolute path> | gap: <structural breadth fact> | evidence: <census numbers or absent-surface probe>'],
    ['SEAMS', 'seam: <origin folder -> target folder> | state: <wired|unwired> | evidence: <absolute path and anchor>'],
    [
        'OWNERS',
        'family: <cross-folder capability family> | owner: <absolute folder path owning it per the strata law> | stratum: <stratum + the ' +
            'one-owner-per-runtime ground> | contenders: <other folders plausibly carrying it> | evidence: <ARCHITECTURE strata anchor>',
    ],
    ['COVERAGE', 'status: read|skipped|unverified | source: <absolute path and anchor when present> | reason: <observable evidence or failed probe>'],
];

const XSECTIONS = [
    ['CARDS', 'file: <absolute libs/.planning IDEAS.md or TASKLOG.md path> | id: <card id> | status: <status> | thesis: <leader text>'],
    ['ESTATE', 'concern: <cross-language concern> | endpoints: <absolute paths> | state: <wired|unwired|partial> | evidence: <anchor>'],
    ['BALANCE', 'dimension: <coverage dimension> | csharp: <fact> | python: <fact> | typescript: <fact> | evidence: <census probe>'],
    ['COVERAGE', 'status: read|skipped|unverified | source: <absolute path and anchor when present> | reason: <observable evidence or failed probe>'],
];

const GSECTIONS = [
    ['WINDOW', 'base: <commit sha> | resolution: <how the pre-campaign base was resolved, with the git evidence>'],
    [
        'ROSTER',
        'package: <exact id> | language: <csharp|python|typescript> | commit: <adding sha> | manifest: <absolute manifest path> | ' +
            'api: <absolute .api catalog path or missing>',
    ],
    ['COVERAGE', 'status: read|skipped|unverified | source: <absolute path when present> | reason: <observable evidence or failed probe>'],
];

const wrapPrompt = (report, law, task, medium, minHeads) =>
    'DISPATCH ROLE: codex performs the complete TASK below through one supervised lane run; never perform, edit, judge, or relay the ' +
    'work yourself. (1) Write the LANE LAW block below VERBATIM to ' +
    report +
    '.lane/law.md and the TASK block below VERBATIM to ' +
    report +
    '.lane/task.md, composing neither. (2) Run ONE Bash call with run_in_background true: ' +
    REPO +
    '/.claude/skills/codex/scripts/codex-lane.sh --task ' +
    report +
    '.lane/task.md --law ' +
    report +
    '.lane/law.md --dir ' +
    report +
    '.lane --cwd ' +
    REPO +
    ' --sandbox danger-full-access --model gpt-5.6-sol' +
    (medium ? ' --effort medium' : '') +
    ' --out ' +
    report +
    '; the harness re-invokes you when the lane exits — Read ' +
    report +
    '.lane/receipt.json then, never a polling loop. Recovery is two-branch and ONCE-only — the whole budget: a receipt reason "crash" ' +
    'alone (the session persisted on disk) overwrites the task file with "continue and complete the lane, then land the receipt" and ' +
    're-runs the same command plus --resume <the receipt thread_id>; any other failed receipt (max-timeout, turn-failed, ' +
    'refusal) re-runs the same command untouched. (3) The lane lands the product at ' +
    report +
    ' via --out. (4) Verify with one Bash call: grep -c "^## \\[" ' +
    report +
    ' — fewer than ' +
    minHeads +
    ' section heads means a malformed product: rewrite once from the last agent_message item text in ' +
    report +
    '.lane/events.jsonl (jq -rs, Write that), then return ok=false with the miss. (5) Return ok, ' +
    'report, entries = the total "- " row count across settled sections ("- none" counts zero), headline = one mechanical per-section ' +
    'tally, failure empty — or ok=false with the error text VERBATIM.\n\nLANE LAW:\n\n' +
    law +
    '\n\nTASK:\n\n' +
    task;

const rosterWrapPrompt = () =>
    wrapPrompt(
        OUT + '/roster-packages.md',
        mapLaw(
            'Read the mandate section [04] at the task-named path first, in full.\nThen resolve the campaign window and walk the git ' +
                'evidence exactly as the task orders, unioned with on-disk manifest state.',
            GSECTIONS,
        ),
        'Build the admitted-this-campaign package roster per mandate [04] at ' +
            MANDATE +
            '. ' +
            (BASE
                ? 'Pre-campaign base: ' + BASE + ' (record it in [WINDOW] with the confirmation evidence).'
                : 'Resolve the pre-campaign base from history: walk git log --oneline over the three central manifests and the libs .api paths; ' +
                  'the campaign window is the contiguous recent run of commits landing package and .api waves; the base is the parent of that ' +
                  'window earliest commit. When ambiguous prefer the WIDER window — a too-wide roster only adds evidence rows, a too-narrow one ' +
                  'silently drops. Record the resolution evidence in [WINDOW].') +
            ' Then walk git log -p from the base to HEAD over ' +
            REPO +
            '/Directory.Packages.props, ' +
            REPO +
            '/pyproject.toml, ' +
            REPO +
            '/pnpm-workspace.yaml, and every .api/ path under ' +
            REPO +
            '/libs; union with current on-disk state; emit one [ROSTER] row per package ADMITTED inside the window (a row edited but ' +
            'pre-existing is not admitted). Git stays read-only: log/show/diff only.',
        false,
        3,
    );

const fmapWrapPrompt = (f) => {
    const fk = focusKeyOf(f);
    return wrapPrompt(
        OUT + '/map-' + fid(f) + '.md',
        mapLaw(
            'Read fully in this order:\n1. The mandate file the task names — sections [02], [03], and [05] govern the map grain.\n2. The ' +
                'campaign handoff section [01] at ' +
                HANDOFF +
                ' — the functionality inventory grounding the axis keys.\n3. The folder README.md, ARCHITECTURE.md, IDEAS.md, and ' +
                'TASKLOG.md.\n4. Every design page under the folder .planning root.\n5. Both .api tiers the task names, at member level.\n' +
                'Treat those files as the census boundary; do not expand into sibling folders.',
            FSECTIONS,
        ),
        'Map ' +
            f.path +
            ' (' +
            f.language +
            ') for the ideation pool. MANDATE: ' +
            MANDATE +
            '. PLANNING ROOT: ' +
            planningRootOf(f) +
            '. API TIERS (member level, both): ' +
            apiTiersOf(f) +
            '. AXIS KEYS for [AXES] (the engine DEPTH axes; the mandate [03] goal template names the capability-family theme axes, graded ' +
            'where the folder domain admits them): ' +
            JSON.stringify(AXES) +
            '.' +
            (fk ? ' ' + FOCUS[fk] : ''),
        !fk,
        7,
    );
};

const bmapWrapPrompt = (L) =>
    wrapPrompt(
        OUT + '/map-branch-' + L.key + '.md',
        mapLaw(
            'Read fully in this order:\n1. The mandate file the task names — sections [02], [03], and [05] govern the map grain.\n2. The ' +
                'campaign handoff section [01] at ' +
                HANDOFF +
                ' — the functionality inventory grounding the breadth grades.\n3. The branch strata map at ' +
                REPO +
                '/' +
                L.root +
                '/.planning/ARCHITECTURE.md — stratum roster, dependency direction, and the [SEAMS] registry; it decides every [OWNERS] ' +
                'assignment, and the owner home is the LOWEST stratum every consumer references — an owner homed above any consumer ' +
                'manufactures twins by law.\n4. The language-root .planning card pair and design pages.\n' +
                '5. The branch .api substrate at member level.\n6. Every package folder directly under the branch root at registry depth: ' +
                'README.md, ARCHITECTURE.md, and page rosters — never full page reads.',
            BSECTIONS,
        ),
        'Map the ' +
            L.key +
            ' branch altitude for the ideation pool. MANDATE: ' +
            MANDATE +
            '. BRANCH ROOT: ' +
            REPO +
            '/' +
            L.root +
            '. LANGUAGE TIER: ' +
            REPO +
            '/' +
            L.root +
            '/.planning. SUBSTRATE: ' +
            REPO +
            '/' +
            L.root +
            '/.api (member level). Grade [BREADTH] against the mandate [02] census evidence and the [03] STRUCTURAL BREADTH law. Grade ' +
            'the folders the campaign mandate names hardest — the mandate [02] rows are the standing evidence.',
        false,
        7,
    );

const xmapWrapPrompt = () =>
    wrapPrompt(
        OUT + '/map-cross.md',
        mapLaw(
            'Read fully in this order:\n1. The mandate file the task names — sections [01], [02], and [03] govern the map grain.\n2. The ' +
                'libs/.planning card pair and design pages.\n3. Each branch root at registry depth: the language-root README/ARCHITECTURE and ' +
                'the .planning card pairs — never full page reads.',
            XSECTIONS,
        ),
        'Map the cross-libs altitude for the ideation pool. MANDATE: ' +
            MANDATE +
            '. CROSS TIER: ' +
            REPO +
            '/libs/.planning. BRANCH ROOTS: ' +
            LANGS.map((L) => REPO + '/' + L.root).join(', ') +
            '. [ESTATE] rows carry cross-language concerns as facts; [BALANCE] compares the three branches on coverage dimensions the ' +
            'mandate [02] census names.',
        true,
        4,
    );

const adjPrompt = (L) =>
    'ADJACENT-PACKAGE RESEARCH — the ' +
    L.key +
    ' ecosystem, per the mandate [03] ADJACENT-PACKAGE MINING axis. Read ' +
    MANDATE +
    ' sections [03] and [06] first, then ' +
    HANDOFF +
    ' section [01] for the functionality inventory. ' +
    PATH_LAW +
    ' ' +
    GIT_LAW +
    ' Repo reads stay SHALLOW: ' +
    REPO +
    '/' +
    L.manifest +
    ' for the admitted families and label groups, and the .api catalog FILE NAMES under ' +
    REPO +
    '/' +
    L.root +
    ' (branch tier and every folder tier) — never member-level reads. Then research LIVE: load the registry tools via ToolSearch (' +
    (L.key === 'csharp' ? 'mcp__nuget__get_latest_package_version, ' : '') +
    'WebSearch, WebFetch, mcp__context7__*) and hunt namespace-adjacent packages the estate does NOT hold — the admitted ecosystem ' +
    'families this branch actually holds, extended, and the branch folder domains beyond them — and, per folder domain under this branch, ' +
    'the two or three real-world production systems that own that domain — their architecture, not their packages — feeding [REFERENCES]. ' +
    'Every [CANDIDATES] row is verified to EXIST on ' +
    L.registry +
    ' today with the probe cited; a capability an admitted package already owns is excluded (name-check the manifest); no version numbers ' +
    'anywhere. Every candidate is working material: a card it seeds states the capability as fact and carries NO registry version anchors ' +
    'or freshness-dated prose — the dossier holds the citation, the card holds the capability; a package a card composes routes as a ' +
    'packageNeeds row for the admission lane to live-verify, never asserted admitted from the dossier. Write one markdown document to ' +
    OUT +
    '/adjacent-' +
    L.key +
    '.md with exactly these H2 sections in order: "## [CANDIDATES]" with one "- " row per entry shaped as: package: <exact registry id> | ' +
    'registry: ' +
    L.registry +
    ' | family: <admitted family or folder domain it extends> | capability: <fact> | adjacent-to: <admitted package or folder> | evidence: ' +
    '<registry probe>; then "## [REFERENCES]" with one "- " row per folder domain under this branch shaped as: folder: <absolute folder ' +
    'path> | system: <named production or reference system owning the domain> | capability: <the capability it owns> | gap: <what the ' +
    'folder lacks against it> | evidence: <url or doc probe>; then "## [COVERAGE]" with rows shaped as: status: read|probed|unverified | ' +
    'source: <path or url> | reason: <observable ' +
    'evidence or failed probe>. Use "- none" when a section has no qualifying rows. Return ok, report (the document path), entries (the ' +
    '[CANDIDATES] row count), one-line headline, failure empty.';

const discoverPrompt = () =>
    'Resolve the ideation roster from disk. First verify the mandate file exists at ' +
    MANDATE +
    ' (one Bash test) and read its section [01]: a missing file returns mandateFound=false, folders [], note naming the miss — nothing else ' +
    'runs. Folders: every package directory directly under ' +
    REPO +
    '/libs/csharp, ' +
    REPO +
    '/libs/python, and ' +
    REPO +
    '/libs/typescript carrying IDEAS.md or TASKLOG.md at its root (fd over libs/, never a hardcoded list; skip node_modules and ' +
    'dot-directories); plus each branch tier ' +
    REPO +
    '/libs/{csharp,python,typescript}/.planning where card files exist; plus the cross-libs tier ' +
    REPO +
    '/libs/.planning. Per folder count open cards: lines matching ^\\[[A-Za-z0-9_-]+\\]-\\[(ACTIVE|QUEUED|BLOCKED)\\] inside the [01]-[OPEN] ' +
    'section — openIdeas from IDEAS.md, openTasks from TASKLOG.md ("(none)" is zero). Return {mandateFound, folders: [{path (absolute), ' +
    'language, openIdeas, openTasks}], note}; language derives from the path segment under libs/, and ' +
    REPO +
    '/libs/.planning is language "cross".' +
    (SCOPE.length ? ' Restrict folders to those matching any of: ' + JSON.stringify(SCOPE) + '.' : '');

const ideatePrompt = (f, mapR, ros, adj, bmap) =>
    'IDEATE ' +
    f.path +
    ' (' +
    f.language +
    ') — the per-folder card-estate build-out. Write territory: EXACTLY ' +
    f.path +
    '/IDEAS.md and ' +
    f.path +
    '/TASKLOG.md plus your receipt document; never a design page, never a sibling folder, never a central manifest. ' +
    MANDATE_LAW +
    ' ' +
    PATH_LAW +
    ' ' +
    GIT_LAW +
    ' Read next —' +
    memoryClause(f) +
    ' ' +
    f.path +
    '/README.md and ' +
    f.path +
    '/ARCHITECTURE.md in full, both card files in full, every design page under ' +
    planningRootOf(f) +
    ' at least to its full section spine, both .api tiers (' +
    apiTiersOf(f) +
    ') at member level for the packages this folder composes, the branch strata map at ' +
    REPO +
    '/libs/' +
    f.language +
    '/.planning/ARCHITECTURE.md (the stratum this folder owns and its seam edges), and — at the wire touchpoints this folder names — the ' +
    'ARCHITECTURE.md and [01]-[OPEN] pools of the cross-language counterpart folders. Derive your OWN axis-by-axis gap ruling from that ' +
    'read FIRST; then read the ' +
    'fact map ' +
    mapClause(mapR) +
    ' Then read ' +
    rosterClause(ros) +
    ' — each roster row owned by this folder tiers must end exploited by one of your cards or carried as axis evidence. Then read the ' +
    'adjacent-candidate map ' +
    adjClause(adj) +
    '. Then read the branch owner map ' +
    bmapClause(bmap) +
    '. ' +
    POOL_LAW +
    ' ' +
    SEED_LAW +
    ' ' +
    OWNER_LAW +
    ' ' +
    CARD_LAW +
    ' ' +
    RIPPLE_LAW +
    ' ' +
    PKG_LAW +
    ' ' +
    DOCGEN_LAW +
    ' Write your COMPLETE receipt document as one JSON object to ' +
    OUT +
    '/ideate-' +
    fid(f) +
    '.json (Write tool, absolute path): {folder, filesTouched, ideas: [{file, id, status, thesis}], tasks: [{file, id, status, thesis, ' +
    'idea}], axes, rippleRequests, packageNeeds, summary}. Then return the thin receipt: folder ' +
    f.path +
    ', ok, report (the receipt document path), ideasAdded, tasksAdded, axes (the same rows), rippleRequests, packageNeeds, filesTouched ' +
    '(absolute), docgenClean, one-line headline, failure empty.';

const langPrompt = (L, bmap, ros, adj, rows, sameLang, failed) =>
    'LANGUAGE PASS ' +
    L.key +
    ' — the branch-altitude card estate. Write territory: EXACTLY the IDEAS.md and TASKLOG.md pairs under ' +
    REPO +
    '/' +
    L.root +
    ' (every package folder plus the language root ' +
    REPO +
    '/' +
    L.root +
    '/.planning) and your receipt document; never a design page, never a sibling language, never libs/.planning, never a central manifest. ' +
    MANDATE_LAW +
    ' ' +
    PATH_LAW +
    ' ' +
    GIT_LAW +
    ' Inputs, in order: (1) your own read of the language-root card pair and of each per-folder receipt document IN FULL from disk — the ' +
    'folder lanes this run: ' +
    JSON.stringify(
        rows.map((r) => ({
            folder: r.folder.path,
            report: (r.idr && r.idr.report) || '',
            ideasAdded: (r.idr && r.idr.ideasAdded) || 0,
            tasksAdded: (r.idr && r.idr.tasksAdded) || 0,
        })),
    ) +
    '; (2) the branch map ' +
    mapClause(bmap) +
    ' (3) ' +
    rosterClause(ros) +
    '; (4) the adjacent-candidate map ' +
    adjClause(adj) +
    '. FAILED FOLDER LANES (their pools got no deepening — card what the branch altitude owns for them, record the remainder as thin in ' +
    'your report, and never re-run a folder ideation): ' +
    JSON.stringify(failed) +
    '. DUTIES: (1) RIPPLE LANDING — per row below, verify the thesis against current disk, then land the counterpart card in the ' +
    'counterpart folder card files per the template with the Ripple line naming the origin; a thesis current disk refutes is DECLINED with ' +
    'the refutation recorded in your report document, never silently dropped: ' +
    JSON.stringify(sameLang) +
    '. (2) DEDUP — near-identical open cards across folders collapse to ONE owner card plus counterpart ripples; collapsed duplicates close ' +
    'as [DROPPED] with a disposition naming the surviving owner. STRATA ARBITRATION (owner grain, not card grain): sweep the owner ' +
    'anchors new cards mint; when 2+ folders mint an owner for ONE bounded concept, rule the folder at the lowest consumer-reachable ' +
    'stratum canonical; the other folder card rewrites to a CONSUMER card composing and rippling INTO the canonical owner, its ' +
    'disposition naming the ruling. Surviving twins — same-stratum owners serving genuinely disjoint domains — keep an explicit [STRATA] ' +
    'disposition line naming the justifying domain; an unexplained twin is a defect. (3) LANGUAGE-ROOT PAIR — card the branch-wide moves: ' +
    'branch .api substrate ' +
    'exploitation, cross-folder strata wiring, structural breadth per mandate [03].' +
    ' The mandate [02] census rows are standing evidence — the folders the mandate names card the deepest, and the branch map [BREADTH] ' +
    'rows ground each structural card.' +
    ' (4) A need whose counterpart lives in another language returns as a crossRequests row, never a foreign edit. ' +
    CARD_LAW +
    ' ' +
    PKG_LAW +
    ' ' +
    DOCGEN_LAW +
    ' Write your COMPLETE receipt document as one JSON object to ' +
    OUT +
    '/lang-' +
    L.key +
    '.json (Write tool, absolute path): {language, filesTouched, ripplesLanded: [{counterpartFolder, id}], ripplesDeclined: [{originCard, ' +
    'refutation}], duplicatesCollapsed: [{owner, dropped}], ideas, tasks, crossRequests, packageNeeds, summary}. Then return the thin ' +
    'receipt: language "' +
    L.key +
    '", ok, report, ripplesLanded/ripplesDeclined/duplicatesCollapsed/ideasAdded/tasksAdded counts, crossRequests, packageNeeds, ' +
    'filesTouched (absolute), docgenClean, one-line headline, failure empty.';

const crossPrompt = (xmap, ros, reqRows, langOut) =>
    'CROSS-LIBS + INTEGRATION — the estate altitude and the terminal alignment pass. Write territory: ' +
    REPO +
    '/libs/.planning/IDEAS.md and TASKLOG.md, plus ANY IDEAS.md/TASKLOG.md under ' +
    REPO +
    '/libs for counterpart landing and coherence repairs, plus your receipt document; never a design page, never a central manifest. ' +
    MANDATE_LAW +
    ' ' +
    PATH_LAW +
    ' ' +
    GIT_LAW +
    ' Inputs: the cross map ' +
    mapClause(xmap) +
    ' Then ' +
    rosterClause(ros) +
    '; then each language receipt document IN FULL from disk: ' +
    JSON.stringify(
        langOut.map((o) => ({ language: o.language, report: (o.lang && o.lang.report) || '', ok: !!(o.lang && o.lang.ok), failedFolders: o.failed })),
    ) +
    '; per-folder receipt documents live under ' +
    OUT +
    ' as ideate-*.json — read the ones your repairs touch. DUTIES: (1) CROSS-LIBS PAIR — card the estate-wide moves at the libs/.planning ' +
    'tier per mandate [01] tier 3 and [09]: root big moves (estate-wide end-to-end systems spanning multiple language trees) each ripple ' +
    'into the exact language/folder ' +
    'cards realizing them, and a folder design that would collide per-app under the app-neutrality law is itself a card. (2) ' +
    'CROSS-LANGUAGE RIPPLES — land each row below both-ends-verified: the counterpart card lands with the ' +
    'Ripple line naming the origin, and the origin card is confirmed on current disk; a refuted or malformed row is DECLINED with the ' +
    'refutation recorded in your report document, never silently dropped: ' +
    JSON.stringify(reqRows) +
    '. (3) ROSTER CLOSURE — every [ROSTER] row of the package roster ends exploited by at least one open or closed card under ' +
    REPO +
    '/libs or carried as explicit axis evidence in a receipt document; a package with neither gains its card at the owning folder NOW, ' +
    'counted in rosterCardsAdded. (4) INTEGRATION — the coherence pass over all four altitudes: grain consistency (ideas big, tasks ' +
    'specific, every open idea decomposed — repair misses in place), no orphan ripples (every Ripple line names an existing counterpart — ' +
    'repair both ends), no duplicate cards across altitudes (collapse to one owner plus ripples). STRATA ARBITRATION (owner grain, not ' +
    'card grain): sweep the owner anchors new cards mint; when 2+ folders mint an owner for ONE bounded concept, rule the folder at the ' +
    'lowest consumer-reachable stratum canonical; the other folder card rewrites to a CONSUMER card composing and rippling INTO the ' +
    'canonical owner, its disposition naming the ruling. Surviving twins — same-stratum owners serving genuinely disjoint domains — keep ' +
    'an explicit [STRATA] disposition line naming the justifying domain; an unexplained twin is a defect. ' +
    CARD_LAW +
    ' ' +
    PKG_LAW +
    ' ' +
    DOCGEN_LAW +
    ' Write your COMPLETE receipt document as one JSON object to ' +
    OUT +
    '/cross.json (Write tool, absolute path): {filesTouched, ideas, tasks, ripplesLanded, ripplesDeclined, orphansRepaired, ' +
    'duplicatesCollapsed, grainRepairs, rosterCardsAdded, packageNeeds, summary}. Then return the thin receipt: ok, report, ' +
    'ideasAdded/tasksAdded/ripplesLanded/ripplesDeclined/orphansRepaired/duplicatesCollapsed/grainRepairs/rosterCardsAdded counts, ' +
    'packageNeeds, filesTouched (absolute), docgenClean, one-line headline, failure empty.';

const admitPrompt = (row, origin) =>
    'ADMISSION LANE for package "' +
    row.package +
    '" (' +
    row.language +
    '), requested by ' +
    origin +
    ': ' +
    row.reason +
    '. Read the mandate [06] section at ' +
    MANDATE +
    ' first — it is this lane law. ' +
    PATH_LAW +
    ' ' +
    GIT_LAW +
    ' You are the SINGLE writer on the ' +
    row.language +
    ' central manifest for this call. Execute the FULL admission chain: (1) LIVE-VERIFY the newest stable version — nuget MCP ' +
    'get_latest_package_version for csharp, the live registry for python/typescript; rejection vocabulary is closed: reject ONLY when an ' +
    'already-admitted package supersedes the capability, when existence or installability fails verification, when the license gate ' +
    'fails — this estate is fully OSS with zero commercial intent, any license granting full free use to an OSS project admits (copyleft ' +
    'included) and only payment-required or paid-tier-gated capability rejects — or when any chain step below fails unrecoverably after ' +
    'one self-heal attempt (EXECUTION FAILURE — the failed step named with its evidence), returning admitted=false with the ' +
    'ruling. (2) Land the central manifest row in its owning group (Directory.Packages.props label group / pyproject.toml lean unpinned / ' +
    'pnpm-workspace.yaml cluster). (3) Prove the install gate green (dotnet restore Workspace.slnx / uv lock plus uv sync / pnpm install), ' +
    'self-healing or reverting what cannot resolve — a reverted admission returns admitted=false with the resolver evidence. (4) Author the ' +
    '.api catalog at the correct tier — folder overlay vs language-root substrate per the two-tier law, overlays never copying substrate — ' +
    'with verified members only; an isolation or app-scoped claim lands ONLY with per-instance member evidence verified on the installed ' +
    'surface, and a process-global surface states its host-wide scope honestly and the single-owner admission it demands. (5) Land the ' +
    'README registry row at the consuming folder. (6) Land the csproj reference where consumed ' +
    '(csharp). (7) Run the docgen gate script at ' +
    REPO +
    '/.claude/skills/docgen/scripts/prose_gate.py (invocation per its --help) over the new files, repaired to zero FAIL. Any chain step ' +
    '(1)-(7) failing unrecoverably after one self-heal attempt returns admitted=false with the step named and its evidence, the manifest ' +
    'row and partial artifacts of this admission reverted so the install gate stays green. Write your full ' +
    'admission report to ' +
    OUT +
    '/admit-' +
    slugOf(row.package) +
    '.md, then return: package, language, ok, admitted, report, filesTouched (absolute), one-line headline, failure empty.';

const auditPrompt = (roots, ros, touched) =>
    'TERMINAL AUDIT — prove mandate [08]; count and gate, edit NOTHING. ' +
    MANDATE_LAW +
    ' ' +
    PATH_LAW +
    ' ' +
    GIT_LAW +
    ' Sweep every IDEAS.md and TASKLOG.md under these roots: ' +
    JSON.stringify(roots) +
    '. PROOFS: (1) NO-SILENT-DROPS — read ' +
    rosterClause(ros) +
    '; for each [ROSTER] row find at least one open or closed card naming the package under the roots, or an axes evidence row naming it ' +
    'inside a receipt document under ' +
    OUT +
    '; rows with neither return as rosterUnexploited, and rosterEntries counts the roster. (2) DECOMPOSITION — every open IDEAS card has at ' +
    'least one open same-folder TASKLOG task; misses return as undecomposed {file, card}. (3) POOL VERDICTS — per folder root: DEEPENED ' +
    '(its OPEN pool holds cards this run added) or EVIDENCE-COMPLETE (its receipt document axes rows all carry page-level evidence); a ' +
    'folder with neither returns as thinFolders {folder, reason}. (4) DOCGEN-ZERO — run the docgen gate script at ' +
    REPO +
    '/.claude/skills/docgen/scripts/prose_gate.py (invocation per its --help) batched over the .md files among: ' +
    JSON.stringify(touched) +
    ' — FAIL rows return in docgenFailures verbatim. (5) LEADER COMPAT — every open card leader under the roots matches the column-zero ' +
    '^\\[[A-Za-z0-9_-]+\\]-\\[(ACTIVE|QUEUED|BLOCKED)\\]: shape the implement discovery greps; a malformed leader returns in docgenFailures ' +
    'prefixed "leader: ". (6) ALTITUDE — per DEEPENED folder, at least one OPEN idea is estate-altitude (a cross-folder or cross-stratum ' +
    'move, a wire counterpart, or a [REFERENCES] gap close) and cites a seed source outside the folder own pages; a folder failing ' +
    'returns as altitudeThin {folder, reason}. Write your full audit document (all six proofs with their probes and rosters) to ' +
    OUT +
    '/audit.md, then return: ok (true only when all six proofs pass — altitudeThin empty included), report, rosterEntries, ' +
    'rosterUnexploited, undecomposed, thinFolders, altitudeThin, ' +
    'docgenFailures, one-line headline, failure naming the failed proofs otherwise.';

// --- [COMPOSITION] ---------------------------------------------------------------------

if (!CAMP) return { skipped: true, reason: 'args.camp (absolute campaign home) is required' };

// --- [ROSTER]

const rosterP = guard(
    slot(() => agent(rosterWrapPrompt(), { label: 'sol:roster', phase: 'Roster', model: 'sonnet', effort: 'low', schema: RECEIPT })),
);
const disco = await guard(slot(() => agent(discoverPrompt(), { label: 'discover', phase: 'Roster', model: 'opus', effort: 'low', schema: ROSTERD })));
if (!disco) return { skipped: true, reason: 'discovery lane failed' };
if (!disco.mandateFound) return { skipped: true, reason: 'mandate file missing at ' + MANDATE, note: disco.note };
let folders = (disco.folders ?? []).filter((f) => f.path && f.language);
if (SCOPE.length)
    folders = folders.filter((f) => SCOPE.some((s) => f.path === s || f.path.endsWith('/' + s.replace(/\/+$/, '')) || f.path.includes(s)));
if (!folders.length) return { skipped: true, reason: 'no card-owning folders resolved', scope: SCOPE };
const folderRecs = folders.filter((f) => f.language !== 'cross' && !f.path.endsWith('/.planning'));
const crossRec = folders.find((f) => f.language === 'cross') || null;
const tierOf = (L) => folders.find((f) => f.language === L.key && f.path.endsWith('/.planning')) || null;
const active = LANGS.filter((L) => folderRecs.some((f) => f.language === L.key) || tierOf(L));
log(
    folderRecs.length +
        ' folder(s), ' +
        active.length +
        ' language tier(s), cross ' +
        (crossRec ? 'in' : 'out') +
        ' — open ideas/tasks ' +
        sum(folders, (f) => f.openIdeas) +
        '/' +
        sum(folders, (f) => f.openTasks),
);

// --- [ADMIT_QUEUE]

const admitSeen = new Map();
const manifestQueue = {};
const admitOnce = (row, origin) => {
    const key = row.language + '|' + row.package;
    if (admitSeen.has(key)) return admitSeen.get(key);
    const run = () =>
        guard(
            slot(() =>
                agent(admitPrompt(row, origin), {
                    label: 'admit:' + slugOf(row.package),
                    phase: 'Admit',
                    model: 'opus',
                    effort: 'high',
                    schema: ADMITR,
                }),
            ),
        );
    const p = (manifestQueue[row.language] || Promise.resolve()).then(run);
    manifestQueue[row.language] = p.then(
        () => undefined,
        () => undefined,
    );
    admitSeen.set(key, p);
    return p;
};
const collectNeeds = (rec, origin) => {
    for (const r of (rec && rec.ok && rec.packageNeeds) || []) if (r && r.package && LANGS.some((L) => L.key === r.language)) admitOnce(r, origin);
};

// --- [MAP_AND_IDEATE]

const bmapP = {};
for (const L of active)
    bmapP[L.key] = guard(
        slot(() =>
            agent(bmapWrapPrompt(L), {
                label: 'sol:bmap:' + L.key,
                phase: 'Map',
                model: 'sonnet',
                effort: 'low',
                schema: RECEIPT,
            }),
        ),
    );
const adjP = {};
for (const L of active)
    adjP[L.key] = guard(slot(() => agent(adjPrompt(L), { label: 'adj:' + L.key, phase: 'Map', model: 'opus', effort: 'high', schema: RECEIPT })));
const xmapP = crossRec
    ? guard(slot(() => agent(xmapWrapPrompt(), { label: 'sol:xmap', phase: 'Map', model: 'sonnet', effort: 'low', schema: RECEIPT })))
    : Promise.resolve(null);

const mapLane = (f) =>
    guard(
        slot(() =>
            agent(fmapWrapPrompt(f), {
                label: 'sol:map:' + fid(f),
                phase: 'Map',
                model: 'sonnet',
                effort: 'low',
                schema: RECEIPT,
            }),
        ),
    );
const ideateLane = (f, mapR, ros, adj, bmap) =>
    guard(
        slot(() =>
            agent(ideatePrompt(f, mapR, ros, adj, bmap), {
                label: 'ideate:' + fid(f),
                phase: 'Ideate',
                model: 'fable',
                effort: 'high',
                schema: IDEATER,
            }),
        ),
    );

const chainLang = async (L) => {
    const fs = folderRecs.filter((f) => f.language === L.key);
    const rows = (
        await pipeline(
            fs,
            (f) => mapLane(f),
            (mapR, f) =>
                Promise.all([rosterP, adjP[f.language], bmapP[f.language]])
                    .then(([ros, adj, bmap]) => ideateLane(f, mapR, ros, adj, bmap))
                    .then((idr) => {
                        collectNeeds(idr, f.path);
                        return { folder: f, mapR, idr };
                    }),
        )
    ).filter(Boolean);
    const ripples = sortRows(rows.flatMap((r) => ((r.idr && r.idr.ok && r.idr.rippleRequests) || []).filter((x) => x && x.counterpartFolder)));
    const sameLang = ripples.filter((x) => langOf(x.counterpartFolder) === L.key);
    const crossRows = ripples.filter((x) => langOf(x.counterpartFolder) !== L.key);
    const failed = fs.filter((f) => !rows.some((r) => r.folder.path === f.path && r.idr && r.idr.ok)).map((f) => f.path);
    if (!rows.length && !tierOf(L)) return { language: L.key, rows, failed, sameLang, crossRows, lang: null };
    const [bmap, ros, adj] = await Promise.all([bmapP[L.key], rosterP, adjP[L.key]]);
    const langR = await guard(
        slot(() =>
            agent(langPrompt(L, bmap, ros, adj, rows, sameLang, failed), {
                label: 'lang:' + L.key,
                phase: 'Language',
                model: 'fable',
                effort: 'high',
                schema: LANGR,
            }),
        ),
    );
    collectNeeds(langR, 'language:' + L.key);
    log(
        'language ' +
            L.key +
            ': ' +
            rows.length +
            ' folder lane(s), ' +
            failed.length +
            ' failed, lang lane ' +
            (langR && langR.ok ? 'ok' : 'FAILED'),
    );
    return { language: L.key, rows, failed, sameLang, crossRows: langR && langR.ok ? crossRows : crossRows.concat(sameLang), lang: langR };
};
const langOut = (await pipeline(active, chainLang)).filter(Boolean);

// --- [CROSS]

const allRows = langOut.flatMap((o) => o.rows);
const crossReqRows = sortRows(
    langOut.flatMap((o) => o.crossRows).concat(langOut.flatMap((o) => (o.lang && o.lang.ok && o.lang.crossRequests) || [])),
);
let crossR = null;
if (crossRec || crossReqRows.length) {
    const [xmap, ros] = await Promise.all([xmapP, rosterP]);
    crossR = await guard(
        slot(() =>
            agent(crossPrompt(xmap, ros, crossReqRows, langOut), {
                label: 'cross',
                phase: 'Cross',
                model: 'fable',
                effort: 'high',
                schema: CROSSR,
            }),
        ),
    );
    collectNeeds(crossR, 'cross');
}

// --- [ADMIT]

const admissions = (await Promise.all([...admitSeen.values()])).filter(Boolean);
log(admissions.length + ' admission(s): ' + admissions.filter((a) => a.ok && a.admitted).length + ' admitted');

// --- [AUDIT]

const ros = await rosterP;
// Docgen gates DURABLE repo files only — campaign receipts under CAMP are non-durable and never batch into the audit.
const touched = [
    ...new Set(
        [
            ...allRows.flatMap((r) => (r.idr && r.idr.filesTouched) || []),
            ...langOut.flatMap((o) => (o.lang && o.lang.filesTouched) || []),
            ...((crossR && crossR.filesTouched) || []),
            ...admissions.flatMap((a) => a.filesTouched || []),
        ].filter((p) => p && !String(p).startsWith(CAMP)),
    ),
].sort();
const audit = await guard(
    slot(() =>
        agent(
            auditPrompt(
                folders.map((f) => f.path),
                ros,
                touched,
            ),
            { label: 'audit', phase: 'Audit', model: 'opus', effort: 'high', schema: AUDITR },
        ),
    ),
);
const poolProven = !!audit && audit.ok;
if (!poolProven) log('POOL NOT PROVEN: ' + (audit ? audit.headline || audit.failure : 'audit lane failed'));

// --- [CLOSE]

return {
    folders: folderRecs.length,
    ideated: allRows.filter((r) => r.idr && r.idr.ok).length,
    failedFolders: langOut.flatMap((o) => o.failed),
    ideasAdded:
        sum(allRows, (r) => r.idr && r.idr.ok && r.idr.ideasAdded) +
        sum(langOut, (o) => o.lang && o.lang.ok && o.lang.ideasAdded) +
        ((crossR && crossR.ok && crossR.ideasAdded) || 0),
    tasksAdded:
        sum(allRows, (r) => r.idr && r.idr.ok && r.idr.tasksAdded) +
        sum(langOut, (o) => o.lang && o.lang.ok && o.lang.tasksAdded) +
        ((crossR && crossR.ok && crossR.tasksAdded) || 0),
    axes: {
        carded: sum(allRows, (r) => ((r.idr && r.idr.ok && r.idr.axes) || []).filter((a) => a.verdict === 'carded').length),
        evidenceComplete: sum(allRows, (r) => ((r.idr && r.idr.ok && r.idr.axes) || []).filter((a) => a.verdict === 'evidence-complete').length),
    },
    ripples: {
        sameLanguage: sum(langOut, (o) => o.sameLang.length),
        crossLanguage: crossReqRows.length,
        landed: sum(langOut, (o) => o.lang && o.lang.ok && o.lang.ripplesLanded) + ((crossR && crossR.ok && crossR.ripplesLanded) || 0),
        declined: sum(langOut, (o) => o.lang && o.lang.ok && o.lang.ripplesDeclined) + ((crossR && crossR.ok && crossR.ripplesDeclined) || 0),
    },
    languages: langOut.map((o) => ({
        language: o.language,
        ok: !!(o.lang && o.lang.ok),
        report: (o.lang && o.lang.report) || '',
        ideasAdded: (o.lang && o.lang.ideasAdded) || 0,
        tasksAdded: (o.lang && o.lang.tasksAdded) || 0,
    })),
    cross: crossR
        ? {
              ok: !!crossR.ok,
              report: crossR.report || '',
              orphansRepaired: crossR.orphansRepaired || 0,
              duplicatesCollapsed: crossR.duplicatesCollapsed || 0,
              grainRepairs: crossR.grainRepairs || 0,
              rosterCardsAdded: crossR.rosterCardsAdded || 0,
          }
        : null,
    admissions: admissions.map((a) => ({ package: a.package, language: a.language, admitted: !!(a.ok && a.admitted), report: a.report || '' })),
    audit: audit
        ? {
              ok: !!audit.ok,
              report: audit.report || '',
              rosterEntries: audit.rosterEntries,
              rosterUnexploited: audit.rosterUnexploited,
              undecomposed: audit.undecomposed,
              thinFolders: audit.thinFolders,
              altitudeThin: audit.altitudeThin,
              docgenFailures: audit.docgenFailures,
          }
        : null,
    reports: [
        ros && ros.ok && ros.report,
        ...allRows.flatMap((r) => [r.mapR && r.mapR.ok && r.mapR.report, r.idr && r.idr.ok && r.idr.report]),
        ...langOut.map((o) => o.lang && o.lang.ok && o.lang.report),
        crossR && crossR.ok && crossR.report,
        ...admissions.map((a) => a.report),
        audit && audit.report,
    ].filter(Boolean),
    poolProven,
    failure: poolProven
        ? ''
        : 'POOL NOT PROVEN: ' +
          (audit
              ? audit.rosterUnexploited.length +
                ' roster drop(s), ' +
                audit.undecomposed.length +
                ' undecomposed idea(s), ' +
                audit.thinFolders.length +
                ' thin folder(s), ' +
                audit.altitudeThin.length +
                ' altitude-thin folder(s), ' +
                audit.docgenFailures.length +
                ' docgen/leader failure(s)'
              : 'audit lane failed'),
};
