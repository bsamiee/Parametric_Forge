# [GRAMMAR]

Mechanical link, shape, and container grammar spans every stroke family, endpoint marker, registered shape, and container form. What a mark asserts is the construction reference's law; appearance work is the theming reference's optional property.

## [01]-[EDGES]

Flowchart endpoint matrix crosses the stroke family with the endpoint marker. Every cell is a working link; an open form omits the arrowhead, a marker on the left mirrors the right.

| [INDEX] | [STROKE]  | [OPEN]    | [POINT]    | [CIRCLE]   | [CROSS]    | [POINT_BOTH] | [CIRCLE_BOTH] | [CROSS_BOTH] |
| :-----: | :-------- | :-------- | :--------- | :--------- | :--------- | :----------- | :------------ | :----------- |
|  [01]   | Normal    | `A --- B` | `A --> B`  | `A --o B`  | `A --x B`  | `A <--> B`   | `A o--o B`    | `A x--x B`   |
|  [02]   | Thick     | `A === B` | `A ==> B`  | `A ==o B`  | `A ==x B`  | `A <==> B`   | `A o==o B`    | `A x==x B`   |
|  [03]   | Dotted    | `A -.- B` | `A -.-> B` | `A -.-o B` | `A -.-x B` | `A <-.-> B`  | `A o-.-o B`   | `A x-.-x B`  |
|  [04]   | Invisible | `A ~~~ B` | —          | —          | —          | —            | —             | —            |

Extra dash, equals, or dot characters raise the minimum rank span; the renderer may still lengthen a link to satisfy layout, and the span caps at 10. With a middle label the extra characters sit right of the label: `A -- text ---> B`.

| [INDEX] | [NORMAL]    | [THICK]     | [DOTTED]     |
| :-----: | :---------- | :---------- | :----------- |
|  [01]   | `A --> B`   | `A ==> B`   | `A -.-> B`   |
|  [02]   | `A ---> B`  | `A ===> B`  | `A -..-> B`  |
|  [03]   | `A ----> B` | `A ====> B` | `A -...-> B` |

Labels attach as a pipe pair or a middle segment on any stroke family:

| [INDEX] | [FORM]               | [SYNTAX]           |
| :-----: | :------------------- | :----------------- |
|  [01]   | Pipe on arrow        | `A -->\|text\| B`  |
|  [02]   | Middle on arrow      | `A -- text --> B`  |
|  [03]   | Pipe on open link    | `A ---\|text\| B`  |
|  [04]   | Middle on open link  | `A -- text --- B`  |
|  [05]   | Middle on dotted     | `A -. text .-> B`  |
|  [06]   | Middle on thick      | `A == text ==> B`  |
|  [07]   | Bidirectional thick  | `A <== text ==> B` |
|  [08]   | Bidirectional dotted | `A <-. text .-> B` |

A closing `o` or `x` fused to the next id is lexed as an edge marker, not the id's first character.

| [INDEX] | [WRITTEN] | [PARSED_AS]        | [FIX]                      |
| :-----: | :-------- | :----------------- | :------------------------- |
|  [01]   | `A---oB`  | circle end, id `B` | `A--- oB` or capitalize id |
|  [02]   | `A---xB`  | cross end, id `B`  | `A--- xB` or capitalize id |

An edge id names one edge for behavior metadata: `A e1@--> B` then a metadata block on the id. Metadata blocks own animate, animation, and curve; when an edge is modified more than once the last modification wins.

| [INDEX] | [METADATA]               | [EFFECT]                                                                     |
| :-----: | :----------------------- | :--------------------------------------------------------------------------- |
|  [01]   | `e1@{ animate: true }`   | Toggles edge animation.                                                      |
|  [02]   | `e1@{ animation: fast }` | Fast preset; `slow` is the slow preset.                                      |
|  [03]   | `e1@{ curve: <value> }`  | Per-edge spline from the documented curve set, overriding the diagram curve. |

Sequence lines carry the stroke shape in the arrow token itself, and grouped backgrounds live in containers.

| [INDEX] | [FAMILY]      | [SOLID]   | [DOTTED]   |
| :-----: | :------------ | :-------- | :--------- |
|  [01]   | Line          | `A->B`    | `A-->B`    |
|  [02]   | Arrow         | `A->>B`   | `A-->>B`   |
|  [03]   | Cross         | `A-xB`    | `A--xB`    |
|  [04]   | Async         | `A-)B`    | `A--)B`    |
|  [05]   | Bidirectional | `A<<->>B` | `A<<-->>B` |

Activation shorthand fuses to the arrow: `A->>+B` opens an activation, `B-->>-A` closes it; every `+` balances a `-`.

