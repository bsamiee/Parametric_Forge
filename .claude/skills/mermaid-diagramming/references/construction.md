# [CONSTRUCTION]

Each diagram type answers one question with a bounded mark vocabulary; per type, this reference binds what its marks must assert, the signal a strong render concentrates, its master patterns, and the failure modes and logic checks that gate review. Type selection, investigation traces, and staged growth stay methodology's property; the validator owns only its named machine checks.

## [01]-[CORE_TYPES]

[FLOWCHART]:

- Question: what exists and how same-level parts relate under one relation.
- Node: an owner or operation at one abstraction level.
- Edge: the single declared relation, its direction load-bearing.
- Signal: the branch structure and its rejoin points — a strong flowchart lets the reader reconstruct every path without prose, so the discriminators and folds carry the value, never the boxes between them.
- Method:
  1. Fix the relation semantic first.
  2. Place the dominant rail from start to outcome.
  3. Attach branches off discriminators only.
  4. Class nodes by semantic role.
  5. Label every non-obvious edge with the relation verb.
- Master patterns:
  - Declare the dominant rail contiguously first, branches after, so the rail reads as one unbroken line.
  - Converge every fault onto one rail instead of per-stage dead ends; the convergence point states the recovery law once.
  - Fan a discriminator with exhaustive labeled out-edges that re-merge at a single fold — an arm that never rejoins is a leaked exit.
  - Keep annotation traffic on dashed Comment traces so the solid control rail stays the loudest ink on the canvas.
  - Broadcast with `A --> B & C` only for genuinely symmetric fan-out; asymmetric hops get their own labeled edges.
- Failure modes:
  - the god-flowchart absorbing lifecycle, sequence, or schema payloads.
  - control flow drawn beside data flow, both unlabeled.
  - decorative arrowheads on a symmetric relation.
  - branch arms that never rejoin, leaking the merge.
- Logic checks:
  - every path from entry reaches a terminal.
  - each discriminator's out-labels are exhaustive and disjoint.
  - no edge contradicts the subject's declared direction law, a dependency edge pointing one way throughout.

[SEQUENCE]:

- Question: who exchanges what, in what order, to complete one scenario.
- Participant: an autonomous runtime actor — process, service, or thread — never a data object.
- Message: one protocol step its sender can actually initiate.
- Signal: causality and ownership — every request visibly paired with its return, and the activation bars showing exactly who holds the work at every instant.
- Method:
  1. Pick one scenario, happy path plus at most one fault split.
  2. Order participants left-to-right by first touch.
  3. Write messages as verb phrases carrying the payload name.
  4. Add activation only where lifetime matters.
  5. Close on the terminal response or fault.
- Master patterns:
  - Name the frame shape ON the wire in a `Note over` both sides — the contract becomes a visible shared fact, not two private assumptions.
  - Tint the region one participant owns with `rect` — sequence's one styling lever — so ownership reads as surface, never inference.
  - Split aborts from outcomes: `break` for the path that ends the exchange, `alt` for the paths that complete it differently.
  - Run `autonumber` on any exchange another document cites, so a step reference survives edits.
  - Show lifetime with `create`/`destroy` instead of a static roster when the scenario births or kills a participant.
  - Group participants into `box` blocks by process boundary, so the wire crossings stand apart from in-process calls.
- Failure modes:
  - the god-participant sending and receiving everything, hiding decomposition.
  - response arrows omitted, leaving causality unverifiable.
  - `alt` or `par` blocks nesting past two levels, the signal to split the scenario.
  - data objects promoted to participants.
- Logic checks:
  - every request expecting a reply carries its dotted return.
  - no message departs a participant destroyed or never created.
  - the message order is achievable, no reply preceding its request.

[STATE]:

- Question: which modes an entity occupies and which events move it.
- State: a mode the system rests in, observable between events.
- Transition: an event plus optional guard; guards leaving one state stay disjoint.
- Signal: the guard vocabulary — which event moves which mode and what makes every exit deterministic; the states are the given, the guards are the knowledge.
- Method:
  1. Enumerate resting modes first, rejecting any activity.
  2. Fix entry `[*]` and every terminal.
  3. Add one transition per event with its guard.
  4. Nest a composite only where substates share every external transition.
  5. Name transitions by event, never by target state.
- Master patterns:
  - Bound every recovery loop — a fault state exits on `recover [attempts < max]` and `abort [attempts == max]`, so the machine provably terminates.
  - Fan a multi-way guard through a `<<choice>>` pseudostate instead of stacking guards on one source, keeping each edge's condition atomic.
  - Split genuinely independent sub-modes into `--` concurrency regions rather than multiplying the state count combinatorially.
  - Class resting states by criticality — dormant `recessed`, fault `error`, terminal `boundary` — while nominal running states ride the primary default, so lifecycle risk reads at a glance.
  - Give a composite its own `direction` when its interior flow runs against the outer axis.
- Failure modes:
  - an activity drawn as a state, a step mistaken for a mode.
  - overlapping guards making a transition nondeterministic.
  - composite nesting used for visual grouping over shared-transition semantics.
  - a missing terminal, so the lifecycle never ends.
- Logic checks:
  - every non-terminal state holds an exit.
  - an absorbing state is declared terminal or gains an exit.
  - the machine carries its initial `[*]` entry.
  - guards leaving one state are mutually exclusive and cover the event's domain.
  - each composite's substates genuinely share its external transitions.

[CLASS]:

- Question: how declared types relate under inheritance, composition, or dependency.
- Class: a real declared type in the system.
- Relation: a compile-time relationship the source proves.
- Signal: the relation kinds chosen — inheritance versus composition versus dependency is the design decision; members exist only to justify an arrow.
- Method:
  1. Select the type cluster answering the question, never the whole codebase.
  2. Choose which relation kinds appear, two at most.
  3. Carry only members that discriminate the design.
  4. Group by namespace when the ownership boundary is the point.
- Master patterns:
  - Hold the two-relation ceiling; a third relation kind is a second diagram over the same class names.
  - Spend `namespace` as the ownership boundary claim, mirroring the real module or package seam.
  - Attach a lollipop `()--` only to the port a consumer actually binds; decorating every class with interfaces flattens the one seam that matters.
  - Keep generics on the declaration and drop them at every reference — the engine collides two classes differing only by generic suffix.
  - Note the one non-obvious invariant with `note for`; every other comment belongs to the owning page.
- Failure modes:
  - member dumps of every field and method drowning the relations.
  - inheritance and dependency arrows mixed without visual distinction.
  - interface lollipops attached to everything.
  - speculative types with no source anchor.
- Logic checks:
  - every drawn relation verifies in source.
  - no cycle among the inheritance arrows.
  - cardinality appears only where the association is the point.

[ER]:

- Question: what data entities exist, how they identify each other, and what multiplicity constrains them.
- Entity: a persisted noun with identity.
- Relationship: a join path whose cardinality storage enforces.
- Signal: keys and cardinality as enforced constraints — the diagram's worth is exactly the set of joins a reader can trust without opening the DDL.
- Method:
  1. Start from the aggregate root.
  2. Add entities one join away until the question closes.
  3. Mark PK and FK on every drawn entity.
  4. Set cardinality from the constraint storage enforces, never intended usage.
  5. Name relations with the owning verb.
- Master patterns:
  - Resolve every many-to-many through a visible junction entity whose composite PK is both FKs — the crow's foot cannot state it directly.
  - Hold FK-edge reciprocity as one atomic edit: an FK attribute lands with its relationship edge, and either alone is a lie.
  - Spend the identifying `--` versus non-identifying `..` stroke as a real dependency claim, not typography.
  - Class the hierarchy — aggregate root `primary`, junction `recessed`, externally-owned registry `external` — so ownership renders, not just relates.
  - Trim attributes to identifying and discriminating columns; the full column roster is the DDL's property.
