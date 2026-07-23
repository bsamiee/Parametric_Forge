export const meta = {
    name: 'rebuild-api',
    whenToUse: 'Rebuild every .api catalog under a target root to full integration-shaped capability.',
    description:
        'Rebuild every .api catalog under a target root to FULL first-class, integration-shaped capability — document each package full advanced surface AND how packages STACK into single dense rails, verified against real members. Substrate-first PER LANGUAGE: each language runs as an independent concurrent lane in which the shared tier (libs/<lang>/.api/) is rebuilt before that language folder tiers — the barrier is language-local, so a python folder catalog never waits on csharp substrate; a failed substrate batch flags that language folder batches in the log and return instead of silently stacking onto stub hubs. Folder batches keep one folder per batch, pack small sibling-folder tails of the same language up to the batch size, and co-batch sibling families as the WORK PARTITION, never a write fence: every batch fixes any catalog its work exposes — either tier, in or out of its batch — in the same pass under the current-state law, so the run ends closed in one pass. Every catalog rebuild batch (substrate and folder tier alike) runs as a dispatched write lane — batches are path-disjoint by construction; the discover stage runs native. Language-agnostic: members verified via assay api over host DLLs / NuGet / Python distributions / node_modules, falling back to the nuget MCP / Context7 / source tier when reflection is blocked. args = optional scope (string, array of scopes, or {target|targets} — e.g. "libs/python" or "libs/csharp/Rasm.Bim"); empty = all of libs.',
    phases: [
        { title: 'API-Discover', detail: 'list every .api catalog under the target from disk; _tmp/archives excluded' },
        {
            title: 'API-Substrate',
            detail: 'per-language dispatched write lanes: each language shared tier (libs/<lang>/.api/) rebuilt first inside its own lane — the hub rails that language folder tier stacks onto; a failed hub batch flags the lane',
        },
        {
            title: 'API-Rebuild',
            detail: 'folder-tier dispatched write batches per language lane: one folder per batch, small sibling-folder tails packed up to the batch size; all lanes concurrent under the run-wide slot cap; every cross-catalog defect fixed in-pass',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const CAP = 14;
const BATCH = 4; // .api files per agent — deep enough per file, many agents for parallelism
const ROOT = '/Users/bardiasamiee/Documents/99.Github/Rasm'; // absolute working root: native products mint absolute here, codex lanes take it as cwd

// --- [INPUTS] --------------------------------------------------------------------------

// args is structured data — a scope string, an array of scopes, or {target|targets}; empty = the full libs sweep.
const scopeRows = Array.isArray(args)
    ? args
    : typeof args === 'string'
      ? [args]
      : args && typeof args === 'object'
        ? [].concat(args.targets ?? args.target ?? [])
        : [];
const scopes = scopeRows.map((s) => String(s).trim()).filter((s) => s && s !== 'ALL');
const SWEEP = scopes.length ? scopes.join(', ') : 'libs';
// Per-instance scratch dir for the per-lane report files — minted deterministically from the normalized scope set (clock/randomness
// would break resume): one FLAT dir under .claude/scratch/, a basename slug and an FNV-1a tail so distinct scopes never collide.
const fnv1a = (s) => {
    let h = 0x811c9dc5;
    for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193);
    return (h >>> 0).toString(16).padStart(8, '0').slice(0, 6);
};
const SCRATCH =
    '.claude/scratch/' +
    ('rebuild-api-' + scopes.map((s) => s.split('/').pop().toLowerCase()).join('-')).replace(/[^a-z0-9.-]+/g, '-').slice(0, 60) +
    '-' +
    fnv1a(JSON.stringify(scopes));

// --- [MODELS] --------------------------------------------------------------------------

const DISCOVERY_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files'],
    properties: { files: { type: 'array', items: { type: 'string' } } },
};
// On-disk product schema: each batch writes its complete fix-log here; required-but-empty `beyondBatch` attests
// the cross-catalog hunt ran and every exposed defect landed in-pass.
const FIXLOG_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'beyondBatch', 'verdict', 'summary'],
    properties: {
        files: { type: 'array', items: { type: 'string' } },
        beyondBatch: { type: 'array', items: { type: 'string' } },
        verdict: { type: 'string', enum: ['rebuilt', 'refined', 'clean'] },
        summary: { type: 'string' },
    },
};

