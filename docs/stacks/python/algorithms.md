# [PYTHON_ALGORITHMS]

Numeric work is admitted once and routed by operand shape. Raw arrays cross into a finite-checked owner at one boundary, the interior is total over admitted operands, and the operand's structure — definite, square, overdetermined, symmetric, nonsymmetric, sparse-pattern, periodic-grid — selects the owning factorization through one route-keyed policy row, never the call site and never a knob beside the matrix. Every solve is the one composed `admit -> route -> solve -> witness -> receipt` lifecycle written once; a per-module pipeline re-deriving the chain is the rejected form.

Every library refuses its own gates — no constructor checks finiteness, array arithmetic returns `nan`/`inf` silently, a near-singular solve yields a garbage vector with no signal, an exact-`==` symmetry test fails on an accumulation-built matrix — so admission re-imposes each refused gate as one explicit predicate. Every result leaves as a frozen `msgspec.Struct` receipt carrying its route case, the scale-derived tolerance it was gated against, and the recomputed true relative residual against the original operator, never a raw `ndarray` or factorization handle.

## [01]-[ROUTE_SPINE]

The operand shape selects the route before any solve; the most specific shape wins, and the table is one lifecycle's route step, never a family of pipelines.

| [INDEX] | [OPERAND_SHAPE]                        | [OWNING_ROUTE]                                 | [CONDITIONING_FALLBACK]                   |
| :-----: | :------------------------------------- | :--------------------------------------------- | :---------------------------------------- |
|  [01]   | dense symmetric positive-definite      | dense Cholesky factor, held, SPD assumption    | shift `ε·I`, then the symmetric spectrum  |
|  [02]   | dense square general                   | dense pivoted LU factor, held                  | rank-revealing pseudo-inverse             |
|  [03]   | dense overdetermined                   | SVD-based least-squares over the normal form   | truncated SVD pseudo-inverse              |
|  [04]   | symmetric or Hermitian spectrum        | symmetric eigensolver, index-banded subset     | generalized eigensolver on the pair       |
|  [05]   | nonsymmetric spectrum                  | general eigensolver, Schur-pair decode         | residual witness, no resort               |
|  [06]   | rank, norm, or condition evidence only | one retained `numpy.linalg.svd` handle         | the one handle answers all three          |
|  [07]   | sparse SPD or symmetric, fixed pattern | sparse direct factor, held; fill read first    | conjugate-gradient while pattern unproven |
|  [08]   | sparse nonsymmetric, fixed pattern     | sparse direct factor, held                     | restarted Krylov + witness gate           |
|  [09]   | huge sparse or changing pattern        | matrix-free Krylov, incomplete-LU precondition | verdict-routed sparse direct solve        |
|  [10]   | symbolic operator, repeated evaluation | one `"numpy"`-lowered kernel, evaluated dense  | dense route on the lowered callable       |

Recover the fallback from the route value and record it on the receipt, never a caller-named entrypoint: a fill ratio (symbolic factor nonzeros over input nonzeros, read from the held sparse factor before the numeric sweep) routes direct versus iterative, and the regularized least-squares case (the design matrix stacked over a `√λ`-scaled identity) is the derived consequence of the conditioning budget exceeding the inverse cap. The fallback is a rebind onto the same lifecycle: primary and conditioning routes converge on the one witness gate, and the receipt records the taken path. The per-member factorization surface — the held-factor tuple, the assumption flag, the index-band, the incomplete-LU operator — is the companion band's depth applied at the compute boundary; this table fixes which substrate and which algebraic shape the operand selects.

