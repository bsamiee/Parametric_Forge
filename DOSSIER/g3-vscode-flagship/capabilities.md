# [G3_VSCODE_FLAGSHIP_CAPABILITIES]

Truth inventory for the F13 residuals — landed Forge state and the platform/Home-Manager API spellings the implementer builds on. Candidate rosters and OSS estate patterns live in `ecosystem.md`. F13 binds product-icon-theme admission, the 40-extension extras cull, workspace-file slimming, and the first earned `keybindings.json` rail; anchors `apps/vscode/{appearance,extensions}.nix`, `overlays/manifest.nix`, the F04 fixlog lineage. Source: `docs/FRONTIER.md:54-59`.

## [01]-[CURRENT_FORGE_STATE]

The landed owner projects appearance rows, behavior rows, Home Manager profile tool bindings, the sentinel-managed Default-profile settings block, and the manifest-rostered extension surface. Source: `modules/home/programs/apps/vscode/default.nix:7-14`.

The publish rail writes `~/Library/Application Support/Code/User/settings.json`; a custom full profile reads `profiles/<id>/settings.json` and never sees the generated block, so the rail owns Default-profile users only. Source: `modules/home/programs/apps/vscode/default.nix:13-14`, `:273-280`.

The settings merge strips asserted scalar keys, inserts a `forge-theme:begin` / `forge-theme:end` block, refuses an unterminated prior block, refuses a root-brace-line managed-key collision, and rewrites the settings inode with `cp`. `managedKeys` derives from the asserted rows plus tombstones for retired keys and throws when the strip set is empty. Source: `modules/home/programs/apps/vscode/default.nix:248-335`, `:248-263`.

User-level artifacts publish to `forge/theme/vscode.json`, `forge/theme/vscode-settings-block.jsonc`, and `forge/vscode/roster.json` under XDG config (all three present on disk). Source: `modules/home/programs/apps/vscode/default.nix:275-283`.

The extension rail treats `overlays/manifest.nix` rows as desired state, the user extension directory as runtime state, and VS Code `extensions.json` as cache; `forge-vscode doctor` proves roster-vs-live plus the settings sentinel, `sync` installs missing rows through `code --install-extension <id> --force` and emits TSV+JSONL receipts, and extras are reported without uninstall. Source: `modules/home/programs/apps/vscode/extensions.nix:7-12`, `:61-90`.

The manifest admission builder emits `id`, `publisher`, `registry`, `native_code`, `postinstall_behavior`, `secret_touching`, `host_permissions`, `runtime_write_policy`, and `mutable_paths`; the VS Code lane source is `marketplace-cli`, forbids Homebrew split ownership, and requires every security field. Source: `overlays/manifest.nix:32-50`, `:521-526`.

The roster carries exactly 26 rows (verified), each declaring the manifest security vocabulary: `charliermarsh.ruff`, `astral-sh.ty`, `ms-python.python`, `ms-python.debugpy`, `ms-python.mypy-type-checker`, `biomejs.biome`, `redhat.vscode-yaml`, `tamasfe.even-better-toml`, `bluebrown.yamlfmt`, `bradlc.vscode-tailwindcss`, `mechatroner.rainbow-csv`, `ms-dotnettools.csharp`, `ms-dotnettools.vscode-dotnet-runtime`, `PKief.material-icon-theme`, `bierner.markdown-mermaid`, `yzhang.markdown-all-in-one`, `ms-playwright.playwright`, `ms-azuretools.vscode-containers`, `CodeRabbit.coderabbit-vscode`, `esbenp.prettier-vscode`, `Gruntfuggly.todo-tree`, `jnoortheen.nix-ide`, `kdl-org.kdl`, `mkhl.shfmt`, `timonwong.shellcheck`, `usernamehw.errorlens`. Source: `overlays/manifest.nix:527-712`, `~/.config/forge/vscode/roster.json`.

The live extension cache holds 66 unique IDs; a case-insensitive diff against the 26 roster rows yields exactly 40 extras, and that computed set matches the `[DRIFT_EXTRAS_VETTING]` roster in `ecosystem.md` row-for-row (verified). Source: `~/.vscode/extensions/extensions.json`, `~/.config/forge/vscode/roster.json`.

The double-Ruff residual is configuration duplication, not two extensions: the only live Ruff extension ID is roster-bound `charliermarsh.ruff` (no `astral-sh.ruff` extra exists), while identical `ruff.*` server keys and the `[python]` `editor.defaultFormatter = "charliermarsh.ruff"` binding are asserted at BOTH user scope and workspace scope. Source: `modules/home/programs/apps/vscode/default.nix:163`, `:210-214`; `.vscode/settings.json:27`, `:103-107`.

