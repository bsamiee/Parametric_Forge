# [STYLING]

The stylesheet is an architecture: layers order the cascade, the NOCTURNE floor carries every token, containers size components, selectors carry state. Every rule lands in one layer and reads the design-system tokens; nothing re-declares a palette, a scale, or a state variant the floor already owns.

## [01]-[ARCHITECTURE]

The stamped `NOCTURNE_BASELINE` region declares the layer order — `reset, tokens, base, components, utilities, print, overrides` — and populates the early layers; the template-local sheet appends into the same named layers after the region's end marker, where same-name layers merge and later source order wins ties.

```css copy-safe
/* template-local sheet; appends into the floor's named layers — the floor owns the order */
@layer tokens {
  :root { --lane: minmax(14rem, 18rem); --gap: var(--s4); }
}
@layer components {
  .swimlane { display: grid; gap: var(--gap); background: var(--raised); border: 1px solid var(--line) }
}
@layer utilities { .flow > * + * { margin-block-start: var(--gap) } }
@layer overrides { [data-density="compact"] { --gap: var(--s2) } }
```

- [FLOOR_OWNS_ORDER]: the floor's `@layer` statement fixes the order once; a template never re-declares it, and a floor component is overridden inside its own layer by later source order or from a later layer — nothing is authored unlayered, since one unlayered rule outranks every layer and re-opens the specificity war the architecture closed.
- [TOKENS_LOCAL_ONLY]: the template tokens layer seeds only template-local structure values — lane widths, gaps, counts; palette, type scale, motion, and state variants live in the floor and never repeat here.
- [IMPORTANT_INVERTS]: an `!important` declaration flips layer precedence — the earliest layer wins; it rides the overrides layer for forced-state resets alone.
- [REVERT_LAYER]: `revert-layer` rolls a property back to the value from earlier layers, the within-stack escape hatch, distinct from `revert` which drops to the floor.
- [PRECEDENCE]: resolution runs origin, importance, layer, specificity, then source proximity — layer ranks above specificity for normal declarations.

## [02]-[CONTAINERS]

The artifact class fixes the content column; `--measure` is overridden once in the template tokens layer and every centered shell reads it.

| [INDEX] | [ARTIFACT_CLASS]                        | [MEASURE]         | [COLLAPSE]                          |
| :-----: | :-------------------------------------- | :---------------- | :---------------------------------- |
|  [01]   | reading — explainer, buy-in, quiz       | `760px`–`900px`   | single column throughout            |
|  [02]   | operational — plan, report, diff-review | `1040px`–`1120px` | sidebar folds under `56rem`         |
|  [03]   | board — editor, dashboard, wargame      | `1180px`–`1280px` | four columns to two under `64rem`   |
|  [04]   | stage — architecture, atlas, prototype  | full viewport     | stage scrolls inside itself         |
|  [05]   | deck                                    | per-slide `100vw` | inner content holds a reading width |

- [ONE_MEASURE]: one `--measure` per artifact; a page mixing widths per section reads as three documents stapled together.
- [CLASS_BY_SPINE]: the type lists are representative, not closed — a composed type adopts the class of the region spine it composes from, so a new artifact type lands as membership in an existing class, never a sixth width band.
- [PAGE_PAD]: the shell pads `var(--s6) var(--s4) var(--s8)` — generous bottom padding so the last section never kisses the viewport edge; a deck and a stage pad per-region instead.
- [COLLAPSE_BANDS]: breakpoints live at the container, not the viewport, wherever a container ancestor exists; the bands above are the only sanctioned widths, so two templates never fold at arbitrary neighboring values.

## [03]-[GRID_RECIPES]

Grid owns page shells and two-dimensional rhythm, subgrid aligns nested internals, and flex packs one axis — every interior gap rides `gap`, never a margin.

