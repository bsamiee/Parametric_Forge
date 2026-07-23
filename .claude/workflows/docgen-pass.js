export const meta = {
    name: 'docgen-pass',
    whenToUse:
        'Docgen conformance sweep for durable Markdown. Finder groups locate ownership, prose, comment, and structure defects. File workers rebuild each page in place, extract misplaced planning rulings, and preserve code-fence bodies. Adversarial writing passes reconcile the cumulative diff for prose-dense pages. API catalogs close after their grounded structural pass. Owner collectors adjudicate extracted rulings, and the terminal formatter restores canonical tables and gate-clean structure.',
    description:
        'Accepts a folder path, path array, or targets object; empty input is a no-op. Routing deduplicates Markdown files and records structural measures. Analysis compares each page with its live instruction, template, registry, and sibling ownership surfaces. Fix workers remove regenerable framing, repair retained prose and tables, prove demotions, ground API members through the project assay rail, and emit typed receipts. Planning pages write only genuine extracted rulings to scratch dossiers. Adversarial passes restore lost law and remove residual duplication or narration. Collection lands surviving rulings in their owning registries. Formatting closes every touched page under repository law.',
    phases: [
        {
            title: 'Route',
            detail: 'Resolve and deduplicate Markdown targets, then establish the structural baseline used by downstream workers.',
        },
        {
            title: 'Analyze',
            detail: 'Inspect prose pages by owner group and API catalogs by tier, returning only grounded defects, ownership moves, and cross-file directives.',
        },
        {
            title: 'Fix',
            detail: 'Rebuild each file in place, prove every ownership move, extract genuine planning rulings, and return a typed receipt.',
        },
        {
            title: 'Redteam',
            detail: 'Review rebuilt prose pages against the cumulative diff, restore real law, remove residual framing, and harden extracted rulings.',
        },
        {
            title: 'Verify',
            detail: 'Reconcile prose-dense pages after adversarial editing, repairing lost law, unproven demotions, duplicate facts, and structural residue.',
        },
        {
            title: 'Collect',
            detail: 'Adjudicate extracted rulings across owners and transcribe only current, non-duplicated decisions into the owning registries.',
        },
        {
            title: 'Format',
            detail: 'Format every touched page and written ruling registry, then close against repository structure and prose gates.',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const ROOT = '/Users/bardiasamiee/Documents/99.Github/Rasm';
const CHAIN = ['/Users/bardiasamiee/.claude/CLAUDE.md', ROOT + '/CLAUDE.md']; // always-loaded fork surfaces: global [02] + project [02]
const CAP = 14;
const GROUP = 5; // finder files per analyze agent (non-`.api` tiers)
const TIER_GROUP = 40; // `.api`-tier finder ownership slice; each slice sees the WHOLE tier for routing, so the split balances read-load without fragmenting cross-file dedup
const BATCH = 5; // pages per agent for both adversarial passes (Redteam, Verify); batching amortizes their shared cold-review law across a small file group
const PROSE_LO = 45; // prose reduction band the receipt grades against, percent of baseline prose lines
const PROSE_HI = 60;
const COMMENT_TARGET = 50; // non-load-bearing fence comments cut, percent of baseline comment lines
const REDTEAM_FURTHER = '20-30'; // further reduction the red-team drives off the post-Fix disk state
const TOTAL_HI = 80; // upper reduction the run's off-band grade tolerates after Fix + Redteam; over-deletion is owned by Verify, not this soft band

// prose lines = non-blank lines outside fences; the ONE measure census, finders, and receipts share
const PROSE_MEASURE = "awk '/^```/{f=!f;next} !f&&NF{n++} END{print n+0}'";
// comment lines = in-fence lines opening on //, #, --, or ; EXCLUDING section dividers and shebangs; the shared comment measure
const COMMENT_MEASURE =
    'awk \'/^```/{f=!f;next} f{s=$0; sub(/^[ \\t]+/,"",s); if(s ~ /^(\\/\\/|#|--|;)/ && s !~ /^(\\/\\/|#|--|;)[ \\t]*---[ \\t]*\\[/ && s !~ /^#!/) c++} END{print c+0}\'';

// --- [INPUTS] --------------------------------------------------------------------------

const norm = (t) =>
    String(t)
        .trim()
        .replace(new RegExp('^' + ROOT.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '/?'), '')
        .replace(/^\/+/, '')
        .replace(/\/+$/, '');
const argsIn = args;
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
const TARGETS = [...new Set(rawTargets.filter(Boolean).map(norm))].filter(Boolean);

// per-run scratch for the RULINGS extraction dossiers; deterministic from the target set (clock/randomness would break resume)
const fnv1a = (s) => {
    let h = 0x811c9dc5;
    for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193);
    return (h >>> 0).toString(16).padStart(8, '0').slice(0, 6);
};
const SCRATCH =
    '.claude/scratch/docgen-pass-' +
    TARGETS.map((t) => t.split('/').pop().toLowerCase())
        .join('-')
        .replace(/[^a-z0-9.-]+/g, '-')
        .slice(0, 50) +
    '-' +
    fnv1a(JSON.stringify(TARGETS));
const DOSSIER_DIR = SCRATCH + '/rulings';

// --- [ROUTING] -------------------------------------------------------------------------

const kindOf = (p) => {
    const b = p.split('/').pop();
    if (b === 'README.md') return 'readme';
    if (b === 'ARCHITECTURE.md') return 'architecture';
    if (b === 'RULINGS.md') return 'rulings';
    if (b === 'IDEAS.md') return 'ideas';
    if (b === 'TASKLOG.md') return 'tasklog';
    if (p.includes('/.api/') || /^api-.*\.md$/.test(b)) return 'api';
    if (p.includes('/.planning/')) return 'spec';
    return 'page';
};
const TEMPLATE = {
    readme: 'readme.template.md',
    architecture: 'architecture.template.md',
    rulings: 'rulings.template.md',
    ideas: 'ideas.template.md',
    tasklog: 'tasklog.template.md',
    api: 'api-catalog.template.md',
    spec: 'spec.template.md',
    page: '',
};
const templatePath = (kind) => (TEMPLATE[kind] ? ROOT + '/.claude/skills/docgen/templates/' + TEMPLATE[kind] : '');
// terminal stage by kind: an `.api` catalog closes at Fix — the fixer already carries the full API-TRUTH, ultra-stacking, structure, and legacy law and grounds each member against
// the polyglot `tools.assay api query` rail (ilspycmd/introspect/.d.ts by language), so one authoritative pass suffices and a diff-driven second pass only re-opens proven cells. The adversarial Fix -> Redteam -> Verify chain is spent only
// where a cold second pass catches real over-deletion — spec pages, README/ARCHITECTURE/RULINGS registries, prose-dense kinds. adversarial(kind) gates BOTH the red-team and the
// verifier: an `.api` catalog enters neither.
const adversarial = (kind) => kind !== 'api';
const chunk = (xs, n) => Array.from({ length: Math.ceil(xs.length / n) }, (_, i) => xs.slice(i * n, i * n + n));

// RULINGS extraction routing — only files under a `.planning/` tree own a RULINGS.md; the owner is the path component above `.planning`
const underPlanning = (p) => p.includes('/.planning/');
const ownerOf = (p) => (underPlanning(p) ? p.slice(0, p.indexOf('/.planning')) : '');
// nearest-tier RULINGS.md candidates for an owner; package RULINGS sits at the owner root, branch RULINGS inside `.planning`
const rulingsCandidates = (owner) => [ROOT + '/' + owner + '/RULINGS.md', ROOT + '/' + owner + '/.planning/RULINGS.md'];
const flatSlug = (p) => p.replace(/[^a-zA-Z0-9]+/g, '_');
const dossierPath = (p) => DOSSIER_DIR + '/' + flatSlug(p) + '.md';

// substrate `.api` root, language-agnostic across the three branches: a folder-tier catalog `libs/<lang>/<pkg>/.../.api/x.md` registers against `libs/<lang>/.api`;
// a catalog already sitting at that substrate tier has no higher owner. The two-tier no-redirect law (campaign-method [03]) audits every folder catalog against this root.
const langOf = (p) => (p.match(/^libs\/([^/]+)\//) || [])[1] || '';
const substrateOf = (p) => {
    const lang = langOf(p);
    if (!lang) return '';
    const sub = 'libs/' + lang + '/.api';
    return p.startsWith(sub + '/') ? '' : sub;
};

// owner registries a page forks against: its own directory, the package-root folder registries, and the branch registries.
// Folder README/ARCHITECTURE/RULINGS live at the package root (the component above `.planning`), never inside it; branch registries live at `libs/<lang>/.planning`.
const ownerSurfaces = (paths) => {
    const names = ['README.md', 'ARCHITECTURE.md', 'RULINGS.md'];
    const set = new Set();
    const add = (base) => {
        for (const n of names) set.add(ROOT + '/' + (base ? base + '/' : '') + n);
    };
    for (const p of paths) {
        add(p.lastIndexOf('/') >= 0 ? p.slice(0, p.lastIndexOf('/')) : ''); // registries sitting as the file's own directory siblings
        const pi = p.indexOf('/.planning');
        if (pi >= 0) {
            const owner = p.slice(0, pi); // package root owns the folder registries
            add(owner);
            const cut = owner.lastIndexOf('/');
            if (cut >= 0) add(owner.slice(0, cut) + '/.planning'); // libs/<lang>/.planning owns the branch cross-folder registries
        }
    }
    return [...set];
};

// --- [MODELS] --------------------------------------------------------------------------

const S = { type: 'string' };
const I = { type: 'integer' };
const B = { type: 'boolean' };

const ROUTE_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'missing'],
    properties: {
        files: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['path', 'total', 'prose', 'comments'],
                properties: { path: S, total: I, prose: I, comments: I },
            },
        },
        missing: { type: 'array', items: S }, // targets that resolved to no folder or no pages
    },
};

const FINDING = {
    type: 'object',
    additionalProperties: false,
    required: ['class', 'anchor', 'problem', 'direction', 'move'],
    properties: {
        class: S, // exact [NN]-[CLASS] heading from defects.md, e.g. ENUMERATION_ANCHOR, SAME_DECISION_SPREAD, DELEGATED_ANATOMY, ROSTER_PREAMBLE
        anchor: S, // heading or first few words of the offending passage
        problem: S, // one sentence: why it is fragile or poison
        direction: S, // one sentence: the reframe or the owner it demotes to; for merge/split it NAMES the distinct clauses/facet to preserve
        // fixer disposition, so the fixer need not re-derive it:
        // delete = regenerable frame, no payload; demote = payload to the named owner; merge = same-decision spread, keep distinct clauses;
        // split = compound fork-boundary bullet, mechanism out + facet re-homed; reframe = in-place
        move: { type: 'string', enum: ['delete', 'demote', 'merge', 'split', 'reframe'] },
    },
};
const CROSSFILE = {
    type: 'object',
    additionalProperties: false,
    required: ['fact', 'ownerSibling'],
    properties: {
        fact: S, // the decision this file restates
        ownerSibling: S, // the sibling that owns it, opened and confirmed to carry the FULL fact
    },
};
const ANALYZE_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files'],
    properties: {
        files: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['path', 'findings', 'crossFile', 'indexStatus', 'researchStatus'],
                properties: {
                    path: S,
                    findings: { type: 'array', items: FINDING },
                    crossFile: { type: 'array', items: CROSSFILE }, // duplicates routed to THIS file as the loser; empty when none
                    indexStatus: { type: 'string', enum: ['ok', 'stale', 'missing', 'n/a'] },
                    researchStatus: { type: 'string', enum: ['ok', 'stale', 'missing', 'n/a'] },
                },
            },
        },
    },
};

