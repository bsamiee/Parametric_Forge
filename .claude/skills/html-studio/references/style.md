# [STYLE]

The design language is dark-first on a violet-black ground: tone carries depth, violet carries interaction, copper carries editorial voice, mono carries every datum. One token registry, one cascade architecture, and one legibility law bind every artifact, so a plan, a dashboard, and a deck read as one system.

## [01]-[CASCADE]

The stylesheet is an architecture: layers order the cascade once, and every rule lands in a named layer.

```css copy-safe
@layer reset, tokens, base, components, utilities, print, overrides;
```

- [LAYER_HOMES]: the reset, token registry, and element base populate the early layers; artifact components land in `components`, one-off structure in `utilities`, print reflow in `print`, forced-state and preference rewrites in `overrides`. Same-name layers merge, and later source order wins ties inside a layer.
- [NO_UNLAYERED]: one unlayered rule outranks every layer and re-opens the specificity war the architecture closed; every rule is authored inside a named layer.
- [IMPORTANT_INVERTS]: `!important` flips layer precedence toward the earliest layer; it is legal only inside `print` and `overrides`, for forced-state resets alone.
- [PRECEDENCE]: resolution runs origin, importance, layer, specificity, then source proximity — layer outranks specificity for normal declarations, and `revert-layer` rolls a property back to earlier layers.
- [SELECTOR_WEIGHT]: `:where()` carries reach at zero weight, `:is()` takes its heaviest argument, nesting keeps the parent's layer, and `@scope (root) to (limit)` styles a component's donut without leaking into nested instances. IDs stay out of every functional-pseudo argument, and two nesting levels is the ceiling per component.
- [LOCAL_TOKENS]: an artifact's own `tokens` additions seed only local structure values — lane widths, gaps, counts; palette, scale, motion, and state variants live in the registry and never repeat locally.

## [02]-[TOKENS]

Semantic names only — a consumer reads intent, never hex. The dark registry is the shipped base:

```css copy-safe
@property --tone {
    syntax: '<percentage>';
    inherits: true;
    initial-value: 0%;
}
@property --raise {
    syntax: '<number>';
    inherits: true;
    initial-value: 0;
}
@layer tokens {
    :root {
        color-scheme: dark;
        --bg: oklch(0.16 0.022 290);
        --surface: oklch(0.205 0.024 290);
        --raised: oklch(0.245 0.026 290);
        --raised-2: oklch(0.295 0.028 290);
        --overlay: oklch(0.345 0.03 290);
        --line: oklch(1 0 0/0.09);
        --line-strong: oklch(1 0 0/0.16);
        --boundary: oklch(0.84 0.089 304);
        --text: oklch(0.965 0.008 290);
        --text-muted: oklch(0.78 0.03 290);
        --text-faint: oklch(0.66 0.032 290);
        --accent: oklch(0.72 0.185 292);
        --accent-hover: oklch(0.78 0.18 292);
        --accent-active: oklch(0.655 0.175 292);
        --accent-weak: oklch(0.72 0.185 292/0.16);
        --on-accent: oklch(0.16 0.02 292);
        --focus: var(--accent);
        --editorial: oklch(0.71 0.13 55);
        --editorial-weak: oklch(0.71 0.13 55/0.14);
        --ok: oklch(0.76 0.15 150);
        --warn: oklch(0.8 0.14 78);
        --fail: oklch(0.7 0.2 25);
        --info: oklch(0.79 0.12 225);
        --series-1: oklch(0.72 0.185 292);
        --series-2: oklch(0.72 0.17 350);
        --series-3: oklch(0.74 0.12 225);
        --series-4: oklch(0.74 0.15 150);
        --series-5: oklch(0.78 0.13 65);
        --series-6: oklch(0.8 0.11 110);
        --s1: 4px;
        --s2: 8px;
        --s3: 12px;
        --s4: 16px;
        --s5: 24px;
        --s6: 32px;
        --s7: 48px;
        --s8: 64px;
        --fs-2xs: 0.694rem;
        --fs-xs: 0.833rem;
        --fs-sm: 0.9rem;
        --fs-md: 1rem;
        --fs-lg: 1.2rem;
        --fs-xl: 1.44rem;
        --fs-2xl: 1.728rem;
        --fs-3xl: 2.074rem;
        --fs-4xl: clamp(2.074rem, 1.6rem + 2.2cqi, 2.986rem);
        --lh-tight: 1.15;
        --lh-heading: 1.25;
        --lh-body: 1.6;
        --lh-data: 1.4;
        --font-display: ui-serif, Georgia, 'Iowan Old Style', serif;
        --font-sans: ui-sans-serif, system-ui, 'Segoe UI', Roboto, sans-serif;
        --font-mono: ui-monospace, 'SF Mono', Menlo, 'Cascadia Mono', Consolas, monospace;
        --dur-1: 120ms;
        --dur-2: 200ms;
        --dur-3: 320ms;
        --dur-out-2: 140ms;
        --dur-out-3: 230ms;
        --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
        --ease-standard: cubic-bezier(0.2, 0, 0, 1);
        --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);
        --r-1: 6px;
        --r-2: 10px;
        --r-3: 16px;
        --r-full: 999px;
        --measure: 1100px;
        --shadow-1: 0 1px 2px oklch(0 0 0/0.45), 0 1px 1px oklch(0 0 0/0.3);
        --shadow-2: 0 6px 24px oklch(0 0 0/0.55), 0 2px 6px oklch(0 0 0/0.4);
    }
    @media (prefers-reduced-motion: reduce) {
        :root {
            --dur-1: 0ms;
            --dur-2: 0ms;
            --dur-3: 0ms;
            --dur-out-2: 0ms;
            --dur-out-3: 0ms;
        }
    }
}
```

