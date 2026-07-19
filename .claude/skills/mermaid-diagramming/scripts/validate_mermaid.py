#!/usr/bin/env python3
# /// script
# requires-python = ">=3.15"
# dependencies = ["cyclopts", "defusedxml", "msgspec", "networkx", "svgelements", "xxhash"]
# ///
"""Validate Mermaid fences through typed source analysis, SVG render proof, rendered-geometry legibility, and browserless raster proof."""

# ruff: noqa: T201, D101, D103

# --- [RUNTIME_PRELUDE] ------------------------------------------------------------------

import base64
from collections import Counter
from collections.abc import Callable, Iterable
from contextlib import suppress
from enum import StrEnum
from itertools import pairwise
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
from tempfile import mkdtemp, TemporaryDirectory
import time
from typing import Literal, TYPE_CHECKING

from cyclopts import App
from defusedxml.ElementTree import fromstring, ParseError
import msgspec
import networkx as nx
from svgelements import Path as SvgPath  # type: ignore[import-untyped]  # ty: ignore[unresolved-import]  # untyped, no py.typed stub
from xxhash import xxh3_128_hexdigest


if TYPE_CHECKING:
    from xml.etree.ElementTree import Element


# --- [TYPES] ----------------------------------------------------------------------------

type Status = Literal["ok", "warn", "fail"]


class Check(StrEnum):
    COLLECT = "collect"
    CONTRACT = "contract"
    EXPORT = "export"
    FRONTMATTER = "frontmatter"
    LEGIBILITY = "legibility"
    LOGIC = "logic"
    PROOF = "proof"
    READ = "read"
    RENDER = "render"
    SETUP = "setup"


class Family(StrEnum):
    ARCHITECTURE = "architecture"
    C4 = "c4"
    CLASS = "class"
    ER = "er"
    FLOWCHART = "flowchart"
    GANTT = "gantt"
    REQUIREMENT = "requirement"
    SEQUENCE = "sequence"
    STATE = "state"
    UNKNOWN = "unknown"


# --- [CONSTANTS] ------------------------------------------------------------------------

APP = App(name="validate-mermaid")
ENCODER = msgspec.json.Encoder()
ENV_MARKERS = ("chrome", "chromium", "puppeteer", "browser", "libnss", "sandbox", "econnrefused", "enoent")
# Version-pinned fallback renderer: proves whether a syntax failure survives a known-good release.
CACHE_TTL = 3600  # seconds; the gitignored render cache stays ephemeral — every run drops entries older than this before rendering
RELEASE_RENDERER = ("pnpm", "dlx", "@mermaid-js/mermaid-cli@11.16.0")
RENDER_TIMEOUT = 120
SUFFIXES = frozenset({".md", ".mmd"})

ACCESS = re.compile(r"^\s*(accTitle|accDescr)(?:\s*:|\s*\{)")
BACKING_FLAT = re.compile(r"(edgeLabelBackground|relationLabelBackground)\s*:\s*[\"']?#282A36\b", re.IGNORECASE)
BLOCKQUOTE = re.compile(r"^\s*(?:>\s?)+")
FONT_BARE = re.compile(r"fontFamily\s*:\s*[\"']?monospace[\"']?\s*$", re.MULTILINE)
FONT_HYPHEN = re.compile(r"fontFamily\s*:\s*[\"']?[^\"'\n]*\w-\w")
CLASS_ASSIGN = re.compile(r"^\s*class\s+([\w,\s.-]+?)\s+([\w,-]+)\s*;?\s*$")
CLASS_DEF = re.compile(r"^\s*classDef\s+([\w,-]+)\s+(.+)$")
DEPRECATED_INIT = re.compile(r"%%\{\s*init\s*:")
ER_RELATION = re.compile(r"^\s*([\w-]+)\s*[|o}{]{2}[-.]{2}[|o}{]{2}\s*([\w-]+)\s*:")
FC_EDGE = re.compile(r"([<ox]?[-=.~]{2,}[>ox]?(?:\|[^|]*\|)?)")
FC_EDGE_ID = re.compile(r"(\w+)@(?=[-=.~<])")
FC_MID_LABEL = re.compile(r"(<?)(--|==|-\.)\s+((?:(?!--|==|\.-)[^|\n])+?)\s+(-{2,}[>ox]?|={2,}[>ox]?|\.-+[>ox]?)")
FC_SHAPE = re.compile(
    r"(\[\[.*?\]\]|\[\(.*?\)\]|\(\(.*?\)\)|\(\[.*?\]\)|\{\{.*?\}\}|\[/.*?/\]|\[\\.*?\\\]|(?<![-=<>])>[^\]]*\]|\[.*?\]|\(.*?\)|\{.*?\})"
)
FC_SKIP = re.compile(r"^\s*(subgraph\b|end\b|direction\b|classDef\b|linkStyle\b|style\b|click\b|class\b|accTitle|accDescr)")
FC_STR = re.compile(r'("[^"]*"|`[^`]*`)')
FENCE_OPEN = re.compile(r"^((?:\s*>)*\s*)(`{3,}|~{3,})\s*mermaid\b")
HEX_COLOR = re.compile(r"#[0-9A-Fa-f]{8}\b|#[0-9A-Fa-f]{6}\b")
IDENT = re.compile(r"[A-Za-z0-9_]+")
LINK_STYLE = re.compile(r"^\s*linkStyle\s+([0-9,\s]+|default)\s+(.+)$")
SQ_ARROW = re.compile(r"^\s*([\w-]*\w)\s*(?:<<--?>>|--?(?:>>|>|\)|x))\s*[+-]?\s*([\w-]*\w)\s*:")
SQ_PARTICIPANT = re.compile(r"^(?:create\s+)?(?:participant|actor)\s+([\w-]+)(?:@\{.*\})?(?:\s+as\s+.+)?\s*$")
ST_TRANSITION = re.compile(r"^\s*(\[\*\]|[\w.]+)\s*-->\s*(\[\*\]|[\w.]+)")
ACCENT_OPAQUE = re.compile(r"fill:#(?:50FA7B|8BE9FD|FFB86C|FFD866|FF5555|BD93F9|FF79C6)(?![0-9A-Fa-f]{2})", re.IGNORECASE)
PADDING_22 = re.compile(r"padding:\s*22\b")
STATE_START_STALE = re.compile(r"state-start\{r:(?!3\.4px)")
TERMINAL_STALE = re.compile(r"scale\(\.64\)")
YELLOW_DARK_LINE = re.compile(r"fill:#FFD866[0-9A-Fa-f]{0,2}\b(?=[^\n]*color:#282A36)", re.IGNORECASE)
YELLOW_DARK_TAG = re.compile(r"tagLabelBackground\s*:\s*[\"']?#FFD866", re.IGNORECASE)
YELLOW_DARK_TAG_INK = re.compile(r"tagLabelColor\s*:\s*[\"']?#282A36", re.IGNORECASE)
YELLOW_DARK_NOTE = re.compile(r"noteBkgColor\s*:\s*[\"']?#FFD866", re.IGNORECASE)
YELLOW_DARK_NOTE_INK = re.compile(r"noteTextColor\s*:\s*[\"']?#282A36", re.IGNORECASE)
CLUSTER_TITLE = re.compile(r"cluster-label[^{}]*\{(?![^{}]*font-size:13\.5px)[^{}]*\}")
SECTION_TITLE = re.compile(r"\.sectionTitle\{(?![^{}]*font-size:13\.5px)[^{}]*\}")
MARKER_CIRCLE_STALE = re.compile(r"\.marker circle\{(?![^{}]*scale\(\.48\))[^{}]*transform[^{}]*\}")
THEME_BASE = re.compile(r"^\s*theme\s*:\s*base\s*$", re.MULTILINE)
LOOK_CLASSIC = re.compile(r"^\s*look\s*:\s*classic\s*$", re.MULTILINE)
GRADIENT_KILL = re.compile(r"^\s*useGradient\s*:\s*false\s*$", re.MULTILINE)
SHADOW_KILL = re.compile(r"^\s*dropShadow\s*:", re.MULTILINE)

