# [ROUND_AND_THREAD_CRAFT]

A round's question batch is the interview's payload, and a thread is the sequence of rounds where each answer's consequence becomes the next question's premise; a batch that asks the abstract, courts agreement, surveys defaults, ratifies a scope cut, or hides a contradiction ships a confident wrong spec, and a thread whose links are descriptive, grandiose, independent, mechanism-first, or one-endpoint burns the budget without landing a ruling. Each entry names one defect — a single round's batch or a cross-round thread — under the fixed Detection / Rejected / Accepted / Reason / Reframe card. The Rejected and Accepted bodies are real batches or real worked threads, never descriptions of them; a thread entry's bodies run numbered strata with answer branches and the premise link that ties each answer to the next stem, terminating in a marked ruling.

## [01]-[UNGROUNDED_ABSTRACTION]

A question asks the user to imagine a design in the air when the corpus already holds the surface the question is about.

- Detection: A round opens with an abstraction — a shape, a policy, a tradeoff — and cites no anchor, so the user answers from imagination instead of reacting to what exists.
- Rejected:
    ```markdown rejected
    1. How should the graph carrier handle multiple backends?
        - a) One unified type
        - b) A separate type per backend
    ```
- Accepted:
    ```markdown accepted
    1. `<unit>/planning/graph.md:55` types the carrier as `AnyGraph = "RxGraph | NxGraph | igraph.Graph"` — a string union no type-checker resolves, and the third arm is GPL. Which backend is the canonical owner the other two fold into?
        - a) `RxGraph` canonical, the rest as boundary adapters — drops the GPL surface from the core rail; costs the `igraph`-only algorithms until re-homed.
        - b) A real tagged union over all three — keeps every algorithm; costs a GPL-confined build lane and a resolvable tag per backend.
    ```
- Reason: The anchor turns imagination into reaction — the user confronts a named surface, a real weakness, a real string, and the answer carries a fact instead of a preference.
- Reframe: Run the corpus check first, embed the path and the observed fact in the question stem, and delete any question the confrontation set already answers.

## [02]-[APPROVAL_SEEKING]

A question invites the user to ratify the interviewer's framing instead of surfacing evidence, so agreement arrives wearing the mask of a ruling.

- Detection: A question a satisfied user answers "yes" to without adding a fact — a tag question, a "does that sound right", a mirror of the interviewer's own preference.
- Rejected:
    ```markdown rejected
    1. The content-keyed scheduler looks like the right call, doesn't it?
    2. You're comfortable leaving impact search deferred, right?
    ```
- Accepted:
    ```markdown accepted
    1. Walk me through the last time a consumer needed the scheduler: what did it request, what did the current design force it to do instead, and what did that cost?
    2. When a caller last reached for impact search, what happened — did the deferred owner serve it, or did the caller route around the gap?
    ```
- Reason: A mirrored question harvests compliance; the episode walk harvests what happened, and the fact the past supplies outranks the assent the framing invites.
- Reframe: Convert every ratification into an occurrence — the most recent time, the current workaround, what it cost — and re-anchor any agreement to a concrete instance before it becomes a ruling.

## [03]-[HYPOTHETICAL_FUTURE]

A question asks how the user hopes to handle an event that has not happened, harvesting optimism where the past holds a fact.

- Detection: A future-tense stem — "if X arrived", "how would you want" — that records aspiration, not evidence, and enters the record as a fact ruling.
- Rejected:
    ```markdown rejected
    1. If a new component family arrived that didn't fit the closed ten, how would you want to handle it?
    ```
- Accepted:
    ```markdown accepted
    1. `<unit>/architecture.md:79` closes `ComponentFamily` at ten. When did a family last press a slot the set refused — what was it, and what did the closed count force?
        - a) No family ever pressed the boundary — the closed count records as fact with its reopen condition.
        - b) A family was dropped or forced to fit — the count is a gap, not a design; name the missing slot.
    ```
