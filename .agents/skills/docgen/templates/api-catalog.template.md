# [<TIER>_API_<PACKAGE>]

<catalog-charter-1-2-lines: the external surface's owned capability, boundary, and rail — at most two single-line paragraphs, 500 characters total; never a roster recap, install note, or realization stamp.>

<!-- source-only: `.api` CATALOG SCHEMA — an external-library capability INDEX letting a design-page fence author call this surface with zero external lookups; abbreviated signatures only, never transcription fences.

BODY MODE — picked by surface shape, never taste:
  [A] ROSTER_FIRST (default, single-owner): `[01]-[PACKAGE_SURFACE]` `[02]-[PUBLIC_TYPES]` `[03]-[ENTRYPOINTS]` `[04]-[IMPLEMENTATION_LAW]`.
  [B] CONCEPT_PARTITIONED (large multi-namespace substrate re-exporting many owners): `[01]-[PACKAGE_SURFACE]`, one `## [NN]-[<CONCEPT>]` per owned namespace (each with its own `[<CONCEPT>_TYPE_SCOPE]:`/`[<CONCEPT>_ENTRY_SCOPE]:` sub-blocks + tables), terminal `## [NN]-[IMPLEMENTATION_LAW]`. `[STACKING]` and `[RAIL_LAW]` stay in the terminal law section in both modes.
  [C] RESOURCE_PROVIDER (IaC provider SDK whose surface is resource CLASSES keyed by inputs and outputs, `[TYPE_FAMILY]` collapsing to one uniform `class`): `[01]-[PACKAGE_SURFACE]` `[02]-[RESOURCES]` (a `[RESOURCE_SCOPE]:` sub-lead, then the resource columns) `[03]-[ENTRYPOINTS]` (provider ctor, data-source functions, config on the standard columns) `[04]-[IMPLEMENTATION_LAW]`; real value types land in a `[02]` type table under the RESOURCES roster, never a renamed column.

SIGNATURES — abbreviated in the cell; the full declaration lives on the composing design page. Repair a standing fence by extending its table within the 150-column render, else collapse overloads into inline family records; every repair removes lines. Carry the caller's three facts — member name, argument shape, return shape — nothing else:
  C# / TS  `Owner.member(TypeA, TypeB)` or `Owner.make(Type) -> Refined` — namespace dropped (owned in `[01]`), parameter TYPES only, `-> Ret` only when load-bearing; a TS generic collapses to its resolved shape, never its conditional/mapped type-level machinery.
  Python   `member(arg, arg, *, kw) -> Ret` — parameter NAMES with the `*` / `/` markers (the call contract), type hints stripped; a shared-kwarg family hoists one `- <family> carry: kw, kw` lead line above the table.

COLUMNS — a closed set, never renamed per file:
  `[02]` types       = `[INDEX] [SYMBOL] [TYPE_FAMILY] [CAPABILITY]`                  ([TYPE_FAMILY]: union / smart-enum / value-object / struct / class / interface / enum / delegate)
  `[02]` resources   = `[INDEX] [SYMBOL] [RESOURCE_FAMILY] [KEY_ARGS] [KEY_OUTPUTS]`  (mode [C] only; [RESOURCE_FAMILY] the grouping service namespace, [KEY_ARGS]/[KEY_OUTPUTS] the load-bearing required inputs and resolved outputs)
  `[03]` entrypoints = `[INDEX] [SURFACE] [SHAPE] [CAPABILITY]`                       ([SHAPE]: static / instance / factory / ctor / property / operator / fold)
    [SHAPE] resolves on the DECLARING type, never the call site: an extension, module-level, or free function reads `static` whatever fluent chain it joins, and `instance` claims the receiver type declares the member. Spell the row `Receiver.verb(args)` either way, and name the declaring static class beside its namespace wherever a caller needs the import.
  `[CONSUMER]` rides as an optional column ONLY where the binding consumer is load-bearing and varies per row; no per-row `[RAIL]` column — the rail is one `[01]` field.

MEMBERS — table rows or one inline token line (`[<TYPE>]: `a` `b` `c``); never a run-on `- Members: a, b, c` bullet or a `[SLUG]: - Members:` card cluster; a row that will not fit relieves its cells or splits into sibling scopes — a table is never torn into prose. Rows are unbounded; the 150-column width cap is the only size law.

CURRENCY — only the library's live current surface: an obsolete, deprecated, or superseded member, overload, or import path drops whole, the live replacement catalogued in its place, and every `use Y instead` / `replaced by` / `formerly` / `in older versions` phrasing removes silently, no tombstone; a domain symbol genuinely named `Version`/`Legacy`/`Obsolete` that IS the live surface stays. -->

