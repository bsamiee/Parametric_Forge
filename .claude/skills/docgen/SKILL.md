---
name: docgen
description: >-
    Owns all prose, markdown files and the comments inside source files and fences
    through a register law, an anti-anchoring rule against rosters, counts, and freezes,
    a named defect catalog, file-kind templates, and a deterministic gate and fixer.
    Use when authoring, editing, reviewing, or markdown files of any kind, and comments in
    source files; when designing a document schema or marker vocabulary; when pruning code
    comments; or on "clean up this doc", "tighten the prose", "this doc is stale".
---

# [DOCGEN]

Write durable prose as law for an agent that loads it cold: every line changes that agent's next action or poisons it. Give every fact one owner, every line one decision — delete everything else, never soften it — inside skill bundles exactly as on any durable surface.

Hold two registers apart: an instruction surface — skill, standard, template comment, prompt — commands the writer in imperative demands; durable content states timeless owner-voice law. Command the act or state the law; describe nothing.

## [01]-[ROUTING]

Load all files in `references/` before creating or editing prose; load the matching examples when repairing that container.

[REFERENCES]:
- [01]-[STRUCTURE](references/structure.md): altitude tiers, routing law, example craft, lead law, file-kind schemas, marker design
- [02]-[DEFECTS](references/defects.md): defect classes — definitions, detection tests, pairs, reframe rules
- [03]-[REWRITING](references/rewriting.md): rebuilding an existing document without inheriting its frame

[STANDARDS]: compose container and surface mechanics from `docs/standards/` as given, never restated — `formatting.md` owns headings, tokens, glyphs, fences, and machine surfaces; `information-structure.md` owns containers, tables, records, lists, and section shapes; `style-guide.md` owns wording, sentences, terminology, and punctuation.

[TEMPLATES]: start a new instance of a known file kind from its template; leave zero residual slot tokens.
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

Run the gate on every touched durable doc before returning; run `fix` for the deterministic repairs its `Repair` vocabulary owns — dry-run prints the plan, `--write` mutates — and resolve every judgment-tier `SKIP` row by hand. Gate and fixer share one table model, so a grid whose canonical render exceeds the width cap fails at any padding. Its `Check` vocabulary owns the mechanical census; treat every class it does not carry as review work against the catalog.

Card files and design-page `[RESEARCH]` sections census against the marker grammar their own source-only template comment declares, so an authoring agent self-checks its document class without the corpus rail.

## [03]-[REGISTER]

[OWNING_SUBJECT] — Seat the acting owner as the grammatical subject of every law sentence and give it a verb that exercises ownership: mints, owns, folds, routes, binds, admits, rejects. State the total positive claim that forecloses every alternative; a surface that merely `supports`, `offers`, or `provides` is not yet designed. State the partition principle and let the reader derive the count — never legislate one.

```markdown rejected
The package offers an optional graph lane and supports self-hosted deployments.
```

```markdown accepted
Only the self-hosted profile row binds the graph lane.
```

[PROHIBITION_BY_STRUCTURE] — Spell a forbidden form only where its enforcing mechanism is the subject of the same clause. Write no corpse rosters, ritual closing tails, or naked impossibility claims; state the one positive law that makes the negation redundant, and state a negated contrast — not X but Y — as the Y claim alone. Naming a forbidden form primes its emission.

```markdown rejected
Cross-tenant batching is unspellable. A per-op check, an ambient flag, or a second meter is the deleted form.
```

```markdown accepted
Batch keys carry the tenant brand, so a batch is tenant-scoped by construction.
```

[DECISION_PER_LINE] — State one resolved fact per line, timeless, with at most one load-bearing reason. Strip reassurance, anticipated objections, ship-status, tags, and origin; leave no trace of which parts were written when, by whom, or in what order.

```markdown rejected
DECISION [V10]: the trust gate binds every identifier crossing into engine SQL — LANDED, verify and extend, never re-initialize (this replaces the phantom the prior draft carried).
```

```markdown accepted
Every identifier crossing into engine SQL passes the trust gate.
```

[LOAD_BEARING_WORD] — Make every word earn its slot; state identical law in a third fewer tokens. Write present active — an owner acts now, never was-acting, will-act, or is-acted-upon. Delete on sight: an intensifier grading the fact, a lead-in delaying the verb, an additive coordinator padding one clause into two, a phrase one verb states, a clause restating its neighbour. Never trade capability for economy — split a two-decision entry into siblings, never write a longer line.

```markdown rejected
It is important to note that the resolver is a very robust component which will be responsible for handling the seamless mapping of keys, and it also provides comprehensive support for the batch case.
```

```markdown accepted
`Resolver` maps every key, batch included.
```

[ADDITIVE_CURE] — Cure additive filler shortest-first: delete the word with its comma and fold the tail into the clause or a serial list; then `with`, which carries accompaniment; then FANBOYS `and` where a compound subject genuinely needs the conjunction; then a precise shorter word where the coinage admits one. Never spend a longer connector than the defect it replaces. Keep emphasis casing and the sense a quantity phrase carries.

```markdown rejected
Findings return the verdict or "absent", plus the surfaces searched.
```

```markdown accepted
Findings return the verdict or "absent" with the surfaces searched.
```

