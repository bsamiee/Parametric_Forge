# [LIST_CRAFT]

List repair classifies fragments before cutting: a fragment's class, never its length, selects the container it routes to.

Budget bounds an entry, never shapes it. Index-tier entries — README, ARCHITECTURE, and every router — land under 150 columns; the gate fails any entry past 500 characters or three sentences. Registry kinds carrying settled law with its governing reason, RULINGS above all, run past that width by design. Read an over-width index entry as payload belonging one tier down, and demote it whole. Width licenses no split: one decision stays one entry at any length, and slicing it at a comma to reach a column count is the shredded split at [03].

## [01]-[MEGA_BULLET]

One hyphen fusing a law, its mechanism, two consequences, an exception, and an example is the canonical crime; repair keeps the law and routes every other fragment to the container that owns it.

- Detection: One entry past the char budget or three sentences carrying more than one fragment class — a law plus mechanism, consequence, exception, or example — chained by semicolons, em dashes, and parentheticals that hide the section it has become.
- Rejected:
    ```markdown rejected
    - Boundary: `Compose` is the dispatch capsule and each `Codec` arm carries the decode form the foreign row needs; the `mesh` arm reads `Reader.Decode` materializing one contiguous `Shape` vertex/normal/index triple at the boundary because the accessor contract admits no zero-copy span, so the one boundary allocation is the point and a per-row `float[]` proliferation is the deleted form; the `scene` arm folds `Variant` graphs onto the same triple through one disposable `Context.Import(...)` over the `Triangulate | JoinVertices | GenerateNormals` steps, the leaked provider types never crossing past this capsule per the boundary-mapping law; the rejected reader picks stand — a native decoder and a closed commercial one both refused, the managed `Reader` shipping its own runtime admitted as the one owner — and a second hand-rolled tokenizer beside it is the deleted form; each arm materializes exactly one `Shape` allocation and a per-format `MeshImporter`/`SceneImporter`/`RowImporter` service family is the deleted form.
    ```
- Accepted:

    ````markdown accepted
    Every arm materializes one `Shape` allocation at the boundary.

    - Law: `Compose` folds each row through its own `Codec` arm, `unless` the row's companion column routes geometry to the companion rail.

    ```text
    mesh   -> Reader.Decode     -> Shape triple
    scene  -> Context.Import    -> Shape triple
    ```
    ````

- Reason: Law is the entry's one decision; the boundary consequence governs every arm so it rises to the section lead, the decode steps are mechanism a fence owns, and the companion route is a contract qualifier on the law; a rejected-reader roster is a deleted-form litany collapsing to the one positive ownership claim.
- Reframe: Keep the law in one to two sentences; demote mechanism to the owning fence, the sibling-governing consequence to the section lead, and a genuine exception to a contract qualifier.

## [02]-[FRAGMENT_PROMOTION]

Entries whose fragments are all load-bearing at this tier are not bullets: each promotes to a GroupedRecord card with earned fields, never shredded into sibling bullets.

- Detection: Flag a single entry carrying three or more co-equal facts about one owner — a shape, its fields, its policy, its receipt — where none governs a sibling and none demotes to a fence, so every fragment must survive at this tier.
- Rejected:
    ```markdown rejected
    - Owner: `Plan` folds the `Work` graph into admission units carrying the pre-minted `key`, the `work` thunk the plan schedules but never invokes, the `parents` upstream keys, the `cost` weight the forward pass sums into earliest-finish, and its `admission` case union, so a node is its key and a dependency is a key edge; the closed `Admission` union selects the scheduling case (`keyed` the cache-eligible default, `bare` a forced-live one-shot, `retried` a transient offload carrying its class), the `Schedule` computes the critical path once over the graph, and a flat unit list losing the front structure is the deleted form.
    ```
- Accepted:
    ```markdown accepted
    [Plan]:

    - Shape: Folds the `Work` graph into admission units; a node is its `key`, a dependency a `key` edge.
    - Fields: `key`, `work`, `parents`, `cost`, `admission`.
    - Admission: `keyed` cache-eligible default, `bare` forced-live, `retried` transient offload with its class.
    - Schedule: Critical path, computed once over the graph.
    ```
- Reason: These fragments are peer facts about one owner, each earning a field line the cell budget of a bullet forbids; a GroupedRecord keeps every payload greppable under one key where a shredded sibling split strips the owner relation.
- Reframe: Promote the entry to a `[KEY]:` card with `- Field: value` lines when every fragment is load-bearing at this tier.

## [03]-[SHREDDED_SPLIT]

Splitting a mega bullet's sentence run into sibling bullets without classifying the fragments shreds the compression instead of repairing it — each sibling still mixes classes.

- Detection: Flag a repair fanning a mega bullet into shorter bullets at sentence boundaries, where a bullet still carries a law fused to its mechanism, consequence, or exception rather than one fragment class per container.
- Rejected:
    ```markdown rejected
    - `Compose` folds each row through its `Codec` arm and a per-format importer family is the deleted form.
    - The `mesh` arm materializes one `Shape` triple because the accessor admits no zero-copy span, so a per-row `float[]` is the deleted form.
    - The rejected reader picks stand and a second tokenizer is the deleted form, while geometry routes to the companion rail unless the row clears it.
    ```
