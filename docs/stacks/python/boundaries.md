# [PYTHON_BOUNDARIES]

Foreign material crosses once: a boundary owner projects native handles, sentinels, callbacks, thread-affine work, state cells, and protocol bytes into admitted values or typed rails, so everything the interior receives — values, receipts, policies, effects — is recoverable from declarations rather than from the foreign surface that produced it. The seam is the only site that names a provider type, catches a provider exception, or holds a native lifetime; the interior is total over admitted owners.

## [01]-[SEAM_CHOOSER]

This table selects the owner for a foreign signal; when a signal matches several rows, the most specific wins, and lifetime rows are read before transport rows.

| [INDEX] | [FOREIGN_SIGNAL]        | [SEAM_OWNER]        | [INTERIOR_FORM]                         | [REJECTED_FORM]            |
| :-----: | :---------------------- | :------------------ | :-------------------------------------- | :------------------------- |
|  [01]   | native handle or FFI    | capsule owner       | `Result[T, Fault]` value projection     | raw `ctypes` handle field  |
|  [02]   | borrowed live memory    | scoped view         | detached `bytes`/value copy             | escaping `memoryview`      |
|  [03]   | null or sentinel        | admission projector | `Option[T]` or closed family            | `None`-as-failure payload  |
|  [04]   | callback or event       | subscription value  | stream-fed admitted signal              | orphan handler             |
|  [05]   | foreign-thread re-entry | portal bridge       | `Result` over `BlockingPortal` re-entry | ambient thread check       |
|  [06]   | session or singleton    | token-gated cell    | closed lifecycle family                 | boolean lifecycle flag     |
|  [07]   | protocol payload        | wire converter      | admitted owner                          | codec-bearing domain owner |
|  [08]   | signed byte field       | byte contract       | canonical octets plus hash              | parse-then-reserialize     |

## [02]-[ADMISSION]

The absence taxonomy arrives settled from `shapes.md` — `None`-as-failure never crosses inward, computed non-failing absence is `Option`, a cause-bearing foreign state is a `@tagged_union` case — and the carrier-minting matrix is `rails-and-effects.md`'s. This page owns what neither settles: _where_ a foreign sentinel is admitted, _where_ a plugin set is discovered without importing it, and that every site that can mint absence or activate foreign code is a seam.

[SENTINEL_SITE]:

- Law: a sentinel projects at the single read site that first sees the foreign value, and that line is the last one in the program that names the sentinel — the carrier the rail page's `of_optional`/`to_result` matrix mints crosses inward, and no interior reader re-derives absence from a value it was never handed.
- Law: a sentinel that _re-appears_ after the seam — a transform that can itself return `None`, a nested field that erases late, a provider default surfacing on a second call — is a second admission site, not a leaked first one, so it projects where it appears; the present branch never manufactures `Some(None)`, because a carrier wrapping a foreign sentinel re-leaks the sentinel one hop later and breaks the interior totality the first admission promised.
- Reject: a sentinel admitted once then trusted forever where a later transform re-mints it; a `None`-check threaded through interior flow; a nullable field riding past the seam; a `dict.get(...)` `None` consumed directly; `Option.value` read without an `is_some` proof.

[ENV_ADMISSION]:

- Law: the environment is the one foreign surface whose read, validation, and rail lift fuse into a single admission step — a `pydantic-settings` `BaseSettings` runs the source chain (env, dotenv, secrets dir) at construction, so `os.environ` is never read raw and a missing or malformed variable surfaces as `SettingsError`/`ValidationError` captured once into the seam fault, never a scattered `os.getenv(...) or default` across the interior.
- Law: provision and runtime state are separate axes — a required capability is _always present_ as a port whose value carries its own `unavailable`/`degraded` case, so a settings field is the static admission of presence and the port's tagged state is the dynamic admission of liveness; a `None` field standing in for "the service might be down" conflates the two.
- Reject: a raw `os.environ[...]` read in interior flow; a settings value re-validated past the `BaseSettings` step; a nullable settings field where the absence carries a cause the port should own; a `beartype.vale.Is` refinement on a settings field, which the pydantic validator ignores (`shapes.md` owns the per-validator-metadata law) — the field constraint rides a pydantic-native `AnyUrl`, a constrained type, or a `Field` bound.

[PROBE_SWEEP]:

- Law: a multi-probe admission — several settings groups, capability handshakes, or provider reads admitted together — fixes its abort-versus-accumulate disposition at the seam where the probes run, never downstream, and composes the rail page's settled fold to realize it; the seam's contribution is the locality, that the decision is bound before the first probe rather than reconstructed by a later reader from a `Block` of mixed outcomes.
- Law: a per-probe boundary obligation — a release, a converted provider exception, a token check — attaches at the probe that incurs it, never inside the traverse that sweeps, because a fail-fast traverse abandons the tail probes and their obligations never run; a survivor/casualty partition is admitted only when callers need both the usable values and the rejected facts, and the obligation rides each probe's own rail so an abandoned probe carries no orphaned cleanup.
- Reject: a single rail for a sweep whose callers need every casualty; a cleanup hung off the sweep that a short-circuit skips; a later walk over the admitted set reinterpreting why each probe disappeared.

[PLUGIN_DISCOVERY]:

- Law: a plugin set is read from distribution metadata, never an import-time registry — `importlib.metadata.entry_points(group=...)` (equivalently `.select(group=, name=)` over the returned `EntryPoints`, whose `.groups` and `.names` enumerate the inventory) exposes each `EntryPoint`'s `name`, `group`, `value`, `module`, and `attr` without importing the plugin module, so the available set is recoverable from metadata and discovery runs no plugin code.
- Law: `EntryPoint.load()` is the single eager activation seam — it imports the named module and resolves the attribute exactly once, traversed fallibly through the rail page's fold so a broken plugin lands as one casualty rather than an import-time crash, and the loaded value is handed to the interior's own admission like any other foreign value.
- Law: explicit discovery is the structural replacement for the import-time side-effect registry — a deferred `lazy import` never runs the module body a registering decorator, metaclass, or `__init_subclass__` hook relied on, so that registry silently empties, where metadata discovery plus an explicit `.load()` is independent of whether the plugin module ever imports.
- Reject: an import-time side-effect registry (a decorator appending to a module global, a metaclass, `__init_subclass__`) for a plugin set a `lazy import` would empty; `entry_points()` re-scanned per call where one selection serves; a plugin module imported eagerly to read metadata the `EntryPoint` already carries.

```python conceptual
from collections.abc import Callable
from enum import StrEnum
from importlib.metadata import entry_points
from typing import Literal

from expression import Error, Ok, Option, Result, case, tag, tagged_union
from expression.collections import Block
from expression.extra.result import catch, sequence
from pydantic import AnyUrl, ValidationError
from pydantic_settings import BaseSettings, SettingsConfigDict, SettingsError

type Endpoint = AnyUrl
type AdmitFault = Literal["<unset>", "<malformed>"]


class Sweep(StrEnum):
    STRICT = "<strict>"
    LENIENT = "<lenient>"


class Env(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="<prefix>_", frozen=True, extra="forbid")
    endpoints: tuple[Endpoint, ...]
    fallback: str | None = None


@tagged_union(frozen=True)
class Link:
    tag: Literal["bound", "unavailable"] = tag()
    bound: Endpoint = case()
    unavailable: tuple[Endpoint, str] = case()

    @staticmethod
    def probed(probe: Callable[[Endpoint], Result[None, str]], endpoint: Endpoint, /) -> Result["Link", "Link"]:
        return probe(endpoint).map(lambda _ok: Link(bound=endpoint)).map_error(lambda reason: Link(unavailable=(endpoint, reason)))


def admitted(probe: Callable[[Endpoint], Result[None, str]], disposition: Sweep, /) -> Result[tuple[Block[Link], Option[str]], AdmitFault | Link]:
    try:
        env = Env()
    except SettingsError:
        return Error("<unset>")
    except ValidationError:
        return Error("<malformed>")
    swept = Block.of_seq(env.endpoints).map(lambda endpoint: Link.probed(probe, endpoint))
    fallback = Option.of_optional(env.fallback)
    match disposition:
        case Sweep.STRICT:
            return sequence(swept).map(lambda live: (live, fallback))
        case Sweep.LENIENT:
            return Ok((swept.map(lambda outcome: outcome.merge()), fallback))


def discovered(group: str, disposition: Sweep, /) -> Result[Block[tuple[str, object]], AdmitFault]:
    probed = Block.of_seq(entry_points(group=group)).map(lambda ep: catch(exception=Exception)(ep.load)().map(lambda loaded: (ep.name, loaded)))
    match disposition:
        case Sweep.STRICT:
            return sequence(probed).map_error(lambda _exc: "<malformed>")
        case Sweep.LENIENT:
            return Ok(probed.choose(lambda outcome: outcome.to_option()))
```

