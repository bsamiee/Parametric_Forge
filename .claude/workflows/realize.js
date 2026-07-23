export const meta = {
    name: 'realize',
    whenToUse:
        'Execute a root campaign DECISION/brief into its target planning folder. args = {doc, root} or an array of such pairs; campaigns run as parallel lanes. Wide reconnaissance hands one terminal writer everything on a golden platter — the doc, exact disk locations, ripple endpoints across every libs/ folder, and the full two-tier .api stacking inventory — and the executor implements the whole campaign under the language doctrine with libs-wide ripple authority. Run cold-verify after.',
    description:
        'Campaign realization in two moves. RECON: dispatched mapper lanes fan out — page-slice mappers (root doc IN FULL + slice pages IN FULL + sibling context), one governance mapper (manifests, csproj/README registries, .api anchors, index docs), two stacking mappers (one per .api tier: the shared libs/<lang>/.api substrate and the folder <root>/.api tier, full inventory mined to operator depth against the doc page set — doc-demanded AND beyond-doc underutilized capability, exact verified members), and ONE BRANCH RIPPLE MAPPER PER language lib (libs/csharp, libs/python, libs/typescript — each sweeping its branch package folders except the target, skipping the branch .planning core; seam ledgers, consumer anchors, counterpart obligations, frozen wire names the campaign touches). Every mapper runs a mandatory second-pass self-verify: each entry re-derived from disk, anchors re-opened, spellings re-checked; a guess, a skim, or a vague entry is deleted before return. Mappers provide information — locations, anchors, ripples, inventory — never prescriptions. EXECUTE: one write lane per campaign takes the root doc and every map and implements everything in place at the docs/stacks/<language>/ bar: the full page set, registry and index closure, every ripple in the same pass with LIBS-WIDE ripple authority (sibling counterparts repaired in place both ends, except where the doc rules a counterpart recorded-only), the two-tier stacking woven in, its own hunt past the maps. The executor carries a required-but-usually-empty harvest attestation; when any campaign pools a non-empty nomination, ONE terminal doctrine lander adjudicates them against docs/laws (refutation-first, land-nothing legal). Otherwise no stage after the executor; cold-verify is the separate closure gate.',
    phases: [
        { title: 'Plan', detail: 'per campaign: enumerate the page set (disk + doc-ruled new pages), partition into mapper slices', model: 'opus' },
        {
            title: 'Recon',
            detail: 'per campaign: page-slice + governance + two-tier stacking + per-branch ripple mappers as dispatched lanes, self-verified information not prescriptions',
            model: 'sonnet',
        },
        {
            title: 'Execute',
            detail: 'per campaign: the write lane implements the whole campaign — doc + maps + doctrine, every ripple in-pass, libs-wide',
            model: 'fable',
        },
        {
            title: 'Doctrine',
            detail: 'terminal doctrine lander, fires only on non-empty pooled harvest: adjudicates executor nominations against docs/laws, refutation-first, land-nothing legal',
            model: 'fable',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const SLICE_SIZE = 4;
const MAX_SLICES = 8;

// --- [INPUTS] --------------------------------------------------------------------------

const argsIn = typeof args === 'string' && /^\s*[\[{]/.test(args) ? JSON.parse(args) : args;
const CAMPS = (Array.isArray(argsIn) ? argsIn : [argsIn]).filter((c) => c && c.doc && c.root);
if (!CAMPS.length) {
    log('No campaigns — pass {doc, root} or an array of pairs.');
    return { campaigns: 0 };
}
const langOf = (root) => (root.indexOf('libs/csharp') === 0 ? 'cs' : root.indexOf('libs/python') === 0 ? 'py' : 'ts');
const STACK = { cs: 'docs/stacks/csharp', py: 'docs/stacks/python', ts: 'docs/stacks/typescript' };
const TIER = { cs: 'libs/csharp/.api', py: 'libs/python/.api', ts: 'libs/typescript/.api' };
const chunk = (a, n) => {
    const o = [];
    for (let i = 0; i < a.length; i += n) o.push(a.slice(i, i + n));
    return o;
};
// Per-instance scratch dir holding per-lane reports — minted deterministically from the normalized campaign set (clock/randomness
// would break resume): one FLAT dir under .claude/scratch/, a root-basename slug and an FNV-1a tail so distinct campaign sets never collide.
const fnv1a = (s) => {
    let h = 0x811c9dc5;
    for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193);
    return (h >>> 0).toString(16).padStart(8, '0').slice(0, 6);
};
const SCRATCH =
    '.claude/scratch/' +
    ('realize-' + CAMPS.map((c) => c.root.split('/').pop().toLowerCase()).join('-')).replace(/[^a-z0-9.-]+/g, '-').slice(0, 60) +
    '-' +
    fnv1a(JSON.stringify(CAMPS));

// --- [MODELS] --------------------------------------------------------------------------

const PLAN = {
    type: 'object',
    additionalProperties: false,
    required: ['pages'],
    properties: {
        pages: { type: 'array', items: { type: 'string' } },
    },
}; // disk pages + doc-ruled new pages, dependency order

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

const MAP = {
    type: 'object',
    additionalProperties: false,
    required: ['entries', 'coverage', 'summary'],
    properties: {
        entries: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['target', 'kind', 'files', 'info', 'anchors', 'members'],
                properties: {
                    target: { type: 'string' }, // page, registry surface, or catalog the entry grounds
                    kind: { type: 'string', enum: ['state', 'ruling-site', 'ripple', 'stacking', 'gap', 'registry'] },
                    files: { type: 'array', items: { type: 'string' } }, // files the executor must open for this entry
                    info: { type: 'string' }, // the fact: current shape, seam endpoints, gap — prose truth, zero prescriptions
                    anchors: { type: 'array', items: ANCHOR }, // exact coordinates backing the fact
                    members: { type: 'array', items: { type: 'string' } },
                },
            },
        }, // verified catalog members backing a stacking entry
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
        summary: { type: 'string' },
    },
};

// Thin wire receipt: the lane's PRODUCT stays on disk at `report`; only status + count + headline travel inline.
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

const FIXLOG = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'built', 'beyond', 'blocked', 'declined', 'harvest', 'summary'],
    properties: {
        files: { type: 'array', items: { type: 'string' } },
        built: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['target', 'action'],
                properties: {
                    target: { type: 'string' },
                    action: { type: 'string' },
                },
            },
        },
        beyond: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['target', 'action'],
                properties: {
                    target: { type: 'string' },
                    action: { type: 'string' },
                },
            },
        },
        blocked: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['target', 'reason'],
                properties: {
                    target: { type: 'string' },
                    reason: { type: 'string' },
                },
            },
        },
        // one line per covering beyond-doc underutilized-capability entry NOT composed: the disk fact or doctrine law forbidding it — empty attests every covering ambition landed
        declined: { type: 'array', items: { type: 'string' } },
        harvest: HARVEST,
        summary: { type: 'string' },
    },
};

