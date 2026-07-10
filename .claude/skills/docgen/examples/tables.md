# [TABLE_CRAFT]

Table repair is symptom-indexed: each entry names one defect an agent already sees in a grid, carries the fixed Detection / Rejected / Accepted / Reason / Reframe card, and shows both table shapes as tiny fences. Repair preserves the grid — hoist, split, extract, relieve, and re-pad in place; the conversion entries fire only after every in-place relief fails.

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

## [04]-[BINARY_FIELD]

A boolean column mixes truthy and falsy spellings, forcing a per-row normalization the reader must carry.

- Detection: A boolean column spelled inconsistently down the rows.
- Rejected:
    ```markdown rejected
    | [INDEX] | [SYMBOL] | [PURE]  |
    | :-----: | :------- | :-----: |
    |  [01]   | `Alpha`  |    Y    |
    |  [02]   | `Beta`   |  false  |
    |  [03]   | `Gamma`  | enabled |
    ```
- Accepted:
    ```markdown accepted
    | [INDEX] | [SYMBOL] | [PURE] |
    | :-----: | :------- | :----: |
    |  [01]   | `Alpha`  |  yes   |
    |  [02]   | `Beta`   |   no   |
    |  [03]   | `Gamma`  |  yes   |
    ```
- Reason: One fixed pair of one-word semantic values makes the column scannable; mixed spellings fork one binary state into many tokens.
- Reframe: Pick one pair — `yes` and `no` — and spell every cell from it.

## [05]-[HEADER_RESTATES_CELLS]

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

## [06]-[PROSE_CRAMMED_CELL]

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

## [07]-[SENTENCE_ROWS]

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

## [08]-[INDEX_LABEL_PROSE]

The rows carry exactly an index, a label, and one prose clause — the indexed-list shape, not a table.

- Detection: The table holds exactly an index, a bracketed label, and one prose clause per row.
- Rejected:
    ```markdown rejected
    | [INDEX] | [LABEL]  | [DETAIL]                                   |
    | :-----: | :------- | :----------------------------------------- |
    |  [01]   | `QUEUED` | accepted for the sequence, not yet running |
    |  [02]   | `ACTIVE` | executing inside the record scope          |
    ```
- Accepted:
    ```markdown accepted
    - [01]-[QUEUED]: Accepted for the sequence, not yet running.
    - [02]-[ACTIVE]: Executing inside the record scope.
    ```
- Reason: Index, label, and one prose clause is the indexed-list shape; a prose column disqualifies the table and cards over-structure a lone clause.
- Reframe: Demote to `- [NN]-[LABEL]: Prose.` entries in document order.

## [09]-[HAMFISTED_TEARDOWN]

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

## [10]-[LINKS_IN_CELLS]

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

## [11]-[SEQUENCE_ROWS]

The rows are ordered steps a reader executes in order — a sequence wearing a grid — so the standardized carrier is the `OrderedStep` record set, one of the two earned conversions.

- Detection: Rows are steps with an execution order; the action column carries imperative commands; row order is the payload.
- Rejected:
    ```markdown rejected
    | [INDEX] | [ACTION]                                   | [VERIFY]          |
    | :-----: | :----------------------------------------- | :---------------- |
    |  [01]   | Install the runtime: `<command-a>`         | `<check-a>` lists |
    |  [02]   | Authenticate: `<command-b>` (keyring, SSH) | `<check-b>`       |
    ```
- Accepted:
    ```markdown accepted
    1. Install the runtime.
        - Command: `<command-a>`
        - Verify: `<check-a>` lists the runtime
    2. Authenticate.
        - Command: `<command-b>` (keyring, SSH)
        - Verify: `<check-b>`
    ```
- Reason: A table asserts comparable rows; a sequence's payload is order plus per-step fields, which is the `OrderedStep` shape, and commands crammed into cells blow the budget.
- Reframe: Convert ordered steps to numbered `OrderedStep` records carrying `Command`/`Verify` field lines; this and the type-standard-owned shape are the only earned conversions.

## [12]-[MISSING_INDEX]

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

## [13]-[SUB_LETTERED_INDEX]

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
