# [PYTHON_SHAPES]

A value-level concept takes exactly one owner, and the lifecycle `Raw -> Payload -> Canonical owner -> Rail -> Projection -> Egress` fixes where it changes shape: raw material is admitted once into an evidence-carrying owner, the interior is total over admitted owners, and projection plus egress derive outward. Role decides first, owner second, projection third; stage names, function names, and return types agree with the stage they occupy — materialization returns the canonical owner, projection returns the boundary view, egress returns encoded or foreign material.

One refinement policy, one fault vocabulary, and one canonical owner span the whole lifecycle: the admission bound is declared once as policy and projected into the form each stage's own validator enforces, so the admission rule has one edit site and no parallel DTO restates it. Admit a payload, ingress model, canonical owner, vocabulary, port, projection, or replacement only when it changes implementation law; reject package-branded interior layers, parallel DTOs, field-rename wrappers, and shapes minted to lower local line count or to mask weak ownership.

## [01]-[SHAPE_LIFECYCLE]

Choose the lifecycle role before adding an owner, construct, rail, or projection.

[ROLE_INDEX]:

| [INDEX] | [ROLE]          | [POSITION]             | [ACCEPTS]             | [EMITS]            | [OWNER]          | [REJECTED_FORM]      |
| :-----: | :-------------- | :--------------------- | :-------------------- | :----------------- | :--------------- | :------------------- |
|  [01]   | Raw ingress     | before admission       | external material     | payload or ingress | boundary adapter | domain raw           |
|  [02]   | Typed payload   | before materialization | static dictionary law | ingress or owner   | payload contract | interior payload     |
|  [03]   | Canonical owner | domain entry           | admitted values       | owner rail or view | domain concept   | parallel DTO         |
|  [04]   | Rail/effect     | operation result       | owner or fault        | value or error     | operation edge   | exception flow       |
|  [05]   | Projection      | boundary view          | canonical owner       | wire or row shape  | adapter surface  | projection authority |
|  [06]   | Egress          | final handoff          | projection            | encoded material   | codec writer     | late correctness     |

[HANDOFF_LAW]:
- Law: a stage skip is admitted only where one boundary owns both endpoints — `Raw -> Canonical owner` fuses payload and materialization at a single factory when no payload type is reused, and any other skip is a missing owner, not a shortcut.
- Law: an erased `object` or `Mapping[str, object]` handoff stops at the boundary that admits it; the interior signature names the canonical owner, the closed member, the owner rail, or the admitted port, and never the erased shape.
- Law: a composed pipeline keeps each lifecycle surface visible — admission, materialization, projection, and egress stay nameable functions or methods, never folded into one opaque pass that hides where shape changes.

[SHARED_REFINEMENT]:
- Law: each validator enforces only its own metadata — `msgspec.Meta(...)` on the wire, a `pydantic` `Field(min_length=..., ge=...)` (or its constrained-type) at ingress, `beartype.vale.Is[...]` at the owner factory — and no validator reads a foreign one's marker, so the policy is declared once as the numeric edge plus the predicate and each stage projects the slice it enforces: the shared edge derives the wire and ingress markers from one constant pair, the predicate rides the owner alias alone, and no mixed alias serves all three; the policy is the single edit site, zero parallel constraint values.
- Law: `beartype.vale.Is[...]` and `msgspec.Meta(...)` never share one `Annotated` on a `@beartype` factory hint, in either order — `[Is, Meta]` raises `BeartypeDecorHintPep593Exception` at decoration (rejecting the agnostic `Meta` as "not beartype validator"), and `[Meta, Is]` is worse, decorating cleanly while silently dropping the `Is` so an unrefined value passes the contract — so the owner alias carries the predicate-as-`Is` alone (the numeric edge is already wire-proven before the factory) while `msgspec.Meta` rides the wire alias and the pydantic `Field` constraint rides the ingress field, each marker landing on the validator that reads it.
- Law: admission maps a contract violation onto the seam's fault, never an exception into the interior — `ConfigDict(extra="forbid", strict=True)` on the ingress model rejects drift, `BeartypeConf(violation_type=...)` redirects a boundary violation to a domain exception the seam catches, and the interior receives only the admitted owner.
- Exemption: `delivered` is the measured admission kernel — one `try` whose `except ValidationError` drift arm precedes its `except ValueError` refusal arm because pydantic's `ValidationError` subclasses `ValueError`, so the most-specific raise maps to `<drift>` and the `@beartype` refusal to `<refused>`; this ordered-capture seam is the named platform-forced statement site, and every interior signature past it is expression-shaped over the admitted owner.
- Reject: a mixed `Is[...]` + `msgspec.Meta(...)` alias on a beartype factory; a validator's bound expressed in a foreign validator's marker that the validator silently ignores; re-validating an admitted owner in the interior; a `try`/`except` wrapping an interior rail transform.