const DEMOTION = {
    type: 'object',
    additionalProperties: false,
    required: ['payload', 'owner', 'verified', 'setWidth'],
    properties: {
        payload: S, // the decision/invariant/member moved out of prose
        owner: S, // the fence, fence comment, or sibling doc + anchor it demoted into
        verified: B, // target OPENED and confirmed to carry every demoted member
        setWidth: { type: 'string', enum: ['exact', 'wider', 'narrower'] }, // demoted set vs the owner's real set
    },
};
const FIX_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: [
        'file',
        'ok',
        'kind',
        'beforeProse',
        'afterProse',
        'proseReductionPct',
        'beforeComments',
        'afterComments',
        'commentReductionPct',
        'demotions',
        'capabilityConserved',
        'indexLanded',
        'researchRows',
        'rulingsExtracted',
        'rulingsDossier',
        'gateClean',
        'notes',
    ],
    properties: {
        file: S,
        ok: B,
        kind: S,
        beforeProse: I,
        afterProse: I,
        proseReductionPct: I,
        beforeComments: I,
        afterComments: I,
        commentReductionPct: I,
        demotions: { type: 'array', items: DEMOTION }, // proven-demotion ledger; empty only for a pure deletion of regenerable frame
        capabilityConserved: B, // every baseline decision/invariant/boundary/trap survives in prose or a verified demotion
        indexLanded: { type: 'string', enum: ['yes', 'no', 'n/a'] }, // [01]-[INDEX] present after the pass, no when a spec could not land it, n/a for non-spec kinds
        researchRows: I, // terminal [RESEARCH] row count; 0 for (none); -1 for kinds with no research section
        rulingsExtracted: I, // folder-wide rulings removed from this page into the dossier; 0 when none applicable; -1 when the file is not under a .planning/ tree
        rulingsDossier: S, // repo-relative dossier path written for a planning file, "" for a non-planning file
        gateClean: B,
        notes: S, // off-band honesty, judgment-tier gate rows resolved; empty when clean
    },
};
// both adversarial passes batch BATCH pages per agent, so each returns one FIX_SCHEMA receipt per page in a files array, never a bare receipt
const BATCH_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files'],
    properties: { files: { type: 'array', items: FIX_SCHEMA } },
};
const COLLECT_ROW = {
    type: 'object',
    additionalProperties: false,
    required: ['section', 'row'],
    properties: {
        section: { type: 'string', enum: ['PACKAGES', 'SHAPE', 'COLLAPSE', 'STRUCTURE', 'PROCESS'] },
        row: S, // the transcribed RULINGS row, exact template grammar
    },
};
// ONE collector adjudicates every owner's dossiers in a single context, so it dedupes ACROSS owners and tiers a cross-cutting ruling once instead of duplicating it into two registries
const COLLECT_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['owners', 'rejected', 'deferred'],
    properties: {
        owners: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['owner', 'rulingsFile', 'created', 'admitted', 'gateClean'],
                properties: {
                    owner: S, // the package/branch dir whose RULINGS.md this entry wrote
                    rulingsFile: S, // the resolved (or minted) RULINGS.md path
                    created: B, // true when no RULINGS.md existed and it was minted from the template
                    admitted: { type: 'array', items: COLLECT_ROW }, // rows transcribed into THIS file this pass
                    gateClean: B,
                },
            },
        },
        // adjudicated once across the whole extraction set, never per owner
        rejected: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['row', 'reason'],
                properties: {
                    row: S,
                    reason: { type: 'string', enum: ['already-homed', 'merged-with-sibling', 'not-guard-grade', 'contradicts-standing-law'] },
                },
            },
        },
        deferred: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['row', 'tier'],
                properties: { row: S, tier: { type: 'string', enum: ['branch', 'cross-libs'] } }, // scoped wider than any one owner; surfaced, never mis-homed
            },
        },
    },
};

// the terminal deterministic format sweep receipt — no content judgment, only the canonical table re-pad + width/anchor gate over every touched surface
const FORMAT_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['formatted', 'unclean'],
    properties: {
        formatted: I, // files the fix pass rewrote
        unclean: { type: 'array', items: S }, // files the check still fails after the fix pass (judgment-tier rows), reported not hand-forced
    },
};

// --- [DOCTRINE] ------------------------------------------------------------------------

const D = ROOT + '/.claude/skills/docgen/';
const STD = ROOT + '/docs/standards/';
const LAW_FILES = [
    D + 'SKILL.md',
    D + 'references/structure.md',
    D + 'references/defects.md',
    D + 'references/rewriting.md',
    STD + 'style-guide.md',
    STD + 'information-structure.md',
    STD + 'formatting.md',
    D + 'examples/intros.md',
    D + 'examples/lists.md',
    D + 'examples/tables.md',
].join(', ');

const PREAMBLE =
    'WORKING ROOT: ' +
    ROOT +
    ' — every relative path resolves against it; read, write, and edit only under it. ' +
    'Durable prose is agent-facing LAW: a future agent loads this document with no memory of why it was written, and every prose line and every fence comment ' +
    "either changes that agent's next action or poisons it. Two enemies live in an overgrown doc. FRAGILE prose needs updating when the corpus moves without this " +
    'page moving — member rosters, scalar counts, sibling-shape mirrors, version/freshness anchors, cross-references, self-descriptions; each is stale the day after ' +
    "it is written and silently lies thereafter. POISON prose walls the next rebuild — enumeration anchors freezing today's census as the contract, deleted-form " +
    'litanies anchoring to the anti-shape, process-ledger tombstones and decision tags, seals and frozen chants, hedges and weak permission verbs marking undecided ' +
    'ownership. What survives is only LAW an agent cannot regenerate from disk: decisions, invariants, boundaries, ownership rulings, traps — each with an owning ' +
    'subject and owning verb, stated once, timeless.';

const ACID =
    'THE ACID TEST — for every prose sentence: does it stay true, unchanged, across any doctrine-conforming rebuild of the fences it accompanies? Prose couples to ' +
    'intent; the fence couples to shape. A sentence whose truth depends on the current fence body is FRAGILE (it drifts when the fence improves); a sentence naming ' +
    "the current shape is POISON (it walls the next rebuild inside today's design). Both cure the same way: state what the rebuild must preserve, and let the fence " +
    'own the shape. PROSE-CODE BOUNDARY: prose names owners, code carries mechanism — a prose line names at most the owning symbol as a code span and states its law; ' +
    'signatures, parameter lists, member chains, and option rosters belong to the fence, not prose.';

const arm = (extra) =>
    'ARM FIRST — read these law files IN FULL before opening any target (reading a target first inherits its frame): ' +
    LAW_FILES +
    (extra ? ', ' + extra : '') +
    '. Read every target as EVIDENCE, never as guidance.';

const RULINGS_TEMPLATE = D + 'templates/rulings.template.md';
const CAMPAIGN_METHOD = ROOT + '/libs/.planning/campaign-method.md';
// the RULINGS extraction charter — appended to finder, fixer, and collector when a target is under a .planning/ tree
const rulingsLaw =
    '\n\nRULINGS EXTRACTION — a `.planning/` design page sometimes carries FOLDER-WIDE law mis-homed as page-local prose: a settled decision that governs the ' +
    'owning package or branch, whose re-litigation guard (the one why that stops it being re-argued) has NO durable home. That belongs in the folder RULINGS.md ' +
    'decision registry, never restated on a design page. Read IN FULL its owning law before acting: ' +
    RULINGS_TEMPLATE +
    ' (admission bar, closed section vocabulary, tier placement, `(none)` convention, guard-grade row anatomy) and ' +
    CAMPAIGN_METHOD +
    ' [03] rulings discipline. ADMISSION BAR (all must hold): the content is a SETTLED decision (open work or a violation is a card, NOT a ruling — leave it); it ' +
    'governs SIBLINGS or the folder, not just this one page (a page-local design decision STAYS on the page); its why has NO durable home (RULINGS, a README/ARCHITECTURE ' +
    'registry, a manifest, or a fence does not already carry both the what and the why); and it seats in exactly one closed section — `[PACKAGES]` admission/rejection, ' +
    '`[SHAPE]` owner-choice discriminant, `[COLLAPSE]` density refusal, `[STRUCTURE]` layout/retirement, `[PROCESS]` folder-learned working law. A guard-grade row pairs a ' +
    'subject code-span, a decision-verb in owning voice (KEEP / rejected / homes at / stays / does-not-re-enter), the one load-bearing why, the recurring WRONG MOVE it ' +
    'guards against, the correct route, and — for an evidence-bound call — the reopen predicate; one decision per row. NOT FORCED: most pages carry no such ruling; extraction ' +
    'is the rare, high-confidence case, and forcing page-local design into RULINGS pollutes the registry and strips the page. When unsure a line is folder-wide vs ' +
    'page-local, KEEP it on the page.';

// the ownership interrogation — the dominant diagnostic; appended to finder, fixer, and grader mandates with the owner surfaces they fork against
const ownershipClause = (paths) =>
    '\n\nOWNERSHIP INTERROGATION — the dominant diagnostic, run FIRST on every law sentence before ruling it load-bearing: who ELSE already binds this fact? ' +
    'Resolve against three owner classes, each naming a fork. (a) The always-loaded instruction chain — global and project CLAUDE.md at ' +
    CHAIN.join(' and ') +
    ' (their [02] prose-comment and implementation-standard sections): a rule true for every agent this session is CHAIN_RESTATEMENT — delete. ' +
    '(b) A sibling durable doc with a nearer or equal claim — the folder README, ARCHITECTURE, RULINGS registry, or a docgen template: ' +
    'that is TWIN_TRUTH or DELEGATED_ANATOMY — demote to a one-line pointer naming the owner and its one consumed concern. ' +
    '(c) A deterministic tool — the prose gate, an analyzer, a template comment: that is TOOL_ENFORCED_LEAK — defer by name. ' +
    'OPEN these owner surfaces as binding law you fork AGAINST, never as targets to edit (skip any that do not exist on disk): ' +
    JSON.stringify(ownerSurfaces(paths)) +
    '. A sentence that reads load-bearing in isolation is the prime suspect — the fork is invisible until the page is held against these surfaces and no script runs this audit. ' +
    'A demotion is UNPROVEN until you open the named owner and confirm it carries EVERY forked member, across ALL candidate owners — not the first that holds part of it; ' +
    'stopping at the first owner both manufactures false over-deletions and misses real forks. Flag a fork against an owner surface as a finding whose direction names that owner.';

// silent-removal and token-trim discipline — shared by the fixer and the red-team; the register bans force-keeping and grades the cut in tokens, not lines alone
const silentAndTrim =
    '\n\nSILENT REMOVAL — never force-keep a line to protect a floor or out of caution. A line whose load already stands elsewhere — the positive law standing, a fence, ' +
    'a sibling owner, the register itself — is DELETED silently: no tombstone, no "removed X" note, no apologetic pointer minted to stand in for the cut. Keeping weak prose ' +
    '"just in case" is the defect this pass kills; the only survivor is a line whose deletion loses law no other surface holds. A comment the code already shows is deleted ' +
    'whole, not tightened.' +
    '\n\nTRIM TO THE TOKEN — reduction is not line-level alone. Inside every surviving line, cut to the load-bearing words: strip filler, hedges, redundant qualifiers, ' +
    'restated context, and throat-clearing lead-ins; state identical law in a third fewer TOKENS. A page hits its line band and still reads bloated at the character level — ' +
    'measure the cut in words and characters, not lines, and a dense-looking survivor that still carries a cuttable clause is unfinished.';

// version/install anchor ban — appended to finder, fixer, and red-team for EVERY kind; the manifest owns versions, a page never does, but the domain word `Version` as a real member survives
const versionBanLaw =
    '\n\nVERSION AND INSTALL BAN — a durable page carries NO package-manager anchor: a package version number, range, floor, or pin (`Google.Protobuf (version, direct pin)`, `>= N`, ' +
    '`transitive floor`, `the central pin wins the version-conflict resolution`), an install or add command (`dotnet add`, `nuget install`, `uv add`, `pnpm add`, `npm i`), or a ' +
    'freshness / as-of / last-verified stamp. The owning manifest (`Directory.Packages.props`, `pyproject.toml`, `pnpm-workspace.yaml`) is the SOLE version owner; a version, pin, or ' +
    'install line on a page is stale the day the manifest moves — DELETE it whole, the package id left as a bare code span, no `see manifest` tombstone and no substitute negation. ' +
    'THIS IS NOT a ban on the domain word: a type, member, signature parameter, or emitted attribute literally named `Version` / `HttpVersion` / `os.version`, and a wire or protocol ' +
    'version that is part of a format contract, are REAL surface and stay verbatim — ban the package-manager anchor, keep the domain member.';

