#!/usr/bin/env node
// validate-workflow.mjs — lint a Claude Code workflow file against the parser's
// hard rules before you waste a run.
//
//   node validate-workflow.mjs <path-to-workflow.js>
//
// Exit 0 = clean (warnings allowed). Exit 1 = errors found, or bad usage.
//
// Comments and string/template contents are neutralized BEFORE any matching, so
// Date.now()/Math.random()/new Date() written inside a prompt or comment are
// intentionally allowed — only real calls in code throw.

import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const MAX_BYTES = 524288; // 512 KB — scripts above this are rejected before parsing.

const path = process.argv[2];
if (!path) {
    console.error('usage: node validate-workflow.mjs <path-to-workflow.js>');
    process.exit(1);
}

let src;
try {
    src = readFileSync(path, 'utf8');
} catch (e) {
    console.error(`cannot read ${path}: ${e.message}`);
    process.exit(1);
}

const errors = [];
const warnings = [];
const lineOf = (idx) => src.slice(0, idx).split('\n').length;

// --- [SIZE] ----------------------------------------------------------------------------

const bytes = Buffer.byteLength(src, 'utf8');
if (bytes > MAX_BYTES) {
    errors.push(`script is ${bytes} bytes — over the ${MAX_BYTES}-byte (512 KB) limit`);
}

// --- [TRUE_PARSE]
// the runtime wraps the body in an async function, so top-level
// await/return are legal; an AsyncFunction-constructor parse is the exact same grammar.
// This catches what regex checks cannot: unterminated strings, unescaped quotes,
// dangling concatenations. Runs first because every later heuristic assumes valid JS.

try {
    const AsyncFunction = Object.getPrototypeOf(async () => {}).constructor;
    new AsyncFunction('args', 'agent', 'parallel', 'log', 'phase', 'budget', 'workflow', src.replace(/^\s*export\s+const\s+meta/m, 'const meta'));
} catch (e) {
    errors.push(`does not parse as a workflow body: ${e.message}`);
}

// --- [COMMENT_STRING_STRIPPED_COPY] ----------------------------------------------------

function strip(code) {
    let out = '';
    let i = 0;
    const n = code.length;
    while (i < n) {
        const c = code[i],
            d = code[i + 1];
        if (c === '/' && d === '/') {
            // line comment
            while (i < n && code[i] !== '\n') {
                out += ' ';
                i++;
            }
        } else if (c === '/' && d === '*') {
            // block comment
            out += '  ';
            i += 2;
            while (i < n && !(code[i] === '*' && code[i + 1] === '/')) {
                out += code[i] === '\n' ? '\n' : ' ';
                i++;
            }
            out += '  ';
            i += 2;
        } else if (c === '"' || c === "'" || c === '`') {
            // string / template
            // Fill interiors with a non-whitespace, non-word, non-paren placeholder so a
            // non-empty argument (e.g. `new Date('2026-01-01')`) does NOT collapse into
            // empty parens and trip the argless-Date check, while still hiding any token.
            const q = c;
            out += ' ';
            i++;
            while (i < n && code[i] !== q) {
                if (code[i] === '\\') {
                    out += '~~';
                    i += 2;
                    continue;
                }
                out += code[i] === '\n' ? '\n' : '~';
                i++;
            }
            out += ' ';
            i++;
        } else {
            out += c;
            i++;
        }
    }
    return out;
}
const code = strip(src);

// --- [META_LITERAL] --------------------------------------------------------------------

const metaMatch = code.match(/export\s+const\s+meta\s*=/);
if (!metaMatch) {
    errors.push('no `export const meta = {…}` found — every workflow needs it');
} else {
    const before = code.slice(0, metaMatch.index).trim();
    if (before.length > 0) {
        errors.push(`\`export const meta\` must be the FIRST statement (line ${lineOf(metaMatch.index)}) — code precedes it`);
    }
    // crude object span: from the `{` after = to its matching `}`
    const open = code.indexOf('{', metaMatch.index);
    if (open !== -1) {
        let depth = 0,
            end = -1;
        for (let j = open; j < code.length; j++) {
            if (code[j] === '{') depth++;
            else if (code[j] === '}' && --depth === 0) {
                end = j;
                break;
            }
        }
        if (end !== -1) {
            const metaBody = code.slice(open, end + 1);
            const rawMeta = src.slice(open, end + 1);
            if (!/\bname\s*:/.test(metaBody)) errors.push('meta is missing a `name` field');
            if (!/\bdescription\s*:/.test(metaBody)) {
                errors.push('meta is missing a `description` field');
            }
            // pure-literal heuristics — high-confidence violations only
            if (/\.\.\./.test(metaBody)) errors.push('meta contains a spread `...` — it must be a pure literal');
            if (/`/.test(rawMeta)) errors.push('meta contains a template literal — it must be a pure literal');
            if (/[A-Za-z_$][\w$]*\s*\(/.test(metaBody)) {
                errors.push('meta appears to contain a function call — it must be a pure literal');
            }
            for (const bad of ['__proto__', 'constructor', 'prototype']) {
                if (new RegExp(`\\b${bad}\\s*:`).test(metaBody)) {
                    errors.push(`meta uses reserved key \`${bad}\``);
                }
            }
        }
    }
}

