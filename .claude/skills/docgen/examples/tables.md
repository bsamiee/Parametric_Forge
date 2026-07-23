# [TABLE_CRAFT]

Table repair opens with the eligibility triple: a failed triple converts the container whole before any cell moves, a passing grid repairs in place, and a row family resisting every move converts last, structure intact.

## [01]-[HIGH_COMPLEXITY_DONE_RIGHT]

A high-column table that passes eligibility is the correct carrier; column count is never the disqualifier, a prose cell is.

- Detection: Rows share one comparison question, every column resolves to an atomic value, and more than one row exists.
- Rejected:
    ```markdown rejected
    `Alpha` is a scalar of arity one defaulting to `"zero"`, while `Beta`is a many-arity vector defaulting to `"unit"` and `Gamma` a many-arity
    tensor defaulting to `"eye"`.
    ```
- Accepted:
    ```markdown accepted
    | [INDEX] | [VARIANT] | [KIND] | [ARITY] | [DEFAULT] |
    | :-----: | :-------- | :----- | :-----: | :-------- |
    |  [01]   | `Alpha`   | scalar |   one   | `"zero"`  |
    |  [02]   | `Beta`    | vector |  many   | `"unit"`  |
    |  [03]   | `Gamma`   | tensor |  many   | `"eye"`   |
    ```
- Reason: Every column resolves to one atomic value across a shared question; prose hides the grid and forces a re-parse.
- Reframe: Keep the dense table when eligibility holds; a prose cell disqualifies it, column count does not.

## [02]-[MULTI_VALUE_CELL]

A cell joins two or more lookup values, so one index no longer maps to one member and the grep breaks.

- Detection: A cell joining lookup values with a slash, a comma, or a conjunction.
- Rejected:
    ```markdown rejected
    | [08] | `Alpha` / `Beta` / `Gamma` / `Delta` / `Epsilon` | hosted | provider-run |
    ```
- Accepted:

    ```markdown accepted
    Every hosted provider tool is one row.

    | [INDEX] | [SYMBOL] | [CAPABILITY] |
    | :-----: | :------- | :----------- |
    |  [08]   | `Alpha`  | web search   |
    |  [09]   | `Beta`   | code exec    |
    |  [10]   | `Gamma`  | file search  |
    ```

- Reason: Each row is one atomic lookup keyed one-to-one with its index; a slashed cell collapses many members past the cell budget, and a value shared by every row is a universal column that belongs in the lead.
- Reframe: Fan the joined values to one row each; lift any value shared by every fanned row to the lead sentence.

## [03]-[UNIVERSAL_COLUMN]

A column carries one identical value down every row, restating a universal fact per line instead of stating it once.

- Detection: A column whose cells all hold one identical value.
- Rejected:
    ```markdown rejected
    | [INDEX] | [SYMBOL] | [RAIL]        |
    | :-----: | :------- | :------------ |
    |  [01]   | `Alpha`  | serialization |
    |  [02]   | `Beta`   | serialization |
    |  [03]   | `Gamma`  | serialization |
    ```
- Accepted:

    ```markdown accepted
    - [RAIL]: serialization

    | [INDEX] | [SYMBOL] |
    | :-----: | :------- |
    |  [01]   | `Alpha`  |
    |  [02]   | `Beta`   |
    ```

- Reason: A value constant down a column decides nothing per row; a `[VALUE]:` card states it once and narrows the grid to what varies.
- Reframe: Extract the universal value to a `[KEY]: value` card above the table and delete the column.

## [04]-[HEADER_RESTATES_CELLS]

Every cell restates a word the header already owns, widening the row for nothing.

- Detection: Every cell in a column repeats a word the header implies, or opens with the same lead word.
- Rejected:
    ```markdown rejected
    | [INDEX] | [MODE]         | [WHEN]         |
    | :-----: | :------------- | :------------- |
    |  [01]   | mode interview | when ambiguous |
    |  [02]   | mode plan      | when settled   |
    ```
- Accepted:
    ```markdown accepted
    | [INDEX] | [MODE]      | [WHEN]    |
    | :-----: | :---------- | :-------- |
    |  [01]   | `interview` | ambiguous |
    |  [02]   | `plan`      | settled   |
    ```
- Reason: The header owns the repeated word once; a cell that restates its header wastes the column and widens every row.
- Reframe: Hoist the shared word into the header and strip it from every cell.

## [05]-[PROSE_CRAMMED_CELL]

A cell packs a multi-clause caveat, a signature, and behavior into a slot the column cannot hold.

- Detection: A cell packing signatures and behavior clauses into one slot.
- Rejected:
    ```markdown rejected
    | [INDEX] | [SYMBOL] | [ROLE]                                                                                                      |
    | :-----: | :------- | :---------------------------------------------------------------------------------------------------------- |
    |  [02]   | `Shape`  | stacked layers via `from_profile(...)`, then `refine()` instances them, and `peel()` strips the outer shell |
    ```
- Accepted:

    ```markdown accepted
    `Shape` stacks layers; `from_profile` extrudes a profile and `peel` strips the outer shell.

    | [INDEX] | [SYMBOL]             | [KIND] |
    | :-----: | :------------------- | :----- |
    |  [02]   | `Shape`              | object |
    |  [03]   | `Shape.from_profile` | ctor   |
    ```

- Reason: The load-bearing caveat lives in a lead sentence the table cannot hold; each cell drops to one atomic member.
- Reframe: Move the invariant to prose before the table and split the crammed clause into atomic rows.

## [06]-[SENTENCE_ROWS]

Every row needs a comma-bearing sentence to explain itself, so the table is the wrong container.

