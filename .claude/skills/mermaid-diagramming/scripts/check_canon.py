#!/usr/bin/env python3
# /// script
# requires-python = ">=3.13"
# dependencies = ["cyclopts", "msgspec", "ruamel.yaml"]
# ///
"""Enforce the Dracula theme and style canon on Mermaid fences through one table-driven per-family rule registry."""

# ruff: noqa: T201, D101, D103

# --- [RUNTIME_PRELUDE] ---------------------------------------------------------------------

from collections.abc import Mapping
from enum import StrEnum
from pathlib import Path
import re
import sys
from typing import Literal, TypeIs

from cyclopts import App
import msgspec
from ruamel.yaml import YAML
from ruamel.yaml.error import YAMLError


# --- [TYPES] -------------------------------------------------------------------------------

type Level = Literal["fail", "warn"]


class Fam(StrEnum):
    ARCHITECTURE = "architecture"
    BLOCK = "block"
    C4 = "c4"
    CLASS = "class"
    CYNEFIN = "cynefin"
    ER = "er"
    EVENTMODELING = "eventmodeling"
    FLOWCHART = "flowchart"
    GANTT = "gantt"
    GITGRAPH = "gitgraph"
    ISHIKAWA = "ishikawa"
    JOURNEY = "journey"
    KANBAN = "kanban"
    MINDMAP = "mindmap"
    PACKET = "packet"
    PIE = "pie"
    QUADRANT = "quadrant"
    RADAR = "radar"
    RAILROAD = "railroad"
    REQUIREMENT = "requirement"
    SANKEY = "sankey"
    SEQUENCE = "sequence"
    STATE = "state"
    SWIMLANE = "swimlane"
    TIMELINE = "timeline"
    TREEMAP = "treemap"
    TREEVIEW = "treeview"
    VENN = "venn"
    WARDLEY = "wardley"
    XYCHART = "xychart"


class Surface(StrEnum):
    FM = "fm"  # config path equals expect (tuple expect = membership)
    FM_ANY = "fm-any"  # config path present, any value
    FM_VALUE = "fm-value"  # config path, when present, equals expect
    FM_NONE = "fm-none"  # config path must be absent
    CSS = "css"  # themeCSS carries the verbatim stamp substring
    BODY = "body"  # body matches the pattern
    BODY_NONE = "body-none"  # body must not match the pattern
    DERIVED = "derived"  # analyzer-owned; the row carries id, level, and canon text


class Cond(StrEnum):
    ALWAYS = "always"
    ACTIVE = "active"
    ASYNC = "async"
    AUTONUMBER = "autonumber"
    BAR = "bar"
    COMPOSITE = "composite"
    CONTAINS = "contains"
    CRIT = "crit"
    DATALABEL = "datalabel"
    DESCRIPTION = "description"
    DONE = "done"
    DOTTED_REL = "dotted-rel"
    EDGE_LABEL = "edge-label"
    EVOLVE = "evolve"
    EXCLUDES = "excludes"
    HIGHLIGHT = "highlight"
    NAMESPACE = "namespace"
    NESTED_BLOCK = "nested-block"
    NOTE_CLASS = "note-class"
    PERSON = "person"
    PRIORITY = "priority"
    REGION = "region"
    SECTION = "section"
    SUBGRAPH = "subgraph"
    TAG = "tag"
    TERMINAL = "terminal"
    TITLE = "title"


# --- [CONSTANTS] ---------------------------------------------------------------------------

FAIL: Level = "fail"
WARN: Level = "warn"
MISSING = object()
SUFFIXES = frozenset({".md", ".mmd"})

DARKER = "#21222C"
CANVAS = "#282A36"
SELECTION = "#44475A"
COMMENT = "#6272A4"
FOREGROUND = "#F8F8F2"
LAVENDER = "#D6BCFA"
PINK = "#FF79C6"
PURPLE = "#BD93F9"
GOLD = "#FFD866"
RED = "#FF5555"
GREEN = "#50FA7B"
CYAN = "#8BE9FD"
ORANGE = "#FFB86C"

FONT_STACK = "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
PALETTE = frozenset({
    DARKER,
    CANVAS,
    SELECTION,
    COMMENT,
    FOREGROUND,
    LAVENDER,
    PINK,
    PURPLE,
    GOLD,
    RED,
    GREEN,
    CYAN,
    ORANGE,
    "#036A96",
    "#14710A",
    "#1F1F1F",
    "#644AC9",
    "#6C664B",
    "#846E15",
    "#A3144D",
    "#A34D14",
    "#CB3A2A",
    "#CFCFDE",
    "#FFFBEB",
})
ENGINE_HOOKS = frozenset({"#444444"})
ENGINE_HOOKS_SHORT = frozenset({"#666"})
WASH_ALPHAS = frozenset({"1A", "26", "33", "4D"})
CHIP_ALPHAS: dict[str, frozenset[str]] = {
    GREEN: frozenset({"66", "BF"}),
    CYAN: frozenset({"66", "BF"}),
    ORANGE: frozenset({"66", "BF"}),
    PINK: frozenset({"80"}),
    PURPLE: frozenset({"80"}),
    RED: frozenset({"80"}),
    GOLD: frozenset({"54"}),
}
ACCENTS = frozenset(CHIP_ALPHAS)
YELLOW_INK_PAIRS = (
    ("tagLabelBackground", "tagLabelColor"),
    ("noteBkgColor", "noteTextColor"),
    ("terminalFill", "terminalTextColor"),
    ("highlightBg", "labelColor"),
)
EM_KINDS = {"ui": "emUi", "cmd": "emCommand", "evt": "emEvent", "pcr": "emProcessor", "rmo": "emReadModel"}
KANBAN_RANGE = 8
JOURNEY_FILLS = 8
JOURNEY_ACTORS = 6

HEADER_FAMILY: dict[str, Fam] = {
    "flowchart": Fam.FLOWCHART,
    "graph": Fam.FLOWCHART,
    "swimlane-beta": Fam.SWIMLANE,
    "sequenceDiagram": Fam.SEQUENCE,
    "stateDiagram": Fam.STATE,
    "stateDiagram-v2": Fam.STATE,
    "classDiagram": Fam.CLASS,
    "erDiagram": Fam.ER,
    "gantt": Fam.GANTT,
    "mindmap": Fam.MINDMAP,
    "block": Fam.BLOCK,
    "block-beta": Fam.BLOCK,
    "journey": Fam.JOURNEY,
    "requirementDiagram": Fam.REQUIREMENT,
    "pie": Fam.PIE,
    "quadrantChart": Fam.QUADRANT,
    "sankey": Fam.SANKEY,
    "sankey-beta": Fam.SANKEY,
    "xychart": Fam.XYCHART,
    "xychart-beta": Fam.XYCHART,
    "radar-beta": Fam.RADAR,
    "treemap": Fam.TREEMAP,
    "treemap-beta": Fam.TREEMAP,
    "C4Context": Fam.C4,
    "C4Container": Fam.C4,
    "C4Component": Fam.C4,
    "C4Dynamic": Fam.C4,
    "C4Deployment": Fam.C4,
    "architecture-beta": Fam.ARCHITECTURE,
    "packet": Fam.PACKET,
    "packet-beta": Fam.PACKET,
    "timeline": Fam.TIMELINE,
    "gitGraph": Fam.GITGRAPH,
    "kanban": Fam.KANBAN,
    "treeView-beta": Fam.TREEVIEW,
    "venn-beta": Fam.VENN,
    "wardley-beta": Fam.WARDLEY,
    "cynefin-beta": Fam.CYNEFIN,
    "railroad-beta": Fam.RAILROAD,
    "railroad-ebnf-beta": Fam.RAILROAD,
    "railroad-abnf-beta": Fam.RAILROAD,
    "railroad-peg-beta": Fam.RAILROAD,
    "eventmodeling": Fam.EVENTMODELING,
    "ishikawa-beta": Fam.ISHIKAWA,
}

BLOCKQUOTE = re.compile(r"^\s*(?:>\s?)+")
FENCE_OPEN = re.compile(r"^((?:\s*>)*\s*)(`{3,}|~{3,})\s*mermaid\b")
HEX_SCAN = re.compile(r"#[0-9A-Fa-f]{8}\b|#[0-9A-Fa-f]{6}\b|#[0-9A-Fa-f]{3}\b")
CSS_BLOCK = re.compile(r"([^{}]+)\{([^{}]*)\}")
CLASSDEF_LINE = re.compile(r"^\s*classDef\s+([\w,-]+)\s+(.+)$")
STYLE_LINE = re.compile(r"^\s*(?:style|linkStyle)\s+\S+\s+(.+)$")
VENN_STYLE_LINE = re.compile(r"^\s*style\s+[\w,\s]+\s+(fill.*)$")
FILL_OPAQUE_ACCENT = re.compile(r"fill:\s*#(50FA7B|8BE9FD|FFB86C|FFD866|FF5555|BD93F9|FF79C6)(?![0-9A-Fa-f])", re.IGNORECASE)
FONT_HYPHEN = re.compile(r"fontFamily[^\n]*?[\"']?[^\"',\n]*\w-\w")
DEPRECATED_INIT = re.compile(r"%%\{\s*init\s*:")
HEX8 = re.compile(r"#[0-9A-Fa-f]{8}\b")

CONDITIONS: dict[Cond, tuple[re.Pattern[str], str]] = {
    Cond.ACTIVE: (re.compile(r":\s*active\b|,\s*active\b"), "body"),
    Cond.ASYNC: (re.compile(r"--?\)"), "body"),
    Cond.AUTONUMBER: (re.compile(r"^\s*autonumber\b", re.MULTILINE), "body"),
    Cond.BAR: (re.compile(r"^\s*bar\s*\[", re.MULTILINE), "body"),
    Cond.COMPOSITE: (re.compile(r"^\s*state\s+\S.*\{", re.MULTILINE), "body"),
    Cond.CONTAINS: (re.compile(r"-\s*contains\s*->|<-\s*contains\s*-"), "body"),
    Cond.CRIT: (re.compile(r":\s*crit\b|,\s*crit\b"), "body"),
    Cond.DATALABEL: (re.compile(r"showDataLabel:\s*true"), "fm"),
    Cond.DESCRIPTION: (re.compile(r"##"), "body"),
    Cond.DONE: (re.compile(r":\s*done\b|,\s*done\b"), "body"),
    Cond.DOTTED_REL: (re.compile(r"\.\."), "body"),
    Cond.EDGE_LABEL: (re.compile(r"\||--\s+\""), "body"),
    Cond.EVOLVE: (re.compile(r"^\s*evolve\s", re.MULTILINE), "body"),
    Cond.EXCLUDES: (re.compile(r"^\s*excludes\s", re.MULTILINE), "body"),
    Cond.HIGHLIGHT: (re.compile(r":::highlight\b"), "body"),
    Cond.NAMESPACE: (re.compile(r"^\s*namespace\s", re.MULTILINE), "body"),
    Cond.NESTED_BLOCK: (re.compile(r"^\s*block:", re.MULTILINE), "body"),
    Cond.NOTE_CLASS: (re.compile(r"^\s*note\s", re.MULTILINE), "body"),
    Cond.PERSON: (re.compile(r"^\s*Person(_Ext)?\(", re.MULTILINE), "body"),
    Cond.PRIORITY: (re.compile(r"priority"), "body"),
    Cond.REGION: (re.compile(r"^\s*(alt|opt|par|critical|break|loop)\b", re.MULTILINE), "body"),
    Cond.SECTION: (re.compile(r"^\s*section\s", re.MULTILINE), "body"),
    Cond.SUBGRAPH: (re.compile(r"^\s*subgraph\s", re.MULTILINE), "body"),
    Cond.TAG: (re.compile(r"\btag:"), "body"),
    Cond.TERMINAL: (re.compile(r"-->\s*\[\*\]"), "body"),
    Cond.TITLE: (re.compile(r"^\s*title\b", re.MULTILINE), "body"),
}

REF_THEMING = "references/theming.md"
REF_STYLING = "references/styling.md"
REF_CONFIG = "references/config.md"

CANON_LOCK = (
    "Every themed fence opens theme: base with look: classic, useGradient: false, and dropShadow: none - the render-flat lock the border canon owns."
)
CANON_MONO = "themeVariables.fontFamily carries the ruled mono stack exactly, declared once in themeVariables and never at config root; hyphenated family tokens make the engine drop the declaration."
CANON_PAD = "Diagram padding is 25 universally - flowchart.padding and every family's breathing-room knob take the same value."
CANON_ELK = "Flowchart fences carry layout: elk with flowchart.curve: linear; every other family stays on its own engine for portability."
CANON_ALPHA = "Every accent fill composites the two-tier alpha table - dark-ink chips at BF, light-ink surfaces at 80/66/54, washes at 1A-4D - and neutral surfaces stay opaque."
CANON_PALETTE = "Every hex on a styling surface traces to the Dracula palette table; ad-hoc hexes are a defect."
CANON_YELLOW = "White ink on gold is the yellow law - a gold chip is a low-alpha wash under a full gold border, never a bright pill with dark ink."
CANON_BACKING = "Label backings ride Darker #21222C, one step recessed below the canvas; a backing equal to the canvas reads as a hole."
CANON_TITLE = "Container and section titles take the 13.5px/700 container-title stamp with Lavender ink."
CANON_LADDER = "The line-weight ladder is one scale: 2px standing edge, 3px fault, 1.5px dashed and node border, 1px container at the 5 4 rhythm."
CANON_MARKER = (
    "Every arrowhead scales .8 and every terminal circle .48 - r:3.4px start disc, .4 barbEnd at stroke weight, .75 commit dots, .5 requirement V."
)
CANON_FLAT = "Every node-bearing themeCSS string carries the filter:none!important belt so no gradient or halo survives on any host."
CANON_CSS_SAFE = (
    "themeCSS admits no > combinator (the sanitizer drops the whole block) and no text-transform (the engine measures labels before CSS applies)."
)
CANON_CLASSDEF = "Every classDef sets an explicit color: to survive a host swap."
CANON_CLASS_FLOOR = "A flowchart ships base vars plus three or more canonical classes with an explicit rail on every non-primary edge."
CANON_ORDINAL = "A type reading an ordinal palette defines the full engine range it consumes, so no band derives to primaryColor mud."
CANON_ACC = "Seven families refuse accTitle/accDescr - block, mindmap, kanban, ishikawa, eventmodeling mis-handle them and sankey, venn reject at parse - so the relation sentence rides beside the fence."
CANON_INIT = "%%{init:...}%% directives are deprecated - frontmatter is the current channel."
CANON_ORDER = "The config block holds one key order: theme, look, layout, root render keys, per-type blocks, themeVariables (opening darkMode, fontFamily, useGradient, dropShadow), themeCSS last."


# --- [MODELS] ------------------------------------------------------------------------------


class Row(msgspec.Struct, frozen=True):
    file: str
    line: int
    status: Level
    rule: str
    detail: str


class Fence(msgspec.Struct, frozen=True):
    file: str
    line: int
    body: str


class Rule(msgspec.Struct, frozen=True):
    id: str
    level: Level
    surface: Surface
    detail: str
    canon: str
    ref: str
    fams: tuple[Fam, ...] = ()
    path: tuple[str, ...] = ()
    expect: object = None
    pattern: str = ""
    when: Cond = Cond.ALWAYS


