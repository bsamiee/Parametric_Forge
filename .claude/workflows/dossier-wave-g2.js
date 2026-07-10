export const meta = {
    name: 'dossier-wave-g2',
    description:
        'Gen-2 get-ahead dossier wave: 16 codex lanes ground every gen-2 charter (t6-t22 + capstone) with launch-only wrappers, a pre-staged harvest script, and an orchestrator harvest loop',
    whenToUse: 'Builds the gen-2 execution mining base while T5 closes; read-only toward repos',
    phases: [
        { title: 'Stage', model: 'sonnet' },
        { title: 'Launch', model: 'sonnet' },
        { title: 'Harvest', model: 'sonnet' },
    ],
};

// --- [CONSTANTS] -----------------------------------------------------------------------

const FORGE = '/Users/bardiasamiee/Documents/99.Github/Parametric_Forge';
const GH = '/Users/bardiasamiee/Documents/99.Github';
const SCRATCH = FORGE + '/.claude/scratch/dossier-wave-g2';
const DOSSIERS = '/Users/bardiasamiee/.claude/dossiers/forge-rebuild/g2';
const THREADS = '/Users/bardiasamiee/.claude/dossiers/forge-rebuild/threads';
const SEEDS = THREADS + '/g2-seeds-t17-t22-capstone.md';
const INTERVAL_MS = 120_000;
const MAX_ROUNDS = 30;

