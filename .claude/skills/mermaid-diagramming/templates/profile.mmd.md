# [PROFILE]

Draw a multivariate comparison of two subjects across one axis set. The template bakes in the radar discipline an unassisted attempt washes out — the curves carry genuinely distinct assessments, because identical data cancels into one pale polygon; fills sit at the `.35` curve opacity so both polygons read where they overlap while their full-hue 2px strokes hold the border law; and the margins clear the axis labels, which anchor outside the chart radius and clip at the viewport edge. Use `radar-beta` with 5-7 axes, two to four curves whose hues follow the ordinal order — pink, cyan, green, keyed entries so values bind by axis id, and short curve labels — the legend position is engine-fixed. Scores come from assessment, never narrative; a profile without a stated scoring basis beside the fence is decoration.

```mermaid
---
config:
  theme: base
  look: classic
  radar:
    width: 480
    height: 480
    marginLeft: 120
    marginRight: 120
    marginTop: 60
    marginBottom: 60
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    titleColor: "#F8F8F2"
    cScale0: "#FF79C6"
    cScale1: "#8BE9FD"
    cScale2: "#50FA7B"
    radar:
      axisColor: "#6272A4"
      axisStrokeWidth: 1.5
      graticuleColor: "#44475A"
      graticuleOpacity: 0.4
      curveOpacity: 0.35
      curveStrokeWidth: 2
---
radar-beta
  accTitle: Package capability profile
  accDescr: The compute kernel, persistence layer, and bim domain compared across six capability axes scored from the corpus audit.
  title Capability Profile
  axis rails["Rails"], depth["Depth"], seams["Seams"], docs["Docs"], gates["Gates"], stack["Stacking"]
  curve compute["Compute"]{ rails: 90, depth: 85, seams: 70, docs: 80, gates: 88, stack: 75 }
  curve persist["Persist"]{ rails: 72, depth: 78, seams: 88, docs: 85, gates: 70, stack: 90 }
  curve bim["Bim"]{ rails: 80, depth: 92, seams: 84, docs: 68, gates: 74, stack: 82 }
  showLegend true
  graticule polygon
  ticks 4
  max 100
  min 0
```

Refill by renaming axes to the real judgment set and curves to the subjects, scores from the stated assessment; axis labels stay short enough for the margins, and a longer roster widens `marginLeft`/`marginRight` before it abbreviates. The two-hue curve set, `.35` fill opacity, full-hue strokes, and Comment graticule are fixed law — a refill renames the comparison, never strips the fidelity surface.
