# [SYNTAX_EXTENDED]

The diagram roster beyond the five core types — each admitted row carries its working form and the traps that bind it, and a registered row outside the admitted scope carries its registry entry alone.

## [01]-[REGISTRY]

Pick a type by intent, then its section for the minimal fence and traps; a dash marks an extended-family registry entry.

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
|  [19]   | `venn-beta`          | set-overlap regions      |
|  [20]   | `ishikawa-beta`      | cause-effect fishbone    |
|  [21]   | `wardley-beta`       | value-chain evolution    |
|  [22]   | `cynefin-beta`       | decision-domain sort     |
|  [23]   | `railroad-beta`      | grammar syntax rails     |
|  [24]   | `swimlane-beta`      | laned process flow       |
|  [25]   | `zenuml`             | sequence via zenuml      |
|  [26]   | `eventmodeling`      | command-event timeline   |

`zenuml` is an external diagram the CLI registers.

The quantitative rows — pie, xychart, sankey, radar — serve only when the artifact must stay a mermaid fence; a data visualization routes to the dataviz lane.

## [02]-[MINDMAP]

```mermaid
---
config:
  theme: base
  look: classic
  mindmap:
    padding: 25
    maxNodeWidth: 180
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    git0: "#BD93F9"
    gitBranchLabel0: "#F8F8F2"
    cScale0: "#FF79C6"
    cScale1: "#8BE9FD"
    cScale2: "#50FA7B"
    cScale3: "#FFB86C"
    cScaleLabel0: "#F8F8F2"
    cScaleLabel1: "#F8F8F2"
    cScaleLabel2: "#F8F8F2"
    cScaleLabel3: "#F8F8F2"
  themeCSS: ".mindmap-node rect,.mindmap-node path,.mindmap-node circle{fill-opacity:.5;stroke-width:1.5px}.edge{stroke-width:2px!important}.mindmap-node-label,.mindmap-node text{font-size:13px}[class^='node-line']{stroke:none!important}.section-0 rect,.section-0 path,.section-0 circle{fill:#FF79C6!important;stroke:#FF79C6!important}.section-edge-0{stroke:#FF79C6!important}.section-1 rect,.section-1 path,.section-1 circle{fill:#8BE9FD!important;stroke:#8BE9FD!important}.section-edge-1{stroke:#8BE9FD!important}.section-2 rect,.section-2 path,.section-2 circle{fill:#50FA7B!important;stroke:#50FA7B!important}.section-edge-2{stroke:#50FA7B!important}.section-3 rect,.section-3 path,.section-3 circle{fill:#FFB86C!important;stroke:#FFB86C!important}.section-edge-3{stroke:#FFB86C!important}.section-root rect,.section-root path,.section-root circle{fill:#BD93F9!important;stroke:#BD93F9!important}"
---
mindmap
  root((Diagram Skill))
    [Laws]
      (Palette roles)
      (Edge rails)
      (Alpha tiers)
      (Type ramp)
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
      (Prose gate)
    [Craft]
      (One question)
      (Staged growth)
      (Split move)
```

The fence asserts the skill decomposing into laws, families, gates, and craft to leaf depth; the family mis-handles `accTitle`/`accDescr`, so the relation sentence rides beside the fence. Root leads; consistent indentation sets depth, mixed tabs and spaces are rejected, and explicit edges are invalid. Shapes carry level — `root((...))` circle, `[...]` branch rects, `(...)` rounded topics, bare text leaves. First-level branches take `.section-0`–`.section-N` classes in declaration order, but the engine lightens every `cScale` hue before painting, so canon color rides explicit per-section `themeCSS` overrides on fills, strokes, and `.section-edge-N` strokes; the `.mindmap-node` fill-opacity stamp composites the translucent law, the `.edge` stamp pulls the engine's thick depth-scaled connectors to the standing 2px, and the `[class^='node-line']` kill retires the engine underline strips. Radial layout is cose-bilkent and owns its own edge geometry.

## [03]-[BLOCK]

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
    textColor: "#F8F8F2"
    titleColor: "#D6BCFA"
    mainBkg: "#44475A"
    nodeBorder: "#BD93F9"
    nodeTextColor: "#F8F8F2"
    lineColor: "#FF79C6"
    arrowheadColor: "#FF79C6"
    edgeLabelBackground: "#21222C"
    clusterBkg: "#21222C"
    clusterBorder: "#D6BCFA"
  themeCSS: ".node rect,.node path,.node polygon{stroke-width:1.5px;filter:none!important}.marker path{fill:#FF79C6;stroke:#FF79C6}.marker circle{fill:#FF79C6;stroke:#FF79C6}.edgeLabel{font-size:12px;font-weight:500}.nodeLabel,.label{font-size:13px;font-weight:500}.cluster-label .nodeLabel,.cluster text{font-size:13.5px;font-weight:700;letter-spacing:.08em}rect.composite{fill:#21222C;stroke:#D6BCFA;stroke-width:1px;stroke-dasharray:5 4}"
---
block-beta
  columns 3
  Fence["Fence"] Parse["Parse"] Logic["Logic"]
  Theme["Theme"] Render["Render"] Proof["Proof"]
  space:3
  block:gate:3
    columns 3
    SVG["SVG"] PNG["PNG"] Cache["Cache"]
  end
  Fence --> Parse
  Parse --> Logic
  Fence --> Theme
  Theme --> Render
  Parse --> Render
  Logic --> Proof
  Render -- "emit" --> gate
  Proof --> gate
  classDef primary fill:#44475A,stroke:#FF79C6,color:#F8F8F2
  classDef boundary fill:#282A36,stroke:#BD93F9,color:#F8F8F2
  classDef data fill:#FFB86CBF,stroke:#FFB86C,color:#282A36
  classDef success fill:#50FA7BBF,stroke:#50FA7B,color:#282A36
  class Fence boundary
  class Parse,Theme,Render,Logic,Proof primary
  class Cache data
  class SVG,PNG success
