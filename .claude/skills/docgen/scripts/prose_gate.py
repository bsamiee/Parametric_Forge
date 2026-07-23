#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.14"
# dependencies = ["cyclopts", "msgspec"]
# ///
# ruff:file-ignore[print, undocumented-public-module, undocumented-public-class, undocumented-public-function]

# --- [RUNTIME_PRELUDE] ------------------------------------------------------------------

from collections.abc import Callable, Iterable
import copy
from enum import StrEnum
from itertools import pairwise
from pathlib import Path
import re
import subprocess
import sys
from typing import Literal

from cyclopts import App
import msgspec


# --- [TYPES] ----------------------------------------------------------------------------

type Status = Literal["ok", "warn", "fail"]
type Align = Literal["center", "left", "right", "none"]


class Check(StrEnum):
    AI_LEXICON = "ai-lexicon"
    ARTICLE_OPENER = "article-opener"
    BOLD_EMPHASIS = "bold-emphasis"
    CARD_FIELD = "card-field"
    CARD_LEADER = "card-leader"
    CARD_SECTION = "card-section"
    CARD_STATUS = "card-status"
    COLLECT = "collect"
    COMMENT_RUNT = "comment-runt"
    COMMENT_SHRED = "comment-shred"
    COMMENT_STACK = "comment-stack"
    COMMENT_WIDTH = "comment-width"
    COUPLED_LINK = "coupled-link"
    DEAD_RELATIVE_LINK = "dead-relative-link"
    EM_DASH = "em-dash"
    FENCE_CONFIG = "fence-config"
    FENCE_GEOMETRY = "fence-geometry"
    FENCE_INTENT = "fence-intent"
    FENCE_LANGUAGE = "fence-language"
    FENCE_STYLE = "fence-style"
    FENCE_UNCLOSED = "fence-unclosed"
    FILLER_WORD = "filler-word"
    GLYPH_BAN = "glyph-ban"
    GROUP_LABEL = "group-label"
    HEADING_ANCHOR = "heading-anchor"
    HEADING_H1 = "heading-h1"
    HEADING_ORDER = "heading-order"
    HEADING_SPACING = "heading-spacing"
    HEDGE = "hedge"
    LABEL_GAP = "label-gap"
    LIST_BLOAT = "list-bloat"
    LIST_LEADER = "list-leader"
    LIST_MARKER = "list-marker"
    LIST_WRAP = "list-wrap"
    MACHINE_PATH = "machine-path"
    META_PHRASE = "meta-phrase"
    NO_OP_WORD = "no-op-word"
    PROSE_BLOAT = "prose-bloat"
    PROSE_WRAP = "prose-wrap"
    READ = "read"
    RESEARCH_ROW = "research-row"
    RESEARCH_SECTION = "research-section"
    ROUTER_WIDTH = "router-width"
    RULINGS_SECTION = "rulings-section"
    SAME_DECISION = "same-decision-spread"
    SECTION_DIVIDER = "section-divider"
    SECTION_WIDTH = "section-width"
    SELF_COUNT = "self-count"
    SETEXT_HEADING = "setext-heading"
    SIBLING_POINTER = "sibling-pointer"
    SKILL_BUNDLE_ORPHAN = "skill-bundle-orphan"
    SKILL_BUNDLE_ROUTER = "skill-bundle-router"
    SKILL_DESCRIPTION = "skill-description"
    SKILL_FRONTMATTER = "skill-frontmatter"
    SKILL_NAME = "skill-name"
    SKILL_ROOT_BUDGET = "skill-root-budget"
    TABLE_ALIGN = "table-align"
    TABLE_BOUNDS = "table-bounds"
    TABLE_CELL = "table-cell"
    TABLE_HEADER = "table-header"
    TABLE_INDEX = "table-index"
    TABLE_LINKS = "table-links"
    TABLE_PROSE = "table-prose"
    TABLE_SEVERED = "table-severed"
    TABLE_SHAPE = "table-shape"
    TABLE_WIDTH = "table-width"
    TEMPLATE_SLOT = "template-slot"
    TRAILING_WHITESPACE = "trailing-whitespace"
    VERSION_ANCHOR = "version-anchor"
    WEAK_VERB = "weak-verb"


# --- [CONSTANTS] ------------------------------------------------------------------------

