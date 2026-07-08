# [METHOD]

The page is an information instrument before it is an interface: every region answers a named reader question, and a mark that cannot name its question is deleted. The method runs in order — qualify the medium, investigate, select, structure, lay out, choose interaction, review — and each stage consumes the artifacts of the one before it.

## [01]-[MEDIUM]

Markdown is the default carrier; a page earns its file only where structure, adjacency, or manipulation changes the reader's answer. The work class names the win the page must deliver — a page that cannot name its row stays markdown.

| [INDEX] | [WORK]                   | [HTML_WINS_WHEN]                                                                        |
| :-----: | :----------------------- | :-------------------------------------------------------------------------------------- |
|  [01]   | exploration and planning | undecided alternatives sit adjacent, compare visually, and convert into the chosen plan |
|  [02]   | review and understanding | diffs, call graphs, and risk maps keep their spatial relations instead of flattening    |
|  [03]   | design                   | tokens, type scales, and component states render as the live decisions they are         |
|  [04]   | prototyping              | motion and interaction must be felt — easing, timing, and flow tune only when live      |
|  [05]   | illustration and diagram | vector figures need hand-tweaking, per-figure export, or clickable inspection           |
|  [06]   | deck                     | a case walks slide by slide under keyboard control with no export step                  |
|  [07]   | research and learning    | navigation scaffolds — tabs, glossaries, live models — make the topic traversable       |
|  [08]   | report                   | metrics, timelines, and evidence tables turn a skimmed document into a scanned one      |
|  [09]   | editing interface        | the exact decision surface is a purpose-built control set exporting durable output      |

Render the thing: real code, real controls, real data rows, real SVG land on the page — prose describing an unrendered candidate is a defect. Decisions sit beside the evidence that earns them: a recommendation, verdict, or ranking shares a viewport with its pro/con rows, risk map, or score matrix, never a separate section.

## [02]-[SCOPES]

Artifacts compose at three scopes, each owning one altitude, linked as relative sibling pages so a reader descends by click and never by re-derivation.

- Repo scope — a roadmap or atlas spanning the monorepo: branch-level outcomes, cross-branch dependencies, promotion conditions. It links each branch page and restates none of its detail.
- Branch scope — one language or platform branch: package sequencing, seam obligations, capability coverage. It links folder pages for mechanism.
- Folder scope — one package or planning folder: stages, acceptance, risks, code-level evidence.

A fact lives at exactly one scope; the scope above carries the link and the consequence, never a copy. A session plan consumed by its own execution stays scratch at any scope.

## [03]-[INVESTIGATE]

Name the decision the page must move; when no decision exists, name the mental model it must change. That sentence governs every later cut.

Inventory before any layout thought:

- Artifact inventory — pull the subject's primary material: repo files, plan sections, dataset fields, decision records, claims, constraints, counterexamples. Audit each as keep, compress, relegate, merge, or discard; existence never earns carriage.
- Question inventory — write the reader's questions in interrogation order: what is the answer, why, what changed, what proves it, what do I do. Record each question's answer form: number, comparison, sequence, mechanism, spatial relation, exception, risk, or command.
- Question class — mark each question skimmer-critical, expert-critical, optional, or archival. Skimmer-critical answers survive in headings, lead assertions, and first-pass visuals; expert-critical answers stay discoverable from the main path; optional material hides behind disclosure or dies; archival material leaves the explanatory flow.

Subject-shaped extraction — the material the inventory reads first:

| [INDEX] | [SUBJECT] | [EXTRACT_FIRST]                                           |
| :-----: | :-------- | :-------------------------------------------------------- |
|  [01]   | repo      | governing docs, entrypoints, tests, call sites, failures  |
|  [02]   | dataset   | schema, units, missingness, cardinality, outliers         |
|  [03]   | decision  | options, constraints, disqualifiers, risks, reversibility |
|  [04]   | plan      | dependency order, owners, acceptance, failure modes       |
|  [05]   | concept   | concrete instance, mechanism, boundary case, ladder       |

Bind evidence to claims: every claim on the page gets one visible evidence object — a table row, chart mark, diagram relation, code span, timeline event, or quote fragment. Hunt negative evidence — excluded cases, failed scenarios, degraded states; negative evidence that changes the answer rides the main path, never a caveat.

Surface the unknowns as regions, never as buried prose: decisions rank by blast radius and tweak likelihood — data model, interface contract, execution model, permissions, persistence semantics precede naming, copy, and polish — and the decisions a reviewer most plausibly flips sit first with their alternative and flip condition beside them, while trusted mechanical work collapses below the decision surface. An assumption the page rests on renders as a named row a reader can strike; an open question carries its decision owner and deadline; a costed option states its implementation consequence, never a bare label. Every captured answer folds back as a constraint on the plan, never as transcript.

Resolve the interactivity conflict before designing: name the one thing a reader misreads if the page stays static, and the one thing a reader skips if the page demands interaction. Those two answers rule the interaction budget.