class Doc(msgspec.Struct, frozen=True):
    fence: Fence
    fam: Fam
    header: str
    fm_text: str
    config: object
    css: str
    body: str


# --- [TABLES] ------------------------------------------------------------------------------

TV = ("themeVariables",)

RULES: tuple[Rule, ...] = (
    # --- [GLOBAL_LOCK]
    Rule("frontmatter-required", FAIL, Surface.DERIVED, "themed family carries fence frontmatter", CANON_LOCK, f"{REF_THEMING} [08]"),
    Rule(
        "frontmatter-parse",
        FAIL,
        Surface.DERIVED,
        "frontmatter YAML parses",
        "Keys are case-sensitive; malformed YAML kills the whole diagram.",
        f"{REF_CONFIG} [01]",
    ),
    Rule("theme-base", FAIL, Surface.FM, "config.theme is base", CANON_LOCK, f"{REF_THEMING} [03]", path=("theme",), expect="base"),
    Rule("look-classic", FAIL, Surface.FM, "config.look is classic", CANON_LOCK, f"{REF_THEMING} [03]", path=("look",), expect="classic"),
    Rule(
        "dark-mode",
        FAIL,
        Surface.FM,
        "themeVariables.darkMode is true",
        "darkMode: true flips the derived-color math toward the dark host.",
        f"{REF_THEMING} [03]",
        path=(*TV, "darkMode"),
        expect=True,
    ),
    Rule(
        "gradient-kill",
        FAIL,
        Surface.FM,
        "themeVariables.useGradient is false",
        CANON_LOCK,
        f"{REF_THEMING} [06]",
        path=(*TV, "useGradient"),
        expect=False,
    ),
    Rule(
        "shadow-kill",
        FAIL,
        Surface.FM,
        "themeVariables.dropShadow is none",
        CANON_LOCK,
        f"{REF_THEMING} [06]",
        path=(*TV, "dropShadow"),
        expect="none",
    ),
    Rule(
        "font-mono-stack",
        FAIL,
        Surface.FM,
        "themeVariables.fontFamily is the ruled mono stack",
        CANON_MONO,
        f"{REF_THEMING} [03]",
        path=(*TV, "fontFamily"),
        expect=FONT_STACK,
    ),
    Rule("font-root-ban", FAIL, Surface.FM_NONE, "fontFamily never sits at config root", CANON_MONO, f"{REF_CONFIG} [01]", path=("fontFamily",)),
    Rule("font-hyphen", FAIL, Surface.DERIVED, "no hyphenated family token in any fontFamily", CANON_MONO, f"{REF_CONFIG} [06]"),
    Rule("init-directive", FAIL, Surface.BODY_NONE, "no deprecated init directive", CANON_INIT, f"{REF_CONFIG} [01]", pattern=r"%%\{\s*init\s*:"),
    Rule("css-child-combinator", FAIL, Surface.DERIVED, "no > combinator in themeCSS", CANON_CSS_SAFE, f"{REF_CONFIG} [06]"),
    Rule("css-text-transform", FAIL, Surface.DERIVED, "no text-transform in themeCSS", CANON_CSS_SAFE, f"{REF_CONFIG} [06]"),
    Rule(
        "hex-off-palette",
        FAIL,
        Surface.DERIVED,
        "every hex traces to the palette table or a documented engine hook",
        CANON_PALETTE,
        f"{REF_THEMING} [01]",
    ),
    Rule(
        "hex-alpha",
        FAIL,
        Surface.DERIVED,
        "alpha suffixes come from the two-tier table: chips BF/80/66/54, washes 1A/26/33/4D, neutrals opaque",
        CANON_ALPHA,
        f"{REF_THEMING} [04]",
    ),
    Rule("yellow-dark-ink", FAIL, Surface.DERIVED, "no #282A36 ink on a #FFD866 surface", CANON_YELLOW, f"{REF_THEMING} [04]"),
    Rule(
        "accent-fill-opaque",
        FAIL,
        Surface.DERIVED,
        "accent class fills carry a sanctioned alpha or a fill-opacity on the same statement",
        CANON_ALPHA,
        f"{REF_STYLING} [07]",
    ),
    Rule("classdef-color", FAIL, Surface.DERIVED, "every classDef declares color:", CANON_CLASSDEF, f"{REF_THEMING} [04]"),
    Rule(
        "container-title-stamp", FAIL, Surface.DERIVED, "cluster-label and sectionTitle blocks stamp 13.5px/700", CANON_TITLE, f"{REF_THEMING} [05]"
    ),
    Rule("stale-scale", FAIL, Surface.DERIVED, "no stale .64 terminal scale survives", CANON_MARKER, f"{REF_THEMING} [05]"),
    Rule("fm-key-order", WARN, Surface.DERIVED, "config keys hold the canonical order with themeCSS last", CANON_ORDER, f"{REF_CONFIG} [01]"),
    Rule(
        "acc-forbidden",
        FAIL,
        Surface.BODY_NONE,
        "family refuses accTitle/accDescr",
        CANON_ACC,
        f"{REF_CONFIG} [04]",
        fams=(Fam.BLOCK, Fam.MINDMAP, Fam.KANBAN, Fam.ISHIKAWA, Fam.EVENTMODELING, Fam.SANKEY, Fam.VENN),
        pattern=r"accTitle|accDescr",
    ),
    # --- [FLOWCHART]
    Rule("flow-elk", FAIL, Surface.DERIVED, "flowchart declares layout elk", CANON_ELK, f"{REF_CONFIG} [02]", fams=(Fam.FLOWCHART,)),
    Rule(
        "elk-only-flowchart",
        FAIL,
        Surface.FM_NONE,
        "only flowchart declares layout: elk",
        CANON_ELK,
        f"{REF_CONFIG} [02]",
        fams=tuple(fam for fam in Fam if fam is not Fam.FLOWCHART),
        path=("layout",),
    ),
    Rule(
        "flow-curve-linear",
        FAIL,
        Surface.FM,
        "flowchart.curve holds the elbow posture on dagre fallback",
        CANON_ELK,
        f"{REF_CONFIG} [02]",
        fams=(Fam.FLOWCHART,),
        path=("flowchart", "curve"),
        expect="linear",
    ),
    Rule(
        "flow-padding-25",
        FAIL,
        Surface.FM_VALUE,
        "flowchart.padding, when declared, is 25",
        CANON_PAD,
        f"{REF_CONFIG} [01]",
        fams=(Fam.FLOWCHART,),
        path=("flowchart", "padding"),
        expect=25,
    ),
    Rule(
        "flow-line-pink",
        FAIL,
        Surface.FM,
        "lineColor is Pink",
        "Pink owns primary control flow: lineColor and arrowheadColor.",
        f"{REF_THEMING} [02]",
        fams=(Fam.FLOWCHART, Fam.SWIMLANE, Fam.STATE, Fam.CLASS, Fam.ER, Fam.BLOCK),
        path=(*TV, "lineColor"),
        expect=PINK,
    ),
    Rule(
        "text-foreground",
        FAIL,
        Surface.FM,
        "textColor is Foreground",
        "Foreground owns label text through every *TextColor and textColor.",
        f"{REF_THEMING} [02]",
        fams=(
            Fam.FLOWCHART,
            Fam.SWIMLANE,
            Fam.STATE,
            Fam.CLASS,
            Fam.ER,
            Fam.BLOCK,
            Fam.GANTT,
            Fam.MINDMAP,
            Fam.TIMELINE,
            Fam.KANBAN,
            Fam.SANKEY,
            Fam.RADAR,
            Fam.TREEMAP,
            Fam.C4,
            Fam.ARCHITECTURE,
            Fam.JOURNEY,
            Fam.REQUIREMENT,
            Fam.EVENTMODELING,
            Fam.VENN,
            Fam.WARDLEY,
            Fam.CYNEFIN,
            Fam.RAILROAD,
            Fam.TREEVIEW,
            Fam.ISHIKAWA,
        ),
        path=(*TV, "textColor"),
        expect=FOREGROUND,
    ),
    Rule(
        "node-owner",
        FAIL,
        Surface.DERIVED,
        "a node fill owner (primaryColor or mainBkg) and border owner (primaryBorderColor or nodeBorder) are set",
        "Selection fills nodes under Purple ownership borders.",
        f"{REF_THEMING} [02]",
        fams=(Fam.FLOWCHART, Fam.SWIMLANE, Fam.STATE, Fam.CLASS, Fam.ER),
    ),
    Rule(
        "edge-label-backing",
        FAIL,
        Surface.FM,
        "edgeLabelBackground is Darker",
        CANON_BACKING,
        f"{REF_THEMING} [03]",
        fams=(Fam.FLOWCHART, Fam.SWIMLANE, Fam.BLOCK),
        path=(*TV, "edgeLabelBackground"),
        expect=DARKER,
        when=Cond.EDGE_LABEL,
    ),
    Rule(
        "label-backing",
        FAIL,
        Surface.FM,
        "labelBackgroundColor is Darker",
        CANON_BACKING,
        f"{REF_THEMING} [03]",
        fams=(Fam.FLOWCHART, Fam.SWIMLANE),
        path=(*TV, "labelBackgroundColor"),
        expect=DARKER,
        when=Cond.EDGE_LABEL,
    ),
    Rule(
        "cluster-bkg",
        FAIL,
        Surface.FM,
        "clusterBkg recesses to Darker",
        "Containers recess and their boundary reads: clusterBkg Darker under a Lavender clusterBorder.",
        f"{REF_THEMING} [03]",
        fams=(Fam.FLOWCHART, Fam.SWIMLANE),
        path=(*TV, "clusterBkg"),
        expect=DARKER,
        when=Cond.SUBGRAPH,
    ),
    Rule(
        "cluster-border",
        FAIL,
        Surface.FM,
        "clusterBorder is Lavender",
        "One hue family carries all ownership; Lavender is the container boundary.",
        f"{REF_THEMING} [02]",
        fams=(Fam.FLOWCHART, Fam.SWIMLANE),
        path=(*TV, "clusterBorder"),
        expect=LAVENDER,
        when=Cond.SUBGRAPH,
    ),
    Rule(
        "title-lavender",
        FAIL,
        Surface.FM,
        "titleColor inks Lavender to match the container border",
        CANON_TITLE,
        f"{REF_THEMING} [05]",
        fams=(Fam.FLOWCHART, Fam.SWIMLANE),
        path=(*TV, "titleColor"),
        expect=LAVENDER,
        when=Cond.SUBGRAPH,
    ),
    Rule(
        "flow-css-node-label",
        FAIL,
        Surface.CSS,
        "node label stamp 13px/500",
        "Node labels ride 13px weight 500 on the three-step type ramp.",
        f"{REF_THEMING} [05]",
        fams=(Fam.FLOWCHART, Fam.SWIMLANE, Fam.STATE, Fam.CLASS),
        pattern=".nodeLabel{font-size:13px;font-weight:500}",
    ),
    Rule(
        "flow-css-edge-label",
        FAIL,
        Surface.CSS,
        "edge label stamp 12px/500",
        "Edge labels ride 12px weight 500.",
        f"{REF_THEMING} [05]",
        fams=(Fam.FLOWCHART, Fam.SWIMLANE, Fam.STATE, Fam.CLASS),
        pattern=".edgeLabel{font-size:12px;font-weight:500}",
    ),
    Rule(
        "flow-css-standing",
        FAIL,
        Surface.CSS,
        "standing edge 2px through the thickness classes",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.FLOWCHART,),
        pattern=".edge-thickness-normal{stroke-width:2px}",
    ),
    Rule(
        "flow-css-thick",
        FAIL,
        Surface.CSS,
        "thick edge 3px",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.FLOWCHART,),
        pattern=".edge-thickness-thick{stroke-width:3px}",
    ),
    Rule(
        "flow-css-dashed",
        FAIL,
        Surface.CSS,
        "dashed and dotted edges 1.5px at the 4 6 trace rhythm",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.FLOWCHART,),
        pattern=".edge-pattern-dashed,.edge-pattern-dotted{stroke-width:1.5px;stroke-dasharray:4 6}",
    ),
    Rule(
        "node-belt",
        FAIL,
        Surface.CSS,
        "node border 1.5px with the filter:none belt",
        CANON_FLAT,
        f"{REF_THEMING} [05]",
        fams=(Fam.FLOWCHART, Fam.SWIMLANE, Fam.STATE, Fam.CLASS, Fam.ER, Fam.BLOCK, Fam.KANBAN),
        pattern="stroke-width:1.5px;filter:none!important",
    ),
    Rule(
        "flow-css-cluster",
        FAIL,
        Surface.CSS,
        "cluster rect 1px dashed 5 4 with the filter belt",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.FLOWCHART,),
        pattern=".cluster rect{stroke-width:1px!important;stroke-dasharray:5 4!important;filter:none!important}",
        when=Cond.SUBGRAPH,
    ),
    Rule(
        "class-css-cluster",
        FAIL,
        Surface.CSS,
        "namespace rect 1px dashed 5 4 with the filter belt",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.CLASS,),
        pattern=".cluster rect{stroke-width:1px!important;stroke-dasharray:5 4!important;filter:none!important}",
        when=Cond.NAMESPACE,
    ),
    Rule(
        "flow-css-cluster-title",
        FAIL,
        Surface.CSS,
        "container title 13.5px/700",
        CANON_TITLE,
        f"{REF_THEMING} [05]",
        fams=(Fam.FLOWCHART,),
        pattern=".cluster-label .nodeLabel{font-size:13.5px;font-weight:700",
        when=Cond.SUBGRAPH,
    ),
    Rule(
        "marker-scale",
        FAIL,
        Surface.CSS,
        "arrowheads scale .8",
        CANON_MARKER,
        f"{REF_THEMING} [05]",
        fams=(Fam.FLOWCHART, Fam.SWIMLANE, Fam.CLASS),
        pattern=".marker path{transform:scale(.8);transform-origin:5px 5px}",
    ),
    Rule(
        "flow-css-marker-circle",
        FAIL,
        Surface.CSS,
        "terminal circles scale .48",
        CANON_MARKER,
        f"{REF_THEMING} [05]",
        fams=(Fam.FLOWCHART,),
        pattern=".marker circle{transform:scale(.48);transform-origin:5px 5px}",
    ),
    Rule(
        "flow-css-label-chip",
        FAIL,
        Surface.CSS,
        "edge label chip breathes at scale(1.1,1.2)",
        "The recessed backing chip masks the stroke it crosses.",
        f"{REF_THEMING} [05]",
        fams=(Fam.FLOWCHART, Fam.SWIMLANE, Fam.STATE),
        pattern=".edgeLabel rect{transform-box:fill-box",
    ),
    Rule(
        "class-floor",
        FAIL,
        Surface.DERIVED,
        "three or more canonical classes ship",
        CANON_CLASS_FLOOR,
        f"{REF_STYLING} [06]",
        fams=(Fam.FLOWCHART, Fam.SWIMLANE),
    ),
    # --- [SEQUENCE]
    Rule(
        "seq-actor-vars",
        FAIL,
        Surface.DERIVED,
        "actor surface vars: actorBkg/actorBorder/actorTextColor/actorLineColor",
        "Selection actors under Purple borders on Comment lifelines.",
        f"{REF_THEMING} [03]",
        fams=(Fam.SEQUENCE,),
    ),
    Rule(
        "seq-signal",
        FAIL,
        Surface.FM,
        "signalColor is Pink",
        "Pink owns primary control flow: signalColor on sequence.",
        f"{REF_THEMING} [02]",
        fams=(Fam.SEQUENCE,),
        path=(*TV, "signalColor"),
        expect=PINK,
    ),
    Rule(
        "seq-signal-text",
        FAIL,
        Surface.FM,
        "signalTextColor is Foreground",
        "Foreground owns label text.",
        f"{REF_THEMING} [02]",
        fams=(Fam.SEQUENCE,),
        path=(*TV, "signalTextColor"),
        expect=FOREGROUND,
    ),
    Rule(
        "seq-activation",
        FAIL,
        Surface.DERIVED,
        "activationBkgColor Selection under a Purple activationBorderColor",
        "A sequence activation reads as a neutral lifted bar over its lifeline.",
        f"{REF_THEMING} [03]",
        fams=(Fam.SEQUENCE,),
    ),
    Rule(
        "seq-note-vars",
        FAIL,
        Surface.DERIVED,
        "neutral note: Selection fill, Comment border, Foreground ink",
        "Neutral notes fill Selection under a Comment border for sequence and state.",
        f"{REF_THEMING} [03]",
        fams=(Fam.SEQUENCE,),
    ),
    Rule(
        "seq-number-ink",
        FAIL,
        Surface.FM,
        "sequenceNumberColor prints dark numerals on Pink discs",
        "sequenceNumberColor carries Background so autonumber chips print dark numerals.",
        f"{REF_THEMING} [03]",
        fams=(Fam.SEQUENCE,),
        path=(*TV, "sequenceNumberColor"),
        expect=CANVAS,
        when=Cond.AUTONUMBER,
    ),
    Rule(
        "seq-labelbox",
        FAIL,
        Surface.DERIVED,
        "region frame vars: labelBox Darker/Lavender with Foreground label and loop text",
        "Loop and alt frames ride Darker labelBox under Lavender borders.",
        f"{REF_THEMING} [03]",
        fams=(Fam.SEQUENCE,),
    ),
    Rule(
        "seq-region-grouped",
        FAIL,
        Surface.DERIVED,
        "every alt/par/critical/break region wraps in a box or rect",
        "A sequence ships one box or rect grouping around each alt/par/critical region.",
        f"{REF_STYLING} [06]",
        fams=(Fam.SEQUENCE,),
    ),
    Rule(
        "seq-css-actor",
        FAIL,
        Surface.CSS,
        "actor label stamp 13px/600",
        "Actor labels ride 13px weight 600.",
        f"{REF_THEMING} [05]",
        fams=(Fam.SEQUENCE,),
        pattern="text.actor tspan{font-size:13px;font-weight:600}",
    ),
    Rule(
        "seq-css-message",
        FAIL,
        Surface.CSS,
        "message text stamp 12px/500",
        "Message text rides 12px weight 500.",
        f"{REF_THEMING} [05]",
        fams=(Fam.SEQUENCE,),
        pattern=".messageText{font-size:12px;font-weight:500}",
    ),
    Rule(
        "seq-css-lines",
        FAIL,
        Surface.CSS,
        "solid message 2px",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.SEQUENCE,),
        pattern=".messageLine0{stroke-width:2px}",
    ),
    Rule(
        "seq-css-dotted",
        FAIL,
        Surface.CSS,
        "dotted message 1.5px at 4 6",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.SEQUENCE,),
        pattern=".messageLine1{stroke-width:1.5px;stroke-dasharray:4 6}",
    ),
    Rule(
        "seq-css-actor-belt",
        FAIL,
        Surface.CSS,
        "actor border 1.5px with the filter belt",
        CANON_FLAT,
        f"{REF_THEMING} [05]",
        fams=(Fam.SEQUENCE,),
        pattern="rect.actor{filter:none!important}",
    ),
    Rule(
        "seq-css-filled-head",
        FAIL,
        Surface.CSS,
        "async -filled-head marker stamped onto the signal hue",
        "The async send terminates in the -filled-head marker the engine leaves unstyled.",
        f"{REF_THEMING} [05]",
        fams=(Fam.SEQUENCE,),
        pattern="[id$='-filled-head'] path{fill:#FF79C6",
        when=Cond.ASYNC,
    ),
    # --- [STATE]
    Rule(
        "state-backing",
        FAIL,
        Surface.FM,
        "labelBackgroundColor is Darker",
        CANON_BACKING,
        f"{REF_THEMING} [03]",
        fams=(Fam.STATE,),
        path=(*TV, "labelBackgroundColor"),
        expect=DARKER,
    ),
    Rule(
        "state-edge-backing",
        FAIL,
        Surface.FM,
        "edgeLabelBackground is Darker",
        CANON_BACKING,
        f"{REF_THEMING} [03]",
        fams=(Fam.STATE,),
        path=(*TV, "edgeLabelBackground"),
        expect=DARKER,
    ),
    Rule(
        "state-composite-vars",
        FAIL,
        Surface.DERIVED,
        "composite vars: compositeBackground Darker, compositeTitleBackground Background, compositeBorder Lavender",
        "Containers recess and their boundary reads.",
        f"{REF_THEMING} [03]",
        fams=(Fam.STATE,),
    ),
    Rule(
        "state-css-title",
        FAIL,
        Surface.CSS,
        "container title 13.5px/700 with explicit Lavender ink",
        CANON_TITLE,
        f"{REF_THEMING} [05]",
        fams=(Fam.STATE,),
        pattern=".cluster-label .nodeLabel{font-size:13.5px;font-weight:700;letter-spacing:.08em;color:#D6BCFA}",
    ),
    Rule(
        "state-css-transition",
        FAIL,
        Surface.CSS,
        "transitions 2px",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.STATE,),
        pattern=".transition{stroke-width:2px}",
    ),
    Rule(
        "state-css-note-edge",
        FAIL,
        Surface.CSS,
        "note edge 1.5px",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.STATE,),
        pattern=".note-edge{stroke-width:1.5px}",
    ),
    Rule(
        "state-css-barb",
        FAIL,
        Surface.CSS,
        "barbEnd scales .4 at the 2px transition weight in Pink",
        CANON_MARKER,
        f"{REF_THEMING} [05]",
        fams=(Fam.STATE,),
        pattern="[id*='barbEnd'] path{fill:#FF79C6;stroke:#FF79C6;transform:scale(.4);transform-origin:14px 7px}",
    ),
    Rule(
        "state-css-start",
        FAIL,
        Surface.CSS,
        "start disc r:3.4px in Pink",
        CANON_MARKER,
        f"{REF_THEMING} [05]",
        fams=(Fam.STATE,),
        pattern=".state-start{r:3.4px;fill:#FF79C6;stroke:#FF79C6}",
    ),
    Rule(
        "state-css-terminal",
        FAIL,
        Surface.CSS,
        "terminal ring scales .48 through the outer-path group",
        CANON_MARKER,
        f"{REF_THEMING} [05]",
        fams=(Fam.STATE,),
        pattern=".node[id*='_end'] .outer-path{transform-box:fill-box;transform-origin:center;transform:scale(.48)}",
        when=Cond.TERMINAL,
    ),
    Rule(
        "state-css-cluster",
        FAIL,
        Surface.CSS,
        "composite outer rect 1px dashed 5 4 Lavender",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.STATE,),
        pattern=".statediagram-cluster rect.outer{stroke:#D6BCFA;stroke-width:1px!important;stroke-dasharray:5 4}",
        when=Cond.COMPOSITE,
    ),
    Rule(
        "state-css-divider",
        FAIL,
        Surface.CSS,
        "concurrency divider 1px dashed 5 4 Lavender",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.STATE,),
        pattern=".statediagram-state rect.divider{stroke:#D6BCFA;stroke-width:1px;stroke-dasharray:5 4",
        when=Cond.COMPOSITE,
    ),
    # --- [CLASS]
    Rule(
        "class-text",
        FAIL,
        Surface.FM,
        "classText is Foreground",
        "classText joins the Foreground ink set.",
        f"{REF_THEMING} [03]",
        fams=(Fam.CLASS,),
        path=(*TV, "classText"),
        expect=FOREGROUND,
    ),
    Rule(
        "class-edge-backing",
        FAIL,
        Surface.FM,
        "edgeLabelBackground is Darker",
        CANON_BACKING,
        f"{REF_THEMING} [03]",
        fams=(Fam.CLASS,),
        path=(*TV, "edgeLabelBackground"),
        expect=DARKER,
    ),
    Rule(
        "class-note-chip",
        FAIL,
        Surface.DERIVED,
        "the class note takes the gold payload chip: #FFD86654 fill, #FFD866 border, Foreground ink",
        "The class-diagram note alone takes the payload chip because a class note tags an invariant.",
        f"{REF_THEMING} [04]",
        fams=(Fam.CLASS,),
    ),
    Rule(
        "class-css-title",
        FAIL,
        Surface.CSS,
        "class title stamp 13px/600",
        "Class titles ride 13px weight 600.",
        f"{REF_THEMING} [05]",
        fams=(Fam.CLASS,),
        pattern=".classTitle{font-size:13px;font-weight:600}",
    ),
    Rule(
        "class-css-relation",
        FAIL,
        Surface.CSS,
        "relations 2px",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.CLASS,),
        pattern=".relation{stroke-width:2px}",
    ),
    Rule(
        "class-css-dashed",
        FAIL,
        Surface.CSS,
        "dashed relations 1.5px at 4 6",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.CLASS,),
        pattern=".edge-pattern-dashed,.edge-pattern-dotted{stroke-width:1.5px;stroke-dasharray:4 6}",
        when=Cond.DOTTED_REL,
    ),
    Rule(
        "class-css-divider",
        FAIL,
        Surface.CSS,
        "member divider 1px",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.CLASS,),
        pattern=".divider{stroke-width:1px}",
    ),
    Rule(
        "class-css-cluster-title",
        FAIL,
        Surface.CSS,
        "namespace title 13.5px/700",
        CANON_TITLE,
        f"{REF_THEMING} [05]",
        fams=(Fam.CLASS,),
        pattern="font-size:13.5px;font-weight:700",
        when=Cond.NAMESPACE,
    ),
    Rule(
        "class-css-note",
        FAIL,
        Surface.CSS,
        "note label 12px",
        "Note text rides 12px on the ramp.",
        f"{REF_THEMING} [05]",
        fams=(Fam.CLASS,),
        pattern=".noteLabel .nodeLabel{font-size:12px}",
        when=Cond.NOTE_CLASS,
    ),
    # --- [ER]
    Rule(
        "er-tertiary",
        FAIL,
        Surface.FM,
        "tertiaryColor is an ER floor key composing the label backing",
        "An ER fence that omits lineColor or tertiaryColor derives pale gray lines and an olive label chip.",
        f"{REF_THEMING} [03]",
        fams=(Fam.ER,),
        path=(*TV, "tertiaryColor"),
        expect=DARKER,
    ),
    Rule(
        "er-banding",
        FAIL,
        Surface.DERIVED,
        "attribute banding alternates Background and Darker",
        "ER ships attribute banding as its floor.",
        f"{REF_STYLING} [06]",
        fams=(Fam.ER,),
    ),
    Rule(
        "er-edge-backing",
        FAIL,
        Surface.FM,
        "edgeLabelBackground is Darker",
        CANON_BACKING,
        f"{REF_THEMING} [03]",
        fams=(Fam.ER,),
        path=(*TV, "edgeLabelBackground"),
        expect=DARKER,
    ),
    Rule(
        "er-css-name",
        FAIL,
        Surface.CSS,
        "entity name stamp 13px/600",
        "Entity names ride 13px weight 600.",
        f"{REF_THEMING} [05]",
        fams=(Fam.ER,),
        pattern=".name .nodeLabel{font-size:13px;font-weight:600}",
    ),
    Rule(
        "er-css-line",
        FAIL,
        Surface.CSS,
        "relationship lines 2px",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.ER,),
        pattern=".relationshipLine{stroke-width:2px}",
    ),
    Rule(
        "er-css-dashed",
        FAIL,
        Surface.CSS,
        "non-identifying relations 1.5px at the 6 6 planned rhythm",
        CANON_LADDER,
        f"{REF_THEMING} [05]",
        fams=(Fam.ER,),
        pattern=".edge-pattern-dashed{stroke-width:1.5px;stroke-dasharray:6 6}",
        when=Cond.DOTTED_REL,
    ),
    Rule(
        "er-css-marker",
        FAIL,
        Surface.CSS,
        "cardinality marks scale .8 as one glyph with the crow's-foot",
        CANON_MARKER,
        f"{REF_THEMING} [05]",
        fams=(Fam.ER,),
        pattern=".marker path,.marker circle{transform:scale(.8);transform-origin:5px 5px}",
    ),
    Rule(
        "er-css-zero-ring",
        FAIL,
        Surface.CSS,
        "the zero-side hollow ring fills canvas",
        "ER cardinality marks ride the relation stroke with a canvas-filled hollow ring for the zero side.",
        f"{REF_THEMING} [05]",
        fams=(Fam.ER,),
        pattern=".marker circle{fill:#282A36}",
    ),
    Rule(
        "er-css-entity-flat",
        FAIL,
        Surface.CSS,
        "the entity box drops its filter",
        CANON_FLAT,
        f"{REF_THEMING} [05]",
        fams=(Fam.ER,),
        pattern=".er.entityBox{filter:none}",
    ),
    # --- [GANTT]
    Rule(
        "gantt-axis",
        FAIL,
        Surface.BODY,
        "axisFormat owns tick legibility",
        "axisFormat with tickInterval own tick legibility; default daily ISO ticks overlap.",
        f"{REF_STYLING} [06]",
        fams=(Fam.GANTT,),
        pattern=r"^\s*axisFormat\s",
    ),
    Rule(
        "gantt-tick",
        FAIL,
        Surface.BODY,
        "tickInterval owns tick spacing",
        "axisFormat with tickInterval own tick legibility.",
        f"{REF_STYLING} [06]",
        fams=(Fam.GANTT,),
        pattern=r"^\s*tickInterval\s",
    ),
    Rule(
        "gantt-section-bkg",
        FAIL,
        Surface.FM,
        "sectionBkgColor recesses to Darker",
        "sectionBkgColor carries Darker.",
        f"{REF_THEMING} [02]",
        fams=(Fam.GANTT,),
        path=(*TV, "sectionBkgColor"),
        expect=DARKER,
    ),
    Rule(
        "gantt-task-vars",
        FAIL,
        Surface.DERIVED,
        "task vars: taskBkgColor Selection, taskBorderColor Purple, Foreground task text incl. taskTextDarkColor",
        "taskTextDarkColor joins the Foreground ink set because done bars recess to Darker.",
        f"{REF_THEMING} [03]",
        fams=(Fam.GANTT,),
    ),
    Rule(
        "gantt-active",
        FAIL,
        Surface.DERIVED,
        "active task vars: activeTaskBkgColor Comment under a Purple border",
        "Active bars lift to Comment under the ownership border.",
        f"{REF_THEMING} [03]",
        fams=(Fam.GANTT,),
    ),
    Rule(
        "gantt-done",
        FAIL,
        Surface.DERIVED,
        "done task vars: doneTaskBkgColor Darker under a Comment border",
        "Done bars recess to Darker.",
        f"{REF_THEMING} [03]",
        fams=(Fam.GANTT,),
    ),
    Rule(
        "gantt-crit",
        FAIL,
        Surface.DERIVED,
        "critical vars: translucent Red critBkgColor under a solid critBorderColor",
        "critBkgColor carries the ruled translucent Red so a critical bar reads as the alarm chip.",
        f"{REF_THEMING} [03]",
        fams=(Fam.GANTT,),
    ),
    Rule(
        "gantt-exclude",
        FAIL,
        Surface.FM,
        "excludeBkgColor recesses excluded bands",
        "Left unset it derives a light gray that floods a dark canvas.",
        f"{REF_THEMING} [03]",
        fams=(Fam.GANTT,),
        path=(*TV, "excludeBkgColor"),
        expect=DARKER,
        when=Cond.EXCLUDES,
    ),
    Rule(
        "gantt-grid",
        FAIL,
        Surface.FM,
        "gridColor is Comment",
        "Comment owns the muted grid.",
        f"{REF_THEMING} [02]",
        fams=(Fam.GANTT,),
        path=(*TV, "gridColor"),
        expect=COMMENT,
    ),
    Rule(
        "gantt-today",
        FAIL,
        Surface.FM,
        "todayLineColor is Pink",
        "Pink owns terminus and today marks.",
        f"{REF_THEMING} [02]",
        fams=(Fam.GANTT,),
        path=(*TV, "todayLineColor"),
        expect=PINK,
    ),
    Rule(
        "gantt-css-section",
        FAIL,
        Surface.CSS,
        "section titles take the 13.5px/700 Lavender stamp",
        CANON_TITLE,
        f"{REF_THEMING} [05]",
        fams=(Fam.GANTT,),
        pattern=".sectionTitle{font-size:13.5px;font-weight:700;fill:#D6BCFA}",
    ),
    Rule(
        "gantt-css-task-text",
        FAIL,
        Surface.CSS,
        "task text 12px",
        "Task text rides 12px on the ramp.",
        f"{REF_THEMING} [05]",
        fams=(Fam.GANTT,),
        pattern=".taskText,.taskTextOutsideRight,.taskTextOutsideLeft{font-size:12px}",
    ),
    Rule(
        "gantt-css-ticks",
        FAIL,
        Surface.CSS,
        "grid tick text 11px",
        "Tick text rides the small ramp step.",
        f"{REF_THEMING} [05]",
        fams=(Fam.GANTT,),
        pattern=".grid .tick text{font-size:11px}",
    ),
    # --- [MINDMAP]
    Rule(
        "mindmap-padding",
        FAIL,
        Surface.FM_VALUE,
        "mindmap.padding, when declared, is 25",
        CANON_PAD,
        f"{REF_CONFIG} [01]",
        fams=(Fam.MINDMAP,),
        path=("mindmap", "padding"),
        expect=25,
    ),
    Rule(
        "mindmap-css-alpha",
        FAIL,
        Surface.CSS,
        "node surfaces composite at .5 fill-opacity",
        "The .mindmap-node fill-opacity stamp composites the translucent law.",
        f"{REF_STYLING} [06]",
        fams=(Fam.MINDMAP,),
        pattern="fill-opacity:.5",
    ),
    Rule(
        "mindmap-css-edge",
        FAIL,
        Surface.CSS,
        "depth-scaled connectors pull to the standing 2px",
        CANON_LADDER,
        f"{REF_STYLING} [06]",
        fams=(Fam.MINDMAP,),
        pattern=".edge{stroke-width:2px!important}",
    ),
    Rule(
        "mindmap-css-lines",
        FAIL,
        Surface.CSS,
        "engine underline strips retire",
        "Kill [class^='node-line'] to retire the engine underline strips.",
        f"{REF_STYLING} [06]",
        fams=(Fam.MINDMAP,),
        pattern="[class^='node-line']{stroke:none!important}",
    ),
    Rule(
        "mindmap-sections",
        FAIL,
        Surface.DERIVED,
        "explicit per-section fill/stroke overrides cover every first-level branch plus the root",
        "The engine lightens every cScale hue before painting, so canon color rides explicit per-section themeCSS overrides.",
        f"{REF_STYLING} [06]",
        fams=(Fam.MINDMAP,),
    ),
    # --- [BLOCK]
    Rule(
        "block-arrowhead",
        FAIL,
        Surface.CSS,
        "the marker path takes an explicit Pink fill",
        "The family stylesheet never reaches its marker children, so the fill-and-stroke stamp is the arrowhead-color floor.",
        f"{REF_STYLING} [06]",
        fams=(Fam.BLOCK,),
        pattern=".marker path{fill:#FF79C6",
    ),
    Rule(
        "block-arrowcircle",
        FAIL,
        Surface.CSS,
        "the marker circle takes an explicit Pink fill",
        "No arrowhead renders grey or black anywhere.",
        f"{REF_THEMING} [05]",
        fams=(Fam.BLOCK,),
        pattern=".marker circle{fill:#FF79C6",
    ),
    Rule(
        "block-composite",
        FAIL,
        Surface.CSS,
        "nested groups restyle through rect.composite at the container rhythm",
        "The engine's own composite paint is a faded gray that never survives review.",
        f"{REF_STYLING} [06]",
        fams=(Fam.BLOCK,),
        pattern="rect.composite{fill:#21222C;stroke:#D6BCFA;stroke-width:1px;stroke-dasharray:5 4}",
        when=Cond.NESTED_BLOCK,
    ),
    Rule(
        "block-arrow-var",
        FAIL,
        Surface.FM,
        "arrowheadColor is Pink",
        "arrowheadColor governs unstyled edges.",
        f"{REF_THEMING} [02]",
        fams=(Fam.BLOCK,),
        path=(*TV, "arrowheadColor"),
        expect=PINK,
    ),
    # --- [JOURNEY]
    Rule(
        "journey-fills",
        FAIL,
        Surface.DERIVED,
        "the full fillType0-7 translucent range is defined",
        CANON_ORDINAL,
        f"{REF_THEMING} [03]",
        fams=(Fam.JOURNEY,),
    ),
    Rule(
        "journey-actors",
        FAIL,
        Surface.DERIVED,
        "the full actor0-5 range is defined",
        "Actor dots read actor0-actor5 theme variables, never the actorColours config list.",
        f"{REF_STYLING} [06]",
        fams=(Fam.JOURNEY,),
    ),
    Rule(
        "journey-face",
        FAIL,
        Surface.FM,
        "faceColor is the translucent gold chip",
        CANON_YELLOW,
        f"{REF_THEMING} [03]",
        fams=(Fam.JOURNEY,),
        path=(*TV, "faceColor"),
        expect=f"{GOLD}54",
    ),
    Rule(
        "journey-title-font",
        FAIL,
        Surface.FM,
        "journey.titleFontFamily carries the mono stack (the theme stack does not reach the title)",
        CANON_MONO,
        f"{REF_STYLING} [06]",
        fams=(Fam.JOURNEY,),
        path=("journey", "titleFontFamily"),
        expect=FONT_STACK,
    ),
    Rule(
        "journey-title-ink",
        FAIL,
        Surface.FM,
        "journey.titleColor inks Foreground",
        "The title reads journey.titleColor config, never the theme.",
        f"{REF_STYLING} [06]",
        fams=(Fam.JOURNEY,),
        path=("journey", "titleColor"),
        expect=FOREGROUND,
    ),
    Rule(
        "journey-css-face",
        FAIL,
        Surface.CSS,
        "score faces restyle as translucent gold chips",
        CANON_YELLOW,
        f"{REF_STYLING} [06]",
        fams=(Fam.JOURNEY,),
        pattern=".face{fill:#FFD86654;stroke:#FFD866",
    ),
    Rule(
        "journey-css-mouth",
        FAIL,
        Surface.CSS,
        "the mouth is a filled crescent - fill, never stroke",
        "The mouth is a FILLED crescent path.",
        f"{REF_STYLING} [06]",
        fams=(Fam.JOURNEY,),
        pattern=".mouth{fill:",
    ),
    Rule(
        "journey-css-eyes",
        FAIL,
        Surface.CSS,
        "eye dots re-ink through the fill attribute hook",
        "Eyes are circle[fill='#666'] attribute hooks.",
        f"{REF_STYLING} [06]",
        fams=(Fam.JOURNEY,),
        pattern="circle[fill='#666']",
    ),
    Rule(
        "journey-css-dots",
        FAIL,
        Surface.CSS,
        "actor dots take stroke and the -25% radius",
        CANON_MARKER,
        f"{REF_STYLING} [06]",
        fams=(Fam.JOURNEY,),
        pattern="circle[class^='actor-']",
    ),
    # --- [REQUIREMENT]
    Rule(
        "req-vars",
        FAIL,
        Surface.DERIVED,
        "requirement surface vars: requirementBackground Selection, requirementBorderColor Purple, requirementTextColor Foreground, relationColor Pink",
        "requirement*/relation* plus edgeLabelBackground are the family floor.",
        f"{REF_STYLING} [06]",
        fams=(Fam.REQUIREMENT,),
    ),
    Rule(
        "req-label-backing",
        FAIL,
        Surface.FM,
        "the relation label chip reads edgeLabelBackground Darker",
        "The recessed chip masks the stroke it sits on - the whole label-off-line law for this family.",
        f"{REF_STYLING} [06]",
        fams=(Fam.REQUIREMENT,),
        path=(*TV, "edgeLabelBackground"),
        expect=DARKER,
    ),
    Rule(
        "req-relation-backing",
        FAIL,
        Surface.FM,
        "relationLabelBackground feeds the SVG-text fallback in Darker",
        CANON_BACKING,
        f"{REF_THEMING} [03]",
        fams=(Fam.REQUIREMENT,),
        path=(*TV, "relationLabelBackground"),
        expect=DARKER,
    ),
    Rule(
        "req-css-arrow",
        FAIL,
        Surface.CSS,
        "the 20x20 open V pulls onto the marker ladder at .5",
        CANON_MARKER,
        f"{REF_STYLING} [06]",
        fams=(Fam.REQUIREMENT,),
        pattern="[id$='requirement_arrowEnd'] path{transform:scale(.5);transform-origin:20px 10px}",
    ),
    Rule(
        "req-css-line",
        FAIL,
        Surface.CSS,
        "relations draw at the trace weight and rhythm",
        CANON_LADDER,
        f"{REF_STYLING} [06]",
        fams=(Fam.REQUIREMENT,),
        pattern=".relationshipLine{stroke-width:1.5px;stroke-dasharray:4 6}",
    ),
    Rule(
        "req-css-contains",
        FAIL,
        Surface.CSS,
        "the contains plus-circle start marker scales onto the ladder",
        CANON_MARKER,
        f"{REF_STYLING} [06]",
        fams=(Fam.REQUIREMENT,),
        pattern="[id$='requirement_containsStart']",
        when=Cond.CONTAINS,
    ),
    Rule(
        "req-class-split",
        FAIL,
        Surface.DERIVED,
        "classes separate requirement from element",
        "A requirement ships classes separating requirement from element.",
        f"{REF_STYLING} [06]",
        fams=(Fam.REQUIREMENT,),
    ),
    # --- [PIE]
    Rule(
        "pie-opacity",
        FAIL,
        Surface.FM,
        "pieOpacity is 1 so borders hold while fills composite per slice",
        "pieOpacity dims fill AND stroke, so translucency rides per-slice nth-of-type stamps under pieOpacity: 1.",
        f"{REF_STYLING} [06]",
        fams=(Fam.PIE,),
        path=(*TV, "pieOpacity"),
        expect=1,
    ),
    Rule(
        "pie-outer",
        FAIL,
        Surface.FM,
        "the redundant outer ring retires",
        "pieOuterStrokeWidth 0px retires the redundant outer ring.",
        f"{REF_STYLING} [06]",
        fams=(Fam.PIE,),
        path=(*TV, "pieOuterStrokeWidth"),
        expect="0px",
    ),
    Rule(
        "pie-stroke",
        FAIL,
        Surface.FM,
        "slice borders ride 1.5px",
        CANON_LADDER,
        f"{REF_THEMING} [03]",
        fams=(Fam.PIE,),
        path=(*TV, "pieStrokeWidth"),
        expect="1.5px",
    ),
    Rule(
        "pie-ink",
        FAIL,
        Surface.DERIVED,
        "section, legend, and title text ink Foreground",
        "Every slice hue sits in the light-ink alpha tier so one ink serves all slices.",
        f"{REF_STYLING} [06]",
        fams=(Fam.PIE,),
    ),
    Rule(
        "pie-slices",
        FAIL,
        Surface.DERIVED,
        "each slice carries its ordinal var and its nth-of-type translucent stamp",
        "Slices follow pie1-pie12 in declaration order, so the nth-of-type index and the ordinal share one count.",
        f"{REF_STYLING} [06]",
        fams=(Fam.PIE,),
    ),
    # --- [QUADRANT]
    Rule(
        "quad-fills",
        FAIL,
        Surface.DERIVED,
        "quadrant fills alternate the two neutral surfaces",
        "Quadrant fills alternate the neutral surfaces so plotted hues carry all the semantics.",
        f"{REF_STYLING} [06]",
        fams=(Fam.QUADRANT,),
    ),
    Rule(
        "quad-captions",
        FAIL,
        Surface.DERIVED,
        "quadrant captions ink Lavender as this family's container titles",
        CANON_TITLE,
        f"{REF_STYLING} [06]",
        fams=(Fam.QUADRANT,),
    ),
    Rule(
        "quad-point-padding",
        FAIL,
        Surface.FM_ANY,
        "pointTextPadding clears each label below its dot",
        "pointTextPadding drops each white label clear below its dot.",
        f"{REF_STYLING} [06]",
        fams=(Fam.QUADRANT,),
        path=("quadrantChart", "pointTextPadding"),
    ),
    Rule(
        "quad-css-points",
        FAIL,
        Surface.CSS,
        "point fills composite through the one fill-opacity stamp",
        "Point styles take six-digit hex only, so translucency rides .data-point circle{fill-opacity:.75}.",
        f"{REF_STYLING} [06]",
        fams=(Fam.QUADRANT,),
        pattern=".data-point circle{fill-opacity:.75}",
    ),
    Rule(
        "quad-hex8",
        FAIL,
        Surface.DERIVED,
        "no 8-digit hex in quadrant point styles - the engine rejects them",
        "Quadrant point styles reject 8-digit hex.",
        f"{REF_STYLING} [05]",
        fams=(Fam.QUADRANT,),
    ),
    # --- [SANKEY]
    Rule(
        "sankey-labelstyle",
        FAIL,
        Surface.FM,
        "labelStyle stays legacy - the outlined mode mushes on dark",
        "labelStyle stays legacy; the outlined mode strokes a surface-colored halo that mushes on dark.",
        f"{REF_STYLING} [06]",
        fams=(Fam.SANKEY,),
        path=("sankey", "labelStyle"),
        expect="legacy",
    ),
    Rule(
        "sankey-nodecolors",
        FAIL,
        Surface.DERIVED,
        "every CSV node maps to a palette hex in sankey.nodeColors",
        "A committed sankey maps every node to a palette hex.",
        f"{REF_STYLING} [06]",
        fams=(Fam.SANKEY,),
    ),
    Rule(
        "sankey-css-link",
        FAIL,
        Surface.CSS,
        "the .link blend stamp restores normal blending at .35 stroke opacity",
        "mix-blend-mode: multiply erases links into a dark canvas.",
        f"{REF_STYLING} [06]",
        fams=(Fam.SANKEY,),
        pattern=".link{mix-blend-mode:normal;stroke-opacity:.35}",
    ),
    Rule(
        "sankey-css-labels",
        FAIL,
        Surface.CSS,
        "node labels ink Foreground at the label floor",
        "The .node-labels text stamp inks Foreground.",
        f"{REF_STYLING} [06]",
        fams=(Fam.SANKEY,),
        pattern=".node-labels text{fill:#F8F8F2}",
    ),
    # --- [XYCHART]
    Rule(
        "xy-nested",
        FAIL,
        Surface.FM_ANY,
        "the nested xyChart theme block is defined",
        "Per-type nested objects nest inside themeVariables.",
        f"{REF_THEMING} [03]",
        fams=(Fam.XYCHART,),
        path=(*TV, "xyChart"),
    ),
    Rule(
        "xy-palette",
        FAIL,
        Surface.FM_ANY,
        "plotColorPalette is defined from palette hexes",
        "The nested xyChart block plus plotColorPalette are the family floor.",
        f"{REF_STYLING} [06]",
        fams=(Fam.XYCHART,),
        path=(*TV, "xyChart", "plotColorPalette"),
    ),
    Rule(
        "xy-background",
        FAIL,
        Surface.FM,
        "the chart background is the canvas",
        "backgroundColor carries the canvas.",
        f"{REF_THEMING} [03]",
        fams=(Fam.XYCHART,),
        path=(*TV, "xyChart", "backgroundColor"),
        expect=CANVAS,
    ),
    Rule(
        "xy-css-bars",
        FAIL,
        Surface.CSS,
        "bars composite the translucent law at .75 under 1.5px hue strokes",
        "The engine strokes each bar in its own hue at width zero.",
        f"{REF_STYLING} [06]",
        fams=(Fam.XYCHART,),
        pattern=".bar-plot-0 rect{fill-opacity:.75;stroke-width:1.5px}",
        when=Cond.BAR,
    ),
    Rule(
        "xy-css-labels",
        FAIL,
        Surface.CSS,
        "data labels cap at the small ramp step",
        "showDataLabel prints values at a size computed from bar width; the .plot text stamp caps it.",
        f"{REF_STYLING} [06]",
        fams=(Fam.XYCHART,),
        pattern=".plot text{font-size:11px}",
        when=Cond.DATALABEL,
    ),
    # --- [RADAR]
    Rule(
        "radar-nested",
        FAIL,
        Surface.DERIVED,
        "the nested radar block carries axisColor Comment, graticuleColor Selection, curveOpacity .35, curveStrokeWidth 2",
        "Curves fill at .35 while their full-hue 2px strokes hold the border law.",
        f"{REF_STYLING} [06]",
        fams=(Fam.RADAR,),
    ),
    Rule(
        "radar-margins",
        FAIL,
        Surface.DERIVED,
        "the radar config margins own axis-label clearance",
        "Axis labels clip at the viewport edge; the config margins own that clearance.",
        f"{REF_STYLING} [06]",
        fams=(Fam.RADAR,),
    ),
    Rule("radar-curves", FAIL, Surface.DERIVED, "each curve carries its ordinal cScale var", CANON_ORDINAL, f"{REF_STYLING} [06]", fams=(Fam.RADAR,)),
    # --- [TREEMAP]
    Rule(
        "treemap-classdef-ban",
        FAIL,
        Surface.BODY_NONE,
        "a themed treemap carries no classes",
        "classDef on a branch emits inline !important fills that lock out every stylesheet correction.",
        f"{REF_STYLING} [05]",
        fams=(Fam.TREEMAP,),
        pattern=r"^\s*classDef\s",
    ),
    Rule(
        "treemap-ordinals",
        FAIL,
        Surface.DERIVED,
        "every cScaleN pairs a cScalePeerN stroke and a Foreground cScaleLabelN",
        "Branch hues assign from cScale with cScalePeer strokes and Foreground labels over composited tiles.",
        f"{REF_STYLING} [06]",
        fams=(Fam.TREEMAP,),
    ),
    Rule(
        "treemap-css-leaf",
        FAIL,
        Surface.CSS,
        "leaves composite at .45 under 1.5px hue borders",
        CANON_ALPHA,
        f"{REF_STYLING} [06]",
        fams=(Fam.TREEMAP,),
        pattern=".treemapLeaf{fill-opacity:.45;stroke-width:1.5px}",
    ),
    Rule(
        "treemap-css-section",
        FAIL,
        Surface.CSS,
        "sections recess to Darker while peer borders carry branch identity",
        "Sections recess through the .treemapSection stamp.",
        f"{REF_STYLING} [06]",
        fams=(Fam.TREEMAP,),
        pattern=".treemapSection{fill:#21222C!important",
    ),
    Rule(
        "treemap-css-title",
        FAIL,
        Surface.CSS,
        "section headers take the container-title stamp",
        CANON_TITLE,
        f"{REF_STYLING} [06]",
        fams=(Fam.TREEMAP,),
        pattern=".treemapSectionLabel{font-size:13.5px;font-weight:700}",
    ),
    # --- [C4]
    Rule(
        "c4-config",
        FAIL,
        Surface.FM_ANY,
        "element colors land through c4: config keys",
        "Element colors are config keys under c4:, so the palette lands without per-element calls.",
        f"{REF_STYLING} [06]",
        fams=(Fam.C4,),
        path=("c4",),
    ),
    Rule(
        "c4-person-vars",
        FAIL,
        Surface.DERIVED,
        "personBorder Purple and personBkg Selection feed from the theme block",
        "C4 reads personBorder/personBkg from the base block.",
        f"{REF_THEMING} [03]",
        fams=(Fam.C4,),
    ),
    Rule(
        "c4-relstyle",
        FAIL,
        Surface.DERIVED,
        "UpdateRelStyle colors every relation",
        "UpdateRelStyle colors each relation and offsets its label clear of boxes.",
        f"{REF_STYLING} [06]",
        fams=(Fam.C4,),
    ),
    Rule(
        "c4-css-boundary",
        FAIL,
        Surface.CSS,
        "the hardcoded #444444 boundary re-inks Lavender through the attribute hook",
        "Boundary strokes and titles hardcode #444444; the attribute hooks re-ink them.",
        f"{REF_STYLING} [06]",
        fams=(Fam.C4,),
        pattern="rect[stroke='#444444']{stroke:#D6BCFA",
    ),
    Rule(
        "c4-css-boundary-text",
        FAIL,
        Surface.CSS,
        "the hardcoded #444444 titles re-ink Lavender",
        "text[fill='#444444'] re-inks boundary titles.",
        f"{REF_STYLING} [06]",
        fams=(Fam.C4,),
        pattern="text[fill='#444444']{fill:#D6BCFA}",
    ),
    Rule(
        "c4-css-arrowhead",
        FAIL,
        Surface.CSS,
        "the -arrowhead marker takes canon Pink at the unified scale",
        CANON_MARKER,
        f"{REF_STYLING} [06]",
        fams=(Fam.C4,),
        pattern="[id$='-arrowhead'] path{fill:#FF79C6",
    ),
    Rule(
        "c4-css-arrowend",
        FAIL,
        Surface.CSS,
        "the -arrowend marker takes canon Pink at the unified scale",
        CANON_MARKER,
        f"{REF_STYLING} [06]",
        fams=(Fam.C4,),
        pattern="[id$='-arrowend'] path{fill:#FF79C6",
    ),
    Rule(
        "c4-css-sprite",
        FAIL,
        Surface.CSS,
        "baked person sprites retire",
        "Person sprites are baked raster images - image{display:none} retires them.",
        f"{REF_STYLING} [06]",
        fams=(Fam.C4,),
        pattern="image{display:none}",
        when=Cond.PERSON,
    ),
    # --- [ARCHITECTURE]
    Rule(
        "arch-seed",
        FAIL,
        Surface.FM_ANY,
        "architecture.seed is the deterministic lock",
        "randomize: false alone never guarantees identical renders.",
        f"{REF_CONFIG} [06]",
        fams=(Fam.ARCHITECTURE,),
        path=("architecture", "seed"),
    ),
    Rule(
        "arch-edge",
        FAIL,
        Surface.FM,
        "archEdgeColor is Pink",
        "archEdge* carry the control-flow hue.",
        f"{REF_THEMING} [03]",
        fams=(Fam.ARCHITECTURE,),
        path=(*TV, "archEdgeColor"),
        expect=PINK,
    ),
    Rule(
        "arch-arrow",
        FAIL,
        Surface.FM,
        "archEdgeArrowColor is Pink - it derives gray unless set",
        "Arrowheads are polygon.arrow filled from archEdgeArrowColor, which derives gray unless set.",
        f"{REF_STYLING} [06]",
        fams=(Fam.ARCHITECTURE,),
        path=(*TV, "archEdgeArrowColor"),
        expect=PINK,
    ),
    Rule(
        "arch-edge-width",
        FAIL,
        Surface.FM,
        "archEdgeWidth is the standing 2",
        CANON_LADDER,
        f"{REF_THEMING} [03]",
        fams=(Fam.ARCHITECTURE,),
        path=(*TV, "archEdgeWidth"),
        expect="2",
    ),
    Rule(
        "arch-group-border",
        FAIL,
        Surface.FM,
        "archGroupBorderColor is Lavender",
        "archGroupBorderColor with the 5 4 dash rhythm draws the Lavender containment.",
        f"{REF_STYLING} [06]",
        fams=(Fam.ARCHITECTURE,),
        path=(*TV, "archGroupBorderColor"),
        expect=LAVENDER,
    ),
    Rule(
        "arch-group-width",
        FAIL,
        Surface.FM,
        "archGroupBorderWidth is the container 1",
        CANON_LADDER,
        f"{REF_THEMING} [03]",
        fams=(Fam.ARCHITECTURE,),
        path=(*TV, "archGroupBorderWidth"),
        expect="1",
    ),
    Rule(
        "arch-css-icon",
        FAIL,
        Surface.CSS,
        "the hardcoded blue icon plate re-fills to Selection",
        "Built-in icons hardcode a blue plate the .architecture-service svg rect stamp re-fills.",
        f"{REF_STYLING} [06]",
        fams=(Fam.ARCHITECTURE,),
        pattern=".architecture-service svg rect{fill:#44475A!important}",
    ),
    Rule(
        "arch-css-dash",
        FAIL,
        Surface.CSS,
        "group borders dash at the 5 4 container rhythm",
        CANON_LADDER,
        f"{REF_STYLING} [06]",
        fams=(Fam.ARCHITECTURE,),
        pattern="stroke-dasharray:5 4",
    ),
    Rule(
        "arch-align",
        FAIL,
        Surface.DERIVED,
        "align rows lock the fcose grid both ways",
        "The port pairs plus align row|column rows fully determine the grid; unaligned members scatter diagonally.",
        f"{REF_STYLING} [06]",
        fams=(Fam.ARCHITECTURE,),
    ),
    # --- [PACKET]
    Rule(
        "packet-tv-ban",
        FAIL,
        Surface.FM_NONE,
        "the nested themeVariables.packet block half-applies and stays out",
        "Packet themes ONLY via themeCSS classes; the nested block half-applies.",
        f"{REF_STYLING} [05]",
        fams=(Fam.PACKET,),
        path=(*TV, "packet"),
    ),
    Rule(
        "packet-css-block",
        FAIL,
        Surface.DERIVED,
        "field blocks composite a wash-tier fill of one hue under a 1.5px full-hue stroke",
        "Fields composite the translucent law as one hue family - a bit layout is one structure, never a rainbow.",
        f"{REF_STYLING} [06]",
        fams=(Fam.PACKET,),
    ),
    Rule(
        "packet-css-label",
        FAIL,
        Surface.CSS,
        "field labels ink Foreground",
        "The .packet* class stamp owns the whole surface.",
        f"{REF_STYLING} [06]",
        fams=(Fam.PACKET,),
        pattern=".packetLabel{fill:#F8F8F2",
    ),
    Rule(
        "packet-css-byte",
        FAIL,
        Surface.CSS,
        "bit indices ink Comment at 11px",
        "Bit indices ride Comment at the small ramp step.",
        f"{REF_STYLING} [06]",
        fams=(Fam.PACKET,),
        pattern=".packetByte{fill:#6272A4",
    ),
    Rule(
        "packet-css-title",
        FAIL,
        Surface.CSS,
        "the packet title takes the Lavender container-title stamp",
        CANON_TITLE,
        f"{REF_STYLING} [06]",
        fams=(Fam.PACKET,),
        pattern=".packetTitle{fill:#D6BCFA;font-size:13.5px;font-weight:700}",
    ),
    # --- [TIMELINE]
    Rule(
        "timeline-ordinals",
        FAIL,
        Surface.DERIVED,
        "every cScaleN pairs a Foreground cScaleLabelN over the composited fills",
        "Theme resolution strips ordinal alpha, so translucency rides fill-opacity while Foreground labels carry the ink.",
        f"{REF_STYLING} [06]",
        fams=(Fam.TIMELINE,),
    ),
    Rule(
        "timeline-css-alpha",
        FAIL,
        Surface.CSS,
        "event chips composite at .5 fill-opacity",
        "Translucency rides .node-bkg{fill-opacity:.5} with per-section full-hue borders.",
        f"{REF_STYLING} [06]",
        fams=(Fam.TIMELINE,),
        pattern=".node-bkg{fill-opacity:.5",
    ),
    Rule(
        "timeline-css-lines",
        FAIL,
        Surface.CSS,
        "engine underline strips retire",
        "Kill [class^='node-line'].",
        f"{REF_STYLING} [06]",
        fams=(Fam.TIMELINE,),
        pattern="[class^='node-line']{stroke:none!important}",
    ),
    Rule(
        "timeline-css-section",
        FAIL,
        Surface.CSS,
        "per-section borders start at .section--1",
        "Section classes index from -1, so the first section is .section--1.",
        f"{REF_STYLING} [06]",
        fams=(Fam.TIMELINE,),
        pattern=".section--1",
        when=Cond.SECTION,
    ),
    Rule(
        "timeline-css-axis",
        FAIL,
        Surface.CSS,
        "the unclassed axis restyles by attribute onto the Comment wayfinding system",
        "The axis is line[stroke-width='4'] pulled to ladder weight in Comment.",
        f"{REF_STYLING} [06]",
        fams=(Fam.TIMELINE,),
        pattern="line[stroke-width='4']{stroke:#6272A4;stroke-width:2px}",
    ),
    Rule(
        "timeline-css-connector",
        FAIL,
        Surface.CSS,
        "dashed connectors restyle to the trace rhythm in Comment",
        CANON_LADDER,
        f"{REF_STYLING} [06]",
        fams=(Fam.TIMELINE,),
        pattern="line[stroke-dasharray='5,5']{stroke:#6272A4;stroke-width:1.5px;stroke-dasharray:4 6}",
    ),
    Rule(
        "timeline-css-arrowhead",
        FAIL,
        Surface.CSS,
        "the one shared marker takes the wayfinding hue",
        "One marker serves the axis and every connector, so the wayfinding layer holds one color.",
        f"{REF_STYLING} [06]",
        fams=(Fam.TIMELINE,),
        pattern="[id$='-arrowhead'] path{fill:#6272A4}",
    ),
    # --- [GITGRAPH]
    Rule(
        "git-rails",
        FAIL,
        Surface.DERIVED,
        "each branch rail carries its gitN hue and dark gitBranchLabelN ink",
        CANON_ORDINAL,
        f"{REF_STYLING} [06]",
        fams=(Fam.GITGRAPH,),
    ),
    Rule(
        "git-canvas-core",
        FAIL,
        Surface.FM,
        "primaryColor holds the canvas so merge cores render as hollow rings",
        "Merge dot cores fill primaryColor, so a canvas-valued primaryColor renders merges as hollow rings.",
        f"{REF_STYLING} [06]",
        fams=(Fam.GITGRAPH,),
        path=(*TV, "primaryColor"),
        expect=CANVAS,
    ),
    Rule(
        "git-commit-ink",
        FAIL,
        Surface.FM,
        "commit ids ink Foreground",
        "Commit ids ride Foreground on recessed chips.",
        f"{REF_THEMING} [03]",
        fams=(Fam.GITGRAPH,),
        path=(*TV, "commitLabelColor"),
        expect=FOREGROUND,
    ),
    Rule(
        "git-commit-chip",
        FAIL,
        Surface.FM,
        "commit id chips recess to Darker",
        CANON_BACKING,
        f"{REF_THEMING} [03]",
        fams=(Fam.GITGRAPH,),
        path=(*TV, "commitLabelBackground"),
        expect=DARKER,
    ),
    Rule(
        "git-tag-chip",
        FAIL,
        Surface.CSS,
        "the tag chip stamps translucent gold under a full gold border through the class route",
        CANON_YELLOW,
        f"{REF_THEMING} [04]",
        fams=(Fam.GITGRAPH,),
        pattern=".tag-label-bkg{fill:#FFD86654;stroke:#FFD866}",
        when=Cond.TAG,
    ),
    Rule(
        "git-tag-ink",
        FAIL,
        Surface.CSS,
        "the tag label inks Foreground - white ink on gold",
        CANON_YELLOW,
        f"{REF_THEMING} [04]",
        fams=(Fam.GITGRAPH,),
        pattern=".tag-label{fill:#F8F8F2}",
        when=Cond.TAG,
    ),
    Rule(
        "git-css-arrow",
        FAIL,
        Surface.CSS,
        "branch rails pull from the engine 8px to the standing 2px",
        "Branch rails are .arrow paths the engine draws at 8px.",
        f"{REF_STYLING} [06]",
        fams=(Fam.GITGRAPH,),
        pattern=".arrow{stroke-width:2px}",
    ),
    Rule(
        "git-css-dots",
        FAIL,
        Surface.CSS,
        "commit dots scale .75 preserving merge and highlight ring ratios",
        CANON_MARKER,
        f"{REF_STYLING} [06]",
        fams=(Fam.GITGRAPH,),
        pattern="scale(.75)",
    ),
    # --- [KANBAN]
    Rule(
        "kanban-ordinals",
        FAIL,
        Surface.DERIVED,
        "the full cScale0-7 range recesses columns under Lavender cScaleLabel0-7 titles",
        "Column classes index from section-1, so the full ordinal range is set.",
        f"{REF_STYLING} [06]",
        fams=(Fam.KANBAN,),
    ),
    Rule(
        "kanban-cards",
        FAIL,
        Surface.DERIVED,
        "cards fill the background variable under nodeBorder strokes",
        "Cards fill background under nodeBorder Purple.",
        f"{REF_STYLING} [06]",
        fams=(Fam.KANBAN,),
    ),
    Rule(
        "kanban-css-title",
        FAIL,
        Surface.CSS,
        "column titles take the 13.5px/700 Lavender container-title stamp",
        CANON_TITLE,
        f"{REF_STYLING} [06]",
        fams=(Fam.KANBAN,),
        pattern=".cluster-label .nodeLabel{font-size:13.5px;font-weight:700;color:#D6BCFA}",
    ),
    Rule(
        "kanban-priority",
        FAIL,
        Surface.DERIVED,
        "hardcoded priority bar colors remap onto the severity ladder at 3px",
        "Priority bars hardcode named colors; the attribute hooks remap them.",
        f"{REF_STYLING} [06]",
        fams=(Fam.KANBAN,),
    ),
    # --- [TREEVIEW]
    Rule(
        "treeview-label",
        FAIL,
        Surface.FM,
        "treeView.labelColor inks Foreground",
        "Config labelColor/lineColor/labelFontSize land directly.",
        f"{REF_STYLING} [06]",
        fams=(Fam.TREEVIEW,),
        path=("treeView", "labelColor"),
        expect=FOREGROUND,
    ),
    Rule(
        "treeview-line",
        FAIL,
        Surface.FM,
        "treeView.lineColor rides Comment",
        "Tree lines ride the muted wayfinding hue.",
        f"{REF_STYLING} [06]",
        fams=(Fam.TREEVIEW,),
        path=("treeView", "lineColor"),
        expect=COMMENT,
    ),
    Rule(
        "treeview-size",
        FAIL,
        Surface.FM_ANY,
        "treeView.labelFontSize is pinned",
        "labelFontSize lands directly through config.",
        f"{REF_STYLING} [06]",
        fams=(Fam.TREEVIEW,),
        path=("treeView", "labelFontSize"),
    ),
    Rule(
        "treeview-css-highlight",
        FAIL,
        Surface.CSS,
        "the highlight band is the yellow-law chip",
        CANON_YELLOW,
        f"{REF_STYLING} [06]",
        fams=(Fam.TREEVIEW,),
        pattern=".treeView-highlight-bg{fill:#FFD86626;stroke:#FFD866}",
        when=Cond.HIGHLIGHT,
    ),
    Rule(
        "treeview-css-description",
        FAIL,
        Surface.CSS,
        "descriptions ink Cyan as typed annotation",
        "Cyan separates information from the gold attention chip.",
        f"{REF_STYLING} [06]",
        fams=(Fam.TREEVIEW,),
        pattern=".treeView-node-description{fill:#8BE9FD}",
        when=Cond.DESCRIPTION,
    ),
    # --- [VENN]
    Rule(
        "venn-set-ink",
        FAIL,
        Surface.FM,
        "set labels ink Foreground",
        "Per-set Foreground label ink.",
        f"{REF_STYLING} [06]",
        fams=(Fam.VENN,),
        path=(*TV, "vennSetTextColor"),
        expect=FOREGROUND,
    ),
    Rule(
        "venn-title-ink",
        FAIL,
        Surface.FM,
        "the title inks Foreground",
        "The title stamp pulls onto the type ramp.",
        f"{REF_STYLING} [06]",
        fams=(Fam.VENN,),
        path=(*TV, "vennTitleTextColor"),
        expect=FOREGROUND,
        when=Cond.TITLE,
    ),
    Rule(
        "venn-styles",
        FAIL,
        Surface.DERIVED,
        "every set carries a style row with fill, fill-opacity, stroke, and color",
        "The translucent law lands natively as hue fills at .3 under full-hue strokes.",
        f"{REF_STYLING} [06]",
        fams=(Fam.VENN,),
    ),
    Rule(
        "venn-css-circle",
        FAIL,
        Surface.CSS,
        "set labels pull onto the type ramp",
        "Set and intersection label sizes scale from canvas width at engine ratios; the stamps pull them onto the ramp.",
        f"{REF_STYLING} [06]",
        fams=(Fam.VENN,),
        pattern=".venn-circle text{",
    ),
    Rule(
        "venn-css-title",
        FAIL,
        Surface.CSS,
        "the title stamp pulls onto the ramp",
        CANON_TITLE,
        f"{REF_STYLING} [06]",
        fams=(Fam.VENN,),
        pattern=".venn-title{",
        when=Cond.TITLE,
    ),
    # --- [WARDLEY]
    Rule(
        "wardley-no-css",
        FAIL,
        Surface.FM_NONE,
        "wardley emits no stylesheet - themeCSS never reaches it",
        "The family emits no stylesheet, so themeCSS, the mono stack, and font metrics never reach it.",
        f"{REF_STYLING} [05]",
        fams=(Fam.WARDLEY,),
        path=("themeCSS",),
    ),
    Rule(
        "wardley-nested",
        FAIL,
        Surface.FM_ANY,
        "colors nest under the wardley block",
        "Colors nest under wardley: because only nested colors land.",
        f"{REF_STYLING} [06]",
        fams=(Fam.WARDLEY,),
        path=(*TV, "wardley"),
    ),
    Rule(
        "wardley-evolution",
        FAIL,
        Surface.FM,
        "wardleyEvolutionColor marks sanctioned movement in Green",
        "Green marks sanctioned movement on the evolution trend.",
        f"{REF_STYLING} [06]",
        fams=(Fam.WARDLEY,),
        path=(*TV, "wardleyEvolutionColor"),
        expect=GREEN,
        when=Cond.EVOLVE,
    ),
    # --- [CYNEFIN]
    Rule(
        "cynefin-seed",
        FAIL,
        Surface.FM_ANY,
        "cynefin.seed pins the boundary jitter",
        "cynefin.seed pins the boundary jitter.",
        f"{REF_STYLING} [06]",
        fams=(Fam.CYNEFIN,),
        path=("cynefin", "seed"),
    ),
    Rule(
        "cynefin-domains",
        FAIL,
        Surface.DERIVED,
        "the five domain tints carry wash-tier alphas with Red cliff and Lavender captions",
        "Domain *Bg values multiply by .4 fill-opacity, so a wash-tier hex lands as a legible field.",
        f"{REF_STYLING} [06]",
        fams=(Fam.CYNEFIN,),
    ),
    Rule(
        "cynefin-css-item",
        FAIL,
        Surface.CSS,
        "item chips ride Selection under Comment strokes",
        "Item chips ride .cynefinItem on Selection.",
        f"{REF_STYLING} [06]",
        fams=(Fam.CYNEFIN,),
        pattern=".cynefinItem{fill:#44475A;stroke:#6272A4}",
    ),
    Rule(
        "cynefin-css-ink",
        FAIL,
        Surface.CSS,
        "item text inks Foreground",
        "Items carry Foreground ink.",
        f"{REF_STYLING} [06]",
        fams=(Fam.CYNEFIN,),
        pattern=".cynefinItemText{fill:#F8F8F2}",
    ),
    # --- [RAILROAD]
    Rule(
        "railroad-config",
        FAIL,
        Surface.DERIVED,
        "the railroad block carries gold-law terminals, Selection nonterminals, Comment rails, Pink markers, Lavender rule names",
        "The whole visual surface is the railroad: config block.",
        f"{REF_STYLING} [06]",
        fams=(Fam.RAILROAD,),
    ),
    Rule(
        "railroad-marker-radius",
        FAIL,
        Surface.FM,
        "start and end dots take the -25% radius",
        CANON_MARKER,
        f"{REF_THEMING} [05]",
        fams=(Fam.RAILROAD,),
        path=("railroad", "markerRadius"),
        expect=4,
    ),
    Rule(
        "railroad-stroke",
        FAIL,
        Surface.FM,
        "rails run the standing 2",
        CANON_LADDER,
        f"{REF_STYLING} [06]",
        fams=(Fam.RAILROAD,),
        path=("railroad", "strokeWidth"),
        expect=2,
    ),
    # --- [SWIMLANE]
    Rule(
        "swim-css-title-band",
        FAIL,
        Surface.CSS,
        "lane title bands recess to Darker",
        "Lane titles ride a recessed .swimlane-title band.",
        f"{REF_STYLING} [06]",
        fams=(Fam.SWIMLANE,),
        pattern=".swimlane-title{fill:#21222C}",
    ),
    Rule(
        "swim-css-walls",
        FAIL,
        Surface.CSS,
        "lane walls draw Lavender",
        "Lavender .swimlane-body walls carry the containment.",
        f"{REF_STYLING} [06]",
        fams=(Fam.SWIMLANE,),
        pattern=".swimlane-body{stroke:#D6BCFA}",
    ),
    Rule(
        "swim-css-title",
        FAIL,
        Surface.CSS,
        "lane titles take the 13.5px/700 stamp",
        CANON_TITLE,
        f"{REF_STYLING} [06]",
        fams=(Fam.SWIMLANE,),
        pattern="font-size:13.5px;font-weight:700",
    ),
    Rule(
        "swim-lane-emphasis",
        WARN,
        Surface.DERIVED,
        "a style row emphasizes the critical-path lane",
        "style laneId emphasizes the critical-path lane as a translucent band.",
        f"{REF_STYLING} [06]",
        fams=(Fam.SWIMLANE,),
    ),
    # --- [EVENTMODELING]
    Rule(
        "em-kinds",
        FAIL,
        Surface.DERIVED,
        "each frame kind used carries its em*Fill/em*Stroke pair",
        "Each kind reads its em*Fill/em*Stroke pair.",
        f"{REF_STYLING} [06]",
        fams=(Fam.EVENTMODELING,),
    ),
    Rule(
        "em-lanes",
        FAIL,
        Surface.DERIVED,
        "swimlane background pair and Pink arrowhead/relation vars are set",
        "emSwimlaneBackground* plus emArrowhead/emRelationStroke are the family floor.",
        f"{REF_STYLING} [06]",
        fams=(Fam.EVENTMODELING,),
    ),
    Rule(
        "em-css-span",
        FAIL,
        Surface.CSS,
        "frame text restores the mono stack at 13px Foreground",
        "Frame text hardcodes a bold 16px sans inside foreignObject spans.",
        f"{REF_STYLING} [06]",
        fams=(Fam.EVENTMODELING,),
        pattern=".em-box span{font-family:'SF Mono'",
    ),
    Rule(
        "em-css-code",
        FAIL,
        Surface.CSS,
        "payload code inks Cyan at 11px",
        "The .em-box code stamp inks payloads Cyan.",
        f"{REF_STYLING} [06]",
        fams=(Fam.EVENTMODELING,),
        pattern=".em-box code{color:#8BE9FD",
    ),
    Rule(
        "em-css-lane",
        FAIL,
        Surface.CSS,
        "lane titles carry Lavender mono at the container size",
        CANON_TITLE,
        f"{REF_STYLING} [06]",
        fams=(Fam.EVENTMODELING,),
        pattern=".em-swimlane text{fill:#D6BCFA",
    ),
    # --- [ISHIKAWA]
    Rule(
        "ishikawa-line",
        FAIL,
        Surface.FM,
        "lineColor carries spine, branches, arrowheads, and borders",
        "The beta reads the general variables only: lineColor draws the whole bone structure.",
        f"{REF_STYLING} [06]",
        fams=(Fam.ISHIKAWA,),
        path=(*TV, "lineColor"),
        expect=PINK,
    ),
    Rule(
        "ishikawa-bkg",
        FAIL,
        Surface.FM,
        "mainBkg fills the head and cause boxes with Selection",
        "mainBkg fills the head and cause boxes.",
        f"{REF_STYLING} [06]",
        fams=(Fam.ISHIKAWA,),
        path=(*TV, "mainBkg"),
        expect=SELECTION,
    ),
)