// --- [SHARED_BLOCKS] -------------------------------------------------------------------

const CTX = (c) =>
    'Rasm monorepo, planning phase — the work product is design pages, index docs, central manifests, and .api ' +
    'catalogs; no source files land. ' +
    c.doc +
    ' at the repo root is the binding campaign ruling for ' +
    c.root +
    '. All .md ' +
    'prose follows docs/standards/style-guide.md: declarative agent-facing law, no provenance, no process narration, no hedges. ' +
    'Never run git commit.';

const INFO_LAW =
    'You provide INFORMATION, never prescriptions: exact disk locations and anchors, the current shape at each ' +
    'ruling site, seam endpoints on both sides, verified member spellings, gaps. The executor decides how to build; a map entry ' +
    'that tells it what to write instead of what is true is a defect. ENTRY FORM: `info` is prose truth; `anchors` carry one ' +
    'coordinate per row (role names what it proves; `note` is the shortest literal witness under 20 words, or empty when ' +
    'path+line suffice; an `absence` anchor names where the expected thing was searched and not found); `files` lists what the ' +
    'executor must open for the entry. An underutilized-capability entry is INVENTORY, never instruction: verified members, ' +
    'current usage anchors, the concept that admits it — the executor decides whether it composes. COVERAGE is part of the ' +
    'product: `requested` = your assigned scope, `read` = what you actually full-read, `skipped`/`unverified` = what you did ' +
    'not reach — an honest skip beats a silent one.';

