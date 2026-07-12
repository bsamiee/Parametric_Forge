# [PYTHON_ITERATION]

Every function body that does real work is one expression over an already-admitted sequence: a fold to a typed seed, a scan to a running trace, a lazy `itertools` pipeline over masked or co-iterated streams, a walrus-tightened comprehension, or a structural recursion bounded by data depth. The value crossed its boundary upstream, so the interior is total over it and never re-validates; the result is built by composing combinators at the depth the standard library and `expression` reach, never a `for` loop accumulating into a mutable list, an index counter the value's own length already answers, or a second pass over a sequence one pass closes. This page owns the pure, carrier-free computation algebra over an admitted in-memory sequence.

Three siblings own the folds this page sets aside, and each is composed here as settled material, never re-derived: a `Result`/`Option` accumulator, `traverse`, and the accumulating fault fold are `rails-and-effects.md`'s carrier algebra; reductions over a `numpy` array are `algorithms.md`'s numeric route; the `T | Iterable[T]` arity head and the `tailrec` dispatch loop are `surfaces-and-dispatch.md`'s. What remains once the carrier, the array, and the dispatch driver are removed is the algebra here — and its one collapse is uniform: a multi-pass scatter folds to one seeded pass, a materialized intermediate dissolves into a lazy combinator, a hand-indexed window becomes a window combinator, nested loops become one `product`, and an unbounded native recursion becomes a streaming-monoid or a marker frontier.

## [01]-[SHAPE_CHOOSER]

A computational shape routes to the form that owns it; the most specific shape wins.

| [INDEX] | [COMPUTATION]                             | [OWNING_FORM]                                | [REJECTED_FORM]                          |
| :-----: | :---------------------------------------- | :------------------------------------------- | :--------------------------------------- |
|  [01]   | several quantities over one sequence      | one-pass `reduce` to a typed struct seed     | a `sum`/`min`/`max`/`len` pass apiece    |
|  [02]   | running or cumulative state               | `accumulate` / `Seq.scan`, the same seed     | an index loop appending each step        |
|  [03]   | masked, trimmed, or bounded stream        | a lazy `compress`/`takewhile`/`islice` chain | nested comprehensions materializing each |
|  [04]   | adjacent-run grouping over an ordered key | `itertools.groupby` on the run key           | `groupby` over unordered input           |
|  [05]   | adjacent pairs or fixed windows           | `pairwise` / `batched`                       | `seq[i : i + n]` or `zip(seq, seq[1:])`  |
|  [06]   | parallel or Cartesian co-iteration        | `zip(strict=True)` / `itertools.product`     | nested `for` loops; unequal-length `zip` |
|  [07]   | one projection guarded by its own value   | a comprehension with a walrus binding        | recompute the projection or a temp var   |
|  [08]   | a multi-stage per-element transform       | a generator function with `yield from`       | a crammed multi-clause comprehension     |
|  [09]   | reduce a bounded recursive structure      | `match`-destructured structural recursion    | a manual stack-and-index walk            |
|  [10]   | a leaf-monoid reduction at depth          | a streaming `(unit, fuse)` frontier          | native recursion past the frame limit    |
|  [11]   | a shape-sensitive reduction at depth      | an `expand`/`combine` marker frontier        | `sys.setrecursionlimit` raising the cap  |
|  [12]   | overlapping subproblems on a pure core    | `@cache` / `@lru_cache` over the function    | a hand-rolled memo `dict`                |

## [02]-[SEED_FOLD]

A function that needs several quantities from one sequence folds them in one pass into a typed seed, and the seed is a frozen struct whose fields are the running invariants. The collapse is the multi-pass scatter: `sum(...)`, `min(...)`, `max(...)`, and `len(...)` over the same iterable are four traversals and a re-materialization; one `reduce(step, values, SEED)` is one. The seed is the growth site — a new statistic is one field plus one line in the step, and every reader of the seed keeps working — so the owner is sized for the family of moments it will carry, not the one in hand.