RULE_INDEX: dict[str, Rule] = {rule.id: rule for rule in RULES}

VAR_GROUPS: dict[str, tuple[tuple[tuple[str, ...], object], ...]] = {
    "seq-actor-vars": ((("actorBkg",), SELECTION), (("actorBorder",), PURPLE), (("actorTextColor",), FOREGROUND), (("actorLineColor",), COMMENT)),
    "seq-activation": ((("activationBkgColor",), SELECTION), (("activationBorderColor",), PURPLE)),
    "seq-note-vars": ((("noteBkgColor",), SELECTION), (("noteBorderColor",), COMMENT), (("noteTextColor",), FOREGROUND)),
    "state-composite-vars": ((("compositeBackground",), DARKER), (("compositeTitleBackground",), CANVAS), (("compositeBorder",), LAVENDER)),
    "class-note-chip": ((("noteBkgColor",), f"{GOLD}54"), (("noteBorderColor",), GOLD), (("noteTextColor",), FOREGROUND)),
    "er-banding": ((("attributeBackgroundColorOdd",), CANVAS), (("attributeBackgroundColorEven",), DARKER)),
    "gantt-task-vars": (
        (("taskBkgColor",), SELECTION),
        (("taskBorderColor",), PURPLE),
        (("taskTextColor",), FOREGROUND),
        (("taskTextOutsideColor",), FOREGROUND),
        (("taskTextDarkColor",), FOREGROUND),
    ),
    "gantt-active": ((("activeTaskBkgColor",), COMMENT), (("activeTaskBorderColor",), PURPLE)),
    "gantt-done": ((("doneTaskBkgColor",), DARKER), (("doneTaskBorderColor",), COMMENT)),
    "gantt-crit": ((("critBkgColor",), f"{RED}80"), (("critBorderColor",), RED)),
    "req-vars": (
        (("requirementBackground",), SELECTION),
        (("requirementBorderColor",), PURPLE),
        (("requirementTextColor",), FOREGROUND),
        (("relationColor",), PINK),
        (("relationLabelColor",), FOREGROUND),
    ),
    "pie-ink": ((("pieSectionTextColor",), FOREGROUND), (("pieLegendTextColor",), FOREGROUND), (("pieTitleTextColor",), FOREGROUND)),
    "quad-fills": (
        (("quadrant1Fill",), (SELECTION, DARKER, CANVAS)),
        (("quadrant2Fill",), (SELECTION, DARKER, CANVAS)),
        (("quadrant3Fill",), (SELECTION, DARKER, CANVAS)),
        (("quadrant4Fill",), (SELECTION, DARKER, CANVAS)),
    ),
    "quad-captions": (
        (("quadrant1TextFill",), LAVENDER),
        (("quadrant2TextFill",), LAVENDER),
        (("quadrant3TextFill",), LAVENDER),
        (("quadrant4TextFill",), LAVENDER),
    ),
    "radar-nested": (
        (("radar", "axisColor"), COMMENT),
        (("radar", "graticuleColor"), SELECTION),
        (("radar", "curveOpacity"), 0.35),
        (("radar", "curveStrokeWidth"), 2),
    ),
    "c4-person-vars": ((("personBorder",), PURPLE), (("personBkg",), SELECTION)),
    "kanban-cards": ((("background",), SELECTION), (("nodeBorder",), PURPLE)),
    "cynefin-domains": (
        (("cynefin", "cliffColor"), RED),
        (("cynefin", "labelColor"), LAVENDER),
        (("cynefin", "boundaryColor"), COMMENT),
        (("cynefin", "arrowColor"), PINK),
    ),
    "em-lanes": (
        (("emSwimlaneBackgroundOdd",), CANVAS),
        (("emSwimlaneBackgroundStroke",), SELECTION),
        (("emArrowhead",), PINK),
        (("emRelationStroke",), PINK),
    ),
}
VAR_GROUP_CONDS: dict[str, Cond] = {"gantt-active": Cond.ACTIVE, "gantt-done": Cond.DONE, "gantt-crit": Cond.CRIT, "class-note-chip": Cond.NOTE_CLASS}