[LIFECYCLE_FLOW]:

```python conceptual
from dataclasses import dataclass
from typing import Annotated, Literal

import msgspec
from beartype import BeartypeConf, beartype
from beartype.vale import Is
from expression import Error, Nothing, Ok, Option, Result
from pydantic import BaseModel, ConfigDict, Field, ValidationError

_MIN, _MAX = 1, 64

type KeyBound = Annotated[str, msgspec.Meta(min_length=_MIN, max_length=_MAX)]
type KeyRefined = Annotated[str, Is[lambda value: value.isascii()]]
type AdmitFault = Literal["<drift>", "<refused>"]

_ADMIT = BeartypeConf(violation_type=ValueError)


class ShapeIngress(BaseModel):
    model_config = ConfigDict(frozen=True, extra="forbid", strict=True)
    key: str = Field(validation_alias="source_key", min_length=_MIN, max_length=_MAX)
    note: str | None = Field(default=None, validation_alias="source_note")


class ShapeWire(msgspec.Struct, frozen=True, gc=False, omit_defaults=True, rename={"key": "wire_key", "note": "wire_note"}):
    key: KeyBound
    note: str | None = None


@dataclass(frozen=True, slots=True, kw_only=True)
class Shape:
    key: KeyRefined
    note: Option[str] = Nothing

    def wired(self, /) -> ShapeWire:
        return ShapeWire(key=self.key, note=self.note.default_value(None))


@beartype(conf=_ADMIT)
def admitted(*, key: KeyRefined, note: Option[str] = Nothing) -> Shape:
    return Shape(key=key, note=note)


def delivered(raw: object, /) -> Result[Shape, AdmitFault]:
    try:
        ingress = ShapeIngress.model_validate(raw)
        return Ok(admitted(key=ingress.key, note=Option.of_optional(ingress.note)))
    except ValidationError:
        return Error("<drift>")
    except ValueError:
        return Error("<refused>")
```

## [02]-[OWNER_CHOOSER]

Choose the invariant owner before choosing a package-backed model, wrapper, protocol, rail, enum, or immutable collection. Five discriminants make the choice mechanical, and every misplaced shape traces to one mis-answered discriminant: admission (is the material trusted, or does it cross an untrusted edge), identity regime (is equality by value, by tag, by key, or by reference), variant arity (one shape, a closed family, or an open extension set), payload timing (is the shape fixed at definition or admitted at runtime), and openness (is the family closed to the program, semi-closed at a versioned wire, or open to foreign code). The OWNER_INDEX rows below are keyed on the answer to these discriminants.

[OWNER_INDEX]:

| [INDEX] | [DECISION]             | [DISCRIMINANT]           | [OWNER]              | [CHOOSE]                   | [REJECTED_FORM]       |
| :-----: | :--------------------- | :----------------------- | :------------------- | :------------------------- | :-------------------- |
|  [01]   | static keys            | untrusted, def-time      | `[BOUNDARY_SHAPES]`  | closed `TypedDict`         | `dict[str, object]`   |
|  [02]   | untrusted admission    | untrusted, runtime       | `[BOUNDARY_SHAPES]`  | Pydantic                   | interior revalidation |
|  [03]   | wire or row            | trusted, fixed layout    | `[BOUNDARY_SHAPES]`  | `msgspec.Struct`           | domain wire owner     |
|  [04]   | compact invariant      | trusted, value-equal     | `[DOMAIN_SHAPES]`    | frozen dataclass           | field rename class    |
|  [05]   | durable schema or wire | trusted, schema-bound    | `[DOMAIN_SHAPES]`    | frozen Pydantic or msgspec | second owner          |
|  [06]   | behavior-dense owner   | trusted, behavior > data | `[DOMAIN_SHAPES]`    | rich class                 | forwarding helper     |
|  [07]   | token or absence state | closed, tag identity     | `[TOKEN_STATE_PORT]` | vocabulary, sentinel, rail | duplicate carriers    |
|  [08]   | immutable evidence     | trusted, key/order id    | `[TOKEN_STATE_PORT]` | tuple, `frozendict`, `Map` | mutable staging       |
|  [09]   | replaceable capability | open, structural id      | `[TOKEN_STATE_PORT]` | `Protocol`                 | single implementation |