```

The fence asserts a two-row render raster feeding a nested proof group; the family mis-handles `accTitle`/`accDescr` as nodes, so the relation sentence rides beside the fence. The portable keyword is `block-beta`; `columns N` precedes a row, a `:n` span widens a block, `space` inserts a filler, and a nested `block:id:span ... end` holds its own `columns`. A block arrow is `blockArrowId<["Label"]>(dir)` with `dir` one of `right`, `left`, `up`, `down`, `x`, `y`, or a compound like `(x, down)`. Links route straight from source center through a midpoint to target center with no obstacle awareness, so a committed raster links only adjacent cells — that placement discipline is the whole of the no-crossing law here. The family stylesheet never reaches its marker children, so the `themeCSS` `.marker path`/`.marker circle` fill-and-stroke stamp is the arrowhead-color floor, and the nested-group rect restyles through `rect.composite` — the engine's own composite paint is a faded gray that never survives review. `classDef`, `class`, and `style` bind by block id.

## [04]-[JOURNEY]

```mermaid
---
config:
  theme: base
  look: classic
  journey:
    titleFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    titleColor: "#F8F8F2"
    titleFontSize: "18px"
    taskFontSize: 12
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    titleColor: "#F8F8F2"
    faceColor: "#FFD86654"
    actor0: "#BD93F9"
    actor1: "#8BE9FD"
    actor2: "#50FA7B"
    actor3: "#FFB86C"
    actor4: "#FF79C6"
    actor5: "#6272A4"
    fillType0: "#FF79C680"
    fillType1: "#8BE9FD66"
    fillType2: "#50FA7B66"
    fillType3: "#FFB86C66"
    fillType4: "#BD93F980"
    fillType5: "#FF555580"
    fillType6: "#FFD86654"
    fillType7: "#6272A4"
  themeCSS: ".face{fill:#FFD86654;stroke:#FFD866;stroke-width:1px}.mouth{fill:#F8F8F2;stroke:none}circle[fill='#666']{fill:#F8F8F2;stroke:#F8F8F2}.task-line{stroke:#6272A4;stroke-dasharray:4 6}line{stroke:#6272A4}[id$='-arrowhead'] path{fill:#6272A4}circle[class^='actor-']{stroke:#282A36;r:5.25px}"
---
journey
  accTitle: Fence authoring journey
  accDescr: An author, agent, and reviewer scored across drafting, review, and shipping a themed fence.
  title Fence Authoring
  section Draft
    Outline question: 5: Author
    Theme tokens: 3: Author, Agent
    Wire classes: 3: Agent
  section Review
    Render proof: 4: Agent
    Inspect PNG: 3: Reviewer
    Fix contrast: 2: Author, Agent
  section Ship
    Gate green: 4: Agent
    Commit fence: 5: Author, Reviewer
```

Scores are integers `1` through `5`; a task belongs under a `section`, an actor needs no declaration, and an out-of-range score is invalid. Task and section fills read `fillType0`–`fillType7`, which accept alpha hexes — the translucent tier composites dark enough that Foreground task ink measures, so journey rides the light-ink alpha ladder. Actor dots read the `actor0`–`actor5` theme variables, never the `journey.actorColours` config list, and take their stroke and the −25% radius through `circle[class^='actor-']`. The score faces restyle as translucent gold chips through `.face`, the eye dots re-ink through the `circle[fill='#666']` attribute hook, and the mouth is a filled crescent path — `.mouth` takes `fill`, never `stroke`. The title reads `journey.titleFontFamily`/`journey.titleColor` config keys — the theme mono stack does not reach it — and the axis line plus its `[id$='-arrowhead']` marker take the Comment wayfinding hue.

## [05]-[REQUIREMENT_DIAGRAM]

```mermaid
---
config:
  theme: base
  look: classic
  htmlLabels: false
  requirement:
    fontSize: 13
    rect_min_width: 190
    rect_min_height: 80
    rect_padding: 12
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    requirementBackground: "#44475A"
    requirementBorderColor: "#BD93F9"
    requirementTextColor: "#F8F8F2"
    relationColor: "#FF79C6"
    relationLabelColor: "#F8F8F2"
    relationLabelBackground: "#21222C"
    edgeLabelBackground: "#21222C"
  themeCSS: ".relationshipLine{stroke-width:1.5px;stroke-dasharray:4 6}[id$='requirement_arrowEnd'] path{transform:scale(.5);transform-origin:20px 10px}[id$='requirement_containsStart'] circle,[id$='requirement_containsStart'] line{transform:scale(.6);transform-origin:0px 10px}.reqTitle{font-weight:600}"
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
  classDef primary fill:#44475A,stroke:#BD93F9,color:#F8F8F2
  classDef external fill:#282A36,stroke:#8BE9FD,color:#F8F8F2
  class renderProof,gateBudget primary
  class validator,themingLaw external
```

Types are `requirement`, `functionalRequirement`, `interfaceRequirement`, `performanceRequirement`, `physicalRequirement`, `designConstraint`; `risk` takes `Low`/`Medium`/`High` and `verifyMethod` takes `Analysis`/`Inspection`/`Test`/`Demonstration`. Relations `contains`, `copies`, `derives`, `satisfies`, `verifies`, `refines`, `traces` spell both `a - satisfies -> b` and `b <- traces - a`; `contains` draws solid with a plus-circle start marker, every other relation draws dashed with the open-arrow end marker. Box fills theme through `classDef`/`class` and `htmlLabels: false` stacks the body attributes cleanly. The relation label is a markdown chip whose backing reads `edgeLabelBackground` — the recessed `#21222C` chip masks the stroke it sits on, which is the whole label-off-line law for this family — while `relationLabelBackground` feeds only the SVG-text fallback box. The engine's `requirement_arrowEnd` marker is a 20×20 open V that never received the unified scale; the `[id$='requirement_arrowEnd']` stamp anchored at its `refX 20 10` tip pulls it onto the one marker ladder, and `.relationshipLine` carries the trace weight and rhythm.

## [06]-[PIE]

