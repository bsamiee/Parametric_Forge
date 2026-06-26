# [H1][ORACLES_LAWS]
>**Dictum:** *The expected value must come from a different idea than the implementation.*

<br>

## [01]-[ORACLE_ORDER]

| [INDEX] | [ORACLE]                | [EXAMPLE]                                                                                |
| :-----: | ----------------------- | ---------------------------------------------------------------------------------------- |
|  [01]   | Algebraic identity      | Transpose involution, identity matrix, reflection length preservation.                   |
|  [02]   | External closed form    | Percentile interpolation, SDF primitive formula, row-major dot product.                  |
|  [03]   | Smaller reference model | `HashSet<T>` for custom set, array loops for matrix multiply, scalar ODE for streamline. |
|  [04]   | Metamorphic relation    | Translate/scale/permute input and assert invariant or transformed output.                |
|  [05]   | Typed receipt invariant | Stop kind, unsupported output, residual budget, convergence metadata.                    |
|  [06]   | Runtime observation     | Host-native validity, UI marshaling, document/canvas side effects.                       |

[CRITICAL] Do not use production `Matrix.operator *`, `Matrix.Determinant`, `CloudKernel.*`, or the same projection method as the expected-value engine for the method under test.

---
## [02]-[ORACLE_GRADE]

| [GRADE] | [ORACLE]                                                           | [USE]                                                                                                                                                                                                            |
| ------- | ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A       | Independent closed form, smaller model, or metamorphic relation    | Default target for core behavior.                                                                                                                                                                                |
| B+      | Independent algorithmic identity with conditioning-aware tolerance | Numeric algorithms where the tolerance scales with the input's condition number (`κ(A) × base`), not a hardcoded constant. The conditioning factor comes from the input generator, not the test author guessing. |
| B       | External library fact or independent scalar/reference loop         | Numeric and parsing rails.                                                                                                                                                                                       |
| C       | Typed receipt/category/code invariant                              | Failure and unsupported-output rails.                                                                                                                                                                            |
| D       | Structural assertion                                               | Supplemental shape proof only.                                                                                                                                                                                   |
| F       | Implementation mirror or current-output snapshot                   | Reject.                                                                                                                                                                                                          |

[CRITICAL]:
- Grade D is never the main oracle for a behavior owner. A factory shape check, non-null output check, or `typeof(TOut)` branch assertion must be paired with a closed form, smaller model, metamorphic law, or stable failure/category rail.
- A real oracle can be tiny: a one-triangle mesh, one-point transport plan, scalar ODE, diagonal matrix, row-major residual loop, or signed-distance formula is enough when it is independent from the production path.
- Product generators should carry distinct values through every field or output channel under test. This turns transport/dispatch tests into swap detectors instead of presence checks.
- Category rails are real value when the category is contractual: `Input`, `Tolerance`, `Result`, `Unsupported`, and `Operation` catch exception-shaped failures without overfitting exact prose.

---
## [03]-[LAW_MATRIX]

| [AXIS]           | [LAW]                                                                                         | [BUGS_CAUGHT]                                          |
| ---------------- | --------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| Construction     | Valid accepted, invalid rejected, non-finite rejected, diagnostics stable by category/code.   | Bad factory boundaries, accidental exception rails.    |
| Projection       | Accepted output succeeds, unsupported output fails, capability-gated output fails truthfully. | Wrong `typeof(TOut)` branch, capability drift.         |
| Algebra          | Identity, inverse, involution, associativity, commutativity, distributivity where true.       | Operator and fold regressions.                         |
| Order/statistics | Monotonicity, extrema ties, percentile interpolation, permutation invariance.                 | Sort/index/tolerance bugs.                             |
| Numeric          | Residual, reconstruction, rank, eigenpair, norm inequalities, conditioning guards.            | Circular linear algebra tests.                         |
| Rail             | `Fin` success/failure, `Validation` accumulation, `Option` some/none, `ManyErrors` shape.     | Swallowed diagnostics.                                 |
| Stateful         | Attach/detach, LIFO/FIFO, idempotence or named non-idempotence, rollback double fault.        | Lifecycle leaks and false monoids.                     |
| Runtime          | Static-vs-bridge classification, native validity, host/UI thread behavior.                    | Tests that pass outside the only runtime that matters. |

---
## [04]-[ANTI_PATTERNS]

- Snapshotting the current implementation output and asserting it later.
- Using one test per branch when one generated law can traverse the axis.
- Adjusting a test after failure before proving whether product code is wrong.
- Testing only happy-path construction while projection/unsupported rails remain untouched.
- Using broad `Assert.True` labels that hide the generated input and law.
- Adding a shared helper for one file instead of inlining or promoting a universal testkit primitive.
- Counting coverage from static specs by calling host-native methods that require host initialization.
- Reusing production projection/operators as expected-value engines under a different name.
- **Generator-mirror**: a generator-side filter that re-encodes a production predicate (e.g., `Gen.Where(v => MyEnum.Items.Contains(v))` when production `MyEnum.Items` is the catalog). The generator becomes the oracle's twin; mutations to the catalog are invisible.
- **Placeholder-fixture swap blindness**: single-value or symmetric fixtures (`(0, 0, 0)`, `UnitTriangle3` for X/Y transport) cannot detect swaps between channels. Use distinct-value product generators.
- **Equal-value channels**: `mass=[1.0, 1.0, 1.0]` cannot detect swap between any two slots. `mass=[1000.0, 7.0, 3.0]` exposes transport / dispatch bugs.
- **Tautological receipt-field self-assertion**: hand-constructing a record then asserting its own fields. The test reads what it just wrote.
- **Spec-class title/body mismatch**: copy-paste authoring against `oracles-laws.md [4]`. Rewrite must re-derive every law name from the law itself, not from a previous fact.
- **`throw` inside `Select`**: `Gen.Int.Select(v => v > 0 ? T(v) : throw ...)` breaks CsCheck shrinking. Use `Gen.Int.Where(v => v > 0).Select(v => T(v))`.
- **Hoisted `Op key` across `Switch` arms**: every `[Union].Switch` arm constructs `Op.Of(name: nameof(CaseName))` for diagnostic provenance.

---
## [05]-[POLYMORPHIC_ORACLE_RULES]

Cross-reference [density-axes.md `[4]`](density-axes.md) for the pattern catalog. Oracle-side rules that govern polymorphic specs:

- A polymorphic spec's oracle table is itself a contract — when a new SmartEnum/Union case is added, the oracle table must be extended in the same change. The architecture test (`Items.Count == OracleTable.Count`) catches drift.
- Per-case oracles in a `Spec.Cases(items, key, law)` body must each be independent of production — a case-specific closed form, a smaller model, or a metamorphic relation. If three of N cases share an oracle and the other N-3 are mirrors, the polymorphic structure hides Grade F coverage; split into two laws.
- When using `Theory + InlineData`, each row is a separately-tracked test ID and Stryker mutation target. Prefer Theory over PBT for SmartEnum case sweeps when the oracle differs per row.
