# [WIRE_SEQUENCE]

Draw an ordered exchange across a wire or process boundary. Template law bakes in the wire discipline an unassisted attempt drops — the frame shape is named ON the wire in a note, so both sides visibly share one contract; every request has its visible return in both the success and fault arms, keeping causality auditable; the resolver's activation brackets exactly the work it owns; and the timeout escape is a `break` block, because a timeout aborts the exchange rather than branching it. Five region kinds carry the exchange grammar: `alt` splits mutually exclusive outcomes, `opt` guards a single conditional step, `par` runs concurrent arms, `critical`/`option` marks a mandatory step with its fault escape, and `loop` carries repetition — a reply stream drains in a `loop`, a retry re-opens in one, and every loop states its bound on the frame label so the exchange provably terminates. A resolver's owned exchange sits on a `rect` background and the in-process pair sits in a `box`; a bare lifeline outside every box reads as external — sequence has no per-actor class, so containment is the externality encoding. Use `sequenceDiagram` with `autonumber` for citable steps; the participant floor is a branch or fault split, not a headcount, though 3-4 participants is the common shape. `sequenceDiagram` takes no ELK. An unordered ownership structure is a spine or seam-graph, never a sequence.

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
    background: "#282A36"
    primaryColor: "#44475A"
    primaryTextColor: "#F8F8F2"
    noteBkgColor: "#44475A"
    noteTextColor: "#F8F8F2"
    noteBorderColor: "#6272A4"
    actorBkg: "#44475A"
    actorBorder: "#BD93F9"
    actorTextColor: "#F8F8F2"
    actorLineColor: "#6272A4"
    signalColor: "#FF79C6"
    signalTextColor: "#F8F8F2"
    sequenceNumberColor: "#282A36"
    activationBkgColor: "#44475A"
    activationBorderColor: "#BD93F9"
    loopTextColor: "#F8F8F2"
    labelBoxBkgColor: "#21222C"
    labelBoxBorderColor: "#D6BCFA"
    labelTextColor: "#F8F8F2"
  themeCSS: "text.actor tspan{font-size:13px;font-weight:600}.messageText{font-size:12px;font-weight:500}.noteText{font-size:12px}.loopText,.labelText{font-size:12px;font-weight:500}.messageLine0{stroke-width:2px}.messageLine1{stroke-width:1.5px;stroke-dasharray:4 6}.actor{stroke-width:1.5px}rect.actor{filter:none!important}[id$='-filled-head'] path{fill:#FF79C6;stroke:#FF79C6}"
---
sequenceDiagram
    accTitle: Bridge wire exchange
    accDescr: The app host dispatching a certified frame through the bridge wire to the host app, with a timeout break, a bounded reply-stream loop, a mandatory trailer drain with its fault option, a rejected alternative, an async telemetry send, and the frame shape noted over the wire.
    autonumber
    box rgb(33, 34, 44) APP PROCESS
        participant C as AppHost composer
        participant W as Bridge wire
    end
    participant R as Host app
    Note over C,W: Frame { contentKey, payload }
    C->>W: Request(Frame)
    break wire timeout
        W-->>C: TimeoutFault
    end
    rect rgb(33, 34, 44)
        W->>R: Dispatch(Frame)
        activate R
        alt resolved
            loop reply stream [chunk <= max]
                R-->>W: FrameChunk
                W-->>C: FrameChunk
            end
            critical drain trailer
                R-->>W: EvidenceCertificate
                W-->>C: EvidenceCertificate
            option trailer fault
                R-->>W: FaultRow
                W-->>C: FaultRow
            end
        else rejected
            R-->>W: FaultRow
            W-->>C: FaultRow
        end
        deactivate R
    end
    R--)C: telemetry(receipt)
```

Refill by renaming the participants to the real boundary pair; an async fire-and-forget rides `--)` and expects no return, and a unary exchange drops the stream loop while keeping the trailer's `critical`/`option` pair wherever a mandatory step can fault. Frontmatter micro-scale `themeCSS` stamp, the ruled mono stack, and the `-filled-head` marker stamp are fixed law — a refill renames participants, never strips the fidelity surface.