```mermaid
---
config:
  theme: base
  look: classic
  pie:
    textPosition: 0.7
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    pieOpacity: 1
    pieOuterStrokeWidth: "0px"
    pieStrokeWidth: "1.5px"
    pieSectionTextSize: "13px"
    pieSectionTextColor: "#F8F8F2"
    pieLegendTextSize: "12px"
    pieLegendTextColor: "#F8F8F2"
    pieTitleTextSize: "15px"
    pieTitleTextColor: "#F8F8F2"
    pie1: "#FF79C6"
    pie2: "#8BE9FD"
    pie3: "#50FA7B"
    pie4: "#FFB86C"
    pie5: "#BD93F9"
  themeCSS: ".pieCircle{opacity:1}.slice{font-weight:700}.pieCircle:nth-of-type(1){fill:#FF79C680;stroke:#FF79C6}.pieCircle:nth-of-type(2){fill:#8BE9FD66;stroke:#8BE9FD}.pieCircle:nth-of-type(3){fill:#50FA7B66;stroke:#50FA7B}.pieCircle:nth-of-type(4){fill:#FFB86C66;stroke:#FFB86C}.pieCircle:nth-of-type(5){fill:#BD93F980;stroke:#BD93F9}.pieTitleText{font-weight:600}"
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

Values sum above `0`, labels are quoted, and `showData` prints values in the legend; donut, legend position, and slice highlight compose on it. `pieOpacity` dims fill and border together, so the translucent-fill law rides per-slice `path.pieCircle:nth-of-type(N)` stamps — alpha in the fill, the same hue at full opacity in the stroke, `pieOpacity: 1` holding the border solid. Slices follow `pie1`–`pie12` in declaration order, so the nth-of-type index and the ordinal share one count. Slice percentages print at 13px bold Foreground through `pieSectionTextSize`/`pieSectionTextColor` and the `.slice` weight stamp — every slice hue sits in the light-ink alpha tier so one ink serves all slices — and `pieOuterStrokeWidth: "0px"` retires the redundant outer ring.

## [07]-[QUADRANT_CHART]

```mermaid
---
config:
  theme: base
  look: classic
  quadrantChart:
    pointRadius: 4
    pointTextPadding: 8
    pointLabelFontSize: 12
    quadrantLabelFontSize: 13
    xAxisLabelFontSize: 13
    yAxisLabelFontSize: 13
    titleFontSize: 15
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    quadrant1Fill: "#44475A"
    quadrant2Fill: "#21222C"
    quadrant3Fill: "#44475A"
    quadrant4Fill: "#21222C"
    quadrant1TextFill: "#D6BCFA"
    quadrant2TextFill: "#D6BCFA"
    quadrant3TextFill: "#D6BCFA"
    quadrant4TextFill: "#D6BCFA"
    quadrantPointFill: "#BD93F9"
    quadrantPointTextFill: "#F8F8F2"
    quadrantXAxisTextFill: "#F8F8F2"
    quadrantYAxisTextFill: "#F8F8F2"
    quadrantTitleFill: "#F8F8F2"
    quadrantInternalBorderStrokeFill: "#6272A4"
    quadrantExternalBorderStrokeFill: "#6272A4"
  themeCSS: ".data-point circle{fill-opacity:.75}"
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
  Cache:::success: [0.22, 0.78]
  Batching:::success: [0.34, 0.86]
  Streaming:::external: [0.66, 0.83]
  Sharding:::external: [0.81, 0.69]
  Polling:::error: [0.24, 0.24]
  Mirroring:::error: [0.38, 0.16]
  Archive:::data: [0.68, 0.30]
  Replay:::data: [0.84, 0.21]
  classDef success color: #50FA7B, radius: 4, stroke-color: #50FA7B, stroke-width: 1px
  classDef external color: #8BE9FD, radius: 4, stroke-color: #8BE9FD, stroke-width: 1px
  classDef error color: #FF5555, radius: 4, stroke-color: #FF5555, stroke-width: 1px
  classDef data color: #FFB86C, radius: 4, stroke-color: #FFB86C, stroke-width: 1px
```

Coordinates bind to `0` through `1` and quadrants number `1` top-right counterclockwise; per-point styling trails the coordinates and `:::class` plus `classDef` reuses it with keys `radius`, `color`, `stroke-color`, `stroke-width` — six-digit hex only, so translucency rides the one `.data-point circle{fill-opacity:.75}` stamp while the class stroke stays full. `pointRadius` and the class radius hold the −25% dot scale, and `pointTextPadding` drops each white label clear below its dot — the dot never blocks its name. Quadrant fills alternate the two neutral surfaces so the plotted hues carry all the semantics, quadrant captions ink Lavender as this family's container titles, and axis text, point labels, and the title ink Foreground.

## [08]-[SANKEY]

```mermaid
---
config:
  theme: base
  look: classic
  sankey:
    labelStyle: legacy
    linkColor: gradient
    nodeWidth: 12
    nodePadding: 24
    width: 900
    height: 480
    nodeColors:
      Fences: "#BD93F9"
      Flowchart: "#FF79C6"
      Charts: "#8BE9FD"
      Render: "#FFB86C"
      Logic: "#6272A4"
      Pass: "#50FA7B"
      Warn: "#FFD866"
      Fail: "#FF5555"
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
  themeCSS: ".link{mix-blend-mode:normal;stroke-opacity:.35}.node-labels{font-size:12px}.node-labels text{fill:#F8F8F2}"
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

The fence asserts a corpus splitting through render and logic gates into pass, warn, and fail sinks; the family rejects `accTitle`/`accDescr` at parse, so the relation sentence rides beside the fence. The keyword is `sankey`; the body is three-column CSV `source,target,value` with CSV quoting for embedded commas. Config carries `linkColor` (`gradient`, `source`, `target`, or a hex), `nodeAlignment`, `showValues`, `prefix`/`suffix`, the geometry knobs, and the `nodeColors` name-to-hex map — a committed sankey maps every node to a palette hex. The engine blends links with `mix-blend-mode: multiply`, which erases them into a dark canvas, so the `.link` stamp restores normal blending at a `.35` stroke opacity; `labelStyle` stays `legacy` — the outlined mode strokes a surface-colored halo that mushes on dark — and `.node-labels text` inks Foreground at the label floor.

## [09]-[XYCHART]

```mermaid
---
config:
  theme: base
  look: classic
  xyChart:
    showDataLabel: true
    showDataLabelOutsideBar: true
    titleFontSize: 15
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    xyChart:
      backgroundColor: "#282A36"
      titleColor: "#F8F8F2"
      dataLabelColor: "#F8F8F2"
      xAxisLabelColor: "#F8F8F2"
      xAxisTitleColor: "#F8F8F2"
      xAxisTickColor: "#6272A4"
      xAxisLineColor: "#6272A4"
      yAxisLabelColor: "#F8F8F2"
      yAxisTitleColor: "#F8F8F2"
      yAxisTickColor: "#6272A4"
      yAxisLineColor: "#6272A4"
      plotColorPalette: "#BD93F9, #FF79C6"
  themeCSS: ".bar-plot-0 rect{fill-opacity:.75;stroke-width:1.5px}.plot text{font-size:11px}"
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

The keyword is `xychart`; `xychart horizontal` flips orientation and each `bar` or `line` array matches the x-axis category count. Bar width derives from the category count against a fixed padding percent — width tunes by adding categories, never by a knob. `showDataLabel` prints the first declared plot's values at a size computed from bar width, so the bar plot declares first, `showDataLabelOutsideBar` lifts the values above the bars, and the `.plot text` stamp caps the computed size at the label floor. Bars carry the translucent law through `.bar-plot-0 rect{fill-opacity:.75;stroke-width:1.5px}` — the engine already strokes each bar in its own hue at width zero. Line point labels render on `line` only and ink the line's palette hue; a label omitted on a point suppresses that one chip, which clears the first-category collision when line and bar meet at the origin.

## [10]-[RADAR]

```mermaid
---
config:
  theme: base
  look: classic
  radar:
    width: 460
    height: 460
    marginLeft: 120
    marginRight: 120
    marginTop: 60
    marginBottom: 60
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    titleColor: "#F8F8F2"
    cScale0: "#FF79C6"
    cScale1: "#8BE9FD"
    radar:
      axisColor: "#6272A4"
      axisStrokeWidth: 1.5
      graticuleColor: "#44475A"
      graticuleOpacity: 0.4
      curveOpacity: 0.35
      curveStrokeWidth: 2
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

