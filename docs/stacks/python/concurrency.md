# [PYTHON_CONCURRENCY]

Concurrent work runs inside one `anyio` failure boundary, never a loose task set: `create_task_group()` joins every child and cancels its siblings on the first raise, so an orphaned task is structurally impossible and each child's whole disposition rides the `TaskHandle` the group hands back. The deadline is a `CancelScope`, never a `timeout` parameter; cancellation is the backend's own exception re-raised after cleanup, never a `Result.Error`; blocking work offloads through a `CapacityLimiter`-bounded thread, subinterpreter, or process arm; intra-boundary coordination rides `Event`/`Lock`/`Semaphore`/`CapacityLimiter` whose `statistics()` snapshot is the only contention probe; resource brackets dispose on every exit including cancellation under a shielded scope; and a foreign thread re-enters the loop through one `BlockingPortalProvider`, the inbound mirror of the offload arm. The group's `BaseExceptionGroup` converts to the domain fault exactly once at the `except*` edge, and the retry weave sees only a raised transient, never a railed `Error`. This rail runs the carriers `rails-and-effects.md` owns on the interpreter substrate `runtime.md` owns and re-teaches neither — it composes the fault vocabulary, its associative `combined` monoid, and `Result`/`Option` as settled material, owns the inbound `BlockingPortal` bridge whose crossing-fault conversion `boundaries.md` composes, and supplies the task-group runtime that page's serialized state cell drains.

## [01]-[SCOPE_CHOOSER]

This table selects the concurrency primitive for an effect; when an effect matches several rows, the most specific wins, and the failure-boundary row is read before the offload rows.

| [INDEX] | [EFFECT_SIGNATURE]                   | [PRIMITIVE]                          | [REJECTED_FORM]                            |
| :-----: | :----------------------------------- | :----------------------------------- | :----------------------------------------- |
|  [01]   | concurrent children, joined fate     | `create_task_group()` + `start_soon` | `asyncio.gather` / bare `create_task`      |
|  [02]   | child result carried back            | `TaskHandle.return_value`            | shared mutable list, stream gather rig     |
|  [03]   | child must signal readiness          | `group.start` + `task_status`        | a polled `ready: bool` the caller reads    |
|  [04]   | bound the whole effect, abort        | `fail_after(seconds)`                | a `timeout=` parameter threaded inward     |
|  [05]   | bound the whole effect, settle       | `move_on_after(seconds)`             | `asyncio.wait_for` wrapping the call       |
|  [06]   | nearest live bound, no token         | `current_effective_deadline()`       | a deadline argument re-threaded per call   |
|  [07]   | scope tripped, not a fault           | `get_cancelled_exc_class()` re-raise | cancellation caught into `Result.Error`    |
|  [08]   | bound in-flight slots                | `CapacityLimiter` / `Semaphore`      | a counter the body increments by hand      |
|  [09]   | GIL-releasing call or blocking I/O   | `to_thread.run_sync(limiter=)`       | `ThreadPoolExecutor` on the loop           |
|  [10]   | isolate-safe pure-Python CPU         | `to_interpreter.run_sync(limiter=)`  | `to_process` for isolate-safe work         |
|  [11]   | GIL-hostile or isolate-unsafe native | `to_process.run_sync(limiter=)`      | unbounded subprocess fan-out               |
|  [12]   | foreign thread re-enters the loop    | `BlockingPortalProvider` + `call`    | `from_thread.run` from an unspawned thread |
|  [13]   | fault-ordered handle disposal        | `AsyncExitStack` + shielded teardown | bare `try`/`finally` awaiting unshielded   |
|  [14]   | group failure into the vocabulary    | `except*` at the group edge          | `except Exception` over the whole block    |
|  [15]   | retry a raised transient             | `stamina.retry_context` over the op  | retrying a railed `Result.Error`           |
|  [16]   | deterministic timing in a spec       | `MockClock(autojump_threshold=0)`    | wall-clock `sleep` in a test               |

## [02]-[TASK_GROUP]

The task group is the failure boundary: one `async with anyio.create_task_group()` whose `__aexit__` awaits every child and cancels siblings on the first raise. The child carrier rides the handle, not a side channel, and every primitive that bounds or coordinates the children lives inside the same `async with` so its lifetime is the boundary's lifetime.

