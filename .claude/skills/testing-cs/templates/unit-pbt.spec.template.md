# [H1][CSHARP_UNIT_PBT_SPEC_TEMPLATE]
>**Dictum:** *One generated law should hit many independent axes.*

<br>

[IMPORTANT] Replace placeholders, keep normal specs near 175 LOC (225 with grace, 300 exceptional only when every line buys an oracle), and move host-native behavior to the repo runtime scenario rail. Lead with polymorphic patterns from [density-axes.md `[4]`](../references/density-axes.md); fall back to per-case Facts only when oracle differs per case.

---
## [VARIANT_1] Polymorphic-first spec (the default)

For source owners with a SmartEnum / Union case set:

```csharp
using <DomainNamespace>;
using <TestKitNamespace>;
using <MathNamespace>;

namespace <TestNamespace>;

// --- [CONSTANTS] ----------------------------------------------------------------------------
internal static class <Source>Gens {
    public static readonly Op Key = Op.Of(name: "<source>-test");
    public static readonly Gen<<CaseType>> Case = Gen.OneOfConst<<CaseType>>([..<CaseType>.Items]);
    public static readonly Gen<<ValueObject>> Value = Gens.<FactoryRoutedValue>;
}

// --- [ALGEBRAIC] ----------------------------------------------------------------------------
public sealed class <Concept>Laws {

    // Pattern [4]/[10]: SmartEnum case sweep with per-case-self-consistency oracle.
    [Fact]
    public void CasesOwnKeysAndPerCaseInvariant() =>
        Spec.Cases(
            items: <CaseType>.Items,
            key: static item => item.Key,
            law: item => {
                Spec.Holds(condition: /* per-case invariant */, label: $"{item.Key}");
                Spec.Succ(item.Project<<Supported>>(source: <Fixture>, key: <Source>Gens.Key));
                Spec.Fail(item.Project<<Unsupported>>(source: <Fixture>, key: <Source>Gens.Key));
            });

    // Pattern [12]/[18]: metamorphic transform bundle — one generated input, multiple invariants.
    [Fact]
    public void MetamorphicTransformsHoldOverSameInput() =>
        Spec.ForAll(<Source>Gens.<Input>, input => {
            TOutput translated = <Sut>(input.Translate(<delta>));
            TOutput scaled = <Sut>(input.Scale(<k>));
            TOutput original = <Sut>(input);
            Spec.Equal(translated.Point, original.Translate(<delta>).Point, tolerance: 1e-9, what: "translation invariance");
            Spec.Equal(scaled.Magnitude, <k> * original.Magnitude, tolerance: 1e-9, what: "scale invariance");
        });

    // Pattern [13]: reference loop oracle for numeric algorithms.
    [Fact]
    public void NumericMatchesIndependentReferenceLoop() =>
        Spec.ForAll(<Source>Gens.<MatrixInput>, m => {
            TMatrix actual = <Sut>(m);
            Numeric.<Operation>(rows: m.Rows.Value, cols: m.Cols.Value,
                expected: (i, j) => /* independent O(n³) loop */,
                actual: (i, j) => actual.At(i, j),
                tolerance: <ConditioningScaled>(m), label: "<sut>");
        });

    // Pattern [15]: distinct-value product generator catches transport swaps.
    [Fact]
    public void TransportPreservesDistinctChannels() =>
        Spec.ForAll(<Source>Gens.<DistinctTriple>, tuple => {
            (TValue a, TValue b, TValue c) = tuple;
            TResult result = <Sut>(a, b, c);
            Spec.Holds(result.A == a, "channel A");
            Spec.Holds(result.B == b, "channel B");
            Spec.Holds(result.C == c, "channel C");
        });
}
```

---
## [VARIANT_2] Theory-cased spec (per-case oracle differs)

When each case has a fundamentally different closed-form, use `[Theory]` + `MemberData` from `SmartEnum.Items`. Stryker treats each row as a separately-killable target.