# Refusal probe on the workspace 11.16.0 binary: block/mindmap/sankey/venn refuse accTitle/accDescr at parse, kanban/ishikawa render the
# directives as content, timeline/eventmodeling accept them inert with no aria output — none earns an acc-missing warn.
ACC_EXEMPT = frozenset({
    "block",
    "block-beta",
    "eventmodeling",
    "ishikawa-beta",
    "kanban",
    "mindmap",
    "sankey",
    "sankey-beta",
    "timeline",
    "venn-beta",
})
# Timeline and eventmodeling parse the directives yet emit no aria output, so a fence carrying them claims accessibility it never delivers.
ACC_INERT = frozenset({"eventmodeling", "timeline"})
CANVAS = "#282A36"
# A semantic rail is chosen by the relation an edge encodes — its label — never the names of the nodes it joins; an invisible ~~~ rank pin
# is layout furniture and never a semantic edge. Word-boundary prefixes keep `default` off the fault vocabulary.
FAULT_LABEL = re.compile(r"\b(fault|error|reject)", re.IGNORECASE)
RAIL_LABEL = re.compile(r"\b(fault|error|reject|trace|data|wire|external|receipt)", re.IGNORECASE)
TRANSFORM_BOX_RULE = re.compile(r"[^{}]+\{[^{}]*transform-box:fill-box[^{}]*\}")
CANON = frozenset({
    "primary",
    "boundary",
    "success",
    "error",
    "external",
    "data",
    "payload",
    "recessed",
    "annotation",
    "edgeSuccess",
    "edgeError",
    "edgeExternal",
    "edgeData",
    "edgeControl",
    "edgeTrace",
})
PALETTE = frozenset({
    "#036A96",
    "#14710A",
    "#1F1F1F",
    "#21222C",
    "#282A36",
    "#44475A",
    "#50FA7B",
    "#6272A4",
    "#644AC9",
    "#6C664B",
    "#846E15",
    "#8BE9FD",
    "#A3144D",
    "#A34D14",
    "#BD93F9",
    "#CB3A2A",
    "#CFCFDE",
    "#D6BCFA",
    "#F8F8F2",
    "#FF5555",
    "#FF79C6",
    "#FFB86C",
    "#FFD866",
    "#FFFBEB",
})
ENGINE_HOOKS = frozenset({"#444444"})
FILL_ALPHAS = frozenset({"", "1A", "26", "33", "4D", "54", "66", "80", "BF"})
RENDER_CONFIG = {
    "theme": "base",
    # Root htmlLabels false renders flowchart/state/class/ER labels as native SVG text (probe-verified on 11.16.0, <br/> line breaks
    # included), so the one canonical SVG rasterizes browserlessly with no label loss; families on their own label path ignore the key.
    "htmlLabels": False,
    "deterministicIds": True,
    "deterministicIDSeed": "mermaid-corpus",
    "handDrawnSeed": 1001,
    "architecture": {"randomize": False, "seed": 1001},
    "flowchart": {"defaultRenderer": "elk"},
}

# Geometry legibility: the g.node/path model families ELK and dagre both render; sequence/gantt/quantitative carry inherent crossings and are exempt.
GEOM_FAMILIES = frozenset({Family.FLOWCHART, Family.STATE, Family.ER, Family.CLASS})
GEOM_EDGE_CLASS = ("flowchart-link", "transition", "edge-thickness", "relation")
GEOM_LABEL_TOK = frozenset({"label", "nodelabel", "edgelabel", "cluster-label"})
GEOM_SAMPLES = 12
TRANSLATE = re.compile(r"translate\(\s*([-\d.eE]+)[ ,]+([-\d.eE]+)")
MATRIX = re.compile(r"matrix\(\s*(?:[-\d.eE]+[ ,]+){4}([-\d.eE]+)[ ,]+([-\d.eE]+)")


def _browser_path() -> str | None:
    """Resolve a pinned headless-shell binary; never an .app bundle, which LaunchServices registers and aborts at _RegisterApplication when headless.

    Returns:
        Path to a pinned chrome-headless-shell binary, or None when none resolves.
    """
    env = os.environ.get("PUPPETEER_EXECUTABLE_PATH", "")
    if env and ".app/" not in env and Path(env).is_file():
        return env
    by_revision = lambda p: [int(n) for n in re.findall(r"\d+", p.parts[-3])]  # noqa: E731
    shells = sorted(
        Path.home().glob(".cache/puppeteer/chrome-headless-shell/*/chrome-headless-shell-*/chrome-headless-shell"), key=by_revision
    ) or sorted(
        Path("/nix/store").glob("*-playwright-browsers/chromium_headless_shell-*/chrome-headless-shell-*/chrome-headless-shell"), key=by_revision
    )
    return str(shells[-1]) if shells else None


PUPPETEER_CONFIG = {
    # Shell headless mode plus a bare non-bundle binary keeps every render crash silent (no ReportCrash dialog); breakpad off drops the crash
    # handler entirely. Throwaway-profile render never touches the macOS keychain: mock-keychain and the basic password store kill the
    # "Chrome Safe Storage" prompt.
    "headless": "shell",
    # FontationsFontBackend off routes web-font shaping back through CoreText, shedding the fontations-attributed share of the benign
    # macOS-26 teardown traps (SIGTRAP in Chromium's Rust region after a successful render; RustyPng has no runtime switch since M142).
    "args": [
        "--no-sandbox",
        "--disable-dev-shm-usage",
        "--disable-breakpad",
        "--disable-features=FontationsFontBackend",
        "--use-mock-keychain",
        "--password-store=basic",
    ],
    **({"executablePath": _path} if (_path := _browser_path()) else {}),
}
# A stale session env can still carry an .app-bundle pin that puppeteer honors over its cache; the render subprocess drops it so the config
# executablePath (or a clean renderer error) is the only launch route.
RENDER_ENV = {k: v for k, v in os.environ.items() if not (k == "PUPPETEER_EXECUTABLE_PATH" and ".app/" in v)}
THEMED = frozenset({
    "architecture-beta",
    "block",
    "block-beta",
    "kanban",
    "packet",
    "packet-beta",
    "treeView-beta",
    "classDiagram",
    "cynefin-beta",
    "erDiagram",
    "eventmodeling",
    "flowchart",
    "gantt",
    "gitGraph",
    "graph",
    "ishikawa-beta",
    "journey",
    "pie",
    "quadrantChart",
    "radar-beta",
    "railroad-abnf-beta",
    "railroad-beta",
    "railroad-ebnf-beta",
    "railroad-peg-beta",
    "requirementDiagram",
    "sankey",
    "sankey-beta",
    "sequenceDiagram",
    "stateDiagram",
    "stateDiagram-v2",
    "swimlane-beta",
    "timeline",
    "treemap",
    "treemap-beta",
    "venn-beta",
    "wardley-beta",
    "xychart",
    "xychart-beta",
})


# --- [MODELS] ---------------------------------------------------------------------------


class Row(msgspec.Struct, frozen=True):
    file: str
    line: int
    check: Check
    status: Status
    detail: str