[OWNER_SELECTION]:
- Law: the discriminant columns resolve left to right and the first matching row wins — admission is read before identity, identity before arity — so a shape that matches `[BOUNDARY_SHAPES]` on admission never falls through to a `[DOMAIN_SHAPES]` arity match, and placement is mechanical rather than by feel.
- Law: a `[BOUNDARY_SHAPES]` owner exists only between the wire and the canonical owner — `TypedDict` carries static-key closure (`closed=True`/`extra_items`/per-key `Required`/`NotRequired`/`ReadOnly`), Pydantic carries untrusted runtime admission, settings, alias policy, and `Discriminator`/`Tag` variant resolution, `msgspec.Struct` carries deterministic wire/row layout with `gc=False` dropping a non-container leaf from the tracked set on hot paths — and none survives into an interior signature.
- Law: a `[DOMAIN_SHAPES]` owner is the first durable frozen shape the interior accepts — a frozen dataclass for a compact value-equal invariant under `copy.replace`, a frozen Pydantic model only when compiled validation, computed fields, and JSON Schema are themselves the contract, a frozen `msgspec.Struct` only when a fixed wire layout is the canonical owner, a rich class when construction law, folds, transitions, evidence, or projection methods exceed declarative fields.
- Law: a `[TOKEN_STATE_PORT]` owner carries identity without product — `StrEnum`/`Literal` for token identity, `Sentinel("NAME")` for caller omission, a `@tagged_union` case for dispatch-changing absence, `frozendict`/`Map`/`tuple`/`Block`/`frozenset` for immutable evidence, a `Protocol` only where independent implementers replace one operation family — and never a one-field wrapper standing in for a scalar the interior already owns.
- Reject: a package-branded interior layer, a parallel DTO, a one-field wrapper without an independent invariant, `None`-as-failure, `Option` masking an error cause, mutable staging after materialization, and a protocol minted to repair weak ownership — each is a row answered by package convenience instead of by discriminant.

[COLLAPSE_AND_GROWTH]:
- Law: the collapse move is keyed on which owner absorbs the family, and the absorption test is the `[02]` discriminants, never a field-count or a resemblance judgment — sibling shapes answering admission, identity regime, payload timing, and consumer identically fold into one `[DOMAIN_SHAPES]` closed family (a union of distinct frozen records for distinct payloads, a `@tagged_union` when each case carries payload), sibling module constants fold into one `[TOKEN_STATE_PORT]` `frozendict` table or `StrEnum`, a wrapper renaming a package API dissolves into the `[BOUNDARY_SHAPES]` package surface used directly, and a sibling survives beside the family only on a genuinely distinct discriminant answer it can name.
- Law: a one-field wrapper, a field-rename class, a sibling factory, and a variant shell each fold into the deeper owner — the wrapper becomes a refinement alias on the owner's field, the rename becomes an egress projection, the sibling factory becomes one classmethod discriminating on input shape, the shell becomes one case under the owner's `match`.
- Law: the same owner is the single growth site forward, and the diff of the next requirement names it — a new `[BOUNDARY_SHAPES]` key is one `extra_items`/`Required` line plus one promotion-fold branch, a new `[DOMAIN_SHAPES]` variant is one frozen record plus one arm under the total `match`, a new `[TOKEN_STATE_PORT]` token is one vocabulary member, a new policy correspondence is one `frozendict` row, and the projection and rail follow by derivation so a new field reaches the wire through one projection, never a parallel edit across owner, wire, and row.
- Reject: a shape minted to lower local line count, a mirror total/non-total payload pair, an enum-plus-parallel-`dict` where the enum should carry the column, a second owner restating an invariant the first proves, a new requirement answered by a parallel type or boolean flag rather than a case/row/member, and an owner sized for the single case in hand whose every consumer must change when the second arrives.

