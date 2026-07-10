# [G6_CROSS_APP_INTEGRATION]

The concert lens: ideas no single group owns, where two or more of the five frontier concerns compose into one estate surface. Each group's dossier proves a capability in isolation; this file names where those capabilities are already halves of one seam spelled twice. The estate law is the frame — `config.forge.*` read-only projection hinges fan one owner into many consumers (`docs/atlas/interconnection.md:5-17`), and new capability lands as a row on the owning table, never a new file (`docs/atlas/interconnection.md:43-62`). A cross-app idea earns its place only when the composed capabilities are individually verified in the group files; a synthesis over a phantom is itself a phantom. Every idea = thesis + composed capability rows (cited across groups) + unlock + estate anchors. No designs, no code — the implementing fable rules every shape.

## [01]-[THE_EVENT_SPINE]

Thesis: attention (G1/F01), the dual-receipt plane (G1/F02), session-fabric state (G4/F05), and the secrets-kernel classification (G5/F08) are four projections of one estate event stream, each spelled in its own vocabulary today. The attention feed carries `ts, event, session_id, cwd, term, wezterm_pane, zellij_session, zellij_pane, tty` rows folded by the collector (`g1 capabilities.md:7-9`, `mcp-launchers.nix:938-957`); the receipt fold accepts `k=v` TSV or one-line JSON and appends a JSONL sibling with `ts`/`surface` always present (`g1 capabilities.md:20`, `receipts.nix:8-26`); `forge-zellij state` emits `forge-zellij-state/v1` over sessions/tabs/panes (`g4 capabilities.md:16`, `ops.nix:242-250`); `setup-env.sh` classifies every Doppler source `live`/`snapshot`/`dead` with dual receipts (`g5 capabilities.md:63-65`, `setup-env.sh:91-104`). These are one stream: source, urgency, surface, pane identity, result. The unifying move owns that vocabulary once beside `forge-agents`, so every emitter — hook feed, WezTerm bell arm (`g1 capabilities.md:15`), tunnel supervisor (`tunnel-${name}` receipt kinds derived from `config.forge.ssh.hosts`, `g1 capabilities.md:22`), drift agents, the secrets kernel's dead-source verdict — publishes rows, and every renderer folds the same corpus.

Composed capabilities: G1 collector fold + receipt registry (`browsers.nix:66-133`, `:595`), G4 state envelope + the unprojected EXITED rows that make a `forge-zellij-state/v2` the resurrection-join seam (`g4 capabilities.md:23`, `ops.nix:140`), G5 kernel classification, the DuckDB query plane over the union (`g1 capabilities.md:25`, `g1 ecosystem.md:14`).

Unlock: "what needs me / what ran / what session is where / which credential is degraded" collapses to one queryable plane; a credential rise, a tunnel flap, and an agent needs-input rise are rows of one schema, not four log formats.

Anchors: `receipts.nix:8-26`, `mcp-launchers.nix:938-957`, `ops.nix:242-250`, `browsers.nix:66-133`, `setup-env.sh:91-104`, `docs/atlas/interconnection.md:64-72`.

## [02]-[THE_REMOTE_SURFACE_SPINE]

Thesis: `config.forge.ssh.hosts` is already the estate's deepest single-row fan-out, projecting into WezTerm `ssh_domains` named `SSH:<host>` (`g4 capabilities.md:10`, `wezterm/default.nix:58-66`), Yazi `[services.<host>]` SFTP rows pinned to the 1Password agent socket (`g4 capabilities.md:20`, `yazi/default.nix:348-360`), the `tunnel-${name}` receipt kinds (`g1 capabilities.md:22`), and the tunnel supervisors/pickers (`docs/atlas/interconnection.md:13`). F12 grows the row with mount-policy fields. The concert move makes one host row the complete remote-surface descriptor: WezTerm domain, Yazi VFS mount, tunnel supervisor, receipt kind, workspace picker entry, and — because Yazi's `ServiceSftp` has no cache field and cannot sink F12's cache-posture (`g4 capabilities.md:48`) — an rclone OS-mount lane whose `--vfs-cache-mode writes|full` is the only verified sink for that field (`g4 ecosystem.md:20-21`). One identity source (`ssh.nix:307` global `IdentityAgent`), every remote consumer folding the same rows.

