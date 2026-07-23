# [SCHEDULE]

Draw owned work committed to dates. Template law bakes in the schedule discipline an unassisted attempt fakes — every bar chains through `after` onto its real dependency and a convergence point lists every prerequisite (`after k2 s2`), so the critical path is derivable, never asserted; state marks truth against the real today (`done`, `active`, `crit`), a law the refiller upholds by dating active bars to straddle the today rule; a `vert` task draws the governance gate as a full-height marker; and the milestone is the zero-length terminal commitment downstream of the convergence gate. Gantt has no blocked state: a stalled task carries its blocker in the label, and `crit` stays reserved for the critical path rather than doubling as an alarm chip. Use `gantt` with sections in phase order, parallel workstreams as interleaved chains, and `axisFormat` with `tickInterval` and `weekday` sized to the span; the `gantt:` block carries geometry keys. Dependency-free decoration bars are the defect — a bar with no `after` and no date commitment is prose, not schedule.

```mermaid
---
config:
  gantt:
    barHeight: 20
    barGap: 5
    topPadding: 70
    leftPadding: 110
    rightPadding: 40
    gridLineStartPadding: 35
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
  section Discovery
  Package survey :done, d1, 2026-06-29, 4d
  Api catalogs :done, d2, after d1, 3d
  section Design
  Campaign brief :done, b1, after d2, 4d
  Architecture pass :active, b2, after b1, 5d
  Scope freeze :vert, v1, 2026-07-24, 0d
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

Refill by renaming sections to the real phases and tasks to the owned work, keep every bar on its `after` chain with convergence points listing all prerequisites, mark state truthfully against the real today, place the `vert` gate on its governed date, and size `tickInterval`/`weekday` to the real span so the axis never overlaps.