[OWNER_COMPOSITION]:
- Law: owners nest without revalidation — a canonical owner holding another canonical owner trusts the inner owner's admission, and the outer materialization never re-runs the inner factory, because admission is proven once at the leaf and the composite inherits it.
- Law: identity regime stays local to each owner in a composite — a value-equal field, a tag-identity case, and a key-identity vocabulary coexist under one owner, each comparing by its own regime, and the composite's equality is the structural product of its fields' regimes, never a flattened reference check.
- Law: a recursive node — a self-nesting composite such as an AST or document tree node — indexed in a map or diffed against another tree takes key identity by structural path, the `tuple[int, ...]` of child ordinals from the root that is the node's structural uid, never by content, because a content-only key collapses structurally-distinct identical siblings onto one slot; content equality is the separate change-detection axis compared only within a fixed path, and the counterpart on the foreign-owner axis, where content cannot recover the foreign owner's identity, is the boundary page's.
- Boundary: a wire projection of a composite owner projects through one converter at the edge (`msgspec.convert` for a pure rename, an explicit constructor or `frozendict` adapter for a value transform), never by flattening the nested owners into one wire bag; the projection mechanics are the boundary page's, composed here.

## [03]-[PAYLOAD_AND_MATERIALIZATION]

A typed payload is the one shape that lives between the wire and the canonical owner: admitted exactly once and never forwarded inward. The closed `TypedDict` payload type form — exact-key closure, the typed `extra_items` band, per-key presence and read-only evidence, and the `Unpack[TypedDict]` root signature — is the language page's settled contract; this page owns the value lifecycle it sheds, where a module-level `TypeAdapter` is the runtime admission gate that materializes the payload into the owner and the extension band condenses into one `frozendict` of evidence.

[TYPED_PAYLOADS]:
- Law: the payload admits exactly once through one module-level `TypeAdapter`, and its type appears only at the `Unpack` root signature — never in a domain interior, because materialization hands the interior the canonical owner; per-request `TypeAdapter` construction and a forwarded payload kwarg are the two leaks this forbids.
- Law: the `extra_items` band materializes into one `frozendict` of evidence at promotion — `ReadOnly` is a static marker no runtime validator enforces inside a band, so the frozen owner field carries extension immutability — and the band partitions through `Payload.__required_keys__ | __optional_keys__`, never a key set hand-listed parallel to the declaration.
- Law: a new key grows the payload by one closure or band line plus one branch in the promotion fold and the owner by one field; a second total/non-total mirror shape, a homogeneous `**kwargs` widening, or a parallel `Mapping[str, object]` bag is the rejected alternative.
- Exemption: `accepted` is the measured admission kernel — the single `try` is the `TypeAdapter.validate_python` gate, the one `except ValidationError` enriches the raised fault with the `.errors()` `loc` paths through `add_note` before mapping to `<invalid-payload>`, and every signature past it holds the materialized owner; this `TypeAdapter` seam is the payload section's named platform-forced statement site, distinct from the `[01]` ordered-capture kernel because one closed payload admits through one validator rather than the wire-then-owner refinement split.
- Reject: a forwarded payload kwarg, a payload type in a domain interior signature, runtime revalidation repairing an erased payload, and a second `TypeAdapter` pass over the already-admitted payload.

```python conceptual
from dataclasses import dataclass, field
from typing import Literal, NotRequired, ReadOnly, Required, Self, TypedDict, Unpack

from builtins import frozendict
from expression import Error, Ok, Result
from pydantic import TypeAdapter, ValidationError

type PayloadFault = Literal["<invalid-payload>"]


class ShapePayload(TypedDict, extra_items=str):
    key: Required[ReadOnly[str]]
    rank: NotRequired[ReadOnly[int]]


_PAYLOAD = TypeAdapter(ShapePayload)
_DECLARED: frozenset[str] = ShapePayload.__required_keys__ | ShapePayload.__optional_keys__


@dataclass(frozen=True, slots=True, kw_only=True)
class Shape:
    key: str
    rank: int = 0
    extensions: frozendict[str, str] = field(default_factory=frozendict)

    @classmethod
    def materialized(cls, payload: ShapePayload, /) -> Self:
        band = frozendict({name: value for name, value in payload.items() if name not in _DECLARED})
        return cls(key=payload["key"], rank=payload.get("rank", 0), extensions=band)


def accepted(**raw: Unpack[ShapePayload]) -> Result[Shape, PayloadFault]:
    try:
        return Ok(Shape.materialized(_PAYLOAD.validate_python(raw)))
    except ValidationError as fault:
        fault.add_note(f"<errors:{[error['loc'] for error in fault.errors()]}>")
        return Error("<invalid-payload>")
```

