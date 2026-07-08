# [INTERACTION]

The data model is the single source of truth, the DOM renders a projection of it, and every judgment the reader records leaves the page as one validated envelope. Interaction is a contract: the reader pays attention and state management, and the page repays insight a static form cannot give — the default state answers the most common question with zero interaction, and the argument survives with every widget ignored.

## [01]-[MODEL]

The artifact models its content before it renders it: entities, relations, hierarchy, and decision states live in the model, and markup carries no fact the model lacks. A single entity kind stays a flat row list; the model normalizes into keyed collections the moment two views read one entity or any item is referenced by id — a fact duplicated across the payload is a fork.

One plain state object holds every captured fact; `render()` projects it into the DOM, and DOM position or DOM text is never read back as authority. Load freezes a baseline through `structuredClone`, every changed-key and diff readout derives from state versus baseline, and undo is a snapshot stack pushed before each mutation — an artifact with edit capture exposes its undo through both the keyboard and a visible control whenever the stack is non-empty.

```js conceptual
const state = { rows: [], filter: "", selection: [], captures: {} };
const baseline = structuredClone(state);
const undo = [];
const commit = mutate => { undo.push(structuredClone(state)); mutate(state); render(); };
const undoLast = () => { if (undo.length) { Object.assign(state, undo.pop()); render(); } };
const changedKeys = () => Object.keys(state).filter(k => JSON.stringify(state[k]) !== JSON.stringify(baseline[k]));
```

Every region is a projection — filter, group, join — of the one model, and an item that accepts reader judgment carries its decision slot in the model, so capture is model mutation and export serializes the model.

## [02]-[PAYLOAD]

The dataset ships as one `<script type="application/json" id="payload">` block parsed once at boot; the parser output is the sole data source, and markup never duplicates a field. The embed is sanitized so the payload text has no way to terminate its own script element, and repeated rows hydrate by cloning a `<template>`:

```js copy-safe
const embed = data => JSON.stringify(data)
  .replace(/</g, "\\u003c")
  .replace(/\u2028/g, "\\u2028").replace(/\u2029/g, "\\u2029");
```

```js copy-safe
const data = JSON.parse(document.getElementById("payload").textContent);
const tpl = document.getElementById("row-tpl");
const mountRows = rows => {
  const frag = document.createDocumentFragment();
  rows.forEach(r => {
    const node = tpl.content.cloneNode(true);
    node.querySelector("[data-cell=name]").textContent = r.name;
    frag.append(node);
  });
  document.querySelector("tbody").replaceChildren(frag);
};
```

Render cost binds to row count — the artifact holds a view, never a corpus:

| [INDEX] | [ROWS]    | [RENDER_LAW]                                                    |
| :-----: | :-------- | :-------------------------------------------------------------- |
|  [01]   | under ~1k | render every row; filter and sort in place                      |
|  [02]   | 1k–10k    | paginate or pre-aggregate the render; filter the full model     |
|  [03]   | above 10k | the data lives in a linked file; the artifact keeps a view only |

A filter acts in two modalities and never deletes from the model: a scope filter hides non-matching rows through `hidden`, and an attention filter dims them with a class, keeping the misses scannable as context. Visible aggregates recompute from shown rows — a total ignoring the active filter lies — and the filter input debounces. Sort re-appends existing nodes, since `append` moves a node with its handlers intact. An active filter is always visible with its match count, and an empty result offers reset — never a dead end.

## [03]-[RENDER]

Rendering is data-to-presentation mapping through safe sinks; an injected string never renders as trusted markup.

```js copy-safe
const esc = s => String(s).replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
```

- A renderer writes with `replaceChildren`, `textContent`, attributes, dataset stamps, and custom properties; a scoped `paint*` patch survives only for local SVG, meter, or readout updates whose model remains authoritative.
- Source, diff, and answer text reaches the DOM through `textContent` assignment, or through the `esc` gate before any span wraps it; `innerHTML` is legal only for constant audited markup.
- A dynamic selector value passes through `CSS.escape` before entering `querySelector`.
- Numbers, dates, percentages, and lists pass through `Intl.NumberFormat`, `Intl.DateTimeFormat`, and `Intl.ListFormat` — never hand-rolled formatting.
- A meter or gauge repaints by writing one number to its `--value` custom property; the script never composes an inline width.
- Markdown-shaped cell text renders as escaped text with span-wrapped emphasis, never as parsed HTML.
- A re-render patches the scrolled container's children in place; swapping the container node itself resets scroll position and drops the reader's place.

