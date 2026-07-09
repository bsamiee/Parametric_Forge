export const meta = {
  name: 'thread-review',
  description: 'Sequential cold write-review station: a predicate-positive CRITIQUE pass then a predicate-negative RED-TEAM pass, both fable write-agents that fix and extend in place and leave fix-log dossiers',
  whenToUse: 'After a thread executor lands and commits: args = {thread, base, head, territory, dossiers, ammo}',
  phases: [
    { title: 'Critique', model: 'fable' },
    { title: 'RedTeam', model: 'fable' },
  ],
}

// --- [CONSTANTS] -----------------------------------------------------------------------

const FORGE = '/Users/bardiasamiee/Documents/99.Github/Parametric_Forge'
const LOGDIR = '/Users/bardiasamiee/.claude/dossiers/forge-rebuild/reviews'

// --- [INPUTS] --------------------------------------------------------------------------

let raw = args
if (typeof raw === 'string' && raw.trim().startsWith('{')) { try { raw = JSON.parse(raw) } catch (e) { raw = {} } }
const cfg = (typeof raw === 'object' && raw) || {}
const THREAD = cfg.thread || 'thread'
const BASE = cfg.base || ''
const HEAD = cfg.head || 'HEAD'
const TERRITORY = Array.isArray(cfg.territory) ? cfg.territory : []
const DOSSIERS = Array.isArray(cfg.dossiers) ? cfg.dossiers : []
const AMMO = Array.isArray(cfg.ammo) ? cfg.ammo : []
if (!BASE || TERRITORY.length === 0) {
  log('thread-review: missing base commit or territory — no-op')
  return { skipped: true, reason: 'args require {thread, base, territory[]}' }
}

// --- [MODELS] --------------------------------------------------------------------------

const FIXLOG = {
  type: 'object',
  additionalProperties: false,
  required: ['log', 'fixed', 'extended', 'refuted', 'unreachable', 'gates_green', 'summary'],
  properties: {
    log: { type: 'string', description: 'absolute path of the fix-log dossier this pass wrote' },
    fixed: { type: 'number', description: 'count of defects repaired in place' },
    extended: { type: 'number', description: 'count of beyond-fix improvements (densification, capability, hardening)' },
    refuted: { type: 'number', description: 'count of prior claims disproven against disk with evidence' },
    unreachable: { type: 'number', description: 'count of genuinely unreachable items (each justified in the log)' },
    gates_green: { type: 'boolean' },
    summary: { type: 'string', description: '3-6 sentence state-of-thread after this pass' },
  },
}

// --- [DOCTRINE] ------------------------------------------------------------------------

const COMMON =
  'Repo: ' + FORGE + ' (nix-darwin + Home Manager flake, macOS Apple Silicon). Thread ' + THREAD + ' territory (the ONLY paths you may edit): ' +
  TERRITORY.join(', ') + ' — plus the fix-log you write under ' + LOGDIR + '. Scope of record: git diff ' + BASE + '..' + HEAD + ' restricted to that territory, ' +
  'PLUS any uncommitted working-tree changes inside it. Ground truth inputs, read IN FULL before editing: the thread dossiers (' + DOSSIERS.join(', ') + ') ' +
  'and the repo CLAUDE.md standards. ' +
  'HARD SAFETY: never kill/stop/restart/attach zellij or wezterm sessions or any process; no darwin-rebuild switch or forge-redeploy --switch; no brew operations; ' +
  'no git commits or pushes; never edit outside the territory; other threads own other paths concurrently. ' +
  'ROLE LAW: you WRITE. Every defect you can reach is repaired in place the moment you find it; your log records edits ALREADY MADE. ' +
  'RESEARCH DELEGATION: offload bulk reading/verification to synchronous read-only codex legs so your own context stays for judgment and writing — ' +
  '(codex exec -s read-only --skip-git-repo-check -c mcp_servers={} "<self-contained question>" </dev/null 2>/dev/null, Bash timeout 600000) for sweeps, upstream checks, ' +
  'and judgment-heavy investigation alike; codex is the ONLY delegation lane here. Helpers NEVER write — every edit is yours. ' +
  'A would/should/could sentence about your own scope is a process defect. An item goes to the log as UNREACHABLE only when it genuinely cannot be resolved ' +
  'from the files at hand (needs a deploy, a user decision, or another thread\'s territory) — with the reason. ' +
  'GATES before you finish, all green, failures in YOUR territory fixed by you: alejandra --check ., deadnix --fail flake.nix flake-modules hosts modules overlays, ' +
  'statix check on those dirs, nix flake check, forge-redeploy --check-only, shellcheck on every script body you touched. ' +
  'A gate failure OUTSIDE your territory is reported in the log, not fixed. ' +
  'FIX-LOG GRAMMAR (one row per action, grouped by file): `FIXED | <file:line> | <defect> | <edit made>`, ' +
  '`EXTENDED | <file:line> | <weakness> | <improvement made>`, `REFUTED | <claim source> | <claim> | <disk evidence>`, ' +
  '`UNREACHABLE | <file:line> | <defect> | <why + where it must resolve>`. Dense rows, no narration, no praise. '

