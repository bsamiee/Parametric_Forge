# [FORMATTING]

Surface mechanics for durable Markdown: headings and marker families, capitalization, page shape, and machine-consumed surfaces.

## [01]-[HEADINGS_TOKENS_GLYPHS]

Surface markers come from one closed family set; each family owns a distinct job and never substitutes for another. Every surface label is a bracketed uppercase rubric: underscores for compounds, one or two semantic words by default and three only when a verified name loses meaning if shortened, no surrounding bold or code span. This rubric binds H1/H2/H3 labels, standalone group labels, and table column rubrics.

[HEADING_IDIOM]:
- H1 `# [DOCUMENT_TITLE]` carries only the semantic title, never a tier prefix.
- H2 `## [NN]-[SECTION_LABEL]`, `NN` zero-padded in document order (`[01]` through `[09]`, the rare `[00]`).
- H3 `### [NN.M]-[SUBSECTION_LABEL]`, the parent number plus the subsection number.
- Same-line qualifiers keep bracket discipline: `## [NN]-[PRIMARY]-[EXTRA]`; never trailing prose after the brackets.
- Reject heading theater such as `# [H1][NAME]`, bracket tokens outside the allowed families, and decorative `<br>` layout. Allowed families: headings, standalone group labels, table rubrics, inline status/result/change/state/lifecycle tokens, compact glyphs, invocation markers, and GitHub alerts.
- Public or registry README files use plain reader-facing headings only when their type standard declares that exception.

[ANCHORS]:
- A bracketed heading slug is the lowercased heading text with brackets, punctuation, dots, and underscores removed: `## [10]-[FOLDER_LAYOUT]` becomes `#10folderlayout`; update every in-repo link on any number or label change.
- Never create duplicate bracket-heading anchors in one file; rename the semantic label instead of relying on renderer duplicate suffixes.
- Renumber headings only on structural change; a cosmetic rewrite preserves numbers so links stay stable.

Render an inline status, result, change, or state as a bracketed token so an agent filters on an exact string. Use the closed set; never invent tokens, emojis, checkmarks, crossmarks, or decorative alternates.

[TOKEN_FAMILIES]:
- Result: `[PASS]` `[FAIL]` `[SKIP]` `[PARTIAL]` `[N/A]` — gate or check outcome.
- Change: `[ADDED]` `[REMOVED]` `[CHANGED]` `[UNCHANGED]` — delta reporting.
- Lifecycle: `[QUEUED]` `[ACTIVE]` `[BLOCKED]` `[COMPLETE]` `[DROPPED]` — inline Status mirror.
- State: `[OK]` `[ERROR]` `[WARNING]` `[CAUTION]` `[PENDING]` `[UNKNOWN]` `[NEW]` `[DELETED]` `[SAME]` `[NULL]` `[APPROX]` `[CACHED]` `[SAVED]` — runtime or operation state.

[COMPACT_GLYPHS]:

| [INDEX] | [GLYPH] | [MEANING]                | [TEXT]      | [REJECT]               |
| :-----: | :-----: | :----------------------- | :---------- | :--------------------- |
|  [01]   |  `[O]`  | affirmative or available | `pass`      | lifecycle `COMPLETE`   |
|  [02]   |  `[X]`  | negative or unavailable  | `fail`      | checkbox completion    |
|  [03]   |  `[!]`  | attention or risk marker | `attention` | confidence gap         |
|  [04]   |  `[?]`  | input value unknown      | `unknown`   | missing detail         |
|  [05]   |  `[+]`  | added or enabled         | `added`     | positive sentiment     |
|  [06]   |  `[-]`  | removed or disabled      | `removed`   | subtraction            |
|  [07]   |  `[=]`  | unchanged or matched     | `unchanged` | equality without basis |
|  [08]   |  `[/]`  | skipped or bypassed      | `skipped`   | partial completion     |
|  [09]   |  `[~]`  | partial or approximate   | `partial`   | unsupported guess      |
|  [10]   |  `[$]`  | cached or stored         | `cached`    | cost or price          |

[ABSENCE_VALUES]:

| [INDEX] | [VALUE]     | [USE]                      | [REJECT]             |
| :-----: | :---------- | :------------------------- | :------------------- |
|  [01]   | `—`         | empty table value          | skipped gate result  |
|  [02]   | `n/a`       | domain not-applicable term | generic missing data |
|  [03]   | `[N/A]`     | result is not applicable   | missing source value |
|  [04]   | `[SKIP]`    | gate did not run           | unknown gate result  |
|  [05]   | `[UNKNOWN]` | value exists but unknown   | literal null         |
|  [06]   | `[NULL]`    | literal null fact          | absent value         |