## [01]-[PACKAGE_SURFACE]

[PACKAGE_SURFACE]: `<package-id>`
- package: `<package-id>` (<SPDX-expression>)
- <asset-field>: <what ships and the ABI it binds>
- rail: <one-line role this package plays in the branch>

<!-- source-only: field labels are lowercase and closed. Required: `package`, `rail`, and the language asset field —
  C#      `- assembly:` `<dll>`   `- namespace:` `<ns>, <ns>`
  Python  `- module:` `<import-name>`   `- namespaces:` `<ns>, <ns>`
  TS      `- module:` <esm/cjs shape, subpath exports>   `- runtime:` <node/browser/isomorphic; peer floor>
Optional-by-condition, omitted when it decides nothing: `target`, `abi`, `plane`, `role`, `depends`. `package`/`packages` carries admitted identifier(s) and license only — repo coordinates, implementation language, install names, asset mechanics, package-manager absences, and dependency narration belong to their owning fields or disappear; a verified license expression rides the package line without backticks, an unknown one omits the parentheses, and license names stand without permissive/copyleft/redistribution/obligation glosses or any holder, publisher, author, or organization. ABI and admission consequences stay in their owning fields or `[LOCAL_ADMISSION]`. NO `version` field in any form — the manifest owns versions; a multi-package catalog stacks one `[PACKAGE_SURFACE]:` record per package, never a merged list. -->

## [02]-[PUBLIC_TYPES]

[PUBLIC_TYPE_SCOPE]: <what this cluster of types is>

| [INDEX] | [SYMBOL]   | [TYPE_FAMILY]      | [CAPABILITY]                |
| :-----: | :--------- | :----------------- | :-------------------------- |
|  [01]   | `<Symbol>` | <family-1-2-words> | <capability-phrase>         |
|  [02]   | `Shape`    | union              | the closed shape vocabulary |
|  [03]   | `Variant`  | smart-enum         | the bounded case set        |

## [03]-[ENTRYPOINTS]

[ENTRYPOINT_SCOPE]: <what these surfaces do>

| [INDEX] | [SURFACE]                   | [SHAPE]  | [CAPABILITY]                       |
| :-----: | :-------------------------- | :------- | :--------------------------------- |
|  [01]   | `Shape.refine(Variant)`     | instance | refine one shape to canonical form |
|  [02]   | `Shape.of(Type) -> Refined` | factory  | admit a raw value to the surface   |

<!-- source-only: one member per row, signature abbreviated per the schema rule; a load-bearing behavioral caveat a signature cannot show — a discarded return, an in-place mutation, a null-despite-signature — rides one `- \`Owner.member\`: <caveat>` line after the table, never a wider cell or a torn card. -->

## [04]-[IMPLEMENTATION_LAW]

[TOPOLOGY]:
- <the invariant law every op on this surface folds through>

[STACKING]:
- `<sibling-package>`(`.api/<path>`): <exact member-level seam — what this surface's outputs become on the sibling's rail>
- <within-lib-owner>: <how the owning folder or kernel composes this surface to its richest depth>

[LOCAL_ADMISSION]:
- <accept-in-repo rule>

[RAIL_LAW]:
- Package: `<package-id>`
- Owns: <the capability this catalog is the sole owner of>
- Accept: <the composed shapes this package's role admits>
- Reject: <the hand-rolled or naive form a denser owner forecloses>

<!-- source-only: `[IMPLEMENTATION_LAW]` is the sole terminal section, owners ordered `[TOPOLOGY]` `[STACKING]` `[LOCAL_ADMISSION]` `[RAIL_LAW]`; `[STACKING]` and `[RAIL_LAW]` are required, an optional owner with no current law omits without `(none)`. Integration belongs to `[STACKING]`; a distinct concern becomes a corpus-wide owner here before any instance uses it. `[STACKING]` evolves whenever verified package or substrate surfaces expose a stronger composition and carries BOTH axes at operator depth — one bullet per composing sibling `.api` naming the exact member-level seam (this surface's output into the sibling's named member, both ends verified against the substrate tier and the named sibling catalog) and one within-library bullet; a bare package-name row with no member on both ends is the shallow-stacking defect. `[RAIL_LAW]` is structural — `Owns`/`Accept`/`Reject` derive from THIS package's real surface, `Reject` naming the hand-rolled form composing it deletes; a `[RAIL_LAW]` that pastes between unrelated packages is the byte-copy defect. -->
