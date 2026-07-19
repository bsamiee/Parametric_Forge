# [SYNTAX_CORE]

Advanced grammar for flowchart, sequence, state, class, and ER; baseline node, edge, marker, and visibility syntax is assumed, never restated.

## [01]-[FLOWCHART]

`@{ shape: name }` form and aliases resolve to canonical names (`database` = `cyl`). Complete shape registry with its aliases is the styling reference's property.

An edge ID names one edge for animation and curve, never stroke: `A e1@--> B` then `e1@{ animate: true }` or `e1@{ animation: fast }`; per-edge curves through `e1@{ curve: linear }`. An edge ID is also a `classDef` target — `classDef pulse stroke:#FF79C6,stroke-dasharray:4 6` then `class e1 pulse` styles the edge stroke through the class system. Curve roster, the `linkStyle` dash-animation mechanics, fan-out, invisible links, and rank-span dashes are the styling reference's property. `datastore` (alias `data-store`) joins the shape registry from mermaid 11.15 as its own persistence shape beside `cyl`.

Icon and image shapes: `A@{ icon: "fa:user", form: "square", label: "User", pos: "t", h: 60 }` and `B@{ img: "<url>", w: 80, h: 60, constraint: "on" }`; `form` is `square`, `circle`, or `rounded` and `pos` is `t` or `b`; `constraint: on` locks aspect ratio, and an image shape distorts its node box without it. An icon resolves only against a pack registered at the renderer, never in frontmatter. Markdown strings and KaTeX (flowchart and sequence only) compose on the same node:

```mermaid
---
config:
  theme: base
  look: classic
  layout: elk
  flowchart:
    curve: linear
    padding: 25
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    background: "#282A36"
    primaryColor: "#44475A"
    primaryTextColor: "#F8F8F2"
    primaryBorderColor: "#BD93F9"
    mainBkg: "#44475A"
    nodeBorder: "#BD93F9"
    lineColor: "#FF79C6"
    textColor: "#F8F8F2"
    titleColor: "#D6BCFA"
    clusterBkg: "#21222C"
    clusterBorder: "#D6BCFA"
    edgeLabelBackground: "#21222C"
    labelBackgroundColor: "#21222C"
  themeCSS: ".nodeLabel{font-size:13px;font-weight:500}.edgeLabel{font-size:12px;font-weight:500}.cluster-label .nodeLabel{font-size:13.5px;font-weight:700;letter-spacing:.08em}.edge-thickness-normal{stroke-width:2px}.edge-thickness-thick{stroke-width:3px}.edge-pattern-dashed,.edge-pattern-dotted{stroke-width:1.5px;stroke-dasharray:4 6}.node rect,.node circle,.node polygon,.node path,.node .outer-path{stroke-width:1.5px;filter:none!important}.cluster rect{stroke-width:1px!important;stroke-dasharray:5 4!important;filter:none!important}.marker path{transform:scale(.8);transform-origin:5px 5px}.marker circle{transform:scale(.48);transform-origin:5px 5px}.edgeLabel rect{transform-box:fill-box;transform-origin:center;transform:scale(1.1,1.2)}"
---
flowchart LR
    accTitle: Flowchart metadata demo
    accDescr: A row store extracted, normalized inside the transform stage, scored with a fault rail converging on quarantine, exercising shape metadata, markdown labels, KaTeX, fan-out, and an animated edge id.
    Store@{ shape: cyl, label: "Row store" } --> Extract@{ shape: lean-r, label: "Extract" }
    subgraph stage[TRANSFORM STAGE]
        direction LR
        Extract --> Norm("`normalize rows`")
        Norm e1@--> Score["$$\sigma = \sqrt{Var}$$"]
        Norm -.->|"trace"| Audit@{ shape: doc, label: "Audit log" }
    end
    Score --> Gate{Fit?}
    Gate -->|"yes"| Publish@{ shape: stadium, label: "Publish" }
    Gate -->|"no"| Quarantine@{ shape: notch-rect, label: "Quarantine" }
    Extract -- "schema fault" --x Quarantine
    Publish --> Feed & Archive
    e1@{ animate: true }
    classDef primary fill:#44475A,stroke:#FF79C6,color:#F8F8F2
    classDef data fill:#FFB86CBF,stroke:#FFB86C,color:#282A36
    classDef boundary fill:#282A36,stroke:#BD93F9,color:#F8F8F2
    classDef error fill:#FF555580,stroke:#FF5555,color:#F8F8F2
    classDef annotation fill:#21222C,stroke:#6272A4,color:#F8F8F2
    class Extract,Norm,Gate primary
    class Store,Archive data
    class Score,Publish,Feed boundary
    class Quarantine error
    class Audit annotation
    linkStyle 3 stroke:#6272A4,color:#F8F8F2,stroke-width:1.5px,stroke-dasharray:4 6
    linkStyle 5 stroke:#50FA7B,color:#F8F8F2
    linkStyle 6,7 stroke:#FF5555,stroke-width:3px,color:#F8F8F2
```

