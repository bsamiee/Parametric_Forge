#!/usr/bin/env node
// dry-run.mjs — dry-run a Claude Code workflow without spending tokens.
//
//   node dry-run.mjs <workflow.js> [--mode sim|real] [--args <json|@file>]
//                    [--fixtures <json|@file>] [--scope <path>] [--json]
//
// SIM (default): re-host the UNMODIFIED file under mocked DSL globals, run its real
// control flow with agent() returning schema-shaped fixtures instead of spawning a
// subagent, prove determinism by running twice, and report agent counts, phase
// sequencing, nested workflows, and runtime-cap pressure — for zero tokens.
// REAL: confirm the file simulates green under --scope, then PRINT the exact
// Workflow({scriptPath,args}) invocation plus the projected agent count and a
// commit-then-revert guard for the operator to authorize. It never spawns an agent.
//
// The one non-obvious fact: a workflow file is a FUNCTION BODY, not a module — it has
// top-level `return`/`await` and runs inside an injected-globals async function, so it
// fails `node --check` and any module parser. This harness builds the same wrapper the
// runtime uses. The file is opened READ-ONLY and NEVER written; the `export` strip
// mutates an in-memory copy only.
//
// Sandbox faithfulness: the runtime gives the body NO Node.js host APIs (no `process`,
// `require`, `fs`, `global`, `Buffer`, network) and bans the non-reproducible time/random
// calls. This harness reproduces both — host names are shadowed to throwers and the time/
// random bans throw on use — so a body that reaches for host entropy fails HERE exactly as
// it would in production, instead of silently passing as a false green.
//
// Crash-proofness: a body that never settles (an unresolved promise / await) is raced
// against a wall-clock budget and reported as a timeout, never hung; a body whose schema
// or args recurses without bound is depth-capped; an unreadable target yields a clean
// error. A SYNCHRONOUS infinite loop (`while(true){}`) cannot be interrupted in-process by
// any single-threaded JS runner — wrap the call in your shell's `timeout` for that one.
//
// Honest limitation: agent() ALWAYS returns a fixture here — it never models the
// runtime's "user skipped the agent → null" path. A `.filter(Boolean)` branch that
// only triggers on a skipped agent is therefore not exercised; force it with a
// `--fixtures` override mapping that label to `null` if that branch is load-bearing.

import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { parseArgs } from 'node:util';

// --- [CONSTANTS] -----------------------------------------------------------------------

const MAX_CONCURRENT = 16; // runtime hard cap; a trace above it is a warning
const MAX_AGENTS = 1000; // runtime per-run lifetime cap
const MAX_DEPTH = 1; // a top-level workflow may call workflow() ONCE; a child that itself calls workflow() is the runtime error
const MAX_SYNTH_DEPTH = 64; // fixture-synthesis recursion bound; a self-referential JSON Schema would otherwise blow the stack (a runtime agent returns finite data, never an infinite shape)
const BODY_TIMEOUT_MS = 5000; // wall-clock budget per body run; an unsettled promise/await is reported as a timeout instead of hanging the harness (a deterministic body settles in microseconds under mocked agents)
// The DSL globals the runtime exposes, then the host names it withholds. Both are passed as named Function params: the DSL set is bound to mocks,
// the host set to throwers/undefined, so the body sees EXACTLY the runtime surface — host access fails here as it would there.
const DSL_GLOBALS = [
    'args',
    'agent',
    'parallel',
    'pipeline',
    'workflow',
    'phase',
    'log',
    'budget',
    'setTimeout',
    'clearTimeout',
    'console',
    'Math',
    'Date',
];
const HOST_GLOBALS = ['process', 'global', 'globalThis', 'require', 'module', 'exports', 'Buffer', '__dirname', '__filename'];
const GLOBALS = [...DSL_GLOBALS, ...HOST_GLOBALS];

// --- [INPUTS] --------------------------------------------------------------------------

