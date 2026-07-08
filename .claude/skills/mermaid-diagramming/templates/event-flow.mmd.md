# [EVENT_FLOW]

Draw which commands produce which events and which read models consume them, in timeline order. The template bakes in the event-modeling discipline an unassisted attempt scrambles — frames land in strict causal order because relations infer from the nearest prior frame in a different lane, so declaration order IS the arrow set; payloads annotate the frames whose shape is the contract; and each frame kind reads its own `em*` pair so the lane semantics render. Use `eventmodeling` with 6-10 `tf` frames across the ui, command/read-model, and event lanes; `accTitle`/`accDescr` break the parser before the frames, so the relation sentence rides beside the fence. Box text hardcodes a bold sans inside `foreignObject` spans — the `.em-box span` stamp restores the mono ramp, `.em-box code` inks payloads Cyan, and `.em-swimlane text` carries the lane titles in Lavender. A read model fed by no upstream event is the defect the frame order makes visible.

```mermaid
---
config:
  theme: base
  look: classic
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    textColor: "#F8F8F2"
    emUiFill: "#44475A"
    emUiStroke: "#BD93F9"
    emCommandFill: "#44475A"
    emCommandStroke: "#8BE9FD"
    emEventFill: "#44475A"
    emEventStroke: "#FFB86C"
    emProcessorFill: "#21222C"
    emProcessorStroke: "#6272A4"
    emReadModelFill: "#21222C"
    emReadModelStroke: "#50FA7B"
    emSwimlaneBackgroundOdd: "#282A36"
    emSwimlaneBackgroundStroke: "#44475A"
    emArrowhead: "#FF79C6"
    emRelationStroke: "#FF79C6"
  themeCSS: ".em-box span{font-family:'SF Mono',Menlo,'Cascadia Mono',Consolas,monospace;font-size:13px;color:#F8F8F2}.em-box code{color:#8BE9FD;font-size:11px}.em-swimlane text{fill:#D6BCFA;font-size:13.5px;font-family:'SF Mono',Menlo,'Cascadia Mono',Consolas,monospace}"
---
eventmodeling
  tf 01 ui PlanBoard { "card": "RS-203" }
  tf 02 cmd RealizeCard
  tf 03 evt CardRealized `json`{ "fence": "cache-rail" }
  tf 04 rmo BoardView
  tf 05 ui GateConsole
  tf 06 cmd RunGate
  tf 07 evt GatePassed
  tf 08 pcr LandingProcessor
  tf 09 evt CardLanded `json`{ "receipt": "ok" }
```

Refill by renaming frames to the real command-event chain in causal order — the implicit relation chain is the assertion, so a frame that must source from an earlier lane declares immediately after it; namespaced ids (`stream.Name`) open extra lanes per stream. The `em*` pairs, mono span stamp, Cyan payload ink, and Lavender lane titles are fixed law — a refill renames the flow, never strips the fidelity surface.