[PYDANTIC_ADMISSION]:
- Use: module-level `TypeAdapter` for unions, payloads, scalars, and containers; frozen and closed ingress models (`ConfigDict(frozen=True, extra="forbid")`) for closed contracts; `Discriminator`/`Tag` for variant admission instead of ambiguous union order; `AliasChoices`/`AliasGenerator` for wire-to-canonical renaming.
- Law: validators normalize and admit only — no I/O, registry mutation, or domain orchestration inside a validator — and a caught `ValidationError` maps through `.errors()` (the `loc` path and `type` code), never `str(exc)`, before entering domain logic.
- Reject: per-request `TypeAdapter` construction, `model_construct` on untrusted input, `model_dump` key surgery, and a second Pydantic pass inside a domain interior.

[MATERIALIZATION]:
- Law: normalization precedes construction — wire names and foreign tokens resolve to canonical spelling before the owner factory runs, and promotion crosses exactly one named adapter or composition-root gate, never a scatter of inline coercions ahead of the constructor.
- Law: construction that can fail returns `Result[Owner, E]`; the interior then receives owners, closed-family members, or rails over owners, never the payload.
- Law: egress projects from the canonical owner through `msgspec.convert`, explicit construction, or an owner-approved projection — never a re-validation pass.

## [04]-[CANONICAL_OWNERS]

The canonical owner is the first durable frozen shape domain logic accepts, and it owns the invariants, lifecycle transitions, folds, and projections that no boundary owns. Owner-type selection follows OWNER_INDEX rows [04]-[06]; a canonical owner never imports a boundary engine unless that engine is itself the durable owner.

[CANONICAL_OWNER_LAW]:
- Law: domain invariants and the failable transition graph live on the owner — a transition that can fail returns `Result[Self, E]` so the successor re-proves the invariant, and an absence-bearing field is `Option[T]`, never `None`; the transition is an owner method, never a free function reconstructing the invariant outside the owner.
- Law: a guard transition reads the owner's own evidence to admit or refuse the next state, so a sequence of transitions threads through `bind` and reports the first refusal, and the owner is the single site that knows which moves are legal from which state.
- Law: a projection method derives the boundary view from the owner and the view never gains authority; the projection mechanics and the projection family are the boundary page's and the projection card's, named here only as the owner's outward derivation.
- Law: a primitive earns this owner when its validation, bundle, or factory recurs — repeated primitive validation graduates to one refinement alias or owner field, a repeated field bundle to one owner, mutable update law to an immutable transition method, and a stable wire or persistence concern to an egress projection, never to a second domain owner mirroring the first.
- Reject: a boundary engine imported into an interior owner, a mutable field on a frozen owner, a transition as a free function, a projection that revalidates, a mirrored validation/domain/wire owner hierarchy, a validator side effect, and a tag-only shape family.

```python conceptual
from copy import replace
from dataclasses import dataclass
from typing import Literal, Self

from expression import Error, Nothing, Ok, Option, Result
from expression.collections import Block

type ShapeFault = Literal["<empty-key>", "<empty-tag>", "<duplicate-tag>", "<sealed>"]


@dataclass(frozen=True, slots=True, kw_only=True)
class Shape:
    key: str
    note: Option[str] = Nothing
    tags: tuple[str, ...] = ()
    sealed: bool = False

    @classmethod
    def admit(cls, *, key: str, note: Option[str] = Nothing) -> Result[Self, ShapeFault]:
        return Ok(cls(key=key, note=note)) if key else Error("<empty-key>")

    def tagged(self, tag: str, /) -> Result[Self, ShapeFault]:
        match tag:
            case _ if self.sealed:
                return Error("<sealed>")
            case "":
                return Error("<empty-tag>")
            case existing if existing in self.tags:
                return Error("<duplicate-tag>")
            case fresh:
                return Ok(replace(self, tags=(*self.tags, fresh)))

    def sealed_after(self, *tags: str) -> Result[Self, ShapeFault]:
        threaded = Block.of_seq(tags).fold(lambda owner, tag: owner.bind(lambda live: live.tagged(tag)), Ok(self))
        return threaded.map(lambda live: replace(live, sealed=True))
```

