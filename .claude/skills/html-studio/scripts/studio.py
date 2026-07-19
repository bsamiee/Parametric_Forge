#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.15"
# dependencies = [
#   "anyio", "coloraide", "cyclopts", "expression", "httpx", "lxml", "msgspec", "psutil",
#   "stamina", "structlog", "tree-sitter", "tree-sitter-typescript", "watchfiles", "xxhash",
#   "tinycss2",
#   "beartype @ git+https://github.com/beartype/beartype.git@f370a0b1733413681e7a72bf36fbe839e60b3c85",
# ]
# ///
# ruff: noqa: T201, D101, D102, D103, D107
"""html-studio automation owner.

Verbs: gate | render | serve | status | stop | receipts | self-test. `gate` statically gates one
artifact; `render` headless-captures a PNG through the pinned Chromium; the server verbs run the
loopback return channel that injects `artifact-return` and `artifact-token` head metas and
appends receipts as one tagged JSONL stream.
"""

# --- [RUNTIME_PRELUDE] ------------------------------------------------------------------

from collections.abc import Iterator, Mapping, Sequence
from datetime import datetime, UTC
from enum import IntEnum, StrEnum
from functools import cache, partial
import hashlib
import hmac
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from itertools import pairwise
import os
from pathlib import Path
import re
from secrets import token_hex
import shutil
from signal import SIGINT, SIGTERM
import subprocess
import sys
import tempfile
import threading
from typing import Annotated, Literal, override, Self, TYPE_CHECKING, TypeIs
from urllib.parse import urlsplit
import webbrowser

import anyio
from anyio import Path as APath
import anyio.to_thread
from beartype import beartype
from coloraide import Color
from cyclopts import App, Parameter
from expression import Error, Ok, Result
from expression.extra.result import catch
import httpx
from lxml import html
from lxml.etree import ParserError, XPath
import msgspec
import psutil
import stamina
import structlog
import tinycss2
from tree_sitter import Language, Parser
import tree_sitter_typescript
import watchfiles
from xxhash import xxh3_128_hexdigest


if TYPE_CHECKING:
    from tree_sitter import Node


# --- [TYPES] ----------------------------------------------------------------------------

type Status = Literal["ok", "warn", "fail"]
type Session = Annotated[str, Parameter(env_var="CLAUDE_CODE_SESSION_ID")]


class Check(StrEnum):
    A11Y_NAME = "a11y-name"
    BASE = "base"
    CONFORMANCE = "conformance"
    CSS_LAYER = "css-layer"
    DOCTYPE = "doctype"
    DUPLICATE_ID = "duplicate-id"
    EMBEDDED_STATE = "embedded-state"
    EXTERNAL_REF = "external-ref"
    FOCUS_VISIBLE = "focus-visible"
    FIELDSET_LEGEND = "fieldset-legend"
    FORM_LABEL = "form-label"
    FORM_NAME = "form-name"
    HEADING_ORDER = "heading-order"
    IMPORTANT = "important"
    INLINE_HANDLER = "inline-handler"
    INLINE_STYLE = "inline-style"
    INNER_HTML = "inner-html"
    INTERACTION = "interaction"
    JS_LEGACY = "js-legacy"
    JS_SINK = "js-sink"
    JS_SYNTAX = "js-syntax"
    PRINT = "print"
    OUTPUT_FOR = "output-for"
    RAW_HEX = "raw-hex"
    READ = "read"
    RENDER = "render"
    RESIDUE = "residue"
    RETURN_META = "return-meta"
    SCRIPT_COUNT = "script-count"
    SCRIPT_HAZARD = "script-hazard"
    SECRET = "secret"
    SIZE = "size"
    SRGB_MIX = "srgb-mix"
    STYLE_COUNT = "style-count"
    TITLE = "title"
    TOKEN_CONTRAST = "token-contrast"
    VAR_GRAPH = "var-graph"


class ScriptKind(StrEnum):
    EXECUTABLE = "executable"
    PAYLOAD = "payload"


class FaultKind(StrEnum):
    BAD_ARTIFACT = "bad-artifact"
    BAD_ENVELOPE = "bad-envelope"
    BAD_HOST = "bad-host"
    BAD_JSON = "bad-json"
    BAD_LENGTH = "bad-length"
    BAD_ORIGIN = "bad-origin"
    BAD_TOKEN = "bad-token"
    BAD_TYPE = "bad-type"
    NOT_FOUND = "not-found"
    OVERSIZE = "oversize"
    PORT_BUSY = "port-busy"
    RECEIPT_IO = "receipt-io"
    SELF_TEST = "self-test"
    STATE_BUSY = "state-busy"
    STATE_UNREADABLE = "state-unreadable"
    STOP_TIMEOUT = "stop-timeout"


class EventKind(StrEnum):
    STARTED = "server.started"
    CHANGED = "artifact.changed"
    REJECTED = "submission.rejected"
    TTL_EXPIRED = "server.ttl-expired"
    STOPPED = "server.stopped"


class Exit(IntEnum):
    OK = 0
    GATE = 1
    USAGE = 2
    STATE = 3
    IO = 4
    NET = 5
    CONTRACT = 6


class OutputMode(StrEnum):
    BANNER = "banner"
    JSON = "json"


# --- [CONSTANTS] ------------------------------------------------------------------------

SKILL_DIR = Path(__file__).resolve().parent

BAD_REF = re.compile(r"^(?:/|//|[a-z][a-z0-9+.-]*:)", re.IGNORECASE)
COLOR_REF = re.compile(r"var\((--[\w-]+)\)|oklch\([^)]+\)|#[0-9a-fA-F]{3,8}\b")
CSS_DECL = re.compile(r"(?P<prop>--?[-\w]+)\s*:\s*(?P<value>[^;{}]+)")
CSS_IMPORT = re.compile(r"@import\s+(?:url\()?['\"]?([^'\"\s)]+)", re.IGNORECASE)
CSS_URL = re.compile(r"url\(\s*['\"]?([^'\"\s)]+)", re.IGNORECASE)
DOCTYPE = re.compile(r"^(?:\s|<!--.*?-->)*<!doctype\s+html", re.IGNORECASE | re.DOTALL)
EXEC_COMMAND = re.compile(r"\bdocument\s*\.\s*execCommand\s*\(")
HEX_COLOR = re.compile(r"#[0-9a-fA-F]{3,8}\b")
JSON_TYPES = frozenset({"application/json"})
LAYER_NAME = re.compile(r"@layer\s+([-\w]+)\s*$")
REMOTE_LITERAL = re.compile(r"(?:https?:)?//|^/")
RESIDUE = re.compile(r"\{\{[^{}]+\}\}")
RETURN_METAS = re.compile(rb'[ \t]*<meta\s+name="artifact-(?:return|token)"[^>]*>\s*', re.IGNORECASE)
SCRIPT_HAZARD = re.compile(r"[\u2028\u2029]")
SCRIPT_SINK_TEXT = re.compile(r"\b(?:fetch|import|Worker|SharedWorker|WebSocket|EventSource|sendBeacon|open)\s*\(", re.IGNORECASE)
SECRET = re.compile(
    r"AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{8,}\.eyJ"
)
SRGB_MIX = re.compile(r"color-mix\(\s*in\s+srgb", re.IGNORECASE)
STYLE_ALLOWED_AT_RULES = ("@charset", "@layer", "@media", "@property", "@supports", "@keyframes", "@starting-style", "@page")
VAR_USE = re.compile(r"var\(\s*(--[\w-]+)\s*(,)?")
PROP_DEF = re.compile(r"@property\s+(--[\w-]+)")
SET_PROPERTY = re.compile(r"setProperty\(\s*['\"](--[\w-]+)")
FOCUS_OUTLINE = re.compile(r":focus-visible[^{}]*{(?=[^{}]*outline\s*:\s*none)(?![^{}]*box-shadow)")
PRINT_EXPORT_BAR = re.compile(r"@media print[\s\S]*\.export-bar[^{]*{[^{}]*display\s*:\s*none")
PRINT_SAFE_LAYERS = frozenset({"print", "overrides"})
SIZE_WARN = 400 * 1024
SUBPROCESS_TIMEOUT = {"vnu": 120.0, "render": 300.0}  # seconds; render covers a cold `uv run --with playwright` install
MIN_CONTRAST = 4.5
CHIP_ALPHA = 0.14
CONTRAST_CHECKS: tuple[tuple[str, str, float], ...] = (
    *((fg, bg, 1.0) for bg in ("--bg", "--surface", "--raised", "--raised-2", "--overlay") for fg in ("--text", "--text-muted")),
    ("--on-accent", "--accent", 1.0),
    *((token, "--raised", CHIP_ALPHA) for token in ("--ok", "--warn", "--fail", "--info")),
)

