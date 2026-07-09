# [INFORMATION_STRUCTURE]

Information architecture for durable Markdown: which container carries which information, how tables and records are designed, and how sections hold their shape.

## [01]-[CONTAINER_CHOOSER]

Use the smallest carrier that preserves the reader job; a carrier earns its place only when deleting it removes a decision, lookup, update route, or machine-readable shape. When a signature matches several rows, the most specific wins.

| [INDEX] | [SIGNATURE]             | [READER_JOB]         | [CARRIER]                | [REJECTED_FORM]   |
| :-----: | :---------------------- | :------------------- | :----------------------- | :---------------- |
|  [01]   | one rule                | understand           | prose paragraph          | one-item list     |
|  [02]   | peer rules              | scan equivalents     | bullet list              | numbered list     |
|  [03]   | ordered actions         | execute sequence     | numbered steps           | bullet list       |
|  [04]   | actionable completion   | assert checked state | checklist                | bullet list       |
|  [05]   | finite lifecycle        | filter by state      | status record set        | status table      |
|  [06]   | multi-field item        | scan fields          | definition record        | one-row table     |
|  [07]   | closed vocabulary       | choose exact value   | vocabulary card          | prose list        |
|  [08]   | comparable rows         | compare attributes   | table                    | record set        |
|  [09]   | finite conditions       | resolve action       | decision table           | prose branches    |
|  [10]   | indexed labeled detail  | reference by index   | indexed list             | prose-cell table  |
|  [11]   | row detail              | update one row       | row-owned record         | wide table cell   |
|  [12]   | command or output       | run or compare       | command/output carrier   | prose transcript  |
|  [13]   | parser-owned shape      | preserve grammar     | machine-consumed record  | normalized prose  |
|  [14]   | topology or flow        | see relation         | diagram or text topology | prose walkthrough |
|  [15]   | interrupting constraint | interrupt            | callout                  | inline prose      |
|  [16]   | low-salience detail     | defer                | details block            | inline prose      |

[CARRIER_LAW]:
- A repeated paragraph pattern is a record set.
- A list item with asserted completion is a checkbox.
- A diagram that repeats a table is deleted.
- A command that has not run is an instruction, not a result.

## [02]-[TABLE_LAW]

Tables enumerate, cards legislate. A table is a lookup grid, not a prose container; it earns its place only when a reader crosses one row against one column to retrieve a single atomic fact. The instant any column holds a sentence, the table is the wrong container — convert before styling.

[TRUTH] — A table's strength is dense cross-row comparison at a glance: many rows, few atomic columns, one comparison question. Its weaknesses are structural: cells resist prose, columns multiply ceremony, a wide row hides its own reading order, and a half-empty grid asserts a rigor it does not have. A table is the strongest container in its narrow lane and the worst container one step outside it; the chooser decides the lane, and the surrounding prose absorbs what cells cannot hold.

[SCOPE]:
- This law binds every Markdown table in standards-controlled and instruction-file surfaces, including skill bodies, skill references, and tool READMEs. There is no lightweight-table exemption; a table too heavy for the law is the wrong container.

[ELIGIBILITY]:
- Build a table only when all three hold: rows share one comparison question, every column answers it with an atomic value, and more than one row exists. Fail any one and the carrier is a record, card, or prose.
- A single prose column disqualifies the table outright. A one-row table is a definition record. Rows with no shared comparison question are separate records.
- Use comparison, lookup, decision, matrix, support, or dependency forms only; never tables for sequences, heterogeneous records, narrative, or field lists.
- Eligibility is structural, never an enumeration license: a table whose rows mirror an owner whose system of record is elsewhere is a stale mirror however atomic its cells; the doc tables only its own registry or a tool-verified representation.

[CELL_BUDGET]:
- Each cell is one atomic unit: a value, marker, token, code span, proper noun, path, or a phrase of at most six words carrying no internal comma, semicolon, or clause-joining conjunction.
- A cell that wants a comma wants to be a card; a cell packing parallel values behind slashes wants one row per value. A cell that wraps to a second rendered line is over budget.
- The stub column is a short unique key — identifier, token, command, proper noun — never a sentence.
- A binary field carries one fixed pair of one-word semantic values, the same pair in every row; a column whose cells all hold one value is tautological — extract it to a `[VALUE]:` card beside the table and delete the column.

[HEADER_COMPRESSION]:
- Before writing cells, hoist every word the cells repeat into the header. Cells that each begin "when" belong under `[WHEN]` with the word dropped; cells that each name a file belong under `[TEMPLATE]` holding the path alone.
- Headers are one semantic word, two only when one loses the meaning; a header that decides nothing for the reader deletes its column.
- No cell restates its header, repeats another cell, or carries a value shared by the whole column; a shared value moves to the lead sentence or a `[VALUE]:` card.