State transitions take four forms and carry no per-transition metadata route: `s1 --> s2`, labeled `s1 --> s2: label`, entry `[*] --> s1`, exit `s1 --> [*]`.

ER relation lines encode strength through the stroke: `--` is identifying, `..` is non-identifying, as in `CUSTOMER \|\|--o{ ORDER : places` against `CUSTOMER \|\|..o{ ORDER : places`.

Class relations pair an endpoint marker with a solid `--` or dashed `..` line.

| [INDEX] | [RELATION]  | [SYNTAX]                  |
| :-----: | :---------- | :------------------------ |
|  [01]   | Inheritance | `Animal <\|-- Duck`       |
|  [02]   | Composition | `Vehicle *-- Wheel`       |
|  [03]   | Aggregation | `Department o-- Employee` |
|  [04]   | Association | `Student --> Course`      |
|  [05]   | Dependency  | `Order ..> Payment`       |
|  [06]   | Realization | `Service ..\|> Impl`      |
|  [07]   | Solid link  | `A -- B`                  |
|  [08]   | Dashed link | `A .. B`                  |

A reverse form places the marker on the opposite end (`Duck --\|> Animal`); the grammar admits a marker on both ends of one line — `Animal <\|--\|> Zebra`, `A *--o B`, `C <..> D` — and a lollipop interface reads `bar ()-- foo`.

## [02]-[SHAPES]

`A@{ shape: <name> }` selects a registered shape by canonical short name or a public alias; the alias resolves to the canonical name, and an unknown name is rejected. This registry is the vocabulary.

| [INDEX] | [SHAPE]      | [ALIASES]                                                        | [ROLE]                |
| :-----: | :----------- | :--------------------------------------------------------------- | :-------------------- |
|  [01]   | `rect`       | `proc`, `process`, `rectangle`                                   | process               |
|  [02]   | `rounded`    | `event`                                                          | rounded event         |
|  [03]   | `stadium`    | `terminal`, `pill`                                               | terminal point        |
|  [04]   | `fr-rect`    | `subprocess`, `subproc`, `framed-rectangle`, `subroutine`        | subprocess            |
|  [05]   | `cyl`        | `db`, `database`, `cylinder`                                     | database              |
|  [06]   | `datastore`  | `data-store`                                                     | data store            |
|  [07]   | `circle`     | `circ`                                                           | start                 |
|  [08]   | `bang`       | none                                                             | bang                  |
|  [09]   | `cloud`      | none                                                             | cloud                 |
|  [10]   | `diam`       | `decision`, `diamond`, `question`                                | decision              |
|  [11]   | `hex`        | `hexagon`, `prepare`                                             | prepare conditional   |
|  [12]   | `lean-r`     | `lean-right`, `in-out`                                           | data input/output     |
|  [13]   | `lean-l`     | `lean-left`, `out-in`                                            | data input/output     |
|  [14]   | `trap-b`     | `priority`, `trapezoid-bottom`, `trapezoid`                      | priority action       |
|  [15]   | `trap-t`     | `manual`, `trapezoid-top`, `inv-trapezoid`                       | manual operation      |
|  [16]   | `dbl-circ`   | `double-circle`                                                  | stop                  |
|  [17]   | `text`       | none                                                             | text block            |
|  [18]   | `notch-rect` | `card`, `notched-rectangle`                                      | card                  |
|  [19]   | `lin-rect`   | `lined-rectangle`, `lined-process`, `lin-proc`, `shaded-process` | lined process         |
|  [20]   | `sm-circ`    | `start`, `small-circle`                                          | start                 |
|  [21]   | `fr-circ`    | `stop`, `framed-circle`                                          | stop                  |
|  [22]   | `fork`       | `join`                                                           | fork/join             |
|  [23]   | `hourglass`  | `collate`                                                        | collate               |
|  [24]   | `brace`      | `comment`, `brace-l`                                             | comment               |
|  [25]   | `brace-r`    | none                                                             | comment right         |
|  [26]   | `braces`     | none                                                             | braces both sides     |
|  [27]   | `bolt`       | `com-link`, `lightning-bolt`                                     | com link              |
|  [28]   | `doc`        | `document`                                                       | document              |
|  [29]   | `delay`      | `half-rounded-rectangle`                                         | delay                 |
|  [30]   | `h-cyl`      | `das`, `horizontal-cylinder`                                     | direct access storage |
|  [31]   | `lin-cyl`    | `disk`, `lined-cylinder`                                         | disk storage          |
|  [32]   | `curv-trap`  | `curved-trapezoid`, `display`                                    | display               |
|  [33]   | `div-rect`   | `div-proc`, `divided-rectangle`, `divided-process`               | divided process       |
|  [34]   | `tri`        | `extract`, `triangle`                                            | extract               |
|  [35]   | `win-pane`   | `internal-storage`, `window-pane`                                | internal storage      |
|  [36]   | `f-circ`     | `junction`, `filled-circle`                                      | junction              |
|  [37]   | `notch-pent` | `loop-limit`, `notched-pentagon`                                 | loop limit            |
|  [38]   | `flip-tri`   | `manual-file`, `flipped-triangle`                                | manual file           |
|  [39]   | `sl-rect`    | `manual-input`, `sloped-rectangle`                               | manual input          |
|  [40]   | `docs`       | `documents`, `st-doc`, `stacked-document`                        | multi-document        |
|  [41]   | `st-rect`    | `procs`, `processes`, `stacked-rectangle`                        | multi-process         |
|  [42]   | `bow-rect`   | `stored-data`, `bow-tie-rectangle`                               | stored data           |
|  [43]   | `cross-circ` | `summary`, `crossed-circle`                                      | summary               |
|  [44]   | `tag-doc`    | `tagged-document`                                                | tagged document       |
|  [45]   | `tag-rect`   | `tagged-rectangle`, `tag-proc`, `tagged-process`                 | tagged process        |
|  [46]   | `flag`       | `paper-tape`                                                     | paper tape            |
|  [47]   | `odd`        | none                                                             | odd                   |
|  [48]   | `lin-doc`    | `lined-document`                                                 | lined document        |

