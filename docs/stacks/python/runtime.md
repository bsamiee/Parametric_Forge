# [PYTHON_RUNTIME]

This page is the interpreter execution and isolation law: how a unit of work is placed onto an isolation arm — own-GIL subinterpreter, subinterpreter or process pool, or a free-threaded lock — and how the running interpreter is observed without a global scraper. Free-threaded execution (PEP 703) and subinterpreters (PEP 734) are the two execution substrates a bleeding-edge build admits, and the placement choice is one `frozendict` policy row, never a per-call knob. Structured concurrency — task groups, deadlines, cancellation, blocking-call offload — is owned by `concurrency.md`; this page owns the substrate that concurrency runs on and the introspection surfaces that read it.

## [01]-[EXECUTION_AND_ISOLATION]

Mutation ownership and isolation strategy are explicit before any work is placed. The isolation arm is selected by a `Lane` policy value keying a `frozendict` table to its execution function, so a new arm is one row and every caller is untouched; a `lane: str` knob the body re-pairs to a strategy is the rejected smuggle. A subinterpreter owns its own GIL, so own-GIL CPU separation is the lighter isolate below the process boundary; a free-threaded build no longer GIL-serializes shared mutation, so an `RLock` guards exactly the shared cell that loses serialization and `copy_context().run` carries the caller's `ContextVar` state across the guard.

| [INDEX] | [CONCERN]              | [USE]                                                    | [REJECTED_FORM]                      |
| :-----: | :--------------------- | :------------------------------------------------------- | :----------------------------------- |
|  [01]   | interpreter isolation  | `concurrent.interpreters.create`                         | process-only isolation wrappers      |
|  [02]   | own-GIL call dispatch  | `Interpreter.call` / `Interpreter.call_in_thread`        | pickled `exec`-string round trips    |
|  [03]   | interpreter main seed  | `Interpreter.prepare_main`                               | module-global seeding of the isolate |
|  [04]   | cross-interpreter pipe | `interpreters.create_queue` / `is_shareable`             | shared module-global handoff         |
|  [05]   | subinterpreter pool    | `concurrent.futures.InterpreterPoolExecutor`             | process-only CPU pools               |
|  [06]   | process-pool stop      | `ProcessPoolExecutor.terminate_workers` / `kill_workers` | private worker traversal             |
|  [07]   | process interrupt      | `multiprocessing.Process.interrupt`                      | cleanup-hostile `terminate`          |
|  [08]   | worker sizing          | `os.process_cpu_count`                                   | `os.cpu_count` worker counts         |
|  [09]   | GIL-state probe        | `sys._is_gil_enabled`                                    | platform-string free-threading guess |
|  [10]   | iterator sharing       | `threading.serialize_iterator`                           | generator lock wrappers              |
|  [11]   | cross-thread context   | `contextvars.copy_context().run`                         | thread-local async state carry       |
|  [12]   | lazy-import control    | `sys.set_lazy_imports` / `sys.set_lazy_imports_filter`   | manual `sys.modules` lazy shims      |

[FREE_THREADING]:

- Use when: shared mutation, context propagation, or a supported-target claim depends on free-threaded execution.
- Accept: free-threaded Python as a supported target, an `RLock` over the one shared-mutable cell the build no longer serializes, `ContextVar` for async or thread context, `copy_context().run` to carry that context across the guard, and `sys._is_gil_enabled()` as the runtime free-threading probe.
- Reject: experimental no-GIL caveats, implicit GIL serialization, thread-local async state, mutable ambient globals, a coarse lock over computation the cell does not share, and import-time singleton mutation as coordination.
- Law: a free-threaded build makes mutation ownership and context propagation explicit before relying on scheduling or cache behavior; `threading.serialize_iterator(it)` wraps a generator shared across threads so one consumer sees one element without an external lock, the per-iterator serialization the GIL once supplied for free.
- Law: the runtime owns the reification of `language.md`'s module-scope `lazy import` — the `types.LazyImportType` proxy a `lazy` binding lands replaces its module-dict slot with the real object on the name's first `LOAD_GLOBAL`/`LOAD_NAME`, `.resolve()` forces that import eagerly and returns the object for a proxy held before its first load, and `sys.lazy_modules` is the per-interpreter `set` of dotted names deferred but not yet reified, diagnostic-only and dropping each name as it resolves.
- Law: global lazy-import policy is one interpreter lever, never a per-call knob — `sys.set_lazy_imports(mode)`, over its `-X lazy_imports=`/`PYTHON_LAZY_IMPORTS=` startup equivalents, takes `"normal"` (only `lazy`-marked imports defer), `"all"` (every top-level import defers), or `"none"` (no deferral even when marked), and the `sys.set_lazy_imports_filter` callback `(importer, name, fromlist) -> bool` returns `False` to force one module eager against that lever, the escape hatch so a codec, dtype, driver, or plugin registration side effect fires at a controlled point and never defers to an arbitrary first-use site, which under a free-threaded build is an arbitrary worker thread.
- Boundary: the async-scheduling axis — task groups, deadlines, cancellation, and the `anyio.to_interpreter`/`to_process` offload onto these arms — is owned by `concurrency.md`, never by a free-threading surface here; the same-task scoped `ContextVar.set` token restore is `system-apis.md`'s, distinct from this page's cross-guard `copy_context().run` carry.

