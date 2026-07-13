# [DEFECTS]

The classes here are the failures only an instruction bundle can commit; a finding cites the class and line, and each class owns the copyable before-and-after that repairs it, so detection and fix have one owner. The trigger is repaired before the body — a body no task selects is dead law. Prose-register defects inside bundle files — hedges, meta-frames, ledgers, litanies — belong to the docgen catalog and are cited from there.

## [01]-[TRIGGER_CLASSES]

### [01.1]-[OVER_BROAD_TRIGGER]

A description claims every adjacent domain, so the skill fires on work a sibling owns and loses the tasks it exists for.

- Detection: More than one unrelated domain family in one description, or a trigger that matches an ordinary working day without a domain noun.
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
- Reason: Metadata competes across every installed skill; a boundary-free trigger fires on work a sibling owns and buries the discriminants that would select it.
- Reframe: Name the artifact kinds and verbs that select the skill, then add the negative boundary that rejects the neighbors.

### [01.2]-[STARVED_TRIGGER]

- Detection: A trigger clause with fewer than two discriminating nouns — no file kinds, no fence kinds, no commands, no artifact names.
- Rejected: Use when working with files.
- Accepted: Use when authoring, editing, or validating Mermaid fences, choosing a diagram type, or repairing graph logic.
- Reason: Selection runs on the description alone; a starved trigger loses to any sibling that names the object.
- Reframe: List the exact objects, verbs, and file kinds; selection needs discriminants, not breadth.

### [01.3]-[KEYWORD_STUFFING]

- Detection: Repeated stems or comma-joined synonyms not tied to distinct trigger contexts.
- Rejected: Use for docs markdown writing README architecture spec prose text documentation editing.
- Accepted: Use when authoring, editing, reviewing, or rewriting durable markdown — README, architecture, specs, standards, skills, prompts, tool docs.
- Reason: Synonym spam inflates startup metadata and blurs the boundary against adjacent skills.
- Reframe: Collapse the synonyms into one discriminating phrase per genuine trigger context.

### [01.4]-[SELF_VOICED_DISCOVERY]

- Detection: First- or second-person voice in the description; quoted user utterances are trigger material, never voice.
- Rejected: I help you process PDFs and can generate reports.
- Accepted: Processes PDF files and generates reports; use for extraction, form filling, and document merging.
- Reason: The description enters system context beside third-person siblings; a voiced entry breaks the selection register.
- Reframe: Third person — owned deliverable first, trigger clause second, negative boundary last.

### [01.5]-[COLLIDING_TRIGGERS]

Two precise sibling descriptions both match one prompt, so selection is a coin flip and both skills lose attribution; precision alone does not prevent a collision.

- Detection: A realistic task phrasing that selects either of two installed skills; a must-not-fire query from one skill's eval set fires the other anyway.
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
- Reason: Symmetric refusal makes the prompt's own noun decide the winner instead of chance; each description names the neighbor's deliverable as its own boundary.
- Reframe: Repair both descriptions, never a body; add the colliding phrasing to both permanent must-not-fire sets. The collision procedure and the neighbor-proof re-run are triggers.md.

## [02]-[DISCLOSURE_CLASSES]

### [02.1]-[MONOLITH_ROOT]

The root inlines reference banks and example floods, so every activation pays for branches the task never takes.

- Detection: A root past the platform line ceiling, or root sections named after an API reference, a troubleshooting ledger, or an example inventory every activation loads.
- Rejected:
    ```markdown rejected
    ## API Reference

    (four hundred lines of member tables)

    ## Troubleshooting

    (every failure ever observed)
    ```
- Accepted:
    ```markdown accepted
    - [01]-[FORMS](references/forms.md): field detection and fill order; open for form-filling tasks.
    - [02]-[TABLES](references/tables.md): extraction geometry; open for table extraction.
    ```
- Reason: A route row costs two lines on every activation; the inlined bank costs its full weight whether or not the branch runs.
- Reframe: Move mutually exclusive and rare material one hop down, each route labeled by the task that opens it; keep the root a router.

### [02.2]-[REFERENCE_MAZE]

- Detection: A route whose target's job is routing onward, or any resource more than one hop from the root.
- Rejected: Read the first reference, then the second, then the README linked under the third.
- Accepted: The route row names one file and the task that opens it; the file carries its doctrine whole.
- Reason: Multi-hop chains make activation non-deterministic — agents under-read or flood context chasing links, and a nested reference is previewed with `head` rather than read whole.
- Reframe: Flatten to one hop; a reference that only points is deleted and its routes move to the root.

### [02.3]-[UNEARNED_HOP]