[CHILD_CARRIER]:
- Law: `group.start_soon(operation, *args)` takes the coroutine function and its arguments — never a pre-built awaitable — and returns a `TaskHandle[T]` carrying the child's whole disposition through the closed `TaskHandle.Status` family (`PENDING`/`FINISHED`/`CANCELLING`/`CANCELLED`/`FAILED`), so the terminal rides `handle.return_value`, read once the `async with` has closed, never a shared mutable list mutated from inside the child and never a `create_memory_object_stream` rig re-implementing it; the stream pair stays the producer-consumer log the boundary page owns, reached only when a child must publish a sequence of intermediates rather than one terminal.
- Law: the child body rails its own offload faults so the group exits clean and every handle settles `FINISHED` — `handle.return_value` then reads the carrier with no re-raise, and the gather yields one `Block[Result[T, E]]` the rail page's fail-fast reducer threads into `Result[Block[T], E]`. A child that raises instead leaves its handle `FAILED`/`CANCELLED` and propagates a `BaseExceptionGroup` from the `async with`, so `handle.return_value` is read only on the all-clean path; the `status`/`exception` accessors — `status` total and never raising, `return_value`/`exception` raising on a non-matching state — are the post-`except*` survivor classification the `[05]` group edge owns, and the deadline verdict that gates the read is the `[03]` owner.
- Law: `handle.cancel()` cancels one child's own scope without tearing down the group — the per-child counterpart to the `[03]` group-wide deadline — so the handle moves `CANCELLING` while the child unwinds its shielded teardown, settles `CANCELLED`, and a sibling-driven abort is this targeted cancel rather than a shared `stop` flag the child polls; `handle.wait()` awaits one child's terminal mid-body where a sibling's spawn gates on that completion alone.
- Use: `group.start(operation, *args)` over `start_soon` when the child must signal readiness — it blocks until the child calls `task_status.started(value)` and returns that value as the listener-bound or port-ready handshake; `return_handle=True` instead returns the `TaskHandle` whose `start_value` carries that handshake and whose `return_value` carries the terminal, so one call both gates on readiness and tracks the child. `start_soon` is fire-and-track with no handshake, and `TASK_STATUS_IGNORED` is the default `task_status` for a child that reports nothing.
- Reject: `asyncio.gather`, `asyncio.create_task`, or a bare `create_task_group` without `async with`; a child appending to a closure-captured list; a `MemoryObjectReceiveStream` drained as the result carrier where the handle already carries it; reading `handle.return_value` on a path the group could have raised through.

[OFFLOAD_LANE]:
- Law: the event loop hosts only already-async non-blocking work, so a synchronous CPU or native body never runs inline on it — every such body is a `to_thread`/`to_interpreter`/`to_process` arm by construction, each under an explicit `CapacityLimiter`, and the offload table carries no fourth "on the loop" lane for a blocking call to select, which makes an `await`-less compute that stalls the scheduler unspellable rather than merely discouraged.
- Law: the arm is keyed by the isolation the call needs, never by a pickle-versus-no-pickle guess — `to_thread.run_sync` for a native call that releases the GIL or a blocking syscall, sharing the address space with zero serialization; `to_process.run_sync` for a GIL-hostile or isolate-unsafe native call that needs its own crash-isolated process and pays a pickle IPC hop each way; `to_interpreter.run_sync` for isolate-safe pure-Python CPU work that wants its own GIL in the same process with no spawn cost, where only a PEP-734-shareable argument or a stateless function crosses copy-free and every other payload still pickles in-process — and every arm takes an explicit `CapacityLimiter` so subsystem concurrency is bounded at the boundary, not left to the per-loop `current_default_*_limiter()` defaults (40-token thread, CPU-count process). The arm is a `frozendict` row keying the `Lane` member straight to the unbound `run_sync` callable, so each `to_X` surface is the row's value with no forwarder wrapping it, a new lane is one entry, and the call site never re-pairs a `lane: str` knob to a dispatcher the value already selects; this `ARM` keys only the `anyio` async-loop crossing, distinct from the own-GIL substrate placement `runtime.md`'s `STRATEGY` table owns — the isolate the `INTERP`/`PROCESS` arms target is that page's, this one stops at the crossing.
- Law: a worker death surfaces as a typed raise the seam converts into a two-case closed family — `BrokenWorkerProcess` from `to_process`, `BrokenWorkerInterpreter` from `to_interpreter` — each kept structurally addressable rather than flattened to one undifferentiated string, so a downstream `match` routes a process death apart from an interpreter death; `abandon_on_cancel=True` on `to_thread.run_sync` lets a cancelled call leave a truly side-effect-free thread running rather than blocking the scope on a thread that ignores cancellation.
- Use: one `CapacityLimiter(slots)` constructed inside the boundary and threaded into every arm of one subsystem; `to_interpreter` over `to_process` whenever the work is isolate-safe and needs no crash-isolated process, since the same-process own-GIL subinterpreter skips the spawn the heavier isolate pays — the pickle cost is shared by both arms, never the discriminant between them.
- Reject: a per-lane forwarder function renaming `to_X.run_sync`; a bare `ThreadPoolExecutor`/`ProcessPoolExecutor` on the loop; an unbounded offload trusting the default limiter; `to_process` for isolate-safe work the in-process subinterpreter already runs without the spawn cost; a single-case `Literal` collapsing the two worker deaths.