The light palette is one declaration block carried twice — inside `@media (prefers-color-scheme: light)` scoped to `:root:not([data-theme])`, and under the selector below, so a stamped choice suppresses the media branch and wins in both directions. Both light blocks — and the print flip's token rewrites — precede the dark base in source: layer precedence and specificity, not source order, select the palette, and the last-declared registry, the dark base, is the one the artifact gate audits.

```css copy-safe
@layer tokens {
    :root[data-theme='light'] {
        color-scheme: light;
        --bg: oklch(0.975 0.008 85);
        --surface: oklch(0.945 0.012 85);
        --raised: oklch(1 0 0);
        --raised-2: oklch(1 0 0);
        --overlay: oklch(1 0 0);
        --line: oklch(0 0 0/0.1);
        --line-strong: oklch(0 0 0/0.16);
        --boundary: oklch(0.55 0.16 301);
        --text: oklch(0.21 0.012 290);
        --text-muted: oklch(0.43 0.02 290);
        --text-faint: oklch(0.54 0.02 290);
        --accent: oklch(0.52 0.19 292);
        --accent-hover: oklch(0.47 0.19 292);
        --accent-active: oklch(0.44 0.18 292);
        --accent-weak: oklch(0.52 0.19 292/0.12);
        --on-accent: oklch(0.99 0 0);
        --editorial: oklch(0.55 0.12 55);
        --editorial-weak: oklch(0.55 0.12 55/0.1);
        --ok: oklch(0.52 0.15 150);
        --warn: oklch(0.56 0.13 70);
        --fail: oklch(0.53 0.2 25);
        --info: oklch(0.52 0.12 235);
        --series-1: oklch(0.52 0.19 292);
        --series-2: oklch(0.54 0.17 350);
        --series-3: oklch(0.54 0.12 225);
        --series-4: oklch(0.55 0.13 150);
        --series-5: oklch(0.58 0.12 65);
        --series-6: oklch(0.6 0.11 110);
        --shadow-1: 0 1px 2px oklch(0 0 0/0.08), 0 1px 1px oklch(0 0 0/0.05);
        --shadow-2: 0 6px 24px oklch(0 0 0/0.12), 0 2px 6px oklch(0 0 0/0.08);
    }
}
```