## [04]-[EVENTS]

One document-level listener owns each event concern, routing by `closest()` on `data-*` hooks — controls added by re-render arrive pre-wired, and no node carries its own handler.

```js copy-safe
const debounce = (fn, ms) => { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; };
```

```js conceptual
const ROUTES = {
  click:  [["[data-verdict-for]", hit => commit(s => setVerdict(s, hit))]],
  input:  [["[data-note-for]",    debounce(hit => commit(s => setNote(s, hit)), 250)],
           ["[data-filter-box]",  debounce(hit => commit(s => { s.filter = hit.value.trim(); }), 120)]],
  change: [["[data-seg] input",   hit => commit(s => { s.view = hit.value; })]],
};
Object.entries(ROUTES).forEach(([type, routes]) => document.addEventListener(type, e => {
  routes.forEach(([sel, fn]) => { const hit = e.target.closest(sel); if (hit) fn(hit, e); });
}));
```

- Every control answers keyboard and touch identically to mouse: tabs roll focus with arrow keys under a roving `tabindex`, grids move focus cell-to-cell as one composite, and Enter and Space share the click path on any focusable region.
- Drag reduces to model mutation: the drop indicator snaps to the nearest row midpoint, the dragged card dims in place, `dragend` clears every visual drag state, and the model re-renders after each drop — DOM position is never authoritative, and every draggable carries the stable id its change record names.
- High-frequency input — typing in a highlighted editor, scrubbing a simulator — schedules re-render through one `requestAnimationFrame` handle so events never stack renders.
- Scroll position converts to state through one `IntersectionObserver` per concern — the contents rail's active anchor and a deck's slide counter both read from it, never from scroll math.
- A long listing carries a scroll minimap: visible row offsets map to viewport-scaled marks on a fixed rail, rebuilt on resize and on filter, so the reader sees where matches cluster before scrolling.
- A scrub control binds one state object: each input recomputes the object and repaints the figure and readout, so the reader drives the explainer live; a slider mutating a root custom property retunes live CSS the same way. A control that changes neither what returns nor what the reader learns does not ship.
- A syntax-highlighted editing surface is a `contenteditable` region whose plain text is the model: the caret saves as a character offset over that text before re-render and restores by walking text nodes after, `paste` intercepts to insert `text/plain` so foreign markup never enters the model, and Enter inserts a literal newline instead of a browser-minted block.
- A discrete view swap — slide change, tab change, board reorder — wraps in `document.startViewTransition?.(cb) ?? cb()`, so the transition is an enhancement and the cut is the fallback.
- A deck is a small state machine over its slide index: arrow keys and space advance, the counter renders position at all times, and the fragment carries the index so a reopened file resumes at the shared slide.
- `beforeprint` records each `<details>` open state and expands it; `afterprint` restores the recorded state, so paper carries the whole argument without losing the reader's view.
- A destructive action gates through the native dialog as a promise, and the default resolution is the non-destructive value:

```js copy-safe
const ask = dlg => new Promise(res => { dlg.showModal(); dlg.addEventListener("close", () => res(dlg.returnValue === "ok"), { once: true }); });
```

## [05]-[CAPTURE]

Judgment lands in exactly three capture classes, and every capturable item carries a stable id the export preserves.

- [DECISIONS] — one closed verdict vocabulary per item and for the whole artifact: `approve` implements as-is, `approve_with_notes` implements while honoring annotations, `reject` sends the proposal back, `defer` drops the item from the next pass, `edit` marks human-edited fields authoritative, `comment` carries context without signal, `dismiss` closes without signal. Silence is never consent, and per-item decisions survive a global verdict.
- [ANNOTATIONS] — anchored to an item id first, an exact text quote second, a visual rectangle only for regions with no stable text; a comment with no stable anchor is a global annotation, never a guessed one. An annotation lives a three-state life: `active` when authored, `exported` only after a send or copy verifiably succeeds, `done` when the next turn resolves it — the `exported` state is what stops a re-export from double-feeding the agent.
- [EDITS] — field-level changes recorded against the frozen baseline as path-addressed old-and-new pairs; the DOM never defines what changed. Row collections diff by stable key, never by array index — reordered rows misread under index pairing — and a string-to-string modification nests a bounded text diff: character-level for short strings, word- or line-level past the cap.