HOST = "127.0.0.1"
LOOPBACK = frozenset({"127.0.0.1", "localhost", "::1", "[::1]"})
MAX_BODY = 256 * 1024
HEAD_OPEN = re.compile(rb"<head(?=[\s>])[^>]*>", re.IGNORECASE)
TOKEN_META_RE = re.compile(r'name="artifact-token" content="([0-9a-f]{32})"')

RENDER_SCRIPT = """
import os
import sys

from playwright.sync_api import sync_playwright

abspath, out = sys.argv[1], sys.argv[2]
messages: list[str] = []
chrome = os.environ.get("PUPPETEER_EXECUTABLE_PATH")
with sync_playwright() as p:
    browser = p.chromium.launch(args=["--use-mock-keychain", "--password-store=basic"], **({"executable_path": chrome} if chrome else {}))
    page = browser.new_page(viewport={"width": 1280, "height": 900})
    page.on("console", lambda m: messages.append(f"{m.type}\\t{m.text}"))
    page.on("pageerror", lambda e: messages.append(f"pageerror\\t{e}"))
    page.goto(f"file://{abspath}", wait_until="load")
    page.wait_for_timeout(300)
    page.screenshot(path=out, full_page=True)
    browser.close()
for message in messages:
    print(message)
sys.exit(1 if any(message.startswith(("error\\t", "pageerror\\t")) for message in messages) else 0)
"""


# --- [MODELS] ---------------------------------------------------------------------------


class Row(msgspec.Struct, frozen=True):
    file: str
    line: int
    check: Check
    status: Status
    detail: str


class Script(msgspec.Struct, frozen=True):
    line: int
    kind: ScriptKind
    media: str
    body: str


class Artifact(msgspec.Struct, frozen=True):
    path: str
    text: str
    raw_size: int
    document: html.HtmlElement
    css: str
    css_flat: str
    css_base: int
    scripts: tuple[Script, ...]

    @classmethod
    def from_path(cls, path: Path) -> Result[Self, Row]:
        try:
            raw = path.read_bytes()
            text = raw.decode("utf-8")
            document = html.document_fromstring(text)
        except (OSError, UnicodeDecodeError, ParserError) as exc:
            return Error(Row(str(path), 0, Check.READ, "fail", type(exc).__name__))
        styles = tuple(document.iter("style"))
        css = "\n".join(style.text or "" for style in styles)
        base = line(styles[0]) if styles else 1
        return Ok(cls(str(path), text, len(raw), document, css, css_plain(css), base, scripts(document)))

    def line_at(self, offset: int, /) -> int:
        """Map an offset into `css`/`css_flat` (length-preserved) to its document line.

        Returns:
            The 1-based line in the document, anchored on the owning `<style>` block.
        """
        return self.css_base + self.css[:offset].count("\n")


class Envelope(msgspec.Struct, frozen=True, forbid_unknown_fields=True):
    kind: Annotated[str, msgspec.Meta(min_length=1, max_length=64)]
    artifact: Annotated[str, msgspec.Meta(min_length=1, max_length=256)]
    version: Annotated[int, msgspec.Meta(ge=1)]
    data: msgspec.Raw


class ReceiptRow(msgspec.Struct, frozen=True, tag="receipt", tag_field="row"):
    id: str
    received: str
    kind: str
    artifact: str
    payload: msgspec.Raw
    wrapper_digest: str = ""


class EventRow(msgspec.Struct, frozen=True, tag="event", tag_field="row"):
    id: str
    received: str
    kind: EventKind
    detail: str


class ServerState(msgspec.Struct, frozen=True):
    version: int
    pid: int
    create_time: float
    port: int
    artifact: str
    artifact_digest: str
    receipts: str
    started_at: str
    token_digest: str


class Reply(msgspec.Struct, frozen=True, omit_defaults=True):
    ok: bool
    id: str = ""
    fault: str = ""


class Fault(msgspec.Struct, frozen=True):
    kind: FaultKind
    detail: str = ""


class Output(msgspec.Struct, frozen=True, omit_defaults=True):
    status: str
    url: str = ""
    artifact: str = ""
    receipts: str = ""
    state: str = ""
    receipt_count: int = 0
    detail: str = ""


class FaultPolicy(msgspec.Struct, frozen=True):
    http: int = 400
    exit: Exit = Exit.USAGE


class DomRule(msgspec.Struct, frozen=True):
    expr: str
    check: Check
    detail: str
    status: Status = "fail"


class VnuMessage(msgspec.Struct, frozen=True, rename="camel"):
    type: str
    message: str = ""
    sub_type: str = ""
    last_line: int = 0
    first_column: int = 0


class VnuReport(msgspec.Struct, frozen=True):
    messages: tuple[VnuMessage, ...] = ()


# --- [SERVICES] -------------------------------------------------------------------------

ENC = msgspec.json.Encoder()
DEC_ENVELOPE = msgspec.json.Decoder(Envelope)
DEC_ROW = msgspec.json.Decoder(ReceiptRow | EventRow)
DEC_STATE = msgspec.json.Decoder(ServerState)
DEC_PAYLOAD = msgspec.json.Decoder()
DEC_VNU = msgspec.json.Decoder(VnuReport)
structlog.configure(
    processors=[structlog.processors.add_log_level, structlog.processors.TimeStamper(fmt="iso"), structlog.processors.JSONRenderer()],
    logger_factory=structlog.PrintLoggerFactory(sys.stderr),
)
LOG = structlog.get_logger()
FAULT_POLICY: Mapping[FaultKind, FaultPolicy] = {
    FaultKind.BAD_HOST: FaultPolicy(http=403),
    FaultKind.BAD_ORIGIN: FaultPolicy(http=403),
    FaultKind.BAD_TOKEN: FaultPolicy(http=403),
    FaultKind.NOT_FOUND: FaultPolicy(http=404),
    FaultKind.BAD_TYPE: FaultPolicy(http=415),
    FaultKind.BAD_LENGTH: FaultPolicy(http=411),
    FaultKind.OVERSIZE: FaultPolicy(http=413),
    FaultKind.BAD_JSON: FaultPolicy(http=400),
    FaultKind.BAD_ENVELOPE: FaultPolicy(http=422),
    FaultKind.RECEIPT_IO: FaultPolicy(http=500, exit=Exit.IO),
    FaultKind.BAD_ARTIFACT: FaultPolicy(http=500, exit=Exit.IO),
    FaultKind.PORT_BUSY: FaultPolicy(exit=Exit.NET),
    FaultKind.SELF_TEST: FaultPolicy(exit=Exit.CONTRACT),
    FaultKind.STATE_BUSY: FaultPolicy(exit=Exit.STATE),
    FaultKind.STATE_UNREADABLE: FaultPolicy(exit=Exit.STATE),
    FaultKind.STOP_TIMEOUT: FaultPolicy(exit=Exit.STATE),
}


