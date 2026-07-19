# [SVG]

Inline SVG is the artifact's pen: every diagram, infographic, and figure is generated vector geometry the reader inspects, clicks, and downloads — never a raster, never a runtime library. Every figure is a parameterized construction — a generator function over data plus the recipes here — so the same code draws three rings or thirty, and every numeric law carries its degenerate-input behavior.

## [01]-[CANVAS]

- One deliberate `viewBox` per SVG, fixed at authoring — `0 0 960 540` and `0 0 720 320` are the house frames — with `preserveAspectRatio` chosen, never defaulted: `xMidYMid meet` for figures that must stay whole, `slice` for full-bleed stage panels, `none` only where non-uniform stretch is the point — and never over text children, because the stretch shears every glyph with the frame. Geometry rides a 4px grid with major bands on 8px increments, so alignment is arithmetic, never eyeballed.
- Canvas background stays transparent — the host surface shows through, so one figure serves every elevation and both themes without a repaint.
- One polar convention across every circular figure: 0° at 12 o'clock, positive clockwise. All radial math below assumes it.
- A 1px horizontal or vertical stroke in an unscaled frame centers on a `.5` coordinate (`y="88.5"`); filled rects stay on integers. `shape-rendering="crispEdges"` is legal only on axis-aligned gridlines, ticks, and bars — it disables antialiasing, so arcs, diagonals, and curves keep the default precision.
- Linework that survives responsive scaling carries `vector-effect="non-scaling-stroke"`; a dashed edge under it recomputes its dash against on-screen length or drops the effect, and the other `vector-effect` values are not interoperable and never ship.
- Every transformed element declares `transform-box: fill-box` (or `view-box` for stage-anchored pivots) with an explicit `transform-origin` — the implicit origin is the viewport corner, and every rotation without this law pivots wrong. Pan and zoom ride an inner `<g>` transform — a CSS transform on the `<svg>` root scales the rendered raster, not the coordinate system.
- An SVG root inherits `color` from the page ink; marks read `currentColor` or a `var(--token)` presentation value. Presentation attributes carry zero specificity, so attribute values are seeds and artifact CSS owns theme and state — a hard-coded hex inside a themed SVG lies in one theme or the other.
- One parametric scale anchors marks to typography: with label size `s`, standard stroke ≈ `s/12`, node padding `0.75s × 0.45s`, node gap `1.25s`, corner radius `min(8, 0.5s)`, arrowhead length `3.5×stroke + 2`. Derived, never sprinkled constants.
- An SVG inside a card sizes to the content box, never the viewport; a diagram whose canvas tone sits within one elevation step of its host loses its edge — the host steps down or the SVG takes a `--line-strong` frame.
- Draw order is document order: zone bands, then edges, then nodes, then labels — each layer one `<g>` with its layer class, so a whole layer dims, hides, or exports as one node.

## [02]-[PATH_GRAMMAR]

Path data is the construction language; generators emit it from data, and hand-typed `d` survives only for glyph-scale fixed art such as markers and icons.

- Uppercase commands are absolute, lowercase relative: `M` opens a subpath, `L`/`H`/`V` draw lines, `C` draws a cubic with two control points and `S` reflects the previous control, `Q`/`T` are the quadratic pair, `Z` closes back to the subpath start. Generators emit absolute commands; relative deltas earn their place only in hand-authored glyphs where they read clearer.
- `A rx ry rot large-arc sweep x y` draws an ellipse arc between the current point and `x y`: `large-arc=1` selects the ≥180° arc of the pair, `sweep=1` bends clockwise in screen coordinates. Coincident endpoints draw nothing — a full circle is always two arcs.
- Compound subpaths in one `<path>` cut holes under `fill-rule="evenodd"`; the default `nonzero` follows winding direction, so a hole under `nonzero` requires the inner subpath to wind opposite.
- Coordinates round to two decimals at authoring scale; deeper precision only bloats the file.
- `pathLength="1"` normalizes dash and draw-on math to the 0–1 range regardless of geometry — set it on animation paths only, never on measured or textPath paths.
- `d` animates through CSS `d: path("...")` only between command lists of identical shape; a morph across differing command counts snaps instead of tweening.

## [03]-[PAINT]

