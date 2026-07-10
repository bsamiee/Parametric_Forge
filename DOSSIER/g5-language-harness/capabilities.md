# G5 Language Harness — Estate Capabilities

Verified current-state truth for `F06` (estate-language parity table) and `F08` (`.claude/` scripts at kernel law), plus the upstream API surfaces the estate's own code already targets. Every row carries a source; a row without one is a phantom the next curation deletes.

## [01]-[SCOPE]

`F06` defines a per-language parity table of five orthogonal cells — LSP row, formatter lane, treesitter grammar, lint lane, health probe — asserted complete for every carried language, a missing cell failing a flake check; C# is the landed reference (Roslyn identity shared with the marketplace row, `csharpier` pinned to the profile binary matching the `fmt` cs lane). `F08` decomposes `setup-env.sh` into row-driven resolver folds with dual receipts and shape-asserted admissions, audits workflow scripts against the determinism law, and holds the unification mandate over `.claude/` scripts. Source: `docs/FRONTIER.md:76`, `docs/FRONTIER.md:79`, `docs/FRONTIER.md:83`, `docs/FRONTIER.md:86`.

## [02]-[PARITY_MATRIX]

Five parity cells live in five separate owners today: LSP rows in nvim `servers`, grammars in nvim `grammars`, formatter lanes in `fmt.nix _LANE`, lint lanes in nvim `toolFacts.lint`, marketplace identities in `.claude/lsp-marketplace/`. No single owner asserts a language row complete, and no cell projects a health probe — the fifth cell is unbuilt everywhere. Source: `modules/home/programs/apps/nvim/default.nix:90`, `modules/home/programs/apps/nvim/default.nix:23`, `modules/home/scripts/fmt.nix:21`, `modules/home/programs/apps/nvim/default.nix:350`, `.claude/lsp-marketplace/.claude-plugin/marketplace.json:8`.

| [INDEX] | [LANGUAGE]    | [LSP]          | [GRAMMAR]                       | [FMT_LANE]           | [LINT]             | [MARKETPLACE]  | [HEALTH] |
| :-----: | :------------ | :------------- | :------------------------------ | :------------------- | :----------------- | :------------- | :------: |
|  [01]   | nix           | `nixd`         | `nix`                           | `nix` → alejandra    | `deadnix`,`statix` | `nixd-lsp`     |    —     |
|  [02]   | lua           | `lua_ls`       | `lua`                           | `lua` → stylua       | —                  | `lua-lsp`      |    —     |
|  [03]   | shell/bash    | `bashls`       | `bash`                          | `shell` → shfmt      | `shellcheck`       | `bash-lsp`     |    —     |
|  [04]   | python        | `ty`           | `python`                        | `python` → ruff      | `ruff`             | `ty-lsp`       |    —     |
|  [05]   | typescript/js | `tsgo`         | `typescript`,`tsx`,`javascript` | `web` → biome        | —                  | `tsgo-lsp`     |    —     |
|  [06]   | c#            | `roslyn_ls`    | `c_sharp`                       | `csharp` → csharpier | —                  | `roslyn-lsp`   |    —     |
|  [07]   | sql           | `postgres_lsp` | `sql`                           | `sql` → sqruff       | `sqruff` (lane)    | `postgres-lsp` |    —     |
|  [08]   | yaml          | `yamlls`       | `yaml`                          | `yaml` → yamlfmt     | `yamllint`         | `yaml-lsp`     |    —     |
|  [09]   | toml          | —              | `toml`                          | `toml` → taplo       | —                  | —              |    —     |
|  [10]   | markdown      | —              | `markdown`,`markdown_inline`    | `prose` → prettier   | `typos` (global)   | —              |    —     |
|  [11]   | dockerfile    | —              | `dockerfile`                    | —                    | `hadolint`         | —              |    —     |

