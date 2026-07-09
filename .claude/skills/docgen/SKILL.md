---
name: docgen
description: >-
  Doc-gen foundation for durable agent-facing documents: the owning-voice register, altitude
  control, file-kind consistency and marker systems, the anti-anchoring law against enumerating
  or freezing facts prose cannot keep true, the named defect catalog (capability-gating,
  legacy-compat, imported upstream posture, process-ledger, deleted-form litanies, coupling),
  and a deterministic prose gate. Use when authoring, editing, reviewing, or rewriting any durable markdown — README,
  ARCHITECTURE, specs, standards, skills, prompts, tool docs — when designing a document schema
  or marker vocabulary, when authoring or repairing a skill bundle (trigger description, root
  routing, references, bundled scripts), or when hunting noise, fragility, staleness, poison
  framing, or context anchoring. Do not trigger for transient chat replies, code-only edits,
  Mermaid fence construction, interactive HTML artifacts, or research whose deliverable is not
  durable markdown.
---

# [DOCGEN]

Durable prose is law for an agent that loads it with no memory of why it was written, and every line either changes that agent's next action or poisons it. One register, one owner per fact, one schema per file kind, one decision per line — everything else is deleted, never softened. Structure, tables, markers, and schemas are [references/structure.md](references/structure.md); the defect catalog is [references/defects.md](references/defects.md); rebuilding existing documents is [references/rewriting.md](references/rewriting.md); skill bundles — trigger descriptions, root routing, progressive disclosure, bundled scripts — are [references/skills.md](references/skills.md).

## [01]-[GATE]

```bash
uv run scripts/prose_gate.py [--json] <paths...>
```

Run the gate on every touched durable doc before returning. It is the mechanical floor — fence, heading, table, link, and list structure; template residue, bold emphasis, and trailing whitespace; the banned-lexeme roster of hedges, meta-phrases, self-counts, and version anchors — and a `SKILL.md` file additionally gates frontmatter shape, description voice and budget, and the root line ceiling; the full check census is the script's `Check` vocabulary. The gate scans prose spans only: fence bodies, code spans, link destinations, template placeholders, and example-leader rows are structural carriers, not prose findings. Every semantic class and every altitude judgment remains review work against the catalog.

## [02]-[REGISTER]

The register's laws produce the voice; every catalog defect is a way of breaking one of them.

[OWNING_SUBJECT] — The owner is the grammatical subject and its verb is an act of ownership over the whole concern: mints, owns, folds, routes, binds, admits, rejects. A total positive claim forecloses every alternative by construction; a surface that merely supports, offers, or provides has not been designed yet. The partition principle is the durable law; a count is a consequence the reader derives, never a ceiling the prose enforces.

```markdown rejected
The package offers an optional graph lane and supports self-hosted deployments.
```

```markdown accepted
The graph lane binds only under the self-hosted profile row.
```

[PROHIBITION_BY_STRUCTURE] — A forbidden form appears only with its enforcing mechanism as the subject of the same clause; never as a roster of corpses, a ritual closing tail, or a naked impossibility claim. One total positive law makes the negation list redundant.

```markdown rejected
Cross-tenant batching is unspellable. A per-op check, an ambient flag, or a second meter is the deleted form.
```

```markdown accepted
Batch keys carry the tenant brand, so a batch is tenant-scoped by construction.
```

[DECISION_PER_LINE] — Each line states one resolved fact in a timeless voice with at most one load-bearing reason: no reassurance, no anticipated objection, no ship-status, no tag, no origin. The reader cannot tell which parts were written when, by whom, or in what order.

```markdown rejected
DECISION [V10]: the trust gate binds every identifier crossing into engine SQL — LANDED, verify and extend, never re-initialize (this replaces the phantom the prior draft carried).
```

```markdown accepted
The trust gate binds every identifier crossing into engine SQL.
```

[CAPABILITY] — Capability lands as present-tense owned fact with deep foresight, or the sentence does not exist. Consumer count is never a design axis: nothing is deferred until demand, defended against an imagined objection, or preserved for an old reader. A capability that cannot yet be modeled gets silence; genuinely open work is a tracked card, never a soft sentence.

[NAMED_SURFACE] — A nameable surface — member, command, key, flag, token — is written as a code span in its exact verified spelling; verification precedes authoring, an unverifiable member is a tracked open item never settled prose, and a nameable surface paraphrased in prose is a defect: the code span is the instruction.

```markdown rejected
Enable the merge-edges option and the network-simplex placement strategy in the layout block.
```

```markdown accepted
The layout block carries `mergeEdges: true` and `nodePlacementStrategy: NETWORK_SIMPLEX`.
```

Rebuilding an existing document under this register is its own discipline — the source's frame is the primary contaminant; run the [references/rewriting.md](references/rewriting.md) procedure.

## [03]-[FACT_LAW]

[FACT_CLASSES] — Every fact in a durable doc is exactly one of:
- [LAW]: Intent, invariant, boundary, prohibition. Survives any rename. Carried in prose.
- [REPRESENTATION]: A structure snapshot — tree, codemap, diagram. Regenerable from disk, verified by tooling, carried only in a fence or diagram, never restated in prose.
- [REGISTRY]: A fact whose system of record is the doc itself. The only class allowed to enumerate.

[REGENERATION_TEST] — Delete the sentence. A fresh agent regenerating the fact from disk plus the document's stated invariants proves it was a mirror: delete it, or demote it to a fenced representation when structure must be shown. A fact that cannot be regenerated is law kept at the altitude that owns it, still answerable to every defect class: surviving regeneration rules out the mirror alone, never a freeze, hedge, or ledger the catalog deletes.

