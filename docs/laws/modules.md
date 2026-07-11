# [MODULES]

Machine-surface law extending `design.md` onto the Nix module graph: modules, overlays, the package manifest, and flake composition. Nix owns packages, environment, vocabulary, and generated data; every other surface consumes projections of one Nix owner. Apply when writing or reviewing Nix modules, overlays, or flake composition; a finding cites the card it breaks.

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

[PACKAGE_MANIFEST]:

- Law: Non-nixpkgs package and extension admission is a manifest row — provenance, version policy, per-platform assets and hashes, license, patch family, cache class, update engine, retention, projection — and overlays, public packages, apps, HM rosters, and extension directories are folds of the rows. Direct-package projection is the default; an overlay-override row names its dependency-graph reason. Nixpkgs-followed admissions carry no frozen version copy — the JSON projection resolves live pins from the package set.
- Rejected: Version/url/hash triples inside derivation bodies, a second hand-maintained public package list, per-app plugin updater semantics, registry-trust admission of extension corpora, overlay mutation without a named graph reason.
- Example: `packages = lib.mapAttrs (name: _: forgePkgs.${name}) (lib.filterAttrs (_: row: row.projection.package or false) manifest.packages);`

[UPSTREAM_LAYOUT_GUARDS]:

- Law: Every install step that depends on upstream layout — a strip, a wrapper target, a conditional install branch — carries an existence guard that fails the build with a named drift error; a package's layout vocabulary is single-owner, read by consumers through `passthru` projections; a kernel file is admitted only when install logic differs — a data-only delta is a manifest row; a pure refactor of package derivations proves identity by out-path equality, and `passthru` projections of row data at the installed root ride `finalAttrs.finalPackage` (`placeholder "out"` serves only build-time text).
- Rejected: Silent `rm -rf` of expected paths (drift ships a fatter output), silent-skip wrapper guards (drift ships a thinner one), consumer-side re-spelling of package subpaths, branches upstream facts prove dead, registry-derived regex alternations without `lib.escapeRegex` and an empty-set guard.
- Example: `[ -x "$runtime/$tool" ] || { echo "patch_drift: $tool missing" >&2; exit 1; }`

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

[BOTH_OS_EVAL]:

- Law: A module the shared home graph imports evaluates on every host; a platform-only package interpolation gates at eval (`lib.optionalString pkgs.stdenv.hostPlatform.isDarwin`) with a runtime emptiness guard, and an option defined under a platform-gated import is consumed cross-platform only through an `or` default. The static gate is the pair: the darwin system build AND the NixOS toplevel drv eval — `nix flake check` alone proves neither host's toplevel.
- Rejected: Darwin-only `pkgs.*` interpolated unconditionally in a both-OS module, cross-gate option reads without a default, a switch proven on one host standing in for the other's eval.
- Example: `tn = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin "${pkgs.terminal-notifier}/bin/terminal-notifier";`