- Reason: Past specifics outrank hypotheticals — the last occurrence yields what was tried, compared, and abandoned, where the future-tense answer yields only what the user hopes.
- Reframe: Anchor every generality to its most recent occurrence; when no answer exists, record the resulting ruling as an assumption carrying its invalidating condition, never as a fact.

## [04]-[STATEMENT_AS_QUESTION]

A question carries one sane answer, spending a round to extract a foregone conclusion instead of a real fork.

- Detection: A stem whose options do not lead to materially different work — strict typing over `Any`, a working seam over a broken one — where one branch is house law.
- Rejected:
    ```markdown rejected
    1. Should the design use strict typing instead of `Any`?
    2. Do we want to avoid shipping a broken seam?
    ```
- Accepted:

    ```markdown accepted
    [CONSTRAINT] Strict typing over `Any` is house law — recorded, not asked.

    1. The strict-typing law forces the carrier off the string union. Two typings survive it: a `Protocol` over the three backends, or a tagged union with a resolver. Which?
        - a) `Protocol` — structural, no tag; costs the backend-specific algorithms that need the concrete type.
        - b) Tagged union — explicit dispatch; costs a resolver per operation.
    ```

- Reason: A question with one sane answer is a statement wearing a question mark; recording it as a constraint frees the round to ask the fork the foregone conclusion opens.
- Reframe: State the settled branch as a constraint in the record, then spend the round on the real tradeoff the constraint exposes — two options changing the work differently.

## [05]-[SURVEY_BATCH]

A batch grows past the point where every option is a real tradeoff, so the user picks defaults down a checklist instead of ruling.

- Detection: A round with more than a handful of questions, each a menu of parameters the domain default already settles, forcing the user to rubber-stamp.
- Rejected:
    ```markdown rejected
    1. What log format? a) JSON b) logfmt c) plain
    2. What retention window? a) 7d b) 30d c) 90d
    3. What serializer? a) msgspec b) orjson c) stdlib
    4. What test runner? a) built-in b) external
    5. What lint profile? a) strict b) default
    6. What cache backend? a) memory b) disk
    7. What CI trigger? a) push b) tag
    8. What doc format? a) markdown b) rst
    ```
- Accepted:
    ```markdown accepted
    1. The acquisition surface carries three entrypoints — `read`, `survey`, `acquire` — over one stated aspect. Collapse to one polymorphic entry discriminating on input shape, or keep three named arms?
        - a) One entry — object-store inventory and presign become input shapes; costs a wider input discriminant.
        - b) Three arms — each name self-documents; costs the entry proliferation the collapse law forbids.
    ```
- Reason: A survey-sized batch makes the user pick defaults and buries the one load-bearing question in noise; a narrow batch keeps every option a real tradeoff the user must rule on.
- Reframe: Default every nonessential gap and name the default in the record; keep the batch narrow enough that each option changes the work, and rank the survivors by the decisions their answers invalidate.

## [06]-[MENU_NOT_PROBE]

Options list forms without their costs, so the user chooses by preference instead of by consequence.

- Detection: A question whose options are bare labels — no cost, no consequence, no anchor — reducing the choice to taste.
- Rejected:
    ```markdown rejected
    1. How should the viewer load geometry?
        - a) wasm decoder
        - b) server-side tessellation
        - c) native codec
    ```
- Accepted:
    ```markdown accepted
    1. `<unit>/architecture.md:54` marks the viewer codec-absent until an upstream wasm decoder identity is admitted. Which decode owner does the viewer bind?
        - a) Upstream wasm decoder — keeps the viewer thin; costs a hard dependency on an unadmitted serving row that blocks render until it lands.
        - b) Server-side tessellation to a mesh wire — unblocks render now; costs a round-trip per view and a server the viewer did not need.
        - c) Needs investigation — routes the decoder-availability question to a corpus leg before this binds; costs one round.
    ```
