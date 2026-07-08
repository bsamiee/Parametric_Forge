# [INTERACTION]

Each pattern drops into the one executable script and one style block and earns its place only by the reader question it answers. One document-level listener owns each concern, native primitives own every overlay and disclosure the platform ships, and every injected string escapes through `textContent` before a span wraps it.

## [01]-[FOUNDATION]

The theme stamp, the escape gate, and the control floor ride every artifact.

[CONTROL_FLOOR]:

The NOCTURNE floor owns the full control grammar — rest affordance, hover, `:active`, `:focus-visible` double ring, pressed state, disabled state — so a template never authors a private hover or drops a state. Composition is by class alone: the one action that commits the page's purpose is `.btn.primary`; peers are `.btn`; quiet inline actions are `.btn.ghost`; a latched control carries `aria-pressed="true"` and reads visually distinct from hover. Every control answers touch and keyboard identically to mouse, and hover-revealed content is never load-bearing — touch and print receive the default state.

[RUNTIME_KERNEL]:

The stamped `NOCTURNE_RUNTIME` region ships the cross-template runtime — the theme controller, `el()` and `clone()` factories, `esc()`, the copy chain, `download()`, `flash()`, `redact()`, the envelope validator and send, the export wire, the scroll spy, fragment view state, and print disclosure expansion — as the `NOCTURNE` namespace the template-local script composes. `NOCTURNE.boot({kind, envelope, toMarkdown, isChanged, onExported, narrative, redactPayload})` wires the drawer, theme, spy, and print hooks in one call; a template re-authoring any kernel concern forks the grammar and is a defect per [code.md](code.md).

[ESCAPE_RENDER]:

Source, diff, and answer text reaches the DOM escaped — `textContent` assignment or the kernel `esc()` for span-wrapped fragments — and a dynamic selector value passes through `CSS.escape` before it enters `querySelector`; an injected string never renders as trusted HTML.

## [02]-[EGRESS]

Egress moves state out of the page: the export drawer is the durable rail, the one clipboard recipe carries every copy, and a draft is never the record.

[EXPORT_DRAWER]:

One paradigm on every page: a fixed `.drawer-tab` pill anchored to the bottom-right corner opens the `.export-bar` panel through `popovertarget` — `popover="auto"` supplies open, light-dismiss, and `Esc` natively, focus returns to the tab on close, and reduced motion stills the slide through the zeroed duration tokens. The drawer is default-collapsed; open, it is a rounded `--raised` panel at 60vh, never full-height or full-width. Interior order is fixed across every type: the send section, then disk egress, then per-type fields. The markup is the stamped `NOCTURNE_DRAWER` region — send button, copy-markdown, download-JSON, copy-changed-only, meta line, readonly mirror — and per-type controls append into `[data-drawer-fields]` at render time; `boot()` removes the send section on a narrative type and the changed-only control when no `isChanged` is supplied.

[COPY_CHAIN]:

One egress chain owns every copy, spelled once in the kernel: the payload lands in the readonly mirror first, `navigator.clipboard.writeText` runs second, and a denied clipboard leaves the mirror selected with the toast naming the fallback — the page never dead-ends and never touches `execCommand`. Downloads ride the kernel `download()` Blob recipe. Two egress paths in one artifact is a defect.

[DRAFT_PERSIST]:

A namespaced `localStorage` draft protects in-session edits, restored on load and saved debounced; a `file://` origin withholds storage in some hosts, so the export is the durable record, never the draft.

```js conceptual
const draftKey = "draft:" + themeKey.slice(6);
try { const s = localStorage.getItem(draftKey); if (s) writeState(JSON.parse(s)); } catch {}
let saveTimer;
document.addEventListener("input", () => { clearTimeout(saveTimer); saveTimer = setTimeout(() => { try { localStorage.setItem(draftKey, JSON.stringify(readState())); } catch {} }, 250); });
```

## [03]-[OVERLAYS]

The top layer owns every transient surface; the browser owns dismiss, focus, and stacking.

[POPOVER_ANCHOR]:

Menus, tooltips, inspector panels, and toasts ride the top layer as a native `popover`; an anchored panel tethers to its trigger by anchor positioning while a `popover="manual"` toast a timer auto-hides carries copy and save feedback. Entry animates from `@starting-style` with `display` flipped discretely.