const { values, positionals } = parseArgs({
    allowPositionals: true,
    options: {
        mode: { type: 'string', default: 'sim' },
        args: { type: 'string' },
        fixtures: { type: 'string' },
        scope: { type: 'string' },
        json: { type: 'boolean', default: false },
    },
});
const FILE = positionals[0];
if (!FILE || (values.mode !== 'sim' && values.mode !== 'real')) {
    console.error(
        'usage: node dry-run.mjs <workflow.js> [--mode sim|real] [--args <json|@file>] [--fixtures <json|@file>] [--scope <path>] [--json]',
    );
    process.exit(2);
}
const loadJson = (v, label) => {
    if (v == null) return undefined;
    try {
        return JSON.parse(v.startsWith('@') ? readFileSync(v.slice(1), 'utf8') : v);
    } catch (e) {
        console.error(`cannot parse --${label}: ${e.message}`);
        process.exit(2);
    }
};
const FIXTURES = loadJson(values.fixtures, 'fixtures') || {};

// --- [OPERATIONS] ----------------------------------------------------------------------

// arrays get exactly one element so control flow proceeds past `.length` guards; a `--fixtures` map keyed by an agent label (exact or prefix) overrides per stage.
const synth = (schema, depth = 0) => {
    if (!schema || typeof schema !== 'object') return null;
    if (depth >= MAX_SYNTH_DEPTH) return null; // self-referential schema ($ref-style cycle or node.child=node) bottoms out here instead of overflowing the stack
    if ('const' in schema) return schema.const;
    if (Array.isArray(schema.enum) && schema.enum.length) return schema.enum[0];
    switch (Array.isArray(schema.type) ? schema.type[0] : schema.type) {
        case 'string':
            return 'x'; // non-empty so a workflow's own `if (!field)` truthiness guards proceed past the fixture
        case 'number':
        case 'integer':
            return 0;
        case 'boolean':
            return false;
        case 'null':
            return null;
        case 'array':
            return [synth(schema.items || {}, depth + 1)];
        default: {
            const o = {},
                props = schema.properties || {};
            for (const k of schema.required || Object.keys(props)) o[k] = synth(props[k] || {}, depth + 1);
            return o;
        }
    }
};

const fixtureFor = (opts) => {
    const label = opts?.label;
    if (label) {
        if (label in FIXTURES) return structuredClone(FIXTURES[label]);
        for (const k of Object.keys(FIXTURES)) if (label.startsWith(k)) return structuredClone(FIXTURES[k]);
    }
    return opts?.schema ? synth(opts.schema) : `<${label || 'agent'}>`;
};