- Reason: Options are probes, not menus — each names its cost and cites its anchor, so the answer reveals which consequence the user accepts, and the `(Recommended)` marker leads only where one option dominates.
- Reframe: Attach a cost or foreclosure to every option, cite the confrontation-set anchor where one exists, and let free-text remain the escape valve, never the plan.

## [07]-[DEPENDENT_CASCADE]

A batch stacks questions whose later members are meaningless until the first answers, wasting every dependent the gating answer invalidates.

- Detection: Questions 2 through N presuppose a specific answer to question 1, so a different answer to 1 discards the rest of the batch.
- Rejected:
    ```markdown rejected
    1. Should the graph carrier be a single owner or split per backend?
    2. For the split, what are the three backend type names?
    3. For those types, which shares the traversal API?
    4. Given that API, where does the GPL backend get isolated?
    ```
- Accepted:
    ```markdown accepted
    1. The carrier owns three backends behind a string union. One decision gates the rest: is the carrier one polymorphic owner, or one owner per backend?
        - a) One owner — the backend becomes a policy value; the next round designs the discriminant and the GPL confinement.
        - b) Per backend — each is its own surface; the next round designs the shared traversal contract.
    ```
- Reason: A cascade of dependents signals the round runs one question deep; batching them spends four slots to learn one answer and re-asks three of them whichever way the gate falls.
- Reframe: Ask the gating question alone, hold its dependents for the next round, and batch only questions that stand independent of each other's answers.

## [08]-[SILENT_RECONCILIATION]

Two rulings collide and the interviewer picks one quietly, burying the conflict the user alone owns the authority to resolve.

- Detection: A round records a ruling that contradicts an earlier one — or an index claim its own pages deny — without ever surfacing the collision as a question.
- Rejected:
    ```markdown rejected
    1. Since the README already calls impact a standing domain owner, I'll record impact search as in-scope and move on.
    ```
- Accepted:
    ```markdown accepted
    1. Two rulings collide: `<unit>/README.md:3` presents impact as a standing domain owner, while `<unit>/planning/impact.md:15` gates impact search and wide sweeps behind an unnamed future consumer. Both cannot hold. Which is law?
        - a) Owner is law — pull search and sweeps into current scope; costs the build now, closes the claim-to-carriage gap.
        - b) Deferral is law — demote the README claim to "impact interchange owner"; costs the broad promise, keeps scope honest.
    ```
- Reason: A silently reconciled conflict hard-codes the interviewer's guess as the user's ruling; surfacing it with each resolution's consequence hands the authority back where it belongs.
- Reframe: Give every contradiction its own question — the two rulings, the surfacing observation, and the consequence of each resolution — and record the outcome as a conflict entry, never as a quiet overwrite.

## [09]-[NAIVE_CHAIN]

A thread chains descriptive facts — biggest, longest, most-used — so each answer ranks nothing and premises no next question; the sequence walks visible inventory instead of the pressure the capability moves.

- Detection: Every stratum's answer is a description that changes no subsequent stem; the thread stops after any link and has learned the same nothing, because size and visibility stand in for ownership pressure.
- Rejected:
    ```text
    1. Which planning page is the longest?
       → the graph page.
    2. Which page names the most backends?
       → the graph page — three.
    3. Which of those three is used most?
       → the first one.
    4. Which page gets edited first?
       → the graph page.
    (no ruling: four descriptions, no decision)
    ```
- Accepted:
    ```text
    1. Which invariant breaks if the new capability lands? [root — decides the whole line]
       - a) identity — a content key changes → 2i
       - b) semantics — a domain vocabulary changes → 2s
       - c) operational — a lifecycle or port changes → 2o
    2i. (premise: identity is the invariant) Does the pressure change the key primitive itself, or only add a consumer of the existing key?
       - a) adds a consumer → 3
       - b) changes the primitive → escalate to the kernel owner; re-run 1 against the wider blast
    3. (premise: an existing key, a new consumer) Which existing owner absorbs the consumer as a seam row rather than a second key scheme?
       - a) the byte-owning page absorbs it → terminal
       - b) no owner fits → the consumer names a missing seam; record open
    Terminal: fact — the campaign edits the invariant owner named at 2i and records every downstream as a seam, never a parallel key. [open if 3b]
    ```