[ONE_OWNER] — A second prose copy of any fact, at any altitude, is a fork waiting to drift. A pointer names the owner and the one consumed symbol, nothing of its internals; a doctrine is stated once at its charter and never recited per page. A corpus's vocabulary, owners, and policy values arrive settled in every later document — composed as given, never re-taught, renamed, or locally re-defined.

Altitude tiers, routing law, representation choice, table design, file-kind schemas, and marker systems are [references/structure.md](references/structure.md).

## [04]-[DEFECTS]

The defect classes are the review vocabulary; findings cite class and line. Definitions, detection tests, pairs, and reframe rules are [references/defects.md](references/defects.md).

[STRUCTURAL]: `ENUMERATION_ANCHOR` `STALE_MIRROR` `MECHANISM_LEAK` `META_FRAME` `TWIN_TRUTH` `REPORT_FRAME` `COUPLING`
[SEMANTIC]: `HEDGE` `CAPABILITY_GATE` `LEGACY_COMPAT` `IMPORTED_POSTURE` `VERSION_ANCHOR` `SET_IN_STONE` `WEAK_VERBS` `PROCESS_LEDGER` `ASSERTED_IMPOSSIBILITY` `DELETED_FORM_LITANY`
[SKILL]: `OVER_BROAD_TRIGGER` `STARVED_TRIGGER` `KEYWORD_STUFFING` `SELF_VOICED_DISCOVERY` `MONOLITH_ROOT` `REFERENCE_MAZE` `NO_OP_INTENSIFIER` `FILLER_LEAD` `CHAIN_RESTATEMENT` `QUALITY_LADDER` `COMMAND_CATALOG` `LIFECYCLE_SCRIPT` `CHECKLIST_TAIL` `SCRIPT_AS_PROSE` `BARE_ABSTRACTION` `FIXED_OUTPUT` `SUPPLY_CHAIN` — skill-bundle classes owned by [references/skills.md](references/skills.md)

## [05]-[TEMPLATES]

Authoring a new instance of a known file kind starts from its template; the binding is per row.

- [01]-[IDEAS]: Copy [templates/ideas.template.md](templates/ideas.template.md) verbatim; fill only the H1 token and lead slot.
- [02]-[TASKLOG]: Copy [templates/tasklog.template.md](templates/tasklog.template.md) verbatim; fill only the H1 token and lead slot.
- [03]-[README]: Use the exact structure of [templates/readme.template.md](templates/readme.template.md); replace only the slots. A unit spanning multiple sub-folders groups its domain cards under one `[FOLDER_TOKEN]:` label per folder; a small unit keeps the flat list and drops the labels.
- [04]-[ARCHITECTURE]: Use the exact structure of [templates/architecture.template.md](templates/architecture.template.md); replace only the slots.
- [05]-[SPEC]: Use the section spine of [templates/spec.template.md](templates/spec.template.md) exactly; slots carry their budgets, and the cluster count follows the domain.
- [06]-[API_CATALOG]: Use the exact structure of [templates/api-catalog.template.md](templates/api-catalog.template.md); replace only the slots.

A finished instance carries zero residual slot tokens — `rg '<[a-z][a-z0-9-]+>' <file>` returns nothing — and its heading census matches the template.

## [06]-[EXAMPLES]

Consult the matching set before building or repairing the container; entries are symptom-indexed with the fix demonstrated.

- [01]-[TABLES]: [examples/tables.md](examples/tables.md) — table crimes and their structural repairs.
- [02]-[LISTS]: [examples/lists.md](examples/lists.md) — mega bullets, shredded splits, and the classified repair.
- [03]-[MARKERS]: [examples/markers.md](examples/markers.md) — entry leaders, status vocabularies, glyphs.
- [04]-[INTROS]: [examples/intros.md](examples/intros.md) — leads that legislate and the rejected frames.
- [05]-[SKILLS]: [examples/skills.md](examples/skills.md) — broad triggers, lifecycle bodies, monolith roots, soft gates.

## [07]-[COMMENTS]

Comments — in source and in transcription-complete fences alike — serve the agent editing the file in isolation. One in-situ constraint the code cannot show, 1-2 lines, uncoupled from paths, sessions, and siblings, never a duplicate of card or index content. Every pass that touches a file prunes its stale or drifted comments in the same pass.

## [08]-[GOTCHAS]

- The most dangerous defect looks like rigor — a complete roster, an exact count, a frozen chant, a litany of forbidden alternatives. It reads as discipline and rots as law.
- Deleting a defective sentence never deletes capability: demote mechanism to its owner first, then collapse the copy; dropped payload is a defect.
- Legal prohibition is the house register, not a defect — stated once at the owner it stands; recited per page it is `TWIN_TRUTH`; enumerated as a roster it is `DELETED_FORM_LITANY`.
- Contract qualifiers survive the hedge ban: `optional`, `if present`, `where supported`, `when configured`, `only when`, `unless` scope behavior. Future tense survives only on a card growth line and a tracked research item.
- Tooling docs are durable law too: a tool doc states its contract and routes verbs to live `--help`, never mirroring help output or narrating commands for a human tour.
- Author satisfaction is never the exit: a durable doc seals on a context-free cold read that raises nothing — the producer's grade admits, the cold read decides.

## [09]-[REPO_INTEGRATION]

When the host repo declares a prose canon in its instruction chain, that canon wins on any conflict and this skill is its portable twin; the repo docs gate consumes `scripts/prose_gate.py --json`.
