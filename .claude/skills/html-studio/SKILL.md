---
name: html-studio
description: >-
  Author single-file, self-contained interactive HTML pages opened from disk or served with an
  agent return channel: plans, roadmaps, brainstorms, wargames with live weighted scoring,
  diff-reviews, quizzes, buy-in pitches, capability atlases, explainers with live simulators,
  decks, micro-editors (triage boards, config editors, prompt tuners) that send state back to the
  agent, design-system pages, status and incident reports, dashboards over embedded data, contact
  sheets, prototypes, SVG figure sheets, and architecture maps. Use when creating or updating any
  HTML planning artifact, when a plan, comparison, roadmap, review, decision, or dataset reads
  better as an interactive page than markdown, when user input should return through an
  interactive surface, or when the user says HTML plan, roadmap, wargame, deck, quiz, dashboard,
  or report, or asks to visualize a plan, decision, architecture, or data. Distinct from the
  Artifact tool's hosted fragments; mermaid fences belong to mermaid-diagramming.
allowed-tools:
  - Bash(uv run ${CLAUDE_SKILL_DIR}/scripts/studio.py *)
---

# [HTML_STUDIO]

An HTML page trades a document that gets skimmed for one that gets read — spatial layout for comparisons, interaction for decisions, rendered structure for architecture — and an interactive page trades one-way delivery for a round trip: the user adjusts the artifact and the adjustment returns to the agent as typed data. One file opens from disk with no network, the page is the deliverable, and NOCTURNE — the Dracula-descended dark-first design system in [references/design-system.md](references/design-system.md) — is the single visual voice. The judgment layer is [references/method.md](references/method.md); build mechanics live in the references routed below.

## [01]-[BUILD]

1. Investigate and select against [references/method.md](references/method.md): name the decision the page moves, build the question inventory, bind every claim to an evidence object, and resolve the interactivity conflict before any layout thought.
2. Pick the type in [02]; copy its template or compose its region spine from [references/artifact-types.md](references/artifact-types.md).
3. Carry the three stamped NOCTURNE regions — baseline style, export drawer, runtime kernel — from the byte canon under `scripts/nocturne/`: a template already carries them, a composed one-off starts from `studio.py stamp --new`, and `studio.py stamp` refreshes drifted regions.
4. Compose from the routed references: code shape and platform admission [references/code.md](references/code.md), layout and devices [references/styling.md](references/styling.md), element generators [references/elements.md](references/elements.md), interaction and motion [references/interaction.md](references/interaction.md), state and redaction [references/state.md](references/state.md), inline SVG [references/svg.md](references/svg.md).
5. Fill content answer-first; render the thing itself — real code, real controls, real data rows — never prose describing an unrendered surface.
6. An artifact that captures judgment composes the round-trip contract from [references/roundtrip.md](references/roundtrip.md): the envelope, verdict vocabulary, stable item ids, dual export, and the return-channel probe.
7. Gate: `uv run ${CLAUDE_SKILL_DIR}/scripts/studio.py gate <file.html>` — self-containment, tokens, contrast, script audit, and W3C HTML/SVG conformance (`vnu`); fix until exit 0; warn rows are review pressure, not noise.
8. Render: `uv run ${CLAUDE_SKILL_DIR}/scripts/studio.py render <file.html>` drives the pinned headless Chromium, writes a full-page screenshot beside the artifact, and surfaces every `console` and `pageerror` as a row; inspect the screenshot and clear every error row.
9. Review in the fixed order method.md owns — skim, coverage, interaction necessity, density, print.
10. Home the artifact per [05]; an interactive session runs the return channel per [04].

## [02]-[TYPE_CHOOSER]

The most specific trigger wins; each row names the misfit sibling it displaces. A comparison of visual directions, UI options, layouts, or weighted candidates never flattens into inline chips or prose options — the artifact route fires first and the page carries the comparison. A request no row matches composes the nearest type's region spine rather than falling back to markdown.

| [INDEX] | [TYPE]           | [WHEN]                                  | [INSTEAD_OF]     |
| :-----: | :--------------- | :-------------------------------------- | :--------------- |
|  [01]   | plan             | staged blueprint for one change         | brainstorm       |
|  [02]   | brainstorm       | unnamed directions generated pre-pick   | wargame          |
|  [03]   | wargame          | named candidates scored on criteria     | brainstorm       |
|  [04]   | roadmap          | capability sequenced by horizon         | plan             |
|  [05]   | diff-review      | a patch read beside critique            | explainer        |
|  [06]   | quiz             | comprehension gated pre-merge           | diff-review      |
|  [07]   | buy-in           | objections answered pre-signoff         | explainer        |
|  [08]   | capability-atlas | one owner-and-edge map                  | roadmap          |
|  [09]   | explainer        | a feature or concept walked             | wargame          |
|  [10]   | deck             | a case walked slide by slide            | explainer        |
|  [11]   | editor           | one decision surface edited in place    | plan             |
|  [12]   | design-system    | repo tokens as a taste surface          | explainer        |
|  [13]   | report           | recurring status or incident page       | explainer        |
|  [14]   | dashboard        | filterable board over one dataset       | report           |
|  [15]   | contact-sheet    | one thing across all its states         | brainstorm       |
|  [16]   | prototype        | an interaction or motion felt pre-build | brainstorm       |
|  [17]   | figure-sheet     | standalone SVG figures for docs         | explainer        |
|  [18]   | architecture     | one topology under many named flows     | capability-atlas |
|  [19]   | schema-map       | one store's entities, keys, and changes | architecture     |