- Reason: A descriptive chain mistakes inventory for pressure — size and visibility rank nothing and premise nothing, so four rounds yield four facts and no decision; a worked thread opens on the invariant the capability moves and lets each answer become the next stem's premise, so the same four rounds converge on one owner.
- Reframe: Open every thread on the root — the load-bearing fork that decides whether the line exists at all — make each stratum's stem consume the prior answer verbatim, and delete any link whose answer changes no subsequent question.

## [10]-[NONSENSE_COMPLEXITY]

A thread dresses its strata in pseudo-profound abstraction — self-synchronizing ontologies, emergent schemas — that no owner, row, or fence can answer, mistaking grandiosity for depth.

- Detection: Each stem reaches for a grand abstraction whose answer names no file, no case, no seam; every answer is unfalsifiable, so the thread cannot terminate in a ruling because nothing it asks is decidable against the corpus.
- Rejected:
    ```text
    1. How should the domain ontology self-synchronize across the computational planes?
    2. Which schema dialect maximizes semantic density?
    3. Which emergent structure best resonates with the runtime?
    (no ruling: no stratum names a surface to edit)
    ```
- Accepted:
    ```text
    1. Which concrete owner carries the concept? [root — the corpus already holds it]
       - a) the graph owner → 2g
       - b) the semantic-projection owner → 2s
       - c) the durable-ledger owner → 2d
    2g. (premise: the graph owner) Is the change a node case, a relationship, a property or quantity row, or a constraint?
       - a) a node case → 3
       - b) a property row → 3'
    3. (premise: a new node case) Which existing relationship and property bags cover the case without a second graph model?
       - a) the existing bags cover it → terminal
       - b) none fit → the case needs a new relationship kind; name it, then terminal
    Terminal: fact — name the owner file, the exact row or case that changes, and the single seam consumer; the abstraction dissolves into one concrete edit.
    ```
- Reason: Grandiosity is not depth — a stem no owner can answer spends a round on a feeling and lands nothing, while the corpus already holds enough real complexity (nodes, projections, rows, receipts) that every stratum can name the surface it moves.
- Reframe: Root every abstraction thread on "which concrete owner carries this", and reject any stratum whose answer cannot name a file, a row, or a fence.

## [11]-[UNTHREADED_SURVEY]

A thread stretches independent inventory prompts across rounds, so no answer becomes the next round's premise; it is a survey wearing a thread's length.

- Detection: Round N's stem does not consume round N-1's answer — reorder the rounds and nothing breaks. The batch defect over-fills one round with independent options; this over-lengthens a whole thread with the same independence, producing a corpus map instead of an elicitation thread.
- Rejected:
    ```text
    1. Which packages exist in the branch?
    2. Which external dependencies are admitted?
    3. Which seams cross the strata?
    4. Which future apps will consume it?
    (reorder these four freely: nothing changes)
    ```
- Accepted:
    ```text
    1. Does the capability cross a stratum boundary? [root]
       - a) no, inside one package → 2n
       - b) yes, across domain peers → 2p
       - c) yes, across runtimes → 2r
    2p. (premise: it crosses domain peers) Does the fact cross as graph content, a content-keyed artifact, or a receipt?
       - a) graph content → 3
       - b) a receipt → 3'
    3. (premise: it crosses as graph content) Which side authors the content and which side only decodes it?
       - a) the graph owner authors, the peer decodes → terminal
       - b) both claim authorship → surface the conflict as its own question before terminal
    Terminal: fact — the campaign lands at the authoring owner and records only the seam at every decoder; no peer owns a second copy.
    ```