class Fence(msgspec.Struct, frozen=True):
    file: str
    line: int
    body: str
    unclosed: bool = False


class LinkStyle(msgspec.Struct, frozen=True):
    line: str
    indices: tuple[int, ...]
    style: str
    default: bool = False


class ClassDef(msgspec.Struct, frozen=True):
    name: str
    style: str


class ClassUse(msgspec.Struct, frozen=True):
    target: str
    name: str


class Edge(msgspec.Struct, frozen=True):
    index: int
    source: str
    target: str
    token: str
    label: str
    ident: str = ""


class Diagram(msgspec.Struct, frozen=True):
    fence: Fence
    family: Family
    header: str
    frontmatter: str
    lines: tuple[str, ...]
    edges: tuple[Edge, ...]
    links: tuple[LinkStyle, ...]
    defs: tuple[ClassDef, ...]
    uses: tuple[ClassUse, ...]
    containers: tuple[str, ...]


# --- [OPERATIONS] -----------------------------------------------------------------------


def emit(row: Row, json_mode: bool) -> None:
    print(ENCODER.encode(row).decode() if json_mode else f"{row.file}:{row.line}: {row.status.upper()} {row.check.value} {row.detail}")


def exit_code(rows: Iterable[Row]) -> int:
    return 1 if any(row.status == "fail" for row in rows) else 0


def row(fence: Fence, check: Check, status: Status, detail: str) -> Row:
    return Row(file=fence.file, line=fence.line, check=check, status=status, detail=detail)


def collect(paths: tuple[Path, ...]) -> tuple[tuple[Path, ...], tuple[Row, ...]]:
    files: list[Path] = []
    rows: list[Row] = []
    for path in paths:
        if path.is_dir():
            found = sorted(child for child in path.rglob("*") if child.suffix in SUFFIXES and child.is_file())
            files.extend(found)
            if not found:
                rows.append(Row(str(path), 0, Check.COLLECT, "fail", "empty target directory"))
        elif path.suffix in SUFFIXES and path.is_file():
            files.append(path)
        else:
            rows.append(Row(str(path), 0, Check.COLLECT, "fail", "not a markdown or mmd target"))
    return tuple(dict.fromkeys(files)), tuple(rows)


def read_fences(path: Path) -> tuple[tuple[Fence, ...], tuple[Row, ...]]:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        return (), (Row(str(path), 0, Check.READ, "fail", type(exc).__name__),)
    if path.suffix == ".mmd":
        return ((Fence(str(path), 1, text),) if text.strip() else ()), ()
    out: list[Fence] = []
    lines = text.splitlines()
    index = 0
    while index < len(lines):
        opened = FENCE_OPEN.match(lines[index])
        if opened is None:
            index += 1
            continue
        quoted = ">" in opened.group(1)
        marker = re.escape(opened.group(2)[0])
        closed_by = re.compile(rf"^(?:\s*>)*\s*{marker}{{{len(opened.group(2))},}}\s*$")
        body: list[str] = []
        cursor = index + 1
        while cursor < len(lines) and closed_by.match(lines[cursor]) is None:
            body.append(BLOCKQUOTE.sub("", lines[cursor]) if quoted else lines[cursor])
            cursor += 1
        out.append(Fence(str(path), index + 2, "\n".join(body), cursor == len(lines)))
        index = cursor + 1
    return tuple(out), ()


def family(header: str) -> Family:
    if header in {"flowchart", "graph"} or header.startswith("swimlane"):
        return Family.FLOWCHART
    if header.startswith("stateDiagram"):
        return Family.STATE
    if header == "sequenceDiagram":
        return Family.SEQUENCE
    if header == "erDiagram":
        return Family.ER
    if header == "classDiagram":
        return Family.CLASS
    if header == "gantt":
        return Family.GANTT
    if header == "architecture-beta":
        return Family.ARCHITECTURE
    if header == "requirementDiagram":
        return Family.REQUIREMENT
    if header.startswith("C4"):
        return Family.C4
    return Family.UNKNOWN


def frontmatter(body: str) -> tuple[str, tuple[str, ...], tuple[Row, ...]]:
    lines = body.splitlines()
    if not lines or lines[0].strip() != "---":
        return "", tuple(lines), ()
    close = next((index for index, line in enumerate(lines[1:], 1) if line.strip() == "---"), -1)
    if close < 0:
        return "", (), (Row("-", 0, Check.LOGIC, "fail", "unclosed-frontmatter"),)
    return "\n".join(lines[1:close]), tuple(lines[close + 1 :]), ()


def body_lines(lines: tuple[str, ...]) -> tuple[str, tuple[str, ...]]:
    body = tuple(line for line in lines if line.strip() and not line.strip().startswith("%%"))
    if not body:
        return "", ()
    return body[0].strip().split()[0], tuple(line for line in body[1:] if ACCESS.match(line) is None and not line.strip().startswith("title "))


def class_rows(lines: tuple[str, ...]) -> tuple[tuple[ClassDef, ...], tuple[ClassUse, ...]]:
    defs: list[ClassDef] = []
    uses: list[ClassUse] = []
    for line in lines:
        if match := CLASS_DEF.match(line):
            defs.extend(ClassDef(name, match.group(2)) for name in match.group(1).split(","))
        for target, names in re.findall(r"([\w.-]+)\"?:::([\w,-]+)", line):
            uses.extend(ClassUse(target, name) for name in names.split(","))
        if match := CLASS_ASSIGN.match(line):
            targets = [part for part in re.split(r"[\s,]+", match.group(1)) if part]
            uses.extend(ClassUse(target, name) for target in targets for name in match.group(2).split(","))
    return tuple(defs), tuple(uses)


def link_rows(lines: tuple[str, ...]) -> tuple[LinkStyle, ...]:
    out: list[LinkStyle] = []
    for line in lines:
        if match := LINK_STYLE.match(line):
            raw = match.group(1).strip()
            out.append(
                LinkStyle(
                    line,
                    () if raw == "default" else tuple(int(part) for part in raw.replace(" ", "").split(",") if part),
                    match.group(2),
                    raw == "default",
                )
            )
    return tuple(out)


def strip_metadata(line: str) -> str:
    # Node-shape metadata keeps its id; edge-behavior metadata (animate/animation/curve) erases whole.
    return re.sub(
        r"(\w+)@\{[^}]*\}", lambda m: m.group(1) if re.search(r"\b(shape|icon|img|label|pos|form|constraint)\s*:", m.group(0)) else " ", line
    )


def flow_edges(lines: tuple[str, ...]) -> tuple[Edge, ...]:
    edges: list[Edge] = []
    for raw in lines:
        if FC_SKIP.match(raw):
            continue
        line = strip_metadata(raw)
        idents = FC_EDGE_ID.findall(line)
        line = FC_EDGE_ID.sub("", FC_STR.sub(lambda m: "Q" + re.sub(r"[^A-Za-z0-9]", "", m.group(0)), line))
        line = FC_MID_LABEL.sub(lambda m: f"{m.group(1)}{m.group(2)}{m.group(4)}|{m.group(3)}|", line)
        parts = FC_EDGE.split(FC_SHAPE.sub(" ", line))
        groups = [IDENT.findall(part) for part in parts[::2]]
        tokens = parts[1::2]
        nodes = [group for group in groups if group]
        ident = idents[0] if len(idents) == 1 and len(tokens) == 1 else ""
        for offset, (left, right) in enumerate(pairwise(nodes)):
            token = tokens[offset] if offset < len(tokens) else "-->"
            label = token.strip("|").strip() if "|" in token else ""
            edges.extend(Edge(len(edges), a, b, token, label, ident) for a in left for b in right)
    return tuple(edges)