| [INDEX] | [RECIPE]       | [TRACKS]                                            | [FOLDS_TO]                |
| :-----: | :------------- | :-------------------------------------------------- | :------------------------ |
|  [01]   | alternatives   | `repeat(3, minmax(0,1fr))`                          | one column under `56rem`  |
|  [02]   | stat band      | `repeat(4, minmax(0,1fr))`                          | two columns under `48rem` |
|  [03]   | main + sidebar | `minmax(0,1fr) minmax(15rem,18rem)`                 | one column under `56rem`  |
|  [04]   | board          | `repeat(4, minmax(0,1fr))`                          | two columns under `64rem` |
|  [05]   | nav + main     | `minmax(11rem,13rem) minmax(0,1fr)`                 | nav hides under `48rem`   |
|  [06]   | collection     | `repeat(auto-fit, minmax(min(100%,18rem),1fr))`     | intrinsic, no query       |
|  [07]   | split pane     | `repeat(2, minmax(0,1fr))` with a shared header row | stacked under `48rem`     |

```css copy-safe
@layer components {
  .shell {
    display: grid;
    grid-template-areas: "mast mast" "side main" "side foot";
    grid-template-columns: minmax(14rem, 18rem) minmax(0, 1fr);
    grid-template-rows: auto 1fr auto;
    min-block-size: 100vb; gap: var(--s4);
  }
  .shell__main { grid-area: main; min-inline-size: 0 }
  .deck-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 18rem), 1fr)); gap: var(--s4) }
  .deck-grid > .card { display: grid; grid-template-rows: subgrid; grid-row: span 3; gap: var(--s2) }
  .field-grid { display: grid; grid-template-columns: max-content minmax(0, 1fr); gap: var(--s2) var(--s4) }
}
@container shell (inline-size < 52rem) {
  .shell { grid-template-areas: "mast" "main" "side" "foot"; grid-template-columns: minmax(0, 1fr) }
}
```

- [AREAS]: `grid-template-areas` names a shell's regions as ASCII, and a container query rewrites the map to reflow the whole page at one edit.
- [SUBGRID]: a card adopting `grid-template-rows: subgrid` aligns its header, body, and footer to sibling cards across the parent tracks; a label/field grid adopts column subgrid the same way.
- [AUTO_FIT]: `repeat(auto-fit, minmax(min(100%, <floor>), 1fr))` wraps a collection with no query and never overflows a narrow container; `auto-fill` holds empty tracks where `auto-fit` collapses them.
- [MIN_ZERO]: a `1fr` track carries a min-content floor and overflows long content; `minmax(0, 1fr)` on the track and `min-inline-size: 0` on the child release the floor.
- [GAP_NOT_MARGIN]: interior rhythm rides `gap`; a child margin inside a grid or flex stack double-counts against the gap and breaks alignment.
- [ALIGN_SELF]: mixed-height rows resolve per item through `align-self`; the row default `stretch` fills the track until an item opts to `start`.

## [04]-[STICKY]

Sticky elements keep orientation and controls in reach; each recipe owns one concern and never stacks on another.

- [TOOLBAR]: editor and board controls ride `position: sticky; top: 0` on `--raised-2` with a bottom `--line-strong` hairline and a `backdrop-filter: blur(8px)` over a translucent fill; the export bar is its bottom mirror.
- [TOC]: the floor's `.toc` sticks at `top: var(--s4)` with `align-self: start`; the `IntersectionObserver` in the script stamps `.on` per visible section — behavior law is [interaction.md](interaction.md).
- [DETAIL_RAIL]: a glossary, annotation, or node-detail panel sticks the same way beside a main column; on fold it moves below the content, never off the page.
- [COLUMN_HEAD]: a board column header sticks within its own scroll container so counts stay visible while cards scroll.
- [ONE_AXIS]: a sticky element pins one axis; a panel sticky on both axes is a fixed element wearing the wrong position and steals scroll room on short viewports.

## [05]-[DEVICES]

The structural devices are the page's visual vocabulary; every template composes from this set, so four artifacts read as one system.

| [INDEX] | [DEVICE]         | [COMPOSITION]                                                                            |
| :-----: | :--------------- | :--------------------------------------------------------------------------------------- |
|  [01]   | header triad     | `.eyebrow` kicker, display `h1`, `.deck` line — every page opens with all three          |
|  [02]   | section numerals | `.section` counter on `h2::before` — copper mono `01 02 03` where order is meaningful    |
|  [03]   | prompt block     | the originating request in a `--surface` panel led by a mono `PROMPT` label              |
|  [04]   | stat chip        | `.stat` serif numeral, mono caption, `.delta.up`/`.delta.down` trend pill                |
|  [05]   | meter            | `.meter` violet gradient fill; `.meter.seg` stacks status segments for pass/fail/skip    |
|  [06]   | keyline rail     | `.rail` callout — copper for editorial asides, status hue for verdicts and risk          |
|  [07]   | heatmap cell     | fill intensity from the score — the recipe below                                         |
|  [08]   | timeline spine   | a vertical or horizontal rail of dot nodes; dot hue carries state, edges carry order     |
|  [09]   | split pane       | before/after panels sharing one header row and one scroll shell                          |
|  [10]   | sidenote         | margin annotation floated into the gutter, folding to block flow when the column narrows |