- Reason: A survey's rounds are commutative — reorder them and nothing changes, proof no answer premised the next; a thread's rounds form a chain where round one's fork chooses which round two even exists.
- Reframe: Before each round, name the prior answer it consumes; a round that consumes none is a survey item — default it or drop it — and reserve the thread for the one fork that gates the rest.

## [12]-[PREMATURE_DEPTH]

A thread opens on mechanism — which attribute, which overload, which fence — before direction is fixed, so the mechanism answer is void the moment the owner and truth source land elsewhere.

- Detection: The first strata ask how while which owner and what truth remain unruled; the sequence skips ownership, stratum, truth source, and seam type, and every mechanism answer is discarded if a later round routes the capability to a different owner.
- Rejected:
    ```text
    1. Which source-generator attribute tags the new type?
    2. Which dispatch overload is fastest?
    3. Which fence signature is shortest?
    (all three void once direction routes the capability elsewhere)
    ```
- Accepted:
    ```text
    1. What truth source changes? [root — direction before mechanism]
       - a) graph truth → 2g
       - b) semantic truth → 2s
       - c) runtime truth → 2r
    2g. (premise: graph truth) Which owner owns canonical admission and mutation of that truth?
       - a) the graph owner → 3
       - b) an unclear owner → resolve ownership before any shape question
    3. (premise: the graph owner) Which generated shape expresses it — value object, smart enum, union, port, or policy row?
       - a) a union case → 4
    4. (premise: a union case on the graph owner) Only now: which generator attribute and dispatch form realize it?
    Terminal: inference — mechanism is ruled last, derived from the truth, owner, and shape the earlier strata fixed; a mechanism chosen before them is rework waiting to happen.
    ```
- Reason: Mechanism has no meaning until the owner and truth source are fixed — a fence chosen before the owner is known is discarded the instant direction lands; the thread earns its mechanism stratum only after truth, owner, and shape are ruled.
- Reframe: Order every thread truth → owner → shape → mechanism; a stem naming an attribute, overload, or signature before the owner is fixed waits for the stratum that fixes it.

## [13]-[ABANDONED_BRANCH]

A gating answer invalidates the pre-planned branch, and the thread pushes the dead branch's rounds forward anyway — or trails off with no terminal ruling — spending the budget on a foreclosed world.

- Detection: The thread pre-planned rounds 2 through N assuming answer (a) to the gating fork; the user answers (b), and the thread asks the (a)-branch rounds regardless, then stops without recording the ruling the fork existed to land.
- Rejected:
    ```text
    1. Is the carrier one owner or one per backend?
       → per backend. [kills the single-owner branch]
    2. For the single owner, which tag discriminates? [dead — presupposes the killed branch]
    3. For that tag, which resolver caches it? [dead]
    (thread stops: no ruling recorded)
    ```
- Accepted:
    ```text
    1. Is the carrier one owner or one per backend? [gating fork — both branches pre-planned]
       - a) one owner → plan A: 2a designs the discriminant, 3a the GPL confinement
       - b) per backend → plan B: 2b designs the shared traversal contract
       → user answers (b): discard plan A, enter plan B at 2b
    2b. (premise: per-backend owners) Which contract does every backend implement so consumers stay backend-agnostic?
       - a) a traversal protocol → 3b
       - b) no shared contract needed → the split is genuine; go to terminal
    3b. (premise: a shared traversal protocol) Which backend's algorithm set forces a member the others cannot honor?
       - a) none → the protocol is total → terminal
       - b) the GPL backend → confine it behind the protocol's optional arm → terminal
    Terminal: fact — per-backend owners behind one traversal protocol, the GPL backend confined to its optional arm; recorded as the ruling the fork opened, not left dangling.
    ```
- Reason: A gating fork plans both branches before it is asked; when the answer kills one, the thread abandons that branch's rounds and enters the other's — pushing the dead rounds spends the budget on a foreclosed world and, worse, lets the thread trail off without the ruling the fork existed to land.
- Reframe: Plan both branches of every gating fork; on the answer, discard the dead branch's strata and re-enter at the live branch's first stratum; a thread seals only on a terminal ruling, never on a trailing question.