Composed capabilities: G4 ssh-host rows (`ssh.nix:20-65`), WezTerm SSH-domain aliasing, Yazi VFS grammar, the rclone remote-mount survey; G1 tunnel receipt kinds joining the flap-history queries the F02 plane already admits.

Unlock: a second VPS lights up domain, mount, tunnel, receipt kind, and picker entry with zero per-app edits; cache posture lands on the rclone lane rather than distorting the Yazi schema.

Anchors: `ssh.nix:20-65`, `wezterm/default.nix:58-66`, `yazi/default.nix:348-360`, `browsers.nix` tunnel rows, `docs/atlas/interconnection.md:5-17`.

## [03]-[THE_REMOTE_WORKSPACE_MESH]

Thesis: `forge-workspace` bridges a generated WezTerm workspace into a live zellij session — it lists via `wezterm cli --no-auto-start list --format json`, spawns a slug-named session under a workspace, and persists a TSV receipt (`g4 capabilities.md:12`, `wezterm/default.nix:422-522`); `deck.lua` carries the outer-workspace-to-inner-session bridge through `session_args` (`g4 capabilities.md:13`, `deck.lua:248-249`). WezTerm already holds SSH domains from the host rows (§02). The fused F05×F12 idea: a remote-workspace row spawns the zellij session on the remote host through the WezTerm SSH mux domain, joined to the same host's Yazi VFS mount — the four-app mesh operating over the tunnel, one row projecting the picker entry, the SSH domain, the layout, the mount, and the acceptance row together. The verified constraint bounds it: `default_ssh_auth_sock` is nightly-only, so on WezTerm's last stable the mux server inherits ambient `SSH_AUTH_SOCK` rather than pinning the 1Password socket (`g4 capabilities.md:41`) — the remote-workspace row rides whatever the mux inherits, and confirming the packaged build is a gate, not an assumption.

Composed capabilities: G4 forge-workspace bridge + deck.lua session identity + WezTerm SSH domains + Yazi VFS; G1 workspace receipt kind joining the session state to the event spine (§01).

Unlock: `maghz` becomes a first-class workspace; the terminal IDE spans local and remote under one picker; session state over the tunnel joins the receipts plane.

Anchors: `wezterm/default.nix:422-522`, `deck.lua:34-35`, `deck.lua:248-249`, `ssh.nix:20-65`, `ops.nix:134-202`.

## [04]-[THE_PANE_CONTENT_CHANNEL]

Thesis: `zellij subscribe` with `--pane-id --scrollback --format json` is a verified, estate-untouched typed pane channel emitting NDJSON `pane_update {pane_id, viewport, scrollback, is_initial}` (`g1 capabilities.md:29-32`), and `dump-screen`/`list-panes --json` give one-shot capture over the same pane-id grammar shared with `focus-pane-id` (`g1 ecosystem.md:20`, `ops.nix:467`). The attention chain today posts a banner and focuses (`forge-agents focus` at `mcp-launchers.nix:1227`) but carries no pane context. The concert binding: a needs-input notification carries a pane preview drawn from the capture channel; the notification click routes through the terminal mesh (`docs/atlas/interconnection.md:70`) to focus the pane and optionally open its scrollback in the editor via `forge-edit.sh`; and where a synchronous answer is wanted, `alerter` returns a typed JSON reply (`--reply`, `g1 ecosystem.md:10`) that pane-id-addressed `write-chars` feeds back into the waiting agent — the notification becomes a question-and-answer channel rather than a one-way banner. This fuses G1 pane capture + G1 attention + G4 terminal mesh + G4 pane addressing; `alerter` admissibility (nixpkgs presence, TCC notification permission from a Nix profile, signing) is the open gate G1 already flags (`g1 ecosystem.md:57`).

Composed capabilities: G1 subscribe/dump-screen + attention focus + the `terminal-notifier`/`alerter` interaction-contract split (`g1 ecosystem.md:46`); G4 terminal mesh (`forge-yazi.sh`→opener→`forge-edit.sh`→editor registry, proven by `forge-terminal-accept.sh`).

Unlock: notification clicks carry the pane's live content; an agent's needs-input is answered from the desktop banner; a pane's scrollback opens in nvim as one mesh hop.

Anchors: `mcp-launchers.nix:1227`, `ops.nix:467`, `docs/atlas/interconnection.md:70`, F10 subscribe rows.

## [05]-[THE_SHARED_RENDER_BUS]

