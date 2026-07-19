---
name: docgen
description: >-
    Doc-gen foundation for durable agent-facing documents: the owning-voice register, altitude
    control, file-kind consistency and marker systems, the anti-anchoring law against enumerating
    or freezing facts prose cannot keep true, the named defect catalog (capability-gating,
    legacy-compat, imported upstream posture, process-ledger, deleted-form litanies, coupling),
    and a deterministic prose gate. Use when authoring, editing, reviewing, or rewriting any durable markdown — README,
    ARCHITECTURE, specs, standards, prompts, tool docs, the prose inside skill files — when
    designing a document schema or marker vocabulary, or when hunting noise, fragility,
    staleness, poison framing, or context anchoring. Skill bundle design — triggers, disclosure,
    bundled scripts, evals — belongs to the skill-writer skill; Mermaid fences to
    mermaid-diagramming; interactive HTML artifacts to html-studio. Do not trigger for transient
    chat replies, code-only edits, or research whose deliverable is not durable markdown.
---

# [DOCGEN]

Durable prose is law for an agent that loads it with no memory of why it was written, and every line either changes that agent's next action or poisons it. One register, one owner per fact, one schema per file kind, one decision per line — everything else is deleted, never softened. Skill bundle design — trigger descriptions, disclosure architecture, bundled scripts, evals — is the skill-writer skill's deliverable; this register binds the prose inside every bundle it produces.

Always use declarative, assertive language, present tense, active voice, FANBOYS, every word must be load bearing, remove otherwise; prose are a source of context poison, the less to maintain the better.

## [01]-[ROUTING]

It is MANDATORY to load all files in `references/` when creating or editing prose. Load examples when refactoring prose types that match.

[REFERENCES]:
- [01]-[STRUCTURE](references/structure.md): altitude tiers, routing law, representation choice, table design, file-kind schemas, marker systems
- [02]-[DEFECTS](references/defects.md): defect classes — definitions, detection tests, pairs, reframe rules
- [03]-[REWRITING](references/rewriting.md): rebuilding an existing document without inheriting its frame

[TEMPLATES]: authoring a new instance of a known file kind starts from its template; a finished instance carries zero residual slot tokens.
- [01]-[IDEAS](templates/ideas.template.md): copy verbatim; fill only the H1 token and lead slot
- [02]-[TASKLOG](templates/tasklog.template.md): copy verbatim; fill only the H1 token and lead slot
- [03]-[README](templates/readme.template.md): exact structure, slots only; a multi-folder unit groups cards under one `[FOLDER_TOKEN]:` per folder
- [04]-[ARCHITECTURE](templates/architecture.template.md): exact structure, replace only the slots
- [05]-[SPEC](templates/spec.template.md): exact section spine; slots carry their budgets, cluster count follows the domain
- [06]-[API_CATALOG](templates/api-catalog.template.md): exact structure, replace only the slots

[EXAMPLES]: symptom-indexed worked pairs; consult the matching set before building or repairing the container.
- [01]-[TABLES](examples/tables.md): table crimes and their structural repairs
- [02]-[LISTS](examples/lists.md): mega bullets, shredded splits, the classified repair
- [03]-[MARKERS](examples/markers.md): entry leaders, status vocabularies, glyphs
- [04]-[INTROS](examples/intros.md): leads that legislate and the rejected frames

[SCRIPTS]:
- [01]-[PROSE_GATE](scripts/prose_gate.py): deterministic gate and fixer; invocation in the gate section

## [02]-[GATE]

```bash template
uv run scripts/prose_gate.py [--json] <paths...>
```

```bash template
uv run scripts/prose_gate.py fix [--write] <paths...>
```

Run the gate on every touched durable doc before returning. `fix` applies every deterministic repair — header, index-column, numbering, list-leader, spacing, and canonical table-render fixes — printing a per-change plan as a dry run by default and mutating only under `--write`; judgment-tier repairs surface as `SKIP` rows. Gate and fixer share one table model, so a grid whose canonical render exceeds the 150-column cap fails `table-width` regardless of current padding. It is the mechanical floor over structural, link-custody, template-residue, article-opener, and banned-lexeme classes, with skill bundles additionally gating frontmatter, name and directory identity, description budgets, root line ceiling, and orphan files; the script's `Check` vocabulary owns the full census. Prose spans alone are scanned — fence bodies, code spans, link destinations, template placeholders, and example-leader rows are structural carriers, not findings — and every semantic class and altitude judgment remains review work against the catalog.