The appearance owner asserts `workbench.colorTheme = "Default Dark Modern"` and `workbench.iconTheme = "material-icon-theme"` and asserts no `workbench.productIconTheme`, so the product icon surface is still stock `Default`. Source: `modules/home/programs/apps/vscode/appearance.nix:96-97`.

Three workspace files still mirror broad base editor behavior the user-scope rows now own: Forge `.vscode/settings.json` (editor defaults, language formatters, Nix/TS/Python-Ruff-Mypy-Ty paths, schema bindings, explorer/file/search excludes, Git/diff posture); Rasm `.vscode/settings.json` (~230 LOC; base + monorepo TS/CSS, Biome, file nesting, exclusions, test, .NET, Ruff, Mypy, Ty, Mermaid); Maghz `.vscode/settings.json` (~232 LOC; base + format-on-save, CSS/Tailwind association, file nesting/exclusion, .NET, Python testing disabled, Ruff, Mypy, Ty). Source: `.vscode/settings.json:3-195`, `/Users/bardiasamiee/Documents/99.Github/Rasm/.vscode/settings.json:15-247`, `/Users/bardiasamiee/Documents/99.Github/Maghz/.vscode/settings.json:15-248`.

Extend: the publish rail's sentinel merge is settings-only, so the first `keybindings.json` rail cannot reuse it — Home Manager writes `keybindings.json` wholesale (see `[06]`), meaning the earned rail overwrites the file rather than merging, and any hand-edited user bindings do not coexist with it. A pure product-icon admission is purely additive: the finalist themes contribute only `productIconThemes` (manifest-verified in `ecosystem.md`), so admission sets one scalar `workbench.productIconTheme` and cannot collide with the standing `material-icon-theme` file-icon assertion.

## [02]-[PRODUCT_ICON_THEME_API]

`contributes.productIconThemes` is the contribution point; each row carries `id`, `label`, and `path`. Source: https://code.visualstudio.com/api/extension-guides/product-icon-theme.

The definition file carries `fonts` and `iconDefinitions`; each `fonts` entry carries `id`, `src`, `weight`, and `style`; each `src` entry carries `path` and `format`; an icon definition carries `fontCharacter` and `fontId`. Product icons must be single-color glyphs in an icon font, and the active color theme supplies the rendered color. Source: https://code.visualstudio.com/api/extension-guides/product-icon-theme.

The setting key is `workbench.productIconTheme`, bound in source through `ThemeSettings.PRODUCT_ICON_THEME` with default `Default`; `productIconThemeSettingSchema` accepts string or null and `updateProductIconThemeConfigurationSchemas` extends the enum from installed themes. Source: https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/services/themes/common/workbenchThemeService.ts, https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/services/themes/common/themeConfiguration.ts.

The product-icon JSON schema `vscode://schemas/product-icon-theme` permits comments and trailing commas, validates `fonts`, and references the icon registry schema for `iconDefinitions`. The switching command is `Preferences: Product Icon Theme`. Product icons use `$(iconIdentifier)` in labels, `ThemeIcon` in API surfaces, and `contributes.icons` for extension-provided IDs. Source: https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/services/themes/common/productIconThemeSchema.ts, https://code.visualstudio.com/api/extension-guides/product-icon-theme, https://code.visualstudio.com/api/references/icons-in-labels.

## [03]-[KEYBINDINGS_API]

`keybindings.json` rules carry `key`, `command`, optional `when`, and optional `args`; user rules append below defaults at runtime, evaluate bottom-to-top, and the first matching `key` plus `when` wins. Source: https://code.visualstudio.com/docs/configure/keybindings.

Key chords are two keypresses separated by a space; macOS modifiers are `Ctrl+`, `Shift+`, `Alt+`, `Cmd+`; accepted keys are `f1-f19`, `a-z`, `0-9`, punctuation, arrows, paging keys, `tab`, `enter`, `escape`, `space`, `backspace`, `delete`, and numpad keys. Command arguments spell as `args`; sequential multi-command bindings use `command = "runCommands"` with `args.commands`; a removal rule prefixes the command with `-`; an empty command overrides. Source: https://code.visualstudio.com/docs/configure/keybindings.

## [04]-[WHEN_CLAUSE_GRAMMAR]

When clauses support `!`, `&&`, `||`, `==`, `!=`, `===`, `!==`, `>`, `>=`, `<`, `<=`, `=~`, `in`, and `not in`; comparison operators require whitespace around the operator. String literals containing whitespace use single quotes; regex clauses use JavaScript regex literals under JSON escaping, with flags `i`, `s`, `m`, `u` supported and `g`, `y` ignored. Source: https://code.visualstudio.com/api/references/when-clause-contexts.