[COORDINATION_PRIMITIVE]:
- Law: coordination inside the boundary is an `anyio` primitive, never shared mutable state plus a poll — `Event` is the set-once readiness latch a child awaits before it proceeds, `Lock`/`Semaphore` bound a critical section or an in-flight slot count, `Condition` wakes a waiter on a predicate change, and a `CapacityLimiter` resizes its `total_tokens` at runtime where a fixed `Semaphore` cannot; each is constructed inside the `async with` so it dies with the group and a stale handle is structurally impossible. The single-consumer serialized-state cell and the high-frequency `send_nowait` callback drain are the boundary page's `MemoryObjectStream` surfaces, not this primitive set — this rail supplies the task group they run inside and stops there.
- Law: contention is read through the primitive's own `statistics()` snapshot — `CapacityLimiterStatistics.borrowed_tokens`/`tasks_waiting`, `SemaphoreStatistics.tasks_waiting`, `LockStatistics.owner`, `EventStatistics.tasks_waiting` — never a hand-counted waiter tally the body maintains beside the primitive, so back-pressure evidence is the snapshot the primitive already owns, projected through the child handles into one frozen evidence value rather than a side effect the body tallies.
- Use: a bare `Event` for a value-less one-shot readiness latch a child awaits; `group.start`'s `task_status.started(value)` handshake when readiness must carry a value; `Semaphore(initial_value, max_value=)` when the in-flight bound is fixed, `CapacityLimiter(total_tokens)` when the bound is offload slots resized under load.
- Reject: a `threading.Lock`/`threading.Event` on the async loop; a `ready: bool` flag polled in a sleep loop where an `Event` wakes exactly once; a hand-maintained in-flight counter where a `Semaphore`/`CapacityLimiter` owns the slot count and its `statistics()` owns the evidence.

```python conceptual
from collections.abc import Awaitable, Callable
from enum import StrEnum
from typing import Literal

import anyio
import anyio.to_interpreter
import anyio.to_process
import anyio.to_thread
import msgspec
from anyio import TASK_STATUS_IGNORED, BrokenWorkerInterpreter, BrokenWorkerProcess, CapacityLimiter, TaskHandle
from anyio.abc import TaskStatus
from anyio.lowlevel import checkpoint
from builtins import frozendict
from expression import Error, Ok, Result
from expression.collections import Block

type RunFault = Literal["<broken-process>", "<broken-interpreter>"]
type Offload[T] = Callable[..., Awaitable[T]]


class Lane(StrEnum):
    THREAD = "<lane-a>"
    INTERP = "<lane-b>"
    PROCESS = "<lane-c>"


class Saturation(msgspec.Struct, frozen=True, gc=False):
    at_prime: int
    waiting: int


ARM: frozendict[Lane, Offload[object]] = frozendict({
    Lane.THREAD: anyio.to_thread.run_sync,
    Lane.INTERP: anyio.to_interpreter.run_sync,
    Lane.PROCESS: anyio.to_process.run_sync,
})
BROKEN: frozendict[type[Exception], RunFault] = frozendict({BrokenWorkerProcess: "<broken-process>", BrokenWorkerInterpreter: "<broken-interpreter>"})


async def gathered[T](work: Block[Callable[[], T]], /, *, lane: Lane, slots: int) -> tuple[Block[Result[T, RunFault]], Saturation]:
    arm, limiter = ARM[lane], CapacityLimiter(slots)

    async def railed(job: Callable[[], T], /) -> Result[T, RunFault]:
        try:
            return Ok(await arm(job, limiter=limiter))
        except (BrokenWorkerProcess, BrokenWorkerInterpreter) as broken:
            return Error(BROKEN[type(broken)])

    async def primed(*, task_status: TaskStatus[int] = TASK_STATUS_IGNORED) -> None:
        async with limiter:
            task_status.started(limiter.statistics().borrowed_tokens)

    async def gauged() -> int:
        await checkpoint()
        return limiter.statistics().tasks_waiting

    async with anyio.create_task_group() as group:
        ready: TaskHandle[None, int] = await group.start(primed, return_handle=True)
        handles: Block[TaskHandle[Result[T, RunFault]]] = work.map(lambda job: group.start_soon(railed, job))
        gauge: TaskHandle[int] = group.start_soon(gauged)
    return handles.map(lambda handle: handle.return_value), Saturation(at_prime=ready.start_value, waiting=gauge.return_value)
```

