# [CODE]

Artifact code is a stamped shell plus one template-local model. Canonical regions carry shared mechanics; template code declares data, projects state, binds capture, and shapes the envelope. Styling owns cascade and tokens, state owns model truth, interaction owns control patterns, roundtrip owns receipts, and code owns executable shape, platform admission, and region boundaries.

## [01]-[STAMPED_REGIONS]

`studio.py` owns every stamped byte. A template composes the regions and appends only its local model, projections, capture bindings, and artifact-specific controls.

| [INDEX] | [REGION]            | [BYTE_OWNER]                    | [INSERTION]                     | [TEMPLATE_EDGE]              |
| :-----: | :------------------ | :------------------------------ | :------------------------------ | :--------------------------- |
|  [01]   | `NOCTURNE_BASELINE` | `scripts/nocturne/baseline.css` | first head `<style>` block      | local layered CSS follows    |
|  [02]   | `NOCTURNE_DRAWER`   | `scripts/nocturne/drawer.html`  | body end before payload data    | drawer fields append by data |
|  [03]   | `NOCTURNE_RUNTIME`  | `scripts/nocturne/runtime.js`   | first executable script segment | local script follows         |

- Region delimiters are the assembler contract; hand-edited bytes fail the region gate.
- One executable script contains exactly one stamped runtime kernel and one local script owner. `application/json` payload scripts are data blocks.
- The runtime kernel owns theme stamping, DOM and SVG factories, escaping, formatting, markdown cell safety, delegated event routing, debounced input, capture controls, copy, download, standalone SVG export, toast feedback, redaction, envelope validation, served send, fragment view state, scroll spy, print disclosure, and drawer boot.
- Template-local code calls `NOCTURNE.boot({ kind, envelope, toMarkdown, isChanged, onExported, narrative, redactPayload })` and supplies model-owned functions only.
- A composed one-off starts from a stamped shell; copied regions never become source truth.

## [02]-[PLATFORM_ADMISSION]

Platform vocabulary lands by support band. Plain vocabulary ships unguarded; guarded vocabulary enhances a complete fallback; dead vocabulary never appears in an artifact.

[PLAIN]:

| [INDEX] | [SURFACE]                                                | [DELETES]                                       |
| :-----: | :------------------------------------------------------- | :---------------------------------------------- |
|  [01]   | `popover`, `popovertarget`, `<dialog>`, `showModal()`    | overlay managers, scrim nodes, focus traps      |
|  [02]   | `<details name>`, `<search>`, `<output>`, `inert`        | accordion scripts, generic landmark retrofits   |
|  [03]   | `fieldset`, `legend`, labeled form-associated controls   | ARIA radio retrofits on generic containers      |
|  [04]   | `:has()`, `:user-valid`, `:user-invalid`                 | parent class toggles, touched-field state       |
|  [05]   | container size queries, `cqi`, subgrid                   | viewport-only breakpoints, equal-height scripts |
|  [06]   | CSS nesting, `@layer`, `@property`, `@scope`             | preprocessors, unlayered specificity fights     |
|  [07]   | OKLCH, `color-mix(in oklch, ...)`, relative color syntax | sRGB ladders, hand-derived hover colors         |
|  [08]   | `@starting-style`, `transition-behavior: allow-discrete` | JS enter and exit classes                       |
|  [09]   | `text-wrap: balance`, `clamp()`, `round()`               | `<br>` tuning, JS measurement constants         |
|  [10]   | `content-visibility: auto`                               | static below-fold virtualization scripts        |

[GUARDED]:

| [INDEX] | [SURFACE]                          | [GUARD]                                      | [FALLBACK]                 |
| :-----: | :--------------------------------- | :------------------------------------------- | :------------------------- |
|  [01]   | same-document view transitions     | `document.startViewTransition?.(cb) ?? cb()` | direct DOM update          |
|  [02]   | scroll-driven animations           | `@supports (animation-timeline: scroll())`   | static progress affordance |
|  [03]   | container style queries            | selector branch carries the same rule        | attribute selector branch  |
|  [04]   | `::details-content` transition     | plain `[open]` state                         | instant disclosure         |
|  [05]   | `interpolate-size: allow-keywords` | fixed block-size fallback                    | instant size change        |
|  [06]   | `field-sizing: content`            | fixed control size                           | scrollable input           |
|  [07]   | invoker commands, `commandfor`     | listener or `popovertarget` twin             | existing route             |
|  [08]   | `text-wrap: pretty`                | plain wrapping                               | standard line wrapping     |
|  [09]   | `linear()` spring easing           | `--ease-spring` cubic fallback               | cubic easing               |
|  [10]   | `hidden="until-found"`             | ordinary `<details>`                         | visible disclosure section |

[DEAD]: masonry `grid-lanes` `reading-flow` CSS `if()` CSS `@function` `<dialog closedby>` customizable `<select>` skinning beyond tokens `blocking="render"` ES modules import maps workers service workers runtime frameworks runtime diagram libraries webfonts `document.execCommand`.

## [03]-[TEMPLATE_GRAMMAR]

