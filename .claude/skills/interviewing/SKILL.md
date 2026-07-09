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

## [01]-[OPERATING_LOOP]

Elicitation is a hard gate before any brief, spec, roadmap, or direction document: a change that looks too simple to design still passes intent, constraints, options, and validation. The loop runs as sequenced moves; each carries its exit test.

- [GROUND]: Read what exists — corpus, supplied references, stated constraints — along the interrogation axes before the first question; exit when every axis the request touches carries a verified anchor or a recorded clean.
- [FRAME]: Classify the unknowns into the knowledge buckets and route each to its technique; exit when every named unknown has a bucket and no bucket with signal has zero coverage.
- [INTERROGATE]: Descend the planned threads round by round — each stratum's rulings premise the next stratum's questions under the question law; exit when every thread has sealed in a durable ruling or a tracked open item, and a thread advancing two rounds without changing a ruling seals as open.
- [RULE]: Convert each answer into a marked ruling — fact, assumption, inference, or open — and surface every conflict as its own question; exit when no answer remains unclassified and every conflict is resolved or held as an open entry binding neither ruling.
- [LAND]: Rule durability and kind by altitude; a durable ruling instantiates its kind's contract, emits the fold-back, and renders as its typed page — exit when fold-back, render, and home stand and a cold read raises no new question; an ephemeral carrier exits by graduating its surviving ruling to the owning durable kind or dying owing nothing.

Pacing is bounded on both ends: one load-bearing question at a time when answers cascade, independent questions batched, roughly ten questions per session with nonessential gaps defaulted and named as defaults in the record. A scope whose threads outrun the session budget partitions by blast radius — the highest-ranked threads run now, the remainder route to tracked cards that seed the next session's frame; a marathon session dilutes every ruling it lands.

## [02]-[GROUNDING]

Questions confront the user with what is, never with an abstraction the user must imagine.

- The corpus check precedes every round: a question whose answer the corpus, the stated constraints, or the domain default already holds is a wasted round.
- The confrontation set is the grounding product: each entry carries the exact anchor (path and line), the observed fact, and its axis token. A question earns force by embedding its anchor — the user reacts to a named surface, a real weakness, a real structure.
- A corpus beyond one session's reading budget partitions into read-only investigation legs, each assigned axes and returning anchored facts; the legs fold into the confrontation set before round one.
- An unverified candidate finding never enters a question; the anchor is re-opened on disk first.
- A corpus that contradicts itself is grounding signal, not noise: the divergence enters the confrontation set as one two-anchor row and surfaces as a conflict question carrying both resolutions' consequences, never resolved by silently siding with either anchor.

The axis catalog — each axis with its probe method, question shape, and confirming evidence — is [references/axes.md](references/axes.md), loaded before any grounding pass.

## [03]-[UNKNOWNS_ROUTING]

Every request decomposes into knowledge buckets; the bucket selects the technique. Blindspot and brainstorm run before interview rounds where their buckets carry signal — the interview covers the residuals they leave.

| [INDEX] | [BUCKET]         | [SIGNAL]                         | [TECHNIQUE]                    |
| :-----: | :--------------- | :------------------------------- | :----------------------------- |
|  [01]   | known knowns     | stated in the request            | recorded as constraints        |
|  [02]   | known unknowns   | the user names the open question | interview rounds               |
|  [03]   | unknown knowns   | recognizable only when seen      | direction fanout and prototype |
|  [04]   | unknown unknowns | unfamiliar territory or corpus   | blindspot pass along the axes  |

Two degenerate signals re-route before any decision question: a user who cannot describe the target supplies a reference — source code outranks any screenshot or description of it, and a ruling premising on the reference passes the reference-confirmation protocol before it seals; a user who cannot evaluate options enters teach-me — fanning variations at someone who cannot judge them wastes the fan.

## [04]-[MODES]

Every mode obeys the operating loop and differs in what it extracts and lands; staged procedures with per-stage exit tests are [references/modes.md](references/modes.md), loaded when a mode begins.

