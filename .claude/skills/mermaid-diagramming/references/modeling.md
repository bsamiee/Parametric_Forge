# [H1][MODELING]

Four types: `classDiagram` (OO structure), `erDiagram` (data relationships), `stateDiagram-v2` (state machines), `requirementDiagram` (traceability).

[REFERENCE] classDef, styling: [->styling.md](./styling.md)
[REFERENCE] Validation: [->validation.md§06](./validation.md#06-modeling_diagrams)

## [01]-[CLASS_DIAGRAMS]

**Declaration:** `classDiagram`.

**Visibility:** `+` (public), `-` (private), `#` (protected), `~` (package). Classifiers: `method()*` (abstract), `method()$` (static).
**Annotations:** `<<interface>>`, `<<abstract>>`, `<<service>>`, `<<enumeration>>`.

**Relationships:** `<|--` (inheritance), `*--` (composition), `o--` (aggregation), `-->` (association), `--` (link), `..>` (dependency), `..|>` (realization), `..` (dashed).
**Lollipop:** `ClassA ()-- ClassB` (interface on A), `ClassA --() ClassB` (interface on B).
**Cardinality:** `1`, `0..1`, `1..*`, `*`, `n`, `0..n`, `1..n`.

**Generics:** `class List~T~` — use `~T~` NOT `<T>`. Nested: `List~List~int~~`.
**Namespace:** `namespace Name { class A; class B }`.
**Notes:** `note "text"`, `note for ClassName "text"`.
**Interactions:** `click ClassName callback "tooltip"`, `link ClassName "URL" "tooltip"`.

[CRITICAL] Comma-separated generics (`~K,V~`) NOT supported in nested contexts.

## [02]-[ENTITY_RELATIONSHIP]

**Declaration:** `erDiagram`.

**Entities:** `ENTITY { type name PK|FK|UK "comment" }`. Multiple keys: `PK, FK`.
**Crow's Foot (left|right):** `||` (exactly one), `|o`/`o|` (zero or one), `}|`/`|{` (one or more), `}o`/`o{` (zero or more).
**Lines:** `--` identifying (strong), `..` non-identifying (weak).
**Syntax:** `ENTITY1 ||--o{ ENTITY2 : label`.
**Direction:** `direction LR|TB|RL|BT` at diagram start. Multi-line labels via ` ` (v11.1.0+).

[IMPORTANT] Entity names UPPERCASE by convention. Reserved: `ONE`, `MANY`, `TO`, `U`, `1` (bug #7093).

## [03]-[STATE_DIAGRAMS]

**Declaration:** `stateDiagram-v2` (v1 deprecated).

**Elements:** `[*]` (start/end), `StateName`, `State : Description`, `S1 --> S2 : event`, `direction LR|TB|RL|BT`.
**Notes:** `note left of S : text`, `note right of S : text`. Comments: `%% text`.
**Composites:** `state A { ... }`, nested `state A { state B { } }`, parallel `--` separator.
**Stereotypes:** `<<fork>>` (split), `<<join>>` (merge), `<<choice>>` (diamond decision).

**Styling:** `classDef className property:value` at diagram root, `class StateName className` or `StateName:::className`.

[CRITICAL] Place `classDef` at diagram root, not inside composites. Start/End `[*]` and containers reject styling.

## [04]-[REQUIREMENT_DIAGRAMS]

**Declaration:** `requirementDiagram`.

**Types:** `requirement`, `functionalRequirement`, `interfaceRequirement`, `performanceRequirement`, `physicalRequirement`, `designConstraint`.
**Block:** `requirement name { id: REQ-001; text: Description; risk: low|medium|high; verifymethod: analysis|inspection|test|demonstration }`.
**Element:** `element name { type: module|component|system; docref: URL }`.

**Relations:** `contains`, `copies`, `derives`, `satisfies`, `verifies`, `refines`, `traces`. Syntax: `A - contains -> B`, reverse: `B <- contains - A`.
**Direction:** `direction TB|BT|LR|RL`. Styling: `classDef`, `class`, `style`, `:::className`.

## [05]-[CONFIG]

| [INDEX] | [KEY]              | [TYPE]  | [DEFAULT] | [APPLIES_TO] |
| :-----: | ------------------ | ------- | :-------: | ------------ |
|  [01]   | `nodeSpacing`      | number  |    50     | Class, State |
|  [02]   | `rankSpacing`      | number  |    50     | Class, State |
|  [03]   | `padding`          | number  |   8-15    | All          |
|  [04]   | `useMaxWidth`      | boolean |   true    | All          |
|  [05]   | `layoutDirection`  | string  |    TB     | ER           |
|  [06]   | `entityPadding`    | number  |    15     | ER           |
|  [07]   | `minEntityWidth`   | number  |    100    | ER           |
|  [08]   | `labelCompactMode` | boolean |   false   | State        |