- Standard edges set `stroke-linejoin: round` with butt caps; round caps mark only gauge arcs and endpoint dots, where the cap is the mark.
- Stroke ladder at figure scale: 1px hairline and grid, 1.5px standard edge, 2px emphasis and container, 2.5px selected; past 3px only width-encoded flow ribbons. Fills stay translucent over opaque strokes — `color-mix(in oklch, <token> 10-22%, transparent)` for region fills — with density carried by stroke weight, never by heavier fill. Connector ink stays under a third of content ink: when edges outweigh nodes and labels, drop edge alpha or weight before touching content.
- One dash vocabulary spans the whole artifact: solid is realized, `4 6` is trace, annotation, or async, `6 6` is planned, `5 4` is containment, and the animated flow edge rides `6 4` with a `stroke-dashoffset` keyframe. A fifth rhythm is a defect.
- Markers live in `<defs>`, one id per edge class; `markerUnits` defaults to `strokeWidth`, so marker geometry scales with its edge. A house barbed head draws a body near 4.8x stroke width with `refX` at the tip; `fill="context-stroke"` inherits each edge's color, with a per-class pre-colored fallback marker for engines without it:

```svg copy-safe
<defs><marker id="arrow" viewBox="0 0 10 10" refX="8.5" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
  <path d="M1 1 L9 5 L1 9 L3.2 5 Z"/>
</marker></defs>
```

- Gradients express depth or focus on at most one hero object per figure — `<linearGradient>` or `<radialGradient>` with `gradientUnits="userSpaceOnUse"` when one light field spans the scene, `objectBoundingBox` when each mark shades locally — and flat fills everywhere else. Stops read tokens through `stop-color="var(--token)"`.
- A diagonal-hatch `<pattern>` (`patternUnits="userSpaceOnUse"`, 8px cell, 1.4px stroke) marks degraded, simulated, or blocked regions — the second channel that keeps state legible in grayscale and print.
- Glow is one `feDropShadow` (`stdDeviation` 1.25–2, `flood-opacity` .2–.35) on the highlighted group alone, never per node; every filter declares an expanded region (`x="-40%" y="-40%" width="180%" height="180%"`) so nothing clips, and sets `color-interpolation-filters="sRGB"` where exact color math matters.
- Repeated glyphs — icons, badges, ports — are one `<symbol>` in `<defs>` stamped by `<use>`, themed through `currentColor` and custom properties set on the `<use>`; selectors never pierce the use-clone shadow tree, so state lands on the `<use>` element itself. Every id carries the artifact slug prefix so two inline SVGs on one page never collide.
- A `<clipPath>` crops geometry hard; a `<mask>` with a white-to-transparent gradient fades it — the edge-fade on an overflowing ribbon or a spotlight vignette is a luminance mask, never a stack of translucent rects. `clipPathUnits` and `maskUnits` default to `userSpaceOnUse` while their content units differ, so a traveling clip declares both. CSS `clip-path: shape(...)` clips in responsive `%`-relative terms where engines carry it — a static `<clipPath>` twin is the fallback.
- Corners: `rx` 4–6 on node rects, 8 on large panels, 10 on standalone figure frames; polyline corners round through the arc-corner recipe below.

## [04]-[SEMANTICS]

Meaning rides two orthogonal class axes — geometry names what a node is, role names what state or rail it carries — one vocabulary across every figure in the artifact.

| [INDEX] | [CLASS]        | [MARK]                                 | [MEANS]                        |
| :-----: | :------------- | :------------------------------------- | :----------------------------- |
|  [01]   | `edge`         | 1.5px solid `--line-strong`            | structural relation, data flow |
|  [02]   | `edge.primary` | 2.5px solid `--accent`                 | the called-out primary path    |
|  [03]   | `edge.ok`      | 2px solid `--ok`                       | success or executed route      |
|  [04]   | `edge.fail`    | 2px dashed `4 6` `--fail`              | failure or rejection route     |
|  [05]   | `edge.ext`     | 1.5px `--info`                         | external or interface crossing |
|  [06]   | `.async`       | dash `4 6` modifier on any edge        | async, fallback, cold          |
|  [07]   | `.planned`     | dash `6 6` modifier on any edge        | not yet realized               |
|  [08]   | `node`         | `--raised` fill, 1.5px `--line-strong` | owner, service, process        |
|  [09]   | `node.gate`    | diamond path                           | decision or readiness gate     |
|  [10]   | `node.store`   | cylinder or tall `rx` rect             | durable store                  |
|  [11]   | `node.ext`     | dashed `6 6`, `--info` stroke          | external system                |
|  [12]   | `node.on`      | 2.5px `--accent` stroke                | selected or active node        |

