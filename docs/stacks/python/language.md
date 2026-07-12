# [PYTHON_LANGUAGE]

Python `>=3.15` is the active language surface. This page is the version-feature and type-level evidence law: every static, caller-facing type-form contract that carries no runtime value — declaration evidence, predicate evidence, type-expression values, generated-owner decorators, callable-signature shape, and the language-form placement sites — is fixed here before a local abstraction is added. The value lifecycle is shed by kind: payload materialization, owner selection, and the `Result` rail ride `shapes.md`; standard-library API replacement rides `system-apis.md`; structured concurrency rides `concurrency.md`; interpreter isolation and runtime-state introspection ride `runtime.md`.

`pyproject.toml` owns the interpreter floor, `uv`, and tool configuration facts. This page names those facts only when they change the language form a Python file may assume.

## [01]-[ACTIVE_SURFACE]

- Interpreter floor: `>=3.15`
- Tool baseline: `uv` owns Python environment, lockfile, dependency, and tool execution entrypoints
- Type gates: strict `ty` and strict `mypy`
- Formatter and lint gate: `Ruff` preview policy
- Encoding baseline: UTF-8 default with explicit persisted-I/O contracts
- Import baseline: module-scope named imports, with `lazy import`/`lazy from` deferring cold dependencies and a module `__getattr__` publishing the deferred package surface; never a function-local or `importlib`-scattered import
- Export baseline: explicit end-of-file `__all__`; no wildcard imports, barrel files, facade exports, or empty `__init__.py` package markers
- Annotation baseline: deferred annotations inspected through annotation APIs

Treat source files as idiomatic Python, not compatibility layers. Remove old imports, shims, typing spellings, package markers, and tool bypasses when the active surface carries the concept directly.

## [02]-[CANONICAL_CHOOSER]

Use the active Python surface directly. This chooser owns language syntax, type-expression, annotation, import/export, template, and typing-protocol forms — the stable language-form law. Standard-library API replacement (paths, files, regex, datetime, numeric primitives, binary codecs, hashing, iteration) is the high-churn surface owned by `system-apis.md`; structured concurrency is owned by `concurrency.md`, and interpreter isolation and runtime-state introspection are owned by `runtime.md`. Replace an older spelling or local machinery when the active language surface owns the behavior. The chooser groups by form kind, and each group routes to one or more `[03]` placement cards for the rule the table row cannot state.

[TYPE_DECLARATION_FORMS]: which declaration, generated-owner, callable, or generic form carries the type evidence.

| [INDEX] | [CONCERN]                | [USE]                                                     | [REJECTED_FORM]                     |
| :-----: | :----------------------- | :-------------------------------------------------------- | :---------------------------------- |
|  [01]   | generic shape            | inline type parameters and `type` aliases                 | `TypeVar`, `ParamSpec`, `TypeAlias` |
|  [02]   | generic defaults         | type parameter defaults and `NoDefault`                   | overload families for defaults      |
|  [03]   | variadic generic options | `TypeVarTuple` bound, variance, and `infer_variance` args | asymmetric variadic-generic shims   |
|  [04]   | callable shape           | inline `**P` parameter-preserving decorators              | `Callable[..., T]` erasure          |
|  [05]   | leading-context callable | `Concatenate[Context, P]`                                 | `*args` context threading           |
|  [06]   | generated owner          | `@dataclass_transform()` field-specifier decorator        | checker-invisible model decorators  |
|  [07]   | self type                | `typing.Self`                                             | bound `TypeVar` self boilerplate    |
|  [08]   | method override          | `@typing.override`                                        | unmarked subclass overrides         |
|  [09]   | finality                 | `@typing.final` and `Final`                               | prose-only finality                 |
|  [10]   | typed disjointness       | `@typing.disjoint_base`                                   | prose-only disjointness             |
|  [11]   | generic slice            | `slice[T]`                                                | unparameterized slice contracts     |
|  [12]   | I/O protocol             | `io.Reader` and `io.Writer`                               | `typing.IO` pseudo-protocols        |
|  [13]   | buffer protocol          | `collections.abc.Buffer`                                  | `ByteString` or bytes prose         |

[TYPE_PREDICATE_AND_EXPRESSION_FORMS]: how membership is proved and a type-expression value is carried.

| [INDEX] | [CONCERN]             | [USE]       | [REJECTED_FORM]                     |
| :-----: | :-------------------- | :---------- | :---------------------------------- |
|  [01]   | type predicates       | `TypeIs`    | one-way `TypeGuard` predicates      |
|  [02]   | non-subtype narrowing | `TypeGuard` | `bool` helper plus `cast`           |
|  [03]   | type expressions      | `TypeForm`  | `object` or broad `type[Any]` forms |

