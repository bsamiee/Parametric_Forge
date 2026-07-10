# [G3_VSCODE_ECOSYSTEM]

Candidate rosters and OSS estate patterns for the F13 residuals — product-icon finalists, the drift-extras cull inventory, admitted-row freshness, and the Nix estates worth stealing from. Landed Forge state and platform/Home-Manager API spellings live in `capabilities.md`. Every extension row below sources its Marketplace signal at `https://marketplace.visualstudio.com/items?itemName=<id>`; gallery-API manifest confirmations are called out inline.

## [01]-[PRODUCT_ICON_CANDIDATES]

Finalists, all confirmed via the gallery manifest to contribute `productIconThemes` and nothing else — admission is purely additive over the standing `PKief.material-icon-theme` file-icon theme, setting only `workbench.productIconTheme`.

| id                                       | installs | updated    | delta / signal                                                                                             |
| :--------------------------------------- | -------: | :--------- | :--------------------------------------------------------------------------------------------------------- |
| `miguelsolorio.fluent-icons`             |    1.79M | 2024-10-25 | Fluent product icons; highest install signal; manifest `contributes: [productIconThemes]` verified         |
| `PKief.material-product-icons`           |     675K | 2024-07-13 | same publisher family as the admitted `PKief.material-icon-theme`; manifest `[productIconThemes]` verified |
| `antfu.icons-carbon`                     |     333K | 2026-01-07 | IBM Carbon set; freshest high-install candidate; manifest `[productIconThemes]` verified                   |
| `RubenVerg.bootstrap-product-icons`      |     191K | 2021-02-23 | Bootstrap glyph set; stale but broad reach                                                                 |
| `ElAnandKumar.el-vsc-product-icon-theme` |     137K | 2025-03-30 | minimalist product-icon set                                                                                |
| `fogio.jetbrains-product-icon-theme`     |     5.6K | 2026-06-08 | JetBrains New UI set; freshest JetBrains representative                                                    |

Culled as low-install redundant or vanity filler: `ztluwu.lucide-icons` (1.7K), `SoulFriends.jetbrains-product-icon-theme-ui` (1K) and `ardonplay.jetbrains-idea-product-icon-theme` (10K, 2024) as redundant JetBrains variants behind `fogio`, `Cheesewaffle.cheesewaffle-product-icon-theme` (1.6K vanity).

## [02]-[DRIFT_EXTRAS_VETTING]

The 40 live extras (roster diff, verified exact against the live cache). These are operator-decided drift the cull leg ledgers; the doctor already reports them without uninstall.

