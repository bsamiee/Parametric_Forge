export const meta = {
  name: 'dossier-wave-t4',
  description: 'Thread 4 dossier fan-out with launch-only wrappers and an orchestrator harvest loop: darwin fixes, machine cleanup gates, Maghz VPS wiring, fonts/VSCode integration',
  whenToUse: 'Runs while earlier threads execute; builds the T4 dossiers',
  phases: [
    { title: 'Launch', model: 'sonnet' },
    { title: 'Harvest', model: 'sonnet' },
  ],
}

// --- [CONSTANTS] -----------------------------------------------------------------------

const FORGE = '/Users/bardiasamiee/Documents/99.Github/Parametric_Forge'
const MAGHZ = '/Users/bardiasamiee/Documents/99.Github/Maghz'
const GH = '/Users/bardiasamiee/Documents/99.Github'
const SCRATCH = FORGE + '/.claude/scratch/dossier-wave-t4'
const DOSSIERS = '/Users/bardiasamiee/.claude/dossiers/forge-rebuild'
const INTERVAL_MS = 90_000
const MAX_ROUNDS = 25

const LANES = [
  {
    scope: 't4-darwin',
    task: 'GOAL: build the darwin-system fix dossier. Locked decisions: login window flips to icon list (SHOWFULLNAME=false); wallpaper becomes a NET-NEW home-manager user-scope activation (nothing exists today); security posture stays fully-off (documented consent — do not propose tightening); dock pins get real install sources or removal. ' +
      'LOCAL READS (cite file:line): every file under ' + FORGE + '/modules/darwin/ (system.nix, interface.nix, security.nix, fonts.nix, input.nix, homebrew/*, default.nix, settings/*). Also read /run/current-system/activate excerpts if useful (rg for loginwindow, LSQuarantine, AppleFontSmoothing). ' +
      'WEB RESEARCH (live, macOS 15/26-era sources): (1) the Sonoma+ wallpaper store: ~/Library/Application Support/com.apple.wallpaper/Store/Index.plist structure, PlistBuddy edit patterns, killall WallpaperAgent reliability, per-space/per-display handling, and any nix-darwin/home-manager modules or community activation scripts that already do this correctly; ' +
      '(2) validity of every system.defaults key the repo sets on current macOS (flag deprecated/inert keys beyond the known AppleFontSmoothing no-op); (3) homebrew.masApps mechanics + the Mac App Store numeric ID for Drafts, and whether claude/codex desktop casks exist in homebrew-cask; ' +
      '(4) loginwindow SHOWFULLNAME=false interactions (hidden users, auto-login off) so the flip has no surprises. ' +
      'DOSSIER MUST CONTAIN: the exact system.nix/interface.nix/security.nix edits (compilable nix snippets); the complete wallpaper activation design (HM activation script body, plist operations, agent bounce, wallpaper image sourcing from a repo-declared path); the dock-pin resolution per app; a deprecated-keys cleanup table; risks.',
  },
  {
    scope: 't4-cleanup',
    task: 'GOAL: build the machine-cleanup gate dossier. Authorized cleanups: chmod 700 ~/Library/LaunchAgents; delete ~/.pyenv; purge zsh compdump litter + add a guard; retire rustup (~/.cargo + ~/.rustup, 3.1GB) — the rustup retirement is GATED on proving no sibling repo needs it. ' +
      'LOCAL SWEEPS (read-only, cite evidence): (1) rustup gate: fd rust-toolchain.toml across ' + GH + ' (all repos); rg -l "cargo |rustc|cargo build|cargo run" in each sibling repo\'s build scripts/justfiles/CI configs/docs; check ~/.cargo/bin contents and which -a rustc cargo; determine what used cargo recently (mtimes under ~/.cargo/registry). Verdict: safe-to-retire or name the blocker. ' +
      '(2) ~/.pyenv: confirm nothing references it (rg pyenv in sibling repos + shell configs + launchagents). (3) ~/Library/LaunchAgents: list every plist with owner/label, flag non-Nix-owned entries, and research what could have set 777 (known installers that chmod LaunchAgents). ' +
      '(4) zsh compdump: count ~/.config/zsh/.zcompdump* now; design the compinit -d single-dump guard (exact zsh init lines) that survives concurrent zellij pane spawn (flock or pid-stable path). ' +
      '(5) XDG/dotfile litter: list $HOME top-level dot-entries NOT symlinked into home-manager-files (compare targets), and ~/.config dirs for tools no longer installed. ' +
      'DOSSIER MUST CONTAIN: per-cleanup verdict + exact commands (ordered, with pre-checks), the rustup gate verdict with evidence, the compdump guard design (compilable), the LaunchAgents inventory table, a do-not-touch list (things that look like litter but are live); risks.',
  },
  {
    scope: 't4-maghz',
    task: 'GOAL: build the Maghz VPS-primary wiring dossier. Locked decisions: the Hostinger VPS is the durable home for the Postgres/Ollama/n8n stack; the Mac gets LocalForwards 15435/11434/5678; a local-parity mode must exist (same compose stack locally, explicit profile switch, no silent DSN drift); the VPS consumes secrets via a Doppler service token; the Codex postgres MCP must stop silently failing. ' +
      'LOCAL READS (cite file:line): ' + FORGE + '/modules/home/programs/shell-tools/ssh.nix (current LocalForwards 9000/6800/1455 + IdentityAgent wiring); ' + MAGHZ + ' repo — read the deploy surface (compose files, admin/remote.py or equivalent, settings.py DSN handling around lines 94 and 235, infra.py port bindings), plus /Users/bardiasamiee/.codex/config.toml postgres MCP entry (redact env values — key names only). ' +
      'WEB RESEARCH (live): (1) Doppler CLI install on Ubuntu VPS (apt repo) + doppler configure set token --scope for a service account running under systemd/compose; (2) SSH LocalForward best practice for long-lived tunnels on macOS (ExitOnForwardFailure, ServerAliveInterval, autossh vs launchd-managed ssh -N) so the forwarded MCP is reliable; (3) named profile patterns for dual local/remote DSNs (env-file switch vs doppler configs dev/prd). ' +
      'DOSSIER MUST CONTAIN: the exact ssh.nix additions (compilable); the tunnel-reliability design (launchd unit or ssh config keepalives — one recommendation); the Doppler dev/prd config topology for maghz with the profile-switch mechanism (exact commands/files); the Codex postgres MCP fix (env var sourcing + failure-visibility); Maghz-side changes needed (files + shape, not full implementations); rollout order Mac-side vs VPS-side; risks. SECRETS DISCIPLINE: never reproduce secret values; key names only.',
  },
  {
    scope: 't4-fonts',
    task: 'GOAL: build the fonts + GUI-app integration dossier (user pain: VSCode and other GUI apps do not see the Nix-installed families like GeistMono Nerd Font; user wants fonts genuinely usable everywhere; VSCode settings.json is 12.5KB and fully unmanaged). ' +
      'LOCAL READS (cite file:line): ' + FORGE + '/modules/darwin/fonts.nix; ls "/Library/Fonts/Nix Fonts" (top level only); ~/Library/Application Support/Code/User/settings.json (extract ONLY font/theme-related keys + total key count — do not dump the whole file); check VSCode version (code --version if available). ' +
      'WEB RESEARCH (live): (1) why Electron/Chromium apps (VSCode) fail to enumerate newly installed macOS fonts — font-cache behavior, whether a restart suffices, known VSCode issues with nested font directories under /Library/Fonts, and whether flattening (fonts directly in /Library/Fonts vs the "Nix Fonts" subdir) or ~/Library/Fonts placement changes enumeration; what nix-darwin fonts.packages does today and any open issues about GUI visibility; ' +
      '(2) the exact editor.fontFamily/terminal font settings syntax for Nerd Font families in VSCode (quoting, fallback chains, ligatures); (3) Home Manager programs.vscode current state on darwin: profiles.default.userSettings management, mutable-settings strategies (userSettings vs keeping the file unmanaged with a managed base), extension pinning — the tradeoffs for a heavily hand-tuned 12.5KB settings file; (4) whether a font-registration nudge exists (atsutil databases -remove / fontd restart) that is safe post-activation. ' +
      'DOSSIER MUST CONTAIN: the root-cause verdict for VSCode font visibility with the fix (config change, placement change, or documented restart requirement — with evidence); a VSCode management recommendation (managed/hybrid/unmanaged) honoring the hand-tuned file; exact font-family strings for our stack; any fonts.nix restructuring worth doing; risks.',
  },
]