// Mapper self-verify (+ native quota twin): neutral register — the second-pass duty carries, the hostile intensifiers do not.
const SELF_CHECK =
    'SELF-VERIFY (second pass, before returning): re-derive every entry from disk — ' +
    're-open each cited anchor and confirm it states what the entry claims, re-verify each member spelling against its ' +
    'catalog, trace each ripple to both endpoints. An entry that fails re-confirmation is corrected or deleted, never ' +
    'returned; a guess, an assumption, a skimmed summary, or a vague/hedged entry is a defect. Completeness is part of ' +
    'correctness: after the re-read, hunt once more for what the first pass missed — an omitted load-bearing fact is as ' +
    'wrong as a false one.';

const LAWS_READ =
    'LAWS — read `docs/laws/` before any durable edit (README + topology + patterns + scars; short registry pages): a ' +
    'topology row whose [SURFACE] your edits touch binds its obligated counterparts into the SAME pass, and every patterns row ' +
    'binds each branch it names.';

// OWN PASS FIRST — the executor's binding input ladder: rung 1 is a DISK ARTIFACT written from the doc + pages before any recon
// report opens; the reports may only ADD [recon]-tagged rows, and a diff dominated by them fails the ladder (the golden-platter tripwire).
const OWN_PASS = (artifact) =>
    'OWN PASS FIRST — the input ladder is binding, in order: (1) your own blind pass over the doc and pages, (2) the recon report ' +
    'files. Rung (1) is the PRIMARY product and it is a DISK ARTIFACT, not a reading step: read the doc IN FULL and cold-read every ' +
    'target page from CURRENT disk, then WRITE your own build-and-ambition list to `' +
    artifact +
    '` — the pages the doc rules, the owner each demands, the collapse and capability gaps you see, and every ripple your reading ' +
    'exposes — BEFORE opening any recon report. The reports may only ADD rows to that file, each tagged [recon]; reading the doc ' +
    'without writing the list is a failed rung, not a cold pass. Rung (2) grounds, extends, and widens YOUR pass — it never scopes, ' +
    'substitutes for, or caps it. TRIPWIRE: a diff dominated by [recon]-tagged rows has failed — the maps cover a MINORITY of what ' +
    'the campaign demands, and the majority of your edits come from your own reading of the doc and pages.';

const HARVEST_LAW =
    'HARVEST (required key, usually empty): nominate ONLY findings that generalize beyond this campaign — a collapse pattern ' +
    'reusable across folders, a naivety class no doctrine clause names, a review rule that would have caught a defect BEFORE ' +
    'review, a cross-surface coupling discovered the hard way. Each row: altitude (stacks|reviewer|constitution|planning|readme|' +
    'laws), lang, claim (the generalized law, one sentence), anchors (file:line evidence), existingClause (the exact doctrine or ' +
    'reviewer clause it would harden, quoted with its path — or "absent" and the surfaces searched). A campaign-local fix never ' +
    'nominates; an empty array is the normal verdict — the terminal doctrine lander refutes weak rows, so nominate substance, never volume.';

// --- [OPERATIONS] ----------------------------------------------------------------------

const RETRY_ATTEMPTS = 2;
// Bounded re-dispatch for a dead CRITICAL lane (usage-limit or transport death): attempt-counted with a retry before each; the
// final death isolates the lane but NEVER the chain — the terminal doctrine lander still runs against current disk.
const retryLane = async (fn) => {
    for (let a = 0; a < RETRY_ATTEMPTS; a++) {
        const r = await fn();
        if (r) return r;
    }
    return null;
};