```css copy-safe
@layer components {
  .heat { background: color-mix(in oklch, var(--surface), var(--accent) calc(var(--score) / var(--max) * 60%)) }
  .timeline { display: grid; grid-template-columns: max-content 1fr; gap: var(--s2) var(--s4) }
  .timeline .dot { inline-size: 10px; block-size: 10px; border-radius: 50%; background: var(--text-faint); margin-block-start: .45em }
  .timeline .dot.done { background: var(--ok) } .timeline .dot.active { background: var(--accent) } .timeline .dot.blocked { background: var(--fail) }
  .timeline .lane { border-inline-start: 2px solid var(--line); padding-inline-start: var(--s4); padding-block-end: var(--s4) }
  .sidenote { float: right; clear: right; inline-size: 38%; margin-inline-end: -42%; font-size: var(--fs-xs); color: var(--text-muted) }
}
```

- [DEPTH_BY_TONE]: the elevation ladder carries depth — a card is visibly lighter than the page and a popover lighter than a card; a hairline accompanies tone and never substitutes for it.
- [GAP_SEPARATES]: card-to-card separation is carried by the `--s4` gap, and a same-elevation abutment steps its border to `--line-strong` — the elevation-nesting law is design-system [07].
- [NO_OPACITY_DIM]: a de-emphasized row keeps legible text — `--text-faint` labels, a `--fail` rail, or a strike on the leading cell; whole-row `opacity` drops content below contrast and is banned.
- [WINNER_MARKED]: in any scored surface the winning row carries an `--ok` rail and the disqualified row a `--fail` rail with its reason inline — verdicts are structural, never a tint rumor.
- [HEAT_CEILING]: heat intensity tops at 60% toward `--accent` so cell text holds 4.5:1 at full score; the winner still signals through its rail, never fill alone.
- [ACCENT_FIELD]: the filled violet field the design-system accent budget demands lands as the primary action, the active tab, or the meter; copper never fills a control.
- [DASH_RHYTHM]: one dashed vocabulary across HTML borders, SVG strokes, and mermaid fences — `4 6` reads as annotation, trace, or async, `6 6` as planned or not-yet, `5 4` as containment boundary, solid as realized; a fourth rhythm is a defect. A `stroke-dasharray` equal to its path length driving a draw-on `stroke-dashoffset` animation renders solid and sits outside the vocabulary, as does the animated `6 4` flow-edge dash in [svg.md](svg.md).
- [MARKER_SCALE]: markers size by role — micro status dot 8px, small marker 10px, node and timeline dot 16px with a 2px border; a hollow marker over tinted fill binds `--text-muted` with a 1px `--bg` outline so it reads at any intensity.
- [HAIRLINE_ORDER]: hairline dividers and card top-highlights ride 1px `--line`; structural dividers and same-elevation borders ride 1px `--line-strong`; chart gridlines ride `--line` with the zero baseline stepped to `--line-strong` — a hairline never outweighs the structural line beside it.

## [06]-[STATE_SYSTEM]

Containers, `:has()`, and registered custom properties form one state machine: data flows down through properties, state flows up through `:has()`, size flows sideways through container queries.

