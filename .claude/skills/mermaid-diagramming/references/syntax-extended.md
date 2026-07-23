# [SYNTAX_EXTENDED]

Diagram types beyond the five core types populate this roster — each row carries its working form and the traps that bind it in the numbered section its index names.

## [01]-[REGISTRY]

Pick a type by intent, then its section for the minimal fence and traps; rows run in section order.

| [INDEX] | [TYPE]               | [INTENT]                 |
| :-----: | :------------------- | :----------------------- |
|  [01]   | `mindmap`            | radial hierarchy         |
|  [02]   | `block`              | manual grid layout       |
|  [03]   | `journey`            | phase sentiment          |
|  [04]   | `requirementDiagram` | requirement traceability |
|  [05]   | `pie`                | part-to-whole share      |
|  [06]   | `quadrantChart`      | two-axis position map    |
|  [07]   | `sankey`             | weighted directed flow   |
|  [08]   | `xychart`            | bar or line chart        |
|  [09]   | `radar-beta`         | multivariate profile     |
|  [10]   | `gantt`              | dated schedule           |
|  [11]   | `treemap-beta`       | area-weighted hierarchy  |
|  [12]   | `C4`                 | system landscape views   |
|  [13]   | `architecture-beta`  | infrastructure groups    |
|  [14]   | `packet`             | bit-field layout         |
|  [15]   | `timeline`           | chronological periods    |
|  [16]   | `gitGraph`           | branch and merge history |
|  [17]   | `kanban`             | workflow-stage board     |
|  [18]   | `treeView-beta`      | file-tree hierarchy      |
|  [19]   | `cynefin-beta`       | decision-domain sort     |
|  [20]   | `railroad-*-beta`    | grammar syntax rails     |
|  [21]   | `swimlane-beta`      | laned process flow       |
|  [22]   | `eventmodeling`      | command-event timeline   |
|  [23]   | `venn-beta`          | set-overlap regions      |
|  [24]   | `wardley-beta`       | value-chain evolution    |
|  [25]   | `ishikawa-beta`      | cause-effect fishbone    |

`zenuml` renders sequence exchanges through an external plugin the CLI registers; it carries this registry mention alone. `UnknownDiagramError` is a host-version fact, never a fence defect: the host's mermaid predates the family, and the bundled validator against the workspace-pinned renderer is the parse proof for every row above.

## [02]-[MINDMAP]

```mermaid
---
config:
  mindmap:
    padding: 25
    maxNodeWidth: 180
---
mindmap
  root((Diagram Skill))
    [Laws]
      (One question)
      (Node law)
      (Edge law)
      (Split move)
    [Families]
      (Core five)
        Flowchart
        Sequence
      (Charts)
        Pie
        Radar
      (Betas)
        Treemap
        Venn
    [Gates]
      (Render proof)
      (Graph logic)
      (Legibility)
    [Craft]
      (Question first)
      (Staged growth)
      (Soundness audit)
```

Fence content asserts the skill decomposing into laws, families, gates, and craft to leaf depth; the family mis-handles `accTitle`/`accDescr`, so the relation sentence rides beside the fence. Root leads; consistent indentation sets depth, mixed tabs and spaces are rejected, and explicit edges are invalid. Shapes carry level — `root((...))` circle, `[...]` branch rects, `(...)` rounded topics, bare text leaves. Radial layout is cose-bilkent and owns its own edge geometry; first-level branches carry `.section-0`–`.section-N` classes in declaration order.

## [03]-[BLOCK]

```mermaid
block-beta
  columns 3
  Fence["Fence"] Parse["Parse"] Logic["Logic"]
  Layout["Layout"] Render["Render"] Proof["Proof"]
  space:3
  block:gate:3
    columns 3
    SVG["SVG"] PNG["PNG"] Cache["Cache"]
  end
  Fence --> Parse
  Parse --> Logic
  Fence --> Layout
  Layout --> Render
  Parse --> Render
  Logic --> Proof
  Render -- "emit" --> gate
  Proof --> gate
```