## [03]-[DEADLINE_AND_CANCELLATION]

The bound on an effect is a scope, never a signature parameter: the deadline rides the enclosing `CancelScope`, so it composes through nested calls with no per-call token, and the value's removal loses nothing the scope does not already carry. Cancellation is the backend's own exception, distinct from every domain fault.

[DEADLINE_SCOPE]:
- Law: a deadline is `anyio.fail_after(seconds)` when expiry is a fault — it raises `TimeoutError` the group edge maps into the vocabulary — or `anyio.move_on_after(seconds)` when expiry is a settled outcome the body reads through `scope.cancelled_caught`; the scope-creating boundary admits the duration as one policy value and opens the scope, but no inner call re-threads a `timeout=` the enclosing scope already bounds — the interior reads `current_effective_deadline()` instead, so a deadline forwarded past the scope that owns it is the knob deleted under the knob test.
- Law: nested scopes compose by deadline propagation — `current_effective_deadline()` reads the nearest active bound as monotonic time so an inner operation honours whichever of the outer abort-deadline or inner settle-deadline is sooner, and the inner scope never outlives the outer because the outer cancellation reaches every checkpoint inside it; an inner `fail_after` nested under an outer `move_on_after` lets a per-step abort live inside a whole-effect settle, the two verdicts read independently after their respective scopes.
- Law: `move_on_after` returns and `cancelled_caught` is the post-scope verdict read before any child handle is drained, so the deadline short-circuits the terminal — a timed-out gather returns `Error("<deadline>")` without touching a `return_value` that raises.
- Exemption: the async sequential fold a staged effect runs is the statement-bearing kernel — `anyio` ships no async `traverse` and `Block.fold` is synchronous, so a per-step `await` under a `current_effective_deadline()`-tightened scope rebinds the carrier in a `for` loop, the one place this page's sequence is not an expression.
- Reject: `asyncio.wait_for` wrapping the call; a `timeout: float` parameter threaded through the signature; a deadline read after the handles are gathered where `cancelled_caught` already settled the outcome; `time.monotonic()` arithmetic where `current_effective_deadline()` reads the live bound.

[CANCELLATION_RAIL]:
- Law: cancellation is not failure — it is the `anyio.get_cancelled_exc_class()` exception, re-raised after cleanup runs, never swallowed into a `Result.Error`, because a value returned in place of the re-raise breaks the structured-cancellation contract the group depends on. Cancellation is level-triggered: a swallowed cancellation re-raises at the next checkpoint, so an awaiting teardown that must finish first runs under the `[04]` shielded bracket, and this rail owns only the verdict that the cancelled exception propagates afterward — never a railed value.
- Law: a cancelled scope never retries — the retry predicate refuses the cancellation class first, so the schedule's `on=` names the provider's transient exceptions and a backoff sleep, itself a checkpoint, never re-arms work an outer deadline cancelled; the `[05]-[GROUP_FAULT]` conversion reads the cancellation arm before the worker arm.
- Reject: catching `get_cancelled_exc_class()` and returning a value; a broad `except Exception` over a block whose cancellation must propagate; cleanup-hostile process termination that abandons the shielded teardown; re-raising a railed `Error` to force a retry an outer scope already cancelled.

