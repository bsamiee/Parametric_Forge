# [PYTHON_RAILS_AND_EFFECTS]

This page is the carrier algebra. `expression` owns the result and absence carriers, the do-notation builders, the `pipe`/`compose` composition surface, and immutable traversal; this page legislates which carrier states an outcome, how a boundary mints it, how reusable transforms thread it, how a collection sequences it, how a fault vocabulary combines, where the carrier collapses, and how state and receipts carry evidence. The carrier is itself the sequencing algebra — `Option` and `Result` short-circuit, the accumulating fold combines — never a flag the body re-reads. It is chosen once at admission and threaded unchanged: the narrowest carrier that states the real outcome carries the value, reusable transforms keep it, and collapse to a bare value or a raised exception happens only at the process, CLI, network, or persistence edge. The interior is total over admitted carriers — raw provider shapes, `None`-as-failure, unclassified exceptions, and cancellation never travel it.

Four siblings own the surfaces this algebra composes as settled material. The runtime that raises a deadline, a group fault, or a cancellation is `concurrency.md`'s; the definition-time aspect weave that stacks retry and contracts over a pure core is `surfaces-and-dispatch.md`'s; the serialized many-producer state cell is `boundaries.md`'s; the closed-family ADT mechanics are `shapes.md`'s. This page composes each to state only which raise crosses into the fault vocabulary and which carrier transports the step.

## [01]-[RAIL_CHOOSER]

Choose the narrowest carrier that preserves the real outcome. A wider carrier is earned only by a capability the narrower one cannot carry: a typed failure cause, or accumulated independent faults. The carrier choice is itself the sequencing algebra; the collection owner and the do-notation builder are that same algebra at traversal scale, not a sixth and seventh carrier.

| [INDEX] | [SURFACE]                | [OWNS]                         | [REJECTED_FORM]                   |
| :-----: | :----------------------- | :----------------------------- | :-------------------------------- |
|  [01]   | `Option[T]`              | non-failing absence            | `None`-as-hidden-failure          |
|  [02]   | `Result[T, E]`           | typed fallibility, fail-fast   | raised control flow in domain     |
|  [03]   | `@effect.result[T, E]()` | sequential `bind` do-notation  | nested `bind` lambda ladders      |
|  [04]   | fault-combining fold     | accumulated independent faults | first-failure `bind` over a batch |
|  [05]   | `Block[T]` / `Map[K, V]` | immutable traversal and lookup | mutable list/dict domain flow     |
|  [06]   | threaded frozen owner    | single-producer state          | shared mutable global             |

`Option[T]` carries absence with zero failure semantics; promote to `Result[T, E]` when the caller must know why, where the error `E` is a closed fault vocabulary, never a bare `str` for a domain with more than one mode. `Try[T]` is not a seventh carrier — it is `Result[T, Exception]`, the transient shape a foreign raise takes the instant a boundary `except` adapter catches it, mapped into the domain fault vocabulary in the same expression so it never reaches the interior. The accumulating fold is not a carrier but a sequencing discipline over `Result` — it earns its row because abort-versus-accumulate is a correctness decision the carrier alone does not make. The serialized many-producer state cell is the boundary owner's surface and the async scope that bounds an effect is the concurrency page's; this page chooses between a frozen owner threaded for one producer and that cell, and stops at the carrier decision.

[REPRESENTATION_DEFAULT]:
- Law: the carrier states the outcome, never the value's representation — a fallible step returns `Result`, a non-failing absent step returns `Option`, and the interior is total over both because `shapes.md`'s admission already settled where `Nothing`, a `sentinel`, and a genuine wire `None` each live; this page never re-derives that representation, it only chooses which carrier transports the step.
- Law: `Result` equality compares tag then payload, so a `set` or `dict` keyed on `Result` distinguishes `Ok(x)` from `Error(e)` and distinct faults from each other; a single-fault collapse coalesces every failure to one key, which an accumulating boundary must never do, and is why the fault vocabulary stays structurally addressable rather than message-collapsed.
- Law: a carrier is migrated, never re-chosen — `Result.swap()` routes the fault half through the same transforms as the success half, and `Result.merge()` collapses a same-typed `Ok`/`Error` to one value only where both arms are already the egress type, never as a mid-pipeline escape from the rail.

## [02]-[BOUNDARY_CONVERSION]

