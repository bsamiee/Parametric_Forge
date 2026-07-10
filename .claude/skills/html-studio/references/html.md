# [HTML]

Markup is the argument: every fact rides the native element that owns its meaning, so the document reads intact with the stylesheet and script deleted. The shell grammar fixes where everything lives, the vocabulary fixes what each element carries, the admission bands fix what platform surface ships, and ARIA repairs only what no native element expresses.

## [01]-[SHELL]

One `<!doctype html>` document opens `<html lang="en">` and declares `<meta charset="utf-8">`, `<meta name="viewport" content="width=device-width,initial-scale=1">`, and one `<title>` naming the artifact — the browser tab, receipt attribution, and theme-persistence key all read it. All CSS lands in one `<style>`; one executable `<script>` closes the body; `<script type="application/json">` blocks are inert data, never code.

Body order is fixed: skip link, artifact `<header>`, sticky control band, the layout shell around `<main id="main">`, auxiliary native surfaces — `<template>`, `<dialog>`, `[popover]` panels — after `<main>`, the export drawer, payload data, then the executable script.

- One `<h1>` per document. Headings descend without level skips, and each names a claim or a reader task, never a bare topic.
- The root element is the theme seam: the script stamps `data-theme` on `<html>` and every other node just reads tokens.
- Every `id` is unique and stable: sections carry ids so the contents rail, fragment deep links, scroll spy, and capture records address them, and the same ids serve `aria-labelledby` and `for` wiring.
- The `style` attribute never appears — presentation binds through a class or a custom property written by `style.setProperty`, so state stays inspectable and theme-safe.
- Inline handler attributes never appear; the delegation script owns every event. `data-*` carries machine state — `data-id` for record identity, `data-k` for figure keys, `data-state` for lifecycle — while classes carry appearance alone.
- The executable script is one IIFE ordered models, then pure operations, then composition wiring, so the script audits top-down in owner order.
- `<base href>` never appears — it silently rewrites every relative resolution in the document.
- A deck is the one alternate visible shell — a full-viewport stack of `<section class="slide">` panels under the same payload, drawer, and script grammar.

## [02]-[LANDMARKS]

Landmarks hand assistive navigation the same map the visual layout draws.

- `<main id="main">` appears once and holds the argument. `<header>` carries the masthead, `<nav>` wraps the contents rail, `<aside>` carries the detail rail and sidenotes, `<footer>` closes the shell, and `<search>` wraps every filter cluster.
- A repeated landmark kind takes a distinguishing `aria-label`: `<nav aria-label="Sections">` beside `<nav aria-label="Slides">`.
- The `<title>` text mirrors the `<h1>` claim, so the tab, the window, and the print header agree on what the page is.
- The masthead is a fixed triad — mono eyebrow kicker, the `<h1>`, a muted deck line — with the chip row baseline-beside or above the title, never below it.
- The skip link is the first focusable node — `<a class="skip" href="#main">Skip to content</a>` — and a target that is not natively focusable carries `tabindex="-1"` so focus actually lands.
- Native semantics precede ARIA: `role` appears only where no element exists — `tablist`/`tab`/`tabpanel`, `role="img"` on meaning-bearing SVG, `role="status"` on the toast, `role="meter"` on the styled meter bar. A role restating its element (`role="button"` on `<button>`) is a defect.
- State and position ride their canonical carriers: `aria-pressed` on every toggle button, `aria-expanded` on a control owning a collapsed region, `aria-current="step"` on the active step, `aria-current="page"` on the active rail anchor, `aria-selected` with roving `tabindex` inside composites, `aria-label` on every icon-only button.
- `inert` freezes a background region while an overlay owns interaction; `hidden="until-found"` keeps collapsed prose reachable by find-in-page where plain `hidden` buries it, and the `beforematch` event tells the script to expand the revealed region's owner.
- `.sr-only` text supplies context sight already carries — a legend name, a table caption, a control's expanded label; load-bearing content that sighted readers also need never hides there.
- A changing readout — filter count, dirty tally, slide counter — renders in `<output>` or a `role="status"` node, so its updates announce without stealing focus.

