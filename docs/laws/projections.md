# [PROJECTIONS]

Machine-surface law extending `design.md` onto the consumers of Nix-owned vocabulary: Lua runtime configuration for editor and terminal hosts, and generated declarative config in every grammar. Nix declares vocabulary and policy once; every consumer indexes projections of that one owner. Apply when writing or reviewing Lua configuration or generated KDL, TOML, JSON, or Lua config; a finding cites the card it breaks.

## [01]-[LUA_CONSUMERS]

[PROJECTION_CONSUMER]:

- Law: Lua consumes Nix-generated vocabulary modules as typed tables and owns only editor or terminal runtime behavior; installation, paths, generated constants, and config files stay with Nix.
- Rejected: Private palettes, duplicated key rows, `io.open` parsing of generated text at startup, cross-tool doctrine or package lists defined in Lua.
- Example: `local palette = require("palette")`

[SETUP_OWNERS]:

- Law: One plugin or host surface gets one dense setup owner with row-derived command, key, and projection groups.
- Rejected: Many files each toggling one plugin field, scattered `setup` calls for one concern.
- Example: `require("shape").setup({ modes = modes, actions = actions })`

[TABLE_DISPATCH]:

- Law: Tables map modes, keys, actions, formatters, and callbacks; loops apply host APIs once, and closed mode families enumerate every supported case so an unknown mode faults at setup.
- Rejected: `if` ladders over mode strings, repeated keymap calls with copied opts, default fallthrough callbacks, partial action maps.
- Example: `for _, row in ipairs(rows) do vim.keymap.set(row.mode, row.key, row.action, row.opts) end`

[HOST_APIS]:

- Law: Host-native builders, setup tables, callback contracts, and state abstractions carry their own semantics; local code composes policy rows on top.
- Rejected: Reimplementing host semantics in Lua wrappers, manual globals tracking toggle state, autocmd stacks duplicating plugin lifecycle.
- Example: `local config = wezterm.config_builder()`

[BUILD_ONCE_CALLBACKS]:

- Law: Host callback-registration APIs (`wezterm.action_callback` and peers) register permanently per call — every action and handler builds once per config generation as a row projection; per-press choice logic lives inside the once-registered callback.
- Rejected: Callback construction inside press, open, or event bodies (each call leaks a registration), palette or selector entries rebuilt per invocation.
- Example: `local pick = wezterm.action_callback(function(win, pane) choose(rows, win, pane) end)`

[GENERATED_TABLE_FIDELITY]:

- Law: A Lua consumer of a Nix row table indexes the generated table directly, and every highlight group or host identifier a projection binds is verified against the plugin's real names from source.
- Rejected: Hand-written key mirrors of generated tables (the two-edit diff returns), theme roles bound to guessed group names (the binding fails silently forever), identity fields restated beside the row that derives them, kernel jq programs enumerating vocabulary keys instead of deriving via `to_entries`.
- Example: `for ft, row in pairs(rows) do lint.linters_by_ft[ft] = row.linters end`

[DETERMINISTIC_STARTUP]:

- Law: Packages and plugins arrive from Nix; Lua startup is deterministic and side-effect-light.
- Rejected: Runtime package installation, network fetches, bootstrap managers inside config.
- Example: `require("plugins.primary")`

## [02]-[GENERATED_CONFIG]

[PROJECTION_ONLY]:

- Law: Generated config is projection, never primary truth: one Nix owner declares vocabulary and policies, and generated files are terminal egress with deterministic ordering.
- Rejected: Hand-maintained JSON, TOML, or KDL beside equivalent Nix rows, comments restating source doctrine, generation history, or freshness notes inside generated files.
- Example: `xdg.configFile."shape/config.toml".source = (pkgs.formats.toml {}).generate "shape" cfg;`

[STRUCTURED_GENERATORS]:

- Law: Formats with a native generator use it; string templates survive only for host grammars generators cannot express, with every interpolated value typed and escaped before interpolation.
- Rejected: JSON or TOML through heredocs, manual quote escaping by convention, KDL fragments with repeated literals.
- Example: `(pkgs.formats.json {}).generate "shape" { rows = cfg.rows; }`

[ROW_RENDER_POLICY]:

- Law: Config rows carry their own render policy — kind, location, permissions, command, style — and renderers are pure folds over named, sorted rows.
- Rejected: One giant template with special-case interpolations, stateful render accumulation, order dependent on attrset accident.
- Example: `lib.concatMapStringsSep "\n" render (lib.sortOn (r: r.name) rows)`

[SELF_REWRITING_TARGETS]:

- Law: A generated config for an app that rewrites its own file merges by ownership class — declared keys win, app-persisted keys survive, unknown roots pass through — and the activation lints the exact staged bytes with the app's own validator before they reach the live file, failing the switch with a named error.
- Rejected: Enumerated `has()` preservation lists (a clobber list waiting for the app's next persisted key), wholesale replacement of a live file carrying operator GUI state, staging unvalidated bytes into a config whose schema error yields a silently dead surface.
- Example: `jq -s '(.[0] | del(.profiles)) + { profiles: mergedProfiles }' "$live" "$staged"`

[TOKEN_OWNERS]:

- Law: Theme, color, and keybinding vocabularies have one owner each; palette roles, ANSI projections, chord rows, labels, and every per-app rendering derive from it.
- Rejected: Private hex values in app configs, chord rows copied between KDL, Lua, and shell, label drift between UI and action.
- Example: `renderBind = r: ''bind "${r.key}" { ${r.action} }'';`

[TYPED_EDGE]:

- Law: Config schemas are typed at the Nix edge — `strMatching`, `enum`, `attrsOf submodule`, `listOf`, package path values — before any rendering.
- Rejected: Arbitrary strings accepted for percent geometry, enum modes, colors, or command names.
- Example: `type = lib.types.strMatching "^[0-9]+%$";`

[SHARED_ROW_FEEDS]:

- Law: One row owner feeds both generated config and derived script arguments, and file locations belong to XDG or Home Manager owners.
- Rejected: CLI flags hardcoded in shell while config renders from different literals, scripts writing configs into `$HOME` at runtime, interactive grants as runtime setup.
- Example: `args = lib.escapeShellArgs [ row.x row.y row.width row.height ];`