const LANES = [
    {
        scope: 'g2-t6-git',
        charter: THREADS + '/t6-git-identity-rail.md',
        extra: 'Research current 1Password SSH commit-signing (allowed-signers, gitsign alternatives), includeIf identity split patterns, declarative gh config under HM, gitleaks allowlist inversion. Extract every git-tools file fully with line cites.',
    },
    {
        scope: 'g2-t7-node',
        charter: THREADS + '/t7-node-rail-pnpm-only.md',
        extra: 'Establish the exact nodejs-bin strip mechanics, pnpm dlx viability for each mcp-launcher row, node XDG env rows (npm_config_*, COREPACK_*), litter paths to purge.',
    },
    {
        scope: 'g2-t9-theme',
        charter: THREADS + '/t9-theme-token-owner.md',
        extra: 'Design the single palette token owner: nix attrset schema (semantic roles, not raw hexes) with per-tool projection functions; produce the COMPLETE hex-site catalog (file:line for all 500+) and the canonical Dracula-variant table extracted from the duplicated comment blocks.',
    },
    {
        scope: 'g2-t10-instructions',
        charter: THREADS + '/t10-instruction-hygiene.md',
        extra: 'Verify the contradiction inventory against current files; for each contradiction draft the precedence ruling OPTIONS (the operator rules later); map the shared blocks worth single-sourcing and the sibling forge-awareness rows to add.',
    },
    {
        scope: 'g2-t11-doppler-iac',
        charter: THREADS + '/t11-doppler-iac.md',
        extra:
            'Also read ' +
            THREADS +
            '/DIRECTIVE-iac-over-yaml.md and, if present, ' +
            FORGE +
            '/.claude/scratch/doppler-config/report.md. Research the Pulumi Doppler provider surface (resources, import syntax for existing projects/configs/tokens), state backend options for a single operator, the doppler-token bootstrap chicken-and-egg, and the HM-applied directory-scope row design replacing every doppler.yaml.',
    },
    {
        scope: 'g2-t12-scripts',
        charter: THREADS + '/t12-scripts-bar-raise.md',
        extra: 'Verify each named defect against current disk (post-station state may have moved); produce fix/design specs for the survivors and the container-diagnostic owner collapse.',
    },
    {
        scope: 'g2-t14-modules',
        charter: THREADS + '/t14-module-table-collapse.md',
        extra: 'Produce the collapse design: per-owner package-row table schema, the 42-file inventory with target rows, the alias reconciliation map (nc/act/ty/pr/gs verdicts), and the closure-equality proof method.',
    },
    {
        scope: 'g2-t15-nvim',
        charter: THREADS + '/t15-nvim-reproducible.md',
        extra: 'Research lazy.nvim pinning under HM (committed lazy-lock vs store-owned plugins vs nixvim), verify the phantom plugin references, design the reproducible rail preserving the forge-edit RPC contract.',
    },
    {
        scope: 'g2-t16-flake',
        charter: THREADS + '/t16-flake-and-asset-hygiene.md',
        extra:
            'ALSO: exhaustive modernization audit of ' +
            FORGE +
            '/hosts/darwin/default.nix — every option against current nix-darwin master (primaryUser semantics, deprecated options, missing modern options worth setting); the operator asked explicitly whether this file is fully modern.',
    },
    {
        scope: 'g2-t17-machineclean',
        charter: SEEDS,
        extra: 'Execute the t17 section DOSSIER NEEDS: full read-only process inventory (ps -eo pid,ppid,etime,command for user processes; classify every stray sh/zsh by parentage), launchd user+system agents vs Nix-declared set, log trees with sizes, PATH tools with zero references across the five repos (liveness table: tool -> referencing projects -> verdict), npx/global-node usage map.',
    },
    {
        scope: 'g2-t18-darwinmax',
        charter: SEEDS,
        extra: 'Execute the t18 section DOSSIER NEEDS: sweep current macOS system.defaults domains (verify each candidate key live with defaults read), TCC automation truth from current sources (what PPPC without MDM can/cannot do in 2026, tccutil surface, per-app pre-granting reality), BTM/login-items management, privacy-friction settings inventory with drop verdicts.',
    },
    {
        scope: 'g2-t19-nixfrontier',
        charter: SEEDS,
        extra: 'Execute the t19 section DOSSIER NEEDS: curated community sweep (mac-app-util, nix-homebrew, notable flake-parts modules, anything genuinely excellent for a single-user darwin machine — evidence of maintenance and value required), stale-input retirement verdicts for the current flake.lock, the scheduled-bump auto-update design (launchd + nh build + notify, never auto-switch), eval/download optimization options.',
    },
    {
        scope: 'g2-t20-shellmodern',
        charter: SEEDS,
        extra: 'Execute the t20 section DOSSIER NEEDS: zsh plugin ecosystem 2026 audit vs our roster (add/remove verdicts with evidence), completion quality levers, starship advanced modules worth adopting, wezterm nightly capabilities beyond parity, the cross-tool keybind consistency model inputs.',
    },
    {
        scope: 'g2-t21-tooling',
        charter: SEEDS,
        extra:
            'Execute the t21 section DOSSIER NEEDS: per-module-folder quality census of ' +
            FORGE +
            '/modules (beyond wrapper collapse: naivety/contradiction/staleness verdicts per folder), cross-tool unification opportunities, and the admission candidate table: modern powerful CLI tools worth adding (research broadly, admit ruthlessly: each row = tool, why it beats incumbents, full integration spec: XDG/env/config/keybinds/aliases).',
    },
    {
        scope: 'g2-t22-container',
        charter: SEEDS,
        extra: 'Execute the t22 section DOSSIER NEEDS: deep current-state research of Apple container (github.com/apple/container + Containerization framework): install paths (brew/nix), macOS 26 requirements and optimizations, networking/volumes/registry/builds, docker-CLI compat and gaps, performance vs colima/docker, coexistence design, the when-to-use decision table for agents, and the surgical instruction-update plan for ~/.claude, ~/.codex, and the three projects.',
    },
    {
        scope: 'g2-capstone-nixos',
        charter: SEEDS,
        extra: 'Execute the CAPSTONE section DOSSIER NEEDS: dual-OS flake architecture research (shared HM cores, per-OS seams, host detection, specialArgs patterns from exemplary public configs), deployment tooling verdicts (nh os vs deploy-rs vs colmena vs fh apply) for a Mac + one VPS, what of the current darwin surface generalizes, NixOS-on-Hostinger feasibility (kexec/nixos-anywhere on their VPS), doppler/secrets on NixOS, and the explicit operator QUESTION LIST that must be answered before scoping.',
    },
];

// --- [MODELS] --------------------------------------------------------------------------

const PRODUCT_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['dossier_markdown', 'facts', 'versions', 'risks', 'open_questions'],
    properties: {
        dossier_markdown: {
            type: 'string',
            description:
                'The complete dossier: current-state extractions with file:line cites, research findings with sources, config-ready designs, tables. Standalone.',
        },
        facts: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['claim', 'evidence', 'source'],
                properties: { claim: { type: 'string' }, evidence: { type: 'string' }, source: { type: 'string' } },
            },
        },
        versions: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['name', 'value', 'source'],
                properties: { name: { type: 'string' }, value: { type: 'string' }, source: { type: 'string' } },
            },
        },
        risks: { type: 'array', items: { type: 'string' } },
        open_questions: { type: 'array', items: { type: 'string' }, description: 'decisions only the operator can make' },
    },
};