[ROUTE_UNION]:
- Law: the `Route` `StrEnum` is the one closed vocabulary over every operand shape the route table lists — definite, square, overdetermined, spectral, nonsymmetric, evidence, sparse-direct, sparse-iterative, symbolic — and the receipt's sole route discriminant, so a new substrate lands as one member, each `Route`-keyed table gains one row, and the receipt carries the taken path. The dense spine `solved` serves the six dense members while the sparse and symbolic members thread their own held factor and lowered callable through the shared witness, so one vocabulary spans every route and no parallel route type forms beside it.
- Law: the operand is the spine's own admitted `np.ndarray` argument, never a case payload, because every dense route carries the identical operator shape; what varies per route is policy — the post-solve admission `Gate`, the `Scale` the tolerance derives from, and the pre-solve conditioning `Probe` — bundled as one `RoutePolicy` frozen owner in one `frozendict[Route, RoutePolicy]` the spine reads by the route key. A `conditioned: bool` re-selecting the probe body is the rejected knob; the `Probe` value carries it.
- Law: the solver is the companion factorization injected as a second `frozendict[Route, Solver]` filled at the compute boundary — the one legitimate split from `RoutePolicy`, because the dense-Cholesky, pivoted-LU, least-squares-SVD, and eigensolver members are dependency-gated off-wheel while the gate-scale-probe bundle is pure — so the in-wheel `numpy.linalg` one-shot members and the companion `scipy.linalg` held factors enter through the one injection seam the spine never branches on.
- Law: every `Route`-keyed table is total over its domain by construction, so an unrouted operand is the classifier's fault projected to `Result` at the seam; static `match` exhaustiveness rides the one genuinely heterogeneous owner `SolveTerminal`, whose three cases carry distinct payloads the spine consumes, never a uniform-payload union the tag alone indexes.
- Reject: a `compute_vectors: bool`, `mode: str`, or `sym: bool` parameter riding beside the matrix — a parallel knob re-describing the input is arity smuggled back; sibling `solve_spd`/`solve_general`/`solve_lstsq` functions where one routed dispatch discriminates on the operand; a second route-keyed `frozendict` per pure-policy axis where one `RoutePolicy` row carries the bundle; a `FactorRoute` tagged union whose six cases each carry one `np.ndarray` and whose claimed exhaustiveness no spine `match` realizes — the `Route` key into the policy and solver tables is denser than a tag-only shape read by `getattr`.
- Boundary: the spine's terminal `bind` lands in the `witnessed` receipt core the witness layer owns, so `solved` returns `Result[SolveReceipt, SolveFault]` and the residual is computed exactly once at that terminus, never a second time here; the element carrier is `numpy` `float64`, admission narrows the dtype and asserts C-contiguity once, and the interior never re-checks either.

```python conceptual
from collections.abc import Callable
from dataclasses import dataclass
from enum import StrEnum
from typing import Literal

import numpy as np
from builtins import frozendict
from expression import Error, Ok, Result

type SolveFault = Literal[
    "<nan>",
    "<inf>",
    "<non-finite>",
    "<singular>",
    "<rank-deficient>",
    "<residual-exceeded>",
    "<stalled>",
    "<broken>",
    "<wrong-arity>",
    "<broken-symmetry>",
    "<contract>",
]
type Solver = Callable[[np.ndarray, np.ndarray], tuple[np.ndarray, int]]
type Gate = Callable[[np.ndarray, np.ndarray, int], Result[np.ndarray, SolveFault]]
type Probe = Callable[[np.ndarray, float], Result[np.ndarray, SolveFault]]


class Route(StrEnum):
    DEFINITE = "definite"
    SQUARE = "square"
    OVERDETERMINED = "overdetermined"
    SPECTRAL = "spectral"
    NONSYMMETRIC = "nonsymmetric"
    EVIDENCE = "evidence"
    SPARSE_DIRECT = "sparse-direct"
    SPARSE_ITERATIVE = "sparse-iterative"
    SYMBOLIC = "symbolic"


@dataclass(frozen=True, slots=True, kw_only=True)
class RoutePolicy:
    scale: "Scale"
    gate: Gate
    probe: Probe


def ranked(a: np.ndarray, x: np.ndarray, rank: int, /) -> Result[np.ndarray, SolveFault]:
    return Ok(x) if rank >= a.shape[1] else Error("<rank-deficient>")


PASS: Gate = lambda _a, x, _rank: Ok(x)
WAIVE: Probe = lambda a, _cap: Ok(a)
POLICY: frozendict[Route, RoutePolicy] = frozendict({
    Route.DEFINITE: RoutePolicy(scale=Scale.OPERATOR_RHS, gate=PASS, probe=conditioned),
    Route.SQUARE: RoutePolicy(scale=Scale.OPERATOR_RHS, gate=PASS, probe=conditioned),
    Route.OVERDETERMINED: RoutePolicy(scale=Scale.SINGULAR_DIM, gate=ranked, probe=WAIVE),
    Route.SPECTRAL: RoutePolicy(scale=Scale.OPERATOR_RHS, gate=PASS, probe=WAIVE),
    Route.NONSYMMETRIC: RoutePolicy(scale=Scale.OPERATOR_RHS, gate=PASS, probe=WAIVE),
    Route.EVIDENCE: RoutePolicy(scale=Scale.SINGULAR_DIM, gate=PASS, probe=WAIVE),
})


def solved(route: Route, operand: np.ndarray, solvers: frozendict[Route, Solver], b: np.ndarray, cap: float, /) -> Result["SolveReceipt", SolveFault]:
    policy = POLICY[route]
    return (
        admitted(operand)
        .bind(lambda m: policy.probe(m, cap))
        .bind(lambda m: policy.gate(m, *solvers[route](m, b)).bind(lambda x: witnessed(route, m, x, b, scaled(policy.scale, m, b))))
    )
```

