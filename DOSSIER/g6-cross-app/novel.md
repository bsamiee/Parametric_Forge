# G6 Cross-App — Novel Lens

Interaction models no single group's charter owns and no ordinary dotfiles estate can build, because each composes the estate's agent-first substrates in concert: the attention feed (`agent-attention.sh` JSONL), the collector fold (`forge-agents/v1`), typed pane streaming (`zellij subscribe`), the dual-receipt corpus (TSV+JSONL, registry-discovered), the theme projection web (`palette.json` roles), the chord register, the tunnel-derived host rows, and the Yazi in-process VFS. Every idea below cites the verified capabilities it stands on; a claim without a source row is a phantom the curation deletes. These are direction concepts for the F09 estate-wide smoothing track, not designs — the implementer rules every shape.

## [01]-[TWO_WAY_ATTENTION_LOOP]

Today attention terminates in a one-way pointer: a `needs_input` rise posts a grouped desktop banner whose click routes to `forge-agents focus` (`mcp-launchers.nix:1090-1100`), and the operator walks to the pane. The novel composition makes the notification itself carry the pane and return the answer.

- On the `needs_input` rise the collector already detects (latest feed event `Notification`, inside the one-hour window, tty still hosts an idle `claude` lane — `mcp-launchers.nix:938-957`), key `zellij subscribe --session <zellij_session> --pane-id terminal_<zellij_pane> -s N -f json` off the attention row's own `zellij_session`/`zellij_pane` fields (`agent-attention.sh` schema, `interconnection.md:68`) to capture the exact pane's last N scrollback lines (`zellij subscribe` NDJSON `pane_update{pane_id, viewport, scrollback}`, g1 cap [03]).
- Fold that tail into a blocking `alerter --message <tail> --reply` (g1 ecosystem alerter: the process exits when the user interacts, `--reply` captures text, `--json` returns it typed), and write the operator's reply straight back to the waiting pane through `zellij action pipe` targeting that session, or by CSI-u injection the chord owner already performs (`chords.nix:1126-1170`).
- Novelty: the notification becomes a synchronous typed answer channel that carries the pane's actual question. No dotfiles estate has this because none joins hook-derived attention state, typed pane streaming, and a blocking-reply alert into one loop. The agent-first posture is load-bearing — the collector's `needs_input` semantics are what make "which pane, right now" answerable.
- Class split by event, not by tool (g1 ecosystem notification-class pattern): a `needs_input` rise routes to `alerter` (question/answer); a `result=error` redeploy receipt routes to `terminal-notifier` grouped banner; a `tunnel-maghz` down receipt routes to `ntfy publish` cross-device so it reaches the phone when the operator is away from the Mac (g1 ecosystem ntfy `Click`/`Priority`). One converged stream (`mcp-launchers.nix:938-1100`), one egress-selection policy keyed on receipt kind and feed event.

## [02]-[RECEIPTS_AS_LIVE_PUSH_BUS]

The receipt plane is pull-only today — written on the EXIT trap, queried after the fact. The novel move is to make every terminal receipt a push event the instant it lands.

- `forge-receipts --follow` already tails the corpus (`browsers.nix:233-246`); the unused `zjstatus::notify::<message>` pipe renders the last message on the `{notifications}` widget across every live session and auto-hides after `notification_show_interval` (g1 cap [04], verified unused estate-wide).
- Compose a thin fold: `forge-receipts --follow --failures --json` piped into `zellij pipe "zjstatus::notify::<kind> FAIL <detail>"` (no newlines, g1 ecosystem spelling) surfaces any `result=error` from any of the twelve-plus registry kinds (`browsers.nix:66-133`) in the bar in real time, estate-wide, with palette `roles.state` color via `#[fg=$red]` directives (theme projection web, `interconnection.md:23-27`).
- Novelty: the receipt corpus becomes both the durable query surface (`forge-receipts --pick`, DuckDB) and a live push source, with zero new event owner — `{notifications}` joins as one more renderer on the stream the collector already publishes to. Ordinary estates cannot do this because they have no dual-receipt law giving every rail a machine-readable emission on a fixed schema.

## [03]-[ESTATE_TIMELINE_FEDERATION]

