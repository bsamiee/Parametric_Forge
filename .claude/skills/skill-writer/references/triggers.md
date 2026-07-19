# [TRIGGERS]

Selection is a one-shot classification over name and description alone, run against every installed sibling on every prompt; the body never influences the choice. Under-triggering dominates the failure field, descriptions lean assertive about the work they own while a single negative boundary keeps them off the neighbors' work.

## [01]-[CONSTRUCTION]

Description construction runs in fixed order because truncation eats from the tail:
- [DELIVERABLE]: First clause names what the skill produces or owns, as a total claim — the one fact that survives every truncation. It names the deliverable, never the procedure that makes it: a description enumerating the skill's internal steps invites the model to obey the description and skip the loaded body, collapsing a multi-step method to a single pass; the method lives in the body, the description carries the produced artifact and the triggers that select it.
- [DISCRIMINANTS]: Concrete objects and verbs that select the skill — file kinds, fence kinds, commands, artifact names, verb-plus-object trigger contexts. Precision comes from discriminating nouns, never from breadth or synonym volume.
- [UTTERANCES]: Quoted user phrasings that select the skill even when the domain noun is absent — the phrases a task actually arrives wearing.
- [BOUNDARY]: Adjacent deliverable the skill refuses, named last, naming the owning sibling where one exists.

Loader admits a `when_to_use` field appended to the description under one shared cap; the utterance and boundary clauses fold into the single description instead, so one budgeted surface carries the whole trigger and the tail-truncation law governs it undivided.

Third person throughout; a voiced description breaks the selection register beside its siblings. A skill's name is its directory name: a lowercase hyphenated noun or gerund phrase of at most 64 characters naming the deliverable, never a vague stem such as helper, utils, or tools, and never a loader's reserved words.

Selection gates on task substance as well as description quality: the model consults a skill only for work it cannot readily complete unaided, so a trivial one-step request bypasses even a perfectly discriminated skill. A non-fire on a thin query is task triviality, never a starved trigger; the discriminant is repaired only when a substantive multi-step task inside the skill's own domain misses.

## [02]-[LISTING_ECONOMICS]

A budgeted listing shapes authoring law:
- Names always survive; descriptions are what the budget spends. Default budget is 1% of the model's context window, raised by `skillListingBudgetFraction` or fixed in characters by `SLASH_COMMAND_TOOL_CHAR_BUDGET`.
- Under overflow, the least-invoked skills lose their descriptions first — a rarely used skill degrades to a bare name, keeping invocability while losing trigger semantics. Frequency of use is earned protection.
- Each entry's combined description text truncates at 1536 characters regardless of budget (`skillListingMaxDescChars`); 1024 is the open-standard validation cap on `description`, so a description authored to 1024 survives both the listing truncation and every other loader's validation.
- `skillOverrides` sets per-skill visibility without editing the bundle: `on`, `name-only`, `user-invocable-only`, `off`. Demoting low-priority siblings to `name-only` frees budget for the skills whose triggers matter.
- `/doctor` reports which descriptions are shortened or dropped; `/context` reports the listing's post-budget size. A skill that mysteriously stopped firing is checked here before its description is rewritten.

## [03]-[INVOCATION_MODES]

Mode selection follows who reliably remembers the skill exists and whether firing has side effects.

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
- [NEIGHBOR_PROOF]: Winner re-runs every adjacent sibling's must-not-fire set before shipping; a candidate that wins its own suite and fires on a neighbor's queries is a collision, repaired symmetrically on both descriptions.
- [ACCUMULATION]: Losing candidates' novel misses join the permanent sets; a tuning round grows the suite even when the incumbent survives.
