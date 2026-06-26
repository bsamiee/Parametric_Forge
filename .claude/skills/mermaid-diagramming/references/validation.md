# [H1][VALIDATION]

Consolidated validation for all Mermaid diagram types. Anti-patterns, escaping rules, verification checklists.

## [01]-[CONFIGURATION]

[REFERENCE] Configuration details: [->global-config.md](./global-config.md)

**Anti-patterns:** `%%{init:...}%%` (use YAML frontmatter), `init:` key (use `config:`), missing `---` fences, security override in config (use `initialize()`).

[VERIFY] Config:
- [ ] Valid YAML with `config:` key and `---` fences.
- [ ] ELK layout installed if using `layout: elk`.
- [ ] Look set to `neo` or `classic`.
- [ ] Theme uses `base` for `themeVariables`.
- [ ] Security level via `initialize()` only.

## [02]-[SECURITY]

**Anti-patterns:** `securityLevel` in frontmatter (silently ignored), `javascript:` URLs, `data:` URLs, missing `dompurifyConfig`, `secure` override in config.

[VERIFY] Security:
- [ ] Security level via `initialize()` only, not frontmatter.
- [ ] URLs use `https://` protocol only.
- [ ] Sanitize callbacks for nodeId and user input.
- [ ] Never use secure keys in frontmatter.

## [03]-[ACCESSIBILITY]

**Anti-patterns:** `accTitle`/`accDescr` before diagram type (place after), accessibility in `block-beta` (#6524) and `mindmap` (#4167).

[VERIFY] Accessibility:
- [ ] Place `accTitle` after diagram type declaration.
- [ ] Provide `accDescr` for WCAG 2.1 compliance.
- [ ] Avoid accessibility in `block-beta` and `mindmap` (known bugs).

## [04]-[GRAPH_DIAGRAMS]

**Reserved words:** `end`, `default`, `subgraph`, `direction`, `style`, `linkStyle`, `classDef`, `class`, `click`, `flowchart`, `graph`. Escape: `id["end"]` or capitalize.
**Node IDs:** Alphanumeric + underscore. Invalid first char: `o`, `x` (edge conflict).
**Version gates:** Named shapes v11.3.0+, Edge IDs v11.6.0+, Markdown strings v10.1.0+.

**Anti-patterns:** `->` instead of `-->`, space before text `A [txt]`, 50+ nodes without ELK, mixed indent in mindmap, missing `columns N` in block, omitted span `:N`.

[VERIFY] Flowchart:
- [ ] Node IDs alphanumeric + underscore; avoid reserved words.
- [ ] Subgraph nesting max 3 levels.
- [ ] Named shapes use `@{ }` syntax (v11.3.0+ only).

[VERIFY] Mindmap:
- [ ] Consistent indentation; root node first; no explicit edges.

[VERIFY] Block:
- [ ] `columns N` first; all blocks have explicit span `:N`.

## [05]-[INTERACTION_DIAGRAMS]

**Anti-patterns:** JSON without quotes, JSON + `as Alias` mixed, unbalanced `+`/`-` activation, missing `end`, `end` in message text (wrap in brackets), journey score outside 1-5.

[VERIFY] Sequence:
- [ ] JSON types use double quotes; never mix JSON and `as Alias`.
- [ ] Balance activation `+`/`-` pairs; end all control blocks.

[VERIFY] Journey:
- [ ] Scores integer 1-5 only; group tasks in `section` blocks.

## [06]-[MODELING_DIAGRAMS]

**Reserved words:** State: `end`, `state`. ER: `ONE`, `MANY`, `TO`, `U`, `1` (bug #7093).
**Anti-patterns:** `<T>` generics (use `~T~`), missing visibility prefix, ER empty `{ }`, `classDef` inside composite, state styling on start/end.

[VERIFY] Class:
- [ ] Generics `~T~` syntax; visibility prefix on all members.
- [ ] Lollipop interface: `()--` or `--()`.

[VERIFY] ER:
- [ ] Crow's foot symbols; UPPERCASE entity names; `direction` at start.

[VERIFY] State:
- [ ] `stateDiagram-v2`; stereotypes `<<fork>>`, `<<join>>`, `<<choice>>`.
- [ ] `classDef` at diagram root only.

[VERIFY] Requirement:
- [ ] `id:` field present; valid relation type.

## [07]-[CHART_DIAGRAMS]

**Anti-patterns:** Pie values sum to 0, sankey circular flow, XY mismatched arrays, gantt invalid dates, radar axis/value mismatch, quadrant coords outside 0-1, treemap mixed indent or non-numeric leaf.

[VERIFY] Charts:
- [ ] Pie: positive value sum.
- [ ] Sankey: DAG only, no cycles.
- [ ] XYChart: match X-axis labels to data length.
- [ ] Radar: match axis count to values.
- [ ] Gantt: match `dateFormat` to dates; reference existing IDs.
- [ ] Quadrant: coordinates 0.0-1.0.
- [ ] Treemap: consistent indentation, numeric leaves.

## [08]-[ARCHITECTURE_DIAGRAMS]

**Anti-patterns:** C4 missing `Rel()`, undefined alias, wrong `$` prefix; architecture missing `in` clause; overlapping/incomplete bits in packet; gitgraph merge before branch, checkout before branch, cherry-pick same branch; kanban wrong indentation, wrong priority strings.

[VERIFY] C4:
- [ ] Declare aliases before `Rel()`; named params use `$` prefix.

[VERIFY] Architecture:
- [ ] All services/junctions specify `in group`; valid edge directions (T/B/L/R).

[VERIFY] Packet:
- [ ] Sequential non-overlapping bit ranges; no gaps.

[VERIFY] GitGraph:
- [ ] Branch exists before merge/checkout; unique commit IDs; cherry-pick merge includes `parent:`.

[VERIFY] Kanban:
- [ ] Tasks indented under columns; priority exact match with single quotes.

## [09]-[ERROR_SYMPTOMS]

| [INDEX] | [SYMPTOM]           | [FIX]                              |
| :-----: | ------------------- | ---------------------------------- |
|  [01]   | Not rendering       | Check `---` fences, `config:` key  |
|  [02]   | Parse error line 1  | Escape reserved word or capitalize |
|  [03]   | Nodes overlapping   | Use `layout: elk`                  |
|  [04]   | Styles not applying | Move `classDef` to diagram root    |
|  [05]   | Config ignored      | Verify key spelling                |
|  [06]   | Security ignored    | Use `initialize()` instead         |
|  [07]   | Activation dangling | Match +/- pairs                    |
|  [08]   | Data misaligned     | Ensure equal array lengths         |
