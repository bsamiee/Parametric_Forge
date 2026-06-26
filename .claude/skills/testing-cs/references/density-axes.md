# [H1][DENSITY_AXES]
>**Dictum:** *Breadth comes from generated axes, not loose test count.*

<br>

## [01]-[PACKING]

| [INDEX] | [TECHNIQUE]           | [USE]                                                                                                          |
| :-----: | --------------------- | -------------------------------------------------------------------------------------------------------------- |
|  [01]   | Packed property body  | One `Spec.ForAll` asserts constructor, projection, unsupported output, and invariant rails for the same input. |
|  [02]   | Case generator        | `Gen.OneOfConst` over SmartEnum/union cases; assert key uniqueness and case semantics together.                |
|  [03]   | Product generator     | `a.Select(b, c, ...)` for law dimensions such as value/context/output.                                         |
|  [04]   | Edge-biased generator | Mix normal range with `0`, tolerance, `TwoPI`, `1`, non-finite, and tiny magnitudes.                           |
|  [05]   | Metamorphic transform | Generate `(input, transform)` and compare invariant/transformed outputs.                                       |
|  [06]   | Reference loop        | Small independent loop over rows/columns/items inside one generated matrix or sequence.                        |
|  [07]   | Receipt table         | Generate operation modes and assert typed receipt invariants in one pass.                                      |

---
## [02]-[COVERAGE_AXES]

Every owning spec should explicitly consider these axes:

| [INDEX] | [AXIS]            | [QUESTION]                                                                                          |
| :-----: | ----------------- | --------------------------------------------------------------------------------------------------- |
|  [01]   | Lines/branches    | Which source branches are static-managed and reachable?                                             |
|  [02]   | Public functions  | Does every public/internal API surface have at least one real law?                                  |
|  [03]   | Type cases        | Are all `[Union]`/`[SmartEnum]` cases enumerated or generated?                                      |
|  [04]   | Domain boundaries | Are minima/maxima/tolerances/non-finite/null/empty covered?                                         |
|  [05]   | Output directions | Are supported and unsupported `TOut` projections exercised?                                         |
|  [06]   | Failure rails     | Are `InvalidInput`, `InvalidResult`, `Unsupported`, and accumulated errors checked by stable shape? |
|  [07]   | Numeric stability | Are residuals, reconstruction, tolerance scaling, and rank/conditioning tested independently?       |
|  [08]   | Native ownership  | Is each native-dependent behavior represented by a bridge scenario?                                 |

---
## [03]-[LOC_TACTICS]

- Collapse repeated `Fact`s into one generated law when they share setup.
- Use local arrays for case tables; use `Spec.SmartEnumKeysUnique` for distinctness.
- Prefer `Spec.SuccValue` once per fixture object, then generated assertions over that object.
- Keep one-off expected values inline only when they are true mathematical constants.
- Promote only reusable generators and independent oracles to `_testkit`.
- Prefer product generators that vary mode, payload, output kind, and invalid edge together; this catches branch swaps with fewer lines than one fact per mode.
- Use local fixture geometry only when it is the independent model: asymmetric tetrahedra, a unit segment, one triangle, one square, diagonal matrices, and one-point probability plans often expose more bugs than large random fixtures.
- Raise the 175 LOC target only after collapsing repeated setup into arrays, `Spec.Cases`, `Spec.SmartEnumKeysUnique`, `Numeric`, or a two-consumer testkit primitive.
- Keep bridge classification concise in static specs; executable native success belongs in `*.verify.csx`, not in long static workarounds.
- Batch independent invariants (catalog multiplicities, fault category + type-pair) under `Assert.Multiple(() => …, …)` so every delta reports at once instead of stopping at the first failure. Use only for INDEPENDENT checks — never when one lambda's `Assert.IsType` result feeds the next.

---
## [04]-[POLYMORPHIC_PATTERNS]
>**Dictum:** *Reach for these before adding a second Fact that shares setup with an existing one.*

<br>

Ten base patterns that convert O(N) per-case Facts into O(1) generated laws:

| [INDEX] | [PATTERN]                                        | [WHEN]                                       | [TEMPLATE]                                                                                                       |
| :-----: | ------------------------------------------------ | -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
|  [01]   | SmartEnum case sweep via `T.Items`               | Closed catalog with per-case invariant       | `Spec.Cases(T.Items, key: m => m.Key, law: m => /* per-case oracle */)`                                          |
|  [02]   | Union case sweep via factory generator           | `[Union]` cases each with their own factory  | `Gen.OneOf(/* per-case factories */)` + single `Spec.ForAll` body with pattern match                             |
|  [03]   | State-threaded Switch as oracle table            | Production uses `[Union].Switch(state, ...)` | `Seq<(Case, ExpectedFn)>` walked once; spec body never calls `Switch`                                            |
|  [04]   | Product generator over (algo × input × output)   | Output type axis matters                     | `Gen.OneOfConst([..Items]).Select(InputGen, Gen.OneOfConst(OutputFamily), ...)`                                  |
|  [05]   | Variable-driven dispatch with dispatch-free body | Oracle is closed-form per case               | Oracle table maps case → closed-form; body has zero `switch`                                                     |
|  [06]   | Single fixture / N invariants                    | One construction is expensive                | One generated SPD matrix asserts orthogonality, trace, det, eigen-sum, Frobenius in one body                     |
|  [07]   | Theory-cased ForAll body                         | Algorithm rows + random inputs               | `[Theory] + [MemberData]` carries algorithm; `Spec.ForAll` inside body carries input                             |
|  [08]   | Reflection-driven `TheoryData(T.Items)`          | Maintenance-free per-case rows               | `static TheoryData<T> CasesOf() => T.Items.Fold(new TheoryData<T>(), ...)`, then `[MemberData(nameof(CasesOf))]` |
|  [09]   | Factory-routed generators                        | Value-objects with `TryCreate`               | `Where(Try).Select(Get)` preserves shrinking; never `Select+throw`                                               |
|  [10]   | Algorithmic O(1) Fact for O(N) impls             | N implementations of same concept            | Single Fact walks `T.Items` asserting per-case-self-consistency                                                  |