## [03]-[VOCABULARY]

Each element earns its row by the reader question it answers natively; the displaced form names the script or div construction the element deletes.

| [INDEX] | [ELEMENT]                   | [CARRIES]                          | [DISPLACES]          |
| :-----: | :-------------------------- | :--------------------------------- | :------------------- |
|  [01]   | `<table>`                   | facts crossed row by column        | grid of divs         |
|  [02]   | `<dl class="kv">`           | key-value ledger                   | label-span pairs     |
|  [03]   | `<details name>`            | exclusive disclosure group         | accordion script     |
|  [04]   | `<dialog>`                  | modal decision                     | overlay manager      |
|  [05]   | `[popover]`                 | top-layer panel, menu, toast       | z-index stack        |
|  [06]   | `<meter>`                   | scalar judged against known bounds | bare numeral         |
|  [07]   | `<progress>`                | task completion                    | spinner div          |
|  [08]   | `<output for>`              | computed result of named inputs    | live span            |
|  [09]   | `<time datetime>`           | machine-readable instant           | text-only date       |
|  [10]   | `<data value>`              | machine value under display text   | dataset duplication  |
|  [11]   | `<figure>` + `<figcaption>` | captioned evidence object          | floating caption     |
|  [12]   | `<fieldset>` + `<legend>`   | named control group                | div with heading     |
|  [13]   | `<datalist>`                | suggested completions              | dropdown script      |
|  [14]   | `<template>`                | inert repeat-row markup            | markup string concat |
|  [15]   | `<ol start reversed>`       | true sequence semantics            | styled ul            |
|  [16]   | `<mark>` `<kbd>` `<code>`   | hit, keystroke, symbol             | tinted spans         |

Meter and progress split by meaning, never by looks: `<meter min max low high optimum value>` states a measurement whose bands judge it — `optimum` placement decides which band renders as good — while `<progress max value>` states completion and renders indeterminate without `value`. Native forms serve inline form-adjacent readouts; a bar whose fill must ride the palette is a `.meter` div driven by the `--value` custom property, carrying `role="meter"` with `aria-valuenow`, `aria-valuemin`, `aria-valuemax`, and a visible text twin — a fill alone is never a reading. `<output for="a b">` names the controls feeding its computation, and its implicit live semantics announce each recomputation.

## [04]-[TABLES]

The table is the artifact's densest surface; its markup does the aligning so the stylesheet only paints.

- `<caption>` names the question the table answers; a caption the layout already states rides `.sr-only` rather than vanishing.
- Header cells declare direction: `<th scope="col">` across the head row, `<th scope="row">` leading each body row, and a matrix corner cell stays an empty `<td>`.
- A wide table rides inside an `overflow-x: auto` wrapper so the page body never scrolls sideways; the wrapper, never the table, takes the border and radius.
- Numeric columns bind `td.num` — right-aligned, tabular, mono — and units live once in the header, never per cell.
- A sortable column puts a `<button type="button">` inside its `<th>`; the script mirrors sort state to `aria-sort` on exactly one header and clears the siblings.
- Every record row carries `data-id` matching its model row, so capture, selection, and diff address the row by the same key the payload uses.
- `<colgroup>` with spanned `<col>` elements tints a compared column as one rule instead of a per-cell class.
- A cell holds one atomic value; a cell that wants interior layout is a card row that outgrew its table.
- `<tfoot>` carries aggregates, and a filtered view recomputes them from the visible rows — a total that ignores the active filter lies.
- A long table sticks its `<thead>` inside the table's own scroll container, never against the page; a sparkline or trend mark embeds as an inline `<svg>` inside its `<td>`.
- Row groups are structural: one `<tbody>` per group with a group-header row spanning the columns, so collapse, zebra, and aggregate logic address the group as one node.

