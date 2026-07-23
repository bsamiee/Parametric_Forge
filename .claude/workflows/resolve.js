export const meta = {
    name: 'resolve',
    whenToUse:
        'The standing RESEARCH-row resolution pass for any libs/ planning corpus: pass folder targets (sub-folder / package root, any number, any language mix); it censuses every research row as an epistemic-debt entry, clusters the debts by verification route, verifies each at its route, then bakes confirmed spellings and DELETES resolved rows, sharpens the unresolvable, and closes with a critique/red-team chain, a deferred drain, and one doctrine landing.',
    description:
        'RESEARCH-row resolution engine over libs/{csharp,python,typescript} planning corpora. args = a folder target, an array of folder paths, or a targets object; empty = no-op. A research row is a writer epistemic debt — an exact question with its verification route, recorded instead of a guessed member spelling. Census (codex read lane) reads every page under the targets and extracts each research row (the C# [NN]-[RESEARCH] section entries, the inline RESEARCH re-verify rows, and the version-blocked capability rows) as an anchored {page, anchor, question, route, routeFamily, routeKey, symbols} entry with coverage; one lane per folder, large folders split by page count. Cluster (plain orchestrator code, no agent) groups the entries by verification route family — same host DLL, package, .api catalog, or doc source. Verify runs one lane per cluster, the route deciding the lane: assay-decompile clusters run NATIVE (they need tools.assay over host DLLs); .api catalog and doc-file clusters ride codex lanes reading the catalogs; external-doc clusters run a native Context7 lane; each writes {question, page, anchor, verdict, evidence, spelling} verdicts to disk. Apply (one resolver writer per folder, pipelined) reads the folder verdicts and the pages, bakes each confirmed spelling into its fence, corrects each refuted assumption at its root, DELETES each resolved research row entirely (no tombstones, no resolved notes), and SHARPENS each unresolvable row in place with a better question and route; docgen loads before durable prose edits, the prose gate returns zero FAILs, and the fixlog carries harvest. A codex critique (fix lane) then a red-team fold-forward per the chain law attack a baked spelling not actually verified, a deleted row whose fact never landed in the fence, and a surviving row that verification already answered. Close: a drain loop over the pooled deferred backlog and orphaned critique fixlogs, then one doctrine lander over the pooled harvest.',
    phases: [
        {
            title: 'Discover',
            detail: 'one thin agent expands the folder targets into the owning packages and their full design-page set (read-only)',
            model: 'sonnet',
        },
        {
            title: 'Census',
            detail: 'one codex lane per folder (large folders split by page count) reads every page and extracts each research row as an anchored epistemic-debt entry with its route family; entries return on the wire for clustering, the full product to disk',
        },
        {
            title: 'Verify',
            detail: 'plain orchestrator code clusters the entries by verification route family, then one lane per cluster verifies at its route — assay-decompile and external-doc NATIVE, catalog and doc-file codex — writing verdicts to disk',
        },
        {
            title: 'Apply',
            detail: 'per folder pipelined: the resolver lane bakes confirmed spellings, corrects refuted assumptions, DELETES resolved rows, sharpens the unresolvable; then a codex critique and a red-team fold-forward per the chain law',
        },
        {
            title: 'Close',
            detail: 'a drain loop over the pooled deferred backlog and orphaned critique fixlogs, then one doctrine lander over the pooled harvest',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const CAP = 14;
const DRAIN_ROUNDS = 4; // terminal drain fixpoint cap; the progress gate (no shrinkage -> stop) is the real bound
const CENSUS_PAGES = 10; // pages per census lane; a folder past it splits so each lane returns a bounded entry set on the wire
const ROOT = '/Users/bardiasamiee/Documents/99.Github/Rasm'; // absolute working root; every disk path a prompt names resolves here
const RETRY_ATTEMPTS = 2;

// --- [INPUTS] --------------------------------------------------------------------------

const normTarget = (t) => String(t).trim().replace(/\/+$/, '').replace(/^\/+/, '');
// Hosts may deliver object args JSON-encoded; decode before shape dispatch.
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
const langOf = (t) =>
    t.indexOf('libs/csharp') === 0 ? 'cs' : t.indexOf('libs/python') === 0 ? 'py' : t.indexOf('libs/typescript') === 0 ? 'ts' : null;
const TARGETS = [...new Set(rawTargets.filter(Boolean).map(normTarget))].filter((t) => langOf(t));
const REJECTED = [...new Set(rawTargets.filter(Boolean).map(normTarget))].filter((t) => !langOf(t));
// Per-instance scratch dir (census products, verdict reports, apply fixlogs, per-folder seam ledgers): one FLAT dir under
// .claude/scratch/, minted deterministically from the normalized targets (clock/randomness would break resume) so a resume rehydrates it.
const fnv1a = (s) => {
    let h = 0x811c9dc5;
    for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193);
    return (h >>> 0).toString(16).padStart(8, '0').slice(0, 6);
};
const SCRATCH =
    '.claude/scratch/' +
    ('resolve-' + TARGETS.map((t) => t.split('/').pop().toLowerCase()).join('-')).replace(/[^a-z0-9.-]+/g, '-').slice(0, 60) +
    '-' +
    fnv1a(JSON.stringify(TARGETS));

// --- [MODELS] --------------------------------------------------------------------------

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

const DISCOVER_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['packages', 'pages', 'unresolved'],
    properties: {
        packages: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['name', 'root', 'planning', 'api'],
                properties: {
                    name: { type: 'string' },
                    root: { type: 'string' },
                    planning: { type: 'string' },
                    api: { type: 'string' },
                },
            },
        },
        pages: { type: 'array', items: { type: 'string' } },
        unresolved: { type: 'array', items: { type: 'string' } },
    },
};

// One census entry = one research row as epistemic debt: the exact question, its verification route, and the route
// family/key the orchestrator clusters on. routeFamily picks the verify lane; routeKey is the cluster grouping key.
const CENSUS_ENTRY = {
    type: 'object',
    additionalProperties: false,
    required: ['page', 'anchor', 'question', 'route', 'routeFamily', 'routeKey', 'symbols'],
    properties: {
        page: { type: 'string' },
        anchor: { type: 'string' }, // the bracketed marker label or the `[NN]-[RESEARCH]` section id with a short locator
        question: { type: 'string' }, // the exact unresolved debt: which member/spelling/capability is unverified or must re-verify
        route: { type: 'string' }, // the verification route as the row states it, verbatim enough to re-derive
        routeFamily: { type: 'string', enum: ['assay', 'catalog', 'docfile', 'extdoc', 'build'] },
        routeKey: { type: 'string' }, // <family>:<assembly|catalog|doc|lib|pkg> — the cluster grouping key
        symbols: { type: 'array', items: { type: 'string' } }, // the member spellings the row names
    },
};

const CENSUS_WIRE = {
    type: 'object',
    additionalProperties: false,
    required: ['entries', 'coverage', 'summary'],
    properties: { entries: { type: 'array', items: CENSUS_ENTRY }, coverage: COVERAGE, summary: { type: 'string' } },
};

const VERDICT_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['verdicts', 'coverage', 'summary'],
    properties: {
        verdicts: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['question', 'page', 'anchor', 'verdict', 'evidence', 'spelling'],
                properties: {
                    question: { type: 'string' },
                    page: { type: 'string' },
                    anchor: { type: 'string' },
                    verdict: { type: 'string', enum: ['confirmed', 'refuted', 'unresolvable'] },
                    evidence: { type: 'string' }, // the route output that decided it — the verbatim member block, command result, or doc fact
                    spelling: { type: 'string' }, // the confirmed member spelling to bake (empty for refuted/unresolvable)
                },
            },
        },
        coverage: COVERAGE,
        summary: { type: 'string' },
    },
};

// Thin wire receipt: a verify lane PRODUCT stays on disk at `report`; only status + count + headline travel inline.
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

const SEAMS = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['file', 'counterpart', 'bothEnds'],
        properties: { file: { type: 'string' }, counterpart: { type: 'string' }, bothEnds: { type: 'boolean' } },
    },
};

const DELTAS = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['symbol', 'change'],
        properties: { symbol: { type: 'string' }, change: { type: 'string' } },
    },
}; // navigation facts: what moved, as data, zero adjectives

const DEFERRED = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['files', 'claim'],
        properties: { files: { type: 'array', items: { type: 'string' } }, claim: { type: 'string' } },
    },
}; // the counted backlog: second-order + live-folder-scope ripples

const BEYOND = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['catalog', 'member'],
        properties: { catalog: { type: 'string' }, member: { type: 'string' } },
    },
};

const INDEXROWS = {
    type: 'array',
    items: {
        type: 'object',
        additionalProperties: false,
        required: ['doc', 'row'],
        properties: { doc: { type: 'string' }, row: { type: 'string' } },
    },
}; // doc = index doc, central manifest, or IDEAS.md; row = the exact row text

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