// .api truth verification — appended to the fixer and red-team for `api`-kind files ONLY; the catalog is a contract, its surface rows live in table cells, and truthfulness outranks trimming
const apiVerifyLaw =
    '\n\nAPI TRUTH — an `.api` catalog is a CONTRACT and truthfulness OUTRANKS trimming: every named surface it lists (type, member, signature, kind, capability) is PROVABLY real or it ' +
    'does not survive, because a false member poisons every consumer that composes this catalog. The surface rows live in TABLE cells — prose you own — not fences. `tools.assay api query` ' +
    'is the polyglot ground-truth rail across all three branches, keyed by the owning package/distribution name and the member: `cd ' +
    ROOT +
    ' && uv run python -m tools.assay api query --key <package> --symbol <member>` (add `--kind`, `--grep`, or `--full` to narrow). It resolves the source kind by language and reports the ' +
    'fidelity it achieved: a C# catalog (path under `libs/csharp`) decompiles the real NUGET/ASSEMBLY through ilspycmd (fidelity `decompiled`) and confirms the package exists through the ' +
    '`nuget` MCP; a PYTHON catalog (`libs/python`) introspects the installed `.venv` object in-process via `inspect` (fidelity `introspected`), so the surface is the EXACT installed ' +
    'version — strictly better than any docs corpus; a TYPESCRIPT catalog (`libs/typescript`) parses the `.d.ts` declarations under `node_modules` (fidelity `declared`). context7 is the ' +
    'FALLBACK ONLY, never the primary py/ts rail: reach for it just when assay returns `unsupported`/`unknown` because the distribution is not installed in the `.venv` or its declaration is ' +
    'absent from `node_modules` (a package the catalog documents but the toolchain has not provisioned) — then `context7` reads the upstream member, and the row is flagged in notes as ' +
    'context7-verified rather than assay-ground-truth so a later provisioned run re-grounds it. CORRECT a proven-wrong cell in place — a misspelled member, a wrong signature, a stale kind, an ' +
    'overclaimed capability — this truthfulness repair is the ONE design-touching move an `.api` catalog authorizes, never invention. A surface you CANNOT verify against either rail is NEVER ' +
    'silently kept as-if-true: flag it in notes with the exact unverifiable symbol. A fence code body proven wrong is flagged in notes, never edited. Record each correction in notes.';

// .api ultra-stacking depth — appended to finder, fixer, and red-team for `api`-kind files ONLY; the catalog exists to extract 100% of an external library's value, never naive single-use
const apiStackingLaw =
    '\n\nAPI ULTRA-STACKING — an `.api` catalog exists to extract 100% of a library`s value, never naive single-import usage. It is the campaign`s deep-stacking source: read ' +
    CAMPAIGN_METHOD +
    ' [02]-[THE_BAR] and [03] external-lib ultra-stacking law before grading its `## [04]-[IMPLEMENTATION_LAW]` (TOPOLOGY, STACKING, LOCAL_ADMISSION, RAIL_LAW). Both `.api` tiers are ' +
    'enumerated in full and mined to OPERATOR DEPTH; an admitted capability the domain admits but the catalog does not surface is a defect the pass CLOSES, and a cited member that ' +
    'cannot be verified is a phantom the pass DELETES. TWO stacking axes both bind. CROSS-`.api`: the `[STACKING]` rows name each sibling `.api` package this one composes WITH and the ' +
    'exact integration shape (`<sibling>`(`.api/<path>`): <shape>) — a shallow, missing, or one-word composition row is a defect; open the sibling catalog and state the real seam. ' +
    'WITHIN-LIB: the catalog surfaces the library`s OWN capabilities stacked to their RICHEST composition — operator overloads chained, fold / pipeline / builder rails, generic-math or ' +
    'typeclass conformances, context / policy threading, zero-copy or span paths, monadic and result rails — never a `using X; X.Do()` reduction. Where the guidance reads single-use or ' +
    'UNDER-mines the surface, DEEPEN it to the true deepest composition, every added claim VERIFIED against the assembly or library per the API-TRUTH law (never invented, never a ' +
    'plausible-sounding phantom). A catalog that merely lists members without the stacking law that composes their combined value is UNFINISHED — the density that survives is deep true ' +
    'capability, not padded prose.';

// markdown-table integrity — appended to fixer and red-team for EVERY kind; a table is repaired in place to docgen discipline, never torn into prose because a prior naive pass could not fit it
const tableIntegrityLaw =
    '\n\nTABLE INTEGRITY — a markdown table is a prose surface you repair IN PLACE to docgen table discipline (information-structure.md, examples/tables.md), never tear into a list or card ' +
    'because a cell ran wide: hoist a value the whole column repeats to the header or a lead sentence, relieve an oversized cell to a lead or a row-owned record after the table, split a ' +
    'crammed multi-value cell into atomic rows, and re-pad. Rows are UNBOUNDED — the 150-column rendered-width cap is the only size law, and a table over it relieves its cells, never sheds ' +
    'rows or flattens to prose. A member roster, signature list, or enum a prior naive pass flattened into `[SLUG]:` cards or a run-on `- a, b, c` bullet is REBUILT as the table it should ' +
    'be; conversion to records is earned only when every in-place relief fails, never by cell width alone.';

// .api structural conformance — appended to fixer and red-team for `api`-kind files ONLY; rebuilds a deformed catalog to the hardened template structurally, fixing signature bloat and torn tables
const apiStructureLaw =
    '\n\nAPI STRUCTURE — land this `.api` catalog TEMPLATE-TRUE against ' +
    templatePath('api') +
    ', read IN FULL: it is the declared schema — the two body modes (ROSTER_FIRST default, CONCEPT_PARTITIONED for a large multi-namespace substrate), the closed column set, the fixed ' +
    '`[04]` sub-labels, the `[01]` field vocabulary, and the abbreviated-signature rule. CONFORM the page to the schema STRUCTURALLY — understand it and rebuild the page to fit, never ' +
    'mechanically paste a block. Repair each recurring deformation. (1) TEARDOWN: a member table torn into `[SLUG]:` card clusters or `- signature — desc` prose bullets is REBUILT AS A ' +
    'TABLE (the teardown was never forced — a code-span signature is a legal atomic cell at any length, and rows are unbounded under the 150-column width cap). (2) SIGNATURE BLOAT: a ' +
    'fully-qualified, fully-param-named signature is abbreviated to the caller`s three facts — member name, argument shape, return shape. C#/TS carry `Owner.member(TypeList)` or ' +
    '`Owner.make(Type) -> Refined` (namespace dropped, parameter TYPES only, `-> Ret` only when load-bearing, a TS generic collapsed to its resolved shape not its type-level machinery); ' +
    'Python carries `member(arg, *, kw) -> Ret` (parameter NAMES + `*`/`/` markers kept, hints stripped, a shared-kwarg family hoisted to one lead line). NEVER a fenced signature block in ' +
    'an `.api` catalog — a fence only bloats the file; the transcription-complete declaration lives on the design page that composes this surface, never here. (3) RUN-ON MEMBERS: a ' +
    '`- Members: a, b, c` mega-bullet or a `[SLUG]: - Members:` card becomes one table row per member, or one inline `[<TYPE>]: `a` `b` `c`` token line for a bare roster. (4) UNIVERSAL ' +
    'RAIL COLUMN: a per-row `[RAIL]` column repeating one value is DELETED — the rail is a single `[01]-[PACKAGE_SURFACE]` field, never a column. (5) COLUMN / LABEL DRIFT: a drifted ' +
    'column renames to the closed set (`[SYMBOL] [TYPE_FAMILY] [CAPABILITY]` for types, `[SURFACE] [SHAPE] [CAPABILITY]` for entrypoints, optional `[CONSUMER]` only where it varies and ' +
    'is load-bearing) and a drifted `[04]` sub-label renames to `[TOPOLOGY] [STACKING] [LOCAL_ADMISSION] [RAIL_LAW]`; a `[<PKG>_TOPOLOGY]` or `[STACKS_WITH]`/`[STACK_LAW]` spelling is ' +
    'the drift. (6) NO `version` FIELD and no install line in `[01]` — the manifest owns versions. Every rebuilt table lands within the 150-column cap by relieving cells, proven by the gate.';

// .api legacy/obsolete purge — appended to fixer and red-team for `api`-kind files ONLY; a catalog carries only the library's current live surface, every outdated anchor silently removed under judgment
const apiLegacyLaw =
    '\n\nNO LEGACY SURFACE — an `.api` catalog presents ONLY the external library`s current, live surface: the one present-day way to use it, so a code-gen consumer never reaches for a ' +
    'dead form. Every anchor to an OUTDATED, OBSOLETE, DEPRECATED, SUPERSEDED, or LEGACY shape is SILENTLY REMOVED. An obsolete member or overload is dropped WHOLE — catalog its live ' +
    'replacement, never the dead form beside a `use Y instead` warning; a `replaced by` / `prior to` / `in older versions` / `the old <X>` / `no longer` caveat is deleted; a ' +
    'version-conditional behavior band collapses to the current behavior; a compatibility note or migration hint dies; and a `- version:` / `- installed:` field or any package version number ' +
    'leaves entirely (the manifest owns versions). This is JUDGMENT work — legacy anchoring hides in many shapes and no regex finds them all, so HUNT every surface (a caveat, a shadowed ' +
    'member, an obsolete overload row, a since/until note, a deprecation mark the source carries): a member the source marks obsolete is not cataloged at all, only its live path. The ONE ' +
    'exception is a domain symbol literally named `Legacy` / `Obsolete` / `Version` that IS the current live API — real surface, kept. Removal is SILENT: no tombstone, no `dropped obsolete X` ' +
    'note, no substitute negation. The positive live surface forecloses the dead form by its absence.';

// the terminal RESEARCH marker, transcribed BYTE-FOR-BYTE from spec.template.md — the exact block every spec page carries under its `## [NN]-[RESEARCH]` heading
const RESEARCH_MARKER =
    '<!-- source-only: research row template:\n' +
    '[TOKEN]-[OPEN|BLOCKED]: <exact question>; <verification route>.\n' +
    '[SPLIT_MEMBER]-[OPEN]: does `shape-core` expose `split_all`; verify against the member rail.\n' +
    '-->';
// terminal RESEARCH-section law for spec pages — appended to the fixer and red-team; brings the section UNDER capability conservation (law re-homed, never deleted) and keeps
// the marker a byte-exact transcription requirement. Three content kinds live under the heading — genuine rows (A), mis-homed law (B), empty (C) — each with one disposition
const researchLaw =
    '\n\nTERMINAL [RESEARCH] SECTION — a spec page ALWAYS ends with a `## [NN]-[RESEARCH]` section (NN contiguous after your edits settle the section count), and it obeys the ' +
    'SAME capability-conservation law as every other surface: content leaves it ONLY by a proven demotion or a proven resolution, NEVER by a bare delete. Three kinds of content ' +
    'appear under the heading and each has ONE disposition — tell them apart by VOICE before touching anything.' +
    '\n\n(A) A GENUINE RESEARCH ROW is epistemic debt: an OPEN or BLOCKED question paired with its verification route. Rewrite each to the exact grammar ' +
    '`- [TOKEN]-[OPEN|BLOCKED]: <exact question>; <verification route>` (TOKEN UPPERCASE_SNAKE), and HARDEN it — a vague question gets the precise unknown, a hand-wave route ' +
    'gets the concrete `.api` entry, member, or harness it resolves against. A row whose question the page`s own settled fences or prose now ANSWER is RESOLVED and deletes ' +
    'WHOLE — no tombstone, no `resolved:` note, no trace — and a row the design has moved past is obsolete and deletes the same way; a row deletes ONLY against evidence the ' +
    'answer is present on the page, never on a guess that it looks answerable, and a still-open question with an unresolved route STAYS and is sharpened.' +
    '\n\n(B) MIS-HOMED LAW is the recurring catastrophe this pass forbids: a `[SLUG] — <present-tense fact>` bullet stating how an owner, algorithm, lattice, or protocol WORKS ' +
    'is DESIGN LAW wearing a research slug, not a question. It is SUBSTANTIVE and capability conservation binds it — RE-HOME it: open the cluster owner it describes, confirm ' +
    'that card or fence already carries the fact (a pure twin then dies as a demotion) or FOLD the missing nuance into that card`s field, and record the demotion. NEVER delete ' +
    'a settled-law bullet as a `non-conforming row`, and NEVER blank a section to `(none)` while it still carries un-rehomed law — writing `(none)` over real design content is ' +
    'a capability-loss FAIL the grader catches. The tell: a question in OPEN/BLOCKED state with a route is (A); a present-tense statement of fact is (B).' +
    '\n\n(C) After (A) and (B) settle, the section carries the byte-exact source-only marker then its rows. The marker is a BYTE-FOR-BYTE transcription from ' +
    D +
    'templates/spec.template.md — copy this block verbatim, every line, backtick, and token; never collapse it to one line, never drop the `[SPLIT_MEMBER]` line, never reword ' +
    'or reformat it.\n' +
    RESEARCH_MARKER +
    '\nBelow the marker: each surviving open/blocked row in the exact grammar, or `(none)` alone on its line ONLY when no genuine open question remains AND every substantive ' +
    'bullet was re-homed. CASES: a MISSING marker (rows but no source-only comment) gets the exact block inserted above the rows; a MANGLED marker (collapsed, truncated, ' +
    'reworded) is REPLACED with the exact block. NEVER invent rows to fill the section, NEVER delete the section or its marker, and keep `## [01]-[INDEX]` in sync with the real ' +
    'section numbers after any renumber this forces.';