[TYPED_DICT_PAYLOAD_FORMS]: how a keyword or dictionary payload states its static key law.

| [INDEX] | [CONCERN]          | [USE]                            | [REJECTED_FORM]                    |
| :-----: | :----------------- | :------------------------------- | :--------------------------------- |
|  [01]   | kwargs payload     | `Unpack[TypedDict]`              | homogeneous `**kwargs`             |
|  [02]   | typed dict closure | `closed=` and `extra_items=`     | open payload prose                 |
|  [03]   | required keys      | `Required[]` and `NotRequired[]` | split `TypedDict` inheritance      |
|  [04]   | immutable keys     | `ReadOnly[T]` in `TypedDict`     | prose-only immutable key contracts |

[CLOSED_DISPATCH_AND_VALUE_FORMS]: how a closed domain dispatches, proves exhaustiveness, and carries an immutable value.

| [INDEX] | [CONCERN]            | [USE]                               | [REJECTED_FORM]                  |
| :-----: | :------------------- | :---------------------------------- | :------------------------------- |
|  [01]   | conditional binding  | assignment expressions (`:=`)       | precondition temporary variables |
|  [02]   | closed dispatch      | `match` with pattern narrowing      | tag `if` chains                  |
|  [03]   | exhaustiveness proof | `Never` and `assert_never()`        | default-arm raises               |
|  [04]   | string enum          | `enum.StrEnum`                      | `str, Enum` mixins               |
|  [05]   | enum invariant       | `enum.verify()` and `EnumCheck`     | local enum validation loops      |
|  [06]   | sentinel value       | `Sentinel("NAME")`                  | `object()` or string sentinels   |
|  [07]   | immutable update     | `copy.replace()` or `__replace__()` | mutate-then-freeze copies        |
|  [08]   | immutable map        | `frozendict`                        | tuple-pair pseudo-maps           |
|  [09]   | invariant arity      | `zip(strict=True)`                  | post-truncation asserts          |
|  [10]   | mapped arity         | `map(strict=True)`                  | post-truncation asserts          |

[TEXT_AND_TEMPLATE_FORMS]: how structured text and templates stay typed and parseable.

| [INDEX] | [CONCERN]             | [USE]                     | [REJECTED_FORM]            |
| :-----: | :-------------------- | :------------------------ | :------------------------- |
|  [01]   | literal text boundary | `LiteralString`           | untyped sensitive `str`    |
|  [02]   | safe templates        | t-strings and processors  | f-string pre-parsing       |
|  [03]   | f-string expression   | full-expression f-strings | quote juggling temporaries |
|  [04]   | template AST          | `ast.TemplateStr`         | f-string AST rewrites      |

[REFLECTION_AND_AST_FORMS]: how annotations, members, unions, frames, and AST are read structurally.

| [INDEX] | [CONCERN]              | [USE]                                                      | [REJECTED_FORM]                     |
| :-----: | :--------------------- | :--------------------------------------------------------- | :---------------------------------- |
|  [01]   | runtime annotations    | `annotationlib.get_annotations()`                          | direct `__annotations__` reads      |
|  [02]   | signature annotations  | `inspect.signature(annotation_format=...)`                 | annotation string post-processing   |
|  [03]   | static reflection      | `inspect.getmembers_static()`                              | descriptor-triggering scans         |
|  [04]   | union introspection    | `typing.get_origin()` and `get_args()`                     | private union implementation checks |
|  [05]   | protocol introspection | `typing.get_protocol_members()` and `typing.is_protocol()` | private protocol probes             |
|  [06]   | generic bases          | `types.get_original_bases()`                               | direct `__orig_bases__` reads       |
|  [07]   | execution locals       | explicit `locals=` and `frame.f_locals`                    | mutating `locals()` snapshots       |
|  [08]   | frame locals type      | `types.FrameLocalsProxyType`                               | private frame-locals proxy checks   |
|  [09]   | AST field schema       | per-node `ast.<Node>._field_types`                         | hand-maintained ASDL maps           |
|  [10]   | AST equality           | `ast.compare()`                                            | `ast.dump()` string comparison      |
|  [11]   | optimized AST          | `ast.parse(optimize=...)`                                  | local AST pruning                   |
|  [12]   | source module name     | `module=` compile APIs                                     | filename-only warning filters       |

[MODULE_AND_IO_FORMS]: how imports, startup hooks, and text encoding state their boundary.

