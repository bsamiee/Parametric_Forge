/**
 * codex-lane-batch — audit heavy scopes on codex through supervised lane-script
 * runs, batch the short probes into ONE wrapper, then read every report file.
 *
 * Demonstrates codex lane composition: each heavy scope gets one write-run-receipt
 * wrapper — the backgrounded codex-lane.sh run IS the wait, the harness re-invokes on
 * exit, no polling; lane law rides the --law file (role split) with a task-only --task
 * file; the short probes share a single wrapper making sequential lane runs and returning
 * one combined receipt (every wrapper costs a full context spin-up, so short legs batch);
 * a quota-dead lane re-dispatches natively at the role's native twin; the terminal reader
 * consumes every ok report IN FULL from disk while only thin receipts cross the wire, and
 * a failed lane's scope becomes its direct-hunt queue.
 *
 * Workflow({ name: 'codex-lane-batch',
 *            args: { scopes: ['libs/python/geometry', 'libs/python/compute'],
 *                    probes: ['pyproject.toml', 'libs/python/README.md'] } })
 */

export const meta = {
    name: 'codex-lane-batch',
    description: 'Audit each heavy scope on a codex lane, batch the short probes into one wrapper, consolidate from the report files',
    whenToUse: 'Transcript-heavy audit legs that should burn codex tokens, not session context',
    phases: [{ title: 'Audit', detail: 'one wrapper per heavy scope + one batched wrapper for the probes', model: 'sonnet' }, { title: 'Resolve' }],
};

// --- [INPUTS] --------------------------------------------------------------------------

// Structured args — heavy scopes fan one lane each; short probe files batch into one wrapper.
const scopes = Array.isArray(args?.scopes) && args.scopes.length ? args.scopes : ['libs/python/geometry', 'libs/python/compute'];
const probes = Array.isArray(args?.probes) && args.probes.length ? args.probes : ['pyproject.toml', 'libs/python/README.md'];
// Per-instance run scratch (lane report files; receipts carry the paths) — minted deterministically from the normalized args AFTER
// normalization, so concurrent and successive runs never share a directory and a resume rehydrates the same one; clock or randomness breaks resume.
const fnv1a = (s) => {
    let h = 0x811c9dc5;
    for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193);
    return (h >>> 0).toString(16).padStart(8, '0').slice(0, 6);
};
const SCRATCH =
    '.claude/scratch/' +
    ('codex-lane-batch-' + scopes.map((s) => s.split('/').pop().toLowerCase()).join('-')).replace(/[^a-z0-9.-]+/g, '-').slice(0, 60) +
    '-' +
    fnv1a(JSON.stringify([scopes, probes]));

// --- [MODELS] --------------------------------------------------------------------------

// Thin wire receipt — the lane's product stays on disk at `report`; STRICT: every property required.
const RECEIPT = {
    type: 'object',
    additionalProperties: false,
    required: ['ok', 'report', 'entries', 'headline', 'failure'],
    properties: {
        ok: { type: 'boolean' },
        report: { type: 'string' },
        entries: { type: 'integer' },
        headline: { type: 'string' },
        failure: { type: 'string' }, // the tool error text; empty on success
    },
};

const RESOLUTION = {
    type: 'object',
    additionalProperties: false,
    required: ['confirmed', 'rejected', 'summary'],
    properties: {
        confirmed: { type: 'array', items: { type: 'string' } },
        rejected: { type: 'array', items: { type: 'string' } }, // findings whose anchors failed re-verification, with reason
        summary: { type: 'string' },
    },
};

// --- [OPERATIONS] ----------------------------------------------------------------------

