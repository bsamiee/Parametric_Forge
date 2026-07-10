# [FORGE_FRONTIER_IDEAS]

The estate's ambitious implementation frontier: the structural wins the rebuild campaign proved possible, the cross-surface integrations those wins opened, and the growth directions each app owner now admits. Every card is a one-session implementation target for a world-class adversarial pass — deep over wide, verified capability over speculation — feeding the per-app agent-facing README charters and the next dispatched wave.

OPEN contains `ACTIVE` work and `QUEUED` next-up work in logical sequence; `BLOCKED` keeps open but non-actionable work; `CLOSED` separates finished `COMPLETE` items from unimplemented `DROPPED` items. `Ripple` names the origin or counterpart card a cross-folder entry pairs with.

## [01]-[OPEN]

[F01]-[QUEUED]: One attention fabric across every surface.

- Capability: the attention chain (hook feed → collector → focus router → notification click) and wezterm's new bell→attention arm are the same concern spelled twice; zellij's zjstatus cells, wezterm toasts, and terminal-notifier posts are three renderers of one event stream.
- Shape: one attention-event vocabulary (source, urgency, pane identity, receipt) owned beside `forge-agents`, with every emitter (hooks, bell arm, tunnel supervisor, drift agents) publishing rows and every renderer (zjstatus, toast, notification, future dashboards) folding the same stream.
- Unlocks: per-source notification policy rows, attention history queries, cross-app "what needs me" as one command.
- Anchors: `shell-tools/mcp-launchers.nix` collector, `wezterm/deck.lua` bell arm, `receipts.nix` grammar, interconnection §RUNTIME_SEAMS.

[F02]-[QUEUED]: Receipts as a queryable estate plane.

- Capability: the dual-receipt grammar (TSV + JSONL, `ts/surface/result` keys) now spans most kernels; `receipts.nix` centralizes the fold; `forge-receipts` browses sources derived from registries.
- Shape: one receipts query surface (DuckDB over the JSONL corpus) with typed per-surface projections — failures-last-24h, switch history, tunnel flaps, acceptance trends — as `forge-receipts` verbs.
- Unlocks: agents diagnose estate history without log spelunking; drift between "what ran" and "what the docs claim" becomes a query.
- Anchors: `shell-tools/receipts.nix`, `browsers.nix` receipt rows, DuckDB overlay, DUAL_RECEIPTS law.

[F03]-[QUEUED]: The theme owner as a full design system.

- Capability: `theme.nix` gained a recursive color-record projector; consumers are proven private-hex-free; roles bind only to verified group names.
- Shape: extend the owner with typographic scale rows (type ramp, letter-spacing, line-height as vocabulary), elevation/depth tokens, motion/duration tokens, and per-surface density rows — projected to wezterm, zellij, yazi, nvim, vscode, and future HTML artifacts from one vocabulary; color theory encoded as derivation (contrast-ratio assertions per role pair at eval).
- Unlocks: WCAG-contrast proofs as flake checks; one-row theme variants; UI/UX masterpiece passes grounded in tokens instead of taste.
- Anchors: `modules/home/theme.nix` projector, `fonts.nix` metrics rows, dataviz skill palette law.

[F04]-[QUEUED]: VS Code as the estate's visual flagship.

- Capability: the masterpiece track holds verified settings-scope law (precedence, per-key language merges, application-scope exclusions, profile publish contract) and three-repo workspace harvests.
- Shape: user-level HM ownership of universal rows with per-repo workspace composition designed in; extension roster rebuilt from verified capability deltas; window chrome, product icons, decorations, and terminal styling as theme-owner projections; render-proven via screencapture + multimodal judgment.
- Unlocks: the same universalize-with-workspace-nuance pattern for Rasm and Maghz `.vscode` files.
- Anchors: vscode masterpiece fixlog, `overlays/manifest.nix` `extensions.vscode`, theme projections, scars §sentinel.

[F05]-[QUEUED]: Zellij/wezterm session fabric unification.

- Capability: wezterm gained reload-surviving singleton floats and structured attention; zellij owns sessions/tabs; `forge-workspace` bridges them; scripts' terminal mesh is acceptance-proven.
- Shape: one session-fabric vocabulary — workspace rows carrying zellij session identity, wezterm domain, float policy, and chord entry — so a new workspace is one row that projects the picker entry, the ssh domain, the layout, and the acceptance row together.
- Unlocks: kill the remaining hand-seams between pickers, layouts, and domains; session state queries via the receipts plane.
- Anchors: `config.forge.ssh.hosts` pattern, `zellij/ops.nix`, `wezterm/deck.lua` registry, chords rows.

[F06]-[QUEUED]: nvim C# + estate-language parity.