| [INDEX] | [CONCERN]       | [USE]                                                                   | [REJECTED_FORM]                       |
| :-----: | :-------------- | :---------------------------------------------------------------------- | :------------------------------------ |
|  [01]   | deferred import | module-scope `lazy import` / `lazy from`; `__getattr__` package surface | function-local imports, `lazy_loader` |
|  [02]   | startup hook    | `.start` entries                                                        | executable `.pth` import lines        |
|  [03]   | UTF-8 default   | UTF-8 default; `encoding="locale"`                                      | locale-dependent implicit text I/O    |

## [03]-[LANGUAGE_FORM_CONTRACTS]

Use these contracts when the chooser names the primitive but code still needs a placement rule.

[TYPE_DECLARATION_SITE]:
- Use when: the defining declaration, the decorator that builds a family of owners, or the callable signature can carry type evidence that callers otherwise repair downstream.
- Accept: inline type parameters, `type` aliases, `TypeForm[T]` for type-expression values, type parameter defaults, `NoDefault`, `slice[T]`, `io.Reader`/`io.Writer`, `@typing.override`, `typing.Self`, `@typing.disjoint_base`, `@typing.final` and `Final`, `@dataclass_transform()` with `field_specifiers` for a generated-owner decorator, inline `**P` with `Concatenate` for parameter-preserving callable signatures, and `TypeVarTuple` `bound`, `covariant`, `contravariant`, and `infer_variance` arguments.
- Reject: erased `Callable[..., T]`, imported `ParamSpec` or `TypeVar`/`Generic` where inline `**P` and `class C[T]` express the shape, `from typing_extensions import` for any member the active `typing` namespace exports, `slots_default`/non-existent decorator keywords, remote alias repair, broad `type[T]` or `object` placeholders for type-form values, unmarked overrides, prose-only disjointness or finality, bound-self boilerplate, checker-invisible model decorators, and protocol shells created only to type an existing object.
- Boundary: `TypeForm`, disjointness, finality, generated-owner, and signature evidence are static typing contracts that carry no runtime value; runtime validation, object-family policy, aspect architecture, protocol ports, and payload materialization belong to the owning concept page.

[TYPE_PREDICATE_SITE]:
- Use when: a reusable predicate proves exact type membership that inline narrowing cannot express.
- Accept: `TypeIs[T]` over the concrete or owned structural target where the predicate is true exactly for `T`; `TypeGuard[T]` only for genuine non-subtype narrowing; `beartype.door.is_bearable(value, hint)` as the `TypeIs`-returning guard for a parametrized hint, and `beartype.door.is_subhint` for decidable subtype proof over a type-expression registry.
- Reject: subtype-compatible predicates written as `TypeGuard`, subset predicates disguised as membership proofs, bool helpers followed by `cast`, hand-rolled `isinstance` trees over parametrized hints, and runtime-checkable protocols created only to satisfy `isinstance`.
- Soundness: `TypeIs[T]` is a biconditional type-membership proof, not a validation rail for valid, non-empty, active, normalized, positive, or otherwise filtered `T` values; that refinement is `beartype.vale.Is[...]` on a shared `Annotated` alias or the owning result rail.
- Consumption: keep predicate use at ingress, dispatch, or projection boundaries; the narrowed value folds through one total `match` or the owning rail, never a branch body re-spread across the function.

The type-evidence spotlight: a `@dataclass_transform` decorator mints the closed owner family, `@disjoint_base` seals the nominal root over `@final` sealed members, `Self`/`override` carry declaration evidence, inline `**P`/`Concatenate` preserve a context-threading signature woven under `@beartype`, a `TypeForm` registry holds the structural type-expression values that `door.is_subhint` resolves by decidable subtyping, `is_primary` is the `TypeIs[Primary]` that narrows the member so its `widened` transition is callable while `door.is_bearable` narrows the raw value into the refinement alias `Atom` that transition admits, and the total `match` over the sealed members proves exhaustiveness — all static evidence, no value materialized into an owner rail.

