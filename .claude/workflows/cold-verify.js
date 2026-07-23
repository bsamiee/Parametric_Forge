export const meta = {
    name: 'cold-verify',
    whenToUse:
        'Campaign closure gate: after a rebuild campaign lands, verify the whole target corpus against its root DECISION/brief and fix every miss in place. args = {doc, root} or an array of such pairs; campaigns verify in parallel lanes. The resolver finalizes each campaign in-run — findings resolve as edits, never as a report; a doctrine lander closes the run only when a pass pools a durable nomination.',
    description:
        'Cold-verify pass over one or more landed campaigns. Per campaign: one plan lane partitions the target folder into balanced verification slices; verifiers fan out as dispatched lanes, each reading the root doc and its slice pages IN FULL, hunting missing/wrong/faked/naive work with typed anchored findings (one verifier owns the governance lane: index docs, manifest rows, csproj/README registries, .api anchors, acceptance traces, rider receipts; a per-language-branch verifier owns the cross-libs ripple lane: every sibling seam ledger, consumer anchor, counterpart obligation, and frozen wire name the campaign touches outside the target root). Every verifier runs a mandatory second-pass self-verify: each finding adversarially re-derived from disk before return, vague or unconfirmed findings deleted, and a clean verdict asserted only after the second hostile pass returns empty. ONE terminal resolver then finalizes the campaign with LIBS-WIDE ripple authority — verifier findings are SIGNALS, not law: it re-verifies each on disk, implements the strongest fix where a suggestion was weak or short-sighted, hunts and fixes what the verifiers missed on its own authority, resolves every ripple its edits expose anywhere under libs/ (sibling counterparts repaired in place both ends, except where the doc rules a counterpart recorded-only), and pushes touched pages past the ruling per the floor law. The resolver is retry-guarded and appends each harvest nomination to a deterministic .jsonl as it is minted; when any campaign pools a non-empty nomination OR its resolver dies, ONE terminal doctrine lander adjudicates against docs/laws (refutation-first, land-nothing legal), sweeping the disk harvest files so a dead finalize loses none. Otherwise no phase follows the resolver.',
    phases: [
        { title: 'Plan', detail: 'per campaign: enumerate pages, partition into balanced slices', model: 'sonnet' },
        {
            title: 'Verify',
            detail: 'per campaign: slice verifiers + one governance verifier + per-branch cross-libs ripple verifiers as dispatched lanes, read-only, self-verified typed anchored findings',
            model: 'sonnet',
        },
        {
            title: 'Resolve',
            detail: 'per campaign: one terminal finalizer — findings as signals, own hunt beyond them, every ripple resolved in-run, libs-wide',
            model: 'fable',
        },
        {
            title: 'Doctrine',
            detail: 'terminal doctrine lander fires on pooled harvest or a dead resolver: sweeps each resolver harvest .jsonl from disk, adjudicates nominations against docs/laws, refutation-first, land-nothing legal',
            model: 'fable',
        },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const SLICES = 4;
const ROOT = '/Users/bardiasamiee/Documents/99.Github/Rasm'; // repo checkout root — native lanes resolve relative paths against it, never the launching session cwd
const RETRY_ATTEMPTS = 2;

// --- [INPUTS] --------------------------------------------------------------------------

const argsIn = typeof args === 'string' && /^\s*[\[{]/.test(args) ? JSON.parse(args) : args;
const CAMPS = (Array.isArray(argsIn) ? argsIn : [argsIn]).filter((c) => c && c.doc && c.root);
if (!CAMPS.length) {
    log('No campaigns — pass {doc, root} or an array of pairs.');
    return { campaigns: 0 };
}
// Per-instance scratch dir holding lane report files, minted deterministically from the normalized campaign set (a clock or
// randomness would break resume): one FLAT dir per instance, a root-basename slug and an FNV-1a tail so distinct sets never collide.
const fnv1a = (s) => {
    let h = 0x811c9dc5;
    for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193);
    return (h >>> 0).toString(16).padStart(8, '0').slice(0, 6);
};
const SCRATCH =
    '.claude/scratch/' +
    ('cold-verify-' + CAMPS.map((c) => c.root.split('/').pop().toLowerCase()).join('-')).replace(/[^a-z0-9.-]+/g, '-').slice(0, 60) +
    '-' +
    fnv1a(JSON.stringify(CAMPS));

// --- [MODELS] --------------------------------------------------------------------------

const PLAN = {
    type: 'object',
    additionalProperties: false,
    required: ['slices', 'governance'],
    properties: {
        slices: { type: 'array', items: { type: 'array', items: { type: 'string' } } },
        governance: { type: 'array', items: { type: 'string' } },
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
        role: { type: 'string', enum: ['defect', 'ruling', 'catalog', 'counterpart', 'absence'] },
        note: { type: 'string' },
    },
};

const FINDINGS = {
    type: 'object',
    additionalProperties: false,
    required: ['findings', 'coverage', 'summary'],
    properties: {
        findings: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['claimKey', 'target', 'files', 'class', 'severity', 'claim', 'anchors', 'mechanism', 'owner', 'reject', 'acceptance'],
                properties: {
                    claimKey: { type: 'string' }, // <class>|<owner>|<primary symbol or absence route> — stable across lanes, never lane wording
                    target: { type: 'string' }, // short display label for the defect
                    files: { type: 'array', items: { type: 'string' } }, // files the resolver must open or edit first
                    class: { type: 'string', enum: ['missing', 'wrong', 'faked', 'naive', 'drift', 'phantom'] },
                    severity: { type: 'string', enum: ['blocker', 'major', 'minor'] }, // bound to consequence: closure-blocking | campaign-correctness | local cleanup
                    claim: { type: 'string' }, // the observed defect as fact
                    anchors: { type: 'array', items: ANCHOR },
                    mechanism: { type: 'string' }, // WHY the current form fails the ruling/doctrine — factual, zero repair verbs
                    owner: { type: 'string' }, // canonical owner that must absorb the resolution
                    reject: { type: 'array', items: { type: 'string' } }, // forms the repair must NOT take (deleted forms)
                    acceptance: { type: 'array', items: { type: 'string' } },
                },
            },
        }, // signals proving resolution
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

// Thin wire receipt: the lane's PRODUCT stays on disk at `report`; only status + counts travel inline.
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

// Required-but-possibly-empty `beyond` is an attestation: the resolver's own hunt ran, not only the signal list.
const FIXLOG = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'resolved', 'beyond', 'rejected', 'harvest', 'summary'],
    properties: {
        files: { type: 'array', items: { type: 'string' } },
        resolved: {
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
        rejected: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['finding', 'reason'],
                properties: {
                    finding: { type: 'string' },
                    reason: { type: 'string' },
                },
            },
        },
        harvest: HARVEST,
        summary: { type: 'string' },
    },
};

