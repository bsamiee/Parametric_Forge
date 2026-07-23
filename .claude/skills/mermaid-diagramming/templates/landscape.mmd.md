# [LANDSCAPE]

Draw the system landscape at one audience's zoom. Template law bakes in the C4 discipline an unassisted attempt violates — one boundary per ownership domain with externals homed in their own boundary, because the engine packs loose shapes in rows above every boundary and relations cross whatever lands beneath the first; persons sit above their systems; every relation carries its verb. Boundaries ride one macro family — the generic `Boundary` whose third argument is a real ownership word rendered as the bracketed tag under the title, so no committed landscape leaks the `[ENTERPRISE]`/`[system]` macro defaults. Use `C4Context` with 5-8 systems and persons across one boundary per ownership domain, commonly 2-4; a view mixing zoom levels is two views, and a container question re-declares as `C4Container` in its own fence.

```mermaid
---
config:
  c4:
    c4ShapeInRow: 3
    c4ShapeMargin: 50
    c4BoundaryInRow: 2
---
C4Context
  accTitle: Platform landscape
  accDescr: An author driving the app platform that solves through the compute kernel into an artifact store, serving a host operator through the host boundary.
  title Platform Landscape
  Person(author, "Author", "Plans and lands fences")
  Person_Ext(operator, "Host Operator", "Drives the host app")
  Boundary(platform, "App Platform", "platform") {
    System(apphost, "AppHost", "Composition and ports")
    System(compute, "Compute", "Solver kernel")
    SystemDb(store, "Persistence", "Artifact index")
  }
  Boundary(hostzone, "Host Boundary", "host") {
    System_Ext(hostapp, "HostApp", "Host adapter")
  }
  Rel(author, apphost, "Plans with")
  Rel(apphost, compute, "Solves through")
  Rel(compute, store, "Writes receipts")
  Rel(hostapp, store, "Reads artifacts")
  Rel(operator, hostapp, "Operates")
```

Refill by renaming boundaries to the real ownership domains — each with its ownership word in the `$type` slot — and elements to the real systems at ONE zoom. Every relation keeps its verb.