// --- [OPERATIONS] ----------------------------------------------------------------------

// the `.api`-tier cross-file finder — the analyzer FLOOR the fixer builds up from, scoped to exactly the whole-tier view a per-file fixer cannot have. It does NOT enumerate the
// per-file defect classes the fixer sweeps unconditionally (structural template drift, version/install anchors, legacy surface, signature bloat, run-on members) — re-reporting them
// doubles work. Its three products are the fixer`s blind spot: cross-file duplication routing, two-tier substrate ownership (no-redirect law, language-agnostic), and the stacking graph.
const apiTierMandate = (owned, wholeTier) => {
    const substrates = [...new Set(wholeTier.map((f) => substrateOf(f.path)).filter(Boolean))];
    return (
        PREAMBLE +
        '\n\n' +
        ACID +
        '\n\nYOU ARE THE .API CROSS-TIER FINDER. Your ONE product is the cross-file map a per-file fixer is structurally blind to, and that an `.api` run gets NOWHERE else — every ' +
        '`.api` catalog closes at Fix, so a duplication or substrate-ownership defect you miss is never caught again. Report ONLY cross-file and cross-tier defects, exhaustive across the ' +
        'WHOLE tier: the per-file classes — structural template drift, version/install anchors, legacy surface, signature bloat, run-on members — are the fixer`s standing law and never ' +
        'your findings.' +
        '\n\n' +
        arm('and the `.api` catalog template ' + templatePath('api')) +
        '\n\nYOU OWN FINDINGS for these ' +
        owned.length +
        ' target files: ' +
        JSON.stringify(owned.map((f) => f.path)) +
        '.\nTHE WHOLE TIER is in view for routing — a duplication winner may sit in ANY of these, and you OPEN it to confirm, never assume: ' +
        JSON.stringify(wholeTier.map((f) => f.path)) +
        '.' +
        (substrates.length
            ? '\nSUBSTRATE TIER(S) — the shared catalogue root each folder catalog registers against (enumerate each with `fd -e md . <root>`): ' +
              JSON.stringify(substrates) +
              '.'
            : '') +
        '\n\nREAD VIA TOOLS, never prompt-preload: use `rg`/`fd`/Read across the tier and substrate to build the map — never attempt to hold every catalog in context. `rg` a shared ' +
        'member name, decision phrase, or roster across the tier to surface duplication fast, then Read the two catalogs to rule on the winner.' +
        '\n\nTHREE cross-file products, each a finding on the file that must CHANGE:' +
        '\n(1) DUPLICATION ROUTING — a decision, invariant, member roster, capability, or mechanism one catalog states that ANOTHER (target tier OR substrate) owns more fully. Route ' +
        'it to the LOSER: record {fact, ownerSibling} in the loser`s crossFile, and add a finding (move=demote, direction naming the winner + its anchor). OPEN the winner and confirm ' +
        'it carries the FULL fact at no narrower set — an unopened winner is an unproven route and the loser keeps its copy.' +
        '\n(2) SUBSTRATE OWNERSHIP (campaign-method [03] no-redirect law) — a folder-tier catalog that duplicates, redirects to, or re-catalogues a package the SUBSTRATE tier already ' +
        'carries is a defect: the folder REGISTERS the substrate package (a one-line pointer naming it), never re-documents its surface. Flag each (move=demote, direction ' +
        '"REGISTER substrate <path>#<anchor>, drop the re-catalogue"). A package the substrate does NOT carry stays folder-owned — never invent a substrate move.' +
        '\n(3) STACKING GRAPH — a `[STACKING]` / `[04]-[STACKING]` row that is one-word, missing, or names a sibling seam shallowly. Flag each (move=reframe, direction naming the real ' +
        'sibling `.api` package and the exact composition shape `<sibling>`(`.api/<path>`): <seam>) so the fixer deepens it to operator depth against the real member.' +
        apiStackingLaw +
        '\n\nFOR EACH owned file carrying at least one cross-file/substrate/stacking finding, return {path, findings:[{class, anchor, problem, direction, move}], crossFile:[{fact, ' +
        'ownerSibling}], indexStatus:"n/a", researchStatus:"n/a"}. Use the exact `[NN]-[CLASS]` heading from defects.md for class. A file with NO cross-file defect is OMITTED — the ' +
        'fixer runs its own per-file depth pass regardless, so an omission is correct, never a gap. Make NO edits and run NO write tools. Return {files:[...]}.'
    );
};

const analyzeMandate = (group) =>
    PREAMBLE +
    '\n\n' +
    ACID +
    '\n\nYOU ARE THE FINDER. You read a group of sibling files and surface every defect for the per-file fixer that follows — you make NO edits. ' +
    'Holding all ' +
    group.length +
    ' files at once is ONE lever — you see cross-file TWIN_TRUTH and SAME_DECISION_SPREAD a single-file fixer is blind to; the DOMINANT lever is the ownership interrogation below.' +
    '\n\n' +
    arm('') +
    ownershipClause(group.map((f) => f.path)) +
    '\n\nTARGETS (read each IN FULL as evidence): ' +
    JSON.stringify(group.map((f) => ({ path: f.path, kind: f.kind }))) +
    '.' +
    '\n\nFOR EACH FILE return a findings list. Classify every suspect passage by its exact `[NN]-[CLASS]` heading in defects.md — the catalog you read IN FULL is the ' +
    'authoritative roster, never a list restated here that drifts the moment a class is minted. Hunt the two newest classes explicitly, an out-of-date reflex ' +
    'misses them: `[26]-[DELEGATED_ANATOMY]` — a page that legally owns a delegated discipline re-spelling the sub-anatomy (row grammar, marker set, touch-point roster, (none) ' +
    'rule) a template or the chain owns, past the obligation delegated to it; keep the obligation, pointer the anatomy, and audit the same entry for a sibling anatomy left ' +
    'inline. `[27]-[ROSTER_PREAMBLE]` — a header entry enumerating a member set whose following detail entries each already expand one member; delete the header when the ' +
    'details carry every member. IMPORTED FRAME — hunt it as the prime structural contaminant: a page whose heading census, section spine, or card grammar does not match its ' +
    'file-kind template (a spec wearing card framing, an ARCHITECTURE wearing a README shape, any doc predating the docgen templates) poisons every future rebuild that reads ' +
    'it as context and inherits its shape; flag it `META_FRAME`, direction = rebuild template-true to the file kind. Cover prose AND fence comment lines; a bloated multi-line ' +
    'comment block, a comment restating adjacent code, or a narration comment is a ' +
    'finding. Do not flag fence code bodies, mermaid bodies, or section-divider comment lines.' +
    versionBanLaw +
    '\n\nHunt every VERSION/INSTALL anchor above as a finding (move=delete, or demote when a capability rides the anchor) — but never flag a real member, parameter, or attribute that ' +
    'merely spells `Version`.' +
    (group.some((f) => f.kind === 'api')
        ? '\n\nAPI TRUTH (this group carries `.api` catalogs): a catalog is a contract — flag any named surface whose spelling, signature, kind, or capability reads WRONG or overclaimed ' +
          'as a finding (move=reframe, direction naming the exact symbol to re-verify), so the fixer grounds it against `tools.assay api query` and corrects it.' +
          apiStackingLaw +
          '\n\nAS THE FINDER on an `.api` catalog, ALSO flag every STRUCTURAL deformation against the hardened template ' +
          templatePath('api') +
          ' (read it): a member table torn into `[SLUG]:` card clusters or `- signature — desc` prose bullets (move=reframe, direction "rebuild as table"); a bloated fully-qualified / ' +
          'fully-param-named signature (direction "abbreviate to member+argshape+return"); a run-on `- Members: a, b, c` bullet or `[SLUG]: - Members:` card (direction "one row per member"); ' +
          'a per-row `[RAIL]` column repeating one value (direction "delete, rail is a [01] field"); a drifted column or `[04]` sub-label (direction naming the closed token); a fenced ' +
          'signature block (direction "abbreviate in-cell, no fence"). ALSO flag shallow ultra-stacking: a `[STACKING]` row that is one-word or missing a real sibling seam, an `[IMPLEMENTATION_LAW]` that ' +
          'reads single-use / under-mines the library surface, and any admitted capability the catalog fails to surface — each a finding (move=reframe or demote) whose direction names ' +
          'the deeper composition or the unexploited member the fixer must mine. ALSO flag every LEGACY anchor for silent removal: an obsolete / deprecated / superseded member or overload, a ' +
          '`use Y instead` / `replaced by` / `in older versions` / `no longer` caveat, a version-conditional band, a `- version:` / `- installed:` field, or any package version number (move=delete, ' +
          'direction "silent-remove, catalog only the live surface") — but never a domain symbol literally named `Legacy`/`Obsolete`/`Version` that is the current API. You make no edits and run no tools; you route the suspect.'
        : '') +
    '\n\nEach finding: {class (the `[NN]-[CLASS]` name), anchor (heading or opening words), problem (one sentence, why fragile or poison), direction (one sentence, the reframe ' +
    'or the owner it demotes to), move (delete|demote|merge|split|reframe)}. move encodes the fixer disposition so it need not re-derive it: delete = regenerable frame, no ' +
    'payload; demote = payload to the named owner in direction; merge = same-decision spread, and direction NAMES every distinct clause to keep; split = compound ' +
    'fork-boundary bullet, and direction names the mechanism to demote and the facet to re-home; reframe = in-place.' +
    '\n\nCROSS-FILE: with all ' +
    group.length +
    ' files in view, find each decision restated across siblings (TWIN_TRUTH or SAME_DECISION_SPREAD across files) and route each duplicate to the ONE file that should LOSE ' +
    "its copy — record it in that loser file's crossFile array as {fact, ownerSibling}. Name the winning sibling AND confirm by opening it that it carries the FULL fact, not a " +
    'narrower form; an unopened winner is an unproven route and the loser keeps its copy until proven. Empty array when none.' +
    '\n\nINDEX/RESEARCH: for a spec-kind file report indexStatus and researchStatus. researchStatus is `ok` ONLY when the terminal `## [NN]-[RESEARCH]` section is present AND ' +
    'its source-only marker comment matches the spec.template.md block byte-for-byte AND every row conforms to `- [TOKEN]-[OPEN|BLOCKED]: <question>; <route>`; a marker that ' +
    'is missing, collapsed to one line, truncated (the `[SPLIT_MEMBER]` line dropped), or reworded is `stale`, and an absent section is `missing`. A RESEARCH section carrying ' +
    'SUBSTANTIVE settled-law content — a `[SLUG] — <present-tense fact>` bullet describing how an owner or algorithm WORKS, not an OPEN/BLOCKED question with a route — is ' +
    'MIS-HOMED law, NOT a research row: report researchStatus `stale` AND flag each such bullet as a finding (move=demote, or split for a compound bullet) whose direction names ' +
    'the cluster owner to re-home it into, so the fixer moves it under capability conservation and never deletes it. indexStatus is `ok` when ' +
    '`## [01]-[INDEX]` is present and its numbers match the real sections, else `stale`/`missing`. For every non-spec kind both are n/a.' +
    (group.some((f) => underPlanning(f.path))
        ? rulingsLaw +
          '\n\nAs the FINDER, flag each folder-wide ruling candidate you find in a planning target as a normal finding with move=demote and direction beginning ' +
          '"RULINGS [SECTION]: " naming the section and the guard — the fixer extracts it. Flag ONLY high-confidence admission-bar passes; a page-local design decision ' +
          'is not a candidate.'
        : '') +
    '\n\nReturn {files:[{path, findings, crossFile, indexStatus, researchStatus}]}. No edits, no gate, no prose written to disk.';