The complete grammar bundle carries 33 parsers beyond the LSP-backed languages, adding `css`, `csv`, `diff`, `git_config`, `git_rebase`, `gitattributes`, `gitcommit`, `html`, `jsdoc`, `json`, `json5`, `kdl`, `mermaid`, `query`, `regex`, `vim`, `vimdoc`, `xml`; the list is pinned to nvim-treesitter `main`-branch parsers and built with `pkgs.vimPlugins.nvim-treesitter.withPlugins (p: map (n: p.${n}) grammars)`. Source: `modules/home/programs/apps/nvim/default.nix:23`, `modules/home/programs/apps/nvim/default.nix:57`.

A new language today edits four surfaces in two files (server row, grammar list, `fmt` lane, lint row) plus the marketplace only auto-projects from the server row — so F06's "one parity row" unlock is not yet realized; the marketplace projection is the only cell that follows automatically. Source: `modules/home/programs/apps/nvim/default.nix:425`, `modules/home/programs/apps/nvim/default.nix:437`.

## [03]-[LSP_REGISTRY_AND_PROJECTION]

One Nix `servers` row family is consumed by both native Neovim and the Claude marketplace; each row carries `cmd`, `filetypes`, `root_markers`, `settings`, and a `claude` marketplace identity where present, so editor and agent LSP identity cannot drift. Source: `modules/home/programs/apps/nvim/default.nix:83`, `modules/home/programs/apps/nvim/default.nix:90`, `modules/home/programs/apps/nvim/default.nix:207`.

Native Neovim iterates `servers`, calls `vim.lsp.config(name, { cmd, filetypes, root_markers, settings })`, then `vim.lsp.enable(name)`, and activates per-client completion on `LspAttach` when `client:supports_method("textDocument/completion")` holds, via `vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })`. Source: `modules/home/programs/apps/nvim/lua/config/lsp.lua:11`, `modules/home/programs/apps/nvim/lua/config/lsp.lua:33`.

The marketplace projection writes `forge/lsp/claude-marketplace.json` from the server rows, deriving `command` from `builtins.head row.cmd`, `args` from `builtins.tail row.cmd`, `extensionToLanguage` from `row.claude.extensions`, and optional `settings` from `row.claude.settings`. Source: `modules/home/programs/apps/nvim/default.nix:425`, `modules/home/programs/apps/nvim/default.nix:437`.

The eight checked-in marketplace plugins spell their commands `nixd`, `lua-language-server`, `bash-language-server`, `ty server`, `tsgo --lsp -stdio`, `postgrestools lsp-proxy`, `roslyn-language-server --stdio`, and `yaml-language-server --stdio`; each `.lsp.json` maps extensions through `extensionToLanguage`. The `roslyn-lsp` row additionally sets `startupTimeout: 60000` and `maxRestarts: 3` and covers `.cs`/`.csx`. Source: `.claude/lsp-marketplace/.claude-plugin/marketplace.json:8`, `.claude/lsp-marketplace/roslyn-lsp/.lsp.json:2`, `.claude/lsp-marketplace/tsgo-lsp/.lsp.json:3`, `.claude/lsp-marketplace/postgres-lsp/.lsp.json:3`.

## [04]-[FORMATTER_LINT_ROUTER]

The `fmt` CLI owns a closed 14-lane `_LANE` vocabulary, each row shaped `tool|write argv|check argv`: `nix`→`alejandra`, `shell`→`shfmt`, `python`→`ruff format`, `web`→`biome format`, `prose`→`prettier`, `yaml`→`yamlfmt`, `toml`→`taplo`, `lua`→`stylua`, `sql`/`sql-duckdb`→`sqruff`, `swift`→`swiftformat`, `csharp`→`csharpier`, `osa`→`forge-osa`, `jq`→`_gate_jq`. Source: `modules/home/scripts/fmt.nix:21`, `modules/home/scripts/fmt.nix:34`.