## [03]-[LIFETIME]

[CAPSULE_OWNER]:

- Use: native handles, FFI pointers, pinned buffers, pooled values, external cursors, memory-mapped trees, and any foreign object with an explicit release.
- Law: borrowed, owned, and measured lifetimes are cases of one closed `@tagged_union` capsule — the owned and measured cases register release through `weakref.finalize` tied to the owner's identity so disposal fires once when the capsule is collected, the borrowed case projects a detached copy and never disposes; one `use` fold projects a read-only copy across all three dispositions under a single or-pattern so a caller never branches on lifetime to read.
- Law: the measured disposition is the owned, mutable window — a multi-megabyte buffer or memory-mapped tree revised across many edits — and `revised` threads that one owned window through the edit `Block` as a single imperative kernel mutating it in place by slice assignment and returning a write-count `Result`; the per-edit fold that rebinds and recopies the whole buffer is the rejected `O(N*size)` form the platform makes prohibitive, so mutation is the disposition's structural property and `revised` refuses the read-only cases with the `readonly` fault rather than a runtime flag.
- Law: a native borrow spans the full operation that observes the pointer — the view materializes inside the borrow window, the projection copies to owned `bytes` while the window is open, and the window closes before the foreign owner can free; liveness is never tested apart from the consumption it guards, because a separate liveness probe races the free the borrow window already orders against.
- Law: callers receive values or rails, never live handles; the native crossing is the one foreign fault family this page mints — `OSError`/`ctypes.ArgumentError`/`ValueError` split through the rail page's multi-`except` form into the closed `host`/`marshal`/`extent` cases so the syscall errno, the marshalling detail, and the bad extent stay structurally addressable instead of flattening to one provider token, and the discrimination rides the same borrow window the lifetime owns so no provider exception type escapes the seam unconverted.
- Law: deterministic close is the disposition's contract, not GC's — a synchronously released handle closes through a `with` block or the capsule's `weakref.finalize`, and a handle whose release must be awaited or fault-ordered against siblings registers on `concurrency.md`'s `AsyncExitStack.enter_async_context` under that page's shielded teardown; a foreign handle left for `__del__`/GC finalization is rejected wherever close must precede the backing buffer's free, because the deferred finalizer races that free and the late close faults on released memory.
- Exemption: the address-to-view materialization, the `view.release()`/`window.release()` calls, the `weakref.finalize` registration, and the in-place slice assignment over the measured window inside the capsule kernel are the named platform-forced statement seam.
- Reject: a public handle field; scattered manual `close()`; parallel borrowed, owned, and measured wrapper classes where one closed family states them; a `__del__` finalizer owning release where `weakref.finalize` states it; a foreign handle left for GC finalization where a shielded bracket must close it before the backing buffer frees; a fold rebinding the whole buffer per edit where the measured window is mutated in place; `revised` on a read-only disposition.