// --- [SHARED_BLOCKS]

// Every relative repo path resolves against ONE absolute root — native terminal lanes (resolver, doctrine) do not reliably
// inherit the launching session cwd, so the pin travels in every prompt; codex lanes additionally pin it as cwd.
const ROOT_LAW =
    'WORKING ROOT: ' +
    ROOT +
    ' — every relative repo path in this brief resolves against this absolute root; read, write, and edit ONLY under it, never another checkout of the repository.';

// reg selects the register by the EXECUTING model: 'codex' neutral for a codex verify lane, the default hostile
// estate register for a native-first lane (plan, resolver) it sharpens; only the stance clause forks.
const CTX = (c, reg) =>
    ROOT_LAW +
    '\n\nRasm monorepo, planning phase. The campaign over ' +
    c.root +
    ' is LANDED; ' +
    c.doc +
    ' at the repo ' +
    'root is the binding ruling it executed. ' +
    (reg === 'codex'
        ? 'This pass earns the cold close by verifying the corpus against that ruling before accepting any claim it makes about itself. '
        : 'This pass earns the cold close: the corpus is presumed defective until an attack finds nothing. ') +
    'All .md prose follows docs/standards/style-guide.md — declarative agent-facing law, no ' +
    'provenance, no process narration, no hedges. Never run git commit.';