| id                                                     | capability                              | installs | updated    |
| :----------------------------------------------------- | :-------------------------------------- | -------: | :--------- |
| `aaron-bond.better-comments`                           | comment annotation                      |    10.4M | 2022-07-30 |
| `alefragnani.project-manager`                          | project switching                       |    7.38M | 2026-03-31 |
| `anseki.vscode-color`                                  | GUI color-code generation               |    2.38M | 2017-08-04 |
| `be5invis.toml`                                        | TOML language support                   |     422K | 2021-11-06 |
| `bierner.markdown-checkbox`                            | checkbox in built-in Markdown preview   |    1.38M | 2022-11-03 |
| `bierner.markdown-footnotes`                           | footnote syntax in Markdown preview     |     850K | 2022-11-18 |
| `bmalehorn.shell-syntax`                               | shell syntax diagnostics                |     159K | 2023-02-18 |
| `bpruitt-goddard.mermaid-markdown-syntax-highlighting` | Mermaid Markdown syntax                 |     807K | 2026-05-25 |
| `christian-kohler.path-intellisense`                   | filename autocomplete                   |   18.99M | 2024-11-29 |
| `donjayamanne.python-extension-pack`                   | Python extension pack                   |   13.95M | 2021-11-08 |
| `evondev.dracula-high-contrast`                        | Dracula high-contrast theme             |     160K | 2025-03-27 |
| `georgiatechdb.sqlcheck`                               | SQL antipattern detection               |      798 | 2022-04-25 |
| `grapecity.gc-excelviewer`                             | spreadsheet/CSV viewer-editor           |    6.68M | 2026-06-05 |
| `humao.rest-client`                                    | REST request client                     |    7.37M | 2022-08-19 |
| `ibm.output-colorizer`                                 | output/log syntax coloring              |    1.60M | 2017-07-05 |
| `idleberg.applescript`                                 | AppleScript/JXA syntax, snippets, build |    98.5K | 2026-05-09 |
| `jq-syntax-highlighting.jq-syntax-highlighting`        | jq syntax support                       |      56K | 2018-06-01 |
| `kisstkondoros.vscode-gutter-preview`                  | image preview in gutter/hover           |    4.15M | 2024-11-30 |
| `llvm-vs-code-extensions.lldb-dap`                     | LLDB DAP debugging                      |     760K | 2026-07-09 |
| `mathematic.vscode-pdf`                                | PDF viewer                              |    2.56M | 2026-03-13 |
| `mikestead.dotenv`                                     | dotenv syntax support                   |    8.21M | 2018-03-01 |
| `ms-python.vscode-python-envs`                         | unified Python environment experience   |    47.1M | 2026-07-02 |
| `ms-vscode-remote.remote-containers`                   | Dev Containers                          |    40.4M | 2026-07-09 |
| `ms-vscode.powershell`                                 | PowerShell language/module dev          |    20.5M | 2026-06-25 |
| `nhoizey.gremlins`                                     | invisible/confusable character reveal   |     985K | 2020-11-05 |
| `nrwl.angular-console`                                 | Nx Console monorepo UI                  |    2.30M | 2026-06-08 |
| `oderwat.indent-rainbow`                               | indentation visualization               |   12.88M | 2022-04-09 |
| `patcx.vscode-nuget-gallery`                           | NuGet install/uninstall UI              |     726K | 2026-05-19 |
| `pflannery.vscode-versionlens`                         | package version codelens                |    2.49M | 2026-03-27 |
| `shardulm94.trailing-spaces`                           | trailing-space highlight/delete         |    3.47M | 2026-06-23 |
| `shd101wyy.markdown-preview-enhanced`                  | Markdown Preview Enhanced               |    9.77M | 2026-06-08 |
| `spywhere.guides`                                      | guide lines                             |     823K | 2019-01-06 |
| `streetsidesoftware.code-spell-checker`                | source-code spell checker               |   17.69M | 2026-02-24 |
| `stryker-mutator.stryker-mutator`                      | mutation testing integration            |      364 | 2026-04-22 |
| `swiftlang.swift-vscode`                               | Swift language support                  |     709K | 2026-07-06 |
| `tomoki1207.pdf`                                       | PDF display                             |   12.46M | 2025-01-11 |
| `tomoyukim.vscode-mermaid-editor`                      | Mermaid live editor                     |     271K | 2023-08-31 |
| `uniquevision.vscode-plpgsql-lsp`                      | PostgreSQL/PL/pgSQL language server     |      63K | 2024-01-30 |
| `vstirbu.vscode-mermaid-preview`                       | Mermaid previewer (Mermaid-maintained)  |     768K | 2025-07-22 |
| `yy0931.vscode-sqlite3-editor`                         | SQLite3 spreadsheet-style editor        |     622K | 2026-06-06 |

Redundancy flags for the cull mapping: three Mermaid extras (`bpruitt-goddard`, `tomoyukim`, `vstirbu`) plus roster row `bierner.markdown-mermaid` overlap VS Code's built-in Markdown preview, which now renders `mermaid` fenced blocks; two PDF viewers (`mathematic.vscode-pdf`, `tomoki1207.pdf`) duplicate; `bierner.markdown-checkbox`/`markdown-footnotes` extend the same built-in preview.

## [03]-[ADMITTED_ROSTER_FRESHNESS]

Freshness of already-admitted roster rows, for the re-vet pass.