```html copy-safe
<button popovertarget="acts" class="btn ghost" aria-label="Actions">&#8943;</button><menu id="acts" popover class="pop"></menu>
<output id="toast" popover="manual" role="status" aria-live="polite"></output>
```

```css copy-safe
[popovertarget="acts"] { anchor-name: --acts }
.pop { position: absolute; position-anchor: --acts; position-area: block-end span-inline-end; margin: var(--s2) 0 0; padding: var(--s3); transform: translateY(-.25rem) }
#toast { position: fixed; inset: auto var(--s4) var(--s4) auto; margin: 0; padding: var(--s2) var(--s3); border-radius: var(--r-1) }
.pop, #toast { border: 1px solid var(--line-strong); border-radius: var(--r-2); background: var(--raised-2); box-shadow: var(--shadow-2); opacity: 0; transition: opacity var(--dur-2) var(--ease-out), transform var(--dur-2) var(--ease-out), display var(--dur-2) allow-discrete }
.pop:popover-open, #toast:popover-open { opacity: 1; transform: translateY(0) }
@starting-style { .pop:popover-open, #toast:popover-open { opacity: 0 } }
```

```js copy-safe
let toastTimer;
const flash = msg => { toast.textContent = msg; toast.showPopover(); clearTimeout(toastTimer); toastTimer = setTimeout(() => toast.hidePopover(), 1600); };
```

[DIALOG]:

A confirm or destructive-choice flow is a native `<dialog>`; `showModal()` makes the page inert, `form method="dialog"` closes on the chosen `value`, and `returnValue` carries the decision back with no focus-trap plumbing.

```html copy-safe
<dialog id="confirm"><form method="dialog">
  <p>Discard the draft?</p>
  <button value="cancel" class="btn">Keep</button><button value="ok" class="btn primary">Discard</button>
</form></dialog>
```

```js conceptual
const ask = dlg => new Promise(res => { dlg.showModal(); dlg.addEventListener("close", () => res(dlg.returnValue === "ok"), { once: true }); });
```

## [04]-[DISCLOSURE]

Disclosure keeps the spine short while depth loads in place.

[COLLAPSIBLE]:

Plan sections, source snippets, and glossary entries are native `<details>`; a shared `name` makes a group mutually exclusive with no accordion script, `::details-content` animates the open box, and `:has(> details[open])` lifts the owning section. Print expands every disclosure.

```css copy-safe
details { border: 1px solid var(--line); border-radius: var(--r-2); padding: var(--s3); margin: var(--s3) 0; background: var(--raised) }
details::details-content { opacity: 0; content-visibility: hidden; transition: opacity var(--dur-2) var(--ease-out), content-visibility var(--dur-2) allow-discrete }
details[open]::details-content { opacity: 1; content-visibility: visible }
.section:has(> details[open]) { border-color: var(--accent) }
```

```js copy-safe
addEventListener("beforeprint", () => document.querySelectorAll("details").forEach(d => { d.dataset.wasOpen = d.open; d.open = true; }));
addEventListener("afterprint", () => document.querySelectorAll("details").forEach(d => { d.open = d.dataset.wasOpen === "true"; }));
```

[TABS]:

A tablist wires `role=tab`/`tablist`/`tabpanel`; the active tab holds `tabindex=0` and the rest `-1`, arrow keys roll focus, and one delegated listener drives selection and panel visibility.

```js copy-safe
const activate = (group, tab) => {
  group.querySelectorAll("[data-tab]").forEach(b => { const on = b === tab; b.setAttribute("aria-selected", on); b.tabIndex = on ? 0 : -1; });
  document.querySelectorAll("[data-panel]").forEach(p => { p.hidden = p.id !== tab.dataset.tab; });
};
document.addEventListener("click", e => { const t = e.target.closest("[data-tab]"); if (t) activate(t.closest("[data-tabs]"), t); });
document.addEventListener("keydown", e => {
  const t = e.target.closest("[data-tab]"), step = { ArrowRight: 1, ArrowLeft: -1 }[e.key]; if (!t || !step) return;
  const tabs = [...t.closest("[data-tabs]").querySelectorAll("[data-tab]")], n = tabs[(tabs.indexOf(t) + step + tabs.length) % tabs.length];
  n.focus(); activate(t.closest("[data-tabs]"), n);
});
```

[SEGMENTED]:

A fixed choice set is a radio group styled as a segmented control; `:has(input:checked)` carries the selected state with zero script, and the checked segment reads as latched, never as hovered.