Templates carry the highest-frequency types; the rest compose their region spines from [references/artifact-types.md](references/artifact-types.md).

- [01]-[PLAN](templates/plan.html)
- [02]-[BRAINSTORM](templates/brainstorm.html)
- [03]-[WARGAME](templates/wargame.html)
- [04]-[ROADMAP](templates/roadmap.html)
- [05]-[DIFF-REVIEW](templates/diff-review.html)
- [08]-[CAPABILITY-ATLAS](templates/atlas.html)
- [09]-[EXPLAINER](templates/explainer.html)
- [10]-[DECK](templates/deck.html)
- [11]-[EDITOR](templates/editor.html)
- [13]-[REPORT](templates/report.html)
- [14]-[DASHBOARD](templates/dashboard.html)
- [16]-[PROTOTYPE](templates/prototype.html)

## [03]-[CONTRACT]

- One file: `<!doctype html>`, a `<title>`, all CSS in one `<style>`, one executable `<script>`, and optional `application/json` payload scripts as inert data. Zero external references — no CDN, no webfont, no remote image; only `#` anchors, `data:` URIs, relative links to sibling artifacts, and the injected return meta.
- From disk means from disk: sibling fetch, module imports, service workers, and webfonts are dead under `file://`; everything the artifact needs, it embeds. `localStorage` is a fallible enhancement; export and the return channel are the durable egress.
- Dark and light both render: NOCTURNE dark is the base, light arrives through the system preference and the `data-theme` toggle, and both directions win per the design-system theme law.
- Wide content — tables, diagrams, code — scrolls inside its own `overflow-x:auto` container; the body never scrolls sideways.
- Escape before inject: source, diff, and answer text reaches the DOM through `textContent` escaping before any span wraps it — an injected string is never trusted as HTML.
- Diagrams are inline pre-rendered SVG under [references/svg.md](references/svg.md), never a runtime diagram library.
- Datasets pass the redaction gate in [references/state.md](references/state.md) before embedding.

## [04]-[RETURN_CHANNEL]

An artifact whose value is the user's judgment — verdicts, scores, reorderings, edits — runs served, not just opened:

1. `uv run ${CLAUDE_SKILL_DIR}/scripts/studio.py serve <artifact.html>` in the background; the banner prints `URL=`, `RECEIPTS=`, `STATE=` (`--output json` for one machine-readable object, `--ttl` to bound the run).
2. Open the URL for the user. The served page carries the injected `artifact-return` and `artifact-token` metas; its export drawer shows the primary send action, and the page returns the token as the `X-Artifact-Token` header.
3. The user adjusts the page and sends; each accepted submission appends one tagged receipt row to the receipts JSONL beside lifecycle event rows.
4. `studio.py receipts <file> --last 1` is the canonical read; act on the payload, then `studio.py stop`. `status` proves liveness; `self-test` proves the circuit end to end.

Opened plain from disk the same artifact degrades to copy-markdown and JSON download; the canonical envelope is identical on every path and the served POST wraps it as `{kind, artifact, version, data}`. Protocol detail is [references/roundtrip.md](references/roundtrip.md).

## [05]-[LIFECYCLE]

- Durable artifacts commit under the host's artifact home (`<artifact-home>`), named `<kind>.<scope>[.<slug>].html`; dated kinds carry `YYYY-MM-DD` in the slug, living kinds update in place, and history is version control.
- Ephemeral artifacts — session plans, one-shot explainers, throwaway editors — live in scratch space and never commit.
- Monorepo artifacts compose at three scopes — repo-wide, branch-level, folder-level — linked as relative sibling pages under the structure law in [references/method.md](references/method.md).
- An artifact that moved a durable decision leaves that decision in the durable record; the artifact visualizes truth and is never its sole carrier.

## [06]-[GOTCHAS]

- A quiet external reference is the most common self-containment breach — a CDN script, a webfont, an `https://` image; the gate catches every one.
- An embedded JSON payload carrying a raw `</script>` or U+2028 terminates its own script element; sanitize on embed per the state reference.
- Hover-only evidence dies on touch and print; anything load-bearing renders visibly in the default state.
- Editing the exported markdown instead of re-exporting forks the truth; the UI state is the source until the next export or submission lands.
- Index-paired array diffs misread reordered rows; diff records key by identity.
- A served artifact left running holds its port and state file; `stop` after the receipts are read.
- A repo-committed full `<html>` document is a different artifact from a claude.ai-hosted Artifact — the hosted kind is a body fragment under a CSP sandbox and belongs to the Artifact tool.

## [07]-[REPO_INTEGRATION]

When the host repo declares an artifact home and naming law (an atlas or artifacts route in its instruction chain), that law binds `<artifact-home>` and filenames; in this repo durable pages home at `docs/atlas/`. When a `dataviz` skill is available, chart color and mark decisions defer to it. Interviewing rulings render through this skill's type rows and interactive interview surfaces run the return channel.