const fixMandate = (f, seed) => {
    const tpl = templatePath(f.kind);
    const spec = f.kind === 'spec';
    const hasSeed = !!seed;
    const planning = underPlanning(f.path);
    const dossier = dossierPath(f.path);
    return (
        PREAMBLE +
        '\n\n' +
        ACID +
        '\n\nYOU ARE THE FIXER for ONE file. A finder pass already read this file with its siblings; its findings are HINTS that seed your work, never the ceiling — ' +
        'you run your own full hostile hunt over the whole page. A rewrite is a reframe from the extracted payload, never a shorter paraphrase of the old sentence.' +
        '\n\n' +
        arm(
            tpl
                ? 'and the file-kind template you land this file against: ' + tpl
                : 'this file is a general durable page — its shape is the docgen page-shape law in formatting.md [03]-[PAGE_SHAPE]',
        ) +
        ownershipClause([f.path]) +
        '\n\nTARGET: ' +
        f.path +
        ' (kind: ' +
        f.kind +
        ') — read it IN FULL as evidence. Baselines: prose ' +
        f.prose +
        ' lines, comments ' +
        f.comments +
        ' lines. Also read the nearest ancestor README.md as your register exemplar if one exists — leads that legislate in owning voice, dense with the ' +
        "folder's own vocabulary, zero narration; your leads read as the same hand." +
        '\n\nFINDER FINDINGS for this file' +
        (hasSeed
            ? f.kind === 'api'
                ? ' (the cross-file / substrate / stacking FLOOR you EXECUTE — not hints to re-derive):'
                : ' (seed, not ceiling):'
            : f.kind === 'api'
              ? ' (no cross-file defect routed here — normal: the cross-tier finder reports only real routes, so run your per-file depth pass and add nothing cross-file you cannot see):'
              : ' (NONE — the finder pass DROPPED this file; run a full cold hostile hunt, no hints exist):') +
        '\n' +
        JSON.stringify(hasSeed ? { findings: seed.findings, crossFile: seed.crossFile } : { findings: [], crossFile: [] }) +
        (f.kind === 'api'
            ? '\n\nANALYZER FLOOR — the directives above are AUTHORITATIVE, not hints: a whole-tier finder held the ENTIRE `.api` tier and its language substrate in one view you lack ' +
              'from this one file, and routed the cross-file duplication, substrate-registration, and stacking-deepening work. EXECUTE each — open the named winner/substrate owner, ' +
              'confirm it carries the full fact, demote your copy per the DEMOTE-VERIFY law, deepen each flagged `[STACKING]` row to the named sibling seam. Your own pass adds the ' +
              'per-file DEPTH the finder could not reach — template-true structure, decompile-verified member truth, version/legacy purge — above this floor, never a second cross-file ' +
              'hunt: a cross-file defect the floor did not route is beyond one file`s view and stays.'
            : '') +
        '\n\nTERRITORY — prose surfaces you rebuild: H1 leads, every section bullet and paragraph, list entries, table leads, and COMMENT LINES inside fences. ' +
        'UNTOUCHED — fence code bodies (signatures, types, members, cases, fields, logic, imports), mermaid diagram bodies, and section-divider comment lines ' +
        '(style-correct a wrong divider label, never delete one). You are a prose surgeon, never a design editor: no owner, case, member, or design decision changes.' +
        '\n\nLAND THE FILE TEMPLATE-TRUE for its kind against ' +
        (tpl || 'the docgen page-shape') +
        '. ' +
        (spec
            ? 'This is a SPEC page: exactly two strong lead paragraphs at the README exemplar bar — a telos lead (the capability this page owns, its piece in the ' +
              'folder system, the boundary it holds) and a composition lead (the settled facts a rebuild composes before editing: reused axes, seam obligations, ' +
              'wire names, rails, policy rows); then `## [01]-[INDEX]` (one line per cluster, `- [NN]-[TOKEN]: <hook>`, built when absent, rebuilt when stale); then the ' +
              'cluster sections renumbered contiguously. The terminal RESEARCH section is specified below and is mandatory.'
            : 'Land every section, marker, and terminal section its template declares; card and registry kinds keep their own closed marker vocabulary and terminal ' +
              'markers exactly as the template comment declares them.') +
        (spec ? researchLaw : '') +
        '\n\nPROSE REDUCTION: land the page at ' +
        PROSE_LO +
        '-' +
        PROSE_HI +
        '% fewer PROSE lines than the ' +
        f.prose +
        ' baseline. PROSE is non-blank lines OUTSIDE code fences, NOT total file lines — fence code bodies stay UNTOUCHED, so a fence-heavy page keeps nearly its whole ' +
        'total-line count while its prose halves; never chase a total-file reduction and never touch a fence to hit a number. The band applies to the prose measure alone. ' +
        'The demotion ledger, never the band, is the master: zero capability loss outranks any percent. The cut comes from defect-kill and density — ' +
        'delete narration, restatement of fence content, enumeration anchors, deleted-form litanies, process ledger, hedges, meta frames, twin truths, chain restatements; ' +
        'tighten every survivor to the load-bearing-word law. REMOVAL IS THE DEFAULT REPAIR, reframe the exception: a forked, hedged, restated, or chain-bound line is ' +
        'deleted outright — no replacement, no note explaining the removal, and never a substitute `never X` / `not Y` clause minted to stand in for the cut (fresh ' +
        'NEGATION_ONLY sediment; naming a forbidden form primes its re-emission). The positive law already standing forecloses the removed form. Reframe only where the line ' +
        'carries load no other surface holds.' +
        silentAndTrim +
        versionBanLaw +
        tableIntegrityLaw +
        (f.kind === 'api' ? apiVerifyLaw + apiStackingLaw + apiStructureLaw + apiLegacyLaw : '') +
        '\n\nCOLLAPSE IS A RESTRUCTURE, never a brute-delete: a SAME_DECISION_SPREAD merges pure restatements into the single strongest spelling and keeps every DISTINCT ' +
        'clause as its own clause or entry — only true restatements die, and a neighbor separating a different failure class or carrying a false-positive discriminator is ' +
        'distinct law. A nuance lost in the collapse is the same defect as the accumulation; resolution must rise while lines fall, and a merged form is never a concatenated ' +
        'mega-entry where a structured container serves. After every fold, re-scan the destination for a fresh twin the fold minted. SEDIMENT: an oversized single list item ' +
        'is a compressed section wearing a hyphen — classify its fragments (law, mechanism, consequence, exception, example, duplicate) and route each to its container per ' +
        'rewriting.md [05]-[LIST_REPAIR], never shred it into sibling bullets unclassified; a guard justified only by a past failure the current surface, tooling, or agent can ' +
        'no longer commit dies with its dead threat.' +
        '\n\nDEMOTE-VERIFY — capability leaves prose only by PROVEN demotion, and capability loss is the one forbidden move: every decision, invariant, boundary ruling, and ' +
        'trap survives, in fewer words or demoted to the owner that keeps it true. Before a prose copy dies, OPEN the destination owner and confirm it carries EVERY demoted ' +
        'member — across ALL candidate owners (the ownership-interrogation surfaces above), not the first that holds part of it; a fact a RULINGS registry owns more precisely ' +
        'than the architecture doc is a FALSE over-deletion if you stop at the doc. When a prose enumeration demotes to a roster owner, re-verify the surviving pointer inherits ' +
        "NO wider set than the law states — three managers must not arrive as the owner's eight (POINTER-SET-WIDENING). An unopened target is an unproven demotion; if no opened " +
        'owner holds the full set, the law is NOT a fork — keep it here. SPLIT BEFORE DEMOTE at a fork boundary: a compound bullet fusing a charter/bar facet with ' +
        'genuinely-forkable mechanism is split first — mechanism demoted to its owner, facet re-homed at its peer bar — never cut whole because its mechanism has an owner ' +
        'elsewhere; the mirror over-cut is a distinct clause that only RESEMBLES a fork, so classify before cutting. Each crossFile entry is a cross-file demotion: open the ' +
        "named ownerSibling, confirm the full fact, delete this file's copy, and record it as a demotions row. RECORD every demotion: {payload (the decision/member moved out " +
        'of prose), owner (the fence, fence comment, or sibling doc + anchor it demoted into), verified (target opened and confirmed), setWidth (exact|wider|narrower vs the ' +
        "owner's real set)}. A pure deletion of regenerable frame demotes nothing and records nothing. Set capabilityConserved true only when every baseline decision, " +
        'invariant, boundary, and trap survives in prose or a verified demotion.' +
        '\n\nCOMMENT LADDER: cut non-load-bearing fence comments by ~' +
        COMMENT_TARGET +
        '%. Per comment: delete a no-load comment whole (narration, code restatement, a human-facing tour); tighten a load-bearing survivor in place (3 lines to ' +
        '2, 2 to 1 wherever the prose fits); re-wrap toward the 150-column cap, lead packed and tail carrying real width; inline a one-line survivor governing one ' +
        'line as its trailing tail. A constraint the code cannot show survives the cut; a section divider is never deleted. The surviving comment count is a ' +
        'consequence of the ladder, not a quota — a page with only load-bearing comments reports a low cut and that is correct.' +
        '\n\nHONESTY OVER BAND: if an honest full-register rebuild lands outside a band, the register wins — report the true numbers and say why in notes. A padded ' +
        'count, an invented research row, an unproven demotion recorded verified, or an unrun gate reported clean is a defect worse than a missed band.' +
        (planning
            ? rulingsLaw +
              '\n\nEXTRACT-AND-DOSSIER: the ownership interrogation already opened this folder`s RULINGS.md, so you know what it already homes. For each admission-bar' +
              '-passing folder-wide ruling THIS page ORIGINATES that RULINGS does NOT already carry: (1) REMOVE it from the page — the page then composes the ruling ' +
              'silently, no restatement and no pointer that re-narrates it (a page restating a ruling RULINGS ALREADY homes is a plain deletion demoted to the existing ' +
              'owner, never a dossier candidate — no duplication). (2) Author the transcribe-ready RULINGS row in exact template grammar. (3) Record it as a demotion ' +
              'whose owner is the dossier + section, verified true, setWidth exact, so the grader reads the removal as a PROVEN move never a loss. WRITE THE DOSSIER ONLY ' +
              'when this page originates at least one such ruling: `mkdir -p ' +
              DOSSIER_DIR +
              '` then write ' +
              dossier +
              ' — per candidate a `## [SECTION]` line (the target RULINGS section), the row line beneath it, and a `<!-- source: ' +
              f.path +
              '#<anchor> | tier: package|branch|cross-libs | dedup: <short-key> -->` metadata comment for the collector. A page with NO folder-wide homeless ruling ' +
              'writes NO dossier file at all — extraction is NEVER forced and an empty stub is dead noise the collector must sift, so leave the path unwritten, set ' +
              'rulingsExtracted 0 and rulingsDossier "". When you DO extract, set rulingsExtracted to the row count and rulingsDossier to ' +
              dossier +
              '.'
            : '\n\nRULINGS: this file is not under a `.planning/` tree and owns no RULINGS.md — set rulingsExtracted -1 and rulingsDossier "".') +
        '\n\nGATE: after the rebuild run `cd ' +
        ROOT +
        ' && uv run .claude/skills/docgen/scripts/prose_gate.py fix --write ' +
        f.path +
        '` then `uv run .claude/skills/docgen/scripts/prose_gate.py ' +
        f.path +
        '`; resolve judgment-tier SKIP rows by hand; gateClean is the second command exiting clean.' +
        '\n\nRECEIPT: re-measure afterProse (' +
        PROSE_MEASURE +
        ') and afterComments (' +
        COMMENT_MEASURE +
        '). Return {file, ok, kind, beforeProse (' +
        f.prose +
        '), afterProse, proseReductionPct, beforeComments (' +
        f.comments +
        '), afterComments, commentReductionPct, demotions (the proven-demotion ledger, empty for a pure-frame deletion), capabilityConserved, indexLanded (' +
        (spec ? 'yes when [01]-[INDEX] is present, no if a spec page could not land it' : 'n/a') +
        '), researchRows (' +
        (spec ? 'terminal row count, 0 for (none)' : '-1') +
        '), rulingsExtracted (' +
        (planning ? 'rows written to the dossier, 0 for none applicable' : '-1') +
        '), rulingsDossier (' +
        (planning ? dossier : '""') +
        '), gateClean, notes}.'
    );
};