// Thin wire receipt: the batch PRODUCT is the edited catalogs on disk and the fix-log at `report`; only status + count + headline travel inline.
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

// --- [DOCTRINE] ------------------------------------------------------------------------

// LAW + rebuildPrompt are the codex-dispatched batch payload: neutral register (hostile-stance/intensifier framing makes a codex
// lane over-probe for zero depth gain); the two naivety axes, ULTRA-STACKING, and phantom deletion are conserved as substance.
const LAW = [
    'Rasm monorepo. .api catalogs are agent-facing declarative records of a package useful surface that DESIGN PAGES compose against. CLAUDE.md ' +
        'DEPENDENCY_POLICY: mine each admitted package to its FULL useful capability; prefer ecosystem primitives over reinvention; internalize ' +
        'capability into canonical owners; treat dependencies as first-class implementation surfaces. House .api format: header (package / version / ' +
        'license / build-floor / marker or target), then member sections grouped by concern, backticked symbols + signatures + a consumer/boundary ' +
        'note. NO provenance/process narration, NO freshness tails. Cite REAL members only — verify via `UV_CACHE_DIR=.cache/uv uv run --frozen ' +
        'python -m tools.assay api resolve <pkg>` (assay api owns external-artifact reflection over host DLLs, NuGet, installed Python distributions, ' +
        'and node_modules declarations per CLAUDE.md OWNER_ROUTING); when reflection is blocked or assay is unavailable, verify through the fallback tier instead ' +
        '— the nuget MCP for NuGet feed truth, Context7 for official API docs, exa/tavily for the package source/official surface — never from ' +
        'memory. Before driving assay, READ tools/assay/README.md for the api-arm contract (its resolve/decompile/reflection invocation, ' +
        'supported artifact kinds, and JSON output shape) so you drive it correctly rather than guessing flags.',
    'LAWS — read `docs/laws/` before any durable edit (README + topology + patterns + scars; short registry pages): a topology row ' +
        'whose [SURFACE] your catalog edits touch binds its obligated counterparts into the SAME pass, and every patterns row binds each ' +
        'branch it names.',
    'MANDATE — INTEGRATION-SHAPED, NOT SURFACE-LEVEL: a rebuilt .api documents (a) the package full ADVANCED surface (combinators, hooks, native ' +
        'pipelines, discriminators, async mirrors — not just the basic members), AND (b) the INTEGRATION patterns the dense design should compose — ' +
        'how this library STACKS with the other admitted libs into single rails (e.g. a decode hook feeding a discriminated model under a retry ' +
        'context with a telemetry span) — INCLUDING the SHARED/UNIVERSAL catalog tier (`libs/python/.api/` for Python; ' +
        '`libs/typescript/.api/` for TypeScript; `libs/csharp/.api/` for C# — the Thinktecture/LanguageExt substrate), so a folder/area catalog ' +
        'documents stacking ONTO those universal rails, not only its sibling-folder ' +
        'libs. The catalog GUIDES the rebuild toward first-class, stacked usage. Reject surface-level member lists.',
    'VERIFICATION LAW: every catalog is unverified until checked against real members — dense, confident-looking catalogs are verified against ' +
        'the package surface, never trusted on appearance, and are the primary site of illusory capability. Naivety is a defect on two orthogonal ' +
        'axes, both intolerable: COVERAGE — the catalog documents a thin slice of its package, the ' +
        'obvious members where the real surface carries far more; APPROACH — enumerated hardcoded instances where one parameterized pattern should ' +
        'own the space (a fixed roster of recipes, variants, or styles is seed DATA feeding one documented parameterized pattern, never the ' +
        'mechanism itself). Every defect list and capability-kind list in this prompt is a FLOOR, never the complete set — hunt past it: any ' +
        'repeated structure, parallel spelling, or enumerable family that one pattern, table, or parameterized rail can own is a collapse target ' +
        'you find yourself. ULTRA-STACKING: enumerate BOTH .api tiers in full from disk and mine each package to operator depth; an admitted ' +
        'capability the package carries but its catalog omits is a defect you close NOW; a cited member that cannot be verified is a phantom you ' +
        'delete NOW.',
    'FIX-IT-NOW LAW: a cross-catalog contradiction or gap your work exposes is YOURS in the same pass, wherever it lives — a hub omitting an ' +
        'anchor your stacking note composes against, a sibling catalog with divergent row grammar, a stale or contradicting claim in a catalog ' +
        'outside your batch: edit THAT catalog directly, either tier, under the CURRENT-STATE law. The batch is a work partition, never a write ' +
        "fence. Package admission is not this pass's surface: catalogs document the admitted set as it stands — a genuinely missing package is " +
        'stated as fact in your summary, never admitted here.',
    'CURRENT-STATE LAW: sibling batches land catalog work concurrently with yours. Before editing any catalog outside your batch — a substrate ' +
        'hub or a sibling folder catalog — re-read its CURRENT on-disk state and compose landed sibling work as found; a conflict between your fix ' +
        'and a landed sibling resolves to the stronger form, never a revert, never a shrink of real content.',
    'WRITE-FULLY MANDATE: every correction you identify you MUST make NOW via Edit/Write directly in the .api file — the structured fix-log is a ' +
        'REPORT of edits ALREADY MADE, never a to-do list or would/should hedge; leave nothing behind. `files` lists every catalog you edited; ' +
        '`beyondBatch` lists those outside your assigned batch — empty attests the cross-catalog hunt found nothing, never that it did not run. ' +
        'Verdict=clean is EARNED by a review that finds nothing, never conceded on first read — and never invent edits to force a verdict.',
].join('\n');