`axis` names the axes, a positional curve `name["Label"]{...}` follows axis order and a keyed curve binds by axis id. Curves fill and stroke `cScale0`–`cScale11` in declaration order with `radar.curveOpacity` on the fill alone, so two curves at `.35` both read while their full-hue 2px strokes hold the border law — identical data across curves cancels into one pale polygon, so each curve carries distinct values, and hues follow the ordinal order so the legend reads as the palette does — two curves compare, four is the legibility edge. `graticule` accepts `polygon` or `circle`, config admits `axisScaleFactor` and `curveTension`, and theme variables nest under `radar:`. Axis labels anchor just outside the chart radius and clip at the viewport edge — the `radar:` config margins own that clearance, and the hardcoded legend position demands short curve labels. Axis lines read `radar.axisColor` while axis text falls through to root `textColor`.

## [11]-[GANTT]

```mermaid
---
config:
  theme: base
  look: classic
  gantt:
    fontSize: 12
    sectionFontSize: 13
    barHeight: 22
    barGap: 6
    topPadding: 60
    leftPadding: 90
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    titleColor: "#F8F8F2"
    taskTextColor: "#F8F8F2"
    taskTextOutsideColor: "#F8F8F2"
    taskTextDarkColor: "#F8F8F2"
    gridColor: "#6272A4"
    excludeBkgColor: "#21222C"
    sectionBkgColor: "#21222C"
    sectionBkgColor2: "#21222C"
    altSectionBkgColor: "#282A36"
    taskBkgColor: "#44475A"
    taskBorderColor: "#BD93F9"
    activeTaskBkgColor: "#6272A4"
    activeTaskBorderColor: "#BD93F9"
    doneTaskBkgColor: "#21222C"
    doneTaskBorderColor: "#6272A4"
    critBkgColor: "#FF555580"
    critBorderColor: "#FF5555"
    todayLineColor: "#FF79C6"
    vertLineColor: "#8BE9FD"
  themeCSS: ".sectionTitle{font-size:13.5px;font-weight:700;fill:#D6BCFA}.taskText,.taskTextOutsideRight,.taskTextOutsideLeft{font-size:12px}.grid .tick text{font-size:11px}"
---
gantt
  accTitle: Release schedule
  accDescr: Design, build, and release phases with an active draft, a critical review, and a tagged ship milestone.
  dateFormat YYYY-MM-DD
  axisFormat %b %d
  tickInterval 2day
  weekday monday
  excludes weekends
  todayMarker stroke-width:2px,stroke:#FF79C6,opacity:0.55
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

Dates match `dateFormat`, `after`/`until` reference existing IDs, and modifiers are `done`, `active`, `crit`, `milestone`, `vert`; repeated `excludes` and `includes` entries stack. `excludeBkgColor` recesses the excluded bands — left unset it derives a light gray that floods a dark canvas — and `axisFormat` with `tickInterval` own tick legibility; default daily ISO ticks overlap into an unreadable strip. Section titles are this family's lane titles and take the container-title stamp with Lavender ink through `.sectionTitle`; `taskTextDarkColor` joins the Foreground ink set because done bars recess to `#21222C`; `vertLineColor` colors the full-height `vert` gate marker, an `after` list (`after a b`) converges on every named prerequisite, `weekday` anchors the tick grid, and the today rule spans the whole canvas — its `todayMarker` style string carries a translucent stroke so it never blinds what it crosses.

## [12]-[TREEMAP]

```mermaid
---
config:
  theme: base
  look: classic
  treemap:
    showValues: true
    valueFormat: ','
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    titleColor: "#F8F8F2"
    cScale0: "#BD93F9"
    cScale1: "#FF79C6"
    cScale2: "#8BE9FD"
    cScale3: "#50FA7B"
    cScale4: "#FFB86C"
    cScaleLabel0: "#F8F8F2"
    cScaleLabel1: "#F8F8F2"
    cScaleLabel2: "#F8F8F2"
    cScaleLabel3: "#F8F8F2"
    cScaleLabel4: "#F8F8F2"
    cScalePeer0: "#BD93F9"
    cScalePeer1: "#FF79C6"
    cScalePeer2: "#8BE9FD"
    cScalePeer3: "#50FA7B"
    cScalePeer4: "#FFB86C"
  themeCSS: ".treemapLeaf{fill-opacity:.45;stroke-width:1.5px}.treemapSection{fill:#21222C!important;fill-opacity:1;stroke-opacity:1;stroke-width:1px}.treemapSectionLabel{font-size:13.5px;font-weight:700}.treemapSectionValue{font-size:12px}.treemapLabel{font-size:13px!important;font-weight:500}.treemapValue{font-size:11px!important}.treemapTitle{font-size:15px;font-weight:600}"
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

Indentation sets hierarchy and a leaf carries a numeric value; `valueFormat` formats values through d3-format grammar alongside `showValues`. Branch hues assign from `cScale0`–`cScale11` in branch declaration order with `cScalePeer` strokes, so the ordinal roster is the palette surface — `classDef` on a branch emits inline `!important` fills that lock out every stylesheet correction, so a themed treemap carries no classes. Sections recess to `#21222C` through the `.treemapSection` stamp while their full-hue peer borders carry the branch identity, leaves composite the translucent law at `.45` fill-opacity under 1.5px hue borders, and `cScaleLabel0`–`cScaleLabel11` ink Foreground so every label reads over the composited tiles. Section headers take the container-title stamp, section values lift to 12px, and the leaf label/value stamps cap the engine's fit-to-tile sizing at the ramp.

## [13]-[C4]

```mermaid
---
config:
  theme: base
  look: classic
  c4:
    c4ShapeInRow: 3
    c4ShapeMargin: 60
    personFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    personFontSize: 13
    external_personFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    external_personFontSize: 13
    systemFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    systemFontSize: 13
    system_dbFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    system_dbFontSize: 13
    external_systemFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    external_systemFontSize: 13
    boundaryFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    boundaryFontSize: 13.5
    messageFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    messageFontSize: 12
    person_bg_color: "#44475A"
    person_border_color: "#BD93F9"
    external_person_bg_color: "#282A36"
    external_person_border_color: "#8BE9FD"
    system_bg_color: "#44475A"
    system_border_color: "#BD93F9"
    system_db_bg_color: "#44475A"
    system_db_border_color: "#FFB86C"
    external_system_bg_color: "#282A36"
    external_system_border_color: "#8BE9FD"
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    personBorder: "#BD93F9"
    personBkg: "#44475A"
  themeCSS: "rect[stroke='#444444']{stroke:#D6BCFA;stroke-dasharray:5 4}text[fill='#444444']{fill:#D6BCFA}[id$='-arrowhead'] path{fill:#FF79C6;transform:scale(.8);transform-origin:9px 5px}[id$='-arrowend'] path{fill:#FF79C6;transform:scale(.8);transform-origin:1px 5px}image{display:none}"
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
  UpdateRelStyle(author, skill, $textColor="#F8F8F2", $lineColor="#FF79C6", $offsetY="-30")
  UpdateRelStyle(skill, cli, $textColor="#F8F8F2", $lineColor="#FF79C6", $offsetY="-14")
  UpdateRelStyle(cli, proofs, $textColor="#F8F8F2", $lineColor="#FFB86C")
  UpdateRelStyle(docs, proofs, $textColor="#F8F8F2", $lineColor="#FFB86C", $offsetY="-30")
  UpdateRelStyle(reader, docs, $textColor="#F8F8F2", $lineColor="#8BE9FD", $offsetY="-14")
```

