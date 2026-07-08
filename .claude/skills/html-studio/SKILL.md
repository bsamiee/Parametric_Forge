---
name: html-studio
description: Author single-file, self-contained interactive HTML artifacts — plans, roadmaps, dashboards, decks, diff-reviews, wargames, editors, reports, capability atlases, figure sheets — composed from world-class templates and element examples under one design system, then validated headless. Use when a plan, roadmap, comparison, decision, dataset, or architecture reads better as an interactive page than markdown, when a page should return the user's adjustments as data, or when the user says HTML plan, roadmap, dashboard, deck, wargame, quiz, or report. Distinct from the Artifact tool's hosted fragments; mermaid fences belong to mermaid-diagramming.
allowed-tools:
  - Bash(uv run ${CLAUDE_SKILL_DIR}/scripts/studio.py *)
---

# [HTML_STUDIO]

Every artifact is one self-contained file: a template carries the design system and base structure, element examples are its parts, and the references rule the code, style, and interaction.

## [01]-[BUILD]

1. Load the four references.
2. Select a template by the artifact's intent. A template carries the design system, base structure, and a starting element set as agnostic placeholders — never real content.
3. Add elements as the content demands; each drops into the template's structure and inherits its tokens.
4. Compose answer-first: replace every placeholder with real content, coded and styled to the references, rendering the thing itself — real controls, real data rows — never prose describing an unbuilt surface.
5. Validate the finalized artifact with `uv run ${CLAUDE_SKILL_DIR}/scripts/studio.py` and fix until clean: `gate <file.html>` checks self-containment, accessibility, style-doctrine conformance, and W3C markup; `render <file.html>` returns a headless screenshot and the console through the machine's pinned Chromium. `--help` lists every verb.
6. An artifact whose value is the user's judgment runs served, not just opened: `serve <file.html>` hosts it with the return channel, the user acts, and `receipts <file.html>` reads the submissions; the interaction reference owns the envelope.

## [02]-[REFERENCES]

- [01]-[HTML](references/html.md): advanced modern HTML — semantic structure, density, and the coding patterns every artifact composes from.
- [02]-[SVG](references/svg.md): advanced inline SVG for HTML — the element vocabulary, construction patterns, and figure and diagram craft.
- [03]-[STYLE](references/style.md): the design language and styling doctrine — the token system, layout, theming, and legibility law every artifact inherits.
- [04]-[INTERACTION](references/interaction.md): interaction and the return channel — the data-to-presentation mapping, the drawer, and how a page returns the user's adjustments as data.

## [03]-[CONTRACT]

- One file: `<!doctype html>`, one `<title>`, all CSS in one `<style>`, one executable `<script>`, optional `application/json` payload scripts as inert data.
- Zero external references: no CDN, no webfont, no remote image; only in-page anchors, `data:` URIs, relative links to sibling artifacts, and the injected return metas.
- Dark and light both render; wide content scrolls inside its own container and the body never scrolls sideways.
- Injected source, diff, and answer text reaches the DOM through escaping before any span wraps it; embedded JSON payloads are sanitized on embed.

## [04]-[INTEGRATION]

- A durable artifact homes at `docs/atlas/` as `<kind>.<scope>[.<slug>].html`; a session artifact stays in scratch and never commits.
- Chart marks and palettes defer to the `dataviz` skill; mermaid fences to `mermaid-diagramming`.

## [05]-[TEMPLATES]

Select one by intent; a template is a starting framework, not a finished page.

| [INDEX] | [TEMPLATE]  | [INTENT]    |
| :-----: | :---------- | :---------- |
|  [01]   | placeholder | placeholder |

## [06]-[EXAMPLES]

Add by content need; each example is a self-contained element restyled to the template.

| [INDEX] | [ELEMENT]   | [USE]       |
| :-----: | :---------- | :---------- |
|  [01]   | placeholder | placeholder |
