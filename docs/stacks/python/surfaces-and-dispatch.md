# [PYTHON_SURFACES_AND_DISPATCH]

A concern with many features keeps one dense surface, never a family of shallow ones: one entrypoint absorbs every verb, arity, and modality — verbs collapse into a `@tagged_union` request under one total `match` so a new verb breaks every dispatch site instead of growing a sibling, arity collapses into one `T | Iterable[T]` parameter the body discriminates by shape, and a dependent dispatch loop is one `tailrec` trampoline over a closed continue-or-done step rather than an open recursion. The discriminant is the value, never a mode flag beside it; knob sets collapse into policy values that carry their own behavior, and optional context enters as `Option[T]` or one frozen settings owner whose default derives from the policy. Six dispatch forms are selected by where ownership lives — one `Protocol` core, one `frozendict` table, one closed-family `match`, behavior carried on the vocabulary member, one `tailrec` step, one `functools.singledispatch` over a genuinely open type set — while the rail stays orthogonal to the form and alone decides accumulate-versus-abort. Aspects split at one seam: a definition-time weave preserves the signature and the rail through inline `**P` and `functools.wraps` and never raises into domain flow, a call-site combinator composes around the one invocation it modifies. The named defect this page refuses is surface spam: parallel near-identical functions, `get`/`get_many`/`get_by_id` families, forward/inverse verb pairs split across sibling exports, stringly-typed dispatch ladders, one-method classes, thin rename wrappers, and barrel re-export files.

## [01]-[FORM_CHOOSER]

When a concern matches several rows, the most specific wins; the rail axis is read after the form is fixed.

| [INDEX] | [CONCERN_SIGNATURE]                         | [FORM]                               | [REJECTED_FORM]                       |
| :-----: | :------------------------------------------ | :----------------------------------- | :------------------------------------ |
|  [01]   | verb family, shared preamble                | request tagged union + total `match` | sibling `create`/`update` functions   |
|  [02]   | one verb, varying arity                     | one `T \| Iterable[T]`, shape-tested | per-arity overload family             |
|  [03]   | consumer owns logic, family owns coverage   | closed-family `match` on the owner   | external `match` repeated per call    |
|  [04]   | the vocabulary member is the behavior       | callable carried on the member       | full-coverage `match` per call site   |
|  [05]   | key is a value, result is static data       | module-level `frozendict` table      | `if`/`elif` returning constants       |
|  [06]   | dependent dispatch loops to a fixpoint      | `tailrec` continue-or-done step      | open recursion or a `while` mutator   |
|  [07]   | receiver is foreign, behavior is local      | one function over the foreign value  | wrapper class renaming the receiver   |
|  [08]   | input shape, not nominal tag, discriminates | structural `match` patterns          | `isinstance` ladder over open input   |
|  [09]   | one body serving every rail                 | union member-overlap function        | `run_result`/`run_option` sibling set |
|  [10]   | open type set, foreign code adds arms       | `functools.singledispatch`           | `match` editing the owner per type    |
|  [11]   | optional context with identity              | one `Option[Context]`                | `a=None, b=None, strict=False` tail   |
|  [12]   | replaceable capability, many implementers   | one `Protocol` port                  | concrete dependency hardcoded inline  |

## [02]-[ENTRYPOINT_LAW]

[REQUEST_COLLAPSE]:

- Law: one concern exposes one entrypoint; a verb family is a `@tagged_union` with one `case()` per verb under the settled total `match`, and each sibling's distinct parameters become its case payload while the shared preamble becomes the dispatch prologue executed once before the `match` — the verb set is the closed family the exhaustiveness mechanic proves, so a new verb is one case that breaks every dispatch arm at type-check, never a sibling `create`/`update` function beside the union.
- Law: admission is two-tier — the private `@tagged_union` constructor seals the case family, and one `of_*` classmethod returning `Result[Request, Fault]` is the validated ingress, so the dispatch interior is total over well-formed requests and never re-checks a field the factory already proved; a verb's independent field checks compose applicatively through `map2` over the field rails rather than a nested abort ladder, and whether that composition short-circuits or accumulates is the rail page's disposition carried as the factory's policy value, fixed once at the admission boundary.
- Law: the entrypoint internalizes the concern's whole operational envelope — policy resolution rides the `[04]` policy values, retry, contract, and telemetry ride the `[08]` aspect stack, lifecycle rides the owner's own transitions — so the consumer hands in one request and composes the returned rail, never re-assembling internals at the call site or importing a symbol per concern; where the domain admits an inverse — encode/decode, project/absorb, advance/rewind — the reverse direction is one more case on the same request family under the same total `match`, never a sibling entrypoint pair.
- Use: `@tagged_union` named cases when verbs carry distinct fields; a `StrEnum` discriminant on one frozen owner when the verbs share one field set and differ only by tag.
- Reject: a request shaped as success-or-failure — rails own outcome transport; a `dispatch(verb: str, **kwargs)` signature where `verb` is an open string and `kwargs` is an untyped bag.