def fault_policy(kind: FaultKind) -> FaultPolicy:
    return FAULT_POLICY.get(kind, FaultPolicy())


@cache
def _js_parser() -> Parser:
    parser = Parser()
    parser.language = Language(tree_sitter_typescript.language_typescript())
    return parser


class Sink:
    """Single locked append path for the tagged receipt/event JSONL stream; one instance per runtime."""

    __slots__ = ("_lock", "path")

    def __init__(self, path: Path) -> None:
        self.path = path
        self._lock = threading.Lock()

    def append(self, row: ReceiptRow | EventRow) -> None:
        with self._lock, self.path.open("ab") as sink:
            sink.write(ENC.encode(row) + b"\n")
            sink.flush()

    def rows(self) -> Iterator[ReceiptRow | EventRow]:
        if not self.path.is_file():
            return iter(())
        return iter(DEC_ROW.decode_lines(self.path.read_bytes()))

    def event(self, kind: EventKind, detail: str) -> None:
        received = _utc()
        self.append(EventRow(id=xxh3_128_hexdigest(f"{kind}{received}{detail}"), received=received, kind=kind, detail=detail))


class Runtime(msgspec.Struct, frozen=True):
    artifact: Path
    token: str
    receipts: Path
    sink: Sink


# --- [OPERATIONS] -----------------------------------------------------------------------

# --- [GATE_DOM]


def _node_set(found: object) -> TypeIs[list[html.HtmlElement]]:
    return isinstance(found, list) and all(isinstance(node, html.HtmlElement) for node in found)


@cache
def xpath(expr: str) -> XPath:
    return XPath(expr, smart_strings=False)


def q(root: html.HtmlElement, expr: str, /, **bindings: str) -> tuple[html.HtmlElement, ...]:
    """Run a compiled, memoized XPath with `$var` bindings; only node-set expressions are spelled here.

    Returns:
        The matched elements in document order.
    """
    found = xpath(expr)(root, **bindings)
    return tuple(found) if _node_set(found) else ()


def line(element: html.HtmlElement) -> int:
    return int(element.sourceline or 1)


def text(element: html.HtmlElement) -> str:
    return " ".join("".join(element.itertext()).split())


LABELABLE = "self::input[not(translate(@type,'HIDEN','hiden')='hidden')] or self::select or self::textarea"


def labelled(document: html.HtmlElement, node: html.HtmlElement) -> bool:
    ident = str(node.get("id") or "")
    return bool(
        node.get("aria-label")
        or node.get("aria-labelledby")
        or q(node, "ancestor::label")
        or (ident and q(document, "//label[@for=$ident]", ident=ident))
    )


def tag(element: html.HtmlElement) -> str:
    raw = element.tag
    return raw.decode("utf-8", "replace") if isinstance(raw, bytes | bytearray) else str(raw)


def scripts(document: html.HtmlElement) -> tuple[Script, ...]:
    def kind(media: str) -> ScriptKind:
        normalized = media.strip().lower()
        return ScriptKind.PAYLOAD if normalized in JSON_TYPES or normalized.endswith("+json") else ScriptKind.EXECUTABLE

    return tuple(
        Script(line(node), kind(media), media, node.text or "")
        for node in q(document, "//script")
        for media in [str(node.get("type") or "text/javascript")]
    )


def emit_row(row: Row, json_mode: bool) -> None:
    print(ENC.encode(row).decode("utf-8") if json_mode else f"{row.file}:{row.line}: {row.status.upper()} {row.check} {row.detail}")


def bad_reference(value: str) -> bool:
    return bool((ref := value.strip()) and BAD_REF.match(ref) and not ref.lower().startswith(("data:", "blob:", "about:blank")))


def srcset_urls(value: str) -> tuple[str, ...]:
    urls: list[str] = []
    token: list[str] = []
    quoted, data = "", False
    for char in f"{value},":
        quoted = "" if quoted == char else char if char in "\"'" and not quoted else quoted
        data = data or "".join(token).lower().startswith("data:")
        if char == "," and not quoted and (not data or re.search(r"\s+\d+(?:w|x)\s*$", "".join(token))):
            if parts := "".join(token).strip().split():  # empty token: trailing/doubled comma in malformed srcset
                urls.append(parts[0])
            token, data = [], False
        else:
            token.append(char)
    return tuple(url for url in urls if url)


def dom_rows(artifact: Artifact) -> tuple[Row, ...]:
    document = artifact.document
    rows: list[Row] = []
    rows.extend(
        Row(artifact.path, line(node), Check.RETURN_META, "fail", f"{node.get('name')} meta is server-injected")
        for node in q(document, "//meta[@name='artifact-return' or @name='artifact-token']")
    )
    rows.extend(Row(artifact.path, line(node), Check.BASE, "fail", "base href rewrites relative resolution") for node in q(document, "//base[@href]"))
    ids = {
        value: q(document, "//*[@id=$ident]", ident=value) for value in {str(node.get("id")) for node in q(document, "//*[@id]") if node.get("id")}
    }
    rows.extend(
        Row(artifact.path, line(nodes[0]), Check.DUPLICATE_ID, "fail", f"#{key} appears {len(nodes)} times")
        for key, nodes in ids.items()
        if len(nodes) > 1
    )
    headings = tuple(
        (int(tag(node)[1]), line(node))
        for node in q(document, "//*[self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6][not(ancestor::template)]")
    )
    rows.extend(
        Row(artifact.path, here, Check.HEADING_ORDER, "fail", f"h{previous} to h{current}")
        for (previous, _), (current, here) in pairwise(headings)
        if current > previous + 1
    )
    h1s = q(document, "//h1[not(ancestor::template)]")
    rows.extend(Row(artifact.path, line(node), Check.HEADING_ORDER, "fail", f"{len(h1s)} h1 elements") for node in h1s[1:2])
    rows.extend(
        Row(artifact.path, line(node), Check.A11Y_NAME, "fail", "icon-only button lacks accessible name")
        for node in q(document, "//button")
        if not text(node) and not any(node.get(attr) for attr in ("aria-label", "aria-labelledby", "title"))
    )
    rows.extend(
        Row(artifact.path, line(node), Check.INTERACTION, "fail", "toggle button lacks aria-pressed")
        for node in q(document, "//button[contains(@class,'toggle') or @role='switch' or @data-toggle]")
        if node.get("aria-pressed") is None
    )
    rows.extend(
        Row(artifact.path, line(node), Check.INLINE_HANDLER, "fail", name)
        for node in q(document, "//*[@*]")
        for name in node.attrib
        if name.lower().startswith("on")
    )
    rows.extend(
        Row(artifact.path, line(node), Check.INLINE_STYLE, "fail", f"inline style on <{tag(node)}>; bind a class or custom property")
        for node in q(document, "//*[@style][not(ancestor-or-self::svg)]")
    )
    rows.extend(
        Row(artifact.path, line(node), Check.INTERACTION, "fail", "clickable svg group lacks tabindex")
        for node in q(document, "//svg//*[@data-k][not(@tabindex)]")
    )
    rows.extend(
        Row(artifact.path, line(node), Check.FORM_LABEL, "fail", f"<{tag(node)}> lacks label")
        for node in q(document, f"//*[{LABELABLE}]")
        if not labelled(document, node)
    )
    rows.extend(
        Row(artifact.path, line(node), Check.FIELDSET_LEGEND, "fail", "segmented control uses div role; use fieldset and legend")
        for node in q(
            document, "//*[contains(concat(' ',normalize-space(@class),' '),' seg ') and (self::div or @role='group' or @role='radiogroup')]"
        )
    )
    rows.extend(
        Row(artifact.path, line(node), Check.FIELDSET_LEGEND, "fail", "fieldset lacks legend") for node in q(document, "//fieldset[not(legend)]")
    )
    rows.extend(
        Row(artifact.path, line(node), Check.FORM_NAME, "warn", f"<{tag(node)}> capture control lacks name")
        for node in q(document, "//*[@form='capture-form' and (self::input or self::select or self::textarea)]")
        if not node.get("name")
    )
    rows.extend(
        Row(artifact.path, line(node), Check.OUTPUT_FOR, "warn", "output lacks for")
        for node in q(document, "//output[not(@for) and not(@id='toast') and not(@id='egress-meta')]")
    )
    return tuple(rows)