const RECEIPT = {
    type: 'object',
    additionalProperties: false,
    required: ['ok', 'report', 'entries', 'headline', 'failure'],
    properties: {
        ok: { type: 'boolean' },
        report: { type: 'string' },
        entries: { type: 'number' },
        headline: { type: 'string' },
        failure: { type: 'string' },
    },
};

const HARVEST = {
    type: 'object',
    additionalProperties: false,
    required: ['promoted', 'dead', 'pending'],
    properties: {
        promoted: { type: 'array', items: { type: 'string' } },
        dead: { type: 'array', items: { type: 'string' } },
        pending: { type: 'array', items: { type: 'string' } },
    },
};

// --- [DOCTRINE] ------------------------------------------------------------------------

const SAFETY =
    'HARD SAFETY: read-only toward every repo and config; writes only under ' +
    SCRATCH +
    ' and ' +
    DOSSIERS +
    '; ' +
    'never kill/stop/restart/attach zellij or wezterm sessions or any process not launched for your own lane; no installs, no git operations, no doppler/op mutations; NEVER print secret values. ';

// --- [OPERATIONS] ----------------------------------------------------------------------

const stagerPrompt = () =>
    SAFETY +
    'You are the stager. (1) Bash: mkdir -p ' +
    SCRATCH +
    ' ' +
    DOSSIERS +
    ' . (2) Write tool: create ' +
    SCRATCH +
    '/harvest.sh with EXACTLY this content between the markers (markers excluded): <<<SCRIPT\n' +
    '#!/bin/bash\nset -uo pipefail\nS="' +
    SCRATCH +
    '"\nD="' +
    DOSSIERS +
    '"\nLANES=(' +
    LANES.map((l) => l.scope).join(' ') +
    ')\n' +
    'promoted=(); dead=(); pending=()\nfor l in "${LANES[@]}"; do\n  if [[ -s "$D/$l.md" ]]; then promoted+=("$l"); continue; fi\n  r="$S/$l-report.json"\n' +
    '  if [[ -s "$r" ]] && jq -e ".dossier_markdown | length > 100" "$r" >/dev/null 2>&1; then\n    jq -r ".dossier_markdown" "$r" > "$D/$l.md" && cp "$r" "$D/$l.json"; promoted+=("$l")\n' +
    '  elif pgrep -f "$l-report" >/dev/null 2>&1; then pending+=("$l")\n  else\n    sleep 5\n' +
    '    if [[ -s "$r" ]] && jq -e ".dossier_markdown | length > 100" "$r" >/dev/null 2>&1; then\n      jq -r ".dossier_markdown" "$r" > "$D/$l.md" && cp "$r" "$D/$l.json"; promoted+=("$l")\n' +
    '    elif pgrep -f "$l-report" >/dev/null 2>&1; then pending+=("$l")\n    else dead+=("$l: $(tail -c 160 "$S/$l-stderr.log" 2>/dev/null | tr \'\\n\' \' \' | tr \'"\' \' \')")\n    fi\n  fi\ndone\n' +
    'printf \'{"promoted":[%s],"dead":[%s],"pending":[%s]}\' "$(printf \'"%s",\' "${promoted[@]}" | sed \'s/,$//\')" "$(printf \'"%s",\' "${dead[@]}" | sed \'s/,$//\')" "$(printf \'"%s",\' "${pending[@]}" | sed \'s/,$//\')"\n' +
    'SCRIPT>>> (3) Bash: bash -n ' +
    SCRATCH +
    '/harvest.sh && test -s ' +
    SCRATCH +
    '/harvest.sh . (4) Return the receipt: ok=true, report=' +
    SCRATCH +
    '/harvest.sh, entries=0, headline="staged", failure="".';