## [14]-[BAR_LOWERED_BY_ABSENCE]

A question frames a scope cut as the default because no consumer exists yet, so the round ratifies a thin owner the capability bar forbids instead of forcing the refused-versus-gap ruling.

- Detection: A stem framing missing demand as license to build less — the options are cut-now against keep-just-in-case — and the concept's full arm census was never taken, so neither option names what the owner actually omits.
- Rejected:
    ```markdown rejected
    1. No consumer reads the assessment sweep yet — cut the owner to the two fields the report uses?
        - a) Cut to two fields — smaller surface, ship sooner.
        - b) Keep everything — just in case a consumer arrives.
    ```
- Accepted:
    ```markdown accepted
    1. `<unit>/planning/assessment.md:31` models the assessment owner with four of the twelve attributes the concept carries — `method`, `stage`, `factor-set`, and `system-boundary` among the absent. Which missing arms are refused by design, and which are gaps the owner absorbs now?
        - a) Refused — each refusal recorded as owned law naming the surface that holds it instead; costs the refusal audit, keeps a four-arm owner honest.
        - b) Gaps — the owner extends to the concept's space now; costs the wider model, prevents the tacked-on retrofit when the first consumer lands.
        - c) Split — some arms refused with their owning surface named, the rest absorbed; costs ruling arm by arm, and the record carries one line per arm.
    ```
- Reason: Absent consumers never lower the capability bar — missing demand is not evidence the domain lacks the arm; the cut-now framing converts an unexamined census into a scope ruling, and the retrofit it invites lands as tacked-on flat code instead of a rebuilt owner.
- Reframe: Take the concept's arm census before the question, confront the user with the carried-versus-full count and the named absentees, and force every missing arm into refused-by-design with its owning surface or gap-absorbed-now — never into a build-less ratification.

## [15]-[ONE_SIDED_SEAM]

A thread rules a cross-owner seam by interrogating one endpoint, so the ruling binds obligations onto a party the thread never questioned and the mirror declaration surfaces later as drift.

- Detection: Every stratum's stem names the producing surface; no stratum opens the consuming endpoint or its mirror declaration, and the terminal ruling assigns decode, versioning, or alignment obligations to the silent side.
- Rejected:
    ```text
    1. Which shape does the producer emit on the wire?
       → the receipt envelope.
    2. Which envelope fields does the producer version?
       → all of them.
    3. When does the producer publish a schema change?
       → on every release.
    (ruling binds the consumer's decode and migration obligations; the consumer's endpoint was never opened)
    ```
- Accepted:
    ```text
    1. Which side owns the seam contract — the producer minting the shape, or a shared vocabulary both endpoints decode? [root — assigns the authority every later ruling cites]
       - a) producer-owned → 2p
       - b) shared vocabulary → 2v
    2p. (premise: producer-owned) What does the consumer's endpoint record today — the mirrored declaration, a local re-decode, or nothing?
       - a) mirrored declaration, same shape → 3
       - b) local re-decode or absent mirror → the one-sided seam is its own finding with both anchors, then 3
    3. (premise: authority fixed, mirror state known) Which drift gate proves the endpoints stay aligned, and whose change breaks loudly first?
       - a) a shared fixture keys both ends → terminal
       - b) no gate exists → the ruling records the gate as its confirmation condition → terminal
    Terminal: fact — contract owner, mirror obligation, and drift gate land as one ruling naming both endpoints; an obligation on a party the thread never questioned re-routes through that party's endpoint before the seal.
    ```
- Reason: A seam is a two-sided fact — a contract declared on one side only is the drift the interview exists to prevent, and a ruling that assigns the silent side's obligations hard-codes the interviewer's guess about an endpoint nobody opened.
- Reframe: Open every seam thread on contract authority, give each endpoint its own stratum, verify the mirror declaration on disk before the ruling, and let the terminal ruling name both endpoints and the gate that keeps them aligned.