[INTERPRETER_ISOLATION]:

- Use when: interpreter isolation, independent execution, or own-GIL CPU separation owns the runtime boundary below the process boundary.
- Accept: `interpreters.create()` (each subinterpreter owns its GIL), `Interpreter.call(fn, *args, **kwargs)` to dispatch a real callable into the isolate, `Interpreter.call_in_thread` for the non-blocking form, `Interpreter.prepare_main(**ns)` to seed shareable names into the isolate's `__main__` for a callable that reads them as globals (distinct from `call`'s direct argument dispatch, never stacked on it), and `create_queue()` with `Queue.put`/`get` and an `is_shareable` proof for streaming cross-interpreter transport where the blocking `call` returns one terminal.
- Law: the isolation strategy is a `Lane` policy value keying the `STRATEGY` `frozendict` to its execution arm — own-GIL subinterpreter, subinterpreter pool, process pool, or free-threaded lock — so a new lane is one row, and a placement fault is one `Lapse` owner carrying the `Lane` discriminant and the failing type name, addressable by lane and constructed once where the weave reads the table key, never a per-arm fault case the body re-states nor a bare `str` the body concatenates.
- Law: an arm returns `Result[T, str]` because the failing-name read is per-arm: the subinterpreter arm catches `interpreters.ExecutionFailed` and reads `fault.excinfo.type.__name__` (the `excinfo` is a `SimpleNamespace` whose `type` carries `__name__`/`__qualname__`/`__module__`, not a live class because the original is unpicklable across the isolate), while the shared pooled arm and the free-threaded arm catch a live `Exception` and read `type(fault).__name__`; the `placed` weave maps that name onto `Lapse(lane=lane, failing=...)` once, so the lane is named at the table key and never restated inside an arm.
- Law: the subinterpreter-pool and process lanes are one `_pooled` arm separated by a single `retire: Callable[[Executor], object]` policy value bound positionally per row — `ProcessPoolExecutor.kill_workers` retires a stuck process pool the `with`-exit `shutdown` otherwise blocks on, the no-op defers the subinterpreter pool to `shutdown` alone because `InterpreterPoolExecutor` carries no `kill_workers` — so a new executor lane is one row plus its retire value, never a second copied body, and `result()` re-raises the child fault that a `BrokenInterpreterPool`/`BrokenProcessPool` marks. The table-dispatch and decorator-weave mechanics are settled at `surfaces-and-dispatch.md` and composed here.
- Reject: a process-pool wrapper where interpreter isolation is the owner; a pickled `exec` string where `Interpreter.call` dispatches the callable directly; shared mutable module state read across an interpreter boundary; a `NotShareableError`-prone object pushed through `create_queue` without an `is_shareable` proof; a per-lane fault case where one `Lapse` owner carries the lane discriminant; a `Lane` smuggled in as a `lane: str` knob the body re-pairs to a strategy the value already selects.
- Boundary: process isolation survives only where the process boundary is the actual requirement — `ProcessPoolExecutor.terminate_workers()`/`kill_workers()` retire a stuck pool and `multiprocessing.Process.interrupt()` sends `SIGINT`, surfacing as `KeyboardInterrupt` in the child so its `finally` cleanup runs, where `terminate` sends an uncatchable `SIGTERM` that strands handles; the `create()` interpreter is the lighter isolate when shared address space is acceptable.