## [03]-[REGISTER]

Register laws produce the voice; every catalog defect is a way of breaking one of them.

[OWNING_SUBJECT] — Every law sentence seats the owner as its grammatical subject, and the verb is an act of ownership over the whole concern: mints, owns, folds, routes, binds, admits, rejects. A total positive claim forecloses every alternative by construction; a surface that merely `supports`, `offers`, or `provides` has not been designed yet. Durable law is the partition principle; a count is a consequence the reader derives, never a ceiling the prose enforces.

```markdown rejected
The package offers an optional graph lane and supports self-hosted deployments.
```

```markdown accepted
Only the self-hosted profile row binds the graph lane.
```

[PROHIBITION_BY_STRUCTURE] — A forbidden form appears only with its enforcing mechanism as the subject of the same clause; never as a roster of corpses, a ritual closing tail, or a naked impossibility claim. One total positive law makes the negation list redundant.

```markdown rejected
Cross-tenant batching is unspellable. A per-op check, an ambient flag, or a second meter is the deleted form.
```

```markdown accepted
Batch keys carry the tenant brand, so a batch is tenant-scoped by construction.
```

[DECISION_PER_LINE] — Each line states one resolved fact in a timeless voice with at most one load-bearing reason: no reassurance, no anticipated objection, no ship-status, no tag, no origin. A reader cannot tell which parts were written when, by whom, or in what order.

```markdown rejected
DECISION [V10]: the trust gate binds every identifier crossing into engine SQL — LANDED, verify and extend, never re-initialize (this replaces the phantom the prior draft carried).
```

```markdown accepted
Every identifier crossing into engine SQL passes the trust gate.
```

[LOAD_BEARING_WORD] — Every word earns its slot or dies, so a finished passage states identical law in a third fewer tokens. Voice is present and active: an owner acts on its concern now, never was-acting, will-act, or is-acted-upon. Deleted on sight — an intensifier grading what the fact already carries, a lead-in delaying the operative verb, a coordinator padding one clause into two, a phrase one verb states, a clause restating its neighbour. Economy is never bought with capability: every decision, condition, and code span survives the cut, and an entry holding two decisions splits into sibling entries, never a longer line.

```markdown rejected
It is important to note that the resolver is a very robust component which will be responsible for handling the seamless mapping of keys, and it also provides comprehensive support for the batch case.
```

```markdown accepted
`Resolver` maps every key, batch included.
```

[CAPABILITY] — Capability lands as present-tense owned fact with deep foresight, or the sentence does not exist. Consumer count is never a design axis: nothing is deferred until demand, defended against an imagined objection, or preserved for an old reader. A capability that cannot yet be modeled gets silence; genuinely open work is a tracked card, never a soft sentence.

```markdown rejected
Incremental rendering is planned once demand justifies it; until then full rebuilds are acceptable for current needs.
```

```markdown accepted
Rendering rebuilds only nodes whose content hash changed.
```

[NAMED_SURFACE] — A nameable surface — member, command, key, flag, token — is written as a code span in its exact verified spelling; verification precedes authoring, an unverifiable member is a tracked open item never settled prose, and a nameable surface paraphrased in prose is a defect: the code span is the instruction.

```markdown rejected
Enable the merge-edges option and the network-simplex placement strategy in the layout block.
```

```markdown accepted
Layout blocks carry `mergeEdges: true` and `nodePlacementStrategy: NETWORK_SIMPLEX`.
```

[PROSE_CODE_BOUNDARY] — Prose names owners; code carries mechanism. A prose line names at most the owning symbol as a code span and states its law; signatures, parameter lists, member chains, option rosters, and per-member behavior live in the fence, catalog, or table that tooling keeps true — carried in prose they are drift debt the next code edit falsifies. A list entry is one focused decision: one owner, one charter phrase; an enumeration tail, a second clause, or a package-mechanism aside demotes to the owning surface or splits into a sibling entry, never a longer line.

```markdown rejected
- [03]-[LENS](lens.md): `DocumentLens` recover-to inverse over PDF, raster, or workbook, plus the examination ops — glyphs, layout metrics, OCG layers, separation inks, page labels, FDF/XFDF form data.
```