- [ELEVATION]: `--bg` through `--overlay` step lightness by 0.04–0.05 in dark, so depth is carried by tone; in light, `--surface` is the one recessed step and depth above white is carried by `--shadow-1`/`--shadow-2` with hairlines. `--line` and `--line-strong` are ink-alpha hairlines that read at every elevation; `--boundary` is the bright containment stroke every dashed zone binds.
- [TEXT_ROLES]: `--text-muted` is contrast-guaranteed body copy; `--text-faint` is decoration-only ink for grip dots, disabled controls, and filter-dimmed rows at 13px and above — an information-bearing label at 12px or below binds `--text-muted`, never faint.
- [ACCENT_ROLES]: violet is the interactive role — buttons, links, focus, selection, meters; copper (`--editorial`) is the editorial role — eyebrows, section numerals, keyline callouts, figure captions. Copper never fills a control, and violet never decorates prose.
- [STATUS]: `--ok` `--warn` `--fail` `--info` mark state on chips, rails, and marks; the bracket text — `[DONE]` `[BLOCKED]` `[AT-RISK]` — is the accessible carrier and hue is reinforcement.
- [SERIES]: `--series-1`..`--series-6` paint chart marks only. The dark ladder holds one lightness band (0.72–0.80) and one chroma band (0.11–0.19) with hue gaps of 40° or more, so no series reads as emphasis; the light branch restates the ladder at 0.52–0.60 lightness, because a 0.72-lightness mark on white drops below the graphical-contrast floor.
- [SPACE_AND_SHAPE]: every gap, pad, and margin rides `--s1`..`--s8`; radii ride `--r-1`..`--r-full`; one `--measure` per artifact.

## [03]-[COLOR]

OKLCH is the only working space, and the channels carry distinct jobs: lightness owns elevation, text hierarchy, and contrast; chroma owns emphasis; hue owns identity. Equal lightness reads equal across hues, so a ladder built on L holds contrast where an HSL ladder drifts.

- [DERIVED_ONLY_MIX]: every derived color is `color-mix(in oklch, ...)` off a registry token — fills at `<token> 10-22%, transparent`, hairlines at `var(--text) 16%, transparent`, scrims at `var(--bg) 55%, transparent`. A raw hex or an sRGB mix forks the palette and desaturates along the wrong curve.
- [STATE_POLARITY]: interactive state moves lightness toward the theme's ink — dark hover lightens (+0.06 L) and active darkens; light hover darkens (−0.05 L) and active darkens further — so pressed reads as pressed in both themes. The hover, active, and weak values are registry tokens; a locally re-mixed hover forks the interaction grammar.
- [RELATIVE_DERIVE]: a lightness-only or chroma-only move derives through relative color syntax — `oklch(from var(--accent) calc(l + 0.06) c h)` — while `color-mix` owns blends between two colors; each idiom names the operation it performs.
- [ON_ACCENT]: text on a filled accent binds `--on-accent`, an ink derived from the ground rather than white, so the filled control holds contrast in both themes.
- [CHROMA_DISCIPLINE]: registry chroma stays conservative (≤0.2) so every mix lands in gamut in both themes; high chroma clips to the device gamut and shifts hue at the clip.
- [CONTRAST_LAW]: body text holds 4.5:1 against its resting surface, and graphical marks and UI edges hold 3:1. A tinted chip is judged after compositing: ink over a 14% status fill over `--surface` is the pair that must clear the floor, not ink over the raw token.
- [HUE_ANCHORS]: the ground family sits at hue 290 with trace chroma (0.008–0.03) so neutrals stay warm-violet rather than dead gray; accent hue 292 keeps the interactive role inside the ground's family, and copper at 55 opposes it across the wheel. Status hues spread across the green, amber, red, and blue quadrants — far enough apart that no state pair collides under common color-vision deficits once the bracket text is present — and each theme tunes its own exact status lightness for its ground.

## [04]-[TYPOGRAPHY]

Type is a role system with one voice per job: mono is the systemic voice — every numeral, label, tag, chip, keycap, data cell, stamp, and code span; serif (`--font-display`) is a restrained editorial accent spent on `h1` and `h2` alone; sans carries sentences and nothing else. The stacks are system-native, so zero font bytes travel and the page renders identically offline.

The scale is modular at ratio 1.2, and fluidity lives in exactly one token — `--fs-4xl`, the display ramp, whose `clamp()` anchors in rem hold the 200% zoom contract while `cqi` scales it locally. Every class carries an exact floor; an element rendering below its floor is a defect regardless of how the page reads at a glance.