```python conceptual
import os
import sys
from collections.abc import Callable
from concurrent import interpreters
from concurrent.futures import Executor, InterpreterPoolExecutor, ProcessPoolExecutor
from contextlib import AbstractContextManager, nullcontext
from contextvars import copy_context
from dataclasses import dataclass
from enum import StrEnum
from functools import partial, wraps
from threading import RLock

from builtins import frozendict
from expression import Error, Ok, Result


class Lane(StrEnum):
    ISOLATE = "<lane-a>"
    POOL = "<lane-b>"
    PROCESS = "<lane-c>"
    LOCKED = "<lane-d>"


@dataclass(frozen=True, slots=True, kw_only=True)
class Lapse:
    lane: Lane
    failing: str


type Placed[T] = Result[T, Lapse]


def _isolate[**P, T](operation: Callable[P, T], /, *args: P.args, **kwargs: P.kwargs) -> Result[T, str]:
    runtime = interpreters.create()
    try:
        return Ok(runtime.call(operation, *args, **kwargs))
    except interpreters.ExecutionFailed as fault:
        return Error(fault.excinfo.type.__name__)
    finally:
        runtime.close()


def _pooled[**P, T](
    factory: Callable[..., Executor], retire: Callable[[Executor], object], operation: Callable[P, T], /, *args: P.args, **kwargs: P.kwargs
) -> Result[T, str]:
    with factory(max_workers=os.process_cpu_count()) as pool:
        try:
            return Ok(pool.submit(operation, *args, **kwargs).result())
        except Exception as fault:
            retire(pool)
            return Error(type(fault).__name__)


_GATE = RLock()


def _locked[**P, T](operation: Callable[P, T], /, *args: P.args, **kwargs: P.kwargs) -> Result[T, str]:
    guard: AbstractContextManager[object] = nullcontext() if sys._is_gil_enabled() else _GATE
    try:
        with guard:
            return Ok(copy_context().run(operation, *args, **kwargs))
    except Exception as fault:
        return Error(type(fault).__name__)


STRATEGY: frozendict[Lane, Callable[..., Result[object, str]]] = frozendict({
    Lane.ISOLATE: _isolate,
    Lane.POOL: partial(_pooled, InterpreterPoolExecutor, lambda _: None),
    Lane.PROCESS: partial(_pooled, ProcessPoolExecutor, ProcessPoolExecutor.kill_workers),
    Lane.LOCKED: _locked,
})


def placed[**P, T](lane: Lane = Lane.ISOLATE, /) -> Callable[[Callable[P, T]], Callable[P, Placed[T]]]:
    run = STRATEGY[lane]

    def weave(operation: Callable[P, T], /) -> Callable[P, Placed[T]]:
        @wraps(operation)
        def call(*args: P.args, **kwargs: P.kwargs) -> Placed[T]:
            return run(operation, *args, **kwargs).map_error(lambda failing: Lapse(lane=lane, failing=failing))

        return call

    return weave
```

## [02]-[RUNTIME_INTROSPECTION]

Introspection reads where and how the interpreter ran — execution location, memory, the collector, the active exception, and security-sensitive events — through scoped, retiring probes, never a whole-program scraper. The three memory evidences are orthogonal and fold into one typed `Witness`: the managed-heap tracer sees Python objects per frame, the whole-process reading batched in one `oneshot` sees native and extension allocations the tracer never records, and the collector reports per-generation frequency, scan volume, and pause. Observation takes three shapes — the per-call measurement bracket that emits a `Witness`, the code-scoped `sys.monitoring` probe whose `Probe` kind keys its `(tool_id, event_mask)` row and whose callback returns `sys.monitoring.DISABLE` to retire itself at a hot location while `restart_events` re-arms the disabled set, and the interpreter-global gate that forwards a closed `Audited` event set through one irreversible `sys.addaudithook`. Telemetry egress — structured records, spans, cross-process propagation — is not a runtime concern and rides the observability domain; this page stops at the interpreter-execution evidence the egress later carries.

