#!/usr/bin/env python3
# /// script
# requires-python = ">=3.13"
# dependencies = ["cyclopts", "msgspec", "pydantic"]
# ///
# ruff: noqa: T201
"""Deterministic conformance gate over durable artifact instances."""

# --- [RUNTIME_PRELUDE] -------------------------------------------------------------------

from collections import defaultdict
from collections.abc import Iterable, Sequence
from enum import StrEnum
from pathlib import Path
import re
import sys
from typing import Annotated, Literal, TypedDict

from cyclopts import App, Parameter
import msgspec
from pydantic import BaseModel, ConfigDict, Field, TypeAdapter, ValidationError


# --- [TYPES] -----------------------------------------------------------------------------

type Status = Literal["ok", "warn", "fail"]


class Check(StrEnum):
    """Closed finding vocabulary."""

    COLLECT = "collect"
    ENTRY_FLOOR = "entry-floor"
    FIELD_DUPLICATE = "field-duplicate"
    FIELD_REQUIRED = "field-required"
    FIELD_VOCAB = "field-vocab"
    FILENAME = "filename"
    FOLD_BACK = "fold-back"
    HEADER = "header"
    HEADING_CENSUS = "heading-census"
    ID_ORDINAL = "id-ordinal"
    ID_REFERENCE = "id-reference"
    ID_TOMBSTONE = "id-tombstone"
    KIND = "kind"
    LEADER_ID = "leader-id"
    LEADER_UNIQUE = "leader-unique"
    LEADER_VOCAB = "leader-vocab"
    MARK_VOCAB = "mark-vocab"
    READ = "read"
    SECTION_COVERAGE = "section-coverage"
    SECTION_DUPLICATE = "section-duplicate"
    SECTION_EMPTY = "section-empty"
    SECTION_SPAN = "section-span"
    SEMANTIC_REVIEW = "semantic-review"
    SLOT_RESIDUE = "slot-residue"
    TABLE_HEADER = "table-header"
    TABLE_INDEX = "table-index"
    TEMPLATE = "template"
    WARGAME_CRITERIA = "wargame-criteria"
    WARGAME_SCORE = "wargame-score"
    WARGAME_TOTAL = "wargame-total"


type ArtifactKind = Literal["decision-record", "direction-set", "roadmap-brief", "blindspot-ledger", "capability-entry"]


class EntryDraft(TypedDict):
    line: int
    section: str
    identity: str
    tokens: tuple[str, ...]
    title: str
    fields: list[dict[str, object]]


class SectionDraft(TypedDict):
    line: int
    number: int
    token: str
    bullets: list[dict[str, object]]
    entries: list[EntryDraft]


# --- [CONSTANTS] -------------------------------------------------------------------------

SKILL_ROOT = Path(__file__).resolve().parent.parent
AXES_PAGE = SKILL_ROOT / "references" / "axes.md"
TEMPLATE_DIR = SKILL_ROOT / "templates"

BRACKET_TOKEN = re.compile(r"\[([A-Z0-9_]+)(?::([A-Z]?\d{2,}))?\]")
BULLET = re.compile(r"^- (?P<name>[A-Z][A-Za-z-]*): (?P<value>\S.*)$")
CODE_SPAN = re.compile(r"`+[^`]*`+")
ENTRY = re.compile(r"^- \[(?P<id>[^\]]+)\](?:-\[(?P<a>[^\]]+)\])?(?:-\[(?P<b>[^\]]+)\])?:\s*(?P<title>.*)$")
FENCE = re.compile(r"^(?P<indent> *)(?P<marker>`{3,}|~{3,})(?P<info>.*)$")
FIELD = re.compile(r"^  - (?P<name>[A-Z][A-Za-z-]*): (?P<value>\S.*)$")
H1 = re.compile(r"^# \[(?P<title>.+)\]\s*$")
HEADING = re.compile(r"^## \[(?P<number>\d{2})\]-\[(?P<token>[A-Z0-9_]+)\]\s*$")
ID = re.compile(r"^(?P<prefix>[A-Z]?)(?P<ordinal>\d{2,})$")
MARK_LEAD = re.compile(r"^\[(?P<token>[A-Z0-9_]+)\]")
MARK_SLOT = re.compile(r"^\[<(?P<label>[A-Z_]+)>\]")
SLOT = re.compile(r"<[A-Za-z][A-Za-z0-9|]*(?:[-_][A-Za-z0-9|<>]+)*>")
TABLE_SPLIT = re.compile(r"^\|(?P<body>.*)\|\s*$")
VOCAB_LINE = re.compile(r"^\[(?P<label>[A-Z_]+)\]:(?P<body>.+)$")
VOCAB_TOKEN = re.compile(r"`\[(?P<token>[A-Z0-9_]+)(?P<tail>:<id>)?\]`")

