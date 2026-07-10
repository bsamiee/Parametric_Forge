# [<pkg-token>_<page-token>]

<page-charter-lead-1-3-sentences>

## [01]-[INDEX]

- [01]-[<cluster-token>]: <route-hook-mechanism-owner>
- [02]-[SHAPE_FOLD]: the shape-op fold, its case vocabulary, and the content-keyed receipt

## [02]-[<cluster-token>]

- Owner: <owner-mint-and-invariant>
- Cases: <cases-bounded-vocabulary-earned>
- Entry: <entry-polymorphic-earned>
- Auto: <auto-internalized-machinery-earned>
- Receipt: <receipt-typed-case-earned>
- Packages: <packages-admitted-composed>
- Growth: <growth-one-row-rule>
- Boundary: <boundary-refusal>

```<lang> signature
<owner-signature-transcription>
```

## [03]-[SHAPE_FOLD]

- Owner: `ShapeFold` mints the one shape-op entry and owns op dispatch
- Cases: `ShapeOp` cases Refine, Merge, and Split
- Entry: `apply` discriminates single, batch, and stream by input shape
- Receipt: `ShapeReceipt.contribute` folds evidence into the run
- Packages: `shape-core` for the refinement kernel
- Growth: a new op is one `ShapeOp` case plus one dispatch arm
- Boundary: this owner refuses wire decode, deferred to the codec seam

```python signature
class ShapeFold:
    def apply(self, op: ShapeOp) -> Result[ShapeReceipt, ShapeFault]: ...
```

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
  themeCSS: ".nodeLabel{font-size:13px;font-weight:500}.edgeLabel{font-size:12px;font-weight:500}.edge-thickness-normal{stroke-width:2px}.node rect,.node circle,.node polygon,.node path,.node .outer-path{stroke-width:1.5px;filter:none!important}.marker path{transform:scale(.8);transform-origin:5px 5px}.edgeLabel rect{transform-box:fill-box;transform-origin:center;transform:scale(1.1,1.2)}"
---
flowchart LR
    accTitle: Shape fold dispatch
    accDescr: One shape-op entry discriminating op cases into kernel arms that fold into one receipt on the delivery rail.
    In([apply]) -->|"[SHAPE]: ShapeOp"| Op{Op?}
    Op -->|"refine"| ArmA[Refine]
    Op -->|"merge"| ArmB[Merge]
    Op -->|"split"| ArmC[Split]
    ArmA --> Fold[Fold]
    ArmB --> Fold
    ArmC --> Fold
    Fold -->|"[RECEIPT]: ShapeReceipt"| Receipt[/ShapeReceipt/]
    linkStyle 7 stroke:#50FA7B,color:#F8F8F2
    classDef primary fill:#44475A,stroke:#FF79C6,color:#F8F8F2
    classDef success fill:#50FA7BBF,stroke:#50FA7B,color:#282A36
    classDef boundary fill:#282A36,stroke:#BD93F9,color:#F8F8F2
    class Op,ArmA,ArmB,ArmC primary
    class Receipt success
    class In,Fold boundary
```

## [04]-[RESEARCH]

- [<research-token>]-[OPEN|BLOCKED]: <exact-question-plus-verification-route>
- [SPLIT_MEMBER]-[OPEN]: does `shape-core` expose `split_all`; verify against the member rail.