The estate spans two hosts (`macbook`, `maghz`) but no surface shows their operational history as one timeline. The tunnel substrate and the dual-receipt law already make this a fold, not an integration.

- `config.forge.ssh.hosts` derives `tunnel-<name>` receipt rows and `forge-receipts` discovers sources from those rows (g1 cap [02], `browsers.nix:595`); the WezTerm `SSH:<host>` domains reach maghz over the same host rows (g4 cap [03], `wezterm/default.nix:58-66`).
- Run `forge-receipts --json` on maghz over the standing SSH domain, fold local Mac receipts and remote VPS receipts with DuckDB `read_json([...glob], filename = true, union_by_name = true)` — `filename` as virtual provenance column since 1.3.0, `union_by_name` absorbing per-kind schema drift (g1 ecosystem DuckDB), keyed on the shared `ts`/`surface` envelope keys (nix-doctrine dual-receipt law).
- Project the fold twice from one query (the Glances one-model-many-egress shape, g2 ecosystem): an html-studio timeline artifact for the operator (inert JSON payload seam, g2 cap [06]) and MCP/`--stdout-json` for agents reading the same typed rows.
- Novelty: a single agent-and-human timeline across both hosts of the estate, keyed by one envelope schema. Impossible without the dual-receipt law, tunnel-derived host rows, and DuckDB `union_by_name` — the three that make cross-host receipts a homogeneous corpus.

## [04]-[RENDERED_CONTRAST_TELEMETRY]

The estate proves WCAG contrast at eval over palette hex (`base24Slots` enumerates every role hex, math deterministic — g2 cap [03]) but never proves what the terminal actually rendered. Pane capture closes the loop.

- `zellij action dump-screen --pane-id <p> --full --ansi` captures real SGR-styled pane output (g1/g4 cap); parse the emitted foreground/background SGR pairs against the resolved `palette.json` roles (theme projection web) and score each observed pair with the same WCAG 2.2 math the eval-time assertion uses, plus an advisory APCA score via Color.js `contrast(bg, "APCA")` (g2 cap [03]).
- Render into an html-studio dashboard (g2 cap [06]) showing the actual color pairs an agent's output produced with pass/fail against the AA `4.5:1` gate and the APCA advisory.
- Novelty: closes the loop between eval-time contrast assertion and runtime-rendered reality — "contrast telemetry" over what agents literally emit. No theme system has this because none captures its own terminal output as structured color data; the estate can because `dump-screen --ansi` yields parseable SGR and the palette owner already computes the math.

## [05]-[FORENSIC_SESSION_REPLAY]

The attention feed JSONL, the receipts JSONL, and `zellij subscribe` scrollback all carry `ts` and pane/session keys — three substrates that share a spine but are never joined chronologically.

- Fold the attention corpus (`agent-attention.jsonl` rows: `ts, event, session_id, cwd, wezterm_pane, zellij_pane, tty`) and the receipts corpus (registry-discovered JSONL siblings) with DuckDB `json_tree`/`json_each` lateral joins exposing `key, value, path` (g1 ecosystem), keyed on `session_id`/`ts`, to reconstruct "what the agent did and what fired" as one ordered stream.
- Optionally enrich with captured pane scrollback at each event `ts` for the pane the event names (`zellij subscribe` or `dump-screen`), giving the reconstructed timeline the actual on-screen context per event.
- Render as an html-studio timeline artifact (g2 cap [06]).
- Novelty: post-hoc forensic replay of an agent session across event, receipt, and pane substrates — genuine observability an ordinary estate cannot assemble because it has neither a structured attention feed nor a homogeneous receipt corpus to join.

## [06]-[RESURRECTION_WITH_CAUSE]

`forge-zellij` parses EXITED rows (`ops.nix:140`) but `state` emits only live sessions (g4 cap [01] ADDED); Zellij serializes every session every second (g4 cap [02]). The resurrection picker shows what died but never why.