REPEATABLE_FIELDS = frozenset({"Anchor", "Rejected", "Route"})
WARGAME_TOTAL_TOLERANCE = 0.05
SEMANTIC_PATTERNS: tuple[tuple[re.Pattern[str], str], ...] = (
    (re.compile(r"\b(probably|maybe|could also|depending on|might)\b", re.IGNORECASE), "hedged ruling language"),
    (re.compile(r"\bweek\s+\d+|\bQ[1-4]\b|\b\d{4}-\d{2}-\d{2}\b", re.IGNORECASE), "dated horizon or plan residue"),
    (re.compile(r"\bnone\b", re.IGNORECASE), "empty gap claim needs cold-read proof"),
)
ROW_ENCODER = msgspec.json.Encoder()


# --- [MODELS] ----------------------------------------------------------------------------


class Row(msgspec.Struct, frozen=True, gc=False):
    """One emitted conformance row."""

    file: str
    line: int
    check: Check
    status: Status
    detail: str


class KindRule(msgspec.Struct, frozen=True, gc=False):
    """One artifact kind's whole gate row; a new kind lands as one row here plus its template.

    `header` names a required `[LABEL]:` document line whose tokens must resolve in the mint
    sections' leader vocabulary; `empty_with_header` names sections legally empty when that
    line carries a nonempty `clean:` tail — required-field optionality stays semantic, so it
    lives here rather than deriving from the template's full field census.
    """

    kind: ArtifactKind
    suffix: str
    floor: int
    mint: frozenset[str]
    required: dict[str, frozenset[str]]
    reference: frozenset[str] = frozenset()
    optional: frozenset[str] = frozenset()
    header: str | None = None
    empty_with_header: frozenset[str] = frozenset()


REGISTRY: tuple[KindRule, ...] = (
    KindRule(
        kind="decision-record",
        suffix="DECISIONS",
        floor=1,
        mint=frozenset({"RECORDS"}),
        required={"RECORDS": frozenset({"Context", "Drivers", "Options", "Ruling", "Consequence", "Confirmation"})},
    ),
    KindRule(
        kind="direction-set",
        suffix="DIRECTIONS",
        floor=2,
        mint=frozenset({"DIRECTIONS"}),
        required={"DIRECTIONS": frozenset({"Thesis", "Cost", "Kills", "Reversibility", "Evidence", "Confidence"})},
        reference=frozenset({"WARGAME", "RULING"}),
        optional=frozenset({"WARGAME"}),
    ),
    KindRule(
        kind="roadmap-brief",
        suffix="ROADMAP",
        floor=1,
        mint=frozenset({"NOW", "NEXT", "LATER"}),
        required={
            "NOW": frozenset({"Why", "Bet", "Measure", "Confidence"}),
            "NEXT": frozenset({"Why", "Bet", "Measure", "Promote"}),
            "LATER": frozenset({"Why", "Promote"}),
        },
    ),
    KindRule(
        kind="blindspot-ledger",
        suffix="BLINDSPOTS",
        floor=0,
        mint=frozenset({"FINDINGS"}),
        required={"FINDINGS": frozenset({"Anchor", "Consequence", "Fold-back", "Route"})},
        header="AXES",
        empty_with_header=frozenset({"FINDINGS"}),
    ),
    KindRule(
        kind="capability-entry",
        suffix="CAPABILITIES",
        floor=1,
        mint=frozenset({"ENTRIES"}),
        required={"ENTRIES": frozenset({"Owner", "Edges", "Importance", "Gaps"})},
    ),
)
RULES: dict[ArtifactKind, KindRule] = {rule.kind: rule for rule in REGISTRY}
KIND_BY_SUFFIX: dict[str, ArtifactKind] = {rule.suffix: rule.kind for rule in REGISTRY}


