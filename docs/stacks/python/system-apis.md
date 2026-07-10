# [PYTHON_SYSTEM_APIS]

Standard-library churn owns this layer, disjoint from the stable language forms the language page keeps, so a standard-library delta retires a local helper here without touching that page. A standard-library API replaces local machinery only when it owns the concern; it never replaces an `expression` rail, `pydantic`/`msgspec` admission, the numeric route owners, or the structured-concurrency owner.

Each card names the owning stdlib surface and the local loop, wrapper, or pattern it deletes, and a snippet composes that surface under the `expression` rail. A snippet whose stdlib core leaves a boundary type-shape implicit carries a `beartype` contract proving that shape at the seam, the value-level invariant the types cannot carry staying on the `Result` rail; the violation-redirecting contract weave — `beartype(conf=BeartypeConf(violation_type=...))` folded onto the fault — is `surfaces-and-dispatch.md`'s aspect, composed there, never re-derived here.

Every member is fixed at the active interpreter surface `language.md` declares; a regressed owner moves to that page's replacement column with the older spelling, and nothing here predates that floor. A provider raise — a transfer `OSError`, `re.PatternError`, a malformed-stamp `ValueError`, the `strict=` ragged-tail `ValueError` — crosses into the fault vocabulary through the single-exception `catch` trap `rails-and-effects.md` owns — `catch(exception=...)` minting the transient and one `map_error` re-spelling it in the same expression — composed here, never re-derived as a hand-rolled `try`/`except`. A statement seam the stdlib forces where no expression reaches is named at its card Exemption and still leaves the result an `expression` `Result`.

## [01]-[SMELL_LOOKUP]

This table is a lookup by repeated local smell; the owning card states the placement law and the spelling it deletes.

| [INDEX] | [SMELL]                            | [OWNER]                          |
| :-----: | :--------------------------------- | :------------------------------- |
|  [01]   | stringly `os.walk`/`os.path` flow  | `pathlib.Path` algebra           |
|  [02]   | `shutil` transfer wrapper          | `Path.copy_into`/`move_into`     |
|  [03]   | repeated `stat()` probe per check  | `Path.info` one-syscall cache    |
|  [04]   | `__file__`-relative resource path  | `importlib.resources.as_file`    |
|  [05]   | inline `re.compile` per call       | module-level `re.Pattern`        |
|  [06]   | `datetime.strptime` then slicing   | `date.strptime`/`time.strptime`  |
|  [07]   | f-string or rendered reparse       | `templatelib.Template` fold      |
|  [08]   | float math on an integer algorithm | `math.integer` submodule         |
|  [09]   | `zip` product or `a*b+c` fold      | `math.sumprod`/`math.fma`        |
|  [10]   | `Fraction` constructor branch      | `Fraction.from_number`           |
|  [11]   | timestamp-prefixed UUID wrapper    | `uuid.uuid7`                     |
|  [12]   | negated-priority heap wrapper      | `heapq` `_max` family            |
|  [13]   | subprocess or bespoke zstd adapter | `compression.zstd`               |
|  [14]   | `os.read` copy slice per call      | `os.readinto`                    |
|  [15]   | `bytes(buf)` plus `buf.clear()`    | `bytearray.take_bytes`           |
|  [16]   | copy-heavy pickle blob             | protocol-5 out-of-band buffers   |
|  [17]   | `==` on a digest or keyed tag      | `hmac.compare_digest`            |
|  [18]   | `hashlib` loop for a keyed tag     | `hmac.digest`                    |
|  [19]   | `random` for secret or nonce bytes | `secrets` token API              |
|  [20]   | lambda wrapper for a `partial` gap | `functools.Placeholder`          |
|  [21]   | `sum(counter.values())` fold       | `Counter.total`                  |
|  [22]   | `reset(token)` in a `finally`      | `ContextVar.set` token-as-`with` |

## [02]-[PATHS_AND_FILES]

[PATH_ALGEBRA]:

- Owner: `pathlib.Path`/`PurePath` — `Path.walk`, `Path.copy`/`copy_into`, `Path.move`/`move_into`, `Path.info`, `Path.from_uri`, `PurePath.full_match`, `PurePath.with_segments`, `os.path.splitroot`, and `os.path.realpath(strict=os.path.ALLOW_MISSING)`.
- Gate: `Path.info` caches one `stat` on a single `_Info` accessor, so `exists`/`is_dir`/`is_file`/`is_symlink` share one syscall instead of one probe each; the copy verb's symlink and metadata behavior enters as POLICY_VALUES — `follow_symlinks=` and `preserve_metadata=` on `copy_into` — never a `copy: bool` knob the body re-derives.
- Law: `Path.copy_into`/`move_into` target a directory and keep the source name — the spelling a rooted right segment corrupts — so the transfer verb is a `frozendict` row binding the bound method to its policy map and projected to `**kwargs` at the call, never a `shutil` wrapper branching on a flag; `Path.walk` yields `(dirpath, dirnames, filenames)` under `follow_symlinks=` and replaces the `os.walk` string idiom end to end, while `Path.glob`/`rglob` carry the distinct `recurse_symlinks=` descent policy a copy never takes; `Path.from_uri` admits a `file:` URI to a path where a `urllib.parse` strip-and-unquote reconstructs it, and `PurePath.full_match(pattern)` matches the whole path with `**` recursion where `PurePath.match` anchors only the right tail.
- Boundary: the transfer verb is a provider call, so its residual `OSError` — the permission, cross-device, or TOCTOU failure the `info` pre-checks cannot preclude — crosses through the single-exception `catch` trap `rails-and-effects.md` owns, never an untrapped raise past the seam.
- Reject: a stringly `os.walk` flow; a `shutil.copy`/`move` wrapper; one `stat()` per `exists`/`is_dir` check; drive/root string slicing for `os.path.splitroot`; a symlink-prefix resolution loop for `realpath(strict=ALLOW_MISSING)`; a `urllib` strip-and-unquote where `Path.from_uri` admits a `file:` URI; a right-anchored `match` where `full_match` spans the whole path; a `copy: bool` knob where a policy row carries `follow_symlinks`/`preserve_metadata`.

[FILE_IO]:

- Owner: `NamedTemporaryFile(delete_on_close=...)`, `shutil.rmtree(onexc=...)`, `importlib.resources.files`/`as_file`, `tomllib` (TOML `1.1.0`), and `mimetypes.guess_file_type`.
- Gate: persisted text I/O states `encoding="utf-8"` (or `encoding="locale"` only at a genuine locale boundary), never an implicit default at a durable seam.
- Law: `importlib.resources.as_file(files(anchor) / name)` materializes a packaged resource to a real path inside a `with` scope and reclaims it on exit — the `__file__`-relative computation it retires; a config payload parses through `tomllib.load`/`loads`, never a `tomli` backport the active interpreter subsumes; `mimetypes.guess_file_type` takes the path directly where `guess_type` re-parses a URL.
- Reject: `mkstemp` unlink ladders; an `onerror` tuple handler for `rmtree(onexc=...)`; a `__file__` extraction loop; a `tomli` shim; path use of `mimetypes.guess_type`.

```python conceptual
from collections.abc import Callable
from enum import StrEnum
from os.path import ALLOW_MISSING, realpath
from pathlib import Path
from typing import Literal

from beartype import beartype
from builtins import frozendict
from expression import Error, Result
from expression.extra.result import catch

type TransferFault = Literal["<missing-source>", "<target-not-dir>", "<transfer-failed>"]
type Policy = frozendict[str, bool]


class Transfer(StrEnum):
    COPY = "<mode-a>"
    MOVE = "<mode-b>"


TRANSFER: frozendict[Transfer, tuple[Callable[..., Path], Policy]] = frozendict({
    Transfer.COPY: (Path.copy_into, frozendict({"follow_symlinks": False, "preserve_metadata": True})),
    Transfer.MOVE: (Path.move_into, frozendict()),
})


@beartype
def transferred(mode: Transfer, source: Path, into: Path, /) -> Result[Path, TransferFault]:
    target = into.with_segments(realpath(into, strict=ALLOW_MISSING))
    verb, policy = TRANSFER[mode]
    return (
        Error("<missing-source>")
        if not source.info.exists()
        else Error("<target-not-dir>")
        if not target.info.is_dir()
        else catch(exception=OSError)(verb)(source, target, **policy).map_error(lambda _io: "<transfer-failed>")
    )
```

## [03]-[TEXT_REGEX_TIME]

[REGEX]:

- Owner: `re` with `re.PatternError`, `re.RegexFlag` composition, and compiled module-level patterns.
- Law: a structural grammar compiles once to a module-level `Pattern` and the flags compose as one `RegexFlag` value (`re.VERBOSE | re.DOTALL`), reused through `Pattern.flags` for a runtime refinement, never a re-compiled inline string per call; `re.PatternError` is the canonical name the legacy `re.error` aliases, so the exception identity is one and only the spelling is fixed.
- Boundary: the compile-time `re.PatternError` crosses through the single-exception `catch` trap `rails-and-effects.md` owns and the parse-time `is None` miss becomes a guard arm in the same expression; the interior never sees the raise or a `None` match.
- Reject: an inline `re.compile` inside the call; a flag passed as a bare `int` the body re-derives; the legacy `re.error` trap target where `re.PatternError` is the fixed identity; a `catch` widened past `re.PatternError` to mask a grammar bug as input failure.

[DATETIME]:

- Owner: `datetime.date.strptime`, `datetime.time.strptime`, and timezone-aware `datetime`.
- Boundary: a wire timestamp admits to an aware `datetime` at the seam and the interior carries the aware value; `date.strptime`/`time.strptime` return the component type directly where `datetime.strptime(...).date()`/`.time()` parses the whole stamp only to discard half, and the malformed-stamp `ValueError` crosses through the single-exception `catch` trap `rails-and-effects.md` owns.
- Reject: `datetime.strptime` followed by `.date()`/`.time()` slicing; naive datetime arithmetic past the seam.

[TEMPLATE_RENDER]:

- Owner: t-string processors over `string.templatelib.Template` consumed at the render boundary.
- Boundary: template structure — segments, interpolations, conversions, format specs — is the language-form concern `language.md` owns; this card owns only the render-time fold of the already-built `Template`, so a processor folds its `str | Interpolation` segments through one `conversion`-keyed `frozendict` and `format(..., format_spec)`, never re-parsing rendered text.
- Reject: f-string pre-parsing; rendered-string reparsing; an enumerated `if conversion == ...` ladder where a `frozendict` derives the converter; string concatenation hiding template policy.

```python conceptual
import datetime
import re
from collections.abc import Callable
from dataclasses import dataclass
from string.templatelib import Template
from typing import Literal

from beartype import beartype
from builtins import frozendict
from expression import Error, Ok, effect
from expression.extra.result import catch

type TextFault = Literal["<bad-grammar>", "<no-match>", "<bad-stamp>"]

STAMPED: re.Pattern[str] = re.compile(r"^ (?P<at>\d{4}-\d\d-\d\d) \s+ (?P<body>.+) $", re.VERBOSE | re.DOTALL)
CONVERT: frozendict[Literal["a", "r", "s"] | None, Callable[[object], str]] = frozendict({None: str, "s": str, "r": repr, "a": ascii})


@dataclass(frozen=True, slots=True, kw_only=True)
class Record:
    at: datetime.datetime
    body: str
    rendered: str


@beartype
@effect.result[Record, TextFault]()
def recorded(line: str, render: Template, *, refine: str | None = None):
    pattern = yield from (
        Ok(STAMPED) if refine is None else catch(exception=re.PatternError)(re.compile)(refine, STAMPED.flags).map_error(lambda _bad: "<bad-grammar>")
    )
    found = yield from (Ok(matched) if (matched := pattern.match(line)) is not None else Error("<no-match>"))
    day = yield from catch(exception=ValueError)(datetime.date.strptime)(found["at"], "%Y-%m-%d").map_error(lambda _bad: "<bad-stamp>")
    return Record(
        at=datetime.datetime.combine(day, datetime.time.min, datetime.UTC),
        body=found["body"],
        rendered="".join(part if isinstance(part, str) else format(CONVERT[part.conversion](part.value), part.format_spec) for part in render),
    )
```

## [04]-[NUMERIC_PRIMITIVES]

[SCALAR_MATH]:

- Owner: the IEEE fused-op set `math.fma`, `math.sumprod`, `math.fmax`/`fmin`, `math.isnormal`/`issubnormal`/`signbit`; the exact-integer submodule `math.integer` (`isqrt`, `gcd`, `lcm`, `comb`, `perm`, `factorial`); and the exact-rational `fractions.Fraction.from_number`/`is_integer`.
- Gate: `math.fma(a, b, c)` is one correctly-rounded fused multiply-add where `a * b + c` rounds twice, and `math.sumprod(p, q)` is the fused dot product a `sum(x * y for ...)` fold loses accuracy and speed to; `math.fmax`/`fmin` carry the IEEE missing-data rule — a `NaN` operand is suppressed and the numeric value wins — where a hand-written `max`/`min` leaks the `NaN` or an order-dependent result.
- Law: `math.integer.isqrt(n)` is the exact integer square root an `int(math.sqrt(n))` float round corrupts past `2**53`, and `math.integer.gcd`/`lcm`/`comb`/`perm`/`factorial` own the number-theoretic and combinatorial algorithms a float `math.*` or a Python reduction loop re-derives — the submodule split that severs exact-integer work from the float domain; `Fraction.from_number(value)` admits a `float`/`Decimal` to an exact rational in one call where a constructor branch ladder dispatches on the input kind, and `Fraction.is_integer()` is the `denominator == 1` integrality probe as a method.
- Boundary: every array, matrix, density-estimate, and seeded-sampling concern routes to `algorithms.md`; this card owns scalar invariants on stdlib numeric primitives only, never a sample-level estimator.
- Reject: a rounded multiply-add; a `zip` product fold; a NaN-blind min/max wrapper; a bit-level float probe where `isnormal`/`issubnormal`/`signbit` name it; `int(math.sqrt(n))` for an integer root; a float `math.*` for a `math.integer` combinatorial algorithm; a `Fraction` constructor branch; a `denominator == 1` re-derivation.

[IDENTITY_AND_HEAP]:

- Owner: `uuid.uuid7`, `uuid.NIL`, `uuid.MAX`, and the complete max-heap `heapq` family `heapify_max`/`heappush_max`/`heappop_max`/`heapreplace_max`/`heappushpop_max`.
- Law: `uuid.uuid7` is monotonic within a timestamp tick, so a time-ordered key carries its own sort order and needs no separate sequence column; the minted value is compared against a prior before binding, so the successor is `max(minted, prior)` rather than a blind overwrite, and `uuid.NIL`/`uuid.MAX` name the boundary literals a magic UUID string restates.
- Law: the `_max` heap family is the native max-priority surface a value-negation `heappush` wrapper simulates; `heapreplace_max` pops-then-pushes and `heappushpop_max` pushes-then-pops, so a bounded top-`k` retention is one atomic call against the root rather than a conditional `heappop_max`-then-`heappush_max` pair.
- Exemption: `heapify_max`/`heapreplace_max`/`heappushpop_max` mutate the heap buffer in place — the one statement seam this card forces — and the railed return copies nothing.
- Reject: a timestamp-prefixed UUID wrapper; a magic UUID boundary literal where `uuid.NIL`/`MAX` name it; a negated-priority heap; a conditional pop-then-push where `heapreplace_max`/`heappushpop_max` is atomic.

```python conceptual
from dataclasses import dataclass
from fractions import Fraction
from heapq import heapify_max, heappushpop_max
from math import fma, isnormal, sumprod
from typing import Literal
from uuid import NIL, UUID, uuid7

from beartype import beartype
from expression import Error, Ok, Result

type WeightFault = Literal["<rank-mismatch>", "<empty>", "<non-integral>", "<unseeded>", "<subnormal>"]


@dataclass(frozen=True, slots=True, kw_only=True)
class Receipt:
    identity: UUID
    weighted: Fraction
    corrected: float
    peak: Fraction


@beartype
def receipted(weights: tuple[Fraction, ...], values: tuple[Fraction, ...], prior: UUID, /) -> Result[Receipt, WeightFault]:
    identity, heap = max(uuid7(), prior), list(weights)
    heapify_max(heap)
    return (
        Error("<unseeded>")
        if prior == NIL
        else Error("<empty>")
        if not weights
        else Error("<rank-mismatch>")
        if len(weights) != len(values)
        else Error("<non-integral>")
        if not (exact := Fraction.from_number(sumprod(weights, values))).is_integer()
        else Error("<subnormal>")
        if not isnormal(corrected := fma(float(weights[0]), float(values[0]), float(exact)))
        else Ok(Receipt(identity=identity, weighted=exact, corrected=corrected, peak=heappushpop_max(heap, exact)))
    )
```

## [05]-[BINARY_AND_INTEGRITY]

[BUFFERS]:

- Owner: `array`/`memoryview` complex codes (`Zf`/`Zd`) with `memoryview.index`/`count`, `inspect.BufferFlags`, `os.readinto`, `bytearray.take_bytes`, and pickle protocol-5 out-of-band buffers.
- Law: a protocol-5 reduction routes its payload through `pickle.PickleBuffer`, the `buffer_callback` collects each out-of-band block, and `loads(..., buffers=...)` restores the view without copying the numeric body; `os.readinto(fd, buffer)` fills a caller-owned `bytearray` in place where `os.read` allocates a fresh slice, `bytearray.take_bytes()` moves the backing store out in one operation where `bytes(buf)` then `buf.clear()` copies then zeroes, the native `Zf`/`Zd` array codes carry a complex buffer a struct-packed pair re-derives, and `memoryview.index`/`count` locate an element inside that live buffer in place where a `bytes(view)` materialization copies the whole span only to search it.
- Boundary: `collections.abc.Buffer` is the protocol-form owner `language.md` declares; the live-memory borrow window — `ctypes.memoryview_at` opened, copied, and `view.release()`-closed before the foreign free, any zero-copy ownership held across an `await` — is the FFI-lifetime concern `boundaries.md` owns. This card owns the stdlib in-process buffer-surface selection only.
- Exemption: the `__reduce_ex__` zero-copy hook, the `os.readinto` caller-buffer fill, and the protocol-5 `buffer_callback` mutable sink are the platform-forced statement seams no expression reaches; each still returns an `expression` `Result`.
- Reject: a struct-packed complex buffer where the `Zf`/`Zd` code is native; a magic integer in place of `inspect.BufferFlags`; an `os.read` copy slice; `bytes(buf)` plus `clear()`; a `bytes(view)` copy to `index`/`count` a span the `memoryview` searches in place; a copy-heavy pickle blob.

[CODECS]:

- Owner: `compression.zstd` (with `ZstdDict`, `train_dict`, `CompressionParameter`), `base64.z85encode`/`z85decode`, the base-N decode controls (`canonical=`/`padded=`/`ignorechars=` on `b32decode`/`b64decode`), and the base-N `wrapcol=` encode control.
- Gate: a repeated-corpus payload trains one `ZstdDict` via `train_dict(samples, dict_size)` rather than recompressing a shared prefix per message, and compression tuning enters as a `frozendict[CompressionParameter, int]` policy projected to the `options=` map at the boundary, never a bare `level=` knob the body re-derives.
- Law: `canonical=True` rejects non-canonical base-N input at decode instead of a post-decode padding-bit check, `wrapcol=` is an encode-side line-width control that never appears on a decode call, and the inverse decode reads that wrapped span directly — `ignorechars=` skips the inserted newlines where a pre-strip pass otherwise precedes decode, and `padded=False` admits an unpadded span where a manual re-pad otherwise restores the `=` tail.
- Reject: a subprocess or bespoke zstd adapter; a local Z85 codec; a padding-bit postcheck; manual line-wrap formatting; a newline pre-strip or manual re-pad before a decode `ignorechars=`/`padded=` carries; a bare `level=` knob where a `CompressionParameter` policy carries the tuning.

[DIGEST_AND_AUTH]:

- Owner: `hashlib.file_digest`, `zlib.adler32_combine`/`crc32_combine`, keyed `hmac.new`/`hmac.digest`, the constant-time `hmac.compare_digest`/`secrets.compare_digest`, and the secure-random `secrets.token_bytes`/`token_hex`.
- Gate: a wire digest streams through `hashlib.file_digest` (file object) or one `hashlib` one-shot (in-memory); key, token, and nonce material comes from `secrets`, never `random`.
- Law: a keyed authenticity tag is one `hmac.digest(key, message, digest)` one-shot where a `hashlib` update loop over key-plus-message reinvents the construction; tag and digest equality is `hmac.compare_digest`, constant-time over the full width where `==` leaks a timing oracle on the first differing byte; `zlib.crc32_combine(crc_a, crc_b, len_b)` folds two independently-checksummed spans into the whole-stream checksum without a rescan.
- Reject: a chunked hash loop; a recompute-to-checksum loop; a `hashlib`-built MAC where `hmac` is the keyed owner; `==` on a digest or tag; `random` for key, token, or nonce material.