RAILROAD_KEYS: tuple[tuple[str, object], ...] = (
    ("terminalFill", f"{GOLD}54"),
    ("terminalStroke", GOLD),
    ("terminalTextColor", FOREGROUND),
    ("nonTerminalFill", SELECTION),
    ("nonTerminalStroke", PURPLE),
    ("nonTerminalTextColor", FOREGROUND),
    ("lineColor", COMMENT),
    ("markerFill", PINK),
    ("ruleNameColor", LAVENDER),
)
CYNEFIN_WASH_KEYS = ("complexBg", "complicatedBg", "clearBg", "chaoticBg", "confusionBg")
KANBAN_PRIORITY_STAMPS = (
    "line[stroke='red']{stroke:#FF5555;stroke-width:3px}",
    "line[stroke='orange']{stroke:#FFB86C;stroke-width:3px}",
    "line[stroke='blue']{stroke:#6272A4;stroke-width:3px}",
    "line[stroke='lightblue']{stroke:#44475A;stroke-width:3px}",
)
TV_OPENING = ("darkMode", "fontFamily", "useGradient", "dropShadow")


# --- [OPERATIONS] --------------------------------------------------------------------------


def emit(row: Row, json_mode: bool) -> None:
    print(ENCODER.encode(row).decode() if json_mode else f"{row.file}:{row.line}: {row.status.upper()} canon {row.rule} {row.detail}")