```css copy-safe
@property --tone { syntax: "<percentage>"; inherits: true; initial-value: 0% }
@property --raise { syntax: "<number>"; inherits: true; initial-value: 0 }
@layer components {
  .panel {
    container: panel / inline-size;
    display: grid; gap: var(--s4); padding: var(--s5);
    background: color-mix(in oklch, var(--raised), var(--accent) var(--tone));
    box-shadow: 0 calc(var(--raise) * var(--s1)) calc(var(--raise) * var(--s4)) oklch(0 0 0 / .28);
    transition: --tone var(--dur-2) var(--ease-standard), --raise var(--dur-2) var(--ease-standard);
  }
  .panel:has(:is(input, textarea, select):focus-visible) { --tone: 10%; --raise: 1 }
  .panel:has([aria-invalid="true"]) { --tone: 14%; border-color: var(--fail) }
  @container panel (inline-size >= 42rem) {
    .panel__body { display: grid; grid-template-columns: minmax(12rem, .8fr) minmax(0, 1.2fr); gap: var(--s4) }
  }
  .panel[data-density="compact"] .panel__body { gap: var(--s2) }              /* load-bearing branch */
  @container panel style(--density: compact) { .panel__body { gap: var(--s2) } } /* refinement */
}
```

- [DATA_DOWN]: a parent seeds `--tone`, `--raise`, and `--density`, and the whole subtree reads them; one property carries a value every descendant consumes.
- [STATE_UP]: `:has()` reads a descendant condition and rewrites the owner's properties, so focus, invalid, and expanded states flow upward with no class toggle.
- [TYPED_PROPERTY]: `@property` with a declared `syntax` makes a custom property animatable and type-checked; an untyped property is a string and never interpolates.
- [CONTAINER_SELF]: a size container never styles itself from its own query; the query targets descendants, so a queried component wraps in a container element carrying `container-type`.
- [SIZE_AXIS]: `container-type: size` detaches block size from content and collapses a height-auto container; `inline-size` sizes on the inline axis alone.
- [HAS_SCOPE]: `:has()` binds to a stable named container, never the document root; a body-wide `:has()` reevaluates the whole tree on every mutation.
- [STYLE_FALLBACK]: a `style()` container query rides only beside an attribute-selector branch carrying the same rule; the selector is load-bearing and the style query refines it.

## [07]-[SELECTORS]

`:where()` carries reach at zero weight, `:is()` carries branching at its heaviest arm, and nesting with `@scope` bounds reach — selector weight is engineered, never accidental.

```css copy-safe
@layer base {
  :where(article, aside, section) :where(h1, h2, h3, p, ul, ol) { max-inline-size: var(--measure) }
}
@layer components {
  @scope (.metric) to (.metric .metric) {
    :scope { display: grid; gap: var(--s2); padding: var(--s4); background: var(--raised) }
    :where(h3, p) { margin: 0 }
    &:has(> [data-trend="down"]) { --edge: var(--fail) }
  }
}
```

- [WHERE_ZEROES]: `:where()` contributes zero specificity, so a wrapped reset or reach selector never outranks a later component rule.
- [IS_MAXES]: `:is()` takes the specificity of its heaviest argument, so an ID inside `:is()` raises the whole selector to ID weight.
- [NESTING]: `&` resolves to the enclosing selector; a nested rule keeps its layer and takes the parent's heaviest branch as its specificity.
- [SCOPE_DONUT]: `@scope (root) to (limit)` styles the donut between root and limit — a component's own tree without its nested instances; scope proximity resolves ties only after layer and specificity settle.
- [ID_POISON]: an ID inside `:is()`, `:has()`, or `:not()` raises the entire selector to ID weight; IDs stay out of every functional-pseudo argument.
- [NEST_CEILING]: two nesting levels is the ceiling for one component; a descendant chain past the component boundary is a coupling the sheet cannot hold true.

## [08]-[COLOR]

OKLCH is the only working space: the floor ships the state ladder — `--accent-hover`, `--accent-active`, `--accent-weak`, `--editorial-weak` — and a template derives only its local fills, always by `color-mix` in OKLCH off a floor token. An sRGB mix desaturates along a different curve than its OKLCH sibling and the gate fails it.

```css copy-safe
@layer tokens {
  :root {
    --fail-fill: color-mix(in oklch, var(--fail) 14%, transparent);
    --hairline-heavy: color-mix(in oklch, var(--text) 16%, transparent);
    --scrim: color-mix(in oklch, var(--bg) 55%, transparent);
  }
}
```

