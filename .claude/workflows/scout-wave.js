export const meta = {
    name: 'scout-wave',
    description:
        'Two fable scouts: one hunts and charters NEW rebuild threads from deep forge+machine+sibling exploration; one charters world-class extensions of ' +
        'threads T1-T5. Charters and dossiers land on disk; no repo edits.',
    whenToUse: 'Thread-discovery pass while execution threads run; read-only toward all repos',
    phases: [{ title: 'Scout', model: 'fable' }],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const FORGE = '/Users/bardiasamiee/Documents/99.Github/Parametric_Forge';
const GH = '/Users/bardiasamiee/Documents/99.Github';
const DOSSIERS = '/Users/bardiasamiee/.claude/dossiers/forge-rebuild';
const THREADS = DOSSIERS + '/threads';

// --- [MODELS] --------------------------------------------------------------------------

const RECEIPT = {
    type: 'object',
    additionalProperties: false,
    required: ['register', 'charters', 'summary'],
    properties: {
        register: { type: 'string', description: 'absolute path of the register file written' },
        charters: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['id', 'title', 'one_liner', 'path'],
                properties: { id: { type: 'string' }, title: { type: 'string' }, one_liner: { type: 'string' }, path: { type: 'string' } },
            },
        },
        summary: { type: 'string', description: '5-10 sentence synthesis: the strongest opportunities found, ranked' },
    },
};

// --- [DOCTRINE] ------------------------------------------------------------------------

const COMMON =
    'Machine: macOS Apple Silicon; Parametric_Forge (' +
    FORGE +
    ') is the nix-darwin + Home Manager machine owner. Sibling repos: Rasm, Maghz, Noesis, Parametric_Portal under ' +
    GH +
    '. ' +
    'User-level agent configs: ~/.claude (CLAUDE.md, settings.json, skills, hooks, scripts), ~/.codex (AGENTS.md, config.toml). ' +
    'HARD RULES: READ-ONLY toward every repo and config — your ONLY writes are new files under ' +
    THREADS +
    ' and your own scratch under ' +
    FORGE +
    '/.claude/scratch/scout/. ' +
    'Never kill/stop/restart/attach zellij or wezterm sessions or any process; no git operations; no installs; no doppler/op/gh mutations (read-only CLI ' +
    'queries allowed; NEVER print secret values — key names only). ' +
    'Three review stations and a harvester are concurrently mutating the repos — treat working trees as moving; anchor on committed state (git log/show) ' +
    'where stability matters. ' +
    'CODEX DISPATCH: you may run gpt-5.5 legs for bulk reading/research: codex exec -s read-only --skip-git-repo-check -c mcp_servers={} [-c ' +
    'web_search="live"] --ephemeral "<self-contained prompt>" </dev/null 2>/dev/null — SYNCHRONOUS ONLY (capture stdout, Bash timeout 600000); never ' +
    'detached, never polled. Use them liberally for file-heavy sweeps; keep your own context for judgment. ' +
    'CHARTER FORMAT — write one file per proposed thread at ' +
    THREADS +
    '/<id>-<slug>.md: (1) GOAL one paragraph; (2) WHY NOW: concrete evidence from this machine/repo (file:line, command output); (3) TERRITORY: exact ' +
    'paths; (4) DOSSIER NEEDS: the codex research lanes to run before execution (each: scope + what it must establish); (5) WORLD-CLASS BAR: what ' +
    'done-properly means, concretely — no naive/ad-hoc/fragile patterns, ground-up integration, parameterized, dense; (6) SEQUENCING: dependencies on ' +
    'other threads, deploy interactions; (7) RISKS. ' +
    'Charters are decision-complete PROPOSALS for the orchestrator — dense, declarative, no hedging, no testing/validation noise. ' +
    'Also append every charter row to the shared register at ' +
    THREADS +
    '/register.md (create if absent; one line per charter: id | title | one-liner | dependencies). ' +
    'CONTEXT YOU MUST ABSORB FIRST: the existing dossier corpus at ' +
    DOSSIERS +
    ' (t1-*..t4-*, reviews/*.md fix-logs and decisions) and the git log since commit b2ef19a — the campaign so far. Do not re-propose work already landed ' +
    'or already chartered by the seed list; verify seeds against current state and deepen them. ';