const makeGlobals = (rec, absFile) => {
    let inflight = 0;
    const agent = async (_prompt, opts = {}) => {
        const seq = ++rec.seq;
        inflight++;
        if (inflight > rec.maxConcurrent) rec.maxConcurrent = inflight;
        rec.agents.push({
            seq,
            phase: opts.phase ?? null,
            label: opts.label ?? null,
            model: opts.model ?? null,
            effort: opts.effort ?? null,
            hasSchema: !!opts.schema,
        });
        if (rec.agents.length > MAX_AGENTS)
            rec.warnings.add(
                `exceeded the ${MAX_AGENTS}-agent lifetime cap — the runtime throws WorkflowAgentCapError; add a counter or budget guard to the loop`,
            );
        await Promise.resolve();
        try {
            return fixtureFor(opts);
        } finally {
            inflight--;
        }
    };
    const parallel = async (thunks) =>
        Promise.all(
            (thunks || []).map(async (t) => {
                try {
                    return await t();
                } catch {
                    return null;
                }
            }),
        ); // a thunk that throws sync OR returns a rejecting promise degrades to null, mirroring pipeline
    const pipeline = async (items, ...stages) =>
        Promise.all(
            (items || []).map(async (item, i) => {
                let v = item;
                for (const s of stages) {
                    try {
                        v = await s(v, item, i);
                    } catch {
                        v = null;
                    }
                    if (v == null) break;
                }
                return v;
            }),
        ); // (prev, originalItem, index) — index is load-bearing
    const phase = (title) => {
        rec.phases.push(String(title));
    };
    const log = (m) => {
        rec.console.push(String(m));
    }; // display-only, like the runtime's log(); surfaced via consoleTail
    const budget = { total: null, spent: () => 0, remaining: () => Infinity };
    const workflow = async (name, wargs) => {
        if (rec.depth >= MAX_DEPTH) {
            rec.warnings.add(`workflow('${name}') called from inside a nested workflow — nesting is one level only, the runtime throws here`);
            return {};
        }
        rec.nested.push(String(name));
        let childSrc;
        try {
            childSrc = readFileSync(resolve(dirname(absFile), `${String(name)}.js`), 'utf8');
        } catch {
            rec.warnings.add(
                `nested workflow '${name}' not resolvable beside ${absFile} — returned {} (supply via --fixtures if its result drives control flow)`,
            );
            return {};
        }
        rec.depth++;
        try {
            return await runBody(childSrc, wargs, rec, resolve(dirname(absFile), `${String(name)}.js`));
        } finally {
            rec.depth--;
        }
    };
    const setTimeoutMock = (fn, _ms, ...rest) => {
        try {
            typeof fn === 'function' && fn(...rest);
        } catch {
            /* fire immediately with Node's setTimeout(fn, ms, ...args) extra-args contract; a throwing timer must not crash the trace */
        }
        return 0;
    };
    const con = new Proxy(console, {
        get:
            (_t, k) =>
            (...a) => {
                if (k === 'log' || k === 'error' || k === 'warn' || k === 'info') rec.console.push(a.map(String).join(' '));
                return undefined;
            },
    });
    // faithfully reproduce the runtime's determinism bans: a banned-global USE throws here exactly as it would in production
    const banMath = new Proxy(Math, {
        get: (t, k) =>
            k === 'random'
                ? () => {
                      throw new Error('Math.random() is banned in a workflow (non-deterministic; breaks resume)');
                  }
                : Reflect.get(t, k),
    });
    const banDate = new Proxy(Date, {
        apply: (t, s, a) => {
            if (!a.length) throw new Error('argless Date() is banned in a workflow');
            return Reflect.apply(t, s, a);
        },
        construct: (t, a) => {
            if (!a.length) throw new Error('argless new Date() is banned in a workflow (use new Date(value))');
            return Reflect.construct(t, a);
        },
        get: (t, k) =>
            k === 'now'
                ? () => {
                      throw new Error('Date.now() is banned in a workflow');
                  }
                : Reflect.get(t, k),
    });
    // withhold every Node host name (no process/global/require/Buffer/fs): bound to undefined, so
    // `typeof process` is 'undefined' (feature-detect ok) but `process.env`/`globalThis.x` throws —
    // matching the runtime sandbox and turning a host-entropy false green into an honest failure
    const host = Object.fromEntries(HOST_GLOBALS.map((k) => [k, undefined]));
    return {
        agent,
        parallel,
        pipeline,
        phase,
        log,
        budget,
        workflow,
        setTimeout: setTimeoutMock,
        clearTimeout: () => {},
        console: con,
        Math: banMath,
        Date: banDate,
        ...host,
    };
};