// Required-but-empty arrays are attestations: forced seamsTouched/beyondMap/indexRows/deltas/deferred make
// "read fully / repair both ends / record the backlog" structurally checkable, never wishful prose.
// ONE fix-log core serves every writing stage; a stage adds only the keys its charter earns — twin literals drift, one owner never does.
const LOG_CORE = {
    files: { type: 'array', items: { type: 'string' } },
    summary: { type: 'string' },
    seamsTouched: SEAMS,
    deltas: DELTAS,
    deferred: DEFERRED,
    beyondMap: BEYOND,
    indexRows: INDEXROWS,
    harvest: HARVEST,
};
const logSchema = (extra) => ({
    type: 'object',
    additionalProperties: false,
    required: Object.keys(LOG_CORE).concat(Object.keys(extra)),
    properties: Object.assign({}, LOG_CORE, extra),
});
// baked/deleted/sharpened are apply-stage-only attestations; the verdict enum forks per stage.
const FIXLOG_SCHEMA = logSchema({
    verdict: { type: 'string', enum: ['resolved', 'partial', 'clean'] },
    baked: { type: 'integer' }, // confirmed spellings baked into fences
    deleted: { type: 'integer' }, // resolved research rows removed entirely
    sharpened: { type: 'integer' }, // unresolvable rows rewritten in place
});
const REVIEW_SCHEMA = logSchema({ verdict: { type: 'string', enum: ['fixed', 'clean'] } });

// Required-but-possibly-empty `beyond` is an attestation: the fixer's own hunt ran, not only the drained list.
const FIXER_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'indexApplied', 'backlogDrained', 'beyond', 'rejected', 'remaining', 'harvest', 'tranches', 'summary'],
    properties: {
        files: { type: 'array', items: { type: 'string' } },
        harvest: HARVEST,
        tranches: { type: 'array', items: { type: 'string' } }, // one checkpoint receipt line per tranche fed this round — a fed tranche absent here is unconsumed
        indexApplied: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['doc', 'action'],
                properties: { doc: { type: 'string' }, action: { type: 'string' } },
            },
        },
        backlogDrained: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['claim', 'action'],
                properties: { claim: { type: 'string' }, action: { type: 'string' } },
            },
        },
        beyond: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['target', 'action'],
                properties: { target: { type: 'string' }, action: { type: 'string' } },
            },
        },
        rejected: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['finding', 'reason'],
                properties: { finding: { type: 'string' }, reason: { type: 'string' } },
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

// LANG carries routing data and engine-parameter rows ONLY — doctrine content is reached through readFirst at the source, never paraphrased here.
const LANG = {
    cs: {
        key: 'cs',
        name: 'C#',
        root: 'libs/csharp',
        stack: 'docs/stacks/csharp',
        casing: 'PascalCase',
        corpus: 'libs/csharp planning corpus (markdown specs of intended C# package designs)',
        strata:
            'CLAUDE.md manifest + WORKSPACE_LAW strata govern (KERNEL -> AEC-DOMAIN -> APP-PLATFORM -> HOST-BOUNDARY -> APP; ' +
            'depend strictly upward; a host-neutral owner only where a non-Rhino runtime consumes the contract).',
        stackFloor:
            'docs/stacks/csharp is the FLOOR, never the ceiling — every fence meets it and pushes past it to the strongest form the doctrine admits.',
        apiTiers:
            'the SHARED substrate catalogs `libs/csharp/.api/*.md` (Thinktecture generated owners, LanguageExt rails/effects/schedules/immutable ' +
            'collections, QuikGraph, Mapperly and siblings) AND the folder catalogs `<package>/.api/*.md`, always layering the universal ' +
            'Thinktecture/LanguageExt rails onto the domain packages, never the folder set alone.',
        verify:
            '`UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api` (assay blocked or unavailable: the `.api` catalogs, the nuget MCP for ' +
            'feed truth, and Context7/exa/tavily for the official surface own the fallback)',
        vocab: '(`[Union]`/`[SmartEnum<TKey>]`/`[ValueObject]`/`Fold`/the rails)',
        slur: 'naive, surface-level code dressed in the right vocabulary',
        illusion: 'a `.api`/host member cited but never verified',
        docBloat: 'XML-doc',
        deepPkgs: 'LanguageExt/Thinktecture/MathNet/CSparse',
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
        strata: 'CLAUDE.md manifest law governs.',
        stackFloor:
            'docs/stacks/python is the bar and docs/stacks/csharp is the density/ambition FLOOR — match its richness, never import C#-shaped idioms.',
        apiTiers:
            'the SHARED/universal branch catalogs `libs/python/.api/*.md` (anyio, expression, msgspec, pydantic, pydantic-settings, beartype, ' +
            'structlog, stamina, numpy, psutil, opentelemetry-*) AND the folder catalogs `<package>/.api/*.md`, always layering the shared/universal ' +
            'rails ON TOP OF the folder-specific domain packages, never the folder set alone.',
        verify:
            '`UV_CACHE_DIR=.cache/uv uv run --frozen python -m tools.assay api resolve <pkg>` (a gated/uninstalled package, or a ' +
            'blocked/unavailable assay, falls back to its catalog/official surface)',
        vocab: '(`@tagged_union`/`frozendict`/`Result`/`Option`/the rails)',
        slur: 'naive, surface-level, old-style Python dressed in the right vocabulary',
        illusion: 'a `.api` member cited but never verified',
        docBloat: 'docstring',
        deepPkgs: 'the admitted both-tier catalogs (expression/msgspec/pydantic/anyio + the folder domain packages)',
        modern: 'py3.15-modern only',
        mechanics: '',
        fileOrg: 'apply the `docs/stacks/python` file-organization + section-order law',
    },
    ts: {
        key: 'ts',
        name: 'TypeScript',
        root: 'libs/typescript',
        stack: 'docs/stacks/typescript',
        casing: 'camelCase',
        corpus: 'libs/typescript planning corpus (markdown specs of intended TypeScript module designs)',
        strata: 'CLAUDE.md manifest law governs.',
        stackFloor: 'docs/stacks/typescript composed in full is the bar — author ultra-advanced TS only, discarding naive idioms wholesale.',
        apiTiers:
            'the SHARED/universal `libs/typescript/.api/*.md` Effect substrate rails AND the folder catalogs `<folder>/.api/*.md`, cross-checked ' +
            'against the published types in node_modules, always layering the shared Effect ecosystem end-to-end ON TOP OF the area-specific packages, ' +
            'never the folder set alone.',
        verify:
            'the published types in node_modules (`UV_CACHE_DIR=.cache/uv uv run python -m tools.assay api` over node_modules declarations where ' +
            'a member is novel)',
        vocab: '(`Schema.Class`/`TaggedClass` families, tagged unions, `Effect`/`Layer`, value-derived vocabulary tables)',
        slur: 'naive JavaScript-in-TypeScript dressed in the right vocabulary',
        illusion: '`any`/unsafe `as`/non-null `!` smuggled under a confident surface; a member cited but unverifiable against node_modules',
        docBloat: 'TSDoc',
        deepPkgs:
            'the Effect ecosystem (`Effect`/`Layer`/`Context`/`Schema`/`Stream` + platform/experimental/cluster/workflow/sql/rpc/ai) + the area packages',
        modern: 'ultra-advanced modern TS only',
        mechanics: '',
        fileOrg: 'apply the `docs/stacks/typescript` file-organization + section-order law',
    },
};

// --- [OPERATIONS] ----------------------------------------------------------------------

// Agent-level slot scheduler: CAP agents in flight across ALL chains, work-conserving
// backfill the moment a slot frees. The single governor for every agent call.
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
// Bounded re-dispatch for a dead CRITICAL lane (usage-limit or transport death): attempt-counted with a retry before each; the
// final death isolates the lane but NEVER the chain — every downstream stage still runs against current disk.
const retryLane = async (fn) => {
    for (let a = 0; a < RETRY_ATTEMPTS; a++) {
        const r = await fn();
        if (r) return r;
    }
    return null;
};