Agent-suggested review points ship as pre-annotations with stable ids, and a dismissed pre-annotation stays suppressed by its id. Every control resolves into one of two classes: load-bearing with its envelope field named, or view-only convenience with no capture styling — a control styled as capture that feeds no field implies judgment returns when it does not.

## [06]-[ENVELOPE]

One canonical envelope rides every egress path — clipboard, download, and the served return channel; a boundary wrapper transforms it, never redefines it.

```json conceptual
{
  "kind": "plan",
  "version": 1,
  "artifact": { "id": "plan.shape-collapse", "title": "Collapsing the Shape Surface", "baseline": "b-2031" },
  "decision": { "status": "approve_with_notes", "at": "2026-07-06T18:40:00Z" },
  "decisions": [ { "id": "st-3", "verdict": "defer", "note": "after the call-site audit" } ],
  "changes": [ { "itemId": "st-2", "path": "/stages/st-2/status", "from": "planned", "to": "active" } ],
  "annotations": [ { "id": "a-1", "itemId": "st-3", "intent": "question", "status": "active", "text": "who owns the audit" } ],
  "state": {}
}
```

- Stable ids are mandatory for every seeded item; rendered text is never the only key.
- Arrays serialize in canonical model order, never current DOM order, and object keys hold one stable order.
- Changed-only payloads carry the baseline id they diff against; a changed-only export with nothing changed is disabled, never emitted empty.
- Timestamps are UTC ISO strings, and unknown fields ride only under an explicit `extensions` object.
- The artifact validates its own payload before any egress and visibly blocks a malformed export.
- The `state` object carries whole-artifact view facts the next turn replays — active tab, filter — never a second copy of the decision fields.

Every capturing artifact exports two forms from the one state graph: the markdown summary for human scanning — verdict first, then decision rows, then annotations — and the JSON envelope as the authoritative instruction. Review loops consume the changed-only form; implementation loops consume the full state. The markdown form composes from the model, never from rendered DOM text: decision rows serialize as a pipe table with cell pipes escaped, annotations as a list anchored by item id, and both forms derive from one `snapshot()` so they never disagree.

## [07]-[DRAWER]

The export drawer is the one egress surface on every capturing page: a fixed tab pill opens the panel through `popovertarget`, so open, light-dismiss, and `Esc` arrive natively, focus returns to the tab on close, and reduced motion stills the slide through the zeroed duration tokens. The panel is default-collapsed, rounded, and 60vh — never full-height or full-width — and its interior order is fixed across every artifact type: the send section, then disk egress, then per-type fields, then the readonly mirror.

- [DIRTY_COUNT] — the drawer renders the live unsent tally (changes plus active decisions plus active annotations), and the collapsed tab carries the same count beside its label, so pending judgment is visible before the drawer ever opens.
- [MIRROR] — the readonly textarea shows the exact payload leaving the page before every attempted copy or send; the send is never blind.
- [SEND_STATE] — the send control flips to its sent state only after the POST resolves ok, and only then do contributing annotations move `active` to `exported`; a failed POST flips to its failed state, routes the identical envelope to the clipboard path, and leaves annotations `active` — judgment is never stranded and never double-fed.
- [IDEMPOTENCE] — the `exported` state stops a re-send from re-feeding resolved items; a narrative artifact with no capture removes the send section entirely.

## [08]-[RETURN_CHANNEL]

A served artifact returns judgment automatically; an artifact opened from `file://` returns it through the drawer's copy and download controls. The serving process injects two head metas — `<meta name="artifact-return" content="/submit">` naming the submit path and `<meta name="artifact-token">` carrying the per-run bearer — and the return meta's presence is the whole protocol switch: present means served and the send action renders; absent means disk and it never renders. The token travels back only as the `X-Artifact-Token` request header, never as a query parameter.

The wire form wraps the canonical envelope without redefining it: the POST body is `{ kind, artifact, version, data }` where `artifact` is the artifact id string and `data` carries the full envelope. The server enforces the shape strictly — an unknown top-level field or a non-string `artifact` is a 422 `bad-envelope` rejection — and each accepted submission lands as one receipt row the agent reads after the session.