def collect(paths: tuple[Path, ...]) -> tuple[tuple[Path, ...], tuple[Row, ...]]:
    files: list[Path] = []
    rows: list[Row] = []
    for path in paths:
        if path.is_dir():
            found = sorted(child for child in path.rglob("*") if child.suffix in SUFFIXES and child.is_file())
            files.extend(found)
            rows.extend([] if found else [Row(str(path), 0, FAIL, "collect", "empty target directory")])
        elif path.suffix in SUFFIXES and path.is_file():
            files.append(path)
        else:
            rows.append(Row(str(path), 0, FAIL, "collect", "not a markdown or mmd target"))
    return tuple(dict.fromkeys(files)), tuple(rows)


def read_fences(path: Path) -> tuple[Fence, ...]:
    text = path.read_text(encoding="utf-8")
    if path.suffix == ".mmd":
        return (Fence(str(path), 1, text),) if text.strip() else ()
    out: list[Fence] = []
    lines = text.splitlines()
    index = 0
    while index < len(lines):
        opened = FENCE_OPEN.match(lines[index])
        if opened is None:
            index += 1
            continue
        quoted = ">" in opened.group(1)
        closed_by = re.compile(rf"^(?:\s*>)*\s*{re.escape(opened.group(2)[0])}{{{len(opened.group(2))},}}\s*$")
        body: list[str] = []
        cursor = index + 1
        while cursor < len(lines) and closed_by.match(lines[cursor]) is None:
            body.append(BLOCKQUOTE.sub("", lines[cursor]) if quoted else lines[cursor])
            cursor += 1
        out.append(Fence(str(path), index + 2, "\n".join(body)))
        index = cursor + 1
    return tuple(out)