| [INDEX] | [ROLE]                        | [TOKEN]      | [FAMILY_WEIGHT]    | [FLOOR] |
| :-----: | :---------------------------- | :----------- | :----------------- | :------ |
|  [01]   | h1                            | `--fs-3xl`   | serif 600          | 30px    |
|  [02]   | h2                            | `--fs-xl`    | serif 600          | 21px    |
|  [03]   | h3                            | `--fs-lg`    | sans 600           | 18px    |
|  [04]   | deck, lead                    | `--fs-lg`    | sans 400           | 17px    |
|  [05]   | stat numeral                  | `--fs-2xl`   | mono 600 tabular   | 22px    |
|  [06]   | body p, li                    | `--fs-md`    | sans 400           | 15px    |
|  [07]   | table cell                    | `--fs-sm`    | sans, mono for num | 13px    |
|  [08]   | pre, code block               | `--fs-xs`    | mono 400           | 12px    |
|  [09]   | small, caption                | `--fs-xs`    | sans 400           | 12px    |
|  [10]   | svg canvas label              | 11px literal | mono 400-500       | 11px    |
|  [11]   | eyebrow, chip, th, kbd, delta | `--fs-2xs`   | mono 600 uppercase | 11px    |

- [MICRO_LEGALITY]: `--fs-2xs` is the label floor, legal only as uppercase mono at weight 600 with letter-spacing at or above `.06em` — never sentence text, never faint ink.
- [TRACKING]: eyebrows track `.08em`; chips, `th`, kv labels, and section numerals `.06em`; numerals track `-.01em` and always set `font-variant-numeric: tabular-nums`.
- [RHYTHM]: line height is a role — `--lh-tight` for display, `--lh-heading` for headings, `--lh-body` for sentences, `--lh-data` for cells; headings set `text-wrap: balance` and body sets `text-wrap: pretty`.
- [MEASURE]: sentences hold 45–75 characters; the deck line caps at `60ch` regardless of the artifact's `--measure`.

## [05]-[HIERARCHY]

Salience is budgeted; the review counts it.

- [ONE_PRIMARY]: a card, panel, or viewport region carries one element at display scale and at most three secondary signals; a second competing numeral or headline demotes or leaves.
- [ONE_FACT_ONE_FORM]: a status, owner, date, or priority renders exactly once per card — a status chip beside a status-tinted border restating the same state is duplication, and `[BLOCKED-BY] <name>` replaces, never accompanies, the bare `[BLOCKED]` chip it explains.
- [ACCENT_BUDGET]: violet appears as a filled field somewhere above the fold — the primary action, active tab, or meter — and covers well under a tenth of the viewport; status hues stay under a twentieth, since a page glowing with status color has spent its alarm before anything is wrong.
- [EDGE_BUDGET]: a viewport exposes at most three major left edges — shell, content, inset — and a card at most two interior edges; a fourth alignment axis is a layout defect.
- [HEADER_BAND]: metadata sits above or baseline-beside the title, the title follows within `--s2`, actions sit at the right edge — a title never sandwiches between two metadata rows.
- [ELEVATION_NESTING]: a chip, input, code block, or `th` sits one step down from its host (`--surface` on `--raised`); a nested card steps up to `--raised-2` — never `--raised` on `--raised`. Card-to-card separation is carried by the `--s4` gap; a same-tone abutment without the gap steps its border to `--line-strong`, since `--line` between equal elevations vanishes.
- [HAIRLINE_ORDER]: decorative dividers ride 1px `--line`; structural dividers and same-elevation borders ride `--line-strong`; a chart's zero baseline steps to `--line-strong` above `--line` gridlines — a hairline never outweighs the structural line beside it.
- [DIM_LEGIBLY]: a de-emphasized row keeps legible text — faint labels, a `--fail` rail, a strike on the leading cell; whole-row `opacity` drops content below the contrast floor and is banned.
- [HEAT_CEILING]: heat-cell intensity tops at 60% toward `--accent` so cell text holds 4.5:1 at full score; a winner signals through its `--ok` rail, never fill alone.
- [ANATOMY]: component metrics are fixed — chips 20px tall with `--s2` inline padding, buttons and inputs 32px, toolbars 48px, card padding `--s4` with `--s3` compact and `--s5` reading variants, icon gaps `--s1` inside chips and `--s2` inside buttons, kv rows baseline-aligned.

## [06]-[LAYOUT]

The artifact class fixes the content column, and one `--measure` rules the page — a page mixing widths per section reads as three documents stapled together.