```python conceptual
from typing import Literal, assert_never

from expression import Error, Ok, Result, case, tag, tagged_union


type RequestFault = Literal["<empty-code>", "<bad-delta>"]
type LedgerFault = Literal["<unknown-code>", "<already-open>", "<sealed>"]


def _checked_code(code: str, /) -> Result[str, RequestFault]:
    return Ok(code) if code else Error("<empty-code>")


def _checked_delta(delta: int, /) -> Result[int, RequestFault]:
    return Ok(delta) if delta != 0 else Error("<bad-delta>")


@tagged_union(frozen=True)
class Request:
    tag: Literal["open", "amend", "close"] = tag()
    open: str = case()
    amend: tuple[str, int] = case()
    close: str = case()

    @staticmethod
    def of_open(code: str, /) -> Result["Request", RequestFault]:
        return _checked_code(code).map(lambda valid: Request(open=valid))

    @staticmethod
    def of_amend(code: str, delta: int, /) -> Result["Request", RequestFault]:
        return _checked_code(code).map2(_checked_delta(delta), lambda valid, step: Request(amend=(valid, step)))


def dispatched(request: Request, ledger: "Ledger", /) -> Result["Receipt", LedgerFault]:
    match request:
        case Request(tag="open"):
            return ledger.open(request.open)
        case Request(tag="amend"):
            code, delta = request.amend
            return ledger.amend(code, delta)
        case Request(tag="close"):
            return ledger.close(request.close)
        case unreachable:
            assert_never(unreachable)
```

## [03]-[MODAL_ARITY]

[ARITY_ABSORPTION]:

- Law: singular, multi-item, and empty call sites collapse into one parameter typed `T | Iterable[T]`; the body normalizes once at the head and the rest of the function sees one shape, so arity is a property of the argument, never of the signature, and the discriminant is recoverable from the value, never restated by a `many: bool` or a `count: int` the value's length already answers.
- Law: the normalization is one structural `match` — one guarded `Iterable()` arm admitting every container, the empty one included, then the lone fallback — so the broadest container pattern wins before the singleton and an empty call still yields the `Block` the reducer seeds over; a second concrete-sequence arm beside the guarded one is the rejected redundancy, because `tuple`/`list` already satisfy the guarded arm and route to the same `Block.of_seq`.
- Exemption: Python has no span boundary, and `str`/`bytes` are themselves `Iterable`, so the `Iterable()` normalization arm carries one guard — `if not isinstance(stream, (str, bytes))` — to keep a string from shattering into characters; this `str`/`bytes` exclusion is the named platform-forced seam, not a free-form guard, and a domain whose lone-value type is itself iterable normalizes by a closed-owner match instead, never by a second guard.
- Use: `*items: T` only when the call site genuinely lists positional arguments; a single `T | Iterable[T]` parameter when the caller already holds a collection, because `*items` forces an unpack the caller did not ask for.
- Reject: a `batch` flag, a `mode` flag, or sibling `process`/`process_many` functions; `singular`/`plural`/`stream` name suffixes that re-describe the input the value already carries; a guard beyond the named `str`/`bytes` seam that smuggles a discriminant the value already answers.

[MODALITY_FOLD]:

- Law: singular, plural-preserving, and plural-reducing are one arm under two combinators — `Block.map` carries singular and plural-preserving with shape intact, `Block.fold(combine, empty)` keyed on the `Monoid` policy value carries plural-reducing — the reducer alone switching the algebra; the empty call the `[03]` normalization admits is why the reducer is `fold` over the monoid's identity and never `reduce`, which has no seed and raises on the empty `Block` the arity head produces.
- Law: a case whose payload is a tuple spreads through `Result.map2`/`Option.starmap` rather than an unpacking lambda, so the reduction names no positional accessor and `Monoid.combine` stays a pure binary step.
- Boundary: the carrier threading and the abort-versus-accumulate disposition are the rail page's, performed by `expression.extra.result.traverse` over the railed block; this surface composes `traverse` to carry the failure semantics and spends its lines on the arity normalization and the monoid-keyed reduction, never re-deriving the threader the substrate ships or the disposition the rail owns.
- Use: the `Monoid` frozen owner (`empty` identity plus `combine` step) as the reduction policy value the call hands in, so plural-reducing over zero, one, or many items is total; `traverse` so the carrier owns short-circuit and the `Monoid` owns the algebra.
- Reject: a `reduce` on the empty `Block` the arity head already admits; a `mode`/`reduce` flag selecting the algebra the `Monoid` value already carries; a mutable accumulator the `fold` replaces.

```python conceptual
from collections.abc import Callable, Iterable
from dataclasses import dataclass

from expression import Result
from expression.collections import Block
from expression.extra.result import traverse


@dataclass(frozen=True, slots=True, kw_only=True)
class Monoid[R]:
    empty: R
    combine: Callable[[R, R], R]


def normalized[T](items: T | Iterable[T], /) -> Block[T]:
    match items:
        case Iterable() as stream if not isinstance(stream, (str, bytes)):
            return Block.of_seq(stream)
        case lone:
            return Block.singleton(lone)


def preserved[T, R](items: T | Iterable[T], step: Callable[[T], R], /) -> Block[R]:
    return normalized(items).map(step)


def swept[T, R, E](items: T | Iterable[T], step: Callable[[T], Result[R, E]], monoid: Monoid[R], /) -> Result[R, E]:
    return traverse(step, normalized(items)).map(lambda kept: kept.fold(monoid.combine, monoid.empty))
```

## [04]-[PARAMETER_ALGEBRA]

[POLICY_VALUES]:

- Law: a policy parameter arrives pre-constructed and carries its own behavior; the entrypoint invokes the value it was handed and no `if`/`match` reconstructs at the call site what the value already encodes.
- Law: behavior-bearing policy is one frozen owner whose fields include the callable step, or a `frozendict` policy table keyed on the discriminant; a `StrEnum` member carries a column only when the column is data, and the callable lives on the owner the enum selects — chooser row `[04]` is exactly this, the vocabulary member owning its behavior so the dispatch is the member's own method, never a full-coverage `match` re-spelled per call site.
- Law: a package whose entry point already accepts a behavior value takes the policy directly — `stamina.retry`'s `on=` is an `ExcOrBackoffHook` discriminator, so a `Callable[[Exception], bool | float | timedelta]` that decides retry and overrides the backoff per error is the policy value the resilience weave consumes, carried as a field on the policy owner beside the domain `step`, never a `bool` plus a separate `delay` parameter the body recombines.
- Use: a frozen dataclass with a `Callable` field and named module-level instances (`STRICT`, `LENIENT`) as the policy family, the caller passing the instance and the entrypoint calling `policy.step(...)`; the package's own behavior-valued knob where it owns the concern.
- Reject: a `strict: bool` parameter selecting between two bodies; a behavioral near-twin chosen by flag rather than by the value that encodes the boundary behavior.

[OPTIONAL_CONTEXT]:

- Law: `Option[T]` is the single optional-parameter form — declaration is `context: Option[T] = Nothing`, consumption is `context.default_value(policy.canonical)` so the fallback derives once from the policy owner — and a nullable flag tail (`a: T | None = None, b: T | None = None, strict: bool = False`) fragments one context into parallel parameters that collapse to one `Option[ContextRecord]` carrying the override bundle, with `ctx: T | None = None` the boundary-only spelling projected to `Option[T]` at admission.
- Law: when caller-omission must stay distinct from a domain-valid `None`, the settled `sentinel` admits as the parameter's own union member and the entrypoint projects it to `Option` before any interior sees it — the signature carries the omission discriminant, never a parallel `present: bool`.
- Boundary: a capability orthogonal to the discriminant — a cancellation scope, a runtime settings record — describes how work runs, not which case it is, so the scope rides the concurrency owner and the settings record rides the runtime owner, never the signature.