Every boundary converts once into the carrier that states the real outcome; reusable transforms thread that carrier through `pipe`/`compose` and never re-project mid-pipeline, and the carrier collapses to a bare value or a raise only at the egress. The interior never sees the provider exception, the provider sentinel, the carrier-to-carrier round trip that erases a fault, or a mid-pipeline collapse.

[EXCEPTION_CAPTURE]:
- Law: one boundary adapter wraps the throwing provider call as explicit `except` arms naming the exact exception types the provider raises — `pydantic.ValidationError`, `msgspec.DecodeError`, `OSError`, `beartype.roar.BeartypeCallHintViolation` — never a bare `except Exception`, so an unexpected raise propagates as a defect rather than being silently railed; distinct arms discriminate distinct provider exceptions into distinct cases of one closed vocabulary, and a hierarchy's most specific exception is ordered first — `FileNotFoundError` before its `OSError` base — because a broad arm placed first shadows the precise one it subsumes.
- Law: a single provider exception crosses through `expression.extra.result.catch(exception=X)` — the substrate trap decorator that mints `Result[T, X]` (the `Try`-transient) from the named raise, lets an unlisted raise propagate as a defect, and is re-spelled into the vocabulary by one `map_error` in the same expression — so the explicit multi-`except` boundary is reached only when several provider exceptions discriminate into distinct cases one `catch` cannot split, never to hand-roll the one-exception trap the substrate already ships.
- Law: `BaseException.add_note(...)` annotates the caught exception with its call coordinate at the capture site, and the fault shape — not the note — decides whether the provider message survives inward: a category-only `Literal` keeps the recovery key while a message-carrying case (`[04]`'s `of_detail`) preserves the message, so the annotated coordinate enriches a defect that propagates or a `Try` payload carried to a single egress, never a second channel beside the typed case. A `@beartype` runtime-contract violation is one more provider raise this adapter catches, and the alternative that redirects the violation onto the carrier without a `try` is the surfaces page's contract weave, composed at definition time, not a second capture form taught here.
- Law: the runtime raises — a `TimeoutError` from a deadline scope, a `BaseExceptionGroup` from a task group, the cancellation class — cross this seam as one more fault case each, but the `except*` group split and the scope that raised them are `concurrency.md`'s group edge; this card states only that the converted raise lands as a vocabulary case, never the group mechanics.
- Reject: `contextlib.suppress` hiding fallibility; a bare `try`/`except` wrapping interior carrier transforms; a bare `except Exception` silently railing an unclassified defect; discarding the provider cause where the fault case carries it; `effect.try_` as a raw-exception trap — it composes `Try` values through `yield from` and never catches a provider raise, where `expression.extra.result.catch` is the substrate's actual single-exception trap.

[CARRIER_THREADING]:
- Law: the instance matrix migrates a carrier exactly once at a boundary — `Option.of_optional(value)`/`Option.of_result(...)` admit, `Option.to_result(error)`/`to_result_with(thunk)` and `Result.of_option(error)`/`of_option_with(thunk)` widen by supplying the missing fault, `Result.to_option()` narrows by discarding it, and the `_with` thunk forms mint the fault lazily on the absent branch alone, so a fault whose construction is itself costly is paid only when the carrier is empty.
- Law: reusable transforms thread the migrated carrier through `pipe(value, *fns)` over the curried module callables (`result.map`, `result.bind`, `result.or_else_with`, `result.map_error`) and `compose(*fns)` builds the reusable carrier-preserving transform once; a multi-step pipeline is point-free and a named `compose`d transform keeps the carrier with no intermediate variable that re-collapses it, while method chaining stays the fluent form only for the chain no second call site reuses — reuse, never length, promotes the chain to a named `compose`d transform.
- Law: the `Result -> Option -> Result` round trip stamps over the original fault and breaks every later `map_error` or fault-code predicate, so `option.to_result(specific_fault)` re-supplies a precise fault, and a carrier migrated to `Option` to reuse an `Option`-only transform is migrated back with a re-supplied fault, never trusted to carry the erased one.
- Reject: a round trip where an explicit projection carries the fault through; `Option.value` access without a prior `is_some` proof; an intermediate variable for a sequential transform `pipe` threads; a wrapper renaming `pipe`/`compose`; a collapse inside a pure projection that stays railed.

[TERMINAL_COLLAPSE]:
- Law: the carrier collapses to a bare value or a raise only at the process, CLI, network, or persistence edge — `default_value(fallback)`/`default_with(...)` extract with an eager or lazy fallback (`default_with` fed the fault on `Result`, called bare on `Option`), a total `match` over the carrier's cases branches both arms at the edge, and the raise is reconstructed from the fault only where a foreign caller demands an exception; a reusable domain transform keeps the carrier, and `Option.value`/`.default_value` is never the mid-pipeline exit.
- Law: the egress fold is asymmetric — a `Result.Error` folds into one structured event through `structlog.get_logger().error(event, **fields)` at the boundary while the `Ok` path stays silent, so observation happens once at the edge and never as a `raise`-and-log inside a `bind` chain; the structlog processor chain and the OpenTelemetry span are the observability domain's, composed here as the egress sink, never configured here.
- Reject: a mid-pipeline collapse inside a pure projection; a `match` collapsing a carrier the next transform still needs railed; `raise`-and-log inside an interior `bind`; a bare value returned from a reusable transform where the carrier must survive to the edge.

```python conceptual
from collections.abc import Callable
from typing import Literal

import structlog
from beartype.roar import BeartypeCallHintViolation
from expression import Error, Ok, Option, Result, compose, pipe, result
from expression.extra.result import catch

type CaptureFault = Literal["<malformed>", "<missing>", "<host>", "<contract>", "<empty-key>"]

_LOG = structlog.get_logger()


def captured(parse: Callable[[bytes], "Shape"], raw: bytes, /) -> Result["Shape", CaptureFault]:
    try:
        return Ok(parse(raw))
    except ValueError as malformed:
        malformed.add_note(f"<at:captured len={len(raw)}>")
        return Error("<malformed>")
    except FileNotFoundError:
        return Error("<missing>")
    except OSError as host:
        host.add_note(f"<errno:{host.errno}>")
        return Error("<host>")
    except BeartypeCallHintViolation:
        return Error("<contract>")


def decoded(parse: Callable[[bytes], "Shape"], raw: bytes, /) -> Result["Shape", CaptureFault]:
    return catch(exception=ValueError)(parse)(raw).map_error(lambda _raised: "<malformed>")


def _keyed(shape: "Shape", /) -> Result["Shape", CaptureFault]:
    return Ok(shape) if shape.key else Error("<empty-key>")


_refined: Callable[[Result["Shape", CaptureFault]], Result["Shape", CaptureFault]] = compose(
    result.bind(_keyed), result.map_error(lambda fault: "<malformed>" if fault == "<empty-key>" else fault)
)


def admitted(parse: Callable[[bytes], "Shape"], raw: bytes, cached: Option["Shape"], /) -> Result["Shape", CaptureFault]:
    return pipe(cached.to_result_with(lambda: "<missing>"), result.or_else_with(lambda _gap: captured(parse, raw)), _refined)


def _logged(fault: CaptureFault, /) -> str:
    _LOG.error("<egress>", fault=fault)
    return "<empty>"


def delivered(outcome: Result["Shape", CaptureFault], /) -> str:
    return outcome.map(lambda shape: shape.key).default_with(_logged)
```

## [03]-[TRAVERSAL_FLOW]

Traversal is carrier policy: the collection owner and the sequencing operator together decide how failures, strictness, and order compose. The operator is the sequencing decision, never a performance choice — fail-fast threads the carrier and aborts on the first `Error`, accumulating folds every element and combines the faults.

[COLLECTION_OWNER]:
- Law: `Block[T]` is the immutable sequence owner — persistent, structurally shared, `cons`/`append`/`fold`/`reduce`/`choose`/`partition` — for domain traversal; `Map[K, V]` is the persistent keyed owner with `add`/`change`/`fold`/`try_find`; a plain `tuple` carries fixed-arity evidence, not a growing sequence.
- Law: `Block.fold(folder, seed)` folds left with an immutable accumulator and `Block.reduce(reducer)` folds a non-empty `Block` with no seed; incremental build is one `fold` or `cons`-then-reverse, never repeated mutation of a list then a freeze.
- Use: `Block.choose(f)` for atomic single-pass filter-map into `Option`, replacing a `filter` then `map`; `Block.partition(p)` when both the kept and rejected halves are needed; `Block.collect(f)` to flat-map a per-element `Block` without an intermediate nesting.
- Reject: a mutable `list` appended in a `for` loop as domain flow; a bare `list`/`dict` carried as a carrier's success payload where `Block`/`Map` is the persistent owner the rail should hold; re-enumerating a lazy `Seq` whose cost is paid per pass.

[SEQUENCING_OPERATOR]:
- Law: fail-fast traversal is `expression.extra.result.traverse(step, block)` — the substrate's own applicative threader that maps each element through a `Result`-returning step, short-circuits the whole `Block` on the first `Error`, and collects every `Ok` into `Result[Block[T], E]` — and `sequence(block_of_results)` is `traverse(identity, ...)` for an already-railed `Block`; the hand-rolled seed-`bind` fold over `Ok(Block.empty())` is the rejected reimplementation of a primitive the package already ships.
- Law: the named `threaded` reducer is reserved for a fold the substrate primitive cannot express — a non-append accumulation order, an interleaved running state beside the carrier, a heterogeneous seed — and is then explicit through `Block.fold(threaded, seed)`; a `threaded` re-spelling of plain `traverse` is the COLLAPSE_SCAN wrapper signal, dissolved into the `traverse` call.
- Law: `traverse` aborts on the first `Error` and the accumulating disposition reports every casualty — the carrier alone switches between them — but accumulation needs the fault's own combination law and is therefore realized in `[04]`, where the `swap().to_option()` partition and the `combined` reduction close the casualty set; this card ships only the substrate's fail-fast threader and the bespoke `threaded` fold it cannot express.
- Law: a dependent chain — each step's input the prior step's output, the ladder `traverse` cannot express — has two forms the carrier short-circuits identically: `expression.extra.result.pipeline(*arrows)` composes the `Callable[[A], Result[B, E]]` arrows kleisli (`>=>`) and threads the carrier point-free with no intermediate name, the dense form when only the terminal value survives; `@effect.result[T, E]()` is the generator do-notation where each `yield from` is a `bind` and the `return` is the final `Ok`, earned exactly when an earlier intermediate must be re-used by a later step — value reuse is the discriminant, never chain length, and a chain whose every intermediate feeds only its successor stays `pipeline`.
- Boundary: the dispatch over a modality (`T | Iterable[T]`) and the head-normalization that drives it are the surfaces page's; this page composes `traverse` to state the failure semantics that dispatch carries, never to re-teach the arity normalization.
- Reject: a hand-rolled seed-`bind` fold where `traverse`/`sequence` states it; `map` then a manual carrier unwrap; an index-threaded fold unless the fold genuinely carries algorithm state; a `match` on the carrier tag where `bind`/`choose` already routes both arms.

```python conceptual
from functools import partial
from typing import Literal

from expression import Error, Ok, Result, effect
from expression.collections import Block
from expression.extra.result import pipeline, sequence, traverse

type TraverseFault = Literal["<empty>", "<over>"]


def gauged(ceiling: int, raw: str, /) -> Result[int, TraverseFault]:
    return Error("<empty>") if raw == "" else Error("<over>") if len(raw) > ceiling else Ok(len(raw))


def _trimmed(raw: str, /) -> Result[str, TraverseFault]:
    return Ok(stripped) if (stripped := raw.strip()) else Error("<empty>")


def traversed(raws: Block[str], ceiling: int, /) -> Result[Block[int], TraverseFault]:
    return traverse(partial(gauged, ceiling), raws)


def resequenced(railed: Block[Result[int, TraverseFault]], /) -> Result[Block[int], TraverseFault]:
    return sequence(railed)


def piped(ceiling: int, raw: str, /) -> Result[int, TraverseFault]:
    return pipeline(_trimmed, partial(gauged, ceiling))(raw)


def stitched(raws: Block[str], budget: int, /) -> Result[Block[int], TraverseFault]:
    def threaded(acc: Result[tuple[int, Block[int]], TraverseFault], raw: str, /) -> Result[tuple[int, Block[int]], TraverseFault]:
        return acc.bind(lambda state: gauged(state[0], raw).map(lambda n: (state[0] - n, state[1].cons(n))))

    return raws.fold(threaded, Ok((budget, Block.empty()))).map(lambda state: state[1])


@effect.result[int, TraverseFault]()
def assembled(head: str, tail: str, ceiling: int):
    first = yield from gauged(ceiling, head)
    second = yield from gauged(first, tail)
    return first + second
```

## [04]-[FAULT_VOCABULARY]

The failure type is a closed vocabulary the program owns, and the carrier realizes its disposition: independent faults abort or accumulate by the chosen disposition, a dependent chain aborts on the first cause. Apply carrier-qualified failure transforms before collapse; a carrier transform never raises, and recovery keys on the fault's own code or case, never on a reconstructed message, so a fault re-spelled with `map_error` still routes to the right arm.

| [INDEX] | [COMBINATOR]         | [CARRIER]          | [USE]                          |
| :-----: | :------------------- | :----------------- | :----------------------------- |
|  [01]   | `.map_error(f)`      | `Result`, `Try`    | re-spell the fault, keep cause |
|  [02]   | `.or_else_with(f)`   | `Result`, `Option` | recover from the fault         |
|  [03]   | `.swap()`            | `Result`           | route the fault half           |
|  [04]   | `.merge()`           | `Result`           | collapse same-typed arms       |
|  [05]   | `.filter_with(p, f)` | `Result`           | guard with a fault on fail     |
|  [06]   | `.default_with(f)`   | `Result`, `Option` | terminal lazy fallback         |

[VOCABULARY_SHAPE]:
- Law: the failure type is a closed family — a `Literal` set for a handful of causes, a `StrEnum` when the causes are iterated or wire-carried, a `@tagged_union` fault family when a cause carries a structured payload — chosen by `shapes.md`'s owner discriminants and admitted through its two-tier `of_*` constructor, so the interior never hand-builds a malformed fault; this card spends its lines on the one thing the shape alone does not decide, which disposition the carrier realizes.
- Law: the disposition is the correctness decision this page owns, orthogonal to whether the operands are independent or dependent: independent operands compose applicatively and the disposition is a free choice the carrier realizes — `Result.map2`/`Option.starmap` over a fixed arity and `traverse`/`sequence` over a batch both abort on the first fault, while the partitioning fold combines every one — whereas dependent operands are abort-only, because a `bind` chain's later step consumes the earlier value and has nothing left to accumulate against. A deadline, a cancelled scope, or a task-group fault enters as one more case in the family, the scope that raised it owned by the concurrency page; the disposition rides as the surfaces page's policy value, never a `strict: bool` the body re-derives.
- Law: the accumulating disposition is only realizable when the fault type carries a combination law — `Fault.combined` is an associative monoid whose `aggregate` case holds the typed members and whose `_members` normalization flattens nested aggregates so `Block.reduce(Fault.combined)` closes the casualty set keeping each member structurally addressable instead of message-collapsed; this monoid is the fault-side instance of the same combination law a receipt carries in `[05]`, and a fault family without it can only abort.
- Law: a fault is migrated through the same combinators as the success half — `map_error` re-spells the category later without losing the `of_detail` provider message it carries, `to_result_with` supplies the fault as a zero-argument thunk paid only on the absent branch, and recovery keys on the case or code the fault still carries, never the re-spelled message.
- Reject: `Exception` subclasses as the interior fault type; a bare `str` fault for a multi-cause domain; `None` standing in for failure; recovery by `==` over a message; an aggregate that joins members into one string and erases their codes; a disposition re-derived from a flag the policy value already carries.

```python conceptual
from enum import StrEnum
from typing import Literal, assert_never

from expression import Error, Ok, Option, Result, case, tag, tagged_union
from expression.collections import Block
from expression.extra.result import sequence

type FaultDefect = Literal["<empty-detail>"]


class Disposition(StrEnum):
    ABORT = "<abort>"
    ACCUMULATE = "<accumulate>"


@tagged_union(frozen=True)
class Fault:
    tag: Literal["bounds", "detail", "deadline", "aggregate"] = tag()
    bounds: tuple[int, int] = case()
    detail: tuple[str, str] = case()
    deadline: float = case()
    aggregate: tuple["Fault", ...] = case()

    @staticmethod
    def of_detail(category: str, message: str, /) -> Result["Fault", FaultDefect]:
        return Ok(Fault(detail=(category, message))) if message else Error("<empty-detail>")

    @staticmethod
    def _members(fault: "Fault", /) -> tuple["Fault", ...]:
        return fault.aggregate if fault.tag == "aggregate" else (fault,)

    @staticmethod
    def combined(left: "Fault", right: "Fault", /) -> "Fault":
        return Fault(aggregate=(*Fault._members(left), *Fault._members(right)))


def guarded(found: Option[int], low: int, high: int, /) -> Result[int, Fault]:
    return found.to_result_with(lambda: Fault(bounds=(low, high))).filter_with(
        lambda score: low <= score <= high, lambda _s: Fault(bounds=(low, high))
    )


def reported(scores: Block[tuple[Option[int], int, int]], disposition: Disposition, /) -> Result[Block[int], Fault]:
    railed = scores.starmap(guarded)
    match disposition:
        case Disposition.ABORT:
            return sequence(railed)
        case Disposition.ACCUMULATE:
            faults = railed.choose(lambda r: r.swap().to_option())
            return Ok(railed.choose(lambda r: r.to_option())) if faults.is_empty() else Error(faults.reduce(Fault.combined))
        case _ as unreachable:
            assert_never(unreachable)


def respelled(outcome: Result[int, Fault], /) -> Result[int, Fault]:
    return outcome.map_error(lambda fault: Fault(detail=("<recovered>", fault.detail[1])) if fault.tag == "detail" else fault)
```

## [05]-[STATE_RECEIPTS]

State belongs at a boundary or session owner, and producer count alone selects its carrier: a single producer threads the frozen owner immutably, each step returning the next owner with no cell and no contention, while a many-producer cell is the boundary owner's serialized agent whose drain, token, apply, and reply mechanics that page owns. A typed receipt carries evidence; a fact stream carries chronology; neither collapses into a generic ledger.

[RECEIPTS]:
- Law: the split is capability — a fact stream answers what happened and when, a typed receipt answers how this computation resolved — and it is the page's region because no upstream owner carries chronology-versus-evidence; one `@tagged_union` fact owner makes resolve, supersede, retire, and fault its cases over the settled exhaustiveness mechanic `shapes.md` owns, the slot a derived projection and the payload each case's own evidence, so parallel record types synced by hand never appear.
- Law: keep a typed receipt — a frozen owner whose fields carry solver, sampling, route, status, metric, or proof evidence — when the fields are evidence; projection by kind, group-by-slot-last-wins, and full chronology are pure folds over the one fact stream, and a receipt combines through the same monoidal `combined` law the fault carries in `[04]` — `Receipt.combined` is its evidence-side instance — never a generic accumulator.
- Reject: parallel `added`/`updated`/`removed` lists kept in sync; a `Literal` tag beside a `Receipt | str` payload where the case family carries the evidence; a generic `dict[str, object]` receipt erasing the typed fields; payload bytes carried on a receipt where a hash suffices.

```python conceptual
from dataclasses import dataclass
from typing import Literal, assert_never

from expression import Nothing, Option, Some, case, tag, tagged_union
from expression.collections import Block, Map


@dataclass(frozen=True, slots=True, kw_only=True)
class Receipt:
    route: str
    samples: int
    residual: float

    @staticmethod
    def combined(left: "Receipt", right: "Receipt", /) -> "Receipt":
        return Receipt(route=right.route, samples=left.samples + right.samples, residual=min(left.residual, right.residual))


@tagged_union(frozen=True)
class Fact:
    tag: Literal["resolved", "superseded", "retired", "faulted"] = tag()
    resolved: tuple[str, Receipt] = case()
    superseded: tuple[str, Receipt] = case()
    retired: str = case()
    faulted: tuple[str, str] = case()

    @property
    def slot(self) -> str:
        match self:
            case Fact(tag="resolved", resolved=(key, _)) | Fact(tag="superseded", superseded=(key, _)) | Fact(tag="faulted", faulted=(key, _)):
                return key
            case Fact(tag="retired", retired=key):
                return key
            case unreachable:
                assert_never(unreachable)

    @property
    def evidence(self) -> Option[Receipt]:
        match self:
            case Fact(tag="resolved", resolved=(_, receipt)) | Fact(tag="superseded", superseded=(_, receipt)):
                return Some(receipt)
            case Fact(tag="retired") | Fact(tag="faulted"):
                return Nothing
            case unreachable:
                assert_never(unreachable)


def collapsed(facts: Block[Fact], /) -> Option[Receipt]:
    return Nothing if (witnessed := facts.choose(lambda fact: fact.evidence)).is_empty() else Some(witnessed.reduce(Receipt.combined))


def latest_per_slot(facts: Block[Fact], /) -> Map[str, Fact]:
    return facts.fold(lambda acc, fact: acc.add(fact.slot, fact), Map.empty())


def faults_in_order(facts: Block[Fact], /) -> Block[tuple[str, str]]:
    return facts.choose(lambda fact: Some(fact.faulted) if fact.tag == "faulted" else Nothing)
```
