# [H1][STYLING]

Themes, looks, themeVariables, classDef, linkStyle, Edge ID, CSS injection, accessibility.

[CRITICAL] Hex colors required — `#RRGGBB` or `#RRGGBBAA`; named colors NOT recognized.
[REFERENCE] Validation: [->validation.md§01](./validation.md#01-configuration)

## [01]-[THEMES_LOOKS]

**Themes:** `base` (customizable via themeVariables), `default`, `dark`, `forest`, `neutral` (not customizable).
**Looks (v11.0+):** `neo` (default modern), `classic` (traditional), `handDrawn` (sketch). Applies to `flowchart`, `state`, `packet`.

[IMPORTANT] ONLY `theme: base` accepts `themeVariables`.

## [02]-[THEMEVARIABLES]

**Core:** `background` (#f4f4f4), `darkMode` (false), `fontFamily` (trebuchet ms), `fontSize` (16px), `primaryColor` (#fff4dd, derives secondary/tertiary/borders), `primaryTextColor`, `primaryBorderColor`, `secondaryColor`, `tertiaryColor`, `lineColor`.

**Diagram-specific variables:**
- *Flowchart:* `mainBkg`, `nodeBorder`, `nodeTextColor`, `clusterBkg`, `clusterBorder`, `edgeLabelBackground`, `defaultLinkColor`, `titleColor`
- *Sequence:* `actorBkg`, `actorBorder`, `signalColor`, `noteBkgColor`, `activationBkgColor`, `sequenceNumberColor`
- *State:* `stateBkg`, `compositeBackground`, `compositeBorder`, `transitionColor`, `specialStateColor`
- *Class:* `classText`
- *Gantt:* `sectionBkgColor`, `taskBkgColor`, `activeTaskBkgColor`, `critBkgColor`, `doneTaskBkgColor`, `gridColor`, `todayLineColor`
- *Pie:* `pie1`-`pie12`, `pieStrokeColor`, `pieTitleTextColor`
- *GitGraph:* `git0`-`git7`, `commitLabelColor`, `tagLabelColor`
- *Journey:* `fillType0`-`fillType7`
- *Quadrant:* `quadrant1Fill`-`quadrant4Fill`, `quadrantPointFill`
- *Radar (nested `radar:`):* `axisColor`, `curveOpacity`, `graticuleColor`
- *Timeline/C4:* `cScale0`-`cScale11`, `cScaleLabel0`-`cScaleLabel11`
- *Requirement:* `requirementBackground`, `requirementBorderColor`, `relationColor`
- *Architecture:* `archEdgeColor`, `archEdgeArrowColor`, `archGroupBorderColor`

## [03]-[CLASSDEF]

**Declaration:** `classDef name prop:val,prop:val` | `classDef cls1,cls2 prop:val` | `classDef default prop:val`.
**Properties:** `fill`, `stroke`, `stroke-width`, `stroke-dasharray` (escape commas `5\,5`), `color`, `font-size`, `font-weight`, `opacity`, `rx`, `ry`.
**Application:** `NodeID:::className` | `class nodeId className` | `class id1,id2 className`.
**Inline:** `style nodeId prop:val,prop:val` — place after node definitions.
**Supported:** `flowchart`, `state`, `class`, `requirement`, `quadrant`, `treemap`, `architecture`.

[CRITICAL] Notes and namespaces NOT styleable; place `classDef` at diagram end; subgraph titles NOT individually styleable.

## [04]-[LINKSTYLE_EDGE_ID]

**linkStyle:** `linkStyle 0 stroke:#hex,stroke-width:2px` (single), `linkStyle 0,1,2 stroke:#hex` (multiple), `linkStyle default stroke:#hex`, `linkStyle -` (previous edge, v11.6.0+).
**Properties:** `stroke`, `stroke-width`, `color` (labels), `stroke-dasharray`, `fill` (none).
**Curves:** `basis`, `bumpX`, `cardinal`, `catmullRom`, `linear`, `monotoneX`, `natural`, `step`, `stepAfter`, `stepBefore`.

**Edge ID (v11.6.0+):** `A e1@--> B`, `e1@{ animate: true }` | `e1@{ animation: fast|slow }`.
**Combined (v11.10.0+):** `e1@{ curve: linear, animation: fast }`.
**Animation CSS:** `stroke-dasharray`, `stroke-dashoffset`, `animation`. Timing: `linear`, `ease-in`, `ease-out`, `cubic-bezier()`.

[CRITICAL] Edge ID cannot style `color` or `stroke` directly — use `linkStyle`.
[IMPORTANT] Indices 0-based in declaration order; only `-` references previous edge.

## [05]-[CSS_INJECTION]

`.cssClass > rect { fill: #ff0000 !important; }`, `.er.entityBox { stroke: #0000ff !important; }`.

[CRITICAL] Use `!important` — Mermaid CSS takes precedence; Shadow DOM prevents override; ER requires `themeCSS`.

## [06]-[ACCESSIBILITY]

**Directives:** `accTitle: Title text`, `accDescr: Description text`, `accDescr { multi-line }`. Place after diagram type; generates `<title>` and `<desc>` with `aria` attributes.

[IMPORTANT] Known issues: `block-beta` (#6524) and `mindmap` (#4167) — treated as nodes or parse errors.