def reference_rows(artifact: Artifact) -> tuple[Row, ...]:
    rows = [
        Row(artifact.path, line(node), Check.EXTERNAL_REF, "fail", f"{tag(node)}[{attr}]={link[:120]}")
        for node, attr, link, _pos in artifact.document.iterlinks()
        if attr != "srcset" and bad_reference(link)
    ]
    rows.extend(
        Row(artifact.path, line(node), Check.EXTERNAL_REF, "fail", f"{tag(node)}[srcset]={url[:120]}")
        for node in q(artifact.document, "//*[@srcset]")
        for url in srcset_urls(str(node.get("srcset") or ""))
        if bad_reference(url)
    )
    rows.extend(
        Row(artifact.path, artifact.line_at(match.start()), Check.EXTERNAL_REF, "fail", f"css {match.group(1)[:120]}")
        for pattern in (CSS_URL, CSS_IMPORT)
        for match in pattern.finditer(artifact.css_flat)
        if bad_reference(match.group(1))
    )
    return tuple(rows)


# --- [GATE_CSS]


def css_plain(css: str) -> str:
    out: list[str] = []
    i, quoted, comment = 0, "", False
    while i < len(css):
        pair = css[i : i + 2]
        comment = False if comment and pair == "*/" else True if not quoted and pair == "/*" else comment
        if pair in {"/*", "*/"}:
            out.extend("  ")
            i += 2
            continue
        quoted = "" if quoted == css[i] and (i == 0 or css[i - 1] != "\\") else css[i] if not comment and not quoted and css[i] in "\"'" else quoted
        out.append(" " if comment or quoted else css[i])
        i += 1
    return "".join(out)


def css_structure_rows(artifact: Artifact) -> tuple[Row, ...]:
    """One brace-walk over the flattened CSS owns layer legality, the layer-name stack, and !important attribution.

    Returns:
        The unlayered-rule and stray-`!important` fail rows.
    """
    rows: list[Row] = []
    stack: list[str] = []
    plain = artifact.css_flat
    start = 0
    for index, char in enumerate(plain):
        if char == "{":
            prelude = plain[start:index].strip()
            named = LAYER_NAME.search(prelude)
            layered = bool(stack and stack[-1]) or prelude.startswith("@layer")
            if prelude and not prelude.startswith(STYLE_ALLOWED_AT_RULES) and not layered:
                rows.append(Row(artifact.path, artifact.line_at(index), Check.CSS_LAYER, "fail", f"unlayered rule {prelude[:80]}"))
            stack.append(named.group(1) if named else (stack[-1] if stack else ""))
            start = index + 1
        elif char == "}":
            if stack:
                stack.pop()
            start = index + 1
        elif char == "!" and plain[index : index + 10] == "!important":
            layer = stack[-1] if stack else ""
            if layer not in PRINT_SAFE_LAYERS:
                rows.append(Row(artifact.path, artifact.line_at(index), Check.IMPORTANT, "fail", f"!important inside layer '{layer or 'none'}'"))
    return tuple(rows)


def css_parse_rows(artifact: Artifact) -> tuple[Row, ...]:
    rules = tinycss2.parse_stylesheet(artifact.css, skip_comments=True, skip_whitespace=True)
    return tuple(
        Row(
            artifact.path,
            artifact.css_base + int(getattr(rule, "source_line", 1)) - 1,
            Check.CSS_LAYER,
            "fail",
            getattr(rule, "message", "css parse error"),
        )
        for rule in rules
        if getattr(rule, "type", "") == "error"
    )


def token_colors(plain: str) -> dict[str, Color]:
    values = {match["prop"]: match["value"].strip() for match in CSS_DECL.finditer(plain) if match["prop"].startswith("--")}

    def resolve(value: str, depth: int = 0) -> Color | None:
        if depth > 6:
            return None
        found = COLOR_REF.search(value)
        if found is None:
            return None
        if found.group(1):
            return resolve(values.get(found.group(1), ""), depth + 1)
        try:
            return Color(found.group(0))
        except ValueError:
            return None

    return {name: color for name, value in values.items() if (color := resolve(value)) is not None}


def composite(fg: Color, alpha: float, bg: Color) -> Color:
    """Alpha-composite `fg` at `alpha` over opaque `bg` in srgb — the color-mix-with-transparent fill a chip paints.

    Returns:
        The flattened opaque color.
    """
    top, base = fg.convert("srgb"), bg.convert("srgb")
    return Color("srgb", [alpha * t + (1 - alpha) * b for t, b in zip(top[:3], base[:3], strict=True)])


def contrast_rows(artifact: Artifact, colors: Mapping[str, Color]) -> tuple[Row, ...]:
    """Fold every token-pair contrast check — text-on-surface, on-accent, and status-chip-on-fill — through one table.

    Returns:
        The sub-threshold WCAG contrast fail rows.
    """
    return tuple(
        Row(
            artifact.path,
            artifact.css_base,
            Check.TOKEN_CONTRAST,
            "fail",
            f"{fg_name} chip ink on its {CHIP_ALPHA:.0%} fill contrast {score:.2f}"
            if alpha < 1.0
            else f"{fg_name} on {bg_name} contrast {score:.2f}",
        )
        for fg_name, bg_name, alpha in CONTRAST_CHECKS
        if (fg := colors.get(fg_name)) is not None
        if (bg := colors.get(bg_name)) is not None
        if (score := fg.contrast(composite(fg, alpha, bg) if alpha < 1.0 else bg, method="wcag21")) < MIN_CONTRAST
    )


