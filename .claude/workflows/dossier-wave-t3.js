export const meta = {
  name: 'dossier-wave-t3',
  description: 'Thread 3 dossier fan-out: gpt-5.5 lanes ground the Doppler migration, MCP fleet symmetry, skills parity, and hook consolidation',
  whenToUse: 'Runs concurrently with Thread 1 execution; builds the dossiers the T3 executor consumes',
  phases: [
    { title: 'Dossier', model: 'sonnet' },
  ],
}

// --- [CONSTANTS] -----------------------------------------------------------------------

const FORGE = '/Users/bardiasamiee/Documents/99.Github/Parametric_Forge'
const RASM = '/Users/bardiasamiee/Documents/99.Github/Rasm'
const MAGHZ = '/Users/bardiasamiee/Documents/99.Github/Maghz'
const GH = '/Users/bardiasamiee/Documents/99.Github'
const SCRATCH = FORGE + '/.claude/scratch/dossier-wave-t3'
const DOSSIERS = '/Users/bardiasamiee/.claude/dossiers/forge-rebuild'
const DEADLINE_MIN = 20
const STALL = 25 * 60_000

const SECRETS_LAW = 'SECRETS DISCIPLINE (absolute): configs you read contain live token values — NEVER reproduce any secret VALUE in the dossier or ' +
  'any output; reference keys by NAME only and write <redacted> where a value would appear. op:// reference PATHS are safe (they are pointers, not values). '