// --- [MODELS] --------------------------------------------------------------------------

const PRODUCT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['dossier_markdown', 'facts', 'versions', 'risks', 'open_questions'],
  properties: {
    dossier_markdown: { type: 'string', description: 'The complete dossier as standalone markdown: current-state extractions with file:line cites, research findings with source URLs, config-ready snippets, tables.' },
    facts: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['claim', 'evidence', 'source'], properties: { claim: { type: 'string' }, evidence: { type: 'string' }, source: { type: 'string' } } } },
    versions: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['name', 'value', 'source'], properties: { name: { type: 'string' }, value: { type: 'string' }, source: { type: 'string' } } } },
    risks: { type: 'array', items: { type: 'string' } },
    open_questions: { type: 'array', items: { type: 'string' } },
  },
}

const LAUNCH_RECEIPT = {
  type: 'object',
  additionalProperties: false,
  required: ['ok', 'report', 'entries', 'headline', 'failure'],
  properties: {
    ok: { type: 'boolean', description: 'true when the codex process is verified alive after launch' },
    report: { type: 'string', description: 'absolute path the report will land at' },
    entries: { type: 'number', description: 'always 0 at launch' },
    headline: { type: 'string', description: 'always "launched"' },
    failure: { type: 'string', description: 'launch error, "" on success' },
  },
}