[TOKEN_RULES]:
- Prefer the most specific family; never use two tokens meaning the same thing in one column.
- Compact glyphs render only where density matters — checked lists, delta summaries, table cells — with the global meanings above.
- Reserve these tokens for status, result, change, and state; never scatter them through prose or duplicate a record field or checkbox state.
- A checkbox asserts completion; `[X]` is a compact fail marker, never a replacement for `- [x]`.
- A type-local marker such as `[PROVISIONAL]` or `[DEPRECATED]` is valid only when a type standard declares its closed vocabulary, meaning, and removal behavior before first use.
- Suffix forms such as `[ACTIVE <ID>]` are valid only as codemap or source-key projections; the base token comes from a declared vocabulary and the suffix adds no lifecycle meaning.
- Invocation markers weight instruction-file constraints; group labels introduce a list or table; GitHub alerts interrupt the reading path; compact glyphs fill dense cells; lifecycle tokens mirror a record `Status` inline. One family never substitutes for another.

[PROGRESS_BASIS] — render a bar only after a record defines the maintained actor, numerator, denominator, closure rule, and basis surface; the line carries only the label, bracketed bar, and percentage:
- 20 cells inside `[...]`: `█` marks completed and `░` remaining, or ASCII `#` and `-`.
- Percentage `floor(100 * numerator / denominator)` as an integer plus `%`, immediately right of the bar; fill `floor(20 * numerator / denominator)`.
- Closure shows `100%` and all 20 cells full only when numerator equals denominator.
- Roadmap milestone and phase bars use the same rule; progress derives from child task completion, so milestone and phase status fields are rejected.

[PROGRESS_EDGE_CASES]:

| [INDEX] | [CASE]                       | [PERCENT]       |     [FILLED_CELLS] |
| :-----: | :--------------------------- | :-------------- | -----------------: |
|  [01]   | numerator is `0`             | `0%`            |                `0` |
|  [02]   | nonzero value floors to `0`  | `<1%`           |                `0` |
|  [03]   | numerator equals denominator | `100%`          |               `20` |
|  [04]   | ordinary incomplete value    | floored integer | floored cell count |

```text conceptual
Progress: [██████░░░░░░░░░░░░░░] 33%
Progress: [############--------] 60%
```

The bar carries no appended count, unit, phase name, date, ETA, or basis text; those fields sit in the adjacent record. Omit the bar when the document cannot define the numerator, denominator, closure rule, and basis surface, or when a checklist already carries the same completion state.

[GLYPH_RULES]:
- Allowed jobs: state, progress, hierarchy, alignment, or comparison the surrounding container needs.
- Declare the glyph alphabet before first use and keep it closed for the local surface.
- Provide a text equivalent when meaning is not recoverable from adjacent text, and a basis when a glyph claims a completed state or progress.
- Rejected: decorative glyphs, emojis, checkmark or crossmark substitution, FIGlet banners, ornamental frames, separator carpets, ANSI color output, ASCII art, and standalone legends that change no reader action.

[INVOCATION_MARKERS]:
- Reserve invocation markers (`[IMPORTANT]`, `[CRITICAL]`, `[ALWAYS]`, `[NEVER]`) for instruction and prompt files where an agent weights a constraint above surrounding text; use them only for invariants that change behavior.
- `CRITICAL` and `NEVER` mark hard boundaries; `IMPORTANT` and `ALWAYS` mark load-bearing defaults.
- Ordinary documentation carries requirement strength through the prose modals `must`, `should`, and `may`; one concept never carries both an invocation marker and a prose modal.

[GITHUB_ALERTS] — ordinary rendered documentation uses this grammar; the container chooser owns when an alert is the right carrier:
- `> [!NOTE]`: neutral context.
- `> [!TIP]`: efficiency payoff.
- `> [!IMPORTANT]`: load-bearing invariant.
- `> [!WARNING]`: risk of incorrect action or failed work.
- `> [!CAUTION]`: safety, loss, or irreversible-risk boundary.
- An alert is not an invocation marker: never `[IMPORTANT]:` in ordinary documentation, never `> [!IMPORTANT]` in an instruction file where an invocation marker is the intended weighting.

## [02]-[CAPITALIZATION]

Capitalization follows the surface, not the position. The first word after a `[LABEL] —` lead or a label colon capitalizes as a sentence start; a code-span lead keeps its literal casing (`` `keyof typeof` selects the member `` stays lowercase). A bracketed rubric is uppercase with underscores. A named surface — identifier, path, command, code span — is verbatim, and a prose fragment capitalizes only its first word. Domain status vocabularies keep their declared casing as field values, while a bracketed inline lifecycle marker uppercases the canonical token and hyphenates spaces.

## [03]-[PAGE_SHAPE]