The family covers `C4Context`, `C4Container`, `C4Component`, `C4Dynamic`, `C4Deployment`; an alias exists before `Rel()` and named parameters take `$`. Element colors are config keys — `person_bg_color`, `system_border_color`, `external_system_bg_color`, and kin under `c4:` — so the palette lands without per-element calls, while `UpdateRelStyle` colors each relation and offsets its label clear of boxes with `$offsetX`/`$offsetY`. Fonts are config keys too: every shape family carries a `*FontFamily`/`*FontSize`/`*FontWeight` triplet — `themeVariables.fontFamily` never reaches C4 text, so the triplets carry the mono stack and the ramp, and the sizes feed the engine's own box measurement. Boundary strokes, boundary titles, and the diagram title hardcode `#444444`, and the `rect[stroke='#444444']`/`text[fill='#444444']` attribute hooks re-ink them Lavender at the container rhythm; the `[id$='-arrowhead']`/`[id$='-arrowend']` markers default black and take canon pink at the unified scale anchored on their ref points. Person sprites are baked raster images — `image{display:none}` retires them and the `<<person>>` stereotype carries the role. Loose shapes pack in rows above every boundary and a third loose shape lands beneath the first where relations cross it, so external systems live in their own `Boundary` and the boundaries pack side by side.

## [14]-[ARCHITECTURE]

```mermaid
---
config:
  theme: base
  look: classic
  architecture:
    seed: 4
    iconSize: 64
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    lineColor: "#FF79C6"
    archEdgeColor: "#FF79C6"
    archEdgeArrowColor: "#FF79C6"
    archEdgeWidth: "2"
    archGroupBorderColor: "#D6BCFA"
    archGroupBorderWidth: "1"
  themeCSS: ".architecture-service svg rect{fill:#44475A!important}.architecture-groups svg rect{fill:#44475A!important}.architecture-groups text{fill:#D6BCFA;font-size:13.5px;font-weight:700;letter-spacing:.08em}.architecture-services text{font-size:13px;font-weight:500}.node-bkg{stroke-dasharray:5 4}"
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

`group` and `service` place nodes, a member declares `in group`, edge ports are `T|B|L|R`, a `junction` joins edges, a group-boundary edge takes `{group}`, and an Iconify icon resolves as `pack:name`. Layout is cytoscape fcose: the port pairs plus `align row|column` rows fully determine the grid, so a committed fence aligns every rank both ways and earns orthogonal edges — unaligned members scatter diagonally. Arrowheads are `polygon.arrow` elements filled from `archEdgeArrowColor`, which derives gray unless set; a CSS transform on those polygons erases their placement translate, so arrow size tunes only through `iconSize` (the arrow is one sixth of it). Built-in icons hardcode a blue plate on services and groups alike — the paired `.architecture-service svg rect,.architecture-groups svg rect` stamp re-fills both to Selection — group titles are bare `text` under `.architecture-groups` and take the Lavender container-title stamp there, service labels take the node-label ramp through `.architecture-services text`, `archGroupBorderColor` with the `5 4` dash rhythm draws the Lavender containment, and `architecture.seed` is the deterministic lock. Junction endpoints shift arrow polygons off their lines, so junctions stay grammar for genuine multi-way joins rather than demo decoration.

## [15]-[PACKET]

```mermaid
---
config:
  theme: base
  look: classic
  packet:
    bitWidth: 24
    rowHeight: 28
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
  themeCSS: ".packetBlock{fill:#BD93F94D;stroke:#BD93F9;stroke-width:1.5px}.packetLabel{fill:#F8F8F2;font-size:12px}.packetByte{fill:#6272A4;font-size:11px}.packetTitle{fill:#D6BCFA;font-size:13.5px;font-weight:700}"
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

The keyword is `packet`; `start-end: "name"` ranges and `+count: "name"` auto-counted fields mix under an optional `title`, blocks stay contiguous, and `accTitle`/`accDescr` are accepted. The family themes through `themeCSS` classes — `.packetBlock` fill and stroke, `.packetLabel`, `.packetByte`, `.packetTitle` — which own the whole surface; the nested `themeVariables.packet` block half-applies (title keys land, block keys re-derive), so the class route is the single styling owner. Fields composite the translucent law as one hue family — a bit layout is one structure, never a rainbow — with Foreground labels, Foreground bit indices at 11px, and the Lavender title at container weight; `bitWidth` and `rowHeight` size the raster.

## [16]-[TIMELINE]

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
    textColor: "#F8F8F2"
    cScale0: "#FF79C6"
    cScale1: "#8BE9FD"
    cScale2: "#50FA7B"
    cScale3: "#FFB86C"
    cScaleLabel0: "#F8F8F2"
    cScaleLabel1: "#F8F8F2"
    cScaleLabel2: "#F8F8F2"
    cScaleLabel3: "#F8F8F2"
  themeCSS: ".node-bkg{fill-opacity:.5;stroke-width:1.5px}[class^='node-line']{stroke:none!important}.section--1 .node-bkg{stroke:#FF79C6}.section-0 .node-bkg{stroke:#8BE9FD}line[stroke-width='4']{stroke:#6272A4;stroke-width:2px}line[stroke-dasharray='5,5']{stroke:#6272A4;stroke-width:1.5px;stroke-dasharray:4 6}[id$='-arrowhead'] path{fill:#6272A4}"
---
timeline
  accTitle: Skill evolution
  accDescr: Four phases of the diagram skill from palette adoption through the visual canon, each carrying its landed changes.
  title Skill Evolution
  section Foundation
    Palette : Dracula tokens : Role map
    Contract : Frontmatter : Validator
  section Canon
    Styling : Rails : Floors : Glow kill
    Visual : Marker scale : Translucent fills