// Lane law rides developer-instructions (role split, contract LAST); the prompt carries only the task.
// The product shape is the contract's prose JSON — the wrapper's RECEIPT schema is the only validation
// boundary on this path; no schema files exist.
const LAW =
    '<context_gathering>\nTerritory: the exact files and directories the task names. Do not open files outside it, including ' +
    'skill or instruction files (.claude/, CLAUDE.md, AGENTS.md).\nBudget: at most 40 tool calls total. Read in small batches ' +
    '(a handful of files per command, line-capped); never concatenate the whole territory into one command - tool output ' +
    'truncates and the data is lost.\nStop as soon as the product is complete; residual uncertainty becomes a severity "minor" ' +
    'finding, never a re-read.\n</context_gathering>\n\n<verification>\nBefore the final message, confirm every cited file:line ' +
    'anchors a real coordinate; drop anything unconfirmed.\n</verification>\n\n<output_contract>\nYour final message is a ' +
    'single JSON object with exactly one key "findings": an array of {claim, file, line, severity: "blocker"|"major"|"minor"} ' +
    'rows.\n- JSON only: no prose before or after it, no code fences, no markdown.\n- Use null for a value you could not ' +
    'determine and [] for an empty list; never guess.\n</output_contract>';

const auditTask = (scope) =>
    'Audit ' + scope + ' for drifted docs, phantom members, and dead references. Read every file under it; verify each claim on disk.';

// One wrapper, one supervised lane run, --out materializes the product, thin receipt back — never
// re-judging the work. Effort inherits the operator default; no effort flag without a real deviation.
const lanePrompt = (label, task) => {
    const report = SCRATCH + '/' + label + '-report.json'; // repo-relative — resolved against the repo root by the wrapper's tools
    const laneDir = report + '.lane';
    return (
        'DISPATCH ROLE: codex performs the complete TASK below through one supervised lane run; never perform, edit, judge, or relay ' +
        'the work yourself. (1) Write the LANE LAW block below VERBATIM to ' +
        laneDir +
        '/law.md and the TASK block below VERBATIM to ' +
        laneDir +
        '/task.md, composing neither. (2) Run ONE Bash call with run_in_background true: ' +
        '.claude/skills/codex/scripts/codex-lane.sh --task ' +
        laneDir +
        '/task.md --law ' +
        laneDir +
        '/law.md --dir ' +
        laneDir +
        ' --cwd <the absolute repo root> --model gpt-5.6-terra --out ' +
        report +
        '; the harness re-invokes you when the lane exits — Read ' +
        laneDir +
        '/receipt.json then, never a polling loop. Recovery is ONCE-only: a receipt reason "crash" overwrites the task file with ' +
        '"continue and complete the lane, then land the receipt" and re-runs the same command plus --resume <the receipt thread_id>; ' +
        'any other failed receipt re-runs the same command untouched. (3) The lane lands the product at ' +
        report +
        ' via --out. (4) Verify with one Bash call: jq -e ".findings" ' +
        report +
        ' >/dev/null — probe the contract key, never bare parseability, which any wrong-shaped JSON passes; on a miss rewrite once from ' +
        'the last agent_message item text in ' +
        laneDir +
        '/events.jsonl (jq -rs, Write that) and re-probe, then return ok=false with the probe error after a second miss. ' +
        '(5) Return ok, report path, entries = the findings count parsed from the product, headline = per-severity tallies, failure empty — ' +
        'or ok=false with the receipt reason and failure text VERBATIM.\n\nLANE LAW:\n\n' +
        LAW +
        '\n\nTASK:\n\n' +
        task
    );
};

// The batched wrapper makes one lane run PER probe, sequentially, and returns ONE combined receipt —
// short legs never earn a wrapper each. The probe tier deviation (medium) is the one legal effort flag.
const batchPrompt = (label, files) => {
    const report = SCRATCH + '/' + label + '-report.json';
    const laneDir = report + '.lane';
    return (
        'DISPATCH ROLE: run ' +
        files.length +
        ' SEQUENTIAL supervised lane runs, one per probe file below. (1) Write the LANE LAW block below VERBATIM to ' +
        laneDir +
        '/law.md once, and per probe <i> (1-based) a task file at ' +
        laneDir +
        '/probe-<i>/task.md reading "Probe <file>: verify every path, version, and member it cites against disk." ' +
        '(2) Per probe run ONE Bash call with run_in_background true: .claude/skills/codex/scripts/codex-lane.sh --task ' +
        laneDir +
        '/probe-<i>/task.md --law ' +
        laneDir +
        '/law.md --dir ' +
        laneDir +
        '/probe-<i> --cwd <the absolute repo root> --model gpt-5.6-terra --effort medium --out ' +
        laneDir +
        '/probe-<i>/out.json; Read the receipt on re-invoke; a failed receipt re-runs that probe ONCE (reason "crash" adds ' +
        '--resume <the receipt thread_id>), then records it failed and continues. (3) Merge every findings array from the probe ' +
        'out.json files and Write the merged JSON to ' +
        report +
        ' (delete any leftover file first), then verify with one Bash call: jq -e ".findings" ' +
        report +
        ' >/dev/null — the contract key, never bare parseability; rewrite once on a miss. (4) Return ok = at least one ' +
        'probe succeeded and the probe passed, the report path, entries = merged findings count, headline = "<n> probes | <tallies>", ' +
        'failure = the failed probe names or empty.\n\nLANE LAW:\n\n' +
        LAW +
        '\n\nPROBES: ' +
        JSON.stringify(files)
    );
};