```python conceptual
import ctypes
import weakref
from collections.abc import Callable
from typing import Literal, assert_never

from expression import Error, Ok, Result, case, tag, tagged_union
from expression.collections import Block


@tagged_union(frozen=True)
class CapsuleFault:
    tag: Literal["host", "marshal", "extent", "readonly"] = tag()
    host: int = case()
    marshal: str = case()
    extent: tuple[int, int] = case()
    readonly: None = case()


@tagged_union(frozen=True)
class Capsule:
    tag: Literal["owned", "borrowed", "measured"] = tag()
    owned: tuple[int, int] = case()
    borrowed: tuple[int, int] = case()
    measured: tuple[int, int] = case()

    @staticmethod
    def acquired(address: int, size: int, release: Callable[[int], None], /) -> "Capsule":
        held = Capsule(owned=(address, size))
        weakref.finalize(held, release, address)
        return held

    @staticmethod
    def viewing(address: int, size: int, /) -> "Capsule":
        return Capsule(borrowed=(address, size))

    @staticmethod
    def measuring(address: int, size: int, release: Callable[[int], None], /) -> "Capsule":
        held = Capsule(measured=(address, size))
        weakref.finalize(held, release, address)
        return held

    def use[T](self, copy: Callable[[memoryview], T], /) -> Result[T, CapsuleFault]:
        match self:
            case (
                Capsule(tag="owned", owned=(address, size))
                | Capsule(tag="borrowed", borrowed=(address, size))
                | Capsule(tag="measured", measured=(address, size))
            ):
                try:
                    view = ctypes.memoryview_at(address, size, readonly=True)
                    try:
                        return Ok(copy(view))
                    finally:
                        view.release()
                except OSError as host:
                    return Error(CapsuleFault(host=host.errno or 0))
                except ctypes.ArgumentError as marshal:
                    return Error(CapsuleFault(marshal=str(marshal)))
                except ValueError:
                    return Error(CapsuleFault(extent=(address, size)))
            case _ as unreachable:
                assert_never(unreachable)

    def revised(self, patches: Block[tuple[int, bytes]], /) -> Result[int, CapsuleFault]:
        match self:
            case Capsule(tag="measured", measured=(address, size)):
                try:
                    window = ctypes.memoryview_at(address, size, readonly=False)
                    try:
                        written = 0
                        for (
                            offset,
                            patch,
                        ) in patches:  # Exemption: measured kernel mutates the owned window in place, the platform-forced statement seam
                            window[offset : offset + len(patch)] = patch
                            written += len(patch)
                        return Ok(written)
                    finally:
                        window.release()
                except OSError as host:
                    return Error(CapsuleFault(host=host.errno or 0))
                except ValueError:
                    return Error(CapsuleFault(extent=(address, size)))
            case Capsule(tag="owned") | Capsule(tag="borrowed"):
                return Error(CapsuleFault(readonly=None))
            case _ as unreachable:
                assert_never(unreachable)


def detached(capsule: Capsule, /) -> Result[bytes, CapsuleFault]:
    return capsule.use(bytes)
```

[REF_SAFE_PROJECTION]:

- Law: the borrow window the capsule's `use` fold opens is strictly synchronous — a `memoryview`/`collections.abc.Buffer` materialized from foreign memory is consumed and copied to owned material before any `await`, because a suspension between the view and its copy lets the foreign owner free the backing store mid-await and the resumed read faults on dangling memory; the value that escapes the window is `bytes(view)` or an owned array, never the view, so the async seam never threads a live foreign buffer through a checkpoint.
- Reject: storing a `memoryview` on a frozen owner; returning the view itself; an `await` between the view materialization and its `bytes(view)` copy; a foreign `Buffer` passed to `to_thread.run_sync` where the loop can free it before the worker reads it.

## [04]-[EVENTS_AND_THREADS]

[SUBSCRIPTION_VALUE]:

- Use: events, callbacks, observers, file watches, notifications, and foreign lifecycle hooks.
- Law: a subscription is the detacher returned by attach, holding the exact callback identity attach used; the callback borrows every touched handle for the whole subscription window, and detach completes before any borrowed handle is released. The detacher is a frozen value with a `close()` method, consumed through `with` or an `AsyncExitStack`, never an inline lambda that cannot be removed.
- Law: the subscription set is the scope — reactivation constructs a fresh set, never appends to a retained one, and the set dies with the live state that owns it.
- Exemption: the attach/detach registration calls and the posted-callback body are the named platform-forced statement seam.
- Reject: an inline lambda passed to `attach` that detach cannot match; a finalizer-owned unsubscribe; split attach and detach owners; host deregistration assumed rather than confirmed.

[HOST_MARSHAL]:

- Law: the seam this card owns is the inbound crossing's evidence — a foreign thread the loop never spawned re-enters through `concurrency.md`'s `BlockingPortal`, and the seam converts that crossing's outcome into a closed fault the interior reads, never the provider exception the bridge raised. The portal lifecycle (`start_blocking_portal`/`BlockingPortalProvider`, the coroutine-function-not-awaitable call contract, the worker-thread token rule for a bare `from_thread.run`) and the outbound offload it pairs with are `concurrency.md`'s runtime; the seam composes the bridge and owns only the conversion, mapping every non-cancellation worker raise into the closed crossing fault so none escapes unconverted.
- Law: a crossing fault carries which crossing failed — loop teardown after the bridge closed, a refused readiness handshake, a converted worker raise — as distinct closed cases, never one stringified provider message, so the `Recovery` predicate sends the loop-closed and handshake-refusal arms to rebuild a fresh provider — a closed loop's provider never re-runs, so reusing it re-faults — while the converted worker raise returns railed to `rails-and-effects.md`'s transient weave, never re-crossed at this seam; cancellation is `concurrency.md`'s re-raised carrier and never enters this fault family.
- Law: context propagation and thread affinity are separate decisions — the bridge copies the caller's context across the crossing, and a callback reading no ambient state needs none; an interior transform never reads ambient thread state to recover what the crossing already carried, because the crossing's evidence is already an admitted value.
- Reject: a `threading.current_thread()` affinity test in interior flow; an ambient `ContextVar` read inside a reusable transform; a fire-and-forget thread launch outside `concurrency.md`'s task group; `from_thread.run` from a thread the loop did not spawn; a stringified provider message standing in for the closed crossing fault.