## [02]-[ADMISSION_GATES]

[FINITE_ADMISSION]:
- Law: gate every operand on one all-finite predicate over the flat array before factoring — `numpy.isfinite(a).all()` in a single vectorized pass — and split the typed rejection into a NaN-any then Inf-any cause only when the failure is real; no factorization rejects `nan`/`inf`, a non-finite entry propagates silently into a corrupted factor, and a Python-level per-element loop forfeits the one-pass vectorized admission the contiguous layout grants.
- Law: admission narrows the dtype to `float64` and forces C-contiguity once through `numpy.ascontiguousarray`, because a strided or object-dtype operand silently degrades every downstream BLAS call to a slow Python path; the narrowed array is the admitted operator the whole lifecycle threads.
- Reject: trusting a constructor; re-checking finiteness inside the interior; `numpy.nan_to_num` substituting a value for a non-finite entry instead of rejecting it.

[SYMMETRY_AND_SINGULAR]:
- Law: force symmetry with `(a + a.T) * 0.5` (`a.conj().T` for Hermitian) before the symmetric route; an exact float `==` symmetry test fails on an accumulation-built matrix, and a one-ULP mirror difference routes to the nonsymmetric path whose spectrum acquires spurious complex pairs. The SPD route reads only one triangle, so symmetrize first and never substitute a separate eigenvalue probe for the guarantee.
- Law: probe singularity through `numpy.linalg.cond(a)` against a scale-relative cap, never a determinant — a pivoted LU on a singular operand returns a finite garbage factor and never raises, and the determinant underflows to `0.0` with no signal. Read a genuinely needed determinant as the streaming log form `2·Σ log|L_ii|` from the Cholesky factor or `Σ log|U_ii|` from the LU factor; the plain product underflows and its logarithm is `-inf`.
- Law: read the least-squares solution rank against the expected column count and reject a deficiency; a rank-deficient design matrix returns a minimum-norm solution silently, and the returned rank is the only signal. The SVD-based least-squares route is the admitted form over the normal equations in near-dependent columns, because the normal equations square the condition number.
- Boundary: guard `numpy.linalg.cond` against `+inf` before gating; it is `+inf` for a rank-deficient operator and a comparison against it always fails closed.

```python conceptual
import numpy as np
from expression import Error, Ok, Result


def admitted(a: np.ndarray, /) -> Result[np.ndarray, SolveFault]:
    m = np.ascontiguousarray(a, dtype=np.float64)
    flat = m.reshape(-1)
    return Ok(m) if np.isfinite(flat).all() else Error("<nan>") if np.isnan(flat).any() else Error("<inf>")


def conditioned(a: np.ndarray, cap: float, /) -> Result[np.ndarray, SolveFault]:
    kappa = float(np.linalg.cond(a))
    return Error("<singular>") if not np.isfinite(kappa) or kappa > cap else Ok(a)
```

## [03]-[TOLERANCE_AND_HELD_HANDLE]

[SCALE_DERIVED_TOLERANCE]:
- Law: every threshold is one of two derivation forms over operator and right-hand-side scale — `Scale.OPERATOR_RHS` is `ε·‖A‖_F·max(‖b‖∞, 1)` for a square solve, `Scale.SINGULAR_DIM` is `ε·σ_max·max(shape)` for the least-squares rank floor reading `σ_max` off the held SVD — closed in one `Scale` vocabulary and projected by one `scaled(form, a, b)`, never a per-route `frozendict[Route, Callable]` whose definite and square rows duplicate one body; the route's `Scale` member rides its `RoutePolicy` row so the derivation is the policy axis the spine already threads, and `solved` reads `scaled(policy.scale, m, b)` at the one terminus. A bare per-module absolute literal in `1e-4..1e-8` is unreplayable and uncomparable across operators, the rejected form, and a fresh literal per call site is the same defect spelled inline; the derived scalar carries onto the receipt as the tolerance the witness gated against.
- Law: recompute domain rank as `count(σ_i > ε_rank · σ_max)` with a caller-supplied relative `ε_rank`; the LAPACK default rank cut misclassifies significant singular values for an operator with `‖A‖₂ ~ 10⁶`.