// --- [OPERATIONS] ----------------------------------------------------------------------

// The single run-wide scheduler: CAP agents in flight across every language lane, a freed slot passes to the next waiter.
let active = 0;
const waiters = [];
const acquire = () => (active < CAP ? (active++, Promise.resolve()) : new Promise((res) => waiters.push(res)));
const release = () => {
    const w = waiters.shift();
    if (w) w();
    else active--;
};
const scheduled = async (fn) => {
    await acquire();
    try {
        return await fn();
    } finally {
        release();
    }
};
const chunk = (arr, n) => {
    const o = [];
    for (let i = 0; i < arr.length; i += n) o.push(arr.slice(i, i + n));
    return o;
};

// Codex dispatch: the wrapper runs one blocking supervised CLI process and writes its content
// to the lane report, and returns mechanical orchestration data. Lane law rides developer-instructions
// (role split); the prompt carries only the task; the output contract sits LAST. Every batch EDITS .api
// files in place, so every lane is a write lane.
const fileTag = (label) => label.replace(/[^A-Za-z0-9_.-]+/g, '-');
const laneLaw = (schema) =>
    '<completion_bar>\nDone is every catalog in your named batch rebuilt to its full integration-shaped depth with its ' +
    'fix-log entry written — proof-complete, never effort-spent, never early. Complete every named move before yielding; do ' +
    'not stop at analysis or a partial edit. If the chosen approach resists, pick the next-best one and proceed. Your layer ' +
    'is rebuild-and-repair: a cross-catalog defect your work exposes is edited in place under the FIX-IT-NOW law and listed ' +
    'in beyondBatch, never deferred; a package genuinely absent from the admitted set is stated as fact in summary, never ' +
    'invented — and re-verifying an unchanged catalog or re-reading covered territory adds no evidence; move to the next ' +
    'deliverable instead.\n</completion_bar>\n\n<verification>\nAfter editing, re-read each changed file and confirm it is ' +
    'coherent and nothing it carried was lost. Fix what fails before yielding; a check you did not run is never claimed as ' +
    'run.\n</verification>' +
    '\n\n<output_contract>\nYour final message is a single JSON object with exactly this shape: ' +
    JSON.stringify(schema) +
    '\n- JSON only: no prose before or after it, no code fences, no markdown.\n- Every key shown is required.\n' +
    '- Use null for a value you could not determine and [] for an empty list; never guess.\n</output_contract>';