class SourceLine(BaseModel):
    """One content line outside fenced blocks."""

    model_config = ConfigDict(frozen=True)

    number: int
    text: str


class FieldLine(BaseModel):
    """One field under an entry."""

    model_config = ConfigDict(frozen=True)

    line: int
    name: str
    value: str


class Entry(BaseModel):
    """One leader and its owned fields."""

    model_config = ConfigDict(frozen=True)

    line: int
    section: str
    identity: str
    tokens: tuple[str, ...] = ()
    title: str = ""
    fields: tuple[FieldLine, ...] = ()


class Section(BaseModel):
    """One heading span."""

    model_config = ConfigDict(frozen=True)

    line: int
    number: int
    token: str
    bullets: tuple[FieldLine, ...] = ()
    entries: tuple[Entry, ...] = ()


class TemplateContract(BaseModel):
    """Template-derived contract for one artifact kind."""

    model_config = ConfigDict(frozen=True)

    kind: ArtifactKind
    sections: tuple[str, ...]
    optional: frozenset[str] = frozenset()
    fields: dict[str, frozenset[str]] = Field(default_factory=dict)
    leaders: dict[str, dict[str, bool]] = Field(default_factory=dict)
    marks: dict[str, dict[str, bool]] = Field(default_factory=dict)
    bullets: dict[str, frozenset[str]] = Field(default_factory=dict)
    required: dict[str, frozenset[str]] = Field(default_factory=dict)


class Document(BaseModel):
    """Parsed instance document."""

    model_config = ConfigDict(frozen=True)

    path: Path
    h1_line: int
    h1_title: str
    kind: ArtifactKind
    lines: tuple[SourceLine, ...]
    sections: tuple[Section, ...]


# --- [OPERATIONS] ------------------------------------------------------------------------


def row(path: Path, line: int, check: Check, status: Status, detail: str) -> Row:
    return Row(file=str(path), line=line, check=check, status=status, detail=detail)


def closed_by(fence: tuple[str, int], match: re.Match[str] | None) -> bool:
    return bool(match and match.group("marker")[0] == fence[0] and len(match.group("marker")) >= fence[1] and not match.group("info").strip())


def content_lines(text: str) -> tuple[SourceLine, ...]:
    admitted: list[dict[str, object]] = []
    fence: tuple[str, int] | None = None
    for number, raw in enumerate(text.splitlines(), 1):
        match = FENCE.match(raw)
        if match and fence is None:
            fence = (match.group("marker")[0], len(match.group("marker")))
            continue
        if fence is not None:
            if closed_by(fence, match):
                fence = None
            continue
        admitted.append({"number": number, "text": raw})
    return tuple(TypeAdapter(list[SourceLine]).validate_python(admitted))


def read(path: Path) -> str | Row:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        return row(path, 0, Check.READ, "fail", type(exc).__name__)


def template_kind(line: SourceLine) -> ArtifactKind | None:
    match = H1.match(line.text)
    return KIND_BY_SUFFIX.get(match.group("title").rsplit("_", 1)[-1]) if match else None


def headings(lines: Iterable[SourceLine]) -> tuple[tuple[int, int, str], ...]:
    return tuple((line.number, int(match.group("number")), match.group("token")) for line in lines if (match := HEADING.match(line.text)))