def split_frontmatter(body: str) -> tuple[str, str]:
    lines = body.splitlines()
    if not lines or lines[0].strip() != "---":
        return "", body
    close = next((index for index, line in enumerate(lines[1:], 1) if line.strip() == "---"), -1)
    return ("", body) if close < 0 else ("\n".join(lines[1:close]), "\n".join(lines[close + 1 :]))


def parse_doc(fence: Fence) -> Doc | None:
    fm_text, rest = split_frontmatter(fence.body)
    header = next((line.strip().split()[0] for line in rest.splitlines() if line.strip() and not line.strip().startswith("%%")), "")
    fam = HEADER_FAMILY.get(header)
    if fam is None:
        return None
    try:
        loaded = YAML(typ="safe").load(fm_text) if fm_text else None
    except YAMLError:
        loaded = MISSING
    config = loaded.get("config") if is_table(loaded) else loaded
    css = config.get("themeCSS", "") if is_table(config) else ""
    return Doc(fence, fam, header, fm_text, config, css if isinstance(css, str) else "", rest)


def is_table(value: object) -> TypeIs[Mapping[str, object]]:
    return isinstance(value, Mapping)


def walk(config: object, path: tuple[str, ...]) -> object:
    current = config
    for key in path:
        if not is_table(current) or key not in current:
            return MISSING
        current = current[key]
    return current


