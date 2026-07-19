---
name: interviewing
description: >-
    Adversarial elicitation that converts unknowns into durable decision artifacts: corpus-grounded
    interviews whose questions confront the user with what exists, blindspot passes along a named
    interrogation-axis catalog, direction brainstorms and wargames, pre-merge comprehension quizzes,
    buy-in packets, mid-build deviation capture, and vocabulary teaching — each terminating in a
    typed html-studio deliverable (decision record, direction set, roadmap brief, blindspot ledger,
    capability entry). Owns question threading, the push-versus-accept ruling, the axis catalog,
    kind contracts, and the durable-versus-ephemeral ruling.
    Use when requirements are ambiguous or live in the user's head, before authoring a brief,
    spec, roadmap, or direction document, when a conversation must land a durable decision or
    roadmap artifact, when a mid-build discovery strikes the plan, or when the user says
    "interview me", "find my blindspots", "what am I missing", "wargame this", "brainstorm this",
    "quiz me", or "teach me the domain".
---

# [INTERVIEWING]

An interview converts the gap between the request and the territory into visible rulings before work seals: the questions confront the user with what exists, every answer is challenged before it becomes a ruling, and every ruling lands in a typed deliverable at its ruled altitude. A stenographer that collects answers without grounding or challenge ships a confident wrong spec.

## [01]-[ROUTING]

[REFERENCES]:
- [01]-[AXES](references/axes.md): each axis with its probe method, question shape, and confirming evidence; loaded before any grounding pass.
- [02]-[MODES](references/modes.md): stages every mode procedure with its per-stage exit tests; loaded when a mode begins.
- [03]-[QUESTION_CRAFT](references/question-craft.md): thread design, evidence extraction, challenge protocols, option and batch mechanics

[EXAMPLES]:
- [01]-[ARTIFACTS](examples/artifacts.md): worked accepted and rejected kind instances.
- [02]-[BATCHES](examples/batches.md): worked question batches and threads.
- [03]-[THREAD](examples/thread.md): one complete descent — request, re-frame, thread plan, strata, record, landing.

## [02]-[OPERATING_LOOP]

Elicitation is a hard gate before any brief, spec, roadmap, or direction document: a change that looks too simple to design still passes intent, constraints, options, and validation. Sequenced moves compose the loop; each carries its exit test.

- [GROUND]: Read corpus, references, and constraints along the axes before round one; exit when every touched axis holds a verified anchor or a clean.
- [FRAME]: Classify unknowns into buckets, each routed to its technique; exit when every unknown has a bucket and no bucket with signal is uncovered.
- [INTERROGATE]: Descend each thread, stratum premising stratum; exit when every thread seals in a ruling or open item; a two-round stall seals open.
- [RULE]: Mark each answer fact, assumption, inference, or open; exit when none is unclassified and each conflict resolves or holds, binding neither.
- [LAND]: Rule durability and kind by altitude, then instantiate its contract; exit when fold-back, render, and home stand under a clean cold read.

Pacing is bounded on both ends: one load-bearing question at a time when answers cascade, independent questions batched, roughly ten questions per session with nonessential gaps defaulted and named as defaults in the record. A scope whose threads outrun the session budget partitions by blast radius — the highest-ranked threads run now, the remainder route to tracked cards that seed the next session's frame; a marathon session dilutes every ruling it lands.

## [03]-[GROUNDING]

Questions confront the user with what is, never with an abstraction the user must imagine.

- A corpus check precedes every round: a question the corpus, the stated constraints, or a domain default already answers is a wasted round.
- Grounding produces the confrontation set: each entry carries its exact anchor (path and line), the observed fact, and its axis token.
- A question earns force by embedding its anchor — the user reacts to a named surface, a real weakness, a real structure.
- A corpus beyond one session's reading budget partitions into read-only investigation legs, each assigned axes and returning anchored facts.
- Those legs fold into the confrontation set before round one.
- An unverified candidate finding never enters a question; the anchor is re-opened on disk first.
- A corpus that contradicts itself is grounding signal, not noise: the divergence enters the confrontation set as one two-anchor row.
- That divergence surfaces as a conflict question carrying both resolutions' consequences, never resolved by silently siding with either anchor.

`axes.md` carries the axis catalog — each axis with its probe method, question shape, and confirming evidence — loaded before any grounding pass.

## [04]-[UNKNOWNS_ROUTING]

Every request decomposes into knowledge buckets; the bucket selects the technique. Blindspot and brainstorm run before interview rounds where their buckets carry signal — the interview covers the residuals they leave.

| [INDEX] | [BUCKET]         | [SIGNAL]                         | [TECHNIQUE]                    |
| :-----: | :--------------- | :------------------------------- | :----------------------------- |
|  [01]   | known knowns     | stated in the request            | recorded as constraints        |
|  [02]   | known unknowns   | the user names the open question | interview rounds               |
|  [03]   | unknown knowns   | recognizable only when seen      | direction fanout and prototype |
|  [04]   | unknown unknowns | unfamiliar territory or corpus   | blindspot pass along the axes  |