- Extend to `forge-zellij-state/v2`: for each resurrectable (EXITED) session, join the last receipt rows written from panes that shared its cwd (receipts corpus DuckDB query keyed on the `cwd` field present in both the attention feed and workspace receipts), so the picker row reads "foo — last: forge-redeploy FAIL 3m ago" instead of bare "EXITED foo".
- Novelty: resurrection becomes diagnostic, not merely restorative. The estate can because both the attention feed and receipts carry `cwd`, making the session-to-history join a key match; a tmux-based estate (none of the surveyed session managers drives Zellij, g4 ecosystem) has no such corpus.

## [07]-[CHORD_AS_ATTENTION_CONTROLLER]

The chord vocabulary drives pane/window management today (`chords.nix` register rows carry `chord_id, consumer, action, scope`, CSI-u injection — g4 cap [01]). Extending the `consumer` class to route agent attention makes the physical keyboard a first-class attention controller.

- A new chord `consumer` resolves the most-recently-`needs_input` session from the collector's `agent-lanes.json` projection (`ops.nix:90`, `mcp-launchers.nix:938-957`) and fires `forge-agents focus` on it — one keypress jumps to whatever needs the operator, over the collector's live state rather than a static pane id.
- A second arm resolves the focused pane's cwd (`list-panes --json`) and launches a scoped Claude Code workflow or receipt query there.
- Novelty: the chord system currently addresses panes; addressing the collector's attention state turns the keyboard into an attention router. The single-owner chord register (projecting to Karabiner/Zellij/WezTerm from one vocabulary, `chords.nix:499-505`) is what lets one new row reach every physical layer at once.

## [08]-[UNIFIED_KEYBOARD_GRAMMAR]

G3 lands the first `keybindings.json` rail (g3 cap [03]); `chords.nix` owns the estate chord vocabulary as register rows with `scope` and `action` (g4 cap [01]). Today the terminal multiplexer and the editor are two disjoint keymap worlds.

- Project the subset of chord register rows whose `scope` matches editor actions into VS Code `keybindings.json` through the same register source, mapping `{key, mods}` to VS Code's `Cmd+`/`Shift+`/`Alt+` chord spelling and gating with `when`-clause contexts (`editorTextFocus`, `resourceLangId` — g3 cap [04]).
- Novelty: one owner drives keyboard grammar across multiplexer AND editor, so a chord change ripples to both. The estate can because the chord register already renders `{key, mods}` to multiple physical layers; adding VS Code is one more projection target, not a second keymap authority. The G3 keybindings rail is wholesale-written by Home Manager (g3 cap [01]), so it accepts a generated projection cleanly.

## [09]-[REMOTE_STATE_THROUGH_VFS]

Yazi's `vfs.toml` exposes `sftp://maghz` from the same host rows (g4 cap [04]); the estate writes typed artifacts to fixed XDG projection paths (`interconnection.md:71`). Remote estate state becomes browsable through the same file UI as local, with zero new tooling.

- The maghz host's own `forge/registers/*.json` and receipt logs become previewable through `sftp://maghz//...` in Yazi (`reveal sftp://maghz//...`, g4 cap [04]), with the theme owner's `forge-dracula.tmTheme` driving the syntect preview (theme projection web — Yazi points syntect at the owner tmTheme, `interconnection.md:27`).
- Novelty: remote agent state inspected through the identical themed file interface as local state, single identity source (`config.forge.ssh.hosts` fans to both the SSH domain and the VFS row). No extra mount, no second credential path — the 1Password `identity_agent` already pins both (g4 cap [01]).

## [10]-[HEALTH_CELL_IN_THE_BAR]

F06's fifth parity cell (health) is unbuilt everywhere (g5 cap [02]); zjstatus ships a `{command_NAME}` widget with `command_NAME_interval`/`_rendermode` (g1 ecosystem). The two compose into an always-visible language-harness health row.

- A `{command_parity}` widget runs a probe over the five parity owners (LSP `cmd` liveness, formatter lane presence, grammar, lint, marketplace identity — g5 cap [02] matrix), rendering a compact per-language glyph row with palette-derived `#[fg=$state]` directives (theme, g1 ecosystem style spellings), `RunCommands` permission already granted to zjstatus (g1 cap [04]).
- Novelty: harness health surfaces as an always-visible status cell, not a flake-check-only assertion — the operator sees a broken LSP the moment the bar renders. The estate can because the parity cells are declared rows a probe can enumerate and zjstatus already owns the `RunCommands` grant.