Fence content asserts a two-row render raster feeding a nested proof group; the family rejects `accTitle`/`accDescr` at parse, so the relation sentence rides beside the fence. `block-beta` is the portable keyword; `columns N` precedes a row, a `:n` span widens a block, `space` inserts a filler, and a nested `block:id:span ... end` holds its own `columns`. A block arrow is `blockArrowId<["Label"]>(dir)` with `dir` one of `right`, `left`, `up`, `down`, `x`, `y`, or a compound like `(x, down)`.

Links route straight from source center through a midpoint to target center with no obstacle awareness, so a committed raster links only adjacent cells — that placement discipline is the whole no-crossing law here.

## [04]-[JOURNEY]

```mermaid
journey
  accTitle: Fence authoring journey
  accDescr: An author, agent, and reviewer scored across drafting, review, and shipping a fence.
  title Fence Authoring
  section Draft
    Outline question: 5: Author
    Draft nodes: 3: Author, Agent
    Wire edges: 3: Agent
  section Review
    Render proof: 4: Agent
    Inspect PNG: 3: Reviewer
    Fix crossings: 2: Author, Agent
  section Ship
    Gate green: 4: Agent
    Commit fence: 5: Author, Reviewer
```

Scores are integers `1` through `5`; a task belongs under a `section`, an actor needs no declaration, and an out-of-range score is invalid.

## [05]-[REQUIREMENT_DIAGRAM]

```mermaid
---
config:
  htmlLabels: false
  requirement:
    rect_min_width: 190
    rect_min_height: 80
    rect_padding: 12
---
requirementDiagram
  accTitle: Render requirement trace
  accDescr: A render-proof requirement satisfied by the validator, verified by the corpus gate, and traced to the theming law document.
  functionalRequirement renderProof {
    id: 1.1
    text: every fence ships a render proof
    risk: Medium
    verifyMethod: Test
  }
  performanceRequirement gateBudget {
    id: 1.2
    text: corpus gate under two minutes
    risk: Low
    verifyMethod: Analysis
  }
  element validator {
    type: script
    docref: validate_mermaid
  }
  element themingLaw {
    type: doc
    docref: theming
  }
  validator - satisfies -> renderProof
  validator - verifies -> gateBudget
  renderProof <- traces - themingLaw
```

Types are `requirement`, `functionalRequirement`, `interfaceRequirement`, `performanceRequirement`, `physicalRequirement`, `designConstraint`; `risk` takes `Low`/`Medium`/`High` and `verifyMethod` takes `Analysis`/`Inspection`/`Test`/`Demonstration`. Relations `contains`, `copies`, `derives`, `satisfies`, `verifies`, `refines`, `traces` spell both `a - satisfies -> b` and `b <- traces - a`; `contains` draws solid with a crossed-circle start marker, every other relation dashed with the open-arrow end marker. `htmlLabels: false` stacks the body attributes cleanly.

## [06]-[PIE]

```mermaid
---
config:
  pie:
    textPosition: 0.7
---
pie showData
  accTitle: Render corpus share
  accDescr: Five diagram families split the committed corpus, flowchart holding the largest share.
  title Corpus Share
  "Flowchart" : 34
  "Sequence" : 22
  "State" : 18
  "ER" : 15
  "Class" : 11
```

Values sum above `0`, labels are quoted, and `showData` prints values in the legend; donut, legend position, and slice highlight compose on it, and `textPosition` places the slice percentages along the radius.

## [07]-[QUADRANT_CHART]

```mermaid
---
config:
  quadrantChart:
    pointRadius: 4
    pointTextPadding: 8
---
quadrantChart
  accTitle: Capability position map
  accDescr: Eight capabilities placed by adoption effort against payoff across promote, assess, retire, and hold quadrants.
  title Capability Positions
  x-axis Low Effort --> High Effort
  y-axis Low Payoff --> High Payoff
  quadrant-1 Assess
  quadrant-2 Promote
  quadrant-3 Retire
  quadrant-4 Hold
  Cache: [0.22, 0.78]
  Batching: [0.34, 0.86]
  Streaming: [0.66, 0.83]
  Sharding: [0.81, 0.69]
  Polling: [0.24, 0.24]
  Mirroring: [0.38, 0.16]
  Archive: [0.68, 0.30]
  Replay: [0.84, 0.21]
```