Two degenerate signals re-route before any decision question: a user who cannot describe the target supplies a reference — source code outranks any screenshot or description of it, and a ruling premising on the reference passes the reference-confirmation protocol before it seals; a user who cannot evaluate options enters teach-me — fanning variations at someone who cannot judge them wastes the fan.

A grounding pass that indicts the request's own framing — the FRAMING axis returning a pain the stated ask leaves standing — re-frames before any thread plans: the extracted goal replaces the stated ask as the interview's subject, and the original ask enters the record as one candidate resolution among its rivals.

## [05]-[MODES]

Every mode obeys the operating loop and differs in what it extracts and lands; staged procedures with per-stage exit tests are `modes.md`, loaded when a mode begins.

| [INDEX] | [MODE]           | [TRIGGER]                          | [DEFAULT_LANDING]     |
| :-----: | :--------------- | :--------------------------------- | :-------------------- |
|  [01]   | `interview`      | requirements ambiguous or unstated | `decision-record` set |
|  [02]   | `blindspot-pass` | unfamiliar ground or pre-seal      | `blindspot-ledger`    |
|  [03]   | `brainstorm`     | direction uncommitted              | `direction-set`       |
|  [04]   | `quiz`           | comprehension unproven pre-merge   | scored gate           |
|  [05]   | `buy-in`         | acceptance needed outside the loop | packet                |
|  [06]   | `teach-me`       | user cannot evaluate or phrase     | vocabulary map        |
|  [07]   | `notes`          | mid-build discovery strikes a plan | deviation ledger      |

Each row's landing column is the default; the altitude law owns kind selection. Roadmap-altitude rulings compose a `roadmap-brief` from any mode, and a finding stating a standing capability fact lands as a `capability-entry` row from any pass. A trigger word never overrides the entry test: a mode invoked while its entry condition fails re-routes to the mode whose condition holds — a wargame call with no direction fan enters `brainstorm` to generate one, a quiz call on unsealed work returns to the build, a brainstorm call against a committed direction interrogates the commitment as an `interview` thread instead of refanning it.

## [06]-[QUESTION_LAW]

Question law is the always-hot core; composition depth — thread design, evidence extraction, challenge protocols, option and batch mechanics — is `question-craft.md`, loaded when composing any round.

- Rounds are strata of a planned thread, never a survey: a thread opens on its root, the load-bearing fork gating whether the thread exists.
- That root also routes the thread's branch, and each ruling's consequence premises the next stratum's question.
- Descent terminates in a durable ruling naming the owner surface that changes.
- A round whose answers premise no next question inventoried the corpus instead of interrogating it.
- Mechanism is the thread's floor, never its head: owner, truth source, and seam type are fixed by the upper strata.
- Only then may a question reach signature, dispatch form, or member choice.
- A question earns its stratum only when undetermined, consequential, and ranked.
- Undetermined means unanswerable from the corpus; consequential means two or more options that change the work differently.
- A ranked question is asked ahead of everything its answer invalidates; architecture outranks interface outranks wording.
- Past specifics outrank hypotheticals: a generality is anchored to its most recent occurrence.
- A future-tense answer is recorded as an assumption, never as a fact ruling.
- Accept and push split by authority and evidence: an answer in the user's authority naming its cost and contradicting no anchor seals on one pass.
- An answer contradicting an anchor, dodging the fork, arriving future-tense, or mirroring the framing is pushed with the anchor in hand.
- That push terminates under the concession law.
- State the target behavior a question must extract; a prohibition phrased as a question plants the pattern it forbids.
- Options are probes carrying costs, not a menu of labels; the `(Recommended)` marker leads only where one option dominates.
- A conflict between rulings surfaces as its own question with the consequence of each resolution spelled out, never silently reconciled.
- Structure holds the interviewer's stance: a pushback earns a concession only through a new verified fact.
- A premise is checked against the corpus before questions build inside it.

## [07]-[ALTITUDE]

Every output lands at exactly one altitude; the altitude rules whether it is durable.

- [DIRECTION]: Why and where — committed and rejected directions with their kill conditions. Durable.
- [ROADMAP]: What order — outcomes sequenced by confidence horizon with promotion conditions between horizons. Durable.
- Horizons are confidence bands; a dated task list inside a roadmap is a plan leaking upward.
- [PLAN]: How — tasks, sequencing, mechanics. Ephemeral: a plan is consumed by its execution and never enters the artifact home.

One durability test decides: a future session consults the artifact as law — a standing direction, a ruled decision, a verified finding, a capability fact. Anything consumed by its own execution — transcripts, quizzes, buy-in packets, deviation ledgers, rendered interactive boards — is working material; its surviving ruling graduates to the owning durable kind and the carrier dies. Wargame scoring survives as the direction set's own wargame section; a buy-in acceptance survives as a decision record.

