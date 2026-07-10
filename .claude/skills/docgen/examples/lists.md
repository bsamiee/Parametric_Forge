# [LIST_CRAFT]

List repair is symptom-indexed: each entry names one defect an agent already sees in a bullet run, carries the fixed Detection / Rejected / Accepted / Reason / Reframe card, and shows both list shapes as tiny fences. A mega bullet is a compressed section wearing a hyphen — repair classifies its fragments and routes each to its container; a closed roster whose payload is the enumeration is a registry entry, legal at length.

## [01]-[MEGA_BULLET]

The canonical crime fuses a law, its mechanism, two consequences, an exception, and an example into one hyphen; repair keeps the law and routes every other fragment to the container that owns it.

- Detection: One entry past the char budget or three sentences carrying more than one fragment class — a law plus mechanism, consequence, exception, or example — chained by semicolons, em dashes, and parentheticals that hide the section it has become.
- Rejected:
    ```markdown rejected
    - Boundary: `Compose` is the lane capsule and each `Codec` arm carries the decode form the foreign row needs; the `mesh` arm reads `Reader.Decode` materializing one contiguous `Shape` vertex/normal/index triple at the boundary because the accessor contract admits no zero-copy span, so the one boundary allocation is the point and a per-row `float[]` proliferation is the deleted form; the `scene` arm folds `Variant` graphs onto the same triple through one disposable `Context.Import(...)` over the `Triangulate | JoinVertices | GenerateNormals` steps, the leaked provider types never crossing past this capsule per the boundary-mapping law; the rejected reader picks stand — a native decoder and a closed commercial one both refused, the managed `Reader` shipping its own runtime admitted as the one owner — and a second hand-rolled tokenizer beside it is the deleted form; each arm materializes exactly one `Shape` allocation and a per-format `MeshImporter`/`SceneImporter`/`RowImporter` service family is the deleted form.
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

- Reason: The law is the entry's one decision; the boundary consequence governs every arm so it rises to the section lead, the decode steps are mechanism a fence owns, and the companion route is a contract qualifier on the law. The rejected-reader roster is a deleted-form litany that collapses to the one positive ownership claim.
- Reframe: Keep the law in one to two sentences; demote mechanism to the owning fence, the sibling-governing consequence to the section lead, and a genuine exception to a contract qualifier.

## [02]-[FRAGMENT_PROMOTION]

An entry whose fragments are all load-bearing at this altitude is not a bullet: it promotes to a GroupedRecord card with earned fields, never shredded into sibling bullets.

- Detection: A single entry carries three or more co-equal facts about one owner — a shape, its fields, its policy, its receipt — where none governs a sibling and none demotes to a fence, so every fragment must survive at this altitude.
- Rejected:
    ```markdown rejected
    - Owner: `Plan` folds the `Work` graph into admission units carrying the pre-minted `key`, the `work` thunk the plan schedules but never invokes, the `parents` upstream keys, the `cost` weight the forward pass sums into earliest-finish, and its `admission` case union, so a node is its key and a dependency is a key edge; the closed `Admission` union selects the lane case (`keyed` the cache-eligible default, `bare` a forced-live one-shot, `retried` a transient offload carrying its class), the `Schedule` computes the critical path once over the graph, and a flat unit list losing the front structure is the deleted form.
    ```
- Accepted:
    ```markdown accepted
    [Plan]:

    - Shape: folds the `Work` graph into admission units; a node is its `key`, a dependency a `key` edge.
    - Fields: `key`, `work`, `parents`, `cost`, `admission`.
    - Admission: `keyed` cache-eligible default, `bare` forced-live, `retried` transient offload with its class.
    - Schedule: the critical path, computed once over the graph.
    ```
- Reason: The fragments are peer facts about one owner, each earning a field line the cell budget of a bullet forbids; a GroupedRecord keeps every payload greppable under one key where a shredded sibling split strips the owner relation.
- Reframe: Promote the entry to a `[KEY]:` card with `- Field: value` lines when every fragment is load-bearing at this altitude.

## [03]-[SHREDDED_SPLIT]

Splitting a mega bullet's sentence run into sibling bullets without classifying the fragments shreds the compression instead of repairing it — each sibling still mixes classes.

- Detection: A repair that fans a mega bullet into shorter bullets at sentence boundaries, where a bullet still carries a law fused to its mechanism, consequence, or exception rather than one fragment class per container.
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

- Reason: The shredded form re-parses the same fusion at lower volume — each sibling still answers what, how, and what-not in one line. Classification routes mechanism to a fence and the sibling-governing consequence to the lead, so every container holds one class.
- Reframe: Classify each fragment before splitting; the bullet keeps one law, mechanism moves to a fence, and a shared consequence moves to the section lead.

## [04]-[MIXED_CONCERN_LIST]

A list whose entries answer different reader questions — what exists, how it runs, what it emits, where ownership stops — is several containers wearing one bullet run.

- Detection: Consecutive entries under one label switch question class — a model inventory beside a package call beside a receipt projection beside an anti-pattern ban — so no single question orders the list.
- Rejected:
    ```markdown rejected
    - Cases: `Row` carries the format, extent, and style; the `mesh` arm calls `Reader.Decode` over the accessor contract; the receipt projects `(key, bytes, count)`; a per-format importer family and a raw `float[]` proliferation are the deleted forms; ownership stops at the capsule, never crossing the seam.
    ```
- Accepted:

    ```markdown accepted
    [Row model]:

    - Fields: `format`, `extent`, `style`.

    [Decode]: the `mesh` arm folds `Reader.Decode` over the accessor contract.
    [Receipt]: `(key, bytes, count)`.

    Ownership stops at the capsule.
    ```

- Reason: A model inventory, a decode mechanism, a receipt shape, and a boundary law answer four questions; one bullet run forces the reader to re-sort them, where a card, a prose line, a record, and a boundary line each own one.
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
    - `keyed`: cache-eligible default.
    - `bare`: forced-live one-shot.
    - `retried`: transient offload with its class.

    The plan folds the graph into fronts, each draining under one policy the runtime threads forward as receipts.
    ```