| id                          | version         | updated    | installs | note                                                                                        |
| :-------------------------- | :-------------- | :--------- | -------: | :------------------------------------------------------------------------------------------ |
| `PKief.material-icon-theme` | 5.36.1          | 2026-06-23 |    34.7M | admitted file-icon theme; `overlays/manifest.nix:636-641`                                   |
| `charliermarsh.ruff`        | 2026.60.0       | 2026-07-09 |     4.1M | Python format/lint; `overlays/manifest.nix:549-556`                                         |
| `astral-sh.ty`              | 2026.60.0       | 2026-06-26 |     130K | Python type-check; `overlays/manifest.nix:557-564`                                          |
| `biomejs.biome`             | 2026.7.60717    | 2026-07-06 |     781K | TS/JS/JSON/CSS format+lint; `overlays/manifest.nix:587-594`                                 |
| `redhat.vscode-yaml`        | 1.25.2026070808 | 2026-07-08 |    28.1M | YAML LSP; `overlays/manifest.nix:601-608`                                                   |
| `ms-dotnettools.csharp`     | 2.146.2         | 2026-07-09 |    41.8M | Roslyn C# lane; `overlays/manifest.nix:617-625`                                             |
| `mechatroner.rainbow-csv`   | 3.24.1          | 2026-01-17 |    22.3M | CSV coloring; `overlays/manifest.nix:654-659`                                               |
| `tamasfe.even-better-toml`  | 0.21.2          | 2024-12-20 |    4.55M | TOML; slow update signal; `overlays/manifest.nix:609-616`                                   |
| `esbenp.prettier-vscode`    | —               | —          |    large | no-config fallback; TS/JS/JSON/CSS default routed to Biome; `overlays/manifest.nix:674-679` |
| `bierner.markdown-mermaid`  | —               | —          |    large | built-in preview now renders `mermaid` fences — admission is re-vet-worthy                  |

## [04]-[NIX_ESTATE_CANDIDATES]

| repo                                  | contribution / pattern                                                                                                                                                                                                                                                                         | maintenance                              | source                                                                                                                                                     |
| :------------------------------------ | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `nix-community/home-manager`          | declarative VS Code profiles, generated user files, generated profile `extensions.json`, symlink/buildEnv extension handling, mutable-dir reconciliation                                                                                                                                       | 10,057★ / 2,417⑂, pushed 2026-07-09, MIT | https://github.com/nix-community/home-manager; `modules/programs/vscode/mkVscodeModule.nix`                                                                |
| `nix-community/nix-vscode-extensions` | generated Nix exprs for Marketplace + Open VSX, daily GitHub-Action updates, `extensions.${system}` attrsets partitioned by registry/release/platform; `forVSCodeVersion`, `usingFixesFrom`; records publisher/name/release/platform/version/engine/VSIX-hash; does not expand extension packs | 381★ / 34⑂, pushed 2026-07-10, MIT       | https://github.com/nix-community/nix-vscode-extensions#readme                                                                                              |
| `nix-community/stylix`                | VS Code theming module composing theme + font through `programs.vscode.profiles.<name>.userSettings`                                                                                                                                                                                           | 2,329★ / 347⑂, pushed 2026-07-09, MIT    | https://github.com/nix-community/stylix/blob/14814ef555d8148ab82eba5054e654cd9eae3a1f/modules/vscode/meta.nix#L1-L29                                       |
| `yunfachi/nix-config`                 | Denix estate routing Codium settings through `programs.vscode.profiles.default.userSettings`, extensions via `vscode-marketplace` attr; appearance/extensions split into separate modules                                                                                                      | 68★ / 1⑂, pushed 2026-03-31, MIT         | https://github.com/yunfachi/nix-config/blob/9ba35d6fc96a4eb86db72c91a0fc74e636c71f82/modules/programs/codium/settings.nix#L12-L70                          |
| `Arcanyx-org/NiXium`                  | branches VS Code spellings across HM release lines; current rows use `programs.vscode.profiles.default.{extensions,enableExtensionUpdateCheck,enableUpdateCheck,userSettings}`                                                                                                                 | 47★ / 3⑂, pushed 2026-07-09, EUPL-1.2    | https://github.com/Arcanyx-org/NiXium/blob/a9cba53da660d4c8c64697ef4b91425f8fdd9bae/src/nixos/users/modules/editors/vscode/vscode.nix                      |
| `collective/robotsuite`               | builds `vscode-with-extensions`, consumes `nix-vscode-extensions.extensions.${system}`, overrides the Ruff extension payload to symlink the Nix `pkgs.ruff` binary                                                                                                                             | 12★ / 5⑂, pushed 2026-05-07, GPL-2.0     | https://github.com/collective/robotsuite/blob/032d1420bc5777a61873253a7f69e5c23d980bfa/devenv/modules/vscode.nix#L8-L33                                    |
| `belak/dotfiles`                      | projects `nix-vscode-extensions.extensions.${system}` into an overlay attr `community-vscode-extensions`                                                                                                                                                                                       | source line resolves on default branch   | https://github.com/belak/dotfiles/blob/e8c9e66f9b2f419183211aa7ccd5e02647371e67/nix/overlays.nix#L53-L55                                                   |
| `microsoft/vscode`                    | upstream monorepo keeps `.vscode/extensions.json` to seven recommendation IDs; workspace settings encode repo-specific build/search/test/Git/schema behavior only, never full personal editor policy                                                                                           | upstream product repo                    | https://github.com/microsoft/vscode/blob/main/.vscode/extensions.json#L1-L13; https://github.com/microsoft/vscode/blob/main/.vscode/settings.json#L39-L180 |

