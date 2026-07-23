export const meta = {
    name: 'survey',
    whenToUse:
        'Deep-research the modern external packages a target planning folder is missing — packages that REPLACE hand-rolled design-page capability or ADD genuine domain capability — then execute end to end in one run: central admission with gates, full-depth .api catalogs, registry closure, and immediate holistic integration into the design pages. args = a planning folder path, an array of paths, or {targets}; target lanes run CONCURRENTLY — only the Admit stage (the central-manifest writer) serializes across targets.',
    description:
        'Package survey-and-integrate over one target planning folder per lane. Scout (the recon lane) maps the folder — admitted packages, hand-rolled capability an ecosystem package owns, domain gaps against the bleeding-edge state of the art — and emits bounded research facets. Research fan (facet lanes with live web search enabled, parallel) hunts the best-in-class modern package per facet, self-validating the admission gate (best-of, platform, newest stable, license, modern packaging, no-dup) with verified versions and members, writing its full candidate dossier to a per-lane report file and returning a thin receipt. ONE admission writer reads every research report IN FULL from disk, consolidates adversarially, hand-edits the central manifest + owning project registry + folder README bidirectionally (adds, and ripple-removes superseded packages), runs the restore/lock gate with the toolchain fallback, self-heals, and reverts what cannot resolve. Catalog writers (parallel) author the .api catalogs at FULL depth — decompile/feed-verified members, [STACKING], homed to the owning tier (folder or language root). Mapper fan (recon lanes) then reads ALL planning-folder pages, the landed catalogs (new first), and the language-root tier, writing information maps to report files — locations, verified members, integration shapes as fact, never prescriptions — and returning thin receipts. ONE terminal executor reads the map reports from disk and implements the whole integration: new pages/sub-folders where the capability demands an owner, existing pages improved and extended in place, holistic composition never tacked-on rows, index-doc closure, every ripple in the same pass. All target lanes run CONCURRENTLY under one agent-level slot cap; the Admit stage alone serializes across targets, and shared-tier catalogs of one language route through one serialized writer so concurrent lanes never collide on the language-root .api files. The scout hand-roll census feeds every Research facet and the Integrate executor; Scout, Admit, and Integrate each carry one bounded re-attempt. The admit and integrate writers carry a required-but-usually-empty harvest attestation; when any lane pools a non-empty nomination, ONE terminal doctrine lander adjudicates them against docs/laws (refutation-first, land-nothing legal) and nothing follows it. Otherwise nothing follows the executor; cold-verify runs separately when wanted.',
    phases: [
        {
            title: 'Scout',
            detail: 'one recon lane per target: folder map, hand-roll census, domain gaps, bounded research facets',
        },
        {
            title: 'Research',
            detail: 'one facet lane with live web search, parallel under the pool cap: best-in-class modern candidates, gate self-validated, versions/licenses/members verified, dossier to disk + thin receipt',
        },
        {
            title: 'Admit',
            detail: 'one writer, serialized across targets: reads research reports from disk, adversarial consolidation, central manifest + registry + README bidirectional edits, restore/lock gate, self-heal, revert on failure',
            model: 'fable',
        },
        {
            title: 'Catalog',
            detail: 'parallel writers: full-depth .api catalogs for every admitted package, verified members, [STACKING], owning-tier homing; shared-tier catalogs of one language route through one serialized writer',
            model: 'fable',
        },
        {
            title: 'Map',
            detail: 'recon mappers over all planning pages + both .api tiers, new catalogs first: information maps to disk + thin receipts, never prescriptions',
        },
        {
            title: 'Integrate',
            detail: 'one executor: reads map reports from disk, then the whole integration in place — new owners where demanded, existing pages grown, index docs closed, ripples in-pass',
            model: 'fable',
        },
        {
            title: 'Doctrine',
            detail: 'terminal doctrine lander, fires only on non-empty pooled harvest: adjudicates admit/integrate nominations against docs/laws, refutation-first, land-nothing legal',
            model: 'fable',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const CAP = 14;
const MAP_SLICE = 5; // planning pages per mapper
const CATALOG_BATCH = 2; // admitted packages per catalog writer

// --- [INPUTS] --------------------------------------------------------------------------

const normTarget = (t) =>
    String(t)
        .trim()
        .replace(/\/+$/, '')
        .replace(/\/\.planning$/, '');
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
const TARGETS = [...new Set(rawTargets.filter(Boolean).map(normTarget))];

// Per-instance scratch dir — per-lane report files, one FLAT dir per instance. Minted deterministically from the normalized target set
// (clock/randomness would break resume): a human-readable basename slug with an FNV-1a tail so distinct target sets never share a directory.
const fnv1a = (s) => {
    let h = 0x811c9dc5;
    for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193);
    return (h >>> 0).toString(16).padStart(8, '0').slice(0, 6);
};
const SCRATCH =
    '.claude/scratch/' +
    ('survey-' + TARGETS.map((t) => t.split('/').pop().toLowerCase()).join('-')).replace(/[^a-z0-9.-]+/g, '-').slice(0, 60) +
    '-' +
    fnv1a(JSON.stringify(TARGETS));

// --- [MODELS] --------------------------------------------------------------------------

// Scout is the run's one INLINE codex payload: facets fan the Research stage and pages slice the Map
// stage, so the typed JSON must travel through structured output; failure is ok=false + `failure`.
const SCOUT_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['ok', 'failure', 'domain', 'packages', 'pages', 'facets', 'handRolls'],
    properties: {
        ok: { type: 'boolean' },
        failure: { type: 'string' },
        domain: { type: 'string' },
        packages: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['name', 'version', 'role'],
                properties: {
                    name: { type: 'string' },
                    version: { type: 'string' },
                    role: { type: 'string' },
                },
            },
        },
        handRolls: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['capability', 'evidence'],
                properties: {
                    capability: { type: 'string' },
                    evidence: { type: 'string' },
                },
            },
        },
        pages: { type: 'array', items: { type: 'string' } }, // real listing of the folder design pages
        facets: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['id', 'direction', 'gap', 'mandate'],
                properties: {
                    id: { type: 'string' },
                    direction: { type: 'string' },
                    gap: { type: 'string' },
                    mandate: { type: 'string' },
                },
            },
        },
    },
};

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