def var_graph_rows(artifact: Artifact) -> tuple[Row, ...]:
    plain = artifact.css_flat
    defined = {match["prop"] for match in CSS_DECL.finditer(plain) if match["prop"].startswith("--")}
    defined |= {match.group(1) for match in PROP_DEF.finditer(plain)}
    uses: dict[str, bool] = {}
    for match in VAR_USE.finditer(artifact.text):
        name, has_fallback = match.group(1), bool(match.group(2))
        uses[name] = uses.get(name, False) or has_fallback
    js_writes = {match.group(1) for script in artifact.scripts for match in SET_PROPERTY.finditer(script.body)}
    rows = [
        Row(artifact.path, artifact.css_base, Check.VAR_GRAPH, "fail", f"var({name}) references an undefined property")
        for name, fallback in sorted(uses.items())
        if not fallback and name not in defined and name not in js_writes
    ]
    rows.extend(
        Row(artifact.path, artifact.css_base, Check.VAR_GRAPH, "warn", f"{name} defined but never read")
        for name in sorted(defined - set(uses) - js_writes)
        if not name.startswith("--series-")
    )
    return tuple(rows)


def css_rows(artifact: Artifact) -> tuple[Row, ...]:
    plain = artifact.css_flat
    rows = [*css_parse_rows(artifact), *css_structure_rows(artifact), *contrast_rows(artifact, token_colors(plain)), *var_graph_rows(artifact)]
    rows.extend(Row(artifact.path, artifact.line_at(match.start()), Check.SRGB_MIX, "fail", match.group(0)) for match in SRGB_MIX.finditer(plain))
    rows.extend(
        Row(artifact.path, artifact.line_at(match.start()), Check.RAW_HEX, "fail", f"{match['prop']}:{match['value'].strip()[:80]}")
        for match in CSS_DECL.finditer(plain)
        if HEX_COLOR.search(match["value"])
    )
    singles = (
        (":focus-visible" not in plain, Check.FOCUS_VISIBLE, "missing :focus-visible selector"),
        (bool(FOCUS_OUTLINE.search(plain)), Check.FOCUS_VISIBLE, "outline:none without same-rule focus replacement"),
        ("@media print" not in plain, Check.PRINT, "missing @media print"),
        ("export-bar" in artifact.text and not PRINT_EXPORT_BAR.search(plain), Check.PRINT, ".export-bar not hidden in print"),
    )
    rows.extend(Row(artifact.path, artifact.css_base, check, "fail", detail) for failed, check, detail in singles if failed)
    return tuple(rows)


# --- [GATE_JS]


def _js_node_rows(artifact: Artifact, script: Script, node: Node, *, sink: bool) -> Iterator[Row]:
    body = script.body
    at = script.line + node.start_point[0]
    if sink and node.type in {"string", "template_string"} and REMOTE_LITERAL.search(body[node.start_byte : node.end_byte].strip("`'\"")):
        yield Row(artifact.path, at, Check.JS_SINK, "fail", body[node.start_byte : node.end_byte][:120])
    if node.type == "assignment_expression":
        target = node.child_by_field_name("left")
        value = node.child_by_field_name("right")
        prop = body[target.start_byte : target.end_byte] if target else ""
        if prop.endswith((".innerHTML", ".outerHTML")) and value is not None and value.type != "string":
            yield Row(artifact.path, at, Check.INNER_HTML, "fail", prop.rsplit(".", 1)[-1] + " assigned non-literal markup")
    if node.type == "call_expression":
        callee = node.child_by_field_name("function")
        if callee is not None and body[callee.start_byte : callee.end_byte].endswith(".insertAdjacentHTML"):
            yield Row(artifact.path, at, Check.INNER_HTML, "fail", "insertAdjacentHTML on dynamic markup")


def js_tree_rows(artifact: Artifact, script: Script) -> tuple[Row, ...]:
    tree = _js_parser().parse(script.body.encode("utf-8"))
    rows = [Row(artifact.path, script.line, Check.JS_SYNTAX, "fail", "tree-sitter parse error")] if tree.root_node.has_error else []
    body = script.body
    stack: list[tuple[Node, bool]] = [(tree.root_node, False)]
    while stack:  # Exemption: iterative AST frontier — input-scaled JS nesting overflows native recursion.
        node, sink = stack.pop()
        active = (
            sink
            or (node.type in {"call_expression", "new_expression"} and bool(SCRIPT_SINK_TEXT.search(body[node.start_byte : node.start_byte + 96])))
            or node.type == "import_call"
        )
        rows.extend(_js_node_rows(artifact, script, node, sink=active))
        stack.extend((child, active) for child in node.children)
    rows.extend(
        Row(
            artifact.path,
            script.line + script.body[: match.start()].count("\n"),
            Check.JS_LEGACY,
            "fail",
            "document.execCommand is dead; the kernel copy chain owns egress",
        )
        for match in EXEC_COMMAND.finditer(script.body)
    )
    return tuple(rows)


def script_rows(artifact: Artifact) -> tuple[Row, ...]:
    executable = tuple(script for script in artifact.scripts if script.kind is ScriptKind.EXECUTABLE)
    rows = [] if len(executable) == 1 else [Row(artifact.path, 1, Check.SCRIPT_COUNT, "fail", f"{len(executable)} executable scripts")]
    for script in artifact.scripts:
        if script.kind is ScriptKind.PAYLOAD:
            try:
                decoded = DEC_PAYLOAD.decode(script.body.encode("utf-8"))
                if not isinstance(decoded, (dict, list)):
                    rows.append(Row(artifact.path, script.line, Check.EMBEDDED_STATE, "fail", "payload is not an object or array"))
            except msgspec.DecodeError as exc:
                rows.append(Row(artifact.path, script.line, Check.EMBEDDED_STATE, "fail", str(exc).splitlines()[0][:120]))
        else:
            rows.extend(js_tree_rows(artifact, script))
        if SCRIPT_HAZARD.search(script.body):
            rows.append(Row(artifact.path, script.line, Check.SCRIPT_HAZARD, "warn", "raw U+2028/U+2029 line separator"))
    return tuple(rows)


# --- [GATE_AUDIT]


@beartype
def audit(path: Path) -> tuple[Row, ...]:
    result = Artifact.from_path(path)
    if result.is_error():
        return (result.error,)
    artifact = result.ok
    titles = q(artifact.document, "//title")
    styles = q(artifact.document, "/html/head/style")
    base = (
        (bool(DOCTYPE.match(artifact.text)), Check.DOCTYPE, "missing <!doctype html>"),
        (bool(titles and text(titles[0])), Check.TITLE, "empty or missing <title>"),
        (len(styles) == 1, Check.STYLE_COUNT, f"{len(styles)} document style blocks"),
    )
    rows = [Row(artifact.path, 1, check, "fail", detail) for ok, check, detail in base if not ok]
    rows.extend(dom_rows(artifact) + reference_rows(artifact) + css_rows(artifact) + script_rows(artifact))
    if artifact.raw_size > SIZE_WARN:
        rows.append(Row(artifact.path, 1, Check.SIZE, "warn", f"{artifact.raw_size // 1024}KB > {SIZE_WARN // 1024}KB"))
    rows.extend(
        Row(artifact.path, number, check, "warn", detail)
        for number, value in enumerate(artifact.text.splitlines(), 1)
        for check, pattern, detail in (
            (Check.RESIDUE, RESIDUE, "unfilled {{...}} template placeholder remains"),
            (Check.SECRET, SECRET, "credential-shaped literal"),
        )
        if pattern.search(value) and not (check is Check.SECRET and ";base64," in value)
    )
    return tuple(sorted(rows, key=lambda row: (row.line, row.check, row.detail)))