const CRITIQUE_MANDATE =
  'You are the CRITIQUE pass — cold, predicate-POSITIVE: verify every required law HOLDS, line by line, and repair every miss in place. ' +
  'You have no knowledge of the implementer\'s reasoning; the diff and the dossiers are your evidence. The checklists are a FLOOR — hunt past them: ' +
  '(1) LOCKED-DECISION CONFORMANCE: every locked decision recorded in the thread dossiers landed fully — partial landings are defects you complete; ' +
  '(2) DOSSIER-FACT CONFORMANCE: every implementation choice that contradicts a dossier-verified fact is corrected, or the dossier claim is REFUTED with disk/upstream evidence; ' +
  '(3) DOCTRINE CONFORMANCE: repo CLAUDE.md law — dense polymorphic nix, no wrapper modules, no function spam, writeShellApplication for shell CLIs, ' +
  'parameterization over hardcodes, file headers, 1-2 line agent-first comments, no dead code, no anticipatory code; ' +
  '(4) CAPABILITY COMPLETENESS: thin slices of a concept the change should own fully are deepened (coverage naivety) and enumerated hardcoded families are ' +
  'collapsed into parameterized owners (approach naivety); ' +
  '(5) INTERNAL CONSISTENCY: names, palette values, chord tables, env keys, and paths consistent across every file the thread touched. ' +
  'Every hit is a FIX, never a note. '

const REDTEAM_MANDATE =
  'You are the RED-TEAM pass — the terminal, most aggressive review; cold and predicate-NEGATIVE: assume the author AND the critique missed things and that ' +
  'their claims are wrong until CURRENT disk proves them. FORM YOUR OWN ATTACK FIRST: cold-read every territory file from disk before consulting the critique ' +
  'fix-log or the reader ammo below. Attack axes: ' +
  '(1) COUNTERFACTUAL on the core design: would a different owner shape, dispatch, or data flow be strictly denser or more correct? If yes, rebuild it in place; ' +
  '(2) NEXT-FEATURE DIFF: does the next obvious capability (a new pane kind, a new secret key, a new tool, a new host) land as one row/case with consumers ' +
  'untouched — or does it require surgery? Restructure until it lands as a row; ' +
  '(3) FAILURE-MODE LONG TAIL: races, concurrent tabs/sessions/activations, empty/missing files, absent binaries, offline network, stale state, signal death, ' +
  'first-run vs steady-state — walk each through the actual code and fix what breaks; ' +
  '(4) PHANTOM SURFACES: every CLI flag, action, option key, env var, and API member the code references must exist in the installed tool or pinned version — ' +
  'verify against binaries/docs on this machine; delete or correct phantoms; ' +
  '(5) ROLLOUT HAZARDS: what breaks at the next switch on THIS machine given its live state — fix what code can fix, log UNREACHABLE deploy-sequencing steps; ' +
  '(6) FULL COLD RE-REVIEW of every conformance dimension the critique claims to have covered. ' +
  'The thread must end OBJECTIVELY denser and more capable than the critique left it — an empty pass is earned by an attack that finds nothing, never conceded on first read. '

// --- [COMPOSITION] ---------------------------------------------------------------------

// --- [CRITIQUE]
phase('Critique')
const critique = await agent(
  COMMON + CRITIQUE_MANDATE +
  'Write your fix-log to ' + LOGDIR + '/' + THREAD + '-critique.md (mkdir -p first). ' +
  'Return the receipt: log path, counts, gates_green, summary.',
  { label: 'critique:' + THREAD, phase: 'Critique', schema: FIXLOG, model: 'fable', effort: 'high' }
)

// --- [RED_TEAM]
phase('RedTeam')
const ammoNote = AMMO.length
  ? 'READER AMMO (independent read-only findings from other model lineages — treat every claim as unverified until disk proves it; refute freely): ' + AMMO.join(', ') + '. '
  : ''
const redteam = await agent(
  COMMON + REDTEAM_MANDATE + ammoNote +
  'The critique pass before you wrote ' + LOGDIR + '/' + THREAD + '-critique.md — consult it ONLY AFTER your own cold attack; re-verify its claims like any other. ' +
  'Write your fix-log to ' + LOGDIR + '/' + THREAD + '-redteam.md. Return the receipt: log path, counts, gates_green, summary.',
  { label: 'redteam:' + THREAD, phase: 'RedTeam', schema: FIXLOG, model: 'fable', effort: 'high' }
)

return { thread: THREAD, critique, redteam }
