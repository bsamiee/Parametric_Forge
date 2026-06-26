# [H1][INTERACTION]

Two diagram types: `sequenceDiagram` (message-passing protocols), `journey` (user experience mapping).
## [01]-[SEQUENCE]

### [1.1]-[PARTICIPANTS]

| [INDEX] | [TYPE]      | [SYNTAX]                                  | [RENDER]           | [UML_SEMANTIC]      |
| :-----: | ----------- | ----------------------------------------- | ------------------ | ------------------- |
|  [01]   | participant | `participant A`                           | Rectangle          | Generic participant |
|  [02]   | actor       | `actor A`                                 | Stick figure       | Human actor         |
|  [03]   | boundary    | `participant A@{ "type": "boundary" }`    | Interface boundary | External interface  |
|  [04]   | control     | `participant A@{ "type": "control" }`     | Controller symbol  | Logic coordinator   |
|  [05]   | entity      | `participant A@{ "type": "entity" }`      | Data object        | Domain data holder  |
|  [06]   | database    | `participant A@{ "type": "database" }`    | Cylinder           | Data storage        |
|  [07]   | queue       | `participant A@{ "type": "queue" }`       | Queue symbol       | Async queue         |
|  [08]   | collections | `participant A@{ "type": "collections" }` | Stack symbol       | Data collection     |

**Aliasing:** `participant LongName as Short`—ID differs from display label.
**Grouping:** `box rgb(r,g,b) Label` ... `end`—supports `transparent` for visual clustering.
**Lifecycle:** `create participant X` spawns mid-diagram; `destroy X` terminates with `X` marker.

[CRITICAL] JSON type requires double quotes; incompatible with `as Alias` syntax.

### [1.2]-[ARROWS]

| [INDEX] | [SYNTAX] | [APPEARANCE]         | [USE_CASE]          |
| :-----: | -------- | -------------------- | ------------------- |
|  [01]   | `->`     | Solid, no arrow      | Basic call          |
|  [02]   | `-->`    | Dotted, no arrow     | Async return        |
|  [03]   | `->>`    | Solid, filled arrow  | Blocking call       |
|  [04]   | `-->>`   | Dotted, filled arrow | Blocking return     |
|  [05]   | `-)`     | Solid, open arrow    | Fire-and-forget     |
|  [06]   | `--)`    | Dotted, open arrow   | Async callback      |
|  [07]   | `-x`     | Solid, X end         | Error/destroy       |
|  [08]   | `--x`    | Dotted, X end        | Async failure       |
|  [09]   | `<<->>>` | Bidirectional solid  | Duplex sync (v11+)  |
|  [10]   | `<<-->>` | Bidirectional dotted | Duplex async (v11+) |

**Format:** `Sender->>Receiver: Message text`—escaping: `#35;` (hash), `#59;` (semicolon), ` ` (newline).
**Activation:** `->>+B` (activate), `-->>-B` (deactivate); or explicit `activate B`, `deactivate B`.
**Notes:** `note right of A: text`, `note left of A: text`, `note over A: text`, `note over A,B: spans`.

[CRITICAL] Reserved word `end` in messages wraps as `(end)`, `[end]`, `{end}`.

### [1.3]-[CONTROL_FLOW]

| [INDEX] | [BLOCK]  | [SYNTAX]                                    | [PURPOSE]                  |
| :-----: | -------- | ------------------------------------------- | -------------------------- |
|  [01]   | loop     | `loop Condition` ... `end`                  | Iteration                  |
|  [02]   | alt      | `alt Case1` ... `else Case2` ... `end`      | Conditional (chain `else`) |
|  [03]   | opt      | `opt Condition` ... `end`                   | Optional execution         |
|  [04]   | par      | `par Label1` ... `and Label2` ... `end`     | Parallel (chain `and`)     |
|  [05]   | critical | `critical Label` ... `option Alt` ... `end` | Mutex with fallback        |
|  [06]   | break    | `break Condition` ... `end`                 | Early exit/exception       |
|  [07]   | rect     | `rect rgb(r,g,b)` ... `end`                 | Visual highlight only      |

All blocks nest arbitrarily; multiple `else`, `and`, `option` clauses chain within single block.

```
critical Establish connection
    Service->>DB: connect
option Network timeout
    Service->>Service: Log error
option Credentials rejected
    Service->>Service: Log auth error
end

break When process fails
    API->>Consumer: show failure
end
```

### [1.4]-[FEATURES]