```

A multi-event row repeats `:`, sections group periods, and timeline takes `LR`/`TD` direction headers. Ordinal fills read `cScale0`–`cScale11`, but theme resolution converts them through hsl and strips alpha, so translucency rides `.node-bkg{fill-opacity:.5}` with per-section full-hue borders — section classes index from `-1`, so the first section is `.section--1` — while `cScaleLabel0`–`cScaleLabel11` carry Foreground ink over the composited fills and the engine underline strips retire through `[class^='node-line']`. The unclassed axis (`line[stroke-width='4']`) and the dashed event connectors (`line[stroke-dasharray='5,5']`) restyle by attribute into one Comment wayfinding system at ladder weights, and the single shared `[id$='-arrowhead']` marker takes the same hue — one marker serves the axis and every connector, so the wayfinding layer holds one color.

## [17]-[GITGRAPH]

```mermaid
---
config:
  theme: base
  look: classic
  gitGraph:
    rotateCommitLabel: false
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    mainBkg: "#282A36"
    primaryColor: "#282A36"
    git0: "#BD93F9"
    git1: "#FF79C6"
    git2: "#8BE9FD"
    git3: "#50FA7B"
    gitBranchLabel0: "#282A36"
    gitBranchLabel1: "#282A36"
    gitBranchLabel2: "#282A36"
    gitBranchLabel3: "#282A36"
    commitLabelColor: "#F8F8F2"
    commitLabelBackground: "#21222C"
    commitLabelFontSize: "11px"
    tagLabelFontSize: "11px"
  themeCSS: ".arrow{stroke-width:2px}.arrow3{stroke-dasharray:6 6}.commit-bullets circle{transform-box:fill-box;transform-origin:center;transform:scale(.75)}.tag-label-bkg{fill:#FFD86654;stroke:#FFD866}.tag-label{fill:#F8F8F2}.tag-hole{fill:#282A36}"
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

Directions are `LR:`, `TB:`, `BT:`; a branch exists before checkout or merge, commit IDs stay unique, and cherry-picking a merge commit adds `parent:`. Branch rails are `.arrow` paths the engine draws at 8px — the stamp pulls them to the standing 2px — and commit dots scale −25% through one transform on `.commit-bullets circle`, which preserves the merge and highlight ring ratios a radius override collapses. Merge dot cores fill `primaryColor`, so a canvas-valued `primaryColor` renders merges as hollow rings on the branch hue. `rotateCommitLabel: false` keeps commit ids horizontal on their recessed `commitLabelBackground` chips at `commitLabelFontSize`, and the tag is the yellow-law chip stamped through `.tag-label-bkg`/`.tag-label`/`.tag-hole` CSS — the class route holds the translucent gold on hosts that strip theme-variable alpha. Branch rails differentiate by line style as well as hue: `.arrowN` classes index the branch declaration order, and only a genuinely unmerged branch takes the `6 6` planned rhythm — a dashed rail on merged history states a false repository fact. Branch label pills stay opaque brand chips with `gitBranchLabel0`–`gitBranchLabel7` dark ink.

## [18]-[KANBAN]

```mermaid
---
config:
  theme: base
  look: classic
  kanban:
    sectionWidth: 210
    ticketBaseUrl: '<ticket-url>#TICKET#'
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    background: "#44475A"
    nodeBorder: "#BD93F9"
    cScale0: "#21222C"
    cScale1: "#21222C"
    cScale2: "#21222C"
    cScale3: "#21222C"
    cScale4: "#21222C"
    cScale5: "#21222C"
    cScale6: "#21222C"
    cScale7: "#21222C"
    cScaleLabel0: "#D6BCFA"
    cScaleLabel1: "#D6BCFA"
    cScaleLabel2: "#D6BCFA"
    cScaleLabel3: "#D6BCFA"
    cScaleLabel4: "#D6BCFA"
    cScaleLabel5: "#D6BCFA"
    cScaleLabel6: "#D6BCFA"
    cScaleLabel7: "#D6BCFA"
  themeCSS: ".nodeLabel{font-size:13px;font-weight:500}.cluster-label .nodeLabel{font-size:13.5px;font-weight:700;color:#D6BCFA}.node rect{stroke-width:1.5px;filter:none!important}line[stroke='red']{stroke:#FF5555;stroke-width:3px}line[stroke='orange']{stroke:#FFB86C;stroke-width:3px}line[stroke='blue']{stroke:#6272A4;stroke-width:3px}line[stroke='lightblue']{stroke:#44475A;stroke-width:3px}"
---
kanban
  todo[Backlog]
    t1[Marker scale audit]@{ ticket: MD-101, assigned: 'Agent', priority: 'High' }
    t2[Container title bump]@{ ticket: MD-102, assigned: 'Author', priority: 'Low' }
  wip[In Progress]
    t3[Translucent fills]@{ ticket: MD-103, assigned: 'Agent', priority: 'Very High' }
    t4[Padding to 25]@{ ticket: MD-104, assigned: 'Agent', priority: 'Low' }
  review[Review]
    t5[Yellow ink flip]@{ ticket: MD-105, assigned: 'Reviewer', priority: 'High' }
  done[Done]
    t6[Glow kill]@{ ticket: MD-106, assigned: 'Author', priority: 'Very Low' }
    t7[Elbow routing]@{ ticket: MD-107, assigned: 'Agent', priority: 'Low' }
```

The fence asserts four queues carrying seven law cards with ticket metadata; the family mis-handles `accTitle`/`accDescr` as columns, so the relation sentence rides beside the fence. Tasks indent under columns, metadata keys are `assigned`, `ticket`, `priority`, and priorities are exactly `Very High`, `High`, `Low`, `Very Low`; `kanban.ticketBaseUrl` links each ticket by substituting the task ticket for `#TICKET#`. Column fills read `cScale0`–`cScale11` shifted one — column classes index from `section-1` — so the full ordinal range recesses the columns; cards fill the `background` variable under `nodeBorder` strokes, and column titles are `.cluster-label .nodeLabel` container titles taking the 13.5px/700 Lavender stamp. Priority bars hardcode named colors, and the `line[stroke='red'|'orange'|'blue'|'lightblue']` attribute hooks remap them onto the severity ladder at 3px.

## [19]-[TREEVIEW]

```mermaid
---
config:
  theme: base
  look: classic
  treeView:
    rowIndent: 14
    paddingY: 6
    labelFontSize: "13px"
    labelColor: "#F8F8F2"
    lineColor: "#6272A4"
    descriptionColor: "#8BE9FD"
    highlightBg: "#BD93F933"
    highlightStroke: "#BD93F9"
    iconColor: "#6272A4"
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
  themeCSS: ".treeView-node-description{fill:#8BE9FD}.treeView-highlight-bg{fill:#FFD86626;stroke:#FFD866}.treeView-node-line{stroke:#6272A4}"
---
treeView-beta
accTitle: Skill tree
accDescr: The diagram skill folder with its law owners annotated and the theming law highlighted.
├── references/
│   ├── theming.md :::highlight ## palette and scale law
│   ├── styling.md ## grammar and floors
│   ├── config.md ## frontmatter law
│   └── syntax-extended.md ## 24-type registry
├── templates/
│   ├── spine.mmd.md
│   └── lifecycle.mmd.md
├── scripts/
│   └── validate_mermaid.py ## render gate
└── SKILL.md
```