const HUNT =
    'HUNT CLASSES: missing (a ruled motion, page, owner, case, band, seam row, or rider with no landed ' +
    'counterpart), wrong (landed but contradicting the ruling or the doctrine), faked (claimed done — prose asserts what ' +
    'the fence body omits, a receipt without the edit, a re-anchor to a dead target), naive (landed thin — a slice of the ' +
    'ruled capability, an underutilized admitted package, a ceiling-read of a floor ruling), drift (two landed surfaces ' +
    'disagreeing — page vs index doc vs manifest vs .api), phantom (a cited member, page, or anchor that does not exist). ' +
    'Verify cited external members against the .api catalogs; never trust page prose about itself.';

const EVIDENCE_LAW =
    'FINDING FORM — you deliver TRUTH, never an implementation: `claim` states the observed defect; ' +
    '`mechanism` states WHY it fails the ruling or doctrine as fact; `anchors` carry one coordinate per row (role names ' +
    'what the coordinate proves; `note` is the shortest literal witness — a symbol, member spelling, or fragment under ' +
    '20 words — or empty when path+line suffice; an `absence` anchor names where the expected thing was searched and not ' +
    'found); `owner` names the canonical owner that must absorb the resolution (the owning axis, row roster, registry, or ' +
    'seam vocabulary — never a new local shape); `reject` lists the deleted forms the repair must not take; `acceptance` ' +
    'lists the signals that prove resolution. NEVER write add/replace/implement/promote/delete as instruction — the ' +
    'executor owns the design; you own the constraint boundary. `claimKey` = <class>|<owner>|<primary symbol or absence ' +
    'route>, identical for the same defect regardless of lane or wording. `severity` binds to consequence: blocker = ' +
    'closure-blocking, major = campaign correctness, minor = local cleanup — never prose confidence. OUTPUT BOUNDS: an ' +
    'ordinary scope yields 3-8 retained findings; 0 only when the second hostile pass comes back empty, and then ' +
    '`summary` names the probes that produced nothing; never manufacture a finding to fill the range, never delete a ' +
    'confirmed one to stay inside it. COVERAGE is part of the product: `requested` = your assigned scope, `read` = what ' +
    'you actually full-read, `skipped`/`unverified` = what you did not reach or could not confirm — an honest skip beats ' +
    'a silent one.';

const SELF_CHECK =
    'MANDATORY SELF-VERIFY (second pass, before returning): re-derive your OWN findings — re-open every ' +
    'cited anchor and try to refute each finding from disk; a finding that fails re-confirmation is deleted, one that ' +
    'survives carries exact anchors and concrete evidence. A vague finding — no precise anchor, hedged appears/seems ' +
    'wording, a class without a demonstrated instance — is a defect. Then re-read your scope once more hunting what the ' +
    'first pass skimmed past; a clean verdict is asserted only after this second pass returns empty.';

const LAWS_READ =
    'LAWS — read `docs/laws/` before any durable edit (README + topology + patterns + scars; short registry pages): a ' +
    'topology row whose [SURFACE] your edits touch binds its obligated counterparts into the SAME pass, and every patterns row ' +
    'binds each branch it names.';

const HARVEST_LAW =
    'HARVEST (required key, usually empty): nominate ONLY findings that generalize beyond this campaign — a collapse pattern ' +
    'reusable across folders, a naivety class no doctrine clause names, a review rule that would have caught a defect BEFORE ' +
    'review, a cross-surface coupling discovered the hard way. Each row: altitude (stacks|reviewer|constitution|planning|readme|' +
    'laws), lang, claim (the generalized law, one sentence, SYMBOL-FREE — every concrete spelling lives in anchors, so the ' +
    'lander adjudicates the law without re-deriving its locality), anchors (file:line evidence), existingClause (the exact doctrine or ' +
    'reviewer clause it would harden, quoted with its path — or "absent" and the surfaces searched). A campaign-local fix never ' +
    'nominates; an empty array is the normal verdict — the terminal doctrine lander refutes weak rows, so nominate substance, never volume.';

// --- [OPERATIONS] ----------------------------------------------------------------------