- Capability: the C# integration mandate (Roslyn identity shared with the lsp-marketplace row, one formatter identity with the `fmt` cs lane) is in flight; the marketplace projection derives identity from cmd rows.
- Shape: a per-language parity table — LSP row, formatter lane, treesitter grammar, lint lane, health probe — asserted complete for every language the estate carries (nix, lua, python, ts, cs, bash, sql); a missing cell fails a check.
- Unlocks: a new language is one parity row; editor/harness/formatter never diverge on tool identity.
- Anchors: nvim `default.nix` grammars, `fmt.nix` `_LANE` vocabulary, `.claude/lsp-marketplace/` rows.

[F07]-[QUEUED]: Estate dashboards from owner data.

- Capability: every owner now projects JSON registers (`forge/registers/*.json`, palette.json, fonts manifest, receipts JSONL, agent-state.json).
- Shape: an html-studio estate dashboard generated from those artifacts — attention, quota, tunnel health, acceptance history, theme proof rows — as a `forge-*` verb rendering a self-contained page; ultra-advanced UI/UX under the F03 token system.
- Unlocks: the operator's "what is my machine doing" as one designed surface; agents get the same facts as typed JSON.
- Anchors: registers seam (interconnection §RUNTIME_SEAMS), html-studio skill, dataviz law.

[F08]-[QUEUED]: `.claude/` scripts at kernel law.

- Capability: hooks are hardened; `setup-env.sh` (~19k) remains the largest un-red-teamed shell surface; the smoothing pass targets `.claude/scripts/` and hooks at the same bar as the estate kernels.
- Shape: setup-env decomposed into row-driven resolver folds with dual receipts, shape-asserted admissions (scars §merge-gate), and the attention/receipt grammars; workflow scripts audited against the determinism law.
- Unlocks: the harness's own substrate proven at the bar it enforces on the estate.
- Anchors: `.claude/hooks/setup-env.sh`, hooks-builder skill, workflow-determinism review rule.

[F12]-[QUEUED]: The VFS fabric as an estate surface.

- Capability: yazi's `vfs.toml [services]` now projects sftp mounts from `config.forge.ssh.hosts` with the 1Password identity agent pinned — remote filesystems became one registry row.
- Shape: the ssh-host row grows mount-policy fields (paths, read-only, cache posture) so every VFS-capable consumer (yazi today, future pickers and sync rails) folds the same rows; `forge-workspace` gains remote-workspace entries riding the same identity.
- Unlocks: browsing maghz volumes as a first-class yazi surface; a second VPS mounts with zero yazi edits.
- Anchors: `yazi/default.nix` vfs projection, `shell-tools/ssh.nix` registry, interconnection §[01][03].

[F13]-[QUEUED]: VS Code flagship follow-ons.

- Capability: pass 1 landed the owned design system (330-token projection, 26-row extension rail, three-repo universalization, `forge-vscode` doctor/sync receipts).
- Shape: the named residuals as one leg — vetted product-icon-theme admission, the 40-extension extras cull (operator-decided, doctor-ledgered), workspace-file slimming in Forge/Rasm/Maghz now that user-level rows own the base, and the keybindings.json rail when the first custom binding earns it.
- Unlocks: the flagship pattern replicated cleanly; workspace files shrink to genuine per-repo intent.
- Anchors: `apps/vscode/{appearance,extensions}.nix`, `overlays/manifest.nix` rows, the settings-scope law in the masterpiece fixlog.

[F10]-[QUEUED]: Agent-readable pane capture as a `forge-zellij` verb.

- Capability: `zellij subscribe --pane-id --scrollback --format json` is verified real on the pinned zellij — a typed pane-content stream no estate surface exploits.
- Shape: a `forge-zellij peek` verb returning pane scrollback as a JSON envelope, joined with the attention fabric so "show me what that waiting agent's pane says" is one command.
- Unlocks: notification clicks can carry context previews; acceptance rows can assert on live pane content without `dump-screen` temp files.
- Anchors: `zellij/ops.nix` graph kernel, F01 attention fabric, receipts grammar.

[F11]-[QUEUED]: zjstatus transient notifications widget.

- Capability: the pinned zjstatus ships a `{notifications}` widget the bars never render; the collector already computes attention transitions.
- Shape: the forge-agents collector publishes transition events to the widget pipe alongside its cells — in-bar transient toasts for needs-input rises without leaving the terminal.
- Unlocks: attention visibility while notifications are muted; one more renderer on the F01 event stream.
- Anchors: `mcp-launchers.nix` collector pipes, zellij config bars.
- Ripple: F01.

[F09]-[QUEUED]: Cross-app integration pass charter.

- Capability: each app lane closed with deferred integration openings — `forge-browse` row-scoped deep links (wezterm arm ready), `forge-workspace`→`receipts.nix` coupling, theme role gaps (`SnacksIndentScope`), chords domain rows for nvim leader keys.
- Shape: one integration red-team over apps/\*\* + scripts + shell-tools + theme as the binding system, landing every deferred seam row and hunting the seams no single lane could see.
- Unlocks: the wave's residual value; the FRONTIER cards above become grounded implementation targets.
- Anchors: every closed lane's `deferred` section; interconnection map.

## [02]-[CLOSED]

(none)
