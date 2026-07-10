# [FORGE_FRONTIER_IDEAS]

The estate's ambitious implementation frontier: the structural wins the rebuild campaign proved possible, the cross-surface integrations those wins opened, and the growth directions each app owner now admits. Every card is a one-session implementation target for a world-class adversarial pass — deep over wide, verified capability over speculation. Cards cluster into dossier groups (`G1`–`G5`); each group's research corpus lives in `DOSSIER/` and grounds the group's implementation pass — one fable 3-pass (initial → critique → red-team) per group, consuming the dossier in full, never mini-steps.

OPEN contains `ACTIVE` work and `QUEUED` next-up work in logical sequence; `BLOCKED` keeps open but non-actionable work; `CLOSED` separates finished `COMPLETE` items from unimplemented `DROPPED` items. `Ripple` names the origin or counterpart card a cross-folder entry pairs with.

## [01]-[OPEN]

[F01]-[QUEUED]: One attention fabric across every surface. `G1`

- Capability: the attention chain (hook feed → collector → focus router → notification click) and wezterm's bell→attention arm are one concern spelled twice; zjstatus cells, wezterm toasts, and terminal-notifier posts are three renderers of one implicit event stream.
- Shape: one attention-event vocabulary (source, urgency, pane identity, receipt) owned beside `forge-agents`; every emitter (hooks, bell arm, tunnel supervisor, drift agents) publishes rows; every renderer (zjstatus, toast, notification, dashboards) folds the same stream through per-source policy rows.
- Unlocks: per-source notification policy, attention history queries, cross-app "what needs me" as one command.
- Anchors: `shell-tools/mcp-launchers.nix` collector, `wezterm/deck.lua` bell arm, `shell-tools/receipts.nix` grammar, interconnection §RUNTIME_SEAMS.

[F02]-[QUEUED]: Receipts as a queryable estate plane. `G1`

- Capability: the dual-receipt grammar (TSV + JSONL, `ts/surface/result` keys) spans the kernels; `receipts.nix` owns the emit fold; `forge-receipts` browses registry-derived sources.
- Shape: one query surface — DuckDB over the JSONL corpus — with typed per-surface projections (failures-last-24h, switch history, tunnel flaps, acceptance trends) as `forge-receipts` verbs; the numeric-inference row (`tonumber?` coercing all-digit strings) resolves at the fold with typed row admission.
- Unlocks: agents diagnose estate history without log spelunking; "what ran" vs "what docs claim" becomes a query.
- Anchors: `shell-tools/receipts.nix`, `browsers.nix` receipt rows, DuckDB overlay, DUAL_RECEIPTS law.

[F10]-[QUEUED]: Agent-readable pane capture as a `forge-zellij` verb. `G1`

- Capability: zellij's subscribe stream with `--pane-id --scrollback --format json` is verified real — a typed pane-content channel no estate surface exploits.
- Shape: a `forge-zellij peek` verb returning pane scrollback as a JSON envelope, joined to the attention fabric so "show me what that waiting agent's pane says" is one command.
- Unlocks: notification clicks carry context previews; acceptance rows assert on live pane content without `dump-screen` temp files.
- Anchors: `zellij/ops.nix` graph kernel, F01 vocabulary, receipts grammar.
- Ripple: F01.

[F11]-[QUEUED]: zjstatus transient notifications widget. `G1`

- Capability: the pinned zjstatus ships a `{notifications}` widget the bars never render; the collector already computes attention transitions.
- Shape: the collector publishes transition events to the widget pipe beside its cells — in-bar transient toasts for needs-input rises without leaving the terminal.
- Unlocks: attention visibility while notifications are muted; one more renderer on the F01 stream.
- Anchors: `mcp-launchers.nix` collector pipes, zellij config bars.
- Ripple: F01.

[F03]-[QUEUED]: The theme owner as a full design system. `G2`

- Capability: `theme.nix` carries the recursive color-record projector; consumers are proven private-hex-free; roles bind only to source-verified group names; the fonts owner carries metrics rows.
- Shape: the owner grows typographic scale rows (type ramp, letter-spacing, line-height), elevation/depth tokens, motion/duration tokens, and per-surface density rows — projected to wezterm, zellij, yazi, nvim, vscode, and HTML artifacts from one vocabulary; color theory lands as derivation (contrast-ratio assertions per role pair at eval). Tokens land only with their first consumer — the anticipatory-rows rejection is already paid law.
- Unlocks: WCAG-contrast proofs as flake checks; one-row theme variants; UI/UX passes grounded in tokens instead of taste.
- Anchors: `modules/home/theme.nix` projector, `fonts.nix` metrics, dataviz skill palette law.

[F07]-[QUEUED]: Estate dashboards from owner data. `G2`

