# TODO

## [03]-[DANGLING_REFERENCES]

- `modules/home/programs/languages/default.nix` :7 :22 — `estate/packages/manifest.json` projection has zero readers; delete with
  `package-manifest` (`overlays/default.nix` ~:398).
- `modules/home/fonts.nix` :55 :143 — the fontTools/`hb-shape` receipt chain and `estate/fonts/manifest.json` had only the deleted font doctor.
- `modules/home/aliases/default.nix` :8 :34 — `estate.registers.aliases` is declared and read by nobody; the `desc`/`risk`/`category` columns
  served the deleted register browser.
- `modules/home/programs/apps/chords.nix` :536-537 :659 :681 — the `[REGISTER_PROJECTION]` block and `register` attribute have no reader.
- `modules/home/theme.nix` :218 — `macos-accent` row names `modules/darwin/settings` after the accent rows moved to `mac-tools/defaults/interface.nix`.
- Stale comments: `flake-modules/tooling.nix` :81
  ("the PATH wrapper"), `overlays/manifest.nix` :107 :117 :421-422 :649 :653, `CLAUDE.md` :43 ("fmt lane"),
  `.coderabbit.yaml` :47 and `.greptile/rules.md` :12 ("the fmt router").

## [04]-[HAND_ROLLED_TOOLING_TO_TEAR_OUT]

Keep: `redeploy`, `gha`, `loc`, the `terminal.nix` yazi→zellij→nvim rail, `osa`, `services-console`,
`gui-op-secrets`, `default-applications`, `known-hosts`, the zellij grant pruner, the karabiner/yazi config proofs.

- Flag-injection wrappers, install the bare package instead: `shfmt` (`languages/dev-tools.nix` :18), `stylua`
  (`lua-tools.nix` :16), `prettier` (`node-tools.nix` :20), `sqruff` (`db-tools.nix` :40), `swiftformat` and the `_walk_up` half of `swiftlint`
  (`apple-tools.nix` :20 :45; keep the `DYLD_FRAMEWORK_PATH` seeding), the argument-less `postgres18-client-tools` makeWrapper
  (`db-tools.nix` :19), `withDefaultFlag` + hexyl (`shell-tools/default.nix` :21 :92), `rsync-safe.sh` (`rsync.nix` :16), the `tree` eza
  wrapper (`eza.nix` :17), `xh --ignore-stdin` (`xh.nix` :29),
  `sqlite-extended` (`overlays/default.nix` :449). Then delete `walkUp` from `modules/style.nix` :64 once no consumer remains.
- Activation scripts that are one-liners in derivation clothing: `install-antigravity-cli` + `ensureAntigravityCli`
  (`dev-tools.nix` :57 :110), `zsh-compdump-retire` + `zshCompdumpRetire` (`zsh/completions.nix` :158 :169),
  `seedProcessComposeSettings` (`process-compose.nix` :67).
- Cosmetic launchd machinery: `bundle-apps.nix` (`estate.bundleApps`, stub `.app` renderer, `launchdAgent` grammar), the atuin
  `AssociatedBundleIdentifiers` patch (`atuin.nix` :13), the linearmouse bundle row; inline the two live agents as plain
  `launchd.agents.<name>.config` under the `dev.bsamiee.<name>` label.
- Receipt and proof ceremony with zero readers: `theme.nix` `targets` table + `targetsProved` + `base24File` + `paletteHtml` +
  `estate/theme/coverage.json` (:200-239 :305-460 :478-483; keep `tmThemeFile`), the fonts receipt chain above, `linearmouse/default.nix`
  `check-jsonschema` validation (:100-102), the wezterm `luac -p` + dispatch-arm grep gate (`wezterm/default.nix` :312-346).
- Overlay manifest ceremony (`overlays/manifest.nix` + `overlays/default.nix` :20-63): the `vocabulary` tables, `checkRow` vocabulary
  asserts, `checkAdmission`, `checkExtensionLane`, `requiredFields`, and the fields nothing builds from: `overlayReason`, `consumers`,
  `cacheClass`, `versionPolicy`, `capability`, `capabilityFloor`, `proof`, `chords`, `completion`/`completionArgs` (and its
  `manifest-completions` consumer, `shell-tools/default.nix` :34), `themeCarrier`, `rowStates`/`resolved`, the dead `ca1` install
  mode, `projection.{package,app,overlay}`. Keep the nvfetcher pin-existence assert; keep every field a builder reads.
- Flake modules: `flake-modules/packages.nix` literal package/app list instead of `projection.*` folding; `flake-modules/qa.nix` drop the `pkg-<name>` smoke checks (flake check builds packages);
  `flake-modules/tooling.nix` :93 point ruff-format at `pyproject.toml` instead of transcribing keys.
- Single-consumer option indirection worth folding if the pass has room: `estate.lsp` (`nixd.nix` :34), `estate.ssh` (`ssh.nix` :41),
  `estate.ignoreEstate` (`fd.nix` :16), `estate.secrets.sessionCache` (`1password.nix` :60), `programs.zellij.popupGeometry` and
  `pluginGrants` (`zellij/default.nix` :46 :77).
