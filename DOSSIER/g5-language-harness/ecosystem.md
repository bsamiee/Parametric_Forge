# G5 Language Harness — Ecosystem

External adoption candidates and composable patterns for `F06` (parity table) and `F08` (harness kernel). Each entry carries a source URL and the capability delta against the current estate; maturity is a coarse tier (established / active / early / nascent) since exact star and timestamp counts are staleness bait a dossier cannot keep true. Estate current-state truth lives in `capabilities.md`.

## [01]-[NIX_OWNED_TOOLING_CANDIDATES]

`treefmt-nix` (established, MIT). One Nix module evaluation owns formatter packages, dependencies, wrapper config, `nix fmt`, and a `nix flake check` formatting gate; carries 100+ formatter modules including `alejandra`, `biome`, `csharpier`, `ruff-format`, `sqruff`, `stylua`, `taplo`, `yamlfmt`, `yamllint`, `zizmor` — nearly the estate's entire `fmt` lane set. Exposes `treefmt-nix.lib.evalModule`, `config.build.wrapper`, `config.build.check self`, flake-parts `inputs.treefmt-nix.flakeModule` with `treefmt = { .. }` under `perSystem`; rows spell `programs.<formatter>.enable`, `.package`, `settings.formatter.<name>.{command,options,includes,excludes}`, and `projectRootFile`. Source: <https://github.com/numtide/treefmt-nix>, <https://raw.githubusercontent.com/numtide/treefmt-nix/main/README.md>.

`git-hooks.nix` (established, Apache-2.0). Nix-owned pre-commit hook registry that runs hooks in development and CI, builds hook tooling, and maps one hook set into `formatter`, `checks`, and `devShells`. Exposes `inputs.git-hooks.lib.${system}.run`, `pre-commit-check.config.{package,configFile}`, `.shellHook`, `.enabledPackages`; hook rows spell `black.enable`, `shellcheck.enable`, `clippy.packageOverrides.*`, and hook-specific `settings`. Source: <https://github.com/cachix/git-hooks.nix>.

`nixvim` (established, MIT). Nix module framework projecting one Neovim config across Home Manager, nix-darwin, NixOS, and standalone `makeNixvim`/`evalNixvim` builds; standalone evaluation exposes `configuration.config.build.package` and `.build.test` (a test derivation for `nix flake check`). Exposes `inputs.nixvim.homeModules.nixvim`, `.nixosModules.nixvim`, `.nixDarwinModules.nixvim`. Source: <https://github.com/nix-community/nixvim>.

`nvf` (active, MIT). Nix/NixOS Neovim framework with standalone, NixOS-module, and Home-Manager-module install modes; config is Nix-owned, reproducible through the store, extensible through the module system — a lighter-surface alternative to `nixvim`'s option depth. Source: <https://github.com/NotAShelf/nvf>.

`nix-wrapper-modules` (active). Nix library for wrapping configured executables through the module system without requiring NixOS, Home Manager, or nix-darwin ownership per consumer — the generalization of the estate's per-tool wrapper pattern (`stylua`, `python`, `roslyn-language-server`). Source: <https://github.com/BirdeeHub/nix-wrapper-modules>.

Nix flake CLI contract. `nix fmt` runs the formatter named by flake outputs and forwards file arguments with `PRJ_ROOT` set to the nearest parent `flake.nix`; `nix flake lock` writes an up-to-date lock per input, leaving already-current entries unmodified — the separation of resolved-input identity from command behavior a parity flake-check rides. Source: <https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-fmt>, <https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake-lock>.

## [02]-[EDITOR_AND_RUNTIME_CANDIDATES]

Helix `languages.toml`. One language record carries `name`, `language-id`, `scope`, `file-types`, `shebangs`, `roots`, `auto-format`, `language-servers`, `grammar`, `formatter`, `workspace-lsp-roots`, and `code-actions-on-save` — every F06 parity cell in a single row, with built-in / user / project override layering. The single-record model is the reference shape for collapsing the estate's five-owner split. Source: <https://raw.githubusercontent.com/helix-editor/helix/master/book/src/languages.md>.

`mise`. `mise.toml` pins `[tools]`, `[env]`, `[tasks]`, `[settings]`, `[plugins]`, `[tool_alias]`, and `min_version` with hierarchical directory-proximity merge and idiomatic version-file ingestion — separates tool-version identity from shell activation. Source: <https://raw.githubusercontent.com/jdx/mise/main/docs/configuration.md>, <https://raw.githubusercontent.com/jdx/mise/main/docs/dev-tools/index.md>.

`pre-commit`. `.pre-commit-config.yaml` pins hook repositories and revisions, installs isolated per-hook environments, and runs cross-language tools as a maintained gate — the upstream framework `git-hooks.nix` wraps in Nix. Source: <https://pre-commit.com/>.

## [03]-[CLAUDE_CODE_HARNESS_ESTATES]

`leeguooooo/claude-code-usage-bar` (active, MIT). Production-shaped `statusLine` parser for 5-hour and 7-day rate-limit usage, reset timers, model, context window, prompt-cache age, session cost, project/git line, optional local bridge state; ships `.claude-plugin`, commands, docs, scripts, a skill, tests, and installers. Source: <https://github.com/leeguooooo/claude-code-usage-bar>.

`livlign/ccbit` (early, MIT). Transcript-derived session awareness as one Go binary, no hooks, no daemon — the Claude transcript is the source of truth, and a settings file defines only one `statusLine`. Source: <https://github.com/livlign/ccbit>.

`frsorrentino/fable-director` (nascent, MIT). Deterministic token-governance surfaces: a `PreToolUse` budget gate, a `Stop` hook, a `SessionEnd` telemetry write to SQLite, and a statusline segment carrying budget state — the top model directs, execution routes to the cheapest adequate means. Source: <https://github.com/frsorrentino/fable-director>.