| [INDEX] | [CONCERN]              | [USE]                                         | [REJECTED_FORM]                        |
| :-----: | :--------------------- | :-------------------------------------------- | :------------------------------------- |
|  [01]   | scoped execution probe | `set_local_events(tool_id, code, events)`     | `settrace` / `set_events` scrapers     |
|  [02]   | callback retire/re-arm | `sys.monitoring.DISABLE` + `restart_events`   | per-call global event toggles          |
|  [03]   | audit interception     | `sys.addaudithook`                            | monkeypatch security probes            |
|  [04]   | native frame dump      | `faulthandler.dump_c_stack`                   | external native stack probes           |
|  [05]   | all-thread hang watch  | `faulthandler.dump_traceback_later`           | a manual watchdog thread               |
|  [06]   | managed-heap snapshot  | `tracemalloc.take_snapshot` + `reset_peak`    | manual allocation counters             |
|  [07]   | process accounting     | `psutil.Process().oneshot()`                  | `resource.getrusage` per-attribute     |
|  [08]   | collector evidence     | `gc.freeze` / `gc.get_stats` / `gc.callbacks` | opaque collection guesses              |
|  [09]   | remote script attach   | `sys.remote_exec(pid, path)`                  | debugger injection hooks               |
|  [10]   | fine-grained location  | `code.co_positions`                           | `co_lnotab` decoding                   |
|  [11]   | active exception       | `sys.exception()`                             | `sys.exc_info()[1]`, traceback strings |
|  [12]   | deprecation marker     | `@warnings.deprecated()`                      | docstring-only deprecation notices     |

[SCOPED_PROBE]:

- Use when: a runtime-owned surface explains execution behavior, performance, security observation, or failure location.
- Accept: `sys.monitoring` tool-id registration scoped to one `__code__`, `sys.addaudithook` for security events, `faulthandler.dump_c_stack` for the native frame and `faulthandler.dump_traceback_later(timeout)` as the all-thread hang watchdog for the cross-thread deadlock no single-thread trace catches, `sys.remote_exec(pid, path)` as the safe attach point (the target reads the named script file at its next checkpoint, so the file must outlive the read), and `co_positions()` for column-precise traceback locations where `co_lines` carries only line ranges.
- Law: the probe kind is a closed vocabulary, not a tool-id parameter — one `Probe` member keys the `SCOPE` `frozendict` to its `(tool_id, event_mask)` row, so a new probe (`FAULT` raises, `RETURN` returns, `STEP` steps) is one row and the callback stays polymorphic over the event family because every admitted event passes `(code, instruction_offset, *rest)` with the offset second, so `co_positions()[offset // 2]` reads the raise/return/step site uniformly and the trailing exception or return value falls into `*rest`; the `LINE` event is excluded from the family precisely because its callback passes a line number where the offset belongs, so a per-event `tool=`/`events=` knob pair the body re-pairs is the rejected form and a line-keyed event mixed into the offset family is the rejected smuggle.
- Law: `sys.monitoring` scopes events to the observed code object through `set_local_events(tool_id, code, events)`, never `set_events` global — a process-wide `RAISE` scraper fires on every internal `StopIteration` of the generator and context-manager protocol, so observation targets one `__code__`, a registered callback returns `sys.monitoring.DISABLE` to retire itself at a hot location, and `restart_events()` re-arms the disabled set; `settrace` is the rejected whole-program scraper.
- Law: observation is a root-scoped primitive, not a per-call decorator arm — installing a monitoring callback inside an invocation aspect rescrapes on every call, so the probe registers once at the observation root over the target `__code__`.
- Law: the audit gate is the interpreter-global security observer the scoped probe is not — `sys.addaudithook(hook)` installs one irreversible hook firing on every `sys.audit` event, so the watched set is a closed `Audited` vocabulary membership-tested inside a total hook that neither rails nor raises because a raising audit hook aborts the audited operation, and the gate forwards the matched `(event, args)` pair rather than scoping to one `__code__`.
- Reject: frame-pointer-stripped native builds, `settrace`/`threading.settrace_all_threads` event scrapers, `set_events` global registration for a scoped probe, a monkeypatched or detach-expecting security probe where `sys.addaudithook` is irreversible, `co_lnotab` decoding, a manual watchdog thread where `dump_traceback_later` arms one, and line-only diagnostics that discard column positions.