[HELD_HANDLE]:
- Law: retain one factorization handle for streamed right-hand sides — the held factor the route names returns its factor tuple once and each solve is one triangular back-substitution; the held factorization enters the interior as one `Solve` closure bound at the compute boundary, and a loop of fresh factorizations is cubic per call where the held handle is quadratic. The plural right-hand-side modality is the `T | Iterable[T]` arity the dispatch owner normalizes, mapped over this one held `Solve`, never a re-factor per vector.
- Law: retain one thin `numpy.linalg.svd` factorization for rank, 2-norm (`s[0]`), and condition (`s[0]/s[-1]`); each separate query otherwise rebuilds the cubic decomposition, while the induced `numpy.linalg.norm` reductions stay quadratic, touching no decomposition. The held `s[0]` is the evidence route's `σ_max`, so a route that already factored reads its tolerance off the retained `s`, while the standalone rank-floor form derives `σ_max` through the dedicated `numpy.linalg.svdvals(a)[0]` once.
- Law: form the iterative-refinement residual against the original operator in working precision (`b - a @ x`), never against reconstructed factors — the factors carry exactly the rounding error the correction exists to cancel — and thread the correction as one `expression.Block.fold` over a fixed budget, never a mutating loop; the `correct` step closes over the held `Solve` and reuses it across every back-substitution, a closure the fold drives, never a re-bind.
- Reject: `numpy.linalg.inv` in a hot loop — it factors plus solves against an identity; solve against the held handle with reused buffers.

```python conceptual
from collections.abc import Callable
from enum import StrEnum

import numpy as np
from builtins import frozendict
from expression import Error, Ok, Result
from expression.collections import Block

type Solve = Callable[[np.ndarray], np.ndarray]


class Scale(StrEnum):
    OPERATOR_RHS = "operator-rhs"
    SINGULAR_DIM = "singular-dim"


_EPS: float = float(np.finfo(np.float64).eps)
FORM: frozendict[Scale, Callable[[np.ndarray, np.ndarray], float]] = frozendict({
    Scale.OPERATOR_RHS: lambda a, b: _EPS * float(np.linalg.norm(a)) * max(float(np.linalg.norm(b, np.inf)), 1.0),
    Scale.SINGULAR_DIM: lambda a, b: _EPS * float(np.linalg.svdvals(a)[0]) * max(a.shape),
})


def scaled(form: Scale, a: np.ndarray, b: np.ndarray, /) -> float:
    return FORM[form](a, b)


def refined(a: np.ndarray, held: Solve, b: np.ndarray, x: np.ndarray, tol: float, cap: int, /) -> Result[np.ndarray, SolveFault]:
    b_inf = max(float(np.linalg.norm(b, np.inf)), np.finfo(np.float64).tiny)
    ratio = lambda residual: float(np.linalg.norm(residual, np.inf)) / b_inf

    def correct(state: np.ndarray, _: int, /) -> np.ndarray:
        residual = b - a @ state
        return state if ratio(residual) <= tol else state + held(residual)

    settled = Block.range(cap).fold(correct, x)
    final = ratio(b - a @ settled)
    return Error("<non-finite>") if not np.isfinite(final) else Ok(settled) if final <= tol else Error("<stalled>")
```

## [04]-[SPARSE_AND_ITERATIVE]