[PROSE_RELIEF]:
- Cross-row invariants, reading rules, and shared consequences live in the lead sentence before the table or a note after it, never duplicated per cell; the prose around a table is a design surface, not decoration.
- When a row needs a sentence to explain itself, promote the whole table to a GroupedRecord or AnchoredRecord set; a pre-table GroupedRecord may carry table-level invariants when the key names the table concept.
- A row family that resists every table fix — split, hoist, extract, relieve — leaves the table as an indexed list or record set; a teardown that flattens the table into mega-prose lines or a bare unlabeled list destroys the structure it was meant to save.

[LINKS]:
- A cell holds a link only in a pure routing table where the path is the sole value and no other column carries prose. A table that also compares attributes is not a routing table; move its links to a following `- Key: path` field line or a row-owned record.
- Never mix a prose column and a link column in one table.

[MECHANICS]:
- Enumerable tables open with a centered `[INDEX]` column numbered `[01]` through `[NN]`; non-enumerable matrices use a bracketed stub rubric instead. Every header is a bracketed uppercase rubric.
- Left-align text, paths, code, enums, and identifiers; right-align numeric and date columns; center only `[INDEX]`, compact markers, and values three characters or fewer.
- Keep tables under 15 columns and 20 rows with at most one trailing prose column that still obeys the cell budget; escape literal pipes; keep every row's cell count equal; decompose over-bound tables on the dominant axis.
- The first word after a label colon in a cell capitalizes as a sentence start; an identifier, path, or code span is verbatim.

[CONVERSION]:

| [INDEX] | [SYMPTOM]                               | [RIGHT_CONTAINER]                    |
| :-----: | :-------------------------------------- | :----------------------------------- |
|  [01]   | cell holds a sentence or internal comma | GroupedRecord card                   |
|  [02]   | cell packs values behind slashes        | one row per value                    |
|  [03]   | column restates its header              | delete column, hoist word to header  |
|  [04]   | column holds one universal value        | `[VALUE]:` card, delete column       |
|  [05]   | prose column and link column in one row | routing table or `- Key: path` line  |
|  [06]   | one row only                            | definition record                    |
|  [07]   | rows share no comparison question       | separate records                     |
|  [08]   | cell wraps to a second rendered line    | row-owned record after the table     |
|  [09]   | every cell in a column is a link        | pure routing table, no other columns |
|  [10]   | index, label, and prose are the fields  | indexed list                         |
|  [11]   | nested or multiline fact in a cell      | subsection-per-record block          |

## [03]-[RECORDS_AND_LISTS]

Records carry independently scanned items; lists carry peer facts or true sequence. A record earns a field only where an agent filters, updates, removes, confirms, or routes by that field; a field that decides nothing is deleted, not filled to a template.

[RECORD_FORMS]:
- `GroupedRecord`: a standalone `[RECORD_KEY]:` label followed by `- Field: value` bullets; the normative field carrier for same-section clusters. A record key naming a verbatim identifier keeps the identifier's exact casing in a code span; a conceptual key is an UPPER_SNAKE rubric.
- `AnchoredRecord`: an H3 record heading, used only when another artifact links to the record or a stable slug is required.
- `ContrastRecord`: `[CONTRAST_KEY]:` followed by `- Accepted:`, `- Rejected:` or `- Near miss:`, and `- Reason:` bullets.
- `OrderedStep`: a numbered task step carrying fields such as `Action`, `Command`, `Expected signal`, `Recovery`, or `Result`.
- `row-owned record`: a record after a table that carries one row's independent status, detail, omission, update, or retention.

[INDEXED_LIST] — The indexed list is the three-field alternative to a table: `- [NN]-[LABEL]: Prose.` carries an index for stable reference, a bracketed label for scanning, and one prose clause for the payload. It is not a heading tier and never joins the `#` hierarchy.
- Reach for it when the information is index, label, and prose — and the prose outgrows a cell budget; a genuine fourth field promotes the set to a table, and entries nobody references by position demote to plain bullets.
- Entries number `[01]` onward in document order; the label is a bracketed uppercase rubric; the prose obeys the register and stays one clause to one short sentence.
- Additions append or renumber consciously — an indexed list another artifact cites by index renumbers only with its citers.

[FIELD_LINES]:
- Fields use `- Field: value` bullets beneath a bracketed `[RECORD_KEY]:` label or H3 heading; keep labels in sentence case or verified field casing, one colon and one space, never bold.
- A list-valued field uses one parent bullet, then one nested bullet tier beneath it; field content is always a bullet, never a bare indented line.
- A field value identical across every sibling record hoists to one `[KEY]: value` card above the set, deleting the copies — the record form of the tautological column.
- Use backticks only for literal fields, symbols, commands, paths, flags, exact tokens, or placeholders.