```python conceptual
import copy
import dataclasses
from collections.abc import Callable
from functools import wraps
from typing import Annotated, Concatenate, Literal, Self, TypeForm, TypeIs
from typing import assert_never, dataclass_transform, disjoint_base, final, override

from beartype import beartype
from beartype.door import is_bearable, is_subhint
from beartype.vale import Is


type Kind = Literal["<value-a>", "<value-b>"]
type Atom = Annotated[int, Is[lambda n: n >= 0]]
type Context = tuple[Kind, str]


@dataclass_transform(frozen_default=True, kw_only_default=True, field_specifiers=(dataclasses.field,))
def record[T: type](cls: T, /) -> T:
    return dataclasses.dataclass(frozen=True, slots=True, kw_only=True)(cls)


@disjoint_base
class Shape:
    def rendered(self, prefix: str, /) -> str:
        raise NotImplementedError


@final
@record
class Primary(Shape):
    key: str
    value: Atom

    def widened(self, value: Atom, /) -> Self:
        return copy.replace(self, value=value)

    @override
    def rendered(self, prefix: str, /) -> str:
        return f"{prefix}:<value-a>:{self.key}:{self.value}"


@final
@record
class Secondary(Shape):
    key: str
    note: str = ""

    @override
    def rendered(self, prefix: str, /) -> str:
        return f"{prefix}:<value-b>:{self.key}:{self.note}"


type Member = Primary | Secondary
type Form = TypeForm[int] | TypeForm[tuple[int, ...]]
REGISTRY: tuple[tuple[str, Form], ...] = (("<scalar>", int), ("<vector>", tuple[int, ...]))


def registered(form: Form, /) -> str:
    return next((name for name, candidate in REGISTRY if is_subhint(form, candidate)), "<unregistered>")


def is_primary(value: Member, /) -> TypeIs[Primary]:
    return isinstance(value, Primary)


def with_context[**P, T](context: Context, /) -> Callable[[Callable[Concatenate[Context, P], T]], Callable[P, T]]:
    def bind(operation: Callable[Concatenate[Context, P], T], /) -> Callable[P, T]:
        @wraps(operation)
        def call(*args: P.args, **kwargs: P.kwargs) -> T:
            return operation(context, *args, **kwargs)

        return call

    return bind


@with_context(("<value-a>", "<field-a>"))
@beartype
def described(context: Context, value: Member, raw: object, /) -> str:
    kind, prefix = context
    projected = value.widened(raw) if is_primary(value) and is_bearable(raw, Atom) else value
    match projected:
        case Primary() as primary:
            return f"{kind}:{registered(int)}:{primary.rendered(prefix)}"
        case Secondary() as secondary:
            return f"{kind}:{registered(tuple[int, ...])}:{secondary.rendered(prefix)}"
        case _ as unreachable:
            assert_never(unreachable)
```

[TYPED_DICT_PAYLOAD_SITE]:
- Use when: keyword or dictionary payload shape is part of the static callable contract; the type form and its root signature are declared here.
- Accept: `Unpack[TypedDict]` as the keyword-payload type at the root entrypoint, `closed=True` for exact-key closure, `extra_items=T` for the typed extension band — `ReadOnly`-wrapped when the band is read-only — and `Required[]`, `NotRequired[]`, `ReadOnly[T]` as per-key static evidence; the interior consumes the concrete `TypedDict` by value, reading a `NotRequired[]` key through `.get` rather than re-checking presence.
- Reject: homogeneous `**kwargs`, open payload prose, split total/non-total `TypedDict` mirror shapes, `Unpack` re-spread through an interior signature, mutable-key promises in comments, and `Mapping[str, object]` bags.
- Boundary: this site owns the payload type form and the `Unpack` root signature; `TypeAdapter` admission of the raw payload, `frozendict` extension-band materialization, and the `Result` rail are the value lifecycle owned by the shape page.

```python conceptual
from typing import NotRequired, ReadOnly, Required, TypedDict, Unpack


class Span(TypedDict, closed=True):
    lo: Required[int]
    hi: Required[int]


class Payload(TypedDict, extra_items=ReadOnly[str]):
    key: Required[str]
    span: ReadOnly[Span]
    note: NotRequired[str]


def projected(payload: Payload, /) -> tuple[str, int, int]:
    span = payload["span"]
    return payload.get("note", payload["key"]), span["lo"], span["hi"]


def admitted(**fields: Unpack[Payload]) -> tuple[str, int, int]:
    return projected(fields)


SHAPE = admitted(key="<key-a>", span={"lo": 0, "hi": 4}, tag="<ext-a>")
```

[MODULE_BOUNDARY_SITE]:
- Use when: a module declares its public names, imports another module surface, or registers an auditable startup hook.
- Accept: named imports, end-of-file `__all__`, `__init__.py` only when it owns real package initialization or a public package contract, and `.start` entries in mandatory `pkg.mod:callable` form for zero-argument startup hooks.
- Reject: wildcard imports, barrel files, facade-only exports, empty `__init__.py` package markers, re-export files that hide the real owner, executable `.pth` import lines, implicit import side effects, and startup code hidden in package marker files.
- Boundary: package topology, generated API documentation, public package contracts, source-symbol documentation, site processing, and startup ordering belong to their owning platform, architecture, or code-documentation surface.

