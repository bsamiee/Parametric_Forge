# [THEMING]

Dracula is the skill's theme system — every committed diagram opens `theme: base` with `look: classic` and draws its colors from the Dracula token table below; ad-hoc hexes outside the table are a defect, and a translucent fill carries a table hex plus its ruled alpha suffix.

## [01]-[PALETTE]

| [INDEX] | [TOKEN]    | [HEX]     | [SEMANTIC_ROLE]                    |
| :-----: | :--------- | :-------- | :--------------------------------- |
|  [01]   | Background | `#282A36` | host surface + bright-fill text    |
|  [02]   | Darker     | `#21222C` | recessed surface + dormant fill    |
|  [03]   | Selection  | `#44475A` | node fill                          |
|  [04]   | Comment    | `#6272A4` | muted line + annotation            |
|  [05]   | Foreground | `#F8F8F2` | label text                         |
|  [06]   | Cyan       | `#8BE9FD` | external system + typed interface  |
|  [07]   | Green      | `#50FA7B` | success rail + executed capability |
|  [08]   | Lavender   | `#D6BCFA` | container boundary + title ink     |
|  [09]   | Orange     | `#FFB86C` | data store + durable fact          |
|  [10]   | Pink       | `#FF79C6` | primary control flow               |
|  [11]   | Purple     | `#BD93F9` | node ownership border + focus      |
|  [12]   | Red        | `#FF5555` | error rail + rejection             |
|  [13]   | Yellow     | `#FFD866` | payload + literal content          |

Current Line and Comment share `#6272A4`; Selection `#44475A` is the fill shade. `themeVariables` take hex only — the theming engine rejects named colors there, and this corpus carries palette hexes on every styling surface.

Lavender is Purple lifted two lightness steps at the same hue — OKLCH `0.84 0.089 304` against Purple's `0.74 0.149 302` — so a container boundary reads as the ownership hue with the luminance a 1px dashed line needs on the dark canvas (8.4:1 against Background, versus Purple's 5.9:1). One hue family carries all ownership; lightness alone separates the node border from the container boundary. Lavender projects into the html-studio system as the `--boundary` token, so both skills draw containment in one color.

Yellow sits at OKLCH `0.89 0.139 90` — true gold, clear of the green-adjacent lemon zone above hue 105 and below near-white lightness, so a payload chip holds shape instead of bleaching. Gold at hue 90 is near-complementary to the violet ground at hue 290, and it stays 24 OKLCH degrees from Orange's 67, so payload and data never blur.

## [02]-[ROLE_MAP]

Every token carries its role on two surfaces at once: the `themeVariables` that spend it diagram-wide and the `classDef` or `linkStyle` rail that spends it per node and per edge. A token holding a role with no rail is unspendable, so every token names both surfaces. Same meaning, same token, across every diagram in a corpus; a role outside this set composes from the nearest listed role, never a new hex.

[BACKGROUND]:

- Role: canvas + bright-fill text
- Theme carriers: `background`, bright-ordinal `*Label*`, `sequenceNumberColor`
- Class or rail: `color:#282A36` on every bright translucent class

[DARKER]:

- Role: recessed container + dormant / done + label backing
- Theme carriers: `clusterBkg`, `compositeBackground`, `tertiaryColor`, `doneTaskBkgColor`, `sectionBkgColor`, `edgeLabelBackground`, `labelBackgroundColor`, `labelBoxBkgColor`, `relationLabelBackground`
- Class or rail: `recessed` class; recessed label backing

[SELECTION]:

- Role: neutral fill + activation + neutral note
- Theme carriers: `mainBkg`, `primaryColor`, `actorBkg`, `taskBkgColor`, `noteBkgColor`, `activationBkgColor`, `altBackground`, `compositeTitleBackground`
- Class or rail: `primary` fill

[COMMENT]:

- Role: secondary rail + muted stroke + neutral-note border
- Theme carriers: `secondaryColor`, `gridColor`, `noteBorderColor`, `actorLineColor`, `git7`
- Class or rail: `annotation` stroke; dashed trace rail

[FOREGROUND]:

- Role: label text
- Theme carriers: every `*TextColor`, `textColor`
- Class or rail: `color:#F8F8F2` on dark and deep-translucent classes

[CYAN]:

- Role: external system / typed interface
- Theme carriers: `git2`, `pie2`, `cScale1`, `plotColorPalette`
- Class or rail: `external` class; external rail

[GREEN]:

- Role: success / executed
- Theme carriers: `git3`, `pie3`, `cScale2`
- Class or rail: `success` class; success rail

[LAVENDER]:

- Role: container boundary + container title ink
- Theme carriers: `clusterBorder`, `compositeBorder`, `titleColor`, `labelBoxBorderColor`, `archGroupBorderColor`
- Class or rail: the 1px dashed container border and its title, every container family, both skills

[ORANGE]:

- Role: data store / durable fact
- Theme carriers: `git4`, `pie4`, `cScale3`
- Class or rail: `data` class; data rail

[PINK]:

- Role: primary control flow + terminus marks
- Theme carriers: `lineColor`, `arrowheadColor`, `signalColor`, `transitionColor`, `todayLineColor`
- Class or rail: `primary` stroke; default rail; arrowheads, pseudostate discs, terminal rings, lollipop rings