def schema_for(kind: ArtifactKind, path: Path) -> TemplateContract | Row:
    text = read(TEMPLATE_DIR / f"{kind}.md")
    if isinstance(text, Row):
        return row(path, 0, Check.TEMPLATE, "fail", text.detail)
    template = content_lines(text)
    named = {
        vocab.group("label"): {token.group("token"): bool(token.group("tail")) for token in VOCAB_TOKEN.finditer(vocab.group("body"))}
        for line in template
        if (vocab := VOCAB_LINE.match(line.text))
    }
    fields: dict[str, set[str]] = defaultdict(set)
    bullets: dict[str, set[str]] = defaultdict(set)
    marks: dict[str, dict[str, bool]] = {}
    mark_names: set[str] = set()
    section = ""
    for line in template:
        if heading := HEADING.match(line.text):
            section = heading.group("token")
        elif section and (field := FIELD.match(line.text)):
            fields[section].add(field.group("name"))
            if (slot := MARK_SLOT.match(field.group("value"))) and slot.group("label") in named:
                marks[field.group("name")] = named[slot.group("label")]
                mark_names.add(slot.group("label"))
        elif section and (bullet := BULLET.match(line.text)):
            bullets[section].add(bullet.group("name"))
    leader_tokens = {label: tokens for label, tokens in named.items() if label not in mark_names}
    leaders: dict[str, dict[str, bool]] = {section_token: {} for _, _, section_token in headings(template)}
    for section_token in leaders:
        leaders[section_token] = {token: requires_id for tokens in leader_tokens.values() for token, requires_id in tokens.items()}
    if kind == "blindspot-ledger" and AXES_PAGE.is_file():
        axis_text = read(AXES_PAGE)
        if not isinstance(axis_text, Row):
            leaders["FINDINGS"].update({token: False for _, _, token in headings(content_lines(axis_text))})
    return TemplateContract(
        kind=kind,
        sections=tuple(token for _, _, token in headings(template)),
        optional=RULES[kind].optional,
        fields={key: frozenset(value) for key, value in fields.items()},
        leaders=leaders,
        marks=marks,
        bullets={key: frozenset(value) for key, value in bullets.items()},
        required=RULES[kind].required,
    )


def parse(path: Path, text: str) -> Document | list[Row]:
    lines = content_lines(text)
    first = next((line for line in lines if line.text.strip()), None)
    if first is None:
        return [row(path, 1, Check.KIND, "fail", "no content lines")]
    h1 = H1.match(first.text)
    kind = template_kind(first)
    if h1 is None or kind is None:
        return [row(path, first.number, Check.KIND, "fail", "first content line does not resolve to a template kind")]
    headings_index = {line: (number, token) for line, number, token in headings(lines)}
    sections: list[SectionDraft] = []
    current: SectionDraft | None = None
    current_entry: EntryDraft | None = None
    for line in lines:
        if line.number in headings_index:
            number, token = headings_index[line.number]
            current = {"line": line.number, "number": number, "token": token, "bullets": [], "entries": []}
            sections.append(current)
            current_entry = None
            continue
        if current is None:
            continue
        if match := BULLET.match(line.text):
            current["bullets"].append({"line": line.number, "name": match.group("name"), "value": match.group("value")})
            current_entry = None
        elif match := ENTRY.match(line.text):
            current_entry = {
                "line": line.number,
                "section": current["token"],
                "identity": match.group("id"),
                "tokens": tuple(token for token in (match.group("a"), match.group("b")) if token),
                "title": match.group("title"),
                "fields": [],
            }
            current["entries"].append(current_entry)
        elif current_entry is not None and (field := FIELD.match(line.text)):
            current_entry["fields"].append({"line": line.number, "name": field.group("name"), "value": field.group("value")})
    try:
        return TypeAdapter(Document).validate_python({
            "path": path,
            "h1_line": first.number,
            "h1_title": h1.group("title"),
            "kind": kind,
            "lines": lines,
            "sections": sections,
        })
    except ValidationError as exc:
        return [
            row(path, first.number, Check.KIND, "fail", f"document admission failed: {err['loc']} {err['msg']}")
            for err in exc.errors(include_url=False)
        ]


def filename_rows(document: Document) -> tuple[Row, ...]:
    pattern = re.compile(rf"^{re.escape(document.kind)}\.[a-z0-9][a-z0-9-]*(?:\.[a-z0-9][a-z0-9-]*)?\.md$")
    return (
        ()
        if pattern.fullmatch(document.path.name)
        else (row(document.path, 0, Check.FILENAME, "fail", f"{document.path.name} must match <kind>.<scope>[.<slug>].md for {document.kind}"),)
    )