## [08]-[KINDS]

Each durable kind is a content contract: the fields it carries are what a future session consults as law, and its page composes through the html-studio type in its row. Each contract binds the content; html-studio binds the page — a kind never restates spine, layout, or capture law here.

| [INDEX] | [KIND]             | [HTML_STUDIO_TYPE] |
| :-----: | :----------------- | :----------------- |
|  [01]   | `decision-record`  | decision-doc       |
|  [02]   | `direction-set`    | decision-doc       |
|  [03]   | `roadmap-brief`    | roadmap            |
|  [04]   | `blindspot-ledger` | report             |
|  [05]   | `capability-entry` | atlas              |

Each kind's contract is the closed field roster its page carries:

- `decision-record`: context, drivers, costed options, one ruling, consequence, marked premises; one indicative ruling with a confirmation signal.
- `direction-set`: constraint frame, directions with thesis/tier, leading direction; disconfirmation results with flip triggers.
- `roadmap-brief`: confidence horizons, outcomes with owners/gates, promotion conditions, deps.
- `blindspot-ledger`: axis-led findings — anchor, blast radius, consequence, fold-back — and clean axes.
- `capability-entry`: owner, edges, maturity, refused arms distinguished from gaps.

Content law binds every instance regardless of kind:

- A ruling is one owning sentence in the indicative; weighing lives in drivers and options, never in the ruling, and a hedged ruling binds nothing.
- Every rejected option and killed direction carries the observable condition that reopens it; a rejection without one gets re-argued from zero.
- Marks are load-bearing: a fact carries its anchor, an assumption its invalidating condition, an inference its premises, an open its tracking route.
- A date renders only at the precision the estimate holds, and a wargame's criteria and weights are declared before any direction is scored.
- Entry ids are zero-padded ordinals scoped to the instance, optionally led by one capital kind letter (`[01]`, `[F01]`).
- An id mints once, a repeat in a scoring or ruling section is a reference, and a deleted id is never reused.

Worked accepted and rejected instances are `artifacts.md`; worked question batches and threads are `batches.md` — consult the matching set before landing a kind, composing a round, or planning a thread. One complete descent — request, re-frame, thread plan, strata, record, landing — is `thread.md`, consulted before a first thread plans.

## [09]-[HANDOFF]

- Every downstream pass binds to the ruling record: the authoring pass honors every ruling and re-litigates none.
- An entry overturned later is edited in place with its superseding ruling.
- Landing completes on three inspectable facts: fold-back emitted, durable kind composed as its typed page, page homed under the repo's naming law.
- A fold-back is the copyable prompt carrying its content into the next task as binding input.
- A durable ruling missing any of the three is unlanded, not merely unpolished.
- A fold-back that seeds a plan orders its rulings by tweak pressure and blast radius, never execution chronology.
- Decisions most exposed to movement lead, and trusted mechanics collapse below the decision surface.
- Every durable kind renders as the html-studio type in its kinds row; ephemeral carriers route to the matching variant and die by graduation.
- Variants: scored boards to wargame, quiz to quiz, packet to buy-in, deviation ledger to report, decision-surface rounds and pickers to decision-doc.
- A record nobody reads rots regardless of its content, so render and home are landing, never decoration.
- A relation an instance carries as three or more interlinked rows projects as one figure beside its rows.
- Such relations are capability edges, roadmap dependency chains, and seam findings spanning owners.
- Rows stay the truth the figure projects, and a figure edge no row carries is a drift defect the seal rejects.
- Mermaid fence craft routes through mermaid-diagramming; in-page SVG figures through html-studio.
- An interactive carrier runs served through the html-studio return channel — serve, receipts, stop.
- Interactive carriers are quiz, scored wargame board, direction picker, decision-surface round, blindspot editor.
- Copy-paste is the degraded path, never the default.
- A receipt's verdicts, scores, and selections are answer material facing the same challenge as any spoken answer.
- A receipt diverging from a spoken answer on one question is a conflict with its own question, never resolved by recency.
- A fresh cold read over a complete landing is the seal — fold-back, render, and home present and no new question raised.
- Author satisfaction is not the exit.

## [10]-[GOTCHAS]

- Agreement is the trap: an answer mirroring the question's framing is re-anchored to a specific instance before it becomes a ruling.
- Compliments and consensus are noise wearing signal.
- Softening a finding to spare the corpus author loses the finding; the anchor states the fact and the fact is the kindness.
- An artifact that needs its transcript to be understood failed the seal; the page carries everything the consumer needs.

## [11]-[REPO_INTEGRATION]

Durable pages home at `docs/atlas/` under `<kind>.<scope>[.<slug>].html`, composed and gated through html-studio; a host instruction chain declaring its own artifact home and naming law binds instead. Corpus grounding routes through the host's declared search owners — structural code search and LSP symbol navigation; the portable law is verb-neutral: verify on disk before asking.