```markdown accepted
- [03]-[LENS](lens.md): `DocumentLens` recover-to inverse rebuilding a node tree from an emitted container, plus the examination ops.
```

## [04]-[FACT_LAW]

[REBUILD_TEST] — One admission test rules every prose sentence: it stays true, unchanged, across any doctrine-conforming rebuild of the surfaces it accompanies. Prose couples to intent — charter, invariant, boundary, ruling, trap; the fence couples to shape. Truth depending on the current fence body drifts when the fence improves, and prose naming the current shape walls the next rebuild inside today's design — one defect, shape-coupled prose, read from two directions; both cure by stating what the rebuild must preserve and letting the fence own the shape. A page passes when a stronger fence body lands with zero prose edits.

[REGENERATION_TEST] — Probes the rebuild test's drift direction. Delete the sentence: a fresh agent that regenerates the fact from disk plus stated invariants proves it a mirror — delete, or demote to a fence when structure must show. A fact that cannot be regenerated is law kept at its owning altitude, still answerable to every defect class; regeneration rules out the mirror alone, never the freeze, hedge, or ledger the catalog deletes.

[ONE_OWNER] — A second prose copy of any fact, at any altitude, is a fork waiting to drift. A pointer names the owner and its one consumed symbol, never internals; doctrine states once at its charter and arrives settled downstream — composed as given, never recited, re-taught, renamed, or re-defined.

[ANCHOR] — Probes the rebuild test's wall direction. Loaded prose is the working model the next agent generates inside, so every shape it names becomes a wall: a member roster walls the rebuild to today's census, a forbidden-alternative litany to the anti-shape, a frozen count or seal to the ceiling. Cure is the extension rule — how one new row, case, or member lands — stated where the anchor stood, the roster living on the surface tooling keeps true.

## [05]-[COMMENTS]

Comments serve the agent editing the file in isolation, in source and transcription-complete fences alike: one in-situ constraint the code cannot show, uncoupled from paths, sessions, and siblings, never duplicating card or index content. A machine-config comment naming its owning module's path survives; a path that merely narrates is deleted. Every block holds the fewest lines that carry the constraint, each line filled toward the 150-column cap before wrapping, and a multi-line comment reduces as far as intent survives. Three gate counts bound the shape — `comment-stack` (a stack past 4), `comment-shred` (2-4 short lines that merge into one dense line), `comment-runt` (a wrapped block ending on an orphan). An orphan is any stacked line under 5-6 words: remove it and refold its content into a neighbor, or rephrase so the surviving lines carry it. Header identity rows, shebangs, doc-comment glyphs, dividers, and tool pragmas are structural and never count; the charter docstring below the divider is prose under comment discipline, exempt only from the stack cap. Every pass prunes stale or drifted comments, and never authors one where the code already carries the constraint.

Remediation runs one ladder per comment: a comment carrying no load — narration, code restatement, a human-facing tour — is deleted whole; a load-bearing comment is tightened in place, a multi-line survivor collapsing 3 lines to 2 and 2 to 1 wherever the prose fits. A one-line survivor governing exactly one line or entry inlines as that line's trailing tail — short, atomic, stated as a positive constraint; a comment governing a block or several lines stays a full-line comment above what it governs. Inlining follows tightening, never replaces it. Deletion keeps payload: a real constraint survives tightening. A merge is a rewrite, not a concatenation. Repair is read-and-rewrite judgment: the gate detects, and no `sed`/regex or scripted pass mutates comment text. Section and sub-section dividers and docstring headers are structural — corrected in style, structure, or label, never deleted; a phantom label naming a concern the block does not own is corrected only after reading the enclosing section structure.

## [06]-[GOTCHAS]

- Rigor's look-alike is the worst defect — a complete roster, an exact count, a frozen chant, a corpse litany; each reads as discipline, rots as law.
- Deleting a defective sentence never deletes capability: demote mechanism to its owner first, then collapse the copy; dropped payload is a defect.
- Future tense survives only on a card growth line and a research item, which carries the exact question plus its verification route, never citations.
- Author satisfaction is never the exit: a doc seals on a cold read that raises nothing — the producer's grade admits, the cold read decides.