// the red-team runs over a GROUP of already-fixed pages (up to BATCH) — shared cold-review law stated once, then a per-file block carrying each page`s baseline, predecessor receipt, and kind-specific hunt
const redteamMandate = (group) => {
    const paths = group.map((g) => g.f.path);
    const anySpec = group.some((g) => g.f.kind === 'spec');
    const anyPlanning = group.some((g) => underPlanning(g.f.path));
    const anyApi = group.some((g) => g.f.kind === 'api');
    const perFile = group
        .map((g, i) => {
            const f = g.f;
            const fix = g.fix;
            const tpl = templatePath(f.kind);
            const spec = f.kind === 'spec';
            const planning = underPlanning(f.path);
            const dossier = dossierPath(f.path);
            return (
                '\n\n--- FILE ' +
                (i + 1) +
                '/' +
                group.length +
                ': ' +
                f.path +
                ' (kind: ' +
                f.kind +
                ') --- ' +
                'ORIGINAL HEAD baseline: prose ' +
                f.prose +
                ' lines, comments ' +
                f.comments +
                '. `cd ' +
                ROOT +
                ' && git show HEAD:' +
                f.path +
                '` is the pre-pass baseline; disk is the predecessor`s output — diff them for what it cut, kept, and reworded. Predecessor receipt: ' +
                JSON.stringify({
                    afterProse: fix.afterProse,
                    afterComments: fix.afterComments,
                    proseReductionPct: fix.proseReductionPct,
                    notes: fix.notes,
                }) +
                '; it left this page at ~' +
                fix.afterProse +
                ' prose lines — drive the FURTHER ' +
                REDTEAM_FURTHER +
                '% off THAT state. Land template-true against ' +
                (tpl || 'the docgen page-shape') +
                '.' +
                (spec
                    ? ' SPEC: sync `## [01]-[INDEX]` to the real section numbers, and the RESEARCH law below binds this file — diff `## [NN]-[RESEARCH]` against HEAD, RESTORE any ' +
                      'settled-law `[SLUG]` bullet the predecessor deleted or blanked to `(none)` and re-home it per (B), then harden the surviving rows per (A).'
                    : '') +
                (f.kind === 'api'
                    ? ' API CATALOG: the surface rows are TABLE cells (prose), not fences — the API-TRUTH and API-ULTRA-STACKING law below bind this file; re-verify every named surface ' +
                      'against the assembly before trimming, correct a proven-wrong cell, and deepen any shallow single-use `[STACKING]`/`[IMPLEMENTATION_LAW]` guidance to the true deepest ' +
                      'cross-`.api` and within-library composition.'
                    : '') +
                (planning
                    ? ' PLANNING: if the predecessor wrote ' +
                      dossier +
                      ', HARDEN every row to guard-grade anatomy; if it MISSED a genuine admission-bar folder-wide ruling still on the page, extract it now — remove from page, ' +
                      'record the demotion, and WRITE ' +
                      dossier +
                      ' with the row when no dossier exists yet. rulingsExtracted is the CUMULATIVE row count standing in the dossier after your pass (predecessor rows + yours), ' +
                      'with rulingsDossier its path; a page that originates NO folder-wide ruling and has no dossier on disk leaves the path unwritten (no empty stub), ' +
                      'rulingsExtracted 0, rulingsDossier ""; NEVER duplicate a row the dossier or the folder RULINGS.md already holds.'
                    : ' RULINGS: not under `.planning/` — rulingsExtracted -1, rulingsDossier "".')
            );
        })
        .join('');
    return (
        PREAMBLE +
        '\n\n' +
        ACID +
        '\n\nYOU ARE THE RED-TEAM for ' +
        group.length +
        ' already-fixed pages — the terminal, most aggressive pass. Process EACH file block below in turn. A predecessor ran one ~' +
        PROSE_LO +
        '-' +
        PROSE_HI +
        '% reduction pass over each; you hold every output NAIVE, INCOMPLETE, and LITTERED until disk proves otherwise, and you both REPAIR its weak work AND drive a SECOND ' +
        'reduction. Read ' +
        CAMPAIGN_METHOD +
        ' [03] RED-TEAM discipline: a pre-mortem that rebuilds rather than annotates, a full cold re-review of every conformance dimension, the current shape never its own ' +
        'defense ("it also reads fine" refutes nothing).' +
        '\n\n' +
        arm('and the file-kind template named in each file block below') +
        ownershipClause(paths) +
        '\n\nHUNT WHAT A FIRST PASS ALWAYS MISSES, per file: litter it introduced (a tombstone note explaining its own removal, a substitute `never X` minted for a cut, a fold that ' +
        'left a fresh twin at the destination, a pointer that re-narrates instead of naming its owner, a `## [NN]-[RESEARCH]` section BLANKED to `(none)` or stripped of its `[SLUG]` ' +
        'settled-law bullets the predecessor mistook for junk rows), weak or bloated survivors it kept out of caution, sediment it softened instead of killing, an imported frame it ' +
        'left standing, and char-level padding under a line band it already hit. Read each file IN FULL before touching it.' +
        '\n\nADJUDICATE WHAT IT REMOVED — the diff`s deleted lines are half the evidence and the half a second pass usually skips: read EVERY line the predecessor cut and rule on it. ' +
        'A cut that dropped a real decision, invariant, boundary ruling, or trap is RESTORED from the baseline; a cut that removed narration, restatement, frame, or hedge STANDS. Any ' +
        'demotion it claimed is proven by OPENING the named owner and confirming that owner carries the full set at exact width — an unproven demotion restores to the page. On an `.api` ' +
        'catalog a cut that dropped a verified member, its call shape, its capability, or a consumer-facing trap is real loss and restores; only bloat, narration, and dead legacy stay cut.' +
        silentAndTrim +
        versionBanLaw +
        tableIntegrityLaw +
        '\n\nBE ADVERSARIAL ON CONTENT QUALITY, never wording alone: this file is worked by an agent with NO memory of why it was written, so judge every surviving line by what it does ' +
        'to that agent`s next action. POISON prose — a frame, roster, count, or named shape that walls the next rebuild inside today`s design — and FRAGILE prose — a mirror, cross-reference, ' +
        'or sibling-shape restatement that lies the day the corpus moves — are REMOVED even when they read well; fluency is not value, and a dense-looking line carrying no law is the prime ' +
        'suspect. Removal stays evidence-based, never random: the bar is that deleting the line loses law no other surface holds.' +
        '\n\nTERRITORY and CAPABILITY are the fixer`s exactly: prose surfaces and fence COMMENTS only; fence code bodies, mermaid bodies, and section dividers UNTOUCHED. ' +
        'Capability conservation is absolute — aggression cuts NOISE, never LAW: every decision, invariant, boundary ruling, and trap survives in fewer words or a proven demotion. ' +
        'Before returning, re-read your own output against the HEAD baseline and restore anything real either you or the predecessor cut: the page you hand back is FINISHED work, never a ' +
        'draft, and every defect you can see is one you fix now.' +
        (anySpec ? researchLaw : '') +
        (anyPlanning ? rulingsLaw : '') +
        (anyApi ? apiVerifyLaw + apiStackingLaw + apiStructureLaw + apiLegacyLaw : '') +
        '\n\nFILE BLOCKS:' +
        perFile +
        '\n\nPER FILE, after the rebuild run `cd ' +
        ROOT +
        ' && uv run .claude/skills/docgen/scripts/prose_gate.py fix --write <file>` then the check; gateClean is that check exiting clean. Return {files:[<one receipt per file block ' +
        'above, IN ORDER>]}, each receipt {file, ok, kind, beforeProse (the ORIGINAL HEAD baseline, so proseReductionPct reads the cumulative HEAD->now cut), afterProse (your final ' +
        're-measure via ' +
        PROSE_MEASURE +
        '), proseReductionPct, beforeComments, afterComments, commentReductionPct (' +
        COMMENT_MEASURE +
        '), demotions (the cumulative proven ledger), capabilityConserved, indexLanded, researchRows, rulingsExtracted, rulingsDossier, gateClean, notes}.'
    );
};

// the verifier runs over a GROUP of rebuilt pages (up to BATCH) — the cumulative HEAD->now diff is its one lever, and it REPAIRS what it finds rather than reporting it.
// The `adversarial` row keeps `.api` catalogs out of this pass entirely (they close at Fix), so no catalog law arms here.
const verifyMandate = (group) => {
    const paths = group.map((g) => g.f.path);
    const anySpec = group.some((g) => g.f.kind === 'spec');
    const anyPlanning = group.some((g) => underPlanning(g.f.path));
    const perFile = group
        .map((g, i) => {
            const f = g.f;
            const tpl = templatePath(f.kind);
            return (
                '\n\n--- FILE ' +
                (i + 1) +
                '/' +
                group.length +
                ': ' +
                f.path +
                ' (kind: ' +
                f.kind +
                ') --- ORIGINAL HEAD baseline: prose ' +
                f.prose +
                ' lines, comments ' +
                f.comments +
                '. `cd ' +
                ROOT +
                ' && git show HEAD:' +
                f.path +
                '` is the pre-pass baseline; disk is the current rebuilt state. Its final receipt: ' +
                JSON.stringify({
                    afterProse: g.fix.afterProse,
                    demotions: g.fix.demotions,
                    capabilityConserved: g.fix.capabilityConserved,
                    notes: g.fix.notes,
                }) +
                '. Template: ' +
                (tpl || 'the docgen page-shape') +
                '.' +
                (underPlanning(f.path)
                    ? ' PLANNING: open ' +
                      dossierPath(f.path) +
                      ' and confirm every ruling removed from the page is present there in full; rulingsExtracted in your receipt is the CUMULATIVE row count standing in that ' +
                      'dossier on disk (0 only when no dossier exists), rulingsDossier its path.'
                    : '')
            );
        })
        .join('');
    return (
        PREAMBLE +
        '\n\n' +
        ACID +
        '\n\nYOU ARE THE VERIFIER for ' +
        group.length +
        ' pages a fixer then a red-team rebuilt. You are ADVERSARIAL and you WRITE: every defect you find you FIX in place, on the page, now — you never merely grade, report, or hand a ' +
        'residual onward. Nothing follows you, so the page you leave is the finished page.' +
        '\n\n' +
        arm('and the file-kind template named in each file block below') +
        ownershipClause(paths) +
        '\n\nTHE DIFF IS YOUR ONE LEVER. For each file, diff the HEAD baseline against the current disk state and read the CUMULATIVE change hostilely — two aggressive passes ran over ' +
        'this page and the compounding is where real law dies. Work the DELETED lines hardest: a removal is correct only against evidence. Repair each of five defects in place. ' +
        '(1) LOST LAW — a decision, invariant, boundary ruling, or trap present in the baseline and absent now, with no proven owner holding it: RESTORE it, rewritten to the register, ' +
        'never pasted back verbatim. (2) UNPROVEN DEMOTION — for every demotion the ledger claims, OPEN the named owner across ALL candidate owners and confirm it carries EVERY demoted ' +
        'member at exact set width; if it does not, restore the law to this page, and watch POINTER-SET-WIDENING (three members demoted to an owner that now implies eight is wrong law). ' +
        '(3) FRESH TWIN — a fold that re-duplicated a rule at its destination: delete the copy at the losing site. (4) RESIDUAL FRAME — read the page as the COLD REBUILD AGENT working ' +
        'from it alone: name the framing assumption it stands on (an inherited corpus shape, a heading census that does not match its file-kind template, a frozen roster, a report frame), ' +
        'and if a rebuild would inherit that frame, REFRAME the page; "the current shape also reads fine" refutes nothing. (5) LITTER either predecessor introduced — a tombstone ' +
        'explaining its own removal, a substitute `never X` minted for a cut, a pointer that re-narrates instead of naming its owner: delete it whole.' +
        (anySpec
            ? ' A `[SLUG] — <fact>` bullet that lived under the baseline `## [NN]-[RESEARCH]` heading is baseline LAW: if the section was blanked to `(none)` or those bullets dropped ' +
              'without a proven re-home into the cluster owner they describe, RESTORE and re-home them.'
            : '') +
        silentAndTrim +
        versionBanLaw +
        tableIntegrityLaw +
        '\n\nTERRITORY is the fixer`s exactly: prose surfaces and fence COMMENTS only; fence code bodies, mermaid bodies, and section dividers UNTOUCHED. Restoration is NOT a licence to ' +
        're-bloat — you restore only law no other surface holds, in the fewest words that carry it, and you keep cutting any noise the predecessors left. A page that lost nothing and ' +
        'carries no litter is left alone and reported honestly; inventing work to look busy is its own defect.' +
        (anyPlanning ? rulingsLaw : '') +
        '\n\nFILE BLOCKS:' +
        perFile +
        '\n\nPER FILE, after your repairs run `cd ' +
        ROOT +
        ' && uv run .claude/skills/docgen/scripts/prose_gate.py fix --write <file>` then the check; gateClean is that check exiting clean. Return {files:[<one receipt per file block ' +
        'above, IN ORDER>]}, each receipt {file, ok, kind, beforeProse (the ORIGINAL HEAD baseline), afterProse (your final re-measure via ' +
        PROSE_MEASURE +
        '), proseReductionPct, beforeComments, afterComments, commentReductionPct (' +
        COMMENT_MEASURE +
        '), demotions (the ledger as it now stands, every row re-proven by you), capabilityConserved, indexLanded, researchRows, rulingsExtracted, rulingsDossier, gateClean, notes ' +
        '(what you restored, re-homed, or deleted; empty when the page needed nothing)}.'
    );
};