[PURPLE]:

- Role: node ownership border / focus
- Theme carriers: `nodeBorder`, `primaryBorderColor`, `actorBorder`, `taskBorderColor`, `activationBorderColor`, `git0`
- Class or rail: `boundary` stroke; solid on nodes, never on containers

[RED]:

- Role: error / rejection / forbidden
- Theme carriers: `critBkgColor`, `critBorderColor`, `git5`, `pie6`, `cScale5`
- Class or rail: `error` class; error rail on every fault edge

[YELLOW]:

- Role: payload / literal / tag / attention note
- Theme carriers: `tagLabelBackground`, `git6`, `pie7`, `cScale6`, class-diagram `noteBkgColor`
- Class or rail: `payload` class; payload rail; class-note chip; gitgraph tag; treeview highlight; railroad terminal — every carrier translucent gold under Foreground ink

## [03]-[BASE_BLOCK]

The block carries the high-traffic themed families; a family absent here takes its keys from its type's section or its local style law, and a diagram carries only the keys its type consumes. `look: classic`, `useGradient: false`, and `dropShadow: "none"` open every themed fence beside `theme: base` — the render-flat lock the border canon owns.

```yaml copy-safe
---
config:
    theme: base
    look: classic
    themeVariables:
        darkMode: true
        fontFamily: 'SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace'
        useGradient: false
        dropShadow: 'none'
        background: '#282A36'
        primaryColor: '#44475A'
        primaryTextColor: '#F8F8F2'
        primaryBorderColor: '#BD93F9'
        secondaryColor: '#6272A4'
        secondaryTextColor: '#F8F8F2'
        secondaryBorderColor: '#6272A4'
        tertiaryColor: '#21222C'
        tertiaryTextColor: '#F8F8F2'
        tertiaryBorderColor: '#44475A'
        mainBkg: '#44475A'
        nodeBorder: '#BD93F9'
        nodeTextColor: '#F8F8F2'
        lineColor: '#FF79C6'
        arrowheadColor: '#FF79C6'
        textColor: '#F8F8F2'
        titleColor: '#D6BCFA'
        clusterBkg: '#21222C'
        clusterBorder: '#D6BCFA'
        compositeBackground: '#21222C'
        compositeTitleBackground: '#282A36'
        compositeBorder: '#D6BCFA'
        altBackground: '#282A36'
        edgeLabelBackground: '#21222C'
        labelBackgroundColor: '#21222C'
        noteBkgColor: '#44475A'
        noteTextColor: '#F8F8F2'
        noteBorderColor: '#6272A4'
        actorBkg: '#44475A'
        actorBorder: '#BD93F9'
        actorTextColor: '#F8F8F2'
        actorLineColor: '#6272A4'
        signalColor: '#FF79C6'
        signalTextColor: '#F8F8F2'
        sequenceNumberColor: '#282A36'
        activationBkgColor: '#44475A'
        activationBorderColor: '#BD93F9'
        labelBoxBkgColor: '#21222C'
        labelBoxBorderColor: '#D6BCFA'
        labelTextColor: '#F8F8F2'
        loopTextColor: '#F8F8F2'
        classText: '#F8F8F2'
        requirementBackground: '#44475A'
        requirementBorderColor: '#BD93F9'
        requirementTextColor: '#F8F8F2'
        relationColor: '#FF79C6'
        relationLabelBackground: '#21222C'
        relationLabelColor: '#F8F8F2'
        attributeBackgroundColorOdd: '#282A36'
        attributeBackgroundColorEven: '#21222C'
        sectionBkgColor: '#21222C'
        altSectionBkgColor: '#282A36'
        sectionBkgColor2: '#21222C'
        excludeBkgColor: '#21222C'
        gridColor: '#6272A4'
        taskBkgColor: '#44475A'
        taskBorderColor: '#BD93F9'
        taskTextColor: '#F8F8F2'
        taskTextOutsideColor: '#F8F8F2'
        taskTextDarkColor: '#F8F8F2'
        activeTaskBkgColor: '#6272A4'
        activeTaskBorderColor: '#BD93F9'
        doneTaskBkgColor: '#21222C'
        doneTaskBorderColor: '#6272A4'
        critBkgColor: '#FF555580'
        critBorderColor: '#FF5555'
        todayLineColor: '#FF79C6'
        vertLineColor: '#8BE9FD'
        fillType0: '#FF79C680'
        fillType1: '#8BE9FD66'
        fillType2: '#50FA7B66'
        fillType3: '#FFB86C66'
        fillType4: '#BD93F980'
        fillType5: '#FF555580'
        fillType6: '#FFD86654'
        fillType7: '#6272A4'
        actor0: '#BD93F9'
        actor1: '#8BE9FD'
        actor2: '#50FA7B'
        actor3: '#FFB86C'
        actor4: '#FF79C6'
        actor5: '#6272A4'
        faceColor: '#FFD86654'
        personBorder: '#BD93F9'
        personBkg: '#44475A'
        archEdgeColor: '#FF79C6'
        archEdgeArrowColor: '#FF79C6'
        archEdgeWidth: '2'
        archGroupBorderColor: '#D6BCFA'
        archGroupBorderWidth: '1'
        git0: '#BD93F9'
        git1: '#FF79C6'
        git2: '#8BE9FD'
        git3: '#50FA7B'
        git4: '#FFB86C'
        git5: '#FF5555'
        git6: '#FFD866'
        git7: '#6272A4'
        gitBranchLabel0: '#282A36'
        gitBranchLabel1: '#282A36'
        gitBranchLabel2: '#282A36'
        gitBranchLabel3: '#282A36'
        gitBranchLabel4: '#282A36'
        gitBranchLabel5: '#282A36'
        gitBranchLabel6: '#282A36'
        gitBranchLabel7: '#282A36'
        commitLabelColor: '#F8F8F2'
        commitLabelBackground: '#21222C'
        commitLabelFontSize: '11px'
        tagLabelColor: '#F8F8F2'
        tagLabelBackground: '#FFD86654'
        tagLabelBorder: '#FFD866'
        tagLabelFontSize: '11px'
        pie1: '#FF79C6'
        pie2: '#8BE9FD'
        pie3: '#50FA7B'
        pie4: '#FFB86C'
        pie5: '#BD93F9'
        pie6: '#FF5555'
        pie7: '#FFD866'
        pie8: '#8BE9FD'
        pie9: '#50FA7B'
        pie10: '#FFB86C'
        pie11: '#BD93F9'
        pie12: '#FF5555'
        pieOpacity: 1
        pieStrokeWidth: '1.5px'
        pieOuterStrokeWidth: '0px'
        pieSectionTextSize: '13px'
        pieSectionTextColor: '#F8F8F2'
        pieLegendTextSize: '12px'
        pieLegendTextColor: '#F8F8F2'
        pieTitleTextSize: '15px'
        pieTitleTextColor: '#F8F8F2'
        cScale0: '#FF79C6'
        cScale1: '#8BE9FD'
        cScale2: '#50FA7B'
        cScale3: '#FFB86C'
        cScale4: '#BD93F9'
        cScale5: '#FF5555'
        cScale6: '#FFD866'
        cScale7: '#8BE9FD'
        cScale8: '#50FA7B'
        cScale9: '#FFB86C'
        cScale10: '#BD93F9'
        cScale11: '#FF5555'
        cScaleLabel0: '#282A36'
        cScaleLabel1: '#282A36'
        cScaleLabel2: '#282A36'
        cScaleLabel3: '#282A36'
        cScaleLabel4: '#282A36'
        cScaleLabel5: '#282A36'
        cScaleLabel6: '#282A36'
        cScaleLabel7: '#282A36'
        cScaleLabel8: '#282A36'
        cScaleLabel9: '#282A36'
        cScaleLabel10: '#282A36'
        cScaleLabel11: '#282A36'
        xyChart:
            backgroundColor: '#282A36'
            titleColor: '#F8F8F2'
            dataLabelColor: '#F8F8F2'
            legendTextColor: '#F8F8F2'
            xAxisLabelColor: '#F8F8F2'
            xAxisTitleColor: '#F8F8F2'
            xAxisTickColor: '#6272A4'
            xAxisLineColor: '#6272A4'
            yAxisLabelColor: '#F8F8F2'
            yAxisTitleColor: '#F8F8F2'
            yAxisTickColor: '#6272A4'
            yAxisLineColor: '#6272A4'
            plotColorPalette: '#FF79C6,#8BE9FD,#50FA7B,#FFB86C,#BD93F9,#FF5555,#FFD866'
        radar:
            axisColor: '#6272A4'
            axisStrokeWidth: 1.5
            graticuleColor: '#44475A'
            graticuleOpacity: 0.4
            curveOpacity: 0.35
            curveStrokeWidth: 2
---
```

