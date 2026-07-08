# [ELEMENTS]

Every information element is a parameterized generator keyed on data shape, never a fixed drawing: same construction, data-driven variation, tokens from the design system, marks under [svg.md](svg.md). Each entry names the reader question it answers, the construction, the sibling it beats and when, and the axes that parameterize it. An element rendering a capturable region carries stable item ids so the envelope anchors to it (`decisions[].id`, `annotations[].itemId`, `changes[].itemId`); an element that captures nothing renders no capture-styled control. A control on any element either mutates a named envelope field or is a named view convenience — nothing between; the per-type ruling is [artifact-types.md](artifact-types.md).

## [01]-[TIMELINE_FAMILY]

Orientation is a data-shape decision, never a default, and the wrong orientation is the primary timeline defect. One shared model — `{ items:[{id,start,end?,lane?,state,deps?}], today }` — rendered by an orientation switch that never changes the model. Choose by the dominant dimension: parallelism takes lanes, single causality takes the spine, a navigation index takes the side rail, a genuine cycle takes the ring.

- [HORIZONTAL_LANES] — Question: what runs in parallel across workstreams and where does today cut them. Construction: one band per lane, bars positioned by a `start` to x linear scale, milestone diamonds at band centerlines, one `today` line spanning every band. Beats the vertical spine when lanes reach three and simultaneity is the question; axes: `laneCount`, `spanScale`, `barMinInline`, `todayMarker`, `connectorMode` (none | hard-dep | critical-path).
- [VERTICAL_SPINE] — Question: in what causal order did events fire and what state did each leave. Construction: one `border-inline-start` rail of stamped dot rows, a mono time stamp and state chip per row, prose beside each dot. Beats lanes when exactly one prose-bearing sequence exists — incidents, changelogs, decision logs; axes: `stampFormat`, `stateVocab` (closed chip set), `density` (compact stamps or full prose rows), render order is model order — never DOM insertion order.
- [SIDE_RAIL] — Question: how does a fixed sequence index a primary body of content scrolling beside it. Construction: two-column grid, a narrow sticky spine of stamped dots synced by one `IntersectionObserver` to the wide content column, the active dot lit as its section enters the read band. Beats the spine when the timeline is navigation over long-form content, not the content itself; axes: `railSide`, `syncMode` (scroll-spy | click-to-scroll), `stickyOffset`.
- [RADIAL] — Question: what is the phase within a closed cycle that repeats. Construction: one polar SVG, items as arc segments where angle is `phase / period` of the full turn, a rotating today needle. Earns its place only when the domain genuinely cycles and wrap-around adjacency is load-bearing; forbidden for any monotone progression, where a ring destroys the duration comparison a bar row gives free; axes: `period`, `ringRadius`, `segmentPad`, `needle`, `innerLabels` (radial | tangential).

## [02]-[SWIMLANE_FAMILY]

- [RESPONSIBILITY_LANES] — Question: which actor owns each step of a cross-actor process. Construction: horizontal lanes labeled by actor, steps as card-grammar nodes in the owning lane, hand-off edges crossing lane boundaries with `marker-end`. Beats a plain flowchart when the question is ownership and hand-off cost, not logic; axes: `laneAxis` (actor | system | environment), `handoffEmphasis` (lane-crossing edges drawn heavier), `stepState`.
- [PHASE_MATRIX] — Question: which phase gate has each parallel track passed. Construction: vertical phase columns crossed with horizontal track rows, cell fill reading the track's state in that phase. Beats responsibility lanes when phases are the ordered axis and tracks advance at different rates; axes: `phaseCount`, `trackCount`, `cellState` (closed vocabulary), `gateMarkers`.

## [03]-[DEPENDENCY_FAMILY]

Graph versus spine is a topology decision: forcing a linear chain into a node cloud hides the sequence, and forcing a mesh onto a line fabricates one.

- [DEPENDENCY_GRAPH] — Question: how do owners stack and how does a named behavior move across them. Construction: typed `<g data-k>` nodes, directed edges with per-class markers in `<defs>`, flow chips dimming all and lighting one path by animated dash offset, reduced motion stilling it. Beats a spine when edges form a real DAG and multiple named flows overlay one topology; axes: `nodeKinds`, `edgeClasses` (sync | async | fault), `flowSet`, `zoneBands`.
- [DEPENDENCY_SPINE] — Question: what is the single critical chain and what blocks what, linearly. Construction: one ordered axis of bars or rail rows with hard-dependency connectors drawn only backward-to-forward; a forward-crossing arrow is the review defect that convicts the sequence; axes: `chainDirection`, `slackDisplay`, `blockMarkers`.

## [04]-[COMPARISON_AND_DENSITY]