[HANDOFF_DRAIN]:

- Law: a high-frequency foreign callback submits intent and returns — `concurrency.md`'s memory object stream is the log this seam owns for a consumer that must see every intermediate, and a single committed cell behind the agent is the latest-value register for a per-tick consumer; the consumer's need selects the carrier here, and producer back-pressure is the stream's `max_buffer_size`, its live fill read off `statistics().current_buffer_used` rather than a tally the seam maintains, independent of consumer pacing.
- Law: a bounded stream's full behavior is the seam's declared policy stated where the producer sends — a zero `max_buffer_size` rendezvous-blocks the producer, a positive bound buffers then back-pressures — and `send_nowait`'s two failure signals are distinct dispositions the seam routes, never one collapsed arm: `WouldBlock` on a full positive bound is the back-pressure drop the policy already authorized, while `BrokenResourceError` means every receiver closed, so the callback retires its own subscription rather than dropping into a dead channel forever.
- Reject: blocking the foreign callback on interior work; mutating interior state from the callback thread; the callback running arbitrary downstream logic instead of sending one message; collapsing `WouldBlock` and `BrokenResourceError` into one silent drop.

```python conceptual
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from enum import StrEnum
from typing import Literal

import anyio
from anyio.from_thread import BlockingPortalProvider
from anyio.streams.memory import MemoryObjectSendStream
from builtins import frozendict
from expression import Error, Ok, Result, case, tag, tagged_union


class Recovery(StrEnum):
    RETRY = "<retry>"
    REOPEN = "<reopen>"


@tagged_union(frozen=True)
class CrossFault:
    tag: Literal["loop_closed", "handshake", "worker"] = tag()
    loop_closed: None = case()
    handshake: str = case()
    worker: str = case()


_RECOVERY: frozendict[str, Recovery] = frozendict({"worker": Recovery.RETRY, "handshake": Recovery.REOPEN, "loop_closed": Recovery.REOPEN})


def re_entered[T](provider: BlockingPortalProvider, cross: Callable[[], Awaitable[T]], /) -> Result[T, CrossFault]:
    with provider as portal:
        try:
            return Ok(portal.call(cross))
        except anyio.RunFinishedError:
            return Error(CrossFault(loop_closed=None))
        except RuntimeError as refused:
            return Error(CrossFault(handshake=str(refused)))
        except anyio.get_cancelled_exc_class():
            raise
        except Exception as worker:  # noqa: BLE001 — every non-cancellation provider raise becomes one closed crossing case
            return Error(CrossFault(worker=type(worker).__name__))


def reopened[T](make: Callable[[], BlockingPortalProvider], cross: Callable[[], Awaitable[T]], /) -> Result[T, CrossFault]:
    outcome = re_entered(make(), cross)
    return outcome.or_else_with(lambda fault: re_entered(make(), cross) if _RECOVERY[fault.tag] is Recovery.REOPEN else outcome)


@dataclass(frozen=True, slots=True)
class Subscription:
    detach: Callable[[], None]

    def close(self, /) -> None:
        self.detach()

    def __enter__(self, /) -> "Subscription":
        return self

    def __exit__(self, *_exc: object) -> None:
        self.detach()


def subscribed(emitter: "Emitter", sink: MemoryObjectSendStream["Signal"], /) -> Subscription:
    def handler(raw: object, /) -> None:
        try:
            sink.send_nowait(Signal.of(raw))
        except anyio.WouldBlock:
            pass
        except anyio.BrokenResourceError:
            emitter.off_change(handler)

    emitter.on_change(handler)
    return Subscription(lambda: emitter.off_change(handler))
```

## [05]-[STATE_CELLS]

[SERIALIZING_AGENT]:

