---
name: html-studio
description: >-
    Authors single-file interactive HTML artifacts — reports, dashboards, roadmaps, plans,
    decision docs, and variants: diff-reviews, quizzes, wargames, decks, boards, walkthroughs,
    prototypes — validated headless and optionally served so reader verdicts, edits, and
    annotations return as data. Use when a comparison, dataset, architecture, or UI mock
    reads better as a page than markdown, when a page must return the reader's judgment,
    or on "make this an HTML page", "build me a dashboard", "turn this into a deck".
---

# [HTML_STUDIO]

Every artifact is one self-contained file: a deliverable type fixes its composition — layout class, structural spine, element set, capture contract — and the references rule the code, style, figures, and interaction it composes from.

## [01]-[ROUTING]

[REFERENCES]:
- [01]-[DELIVERABLES](references/deliverables.md): registers each type — spine, layout class, element set, capture contract, variant-to-core table
- [02]-[HTML](references/html.md): advanced HTML — semantic structure, density, and the coding patterns every artifact composes from.
- [03]-[SVG](references/svg.md): advanced inline SVG for HTML — the element vocabulary, construction patterns, and figure and diagram craft.
- [04]-[STYLE](references/style.md): rules the design language — token system, layout, theming, and the legibility law every artifact inherits
- [05]-[INTERACTION](references/interaction.md): rules the return channel — data-to-presentation mapping, the drawer, adjustments returned as data

## [02]-[BUILD]

1. Load the references.
2. Select the deliverable type by the reader's first question; it fixes measure, spine, envelope, and drawer. A two-type page splits or subordinates.
3. Model content before rendering: the payload block carries every fact and stable ids on each capturable item; markup states nothing the model lacks.
4. Compose answer-first down the spine: real controls, data rows, and rendered rivals inherit the token registry, never prose over an unbuilt surface.
5. Run `uv run ${CLAUDE_SKILL_DIR}/scripts/studio.py gate <file.html>` until clean: self-containment, accessibility, style doctrine, W3C markup.
6. `render <file.html>` returns a headless screenshot and the console through the machine's pinned Chromium; `--help` lists every verb.
7. An artifact whose value is the user's judgment runs served: `serve <file.html>` hosts the return channel, `receipts <file.html>` reads submissions.

## [03]-[CONTRACT]

- One file: `<!doctype html>`, one `<title>`, all CSS in one `<style>`, one executable `<script>`, optional inert `application/json` payloads.
- Zero external references — no CDN, webfont, or remote image; only in-page anchors, `data:` URIs, sibling-artifact links, and injected return metas.
- Dark and light both render; wide content scrolls inside its own container and the body never scrolls sideways.
- Injected source, diff, and answer text reaches the DOM through escaping before any span wraps it; embedded JSON payloads are sanitized on embed.

## [04]-[INTEGRATION]

- A durable artifact homes at `docs/atlas/` as `<kind>.<scope>[.<slug>].html`; a session artifact stays in scratch and never commits.
- Chart form, mark, and palette selection precedes realization; this bundle owns the page shell and the SVG once the form is chosen.
- Mermaid fences defer to `mermaid-diagramming`, whose render lane delivers a mermaid-sourced figure as pre-rendered inline SVG the page hosts.