```html template
<div class="twrap">
    <table>
        <caption class="sr-only">
            Stage readiness by package
        </caption>
        <thead>
            <tr>
                <th scope="col" aria-sort="descending"><button type="button" data-sort="pkg">Package</button></th>
                <th scope="col" class="num">Coverage</th>
                <th scope="col">Status</th>
            </tr>
        </thead>
        <tbody>
            <tr data-id="pkg-a">
                <th scope="row">Loader</th>
                <td class="num">62</td>
                <td><span class="chip warn">[AT-RISK]</span></td>
            </tr>
        </tbody>
    </table>
</div>
```

## [05]-[DISCLOSURE_AND_OVERLAY]

Native disclosure and top-layer elements own open state, dismissal, focus, and stacking; script only reacts.

- `<details>` holds depth in place: `<summary>` stays a short claim with an optional trailing chip or count, and a shared `name` makes a sibling group mutually exclusive with zero script. Load-bearing conclusions render open at rest — disclosure deepens the argument, never gates it.
- `<dialog>` opened by `showModal()` makes the rest of the page inert automatically; `<form method="dialog">` with valued buttons returns the choice through `returnValue`, so a confirm flow carries no focus-trap plumbing. The least-destructive button carries `autofocus`, so Enter-through never destroys.
- `popovertarget` pairs a button to its `popover` panel and supplies open, light-dismiss, and `Esc` natively; a timed toast is a `popover="manual"` div carrying `role="status"`, shown and hidden by script alone — `<output>` stays bound to named inputs through `for`.
- Dialog and popover split by weight: a `<dialog>` blocks the page for a decision the flow requires; a popover floats context the reader dismisses at will. A blocking popover and a light-dismiss dialog are both the wrong element.
- The `toggle` event on a popover or `<details>` is the state seam the script listens on — open state reads from the event, never from a click handler inferring it.
- Nested popovers form one open chain: opening a child keeps its ancestor panels open, and light-dismiss unwinds from the top of the chain.
- An anchored panel declares `anchor-name` on its trigger and `position-anchor` + `position-area` on the panel, so the menu tethers to its button with zero placement script.
- The export drawer is a fixed tab button paired to a popover panel with a fixed interior order — send, disk egress, per-type fields, mirror:

```html template
<button class="drawer-tab" popovertarget="drawer">Export</button>
<aside id="drawer" class="export-bar" popover aria-label="Export">
    <header>
        <h2>Export</h2>
        <span class="micro" data-dirty></span>
    </header>
    <div data-send hidden><button class="btn primary" data-export="send">Send to agent</button></div>
    <div>
        <button class="btn" data-export="markdown">Copy markdown</button>
        <button class="btn" data-export="json">Download JSON</button>
        <button class="btn ghost" data-export="changed">Copy changed only</button>
    </div>
    <div data-drawer-fields></div>
    <textarea readonly aria-label="Outgoing payload"></textarea>
</aside>
```

## [06]-[COMPOSITES]

A composite widget is the one place `role` builds what HTML lacks; the markup carries the full state so the script only moves focus and flips attributes.

```html template
<div role="tablist" aria-label="Views" data-tabs>
    <button type="button" role="tab" id="tab-a" aria-selected="true" aria-controls="panel-a" data-tab="panel-a">Plan</button>
    <button type="button" role="tab" id="tab-b" aria-selected="false" tabindex="-1" aria-controls="panel-b" data-tab="panel-b">Risks</button>
</div>
<section role="tabpanel" id="panel-a" aria-labelledby="tab-a"></section>
<section role="tabpanel" id="panel-b" aria-labelledby="tab-b" hidden></section>
```