def heading_rows(document: Document, contract: TemplateContract) -> tuple[Row, ...]:
    got = [(section.line, section.number, section.token) for section in document.sections]
    tokens = [token for _, _, token in got]
    present = set(tokens)
    anchor = got[0][0] if got else document.h1_line
    duplicate_rows = [
        row(document.path, line, Check.SECTION_DUPLICATE, "fail", f"[{token}] duplicates an earlier section")
        for index, (line, _, token) in enumerate(got)
        if token in tokens[:index]
    ]
    required_rows = [
        row(document.path, anchor, Check.HEADING_CENSUS, "fail", f"missing section [{token}]")
        for token in contract.sections
        if token not in present and token not in contract.optional
    ]
    unknown_rows = [
        row(document.path, line, Check.HEADING_CENSUS, "fail", f"unknown section [{token}]")
        for line, _, token in got
        if token not in contract.sections
    ]
    order = [token for token in contract.sections if token in present]
    order_rows = (
        []
        if [token for token in tokens if token in contract.sections] == order
        else [row(document.path, anchor, Check.HEADING_CENSUS, "fail", f"sections {tokens} out of template order")]
    )
    number_rows = [
        row(document.path, line, Check.HEADING_CENSUS, "fail", f"number [{number:02d}] out of sequence, expected [{index:02d}]")
        for index, (line, number, _) in enumerate(got, 1)
        if number != index
    ]
    exempt = RULES[document.kind].empty_with_header if header_clean(document) else frozenset()
    empty_rows = [
        row(document.path, section.line, Check.SECTION_EMPTY, "fail", f"[{section.token}] has no bullets or entries")
        for section in document.sections
        if section.token in contract.sections and section.token not in exempt and not section.bullets and not section.entries
    ]
    return (*duplicate_rows, *required_rows, *unknown_rows, *order_rows, *number_rows, *empty_rows)


def header_line(document: Document) -> tuple[SourceLine, str] | None:
    label = RULES[document.kind].header
    if label is None:
        return None
    return next(((line, match.group("body")) for line in document.lines if (match := re.match(rf"^\[{label}\]: (?P<body>\S.*)$", line.text))), None)


def header_clean(document: Document) -> bool:
    found = header_line(document)
    return found is not None and bool(re.search(r"\bclean: *[A-Z][A-Z0-9_]*", found[1]))


def header_rows(document: Document, contract: TemplateContract) -> tuple[Row, ...]:
    rule = RULES[document.kind]
    if rule.header is None:
        return ()
    found = header_line(document)
    if found is None:
        return (row(document.path, document.h1_line, Check.HEADER, "fail", f"missing [{rule.header}]: line"),)
    line, body = found
    vocabulary = {token for section in rule.mint for token in contract.leaders.get(section, {})}
    return tuple(
        row(document.path, line.number, Check.HEADER, "fail", f"[{token}] outside the [{rule.header}] vocabulary")
        for token in re.findall(r"[A-Z][A-Z0-9_]*", body)
        if token not in vocabulary
    )