The comparison phase gates the comparison shape: unnamed candidates get a generative fan-out of genuinely distinct directions, and named candidates get an evaluative scoring surface. Variants pass a distinctness test — each occupies a different tradeoff position, and two variants a reader cannot tell apart are one variant. A scored matrix carries its sensitivity: the smallest weight or score change that flips the winner.

Investigation stops when every surviving content object maps to a reader question and every question has an answer object. The first pass removes content; it never collects more.

## [04]-[SELECT]

Placement is earned on a ladder, and the ladder is the whole selection law:

- Primary placement — losing the object changes the reader's answer, action, or confidence.
- Secondary placement — the object defeats a plausible expert objection.
- Disclosure placement — the object supports verification without slowing first-pass reading.
- Deletion — the object is historical, decorative, duplicative, or reassuring.

Compression moves, each reversible only by evidence: prose compresses to assertions when the evidence carries the explanation; repeated examples compress to small multiples when the comparison axis is stable; derivations compress to staged disclosure when the conclusion works without them; a chart compresses to a sparkline only when local trend suffices and a nearby label carries scale. Units, baselines, denominators, and comparison context never compress away.

Representation swaps by reader task:

| [INDEX] | [TASK]                        | [USE]           | [OVER]        |
| :-----: | :---------------------------- | :-------------- | :------------ |
|  [01]   | lookup, compare, scan records | table           | prose         |
|  [02]   | one causal judgment           | prose           | table         |
|  [03]   | exact values                  | table           | chart         |
|  [04]   | pattern, outlier, trend       | chart           | table         |
|  [05]   | many equivalent cases         | small multiples | one big chart |
|  [06]   | topology, flow, dependency    | diagram         | prose         |
|  [07]   | under three flat relations    | prose           | diagram       |
|  [08]   | quantity, distribution        | chart           | diagram       |
|  [09]   | mechanism, ownership          | diagram         | chart         |
|  [10]   | precise state comparison      | small multiples | animation     |

A metric earns placement only with its target, history, threshold, or denominator beside it. A screenshot earns placement only for spatial evidence text cannot reconstruct. A code excerpt earns placement only when the exact syntax is the evidence; otherwise render behavior or flow. Sourced material synthesizes — the page states what the sources mean together, never serially paraphrases them — and every finding carries its action edge: what the reader does differently for knowing it. The final selection fits one answer path, one evidence path, and one verification path.

## [05]-[STRUCTURE]

Answer-first is the default order: the first viewport carries the answer, its scope, the dominant evidence, and a route to deeper inspection. Model-building order — prerequisites before the answer — is reserved for concept pages where the answer is meaningless until the model exists.

Model before markup: the surviving content shapes an embedded data model — entities, relations, hierarchy, decision states — and every region renders as a projection of it, so structure is decided in the model and the markup merely draws it.

- Section headings make claims or name reader tasks; a heading that names a topic is rewritten.
- The main spine holds five to seven claims; deeper detail rides disclosure or repeated visual grammar.
- Each section introduces exactly one cognitive operation: compare, locate, rank, trace, vary, verify, decide, or apply.
- Detail layers inside a section in fixed order: assertion, evidence object, annotation, optional derivation, source — and source proof sits beside the evidence it validates, never in a detached list.
- Spatial arrangement carries simultaneous, comparative, and dependency relations; linear arrangement carries chronology, procedure, and argument. A persistent visual frame receiving sequential annotations earns a sticky region.

Endings are typed: a concept page ends in a bounded sandbox or transfer task; a decision page ends in action criteria, risk boundary, and evidence trail; an audit page ends in defect classes, ranked fixes, and acceptance checks.

A file tour, member walk, or evidence sequence orders by reading path, never alphabetically. Time renders at the precision the estimate holds — a quarter-grade guess drawn at day granularity lies, and mixed certainty splits into bands rather than sharing one false scale.

Structure fails when the same fact appears twice without serving different tasks, when two sections swap without damaging logic, when the richest evidence lands after the reader was asked to believe, or when the complete story exists only behind every widget.

## [06]-[LAYOUT]

The spine is the vertical claim path that stays coherent with every optional branch ignored; rails and stickiness are earned, never default.

- Prime top-left space carries the highest-value answer or evidence; salience order matches decision importance, and the loudest object on the page is the most important evidence or the layout is wrong.
- Density runs as a gradient: overview first, dense evidence next, verification detail last or disclosed. Sparseness that hides required comparisons is a defect equal to noise.
- Side-by-side wins when the reader compares states, options, or records; stacked wins for sequence, concept building, and long prose. Side-by-side dies when either column starves its labels; stacked dies when comparison forces scroll memory.
- A two-column layout holds stable roles — claim/evidence, before/after, input/output — and never swaps roles between sections silently.
- Controls sit adjacent to the region they mutate; legends sit on the marks or die into direct labels; annotations land at the point of evidence and stay under forty words; callouts mark exceptions and pivots only.
- Repeated sections share one visual grammar so the reader spends cognition on differences, not decoding.
- Responsive collapse preserves argument order and comparison labels; a sticky region that traps scroll or detaches text from its evidence anchor is removed.