def conformance_rows(path: Path) -> tuple[Row, ...]:
    """W3C `vnu` HTML5 structural conformance over one page.

    Returns:
        The conformance rows, or a single skip/unparseable warn row. `info` maps warn, all else fail.
    """
    if shutil.which("vnu") is None:
        return (Row(str(path), 0, Check.CONFORMANCE, "warn", "vnu not on PATH: conformance skipped"),)
    try:
        proc = subprocess.run(
            ["vnu", "--format", "json", "--stdout", str(path)], capture_output=True, text=True, check=False, timeout=SUBPROCESS_TIMEOUT["vnu"]
        )
    except subprocess.TimeoutExpired:
        return (Row(str(path), 0, Check.CONFORMANCE, "warn", f"vnu stalled past {SUBPROCESS_TIMEOUT['vnu']:.0f}s: conformance skipped"),)
    if not (stdout := proc.stdout.strip()):
        return (
            () if proc.returncode == 0 else (Row(str(path), 0, Check.CONFORMANCE, "warn", f"vnu emitted no output (returncode {proc.returncode})"),)
        )
    try:
        report = DEC_VNU.decode(stdout.encode("utf-8"))
    except msgspec.DecodeError:
        return (Row(str(path), 0, Check.CONFORMANCE, "warn", f"vnu output unparseable (returncode {proc.returncode})"),)
    # Drop two vnu lanes: CSS messages (tinycss2 owns CSS here) and XML-1.0 mappability (these pages are HTML5 from file://, never XML/XHTML).
    return tuple(
        Row(str(path), message.last_line, Check.CONFORMANCE, "warn" if message.type == "info" else "fail", message.message[:120])
        for message in report.messages
        if not message.message.startswith("CSS:") and "not mappable to XML" not in message.message
    )


# --- [SERVER_OPS]


def _utc() -> str:
    return datetime.now(UTC).isoformat(timespec="seconds")


def _state_path(session: str) -> Path:
    return Path(tempfile.gettempdir()) / f"html-studio-server-{session}.json"


@beartype
def admit_artifact(path: Path) -> Result[Path, Fault]:
    resolved = path.resolve()
    admitted = resolved.suffix == ".html" and resolved.is_file()
    return Ok(resolved) if admitted else Error(Fault(FaultKind.BAD_ARTIFACT, str(resolved)))


@beartype
def fresh_page(artifact: Path, token: str) -> Result[bytes, Fault]:
    """Serve-time page: committed return-channel metas stripped, one fresh pair injected after `<head>`.

    Returns:
        The served bytes or the structural fault.
    """
    try:
        raw = artifact.read_bytes()
    except OSError as exc:
        return Error(Fault(FaultKind.BAD_ARTIFACT, type(exc).__name__))
    heads = HEAD_OPEN.findall(raw)
    if len(heads) != 1:
        return Error(Fault(FaultKind.BAD_ARTIFACT, f"{len(heads)} <head> elements"))
    raw = RETURN_METAS.sub(b"", raw)
    match = HEAD_OPEN.search(raw)
    if match is None:
        return Error(Fault(FaultKind.BAD_ARTIFACT, "no <head>"))
    meta = f'<meta name="artifact-return" content="/submit"><meta name="artifact-token" content="{token}">'.encode()
    return Ok(raw[: match.end()] + meta + raw[match.end() :])


def read_state(state_file: Path) -> Result[ServerState | None, Fault]:
    if not state_file.is_file():
        return Ok(None)
    try:
        return Ok(DEC_STATE.decode(state_file.read_bytes()))
    except (OSError, msgspec.DecodeError) as exc:
        return Error(Fault(FaultKind.STATE_UNREADABLE, f"{state_file}: {type(exc).__name__}"))


def live_process(state: ServerState) -> psutil.Process | None:
    try:
        process = psutil.Process(state.pid)
        with process.oneshot():
            return process if process.is_running() and abs(process.create_time() - state.create_time) < 1.0 else None
    except psutil.NoSuchProcess, psutil.ZombieProcess, psutil.AccessDenied:
        return None


def write_state(state_file: Path, state: ServerState) -> None:
    scratch = state_file.with_suffix(".tmp")
    scratch.write_bytes(ENC.encode(state))
    scratch.chmod(0o600)
    scratch.replace(state_file)


def emit(output: Output, mode: OutputMode) -> None:
    if mode is OutputMode.JSON:
        print(ENC.encode(output).decode())
    else:
        pairs = (
            ("URL", output.url),
            ("ARTIFACT", output.artifact),
            ("RECEIPTS", output.receipts),
            ("STATE", output.state),
            ("RECEIPT_COUNT", str(output.receipt_count or "")),
            ("DETAIL", output.detail),
        )
        print("\n".join((f"STATUS={output.status}", *(f"{key}={value}" for key, value in pairs if value))))
    sys.stdout.flush()


def fail(fault: Fault, mode: OutputMode) -> int:
    emit(Output(status="ERROR", detail=f"{fault.kind}: {fault.detail}".strip(": ")), mode)
    return int(fault_policy(fault.kind).exit)