- Use: session, singleton, wake, drain, and cross-call boundary lifetime — every cell a foreign edge mutates from more than one task.
- Law: the serialization owner is one consumer task draining a `MemoryObjectReceiveStream[Command]` — the bundled `expression.MailboxProcessor` is forbidden here because it reaches `asyncio.get_event_loop()` against the `asyncio` ban, so the cell rides an `anyio` send/receive pair where producers `send_nowait` a command and the lone consumer applies it. The agent holds the cell as a plain local, replaces the whole immutable reference per applied command, and is the only reader, so a torn multi-field read and a read-modify-write race are both structurally impossible — the `anyio` single-consumer drain is what `threading.Lock` around shared mutable state is the rejected substitute for.
- Law: the lifecycle is a closed `@tagged_union` state family (pending, live, draining, failed; never booleans), the agent's command set is a second closed `@tagged_union` (open, close, drain, poison) folded under one total `match`, and the refusal rail is a third closed `GateFault` vocabulary — never a bare `str` reason — so the `failed` state carries the typed cause and a waiter recovers on the fault's own case rather than a reconstructed message. A new lifecycle verb is one state case plus one command case plus one transition arm, never a new lock, flag, or sibling mutator, so the agent surface absorbs the verb family the next requirement adds (the `draining` state is exactly that growth: one case carrying the deadline and in-flight count, one arm fencing admission).
- Law: each command carries its own reply channel — a per-command `anyio.Event` plus a single-slot result, set after the transition publishes — so a waiter wakes only on committed state, never an attempted or aborted one, and the post-command continuation rides that reply rather than a second flag polled from outside. The transition functions stay pure: `opened`/`closed`/`drained`/`poisoned` take the state and return the successor and its outcome, and the agent is the only impure seam, holding no factory, disposer, deadline await, or external call inside the apply step.
- Law: a stale teardown succeeds only while its token still owns the live state — the transition matches the live token before it acts, so a `close` carrying a superseded token is a total no-op, never a disposed replacement session; the `poison` command moves a live or draining cell to `failed` carrying the typed cause so every later `open`/`drain` refuses on that case, and a faulted cell is escaped only by a fresh agent because a cancelled `anyio.CancelScope` never resets and re-opening replaces the whole scope.
- Law: drain is one command reading phase, in-flight count, and deadline together — admission is fenced the instant the agent applies it, and the post-drain continuation waits on the same reply channel as mid-flight work reaches a typed terminal, never a `threading.Lock` plus a polled second flag.
- Reject: a `MailboxProcessor` on the `anyio` substrate; a `threading.Lock` or shutdown boolean standing in for the agent; a bare `str` reason where the closed `GateFault` carries the cause; a second flag polled from outside the reply; teardown that disposes a replacement session; a factory, deadline await, or external call inside the apply step; acting on a change fired from an aborted transition.

[MEMO_KEY]:

- Law: a boundary memo key binds the foreign identity content alone cannot recover — a provider handle's `id()`, a session token, or a capability fingerprint joins the content and policy axes into one hashable composite, a fixed axis set riding a `tuple` and a dynamic one a `frozendict`, so two payloads identical in bytes but sourced from distinct foreign owners never collide.
- Law: a structural index or tree diff binds the discriminant content alone cannot recover — a node's path-vector or sibling ordinal joins the content digest so two identical-content siblings under one parent key distinctly, the structural axis riding the same composite `tuple` the foreign-identity axis does; an order-sensitive tree keyed on content alone collapses those siblings to one entry and the diff loses the move.
- Reject: a content-only, path-only, or type-only key dropping the foreign axis; a content-only AST or tree key dropping the structural-path axis and collapsing identical-content siblings; a `dict[str, object]` key bag where a fixed `tuple` states the axes; a mutable `dict` memo store where the agent's own state or a `frozendict` snapshot owns the table.