[SPARSE_ROUTE]:
- Law: a fixed-pattern sparse operator factors once through the companion `scipy.sparse.linalg` direct factor at the compute boundary and reuses the held object for every right-hand side; the held factor's nonzero count over the input nonzero count is the fill ratio read before the numeric sweep, and a fill ratio above the budget routes to an iterative solve instead.
- Law: an iterative solve — conjugate-gradient for SPD, a restarted-Krylov mirror otherwise — carries its convergence criterion as the call's relative and absolute residual bounds and its iteration ceiling, returns an `(x, info)` verdict pair, and a nonzero `info` is a non-convergence fault routed to the verdict-gated direct fallback, never a silently accepted partial iterate; this `(x, info)` contract is where the choice turns, so the page fixes it while the per-solver member rides the companion owner.
- Law: a preconditioner is the matrix-free linear operator passed through the solver's preconditioner slot; an incomplete-LU factor lowered to that operator is the standard accelerant and rides the route value, never a global default.
- Reject: rebuilding the sparse factorization per right-hand side; accepting an iterative iterate without checking the verdict code; densifying a sparse operator to reuse the dense route.

[TERMINAL_PARTITION]:
- Law: partition the solver terminus through an `@tagged_union` `SolveTerminal` over `admitted | exhausted | broken`, mapping the `(x, info)` verdict onto one case — converged to `admitted`, count-exhausted to `exhausted` carrying the partial iterate and the binding budget, breakdown to `broken` — so the relaxed-criterion or direct-solve retry reads the residual budget off the value rather than re-running the solve.
- Law: the breakdown semantics are a solver-kind property, not a call-site flag: the same near-zero inner-product denominator throws in one solver, cancels the iterate in a second, and substitutes `1` and continues in a third, so the terminus case is read from the solver identity and the witness gate is the only signal that survives the substitution path.
- Reject: collapsing count-exhaustion into the failure rail — it destroys the caller's seeded-direct retry; accepting the substitution iterate under a converged verdict without the independent residual witness.

```python conceptual
from typing import Literal, assert_never

import numpy as np
from expression import Error, Ok, Result, case, tag, tagged_union


@tagged_union(frozen=True)
class SolveTerminal:
    tag: Literal["admitted", "exhausted", "broken"] = tag()
    admitted: np.ndarray = case()
    exhausted: tuple[np.ndarray, int] = case()
    broken: int = case()


def settled(verdict: SolveTerminal, witness: float, cap: float, /) -> Result[np.ndarray, SolveFault]:
    passed = np.isfinite(witness) and witness <= cap
    match verdict:
        case SolveTerminal(tag="admitted", admitted=x) | SolveTerminal(tag="exhausted", exhausted=(x, _)):
            return Ok(x) if passed else Error("<residual-exceeded>")
        case SolveTerminal(tag="broken"):
            return Error("<broken>")
        case never:
            assert_never(never)
```

## [05]-[WITNESS_AND_RECEIPT]

[RESIDUAL_WITNESS]:
- Law: every solve — dense, sparse, direct, iterative, primary, fallback — converges on one witness gate that recomputes the true relative residual `‖b - A·x‖ / ‖b‖` against the original operator and compares it to the scale-derived tolerance; this single signal survives preconditioning, breakdown substitution, cancellation, and provider divergence, and a solve that returns without passing the gate is the rejected form.
- Law: the witness reads the residual in the operator's own working precision and rejects a non-finite residual before comparing it to the tolerance; a `nan` residual compared with `<=` silently passes, so the finite check precedes the magnitude check, and the residual is computed exactly once per result — the gate returns it and the receipt carries that value, never a second recomputation.

[TYPED_RECEIPT]:
- Law: every result leaves as one frozen `msgspec.Struct` `SolveReceipt` carrying the route case as a `Route` member, the scale-derived tolerance it was gated against, and the recomputed residual — the numeric evidence this layer owns; it never carries the operator, the factorization handle, or an eagerly decoded solution array, because the numeric block is large and its decode is the consumer's choice. The solution defers as a `Raw` field: the contiguous-octet capture and the consumer's zero-copy `frombuffer` view are `numpy`'s own `ascontiguousarray(...).tobytes()` and reconstruction, this page's substrate, while the byte-identical opaque round-trip band is `boundaries.md`'s `msgspec.Raw` wire mechanic — this card fixes only which evidence the receipt holds.
- Law: the egress weave is the `aspected` factory `surfaces-and-dispatch.md` owns, composed over the pure witness core and never re-derived here: the in-process numeric interior carries no transient provider, so the spine weaves only the factory's fixed contract arm under one shared `BeartypeConf`, which lifts a `BeartypeCallHintViolation` through `lifted` onto `<contract>` — a malformed operand shape becomes a `SolveFault` member rather than an escaping exception, and a co-occurring concern lands as one more `Concern` entry with the body untouched. No `numpy.linalg.LinAlgError` capture rides this weave: the `<singular>` cap-against-`cond` gate at admission already precludes the near-singular factorization that raises it, so a re-catch at egress would re-impose a gate the interior owns once.
- Boundary: the receipt's scalar projection — route, tolerance, residual — is the `str | float` evidence a downstream span or structured-emission consumer reads, never the `Raw` solution bytes; the emission weave that consumes it is the domain observability owner's, this layer states only that the projection carries scalars and the solution stays bytes.