const COVERAGE = {
    type: 'object',
    additionalProperties: false,
    required: ['requested', 'read', 'skipped', 'unverified'],
    properties: {
        requested: { type: 'array', items: { type: 'string' } },
        read: { type: 'array', items: { type: 'string' } },
        skipped: { type: 'array', items: { type: 'string' } },
        unverified: { type: 'array', items: { type: 'string' } },
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

const RESEARCH_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['facet', 'candidates', 'coverage'],
    properties: {
        facet: { type: 'string' },
        candidates: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: [
                    'package',
                    'fills',
                    'ok',
                    'version',
                    'license',
                    'bestOf',
                    'platformOk',
                    'newest',
                    'licenseOk',
                    'modernPkg',
                    'notDup',
                    'dupOf',
                    'alternativesConsidered',
                    'evidence',
                    'members',
                    'files',
                    'anchors',
                ],
                properties: {
                    package: { type: 'string' },
                    fills: { type: 'string' },
                    version: { type: 'string' },
                    license: { type: 'string' },
                    bestOf: { type: 'boolean' },
                    platformOk: { type: 'boolean' },
                    newest: { type: 'boolean' },
                    licenseOk: { type: 'boolean' },
                    modernPkg: { type: 'boolean' },
                    notDup: { type: 'boolean' },
                    dupOf: { type: 'string' },
                    ok: { type: 'boolean' },
                    alternativesConsidered: { type: 'string' },
                    evidence: { type: 'string' },
                    members: { type: 'array', items: { type: 'string' } }, // verified member spellings backing the capability claim
                    files: { type: 'array', items: { type: 'string' } }, // repo files the admission writer must open: census sites, overlapping catalogs, manifest rows
                    anchors: { type: 'array', items: ANCHOR },
                },
            },
        }, // repo-side coordinates only; web truth stays in `evidence`
        coverage: COVERAGE,
    },
};

const ADMIT_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['admitted', 'skipped', 'files', 'green', 'harvest', 'summary'],
    properties: {
        admitted: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['package', 'version', 'catalog', 'license', 'replaces'],
                properties: {
                    package: { type: 'string' },
                    version: { type: 'string' },
                    license: { type: 'string' },
                    catalog: { type: 'string' }, // canonical .api path at the OWNING tier the Catalog stage fills
                    replaces: { type: 'string' },
                },
            },
        },
        skipped: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['package', 'why'],
                properties: {
                    package: { type: 'string' },
                    why: { type: 'string' },
                },
            },
        },
        files: { type: 'array', items: { type: 'string' } },
        green: { type: 'boolean' },
        harvest: HARVEST,
        summary: { type: 'string' },
    },
};

const CATALOG_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'summary', 'phantomsDropped'],
    properties: {
        files: { type: 'array', items: { type: 'string' } },
        phantomsDropped: { type: 'array', items: { type: 'string' } },
        summary: { type: 'string' },
    },
};

const MAP_SCHEMA = {
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
                    target: { type: 'string' },
                    kind: { type: 'string', enum: ['state', 'stacking', 'gap', 'ripple', 'registry'] },
                    files: { type: 'array', items: { type: 'string' } }, // files the executor must open for this entry
                    info: { type: 'string' }, // the fact: current shape, integration shape, gap — prose truth, zero prescriptions
                    anchors: { type: 'array', items: ANCHOR }, // exact coordinates backing the fact
                    members: { type: 'array', items: { type: 'string' } },
                },
            },
        }, // verified member spellings backing a stacking entry
        coverage: COVERAGE,
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

const FIXLOG = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'built', 'beyond', 'harvest', 'summary'],
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
        harvest: HARVEST,
        summary: { type: 'string' },
    },
};

// --- [DOCTRINE] ------------------------------------------------------------------------

const LANG = {
    cs: {
        key: 'cs',
        root: 'libs/csharp',
        stack: 'docs/stacks/csharp',
        manifest:
            '`Directory.Packages.props` (central pins, label-grouped, one-line maintenance comments) + `Directory.Build.props` (net10.0 floor, osx-arm64)',
        registry: 'the owning `.csproj` PackageReference rows and the folder README package sections',
        gate:
            '`UV_CACHE_DIR=.cache/uv uv run --frozen python -m tools.assay static --project <csproj>` (one JSON Envelope on stdout); assay unavailable: `dotnet restore` + ' +
            '`dotnet build` at the same green criterion',
        runtime:
            'PLATFORM: osx-arm64 on net10.0 — managed AnyCPU, an osx-arm64 native asset, or a Forge-provisioned native substrate; reject ' +
            'win-only/x64-only/dead-on-arm. For a multi-target package decompile the lib/<tfm> a net10 consumer actually binds (assay default ' +
            'resolution can pick a non-bound TFM whose surface differs — set DOTNET_ROOT and run `ilspycmd <pkg>/lib/<consumer-tfm>/<asm>.dll ' +
            '-t <FQN>` when in doubt); never document a member from a non-bound TFM.',
    },
    py: {
        key: 'py',
        root: 'libs/python',
        stack: 'docs/stacks/python',
        manifest: '`pyproject.toml` (dependencies / dependency-groups, lean unpinned names by default)',
        registry: 'the folder README package sections',
        gate: '`uv lock` + `uv sync` + import-verification of the new modules + `ruff check` at the same green criterion',
        runtime:
            'RUNTIME: the workspace floor is CPython 3.15 on osx-arm64; admissibility is decided by an ACTUAL `uv lock` + `uv sync` + import ' +
            'on cp315, never wheel-presence alone — a pure-Python/cp315-clean wheel or a native sdist that source-builds via the Forge scientific ' +
            'toolchain is admitted un-gated; a `python_version` marker is honest only for a real reported cp315 build failure. Verify members ' +
            'against the actually-installed distribution.',
    },
    ts: {
        key: 'ts',
        root: 'libs/typescript',
        stack: 'docs/stacks/typescript',
        manifest: '`pnpm-workspace.yaml` (catalog)',
        registry: 'the folder README package sections',
        gate: '`pnpm install` + `pnpm -r build` (or `tsc -p`) over the affected packages at the same green criterion',
        runtime:
            'RUNTIME: verify members against the published types in node_modules `.d.ts` declarations; a member absent from the published types is a phantom.',
    },
};
const langOf = (t) =>
    t.indexOf('libs/csharp') === 0 ? 'cs' : t.indexOf('libs/python') === 0 ? 'py' : t.indexOf('libs/typescript') === 0 ? 'ts' : null;