def leader_rows(document: Document, contract: TemplateContract) -> tuple[Row, ...]:
    # Two passes: mint every id first, then resolve references — supersession points forward.
    rows: list[Row] = []
    rule = RULES[document.kind]
    minted: dict[str, Entry] = {}
    minted_prefix: str | None = None
    minted_order: list[tuple[int, int]] = []
    parsed = [(section.token, entry, ID.fullmatch(entry.identity)) for section in document.sections for entry in section.entries]
    for token, entry, match in parsed:
        if match is None or int(match.group("ordinal")) == 0:
            rows.append(row(document.path, entry.line, Check.LEADER_ID, "fail", f"[{entry.identity}] outside the id grammar"))
        elif token in rule.mint:
            if entry.identity in minted:
                rows.append(
                    row(
                        document.path,
                        entry.line,
                        Check.LEADER_UNIQUE,
                        "fail",
                        f"[{entry.identity}] already minted at line {minted[entry.identity].line}",
                    )
                )
            minted.setdefault(entry.identity, entry)
            minted_order.append((entry.line, int(match.group("ordinal"))))
            if minted_prefix is None:
                minted_prefix = match.group("prefix")
            elif minted_prefix != match.group("prefix"):
                rows.append(row(document.path, entry.line, Check.ID_ORDINAL, "fail", f"[{entry.identity}] prefix drifts inside the instance"))
    for token, entry, match in parsed:
        if match is None or int(match.group("ordinal")) == 0:
            continue
        if token in rule.reference and entry.identity not in minted:
            rows.append(row(document.path, entry.line, Check.ID_REFERENCE, "fail", f"[{entry.identity}] references no minted entry"))
        allowed = contract.leaders.get(token, {})
        for leader in entry.tokens:
            name, _, tail = leader.partition(":")
            requires_id = allowed.get(name)
            valid = requires_id is not None and ((tail in minted) if requires_id else not tail)
            if not valid:
                rows.append(
                    row(document.path, entry.line, Check.LEADER_VOCAB, "fail", f"[{leader}] outside declared vocabulary or unresolved id tail")
                )
        if entry.tokens and entry.tokens[0].startswith("SUPERSEDED:"):
            successor = entry.tokens[0].partition(":")[2]
            if successor not in minted or successor == entry.identity:
                rows.append(row(document.path, entry.line, Check.ID_TOMBSTONE, "fail", f"[{entry.tokens[0]}] names no distinct minted successor"))
    for (line, ordinal), wanted in zip(minted_order, range(1, len(minted_order) + 1), strict=True):
        if ordinal != wanted:
            rows.append(row(document.path, line, Check.ID_ORDINAL, "fail", f"minted ordinal {ordinal:02d} expected {wanted:02d} in instance order"))
    return tuple(rows)


def field_rows(document: Document, contract: TemplateContract) -> tuple[Row, ...]:
    rows: list[Row] = []
    for section in document.sections:
        declared = contract.fields.get(section.token, frozenset()) | contract.bullets.get(section.token, frozenset())
        rows.extend(
            row(document.path, bullet.line, Check.FIELD_VOCAB, "fail", f"field {bullet.name} outside [{section.token}] vocabulary")
            for bullet in section.bullets
            if declared and bullet.name not in declared
        )
        rows.extend(
            row(document.path, section.line, Check.FIELD_REQUIRED, "fail", f"[{section.token}] missing bullet {name}")
            for name in sorted(contract.bullets.get(section.token, frozenset()) - {bullet.name for bullet in section.bullets})
        )
        for entry in section.entries:
            rows.extend(entry_field_rows(document.path, section.token, entry, contract, declared))
    return tuple(rows)


def entry_field_rows(path: Path, section: str, entry: Entry, contract: TemplateContract, declared: frozenset[str]) -> tuple[Row, ...]:
    by_name: dict[str, list[FieldLine]] = defaultdict(list)
    rows: list[Row] = []
    for field in entry.fields:
        by_name[field.name].append(field)
        rows.extend(field_vocab_rows(path, section, field, contract, declared))
    rows.extend(
        row(path, entry.line, Check.FIELD_REQUIRED, "fail", f"[{entry.identity}] missing field {name}")
        for name in contract.required.get(section, frozenset())
        if name not in by_name
    )
    rows.extend(
        row(path, repeats[1].line, Check.FIELD_DUPLICATE, "fail", f"{name} repeats inside [{entry.identity}]")
        for name, repeats in by_name.items()
        if len(repeats) > 1 and name not in REPEATABLE_FIELDS
    )
    return tuple(rows)


def field_vocab_rows(path: Path, section: str, field: FieldLine, contract: TemplateContract, declared: frozenset[str]) -> tuple[Row, ...]:
    rows = (
        [row(path, field.line, Check.FIELD_VOCAB, "fail", f"field {field.name} outside [{section}] vocabulary")]
        if declared and field.name not in declared
        else []
    )
    if (allowed := contract.marks.get(field.name)) is not None:
        lead = MARK_LEAD.match(field.value)
        if lead is None or lead.group("token") not in allowed:
            rows.append(row(path, field.line, Check.MARK_VOCAB, "fail", f"{field.name} value lacks a declared leading mark"))
    return tuple(rows)


def slot_rows(document: Document) -> tuple[Row, ...]:
    return tuple(
        row(document.path, line.number, Check.SLOT_RESIDUE, "fail", match.group(0))
        for line in document.lines
        for match in SLOT.finditer(CODE_SPAN.sub(" ", line.text))
    )