## [05]-[VOCABULARY_ABSENCE_AND_VARIANTS]

One vocabulary owner feeds ingress discriminants, canonical tags, wire tags, registry rows, and schema enum arms; absence is a closed axis, not a scatter of nullable fields; and a variant family is one owner namespace under a total `match`. The three concerns share one rule: a bounded set of states is one closed owner, never parallel module-level types or boolean flags.

[VOCABULARY]:
- Use: `StrEnum` for runtime token identity, iteration, registry keys, settings, CLI, or wire values; `Literal` when static proof suffices and no runtime vocabulary behavior is needed; verified `Flag` only when bit composition is the contract.
- Reject: routing on `.value` strings in domain code; duplicating a token band across enums, literals, schemas, fixtures, and handler maps.

[ABSENCE]:
- Law: omitted key is `NotRequired[T]`; valid null is `T | None` only when `None` is a real domain or wire value; caller omission or inherited default rides the `Sentinel("NAME")` form, distinct from every valid value including `None`, and never serialized.
- Law: wire unset is the codec's own presence sentinel collapsed at the seam — `msgspec.UNSET` (a field typed `T | UnsetType = UNSET` round-trips absent under `omit_defaults`) on the struct side and `pydantic.experimental.missing_sentinel.MISSING` on the model side — and the domain absence axis that changes dispatch is a `@tagged_union` case, never the wire sentinel leaked inward.
- Law: `Nothing` is non-failing computed absence after admission; `Result.Error` is failure.
- Reject: `None` for failure, a sentinel on a wire struct's domain field, `Option` hiding validation errors, bool flags splitting one option shape, and three loose dataclasses standing in for one closed absence family.

```python conceptual
from typing import Literal, assert_never

import msgspec
from expression import Error, Nothing, Ok, Option, Result, Some, case, tag, tagged_union

type NoteFault = Literal["<empty-note>"]


@tagged_union(frozen=True)
class Note:
    tag: Literal["omitted", "null", "provided"] = tag()
    omitted: None = case()
    null: None = case()
    provided: str = case()


class NotePatch(msgspec.Struct, frozen=True, omit_defaults=True):
    note: str | None | msgspec.UnsetType = msgspec.UNSET


def admitted_note(patch: NotePatch, /) -> Result[Note, NoteFault]:
    match patch.note:
        case msgspec.UnsetType():
            return Ok(Note(omitted=None))
        case None:
            return Ok(Note(null=None))
        case "":
            return Error("<empty-note>")
        case str() as text:
            return Ok(Note(provided=text))


def selected(note: Note, fallback: Option[str] = Nothing, /) -> Option[str]:
    match note:
        case Note(tag="provided"):
            return Some(note.provided)
        case Note(tag="null"):
            return Nothing
        case Note(tag="omitted"):
            return fallback
        case _ as unreachable:
            assert_never(unreachable)
```

[FAMILIES]:
- Law: a closed family of variants that carry different fields or lifecycle states is one `type Member = A | B | C` union of distinct frozen records whose interior owns the failable transition fold — a transition returns `Result[Active, E]`, the live arm projects the successor record, and a fourth variant lands as one frozen record plus one arm with every fold breaking loudly at type-check until the arm exists; the growth axis is the union member, never a sibling type beside the family.
- Law: the distinct-records union is the form when cases hold disjoint field sets; the shared-field shallow encoding — one frozen owner with a `StrEnum` discriminant, or one `@tagged_union` when payload-carrying cases need a wire tag — is the codec/dispatch form the surface and boundary pages own, and the choice is field disjointness, never preference. This card owns the distinct-records transition fold; combining two transitions applicatively is the rail page's accumulation algebra, composed over this family, never re-taught here.
- Law: total structural `match` with `assert_never` is the settled exhaustiveness mechanic the language and surface pages own; this card composes it to carry the transition fold, splitting one member into sub-cases through a guard that refines after the member pattern and never stands in for the exhaustiveness proof.
- Law: a semi-closed family is a closed core union plus one typed `extra_items` extension band; an open family is admitted only when foreign or plugin code adds members without editing the owner, dispatched through `singledispatch` at the one seam the surface page owns.
- Reject: optional-field variant bags collapsing N shapes into one nullable record, string dispatch on a `.value`, `singledispatch` over an owned closed family, protocol-per-variant, catch-all default arms, a sibling transition function where an owner method states it, and foreign token spelling inside canonical members.