// --- [OPERATIONS] ----------------------------------------------------------------------

// Agent-level slot scheduler: CAP agents in flight across ALL target lanes, work-conserving backfill the moment a
// slot frees. The single governor for every agent call.
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
const RETRY_ATTEMPTS = 2;
// Bounded re-dispatch for a dead CRITICAL lane (scout, admit, integrate): attempt-counted with a retry BEFORE each attempt — the
// Retry releases the slot and admit's serial window so siblings continue. `ok` defaults to non-null; scout
// passes an ok-field predicate. The final death isolates the lane, never the run — the caller's data-dependency guard stops an empty chain.
const retryLane = async (fn, ok = (r) => !!r) => {
    for (let a = 0; a < RETRY_ATTEMPTS; a++) {
        const r = await fn();
        if (ok(r)) return r;
    }
    return null;
};

// Serial write chains — first lane to arrive goes first; the slot is acquired INSIDE the chained thunk, so a
// queued lane never holds a slot while waiting its turn.
const makeChain = () => {
    let tail = Promise.resolve();
    return (fn) => {
        const p = tail.then(fn, fn);
        tail = p.then(
            () => undefined,
            () => undefined,
        );
        return p;
    };
};
const admitSerial = makeChain(); // ONE central-manifest writer at a time across all targets
const sharedSerial = { cs: makeChain(), py: makeChain(), ts: makeChain() }; // ONE language-root .api writer at a time per language
const chunk = (arr, n) => {
    const o = [];
    for (let i = 0; i < arr.length; i += n) o.push(arr.slice(i, i + n));
    return o;
};

// Dispatch: the wrapper runs one supervised codex-lane.sh lane in the background, reads the receipt, verifies the
// --out product, and returns mechanical orchestration data. Lane law rides --law (developer-instructions,
// role split); the --task file carries only the task; the output contract sits LAST. A web-research lane (o.web)
// rides --web and takes a territory clause that admits its web tools and the named packages' official sources over repo files.
const fileTag = (label) => label.replace(/[^A-Za-z0-9_.-]+/g, '-');
// Per-target own-pass artifact path — the integrate executor's blind integration plan, distinct from its map reports.
const ownPassArt = (t, stage) => SCRATCH + '/' + fileTag(t.split('/').pop()) + '-' + stage + '-ownpass.md';
const laneLaw = (schema, o) =>
    '<context_gathering>\nTerritory: ' +
    (o.web
        ? 'the official sources of the packages the task names — the package registry (PyPI/NuGet/npm), the package docs, ' +
          'and the source repository — for landscape, newest version, license, and maintenance, AND the exact repo files the ' +
          'task cites for cross-check. Use web search and fetch freely over those sources; do not open repo files beyond the ' +
          'ones the task names, and never open skill or instruction files (.claude/, CLAUDE.md, AGENTS.md).'
        : 'the exact files and directories the task names. Do not open files outside it, including skill or instruction ' +
          'files (.claude/, CLAUDE.md, AGENTS.md).') +
    '\nBudget: at most ' +
    (o.calls || 60) +
    ' tool calls total. Read in small batches (a handful of files per command, line-capped); never concatenate the whole ' +
    'territory into one command - tool output truncates and the data is lost.\nStop as soon as the product is complete. ' +
    'If something is still uncertain at the budget, proceed and record the residue in the product coverage/unverified field ' +
    'instead of re-reading.\n</context_gathering>\n\n<verification>\nBefore the final message, confirm every cited ' +
    'spelling appears verbatim in the cited file or source; anything unconfirmed is recorded as a gap, never asserted.\n' +
    '</verification>' +
    '\n\n<output_contract>\nYour final message is a single JSON object with exactly this shape: ' +
    JSON.stringify(schema) +
    '\n- JSON only: no prose before or after it, no code fences, no markdown.\n- Every key shown is required.\n' +
    '- Use null for a value you could not determine and [] for an empty list; never guess.\n</output_contract>';

// One core builder for both codex lanes; only step (4) differs — codexPrompt returns a thin receipt, codexInline
// relays the product JSON verbatim (scout's payload is small orchestration input that fans Research and slices Map).
const LANE_SCRIPT = '/Users/bardiasamiee/Documents/99.Github/Rasm/.claude/skills/codex/scripts/codex-lane.sh';
const codexSteps = (label, task, schema, o, step4) => {
    const base = SCRATCH + '/' + fileTag(label);
    const root = '/Users/bardiasamiee/Documents/99.Github/Rasm';
    const report = root + '/' + base + '-report.json';
    const lane = report + '.lane';
    return [
        'DISPATCH ROLE: a delegate performs the complete TASK below through one supervised lane run; never perform, edit, judge, ' +
            'soften, summarize, or relay the work yourself.',
        '(1) Write the LANE LAW block below VERBATIM to ' +
            lane +
            '/law.md and the TASK block below VERBATIM to ' +
            lane +
            '/task.md, composing neither.',
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
            ' --sandbox read-only --model gpt-5.6-terra' +
            (o.codexEffort ? ' --effort ' + o.codexEffort : '') +
            (o.web ? ' --web' : '') +
            ' --out ' +
            report +
            '; the harness re-invokes you when the lane exits — Read ' +
            lane +
            '/receipt.json then, never a polling loop. Recovery is two-branch and ONCE-only — the whole budget: a receipt reason "crash" ' +
            'alone (the session persisted on disk) overwrites the task file with "continue and complete the lane, then land the receipt" and ' +
            're-runs the same command plus --resume <the receipt thread_id>; any other failed receipt (max-timeout, turn-failed, ' +
            'refusal) re-runs the same command untouched.',
        'LANE LAW:\n\n' + laneLaw(schema, o),
        'TASK:\n\n' + task,
        // recon lanes: --out materializes the product; a jq gate catches a dropped tail before the receipt asserts ok.
        '(3) The lane lands the product at ' +
            report +
            ' via --out. Verify with one Bash call: jq -e . ' +
            report +
            ' >/dev/null — a nonzero exit means a missing or malformed product; on a miss re-derive the product once from the lane ' +
            'events.jsonl (jq -rs to the last agent_message item text, Write that), re-probe, and a second miss returns through step (4) with the error.',
        step4(base, report),
    ].join('\n\n');
};
const codexPrompt = (label, task, schema, o) =>
    codexSteps(
        label,
        task,
        schema,
        o,
        (base, report) =>
            '(4) Read the product at ' +
            report +
            ' to compute ' +
            o.head.arr +
            '.length and the configured kind tallies. Return ok=true, report=' +
            base +
            '-report.json, entries=that count, headline="<entries> ' +
            o.head.unit +
            ' | <kind tallies>", and failure empty. On a failed receipt return ok=false, entries=0, report and headline ' +
            'empty, and failure equal to the receipt reason and failure text VERBATIM.',
    );