`markdownAutoWrap: false` stops auto-wrap on markdown labels; edge labels take math as `|"$$\sqrt{x+3}$$"|`. `@{ label: "text" }` overrides the bracket text, and the `text` shape renders a borderless label-only node.

[GOTCHAS]:
- Reserved IDs `end`, `subgraph`, `class`, `graph` need quoting or capitalization; `default` is reserved only in `classDef default` and `linkStyle default` position.
- A space inside `A [txt]` breaks the node.
- Markdown strings are inert inside `@{ label: ... }` metadata — backtick labels ride the classic bracket forms.
- Markdown and `$$math$$` in one label break together, and `<br/>` dies inside a math label — one channel per label.
- `htmlLabels: false` strips backtick text and entity codes.
- A node and an edge sharing one ID silently kills the render.
- KaTeX renders only where the host loads it, and its labels ride `foreignObject` — proof rasters come from the mmdc/Chromium lane, never a pure-SVG rasterizer.

## [02]-[SEQUENCE]

`-)` is the async send and `--)` the async dotted send; the full arrow matrix — line, arrow, cross, async, bidirectional, solid and dotted — is the styling reference's edge table.

Typed participants carry a UML stereotype (`type` values `boundary`, `control`, `entity`, `database`, `queue`, `collections`) with an alias through exactly one channel — the metadata `alias` key or the `as` clause, never both fused on one declaration. Aliasing, activation, and the create/destroy lifecycle compose:

```mermaid
---
config:
  theme: base
  look: classic
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    background: "#282A36"
    primaryColor: "#44475A"
    primaryTextColor: "#F8F8F2"
    actorBkg: "#44475A"
    actorBorder: "#BD93F9"
    actorTextColor: "#F8F8F2"
    actorLineColor: "#6272A4"
    signalColor: "#FF79C6"
    signalTextColor: "#F8F8F2"
    messageTextColor: "#F8F8F2"
    sequenceNumberColor: "#282A36"
    activationBkgColor: "#44475A"
    activationBorderColor: "#BD93F9"
    noteBkgColor: "#44475A"
    noteBorderColor: "#6272A4"
    noteTextColor: "#F8F8F2"
    labelBoxBkgColor: "#21222C"
    labelBoxBorderColor: "#D6BCFA"
    labelTextColor: "#F8F8F2"
    loopTextColor: "#F8F8F2"
  themeCSS: "text.actor tspan{font-size:13px;font-weight:600}.messageText{font-size:12px;font-weight:500}.noteText{font-size:12px}.loopText,.labelText{font-size:12px;font-weight:500}.messageLine0{stroke-width:2px}.messageLine1{stroke-width:1.5px;stroke-dasharray:4 6}.actor{stroke-width:1.5px}rect.actor{filter:none!important}[id$='-filled-head'] path{fill:#FF79C6;stroke:#FF79C6}[id$='TopArrowHead'] path,[id$='BottomArrowHead'] path{stroke:#FF79C6}"
---
sequenceDiagram
    accTitle: Sequence lifecycle demo
    accDescr: An API querying a user database inside one process while warming a created cache participant that answers, misses once, and is destroyed on eviction.
    autonumber
    box rgb(33, 34, 44) QUERY PROCESS
        participant API as Public API
        participant DB@{ type: database, alias: "User Database" }
    end
    Note over API,DB: RowQuery { keys, page }
    API->>+DB: query rows
    DB-->>-API: row batch
    create participant Cache
    API->>+Cache: warm(rows)
    Cache-->>-API: ready
    alt cache hit
        API->>Cache: read(key)
        Cache-->>API: row
    else cache miss
        API->>Cache: read(key)
        Cache--)API: miss
        API->>DB: query row
    end
    destroy Cache
    API-xCache: evict
```

