export const meta = {
  name: 'dossier-wave',
  description: 'Thread 1+2 dossier fan-out: gpt-5.5 lanes ground the terminal keystone and nix-core rebuild with verified current-state and upstream research',
  whenToUse: 'Before executing a rebuild thread: builds the durable dossiers the fable executor consumes',
  phases: [
    { title: 'Dossier', model: 'sonnet' },
  ],
}

// --- [CONSTANTS] -----------------------------------------------------------------------

const FORGE = '/Users/bardiasamiee/Documents/99.Github/Parametric_Forge'
const SCRATCH = FORGE + '/.claude/scratch/dossier-wave'
const DOSSIERS = '/Users/bardiasamiee/.claude/dossiers/forge-rebuild'
const DEADLINE_MIN = 20

const LANES = [
  {
    scope: 't1-wezterm',
    task: 'GOAL: build the WezTerm-nightly migration dossier for a tabula-rasa terminal rebuild on macOS (Apple Silicon, nix-darwin + Home Manager). ' +
      'LOCAL READS (read fully, cite file:line): ' + FORGE + '/modules/home/programs/apps/wezterm/ (all .lua + default.nix), ' +
      FORGE + '/modules/darwin/homebrew/casks.nix (wezterm cask row), ' + FORGE + '/modules/darwin/homebrew/default.nix (autoupdate posture). ' +
      'WEB RESEARCH (live, official sources: wezfurlong.org/wezterm docs + github.com/wezterm/wezterm): (1) the exact Homebrew cask name and mechanics for WezTerm nightly on macOS, its update cadence, and how to PIN a nightly build against unwanted auto-updates given a brew-autoupdate launchd daemon runs with --upgrade (auto_updates flag on the cask? greedy behavior?); ' +
      '(2) config-surface diffs between release 20240203-110809 and current nightly that touch OUR config keys: front_end default, WebGpu status, freetype_load_target/render_target, use_cap_height_to_scale_fallback_fonts, font fallback behavior fixes, command palette options (command_palette_font?), quick_select changes, window_decorations/background blur on modern macOS; ' +
      '(3) key_tables + leader + update-status which-key emulation primitives (for a later discoverability surface). ' +
      'DOSSIER MUST CONTAIN: current-config inventory table (every config key we set, file:line, keep/change/drop-on-nightly verdict each with reason); the cask migration plan (exact commands/cask names, pinning strategy vs the autoupdate daemon); nightly-only options worth adopting; risks.',
  },
  {
    scope: 't1-zellij',
    task: 'GOAL: build the Zellij tabula-rasa grounding dossier. Zellij is 0.44.3, config is Nix-generated. ' +
      'LOCAL READS (read fully, cite file:line): ' + FORGE + '/modules/home/programs/apps/zellij/ (config.nix, default.nix, layouts/*.nix, themes/*.nix), ' +
      FORGE + '/modules/home/programs/apps/wezterm/integration.lua (handoff), ' + FORGE + '/modules/home/environments/applications.nix (ZELLIJ_DEFAULT_LAYOUT), ' +
      'and the live generated /Users/bardiasamiee/.config/zellij/config.kdl. ' +
      'WEB RESEARCH (live, zellij.dev docs + github.com/zellij-org/zellij 0.44.x release notes): (1) floating + pinned pane support: exact kdl for floating_panes in layouts, zellij run --floating --pinned -x -y --width --height --name --close-on-exit, TogglePanePinned; ' +
      '(2) the full zellij action command list on 0.44.3 relevant to pane targeting: can a pane be focused/toggled BY NAME or id (list-clients, focus-* actions, MoveFocusOrTab), zellij action new-pane flags, zellij action edit behavior; ' +
      '(3) attach semantics: confirmation that --layout applies only at session creation with session_serialization=true resurrection, and the sanctioned way to roll a new layout onto a persistent session named main WITHOUT killing other live sessions (delete-session vs kill-session semantics on a detached serialized session); ' +
      '(4) compact-bar tooltip config key on 0.44 (plugin alias config), plugin alias + LaunchOrFocusPlugin patterns. ' +
      'DOSSIER MUST CONTAIN: complete current keybind map (every mode, chord, action — one table), layout topology map with pane_template/swap_layout structure, the preserve-list (dracula hex set, GeistMono stack, session name main, Super/Hyper/Power chord scheme), verified floating-yazi bind snippet, serialized-session rollout procedure, risks.',
  },
  {
    scope: 't1-yazi',
    task: 'GOAL: build the Yazi modernization dossier (floating-popup-first redesign, current plugin ecosystem). ' +
      'LOCAL READS (read fully, cite file:line): ' + FORGE + '/modules/home/programs/apps/yazi/ (every file incl. yazi.toml, theme, plugins/*), ' +
      FORGE + '/modules/home/scripts/integration/yazi/ and ' + FORGE + '/modules/home/scripts/integration/zellij/ (forge-yazi.sh, forge-edit.sh, forge-nvim.sh sources — extract the full text of each with line numbers). ' +
      'Try local version probes (nix eval --raw nixpkgs#yazi.version; yazi --version); if sandbox blocks, resolve versions via web (search.nixos.org). ' +
      'WEB RESEARCH (live, yazi-rs.github.io docs + github.com/sxyazi/yazi + github.com/yazi-rs/plugins): (1) current yazi version line (26.x calendar versioning) and what changed vs our config surface (yazi.toml schema: [mgr] vs [manager] rename status, opener/previewer config shape, ratio); ' +
      '(2) Home Manager programs.yazi option surface today (plugins attrset via fetchFromGitHub pins, flavors, initLua); ' +
      '(3) the plugin roster worth shipping: official monorepo plugins (git, piper, toggle-pane, chmod, mount, smart-enter?) + vetted community must-haves 2026 + dracula flavor repo (exact repo + latest rev), zoxide/fzf builtins config; ' +
      '(4) yazi-as-floating-popup ergonomics: quit-to-cwd patterns, single-instance behavior, opener config for handing files to an editor in the HOST multiplexer rather than $EDITOR inside the popup. ' +
      'DOSSIER MUST CONTAIN: current module map + full script extractions; target plugin roster table (name, repo, purpose, pin strategy); yazi.toml redesign inputs for popup-first usage; theme plan; risks.',
  },
  {
    scope: 't1-karabiner',
    task: 'GOAL: build the Karabiner capture + declarative-staging dossier. The live config is the ONLY source of the physical modifier scheme every zellij chord depends on. ' +
      'LOCAL READS: /Users/bardiasamiee/.config/karabiner/karabiner.json (read fully), /Users/bardiasamiee/.config/karabiner/assets/complex_modifications/*.json if present, and check what Karabiner version is installed (/Applications/Karabiner-Elements.app Info.plist CFBundleShortVersionString or brew list --cask --versions karabiner-elements). ' +
      'CANONICALIZE: embed the complete karabiner.json verbatim in the dossier AND write a semantic description of every profile, rule (including the Caps-Lock rule), manipulator, device-specific setting, and parameter — what physical key maps to what, producing the Hyper/Super/Power chord table. ' +
      'WEB RESEARCH (live, karabiner-elements.pqrs.org docs + github.com/pqrs-org/Karabiner-Elements): (1) karabiner.json schema for the installed major version (16.x): profiles, complex_modifications.parameters, breaking changes 15.x->16.x; ' +
      '(2) how Karabiner-Elements treats external edits to karabiner.json (karabiner_console_user_server file watching — does it hot-reload, does it rewrite/reformat on GUI change, atomic-write requirements); ' +
      '(3) proven declarative-management patterns that COEXIST with the app: HM activation write-if-changed into ~/.config/karabiner (not a symlink), assets/complex_modifications staging + GUI enable, karabiner.ts/goku as codegen references only. ' +
      'DOSSIER MUST CONTAIN: the verbatim config, the semantic chord table (physical key -> modifiers -> meaning), regeneration design inputs (what Nix data structure must express), coexistence/write-safety rules with citations, risks.',
  },
  {
    scope: 't1-whichkey',
    task: 'GOAL: build the keybinding-discoverability stack dossier for Zellij 0.44.3 (decision locked: in-terminal stack = compact-bar tooltip + zjstatus-hints + zellij-forgot, dracula-themed). ' +
      'LOCAL READS: ' + FORGE + '/modules/home/programs/apps/zellij/config.nix (plugin alias block + zjstatus config, keybind modes) for wiring shape. ' +
      'WEB RESEARCH (live, verify against the CANONICAL repos): (1) zellij built-in compact-bar/status-bar tooltip: the exact plugin config key on 0.44.x (tooltip "F1"?), where it renders, PR/issue references; ' +
      '(2) github.com/b0o/zjstatus-hints: latest release tag, the .wasm asset URL, configuration surface (pipe name, format, max length), the zjstatus format token that receives the pipe output, and a complete integration snippet with dj95/zjstatus v0.23.0; ' +
      '(3) github.com/karimould/zellij-forgot: latest release, wasm URL, config (keybind LOAD_ZELLIJ_BINDINGS etc.), evidence it loads under zellij 0.44.x (issues/discussions), how it sources keybinds (config.kdl parse? manual list?); ' +
      '(4) sweep for any NEWER maintained which-key/cheatsheet zellij plugins (2025-2026) that supersede these; ' +
      '(5) sha256 for each wasm asset if computable from release metadata; otherwise give exact URLs for nix prefetch at execution time. ' +
      'DOSSIER MUST CONTAIN: the chosen stack with config-READY kdl/nix snippets (plugin aliases, keybinds, zjstatus format integration, dracula tokens), load order, fallbacks if a plugin fails under 0.44.3, risks.',
  },
  {
    scope: 't1-editrail',
    task: 'GOAL: design-ground the yazi->editor rail rebuild (current one is broken three ways: focus-next-pane hits yazi at startup, Nix-escaped \\$SOCKET/\\$* expand empty, ordinal focus is layout-dependent). ' +
      'LOCAL READS (extract full text with line numbers): ' + FORGE + '/modules/home/scripts/integration/zellij/default.nix (forge-edit.sh, forge-nvim.sh), ' +
      FORGE + '/modules/home/scripts/integration/yazi/ (forge-yazi.sh, any zoxide script), ' + FORGE + '/modules/home/programs/apps/yazi/yazi.toml (opener config), ' +
      'and check whether an nvim module exists under ' + FORGE + '/modules/home/programs/apps/nvim/ (read its default.nix if so). ' +
      'WEB RESEARCH (live, zellij.dev + neovim docs + community patterns 2025-2026): (1) the exact zellij action surface for editor handoff on 0.44.3: zellij action edit <file> (which pane it opens in, cwd, flags), new-pane --floating -- nvim, focus actions available (by direction/index — confirm whether name-targeted focus exists or not); ' +
      '(2) nvim single-instance patterns: nvim --listen <socket> + nvr --remote vs --server --remote flags on current nvim (0.11+), socket-per-tab vs socket-per-session designs; ' +
      '(3) how people actually wire yazi (floating) -> existing nvim pane in zellij: real dotfile/plugin examples. ' +
      'DOSSIER MUST CONTAIN: 2-3 candidate rail architectures with EXACT commands (opener line in yazi.toml, script body sketch, zellij actions used), a scored recommendation, edge cases (no editor pane yet, floating yazi closed on open, multiple files), risks.',
  },
  {
    scope: 't2-determinate',
    task: 'GOAL: build the Determinate-Nix declarative-settings migration dossier. Today nix.enable=false makes the entire nix.settings block dead; /etc/nix/*.conf are stale installer artifacts. Decision locked: adopt the official Determinate darwin module. ' +
      'LOCAL READS (read fully, cite line numbers): ' + FORGE + '/modules/common/nix.nix (the dead block — every setting), ' + FORGE + '/flake.nix + ' + FORGE + '/flake-modules/nixpkgs.nix (input wiring), /etc/nix/nix.conf and /etc/nix/nix.custom.conf (live state), and run: nix --version; determinate-nixd version 2>/dev/null. ' +
      'WEB RESEARCH (live, github.com/DeterminateSystems/determinate + FlakeHub + docs.determinate.systems): (1) the determinate flake input URL form and darwinModules usage current as of mid-2026; determinateNix.enable and determinateNix.customSettings exact option names/types FROM MODULE SOURCE; interaction with nix-darwin nix.enable; ' +
      '(2) current Determinate Nix version + changelog highlights since 3.21 (we run 3.21.2); lazy-trees and eval-cores current defaults (still needed explicitly?); parallel-eval status; ' +
      '(3) which settings belong in customSettings for our use: substituters (cache.nixos.org, nix-community, bsamiee.cachix.org), trusted-public-keys, keep-outputs, min/max-free, http-connections, netrc handling for FlakeHub; what Determinate manages itself and will fight us on. ' +
      'DOSSIER MUST CONTAIN: a per-setting migration table for every line of the dead nix.settings block (keep->customSettings / drop-with-reason / determinate-owns-it), the exact flake input + module import snippet, rollout order with verification commands (nix config show effective values), rollback story, risks.',
  },
  {
    scope: 't2-cache',
    task: 'GOAL: build the build-speed dossier: kill the 1h+ rebuilds. Confirmed causes: uv overlay overrideAttrs (version/src/cargoHash swap -> full local Rust build), a mise checkFlags override (cache-bust), cachix push doubly dead. Decision locked: drop absorbed overrides, push explicitly from forge-redeploy, and check community caches/overlays that ship prebuilt binaries. ' +
      'LOCAL READS (cite line numbers): ' + FORGE + '/overlays/default.nix (uv override block), the mise override (search ' + FORGE + '/modules for mise.nix overrideAttrs), ' + FORGE + '/flake.lock (nixpkgs rev + date), ' + FORGE + '/modules/home/programs/shell-tools/forge-tools.nix (forge-redeploy body). ' +
      'WEB RESEARCH (live): (1) current uv and mise versions in nixpkgs-unstable (search.nixos.org/packages + github nixpkgs) vs the versions our overrides pin — is the override obsolete; ' +
      '(2) community binary sources: does nix-community cachix cover uv/mise builds; any maintained community overlay/flake shipping current prebuilt uv (astral-sh official flake? uv2nix irrelevant here), mise flake with cache; charm/other caches; ' +
      '(3) correct cachix push discipline for a personal cache on darwin: push what (system closure? runtime-only paths?), exact commands post-switch, CACHIX_AUTH_TOKEN sourcing from an op-injected interactive env; ' +
      '(4) whether any flake input in our flake.lock has nixpkgs.follows that breaks its upstream cache (list inputs + follows from the lock). ' +
      'DOSSIER MUST CONTAIN: per-override verdict table (drop/keep+cache/replace-with-flake, with version evidence), the final substituters+keys set, the forge-redeploy push design (exact commands), expected impact, risks.',
  },
  {
    scope: 't2-shell',
    task: 'GOAL: build the shell-stack rebuild dossier (zsh init order, fzf, atuin, starship, PATH consolidation). Confirmed defects to design around: ZSH_AUTOSUGGEST_STRATEGY clobbered to (history) — fix requires strategy=[] plus a real array assignment in initContent AFTER autosuggestions sources; fzf-tab loads after autosuggestions at HM mkOrder 900 (contract violation); global bat/tree preview forced on all fzf-tab completions via use-fzf-default-opts; PATH triple-written (home.sessionPath + envExtra loop + profileExtra, 31 entries/17 unique, 2 nonexistent dirs); profileExtra never runs in zellij non-login panes; ZSH_COMPDUMP exported but compinit called without -d (80 orphan dumps); atuin history_filter drops 1-3 char + common commands. ' +
      'LOCAL READS (extract fully with line numbers): ' + FORGE + '/modules/home/programs/zsh/*.nix, ' + FORGE + '/modules/home/programs/shell-tools/{fzf,atuin,starship,shell}.nix, ' + FORGE + '/modules/common/toolchain-env.nix (PATH sources), ' + FORGE + '/modules/home/environments/*.nix (session vars). ' +
      'WEB RESEARCH (live, current Home Manager source + tool docs): (1) HM programs.zsh emission order TODAY (which mkOrder each block gets: envExtra/profileExtra/initContent tiers, autosuggestion/syntaxHighlighting/plugins emission points) — verify against home-manager master source; ' +
      '(2) fzf-tab canonical load position + config (Aloxaf/fzf-tab README current), scoped per-completion-tag preview pattern; (3) atuin current (v18+) zsh init flags, daemon mode status, history_filter semantics, recommended filter sets; (4) starship current version, vcs module status, sane timeout values; (5) zsh compinit -d + single-dump discipline under concurrent pane spawn. ' +
      'DOSSIER MUST CONTAIN: current-state extraction (every PATH writer, every init hook with its mkOrder, in one ordered table), the target init-order design (explicit mkOrder plan), config-ready fixes for each defect, atuin filter redesign, starship trim/add list, risks.',
  },
  {
    scope: 't2-nh',
    task: 'GOAL: build the rebuild-driver dossier: forge-redeploy wrapping nh v4 with dix/nvd diffs on Determinate Nix. ' +
      'LOCAL READS (cite line numbers): ' + FORGE + '/modules/home/programs/shell-tools/forge-tools.nix (current forge-redeploy: pkgs.nix pin in runtimeInputs causes eval-cores/lazy-trees unknown-setting warnings, sudo -n darwin-rebuild switch path), ' + FORGE + '/modules/darwin/settings/security.nix (TouchID/sudo posture). ' +
      'WEB RESEARCH (live, github.com/nix-community/nh + nixpkgs): (1) nh current version in nixpkgs-unstable, nh darwin switch semantics (flags, --hostname, how it invokes activation, sudo handling — does it self-elevate, does it respect an external nix binary on PATH), NH_FLAKE env var; ' +
      '(2) dix vs nvd current state (versions, output, which to prefer for closure diffs); (3) known nh-on-Determinate interactions (nh calling nix with Determinate settings; any issues with FlakeHub netrc or lazy-trees under nh); (4) darwin-rebuild vs nh activation differences worth knowing (does nh build then call darwin-rebuild activate, or switch-to-configuration directly). ' +
      'DOSSIER MUST CONTAIN: a compilable draft of the new forge-redeploy writeShellApplication body (check/build/switch modes preserved, nh-driven, Determinate nix on PATH — no pkgs.nix pin, cachix push hook point from t2-cache design, dix/nvd diff step), runtimeInputs list, migration notes, risks.',
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
    '(2) Write tool: create ' + taskFile + ' containing EXACTLY this task text (verbatim, nothing added): <<<TASK ' + lane.task + ' TASK>>> then create ' + schemaFile + ' containing EXACTLY this JSON: ' + JSON.stringify(PRODUCT_SCHEMA) + ' . Then Bash: test -s ' + taskFile + ' && test -s ' + schemaFile + ' . ' +
    '(3) Launch detached (ONE Bash call, exactly this shape): cd ' + FORGE + ' && codex exec -s read-only --skip-git-repo-check -c web_search="live" -c mcp_servers={} --ephemeral -o ' + reportFile + ' --output-schema ' + schemaFile + ' "Complete the task specified in ' + taskFile + '. Work from absolute paths. Final message must satisfy the output schema; put the full dossier in dossier_markdown." </dev/null >/dev/null 2>' + stderrFile + ' & ' +
    '(4) Poll with sequential bounded Bash calls (each its own tool call, e.g. sleep 45; test -s ' + reportFile + ' && echo READY || (pgrep -f "' + base + '-report" >/dev/null && echo ALIVE || echo GONE)). An absent report while the process lives is NORMAL — keep polling. Hard deadline ' + DEADLINE_MIN + ' minutes: alive past it with no report = WEDGED — pkill -f "' + base + '-report", relaunch once (repeat step 3); a second wedge or a GONE with empty report after one relaunch = failure: return ok=false with failure = last 3 lines of ' + stderrFile + ' . ' +
    '(5) On READY: Bash: jq -e .dossier_markdown ' + reportFile + ' >/dev/null (invalid json = treat as failure with stderr tail); then jq -r .dossier_markdown ' + reportFile + ' > ' + dossierMd + ' && cp ' + reportFile + ' ' + dossierJson + ' . ' +
    '(6) Compute MECHANICALLY: entries = jq "(.facts|length) + (.versions|length)" ' + reportFile + ' ; headline = "facts=" + (.facts|length) + " versions=" + (.versions|length) + " risks=" + (.risks|length) + " oq=" + (.open_questions|length) via jq string interpolation. ' +
    '(7) Return the receipt object: ok=true, report=' + dossierMd + ', entries, headline, failure="".'
}

// --- [COMPOSITION] ---------------------------------------------------------------------

phase('Dossier')
log('Launching ' + LANES.length + ' gpt-5.5 dossier lanes (threads 1+2)')

const roster = (await parallel(LANES.map((lane) => () =>
  agent(wrapperPrompt(lane), { label: 'gpt-5.5:' + lane.scope, phase: 'Dossier', schema: RECEIPT, model: 'sonnet', effort: 'low' })
    .then((r) => ({ lane: lane.scope, scope: [lane.scope], ...(r || { ok: false, report: '', entries: 0, headline: '', failure: 'wrapper skipped or died' }) }))
))).filter(Boolean)

const okCount = roster.filter((r) => r.ok).length
log('Dossier wave complete: ' + okCount + '/' + LANES.length + ' lanes ok')

return { roster, dossierHome: DOSSIERS, unmapped: roster.filter((r) => !r.ok).map((r) => r.lane) }