const runBody = async (src, args, rec, absFile) => {
    const g = makeGlobals(rec, absFile);
    const stripped = src.replace(/^([ \t]*)export([ \t]+const[ \t]+meta\b)/m, '$1$2'); // drop only the `export` on the meta line (handles a leading comment)
    const fn = new Function(...GLOBALS, `return (async () => {\n${stripped}\n})()`); // construction throws on a syntax error — this IS the parse-check
    const argv = [
        structuredClone(args),
        g.agent,
        g.parallel,
        g.pipeline,
        g.workflow,
        g.phase,
        g.log,
        g.budget,
        g.setTimeout,
        g.clearTimeout,
        g.console,
        g.Math,
        g.Date,
        ...HOST_GLOBALS.map((k) => g[k]),
    ];
    return fn(...argv); // argv is positional over GLOBALS = [...DSL_GLOBALS, ...HOST_GLOBALS], so host names land on their declared params
};

const freshRecorder = () => ({
    seq: 0,
    depth: 0,
    maxConcurrent: 0,
    agents: [],
    phases: [],
    nested: [],
    console: [],
    warnings: new Set(),
});
const traceOf = (rec, result) =>
    JSON.stringify({
        agents: rec.agents.map((a) => ({
            phase: a.phase,
            label: a.label,
            model: a.model,
            effort: a.effort,
            hasSchema: a.hasSchema,
        })),
        phases: rec.phases,
        nested: rec.nested,
        result,
    });

const simulate = async (absFile, args) => {
    let src;
    try {
        src = readFileSync(absFile, 'utf8');
    } catch (e) {
        return {
            file: absFile,
            mode: 'sim',
            parseOk: false,
            ran: false,
            deterministic: null,
            error: `cannot read ${absFile}: ${e.code || e.message}`,
        };
    }
    // an unsettled body — a promise or await that never resolves — races a wall-clock budget so the harness reports a timeout instead of hanging on it.
    // the timer is NOT unref'd: it holds the event loop open to fire and reject, or Node exits early (code 13) on the stalled await before the timeout lands.
    const withTimeout = (p) =>
        new Promise((res, rej) => {
            const t = setTimeout(
                () =>
                    rej(
                        new Error(
                            `body did not settle within ${BODY_TIMEOUT_MS}ms — a never-resolving promise/await, or an agent() awaited outside the mocked rail`,
                        ),
                    ),
                BODY_TIMEOUT_MS,
            );
            p.then(
                (v) => {
                    clearTimeout(t);
                    res(v);
                },
                (e) => {
                    clearTimeout(t);
                    rej(e);
                },
            );
        });
    // one pass: a SyntaxError at construction propagates (parse fail); a runtime throw is captured as `err` so determinism can still be compared
    const once = async () => {
        const rec = freshRecorder();
        let result,
            err = null;
        try {
            result = await withTimeout(runBody(src, args, rec, absFile));
        } catch (e) {
            if (e instanceof SyntaxError) throw e;
            err = e.message;
            result = { __error: e.message };
        }
        return { rec, result, err };
    };
    let a;
    try {
        a = await once();
    } catch (e) {
        return {
            file: absFile,
            mode: 'sim',
            parseOk: false,
            ran: false,
            deterministic: null,
            error: e.message,
        };
    }
    const b = await once();
    const deterministic = traceOf(a.rec, a.result) === traceOf(b.rec, b.result);
    const perPhase = {},
        perLabel = {};
    for (const ag of a.rec.agents) {
        const p = ag.phase || '(none)';
        perPhase[p] = (perPhase[p] || 0) + 1;
        if (ag.label) perLabel[ag.label] = (perLabel[ag.label] || 0) + 1;
    }
    if (a.rec.maxConcurrent > MAX_CONCURRENT)
        a.rec.warnings.add(`observed ${a.rec.maxConcurrent} concurrent agents — the runtime caps at ${MAX_CONCURRENT}`);
    if (a.err) a.rec.warnings.add(`runtime error: ${a.err}`);
    return {
        file: absFile,
        mode: 'sim',
        parseOk: true,
        ran: !a.err,
        runtimeError: a.err,
        deterministic,
        totalAgents: a.rec.agents.length,
        perPhase,
        perLabel,
        maxConcurrentObserved: a.rec.maxConcurrent,
        phaseSequence: a.rec.phases,
        nestedWorkflows: a.rec.nested,
        capsHit: a.rec.agents.length > MAX_AGENTS || a.rec.maxConcurrent > MAX_CONCURRENT,
        finalReturn: a.result === undefined ? null : a.result,
        consoleTail: a.rec.console.slice(-5),
        warnings: [...a.rec.warnings],
        determinismDiff: deterministic ? null : firstDiff(traceOf(a.rec, a.result), traceOf(b.rec, b.result)),
    };
};
const firstDiff = (a, b) => {
    let i = 0;
    while (i < a.length && i < b.length && a[i] === b[i]) i++;
    return {
        at: i,
        a: a.slice(Math.max(0, i - 30), i + 30),
        b: b.slice(Math.max(0, i - 30), i + 30),
    };
};