- Accepted:

    ````markdown accepted
    Every arm materializes one `Shape` allocation at the boundary.

    - Law: `Compose` folds each row through its own `Codec` arm, `unless` the row routes geometry to the companion rail.

    ```text
    mesh   -> Reader.Decode     -> Shape triple
    scene  -> Context.Import    -> Shape triple
    ```
    ````

- Reason: Shredded forms re-parse the same fusion at lower volume — each sibling still answers what, how, and what-not in one line. Classification routes mechanism to a fence and the sibling-governing consequence to the lead, so every container holds one class.
- Reframe: Classify each fragment before splitting; the bullet keeps one law, mechanism moves to a fence, and a shared consequence moves to the section lead.

## [04]-[MIXED_CONCERN_LIST]

Lists whose entries answer different reader questions — what exists, how it runs, what it emits, where ownership stops — are several containers wearing one bullet run.

- Detection: Consecutive entries under one label switch question class — a model inventory beside a package call beside a receipt projection beside an anti-pattern ban — so no single question orders the list.
- Rejected:
    ```markdown rejected
    - Cases: `Row` carries the format, extent, and style; the `mesh` arm calls `Reader.Decode` over the accessor contract; the receipt projects `(key, bytes, count)`; a per-format importer family and a raw `float[]` proliferation are the deleted forms; ownership stops at the capsule, never crossing the seam.
    ```
- Accepted:

    ```markdown accepted
    [Row model]:
    - Fields: `format`, `extent`, `style`.

    [Decode]: The `mesh` arm folds `Reader.Decode` over the accessor contract.
    [Receipt]: `(key, bytes, count)`.

    Ownership stops at the capsule.
    ```

- Reason: Model inventory, decode mechanism, receipt shape, and boundary law answer four questions; one bullet run forces the reader to re-sort them, where a card, a prose line, a record, and a boundary line each own one.
- Reframe: Split the run by question class — inventory to a card or table, mechanism to prose or a fence, receipt to a record, boundary to one line.

## [05]-[PSEUDO_SEQUENCE]

Numbered markers claim an ordered sequence; peers wearing numbers de-number to bullets, and a continuous narrative chopped into bullets re-flows to a paragraph.

- Detection: Ordinal markers over items with no execution order or data dependence, or a bullet run whose entries only read in sequence and share no atomic parallel — a paragraph split at its sentence joints.
- Rejected:

    ```markdown rejected
    1. `keyed` admits the cache-eligible default.
    2. `bare` forces a live one-shot.
    3. `retried` offloads a transient with its class.

    - The plan folds the graph into fronts,
    - so each front drains under one policy,
    - which the runtime threads forward as receipts.
    ```

- Accepted:

    ```markdown accepted
    - `keyed`: Cache-eligible default.
    - `bare`: Forced-live one-shot.
    - `retried`: Transient offload with its class.

    The plan folds the graph into fronts, each draining under one policy the runtime threads forward as receipts.
    ```

- Reason: Numbers claim an order the union cases do not carry, so they read as peer bullets; the second run is one sentence broken at its commas, so it reflows to prose where the bullet markers add no parallel structure.
- Reframe: De-number peers to bullets and de-list a continuous narrative to a paragraph; reserve ordinals for genuine sequence or data dependence.

## [06]-[ROSTER_EXEMPTION]

Closed enumerations whose payload is the roster itself are registry entries, legal past the budget; the members are data, not prose hiding law.

- Detection: Admit an entry over the budget whose body is one closed set of atomic tokens — a banned-word roster, a vocabulary inventory, a code-span registry — carrying no law, mechanism, or consequence between members.
- Rejected:
    ```markdown rejected
    - The gate bans hedging: the word should is banned, and could is banned, and would is banned, and might is banned, and maybe is banned, because each softens a settled decision the voice forecloses.
    ```
- Accepted:
    ```markdown accepted
    - Banned: `should` `could` `would` `might` `maybe` `perhaps` `likely` `probably` `propose` `consider` `recommended` `ideally` `is expected to` `aims to` `in the future` `eventually` `as needed`.
    ```
- Reason: Roster members are the payload and each is an atomic token, so the entry is a registry enumeration the budget exempts by its code-span density; spelled as prose with a conjunction between members it hides no roster and the exemption lapses.
- Reframe: Carry a closed roster as a `Banned:`/`[REGISTRY]:` entry of code-span tokens; the budget exempts an entry whose body is the enumeration, never prose narrating it.

## [07]-[LEADER_SENTENCE]

Sections opening straight into their first list entry force that entry to carry the whole section frame; a lead sentence names the container grammar so the entries stay peers.