- `theme: base` is the only theme accepting `themeVariables`; every unset variable derives from `primaryColor`, `background`, or `darkMode`, and a direct override always wins over a derived default.
- `look: classic` pins the flat look, and it wins over any host `initialize` look because fence frontmatter is the highest non-secure config layer; `useGradient: false` and `dropShadow: "none"` kill the gradient-border and halo variables at their source, so the fence stays flat even where a host forces the neo look onto the elements. The border canon owns the full lock.
- `darkMode: true` flips the derived-color math toward the dark host.
- `fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"` is the ruled mono stack, declared once in `themeVariables` and never at config root — every canvas label is mono, resolving through Menlo on Apple and Cascadia Mono or Consolas on Windows. A bare `fontFamily: "monospace"` is a defect, and a hyphenated family token — `ui-monospace`, `SFMono-Regular` — makes the engine emit an empty declaration, silently falling back to the sans default.
- `fontSize` stays inert for gantt, ER, and flowchart — per-class sizing rides `themeCSS` per [05], never that variable.
- `edgeLabelBackground`, `relationLabelBackground`, and the state family's `labelBackgroundColor` carry Darker `#21222C`, one step recessed below the canvas, so a label reads as a subtle recessed chip that masks any crossing stroke without the bright pill a Selection backing paints; a backing equal to `background` renders invisible and a backing left unset derives to near-black, and either collides labels with Pink strokes.
- Containers recess and their boundary reads: `clusterBkg` and `compositeBackground` carry Darker `#21222C` under a `compositeTitleBackground` Background `#282A36` title bar, and `altBackground` carries Background `#282A36` so a nested region reads one step lighter. `clusterBorder`/`compositeBorder`/`archGroupBorderColor` carry Lavender `#D6BCFA` with `titleColor` matching, so border and title read as one boundary object.
- The ER family draws its relationship lines and cardinality markers from `lineColor` and composites its label backing from `tertiaryColor` — an ER fence that omits either derives pale gray lines and an olive label chip, so both keys are ER floor keys; `relationColor` and its label keys feed the requirement family, never ER.
- `activationBkgColor` carries Selection `#44475A` so a sequence activation reads as a neutral lifted bar over its lifeline, and `sequenceNumberColor` carries Background `#282A36` so autonumber chips print dark numerals on their Pink discs.
- `critBkgColor` carries the ruled translucent Red `#FF555580` under a solid `critBorderColor`, so a critical gantt bar reads as the same alarm chip an `error` node paints; `excludeBkgColor` recesses excluded date bands and `taskTextDarkColor` joins the Foreground ink set because done bars recess to Darker.
- Neutral notes fill Selection under a Comment border for sequence and state; the class-diagram note overrides to the translucent Yellow chip per [04].
- Bright translucent fills take `#282A36` text on the dark-ink tier and `#F8F8F2` text on the light-ink tier — the two-tier table in [04] is the owner. The journey `fillType` set, the gitgraph tag, and the face chip ship in light-ink form here.
- Ordinal families run their full engine range here — `pie1`–`pie12`, `cScale0`–`cScale11` with `cScaleLabel0`–`cScaleLabel11`, `fillType0`–`fillType7`, `git0`–`git7` — so no band derives to `primaryColor` mud. `cScaleLabel` dark ink serves opaque ordinal fills; a family compositing translucent or recessed ordinal surfaces — timeline, treemap, kanban — overrides its `cScaleLabel` range to Foreground or Lavender in its own fence.
- Per-type nested objects `xyChart` and `radar` nest inside `themeVariables`, alongside any other type that admits a nested block.
- Partial-consumers: C4 reads `personBorder`/`personBkg` from this block and themes element surfaces through `c4:` config color keys plus `UpdateRelStyle`; packet themes through its `themeCSS` class stamp because the nested `themeVariables.packet` block half-applies; sankey and ishikawa take global vars only; wardley emits no stylesheet, so only its nested `wardley:` colors land.
- This block is the single home for every corpus-wide token: an extended fence demonstrates the keys it consumes and never privately defines a role — `architecture`, `journey`, and C4 tokens live here, not in their fences.