- Failure modes:
  - value objects promoted to entities.
  - cardinality drawn from hope — the code admits many, the diagram says one.
  - an FK attribute shown without its relationship edge, or the edge without the FK.
  - attribute dumps past the identifying and discriminating columns.
- Logic checks:
  - every FK attribute has a matching relationship edge and the reverse.
  - every entity carries a PK.
  - cardinality matches the schema constraint.

## [02]-[EXTENDED_TYPES]

[BLOCK]:

- Question: how parts occupy a fixed grid the layout engine must not rearrange.
- Block: one cell or span in a declared column raster, nesting reading as containment.
- Signal: the raster itself — position and span assert the meaning automatic layout destroys.
- Method: sketch the grid on paper first, size `columns` to the widest row, spend `space` to hold alignment, and link only adjacent cells — links route straight through anything between them.
- Failure modes: a manual grid standing in for a flowchart's automatic layout, position earning its cost only where position is the meaning, or spans that break the column arithmetic.
- Logic checks: every row's spans sum within the declared `columns`.

[JOURNEY]:

- Question: how satisfaction moves across the phases one actor set walks.
- Task: one scored step owned by named actors, the score asserting measured or judged sentiment.
- Signal: the sentiment curve across phases — the face row is the finding, the tasks are its evidence.
- Method: phase the actor's real path, three sections or more; score from evidence; name every actor on the tasks it touches so the dot rows expose handoffs.
- Failure modes: scores invented to fill the syntax, or phases that are org-chart stages rather than the actor's path.
- Logic checks: every task carries at least one actor and a defensible 1-5 score.

[ARCHITECTURE]:

- Question: which deployable units run where and reach each other over what path.
- Service: a deployable unit.
- Edge: network reachability over a real port or protocol.
- Signal: the group topology — which unit lives in which zone and which seams cross zone walls.
- Method: group first, place services in flow order, port every edge (`L|R|T|B`) to match the reading direction, then `align row|column` every rank both ways — the aligned grid is what earns orthogonal edges.
- Failure modes: logical components drawn as services.
- Logic checks: every edge traces a real port or protocol path.

[C4]:

- Question: what the system landscape holds at one audience's zoom level.
- Element: a context, container, or component fixed at one level per view.
- Signal: the boundary walls — what sits inside the system under discussion and what talks to it from outside.
- Method: one boundary per ownership domain, externals homed in their own boundary, persons above, every relation labeled with its verb and colored by its kind; a view whose relations cross a loose shape re-homes that shape.
- Failure modes: levels mixed inside one view.
- Logic checks: every element resolves into the next zoom level.

[GANTT]:

- Question: which owned work commits to which dates, and what waits on what.
- Task: owned work with real start and end dates.
- Dependency: an `after` chain onto a prior task.
- Signal: the critical chain — which `after` path bounds the end date, and where the milestone lands on it.
- Method: section by phase, chain tasks with `after` over hand-placed dates, mark state truthfully (`done`/`active`/`crit`), and fit the axis to the span so ticks stay readable.
- Failure modes: dependency-free bars that decorate rather than commit.
- Logic checks: every `after` chain matches a real dependency.

[TREEMAP]:

- Question: how a whole decomposes into parts weighted by one measure.
- Leaf: a part carrying its numeric weight, nesting reading as strict containment under one root.
- Signal: relative area — the two-second read of where the measure concentrates.
- Method: one measure, one unit; branch by the reader's grouping, not the org chart; keep leaves per branch under seven so labels hold their floor.
- Failure modes: weights of mixed units gathered in one tree, or a hierarchy invented to group visually when the data is flat.
- Logic checks: sibling weights share one unit and sum to their parent's meaning.

[TIMELINE]:

- Question: what occurred across successive periods.
- Event: a dated occurrence under its period; adjacency asserts no cause.
- Signal: density and clustering along the axis — when things happened, and how much at once.
- Method: section by era, one period per column, two to four events per period; wording stays parallel so the columns compare.
- Failure modes: causality implied by mere adjacency.
- Logic checks: the period sequence runs strictly chronological.

[MINDMAP]:

- Question: how one root concept decomposes into an owned hierarchy.
- Node: a child owned by exactly one parent, the tree admitting no explicit edge.
- Signal: the first-level partition — the four-to-six branches that claim to exhaust the root.
- Method: name the root as the whole subject, partition once without overlap, then deepen only the branches whose detail answers the question; shape marks level, depth stays within four.
- Failure modes: a needed cross-link, proving the subject a graph rather than a tree.
- Logic checks: every node traces one path back to the root.

[KANBAN]:

- Question: which workflow stage holds which work right now.
- Column: a work queue.
- Card: one task carrying its stage.
- Signal: queue depth — where work piles and where it starves.
- Method: columns are the real workflow gates in flow order; every card carries its ticket and owner so the board stays auditable.
- Failure modes: columns that are statuses rather than queues.
- Logic checks: every card sits in exactly one column.

[TREEVIEW]:

- Question: what a filesystem or containment hierarchy actually holds.
- Entry: one file or directory at its true depth, a trailing slash marking a directory.
- Signal: the annotated entries — the highlight and descriptions carry the argument, the tree is its address system.
- Method: list from disk, prune to the subtree the question touches, describe only load-bearing entries, highlight exactly one.
- Failure modes: a tree drawn from memory rather than disk truth, or annotation icons carrying meaning the text does not.
- Logic checks: the tree matches a listing of the real structure it claims.

[CYNEFIN]:

- Question: which decision domain each item occupies and what movement between domains is claimed.
- Item: one situated practice quoted under exactly one domain, a transition asserting a real reclassification event.
- Signal: the sort itself — which practices the team treats as known versus emergent, and what last moved.
- Method: two or three items per occupied domain, at most two labeled transitions; the tip of a transition lands beside the target caption, so few arrows keep the field readable.
- Failure modes: items placed by mood rather than the domain's definition — clear holds known practice, complicated expert analysis, complex an emergent probe, chaotic act-first — or transitions drawn as decoration.
- Logic checks: every transition names its trigger in the label.

[RAILROAD]:

- Question: which strings a grammar admits, rule by rule.
- Production: one named rule owning its expression, a reference naming another rule.
- Signal: the rail alternatives — what a valid string may do at each junction.
- Method: one production per concern, referenced rules defined below their first use, terminals quoted and nonterminals bare so the two read as different marks.
- Failure modes: a referenced rule never defined, or alternation flattened into prose that hides precedence.
- Logic checks: every referenced nonterminal carries its own production.

[REQUIREMENT]:

- Question: which requirements trace to which satisfying or verifying elements.
- Requirement: a demanded capability node.
- Element: a design or artifact node bound by `satisfies`, `verifies`, or `traces`.
- Signal: the trace matrix as a picture — every requirement's satisfaction and verification visible as edges.
- Method: two to four requirements per view, elements beneath them, every relation labeled by the engine's `<<kind>>` chip; a requirement with no inbound `satisfies` is the finding, shown not hidden.
- Failure modes: a requirement orphaned from any satisfying or verifying element.
- Logic checks: every requirement reaches at least one element via `satisfies` or `verifies`.

[GITGRAPH]:

- Question: how branches diverge, commit, and merge across repository history.
- Commit: one node on a branch.
- Branch: a named line joined by parentage or merge.
- Signal: the merge topology — where lines cut, join, and tag, read like a subway map.
- Method: order branches main-first so ranks stack stably, commit ids name real work, tag on main at release points; history stays truthful to the repository it claims.
- Failure modes:
  - fabricated history matching no real repo state.
  - a branch merged or checked out before it exists.