def containers(lines: tuple[str, ...]) -> tuple[str, ...]:
    return tuple(line.strip() for line in lines if re.match(r"^(subgraph|alt\b|par\b|critical\b|break\b|state\s+[\w.]+\s*\{)", line.strip()))


def parse(fence: Fence) -> tuple[Diagram | None, tuple[Row, ...]]:
    if fence.unclosed:
        return None, (row(fence, Check.LOGIC, "fail", "unclosed-fence"),)
    fm, source, faults = frontmatter(fence.body)
    faults = tuple(Row(fence.file, fence.line, fault.check, fault.status, fault.detail) for fault in faults)
    header, lines = body_lines(source)
    defs, uses = class_rows(lines)
    diagram = Diagram(fence, family(header), header, fm, lines, flow_edges(lines), link_rows(lines), defs, uses, containers(lines))
    return diagram, faults


def contract(diagram: Diagram) -> tuple[Row, ...]:
    body = diagram.fence.body
    access = [line.strip().split(":", 1)[0].split("{", 1)[0].strip() for line in body.splitlines() if ACCESS.match(line)]
    off_palette = sorted({
        value
        for value in (hex_value.upper() for hex_value in HEX_COLOR.findall(body))
        if (value[:7] not in PALETTE or value[7:] not in FILL_ALPHAS) and value not in ENGINE_HOOKS
    })
    defs = {definition.name: definition for definition in diagram.defs}
    used = {use.name for use in diagram.uses}
    rows = [row(diagram.fence, Check.FRONTMATTER, "warn", "no-frontmatter")] if not body.startswith("---") else []
    rows += [row(diagram.fence, Check.CONTRACT, "warn", "deprecated-init-directive")] if DEPRECATED_INIT.search(body) else []
    rows += [row(diagram.fence, Check.CONTRACT, "warn", "acc-order")] if access and access[:2] != ["accTitle", "accDescr"] else []
    rows += [row(diagram.fence, Check.CONTRACT, "warn", "acc-pair-incomplete")] if ("accTitle" in body) != ("accDescr" in body) else []
    rows += [row(diagram.fence, Check.CONTRACT, "warn", "acc-missing")] if not access and diagram.header and diagram.header not in ACC_EXEMPT else []
    rows += [row(diagram.fence, Check.CONTRACT, "warn", "acc-inert")] if access and diagram.header in ACC_INERT else []
    rows += [row(diagram.fence, Check.CONTRACT, "warn", f"off-palette:{value}") for value in off_palette]
    rows += (
        [row(diagram.fence, Check.CONTRACT, "warn", "floor:theme-base")]
        if diagram.header in THEMED and not THEME_BASE.search(diagram.frontmatter)
        else []
    )
    rows += (
        [
            row(diagram.fence, Check.CONTRACT, "warn", f"floor:{name}")
            for name, pattern in (("look-classic", LOOK_CLASSIC), ("use-gradient", GRADIENT_KILL), ("drop-shadow", SHADOW_KILL))
            if not pattern.search(diagram.frontmatter)
        ]
        if diagram.header in THEMED
        else []
    )
    rows += (
        [row(diagram.fence, Check.CONTRACT, "warn", "floor:fontFamily")]
        if diagram.header in THEMED and "fontFamily" not in diagram.frontmatter
        else []
    )
    rows += [row(diagram.fence, Check.CONTRACT, "warn", "floor:fontFamily-stack")] if FONT_BARE.search(diagram.frontmatter) else []
    rows += [row(diagram.fence, Check.CONTRACT, "warn", "floor:fontFamily-hyphen")] if FONT_HYPHEN.search(diagram.frontmatter) else []
    rows += [
        row(diagram.fence, Check.CONTRACT, "warn", f"floor:label-backing:{name}") for name in sorted(set(BACKING_FLAT.findall(diagram.frontmatter)))
    ]
    rows += (
        [row(diagram.fence, Check.CONTRACT, "warn", "floor:clusterBkg")]
        if diagram.family == Family.FLOWCHART
        and any(c.startswith("subgraph") for c in diagram.containers)
        and "clusterBkg" not in diagram.frontmatter
        else []
    )
    rows += (
        [row(diagram.fence, Check.CONTRACT, "warn", "flowchart-floor:canonical-class-count")]
        if diagram.family == Family.FLOWCHART and len(set(defs) & CANON) < 3
        else []
    )
    rows += [row(diagram.fence, Check.CONTRACT, "warn", f"class:non-canonical:{name}") for name in sorted(set(defs) - CANON)]
    rows += [row(diagram.fence, Check.CONTRACT, "warn", f"class:unused:{name}") for name in sorted(set(defs) - used)]
    rows += [
        row(diagram.fence, Check.CONTRACT, "warn", f"class:missing-color:{name}")
        for name, definition in sorted(defs.items())
        if "color:" not in definition.style
    ]
    rows += [
        row(diagram.fence, Check.CONTRACT, "warn", f"class:accent-fill-opaque:{name}")
        for name, definition in sorted(defs.items())
        if ACCENT_OPAQUE.search(definition.style)
    ]
    rows += [row(diagram.fence, Check.CONTRACT, "warn", "floor:padding-25")] if PADDING_22.search(diagram.frontmatter) else []
    rows += (
        [row(diagram.fence, Check.CONTRACT, "warn", "floor:container-title")]
        if CLUSTER_TITLE.search(diagram.frontmatter) or SECTION_TITLE.search(diagram.frontmatter)
        else []
    )
    rows += (
        [row(diagram.fence, Check.CONTRACT, "warn", "floor:terminal-circle")]
        if STATE_START_STALE.search(diagram.frontmatter) or TERMINAL_STALE.search(diagram.frontmatter)
        else []
    )
    rows += (
        [row(diagram.fence, Check.CONTRACT, "warn", "floor:marker-circle-scale")]
        if diagram.family == Family.FLOWCHART and MARKER_CIRCLE_STALE.search(diagram.frontmatter)
        else []
    )
    yellow_dark = (
        any(YELLOW_DARK_LINE.search(line) for line in diagram.lines)
        or (YELLOW_DARK_TAG.search(diagram.frontmatter) and YELLOW_DARK_TAG_INK.search(diagram.frontmatter))
        or (YELLOW_DARK_NOTE.search(diagram.frontmatter) and YELLOW_DARK_NOTE_INK.search(diagram.frontmatter))
    )
    rows += [row(diagram.fence, Check.CONTRACT, "warn", "floor:yellow-dark-ink")] if yellow_dark else []
    return tuple(rows)