```python conceptual
import numpy as np
from beartype import BeartypeConf
from expression import Error, Ok, Result
from msgspec import Raw, Struct


class SolveReceipt(Struct, frozen=True, gc=False):
    route: Route
    tolerance: float
    residual: float
    solution: Raw


_CONTRACT = BeartypeConf(is_pep484_tower=True)


def attested(a: np.ndarray, x: np.ndarray, b: np.ndarray, tol: float, /) -> Result[tuple[np.ndarray, float], SolveFault]:
    residual = float(np.linalg.norm(b - a @ x)) / max(float(np.linalg.norm(b)), np.finfo(np.float64).tiny)
    return Error("<non-finite>") if not np.isfinite(residual) else Ok((x, residual)) if residual <= tol else Error("<residual-exceeded>")


@aspected(lifted=lambda _v: "<contract>", conf=_CONTRACT)
def witnessed(route: Route, a: np.ndarray, x: np.ndarray, b: np.ndarray, tol: float, /) -> Result[SolveReceipt, SolveFault]:
    framed = lambda ok: Raw(np.ascontiguousarray(ok, dtype=np.float64).tobytes())
    return attested(a, x, b, tol).map(lambda pair: SolveReceipt(route, tol, pair[1], framed(pair[0])))
```

## [06]-[COMPANION_ADMISSION]

The symbolic, dimensional, and uncertainty surfaces are the compute companion band produced at the boundary; this layer admits each produced value — a lowered callable, a dimension-stripped magnitude, a covariance-lifted estimate — into the `float64` interior under one admission law, never re-deriving the companion algebra and never threading a companion object through the BLAS hot path. The law is shared, the gate is shape-fitted: a callable crosses the finite-sample probe below, a stripped magnitude crosses the flat finite `admitted` gate the dense route already owns, and neither a `Quantity` nor an object-dtype error array reaches a BLAS call where it silently degrades the kernel dispatch to an object loop.

[SYMBOLIC_LOWERING]:
- Law: the `sympy` derivation route — differentiation, simplification, common-subexpression elimination, then lowering to a `"numpy"`-backend vectorized callable — produces one `Kernel` exactly once at the compute boundary, and a runtime derivative lowers with its primal in one tuple-lowering so value and gradient share one compiled kernel and one subexpression pass; this layer admits that produced callable under a finite-sample gate that rejects a `nan`/`inf`-producing derivation before it poisons the interior, then the admitted kernel enters the dense route as an ordinary operator. The `"numpy"` lowering target is named because it fixes the backend the admitted kernel runs on.
- Reject: symbolic per-sample evaluation in a loop; re-deriving the symbolic expression per call; admitting the lowered kernel without the finite-sample gate.

[DIMENSIONAL_AND_ERROR]:
- Law: the `pint` units route strips a dimensioned input to its canonical base-unit magnitude through one module-level registry before the stripped array crosses the `[02]` finite-admission gate, and the receipt re-attaches the unit on egress; the `uncertainties` route lifts a fit covariance into auto-propagating arithmetic strictly as a boundary-and-receipt concern. Both obey the one admission law under their own gate — the magnitude through the flat finite gate, the kernel through the finite-sample probe — so a `Quantity` or an object-dtype error array never reaches a BLAS call, where its `__array_ufunc__` dispatch defeats the float64 kernel.
- Reject: stringly-typed unit suffixes on field names; manual error-propagation arithmetic where the route derives the partials from its own shared-variable graph; mixing a dimensioned quantity or an uncertainty object into the dense factorization hot path.

