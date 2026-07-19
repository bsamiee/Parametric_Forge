---
name: skill-writer
description: >-
    Designs, authors, reviews, and repairs skill bundles — SKILL.md roots, trigger descriptions,
    references, templates, bundled scripts, frontmatter policy — and proves them with trigger and
    adherence evals. Use when creating a skill, rewriting or auditing an existing bundle, writing
    or tuning a trigger description, splitting an oversized root, deciding whether material earns
    a skill or a cheaper owner, pricing how rigid an instruction is allowed to be, measuring
    trigger and adherence quality, or auditing a skill estate for trigger collisions, listing
    overflow, and forks. Prose register and the deterministic prose gate belong to the
    docgen skill; codex-native format and discovery mechanics belong to the codex skill;
    runnable orchestration scripts belong to workflow-creator; placement across memory files,
    rules, settings, and hooks belongs to harness-steering.
---

# [SKILL_WRITER]

A skill is deployed law plus packaged capability: the description competes for selection in every session, the body competes with the task's own context once loaded, and every bundled file is either routed capability or dead weight.

## [01]-[ROUTING]

[REFERENCES]:
- [01]-[ANATOMY](references/anatomy.md): bundle anatomy, budgets, frontmatter policy, the root schema, freedom calibration
- [02]-[TRIGGERS](references/triggers.md): trigger science and listing economics
- [03]-[DEFECTS](references/defects.md): catalogs each authoring defect class with its copyable repair

[TEMPLATES]:
- [01]-[SKILL](templates/skill.template.md): carries the root schema as a copyable skeleton; fill the slots, leave zero residual tokens

[SCRIPTS]:
- [01]-[ESTATE_AUDIT](scripts/estate_audit.py): one-pass fleet sweep; invocation in the estate section

## [02]-[BUDGETS]

- [ROOT]: `SKILL.md` holds at most 500 lines and is the bundle's only router; a `README.md` or secondary index at any depth is a defect.
- [DEPTH]: References carry depth one hop down, and a route's target never routes onward.
- [DESCRIPTION]: At most 1024 characters, third person, deliverable and primary triggers first — listings truncate, and the tail dies first.
- [BODY]: A loaded body persists across turns and lands late where attention is dense — its law binds, and every dead line taxes the whole session.
- [SCRIPTS]: Execute without entering context; their cost is invocation and receipt, never implementation.

## [03]-[TRIGGERS]

Selection runs on name and description alone — the body is invisible until after the choice is made. Each description names the owned deliverable, the discriminating objects and verbs that select it, and the adjacent deliverable it refuses; under-triggering is the dominant field failure, so descriptions lean assertive.

## [04]-[EVALS]

A skill is proven, never assumed: trigger evals show it fires on the tasks it owns and stays silent on its neighbors; adherence evals show the loaded body changes output against a baseline run. A body rule that never changes an output across the suite is dead weight and is deleted.

## [05]-[GATE]

Every bundle file passes the docgen skill's prose gate before return — it mechanically binds frontmatter shape, name and directory identity, description voice and budgets, the root line ceiling, orphan bundle files, and nested reference hops, beside the full prose floor. Register inside every bundle file answers to the docgen catalog; this skill owns what the bundle is, docgen owns how its prose speaks.

## [06]-[COMPOSITION]

- Each skill owns one deliverable kind and names the adjacent one it refuses; two skills matching one prompt is a defect on both descriptions.
- Shared doctrine has one owning skill every sibling composes silently; a policy sentence or marker vocabulary spelled in two bundles is a fork.
- A mixed task routes by deliverable, never by topic: prose to the prose owner, fences to the fence owner, bundles to this skill, in sequence.

## [07]-[ESTATE]

An installed fleet is one selection system: descriptions compete in a shared listing, the budget is common property, and a defect in one bundle degrades its neighbors' selection. `${CLAUDE_SKILL_DIR}/scripts/estate_audit.py <roots...>` sweeps every bundle beneath the given roots in one pass and receipts description budgets, starved triggers, pairwise trigger overlap, cross-bundle prose forks, shadowed names, and the listing spend — text rows by default, `--json` for machine consumers, nonzero exit on hard failures.
