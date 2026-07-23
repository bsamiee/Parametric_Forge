export const meta = {
    name: 'ideate',
    whenToUse: 'Rebuild a folder IDEAS and TASK pool to world-class when the deferred idea or task pool is stale or thin.',
    description:
        'Rebuild a folder IDEAS + TASKS card pool to world-class: survey the realized corpus and research the real domain, author the genuinely-deferred idea/task pool, then fix-in-place constructive critique + hostile adversarial redteam. Language-agnostic (cards are markdown governed by the card schema). Authors NO design pages (that is the rebuild-* workflows) and aligns nothing pre-existing for its own sake (that is align-cards) — this is the greenfield/expansion pool generator. Every agent call takes a slot in one agent-level scheduler so the true in-flight agent count stays at cap while all folder chains run concurrently; within a folder the survey -> ideate -> critique -> redteam chain holds because each stage consumes the prior stage\'s landed cards, and a folder above the survey page cap runs two page-slice survey agents whose maps merge before the ideate stage. Survey lanes (including the page-slice splits) run as dispatched recon lanes; ideate and redteam stay native writers, and critique runs as ONE dispatched write lane per folder (cardlog to disk, receipt on the wire; the redteam reads it from disk as refutation targets and folds its verified files into the folder record). Every stage writes BOTH ends of every Ripple itself — a cross-folder counterpart is authored or repaired directly in the sibling folder\'s card files in the same pass under the current-state law; nothing routes to a later phase. Every writing stage also nominates generalizable lessons into a required-usually-empty harvest, folded forward through the redteam and the orphan drain; one terminal doctrine lander then adjudicates the pooled harvest against the docs/laws admission bar (land-nothing legal) before the run closes. The terminal stays the single fold-forward orphan drain, not a round-based DRAIN LOOP: Ripples land both ends in-pass by design and the cardlog carries no {files, claim} backlog, so nothing pools across stages. args = optional scope (e.g. "libs/python/geometry"); empty = all of libs.',
    phases: [
        {
            title: 'Survey',
            detail: 'discover card-owning folders with page counts, then per folder: a dispatched recon lane maps realized capability + current pool + researched domain-completeness gaps + cross-folder seams; a folder above the survey page cap splits the survey across two page-slice recon lanes merged before ideate',
        },
        { title: 'Ideate', detail: 'author/rebuild the IDEAS + TASKS pool grounded in the survey, genuinely-deferred only, both Ripple ends landed' },
        {
            title: 'Critique',
            detail: 'fix-in-place write lane: pull the pool up — density, domain-completeness, anchors, ripples; cardlog to disk',
        },
        { title: 'Redteam', detail: 'fix-in-place hostile reviewer: attack redundancy, mis-carding, dangling ripples, under-ideation' },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const CAP = 14;
const SURVEY_PAGE_CAP = 12;
const ROOT = '/Users/bardiasamiee/Documents/99.Github/Rasm'; // absolute working root; codex cwd + native terminal lanes resolve relative scratch paths against it
const RETRY_ATTEMPTS = 2;

// --- [INPUTS] --------------------------------------------------------------------------

const input =
    typeof args === 'string'
        ? (() => {
              try {
                  return JSON.parse(args);
              } catch {
                  return args;
              }
          })()
        : args;
const rawScope = typeof input === 'string' ? input.trim() : input && typeof input === 'object' && input.target ? String(input.target).trim() : '';
const SWEEP = !rawScope || rawScope === 'ALL' ? 'libs' : rawScope;
// Per-instance scratch dir for the lane report files — minted deterministically from the normalized scope (clock/randomness would break
// resume): one FLAT dir under .claude/scratch/, a human-readable basename slug and an FNV-1a tail forking distinct scopes and rehydrating on resume.
const fnv1a = (s) => {
    let h = 0x811c9dc5;
    for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193);
    return (h >>> 0).toString(16).padStart(8, '0').slice(0, 6);
};
const SCRATCH =
    '.claude/scratch/' +
    ('ideate-' + SWEEP.split('/').pop().toLowerCase()).replace(/[^a-z0-9.-]+/g, '-').slice(0, 60) +
    '-' +
    fnv1a(JSON.stringify(SWEEP));

// --- [MODELS] --------------------------------------------------------------------------

const DISCOVERY_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['folders'],
    properties: {
        folders: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['folder', 'pages'],
                properties: { folder: { type: 'string' }, pages: { type: 'integer' } },
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

// Heavy survey product — written to disk, read by the ideate stage; inventory-shaped, one anchored fact per entry.
const SURVEY_SCHEMA = {
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
                    target: { type: 'string' }, // page, seam, catalog, or card the entry grounds
                    kind: { type: 'string', enum: ['realized', 'gap', 'cross-folder', 'existing-card', 'stacking'] },
                    files: { type: 'array', items: { type: 'string' } }, // files the ideate stage must open for this entry
                    info: { type: 'string' }, // the fact: realized capability, deferred gap, seam endpoints — prose truth, zero prescriptions
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

// Thin wire receipt: the survey lane's PRODUCT stays on disk at `report`; only status + count + headline travel inline.
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

// Required-but-possibly-empty `beyondFolder` is an attestation: the cross-folder Ripple hunt ran, and every counterpart landed.
const CARDLOG_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'beyondFolder', 'verdict', 'summary', 'applied', 'harvest'],
    properties: {
        files: { type: 'array', items: { type: 'string' } },
        beyondFolder: { type: 'array', items: { type: 'string' } },
        applied: { type: 'array', items: { type: 'string' } },
        verdict: { type: 'string', enum: ['authored', 'refined', 'hardened', 'clean'] },
        harvest: HARVEST,
        summary: { type: 'string' },
    },
};

// The run's durable-learning terminal product: nominations adjudicated against the docs/laws admission bar.
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

const LAW = [
    'Rasm monorepo. CLAUDE.md card law governs. READ libs/.planning/campaign-method.md for the role law and voice, and libs/.planning/README.md ' +
        'for the exact IDEAS/TASKLOG card schema. You produce a folder ' +
        'IDEAS + TASKS card pool: IDEAS are conceptual/multi-step/higher-order deferred capability; TASKS are concrete/focused deferred units. Every ' +
        'card passes the 7-point density rubric (polymorphic collapse; one-hop; growth-axis absorption; Result/Option rails; library-at-depth; ' +
        'policy-values not boolean knobs; greenfield in-place). A card is ONLY for genuinely DEFERRED work — NEVER duplicate a realized design page, ' +
        'NEVER a test/meta/decision/unblock/create-file card. Cards are FLOORS, not ceilings. HARDENING: capability is improved or extended, NEVER ' +
        'dropped for lack of a current consumer — zero consumers never lowers the bar; planned future consumers are real design pressure on every card.',
    'NAIVETY LAW: a card is naive on two axes, both defects repaired on sight — COVERAGE: its Capability/Shape models a thin slice of the concept ' +
        '(the obvious three fields where the domain carries fifteen; a two-case family for a twenty-case domain); APPROACH: enumerated hardcoded ' +
        'instances — a fixed roster of styles/patterns/variants — where a parameterized algorithmic owner should generate the space (a roster is ' +
        'seed DATA feeding one generator over named parameters, never the mechanism). Every rubric, checklist, and attack list in this workflow is ' +
        'a FLOOR hunted past, never the complete set: any repeated structure, parallel spelling, or enumerable family an algebra/table/fold/generator ' +
        'can own is a collapse target you find yourself.',
    'RIPPLE LAW: a cross-folder dependency is a Ripple that pairs two cards — each references the other by backticked owner + backticked [SLUG]. ' +
        'BOTH ends are YOURS in the same pass: a Ripple to an EXISTING counterpart REFERENCES it (never re-creates the slug); an ABSENT counterpart ' +
        'is authored NOW directly in the sibling folder IDEAS.md/TASKLOG.md (create them if absent), matched to that pool as it stands on disk. One ' +
        'canonical slug per bounded concept; no collisions; no dangling or one-sided Ripple survives your pass.',
    'CURRENT-STATE LAW: sibling folder pipelines land cards concurrently with yours. Before ANY edit — above all to a sibling folder card file — ' +
        're-read the CURRENT on-disk state of every file you touch; landed sibling work is composed as found, an existing counterpart slug is ' +
        'referenced rather than duplicated, and a conflict between your card and a landed sibling resolves to the stronger form, never a revert.',
    'RESEARCH MANDATE: never guess domain completeness. Read the folder realized corpus (its design pages + ARCHITECTURE + README) AND research the ' +
        'REAL domain to find genuinely-deferred capability the pool should hold. The pool must reflect the domain, not only what is already written.',
    'ULTRA-STACKING LAW: enumerate BOTH .api tiers in full with a real ls/find from disk, never memory — the language-root tier (libs/<lang>/.api/) ' +
        'and the folder/package tier — and mine them to operator depth. An admitted capability the domain admits but no design page or card exploits ' +
        'is a defect: card it. A member a card cites that no .api catalogue or design page verifies is a phantom: correct or delete it. Verified ' +
        'members only.',
    'WRITE-FULLY MANDATE: every card you author/refine/repair you MUST write NOW via Edit/Write directly into the owning IDEAS.md / TASKLOG.md — ' +
        'this folder or a sibling: any card file your work exposes is yours in the same pass. The writing is YOURS: never delegate authoring to ' +
        'another agent — a delegate may only fetch information. The structured log is a REPORT of edits ALREADY MADE, ' +
        'never a to-do list or hedge; leave nothing behind. `files` lists every file you edited; `beyondFolder` lists the sibling-folder card files ' +
        'among them — empty attests every Ripple counterpart already existed, never that the hunt did not run. If the pool is already world-class, ' +
        'return verdict=clean — a clean verdict is EARNED by an attack that finds nothing, never conceded on first read; never invent cards to look busy.',
].join('\n');

const ROOT_LAW =
    'WORKING ROOT: ' +
    ROOT +
    ' — every relative repo path here, scratch report paths included, resolves against this absolute root; read, write, and edit ONLY under it.';

const INFO_LAW =
    'You provide INFORMATION, never prescriptions: exact disk locations and anchors, the current shape at each realized site, seam ' +
    'endpoints on both sides, verified member spellings, gaps. The ideate stage decides what to card; a map entry that tells it what to write ' +
    'instead of what is true is a defect. ENTRY FORM: `info` is prose truth; `anchors` carry one coordinate per row (role names what it proves; ' +
    '`note` is the shortest literal witness under 20 words, or empty when path+line suffice; an `absence` anchor names where the expected thing ' +
    'was searched and not found); `files` lists what the ideate stage must open for the entry; `members` are verified catalog spellings backing a ' +
    'stacking entry. A stacking or gap entry is INVENTORY, never instruction: verified members, current usage anchors, the concept that admits it — ' +
    'the ideate stage decides whether it cards. COVERAGE is part of the product: `requested` = your assigned scope, `read` = what you actually ' +
    'full-read, `skipped`/`unverified` = what you did not reach — an honest skip beats a silent one.';

const SELF_CHECK =
    'SELF-VERIFY (second pass, before returning): re-derive every entry from disk — re-open each cited ' +
    'anchor and confirm it states what the entry claims, re-verify each member spelling against its catalog, trace each cross-folder seam to both ' +
    'endpoints. An entry that fails re-confirmation is corrected or deleted, never returned; a guess, an assumption, a skimmed summary, or a ' +
    'vague/hedged entry is a defect. Completeness is part of correctness: after the re-read, hunt once more for what the first pass missed — an ' +
    'omitted load-bearing fact is as wrong as a false one.';

const LAWS =
    'LAWS — read `docs/laws/` IN FULL (README + topology + patterns + scars; short registry pages) before any edit: a topology row whose ' +
    '[SURFACE] your edits touch binds its obligated counterparts into the SAME pass, and every patterns row binds each branch it names.';

const HARVEST_LAW =
    'HARVEST (required key, usually empty): nominate ONLY findings that generalize beyond this folder — a collapse pattern reusable across ' +
    'folders, a naivety class no card rubric names, a review rule that would have caught a defect BEFORE review, a cross-surface coupling ' +
    'discovered the hard way. Each row: altitude (stacks|reviewer|constitution|planning|readme|laws), lang, claim (the generalized law, one ' +
    'sentence), anchors (file:line evidence), existingClause (the exact doctrine or reviewer clause it would harden, quoted with its path — or ' +
    '"absent" and the surfaces searched). A card-local fix never nominates; an empty array is the normal verdict — the terminal doctrine ' +
    'lander refutes weak rows, so nominate substance, never volume.';

const OWN_PASS = (artifact, later) =>
    'OWN PASS FIRST — form your own pass as a DISK ARTIFACT before any ' +
    later +
    ' opens: cold-read the target folder from CURRENT disk — its realized corpus and any existing cards — and WRITE your ' +
    'own defect-and-ambition list to `' +
    artifact +
    '` — mis-cardings, thin-slice COVERAGE, roster-APPROACH collapses, dangling Ripples, phantom members, and the ' +
    'genuinely-deferred gaps the pool still owes — BEFORE reading it. Later inputs may only ADD rows tagged [recon]; ' +
    'reading the corpus without writing the list is a failed rung, not a cold pass. TRIPWIRE: a pass whose edits map ' +
    'one-to-one onto [recon] rows has failed — the recon covers a MINORITY of what the pass demands, and the majority of ' +
    'your edits come from your own attack.';

// --- [OPERATIONS] ----------------------------------------------------------------------

// Agent-level slot scheduler: every agent() call takes one slot, so folder chains launch freely via Promise.all while true in-flight agents stay at CAP.
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
// Bounded re-dispatch for a dead CRITICAL lane (usage-limit or transport death): attempt-counted with a retry before each
// attempt sized to a limit reset; the final death isolates the lane, NEVER the chain — every downstream stage runs against disk.
const retryLane = async (fn) => {
    for (let a = 0; a < RETRY_ATTEMPTS; a++) {
        const r = await fn();
        if (r) return r;
    }
    return null;
};
const nameOf = (f) => f.split('/').pop() || f;

// Codex dispatch: the wrapper runs one blocking supervised CLI process, writes its content to the lane report, and returns mechanical
// orchestration data. Lane law rides developer-instructions (role split — recon law for the survey lanes, fix law for the in-place critique
// lane); the prompt carries only the task; the output contract sits LAST. surveyPrompt/critiquePrompt feed dispatched lanes and carry a neutral
// register (a hostile stance makes a dispatched lane over-probe); the native ideatePrompt/redteamPrompt keep the estate register — same substance.
const fileTag = (label) => label.replace(/[^A-Za-z0-9_.-]+/g, '-');
const laneLaw = (schema, o) =>
    (o.fix
        ? '<completion_bar>\nDone is every card in your named pool audited to full depth with its fix landed — proof-complete, ' +
          'never effort-spent, never early. Complete every named move before yielding; do not stop at analysis or a partial ' +
          'edit. If the chosen approach resists, pick the next-best one and proceed; a move the territory genuinely admits no ' +
          'edit for is recorded, never forced. Your layer is review-and-repair of the named card pool: a cross-folder finding ' +
          'is repaired at BOTH ends in the same pass per the RIPPLE law, never deferred, and re-verifying unchanged cards or ' +
          're-reading covered territory adds no evidence — move to the next card instead.\n</completion_bar>\n\n<verification>\n' +
          'After editing, re-read each changed file and confirm it is coherent and nothing it carried was lost. Fix what fails ' +
          'before yielding; a check you did not run is never claimed as run.\n</verification>'
        : '<context_gathering>\nTerritory: the exact files and directories the task names. Do not open files outside it, ' +
          'including skill or instruction files (.claude/, CLAUDE.md, AGENTS.md).\nBudget: at most ' +
          (o.calls || 60) +
          ' tool calls total. Read in small batches (a handful of files per command, line-capped); never concatenate the whole ' +
          'territory into one command - tool output truncates and the data is lost.\nStop as soon as the product is complete. ' +
          'If something is still uncertain at the budget, proceed and record the residue in coverage.unverified instead of ' +
          're-reading.\n</context_gathering>\n\n<verification>\nBefore the final message, confirm every cited spelling appears ' +
          'verbatim in the cited file; move anything unconfirmed into coverage.unverified, never assert it.\n</verification>') +
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
    const root = ROOT;
    const report = root + '/' + base + '-report.json';
    const lane = report + '.lane';
    const authored = !!o.writes;
    const sandbox = authored ? 'workspace-write' : 'read-only';
    const hl = o.hl || { arr: 'entries', group: 'kind' };
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
        root +
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
        '-report.json, entries = the length of the "' +
        hl.arr +
        '" array in the product, headline="<entries> ' +
        hl.arr +
        (hl.group ? ' | <' + hl.group + ' tallies>' : '') +
        '", and failure empty. On a failed receipt return ok=false, entries=0, report and headline empty, and failure equal to the ' +
        'receipt reason and failure text VERBATIM.\n\nLANE LAW:\n\n' +
        laneLaw(schema, o) +
        '\n\nTASK:\n\n' +
        taskFull
    );
};
// Every dispatched lane routes here: the config default unless o.model names a deviation. QUOTA FALLBACK: a
// receipt whose failure matches usage/quota/limit re-dispatches the SAME task natively at the role's native twin
// — the caller owns the re-dispatch, the wrapper never executes work itself. The roster row carries `scope` from the
// ORCHESTRATOR (never the lane's self-report) so a failed lane's unmapped territory is exact even when the lane died before writing anything.
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
const recon = (task, o) =>
    agent(codexPrompt(o.label, task, o.schema, o), {
        label: (o.model && o.model.indexOf('-terra') >= 0 ? 'terra:' : 'sol:') + o.label,
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
const surveyPrompt = (folder, slice) =>
    [
        LAW,
        '',
        LAWS,
        '',
        INFO_LAW,
        '',
        SELF_CHECK,
        '',
        'TASK: DISCOVERY SURVEY of ' +
            folder +
            ' — read-only is its ONLY concession; skimming, memory-recall ' +
            'inventories, and verdict-only output are process defects. FULL-FILE read every design page under ' +
            folder +
            '/.planning/**, ' +
            'ARCHITECTURE.md, README.md, and any existing ' +
            folder +
            '/IDEAS.md + TASKLOG.md; walk the folder at large and enumerate both .api tiers per ' +
            'the ULTRA-STACKING LAW; resolve scope against real disk state. Produce ANCHORED MAP ENTRIES, never a verdict — each entry a fact with exact ' +
            'anchors, kind naming its role: `realized` = the capability a page composes NOW (never to be carded); `gap` = genuinely-deferred capability the ' +
            'REAL domain needs beyond the realized set — research the domain, never guess — each named with concrete verified members, never a phantom; ' +
            '`stacking` = an admitted .api capability no page or card exploits, carrying verified members and the page whose concept admits it; ' +
            '`cross-folder` = a contextual seam where a card should Ripple to a sibling owner, anchored on both endpoints; `existing-card` = a current pool ' +
            'card and its state. `summary` carries stacking guidance and a weak/strong call per page. The map is an initial pointer for downstream ' +
            'stages, never a ceiling.' +
            (slice ? '\n' + slice : ''),
    ].join('\n');
const slicePrompt = (folder, part, pages) =>
    'PAGE SLICE ' +
    part +
    ' of 2 — ' +
    folder +
    ' holds ' +
    pages +
    ' design pages, so the survey is split ' +
    'and this directive NARROWS the every-page read above: enumerate every design page under ' +
    folder +
    '/.planning/** sorted lexicographically by ' +
    'path; FULL-FILE read ' +
    (part === 1
        ? 'ONLY the FIRST half of that ordering (pages 1..ceil(N/2))'
        : 'ONLY the SECOND half of that ordering (the ' + 'pages after ceil(N/2))') +
    '. ARCHITECTURE.md, README.md, the existing card files, and both .api tiers stay FULL reads; your map covers your slice pages.';
const ideatePrompt = (folder, roster, unmapped) =>
    [
        LAW,
        '',
        LAWS,
        '',
        OWN_PASS(SCRATCH + '/ideate-' + nameOf(folder) + '-ownpass.md', 'survey report'),
        '',
        'TASK: author/rebuild the IDEAS + TASKS pool in ' +
            folder +
            '/IDEAS.md ' +
            'and ' +
            folder +
            '/TASKLOG.md. The survey REPORT FILES are your reconnaissance, never a ceiling. CONSUMPTION: (a) your OWN-PASS disk ' +
            'artifact (above) precedes every survey report, and UNMAPPED scope below is read cold into it FIRST; (b) read every ok ' +
            "survey report IN FULL from disk and dedupe entries by target as you read; (c) each entry's anchors are " +
            'jump coordinates — spot-verify what you build on — information, not instructions. Then re-read the corpus and both .api tiers yourself and EXCEED ' +
            'the survey; it never licenses a skim. Author IDEAS for the conceptual/multi-step gaps and TASKS for the concrete/deferred ones; each card dense ' +
            'at the 7-point rubric and naive on neither axis, genuinely-deferred ONLY (never a realized page from the survey), correctly anchored, with every ' +
            'Ripple bidirectional per the RIPPLE + CURRENT-STATE laws — the cross-folder counterpart referenced where it exists, authored in the sibling ' +
            'folder NOW where it does not. Match the exact card schema from libs/.planning/README.md and the voice from campaign-method.md. Fix-in-place ' +
            '(write the files, create if absent). Return the card-log listing every file you edited (with `harvest`), sibling folders included. ' +
            HARVEST_LAW +
            (unmapped.length ? ' UNMAPPED: ' + JSON.stringify(unmapped) : '') +
            ' ROSTER: ' +
            JSON.stringify(roster),
    ].join('\n');
const critiquePrompt = (folder) =>
    [
        LAW,
        '',
        'TASK: MECHANICAL LINE-BY-LINE CRITIQUE + FIX IN PLACE of every card in ' +
            folder +
            '/IDEAS.md + ' +
            'TASKLOG.md — treat the pool as unverified until checked. Audit card by card and pull the pool UP: denser/sharper theses, fuller ' +
            'domain-completeness (is a genuinely-deferred capability still missing?), better anchors, richer and correct Ripple refs, polymorphic/AOP ' +
            'framing in Capability/Shape. Address both naivety axes: widen COVERAGE thin-slices to the full concept; rewrite APPROACH roster-cards so the ' +
            'roster is seed data feeding one parameterized generator. Check every member a card cites against both .api tiers — correct or delete ' +
            'phantoms; card any admitted capability the pool ignores. These checks are a floor — hunt past them. A cross-folder Ripple asymmetry is ' +
            'repaired at BOTH ends NOW per the RIPPLE + CURRENT-STATE laws. EDIT the card files. Return the card-log listing every file you edited ' +
            '(with `harvest`), sibling folders included. ' +
            HARVEST_LAW,
    ].join('\n');
const redteamPrompt = (folder, critOk, critReport) =>
    [
        LAW,
        '',
        (critOk
            ? 'PRIOR CLAIMS (UNVERIFIED): the critique cardlog is ON DISK at ' + critReport
            : 'PRIOR CLAIMS (UNVERIFIED): the critique wrapper died, but the lane writes its cardlog before any ceiling can ' +
              'kill the call — check ' +
              critReport +
              ' FIRST; absent or unparseable, your cold attack is the only review this pool gets, judged from CURRENT disk alone. ' +
              'Present') +
            ' — read it IN FULL from disk; its edits and verdicts are refutation targets you judge against CURRENT disk, never a ' +
            "settled record. FOLD-FORWARD is OPERATIONAL ONLY: union the critique cardlog's `files` and `beyondFolder` (each " +
            "re-verified on disk) into your own return so it is the folder's CONSOLIDATED edit record. Its `harvest` is NOT " +
            "yours to carry — the doctrine lander reads every critique cardlog's nominations directly from its deterministic " +
            'disk path, so a live fold is never their transport; your `harvest` holds ONLY nominations your own pass mints.\n',
        OWN_PASS(SCRATCH + '/redteam-' + nameOf(folder) + '-ownpass.md', 'PRIOR CLAIMS cardlog'),
        '',
        'TASK: ADVERSARIAL RED-TEAM + FIX IN PLACE of the cards in ' +
            folder +
            '/IDEAS.md + TASKLOG.md — ' +
            'the terminal and most aggressive review. Your own-pass attack artifact (OWN PASS FIRST above) precedes the PRIOR ' +
            'CLAIMS. You are a HOSTILE reviewer whose goal is to REJECT this pool — assume it is redundant, under-dense, ' +
            'naive, or under-ideated until it proves otherwise; dense confident-looking cards are the prime suspects for hollowness. ATTACK and repair: ' +
            'any card that duplicates a realized design page (mis-carded in-pass work — delete/disposition); any ' +
            'test/meta/decision/unblock/create-file card; dangling/asymmetric/colliding Ripple — repaired at BOTH ends NOW per the RIPPLE + CURRENT-STATE ' +
            'laws, counterpart authored where absent; weak/under-dense cards failing the 7-point rubric; cards naive on either NAIVETY-LAW axis; cited ' +
            'members no .api catalogue or page verifies (phantoms — correct or delete); non-deferred work wrongly carded. This attack list is a FLOOR — ' +
            'hunt defects beyond it. ALSO the FORWARD lens: genuinely-deferred domain capability MISSING from the pool (under-ideation), admitted .api ' +
            "capability no card exploits, a pool that understates the real domain — author what is missing. Run a COUNTERFACTUAL on the pool's central " +
            'framing — a counterfactual REBUILDS the set with its central assumption removed, never merely questions it: name the assumption the pool ' +
            'stands on (the chosen carving of the deferred space, the enumerated card roster, the granularity of each bet), derive the stronger set ' +
            'WITHOUT it — a denser card absorbing several, a parameterized capability where a roster of cards enumerates, a higher-leverage bet the ' +
            'framing hid — and where the rebuilt set is stronger, BUILD IT IN PLACE; "the current pool also works" is not a refutation. Then END with a ' +
            'full cold re-review of both files as one body — verdict=clean only when that cold attack finds nothing. Repair every defect in place, ' +
            'wherever it lives. Return the card-log listing every file you edited (with `harvest`), sibling folders included. ' +
            HARVEST_LAW,
    ].join('\n');
const doctrinePrompt = (rows, orphans) =>
    ROOT_LAW +
    '\n\nTASK: DOCTRINE LANDER — the durable-learning terminal of this run. Read `docs/laws/README.md` FIRST — it ' +
    'owns the corpus admission and page-shape law; obey it over any restatement. Load the `docgen` skill via ' +
    'the Skill tool BEFORE any durable edit; ' +
    'load `mermaid-diagramming` before touching any diagram. ' +
    "NOMINATIONS (unverified, biased toward their authors' own work — refute by default): " +
    JSON.stringify(rows) +
    '\nAlso read the `harvest` array of every critique cardlog at these deterministic paths (an absent or invalid file ' +
    'skips; no other agent transports these rows — a live fold never carries them): ' +
    JSON.stringify(orphans) +
    ' — dedupe them against NOMINATIONS and adjudicate them identically.' +
    '\nADJUDICATE each row per the admission bar: cold-read its target surface IN FULL, verify its anchors on CURRENT disk; LAND NOTHING is a ' +
    'first-class verdict.\nTOPOLOGY RE-PROOF: re-verify every `docs/laws/topology.md` row whose [SURFACE] this run touched — cull a row whose ' +
    'coupling no longer holds, land a coupling this run proved.\nGATE: run `uv run .claude/skills/docgen/scripts/prose_gate.py <every touched ' +
    '.md>` and repair to zero FAILs before returning. Return landed/refined/rejected (each rejection with its reason)/files/summary.';

const ideateFolder = async (u) => {
    const folder = u.folder;
    const surveyors =
        (u.pages || 0) > SURVEY_PAGE_CAP
            ? [1, 2].map((part) =>
                  slot(() =>
                      recon(surveyPrompt(folder, slicePrompt(folder, part, u.pages)), {
                          label: 'survey:' + nameOf(folder) + '#' + part,
                          phase: 'Survey',
                          schema: SURVEY_SCHEMA,
                          model: 'gpt-5.6-terra',
                          scope: [folder + ' (slice ' + part + '/2)'],
                      }),
                  ),
              )
            : [
                  slot(() =>
                      recon(surveyPrompt(folder, ''), {
                          label: 'survey:' + nameOf(folder),
                          phase: 'Survey',
                          schema: SURVEY_SCHEMA,
                          model: 'gpt-5.6-terra',
                          scope: [folder],
                      }),
                  ),
              ];
    const roster = (await Promise.all(surveyors)).filter(Boolean);
    const mapped = roster.filter((r) => r.ok);
    const total = mapped.reduce((a, r) => a + r.entries, 0);
    const unmapped = roster.filter((r) => !r.ok).flatMap((r) => r.scope.map((sc) => ({ lane: r.lane, scope: sc })));
    log(
        nameOf(folder) +
            ': ' +
            total +
            ' survey entries across ' +
            mapped.length +
            '/' +
            roster.length +
            ' lane(s)' +
            (mapped.length < roster.length
                ? ' — FAILED: ' +
                  roster
                      .filter((r) => !r.ok)
                      .map((r) => r.lane)
                      .join(', ')
                : ''),
    );
    // CHAIN CONTINUATION: the ideate writer is critical (primary authoring) — it earns retryLane, but its death isolates the
    // lane, NEVER the chain: the critique (a writer) and the redteam still audit and extend the pool as it stands on disk,
    // and the ideate log simply arrives absent.
    const ideateOpts = (suffix) => ({
        label: 'ideate:' + nameOf(folder) + suffix,
        phase: 'Ideate',
        model: 'fable',
        schema: CARDLOG_SCHEMA,
        effort: 'high',
    });
    const authored =
        (await slot(() => agent(ideatePrompt(folder, roster, unmapped), ideateOpts('')))) ||
        (await retryLane(() => slot(() => agent(ideatePrompt(folder, roster, unmapped), ideateOpts(':a1')))));
    // Critique: a dispatched lane fixing the pool in place; cardlog to disk, receipt on the wire; the redteam
    // folds its verified operational rows and the doctrine lander reads its nominations directly from the deterministic path.
    const crit = await slot(() =>
        recon(critiquePrompt(folder), {
            label: 'crit:' + nameOf(folder),
            phase: 'Critique',
            schema: CARDLOG_SCHEMA,
            writes: true,
            fix: true,
            nativeModel: 'fable',
            scope: [folder],
            hl: { arr: 'files', group: '' },
        }),
    );
    // Deterministic critique-report path from the folder alone — set even when the critique wrapper dies, so the redteam, the
    // terminal drain, and the doctrine lander reach a written cardlog off the path, never a receipt a dead wrapper never returned.
    const critReport = SCRATCH + '/' + fileTag('crit:' + nameOf(folder)) + '-report.json';
    // The redteam is the terminal review and sole card-status owner — critical, so it too earns retryLane.
    const rtOpts = (suffix) => ({
        label: 'redteam:' + nameOf(folder) + suffix,
        phase: 'Redteam',
        model: 'fable',
        schema: CARDLOG_SCHEMA,
        effort: 'high',
    });
    const rt =
        (await slot(() => agent(redteamPrompt(folder, !!(crit && crit.ok), critReport), rtOpts('')))) ||
        (await retryLane(() => slot(() => agent(redteamPrompt(folder, !!(crit && crit.ok), critReport), rtOpts(':a1')))));
    return { folder, logs: { ideate: authored, redteam: rt }, critReport, ok: !!(authored || rt) };
};

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('Survey');
const inv = await agent(
    'DISCOVERY: list the package/area folders under ' +
        SWEEP +
        ' that own a design corpus (immediate child directories containing a ' +
        '.planning directory and/or a README.md + ARCHITECTURE.md). Include the branch-level tier if it owns cards. The listing MUST be a live find/ls ' +
        'run against the working tree — never memory, a prior run, or an index — with the scope path first proven to exist on disk. Completeness is the ' +
        'product: a folder you miss silently escapes the whole pass; widen the search on any doubt and verify every returned path exists. For each ' +
        'folder also COUNT its design pages (markdown files under <folder>/.planning/**; 0 when no .planning tree exists) and return the count as ' +
        'pages. Return folders sorted by path. Read-only; do not cd.',
    { label: 'discover', phase: 'Survey', schema: DISCOVERY_SCHEMA, model: 'sonnet', effort: 'low' },
);
// Validate the discovery agent's emitted folder roster against the requested scope before any chain dispatches on it: a
// hallucinated or out-of-scope path would otherwise spawn a full ideate chain writing card files outside the territory.
const SWEEP_N = SWEEP.replace(/\/+$/, '');
const underScope = (f) => /^libs(\/|$)/.test(f) && (SWEEP_N === 'libs' || f === SWEEP_N || f.indexOf(SWEEP_N + '/') === 0);
const emitted = ((inv && inv.folders) || []).filter((u) => u && u.folder);
const FOLDERS = emitted.filter((u) => underScope(u.folder));
const OFF_SCOPE = emitted.filter((u) => !underScope(u.folder)).map((u) => u.folder);
if (OFF_SCOPE.length) log('Ideate: dropped ' + OFF_SCOPE.length + ' off-scope discovery folder(s): ' + OFF_SCOPE.join(', '));
log('Ideate discover under ' + SWEEP + ': ' + FOLDERS.length + ' folders');

const done = (await Promise.all(FOLDERS.map((u) => ideateFolder(u)))).filter(Boolean);
const complete = done.filter((r) => r.ok);
const failed = done.filter((r) => !r.ok).map((r) => r.folder);
// TERMINAL DRAIN: sweep EVERY critique cardlog, keyed on its DETERMINISTIC path, never the receipt — a dead wrapper
// does not erase a written cardlog, a live redteam's fold is judgment-lossy anyway, and rows already folded re-verify and
// disk-dedupe in the sweep. No round-based DRAIN LOOP: Ripples land BOTH ends in-pass by the RIPPLE law and CARDLOG
// carries no {files, claim} backlog, so nothing pools across stages — the single fold-forward drain is the whole terminal.
const ORPHANS = done.filter((r) => r.critReport).map((r) => r.critReport);
// The terminal drain gets retryLane and stays OPERATIONAL: it consolidates the critique cardlogs' `files`/`beyondFolder`
// (a redteam that died left its critique cardlog unfolded), never their `harvest` — the doctrine lander is the sole nomination
// transport, reading each critique cardlog from its deterministic path directly, so a dead drain never loses a nomination.
const fireDrain = (suffix) =>
    slot(() =>
        agent(
            ROOT_LAW +
                '\n\nTERMINAL DRAIN (operational consolidation): every critique cardlog on disk, keyed on its deterministic ' +
                'path — read each IN FULL (an absent or invalid file skips): ' +
                JSON.stringify(ORPHANS) +
                '. Re-verify its `files` and `beyondFolder` against the live card files and return the consolidated union — ' +
                'files, beyondFolder, verdict. The critique `harvest` is NOT folded here: the doctrine lander reads every ' +
                "critique cardlog's nominations directly from these same paths, so your `harvest` holds only nominations your " +
                'own consolidation pass mints (usually none).',
            { label: 'drain:orphans' + suffix, phase: 'Redteam', model: 'fable', effort: 'high', schema: CARDLOG_SCHEMA },
        ),
    );
const drained = ORPHANS.length ? (await fireDrain('')) || (await retryLane(() => fireDrain(':a1'))) : null;
const stages = ['ideate', 'redteam']; // the critique cardlog lives on disk; the redteam folds its rows into the folder record
const folded = drained ? [{ folder: 'orphans', logs: { redteam: drained }, ok: true }] : [];
const touched = [...new Set(complete.concat(folded).flatMap((r) => stages.flatMap((k) => (r.logs[k] && r.logs[k].files) || [])))];
const beyond = [...new Set(complete.concat(folded).flatMap((r) => stages.flatMap((k) => (r.logs[k] && r.logs[k].beyondFolder) || [])))];
const verdicts = {};
for (const r of done.concat(folded))
    for (const k of stages) {
        const v = r.logs[k] && r.logs[k].verdict;
        if (v) verdicts[v] = (verdicts[v] || 0) + 1;
    }
log(
    'Ideate: ' +
        complete.length +
        '/' +
        FOLDERS.length +
        ' folder pools closed; ' +
        touched.length +
        ' card files touched (' +
        beyond.length +
        ' via cross-folder Ripple authorship); verdicts ' +
        JSON.stringify(verdicts) +
        (failed.length ? ' — FAILED (reported, run continues): ' + failed.join(', ') : ''),
);
// DOCTRINE LANDER: the run's durable-learning terminal — pooled harvest nominations from every landed cardlog
// adjudicated against the live docs/laws surfaces; refutation-first, land-nothing legal. Fires only when non-empty.
const HARVEST_ROWS = complete.concat(folded).flatMap((r) => stages.flatMap((k) => (r.logs[k] && r.logs[k].harvest) || []));
// The doctrine lander is the ONLY transport for the critique cardlogs' nominations — it reads each from its deterministic
// path directly, so it fires whenever a critique cardlog exists (ORPHANS), even with no wire nominations and a dead drain.
const doctrine =
    HARVEST_ROWS.length || ORPHANS.length
        ? await agent(doctrinePrompt(HARVEST_ROWS, ORPHANS), {
              label: 'doctrine',
              phase: 'Redteam',
              model: 'fable',
              effort: 'high',
              schema: DOCTRINE_SCHEMA,
          })
        : null;
return {
    scope: SWEEP,
    folders: FOLDERS.length,
    complete: complete.map((r) => r.folder),
    failed,
    orphansDrained: ORPHANS.length,
    filesTouched: touched.length,
    beyondFolder: beyond,
    verdicts,
    doctrine: doctrine && {
        nominated: HARVEST_ROWS.length,
        landed: (doctrine.landed || []).length,
        refined: (doctrine.refined || []).length,
        rejected: (doctrine.rejected || []).length,
        files: doctrine.files || [],
        summary: doctrine.summary,
    },
};