Lifecycle uses `create participant X`, the aliased variant `create actor D as Donald`, and `destroy X` mid-diagram. Grouping boxes wrap participants: `box rgb(33, 34, 44) Name ... end`, or `box transparent Name`, and `rect` background blocks nest. Async `-)`/`--)` sends terminate in the `-filled-head` marker, which the engine leaves unstyled — the family `themeCSS` stamps it onto the signal hue. Parallel and conditional blocks are `par ... and ... end`, `critical ... option ... end`, and `break ... end`. `autonumber` accepts a start and increment, decimal from mermaid 11.15: `autonumber 10.5 0.25`; `autonumber off` halts numbering, and a bare `autonumber` resumes it. A note takes a `:wrap:` or `:nowrap:` modifier as `Note over X:wrap: text`. Actor menus attach interactive links, live in interactive renderers only: `link Alice: Dashboard @ <url>` and `links Alice: {"Dashboard": "<url>"}`. KaTeX renders in participant names and messages.

[GOTCHAS]:
- Balance every `+` activation with a `-` deactivation.
- `<br/>` breaks a message line.
- Actor menus are dead in sandboxed or static hosts.
- Sequence ignores `layout` and `direction`.

## [03]-[STATE]

Composite states nest a per-composite `direction`, and a `--` separator splits concurrency regions inside one composite:

```mermaid
---
config:
  theme: base
  look: classic
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    background: "#282A36"
    primaryColor: "#44475A"
    primaryTextColor: "#F8F8F2"
    primaryBorderColor: "#BD93F9"
    mainBkg: "#44475A"
    nodeBorder: "#BD93F9"
    lineColor: "#FF79C6"
    textColor: "#F8F8F2"
    titleColor: "#D6BCFA"
    clusterBkg: "#21222C"
    clusterBorder: "#D6BCFA"
    compositeBackground: "#21222C"
    compositeTitleBackground: "#282A36"
    compositeBorder: "#D6BCFA"
    altBackground: "#282A36"
    edgeLabelBackground: "#21222C"
    labelBackgroundColor: "#21222C"
  themeCSS: ".nodeLabel{font-size:13px;font-weight:500}.edgeLabel{font-size:12px;font-weight:500}.cluster-label .nodeLabel{font-size:13.5px;font-weight:700;letter-spacing:.08em;color:#D6BCFA}.transition{stroke-width:2px}.note-edge{stroke-width:1.5px}.node rect,.node circle,.node path,.node .outer-path{stroke-width:1.5px;filter:none!important}.statediagram-cluster rect.outer{stroke:#D6BCFA;stroke-width:1px!important;stroke-dasharray:5 4}.statediagram-state rect.divider{stroke:#D6BCFA;stroke-width:1px;stroke-dasharray:5 4;fill:#282A36}[id*='barbEnd'] path{fill:#FF79C6;stroke:#FF79C6;transform:scale(.4);transform-origin:14px 7px}.state-start{r:3.4px;fill:#FF79C6;stroke:#FF79C6}.node[id*='_end'] .outer-path{transform-box:fill-box;transform-origin:center;transform:scale(.48)}.edgeLabel rect{transform-box:fill-box;transform-origin:center;transform:scale(1.1,1.2)}"
---
stateDiagram-v2
    accTitle: Composite state demo
    accDescr: A ready worker routed through a choice into a composite running state with concurrent exec and watch regions, a bounded fault recovery loop, and one terminal.
    direction LR
    [*] --> Idle
    state Pick <<choice>>
    Idle --> Pick: start
    Pick --> Run: [slots > 0]
    Pick --> Idle: [slots == 0]
    state "RUN" as Run {
      direction TB
      [*] --> Exec
      Exec --> Flush: drain
      Flush --> [*]: drained
      --
      [*] --> Watch
      Watch --> [*]: stop
    }
    Run --> Faulted: fault
    Faulted --> Idle: recover [tries < max]
    Faulted --> Stopped: abort [tries == max]
    Run --> Stopped: stop
    Stopped --> [*]
    classDef recessed fill:#21222C,stroke:#6272A4,color:#F8F8F2
    classDef error fill:#FF555580,stroke:#FF5555,color:#F8F8F2
    classDef boundary fill:#282A36,stroke:#BD93F9,color:#F8F8F2
    class Idle recessed
    class Faulted error
    class Stopped boundary
```