Coordinates bind to `0` through `1` and quadrants number `1` top-right counterclockwise. `pointRadius` sizes every dot and `pointTextPadding` drops each label clear below its dot — the dot never blocks its name.

## [08]-[SANKEY]

```mermaid
---
config:
  sankey:
    nodeWidth: 12
    nodePadding: 24
    width: 900
    height: 480
---
sankey

Fences,Flowchart,140
Fences,Charts,80
Flowchart,Render,90
Flowchart,Logic,50
Charts,Render,60
Charts,Logic,20
Render,Pass,120
Render,Warn,20
Render,Fail,10
Logic,Pass,50
Logic,Warn,15
Logic,Fail,5
```

Fence content asserts a corpus splitting through render and logic gates into pass, warn, and fail sinks; the family rejects `accTitle`/`accDescr` at parse, so the relation sentence rides beside the fence. `sankey` is the keyword; the body is strictly three-column CSV `source,target,value` — CSV quoting covers embedded commas, blank lines carry no separators. Config carries `nodeAlignment`, `showValues`, `prefix`/`suffix`, and the geometry knobs `nodeWidth`, `nodePadding`, `width`, and `height`.

## [09]-[XYCHART]

```mermaid
---
config:
  xyChart:
    showDataLabel: true
    showDataLabelOutsideBar: true
---
xychart
  accTitle: Corpus growth
  accDescr: Fences added per quarter as bars with the cumulative corpus size as a line overlay.
  title "Corpus Growth"
  x-axis "Quarter" ["Q1", "Q2", "Q3", "Q4", "Q5", "Q6", "Q7"]
  y-axis "Fences" 0 --> 400
  bar [42, 58, 66, 54, 71, 63, 39]
  line [42, 100 "100", 166 "166", 220 "220", 291 "291", 354 "354", 393 "393"]
```

`xychart` is the keyword; `xychart horizontal` flips orientation and each `bar` or `line` array matches the x-axis category count. Bar width derives from the category count against a fixed padding percent — width tunes by adding categories, never by a knob. `showDataLabel` prints the first declared plot's values at a size computed from bar width, so the bar plot declares first; `showDataLabelOutsideBar` lifts the values above the bars.

Inline point labels (`50 "50"`) render on `line` only — the syntax parses on `bar` while the labels silently drop — and a label omitted on a point suppresses that one chip, clearing the first-category collision where line and bar meet at the origin.

## [10]-[RADAR]

```mermaid
---
config:
  radar:
    width: 460
    height: 460
    marginLeft: 120
    marginRight: 120
    marginTop: 60
    marginBottom: 60
---
radar-beta
  accTitle: Renderer profile
  accDescr: The pinned renderer compared against the host viewer across six capability axes.
  title Renderer Profile
  axis th["Theming"], la["Layout"], gr["Grammar"], pf["Performance"], po["Portability"], va["Validation"]
  curve pinned["Pinned CLI"]{ th: 92, la: 88, gr: 90, pf: 68, po: 55, va: 85 }
  curve host["Host view"]{ th: 60, la: 55, gr: 72, pf: 90, po: 92, va: 40 }
  showLegend true
  graticule polygon
  ticks 4
  max 100
  min 0
```

`axis` names the axes, a positional curve `name["Label"]{...}` follows axis order and a keyed curve binds by axis id. Identical data across curves cancels into one pale polygon, so each curve carries distinct values — the subject-count law is the construction reference's property.

`graticule` accepts `polygon` or `circle`, and config admits `axisScaleFactor` and `curveTension`. Axis labels anchor just outside the chart radius and clip at the viewport edge — the `radar:` config margins own that clearance, and the hardcoded legend position demands short curve labels.

## [11]-[GANTT]

```mermaid
---
config:
  gantt:
    barHeight: 22
    barGap: 6
    topPadding: 60
    leftPadding: 90
---
gantt
  accTitle: Release schedule
  accDescr: Design, build, and release phases with an active draft, a critical review, and a tagged ship milestone.
  dateFormat YYYY-MM-DD
  axisFormat %b %d
  tickInterval 2day
  weekday monday
  excludes weekends
  section Design
  Spec :done, s1, 2026-06-29, 3d
  Tokens :done, s2, after s1, 2d
  section Build
  Draft :active, b1, 2026-07-03, 4d
  Wire classes :b2, after b1, 3d
  Review :crit, b3, after b2, 2d
  section Release
  Render proof :r1, after b3, 2d
  Ship :milestone, m1, after r1, 0d
```