Nine torture-pattern extensions:

| [INDEX] | [PATTERN]                            | [WHEN]                                                                                           | [TEMPLATE]                                                                                                                                                                    |
| :-----: | ------------------------------------ | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|  [11]   | Algebraic trio generator             | Operator-rich algebra                                                                            | `Spec.ForAll(genT.Select(genT, genT), (a, b, c) => { /* associativity + distributivity */ })`                                                                                 |
|  [12]   | Metamorphic transform bundle         | Numeric algorithm with symmetries                                                                | One ForAll body asserts (translate, scale, permute) invariants over the same input                                                                                            |
|  [13]   | Reference loop oracle                | Matrix/vector algorithm                                                                          | Independent O(n³) loop over rows/cols/items inside the property body                                                                                                          |
|  [14]   | Generative oracle ladder             | Closed-form unknown                                                                              | Algebraic identity → metamorphic → smaller reference → conditioning fuzz                                                                                                      |
|  [15]   | Distinct-value product               | Transport / dispatch                                                                             | `Where`-enforced channel entropy: `(7.0, 13.0, 3.0)` over `(1.0, 1.0, 1.0)`                                                                                                   |
|  [16]   | Stratified edge-bias `Gen.Frequency` | Tail-of-distribution coverage                                                                    | 5-7 tier weights mixing zero, infinity, NaN, tolerance-adjacent with bulk-random                                                                                              |
|  [17]   | Conditioning-aware tolerance         | Floating-point algorithms                                                                        | Tolerance = `κ(A) × base` where conditioning comes from the input generator, not a constant                                                                                   |
|  [18]   | Composite MR chain                   | Multi-step pipeline                                                                              | `f(g(h(x))) ≡ permuted_chain(x)` over generated `(x, perm)`                                                                                                                   |
|  [19]   | Pre/post triple for stateful APIs    | `Atom` / `Validation` / `Fin` chains                                                             | Generated `(precondition, action, postcondition)` triples                                                                                                                     |
|  [20]   | `Spec.SmartEnumOutputCatalog`        | SmartEnum catalog whose per-case declared `Output` type is the invariant                         | Folds dense-key + uniqueness + per-case Output vs an independent `expectedOutput` table in one law (wraps `SmartEnumCatalogMatches`).                                         |
|  [21]   | `Spec.SupportMatrix`                 | Walls of `Assert.True/False(...IsSupported)` or capability probes (`AcceptsTarget`/`CanProject`) | Labeled `(Label, () => probe, Expected)` rows; thunks keep `<TGeom,TOut>` generics at the call site and each row names its own failure instead of an anonymous `Assert.True`. |

Worked example — composite MR chain:

```csharp
[Fact]
public void TransposeScalePermuteChainOrderInvariant() =>
    Spec.ForAll(matrixGen.Select(scalarGen, permutationGen), tuple => {
        var (M, k, perm) = tuple;
        var Mp = M.PermuteRows(perm);
        var Mps = Mp.Multiply(k);
        var Mpst = Mps.Transpose();
        var Mt = M.Transpose();
        var Mts = Mt.Multiply(k);
        var Mtsp = Mts.PermuteCols(perm);
        Numeric.Entrywise(M.Rows.Value, M.Cols.Value,
            (i, j) => Mpst.At(i, j), (i, j) => Mtsp.At(i, j),
            tolerance: 1e-7, "composite MR chain");
    });
```

When NOT to polymorphize:
- The *oracle statement* changes per case (distinct closed-form per primitive, different operator algebra, disjoint state machines).
- Number of cases is 2 and likely to stay at 2.
- Failure on one case must be visible as separately-tracked test ID for CI triage — use Theory rows.

---
## [05]-[COVERAGE_AXES_EXTENDED]

Beyond the base axes in `[2]`, two more axes apply to numeric algorithms:

| [INDEX] | [AXIS]                   | [QUESTION]                                                              |
| :-----: | ------------------------ | ----------------------------------------------------------------------- |
|  [09]   | Conditioning regimes     | Are well-conditioned, mildly-ill, and severely-ill inputs all sampled?  |
|  [10]   | Distinct-channel entropy | Do generator outputs carry distinct values per channel to expose swaps? |