// --- [COMPOSITION] ---------------------------------------------------------------------

const absFile = resolve(FILE);
if (values.mode === 'real' && !values.scope) {
    console.error('--mode real needs --scope <one tiny path> (cheapness is args-scoping, never call rewriting)');
    process.exit(2);
}

// REAL passes the raw --scope path as the workflow's args (a path string, not JSON); SIM takes --args as JSON
const report = await simulate(absFile, values.mode === 'real' ? values.scope : loadJson(values.args, 'args'));

if (values.mode === 'real') {
    if (!report.parseOk || !report.ran) {
        console.error(`refusing a real run: the file does not simulate clean (${report.error || report.runtimeError})`);
        process.exit(1);
    }
    console.log('REAL-RUN PRE-FLIGHT (no agent spawned)\n');
    console.log(
        '  simulate(--scope ' +
            values.scope +
            '): parseOk=' +
            report.parseOk +
            ' deterministic=' +
            report.deterministic +
            ' projectedAgents=' +
            report.totalAgents +
            (report.capsHit ? ' [CAP PRESSURE]' : ''),
    );
    if (report.totalAgents === 0)
        console.log('  WARNING: the scope produced 0 agents under fixtures — widen --scope or supply --fixtures so a real run does real work.');
    console.log('\n  Authorize the real run yourself (it spends tokens and may WRITE):');
    console.log(`    Workflow({ scriptPath: '${absFile}', args: ${JSON.stringify(values.scope)} })`);
    console.log('\n  SAFETY: commit a clean base first; if a phase writes, revert with `git checkout . && git clean -fd` afterward.');
    process.exit(0);
}

if (values.json) console.log(JSON.stringify(report, null, 2));
else {
    const name = absFile.split('/').pop();
    if (!report.parseOk) console.log(`  PARSE  ${name} — SYNTAX ERROR: ${report.error}`);
    else if (!report.ran)
        console.log(`  RAN    ${name} — RUNTIME ERROR: ${report.runtimeError}\n  phases reached: ${report.phaseSequence.join(' -> ') || '(none)'}`);
    else {
        console.log(
            `  ${name}: parseOk=true  ran=true  deterministic=${report.deterministic}  agents=${report.totalAgents}  maxConcurrent=${report.maxConcurrentObserved}/${MAX_CONCURRENT}`,
        );
        console.log(`  phases: ${report.phaseSequence.join(' -> ') || '(none)'}`);
        console.log(`  perPhase: ${JSON.stringify(report.perPhase)}`);
        if (report.nestedWorkflows.length) console.log(`  nested: ${report.nestedWorkflows.join(', ')}`);
        if (report.determinismDiff)
            console.log(
                '  DIVERGENCE at char ' +
                    report.determinismDiff.at +
                    ':\n    run1: …' +
                    report.determinismDiff.a +
                    '…\n    run2: …' +
                    report.determinismDiff.b +
                    '…',
            );
        for (const w of report.warnings) console.log(`  warn  ${w}`);
    }
}

process.exit(report.parseOk && report.ran !== false && report.deterministic !== false ? 0 : 1);
