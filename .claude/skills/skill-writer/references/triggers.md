# [TRIGGERS]

Selection is a one-shot classification over name and description alone, run against every installed sibling on every prompt; the body never influences the choice. Under-triggering dominates the failure field — a skill that never fires teaches nothing — so descriptions lean assertive about the work they own while a single negative boundary keeps them off the neighbors' work.

## [01]-[CONSTRUCTION]

The description is built in fixed order because truncation eats from the tail:

- [DELIVERABLE]: The first clause names what the skill produces or owns, as a total claim — the one fact that survives every truncation.
- [DISCRIMINANTS]: Concrete objects and verbs that select the skill — file kinds, fence kinds, commands, artifact names, verb-plus-object trigger contexts. Precision comes from discriminating nouns, never from breadth or synonym volume.
- [UTTERANCES]: Quoted user phrasings that select the skill even when the domain noun is absent — the phrases a task actually arrives wearing.
- [BOUNDARY]: The adjacent deliverable the skill refuses, named last, naming the owning sibling where one exists.

The loader admits a `when_to_use` field appended to the description under one shared cap; the utterance and boundary clauses fold into the single description instead, so one budgeted surface carries the whole trigger and the tail-truncation law governs it undivided.

Third person throughout; a voiced description breaks the selection register beside its siblings. The name is the directory name: a lowercase hyphenated noun or gerund phrase naming the deliverable, never a vague stem such as helper, utils, or tools, and never a loader's reserved words.

## [02]-[LISTING_ECONOMICS]

The listing is budgeted, and the budget shapes authoring law:

- Names always survive; descriptions are what the budget spends. The default budget is 1% of the model's context window, raised by `skillListingBudgetFraction` or fixed in characters by `SLASH_COMMAND_TOOL_CHAR_BUDGET`.
- Under overflow, the least-invoked skills lose their descriptions first — a rarely used skill degrades to a bare name, keeping invocability while losing trigger semantics. Frequency of use is earned protection.
- Each entry's combined description text caps at 1536 characters regardless of budget (`skillListingMaxDescChars`); the authoring budget of 1024 keeps a margin under the ceiling and survives portability across loaders.
- `skillOverrides` sets per-skill visibility without editing the bundle: `on`, `name-only`, `user-invocable-only`, `off`. Demoting low-priority siblings to `name-only` frees budget for the skills whose triggers matter.
- `/doctor` reports which descriptions are shortened or dropped; `/context` reports the listing's post-budget size. A skill that mysteriously stopped firing is checked here before its description is rewritten.

Codex-side listing budgets, discovery roots, and format deltas are the codex skill's authoring reference; a port keeps the same description and inherits that loader's truncation behavior.

## [03]-[INVOCATION_MODES]

The mode is chosen by who reliably remembers the skill exists and whether firing has side effects.

| [INDEX] | [MODE]     | [MECHANISM]                      | [WHEN]                                                          |
| :-----: | :--------- | :------------------------------- | :-------------------------------------------------------------- |
|  [01]   | `MODEL`    | Listed description, default      | Task-shaped doctrine the model matches autonomously             |
|  [02]   | `OPERATOR` | `disable-model-invocation: true` | Side-effect workflows; zero listing cost when the human indexes |
|  [03]   | `AMBIENT`  | `user-invocable: false`          | Background knowledge that is never a command                    |

`paths` globs bind a listing to work touching matching files — the monorepo cure: the description competes only where the subtree is in play, and the trigger clause stops paying for irrelevance everywhere else.

## [04]-[COLLISION]

Two skills matching one prompt is a boundary defect on both, repaired in both descriptions, never by body edits: each names the deliverable it owns and the neighbor it refuses, and the pair of boundary sentences is symmetric — each side's refusal names the other's deliverable. A must-not-fire miss discovered in evals lands here; the fix is a sharper discriminant or an added boundary, and the eval's query joins the permanent must-not-fire set.

## [05]-[DESCRIPTION_AB]

Description tuning is a measured competition, never a rewrite on taste:

- [CANDIDATES]: Rival descriptions vary the discriminants, utterances, and boundary while holding the first clause fixed — the deliverable claim is identity, not a tuning surface.
- [MEASUREMENT]: Every candidate runs the same must-fire and must-not-fire sets under the eval loop's holdout split; the adopted winner is the one that wins on the held-out half, and a candidate that wins only its tuning half memorized phrasings.
- [NEIGHBOR_PROOF]: The winner re-runs every adjacent sibling's must-not-fire set before shipping; a candidate that wins its own suite and fires on a neighbor's queries is a collision, repaired symmetrically on both descriptions.
- [ACCUMULATION]: Losing candidates' novel misses join the permanent sets; a tuning round grows the suite even when the incumbent survives.
