---
name: docgen
description: >-
    Owns all prose, markdown files and the comments inside source files and fences
    through one register, an anti-anchoring rule against rosters, counts, and freezes,
    a named defect catalog, file-kind templates, and a deterministic gate and fixer.
    Use when authoring, editing, reviewing, or markdown files of any kind, and comments in
    source files; when designing a document schema or marker vocabulary; when pruning code
    comments; or on "clean up this doc", "tighten the prose", "this doc is stale".
---

# [DOCGEN]

Durable prose is law for an agent that loads it with no memory of why it was written, and every line either changes that agent's next action or poisons it. One register, one owner per fact, one schema per file kind, one decision per line — everything else is deleted, never softened. This register binds the prose inside every skill bundle exactly as it binds any other durable surface.

## [01]-[ROUTING]

It is MANDATORY to load all files in `references/` when creating or editing prose. Load examples when refactoring prose types that match.

[REFERENCES]:
- [01]-[STRUCTURE](references/structure.md): altitude tiers, routing law, example craft, lead law, file-kind schemas, marker design
- [02]-[DEFECTS](references/defects.md): defect classes — definitions, detection tests, pairs, reframe rules
- [03]-[REWRITING](references/rewriting.md): rebuilding an existing document without inheriting its frame

[STANDARDS]: container and surface mechanics compose from `docs/standards/` as given, never restated — `formatting.md` owns headings, tokens, glyphs, fences, and machine surfaces; `information-structure.md` owns containers, tables, records, lists, and section shapes; `style-guide.md` owns wording, sentences, terminology, and punctuation.

[TEMPLATES]: authoring a new instance of a known file kind starts from its template; a finished instance carries zero residual slot tokens.
- [01]-[IDEAS](templates/ideas.template.md): copy verbatim; fill only the H1 token and lead slot
- [02]-[TASKLOG](templates/tasklog.template.md): copy verbatim; fill only the H1 token and lead slot
- [03]-[README](templates/readme.template.md): exact structure, slots only; a multi-folder unit groups cards under one `[FOLDER_TOKEN]:` per folder
- [04]-[ARCHITECTURE](templates/architecture.template.md): exact structure, replace only the slots
- [05]-[SPEC](templates/spec.template.md): exact section spine; slots carry their budgets, cluster count follows the domain
- [06]-[API_CATALOG](templates/api-catalog.template.md): exact structure, replace only the slots
- [07]-[RULINGS](templates/rulings.template.md): copy the section spine; a row guards a re-litigation no other surface already homes

[EXAMPLES]: symptom-indexed worked pairs; consult the matching set before building or repairing the container.
- [01]-[TABLES](examples/tables.md): table crimes and their structural repairs
- [02]-[LISTS](examples/lists.md): mega bullets, shredded splits, same-decision siblings, the classified repair
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

Run the gate on every touched durable doc before returning. `fix` applies the deterministic repairs its `Repair` vocabulary owns — dry-run printing a per-change plan, mutating only under `--write` — and surfaces judgment-tier repairs as `SKIP` rows. Gate and fixer share one table model, so a grid whose canonical render exceeds the width cap fails at any current padding. Its `Check` vocabulary owns the mechanical census — prose spans feed the register checks, structural carriers only their own — and every class it does not carry is review work against the catalog.

Card files and design-page `[RESEARCH]` sections census against the marker grammar — leader identity-and-state, closed statuses, the field roster the file's own source-only template comment declares, terminal-marker integrity — so an authoring agent self-checks its document class without the corpus rail.

## [03]-[REGISTER]

[OWNING_SUBJECT] — Every law sentence seats the owner as its grammatical subject, and the verb is an act of ownership over the whole concern: mints, owns, folds, routes, binds, admits, rejects. A total positive claim forecloses every alternative by construction; a surface that merely `supports`, `offers`, or `provides` has not been designed yet. Durable law is the partition principle; a count is a consequence the reader derives, never a ceiling the prose enforces.

```markdown rejected
The package offers an optional graph lane and supports self-hosted deployments.
```

```markdown accepted
Only the self-hosted profile row binds the graph lane.
```

[PROHIBITION_BY_STRUCTURE] — A forbidden form appears only with its enforcing mechanism as the subject of the same clause; never as a roster of corpses, a ritual closing tail, or a naked impossibility claim. One total positive law makes the negation list redundant, and a negated contrast — not X but Y — states the Y claim alone: naming a forbidden form primes its emission, so a banned token is spelled only where its enforcing mechanism is the clause subject.

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

[LOAD_BEARING_WORD] — Every word earns its slot or dies, so a finished passage states identical law in a third fewer tokens. Voice is present and active: an owner acts now, never was-acting, will-act, or is-acted-upon. Deleted on sight: an intensifier grading the fact, a lead-in delaying the verb, an additive coordinator padding one clause into two, a phrase one verb states, a clause restating its neighbour. Economy never costs capability — every decision, condition, and code span survives the cut, and an entry holding two decisions splits into sibling entries, never a longer line.

```markdown rejected
It is important to note that the resolver is a very robust component which will be responsible for handling the seamless mapping of keys, and it also provides comprehensive support for the batch case.
```

```markdown accepted
`Resolver` maps every key, batch included.
```

[ADDITIVE_CURE] — Additive filler joins nothing, and its cure runs shortest-first: delete the word with its comma, folding the tail into the clause or a serial list; then `with`, which carries accompaniment; then FANBOYS `and` where a compound subject genuinely needs the conjunction; then a precise shorter word where the coinage admits one. Every longer connector costs more characters than the defect it replaces. Emphasis casing survives the swap, and a quantity phrase keeps the sense the word carries.

```markdown rejected
Findings return the verdict or "absent", plus the surfaces searched.
```