// Codex dispatch: the wrapper runs one supervised codex-lane.sh lane in the background, reads the receipt, verifies the
// --out product, and returns mechanical orchestration data. Lane law rides --law (developer-instructions,
// role split); the --task file carries only the task; the output contract sits LAST.
const fileTag = (label) => label.replace(/[^A-Za-z0-9_.-]+/g, '-');
// Every realize codex lane is recon investigation (the executor is the native author), so the lane law is the
// context-gathering budget + stop rule alone — no write-lane persistence arm the shape never dispatches.
const laneLaw = (schema, o) =>
    '<context_gathering>\nTerritory: the exact files and directories the task names. Do not open files outside it, ' +
    'including skill or instruction files (.claude/, CLAUDE.md, AGENTS.md).\nBudget: at most ' +
    (o.calls || 60) +
    ' tool calls total. Read in small batches (a handful of files per command, line-capped); never concatenate the whole ' +
    'territory into one command - tool output truncates and the data is lost.\nStop as soon as the product is complete. ' +
    'If something is still uncertain at the budget, proceed and record the residue in the product gap/unverified field ' +
    'instead of re-reading.\n</context_gathering>\n\n<verification>\nBefore the final message, confirm every cited ' +
    'spelling appears verbatim in the cited file; anything unconfirmed is recorded as a gap, never asserted.\n' +
    '</verification>' +
    '\n\n<output_contract>\nYour final message is a single JSON object with exactly this shape: ' +
    JSON.stringify(schema) +
    '\n- JSON only: no prose before or after it, no code fences, no markdown.\n- Every key shown is required.\n' +
    '- Use null for a value you could not determine and [] for an empty list; never guess.\n</output_contract>';
// Every realize codex lane is read-only recon (the native executor authors), so the delegate never writes: --out
// materializes the product and the wrapper relays only the thin receipt.
const LANE_SCRIPT = '/Users/bardiasamiee/Documents/99.Github/Rasm/.claude/skills/codex/scripts/codex-lane.sh';
const flagsOf = (o) =>
    [o.codexEffort && '--effort ' + o.codexEffort, o.web && '--web']
        .filter(Boolean)
        .map((f) => ' ' + f)
        .join('');