[MEMORY_AND_COLLECTOR]:

- Use when: managed-heap growth, native-allocation peak, collector pressure, process-handle accounting, or a scoped resource ceiling is the evidence sought.
- Accept: `tracemalloc.take_snapshot()` for the per-frame managed-heap table, `Snapshot.compare_to(other, "lineno")` for the allocation delta, `tracemalloc.reset_peak()` between measured phases; `psutil.Process().oneshot()` batching `memory_full_info()` (`rss`/`uss`), `num_ctx_switches().involuntary`, and `num_fds()` into one syscall collection; `gc.get_stats()` for the per-generation collector row, `gc.freeze()` to retire startup survivors, `gc.callbacks` for a phase observer; `resource.setrlimit` for a scoped POSIX ceiling; and a `msgspec.Struct(..., gc=False)` evidence leaf.
- Law: the three memory evidences are orthogonal and compose into one receipt — `tracemalloc` sees only the Python managed heap per frame, `psutil` sees the whole process including native and extension allocations the tracer never records (`uss` is the truly-private set a process death reclaims), and `gc` sees the collector — so a single `oneshot()` block collapses every process read to one collection, the psutil counterpart to the snapshot pair, and a `resource.getrusage` per-attribute scrape returning `ru_maxrss` alone is the rejected shallow form.
- Law: a memory measurement is a snapshot pair, not a running counter — `take_snapshot` before and after the measured region and `compare_to` reports the per-line growth, while `reset_peak()` zeroes the high-water mark so the next region's peak is its own; the raw `get_traced_memory()` pair is the current/peak scalar, the snapshot the structured evidence.
- Law: the per-generation collector evidence is one `Generation` leaf carrying `collections`/`collected`/`uncollectable`/`candidates`/`duration`, never parallel arrays the generation index re-pairs — `gc.get_stats()` returns one such row per generation, so the leaf keeps the `collections` frequency, the `candidates` scan volume the incremental collector examined that generation, and the `duration` pause seconds that a bare `gc.collect()` return count flattens to one number, and the leaf carries `gc=False` because it holds only non-container fields, dropping the evidence record from the very tracked set it measures; `gc.freeze()` excludes startup survivors from every later scan so steady-state collection scans only the working set.
- Reject: a hand-maintained allocation counter where a snapshot diff carries the per-frame table; a `resource.getrusage` scrape where `psutil.oneshot()` batches the process reading; two parallel per-generation arrays where one `Generation` leaf carries the row; a process-global `setrlimit` raise that outlives its scope; treating `gc.collect()` as a leak fix rather than the collector as evidence.

[ACTIVE_EXCEPTION]:

- Use when: the in-flight exception feeds an introspection surface, or a syntax form changes what the interpreter reports about it.
- Law: the active exception is read through `sys.exception()` — the single-object form that replaces the `sys.exc_info()` triple — and the raise-site `(lineno, end_lineno, col, end_col)` is `co_positions()` indexed at the deepest traceback frame: walk `__traceback__` to its last `tb_next`, then index `tuple(code.co_positions())[tb_lasti // 2]`, because `co_positions()` enumerates every instruction and only `tb_lasti` selects the raising one — a bare `next(co_positions())` reads the first instruction's location, not the fault's. The read never reconstructs a traceback string and never threads an `exc_info` tuple through a signature. Grouped-failure transport into the carrier — `except*` partitioning and `BaseException.add_note` cause preservation — is `concurrency.md`'s group-edge conversion and `rails-and-effects.md`'s boundary-capture law, composed when introspection rides a multi-failure boundary, never re-spelled here.
- Reject: `sys.exc_info()[1]` where `sys.exception()` reads the active exception; a hand-built traceback string where `co_positions` carries the structured location; `next(co_positions())` standing in for the raise-site position it does not name; the top `__traceback__` frame where the deepest `tb_next` frame holds the raise; `return`/`break`/`continue` that exits a `finally` and discards the in-flight exception; a docstring-only deprecation where `@warnings.deprecated()` is the auditable marker the type checker and `DeprecationWarning` filter both see.