- Detection: Flag a header followed immediately by a list, and a repeated label leader — `Cases:`, `Auto:`, `Owner:` — introducing an inventory without declaring whether the rows are peers, ordered stages, rejected shapes, or owner records.
- Rejected:
    ```markdown rejected
    ## [02]-[COMPOSE_AXIS]

    - Owner: `Compose` the rows carrying media type, extent, capability, codec discriminant, companion flag, the basis-change column, the protocol discriminant, and the serialization option, folded by one lookup over the discriminant, never a call-site branch.
    ```
- Accepted:

    ```markdown accepted
    ## [02]-[COMPOSE_AXIS]

    `Compose` mints one row per format; the discriminant selects the codec arm.

    | [INDEX] | [FORMAT] | [CODEC]  | [COMPANION] |
    | :-----: | :------- | :------- | :---------: |
    |  [01]   | `mesh`   | `reader` |     no      |
    |  [02]   | `scene`  | `import` |     yes     |
    ```

- Reason: Leads state the axis law once so each row drops to an atomic lookup; without one the first entry absorbs the owner declaration, the field roster, and the dispatch rule and collapses under the load.
- Reframe: Open the section with one charter sentence naming the container, then let the entries or table rows carry atomic members.

## [08]-[NESTED_LIST]

Child entries nested under a parent that is not their governing rule are peers mis-filed as details; a bullet that avoids nesting with semicolons and em dashes hides the same hierarchy in one unreviewable line.

- Detection: Children owning a different concern than the parent's rule — codec records, registries, protocol rows beneath a boundary bullet — or one entry whose semicolons, dashes, and parentheticals encode a tree the render flattens.
- Rejected:
    ```markdown rejected
    - Boundary: `Compose` closes the dispatch and prepares each arm, never authoring content.
        - [MESH_CODECS]: The `mesh` arm names `Reader` as its package and grounds the `stl`/`obj`/`off` rows, import-only, the writer family out of scope.
        - [SCENE_CODECS]: The `scene` arm folds `Context.Import` over the triangulate steps, the leaked types never crossing the seam.
        - [PROTOCOL]: The `step` rows split a managed leg and a companion geometry leg keyed on the row.
    ```
- Accepted:

    ```markdown accepted
    `Compose` closes the dispatch and prepares each arm, never authoring content.

    | [INDEX] | [CODEC] | [ARM]            | [SCOPE]     |
    | :-----: | :------ | :--------------- | :---------- |
    |  [01]   | `mesh`  | `Reader`         | import-only |
    |  [02]   | `scene` | `Context.Import` | import-only |
    |  [03]   | `step`  | `managed`        | split-leg   |
    ```

- Reason: These children are codec and protocol records owning a concern the boundary rule does not govern, so they belong in a registry table; nested under the boundary bullet they read as subordinate details and the parent overstuffs to hold them.
- Reframe: Keep the boundary law as one line and lift the mis-nested children to the registry table or record set that owns them.

## [09]-[SAME_DECISION_SIBLINGS]

Sibling entries each re-carrying one decision in different words are restatements wearing a list — the merge-inverse of the shredded split: restatements collapse into one denser entry while every distinct clause survives intact.

- Detection: Delete all but the strongest sibling; no law lost proves the run was restatements, and an entry carrying a genuinely distinct decision — a boundary, an exception, a failure law — stays a sibling.
- Rejected:
    ```markdown rejected
    - `Compose` folds every row through one dispatch table, never a call-site branch.
    - Dispatch rides the table; a call-site branch is the deleted form.
    - Every row resolves through the one table — branching at the call site defeats it.
    - A row missing its table entry fails loudly at registration, never silently at dispatch.
    ```
- Accepted:
    ```markdown accepted
    - `Compose` folds every row through one dispatch table, never a call-site branch.
    - A row missing its table entry fails loudly at registration, never silently at dispatch.
    ```
- Reason: Entries one through three re-spell one decision — table-owned dispatch — while the fourth carries a distinct failure law; the merge keeps the strongest spelling with its call-site clause intact and the failure entry whole, so resolution rises as the run shrinks.
- Reframe: Classify each sibling against the strongest one before deleting: a restatement merges into it, a distinct decision survives as its own entry with its clause intact — never a concatenated mega-entry, never a paragraph flood.

## [10]-[ARTICLE_HOOK]

Entries opening on an article bury their owner; marker leaders only disguise the same voice defect.

- Detection: Flag marker bodies opening on an article — `The`/`the`, `A`/`An`.
- Rejected:
    ```markdown rejected
    - [02]-[SOLVE_VOCABULARY]: The solve, eigen, norm, and gauge route algebra every receipt discriminates on.
    ```
- Accepted:
    ```markdown accepted
    - [02]-[SOLVE_VOCABULARY]: `Solve`, `eigen`, `norm`, and `gauge` route the algebra every receipt discriminates on.
    ```
- Reason: Route families become the subject under the owning verb `route`.
- Reframe: Recast owner-first; repair holds only when the subject moved, never when the determiner changed.