| [INDEX] | [MODE]           | [TRIGGER]                          | [DEFAULT_LANDING]     |
| :-----: | :--------------- | :--------------------------------- | :-------------------- |
|  [01]   | `interview`      | requirements ambiguous or unstated | `decision-record` set |
|  [02]   | `blindspot-pass` | unfamiliar ground or pre-seal      | `blindspot-ledger`    |
|  [03]   | `brainstorm`     | direction uncommitted              | `direction-set`       |
|  [04]   | `quiz`           | comprehension unproven pre-merge   | scored gate           |
|  [05]   | `buy-in`         | acceptance needed outside the loop | packet                |
|  [06]   | `teach-me`       | user cannot evaluate or phrase     | vocabulary map        |
|  [07]   | `notes`          | mid-build discovery strikes a plan | deviation ledger      |

The landing column is the default; the altitude law owns kind selection. Roadmap-altitude rulings compose a `roadmap-brief` from any mode, and a finding stating a standing capability fact lands as a `capability-entry` row from any pass. The trigger word never overrides the entry test: a mode invoked while its entry condition fails re-routes to the mode whose condition holds — a wargame call with no direction fan enters `brainstorm` to generate one, a quiz call on unsealed work returns to the build, a brainstorm call against a committed direction interrogates the commitment as an `interview` thread instead of refanning it.

## [05]-[QUESTION_LAW]

The always-hot core; composition depth — thread design, evidence extraction, challenge protocols, option and batch mechanics — is [references/question-craft.md](references/question-craft.md), loaded when composing any round.

- Rounds are strata of a planned thread, never a survey: a thread opens on its root — the load-bearing fork that gates whether the thread exists and routes its branch — each ruling's consequence premises the next stratum's question, and the descent terminates in a durable ruling naming the owner surface that changes. A round whose answers premise no next question inventoried the corpus instead of interrogating it.
- Mechanism is the thread's floor, never its head: owner, truth source, and seam type are fixed by the upper strata before any question reaches signature, dispatch form, or member choice.
- A question earns its stratum only when undetermined, consequential, and ranked: not answerable from the corpus, carrying at least two options that change the work differently, and asked ahead of everything its answer invalidates. Architecture outranks interface outranks wording.
- Past specifics outrank hypotheticals: a generality is anchored to its most recent occurrence, and a future-tense answer is recorded as an assumption, never as a fact ruling.
- Accept and push split by authority and evidence: an answer inside the user's authority that names its cost and contradicts no anchor seals on one pass; an answer contradicting an anchor, dodging the fork, arriving future-tense, or mirroring the framing is pushed with the anchor in hand, and the push terminates under the concession law.
- State the target behavior a question must extract; a prohibition phrased as a question plants the pattern it forbids.
- Options are probes carrying costs, not a menu of labels; the `(Recommended)` marker leads only where one option dominates.
- A conflict between rulings surfaces as its own question with the consequence of each resolution spelled out, never silently reconciled.
- The interviewer holds its own stance by structure: a pushback earns a concession only through a new verified fact, and a premise is checked against the corpus before questions build inside it.

## [06]-[ALTITUDE]

Every output lands at exactly one altitude; the altitude rules whether it is durable.

- [DIRECTION]: Why and where — committed and rejected directions with their kill conditions. Durable.
- [ROADMAP]: What order — outcomes sequenced by confidence horizon with promotion conditions between horizons. Durable. Horizons are confidence bands; a dated task list inside a roadmap is a plan leaking upward.
- [PLAN]: How — tasks, sequencing, mechanics. Ephemeral: a plan is consumed by its execution and never enters the artifact home.

The durability test: a future session consults the artifact as law — a standing direction, a ruled decision, a verified finding, a capability fact. Anything consumed by its own execution — transcripts, quizzes, buy-in packets, deviation ledgers, rendered interactive boards — is working material; its surviving ruling graduates to the owning durable kind and the carrier dies. Wargame scoring survives as the direction set's own wargame section; a buy-in acceptance survives as a decision record.

## [07]-[KINDS]

Each durable kind is a content contract: the fields in its row are what a future session consults as law, and the kind's page composes through the html-studio type in its row. The contract binds the content; html-studio binds the page — a kind never restates spine, layout, or capture law here.