Classic bracket forms are shorthands over that registry.

| [INDEX] | [SHORTHAND]   | [SHAPE]    |
| :-----: | :------------ | :--------- |
|  [01]   | `A[Text]`     | `rect`     |
|  [02]   | `A(Text)`     | `rounded`  |
|  [03]   | `A([Text])`   | `stadium`  |
|  [04]   | `A[[Text]]`   | `fr-rect`  |
|  [05]   | `A[(Text)]`   | `cyl`      |
|  [06]   | `A((Text))`   | `circle`   |
|  [07]   | `A>Text]`     | `odd`      |
|  [08]   | `A{Text}`     | `diam`     |
|  [09]   | `A{{Text}}`   | `hex`      |
|  [10]   | `A[/Text/]`   | `lean-r`   |
|  [11]   | `A[\Text\]`   | `lean-l`   |
|  [12]   | `A[/Text\]`   | `trap-b`   |
|  [13]   | `A[\Text/]`   | `trap-t`   |
|  [14]   | `A(((Text)))` | `dbl-circ` |

Icon and image nodes are special shapes carrying their own parameter set; the icon pack registers at the host, never in the fence.

| [INDEX] | [ICON_KEY] | [VALUES]                                                 |
| :-----: | :--------- | :------------------------------------------------------- |
|  [01]   | `icon`     | Registered icon name such as `fa:user`.                  |
|  [02]   | `form`     | `square`, `circle`, `rounded`; omitted renders unframed. |
|  [03]   | `label`    | Text label.                                              |
|  [04]   | `pos`      | `t` or `b`; default bottom.                              |
|  [05]   | `h`        | Height; default and minimum 48.                          |

| [INDEX] | [IMAGE_KEY]  | [VALUES]                                                 |
| :-----: | :----------- | :------------------------------------------------------- |
|  [01]   | `img`        | Image URL.                                               |
|  [02]   | `label`      | Text label.                                              |
|  [03]   | `pos`        | `t` or `b`; default bottom.                              |
|  [04]   | `w`          | Image width.                                             |
|  [05]   | `h`          | Image height.                                            |
|  [06]   | `constraint` | `on` or `off`; default off, `on` preserves aspect ratio. |

A metadata block also accepts `label` to override the bracket text, and the `text` shape renders a borderless label-only node.

## [03]-[CONTAINERS]

A subgraph names its id and title as `subgraph id [Title]`, nests, and takes an inner `direction`; that inner direction is dropped and inherited from the parent the moment any member node links outside the block.

An edge endpoint may name a subgraph id: under ELK the arrowhead lands on the cluster boundary, so one labeled edge onto a layer replaces a per-member fan.

A fan-to-foundation shape — N upper tiers composing one shared base — resolves by edge truth: a permission or law diagram consolidates the fan into one demonstrative dashed rail onto the base boundary; an import-truth diagram draws every real import as a solid edge carrying its sourced-type label at the named member, falling to the cluster boundary only where sourcing names no member. A dashed edge standing for several imports fabricates, and `mergeEdges` never substitutes for either move — it fuses routing corridors, not semantics.

Sequence containers group structurally: `box <name> ... end` wraps in-process participants (`box transparent Name` is the colorless form), and `rect` blocks nest to mark an owned region — `rect` grammar embeds its color argument. State composites nest with a per-composite `direction`; class `namespace` groups by ownership; block `block:id:span ... end` holds its own `columns`.