| [INDEX] | [ELEMENT]       | [READER_QUESTION]                                   | [BEATS]                    |
| :-----: | :-------------- | :-------------------------------------------------- | :------------------------- |
|  [01]   | small multiples | how one measure differs across many categories      | one overplotted multi-line |
|  [02]   | sparkline row   | which table rows trend, and with what shape         | a full chart, a bare delta |
|  [03]   | slope chart     | which items rose or fell between exactly two states | grouped before/after bars  |
|  [04]   | segment meter   | what fraction of a bounded whole sits in each state | a pie                      |
|  [05]   | waffle grid     | how many countable units fall in each category      | the segment meter          |
|  [06]   | annotated axis  | where thresholds and events sit against the data    | a bare axis                |
|  [07]   | margin note     | what critique anchors to an exact line or region    | inline interruption        |
|  [08]   | step ribbon     | where the reader stands in a short linear procedure | a numbered list            |
|  [09]   | matrix heatmap  | where two categorical axes intersect most intensely | small multiples            |
|  [10]   | tree indent     | what contains what, hierarchically                  | a flat table               |
|  [11]   | chip taxonomy   | what closed status, kind, or severity an item holds | free-text status           |

- [SMALL_MULTIPLES] — a `.grid` of identical mini-figures: same `viewBox`, same mark, one category per cell, the axis domain locked across every cell — an unlocked domain turns difference into noise, non-negotiable. Wins when series count passes four and per-series shape matters more than exact cross-series values; axes: `cellCount`, `sharedDomain` (locked min and max), `markType` (line | area | bar), `cellMinInline`.
- [SPARKLINE_ROW] — a `<td>`-embedded inline `<svg>` polyline near 120x24, last point dotted, optional min-max band. Wins when the trend annotates a table rather than being the subject, and when shape — spike, plateau, decay — carries what a single delta erases; axes: `pointCount`, `endpointDot`, `bandMode` (none | min-max | threshold), `trendColor` (`--ok`/`--fail` by slope sign).
- [SLOPE_CHART] — two vertical axes for before and after, one line per item connecting its values, slope sign to `--ok`/`--fail`, labels at both ends. Wins when rank change is the message: crossing lines make reordering legible where paired bars bury it; axes: `stateLabels`, `rankMode` (value | rank position), `highlightSet`, `crossingEmphasis`.
- [SEGMENT_METER] — the `.meter.seg` grammar as a segmented bar: one span per state, inline-size equal to share, states in one fixed order, total labeled. Wins over a pie because linear length compares across stacked meters where angle cannot; axes: `segmentVocab` (closed ordered states), `total`, `labelMode` (inline | legend), `targetMarker`.
- [WAFFLE_GRID] — an N-by-M lattice of cells, each one unit or a fixed quantum, filled by category through `--series-N`. Wins when the reader must count units rather than read a proportion and each cell is a real thing; axes: `gridDims`, `unitQuantum`, `categoryOrder`, `fillDirection`.
- [ANNOTATED_AXIS] — a chart axis carrying reference rules (target, limit, today), band labels, and event ticks — every annotation a model row, never hand-placed. Wins when the data means nothing except against named thresholds; axes: `refLines[]` (`{value,label,token}`), `bands[]` (`{from,to,label}`), `eventTicks[]`, `axisSide`.
- [MARGIN_NOTE] — the diff-review annotation rail: content left, notes right anchored to their target line's vertical position, a severity rail per note, each note under forty words. A capturable region — every note is an `annotation` with `itemId` and intent; wins when the base content must stay continuously readable; axes: `anchorMode`, `severityVocab`, `railSide`, `collapseSafe`.
- [STEP_RIBBON] — a ribbon of connected step chips in past | current | next states, connector fill tracking completion, the current step latched with `aria-current="step"`. Distinct from a timeline: ordinal position only, no time axis; axes: `stepVocab`, `orientation` (horizontal default, vertical for long labels), `branchPoints`, `currentIndex`.
- [MATRIX_HEATMAP] — a grid or SVG lattice of cells whose fill intensity rides the heat recipe and ceiling in [styling.md](styling.md), row and column headers, optional cell value. Cell encodings: `intensity` (continuous score), `categorical` (state vocabulary to discrete fill), `bivariate` (fill plus glyph). Wins when both axes are categorical and the crossing value is the whole subject; axes: `rowKey`, `colKey`, `cellEncoding`, `scaleDomain` (locked), `editableCells` (cells writing `changes[]`).
- [TREE_INDENT] — nested `<details>`/`<ul>` with `border-inline-start` guides per level, disclosure triangles on the summary marker, leaf rows carrying their own chips. Wins when containment is the relationship and depth stays near five; axes: `depthMax`, `guideStyle`, `leafContent`, `defaultOpen` (depth cutoff), `collapseGroup` (shared `name`).
- [CHIP_TAXONOMY] — the `.chip` grammar under one closed vocabulary per semantic axis: status, severity, kind, and ownership are distinct axes on distinct token ramps, never a rainbow of ad-hoc colors. A chip is a label, never a control — unless it is a filter facet, which toggles `aria-pressed` and dims the collection; axes: `axisVocab` (closed set), `tokenRamp`, `role` (label | filter-facet | verdict-input), `shape` (pill | square | dot).