**Autonumber:** `autonumber`—placed after `sequenceDiagram`, before first message; no offset/increment control.
**Links:** `link A: Label @ URL` (single), `links A: {"Label1": "URL1", "Label2": "URL2"}` (multi)—placed after participant declarations; `participant` compatible only; `actor` has known issues.

## [02]-[JOURNEY]

### [2.1]-[SYNTAX]

**Structure:** `journey` → `title Label` → `section Phase` → `Task: score: Actor1, Actor2`.

| [INDEX] | [SCORE] | [SENTIMENT]   | [COLOR]     |
| :-----: | :-----: | ------------- | ----------- |
|  [01]   |    1    | Very poor     | Red         |
|  [02]   |    2    | Below average | Orange      |
|  [03]   |    3    | Neutral       | Yellow      |
|  [04]   |    4    | Good          | Light green |
|  [05]   |    5    | Excellent     | Green       |

**Actors:** Comma-separated; no declaration needed.
**Sections:** `section Phase Name` groups tasks.

```
journey
    title User Onboarding
    section Discovery
        Visit homepage: 5: User
        Read features: 4: User
    section Signup
        Fill form: 3: User
        Verify email: 2: User, System
    section Activation
        Complete tutorial: 4: User
        First success: 5: User
```
**Theming:** Variables `fillType0`-`fillType9` (sections), `titleColor`/`titleFontFamily`/`titleFontSize` (v11+); actor colors theme-dependent—use `themeCSS` for overrides.

## [03]-[CONFIG]

Comments via `%% text` (single-line only, own line).

### [3.1]-[SEQUENCE_CONFIG]

| [INDEX] | [KEY]                    | [TYPE]  | [DEFAULT] | [EFFECT]                                 |
| :-----: | ------------------------ | ------- | :-------: | ---------------------------------------- |
|  [01]   | `mirrorActors`           | boolean |   true    | Duplicate actors at bottom               |
|  [02]   | `showSequenceNumbers`    | boolean |   false   | Auto-number messages                     |
|  [03]   | `actorMargin`            | number  |    50     | Horizontal actor spacing                 |
|  [04]   | `messageMargin`          | number  |    35     | Vertical message spacing                 |
|  [05]   | `boxMargin`              | number  |    10     | Box group margin                         |
|  [06]   | `boxTextMargin`          | number  |     5     | Text margin inside boxes                 |
|  [07]   | `noteMargin`             | number  |    10     | Note offset                              |
|  [08]   | `width`                  | number  |    150    | Actor box width                          |
|  [09]   | `height`                 | number  |    50     | Actor box height                         |
|  [10]   | `activationWidth`        | number  |    10     | Activation bar width                     |
|  [11]   | `hideUnusedParticipants` | boolean |   false   | Omit declared actors with zero messages  |
|  [12]   | `messageAlign`           | string  |  center   | Multiline alignment: left, center, right |
|  [13]   | `rightAngles`            | boolean |   false   | 90° message corners vs curves            |
|  [14]   | `wrap`                   | boolean |   false   | Auto-wrap labels                         |
|  [15]   | `wrapPadding`            | number  |    10     | Wrap padding                             |
|  [16]   | `diagramMarginX`         | number  |    50     | Horizontal diagram margin                |
|  [17]   | `diagramMarginY`         | number  |    10     | Vertical diagram margin                  |
|  [18]   | `forceMenus`             | boolean |   false   | Force popup menus visible                |
|  [19]   | `bottomMarginAdj`        | number  |     1     | Bottom edge extension                    |

**Font Properties:** Pattern `{prefix}FontSize`, `{prefix}FontFamily`, `{prefix}FontWeight`.

| [INDEX] | [PREFIX]  | [SIZE_DEFAULT] | [APPLIES_TO]       |
| :-----: | --------- | :------------: | ------------------ |
|  [01]   | `actor`   |       14       | Participant labels |
|  [02]   | `message` |       16       | Message text       |
|  [03]   | `note`    |       14       | Note content       |

### [3.2]-[JOURNEY_CONFIG]

| [INDEX] | [KEY]         | [TYPE]  | [DEFAULT] | [EFFECT]               |
| :-----: | ------------- | ------- | :-------: | ---------------------- |
|  [01]   | `useMaxWidth` | boolean |   true    | Constrain to container |
|  [02]   | `padding`     | number  |    10     | Diagram padding        |

[REFERENCE] Interaction validation: [→validation.md§05](./validation.md#05-interaction_diagrams)