Thesis: zjstatus is the estate's one always-on render surface, and it renders more of the mesh than it is asked to. The collector already publishes `pipe_agents`/`pipe_quota` cells into every live session by exact pipe name (`g1 capabilities.md:11`, `mcp-launchers.nix:1084-1085`), the `{notifications}` widget on the pinned line is verified but unrendered (`g1 capabilities.md:42-43`), and the `{command_NAME}` widget runs a command on an interval with `static|dynamic|raw` rendermodes (`g1 ecosystem.md:30`). The concert move folds every app's health into bar cells through those two idle widgets: tunnel health from the ssh-host supervisors (§02), resurrection/session state from `forge-zellij-state/v2` (§01), language-parity health from G5's unbuilt fifth cell (`g5 capabilities.md:11-25`), and theme-proof status from `forge-theme-proof` (`g2 capabilities.md:11`). This is the terminal counterpart to the always-visible-box information design btop and glances embody (`g2 ecosystem.md:28`, `:27`) — one bar carrying attention, quota, tunnel, parity, and theme without leaving the multiplexer, every cell a fold over the event spine (§01), never a second event owner.

Composed capabilities: G1 zjstatus pipe/notify/command widgets + collector publish; G4 tunnel + session state; G5 parity health probe; G2 theme proof + the monitor information-design precedent.

Unlock: the estate's health is one glance; a new health signal is one more cell fold, not a new surface.

Anchors: `mcp-launchers.nix:1084-1085`, `zellij/config.nix:428-441`, `ops.nix:242-250`, `g5 capabilities.md` parity matrix, `theme.nix:593`.

## [06]-[THE_COMMAND_SPINE]

Thesis: `chords.nix` owns one physical-layer vocabulary projected into Karabiner JSON, Zellij KDL, zellij-forgot, hint ribbons, and WezTerm native rows, with register rows carrying `chord_id, consumer, physical_layer, mods, key, label, action, scope, projection_path` and optional CSI-u injection (`g4 capabilities.md:18-19`, `chords.nix:1126-1170`, `docs/atlas/interconnection.md:29-31`). G3's F13 introduces the first earned VS Code `keybindings.json` rail, with the Home Manager sink writing `key/command/when/args` rows and the full when-clause grammar available (`g3 capabilities.md:43-45`, `:65`). The concert move extends the single chord vocabulary with a `vscode` consumer projection, so one chord row lights up the physical layer, zellij, WezTerm, and the editor — cross-app muscle memory from one owner. The verified constraint shapes it: Home Manager writes `keybindings.json` wholesale with no sentinel-merge analog to the settings block (`g3 capabilities.md:29`, `:69`), so the editor projection takes full file ownership rather than coexisting with hand-edited bindings — a property the chord owner already has for its other consumers.

Composed capabilities: G4 chord register rows + multi-consumer projection; G3 keybindings API + when-clause grammar + the wholesale-write constraint.

Unlock: a chord means the same thing in terminal and editor; a new binding is one register row projecting into every consumer including VS Code.

Anchors: `chords.nix:1126-1170`, `chords.nix:499-505`, `g3 capabilities.md` §03/§04/§06, `docs/atlas/interconnection.md:29-31`.

## [07]-[THE_TOKEN_SPINE_AND_ITS_CONSUMER_GATE]

Thesis: `theme.nix` already projects one palette into WezTerm, Zellij, Yazi, Neovim, VS Code, and HTML artifacts, with `mkColor` rendering `{hex, r, g, b, triple, csv, rgba}` per row and `targetsProved` failing eval on any missing owner path (`g2 capabilities.md:9-13`, `theme.nix:18-31`, `:453-460`). F03 grows the owner with type-ramp, elevation, motion, and density tokens. The cross-app insight the design group cannot resolve alone is the consumer gate: the token axes are not uniformly consumable — most terminals do not animate, so `duration`/`cubicBezier` tokens have no WezTerm/Zellij/Yazi sink (`g2 capabilities.md:74` gap), while the type ramp reaches the terminal only as a fonts.nix metrics row-group mapping steps to fixed cell sizes, never Utopia's viewport-fluid `clamp()` (`g2 capabilities.md:38`, `fonts.nix:105-126`). The integration ruling: each token axis projects only to the surfaces that verifiably consume it, and the html-studio dashboard (F07) is the single surface consuming every axis — color, type, elevation, motion, density — which makes the dashboard the token system's own proof surface, not merely a reader of it. WCAG contrast is deterministic over the `base24Slots` hexes, so per-role-pair proofs are a pure eval-time fold gating the build like `targetsProved` (`g2 capabilities.md:64`, `:31`).