`_EXT_LANE` routes extensions to lanes — `.cs`→`csharp`, `.py`/`.pyi`→`python`, `.ts`/`.tsx`/`.js`/`.jsx`/`.mjs`/`.cjs`/`.mts`/`.cts`/`.json`/`.jsonc`/`.css`→`web`, `.md`/`.markdown`/`.html`→`prose`, `.applescript`→`osa`; `duckdb-*` SQL filenames route to `sql-duckdb` while `sqlite-*` SQL is intentionally unowned, and package-manager lockfiles (`pnpm-lock.yaml`, `package-lock.json`, `packages.lock.json`) are deny-listed as machine-owned. Source: `modules/home/scripts/fmt.nix:40`, `modules/home/scripts/fmt.nix:57`, `modules/home/scripts/fmt.nix:115`.

The `--self-test` proves extension-to-lane ownership, lane-row completeness, write/check head-token agreement, shebang probes, package-lock denials, SQL dialect routing, and jq compile gating — an invariant harness covering the formatter cell only, not LSP/grammar/lint parity. Source: `modules/home/scripts/fmt.nix:133`, `modules/home/scripts/fmt.nix:195`.

The Neovim editor formatter surface (`toolFacts.format`, conform-style) maps `nix`→alejandra, `sh`/`bash`→shfmt, `lua`→stylua, `python`→ruff_format, `toml`→taplo, `yaml`→yamlfmt, `sql`→sqruff, `cs`→csharpier, and every web/markup filetype (`css`,`html`,`javascript`,`javascriptreact`,`json`,`jsonc`,`markdown`,`typescript`,`typescriptreact`)→prettier; lint facts split `ft` rows (`nix`→deadnix+statix, `sh`/`bash`→shellcheck, `python`→ruff, `yaml`→yamllint, `dockerfile`→hadolint), `workflow` (actionlint+zizmor), and `global` (typos). Source: `modules/home/programs/apps/nvim/default.nix:333`, `modules/home/programs/apps/nvim/default.nix:361`.

The editor and the `fmt` CLI disagree on web formatting: conform routes `.ts`/`.js`/`.json`/`.css`/`.tsx` to `prettier` while `fmt`'s `web` lane routes the same extensions to `biome`, aligning only on `prose` (markdown/html → prettier in both). Source: `modules/home/programs/apps/nvim/default.nix:345`, `modules/home/scripts/fmt.nix:24`, `modules/home/scripts/fmt.nix:47`.

## [05]-[LANGUAGE_OWNERS]

Python owner sets `python = pkgs.python315`, exposes `python`/`python3` wrappers, resolves `ruff`/`ty`/`mypy` through project environments before Nix or uv-tool fallback, and pins `UV_PYTHON_PREFERENCE=only-system` with `UV_PYTHON_DOWNLOADS=never`. Source: `modules/home/programs/languages/python-tools.nix:15`, `modules/home/programs/languages/python-tools.nix:49`, `modules/home/programs/languages/python-tools.nix:203`.

C# owner combines `dotnet-sdk_8`/`_9`/`_10`, wraps `pkgs.roslyn-ls` as `roslyn-language-server`, installs `csharpier`, and exports `DOTNET_ROOT` from the combined SDK. TypeScript/Node owner installs `nodejs-bin_26`, `pnpm_11`, `prettier`, `biome`, and `typescript-go` (labeled TypeScript 7 upstream identity, `tsgo` the nixpkgs binary). Lua owner installs `stylua`, `luacheck`, `lua-language-server`; its `stylua` wrapper forces `--search-parent-directories` only when the caller passes no explicit config flags. `nixd` owner exports `config.forge.lsp.nixd` carrying `nixpkgs.expr`, `formatting.command = ["alejandra"]`, and host-specific option-completion expressions. Source: `modules/home/programs/languages/dev-tools.nix:60`, `modules/home/programs/languages/node-tools.nix:60`, `modules/home/programs/languages/lua-tools.nix:17`, `modules/home/programs/nix-tools/nixd.nix:42`.

## [06]-[HARNESS_KERNEL]

Active Claude settings bind only `SessionStart` with matcher `startup|resume|compact`, a `command` hook invoking `.claude/hooks/setup-env.sh`, and `timeout: 10`. Source: `.claude/settings.json:18`, `.claude/settings.json:31`.

