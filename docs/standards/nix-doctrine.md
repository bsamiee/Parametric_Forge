# [NIX_DOCTRINE]

Machine-surface law extending the design doctrine onto Nix modules, shell kernels packaged from Nix, Lua runtime consumers, and generated declarative config. Nix owns packages, environment, vocabulary, and generated data; every other surface consumes projections of one Nix owner.

## [01]-[USE_WHEN]

Apply when writing or reviewing Nix modules, overlays, flake composition, `writeShellApplication` bodies, Lua configuration for editor or terminal hosts, and generated KDL, TOML, JSON, or Lua config. A finding cites the card it breaks.

## [02]-[MODULES]

[OWNER_MODULES]:
- Law: One module owns one concern; typed `submodule` options admit raw config once, and every consumer reads the owner's derived projections.
- Rejected: Wrapper modules around one option, untyped attrsets, stringly booleans, consumer-side validation, mixed system and user scope, scattered `home.file` writes.
- Example: `options.shape.rows = lib.mkOption { type = lib.types.attrsOf rowType; default = {}; };`

[ROW_DISPATCH]:
- Law: Dispatch is attrset and list algebra — `lib.mapAttrs`, `lib.genAttrs`, `lib.foldl'`, row-indexed builders — and growth lands as rows on the owning surface.
- Rejected: `if`/`else` ladders per package, per-host copies, sibling `mkFooA`/`mkFooB` helpers, splitting one dispatch family across files to meet a line target.
- Example: `lib.mapAttrs (_: row: pkgs.writeShellApplication row) rows`

[OVERLAYS]:
- Law: Overlays are package-admission seams: `final: prev:` rows admit upstream packages, apply minimal derivation changes, and expose canonical names.
- Rejected: Home Manager logic inside overlays, convenience wrapper packages, package aliases hiding behavior.
- Example: `final: prev: { shape = prev.shape.overrideAttrs (old: { postPatch = (old.postPatch or "") + patch; }); }`

[COMPOSITION_ROOT]:
- Law: The flake composition root admits inputs once, and `perSystem` derives packages, apps, checks, and the formatter from one package set.
- Rejected: Duplicated per-system package attrsets, host conditionals outside `perSystem`, ad hoc system strings inside modules.
- Example: `perSystem = { pkgs, ... }: { packages = lib.genAttrs names (n: pkgs.${n}); };`

[POLICY_ROWS]:
- Law: Closed policy rows replace flag clusters; a row carries package, command, environment, service shape, lock mode, and projection behavior together.
- Rejected: Boolean option clusters, `enableX`/`useY` knobs, mode strings that downstream code reconstructs into behavior.
- Example: `policies.primary = { mutates = false; render = row: builtins.toJSON row; };`

[IMPORTS_AND_PATHS]:
- Law: Imports are topology with minimal module parameters, and store paths stay symbolic through package references until terminal projection.
- Rejected: Kitchen-sink lambda args, `with pkgs;` at file level, hardcoded executable paths, PATH-sensitive commands, string interpolation before package ownership is fixed.
- Example: `command = "${pkgs.coreutils}/bin/true"; args = lib.escapeShellArgs row.args;`

[KERNELS_AND_RECEIPTS]:
- Law: Host mutation lives in named `writeShellApplication` kernels, and every Nix-produced command emits structured receipt fields — input owner, derived path, action, status, proof surface.
- Rejected: Evaluation-time shell guessing, shell fragments spread across config, build or activation output that only prints success text.
- Example: `pkgs.writeShellApplication { name = "shape"; runtimeInputs = [ pkgs.jq ]; text = script; }`

## [03]-[SHELL_KERNELS]

[KERNEL_BODIES]:
- Law: Bash performs admission, subprocess execution, locks, traps, and exit discipline; `jq` owns JSON shape, filtering, projection, and envelope assembly.
- Rejected: Large Bash decision bodies, Bash loops transforming JSON, `awk` over structured payloads, regex extraction from JSON text, mutating loops computing domain projections.
- Example: `jq -n --arg verb "$verb" --argjson ok true '{verb:$verb, ok:$ok}'`

[CATALOG_DISPATCH]:
- Law: One generated catalog drives command dispatch; a verb row declares handler, mutability, lock mode, argspec, and JSON support, and the dispatcher applies lock and admission before the handler runs. Retired spellings fault with one replacement hint.
- Rejected: `if [[ $1 == ... ]]` forests, per-verb hand parsing, verb aliases, silent env-var fallbacks, locking decided inside handler bodies.
- Example: `handler="$(jq -r --arg v "$verb" '.[]|select(.verb==$v).handler' "$catalog")"`

[ENVELOPE_RAIL]:
- Law: Exit code plus one JSON envelope is the rail; every failure uses the same shape, and envelope builders emit only sanitized booleans, kinds, names, and row metadata.
- Rejected: Text-only errors, partial JSON on success only, raw sockets, host absolute paths, DSNs, or token material in agent-facing JSON, `sed` scrub passes over arbitrary output.
- Example: `jq -n --arg code "$code" --arg detail "$detail" '{ok:false,error:{code:$code,detail:$detail}}'`

[PARAMETERIZED_INPUT]:
- Law: Environment values admit at the top, defaults are named once, paths derive once, and argv arrays build through `mapfile` or `readarray`.
- Rejected: Inline paths, unquoted command strings, user or host literals, pattern-matched absolute paths.
- Example: `mapfile -t args < <(jq -r '.args[]' "$row_file")`

[RECEIPTS_AND_LOCKS]:
- Law: State touches append one typed receipt row each — timestamp, command, target, derived identity, result — and mutation runs under one lock primitive with row-selected scope, timeout, and stale-owner recovery.
- Rejected: Generic logs as proof, prose summaries as results, opportunistic lock files, per-command lock code, lockless mutation beside locked mutation.
- Example: `exec 9>"$lock"; flock -w "$wait_s" 9`

[ADMITTED_SUBPROCESS]:
- Law: Every executable arrives through `runtimeInputs` or an absolute store path, and feature absence becomes a railed fault.
- Rejected: Calling tools undeclared in `runtimeInputs`, interactive shell functions, `which`-based discovery.
- Example: `runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.docker-client ];`

## [04]-[LUA_CONSUMERS]

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

[DETERMINISTIC_STARTUP]:
- Law: Packages and plugins arrive from Nix; Lua startup is deterministic and side-effect-light.
- Rejected: Runtime package installation, network fetches, bootstrap managers inside config.
- Example: `require("plugins.primary")`

## [05]-[GENERATED_CONFIG]

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