## [05]-[OSS_PATTERNS]

- Home Manager treats VS Code profiles as first-class generated file roots and declares `mutableExtensionsDir` incompatible with non-default profiles; it writes non-default `extensions.json` separately and switches to an extension-directory buildEnv when an immutable profile extension set is active. Source: https://raw.githubusercontent.com/nix-community/home-manager/master/modules/programs/vscode/mkVscodeModule.nix.
- `nix-vscode-extensions` separates extension-source freshness from profile projection: it supplies generated package attrsets while consumers decide whether packages land through `programs.vscode.profiles.default.extensions`, a `vscode-with-extensions` output, or an overlay alias; attrset priority differentiates pre-release/release and platform-specific/universal builds, and the README warns there is no reliable way to pick the semantically latest cached version. Source: https://github.com/nix-community/nix-vscode-extensions#the-extensions-attrset; https://github.com/collective/robotsuite/blob/032d1420bc5777a61873253a7f69e5c23d980bfa/devenv/modules/vscode.nix#L8-L33; https://github.com/belak/dotfiles/blob/e8c9e66f9b2f419183211aa7ccd5e02647371e67/nix/overlays.nix#L53-L55.
- Public personal estates split appearance/user settings and extension rows into separate Nix modules joined at the profile-default settings, matching Forge's own `{appearance,extensions}.nix` split; Stylix composes theme+font through `profiles.<name>.userSettings` rather than workspace files. Source: https://github.com/yunfachi/nix-config/blob/9ba35d6fc96a4eb86db72c91a0fc74e636c71f82/modules/programs/codium/settings.nix#L12-L70; https://github.com/nix-community/stylix/blob/14814ef555d8148ab82eba5054e654cd9eae3a1f/modules/vscode/meta.nix#L7-L27.
- The install-owner boundary is doctrine, not preference: VS Code's own docs make `.vscode/extensions.json` a recommendation surface and the user/CLI/managed system the install owner, and make workspace `settings.json` a project-shared surface with workspace scope overriding user scope and profile settings scoping user settings. The `microsoft/vscode` monorepo itself keeps its workspace recommendation set to seven IDs and its workspace settings to repo-specific generated-output hiding, schema bindings, test/debug outFiles, and PR behavior — the reference floor for the slimming leg. Source: https://code.visualstudio.com/docs/configure/settings; https://github.com/microsoft/vscode/blob/main/.vscode/extensions.json#L1-L13; https://github.com/microsoft/vscode/blob/main/.vscode/settings.json#L39-L180.

## [06]-[GAPS]

- Per-candidate glyph coverage: the manifest confirms the `productIconThemes` contribution point but not how completely each finalist restyles the built-in product-icon set — the fluent/carbon/material completeness delta against Dark Modern's ~200 IDs is unmeasured, so "which finalist actually looks finished" is undecided.
- Manifest security posture per finalist: product-icon themes are font+JSON and presumed inert, but `native_code`, `postinstall_behavior`, and `secret_touching` — the manifest vocabulary the roster requires — are unconfirmed per candidate; the admission row cannot be written until each finalist is vetted against that vocabulary.
- Open VSX availability and VSIX hash for each finalist, needed the moment the VS Code lane moves from `marketplace-cli` to `nix-vscode-extensions` generated rows.
- Drift-cull verdicts: the 40 extras carry redundancy flags but no per-row keep/cull/absorb decision tied to a Forge capability (roster duplicate, built-in duplicate, genuinely additive) — the operator-decided cull needs that mapping filled before doctor can ledger verdicts.
- Keybindings-merge precedent: the OSS corpus shows only wholesale Home-Manager `keybindings.json` generation; no observed estate pairs a managed `keybindings.json` with a sentinel-merge rail, so the merge pattern the earned rail may want is unproven in the wild.
