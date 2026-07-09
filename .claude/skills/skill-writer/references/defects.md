# [DEFECTS]

The classes here are the failures only an instruction bundle can commit; findings cite class and line. The trigger is repaired before the body — a body no task selects is dead law. Prose-register defects inside bundle files — hedges, meta-frames, ledgers, litanies — belong to the docgen catalog and are cited from there.

## [01]-[TRIGGER_CLASSES]

### [01.1]-[OVER_BROAD_TRIGGER]

- Detection: More than one unrelated domain family in one description, or a trigger that matches an ordinary working day without a domain noun.
- Rejected: Use for all programming, debugging, review, research, and documentation tasks.
- Accepted: Use for shell scripts, CLI entrypoints, CI jobs, cron, and text-processing pipelines.
- Reason: Metadata competes across every installed skill; a boundary-free trigger fires on work a sibling owns.
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

## [02]-[DISCLOSURE_CLASSES]

### [02.1]-[MONOLITH_ROOT]

- Detection: A root past the platform line ceiling, or root sections carrying reference banks, troubleshooting inventories, or example floods every activation loads.
- Rejected: One root file carrying the full API reference, every worked example, and the troubleshooting ledger inline.
- Accepted: The root routes; references carry the doctrine, examples the pressure cases, scripts the mechanics.
- Reason: Rare branches loaded on every activation tax every task the skill touches.
- Reframe: Move mutually exclusive and rare material one hop down; keep the root a router.

### [02.2]-[REFERENCE_MAZE]

- Detection: A route whose target's job is routing onward, or any resource more than one hop from the root.
- Rejected: Read the first reference, then the second, then the README linked under the third.
- Accepted: The route row names one file and the task that opens it; the file carries its doctrine whole.
- Reason: Multi-hop chains make activation non-deterministic — agents under-read or flood context chasing links.
- Reframe: Flatten to one hop; a reference that only points is deleted and its routes move to the root.

### [02.3]-[UNEARNED_HOP]

- Detection: A reference no route's task opens, one restating root content a hop down, or one whose whole content fits the root without breaching its ceiling.
- Rejected: A twelve-line file of general tips behind a route labeled for more detail.
- Accepted: The route row names the task that opens the file; the file carries doctrine the common path never loads and the root cannot hold.
- Reason: Every reference bets a permanent route row against depth paid on one branch; a file that loses the bet taxes routing while teaching nothing.
- Reframe: Fold the content into the root or delete the file; a reference is admitted by the branch that needs it, never by the material's existence.

## [03]-[BODY_CLASSES]

A body line earns its place by changing trigger selection, routing, execution, or validation; intensity, ceremony, and restated harness obligations change nothing and are deleted.

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

- Detection: Numbered lifecycle steps every coding task already performs — think, plan, inspect, implement, validate — or a mandated reasoning shape with fixed depth.
- Rejected: First think deeply, then plan, then inspect, then implement, then validate, then summarize.
- Accepted: A document edit classifies each suspect passage before rewriting it.
- Reason: Ceremonial sequencing fights the model's native loop; the value is the domain-specific decision point alone.
- Reframe: Keep only the branch a generic agent gets wrong; delete every step that binds any task equally.

### [03.7]-[CHECKLIST_TAIL]

- Detection: A closing section of soft reminders — ensure quality, validate, document, summarize — with no machine-checkable gate.
- Rejected: Before finishing: ensure quality, handle edge cases, validate, document, ask if needed.
- Accepted: Completion binds on a clean gate run over every touched artifact.
- Reason: Ritual closure reads as optional and paraphrasable; a hard gate is a command with an exit code.
- Reframe: Replace the tail with the concrete gate, or delete it.

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

- Detection: Instruction rigidity mismatched to task variance — a fragile deterministic sequence left as loose heuristics, or an exact command sequence and fixed depth mandated over work whose correct shape varies by context.
- Rejected: Migrate the schema however fits the situation. Run exactly these four commands for every review, in order, every time.
- Accepted: The migration runs `scripts/migrate.py --verify --backup` unchanged; review depth follows the diff, and only the acceptance gate is fixed.
- Reason: Freedom is a design axis: an operation that breaks on deviation needs rails with no parameters, and work whose best path is contextual needs the goal and the gate, not a script.
- Reframe: Classify each instruction by the cost of deviation — deviation breaks it: pin the exact invocation; deviation is legitimate: state the deliverable and its gate, delete the mandated path.

### [03.12]-[SEDIMENT]

- Detection: A rule explainable only by a past incident, not by the deliverable — a guard against a failure mode the current bundle, tooling, or model no longer exhibits.
- Rejected: Never call the formatter twice in one pass; always re-read the file after every edit; double-check the encoding before saving.
- Accepted: (silence — the incident's fix lives in the script or gate that now makes the failure unspellable.)
- Reason: Scar tissue accretes one incident at a time until the body is a museum of dead threats taxing every activation.
- Reframe: Move the guard into the script or gate that enforces it mechanically, then delete the sentence; a guard that cannot be mechanized names its live failure condition or dies.

### [03.13]-[NEGATION_ONLY]

- Detection: A rule stated only as prohibition, leaving the correct form unwritten.
- Rejected: Do not use vague trigger descriptions. Never put examples in the root.
- Accepted: The description names the owned deliverable and its discriminating nouns; examples ride one hop down, symptom-indexed.
- Reason: A bare negation defines a hole, not a target — the agent knows one rejected point in an unbounded space and guesses the rest.
- Reframe: State the positive form that forecloses the prohibited one; keep the negation only when it carries the enforcing mechanism.

### [03.14]-[SUPPLY_CHAIN]

- Detection: A network fetch, global install, credential read, or broad filesystem grant instructed inside a skill body.
- Rejected: Install the helper globally and fetch the newest script from the vendor URL at run time.
- Accepted: Bundled scripts run as shipped; a skill that owns an install surface names the exact source, its scope, and its verification step.
- Reason: A skill is an executable supply-chain artifact; an instructed fetch is an injection channel wearing documentation.
- Reframe: Bundle the mechanics; an owned install surface carries source, scope, and verification in one row.

### [03.15]-[DECORATIVE_DIAGRAM]

- Detection: A diagram fence restating an adjacent table, roster, or two-step sequence — no topology, state, or flow the prose fails to carry.
- Rejected: A three-node flowchart under the three-row table naming the same tiers.
- Accepted: A dispatch-topology fence whose labeled edges carry routing prose spends a paragraph per arm to state; construction and validation ride the mermaid-diagramming skill.
- Reason: A fence costs render validation and reader traversal; decoration spends both on information already cheaper as a table.
- Reframe: Admit a fence only where shape is the content — dispatch topology, state machine, multi-actor flow — and keep the table otherwise.

### [03.16]-[INERT_EXAMPLE]

- Detection: An example whose accepted half cannot drop into a template or live bundle unchanged — narrative retelling, elided bodies, placeholder residue.
- Rejected: An entry narrating how a weak description was once improved, with the improved description elided.
- Accepted: Every example is an executable seed: the accepted half is complete, copyable, and passes the gate as it stands.
- Reason: Examples exist because agents copy; a pair that resists copying calibrates nothing and feeds no template.
- Reframe: Rebuild the pair at copyable scale or delete it; templates distill from examples, and an example no template inherits is an illustration.