// Codex dispatch: the wrapper runs one supervised codex-lane.sh lane in the background, reads the receipt, verifies the product, and
// returns mechanical orchestration data. Lane law rides --law (developer-instructions); the --task file carries only the task; the output contract sits LAST.
const fileTag = (label) => label.replace(/[^A-Za-z0-9_.-]+/g, '-');
const laneLaw = (schema, o) =>
    (o.fix
        ? '<completion_bar>\nDone is every page in your named scope worked to its full depth with its fixlog entry written — ' +
          'proof-complete, never effort-spent, never early. Complete every named move before yielding; do not stop at analysis ' +
          'or a partial edit. If the chosen approach resists, pick the next-best one and proceed; a move the territory genuinely ' +
          'admits no edit for returns as a deferred row naming its blocker. Your layer is review-and-repair of the named scope: a ' +
          'finding outside it lands as a typed deferred/index row, never an edit — and re-verifying unchanged work or re-reading ' +
          'covered territory adds no evidence; move to the next deliverable instead.\n</completion_bar>\n\n<verification>\nAfter ' +
          'editing, re-read each changed file and confirm it is coherent and nothing it carried was lost. Fix what fails before ' +
          'yielding; a check you did not run is never claimed as run.\n</verification>'
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
const LANE_SCRIPT = ROOT + '/.claude/skills/codex/scripts/codex-lane.sh';
const flagsOf = (o) =>
    [o.model && '--model ' + o.model, o.codexEffort && '--effort ' + o.codexEffort, o.web && '--web']
        .filter(Boolean)
        .map((f) => ' ' + f)
        .join('');

const codexPrompt = (label, task, schema, o) => {
    const base = SCRATCH + '/' + fileTag(label);
    const report = ROOT + '/' + base + '-report.json';
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
        ROOT +
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
// Every codex-dispatched receipt lane routes here: the model `o.model` names, the config default unflagged otherwise.
// QUOTA FALLBACK: a codex receipt whose failure matches usage/quota/limit re-dispatches the SAME task natively at the
// role twin. The roster row carries `scope` from the ORCHESTRATOR so a failed lane
// unmapped territory is exact even when the lane died before writing anything.
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
        {
            label: o.label,
            phase: o.phase,
            model: o.nativeModel || twinOf(o.model),
            effort: 'high',
            schema: RECEIPT,
        },
    );
const recon = (task, o) =>
    agent(codexPrompt(o.label, task, o.schema, o), {
        label: (o.model ? 'terra:' : 'sol:') + o.label,
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
// Native receipt lane (assay/extdoc verify): normalized into the recon roster shape so a NATIVE cluster and a codex cluster read identically downstream.
const asLane = (label, scope, p) =>
    p.then((r) => ({
        lane: label,
        scope: scope || [],
        ok: !!(r && r.ok && r.report),
        report: (r && r.report) || '',
        entries: (r && r.entries) || 0,
        headline: (r && r.headline) || '',
        failure: (r && r.failure) || (r ? '' : 'lane died'),
    }));

// Census dispatch: the wrapper makes one Codex call, writes the product to disk, AND relays the
// entries themselves on the wire — the orchestrator clusters on them, so a receipt count alone would not do. Bounded
// per lane by CENSUS_PAGES so the relayed entry set stays small.
const censusCodexPrompt = (label, task, o) => {
    const base = SCRATCH + '/' + fileTag(label);
    const report = ROOT + '/' + base + '-report.json';
    const lane = report + '.lane';
    const model = o.model || 'gpt-5.6-terra';
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
        ROOT +
        ' --sandbox read-only --model ' +
        model +
        ' --out ' +
        report +
        '; the harness re-invokes you when the lane exits — Read ' +
        lane +
        '/receipt.json then, never a polling loop. Recovery is two-branch and ONCE-only — the whole budget: a receipt reason "crash" ' +
        'alone (the session persisted on disk) overwrites the task file with "continue and complete the lane, then land the receipt" and ' +
        're-runs the same command plus --resume <the receipt thread_id>; any other failed receipt (max-timeout, turn-failed, ' +
        'refusal) re-runs the same command untouched. (3) The lane lands the census product at ' +
        report +
        ' via --out. Verify with one Bash call: jq -e . ' +
        report +
        ' >/dev/null — a nonzero exit means a missing or malformed product; on a miss re-derive the product once from the lane ' +
        'events.jsonl (jq -rs to the last agent_message item text, Write that), re-probe, and a second miss returns the empty product. ' +
        '(4) Read the census product at ' +
        report +
        ' and return it VERBATIM as YOUR final message — the object with keys entries, coverage, summary matching the output schema. On a ' +
        'failed receipt return entries [], an empty coverage (all four arrays []), and summary equal to the receipt reason and failure text ' +
        'VERBATIM.\n\nLANE LAW:\n\n' +
        laneLaw(CENSUS_WIRE, o) +
        '\n\nTASK:\n\n' +
        task
    );
};
const census = (task, o) =>
    agent(censusCodexPrompt('terra:' + o.label, task, o), {
        label: 'terra:' + o.label,
        phase: 'Census',
        model: 'sonnet',
        effort: 'low',
        schema: CENSUS_WIRE,
    })
        .then((r) =>
            r && (!r.entries || !r.entries.length) && /usage|quota|limit/i.test((r && r.summary) || '')
                ? agent(
                      task +
                          '\n\nPRODUCT TO DISK: also write your COMPLETE product to ' +
                          SCRATCH +
                          '/' +
                          fileTag(o.label) +
                          '-report.json (Write tool, absolute path under the repo root), then return the SAME object as your final message.',
                      { label: o.label, phase: 'Census', model: 'opus', effort: 'high', schema: CENSUS_WIRE },
                  )
                : r,
        )
        .then((r) => ({ lane: o.label, entries: (r && r.entries) || [], summary: (r && r.summary) || '' }));

const chunk = (arr, n) => {
    const o = [];
    for (let i = 0; i < arr.length; i += n) o.push(arr.slice(i, i + n));
    return o;
};
// Even split: ceil(n/max) slices of near-equal size — no runt tail heavying slice 0 and starving the last.
const evenChunk = (arr, max) => chunk(arr, Math.ceil(arr.length / (Math.ceil(arr.length / max) || 1)));
const pkgOf = (p) => p.split('/.planning/')[0]; // package = the folder write-partition key (index docs live at its root)
const Lof = (pkg) => LANG[langOf(pkg)] || LANG.cs;
const scratchBase = (folder, i) => SCRATCH + '/' + fileTag(folder.split('/').pop() + ':f' + i);
// Assay/external-doc clusters run NATIVE; catalog/doc-file clusters ride codex lanes reading the repo.
const NATIVE_FAMILY = { assay: true, build: true, extdoc: true, catalog: false, docfile: false };

// Navigation handoff: FACTS ONLY — files, symbol deltas, seam rows, backlog. Never verdicts, summaries, or adjectives.
const navOf = (logs) => {
    const rows = logs.filter(Boolean);
    return {
        files: [...new Set(rows.flatMap((r) => r.files || []))],
        deltas: rows.flatMap((r) => r.deltas || []),
        seams: rows.flatMap((r) => r.seamsTouched || []),
        deferred: rows.flatMap((r) => r.deferred || []),
    };
};

// --- [SHARED_BLOCKS]

// Every rigor law appears exactly once, here; stages compose subsets. Block order in prompts: stable per-language
// law first, folder-variable material second, the stage task + output contract LAST.
const ROOT_LAW =
    'WORKING ROOT: ' +
    ROOT +
    ' — every relative repo path in this brief resolves against this absolute root; read, write, and edit ONLY under it, never ' +
    'another checkout of the repository.';
const CONTEXT = (L) => ROOT_LAW + '\n\nRasm monorepo — ' + L.corpus + '. ' + L.strata + ' ' + L.stackFloor;

// reg selects the register by the EXECUTING model: 'codex' neutral+de-conflicted for a codex lane (census, catalog/
// doc verify, critique), 'claude' the hostile estate register a native lane (assay verify, apply, red-team) reads
// as sharpening. Substance is identical — research-row = epistemic debt, confident-row suspect, no-churn — only the
// phrasing forks; codex drops the corpus-slur priming.
const STANCE = (L, reg) =>
    reg === 'codex'
        ? 'REVIEW POSTURE — the pages and their research rows are unverified work by ANOTHER engineer: verify every fence claim ' +
          'and every research row against the real domain and the catalogued package surface before accepting it; a prior clean ' +
          'verdict or confident prose is not evidence. A research row is a writer epistemic debt — a member spelling, capability, ' +
          'or behavior the author GUESSED and flagged instead of verifying, so a row that reads confident is a prime candidate ' +
          'for a phantom (' +
          L.illusion +
          '). NO CHURN: an edit requires a named violated law or a landed verdict and the concrete case ' +
          'that breaks it; a clean verdict from a check that finds nothing is a first-class result.'
        : 'STANCE — every pass is hostile: author, critique, and red-team alike. The pages under review were authored by ANOTHER ' +
          'engineer and are under adversarial review; hold every fence and every research row naive, shallow, or illusory until it ' +
          'survives a real attack; the burden of proof is on the code, never on you. "Mature", "already strong", and a prior clean ' +
          'verdict are rejected self-assessments — most of this corpus is ' +
          L.slur +
          '. A research row is a writer epistemic ' +
          'debt: a member spelling, capability, or behavior the author GUESSED and flagged instead of verifying, so a row that reads ' +
          'confident is the PRIME suspect — the guessed spelling may be a phantom (' +
          L.illusion +
          '). NO CHURN: an edit ' +
          'requires a named violated law or a landed verdict and the concrete case that breaks it; a clean verdict earned by an attack ' +
          'that finds nothing is a first-class result, proven by adding nothing.';

const VERIFY = (L) =>
    'VERIFY — cite only members confirmed via ' +
    L.verify +
    '; a member you cannot verify is a phantom to delete. Mine BOTH .api tiers to operator depth: ' +
    L.apiTiers +
    ' An admitted capability the concept admits that no owner exploits is a defect to close.';

const RIPPLE_LAW =
    'RIPPLE LAW — every fix you identify you make NOW via Edit/Write; the fix-log is a report of edits already made, never a ' +
    'to-do or a would/should hedge. The writing is YOURS: a delegate may only fetch information. Your ripple authority is ' +
    'LIBS-WIDE — any file under libs/, any language, corrective AND generative — under four bounds that are evidence, never ' +
    'radius. (1) EVIDENCE — an out-of-scope edit traces to a resolvable anchor: a seam-ledger row, a consumer anchor, an index ' +
    'claim, or a wire row in the branch ARCHITECTURE.md [02]-[SEAMS] ledger; an unanchored edit is drift, forbidden. ' +
    '(2) EXPAND-FORM — a foreign edit made while sibling folders run is ADDITIVE only: add the case, row, field, operation, or ' +
    'counterpart; renaming, removing, or collapsing a foreign surface is recorded in `deferred` for the terminal fixer, never ' +
    'raced. Wire-canonical names stay frozen; a foreign-language counterpart is repaired at ITS branch doctrine bar with ' +
    'surgical anchored edits, never a foreign-interior rebuild. (3) DEPTH — a first-order ripple (your edit broke or opened it ' +
    'directly) is repaired both ends this pass and recorded in `seamsTouched`; a second-order ripple or a counterpart INSIDE a ' +
    'concurrent folder scope is recorded in `deferred` as {files, claim} — the fixer drains the backlog this run; nothing is ' +
    'silently dropped. (4) DECISION/PROPAGATION — the owning-package index docs (ARCHITECTURE.md + README.md at the path before ' +
    '`/.planning/`), IDEAS.md, and the central manifests take exact rows via `indexRows` for the terminal fixer to apply once; ' +
    'propagating an already-ruled contract is yours to distribute.';

const CURRENT_STATE =
    'CURRENT STATE — sibling folders land work concurrently with yours. Before any edit, re-read the CURRENT on-disk state of ' +
    'your pages AND every sibling page your pages compose or ripple into; landed sibling work is picked up as found. A seam ' +
    'counterpart a sibling folder landed is COMPOSED, not re-derived; a conflict between your design and a landed sibling ' +
    'resolves to the stronger form, never a revert.';

const LEDGER = (base, scopes) =>
    'SEAM LEDGER — cross-folder coordination is typed fact rows on disk, never prose. Your folder ledger is `' +
    base +
    '-seams.md`: append one row per cross-file event as you work — `SEAM_CHANGED | <files> | <symbol/wire fact, old -> new>` ' +
    'when a shared name, signature, or contract you own moves; `RIPPLE_REPAIRED | <files> | <fact>` when you repair a ' +
    'counterpart, so no sibling redoes it; `SEAM_CONFLICT | <files> | <both values>` when your decision collides with a landed ' +
    'sibling row (then resolve to the stronger form per CURRENT STATE). Before ANY edit outside your folder pages, `ls` `' +
    SCRATCH +
    '/` and read every sibling `*-seams.md` row whose files intersect yours — a RIPPLE_REPAIRED row is work you do NOT redo; a ' +
    'SEAM_CHANGED row is a contract you compose. Rows are facts with zero adjectives; your returned `seamsTouched` rows ARE ' +
    'these ledger rows verbatim, never a second derivation. CONCURRENT FOLDER SCOPES (a counterpart ' +
    'inside another live folder scope is recorded in `deferred`, never edited): ' +
    scopes;

const PROSE_COMMENTS = (L) =>
    'PROSE + COMMENTS — apply docs/standards/style-guide.md, information-structure.md, and formatting.md. The page is a design ' +
    'spec: lead each section with the controlling contract, one idea per paragraph, close on the consequence; no provenance, ' +
    'process narration, freshness disclaimers, or hedges. Backtick every symbol, type, field, function, operator, package ID, ' +
    'path, command, flag, and literal; name the exact member instead of paraphrasing behavior; trimming never reduces technical ' +
    'density. Code fences comment for the next agent only: keep the canonical section-divider headers; beyond them default to ' +
    'zero comments, 1-2 lines only for a truly subtle invariant, contract, or boundary; no restating the code, no narration, no ' +
    L.docBloat +
    ' bloat.';

// reg forks only the second-pass intensifier: 'claude' keeps the adversarial framing a native lane sharpens on, 'codex' drops it.
const SELF_CHECK = (reg) =>
    'MANDATORY SELF-VERIFY (second pass, before returning): ' +
    (reg === 'codex' ? 're-derive' : 'adversarially re-derive') +
    ' every entry from disk — re-open each cited ' +
    'anchor and confirm it states what the entry claims, re-verify each member spelling against its route, trace each seam to ' +
    'both endpoints. An entry that fails re-confirmation is corrected or deleted, never returned; a guess, an assumption, a ' +
    'skimmed summary, or a vague/hedged entry is a defect. Completeness is part of correctness: after the re-read, hunt once ' +
    'more for what the first pass missed — an omitted load-bearing fact is as wrong as a false one.';

const HARVEST_LAW =
    'HARVEST (required key, usually empty): nominate ONLY findings that generalize beyond this folder — a resolution pattern ' +
    'reusable across folders, a research-debt class no doctrine clause names, a review rule that would have caught a defect ' +
    'BEFORE review, a cross-surface coupling discovered the hard way. Each row: altitude (stacks|reviewer|constitution|planning|' +
    'readme|laws), lang, claim (the generalized law, one sentence), anchors (file:line evidence), existingClause (the exact ' +
    'doctrine or reviewer clause it would harden, quoted with its path — or "absent" with the surfaces searched). A folder-local ' +
    'fix never nominates; an empty array is the normal verdict — the doctrine lander refutes weak rows, so nominate substance, ' +
    'never volume.';

const OWN_PASS = (artifact, later) =>
    'OWN PASS FIRST — form your own defect list as a DISK ARTIFACT before ' +
    later +
    ' opens: cold-read each touched page from CURRENT disk, check it against the verdict reports, and WRITE your own defect ' +
    'list to `' +
    artifact +
    '` BEFORE reading ' +
    later +
    ' — false bakes, lost facts, stale survivors, tombstones, vague sharpens, and every doctrine miss the resolution left. ' +
    'Later inputs may only ADD rows tagged [recon]; reading the pages without writing the list is a failed rung. TRIPWIRE: a ' +
    'diff whose edits map one-to-one onto [recon] rows has failed — the recon covers a MINORITY of the resolution defects, ' +
    'and the majority of your edits come from your own attack.';

const GIT_GROUND =
    'DELTA GROUNDING — run `git diff --stat` then `git diff -- <your folder pages and their seam files>` to see exactly what ' +
    'this run changed before judging it; `git status` surfaces new files. The diff is orientation, CURRENT disk is truth — the ' +
    "repo carries pre-run uncommitted work, so an unfamiliar hunk is verified against disk, never assumed to be this run's.";

const readFirst = (L, pkg) =>
    [
        'READ FIRST, IN ORDER, BEFORE ANY EDIT — no fence is judged before this read lands.',
        '(1) DOCTRINE — enumerate `' +
            L.stack +
            '/` with a real `ls` (never memory), then read the README and EVERY root page it routes IN FULL in the README ' +
            '[01]-[ATLAS] order — top-to-bottom, never a partial, skim, grep-jump, or section-sample; a root page on disk but ' +
            'absent from the atlas is still mandatory law. The README [02]-[DOCTRINE] laws, the [03]-[COLLAPSE_SCAN] table, ' +
            'OWNER_CHOOSER (`shapes.md` [01]), RAIL_CHOOSER (`rails-and-effects.md` [01]), and the aspect two-weave are binding ' +
            'law AT THE SOURCE. This prompt does not restate the doctrine; read it there and conform every fence to it.',
        L.key === 'cs'
            ? '(1b) Enumerate `docs/stacks/csharp/domain/` with a real `ls` through its router README, then read every shard the ' +
              'page concerns touch — chosen from the enumerated set, truthfully, never from memory or skipped; shard conformance ' +
              'is a hard gate.'
            : '',
        '(1c) ANALYZER LAW — read the repo `.editorconfig` rules for your language: every rule at `error` severity is a COMPILE ' +
            'GATE the fences must satisfy; a doc claim that contradicts an error-level analyzer rule is a FICTION to correct, ' +
            'never law to compose.',
        '(1d) LAWS — read `docs/laws/` IN FULL (README + topology + patterns + scars; short registry pages): a topology row whose ' +
            '[SURFACE] your edits touch binds its obligated counterparts into the SAME pass, and every patterns row binds each ' +
            'branch it names.',
        '(2) .API — `ls` BOTH catalog tiers in full — the shared substrate `' +
            L.root +
            '/.api/` AND the folder `' +
            pkg +
            '/.api/` — then read every catalog relevant to these pages, layering the shared rails (' +
            L.deepPkgs +
            ') ON TOP OF the folder domain packages, never the folder set alone.',
        '(3) SCOPE — read the owning-package charter — ARCHITECTURE.md + README.md + IDEAS.md — as the INTENT authority for what ' +
            'each page owns and which pages are settled.',
    ]
        .filter(Boolean)
        .join('\n');

const discoverPrompt = () =>
    [
        'Rasm monorepo — the libs/{csharp,python,typescript} planning corpora (markdown design specs). Targets may mix ' +
            'languages; each page owning package is the path before `/.planning/`.',
        'TASK: thin enumerate (read-only, do NOT edit). TARGETS (repo-relative): ' +
            JSON.stringify(TARGETS) +
            '. EXPAND with a real recursive listing per target — run find <target-or-its-.planning-tree> -name *.md — a design ' +
            'page lives INSIDE the .planning tree, so a package-root ls alone NEVER proves an empty page set. Validate the ' +
            'expansion against `libs/.planning/planning-targets.md` (a mis-scoped or renamed target is reported in `unresolved`).',
        'Return `packages` (one entry per distinct owning package: {name, root, planning, api}) and `pages` — every design page ' +
            'under the targets: a ROOT expands to every page under its planning tree, a SUB-FOLDER to every page under it, a FILE ' +
            'to itself; union + dedup; exclude IDEAS.md/TASKLOG.md/README.md/ARCHITECTURE.md.',
    ].join('\n\n');

const censusPrompt = (L, pages) =>
    [
        CONTEXT(L),
        STANCE(L, 'codex'),
        SELF_CHECK('codex'),
        'TASK: READ-ONLY RESEARCH CENSUS over these ' +
            pages.length +
            ' pages (investigate, do NOT edit): ' +
            JSON.stringify(pages) +
            '. Read each page IN FULL and extract EVERY research row — a writer epistemic debt: an exact question with its ' +
            'verification route, recorded instead of a guessed member spelling. The convention on disk takes THREE forms, all in ' +
            'scope:\n' +
            '(A) SECTION ROWS — a numbered `## [NN]-[RESEARCH]` section (usually near the page bottom) whose bullet entries read ' +
            '`- [MARKER_LABEL]: <claim> grounds against <route> ... <verified members>`. Some entries are already-grounded ' +
            'provenance ("decompile-verified against `.api/api-geometrygym-ifc` and `assay api query GeometryGymIFC_Core`"), ' +
            'others carry an OPEN debt (a version-BLOCKED capability, a still-suspect assumption). Extract every entry; the ' +
            '`anchor` is its bracketed marker label.\n' +
            '(B) INLINE RE-VERIFY ROWS — a bullet anywhere in a page reading `- RESEARCH: <member/spelling> is census-sighted but ' +
            'catalog-unverified — <what lands when the decompile/catalogue confirms it>; <the settled fallback> until then`, or ' +
            'the `... re-verify at decompile` / `... re-verify at the same pass` phrasing. These are the purest debts: an exact ' +
            'unverified spelling, its route, and the interim fence. The `anchor` is the leading symbol or the `RESEARCH:` marker ' +
            'with a short locator.\n' +
            '(C) CROSS-REFERENCE MARKERS — `(RESEARCH)`, `see [NN]-[RESEARCH]`, `see RESEARCH`, or an inline note inside a fence ' +
            'comment POINTING at a row. A pointer is NOT itself a debt; record it only as an extra `symbols`/route note on the ' +
            'entry it points to, never as a standalone entry.\n' +
            'For EACH real research row return {page, anchor, question, route, routeFamily, routeKey, symbols}. `question` is the ' +
            'exact debt as fact (which member/spelling/capability is unverified or must re-verify — never the surrounding ' +
            'design). `route` quotes the verification route the row states, verbatim enough to re-run. `symbols` lists every ' +
            'member spelling the row names. Classify `routeFamily` and `routeKey` by the route:\n' +
            '- assay: grounds a member/spelling against a HOST-DLL decompile — "at decompile", "the decompile confirms", ' +
            '"census-sighted but catalog-unverified", `assay api query <Assembly>`, `tools.assay api resolve <pkg>`. routeKey = ' +
            '"assay:" + the assembly or package name (e.g. "assay:GeometryGymIFC_Core").\n' +
            '- catalog: grounds against a REPO `.api/api-*.md` catalog — "the branch/folder catalogue rows its spelling", an ' +
            '`.api/api-*` path. routeKey = "catalog:" + the catalog basename (e.g. "catalog:api-thinktecture-runtime-extensions").\n' +
            '- docfile: grounds against a REPO planning doc or seam anchor — `ELEMENT-REBUILD-PLAN.md §N`, a `Rasm.X/...#ANCHOR` ' +
            'or `csharp:...#ANCHOR` reference. routeKey = "docfile:" + the doc basename or seam file (e.g. ' +
            '"docfile:ELEMENT-REBUILD-PLAN.md").\n' +
            '- extdoc: grounds against an UPSTREAM/EXTERNAL reference not yet in a repo catalog — "the extension own reference", ' +
            'upstream package docs, node_modules types. routeKey = "extdoc:" + the library (e.g. "extdoc:vchord_bm25").\n' +
            '- build: a version/BUILD-blocked capability — "version-BLOCKED on the current <pkg> build", a capability gated on a ' +
            'newer release. routeKey = "build:" + the package. A row whose route resolves to nothing usable also lands here as ' +
            '"build:unresolved" so a native lane can confirm the block.\n' +
            'A page with no research rows contributes nothing but is listed in `coverage.read`. Cite an anchor only after ' +
            'confirming the row text on disk; a mis-located or invented entry is a defect.',
    ].join('\n\n');

// reg = the EXECUTING branch: 'claude' for the native assay/build/extdoc clusters, 'codex' for the catalog/doc-file
// codex lanes; the stance, self-verify intensifier, and TASK header fork, the route substance is identical.
const verifyPrompt = (L, cluster, reg) =>
    [
        CONTEXT(L),
        STANCE(L, reg),
        VERIFY(L),
        SELF_CHECK(reg),
        'TASK: ' +
            (reg === 'codex' ? '' : 'HOSTILE ') +
            'ROUTE VERIFICATION of the research debts in cluster `' +
            cluster.routeKey +
            '` (family `' +
            cluster.routeFamily +
            '`). Each entry names a member spelling, capability, or behavior a writer GUESSED; your job is to DECIDE it at the ' +
            'route, never to trust the page. ENTRIES: ' +
            JSON.stringify(cluster.entries) +
            '.\nRUN THE ROUTE per the family:\n' +
            '- assay: run `' +
            L.verify +
            '` against the named assembly/package and read the real member surface; a spelling absent from the decompile is ' +
            'REFUTED (a phantom).\n' +
            '- build: probe the CURRENTLY installed package build (its version and member surface via the same assay/uv route); ' +
            'a capability the current build still lacks is UNRESOLVABLE (blocked), a capability the current build now ships is ' +
            'CONFIRMED with the real spelling.\n' +
            '- catalog: open the named repo `.api/api-*.md` catalog and confirm the member spelling VERBATIM; a catalog that ' +
            'lacks it but exists routes the entry UNRESOLVABLE (the catalog must grow first), a contradicting spelling REFUTES.\n' +
            '- docfile: open the named repo doc or seam anchor and confirm the claim/spelling at its coordinate; a doc that ' +
            'contradicts the row REFUTES, a doc silent on it routes UNRESOLVABLE.\n' +
            '- extdoc: resolve the library via Context7 (resolve-library-id then query-docs, or a known /org/project id) and ' +
            'confirm the member against the official surface; unreachable/ambiguous is UNRESOLVABLE.\n' +
            'For EACH entry return {question, page, anchor, verdict, evidence, spelling}: verdict `confirmed` (the route proves ' +
            'the exact spelling — put it in `spelling`, the proving member block/command result in `evidence`), `refuted` (the ' +
            'route proves the guess wrong — `evidence` names the real member or the absence, `spelling` empty or the corrected ' +
            'form), or `unresolvable` (the route cannot decide now — `evidence` names WHY, `spelling` empty). Never mark ' +
            'confirmed without the route output in `evidence`; an unrun route is `unresolvable`, never an optimistic confirm.',
    ].join('\n\n');

// reg selects STANCE by the EXECUTING branch: apply + red-team run native ('claude'), the critique runs codex ('codex').
const applyPreamble = (L, folder, scopes, reg) => [
    CONTEXT(L),
    STANCE(L, reg),
    VERIFY(L),
    RIPPLE_LAW,
    CURRENT_STATE,
    PROSE_COMMENTS(L),
    readFirst(L, folder),
    LEDGER(scratchBase(folder, 0), scopes),
];

const applyPrompt = (L, folder, entries, verdictReports, scopes) =>
    applyPreamble(L, folder, scopes, 'claude')
        .concat([
            'TASK: RESOLVE the research debts of this folder IN PLACE: ' +
                folder +
                '. Load the `docgen` skill via the Skill tool BEFORE any durable prose edit. Read the folder pages that carry ' +
                'these entries IN FULL, and read the VERDICT REPORTS on disk IN FULL at these paths (each a JSON ' +
                '{verdicts:[{question, page, anchor, verdict, evidence, spelling}]}): ' +
                JSON.stringify(verdictReports) +
                '. The folder research entries (match each verdict to its row by page+anchor+question): ' +
                JSON.stringify(entries) +
                '.\nFOR EACH ROW, act by its verdict:\n' +
                '- confirmed: BAKE the confirmed `spelling` into the fence at its site — replace the guessed/placeholder member ' +
                'with the real one, wire it through every fence that assumed it, then DELETE the research row entirely. The fact ' +
                'now lives in the fence; the row is scaffolding and leaves no trace.\n' +
                '- refuted: CORRECT the assumption at its ROOT — the fence built on the wrong spelling/behavior is rebuilt on the ' +
                'real one from `evidence` (a denser owner where the correction opens one), every dependent fence realigned; ' +
                'CAPABILITY-COMPLETENESS binds the rebuild — the corrected owner implements what its names and prose promise, a ' +
                'named-but-omitted capability closed NOW at the same bar as the correction — then DELETE the research row ' +
                'entirely.\n' +
                '- unresolvable: SHARPEN the row IN PLACE — rewrite it to the crispest possible question and the most precise ' +
                'route (the exact member to decompile, the exact catalog to grow, the exact doc to consult), and keep the ' +
                'settled interim fence explicit. Never leave vague residue; never delete an unresolvable row.\n' +
                'NO TOMBSTONES: a deleted row leaves no "resolved"/"verified"/"removed" note, no empty `## [NN]-[RESEARCH]` ' +
                'heading, and no dangling `see [NN]-[RESEARCH]` pointer — a section emptied of every row is removed and its ' +
                'section numbering closed up; a cross-reference to a deleted row is rewritten to the baked fact or dropped. Every ' +
                'ripple a bake/correction opens is YOURS per RIPPLE LAW — seam counterparts both ends, index rows via ' +
                '`indexRows`. ' +
                L.modern +
                '; ' +
                L.fileOrg +
                '; high-signal all-backticked prose. GATE: run `uv run .claude/skills/docgen/scripts/prose_gate.py <every ' +
                'touched .md>` and repair to zero FAILs before returning. Return the fix-log — `baked`/`deleted`/`sharpened` ' +
                'counts exact, `deltas` every moved symbol/wire, `deferred` the backlog rows. ' +
                HARVEST_LAW,
        ])
        .join('\n\n');

const critiquePrompt = (L, folder, entries, verdictReports, scopes, nav) =>
    applyPreamble(L, folder, scopes, 'codex')
        .concat([
            OWN_PASS(scratchBase(folder, 0) + '-crit-ownpass.md', 'NAVIGATION'),
            'NAVIGATION (facts from the apply pass — locations only, no assessments; it changes where you look FIRST, never what ' +
                'you conclude): ' +
                JSON.stringify(nav),
            'VERDICT REPORTS (read IN FULL from disk — the route decisions the apply pass was meant to honor): ' +
                JSON.stringify(verdictReports) +
                '. The folder research entries: ' +
                JSON.stringify(entries),
            GIT_GROUND,
            'TASK: RESOLUTION-CONFORMANCE AUDIT; fix EACH defect in place for folder ' +
                folder +
                '. Per OWN PASS FIRST above, your written defect artifact precedes NAVIGATION. Your mandate is ' +
                'PREDICATE-POSITIVE — verify each resolution actually held:\n' +
                '- A `confirmed` verdict whose spelling was baked: the baked member appears verbatim in the fence AND matches the ' +
                'verdict `evidence`; a spelling baked that the verdict did NOT confirm (or that contradicts the evidence) is a ' +
                'defect — re-derive it and correct.\n' +
                '- A deleted row: the fact it carried actually LANDED in a fence; a row deleted whose fact never landed is a ' +
                'silent capability loss — restore the fact into the fence.\n' +
                '- A surviving row: verification did NOT already answer it; a row left standing that a verdict already resolved is ' +
                'stale residue — bake/delete it now.\n' +
                '- No tombstone survives: no empty RESEARCH heading, no dangling `see [NN]-[RESEARCH]` pointer, no ' +
                '"resolved"/"verified" note; the `.api`/doctrine conformance of every touched fence holds (' +
                L.modern +
                '; ' +
                L.fileOrg +
                '). Every miss is repaired at its root now, a cross-file hit yours per RIPPLE LAW. GATE the touched .md through ' +
                'the docgen prose gate to zero FAILs. Return the fix-log — `deltas` and `deferred` exact. ' +
                HARVEST_LAW,
        ])
        .join('\n\n');

const redteamPrompt = (L, folder, entries, verdictReports, scopes, nav, critOk, critReport) =>
    applyPreamble(L, folder, scopes, 'claude')
        .concat([
            'NAVIGATION (locations only, no assessments): ' + JSON.stringify(nav),
            'VERDICT REPORTS (read IN FULL from disk): ' + JSON.stringify(verdictReports) + '. Folder research entries: ' + JSON.stringify(entries),
            (critOk
                ? 'PRIOR CLAIMS (UNVERIFIED): the critique fixlog is ON DISK at ' + critReport
                : 'PRIOR CLAIMS (UNVERIFIED): the critique wrapper died, but the lane writes its fixlog before any ceiling ' +
                  'can kill the call — check ' +
                  critReport +
                  ' FIRST; absent or unparseable, your cold attack is the only review this folder gets, judged from CURRENT disk ' +
                  'alone. Present') +
                ' — read it IN FULL from disk; its edits and verdicts are refutation targets you judge against CURRENT disk, ' +
                'never a settled record. FOLD-FORWARD DUTY: its surviving `seamsTouched`, `deltas`, `deferred`, `beyondMap`, and ' +
                '`indexRows` rows fold into YOUR return (re-verified against current disk, deduped) — your fix-log is the folder ' +
                'consolidated record. Its `harvest` rows are NOT yours to fold: the doctrine lander sweeps every critique fixlog ' +
                'from disk directly, so nomination transport never rides a living fold.',
            OWN_PASS(scratchBase(folder, 0) + '-rt-ownpass.md', 'the PRIOR CLAIMS'),
            GIT_GROUND,
            'TASK: ADVERSARIAL RED-TEAM of the RESOLUTION; fix EACH defect in place for folder ' +
                folder +
                '. Assume the apply and critique missed things and their claims are wrong until disk proves them. Per OWN PASS ' +
                'FIRST above, your written attack artifact precedes the claims. Your mandate is ' +
                'PREDICATE-NEGATIVE — a pre-mortem on the resolution:\n' +
                '(A) FALSE BAKE — a baked spelling not ACTUALLY proven by its verdict `evidence`: re-run the route in your head ' +
                'against the evidence; a spelling the evidence does not support is a fresh phantom, reverted to the real member ' +
                'or re-flagged as a sharpened unresolvable row.\n' +
                '(B) LOST FACT — a deleted row whose fact did NOT land anywhere in the fence set: the capability the row guarded ' +
                'is gone; restore it into the owning fence, densely.\n' +
                '(C) STALE SURVIVOR — a surviving research row that a landed verdict already answered: resolve it now (bake or ' +
                'delete).\n' +
                '(D) TOMBSTONE + POINTER — an empty RESEARCH section, a "resolved" note, or a `see [NN]-[RESEARCH]` pointer to a ' +
                'deleted row: remove it and rewire the reference to the baked fact.\n' +
                '(E) SHARPEN QUALITY — an unresolvable row left vague: rewrite it to the exact member/catalog/doc and the precise ' +
                'route, the interim fence explicit.\n' +
                'Then a FULL COLD RE-REVIEW of every touched fence against the doctrine (' +
                L.modern +
                '; ' +
                L.fileOrg +
                '; both-tier .api maximization; prose + comment hygiene), judged against CURRENT disk. Every ripple is yours per ' +
                'RIPPLE LAW; GATE the touched .md through the docgen prose gate to zero FAILs. Return the consolidated fix-log — ' +
                '`deltas` and `deferred` exact. ' +
                HARVEST_LAW,
        ])
        .join('\n\n');

const fixerPrompt = (langs, rows, backlog, folders, orphans, round) =>
    [
        ROOT_LAW,
        round
            ? 'DRAIN ROUND ' +
              round +
              ' — the backlog rows below were verified STILL-OPEN by the prior round; fix each at its root NOW, and a row you ' +
              'genuinely cannot land carries its named blocker and owner in `remaining`. Every other tranche re-arrives in full ' +
              'so a dead or partial prior round loses nothing — the checkpoint ledger is the consumption truth: skip every ' +
              'tranche it receipts, drain the rest.'
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
                        '; verify members via ' +
                        LANG[k].verify +
                        '.',
                )
                .join('\n'),
        GIT_GROUND,
        'CHECKPOINT LEDGER: `' +
            SCRATCH +
            '/fixer-checkpoint.md` — read it FIRST and skip every tranche it already receipts (an interrupted drain re-enters, ' +
            'never restarts); append one line per tranche AS EACH COMPLETES (the index-row apply, the backlog block, each ' +
            'critique fixlog, the own hunt). HARVEST FILE: append each `harvest` nomination to `' +
            SCRATCH +
            '/fixer-harvest.jsonl` (one JSON row per line) the moment it is minted — the doctrine lander sweeps the file, so a ' +
            'killed round loses no nomination; your returned `harvest` carries the same rows. Your returned `tranches` lists the ' +
            'checkpoint receipt line of every tranche fed this round — a fed tranche absent from that list is unconsumed.',
        "TASK: TERMINAL FIX (WRITER — you are the run's LAST agent, nothing follows you; full write authority over the resolved " +
            'corpus and libs-wide ripple authority with the expand-form bound LIFTED — collapse, rename, and contract are yours ' +
            "now that no sibling writer runs; and you are the run's SOLE writer for the owning-package index docs, IDEAS.md, and " +
            'the central manifests). Resolved folders: ' +
            JSON.stringify(folders) +
            '.\nTRANCHE ORDER IS EXECUTION ORDER — drain the received rows (1, 2, 2b) before the own hunt (3); never demote a ' +
            'received tranche behind the hunt.\n' +
            [
                rows.length
                    ? '(1) INDEX ROWS: apply every reported row to its owning doc exactly once — dedupe semantically identical rows, ' +
                      'keep each doc section grammar, verify every folder resolved this run is truthfully reflected; a central-manifest ' +
                      'row hand-edits the grouped manifest at the SYMBOL anchor (never a line number); an IDEAS row lands as a ' +
                      'fully-specified card in the named IDEAS.md: ' +
                      JSON.stringify(rows) +
                      '.'
                    : '',
                backlog.length
                    ? '(2) DEFERRED BACKLOG (second-order and cross-folder ripples the apply/red-team writers recorded — re-verify ' +
                      'each {files, claim} on current disk, fix what holds, reject what disk already resolved): ' +
                      JSON.stringify(backlog) +
                      '.'
                    : '',
                orphans.length
                    ? '(2b) CRITIQUE FIXLOGS (every critique fixlog on disk, keyed on its deterministic path — a folder whose ' +
                      'red-team folded its own fixlog already landed those seamsTouched/deferred/indexRows rows, so re-verification ' +
                      'disk-dedupes them, while a fixlog whose red-team died folds for the first time here — read each present file ' +
                      'IN FULL from disk and drain the seam/deferred/index rows still open under the same law; the fixlog `harvest` ' +
                      "arrays are the doctrine lander's to sweep, never yours to fold): " +
                      JSON.stringify(orphans) +
                      '.'
                    : '',
                '(3) OWN HUNT: on your own authority, sweep the resolved folders for the resolution-defect classes the chain may ' +
                    'have missed — a baked spelling not actually verified, a deleted row whose fact never landed in a fence, a ' +
                    'surviving row a verdict already answered, an empty RESEARCH section or dangling `see [NN]-[RESEARCH]` pointer, ' +
                    'an unresolvable row left vague — and fix each at its root; `beyond` enumerates those fixes, and an empty ' +
                    '`beyond` attests your hunt found nothing, never that it did not run.',
                'Every ripple an edit exposes is YOURS in the same pass — seam counterparts both ends, consumer sites, index docs, ' +
                    'manifest rows, .api anchors; wire-canonical names stay frozen. Return the final fixlog — `remaining` carries ' +
                    'ONLY rows verified still-open on current disk and genuinely blocked, each claim naming its blocker and owner; a ' +
                    'row disk already resolved is culled with proof in `rejected`, and an empty `remaining` attests the drain ' +
                    'closed. ' +
                    HARVEST_LAW,
            ]
                .filter(Boolean)
                .join('\n'),
    ]
        .filter(Boolean)
        .join('\n\n');

// --- [COMPOSITION] ---------------------------------------------------------------------

if (REJECTED.length) log('Rejected targets outside libs/{csharp,python,typescript}: ' + REJECTED.join(', '));
if (!TARGETS.length) {
    log('No targets — pass a folder path, an array of paths, or {targets}. Empty args is a no-op.');
    return { targets: [], total: 0 };
}

phase('Discover');
const disc = await slot(() =>
    agent(discoverPrompt(), { label: 'discover', phase: 'Discover', model: 'sonnet', effort: 'low', schema: DISCOVER_SCHEMA }),
);
// Guard the model-emitted page roster: a discover-emitted path outside a valid libs/{cs,py,ts} route would route as cs by
// Lof's fallback and dispatch census/apply on a wrong-language page — drop it before any lane fires.
const RAW_PAGES = [...new Set(((disc && disc.pages) || []).filter(Boolean))];
const PAGES = RAW_PAGES.filter((p) => langOf(p));
const STRAY = RAW_PAGES.filter((p) => !langOf(p));
if (STRAY.length) log('Dropped ' + STRAY.length + ' discover page(s) outside libs/{csharp,python,typescript}: ' + STRAY.join(', '));
const UNRESOLVED = (disc && disc.unresolved) || [];
if (UNRESOLVED.length) log('Unresolved targets (mis-scoped or renamed): ' + UNRESOLVED.join(', '));
if (!PAGES.length) {
    log('No design pages resolved under the targets');
    return { targets: TARGETS, total: 0 };
}
const FOLDERS = [...new Set(PAGES.map(pkgOf))];
log('Discover: ' + PAGES.length + ' pages across ' + FOLDERS.length + ' folder(s); CAP=' + CAP + ', CENSUS_PAGES=' + CENSUS_PAGES);

phase('Census');
// One census lane per folder, large folders split by page count; each lane returns its slice entries on the wire.
const censusUnits = FOLDERS.flatMap((f) =>
    evenChunk(
        PAGES.filter((p) => pkgOf(p) === f),
        CENSUS_PAGES,
    ).map((slice, i) => ({ f, i, pages: slice })),
);
const censusRes = (
    await Promise.all(
        censusUnits.map((u) =>
            slot(() => census(censusPrompt(Lof(u.f), u.pages), { label: 'census:' + u.f.split('/').pop() + ':s' + u.i })).catch(() => null),
        ),
    )
).filter(Boolean);
const ENTRIES = censusRes.flatMap((r) => (r && r.entries) || []).filter((e) => e && e.page && e.routeKey);
log('Census: ' + ENTRIES.length + ' research row(s) across ' + censusRes.length + '/' + censusUnits.length + ' lane(s)');
if (!ENTRIES.length) {
    log('No research rows under the targets — nothing to resolve');
    return { targets: TARGETS, folders: FOLDERS.length, entries: 0 };
}

phase('Verify');
// Cluster (plain orchestrator code, no agent): group the census entries by verification route family/key.
const CLUSTERS = Object.values(
    ENTRIES.reduce((m, e) => {
        const k = e.routeKey;
        (m[k] = m[k] || { routeKey: k, routeFamily: e.routeFamily || 'docfile', entries: [] }).entries.push(e);
        return m;
    }, {}),
);
log('Verify: ' + CLUSTERS.length + ' cluster(s) by route family');
// The route decides the lane: assay/build/extdoc run NATIVE (tools.assay over host DLLs, a native Context7 lane for
// extdoc); catalog/docfile ride codex lanes reading the repo.
const verified = (
    await Promise.all(
        CLUSTERS.map((c) => {
            const label = 'verify:' + fileTag(c.routeKey);
            const scope = [...new Set(c.entries.map((e) => e.page))];
            const L = Lof(pkgOf(c.entries[0].page));
            // Register follows the executing branch: native assay/build/extdoc get the hostile register they sharpen on; codex catalog/doc lanes get neutral.
            const p = NATIVE_FAMILY[c.routeFamily]
                ? asLane(
                      label,
                      scope,
                      nativeLane(verifyPrompt(L, c, 'claude'), {
                          label,
                          phase: 'Verify',
                          schema: VERDICT_SCHEMA,
                          nativeModel: 'opus',
                      }),
                  )
                : recon(verifyPrompt(L, c, 'codex'), {
                      label,
                      phase: 'Verify',
                      schema: VERDICT_SCHEMA,
                      model: 'gpt-5.6-terra',
                      scope,
                      hl: { arr: 'verdicts', group: 'verdict' },
                  });
            return slot(() => p.then((r) => (r ? Object.assign(r, { routeKey: c.routeKey, rows: c.entries }) : null))).catch(() => null);
        }),
    )
).filter(Boolean);
const VERIFIED_OK = verified.filter((v) => v.ok);
log(
    'Verify: ' +
        VERIFIED_OK.reduce((a, v) => a + v.entries, 0) +
        ' verdict(s) across ' +
        VERIFIED_OK.length +
        '/' +
        verified.length +
        ' cluster(s)' +
        (verified.length > VERIFIED_OK.length
            ? ' — FAILED: ' +
              verified
                  .filter((v) => !v.ok)
                  .map((v) => v.routeKey)
                  .join(', ')
            : ''),
);

phase('Apply');
// Per folder, pipelined: apply -> critique -> red-team chained behind the folder only, all folders concurrent under the slot cap.
const applyFolders = [...new Set(ENTRIES.map((e) => pkgOf(e.page)))];
const SCOPES = JSON.stringify(
    applyFolders.map((f) => ({ folder: f.split('/').pop(), pages: [...new Set(ENTRIES.filter((e) => pkgOf(e.page) === f).map((e) => e.page))] })),
);
const built = (
    await Promise.all(
        applyFolders
            .map(async (folder) => {
                const L = Lof(folder);
                const folderEntries = ENTRIES.filter((e) => pkgOf(e.page) === folder);
                // Verdict reports covering this folder: any landed verify cluster holding an entry whose page is in the folder.
                const verdictReports = [...new Set(VERIFIED_OK.filter((v) => v.rows.some((e) => pkgOf(e.page) === folder)).map((v) => v.report))];
                const tag = folder.split('/').pop();
                const applyOpts = (suffix) => ({
                    label: 'apply:' + tag + suffix,
                    phase: 'Apply',
                    model: 'fable',
                    effort: 'high',
                    schema: FIXLOG_SCHEMA,
                });
                const apply =
                    (await slot(() => agent(applyPrompt(L, folder, folderEntries, verdictReports, SCOPES), applyOpts('')))) ||
                    (await retryLane(() => slot(() => agent(applyPrompt(L, folder, folderEntries, verdictReports, SCOPES), applyOpts(':a1')))));
                // CHAIN CONTINUATION: a dead apply never blocks the reviews — the critique's conformance audit and the red-team's
                // pre-mortem still improve the pages as they stand on disk; navigation simply arrives empty.
                const nav = navOf(apply ? [apply] : []);
                const crit = await slot(() =>
                    recon(critiquePrompt(L, folder, folderEntries, verdictReports, SCOPES, nav), {
                        label: 'crit:' + tag,
                        phase: 'Apply',
                        schema: REVIEW_SCHEMA,
                        writes: true,
                        fix: true,
                        nativeModel: 'fable',
                        scope: [...new Set(folderEntries.map((e) => e.page))],
                        hl: { arr: 'files' },
                    }),
                );
                const critR = crit && crit.ok ? crit : null;
                // Deterministic critique-report path from the folder alone — set even when the critique wrapper dies, so the redteam
                // and the terminal drain reach a written fixlog off the path, never a receipt a dead wrapper never returned.
                const critReport = SCRATCH + '/' + fileTag('crit:' + tag) + '-report.json';
                const rtArgs = redteamPrompt(L, folder, folderEntries, verdictReports, SCOPES, nav, !!critR, critReport);
                const rtOpts = (suffix) => ({
                    label: 'rt:' + tag + suffix,
                    phase: 'Apply',
                    model: 'fable',
                    effort: 'high',
                    schema: REVIEW_SCHEMA,
                });
                const rt = (await slot(() => agent(rtArgs, rtOpts('')))) || (await retryLane(() => slot(() => agent(rtArgs, rtOpts(':a1')))));
                return { folder, entries: folderEntries, apply, crit: critR, critReport, rt };
            })
            .map((p) => p.catch(() => null)),
    )
).filter(Boolean);
const RESOLVED = built.filter((d) => d.apply).map((d) => d.folder);
const FAILED = built.filter((d) => !d.apply).map((d) => d.folder);
// The critique fixlog lives on disk; the red-team folds its rows forward, so aggregation reads apply + rt only.
const ROWS = built.flatMap((d) => ((d.apply && d.apply.indexRows) || []).concat((d.rt && d.rt.indexRows) || []));
const BACKLOG = built.flatMap((d) => ((d.apply && d.apply.deferred) || []).concat((d.rt && d.rt.deferred) || []));
// EVERY critique fixlog reaches the fixer — keyed on the DETERMINISTIC path, never the receipt: a dead wrapper does not
// erase a written fixlog, a live red-team's fold is judgment-lossy anyway, and rows already landed disk-resolve and drop
// in the fixer's re-verifying sweep.
const ORPHANS = built.filter((d) => d.critReport).map((d) => d.critReport);
const HARVEST_ROWS = built.flatMap((d) => ((d.apply && d.apply.harvest) || []).concat((d.rt && d.rt.harvest) || []));
const BAKED = built.reduce((a, d) => a + ((d.apply && d.apply.baked) || 0), 0);
const DELETED = built.reduce((a, d) => a + ((d.apply && d.apply.deleted) || 0), 0);
const SHARPENED = built.reduce((a, d) => a + ((d.apply && d.apply.sharpened) || 0), 0);
log(
    'Apply: ' +
        RESOLVED.length +
        '/' +
        applyFolders.length +
        ' folder(s) resolved; ' +
        BAKED +
        ' baked, ' +
        DELETED +
        ' deleted, ' +
        SHARPENED +
        ' sharpened, ' +
        BACKLOG.length +
        ' deferred row(s)' +
        (FAILED.length ? ' — FAILED (reported, run continues): ' + FAILED.join(', ') : ''),
);
if (!RESOLVED.length) {
    log('Nothing resolved — no close to run');
    return { targets: TARGETS, folders: applyFolders.length, entries: ENTRIES.length, resolved: 0, failed: FAILED };
}

phase('Close');
const RESOLVED_LANGS = [...new Set(RESOLVED.map((f) => langOf(f)).filter(Boolean))];
// Terminal DRAIN LOOP: one serial closer per round verifies every row against live disk, fixes at root, loops until
// empty; a round without shrinkage stops with the blocked set final. Every round re-receives the FULL tranche set — index
// rows, orphan fixlogs, and the residual backlog — because the checkpoint ledger receipts consumption, so a dead or partial
// round loses nothing and a live one skips what it already landed; only the backlog narrows round over round.
let fixer = null;
let fixerHarvest = [];
let residuals = BACKLOG;
let lastOpen = Infinity;
for (let round = 0; round < DRAIN_ROUNDS; round++) {
    const fire = (suffix) =>
        slot(() =>
            agent(fixerPrompt(RESOLVED_LANGS, ROWS, residuals, RESOLVED, ORPHANS, round), {
                label: (round ? 'fixer:r' + round : 'fixer') + suffix,
                phase: 'Close',
                model: 'fable',
                effort: 'high',
                schema: FIXER_SCHEMA,
            }),
        );
    fixer = (await fire('')) || (await retryLane(() => fire(':a1')));
    if (!fixer) break; // dead round after retries: the residual and orphan sets survive to the run return, every disk tranche stays checkpoint-re-enterable
    fixerHarvest = fixerHarvest.concat(fixer.harvest || []);
    const open = fixer.remaining || [];
    residuals = open;
    if (!open.length || open.length >= lastOpen) break;
    lastOpen = open.length;
}
const POOLED_HARVEST = HARVEST_ROWS.concat(fixerHarvest);
// DOCTRINE LANDER: the run durable-learning terminal — pooled harvest nominations adjudicated against the live doctrine
// surfaces; refutation-first, land-nothing legal, admission law owned by docs/laws. A dead fixer still fires it (its
// nominations live in the incremental harvest file), and critique fixlogs on disk fire it too — the lander is those
// harvest arrays' ONLY transport, never a living red-team or fixer fold.
const doctrine =
    POOLED_HARVEST.length || ORPHANS.length || !fixer
        ? await slot(() =>
              agent(
                  ROOT_LAW +
                      '\n\nTASK: DOCTRINE LANDER — the durable-learning terminal of a research-resolution run. Read ' +
                      '`docs/laws/README.md` FIRST — it owns the corpus admission and page-shape law; obey it over any restatement. ' +
                      'Load the `docgen` skill via the Skill tool BEFORE any durable edit; load ' +
                      "`mermaid-diagramming` before touching any diagram. NOMINATIONS (unverified, biased toward their authors' own " +
                      'work — refute by default): ' +
                      JSON.stringify(POOLED_HARVEST) +
                      '\nAlso sweep `' +
                      SCRATCH +
                      '/fixer-harvest.jsonl` (absent = none): rows there missing from NOMINATIONS are nominations too — a killed ' +
                      'fixer round reaches you only through that file.\n' +
                      'Also read the `harvest` array of every critique fixlog at these deterministic paths (an absent or invalid ' +
                      'file skips; no other agent transports these rows): ' +
                      JSON.stringify(ORPHANS) +
                      ' — dedupe them against NOMINATIONS and adjudicate them identically.\n' +
                      'ADJUDICATE each row per the admission bar: cold-read its target surface IN FULL, verify its anchors on ' +
                      'CURRENT disk; LAND NOTHING is a first-class verdict.\n' +
                      'TOPOLOGY RE-PROOF: re-verify every `docs/laws/topology.md` row whose [SURFACE] this run touched — cull a row ' +
                      'whose coupling no longer holds, land a coupling this run proved.\n' +
                      'GATE: run `uv run .claude/skills/docgen/scripts/prose_gate.py <every touched .md>` and repair to zero FAILs ' +
                      'before returning. Return landed/refined/rejected (each rejection with its reason)/files/summary.',
                  { label: 'doctrine', phase: 'Close', model: 'fable', effort: 'high', schema: DOCTRINE_SCHEMA },
              ),
          )
        : null;

const verdictCounts = {
    total: VERIFIED_OK.reduce((a, v) => a + v.entries, 0),
    clusters: VERIFIED_OK.length,
    failedClusters: verified.filter((v) => !v.ok).map((v) => v.routeKey),
    lanes: VERIFIED_OK.map((v) => ({ routeKey: v.routeKey, count: v.entries, headline: v.headline })),
};
return {
    targets: TARGETS,
    languages: RESOLVED_LANGS,
    folders: applyFolders.length,
    entries: ENTRIES.length,
    resolved: RESOLVED.length,
    failed: FAILED,
    baked: BAKED,
    deleted: DELETED,
    sharpened: SHARPENED,
    verdictCounts,
    backlog: BACKLOG.length,
    residuals,
    fixer: fixer && {
        files: (fixer.files || []).length,
        indexApplied: (fixer.indexApplied || []).length,
        backlogDrained: (fixer.backlogDrained || []).length,
        beyond: (fixer.beyond || []).length,
        rejected: (fixer.rejected || []).length,
        summary: fixer.summary,
    },
    doctrine: doctrine && {
        nominated: POOLED_HARVEST.length,
        landed: (doctrine.landed || []).length,
        refined: (doctrine.refined || []).length,
        rejected: (doctrine.rejected || []).length,
        files: doctrine.files || [],
        summary: doctrine.summary,
    },
};