Dates match `dateFormat`, `after`/`until` reference existing IDs, and modifiers are `done`, `active`, `crit`, `milestone`, `vert`; repeated `excludes` and `includes` entries stack. `axisFormat` with `tickInterval` own tick legibility; default daily ISO ticks overlap into an unreadable strip.

`vert` draws a full-height gate marker, an `after` list (`after a b`) converges on every named prerequisite, `weekday` anchors the tick grid, and the today rule spans the whole canvas.

## [12]-[TREEMAP]

```mermaid
---
config:
  treemap:
    showValues: true
    valueFormat: ','
---
treemap-beta
accTitle: Corpus render cost
accDescr: Render milliseconds per diagram family grouped by engine, chart families cheapest and layout-engine families dearest.
"Corpus"
    "Layout engines"
        "Flowchart": 4200
        "Architecture": 2600
        "Block": 1400
    "Type-owned"
        "Sequence": 2100
        "State": 1800
        "Class": 1500
        "ER": 1200
    "Charts"
        "XY": 900
        "Pie": 600
        "Radar": 700
    "Betas"
        "Treemap": 800
        "Packet": 400
        "Venn": 500
```

Indentation sets hierarchy and a leaf carries a numeric value; `valueFormat` formats values through d3-format grammar alongside `showValues`, and branch identity assigns in branch declaration order.

## [13]-[C4]

```mermaid
---
config:
  c4:
    c4ShapeInRow: 3
    c4ShapeMargin: 60
---
C4Context
  accTitle: Render platform landscape
  accDescr: An author using the diagram skill that renders through a pinned CLI into a proof store serving a docs site and its reader.
  title Render Platform Landscape
  Person(author, "Author", "Writes fences")
  Person_Ext(reader, "Reader", "Views docs")
  Enterprise_Boundary(platform, "Render Platform") {
    System(skill, "Diagram Skill", "Methodology and canon")
    System(cli, "Pinned CLI", "Headless renderer")
    SystemDb(proofs, "Proof Store", "Rendered SVG cache")
  }
  Boundary(web, "Docs Host") {
    System_Ext(docs, "Docs Site", "Hosts fences")
  }
  Rel(author, skill, "Authors with")
  Rel(skill, cli, "Renders through")
  Rel(cli, proofs, "Writes proofs")
  Rel(docs, proofs, "Reads proofs")
  Rel(reader, docs, "Reads")
```

Family coverage spans `C4Context`, `C4Container`, `C4Component`, `C4Dynamic`, `C4Deployment`; an alias exists before `Rel()` and named parameters take `$`. `UpdateRelStyle` offsets a relation label clear of boxes with `$offsetX`/`$offsetY`, and `c4ShapeInRow`/`c4BoundaryInRow` govern packing.

Loose shapes pack in rows above every boundary — a third lands beneath the first where relations cross — so external systems live in their own `Boundary` and boundaries pack side by side.

## [14]-[ARCHITECTURE]

```mermaid
---
config:
  architecture:
    seed: 4
    iconSize: 64
---
architecture-beta
  accTitle: Render service topology
  accDescr: An edge gateway feeding a render service pair backed by a cache and a registry database, with proof storage receiving output.
  group edge(cloud)[Edge]
  group core(cloud)[Core]
  group store(cloud)[Store]
  service gw(internet)[Gateway] in edge
  service render(server)[Render] in core
  service layout(server)[Layout] in core
  service cache(disk)[Cache] in store
  service registry(database)[Registry] in store
  gw:R --> L:render
  render:R --> L:cache
  layout:R --> L:registry
  render:B --> T:layout
  align column render layout
  align row gw render cache
  align row layout registry
  align column cache registry
```