[KNOB_TEST]:

- Law: the knob test is removal — delete the parameter, and if no information is lost that the value cannot reconstruct, the parameter was a knob and the value already discriminates.
- Reject: a timeout, retry count, or deadline as an entrypoint parameter; the bound is a definition-time aspect or an `anyio` scope around the call, and the signature never grows a token tail for it.

```python conceptual
from collections.abc import Callable
from dataclasses import dataclass
from datetime import timedelta

from expression import Error, Nothing, Ok, Option, Result


@dataclass(frozen=True, slots=True, kw_only=True)
class Context:
    ceiling: int


@dataclass(frozen=True, slots=True, kw_only=True)
class Policy:
    canonical: Context
    step: Callable[["Input", Context], Result["Receipt", str]]
    backoff: Callable[[Exception], bool | float | timedelta]


STRICT = Policy(
    canonical=Context(ceiling=1),
    step=lambda value, ctx: Ok(Receipt.EMPTY) if value.score <= ctx.ceiling else Error(f"<over:{value.score}>"),
    backoff=lambda exc: float(exc.args[0]) if isinstance(exc, TimeoutError) else False,
)
LENIENT = Policy(canonical=Context(ceiling=8), step=lambda _v, _c: Ok(Receipt.DEGRADED), backoff=lambda _e: 0.5)


def run(policy: Policy, value: "Input", context: Option[Context] = Nothing, /) -> Result["Receipt", str]:
    return policy.step(value, context.default_value(policy.canonical))
```

## [05]-[DISPATCH_FORMS]

[FORM_SELECTION]:

- Law: the six forms are selected by where ownership lives — the chooser's ownership signatures are the selection law — and when two forms both fit, the one whose owner already holds the exhaustiveness obligation wins.
- Law: a closed vocabulary the program owns dispatches through a `match` over the owner or a `frozendict` table; `functools.singledispatch` is reserved for a genuinely open type set foreign code extends, where editing one `match` per new type is impossible.
- Reject: a `frozendict` table restating a closed family's own cases — a duplicate-entry burden with a silent missed-case failure when a member is added; `singledispatch` over a closed family the program owns, which trades the static exhaustiveness proof for a runtime registration scan; an `if`/`elif` ladder over a `StrEnum`'s `.value` strings.
- Boundary: mixing forms at one site signals an unresolved ownership boundary, except the valid composition — a `match` arm reading a `frozendict` table is dispatch plus data retrieval, and a function owning foreign-to-domain translation while its inner `match` owns per-case projection.

[TABLE_DISPATCH]:

- Law: the table chooses this form when the key is a value and the result is static data — the `language.md` `frozendict` table (its single-edit-site primary and comprehension-derived secondaries) is the settled owner; this form's own decision is that the lookup is the dispatch, replacing an `if`/`elif` ladder, and that the table's `None`-for-absent-key is projected to `Option` or a typed fault at the call boundary so absence never rides a sentinel value inside the table.
- Law: routing a raw token through the table admits it first — enum-value membership crosses through `EnumType(value)` under `try`/`except ValueError` projected to `Option`/`Result`, so an unknown key becomes a fault at the seam and the interior lookup is total, never a reach into `EnumType._value2member_map_` or any other private dunder.
- Exemption: the `EnumType(value)` `try`/`except ValueError` is the measured admission kernel — the platform-forced statement seam where a raw token crosses into the closed vocabulary, projected to `Option`/`Result` so every interior lookup past it is total over admitted members and no second statement survives in the dispatch body.
- Use: the table lookup as the dispatch when the key maps to static data; the `enum` member as the key when the vocabulary is closed and process-local.
- Reject: a table whose values are callables the owning vocabulary carries as case methods (chooser row `[04]`); an `if value in EnumType._value2member_map_` private-internal membership probe; an `if`/`elif` ladder restating a correspondence the table already holds.

[OPEN_DISPATCH]:

- Law: `@singledispatch` registers one arm per concrete type and a base arm; the registered functions are the open extension axis, so foreign code adds a type by registering an arm without editing the owner — the inverse of the closed `match`.
- Law: the base `@singledispatch` arm returns the rail's typed fault for an unregistered type; dispatch resolves on the first argument's runtime type through the method resolution order, so an `ABC` registration covers its subclasses in one arm, and every registered arm returns the rail the owner declares so the open axis stays rail-consistent with the closed forms.
- Use: `singledispatch` only at a true plugin seam — a renderer over a host type hierarchy the library does not own; the closed `match` everywhere the program owns the type set.