Composed capabilities: G2 theme projector + fonts metrics + eval-time contrast + html-studio contract; the all-app projection web (`docs/atlas/interconnection.md:23-27`) as the consumer-reality map.

Unlock: token growth lands per-surface-gated instead of anticipatory; WCAG proofs become flake checks; the dashboard renders the full token system as its acceptance.

Anchors: `theme.nix:18-31`, `theme.nix:453-460`, `fonts.nix:105-126`, `docs/atlas/interconnection.md:23-27`, `.claude/skills/html-studio/SKILL.md:41-42`.

## [08]-[THE_UNION_DASHBOARD]

Thesis: F07 renders an html-studio estate dashboard from owner JSON, and `forge-update-board` proves the observation-only pattern — one row per family folded from existing receipts and local metadata with zero mutation (`g2 capabilities.md:16`, `forge-tools.nix:1994-2016`). The capstone concert unions every group's registers into one page: attention `agent-state.json` + the receipts JSONL corpus (G1), `palette.json` + `coverage.json` (G2), the VS Code roster + `forge-vscode doctor` verdicts (G3), `config.forge.ssh.hosts` + `forge-zellij-state` + workspace receipts (G4), the parity matrix + marketplace projection + secrets-kernel verdicts (G5). Web Components + CSS variables + Canvas/SVG + `<dialog>` cover tiles, cascade, charts, and drill-down inside the one self-contained file, and the inert JSON payload script folds the same register JSON the page renders — the dual-consumer shape where agents read the typed facts the human sees (`g2 capabilities.md:55-58`, `:66`). Glances joins as a live observation feed through `--stdout-json` for the page and `--enable-mcp` for agents (`g2 ecosystem.md:27`), and the DuckDB query plane (§01) backs the historical tiles. This is the single pane of glass across all five frontier concerns.

Composed capabilities: every register seam (`docs/atlas/interconnection.md:64-72`); G2 html-studio + dashboard precedent + glances one-model-many-egress; G1 receipts query plane.

Unlock: "what is my machine doing" as one designed surface spanning attention, theme, editor, session, and language health; page and agents consume identical JSON.

Anchors: `forge-tools.nix:1994-2016`, `docs/atlas/interconnection.md:64-72`, `.claude/skills/html-studio/SKILL.md:41-42`, `browsers.nix:595`, `theme.nix:826-840`.

## [09]-[THE_FLOAT_REGISTRY_AND_NEW_PANE_TYPES]

Thesis: four floating-surface mechanisms exist independently across the mesh — WezTerm singleton floats keyed in `wezterm.GLOBAL.deck_floats`, resolved and refocused before respawn (`g4 capabilities.md:14`, `deck.lua:88-156`); Zellij floating macro panes dispatched by `forge-zellij` (`ops.nix:449-487`); the Yazi popup runtime toggled through `zellij.ids.yaziToggle` (`docs/atlas/interconnection.md:31`); and `viddy` receipt/git floating panels already running as `forge-zellij` watch rows (`g1 capabilities.md:24`, `ops.nix:22-40`). The concert move owns one float-policy vocabulary — surface, singleton-vs-spawn, dismiss behavior, content source — so a new float is one row across all four apps, and it admits genuinely new pane types the capabilities now support: a peek pane backed by `zellij subscribe` streaming a target pane's content (§04), a receipt pane backed by `forge-receipts --follow` (`g1 capabilities.md:23`), a parity-probe pane backed by G5's health cell. The `terminal-notifier` click and the chord spine (§06) both target the same registry, so a notification and a keybinding open the same float.

Composed capabilities: G4 WezTerm/Zellij/Yazi float mechanisms; G1 subscribe pane channel + `viddy` panels + `forge-receipts --follow`; G5 parity probe as float content.

Unlock: floating surfaces become a parameterized registry instead of four hand-wired mechanisms; a new float — including new content-backed pane types — is one row.

Anchors: `deck.lua:88-156`, `ops.nix:22-40`, `ops.nix:449-487`, `docs/atlas/interconnection.md:31`, F10 subscribe rows.

## [10]-[THE_INTEGRATION_LAYER_OWNER]