`group` and `service` place nodes, a member declares `in group`, edge ports are `T|B|L|R`, a `junction` joins edges, a group-boundary edge takes `{group}`, and an Iconify icon resolves as `pack:name`. Layout is cytoscape fcose: port pairs and `align row|column` rows fully determine the grid, so a committed fence aligns every rank both ways for orthogonal edges — unaligned members scatter diagonally, and an `align` row fails where its order contradicts a directional-edge constraint. Junction endpoints shift arrow polygons off their lines, so junctions stay grammar for genuine multi-way joins.

Arrow size tunes only through `iconSize` — the arrow is one sixth of it — and `architecture.seed` is the deterministic lock.

## [15]-[PACKET]

```mermaid
---
config:
  packet:
    bitWidth: 24
    rowHeight: 28
---
packet
accTitle: TCP header bit layout
accDescr: TCP header fields across six 32-bit rows from source port through options.
title TCP Header
0-15: "Source Port"
16-31: "Destination Port"
32-63: "Sequence Number"
64-95: "Acknowledgment Number"
96-99: "Offset"
100-105: "Reserved"
106: "U"
107: "A"
108: "P"
109: "R"
110: "S"
111: "F"
112-127: "Window"
128-143: "Checksum"
144-159: "Urgent Pointer"
160-191: "Options and Padding"
```

`packet` is the keyword; `start-end: "name"` ranges and `+count: "name"` auto-counted fields mix under an optional `title`, blocks stay contiguous, and `accTitle`/`accDescr` are accepted. `bitWidth` and `rowHeight` size the raster.

## [16]-[TIMELINE]

```mermaid
timeline
  accTitle: Skill evolution
  accDescr: Two phases of the diagram skill from question-first method through the validation gates, each carrying its landed changes.
  title Skill Evolution
  section Foundation
    Method : One question : Staged growth
    Contract : Frontmatter : Validator
  section Gates
    Logic : Graph checks : Split law
    Render : Geometry : Proof rasters
```

A multi-event row repeats `:`, sections group periods, and timeline takes `LR`/`TD` direction headers. Family parses `accTitle`/`accDescr` while emitting neither into the SVG, so the relation sentence rides beside the fence; section classes index from `-1`, so the first section is `.section--1`.

## [17]-[GITGRAPH]

```mermaid
---
config:
  gitGraph:
    rotateCommitLabel: false
---
gitGraph LR:
  accTitle: Release branch history
  accDescr: A develop branch cut from main, a feature merged into develop, develop merged back for a tagged release, and an in-flight next branch cut after the release.
  commit id: "boot"
  commit id: "tokens"
  branch develop
  checkout develop
  commit id: "rails"
  branch feature
  checkout feature
  commit id: "elk"
  commit id: "markers"
  checkout develop
  merge feature
  commit id: "floors"
  checkout main
  merge develop tag: "v1.0"
  commit id: "hotfix" tag: "v1.0.1"
  branch next
  checkout next
  commit id: "canon"
```

Directions are `LR:`, `TB:`, `BT:`; a branch exists before checkout or merge, commit IDs stay unique, and cherry-picking a merge commit adds `parent:`. `rotateCommitLabel: false` keeps commit ids horizontal, and `.arrowN` classes index the branch declaration order.

## [18]-[KANBAN]

```mermaid
---
config:
  kanban:
    sectionWidth: 210
    ticketBaseUrl: '<ticket-url>#TICKET#'
---
kanban
  todo[Backlog]
    t1[Crossing audit]@{ ticket: MD-101, assigned: 'Agent', priority: 'High' }
    t2[Split oversized fence]@{ ticket: MD-102, assigned: 'Author', priority: 'Low' }
  wip[In Progress]
    t3[Guard vocabulary]@{ ticket: MD-103, assigned: 'Agent', priority: 'Very High' }
    t4[Padding to 25]@{ ticket: MD-104, assigned: 'Agent', priority: 'Low' }
  review[Review]
    t5[Acc directive sweep]@{ ticket: MD-105, assigned: 'Reviewer', priority: 'High' }
  done[Done]
    t6[Orphan node purge]@{ ticket: MD-106, assigned: 'Author', priority: 'Very Low' }
    t7[Elbow routing]@{ ticket: MD-107, assigned: 'Agent', priority: 'Low' }
```