def make_handler(runtime: Runtime) -> type[BaseHTTPRequestHandler]:
    class Handler(BaseHTTPRequestHandler):
        @override
        def log_message(self, format: str, *args: object) -> None:
            del format, args

        def _respond(self, code: int, body: bytes, ctype: str) -> None:
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("Referrer-Policy", "no-referrer")
            self.end_headers()
            self.wfile.write(body)

        def _fault(self, fault: Fault) -> None:
            LOG.warning("request.rejected", fault=fault.kind, detail=fault.detail)
            self._respond(fault_policy(fault.kind).http, ENC.encode(Reply(ok=False, fault=fault.kind)), "application/json")

        def _token_ok(self) -> bool:
            return hmac.compare_digest(self.headers.get("X-Artifact-Token", ""), runtime.token)

        def _gate(self) -> Fault | None:
            host = (self.headers.get("Host") or "").rsplit(":", 1)[0]
            origin = self.headers.get("Origin", "")
            checks = (
                Fault(FaultKind.BAD_HOST, host) if host not in LOOPBACK else None,
                Fault(FaultKind.BAD_ORIGIN, origin) if origin and urlsplit(origin).hostname not in LOOPBACK else None,
            )
            return next((fault for fault in checks if fault), None)

        def do_GET(self) -> None:
            route = urlsplit(self.path).path
            if fault := self._gate():
                return self._fault(fault)
            if route in {"/", "/index.html"}:
                page = fresh_page(runtime.artifact, runtime.token)
                return self._respond(200, page.ok, "text/html; charset=utf-8") if page.is_ok() else self._fault(page.error)
            if route == "/receipts":
                if not self._token_ok():
                    return self._fault(Fault(FaultKind.BAD_TOKEN))
                body = runtime.receipts.read_bytes() if runtime.receipts.is_file() else b""
                return self._respond(200, body, "application/x-ndjson")
            return self._fault(Fault(FaultKind.NOT_FOUND, route))

        def do_POST(self) -> None:
            length = self.headers.get("Content-Length", "")
            checks = (
                self._gate(),
                Fault(FaultKind.NOT_FOUND, self.path) if urlsplit(self.path).path != "/submit" else None,
                Fault(FaultKind.BAD_TOKEN) if not self._token_ok() else None,
                Fault(FaultKind.BAD_TYPE) if not (self.headers.get("Content-Type") or "").startswith("application/json") else None,
                Fault(FaultKind.BAD_LENGTH, length) if not length.isdigit() else None,
                Fault(FaultKind.OVERSIZE, length) if length.isdigit() and not 0 < int(length) <= MAX_BODY else None,
            )
            if fault := next((fault for fault in checks if fault), None):
                runtime.sink.event(EventKind.REJECTED, fault.kind)
                return self._fault(fault)
            raw = self.rfile.read(int(length))
            try:
                envelope = DEC_ENVELOPE.decode(raw)
            except msgspec.ValidationError as exc:
                runtime.sink.event(EventKind.REJECTED, FaultKind.BAD_ENVELOPE)
                return self._fault(Fault(FaultKind.BAD_ENVELOPE, str(exc)[:120]))
            except msgspec.DecodeError as exc:
                runtime.sink.event(EventKind.REJECTED, FaultKind.BAD_JSON)
                return self._fault(Fault(FaultKind.BAD_JSON, str(exc)[:120]))
            row = ReceiptRow(
                id=(digest := xxh3_128_hexdigest(raw)),
                received=_utc(),
                kind=envelope.kind,
                artifact=envelope.artifact,
                payload=envelope.data,
                wrapper_digest=digest,
            )
            try:
                runtime.sink.append(row)
            except OSError as exc:
                return self._fault(Fault(FaultKind.RECEIPT_IO, type(exc).__name__))
            LOG.info("submission.received", id=row.id, kind=row.kind)
            return self._respond(200, ENC.encode(Reply(ok=True, id=row.id)), "application/json")

    return Handler


async def supervise(server: ThreadingHTTPServer, runtime: Runtime, ttl: float | None) -> None:
    async def signals(scope: anyio.CancelScope) -> None:
        with anyio.open_signal_receiver(SIGTERM, SIGINT) as stream:
            async for _ in stream:
                scope.cancel()
                return

    async def watch() -> None:
        async for _ in watchfiles.awatch(runtime.artifact):
            page = APath(runtime.artifact)
            digest = xxh3_128_hexdigest(await page.read_bytes()) if await page.is_file() else "deleted"
            runtime.sink.event(EventKind.CHANGED, digest)
            LOG.info("artifact.changed", digest=digest)

    async def expiry(scope: anyio.CancelScope, seconds: float) -> None:
        await anyio.sleep(seconds)
        runtime.sink.event(EventKind.TTL_EXPIRED, f"{seconds}s")
        scope.cancel()

    async with anyio.create_task_group() as tg:
        _ = tg.start_soon(partial(anyio.to_thread.run_sync, server.serve_forever, abandon_on_cancel=True))
        _ = tg.start_soon(signals, tg.cancel_scope)
        _ = tg.start_soon(watch)
        if ttl:
            _ = tg.start_soon(expiry, tg.cancel_scope, ttl)
    server.shutdown()
    server.server_close()
    runtime.sink.event(EventKind.STOPPED, "supervisor exit")


# --- [COMPOSITION] ----------------------------------------------------------------------


def gate(paths: Annotated[Sequence[Path], Parameter(name="paths")], *, json: bool = False) -> int:
    """Static artifact gate: structure, self-containment, tokens, contrast, script audit, conformance.

    Returns:
        Process exit code from the closed `Exit` vocabulary.
    """
    rows = tuple(
        row
        for path in paths
        for row in (audit(path) + conformance_rows(path) if path.is_file() else (Row(str(path), 0, Check.READ, "fail", "not a readable file"),))
    )
    for row in rows:
        emit_row(row, json)
    return int(Exit.GATE) if any(row.status == "fail" for row in rows) else int(Exit.OK)


def render(artifact: Path, *, out: Path | None = None, json: bool = False) -> int:
    """Headless-render an artifact to PNG through the pinned Chromium, surfacing console/page failures.

    Returns:
        Process exit code from the closed `Exit` vocabulary.
    """
    target = out or artifact.with_suffix(".png")
    try:
        proc = subprocess.run(
            ["uv", "run", "--with", "playwright", "python", "-", str(artifact.resolve()), str(target)],
            input=RENDER_SCRIPT,
            capture_output=True,
            text=True,
            check=False,
            timeout=SUBPROCESS_TIMEOUT["render"],
        )
    except subprocess.TimeoutExpired:
        emit_row(Row(str(artifact), 0, Check.RENDER, "fail", f"render stalled past {SUBPROCESS_TIMEOUT['render']:.0f}s"), json)
        return int(Exit.GATE)

    def render_status(kind: str) -> Status | None:
        return "fail" if kind in {"error", "pageerror"} else "warn" if kind == "warning" else None

    rows = [
        Row(str(artifact), 0, Check.RENDER, status, f"{kind}: {detail}")
        for report_line in proc.stdout.splitlines()
        for kind, _, detail in (report_line.partition("\t"),)
        if (status := render_status(kind)) is not None
    ]
    if proc.returncode != 0 and not rows:
        rows.append(Row(str(artifact), 0, Check.RENDER, "fail", proc.stderr.strip()[-240:] or "render subprocess failed"))
    for row in rows:
        emit_row(row, json)
    print(f"SCREENSHOT={target}")
    return int(Exit.GATE) if proc.returncode != 0 else int(Exit.OK)


def serve(
    artifact: Path,
    *,
    port: int = 0,
    receipts: Path | None = None,
    ttl: float | None = None,
    output: OutputMode = OutputMode.BANNER,
    open_page: Annotated[bool, Parameter(name="--open")] = False,
    session: Session = "no-session",
) -> int:
    """Host one artifact with an injected return channel until stopped, TTL, or signal.

    Returns:
        Process exit code from the closed `Exit` vocabulary.
    """
    admitted = admit_artifact(artifact)
    if admitted.is_error():
        return fail(admitted.error, output)
    resolved = admitted.ok
    state_file = _state_path(session)
    state = read_state(state_file)
    if state.is_error():
        return fail(state.error, output)
    if state.ok is not None and live_process(state.ok):
        return fail(Fault(FaultKind.STATE_BUSY, f"pid {state.ok.pid} live at port {state.ok.port}"), output)
    if state.ok is not None:
        state_file.unlink(missing_ok=True)
        LOG.info("state.stale-healed", pid=state.ok.pid)
    token = token_hex(16)
    probe = fresh_page(resolved, token)
    if probe.is_error():
        return fail(probe.error, output)
    receipt_path = (receipts or resolved.with_suffix(".receipts.jsonl")).resolve()
    receipt_path.parent.mkdir(parents=True, exist_ok=True)
    runtime = Runtime(artifact=resolved, token=token, receipts=receipt_path, sink=Sink(receipt_path))
    try:
        server = ThreadingHTTPServer((HOST, port), make_handler(runtime))
    except OSError as exc:
        return fail(Fault(FaultKind.PORT_BUSY, str(exc)), output)
    me = psutil.Process()
    bound = int(server.server_address[1])
    write_state(
        state_file,
        ServerState(
            version=2,
            pid=me.pid,
            create_time=me.create_time(),
            port=bound,
            artifact=str(resolved),
            artifact_digest=xxh3_128_hexdigest(resolved.read_bytes()),
            receipts=str(receipt_path),
            started_at=_utc(),
            token_digest=hashlib.sha256(token.encode()).hexdigest(),
        ),
    )
    runtime.sink.event(EventKind.STARTED, f"port {bound}")
    emit(Output(status="ACTIVE", url=f"http://{HOST}:{bound}/", artifact=str(resolved), receipts=str(receipt_path), state=str(state_file)), output)
    if open_page:
        webbrowser.open(f"http://{HOST}:{bound}/")
    try:
        anyio.run(supervise, server, runtime, ttl)
    finally:
        state_file.unlink(missing_ok=True)
    return int(Exit.OK)