```python conceptual
from collections.abc import Sequence
from enum import StrEnum
from functools import singledispatch
from typing import Literal

from builtins import frozendict
from expression import Error, Nothing, Ok, Result, Some


type RouteFault = Literal["<unknown>", "<no-arm>"]


class Marker(StrEnum):
    PRIMARY = "<key-a>"
    SECONDARY = "<key-b>"


WEIGHT: frozendict[Marker, tuple[int, str]] = frozendict({Marker.PRIMARY: (1, "<label-a>"), Marker.SECONDARY: (2, "<label-b>")})


def weighted(raw: str, /) -> Result[tuple[int, str], RouteFault]:
    try:
        admitted = Some(Marker(raw))
    except ValueError:
        admitted = Nothing
    return admitted.map(WEIGHT.__getitem__).to_result("<unknown>")


@singledispatch
def rendered(value: object, /) -> Result[str, RouteFault]:
    return Error("<no-arm>")


@rendered.register
def _(value: Marker, /) -> Result[str, RouteFault]:
    return Ok(WEIGHT[value][1])


rendered.register(Sequence, lambda value: Ok(f"<seq:{len(value)}>"))
```

## [06]-[RAIL_POLYMORPHIC_DISPATCH]

[ONE_RAIL_SURFACE]:

- Law: the form selects which arm runs; the rail the arms return selects how results combine — orthogonal axes. One function whose body composes through `bind`/`map` serves `Result` and `Option` by member-name overlap over the union `Result[T, E] | Option[T]`, not by a shared higher-kinded carrier — `expression` exposes no common monadic supertype, the only shared bases being `Iterable`, `PipeMixin`, and `object` — so the per-rail sibling family is the rejected form while the neutral body stays restricted to the literal `map`/`bind`/`default_value` names both carriers expose and never names `Ok`/`Some`/`Error`/`Nothing`, because the moment it constructs a carrier by name it commits to one and the union stops type-checking.
- Law: the rail is chosen once at the function's boundary and threaded unchanged; `Result.to_option` and `Option.to_result` migrate the rail exactly once at a boundary, never mid-pipeline, because the round trip stamps over the original fault.
- Law: a conditional inside the dispatch body is a fourth dispatch smuggled into combination — its only legitimate content is total construction over already-railed values — so it lifts into its own arm and the body stays a pure `map`/`bind` composition; independent operands join through `map2`/`starmap` over the rail, never an `if` reconstructing a discriminant the value already carries.
- Boundary: which join the body uses and whether it aborts on the first fault or accumulates every one is the rail page's disposition, threaded here as the `[04]` policy value the dispatch carries; this surface composes that decision and never re-derives the `map2`-versus-fold mechanics or the fault-combining monoid the rail owns.
- Use: a generic `[T, E]` signature whose body names only `map`/`bind`/`default_value`, deleting the `run_result`/`run_option` sibling pair and admitting any fault vocabulary; the rail page's `@effect.result`/`@effect.option` builders own the sequential `yield from` form, reached only when one carrier is already fixed.

[ITERATIVE_DISPATCH]:

- Law: a dependent dispatch loop — each step's successor decided by the prior step's case — is one `tailrec` function over a closed continue-or-done step, the live case picking the next seed and a terminal case returning the fixpoint, so the stack never grows and the loop carries no mutable index; the split is the continue-or-done axis of one `@tagged_union` — one advance case against a closed terminal sub-family that distinguishes the settled fixpoint from each divergence cause — never a sentinel return or a `None` terminator the caller re-reads.
- Law: the step is a pure function returning `TailCall(*next_seed)` to recurse or a plain terminal to complete; a fallible step threads the rail by returning the carrier as the terminal, so the trampoline drives dependent dispatch to a fixpoint and the boundary lifts the terminal once — `match` over the step's own continue-or-done cases is the dispatch, `tailrec` is the driver, and the two stay orthogonal exactly as form and rail do.
- Use: `tailrec` for bounded fixpoint iteration the call modality folds over — a settle loop, a refinement sweep, a state-machine advance whose verb the prior state selects; the `@effect.result` do-notation when the chain is dependent but not iterative.
- Reject: an open `def f(): ... return f(...)` recursion that grows the stack on deep input; a `while` loop mutating an accumulator; a `count` parameter bounding a loop whose terminal case already answers when to stop.

