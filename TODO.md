# TODO

Cleanup pass planned on 2026-09-14 and stopped before any edit landed. The tree already carries an uncommitted `flake.lock` bump and
advanced `overlays/_sources` pins (verapdf 1.31.170, biome 2.5.13); neither has been built or switched.

## [01]-[BUMP_AND_DEPLOY]

- Build and switch the bumped inputs: `forge-redeploy --switch`, fix every warning, then trim to one generation
  (`sudo -H nix-env -p /nix/var/nix/profiles/system --delete-generations old`, `nix-collect-garbage -d`, `nix store optimise`).
- Homebrew is already upgraded and cleaned; nine casks stay outdated only because their `--greedy` auto-update rows are upstream-owned.

## [02]-[DOCS_REMOVAL]

- `git rm -r docs/` and scrub every reference: `CLAUDE.md` [02] and [04], `AGENTS.md` :19 :39, `README.md` :50 :92 :130-135 :174,
  `.coderabbit.yaml` :3 :47-71 :230-232, `.greptile/rules.md` :9 :12 :14 :15, `.greptile/config.json` :46 :67 :81,
  `.greptile/files.json` every `docs/` path row, `nvfetcher.toml` :2.
- Shared skill surfaces still name `docs/stacks/` and `docs/standards/` as a sibling-repo convention (`.claude/agents/reviewer-harvest.md`,
  `.claude/skills/code-review/templates/{fix,harvest,close}.md`, `refuted-classes.yaml`, `scripts/review_rail.py`); those byte-copy to the
  sibling repos, so decide whether the convention dies estate-wide before scrubbing them.

## [03]-[DANGLING_REFERENCES]

- `modules/home/programs/languages/default.nix` :7 :22 — `forge/packages/manifest.json` projection has zero readers; delete with
  `forge-package-manifest` (`overlays/default.nix` ~:398).
- `modules/home/fonts.nix` :55 :143 — the fontTools/`hb-shape` receipt chain and `forge/fonts/manifest.json` had only the deleted font doctor.
- `modules/home/aliases/default.nix` :8 :34 — `forge.registers.aliases` is declared and read by nobody; the `desc`/`risk`/`category` columns
  served the deleted register browser.
- `modules/home/programs/apps/chords.nix` :536-537 :659 :681 — the `[REGISTER_PROJECTION]` block and `register` attribute have no reader.
- `modules/home/theme.nix` :218 — `macos-accent` row names `modules/darwin/settings` after the accent rows moved to `mac-tools/defaults/interface.nix`.
- `modules/home/aliases/core.nix` — rows whose binary left the machine PATH: `alint`, `jqr`, `jqc`, `jqs`, `j2y`, `y2j`, `yaml`, `tyc`,
  `rfix`, `rformat`, `fda`, `bench`, and the `rg` self-alias (`which -a rg fd biome ast-grep` all resolve nowhere).
- `modules/home/programs/apps/nvim/default.nix` :203-207 :344 :356-360 — biome `lsp-proxy`, `yamlfmt`, `yamllint`, `actionlint` rows point at
  binaries no longer installed; `lua/plugins/grug-far.lua` :7 :11-12 pins `rg`/`ast-grep` paths the same way.
- `.claude/lsp-marketplace/biome-lsp/.lsp.json` :3 — `biome` command is on no PATH and in no `mise.toml`.
- Stale comments: `modules/home/environments/development.nix` :9 (deleted `forge-tools/default.nix`), `flake-modules/tooling.nix` :81
  ("the PATH wrapper"), `overlays/manifest.nix` :107 :117 :421-422 :649 :653, `CLAUDE.md` :43 ("fmt lane") :104 (duckdb row),
  `.coderabbit.yaml` :47 and `.greptile/rules.md` :12 ("the fmt router").

## [04]-[HAND_ROLLED_TOOLING_TO_TEAR_OUT]

Keep: `forge-redeploy`, `forge-provision`, `gha`, `loc`, the `terminal.nix` yazi→zellij→nvim rail, `forge-osa`, `forge-console`,
`gui-op-secrets`, `forge-default-applications`, `forge-known-hosts`, the zellij grant pruner, the karabiner/yazi config proofs.