```python conceptual
from copy import replace
from dataclasses import dataclass
from typing import Literal, assert_never

from expression import Error, Nothing, Ok, Option, Result


@dataclass(frozen=True, slots=True, kw_only=True)
class Pending:
    key: str


@dataclass(frozen=True, slots=True, kw_only=True)
class Active:
    key: str
    epoch: int
    note: Option[str] = Nothing


@dataclass(frozen=True, slots=True, kw_only=True)
class Retired:
    key: str
    reason: str


@dataclass(frozen=True, slots=True, kw_only=True)
class Sealed:
    key: str
    epoch: int
    seal: str


type Member = Pending | Active | Retired | Sealed
type MemberFault = Literal["<not-active>", "<exhausted>"]


def advanced(member: Member, /) -> Result[Member, MemberFault]:
    match member:
        case Pending(key=key):
            return Ok(Active(key=key, epoch=1))
        case Active(epoch=epoch) if epoch >= 9:
            return Ok(Sealed(key=member.key, epoch=epoch, seal="<seal-a>"))
        case Active() as live:
            return Ok(replace(live, epoch=live.epoch + 1))
        case Sealed():
            return Error("<not-active>")
        case Retired():
            return Error("<exhausted>")
        case _ as unreachable:
            assert_never(unreachable)
```

## [06]-[PROJECTIONS_AND_PORTS]

Projection derives outward and never gains authority: a wire struct, persistence row, receipt, or schema view is computed from the canonical owner, and the owner stays unaware of the wire. One owner derives a whole projection family — the pure-rename leg and the value-transform leg are two methods on the owner, not two parallel owners — and a structural port is the inverse seam, a capability the interior consumes through admitted implementers. This page fixes which owner a port is and that an owner derives its projections; the codec mechanics that the projection methods invoke are the boundary page's.

[BOUNDARY_PROJECTIONS]:
- Law: ingress admits foreign material inward through payloads, settings, and ingress models; egress derives wire structs, rows, receipts, and schema views outward from the canonical owner, and each projection is a method on the owner so the family has one growth site, never a sibling free function per target.
- Law: the pure-rename leg and the value-transform leg split by whether the projection changes a value — a rename keeps canonical attribute names and routes through the boundary page's `msgspec.convert` seam composed in one line, a transform composes an explicit constructor or a `frozendict` correspondence, and the two never collapse onto one path because `convert` cannot transform.
- Law: a foreign boundary remaps provider names, token vocabularies, cardinality, discriminants, and omitted fields before canonical entry, and the correspondence lives in an adapter table or schema-owned alias the boundary page owns, never a provider-shaped field reaching the owner.
- Reject: projection-to-projection authority, a projection as a free function instead of an owner method, codec engines in canonical owners, scattered `model_dump` key pops, model-per-provider interiors, and a canonical `schema_version` branch that belongs to read-boundary migration.

```python conceptual
from dataclasses import dataclass
from enum import StrEnum
from typing import Annotated

import msgspec

from builtins import frozendict

type Score = Annotated[int, msgspec.Meta(ge=0)]
_WIDTH: int = 8


class Grade(StrEnum):
    PRIMARY = "<value-a>"
    SECONDARY = "<value-b>"


_BAND: frozendict[Grade, str] = frozendict({Grade.PRIMARY: "<band-a>", Grade.SECONDARY: "<band-b>"})


class ShapeWire(msgspec.Struct, frozen=True, gc=False, rename={"key": "wire_key", "grade": "wire_grade", "score": "wire_score"}):
    key: str
    grade: Grade
    score: Score


class ShapeRow(msgspec.Struct, frozen=True, gc=False):
    row_key: str
    band: str


@dataclass(frozen=True, slots=True, kw_only=True)
class Shape:
    key: str
    grade: Grade
    score: Score

    def wired(self, /) -> ShapeWire:
        return msgspec.convert(self, ShapeWire, from_attributes=True)

    def rowed(self, /) -> ShapeRow:
        return ShapeRow(row_key=f"{self.grade}:{self.key}", band=f"{_BAND[self.grade]}:{self.score:0{_WIDTH}d}")
```