// Bounded re-dispatch for a dead CRITICAL lane (usage-limit or transport death): attempt-counted with a retry before each;
// the final death isolates the lane, NEVER the chain — the doctrine lander still fires from the resolver's disk harvest file.
const retryLane = async (fn) => {
    for (let a = 0; a < RETRY_ATTEMPTS; a++) {
        const r = await fn();
        if (r) return r;
    }
    return null;
};

// Codex dispatch: the shell lane runs one blocking supervised CLI process and writes its content
// to the lane report, and returns mechanical orchestration data. Lane law rides developer-instructions
// (role split); the prompt carries only the task; the output contract sits LAST.
const fileTag = (label) => label.replace(/[^A-Za-z0-9_.-]+/g, '-');
const laneLaw = (schema, o) =>
    (o.fix
        ? '<persistence>\nComplete every named move before yielding; do not stop at analysis or a partial edit. If the chosen ' +
          'approach resists, pick the next-best one and proceed. Return without an applied edit only if the territory genuinely ' +
          'admits none.\n</persistence>\n\n<verification>\nAfter editing, re-read each changed file and confirm it is coherent ' +
          'and nothing it carried was lost. Fix what fails before yielding.\n</verification>'
        : '<context_gathering>\nTerritory: the exact files and directories the task names. Do not open files outside it, ' +
          'including skill or instruction files (.claude/, CLAUDE.md, AGENTS.md).\nBudget: at most ' +
          (o.calls || 60) +
          ' tool calls total. Read in small batches (a handful of files per command, line-capped); never concatenate the whole ' +
          'territory into one command - tool output truncates and the data is lost.\nStop as soon as the product is complete. ' +
          'If something is still uncertain at the budget, proceed and record the residue in coverage.unverified instead of ' +
          're-reading.\n</context_gathering>\n\n<verification>\nBefore the final message, confirm every cited spelling appears ' +
          'verbatim in the cited file; anything unconfirmed moves into coverage.unverified, never asserted.\n</verification>') +
    '\n\n<output_contract>\nYour final message is a single JSON object with exactly this shape: ' +
    JSON.stringify(schema) +
    '\n- JSON only: no prose before or after it, no code fences, no markdown.\n- Every key shown is required.\n' +
    '- Use null for a value you could not determine and [] for an empty list; never guess.\n</output_contract>';
// Sandbox decides authorship: verify lanes are read-only, so --out materializes the product; the delegate never writes the corpus.
const LANE_SCRIPT = ROOT + '/.claude/skills/codex/scripts/codex-lane.sh';
const flagsOf = (o) =>
    [o.model && '--model ' + o.model, o.codexEffort && '--effort ' + o.codexEffort, o.web && '--web']
        .filter(Boolean)
        .map((f) => ' ' + f)
        .join('');

