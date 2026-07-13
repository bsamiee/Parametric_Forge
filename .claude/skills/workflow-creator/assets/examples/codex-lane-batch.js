/**
 * codex-lane-batch — audit heavy scopes on codex (gpt-5.6-terra) through blocking MCP
 * wrapper lanes, batch the short probes into ONE wrapper, then read every report file.
 *
 * Demonstrates codex lane composition: each heavy scope gets one call-write-receipt
 * wrapper — the blocking `codex` MCP call IS the wait, no polling, no launch ceremony;
 * lane law rides developer-instructions (role split) with a task-only prompt; the short
 * probes share a single wrapper making sequential codex calls and returning one combined
 * receipt (every wrapper costs a full context spin-up, so short legs batch); a quota-dead
 * lane re-dispatches natively at the role's Claude twin; the terminal reader consumes
 * every ok report IN FULL from disk while only thin receipts cross the wire, and a
 * failed lane's scope becomes its direct-hunt queue.
 *
 * Workflow({ name: 'codex-lane-batch',
 *            args: { scopes: ['libs/python/geometry', 'libs/python/compute'],
 *                    probes: ['pyproject.toml', 'libs/python/README.md'] } })
 */

export const meta = {
    name: 'codex-lane-batch',
    description: 'Audit each heavy scope on a codex terra lane, batch the short probes into one wrapper, consolidate from the report files',
    whenToUse: 'Transcript-heavy audit legs that should burn codex tokens, not Claude context',
    phases: [
        { title: 'Audit', detail: 'one terra wrapper per heavy scope + one batched wrapper for the probes', model: 'sonnet' },
        { title: 'Resolve' },
    ],
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

// One wrapper, one blocking codex call, envelope CONTENT written unmodified, thin receipt back — never
// re-judging the work. Effort inherits the operator default; no config clause without a real deviation.
const lanePrompt = (label, task) =>
    'DISPATCH ROLE: gpt-5.6-terra performs the complete TASK below through one blocking codex MCP call; never perform, edit, judge, or relay ' +
    'the work yourself. (1) ToolSearch "select:mcp__codex__codex". (2) Call mcp__codex__codex ONCE with ' +
    'model="gpt-5.6-terra", sandbox="read-only", cwd set to the repo root, "developer-instructions" = the LANE LAW block below VERBATIM, ' +
    'prompt = the TASK block below VERBATIM. On a tool error retry the identical call ONCE. (3) The tool result is a JSON envelope ' +
    '{threadId, content}; Write the CONTENT text (never the envelope) unmodified to ' +
    SCRATCH +
    '/' +
    label +
    '-report.json (a repo-relative path — resolve it against the repo root for the Write tool; delete any leftover file there first). ' +
    '(4) Return ok, report path, entries = the findings count parsed from the content, headline = per-severity tallies, failure empty — ' +
    'or ok=false with the error text VERBATIM after a failed retry.\n\nLANE LAW:\n\n' +
    LAW +
    '\n\nTASK:\n\n' +
    task;

// The batched wrapper makes one codex call PER probe, sequentially, and returns ONE combined receipt —
// short legs never earn a wrapper each. The probe tier deviation (medium) is the one legal config clause.
const batchPrompt = (label, files) =>
    'DISPATCH ROLE: run ' +
    files.length +
    ' SEQUENTIAL blocking codex MCP calls, one per probe file below, each with model="gpt-5.6-terra", sandbox="read-only", cwd at the repo ' +
    'root, config={"model_reasoning_effort":"medium"}, "developer-instructions" = the LANE LAW block below VERBATIM, and prompt = ' +
    '"Probe <file>: verify every path, version, and member it cites against disk." ' +
    '(1) ToolSearch "select:mcp__codex__codex" once. (2) Call per probe; on a tool error retry that probe ONCE, then record it failed and ' +
    'continue. Each tool result is a JSON envelope {threadId, content}; content holds the probe findings JSON. (3) Merge every findings ' +
    'array from the CONTENT texts and Write the merged JSON to ' +
    SCRATCH +
    '/' +
    label +
    '-report.json (repo-relative — resolve against the repo root; delete any leftover file first). (4) Return ok = at least one ' +
    'probe succeeded, the report path, entries = merged findings count, headline = "<n> probes | <tallies>", failure = the failed probe ' +
    'names or empty.\n\nLANE LAW:\n\n' +
    LAW +
    '\n\nPROBES: ' +
    JSON.stringify(files);

// Orchestrator-owned scope rides the receipt so a lane that dies before writing still names its territory.
// QUOTA FALLBACK: usage exhaustion fails the call loudly; the CALLER re-dispatches the same task natively at
// the role's Claude twin (terra->opus) — the sonnet wrapper never becomes the implicit executor. The wrapper
// stall sits above the codex effort tier's blocking-call ceiling: a silent live MCP call is legal waiting.
const shape = (label, scope) => (r) => ({
    lane: label,
    scope,
    ok: !!(r && r.ok && r.report),
    report: (r && r.report) || '',
    entries: (r && r.entries) || 0,
    headline: (r && r.headline) || '',
    failure: (r && r.failure) || (r ? '' : 'lane died'),
});
const lane = (prompt, label, scope, nativeTask) =>
    agent(prompt, { label: 'terra:' + label, phase: 'Audit', model: 'sonnet', effort: 'low', schema: RECEIPT, stallMs: 1500000 })
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