def table_rows(document: Document) -> tuple[Row, ...]:
    rows: list[Row] = []
    lines = document.lines
    for index, line in enumerate(lines[:-1]):
        header = TABLE_SPLIT.match(line.text)
        divider = TABLE_SPLIT.match(lines[index + 1].text)
        if header is None or divider is None or not set(divider.group("body").replace("|", "").strip()) <= {":", "-", " "}:
            continue
        cells = [cell.strip() for cell in header.group("body").split("|")]
        if "[INDEX]" not in cells:
            rows.append(row(document.path, line.number, Check.TABLE_INDEX, "fail", "table header lacks [INDEX]"))
        rows.extend(
            row(document.path, line.number, Check.TABLE_HEADER, "fail", f"header {cell} is not bracketed uppercase")
            for cell in cells
            if not re.fullmatch(r"\[[A-Z0-9_]+\]", cell)
        )
    return tuple(rows)


def wargame_rows(document: Document) -> tuple[Row, ...]:
    if document.kind != "direction-set":
        return ()
    directions = {entry.identity for section in document.sections if section.token == "DIRECTIONS" for entry in section.entries}
    wargame = next((section for section in document.sections if section.token == "WARGAME"), None)
    if wargame is None:
        return ()
    criteria = next((bullet for bullet in wargame.bullets if bullet.name == "Criteria"), None)
    tokens = BRACKET_TOKEN.findall(criteria.value) if criteria else []
    weights = [float(match.group(1)) for match in re.finditer(r"\[[A-Z0-9_]+\]:(\d+(?:\.\d+)?)", criteria.value if criteria else "")]
    rows = [
        row(document.path, criteria.line if criteria else wargame.line, Check.WARGAME_CRITERIA, "fail", "criteria tokens repeat")
        for values in ([token for token, _ in tokens],)
        if len(values) != len(set(values))
    ]
    score_ids = {entry.identity for entry in wargame.entries}
    rows.extend(
        row(document.path, wargame.line, Check.SECTION_COVERAGE, "fail", f"[DIRECTIONS] entry [{identity}] has no [WARGAME] score row")
        for identity in sorted(directions - score_ids)
    )
    rows.extend(
        row(document.path, entry.line, Check.SECTION_COVERAGE, "fail", f"[WARGAME] score row [{entry.identity}] matches no [DIRECTIONS] entry")
        for entry in wargame.entries
        if entry.identity not in directions
    )
    for entry in wargame.entries:
        numbers = [float(value) for value in re.findall(r"(?<!\[)\b\d+(?:\.\d+)?\b(?!\])", entry.title)]
        scores = numbers[:-1] if "=" in entry.title else numbers
        if len(scores) != len(weights):
            rows.append(row(document.path, entry.line, Check.WARGAME_SCORE, "fail", f"{len(scores)} scores for {len(weights)} criteria"))
            continue
        if numbers and weights:
            total = numbers[-1]
            weighted = sum(score * weight for score, weight in zip(scores, weights, strict=True))
            if abs(total - weighted) > WARGAME_TOTAL_TOLERANCE:
                rows.append(row(document.path, entry.line, Check.WARGAME_TOTAL, "fail", f"total {total:g} does not match weighted {weighted:g}"))
    return tuple(rows)


def semantic_rows(document: Document) -> tuple[Row, ...]:
    return tuple(
        row(document.path, line.number, Check.SEMANTIC_REVIEW, "warn", detail)
        for line in document.lines
        for pattern, detail in SEMANTIC_PATTERNS
        if pattern.search(CODE_SPAN.sub(" ", line.text))
    )


def landing_rows(document: Document) -> tuple[Row, ...]:
    if document.kind != "blindspot-ledger":
        return ()
    rows: list[Row] = []
    for section in document.sections:
        for entry in section.entries:
            fields = {field.name: field for field in entry.fields}
            for name in ("Fold-back", "Route"):
                field = fields.get(name)
                if field is None or SLOT.search(field.value) or field.value.lower().startswith(("none", "n/a")):
                    rows.append(
                        row(
                            document.path,
                            entry.line if field is None else field.line,
                            Check.FOLD_BACK,
                            "fail",
                            f"[{entry.identity}] needs concrete {name}",
                        )
                    )
    return tuple(rows)