## [05]-[INFOGRAPHIC_FAMILY]

Vector figure generators past the chart marks above; each row names the reader question and the sibling it beats, and every construction recipe — polar kernel, ribbon cubic, squarify, isometric projection, micro marks — lives in [svg.md](svg.md). A figure earns its geometry by the question: magnitude comparisons stay linear (meter, waffle, bars), and a radial form is legal only where the bounded scalar, the cycle, or the shared-center comparison is itself the subject.

| [INDEX] | [ELEMENT]        | [READER_QUESTION]                                      | [BEATS]                       |
| :-----: | :--------------- | :----------------------------------------------------- | :---------------------------- |
|  [01]   | arc gauge        | how far along one bounded scalar stands                | bare percentage numeral       |
|  [02]   | concentric rings | how 2-6 independent scalars compare on one scale       | row of separate gauges        |
|  [03]   | radar            | how one option's profile spans a closed criteria set   | per-criterion bar row         |
|  [04]   | sunburst         | how a hierarchy's parts nest and weigh                 | flat treemap past depth two   |
|  [05]   | sankey ribbon    | how quantity flows and splits between stages           | table of stage deltas         |
|  [06]   | dependency arcs  | which ordering constraints span a linear sequence      | full node-edge graph          |
|  [07]   | funnel           | where a monotone pipeline loses volume                 | bar chart per stage           |
|  [08]   | treemap          | how a whole divides by weight at one or two levels     | pie, a long ranked list       |
|  [09]   | icicle           | how a deep hierarchy weighs with legible ancestry      | sunburst past depth three     |
|  [10]   | isometric stack  | how layered infrastructure composes spatially          | flat box diagram, sometimes   |
|  [11]   | hex grid         | how modular capabilities tile and neighbor             | card grid without adjacency   |
|  [12]   | span bars        | when work spans, overlaps, and gates across lanes      | dated task table              |
|  [13]   | tidy tree        | who reports to or contains whom, 3-40 nodes            | indented text past two levels |
|  [14]   | bullet           | how an actual stands against target and bands, per row | gauge per row                 |
|  [15]   | strip plot       | how values spread beyond their center                  | mean with no distribution     |

## [06]-[ANTI_NAIVETY]

Named failure modes; a review flags any survivor as a defect.

- [DECORATIVE_SLIDER] — a slider or knob that mutates a visual property but writes no envelope field and drives no readout; a control that changes neither what returns nor what the reader learns does not ship. The explainer simulator scrub is exempt — its readout is the learning.
- [UNKEYED_DRAG_STATE] — a drag whose result is read from DOM position instead of the model, forking the export from the truth; every drop mutates the model and re-renders, and every draggable carries the stable id its `changes[]` path names.
- [FORCED_ORIENTATION] — one timeline orientation stamped onto the wrong shape: a linear project on a ring, one narrative crushed into lanes, a cycle straightened. Orientation is chosen by the dominant dimension and defensible, never defaulted.
- [BURIED_CONCLUSION] — load-bearing content gated behind a gesture: a verdict reachable only after a scrub, a settled decision collapsed by default, a KPI legible only on hover. Load-bearing content renders at rest; interaction deepens, never gates.
- [CIRCULAR_FOR_LINEAR] — a ring, pie, or donut for data with a start and an end or for cross-group part-to-whole; length compares where angle cannot, so bars, meters, and waffles win for magnitude and proportion.
- [RAINBOW_TAXONOMY] — one item carrying multiple ad-hoc color axes with no closed vocabulary, blurring status, severity, kind, and ownership into an unreadable palette.
- [UNLOCKED_MULTIPLES] — small multiples or matrix cells drawn at per-cell scale, so difference reads as noise.
- [DOM_SOURCED_EXPORT] — a capturing surface whose export reads rendered nodes instead of the frozen-baseline model, so the payload lies against the true edit.
- [PHANTOM_CAPTURE] — a control styled as capture — a steal chip, a verdict pill, a keep mark — contributing to no envelope field, implying judgment returns when it does not; it names its `decisions[]`/`changes[]`/`annotations[]` contribution or reverts to a plain label.