| [INDEX] | [KIND]             | [CONTRACT]                                                                                                  | [HTML_STUDIO_TYPE] |
| :-----: | :----------------- | :----------------------------------------------------------------------------------------------------------- | :----------------- |
|  [01]   | `decision-record`  | context, drivers, options with costs, one indicative ruling, consequence, confirmation signal, marked premises | decision-doc       |
|  [02]   | `direction-set`    | constraint frame, directions with thesis and tier, disconfirmation results, leading direction, flip triggers   | decision-doc       |
|  [03]   | `roadmap-brief`    | confidence horizons, outcomes with owners and gates, promotion conditions, dependencies                       | roadmap            |
|  [04]   | `blindspot-ledger` | axis-led findings with anchor, blast radius, consequence, and fold-back; clean axes listed                     | report             |
|  [05]   | `capability-entry` | owner, edges, maturity, refused arms distinguished from gaps                                                   | atlas              |

Content law binds every instance regardless of kind:

- The ruling is one owning sentence in the indicative; weighing lives in drivers and options, never in the ruling, and a hedged ruling binds nothing.
- Every rejected option and killed direction carries the observable condition that reopens it; a rejection without one reads as dogma and gets re-argued from zero.
- Marks are load-bearing: a fact carries its anchor, an assumption its invalidating condition, an inference its named premises, an open item its tracking route.
- A date renders only at the precision the estimate holds, and a wargame's criteria and weights are declared before any direction is scored.
- Entry ids are zero-padded ordinals scoped to the instance, optionally led by one capital kind letter (`[01]`, `[F01]`); an id mints once, a repeat in a scoring or ruling section is a reference, and a deleted id is never reused.

Worked accepted and rejected instances are [examples/artifacts.md](examples/artifacts.md); worked question batches and threads are [examples/batches.md](examples/batches.md) — consult the matching set before landing a kind, composing a round, or planning a thread.

## [08]-[HANDOFF]

- The ruling record binds downstream: the authoring pass honors every ruling and re-litigates none; an entry overturned later is edited in place with its superseding ruling.
- Landing completes on three inspectable facts: the terminal deliverable's fold-back is emitted — the copyable prompt that carries its content into the next task as binding input — the durable kind is composed as its typed page, and the page is homed under the repo's naming law. A durable ruling missing any of the three is unlanded, not merely unpolished.
- A fold-back that seeds a plan orders its rulings by tweak pressure and blast radius, never execution chronology: the decisions most exposed to movement lead, and trusted mechanics collapse below the decision surface.
- Every durable kind renders as the html-studio type in its kinds row; ephemeral carriers route to the matching html-studio variant — scored boards as wargame, quiz as quiz, packet as buy-in, deviation ledger as report, decision-surface rounds and direction pickers as decision-doc — and die by graduation. A record nobody reads rots regardless of its content, so render and home are landing, never decoration.
- A relation an instance carries as three or more interlinked rows — capability edges, roadmap dependency chains, seam findings spanning owners — projects as one figure beside its rows; the rows stay the truth the figure projects, and a figure edge no row carries is a drift defect the seal rejects. Mermaid fence craft routes through mermaid-diagramming; in-page SVG figures through html-studio.
- An interactive carrier — quiz, scored wargame board, direction picker, decision-surface round, blindspot editor — runs served through the html-studio return channel (serve, receipts, stop); copy-paste is the degraded path, never the default. A receipt's verdicts, scores, and selections are answer material facing the same challenge as any spoken answer, and a receipt diverging from a spoken answer on one question is a conflict with its own question, never resolved by recency.
- The seal is a fresh cold read over a complete landing — fold-back, render, and home present and no new question raised; author satisfaction is not the exit.

## [09]-[GOTCHAS]

- Agreement is the trap: an answer mirroring the question's framing is re-anchored to a specific instance before it becomes a ruling — compliments and consensus are noise wearing signal.
- Softening a finding to spare the corpus author loses the finding; the anchor states the fact and the fact is the kindness.
- An artifact that needs its transcript to be understood failed the seal; the page carries everything the consumer needs.

## [10]-[REPO_INTEGRATION]

Durable pages home at `docs/atlas/` under `<kind>.<scope>[.<slug>].html`, composed and gated through html-studio; a host instruction chain declaring its own artifact home and naming law binds instead. Corpus grounding routes through the host's declared search owners — structural code search and LSP symbol navigation; the portable law is verb-neutral: verify on disk before asking.