```python conceptual
from collections.abc import Callable
from dataclasses import dataclass, field
from typing import Literal, assert_never

from anyio import BrokenResourceError, Event
from anyio.streams.memory import MemoryObjectReceiveStream, MemoryObjectSendStream
from builtins import frozendict
from expression import Error, Ok, Result, case, tag, tagged_union
from expression.extra.result import catch

type GateFault = Literal["<draining>", "<not-live>", "<faulted>"]


@tagged_union(frozen=True)
class Gate:
    tag: Literal["pending", "live", "draining", "failed"] = tag()
    pending: None = case()
    live: tuple[int, "Session"] = case()
    draining: tuple[int, "Session", float, int] = case()
    failed: GateFault = case()


def opened(gate: Gate, token: int, session: "Session", /) -> tuple[Gate, Result["Session", GateFault]]:
    match gate:
        case Gate(tag="pending"):
            return Gate(live=(token, session)), Ok(session)
        case Gate(tag="live", live=(_, held)):
            return gate, Ok(held)
        case Gate(tag="draining"):
            return gate, Error("<draining>")
        case Gate(tag="failed", failed=cause):
            return gate, Error(cause)
        case _ as unreachable:
            assert_never(unreachable)


def closed(gate: Gate, token: int, /) -> tuple[Gate, Result[None, GateFault]]:
    match gate:
        case Gate(tag="live", live=(active, _)) if active == token:
            return Gate(pending=None), Ok(None)
        case Gate(tag="draining", draining=(active, *_)) if active == token:
            return Gate(pending=None), Ok(None)
        case _:
            return gate, Ok(None)


def drained(gate: Gate, deadline: float, /) -> tuple[Gate, Result[int, GateFault]]:
    match gate:
        case Gate(tag="live", live=(token, session)):
            return Gate(draining=(token, session, deadline, 0)), Ok(0)
        case Gate(tag="draining", draining=(_, _, _, inflight)):
            return gate, Ok(inflight)
        case _:
            return gate, Error("<not-live>")


def poisoned(gate: Gate, cause: GateFault, /) -> tuple[Gate, Result[None, GateFault]]:
    match gate:
        case Gate(tag="failed", failed=prior):
            return gate, Error(prior)
        case _:
            return Gate(failed=cause), Ok(None)


@dataclass(slots=True)
class Reply[T]:
    ready: Event = field(default_factory=Event)
    slot: list[Result[T, GateFault]] = field(default_factory=list)

    def settle(self, outcome: Result[T, GateFault], /) -> None:
        self.slot.append(outcome)
        self.ready.set()


@tagged_union(frozen=True)
class Command:
    tag: Literal["open", "close", "drain", "poison"] = tag()
    open: tuple[int, "Session", Reply["Session"]] = case()
    close: tuple[int, Reply[None]] = case()
    drain: tuple[float, Reply[int]] = case()
    poison: tuple[GateFault, Reply[None]] = case()


async def agent(inbox: MemoryObjectReceiveStream[Command], /) -> None:
    gate = Gate(pending=None)
    async with inbox:
        async for command in inbox:
            match command:
                case Command(tag="open", open=(token, session, reply)):
                    gate, outcome = opened(gate, token, session)
                    reply.settle(outcome)
                case Command(tag="close", close=(token, reply)):
                    gate, outcome = closed(gate, token)
                    reply.settle(outcome)
                case Command(tag="drain", drain=(deadline, reply)):
                    gate, outcome = drained(gate, deadline)
                    reply.settle(outcome)
                case Command(tag="poison", poison=(cause, reply)):
                    gate, outcome = poisoned(gate, cause)
                    reply.settle(outcome)
                case _ as unreachable:
                    assert_never(unreachable)


async def commanded[T](outbox: MemoryObjectSendStream[Command], build: Callable[[Reply[T]], Command], /) -> Result[T, GateFault]:
    reply: Reply[T] = Reply()
    if catch(exception=BrokenResourceError)(outbox.send_nowait)(build(reply)).is_error():
        return Error("<faulted>")
    await reply.ready.wait()
    return reply.slot[0]


def keyed(
    session: "Session", path: tuple[int, ...], content: bytes, policy: frozendict[str, str], /
) -> tuple[int, tuple[int, ...], bytes, frozendict[str, str]]:
    return (id(session), path, content, policy)
```

## [06]-[WIRE_CONTRACTS]

[PROTOCOL_EDGE]:

- Use: payload structs, envelopes, serializer contracts, persisted packets, and remote frames.
- Law: wire shapes stay protocol-shaped at the edge — a `msgspec.Struct` with `rename=`/`forbid_unknown_fields=True` or a pydantic ingress model is the only site where protocol and interior schemas meet, and interior canonical owners carry no codec attributes, serializer options, or transport fields. The converter is the boundary; the domain owner is unaware of the wire.
- Law: inner envelopes reject drift — `forbid_unknown_fields=True` on `msgspec.Struct` and `extra="forbid"` on a pydantic model fail an unknown member before admission — while only a declared `extra_items` band tolerates extension material.
- Reject: a `schema_version` branch on a canonical owner that belongs to read-boundary migration; last-write-wins parse for an owned protocol shape; a domain owner decorated with serializer config.