- [FLOOR_LADDER]: hover, active, weak, and on-accent values are floor tokens; a template re-mixing its own hover shade forks the interaction grammar and is a defect.
- [ALPHA_LADDER]: `color-mix(in oklch, <token> N%, transparent)` derives fills, hairlines, and scrims; a soft fill is a transparency of the status token, not a second hue.
- [OKLCH_ANATOMY]: OKLCH separates perceptual lightness, chroma, and hue, so equal lightness reads equal across hues and a token ladder holds contrast where an HSL ladder drifts.
- [CHROMA_CLIP]: high chroma clips to the device gamut and shifts hue; the floor holds chroma conservative so each mix stays in gamut across themes.
- [MUTED_LEGAL]: `--text-muted` is contrast-guaranteed body copy; `--text-faint` carries labels alone, and no sentence a reader must not miss rides it.
- [FORCED_COLORS]: `forced-colors: active` swaps author color for system keywords — `Canvas`, `CanvasText`, `ButtonText`, `Highlight` — and borders and outlines carry the semantics color drops.

## [09]-[FLUID]

The modular scale is fixed; fluidity lives in exactly one token — `--fs-4xl`, the display ramp — plus template-local space pairs. Body, heading, and data sizes hold their scale steps so the type system stays locked across artifacts.

```css copy-safe
@layer tokens {
  :root {
    --space-s: clamp(var(--s2), 0.6rem + 0.8cqi, var(--s4));
    --space-l: clamp(var(--s5), 1rem + 2cqi, var(--s6));
  }
}
@layer components {
  .hero h1 { font-size: var(--fs-4xl); line-height: var(--lh-tight) }
}
```

- [ONE_RAMP]: display type rides `--fs-4xl`; a second fluid type token forks the scale, and body or control text never rides a viewport-relative size.
- [RAMP_ANCHORS]: a `clamp()` floor and ceiling in rem hold the accessibility bound, and the middle term mixes a rem base with a container unit so the ramp scales locally.
- [CQI_LOCAL]: `cqi` grows against the nearest inline container; with no query container it resolves against small viewport units, a silent fallback that breaks component-local intent.
- [ZOOM_FLOOR]: a viewport-only or px-only font size defeats 200% text zoom; the rem anchors inside `clamp()` are the zoom contract.

## [10]-[MOTION]

The floor ships entry durations, shorter exit durations, and three easings, and zeroes every duration under reduced motion — a transition reading the tokens collapses to instant for the reduced-motion reader with no per-rule guard. Exit asymmetry is structural: the base rule carries the exit duration and `--ease-standard`, the open-state selector (`:popover-open`, `[open]`) overrides to the entry duration and `--ease-out`, so every overlay leaves faster and quieter than it arrived. Focus rings transition nothing — they appear instantly.

| [INDEX] | [MOVE]                   | [TOKENS]                                         |
| :-----: | :----------------------- | :----------------------------------------------- |
|  [01]   | tint, color, border      | `--dur-1` + `--ease-standard`                    |
|  [02]   | lift, reveal, disclosure | `--dur-2` in, `--dur-out-2` out, `--ease-out` in |
|  [03]   | overlay, panel slide     | `--dur-3` in, `--dur-out-3` out, `--ease-out` in |
|  [04]   | micro-celebration        | `--ease-spring`, one element, once               |

```css copy-safe
@layer components {
  @property --lift { syntax: "<number>"; inherits: false; initial-value: 0 }
  .card { --lift: 0; transform: translateY(calc(var(--lift) * -1 * var(--s1)));
    transition: --lift var(--dur-2) var(--ease-out), background-color var(--dur-1) var(--ease-standard) }
  .card:hover { --lift: 1 }
  .pop { opacity: 1; transform: translateY(0);
    transition: opacity var(--dur-2) var(--ease-out), transform var(--dur-2) var(--ease-out), display var(--dur-2) allow-discrete }
  @starting-style { .pop:popover-open { opacity: 0; transform: translateY(var(--s2)) } }
}
@supports (animation-timeline: scroll()) {
  .reading-bar { animation: fill linear both; animation-timeline: scroll(root block); transform-origin: left }
  @keyframes fill { from { scale: 0 1 } to { scale: 1 1 } }
}
```