The layout passes only when a reader can always name the current section, active filter, active parameter, and reset path without memory.

## [07]-[INTERACTION]

Interaction is a contract: the reader pays attention, effort, and state management, and the page repays insight unavailable statically. The default state answers the most common question with zero interaction, and the page stays a complete argument with every widget ignored.

Write the static alternative first; the interactive form ships only after the static form loses on answer speed, accuracy, or memory load. Interaction pays when it lets the reader test an assumption, manipulate a mechanism, inspect a personally relevant slice, or replace mental simulation with visible simulation.

| [INDEX] | [READER_ASKS]                 | [USE]                       | [FAILS_WHEN]                   |
| :-----: | :---------------------------- | :-------------------------- | :----------------------------- |
|  [01]   | what is the answer            | assertion plus evidence     | answer requires interaction    |
|  [02]   | what changed                  | side-by-side                | states not simultaneously seen |
|  [03]   | which option wins             | sortable table, ranked bars | criteria shift per row         |
|  [04]   | how does it vary              | slider with live render     | thresholds unlabeled           |
|  [05]   | what happens stepwise         | stepper                     | position or count hidden       |
|  [06]   | where am I                    | rail nav, progress          | chrome steals evidence space   |
|  [07]   | which records match           | filter with counts          | active filter invisible        |
|  [08]   | can I find this item          | search                      | empty result dead-ends         |
|  [09]   | why believe this              | local source disclosure     | proof detached from claim      |
|  [10]   | what if my assumption differs | scenario control            | ranges lack provenance         |
|  [11]   | do I understand               | prediction, quiz            | wrong answers teach nothing    |
|  [12]   | what do I do first            | ranked action list          | ranking criteria invisible     |
|  [13]   | what is the mechanism         | manipulable diagram         | moving parts not causal        |
|  [14]   | what is my priority order     | drag ranking                | order feeds no result          |

Every control declares its variable in its label, shows its current state at all times, and exposes reset whenever a noncanonical state is reachable. Hover carries supplement only — hover-only evidence dies on touch and print. A toggle serves two low-memory states; many or precise differences force side-by-side. Motion binds to scroll or slider position so the reader can slow, reverse, and inspect; motion that decorates is removed. A sandbox opens only after the guided model gives exploration meaning, and a control whose states the prose never interprets is deleted.

A control that captures judgment — a verdict, a ranking, an edited value — feeds the export model and, when the return channel is live, the send-to-agent action; a captured state that reaches neither is a toy and is removed. Every control resolves into one of the three classes the type law fixes — load-bearing with its envelope field named, view-only convenience, or forbidden — and the element carrying it is chosen from the generator catalog in [elements.md](elements.md) by the reader question, never by habit.

## [08]-[REVIEW]

Review runs in fixed order — skim, coverage, interaction necessity, density, print — and aesthetics is judged last. Each test is falsifiable; a failed test is repaired before the next runs.

- [SKIM] — Read only title, headings, annotations, and emphasized marks. Pass: the answer, its confidence, and the next action are stateable in thirty seconds. Fail: a topic-shaped title, noun headings, a first viewport without the answer, or a high-salience path that leaves a wrong answer.
- [COVERAGE] — Compare the page against the question inventory. Fail: a skimmer-critical question without a visible answer in the spine, an expert question without a verification path, a section answering no inventoried question, a control answering a question nobody asked, or found negative evidence missing from the structure. A region the author skipped or never inspected says so on the page; silent omission fabricates coverage.
- [INTERACTION_NECESSITY] — For each control, compare against its recorded static alternative. Fail: the static form answers as well with less effort, the default state is uninformative, essential evidence hides behind optional action, or keyboard and print users lose the argument.
- [DENSITY] — Remove every mark that carries no evidence, separation, or priority; removal that costs nothing convicts the mark. Fail: decoration survives, everything is highlighted, values lack units or baselines, or the page is sparse because comparisons were exiled to separate views.
- [PRINT] — Freeze the default state and read it as paper. Pass: answer, evidence, caveats, and verification route all survive; color never carries a category alone; controls print with their selected values readable.

Attack stances that catch what the ordered tests miss: the hostile skimmer writes the answer from the first viewport alone and diffs it against the real answer; the hostile expert jumps straight to the densest evidence and verifies the claim survives exact inspection; the hostile skeptic hunts the missing denominator, stale source, or excluded case; the hostile editor removes each paragraph and keeps every one whose absence unanswers a question; the hostile navigator demands location, active state, and exit without memory; the hostile interaction skipper ignores every widget and requires a complete argument. The named element defects — decorative slider, unkeyed drag state, forced orientation, buried conclusion, circular-for-linear, rainbow taxonomy, unlocked multiples, DOM-sourced export, phantom capture — are hunted by name per [elements.md](elements.md). A defect defended by taste, convention, or implementation difficulty stands unrepaired — the review passes only when every surviving region carries a reader question, an evidence object, an interaction cost, and a falsifiable completion check.