The tree parses box-drawing input, a trailing `/` marking a directory; annotations trail an entry as `:::class`, `## description`, and `icon(name)`/`icon(none)`. Config carries `rowIndent`, `paddingY`, `labelFontSize`, `labelColor`, and `lineColor`, which land directly, while the highlight and description surfaces restyle through `themeCSS` — `.treeView-highlight-bg` as the yellow-law chip (translucent gold fill, full gold stroke, the white label riding over it) and `.treeView-node-description` in Cyan as typed annotation ink, the hue pair that separates attention from information. `showIcons`, `defaultIconPack`, `filenameIcons`, and `extensionIcons` govern icons; an unregistered icon renders as a question mark, and `highlight` is the one class name with built-in geometry.

## [20]-[CYNEFIN]

```mermaid
---
config:
  theme: base
  look: classic
  cynefin:
    seed: 7
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    mainBkg: "#44475A"
    cynefin:
      domainFontSize: 14
      itemFontSize: 12
      textColor: "#F8F8F2"
      labelColor: "#D6BCFA"
      boundaryColor: "#6272A4"
      boundaryWidth: 1.5
      cliffColor: "#FF5555"
      cliffWidth: 2
      arrowColor: "#FF79C6"
      arrowWidth: 2
      complexBg: "#50FA7B33"
      complicatedBg: "#8BE9FD33"
      clearBg: "#FFD86633"
      chaoticBg: "#FF555533"
      confusionBg: "#BD93F933"
  themeCSS: ".cynefinItem{fill:#44475A;stroke:#6272A4}.cynefinItemText{fill:#F8F8F2}"
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

The five domains are `complex`, `complicated`, `clear`, `chaotic`, `confusion`, each holding quoted items, and a transition spells `domain --> domain : "label"`; domain fills, boundary, cliff, and arrow color nest under `cynefin:`. Domain tints carry the translucent law — the engine multiplies each `*Bg` by a `.4` fill-opacity, so a ~20% alpha hex lands near an 8% composite wash that keeps items legible — while `.cynefinItem`/`.cynefinItemText` chip the items on Selection with Foreground ink and `labelColor` inks the domain captions Lavender. The cliff between chaotic and clear is canonical geometry and takes Red at 2px; transitions curve center to center with a fixed 15% bow and the arrow tip lands beside the target caption — engine geometry, so a committed fence keeps transitions few and lets the label ride the bow's midpoint. `cynefin.seed` pins the boundary jitter.

## [21]-[RAILROAD]

```mermaid
---
config:
  theme: base
  look: classic
  railroad:
    fontSize: 13
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Consolas, monospace"
    strokeWidth: 2
    padding: 16
    lineColor: "#6272A4"
    markerFill: "#FF79C6"
    markerRadius: 4
    terminalFill: "#FFD86654"
    terminalStroke: "#FFD866"
    terminalTextColor: "#F8F8F2"
    nonTerminalFill: "#44475A"
    nonTerminalStroke: "#BD93F9"
    nonTerminalTextColor: "#F8F8F2"
    ruleNameColor: "#D6BCFA"
    specialFill: "#21222C"
    specialStroke: "#6272A4"
    commentFill: "#21222C"
    commentStroke: "#6272A4"
    commentTextColor: "#F8F8F2"
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
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

The keyword selects the grammar parser — `railroad-ebnf-beta` for EBNF, `railroad-abnf-beta` for ABNF, `railroad-peg-beta` for PEG, and `railroad-beta` for Mermaid's intermediate constructors. The whole visual surface is the `railroad:` config block — fills, strokes, text colors, `lineColor`, `markerFill`, `markerRadius`, `strokeWidth`, `fontSize`, `fontFamily` — sanitized to hex (alpha included), functional color spaces, and named colors. Terminals chip as the yellow-law surface (translucent gold, full gold stroke, Foreground ink), nonterminals ride Selection under Purple, rails run Comment at the standing 2px, rule names ink Lavender bold, and the start/end dots take pink at the −25% radius. In this EBNF dialect `? ... ?` is a special sequence, so optionality spells `[ ... ]` and repetition `{ ... }` — a postfix `?` fuses everything up to the next `?` into one special box.

## [22]-[SWIMLANE]

```mermaid
---
config:
  theme: base
  look: classic
  swimlane:
    lineHops: arc
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    titleColor: "#D6BCFA"
    primaryColor: "#44475A"
    primaryTextColor: "#F8F8F2"
    primaryBorderColor: "#BD93F9"
    mainBkg: "#44475A"
    nodeBorder: "#BD93F9"
    lineColor: "#FF79C6"
    tertiaryColor: "#21222C"
    clusterBkg: "#21222C"
    clusterBorder: "#D6BCFA"
    edgeLabelBackground: "#21222C"
    labelBackgroundColor: "#21222C"
  themeCSS: ".nodeLabel{font-size:13px;font-weight:500}.edgeLabel{font-size:12px;font-weight:500}.cluster-label .nodeLabel,.cluster-label text{font-size:13.5px;font-weight:700;letter-spacing:.08em}.node rect,.node circle,.node polygon,.node path{stroke-width:1.5px;filter:none!important}.swimlane-title{fill:#21222C}.swimlane-body{stroke:#D6BCFA}.marker path{transform:scale(.8);transform-origin:5px 5px}.edgeLabel rect{transform-box:fill-box;transform-origin:center;transform:scale(1.1,1.2)}"
---
swimlane-beta
  accTitle: Fence review lanes
  accDescr: A fence drafted by the author, themed by the agent, gated by the validator lane on the critical path, and proven by the renderer.
  subgraph author[AUTHOR]
    Draft([Draft fence])
    Commit([Commit])
  end
  subgraph agent[AGENT]
    Theme[Apply canon]
    Inspect[Inspect PNG]
  end
  subgraph validator[VALIDATOR]
    Gate{Gate?}
  end
  subgraph renderer[RENDERER]
    Render[Render proof]
  end
  Draft --> Theme
  Theme --> Gate
  Gate -->|pass| Render
  Gate --> Theme
  Render --> Inspect
  Inspect --> Commit
  classDef primary fill:#44475A,stroke:#FF79C6,color:#F8F8F2
  classDef boundary fill:#282A36,stroke:#BD93F9,color:#F8F8F2
  classDef error fill:#FF555580,stroke:#FF5555,color:#F8F8F2
  class Draft,Commit boundary
  class Theme,Inspect,Render primary
  class Gate error
  linkStyle 3 stroke:#FF5555,stroke-width:3px,color:#F8F8F2
  linkStyle 4 stroke:#50FA7B,color:#F8F8F2
  style validator fill:#BD93F91A,stroke:#BD93F9
```