[LAZY_IMPORT_SITE]:
- Use when: a cold, heavy, native, or cyclically coupled dependency must stay declared at the module boundary while its import cost falls on first use, or a package `__init__` publishes a deferred public surface — mandatory re-exports kept lexically static-visible, optional install-extra-gated submodules left degradable, and a computed metadata tail — eagerly importing none of it.
- Accept: the form keys on what defers and on whether a published name is mandatory or optional. A module deferring an absolute dependency it names itself uses module-scope `lazy import X` or `lazy from X import Y`, so a heavy or native import costs nothing until first use and deferring a coupled peer breaks the cycle. A package `__init__` re-exporting a mandatory owned symbol uses module-scope `lazy from package.submodule import Symbol`: the name stays lexically present, so a type checker resolves a downstream `from package import Symbol` while the load defers and the in-`__init__` deferral breaks the package self-cycle. Only an optional, install-extra-gated submodule and the computed `__version__` fall to the module `__getattr__` resolver, with the companion `__dir__` unioning the static and optional names. `__lazy_modules__`, a per-module collection of fully-qualified module-name strings whose opt-in is checked by `__contains__`, is the bulk per-module deferral for a name the file does not mark inline.
- Reject: a `lazy` statement inside a function, class, or `try`, a `lazy from M import *`, and a `lazy from __future__` are each a `SyntaxError`, the soft keyword being module-scope, non-star, and non-future only; `lazy from . import a` and `lazy from .core import Y` compile but the `ban-relative-imports` gate rejects them, routing the package surface through the absolute `lazy from package.submodule import ...` form; a function-local `import`, an `importlib.import_module` scattered beyond the single resolver, a `sys.modules` mutation, and a per-call re-import each stand in for a module-scope binding; `lazy_loader.attach`/`attach_stub`/`load` (not an admitted dependency, superseded by the native keyword and the `__getattr__` surface) and `importlib.util.LazyLoader` (no `from`-import support, eager spec resolution) are dead forms; a `__lazy_modules__ = ["*"]` wildcard and a process-wide `sys.set_lazy_imports` blanket mode override the explicit per-import boundary.
- Law: the deferred surface grows by one declaration — a new cold dependency is one more `lazy` line, a new mandatory re-export one more module-scope `lazy from` name, a new optional surface one more `EXTRAS` row — no consumer is edited, and a removed name breaks loudly at its first reference. The `__getattr__` body stays a pure idempotent resolver, its memoization riding import idempotency under the import lock; a genuinely computed value that must cache takes a `threading.Lock` double-check, never an unguarded `globals()[name] = ...` check-then-set that races under a free-threaded build.
- Boundary: `if TYPE_CHECKING: from X import Y` is the narrower form for a name that must never load at runtime, while a `lazy from X import Y` used only in annotations already costs nothing under PEP 649/749 deferred evaluation, so the guard is reserved for the reference that must stay unimportable. A module whose import registers or runs a side effect — codec, dtype, driver, or plugin registration — is never `lazy`-deferred, since deferral moves the effect to an arbitrary first-use site and a worker thread under free-threading; force it eager through the runtime's `sys.set_lazy_imports_filter`, or populate the registry by explicit entry-point discovery owned by `boundaries.md`. The proxy reifies on a first `LOAD_GLOBAL`/`LOAD_NAME`, attribute access, `getattr`, or `types.LazyImportType.resolve()` — `globals()`, `dir()`, `__dict__`, and `frame.f_globals` reads do not, so the `__dir__` union stays cost-free — while the reification mechanism, `sys.lazy_modules` membership, the `sys.set_lazy_imports` modes, and the `require-lazy`/`ban-lazy` policy belong to the runtime owner and the enforcement gate.
- Exemption: the module `__getattr__` resolver is the platform-forced statement seam — the attribute protocol calls it and reads a raised `AttributeError` as the miss signal, so it cannot ride the `Result` rail; its `find_spec` presence guard, the `raise AttributeError` miss, and the `raise ImportError` install-hint on a known-but-absent optional dependency (where `hasattr` raises and `find_spec` probes without importing) are its only statements.

