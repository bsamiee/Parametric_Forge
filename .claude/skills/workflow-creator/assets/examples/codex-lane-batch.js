/**
 * codex-lane-batch — audit heavy scopes on codex (gpt-5.6-terra) through blocking MCP
 * wrapper lanes, batch the short probes into ONE wrapper, then read every report file.
 *
 * Demonstrates codex lane composition: each heavy scope gets one call-write-receipt
 * wrapper — the blocking `codex` MCP call IS the wait, no polling, no launch ceremony;
 * the short probes share a single wrapper making sequential codex calls and returning one
 * combined receipt (every wrapper costs a full context spin-up, so short legs batch);
 * the terminal reader consumes every ok report IN FULL from disk while only thin
 * receipts cross the wire, and a failed lane's scope becomes its direct-hunt queue.
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

// --- [CONSTANTS] -----------------------------------------------------------------------

const SCRATCH = '.claude/scratch/codex-lane-batch'; // run scratch: lane report files; receipts carry the paths

// --- [INPUTS] --------------------------------------------------------------------------

// Structured args — heavy scopes fan one lane each; short probe files batch into one wrapper.
const scopes = Array.isArray(args?.scopes) && args.scopes.length ? args.scopes : ['libs/python/geometry', 'libs/python/compute'];
const probes = Array.isArray(args?.probes) && args.probes.length ? args.probes : ['pyproject.toml', 'libs/python/README.md'];

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

// The codex product shape travels as a prose JSON contract inside the codex prompt — the wrapper's
// RECEIPT schema is the only validation boundary on this path; no schema files exist.
const CONTRACT =
    'Final message: ONLY a JSON object (no fences, no prose) with key "findings" — an array of ' +
    '{claim, file, line, severity: "blocker"|"major"|"minor"} rows, each anchored to a real coordinate.';

const auditTask = (scope) =>
    'Audit ' + scope + ' for drifted docs, phantom members, and dead references. Read every file under it; verify each claim on disk. ' + CONTRACT;

// One wrapper, one blocking codex call, product written verbatim, thin receipt back — never re-judging the work.
const lanePrompt = (label, task) =>
    'DISPATCH ROLE: gpt-5.6-terra performs the complete TASK below through one blocking codex MCP call; never perform, edit, judge, or relay ' +
    'the work yourself. (1) ToolSearch "select:mcp__codex__codex". (2) Call mcp__codex__codex ONCE with model="gpt-5.6-terra", ' +
    'sandbox="read-only", cwd set to the repo root, config={"model_reasoning_effort":"high"}, prompt = the TASK text verbatim. On a tool ' +
    'error retry the identical call ONCE. (3) Write the tool result text VERBATIM to ' +
    SCRATCH +
    '/' +
    label +
    '-report.json (a repo-relative path — resolve it against the repo root for the Write tool; delete any leftover file there ' +
    'first). (4) Return ok, report path, entries = the ' +
    'findings count parsed from the result, headline = per-severity tallies, failure empty — or ok=false with the error text after a failed ' +
    'retry.\n\nTASK:\n\n' +
    task;

// The batched wrapper makes one codex call PER probe, sequentially, and returns ONE combined receipt —
// short legs never earn a wrapper each.
const batchPrompt = (label, files) =>
    'DISPATCH ROLE: run ' +
    files.length +
    ' SEQUENTIAL blocking codex MCP calls, one per probe file below, each with model="gpt-5.6-terra", sandbox="read-only", cwd at the repo ' +
    'root, config={"model_reasoning_effort":"medium"}, prompt = "Probe <file>: verify every path, version, and member it cites against disk. ' +
    CONTRACT +
    '" (1) ToolSearch "select:mcp__codex__codex" once. (2) Call per probe; on a tool error retry that probe ONCE, then record it failed and ' +
    'continue. (3) Merge every findings array and Write the merged JSON VERBATIM to ' +
    SCRATCH +
    '/' +
    label +
    '-report.json (repo-relative — resolve against the repo root; delete any leftover file first). (4) Return ok = at least one ' +
    'probe succeeded, the report path, entries = merged findings ' +
    'count, headline = "<n> probes | <tallies>", failure = the failed probe names or empty.\n\nPROBES: ' +
    JSON.stringify(files);

// Orchestrator-owned scope rides the receipt so a lane that dies before writing still names its territory.
const lane = (prompt, label, scope) =>
    agent(prompt, { label: 'terra:' + label, phase: 'Audit', model: 'sonnet', effort: 'low', schema: RECEIPT }).then((r) => ({
        lane: label,
        scope,
        ok: !!(r && r.ok && r.report),
        report: (r && r.report) || '',
        entries: (r && r.entries) || 0,
        headline: (r && r.headline) || '',
        failure: (r && r.failure) || (r ? '' : 'lane died'),
    }));

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