Pseudostates are `<<choice>>`, `<<fork>>`, and `<<join>>`. `state "long text" as S` aliases a spaced label. A `click` directive attaches an interactive link to a state.

[GOTCHAS]:
- `end` and `state` are reserved words.
- A pseudostate stereotype declared after the state's first edge reference silently drops — the state renders as a plain labeled box; `state X <<choice>>` precedes X's first use.
- State honors `layout: elk` only where the host registers the ELK loader, with no dagre fallback when it is missing — state fences omit the key and stay on the type-owned layout.

## [04]-[CLASS]

Generics use `~T~` and nest as `List~List~int~~`; commas inside a generic declaration are unsupported. A `namespace` groups classes, a bracket label renames it (`namespace Auth["Authentication Service"]`), and `class.hierarchicalNamespaces: false` flattens dotted paths:

```mermaid
---
config:
  theme: base
  look: classic
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    background: "#282A36"
    primaryColor: "#44475A"
    primaryBorderColor: "#BD93F9"
    mainBkg: "#44475A"
    nodeBorder: "#BD93F9"
    lineColor: "#FF79C6"
    classText: "#F8F8F2"
    textColor: "#F8F8F2"
    titleColor: "#D6BCFA"
    clusterBkg: "#21222C"
    clusterBorder: "#D6BCFA"
    edgeLabelBackground: "#21222C"
    labelBackgroundColor: "#21222C"
    noteBkgColor: "#FFD86654"
    noteBorderColor: "#FFD866"
    noteTextColor: "#F8F8F2"
  themeCSS: ".nodeLabel{font-size:13px;font-weight:500}.edgeLabel{font-size:12px;font-weight:500}.classTitle{font-size:13px;font-weight:600}.cluster-label .nodeLabel,.cluster-label text{font-size:13.5px;font-weight:700;letter-spacing:.08em}.noteLabel .nodeLabel{font-size:12px}.relation{stroke-width:2px}.edge-pattern-dashed,.edge-pattern-dotted{stroke-width:1.5px;stroke-dasharray:4 6}.divider{stroke-width:1px}.node rect,.node path{stroke-width:1.5px;filter:none!important}.cluster rect{stroke-width:1px!important;stroke-dasharray:5 4!important;filter:none!important}.marker path{transform:scale(.8);transform-origin:5px 5px}"
---
classDiagram
    accTitle: Namespace and generics demo
    accDescr: A generic user service implementing a session port inside its namespace, composing a token store, consumed by a developer through a lollipop interface.
    namespace Auth {
        class UserService~T~ {
            +login() Result~T~
            +roles() List~List~int~~
        }
        class SessionPort {
            <<interface>>
            +issue() Token
        }
        class TokenStore {
            -rotate() void
        }
    }
    namespace Company {
        class Developer {
            +consume() void
        }
    }
    UserService ..|> SessionPort : implements
    UserService *-- TokenStore : owns
    AuthPort ()-- UserService
    Developer ..> UserService : consumes
    note for TokenStore "rotation is invariant"
```

Lollipop interfaces are `bar ()-- foo`. `note for Shape "text"` attaches a note, and `direction RL` reorients. Two hyperlink forms carry tooltips: `link Shape "<url>" "tooltip"` renders a static anchor, `click Shape href "<url>" "tooltip"` fires only in interactive renderers.