const HARVEST = {
  type: 'object',
  additionalProperties: false,
  required: ['promoted', 'dead', 'pending'],
  properties: {
    promoted: { type: 'array', items: { type: 'string' }, description: 'lane scopes promoted this round (or found already promoted)' },
    dead: { type: 'array', items: { type: 'string' }, description: 'lane: reason strings for gone-with-no-valid-report lanes' },
    pending: { type: 'array', items: { type: 'string' }, description: 'lane scopes still running' },
  },
}

// --- [DOCTRINE] ------------------------------------------------------------------------

const SAFETY =
  'HARD SAFETY RULES: read-only toward the machine — never edit repo files, never run mutating commands beyond your own scratch/dossier writes, ' +
  'NEVER kill/stop/restart/attach zellij or wezterm sessions or any process not launched for your own lane. '

// --- [OPERATIONS] ----------------------------------------------------------------------

const launchPrompt = (lane) => {
  const base = lane.scope
  const taskFile = SCRATCH + '/' + base + '-task.md'
  const schemaFile = SCRATCH + '/' + base + '-schema.json'
  const reportFile = SCRATCH + '/' + base + '-report.json'
  const stderrFile = SCRATCH + '/' + base + '-stderr.log'
  return SAFETY +
    'You are a LAUNCH-ONLY wrapper: you start one codex (gpt-5.5) run and return immediately — you never wait for it, never poll it, never do its work. Steps, exactly: ' +
    '(1) Bash: mkdir -p ' + SCRATCH + ' ' + DOSSIERS + ' && rm -f ' + reportFile + ' ' + stderrFile + ' . ' +
    '(2) Write tool: create ' + taskFile + ' containing EXACTLY the task text between the markers (markers are NOT part of the file): <<<TASK ' + lane.task + ' TASK>>> ' +
    'Then create ' + schemaFile + ' containing EXACTLY this JSON: ' + JSON.stringify(PRODUCT_SCHEMA) + ' . Then Bash: test -s ' + taskFile + ' && test -s ' + schemaFile + ' . ' +
    '(3) Launch detached (ONE Bash call): cd ' + FORGE + ' && codex exec -s read-only --skip-git-repo-check -c web_search="live" -c mcp_servers={} --ephemeral -o ' + reportFile + ' --output-schema ' + schemaFile + ' "Complete the task specified in ' + taskFile + '. Work from absolute paths. Final message must satisfy the output schema; put the full dossier in dossier_markdown." </dev/null >/dev/null 2>' + stderrFile + ' & ' +
    '(4) ONE verification Bash call: pgrep -f "' + base + '-report" >/dev/null && echo ALIVE || echo DEAD-ON-LAUNCH. ' +
    '(5) Return the receipt NOW: ok=true (if ALIVE), report=' + reportFile + ', entries=0, headline="launched", failure="" — or ok=false with the stderr tail if DEAD-ON-LAUNCH.'
}