- Rail hue names the relation's kind; the dash modifier names its modality — async and planned are dashes composed onto a rail, never colors of their own.
- Zones group nodes as 1px dashed-`5 4` rects stroked `--boundary` over `--surface` fills with mono zone labels in `--boundary` ink — half the standing edge weight, the token's brightness carrying what the thinness gives up.
- Status hues mark node state (`--ok` healthy, `--warn` degraded, `--fail` down) reinforced by a text badge and, for filled regions, the hatch channel — hue never carries state alone.
- Node ink follows the fill: a `--raised` node carries `--text`, and a status-tinted fill either holds its label at the text contrast floor or moves the label outside the shape.
- Every edge label takes a backing rect at `rx="4"` filled one elevation step below the canvas — a recessed chip that masks crossing strokes; a backing at canvas tone reads as a hole, and no backing lets lines strike through words.
- [STATE] — a state machine assembles from standing marks: states are `rx="6"` `node` rects, the initial pseudostate a filled `--text` dot at `r ≈ 5`, the final pseudostate a concentric ring — an outer stroked circle around a filled inner dot — and each transition carries its `guard / action` label on the arc-midpoint backing chip.
- A figure splits by zone or phase when edge crossings, label collisions, or node degree defeat one canvas — two legible figures beat one spaghetti map, and calling out a genuinely tangled region beats hiding it.

## [05]-[TEXT]

- Nothing on a canvas renders below 11px: inner node labels mono 11–12px, edge labels mono 11px, outer annotations sans 12px `--text-muted`; values set `font-variant-numeric: tabular-nums`, and an information-bearing label never binds `--text-faint`.
- `<text>` carries geometry-bound labels, ticks, and short values as positioned vector glyphs; paragraphs and wrapping copy ride an HTML overlay positioned over the figure. `<foreignObject>` is legal for in-page rich labels but dies in standalone export — an export-bound figure keeps text as `<text>`.
- Sizing against text: authoring-time boxes size from the longest label at `0.62em × chars + 2×pad` for mono; runtime-precise fitting measures with `getComputedTextLength()` after `document.fonts.ready`. Deterministic no-script fitting binds `textLength` + `lengthAdjust="spacing"` on `<text>` — never on `tspan`, which Firefox ignores. Multi-line labels are explicit `<tspan x dy="1.15em">` rows.
- `getBBox()` is unreliable inside `display:none` and excludes transforms — measure in a `visibility:hidden` staging state, and read a transformed box through `getBoundingClientRect()`.
- Single-line centering is `text-anchor` plus `dominant-baseline="central"`; a column of tick numerals right-aligns through `text-anchor="end"` at one shared x, so magnitudes line up digit-for-digit. Curved text rides `<textPath>` only when the measured text fits the arc with 12% slack (`arcLength ≥ 1.12 × textWidth`) and stays near-upright — reverse the hidden path when the tangent points down so glyphs never invert; `side="right"` is not interoperable. Otherwise a straight callout wins.
- Every label crossing geometry takes a `paint-order: stroke` halo — `stroke` bound to the canvas tone at 4–5px under the fill — one text node, no duplicate shadow text.
- Label placement under pressure runs the anchor ring: try the eight positions around the mark (E, W, N, S, then diagonals) with a 2px inflation, score each candidate by overlap area against placed labels and marks plus leader length, place best-first by priority, and demote the lowest-priority colliders to a legend row rather than shipping overlap. A leader line is straight or one elbow, never a routing system.
- Corridors: 6px mark-to-label, 10–12px leader-end-to-text, 64px of clear margin outside a radial figure for callouts; a radial leader elbows at `r + 12`. Outer canvas padding runs 24–32, figure-to-legend gap 20–28.
- [CALLOUT] — the annotated-figure overlay: each badge is an `--accent` circle at `r ≈ 9` carrying a mono ordinal, its leader runs from the badge rim to the point — straight or one elbow — and captions ride an ordered HTML list beside the figure keyed by ordinal. A dimension line is two 1px witness ticks plus a spanning line whose center gaps for the value; a span bracket is a squared-U path with its label at the mid-outer edge.
- Direct labels beat a legend up to roughly six marks; a legend survives only where marks are too dense to label in place, and it never restates a direct label already on the canvas.
- Labels stay horizontal except tangential ring labels; a rotated axis title reads slower than a horizontal title placed above the axis.

## [06]-[RADIAL]

A figure earns its geometry by the reader question: magnitude and proportion stay linear — meter, waffle, bars — and a radial form is legal only where the bounded scalar, the genuine cycle, or the shared-center comparison is itself the subject. Every circular figure composes the polar kernel below, and degeneracy is law: a zero-width domain returns the neutral point, a span under 0.5° culls the segment, and a full 360° ring splits into two 180° arcs.