[STRUCT_SEED]:
- Law: the seed is a `msgspec.Struct(frozen=True, gc=False)` the moment a reader names its fields or a derived projection rides them — evidence, never a field count, decides the named owner; `gc=False` drops the per-step allocation from the tracked set, which is load-bearing because the fold re-allocates the immutable seed once per element. A positional pair no reader names stays a bare `tuple`.
- Law: derived statistics are `@property` projections over the raw accumulators, never extra fold state — `mean` is `total / count` and the second moment is `total_sq / count - mean**2`, so the fold carries sums and the ratios derive at read time; carrying a running `mean` in the seed is the rejected form because it cannot be combined associatively across two partial folds.
- Use: `functools.reduce(step, values, SEED)` for the terminal seed; the step is a pure `(Seed, T) -> Seed` returning a freshly constructed seed, the discriminant of which field advances living in the construction, never an `if` ladder.
- Reject: a `for` loop mutating a seed in place; a `dict` accumulator keyed by statistic name; parallel `sum`/`min`/`max` passes; a running average or variance held as fold state where the raw sums compose and the ratio derives.

[SCAN_TRACE]:
- Law: a scan keeps every intermediate the fold discards — the same `(step, SEED)` pair drives both, `reduce` returning the last seed and `itertools.accumulate(values, step, initial=SEED)` returning the lazy trace of every seed; a running maximum, a prefix total, or a per-step state snapshot is one `accumulate`, never an index loop appending a list.
- Law: the owner splits on whether the trace threads onward — `Seq.scan(step, SEED)` is the `expression` form when the running states feed a further `Seq` transform under `pipe`, and the stdlib `accumulate` is the form when a bare iterator suffices; neither materializes until the consumer pulls, so a downstream `map`/`filter` fuses without an intermediate list.
- Boundary: a fold whose accumulator is a `Result` or whose combination reports faults is `rails-and-effects.md`'s carrier thread, and a reduction over a `numpy` array is `algorithms.md`'s route; this seed is a pure value, total over the admitted element, and the page composes those owners without re-deriving either fold.

```python conceptual
from collections.abc import Iterable, Iterator
from functools import reduce
from itertools import accumulate

import msgspec
from expression.collections import Seq


class Moments(msgspec.Struct, frozen=True, gc=False):
    count: int
    total: float
    total_sq: float
    low: float
    high: float

    @property
    def mean(self) -> float:
        return self.total / self.count if self.count else 0.0

    @property
    def spread(self) -> float:
        return self.total_sq / self.count - self.mean**2 if self.count else 0.0


SEED = Moments(count=0, total=0.0, total_sq=0.0, low=float("inf"), high=float("-inf"))


def stepped(acc: Moments, value: float, /) -> Moments:
    return Moments(
        count=acc.count + 1, total=acc.total + value, total_sq=acc.total_sq + value * value, low=min(acc.low, value), high=max(acc.high, value)
    )


def summarized(values: Iterable[float], /) -> Moments:
    return reduce(stepped, values, SEED)


def traced(values: Iterable[float], /) -> Iterator[Moments]:
    return accumulate(values, stepped, initial=SEED)


def dispersed(values: Iterable[float], /) -> Seq[float]:
    return Seq.of_iterable(values).scan(stepped, SEED).map(lambda moment: moment.spread)
```

## [03]-[LAZY_COMBINATORS]

A multi-stage transform over a stream is one lazy `itertools` pipeline that never materializes an intermediate: each combinator is an iterator over the previous one, bounded memory holds an unbounded source, and the whole chain stays unevaluated until a single consumer pulls. The named combinator replaces the hand-rolled equivalent — `compress` replaces a `filter` reading a parallel boolean list, `takewhile`/`dropwhile` replace a prefix `break`, `groupby` replaces a run accumulator, `pairwise`/`batched` replace an index-stepped slice, `product` replaces a nested loop, and `starmap` replaces a comprehension unpacking each tuple. Surface depth is the metric: a pipeline written below the combinator the standard library already ships re-derives, line by line, what one operator states once.