def condition_holds(doc: Doc, when: Cond) -> bool:
    if when is Cond.ALWAYS:
        return True
    pattern, scope = CONDITIONS[when]
    return pattern.search(doc.body if scope == "body" else doc.fm_text) is not None


def derived(doc: Doc, rule_id: str, detail: str = "") -> Row:
    rule = RULE_INDEX[rule_id]
    return Row(doc.fence.file, doc.fence.line, rule.level, rule.id, detail or rule.detail)


def matches(value: object, expect: object) -> bool:
    return value in expect if isinstance(expect, tuple) else value == expect


def var_group_rows(doc: Doc, rule_id: str) -> tuple[Row, ...]:
    if (when := VAR_GROUP_CONDS.get(rule_id, Cond.ALWAYS)) is not Cond.ALWAYS and not condition_holds(doc, when):
        return ()
    return tuple(
        derived(
            doc,
            rule_id,
            f"{'.'.join(path)} must be {expect!r}, found {found!r}"
            if (found := walk(doc.config, (*TV, *path))) is not MISSING
            else f"{'.'.join(path)} is missing",
        )
        for path, expect in VAR_GROUPS[rule_id]
        if not matches(walk(doc.config, (*TV, *path)), expect)
    )


def rule_rows(doc: Doc) -> tuple[Row, ...]:
    rows: list[Row] = []
    for rule in RULES:
        if (rule.fams and doc.fam not in rule.fams) or rule.surface is Surface.DERIVED or not condition_holds(doc, rule.when):
            continue
        match rule.surface:
            case Surface.FM:
                found = walk(doc.config, rule.path)
                if not matches(found, rule.expect):
                    where = ".".join(rule.path)
                    rows.append(
                        Row(
                            doc.fence.file,
                            doc.fence.line,
                            rule.level,
                            rule.id,
                            f"{where} must be {rule.expect!r}, found {'nothing' if found is MISSING else repr(found)}",
                        )
                    )
            case Surface.FM_ANY:
                if walk(doc.config, rule.path) is MISSING:
                    rows.append(Row(doc.fence.file, doc.fence.line, rule.level, rule.id, f"{'.'.join(rule.path)} is required: {rule.detail}"))
            case Surface.FM_VALUE:
                found = walk(doc.config, rule.path)
                if found is not MISSING and not matches(found, rule.expect):
                    rows.append(
                        Row(doc.fence.file, doc.fence.line, rule.level, rule.id, f"{'.'.join(rule.path)} must be {rule.expect!r}, found {found!r}")
                    )
            case Surface.FM_NONE:
                if walk(doc.config, rule.path) is not MISSING:
                    rows.append(Row(doc.fence.file, doc.fence.line, rule.level, rule.id, f"{'.'.join(rule.path)} must not be set: {rule.detail}"))
            case Surface.CSS:
                if rule.pattern not in doc.css:
                    rows.append(Row(doc.fence.file, doc.fence.line, rule.level, rule.id, f"themeCSS stamp missing or wrong: {rule.pattern}"))
            case Surface.BODY:
                if re.search(rule.pattern, doc.body, re.MULTILINE) is None:
                    rows.append(Row(doc.fence.file, doc.fence.line, rule.level, rule.id, rule.detail))
            case Surface.BODY_NONE:
                if re.search(rule.pattern, doc.body, re.MULTILINE) is not None:
                    rows.append(Row(doc.fence.file, doc.fence.line, rule.level, rule.id, rule.detail))
            case Surface.DERIVED:
                pass
    return tuple(rows)


def hex_rows(doc: Doc) -> tuple[Row, ...]:
    rows: list[Row] = []
    for offset, line in enumerate(doc.fence.body.splitlines()):
        for token in HEX_SCAN.findall(line):
            value = token.upper()
            at = doc.fence.line + offset
            if len(value) == 4:
                rows.extend(
                    []
                    if value in {hook.upper() for hook in ENGINE_HOOKS_SHORT}
                    else [Row(doc.fence.file, at, FAIL, "hex-off-palette", f"short hex {value} is not a documented engine hook")]
                )
                continue
            base, alpha = value[:7], value[7:9]
            if base not in PALETTE and base not in ENGINE_HOOKS:
                rows.append(Row(doc.fence.file, at, FAIL, "hex-off-palette", f"{value} is not a palette hex or engine hook"))
            elif alpha and alpha not in CHIP_ALPHAS.get(base, frozenset()) | (WASH_ALPHAS if base in ACCENTS else frozenset()):
                rows.append(Row(doc.fence.file, at, FAIL, "hex-alpha", f"{value} carries an unsanctioned alpha for its hue tier"))
    return tuple(rows)


def yellow_rows(doc: Doc) -> tuple[Row, ...]:
    rows: list[Row] = []
    statements = [match.group(2) for line in doc.body.splitlines() for match in [CLASSDEF_LINE.match(line)] if match]
    statements += [match.group(1) for line in doc.body.splitlines() for match in [STYLE_LINE.match(line)] if match]
    statements += [decls for _selector, decls in CSS_BLOCK.findall(doc.css)]
    rows.extend(
        Row(doc.fence.file, doc.fence.line, FAIL, "yellow-dark-ink", "gold fill paired with #282A36 ink")
        for statement in statements
        if re.search(r"fill:\s*#FFD866", statement, re.IGNORECASE)
        and re.search(r"(?:color|fill)\s*:\s*#282A36", statement.split("fill:", 1)[-1], re.IGNORECASE)
    )
    for bg_key, ink_key in YELLOW_INK_PAIRS:
        pairs = _sibling_pairs(doc.config, bg_key, ink_key)
        rows.extend(
            Row(doc.fence.file, doc.fence.line, FAIL, "yellow-dark-ink", f"{bg_key} gold surface paired with {ink_key} dark ink")
            for bg, ink in pairs
            if isinstance(bg, str) and bg.upper().startswith(GOLD) and ink == CANVAS
        )
    return tuple(rows)


def _sibling_pairs(node: object, bg_key: str, ink_key: str) -> tuple[tuple[object, object], ...]:
    if not is_table(node):
        return ()
    here = ((node[bg_key], node[ink_key]),) if bg_key in node and ink_key in node else ()
    return here + tuple(pair for value in node.values() for pair in _sibling_pairs(value, bg_key, ink_key))


def _style_payload(line: str) -> str:
    if match := CLASSDEF_LINE.match(line):
        return match.group(2)
    if match := STYLE_LINE.match(line):
        return match.group(1)
    return match.group(1) if (match := VENN_STYLE_LINE.match(line)) else ""