`setup-env.sh` writes secret-adjacent artifacts under `umask 077`, carries `DOPPLER_SOURCES` rows of shape `project:config:snapshot[:TOKEN_ENV_VAR]` (`agent-runtime:dev`, `parametric-forge:dev_machine`, `maghz:prd_host`), and admits `CLAUDE_ENV_EXPORT_KEYS` plus `CLAUDE_TOOL_PATHS` as per-project extras. It fetches via `doppler secrets download --project <p> --config <c> --no-file --format json --attempts 1` with `--fallback`, `--no-cache`, `--timeout 3s`, then classifies each source `live`, `snapshot`, or `dead` by return code, offline state, and snapshot mtime movement. Source: `.claude/hooks/setup-env.sh:26`, `.claude/hooks/setup-env.sh:39`, `.claude/hooks/setup-env.sh:91`, `.claude/hooks/setup-env.sh:104`.

Three runtime lanes gate cost: `--refresh` detached cache refresh, warm-cache replay into `CLAUDE_ENV_FILE` plus detached `nohup --refresh`, and cold inline resolution single-flighted through `${REFRESH_LOCK}`. Receipts publish key names only (`jq -r 'keys_unsorted[]'`), the session cache lands at `${XDG_CACHE_HOME:-${HOME}/.cache}/forge-secrets/session-env.sh`, receipt rows (`live`/`snapshot`/`DEAD`) go to stderr, and alert rows reach stdout only under degraded states. Source: `.claude/hooks/setup-env.sh:156`, `.claude/hooks/setup-env.sh:352`, `.claude/hooks/setup-env.sh:385`, `.claude/hooks/setup-env.sh:434`.

The workflow determinism gate spells `node ${CLAUDE_SKILL_DIR}/scripts/validate-workflow.mjs <file.js>` and `dry-run.mjs`; the validator enforces the first-statement `export const meta`, bans `Date.now()`, `Math.random()`, and argless `new Date()`, warns on host APIs (`require()`, `import ... from`, `process.*`), and the dry run rehosts the script twice, reporting `parseOk`, `ran`, `deterministic`, `perPhase`, `totalAgents`, `maxConcurrentObserved`. Source: `.claude/skills/workflow-creator/scripts/validate-workflow.mjs:48`, `.claude/skills/workflow-creator/scripts/validate-workflow.mjs:179`, `.claude/skills/workflow-creator/references/api.md:266`, `.claude/skills/workflow-creator/references/api.md:280`.

## [07]-[UPSTREAM_API_SURFACES]

Neovim native LSP defines configs with `vim.lsp.config[name] = { cmd, filetypes, root_markers, settings }` and activates with `vim.lsp.enable('<name>')`; merge order runs `vim.lsp.config('*')`, runtimepath `lsp/<name>.lua`, `after/lsp/<name>.lua`, then configs defined elsewhere, force deep-merged; `root_markers` reuse the client connection across files sharing a root; default keymaps `gra`/`gri`/`grn`/`grr`/`grt`/`grx`/`gO` bind on startup and `vim.keymap.del()` removes them. Source: <https://raw.githubusercontent.com/neovim/neovim/master/runtime/doc/lsp.txt>.

`nvim-treesitter` `main` is an incompatible rewrite (`master` frozen for compatibility), requires nightly-era Neovim plus package-manager `tree-sitter-cli`, `tar`, `curl`, and a C compiler, ties parser/query versions to `parser.lua`, forbids lazy loading, installs via `require('nvim-treesitter').install { ... }` (`:wait(300000)` for sync bootstrap), and activates highlighting through `vim.treesitter.start()` in an ftplugin or `FileType` autocmd. Custom parsers register through `require('nvim-treesitter.parsers').<name> = { install_info = { url, revision, branch, location, generate, generate_from_json, queries } }` with `vim.treesitter.language.register('<parser>', { '<filetype>' })`. Source: <https://raw.githubusercontent.com/nvim-treesitter/nvim-treesitter/main/README.md>.