## [04]-[CLASSDEF_LINKSTYLE]

Each surface owns one color job; ceding it to another is the defect, and every `classDef` sets an explicit `color:` to survive a host swap. Class names are free-form — an archetype names its own semantic classes — while every hex a class carries traces to the palette table.

| [INDEX] | [SURFACE]        | [OWNS]                                     |
| :-----: | :--------------- | :----------------------------------------- |
|  [01]   | `themeVariables` | diagram-wide defaults                      |
|  [02]   | `classDef`       | semantic node classes, id-bound edge rails |
|  [03]   | `linkStyle`      | positional per-edge semantic rails         |
|  [04]   | inline `style`   | one-off node exception                     |
|  [05]   | `themeCSS`       | renderer escape hatch                      |

Every accent-colored shape fills translucent: the fill carries its palette hex with an alpha suffix while the border holds the same hue at 100% opacity and a slightly thinner weight, so the canvas tone breathes through the fill and depth reads without any shadow. The alpha per hue derives from one law — the composited fill must hold at least 4.5:1 against its declared ink — and resolves into two tiers. The dark-ink tier runs the high-luminance accents at 75% under `#282A36` ink; the light-ink tier drops each hue until `#F8F8F2` ink measures, which is where Yellow always lives — white ink on gold is the yellow law, so a gold chip is a low-alpha wash under a full gold border, never a bright pill with dark ink — and where Pink, Purple, and Red live at every alpha, since no alpha lets them carry dark ink:

| [INDEX] | [TIER]    | [ACCENT] | [FILL]      | [ALPHA] | [INK]     | [COMPOSITE_CONTRAST] |
| :-----: | :-------- | :------- | :---------- | :-----: | :-------- | :------------------: |
|  [01]   | dark-ink  | Green    | `#50FA7BBF` |   75%   | `#282A36` |        `6.5`         |
|  [02]   | dark-ink  | Cyan     | `#8BE9FDBF` |   75%   | `#282A36` |        `6.5`         |
|  [03]   | dark-ink  | Orange   | `#FFB86CBF` |   75%   | `#282A36` |        `5.3`         |
|  [04]   | light-ink | Pink     | `#FF79C680` |   50%   | `#F8F8F2` |        `5.3`         |
|  [05]   | light-ink | Purple   | `#BD93F980` |   50%   | `#F8F8F2` |        `5.2`         |
|  [06]   | light-ink | Red      | `#FF555580` |   50%   | `#F8F8F2` |        `6.3`         |
|  [07]   | light-ink | Cyan     | `#8BE9FD66` |   40%   | `#F8F8F2` |        `4.6`         |
|  [08]   | light-ink | Green    | `#50FA7B66` |   40%   | `#F8F8F2` |        `4.7`         |
|  [09]   | light-ink | Orange   | `#FFB86C66` |   40%   | `#F8F8F2` |        `5.2`         |
|  [10]   | light-ink | Yellow   | `#FFD86654` |   33%   | `#F8F8F2` |        `5.5`         |

