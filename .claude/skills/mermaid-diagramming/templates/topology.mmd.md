# [TOPOLOGY]

Draw which deployable units run where and reach each other over what path. Template law bakes in the topology discipline an unassisted attempt scatters — groups are real zones, every edge is reachability over a real port pair, and the fcose grid is earned by constraint: edge ports (`L|R|T|B`) match the reading direction and every rank aligns both ways through `align row|column`, which is what produces orthogonal edges instead of diagonal drift. A junction joins genuinely multi-way edges only, and it holds orthogonal shape only inside the grid: home the junction in the fan's group, run the feeder in on one axis (`gw:R -- L:jfan`), fan out on the perpendicular axis with matched ports (`jfan:T --> B:render`, `jfan:B --> T:layout`), and pin it with an `align row` through its feeder and an `align column` through its targets — an unpinned junction, or one whose fan ports cross axes, drifts diagonal and misplaces its arrowheads. Use `architecture-beta` with 2-4 groups, 4-7 services, ports on every edge, and `architecture.seed` as the deterministic lock. Arrowheads fill from `archEdgeArrowColor` — unset they render grey, and `lineColor` never reaches this family — the built-in icon plates re-fill through the service and group rect stamps (service and group icons hardcode the same blue plate), group titles take the Lavender container-title stamp through `.architecture-groups text`, and arrow size rides `iconSize` because a CSS transform on the arrow polygons erases their placement. Logical components drawn as services are the defect; this archetype holds deployables.

```mermaid
---
config:
  theme: base
  look: classic
  architecture:
    seed: 7
    iconSize: 64
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    archEdgeColor: "#FF79C6"
    archEdgeArrowColor: "#FF79C6"
    archEdgeWidth: "2"
    archGroupBorderColor: "#D6BCFA"
    archGroupBorderWidth: "1"
  themeCSS: ".architecture-service svg rect{fill:#44475A!important}.architecture-groups svg rect{fill:#44475A!important}.architecture-groups text{fill:#D6BCFA;font-size:13.5px;font-weight:700;letter-spacing:.08em}.architecture-services text{font-size:13px;font-weight:500}.node-bkg{stroke-dasharray:5 4}"
---
architecture-beta
  accTitle: Render service topology
  accDescr: An edge gateway fanning through a junction bus to a render and layout service pair backed by a content cache and an artifact registry, aligned into an orthogonal grid.
  group edge(cloud)[Edge]
  group core(cloud)[Core]
  group store(cloud)[Store]
  service gw(internet)[Gateway] in edge
  service render(server)[Render] in core
  service layout(server)[Layout] in core
  service cache(disk)[Cache] in store
  service registry(database)[Registry] in store
  junction jfan in core
  gw:R -- L:jfan
  jfan:T --> B:render
  jfan:B --> T:layout
  render:R --> L:cache
  layout:R --> L:registry
  align row gw jfan
  align column render jfan layout
  align row render cache
  align row layout registry
  align column cache registry
```

Refill by renaming zones and services to the real deployment, keep a port pair on every edge, and re-derive the `align` grid whenever a service lands — every row and column of the intended grid is declared, because the constraint set is the layout, and a landed junction re-pins into both axes of that grid.
