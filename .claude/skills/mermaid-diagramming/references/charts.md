# [H1][CHARTS]

Seven chart types: `pie`, `quadrantChart`, `xychart-beta`, `radar-beta`, `sankey-beta`, `gantt`, `treemap-beta`.

[REFERENCE] Theme, classDef: [->styling.md](./styling.md)
[REFERENCE] Validation: [->validation.md§07](./validation.md#07-chart_diagrams)

## [01]-[PIE]

**Declaration:** `pie` | `pie showData` (display percentages). `title Text`, `"Label" : value`.
**Config:** `textPosition` (0.0-1.0, default 0.75), `useMaxWidth` (true).
**Theme:** `pie1`-`pie12` (slice colors, sequential), `pieStrokeColor`, `pieTitleTextColor`, `pieSectionTextColor`.

[IMPORTANT] Hex colors only — theming engine rejects color names.

## [02]-[QUADRANT]

**Declaration:** `quadrantChart`. `title Text`, `x-axis Low --> High`, `y-axis Low --> High`, `quadrant-1 Label` through `quadrant-4 Label`, `Item: [x, y]` (0-1 range).
**Numbering:** 1=Top-right, 2=Top-left, 3=Bottom-left, 4=Bottom-right.
**Point styling:** Direct `Item: [0.6, 0.3] radius: 15, color: #hex` or classDef `Item:::cls: [x, y]`.
**Theme:** `quadrant1Fill`-`quadrant4Fill`, `quadrantPointFill`, axis text fills.
**Config:** `chartWidth/Height` (500), `pointRadius` (5), `xAxisPosition` (top|bottom), `yAxisPosition` (left|right).

## [03]-[XYCHART]

**Declaration:** `xychart-beta` | `xychart-beta horizontal`.
**Syntax:** `title "Text"`, `x-axis [a, b, c]` (categories) or `x-axis "Label" min --> max` (range), `y-axis "Label" min --> max`, `bar [values]`, `line [values]`.
**Config:** `width` (700), `height` (500), `chartOrientation` (vertical|horizontal), `showDataLabel` (false).
**Theme (nested `xyChart:`):** `backgroundColor`, `titleColor`, `xAxisLabelColor`, `yAxisLabelColor`, `plotColorPalette` (comma-separated).

[CRITICAL] Array lengths must match x-axis category count.

## [04]-[RADAR]

**Declaration:** `radar-beta` (v11.6.0+).
**Syntax:** `title Text`, `axis A, B, C, D, E`, `max value`, `min value`, `ticks N`, `graticule polygon|circle`, `"Series": [values]`, `showLegend`.
**Config:** `width/height` (600), `marginTop/Bottom/Left/Right` (50), `curveTension` (0.17).
**Theme (nested `radar:`):** `axisColor`, `curveOpacity` (0.7), `curveStrokeWidth` (2), `graticuleColor`. Colors: `cScale0`-`cScale11`.

[IMPORTANT] Axis count must match value array length. Omitting `max` triggers auto-scaling.

## [05]-[SANKEY]

**Declaration:** `sankey-beta`. CSV format — `Source,Target,Value` per line.
**Config:** `width` (600), `height` (400), `linkColor` (gradient|source|target|#hex), `nodeAlignment` (justify|center|left|right), `showValues` (true), `prefix`/`suffix` (string).

[IMPORTANT] DAG structure only — circular flows rejected.

## [06]-[GANTT]

**Declaration:** `gantt`. `title Text`, `dateFormat YYYY-MM-DD`, `axisFormat %m-%d`, `section Name`.
**Task:** `Name :modifiers, id, start, duration|end`. Start: date, `after taskId`, `until taskId`. Duration: `7d`, `2w`, `1m`.
**Modifiers:** `done` (complete), `active` (current), `crit` (critical path), `milestone` (zero-duration), `vert` (vertical marker).
**Exclusions:** `excludes weekends`, `excludes 2024-01-15`, `includes 2024-01-20`, `weekend friday` (v11.0.0+).
**Display:** `todayMarker off|stroke-width:5px`, `tickInterval 1day|1week|1month`, `displayMode: compact`, `topAxis`.
**Config:** `barHeight` (20), `barGap` (4), `fontSize` (11), `numberSectionStyles` (4).
**Theme:** `sectionBkgColor`, `taskBkgColor`, `activeTaskBkgColor`, `critBkgColor`, `doneTaskBkgColor`, `gridColor`, `todayLineColor`.

[CRITICAL] `%%{init:...}%%` deprecated v10.5.0; use YAML frontmatter exclusively.
[IMPORTANT] Only `base` theme exposes full themeVariables customization.

## [07]-[TREEMAP]

**Declaration:** `treemap-beta`. Hierarchy via indentation — sections `"Name"` (no value), leaves `"Name": value`.
**Styling:** `"Name":::className: value`, `classDef className fill:#hex`.
**Config:** `padding` (10), `diagramPadding` (8), `showValues` (true), `valueFormat` (D3 specifier: `.2f`, `.0%`, `$,.2f`), `labelFontSize` (14), `valueFontSize` (12).