// Sandbox decides authorship: batch lanes always author their own report, so they run workspace-write and land the product themselves.
const LANE_SCRIPT = ROOT + '/.claude/skills/codex/scripts/codex-lane.sh';
const flagsOf = (o) =>
    [o.model && '--model ' + o.model, o.codexEffort && '--effort ' + o.codexEffort, o.web && '--web']
        .filter(Boolean)
        .map((f) => ' ' + f)
        .join('');

const codexPrompt = (label, task, schema, o) => {
    const base = SCRATCH + '/' + fileTag(label);
    const root = ROOT;
    const report = root + '/' + base + '-report.json';
    const model = o.model || 'gpt-5.6-terra';
    const lane = report + '.lane';
    return (
        'DISPATCH ROLE: a delegate performs the complete TASK below through one supervised lane run; never perform, edit, judge, soften, ' +
        'summarize, or relay the work yourself. (1) Write the LANE LAW block below VERBATIM to ' +
        lane +
        '/law.md and the TASK block below VERBATIM to ' +
        lane +
        '/task.md, composing neither. Delete any leftover file at ' +
        report +
        ' with one Bash rm -f (a stale product there passes the verify probe as a false success). ' +
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
        ' --sandbox workspace-write' +
        flagsOf({ model, codexEffort: o.codexEffort, web: o.web }) +
        '; the harness re-invokes you when the lane exits — Read ' +
        lane +
        '/receipt.json then, never a polling loop. Recovery is two-branch and ONCE-only — the whole budget: a receipt reason "crash" ' +
        'alone (the session persisted on disk) overwrites the task file with "continue and complete the lane, then land the receipt" and ' +
        're-runs the same command plus --resume <the receipt thread_id>; any other failed receipt (max-timeout, turn-failed, ' +
        'refusal) re-runs the same command untouched. (3) The delegate lands the product itself at ' +
        report +
        ' as its final act. (4) Verify with one Bash call: jq -e . ' +
        report +
        ' >/dev/null — a nonzero exit means a missing or malformed product; on a miss re-derive the product once from the lane ' +
        'events.jsonl (jq -rs to the last agent_message item text, Write that), re-probe, and a second miss returns ok=false with the ' +
        'probe output. (5) Return ok=true, report=' +
        base +
        '-report.json (this repo-relative form, matching codex-lane receipts), entries = the length of the "' +
        o.hl.arr +
        '" array in the product, headline="<entries> catalogs | verdict:<verdict> | +<beyondBatch.length> beyond", and failure empty. ' +
        'On a failed receipt return ok=false, entries=0, report and headline empty, and failure equal to the receipt reason and failure ' +
        'text VERBATIM.\n\nLANE LAW:\n\n' +
        laneLaw(schema) +
        '\n\nTASK:\n\n' +
        task +
        '\n\nREPORT FILE (final act): before returning your final message, write that COMPLETE final-message JSON verbatim to ' +
        report +
        ' yourself.'
    );
};
// Every catalog rebuild batch routes here through the codex wrapper. QUOTA FALLBACK: a codex receipt whose failure matches
// usage/quota/limit re-dispatches the SAME task natively at the role's native twin — the caller owns the re-dispatch, the
// wrapper never executes work itself. The roster row carries `scope` from the ORCHESTRATOR (the batch's assigned files) so
// a failed lane's territory is exact even when it died.
const twinOf = (m) => (/-sol/.test(m || '') ? 'fable' : /-luna/.test(m || '') ? 'sonnet' : 'opus');
const nativeLane = (task, o) => {
    // Path authority: a native lane may not follow the session cwd, so the product mints ABSOLUTE under ROOT while the
    // receipt returns the repo-relative form codex lanes report — the aggregation reads one consistent `report` shape.
    const report = SCRATCH + '/' + fileTag(o.label) + '-report.json';
    return agent(
        task +
            '\n\nPRODUCT TO DISK: write your COMPLETE product as one JSON file matching this schema at ' +
            ROOT +
            '/' +
            report +
            ' (Write tool, exactly this absolute path): ' +
            JSON.stringify(o.schema) +
            ' — then return ONLY the receipt: ok, report = ' +
            report +
            ' (this repo-relative form, matching codex-lane receipts), entries count, one-line mechanical headline, failure empty.',
        {
            label: o.label,
            phase: o.phase,
            model: o.nativeModel || twinOf(o.model),
            effort: 'high',
            schema: RECEIPT,
        },
    );
};
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
const rel = (f) => {
    const i = String(f).indexOf('libs/');
    return i > 0 ? String(f).slice(i) : String(f);
};
const isSubstrate = (f) => /^libs\/[^/]+\/\.api\//.test(f);
const isApiPath = (f) => /^libs\/.+\/\.api\/.+\.md$/.test(f); // model-emitted roster guard: only repo-relative libs/**/.api/**.md paths dispatch
const folderOf = (f) => f.slice(0, f.indexOf('/.api/'));
const langOf = (f) => f.split('/')[1] || '';