// --- [BANNED_NONDETERMINISTIC_CALLS] ---------------------------------------------------

const banned = [
    [/\bDate\s*\.\s*now\b/g, 'Date.now()'],
    [/\bMath\s*\.\s*random\b/g, 'Math.random()'],
    [/\b(?:new\s+)?Date\s*\(\s*\)/g, 'argless Date()/new Date()  (new Date(value) is fine)'],
];
for (const [re, label] of banned) {
    let m;
    while ((m = re.exec(code))) {
        errors.push(`banned non-deterministic call \`${label}\` at line ${lineOf(m.index)} — it throws inside a workflow (breaks resume)`);
    }
}

// --- [SANDBOX_HOST_APIS] ---------------------------------------------------------------

for (const [re, label] of [
    [/\brequire\s*\(/g, 'require()'],
    [/\bimport\s+[^\n]*\bfrom\b/g, 'import … from …'],
    [/\bprocess\s*\./g, 'process.*'],
]) {
    let m;
    while ((m = re.exec(code))) {
        warnings.push(
            `\`${label}\` at line ${lineOf(m.index)} — no Node/host APIs in the orchestrator; do file/shell work inside an agent() instead`,
        );
    }
}

// --- [EFFORT_MODEL_VALUES]
// `effort:`/`model:` are matched in the stripped `code` (so prompt/comment mentions
// never trip this), and the literal VALUE is read from raw `src` at the same offset.

const ALLOWED = {
    effort: new Set(['low', 'medium', 'high', 'xhigh', 'max']),
    model: new Set(['sonnet', 'opus', 'fable', 'inherit']),
};

for (const key of ['effort', 'model']) {
    const re = new RegExp(`\\b${key}\\s*:`, 'g');
    let m;
    while ((m = re.exec(code))) {
        const lit = src.slice(m.index + m[0].length).match(/^\s*(['"])([^'"]*)\1/);
        if (!lit) continue; // a number, variable, or non-literal — not statically checkable
        const val = lit[2];
        if (key === 'model' && val.includes('-')) continue; // a full model id (e.g. claude-opus-4-8), not a short alias
        if (!ALLOWED[key].has(val)) {
            warnings.push(
                `${key} value '${val}' at line ${lineOf(m.index)} is not in ` +
                    `{${[...ALLOWED[key]].join(', ')}}${key === 'model' ? ' (or a full model id)' : ''} ` +
                    '— the agent would fail at runtime',
            );
        }
    }
}

// --- [LONG_PROMPT_STRINGS]
// Targets the actual anti-pattern: a SINGLE string literal whose own content runs
// past the column budget. A correctly `+`-wrapped segment is well under it, so it
// never trips; only a genuinely unwrapped prose string does. Code-overflow lines
// (long because of trailing `.join()`/opts, not the string) are not the string's
// problem and are ignored. `meta` is exempt — its `description` is a forced one-liner.

const MAX_COL = 160;
{
    let metaLo = -1,
        metaHi = -1;
    if (metaMatch) {
        const o = code.indexOf('{', metaMatch.index);
        if (o !== -1) {
            let d = 0;
            for (let j = o; j < code.length; j++) {
                if (code[j] === '{') d++;
                else if (code[j] === '}' && --d === 0) {
                    metaLo = lineOf(o);
                    metaHi = lineOf(j);
                    break;
                }
            }
        }
    }
    // single/double-quoted literals, escape-aware; backtick templates skipped (may be multi-line)
    const re = /'(?:\\.|[^'\\\n])*'|"(?:\\.|[^"\\\n])*"/g;
    let m;
    while ((m = re.exec(src))) {
        const content = m[0].slice(1, -1);
        if (content.length <= MAX_COL || !content.includes(' ')) continue;
        const num = lineOf(m.index);
        if (metaLo !== -1 && num >= metaLo && num <= metaHi) continue;
        warnings.push(
            `string literal at line ${num} is ${content.length} chars — wrap it with adjacent \`+\` ` +
                '(split at a space, keep the space on the left segment; the value stays identical)',
        );
    }
}

// --- [SECTION_DIVIDER_GRAMMAR]
// A real divider is a pure-comment line (its stripped form is blank) matching the
// pattern; in-prompt `[X]` text never qualifies. Flags free text after the bracket
// and banned drift labels. Phase subsection labels (any UPPER_SNAKE) are allowed.

{
    const BANNED = new Set([
        'HARNESS',
        'SCHEMAS',
        'SCHEMA',
        'LAW',
        'CONFIG',
        'PROMPTS',
        'HELPERS',
        'UTILS',
        'COMMON',
        'MISC',
        'FUNCTIONS',
        'LAYERS',
        'IMPORTS',
        'INTERFACES',
        'ENUMS',
        'DTO',
        'QUERIES',
        'FOLDER',
        'SCOPE',
        'INPUT',
    ]);
    const srcLines = src.split('\n');
    const codeLines = code.split('\n');
    for (let i = 0; i < srcLines.length; i++) {
        if ((codeLines[i] || '').trim() !== '') continue; // not a pure comment line
        const m = srcLines[i].match(/^\s*\/\/\s*---\s*\[([A-Z0-9_]+)\](.*)$/);
        if (!m) continue;
        const [, label, tail] = m;
        if (/[^\s-]/.test(tail))
            warnings.push(`divider \`[${label}]\` at line ${i + 1} has free text after the bracket — use \`// --- [${label}]\` + dash-fill only`);
        if (BANNED.has(label))
            warnings.push(
                `divider label \`[${label}]\` at line ${i + 1} is a banned drift label — use a canonical section (CONSTANTS/INPUTS/MODELS/DOCTRINE/OPERATIONS/COMPOSITION) or a phase subsection`,
            );
    }
}

// --- [DEAD_INTERPOLATION]
// Both patterns live INSIDE string/template content, so they are matched in raw
// `src`. `${'$'}{…}` evaluates to the literal text `${…}`; a `__TOKEN__` placeholder
// left for a later patch ships verbatim. Either way a stage prompt fires without
// its data, silently, hours into the run.

for (const [re, label] of [
    [/\$\{\s*['"]\$['"]\s*\}\s*\{/g, "`${'$'}{…}` escape — evaluates to the literal text `${…}`"],
    [/__[A-Z][A-Z0-9_]*__/g, '`__TOKEN__` placeholder — ships verbatim into the prompt'],
]) {
    let m;
    while ((m = re.exec(src))) {
        warnings.push(
            `dead interpolation at line ${lineOf(m.index)}: ${label}; ` +
                'interpolate live — `+ JSON.stringify(x) +` or a single-line `${JSON.stringify(x)}`',
        );
    }
}

// --- [PARALLEL_THUNKS] -----------------------------------------------------------------

{
    const re = /\bparallel\s*\(\s*\[/g;
    let m;
    while ((m = re.exec(code))) {
        const tail = code.slice(m.index + m[0].length, m.index + m[0].length + 40);
        if (/^\s*agent\s*\(/.test(tail)) {
            warnings.push(
                `parallel([...]) at line ${lineOf(m.index)} looks like it holds bare agent(...) calls — wrap each as a thunk: () => agent(...)`,
            );
        }
    }
}

// --- [FORMAT]
// prettier is the one JS formatter whose babel grammar accepts the workflow DSL
// (biome rejects top-level await/return). Structural errors suppress the probe so
// format noise never buries a real defect; a machine without prettier stays silent.

if (errors.length === 0) {
    const probe = spawnSync('prettier', ['--log-level', 'warn', '--check', path], { encoding: 'utf8' });
    if (probe.status === 1) {
        warnings.push(`not house-formatted — run \`prettier --write ${path}\` (or \`fmt ${path}\`)`);
    }
}

// --- [REPORT] --------------------------------------------------------------------------

const name = path.split('/').pop();
for (const w of warnings) console.log(`  warn  ${w}`);
for (const e of errors) console.log(`  ERROR ${e}`);

if (errors.length === 0) {
    console.log(`ok — ${name} passes (${bytes} bytes` + `${warnings.length ? `, ${warnings.length} warning(s)` : ''})`);
    process.exit(0);
} else {
    console.log(`\n${errors.length} error(s) in ${name} — fix before running.`);
    process.exit(1);
}