`yesitsfebreeze/voit` (nascent, MIT). Four-tier plugin estate: a `SessionStart` role/scope hook, a `PreToolUse` write-scope hook, project bootstrap, a zero-dep Unix-socket message bus, commands as bus clients, and a role/branch/bus statusline. Source: <https://github.com/yesitsfebreeze/voit>.

`YangHungTW/harness` (nascent, MIT). Personal marketplace with daily-ops skills, nested `CLAUDE.md` gap detection, hook-fed `ledger.jsonl` rows, a dashboard, and a statusline wired as `subagentStatusLine` with optional main `statusLine`. Source: <https://github.com/YangHungTW/harness>.

## [04]-[PATTERNS_WORTH_COMPOSING]

Single Nix owner projects editor, formatter, and check outputs. `nixvim` projects cross-surface Neovim modules plus a standalone test derivation; `treefmt-nix` projects one formatter wrapper and one flake check from one evaluation; `git-hooks.nix` maps one hook set into formatter, check, and dev-shell — the same shape the estate's nvim `servers` row already uses to feed editor and marketplace. Source: <https://github.com/nix-community/nixvim>, <https://github.com/numtide/treefmt-nix>, <https://github.com/cachix/git-hooks.nix>.

Formatter registries expose row-level package and option override. `treefmt-nix` uses `programs.<formatter>.enable` plus `settings.formatter.<name>` rows; `git-hooks.nix` uses `black.enable`/`shellcheck.enable`/`clippy.packageOverrides.*` plus hook `settings`; the estate's `fmt` owner uses `_LANE`/`_EXT_LANE` rows plus `--self-test` to prove lane completeness — the same registry-row discipline, one in Nix eval, one in a packaged shell kernel. Source: <https://github.com/numtide/treefmt-nix>, <https://github.com/cachix/git-hooks.nix>, `modules/home/scripts/fmt.nix:21`, `modules/home/scripts/fmt.nix:133`.

Single-record parity beats five-owner split. Helix records language ID, file detection, roots, grammar, LSP servers, formatter, and code actions in one `languages.toml` record with override layers — the collapse target for F06's five separated owners. Source: <https://raw.githubusercontent.com/helix-editor/helix/master/book/src/languages.md>.

Statuslines converge on stdin JSON plus local cache, never agent-token calls. Claude Code documents statusline stdin JSON and no-token local execution; `claude-code-usage-bar` renders quota/context/cache/model/git/bridge from stdin plus local caches; `ccbit` reads the transcript as source of truth. Source: <https://code.claude.com/docs/en/statusline>, <https://github.com/leeguooooo/claude-code-usage-bar>, <https://github.com/livlign/ccbit>.

Hook estates converge on deterministic lifecycle handlers for enforcement and receipts. `fable-director` uses `PreToolUse`/`Stop`/`SessionEnd`/statusline for budget governance; `voit` uses `SessionStart`/`PreToolUse` for role/scope registration and write-scope denial — deterministic handlers gating side effects, the shape F08 enforces on `.claude/` scripts. Source: <https://code.claude.com/docs/en/hooks>, <https://github.com/frsorrentino/fable-director>, <https://github.com/yesitsfebreeze/voit>.

Claude marketplace estates converge on plugin-style distributable surfaces. `claude-code-usage-bar` ships a `.claude-plugin` with commands, skill, tests, and installers; `YangHungTW/harness` ships plugins, hooks, statusline, ledger, dashboard, and marketplace wiring — the distributable shape the estate's `.claude/lsp-marketplace/` already adopts for LSP identity. Source: <https://github.com/leeguooooo/claude-code-usage-bar>, <https://github.com/YangHungTW/harness>.

Flake input identity separates from command behavior. `flake.lock` records resolved inputs while `nix fmt` reads the formatter from flake outputs and forwards arguments — a parity flake-check asserts cell completeness at eval time, independent of the tools' own invocation. Source: <https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake-lock>, <https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-fmt>.

## [05]-[GAPS]

Next research wave must hunt:

- treefmt-nix migration surface: test the estate's 14-lane `fmt` shell kernel against a `treefmt-nix` eval that projects both `nix fmt` and a flake check, measuring the `--self-test` invariants (shebang probes, lockfile denials, SQL dialect routing, jq compile gating) no `treefmt` module expresses.
- Single-record parity owner: cost the Helix-style one-record model against the estate's five-owner split — verify a Nix parity registry owns LSP/grammar/fmt/lint/health cells and projects into nvim `servers`, `grammars`, `fmt.nix`, and the marketplace, or prove the shell/Nix boundary forces two owners.
- Health-probe candidate: no surveyed estate ships the F06 fifth cell; hunt a Nix assertion pattern (or `nix flake check` module) that fails on a missing parity cell, and any OSS estate that proves per-language liveness at build time.
- Statusline adoption: `claude-code-usage-bar` and `ccbit` are the mature stdin-JSON references — name the fields (`rate_limits.*`, `context_window.*`, `cost.*`, `effort.level`) the estate surfaces and settle whether a statusline sits in F08's kernel scope or a sibling card.
- Hook-governance depth: `fable-director` and `voit` demonstrate `PreToolUse`/`Stop`/`SessionEnd` enforcement the estate's single `SessionStart` binding does not use — scope the lifecycle events F08's kernel law owns beyond session bootstrap.
- nvf-vs-nixvim posture: the estate hand-rolls its nvim owner; establish whether `nixvim`'s option depth or `nvf`'s lighter surface subsumes the `servers`/`grammars`/`toolFacts` projection or fights the marketplace derivation.