- Detection: Every row needs a sentence with internal commas; the rows share no atomic column.
- Rejected:
    ```markdown rejected
    | [INDEX] | [MODE]      | [NOTE]                                                      |
    | :-----: | :---------- | :---------------------------------------------------------- |
    |  [01]   | `interview` | ask when requirements are ambiguous, unstated, or contested |
    |  [02]   | `plan`      | emit a decisions table plus a ready-to-run prompt           |
    ```
- Accepted:

    ```markdown accepted
    [interview]:
    - Trigger: Requirements ambiguous, unstated, or contested
    - Output: Decisions table plus implementation prompt

    [plan]:
    - Trigger: Scope settled, sequence unresolved
    - Output: Ordered build steps
    ```

- Reason: A row that needs a comma-bearing sentence is a card; the GroupedRecord carries field lines the cell budget forbids.
- Reframe: Promote each row to a `[KEY]:` card with `- Field: value` lines.

## [07]-[HAMFISTED_TEARDOWN]

A row family resists every table fix, and the teardown flattens it to mega-prose or dumps it to a bare unlabeled list — both destroy the structure the table held.

- Detection: A row family resists split, hoist, extract, and relief, and the fix reaches for a paragraph flood or an unkeyed dump.
- Rejected:
    ```markdown rejected
    `Shape` extrudes a profile into stacked layers and instances the
    refined ones; `Variant` peels the outer and inner shells while `Region`
    detaches the mid layers and re-solves adjacency across the body.
    ```
    ```markdown rejected
    - `Shape` extrude stack instance
    - `Variant` peel outer inner
    - `Region` detach mid resolve
    ```
- Accepted:
    ```markdown accepted
    - [01]-[EXTRUDE]: `Shape` stacks layers from a profile.
    - [02]-[PEEL]: `Variant` separates outer and inner shells.
    - [03]-[DETACH]: `Region` re-solves mid-layer adjacency.
    ```
- Reason: The mega-prose form drowns the lookup and the bare list strips every label and index; the structured conversion keeps a greppable key per member without a column set the family rejects.
- Reframe: Convert to a labeled indexed list or a GroupedRecord set, never a paragraph flood or an unkeyed dump.

## [08]-[LINKS_IN_CELLS]

A link rides inside a comparison cell, so it drifts with the attribute grid instead of a routing surface.

- Detection: A `[label](path)` link inside a cell of a table that also compares attributes.
- Rejected:
    ```markdown rejected
    | [INDEX] | [MODE]      | [DOC]                             |
    | :-----: | :---------- | :-------------------------------- |
    |  [01]   | `interview` | ambiguous scope [modes](modes.md) |
    |  [02]   | `plan`      | settled scope [build](build.md)   |
    ```
- Accepted:

    ```markdown accepted
    | [INDEX] | [MODE]      | [WHEN]    |
    | :-----: | :---------- | :-------- |
    |  [01]   | `interview` | ambiguous |
    |  [02]   | `plan`      | settled   |

    - `interview`: modes.md
    - `plan`: build.md
    ```

- Reason: A mixed table is not a routing table; the link belongs on a `- Key: path` line after the grid, not inside a comparison cell.
- Reframe: Strip links from attribute cells to a routing list below; keep an in-cell link only in a path-only routing table.

## [09]-[MISSING_INDEX]

An enumerable table drops the leading `[INDEX]` column or carries bare-word headers, breaking stable reference and census.

- Detection: An enumerable table over two rows lacks the centered `[INDEX]` column, or a header is not a bracketed rubric.
- Rejected:
    ```markdown rejected
    | Mode      | When      | Output |
    | :-------- | :-------- | :----- |
    | interview | ambiguous | prompt |
    | plan      | settled   | steps  |
    ```
- Accepted:
    ```markdown accepted
    | [INDEX] | [MODE]      | [WHEN]    | [OUTPUT] |
    | :-----: | :---------- | :-------- | :------- |
    |  [01]   | `interview` | ambiguous | `prompt` |
    |  [02]   | `plan`      | settled   | `steps`  |
    ```
- Reason: The `[INDEX]` column gives every row a stable reference and the bracketed rubric makes headers censusable across sibling tables.
- Reframe: Add the centered `[INDEX]` column numbered `[01]` onward and bracket every header as an uppercase rubric.

## [10]-[SUB_LETTERED_INDEX]

Rows carry invented sub-index tokens — `[1a]`, `[1b]` — to nest children under a parent row, breaking the `[NN]` sequence and the grid's flat-lookup contract.

- Detection: Index cells outside the sequential `[NN]` vocabulary, lettered or dotted to express hierarchy inside the grid.
- Rejected:
    ```markdown rejected
    | [INDEX] | [AXIS]        | [OWNER]       |
    | :-----: | :------------ | :------------ |
    |  [01]   | Panel algebra | `Panelize`    |
    |  [1a]   | Family axis   | `PanelFamily` |
    |  [1b]   | Panel wire    | `PanelField`  |
    ```
- Accepted:

    ```markdown accepted
    `Panelize` folds the algebra; its payload owners ride their own rows.

    | [INDEX] | [AXIS]        | [OWNER]       |
    | :-----: | :------------ | :------------ |
    |  [01]   | Panel algebra | `Panelize`    |
    |  [02]   | Family axis   | `PanelFamily` |
    |  [03]   | Panel wire    | `PanelField`  |
    ```

- Reason: A GFM grid is flat — a lettered sub-row asserts a hierarchy the table cannot render, breaks index grep, and defeats the fixer's renumbering; the parent relation lives in the lead or an owner column, never in the index vocabulary.
- Reframe: Fan sub-rows to sequential `[NN]` rows and carry the parent relation in the lead sentence or an owning column; a genuinely two-level family is two tables or a record set.