A node-scale chip takes the dark-ink tier for maximum punch; a family whose engine fixes one ink for every colored surface — journey, pie, timeline, treemap, packet — takes the light-ink tier throughout so Foreground serves everything. Below both tiers sits the wash tier, 10–30% alphas (`1A`–`4D`) for large-area tints that carry no ink of their own: lane emphasis, cynefin domain fields, the treeview highlight band, packet field blocks. Neutral surfaces — Selection, Darker, Background — stay opaque; translucency marks accent semantics, never structure. The canonical Dracula node classes, one per role the role map binds:

```text
classDef primary fill:#44475A,stroke:#FF79C6,color:#F8F8F2
classDef boundary fill:#282A36,stroke:#BD93F9,color:#F8F8F2
classDef success fill:#50FA7BBF,stroke:#50FA7B,color:#282A36
classDef error fill:#FF555580,stroke:#FF5555,color:#F8F8F2
classDef external fill:#8BE9FDBF,stroke:#8BE9FD,color:#282A36
classDef data fill:#FFB86CBF,stroke:#FFB86C,color:#282A36
classDef payload fill:#FFD86654,stroke:#FFD866,color:#F8F8F2
classDef recessed fill:#21222C,stroke:#6272A4,color:#F8F8F2
classDef annotation fill:#21222C,stroke:#6272A4,color:#F8F8F2
```

The callout family lifts one node out of the flow for attention — a recessed `#282A36` fill under a bright `2px` stroke whose hue names the call, so the eye lands where the diagram argues. Purple is the neutral focus; each variant swaps only the stroke and matching text, never the recessed fill:

```text
classDef callout fill:#282A36,stroke:#BD93F9,stroke-width:2px,color:#F8F8F2
classDef calloutOk fill:#282A36,stroke:#50FA7B,stroke-width:2px,color:#F8F8F2
classDef calloutFault fill:#282A36,stroke:#FF5555,stroke-width:2px,color:#F8F8F2
classDef calloutData fill:#282A36,stroke:#FFB86C,stroke-width:2px,color:#F8F8F2
classDef calloutExternal fill:#282A36,stroke:#8BE9FD,stroke-width:2px,color:#F8F8F2
```

A callout node reads against the standing role fills because its recessed surface and heavier stroke set it apart; one or two per diagram hold, a wall of callouts erases the emphasis. The called-out node pairs with an animated hot edge feeding it, so the focus and the flow reaching it read as one gesture.

`recessed` fills a dormant, done, or terminal-adjacent node; `annotation` shares its surface with a Comment stroke and carries side commentary, never flow. On an ER entity a bright class fill floods the attribute rows and collides with the banding, so ER role classes stroke-encode instead — an external registry rides `fill:#21222C,stroke:#8BE9FD,color:#8BE9FD`, the role carried by stroke and title ink on a recessed surface. The class-diagram note alone takes the payload chip — `noteBkgColor: "#FFD86654"`, `noteBorderColor: "#FFD866"`, `noteTextColor: "#F8F8F2"` — because a class note tags an invariant, while sequence and state notes stay neutral Selection captions. The gitgraph tag, the treeview highlight, and the railroad terminal spend the same yellow-law chip: translucent gold, full gold border, Foreground ink.

The edge rails — every semantic edge takes its rail explicitly, and only a plain forward hop rides the default:

```text
linkStyle default stroke:#FF79C6,color:#F8F8F2
linkStyle 1 stroke:#50FA7B,color:#F8F8F2
linkStyle 2 stroke:#FF5555,stroke-width:3px,color:#F8F8F2
linkStyle 3 stroke:#8BE9FD,color:#F8F8F2
linkStyle 4 stroke:#FFB86C,color:#F8F8F2
linkStyle 5 stroke:#6272A4,color:#F8F8F2,stroke-width:1.5px,stroke-dasharray:4 6
```

Rail semantics: Pink primary, Green success, Red error — mandatory on every fault edge — Cyan external, Orange data-carrying, Comment-dashed trace and secondary. Every rail declares `color:#F8F8F2` so its label never falls to a derived color; a rail without an explicit width rides the standing `2px` the micro-scale stamps, the fault rail carries the `3px` emphasis weight, and the trace rail carries the `1.5px` dashed weight — the one ladder in [05]. The engine colors each styled edge's arrowhead from its resolved stroke, so a Red rail terminates in a Red head with no extra key, and `arrowheadColor` governs only unstyled edges. A rail binds two ways with identical semantics: positionally through `linkStyle N` — indices are 0-based parse positions, so every edge insertion or deletion recounts every positional index before the diagram ships — or insertion-stably through an edge id, `A e1@--> B` then `class e1 edgeError`, where the id form survives the insertions that renumber every positional index; a fence under ongoing edits prefers the id form. The canonical edge classes mirror the non-default rails:

```text
classDef edgeSuccess stroke:#50FA7B,color:#F8F8F2
classDef edgeError stroke:#FF5555,stroke-width:3px,color:#F8F8F2
classDef edgeExternal stroke:#8BE9FD,color:#F8F8F2
classDef edgeData stroke:#FFB86C,color:#F8F8F2
classDef edgeTrace stroke:#6272A4,color:#F8F8F2,stroke-width:1.5px,stroke-dasharray:4 6
```

## [05]-[MICRO_SCALE]

Per-element sizing rides `themeCSS`, never `themeVariables.fontSize`. Every value is an exact stamp over the SVG-px scale on a three-step type ramp — 13.5 bold container title, 13 primary, 12 tertiary — and nothing on a mermaid canvas renders below the 12px floor, since SVG text carries no hinting and sits below a hinted HTML equivalent at equal size. The container title sits above the node label deliberately: containment names the largest scope on the canvas, so its title carries the heaviest type, and the 13.5px/700 stamp stays under the engine's 16px measurement box, so no titled container clips.

| [INDEX] | [CLASS]                     | [SELECTOR]                               | [PX] | [WEIGHT]               |
| :-----: | :-------------------------- | :--------------------------------------- | :--: | :--------------------- |
|  [01]   | node label                  | `.nodeLabel`                             |  13  | 500                    |
|  [02]   | actor label (sequence)      | `text.actor tspan`                       |  13  | 600                    |
|  [03]   | ER entity name              | `.name .nodeLabel`                       |  13  | 600                    |
|  [04]   | class title                 | `.classTitle`                            |  13  | 600                    |
|  [05]   | container / namespace title | `.cluster-label .nodeLabel`              | 13.5 | 700, uppercase in text |
|  [06]   | edge label                  | `.edgeLabel`                             |  12  | 500                    |
|  [07]   | message text (sequence)     | `.messageText`                           |  12  | 500                    |
|  [08]   | note text                   | `.noteText`, `.noteLabel .nodeLabel`     |  12  | 400                    |
|  [09]   | ER attribute cell           | `.nodeLabel` under ER                    |  12  | 400                    |
|  [10]   | loop / group label          | `.loopText`, `.labelText`                |  12  | 500                    |
|  [11]   | section / lane title        | `.sectionTitle`, kanban `.cluster-label` | 13.5 | 700, Lavender ink      |

The line-weight ladder — one scale, every stroke on the canvas, stated here once and spent verbatim by every stamp, rail, and class:

| [INDEX] | [STROKE]                         | [WEIGHT] | [RATIO] | [FORM]                     |
| :-----: | :------------------------------- | :------: | :-----: | :------------------------- |
|  [01]   | standing edge                    |  `2px`   |  100%   | solid                      |
|  [02]   | fault / critical / emphasis edge |  `3px`   |  150%   | solid                      |
|  [03]   | dashed / dotted edge             | `1.5px`  |   75%   | `4 6` trace, `6 6` planned |
|  [04]   | node border                      | `1.5px`  |   75%   | solid, 100% opacity        |
|  [05]   | callout / emphasis node border   |  `2px`   |  100%   | solid                      |
|  [06]   | container border                 |  `1px`   |   50%   | dashed `5 4`, Lavender     |
|  [07]   | grid / divider stroke            |  `1px`   |   50%   | family-owned dash          |

Marker and circle scale tie to one factor: every arrowhead across every family scales `.8` linear, and every terminal circle scales `.48` — the `.8` squared area factor cut a further 25%, radius `3.4px` on the state start disc — because a filled disc reads by area while a head reads by length, and a circle at the old `.64` still shouldered its label. The circle factor binds every terminal and endpoint disc: state start and terminal ring, flowchart `--o` endpoints, gitgraph commit dots (`.75` transform on the engine radii, preserving merge-ring ratios), journey actor dots (`r:5.25px`), quadrant points (`radius: 4`), railroad start and end (`markerRadius: 4`). ER cardinality rings stay at the `.8` marker scale — they pair with crow's-foot paths as one glyph, never as terminal dots.

The canonical `themeCSS` strings — one per family, copied verbatim into the fence frontmatter. Every node-bearing string carries `filter:none!important` across the node shapes and cluster rects: the belt that outranks any host-injected halo even when a host forces the neo look, since `themeCSS` lands after the engine's look rules and `!important` wins there. Attribute selectors inside a `themeCSS` string quote with single quotes — a double quote closes the YAML string — and no string uses the `>` combinator, which the sanitizer rejects by dropping the whole block.