def style_logic(diagram: Diagram) -> tuple[Row, ...]:
    count = len(diagram.edges)
    rows = [
        row(diagram.fence, Check.LOGIC, "fail", f"linkStyle-out-of-range:{index}")
        for link in diagram.links
        for index in link.indices
        if index >= count
    ]
    class_styles = {definition.name: definition.style for definition in diagram.defs}
    edge_classes = {use.target: class_styles.get(use.name, "") for use in diagram.uses}
    styled = {index for link in diagram.links for index in link.indices} | {edge.index for edge in diagram.edges if edge.ident in edge_classes}
    if diagram.family == Family.FLOWCHART:
        rows += [
            row(diagram.fence, Check.CONTRACT, "warn", f"edge:semantic-rail:{edge.index}")
            for edge in diagram.edges
            if "~" not in edge.token and RAIL_LABEL.search(edge.label) and edge.index not in styled
        ]
        fault_edges = [edge for edge in diagram.edges if "~" not in edge.token and FAULT_LABEL.search(edge.label)]
        rows += [
            row(diagram.fence, Check.CONTRACT, "warn", f"edge:fault-not-red:{edge.index}")
            for edge in fault_edges
            for link in diagram.links
            if edge.index in link.indices and "#FF5555" not in link.style.upper()
        ]
        rows += [
            row(diagram.fence, Check.CONTRACT, "warn", f"edge:fault-not-red:{edge.index}")
            for edge in fault_edges
            if edge.ident in edge_classes and "#FF5555" not in edge_classes[edge.ident].upper()
        ]
    if diagram.family == Family.SEQUENCE:
        grouped = any(line.strip().startswith(("rect ", "box ")) for line in diagram.lines)
        guarded = any(line.strip().startswith(("alt ", "par ", "critical", "break ")) for line in diagram.lines)
        rows += [row(diagram.fence, Check.CONTRACT, "warn", "sequence-floor:region-without-box-or-rect")] if guarded and not grouped else []
    if diagram.family == Family.C4 and "UpdateRelStyle" not in diagram.fence.body and "UpdateElementStyle" not in diagram.fence.body:
        rows += [row(diagram.fence, Check.CONTRACT, "warn", "c4-floor:update-style")]
    return tuple(rows)


def _flowchart_logic(diagram: Diagram) -> tuple[Row, ...]:
    declared: set[str] = set()
    for line in diagram.lines:
        clean = FC_EDGE_ID.sub("", FC_STR.sub("QL", strip_metadata(line)))
        if not FC_SKIP.match(clean) and FC_EDGE.search(clean) is None:
            declared.update(IDENT.findall(FC_SHAPE.sub(" ", clean)))
    endpoint = {node for edge in diagram.edges for node in (edge.source, edge.target)}
    # A declared-but-edgeless node renders correctly — inventory-by-membership is a legitimate pattern — so orphanhood warns, never blocks.
    rows = [row(diagram.fence, Check.LOGIC, "warn", f"orphan-node:{node}") for node in sorted(declared - endpoint)]
    rows += [
        row(diagram.fence, Check.LOGIC, "warn", f"duplicate-edge:{a}->{b}")
        for (a, b, _), count in Counter((edge.source, edge.target, edge.label) for edge in diagram.edges if "~" not in edge.token).items()
        if count > 1
    ]
    return tuple(rows)


def _state_logic(diagram: Diagram) -> tuple[Row, ...]:
    reach: nx.DiGraph[str, dict[str, object], dict[str, object]] = nx.DiGraph()
    states, starts, sources, terminals = set[str](), set[str](), set[str](), set[str]()
    for line in diagram.lines:
        if match := ST_TRANSITION.match(line):
            left, right = match.group(1), match.group(2)
            states.update(node for node in (left, right) if node != "[*]")
            starts.update({right} if left == "[*]" and right != "[*]" else set())
            sources.update({left} if left != "[*]" else set())
            terminals.update({left} if right == "[*]" and left != "[*]" else set())
            reach.add_edge(left, right)
    reachable = set().union(*(nx.descendants(reach, start) | {start} for start in starts), set()) if starts else states
    rows = [row(diagram.fence, Check.LOGIC, "fail", f"unreachable-state:{state}") for state in sorted(states - reachable)]
    # An absorbing non-terminal state — entered, never exited, never declared terminal — models nothing; declare the exit or the terminal.
    rows += [row(diagram.fence, Check.LOGIC, "warn", f"absorbing-state:{state}") for state in sorted(states - sources - terminals)]
    return tuple(rows)


def _sequence_logic(diagram: Diagram) -> tuple[Row, ...]:
    declared, used = set[str](), set[str]()
    for line in diagram.lines:
        declared.update(match.group(1) for match in [SQ_PARTICIPANT.match(line.strip())] if match)
        used.update(name for match in [SQ_ARROW.match(line)] if match for name in (match.group(1), match.group(2)))
    return tuple(row(diagram.fence, Check.LOGIC, "warn", f"orphan-participant:{name}") for name in sorted(declared - used))


def _er_logic(diagram: Diagram) -> tuple[Row, ...]:
    blocks, related = dict[str, str](), set[str]()
    entity = ""
    for line in diagram.lines:
        related.update(name for match in [ER_RELATION.match(line)] if match for name in (match.group(1), match.group(2)))
        if match := re.match(r"^\s*([\w-]+)\s*\{", line):
            entity = match.group(1)
            blocks.setdefault(entity, "")
        elif entity and re.match(r"^\s*\}", line):
            entity = ""
        elif entity:
            blocks[entity] += f" {line}"
    keyed = {name: set(re.findall(r"\b(PK|FK)\b", body)) for name, body in blocks.items()}
    rows = [row(diagram.fence, Check.LOGIC, "warn", f"orphan-entity:{name}") for name in sorted(set(blocks) - related)]
    rows += [
        row(diagram.fence, Check.LOGIC, "warn", f"er:no-pk:{name}")
        for name, keys in sorted(keyed.items())
        if blocks[name].strip() and "PK" not in keys
    ]
    # Entity-granular only: a bare discriminator pair without an FK marker is the sanctioned polymorphic form and never flags.
    rows += [
        row(diagram.fence, Check.LOGIC, "warn", f"er:fk-without-edge:{name}")
        for name, keys in sorted(keyed.items())
        if "FK" in keys and name not in related
    ]
    return tuple(rows)


def _gantt_logic(diagram: Diagram) -> tuple[Row, ...]:
    ids, refs = set[str](), set[str]()
    heads = ("section", "title", "dateFormat", "axisFormat", "tickInterval", "excludes", "includes", "todayMarker", "weekend")
    for line in diagram.lines:
        if ":" not in line or line.strip().startswith(heads):
            continue
        parts = [part.strip() for part in line.split(":", 1)[1].split(",")]
        ids.update(part for part in parts if re.fullmatch(r"[A-Za-z_][\w-]*", part) and part not in {"active", "crit", "done", "milestone", "vert"})
        refs.update(match.group(2) for match in re.finditer(r"\b(after|until)\s+([\w-]+)", line))
    return tuple(row(diagram.fence, Check.LOGIC, "fail", f"dangling-task:{ref}") for ref in sorted(refs - ids))


def _architecture_logic(diagram: Diagram) -> tuple[Row, ...]:
    groups, nodes, member_refs, edge_refs = (set[str](), set[str](), set[str](), set[str]())
    for line in diagram.lines:
        text = line.strip()
        if match := re.match(r"^group\s+([\w-]+)", text):
            groups.add(match.group(1))
        elif match := re.match(r"^(?:service|junction)\s+([\w-]+)", text):
            nodes.add(match.group(1))
            member_refs.update(ref.group(1) for ref in [re.search(r"\bin\s+([\w-]+)\s*$", text)] if ref)
        elif match := re.match(r"^([\w-]+)(?:\{[\w-]+\})?:[TBLR]\s*(?:<)?--(?:>)?\s*[TBLR]:([\w-]+)(?:\{[\w-]+\})?", text):
            edge_refs.update((match.group(1), match.group(2)))
    rows = [row(diagram.fence, Check.LOGIC, "fail", f"dangling-group:{name}") for name in sorted(member_refs - groups)]
    rows += [row(diagram.fence, Check.LOGIC, "fail", f"dangling-service:{name}") for name in sorted(edge_refs - nodes)]
    rows += [row(diagram.fence, Check.LOGIC, "warn", f"orphan-service:{name}") for name in sorted(nodes - edge_refs)]
    return tuple(rows)