[GOTCHAS]:
- A generic suffix drops in references — two classes differing only by generic collide.
- Notes and namespaces take themes but are not individually styleable — the note chip themes through `noteBkgColor`/`noteBorderColor`/`noteTextColor` and namespaces through `clusterBorder`/`titleColor`.
- A member-less `class Foo` renders empty members hidden under the unified renderer.
- `style`, `classDef`, and `click` bind to a generic class by its bare name — `UserService`, never `UserService~T~`.

## [05]-[ER]

ER attributes extend `type name key`: `string? middleName` marks a nullable type from mermaid 11.16, `string[] parts` an array, and `PK, FK` a compound key; a backtick-escaped name carries dots, and an entity alias quotes a spaced name. Keyed and commented attributes with a crow's-foot join compose:

```mermaid
---
config:
  theme: base
  look: classic
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    background: "#282A36"
    primaryColor: "#44475A"
    primaryTextColor: "#F8F8F2"
    primaryBorderColor: "#BD93F9"
    tertiaryColor: "#21222C"
    mainBkg: "#44475A"
    nodeBorder: "#BD93F9"
    lineColor: "#FF79C6"
    textColor: "#F8F8F2"
    edgeLabelBackground: "#21222C"
    attributeBackgroundColorOdd: "#282A36"
    attributeBackgroundColorEven: "#21222C"
  themeCSS: ".nodeLabel{font-size:12px}.name .nodeLabel{font-size:13px;font-weight:600}.edgeLabel .nodeLabel{font-size:12px;font-weight:500}.relationshipLine{stroke-width:2px}.edge-pattern-dashed{stroke-width:1.5px;stroke-dasharray:6 6}.marker path,.marker circle{transform:scale(.8);transform-origin:5px 5px}.marker circle{fill:#282A36}.node rect,.node path{stroke-width:1.5px;filter:none!important}.er.entityBox{filter:none}"
---
erDiagram
    accTitle: ER attribute grammar demo
    accDescr: A person holding customer accounts whose grants resolve through a junction onto an externally owned role registry.
    direction LR
    p["Person"] {
        string driversLicense PK "license number"
        string firstName
        string middleName
        datetime createdAt
    }
    a["Customer Account"] {
        uuid id PK
        string email UK
        string person_id FK
    }
    g["Account Grant"] {
        uuid account_id PK, FK
        uuid role_id PK, FK
    }
    r["Role Registry"] {
        uuid id PK
        string name
    }
    p only one to zero or more a : holds
    a ||--o{ g : grants
    r ||..o{ g : defines
    classDef primary fill:#44475A,stroke:#FF79C6,color:#F8F8F2
    classDef recessed fill:#21222C,stroke:#6272A4,color:#F8F8F2
    classDef external fill:#21222C,stroke:#8BE9FD,color:#8BE9FD
    class a primary
    class g recessed
    class r external
```

Word-alias cardinalities map onto the crow's-foot markers, and `to` versus `optionally to` names the identifying versus non-identifying join. Quoted entity and attribute text takes markdown and Unicode, and a multi-line attribute label breaks with `<br/>`. ER family draws relationship lines and cardinality marks from `lineColor` and composites its label backing from `tertiaryColor` — both are floor keys on every ER fence.

| [INDEX] | [ALIAS]                       | [MARKER]         |
| :-----: | :---------------------------- | :--------------- |
|  [01]   | `only one` `1`                | `\|\|` exact one |
|  [02]   | `zero or one` `one or zero`   | `\|o` optional   |
|  [03]   | `zero or more` `many(0)` `0+` | `}o` many        |
|  [04]   | `one or more` `many(1)` `1+`  | `}\|` required   |

[GOTCHAS]:
- Keys accept only `PK`, `FK`, `UK` — no Unicode or markdown in a key.
- An empty entity block `{ }` renders as a title-only entity box; reserved entity ids are `ONE`, `MANY`, and `TO`.
- Hand-drawn look and `direction` apply.