- Detection: A reference no route's task opens, one restating root content a hop down, or one whose whole content fits the root without breaching its ceiling.
- Rejected: A twelve-line file of general tips behind a route labeled for more detail.
- Accepted: The route row names the task that opens the file; the file carries doctrine the common path never loads and the root cannot hold.
- Reason: Every reference bets a permanent route row against depth paid on one branch; a file that loses the bet taxes routing while teaching nothing.
- Reframe: Fold the content into the root or delete the file; a reference is admitted by the branch that needs it, never by the material's existence.

## [03]-[BODY_CLASSES]

A body line earns its place by changing trigger selection, routing, execution, or validation; intensity, ceremony, and restated harness obligations change nothing and are deleted. The form each line takes follows the failure it guards, and that mapping is [03.17]-[FORM_MISMATCH].

### [03.1]-[NO_OP_INTENSIFIER]

- Detection: A sentence carrying only quality adjectives — no owned noun, verb, tool, file, trigger, or refusal condition.
- Rejected: Always be extremely careful and produce high-quality, robust work.
- Accepted: Reject a row unless it changes trigger selection, routing, execution, or validation.
- Reason: Intensity alone changes no next action; the line burns context the task owns.
- Reframe: Bind the sentence to an owner, an action, and a condition, or delete it.

### [03.2]-[FILLER_LEAD]

- Detection: An operative instruction delayed behind a lead-in — note that, remember to, make sure to, keep in mind.
- Rejected: It is important to note that the artifact needs validation before returning.
- Accepted: Validate the artifact with `scripts/check.py <file>`.
- Reason: The lead-in buries the operative verb and makes weak prose read as policy.
- Reframe: Open on the operative verb; the lead-in dies.

### [03.3]-[CHAIN_RESTATEMENT]

- Detection: A sentence naming root instructions, system prompts, generic tool use, or obedience the harness already injects.
- Rejected: Follow CLAUDE.md, use the available tools, obey system instructions, and ask clarifying questions.
- Accepted: (silence — the instruction chain already binds; the skill adds only its own routing and law.)
- Reason: The duplicate is a fork of a fact the harness owns and hides the skill's incremental capability.
- Reframe: Delete the restatement; keep only the skill-local files, triggers, and contracts the chain does not carry.

### [03.4]-[QUALITY_LADDER]

- Detection: Good/better/best, minimum/ideal, or basic/advanced tiers with no trigger selecting a tier.
- Rejected: Good: run tests. Better: lint and tests. Best: review, lint, tests, and screenshots.
- Accepted: `gate <file>` passes before return; `render <file>` binds whenever layout changed.
- Reason: Subjective escalation invites tier-shopping by time and confidence; a contract has no tiers.
- Reframe: State the gate as an unconditional contract, or make each mode a row with the trigger that selects it.

### [03.5]-[COMMAND_CATALOG]

- Detection: A tool or command inventory whose rows carry no task trigger and no acceptance effect.
- Rejected: Useful commands: rg, fd, jq, yq, shellcheck, shfmt, tree.
- Accepted: A shell script passes `bash -n`, ShellCheck, and its own `--self-test` where present.
- Reason: A brochure spends selection attention on commands the task never needs.
- Reframe: Tie each command to the trigger that demands it and the signal that accepts it; delete the rest.

### [03.6]-[LIFECYCLE_SCRIPT]

The body narrates a generic work loop instead of the one domain decision a generic agent gets wrong.

- Detection: Numbered lifecycle steps every coding task already performs — think, plan, inspect, implement, validate — or a mandated reasoning shape with fixed depth.
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
- Reason: Ceremonial sequencing restates the model's native loop and displaces the branch the skill exists to teach.
- Reframe: Keep only the branch a generic agent gets wrong; delete every step that binds any task equally.

### [03.7]-[CHECKLIST_TAIL]

A closing checklist of reminders stands where a machine gate belongs, so completion is paraphrasable.

- Detection: A closing section of soft imperatives — ensure quality, validate, document, summarize — with no command and no exit code.
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

### [03.8]-[SCRIPT_AS_PROSE]

- Detection: Deterministic parsing, sorting, extraction, conversion, or rendering narrated as sequential prose steps.
- Rejected: To inspect the file, parse the pages, detect the fields, sort them, and emit JSON.
- Accepted: Run `scripts/extract_fields.py <file>`; the receipt carries the field rows.
- Reason: Prose mechanics drift from the code that executes them and spend tokens on what a script owns silently.
- Reframe: Move the mechanics into a bundled script; the root keeps the invocation and the receipt shape.

### [03.9]-[BARE_ABSTRACTION]

- Detection: Three or more abstract guidance bullets with no paired rejected/accepted example, template, or gate.
- Rejected: Write concise, actionable instructions with good style.
- Accepted: One rejected/accepted pair per rule agents copy incorrectly without it.
- Reason: Adjectives calibrate nothing; the paired example teaches the exact transformation.
- Reframe: Attach the pair, or delete the abstraction.

### [03.10]-[FIXED_OUTPUT]