```markdown accepted
Findings return the verdict or "absent" with the surfaces searched.
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

[PROSE_CODE_BOUNDARY] — Prose names owners; code carries mechanism. A prose line names at most the owning symbol as a code span and states its law; signatures, parameter lists, member chains, option rosters, and per-member behavior live in the fence, catalog, or table that tooling keeps true — carried in prose they are drift debt the next code edit falsifies. Two carriers split the signature by job: a capability catalog or comparison table holds the ABBREVIATED call shape — member name, argument types (or the keyword names where the name is the call contract), and a load-bearing return — a legal code-span cell at any length; the transcription-complete declaration an implementer copies verbatim lives only in a design-page fence, and a catalog that indexes a surface never fences it. A list entry is one focused decision: one owner, one charter phrase; an enumeration tail, a second clause, or a package-mechanism aside demotes to the owning surface or splits into a sibling entry, never a longer line.

```markdown rejected
- [03]-[LENS](lens.md): `DocumentLens` recover-to inverse over PDF, raster, or workbook, and the examination ops — glyphs, layout metrics, OCG layers, separation inks, page labels, FDF/XFDF form data.
```

```markdown accepted
- [03]-[LENS](lens.md): `DocumentLens` recover-to inverse rebuilding a node tree from an emitted container, and the examination ops.
```

## [04]-[FACT_LAW]

[REBUILD_TEST] — One admission test rules every prose sentence: it stays true, unchanged, across any doctrine-conforming rebuild of its surfaces. Prose couples to intent — charter, invariant, boundary, ruling, trap; the fence couples to shape. Shape-coupled prose is one defect read two ways — truth tied to the fence body drifts when the fence improves, and prose naming the shape walls the next rebuild inside today's design; both cure by stating what the rebuild preserves and letting the fence own the shape. A page passes when a stronger fence body lands with zero prose edits.

[REGENERATION_TEST] — Probes the rebuild test's drift direction. Delete the sentence: a fresh agent that regenerates the fact from disk and stated invariants proves it a mirror — delete, or demote to a fence when structure must show. A fact that cannot be regenerated is law kept at its owning altitude, still answerable to every defect class; regeneration rules out the mirror alone, never the freeze, hedge, or ledger the catalog deletes.

[ADHERENCE_TEST] — Binds always-loaded instruction surfaces. Delete the line: an agent that already behaves as the line commands proves it dead weight, deletion-eligible regardless of truth. Retained rules dilute one another's pull on the same surface, so the line that survives is the one whose removal causes a mistake the agent otherwise avoids.

[ONE_OWNER] — A second prose copy of any fact, at any altitude, is a fork waiting to drift. One interrogation finds it: who else already binds this fact — the always-loaded chain, a sibling doc or registry, or a deterministic tool? A sentence load-bearing in isolation is the prime suspect, invisible until the page is held against the other loaded surfaces. A pointer names the owner and its one consumed symbol, never internals; doctrine states once at its charter and arrives settled downstream — composed as given, never recited, re-taught, renamed, or re-defined.

[ANCHOR] — Probes the rebuild test's wall direction. Loaded prose is the working model the next agent generates inside, so every shape it names becomes a wall: a member roster walls the rebuild to today's census, a forbidden-alternative litany to the anti-shape, a frozen count or seal to the ceiling. Cure is the extension rule — how one new row, case, or member lands — stated where the anchor stood, the roster living on the surface tooling keeps true.

## [05]-[COMMENTS]

Comments serve the agent editing the file in isolation, in source and transcription-complete fences alike: one in-situ constraint the code cannot show, uncoupled from paths, sessions, and siblings, never duplicating card or index content. A machine-config comment naming its owning module's path survives; a narrating path is deleted. Every pass prunes stale comments and never authors one whose constraint the code already carries.

A block holds the fewest lines that carry the constraint, each filled toward the 150-column cap before wrapping. Gate counts `comment-stack`, `comment-shred`, and `comment-runt` bound the shape at gate-owned thresholds. An orphan — a trailing line too short to stand — refolds into a neighbor or rephrases away; a re-wrap splits asymmetrically, lead packed, tail carrying real width, never an even split. Header identity rows, shebangs, doc-comment glyphs, dividers, and tool pragmas never count; the charter docstring below the divider is comment-discipline prose exempt only from the stack cap.

Remediation runs one ladder per comment: a comment carrying no load — narration, code restatement, a human-facing tour — is deleted whole; a load-bearing comment tightens in place, a multi-line survivor collapsing 3 lines to 2 and 2 to 1 wherever the prose fits. A one-line survivor governing one line or entry inlines as its trailing tail — short, atomic, positively stated, riding outside every count and width budget, long only where the file kind carries columnar tails; a comment governing a block stays a full-line comment above it. Inlining follows tightening, never replaces it.

Deletion keeps payload — a real constraint survives tightening. A merge is a rewrite, never a concatenation, and repair is read-and-rewrite judgment: the gate detects, and no `sed`/regex or scripted pass mutates comment text. Section and sub-section dividers and docstring headers are structural — corrected in style, structure, or label, never deleted; a phantom label naming a concern the block does not own is corrected only after reading the enclosing section structure.

## [06]-[GOTCHAS]

- Rigor's look-alike is the worst defect — a complete roster, an exact count, a frozen chant, a corpse litany; each reads as discipline, rots as law.
- Deleting a defective sentence never deletes capability: demote mechanism to its owner first, then collapse the copy; dropped payload is a defect. Removal is the fix for a fork or restatement, never a substitute — a `never X` clause minted to stand in for the cut is fresh sediment.
- Future tense survives only on a card growth line and a research item, which carries the exact question and its verification route, never citations.
- Author satisfaction is never the exit: a doc seals on a cold read that raises nothing — the producer's grade admits, the cold read decides.
