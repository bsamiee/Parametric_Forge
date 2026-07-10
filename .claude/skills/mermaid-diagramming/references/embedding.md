# [EMBEDDING]

A validated fence reaches its reader through a host, and every host binds one of two lanes: source lane — the host renders the fence itself — or render lane — the page carries the pre-rendered SVG. The fence stays the single source of truth in both; the SVG is a projection regenerated at will. Skills that produce artifacts route here by name for the contract; the mermaid-diagramming validator owns the mechanics.

## [01]-[MARKDOWN_HOSTS]

Durable markdown carries the source lane: the fence itself, opened with the `mermaid` info string, frontmatter on line 1 of the body, delimiters at column one, one diagram per fence, placed beside the prose that cites it.

- A platform that renders fences client-side injects its own `initialize`; the fence's frontmatter `theme`, `look`, `themeVariables`, and `themeCSS` outrank it, so a themed fence keeps its face on any renderer that honors frontmatter. A docs host that owns a site-level theme takes the whole-theme drop rule in the theming reference.
- `accTitle` and `accDescr` travel inside the fence, so every downstream render carries its SVG `<title>` and `<desc>` without the embedding page adding anything.
- The bundled validator consumes the markdown file directly — the fence in its final host position is the artifact under test, never a copy in a scratch file.

## [02]-[HTML_ARTIFACTS]

A single-file HTML artifact — an html-studio deliverable or any page under a strict content-security policy — carries the render lane: the pre-rendered SVG inlined into the document, never a CDN script tag and never a bundled runtime spent on a static picture.

```bash template
uv run scripts/validate_mermaid.py --export <dir> <file.md ...>
```

The export row is the contract: each passing fence lands as an SVG whose root id is unique per fence (multi-diagram pages never collide on ids, selectors, or aria references), whose `accTitle`/`accDescr` ride as `<title>`/`<desc>` with the aria wiring intact, whose `width="100%"` plus `viewBox` scale to any container, and whose Dracula canvas is baked so the diagram self-carries on light and dark hosts alike.

- The SVG sits inside a container with `overflow-x: auto`; a wide diagram scrolls in its own box and never forces page-level horizontal scroll.
- On a dark host the baked `#282A36` canvas reads as a raised panel; the container steps its own surface down a level or frames the SVG with a visible border — the elevation rule the theming reference states for inline placement.
- The source fence rides beside the render — a collapsed `<details>` block carrying the fence keeps the diagram legible to machine readers, who see explicit labeled edges where a human sees layout. Spatial implication is invisible to an agent; the fence is the diagram's machine form.
- A page that must re-render user-edited diagram source is an editor, not an artifact: only there does an inlined mermaid runtime earn its megabytes, initialized once with the host's security posture, and the artifact contract above stops applying.

## [03]-[EXPORT_SURFACES]

- Inline SVG in a browser context is full fidelity: labels ride `foreignObject` HTML, and every browser renders it. A consumer outside the browser — vector editors, PDF pipelines, image toolchains — drops `foreignObject`, so anything bound for one exports PNG through the mmdc raster flags the config reference owns.
- Chat surfaces, slides, and issue trackers take PNG; a repository README takes the fence itself and lets the platform render; an HTML artifact takes the exported SVG. The consumer picks the surface — the fence never changes to suit one.
- A regenerated export replaces its predecessor wholesale; the unique root id is deterministic per source file and fence line, so a re-export lands on the same id and downstream references hold.