def status(*, output: OutputMode = OutputMode.BANNER, session: Session = "no-session") -> int:
    """Report liveness-proven server state and receipt count.

    Returns:
        Process exit code from the closed `Exit` vocabulary.
    """
    state_file = _state_path(session)
    state = read_state(state_file)
    if state.is_error():
        return fail(state.error, output)
    if state.ok is None:
        emit(Output(status="INACTIVE"), output)
        return int(Exit.OK)
    if live_process(state.ok) is None:
        state_file.unlink(missing_ok=True)
        emit(Output(status="STALE", state=str(state_file), detail=f"pid {state.ok.pid} gone; state retired"), output)
        return int(Exit.OK)
    count = sum(1 for row in Sink(Path(state.ok.receipts)).rows() if isinstance(row, ReceiptRow))
    emit(
        Output(
            status="ACTIVE",
            url=f"http://{HOST}:{state.ok.port}/",
            artifact=state.ok.artifact,
            receipts=state.ok.receipts,
            state=str(state_file),
            receipt_count=count,
        ),
        output,
    )
    return int(Exit.OK)


def stop(*, grace: float = 2.0, output: OutputMode = OutputMode.BANNER, session: Session = "no-session") -> int:
    """Terminate the liveness-proven server; never signal an unmatched pid.

    Returns:
        Process exit code from the closed `Exit` vocabulary.
    """
    state_file = _state_path(session)
    state = read_state(state_file)
    if state.is_error():
        return fail(state.error, output)
    if state.ok is None:
        emit(Output(status="INACTIVE"), output)
        return int(Exit.OK)
    process = live_process(state.ok)
    if process is None:
        state_file.unlink(missing_ok=True)
        emit(Output(status="STALE", detail="state retired without signal"), output)
        return int(Exit.OK)
    process.terminate()
    try:
        process.wait(timeout=grace)
    except psutil.TimeoutExpired:
        return fail(Fault(FaultKind.STOP_TIMEOUT, f"pid {process.pid} alive after {grace}s"), output)
    state_file.unlink(missing_ok=True)
    emit(Output(status="STOPPED", receipts=state.ok.receipts), output)
    return int(Exit.OK)


def receipts(path: Path, *, last: int = 1, kind: str = "", json: bool = False) -> int:
    """Print the newest receipt rows from a receipts stream; the agent's canonical read.

    Returns:
        Process exit code from the closed `Exit` vocabulary.
    """
    rows = [row for row in Sink(path).rows() if isinstance(row, ReceiptRow) and (not kind or row.kind == kind)]
    for row in rows[-last:] if last else rows:
        print(ENC.encode(row).decode() if json else f"{row.received} {row.kind} {row.id} {bytes(row.payload).decode()}")
    return int(Exit.OK)


def self_test() -> int:
    """Prove artifact -> serve -> GET -> POST -> reject -> receipt readback -> stop.

    Returns:
        Process exit code from the closed `Exit` vocabulary.
    """

    async def circuit() -> Fault | None:
        scratch = APath(tempfile.mkdtemp(prefix="html-studio-selftest-")) / "probe.html"
        await scratch.write_text(
            '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
            "<title>Self-test probe</title>\n<style>:root{color-scheme:dark light}</style>\n</head>\n"
            "<body><main><h1>probe</h1></main><script>const probe=1;</script></body>\n</html>\n"
        )
        env = dict(os.environ) | {"CLAUDE_CODE_SESSION_ID": f"selftest-{os.getpid()}"}
        process = await anyio.open_process([sys.executable, str(APath(__file__)), "serve", str(scratch), "--output", "json"], env=env)
        try:
            stdout = process.stdout
            if stdout is None:
                return Fault(FaultKind.SELF_TEST, "subprocess stdout not piped")
            banner = msgspec.json.decode(await stdout.receive(), type=Output)

            async def fetch(client: httpx.AsyncClient) -> httpx.Response:
                async for attempt in stamina.retry_context(on=httpx.TransportError, attempts=8, timeout=10.0):
                    with attempt:
                        return await client.get(banner.url)
                raise httpx.TransportError("server never became reachable")

            async with httpx.AsyncClient(timeout=httpx.Timeout(5.0)) as client:
                served = await fetch(client)
                token_match = TOKEN_META_RE.search(served.text)
                if token_match is None:
                    return Fault(FaultKind.SELF_TEST, "token meta missing from served page")
                if served.text.count('<meta name="artifact-return"') != 1:
                    return Fault(FaultKind.SELF_TEST, "served page carries a duplicated return meta")
                headers = {"X-Artifact-Token": token_match.group(1), "Content-Type": "application/json"}
                data = {"probe": True, "at": _utc()}
                envelope = {"kind": "self-test", "artifact": "probe", "version": 1, "data": data}
                posted = await client.post(f"{banner.url}submit", content=ENC.encode(envelope), headers=headers)
                reply = msgspec.json.decode(posted.content, type=Reply)
                if posted.status_code != 200 or not reply.ok:
                    return Fault(FaultKind.SELF_TEST, f"submit failed: {posted.status_code}")
                bad = await client.post(f"{banner.url}submit", content=b"{}", headers=headers | {"X-Artifact-Token": "0" * 32})
                if bad.status_code != 403:
                    return Fault(FaultKind.SELF_TEST, f"bad token accepted: {bad.status_code}")
                stream = await client.get(f"{banner.url}receipts", headers=headers)
                rows = list(DEC_ROW.decode_lines(stream.content))
                receipt = next((row for row in rows if isinstance(row, ReceiptRow) and row.id == reply.id), None)
                if receipt is None:
                    return Fault(FaultKind.SELF_TEST, "receipt row missing from readback")
                if msgspec.json.decode(bytes(receipt.payload)) != data:
                    return Fault(FaultKind.SELF_TEST, "receipt payload is not the canonical data envelope")
        finally:
            _ = catch(exception=ProcessLookupError)(process.terminate)()  # already-dead child terminate is a benign miss
            await process.wait()
        return None

    fault = anyio.run(circuit)
    if fault is not None:
        return fail(fault, OutputMode.BANNER)
    print("STATUS=SELF_TEST_OK")
    return int(Exit.OK)


# --- [ENTRY] ----------------------------------------------------------------------------

app = App(name="studio", result_action="return_int_as_exit_code_else_zero")
app.command(gate)
app.command(render)
app.command(serve)
app.command(status)
app.command(stop)
app.command(receipts)
app.command(self_test, name="self-test")

if __name__ == "__main__":
    sys.exit(app())