- Logic checks: every commit id stays unique and every branch predates its checkout.

[QUADRANT]:

- Question: where items place across two independent judgments.
- Point: an item positioned by two coordinates.
- Axis: one independent judgment bounded low to high.
- Signal: cluster and outlier — which items group and which sit alone in a quadrant.
- Method: six to ten points, coordinates from assessment not narrative, class points by category so hue carries the second reading.
- Failure modes:
  - axes that are not independent, collapsing the plane to a line.
  - points placed by narrative rather than measured coordinates.
- Logic checks:  every coordinate falls within its declared axis range.

[PACKET]:

- Question: how bits lay out across a wire-format field contract.
- Field: a named bit range in the packet.
- Signal: field widths at a glance — where the payload budget actually goes.
- Method: transcribe the wire spec exactly, contiguous from bit zero; single-bit flags stay single-bit, and the row width matches the protocol word.
- Failure modes: field ranges that gap or overlap the wire contract.
- Logic checks: field ranges match the wire spec exactly, no gaps or overlaps.

[SWIMLANE]:

- Question: which owner performs which step in one laned process.
- Lane: one owner, a node asserting that owner performs the step.
- Signal: the handoffs — every cross-lane edge is a coordination cost made visible.
- Method: three to five lanes of real actors in flow order, the critical-path lane emphasized, fault returns riding color; a lane with one node merges into its caller.
- Failure modes: lanes for systems that never act, a data store being no owner, or cross-lane edges so dense the partition carries nothing.
- Logic checks: every node sits in the lane of the owner that performs it.

[EVENTMODELING]:

- Question: which commands produce which events and which projections consume them, in timeline order.
- Frame: one numbered timeframe holding a ui, command, event, processor, or read-model fact; frame order is the asserted causality.
- Signal: the lane rhythm — commands descending into events, read models rising from them, left to right.
- Method: frames in strict causal order (relations infer from the nearest prior frame in another lane), payloads annotated where the shape is the contract, one stream per namespace.
- Failure modes: a command and its event out of frame order, a read model fed by no upstream event, or frames spent as free-form boxes outside the five kinds.
- Logic checks: frame numbers strictly increase within each timeline run, and every read model traces to an upstream event frame.

[VENN]:

- Question: how much the declared sets genuinely overlap under one measure.
- Set: a weighted membership region; a union row asserts a measured overlap, never a drawn guess.
- Signal: the labeled regions — each union caption names what the overlap IS, not just that it exists.
- Method: three sets at most, every meaningful union sized and labeled, set labels inside their exclusive regions.
- Failure modes: overlap sizes invented to render nicely, or a union larger than its smallest member.
- Logic checks: every union size is at most the smallest member set's size.

[WARDLEY]:

- Question: where each capability sits on visibility and evolution, and what depends on what.
- Component: a capability at assessed `[visibility, evolution]` coordinates; the anchor is the user need every chain serves.
- Signal: the slope — visible custom capability up-left, invisible commodity down-right, and the evolve arrows naming the strategy.
- Method: chain from the user need down through six to nine components, one `evolve` per claimed movement, labels clear of the stage boundaries.
- Failure modes: coordinates placed by narrative rather than assessed evolution, or a component chain reaching no anchor.
- Logic checks: every component reaches an anchor through the dependency links, and every coordinate stays inside the unit square.

[ISHIKAWA]:

- Question: which cause categories plausibly produce one named effect.
- Cause: one contributing condition under exactly one category; the head names the effect, never a category.
- Signal: depth under a category — a deep branch is the diagnosis, a flat one a suspicion.
- Method: three or four categories, causes deepened into sub-causes where evidence exists; growth deepens branches rather than adding categories.
- Failure modes: categories that are org names rather than causal families, or a remedy listed where a condition belongs.
- Logic checks: every cause states a condition, and each sits under exactly one category.
