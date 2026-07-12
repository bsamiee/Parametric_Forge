---
name: html-studio
description: Author single-file, self-contained interactive HTML artifacts — reports, dashboards, roadmaps, plans, decision docs, and their variants (diff-reviews, quizzes, wargames, buy-in packets, boards, decks, explainers, atlases) — as typed deliverable compositions under one design system, then validated headless (`gate`, `render`) and optionally served with a return channel (`serve`, `receipts`) that brings the reader's judgment back as data. Use when a plan, roadmap, comparison, decision, dataset, or architecture reads better as an interactive page than markdown, when a page should return the user's adjustments as data, or when the user says HTML plan, roadmap, dashboard, deck, wargame, quiz, or report. Distinct from the Artifact tool's hosted fragments; mermaid fences belong to mermaid-diagramming.
allowed-tools:
    - Bash(uv run ${CLAUDE_SKILL_DIR}/scripts/studio.py *)
---

# [HTML_STUDIO]

Every artifact is one self-contained file: a deliverable type fixes its composition — layout class, structural spine, element set, capture contract — and the references rule the code, style, figures, and interaction it composes from.

## [01]-[ROUTING]

[REFERENCES]:
- [01]-[DELIVERABLES](references/deliverables.md): the type registry — per-type spine, layout class, element set, capture contract, and the variant table that resolves every named deliverable onto a core type.
- [02]-[HTML](references/html.md): advanced HTML — semantic structure, density, and the coding patterns every artifact composes from.
- [03]-[SVG](references/svg.md): advanced inline SVG for HTML — the element vocabulary, construction patterns, and figure and diagram craft.
- [04]-[STYLE](references/style.md): the design language and styling doctrine — the token system, layout, theming, and legibility law every artifact inherits.
- [05]-[INTERACTION](references/interaction.md): interaction and the return channel — the data-to-presentation mapping, the drawer, and how a page returns the user's adjustments as data.

[TEMPLATES]:
- [01]-[ARTIFACT](templates/artifact.template.html): the gate-clean shell with the registry, layers, body order, drawer, and script kernels.

[EXAMPLES]:
- [01]-[DECISION_RECORD](examples/decision-record.html): the worked decision-doc instance at composed scale.

## [02]-[BUILD]

1. Load the references.
2. Select the deliverable type from the deliverables reference by the reader's first question; the type fixes the measure, the section spine, the envelope kind, and whether a drawer ships. A page serving two types splits or subordinates.
3. Model the content before rendering it: the payload block carries every fact, stable ids on every capturable item, and markup states nothing the model lacks.
4. Compose answer-first down the type's spine, starting from `templates/artifact.template.html` and consulting `examples/decision-record.html`. Real controls, real data rows, real rendered rivals — never prose describing an unbuilt surface — with every element inheriting the token registry.
5. Validate the finalized artifact with `uv run ${CLAUDE_SKILL_DIR}/scripts/studio.py` and fix until clean: `gate <file.html>` checks self-containment, accessibility, style-doctrine conformance, and W3C markup; `render <file.html>` returns a headless screenshot and the console through the machine's pinned Chromium. `--help` lists every verb.
6. An artifact whose value is the user's judgment runs served, not just opened: `serve <file.html>` hosts it with the return channel, the user acts, and `receipts <file.html>` reads the submissions; the interaction reference owns the envelope.

## [03]-[CONTRACT]

- One file: `<!doctype html>`, one `<title>`, all CSS in one `<style>`, one executable `<script>`, optional `application/json` payload scripts as inert data.
- Zero external references: no CDN, no webfont, no remote image; only in-page anchors, `data:` URIs, relative links to sibling artifacts, and the injected return metas.
- Dark and light both render; wide content scrolls inside its own container and the body never scrolls sideways.
- Injected source, diff, and answer text reaches the DOM through escaping before any span wraps it; embedded JSON payloads are sanitized on embed.

## [04]-[INTEGRATION]

- A durable artifact homes at `docs/atlas/` as `<kind>.<scope>[.<slug>].html`; a session artifact stays in scratch and never commits.
- Chart marks and palettes defer to the `dataviz` skill; mermaid fences to `mermaid-diagramming`, whose render lane delivers a mermaid-sourced figure as pre-rendered inline SVG the page hosts; interview method, kind contracts, and the durable-versus-ephemeral ruling to the `interviewing` skill.