const LANES = [
  {
    scope: 't3-doppler',
    task: SECRETS_LAW +
      'GOAL: build the Doppler-primary secrets-rail migration dossier. Locked decisions: Doppler owns app/API tokens (per-repo scoping, doppler run wrappers, prompt-free for agents/sub-agents); ' +
      'op keeps SSH + personal vaults and seeds a one-time import; transitional fix = launchctl kickstart of the gui replay after secret injection; ambient rail retires post-migration. ' +
      'Doppler CLI v3.76.0 is installed and authenticated to workplace Parametric_Arsenal (only the default example-project exists). ' +
      'LOCAL READS (cite file:line): ' + FORGE + '/modules/home/programs/shell-tools/1password.nix IN FULL (the env.template op:// key inventory = the migration keyset, guiOpSecrets launchd agent, injectSecretsFromVault activation), ' +
      FORGE + '/.claude/hooks/setup-env.sh (canonical agent hook), and run doppler --version && doppler projects --json (safe: names only). ' +
      'WEB RESEARCH (live, docs.doppler.com + github.com/DopplerHQ): (1) per-directory scoping mechanics (doppler setup, doppler.yaml committed per repo, --scope semantics); ' +
      '(2) launchd/GUI-launcher patterns for doppler run on macOS and the --fallback encrypted-snapshot flag for offline reads; ' +
      '(3) service-token minting (CLI + dashboard) and VPS persistence (doppler configure set token --scope) for the Maghz host; ' +
      '(4) @dopplerhq/mcp-server current version + exact registration shape for Claude Code (~/.claude.json mcpServers) and Codex (~/.codex/config.toml mcp_servers) with a config-scoped read-only service token; ' +
      '(5) RE-VERIFY whether DopplerHQ ships official agent skills/plugins (docs + github org sweep) — a Jul 3 check found none; confirm or correct with evidence. ' +
      'DOSSIER MUST CONTAIN: proposed project/config topology for Parametric_Arsenal (machine-wide vs per-repo vs maghz, within free-plan limits 10 projects/4 envs); ' +
      'key-by-key migration map (every env.template key NAME -> target doppler project/config path -> consumers); the setup-env.sh redesign (doppler-first fetch, op fallback during transition, offline behavior); ' +
      'the transitional kickstart fix (exact line + insertion point in 1password.nix); the one-time op->doppler import procedure (command shapes, run by the operator); ' +
      'MCP registration snippets for both runtimes; rollback story; risks.',
  },
  {
    scope: 't3-mcpfleet',
    task: SECRETS_LAW +
      'GOAL: build the MCP fleet symmetry dossier (locked: fully symmetric fleet across Claude + Codex, add the Doppler MCP, fold in Rasm-recent playwright/e2e servers, relocate the LSP marketplace out of the Rasm repo path, drop dead grants). ' +
      'LOCAL READS: /Users/bardiasamiee/.claude.json mcpServers block (server names + command/args; <redacted> every env value); /Users/bardiasamiee/.claude/settings.json (permission grants incl. suspected-dead mcp__computer-use__* and mcp__postgres__*, and extraKnownMarketplaces rasm-lsp hardcoded to ' + RASM + '/.claude/lsp-marketplace); ' +
      '/Users/bardiasamiee/.codex/config.toml mcp_servers tables (names + commands, redact env values); the Forge npm-MCP launcher owner from commit 13e654d (rg "forge-mcp-outdated|mcp-launchers|forge-tavily-mcp" ' + FORGE + '/modules -l, read the owning file fully — table-driven pinned launchers); ' +
      'and Rasm recent additions: rg -i "playwright|e2e|browser" ' + RASM + '/.claude ' + RASM + '/CLAUDE.md ' + RASM + '/AGENTS.md plus any mcp config files found — inventory exactly which playwright/e2e MCP servers or skills Rasm added, their launch commands and pins. ' +
      'DOSSIER MUST CONTAIN: the full fleet matrix (every server x claude-registered x codex-registered x launcher/pin owner x version); asymmetry + dead-grant findings; ' +
      'the target symmetric fleet with EXACT per-file edits (adds, removes, env key NAMES needed per server); playwright/e2e rows with machine-relevance verdicts; ' +
      'LSP marketplace relocation design (candidate homes, tradeoffs, one recommendation — must decouple from the Rasm repo path per the no-project-coupling mandate); risks.',
  },
  {
    scope: 't3-skills',
    task: SECRETS_LAW +
      'GOAL: build the agent-asset parity dossier across four .claude trees. LAW: Rasm is canonical/newest for ALL skills; the direction is Rasm -> (Forge, Maghz, user-global) fix-in-place; ' +
      'EXCEPTION: coding-bash/references/bash-testing.md stays retired in Forge (deliberately removed in commit 03bb4a1 — never restore it). NO WEB NEEDED — local comparative work only. ' +
      'INVENTORY (the product is a matrix): compare ' + FORGE + '/.claude, ' + RASM + '/.claude, ' + MAGHZ + '/.claude, /Users/bardiasamiee/.claude — subtrees skills/, agents/, commands/, hooks/, scripts/, output-styles/, workflows/, settings.json, settings.local.json. ' +
      'For every same-named file present in 2+ trees: sha256 each side, byte size, mtime; classify IDENTICAL vs DRIFTED; for DRIFTED read both and summarize the semantic difference in one line and name the richer/newer side (verify against the Rasm-is-canonical law — flag any file where Forge or global is demonstrably newer instead). ' +
      'List one-tree-only files per tree. Read ' + FORGE + '/.claude/settings.local.json fully (suspected Parametric_Portal leftovers — verify against ' + GH + '/Parametric_Portal if present). ' +
      'Identify the shell scripts under ' + FORGE + '/.claude (hooks/*.sh, scripts/*.sh) — the user calls them "the 2 scripts" — read each fully and grade (strict mode, shellcheck-cleanliness, correctness). ' +
      'DOSSIER MUST CONTAIN: the full parity matrix (grouped by subtree), the fix-in-place action map (file -> copy-from-rasm | keep | delete | merge, each with a one-line reason), the settings.local.json verdict, script grades with defects cited by line. ',
  },
  {
    scope: 't3-hooks',
    task: SECRETS_LAW +
      'GOAL: build the hook + bootstrap consolidation dossier across all five repos. ' +
      'LOCAL READS: .claude/hooks/setup-env.sh in ' + FORGE + ', ' + RASM + ', ' + MAGHZ + ', and locate the other two repos with fd -t d -d 1 . ' + GH + ' (Noesis and Parametric_Portal); read their variants too. ' +
      'Also read each repo\'s .claude/settings.json hooks block (event, command, matcher). ' +
      'KNOWN FACTS TO VERIFY BY sha256 (correct them if drifted since Jul 3): Forge==Maghz canonical (303b42ed...), Noesis==Portal old-drift (52f8cf87... — missing 11 keys, emits retired GREPTILE_TOKEN name, sources the token cache unguarded under set -Eeuo pipefail), Rasm cosmetically reformatted but functionally canonical (66c8e208...). ' +
      'Extract the EXACT corrupted associative-array lines in ' + RASM + '/.claude/scripts/bootstrap-cli-tools.sh (keys like [trash - put], [antigravity - installer], [github - go], [github - release - sha]) and the corresponding intact lines in Forge\'s copy (locate it under ' + FORGE + '/.claude or /Users/bardiasamiee/.claude — rg -l bootstrap-cli-tools across all trees). ' +
      'DOSSIER MUST CONTAIN: per-repo hook diff table (sha, missing key NAMES, wrong env names, guard status, hooks-block wiring); the propagation plan (which exact content lands in each repo — reference the canonical body, do not restate secrets); ' +
      'bootstrap-cli-tools fix rows (corrupted line -> corrected line, with line numbers both sides); settings.json hooks consistency verdicts; risks.',
  },
]

// --- [MODELS] --------------------------------------------------------------------------

const PRODUCT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['dossier_markdown', 'facts', 'versions', 'risks', 'open_questions'],
  properties: {
    dossier_markdown: { type: 'string', description: 'The complete dossier as standalone markdown: current-state extractions with file:line cites, research findings with source URLs, config-ready snippets, tables. This is the primary product.' },
    facts: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['claim', 'evidence', 'source'], properties: { claim: { type: 'string' }, evidence: { type: 'string' }, source: { type: 'string' } } } },
    versions: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['name', 'value', 'source'], properties: { name: { type: 'string' }, value: { type: 'string' }, source: { type: 'string' } } } },
    risks: { type: 'array', items: { type: 'string' } },
    open_questions: { type: 'array', items: { type: 'string' } },
  },
}