// ONE collector for the whole run: it holds every owner's dossiers in one context, which is the only way cross-owner dedup and correct tier placement are decidable
const collectMandate = (targets) =>
    PREAMBLE +
    '\n\nYOU ARE THE COLLECTOR — the SINGLE adjudicator for every folder-wide ruling this run extracted, across every owner. You transcribe survivors into the owning ' +
    '`RULINGS.md` decision registries and nothing else. Nothing is admitted by default; the registry is a guard against re-litigation, never a dumping ground, and a run ' +
    'that admits zero rows is a correct outcome.' +
    rulingsLaw +
    '\n\nGROUND YOURSELF FIRST — read ALL of these IN FULL before judging any candidate, because admission is decided against standing law, never against the dossier alone: ' +
    'the always-loaded instruction chain ' +
    CHAIN.join(' and ') +
    ' (a candidate the chain already binds is CHAIN_RESTATEMENT, rejected); every `.md` under ' +
    ROOT +
    '/libs/.planning/ — the Tier-0 corpus law (campaign method, architecture, authoring standard, planning targets, and the cross-`libs/` RULINGS registry) that governs ' +
    'what a ruling IS and where it seats; the rulings template ' +
    RULINGS_TEMPLATE +
    ' (admission bar, closed section vocabulary, tier placement, `(none)` convention, guard-grade row anatomy); and EVERY target `RULINGS.md` listed below, each read in ' +
    'full as its own admission authority.' +
    '\n\nTARGETS — each owner with its candidate RULINGS.md paths (nearest EXISTING wins, package tier before branch tier; if neither exists, mint the first from the ' +
    'template — charter lead plus the closed sections each marked `(none)` — and set created true) and the dossiers its pages wrote: ' +
    JSON.stringify(targets) +
    '. Read every dossier listed — each exists only because a page originated at least one real ruling, so there are no empty stubs to sift.' +
    '\n\nADJUDICATE the WHOLE candidate set at once — holding every owner`s dossiers together is your one lever, and it decides two things a per-owner pass cannot. ' +
    '(a) CROSS-OWNER DEDUP — the same ruling extracted from two pages, or from two different owners, is ONE row merged to the single strongest guard-grade spelling ' +
    '(reason=merged-with-sibling for each dropped copy); near-similar candidates fold into one higher-resolution row where every distinct clause survives, never a ' +
    'concatenated mega-row. (b) TIER — a ruling that governs siblings ACROSS owners does not belong in either package registry: it seats at the branch or cross-`libs/` ' +
    'tier, recorded in deferred with its tier and written nowhere else. Then per candidate: (c) ALREADY-HOMED — the resolved RULINGS.md, a README/ARCHITECTURE registry, ' +
    'a manifest, the instruction chain, or a fence already carries the fact AND its why → reject (reason=already-homed); the page-removal already stands and no row is ' +
    'minted, so no duplication. (d) CONTRADICTION — a candidate that conflicts with a ruling already standing in any registry you read is rejected ' +
    '(reason=contradicts-standing-law), never silently written beside the rule it contradicts. (e) GUARD-GRADE — a row missing its wrong-move, route, or reopen predicate, ' +
    'or carrying two decisions, is repaired to anatomy or split into siblings; an irreparably non-guard candidate is rejected (reason=not-guard-grade).' +
    '\n\nRECONCILE TO CURRENT STANDING POLICY — a candidate extracted from a design page can carry a RATIONALE or discriminant that predates the current libs/.planning ' +
    'policy: a stale license framing, a superseded owner-choice, an admission reason the standing law has since replaced. Before admitting, reconcile its framing against the ' +
    'policy you read and admit the CORRECTED form aligned to current standing law — NEVER transcribe the source page`s outdated framing verbatim. State every admitted rule as ' +
    'standing FACT in owning voice with NO meta-reference to the policy behind it (no `per the license policy`, no `as documented in`, no doc pointer); the guard names the wrong ' +
    'move and the correct route, and the policy stands behind it silently. Where the candidate`s DECISION itself — not merely its framing — conflicts with current standing ' +
    'policy, reject it (reason=contradicts-standing-law) rather than admit a corrected contradiction.' +
    '\n\nTRANSCRIBE the survivors into each resolved RULINGS.md: append each at its section`s tail in arrival order (adjacency is arrival, never taxonomy), replace a ' +
    'section`s `(none)` when you first populate it, keep the closed section order, and renumber headings contiguously. Subjects and members are code spans in verified ' +
    'spelling; slugs UPPERCASE_SNAKE; paths repo-relative. Write ONLY inside the owners listed above, and do NOT re-open or edit the source design pages — they are ' +
    'already trimmed; you write RULINGS.md files alone.' +
    '\n\nGATE each RULINGS.md you wrote or minted: `cd ' +
    ROOT +
    ' && uv run .claude/skills/docgen/scripts/prose_gate.py fix --write <rulingsFile>` then the check on the same file; resolve judgment-tier SKIP rows by hand; that ' +
    'file`s gateClean is its check exiting clean.' +
    '\n\nRETURN {owners:[{owner, rulingsFile, created, admitted:[{section, row}], gateClean}], rejected:[{row, reason}], deferred:[{row, tier}]} — one owners entry per ' +
    'registry you touched (omit an owner whose every candidate was rejected or deferred), with rejected and deferred adjudicated once across the whole set.';

// the terminal format sweep — one deterministic pass, no prose judgment: re-pad every touched surface to the canonical table render and re-run the width/anchor gate so the run closes proven clean under the 150-column cap
const formatMandate = (paths) =>
    'WORKING ROOT: ' +
    ROOT +
    '. DETERMINISTIC FORMAT SWEEP — no prose judgment, no content edits, no fence or table-cell rewriting by hand: run the docgen gate`s canonical table re-pad and ' +
    'width/anchor check over every path below, so the run closes with every table rendered within the 150-column cap. PER FILE in ' +
    JSON.stringify(paths) +
    ': `cd ' +
    ROOT +
    ' && uv run .claude/skills/docgen/scripts/prose_gate.py fix --write <file>` then `uv run .claude/skills/docgen/scripts/prose_gate.py <file>`. The fix pass applies the ' +
    'deterministic repairs its Repair vocabulary owns (table re-pad the load-bearing one here) and is idempotent; the check reports the verdict. A file the check STILL fails ' +
    'after the fix pass carries a judgment-tier row — report its path in unclean, NEVER hand-force it. Return {formatted: <count of files the fix pass rewrote>, unclean: ' +
    '[<path of every file the check still fails>]}.';

// slot semaphore: caps the true in-flight agent count at CAP with work-conserving backfill, so a group-chain`s fan-fix burst never overshoots the cap (throughput [02]-[CONCURRENCY]).
// Group-chains launch via Promise.all and stream; a stage of one group never gates on the whole corpus. Only terminal Collect and Format barriers hold every file at once.
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
// one slotted agent call with retry-once — a throw or null-return retries once, then yields null so a single dead lane never rejects its group-chain`s Promise.all wave
const run = async (fn) => {
    for (let a = 0; a <= 1; a++) {
        const r = await slot(fn).catch(() => null);
        if (r) return r;
    }
    return null;
};

// --- [COMPOSITION] ---------------------------------------------------------------------

if (!TARGETS.length) {
    log('No targets — pass a folder path, an array of paths, or {targets}. Empty args is a no-op.');
    return { skipped: true };
}

phase('Route');
const census = await agent(
    PREAMBLE +
        '\n\nCENSUS these folders: ' +
        JSON.stringify(TARGETS) +
        '. For each, enumerate every .md file recursively (fd -e md . <folder>). For every file record total lines (wc -l), prose lines via exactly ' +
        PROSE_MEASURE +
        ' <file>, and comment lines via exactly ' +
        COMMENT_MEASURE +
        ' <file>. A target that does not exist or holds no .md files goes to missing. Return the flat file list across all targets; no analysis, no reading of ' +
        'page bodies.',
    { label: 'census', phase: 'Route', model: 'sonnet', effort: 'low', schema: ROUTE_SCHEMA },
);
if (!census || !census.files.length) {
    log('Census returned no files' + (census && census.missing.length ? '; missing: ' + census.missing.join(', ') : ''));
    return { skipped: true, missing: census ? census.missing : TARGETS };
}
if (census.missing.length) log('Missing targets skipped: ' + census.missing.join(', '));

// dedup by path so overlapping parent/child targets never spawn concurrent in-place fixers on the same file
const seenPath = new Set();
const files = census.files
    .filter((f) => !seenPath.has(f.path) && seenPath.add(f.path))
    .map((f) => ({ ...f, kind: kindOf(f.path) }))
    .sort((a, b) => a.path.localeCompare(b.path));

// census file by path; Redteam and Remediate resolve an agent-returned receipt/grade back to its census file here and SKIP an unmatched one, so undefined never reaches a mandate (the `f.path` crash)
const fileByPath = new Map(files.map((f) => [f.path, f]));

const baseProse = files.reduce((a, f) => a + f.prose, 0);
const baseComments = files.reduce((a, f) => a + f.comments, 0);

// one fixer per file, all concurrent; each starts at its finder floor (an `.api` fixer executes the cross-file directives and adds per-file decompile depth; a prose fixer seeds off
// its own findings) — a file with no seed runs its own hunt. Shared by both Analyze shapes so the Fix fan is identical.
const fanFix = (list, seed) =>
    Promise.all(
        list.map((f) =>
            run(() =>
                agent(fixMandate(f, seed.get(f.path)), {
                    label: 'fix:' + f.path.split('/').slice(-2).join('/'),
                    phase: 'Fix',
                    model: 'opus',
                    effort: 'high',
                    schema: FIX_SCHEMA,
                }),
            ),
        ),
    ).then((rs) => rs.filter(Boolean));

