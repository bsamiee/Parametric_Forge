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

import { readFileSync } from 'node:fs'

const MAX_BYTES = 524288 // 512 KB — scripts above this are rejected before parsing.

const path = process.argv[2]
if (!path) {
  console.error('usage: node validate-workflow.mjs <path-to-workflow.js>')
  process.exit(1)
}

let src
try {
  src = readFileSync(path, 'utf8')
} catch (e) {
  console.error(`cannot read ${path}: ${e.message}`)
  process.exit(1)
}

const errors = []
const warnings = []
const lineOf = (idx) => src.slice(0, idx).split('\n').length

// --- 1. size -----------------------------------------------------------------
const bytes = Buffer.byteLength(src, 'utf8')
if (bytes > MAX_BYTES) {
  errors.push(`script is ${bytes} bytes — over the ${MAX_BYTES}-byte (512 KB) limit`)
}

// --- 2. comment/string-stripped copy (so checks ignore text in comments/strings)
function strip(code) {
  let out = ''
  let i = 0
  const n = code.length
  while (i < n) {
    const c = code[i], d = code[i + 1]
    if (c === '/' && d === '/') {                    // line comment
      while (i < n && code[i] !== '\n') { out += ' '; i++ }
    } else if (c === '/' && d === '*') {             // block comment
      out += '  '; i += 2
      while (i < n && !(code[i] === '*' && code[i + 1] === '/')) {
        out += code[i] === '\n' ? '\n' : ' '; i++
      }
      out += '  '; i += 2
    } else if (c === '"' || c === "'" || c === '`') { // string / template
      // Fill interiors with a non-whitespace, non-word, non-paren placeholder so a
      // non-empty argument (e.g. `new Date('2026-01-01')`) does NOT collapse into
      // empty parens and trip the argless-Date check, while still hiding any token.
      const q = c; out += ' '; i++
      while (i < n && code[i] !== q) {
        if (code[i] === '\\') { out += '~~'; i += 2; continue }
        out += code[i] === '\n' ? '\n' : '~'; i++
      }
      out += ' '; i++
    } else {
      out += c; i++
    }
  }
  return out
}
const code = strip(src)

// --- 3. meta must exist, be first, and be a literal --------------------------
const metaMatch = code.match(/export\s+const\s+meta\s*=/)
if (!metaMatch) {
  errors.push('no `export const meta = {…}` found — every workflow needs it')
} else {
  const before = code.slice(0, metaMatch.index).trim()
  if (before.length > 0) {
    errors.push(`\`export const meta\` must be the FIRST statement `
      + `(line ${lineOf(metaMatch.index)}) — code precedes it`)
  }
  // crude object span: from the `{` after = to its matching `}`
  const open = code.indexOf('{', metaMatch.index)
  if (open !== -1) {
    let depth = 0, end = -1
    for (let j = open; j < code.length; j++) {
      if (code[j] === '{') depth++
      else if (code[j] === '}' && --depth === 0) { end = j; break }
    }
    if (end !== -1) {
      const metaBody = code.slice(open, end + 1)
      const rawMeta = src.slice(open, end + 1)
      if (!/\bname\s*:/.test(metaBody)) errors.push('meta is missing a `name` field')
      if (!/\bdescription\s*:/.test(metaBody)) {
        errors.push('meta is missing a `description` field')
      }
      // pure-literal heuristics — high-confidence violations only
      if (/\.\.\./.test(metaBody)) errors.push('meta contains a spread `...` — it must be a pure literal')
      if (/`/.test(rawMeta)) errors.push('meta contains a template literal — it must be a pure literal')
      if (/[A-Za-z_$][\w$]*\s*\(/.test(metaBody)) {
        errors.push('meta appears to contain a function call — it must be a pure literal')
      }
      for (const bad of ['__proto__', 'constructor', 'prototype']) {
        if (new RegExp(`\\b${bad}\\s*:`).test(metaBody)) {
          errors.push(`meta uses reserved key \`${bad}\``)
        }
      }
    }
  }
}

// --- 4. banned non-deterministic calls ---------------------------------------
const banned = [
  [/\bDate\s*\.\s*now\b/g, 'Date.now()'],
  [/\bMath\s*\.\s*random\b/g, 'Math.random()'],
  [/\b(?:new\s+)?Date\s*\(\s*\)/g, 'argless Date()/new Date()  (new Date(value) is fine)'],
]
for (const [re, label] of banned) {
  let m
  while ((m = re.exec(code))) {
    errors.push(`banned non-deterministic call \`${label}\` at line ${lineOf(m.index)} `
      + '— it throws inside a workflow (breaks resume)')
  }
}

// --- 5. host APIs that do not exist in the sandbox ---------------------------
for (const [re, label] of [
  [/\brequire\s*\(/g, 'require()'],
  [/\bimport\s+[^\n]*\bfrom\b/g, 'import … from …'],
  [/\bprocess\s*\./g, 'process.*'],
]) {
  let m
  while ((m = re.exec(code))) {
    warnings.push(`\`${label}\` at line ${lineOf(m.index)} — no Node/host APIs in the `
      + 'orchestrator; do file/shell work inside an agent() instead')
  }
}

// --- 5b. effort / model values outside the allowed set -----------------------
// `effort:`/`model:` are matched in the stripped `code` (so prompt/comment mentions
// never trip this), and the literal VALUE is read from raw `src` at the same offset.
const ALLOWED = {
  effort: new Set(['low', 'medium', 'high', 'xhigh', 'max']),
  model: new Set(['haiku', 'sonnet', 'opus', 'fable', 'inherit']),
}
for (const key of ['effort', 'model']) {
  const re = new RegExp(`\\b${key}\\s*:`, 'g')
  let m
  while ((m = re.exec(code))) {
    const lit = src.slice(m.index + m[0].length).match(/^\s*(['"])([^'"]*)\1/)
    if (!lit) continue                                   // a number, variable, or non-literal — not statically checkable
    const val = lit[2]
    if (key === 'model' && val.includes('-')) continue   // a full model id (e.g. claude-opus-4-8), not a short alias
    if (!ALLOWED[key].has(val)) {
      warnings.push(`${key} value '${val}' at line ${lineOf(m.index)} is not in `
        + `{${[...ALLOWED[key]].join(', ')}}${key === 'model' ? ' (or a full model id)' : ''} `
        + '— the agent would fail at runtime')
    }
  }
}

// --- 6. parallel() should get thunks, not bare promises ----------------------
{
  const re = /\bparallel\s*\(\s*\[/g
  let m
  while ((m = re.exec(code))) {
    const tail = code.slice(m.index + m[0].length, m.index + m[0].length + 40)
    if (/^\s*agent\s*\(/.test(tail)) {
      warnings.push(`parallel([...]) at line ${lineOf(m.index)} looks like it holds bare `
        + 'agent(...) calls — wrap each as a thunk: () => agent(...)')
    }
  }
}

// --- report ------------------------------------------------------------------
const name = path.split('/').pop()
for (const w of warnings) console.log(`  warn  ${w}`)
for (const e of errors) console.log(`  ERROR ${e}`)

if (errors.length === 0) {
  console.log(`ok — ${name} passes (${bytes} bytes`
    + `${warnings.length ? `, ${warnings.length} warning(s)` : ''})`)
  process.exit(0)
} else {
  console.log(`\n${errors.length} error(s) in ${name} — fix before running.`)
  process.exit(1)
}