```python conceptual
from typing import Literal, assert_never

from expression import Error, Ok, Option, Result, TailCall, TailCallResult, case, tag, tagged_union, tailrec


type StepFault = Literal["<diverged>"]


@tagged_union(frozen=True)
class Step:
    tag: Literal["advance", "settle", "diverge"] = tag()
    advance: int = case()
    settle: int = case()
    diverge: int = case()


def stepped(state: int, ceiling: int, /) -> Step:
    folded = state // 2 if state % 2 == 0 else (3 * state + 1) // 2
    return Step(settle=state) if state <= 1 else Step(diverge=folded) if folded >= ceiling else Step(advance=folded)


@tailrec
def driven(state: int, ceiling: int, /) -> TailCallResult[Result[int, StepFault], [int, int]]:
    match stepped(state, ceiling):
        case Step(tag="advance", advance=nxt):
            return TailCall(nxt, ceiling)
        case Step(tag="settle", settle=fixed):
            return Ok(fixed)
        case Step(tag="diverge"):
            return Error("<diverged>")
        case unreachable:
            assert_never(unreachable)


def converged(seed: int, ceiling: int, /) -> Result[int, StepFault]:
    return driven(seed, ceiling)


def projected[E](outcome: Result[int, E] | Option[int], /) -> int:
    return outcome.map(lambda fixed: fixed + 1).default_value(0)
```

## [07]-[TYPE_LEVEL_DISPATCH]

The `Protocol` itself is the `shapes.md` `[TOKEN_STATE_PORT]` owner for a replaceable capability — its minimal rail-typed method set, `get_protocol_members` coverage proof, and `type[Port]` injection key are settled there; runtime narrowing into it (`@runtime_checkable` plus a `TypeIs` predicate, `beartype.door.is_subhint` registry subtyping) is the `language.md` `[TYPE_PREDICATE_SITE]`. This page owns only the leg those owners delegate: the generic `[S: Port]` constraint as a dispatch form, and how it composes against the closed forms.

[GENERIC_DISPATCH]:

- Law: the constraint `[S: Port]` is itself the dispatch — the inversion of the closed `match`: the `match` is closed over one owner's cases and resolves at the value, the `[S: Port]` form is open over the unbounded implementer family and resolves at the type, statically, with no registration, no nominal base, and no `isinstance` at the call site, so adding an implementer edits no dispatch site.
- Law: the constrained function returns `S`, not the bare `Port`, so an immutable implementer threads its own concrete successor through the rail and the caller keeps the precise type — one dispatch surface over every present and future implementer whose every method returns the one fault family, so the port's operations compose through `bind`/`map2` exactly as a closed owner's transitions do and the open axis stays rail-consistent with the closed forms.
- Law: a `type[Port]` key selects the active implementer from a runtime settings owner before the `[S: Port]` body runs, so injection is one table read at the composition root and the dispatch interior never branches on which implementer it holds; the selection is data, the dispatch is the constraint.
- Use: one generic function constrained `[S: Port]` composing several port operations through the rail and returning `S`; the `type[Port]` injection key when the implementer is chosen at the root, the `match`-resolved closed form when the program owns the case set.
- Reject: a `Port`-typed return that erases the concrete implementer the caller passed; a per-implementer overload family where one `[S: Port]` constraint already dispatches; an `isinstance` branch inside the constrained body re-deciding which port it holds.

[REACH_LIMIT]:

- Law: the `[S: Port]` form binds at the call site, so a runtime-discovered candidate is narrowed once by the `language.md` predicate seam and the narrowed value re-enters this same static surface — the discovery narrowing happens at the boundary, never per dispatch, and the interior stays the zero-cost structural form.
- Boundary: the discovery seam is the one place a candidate of unknown type crosses into the port family; everywhere downstream the implementer is statically `S` and the constraint alone carries the dispatch.