- The active tab holds `tabindex="0"` and `aria-selected="true"`; every other tab holds `-1` and `false`, so the tablist is one tab stop and arrow keys roll focus.
- A keyboard-traversed grid or list is one roving-tabindex composite: cells carry `data-cell` with exactly one at `tabindex="0"`, and the container carries `data-roving` for the delegated arrow-key handler.
- A drag surface pairs `draggable="true"` cards carrying `data-id` with `data-bucket` list containers and one reusable drop-marker element; the markup names the move (card id, target bucket) so the drop reduces to a model mutation.
- An annotation rail is an `<aside>` of note cards each carrying `data-for` naming its target's id, so the rail aligns notes to their anchors by data, never by hand-placed offsets.
- A step ribbon is an `<ol>` of step chips with `aria-current="step"` latching the active one — ordinal position only; a sequence with a time axis is a timeline, not a ribbon.
- A filter facet is a toggle `<button aria-pressed>`; a segmented choice is a radio fieldset — a composite never rebuilds what a form control already owns.
- `<a href>` navigates and `<button>` acts: an anchor with a click handler and no navigable target is a button wearing an anchor, and it breaks open-in-new-tab, focus semantics, and the status bar.
- Interactive elements never nest: a button inside a `<summary>` or a link inside a button splits the activation target; a chip or count inside a summary stays inert.

## [07]-[FORMS_AND_CAPTURE]

Native form semantics own every capture control, so keyboard order, grouping, and validation arrive without script.

- Every `input`, `select`, and `textarea` pairs with a `<label>` — wrapping or `for`-linked — and the field block orders label, control, then a `<small>` help line.
- A fixed choice set is a `<fieldset class="seg">` radio group: `<legend class="sr-only">` names it, one shared `name` binds it, one labeled `<input type="radio">` per option. A div wearing `role="radiogroup"` forfeits keyboard traversal and form participation.
- Distributed controls compose through the `form` attribute into one `<form id="capture-form">`, so a single `new FormData(captureForm)` reads every verdict and note on the page without selector harvesting.
- Constraint attributes — `required`, `min`, `max`, `maxlength`, `pattern` — carry validation; `:user-valid` and `:user-invalid` style only after the reader interacts, so a fresh form never opens red.
- Judgment fields carry `autocomplete="off"` — browser autofill has no business completing a verdict or an annotation — and `inputmode` with `enterkeyhint` tunes the virtual keyboard where a field expects numerals or a terminal action.
- A `<button>` inside any form declares `type="button"` unless it genuinely submits; the default type submits and reloads the page.
- A control either mutates a named field of the export model or renders as view-only chrome without capture styling — a control styled as capture that feeds nothing implies judgment returns when it does not.

## [08]-[DENSITY]

Density is semantic compression: fewer, richer elements each carrying a whole fact.

- A `<div>` exists only as a layout shell; every content node is a semantic element, so the renderer and the delegation script address meaning, never wrapper depth.
- The kv ledger — `<dl class="kv">` with mono `dt` labels and aligned `dd` values — replaces scattered `small` runs for owners, dates, ids, and counts.
- One fact, one node: a status is one chip, an identity one `data-id`, a metric one `.stat` block; markup never restates what a sibling node already carries.
- `<ul>` carries parallel atomic facts and `<ol>` carries claimed order; a one-item list is a paragraph wearing a bullet.
- `<time>` renders human text over an ISO `datetime` at the precision the estimate holds — a quarter-grade guess never renders day-precise.
- Repeated records hydrate by cloning `<template>` content into a fragment; markup strings never concatenate.
- Empty states are authored: a collection with zero visible rows renders its named empty message from the template, never a blank region.
- Section grammar is uniform: `<section class="section" id="...">` opens with its `<h2>` claim, and the section numeral arrives from the CSS counter, never typed into the heading text.
- Code evidence wraps as `<figure><pre><code>` with a `<figcaption>` naming the claim the excerpt proves; the excerpt earns its place only when the exact syntax is the evidence.
- `<pre>` is whitespace-verbatim: the code text opens flush against `<pre><code>` and the source indentation is the rendered indentation, so embedded snippets never inherit the surrounding markup's leading whitespace.
- Inline semantics finish the compression: `<code>` for symbols and paths, `<kbd>` for keystrokes, `<mark>` for search hits, `<time>` for instants, `<small>` for captions — each a hook the stylesheet and the delegation script address without extra classes.