def statement_rows(doc: Doc) -> tuple[Row, ...]:
    rows: list[Row] = []
    defs: list[tuple[int, str, str]] = []
    for offset, line in enumerate(doc.body.splitlines()):
        at = doc.fence.line + offset
        if match := CLASSDEF_LINE.match(line):
            defs.append((at, match.group(1), match.group(2)))
        style = _style_payload(line)
        if style and FILL_OPAQUE_ACCENT.search(style) and "fill-opacity" not in style:
            rows.append(Row(doc.fence.file, at, FAIL, "accent-fill-opaque", "opaque accent fill without alpha or fill-opacity"))
        if doc.fam is Fam.QUADRANT and HEX8.search(line):
            rows.append(Row(doc.fence.file, at, FAIL, "quad-hex8", "quadrant point styles reject 8-digit hex"))
    if doc.fam is not Fam.QUADRANT:
        rows.extend(
            Row(doc.fence.file, at, FAIL, "classdef-color", f"classDef {name} lacks an explicit color:")
            for at, name, style in defs
            if "color:" not in style
        )
    if doc.fam in {Fam.FLOWCHART, Fam.SWIMLANE} and len(defs) < 3:
        rows.append(derived(doc, "class-floor"))
    if doc.fam is Fam.REQUIREMENT and len(defs) < 2:
        rows.append(derived(doc, "req-class-split"))
    return tuple(rows)


def css_rows(doc: Doc) -> tuple[Row, ...]:
    rows: list[Row] = []
    if ">" in doc.css:
        rows.append(derived(doc, "css-child-combinator"))
    if "text-transform" in doc.css:
        rows.append(derived(doc, "css-text-transform"))
    if "scale(.64)" in doc.fence.body:
        rows.append(derived(doc, "stale-scale"))
    rows.extend(
        derived(doc, "container-title-stamp", f"selector {selector.strip()} lacks the 13.5px/700 stamp")
        for selector, decls in CSS_BLOCK.findall(doc.css)
        if ("cluster-label" in selector or ".sectionTitle" in selector) and not ("font-size:13.5px" in decls and "font-weight:700" in decls)
    )
    if doc.fam is Fam.PACKET:
        block = next((decls for selector, decls in CSS_BLOCK.findall(doc.css) if ".packetBlock" in selector), None)
        wash = block is not None and re.search(r"fill:#[0-9A-Fa-f]{6}(1A|26|33|4D)", block) is not None and "stroke-width:1.5px" in block
        rows.extend([] if wash else [derived(doc, "packet-css-block")])
    return tuple(rows)


def ordinal_rows(doc: Doc) -> tuple[Row, ...]:
    tv = walk(doc.config, TV)
    keys = frozenset(tv) if is_table(tv) else frozenset()
    scales = {int(match.group(1)) for key in keys if (match := re.fullmatch(r"cScale(\d+)", key))}
    rows: list[Row] = []
    if doc.fam in {Fam.TIMELINE, Fam.TREEMAP}:
        rule = "timeline-ordinals" if doc.fam is Fam.TIMELINE else "treemap-ordinals"
        rows.extend(
            derived(doc, rule, f"cScaleLabel{index} must ink Foreground beside cScale{index}")
            for index in sorted(scales)
            if walk(doc.config, (*TV, f"cScaleLabel{index}")) != FOREGROUND
        )
        if doc.fam is Fam.TREEMAP:
            rows.extend(
                derived(doc, rule, f"cScalePeer{index} is missing beside cScale{index}")
                for index in sorted(scales)
                if f"cScalePeer{index}" not in keys
            )
    if doc.fam is Fam.KANBAN:
        rows.extend(
            derived(doc, "kanban-ordinals", f"cScale{index} must recess to Darker")
            for index in range(KANBAN_RANGE)
            if walk(doc.config, (*TV, f"cScale{index}")) != DARKER
        )
        rows.extend(
            derived(doc, "kanban-ordinals", f"cScaleLabel{index} must ink Lavender")
            for index in range(KANBAN_RANGE)
            if walk(doc.config, (*TV, f"cScaleLabel{index}")) != LAVENDER
        )
    if doc.fam is Fam.JOURNEY:
        rows.extend(derived(doc, "journey-fills", f"fillType{index} is missing") for index in range(JOURNEY_FILLS) if f"fillType{index}" not in keys)
        rows.extend(derived(doc, "journey-actors", f"actor{index} is missing") for index in range(JOURNEY_ACTORS) if f"actor{index}" not in keys)
    if doc.fam is Fam.RADAR:
        curves = len(re.findall(r"^\s*curve\s", doc.body, re.MULTILINE))
        rows.extend(
            derived(doc, "radar-curves", f"cScale{index} is missing for curve {index + 1}") for index in range(curves) if f"cScale{index}" not in keys
        )
    if doc.fam is Fam.GITGRAPH:
        branches = 1 + len(re.findall(r"^\s*branch\s", doc.body, re.MULTILINE))
        rows.extend(
            derived(doc, "git-rails", f"git{index} is missing for branch rail {index}") for index in range(branches) if f"git{index}" not in keys
        )
        rows.extend(
            derived(doc, "git-rails", f"gitBranchLabel{index} must carry dark ink")
            for index in range(branches)
            if walk(doc.config, (*TV, f"gitBranchLabel{index}")) != CANVAS
        )
    return tuple(rows)


def family_rows(doc: Doc) -> tuple[Row, ...]:
    rows: list[Row] = [row for rule_id in VAR_GROUPS if doc.fam in RULE_INDEX[rule_id].fams for row in var_group_rows(doc, rule_id)]
    body_lines = doc.body.splitlines()
    if doc.fam is Fam.FLOWCHART:
        elk = walk(doc.config, ("layout",)) == "elk" or walk(doc.config, ("flowchart", "defaultRenderer")) == "elk"
        rows.extend([] if elk else [derived(doc, "flow-elk")])
    if doc.fam in {Fam.FLOWCHART, Fam.SWIMLANE, Fam.STATE, Fam.CLASS, Fam.ER}:
        fill_owner = walk(doc.config, (*TV, "primaryColor")) is not MISSING or walk(doc.config, (*TV, "mainBkg")) is not MISSING
        border_owner = walk(doc.config, (*TV, "primaryBorderColor")) is not MISSING or walk(doc.config, (*TV, "nodeBorder")) is not MISSING
        rows.extend([] if fill_owner and border_owner else [derived(doc, "node-owner")])
    if doc.fam is Fam.SEQUENCE and condition_holds(doc, Cond.REGION):
        rows.extend([] if any(line.strip().startswith(("box", "rect")) for line in body_lines) else [derived(doc, "seq-region-grouped")])
        rows.extend(var_group_rows_for_labelbox(doc))
    if doc.fam is Fam.PIE:
        slices = len([line for line in body_lines if re.match(r'^\s*"[^"]+"\s*:\s*[\d.]+', line)])
        tv = walk(doc.config, TV)
        keys = frozenset(tv) if is_table(tv) else frozenset()
        rows.extend(
            derived(doc, "pie-slices", f"pie{index} is missing for slice {index}") for index in range(1, slices + 1) if f"pie{index}" not in keys
        )
        rows.extend(
            derived(doc, "pie-slices", f"nth-of-type({index}) stamp is missing for slice {index}")
            for index in range(1, slices + 1)
            if f"nth-of-type({index})" not in doc.css
        )
    if doc.fam is Fam.SANKEY:
        colors = walk(doc.config, ("sankey", "nodeColors"))
        names = {
            part.strip()
            for line in body_lines
            if line.count(",") == 2 and not line.strip().startswith("%")
            for part in line.rsplit(",", 1)[0].split(",")
        } - {""}
        mapped = frozenset(colors) if is_table(colors) else frozenset()
        rows.extend(derived(doc, "sankey-nodecolors", f"node {name} has no nodeColors entry") for name in sorted(names - mapped))
    if doc.fam is Fam.VENN:
        sets = len(re.findall(r"^\s*set\s", doc.body, re.MULTILINE))
        styles = [line for line in body_lines if re.match(r"^\s*style\s", line)]
        rows.extend([] if len(styles) >= sets else [derived(doc, "venn-styles", f"{sets} sets but {len(styles)} style rows")])
        rows.extend(derived(doc, "venn-styles", "style row lacks fill-opacity") for line in styles if "fill-opacity" not in line)
    if doc.fam is Fam.C4:
        rels = len(re.findall(r"^\s*(?:Bi)?Rel\w*\(", doc.body, re.MULTILINE))
        updates = len(re.findall(r"^\s*UpdateRelStyle\(", doc.body, re.MULTILINE))
        rows.extend([] if updates >= rels else [derived(doc, "c4-relstyle", f"{rels} relations but {updates} UpdateRelStyle calls")])
    if doc.fam is Fam.ARCHITECTURE:
        services = len(re.findall(r"^\s*service\s", doc.body, re.MULTILINE))
        aligned = re.search(r"^\s*align\s+(row|column)\s", doc.body, re.MULTILINE) is not None
        rows.extend([] if services < 2 or aligned else [derived(doc, "arch-align")])
    if doc.fam is Fam.EVENTMODELING:
        used = {kind for line in body_lines for kind in EM_KINDS if re.match(rf"^\s*(?:tf|rf|timeframe|resetframe)\s+\S+\s+{kind}\b", line)}
        rows.extend(
            derived(doc, "em-kinds", f"{EM_KINDS[kind]}Fill/{EM_KINDS[kind]}Stroke pair required for used kind {kind}")
            for kind in sorted(used)
            if walk(doc.config, (*TV, f"{EM_KINDS[kind]}Fill")) is MISSING or walk(doc.config, (*TV, f"{EM_KINDS[kind]}Stroke")) is MISSING
        )
    if doc.fam is Fam.MINDMAP:
        rows.extend(mindmap_rows(doc))
    if doc.fam is Fam.CYNEFIN:
        rows.extend(
            derived(doc, "cynefin-domains", f"cynefin.{key} wash tint is missing")
            for key in CYNEFIN_WASH_KEYS
            if walk(doc.config, (*TV, "cynefin", key)) is MISSING
        )
    if doc.fam is Fam.RADAR:
        margins = ("marginTop", "marginRight", "marginBottom", "marginLeft")
        rows.extend([] if any(walk(doc.config, ("radar", key)) is not MISSING for key in margins) else [derived(doc, "radar-margins")])
    if doc.fam is Fam.RAILROAD:
        rows.extend(
            derived(doc, "railroad-config", f"railroad.{key} must be {expect!r}")
            for key, expect in RAILROAD_KEYS
            if walk(doc.config, ("railroad", key)) != expect
        )
    if doc.fam is Fam.KANBAN and condition_holds(doc, Cond.PRIORITY):
        rows.extend(derived(doc, "kanban-priority", f"priority remap missing: {stamp}") for stamp in KANBAN_PRIORITY_STAMPS if stamp not in doc.css)
    if doc.fam is Fam.SWIMLANE:
        rows.extend([] if re.search(r"^\s*style\s+\w+", doc.body, re.MULTILINE) else [derived(doc, "swim-lane-emphasis")])
    return tuple(rows)


def var_group_rows_for_labelbox(doc: Doc) -> tuple[Row, ...]:
    frame = (
        (("labelBoxBkgColor",), DARKER),
        (("labelBoxBorderColor",), LAVENDER),
        (("labelTextColor",), FOREGROUND),
        (("loopTextColor",), FOREGROUND),
    )
    return tuple(
        derived(doc, "seq-labelbox", f"{path[0]} must be {expect!r}") for path, expect in frame if not matches(walk(doc.config, (*TV, *path)), expect)
    )


def mindmap_rows(doc: Doc) -> tuple[Row, ...]:
    nodes = [(len(line) - len(line.lstrip()), line.strip()) for line in doc.body.splitlines() if line.strip() and not line.strip().startswith("%%")][
        1:
    ]
    if not nodes:
        return ()
    root_indent = nodes[0][0]
    child_indent = next((indent for indent, _text in nodes[1:] if indent > root_indent), None)
    branches = sum(1 for indent, _text in nodes[1:] if indent == child_indent) if child_indent is not None else 0
    missing = tuple(
        derived(doc, "mindmap-sections", f".section-{index} override is missing") for index in range(branches) if f".section-{index} " not in doc.css
    )
    root = () if ".section-root" in doc.css else (derived(doc, "mindmap-sections", ".section-root override is missing"),)
    return missing + root


def order_rows(doc: Doc) -> tuple[Row, ...]:
    keys = [match.group(1) for match in re.finditer(r"^  (\w+):", doc.fm_text, re.MULTILINE)]
    rows: list[Row] = []
    if "theme" in keys and "look" in keys and keys.index("theme") > keys.index("look"):
        rows.append(derived(doc, "fm-key-order", "theme must precede look"))
    if "themeCSS" in keys and keys[-1] != "themeCSS":
        rows.append(derived(doc, "fm-key-order", "themeCSS must be the last config key"))
    block = re.search(r"^  themeVariables:\n((?:^(?:    .*)?\n?)*)", doc.fm_text, re.MULTILINE)
    tv_keys = [match.group(1) for match in re.finditer(r"^    (\w+):", block.group(1), re.MULTILINE)] if block else []
    opening = [key for key in tv_keys if key in TV_OPENING]
    if opening and opening != [key for key in TV_OPENING if key in opening]:
        rows.append(derived(doc, "fm-key-order", "themeVariables must open darkMode, fontFamily, useGradient, dropShadow"))
    return tuple(rows)


def check(doc: Doc) -> tuple[Row, ...]:
    if doc.config is MISSING:
        return (derived(doc, "frontmatter-parse"), *hex_rows(doc))
    if doc.config is None:
        return (derived(doc, "frontmatter-required"), *hex_rows(doc), *statement_rows(doc))
    font_hits = tuple(derived(doc, "font-hyphen") for _ in [1] if FONT_HYPHEN.search(doc.fm_text))
    return (
        *rule_rows(doc),
        *hex_rows(doc),
        *yellow_rows(doc),
        *statement_rows(doc),
        *css_rows(doc),
        *ordinal_rows(doc),
        *family_rows(doc),
        *order_rows(doc),
        *font_hits,
    )


def explained(rule_id: str) -> int:
    rule = RULE_INDEX.get(rule_id)
    if rule is None:
        print(f"unknown rule id: {rule_id}")
        return 1
    print(f"{rule.id} [{rule.level}] - {rule.detail}")
    print(f"canon: {rule.canon}")
    print(f"owner: {rule.ref}")
    return 0


# --- [COMPOSITION] -------------------------------------------------------------------------

APP = App(name="check-canon")
ENCODER = msgspec.json.Encoder()


@APP.default
def main(*paths: Path, json: bool = False, explain: str | None = None) -> int:
    if explain is not None:
        return explained(explain)
    files, rows = collect(paths)
    docs = tuple(doc for file in files for fence in read_fences(file) if (doc := parse_doc(fence)) is not None)
    rows = (*rows, *(row for doc in docs for row in check(doc)))
    for row in rows:
        emit(row, json)
    return 1 if any(row.status == "fail" for row in rows) else 0


if __name__ == "__main__":
    sys.exit(APP())