```python conceptual
from collections.abc import Awaitable, Callable
from typing import Literal

import anyio
from expression import Error, Ok, Result
from expression.collections import Block

type DeadlineFault = Literal["<whole-deadline>", "<step-deadline>"]


async def bounded_step[T](
    step: Callable[[], Awaitable[T]], release: Callable[[], Awaitable[None]], /, *, step_seconds: float
) -> Result[T, DeadlineFault]:
    with anyio.move_on_after(step_seconds):
        try:
            return Ok(await step())
        except anyio.get_cancelled_exc_class():
            with anyio.CancelScope(shield=True):
                await release()
            raise
    return Error("<step-deadline>")


async def staged[T](
    steps: Block[Callable[[], Awaitable[T]]], release: Callable[[], Awaitable[None]], /, *, whole_seconds: float, step_seconds: float
) -> Result[Block[T], DeadlineFault]:
    async def threaded(acc: Result[Block[T], DeadlineFault], step: Callable[[], Awaitable[T]], /) -> Result[Block[T], DeadlineFault]:
        if acc.is_error():
            return acc
        tighter = min(step_seconds, anyio.current_effective_deadline() - anyio.current_time())
        outcome = await bounded_step(step, release, step_seconds=tighter)
        return acc.bind(lambda kept: outcome.map(lambda value: kept.append(Block.singleton(value))))

    with anyio.move_on_after(whole_seconds):
        acc: Result[Block[T], DeadlineFault] = Ok(Block.empty())
        for step in steps:  # Exemption: async sequential fold — no async traverse exists, so the carrier rebinds per awaited step.
            acc = await threaded(acc, step)
        return acc
    return Error("<whole-deadline>")
```

## [04]-[RESOURCE_BRACKET]

The owner that acquires a resource disposes it on every exit — success, domain fault, raised exception, and cancellation. Acquisition order is teardown order reversed, and a later acquisition failing releases every earlier handle.

[BRACKET_OWNER]:
- Law: a dynamic, fault-ordered set of handles rides one `contextlib.AsyncExitStack` whose `enter_async_context` registers each handle as it is acquired, so the stack unwinds in reverse on exit and an acquisition raise mid-build releases the earlier handles before it propagates; a statically scoped single lifetime is one `async with` per handle, the stack reserved for the dynamic set.
- Law: cleanup runs under `with anyio.CancelScope(shield=True):` because an outer deadline or sibling failure cancels the scope mid-teardown otherwise — an unshielded `finally` that awaits is aborted before the handle closes, leaking it; the shielded scope is the named platform-forced statement seam, and the address-bound `await _release(...)` inside it is that seam's only statement.
- Law: a release that itself raises joins the in-flight failure set rather than masking the fault that triggered teardown — `AsyncExitStack.__aexit__` unwinds every registered handle and aggregates a raised teardown into the propagating `BaseExceptionGroup`, so a cleanup fault and the original fault both reach the `[05]` conversion edge as distinct members instead of one shadowing the other.
- Exemption: the `enter_async_context` acquisition call, the shielded `await _release(...)`, and the `yield handle` inside the async context manager are the named platform-forced statement seam.
- Reject: a bare `try`/`finally` whose `finally` awaits without a shield; a handle acquired before the stack that no exit path releases; cleanup that swallows the cancellation exception instead of re-raising after release.

```python conceptual
from collections.abc import AsyncIterator, Callable
from contextlib import AsyncExitStack, asynccontextmanager
from typing import Literal

import anyio
from expression import Error, Result
from expression.collections import Block

type BracketFault = Literal["<acquire-deadline>"]


@asynccontextmanager
async def leased(name: str, acquire: Callable[[str], "Lease"], release: Callable[["Lease"], None], /) -> AsyncIterator["Lease"]:
    handle = await anyio.to_thread.run_sync(acquire, name)
    try:
        yield handle
    finally:
        with anyio.CancelScope(shield=True):
            await anyio.to_thread.run_sync(release, handle)


async def bracketed[T, E](
    names: Block[str],
    body: Callable[[Block["Lease"]], Result[T, E]],
    acquire: Callable[[str], "Lease"],
    release: Callable[["Lease"], None],
    /,
    *,
    seconds: float,
) -> Result[T, E | BracketFault]:
    async with AsyncExitStack() as stack:
        held: Block["Lease"] = Block.empty()
        with anyio.move_on_after(seconds) as scope:
            held = Block.of_seq([await stack.enter_async_context(leased(name, acquire, release)) for name in names])
        return Error("<acquire-deadline>") if scope.cancelled_caught else body(held)
```