const codexPrompt = (label, task, schema, o) => {
    const base = SCRATCH + '/' + fileTag(label);
    const root = '/Users/bardiasamiee/Documents/99.Github/Rasm';
    const report = root + '/' + base + '-report.json';
    const lane = report + '.lane';
    const model = o.model || 'gpt-5.6-terra';
    const hl = o.hl || { arr: 'entries', group: 'kind' };
    return (
        'DISPATCH ROLE: a delegate performs the complete TASK below through one supervised lane run; never perform, edit, judge, soften, ' +
        'summarize, or relay the work yourself. (1) Write the LANE LAW block below VERBATIM to ' +
        lane +
        '/law.md and the TASK block below VERBATIM to ' +
        lane +
        '/task.md, composing neither. (2) Run ONE Bash call with run_in_background true: ' +
        LANE_SCRIPT +
        ' --task ' +
        lane +
        '/task.md --law ' +
        lane +
        '/law.md --dir ' +
        lane +
        ' --cwd ' +
        root +
        ' --sandbox read-only --model ' +
        model +
        flagsOf(o) +
        ' --out ' +
        report +
        '; the harness re-invokes you when the lane exits — Read ' +
        lane +
        '/receipt.json then, never a polling loop. Recovery is two-branch and ONCE-only — the whole budget: a receipt reason "crash" ' +
        'alone (the session persisted on disk) overwrites the task file with "continue and complete the lane, then land the receipt" and ' +
        're-runs the same command plus --resume <the receipt thread_id>; any other failed receipt (max-timeout, turn-failed, ' +
        'refusal) re-runs the same command untouched. (3) The lane lands the product at ' +
        report +
        ' via --out. (4) Verify with one Bash call: jq -e . ' +
        report +
        ' >/dev/null — a nonzero exit means a missing or malformed product; on a miss re-derive the product once from the lane ' +
        'events.jsonl (jq -rs to the last agent_message item text, Write that), re-probe, and a second miss returns ok=false with the ' +
        'probe output. (5) Return ok=true, report=' +
        base +
        '-report.json (this repo-relative form, matching codex-lane receipts), entries = the length of the "' +
        hl.arr +
        '" array in the product, headline="<entries> ' +
        hl.arr +
        (hl.group ? ' | <' + hl.group + ' tallies>' : '') +
        ' | top: <most frequent first file or none>", and failure empty. On a failed receipt return ok=false, entries=0, report and ' +
        'headline empty, and failure equal to the receipt reason and failure text VERBATIM.\n\nLANE LAW:\n\n' +
        laneLaw(schema, o) +
        '\n\nTASK:\n\n' +
        task
    );
};
// Every heavy read/investigate lane routes here as the quota twin. QUOTA FALLBACK: a codex receipt whose
// failure matches usage/quota/limit re-dispatches the SAME task natively at the role's native twin — the
// caller owns the re-dispatch, the shell lane never executes work itself.
const twinOf = (m) => (/-sol/.test(m || '') ? 'fable' : /-luna/.test(m || '') ? 'sonnet' : 'opus');
const nativeLane = (task, o) =>
    agent(
        task +
            '\n\nPRODUCT TO DISK: write your COMPLETE product as one JSON file matching this schema at ' +
            SCRATCH +
            '/' +
            fileTag(o.label) +
            '-report.json (Write tool, absolute path under the repo root): ' +
            JSON.stringify(o.schema) +
            ' — then return ONLY the receipt: ok, report path, entries count, one-line headline, failure empty.',
        { label: o.label, phase: o.phase, model: twinOf(o.model), effort: 'high', schema: RECEIPT },
    );
const recon = (task, o) =>
    agent(codexPrompt(o.label, task, o.schema, o), {
        label: (o.model && o.model.indexOf('-sol') >= 0 ? 'sol:' : 'terra:') + o.label,
        phase: o.phase,
        model: 'sonnet',
        effort: 'low',
        schema: RECEIPT,
    })
        .then((r) => (r && !r.ok && /usage|quota|limit/i.test(r.failure || '') ? nativeLane(task, o) : r))
        .then((r) => ({
            lane: o.label,
            scope: o.scope || [],
            ok: !!(r && r.ok && r.report),
            report: (r && r.report) || '',
            entries: (r && r.entries) || 0,
            headline: (r && r.headline) || '',
            failure: (r && r.failure) || (r ? '' : 'lane died'),
        }));

// --- [COMPOSITION] ---------------------------------------------------------------------