A template has one shell grammar.

1. `head` declares metadata, title, one `style`, the stamped `NOCTURNE_BASELINE`, and template-local CSS.
2. Template-local CSS appends only through `@layer tokens`, `@layer components`, `@layer utilities`, `@layer print`, and `@layer overrides`.
3. Baseline CSS owns repeated structure: masthead, split layout, compact command rows, note popovers, flow, rowline, mono text, horizontal scrolling, SVG fit utilities, and native capture scaffolding.
4. `body` orders content as skip link, artifact header, control band, layout shell, `main`, auxiliary native surfaces, stamped drawer, payload, runtime, and local script.
5. Auxiliary native surfaces are `template`, `dialog`, and `popover` nodes placed after `main` and before the drawer.
6. The payload script is the only embedded model source and uses `type="application/json"` with `id="payload"`.
7. The executable script starts with the stamped runtime and continues with one local IIFE.
8. The local IIFE orders blocks as `[MODELS]`, `[CONSTANTS]` when needed, `[OPERATIONS]`, and `[COMPOSITION]`.
9. `deck` owns the only alternate visible shell. It still follows the same payload, runtime, and local script grammar.

Native form semantics own every capture control. A segmented choice renders as `fieldset.seg` with `legend.sr-only`, one labeled `input` per option, one shared `name`, and `form="capture-form"` so distributed controls compose into one `FormData` read without selector harvesting. A note, verdict, score, status override, or drawer field either mutates the model and names its envelope contribution, or it renders as view-only chrome with no capture styling.

Template variation is row data. A new section, control, export field, table, card, slide, filter, or capture surface enters through a descriptor row and an existing renderer when that renderer already owns the shape.

## [04]-[EXECUTABLE_SHAPE]

The executable script audits top-down in owner order: stamped runtime, model declarations, pure operations, composition wiring.

[RUNTIME_OWNERS]:

| [INDEX] | [SURFACE]              | [OWNS]                                      |
| :-----: | :--------------------- | :------------------------------------------ |
|  [01]   | `NOCTURNE.payload()`   | payload parse                               |
|  [02]   | `NOCTURNE.index()`     | keyed row maps                              |
|  [03]   | `NOCTURNE.md`          | Markdown-safe text and tables               |
|  [04]   | `NOCTURNE.debounce()`  | delayed input commits                       |
|  [05]   | `NOCTURNE.delegate()`  | document-level event routing                |
|  [06]   | `NOCTURNE.capture()`   | verdict, note, annotation, exported state   |
|  [07]   | `NOCTURNE.svg()`       | SVG node construction                       |
|  [08]   | `NOCTURNE.exportSvg()` | standalone SVG serialization and token fill |
|  [09]   | `NOCTURNE.boot()`      | envelope egress and drawer lifecycle        |

- `[TYPES]` appears only for JSDoc typedefs. `[CONSTANTS]` appears only for dependency-free anchors independent of model data. `DATA`, `HELPERS`, `UTILS`, `FUNCTIONS`, and `WIRE` do not appear.
- Module-scope declarations are `const` except timers, drag cursors, RAF handles, and browser lifecycle cells. State itself is a `const` object mutated only through the artifact's named commit path.
- One state object, one render projection, one mutation lane per user action. A handler mutates state through the lane; it never reads final truth from DOM position or DOM text.
- A renderer writes with `replaceChildren`, `textContent`, attributes, dataset stamps, or custom properties. A scoped `paint*` function survives only for local SVG, meter, or readout patches whose model remains authoritative.
- Repeated markup hydrates through `NOCTURNE.el()` or `<template>` cloning. `innerHTML` is legal only for constant audited markup or a wrapper string whose dynamic fragments pass through `NOCTURNE.esc()`.
- Dynamic selector values pass through `CSS.escape`. Numbers, dates, percentages, and lists pass through `Intl` formatters. Snapshots pass through `structuredClone`.
- Template-local growth is valid when it is model rows, descriptor rows, or artifact-specific projections. A repeated mechanic graduates to `NOCTURNE` before a second template redefines it.

```js copy-safe
const capture = NOCTURNE.capture(state.captures);
const sync = () => {
  api.refresh();
  paintMeta();
};

NOCTURNE.delegate({
  change: [["[data-verdict-for]", hit => { capture.setVerdict(hit); sync(); }]],
  input: [["[data-note-for]", hit => { capture.setNote(hit); sync(); }]],
});
```

## [05]-[EGRESS_RESILIENCE]

Every egress path emits one validated envelope and reports the landing path.

- Ordered chain: served `POST` -> clipboard `writeText` -> readonly mirror. The mirror receives the exact payload before every attempted copy or send.
- Send failure routes the identical envelope into the clipboard path and leaves contributing annotations `active`.
- `redactPayload` runs before copy, download, or send for config, prompt, dataset, and credential-shaped content.
- `validateEnvelope` blocks malformed payloads visibly before egress.
- Changed-only export is disabled when no model diff exists; it never emits an empty payload.
- Export marks annotations `exported` only after a send or copy succeeds.
