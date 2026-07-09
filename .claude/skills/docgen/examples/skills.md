# [SKILL_CRAFT]

Skill repair is symptom-indexed: each entry names one defect an agent already sees in a skill bundle, carries the fixed Detection / Rejected / Accepted / Reason / Reframe card, and shows both shapes as tiny fences. The trigger is repaired before the body — a body no task selects is dead law.

## [01]-[BROAD_TRIGGER]

A description claims every adjacent domain, so the skill fires on work a sibling owns and loses the tasks it exists for.

- Detection: A description spanning unrelated domain families, or one that matches an ordinary working day without a domain noun.
- Rejected:
  ```yaml rejected
  description: Helps with documentation, writing, editing, review, research, and general text quality across all file types.
  ```
- Accepted:
  ```yaml accepted
  description: >-
    Authors and repairs Mermaid fences: diagram type selection, graph logic, and layout
    validation. Use when a task draws, maps, or diagrams a system, flow, or schema — not
    for quantitative charts or interactive HTML pages.
  ```
- Reason: The accepted form names the owned deliverable, the selecting verbs, the concrete objects, and the refused neighbors; the rejected form competes with every sibling on every prompt.
- Reframe: Deliverable first, discriminating nouns second, negative boundary last — all in third person.

## [02]-[LIFECYCLE_BODY]

The body narrates a generic work loop instead of the domain decisions a generic agent gets wrong.

- Detection: Numbered steps that bind any coding task equally — plan, inspect, implement, validate, summarize.
- Rejected:
  ```markdown rejected
  1. Think carefully about the request.
  2. Plan the work in detail.
  3. Implement the changes.
  4. Validate everything thoroughly.
  5. Summarize what was done.
  ```
- Accepted:
  ```markdown accepted
  A table failing the eligibility triple converts whole — record set, indexed list, or cards — never trimmed in place. A passed test repairs in place: split, hoist, extract, relieve.
  ```
- Reason: The rejected steps restate the model's native loop and displace the one branch the skill exists to teach; the accepted form carries only the decision a generic agent misses.
- Reframe: Delete the ceremonial sequence; keep the domain-specific branch points and their selection conditions.

## [03]-[MONOLITH_ROOT]

The root inlines reference banks and example floods, so every activation pays for branches the task never takes.

- Detection: Root sections named after an API reference, a troubleshooting ledger, or an example inventory.
- Rejected:
  ```markdown rejected
  ## API Reference
  (four hundred lines of member tables)
  ## Troubleshooting
  (every failure ever observed)
  ```
- Accepted:
  ```markdown accepted
  - [01]-[FORMS]: [references/forms.md](references/forms.md) — field detection and fill order; open for form-filling tasks.
  - [02]-[TABLES]: [references/tables.md](references/tables.md) — extraction geometry; open for table extraction.
  ```
- Reason: The route row costs two lines on every activation; the inlined bank costs its full weight whether or not the branch runs.
- Reframe: Move mutually exclusive and rare material one hop down, each route labeled by the task that opens it.

## [04]-[SOFT_GATE]

A closing checklist of reminders stands where a machine gate belongs, so completion is paraphrasable.

- Detection: A final section of soft imperatives with no command and no exit code.
- Rejected:
  ```markdown rejected
  ## Before returning
  - Ensure quality and consistency.
  - Validate the output.
  - Document any changes.
  ```
- Accepted:
  ```markdown accepted
  Completion binds on `uv run scripts/gate.py --json <paths>` returning clean for every touched artifact.
  ```
- Reason: A reminder is skipped or paraphrased under pressure; a gate command with an exit code is executed or visibly failed.
- Reframe: Replace the tail with the concrete gate invocation, or delete it.

## [05]-[FREEDOM_MISMATCH]

Instruction rigidity contradicts task variance: fragile mechanics float free while contextual judgment is pinned to a script.

- Detection: A deterministic, breaks-on-deviation operation described as open guidance, or a fixed command litany mandated over work whose right depth follows the input.
- Rejected:
  ```markdown rejected
  Migrate the schema in whatever way fits.
  Every review runs the same four commands in the same order regardless of the diff.
  ```
- Accepted:
  ```markdown accepted
  The migration runs `scripts/migrate.py --verify --backup` unchanged.
  Review depth follows the diff; completion binds only on the acceptance gate.
  ```
- Reason: Rails belong where deviation breaks the run; goals and gates belong where the best path is contextual — each inversion produces broken runs or ritual theater.
- Reframe: Price each instruction by its cost of deviation, then pin the invocation or free the path.