const harvestPrompt = (pending) =>
  SAFETY +
  'You are a mechanical harvester for detached codex dossier lanes. Lanes pending: ' + JSON.stringify(pending) + ' . For EACH lane L do exactly: ' +
  '(a) if ' + DOSSIERS + '/L.md already exists (test -s), count it promoted; ' +
  '(b) else if ' + SCRATCH + '/L-report.json exists AND jq -e ".dossier_markdown | length > 100" passes: promote via jq -r .dossier_markdown ' + SCRATCH + '/L-report.json > ' + DOSSIERS + '/L.md && cp ' + SCRATCH + '/L-report.json ' + DOSSIERS + '/L.json — count promoted; ' +
  '(c) else if pgrep -f "L-report" finds the process: count pending; ' +
  '(d) else re-check (b) once more (write race), and if still no valid report count dead as "L: <last 2 lines of ' + SCRATCH + '/L-stderr.log>". ' +
  'Batch the checks efficiently (one or two Bash calls total using a for-loop over the lane list is ideal). Never kill anything, never relaunch anything, never read report bodies beyond the jq checks. Return {promoted, dead, pending} covering every input lane exactly once.'

// --- [COMPOSITION] ---------------------------------------------------------------------

// --- [LAUNCH]
phase('Launch')
log('Launching ' + LANES.length + ' detached codex lanes (thread 4)')
const launches = (await parallel(LANES.map((lane) => () =>
  agent(launchPrompt(lane), { label: 'gpt-5.5:' + lane.scope, phase: 'Launch', schema: LAUNCH_RECEIPT, model: 'sonnet', effort: 'low' })
    .then((r) => ({ lane: lane.scope, ...(r || { ok: false, failure: 'wrapper died' }) }))
))).filter(Boolean)

// --- [HARVEST]
phase('Harvest')
let pending = launches.filter((r) => r.ok).map((r) => r.lane)
const dead = launches.filter((r) => !r.ok).map((r) => r.lane + ': ' + (r.failure || 'launch failed'))
const promoted = []
let round = 0
while (pending.length && round < MAX_ROUNDS) {
  round++
  await new Promise((resolve) => setTimeout(resolve, INTERVAL_MS))
  const res = await agent(harvestPrompt(pending), { label: 'harvest:r' + round, phase: 'Harvest', schema: HARVEST, model: 'sonnet', effort: 'low' })
  if (!res) continue
  promoted.push(...res.promoted)
  dead.push(...res.dead)
  pending = res.pending
  log('harvest round ' + round + ': promoted=' + promoted.length + ' dead=' + dead.length + ' pending=' + pending.length)
}

return { promoted, dead, pending, rounds: round, dossierHome: DOSSIERS }