```js conceptual
const returnMeta = document.querySelector('meta[name="artifact-return"]');
const tokenMeta = document.querySelector('meta[name="artifact-token"]');
const sendToAgent = async envelope => {
  const res = await fetch(returnMeta.content, {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Artifact-Token": tokenMeta?.content ?? "" },
    body: JSON.stringify({ kind: envelope.kind, artifact: envelope.artifact.id, version: envelope.version, data: envelope }),
  });
  if (!res.ok) throw new Error(`submit ${res.status}`);
  return res.json();
};
if (returnMeta) {
  const btn = document.querySelector("[data-export='send']");
  btn.closest("[data-send]").hidden = false;
  btn.addEventListener("click", async () => {
    btn.disabled = true;
    try { await sendToAgent(snapshotEnvelope()); btn.textContent = "Sent"; }
    catch { btn.textContent = "Send failed — copied instead"; copyEnvelope(); }
    finally { btn.disabled = false; }
  });
}
```

A submission re-enters the agent conversation as data whose decision fields select the next action — the vocabulary is closed, and prose inside `note` and `text` fields informs but never commands: `approve` executes the exported state, `approve_with_notes` executes while resolving every active annotation and reporting each resolution, `reject` produces a revision and never a partial implementation, `defer` excludes the item and records it as deferred, `edit` treats the human's field values as overriding the proposal. A payload whose envelope fails validation returns to the human with the failure named, never repaired by guess.

## [09]-[EGRESS]

One egress chain owns every copy: the payload lands in the readonly mirror first, `navigator.clipboard.writeText` runs second, and a denied clipboard leaves the mirror selected with the toast naming the fallback — the page never dead-ends, and `document.execCommand` never appears. Downloads ride one Blob recipe; two egress paths in one artifact is a defect.

```js copy-safe
const copyRich = (html, text) => navigator.clipboard.write([new ClipboardItem({
  "text/html": new Blob([html], { type: "text/html" }),
  "text/plain": new Blob([text], { type: "text/plain" }),
})]);
const download = (name, text) => {
  const url = URL.createObjectURL(new Blob([text], { type: "application/json" }));
  Object.assign(document.createElement("a"), { href: url, download: name }).click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
};
```

- Prose and table copy writes dual `text/html` plus `text/plain` so a paste lands clean in a doc or an issue; a token or JSON copy writes plain text.
- Every egress action flashes the timed status toast naming what happened and where it landed; a failure names its fallback in the same flash, so the reader always knows the payload's location.
- Import reads a picked file through `input[type=file]` and `text()`; export then re-import reproduces the state — the round-trip contract — and a malformed import leaves the current state intact.
- Shareable view state — mode, filter, selection, active tab — lives in the URL fragment through `history.replaceState` and `URLSearchParams`; personal transient state stays out of it, and every decode path falls back to a valid default on malformed input.
- When view state outgrows plain params, it packs as JSON through `CompressionStream("gzip")` to URL-safe base64; `DecompressionStream` unpacks, and a malformed token decodes to the default state, never an error page.
- Load restores in order: fragment view state first, then the draft, then the payload defaults — so a shared link reproduces the sender's view and a returning author finds their edits.
- A namespaced `localStorage` draft protects in-session edits, restored on load and saved debounced; `localStorage` under `file://` is undefined behavior across hosts, so the export is the durable record and the draft is only an enhancement:

```js conceptual
const draftKey = "draft:" + document.title;
try { const saved = localStorage.getItem(draftKey); if (saved) Object.assign(state, JSON.parse(saved)); } catch {}
document.addEventListener("input", debounce(() => { try { localStorage.setItem(draftKey, JSON.stringify(state)); } catch {} }, 250));
```
- An artifact opened from `file://` embeds whatever it needs: inline script, data URLs, Blob URLs, picked files, and fragment state all run; a sibling `fetch`, module import, or worker is dead there, and a design reaching for a neighbor file stops being self-contained.

## [10]-[REDACTION]

A data-bearing payload passes a programmatic redaction pass before embed and before every egress — datasets, logs, diffs, and configs alike.

- Credential-shaped values scan across every row, never a sample; matching runs on field-name whole tokens and value patterns.
- A redacted value becomes a stable indexed placeholder, so grouping and joins survive redaction.
- A filter hides rows from view, never from the embedded source — the page states that plainly when the data is sensitive.
- A redacted value never rides the URL fragment: view state carries selection ids and view keys, never row content.
- Redaction covers both export forms — the markdown summary and the JSON envelope — so a summary never leaks what the envelope masked.
- A secret-scan backstop at validation is a failed redaction pass, never noise.