[CAPABILITY] — State capability as present-tense owned fact with deep foresight, or write nothing. Never defer to demand, defend against an imagined objection, or preserve for an old reader; give an unmodelable capability silence and route genuinely open work to a tracked card.

```markdown rejected
Incremental rendering is planned once demand justifies it; until then full rebuilds are acceptable for current needs.
```

```markdown accepted
Rendering rebuilds only nodes whose content hash changed.
```

[NAMED_SURFACE] — Write every nameable surface — member, command, key, flag, token — as a code span in its exact verified spelling, and verify before authoring. Track an unverifiable member as an open item, never settle it as prose; the code span is the instruction, so never paraphrase it.

```markdown rejected
Enable the merge-edges option and the network-simplex placement strategy in the layout block.
```

```markdown accepted
Layout blocks carry `mergeEdges: true` and `nodePlacementStrategy: NETWORK_SIMPLEX`.
```

[PROSE_CODE_BOUNDARY] — Name owners in prose; carry mechanism in code. Name at most the owning symbol as a code span and state its law; leave signatures, rosters, and per-member behavior in the fence, catalog, or table tooling keeps true — in prose, drift debt. Hold the abbreviated call shape in a catalog or comparison cell (anatomy: api-catalog template) and the transcription-complete declaration only in a design-page fence; never fence what a catalog indexes. Write one decision per list entry — one owner, one charter phrase — demoting or splitting any tail, second clause, or mechanism aside.

```markdown rejected
- [03]-[LENS](lens.md): `DocumentLens` recover-to inverse over PDF, raster, or workbook, and the examination ops — glyphs, layout metrics, OCG layers, separation inks, page labels, FDF/XFDF form data.
```

```markdown accepted
- [03]-[LENS](lens.md): `DocumentLens` recover-to inverse rebuilding a node tree from an emitted container, and the examination ops.
```

## [04]-[FACT_LAW]

[REBUILD_TEST] — Admit a sentence only when it stays true, unchanged, across any doctrine-conforming rebuild of its surfaces. Couple prose to intent — charter, invariant, boundary, ruling, trap — and let the fence own shape. Cure fragile prose (truth tied to today's fence body) and walling prose (today's shape named as the contract) the same way: state what the rebuild preserves. A page passes when a stronger fence body lands with zero prose edits.

[REGENERATION_TEST] — Delete the sentence; when a fresh agent regenerates the fact from disk and stated invariants, keep it deleted or demote it to a fence where structure must show. Keep a fact that cannot regenerate at its owning altitude — still answerable to every defect class, because regeneration rules out the mirror alone, never the freeze, hedge, or ledger.

[ADHERENCE_TEST] — On an always-loaded instruction surface, delete every line the agent already obeys regardless of its truth; retained rules dilute one another's pull. Keep only the line whose removal causes a mistake the agent otherwise avoids.

[ONE_OWNER] — Give every fact exactly one prose owner; a second copy at any altitude is a fork waiting to drift. Interrogate every law sentence — who else binds this fact: the always-loaded chain, a sibling doc or registry, a deterministic tool? — holding the page against the other loaded surfaces, because a sentence load-bearing in isolation is the prime suspect. Point with the owner and its one consumed symbol, never internals; compose doctrine silently downstream — never recite, re-teach, rename, or re-define it.

[ANCHOR] — Never name a shape prose walls a rebuild inside: a member roster walls it to today's census, a forbidden-alternative litany to the anti-shape, a frozen count or seal to the ceiling. State the extension rule — how one new row, case, or member lands — where the anchor stood, and leave the roster on the surface tooling keeps true.

## [05]-[COMMENTS]

Write a comment only for the agent editing the file in isolation, in source and transcription-complete fences alike: one in-situ constraint the code cannot show, uncoupled from paths, sessions, and siblings, never duplicating card or index content. Delete a comment whose constraint the code carries, and prune stale comments every pass. Keep a machine-config comment naming its owning module's path; delete a narrating path.

Hold a block to the fewest lines that carry the constraint, each filled toward the 150-column cap; split a re-wrap asymmetrically — lead packed, tail carrying real width, never an even split. Refold an orphan line into a neighbor or rephrase it away. Gate counts bound the shape; header identity rows, shebangs, doc-comment glyphs, dividers, and tool pragmas never count, and the charter docstring is exempt only from the stack cap.

Run one ladder per comment: delete a no-load comment whole — narration, code restatement, a human-facing tour — keeping any real constraint it carried; tighten a load-bearing survivor in place, 3 lines to 2 and 2 to 1; then inline a one-line survivor governing one line as its trailing tail — short, atomic, positive, outside every count and width budget — while a block-governing comment stays above its block.

Rewrite on merge, never concatenate, and repair by read-and-rewrite judgment — the gate detects, no `sed`/regex mutates comment text. Correct dividers and docstring headers in style, structure, or label, never delete them; correct a phantom label only after reading the enclosing section.

## [06]-[GOTCHAS]

- Distrust rigor's look-alike — a complete roster, an exact count, a frozen chant, a corpse litany each reads as discipline and rots as law.
- Demote mechanism to its owner before collapsing the copy; dropped payload is a defect. Delete a fork or restatement outright — never mint a `never X` to stand in for the cut.
- Reserve future tense for a card growth line and a research item carrying the exact question and its verification route, never citations.
- Exit on a cold read that raises nothing, never on author satisfaction — the producer's grade admits, the cold read decides.
