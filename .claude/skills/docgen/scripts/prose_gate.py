#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.13"
# dependencies = ["cyclopts", "msgspec"]
# ///
# ruff: noqa: T201, D100, D101, D103

# --- [RUNTIME_PRELUDE] -------------------------------------------------------------------

from collections.abc import Iterable
from enum import StrEnum
from pathlib import Path
import re
import sys
from typing import Literal

from cyclopts import App
import msgspec


# --- [TYPES] -----------------------------------------------------------------------------

type Status = Literal["ok", "warn", "fail"]
type Align = Literal["center", "left", "right", "none"]


class Check(StrEnum):
    BOLD_EMPHASIS = "bold-emphasis"
    COLLECT = "collect"
    DEAD_RELATIVE_LINK = "dead-relative-link"
    FENCE_GEOMETRY = "fence-geometry"
    FENCE_LANGUAGE = "fence-language"
    FENCE_UNCLOSED = "fence-unclosed"
    HEADING_H1 = "heading-h1"
    HEADING_ORDER = "heading-order"
    HEDGE = "hedge"
    LIST_BLOAT = "list-bloat"
    LIST_LEADER = "list-leader"
    META_PHRASE = "meta-phrase"
    READ = "read"
    SELF_COUNT = "self-count"
    SETEXT_HEADING = "setext-heading"
    TABLE_ALIGN = "table-align"
    TABLE_CELL = "table-cell"
    TABLE_HEADER = "table-header"
    TABLE_INDEX = "table-index"
    TABLE_SHAPE = "table-shape"
    TEMPLATE_SLOT = "template-slot"
    TRAILING_WHITESPACE = "trailing-whitespace"
    VERSION_ANCHOR = "version-anchor"


# --- [CONSTANTS] -------------------------------------------------------------------------

CAP = 150
CELL_BUDGET = 160
LIST_CHAR_CAP = 500
LIST_SENTENCE_CAP = 3
ROSTER_SPAN_SHARE = 0.6
APP = App(help="Gate durable markdown prose.")
ENCODER = msgspec.json.Encoder()