// Full folder chunks stay whole; sub-BATCH tails of sibling folders in one language pack together — never a 1-catalog agent per tiny folder.
const packFolders = (byFolder) => {
    const batches = [];
    let tail = [];
    for (const k of [...byFolder.keys()].sort()) {
        for (const c of chunk(byFolder.get(k).slice().sort(), BATCH)) {
            if (c.length === BATCH) batches.push({ files: c });
            else if (tail.length + c.length > BATCH) {
                batches.push({ files: tail });
                tail = c;
            } else tail = tail.concat(c);
        }
    }
    if (tail.length) batches.push({ files: tail });
    return batches;
};

const rebuildPrompt = (files, tier, degraded) =>
    [
        LAW,
        '',
        'TASK: REBUILD these .api catalogs to FULL first-class, integration-shaped capability (fix-in-place, read-then-extend; never shrink real ' +
            'content): ' +
            files.join(', '),
        tier === 'substrate'
            ? 'These are SHARED-TIER catalogs — the universal rails every folder tier in this language stacks onto. Beyond the package own advanced ' +
              'surface, document the ANCHOR members downstream catalogs compose against (the service tags, carriers, schema/codec entrypoints, ' +
              'layer/runtime constructors, and cross-package seams that make this the hub) at operator depth — a folder catalog written after you must ' +
              'find every rail it stacks onto already documented here. A defect this work exposes in a sibling substrate catalog outside your batch is ' +
              'yours per the FIX-IT-NOW + CURRENT-STATE laws.'
            : 'The shared substrate tier for this language was rebuilt EARLIER in this run' +
              (degraded && degraded.length
                  ? ' — INCOMPLETELY: the hub batch(es) covering ' +
                    degraded.join(', ') +
                    ' FAILED, so those hubs may still be pre-rebuild. Trust NO ' +
                    'hub as rebuilt: verify every anchor you stack onto against CURRENT disk content, and where a hub omits an anchor your stacking ' +
                    'note composes against, extend that hub YOURSELF per the FIX-IT-NOW + CURRENT-STATE laws.'
                  : '.') +
              ' Read the substrate catalogs your stacking notes ' +
              'compose against FROM DISK and verify every stacking claim against their REAL content — a stacking claim written from memory is ' +
              'a phantom; a hub that truly omits an anchor you stack onto is extended by YOU now per the FIX-IT-NOW + CURRENT-STATE laws, ' +
              'never noted for someone else. Your batch is one folder, or a PACKED set of small sibling folders in one language: unify the row ' +
              'grammar across sibling catalogs in the batch (same family, same ' +
              'shape — provider rows, client/layer/config spellings, asymmetry columns) so siblings read as one family, never divergent one-offs — and ' +
              'a divergent sibling outside your batch is equally yours.',
        'For EACH file run the same 3-lens write: (1) EXTRACT-FULL — confirm the package and document its full useful ADVANCED surface ' +
            '(combinators/hooks/async mirrors/discriminators/native pipelines — a floor, not the set), not the basic subset; (2) REFINE/REFACTOR — ' +
            'restructure to integration-shaped, documenting how this lib STACKS with the universal-tier rails AND sibling admitted libs into single ' +
            'dense rails; (3) HARDEN — the terminal review: check BOTH naivety axes (COVERAGE thin-slice, APPROACH ' +
            'enumerated-instances-where-one-parameterized-pattern-owns-the-space), then remove every phantom member, wrong floor/marker/target, ' +
            'surface-level framing, missing license/ABI/runtime flag, and un-stacked single-feature framing — a defect list you hunt past — and end ' +
            'with a full cold re-read of each finished catalog. Verify members via `UV_CACHE_DIR=.cache/uv uv run --frozen python -m tools.assay api ' +
            'resolve` (blocked: the nuget MCP / Context7 / exa-tavily source tier owns the fallback). Also close any ' +
            'gap a consuming design page genuinely needs (a specific member/signature the design composes). Return the fix-log: `files` = every ' +
            'catalog you edited, `beyondBatch` = those outside your assigned batch.',
    ].join('\n');