```text
flowchart: ".nodeLabel{font-size:13px;font-weight:500}.edgeLabel{font-size:12px;font-weight:500}.cluster-label .nodeLabel{font-size:13.5px;font-weight:700;letter-spacing:.08em}.edge-thickness-normal{stroke-width:2px}.edge-thickness-thick{stroke-width:3px}.edge-pattern-dashed,.edge-pattern-dotted{stroke-width:1.5px;stroke-dasharray:4 6}.node rect,.node circle,.node polygon,.node path,.node .outer-path{stroke-width:1.5px;filter:none!important}.cluster rect{stroke-width:1px!important;stroke-dasharray:5 4!important;filter:none!important}.marker path{transform:scale(.8);transform-origin:5px 5px}.marker circle{transform:scale(.48);transform-origin:5px 5px}.edgeLabel rect{transform-box:fill-box;transform-origin:center;transform:scale(1.1,1.2)}"
state:     ".nodeLabel{font-size:13px;font-weight:500}.edgeLabel{font-size:12px;font-weight:500}.cluster-label .nodeLabel{font-size:13.5px;font-weight:700;letter-spacing:.08em;color:#D6BCFA}.transition{stroke-width:2px}.note-edge{stroke-width:1.5px}.node rect,.node circle,.node path,.node .outer-path{stroke-width:1.5px;filter:none!important}.statediagram-cluster rect.outer{stroke:#D6BCFA;stroke-width:1px!important;stroke-dasharray:5 4}.statediagram-state rect.divider{stroke:#D6BCFA;stroke-width:1px;stroke-dasharray:5 4;fill:#282A36}[id*='barbEnd'] path{fill:#FF79C6;stroke:#FF79C6;transform:scale(.4);transform-origin:14px 7px}.state-start{r:3.4px;fill:#FF79C6;stroke:#FF79C6}.node[id*='_end'] .outer-path{transform-box:fill-box;transform-origin:center;transform:scale(.48)}.edgeLabel rect{transform-box:fill-box;transform-origin:center;transform:scale(1.1,1.2)}"
sequence:  "text.actor tspan{font-size:13px;font-weight:600}.messageText{font-size:12px;font-weight:500}.noteText{font-size:12px}.loopText,.labelText{font-size:12px;font-weight:500}.messageLine0{stroke-width:2px}.messageLine1{stroke-width:1.5px;stroke-dasharray:4 6}.actor{stroke-width:1.5px}rect.actor{filter:none!important}[id$='-filled-head'] path{fill:#FF79C6;stroke:#FF79C6}"
class:     ".nodeLabel{font-size:13px;font-weight:500}.edgeLabel{font-size:12px;font-weight:500}.classTitle{font-size:13px;font-weight:600}.cluster-label .nodeLabel,.cluster-label text{font-size:13.5px;font-weight:700;letter-spacing:.08em}.noteLabel .nodeLabel{font-size:12px}.relation{stroke-width:2px}.edge-pattern-dashed,.edge-pattern-dotted{stroke-width:1.5px;stroke-dasharray:4 6}.divider{stroke-width:1px}.node rect,.node path{stroke-width:1.5px;filter:none!important}.cluster rect{stroke-width:1px!important;stroke-dasharray:5 4!important;filter:none!important}.marker path{transform:scale(.8);transform-origin:5px 5px}"
er:        ".nodeLabel{font-size:12px}.name .nodeLabel{font-size:13px;font-weight:600}.edgeLabel .nodeLabel{font-size:12px;font-weight:500}.relationshipLine{stroke-width:2px}.edge-pattern-dashed{stroke-width:1.5px;stroke-dasharray:6 6}.marker path,.marker circle{transform:scale(.8);transform-origin:5px 5px}.marker circle{fill:#282A36}.node rect,.node path{stroke-width:1.5px;filter:none!important}.er.entityBox{filter:none}"
gantt:     ".sectionTitle{font-size:13.5px;font-weight:700;fill:#D6BCFA}.taskText,.taskTextOutsideRight,.taskTextOutsideLeft{font-size:12px}.grid .tick text{font-size:11px}"
```

- `themeCSS` admits no `>` combinator: the sanitizer drops the entire injected block on the first `>`, silently reverting every rule in it — use the descendant space. A `classDef` emits inline `!important` declarations that beat any stylesheet rule including an `!important` one, so the strings above own only what no class carries: typography, bare strokes, weights, and the filter belt.
- The engine measures label boxes before `themeCSS` applies, so a `text-transform` clips its target — the uppercase container title rides the title text itself (`subgraph core[CORE PACKAGE]`), and any size stamped above the measured 16px default clips the same way; the stamps above only step down. A namespace path title (`Company.Engineering.Backend`) renders as declared — case law binds free labels only.
- Weight law: the ladder above is the only weight source — the standing `2px` edge stamps through the engine's own thickness classes, the pattern classes pull every dashed and dotted edge to `1.5px` at the trace rhythm, and a rail that needs another weight carries it inline where it wins by inline precedence.
- Dashed-rhythm law: `4 6` reads as trace and annotation, `6 6` as planned and deferred, `5 4` as container containment, solid as realized — one rhythm system across every diagram; the trace gap runs longer than its dash so a dotted line reads as a distinct rhythm, not a broken solid.
- Canvas law: flowchart fences carry `layout: elk` and `flowchart: { curve: linear, padding: 25 }` — ELK routes orthogonally on its own and paints its bends through a fixed rounded joint, while the `curve: linear` key holds the elbow posture on any host that falls back to the non-ELK renderer; `subGraphTitleMargin` stays out of ELK diagrams, since it displaces edge labels there.
- Marker scale law: Arrowheads scale at `.8`; terminal circles scale at `.48`; state markers stay at `.4`.
- Marker route law: Requirement, C4, and architecture markers use family routes. Every unfilled marker declares fill and stroke.
- Terminus law: every terminus mark rides its line's color — Pink arrowheads, the Pink `state-start` disc at `r:3.4px`, the Pink terminal ring scaled `.48` around its Purple core, the Pink lollipop ring, and ER cardinality marks on the relation stroke with a canvas-filled hollow ring for the zero side; a terminus carries no label while a named state always does. The terminal scale rides `.node[id*='_end'] .outer-path` — the engine draws the ring as a path group, never a circle element.
- Text-color law: container and namespace titles ink Lavender through `titleColor` — the state string carries the ink explicitly because its composite title ignores that key — matching their border so containment reads as one object; node labels ink Foreground; bright translucent fills ink per the [04] table; canvas text takes a surgical color only through these owners, never a blanket dim gray — a family whose title derives gray is missing its `titleColor` key.

