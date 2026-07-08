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
  layout: elk
  look: neo
  theme: base
---
flowchart LR
    accTitle: Shape fold dispatch
    accDescr: One shape-op entry dispatching cases to the refinement kernel and folding a receipt.
    Apply[apply] -->|"[SHAPE]: ShapeOp"| Dispatch{{dispatch}}
    Dispatch -->|"[RECEIPT]: ShapeReceipt"| Fold[contribute]
    classDef entry fill:#44506b,stroke:#8b9bc4,color:#ffffff
    class Apply,Dispatch,Fold entry
```

## [04]-[RESEARCH]

- [<research-token>]-[OPEN|BLOCKED]: <exact-question-plus-verification-route>
- [SPLIT_MEMBER]-[OPEN]: does `shape-core` expose `split_all`; verify against the member rail.