| [INDEX] | [CLASS]                                 | [MEASURE]          | [COLLAPSE]                        |
| :-----: | :-------------------------------------- | :----------------- | :-------------------------------- |
|  [01]   | reading — explainer, brief, quiz        | `760px`–`900px`    | single column throughout          |
|  [02]   | operational — plan, report, diff-review | `1040px`–`1120px`  | sidebar folds under `56rem`       |
|  [03]   | board — editor, dashboard, wargame      | `1180px`–`1280px`  | four columns to two under `64rem` |
|  [04]   | stage — architecture, atlas, prototype  | full viewport      | stage scrolls inside itself       |
|  [05]   | deck                                    | per-slide viewport | slide content holds reading width |

- [GRID_OWNS]: grid owns page shells and two-dimensional rhythm through `grid-template-areas`, so a container query rewrites the area map and reflows the whole page at one edit; flex packs one axis; every interior gap rides `gap`, never a child margin.
- [SUBGRID]: a card adopting `grid-template-rows: subgrid` aligns its header, body, and footer to sibling cards across the parent tracks; label-field pairs adopt column subgrid the same way.
- [AUTO_FIT]: `repeat(auto-fit, minmax(min(100%, 18rem), 1fr))` wraps a collection with no query and never overflows a narrow container.
- [MIN_ZERO]: a bare `1fr` track carries a min-content floor and overflows long content; `minmax(0, 1fr)` on the track plus `min-inline-size: 0` on the child release it.
- [CONTAINER_QUERIES]: breakpoints live at the container wherever a container ancestor exists; a size container never styles itself from its own query, so a queried component wraps in an element carrying `container-type: inline-size`.
- [STICKY]: a sticky element pins one axis and one concern — toolbar at top, contents rail at `top: var(--s4)` with `align-self: start`, a column header inside its own scroll container; a panel sticky on both axes is a fixed element wearing the wrong position.
- [LOGICAL_AXES]: layout speaks `margin-inline`, `padding-block`, `inset-inline`, and `border-inline-start`; physical sides survive only where geometry is physical — shadows, transforms, gradient angles, print imposition.
- [FLUID_SPACE]: a locally fluid gap is one `clamp()` pair — rem floor and ceiling holding the zoom contract, a `cqi` middle term scaling against the nearest container — beside the fixed `--s*` steps.

The structural devices are the page's shared visual vocabulary; every artifact composes from this set, so sibling artifacts read as one system.

- [01]-[HEADER_TRIAD]: mono eyebrow kicker, serif display `h1`, muted deck line.
- [02]-[SECTION_NUMERALS]: CSS-counter `h2::before` in copper mono where order is meaningful.
- [03]-[STAT_CHIP]: mono display numeral, mono caption, signed trend delta.
- [04]-[METER]: violet gradient fill driven by `--value`; segmented variant stacks status shares.
- [05]-[KEYLINE_RAIL]: 3px inline-start callout — copper for asides, status hue for verdicts.
- [06]-[HEAT_CELL]: fill mixed toward `--accent` by score share, capped at 60%.
- [07]-[TIMELINE_SPINE]: rail of stamped dot rows; dot hue carries state, the rail carries order.
- [08]-[SPLIT_PANE]: before-and-after panels sharing one header row and one scroll shell.
- [09]-[SIDENOTE]: margin annotation floated into the gutter, folding to block flow when narrow.

## [07]-[STATE_SYSTEM]

Containers, `:has()`, and registered custom properties form one state machine: data flows down through properties, state flows up through `:has()`, and size flows sideways through container queries.

```css copy-safe
@layer components {
    .panel {
        container: panel / inline-size;
        background: color-mix(in oklch, var(--raised), var(--accent) var(--tone));
        box-shadow: 0 calc(var(--raise) * var(--s1)) calc(var(--raise) * var(--s4)) oklch(0 0 0 / 0.28);
        transition:
            --tone var(--dur-2) var(--ease-standard),
            --raise var(--dur-2) var(--ease-standard);
    }
    .panel:has(:is(input, textarea, select):focus-visible) {
        --tone: 10%;
        --raise: 1;
    }
    .panel:has([aria-invalid='true']) {
        --tone: 14%;
        border-color: var(--fail);
    }
    @container panel (inline-size >= 42rem) {
        .panel__body {
            display: grid;
            grid-template-columns: minmax(12rem, 0.8fr) minmax(0, 1.2fr);
            gap: var(--s4);
        }
    }
}
```

