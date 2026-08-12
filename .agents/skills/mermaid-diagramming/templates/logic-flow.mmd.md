# [LOGIC_FLOW]

Draw one operation's dispatch structure: input discrimination fanning to arms, arms folding into one merge, the merge yielding a receipt. Template law bakes in the polymorphic-collapse law — variation lives in the arms and never in parallel exits, so every arm folds back to the single receipt path — and four load-bearing moves an unassisted attempt omits: the discriminator reads its arms from a policy store, making dispatch table-driven rather than hardcoded branching; the content key gates a cache short-circuit; every arm can reject onto one fault rail whose convergence point states the recovery law once, and the rail rejoins the fold so a fault still yields the one receipt; and evidence feeds the fold on a dotted trace so the receipt is auditable. Use `flowchart LR` with two rhombi — a cache gate feeding one arm discriminator, each with exhaustive, disjoint out-labels — and three-or-more arms. Ordered steps across a boundary are a wire-sequence, never a dispatch fold.

```mermaid
---
config:
  layout: elk
  flowchart:
    curve: linear
    padding: 25
---
flowchart LR
    accTitle: Solve dispatch and fold
    accDescr: One compute entry discriminating input shape into three policy-selected arms behind an animated content-key cache short-circuit, arm rejects converging on one red fault rail that rejoins the fold, and a dotted evidence trace feeding the single solver receipt.
    In([SolveRequest]) -->|"content key"| Hit{Cached?}
    Hit e1@-->|"hit"| Fold
    Hit -->|"miss"| Shape{Shape?}
    Policy[(Policy rows)] e2@-.->|"selects arms"| Shape
    Shape -->|"single"| ArmA[Solve one]
    Shape -->|"batch"| ArmB[Solve batch]
    Shape -->|"stream"| ArmC[Solve stream]
    ArmA --> Fold[Fold]
    ArmB --> Fold
    ArmC --> Fold
    ArmA e3@-.->|"reject"| Fault[/Fault rail/]
    ArmB e4@-.->|"reject"| Fault
    ArmC e5@-.->|"reject"| Fault
    Fault e6@-->|"fault row"| Fold
    Fold e7@--> Receipt[/SolveReceipt/]
    Evidence[(Evidence)] e8@-.->|"trace"| Fold
```

Arm labels are the input-shape vocabulary — rename them to the real discriminants and keep them exhaustive; a new capability is a new arm row, never a second exit after the fold. Node budget of 8-12 holds at three arms — past four, drop the cache or evidence furniture or extract an arm subflow into its own fence, because 2N converging arm edges break the crossing floor before the node ceiling.
