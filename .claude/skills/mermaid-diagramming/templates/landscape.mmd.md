# [LANDSCAPE]

Draw the system landscape at one audience's zoom. The template bakes in the C4 discipline an unassisted attempt violates — one boundary per ownership domain with externals homed in their own boundary, because the engine packs loose shapes in rows above every boundary and relations cross whatever lands beneath the first; persons sit above their systems; every relation carries its verb and its kind's color through `UpdateRelStyle`, with `$offsetX`/`$offsetY` pulling labels clear of boxes. Element colors are `c4:` config keys, and so are fonts — `themeVariables.fontFamily` never reaches C4 text, so the per-family `*FontFamily`/`*FontSize` triplets carry the mono stack and the type ramp; boundary walls and titles re-ink Lavender through the `#444444` attribute hooks, the black default markers take canon pink at the unified scale — one shared marker serves every relation, so heads hold Pink over any line color — and the raster person sprites retire so the stereotype carries the role. Use `C4Context` with 5-8 elements across 2 boundaries; a view mixing zoom levels is two views.

```mermaid
---
config:
  theme: base
  look: classic
  c4:
    c4ShapeInRow: 3
    c4ShapeMargin: 50
    c4BoundaryInRow: 2
    personFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    personFontSize: 13
    external_personFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    external_personFontSize: 13
    systemFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    systemFontSize: 13
    system_dbFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    system_dbFontSize: 13
    external_systemFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    external_systemFontSize: 13
    boundaryFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    boundaryFontSize: 13.5
    messageFontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    messageFontSize: 12
    person_bg_color: "#44475A"
    person_border_color: "#BD93F9"
    external_person_bg_color: "#282A36"
    external_person_border_color: "#8BE9FD"
    system_bg_color: "#44475A"
    system_border_color: "#BD93F9"
    system_db_bg_color: "#44475A"
    system_db_border_color: "#FFB86C"
    external_system_bg_color: "#282A36"
    external_system_border_color: "#8BE9FD"
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    personBorder: "#BD93F9"
    personBkg: "#44475A"
  themeCSS: "rect[stroke='#444444']{stroke:#D6BCFA;stroke-dasharray:5 4}text[fill='#444444']{fill:#D6BCFA}[id$='-arrowhead'] path{fill:#FF79C6;transform:scale(.8);transform-origin:9px 5px}[id$='-arrowend'] path{fill:#FF79C6;transform:scale(.8);transform-origin:1px 5px}image{display:none}"
---
C4Context
  accTitle: Rasm platform landscape
  accDescr: An author driving the app platform that solves through the compute kernel into an artifact store, serving a Rhino host operator through the host boundary.
  title Rasm Platform Landscape
  Person(author, "Author", "Plans and lands fences")
  Person_Ext(operator, "Host Operator", "Drives Rhino")
  Enterprise_Boundary(platform, "App Platform") {
    System(apphost, "Rasm.AppHost", "Composition and ports")
    System(compute, "Rasm.Compute", "Solver kernel")
    SystemDb(store, "Rasm.Persistence", "Artifact index")
  }
  Boundary(hostzone, "Host Boundary") {
    System_Ext(rhino, "Rasm.Rhino", "Host adapter")
  }
  Rel(author, apphost, "Plans with")
  Rel(apphost, compute, "Solves through")
  Rel(compute, store, "Writes receipts")
  Rel(rhino, store, "Reads artifacts")
  Rel(operator, rhino, "Operates")
  UpdateRelStyle(author, apphost, $textColor="#F8F8F2", $lineColor="#FF79C6", $offsetY="-30")
  UpdateRelStyle(apphost, compute, $textColor="#F8F8F2", $lineColor="#FF79C6", $offsetY="-14")
  UpdateRelStyle(compute, store, $textColor="#F8F8F2", $lineColor="#FFB86C")
  UpdateRelStyle(rhino, store, $textColor="#F8F8F2", $lineColor="#FFB86C", $offsetY="-30")
  UpdateRelStyle(operator, rhino, $textColor="#F8F8F2", $lineColor="#8BE9FD", $offsetY="-14")
```

Refill by renaming boundaries to the real ownership domains and elements to the real systems at ONE zoom — a container question re-declares as `C4Container` in its own fence. Every relation keeps its verb, kind color, and a label offset that clears the packed rows. The Lavender boundary hooks, pink scaled markers, and retired sprites are fixed law — a refill renames the landscape, never strips the fidelity surface.