[STREAM_PIPELINE]:
- Law: flatten with `chain.from_iterable`, mask with `compress` against a positional selector iterable, trim with `takewhile`/`dropwhile`, bound with `islice`, and fan a single consumer into independent passes with `tee` — each is lazy, so the composition is one generator the consumer drives, never a sequence of fully built lists. `tee` buffers every element until the slowest branch consumes it, so it earns its place only across genuinely independent bounded passes, never as a re-iteration of a cheap source.
- Law: `itertools.groupby(stream, key)` groups adjacent runs of equal key and nothing else, so the stream must already be ordered by that key — the platform-forced precondition this card names — and a `groupby` over unordered input silently fragments one logical group into scattered runs. A full regroup of unordered material folds the stream into the persistent keyed `Map` owner `shapes.md` holds — each key's run grown by `Map.change` — composed here, never `groupby(sorted(...))` materializing the whole stream to fake adjacency.
- Use: `starmap(f, pairs)` to apply over already-tupled elements without an unpacking lambda; a generator expression as one pipeline stage when the transform is a single projection the combinators do not name.
- Reject: a nested comprehension that materializes each stage into a list; `groupby` over an unsorted stream; `tee` standing in for a list when one pass suffices; `sorted(...)` inside a lazy chain that defeats the streaming bound.

[WINDOW_ALGEBRA]:
- Law: an index is never spelled — `pairwise(values)` yields each adjacent window, `batched(values, n, strict=True)` yields fixed-width chunks and asserts exact division through `strict`, and `enumerate(values)` carries the position when one is genuinely needed; `range(len(values))` indexing and `seq[i : i + n]` slicing are rejected because the value's own structure already answers the position.
- Law: co-iteration over several sequences has two combinators — `zip(strict=True)` for the parallel, arity-invariant pairing `language.md` owns, composed here so an adjacent-difference or a paired build proves equal length at the seam, and `itertools.product` for the Cartesian pairing that collapses a nested `for i: for j:` into one lazy stream; an unequal-length `zip` without `strict` truncates silently and a hand-written nested loop materializes the cross-product, both rejected.
- Use: `starmap(operation, pairs)` over any of these pairings so the body applies without an unpacking lambda; `frozendict(zip(keys, values, strict=True))` to build a keyed index from two aligned sequences in one expression.
- Reject: a manual `index` counter; `zip(seq, seq[1:])` where `pairwise` states the window; a slice-step loop where `batched` states the chunk; nested `for` loops where `product` states the Cartesian; co-iteration that truncates on the shorter operand.

```python conceptual
import operator
from collections.abc import Callable, Iterable, Iterator
from itertools import batched, chain, compress, groupby, islice, pairwise, product, starmap, takewhile

from builtins import frozendict

type Row = tuple[str, float]


def piped(batches: Iterable[Iterable[Row]], mask: Iterable[bool], cap: int, /) -> Iterator[tuple[str, float]]:
    rows = compress(chain.from_iterable(batches), mask)
    bounded = takewhile(lambda row: row[1] >= 0.0, rows)
    grouped = groupby(bounded, key=lambda row: row[0])
    reduced = ((key, sum(value for _, value in run)) for key, run in grouped)
    return islice(reduced, cap)


def differenced(values: Iterable[float], /) -> Iterator[float]:
    return starmap(operator.sub, pairwise(values))


def paired(keys: Iterable[str], values: Iterable[float], /) -> frozendict[str, float]:
    return frozendict(zip(keys, values, strict=True))


def meshed(rows: Iterable[float], cols: Iterable[float], weigh: Callable[[float, float], float], /) -> Iterator[float]:
    return starmap(weigh, product(rows, cols))


def chunked(values: Iterable[float], width: int, /) -> Iterator[float]:
    return (sum(block) / width for block in batched(values, width, strict=True))
```

## [04]-[COMPREHENSION_FORM]

A comprehension owns exactly one projection and one guard; the moment a second stage or a reused sub-expression appears, it graduates to a generator function or a fold. Within that one stage the walrus is the tightening tool — `(refined := f(x))` computes the projection once, the guard tests the binding, and the output emits it, so the expensive call is paid once and no precondition temporary leaks into the enclosing scope. The form is chosen by what is built: a `tuple`/`frozenset` comprehension for a fixed eager collection, a `frozendict` comprehension for a keyed index, and a generator function when the transform spans stages or the result must stay lazy.

[BOUND_COMPREHENSION]:
- Law: a projection reused inside one comprehension is bound once with `:=` in the guard and emitted from the binding — `tuple(refined for _, value in rows if (refined := f(value)) >= gate)` evaluates `f` once per element, where a guard-plus-output recompute evaluates it twice; the `:=` syntax form is `language.md`'s, and its use to collapse a recompute or a precondition temporary is this card's.
- Law: a keyed build is a `frozendict` comprehension over `enumerate` or a paired source, producing the immutable index in one expression; a `dict` mutated by `index[key] = rank` in a loop is the rejected form, and the immutable-map owner is the `frozendict` `language.md` legislates, composed here as the comprehension's target.
- Use: a `tuple`/`frozenset` comprehension when the collection is eager and bounded; a `frozendict` comprehension when the result is a lookup; a single projection plus a single guard as the whole body.
- Reject: a comprehension carrying two guards and a nested loop where a generator function reads clearer; a list comprehension built only to be consumed once where a generator expression never materializes; a recompute the walrus removes.