Fence content asserts four queues carrying seven law cards with ticket metadata; the family mis-handles `accTitle`/`accDescr` as columns, so the relation sentence rides beside the fence. Tasks indent under columns, metadata keys are `assigned`, `ticket`, `priority`, and priorities are exactly `Very High`, `High`, `Low`, `Very Low`; `kanban.ticketBaseUrl` links each ticket by substituting the task ticket for `#TICKET#`, and column classes index from `section-1`.

## [19]-[TREEVIEW]

```mermaid
---
config:
  treeView:
    rowIndent: 14
    paddingY: 6
---
treeView-beta
accTitle: Skill tree
accDescr: The diagram skill folder with its law owners annotated.
├── references/
│   ├── methodology.md ## question and growth law
│   ├── grammar.md ## link and shape grammar
│   ├── config.md ## frontmatter law
│   └── syntax-extended.md ## 25-type registry
├── templates/
│   ├── spine.mmd.md
│   └── lifecycle.mmd.md
├── scripts/
│   └── validate_mermaid.py ## render gate
└── SKILL.md
```

TreeView parses box-drawing input, a trailing `/` marking a directory; annotations trail an entry as `:::class`, `## description`, and `icon(name)`/`icon(none)`. Config carries `rowIndent` and `paddingY`, which land directly. `showIcons`, `defaultIconPack`, `filenameIcons`, and `extensionIcons` govern icons; an unregistered icon renders as a question mark, and `highlight` is the one class name with built-in geometry.

## [20]-[CYNEFIN]

```mermaid
---
config:
  cynefin:
    seed: 7
---
cynefin-beta
  accTitle: Failure domain sort
  accDescr: Render faults sorted across the five cynefin domains with two labeled reclassifications as understanding grows.
  complex
    "Flaky layout drift"
    "Host CSS bleed"
  complicated
    "Marker scale math"
    "Contrast audit"
  clear
    "Restart renderer"
    "Pin the CLI"
  chaotic
    "Corpus-wide breakage"
  confusion
    "Unclassified fault"
  complex --> complicated : "Pattern found"
  chaotic --> clear : "Order imposed"
```

Domains `complex`, `complicated`, `clear`, `chaotic`, and `confusion` each hold quoted items, and a transition spells `domain --> domain : "label"`.

A cliff separates chaotic from clear as canonical geometry; transitions curve center to center with a fixed 15% bow and the arrow tip lands beside the target caption — engine geometry, so a committed fence keeps transitions few and lets the label ride the bow's midpoint. `cynefin.seed` pins the boundary jitter.

## [21]-[RAILROAD]

```mermaid
---
config:
  railroad:
    padding: 16
    markerRadius: 4
---
railroad-ebnf-beta
accTitle: Numeric literal grammar
accDescr: A signed decimal number production with fraction and exponent over sign, integer, and exponent rules.
title "Numeric Literal"

number = [ sign ] integer [ "." digit { digit } ] [ exponent ] ;
sign = "+" | "-" ;
integer = "0" | nonzero { digit } ;
exponent = ( "e" | "E" ) [ sign ] digit { digit } ;
```

Keyword choice selects the grammar parser — `railroad-ebnf-beta` for EBNF, `railroad-abnf-beta` for ABNF, `railroad-peg-beta` for PEG, and `railroad-beta` for Mermaid's intermediate constructors. In this EBNF dialect `? ... ?` is a special sequence, so optionality spells `[ ... ]` and repetition `{ ... }` — a postfix `?` fuses everything up to the next `?` into one special box. Terminals render quoted and nonterminals bare, so the two read as different marks; `padding` and `markerRadius` size the rails.

## [22]-[SWIMLANE]

```mermaid
---
config:
  swimlane:
    lineHops: arc
---
swimlane-beta
  accTitle: Fence review lanes
  accDescr: A fence drafted by the author, tightened by the agent, gated by the validator lane on the critical path, and proven by the renderer.
  subgraph author[AUTHOR]
    Draft([Draft fence])
    Commit([Commit])
  end
  subgraph agent[AGENT]
    Tighten[Tighten graph]
    Inspect[Inspect PNG]
  end
  subgraph validator[VALIDATOR]
    Gate{Gate?}
  end
  subgraph renderer[RENDERER]
    Render[Render proof]
  end
  Draft --> Tighten
  Tighten --> Gate
  Gate -->|pass| Render
  Gate --> Tighten
  Render --> Inspect
  Inspect --> Commit
```