```python conceptual
import threading
from importlib import import_module
from importlib.metadata import version
from importlib.util import find_spec

from builtins import frozendict

lazy import driver  # CASE A: heavy native dep, proxy reified on first use
lazy from worker import Backend  # CASE A: cold peer, deferral breaks the import cycle

lazy from package import codec, store  # CASE B: mandatory submodule re-exports, lexically static-visible
lazy from package.core import Shape, TABLE  # CASE B: mandatory owner symbols, in-__init__ deferral breaks the self-cycle
lazy from package.render import render


type Extra = tuple[str, str | None, str]  # (module, attribute|None, install-extra); a None attribute publishes the module
DISTRIBUTION = "package"

EXTRAS: frozendict[str, Extra] = frozendict({
    "accelerated": ("accel", None, "accel"),  # CASE B: optional backend gated by an install extra
    "Probe": ("plugins", "Probe", "plugins"),  # the next optional surface lands as one row
})
_LOCK = threading.Lock()
_VERSION: str | None = None


def __getattr__(name: str, /) -> object:
    global _VERSION
    if name == "__version__":
        if _VERSION is None:  # double-checked compute cache; never a bare globals()[name] = ... race
            with _LOCK:
                if _VERSION is None:
                    _VERSION = version(DISTRIBUTION)
        return _VERSION
    if (entry := EXTRAS.get(name)) is None:
        raise AttributeError(name)  # CASE B: unknown name, attribute-protocol miss
    module, attribute, extra = entry
    if find_spec(module) is None:  # non-importing presence probe; hasattr would raise, find_spec stays silent
        raise ImportError(f"{name!r} needs the {extra!r} extra: pip install {DISTRIBUTION}[{extra}]")
    resolved = import_module(module)  # import idempotency memoizes; the resolver stays pure
    return resolved if attribute is None else getattr(resolved, attribute)


def __dir__() -> list[str]:  # dir() never reifies (special-cased in __dir__), so the union is free
    return sorted({*__all__, "__version__", *EXTRAS})


__all__ = ("Backend", "Shape", "TABLE", "codec", "driver", "render", "store")
```

[TEMPLATE_STRUCTURE_SITE]:
- Use when: dynamic text must preserve template structure for policy or AST analysis instead of collapsing to a rendered string.
- Accept: live `string.templatelib.Template`/`Interpolation` for evaluated `value`/`expression`/`conversion`/`format_spec` fields, and `ast.TemplateStr`/`ast.Interpolation` over `ast.parse(optimize=, module=)` for the pre-evaluation source structure — `Constant.value` static segments, `Interpolation.str` expression text with the integer `conversion` ordinal, and the nested `Interpolation.format_spec` as an `ast.JoinedStr` of `ast.FormattedValue` expression nodes — proved congruent with `ast.compare`.
- Reject: f-string pre-parsing, rendered-string reparsing, regex extraction from formatted text, hand-built interpolation tuples, `ast.dump` string comparison where `ast.compare` decides node equality, string concatenation hiding template policy, and an f-string, `%`-format, or `str.format` splice of dynamic input into SVG, XML, HTML, or Typst markup, whose interpolation renders before the destination escaper can run.
- Law: untrusted or dynamic input interpolated into markup — SVG, XML, HTML, or Typst — rides a `string.templatelib.Template`, never an f-string, because an f-string renders the interpolation into the surrounding markup before any escape point can intercept it; a `Template` instead exposes each `Interpolation.value` for a destination-keyed processor to escape or validate against its target grammar before render, and `xml.etree.ElementTree` builds the XML or SVG node tree so a serializer escapes rather than a string splice.
- Boundary: the render-time fold of a live `Template`'s `str | Interpolation` segments, the conversion/format-spec application, and the destination-keyed escaping or validation of each `Interpolation.value` are `system-apis.md`'s; this site owns the structural type forms — the AST nodes and the live `Template` shape — read before any rendering, never the render itself.

```python conceptual
import ast

from builtins import frozendict

type Segment = tuple[str, str, tuple[str, ...]]
type TemplateShape = tuple[tuple[str, ...], tuple[Segment, ...]]

CONVERSION: frozendict[int, str] = frozendict({-1: "<plain>", 114: "<repr>", 115: "<str>", 97: "<ascii>"})


def _spec(part: ast.Interpolation, /) -> tuple[str, ...]:
    nested = part.format_spec
    return () if nested is None else tuple(ast.unparse(field.value) for field in nested.values if isinstance(field, ast.FormattedValue))


def shaped(source: str, /) -> TemplateShape:
    template = ast.parse(source, mode="eval", optimize=1, module="<template>").body
    statics = tuple(part.value for part in template.values if isinstance(part, ast.Constant))
    fields = tuple((part.str, CONVERSION[part.conversion], _spec(part)) for part in template.values if isinstance(part, ast.Interpolation))
    return statics, fields


SHAPE = shaped('t"<head>{alpha!r:>{width}}<mid>{beta}<tail>"')
CONGRUENT = ast.compare(ast.parse('t"{alpha}"', mode="eval"), ast.parse('t"{alpha}"', mode="eval"))
```