[GENERATOR_FUSION]:
- Law: a multi-stage per-element transform is a generator function whose stages compose through `yield from` — a sub-pipeline delegated by `yield from` fuses without an intermediate list, and the whole function stays lazy and bounded.
- Law: a large or unbounded extraction — every element of an open source, every node of a deep structure — returns `Iterator[T]` and materializes only at the persistence or egress edge `boundaries.md` owns, never an eager `tuple`/`Block`/`list` of the whole result held in memory and walked once; a bounded eager `tuple`/`frozenset` sized in hand at admission is the deliberate contrast, not the open stream this card keeps lazy to its consumer.
- Boundary: `yield from` over a `Result`-returning step that short-circuits is the `@effect.result` do-notation `rails-and-effects.md` owns, not this fusion; the carrier-free `yield from` here delegates a pure sub-generator, and the two never merge.
- Reject: a `tuple`/`Block`/`list` that materializes a whole unbounded result for one walk where `Iterator[T]` streams to the egress edge; a stack of `map`/`filter` calls where one comprehension or one generator states the fusion; `yield from` smuggling a carrier the rail page owns.

```python conceptual
from collections.abc import Callable, Iterable, Iterator
from itertools import accumulate

from builtins import frozendict

type Row = tuple[str, float]


def projected(rows: Iterable[Row], refine: Callable[[float], float], gate: float, /) -> tuple[float, ...]:
    return tuple(scaled for _, value in rows if (scaled := refine(value)) >= gate)


def indexed(rows: Iterable[Row], /) -> frozendict[str, int]:
    return frozendict({key: rank for rank, (key, _) in enumerate(rows)})


def fused(batches: Iterable[Iterable[Row]], refine: Callable[[float], float], gate: float, /) -> Iterator[float]:
    kept = (scaled for batch in batches for _, value in batch if (scaled := refine(value)) >= gate)
    yield from accumulate(kept, max)
```

## [05]-[STRUCTURAL_RECURSION]

A computation over a recursive structure is a catamorphism: one function destructures each node with a `match` over its shape and folds the children's results, the leaf arm projecting and the branch arm joining. The destructuring is sequence- and shape-pattern matching over data — `case tuple() as branch` against `case value`, `[head, *tail]` against `[]` — not the closed-union dispatch `language.md` and `surfaces-and-dispatch.md` own and not the `tailrec` dispatch loop that drives a state machine to a fixpoint; this card owns recursion over recursive data and the depth at which native recursion stops being legal.

[CATAMORPHISM]:
- Law: the catamorphism is parameterized by a `leaf` projection and a `join` combine — one `(leaf, join)` algebra serves every reduction over the structure, sum, height, flatten, and render being the pair, never a recursive function per reduction — and the `match` carries the structural arms while the recursion threads each child through the same surface; depth and join shape select the execution form, never the algebra.
- Law: native recursion is legal only to data depth, so `folded` reads a bounded structure and a structure-sensitive `join` (height as `1 + max(children)`, a balanced regroup) freely; an input-scaled or adversarial depth exceeds the interpreter's frame limit and forfeits the recursive form. A leaf-monoid `join` `(unit, fuse)` then runs `folded_deep`, a frontier that streams each leaf into one accumulator with no result stack because `fuse` is associative and order-preserving; a structure-sensitive `join` at that depth runs `folded_safe`, an `expand`/`combine` marker frontier that pushes one `combine(arity)` frame behind each branch's reversed children and applies the `join` over the `arity` results waiting on a second immutable stack once those children resolve. `sys.setrecursionlimit` raising the ceiling is never the answer.
- Exemption: the two explicit frontiers are the page's statement-bearing kernels, licensed by the platform's fixed frame limit — an immutable `Block` work-stack is rebound each turn, the head popped and `match`-destructured, then a branch re-pushed and its leaves fused left-to-right into one accumulator (`folded_deep`) or deferred behind a `combine` marker whose children's results a second immutable stack carries until the `join` (`folded_safe`), so the traversal stays iterative exactly where native recursion overflows.
- Boundary: a dependent dispatch loop whose next step the prior case selects is the `tailrec` continue-or-done trampoline `surfaces-and-dispatch.md` owns; these frontiers consume a recursive structure while the trampoline drives a fixpoint, and the two stay distinct — one folds a structure, the other settles a state.
- Reject: a recursion per reduction where one `(leaf, join)` algebra states them all; native recursion over input-sized depth; `sys.setrecursionlimit` raising the ceiling instead of folding the frontier; a result-stack marker frontier where a leaf monoid streams without one; a manual index walk reconstructing the structure the `match` already destructures.