CAP = 150
CELL_BUDGET = 160
CELL_WORD_BUDGET = 6
COLUMN_FLOOR = 5
COMMENT_RUNT_FLOOR = 50
COMMENT_SHRED_FLOOR = 100
COMMENT_STACK_CAP = 4
# Guidance fills toward CAP; the gate grants slack above it before failing the line. Widths measure from column 1
# of the source: Nix ''-string stripping only narrows the artifact, so the slack band absorbs the embedding indent.
COMMENT_WIDTH_CAP = 165
LIST_CHAR_CAP = 500
LIST_SENTENCE_CAP = 3
PROSE_CHAR_CAP = 600
PROSE_SENTENCE_CAP = 6
ROSTER_SPAN_SHARE = 0.6
SKILL_DESCRIPTION_CAP = 1024
SKILL_DESCRIPTION_CEILING = 1536
SKILL_DESCRIPTION_FLOOR = 60
SKILL_NAME_CAP = 64
SKILL_ROOT_CAP = 500
TABLE_WIDTH_CAP = 150
DIVIDER_WIDTH = 90
FENCE_INTENTS = frozenset({
    "accepted",
    "codemap",
    "copy-safe",
    "template",
    "conceptual",
    "generated",
    "output-only",
    "rejected",
    "seams",
    "signature",
    "test-only",
})
TABLE_COLUMN_CEILING = (
    15  # row count is never capped; the 150-column rendered-width cap (TABLE_WIDTH_CAP) is the sole size law, columns govern only the horizontal axis
)
MARKERS: dict[str, str] = (
    dict.fromkeys((".py", ".sh", ".bash", ".zsh", ".nix", ".toml", ".jq"), "#")
    | dict.fromkeys((".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".cs", ".jsonc"), "//")
    | dict.fromkeys((".lua", ".sql"), "--")
)
# Teaching surfaces carry comments and dividers as taught pattern; the exemption binds only inside skill and docs trees.
TEACHING = frozenset({"templates", "examples", "assets"})
PRUNED = frozenset({".git", "node_modules", ".venv", ".cache", ".direnv", "result", "dist", "coverage", ".archive", ".history"})
# Routing is a file class: only these filenames carry file links; a relative link anywhere else is coupling.
ROUTING_FILES = frozenset({"README.md", "SKILL.md", "CLAUDE.md", "AGENTS.md", "MEMORY.md"})
# Instruction files weight constraints with the closed invocation-marker family; the leader is legal there and nowhere else.
INSTRUCTION_FILES = frozenset({"CLAUDE.md", "CLAUDE.local.md", "AGENTS.md"})
APP = App(help="Gate and format durable markdown prose.")
ENCODER = msgspec.json.Encoder()

BOLD = re.compile(r"(?<!\*)\*\*(?=\S)(.+?)(?<=\S)\*\*(?!\*)|(?<!_)__(?=\S)(.+?)(?<=\S)__(?!_)")
ROUTER_CARD = re.compile(
    r"^(?P<indent>\s*)- \[?\s*(?P<n>\d{1,3})\s*(?:-[A-Z0-9_]+)?\]?\s*[-\u2013\u2014]?\s*\[(?P<text>[^\]]+)\]\((?P<path>[^)\s]+)\)\s*:\s*(?P<rest>.*)$"
)
DASH_TAIL = re.compile(r"^ -+$")
DIVIDER = re.compile(r"^(?P<indent>\s*)(?P<marker>#|//|--) --- (?P<body>\S.*)$")
DIVIDER_BODY = re.compile(r"^\[(?P<label>[A-Z][A-Z0-9_]*)\](?P<tail>.*)$")
DIVIDER_LOOSE = re.compile(r"^\[(?P<raw>[^\]]+)\](?P<tail>.*)$")
CHECKBOX = re.compile(r"^\[[ xX]\]\s")
CARD_ROW = re.compile(r"^\s*-\s+`[^`]+`\s+-\s+")
# A named-surface leader — code span or link, optionally behind marker tokens — is the annotation's subject, so the
# clause after its dash or colon opens with the owning verb; the definite-article opener is the dead appositive form.
ARTICLE_ANNOTATION = re.compile(
    r"^\s*(?:(?:[-+*]|\d+[.)])\s+)?(?:\[[^\]]*\][-\u2013\u2014]?\s*)*(?:`[^`]+`|\[[^\]]+\]\([^)\s]+\))\s*(?:[\u2013\u2014:]|-)\s+[Tt]he\s"
)
# List entries lead with their owner or owning verb, bare or behind the full marker grammar.
ARTICLE_FRAGMENT = re.compile(r"^\s*(?:[-+*]|\d+[.)])\s+(?:\[[A-Z0-9][A-Z0-9_|]*\](?:-\[[A-Z0-9][A-Z0-9_|]*\])*:\s+)?[Tt]he\s")
# Sentence boundaries reject article-led voice; colons, semicolons, and leader dashes retain lowercase continuation.
SENTENCE_ARTICLE = re.compile(r"^\s*[Tt]he\b|[.!?]\s+[Tt]he\b|[:;\u2013\u2014]\s+The\b")
# One cure, every article site: the article marks a clause whose subject is not the acting owner; the repair is structural, never a determiner edit.
ARTICLE_CURE = "; find the actor, seat it as subject under a present-active owning verb; deleting the article or swapping it for A/One/This re-heads the same broken clause"
# Comments obey the same owner-first voice.
COMMENT_ARTICLE = re.compile(r"^[Tt]he\s")
# A fence tag names the marker its full-line comments carry, so a fence body answers the comment law its language spells.
FENCE_MARKERS: dict[str, str] = (
    dict.fromkeys(("python", "py", "bash", "sh", "shell", "zsh", "nix", "toml", "jq", "yaml", "yml", "ruby"), "#")
    | dict.fromkeys(
        ("csharp", "cs", "typescript", "ts", "tsx", "javascript", "js", "jsx", "jsonc", "rust", "go", "java", "kotlin", "swift", "cpp"), "//"
    )
    | dict.fromkeys(("lua", "sql", "haskell", "elm"), "--")
)
# Doc-comment glyphs bind only marker-adjacent (`///`, `//!`, `#!`, `--[[`, `#:schema`, `//#region`); a spaced glyph opens prose.
COMMENT_GLYPH = re.compile(r"[!/@:#\[-]")
# Tool pragmas count as structural only in pragma spelling — a bare tool name opening prose stays countable.
COMMENT_DIRECTIVE = re.compile(
    r"shellcheck\s+[a-z-]+=|noqa\b|ruff:|type:\s*ignore|mypy:|pyright:|fmt:\s*(?:off|on|skip)|eslint-|@ts-"
    r"|biome-ignore\b|prettier-ignore\b|luacheck:|stylua:|%%(?:\s|$)|#?(?:end)?region\b|-\*-"
)
# Label-plus-dash-fill divider rows and column-aligned topology rows (continuation indents, 3+-space columns) are structural carriers.
COMMENT_LABEL_FILL = re.compile(r"^\[?[A-Za-z][A-Za-z0-9_ .]{0,40}\]?\s*-{4,}\s*$")
COMMENT_ALIGNED = re.compile(r"^\s{2,}|\S\s{3,}\S")
EXAMPLE_LINE = re.compile(
    r"^\s*(?:>\s*)?(?:[-+*]|\d+[.)])?\s*(?:Detection|Reject(?:ed)?|Accept(?:ed)?|Near miss|Banned|Survivors|Reason|Reframe)"
    r"(?:\s*\([^)]*\))?:"
)
# Quote-labeled fields carry defective prose by design and skip every check; guidance-voice fields (Detection/Reason/Reframe/Accepted)
# skip the register rosters they must name yet still answer the article-opener check — their voice is the skill's own.
QUOTE_LINE = re.compile(r"^\s*(?:>\s*)?(?:[-+*]|\d+[.)])?\s*(?:Reject(?:ed)?|Near miss|Banned|Survivors)(?:\s*\([^)]*\))?:")
# Any-indent fences: list-nested fences open at the item's content column; close indent is bounded at the check site.
FENCE = re.compile(r"^(?P<indent>[ \t]*)(?P<marker>`{3,}|~{3,})(?P<info>.*)$")
# Mermaid payload-only law: a durable-doc fence carries structure — declaration, nodes, edges, labels, subgraphs, accTitle/accDescr, and
# functional layout keys (`layout`, `elk`, curve, geometry knobs) — never appearance. A styling key strips with its nested block; a color
# value marks its key as appearance whatever its spelling.
MERMAID_STYLE_KEY = re.compile(
    r"^(\s*)([\w-]*(?:color|colours|fill|stroke|font|opacity|bkg|background|theme|look|gradient|shadow|darkmode|labelstyle)[\w-]*)\s*:", re.IGNORECASE
)
MERMAID_HEX_VALUE = re.compile(r":\s*[\"']?#[0-9A-Fa-f]{3,8}\b")
MERMAID_STYLE_LINE = re.compile(r"^\s*(classDef\s|linkStyle\s|style\s+\S+\s|%%\{\s*init|Update(?:Rel|Element)Style\b)")
MERMAID_CLASS_ASSIGN = re.compile(r"^\s*class\s+[\w,.$@-]+\s+[\w,-]+\s*;?\s*$")
MERMAID_CLASS_TAIL = re.compile(r":::[\w,-]+")
MERMAID_ANIMATE = re.compile(r"^\s*[\w-]+@\{[^}]*\banimat(?:e|ion)\b[^}]*\}\s*$")
# Body statements carrying css-property styling (todayMarker strings, venn style rows); `rect rgb(...)` stays — its grammar embeds the color.
MERMAID_BODY_CSS = re.compile(r"(?:stroke|fill|color|opacity)\s*:\s*\S")
MERMAID_BOX_COLOR = re.compile(r"^(\s*box\s+)rgba?\([^)]*\)")
# Required-payload law inverts styling law: a flowchart fence opens on the standing ELK block, and renderer-capable families carry both
# accessibility directives under their declaration. Mute families reject or swallow them, so their relation sentence sits beside the fence.
ACCESSIBILITY = ("accTitle", "accDescr")
MERMAID_ELK_KEYS = ("layout: elk", "curve: linear", "padding: 25")
MERMAID_ELK_BLOCK = ("---", "config:", "  layout: elk", "  flowchart:", "    curve: linear", "    padding: 25", "---")
MERMAID_FAMILY = re.compile(r"^[A-Za-z0-9]+")
MERMAID_LAYOUT = frozenset({"flowchart"})
MERMAID_MUTE = frozenset({"block", "eventmodeling", "ishikawa", "kanban", "mindmap", "sankey", "timeline", "venn"})
# Block 2600-27BF covers warning/exclamation/info pictographs; the arrow blocks stay legal for codemap glyphs.
EMOJI = re.compile(r"[\U0001F000-\U0001FAFF\u2600-\u27BF\u2B50\u2139\uFE0F]")
PROMPT_LINE = re.compile(r"^\s*(?:\$|\u276F|PS>)\s+\S")
# A bare group label `[X]:` hugs its list; a table keeps its blank.
GROUP_LABEL = re.compile(r"^\[[A-Z][A-Z0-9_]*\]:\s*$")
# A floating bracketed label — no colon, alone on its line — that introduces a list or table lacks the colon a list label carries.
FLOATING_LABEL = re.compile(r"^\[[A-Z][A-Z0-9_-]*\]\s*$")
GLYPHS = ("│", "├", "└", "⇄")
HEADER_CELL = re.compile(r"^\[[A-Z][A-Z0-9_]*\]$")
HEADING = re.compile(r"^(?P<level>#{1,6})\s+(?P<title>.+?)\s*$")
LIST_ITEM = re.compile(r"^(?P<indent>\s*)(?P<mark>[-+*]|\d+[.)])\s+(?P<body>\S.*)$")
LIST_LEADER = re.compile(r"^\s*(?:[-+*]|\d+[.)])\s+\[(?:\d{2}(?:\.\d+)?(?:-[A-Z0-9_]+)?|[A-Z0-9_]+|[OX!~ ])\](?:\s+[—-]|[-:]\s*|:)")
# An invocation-marker leader weights the imperative following it directly — no colon, no dash — per the formatting standard's closed family.
INVOCATION_LEADER = re.compile(r"^\s*[-+*]\s+\[(?:ALWAYS|NEVER|IMPORTANT|CRITICAL)\]\s+\S")
# A `- Field: value` record field answers to the earned-field law at card altitude; the entry budget binds peer bullets.
FIELD_LINE = re.compile(r"^[A-Z][A-Za-z-]*(?: [A-Za-z-]+){0,2}: \S")
# Hard-wrap detection: a flush-left prose line whose predecessor is also flush-left prose; structural leads are excluded.
PLAIN_EXCLUDED = ("#", "-", "*", "+", ">", "|", "<", "=", "[")
NUMBERED_LEAD = re.compile(r"^\d+[.)]\s")
LINK = re.compile(r"(?<!!)\[([^\]\n]+)\]\(((?:[^()\s]|\([^()\s]*\))+)(?:\s+\"[^\"]*\")?\)")
NUMBERED_SECTION = re.compile(r"^\[(?P<n>\d{2})\]-\[(?P<token>[A-Z][A-Z0-9_]*)\](?:-\[[A-Z][A-Z0-9_]*\])*$")
PLACEHOLDER = re.compile(r"<[a-z][a-z0-9]*(?:[-_][a-z0-9]+)+>")
SENTENCE_END = re.compile(r"[.!?](?:\s|$)")
SETEXT = re.compile(r"^\s*(?:=+|-{3,})\s*$")
TABLE_SEP = re.compile(r"^\s*\|(?:\s*:?-+:?\s*\|)+\s*$")
YAML_KEY = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*\s*:")

INDEX_ALIASES = frozenset({"INDEX", "IDX", "NN", "NO", "NUM", "ROW"})
NUMBER_ENTRY = re.compile(r"^\[?\s*0*(\d{1,3})\s*\]?$")
H2_NUMBERED = re.compile(r"^\[(\d{2})\]-(\[[A-Z][A-Z0-9_]*\](?:-\[[A-Z][A-Z0-9_]*\])*)$")
H3_NUMBERED = re.compile(r"^\[(\d{2})\.(\d+)\]-(\[[A-Z][A-Z0-9_]*\](?:-\[[A-Z][A-Z0-9_]*\])*)$")
LEADER_BARE = re.compile(r"^(?P<indent>\s*)- \[(?P<token>\d{1,3}|[A-Z][A-Z0-9_]*)\]\s+(?![-\u2013\u2014:(])(?P<rest>\S.*)$")
LEADER_LOOSE = re.compile(
    r"^(?P<indent>\s*)-\s+\[?\s*(?P<n>\d{1,3})\s*\]?\s*[-\u2013\u2014]\s*\[?\s*(?P<label>[A-Za-z][A-Za-z0-9_ ]*?)\s*\]?\s*:(?P<rest>.*)$"
)

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
    r"|at\s+the\s+time\s+of\s+writing|make\s+sure\s+to|be\s+sure\s+to|keep\s+in\s+mind|remember\s+to"
    r"|it\s+is\s+important\s+to)\b",
    re.IGNORECASE,
)
# Quoted user utterances and code spans are trigger material, not voice.
QUOTED_SPAN = re.compile(r"\"[^\"]*\"|“[^”]*”|`[^`]*`")
# A cell carrying an internal comma or semicolon is a card wearing a row; the atomic budget is one clause of six words.
CLAUSE_PUNCT = re.compile(r"[,;]")
SKILL_NAME_SHAPE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
SKILL_NAME_RESERVED = re.compile(r"(?:^|-)(?:claude|anthropic)(?:-|$)")
SKILL_VOICE = re.compile(r"\b(?:I(?!/)|me|my|mine|we|our|you|your)\b", re.IGNORECASE)
SELF_COUNT = re.compile(
    r"(?:^|[.!?]\s+)(Two|Three|Four|Five|Six|Seven|Eight|Nine|Ten|Eleven|Twelve|Thirteen|Fourteen|Fifteen|Sixteen"
    r"|Seventeen|Eighteen|Nineteen|Twenty|\d+)\s+(named\s+)?(classes|laws|rules|sections|types|axes|fields|modes"
    r"|tests|checks|steps|entries|forms|tiers|bands|devices|archetypes|templates|references|tables|diagrams|cards"
    r"|rows|columns|tokens|markers|vocabularies)\b"
)
# Its lookahead spares dotted-quad network literals; the lookbehind blocks interior re-matches inside them.
VERSION_ANCHOR = re.compile(r"(?<![\d.])\b(?!(?:\d{1,3}\.){3}\d{1,3}\b)v?\d+\.\d+(?:\.\d+)+\b|(?<![A-Za-z-])\b\d+\.\d+(?:\.\d+)?\+|\bv\d+\.\d+\b")
# A bare major band anchored to a capitalized product token: the `<Product> NN+` compatibility floor.
# Its lookahead spares `N+M` notation (a digit after `+`) — CNC axis notation like `3+2`, never a version band.
VERSION_BAND = re.compile(r"\b[A-Z][A-Za-z]*\s+\d{1,3}\+(?![+\d])")
# A standards-clause citation is a domain value, not a release pin: Table 2.3.2 and its kin pass the anchor scan.
CITATION_LEAD = re.compile(r"(?:Table|Clause|Section|Annex|Figure|Chapter|Note|Part|§)\s*$")
# Spaced double or triple hyphens ride prose as an em dash; the spelled character is the only legal interrupter.
EM_DASH_ASCII = re.compile(r"(?<=\s)-{2,3}(?=\s)")
# Section-anchored pointers couple prose to a sibling's interior; a bare owner mention stays the legal one-line pointer form.
POINTER = re.compile(r"[\w./-]*\w\.md#[\w.-]+|\b[\w./-]+/[\w.-]+#[A-Z][A-Z0-9_]+\b")
# Deictic freshness and permission verbs warn: both admit context-legal uses review adjudicates.
FRESHNESS_DEICTIC = re.compile(r"\b(?:currently|recently|nowadays|at\s+present|these\s+days|going\s+forward|modern)\b", re.IGNORECASE)
WEAK_VERB = re.compile(r"\b(?:supports|provides|offers|allows|enables)\b", re.IGNORECASE)
# Soft-preference and discourse hedges warn: `prefer` names a legitimate default across the estate, so review adjudicates each.
SOFT_HEDGE = re.compile(r"\b(?:however|prefer(?:s|red|ably)?|etc)\b", re.IGNORECASE)
# Grade and intensity words fail: each grades a fact the fact already carries, and deleting one costs no law. Roster admits
# only the unambiguous — a domain term the corpus owns (`robust` predicates, `optimal` collapse, `ideal` in the algebraic
# sense, `perfect` forwarding/hashing), estate vocabulary (`first-class`, `rich`, `advanced`), and a contrastive `merely`
# all stay legal, as does `rather` whose corpus mass is the contrastive `rather than`.
NO_OP_WORD = re.compile(
    r"\b(?:simply|very|really|quite|basically|essentially|seamless(?:ly)?|effortless(?:ly)?|cutting-edge"
    r"|state-of-the-art|best-in-class|world-class|powerful|utiliz(?:e|es|ed|ing)|comprehensive"
    r"|actually|literally|truly|completely|thoroughly|obviously|clearly|certainly|definitely|undoubtedly|arguably"
    r"|extremely|highly|incredibly|significantly|substantially|notably|particularly|especially"
    r"|blazing|lightning-fast|battle-tested|production-ready|enterprise-grade|next-generation|revolutionary|innovative)\b",
    re.IGNORECASE,
)
# Sentence-initial `So` is filler glue delaying the subject; its cure is a recast, never a comma swap. The causal `, so …`
# join states real consequence law and is the corpus's canonical connector, so only the lead-in form answers here.
SENTENCE_SO = re.compile(r"(?:^|[.!?]\s+)So\b")
# AI-register lexemes fail: puffery, significance theater, transition filler, summary tails, and abstract nouns carry zero
# domain load; each hit is delete-or-reframe. Estate terms `leverage`, `overall`, `therefore`, `thus`, `likewise`, and
# `backbone` retain concrete stacking, grading, ordering, or spine semantics, so the roster excludes them.
AI_LEXICON = re.compile(
    r"\b(?:delv(?:e|es|ed|ing)|tapestry|testament|pivotal|meticulous(?:ly)?|showcas(?:e|es|ed|ing)|multifaceted"
    r"|myriad|plethora|holistic|intricate|nuanced|vibrant|additionally|moreover|furthermore"
    r"|in conclusion|in summary|to summarize|as such|in essence|at its core|it'?s worth noting"
    r"|it is worth noting|it is important to note|note that|keep in mind|bear in mind|that said"
    r"|in other words|when it comes to|a wide range of|a variety of|needless to say|first and foremost"
    r"|landscape|realm|journey|deep dive|game-changer|treasure trove|powerhouse|cornerstone)\b",
    re.IGNORECASE,
)
# Copula avoidance warns: an identity claim states is/are/has; a serves-as apposition re-labels the surface without owning its concern.
COPULA_AVOIDANCE = re.compile(r"\b(?:serves|stands|functions|operates)\s+as\b|\bboasts\b", re.IGNORECASE)
# Additive filler fails: `plus` pads a clause it never joins. Cure runs shortest-first — delete the word with its comma, folding the tail
# into the clause or a serial list; then `with`, which carries accompaniment; then FANBOYS `and` where a compound subject needs the
# conjunction; then a precise shorter word where the coinage admits one. Every longer connector costs more characters than the defect.
# Emphasis casing and quantity sense survive the swap. Hyphen lookarounds spare compound tokens (`delete-plus-create`), read as names.
FILLER_WORD = re.compile(r"(?<![\w-])plus(?![\w-])", re.IGNORECASE)
# A label-led paragraph — `[LABEL] — prose` or `[LABEL]: prose` — is measured prose mass, never structure.
LABELED_PARAGRAPH = re.compile(r"^\[[A-Z][A-Z0-9_]*\](?:-\[[A-Z][A-Z0-9_]*\])*(?: [\u2013\u2014] |: )\S")

# --- [CARD_GRAMMAR]
# IDEAS/TASKLOG card files, design-page [RESEARCH] sections, and RULINGS.md registries census against the
# ratified marker grammar: `[SLUG]-[STATUS]:` leaders, closed status vocabularies, the field roster each file's
# own source-only template comment declares (ratified set as fallback), the terminal research-section contract,
# and the rulings section vocabulary under omit-and-renumber.
CARD_FILES = frozenset({"IDEAS.md", "TASKLOG.md"})
CORE_FIELDS: tuple[str, ...] = ("Capability", "Shape", "Unlocks", "Anchors")
RATIFIED_FIELDS = frozenset({*CORE_FIELDS, "Arms", "Atomic", "Ripple", "Route", "Tension"})
OPEN_STATUSES = frozenset({"ACTIVE", "QUEUED", "BLOCKED"})
CLOSED_STATUSES = frozenset({"COMPLETE", "DROPPED"})
RESEARCH_STATUSES = frozenset({"OPEN", "BLOCKED"})
# Rulings sections are a closed vocabulary in canonical order; a file's own source-only comment extends it
# through code-spanned labels under the union law, and unused sections omit with survivors renumbered.
RULING_SECTIONS: tuple[str, ...] = ("PACKAGES", "SHAPE", "COLLAPSE", "STRUCTURE", "PROCESS")
STATUS_LAW = "legal open statuses ACTIVE|QUEUED|BLOCKED, closed COMPLETE|DROPPED"
CARD_HEAD = re.compile(r"^\[(?P<slug>[^\]]+)\]-\[(?P<status>[^\]]+)\]:\s+\S")
CARD_BULLET = re.compile(r"^- (?P<label>[A-Z][A-Za-z]*):\s+\S")
CARD_BAND = re.compile(r"^## \[\d{2}\]-\[(?P<band>OPEN|CLOSED)\]\s*$")
RESEARCH_HEAD = re.compile(r"^\[\d{2}\]-\[RESEARCH\]$")
RESEARCH_ENTRY = re.compile(r"^- \[(?P<token>[^\]]+)\]-\[(?P<status>[^\]]+)\]:\s*(?P<body>.*)$")
RULINGS_H1 = re.compile(r"^\[[A-Z][A-Z0-9_]*_RULINGS\]$")
SPANNED_LABEL = re.compile(r"`\[([A-Z][A-Z0-9_]*)\]`")
SLUG_SHAPE = re.compile(r"^[A-Z][A-Z0-9_]*$")
NUMERIC_ID = re.compile(r"^\d+$")
ABSOLUTE_PATH = re.compile(r"/(?:Users|home)/[\w.-]+")
SOURCE_ONLY = "source-only"
COMMENT_OPEN, COMMENT_CLOSE = "<!--", "-->"
# Same-decision spread: adjacent prose units sharing most content words restate one ruling; the floor bounds the
# token sets so short structural lines never pair, and the share is Jaccard overlap on 4+-letter words.
SPREAD_FLOOR = 6
SPREAD_SHARE = 0.5
SPREAD_WORD = re.compile(r"[a-z]{4,}")
SENTENCE_SPLIT = re.compile(r"(?<=[.!?])\s+")
# A cure clause rides each pattern row: the matched span names the defect, the appended clause names the move that
# clears it at the grain an agent acts on; an empty cure marks a review-adjudicated warn.
PATTERNS: tuple[tuple[Check, re.Pattern[str], Status, str], ...] = (
    (Check.HEDGE, HEDGE_WORDS, "fail", "; state the settled fact or delete the sentence"),
    (Check.HEDGE, MARKER_WORDS, "fail", "; open work is a tracked card, never prose"),
    (Check.HEDGE, HEDGE_PHRASE, "fail", "; state the settled fact or delete the sentence"),
    (Check.META_PHRASE, META_PHRASE, "fail", "; delete the frame, keep the law"),
    (Check.SELF_COUNT, SELF_COUNT, "fail", "; a count is derived by the reader — delete the numeral claim"),
    (Check.VERSION_ANCHOR, VERSION_ANCHOR, "fail", "; version pins live in the owning manifest"),
    (Check.VERSION_ANCHOR, VERSION_BAND, "fail", "; version pins live in the owning manifest"),
    (Check.VERSION_ANCHOR, FRESHNESS_DEICTIC, "warn", ""),
    (Check.WEAK_VERB, WEAK_VERB, "warn", "; name the owner and its act — mints, owns, folds, routes, binds"),
    (Check.HEDGE, SOFT_HEDGE, "warn", ""),
    (Check.EM_DASH, EM_DASH_ASCII, "fail", "; spell the em dash character"),
    (Check.ARTICLE_OPENER, SENTENCE_ARTICLE, "fail", ARTICLE_CURE),
    (Check.NO_OP_WORD, NO_OP_WORD, "fail", "; delete the grade — the fact carries its own weight"),
    (Check.NO_OP_WORD, SENTENCE_SO, "fail", "; sentence-initial `So` is filler — recast the clause owner-first, never swap it for a comma join"),
    (Check.AI_LEXICON, AI_LEXICON, "fail", "; delete or reframe, never synonym-swap"),
    (Check.WEAK_VERB, COPULA_AVOIDANCE, "warn", "; state is/are/owns directly"),
    (Check.FILLER_WORD, FILLER_WORD, "fail", "; delete, folding the tail into the clause; else `with`; else FANBOYS `and`; else a shorter word"),
)


# --- [MODELS] ---------------------------------------------------------------------------


class Front(StrEnum):
    PENDING = "pending"
    OPEN = "open"
    CLOSED = "closed"


class Repair(StrEnum):
    HEADER = "header-rubric"
    INDEX = "index-column"
    ENTRY = "index-entry"
    ALIGN = "alignment"
    COLON = "label-colon"
    HEADING = "heading-number"
    HUG = "label-hug"
    LEADER = "list-leader"
    DIVIDER = "section-divider"
    SPACING = "table-spacing"
    CONFIG = "fence-config"
    STYLE = "fence-style"
    WHITESPACE = "trailing-whitespace"
    SKIP = "unfixable"


class Row(msgspec.Struct, frozen=True):
    file: str
    line: int
    check: Check
    status: Status
    detail: str


class Change(msgspec.Struct, frozen=True):
    line: int
    kind: Repair
    before: str
    after: str


class Diagram(msgspec.Struct, frozen=True):
    # Fence-body census carries frontmatter phase, flagged-style indent, opening declaration, accessibility directives, and canonical keys.
    mermaid: bool = False
    front: Front = Front.CLOSED
    styling: int | None = None
    header: str = ""
    directives: frozenset[str] = frozenset()
    keys: frozenset[str] = frozenset()


PLAIN_FENCE = Diagram()
MERMAID_FENCE = Diagram(mermaid=True, front=Front.PENDING)


class Span(msgspec.Struct, frozen=True):
    line: int
    text: str


class Table(msgspec.Struct, frozen=True):
    line: int
    end: int
    indent: str
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


# --- [TABLE_GEOMETRY] -------------------------------------------------------------------
# One projection owns table shape: the gate measures the canonical render and fmt writes it, so the verdict and the written bytes cannot drift.


def split_cells(line: str) -> tuple[str, ...]:
    cells: list[str] = []
    current: list[str] = []
    escaped = False
    for char in line.strip().strip("|"):
        if escaped:
            current.append(char)
            escaped = False
        elif char == "\\":
            current.append(char)
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


def padded(text: str, width: int, align: Align) -> str:
    gap = width - len(text)
    head = gap // 2 if align == "center" else gap if align == "right" else 0
    return " " * head + text + " " * (gap - head)


def separator(width: int, align: Align) -> str:
    body = "-" * (width - 2)
    return {"center": f":{body}:", "right": f"{body}-:", "left": f":{body}-", "none": f":{body}-"}[align]


def rendered(table: Table) -> tuple[str, ...]:
    ncol = max(len(table.headers), *(len(row) for row in table.rows), 1) if table.rows else len(table.headers)
    headers = table.headers + ("",) * (ncol - len(table.headers))
    filler: Align = "left"
    aligns: tuple[Align, ...] = table.aligns + (filler,) * (ncol - len(table.aligns))
    widths = tuple(max([len(headers[col])] + [len(row[col]) for row in table.rows if col < len(row)] + [COLUMN_FLOOR]) for col in range(ncol))

    def emit(cells: tuple[str, ...], fill: Callable[[str, int, Align], str], /) -> str:
        full = cells + ("",) * (ncol - len(cells))
        return table.indent + "| " + " | ".join(fill(full[col], widths[col], aligns[col]) for col in range(ncol)) + " |"

    return (
        emit(headers, padded),
        emit(tuple(map(separator, widths, aligns, strict=True)), lambda cell, _w, _a: cell),
        *(emit(row, padded) for row in table.rows),
    )


# --- [LEXER] ----------------------------------------------------------------------------


def row(path: Path | str, line: int, check: Check, status: Status, detail: str) -> Row:
    return Row(file=str(path), line=line, check=check, status=status, detail=detail)


def git_listed(base: Path) -> tuple[Path, ...] | None:
    # Gitignore-accurate universe: tracked plus untracked-not-ignored files under base; None when base is outside a git repo.
    try:
        out = subprocess.run(
            ("git", "-C", str(base), "ls-files", "--cached", "--others", "--exclude-standard", "-z"), capture_output=True, check=True
        ).stdout
    except OSError, subprocess.CalledProcessError:
        return None
    return tuple(base / raw.decode() for raw in out.split(b"\0") if raw)


def walked(target: Path, owned: frozenset[str]) -> tuple[Path, ...]:
    listed = git_listed(target)
    if listed is not None:
        return tuple(sorted({path.resolve() for path in listed if path.suffix in owned}))
    found: list[Path] = []
    for root, dirs, names in target.walk():
        dirs[:] = [entry for entry in dirs if entry not in PRUNED]
        found.extend((root / name).resolve() for name in names if (root / name).suffix in owned)
    return tuple(sorted(found))


def collect(paths: tuple[Path, ...]) -> tuple[tuple[Path, ...], tuple[Row, ...]]:
    files: list[Path] = []
    faults: list[Row] = []
    owned = frozenset(MARKERS) | {".md"}
    for target in paths:
        if target.is_dir():
            found = walked(target, owned)
            files.extend(found)
            if not found:
                faults.append(row(target, 0, Check.COLLECT, "fail", "directory holds no owned files"))
        elif target.suffix in owned and target.is_file():
            files.append(target.resolve())
        elif not target.exists():
            faults.append(row(target, 0, Check.COLLECT, "fail", "path does not exist"))
        else:
            faults.append(row(target, 0, Check.COLLECT, "fail", "not an owned file kind"))
    return tuple(dict.fromkeys(files)), tuple(faults)


def frontmatter_end(lines: tuple[str, ...]) -> int:
    if not lines or lines[0].rstrip() != "---":
        return 0
    for number, line in enumerate(lines[1:], 2):
        if line.rstrip() == "---":
            return number if any(YAML_KEY.match(body) for body in lines[1 : number - 1]) else 0
    return 0


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
        return path.read_text(encoding="utf-8-sig")
    except (OSError, UnicodeDecodeError) as exc:
        return row(path, 0, Check.READ, "fail", type(exc).__name__)


def teaching(path: Path) -> bool:
    parts = set(path.parts)
    return bool(TEACHING & parts) and bool({".claude", "skills", "docs"} & parts)


def fence_closes(matched: re.Match[str] | None, glyph: str, width: int, margin: int) -> bool:
    # One owner decides fence closure everywhere: same glyph, at least the opening run, bare info, bounded indent.
    return (
        matched is not None
        and matched.group("marker")[0] == glyph
        and len(matched.group("marker")) >= width
        and not matched.group("info").strip()
        and len(matched.group("indent")) <= margin + 3
    )


def label_context(after: str, beyond: str) -> tuple[bool, bool, bool]:
    # (gap, intro_list, intro_table) under a bracketed label: the first nonblank follower decides which body it charters.
    gap = not after.strip()
    follow = beyond if gap else after
    return gap, bool(LIST_ITEM.match(follow)) and not follow.lstrip().startswith("|"), follow.lstrip().startswith("|")


def family(header: str) -> str:
    # Declaration family from a fence header: the leading word alone, so `stateDiagram-v2`, `radar-beta`, and `flowchart LR` all key.
    matched = MERMAID_FAMILY.match(header)
    return matched.group().lower() if matched else ""


def diagrammed(path: Path, line: str, number: int, state: Diagram, scope: bool) -> tuple[Diagram, tuple[Row, ...]]:
    # One pass advances the mermaid body state and censuses payload; styling rows fire only inside a durable-doc scope.
    trimmed = line.strip()
    if state.front is Front.PENDING:
        opens = trimmed == "---"
        return copy.replace(state, front=Front.OPEN if opens else Front.CLOSED, header="" if opens else trimmed), ()
    if state.front is Front.OPEN:
        if trimmed == "---":
            return copy.replace(state, front=Front.CLOSED, styling=None), ()
        depth = len(line) - len(line.lstrip())
        if state.styling is not None and depth > state.styling:
            return state, ()  # nested payload of a flagged styling block; one row per block
        if scope and (MERMAID_STYLE_KEY.match(line) or MERMAID_HEX_VALUE.search(line)):
            detail = f"styling key in a durable-doc mermaid fence: {trimmed[:60]}"
            return copy.replace(state, styling=depth), (row(path, number, Check.FENCE_STYLE, "fail", detail),)
        carried = state.keys | {trimmed} if trimmed in MERMAID_ELK_KEYS else state.keys
        return copy.replace(state, styling=None, keys=carried), ()
    named = state.directives | {name for name in ACCESSIBILITY if trimmed.startswith(name)}
    settled = copy.replace(state, header=state.header or trimmed, directives=named)
    if not scope:
        return settled, ()
    if MERMAID_STYLE_LINE.match(line) or MERMAID_CLASS_ASSIGN.match(line) or MERMAID_ANIMATE.match(line):
        detail = f"styling statement in a durable-doc mermaid fence: {trimmed[:60]}"
    elif MERMAID_CLASS_TAIL.search(line):
        detail = "':::' class tail in a durable-doc mermaid fence"
    elif MERMAID_BOX_COLOR.match(line) or (MERMAID_BODY_CSS.search(line) and not trimmed.startswith("rect")):
        detail = f"css styling on a durable-doc mermaid line: {trimmed[:60]}"
    else:
        return settled, ()
    return settled, (row(path, number, Check.FENCE_STYLE, "fail", detail),)


def sealed(path: Path, start: int, state: Diagram, scope: bool) -> tuple[Row, ...]:
    # Close-time required-payload verdict: the declaration opens the body, both directives follow it, a flowchart carries the ELK block.
    if not (state.mermaid and scope):
        return ()
    lead = state.header.split(":", 1)[0]
    if lead in ACCESSIBILITY:
        detail = f"`{lead}` opens the fence body; the declaration leads and the directives follow it"
        return (row(path, start, Check.FENCE_CONFIG, "fail", detail),)
    kind = family(state.header)
    rows: list[Row] = []
    absent = tuple(name for name in ACCESSIBILITY if name not in state.directives)
    if absent and kind not in MERMAID_MUTE:
        rows.append(row(path, start, Check.FENCE_INTENT, "fail", f"mermaid fence lacks {' and '.join(absent)} under its declaration"))
    if kind in MERMAID_LAYOUT and (keys := tuple(key for key in MERMAID_ELK_KEYS if key not in state.keys)):
        rows.append(row(path, start, Check.FENCE_CONFIG, "fail", f"{kind} fence frontmatter lacks `{'`, `'.join(keys)}`"))
    return tuple(rows)


def fenced(
    path: Path, line: str, number: int, fence: tuple[str, int, int, str, int], state: Diagram, scope: bool, cap: int
) -> tuple[bool, Diagram, tuple[Row, ...]]:
    # Fence-interior census: geometry, intent misuse, mermaid payload, and comment openers; returns (closed, fence state, rows).
    rows: list[Row] = []
    glyph, width, start, info, margin = fence
    if fence_closes(FENCE.match(line), glyph, width, margin):
        return True, state, sealed(path, start, state, scope)
    trimmed = line.strip()
    if ("codemap" in info or "seams" in info or any(mark in line for mark in GLYPHS)) and len(line) > cap:
        rows.append(row(path, number, Check.FENCE_GEOMETRY, "fail", f"line {len(line)} > cap {cap}"))
    elif "copy-safe" in info and PROMPT_LINE.match(line):
        rows.append(row(path, number, Check.FENCE_INTENT, "fail", "copy-safe fence line carries a shell prompt"))
    elif "copy-safe" in info and PLACEHOLDER.search(line):
        rows.append(row(path, number, Check.FENCE_INTENT, "fail", "copy-safe fence carries a placeholder slot; the body is a template"))
    elif "output-only" in info and PROMPT_LINE.match(line):
        rows.append(row(path, number, Check.FENCE_INTENT, "fail", "prompt-led command rides an output-only fence; the body is a run instruction"))
    if state.mermaid:
        state, payload_rows = diagrammed(path, line, number, state, scope)
        rows.extend(payload_rows)
    mark = FENCE_MARKERS.get(info.split()[0] if info else "", "")
    if mark and trimmed.startswith(mark) and COMMENT_ARTICLE.match(trimmed.removeprefix(mark).lstrip()):
        rows.append(row(path, number, Check.ARTICLE_OPENER, "fail", f"fence comment opens on 'the'{ARTICLE_CURE}"))
    return False, state, tuple(rows)


def lex(path: Path, text: str, cap: int) -> tuple[Document, tuple[Row, ...]]:
    raw = tuple(text.splitlines())
    skip_until = frontmatter_end(raw)
    prose: list[Span] = []
    tables: list[Table] = []
    headings: list[Heading] = []
    links: list[LinkRef] = []
    lists: list[ListEntry] = []
    rows: list[Row] = []
    fence: tuple[str, int, int, str, int] | None = None
    diagram = PLAIN_FENCE
    payload_scope = "templates" not in path.parts and not teaching(path)
    plain_run = False
    last_rubric = ""
    template = "templates" in path.parts
    pointered = path.name not in ROUTING_FILES and not template and not teaching(path)
    n = 0
    while n < len(raw):
        number, line = n + 1, raw[n]
        if line.endswith((" ", "\t")):
            rows.append(row(path, number, Check.TRAILING_WHITESPACE, "fail", "line ends with space or tab; strip the trailing run"))
        if number <= skip_until:
            plain_run = False
            n += 1
            continue
        matched = FENCE.match(line)
        if fence is None and matched:
            plain_run = False
            marker, info = matched.group("marker"), matched.group("info").strip()
            tokens = info.lower().split()
            if not info:
                rows.append(
                    row(
                        path, number, Check.FENCE_LANGUAGE, "fail", "opening fence has no language tag; tag the language, or `text` for plain payload"
                    )
                )
            elif template:
                pass
            elif len(tokens) == 1 and tokens[0] not in ("text", "mermaid"):
                rows.append(
                    row(path, number, Check.FENCE_INTENT, "fail", f"fence `{info}` carries no intent label; append one from the closed intent set")
                )
            elif len(tokens) > 1 and tokens[1] not in FENCE_INTENTS:
                rows.append(
                    row(
                        path,
                        number,
                        Check.FENCE_INTENT,
                        "fail",
                        f"fence intent {tokens[1]} outside the closed set {', '.join(sorted(FENCE_INTENTS))}",
                    )
                )
            fence = (marker[0], len(marker), number, info.lower(), len(matched.group("indent")))
            diagram = MERMAID_FENCE if tokens[:1] == ["mermaid"] else PLAIN_FENCE
            n += 1
            continue
        if fence is not None:
            plain_run = False
            closed, diagram, fenced_rows = fenced(path, line, number, fence, diagram, payload_scope, cap)
            rows.extend(fenced_rows)
            if closed:
                fence = None
            n += 1
            continue
        if path.name == "README.md" and CARD_ROW.match(line) and len(line) > cap:
            rows.append(row(path, number, Check.FENCE_GEOMETRY, "fail", f"card row {len(line)} > cap {cap}; demote the tail to the owning page"))
        if not template and ROUTER_CARD.match(line) and len(line) > cap:
            rows.append(
                row(
                    path,
                    number,
                    Check.ROUTER_WIDTH,
                    "fail",
                    f"router card {len(line)} cols > cap {cap}; one owner, one charter phrase — demote the tail",
                )
            )
        if heading := HEADING.match(line):
            headings.append(Heading(number, len(heading.group("level")), heading.group("title")))
            rubrics = re.findall(r"\[([A-Z][A-Z0-9_]*)\]", heading.group("title"))
            last_rubric = rubrics[-1] if rubrics else last_rubric
            if n + 1 < len(raw) and raw[n + 1].strip():
                rows.append(row(path, number, Check.HEADING_SPACING, "fail", "heading lacks its following blank line; insert one"))
        elif GROUP_LABEL.match(line.strip()) and line.strip() == f"[{last_rubric}]:":
            rows.append(row(path, number, Check.GROUP_LABEL, "warn", f"[{last_rubric}]: echoes its section heading; the label is phantom structure"))
        elif (floating := bool(FLOATING_LABEL.match(line))) or GROUP_LABEL.match(line.strip()):
            gap, intro_list, intro_table = label_context(raw[n + 1] if n + 1 < len(raw) else "", raw[n + 2] if n + 2 < len(raw) else "")
            if floating and (intro_list or intro_table):
                rows.append(row(path, number, Check.LABEL_GAP, "fail", "floating label lacks its colon; a list or record label carries [LABEL]:"))
            elif not floating and gap and intro_list:
                rows.append(row(path, number, Check.LABEL_GAP, "fail", "blank gap between the label and its list; hug the list"))
            elif not floating and not gap and intro_table:
                rows.append(row(path, number, Check.LABEL_GAP, "fail", "label sits directly on a table; keep one blank line before the grid"))
        if SETEXT.match(line) and n > 0 and raw[n - 1].strip() and not TABLE_SEP.match(line):
            rows.append(row(path, number, Check.SETEXT_HEADING, "fail", "setext heading marker; spell the heading as ATX `#` on one line"))
        if line.lstrip().startswith("|") and n + 1 < len(raw) and TABLE_SEP.match(raw[n + 1]):
            indent = line[: len(line) - len(line.lstrip())]
            headers = split_cells(line)
            aligns = tuple(aligned(cell) for cell in split_cells(raw[n + 1]))
            body: list[tuple[str, ...]] = []
            cursor = n + 2
            while cursor < len(raw) and raw[cursor].lstrip().startswith("|"):
                body.append(split_cells(raw[cursor]))
                cursor += 1
            tables.append(Table(number, cursor, indent, headers, aligns, tuple(body)))
            plain_run = False
            n = cursor
            continue
        if line.lstrip().startswith("|"):
            rows.append(row(path, number, Check.TABLE_SEVERED, "fail", "table row stranded outside a grid; rejoin it to its table or delete it"))
        links.extend(LinkRef(number, link.group(2)) for link in LINK.finditer(re.sub(r"`[^`]*`", "", line)))
        if not template and not EXAMPLE_LINE.match(line):
            if ARTICLE_ANNOTATION.match(line):
                rows.append(
                    row(path, number, Check.ARTICLE_OPENER, "fail", f"annotation opens on 'the'{ARTICLE_CURE}")
                )
            elif ARTICLE_FRAGMENT.match(line):
                rows.append(
                    row(path, number, Check.ARTICLE_OPENER, "fail", f"entry opens on 'the'{ARTICLE_CURE}")
                )
        if item := LIST_ITEM.match(line):
            if item.group("mark") in "*+":
                rows.append(row(path, number, Check.LIST_MARKER, "fail", f"bullet marker {item.group('mark')} where - is the only legal marker"))
            cursor = n + 1
            chunks = [item.group("body")]
            # A nested fence ends the measured entry text; its body is fence material, never entry prose.
            while cursor < len(raw) and raw[cursor].startswith((" ", "\t")) and not LIST_ITEM.match(raw[cursor]) and not FENCE.match(raw[cursor]):
                chunks.append(raw[cursor].strip())
                cursor += 1
            text_joined = " ".join(chunks)
            stripped = " ".join(span.text.strip() for span in prose_spans(text_joined, number))
            share = 1 - (len(stripped) / max(1, len(text_joined.strip())))
            lists.append(ListEntry(number, text_joined, stripped, share))
            if cursor > n + 1:
                rows.append(
                    row(
                        path,
                        number,
                        Check.LIST_WRAP,
                        "fail",
                        "list item hard-wraps across physical lines; the bullet is one logical line the editor soft-wraps",
                    )
                )
        if not line.lstrip().startswith("|"):
            prose.extend(prose_spans(line, number))
            if pointered and line.strip() and not EXAMPLE_LINE.match(line):
                delinked = LINK.sub(" ", line)
                rows.extend(
                    row(path, number, Check.SIBLING_POINTER, "warn", f"{hit.group(0)} anchors a sibling's interior; compose its law silently")
                    for hit in POINTER.finditer(delinked)
                )
                if not HEADING.match(line) and re.search(rf"(?<![\w/.-]){re.escape(path.name)}\b", delinked):
                    rows.append(row(path, number, Check.SIBLING_POINTER, "warn", f"{path.name} names itself; a page never self-references"))
        stripped = line.strip()
        plain = (
            bool(stripped) and not line.startswith((" ", "\t")) and not stripped.startswith(PLAIN_EXCLUDED) and NUMBERED_LEAD.match(stripped) is None
        )
        if plain and plain_run:
            rows.append(row(path, number, Check.PROSE_WRAP, "fail", "hard-wrapped paragraph; write the paragraph as one logical line"))
        if not template and (plain or LABELED_PARAGRAPH.match(stripped)):
            sentence_count = len(SENTENCE_END.findall(" ".join(span.text for span in prose_spans(stripped, number))))
            if len(stripped) > PROSE_CHAR_CAP or sentence_count > PROSE_SENTENCE_CAP:
                rows.append(
                    row(
                        path,
                        number,
                        Check.PROSE_BLOAT,
                        "warn",
                        f"paragraph {len(stripped)} chars / {sentence_count} sentences past caps {PROSE_CHAR_CAP}/{PROSE_SENTENCE_CAP};"
                        " cut 20-30% — kill sediment, tighten phrasing, split only where two concerns separate",
                    )
                )
        plain_run = plain
        n += 1
    if fence is not None:
        rows.append(row(path, fence[2], Check.FENCE_UNCLOSED, "fail", "opening fence never closes; close it with a matching marker run"))
    doc = Document(str(path), "templates" in path.parts, tuple(prose), tuple(tables), tuple(headings), tuple(links), tuple(lists))
    return doc, tuple(rows)


# --- [CHECKS] ---------------------------------------------------------------------------


def prose_column_cell(cell: str) -> bool:
    # A stub-key column (short atomic decision key) is not prose; only a comma/semicolon or a phrase past the
    # word budget marks a genuine prose column that a link cell must not ride beside.
    bare = QUOTED_SPAN.sub(" ", cell)
    return not LINK.search(bare) and (CLAUSE_PUNCT.search(bare) is not None or len(bare.split()) > CELL_WORD_BUDGET)


def table_rows(doc: Document) -> tuple[Row, ...]:
    rows: list[Row] = []
    for table in doc.tables:
        sep_line = table.line + 1
        indexed = bool(table.headers) and table.headers[0] == "[INDEX]"
        rows.extend(
            row(doc.path, table.line, Check.TABLE_HEADER, "fail", f"header cell {cell or '<empty>'} is not a bracketed [UPPER_SNAKE] rubric")
            for cell in table.headers
            if not HEADER_CELL.match(cell)
        )
        if len(table.aligns) != len(table.headers):
            rows.append(
                row(
                    doc.path,
                    sep_line,
                    Check.TABLE_ALIGN,
                    "fail",
                    f"separator cells {len(table.aligns)} != header cells {len(table.headers)}; re-pad the separator to one cell per column",
                )
            )
        rows.extend(
            row(doc.path, sep_line, Check.TABLE_ALIGN, "fail", f"column {position} carries no alignment colon; state `:---`, `:---:`, or `---:`")
            for position, align in enumerate(table.aligns, 1)
            if align == "none"
        )
        for index, body in enumerate(table.rows, 1):
            if len(body) != len(table.headers):
                rows.append(
                    row(
                        doc.path,
                        table.line + index + 1,
                        Check.TABLE_SHAPE,
                        "fail",
                        f"row cells {len(body)} != header cells {len(table.headers)}; re-pad the row to the header width",
                    )
                )
        if len(table.rows) >= 2 and not indexed:
            rows.append(row(doc.path, table.line, Check.TABLE_INDEX, "fail", "enumerable table lacks its leading centered [INDEX] column; insert it"))
        if indexed:
            if table.aligns and table.aligns[0] != "center":
                rows.append(
                    row(doc.path, sep_line, Check.TABLE_INDEX, "fail", f"[INDEX] column is {table.aligns[0]}-aligned; center it with `:---:`")
                )
            for index, body in enumerate(table.rows, 1):
                expected = f"[{index:02}]"
                actual = body[0] if body else "<empty>"
                if actual.strip() != expected:
                    rows.append(
                        row(doc.path, table.line + index + 1, Check.TABLE_INDEX, "fail", f"index cell {actual or '<empty>'} != {expected}; renumber")
                    )
        # Row count stays uncapped; every tabular row remains, while oversized grids relieve cells or decompose on the column axis.
        if len(table.headers) > TABLE_COLUMN_CEILING:
            rows.append(
                row(
                    doc.path,
                    table.line,
                    Check.TABLE_BOUNDS,
                    "fail",
                    f"{len(table.headers)} columns exceeds the {TABLE_COLUMN_CEILING}-column ceiling; decompose on the column axis, never to prose",
                )
            )
        linked = any(LINK.search(QUOTED_SPAN.sub("", cell)) for body in table.rows for cell in body)
        prose_bearing = any(prose_column_cell(cell) for body in table.rows for cell in body)
        if linked and prose_bearing:
            rows.append(
                row(
                    doc.path,
                    table.line,
                    Check.TABLE_LINKS,
                    "fail",
                    "a prose column rides beside a link column; move links below the table or drop the prose column",
                )
            )
        if (width := max(len(line) for line in rendered(table))) > TABLE_WIDTH_CAP:
            rows.append(
                row(doc.path, table.line, Check.TABLE_WIDTH, "fail", f"rendered width {width} > cap {TABLE_WIDTH_CAP}; relieve cells, keep the table")
            )
        rows.extend(
            row(
                doc.path,
                table.line + index + 1,
                Check.TABLE_CELL,
                "warn",
                f"prose-crammed cell ({len(cell)} chars); hoist repeats into the header or relieve the clause into the lead — the grid stays",
            )
            for index, body in enumerate(table.rows, 1)
            for cell in body
            if len(cell) > CELL_BUDGET
        )
        rows.extend(
            row(doc.path, table.line + index + 1, Check.TABLE_PROSE, "warn", f"{hit.group(0)} rides a cell; reword the cell in place, the grid stays")
            for index, body in enumerate(table.rows, 1)
            for cell in body
            for pattern in (HEDGE_WORDS, MARKER_WORDS, META_PHRASE)
            for hit in pattern.finditer(QUOTED_SPAN.sub(" ", cell))
        )
        rows.extend(
            row(
                doc.path, table.line + index + 1, Check.BOLD_EMPHASIS, "fail", f"{hit.group(0)[:60]} — bold is banned; structure carries the emphasis"
            )
            for index, body in enumerate(table.rows, 1)
            for cell in body
            for hit in BOLD.finditer(QUOTED_SPAN.sub(" ", cell))
        )
    return tuple(rows)


def heading_rows(doc: Document) -> tuple[Row, ...]:
    if doc.template:
        return ()
    rows: list[Row] = []
    h1 = tuple(heading for heading in doc.headings if heading.level == 1)
    rows.extend(row(doc.path, heading.line, Check.HEADING_H1, "fail", "duplicate H1; a page carries one H1 rubric") for heading in h1[1:])
    rows.extend(
        row(doc.path, heading.line, Check.HEADING_H1, "fail", f"H1 is one bracketed rubric, never theater: {heading.title[:50]}")
        for heading in h1
        if heading.title.startswith("[") and not HEADER_CELL.match(heading.title)
    )
    expected = 1
    subsection = 0
    for heading in (heading for heading in doc.headings if heading.level in (2, 3)):
        if heading.level == 3:
            subsection += 1
            deep = H3_NUMBERED.match(heading.title)
            if not deep or (int(deep.group(1)), int(deep.group(2))) != (expected - 1, subsection):
                rows.append(
                    row(
                        doc.path,
                        heading.line,
                        Check.HEADING_ORDER,
                        "fail",
                        f"H3 breaks [{expected - 1:02}.{subsection}] numbering: {heading.title[:50]}",
                    )
                )
            continue
        subsection = 0
        matched = NUMBERED_SECTION.match(heading.title)
        if not matched:
            rows.append(row(doc.path, heading.line, Check.HEADING_ORDER, "fail", f"H2 is not [NN]-[TOKEN] numbered: {heading.title[:50]}"))
            continue
        actual = int(matched.group("n"))
        if actual != expected:
            rows.append(
                row(doc.path, heading.line, Check.HEADING_ORDER, "fail", f"H2 numbered [{actual:02}] where [{expected:02}] is next; renumber")
            )
        expected = actual + 1
    slugs: dict[str, int] = {}
    for heading in doc.headings:
        slug = re.sub(r"[^a-z0-9 -]", "", heading.title.lower())
        if slug in slugs:
            rows.append(
                row(doc.path, heading.line, Check.HEADING_ANCHOR, "fail", f"anchor slug collides with line {slugs[slug]}; retitle one heading")
            )
        else:
            slugs[slug] = heading.line
    return tuple(rows)


def link_rows(doc: Document) -> tuple[Row, ...]:
    if doc.template:
        return ()
    path = Path(doc.path)
    routing = path.name in ROUTING_FILES
    rows: list[Row] = []
    for link in doc.links:
        target = link.target.split("#", 1)[0]
        if not target or target == "path" or re.match(r"^[a-z][a-z0-9+.-]*:", target, re.IGNORECASE):
            continue
        if not routing:
            rows.append(
                row(
                    doc.path,
                    link.line,
                    Check.COUPLED_LINK,
                    "fail",
                    f"{link.target} couples a non-routing page; links live only in {', '.join(sorted(ROUTING_FILES))}",
                )
            )
        if not (path.parent / target).resolve(strict=False).exists():
            rows.append(row(doc.path, link.line, Check.DEAD_RELATIVE_LINK, "fail", f"{link.target} resolves to no file from this page"))
    return tuple(rows)


def prose_rows(doc: Document) -> tuple[Row, ...]:
    rows: list[Row] = []
    for span in doc.prose:
        if EXAMPLE_LINE.match(span.text):
            if not QUOTE_LINE.match(span.text):
                rows.extend(
                    row(
                        doc.path,
                        span.line,
                        Check.ARTICLE_OPENER,
                        "fail",
                        f"{hit.group(0).lstrip('.!?:; ')}{ARTICLE_CURE}",
                    )
                    for hit in SENTENCE_ARTICLE.finditer(QUOTED_SPAN.sub(" ", span.text))
                )
            continue
        if not doc.template:
            rows.extend(
                row(doc.path, span.line, Check.TEMPLATE_SLOT, "fail", f"{hit.group(0)} is an unfilled template slot; fill it or delete the line")
                for hit in PLACEHOLDER.finditer(span.text)
            )
        rows.extend(
            row(doc.path, span.line, Check.BOLD_EMPHASIS, "fail", f"{hit.group(0)[:60]} — bold is banned; structure carries the emphasis")
            for hit in BOLD.finditer(span.text)
        )
        rows.extend(
            row(doc.path, span.line, Check.GLYPH_BAN, "fail", f"banned glyph {hit.group(0)!r}; delete it — bracketed [X] markers carry status")
            for hit in EMOJI.finditer(span.text)
        )
        voiced = QUOTED_SPAN.sub(" ", span.text)
        rows.extend(
            row(doc.path, span.line, check, status, f"{hit.group(0).lstrip('.!?:; ')}{cure}")
            for check, pattern, status, cure in PATTERNS
            for hit in pattern.finditer(voiced)
            if not (check is Check.VERSION_ANCHOR and CITATION_LEAD.search(voiced[: hit.start()]))
        )
    return tuple(rows)


def list_rows(doc: Document) -> tuple[Row, ...]:
    if doc.template:
        return ()
    parts = Path(doc.path).parts
    instruction = Path(doc.path).name in INSTRUCTION_FILES or "rules" in parts
    rows: list[Row] = []
    for entry in doc.lists:
        card = ROUTER_CARD.match(f"- {entry.text}")
        if card is not None and f"- {entry.text}" != carded(card):
            rows.append(row(doc.path, entry.line, Check.LIST_LEADER, "fail", f"router card deviates from - [NN]-[TOKEN](path): {entry.text[:50]}"))
        elif (
            entry.text.startswith("[")
            and not CHECKBOX.match(entry.text)
            and not LIST_LEADER.match(f"- {entry.text}")
            and not (instruction and INVOCATION_LEADER.match(f"- {entry.text}"))
        ):
            rows.append(
                row(
                    doc.path,
                    entry.line,
                    Check.LIST_LEADER,
                    "fail",
                    f"{entry.text.split(':', 1)[0]} is not a legal leader — [NN]-[TOKEN]:, [TOKEN]:, or [NN]: with UPPERCASE_SNAKE tokens",
                )
            )
        if entry.span_share < ROSTER_SPAN_SHARE and not entry.text.startswith("`") and FIELD_LINE.match(entry.text) is None:
            sentences = len(SENTENCE_END.findall(entry.prose))
            if sentences > LIST_SENTENCE_CAP:
                detail = f"{sentences} sentences > cap {LIST_SENTENCE_CAP}; split distinct decisions into sibling entries, delete restatements"
                rows.append(row(doc.path, entry.line, Check.LIST_BLOAT, "warn", detail))
            elif len(entry.text) > LIST_CHAR_CAP:
                detail = f"entry {len(entry.text)} chars > cap {LIST_CHAR_CAP}; tighten phrasing or demote the tail to its owning surface"
                rows.append(row(doc.path, entry.line, Check.LIST_BLOAT, "warn", detail))
    return tuple(rows)


def spread_tokens(text: str) -> frozenset[str]:
    return frozenset(SPREAD_WORD.findall(text.lower()))


def restated(first: frozenset[str], second: frozenset[str]) -> bool:
    bounded = len(first) >= SPREAD_FLOOR and len(second) >= SPREAD_FLOOR
    return bounded and len(first & second) / len(first | second) >= SPREAD_SHARE


def spread_rows(doc: Document) -> tuple[Row, ...]:
    # SAME_DECISION_SPREAD census: adjacent sentences in one paragraph and adjacent sibling entries that carry
    # near-identical content words restate one ruling; the collapse keeps every distinct decision as its own clause.
    if doc.template:
        return ()
    rows: list[Row] = []
    for span in doc.prose:
        sentences = tuple(sentence for sentence in SENTENCE_SPLIT.split(span.text) if sentence.strip())
        rows.extend(
            row(
                doc.path,
                span.line,
                Check.SAME_DECISION,
                "warn",
                "adjacent sentences restate one decision; collapse to the strongest ruling — only restatements merge",
            )
            for first, second in pairwise(sentences)
            if restated(spread_tokens(first), spread_tokens(second))
        )
    rows.extend(
        row(
            doc.path,
            second.line,
            Check.SAME_DECISION,
            "warn",
            f"entry restates line {first.line}; merge to one entry smaller than both — a distinct decision survives as its own entry",
        )
        for first, second in pairwise(doc.lists)
        if second.line - first.line <= 2 and restated(spread_tokens(first.prose), spread_tokens(second.prose))
    )
    return tuple(rows)


def card_vocabulary(lines: tuple[str, ...]) -> tuple[frozenset[str], dict[str, int], frozenset[str]]:
    # First pass over a card file: the field roster its template comments declare, section-marker lines, templated bands.
    fields: set[str] = set()
    sections: dict[str, int] = {}
    templated: set[str] = set()
    band = ""
    commented = False
    for number, line in enumerate(lines, 1):
        if (section := CARD_BAND.match(line)) is not None:
            band = section["band"]
            sections[band] = number
            continue
        stripped = line.strip()
        opened = not commented and stripped.startswith(COMMENT_OPEN)
        if opened and SOURCE_ONLY in stripped and band:
            templated.add(band)
        if commented or opened:
            if (field := CARD_BULLET.match(stripped)) is not None:
                fields.add(field["label"])
            commented = COMMENT_CLOSE not in stripped
    return frozenset(fields) or RATIFIED_FIELDS, sections, frozenset(templated)


def card_rows(path: Path, text: str) -> tuple[Row, ...]:
    # IDEAS/TASKLOG marker census: leader grammar, closed statuses, section agreement, the template-comment field
    # vocabulary with drift detection, four core bullets per open card, and repo-relative paths.
    if path.name not in CARD_FILES or "templates" in path.parts or teaching(path):
        return ()
    lines = tuple(text.splitlines())
    vocabulary, sections, templated = card_vocabulary(lines)
    rows: list[Row] = []
    band = ""
    commented = False
    card: tuple[int, str, str] | None = None
    seen: set[str] = set()

    def sealed() -> None:
        if card and band == "OPEN" and card[2] in OPEN_STATUSES and (missing := [field for field in CORE_FIELDS if field not in seen]):
            detail = f"open card [{card[1]}] lacks {', '.join(missing)} — Capability, Shape, Unlocks, Anchors ride every open card"
            rows.append(row(path, card[0], Check.CARD_FIELD, "fail", detail))

    for number, line in enumerate(lines, 1):
        stripped = line.strip()
        if commented or stripped.startswith(COMMENT_OPEN):
            commented = COMMENT_CLOSE not in stripped
            continue
        if (section := CARD_BAND.match(line)) is not None or HEADING.match(line):
            sealed()
            card, band = None, section["band"] if section else ""
            continue
        if (hit := ABSOLUTE_PATH.search(line)) is not None:
            rows.append(row(path, number, Check.MACHINE_PATH, "fail", f"{hit.group(0)} is an absolute machine path; card paths stay repo-relative"))
        if (leader := CARD_HEAD.match(line)) is not None:
            sealed()
            slug, status = leader["slug"], leader["status"]
            card, seen = (number, slug, status), set()
            if NUMERIC_ID.match(slug):
                rows.append(
                    row(
                        path,
                        number,
                        Check.CARD_LEADER,
                        "fail",
                        f"id [{slug}] is pure-numeric; ids are semantic UPPERCASE_SNAKE slugs carrying meaning",
                    )
                )
            elif not SLUG_SHAPE.match(slug):
                rows.append(row(path, number, Check.CARD_LEADER, "fail", f"slug [{slug}] breaks UPPERCASE_SNAKE — a hyphenated slug is a defect"))
            if status not in OPEN_STATUSES | CLOSED_STATUSES:
                rows.append(row(path, number, Check.CARD_STATUS, "fail", f"status {status} outside the closed vocabulary — {STATUS_LAW}"))
            elif band == "OPEN" and status in CLOSED_STATUSES:
                rows.append(row(path, number, Check.CARD_STATUS, "fail", f"closed status {status} under [OPEN]; move the card to [02]-[CLOSED]"))
            elif band == "CLOSED" and status in OPEN_STATUSES:
                rows.append(row(path, number, Check.CARD_STATUS, "fail", f"open status {status} under [CLOSED]; reopen the card under [01]-[OPEN]"))
            elif not band:
                rows.append(row(path, number, Check.CARD_SECTION, "fail", f"card [{slug}] sits outside the [OPEN]/[CLOSED] sections"))
            continue
        if card and stripped.startswith("- "):
            if (field := CARD_BULLET.match(stripped)) is None:
                rows.append(row(path, number, Check.CARD_FIELD, "fail", "card bullet is not a `- Field:` line from the template vocabulary"))
            elif field["label"] not in vocabulary:
                detail = f"field {field['label']} drifts from the template-comment vocabulary {'|'.join(sorted(vocabulary))}"
                rows.append(row(path, number, Check.CARD_FIELD, "fail", detail))
            else:
                seen.add(field["label"])
            continue
        if not stripped:
            sealed()
            card = None
    sealed()
    for wanted in ("OPEN", "CLOSED"):
        if wanted not in sections:
            rows.append(row(path, 0, Check.CARD_SECTION, "fail", f"card file lacks its ## [NN]-[{wanted}] section marker"))
        elif wanted not in templated:
            detail = f"[{wanted}] section carries no source-only template comment; the comment declares the card grammar"
            rows.append(row(path, sections[wanted], Check.CARD_SECTION, "fail", detail))
    return tuple(sorted(rows, key=lambda finding: finding.line))


def rulings_vocabulary(lines: tuple[str, ...]) -> tuple[str, ...]:
    # Union law: code-spanned labels the file's own template comments declare extend the ratified closed set;
    # ratified order leads, declared extensions follow in declaration order and rank after every ratified label.
    declared: list[str] = []
    commented = False
    for line in lines:
        stripped = line.strip()
        if commented or stripped.startswith(COMMENT_OPEN):
            declared.extend(label for label in SPANNED_LABEL.findall(stripped) if label not in declared)
            commented = COMMENT_CLOSE not in stripped
    return RULING_SECTIONS + tuple(label for label in declared if label not in RULING_SECTIONS)


def rulings_rows(path: Path, text: str) -> tuple[Row, ...]:
    # RULINGS.md census: one [TOKEN_RULINGS] H1 and ## [NN]-[LABEL] sections inside the closed vocabulary,
    # present sections in canonical order, numbering contiguous from [01] under omit-and-renumber; the
    # per-row admission bar stays review judgment, never a pattern.
    if path.name != "RULINGS.md" or "templates" in path.parts or teaching(path):
        return ()
    lines = tuple(text.splitlines())
    order = rulings_vocabulary(lines)
    rank = {label: position for position, label in enumerate(order)}
    law = "|".join(order)
    rows: list[Row] = []
    fence: tuple[str, int, int] | None = None
    commented = False
    seen: dict[str, int] = {}
    anchored = False
    previous = ""
    expected = 1
    for number, line in enumerate(lines, 1):
        stripped = line.strip()
        if commented or stripped.startswith(COMMENT_OPEN):
            commented = COMMENT_CLOSE not in stripped
            continue
        matched = FENCE.match(line)
        if fence is None and matched:
            fence = (matched.group("marker")[0], len(matched.group("marker")), len(matched.group("indent")))
            continue
        if fence is not None:
            if fence_closes(matched, *fence):
                fence = None
            continue
        if (heading := HEADING.match(line)) is None:
            continue
        if len(heading.group("level")) == 1:
            anchored = True
            if not RULINGS_H1.match(heading.group("title")):
                detail = f"H1 {heading.group('title')[:50]} is not the owner rubric; a rulings page opens on one bracketed [TOKEN_RULINGS] H1"
                rows.append(row(path, number, Check.RULINGS_SECTION, "fail", detail))
            continue
        if len(heading.group("level")) != 2 or (numbered := H2_NUMBERED.match(heading.group("title"))) is None:
            continue
        actual, label = int(numbered.group(1)), numbered.group(2)[1:-1]
        if actual != expected:
            detail = f"section numbered [{actual:02}] where [{expected:02}] is next; an omitted section renumbers survivors — close the gap"
            rows.append(row(path, number, Check.RULINGS_SECTION, "fail", detail))
        expected = actual + 1
        if label not in rank:
            detail = f"[{label}] outside the closed section vocabulary {law}; re-home its rulings under a declared section"
            rows.append(row(path, number, Check.RULINGS_SECTION, "fail", detail))
        elif label in seen:
            detail = f"[{label}] duplicates the section at line {seen[label]}; one section owns a label — merge the rulings there"
            rows.append(row(path, number, Check.RULINGS_SECTION, "fail", detail))
        else:
            seen[label] = number
            if previous and rank[label] < rank[previous]:
                detail = f"[{label}] rides after [{previous}] against canonical order {law}; reorder the sections and renumber from [01]"
                rows.append(row(path, number, Check.RULINGS_SECTION, "fail", detail))
            previous = label
    if not anchored:
        rows.append(row(path, 0, Check.RULINGS_SECTION, "fail", "page lacks its # [TOKEN_RULINGS] H1; one owner rubric opens the registry"))
    return tuple(rows)


def research_rows(path: Path, text: str) -> tuple[Row, ...]:
    # Design-page research census: one terminal ## [NN]-[RESEARCH] section owning every well-formed
    # `- [TOKEN]-[OPEN|BLOCKED]: <question>; <route>` row, `(none)` marking the legal-empty section;
    # a spec page under .planning/<sub>/ carries the section always, and absence is an error.
    if path.name in CARD_FILES or "templates" in path.parts or teaching(path):
        return ()
    parts = path.parts
    spec_page = (
        ".planning" in parts and parts.index(".planning") < len(parts) - 2 and path.name not in ROUTING_FILES and path.name != "ARCHITECTURE.md"
    )
    lines = tuple(text.splitlines())
    rows: list[Row] = []
    fence: tuple[str, int, int] | None = None
    research: int | None = None
    inside = False
    populated = False
    for number, line in enumerate(lines, 1):
        matched = FENCE.match(line)
        if fence is None and matched:
            fence = (matched.group("marker")[0], len(matched.group("marker")), len(matched.group("indent")))
            continue
        if fence is not None:
            if fence_closes(matched, *fence):
                fence = None
            continue
        if (heading := HEADING.match(line)) is not None and len(heading.group("level")) == 2:
            if RESEARCH_HEAD.match(heading.group("title")):
                if research is not None:
                    rows.append(row(path, number, Check.RESEARCH_SECTION, "fail", "duplicate [RESEARCH] marker; one terminal section owns every row"))
                    continue
                research, inside = number, True
            elif inside:
                rows.append(row(path, research or number, Check.RESEARCH_SECTION, "fail", "[RESEARCH] is displaced — the section ends the page"))
                inside = False
            continue
        if not inside:
            if (stray := RESEARCH_ENTRY.match(line)) is not None and stray["status"] in RESEARCH_STATUSES | {"RESOLVED"}:
                detail = f"research row [{stray['token']}] outside the terminal [RESEARCH] section; the section owns every research row"
                rows.append(row(path, number, Check.RESEARCH_SECTION, "fail", detail))
            continue
        if line.strip() == "(none)":
            populated = True
            continue
        if not line.startswith("- "):
            continue
        populated = True
        if (entry := RESEARCH_ENTRY.match(line)) is None:
            rows.append(row(path, number, Check.RESEARCH_ROW, "fail", "row is not `- [TOKEN]-[OPEN|BLOCKED]: <question>; <route>`"))
            continue
        token, status, body = entry["token"], entry["status"], entry["body"]
        if NUMERIC_ID.match(token):
            rows.append(
                row(
                    path,
                    number,
                    Check.RESEARCH_ROW,
                    "fail",
                    f"token [{token}] is pure-numeric; tokens are semantic UPPERCASE_SNAKE slugs carrying meaning",
                )
            )
        elif not SLUG_SHAPE.match(token):
            rows.append(row(path, number, Check.RESEARCH_ROW, "fail", f"token [{token}] breaks UPPERCASE_SNAKE — a hyphenated token is a defect"))
        if status == "RESOLVED":
            rows.append(row(path, number, Check.RESEARCH_ROW, "fail", "RESOLVED is not a research status — a resolved row is deleted outright"))
        elif status not in RESEARCH_STATUSES:
            rows.append(row(path, number, Check.RESEARCH_ROW, "fail", f"status {status} outside the research vocabulary OPEN|BLOCKED"))
        question, _, route = body.partition(";")
        if not (question.strip() and route.strip()):
            rows.append(row(path, number, Check.RESEARCH_ROW, "fail", "row lacks its `<question>; <route>` split — exact question, then route"))
    if research is not None and not populated:
        rows.append(row(path, research, Check.RESEARCH_SECTION, "fail", "(none) marks the empty [RESEARCH] section; the marker survives realization"))
    if research is None and spec_page:
        detail = "design page lacks its terminal ## [NN]-[RESEARCH] section; append it, `(none)` marking legal-empty"
        rows.append(row(path, 0, Check.RESEARCH_SECTION, "fail", detail))
    return tuple(rows)


def skill_rows(path: Path, text: str) -> tuple[Row, ...]:
    if path.name != "SKILL.md":
        return ()
    lines = tuple(text.splitlines())
    rows: list[Row] = []
    end = frontmatter_end(lines)
    if end == 0:
        return (row(path, 1, Check.SKILL_FRONTMATTER, "fail", "missing or keyless frontmatter; open with `---` carrying name and description"),)
    body = lines[1 : end - 1]
    fields: dict[str, tuple[int, str]] = {}
    current: str | None = None
    for offset, line in enumerate(body, 2):
        key = YAML_KEY.match(line)
        if key and not line.startswith((" ", "\t")):
            current = line.split(":", 1)[0].strip()
            fields[current] = (offset, line.split(":", 1)[1].strip().lstrip(">|-").strip())
        elif current and line.startswith((" ", "\t")):
            anchor, value = fields[current]
            fields[current] = (anchor, f"{value} {line.strip()}".strip())
    rows.extend(
        row(path, 1, Check.SKILL_FRONTMATTER, "fail", f"frontmatter lacks {required}")
        for required in ("name", "description")
        if not fields.get(required, (0, ""))[1]
    )
    name_anchor, name = fields.get("name", (1, ""))
    if name:
        if not SKILL_NAME_SHAPE.match(name) or len(name) > SKILL_NAME_CAP:
            rows.append(row(path, name_anchor, Check.SKILL_NAME, "fail", f"{name} breaks lowercase-hyphen shape or cap {SKILL_NAME_CAP}"))
        if SKILL_NAME_RESERVED.search(name):
            rows.append(row(path, name_anchor, Check.SKILL_NAME, "fail", f"{name} carries a reserved word; drop claude/anthropic from the name"))
        if name != path.parent.name:
            rows.append(row(path, name_anchor, Check.SKILL_NAME, "fail", f"{name} != directory {path.parent.name}; rename one to match the other"))
    anchor, description = fields.get("description", (1, ""))
    if description:
        voiced = QUOTED_SPAN.sub(" ", description)
        rows.extend(
            row(path, anchor, Check.SKILL_DESCRIPTION, "fail", f"{hit.group(0)} voices a persona; a description states triggers in third person")
            for hit in SKILL_VOICE.finditer(voiced)
        )
        if len(description) < SKILL_DESCRIPTION_FLOOR:
            rows.append(row(path, anchor, Check.SKILL_DESCRIPTION, "fail", f"{len(description)} chars carries no discriminating triggers"))
        elif len(description) > SKILL_DESCRIPTION_CEILING:
            rows.append(row(path, anchor, Check.SKILL_DESCRIPTION, "fail", f"{len(description)} chars > listing ceiling {SKILL_DESCRIPTION_CEILING}"))
        elif len(description) > SKILL_DESCRIPTION_CAP:
            rows.append(row(path, anchor, Check.SKILL_DESCRIPTION, "warn", f"{len(description)} chars > portability budget {SKILL_DESCRIPTION_CAP}"))
    if len(lines) > SKILL_ROOT_CAP:
        rows.append(
            row(path, len(lines), Check.SKILL_ROOT_BUDGET, "fail", f"root {len(lines)} lines > cap {SKILL_ROOT_CAP}; move body into references/")
        )
    return tuple(rows)


def bundle_rows(path: Path, text: str) -> tuple[Row, ...]:
    if path.name != "SKILL.md":
        return ()
    rows: list[Row] = [
        row(path, 0, Check.SKILL_BUNDLE_ROUTER, "fail", f"{readme.relative_to(path.parent).as_posix()} rides a bundle; SKILL.md is the only router")
        for readme in sorted(path.parent.rglob("README.md"))
    ]
    for sibling in sorted(path.parent.rglob("*.md")):
        relative = sibling.relative_to(path.parent).as_posix()
        if sibling == path or relative in text or sibling.name in text:
            continue
        rows.append(row(path, 0, Check.SKILL_BUNDLE_ORPHAN, "warn", f"{relative} unreachable from root"))
    return tuple(rows)


def comment_rows(path: Path, text: str) -> tuple[Row, ...]:
    marker = MARKERS[path.suffix]
    rows: list[Row] = []
    run: list[tuple[int, int]] = []
    # Header identity rows are frozen; the charter docstring below the header's dash divider carries shred, runt,
    # and width discipline but never the stack cap; the first code line opens the body zone for good.
    zone = "header"

    def close() -> None:
        if zone == "body" and len(run) > COMMENT_STACK_CAP:
            detail = f"{len(run)} stacked comment lines > cap {COMMENT_STACK_CAP}; merge toward the {CAP}-column width"
            rows.append(row(path, run[0][0], Check.COMMENT_STACK, "fail", detail))
        elif len(run) >= 2 and all(width < COMMENT_SHRED_FLOOR for _, width in run):
            detail = f"{len(run)} stacked comment lines all under {COMMENT_SHRED_FLOOR} columns; merge toward the {CAP}-column width, or delete a no-load comment whole"
            rows.append(row(path, run[0][0], Check.COMMENT_SHRED, "fail", detail))
        elif len(run) >= 2 and run[-1][1] < COMMENT_RUNT_FLOOR:
            detail = f"trailing runt line {run[-1][1]} < floor {COMMENT_RUNT_FLOOR}; re-flow into fewer balanced lines, refold the orphan into its neighbour, or delete the comment if it carries no load"
            rows.append(row(path, run[-1][0], Check.COMMENT_RUNT, "fail", detail))
        run.clear()

    for number, line in enumerate(text.splitlines(), 1):
        body = line.strip()
        if not body.startswith(marker):
            # Leading zones survive the shebang (`#!` opens every marker language's line 1) and interior blanks.
            close()
            if body and not (number == 1 and body.startswith("#!")):
                zone = "body"
            continue
        # Width is absolute geometry: it binds in every zone, structural lines included.
        width = len(line.rstrip())
        if width > COMMENT_WIDTH_CAP:
            rows.append(
                row(path, number, Check.COMMENT_WIDTH, "fail", f"comment line {width} > cap {COMMENT_WIDTH_CAP}; re-wrap with the lead packed")
            )
        glyphed = body.removeprefix(marker)
        tail = glyphed.removeprefix(" ")
        dash_fill = re.fullmatch(r"-{4,}", tail.strip()) is not None
        if zone == "header":
            if dash_fill:
                zone = "charter"
            continue
        if (
            DIVIDER.match(line)
            or dash_fill
            or (bool(glyphed) and not glyphed.startswith(" ") and COMMENT_GLYPH.match(glyphed) is not None)
            or COMMENT_DIRECTIVE.match(tail.lstrip()) is not None
            or COMMENT_LABEL_FILL.match(tail.strip()) is not None
            or COMMENT_ALIGNED.search(tail) is not None
        ):
            close()
            continue
        rows.extend(
            row(path, number, Check.HEDGE, "warn", f"{hit.group(0)}; open work is a tracked card, never a comment")
            for hit in MARKER_WORDS.finditer(tail)
        )
        if COMMENT_ARTICLE.match(tail):
            rows.append(row(path, number, Check.ARTICLE_OPENER, "fail", f"comment opens on 'the'{ARTICLE_CURE}"))
        run.append((number, width))
    close()
    return tuple(rows)


def divider_rows(path: Path, text: str) -> tuple[Row, ...]:
    marker = MARKERS[path.suffix]
    rows: list[Row] = []
    seen: dict[str, int] = {}
    open_section: tuple[int, str] | None = None
    payload = 0
    for number, line in enumerate(text.splitlines(), 1):
        matched = DIVIDER.match(line)
        if not matched or matched["marker"] != marker or matched["indent"]:
            stripped = line.strip()
            payload += bool(stripped) and not stripped.startswith(marker)
            continue
        body = DIVIDER_BODY.match(matched["body"])
        if not body:
            rows.append(
                row(path, number, Check.SECTION_DIVIDER, "fail", f"divider label is not bracketed UPPER_SNAKE — `[LABEL]`: {matched['body'][:60]}")
            )
        elif body["tail"] and not DASH_TAIL.match(body["tail"]):
            rows.append(row(path, number, Check.SECTION_DIVIDER, "fail", "divider carries content beyond the label and dash fill; move it below"))
        elif body["tail"] and len(line) != DIVIDER_WIDTH:
            rows.append(row(path, number, Check.SECTION_WIDTH, "fail", f"full divider width {len(line)} != {DIVIDER_WIDTH}; re-pad the dash fill"))
        # Full dividers charter sections: duplicate labels, empty sections, and orphan sub-dividers are phantom
        # structure; every repair reads the enclosing section first, so the tier fails with no fixer arm — a divider
        # is corrected in style, structure, or label by hand, never deleted and never scripted.
        if body and body["tail"]:
            if body["label"] in seen:
                rows.append(
                    row(
                        path, number, Check.SECTION_DIVIDER, "fail", f"[{body['label']}] duplicates the section divider at line {seen[body['label']]}"
                    )
                )
            seen[body["label"]] = number
            if open_section and payload == 0:
                rows.append(
                    row(
                        path,
                        open_section[0],
                        Check.SECTION_DIVIDER,
                        "fail",
                        f"[{open_section[1]}] charters an empty section; phantom label or misplaced divider",
                    )
                )
            open_section, payload = (number, body["label"]), 0
        elif body and open_section is None:
            rows.append(row(path, number, Check.SECTION_DIVIDER, "fail", "sub-section divider precedes any chartering section"))
    if open_section and payload == 0:
        rows.append(
            row(
                path,
                open_section[0],
                Check.SECTION_DIVIDER,
                "fail",
                f"[{open_section[1]}] charters an empty section; phantom label or misplaced divider",
            )
        )
    return tuple(rows)


def scan(path: Path, cap: int) -> tuple[Row, ...]:
    text = read(path)
    if isinstance(text, Row):
        return (text,)
    if path.suffix != ".md":
        return () if teaching(path) else divider_rows(path, text) + comment_rows(path, text)
    doc, lexer_rows = lex(path, text, cap)
    checks = lexer_rows + table_rows(doc) + heading_rows(doc) + link_rows(doc) + prose_rows(doc) + list_rows(doc) + spread_rows(doc)
    return checks + card_rows(path, text) + rulings_rows(path, text) + research_rows(path, text) + skill_rows(path, text) + bundle_rows(path, text)


# --- [EMIT] -----------------------------------------------------------------------------


def emit(rows: Iterable[Row], json_mode: bool) -> None:
    for finding in rows:
        if json_mode:
            print(ENCODER.encode(finding).decode())
        else:
            print(f"{finding.file}:{finding.line}: {finding.status.upper()} {finding.check} {finding.detail}")


def code(rows: Iterable[Row]) -> int:
    return 1 if any(finding.status == "fail" for finding in rows) else 0


# --- [REPAIR] ---------------------------------------------------------------------------
# Judgment-tier repairs emit SKIP instead of mutating; every gate-provable repair is applied.


def carded(matched: re.Match[str]) -> str:
    stem = re.sub(r"\.[A-Za-z0-9.]+$", "", matched["text"])
    return f"{matched['indent']}- [{int(matched['n']):02}]-{rubric(stem)}({matched['path']}): {matched['rest']}"


def rubric(text: str) -> str:
    token = re.sub(r"[^A-Za-z0-9]+", "_", text).strip("_").upper().lstrip("0123456789_")
    return f"[{token}]" if token else text


def repaired_table(table: Table) -> tuple[Table, tuple[Change, ...]]:
    changes: list[Change] = []
    headers = list(table.headers)
    aligns: list[Align] = list(table.aligns)
    rows = [list(body) for body in table.rows]
    for position, header in enumerate(headers):
        fixed = rubric(header)
        if header and not HEADER_CELL.match(header) and fixed != header and HEADER_CELL.match(fixed):
            changes.append(Change(table.line, Repair.HEADER, header, fixed))
            headers[position] = fixed
    numbers = [NUMBER_ENTRY.match(body[0]) if body else None for body in rows]
    sequential = bool(rows) and all(numbers) and [int(matched.group(1)) for matched in numbers if matched] == list(range(1, len(rows) + 1))
    if headers and headers[0].strip("[]") in INDEX_ALIASES:
        if headers[0] != "[INDEX]":
            changes.append(Change(table.line, Repair.INDEX, headers[0], "[INDEX]"))
            headers[0] = "[INDEX]"
        for offset, body in enumerate(rows, 1):
            expected = f"[{offset:02}]"
            if body and body[0] != expected:
                if numbers[offset - 1] or not body[0]:
                    changes.append(Change(table.line + offset + 1, Repair.ENTRY, body[0], expected))
                    body[0] = expected
                else:
                    changes.append(Change(table.line + offset + 1, Repair.SKIP, body[0], "non-numeric cell under [INDEX]; review"))
    elif len(rows) >= 2 and sequential:
        changes.append(
            Change(table.line, Repair.SKIP, headers[0] if headers else "<empty>", "sequential first column under a non-index header; review")
        )
    elif len(rows) >= 2:
        changes.append(Change(table.line, Repair.INDEX, "<absent>", "[INDEX] column inserted"))
        headers.insert(0, "[INDEX]")
        aligns.insert(0, "center")
        for offset, body in enumerate(rows, 1):
            body.insert(0, f"[{offset:02}]")
    ncol = len(headers)
    normalized: list[Align] = []
    for position in range(ncol):
        current: Align = aligns[position] if position < len(aligns) else "none"
        wanted: Align = "center" if position == 0 and headers and headers[0] == "[INDEX]" else ("left" if current == "none" else current)
        if wanted != current:
            changes.append(Change(table.line + 1, Repair.ALIGN, f"column {position + 1} {current}", wanted))
        normalized.append(wanted)
    for offset, body in enumerate(rows, 1):
        if len(body) > ncol:
            changes.append(Change(table.line + offset + 1, Repair.SKIP, f"{len(body)} cells", f"{ncol} header cells; ragged row needs review"))
        body.extend([""] * (ncol - len(body)))
    repaired = Table(table.line, table.end, table.indent, tuple(headers), tuple(normalized), tuple(tuple(body) for body in rows))
    return repaired, tuple(changes)


def repaired_lines(lines: list[str], skip_until: int) -> tuple[list[str], tuple[Change, ...]]:
    changes: list[Change] = []
    out: list[str] = []
    fence: tuple[str, int, int] | None = None
    section = 0
    subsection = 0
    for number, raw in enumerate(lines, 1):
        line = raw
        if raw.endswith((" ", "\t")):
            changes.append(Change(number, Repair.WHITESPACE, "<trailing whitespace>", "<stripped>"))
            line = raw.rstrip()
        if number <= skip_until:
            out.append(line)
            continue
        matched = FENCE.match(line)
        if fence is None and matched:
            fence = (matched.group("marker")[0], len(matched.group("marker")), len(matched.group("indent")))
            out.append(line)
            continue
        if fence is not None:
            if fence_closes(matched, *fence):
                fence = None
            out.append(line)
            continue
        if (item := LIST_ITEM.match(line)) and item.group("mark") in "*+":
            wanted = f"{item.group('indent')}- {item.group('body')}"
            changes.append(Change(number, Repair.LEADER, line.strip()[:60], wanted.strip()[:60]))
            line = wanted
        heading = HEADING.match(line)
        if heading and len(heading.group("level")) == 2:
            section, subsection = section + 1, 0
            numbered = H2_NUMBERED.match(heading.group("title"))
            label = numbered.group(2) if numbered else rubric(heading.group("title"))
            wanted = f"## [{section:02}]-{label}"
            if line != wanted and label.startswith("["):
                changes.append(Change(number, Repair.HEADING, line, wanted))
                line = wanted
        elif heading and len(heading.group("level")) == 3 and section:
            subsection += 1
            numbered = H3_NUMBERED.match(heading.group("title"))
            label = numbered.group(3) if numbered else rubric(heading.group("title"))
            wanted = f"### [{section:02}.{subsection}]-{label}"
            if line != wanted and label.startswith("["):
                changes.append(Change(number, Repair.HEADING, line, wanted))
                line = wanted
        elif (card := ROUTER_CARD.match(line)) is not None:
            wanted = carded(card)
            if line != wanted:
                changes.append(Change(number, Repair.LEADER, line.strip()[:60], wanted.strip()[:60]))
                line = wanted
        elif (bare := LEADER_BARE.match(line)) is not None:
            token = bare["token"]
            wanted = f"{bare['indent']}- [{f'{int(token):02}' if token.isdigit() else token}]: {bare['rest']}"
            changes.append(Change(number, Repair.LEADER, line.strip(), wanted.strip()))
            line = wanted
        elif (loose := LEADER_LOOSE.match(line)) is not None:
            wanted = f"{loose['indent']}- [{int(loose['n']):02}]-{rubric(loose['label'])}:{loose['rest']}"
            if line != wanted:
                changes.append(Change(number, Repair.LEADER, line.strip(), wanted.strip()))
                line = wanted
        out.append(line)
        if HEADING.match(line) and number < len(lines) and lines[number].strip():
            out.append("")
            changes.append(Change(number, Repair.SPACING, "<none>", "blank line after heading"))
    return out, tuple(changes)


def hugged_labels(lines: list[str]) -> tuple[list[str], tuple[Change, ...]]:
    out: list[str] = []
    changes: list[Change] = []
    fence: tuple[str, int, int] | None = None
    index, total = 0, len(lines)
    while index < total:
        line = lines[index]
        matched = FENCE.match(line)
        if fence is None and matched:
            fence = (matched.group("marker")[0], len(matched.group("marker")), len(matched.group("indent")))
            out.append(line)
            index += 1
            continue
        if fence is not None:
            if fence_closes(matched, *fence):
                fence = None
            out.append(line)
            index += 1
            continue
        # A bracketed label hugs its list: a floating label first earns the colon a list label carries; a table keeps the blank the grid demands.
        floating = bool(FLOATING_LABEL.match(line))
        if floating or GROUP_LABEL.match(line.strip()):
            gap, intro_list, intro_table = label_context(lines[index + 1] if index + 1 < total else "", lines[index + 2] if index + 2 < total else "")
            if floating and (intro_list or intro_table):
                labeled = line.rstrip() + ":"
                changes.append(Change(index + 1, Repair.COLON, line.strip(), labeled.strip()))
                out.append(labeled)
                if intro_list and gap:
                    changes.append(Change(index + 2, Repair.HUG, "<blank gap>", "<hugged to list>"))
                    index += 2
                    continue
                index += 1
                continue
            if not floating and gap and intro_list:
                out.append(line)
                changes.append(Change(index + 2, Repair.HUG, "<blank gap>", "<hugged to list>"))
                index += 2
                continue
        out.append(line)
        index += 1
    return out, tuple(changes)


def _strip_fm_styling(block: list[str]) -> tuple[list[str], int]:
    # One pass drops flagged keys with their nested blocks; repeated passes drop parents emptied by the cut.
    dropped = 0
    while True:
        out: list[str] = []
        index = 0
        cut = 0
        while index < len(block):
            line = block[index]
            depth = len(line) - len(line.lstrip())
            flagged = bool(MERMAID_STYLE_KEY.match(line) or MERMAID_HEX_VALUE.search(line))
            childless = line.rstrip().endswith(":") and not (
                index + 1 < len(block) and (len(block[index + 1]) - len(block[index + 1].lstrip())) > depth
            )
            if flagged or childless:
                cut += 1
                index += 1
                while index < len(block) and (not block[index].strip() or (len(block[index]) - len(block[index].lstrip())) > depth):
                    index += 1
                continue
            out.append(line)
            index += 1
        dropped += cut
        if cut == 0:
            return out, dropped
        block = out


def _elk_frontmatter(front: list[str], header: str, indent: str, at: int) -> tuple[list[str], tuple[Change, ...]]:
    # Layout-family completion: a bare fence takes the standing block whole, a partial one names its absent keys for hand repair.
    carried = {entry.strip() for entry in front}
    absent = tuple(key for key in MERMAID_ELK_KEYS if key not in carried)
    if family(header) not in MERMAID_LAYOUT or not absent:
        return front, ()
    if front:
        return front, (Change(at, Repair.SKIP, ", ".join(absent), "frontmatter carries other keys; merge the absent keys by hand"),)
    return [f"{indent}{entry}" for entry in MERMAID_ELK_BLOCK], (Change(at, Repair.CONFIG, "<none>", "standing ELK config block"),)


def repaired_mermaid(lines: list[str]) -> tuple[list[str], tuple[Change, ...]]:
    out: list[str] = []
    changes: list[Change] = []
    index, total = 0, len(lines)
    while index < total:
        line = lines[index]
        opened = FENCE.match(line)
        if not (opened and opened.group("info").strip().lower().split()[:1] == ["mermaid"]):
            out.append(line)
            index += 1
            continue
        indent = opened.group("indent")
        glyph, width, margin = opened.group("marker")[0], len(opened.group("marker")), len(indent)
        body: list[str] = []
        cursor = index + 1
        while cursor < total:
            if fence_closes(FENCE.match(lines[cursor]), glyph, width, margin):
                break
            body.append(lines[cursor])
            cursor += 1
        fm_end = next((i for i, entry in enumerate(body[1:], 1) if entry.strip() == "---"), -1) if body and body[0].strip() == "---" else -1
        front: list[str] = []
        kept: list[str] = []
        base = index + 2
        if fm_end >= 0:
            fm_block, dropped = _strip_fm_styling(body[1:fm_end])
            if dropped:
                changes.append(Change(base, Repair.STYLE, f"{dropped} styling frontmatter blocks", "<stripped>"))
            front = [f"{indent}---", *fm_block, f"{indent}---"] if any(entry.strip() for entry in fm_block) else []
            body, base = body[fm_end + 1 :], base + fm_end + 1
        for offset, source in enumerate(body):
            trimmed = source.strip()
            at = base + offset
            if MERMAID_STYLE_LINE.match(source) or MERMAID_CLASS_ASSIGN.match(source) or MERMAID_ANIMATE.match(source):
                changes.append(Change(at, Repair.STYLE, trimmed[:60], "<stripped>"))
                continue
            if MERMAID_BODY_CSS.search(source) and not trimmed.startswith("rect") and not MERMAID_BOX_COLOR.match(source):
                changes.append(Change(at, Repair.STYLE, trimmed[:60], "<stripped>"))
                continue
            entry = source
            if boxed := MERMAID_BOX_COLOR.match(entry):
                entry = f"{boxed.group(1)}transparent{entry[boxed.end() :]}"
                changes.append(Change(at, Repair.STYLE, trimmed[:60], entry.strip()[:60]))
            if MERMAID_CLASS_TAIL.search(entry):
                changes.append(Change(at, Repair.STYLE, trimmed[:60], "<class tail stripped>"))
                entry = MERMAID_CLASS_TAIL.sub("", entry)
            kept.append(entry)
        header = next((entry.strip() for entry in kept if entry.strip()), "")
        front, elk_changes = _elk_frontmatter(front, header, indent, index + 2)
        changes.extend(elk_changes)
        out.append(line)
        out.extend(front)
        out.extend(kept)
        if cursor < total:
            out.append(lines[cursor])
        index = cursor + 1
    return out, tuple(changes)


def repaired_source(path: Path, text: str) -> tuple[str, tuple[Change, ...]]:
    marker = MARKERS[path.suffix]
    changes: list[Change] = []
    out: list[str] = []
    for number, line in enumerate(text.splitlines(), 1):
        matched = DIVIDER.match(line)
        loose = DIVIDER_LOOSE.match(matched["body"]) if matched and matched["marker"] == marker and not matched["indent"] else None
        if loose is None or matched is None:
            if matched and matched["marker"] == marker and not matched["indent"]:
                changes.append(Change(number, Repair.SKIP, matched["body"][:60], "unlabeled divider body needs review"))
            out.append(line)
            continue
        label = rubric(loose["raw"])
        tail = loose["tail"]
        head = f"{matched['indent']}{marker} --- {label}"
        fill = re.fullmatch(r"\s*-+\s*", tail) is not None if tail else False
        if not HEADER_CELL.match(label) or (tail and not fill) or (tail and len(head) > DIVIDER_WIDTH - 2):
            changes.append(Change(number, Repair.SKIP, line.strip()[:60], "divider resists mechanical repair; review"))
            out.append(line)
            continue
        wanted = f"{head} " + "-" * (DIVIDER_WIDTH - len(head) - 1) if fill else head
        if wanted != line:
            changes.append(Change(number, Repair.DIVIDER, line.strip()[:60], wanted.strip()[:60]))
        out.append(wanted)
    return "\n".join(out) + ("\n" if text.endswith("\n") else ""), tuple(changes)


def repaired_text(path: Path, text: str, cap: int) -> tuple[str, tuple[Change, ...]]:
    if path.suffix != ".md":
        return (text, ()) if teaching(path) else repaired_source(path, text)
    template = "templates" in path.parts
    lines = list(text.splitlines())
    changes: list[Change] = []
    if not template:
        lines, line_changes = repaired_lines(lines, frontmatter_end(tuple(lines)))
        changes.extend(line_changes)
    if not template and not teaching(path):
        lines, payload_changes = repaired_mermaid(lines)
        changes.extend(payload_changes)
    lines, hug_changes = hugged_labels(lines)
    changes.extend(hug_changes)
    doc, _ = lex(path, "\n".join(lines), cap)
    for table in reversed(doc.tables):
        target = table
        if not template:
            target, table_changes = repaired_table(table)
            changes.extend(table_changes)
        block = list(rendered(target))
        if table.end < len(lines) and lines[table.end].strip():
            block.append("")
            changes.append(Change(table.end + 1, Repair.SPACING, "<none>", "blank line after table"))
        if table.line > 1 and lines[table.line - 2].strip():
            block.insert(0, "")
            changes.append(Change(table.line, Repair.SPACING, "<none>", "blank line before table"))
        lines[table.line - 1 : table.end] = block
    return "\n".join(lines) + ("\n" if text.endswith("\n") else ""), tuple(sorted(changes, key=lambda change: change.line))


# --- [ENTRY] ----------------------------------------------------------------------------


@APP.default
def gate(*paths: Path, json: bool = False, cap: int = CAP) -> int:
    files, faults = collect(paths)
    rows = faults + tuple(finding for path in files for finding in scan(path, cap))
    emit(rows, json)
    return code(rows)


@APP.command
def fix(*paths: Path, write: bool = False, cap: int = CAP) -> int:
    """Apply every deterministic repair; dry-run by default, --write mutates files.

    Returns:
        1 when faults or pending dry-run changes exist, 0 otherwise.
    """
    files, faults = collect(paths)
    emit(faults, json_mode=False)
    pending = 0
    for path in files:
        text = read(path)
        if isinstance(text, Row):
            emit((text,), json_mode=False)
            continue
        repaired, changes = repaired_text(path, text, cap)
        verb = "FIX" if write else "PLAN"
        for change in changes:
            print(f"{path}:{change.line}: {verb if change.kind is not Repair.SKIP else 'SKIP'} {change.kind} {change.before} -> {change.after}")
        if repaired != text:
            pending += 1
            if write:
                path.write_text(repaired, encoding="utf-8")
    return 1 if (faults or (not write and pending)) else 0


if __name__ == "__main__":
    sys.exit(APP(sys.argv[1:], result_action="return_value"))