```css copy-safe
.seg { display: inline-flex; border: 1px solid var(--line-strong); border-radius: var(--r-1); overflow: hidden }
.seg label { padding: var(--s1) var(--s3); font-size: var(--fs-sm); font-weight: 500; cursor: pointer }
.seg label:has(input:checked) { background: var(--accent-weak); box-shadow: inset 0 0 0 1px var(--accent); font-weight: 600 }
.seg input { position: absolute; opacity: 0; pointer-events: none }
```

## [05]-[COLLECTIONS]

Collection patterns narrow, reorder, and traverse repeated records; the model stays the source and the DOM follows.

[FILTER]:

A live query narrows any `[data-filter]` collection inside a `<search>` landmark; filtering dims or hides the misses from view, never from the model or the export.

```js copy-safe
document.addEventListener("input", e => {
  const box = e.target.closest("[data-filter-box]"); if (!box) return;
  const q = box.value.trim().toLowerCase();
  document.querySelectorAll("[data-filter]").forEach(el => { el.hidden = q !== "" && !el.textContent.toLowerCase().includes(q); });
});
```

[DRAG_BOARD]:

Work items drag across buckets with move state reduced to card id plus target bucket; a drop indicator snaps to the nearest row midpoint, the dragged card stays in place at reduced opacity with a slight tilt, and `dragend` clears every visual drag state. The model re-renders after each drop — DOM position is never authoritative.

```js conceptual
let dragId = null, marker = document.getElementById("drop-marker");
document.addEventListener("dragstart", e => { const c = e.target.closest("[data-id]"); if (!c) return; dragId = c.dataset.id; c.classList.add("dragging"); });
document.addEventListener("dragover", e => {
  const b = e.target.closest("[data-bucket]"); if (!b) return; e.preventDefault();
  const rows = [...b.querySelectorAll("[data-id]:not(.dragging)")];
  const before = rows.find(r => e.clientY < r.getBoundingClientRect().top + r.offsetHeight / 2);
  (before ?? b).insertAdjacentElement(before ? "beforebegin" : "beforeend", marker);
});
document.addEventListener("drop", e => {
  const b = e.target.closest("[data-bucket]"); if (!b) return;
  moveCard(dragId, b.dataset.bucket, [...b.children].indexOf(marker)); render();
});
document.addEventListener("dragend", () => { dragId = null; marker.remove(); document.querySelectorAll(".dragging").forEach(c => c.classList.remove("dragging")); });
```

```css copy-safe
.dragging { opacity: .5; rotate: 2deg }
#drop-marker { block-size: 2px; background: var(--accent); border-radius: var(--r-full) }
```

[KEYBOARD_NAV]:

A skip link jumps to `#main`; a grid or list is one roving-tabindex composite, so arrow keys move focus across cells while the collection holds a single tab stop.

```js copy-safe
document.addEventListener("keydown", e => {
  const cell = e.target.closest("[data-cell]"), step = { ArrowRight: 1, ArrowLeft: -1, ArrowDown: 1, ArrowUp: -1 }[e.key]; if (!cell || !step) return;
  const cells = [...cell.closest("[data-roving]").querySelectorAll("[data-cell]")], n = cells[Math.max(0, Math.min(cells.length - 1, cells.indexOf(cell) + step))];
  cells.forEach(c => { c.tabIndex = -1; }); n.tabIndex = 0; n.focus(); e.preventDefault();
});
```

## [06]-[OBSERVATION]

One `IntersectionObserver` per concern converts scroll position into state: the TOC's active anchor and a deck's slide counter both read from it, never from scroll math.

```js copy-safe
const tocFor = id => document.querySelector(`.toc a[href="#${CSS.escape(id)}"]`);
const spy = new IntersectionObserver(entries => {
  entries.forEach(en => { if (en.isIntersecting) { document.querySelectorAll(".toc a.on").forEach(a => a.classList.remove("on")); tocFor(en.target.id)?.classList.add("on"); } });
}, { rootMargin: "-20% 0px -70% 0px" });
document.querySelectorAll("main [id]").forEach(s => spy.observe(s));
```

## [07]-[EDITOR]

A syntax-highlighted editing surface is a `contenteditable` region whose plain text is the model; the DOM is a rendering the script rebuilds.