def _requirement_logic(diagram: Diagram) -> tuple[Row, ...]:
    kinds = "requirement|functionalRequirement|interfaceRequirement|performanceRequirement|physicalRequirement|designConstraint|element"
    declared, requirements, related = set[str](), set[str](), set[str]()
    for line in diagram.lines:
        text = line.strip()
        if match := re.match(rf"^({kinds})\s+([\w-]+)\s*\{{", text):
            declared.add(match.group(2))
            requirements.update({match.group(2)} if match.group(1) != "element" else set())
        elif match := re.match(r"^([\w-]+)\s*(?:-\s*\w+\s*->|<-\s*\w+\s*-)\s*([\w-]+)", text):
            related.update((match.group(1), match.group(2)))
    rows = [row(diagram.fence, Check.LOGIC, "fail", f"dangling-relation:{name}") for name in sorted(related - declared)]
    rows += [row(diagram.fence, Check.LOGIC, "warn", f"orphan-requirement:{name}") for name in sorted(requirements - related)]
    return tuple(rows)


def _c4_logic(diagram: Diagram) -> tuple[Row, ...]:
    declared = {match.group(1) for line in diagram.lines for match in [re.match(r"^\s*(?!Rel|BiRel|Update)[A-Za-z_]+\(\s*(\w+)\s*,", line)] if match}
    related = {
        name
        for line in diagram.lines
        for match in [re.match(r"^\s*(?:Bi)?Rel\w*\(\s*(\w+)\s*,\s*(\w+)", line)]
        if match
        for name in (match.group(1), match.group(2))
    }
    return tuple(row(diagram.fence, Check.LOGIC, "fail", f"dangling-relation:{name}") for name in sorted(related - declared))


LOGIC_FAMILY: dict[Family, Callable[[Diagram], tuple[Row, ...]]] = {
    Family.FLOWCHART: _flowchart_logic,
    Family.STATE: _state_logic,
    Family.SEQUENCE: _sequence_logic,
    Family.ER: _er_logic,
    Family.GANTT: _gantt_logic,
    Family.ARCHITECTURE: _architecture_logic,
    Family.REQUIREMENT: _requirement_logic,
    Family.C4: _c4_logic,
}


def graph_logic(diagram: Diagram) -> tuple[Row, ...]:
    if (family_logic := LOGIC_FAMILY.get(diagram.family)) is not None:
        return family_logic(diagram)
    return (
        (row(diagram.fence, Check.LOGIC, "warn", f"logic-unimplemented:{diagram.header}"),)
        if diagram.family == Family.UNKNOWN and diagram.header
        else ()
    )


def class_logic(diagram: Diagram) -> tuple[Row, ...]:
    defs = {definition.name for definition in diagram.defs} | {"default"}
    subgraphs = {match.group(1) for line in diagram.lines for match in [re.match(r"^\s*subgraph\s+([\w.-]+)", line)] if match}
    edge_ids = {name for line in diagram.lines for name in FC_EDGE_ID.findall(line)}
    targets = {edge.source for edge in diagram.edges} | {edge.target for edge in diagram.edges} | subgraphs | edge_ids
    return tuple(
        [row(diagram.fence, Check.LOGIC, "fail", f"undefined-class:{use.name}") for use in diagram.uses if use.name not in defs]
        + [
            row(diagram.fence, Check.LOGIC, "fail", f"unknown-node-in-class:{use.target}")
            for use in diagram.uses
            if diagram.family == Family.FLOWCHART and targets and use.target not in targets
        ]
    )


# --- [GEOMETRY] -------------------------------------------------------------------------


def _delta(transform: str) -> tuple[float, float]:
    if m := TRANSLATE.search(transform):
        return float(m.group(1)), float(m.group(2))
    if m := MATRIX.search(transform):
        return float(m.group(1)), float(m.group(2))
    return 0.0, 0.0


def _tag(el: Element) -> str:
    return el.tag.rsplit("}", 1)[-1]


def _poly_d(points: str) -> str:
    nums = re.findall(r"[-\d.eE]+", points)
    return "M" + " L".join(f"{nums[i]},{nums[i + 1]}" for i in range(0, len(nums) - 1, 2)) + " Z" if len(nums) >= 4 else ""


def _rect_box(el: Element) -> tuple[float, float, float, float]:
    x, y, w, h = (float(el.get(key, 0)) for key in ("x", "y", "width", "height"))
    return x, y, x + w, y + h


def _circle_box(el: Element) -> tuple[float, float, float, float]:
    cx, cy, r = (float(el.get(key, 0)) for key in ("cx", "cy", "r"))
    return cx - r, cy - r, cx + r, cy + r


def _path_box(el: Element) -> tuple[float, float, float, float] | None:
    d = el.get("d") or _poly_d(el.get("points", ""))
    box = SvgPath(d).bbox() if d else None
    return (box[0], box[1], box[2], box[3]) if box else None


# Shape-tag dispatch keeps the failure-guarding try body to one statement; the caller adds the accumulated translate.
SHAPE_BOX = {"rect": _rect_box, "circle": _circle_box, "path": _path_box, "polygon": _path_box}


def _shape_bbox(el: Element) -> tuple[float, float, float, float] | None:
    if (shape := SHAPE_BOX.get(_tag(el))) is None:
        return None
    try:
        return shape(el)
    except ValueError, TypeError:
        return None


def _group_box(group: Element, tx: float, ty: float) -> tuple[float, float, float, float] | None:
    # Union the shape descendants of a node or cluster group, skipping label subtrees whose foreignObject inflates the box.
    boxes: list[tuple[float, float, float, float]] = []

    def descend(el: Element, ax: float, ay: float, *, labelled: bool) -> None:
        dx, dy = _delta(el.get("transform", ""))
        ax, ay = ax + dx, ay + dy
        labelled = labelled or bool({t.lower() for t in el.get("class", "").split()} & GEOM_LABEL_TOK) or _tag(el) in {"foreignObject", "text"}
        if not labelled and (bb := _shape_bbox(el)):
            boxes.append((bb[0] + ax, bb[1] + ay, bb[2] + ax, bb[3] + ay))
        for child in el:
            descend(child, ax, ay, labelled=labelled)

    for child in group:
        descend(child, tx, ty, labelled=False)
    return (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes)) if boxes else None


def _edge_polyline(el: Element, tx: float, ty: float) -> list[tuple[float, float]] | None:
    # The exact ELK/dagre data-points routing waypoints when present; else the sampled path, curve smoothing included.
    if raw := el.get("data-points"):
        with suppress(ValueError, KeyError, TypeError):
            waypoints = json.loads(base64.b64decode(raw))
            if len(waypoints) >= 2:
                return [(point["x"] + tx, point["y"] + ty) for point in waypoints]
    if d := el.get("d"):
        with suppress(ValueError, TypeError, ZeroDivisionError):
            path = SvgPath(d)
            return [(path.point(i / GEOM_SAMPLES).x + tx, path.point(i / GEOM_SAMPLES).y + ty) for i in range(GEOM_SAMPLES + 1)]
    return None


def svg_geometry(
    svg_text: str,
) -> tuple[list[tuple[float, float, float, float]], list[list[tuple[float, float]]], list[tuple[float, float, float, float]]]:
    root = fromstring(svg_text)
    nodes: list[tuple[float, float, float, float]] = []
    edges: list[list[tuple[float, float]]] = []
    clusters: list[tuple[float, float, float, float]] = []

    def walk(el: Element, tx: float, ty: float) -> None:
        dx, dy = _delta(el.get("transform", ""))
        tx, ty = tx + dx, ty + dy
        tokens = el.get("class", "").split()
        if _tag(el) == "g" and ("cluster" in tokens or "subgraph" in tokens):
            clusters.append(bb) if (bb := _group_box(el, tx, ty)) else None
            return  # nested subgraph and cluster groups share one rect; capture once
        if "node" in tokens:
            nodes.append(bb) if (bb := _group_box(el, tx, ty)) else None
            return  # node outline captured from its shapes; never descend into the label
        if _tag(el) == "path" and any(kind in el.get("class", "") for kind in GEOM_EDGE_CLASS) and (pts := _edge_polyline(el, tx, ty)):
            edges.append(pts)
        for child in el:
            walk(child, tx, ty)

    walk(root, 0.0, 0.0)
    return nodes, edges, clusters