```python conceptual
from typing import Literal, Protocol, Self, TypeIs, runtime_checkable

from builtins import frozendict
from expression import Error, Result


type StoreFault = Literal["<missing>", "<sealed>", "<conflict>", "<unbound>", "<no-route>"]


@runtime_checkable
class ShapeStore(Protocol):
    def loaded(self, key: str, /) -> Result["Shape", StoreFault]: ...
    def stamped(self, shape: "Shape", seal: str, /) -> Result["Shape", StoreFault]: ...
    def committed(self, shape: "Shape", /) -> Result[Self, StoreFault]: ...


def sealed[S: ShapeStore](store: S, key: str, seal: str, /) -> Result[S, StoreFault]:
    return store.loaded(key).bind(lambda shape: store.stamped(shape, seal)).bind(store.committed)


def resolved[S: ShapeStore](port: type[S], root: frozendict[type[ShapeStore], ShapeStore], key: str, seal: str, /) -> Result[S, StoreFault]:
    candidate = root.get(port)
    return sealed(candidate, key, seal) if isinstance(candidate, port) else Error("<unbound>")


def admitted(candidate: object, /) -> TypeIs[ShapeStore]:
    return isinstance(candidate, ShapeStore) and not isinstance(candidate, type)


def discovered(candidate: object, key: str, seal: str, /) -> Result[ShapeStore, StoreFault]:
    return sealed(candidate, key, seal) if admitted(candidate) else Error("<no-route>")
```

## [08]-[ASPECTS]

[WEAVE_TAXONOMY]:

- Law: a definition-time aspect is a property of the function — declared by a signature-preserving decorator, present at every call site; a call-site aspect is a property of one invocation — attached as a scope or combinator around the call it modifies, and the classification test is per-site variance: a concern present at every use weaves at definition (retry policy, runtime contract, observability span, memoization), a concern that varies per site composes at the site (one deadline, one cancellation scope, one resource bracket).
- Law: a definition-time aspect preserves the signature and the rail through inline `**P` and `functools.wraps`, materializes policy from its arguments, and never raises inside domain flow — a failing aspect returns the rail's `Error`, it does not throw past the wrapped function, so the contract weave applies `beartype(conf=...)` under a shared cached `BeartypeConf` and catches `BeartypeCallHintViolation` (the root both the param and return violations inherit, so one arm covers the default conf), lifting it through `lifted` onto the fault rather than a bare `@beartype` that throws the violation into the interior; the `violation_type=` redirect that raises a domain exception instead of railing is the shape page's admission-factory form, distinct from this rail-lift weave.
- Exemption: the weave's `try`/`except BeartypeCallHintViolation` is the measured rail-lift kernel — the one statement a definition-time aspect admits, converting the contract violation to the fault rail so the wrapped core stays expression-shaped and the raised violation never reaches domain flow.
- Boundary: the synchronous weave layering this page shows is the definition-time form; an async core threads each weave as an `async def` layer whose structured-concurrency placement — the retry seeing only a raised transient, the deadline scope, the offload — is `concurrency.md`'s, composed over this fold and never re-derived here.

[CONCERN_PRECEDENCE]:

- Law: the cross-cutting concerns over one pure core rank by a single `_RANK` precedence table keyed on the closed `WeaveName` vocabulary — the page's own concerns are a closed `Concern` family resolving each case's payload to one `Weave`, the owner-built weaves compose in pre-constructed through the `owned` table keyed by `Deferred`, and the factory derives the canonical innermost-to-outermost order from the rank and never the caller's argument order, so an unranked name is a type error, a miswired stack is unspellable, and a new concern lands as one `Concern` case or one `owned` row plus one `_RANK` row with every existing call site untouched.
- Law: the table fixes the one ordering correctness forces and declares the rest in one place — `contract` is innermost (rank 0) because a memoization weave that hashes arguments before the contract validates them caches the rejected `Error` permanently, so `cache` and every outer weave wrap an already-validated body; the relative rank of `cache`, `observe`, and `retry` is the policy the `_RANK` table declares — here `observe` encloses `cache` so a cache hit is still traced and `retry` is outermost so a transient re-drives the whole observed body — so a policy change is one row edit, never a tower re-spelled at every call site.
- Law: every weave in the fold satisfies one signature — `Callable[[Callable[P, Result[T, E]]], Callable[P, Result[T, E]]]` — which keeps `**P`, the return rail, and `functools.wraps` identity intact through an arbitrary-depth stack; `contract` and `retry` are this page's own weaves built from the concern's payload (`beartype(conf=...)` plus the `except BeartypeCallHintViolation` rail-lift, `stamina.retry(on=...)` over the backoff hook whose raised-versus-railed edge `concurrency.md` owns), while `cache` and `observe` enter as owner-built weaves the `owned` frozendict carries already constructed for the rank alone to place; raw-ingress coercion never joins the stack, because admission is the shape page's once-at-the-edge factory and the core the weave wraps already holds admitted owners.
- Use: the `Concern` family and the `owned` weaves folded by ascending rank onto the forced `contract` arm, the rail-safe `beartype(conf=...)` + `except BeartypeCallHintViolation` weave as this page's spotlight; this factory the moment local or owner-built weaves co-occur over one pure core.
- Reject: a hand-rolled `try`/`except` retry loop; a fixed decorator tower re-spelled at every owner; a span timer or `structlog.get_logger` chain rebuilt here where the observability weave owns it; a bare `@beartype` that raises into the rail; a weave typed `Callable[..., Any]` that erases the wrapped signature; a caller-ordered stack where the `_RANK` table already fixes the order.

