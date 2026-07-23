# [MARKER_CRAFT]

Marker repair lands state in declared tokens: an undeclared spelling, a narrated status, or an exploded token list converts to the schema owner's greppable form.

## [01]-[ENTRY_LEADER_LEDGER]

A work-file entry buries its state in a prose sentence instead of a greppable `[<ID>]-[<STATUS>]:` leader.

- Detection: An entry whose lifecycle state lives in a sentence an agent must parse, not in a leader token it can filter.
- Rejected:
    ```markdown rejected
    - Entry 0042 is currently blocked on the persistence seam and moves once the codec lands.
    ```
- Accepted:
    ```markdown accepted
    - [0042]-[BLOCKED]: persistence seam codec
        - Capability: Content-addressed decode across the wire
        - Anchors: The codec owner and the artifact index
        - Tension: The decode contract is unresolved
    ```
- Reason: The leader carries identity and state as one greppable token; an agent filters the ledger on `[BLOCKED]` without parsing bodies.
- Reframe: Compose the leader as `[<ID>]-[<STATUS>]:` and advance by editing the token alone — `[0042]-[BLOCKED]:` becomes `[0042]-[ACTIVE]:` — with no prose move narration.

## [02]-[STATUS_VOCABULARY]

A work-file marks state with ad-hoc words drawn from no declared, closed vocabulary.

- Detection: State tokens that vary across agents and files with no owning declaration.
- Rejected:
    ```markdown rejected
    - Entries use `done`, `finished`, `in-flight`, `on-hold`, `killed`, and `wip` interchangeably across agents.
    ```
- Accepted:
    ```markdown accepted
    [STATUS]: `[QUEUED]` `[ACTIVE]` `[BLOCKED]` `[COMPLETE]` `[DROPPED]`
    ```
- Reason: A closed token set with one meaning per token makes the ledger machine-filterable; interchangeable synonyms fork one state across agents.
- Reframe: Declare the vocabulary once as an inline token run and let a type standard narrow casing and terminal states, never redefine tokens per instance.

## [03]-[GROUP_LABEL_VS_LIST]

A closed token set with no per-member content is exploded into a one-per-line list.

- Detection: A referenced token set rendered as a bullet list where no member carries its own field.
- Rejected:
    ```markdown rejected
    - `QUEUED`
    - `ACTIVE`
    - `BLOCKED`
    - `COMPLETE`
    ```
- Accepted:
    ```markdown accepted
    [STATUS]: `[QUEUED]` `[ACTIVE]` `[BLOCKED]` `[COMPLETE]`
    ```
    ```markdown accepted
    [STATUS]:
    - `[QUEUED]`: Accepted for the sequence, not yet running
    - `[BLOCKED]`: Held by a dependency
    ```
- Reason: A referenced token set rides inline after its group label on one line; the list form is earned only where each member carries its own content.
- Reframe: Inline the bare token run; expand to a per-member list only when a meaning or field attaches to each token.

## [04]-[COMPACT_GLYPHS]

A dense delta or checklist spells each state as a full word where a declared compact glyph carries it.

- Detection: A delta or checked list widened by full-word status where a globally declared glyph suffices.
- Rejected:
    ```markdown rejected
    - pass: codec landing
    - fail: seam alignment
    - attention: index migration
    ```
- Accepted:
    ```markdown accepted
    - [O] codec landing
    - [X] seam alignment
    - [!] index migration
    ```
- Reason: Compact glyphs with globally declared meanings carry state at delta density; a full-word status widens every line where the glyph suffices.
- Reframe: Render declared compact glyphs in dense checked or delta lists only, meanings stated once at the owner and never duplicating a field the entry already holds.

## [05]-[UNDECLARED_MARKER_SPRAWL]

Multiple work files each declare their own marker spellings for one shared state concept.

- Detection: Two or more surfaces re-declaring partial, differently-spelled tokens for the same lifecycle.
- Rejected:
    ```markdown rejected
    - file one: `[WIP]` `[DONE]` `[STUCK]`
    - file two: `[in-progress]` `[complete]` `[held]`
    - file three: `[active]` `[shipped]` `[waiting]`
    ```
- Accepted:
    ```markdown accepted
    [STATUS]: `[QUEUED]` `[ACTIVE]` `[BLOCKED]` `[COMPLETE]` `[DROPPED]`
    ```
- Reason: One owner declares the vocabulary and every instance composes it; scattered re-declarations fork the state concept into incompatible spellings.
- Reframe: Consolidate every spelling to the schema owner and convert each instance to silent composition.