[MEMO_ASPECT]:
- Law: an overlapping-subproblem recurrence on a pure, hashable-argument core carries memoization as a stacked decorator, never inline state — `@cache` is the unbounded memo and `@lru_cache(maxsize=...)` is the bounded one whose `maxsize` is the policy value the call site chooses by working-set size; every operand the result depends on rides the signature so the cache key fully determines the value, and a memo `dict` threaded through the signature is the open-coded concern the decorator replaces.
- Law: the top-down memo is legal while the dependency chain fits the frame limit, because the decorator caches results but never shortens the stack the first descent still grows; a recurrence whose chain scales past it tabulates bottom-up instead — a `reduce` over the ordered subproblems threading the resolved table as its seed, the structural dual of the cache built on `[02]`'s fold owner — so the deep dynamic program is a fold, never a stack-bound recursion.
- Boundary: a standalone memo over a pure recurrence is this layer's one admitted cross-cutting concern, because the interior is total over admitted values and re-validates nothing; once it co-occurs with a contract, span, or retry, memoization is the ranked `cache` weave wrapping the already-validated body inside the `aspected` stack `surfaces-and-dispatch.md` owns, and a contract, span, or retry never wraps a total interior fold whose rail it invents.
- Reject: a memo `dict` carried as a parameter; a captured mutable operand the cache key omits, so the cache silently diverges from the inputs; a contract or telemetry decorator on a total interior computation; `@cache` on an unhashable-argument or effectful function.

```python conceptual
from collections.abc import Callable, Iterable
from functools import lru_cache
from typing import Literal

from expression import case, tag, tagged_union
from expression.collections import Block

type Tree[T] = T | tuple[Tree[T], ...]


@tagged_union(frozen=True)
class Frame[T]:
    tag: Literal["expand", "combine"] = tag()
    expand: Tree[T] = case()
    combine: int = case()


def folded[T, R](node: Tree[T], leaf: Callable[[T], R], join: Callable[[Iterable[R]], R], /) -> R:
    match node:
        case tuple() as branch:
            return join(folded(child, leaf, join) for child in branch)
        case value:
            return leaf(value)


def folded_deep[T, R](node: Tree[T], leaf: Callable[[T], R], unit: R, fuse: Callable[[R, R], R], /) -> R:
    stack, acc = Block.singleton(node), unit
    while not stack.is_empty():
        head, stack = stack.head(), stack.tail()
        match head:
            case tuple() as branch:
                stack = Block.of_seq(branch).append(stack)
            case value:
                acc = fuse(acc, leaf(value))
    return acc


def folded_safe[T, R](node: Tree[T], leaf: Callable[[T], R], join: Callable[[Iterable[R]], R], /) -> R:
    frames, results = Block.singleton(Frame(expand=node)), Block.empty()
    while not frames.is_empty():
        head, frames = frames.head(), frames.tail()
        match head:
            case Frame(tag="expand", expand=tuple() as branch):
                pending = Block.of_seq(Frame(expand=child) for child in reversed(branch))
                frames = pending.append(frames.cons(Frame(combine=len(branch))))
            case Frame(tag="expand", expand=value):
                results = results.cons(leaf(value))
            case Frame(tag="combine", combine=arity):
                results = results.skip(arity).cons(join(results.take(arity)))
    return results.head()


@lru_cache(maxsize=2048)
def ways(target: int, steps: tuple[int, ...], /) -> int:
    return 1 if target == 0 else sum(ways(target - step, steps) for step in steps if step <= target)
```