A standard file carries one H1, a dense law lead, a container chooser or use-when, and rule sections named by the concern they own, with examples only where a common mistake needs a guard; it opens on its operating law rather than self-description and ends at the last load-bearing section with no closing checklist. Cross-reference and boundaries sections are banned: each standard owns its domain, and the instruction chain routes readers.

```markdown template
# [TITLE]

<Lead: the operating law in one short paragraph.>

## [01]-[USE_WHEN]

## [02]-[<RULE_OWNER>]
```

[SECTION_CARDINALITY]:
- The lead and the first rule section are required.
- Rule sections are required and named by the concern they own.
- Examples appear only where a common mistake needs a guard; conditional sections appear only when their condition holds.

[HEADINGS]:
- H2 headings form standalone retrievable units; H3 refines one H2 concern; avoid H4 unless a generated format requires it.
- An oversized carrier decomposes by its dominant axis into a lead plus record sections; extract text to preserve value, never only to reduce width.

## [04]-[MACHINE_SURFACES]

A surface a parser, generator, gate, or ledger reads keeps its exact shape. Every load-bearing form names its enforcing gate or the reason none exists yet, and a gate compiles established law into build or review pressure without inventing law of its own.

[FENCE_RULES]:
- A code fence carries a language tag plus one intent label; renderer-local fences use the exact renderer tag, and Mermaid fences are `mermaid`.
- Intent labels: `copy-safe` runs as written, `template` for neutral placeholders, `conceptual` for illustration, `generated` for generated output, `test-only` for test source, `output-only` for observed output, `signature` for a transcription-complete owner declaration an implementer copies verbatim, `accepted` and `rejected` for a worked contrast pair, and `codemap`/`seams` for width-capped topology fences.
- The body honors its label: a `copy-safe` body carries no placeholder slots or shell prompts, and an `output-only` body carries no prompt-led run command — either mismatch retags the fence.

[COMMAND_OUTPUT]:
- A copy-safe command is an instruction to run; an expected signal is the short output or state change to compare.
- Observed output sits only beside the completed result it confirms; never paste a terminal transcript where a short result statement carries the fact.
- A command card carries command, purpose, precondition, effect, output, and refresh trigger only where each field changes the reader action.

[MACHINE_RECORD]:
- Declare the consumer (parser, analyzer, generator, ledger), the required shape, the checked fields, the unchecked convention, the owner, and the refresh trigger.
- Machine-consumed Markdown keeps a narrower shape only where a named consumer reads exact headings, fields, rows, or fence grammar; declare the exception before ordinary normalization.

[MONOSPACE_TOPOLOGY]:
- Use monospace text where raw Markdown inspection matters more than a render: file trees, repository layout, tiny matrices, and small stacks. Alignment is the meaning; misaligned topology is worse than prose.

```text conceptual
project/
├── README.md
└── reference/
    └── api.md
```

[DECISION_HIT_POLICY]:
- Declare the hit policy before a decision table when rows overlap: `first match wins` only when row order is semantic, `most specific wins` only when wildcard count decides, `all matching actions apply` only when actions compose without conflict.
- Convert the rule to prose plus cases when no deterministic hit policy exists.

[GFM_INTEGRITY]:
- GFM tables are flat: no row spans, column spans, nested lists, or reliable multiline cells. A row needing nested facts becomes records.
- Before publication every row has an equal cell count after escaped pipes, literal pipes inside cells are escaped, and a table over the row or column ceiling decomposes by the dominant violation.

[ENFORCEMENT]:
- `prose_gate.py` compiles the hedge ban, the meta-frame ban, the self-count and list-entry budgets, and the fence-geometry cap into a fail-on-hit gate.
- `prose_gate.py fix` mechanically repairs header rubrics, `[INDEX]` columns and `[NN]` entries, alignment colons, heading numbering, loose list leaders, and padding — dry-run by default, `--write` applies; padding and marker mechanics are never review-tier.
- Table cell-count equality, pipe escaping, and the 150-column rendered width cap are mechanically checked; header compression and carrier choice stay review-tier until a checker owns them.

[COMMAND_ROUTING]:
- A tool document states its contract and routes verbs and flags to live `--help`; it never mirrors help output, which stales on the next release.
- A flag or option table is legal only where the document is the system of record — the surface ships no live `--help` or equivalent introspection. Where live help exists, the table is a stale mirror however atomic its cells; the doc routes.

[ANCHOR_COMMENTS]:
- Use HTML comments only for source-view authoring or maintenance notes that must not render: `<!-- source-only: <short reason> -->`, placed immediately before the block they annotate.
- Never carry safety, claim confidence, intent, or a required constraint in a hidden comment alone, and never place a comment inside a table row or cell.