[REFLECTION_SITE]:
- Use when: annotations, members, unions, protocols, generic bases, execution locals, or AST structure must be read as the language's own structured form instead of reconstructed from rendered text or private state.
- Accept: deferred annotations through `annotationlib.get_annotations(format=...)` and `inspect.signature(annotation_format=...)` at the `annotationlib.Format` the consumer needs — `VALUE`, `FORWARDREF`, or `STRING`; side-effect-free member reads through `inspect.getmembers_static()`; union and protocol shape through `typing.get_origin()`/`get_args()`/`get_protocol_members()`/`is_protocol()`; generic bases through `types.get_original_bases()`; execution locals through an explicit `locals=` argument or a `types.FrameLocalsProxyType` over `frame.f_locals`; and AST structure through per-node `ast.<Node>._field_types` with `ast.compare()` deciding node equality over `ast.parse(optimize=, module=)`.
- Reject: direct `__annotations__`/`__orig_bases__`/`__protocol_attrs__` dunder reads, descriptor-triggering `getattr` member scans, private union or protocol implementation probes, mutating `locals()` snapshots, `ast.dump()` string comparison where `ast.compare()` decides equality, and re-parsing rendered text a structured reader already returns.
- Boundary: these are static structural reads feeding a generated owner, dispatch table, or registry; they never re-validate an admitted owner or materialize a value. The live `Template`/`Interpolation` render structure is the template-structure site's, and the value the read ultimately drives belongs to the shape page.

The reflection spotlight: one entrypoint discriminates on whether the subject is a protocol or a concrete owner, then folds every structural reader into one `frozendict` evidence registry — `get_protocol_members` over a proven protocol, `annotationlib.get_annotations(format=FORWARDREF)` reading deferred field hints without forcing evaluation, `get_original_bases` with `get_origin`/`get_args` decomposing the generic base list, and side-effect-free `inspect.getmembers_static` over the public member set — feeding a generated owner with no descriptor triggered and no value materialized.

```python conceptual
import annotationlib
import inspect
from types import get_original_bases
from typing import Protocol, get_args, get_origin, get_protocol_members, is_protocol

from builtins import frozendict

type Reflected = frozendict[str, frozendict[str, str]]


class Port(Protocol):
    def loaded(self, key: str, /) -> int: ...
    def committed(self, seal: str, /) -> int: ...


class Shape[T](Port):
    primary: list[T]
    refined: frozendict[str, T]

    def loaded(self, key: str, /) -> int: ...
    def committed(self, seal: str, /) -> int: ...


def reflected(subject: type, /) -> Reflected:
    members = frozendict({name: "<required>" for name in get_protocol_members(subject)} if is_protocol(subject) else {})
    deferred = annotationlib.get_annotations(subject, format=annotationlib.Format.FORWARDREF)
    fields = frozendict({name: getattr(hint, "__forward_arg__", repr(hint)) for name, hint in deferred.items()})
    origins = frozendict({getattr(get_origin(base) or base, "__name__", repr(base)): repr(get_args(base)) for base in get_original_bases(subject)})
    statics = frozendict({name: type(member).__name__ for name, member in inspect.getmembers_static(subject) if not name.startswith("_")})
    return frozendict({"members": members, "fields": fields, "origins": origins, "statics": statics})


REFLECTED: Reflected = reflected(Shape)
```

[CLOSED_MATCH_SITE]:
- Use when: a closed domain must project every case through one operation-local `match` statement.
- Accept: structural pattern dispatch over the sealed member set, one operation-local projection, and `case _ as unreachable: assert_never(unreachable)` as the exhaustiveness witness; a `TypeIs` predicate narrows at the projection boundary before the `match`, never as a guarded arm the checker cannot prove total.
- Reject: tag `if` chains, an arm body opening a second `match` or an `if` ladder where a refining guard or an or-pattern carries the sub-case, a `case x if predicate(x):` guard arm carrying the only narrowing, catch-all raises, default arms that hide a missing case, and pre-match normalization that erases the discriminant.
- Boundary: the type-evidence spotlight above demonstrates the closed `match` over `@disjoint_base` members; variant ownership, error rail shape, and cross-module dispatch architecture belong to the owning domain or surface concept page.