## [05]-[GROUP_FAULT]

The group's `BaseExceptionGroup` is the one raise this rail converts into the settled fault vocabulary, exactly once at the group edge through `except*`. The conversion reads the cancellation arm first, partitions the remaining failures into the vocabulary's cases by type, and preserves cause with `add_note`; the fault family, its two-tier constructor, and its associative `combined` monoid arrive finalized from `rails-and-effects.md` — this card weaves them, never re-spelling the combination law. The retry weave wraps each attempt and sees only a raised transient, and a session-bearing consumer opens under the deadline and outlives the group it feeds, so one child's transport fault cancels the siblings and surfaces through the same edge.

[GROUP_CONVERSION]:
- Law: a task group aggregates child failures into a `BaseExceptionGroup` the group edge splits with `except*` — one arm per vocabulary case binding the partitioned subgroup, because `return`/`break`/`continue` are illegal inside an `except*` block, so each arm folds its subgroup into a `Fault` and assigns the running carrier, and the post-scope read folds that carrier and the deadline verdict into one terminal; an `except Exception` over the whole `async with` flattens the group and erases which children failed.
- Law: each `except*` arm reduces its subgroup through the settled `Fault.combined` monoid the rail page owns — every child re-spelled by the vocabulary's two-tier `Fault.of_detail` constructor, the railed results threaded by `Block.choose(to_option)`, and `reduce(Fault.combined)` closing the arm — and accrues onto the prior arm through that same law, so the multi-arm, multi-child accumulation is one associative reduction and no second combination algebra is authored here; the seam composes the monoid, it does not redefine it.
- Law: cause survives the conversion — `BaseException.add_note` annotates each in-flight exception before it is re-spelled into a case, and a release that raised during teardown joins the failure set rather than masking the trigger, so the aggregate fault's typed members stay structurally addressable instead of collapsing to one concatenated string.
- Law: the conversion reads dispositions in fixed order, most-specific arm first — the cancellation class excluded from every `except*` arm and re-raised because it is the backend signal rather than a vocabulary case, then the worker-death arm (`[02]`'s `BrokenWorkerProcess`/`BrokenWorkerInterpreter` routed apart), the transport arm, and the residual `Exception` arm — so a deadline that cancelled the group settles through `scope.cancelled_caught` and never routes through the transient set.
- Reject: a parallel group-only fault family or a re-authored `combined` beside the settled `Fault` monoid; `except Exception` over a task group; a stringified group message standing in for the typed cases; `return`/`break`/`continue` inside an `except*` block; the cancellation class folded into a fault arm.

[RETRY_BOUNDARY]:
- Law: retry triggers only on a raised transient at the effect boundary and wraps each attempt independently — a domain fault already railed as `Result.Error` is not an exception and is never retried, so the boundary maps the retried call's terminal onto the carrier after the schedule returns, and re-raising an `Error` to force a retry is the rejected inversion. `stamina.retry_context(on=...)` yields one `Attempt` per iteration whose body is the single transient-raising op, the inline form when only part of a task body retries; `@stamina.retry(on=...)` is the whole-callable form, and a fixed-policy target reused across sites is one `AsyncRetryingCaller` built once whose `.on(exc)` pre-binds the transient set — the transport transients alone, never the structural worker deaths `[02]` routes at the group edge — so the call site passes only the callable and arguments.
- Law: the schedule is bounded — at least one of `attempts` or `timeout` is non-`None` — and its backoff sleep is an `anyio` checkpoint sniffio-dispatched onto the live backend, so an enclosing `move_on_after` deadline preempts a retry storm and the `[03]` cancellation exclusion keeps a cancelled scope out of the transient set; a `RetryHook` returning a context manager wraps each scheduled wait, so one span opened per attempt rides the retry seam the observability domain's emission owner already legislates, composed here, never re-built.
- Law: a session-bearing consumer is the rail at transport scale — an `AsyncResource` session is an `async with` opened under the deadline and wrapping the task group, so it outlives every child it feeds while one child's raised transient cancels the siblings and surfaces through the group edge, and the session's `aclose` is the post-join shielded teardown the bracket owns; the concrete transport surface, its verification, and its fault taxonomy are the transport owner's, this rail only drives it under the deadline and cancellation it owns.
- Reject: retrying a `Result.Error` by re-raising it; an unbounded retry trusted to stop itself; a second retry implementation beside the composed weave; the cancellation class in the schedule's `on=` set; the session's operations driven outside the group where a transport fault cannot cancel the siblings.

```python conceptual
from collections.abc import Awaitable, Callable

import anyio
import stamina
from anyio import BrokenWorkerInterpreter, BrokenWorkerProcess, TaskHandle
from anyio.abc import AsyncResource
from expression import Error, Nothing, Ok, Option, Result, Some
from expression.collections import Block

_TRANSIENT = stamina.AsyncRetryingCaller(attempts=5, timeout=30.0).on((ConnectionError, TimeoutError))


def _accrued(prior: Option["Fault"], group: BaseExceptionGroup[Exception], note: str, /) -> Option["Fault"]:
    for exc in group.exceptions:  # Exemption: BaseException.add_note mutates in place, the platform's cause-annotation seam.
        exc.add_note(note)
    cased = Block.of_seq(Fault.of_detail(note, type(exc).__name__) for exc in group.exceptions).choose(lambda r: r.to_option())
    if cased.is_empty():
        return prior
    arm = cased.reduce(Fault.combined)
    return Some(prior.map(lambda held: Fault.combined(held, arm)).default_value(arm))


async def converged(
    session: AsyncResource, worked: Callable[[str], Awaitable[str]], inputs: Block[str], /, *, seconds: float
) -> Result[Block[str], "Fault"]:
    handles: Block[TaskHandle[str]] = Block.empty()
    fault: Option["Fault"] = Nothing

    with anyio.move_on_after(seconds) as scope:
        async with session:
            try:
                async with anyio.create_task_group() as group:
                    handles = inputs.map(lambda value: group.start_soon(_TRANSIENT, worked, value))
            except* (BrokenWorkerProcess, BrokenWorkerInterpreter) as died:
                fault = _accrued(fault, died, "<at:worker>")
            except* (ConnectionError, TimeoutError) as transport:
                fault = _accrued(fault, transport, "<at:transport>")
            except* Exception as failed:
                fault = _accrued(fault, failed, "<at:converged>")

    if scope.cancelled_caught:
        return Error(Fault(deadline=seconds))
    return fault.map(Error).default_with(lambda: Ok(handles.map(lambda handle: handle.return_value)))
```

## [06]-[PORTAL_BRIDGE]

The inbound crossing is the mirror of the offload arm: a thread the loop never spawned re-enters async code through one portal, runs its work as structured children of the portal's own task group, and observes the same cancellation the scope carries. The portal lifecycle is this rail's runtime; `boundaries.md`'s host-marshal seam composes it and owns only the conversion of a crossing fault into the closed vocabulary.

[INBOUND_BRIDGE]:
- Law: one `from_thread.BlockingPortalProvider(backend, backend_options)` shares a single event loop across every calling thread, so the bridge is built once and entered per crossing rather than spun up per call; `portal.call(operation, *args)` takes a coroutine function and its arguments — never a pre-built awaitable, the same contract `start_soon` enforces — and blocks the foreign thread until the loop resolves it, while `portal.start_task_soon(operation, *args)` returns a `concurrent.futures.Future` the foreign thread polls, and a call after the loop closed raises `RunFinishedError`.
- Law: `from_thread.run`/`from_thread.run_sync` are the bare bridges valid only inside a portal-spawned worker thread — they reach the loop through the thread-local token the portal installed, so a bare `from_thread.run` from a thread the loop never spawned raises, the worker-thread token rule — and `from_thread.check_cancelled()` raises the host task's cancellation into a long synchronous worker, the inbound counterpart to the offload arm's `abandon_on_cancel`, so a blocking worker observes the scope's cancellation rather than a polled flag.
- Law: `portal.wrap_async_context_manager(cm)` projects an async context manager into a synchronous `with`, so a foreign caller drives an async resource's full lifecycle without a second bracket form, and a task started through the portal dies when the portal stops, never orphaned past the loop that owns it.
- Reject: a pre-built awaitable handed to `portal.call` where the coroutine function plus arguments is the contract; a per-thread event loop where one `BlockingPortalProvider` shares it; `from_thread.run` from a thread the loop never spawned; a raw `ThreadPoolExecutor` bridging into async where the portal owns the crossing; a polled boolean where `check_cancelled` reads the scope's cancellation.

```python conceptual
from collections.abc import Awaitable, Callable
from concurrent.futures import Future
from contextlib import AbstractAsyncContextManager

from anyio.from_thread import BlockingPortalProvider
from expression.collections import Block


def crossed[R, T](
    provider: BlockingPortalProvider,
    opened: Callable[[], AbstractAsyncContextManager[R]],
    preflight: Callable[[R], Awaitable[None]],
    operation: Callable[[R, str], Awaitable[T]],
    inputs: Block[str],
    /,
) -> Block[T]:
    with provider as portal, portal.wrap_async_context_manager(opened()) as resource:
        portal.call(preflight, resource)
        pending: Block[Future[T]] = inputs.map(lambda value: portal.start_task_soon(operation, resource, value))
        return pending.map(lambda task: task.result())
```

## [07]-[BACKEND_PROOF]

`trio` is the backend `anyio` runs on, selected by the `run(backend=...)` argument; the boundary tier targets the `anyio` surface, and the bare `trio` surface is reached only for what `anyio` does not expose — guest-mode hosting, a custom clock, instrument hooks, and the deterministic concurrency kit. A backend swap is one `run` argument, never a rewrite, because the vocabularies are parallel: `create_task_group`/`CancelScope`/`move_on_after`/`create_memory_object_stream` map one-to-one onto `open_nursery`/`CancelScope`/`move_on_after`/`open_memory_channel`, and the retry sleep is a checkpoint on whichever backend `sniffio` detects.

[DETERMINISTIC_KIT]:
- Law: a concurrency spec gates timing on `trio.testing.MockClock(autojump_threshold=0)` injected at `trio.run(main, clock=clock)`, which collapses every idle wait to zero virtual time, so a deadline test runs instantly and deterministically; `trio.testing.wait_all_tasks_blocked()` settles the run to a fixed interleaving before an assertion, `trio.testing.Sequencer()` forces a deterministic cross-task interleaving where ordering is the property under test, and `assert_checkpoints()` proves a block yields to the scheduler — wall-clock `sleep` and timing tolerance in a test are the rejected forms.
- Law: a `trio.abc.Instrument` attached at run entry through `trio.run(..., instruments=[...])` or dynamically through `lowlevel.add_instrument`/`remove_instrument` observes `task_spawned`/`before_task_step`/`task_exited` across the whole run without touching task code, so cross-task tracing and metrics ride the instrument bus rather than a per-task wrapper; `lowlevel.start_guest_run` interleaves a trio run inside a foreign loop by handing trio a `run_sync_soon_threadsafe` callback, the one integration point when trio must coexist with a host loop it does not own.
- Reject: a wall-clock `sleep` or timing tolerance in a deterministic spec; instrumenting each task by hand where one `Instrument` covers the run; mixing `asyncio` primitives into a trio run; catching `trio.Cancelled` directly rather than letting the owning scope re-raise it.

```python conceptual
from collections.abc import Callable
from typing import override

import trio
import trio.testing
from trio.abc import Instrument
from trio.lowlevel import Task


class Spans(Instrument):
    def __init__(self, sink: Callable[[str, str], None], /) -> None:
        self._sink = sink

    @override
    def task_spawned(self, task: Task, /) -> None:
        self._sink("<spawned>", task.name)

    @override
    def task_exited(self, task: Task, /) -> None:
        self._sink("<exited>", task.name)


async def _expired(seconds: float, /) -> bool:
    with trio.testing.assert_checkpoints():
        await trio.sleep(0)
    with trio.move_on_after(seconds) as scope:
        async with trio.open_nursery() as nursery:
            nursery.start_soon(trio.sleep_forever)
            await trio.testing.wait_all_tasks_blocked()
            await trio.sleep(seconds * 2)
    return scope.cancelled_caught


def proven(sink: Callable[[str, str], None], /, *, seconds: float) -> bool:
    clock = trio.testing.MockClock(autojump_threshold=0)
    return trio.run(_expired, seconds, clock=clock, instruments=[Spans(sink)])
```