def _orient(o: tuple[float, float], a: tuple[float, float], b: tuple[float, float]) -> float:
    return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])


def _segments_cross(a: tuple[float, float], b: tuple[float, float], c: tuple[float, float], d: tuple[float, float]) -> bool:
    # Proper (strict) intersection excludes shared endpoints and collinear touches by construction.
    return _orient(c, d, a) * _orient(c, d, b) < 0 and _orient(a, b, c) * _orient(a, b, d) < 0


def _endpoints(edge: list[tuple[float, float]], nodes: list[tuple[float, float, float, float]]) -> set[int]:
    # An edge's true endpoint nodes are the boxes nearest its two termini; every other box it enters is a defect.
    def nearest(pt: tuple[float, float]) -> int:
        return min(
            range(len(nodes)),
            key=lambda i: (pt[0] - (nodes[i][0] + nodes[i][2]) / 2) ** 2 + (pt[1] - (nodes[i][1] + nodes[i][3]) / 2) ** 2,
            default=-1,
        )

    return {index for index in (nearest(edge[0]), nearest(edge[-1])) if index >= 0}


def _in_box(pt: tuple[float, float], box: tuple[float, float, float, float], pad: float) -> bool:
    return box[0] - pad <= pt[0] <= box[2] + pad and box[1] - pad <= pt[1] <= box[3] + pad


def geometry_rows(svg_text: str, diagram: Diagram) -> tuple[Row, ...]:
    if diagram.family not in GEOM_FAMILIES:
        return ()
    try:
        nodes, edges, clusters = svg_geometry(svg_text)
    except ParseError, ValueError, TypeError:
        return ()
    del clusters
    rows: list[Row] = [
        row(diagram.fence, Check.LEGIBILITY, "fail", f"node-overlap:{i}-{j}")
        for i, a in enumerate(nodes)
        for j, b in enumerate(nodes)
        if i < j and a[0] < b[2] and a[2] > b[0] and a[1] < b[3] and a[3] > b[1]
    ]
    endpoints = [_endpoints(edge, nodes) for edge in edges] if nodes else [set() for _ in edges]
    for ei, edge in enumerate(edges):
        interior = edge[1:-1] if len(edge) > 2 else edge
        crossed = next((ni for ni, box in enumerate(nodes) if ni not in endpoints[ei] and any(_in_box(pt, box, -2.0) for pt in interior)), None)
        rows.append(row(diagram.fence, Check.LEGIBILITY, "warn", f"edge-over-node:{ei}-{crossed}")) if crossed is not None else None
    # A pair counts once however many times its two polylines cross, and curve sampling under-detects, so N is a lower bound on visual
    # crossings — the honest name is pairs, never a crossing count.
    crossings = sum(
        1
        for i in range(len(edges))
        for j in range(i + 1, len(edges))
        if not (endpoints[i] & endpoints[j]) and any(_segments_cross(a, b, c, d) for a, b in pairwise(edges[i]) for c, d in pairwise(edges[j]))
    )
    rows.append(row(diagram.fence, Check.LEGIBILITY, "warn", f"edge-crossing-pairs:{crossings}")) if crossings else None
    return tuple(rows)


def prune_cache(cache_dir: Path, ttl: float = CACHE_TTL) -> None:
    cutoff = time.time() - ttl
    for entry in cache_dir.glob("*.svg"):
        with suppress(OSError):
            if entry.stat().st_mtime < cutoff:
                entry.unlink()


def _slug(diagram: Diagram) -> str:
    stem = re.sub(r"[^a-z0-9]+", "-", Path(diagram.fence.file).name.split(".")[0].lower()).strip("-") or "diagram"
    return f"{stem}-{diagram.fence.line}"


def _canvased(svg: str) -> str:
    # The renderer bakes background-color: white onto the SVG root; the Dracula canvas replaces it so the artifact self-carries on any host.
    head, sep, tail = svg.partition(">")
    if "background-color" in head:
        head = re.sub(r"background-color:\s*[^;\"]+", f"background-color: {CANVAS}", head)
    elif 'style="' in head:
        head = head.replace('style="', f'style="background-color: {CANVAS}; ', 1)
    else:
        head = head.replace("<svg", f'<svg style="background-color: {CANVAS};"', 1)
    return head + sep + tail