Thesis: the cross-app orchestration kernels are scattered across their single-app config owners — `forge-workspace` lives in `wezterm/default.nix:422-522`, `forge-zellij` in `zellij/ops.nix`, `forge-agents` in `shell-tools/mcp-launchers.nix`, `forge-yazi.sh`/`forge-edit.sh` in `scripts/terminal.nix`, `fmt` in `scripts/fmt.nix`, `forge-receipts` in `shell-tools/browsers.nix`. Each kernel spans two or more apps yet is housed with one of them, so the integration layer has no home and its seams (the terminal mesh, the attention chain, the receipts plane) are proven by scattered acceptance rather than one owner. The organizational thesis — subject to the estate's extend-in-place law, which admits a split only for a genuinely distinct concern (`docs/atlas/interconnection.md:43-45`) — is that these cross-app kernels form one coherent surface distinct from single-app configuration: the layer that binds wezterm+zellij+yazi+nvim into one system. `modules/home/scripts` is the natural owner, growing the terminal-mesh acceptance (`forge-terminal-accept.sh`) to cover the whole spine — attention, receipts, session, and remote surfaces — as one acceptance rather than per-app fragments. The counterweight is real: a premature split fragments what the owner tables deliberately co-locate, so the ruling turns on whether the integration layer is one concern or several.

Composed capabilities: the observed scatter across `mcp-launchers.nix`, `ops.nix`, `wezterm/default.nix`, `scripts/terminal.nix`, `browsers.nix`, `fmt.nix`; the estate owner-table law and the terminal-mesh acceptance seam (`docs/atlas/interconnection.md:64-72`).

Unlock: the integration layer has one home and one acceptance; the four-app mesh is proven as a system, not as five independent configs that happen to interoperate.

Anchors: `docs/atlas/interconnection.md:43-62`, `scripts/fmt.nix:21`, `wezterm/default.nix:422-522`, `ops.nix:134-202`, `mcp-launchers.nix:938-957`.

## [GAPS]

- The event-spine schema (§01) has no field census: the four contributing vocabularies (attention feed, receipt envelope, `forge-zellij-state/v1`, secrets classification) must have their live field sets captured so the unified row is derived from real keys, not invented — the same field-inventory gap G1 names for F01 (`g1 capabilities.md:49`), now widened to session and kernel emitters.
- Remote-workspace auth (§03) is unproven end to end: whether the packaged WezTerm mux inherits an `SSH_AUTH_SOCK` that reaches the 1Password agent over the tunnel, or whether the nightly-only `default_ssh_auth_sock` gap blocks a remote zellij spawn under the SSH domain (`g4 capabilities.md:41`, `:62`).
- The answer-channel hop (§04) depends on `alerter` admissibility (nixpkgs derivation, TCC notification permission from a Nix profile, signing) — unresolved in G1 (`g1 ecosystem.md:57`) — and on whether `zellij action write-chars` (or equivalent pane-write) reliably injects into a waiting agent's read loop without racing its prompt.
- The render-bus fold (§05) inherits G1's two open proofs: whether a destination-less `zjstatus::notify::` broadcast reaches both bar instances or needs targeted `--plugin` delivery (`g1 capabilities.md:48`, `g1 ecosystem.md:63`), and the `{command_NAME}` key roster beyond format/rendermode for interval-driven health cells.
- The command spine (§06) needs the language-block precedence and wholesale-write semantics of `keybindings.json` confirmed live before a `vscode` chord consumer is minted — the same Home Manager write-path gap G3 flags (`g3 capabilities.md:69`).
- The consumer gate (§07) rests on unverified motion/density consumer reality: no evidence yet that any of wezterm/zellij/yazi/nvim honors a duration or density token, so the per-surface projection map is provisional until the sinks are probed (`g2 capabilities.md:74-75`).
- The union dashboard (§08) has no settled tile vocabulary or refresh contract across heterogeneous register cadences (eval-time JSON vs live receipts vs glances SSE), and the glances `/mcp` payload shape is uncaptured (`g2 ecosystem.md:46`).
- The float registry (§09) awaits G1's live `subscribe` probe matrix — frame cadence, multi-pane interleaving, `pane_closed` on session death, backpressure — before a streaming peek-pane type is more than a proposal (`g1 capabilities.md:47`).
- The integration-layer split (§10) is an unresolved ruling, not a decision: whether the cross-app kernels are one concern the estate law admits as a focused surface, or a co-location the owner tables intend — the implementer must weigh the fragmentation risk against the missing single acceptance owner.