Common contexts: `editorFocus`, `editorTextFocus`, `textInputFocus`, `inputFocus`, `editorHasSelection`, `editorHasMultipleSelections`, `editorReadonly`, `editorLangId`, `isInDiffEditor`, `isLinux`, `isMac`, `isWindows`, `isWeb`, `listFocus`, `inSnippetMode`, `inQuickOpen`, `resourceScheme`, `resourceFilename`, `resourceExtname`, `resourceDirname`, `resourcePath`, `resourceLangId`. Source: https://code.visualstudio.com/api/references/when-clause-contexts.

## [05]-[SETTINGS_PROFILES_SYNC]

macOS user settings live at `~/Library/Application Support/Code/User/settings.json`, workspace settings at `.vscode/settings.json`, multi-root settings inside the `.code-workspace` file, and profile settings at `Code/User/profiles/<id>/settings.json` (created only when a setting is modified for that profile). Language block keys spell `[typescript]` and multi-language blocks `[javascript][typescript]`; language-specific user settings override non-language workspace settings, and workspace language blocks override user language blocks for the same language. Source: https://code.visualstudio.com/docs/configure/settings.

Extension identifiers use `publisher.extension`; the CLI exposes `code --list-extensions`, `--show-versions`, `--install-extension`, `--uninstall-extension`, and `--extensions-dir <dir>`. Workspace recommendations use `.vscode/extensions.json` (single-folder) or `extensions.recommendations` inside a `.code-workspace` (multi-root) — a recommendation surface, never the install owner. Source: https://code.visualstudio.com/docs/configure/extensions/extension-marketplace.

Profiles store settings, extensions, and UI layout in the active profile; folder and workspace associations activate a profile, a setting or extension can be marked applied to all profiles, and VS Code never synchronizes extensions to or from remote windows. Settings Sync merges or replaces local preferences; `settingsSync.ignoredSettings` excludes settings, `settingsSync.keybindingsPerPlatform` scopes keybinding sync per platform, and `settingsSync.ignoredExtensions` excludes extensions. Sync covers built-in and installed extensions plus global enablement state, and UI state including display language, Activity Bar and Panel entries, view layout and visibility, command history, and do-not-show-again notifications. Source: https://code.visualstudio.com/docs/configure/profiles, https://code.visualstudio.com/docs/configure/settings-sync.

## [06]-[HOME_MANAGER_VSCODE_API]

Home Manager maps legacy `programs.vscode.{userSettings,userTasks,userMcp,keybindings,extensions,languageSnippets,globalSnippets}` into `programs.vscode.profiles.default.<same-key>`, and removed `programs.vscode.pname` — forks now have dedicated `programs.{vscodium,cursor,windsurf,kiro,antigravity}` modules. Source: https://raw.githubusercontent.com/nix-community/home-manager/master/modules/programs/vscode/default.nix.

Default-profile files write under `Code/User` (`settings.json`, `tasks.json`, `mcp.json`, `keybindings.json`, `snippets`); non-default profiles write under `Code/User/profiles/<name>`. Profile option spellings are `.userSettings`, `.userTasks`, `.enableMcpIntegration`, `.userMcp`, `.keybindings`, `.extensions`, `.languageSnippets`, `.globalSnippets`, `.enableUpdateCheck`, `.enableExtensionUpdateCheck`. `keybindings` rows carry `key`, `command`, optional `when`, and optional `args`, and non-null fields are written to `keybindings.json`. `mutableExtensionsDir` is a boolean defaulting true only when no non-default profiles exist and is mutually exclusive with non-default profiles. Source: https://raw.githubusercontent.com/nix-community/home-manager/master/modules/programs/vscode/mkVscodeModule.nix.

## [07]-[GAPS]

- Keybindings write path: whether Home Manager's `programs.vscode.profiles.default.keybindings` overwrites `Code/User/keybindings.json` wholesale on every switch (strongly implied by the settings-only sentinel merge) and, if so, whether the earned rail needs a keybindings-scoped sentinel merge mirroring the settings one, or accepts full ownership. Hunt: the exact `mkVscodeModule` write semantics for `keybindings.json` and any collision behavior against a user-edited file.
- Language-block precedence proof: settings docs assert workspace scope wins over user scope for `[python]` `editor.defaultFormatter`, but the double-Ruff cull needs the resolved winner confirmed live so the correct scope's `ruff.*` block is the one deleted rather than the surviving authority.
- Sync interaction with the managed region: whether Settings Sync round-trips the `forge-theme:begin/end` block and re-injects it on a second machine, or whether the managed keys belong in `settingsSync.ignoredSettings` to keep Sync from fighting the switch.
- Built-in product-icon ID surface: no enumeration exists of the ~200 built-in product icon IDs the active Dark Modern theme renders, so the visible delta of any admitted product icon theme (activity bar, panel, editor gutter) is unquantified.
- Workspace-slim floor: the minimum genuinely per-repo settings each of Forge/Rasm/Maghz `.vscode/settings.json` must retain after user-scope rows absorb the base is unmapped — no per-key classification of "base duplicate" vs "true per-repo intent" yet exists.