[CONVERTER_OWNER]:

- Law: one converter owns a closed wire family — `msgspec.json.Decoder(type=Family)` over a tagged union resolves the discriminant once on read and `msgspec.json.Encoder` emits it on write, and `msgspec.convert(owner, Wire, from_attributes=True)` projects a pure field rename when the wire struct keeps canonical attribute names and renames only at the encoded edge; the converter consumes exactly the family it owns and discriminates both wire-rejection paths into distinct fault cases — `msgspec.DecodeError` for malformed bytes, `msgspec.ValidationError` for a constraint or discriminant miss — as separate `except` arms under the shared `msgspec.MsgspecError` base, so neither escapes unconverted and which path failed stays a boundary fact rather than collapsing to one token.
- Law: a value-transforming projection (not a pure rename) rides an explicit constructor or a `frozendict` adapter table, never `msgspec.convert`; the convert path is reserved for name-only correspondence.
- Reject: a converter per case; a case-level codec bypassing the family owner; a sentinel returned from a decoder hook instead of a raised validation error; per-call `Decoder`/`Encoder` construction where one module-level instance serves.

```python conceptual
import hashlib
from typing import Literal

import msgspec
from expression import Error, Ok, Result
from expression.extra.result import catch


class FrameSingle(msgspec.Struct, tag="single", frozen=True, forbid_unknown_fields=True, rename={"at": "t"}):
    at: int


class FrameBlock(msgspec.Struct, tag="block", frozen=True, forbid_unknown_fields=True, rename={"start": "s", "end": "e"}):
    start: int
    end: int


class Signed(msgspec.Struct, frozen=True, forbid_unknown_fields=True):
    coordinate: str
    body: msgspec.Raw


type Frame = FrameSingle | FrameBlock
type WireFault = Literal["<malformed>", "<constraint>"]

_FRAME_DECODER = msgspec.json.Decoder(type=Frame)
_FRAME_ENCODER = msgspec.json.Encoder()
_SIGNED_DECODER = msgspec.json.Decoder(type=Signed)


def decoded(raw: bytes, /) -> Result[Frame, WireFault]:
    try:
        return Ok(_FRAME_DECODER.decode(raw))
    except msgspec.ValidationError:  # subclass of DecodeError — the constraint/discriminant arm reads first
        return Error("<constraint>")
    except msgspec.DecodeError:
        return Error("<malformed>")


def renamed(owner: "Shape", /) -> FrameBlock:
    return msgspec.convert(owner, FrameBlock, from_attributes=True)


def encoded(frame: Frame, /) -> bytes:
    return _FRAME_ENCODER.encode(frame)


def signed(raw: bytes, /) -> Result[tuple[str, str], WireFault]:
    return (
        catch(exception=msgspec.DecodeError)(_SIGNED_DECODER.decode)(raw)
        .map(lambda envelope: (envelope.coordinate, hashlib.sha256(bytes(envelope.body)).hexdigest()))
        .map_error(lambda _exc: "<malformed>")
    )
```

[BYTE_IDENTITY]:

- Use: signatures, content hashes, idempotency keys, checksums, and byte-stable forwarding.
- Law: the sub-tree that must round-trip byte-identically is a `msgspec.Raw` band on the envelope — the decoder holds the inner octets opaque instead of parsing them and a re-encode writes them verbatim, so a float spelled `1.1000`, a `-0.0`, and a non-finite `1e400` survive intact where a parse-then-reserialize re-spells every one; `bytes(raw)` is the exact octet sequence the digest signs, captured before any interior owner sees a parsed value.
- Law: semantic equality and byte equality are different contracts — one `hashlib` surface per byte-identity domain is fixed at composition (`hashlib.sha256(bytes(raw)).hexdigest()`), never chosen per site, and the parsed projection of the same envelope is a separate egress that never feeds the signature.
- Boundary: a receipt carries the coordinate and the hex digest, never the `Raw` octets; the persisted fingerprint is the stable `hashlib` digest, never a process-randomized `hash()` whose seed resets each run.
- Reject: a parsed-then-reserialized payload between verification, signing, or forwarding; a per-site encoder where one composition-fixed `hashlib` surface serves; a `hash()` persisted as stable identity; a domain field reaching the interior where the `msgspec.Raw` band holds the signed octets opaque.