[STATUS_VOCABULARY]:

| [INDEX] | [STATUS]   | [MEANING]                 |
| :-----: | :--------- | :------------------------ |
|  [01]   | `QUEUED`   | accepted for the sequence |
|  [02]   | `ACTIVE`   | executing in record scope |
|  [03]   | `BLOCKED`  | held by a dependency      |
|  [04]   | `COMPLETE` | exit condition met        |
|  [05]   | `DROPPED`  | removed or superseded     |

A type standard narrows this vocabulary only when it declares exact casing, active states, blocked states, terminal states, and removal behavior before examples.

[PACKET_PROMOTION]:
- Promote a definition block to a record only when repeated decisions, independent field updates, parser consumption, failure reading, omission behavior, or claim confidence exceeds ordinary prose.
- Collapse a record to a short field block when fewer than three fields are independently scanned, updated, closed, or omitted.

[CHECKLISTS]:
- Use `- [ ]` and `- [x]` when an item carries an actionable completion, acceptance, readiness, or status assertion; use bullets for unordered peer facts whose completion is not asserted.
- Acceptance checklists carry an `Exit` condition per item; a status item promotes to a record when it needs `Status`, `Depends`, `Update when`, `Close when`, or multiline detail.
- Fields trail item text after an em dash and stay compact; promote past three trailing fields or any field that needs its own list.

[LISTS]:
- Use `-` for bullets; never `*` or `+`. Bullets carry equivalent items; numbered lists carry true sequence; never mix ordered and unordered items in one logical block.
- A bullet is one atomic entry: one fact, one rule, one member. A bullet whose content is a run of parallel values is a mis-container — either each value takes its own bullet, or the set collapses out of list form entirely.
- An entry carries one decision in one to two sentences, three at the hard cap; past the cap the entry is hiding a card, a labeled block, or section prose. A law and its mechanism, consequences, and exceptions packed into one bullet is a compressed section wearing a hyphen.
- Closed enumerations whose payload is the member roster itself — banned-word lists, generated member sets, fault-code ledgers, package rows — are registry entries and legal at length; everything else obeys the budget.
- A closed token set that is referenced rather than defined rides inline after its group label — ``[SET_LABEL]: `TOKEN_A` `TOKEN_B` `TOKEN_C` `` — one line, no list; the list form is earned only when members carry per-member content.
- Split lists past seven items into named sets; keep nesting to two levels with four-space child indentation.
- A complete lead sentence ending in a colon introduces a list with no blank gap; a section may open directly with its primary rule list after the heading blank line.

[GROUP_LABELS]:
- A standalone bracketed set label `[X_Y_Z]:` introduces a category, set, or key list; keep one blank line before it and place its list or table on the next line with no blank gap.
- Never stack two set labels; if a second appears before the first label's list, remove the outer label or promote it to prose or a heading.
- A `[RECORD_KEY]:` or `[CONTRAST_KEY]:` label is followed by a bullet list, never bare indented `Field: value` lines.

[WHITESPACE]:
- Put one blank line after every H1, H2, and H3 heading, and one blank line on each side of a table, fenced block, or diagram; a lead sentence introduces the structure but the blank line still separates prose from the opening fence.
- Do not hard-wrap prose: write each paragraph as one logical line and let the renderer soft-wrap; insert manual breaks only for list items, table rows, record fields, and fences.

## [04]-[SECTION_SHAPES]

A section exists only where it owns a decision cluster; the section set is engineered, never accumulated, and a header that groups nothing is deleted, not filled.

- Section count follows concern count: a document with more sections than owned concerns is over-sectioned, and two sections answering one reader question merge. Splitting a section is earned by a reader who arrives needing only one half.
- A short section is one lead and one container; a medium section is a lead, one primary container, and its relief prose; a long section is a lead, a labeled block per sub-concern, and one container per block. Depth grows by labeled blocks inside the section before it grows by new sections.
- Mixed paradigms inside one section are legal when each carrier owns a distinct reader job — a lead that legislates, a table that enumerates, a record that details one row — and illegal when two carriers repeat one fact in two shapes.
- The first container after the lead carries the section's primary payload; supporting carriers follow it, never precede it.
- An intro section earns its slot by changing the reader's next action: charter and boundary consequence, nothing else. Scene-setting, tour narration, and importance claims are deleted on sight.

## [05]-[VISUAL_TOPOLOGY]

A tree, codemap, or diagram carries structure and relations; prose carries the law the structure obeys.

- A node, edge, or tree-entry label is a concept name plus at most one charter phrase, under ten words; signatures, versions, and mechanism never ride a label.
- A visual is declared regenerable, verified by tooling where a verifier exists, and never paraphrased back into prose.
- One visual owns one question; a visual needing two legends is two visuals, and a visual that repeats a table is deleted.