```js copy-safe
const P = (cx, cy, r, deg) => {
    const t = ((deg - 90) * Math.PI) / 180;
    return `${cx + r * Math.cos(t)} ${cy + r * Math.sin(t)}`;
};
const norm = (v, lo, hi) => (hi - lo < 1e-9 ? 0 : Math.min(1, Math.max(0, (v - lo) / (hi - lo))));
const arcPath = (cx, cy, r, a0, a1) => {
    const span = (((a1 - a0) % 360) + 360) % 360 || (a1 !== a0 ? 360 : 0);
    if (span < 0.5) return "";
    if (span >= 360) return `${arcPath(cx, cy, r, a0, a0 + 180)} ${arcPath(cx, cy, r, a0 + 180, a0 + 360 - 1e-4).replace("M", "L")}`;
    return `M ${P(cx, cy, r, a0)} A ${r} ${r} 0 ${span > 180 ? 1 : 0} 1 ${P(cx, cy, r, a0 + span)}`;
};
const ringSeg = (cx, cy, ri, ro, a0, a1) => {
    const span = (((a1 - a0) % 360) + 360) % 360;
    if (span < 0.5 || ro <= ri || ri < 0) return "";
    const L = span > 180 ? 1 : 0;
    return `M ${P(cx, cy, ro, a0)} A ${ro} ${ro} 0 ${L} 1 ${P(cx, cy, ro, a1)} L ${P(cx, cy, ri, a1)} A ${ri} ${ri} 0 ${L} 0 ${P(cx, cy, ri, a0)} Z`;
};
```

- [ARC_GAUGE] — a scalar with a known maximum: `p = norm(v, min, max)`, foreground `arcPath` over `a0 + p·(a1 - a0)` at `stroke-width:6; stroke-linecap:round`, background the full span at 16% opacity; the semicircle house span is `[-120, 120]`. That value renders as HTML text over the center — it animates and wraps where SVG text cannot.
- [DONUT_SEGMENTS] — categorical slices as `ringSeg` per category with a 2° pad; band width `ro - ri` runs 12–20 at figure scale, 6–8 at micro; a rounded segment corner never exceeds `(ro - ri)/2`, and a padded ring keeps `ri ≥ ro × padAngle / sin(θ)` so inner edges never collapse. Magnitude and cross-group part-to-whole stay linear — a meter or waffle — because length compares where angle cannot.
- [SUNBURST] — depth owns radius (`ri = r0 + depth × (band + gap)`, `ro = ri + band`); sibling spans divide the parent's span by cumulative value: `a0ᵢ = parent.a0 + parent.span × cumBeforeᵢ / parent.sum`.
- [RADAR] — n axes at `aᵢ = i × 360 / n`, each value normalized per axis through `norm`, vertex `P(cx, cy, R × ρᵢ, aᵢ)`, closed polygon filled at 18% with a 1.5px stroke; grid rings at 25/50/75/100% in `--line`. Three overlaid shapes maximum, each on its own series token.
- [CONCENTRIC_RINGS] — 2–6 independent scalars on one scale: `rᵢ = r0 + i × (stroke + gap)` with `gap ≥ 0.75 × stroke`, each ring an arc gauge; labels sit outside the largest radius, never between rings.
- [CIRCULAR_TIMELINE] — legal only for a genuinely cyclic domain where wrap-around adjacency is load-bearing; a monotone progression on a ring destroys the duration comparison a bar row gives free. Time maps to angle `a = a0 + (t - t0) / period × 360`, events as radial ticks, spans as `ringSeg`, the now-needle a 2px `--accent` line from center.
- [NEEDLE] — direction over magnitude: tip at `c + u × len`, tail at `c - u × tailLen`, base corners at `c ± n × w` where `u = (cos θ, sin θ)` and `n = (-sin θ, cos θ)`; one closed path, filled.

## [07]-[FLOW]