A standalone diagram reusing the flowchart body under a layered orthogonal layout: every top-level `subgraph` is a lane, nodes inside it belong to it, and loose nodes fall into a synthetic unlabeled lane. The full flowchart styling surface travels — `classDef`, `class`, `linkStyle`, edge labels — so the six-rail edge law binds here verbatim; `swimlane.lineHops: arc` hops edge crossings, and `style laneId fill:...,stroke:...` emphasizes the critical-path lane as a translucent purple band. Lane titles are `.cluster-label` container titles taking the 13.5px/700 Lavender stamp over a recessed `.swimlane-title` band with `.swimlane-body` Lavender walls. A label on a return edge orphans away from its stroke, so the fault return rides the Red rail alone — color carries the semantics the label cannot.

## [23]-[EVENTMODELING]

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
    textColor: "#F8F8F2"
    emUiFill: "#44475A"
    emUiStroke: "#BD93F9"
    emCommandFill: "#44475A"
    emCommandStroke: "#8BE9FD"
    emEventFill: "#44475A"
    emEventStroke: "#FFB86C"
    emProcessorFill: "#21222C"
    emProcessorStroke: "#6272A4"
    emReadModelFill: "#21222C"
    emReadModelStroke: "#50FA7B"
    emSwimlaneBackgroundOdd: "#282A36"
    emSwimlaneBackgroundStroke: "#44475A"
    emArrowhead: "#FF79C6"
    emRelationStroke: "#FF79C6"
  themeCSS: ".em-box span{font-family:'SF Mono',Menlo,'Cascadia Mono',Consolas,monospace;font-size:13px;color:#F8F8F2}.em-box code{color:#8BE9FD;font-size:11px}.em-swimlane text{fill:#D6BCFA;font-size:13.5px;font-family:'SF Mono',Menlo,'Cascadia Mono',Consolas,monospace}"
---
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

The fence asserts a cart flow from UI through commands and events into a read model and a payment processor; `accTitle`/`accDescr` break the parser before the frames, so the relation sentence rides beside the fence. `tf`/`timeframe` orders frames left to right and `rf`/`resetframe` restarts the clock; frame kinds are `ui`, `cmd`, `evt`, `pcr` (processor), and `rmo` (read model), an inline `{ ... }` or `` `json`{ ... } `` payload annotates a frame, and each kind reads its `em*Fill`/`em*Stroke` pair. Relations infer from the nearest prior frame in a different lane, so declaration order draws the chain. Frame text hardcodes a bold 16px sans inside `foreignObject` spans — the `.em-box span` stamp restores the mono stack at 13px with Foreground ink, `.em-box code` inks payloads Cyan at 11px, and `.em-swimlane text` carries the lane titles in Lavender mono. Namespaced frame ids (`stream.Name`) map onto extra swimlanes.

## [24]-[VENN]

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
    textColor: "#F8F8F2"
    vennTitleTextColor: "#F8F8F2"
    vennSetTextColor: "#F8F8F2"
  themeCSS: ".venn-title{font-size:15px;font-weight:600}.venn-circle text{font-size:14px;font-weight:600}.venn-intersection text{font-size:12px}.venn-text-node{font-size:12px}"
---
venn-beta
  title Corpus Coverage
  set A["Authored"] : 80
  set B["Rendered"] : 70
  set C["Validated"] : 60
  union A,B ["Proofed"] : 42
  union B,C ["Gated"] : 34
  union A,C : 26
  union A,B,C ["Canon"] : 18
  style A fill: #BD93F9, fill-opacity: 0.3, stroke: #BD93F9, stroke-width: 1.5, color: #F8F8F2
  style B fill: #8BE9FD, fill-opacity: 0.3, stroke: #8BE9FD, stroke-width: 1.5, color: #F8F8F2
  style C fill: #50FA7B, fill-opacity: 0.3, stroke: #50FA7B, stroke-width: 1.5, color: #F8F8F2
```

The fence asserts three weighted sets overlapping into labeled proof regions; the family rejects `accTitle`/`accDescr` at parse, so the relation sentence rides beside the fence. `set id["Label"] : size` declares a weighted set, `union A,B ["Label"] : size` sizes and captions an overlap, higher-arity unions list every member, and `style targets key: value, ...` carries per-set `fill`, `fill-opacity`, `stroke`, `stroke-width`, and `color` — the translucent law lands natively as hue fills at `.3` under full-hue strokes with per-set Foreground label ink. Region captions ride the union labels at the region centroids, so overlaps read without leaders or a legend. Set and intersection label sizes scale from canvas width at engine ratios; the `.venn-title`, `.venn-circle text`, and `.venn-intersection text` stamps pull them onto the type ramp. Up to eight sets read `venn1`–`venn8` where no per-set style speaks.

## [25]-[WARDLEY]

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
    textColor: "#F8F8F2"
    wardleyEvolutionColor: "#50FA7B"
    wardley:
      backgroundColor: "#282A36"
      axisColor: "#6272A4"
      axisTextColor: "#F8F8F2"
      gridColor: "#44475A"
      componentFill: "#44475A"
      componentStroke: "#BD93F9"
      componentLabelColor: "#F8F8F2"
      linkStroke: "#FF79C6"
      evolutionStroke: "#50FA7B"
      annotationStroke: "#6272A4"
      annotationTextColor: "#F8F8F2"
      annotationFill: "#282A36"
---
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

Coordinates are `[visibility, evolution]` on `0`–`1`; `component` places a capability, `->` a dependency link, `evolve` draws the evolution trend to a target maturity, and OWM grammar adds `pipeline`, `note`, decorators, and inertia. Colors nest under `wardley:` with `wardleyEvolutionColor` owning the trend arrow — Green marks sanctioned movement. The family emits no stylesheet, so `themeCSS`, the mono stack, and font metrics never reach it: label and axis sizes are engine-owned, and the `anchor` node inks its label engine-black, so a dark-canvas map models the user need as its top component instead. Component nodes ride `componentFill`/`componentStroke`, labels `componentLabelColor`, links `linkStroke`, and the stage boundary dashes stay engine-dark as background texture.

## [26]-[ISHIKAWA]

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
    textColor: "#F8F8F2"
    primaryColor: "#44475A"
    primaryTextColor: "#F8F8F2"
    primaryBorderColor: "#BD93F9"
    mainBkg: "#44475A"
    lineColor: "#FF79C6"
---
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

The fence asserts a render failure traced through browser, asset, and syntax cause families into nested sub-causes; the family mis-handles `accTitle`/`accDescr`/`title` as spurious head nodes, so the relation sentence rides beside the fence. The quoted head names the effect, top-level identifiers are cause categories, quoted children are causes, and depth rides indentation — meaningful growth deepens existing branches into sub-causes rather than adding head-level categories. The beta reads the general variables only: `lineColor` draws spine, branches, arrowheads, and box borders, `mainBkg` fills the head and cause boxes, and sub-branches thin to 1px under the 2px primary bones — the ladder expressed with the two weights the engine owns.
