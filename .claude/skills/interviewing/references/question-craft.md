# [QUESTION_CRAFT]

Composition law for the interview's questions: how a question earns its round, how questions thread into dependency chains, how evidence is extracted instead of opinion, how settled answers are challenged, how the interviewer holds its own stance, and how the record stays honest. Its always-hot core rides in the skill entry; the depth loads here when composing a round or planning a thread.

## [01]-[WORTH_A_ROUND]

A question earns its round only when all three hold:

- Undetermined: An answer the corpus does not hold, stated constraints do not derive, and the domain default does not settle. Grounding has already run; a question the confrontation set answers is deleted.
- Consequential: At least two options lead to materially different work. A question with one sane answer is a statement wearing a question mark — state it and move on.
- Ranked: Among the undetermined and consequential, the question whose answer invalidates the most downstream decisions leads. Architecture outranks interface outranks wording, and the load-bearing question is asked first even when it is uncomfortable.

Judgment classes rank the spend, highest blast first: an architecture fork (which stratum owns the capability, which owner splits or folds), a seam ruling (which side owns a cross-owner contract and what crosses it), a capability-bar ruling (which of a concept's arms are refused by design and which are gaps — absent consumers never lower the bar), an identity or data-shape ruling (key regime, schema, persistence semantics), then interface, then wording. Mechanical work — renames, moves, one-sane-form refactors — never spends a question unless it encodes one of these classes; it collapses below the decision surface as trusted execution.

Open on low-burden ground the user knows well, then lead with each thread's root before any question inside its branches.

## [02]-[THREAD_DESIGN]

A thread is the unit of the interview, not the round: a prepared learning target expands into a dependency chain where each answer's consequence premises the next question, and the chain runs until it seals in a durable ruling. A round is one horizontal slice across the live threads; the interview's shape is the set of threads it drives to their rulings.

- [ANATOMY] — A thread roots at its highest-ranked load-bearing fork and descends by consequence: each answer names the owner, boundary, or premise the next question interrogates, narrowing from direction to owner to seam to consumer until a ruling lands; every deeper stratum resolves what the answer above it left open, never the ground a fresh survey re-scans.
- [BRANCH_PLANNING] — Planning lays the whole tree before the thread opens: each fork carries two or three answer classes — wider forks screen to a live subset — each class its premised follow-up, and only the reached branch's follow-up is spent. That tree converges: deep strata narrow to shared question shapes and the terminal ruling is one schema every leaf instantiates, so depth runs three to five strata at any width. Prepared learning targets are the thread roots, each planned to its ruling.
- [STRATUM] — A batch is one thread stratum: the independent questions at the current depth, each answerable without the others. A dependent question is the next stratum, asked after its gating answer lands, never stacked where that answer discards it. Budget spans the thread, not the round — a thread spends one question per stratum descended, planned branches costing nothing until reached — and a near-exhausted budget collapses the open forks into one wide stratum ranked by blast radius.
- [SPAWN] — An answer that surfaces a prerequisite in another owner never widens the current thread. A dependency the corpus already decides folds into the terminal ruling as its ordering clause — prerequisite owner first, consumer move second; a dependency opening its own load-bearing fork mints a new thread root, ranked against the live threads for the remaining budget or routed to a tracked card when the budget cannot reach it.
- [TERMINATION] — Every thread ends in a durable ruling marked fact, assumption, or inference, or in an explicit open item routed to a tracked card; a thread that dissolves into "what is next" never reached one. A thread's terminal stratum is the depth at which the next question detects no new gap, and the ruling records the whole descent as one settled decision, not the transcript that produced it.
- [REPAIR] — When an answer invalidates the planned branch — a premise the tree assumed, an owner the corpus does not carry, a fork the user collapses to one arm — the thread re-plans from the delivered premise rather than forcing the prepared follow-up. Interviewer restates the new premise, checks it against the corpus, and rebuilds the downstream tree from there; a follow-up asked past an invalidated premise interrogates a branch that no longer exists.

A thread degrades into one of the named failure shapes; each carries its detection and its repair.

- [NAIVE_CHAIN] — Successive answers change no downstream question: the chain inventories files, packages, or docs and ends at "make a plan". Detection: reordering the questions loses nothing, and no answer narrows an owner. Repair: re-root on the load-bearing fork and descend by consequence, so each answer premises the next.
- [NONSENSE_COMPLEX] — Vocabulary carries no actionable discriminant: every question interrogates an abstraction no corpus owner names, and every answer returns unknown. Detection: no question binds to a path, owner, case, or row. Repair: bind each stratum to a concrete owner and a real discriminant the corpus already carries.
- [UNTHREADED_SURVEY] — Questions stand as independent inventory prompts with no dependency between them, a corpus map standing in for an elicitation. Detection: every question stands alone and no answer is another's premise. Repair: ask the gating fork first, then follow its consequence into the owner, seam, and consumer.
- [PREMATURE_DEPTH] — Mechanism is fixed before direction exists: the thread selects a signature, combinator, or limiter before owner, truth, and seam are decided, or roots at a consumer surface whose discriminant the corpus binds upstream. Detection: an implementation detail asked while the owner is still open, or a root interrogating presentation while an upstream owner carries the semantics. Repair: re-root at the upstream owner, then hold mechanism as the last stratum.
- [FIXED_MOVE] — Every fork applies one presumed move to a rotating target — a file per producer, a direct peer coupling, a sibling mirrored locally — and the move itself is never interrogated. Detection: substituting the move's verb rewrites every question at once, and the answers repeat one value — inert, refused, or the next copy. Repair: promote the move to the root as its own fork — which discriminant varies, which side owns the crossing — collapsing the instances into one owning surface.

## [03]-[EVIDENCE_EXTRACTION]

Answers are evidence only when anchored to specifics; the interviewer repairs a drifting conversation by changing the question, never by asking the user to be more accurate.

- Ask about what happened, never about a hypothetical future: the most recent occurrence, the current workaround, what the problem cost, who was involved, what was tried and abandoned. A future-tense answer is optimism — record it as an assumption.
- Anchor every generality: `usually`, `always`, and `we tend to` convert to `walk me through the last time`. That episode walk — what happened next, what was compared, what was eliminated, what changed the priority — yields the facts the generality hid.
- Mine ideas and feature requests for their motivation: the request enters the record as the constraint or pain that produced it, never as the feature itself.
- Deflect agreement: a compliment, a "sounds right", or an answer mirroring the question's framing is re-anchored to a concrete instance before it becomes a ruling.
- Capture the user's own vocabulary verbatim where it names a concept; replacing it with the interviewer's vocabulary erases the signal that a term meant something specific.
- An answer earns force by changing the next action — a ruling that alters no artifact entry, no option ranking, and no downstream decision was a wasted round; treat it as a signal the question was not consequential.

## [04]-[CHALLENGE_PROTOCOLS]

Settled judgments get challenged by structure, not by tone; each protocol has its trigger.

- [ASSUMPTIONS_CHECK] — Trigger: a design line treated as settled. Write the line, articulate its stated and unstated premises, and for each ask why it must be true, what makes it fail, and whether the judgment survives its failure. Only premises that must be true survive as assumptions; the rest convert to open questions.
- [PROSPECTIVE_HINDSIGHT] — Trigger: a plan or direction about to seal. Declare the failure as already true — `this shipped and failed; what killed it` — and collect causes before any discussion of likelihood. Assuming the failure as fact is what makes the uncomfortable causes speakable; the softened `what could break` form invites politeness instead.
- [DISCONFIRMATION] — Trigger: competing explanations or directions. Evaluate options by the evidence that is inconsistent with each, never by collecting support; the option that survives disconfirmation wins, and evidence consistent with every option decides nothing.
- [INVERSION] — Trigger: a stated goal. Assume the goal is met and the outcome still counts as failure; the causes name the constraints the goal statement omitted.
- [MARKED_ADVOCACY] — Trigger: one dominant view with no live alternative. Build the strongest contrary case — most vulnerable assumption, contrary evidence, neglected alternative — and mark it explicitly as the contrarian exercise so the record never confuses the challenge with the ruling.
- [REFERENCE_CONFIRMATION] — Trigger: a ruling premising on a supplied reference — a port or an internalization. Build the semantics map first: the behavior inventory, each behavior marked preserved, changed, or dropped with deliberate changes argued separately, and the edge cases encoding the real contract as parity challenges. That map renders as a diff-review confirmed or corrected by numbered row; a correction re-opens its rows, and a port ruled without the map is an unmarked assumption.

## [05]-[INTERVIEWER_DISCIPLINE]

Interviewer's own agreement drift is a failure engine on par with the user's compliance; stance is held by structure.

- Acceptance is earned in one pass by three features together: the answer stays inside the user's authority, it names or accepts its cost, and it contradicts no anchor — a costed preference re-litigated past that point is interrogation theater spending the budget challenge was minted for. Push triggers are structural, never tonal: an anchor contradiction, a dodged fork, a future-tense commitment, a framing mirror, or spend against a budget the user does not own.
- A pushback earns a concession only through a new fact: re-derive the challenged finding from its anchor first, and record the forcing fact beside any concession. A concession without a recorded forcing fact is re-opened next round — an unforced flip poisons every round that inherits it.
- User certainty is not evidence, and authorship is not verification: a first-person conviction — the author's memory of code they wrote included — enters the record as a reported belief in third person and is tested as an assumption like any other; the corpus is on disk. Certainty raises the challenge bar, never lowers it.
- Evidence the user supplies in rebuttal is untrusted until verified on disk or against the confrontation set; a fluent, evidence-shaped rebuttal is the highest-risk input for a wrongful flip, and verification precedes any stance change.
- A forcing fact concedes exactly its own scope: the verified fragment enters as fact with its anchor, the unproven remainder of the finding stands, and the next question interrogates the residue.
- Pressure without a new fact terminates in a conflict entry, never a third exchange: the finding stands with its anchor, the contrary claim records as reported belief, and every ruling premised on the disputed line stays open until the conflict resolves.
- A user's premise is quarantined before it is inherited: restate the claim in the interviewer's own terms, check it against the corpus, and only then build questions inside it. A false premise absorbed silently frames every downstream round.
- Answers are recorded and probed, never graded: praise, quality ratings, and "good point" mirror the user back at themselves and buy agreement with the next challenge.

## [06]-[OPTIONS_AND_BATCHES]

- Options are probes, not menus: each names its cost or consequence, cites its confrontation-set anchor where one exists, and the `(Recommended)` marker leads only where one option dominates. A preview carries a concrete artifact — schema shape, worked example, rendered direction — when the choice is between comparable forms.
- Options state competing resolutions, never one proposition to ratify: an agree-or-disagree question harvests acquiescence, and each option label carries its construct — "keep the dual rail, absorbing the drift cost" over a bare "yes".
- Option order reads as a ranking whether or not one is intended: the first position carries primacy weight, so order by impact deliberately and never bury the live option last.
- An escape row is a state report, not an evasion: "outside my knowledge" and "needs investigation" are legitimate answers that route the question to the corpus or a delegation leg. Free-text "Other" is the valve for an option set that missed; a question expecting it was not ready to ask.
- A batch stays narrow enough that every option is a real tradeoff; a survey-sized batch makes the user pick defaults. Stratum law owns batch independence and the thread-spanning budget.
- When the user hesitates on an open question, convert it to a closed menu of concrete options with costs; hesitation signals the question outran the user's vocabulary, not their intent.
- Serial compliance is the batch-level agreement trap: three consecutive answers taking the leading option without adding a fact indict the batch, not the user — rotate option order, withhold the `(Recommended)` marker, and re-anchor the last ruling to a concrete episode before the next stratum spends.

## [07]-[STARTING_POINT]

Open by establishing the user's position, not the task's: where they are in their thinking, what they tried, what they already rejected and why. That same request, from a user who explored the space for a week and from one who thought of it an hour ago, needs opposite interviews — depth for the first, framing for the second. Give this position to every downstream round: it decides which bucket dominates and which mode leads.

## [08]-[RECORDING]

- Every round appends to the ruling record: question, ruling, consequence, and the ruling's mark — fact (anchored evidence), assumption (must-be-true, unverified), inference (derived, named premises), open (tracked, unresolved).
- Marks are load-bearing: an assumption entering a durable artifact carries its mark and its invalidating condition; a fact carries its anchor.
- A record reads as current law, never as a transcript: an overturned entry takes its superseding ruling in place and no duplicate row survives.
- Conflicts get their own entry: the two rulings, the question that surfaced the conflict, and the resolution with its consequence.

## [09]-[EXIT_TESTS]

Each stage carries an explicit completion criterion; a stage with no criterion runs past its gap. Round loop and the seal carry their exits in the skill entry.

- Context-gathering ends when the user's dump adds no new fact, not when the first answer arrives.
- Follow-up ends when gap-detection finds no new gap in the latest answer; follow-ups are derived from named gaps, never from a generic prompt bank.