- [CARET_KEPT]: the caret is saved as a character offset over the region's plain text before re-render and restored by walking text nodes after — highlighting spans never move the caret.
- [PLAIN_PASTE]: `paste` is intercepted, `text/plain` inserted, so foreign HTML never enters the model; Enter inserts a literal newline instead of a browser-minted block.
- [RAF_THROTTLE]: input re-render schedules through one `requestAnimationFrame` handle, so typing never stacks renders.

```js conceptual
const insertText = text => {
  const sel = getSelection();
  if (!sel?.rangeCount) return;
  const range = sel.getRangeAt(0);
  range.deleteContents();
  range.insertNode(document.createTextNode(text));
  range.collapse(false);
  sel.removeAllRanges();
  sel.addRange(range);
};
editor.addEventListener("paste", e => { e.preventDefault(); insertText(e.clipboardData.getData("text/plain")); });
let raf = 0;
editor.addEventListener("input", () => { cancelAnimationFrame(raf); raf = requestAnimationFrame(() => refresh({ preserveCaret: true })); });
```

## [08]-[REVIEW]

The patch renders as a preserved line stream beside a sticky annotation rail; a two-column grid keeps code and critique synchronized, and each line escapes before it renders. An editor freezes a `structuredClone` baseline at load and derives every change against it.

```css copy-safe
.review { display: grid; grid-template-columns: minmax(0,1fr) 280px; gap: var(--s5) }
.line { display: block; white-space: pre-wrap; font-family: var(--font-mono); font-size: var(--fs-xs) }
.added { background: color-mix(in oklch, var(--ok) 14%, transparent) }
.removed { background: color-mix(in oklch, var(--fail) 14%, transparent) }
```

```js conceptual
const renderDiff = parts => parts.map(p => `<span class="line ${p.type === "add" ? "added" : p.type === "remove" ? "removed" : "same"}">${esc(p.text)}</span>`).join("");
const baseline = structuredClone(readState());
const changedKeys = () => { const now = readState(); return Object.keys(now).filter(k => now[k] !== baseline[k]); };
```

## [09]-[NARRATIVE]

Narrative patterns walk a reader through an argument and keep position shareable.

[DECK]:

A small state machine over `<section class="slide">` holds one active slide; arrow keys and space advance, the counter reads from the observer, and `startViewTransition` wraps the swap as a guarded enhancement that degrades to an instant cut.

```js conceptual
const slides = [...document.querySelectorAll(".slide")], swap = document.startViewTransition ? cb => document.startViewTransition(cb) : cb => cb();
let index = 0;
const paint = () => { slides.forEach((s, i) => s.classList.toggle("active", i === index)); counter.textContent = `${index + 1} / ${slides.length}`; };
const show = next => { const c = Math.max(0, Math.min(slides.length - 1, next)); if (c !== index) { index = c; swap(paint); } };
addEventListener("keydown", e => { const d = { ArrowRight: 1, ArrowDown: 1, " ": 1, ArrowLeft: -1, ArrowUp: -1 }[e.key]; if (d) { e.preventDefault(); show(index + d); } });
paint();
```

[SCRUB_CONTROL]:

A slider or segmented control binds to one state object; each input recomputes the object and repaints the SVG figure and metric readout, so the reader drives the explainer live. A slider mutating a root custom property retunes live CSS the same way.

```js copy-safe
const scrub = { load: 40 };
const paintFig = () => { document.querySelector("[data-bar]").setAttribute("width", scrub.load); document.querySelector("[data-readout]").textContent = `${scrub.load}%`; };
document.addEventListener("input", e => {
  const c = e.target.closest("[data-scrub]"); if (!c) return;
  scrub[c.dataset.scrub] = Number(c.value);
  if (c.dataset.prop) document.documentElement.style.setProperty(c.dataset.prop, c.value + (c.dataset.unit ?? ""));
  paintFig();
});
paintFig();
```

[DEEP_LINK]:

On load the page scrolls to the hash target; `URLSearchParams` packed onto the fragment carries selected tab, lane, filter, and theme, so a reopened file restores its view with no storage.

```js copy-safe
const params = () => new URLSearchParams(location.hash.slice(1));
const writeView = patch => { const p = params(); for (const [k, v] of Object.entries(patch)) p.set(k, v); history.replaceState(null, "", "#" + p); };
const restore = () => { const id = params().get("at"); if (id) document.getElementById(id)?.scrollIntoView(); };
addEventListener("hashchange", restore); restore();
```