## [06]-[BORDER_CANON]

One border system for both skills — every stroke around a shape resolves here, and no border anywhere carries a gradient or a shadow.

- Node borders are solid `1.5px` at 100% opacity: Purple on neutral and boundary nodes, the accent hue on translucent accent fills, Comment on recessed and annotation nodes. A callout or emphasis node steps to `2px`. Weight and opacity never vary past these two steps.
- Container borders — flowchart subgraph, state composite and region, class namespace, architecture group, sequence loop/alt frame — are dashed `1px` Lavender `#D6BCFA` at the `5 4` rhythm: half the standing edge weight, brightness carrying what the thinness gives up at 8.4:1 against the canvas. The container title inks the same Lavender, and html-studio spends the color as its `--boundary` token on every SVG zone border — one containment language across both skills.
- Gradients never render: `useGradient: false` disables the gradient definition and drops the engine's neo stroke back to `nodeBorder`, and `look: classic` keeps the neo selectors from matching at all. No fence, string, or template references a gradient.
- Shadows never render: `dropShadow: "none"` empties the halo variable, and the `filter:none!important` belt in every node-bearing `themeCSS` string overrides the halo rule even on a host that forces `look: neo` at initialize, because user styles land after the look rules and inline-`!important` class styles never carry filters. The engine's halo — a full-opacity light-gray drop shadow that stacks where nodes crowd — never survives this lock.
- The lock is four layers deep because each layer fails differently: `look: classic` wins config resolution, `useGradient`/`dropShadow` win the variable derivation, and the `!important` belt wins the cascade; a host defeats all four only by stripping frontmatter entirely, which no themed fence can survive by any means.

## [07]-[DUAL_HOST]

Node fills and their text travel inside the SVG, so Selection-filled nodes with Foreground text hold on any host. What breaks on a white host is ink drawn over the page — edge strokes, edge labels without a background, transparent-canvas text. Each token carries its WCAG contrast ratio against each host canvas and the duty that ratio clears: `text` at 4.5 and up, `large` from 3.0 to 4.5 (large text plus non-text ink), `fail` below 3.0.

| [INDEX] | [TOKEN]  | [DARK_RATIO] | [DARK_DUTY] | [WHITE_RATIO] | [WHITE_DUTY] |
| :-----: | :------- | :----------: | :---------- | :-----------: | :----------- |
|  [01]   | Comment  |    `3.03`    | large       |    `4.71`     | text         |
|  [02]   | Cyan     |   `10.29`    | text        |    `1.38`     | fail         |
|  [03]   | Green    |   `10.38`    | text        |    `1.37`     | fail         |
|  [04]   | Lavender |    `8.43`    | text        |    `1.69`     | fail         |
|  [05]   | Orange   |    `8.36`    | text        |    `1.70`     | fail         |
|  [06]   | Pink     |    `5.97`    | text        |    `2.39`     | fail         |
|  [07]   | Purple   |    `5.90`    | text        |    `2.41`     | fail         |
|  [08]   | Red      |    `4.53`    | text        |    `3.14`     | large        |
|  [09]   | Yellow   |   `10.35`    | text        |    `1.38`     | fail         |

Red is the only accent clearing non-text duty on both hosts; Comment clears normal text on white and large-only duty on dark; every other accent is dark-host-only ink.

- A diagram whose host is unknown keeps `edgeLabelBackground: "#21222C"` and dark node fills, so labels ride their own lifted surface on any page.
- On a dark host page the `#282A36` canvas reads as a raised panel — inline the SVG on the page body; a container whose fill sits within one elevation step of the canvas erases the diagram edge, so the container steps down a level or frames the SVG with a visible border.
- Pink primary-flow strokes are the standing default; a white-host commitment downgrades line ink to Comment `#6272A4`, the one dual-host line token besides Red.
- A genuinely light-host corpus themes from Alucard, the official light complement, instead of forcing Dracula accents onto white.

Alucard carries the same role map on a light surface: Background `#FFFBEB`, Foreground `#1F1F1F`, Comment `#6C664B`, Selection `#CFCFDE`, Red `#CB3A2A`, Orange `#A34D14`, Yellow `#846E15`, Green `#14710A`, Cyan `#036A96`, Purple `#644AC9`, Pink `#A3144D`. The container boundary shares Purple `#644AC9` there — a thin dark line reads on a light ground without a dedicated lift.

## [08]-[WHEN_THEMING_DROPS]

Theming is omitted whole, never half-applied. Drop the theme block when the fence targets a host that injects its own mermaid theme, such as a docs site with a site-level `initialize`; when the type ignores `themeVariables`, such as packet; or when a diagram is a throwaway scratch artifact that never ships. A committed diagram in this repo is themed, or it carries the reason in its authoring context, not in the fence.