const codexPrompt = (label, task, schema, o) => {
    const base = SCRATCH + '/' + fileTag(label);
    const report = ROOT + '/' + base + '-report.json';
    const model = o.model || 'gpt-5.6-terra';
    const lane = report + '.lane';
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
        ' --sandbox read-only' +
        flagsOf({ model, codexEffort: o.codexEffort, web: o.web }) +
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
        o.hl.arr +
        '" array in the product, headline="<entries> ' +
        o.hl.arr +
        (o.hl.group ? ' | <' + o.hl.group + ' tallies>' : '') +
        ' | top: <most frequent first file or none>", and failure empty. On a failed receipt return ok=false, entries=0, report and ' +
        'headline empty, and failure equal to the receipt reason and failure text VERBATIM.\n\nLANE LAW:\n\n' +
        laneLaw(schema, o) +
        '\n\nTASK:\n\n' +
        task
    );
};
// QUOTA FALLBACK: a codex receipt whose failure matches usage/quota/limit re-dispatches the SAME task natively at the role's
// native twin — the caller owns the re-dispatch, the shell lane never executes work itself. The roster row carries `scope` from the
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
        const plan = await agent(
            CTX(c) +
                '\n\nTASK: thin enumerate (read-only). List every design page under ' +
                c.root +
                '/.planning/ (real ls/find, never memory) and partition them into ' +
                SLICES +
                ' balanced slices grouped by ' +
                'sub-folder in dependency order. Return `governance` as the campaign governance surface: the package README.md and ' +
                'ARCHITECTURE.md, the .csproj or language manifest rows for this package, the .api folder path, and ' +
                c.doc +
                '.',
            { label: 'plan:' + tag, phase: 'Plan', model: 'sonnet', effort: 'low', schema: PLAN },
        );
        // Predicate-validate the model-emitted path rosters before dispatch: a slice page is a repo-relative .md under this
        // campaign's .planning/ root; governance entries (README/ARCHITECTURE, manifest rows, .api path, the doc) are non-empty strings.
        const planRoot = c.root + '/.planning/';
        const okPage = (p) => typeof p === 'string' && p.trim().startsWith(planRoot) && p.trim().endsWith('.md');
        const slices = ((plan && plan.slices) || [])
            .map((s) => (Array.isArray(s) ? s.map((p) => (typeof p === 'string' ? p.trim() : p)).filter(okPage) : []))
            .filter((s) => s.length);
        const gov = ((plan && plan.governance) || []).filter((g) => typeof g === 'string' && g.trim());
        const verifyTasks = slices.map(
            (pages, i) => () =>
                recon(
                    CTX(c, 'codex') +
                        '\n\n' +
                        HUNT +
                        '\n\n' +
                        EVIDENCE_LAW +
                        '\n\n' +
                        SELF_CHECK +
                        '\n\nTASK: READ-ONLY VERIFY, ' +
                        'slice ' +
                        i +
                        '. Read ' +
                        c.doc +
                        ' IN FULL — every ruling, page row, band, seam, rider, and acceptance trace that ' +
                        'touches your pages. Then read each of these pages IN FULL and every .api catalog its fences cite: ' +
                        JSON.stringify(pages) +
                        '. Verify each ruling landed PROPERLY — integrated as if always designed that way, at the ' +
                        'ruled band/signature/charter, frozen names byte-identical — and verify past the ruling: the floor law means a ' +
                        'page that merely met its disposition without depth is a naive finding. Return typed anchored findings.',
                    { label: 'verify:' + tag + ':s' + i, phase: 'Verify', schema: FINDINGS, scope: pages, hl: { arr: 'findings', group: 'class' } },
                ),
        );
        verifyTasks.push(() =>
            recon(
                CTX(c, 'codex') +
                    '\n\n' +
                    HUNT +
                    '\n\n' +
                    EVIDENCE_LAW +
                    '\n\n' +
                    SELF_CHECK +
                    '\n\nTASK: READ-ONLY GOVERNANCE VERIFY. Read ' +
                    c.doc +
                    ' IN FULL, then audit the governance surface end to end: ' +
                    JSON.stringify(gov) +
                    '. Every acceptance trace ' +
                    'resolves on disk (page exists, entry carries the ruled signature, seam anchor present); every rider has its landed ' +
                    'receipt; the README router/package groups, ARCHITECTURE codemap + seams ledger (canonical [KIND] tags, mirrored ' +
                    'endpoints), central manifest rows, and .api anchors agree with the landed page set — a disagreement between any ' +
                    'two surfaces is a drift finding. Return typed anchored findings.',
                { label: 'verify:' + tag + ':gov', phase: 'Verify', schema: FINDINGS, scope: gov, hl: { arr: 'findings', group: 'class' } },
            ),
        );
        const BRANCHES = ['libs/csharp', 'libs/python', 'libs/typescript'];
        BRANCHES.forEach((branch) =>
            verifyTasks.push(() =>
                recon(
                    CTX(c, 'codex') +
                        '\n\n' +
                        HUNT +
                        '\n\n' +
                        EVIDENCE_LAW +
                        '\n\n' +
                        SELF_CHECK +
                        '\n\nTASK: ' +
                        'READ-ONLY CROSS-LIBS RIPPLE VERIFY over ' +
                        branch +
                        ' (its branch .planning core, its .api tier, and ' +
                        'every package folder inside it EXCEPT ' +
                        c.root +
                        '). Read ' +
                        c.doc +
                        ' IN FULL, then hunt every cross-folder ' +
                        'touchpoint the campaign touches inside your scope (real grep/listing, never memory): sibling ARCHITECTURE seam ' +
                        'ledgers naming this package (mirrored glyphs and [KIND] tags, anchors into pages the campaign split, renamed, ' +
                        're-pointed, or deleted), consumer pages citing target anchors, every counterpart obligation or authorized 1-hop ' +
                        'edit the doc records (each landed at its named home exactly as sealed, or recorded where the doc rules ' +
                        'recorded-only), shared manifest rows and .api tiers, frozen wire names held byte-identical on both ends. A stale ' +
                        'sibling anchor, a one-sided seam edit, a missing authorized edit, an unrecorded counterpart, or a sibling ' +
                        'interior edited past the doc ruling is a finding. Zero touchpoints in your scope is a valid empty result. ' +
                        'Return typed anchored findings.',
                    {
                        label: 'verify:' + tag + ':ripple:' + branch.split('/').pop(),
                        phase: 'Verify',
                        schema: FINDINGS,
                        scope: [branch],
                        hl: { arr: 'findings', group: 'class' },
                        calls: 90,
                    },
                ),
            ),
        );
        const roster = (await parallel(verifyTasks)).filter(Boolean);
        const verified = roster.filter((r) => r.ok);
        const total = verified.reduce((a, r) => a + r.entries, 0);
        const unmapped = roster.filter((r) => !r.ok).flatMap((r) => r.scope.map((s) => ({ lane: r.lane, scope: s })));
        log(
            tag +
                ': ' +
                total +
                ' finding(s) across ' +
                verified.length +
                '/' +
                roster.length +
                ' lanes' +
                (verified.length < roster.length
                    ? ' — FAILED: ' +
                      roster
                          .filter((r) => !r.ok)
                          .map((r) => r.lane)
                          .join(', ')
                    : ''),
        );
        const harvestFile = SCRATCH + '/' + fileTag('resolve:' + tag) + '-harvest.jsonl';
        const resolveTask =
            CTX(c) +
            '\n\n' +
            HUNT +
            '\n\n' +
            LAWS_READ +
            '\n\n' +
            HARVEST_LAW +
            '\n\nTASK: TERMINAL FINALIZE (WRITER — full authority over ' +
            c.root +
            ', its manifest rows, ' +
            c.doc +
            ' where a finding proves the doc itself wrong, AND libs-wide ripple authority: a ' +
            'ripple a fix exposes anywhere under libs/ — sibling seam ledgers, mirrored rows, consumer anchors, index docs, ' +
            '.api catalogs — is repaired in place at the sibling in the same pass, both ends; where the doc rules a ' +
            'counterpart RECORDED with a demanding consumer rather than edited, the recording IS the fix and the sibling ' +
            "interior stays unedited past that ruling. You are the run's LAST agent, no phase follows you). " +
            'CONSUMPTION PROTOCOL, in order: (a) read ' +
            c.doc +
            ' IN FULL — it is the ruling; (b) UNMAPPED scope below is ' +
            "your direct-hunt queue — a failed lane's territory gets your own cold read, first; (c) read every ok report " +
            'file IN FULL from disk, governance and ripple lanes before page slices — group findings by `claimKey` as you ' +
            'read (the same key across lanes is ONE defect with corroborating evidence, never several priorities) and order ' +
            'work by `severity` then `owner` (shared owners and registries before their consumers, cross-folder seams before ' +
            'local prose); (d) each finding is a SIGNAL: re-open its anchors before editing — anchors behind an edit, cited ' +
            'members, seams, and manifest rows re-verify MANDATORY; navigation-only entries in untouched groups re-verify ' +
            'only when touched (re-proving findings you will not act on is waste); (e) `mechanism`/`owner`/`reject`/' +
            "`acceptance` are the finding's constraint boundary — honor the owner and the rejected forms, but the DESIGN is " +
            'yours: implement the densest root-level resolution the boundary admits, never a single-point patch; a finding ' +
            'whose anchors do not re-confirm is rejected with reason. Then hunt PAST the signal list on your own authority — ' +
            'the hunt classes above over the corpus and governance surface as you work it — and fix what the verifiers ' +
            'missed; `beyond` enumerates those fixes, and an empty `beyond` attests your own hunt found nothing, never that ' +
            'it did not run. Every ripple an edit exposes is YOURS in the same pass, anywhere under libs/: seam counterparts ' +
            'both ends, consumer sites, index docs, manifest rows, .api anchors — the run ends finalized, nothing deferred. ' +
            'The floor law governs every page you touch: exceed the ruling with denser, deeper, more capable form. Frozen ' +
            'signatures and wire names stay byte-identical. ' +
            'HARVEST FILE: append each `harvest` nomination to `' +
            harvestFile +
            '` (one JSON row per line) the moment it is minted — the doctrine lander sweeps that file, so a dead finalize ' +
            'loses no nomination; your returned `harvest` carries the same rows. ' +
            'UNMAPPED: ' +
            JSON.stringify(unmapped) +
            ' ROSTER: ' +
            JSON.stringify(roster);
        // Terminal writer: a dead resolver retries with a suffixed label; a final death isolates the campaign, never the run —
        // its harvest survives on disk for the lander. Operational FIXLOG rows ride the wire only for the run summary.
        const fireResolve = (suffix) =>
            agent(resolveTask, {
                label: 'resolve:' + tag + suffix,
                phase: 'Resolve',
                model: 'fable',
                effort: 'high',
                schema: FIXLOG,
            });
        const fix = (await fireResolve('')) || (await retryLane(() => fireResolve(':r1')));
        return {
            campaign: c.root,
            lanes: roster.length,
            failedLanes: roster.filter((r) => !r.ok).map((r) => r.lane),
            findings: total,
            resolved: (fix && fix.resolved && fix.resolved.length) || 0,
            beyond: (fix && fix.beyond && fix.beyond.length) || 0,
            rejected: (fix && fix.rejected && fix.rejected.length) || 0,
            harvest: (fix && fix.harvest) || [],
            harvestFile,
            resolverDead: !fix,
            summary: (fix && fix.summary) || '',
        };
    }),
);