[STRUCTURAL_PORTS]:
- Law: a `Protocol` is a capability seam, admitted only when multiple independent implementers satisfy one replaceable operation family without inheritance; method sets stay minimal and capability-named, and every method returns the rail the domain declares.
- Law: keying scope by `type[Port]` injects the port, `get_protocol_members` proves coverage at registration, `@runtime_checkable` gates only a real dynamic edge, and `TypeIs[Port]` narrows when semantic membership exceeds member presence.
- Boundary: the generic function constrained `[S: Port]` and its rail composition are the surface page's dispatch law; this page fixes only that the port is the owner for a replaceable capability and that its methods stay rail-typed.
- Reject: a one-method callback protocol where `Callable` works, a protocol union simulating a closed family, a protocol as a wire or ingress field, and a protocol used as weak type repair.

## [07]-[IMMUTABLE_REPLACEMENT]

A durable owner is frozen after materialization, and state change is a transition that returns a successor, never a mutation. The replacement lane splits by trust: a same-process trusted swap runs the owner kernel directly, and an untrusted, computed, or wire-sourced delta starts from a closed patch payload validated at the boundary and returns through the owner rail.

[IMMUTABLE_REPLACEMENT_LAW]:
- Law: durable collections are `tuple`, `frozenset`, `frozendict`, `Map`, `Block`, or another admitted immutable owner; a transition returns `Self`, `Result[Self, E]`, or a closed successor union.
- Law: a trusted swap uses `copy.replace`, `msgspec.structs.replace`, `frozendict` union, or a persistent `Map`/`Block` combinator; an untrusted delta validates a closed patch first, then becomes a replacement expression.
- Law: a patch is a closed `TypedDict` with `NotRequired` update fields and `Required[ReadOnly[...]]` identity or version fields, admitted exactly once through the `[03]-[PAYLOAD_AND_MATERIALIZATION]` `TypeAdapter` gate; the replacement lane receives the admitted patch and never re-validates it, so this section owns the transition algebra and not the admission it composes.
- Law: deep transition rebuilds nested identity when a shallow swap replays cached, mutable, or session-owned state — a composite owner's transition replaces the inner owner through its own kernel and the outer owner through `copy.replace`, so a stale nested map, cursor, or session is never carried forward by a top-level field swap.
- Law: a `frozendict` field transitions through union (`row | {key: value}`), a `Map`/`Block` field through its persistent combinator, and the whole successor is one expression; aliases normalize before replacement and never key an owner replacement.
- Reject: a mutable field on a frozen owner, a direct `__replace__` where `copy.replace` states the transition, mutate-then-freeze, a shallow nested-dict update, cached-session replay by shallow replace, a second `TypeAdapter` pass over the already-admitted patch, and `MappingProxyType` as durable immutability.

```python conceptual
from copy import replace
from dataclasses import dataclass, field
from typing import Literal, NotRequired, ReadOnly, Required, Self, TypedDict

from builtins import frozendict
from expression import Error, Ok, Result, case, tag, tagged_union


@tagged_union(frozen=True)
class ReplaceFault:
    tag: Literal["stale", "empty_key"] = tag()
    stale: tuple[int, int] = case()
    empty_key: None = case()


class ShapePatch(TypedDict, closed=True):
    expected_version: Required[ReadOnly[int]]
    key: NotRequired[ReadOnly[str]]
    labels: NotRequired[ReadOnly[frozendict[str, str]]]


@dataclass(frozen=True, slots=True, kw_only=True)
class Cursor:
    offset: int
    epoch: int

    def rewound(self, epoch: int, /) -> Self:
        return replace(self, offset=0, epoch=epoch)


@dataclass(frozen=True, slots=True, kw_only=True)
class Shape:
    key: str
    version: int = 1
    labels: frozendict[str, str] = field(default_factory=frozendict)
    cursor: Cursor = field(default_factory=lambda: Cursor(offset=0, epoch=0))

    def advanced(self, patch: ShapePatch, /) -> Result[Self, ReplaceFault]:
        match patch:
            case {"expected_version": stale} if stale != self.version:
                return Error(ReplaceFault(stale=(stale, self.version)))
            case {"key": ""}:
                return Error(ReplaceFault(empty_key=None))
            case _:
                return Ok(
                    replace(
                        self,
                        key=patch.get("key", self.key),
                        version=self.version + 1,
                        labels=self.labels | patch.get("labels", frozendict()),
                        cursor=self.cursor.rewound(self.version + 1),
                    )
                )
```