A standalone diagram reusing the flowchart body under a layered orthogonal layout: every top-level `subgraph` is a lane, nodes inside it belong to it, and loose nodes fall into a synthetic unlabeled lane; `swimlane.lineHops: arc` hops edge crossings. A label on a return edge orphans away from its stroke — keep return-edge labels short or carry the fact on the target node.

## [23]-[EVENTMODELING]

```mermaid
eventmodeling
  tf 01 ui CartUI { "sku": "A1" }
  tf 02 cmd AddItem
  tf 03 evt ItemAdded `json`{ "qty": 1 }
  tf 04 rmo CartView
  tf 05 ui CheckoutUI
  tf 06 cmd Checkout
  tf 07 evt CheckedOut
  tf 08 pcr PaymentProcessor
  tf 09 evt PaymentRequested `json`{ "total": 42 }
```

Fence content asserts a cart flow from UI through commands and events into a read model and payment processor; `accTitle`/`accDescr` parse but emit nothing, so the relation sentence rides beside the fence. `tf`/`timeframe` orders frames left to right, `rf`/`resetframe` restarts the clock; kinds are `ui`, `cmd`, `evt`, `pcr` (processor), and `rmo` (read model), and an inline `{ ... }` or `` `json`{ ... } `` payload rides a frame. Relations infer from the nearest prior frame in a different lane, so declaration order draws the chain; namespaced frame ids (`stream.Name`) map to extra swimlanes.

## [24]-[VENN]

```mermaid
venn-beta
  title Corpus Coverage
  set A["Authored"] : 80
  set B["Rendered"] : 70
  set C["Validated"] : 60
  union A,B ["Proofed"] : 42
  union B,C ["Gated"] : 34
  union A,C : 26
  union A,B,C ["Canon"] : 18
```

Fence content asserts three weighted sets overlapping into labeled proof regions; the family rejects `accTitle`/`accDescr` at parse, so the relation sentence rides beside the fence. `set id["Label"] : size` declares a weighted set, `union A,B ["Label"] : size` sizes and captions an overlap, and higher-arity unions list every member.

Region captions ride the union labels at the region centroids, so overlaps read without leaders or a legend; set and intersection label sizes scale from canvas width at engine ratios.

## [25]-[WARDLEY]

```mermaid
wardley-beta
  accTitle: Render capability map
  accDescr: An author need anchored on the diagram skill whose dependencies slide from custom fences toward commodity browsers and caches.
  title Render Capability
  component Author [0.95, 0.63]
  component Skill [0.84, 0.30]
  component Fence [0.72, 0.45]
  component CLI [0.60, 0.62]
  component IconPack [0.42, 0.55]
  component Browser [0.38, 0.78]
  component Cache [0.24, 0.82]
  Author->Skill
  Skill->Fence
  Fence->CLI
  CLI->Browser
  CLI->Cache
  Fence->IconPack
  evolve IconPack 0.75
```

Coordinates are `[visibility, evolution]` on `0`–`1`; `component` places a capability, `->` a dependency link, `evolve` draws the evolution trend to a target maturity, and OWM grammar adds `pipeline`, `note`, decorators, and inertia. Label and axis sizes are engine-owned.

## [26]-[ISHIKAWA]

```mermaid
ishikawa-beta
  "Render Failure"
    Browser
      "Chromium missing"
        "PATH empty"
        "Sandbox denied"
      "Stale headless flag"
    Assets
      "Remote icon"
        "Registry offline"
      "Remote image"
        "Blocked CDN"
    Syntax
      "Syntax drift"
        "Renamed keyword"
      "Reserved word"
```

Fence content asserts a render failure traced through browser, asset, and syntax cause families into nested sub-causes; the family mis-handles `accTitle`/`accDescr`/`title` as spurious head nodes, so the relation sentence rides beside the fence. A quoted head names the effect, top-level identifiers are cause categories, quoted children are causes, and depth rides indentation — growth deepens existing branches into sub-causes, never head-level categories; sub-branches thin under the primary bones in the engine's two weights.