- [ARC_CORNER] — the exact rounded corner for any polyline: at vertex `B` with neighbors `A`, `C`, take unit vectors `u = unit(A−B)`, `v = unit(C−B)`, `θ = acos(u·v)`, tangent distance `d = min(r/tan(θ/2), 0.45·|AB|, 0.45·|BC|)`, actual radius `ra = d·tan(θ/2)`; emit `L (B + u·d)` then `A ra ra 0 0 sweep (B + v·d)` with `sweep = cross(u,v) < 0 ? 1 : 0`. Radius cap 8.
- [ORTHOGONAL_ROUTE] — architecture edges route Manhattan through a mid-lane snapped to the 8px grid: `m = round₈((x0 + x1) / 2)`, points `(x0,y0) (m,y0) (m,y1) (x1,y1)`; a segment crossing an obstacle inflated by 8 detours at `top - 16` or `bottom + 16`, whichever leg is shorter, and route cost ranks `length + 18·turns + 80·crossings`.
- [PORTS] — port sides assign by the dominant component of the center-to-center vector, and edges sharing a side sort by target coordinate into slots `(i - (m-1)/2) × slotGap` — an edge never enters a box at an arbitrary point, and every arrowhead points into the target face. An architecture diagram composes zone bands, then ported nodes, then orthogonal routes — the full assembly.
- [LAYERED_DAG] — pipelines and ownership chains lay out in two passes: layer by longest path from sources, then order each layer by the barycenter of neighbor indices, two alternating sweeps. House spacing: 50px between ranks, 50px between nodes, 20px between parallel edges, compressed to 20/20/10 for dense strata. Cross-layer edges route orthogonally; a cycle renders in `--fail`, never silently broken.
- [SEQUENCE] — time flows top-down, vertical order is model order: participant heads are top `node` rects at `xᵢ = left + i × laneGap`, lifelines 1px dashed `--line` verticals from each head, activations narrow `--raised` rects (`width ≈ 10`, `rx="2"`) centered on the lifeline over the active window. Sync messages are solid `edge` horizontals with the barbed head, returns dashed `4 6` open-headed, async the `.async` modifier; a self-message loops off the lifeline's right side as a rectangular jog.
- [FRAGMENT] — a combined `alt`/`opt`/`loop` block over a sequence: a labeled `5 4` containment rect spanning the participating lifelines, a mono tab label at its top-left, and a dashed divider per compartment.
- [SANKEY_RIBBON] — 3–12 flows: node bars 24px wide with 8px padding, slots assigned cumulatively (`slotY = node.y0 + Σ priorWidths + w/2`), outgoing links sorted by target y and incoming by source y, up to 6 relaxation sweeps of barycenter reordering when crossings fight value-tracking. Ribbon totals conserve: a node's in-width equals its out-width or the gap renders as an explicit loss stub. Each ribbon is two horizontal-tangent cubics closed into one path:

```js copy-safe
const ribbon = (x0, y0, w0, x1, y1, w1) => {
    const dx = (x1 - x0) * 0.5;
    return `M ${x0} ${y0 - w0 / 2} C ${x0 + dx} ${y0 - w0 / 2} ${x1 - dx} ${y1 - w1 / 2} ${x1} ${y1 - w1 / 2}
          L ${x1} ${y1 + w1 / 2} C ${x1 - dx} ${y1 + w1 / 2} ${x0 + dx} ${y0 + w0 / 2} ${x0} ${y0 + w0 / 2} Z`;
};
```

- [DEPENDENCY_ARCS] — ordering constraints over one baseline of nodes at `xᵢ = x0 + i × step`: edge `i→j` is `M xᵢ base A rx ry 0 0 1 xⱼ base` with `rx = |xⱼ - xᵢ| / 2`, `ry = clamp(|xⱼ - xᵢ| × 0.32, 20, 96)`; long arcs draw first at lower opacity, short arcs above. A backward constraint renders in `--fail` — the defect that convicts the sequence.
- [MULTI_EDGE] — parallel edges between one pair fan by perpendicular offset `(i - (k-1)/2) × gap`, `gap = max(6, 0.45 × fontSize)`, each a quadratic through its offset midpoint; a self-loop departs and returns at ±35° around its anchor angle with cubic controls at ±80°, loop radius `max(18, 1.4 × nodeR)`, drawn on the node's least-crowded side.
- [SMOOTH_LINE] — a data line never overshoots: monotone (Fritsch–Carlson) interpolation for scalar series, Catmull-Rom (centripetal when point spacing is uneven) only for organic routes; the default remains the straight polyline — curvature is a semantic mode, not a garnish.
- [FUNNEL] — monotone stage attrition: width tracks the survivor share `wᵢ = wMax × vᵢ / v0`, each stage a symmetric trapezoid; the drop between stages labels the edge, not the fill.
- [SLOPE] — two states, one line per item: `M x0 y0 C x0+dx·.5 y0, x1-dx·.5 y1, x1 y1`, slope sign to `--ok`/`--fail`, labels at both endpoints only. Rank change uses rank rows (`y = top + (rank - 1) × rowGap`) — the bump variant.

## [08]-[STRUCTURAL]