```python conceptual
import gc
import sys
import tracemalloc
from collections.abc import Callable
from enum import StrEnum
from functools import wraps
from types import CodeType

import msgspec
import psutil
from beartype import beartype

from builtins import frozendict

_EVENT = sys.monitoring.events
_SELF = psutil.Process()


type Location = tuple[int | None, int | None, int | None, int | None]
type Sink = Callable[["Witness"], None]


class Probe(StrEnum):
    FAULT = "<probe-a>"
    RETURN = "<probe-b>"
    STEP = "<probe-c>"


class Audited(StrEnum):
    OPEN = "open"
    EXEC = "exec"
    IMPORT = "import"


class Generation(msgspec.Struct, frozen=True, gc=False):
    collections: int
    collected: int
    uncollectable: int
    candidates: int
    duration: float


class Witness(msgspec.Struct, frozen=True, kw_only=True):
    qualname: str
    grew: int
    peak: int
    rss: int
    uss: int
    switches: int
    descriptors: int
    generations: tuple[Generation, ...]
    raised: str | None
    at: Location | None


SCOPE: frozendict[Probe, tuple[int, int]] = frozendict({
    Probe.FAULT: (sys.monitoring.PROFILER_ID, _EVENT.RAISE),
    Probe.RETURN: (sys.monitoring.PROFILER_ID, _EVENT.PY_RETURN),
    Probe.STEP: (sys.monitoring.DEBUGGER_ID, _EVENT.INSTRUCTION),
})
_WATCHED: frozenset[str] = frozenset(Audited)


def _at(exc: BaseException, /) -> Location | None:
    frame = exc.__traceback__
    while frame and frame.tb_next:  # Exemption: the traceback chain is a platform linked list with no expression walk.
        frame = frame.tb_next
    return tuple(frame.tb_frame.f_code.co_positions())[frame.tb_lasti // 2] if frame else None


def measured[**P, T](sink: Sink, /) -> Callable[[Callable[P, T]], Callable[P, T]]:
    def weave(operation: Callable[P, T], /) -> Callable[P, T]:
        @wraps(operation)
        def call(*args: P.args, **kwargs: P.kwargs) -> T:
            tracemalloc.start()
            tracemalloc.reset_peak()
            before = tracemalloc.take_snapshot()
            try:
                return operation(*args, **kwargs)
            finally:  # Exemption: the measurement kernel brackets the call to capture its own execution evidence.
                active = sys.exception()
                _, peak = tracemalloc.get_traced_memory()
                with _SELF.oneshot():
                    memory = _SELF.memory_full_info()
                    switches = _SELF.num_ctx_switches().involuntary
                    descriptors = _SELF.num_fds()
                sink(
                    Witness(
                        qualname=operation.__qualname__,
                        grew=sum(stat.size_diff for stat in tracemalloc.take_snapshot().compare_to(before, "lineno")),
                        peak=peak,
                        rss=memory.rss,
                        uss=memory.uss,
                        switches=switches,
                        descriptors=descriptors,
                        generations=msgspec.convert(gc.get_stats(), tuple[Generation, ...]),
                        raised=type(active).__name__ if active else None,
                        at=_at(active) if active else None,
                    )
                )
                tracemalloc.stop()

        return call

    return weave


@beartype
def observed(target: CodeType, sink: Callable[[Location], None], /, *, probe: Probe = Probe.FAULT) -> None:
    tool, events = SCOPE[probe]

    def fired(code: CodeType, offset: int, /, *rest: object) -> object:
        sink(tuple(code.co_positions())[offset // 2])
        return sys.monitoring.DISABLE

    sys.monitoring.use_tool_id(tool, target.co_qualname)  # Exemption: sys.monitoring registration is an imperative C-API seam.
    sys.monitoring.register_callback(tool, events, fired)
    sys.monitoring.set_local_events(tool, target, events)


@beartype
def audited(sink: Callable[[str, tuple[object, ...]], None], /) -> None:
    def hook(event: str, args: tuple[object, ...], /) -> None:  # Exemption: an audit hook fires on every event and neither rails nor raises.
        if event in _WATCHED:
            sink(event, args)

    sys.addaudithook(hook)  # Exemption: addaudithook is an irreversible interpreter-global C-API install.
```