```python conceptual
from collections.abc import Callable

import numpy as np
from expression import Error, Ok, Result

type Kernel = Callable[..., tuple[np.ndarray, np.ndarray]]


def admitted_kernel(lowered: Kernel, arity: int, /) -> Result[Kernel, SolveFault]:
    probe = (np.zeros(1) for _ in range(arity))
    sample = lowered(*probe)
    return (
        Error("<wrong-arity>")
        if len(sample) != 2
        else Ok(lowered)
        if all(np.isfinite(np.asarray(part)).all() for part in sample)
        else Error("<non-finite>")
    )
```

## [07]-[OWNED_BUILDS]

The constant-coefficient periodic operators and the seeded sampler have no companion-band solver surface; they are composed from `numpy.fft`, the seeded `numpy.random.Generator`, and the rails, with the route owning the policy the providers refuse.

[SPECTRAL_OPERATOR]:
- Law: collapse every constant-coefficient periodic operator to one symbol applied pointwise to the forward `numpy.fft.rfft`; the symbol is a `frozendict` policy row keyed by a closed `StrEnum` operator vocabulary, composed by pointwise multiplication before a single `irfft`, and a new operator is a new row, never a new code path.
- Law: derive the split-spectrum wavenumber once at grid construction through `numpy.fft.rfftfreq`, scaled by `2π/extent`; hand-indexing the bin number applies an aliased symbol past the half length silently. The Nyquist-null is a property of the symbol, not a runtime branch on grid size: each operator row carries its odd-order flag beside its callable, and an odd-order symbol on an even-length grid nulls the Nyquist coefficient (the real `rfft` cannot represent its imaginary half) while an even-order symbol keeps it — the flag is the row's `Symbol.odd_order` field, never an `if` re-deciding parity per call.
- Exemption: the in-place Nyquist null `spectrum[-1] *= ...` is the page's one measured statement seam — `numpy.fft.rfft` returns a freshly allocated, unaliased buffer, so the slot assignment zeroes the unrepresentable coefficient without copying the spectrum, the platform-forced mutation the expression interior licenses here.
- Boundary: mark the result inadmissible on a non-finite inverse; a real-symbol operator owes a finite real field, and a `nan` diagnoses broken Hermitian symmetry in the assembled spectrum.

[SEEDED_SAMPLING]:
- Law: draw stochastic samples through one explicit `numpy.random.default_rng(seed)` over a state-serializable generator for checkpoint-resume, deriving independent parallel streams through `SeedSequence.spawn`; the default entropy source is non-deterministic regardless of seeding, so the seed and the spawned child index are the replicate family's replay key, recorded for an exact checkpoint resume.
- Boundary: a stochastic estimate leaves as a replicate family whose cross-replicate spread is the receipt's variance evidence; a single draw carries no recoverable variance.

```python conceptual
from collections.abc import Callable
from dataclasses import dataclass
from enum import StrEnum

import numpy as np
from builtins import frozendict
from expression import Error, Ok, Result


class Operator(StrEnum):
    LAPLACIAN = "laplacian"
    GRADIENT = "gradient"
    HELMHOLTZ = "helmholtz"


@dataclass(frozen=True, slots=True)
class Symbol:
    apply: Callable[[np.ndarray], np.ndarray]
    odd_order: bool


SYMBOL: frozendict[Operator, Symbol] = frozendict({
    Operator.LAPLACIAN: Symbol(lambda k: -(k**2), False),
    Operator.GRADIENT: Symbol(lambda k: 1j * k, True),
    Operator.HELMHOLTZ: Symbol(lambda k: 1.0 / (1.0 + k**2), False),
})


def driven(field: np.ndarray, extent: float, operator: Operator, /) -> Result[np.ndarray, SolveFault]:
    symbol = SYMBOL[operator]
    k = np.fft.rfftfreq(field.size, d=extent / field.size) * (2.0 * np.pi)
    spectrum = np.fft.rfft(field) * symbol.apply(k)
    spectrum[-1] *= 0.0 if symbol.odd_order and field.size % 2 == 0 else 1.0
    inverted = np.fft.irfft(spectrum, n=field.size)
    return Ok(inverted) if np.isfinite(inverted).all() else Error("<broken-symmetry>")


def sampled(seed: int, children: int, draws: int, /) -> Result[np.ndarray, SolveFault]:
    streams = np.random.SeedSequence(seed).spawn(children)
    replicates = np.stack(tuple(np.random.default_rng(child).normal(0.0, 1.0, draws) for child in streams))
    return Ok(replicates) if np.isfinite(replicates).all() else Error("<non-finite>")
```