- Reason: A number is a claim of order the lane cases do not carry, so they read as peer bullets; the second run is one sentence broken at its commas, so it reflows to prose where the bullet markers add no parallel structure.
- Reframe: De-number peers to bullets and de-list a continuous narrative to a paragraph; reserve ordinals for genuine sequence or data dependence.

## [06]-[ROSTER_EXEMPTION]

A closed enumeration whose payload is the roster itself is a registry entry, legal past the budget; the members are data, not prose hiding law.

- Detection: An entry over the budget whose body is one closed set of atomic tokens — a banned-word roster, a vocabulary inventory, a code-span registry — carrying no law, mechanism, or consequence between members.
- Rejected:
    ```markdown rejected
    - The gate bans hedging: the word should is banned, and could is banned, and would is banned, and might is banned, and maybe is banned, because each softens a settled decision the register forecloses.
    ```
- Accepted:
    ```markdown accepted
    - Banned: `should` `could` `would` `might` `maybe` `perhaps` `likely` `probably` `propose` `consider` `recommended` `ideally` `is expected to` `aims to` `in the future` `eventually` `as needed`.
    ```
- Reason: The roster's members are the payload and each is an atomic token, so the entry is a registry enumeration the budget exempts by its code-span density; spelled as prose with a conjunction between members it hides no roster and the exemption lapses.
- Reframe: Carry a closed roster as a `Banned:`/`[REGISTRY]:` entry of code-span tokens; the budget exempts an entry whose body is the enumeration, never prose narrating it.

## [07]-[LEADER_SENTENCE]

A section that opens straight into its first list entry forces that entry to carry the whole section frame; a lead sentence names the container grammar so the entries stay peers.

- Detection: A header followed immediately by a list, or a repeated label leader — `Cases:`, `Auto:`, `Owner:` — introducing an inventory without declaring whether the rows are peers, ordered stages, rejected shapes, or owner records.
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

- Reason: The lead states the axis law once so each row drops to an atomic lookup; without it the first entry absorbs the owner declaration, the field roster, and the dispatch rule and collapses under the load.
- Reframe: Open the section with one charter sentence naming the container, then let the entries or table rows carry atomic members.

## [08]-[NESTED_LIST]

Child entries nested under a parent that is not their governing rule are peers mis-filed as details; a bullet that avoids nesting with semicolons and em dashes hides the same hierarchy in one unreviewable line.

- Detection: Children owning a different concern than the parent's rule — codec records, registries, protocol rows beneath a boundary bullet — or one entry whose semicolons, dashes, and parentheticals encode a tree the render flattens.
- Rejected:
    ```markdown rejected
    - Boundary: `Compose` closes the lane and prepares each arm, never authoring content.
        - [MESH_CODECS]: the `mesh` arm names `Reader` as its package and grounds the `stl`/`obj`/`off` rows, import-only, the writer family out of scope.
        - [SCENE_CODECS]: the `scene` arm folds `Context.Import` over the triangulate steps, the leaked types never crossing the seam.
        - [PROTOCOL]: the `step` rows split a managed leg and a companion geometry leg keyed on the row.
    ```
- Accepted:

    ```markdown accepted
    `Compose` closes the lane and prepares each arm, never authoring content.

    | [INDEX] | [CODEC] | [ARM]            | [SCOPE]     |
    | :-----: | :------ | :--------------- | :---------- |
    |  [01]   | `mesh`  | `Reader`         | import-only |
    |  [02]   | `scene` | `Context.Import` | import-only |
    |  [03]   | `step`  | `managed`        | split-leg   |
    ```

- Reason: The children are codec and protocol records owning a concern the boundary rule does not govern, so they belong in a registry table; nested under the boundary bullet they read as subordinate details and the parent overstuffs to hold them.
- Reframe: Keep the boundary law as one line and lift the mis-nested children to the registry table or record set that owns them.