## [11]-[BELL_AS_ATTENTION_EMITTER]

The WezTerm bell arm is already structured attention: `audible_bell = "Disabled"`, the `bell` event writes a receipt and toasts only when the bell is outside the focused view (g1 cap [01], `wezterm/events.lua:52-58`). Bridging it into the attention feed gives non-Claude processes the same routing.

- Any long-running command that ends with `\a` (a build, a test run, a `forge-redeploy`) becomes an attention-feed emitter: the WezTerm `bell` event appends an attention row keyed to its `wezterm_pane`, and the collector's fold (`mcp-launchers.nix:938-957`) treats it like a hook `Notification`, routing `forge-agents focus` (tty-ancestry terminal resolution, `mcp-launchers.nix:1227`) and the notification chain.
- Novelty: the OS-level terminal bell — a signal every process can raise — enters the structured attention fabric, so attention routing is no longer Claude-hook-exclusive. The estate can because the bell arm already writes a dual-envelope receipt (g1 cap [01]) that the feed schema can absorb.

## [12]-[LIVE_THEMED_AGENT_WATCHER]

`viddy` floating panels render receipt/git queries by re-polling (`ops.nix:22-40`); `zellij subscribe -f json` is a push stream never used in the estate (g1 cap [03], verified absent). A structured watcher beats re-polling.

- `zellij subscribe --pane-id <agent-pane> -f json --ansi` streams an agent pane's output; a fold classifies new lines (error/warn/ok) and re-emits them into a floating zellij pane colored by palette `roles.state` (theme), giving a "tail the agent, highlight the failures" surface driven by push, not interval re-render.
- Novelty: structured pane streaming feeding a themed live view — lower latency and lower cost than viddy's re-poll, and content-aware because the stream is NDJSON, not a screen scrape. The estate can because `subscribe` targets a named session from an outside shell (g1 cap [03]) and the palette owner supplies the state colors.

## [GAPS]

- `zellij subscribe` live cadence is unprobed (inherited g1 gap): NDJSON frame rate under heavy output, `--session` targeting from a fully detached shell, and backpressure toward the producing pane — the two-way loop [01] and the watcher [12] both depend on subscribe behaving from an outside collector shell.
- `zjstatus::notify::` broadcast reach is unproven (inherited g1 gap): whether a destination-less notify hits both bar instances (`zjstatus` and `zjstatus-hints`) or needs targeted `--plugin` delivery — gates the live push bus [02] and the health cell [10] render.
- `alerter` admissibility is unresolved (inherited g1 gap): nixpkgs presence, notarization, and TCC notification-permission behavior from a Nix profile decide whether the blocking-reply arm of [01] can exist at all; ntfy estate fit (nixpkgs identity, Doppler-backed auth row, receive-side client) gates the cross-device egress.
- Cross-host `forge-receipts --json` over the maghz SSH domain [03] is untested for the remote binary's presence and the tunnel `state=up` precondition the acceptance harness already gates (`rails-and-contracts.md:26`); confirm the remote emits the same envelope schema before folding.
- SGR-pair extraction from `dump-screen --ansi` [04] has no verified parser path: whether the ANSI dump resolves palette-indexed colors to hex or emits raw index codes needing a palette-index→hex map from the theme owner.
- VS Code keybinding projection [08] needs the wholesale-write semantics of `programs.vscode.profiles.default.keybindings` confirmed (g3 gap) and a `{key, mods}`→VS Code chord spelling map that survives macOS modifier differences.
- The chord `consumer` extension [07] and bell emitter [11] both write to the attention feed; the feed row schema carries no `source` or `urgency` key today (inherited g1 gap), so a unified admission schema must be derived from the real emitter shapes (hook feed, WezTerm bell receipt, chord press) before non-Claude sources can join without severing the collector fold.
- Receipt-corpus `cwd` join for resurrection-with-cause [06] assumes `cwd` is present and normalized identically in the attention feed and workspace receipts; the envelope drift census (inherited g1 gap) must confirm key parity across kinds before the join is reliable.