Claude Code hooks accept `command`, `http`, `mcp_tool`, `prompt`, and `agent` handlers under nested `hooks` JSON (event key → matcher group → handler); common fields `type`/`if`/`timeout`/`statusMessage`/`once`, command fields `command`/`args`/`async`/`asyncRewake`/`shell` (adding `args` selects exec form, omitting selects shell). Matchers evaluate match-all for `"*"`/`""`/omitted, exact/`|`/`,` lists, else unanchored `RegExp.prototype.test`; tool-event `if` narrows with permission syntax (`Bash(git *)`, `Edit(*.ts)`). The full event surface spans `SessionStart`, `Setup`, `InstructionsLoaded`, `UserPromptSubmit`, `UserPromptExpansion`, `MessageDisplay`, `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch`, `PermissionDenied`, `Notification`, `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `Stop`, `StopFailure`, `TeammateIdle`, `ConfigChange`, `CwdChanged`, `FileChanged`, `WorktreeCreate`, `WorktreeRemove`, `PreCompact`, `PostCompact`, `SessionEnd`, `Elicitation`, `ElicitationResult`. Source: <https://code.claude.com/docs/en/hooks>.

`SessionStart` admits only `command` and `mcp_tool` handlers, matchers `startup`/`resume`/`clear`/`compact`, input `source` plus optional `model`/`agent_type`/`session_title`, and decision output `hookSpecificOutput.additionalContext`/`initialUserMessage`/`sessionTitle`/`watchPaths`/`reloadSkills`; `CLAUDE_ENV_FILE` persists `export` statements from `SessionStart`/`Setup`/`CwdChanged`/`FileChanged` into later Bash commands. `Setup` fires only for `--init-only`, or `--init`/`--maintenance` in non-interactive `-p` mode. Settings gate hooks via `allowedHttpHookUrls`, `allowManagedHooksOnly`, `disableAllHooks`; invalid user/project/local settings are rejected wholesale while managed settings fall back field-by-field. Source: <https://code.claude.com/docs/en/hooks>, <https://code.claude.com/docs/en/settings>.

Claude Code status lines configure through `statusLine` (`type: "command"`, `command`, optional `padding`/`refreshInterval`/`hideVimModeIndicator`), receive session JSON on stdin, and print display text to stdout; input fields include `model.*`, `workspace.*`, `cost.*`, `context_window.*`, `effort.level`, `thinking.enabled`, `rate_limits.*`, `session_id`, `transcript_path`, `vim.mode`, `agent.name`, `pr.*`, `worktree.*`. Source: <https://code.claude.com/docs/en/statusline>.

## [08]-[GAPS]

Next research wave must hunt:

- Health-probe cell (F06's fifth): no owner projects a per-language liveness/parity probe; `fmt --self-test` covers only formatter lanes. Find the mechanism that asserts a language row complete and fails `nix flake check` on a missing cell — whether a generated Nix assertion over the five owners, or a runtime probe binary.
- Parity-row unification: four surfaces (server, grammar, `fmt` lane, lint row) across two files must collapse to one owner for "a new language is one parity row" to hold; identify whether the nvim `servers` row can absorb grammar/fmt/lint cells or whether a new top-level parity registry owns all five.
- Web-formatter divergence: conform routes web/markup to `prettier`, `fmt`'s `web` lane to `biome` — resolve which tool is canonical for `.ts`/`.js`/`.json`/`.css` and whether the editor and CLI must share one lane vocabulary.
- Missing lint cells: `typescript`, `c#`, `lua`, `toml` carry no `ft` lint row despite shipping linters (`biome`/`luacheck`); confirm intended coverage and whether lint parity is asserted or best-effort.
- `setup-env.sh` decomposition target: F08 names "row-driven resolver folds with dual receipts and shape-asserted admissions" — locate the current fold boundaries and receipt shapes to size the rewrite against the live 448-line script.
- Grammar-vs-LSP asymmetry: 33 grammars but 8 LSP servers and 8 marketplace rows; determine which grammar-only languages (`kdl`, `mermaid`, `json5`, `xml`, `regex`) are deliberately editor-only versus parity holes.
