# [LOGIC_FLOW]

Draw one operation's dispatch structure: input discrimination fanning to arms, arms folding into one merge, the merge yielding a receipt. The template bakes in the polymorphic-collapse law — variation lives in the arms and never in parallel exits, so every arm folds back to the single receipt path — plus three load-bearing moves an unassisted attempt omits: the discriminator reads its arms from a policy store, making dispatch table-driven rather than hardcoded branching; the content key gates a cache short-circuit so the hot path is visible; and evidence feeds the fold on a dotted trace so the receipt is auditable. Use `flowchart LR` with 8-12 nodes, one rhombus discriminator whose out-labels are exhaustive and disjoint, and three-or-more arms; the receipt is classed `success` with its delivery edges on the Green rail, stores are classed `data`, and every dotted trace rides the Comment rail — a trace annotates the fold, so its stroke leaves the Pink control default. Ordered steps across a boundary are a wire-sequence, never a dispatch fold.

```mermaid
---
config:
  theme: base
  look: classic
  layout: elk
  flowchart:
    curve: linear
    padding: 25
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    background: "#282A36"
    primaryColor: "#44475A"
    primaryTextColor: "#F8F8F2"
    primaryBorderColor: "#BD93F9"
    lineColor: "#FF79C6"
    textColor: "#F8F8F2"
    edgeLabelBackground: "#21222C"
    labelBackgroundColor: "#21222C"
  themeCSS: ".nodeLabel{font-size:13px;font-weight:500}.edgeLabel{font-size:12px;font-weight:500}.cluster-label .nodeLabel{font-size:13.5px;font-weight:700;letter-spacing:.08em}.edge-thickness-normal{stroke-width:2px}.edge-thickness-thick{stroke-width:3px}.edge-pattern-dashed,.edge-pattern-dotted{stroke-width:1.5px;stroke-dasharray:4 6}.node rect,.node circle,.node polygon,.node path,.node .outer-path{stroke-width:1.5px;filter:none!important}.cluster rect{stroke-width:1px!important;stroke-dasharray:5 4!important;filter:none!important}.marker path{transform:scale(.8);transform-origin:5px 5px}.marker circle{transform:scale(.48);transform-origin:5px 5px}.edgeLabel rect{transform-box:fill-box;transform-origin:center;transform:scale(1.1,1.2)}"
---
flowchart LR
    accTitle: Solve dispatch and fold
    accDescr: One compute entry discriminating input shape into three policy-selected arms behind a content-key cache, folding into a merge that yields one solver receipt, with a dotted evidence trace feeding the fold.
    In([SolveRequest]) -->|"content key"| Hit{Cached?}
    Hit -->|"hit"| Fold
    Hit -->|"miss"| Shape{Shape?}
    Policy[(Policy rows)] -.->|"selects arms"| Shape
    Shape -->|"single"| ArmA[Solve one]
    Shape -->|"batch"| ArmB[Solve batch]
    Shape -->|"stream"| ArmC[Solve stream]
    ArmA --> Fold[Fold]
    ArmB --> Fold
    ArmC --> Fold
    Fold --> Receipt[/SolveReceipt/]
    Evidence[(Evidence)] -.->|"trace"| Fold
    linkStyle 1 stroke:#50FA7B,color:#F8F8F2
    linkStyle 3,11 stroke:#6272A4,color:#F8F8F2,stroke-width:1.5px,stroke-dasharray:4 6
    linkStyle 10 stroke:#50FA7B,color:#F8F8F2
    classDef primary fill:#44475A,stroke:#FF79C6,color:#F8F8F2
    classDef success fill:#50FA7BBF,stroke:#50FA7B,color:#282A36
    classDef data fill:#FFB86CBF,stroke:#FFB86C,color:#282A36
    classDef boundary fill:#282A36,stroke:#BD93F9,color:#F8F8F2
    class ArmA,ArmB,ArmC,Shape,Hit primary
    class Receipt success
    class Policy,Evidence data
    class In,Fold boundary
```

The arm labels are the input-shape vocabulary — rename them to the real discriminants and keep them exhaustive; a new capability is a new arm row, never a second exit after the fold. The cache short-circuit rides the Green rail because it delivers the same receipt. Trace edges keep the Comment rail: recount the `linkStyle` indices after any edge insertion. The frontmatter micro-scale `themeCSS` stamp, the ruled mono stack, and the `#21222C` edge-label backing are fixed law — a refill renames content, never strips the fidelity surface.