```python conceptual
import compression.zstd as zstd
import hashlib
import hmac
import os
import pickle
import secrets
from collections.abc import Buffer, Callable
from dataclasses import dataclass
from typing import Literal

from beartype import beartype
from builtins import frozendict
from expression import Error, Ok, Result

type FrameFault = Literal["<empty-span>", "<short-read>", "<bad-mac>"]

_TUNING: frozendict[zstd.CompressionParameter, int] = frozendict({
    zstd.CompressionParameter.compression_level: 9,
    zstd.CompressionParameter.window_log: 24,
    zstd.CompressionParameter.enable_long_distance_matching: 1,
})


@dataclass(frozen=True, slots=True, kw_only=True)
class Frame:
    body: bytes
    blocks: tuple[pickle.PickleBuffer, ...]
    digest: str
    nonce: bytes
    mac: bytes


class Carrier:
    __slots__ = ("_view",)

    def __init__(self, payload: Buffer, /) -> None:
        self._view = memoryview(payload)

    def __reduce_ex__(self, protocol: int, /) -> tuple[Callable[[pickle.PickleBuffer], memoryview], tuple[pickle.PickleBuffer]]:
        return memoryview, (pickle.PickleBuffer(self._view),)


@beartype
def framed(
    fd: int, span: int, key: bytes, *, shared: zstd.ZstdDict | None = None, tuning: frozendict[zstd.CompressionParameter, int] = _TUNING
) -> Result[Frame, FrameFault]:
    if span == 0:
        return Error("<empty-span>")
    sink = bytearray(span)
    if os.readinto(fd, sink) < span:
        return Error("<short-read>")
    blocks: list[pickle.PickleBuffer] = []
    stream = pickle.dumps(Carrier(sink.take_bytes()), protocol=5, buffer_callback=blocks.append)
    body = zstd.compress(stream, options=dict(tuning), zstd_dict=shared)
    nonce = secrets.token_bytes(16)
    return Ok(
        Frame(body=body, blocks=tuple(blocks), digest=hashlib.sha256(stream).hexdigest(), nonce=nonce, mac=hmac.digest(key, nonce + body, "sha256"))
    )


@beartype
def verified(frame: Frame, key: bytes, /) -> Result[bytes, FrameFault]:
    return Ok(frame.body) if hmac.compare_digest(frame.mac, hmac.digest(key, frame.nonce + frame.body, "sha256")) else Error("<bad-mac>")
```

## [06]-[PARTIALS_AND_CONTEXT]

[PARTIAL_AND_MULTISET]:

- Owner: `functools.Placeholder` and the `collections.Counter` multiset surface (`Counter.total`, `Counter.subtract`).
- Boundary: the fixed-width chunk and window combinator `itertools.batched(strict=...)` is `iteration.md`'s, and the `zip(strict=True)`/`map(strict=True)` arity-invariant form is `language.md`'s; this card composes the chunk stream and owns only the partial-application and multiset-fold primitives that retire a local loop, the `strict=` ragged-tail `ValueError` crossing through the single-exception `catch` trap `rails-and-effects.md` owns.
- Law: `Counter.total()` is the multiset cardinality a `sum(counter.values())` fold restates, and `Counter.subtract` keeps the signed count delta the multiset `-` operator clamps to positive and a paired-iteration fold restates by hand.
- Law: `functools.Placeholder` fills a leading or interior `partial` gap so a held argument binds while the gap awaits the call value, but a trailing `Placeholder` raises `TypeError` at construction, so held arguments stay left-justified and a fully-trailing bind uses a direct call.
- Reject: a lambda wrapper for a partial argument gap; a `sum(counter.values())` fold; a manual signed count-difference fold; a re-teaching of `batched`'s `strict=` semantics `iteration.md` owns.

[SCOPED_CONTEXT]:

- Owner: the `ContextVar.set` token-as-context-manager.
- Law: `ContextVar.set(value)` returns a `Token` usable directly as a `with` context manager that restores the prior value on exit — including when a raise unwinds the scope — retiring the `token = cv.set(v); try: ... finally: cv.reset(token)` ladder; this is the same-task scoped-restore primitive, distinct from `runtime.md`'s `copy_context().run` which carries `ContextVar` state across a thread or guard boundary.
- Reject: a `reset(token)` paired in a `finally`; a manual save-and-restore of the prior value.

```python conceptual
from collections import Counter
from collections.abc import Callable, Iterable
from contextvars import ContextVar
from functools import Placeholder, partial
from itertools import batched
from typing import Literal

from beartype import beartype
from builtins import frozendict
from expression import Result
from expression.extra.result import catch

type WindowFault = Literal["<ragged-window>"]

_FLOOR: ContextVar[int] = ContextVar("floor", default=0)


def _floored(scored: int, /) -> int:
    return max(scored, _FLOOR.get())


@beartype
def tallied[T](
    stream: Iterable[T], width: int, weigh: Callable[[tuple[T, ...], int], int], scale: int, floor: int, /
) -> Result[tuple[frozendict[int, int], int], WindowFault]:
    with _FLOOR.set(floor):
        score = partial(weigh, Placeholder, scale)
        return (
            catch(exception=ValueError)(Counter)(_floored(score(window)) for window in batched(stream, width, strict=True))
            .map(lambda tally: (frozendict(tally), tally.total()))
            .map_error(lambda _ragged: "<ragged-window>")
        )
```