```python conceptual
from collections.abc import Callable
from functools import reduce, wraps
from typing import Literal, assert_never

import stamina
from beartype import BeartypeConf, beartype
from beartype.roar import BeartypeCallHintViolation
from builtins import frozendict
from expression import Error, Ok, Result, case, tag, tagged_union

type FetchFault = Literal["<empty>", "<contract>"]
type Weave[**P, T, E] = Callable[[Callable[P, Result[T, E]]], Callable[P, Result[T, E]]]
type WeaveName = Literal["contract", "cache", "observe", "retry"]
type Deferred = Literal["cache", "observe"]

_RANK: frozendict[WeaveName, int] = frozendict({"contract": 0, "cache": 1, "observe": 2, "retry": 3})
_CONTRACT = BeartypeConf(is_pep484_tower=True)


def _transient(error: Exception, /) -> bool | float:
    return 0.5 if isinstance(error, ConnectionError) else False


@tagged_union(frozen=True)
class Concern:
    tag: Literal["contract", "retry"] = tag()
    contract: BeartypeConf = case()
    retry: Callable[[Exception], bool | float] = case()


def _contracted[**P, T, E](lifted: Callable[[BeartypeCallHintViolation], E], conf: BeartypeConf, /) -> Weave[P, T, E]:
    def weave(operation: Callable[P, Result[T, E]], /) -> Callable[P, Result[T, E]]:
        guarded = beartype(conf=conf)(operation)

        @wraps(operation)
        def call(*args: P.args, **kwargs: P.kwargs) -> Result[T, E]:
            try:
                return guarded(*args, **kwargs)
            except BeartypeCallHintViolation as violation:
                return Error(lifted(violation))

        return call

    return weave


def aspected[**P, T, E](
    *concerns: Concern,
    owned: frozendict[Deferred, Weave[P, T, E]] = frozendict(),
    lifted: Callable[[BeartypeCallHintViolation], E],
    conf: BeartypeConf,
) -> Weave[P, T, E]:
    def ranked(concern: Concern, /) -> tuple[int, Weave[P, T, E]]:
        match concern:
            case Concern(tag="contract", contract=cfg):
                return _RANK["contract"], _contracted(lifted, cfg)
            case Concern(tag="retry", retry=hook):
                return _RANK["retry"], stamina.retry(on=hook, attempts=5)
            case unreachable:
                assert_never(unreachable)

    ranked_local = (ranked(concern) for concern in (Concern(contract=conf), *concerns))
    ranked_owned = ((_RANK[name], weave) for name, weave in owned.items())
    ordered = sorted((*ranked_local, *ranked_owned), key=lambda rw: rw[0])
    return lambda operation: reduce(lambda wrapped, rw: rw[1](wrapped), ordered, operation)


def _observed[**P, T, E](operation: Callable[P, Result[T, E]], /) -> Callable[P, Result[T, E]]:
    return operation


@aspected(Concern(retry=_transient), owned=frozendict({"observe": _observed}), lifted=lambda _v: "<contract>", conf=_CONTRACT)
def fetched(code: str, /) -> Result[str, FetchFault]:
    return Error("<empty>") if code == "" else Ok(code.upper())
```