// Analyze partitions by what each stage can UNIQUELY see, so no two stages re-litigate one fact. `.api`-tier mode: the finder owns ONLY the whole-tier cross-file / substrate /
// stacking view (the fixer`s blind spot) and the per-file fixer owns the decompile-verified per-file depth (the finder`s blind spot) — the fixer starts at the finder floor and builds
// up, never re-derives it. Non-`.api` tiers keep the per-group finder streamed into its fixers (its per-file findings feed Redteam/Verify downstream, a chain `.api` never runs).
const apiFiles = files.filter((f) => f.kind === 'api');
const apiTierMode = apiFiles.length >= 2 && apiFiles.length >= files.length * 0.8;
let analyzed = 0;
let fixReceipts;
if (apiTierMode) {
    const nonApi = files.filter((f) => f.kind !== 'api');
    log(files.length + ' `.api` pages, ' + Math.ceil(apiFiles.length / TIER_GROUP) + ' cross-tier finder(s), ' + baseProse + ' prose baseline lines');
    const seedByPath = new Map();
    // each finder OWNS a TIER_GROUP slice but sees the WHOLE tier for routing, so a duplication winner in another slice is opened and routed — never fragmented as a fixed window would
    const tierMaps = await Promise.all(
        chunk(apiFiles, TIER_GROUP).map((sub) =>
            run(() =>
                agent(apiTierMandate(sub, apiFiles), {
                    label: 'find:tier+' + sub.length,
                    phase: 'Analyze',
                    model: 'opus',
                    effort: 'high',
                    schema: ANALYZE_SCHEMA,
                }),
            ),
        ),
    );
    for (const m of tierMaps) if (m) for (const fr of m.files) seedByPath.set(fr.path, fr);
    // a stray non-`.api` page in the folder (README/spec) keeps the standard per-file finder
    if (nonApi.length) {
        const resid = await Promise.all(
            chunk(nonApi, GROUP).map((g) =>
                run(() =>
                    agent(analyzeMandate(g), {
                        label: 'find:resid+' + g.length,
                        phase: 'Analyze',
                        model: 'opus',
                        effort: 'high',
                        schema: ANALYZE_SCHEMA,
                    }),
                ),
            ),
        );
        for (const m of resid) if (m) for (const fr of m.files) seedByPath.set(fr.path, fr);
    }
    analyzed = seedByPath.size;
    fixReceipts = await fanFix(files, seedByPath);
} else {
    // per-group stream: one finder over the group of GROUP, then a fixer per file fired the instant that finder returns — no chain waits on a sibling group. The sort keeps same-folder
    // pages adjacent for cross-file TWIN_TRUTH; Redteam/Verify then pool globally (per-page HEAD->now diff, not the finder group) so no lonely tail batch strands.
    const groups = chunk(files, GROUP);
    log(files.length + ' pages, ' + groups.length + ' finder group(s), ' + baseProse + ' prose + ' + baseComments + ' comment baseline lines');
    const fixChains = await Promise.all(
        groups.map(async (g) => {
            const analysis = await run(() =>
                agent(analyzeMandate(g), {
                    label: 'find:' + g[0].path.split('/').slice(-2)[0] + '+' + g.length,
                    phase: 'Analyze',
                    model: 'opus',
                    effort: 'high',
                    schema: ANALYZE_SCHEMA,
                }),
            );
            const byPath = new Map();
            if (analysis) for (const fr of analysis.files) byPath.set(fr.path, fr);
            analyzed += byPath.size;
            return fanFix(g, byPath);
        }),
    );
    fixReceipts = fixChains.flat().filter(Boolean);
}

// Redteam: ONE global pooled stage over every OK-fixed page of an ADVERSARIAL kind (an `.api` catalog is excluded — it closed at Fix), batched at BATCH — full batches, cross-group,
// each file redteamed once. Its receipt supersedes the fixer`s; a fixer that failed or whose red-team dropped keeps the fixer receipt so downstream Verify and the return still account for it.
const okForRed = fixReceipts
    .filter((r) => r.ok && fileByPath.has(r.file) && adversarial(fileByPath.get(r.file).kind))
    .map((r) => ({ f: fileByPath.get(r.file), fix: r }));
const redteamed = (
    await Promise.all(
        chunk(okForRed, BATCH).map((grp) =>
            run(() =>
                agent(redteamMandate(grp), {
                    label: 'redteam:' + grp[0].f.path.split('/').slice(-1)[0] + (grp.length > 1 ? '+' + (grp.length - 1) : ''),
                    phase: 'Redteam',
                    model: 'opus',
                    effort: 'high',
                    schema: BATCH_SCHEMA,
                }),
            ),
        ),
    )
)
    .filter(Boolean)
    .flatMap((b) => b.files)
    .filter(Boolean);
const redByFile = new Map(redteamed.map((r) => [r.file, r]));
const redteamReceipts = fixReceipts.map((r) => redByFile.get(r.file) || r);

// Verify: ONE global pooled stage over every OK, adversarial-eligible page (an `.api` catalog closed at Fix — `adversarial` false — and entered neither redteam nor verify), batched
// at BATCH. Its receipt supersedes the red-team`s. A pure `.api` run has no eligible page and spends no adversarial pass at all.
const verifyPages = redteamReceipts
    .filter((r) => r.ok && fileByPath.has(r.file) && adversarial(fileByPath.get(r.file).kind))
    .map((r) => ({ f: fileByPath.get(r.file), fix: r }));
const fixTerminal = fixReceipts.filter((r) => r.ok && fileByPath.has(r.file) && !adversarial(fileByPath.get(r.file).kind)).length;
let receipts = redteamReceipts;
if (verifyPages.length) {
    const verified = (
        await Promise.all(
            chunk(verifyPages, BATCH).map((grp) =>
                run(() =>
                    agent(verifyMandate(grp), {
                        label: 'verify:' + grp[0].f.path.split('/').slice(-1)[0] + (grp.length > 1 ? '+' + (grp.length - 1) : ''),
                        phase: 'Verify',
                        model: 'opus',
                        effort: 'high',
                        schema: BATCH_SCHEMA,
                    }),
                ),
            ),
        )
    )
        .filter(Boolean)
        .flatMap((b) => b.files)
        .filter(Boolean);
    const verByFile = new Map(verified.map((r) => [r.file, r]));
    receipts = redteamReceipts.map((r) => verByFile.get(r.file) || r);
}
log(
    analyzed +
        '/' +
        files.length +
        ' analyzed; ' +
        fixReceipts.length +
        ' fixed; ' +
        redteamed.length +
        ' pages redteamed' +
        (verifyPages.length ? '; ' + verifyPages.length + ' verified' : '') +
        (fixTerminal ? '; ' + fixTerminal + ' `.api` closed at Fix by kind' : ''),
);

// Collect fires ONLY when a .planning/ page actually extracted a folder-wide ruling; a .api/ tier, a tools/ target, or any folder with no .planning/ files skips it
// whole — no phase, no dossier collection, no wasted agent. ONE collector takes every owner: cross-owner dedup and tier placement are only decidable with the whole
// candidate set in one context, and a single writer across disjoint registries cannot collide with itself.
// only a receipt that actually extracted (rulingsExtracted > 0) has a written dossier on disk; an empty page writes none, so the collector is handed filled dossiers alone.
// The union spans every receipt generation (fix, redteam, final) — a dossier the fixer wrote survives on disk even when a superseding receipt under-reports the count.
const extractedPaths = new Set([...fixReceipts, ...redteamed, ...receipts].filter((r) => r.ok && r.rulingsExtracted > 0).map((r) => r.file));
const owners = [...new Set([...extractedPaths].map((p) => ownerOf(p)))].filter(Boolean);
let collected = null;
if (owners.length) {
    phase('Collect');
    const collectTargets = owners.map((owner) => ({
        owner,
        rulings: rulingsCandidates(owner),
        dossiers: files.filter((f) => extractedPaths.has(f.path) && ownerOf(f.path) === owner).map((f) => dossierPath(f.path)),
    }));
    collected = await agent(collectMandate(collectTargets), {
        label: 'rulings:' + owners.length,
        phase: 'Collect',
        model: 'fable',
        effort: 'high',
        schema: COLLECT_SCHEMA,
    });
    if (collected) log(collected.owners.length + ' RULINGS.md file(s) written across ' + owners.length + ' owner(s) with extractions');
}
const collectedOwners = collected ? collected.owners : [];

// Format: one deterministic sweep re-pads every touched page AND every written RULINGS.md to the canonical table render and re-runs the width/anchor gate, so the run closes
// with every table proven within the 150-column cap — the single integrity floor after the writing passes, mechanical and idempotent (no content judgment).
phase('Format');
const touched = [...new Set([...receipts.map((r) => r.file), ...collectedOwners.map((c) => c.rulingsFile)])].filter(Boolean);
const formatted = touched.length
    ? await agent(formatMandate(touched), { label: 'format:' + touched.length, phase: 'Format', model: 'opus', effort: 'low', schema: FORMAT_SCHEMA })
    : null;
if (formatted && formatted.unclean.length) log('Gate unclean after format sweep: ' + formatted.unclean.join(', '));

const beforeProseT = receipts.reduce((a, r) => a + r.beforeProse, 0);
const afterProseT = receipts.reduce((a, r) => a + r.afterProse, 0);
const beforeCommT = receipts.reduce((a, r) => a + r.beforeComments, 0);
const afterCommT = receipts.reduce((a, r) => a + r.afterComments, 0);
const dropped = files.length - receipts.length;
if (dropped) log(dropped + ' file agent(s) returned nothing after retry — rerun those files or resume');
return {
    targets: TARGETS,
    pages: files.length,
    fixed: receipts.length,
    proseReductionPct: beforeProseT ? Math.round(100 - (afterProseT / beforeProseT) * 100) : 0,
    commentReductionPct: beforeCommT ? Math.round(100 - (afterCommT / beforeCommT) * 100) : 0,
    proseOffBand: receipts
        .filter((r) => r.ok && (r.proseReductionPct < PROSE_LO || r.proseReductionPct > TOTAL_HI))
        .map((r) => ({ file: r.file, pct: r.proseReductionPct, notes: r.notes })),
    capabilityLoss: receipts.filter((r) => r.ok && !r.capabilityConserved).map((r) => ({ file: r.file, notes: r.notes })),
    demotionsUnverified: receipts.flatMap((r) =>
        (r.demotions || [])
            .filter((d) => !d.verified || d.setWidth !== 'exact')
            .map((d) => ({ file: r.file, payload: d.payload, owner: d.owner, verified: d.verified, setWidth: d.setWidth })),
    ),
    indexMissing: receipts.filter((r) => r.indexLanded === 'no').map((r) => r.file),
    gateUnclean: receipts.filter((r) => !r.gateClean).map((r) => r.file),
    formatSweep: formatted ? { formatted: formatted.formatted, unclean: formatted.unclean } : undefined,
    // rulings summary appears ONLY for a run that scoped in .planning/ files; a pure .api/, tools/, or non-libs cleanup returns none of it
    ...(files.some((f) => underPlanning(f.path))
        ? {
              rulingsExtracted: receipts.filter((r) => r.ok).reduce((a, r) => a + Math.max(0, r.rulingsExtracted), 0),
              rulingsAdmitted: collectedOwners.reduce((a, c) => a + c.admitted.length, 0),
              rulingsFilesWritten: collectedOwners.map((c) => ({
                  owner: c.owner,
                  file: c.rulingsFile,
                  created: c.created,
                  admitted: c.admitted.length,
              })),
              rulingsRejected: collected ? collected.rejected : [],
              rulingsDeferred: collected ? collected.deferred : [],
              rulingsGateUnclean: collectedOwners.filter((c) => !c.gateClean).map((c) => c.rulingsFile),
              dossierDir: owners.length ? SCRATCH : undefined,
          }
        : {}),
    failed: receipts.filter((r) => !r.ok).map((r) => ({ file: r.file, notes: r.notes })),
    dropped,
};