const processBatch = (tier, degraded) => async (w) =>
    recon(rebuildPrompt(w.files, tier, degraded), {
        label: 'api:' + w.files[0].split('/.api/')[0].split('/').pop() + ':b' + w.idx + '+' + (w.files.length - 1),
        phase: tier === 'substrate' ? 'API-Substrate' : 'API-Rebuild',
        schema: FIXLOG_SCHEMA,
        scope: w.files,
        hl: { arr: 'files' },
    });
const failedOf = (batches, res) => batches.filter((_, i) => !res[i] || !res[i].ok).flatMap((b) => b.files);
// One language lane: its substrate hubs land before its folder tier; a failed hub batch FLAGS the folder batches instead of failing silently.
const runLane = async (l) => {
    const subRes = l.sub.length
        ? await Promise.all(l.sub.map((w, bi) => scheduled(() => processBatch('substrate', [])({ ...w, idx: bi })).catch(() => null)))
        : [];
    const subFailed = failedOf(l.sub, subRes);
    if (subFailed.length)
        log(
            'Substrate DEGRADED [' +
                l.lang +
                ']: ' +
                subFailed.join(', ') +
                ' — ' +
                l.fold.length +
                ' folder batch(es) proceed FLAGGED: hubs verified from disk, never assumed rebuilt',
        );
    else if (l.sub.length) log('Substrate [' + l.lang + ']: ' + subRes.filter((r) => r && r.ok).length + '/' + l.sub.length + ' hub batches landed');
    const foldRes = l.fold.length
        ? await Promise.all(l.fold.map((w, bi) => scheduled(() => processBatch('folder', subFailed)({ ...w, idx: bi })).catch(() => null)))
        : [];
    return { lang: l.lang, fold: l.fold, subRes, foldRes, subFailed, foldFailed: failedOf(l.fold, foldRes) };
};

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('API-Discover');
const inv = await agent(
    'Enumerate every .api catalog file under ' +
        SWEEP +
        ' from REAL disk state — one find listing over */.api/*.md (and any ' +
        'nested .api subdirs), never a memory-recall inventory: BOTH tiers the scope contains, the shared/universal tier (libs/<lang>/.api/) AND every ' +
        'folder tier (libs/<lang>/<folder>/.api/). EXCLUDE archive and scratch trees: any path segment _tmp, _archive, or node_modules. Return each as ' +
        'a repo-relative path — this listing is the ground truth downstream batches resolve against, an initial pointer never a ceiling. If none ' +
        'exist, return an empty list. Use find; do not cd.',
    { label: 'discover', phase: 'API-Discover', schema: DISCOVERY_SCHEMA, model: 'sonnet', effort: 'low' },
);
const FILES = [...new Set(((inv && inv.files) || []).filter(Boolean).map(rel))].filter(
    (f) => isApiPath(f) && !/(^|\/)(_tmp|_archive|node_modules)\//.test(f),
);
const T0 = FILES.filter(isSubstrate).sort();
const T1 = FILES.filter((f) => !isSubstrate(f) && f.includes('/.api/'));
const LANGS = [...new Set([...T0, ...T1].map(langOf))].sort();
const lanes = LANGS.map((lang) => {
    const byFolder = new Map();
    for (const f of T1.filter((x) => langOf(x) === lang)) {
        const k = folderOf(f);
        if (!byFolder.has(k)) byFolder.set(k, []);
        byFolder.get(k).push(f);
    }
    return {
        lang,
        sub: chunk(
            T0.filter((f) => langOf(f) === lang),
            BATCH,
        ).map((files) => ({ files })),
        fold: packFolders(byFolder),
        folders: byFolder.size,
    };
});
const totalFiles = T0.length + T1.length;
const totalBatches = lanes.reduce((n, l) => n + l.sub.length + l.fold.length, 0);
log(
    'API discover under ' +
        SWEEP +
        ': ' +
        totalFiles +
        ' catalogs (' +
        T0.length +
        ' substrate + ' +
        T1.length +
        ' folder-tier across ' +
        lanes.reduce((n, l) => n + l.folders, 0) +
        ' folders) in ' +
        totalBatches +
        ' batches across ' +
        LANGS.length +
        ' language lane(s); CAP=' +
        CAP,
);