The composed card shows the grammar at real scale — identity on the article, the header band, the kv ledger, disclosure holding the evidence:

```html template
<article class="card" data-id="st-2">
    <header class="rowline">
        <h3>Ingest loader collapse</h3>
        <span class="chip warn">[AT-RISK]</span>
        <time class="micro right" datetime="2026-07-20">Jul 20</time>
    </header>
    <dl class="kv">
        <dt>Owner</dt>
        <dd>runtime</dd>
        <dt>Gate</dt>
        <dd><code>bridge-verify</code></dd>
    </dl>
    <details>
        <summary>Evidence <span class="chip">3 rows</span></summary>
        <figure>
            <pre><code>loader.fold(rows)</code></pre>
            <figcaption>One entry point discriminates on input shape.</figcaption>
        </figure>
    </details>
</article>
```

## [09]-[ADMISSION]

Platform vocabulary lands by support band: plain vocabulary ships unguarded, guarded vocabulary enhances a complete fallback, and dead vocabulary never appears. The bands below are the admission registry.

[PLAIN] — shipped bare, each deleting the script it obsoletes:

| [INDEX] | [SURFACE]                                                | [DELETES]                                       |
| :-----: | :------------------------------------------------------- | :---------------------------------------------- |
|  [01]   | `popover`, `popovertarget`, `<dialog>`, `showModal()`    | overlay managers, scrim nodes, focus traps      |
|  [02]   | `<details name>`, `<search>`, `<output>`, `inert`        | accordion scripts, landmark retrofits           |
|  [03]   | `:has()`, `:user-valid`, `:user-invalid`                 | parent class toggles, touched-field state       |
|  [04]   | container size queries, `cqi`, subgrid                   | viewport-only breakpoints, equal-height scripts |
|  [05]   | CSS nesting, `@layer`, `@property`, `@scope`             | preprocessors, unlayered specificity fights     |
|  [06]   | OKLCH, `color-mix(in oklch, ...)`, relative color syntax | sRGB ladders, hand-derived hover colors         |
|  [07]   | `@starting-style`, `transition-behavior: allow-discrete` | JS enter and exit classes                       |
|  [08]   | `text-wrap: balance`, `clamp()`, `round()`               | line-break tuning, JS measurement constants     |
|  [09]   | `content-visibility: auto`                               | below-fold virtualization scripts               |
|  [10]   | anchor positioning — `anchor-name`, `position-area`      | popup placement math                            |
|  [11]   | `structuredClone`, `CompressionStream`, `Intl` formats   | hand-rolled clone, packing, and format code     |

[GUARDED] — the enhancement and its complete fallback ship together:

| [INDEX] | [SURFACE]                          | [GUARD]                                      | [FALLBACK]                 |
| :-----: | :--------------------------------- | :------------------------------------------- | :------------------------- |
|  [01]   | same-document view transitions     | `document.startViewTransition?.(cb) ?? cb()` | direct DOM update          |
|  [02]   | scroll-driven animations           | `@supports (animation-timeline: scroll())`   | static progress affordance |
|  [03]   | `::details-content` transition     | plain `[open]` state                         | instant disclosure         |
|  [04]   | `interpolate-size: allow-keywords` | fixed block-size fallback                    | instant size change        |
|  [05]   | `field-sizing: content`            | fixed control size                           | scrollable input           |
|  [06]   | invoker commands, `commandfor`     | listener or `popovertarget` twin             | existing route             |
|  [07]   | `hidden="until-found"`             | ordinary `<details>`                         | visible disclosure section |
|  [08]   | `linear()` spring easing           | cubic spring approximation                   | cubic easing               |
|  [09]   | `text-wrap: pretty`                | plain wrapping                               | standard line wrapping     |

[DEAD] — the self-containment contract makes these unspellable: ES modules, import maps, workers, service workers, runtime frameworks, runtime diagram libraries, webfonts, sibling-file `fetch`, `document.execCommand`, masonry layout, CSS `if()`, CSS `@function`, customizable `<select>` skinning beyond tokens.