BOLD = re.compile(r"(?<!\*)\*\*(?=\S)(.+?)(?<=\S)\*\*(?!\*)|(?<!_)__(?=\S)(.+?)(?<=\S)__(?!_)")
CARD_ROW = re.compile(r"^\s*-\s+`[^`]+`\s+-\s+")
EXAMPLE_LINE = re.compile(
    r"^\s*(?:>\s*)?(?:[-+*]|\d+[.)])?\s*(?:Detection|Rejected|Accepted|Near miss|Banned|Survivors|Reason|Reframe)"
    r"(?:\s*\([^)]*\))?:"
)
FENCE = re.compile(r"^(?P<indent> {0,3})(?P<marker>`{3,}|~{3,})(?P<info>.*)$")
GLYPHS = ("│", "├", "└", "⇄")
HEADER_CELL = re.compile(r"^\[[A-Z][A-Z0-9_]*\]$")
HEADING = re.compile(r"^(?P<level>#{1,6})\s+(?P<title>.+?)\s*$")
LIST_ITEM = re.compile(r"^(?P<indent>\s*)(?:[-+*]|\d+[.)])\s+(?P<body>\S.*)$")
LIST_LEADER = re.compile(r"^\s*(?:[-+*]|\d+[.)])\s+\[(?:\d{2}(?:-[A-Z0-9_]+)?|[A-Z0-9_]+|[OX!~ ])\](?:\s+[—-]|[-:]\s*|:)")
LINK = re.compile(r"(?<!!)\[([^\]\n]+)\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
NUMBERED_SECTION = re.compile(r"^\[(?P<n>\d{2})\]-\[(?P<token>[A-Z][A-Z0-9_]*)\]$")
PLACEHOLDER = re.compile(r"<[a-z][a-z0-9]*(?:[-_][a-z0-9]+)+>")
SENTENCE_END = re.compile(r"[.!?](?:\s|$)")
SETEXT = re.compile(r"^\s*(?:=+|-{3,})\s*$")
TABLE_SEP = re.compile(r"^\s*\|(?:\s*:?-+:?\s*\|)+\s*$")
YAML_KEY = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*\s*:")

HEDGE_PHRASE = re.compile(
    r"\b(?:is\s+expected\s+to|can\s+be|aims\s+to|is\s+designed\s+to|in\s+the\s+future|eventually|as\s+needed|if\s+necessary)\b", re.IGNORECASE
)
HEDGE_WORDS = re.compile(
    r"\b(should|could|would|might|maybe|perhaps|likely|probably|propose|consider|recommended|ideally|experimental|we|our|you)\b", re.IGNORECASE
)
MARKER_WORDS = re.compile(r"\b(TBD|TODO|FIXME)\b", re.IGNORECASE)
META_PHRASE = re.compile(
    r"\b(?:this\s+document|this\s+file\s+describes|this\s+page\s+describes|as\s+mentioned\s+above|as\s+described\s+above"
    r"|note\s+that|it\s+is\s+worth|in\s+this\s+section|the\s+following\s+sections|as\s+of\s+20|per\s+research"
    r"|at\s+the\s+time\s+of\s+writing)\b",
    re.IGNORECASE,
)
SELF_COUNT = re.compile(
    r"(?:^|[.!?]\s+)(Two|Three|Four|Five|Six|Seven|Eight|Nine|Ten|Eleven|Twelve|Thirteen|Fourteen|Fifteen|Sixteen"
    r"|Seventeen|Eighteen|Nineteen|Twenty|\d+)\s+(named\s+)?(classes|laws|rules|sections|types|axes|fields|modes"
    r"|tests|checks|steps|entries|forms|tiers|bands|devices|archetypes|templates|references|tables|diagrams|cards"
    r"|rows|columns|tokens|markers|vocabularies)\b"
)
VERSION_ANCHOR = re.compile(r"\bv?\d+\.\d+(?:\.\d+)+\b|\b\d+\.\d+(?:\.\d+)?\+|\bv\d+\.\d+\b")
PATTERNS: tuple[tuple[Check, re.Pattern[str]], ...] = (
    (Check.HEDGE, HEDGE_WORDS),
    (Check.HEDGE, MARKER_WORDS),
    (Check.HEDGE, HEDGE_PHRASE),
    (Check.META_PHRASE, META_PHRASE),
    (Check.SELF_COUNT, SELF_COUNT),
    (Check.VERSION_ANCHOR, VERSION_ANCHOR),
)


# --- [MODELS] ----------------------------------------------------------------------------


class Row(msgspec.Struct, frozen=True):
    file: str
    line: int
    check: Check
    status: Status
    detail: str


class Span(msgspec.Struct, frozen=True):
    line: int
    text: str


class Table(msgspec.Struct, frozen=True):
    line: int
    headers: tuple[str, ...]
    aligns: tuple[Align, ...]
    rows: tuple[tuple[str, ...], ...]


class Heading(msgspec.Struct, frozen=True):
    line: int
    level: int
    title: str


class LinkRef(msgspec.Struct, frozen=True):
    line: int
    target: str


class ListEntry(msgspec.Struct, frozen=True):
    line: int
    text: str
    prose: str
    span_share: float


class Document(msgspec.Struct, frozen=True):
    path: str
    template: bool
    prose: tuple[Span, ...]
    tables: tuple[Table, ...]
    headings: tuple[Heading, ...]
    links: tuple[LinkRef, ...]
    lists: tuple[ListEntry, ...]


# --- [OPERATIONS] ------------------------------------------------------------------------


def row(path: Path | str, line: int, check: Check, status: Status, detail: str) -> Row:
    return Row(file=str(path), line=line, check=check, status=status, detail=detail)


def collect(paths: tuple[Path, ...]) -> tuple[tuple[Path, ...], tuple[Row, ...]]:
    files: list[Path] = []
    faults: list[Row] = []
    for target in paths:
        if target.is_dir():
            found = tuple(sorted(target.rglob("*.md")))
            files.extend(found)
            if not found:
                faults.append(row(target, 0, Check.COLLECT, "fail", "directory holds no markdown"))
        elif target.suffix == ".md" and target.is_file():
            files.append(target)
        else:
            faults.append(row(target, 0, Check.COLLECT, "fail", "not a readable markdown file"))
    return tuple(dict.fromkeys(files)), tuple(faults)


def frontmatter_end(lines: tuple[str, ...]) -> int:
    if not lines or lines[0].rstrip() != "---":
        return 0
    for number, line in enumerate(lines[1:], 2):
        if line.rstrip() == "---":
            return number if any(YAML_KEY.match(body) for body in lines[1 : number - 1]) else 0
    return 0


def split_cells(line: str) -> tuple[str, ...]:
    cells: list[str] = []
    current: list[str] = []
    escaped = False
    for char in line.strip().strip("|"):
        if escaped:
            current.append(char)
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == "|":
            cells.append("".join(current).strip())
            current = []
        else:
            current.append(char)
    cells.append("".join(current).strip())
    return tuple(cells)


def aligned(cell: str) -> Align:
    left, right = cell.startswith(":"), cell.endswith(":")
    return "center" if left and right else "left" if left else "right" if right else "none"


def prose_spans(line: str, number: int) -> tuple[Span, ...]:
    pieces: list[str] = []
    index = 0
    while index < len(line):
        link = LINK.match(line, index)
        if link:
            pieces.append(link.group(1))
            index = link.end()
            continue
        if line[index] == "`":
            width = len(line[index:]) - len(line[index:].lstrip("`"))
            end = line.find("`" * width, index + width)
            index = end + width if end >= 0 else index + 1
            continue
        pieces.append(line[index])
        index += 1
    text = "".join(pieces)
    return (Span(number, text),) if text.strip() else ()


def read(path: Path) -> str | Row:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        return row(path, 0, Check.READ, "fail", type(exc).__name__)


def lex(path: Path, text: str, cap: int) -> tuple[Document | None, tuple[Row, ...]]:
    raw = tuple(text.splitlines())
    skip_until = frontmatter_end(raw)
    prose: list[Span] = []
    tables: list[Table] = []
    headings: list[Heading] = []
    links: list[LinkRef] = []
    lists: list[ListEntry] = []
    rows: list[Row] = []
    fence: tuple[str, int, int, str] | None = None
    n = 0
    while n < len(raw):
        number, line = n + 1, raw[n]
        if line.endswith((" ", "\t")):
            rows.append(row(path, number, Check.TRAILING_WHITESPACE, "fail", "line ends with space or tab"))
        if number <= skip_until:
            n += 1
            continue
        matched = FENCE.match(line)
        if fence is None and matched:
            marker, info = matched.group("marker"), matched.group("info").strip()
            if not info:
                rows.append(row(path, number, Check.FENCE_LANGUAGE, "fail", "opening fence has no language tag"))
            fence = (marker[0], len(marker), number, info.lower())
            n += 1
            continue
        if fence is not None:
            glyph, width, _start, info = fence
            if matched and matched.group("marker")[0] == glyph and len(matched.group("marker")) >= width and not matched.group("info").strip():
                fence = None
            elif ("codemap" in info or "seams" in info or any(glyph in line for glyph in GLYPHS)) and len(line) > cap:
                rows.append(row(path, number, Check.FENCE_GEOMETRY, "fail", f"line {len(line)} > cap {cap}"))
            n += 1
            continue
        if path.name == "README.md" and CARD_ROW.match(line) and len(line) > cap:
            rows.append(row(path, number, Check.FENCE_GEOMETRY, "fail", f"card row {len(line)} > cap {cap}"))
        if heading := HEADING.match(line):
            headings.append(Heading(number, len(heading.group("level")), heading.group("title")))
        if SETEXT.match(line) and n > 0 and raw[n - 1].strip() and not TABLE_SEP.match(line):
            rows.append(row(path, number, Check.SETEXT_HEADING, "fail", "setext heading marker"))
        if line.lstrip().startswith("|") and n + 1 < len(raw) and TABLE_SEP.match(raw[n + 1]):
            headers = split_cells(line)
            aligns = tuple(aligned(cell) for cell in split_cells(raw[n + 1]))
            body: list[tuple[str, ...]] = []
            cursor = n + 2
            while cursor < len(raw) and raw[cursor].lstrip().startswith("|"):
                body.append(split_cells(raw[cursor]))
                cursor += 1
            tables.append(Table(number, headers, aligns, tuple(body)))
            n = cursor
            continue
        links.extend(LinkRef(number, link.group(2)) for link in LINK.finditer(line))
        if item := LIST_ITEM.match(line):
            cursor = n + 1
            chunks = [item.group("body")]
            while cursor < len(raw) and raw[cursor].startswith((" ", "\t")) and not LIST_ITEM.match(raw[cursor]):
                chunks.append(raw[cursor].strip())
                cursor += 1
            text = " ".join(chunks)
            stripped = " ".join(span.text.strip() for span in prose_spans(text, number))
            share = 1 - (len(stripped) / max(1, len(text.strip())))
            lists.append(ListEntry(number, text, stripped, share))
        if not line.lstrip().startswith("|"):
            prose.extend(prose_spans(line, number))
        n += 1
    if fence is not None:
        rows.append(row(path, fence[2], Check.FENCE_UNCLOSED, "fail", "opening fence has no closing fence"))
    doc = Document(str(path), "templates" in path.parts, tuple(prose), tuple(tables), tuple(headings), tuple(links), tuple(lists))
    return doc, tuple(rows)


def table_rows(doc: Document) -> tuple[Row, ...]:
    rows: list[Row] = []
    for table in doc.tables:
        sep_line = table.line + 1
        indexed = bool(table.headers) and table.headers[0] == "[INDEX]"
        rows.extend(row(doc.path, table.line, Check.TABLE_HEADER, "fail", cell or "<empty>") for cell in table.headers if not HEADER_CELL.match(cell))
        if len(table.aligns) != len(table.headers):
            rows.append(
                row(doc.path, sep_line, Check.TABLE_ALIGN, "fail", f"separator cells {len(table.aligns)} != header cells {len(table.headers)}")
            )
        rows.extend(
            row(doc.path, sep_line, Check.TABLE_ALIGN, "fail", f"column {position} carries no explicit alignment colon")
            for position, align in enumerate(table.aligns, 1)
            if align == "none"
        )
        for index, body in enumerate(table.rows, 1):
            if len(body) != len(table.headers):
                rows.append(
                    row(doc.path, table.line + index + 1, Check.TABLE_SHAPE, "fail", f"row cells {len(body)} != header cells {len(table.headers)}")
                )
        if len(table.rows) >= 2 and not indexed:
            rows.append(row(doc.path, table.line, Check.TABLE_INDEX, "fail", "enumerable table lacks leading [INDEX]"))
        if indexed:
            if table.aligns and table.aligns[0] != "center":
                rows.append(row(doc.path, sep_line, Check.TABLE_INDEX, "fail", f"[INDEX] column is {table.aligns[0]}-aligned, not centered"))
            for index, body in enumerate(table.rows, 1):
                expected = f"[{index:02}]"
                actual = body[0] if body else "<empty>"
                if actual.strip() != expected:
                    rows.append(row(doc.path, table.line + index + 1, Check.TABLE_INDEX, "fail", f"{actual or '<empty>'} != {expected}"))
        rows.extend(
            row(
                doc.path,
                table.line + index + 1,
                Check.TABLE_CELL,
                "warn",
                f"prose-crammed cell ({len(cell)} chars); rows stay atomic, nuance moves to prose",
            )
            for index, body in enumerate(table.rows, 1)
            for cell in body
            if len(cell) > CELL_BUDGET
        )
    return tuple(rows)


def heading_rows(doc: Document) -> tuple[Row, ...]:
    if doc.template:
        return ()
    rows: list[Row] = []
    h1 = tuple(heading for heading in doc.headings if heading.level == 1)
    rows.extend(row(doc.path, heading.line, Check.HEADING_H1, "fail", "duplicate H1") for heading in h1[1:])
    expected = 1
    for heading in (heading for heading in doc.headings if heading.level == 2):
        matched = NUMBERED_SECTION.match(heading.title)
        if not matched:
            rows.append(row(doc.path, heading.line, Check.HEADING_ORDER, "fail", heading.title))
            continue
        actual = int(matched.group("n"))
        if actual != expected:
            rows.append(row(doc.path, heading.line, Check.HEADING_ORDER, "fail", f"{actual:02} != {expected:02}"))
        expected = actual + 1
    return tuple(rows)


def link_rows(doc: Document) -> tuple[Row, ...]:
    if doc.template:
        return ()
    base = Path(doc.path).parent
    rows: list[Row] = []
    for link in doc.links:
        target = link.target.split("#", 1)[0]
        if not target or target == "path" or re.match(r"^[a-z][a-z0-9+.-]*:", target, re.IGNORECASE):
            continue
        if not (base / target).resolve(strict=False).exists():
            rows.append(row(doc.path, link.line, Check.DEAD_RELATIVE_LINK, "fail", link.target))
    return tuple(rows)


def prose_rows(doc: Document) -> tuple[Row, ...]:
    rows: list[Row] = []
    for span in doc.prose:
        if EXAMPLE_LINE.match(span.text):
            continue
        if not doc.template:
            rows.extend(row(doc.path, span.line, Check.TEMPLATE_SLOT, "fail", hit.group(0)) for hit in PLACEHOLDER.finditer(span.text))
        rows.extend(row(doc.path, span.line, Check.BOLD_EMPHASIS, "fail", hit.group(0)) for hit in BOLD.finditer(span.text))
        rows.extend(
            row(doc.path, span.line, check, "fail", hit.group(0).lstrip(".!? ")) for check, pattern in PATTERNS for hit in pattern.finditer(span.text)
        )
    return tuple(rows)


def list_rows(doc: Document) -> tuple[Row, ...]:
    if doc.template:
        return ()
    rows: list[Row] = []
    for entry in doc.lists:
        if entry.text.startswith("[") and not LIST_LEADER.match(f"- {entry.text}"):
            rows.append(row(doc.path, entry.line, Check.LIST_LEADER, "fail", entry.text.split(":", 1)[0]))
        if entry.span_share < ROSTER_SPAN_SHARE:
            sentences = len(SENTENCE_END.findall(entry.prose))
            if sentences > LIST_SENTENCE_CAP:
                rows.append(row(doc.path, entry.line, Check.LIST_BLOAT, "warn", f"{sentences} sentences > cap {LIST_SENTENCE_CAP}"))
            elif len(entry.text) > LIST_CHAR_CAP:
                rows.append(row(doc.path, entry.line, Check.LIST_BLOAT, "warn", f"entry {len(entry.text)} chars > cap {LIST_CHAR_CAP}"))
    return tuple(rows)


def scan(path: Path, cap: int) -> tuple[Row, ...]:
    text = read(path)
    if isinstance(text, Row):
        return (text,)
    doc, lexer_rows = lex(path, text, cap)
    return lexer_rows if doc is None else lexer_rows + table_rows(doc) + heading_rows(doc) + link_rows(doc) + prose_rows(doc) + list_rows(doc)


def emit(rows: Iterable[Row], json_mode: bool) -> None:
    for finding in rows:
        if json_mode:
            print(ENCODER.encode(finding).decode())
        else:
            print(f"{finding.file}:{finding.line}: {finding.status.upper()} {finding.check} {finding.detail}")


def code(rows: Iterable[Row]) -> int:
    return 1 if any(finding.status == "fail" for finding in rows) else 0


# --- [ENTRY] -----------------------------------------------------------------------------


@APP.default
def run(*paths: Path, json: bool = False, cap: int = CAP) -> int:
    files, faults = collect(paths)
    rows = faults + tuple(finding for path in files for finding in scan(path, cap))
    emit(rows, json)
    return code(rows)


if __name__ == "__main__":
    sys.exit(APP(sys.argv[1:], result_action="return_value"))