- Flag-injection wrappers, install the bare package instead: `shfmt` and `taplo` (`languages/dev-tools.nix` :18 :39), `stylua`
  (`lua-tools.nix` :16), `prettier` (`node-tools.nix` :20), `sqruff` (`db-tools.nix` :40), `swiftformat` and the `_walk_up` half of `swiftlint`
  (`apple-tools.nix` :20 :45; keep the `DYLD_FRAMEWORK_PATH` seeding), the argument-less `postgres18-forge-client-tools` makeWrapper
  (`db-tools.nix` :19), `withDefaultFlag` + hexyl (`shell-tools/default.nix` :21 :92), `rsync-safe.sh` (`rsync.nix` :16), the `tree` eza
  wrapper (`eza.nix` :17), `xh --ignore-stdin` (`xh.nix` :29), `carbon-playwright-install.sh` + `carbon-now.sh` (`carbon.nix` :79 :94),
  `sqlite-forge` (`overlays/default.nix` :449). Then delete `walkUp` from `modules/style.nix` :64 once no consumer remains.
- Activation scripts that are one-liners in derivation clothing: `forge-install-antigravity-cli` + `ensureAntigravityCli`
  (`dev-tools.nix` :57 :110), `forge-zsh-compdump-retire` + `forgeZshCompletions` (`zsh/completions.nix` :158 :169),
  `seedProcessComposeSettings` (`process-compose.nix` :67).
- Cosmetic launchd machinery: `bundle-apps.nix` (`forge.bundleApps`, stub `.app` renderer, `forgeAgent` grammar), the atuin
  `AssociatedBundleIdentifiers` patch (`atuin.nix` :13), the linearmouse bundle row; inline the two live agents as plain
  `launchd.agents.<name>.config` under the `com.parametric-forge.<name>` label.
- Receipt and proof ceremony with zero readers: `theme.nix` `targets` table + `targetsProved` + `base24File` + `paletteHtml` +
  `forge/theme/coverage.json` (:200-239 :305-460 :478-483; keep `tmThemeFile`), the fonts receipt chain above, `linearmouse/default.nix`
  `check-jsonschema` validation (:100-102), the wezterm `luac -p` + dispatch-arm grep gate (`wezterm/default.nix` :312-346).
- Overlay manifest ceremony (`overlays/manifest.nix` + `overlays/default.nix` :20-63): the `vocabulary` tables, `checkRow` vocabulary
  asserts, `checkAdmission`, `checkExtensionLane`, `requiredFields`, and the fields nothing builds from: `overlayReason`, `consumers`,
  `cacheClass`, `versionPolicy`, `capability`, `capabilityFloor`, `proof`, `chords`, `completion`/`completionArgs` (and its
  `forge-manifest-completions` consumer, `shell-tools/default.nix` :34), `themeCarrier`, `rowStates`/`resolved`, the dead `ca1` install
  mode, `projection.{package,app,default,overlay}`. Keep the nvfetcher pin-existence assert; keep every field a builder reads.
- Flake modules: `flake-modules/packages.nix` literal package/app list instead of `projection.*` folding (keep `nix run .#forge-provision`),
  drop the `defaultName`/`apps.default` throws; `flake-modules/qa.nix` drop the `pkg-<name>` smoke checks (flake check builds packages);
  `flake-modules/tooling.nix` :93 point ruff-format at `pyproject.toml` instead of transcribing keys.
- Single-consumer option indirection worth folding if the pass has room: `forge.lsp` (`nixd.nix` :34), `forge.ssh` (`ssh.nix` :41),
  `forge.ignoreEstate` (`fd.nix` :16), `forge.secrets.sessionCache` (`1password.nix` :60), `programs.zellij.popupGeometry` and
  `pluginGrants` (`zellij/default.nix` :46 :77).

## [05]-[CLOSE]

- `forge-redeploy --switch` clean, generation trim, garbage collect, optimise, then commit under `home:`/`nix:`/`docs:` scopes and push.