phase('API-Substrate');

phase('API-Rebuild');

// Both groups open before launch: lanes interleave the two tiers across languages; each agent lands in the group its phase option names.
const laneOut = (await Promise.all(lanes.map(runLane))).filter(Boolean);
const done = laneOut.flatMap((l) => [...l.subRes, ...l.foldRes]).filter((r) => r && r.ok);
const FAILED = laneOut.flatMap((l) => [...l.subFailed, ...l.foldFailed]);
const DEGRADED = laneOut
    .filter((l) => l.subFailed.length)
    .map((l) => ({ lang: l.lang, substrateFailed: l.subFailed, flaggedFolderBatches: l.fold.length }));
const edits = done.reduce((n, r) => n + r.entries, 0); // catalog edits reported across batches; each batch's full fix-log stays on disk at its receipt's `report`
log(
    'API rebuild: ' +
        done.length +
        '/' +
        totalBatches +
        ' batches landed (' +
        totalFiles +
        ' catalogs); ' +
        edits +
        ' catalog edits reported' +
        (DEGRADED.length ? ' — DEGRADED lane(s), folder batches ran against unverified hubs: ' + DEGRADED.map((d) => d.lang).join(', ') : '') +
        (FAILED.length ? ' — FAILED (reported, run continues): ' + FAILED.join(', ') : ''),
);

return {
    scope: SWEEP,
    catalogs: totalFiles,
    batches: totalBatches,
    complete: done.length,
    failed: FAILED,
    degraded: DEGRADED,
    edits,
    reports: done.map((r) => r.report),
};