- [TREEMAP] — small ordered sets slice-dice (alternate the split axis by depth); unordered sets squarify: sort descending, grow the current row while it improves `worst(row, shortSide) = max(shortSide²·max(row) / (Σrow)², (Σrow)² / (shortSide²·min(row)))`, lay each accepted row across the longer side. Padding defaults to 0 and becomes a signal only when depth must read as containment; areas round by largest remainder so cells sum exactly; cell labels obey the 11px floor or drop to a legend.
- [ICICLE] — hierarchy with legible ancestry: a child's span divides the parent's by value, `y = top + depth × bandH`; the flame variant grows upward.
- [DIMETRIC_STACK] — layered systems in the 2:1 pixel projection: `sx = ox + (x - y) × tileW/2`, `sy = oy + (x + y) × tileH/2 - z × zH` with `tileW = 2 × tileH`; a block is three faces — top at +8% lightness via `color-mix`, left at base, right at −8% — drawn back-to-front so nearer blocks occlude. An extruded stack is the cheap flat sibling: depth offset `(14, -10)` on each panel's top and right faces, five layers maximum.
- [HEX_GRID] — modular capability cells. Pointy-top axial: `px = cx + s√3 × (q + r/2)`, `py = cy + 1.5s × r`, corner k at `30 + 60k`°. Flat-top axial: `px = cx + 1.5s × q`, `py = cy + s√3 × (r + q/2)`, corner k at `60k`°.
- [WAFFLE] — countable units in a 10-column lattice, cell counts from largest-remainder rounding: `x = left + (i % 10) × cell`, `y = top + ⌊i / 10⌋ × cell`, dot radius `0.28 × cell`; filled dots are units, outlined dots remaining capacity, category fill by `--series-*`.
- [SPAN_BARS] — schedules and epochs on a linear time scale `x(t) = left + (t - t0) / (t1 - t0) × W`: spans as `rx="4"` rects of `width = max(1, x(end) - x(start))`, instants as ticks, epoch bands behind everything at 8–14% opacity, dependencies routed Manhattan with the arrow marker; the today line spans every lane, and the critical chain draws at emphasis weight with slack rendered as a lighter buffer extension.
- [TIDY_TREE] — 3–40 node hierarchies: leaves take sequential `x = leafIndex × leafGap`, each parent centers on `mean(children.x)`, `y = depth × levelGap`; after centering, scan each depth for sibling-subtree overlap and shift the right subtree (with its descendants) by the deficit. Sibling gap 1 unit, cousin gap 2. Edges are vertical-tangent cubics `M parentBottom C px midY, cx midY, childTop`.
- [BLOB_HULL] — a cluster boundary is the convex hull of its members, each vertex pushed out from the centroid by `pad` (`0.65 × fontSize` for text groups, `1.25 × nodeR` for node clusters), corners rounded by [ARC_CORNER]; the zone label sits at the hull's most interior point, never the centroid of a concave shape.

## [09]-[SCALES_AND_MICRO]

Every axis and micro mark declares its domain law: ticks land on the 1–2–5–10 sequence (`step = nice((max - min) / (target - 1))`, target 5 for small charts), a length- or area-encoding mark includes zero in its domain, a position-only line may crop with the truncation named, domains pad 5% except against a zero baseline, and a degenerate domain (`min === max`, `n < 2`) renders the neutral form instead of NaN geometry. Sibling micro marks lock one shared domain — a per-cell scale turns difference into noise.

- [SPARKLINE] — ~120×24: `xᵢ = left + i/(n-1) × W`, `yᵢ = top + (1 - norm(vᵢ, min, max)) × H`, 1.25px stroke, endpoint dot only; the area variant closes to the baseline at 18% fill; win-loss draws signed bars off a hairline midline at `±0.42 × H`.
- [BULLET] — actual versus target in one row: qualitative range rects behind, the measure a centered bar at `0.42 × rowH`, the target a vertical 2px line at `x(target)`.
- [DELTA] — a signed arrow beside a numeral: shaft `clamp(|Δnorm| × 18, 8, 18)` at ±45°, triangle head at the tip, neutral a 10px horizontal rule; color by sign through `--ok`/`--fail`.
- [HEAT_STRIP] — temporal intensity as fixed-hue cells whose opacity rides `0.12 + 0.78 × norm(v)`; hue changes are reserved for semantic state, never magnitude.
- [DIAL] — the arc gauge at micro scale over `[-120, 120]`, background arc at 16% opacity, value as adjacent HTML text.
- [STRIP_PLOT] — spread beyond a center: value to x, deterministic hash jitter `y = mid + ((hash(id) % 100)/100 - 0.5) × jitterH` — never `Math.random`, since diffs must reproduce; the beeswarm variant resolves collisions by trying y offsets `0, ±r, ±2r…` against prior points within `2r + 1` horizontally; the box-lite overlay is a min–max whisker, an IQR rect, and a 2px median line.

## [10]-[CHARTS]

A quantitative figure is hand-authored from the same kernels as every diagram — scales, ticks, and axes are generated geometry, never a runtime charting library. Chart-form selection and palette law ride the `dataviz` skill; this section owns the SVG realization once the form is chosen, and the domain law above binds every scale it builds.

