# [<TIER>_API_<PACKAGE>]

<catalog-charter-1-2-lines: the external surface's owned capability, boundary, and rail in at most two single-line paragraphs and 500 characters total; never a roster recap, install note, or realization stamp.>

<!-- source-only: `.api` CATALOG SCHEMA — an external-library capability INDEX that lets a design-page fence author call this surface with zero external lookups. It is NOT a design page: it carries abbreviated signatures, never transcription fences.

BODY MODE — pick by owner count, never taste:
  A ROSTER_FIRST (default, single-owner): `[01]-[PACKAGE_SURFACE]` `[02]-[PUBLIC_TYPES]` `[03]-[ENTRYPOINTS]` `[04]-[IMPLEMENTATION_LAW]`.
  B CONCEPT_PARTITIONED (large multi-namespace substrate re-exporting many owners): `[01]-[PACKAGE_SURFACE]`, then one `## [NN]-[<CONCEPT>]` per owned namespace (each carrying its own `[<CONCEPT>_TYPE_SCOPE]:`/`[<CONCEPT>_ENTRY_SCOPE]:` sub-blocks + tables), then the terminal `## [NN]-[IMPLEMENTATION_LAW]`. `[STACKING]` and `[RAIL_LAW]` stay in the terminal law section in both modes.

SIGNATURES — abbreviated in the table cell, NEVER a transcription fence (the full declaration lives on the design page that composes this surface; a fence here only bloats the catalog). Repair a standing fence by extending its existing table while the canonical render stays within 150 columns; otherwise collapse overloads into inline family records. Every repair removes lines. Carry the caller's three load-bearing facts — member name, argument shape, return shape — and nothing else:
  C# / TS  `Owner.member(TypeA, TypeB)` or `Owner.make(Type) -> Refined` — namespace dropped (owned in `[01]`), parameter TYPES only, `-> Ret` only when the return is load-bearing; a TS generic collapses to its resolved shape, never its conditional/mapped type-level machinery.
  Python   `member(arg, arg, *, kw) -> Ret` — parameter NAMES kept with the `*` / `/` markers (the call contract), type hints stripped; a shared-kwarg family hoists to one `- <family> carry: kw, kw` lead line above the table.

COLUMNS are a closed set, never renamed per file:
  `[02]` types       = `[INDEX] [SYMBOL] [TYPE_FAMILY] [CAPABILITY]`   ([TYPE_FAMILY] from union / smart-enum / value-object / struct / class / interface / enum / delegate)
  `[03]` entrypoints = `[INDEX] [SURFACE] [SHAPE] [CAPABILITY]`         ([SHAPE] from static / instance / factory / ctor / property / operator / fold)
  An optional `[CONSUMER]` column rides ONLY where the binding consumer is load-bearing and varies per row. No per-row `[RAIL]` column — the rail is one `[01]` field, never a column that repeats it.

MEMBERS are table rows or one inline token line (`[<TYPE>]: `a` `b` `c``); never a run-on `- Members: a, b, c` bullet and never a `[SLUG]: - Members:` card cluster. A row that will not fit relieves its cells or splits into sibling scopes — a table is never torn into prose. Rows are unbounded; the 150-column width cap is the only size law.

CURRENCY — a catalog presents only the library's live current surface: an obsolete, deprecated, or superseded member, overload, or import path drops whole — catalog the live replacement, never the dead form beside a pointer — and every `use Y instead` / `replaced by` / `formerly` / `in older versions` phrasing removes silently, no tombstone. A domain symbol genuinely named `Version`/`Legacy`/`Obsolete` that IS the live surface is real surface, kept. -->

## [01]-[PACKAGE_SURFACE]

[PACKAGE_SURFACE]: `<package-id>`
- package: `<package-id>` (<SPDX-expression>)
- <asset-field>: <what ships and the ABI it binds>
- rail: <one-line role this package plays in the branch>

<!-- source-only: field labels are lowercase and closed. Required: `package`, `rail`, and the language asset field —
  C#      `- assembly:` `<dll>`   `- namespace:` `<ns>, <ns>`
  Python  `- module:` `<import-name>`   `- namespaces:` `<ns>, <ns>`
  TS      `- module:` <esm/cjs shape, subpath exports>   `- runtime:` <node/browser/isomorphic; peer floor>
Optional-by-condition, omitted when it decides nothing: `target`, `abi`, `plane`, `role`, `depends`. `package`/`packages` contains admitted identifier(s) and license only; repo coordinates, implementation language, install names, asset mechanics, package-manager absences, and dependency narration belong to their owning fields or disappear when another field already carries them. A verified license expression rides the package line without backticks; an unknown expression omits the parentheses. License names stand without permissive, copyleft, redistribution, or obligation glosses. Copyright holders, publishers, authors, and organizations never ride the record. ABI and admission consequences stay in their owning fields or `[LOCAL_ADMISSION]`. NO `version` field in any form — the manifest owns versions. A multi-package catalog stacks one `[PACKAGE_SURFACE]:` record per package, never a merged list. -->

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

<!-- source-only: one member per row, signature abbreviated per the schema rule above. A load-bearing behavioral caveat a signature cannot show — a discarded return, an in-place mutation, a null-despite-signature — rides one `- \`Owner.member\`: <caveat>` line after the table, never a wider cell and never a torn card. -->

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

<!-- source-only: `[IMPLEMENTATION_LAW]` is the sole terminal section. Its ordered owner set is `[TOPOLOGY]` `[STACKING]` `[LOCAL_ADMISSION]` `[RAIL_LAW]`; `[STACKING]` and `[RAIL_LAW]` are required, while an optional owner with no current law is omitted without `(none)`. Integration belongs to `[STACKING]`; a distinct concern becomes a corpus-wide owner here before any instance uses it. `[STACKING]` evolves whenever verified package or substrate surfaces expose a stronger composition and carries BOTH axes to operator depth: one bullet per composing sibling `.api` naming the exact member-level seam — this surface's output flowing into the sibling's named member, both ends verified by reading the substrate tier and named sibling catalog — and one bullet for within-library composition. A bare package-name row with no member on both ends is the shallow-stacking defect. `[RAIL_LAW]` is structural — `Owns`/`Accept`/`Reject` derive from THIS package's real surface, `Reject` naming the hand-rolled form composing it deletes; a `[RAIL_LAW]` that pastes between unrelated packages is the byte-copy defect. -->