const lanes = await parallel(
    CAMPS.map((c) => async () => {
        const tag = c.root.split('/').pop();
        const lang = langOf(c.root);
        const execArtifact = SCRATCH + '/execute-' + tag + '-ownpass.md';
        const plan = await agent(
            CTX(c) +
                '\n\nTASK: thin enumerate (read-only). Union (a) every design page under ' +
                c.root +
                '/.planning/ from a real listing and (b) every page ' +
                c.doc +
                ' rules into existence that is absent on disk. Return ' +
                'the union as one dependency-ordered list (foundations before consumers, per the doc where it rules an order).',
            { label: 'plan:' + tag, phase: 'Plan', model: 'opus', effort: 'high', schema: PLAN },
        );
        // Guard the plan lane's page roster: drop non-string, empty, and out-of-root paths (a hallucinated or mis-scoped page
        // would mis-slice a mapper), dedupe first-wins — every downstream slice and stacking map dispatches on this set.
        const pages = [...new Set(((plan && plan.pages) || []).filter((p) => typeof p === 'string' && p && p.indexOf(c.root) === 0))];
        const slices = chunk(pages, Math.max(SLICE_SIZE, Math.ceil(pages.length / MAX_SLICES)));
        const mappers = slices.map(
            (s, i) => () =>
                recon(
                    CTX(c) +
                        '\n\n' +
                        INFO_LAW +
                        '\n\n' +
                        SELF_CHECK +
                        '\n\nTASK: PAGE-SLICE MAP, slice ' +
                        i +
                        ' (read-only). Read ' +
                        c.doc +
                        ' IN FULL, then each of these pages IN FULL (a doc-ruled page absent on disk maps its ' +
                        'ruling and the nearest sibling context instead): ' +
                        JSON.stringify(s) +
                        '. For each page return: its current state ' +
                        'against every doc ruling that touches it (exact anchors), every seam/consumer ripple endpoint on both sides, every ' +
                        'catalog its fences cite with the cited members verified against the .api tier, and every gap between the ruling and ' +
                        'disk. Entries are facts with anchors.',
                    { label: 'map:' + tag + ':s' + i, phase: 'Recon', schema: MAP, scope: s },
                ),
        );
        mappers.push(() =>
            recon(
                CTX(c) +
                    '\n\n' +
                    INFO_LAW +
                    '\n\n' +
                    SELF_CHECK +
                    '\n\nTASK: GOVERNANCE MAP (read-only). Map the campaign governance ' +
                    'surface: ' +
                    c.root +
                    '/README.md and ARCHITECTURE.md (router, package groups, codemap, seams ledger), the folder ' +
                    'manifest surface (' +
                    (lang === 'cs'
                        ? 'the .csproj + the Directory.Packages.props rows this package consumes'
                        : 'the pyproject.toml rows this package consumes') +
                    '), the ' +
                    c.root +
                    "/.api/ inventory with each catalog's " +
                    'anchor state, and every registry fact ' +
                    c.doc +
                    ' rules. Return the exact current state of each surface and every ' +
                    'disagreement between two surfaces, with anchors.',
                {
                    label: 'map:' + tag + ':gov',
                    phase: 'Recon',
                    schema: MAP,
                    scope: [c.root + '/README.md', c.root + '/ARCHITECTURE.md', c.root + '/.api', 'manifest rows'],
                },
            ),
        );
        mappers.push(() =>
            recon(
                CTX(c) +
                    '\n\n' +
                    INFO_LAW +
                    '\n\n' +
                    SELF_CHECK +
                    '\n\nTASK: SUBSTRATE-TIER STACKING MAP (read-only). Enumerate ' +
                    TIER[lang] +
                    '/ with a real listing and read every catalog relevant to this campaign. Against the full page set (' +
                    JSON.stringify(pages) +
                    ') and the doc rulings, return every substrate capability the corpus composes, under-composes, ' +
                    'or ignores — doc-demanded AND beyond-doc: {catalog, verified member spellings, the page whose concept admits it, the ' +
                    'integration shape as fact}. Depth over breadth: operator-level members, never headline names.',
                { label: 'map:' + tag + ':tier1', phase: 'Recon', schema: MAP, scope: [TIER[lang]] },
            ),
        );
        mappers.push(() =>
            recon(
                CTX(c) +
                    '\n\n' +
                    INFO_LAW +
                    '\n\n' +
                    SELF_CHECK +
                    '\n\nTASK: FOLDER-TIER STACKING MAP (read-only). Enumerate ' +
                    c.root +
                    '/.api/ with a real listing and read EVERY catalog. Against the full page set (' +
                    JSON.stringify(pages) +
                    ') and the ' +
                    'doc rulings, return every folder-package capability the corpus composes, under-composes, or ignores — doc-demanded AND ' +
                    'beyond-doc underutilized capability: {catalog, verified member spellings, the page whose concept admits it, the ' +
                    'integration shape as fact}. An admitted capability no page exploits is a named entry, never a silence.',
                { label: 'map:' + tag + ':tier2', phase: 'Recon', schema: MAP, scope: [c.root + '/.api'] },
            ),
        );
        const BRANCHES = ['libs/csharp', 'libs/python', 'libs/typescript'];
        BRANCHES.forEach((branch) =>
            mappers.push(() =>
                recon(
                    CTX(c) +
                        '\n\n' +
                        INFO_LAW +
                        '\n\n' +
                        SELF_CHECK +
                        '\n\nTASK: ' +
                        'BRANCH RIPPLE MAP for ' +
                        branch +
                        ' (read-only). Read ' +
                        c.doc +
                        ' IN FULL, then sweep every package folder ' +
                        'under ' +
                        branch +
                        ' EXCEPT ' +
                        c.root +
                        " — each folder's ARCHITECTURE seams ledger and codemap, README router " +
                        'and package groups, index docs, design pages, and .api catalogs that name, anchor, or compose ' +
                        c.root +
                        ' ' +
                        'content (real grep, never memory). SKIP the branch core ' +
                        branch +
                        '/.planning entirely. Return every ' +
                        'touchpoint the campaign rulings touch: seam rows anchored to pages the doc splits, renames, re-points, or ' +
                        'deletes; consumer-cited anchors into the target; counterpart obligations the doc records with a folder in this ' +
                        'branch as an endpoint; frozen wire names and shapes both ends hold byte-identical; shared manifest rows and ' +
                        '.api tier overlaps. Each entry is a fact with exact anchors on BOTH endpoints. Zero genuine touchpoints is a ' +
                        'valid result — return empty entries, never manufactured ripples.',
                    { label: 'map:' + tag + ':rip:' + branch.split('/').pop(), phase: 'Recon', schema: MAP, scope: [branch] },
                ),
            ),
        );
        const roster = (await parallel(mappers)).filter(Boolean);
        const mapped = roster.filter((r) => r.ok);
        const total = mapped.reduce((a, r) => a + r.entries, 0);
        const unmapped = roster.filter((r) => !r.ok).flatMap((r) => r.scope.map((sc) => ({ lane: r.lane, scope: sc })));
        log(
            tag +
                ': ' +
                total +
                ' map entries across ' +
                mapped.length +
                '/' +
                roster.length +
                ' lanes' +
                (mapped.length < roster.length
                    ? ' — FAILED: ' +
                      roster
                          .filter((r) => !r.ok)
                          .map((r) => r.lane)
                          .join(', ')
                    : ''),
        );
        const execPrompt =
            CTX(c) +
            '\n\n' +
            LAWS_READ +
            '\n\n' +
            HARVEST_LAW +
            '\n\n' +
            OWN_PASS(execArtifact) +
            '\n\nTASK: EXECUTE THE CAMPAIGN (WRITER — full authority over ' +
            c.root +
            ', its ' +
            'manifest rows, its .api tier, the index docs, AND libs-wide ripple authority: a ripple your edits expose anywhere ' +
            'under libs/ — sibling seam ledgers, mirrored ARCHITECTURE rows, consumer page anchors, index docs, .api catalogs — ' +
            'is repaired in place at the sibling in the same pass, both ends, so the tree ends coherent, never disjointed; ' +
            'where ' +
            c.doc +
            ' explicitly rules a counterpart RECORDED with a demanding consumer rather than edited, the ' +
            "recording IS the fix and the sibling interior stays unedited past that ruling. You are the run's LAST agent). " +
            'Read ' +
            c.doc +
            ' IN FULL — it is ' +
            'the ruling. Read the ' +
            STACK[lang] +
            '/ doctrine at source (README and every page it routes) — it is the bar. The ' +
            'recon REPORT FILES are your reconnaissance. CONSUMPTION (rung 2, AFTER your OWN PASS FIRST artifact lands): (a) ' +
            'UNMAPPED scope below gets your own cold read FIRST; ' +
            '(b) read every ok report IN FULL from disk — governance and the two stacking maps ' +
            'before page slices, ripple maps before the pages whose seams they anchor; entries overlap across lanes, dedupe by target ' +
            "as you read; (c) each entry's anchors are jump coordinates — spot-verify what you build on, and re-open every anchor behind an edit — " +
            'information, not instructions; spot-verify what you build on, and hunt past them on your own authority. IMPLEMENT ' +
            'EVERYTHING the doc rules, in dependency order: author ruled-new pages ground-up, rebuild and improve ruled pages in ' +
            'place, weave the stacking inventory into the owning pages as cases, rows, fields, and operations (doc-demanded and ' +
            'beyond-doc alike — an admitted capability the concept admits is composed, never noted). CAPABILITY-COMPLETENESS IS ' +
            'MANDATORY, NOT OPTIONAL: for every owner you author or rebuild, the body implements what its names and prose promise — ' +
            'a named-but-omitted capability is a defect you close NOW, at the same bar as any doc ruling. Every beyond-doc ' +
            'underutilized-capability entry the stacking maps surface that a target page’s concept admits resolves EXPLICITLY: ' +
            'composed into the owning page, or a one-line `declined` entry naming the disk fact or doctrine law that forbids it — an ' +
            'entry neither composed nor justified-declined is a silent loss. Close the registry and index ' +
            'docs, and repair every ripple your edits expose in the same pass, both seam ends — the sibling ripple maps ' +
            'enumerate the known cross-folder endpoints; cover every one and hunt past them. A ruling is a FLOOR: exceed it with ' +
            'denser, deeper, more capable form; frozen signatures and wire names stay byte-identical. `blocked` carries only what ' +
            'is genuinely unreachable (a gated cross-package producer), with reason — never deferred work. ' +
            'UNMAPPED: ' +
            JSON.stringify(unmapped) +
            ' ROSTER: ' +
            JSON.stringify(roster);
        // CHAIN CONTINUATION: the executor is the campaign's CRITICAL write lane — its death loses the whole campaign's landed
        // work, so a usage-limit or transport death earns bounded re-dispatch; the retry re-runs against CURRENT disk, composing
        // its own partial edits. The final death isolates this campaign; sibling campaigns and the doctrine terminal still run.
        const execOpts = (suffix) => ({
            label: 'execute:' + tag + suffix,
            phase: 'Execute',
            model: 'fable',
            effort: 'high',
            schema: FIXLOG,
        });
        const fix = (await agent(execPrompt, execOpts(''))) || (await retryLane(() => agent(execPrompt, execOpts(':r1'))));
        return {
            campaign: c.root,
            lanes: roster.length,
            failedLanes: roster.filter((r) => !r.ok).map((r) => r.lane),
            mapEntries: total,
            built: (fix && fix.built && fix.built.length) || 0,
            beyond: (fix && fix.beyond && fix.beyond.length) || 0,
            blocked: (fix && fix.blocked) || [],
            declined: (fix && fix.declined) || [],
            harvest: (fix && fix.harvest) || [],
            summary: (fix && fix.summary) || '',
        };
    }),
);

// DOCTRINE LANDER: the run's durable-learning terminal — pooled harvest nominations adjudicated against the live
// doctrine surfaces; refutation-first, land-nothing legal, admission law owned by docs/laws. Fires only on non-empty rows.
const HARVEST_ROWS = lanes.filter(Boolean).flatMap((l) => l.harvest || []);
const doctrine = HARVEST_ROWS.length
    ? await agent(
          'TASK: DOCTRINE LANDER — the durable-learning terminal of this run. Read `docs/laws/README.md` ' +
              'FIRST — it owns the corpus admission and page-shape law; obey it over any restatement. Load ' +
              'the `docgen` skill via the Skill tool BEFORE any durable edit; load ' +
              '`mermaid-diagramming` before touching any diagram. ' +
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
    campaigns: lanes.filter(Boolean),
    doctrine: doctrine && {
        nominated: HARVEST_ROWS.length,
        landed: (doctrine.landed || []).length,
        refined: (doctrine.refined || []).length,
        rejected: (doctrine.rejected || []).length,
        files: doctrine.files || [],
        summary: doctrine.summary,
    },
};