const SCOUT_NEW =
    'You are the NEW-THREAD scout. Verified-unassigned seeds (confirm against current disk, then charter the real shape): ' +
    '(t6) git-tools strategy: modules/home/programs/git-tools/* never audited — identity/signing (op SSH signing?), includeIf per-directory identity, ' +
    'universal-vs-per-repo config boundary, gh/lazygit/gitleaks quality; ' +
    '(t7) node rail: pnpm-only — nodejs-bin overlay exposes npm/npx/corepack on PATH; strip + XDG containment + litter cleanup (~/.npm etc.); ' +
    '(t8) forge-provision: keep+improve+slim (3273-line bash, no doc surface) + document its agent-facing purpose into Rasm instructions + ~/.claude + ~/.codex; ' +
    '(t9) theme single-source: one Dracula token owner feeding wezterm/zellij/yazi/bat/delta/fzf/lazygit/starship (+vscode?) — kill per-file hex duplication; ' +
    '(t10) instruction hygiene: CLAUDE.md/AGENTS.md drift reconciliation (LSP table, [NEVER] bullets, sub-agent paragraphs), stale info purge, ' +
    'forge-capability awareness sections for sibling roots, README truthfulness; ' +
    '(t11) doppler maturation: environments/config topology beyond dev, token expiry/rotation posture, workplace settings, and the doppler.yaml-per-repo ' +
    'question — design the Forge-owned path-scope table alternative (doppler configure set --scope rows applied machine-side) so repos carry nothing; ' +
    '(t12) scripts/custom-tooling bar-raise: modules/home/scripts + forge-tools beyond what T1/T2 touched — universal machine/project usage, kill ad-hoc patterns; ' +
    '(t13) canonical drift-proofing: a Forge-owned freshness check (shas of setup-env/bootstrap/mastered skills vs mirrors) surfacing drift without a sync rail. ' +
    'THEN HUNT FREELY for threads the seeds miss. Axes: zsh/shell modernization beyond T2 fixes (plugins worth adding/removing, completion quality, ' +
    'prompt); nix integration tedium (bin/path ergonomics, mise vs nix runtime boundary, devshell quality, new overlays/leaf packages worth owning); ' +
    'agentic hardening (permission ergonomics, hook coverage, notification surfaces, non-interactive rails); spam/legacy patterns across modules (function ' +
    'spam, wrapper modules, dead options); container tools; db-tools; launchd agent hygiene; anything a deep tree/loc sweep of ' +
    FORGE +
    '/modules + overlays exposes. ' +
    'Rank ruthlessly: charter only what carries real value; fold small items into existing charters as line items. Target 6-12 charters total including ' +
    'matured seeds.';

const SCOUT_EXTEND =
    'You are the EXTENSION scout for threads T1-T5. Inputs: the t1-*..t4-* dossiers, every reviews/*.md fix-log and decisions file, the git log ' +
    'b2ef19a..HEAD (nine campaign commits), and the current working trees. ' +
    'For EACH thread T1-T5, identify what separates the landed state from a world-class, ultra-advanced implementation — then charter the extension (ids ' +
    't1x..t5x, same format, one file each; skip a thread only if genuinely nothing above the bar remains, and say why in the register). Focus axes per ' +
    'thread: ' +
    'T1 terminal: runtime acceptance automation for the popup/edit rail, which-key content depth, karabiner data-model elegance (is the captured JSON a ' +
    'dense Nix data structure or a blob?), wezterm nightly capability adoption beyond parity; ' +
    'T2 nix core: the switch-time rail completeness (the stations are fixing kickstart/collision/NOPASSWD — what remains: build-profiling proof of the 1h ' +
    'fix, cache push discipline, gc/optimise posture under Determinate); ' +
    'T3 rails: doppler NON-NAIVETY is the headline — the current rail fetches three fixed configs with a transitional op fallback: design the mature ' +
    'end-state (config topology, per-consumer tokens, failure semantics, offline story, cutover plan, sub-agent inheritance proof across gui/tui/cli), MCP ' +
    'fleet health-checking, launcher drift automation; ' +
    'T4 darwin/cleanup/maghz/fonts: whatever its dossiers left as open questions plus execution depth (wallpaper robustness across displays/spaces, ' +
    'cleanup guards, maghz local-parity mechanism quality); ' +
    'T5 integration: define the ACTUAL integration red-team scope from the real cross-thread seams visible in the fix-logs (cachix token x doppler, cask x ' +
    'forge-redeploy, layout x karabiner, hook x secrets backend) plus live acceptance choreography. ' +
    'Extensions must be improvements a fable executor can land — concrete, territory-bounded, evidence-cited. No re-litigating adjudicated decisions ' +
    '(reviews/*-decisions.md are binding).';

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('Scout');
const results = (
    await parallel([
        () => agent(COMMON + SCOUT_NEW, { label: 'scout:new-threads', phase: 'Scout', schema: RECEIPT, model: 'fable', effort: 'high' }),
        () => agent(COMMON + SCOUT_EXTEND, { label: 'scout:extensions', phase: 'Scout', schema: RECEIPT, model: 'fable', effort: 'high' }),
    ])
).filter(Boolean);

return { scouts: results, threadsHome: THREADS };
