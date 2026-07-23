# [EMBEDDING]

A validated fence reaches its reader through a host, and every host binds one of two lanes: source lane — the host renders the fence itself — or render lane — the page carries the pre-rendered SVG. Fence stays the single source of truth in both; the SVG is a projection regenerated at will. Mermaid-diagramming validator owns the render mechanics.

## [01]-[MARKDOWN_HOSTS]

Durable markdown carries the source lane: the fence itself, one diagram per fence, placed beside the prose that cites it.

- A platform that renders fences client-side injects its own `initialize`; a payload-only fence takes the host theme by construction, so it reads native on every renderer — GitHub, docs sites, chat surfaces alike.
- `accTitle` and `accDescr` travel inside the fence, so every downstream render carries its SVG `<title>` and `<desc>` without the embedding page adding anything.
- Bundled validator consumes the markdown file directly — the fence in its final host position is the artifact under test, never a copy in a scratch file.

## [02]-[HTML_ARTIFACTS]

Render lane binds on self-containment and CSP, never on the host being HTML: a single-file html-studio deliverable or any strict-CSP page carries the pre-rendered SVG inlined into the document — never a CDN script tag, never a bundled runtime spent on a static picture — while a claude.ai Artifact page renders `mermaid` fences and `<pre class="mermaid">` blocks natively and stays a source-lane host despite its HTML form.

```bash template
uv run scripts/validate_mermaid.py --export <dir> <file.md ...>
```

Export row is the contract: each passing fence lands as an SVG whose root id is unique per fence (multi-diagram pages never collide on ids, selectors, or aria references), whose `accTitle`/`accDescr` ride as `<title>`/`<desc>` with the aria wiring intact, and whose `width="100%"` and `viewBox` scale to any container.

- SVG sits inside a container with `overflow-x: auto`; a wide diagram scrolls in its own box and never forces page-level horizontal scroll.
- Source fence rides beside the render — a collapsed `<details>` block carrying the fence keeps the diagram legible to machine readers, who see explicit labeled edges where a human sees layout. Spatial implication is invisible to an agent; the fence is the diagram's machine form.
- A page that must re-render user-edited diagram source is an editor, not an artifact: only there does an inlined mermaid runtime earn its megabytes, initialized once with the host's security posture, and the artifact contract stops applying.

## [03]-[EXPORT_SURFACES]

- Validator-rendered and `--export` SVGs carry native SVG text for flowchart, class, state, and ER — the render config bakes root `htmlLabels: false` — so those families survive vector editors, PDF pipelines, and pure-SVG rasterizers intact; a family still emitting `foreignObject` labels exports PNG through the mmdc raster flags the config reference owns.
- Visual proof is the validator's `--proof` lane: a browserless resvg raster of the canonical SVG, falling back to mmdc's own PNG where `foreignObject` labels remain — a pure-SVG rasterizer aimed at a `foreignObject` fence is label-blind and reads a healthy diagram as broken.
- Chat surfaces, slides, and issue trackers take PNG; a repository README takes the fence itself and lets the platform render; an HTML artifact takes the exported SVG. A consumer picks the surface — the fence never changes to suit one.
- A regenerated export replaces its predecessor wholesale; the unique root id is deterministic per source file and fence line, so a re-export lands on the same id and downstream references hold. Export slugs key on the file's basename — two same-basename files exported into one directory collide, so exports land in per-file directories or under unique basenames.