- Detection: One mandated output skeleton — summary, findings, recommendations, next steps — regardless of consumer.
- Rejected: Always output a long markdown report with summary, findings, recommendations, and next steps.
- Accepted: An analytical run emits the report template; a machine consumer takes a receipt row.
- Reason: A fixed skeleton spends context on format where the consumer defines the product.
- Reframe: Route output shape by consumer; mandate a skeleton only where that artifact is the skill's deliverable.

### [03.11]-[DEGREES_OF_FREEDOM]

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

### [03.12]-[SEDIMENT]

The body accretes one guard per past incident until dead threats outweigh live law.

- Detection: A rule explainable only by a past incident, not by the deliverable — a guard against a failure the current bundle, tooling, or model no longer exhibits.
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

### [03.13]-[NEGATION_ONLY]

- Detection: A rule stated only as prohibition, leaving the correct form unwritten.
- Rejected: Do not use vague trigger descriptions. Never put examples in the root.
- Accepted: The description names the owned deliverable and its discriminating nouns; examples ride one hop down, symptom-indexed.
- Reason: A bare negation defines a hole, not a target — the agent knows one rejected point in an unbounded space and guesses the rest.
- Reframe: State the positive form that forecloses the prohibited one; keep the negation only where it guards a rule violated under pressure and carries its enforcing mechanism, and pick the instruction's form by its failure per [03.17]-[FORM_MISMATCH].

### [03.14]-[SUPPLY_CHAIN]

- Detection: A network fetch, global install, credential read, or broad filesystem grant instructed inside a skill body.
- Rejected: Install the helper globally and fetch the newest script from the vendor URL at run time.
- Accepted: Bundled scripts run as shipped; a skill that owns an install surface names the exact source, its scope, and its verification step.
- Reason: A skill is an executable supply-chain artifact; an instructed fetch is an injection channel wearing documentation.
- Reframe: Bundle the mechanics; an owned install surface carries source, scope, and verification in one row.

### [03.15]-[DECORATIVE_DIAGRAM]

A fence restates the table beside it, so every activation pays render validation and reader traversal for information the prose already carries.

- Detection: A diagram fence restating an adjacent table, roster, or two-step sequence — no topology, state, or flow the prose fails to carry.
- Rejected:
    ```mermaid rejected
    flowchart LR
      accTitle: Decorative reading-order chain
      accDescr: A linear description-to-references chain restating the loading tiers in reading order.
      A[description] --> B[SKILL.md] --> C[references]
    ```
- Accepted:
    ```mermaid accepted
    flowchart TD
      accTitle: Eval-miss routing
      accDescr: Each eval-miss class routes to the repair surface that owns it.
      M{eval miss} -->|must-fire miss| D[starved discriminant: repair the first clause]
      M -->|must-not-fire hit| B[collision: repair both descriptions]
      M -->|adherence tie| L[dead law: delete the body rule]
    ```
- Reason: The rejected fence repeats an adjacent table in reading order and carries no structure; the accepted fence is a dispatch whose labeled edges route each miss class to its repair surface — shape is the content.
- Reframe: Admit a fence only where edges carry routing, state, or interaction that prose spends a paragraph per arm to state; construction and render validation ride the mermaid-diagramming skill.

### [03.16]-[INERT_EXAMPLE]

- Detection: An example whose accepted half cannot drop into a template or live bundle unchanged — narrative retelling, elided bodies, placeholder residue.
- Rejected: An entry narrating how a weak description was once improved, with the improved description elided.
- Accepted: Every example is an executable seed: the accepted half is complete, copyable, and passes the gate as it stands.
- Reason: Examples exist because agents copy; a pair that resists copying calibrates nothing and feeds no template.
- Reframe: Rebuild the pair at copyable scale or delete it; templates distill from examples, and an example no template inherits is an illustration.

### [03.17]-[FORM_MISMATCH]

The instruction is well-founded but wears the wrong form for its failure, so it misfires the way the wrong tool does.

- Detection: A prohibition guarding a wrongly-shaped output, a positive recipe guarding a rule violated under pressure, prose guarding an element the model omits, or an unconditional rule guarding behavior that is correct only under a predicate.
- Rejected: Never write shallow analysis. (the failure is shallow output, not a violation under pressure)
- Accepted: The analysis names the mechanism, the failure mode, and the observed evidence for each finding. (a positive recipe shapes the output the prohibition could not)
- Reason: The form the instruction takes is a lever, and each failure mode answers to one lever — a prohibition shapes a rule violated under pressure, a positive recipe shapes output form, a required slot forecloses omission, and a predicate scopes conditional behavior; a form mismatched to its failure produces the very output it guards against.
- Reframe: Classify the failure, then pick the form — prohibition with a rationalization guard for pressure violations, positive recipe for output shape, a required structural slot for omission, a rule conditioned on an observable predicate for conditional behavior.
