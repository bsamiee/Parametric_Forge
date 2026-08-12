# [TOPOLOGY]

Draw which deployable units run where and reach each other over what path. Template law bakes in the topology discipline an unassisted attempt scatters — groups are real zones, every edge is reachability over a real port pair, and the fcose grid is earned by constraint: edge ports (`L|R|T|B`) match the reading direction and every rank aligns both ways through `align row|column`, which is what produces orthogonal edges instead of diagonal drift. A junction joins genuinely multi-way edges only, and it holds orthogonal shape only inside the grid: home the junction in the fan's group, run the feeder in on one axis (`gw:R -- L:jfan`), fan out on the perpendicular axis with matched ports (`jfan:T --> B:render`, `jfan:B --> T:layout`), and pin it with an `align row` through its feeder and an `align column` through its targets — an unpinned junction, or one whose fan ports cross axes, drifts diagonal and misplaces its arrowheads. Use `architecture-beta` with 2-4 groups, 4-7 services, ports on every edge, and `architecture.seed` as the deterministic lock; arrow size rides `iconSize`. Logical components drawn as services are the defect; this archetype holds deployables.

```mermaid
---
config:
  architecture:
    seed: 7
    iconSize: 64
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