const launchPrompt = (lane) => {
    const base = lane.scope;
    const taskFile = SCRATCH + '/' + base + '-task.md';
    const schemaFile = SCRATCH + '/' + base + '-schema.json';
    const reportFile = SCRATCH + '/' + base + '-report.json';
    const stderrFile = SCRATCH + '/' + base + '-stderr.log';
    return (
        SAFETY +
        'You are a LAUNCH-ONLY wrapper: start one codex (gpt-5.5) run and return immediately — never wait, never poll, never do its work. Steps: ' +
        '(1) Bash: mkdir -p ' +
        SCRATCH +
        ' ' +
        DOSSIERS +
        ' && rm -f ' +
        reportFile +
        ' ' +
        stderrFile +
        ' . ' +
        '(2) Write tool: create ' +
        taskFile +
        ' with EXACTLY this task text between the markers (markers excluded): <<<TASK ' +
        'GEN-2 DOSSIER LANE ' +
        base +
        '. Read the charter at ' +
        lane.charter +
        ' IN FULL first — execute its DOSSIER NEEDS for this thread. ' +
        lane.extra +
        ' ' +
        'Context: Parametric_Forge (' +
        FORGE +
        ') is the nix-darwin+HM machine owner; sibling repos under ' +
        GH +
        '; a 4-thread rebuild just landed (git log b2ef19a..HEAD). Cite file:line for every local claim and a source URL for every research claim. Never print secret values. ' +
        'The dossier must be decision-complete mining material: current-state extraction, verified research, config-ready designs, and the open questions only the operator can answer. TASK>>> ' +
        'Then create ' +
        schemaFile +
        ' containing EXACTLY this JSON: ' +
        JSON.stringify(PRODUCT_SCHEMA) +
        ' . Then Bash: test -s ' +
        taskFile +
        ' && test -s ' +
        schemaFile +
        ' . ' +
        '(3) Launch detached (ONE Bash call): cd ' +
        FORGE +
        ' && codex exec -s read-only --skip-git-repo-check -c web_search="live" -c mcp_servers={} --ephemeral -o ' +
        reportFile +
        ' --output-schema ' +
        schemaFile +
        ' "Complete the task specified in ' +
        taskFile +
        '. Work from absolute paths. Final message must satisfy the output schema; put the full dossier in dossier_markdown." </dev/null >/dev/null 2>' +
        stderrFile +
        ' & ' +
        '(4) ONE verification call: pgrep -f "' +
        base +
        '-report" >/dev/null && echo ALIVE || echo DEAD-ON-LAUNCH. ' +
        '(5) Return the receipt NOW: ok=true if ALIVE (report=' +
        reportFile +
        ', entries=0, headline="launched", failure=""), else ok=false with the stderr tail as failure.'
    );
};

const harvestPrompt = (pending) =>
    SAFETY +
    'You are a mechanical harvester. Run EXACTLY: bash ' +
    SCRATCH +
    '/harvest.sh — it prints a JSON verdict {promoted, dead, pending} covering every lane. ' +
    'Return that JSON as your structured output, filtered to the lanes you were asked about: ' +
    JSON.stringify(pending) +
    ' (a lane not in your input list stays out of your output). ' +
    'Never kill anything, never relaunch anything, never edit the script, never re-derive its logic yourself.';

// --- [COMPOSITION] ---------------------------------------------------------------------

// --- [STAGE]
phase('Stage');
const staged = await agent(stagerPrompt(), { label: 'stage:harvest-script', phase: 'Stage', schema: RECEIPT, model: 'sonnet', effort: 'low' });
if (!staged || !staged.ok) {
    return { failed: 'stager did not land harvest.sh', staged };
}

// --- [LAUNCH]
phase('Launch');
log('Launching ' + LANES.length + ' gen-2 codex dossier lanes');
const launches = (
    await parallel(
        LANES.map(
            (lane) => () =>
                agent(launchPrompt(lane), { label: 'gpt-5.5:' + lane.scope, phase: 'Launch', schema: RECEIPT, model: 'sonnet', effort: 'low' }).then(
                    (r) => ({ lane: lane.scope, ...(r || { ok: false, failure: 'wrapper died' }) }),
                ),
        ),
    )
).filter(Boolean);

// --- [HARVEST]
phase('Harvest');
let pending = launches.filter((r) => r.ok).map((r) => r.lane);
const dead = launches.filter((r) => !r.ok).map((r) => r.lane + ': ' + (r.failure || 'launch failed'));
const promoted = [];
let round = 0;
while (pending.length && round < MAX_ROUNDS) {
    round++;
    await new Promise((resolve) => setTimeout(resolve, INTERVAL_MS));
    const res = await agent(harvestPrompt(pending), {
        label: 'harvest:r' + round,
        phase: 'Harvest',
        schema: HARVEST,
        model: 'sonnet',
        effort: 'low',
    });
    if (!res) continue;
    promoted.push(...res.promoted);
    dead.push(...res.dead);
    pending = res.pending;
    log('harvest round ' + round + ': promoted=' + promoted.length + ' dead=' + dead.length + ' pending=' + pending.length);
}

return { promoted, dead, pending, rounds: round, dossierHome: DOSSIERS };
