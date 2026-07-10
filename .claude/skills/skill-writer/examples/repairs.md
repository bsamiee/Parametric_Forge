# [REPAIRS]

Skill repair is symptom-indexed: each entry names one defect an agent already sees in a bundle, carries the fixed Detection / Rejected / Accepted / Reason / Reframe card, and shows both shapes as tiny fences. The trigger is repaired before the body — a body no task selects is dead law.

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

## [06]-[SEDIMENT_BODY]

The body accretes one guard per past incident until dead threats outweigh live law.

- Detection: Rules that answer no property of the deliverable — each one a scar from a failure the current tooling already forecloses.
- Rejected:
    ```markdown rejected
    Never run the formatter twice in one pass.
    Always re-read the file after every edit before continuing.
    Double-check that the output directory exists before writing.
    ```
- Accepted:
    ```markdown accepted
    Run `scripts/render.py <file>`; it creates the output directory, formats once, and exits nonzero on drift.
    ```
- Reason: Every scar taxes every activation forever, and the pile buries the branch the skill exists to teach; the mechanized guard costs nothing and cannot be skipped.
- Reframe: Fold each guard into the script or gate that makes the failure unspellable, then delete the sentence; a guard that cannot be mechanized names its live failure condition or dies.

## [07]-[COLLIDING_TRIGGERS]

Two sibling descriptions both match one prompt, so selection is a coin flip and both skills lose attribution.

- Detection: A realistic task phrasing that selects either of two installed skills; a must-not-fire query from one skill's eval set fires it anyway.
- Rejected:
    ```yaml rejected
    # skill A
    description: Builds dashboards, charts, and data visualizations for any output medium.
    # skill B
    description: Creates interactive HTML pages including dashboards and visual reports.
    ```
- Accepted:
    ```yaml accepted
    # skill A
    description: >-
      Owns chart and graph construction — mark selection, palettes, axes — in any medium.
      Page layout, tabs, and interactivity around the charts belong to the HTML page owner.
    # skill B
    description: >-
      Owns interactive HTML pages — layout, navigation, controls, export. Chart internals
      (marks, scales, palettes) belong to the chart owner.
    ```
- Reason: The repair is symmetric refusal: each description names the neighbor's deliverable as its own boundary, so the prompt's noun decides the winner instead of chance.
- Reframe: Repair both descriptions, never a body; add the colliding phrasing to both skills' permanent must-not-fire sets.

## [08]-[DECORATIVE_DIAGRAM]

A fence restates the table beside it, so every activation pays render validation and reader traversal for information the prose already carries.

- Detection: A diagram whose nodes map one-to-one onto an adjacent table's rows, with no edges beyond reading order.
- Rejected:
    ```mermaid rejected
    flowchart LR
      A[description] --> B[SKILL.md] --> C[references]
    ```
- Accepted:
    ```mermaid accepted
    flowchart TD
      M{eval miss} -->|must-fire miss| D[starved discriminant: repair the first clause]
      M -->|must-not-fire hit| B[collision: repair both descriptions]
      M -->|adherence tie| L[dead law: delete the body rule]
    ```
- Reason: The rejected fence repeats the loading-tier table in reading order and carries no structure; the accepted fence is a dispatch whose labeled edges route each miss class to its repair surface — shape is the content.
- Reframe: Admit a fence only where edges carry routing, state, or interaction that prose spends a paragraph per arm to state; type selection, construction, and render validation ride the mermaid-diagramming skill.