const RECEIPT = {
  type: 'object',
  additionalProperties: false,
  required: ['ok', 'report', 'entries', 'headline', 'failure'],
  properties: {
    ok: { type: 'boolean' },
    report: { type: 'string', description: 'absolute path of the promoted durable dossier markdown ("" on failure)' },
    entries: { type: 'number', description: 'facts+versions count from the report json (0 on failure)' },
    headline: { type: 'string', description: 'mechanical jq tally, e.g. facts=12 versions=4 risks=3 oq=2' },
    failure: { type: 'string', description: 'stderr tail / reason on failure, "" on success' },
  },
}

// --- [DOCTRINE] ------------------------------------------------------------------------

const SAFETY =
  'HARD SAFETY RULES for you and the codex run: read-only investigation — never edit repo files, never run mutating commands, ' +
  'NEVER kill/stop/restart/attach zellij or wezterm sessions or any running process (the user works inside them). '

// --- [OPERATIONS] ----------------------------------------------------------------------

const wrapperPrompt = (lane) => {
  const dir = SCRATCH
  const base = lane.scope
  const taskFile = dir + '/' + base + '-task.md'
  const schemaFile = dir + '/' + base + '-schema.json'
  const reportFile = dir + '/' + base + '-report.json'
  const stderrFile = dir + '/' + base + '-stderr.log'
  const dossierMd = DOSSIERS + '/' + base + '.md'
  const dossierJson = DOSSIERS + '/' + base + '.json'
  return SAFETY +
    'You are a dispatch-and-receipt wrapper. Your ONLY job: launch one codex (gpt-5.5) run, poll it, promote its product, return the receipt. ' +
    'You NEVER perform, redo, judge, summarize, or relay the research yourself. Steps, exactly: ' +
    '(1) Bash: mkdir -p ' + dir + ' ' + DOSSIERS + ' && rm -f ' + reportFile + ' ' + stderrFile + ' . ' +
    '(2) Write tool: create ' + taskFile + ' containing EXACTLY the task text between the markers below (the markers themselves are NOT part of the file): ' +
    '<<<TASK ' + lane.task + ' TASK>>> Then create ' + schemaFile + ' containing EXACTLY this JSON: ' + JSON.stringify(PRODUCT_SCHEMA) + ' . Then Bash: test -s ' + taskFile + ' && test -s ' + schemaFile + ' . ' +
    '(3) Launch detached (ONE Bash call, exactly this shape): cd ' + FORGE + ' && codex exec -s read-only --skip-git-repo-check -c web_search="live" -c mcp_servers={} --ephemeral -o ' + reportFile + ' --output-schema ' + schemaFile + ' "Complete the task specified in ' + taskFile + '. Work from absolute paths. Final message must satisfy the output schema; put the full dossier in dossier_markdown." </dev/null >/dev/null 2>' + stderrFile + ' & ' +
    '(4) Poll with sequential bounded Bash calls (each its own tool call: sleep 45; test -s ' + reportFile + ' && echo READY || (pgrep -f "' + base + '-report" >/dev/null && echo ALIVE || echo GONE)). An absent report while the process lives is NORMAL — keep polling patiently; you have a raised stall allowance for exactly this. Hard deadline ' + DEADLINE_MIN + ' minutes: alive past it with no report = WEDGED — pkill -f "' + base + '-report", relaunch once (repeat step 3); a second wedge or a GONE with empty report after one relaunch = failure: return ok=false with failure = last 3 lines of ' + stderrFile + ' . ' +
    '(5) On READY: Bash: jq -e .dossier_markdown ' + reportFile + ' >/dev/null (invalid json = failure with stderr tail); then jq -r .dossier_markdown ' + reportFile + ' > ' + dossierMd + ' && cp ' + reportFile + ' ' + dossierJson + ' . ' +
    '(6) Compute MECHANICALLY via jq: entries = (.facts|length) + (.versions|length); headline = "facts=N versions=N risks=N oq=N" from the same counts. ' +
    '(7) Return the receipt object: ok=true, report=' + dossierMd + ', entries, headline, failure="".'
}

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('Dossier')
log('Launching ' + LANES.length + ' gpt-5.5 dossier lanes (thread 3)')

const roster = (await parallel(LANES.map((lane) => () =>
  agent(wrapperPrompt(lane), { label: 'gpt-5.5:' + lane.scope, phase: 'Dossier', schema: RECEIPT, model: 'sonnet', effort: 'low', stallMs: STALL })
    .then((r) => ({ lane: lane.scope, scope: [lane.scope], ...(r || { ok: false, report: '', entries: 0, headline: '', failure: 'wrapper skipped or died' }) }))
))).filter(Boolean)

const okCount = roster.filter((r) => r.ok).length
log('T3 dossier wave complete: ' + okCount + '/' + LANES.length + ' lanes ok')

return { roster, dossierHome: DOSSIERS, unmapped: roster.filter((r) => !r.ok).map((r) => r.lane) }