```csharp
public sealed class <Concept>ClosedFormLaws {
    public static TheoryData<<CaseType>> AllCases() =>
        <CaseType>.Items.Fold(new TheoryData<<CaseType>>(), (data, item) => { data.Add(item); return data; });

    [Theory]
    [MemberData(nameof(AllCases))]
    public void EachCaseSatisfiesItsOwnClosedForm(<CaseType> item) =>
        Spec.ForAll(GenInputFor(item), input => {
            double expected = item.Key switch {
                "sphere" => input.Magnitude - input.Radius,
                "box" => /* box formula */,
                _ => throw new UnreachableException()
            };
            Spec.Equal(<Sut>(item, input), expected, tolerance: 1e-9, what: item.Key);
        });
}
```

---
## [VARIANT_3] Single-fixture / N-invariant spec (expensive construction)

When fixture construction dominates per-test cost:

```csharp
public sealed class <Concept>SpdMatrixInvariants {
    [Fact]
    public void OneSpdMatrixSatisfiesFiveInvariants() =>
        Spec.ForAll(<SpdGen>, m => {
            // Invariant 1: symmetric
            Numeric.Symmetric(dim: m.Dimension.Value, at: m.At, tolerance: 1e-12, "symmetric");
            // Invariant 2: positive trace
            Spec.Holds(m.Trace() > 0.0, "positive trace");
            // Invariant 3: positive determinant
            Spec.Holds(m.Determinant() > 0.0, "positive det");
            // Invariant 4: all eigenvalues > 0
            EigenPair[] pairs = m.DecomposeEigen();
            Spec.Holds(pairs.All(p => p.Eigenvalue > -<numeric-epsilon>), "eigenvalues positive");
            // Invariant 5: Cholesky succeeds
            Spec.Succ(m.DecomposeCholesky());
        });
}
```

---
## [VARIANT_4] Receipt-invariant spec (avoid stub-receipt anti-pattern)

When a receipt type encodes N conjunctive invariants, build the invariant table as `TheoryData<Receipt, bool>` — one valid row, each invariant individually broken. Avoid hand-constructing a receipt then asserting its own fields (Grade D mirror).

```csharp
public sealed class <Receipt>IsValidLaws {
    public static TheoryData<<Receipt>, bool> Receipts() {
        var valid = new <Receipt>(/* every invariant satisfied */);
        return new TheoryData<<Receipt>, bool> {
            { valid, true },
            { valid with { /* break invariant 1 */ }, false },
            { valid with { /* break invariant 2 */ }, false },
            // one row per conjunctive invariant
        };
    }

    [Theory]
    [MemberData(nameof(Receipts))]
    public void IsValidEncodesEveryInvariant(<Receipt> receipt, bool expected) =>
        Assert.Equal(expected, receipt.IsValid);
}
```

---
## [GENERATOR_RULES]

- Use `Gen.Where(predicate).Select(transform)` for filtered generators. Never `Select+throw` — `throw` breaks CsCheck shrinking (see [testkit.md `[5]`](../references/testkit.md)).
- Use distinct-value product generators (`(7.0, 13.0, 3.0)`) over symmetric placeholders (`(1.0, 1.0, 1.0)`) when channels matter.
- Route value-object construction through production `TryCreate`/`Create`; do not invent parallel constructors.
- Promote a generator to `_testkit/Gens.cs` only when ≥2 specs share the same domain shape.

## [FAILURE_RAIL_PATTERNS]

- `Spec.FailCategory<T>(result, "Input")` for category-stable diagnostics.
- `Spec.FailCode<T>(result, Fault.UnsupportedCode)` for stable error code rails.
- `Spec.FailMany<T>(result, expectedCount, "substring1", "substring2")` for accumulated Validation rails.
- `Spec.AllErrors(validation, "Input", "Tolerance")` for order-independent Validation Apply.