- [DATA_DOWN]: a parent seeds `--tone`, `--raise`, and `--density`, and the whole subtree reads them — one property carries a value every descendant consumes.
- [STATE_UP]: `:has()` reads a descendant condition and rewrites the owner's properties, so focus, invalid, and expanded states flow upward with no class toggle; it binds to a stable named container, never the document root, since a body-wide `:has()` reevaluates the whole tree on every mutation.
- [STYLE_QUERY]: a `@container style(...)` branch rides only beside an attribute-selector branch carrying the same rule — the selector is load-bearing and the style query refines it.

## [08]-[MOTION]

Entries ride the entry durations and exits ride the shorter `--dur-out-*` set with `--ease-standard` — leaving is quicker and quieter than arriving, structurally: the base rule carries the exit, and the open-state selector (`:popover-open`, `[open]`) overrides to the entry duration and `--ease-out`.

| [INDEX] | [MOVE]                   | [TOKENS]                                         |
| :-----: | :----------------------- | :----------------------------------------------- |
|  [01]   | tint, color, border      | `--dur-1` + `--ease-standard`                    |
|  [02]   | lift, reveal, disclosure | `--dur-2` in, `--dur-out-2` out, `--ease-out` in |
|  [03]   | overlay, panel slide     | `--dur-3` in, `--dur-out-3` out, `--ease-out` in |
|  [04]   | micro-celebration        | `--ease-spring`                                  |

- [TYPED_PROPERTY]: a `@property`-registered number or percentage interpolates and type-checks, so one custom property (`--tone`, `--raise`) drives background, shadow, and transform together; an unregistered property is a string and never animates.
- [DISCRETE_REVEAL]: `transition-behavior: allow-discrete` with `@starting-style` animates `display`-toggled overlays in and out; opacity and transform carry the visible motion while `display` flips discretely.
- [NAMED_TRANSITIONS]: a component lists its transitioned properties; `transition: all` hides ownership and animates the unintended.
- [SPRING_BUDGET]: `--ease-spring` marks one completed action — a check settling, a copy confirming; a spring on hover or layout reads as jitter.
- [REDUCED_MOTION]: the registry zeroes every duration under `prefers-reduced-motion`, so a transition reading the tokens collapses to instant with no per-rule guard. Focus rings transition nothing — they appear instantly.
- [SCROLL_ENHANCE]: `animation-timeline: scroll()` behind `@supports` drives orientation-only progress; comprehension never depends on a scroll animation.

## [09]-[THEMES_AND_PREFERENCES]

The base root is dark; light arrives twice — by system preference for the unstamped page, by `data-theme="light"` on the root when a choice is stamped — and `color-scheme` follows the palette so native controls match. A preference rewrites token values, never a parallel component.

- [PRINT_FLIP]: the print layer flips the registry to the light palette on white, drops shadows, hides screen chrome (`.toolbar`, `.export-bar`, `.drawer-tab`, `.toc`, buttons), expands disclosure, and holds `break-inside: avoid` on cards, rows, figures, and code with `break-after: avoid` on headings; `print-color-adjust: exact` keeps the tokened tints. `break-inside: avoid` is a request an oversized box overrides — a unit that must stay whole is sized to a sheet.
- [FORCED_COLORS]: `forced-colors: active` hands the palette to system keywords — `Canvas`, `CanvasText`, `Highlight` — and zeroes shadows; borders and outlines carry the semantics color drops.
- [CONTRAST_MORE]: `prefers-contrast: more` promotes `--line` to `--line-strong` and widens the focus ring; no preference branch removes a focus ring.

## [10]-[LEGIBILITY]

Legibility floors bind harder than any aesthetic: a page that reads at a glance and fails at the element level fails.

- Font sizes anchor in rem so 200% text zoom holds; a px-only or viewport-only size defeats it.
- Hover-revealed content is never load-bearing — touch and print receive the default state, so the argument survives with zero hover.
- Wide content — tables, diagrams, code — scrolls inside its own `overflow-x: auto` container while the body never scrolls sideways.
- Focus is always visible: a two-ring `:focus-visible` box-shadow (`--bg` inner, `--focus` outer) rides every focusable element, and `outline: none` is legal only in the rule that supplies that replacement.
- Long unbroken tokens — paths, hashes, ids — carry `overflow-wrap: anywhere` so a single value never forces a horizontal scroll.
- Every state has a second channel: hue pairs with bracket text, fill intensity with a value, a dash with a label — the page reads in grayscale.