// DOCTRINE LANDER: the run's durable-learning terminal — pooled harvest nominations adjudicated against the live doctrine
// surfaces; refutation-first, land-nothing legal, admission law owned by docs/laws. Nomination transport never rides a living
// fold: the wire `harvest` is corroboration only, and the lander reads each resolver's deterministic harvest `.jsonl` from disk
// directly — a dead resolver still fires it (fire-gate below) and loses no row. Harvest paths mint from CAMPS, not lane returns,
// so a fully-dead campaign lane still contributes its file.
const LIVE = lanes.filter(Boolean);
const HARVEST_ROWS = LIVE.flatMap((l) => l.harvest || []);
const HARVEST_FILES = CAMPS.map((c) => SCRATCH + '/' + fileTag('resolve:' + c.root.split('/').pop()) + '-harvest.jsonl');
const RESOLVER_DIED = lanes.some((l) => !l || l.resolverDead);
const doctrine =
    HARVEST_ROWS.length || RESOLVER_DIED
        ? await agent(
              ROOT_LAW +
                  '\n\nTASK: DOCTRINE LANDER — the durable-learning terminal of this run. Read `docs/laws/README.md` ' +
                  'FIRST — it owns the corpus admission and page-shape law; obey it over any restatement. Load ' +
                  'the `docgen` skill via the Skill tool BEFORE any durable edit; load ' +
                  '`mermaid-diagramming` before touching any diagram. ' +
                  "NOMINATIONS (unverified, biased toward their authors' own work — refute by default): " +
                  JSON.stringify(HARVEST_ROWS) +
                  '\nAlso sweep each resolver harvest file at these deterministic paths (an absent or invalid file skips; a dead ' +
                  'finalize reaches you ONLY through these files, and no other agent transports these rows): ' +
                  JSON.stringify(HARVEST_FILES) +
                  ' — each line is one JSON nomination row; rows there missing from NOMINATIONS are nominations too. Dedupe ' +
                  'against NOMINATIONS and adjudicate them identically.\n' +
                  'ADJUDICATE each row per the admission bar: cold-read its target surface IN FULL, verify its anchors on ' +
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