- [TYPED_TRANSITION]: a `@property`-typed number interpolates, so a custom property drives transform and color transitions a raw variable cannot.
- [DISCRETE]: `transition-behavior: allow-discrete` with `@starting-style` animates a `display`-toggled overlay in and out; opacity and transform carry the visible motion while `display` flips discretely.
- [TRANSITION_ALL]: `transition: all` hides ownership and animates unintended properties; a component lists its transitioned properties.
- [DISPLAY_ONLY]: a `display`-only transition never renders; opacity and transform carry the visible change or the reveal cuts.
- [SPRING_BUDGET]: `--ease-spring` marks one completed action — a check settling, a copy confirming; a spring on hover or layout motion reads as jitter.
- [SCROLL_ENHANCE]: `animation-timeline: scroll()` behind its `@supports` guard drives orientation-only progress, and comprehension never depends on a scroll animation.

## [11]-[LOGICAL]

Layout speaks the inline and block axes so a sheet survives writing-mode and localization; physical sides stay only where geometry is physical — shadows, transforms, and print imposition.

```css copy-safe
@layer base {
  .flow { margin-inline: auto; max-inline-size: var(--measure);
    padding-block: var(--s6); padding-inline: clamp(var(--s4), 4cqi, var(--s6)) }
  .callout { border-inline-start: 3px solid var(--editorial); padding-inline-start: var(--s4); margin-block: var(--s4) }
}
```

- [INLINE_BLOCK]: `margin-inline`, `padding-block`, `inset-inline`, and `border-inline-start` map to the writing mode, and `min-inline-size` with `max-block-size` replaces width and height for flow-relative sizing.
- [PHYSICAL_KEEP]: `box-shadow` offsets, `transform` coordinates, gradient angles, and print crop geometry stay physical — the axis is the medium, not the text flow.
- [SHORTHAND_RESET]: `margin-inline` sets both inline sides at once, so mixing it with a physical longhand in one layer silently resets the intended side unless the physical override is deliberate.

## [12]-[PREFERENCES]

Preference queries are peers — color scheme, reduced motion, contrast, forced colors, and print each carry an environmental truth into one token branch, so a preference rewrites values, never a parallel component.

```css copy-safe
@layer overrides {
  @media (prefers-contrast: more) { :root { --line: var(--line-strong) } }
  @media (forced-colors: active) {
    :root { --accent: Highlight; --line: CanvasText }
    * { box-shadow: none; text-shadow: none }
  }
}
```

- [SCHEME]: `color-scheme` and `data-theme` carry the palette; the floor owns the mechanism and a template composes the token branch alone.
- [MOTION_GATE]: reduced motion zeroes `--dur-1/2/3` in the floor's tokens layer, one seam the whole sheet reads.
- [CONTRAST]: `prefers-contrast: more` strengthens hairline tokens and widens the focus ring — the floor already carries the ring rule.
- [TOKEN_BRANCH]: a preference-specific component one-off forks the component; the branch belongs in a token rewrite the component already reads.
- [FOCUS_KEPT]: no preference branch removes a focus ring; contrast and forced-colors strengthen it.

## [13]-[PRINT]

Print is the terminal medium branch: the floor's print layer flips the tokens to the light sheet and hides screen controls; the template print layer carries only its own reflow, fragmentation, and utilities — never a second token flip.

```css copy-safe
@layer print {
  @page { size: letter }
  @media print {
    .shell, .deck-grid, .panel__body { display: block }
    .card, figure, table, pre, tr { break-inside: avoid }
    h1, h2, h3 { break-after: avoid }
    .section--major { break-before: page }
    [data-print="omit"], .no-print { display: none }
    .print-only { display: revert }
    a[href]:not([href^="#"])::after { content: " (" attr(href) ")"; font-size: .85em; overflow-wrap: anywhere }
  }
}
.print-only { display: none }
```

- [FRAGMENTATION]: `break-inside: avoid` holds a card, row, figure, or code block whole, `break-after: avoid` keeps a heading with its content, and `break-before: page` opens a major section on a fresh sheet.
- [AVOID_IS_REQUEST]: `break-inside: avoid` is a request an oversized box overrides by fragmenting; a unit that must stay whole is sized to a single sheet.
- [BG_SUPPRESSED]: a print setting drops dark backgrounds and images, so the light token flip prints the page independent of that setting.
- [LINK_EXPAND]: an off-page link expands to its `href` through `::after`, and the `:not([href^="#"])` guard excludes an in-page anchor.
- [HOVER_DIES]: hover-revealed and overlay-only content never carries load-bearing evidence; print and touch receive the default state alone.
