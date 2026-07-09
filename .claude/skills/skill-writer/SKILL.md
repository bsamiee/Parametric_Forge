---
name: skill-writer
description: >-
  Designs, authors, reviews, and repairs skill bundles end to end: SKILL.md root routing,
  trigger descriptions and listing budgets, references and progressive disclosure, bundled
  scripts and templates, frontmatter invocation policy, degrees-of-freedom calibration, and
  the eval loop that proves a skill fires when it must and changes output when it loads. Use
  when creating a skill, rewriting or auditing an existing bundle, writing or tuning a trigger
  description, splitting an oversized root, deciding whether material earns a skill or a
  cheaper owner, pricing how rigid an instruction is allowed to be, measuring trigger and
  adherence quality, or auditing a skill estate for trigger collisions, listing overflow,
  and forks. Prose register and the deterministic prose gate belong to the
  docgen skill; codex-native format and discovery mechanics belong to the codex skill;
  runnable orchestration scripts belong to workflow-creator; placement across memory files,
  rules, settings, and hooks belongs to harness-config.
---

# [SKILL_WRITER]

A skill is deployed law plus packaged capability: the description competes for selection in every session, the body competes with the task's own context once loaded, and every bundled file is either routed capability or dead weight. Bundle anatomy, budgets, frontmatter policy, and freedom calibration are [references/anatomy.md](references/anatomy.md); trigger science and listing economics are [references/triggers.md](references/triggers.md); the defect catalog is [references/defects.md](references/defects.md); the eval loop is [references/evals.md](references/evals.md); fleet-scale governance is [references/estate.md](references/estate.md); pressure cases with fixes are [examples/repairs.md](examples/repairs.md).

## [01]-[PLACEMENT]

A skill exists only when its material is a reusable procedure or deliverable-bound doctrine that recurs across tasks; everything else has a cheaper owner.

- [MEMORY]: An always-true project convention rides the memory hierarchy — it binds every session, so on-demand loading only delays it.
- [RULE]: A convention true only for a subtree rides a path-scoped rule; the path predicate is the trigger, no description competes.
- [SKILL]: A procedure, doctrine, or artifact contract selected by task shape rides a skill; the description is the classifier.
- [SUBAGENT]: Work whose transcript pollutes the parent context moves to a subagent; a skill changes what the active agent knows, a subagent changes where work happens — orthogonal axes, freely combined.
- [SCRIPT]: Deterministic mechanics ride an executable the skill invokes, never prose the agent re-derives.

A recurring prompt pattern graduates into a skill after it has recurred, never before; a skill authored for an imagined future task is deleted, not improved.

## [02]-[BUDGETS]

- [ROOT]: `SKILL.md` holds at most 500 lines; the root routes, references carry depth one hop down, and a route's target never routes onward.
- [DESCRIPTION]: At most 1024 characters, third person, deliverable and primary triggers in the first clause — listings truncate, and the tail dies first.
- [BODY]: Loaded body persists across turns and rides compaction inside a token budget; it lands late in context where attention is dense, which is why loaded law binds and why every dead line taxes every task the skill touches for the rest of the session.
- [SCRIPTS]: Execute without entering context; their cost is invocation and receipt, never implementation.

Admission tests per file kind, the frontmatter policy surface, and the freedom bands are [references/anatomy.md](references/anatomy.md).

## [03]-[TRIGGERS]

Selection runs on name and description alone — the body is invisible until after the choice is made. The description names the owned deliverable, the discriminating objects and verbs that select it, and the adjacent deliverable it refuses; under-triggering is the dominant field failure, so descriptions lean assertive. Listing truncation law, invocation-mode policy, path scoping, measured description A/B, and collision repair are [references/triggers.md](references/triggers.md).

## [04]-[DEFECTS]

Findings cite class and line; definitions, detection tests, and reframes are [references/defects.md](references/defects.md).

[TRIGGER]: `OVER_BROAD_TRIGGER` `STARVED_TRIGGER` `KEYWORD_STUFFING` `SELF_VOICED_DISCOVERY`
[DISCLOSURE]: `MONOLITH_ROOT` `REFERENCE_MAZE` `UNEARNED_HOP`
[BODY]: `NO_OP_INTENSIFIER` `FILLER_LEAD` `CHAIN_RESTATEMENT` `QUALITY_LADDER` `COMMAND_CATALOG` `LIFECYCLE_SCRIPT` `CHECKLIST_TAIL` `SCRIPT_AS_PROSE` `BARE_ABSTRACTION` `FIXED_OUTPUT` `DEGREES_OF_FREEDOM` `SEDIMENT` `NEGATION_ONLY` `SUPPLY_CHAIN` `DECORATIVE_DIAGRAM` `INERT_EXAMPLE`

## [05]-[EVALS]

A skill is proven, never assumed: trigger evals show it fires on the tasks it owns and stays silent on its neighbors; adherence evals show the loaded body changes output against a baseline run. A body rule that never changes an output across the suite is dead weight and is deleted. Query-set construction, paired blind comparison, grader doctrine, tooling separation, and suite maintenance are [references/evals.md](references/evals.md).

## [06]-[GATE]

Every bundle file passes the docgen skill's prose gate before return — it mechanically binds frontmatter shape, name and directory identity, description voice and budgets, the root line ceiling, orphan bundle files, and nested reference hops, beside the full prose floor. The register inside every bundle file answers to the docgen catalog; this skill owns what the bundle is, docgen owns how its prose speaks.

## [07]-[COMPOSITION]

- Each skill owns one deliverable kind and names in its description the adjacent deliverable it refuses; two skills matching one prompt is a boundary defect repaired on both descriptions.
- Shared doctrine has one owning skill and every sibling composes it silently by name; a policy sentence or marker vocabulary spelled in two bundles is a fork.
- A mixed task routes by deliverable, never by topic: prose to the prose owner, fences to the fence owner, bundles to this skill, in sequence.

## [08]-[ESTATE]

An installed fleet is one selection system: descriptions compete in a shared listing, the budget is common property, and a defect in one bundle degrades its neighbors' selection. `scripts/estate_audit.py <roots...>` sweeps every bundle beneath the given roots in one pass and receipts description budgets, starved triggers, pairwise trigger overlap, cross-bundle prose forks, shadowed names, and the listing spend — text rows by default, `--json` for machine consumers, nonzero exit on hard failures. Audit cadence, finding-to-repair routing, and mirror and port discipline are [references/estate.md](references/estate.md).