// Orchestrator-owned scope rides the receipt so a lane that dies before writing still names its territory.
// QUOTA FALLBACK: usage exhaustion fails the lane loudly; the CALLER re-dispatches the same task natively at
// the role's native twin — the wrapper never becomes the implicit executor. A backgrounded
// lane run is legal waiting.
const shape = (label, scope) => (r) => ({
    lane: label,
    scope,
    ok: !!(r && r.ok && r.report),
    report: (r && r.report) || '',
    entries: (r && r.entries) || 0,
    headline: (r && r.headline) || '',
    failure: (r && r.failure) || (r ? '' : 'lane died'),
});
// The native fallback writes its product to the SAME report path as the dispatched lane, so both tiers land on disk and the
// terminal reader's roster covers every lane. A fallback returning its product inline instead reaches no disk consumer at
// all — the reader glob skips it silently and reports over the subset, which reads as a clean partial rather than a gap.
const lane = (prompt, label, scope, nativeTask) =>
    agent(prompt, { label: 'terra:' + label, phase: 'Audit', model: 'sonnet', effort: 'low', schema: RECEIPT })
        .then((r) =>
            r && !r.ok && /usage|quota|limit/i.test(r.failure || '')
                ? agent(
                      nativeTask +
                          '\n\nPRODUCT TO DISK: write your COMPLETE findings JSON to ' +
                          SCRATCH +
                          '/' +
                          label +
                          '-report.json (Write tool, path resolved against the repo root), then return ONLY the thin receipt: ok, report ' +
                          'path, entries count, one-line headline, failure empty.',
                      { label, phase: 'Audit', model: 'opus', effort: 'high', schema: RECEIPT },
                  )
                : r,
        )
        .then(shape(label, scope));

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('Audit');
const roster = (
    await parallel([
        ...scopes.map((s, i) => () => lane(lanePrompt('scope-' + i, auditTask(s)), 'scope-' + i, [s])),
        () => lane(batchPrompt('probes', probes), 'probes', probes),
    ])
).filter(Boolean);

const unmapped = roster.filter((r) => !r.ok).flatMap((r) => r.scope.map((sc) => ({ lane: r.lane, scope: sc })));
log(
    roster.filter((r) => r.ok).reduce((a, r) => a + r.entries, 0) +
        ' findings across ' +
        roster.length +
        ' lane(s), ' +
        unmapped.length +
        ' unmapped',
);

// Terminal reader: cold-read the unmapped territory FIRST, then every ok report IN FULL from disk;
// every finding is a signal whose anchors re-verify before it is confirmed.
phase('Resolve');
const resolved = await agent(
    'Consolidate this audit. UNMAPPED scopes get your own cold read FIRST: ' +
        JSON.stringify(unmapped) +
        '. Then read every ok report file IN FULL from disk (they sit under a gitignored dir — use the exact paths, never search): ' +
        JSON.stringify(roster.filter((r) => r.ok).map((r) => r.report)) +
        '. Re-verify each finding at its anchor; confirm or reject with reason, and hunt past the signal list on your own authority.',
    { label: 'resolve', phase: 'Resolve', model: 'fable', effort: 'high', schema: RESOLUTION },
);

return { lanes: roster.length, unmapped: unmapped.length, confirmed: resolved?.confirmed?.length ?? 0, resolution: resolved };