[SENTINEL_DEFAULT_SITE]:
- Use when: omission or inherited selection must be distinct from every valid domain value, including `None`.
- Accept: module-global `NAME = Sentinel("NAME")` through the PEP 661 `typing_extensions.Sentinel` the `typing` namespace does not yet export, the variable name matching the sentinel name, reused by `is`, and carried directly in the union as `T | NAME`.
- Reject: a repeated `Sentinel("NAME")` call for one semantic value — a second call mints a distinct object, so the module global is the sole identity — `object()` defaults, `None` defaults when `None` is domain-valid, string tokens, omitted-vs-supplied overloads with no return-shape change, and bool flags that split one option shape.
- Boundary: queue or task lifecycle, wire payload tags, and protocol tokens use the owning lifecycle API or explicit domain value instead of sentinel payloads.

[FROZENDICT_TABLE_SITE]:
- Use when: immutable mapping rows or nested policy tables need mapping semantics, language-level immutability, and order-insensitive equality or hashing of the `frozendict` value.
- Accept: `frozendict[K, V]` rows with hashable keys; values must also be hashable when the row itself is hashed or used as an outer key.
- Law: one primary correspondence is the single edit site and every secondary — an inverse, a projection, a nested composite-keyed policy table — is a comprehension over the primary's `.items()`, so a new entry lands once on the primary and each derived table re-derives with no consumer edited.
- Reject: tuple-pair pseudo-maps, sorted-item key normalizers, module-level dictionaries used as immutable policy tables, `MappingProxyType` views over mutable storage, frozen shells around dictionaries, mutate-then-freeze copy ladders, and a hand-maintained secondary map kept parallel to the primary it should derive from.
- Boundary: `frozendict` is not a `dict` subclass and preserves insertion order for iteration, but order is not equality or value-hash semantics; use tuple pairs or an owning value object when order is semantic. `frozendict` is shallowly immutable; nested values must be immutable or owned by a model.

```python conceptual
from builtins import frozendict
from enum import EnumCheck, StrEnum, verify


@verify(EnumCheck.UNIQUE)
class Tier(StrEnum):
    PRIMARY = "<tier-a>"
    SECONDARY = "<tier-b>"
    TERTIARY = "<tier-c>"


class Field(StrEnum):
    TIER = "<field-a>"
    ZONE = "<field-b>"


type Row = frozendict[Field, str]

WEIGHT: frozendict[Tier, int] = frozendict({Tier.PRIMARY: 1, Tier.SECONDARY: 2, Tier.TERTIARY: 4})
RANK: frozendict[int, Tier] = frozendict({weight: tier for tier, weight in WEIGHT.items()})
POLICY: frozendict[Row, int] = frozendict({frozendict({Field.TIER: tier, Field.ZONE: "<zone-a>"}): weight for tier, weight in WEIGHT.items()})

SELECTED: int = POLICY[frozendict({Field.ZONE: "<zone-a>", Field.TIER: Tier.SECONDARY})]
HEAVIEST: Tier = RANK[max(RANK)]
```

## [04]-[ABSTRACTION_COLLAPSE_TESTS]

Use these tests before keeping a local abstraction beside a language primitive.

[TYPE_EVIDENCE_REPAIR]:
- Smell: a cast, alias, erased callable, fake protocol, runtime-checkable shell, or bool predicate exists only to recover type evidence the declaration itself carries.
- Collapse: move evidence into the owner declaration, `TypeIs` predicate, `TypedDict` payload, `TypeForm`, parameter-preserving callable, or real structural owner.
- Done when: callers narrow, call, unpack, or inspect the value without `cast`, wildcard protocols, post-check repair code, or duplicated declaration aliases.

[STRING_RECOVERY]:
- Smell: code parses rendered strings, paths, URLs, annotations, regex intent, warning filters, template fields, AST structure, or source names by hand.
- Collapse: ask the language API for the structured form.
- Done when: the implementation consumes typed components instead of reconstructed text.

[MAGIC_VALUE]:
- Smell: absence, inherited selection, closed-domain membership, or ordering is carried by a bare string, an `object()` token, a numeric sentinel, or a `.value` literal the program already names.
- Collapse: replace the literal with the language form that carries the semantics — `Sentinel("NAME")` for omission, a `StrEnum`/`Literal` member for closed membership, a `frozendict` row for a derived correspondence, `Never`/`assert_never` for the unreachable arm.
- Done when: the value carries its own semantics through a named language form, and no prose restates a meaning the declaration already holds; stdlib primitive policy (`uuid.NIL`/`uuid.MAX`, base-N decode flags, buffer flags) is the system-API owner's magic-value rule, named there.