- Capability: every owner projects JSON registers — `forge/registers/*.json`, `palette.json` (now carrying icons + syntax backgrounds), fonts manifest, receipts JSONL, `agent-state.json`.
- Shape: an html-studio estate dashboard generated from those artifacts — attention, quota, tunnel health, acceptance history, theme proof — as a `forge-*` verb rendering a self-contained page under the F03 token system.
- Unlocks: "what is my machine doing" as one designed surface; agents read the same facts as typed JSON.
- Anchors: registers seam (interconnection §RUNTIME_SEAMS), html-studio skill, dataviz law, F02 query plane.
- Ripple: F02, F03.

[F13]-[QUEUED]: VS Code flagship follow-ons. `G3`

- Capability: the flagship foundation is landed (F04 closed): 365-token projection over builtin Dark Modern, 26-row vetted extension rail with doctor/sync receipts, three-repo settings universalized under per-key merge law, the settings-scope truth ladder recorded in-module.
- Shape: the named residuals as one leg — vetted product-icon-theme admission, the 40-extension extras cull (operator-decided, doctor-ledgered, incl. the live double-ruff), workspace-file slimming in Forge/Rasm/Maghz now that user-level rows own the base, and the keybindings.json rail when the first custom binding earns it.
- Unlocks: workspace files shrink to genuine per-repo intent; the flagship pattern becomes replicable.
- Anchors: `apps/vscode/{appearance,extensions}.nix`, `overlays/manifest.nix` rows, the masterpiece fixlogs.

[F05]-[QUEUED]: Zellij/wezterm session fabric unification. `G4`

- Capability: wezterm carries reload-surviving singleton floats and structured attention; zellij owns sessions/tabs with the mode-row table; `forge-workspace` bridges them; the terminal mesh is acceptance-proven at 12 PASS.
- Shape: one session-fabric vocabulary — workspace rows carrying zellij session identity, wezterm domain, float policy, and chord entry — so a new workspace is one row projecting the picker entry, ssh domain, layout, and acceptance row together.
- Unlocks: the remaining hand-seams between pickers, layouts, and domains die; session state joins the receipts plane.
- Anchors: `config.forge.ssh.hosts` row pattern, `zellij/ops.nix`, `wezterm/deck.lua` registry, chords rows.

[F12]-[QUEUED]: The VFS fabric as an estate surface. `G4`

- Capability: yazi's `vfs.toml [services]` projects sftp mounts from `config.forge.ssh.hosts` with the 1Password identity agent pinned — remote filesystems became one registry row.
- Shape: the ssh-host row grows mount-policy fields (paths, read-only, cache posture) so every VFS-capable consumer folds the same rows; `forge-workspace` gains remote-workspace entries riding the same identity.
- Unlocks: maghz volumes as a first-class yazi surface; a second VPS mounts with zero yazi edits.
- Anchors: `yazi/default.nix` vfs projection, `shell-tools/ssh.nix` registry, interconnection §[01][03].
- Ripple: F05.

[F06]-[QUEUED]: Estate-language parity table. `G5`

- Capability: C# integration is landed (Roslyn identity shared with the lsp-marketplace row, csharpier pinned to the profile binary matching the `fmt` cs lane); the marketplace projection derives identity from cmd rows.
- Shape: a per-language parity table — LSP row, formatter lane, treesitter grammar, lint lane, health probe — asserted complete for every language the estate carries; a missing cell fails a flake check.
- Unlocks: a new language is one parity row; editor, harness, and formatter never diverge on tool identity.
- Anchors: nvim `default.nix` grammars, `fmt.nix` `_LANE` vocabulary, `.claude/lsp-marketplace/` rows.

[F08]-[ACTIVE]: `.claude/` scripts at kernel law. `G5`

- Capability: hooks are hardened (secret umask, single-flight refresh, PATH-resolved dispatch); the Phase A smoothing track holds the unification mandate over `.claude/` scripts and the terminal-mesh integration.
- Shape: `setup-env.sh` decomposed into row-driven resolver folds with dual receipts and shape-asserted admissions; workflow scripts audited against the determinism law; whatever Phase A leaves becomes this card's residue.
- Unlocks: the harness's own substrate proven at the bar it enforces on the estate.
- Anchors: `.claude/hooks/setup-env.sh`, hooks-builder skill, workflow-determinism review rule.

## [02]-[CLOSED]

[F04]-[COMPLETE]: VS Code flagship foundation landed through deployed generations — owned design system, extension rail, three-repo universalization; residuals carry as F13.
[F09]-[COMPLETE]: Cross-app integration pass absorbed into the Phase A estate-wide smoothing track (one fable writer + its cold critique and red-team spawns).
