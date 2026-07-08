# [SCHEDULE]

Draw owned work committed to dates. The template bakes in the schedule discipline an unassisted attempt fakes — every bar chains through `after` onto its real dependency and a convergence point lists every prerequisite (`after k2 s2`), so the critical path is derivable, never asserted; state marks truth (`done`, `active`, `crit`), with active bars straddling the today rule; a `vert` task draws the governance gate as a full-height marker — an engine rect classed `.vert` that renders as an opaque pipe until the fill-opacity stamp washes it; excluded days recess instead of glare; and the milestone is the one zero-length commitment the chains converge on. Use `gantt` with sections in phase order, parallel workstreams as interleaved chains, `axisFormat` with `tickInterval` and `weekday` sized to the span, and the Lavender `.sectionTitle` stamp so lane titles carry the container-title law. The today rule spans the full canvas, so it carries a translucent stroke through the `todayMarker` style string and never blinds what it crosses. Dependency-free decoration bars are the defect — a bar with no `after` and no date commitment is prose, not schedule.

```mermaid
---
config:
  theme: base
  look: classic
  gantt:
    fontSize: 12
    sectionFontSize: 13
    barHeight: 20
    barGap: 5
    topPadding: 70
    leftPadding: 110
    rightPadding: 40
    gridLineStartPadding: 35
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    titleColor: "#D6BCFA"
    taskTextColor: "#F8F8F2"
    taskTextOutsideColor: "#F8F8F2"
    taskTextDarkColor: "#F8F8F2"
    gridColor: "#6272A4"
    excludeBkgColor: "#21222C"
    sectionBkgColor: "#21222C"
    sectionBkgColor2: "#21222C"
    altSectionBkgColor: "#282A36"
    taskBkgColor: "#44475A"
    taskBorderColor: "#BD93F9"
    activeTaskBkgColor: "#6272A4"
    activeTaskBorderColor: "#BD93F9"
    doneTaskBkgColor: "#21222C"
    doneTaskBorderColor: "#6272A4"
    critBkgColor: "#FF555580"
    critBorderColor: "#FF5555"
    todayLineColor: "#FF79C6"
    vertLineColor: "#8BE9FD"
  themeCSS: ".sectionTitle{font-size:13.5px;font-weight:700;fill:#D6BCFA}.taskText,.taskTextOutsideRight,.taskTextOutsideLeft{font-size:12px}.grid .tick text{font-size:11px}.titleText{font-size:15px;font-weight:600}.vert{fill-opacity:.35;stroke-opacity:.6}.vertText{font-size:11px}"
---
gantt
  accTitle: Compute campaign schedule
  accDescr: A six-week compute campaign from survey and brief through parallel kernel and seam workstreams, gated by a scope freeze, converging on a verified landing milestone.
  title Compute Campaign
  dateFormat YYYY-MM-DD
  axisFormat %b %d
  tickInterval 1week
  weekday monday
  excludes weekends
  todayMarker stroke-width:2px,stroke:#FF79C6,opacity:0.55
  section Discovery
  Package survey :done, d1, 2026-06-15, 4d
  Api catalogs :done, d2, after d1, 3d
  section Design
  Campaign brief :done, b1, after d2, 4d
  Architecture pass :active, b2, after b1, 5d
  Scope freeze :vert, v1, 2026-07-10, 0d
  section Build
  Solver kernel :active, k1, after b1, 6d
  Receipt algebra :k2, after k1, 4d
  Seam ledger :s1, after b2, 5d
  Wire fences :crit, s2, after s1, 5d
  section Landing
  Cold verify :crit, l1, after k2 s2, 3d
  Gate sweep :l2, after l1, 2d
  Landed :milestone, m1, after l2, 0d
```

Refill by renaming sections to the real phases and tasks to the owned work, keep every bar on its `after` chain with convergence points listing all prerequisites, mark state truthfully against the real today, place the `vert` gate on its governed date, and size `tickInterval`/`weekday` to the real span so the axis never overlaps. The Lavender section stamp, recessed exclude bands, translucent critical chip, and translucent today rule are fixed law — a refill renames work, never strips the fidelity surface.