const codexInline = (label, task, schema, o) =>
    codexSteps(
        label,
        task,
        schema,
        o,
        (base, report) =>
            '(4) Read the product at ' +
            report +
            ' and return that JSON through your structured output VERBATIM. On a failed receipt return the schema ' +
            'shape with ok=false, failure equal to the receipt reason and failure text VERBATIM, every array empty, and every other string empty.',
    );
// jq headline bits per receipt product: mechanical counts by gate/kind, never lane judgment.
const HEAD = {
    research: { arr: '.candidates', kind: '[.candidates[] | if .ok then "gated" else "rejected" end]', unit: 'candidates' },
    map: { arr: '.entries', kind: '[.entries[].kind]', unit: 'entries' },
};

// Native re-dispatch target for a dispatched lane; survey uses one arm, the others carry for parity.
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
            ' — then return ONLY the receipt: ok, report path, entries count, one-line mechanical headline, failure empty.',
        { label: o.label, phase: o.phase, model: o.nativeModel || twinOf(o.model), effort: 'high', schema: RECEIPT },
    );

// Every heavy read/investigate lane routes through the codex wrapper. QUOTA FALLBACK: a receipt whose
// failure matches usage/quota/limit re-dispatches the SAME task at the role's native twin; the caller owns the re-dispatch, and the
// wrapper never executes work itself. The roster row carries `scope` from the ORCHESTRATOR (never the lane's self-report) so a failed lane's
// uncovered territory is exact even when the lane died before writing anything.
const recon = (task, o) =>
    agent(codexPrompt(o.label, task, o.schema, o), {
        label: 'terra:' + o.label,
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
// Scout is the run's one inline codex lane: the wrapper relays the SCOUT_SCHEMA product verbatim (ok/failure carried in-shape). Quota failure
// re-dispatches the same task on a native lane; a non-quota failure is final.
const scoutLane = (task, o) => {
    const native = () => agent(task, { label: o.label, phase: o.phase, model: 'opus', effort: 'high', schema: o.schema });
    return agent(codexInline(o.label, task, o.schema, o), {
        label: 'terra:' + o.label,
        phase: o.phase,
        model: 'sonnet',
        effort: 'low',
        schema: o.schema,
    }).then((r) => (r && r.ok === false && /usage|quota|limit/i.test(r.failure || '') ? native() : r));
};

// --- [SHARED_BLOCKS] -------------------------------------------------------------------

const CTX = (t, L) =>
    'Rasm monorepo, planning phase — the work product is design pages, index docs, central manifests, and .api ' +
    'catalogs; no source files land. Target planning folder: ' +
    t +
    ' (design pages under ' +
    t +
    '/.planning/, folder catalogs ' +
    'under ' +
    t +
    '/.api/, shared substrate catalogs under ' +
    L.root +
    '/.api/). Central pins live in ' +
    L.manifest +
    ' — never a ' +
    'per-package manifest. All .md prose follows docs/standards/style-guide.md: declarative agent-facing law, no provenance, no ' +
    'process narration, no hedges. Never run git commit.';

const MEMBER_TRUTH = (L) =>
    'MEMBER TRUTH — verify external members via `UV_CACHE_DIR=.cache/uv uv run --frozen python -m tools.assay api` ' +
    '(decompile/reflection); when the assay rail is unavailable or errors, truth routes through the fallback tier: both .api tiers, ' +
    'the nuget MCP (feed truth: newest version, license, TFMs, deprecation), Context7 for the official surface, exa/tavily source ' +
    'reads. A package, version, or member no tier can verify is a PHANTOM: never survey it, never cite it, never admit it. ' +
    L.runtime;

const ADMISSION_GATE =
    'ADMISSION GATE — every candidate passes ALL of: BEST-OF (the strongest package for the gap, real ' +
    'alternatives compared, never the first found); PLATFORM (resolves on the workspace floor); NEWEST (current stable named, ' +
    'actively maintained); LICENSE (OSS under any OSI license, or a commercial grant that is free with full access — any fee, ' +
    'subscription, seat cap, usage tier, or eval-only grant is REJECTED; state the exact SPDX/grant); MODERN PACKAGING (current ' +
    'TFM/abi/wheel era; reject abandoned or outdated-framework-only artifacts); NO-DUP (does not duplicate an admitted package or a ' +
    'sibling candidate — when two overlap, keep the single best and set dupOf on the loser). The gate is a FLOOR: hunt disqualifiers ' +
    'beyond it — dead or vulnerable transitive dependencies, native supply-chain rot, eval-gated features behind an OSS shell — and ' +
    'any found disqualifier is evidence for ok=false. Default ok=false on any unproven condition.';

const ADDITION_LAW =
    'ADDITION LAW — aggressive, zero hedging: admit a package whenever it provides unique, modern capability ' +
    "appropriate to the folder domain, judged for five times today's demands. DECLINE only for a real reason: old/unmaintained/" +
    'low-quality, a strictly stronger alternative already admitted, or out of the folder domain. Never decline for lack of a ' +
    'CURRENT consumer — planned consumers are real design pressure. Never add for its own sake, never add a thin wrapper over an ' +
    'admitted surface, and only remove a package when another admitted package provably covers every site it serves (cite the ' +
    'subsumer and the sites); a replacement must be strictly more modern/capable/maintained, never a lateral move. A justified ' +
    'admission is executed FULLY in this run — manifest + registry + README + full-depth catalog + real design integration — never ' +
    'recorded as future or deferred work.';

const CATALOG_LAW = (L) =>
    'CATALOG LAW — a catalog is homed to its OWNING tier: a folder-domain package lives at the folder ' +
    'tier, a cross-folder substrate package at ' +
    L.root +
    '/.api/. House format: header (package / version / license / floor), ' +
    'member sections grouped by concern with backticked symbols + signatures + a consumer/boundary note, and a [STACKING] section ' +
    'stating how the package composes with the admitted substrate rails and its sibling domain packages into single dense rails. ' +
    'Full advanced surface at operator depth — real members only, verified per MEMBER TRUTH; a member you cannot verify is dropped ' +
    'and reported, never kept.';

const INFO_LAW =
    'You provide INFORMATION, never prescriptions: exact disk locations and anchors, the current shape at each ' +
    'site, verified member spellings, integration shapes as fact. The executor decides how to build; a map entry that tells it ' +
    'what to write instead of what is true is a defect. ENTRY FORM: `info` is prose truth; `anchors` carry one coordinate per ' +
    'row (role names what it proves; `note` is the shortest literal witness under 20 words, or empty when path+line suffice; an ' +
    '`absence` anchor names where the expected thing was searched and not found); `files` lists what the executor must open for ' +
    'the entry. An underutilized-capability entry is INVENTORY, never instruction: verified members, current usage anchors, the ' +
    'concept that admits it — the executor decides whether it composes. COVERAGE is part of the product: `requested` = your ' +
    'assigned scope, `read` = what you actually full-read, `skipped`/`unverified` = what you did not reach — an honest skip ' +
    'beats a silent one.';

const OWN_PASS = (artifact) =>
    'OWN PASS FIRST — the input ladder is binding, in order: (1) your own blind integration read, (2) the map reports. Rung ' +
    '(1) is the PRIMARY product and it is a DISK ARTIFACT, not a reading step: cold-read every folder design page from CURRENT ' +
    'disk and WRITE your own integration plan to `' +
    artifact +
    '` — where each admitted package replaces a hand-rolled site, which page owner grows to absorb it, where a new page or ' +
    'sub-folder is warranted because no owner carries the concept, and the underutilized capability the catalogs expose — ' +
    'BEFORE opening any map report. The maps may only ADD rows to that file, each tagged [recon]; reading the pages without ' +
    'writing the plan is a failed rung, not a cold pass. Rung (2) grounds, verifies, and widens YOUR plan — it never scopes, ' +
    'substitutes for, or caps it. TRIPWIRE: a diff dominated by [recon]-tagged rows has failed — the maps cover a MINORITY of ' +
    'what the integration demands, and the majority of your edits must come from your own attack.';

const WRITE_LAW =
    'WRITE FULLY — every fix you identify you make NOW via Edit/Write; a fix-log reports edits already made, ' +
    'never a to-do or a hedge. Every ripple your edit exposes is YOURS in the same pass — any project file, both seam ends, ' +
    'consumer sites, index docs. Landed sibling work is composed as found; a conflict resolves to the stronger form, never a revert.';

const LAWS_READ =
    'LAWS — read `docs/laws/` before any durable edit (README + topology + patterns + scars; short registry pages): a ' +
    'topology row whose [SURFACE] your edits touch binds its obligated counterparts into the SAME pass, and every patterns row ' +
    'binds each branch it names.';

const HARVEST_LAW =
    'HARVEST (required key, usually empty): nominate ONLY findings that generalize beyond this target — a collapse pattern reusable ' +
    'across folders, a naivety class no doctrine clause names, a review rule that would have caught a defect BEFORE review, a ' +
    'cross-surface coupling discovered the hard way. Each row: altitude (stacks|reviewer|constitution|planning|readme|laws), lang, ' +
    'claim (the generalized law, one sentence, SYMBOL-FREE — every concrete spelling lives in anchors, so the lander adjudicates ' +
    'the law without re-deriving its locality), anchors (file:line evidence), existingClause (the exact doctrine or reviewer clause ' +
    'it would harden, quoted with its path — or "absent" with the surfaces searched). A target-local fix never nominates; an empty ' +
    'array is the normal verdict — the terminal doctrine lander refutes weak rows, so nominate substance, never volume.';

// --- [COMPOSITION] ---------------------------------------------------------------------

if (!TARGETS.length) {
    log('No targets — pass a planning folder path, an array of paths, or {targets}. Empty args is a no-op.');
    return { targets: [], lanes: [] };
}

const badLang = TARGETS.filter((t) => !langOf(t));

if (badLang.length) {
    log('Targets must live under libs/csharp | libs/python | libs/typescript. Got: ' + JSON.stringify(badLang));
    return { targets: TARGETS, lanes: [] };
}

// All target lanes run CONCURRENTLY; the slot scheduler is the only concurrency governor. The phases are declared up front — concurrent lanes
// route every agent to its group via the per-call phase option and never race the global phase(). Only Admit serializes across lanes (admitSerial);
// shared-tier catalogs of one language serialize through sharedSerial so lanes never collide on the language-root .api files.
phase('Scout');
phase('Research');
phase('Admit');
phase('Catalog');
phase('Map');
phase('Integrate');
phase('Doctrine');

const lane = async (t) => {
    const L = LANG[langOf(t)];
    const tag = t.split('/').pop();

    // --- [SCOUT]
    // Scout/research/map are codex-primary lanes: their task text is neutral-register (a hostile stance makes them
    // over-probe); the native admit/catalog/integrate builders keep the estate register — same substance.
    const scoutPrompt = [
        CTX(t, L),
        MEMBER_TRUTH(L),
        ADDITION_LAW,
        'TASK: READ-ONLY SCOUT (investigate, do NOT edit). Map ' +
            t +
            ' against real disk, never memory: `ls`/`fd` the ' +
            'folder tree and BOTH .api tiers, then FULL-read the README, the project/registry surface, every folder-tier catalog, every ' +
            'design page under ' +
            t +
            "/.planning/, the substrate-tier catalogs the folder references, and the folder's central " +
            'manifest rows. Return: `domain` (1-2 sentences); `packages` (every admitted package with version and a candid role call); ' +
            '`handRolls` (each capability the design pages implement by hand that a real ecosystem package owns, with a verified ' +
            'page-section evidence pointer); `pages` (the real listing of every design page); `facets` — 4 to 8 non-overlapping research ' +
            "directions that together cover the folder's highest-value package gaps, judged against the bleeding-edge state of the art " +
            'on both naivety axes (COVERAGE: the folder models a thin slice of its domain; APPROACH: hand-rolled enumeration where a ' +
            'package-backed generator should own the space). Each facet is all its researcher receives — pack the mandate with the ' +
            'admitted-adjacent packages the candidate must NOT duplicate and the seams it must integrate with; the facet is a pointer, ' +
            'never a ceiling. A completed scout sets `ok` true with `failure` empty; a scout that cannot complete sets `ok` false with ' +
            'the one-line reason in `failure` and every array empty.',
    ].join('\n\n');
    const scoutOpts = { label: 'scout:' + tag, phase: 'Scout', schema: SCOUT_SCHEMA, calls: 120 };
    // A dead or failed scout no-ops the whole lane after bounded re-dispatch, and the
    // original failed receipt survives a still-dead retry so the log keeps its reason.
    let scout = await slot(() => scoutLane(scoutPrompt, scoutOpts));
    if (!(scout && scout.ok))
        scout =
            (await retryLane(
                () => slot(() => scoutLane(scoutPrompt, { ...scoutOpts, label: 'scout:' + tag + ':a1' })),
                (r) => r && r.ok,
            )) || scout;
    const facets = ((scout && scout.facets) || []).filter((f) => f && f.id);
    // Scout is a model emitting a path roster the Map stage slices and dispatches on: keep only real in-target paths so a hallucinated
    // coordinate never mints a mapper over nothing (an out-of-target roster degrades to Integrate's own cold read, never a bad dispatch).
    const pages = ((scout && scout.pages) || []).filter((p) => p && String(p).indexOf(t + '/') === 0);
    const handRolls = ((scout && scout.handRolls) || []).filter(Boolean);
    log(
        tag +
            ' scout: ' +
            facets.length +
            ' facet(s), ' +
            pages.length +
            ' page(s), ' +
            handRolls.length +
            ' hand-roll(s)' +
            (scout && !scout.ok && scout.failure ? ' — FAILED: ' + scout.failure : ''),
    );
    if (!facets.length) return { target: t, admitted: 0, note: 'no research facets' };

    // --- [RESEARCH]
    const research = (
        await Promise.all(
            facets.map((fc) =>
                slot(() =>
                    recon(
                        [
                            CTX(t, L),
                            MEMBER_TRUTH(L),
                            ADMISSION_GATE,
                            ADDITION_LAW,
                            'TASK: RESEARCH one facet (read-only, then self-validate). facet=' +
                                fc.id +
                                ' · direction=' +
                                fc.direction +
                                ' · gap=' +
                                fc.gap +
                                (fc.mandate ? ' · mandate=' + fc.mandate : '') +
                                '. Find the best-in-class MODERN package(s) that close this gap ' +
                                'for the folder domain. The facet is your initial pointer, never a ceiling: re-derive the landscape yourself and sweep the ' +
                                'full space it names — the first-found candidate is provisional until the real alternatives are compared and ' +
                                'the strongest named. Reject a thin-slice package covering one corner when a full-space owner exists; prefer one ' +
                                "parameterized owner over a roster of point solutions. The folder's scout-verified HAND-ROLL CENSUS — capability the " +
                                'design pages implement by hand that a real package owns — is: ' +
                                JSON.stringify(handRolls) +
                                '; a candidate that owns ' +
                                'one of these census sites outranks one that merely adjoins the gap. Web research for landscape/newest/maintenance/license; registry ' +
                                'truth for versions and licenses; members per MEMBER TRUTH. Exclude anything already admitted unless it is a strictly ' +
                                'stronger replacement (then set `fills` to name what it replaces). Self-validate each candidate against the ADMISSION GATE ' +
                                'and return the gate fields with evidence and the alternatives compared. CANDIDATE FORM: `members` = the verified member ' +
                                'spellings backing the capability claim; repo-side facts carry coordinates — the census site a candidate owns, the admitted ' +
                                'catalog or manifest row it overlaps — as `anchors` (role names what each proves; `note` = shortest literal witness under ' +
                                '20 words, or empty; an `absence` anchor names where the expected thing was searched and not found) with `files` = the repo ' +
                                'files the admission writer must open; web truth stays in `evidence`. COVERAGE is part of the product: `requested` = your ' +
                                'facet scope, `read` = the registries, sources, and repo surfaces you actually consulted, `skipped`/`unverified` = what you ' +
                                'did not reach — an honest skip beats a silent one. Write nothing.',
                        ].join('\n\n'),
                        {
                            label: 'research:' + tag + ':' + fc.id,
                            phase: 'Research',
                            schema: RESEARCH_SCHEMA,
                            web: true,
                            calls: 80,
                            head: HEAD.research,
                            scope: [fc.id + ' | ' + fc.direction + ' | ' + fc.gap],
                        },
                    ),
                ),
            ),
        )
    ).filter(Boolean);
    const researched = research.filter((r) => r.ok);
    const candTotal = researched.reduce((n, r) => n + r.entries, 0);
    const unresearched = research.filter((r) => !r.ok).flatMap((r) => r.scope.map((sc) => ({ lane: r.lane, scope: sc })));
    log(
        tag +
            ' research: ' +
            researched.length +
            '/' +
            facets.length +
            ' facet report(s), ' +
            candTotal +
            ' candidate(s)' +
            (unresearched.length
                ? ' — FAILED: ' +
                  research
                      .filter((r) => !r.ok)
                      .map((r) => r.lane)
                      .join(', ')
                : ''),
    );
    if (!researched.length) return { target: t, admitted: 0, note: 'no research reports landed' };

    // --- [ADMIT]
    // Serialized across lanes: one central-manifest writer at a time. Research products stay on disk;
    // the writer consumes the roster's report files, never an inlined payload.
    const admitPrompt = [
        CTX(t, L),
        MEMBER_TRUTH(L),
        ADMISSION_GATE,
        ADDITION_LAW,
        WRITE_LAW,
        LAWS_READ,
        HARVEST_LAW,
        "TASK: ADMISSION WRITER — you are the run's only central-manifest writer while you hold the serial window. The research " +
            'products are ON DISK, one report file per facet (ROSTER below; consume only lanes with ok=true). CONSUMPTION: (a) ' +
            'UNRESEARCHED facets below got no research coverage — they admit nothing this run; never back-fill them from memory; ' +
            '(b) read every ok report IN FULL from disk before deciding anything — candidates overlap across facets, cluster by ' +
            'package as you read; (c) consolidate ADVERSARIALLY: an on-disk ok=true candidate is a claim to re-derive, never a fact — ' +
            're-check each against the central manifest truth (a dup with an admitted row, a phantom version, or domain drift kills ' +
            'the claim), re-open the repo `anchors`/`files` a candidate cites, resolve every remaining overlap across facets to the ' +
            'single best, and drop anything outside the folder domain. THEN execute each surviving ' +
            'admission NOW: (a) the central pin in ' +
            L.manifest +
            ' at the newest stable version, hand-edited in the matching ' +
            'label group; (b) ' +
            L.registry +
            ', bidirectionally — a replacement named in `fills` ripple-removes the superseded ' +
            "package's pin, registry row, README mention, and catalog; (c) the restore/lock gate: " +
            L.gate +
            ' — self-heal a red ' +
            'gate in place (wrong group, missing transitive floor pin, nonexistent version, stale reference); a package that ' +
            'genuinely cannot resolve is REVERTED entirely and reported under `skipped` with the reason. For each admitted package ' +
            'report `catalog` = the canonical .api path at its OWNING tier (folder-domain package -> ' +
            t +
            '/.api/; cross-folder ' +
            'substrate -> ' +
            L.root +
            '/.api/), matching the sibling naming convention. `green` is true only when the final gate is ' +
            'clean after your repairs. Admit only candidates present in the on-disk reports; never fabricate a package, version, or ' +
            'member beyond them. UNRESEARCHED: ' +
            JSON.stringify(unresearched) +
            ' ROSTER: ' +
            JSON.stringify(research),
    ].join('\n\n');
    const admitOpts = { label: 'admit:' + tag, phase: 'Admit', model: 'fable', effort: 'high', schema: ADMIT_SCHEMA };
    // A dead admit drops the lane's whole admission and severs its catalog/map/integrate: the re-dispatch acquires the serial window
    // AFRESH each attempt, so the retry never holds the central-manifest lock — sibling targets admit while a limit-dead lane waits.
    const admitOnce = (label) => admitSerial(() => slot(() => agent(admitPrompt, { ...admitOpts, label })));
    const admit = (await admitOnce('admit:' + tag)) || (await retryLane(() => admitOnce('admit:' + tag + ':a1')));
    const admitted = ((admit && admit.admitted) || []).filter((a) => a && a.package);
    log(tag + ' admit: ' + admitted.length + ' admitted, ' + ((admit && admit.skipped) || []).length + ' skipped, green=' + !!(admit && admit.green));
    if (!admitted.length) return { target: t, admitted: 0, green: !!(admit && admit.green), note: (admit && admit.summary) || 'nothing admitted' };

    // --- [CATALOG]
    // Folder-tier batches fan freely; shared-tier catalogs route through this language's ONE serialized writer.
    const catalogPrompt = (batch) =>
        [
            CTX(t, L),
            MEMBER_TRUTH(L),
            CATALOG_LAW(L),
            WRITE_LAW,
            LAWS_READ,
            'TASK: AUTHOR the full-depth .api catalog for each of these admitted packages, at the exact `catalog` path each carries: ' +
                JSON.stringify(batch) +
                '. Read the sibling catalogs at the owning tier first for the house convention, then write each ' +
                'catalog complete: the full advanced surface at operator depth, every member verified per MEMBER TRUTH (a member no tier ' +
                'verifies is dropped and listed in `phantomsDropped`), the [STACKING] section wiring the package into the substrate rails ' +
                'and its sibling domain packages. Sibling writers land catalogs concurrently — compose theirs as found on disk.',
        ].join('\n\n');
    const catalogOpts = (lbl) => ({ label: lbl, phase: 'Catalog', model: 'fable', effort: 'high', schema: CATALOG_SCHEMA });
    const sharedTier = admitted.filter((a) => String(a.catalog || '').indexOf(L.root + '/.api/') === 0);
    const folderTier = admitted.filter((a) => String(a.catalog || '').indexOf(L.root + '/.api/') !== 0);
    const catalogTasks = chunk(folderTier, CATALOG_BATCH).map((batch, i) =>
        slot(() => agent(catalogPrompt(batch), catalogOpts('catalog:' + tag + ':b' + i))),
    );
    if (sharedTier.length)
        catalogTasks.push(sharedSerial[L.key](() => slot(() => agent(catalogPrompt(sharedTier), catalogOpts('catalog:' + tag + ':shared')))));
    const catalogs = (await Promise.all(catalogTasks)).filter(Boolean);
    const catalogFiles = catalogs.flatMap((c) => c.files || []);
    log(tag + ' catalog: ' + catalogFiles.length + ' catalog file(s) authored');

    // --- [MAP]
    const slices = pages.length ? chunk(pages, MAP_SLICE) : [[]];
    const maps = (
        await Promise.all(
            slices.map((s, i) =>
                slot(() =>
                    recon(
                        [
                            CTX(t, L),
                            MEMBER_TRUTH(L),
                            INFO_LAW,
                            'TASK: INTEGRATION MAP, slice ' +
                                i +
                                ' (read-only). The run just admitted: ' +
                                JSON.stringify(admitted) +
                                '. Read the NEW ' +
                                'catalogs FIRST (' +
                                JSON.stringify(catalogFiles) +
                                '), then each of these design pages IN FULL from CURRENT disk: ' +
                                JSON.stringify(s) +
                                ', then every other catalog (folder tier and ' +
                                L.root +
                                '/.api/) the pages cite. Return entries: ' +
                                'where each new capability lands (`stacking` — the page whose concept admits it, verified member spellings, the ' +
                                'integration shape as fact), what each page currently hand-rolls that an admitted package now owns (`state`/`gap` with ' +
                                'exact anchors), where a new page or sub-folder is warranted because no existing page owns the concept (`gap`), and every ' +
                                'registry/index surface the integration will touch (`registry`/`ripple`).',
                        ].join('\n\n'),
                        { label: 'map:' + tag + ':s' + i, phase: 'Map', schema: MAP_SCHEMA, calls: 80, head: HEAD.map, scope: s },
                    ),
                ),
            ),
        )
    ).filter(Boolean);
    const mapped = maps.filter((r) => r.ok);
    const mapTotal = mapped.reduce((n, r) => n + r.entries, 0);
    const unmapped = maps.filter((r) => !r.ok).flatMap((r) => r.scope.map((sc) => ({ lane: r.lane, scope: sc })));
    log(
        tag +
            ' map: ' +
            mapTotal +
            ' entr(ies) across ' +
            mapped.length +
            '/' +
            maps.length +
            ' mapper(s)' +
            (unmapped.length
                ? ' — FAILED: ' +
                  maps
                      .filter((r) => !r.ok)
                      .map((r) => r.lane)
                      .join(', ')
                : ''),
    );

    // --- [INTEGRATE]
    const integratePrompt = [
        CTX(t, L),
        OWN_PASS(ownPassArt(t, 'integrate')),
        MEMBER_TRUTH(L),
        WRITE_LAW,
        LAWS_READ,
        HARVEST_LAW,
        "TASK: INTEGRATION EXECUTOR (WRITER — you are the run's LAST agent for this target; nothing follows you; full write " +
            'authority over the folder, its index docs, and any file a ripple exposes). Read the ' +
            L.stack +
            '/ doctrine at source ' +
            '(README and every page it routes) — it is the bar. The map REPORT FILES are your reconnaissance — information, not ' +
            'instructions. CONSUMPTION (your own-pass integration plan from OWN PASS FIRST precedes every map report): (a) ' +
            "UNMAPPED pages below get your own cold read FIRST — a failed mapper's territory is yours directly; (b) read every ok " +
            'map report IN FULL from disk; entries overlap across slices — dedupe by target as ' +
            "you read; (c) each entry's anchors are jump coordinates — re-open every anchor behind an edit (mandatory); " +
            'navigation-only entries re-verify only when touched; spot-verify what you build on and hunt past the maps on your own ' +
            'authority. IMPLEMENT the whole integration NOW: replace ' +
            'hand-rolled capability with the admitted packages at every mapped site, grow existing owners in place (a case, row, ' +
            'field, or operation — reshaped as if always carried, never a tacked-on mention), author a new page or sub-folder ' +
            'ground-up where the mapped capability demands an owner no page carries, weave beyond-map underutilized capability the ' +
            'catalogs expose, and close the folder README/ARCHITECTURE index docs so the landed state is truthfully reflected. ' +
            'CAPABILITY-COMPLETENESS IS MANDATORY: for every owner you author or grow, the fence body implements what its names ' +
            'and prose promise — a named-but-omitted capability is a defect you close NOW, at the same bar as a mapped hand-roll. ' +
            'Every ripple in the same pass, both seam ends. ADMITTED: ' +
            JSON.stringify(admitted) +
            '. HAND-ROLLS (the scout census ' +
            'of page-local reimplementation the admission now owns — every census site replaced at its evidence anchor, none left ' +
            'half-migrated): ' +
            JSON.stringify(handRolls) +
            '. UNMAPPED: ' +
            JSON.stringify(unmapped) +
            ' MAP ROSTER: ' +
            JSON.stringify(maps),
    ].join('\n\n');
    const integrateOpts = { label: 'integrate:' + tag, phase: 'Integrate', model: 'fable', effort: 'high', schema: FIXLOG };
    // A dead executor leaves the lane admitted-but-unintegrated (landed catalogs, no design integration): re-dispatch through the
    // bounded re-dispatch so a usage-limit death can recover without losing the whole integration.
    const integrateOnce = (label) => slot(() => agent(integratePrompt, { ...integrateOpts, label }));
    const fix = (await integrateOnce('integrate:' + tag)) || (await retryLane(() => integrateOnce('integrate:' + tag + ':a1')));
    return {
        target: t,
        admitted: admitted.length,
        skipped: (admit && admit.skipped) || [],
        green: !!(admit && admit.green),
        catalogs: catalogFiles,
        mapEntries: mapTotal,
        failedLanes: research
            .concat(maps)
            .filter((r) => !r.ok)
            .map((r) => r.lane),
        built: (fix && fix.built && fix.built.length) || 0,
        beyond: (fix && fix.beyond && fix.beyond.length) || 0,
        harvest: ((admit && admit.harvest) || []).concat((fix && fix.harvest) || []),
        summary: (fix && fix.summary) || (fix ? '' : 'integrate agent died twice'),
    };
};

const lanes = (
    await Promise.all(
        TARGETS.map((t) =>
            lane(t).then(
                (r) => r,
                () => ({ target: t, admitted: 0, note: 'lane crashed — inspect the run journal' }),
            ),
        ),
    )
).filter(Boolean);

// DOCTRINE LANDER: the run's durable-learning terminal — pooled harvest nominations adjudicated against the live
// doctrine surfaces; refutation-first, land-nothing legal, admission law owned by docs/laws. Fires only on non-empty rows.
const HARVEST_ROWS = lanes.flatMap((l) => (l && l.harvest) || []);
const doctrine = HARVEST_ROWS.length
    ? await slot(() =>
          agent(
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
          ),
      )
    : null;

return {
    targets: TARGETS,
    lanes,
    doctrine: doctrine && {
        nominated: HARVEST_ROWS.length,
        landed: (doctrine.landed || []).length,
        refined: (doctrine.refined || []).length,
        rejected: (doctrine.rejected || []).length,
        files: doctrine.files || [],
        summary: doctrine.summary,
    },
};