def kind_rows(document: Document) -> tuple[Row, ...]:
    entry_count = sum(len(section.entries) for section in document.sections if section.token in RULES[document.kind].mint)
    floor = RULES[document.kind].floor
    span = {
        token
        for section in document.sections
        if document.kind == "direction-set" and section.token == "DIRECTIONS"
        for entry in section.entries
        for token in entry.tokens[:1]
    }
    return (
        *(
            []
            if entry_count >= floor
            else [row(document.path, document.h1_line, Check.ENTRY_FLOOR, "fail", f"{document.kind} carries {entry_count} entries, minimum {floor}")]
        ),
        *(
            []
            if document.kind != "direction-set" or len(span) >= 2
            else [row(document.path, document.h1_line, Check.SECTION_SPAN, "fail", f"[DIRECTIONS] spans {len(span)} distinct tiers, minimum 2")]
        ),
    )


def validate(path: Path) -> tuple[Row, ...]:
    """Return every conformance row for one instance path."""
    if is_skill_corpus_non_instance(path):
        return ()
    text = read(path)
    if isinstance(text, Row):
        return (text,)
    parsed = parse(path, text)
    if isinstance(parsed, list):
        return tuple(parsed)
    contract = schema_for(parsed.kind, path)
    if isinstance(contract, Row):
        return (contract,)
    return tuple(
        rows
        for group in (
            filename_rows(parsed),
            heading_rows(parsed, contract),
            header_rows(parsed, contract),
            slot_rows(parsed),
            leader_rows(parsed, contract),
            field_rows(parsed, contract),
            table_rows(parsed),
            kind_rows(parsed),
            wargame_rows(parsed),
            landing_rows(parsed),
            semantic_rows(parsed),
        )
        for rows in group
    )


def is_skill_corpus_non_instance(path: Path) -> bool:
    try:
        inside_skill = path.resolve().is_relative_to(SKILL_ROOT)
    except OSError:
        inside_skill = False
    return inside_skill and not any(
        re.fullmatch(rf"{re.escape(kind)}\.[a-z0-9][a-z0-9-]*(?:\.[a-z0-9][a-z0-9-]*)?\.md", path.name) for kind in KIND_BY_SUFFIX.values()
    )


def collect(paths: Sequence[str]) -> tuple[Path | Row, ...]:
    found: list[Path | Row] = []
    for raw in paths:
        path = Path(raw)
        found.append(path if path.is_file() and path.suffix == ".md" else row(path, 0, Check.COLLECT, "fail", "not a readable markdown file"))
    return tuple(found)


def emit(record: Row, json_mode: bool) -> None:
    if json_mode:
        print(ROW_ENCODER.encode(record).decode())
    else:
        print(f"{record.file}:{record.line}: {record.status.upper()} {record.check.value} {record.detail}")


def exit_code(rows: Iterable[Row]) -> int:
    return 1 if any(record.status == "fail" for record in rows) else 0


def scan(path: Path) -> list[Row]:
    """Compatibility surface for tests that expect a mutable row list.

    Returns:
        Conformance rows as a list.
    """
    return list(validate(path))


# --- [COMPOSITION] -----------------------------------------------------------------------

app = App(result_action="return_int_as_exit_code_else_zero")


@app.default
def command(*paths: str, json: Annotated[bool, Parameter(negative="")] = False) -> int:
    records = tuple(
        item if isinstance(item, Row) else rows for item in collect(paths) for rows in ((item,) if isinstance(item, Row) else validate(item))
    )
    for record in records:
        emit(record, json)
    return exit_code(records)


def main(argv: list[str] | None = None) -> int:
    """Execute the Cyclopts app.

    Returns:
        Process exit code.
    """
    result = app(argv)
    return result if isinstance(result, int) else 0


# --- [EXPORTS] ---------------------------------------------------------------------------

__all__ = ["Check", "Document", "KindRule", "Row", "TemplateContract", "main", "scan", "validate"]


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
