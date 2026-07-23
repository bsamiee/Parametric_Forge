# [EVENT_FLOW]

Draw which commands produce which events and which read models consume them, in timeline order. Template law bakes in the event-modeling discipline an unassisted attempt scrambles — frames land in strict causal order because relations infer from the nearest prior frame in a different lane, so declaration order IS the arrow set, and payloads annotate the frames whose shape is the contract, each riding the `` `json` `` code form. Relations stay single-source by construction: the family has no explicit-edge syntax, so a fan-in — a frame consuming two upstream lanes, a merge, a correlation — is inexpressible here and routes to logic-flow or a flowchart. A host predating the family renders the error bomb rather than the lanes. Use 6-10 `tf` frames across the ui, command/read-model, and event lanes; `accTitle`/`accDescr` parse but emit nothing into the SVG, so the relation sentence rides beside the fence. A read model fed by no upstream event is the defect the frame order makes visible.

```mermaid
eventmodeling
  tf 01 ui PlanBoard `json`{ "card": "RS-203" }
  tf 02 cmd RealizeCard
  tf 03 evt CardRealized `json`{ "fence": "cache-rail" }
  tf 04 rmo BoardView
  tf 05 ui GateConsole
  tf 06 cmd RunGate
  tf 07 evt GatePassed
  tf 08 pcr LandingProcessor
  tf 09 evt CardLanded `json`{ "receipt": "ok" }
```

Refill by renaming frames to the real command-event chain in causal order — the implicit relation chain is the assertion, so a frame that must source from an earlier lane declares immediately after it, namespaced ids (`stream.Name`) open extra lanes per stream, and a join of two streams leaves this family.