def proof_png(prefix: tuple[str, ...], cwd: Path | None, diagram: Diagram, svg_path: Path, workdir: Path, proof_dir: Path) -> Row:
    target = proof_dir / f"{_slug(diagram)}.png"
    svg = svg_path.read_text(encoding="utf-8", errors="ignore")
    resvg = shutil.which("resvg")
    if "<foreignObject" not in svg and resvg:
        # resvg applies CSS transform without transform-box support, scaling from the canvas origin and casting label chips adrift, so
        # every transform-box:fill-box rule drops from the raster copy — geometry stays true, only the micro-scale garnish is shed.
        flattened = workdir / f"{_slug(diagram)}-raster.svg"
        flattened.write_text(_canvased(TRANSFORM_BOX_RULE.sub("", svg)), encoding="utf-8")
        with suppress(subprocess.TimeoutExpired, OSError):
            raster = subprocess.run(
                [resvg, "--zoom", "2", "--background", CANVAS, str(flattened), str(target)],
                capture_output=True,
                text=True,
                timeout=RENDER_TIMEOUT,
                check=False,
            )
            if raster.returncode == 0 and target.is_file():
                return row(diagram.fence, Check.PROOF, "ok", f"proof:{target}")
    # foreignObject labels die under resvg, so the faithful raster for this SVG is mmdc's own PNG render.
    src, cfg, browser = workdir / f"{_slug(diagram)}-proof.mmd", workdir / "mermaid-config.json", workdir / "puppeteer-config.json"
    src.write_text(diagram.fence.body, encoding="utf-8")
    cfg.write_bytes(ENCODER.encode(RENDER_CONFIG))
    browser.write_bytes(ENCODER.encode(PUPPETEER_CONFIG))
    try:
        proc = subprocess.run(
            [*prefix, "-q", "-i", str(src), "-o", str(target), "-c", str(cfg), "-p", str(browser), "-b", CANVAS, "-s", "2"],
            cwd=cwd,
            env=RENDER_ENV,
            capture_output=True,
            text=True,
            timeout=RENDER_TIMEOUT,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return row(diagram.fence, Check.PROOF, "fail", f"environment:proof-timeout:{RENDER_TIMEOUT}s")
    except OSError as exc:
        return row(diagram.fence, Check.PROOF, "fail", f"environment:proof-renderer-unavailable:{type(exc).__name__}")
    if proc.returncode != 0 or not target.is_file():
        raw = next((line for line in (proc.stderr or proc.stdout).splitlines() if line.strip()), "proof render failed")
        return row(diagram.fence, Check.PROOF, "fail", f"environment:{raw.strip()[:280]}")
    return row(diagram.fence, Check.PROOF, "ok", f"proof:{target}")


def rendered_rows(
    prefix: tuple[str, ...], cwd: Path | None, diagrams: tuple[Diagram, ...], cache_dir: Path, export: Path | None, proof_dir: Path | None
) -> tuple[Row, ...]:
    prune_cache(cache_dir)
    rows: list[Row] = []
    with TemporaryDirectory(prefix="mermaid-validate-") as tmp:
        workdir = Path(tmp)
        for diagram in diagrams:
            outcome = render(prefix, cwd, diagram, workdir, cache_dir)
            rows.append(outcome)
            if outcome.status != "ok":
                continue
            svg_path = Path(outcome.detail.split(":", 1)[1])
            with suppress(OSError):
                rows.extend(geometry_rows(svg_path.read_text(encoding="utf-8", errors="ignore"), diagram))
            if proof_dir is not None:
                released = outcome.detail.startswith(("rendered-release:", "release-cache-hit:"))
                rows.append(proof_png(RELEASE_RENDERER if released else prefix, None if released else cwd, diagram, svg_path, workdir, proof_dir))
            if export is not None:
                rows.append(export_svg(svg_path, diagram, export))
    return tuple(rows)


def resolve_renderer(override: str | None) -> tuple[tuple[str, ...], Path | None]:
    if override:
        argv = tuple(shlex.split(override))
        return (argv, None) if argv and shutil.which(argv[0]) else ((), None)
    workspace = next((c for d in (Path.cwd(), *Path.cwd().parents) if (c := d / "node_modules" / ".bin" / "mmdc").is_file()), None)
    if workspace is not None:
        return ((str(workspace),), None)
    return (("mmdc",), None) if shutil.which("mmdc") else ((), None)


def render(prefix: tuple[str, ...], cwd: Path | None, diagram: Diagram, workdir: Path, cache_dir: Path) -> Row:
    primary = attempt(prefix, cwd, diagram, workdir, cache_dir)
    if primary.status != "fail" or not primary.detail.startswith("syntax:") or prefix == RELEASE_RENDERER or not shutil.which("pnpm"):
        return primary
    fallback = attempt(RELEASE_RENDERER, None, diagram, workdir, cache_dir)
    if fallback.status == "ok":
        return row(
            diagram.fence,
            Check.RENDER,
            "ok",
            fallback.detail.replace("rendered:", "rendered-release:", 1).replace("render-cache-hit:", "release-cache-hit:", 1),
        )
    return fallback


def attempt(prefix: tuple[str, ...], cwd: Path | None, diagram: Diagram, workdir: Path, cache_dir: Path) -> Row:
    cache_dir.mkdir(parents=True, exist_ok=True)
    config = ENCODER.encode(RENDER_CONFIG)
    key = xxh3_128_hexdigest(diagram.fence.body.encode() + b"\0".join(part.encode() for part in prefix) + config)
    cached = cache_dir / f"{key}.svg"
    if cached.exists() and cached.read_text(encoding="utf-8", errors="ignore").lstrip().startswith("<svg"):
        return row(diagram.fence, Check.RENDER, "ok", f"render-cache-hit:{cached}")
    src, out, cfg, browser = (workdir / f"{key}.mmd", workdir / f"{key}.svg", workdir / "mermaid-config.json", workdir / "puppeteer-config.json")
    src.write_text(diagram.fence.body, encoding="utf-8")
    cfg.write_bytes(config)
    browser.write_bytes(ENCODER.encode(PUPPETEER_CONFIG))
    try:
        proc = subprocess.run(
            [*prefix, "-q", "-i", str(src), "-o", str(out), "-c", str(cfg), "-p", str(browser)],
            cwd=cwd,
            env=RENDER_ENV,
            capture_output=True,
            text=True,
            timeout=RENDER_TIMEOUT,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return row(diagram.fence, Check.RENDER, "fail", f"environment:render-timeout:{RENDER_TIMEOUT}s")
    except OSError as exc:
        return row(diagram.fence, Check.RENDER, "fail", f"environment:renderer-unavailable:{type(exc).__name__}")
    raw = next((line for line in (proc.stderr or proc.stdout).splitlines() if line.strip()), "renderer failed")
    if proc.returncode != 0 or not out.exists():
        stage = "environment" if any(marker in raw.lower() for marker in ENV_MARKERS) else "syntax"
        return row(diagram.fence, Check.RENDER, "fail", f"{stage}:{raw.strip()[:280]}")
    svg = out.read_text(encoding="utf-8", errors="ignore")
    if not svg.lstrip().startswith("<svg"):
        return row(diagram.fence, Check.RENDER, "fail", "syntax:invalid-svg-root")
    if 'aria-roledescription="error"' in svg or "Syntax error in text" in svg:
        detail = next(iter(re.findall(r"(?:Syntax|Parse) error[^<]{0,180}", svg)), "mermaid-error-graphic")
        return row(diagram.fence, Check.RENDER, "fail", f"syntax:error-graphic:{' '.join(detail.split())}")
    cached.write_bytes(out.read_bytes())
    return row(diagram.fence, Check.RENDER, "ok", f"rendered:{cached}")


def export_svg(source: Path, diagram: Diagram, export_dir: Path) -> Row:
    export_dir.mkdir(parents=True, exist_ok=True)
    svg = source.read_text(encoding="utf-8", errors="ignore")
    slug = _slug(diagram)
    if root_id := next(iter(re.findall(r'<svg[^>]*?\bid="([^"]+)"', svg)), None):
        svg = svg.replace(root_id, slug)
    target = export_dir / f"{slug}.svg"
    target.write_text(_canvased(svg), encoding="utf-8")
    return row(diagram.fence, Check.EXPORT, "ok", f"exported:{target}")


def static_rows(fences: tuple[Fence, ...]) -> tuple[Row, ...]:
    rows: list[Row] = []
    for fence in fences:
        diagram, faults = parse(fence)
        rows.extend(faults)
        if diagram is not None:
            rows.extend((*contract(diagram), *style_logic(diagram), *graph_logic(diagram), *class_logic(diagram)))
    return tuple(rows)


# --- [COMPOSITION] ----------------------------------------------------------------------


@APP.default
def main(
    *paths: Path,
    json: bool = False,
    no_render: bool = False,
    renderer: str | None = None,
    cache_dir: Path = Path(".cache/mermaid"),
    export: Path | None = None,
    proof: bool = False,
    keep: bool = False,
) -> int:
    files, rows = collect(paths)
    fences: list[Fence] = []
    for file in files:
        found, read_rows = read_fences(file)
        fences.extend(found)
        rows = (*rows, *read_rows)
    parsed = tuple(parse(fence)[0] for fence in fences)
    diagrams = tuple(diagram for diagram in parsed if diagram is not None)
    rows = (*rows, *static_rows(tuple(fences)))
    if not no_render and diagrams:
        # Proof rasters are per-run ephemera, never a growing cache: the dir dies with the run unless --keep preserves it for inspection.
        proof_dir = Path(mkdtemp(prefix="mermaid-proof-")) if proof else None
        prefix, cwd = resolve_renderer(renderer)
        rendered = (
            rendered_rows(prefix, cwd, diagrams, cache_dir, export, proof_dir)
            if prefix
            else (Row("-", 0, Check.SETUP, "fail", "no mermaid renderer"),)
        )
        rows = (*rows, *rendered)
        if proof_dir is not None:
            if keep:
                rows = (*rows, Row("-", 0, Check.PROOF, "ok", f"proof-dir:{proof_dir}"))
            else:
                shutil.rmtree(proof_dir, ignore_errors=True)
    for output in rows:
        emit(output, json)
    return exit_code(rows)


if __name__ == "__main__":
    sys.exit(APP())