```js copy-safe
const linear = (d0, d1, r0, r1) => (v) => r0 + (d1 - d0 < 1e-9 ? 0.5 : (v - d0) / (d1 - d0)) * (r1 - r0);
const band = (n, r0, r1, padIn = 0.15, padOut = 0.1) => {
    const step = (r1 - r0) / Math.max(1e-9, n - padIn + 2 * padOut);
    return { x: (i) => r0 + step * (padOut + i), w: step * (1 - padIn), step };
};
const ticks = (lo, hi, target = 5) => {
    if (hi - lo < 1e-9) return [lo];
    const raw = (hi - lo) / Math.max(1, target - 1);
    const mag = 10 ** Math.floor(Math.log10(raw));
    const step = [1, 2, 5, 10].map((s) => s * mag).find((s) => s >= raw);
    const t0 = Math.ceil(lo / step) * step;
    return Array.from({ length: Math.floor((hi - t0) / step) + 1 }, (_, i) => +(t0 + i * step).toFixed(10));
};
```

- [FRAME] — the plot rect insets from the canvas by measured label budgets, never guessed margins: left is the widest formatted y label plus 8, bottom 30, top 14 of headroom so the topmost tick label never clips, right 8 or the direct-label gutter when series label at line end. A time domain rides `linear` over UTC milliseconds with ticks landed on calendar boundaries — day, week, month, quarter — never on raw 1–2–5 steps.
- [AXES] — layer order is gridlines, marks, then axis furniture: gridlines run the plot width at every y tick in 1px `--line`, the zero baseline steps to `--line-strong`, and vertical gridlines ship only under dense scatter. Tick stubs are 4px outside the plot edge; y labels right-align at one shared x so magnitudes align digit-for-digit, x labels center under their ticks — all mono 11px `tabular-nums` through one `Intl.NumberFormat` per axis, the unit stated once in the axis title.
- [TITLES] — axis titles are horizontal sans 12px `--text-muted`: the y title sits above the axis at the plot's top-left, the x title below the label row. Nothing on a chart rotates: a crowded x axis thins to every nth tick, shortens its format, or the chart flips to horizontal bars.
- [BARS] — categorical bars ride the band scale and grow from the zero baseline, one `--series-*` fill at full opacity with no stroke, `rx` ≤ 2; value labels sit just past the bar end in mono 11px, inside only when the bar holds the label plus padding at the contrast floor. Long category names flip the chart horizontal; grouped bars cap at four series before small multiples, and a stack is legal only when the total is the subject, splitting at zero when it diverges.
- [LINES] — a series line is 2px on its `--series-*` token, straight or monotone per [SMOOTH_LINE]; up to five series label directly at the line's right end under the anchor ring, and past that the chart splits into small multiples before it grows a legend. A missing point breaks the line — a visible gap or a dashed `4 6` bridge, never a silent interpolation — and the area variant fills to the zero baseline at 18%, single-series or stacked only.
- [SCATTER] — dots at `r` 3–4 filled at 75% opacity so overplot reads as density; a highlighted point takes full opacity and a 2px ring; a trend, threshold, or cluster claim enters as an explicit annotated mark, never left for the reader to infer.
- [MULTIPLES] — sibling panels lock one shared domain per the shared-domain law, tile at equal size with a mono panel title at each top-left, and render axis labels on the bottom rank and left file alone.
- [ANNOTATION] — the chart states its takeaway on the canvas: one callout or labeled reference line naming the claim the figure argues. A target, threshold, or event line is a first-class mark — dashed `4 6` with its label on a backing chip — and never a caption-only fact.
- [TABLE_TWIN] — a data chart pairs with its data as a table, visible beside dense evidence or `.sr-only` otherwise, and the SVG `<desc>` states the takeaway: the chart argues, the table is the record.

## [11]-[INTERACTION_AND_A11Y]

Detail lives outboard, never crammed into boxes; animation exists to show flow, and `prefers-reduced-motion` stills it while preserving the state it showed.

- A meaning-bearing SVG names itself: `role="img"` with `<title>` + `<desc>` wired through `aria-labelledby` for atomic figures; `role="graphics-document"` only when sub-elements are genuinely navigable. A decorative SVG takes `aria-hidden="true"` and no tabindex. Long interpretation rides adjacent HTML through `aria-describedby`, never `<desc>` alone — and `<desc>` states the figure's takeaway, never its construction.
- Every interactive region is focusable with a name — `<g data-k tabindex="0" role="button" aria-label="...">` with Enter and Space sharing the click path — and in-page navigation is a native SVG `<a href="#...">`, not a click handler.
- A thin stroke gets invisible hit geometry: a transparent twin path at ≥24px effective width carries the pointer while the visible path stays precise.
- Connected highlighting is data plus CSS — nodes carry `data-k`, dependent marks carry a space-separated `data-rel` roster, `:has()` on the figure root lights the neighborhood with zero script — and the same states bind to a `data-selected` stamp so touch and keyboard reach what hover shows:

```css copy-safe
.diagram:has([data-k="api"]:hover) [data-rel~="api"],
.diagram[data-selected="api"] [data-rel~="api"] {
    opacity: 1;
    stroke-width: 2.25;
}
.diagram:has([data-k="api"]:hover) [data-rel]:not([data-rel~="api"]),
.diagram[data-selected="api"] [data-rel]:not([data-rel~="api"]) {
    opacity: 0.22;
    transition: opacity var(--dur-2) var(--ease-standard);
}
```

- A multi-behavior system draws one stable topology and overlays named flows — never one diagram per behavior. A `FLOWS` map owns each flow's edge ids, node ids, and ordered captions; selecting a flow chip dims everything, lights the members, animates the lit edges by dash offset, and walks the captions in a floating card:

```js copy-safe
const FLOWS = { publish: { edges: ["e1", "e3"], nodes: ["api", "queue"], steps: ["Client submits", "Queue fans out"] } };
const setFlow = (key) => {
    const flow = FLOWS[key];
    document.querySelectorAll(".diagram .lit").forEach((el) => el.classList.remove("lit"));
    document.querySelectorAll(".diagram [id]").forEach((el) => el.classList.toggle("dim", Boolean(flow)));
    (flow?.edges ?? []).concat(flow?.nodes ?? []).forEach((id) => document.getElementById(id)?.classList.remove("dim"));
    (flow?.edges ?? []).forEach((id) => document.getElementById(id)?.classList.add("lit"));
};
```

- Selection is one dataset stamp the CSS graph reads — geometry never recomputes for state; the detail panel repaints from a keyed record map on the same stamp, and arrow keys move the stamp through the node order so the keyboard reaches everything hover shows.
- Animation routes: CSS owns transform, opacity, dash, and `@property`-typed custom properties — one registered number drives stroke, glow, and emphasis together; draw-in normalizes with `pathLength="1"`; SMIL `<animate>` is legal for attribute animation CSS cannot portably reach (a `d` morph with matching command lists, an animated mask wipe, gradient stops), with `fill="freeze"` holding the end state. Animate a parent group or one variable, never hundreds of children.
- A token riding an edge travels by `offset-path: path(...)` with `offset-distance` animated `0%` to `100%` and `offset-rotate` tracking the tangent — the CSS-only flow mark beside dash offset; its travel time binds the duration tokens, so `prefers-reduced-motion` stills it with the page.

## [12]-[EXPORT]

A figure sheet delivers standalone illustrations — doc headers, README figures — each exportable alone, its download filename derived from the figure's `<title>` slug so sibling figures export distinct names. A standalone frame is `viewBox="0 0 720 320"`, rects at `rx="10"`, strokes 1.5px neutral and 2px emphasis, flat fills only. Export is a pipeline, never a bare serialize: the clone carries `xmlns`, explicit `width`/`height`, `<title>`/`<desc>`, every `var(--token)` resolved to its literal, ids rewritten with the figure slug, interactive-only state stripped, and its own `<style>` in `<defs>` — page CSS does not travel, and a `<foreignObject>` label dies outside the page.

```js copy-safe
const exportSvg = (svg, filename) => {
    const clone = svg.cloneNode(true);
    clone.setAttribute("xmlns", "http://www.w3.org/2000/svg");
    const box = svg.viewBox.baseVal;
    clone.setAttribute("width", box.width);
    clone.setAttribute("height", box.height);
    clone.querySelectorAll("[data-selected],.dim,.lit").forEach((n) => {
        n.classList.remove("dim", "lit");
        delete n.dataset.selected;
    });
    const styles = getComputedStyle(svg);
    clone.querySelectorAll("[fill^='var('],[stroke^='var(']").forEach((n) => {
        for (const attr of ["fill", "stroke"]) {
            const raw = n.getAttribute(attr);
            if (raw?.startsWith("var(")) n.setAttribute(attr, styles.getPropertyValue(raw.slice(4, -1).split(",")[0].trim()).trim() || raw);
        }
    });
    const url = URL.createObjectURL(new Blob([new XMLSerializer().serializeToString(clone)], { type: "image/svg+xml;charset=utf-8" }));
    Object.assign(document.createElement("a"), { href: url, download: filename }).click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
};
```
