#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.15"
# dependencies = ["cyclopts>=4", "expression>=5", "msgspec>=0.19", "ruamel.yaml>=0.18"]
# ///
# ruff: noqa: T201, D100, D101, D102, D103, DOC201 — command docstrings are cyclopts help text; a Returns section would pollute --help

# --- [RUNTIME_PRELUDE] ------------------------------------------------------------------

from collections import Counter
from collections.abc import Callable, Mapping
from copy import replace as evolved
from dataclasses import dataclass
from fnmatch import fnmatch
from functools import reduce
import hashlib
import io
from itertools import accumulate, groupby, islice
import json
from operator import itemgetter
import os
from pathlib import Path, PurePosixPath
import re
import shlex
import shutil
import signal
from statistics import median
import string
import subprocess
import sys
import time
from types import MappingProxyType
from typing import Annotated, Final, Literal
import unicodedata

from cyclopts import App, Parameter
from expression import Error, Nothing, Ok, Option, Result, Some
from expression.collections import Block
from expression.extra.result import catch, traverse
import msgspec
from msgspec.structs import replace
from ruamel.yaml import YAML
from ruamel.yaml.error import YAMLError


# --- [TYPES] ----------------------------------------------------------------------------

type Reviewer = Literal["coderabbit", "greptile", "macroscope"]
type Severity = Literal["critical", "major", "minor", "trivial", "info"]
type ScopeKind = Literal["all", "committed", "uncommitted", "base", "base-commit", "union"]
type Phase = Literal["launched", "reviewing", "completed", "failed", "refused", "stalled", "timed-out", "killed"]
type RunKind = Literal["engine", "gather"]
type Provenance = Literal["relitigation", "refuted_remint", "new_work", "late_discovery", ""]
type Balance = Literal["count", "loc"]
type Weigh = Callable[[Finding], float]
type FaultSignature = Literal[
    "oversized",
    "billing",
    "not-indexed",
    "auth-failed",
    "base-unresolvable",
    "rate-limited",
    "stale-binary",
    "tty-required",
    "network",
    "engine-error",
    "empty-diff",
    "no-start",
    "deadline",
    "died",
]
type FaultCode = Literal[
    "not-a-repo",
    "command-failed",
    "spawn-failed",
    "bad-scope",
    "bad-flag",
    "unsupported-scope",
    "unsupported-focus",
    "live-run",
    "ambiguous",
    "no-base",
    "no-process",
    "no-round",
    "not-completed",
    "unreadable",
    "unwritable",
    "malformed",
    "bad-matcher",
    "empty-class",
    "no-matchers",
    "unknown-key",
    "duplicate-class",
    "dedup-collapse",
    "no-findings",
    "no-lanes",
    "bad-lane",
    "no-report",
    "store-missing",
    "no-payload",
    "already-sliced",
    "already-closed",
    "routing-undrained",
]

# --- [CONSTANTS] ------------------------------------------------------------------------

CLAIM_STEM: Final = 120
DEDUP_GUARD_FLOOR: Final = 8
DEDUP_GUARD_SHARE: Final = 0.5
DIGEST_FOLDS: Final = 8
DIGEST_TOP: Final = 3
HEADLINE: Final = 160
JSON_SCAN_CAP: Final = 64
LANE_ALPHABET: Final = string.ascii_lowercase
LANE_LOAD: Final = 12  # findings per lane the auto cut targets when --lanes is omitted
LANES_CAP: Final = 14  # operational lane ceiling; LANE_ALPHABET carries the structural headroom above it
PROSE_ROOTS: Final[frozenset[str]] = frozenset({".claude", "docs"})
PROSE_SUFFIXES: Final[frozenset[str]] = frozenset({".md", ".mdx", ".markdown"})
KILL_ESCALATE_S: Final = 3.0
KILL_TICK_S: Final = 0.2
LIVENESS_NOTE_S: Final = 60.0
POLL_S: Final = 5.0
STORE_SLACK_S: Final = 120.0
WORKTREE_ERA_S: Final = 5.0
EXIT_MARK: Final = "__rail_exit="
FEED_NAME: Final = "harvest-feed.md"
FINDINGS_NAME: Final = "findings.json"
FOCUS_NAME: Final = "focus.md"
KILLED_NAME: Final = "killed.json"
LEDGER_NAME: Final = "rounds.jsonl"
LOG_NAME: Final = "stream.log"
PROPOSALS_DIR: Final = "memory-proposals"
PROVENANCE_NAME: Final = "provenance.json"
RUN_NAME: Final = "run.json"
SURFACE_LEDGER_NAME: Final = "surface-ledger.json"
WORKTREE_NEEDLE: Final = "macroscope-review-"
WORKTREE_BRANCH: Final = "macroscope/review-"
SIG_TERM: Final[int] = int(signal.SIGTERM)
SIG_KILL: Final[int] = int(getattr(signal, "SIGKILL", 9))
KILLPG: Final[Callable[[int, int], None]] = getattr(os, "killpg", os.kill)
CR_BASE_REMEDY: Final = "Pass one explicitly with --base <branch>, or persist it with 'git config coderabbit.baseBranch <branch>'"
STATE_DIR: Final = Path(".cache/review")
CR_STORE: Final = Path.home() / ".coderabbit" / "reviews"
GREPTILE_LEDGER: Final = Path.home() / ".greptile" / "reviews.json"
SELF: Final = Path(__file__).resolve()
# REVIEW_RAIL_BUNDLE relocates every bundle-owned data surface (registry, prompt templates) so the rail runs from any copy of this one file.
BUNDLE: Final = Path(os.environ.get("REVIEW_RAIL_BUNDLE", "") or SELF.parent.parent).resolve()
REGISTRY_PATH: Final = BUNDLE / "templates" / "refuted-classes.yaml"
CODEX_SESSIONS: Final = Path.home() / ".codex" / "sessions"
PROMPT_TEMPLATES: Final[tuple[str, ...]] = ("fix.md", "close.md", "harvest.md")
AGENT_DEFINITION: Final = ".claude/agents/reviewer-harvest.md"
PROMPT_PRINT_WIDTH: Final = 12
SPAWN_TOOL: Final = "spawn_agent"
WALL_OUTLIER_FACTOR: Final = 2.0  # a lane is a wall-time outlier above this multiple of the lane median
CR_META_NAMES: Final = frozenset({"git.json", "internalState.json", "diff.json", "incrementalDiff.json"})
GT_ORACLE_FILES: Final[tuple[str, ...]] = (".greptile/config.json", ".greptile/rules.md")
MS_HOME: Final = ".macroscope"
ROSTER_KEYS: Final = ("members", "roster", "symbols")
SEVERITIES: Final[tuple[Severity, ...]] = ("critical", "major", "minor", "trivial", "info")
RANK: Final[Mapping[Severity, int]] = MappingProxyType({level: rank for rank, level in enumerate(SEVERITIES)})
TERMINAL: Final[frozenset[Phase]] = frozenset({"completed", "failed", "refused", "stalled", "timed-out", "killed"})
REFUSAL_SIGNATURES: Final[frozenset[FaultSignature]] = frozenset({"oversized"})
ACCEPTED_VERDICTS: Final[frozenset[str]] = frozenset({"fixed", "upgraded", "already_resolved"})
NOVEL_PROVENANCE: Final[frozenset[Provenance]] = frozenset({"new_work", "late_discovery"})
# Constant engine boilerplate opening a finding's fix text; a new engine's preamble is one more row. Stripped at mint so fingerprints,
# claim-scoped queries, and class matchers carry finding content only — unstripped, every verify/fix/minimal regex matches all rows.
ENGINE_PREAMBLES: Final[tuple[str, ...]] = (
    "Verify each finding against current code. Fix only still-valid issues, skip the rest with a brief reason, keep changes minimal, and validate.",
)
SEVERITY_ROWS: Final[tuple[tuple[str, Severity], ...]] = (
    ("critical", "critical"),
    ("p0", "critical"),
    ("major", "major"),
    ("high", "major"),
    ("p1", "major"),
    ("medium", "minor"),
    ("minor", "minor"),
    ("p2", "minor"),
    ("low", "trivial"),
    ("trivial", "trivial"),
    ("p3", "trivial"),
    ("info", "info"),
    ("p4", "info"),
)
SEVERITY_MAP: Final[Mapping[str, Severity]] = MappingProxyType(dict(SEVERITY_ROWS))
SCOPE_ROWS: Final[tuple[tuple[str, ScopeKind], ...]] = (
    ("all", "all"),
    ("committed", "committed"),
    ("uncommitted", "uncommitted"),
    ("base", "base"),
    ("base-commit", "base-commit"),
)
SCOPE_KINDS: Final[Mapping[str, ScopeKind]] = MappingProxyType(dict(SCOPE_ROWS))
REF_KINDS: Final[frozenset[ScopeKind]] = frozenset({"base", "base-commit"})
REVIEWER_ALIAS_ROWS: Final[tuple[tuple[str, Reviewer], ...]] = (
    ("coderabbit", "coderabbit"),
    ("cr", "coderabbit"),
    ("greptile", "greptile"),
    ("gt", "greptile"),
    ("macroscope", "macroscope"),
    ("ms", "macroscope"),
)
REVIEWER_ALIASES: Final[Mapping[str, Reviewer]] = MappingProxyType(dict(REVIEWER_ALIAS_ROWS))
REVIEWER_SHORT: Final[Mapping[Reviewer, str]] = MappingProxyType({"coderabbit": "cr", "greptile": "gt", "macroscope": "ms"})
LEVER_ROWS: Final[Mapping[Reviewer, frozenset[str]]] = MappingProxyType({
    "coderabbit": frozenset({"light"}),
    "greptile": frozenset({"resume", "include"}),
    "macroscope": frozenset(),
})
PROVENANCE_VERDICT_ROWS: Final[tuple[tuple[str, Provenance], ...]] = (
    ("fixed", "relitigation"),
    ("upgraded", "relitigation"),
    ("already_resolved", "relitigation"),
    ("pushed-back", "refuted_remint"),
)
PROVENANCE_VERDICTS: Final[Mapping[str, Provenance]] = MappingProxyType(dict(PROVENANCE_VERDICT_ROWS))
ANSI_RE: Final = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
EXIT_LINE_RE: Final = re.compile(rf"^{EXIT_MARK}(\d+)\s*$")
ISSUE_AT_RE: Final = re.compile(r"issue_event\s*=\s*")
STEM_RE: Final = re.compile(r"\W+")

# --- [MODELS] ---------------------------------------------------------------------------


class Scope(msgspec.Struct, frozen=True):
    kind: ScopeKind
    ref: str = ""

    @property
    def line(self) -> str:
        match self.kind:
            case "union":
                return f"union[{self.ref}]"
            case kind:
                return f"{kind}:{self.ref}" if self.ref else str(kind)

    @staticmethod
    def of(text: str, /) -> Result[Scope, Fault]:
        head, _, ref = text.partition(":")
        kind = SCOPE_KINDS.get(head)
        return (
            Ok(Scope(kind=kind, ref=ref))
            if kind is not None and (kind in REF_KINDS) == bool(ref)
            else Error(Fault(code="bad-scope", detail=f"{text!r} is not all|committed|uncommitted|base:<ref>|base-commit:<sha>"))
        )


class Range(msgspec.Struct, frozen=True):
    start: int = 0
    end: int = 0


class Finding(msgspec.Struct, frozen=True):
    # No raw engine payload rides the finding — the receipt's `source` names the store a payload re-reads from; content fields carry the evidence.
    id: str
    fingerprint: str
    reviewer: Reviewer
    file: str
    range: Range
    severity: Severity
    claim: str
    fix_instructions: str
    class_match: str
    corroborators: tuple[Reviewer, ...] = ()
    provenance: Provenance = ""
    anchored: bool = False
    actionable: bool = False


class Run(msgspec.Struct, frozen=True):
    round: int
    kind: RunKind
    reviewer: Reviewer
    scope: Scope
    pid: int
    pgid: int
    started: float
    argv: tuple[str, ...]
    sources: tuple[int, ...] = ()
    focus: str = ""


class Levers(msgspec.Struct, frozen=True):
    light: bool = False
    resume: bool = False
    include: tuple[str, ...] = ()


class KillMark(msgspec.Struct, frozen=True):
    sent: str = ""
    at: float = 0.0


class SurfaceGuard(msgspec.Struct, frozen=True):
    surface: str
    text: str = ""
    path: str = ""


class LaneManifest(msgspec.Struct, frozen=True):
    lane: str
    files: tuple[str, ...]
    count: int
    criticals: int
    suggested_scope_line: str
    brief: str = ""


class LaneSlice(msgspec.Struct, frozen=True):
    manifest: LaneManifest
    settled_rulings: tuple[str, ...]
    findings: tuple[Finding, ...]


class LedgerRow(msgspec.Struct, frozen=True):
    id: str = ""
    file: str = ""
    severity: str = ""
    verdict: str = ""
    note: str = ""
    shape: str = ""  # fixer-stamped capability shape (substitution|collapse|completion); the rollup never infers it from prose


class Improvement(msgspec.Struct, frozen=True):
    page: str = ""
    pattern: str = ""
    what: str = ""
    axis: str = ""


class Refutation(msgspec.Struct, frozen=True):
    claim: str = ""
    evidence: str = ""


class LaneReport(msgspec.Struct, frozen=True):
    ledger: tuple[LedgerRow, ...] = ()
    improvements: tuple[Improvement, ...] = ()
    refuted: tuple[Refutation, ...] = ()
    capability: tuple[msgspec.Raw, ...] = ()
    routing: tuple[msgspec.Raw, ...] = ()
    uncertain: tuple[msgspec.Raw, ...] = ()
    files: tuple[str, ...] = ()  # files the lane actually edited, fixer-reported; the manifest carries the assigned set
    gate_clean: bool | None = None
    model: str = ""
    wall_s: float = 0.0


class CloserReport(msgspec.Struct, frozen=True):
    # Closer intake per templates/close.md: one verdict row per routed demand plus the edited-file roster.
    rows: tuple[LedgerRow, ...] = ()
    files: tuple[str, ...] = ()


class RoutingRow(msgspec.Struct, frozen=True):
    lane: str
    target_file: str
    needed_change: str
    key: str  # "<lane-letter>:<target_file>" — the id spelling closer verdict rows answer with


class RoutingDrain(msgspec.Struct, frozen=True):
    # Oracle: lane-report routing[] rows matched against close-*-report.json verdict rows by key or bare target_file.
    total: int = 0
    drained: int = 0
    deferred: bool = False
    verdicts: dict[str, int] = msgspec.field(default_factory=dict)
    pending: tuple[RoutingRow, ...] = ()


class WallSpread(msgspec.Struct, frozen=True):
    # Oracle: LaneStat.wall_s; an outlier lane exceeds WALL_OUTLIER_FACTOR x median.
    median_s: float = 0.0
    max_s: float = 0.0
    outliers: tuple[str, ...] = ()


class RefutedClass(msgspec.Struct, frozen=True):
    class_id: str
    corpus: str = ""
    matchers: tuple[str, ...] = ()
    refuting_citation: str = ""
    landed_surfaces: tuple[str, ...] = ()
    recurrences: int = 0


class Registry(msgspec.Struct, frozen=True):
    classes: tuple[RefutedClass, ...] = ()


class CrMeta(msgspec.Struct, frozen=True, rename="camel"):
    working_directory: str = ""
    timestamp: float = 0.0


class CrRich(msgspec.Struct, frozen=True, rename="camel"):
    id: str = ""
    severity: str = "info"
    file_name: str = ""
    start_line: int = 0
    end_line: int = 0
    line_range: Range | None = None
    title: str = ""
    comment: str = ""
    codegen_instructions: str = ""


class GtComment(msgspec.Struct, frozen=True, rename="camel"):
    # Declared fields are the consumed set only — undeclared payload regions (hunk, side, evidence) decode tolerantly and cannot abort a harvest.
    id: str = ""
    path: str = ""
    start_line: int = 0
    end_line: int = 0
    severity: str = ""
    body: str = ""
    suggestion: str | None = None


class GreptileRow(msgspec.Struct, frozen=True, rename="camel"):
    run_id: str = ""
    remote_url: str = ""
    head_sha: str = ""
    created_at: str = ""
    status: str = ""
    comment_count: int = 0


class GreptileLedger(msgspec.Struct, frozen=True):
    version: int = 1
    reviews: tuple[GreptileRow, ...] = ()


class MsIssue(msgspec.Struct, frozen=True):
    issue_id: str = ""
    path: str = ""
    line: int = 0
    end_line: int = 0
    severity: str = ""
    body: str = ""


class LaneStat(msgspec.Struct, frozen=True):
    lane: str
    model: str
    findings: int
    verdicts: dict[str, int]
    missing: tuple[str, ...]
    phantom: tuple[str, ...]
    wall_s: float
    report_valid: bool
    gate_clean: bool | None = None
    fault: str = ""
    files: tuple[str, ...] = ()  # fixer-reported touched files
    strays: tuple[str, ...] = ()  # reported files outside the lane manifest — the cross-lane-write signal
    shapes: dict[str, int] = msgspec.field(default_factory=dict)  # fixer-stamped shape histogram; blank stamps count as "unstamped"


class LaneGrade(msgspec.Struct, frozen=True):
    depth_of_fix: float
    scope_clean: float
    refute_cited: float
    gate_clean: float
    bijective: float


class RoundRow(msgspec.Struct, frozen=True):
    round: int
    reviewer: Reviewer
    reviewers: tuple[Reviewer, ...]
    scope: str
    counts_by_severity: dict[str, int]
    total: int
    lanes: tuple[LaneStat, ...]
    recurred_classes: tuple[str, ...]
    new_classes: int
    routed: int
    capability_rows: int
    provenance_by_kind: dict[str, int]
    corroboration_histogram: dict[str, int]
    commit: str
    at: float
    focus: str = ""
    fp_share: float = 0.0
    relitigation_share: float = 0.0
    novel_quality: float = 0.0
    hunt_axis_fire: dict[str, int] = msgspec.field(default_factory=dict)
    by_model: dict[str, dict[str, int]] = msgspec.field(default_factory=dict)
    grades: dict[str, LaneGrade] = msgspec.field(default_factory=dict)
    shape_fire: dict[str, int] = msgspec.field(default_factory=dict)  # fixer-stamped LedgerRow.shape counts, stamped rows only
    routing: RoutingDrain = msgspec.field(default_factory=RoutingDrain)
    wall_spread: WallSpread = msgspec.field(default_factory=WallSpread)
    prompts: dict[str, str] = msgspec.field(default_factory=dict)  # content hashes of dispatch templates + agent definition


class Delta(msgspec.Struct, frozen=True):
    prior_round: int
    total_delta: int
    by_severity: dict[str, int]
    recurred_still: tuple[str, ...]


class LaunchReceipt(msgspec.Struct, frozen=True):
    round: int
    reviewer: Reviewer
    scope: str
    pid: int
    pgid: int
    argv: tuple[str, ...]
    focus: str
    watch_cmd: str
    log: str
    run: str


class StatusReceipt(msgspec.Struct, frozen=True):
    round: int
    reviewer: Reviewer
    scope: str
    phase: Phase
    elapsed_s: float
    last_pulse_age_s: float
    findings_seen: int | None
    detail: str
    signature: FaultSignature | None
    remedy: str
    exit_code: int | None
    alive: bool
    budget_s: float
    keepalive: bool
    log: str


class LiveStatus(msgspec.Struct, frozen=True):
    rounds: tuple[StatusReceipt, ...]
    all_terminal: bool
    live: int


class KillReceipt(msgspec.Struct, frozen=True):
    round: int
    reviewer: Reviewer
    signalled: str
    pgid: int
    survivors: tuple[int, ...]
    worktrees_removed: tuple[str, ...]
    phase: Phase


class FindingsReceipt(msgspec.Struct, frozen=True):
    round: int
    reviewer: Reviewer
    admitted: int
    total: int
    deduped: int
    collapse_ratio: float
    cross_deduped: int
    classified: int
    counts_by_severity: dict[str, int]
    provenance: dict[str, int]
    scope_misfire: bool
    source: str
    path: str
    prior_round: int | None = None


class FindingLine(msgspec.Struct, frozen=True):
    id: str
    severity: Severity
    file: str
    range: Range
    claim: str


class ClassFire(msgspec.Struct, frozen=True):
    class_id: str
    count: int
    ids: tuple[str, ...]


class FolderCut(msgspec.Struct, frozen=True):
    folder: str
    count: int
    files: int
    criticals: int


class Digest(msgspec.Struct, frozen=True):
    round: int
    reviewer: Reviewer
    scope: str
    total: int
    counts_by_severity: dict[str, int]
    anchored_share: float
    actionable_share: float
    corroborated: int
    provenance: dict[str, int]
    classes: tuple[ClassFire, ...]
    folders: tuple[FolderCut, ...]
    top: dict[str, tuple[FindingLine, ...]]


class QueryReceipt(msgspec.Struct, frozen=True):
    round: int
    matched: int
    total: int
    filters: dict[str, str]
    rows: tuple[FindingLine, ...]


class GatherReceipt(msgspec.Struct, frozen=True):
    round: int
    sources: tuple[int, ...]
    total: int
    corroborated: int
    counts_by_severity: dict[str, int]
    path: str


class SliceReceipt(msgspec.Struct, frozen=True):
    round: int
    lanes: tuple[LaneManifest, ...]
    stamped: int
    settled_rulings: int
    cleared: int


class PackageTier(msgspec.Struct, frozen=True):
    root: str
    api: str = ""  # blank when the package ships no .api overlay


class LaneFill(msgspec.Struct, frozen=True):
    lane: str
    files: tuple[str, ...]
    packages: tuple[PackageTier, ...] = ()
    substrate: tuple[str, ...] = ()  # language-root .api tiers beside the package overlays
    doctrine: tuple[str, ...] = ()  # docs/stacks/<language> roots owning the lane's files
    unplaced: tuple[str, ...] = ()  # files outside every tiered root — no package, no .api, no stack doctrine


class FillReceipt(msgspec.Struct, frozen=True):
    round: int
    lanes: tuple[LaneFill, ...]


class EventHead(msgspec.Struct, frozen=True):
    type: str = ""
    thread_id: str = ""


class RolloutCall(msgspec.Struct, frozen=True):
    type: str = ""
    name: str = ""
    arguments: str = ""


class RolloutLine(msgspec.Struct, frozen=True):
    type: str = ""
    payload: RolloutCall | None = None


class SpawnRow(msgspec.Struct, frozen=True):
    lane: str
    session: str = ""
    rollout: str = ""
    spawns: int = 0
    agents: tuple[str, ...] = ()
    fault: str = ""  # no-events | no-session | no-rollout — a per-lane fact, never a refusal


class SpawnReceipt(msgspec.Struct, frozen=True):
    round: int
    oracle: str  # the rollout store queried; the per-lane events stream false-negatives spawns and is never consulted
    lanes: tuple[SpawnRow, ...]


class ReconcileReceipt(msgspec.Struct, frozen=True):
    round: int
    lanes: tuple[LaneStat, ...]
    bijective: bool  # proves id bijection alone; routing states the closer drain
    routing: RoutingDrain = msgspec.field(default_factory=RoutingDrain)


class HarvestReceipt(msgspec.Struct, frozen=True):
    round: int
    reports: int
    recurred: tuple[str, ...]
    new_refuted: int
    improvements: int
    capability: int
    routed: int
    proposals: tuple[str, ...]
    path: str


class RoundReceipt(msgspec.Struct, frozen=True):
    row: RoundRow
    delta: Delta | None


class RowVerdict(msgspec.Struct, frozen=True):
    at: int
    class_id: str
    faults: tuple["Fault", ...] = ()


class RegistryCheckReceipt(msgspec.Struct, frozen=True):
    path: str
    standing: int
    rows: int
    clean: int
    faulted: tuple[RowVerdict, ...]


class RegistryApplyReceipt(msgspec.Struct, frozen=True):
    path: str
    appended: tuple[str, ...]
    standing: int


class VerifyReceipt(msgspec.Struct, frozen=True):
    rule: str
    path: str
    effective: bool
    matched: str
    source: str


class SelftestReceipt(msgspec.Struct, frozen=True):
    proofs: int
    passed: int
    failures: tuple[str, ...]


# --- [ERRORS] ---------------------------------------------------------------------------


class Fault(msgspec.Struct, frozen=True):
    code: FaultCode
    detail: str = ""


# --- [SERVICES] -------------------------------------------------------------------------

APP: Final = App(
    help=(
        "One verb rail over CodeRabbit, Greptile, and Macroscope: launch, status, kill, findings, slice, reconcile, lanes, harvest, gather,"
        " round, registry, verify, selftest."
    )
)
ENCODER: Final = msgspec.json.Encoder()
RAW_JSON: Final = json.JSONDecoder()
YAML_SAFE: Final = YAML(typ="safe")
YAML_RT: Final = YAML(typ="rt")  # round-trip policy pinned to the registry file's own layout, so an apply rewrites only what it appends
YAML_RT.preserve_quotes = True
YAML_RT.width = 4096
YAML_RT.indent(mapping=2, sequence=4, offset=2)

# --- [BOUNDARIES] -----------------------------------------------------------------------


def emitted(payload: object, /) -> int:
    print(ENCODER.encode(payload).decode())
    return 0


def refused(fault: Fault, /) -> int:
    emitted(fault)
    return 1


def delivered(outcome: Result[object, Fault], /, *, clean: Callable[[object], bool] = lambda _receipt: True) -> int:
    def landed(receipt: object, /) -> int:
        emitted(receipt)
        return 0 if clean(receipt) else 1

    return outcome.map(landed).default_with(refused)


def read_bytes(path: Path, /) -> Result[bytes, Fault]:
    return catch(exception=OSError)(path.read_bytes)().map_error(lambda unreachable: Fault(code="unreadable", detail=f"{path}: {unreachable}"))


def written(path: Path, payload: bytes, /, *, append: bool = False) -> Result[Path, Fault]:
    def sunk() -> Path:
        if append:
            with path.open("ab") as sink:
                sink.write(payload)
            return path
        staging = path.with_name(f"{path.name}.tmp")  # whole-file writes stage then replace, so a torn write never truncates the target
        staging.write_bytes(payload)
        staging.replace(path)
        return path

    return catch(exception=OSError)(sunk)().map_error(lambda unwritable: Fault(code="unwritable", detail=f"{path}: {unwritable}"))


def unlinked(paths: tuple[Path, ...], /) -> Result[int, Fault]:
    def gone(path: Path, /) -> Result[Path, Fault]:
        return catch(exception=OSError)(path.unlink)().map(lambda _n: path).map_error(lambda held: Fault(code="unwritable", detail=f"{path}: {held}"))

    return traverse(gone, Block.of_seq(paths)).map(len)


def decoded[T](payload: bytes, shape: type[T], origin: str, /) -> Result[T, Fault]:
    try:
        return Ok(msgspec.json.decode(payload, type=shape, strict=False))
    except msgspec.ValidationError as drift:
        return Error(Fault(code="malformed", detail=f"{origin}: {drift}"))
    except msgspec.DecodeError as garbled:
        return Error(Fault(code="malformed", detail=f"{origin}: {garbled}"))


def json_value(payload: bytes, origin: str, /) -> Result[object, Fault]:
    def parsed() -> object:
        value: object = msgspec.json.decode(payload)
        return value

    return catch(exception=msgspec.DecodeError)(parsed)().map_error(lambda garbled: Fault(code="malformed", detail=f"{origin}: {garbled}"))


def json_document(text: str, at: int, /) -> Option[tuple[object, int]]:
    return catch(exception=ValueError)(RAW_JSON.raw_decode)(text, at).to_option()


def shaped[T](path: Path, shape: type[T], /) -> Option[T]:
    return read_bytes(path).bind(lambda payload: decoded(payload, shape, str(path))).to_option()


def null_scrubbed(value: object, /) -> object:
    match value:
        case dict() as mapping:
            return {key: null_scrubbed(item) for key, item in mapping.items() if item is not None}
        case list() as items:
            return [null_scrubbed(item) for item in items]
        case _:
            return value


def report_decoded[T](payload: bytes, shape: type[T], origin: str, /) -> Result[T, Fault]:
    # Reports are agent-written: the contract spells null for empty collections, so nulls scrub to absent keys before the strict tuple decode.
    return json_value(payload, origin).bind(
        lambda value: catch(exception=msgspec.ValidationError)(
            lambda: msgspec.json.decode(msgspec.json.encode(null_scrubbed(value)), type=shape, strict=False)
        )().map_error(lambda drift: Fault(code="malformed", detail=f"{origin}: {drift}"))
    )


def report_shaped[T](path: Path, shape: type[T], /) -> Result[T, Fault]:
    return read_bytes(path).bind(lambda payload: report_decoded(payload, shape, str(path)))


def yaml_loaded(path: Path, /, *, codec: YAML = YAML_SAFE) -> Result[object, Fault]:
    try:
        parsed: object = codec.load(path.read_text(encoding="utf-8"))
    except OSError as unreachable_file:
        return Error(Fault(code="unreadable", detail=f"{path}: {unreachable_file}"))
    except YAMLError as garbled:
        return Error(Fault(code="malformed", detail=f"{path}: {garbled}"))
    return Ok(parsed)


def sh(argv: tuple[str, ...], /, *, cwd: Path | None = None) -> Result[str, Fault]:
    def ran() -> subprocess.CompletedProcess[str]:
        return subprocess.run(argv, capture_output=True, text=True, check=False, cwd=None if cwd is None else str(cwd))

    return (
        catch(exception=OSError)(ran)()
        .map_error(lambda unrunnable: Fault(code="command-failed", detail=f"{argv[0]}: {unrunnable}"))
        .bind(
            lambda probe: (
                Ok(probe.stdout.strip())
                if probe.returncode == 0
                else Error(Fault(code="command-failed", detail=f"{argv[0]}: {probe.stderr.strip() or f'exit={probe.returncode}'}"))
            )
        )
    )


def spawned(argv: tuple[str, ...], log: Path, cwd: Path, /) -> Result[int, Fault]:
    script = f'{shlex.join(argv)}; printf "\\n{EXIT_MARK}%s\\n" "$?"'

    def forked() -> int:
        with log.open("ab") as sink:
            child = subprocess.Popen(
                ("/bin/sh", "-c", script), stdin=subprocess.DEVNULL, stdout=sink, stderr=subprocess.STDOUT, cwd=str(cwd), start_new_session=True
            )
        return child.pid

    return catch(exception=OSError)(forked)().map_error(lambda unspawnable: Fault(code="spawn-failed", detail=f"{argv[0]}: {unspawnable}"))


def alive(pid: int, /) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def breathing(pid: int, needle: str, /) -> bool:
    return alive(pid) and sh(("ps", "-p", str(pid), "-o", "command=")).map(lambda command: needle in command).default_with(lambda _f: False)


def repo_root(directory: Path | None, /) -> Result[Path, Fault]:
    anchor = directory or Path.cwd()
    return (
        sh(("git", "-C", str(anchor), "rev-parse", "--show-toplevel"))
        .map(Path)
        .map_error(lambda fault: Fault(code="not-a-repo", detail=f"{anchor}: {fault.detail}"))
    )


def registry_loaded() -> Result[Registry, Fault]:
    if not REGISTRY_PATH.is_file():
        return Ok(Registry())

    def converted(parsed: object, /) -> Result[Registry, Fault]:
        try:
            return Ok(msgspec.convert(parsed or {}, type=Registry, strict=False))
        except msgspec.ValidationError as drift:
            return Error(Fault(code="malformed", detail=f"{REGISTRY_PATH}: {drift}"))

    return yaml_loaded(REGISTRY_PATH).bind(converted)


# --- [OPERATIONS] -----------------------------------------------------------------------

# --- [ROUND_STORE]


@dataclass(frozen=True, slots=True, kw_only=True)
class Context:
    repo: Path
    round_dir: Path
    run: Run


def round_number(round_dir: Path, /) -> int:
    tail = round_dir.name.rpartition("-")[2]
    return int(tail) if tail.isdigit() else 0


def round_dirs(repo: Path, /) -> tuple[Path, ...]:
    return tuple(sorted((repo / STATE_DIR).glob("round-*"), key=round_number))


def run_loaded(round_dir: Path, /) -> Result[Run, Fault]:
    return read_bytes(round_dir / RUN_NAME).bind(lambda payload: decoded(payload, Run, str(round_dir / RUN_NAME)))


def round_minted(repo: Path, /) -> Result[tuple[int, Path], Fault]:
    def attempted(retries: int, /) -> Result[tuple[int, Path], Fault]:
        rounds = round_dirs(repo)
        number = (round_number(rounds[-1]) if rounds else 0) + 1
        round_dir = repo / STATE_DIR / f"round-{number:03d}"
        try:
            round_dir.mkdir(parents=True)
        except FileExistsError:  # mkdir is the atomic arbiter; a concurrent launch took this number, so re-derive the next
            return attempted(retries - 1) if retries else Error(Fault(code="unwritable", detail=f"{round_dir}: numbering contention"))
        except OSError as unmakeable:
            return Error(Fault(code="unwritable", detail=f"{round_dir}: {unmakeable}"))
        return Ok((number, round_dir))

    return attempted(3)


def round_context(repo: Path, round_no: int | None, /) -> Result[Context, Fault]:
    rounds = round_dirs(repo)
    found = next((d for d in rounds if round_number(d) == round_no), None) if round_no is not None else (rounds[-1] if rounds else None)
    if found is None:
        wanted = f"round {round_no}" if round_no is not None else "any round-*"
        return Error(Fault(code="no-round", detail=f"{wanted} not under {repo / STATE_DIR}; launch first"))
    return run_loaded(found).map(lambda run: Context(repo=repo, round_dir=found, run=run))


def context_resolved(directory: Path | None, round_no: int | None, /) -> Result[Context, Fault]:
    return repo_root(directory).bind(lambda repo: round_context(repo, round_no))


def contexts_of(repo: Path, /) -> tuple[Context, ...]:
    return tuple(Block.of_seq(round_dirs(repo)).choose(lambda d: run_loaded(d).to_option().map(lambda run: Context(repo=repo, round_dir=d, run=run))))


def live_pairs(repo: Path, /) -> tuple[tuple[Context, StatusReceipt], ...]:
    watched = tuple((context, observed(context)) for context in contexts_of(repo))
    return tuple(pair for pair in watched if pair[1].phase not in TERMINAL)


def reviewer_resolved(spec: str, /) -> Result[Reviewer, Fault]:
    held = REVIEWER_ALIASES.get(spec.strip().lower())
    return (
        Ok(held) if held is not None else Error(Fault(code="bad-flag", detail=f"{spec!r} is not coderabbit|greptile|macroscope (aliases cr|gt|ms)"))
    )


def latest_of(repo: Path, reviewer: Reviewer, /) -> Result[Context, Fault]:
    owned = tuple(context for context in contexts_of(repo) if context.run.kind == "engine" and context.run.reviewer == reviewer)
    if owned:
        return Ok(owned[-1])
    return Error(Fault(code="no-round", detail=f"no {reviewer} round under {repo / STATE_DIR}"))


def rounds_read(repo: Path, /) -> tuple[RoundRow, ...]:
    lines = read_bytes(repo / STATE_DIR / LEDGER_NAME).map(bytes.splitlines).default_with(lambda _f: [])
    return tuple(Block.of_seq(lines).choose(lambda line: decoded(line, RoundRow, LEDGER_NAME).to_option() if line.strip() else Nothing))


# --- [PROBE]


@dataclass(frozen=True, slots=True, kw_only=True)
class FaultSig:
    pattern: re.Pattern[str]
    signature: FaultSignature
    remedy: str
    nonzero_only: bool = True


@dataclass(frozen=True, slots=True, kw_only=True)
class Markers:
    start_grace_s: float
    stall_grace_s: float
    deadline_s: float
    keepalive: bool = False
    done: Option[re.Pattern[str]] = Nothing
    pulse: Option[re.Pattern[str]] = Nothing
    tick: Option[re.Pattern[str]] = Nothing
    signatures: tuple[FaultSig, ...] = ()


@dataclass(frozen=True, slots=True, kw_only=True)
class StreamProbe:
    remainder: str = ""
    done: bool = False
    fault: Option[tuple[FaultSig, str]] = Nothing
    pulses: int = 0
    ticks: int = 0
    exited: Option[int] = Nothing
    tail: str = ""


@dataclass(frozen=True, slots=True, kw_only=True)
class Liveness:
    elapsed: float
    pulse_age: float
    alive: bool


def plain(line: str, /) -> str:
    return ANSI_RE.sub("", line).strip()[:HEADLINE]


def marker_hit(pattern: Option[re.Pattern[str]], line: str, /) -> bool:
    return pattern.filter(lambda held: held.search(line) is not None).is_some()


def sig_caught(prior: Option[tuple[FaultSig, str]], rows: tuple[FaultSig, ...], line: str, /) -> Option[tuple[FaultSig, str]]:
    if prior.is_some():
        return prior
    return next((Some((row, plain(line))) for row in rows if row.pattern.search(line)), Nothing)


def scanned(probe: StreamProbe, chunk: str, markers: Markers, /) -> StreamProbe:
    lines = (probe.remainder + chunk).split("\n")

    def stepped(acc: StreamProbe, raw_line: str, /) -> StreamProbe:
        line = ANSI_RE.sub("", raw_line)  # markers match undecorated text, the same boundary strip every harvest leg applies
        exit_hit = EXIT_LINE_RE.match(line)
        bare = line.strip()
        return evolved(
            acc,
            done=acc.done or marker_hit(markers.done, line),
            fault=sig_caught(acc.fault, markers.signatures, line),
            pulses=acc.pulses + int(marker_hit(markers.pulse, line)),
            ticks=acc.ticks + int(marker_hit(markers.tick, line)),
            exited=Some(int(exit_hit.group(1))) if exit_hit else acc.exited,
            tail=plain(line) if bare and not bare.startswith(EXIT_MARK) else acc.tail,
        )

    folded: StreamProbe = reduce(stepped, lines[:-1], probe)
    return evolved(folded, remainder=lines[-1])


def phased(probe: StreamProbe, markers: Markers, live: Liveness, /) -> tuple[Phase, str, FaultSignature | None, str]:
    exit_zero = probe.exited.filter(lambda code: code == 0).is_some()
    exit_nonzero = probe.exited.filter(lambda code: code != 0).is_some()

    def promoted(hit: tuple[FaultSig, str], /) -> tuple[bool, Phase, str, FaultSignature | None, str]:
        row, line = hit
        phase: Phase = "completed" if row.signature == "empty-diff" else "refused" if row.signature in REFUSAL_SIGNATURES else "failed"
        return (True, phase, line, row.signature, row.remedy)

    match probe.fault.filter(lambda hit: (not hit[0].nonzero_only) or exit_nonzero):
        case Option(tag="some", some=hit):
            head: tuple[tuple[bool, Phase, str, FaultSignature | None, str], ...] = (promoted(hit),)
        case _:
            head = ()
    rules: tuple[tuple[bool, Phase, str, FaultSignature | None, str], ...] = (
        *head,
        (probe.done, "completed", "", None, ""),
        (exit_zero, "failed", "exited 0 without the engine's terminal marker", None, ""),
        (exit_nonzero, "failed", probe.tail or f"exit={probe.exited.default_value(-1)}", None, ""),
        (not live.alive, "failed", "process died without a terminal marker", "died", "inspect the log tail; relaunch"),
        (
            live.elapsed > markers.deadline_s,
            "timed-out",
            f"exceeded the {markers.deadline_s:.0f}s engine deadline",
            "deadline",
            "kill the round; relaunch, or --resume where the engine offers it",
        ),
        (
            markers.keepalive and probe.pulses == 0 and live.elapsed > markers.start_grace_s,
            "failed",
            f"no pulse within the {markers.start_grace_s:.0f}s start grace",
            "no-start",
            "inspect the log head; relaunch",
        ),
        (
            markers.keepalive and live.pulse_age > markers.stall_grace_s,
            "stalled",
            f"alive with no output for {live.pulse_age:.0f}s (grace {markers.stall_grace_s:.0f}s)",
            None,
            "kill the round; relaunch",
        ),
        (probe.pulses > 0 or probe.ticks > 0 or (not markers.keepalive and live.alive), "reviewing", "", None, ""),
    )
    return next(((phase, detail, sig, remedy) for hit, phase, detail, sig, remedy in rules if hit), ("launched", "", None, ""))


def status_of(context: Context, probe: StreamProbe, broken: Option[str], /) -> StatusReceipt:
    markers = ADAPTERS[context.run.reviewer].markers
    log = context.round_dir / LOG_NAME
    now = time.time()
    mtime = catch(exception=OSError)(log.stat)().to_option().map(lambda held: held.st_mtime)
    live = Liveness(
        elapsed=max(now - context.run.started, 0.0),
        pulse_age=max(now - mtime.default_value(context.run.started), 0.0),
        alive=breathing(context.run.pid, context.run.argv[0]) if context.run.argv else False,
    )

    def broken_status(cause: str, /) -> tuple[Phase, str, FaultSignature | None, str]:
        return "failed", cause, None, ""

    phase, detail, sig, remedy = broken.map(broken_status).default_with(lambda: phased(probe, markers, live))
    match probe.exited:
        case Option(tag="some", some=code):
            exit_code: int | None = code
        case _:
            exit_code = None
    settled_at = mtime.map(lambda held: max(held - context.run.started, 0.0)).default_value(live.elapsed)
    terminal = phase in TERMINAL
    clamped = min(live.elapsed, settled_at) if terminal else live.elapsed  # one clock: elapsed, budget, and pulse age agree on terminal receipts
    return StatusReceipt(
        round=context.run.round,
        reviewer=context.run.reviewer,
        scope=context.run.scope.line,
        phase=phase,
        elapsed_s=round(clamped, 1),
        last_pulse_age_s=0.0 if terminal else round(live.pulse_age, 1),
        findings_seen=probe.ticks if markers.tick.is_some() else None,
        detail=detail,
        signature=sig,
        remedy=remedy,
        exit_code=exit_code,
        alive=live.alive,
        budget_s=round(max(markers.deadline_s - clamped, 0.0), 1),
        keepalive=markers.keepalive,
        log=str(log),
    )


def settled_receipt(context: Context, phase: Phase, detail: str, elapsed: float, /) -> StatusReceipt:
    markers = ADAPTERS[context.run.reviewer].markers
    return StatusReceipt(
        round=context.run.round,
        reviewer=context.run.reviewer,
        scope=context.run.scope.line,
        phase=phase,
        elapsed_s=round(max(elapsed, 0.0), 1),
        last_pulse_age_s=0.0,
        findings_seen=0,
        detail=detail,
        signature=None,
        remedy="",
        exit_code=None,
        alive=False,
        budget_s=0.0,
        keepalive=markers.keepalive,
        log=str(context.round_dir / LOG_NAME),
    )


def sentineled(context: Context, /) -> Option[StatusReceipt]:
    if context.run.kind == "gather":
        return Some(settled_receipt(context, "completed", "gather round (no engine process)", 0.0))
    return shaped(context.round_dir / KILLED_NAME, KillMark).map(
        lambda mark: settled_receipt(context, "killed", f"killed by rail ({mark.sent})", mark.at - context.run.started)
    )


def observed(context: Context, /) -> StatusReceipt:
    def scanned_status() -> StatusReceipt:
        markers = ADAPTERS[context.run.reviewer].markers
        log = context.round_dir / LOG_NAME
        payload = read_bytes(log)
        text = payload.map(lambda raw: raw.decode(errors="replace")).default_with(lambda _f: "")
        broken = payload.swap().to_option().bind(lambda fault: Some(fault.detail) if log.is_file() else Nothing)
        return status_of(context, scanned(StreamProbe(), text + "\n", markers), broken)

    first = sentineled(context).default_with(scanned_status)
    # A read-then-probe race can see the process gone before its exit marker flushed; one fresh re-read decides, so a completed run never grades died.
    return first if first.signature != "died" else scanned_status()


def log_chunk(log: Path, offset: int, /) -> tuple[str, int]:
    def sliced_read() -> tuple[str, int]:
        with log.open("rb") as source:
            source.seek(offset)
            payload = source.read()
        return payload.decode(errors="replace"), offset + len(payload)

    return catch(exception=OSError)(sliced_read)().default_with(lambda _f: ("", offset))


def stepped_status(context: Context, probe: StreamProbe, offset: int, /) -> tuple[StatusReceipt, StreamProbe, int]:
    match sentineled(context):
        case Option(tag="some", some=receipt):
            return receipt, probe, offset
        case _:
            chunk, moved = log_chunk(context.round_dir / LOG_NAME, offset)
            grown = scanned(probe, chunk, ADAPTERS[context.run.reviewer].markers)
            first = status_of(context, grown, Nothing)
            if first.signature != "died":
                return first, grown, moved
            tail, settled = log_chunk(context.round_dir / LOG_NAME, moved)  # confirm death against a fresh tail before the terminal verdict lands
            regrown = scanned(grown, tail, ADAPTERS[context.run.reviewer].markers)
            return status_of(context, regrown, Nothing), regrown, settled


def liveness_line(receipt: StatusReceipt, /) -> str:
    tail = (
        f"heartbeat {receipt.last_pulse_age_s:.0f}s ago"
        if receipt.keepalive
        else f"quiet {receipt.last_pulse_age_s:.0f}s — blind engine, silence normal until the terminal marker"
    )
    return (
        f"[{receipt.phase.upper()}] round={receipt.round} {receipt.reviewer} elapsed={receipt.elapsed_s:.0f}s "
        f"alive={'yes' if receipt.alive else 'no'} budget={receipt.budget_s:.0f}s findings={receipt.findings_seen}  {tail}"
    )


# --- [PROCESS_CONTROL]


def worktree_rows(repo: Path, /) -> tuple[tuple[Path, str], ...]:
    text = sh(("git", "-C", str(repo), "worktree", "list", "--porcelain")).default_with(lambda _f: "")

    def parsed(block: str, /) -> Option[tuple[Path, str]]:
        fields = dict(line.split(" ", 1) for line in block.splitlines() if " " in line)
        held = fields.get("worktree", "")
        return Some((Path(held), fields.get("branch", "").removeprefix("refs/heads/"))) if held else Nothing

    return tuple(Block.of_seq(text.split("\n\n")).choose(parsed))


def swept_worktrees(repo: Path, since: float | None, /) -> tuple[str, ...]:
    git = ("git", "-C", str(repo))

    def aged(path: Path, /) -> bool:
        return since is None or catch(exception=OSError)(path.stat)().map(lambda held: held.st_mtime >= since).default_with(lambda _f: True)

    victims = tuple((path, branch) for path, branch in worktree_rows(repo) if WORKTREE_NEEDLE in path.name and aged(path))
    for path, _branch in victims:
        sh((*git, "worktree", "remove", "-f", str(path)))
    if victims:
        sh((*git, "worktree", "prune"))
        for _path, branch in victims:
            if branch.startswith(WORKTREE_BRANCH):
                sh((*git, "branch", "-D", branch))
    if since is None:
        live = {branch for _path, branch in worktree_rows(repo) if branch}  # a branch still backing a live worktree is never reaped
        leftovers = sh((*git, "branch", "--list", f"{WORKTREE_BRANCH}*", "--format=%(refname:short)")).map(str.splitlines).default_with(lambda _f: [])
        for branch in leftovers:
            if branch.strip() and branch.strip() not in live:
                sh((*git, "branch", "-D", branch.strip()))
    return tuple(str(path) for path, _branch in victims)


def survivors_swept(repo: Path, needle: str, /) -> tuple[int, ...]:
    anchor = Path(os.path.realpath(repo))
    own = {os.getpid(), os.getppid()}
    listed = sh(("pgrep", "-f", needle)).map(str.splitlines).default_with(lambda _f: [])
    pids = tuple(int(line) for line in listed if line.strip().isdigit() and int(line) not in own)

    def engine_led(pid: int, /) -> bool:
        # Only a process whose argv[0] IS the engine binary is a survivor; a shell or rail invocation merely naming it is a bystander.
        command = sh(("ps", "-p", str(pid), "-o", "command=")).default_with(lambda _f: "")
        head = command.split(maxsplit=1)[0] if command else ""
        return Path(head).name == needle

    def anchored(pid: int, /) -> bool:
        cwd = sh(("lsof", "-a", "-p", str(pid), "-d", "cwd", "-Fn")).default_with(lambda _f: "")
        return any(line.startswith("n") and Path(os.path.realpath(line[1:])) == anchor for line in cwd.splitlines())

    doomed = tuple(pid for pid in pids if engine_led(pid) and anchored(pid))
    for pid in doomed:
        if breathing(pid, needle):  # re-verify identity at the last instant, closing most of the pid-reuse window
            catch(exception=ProcessLookupError)(os.kill)(pid, SIG_KILL)
    return doomed


def killable(context: Context, /) -> bool:
    run = context.run
    if run.kind != "engine":
        return False
    return observed(context).phase not in TERMINAL or (bool(run.argv) and breathing(run.pid, run.argv[0]))


def killed_round(context: Context, /) -> Result[KillReceipt, Fault]:
    run = context.run
    if run.kind == "gather":
        return Error(Fault(code="no-process", detail=f"round {run.round} is a gather round (no engine process); nothing to kill"))
    needle = run.argv[0]
    prior = observed(context)
    if prior.phase in TERMINAL and not breathing(run.pid, needle):
        return Error(Fault(code="already-closed", detail=f"round {run.round} is already {prior.phase} and its process group is gone"))

    def grouped(sig: int, /) -> None:
        catch(exception=ProcessLookupError)(KILLPG)(run.pgid, sig)

    signalled = ""
    if breathing(run.pid, needle):
        grouped(SIG_TERM)
        deadline = time.time() + KILL_ESCALATE_S
        while time.time() < deadline and breathing(run.pid, needle):
            time.sleep(KILL_TICK_S)
        signalled = "SIGTERM"
        if breathing(run.pid, needle):
            grouped(SIG_KILL)
            signalled = "SIGTERM+SIGKILL"
    survivors = survivors_swept(context.repo, needle)
    removed = swept_worktrees(context.repo, run.started - WORKTREE_ERA_S) if run.reviewer == "macroscope" else ()
    return written(context.round_dir / KILLED_NAME, ENCODER.encode(KillMark(sent=signalled or "already-dead", at=time.time()))).map(
        lambda _path: KillReceipt(
            round=run.round, reviewer=run.reviewer, signalled=signalled, pgid=run.pgid, survivors=survivors, worktrees_removed=removed, phase="killed"
        )
    )


# --- [NORMALIZE]


def headline(text: str, /) -> str:
    return next((line.strip()[:HEADLINE] for line in text.splitlines() if line.strip()), "")


def ranked(native: str, /) -> Severity:
    return SEVERITY_MAP.get(native.lower(), "minor")


def stemmed(claim: str, /) -> str:
    return STEM_RE.sub(" ", unicodedata.normalize("NFC", claim).casefold()).strip()[:CLAIM_STEM]


def fingerprinted(file: str, span: Range, claim: str, /) -> str:
    return hashlib.sha256(f"{file}|{span.start}:{span.end}|{stemmed(claim)}".encode()).hexdigest()[:16]


def depreambled(text: str, /) -> str:
    return next((text[len(mark) :].lstrip() for mark in ENGINE_PREAMBLES if text.startswith(mark)), text)


def minted(reviewer: Reviewer, file: str, span: Range, claim: str, fix: str, severity: str, /) -> Option[Finding]:
    claim, fix = depreambled(claim), depreambled(fix)
    if not file and not claim:
        return Nothing
    return Some(
        Finding(
            id="",
            fingerprint=fingerprinted(file, span, claim),
            reviewer=reviewer,
            file=file,
            range=span,
            severity=ranked(severity),
            claim=claim,
            fix_instructions=fix,
            class_match="",
            anchored=bool(file) and span.start > 0,
            actionable=bool(fix),
        )
    )


def counted(rows: tuple[Finding, ...], /) -> dict[str, int]:
    tally = Counter(row.severity for row in rows)
    return {level: tally[level] for level in SEVERITIES if level in tally}


def provenance_hist(rows: tuple[Finding, ...], /) -> dict[str, int]:
    return {str(key): count for key, count in Counter(row.provenance for row in rows if row.provenance).items()}


def lenient_pattern(matcher: str, /) -> re.Pattern[str]:
    return catch(exception=re.PatternError)(re.compile)(matcher, re.IGNORECASE).default_with(
        lambda _bad: re.compile(re.escape(matcher), re.IGNORECASE)
    )


def compiled(registry: Registry, /) -> tuple[tuple[str, tuple[re.Pattern[str], ...]], ...]:
    return tuple((row.class_id, tuple(lenient_pattern(matcher) for matcher in row.matchers)) for row in registry.classes)


def classified(matchers: tuple[tuple[str, tuple[re.Pattern[str], ...]], ...], claim: str, /) -> str:
    return next((class_id for class_id, patterns in matchers if any(pattern.search(claim) for pattern in patterns)), "")


def claim_scope(row: Finding, /) -> str:
    return f"{row.claim}\n{row.fix_instructions}"


SEARCH_SCOPES: Final[Mapping[str, Callable[[Finding], str]]] = MappingProxyType({
    "claim": lambda row: row.claim,
    "fix": lambda row: row.fix_instructions,
    "both": claim_scope,
})


def finding_order(row: Finding, /) -> tuple[int, str, int]:
    return (RANK[row.severity], row.file, row.range.start)


def normalized(rows: tuple[Finding, ...], registry: Registry, /) -> tuple[Finding, ...]:
    matchers = compiled(registry)
    stamped = tuple(replace(row, class_match=classified(matchers, claim_scope(row))) for row in rows)
    ordered = sorted(stamped, key=lambda row: (row.fingerprint, RANK[row.severity]))
    survivors = tuple(next(iter(bunch)) for _, bunch in groupby(ordered, key=lambda row: row.fingerprint))
    return tuple(sorted(survivors, key=finding_order))


def unioned(pools: tuple[tuple[Finding, ...], ...], registry: Registry, /) -> tuple[Finding, ...]:
    matchers = compiled(registry)
    tagged = tuple(replace(row, class_match=row.class_match or classified(matchers, claim_scope(row))) for pool in pools for row in pool)
    ordered = sorted(tagged, key=lambda row: row.fingerprint)

    def collapsed(bunch: tuple[Finding, ...], /) -> Finding:
        group = sorted(bunch, key=lambda row: RANK[row.severity])
        primary = group[0]
        others = tuple(row.reviewer for row in group[1:] if row.reviewer != primary.reviewer)
        return replace(primary, corroborators=tuple(dict.fromkeys((*primary.corroborators, *others))))

    survivors = tuple(collapsed(tuple(bunch)) for _, bunch in groupby(ordered, key=lambda row: row.fingerprint))
    return tuple(sorted(survivors, key=finding_order))


def pruned_against(prior: tuple[Finding, ...], rows: tuple[Finding, ...], /) -> tuple[tuple[Finding, ...], int]:
    seen = {row.fingerprint for row in prior}
    kept = tuple(row for row in rows if row.fingerprint not in seen)
    return kept, len(rows) - len(kept)


def prior_pool(repo: Path, current: int, dedup_against: int | None, /) -> Result[Option[tuple[Path, tuple[Finding, ...]]], Fault]:
    if dedup_against is not None and dedup_against >= current:
        return Error(
            Fault(code="bad-flag", detail=f"--dedup-against {dedup_against} must name a round before {current}; a self-dedup empties the round")
        )
    candidates = tuple(
        d for d in round_dirs(repo) if round_number(d) < current and (d / FINDINGS_NAME).is_file() and tuple(d.glob("lane-?-report.json"))
    )
    found = repo / STATE_DIR / f"round-{dedup_against:03d}" if dedup_against is not None else (candidates[-1] if candidates else None)
    if found is None:
        return Ok(Nothing)
    held = found / FINDINGS_NAME
    # A prior round that qualifies must decode loudly: a swallowed decode fault here is a silently empty provenance histogram downstream.
    return read_bytes(held).bind(lambda payload: decoded(payload, tuple[Finding, ...], str(held))).map(lambda rows: Some((found, rows)))


def provenanced(rows: tuple[Finding, ...], prior: Option[tuple[Path, tuple[Finding, ...]]], /) -> tuple[Finding, ...]:
    match prior:
        case Option(tag="some", some=(prior_dir, prior_rows)):
            pass
        case _:
            return rows
    ledger = tuple(row for report in lane_reports(prior_dir) for row in report.ledger)
    by_id = {row.id: row.fingerprint for row in prior_rows if row.id}
    verdicts = {fp: entry.verdict for entry in ledger if (fp := by_id.get(entry.id))}
    touched = frozenset(entry.file for entry in ledger if entry.verdict in {"fixed", "upgraded"})
    prior_fps = frozenset(row.fingerprint for row in prior_rows)

    def stamped(row: Finding, /) -> Finding:
        held: Provenance = (
            PROVENANCE_VERDICTS.get(verdicts.get(row.fingerprint, ""), "")
            if row.fingerprint in prior_fps
            else "new_work"
            if row.file in touched
            else "late_discovery"
        )
        return replace(row, provenance=held)

    return tuple(stamped(row) for row in rows)


def scope_dirty(repo: Path, scope: Scope, /) -> bool:
    git = ("git", "-C", str(repo))

    def status_dirty() -> bool:
        return sh((*git, "status", "--porcelain")).map(bool).default_with(lambda _f: False)

    def diff_dirty(ref: str, /) -> bool:
        return sh((*git, "diff", f"{ref}...HEAD", "--name-only")).map(bool).default_with(lambda _f: False)

    match scope.kind:
        case "uncommitted" | "all":
            return status_dirty()
        case "base" | "base-commit":
            return diff_dirty(scope.ref)
        case "committed":
            return base_resolved(repo).map(diff_dirty).default_with(lambda _f: False)
        case _:
            return False


@dataclass(frozen=True, slots=True, kw_only=True)
class DedupTrace:
    deduped: int = 0
    collapse_ratio: float = 0.0
    cross_deduped: int = 0
    prior_round: int | None = None


NO_DEDUP: Final = DedupTrace()


def findings_receipt(
    context: Context,
    rows: tuple[Finding, ...],
    /,
    *,
    admitted: int,
    trace: DedupTrace = NO_DEDUP,
    provenance: dict[str, int] | None = None,
    source: str = "",
) -> FindingsReceipt:
    return FindingsReceipt(
        round=context.run.round,
        reviewer=context.run.reviewer,
        admitted=admitted,
        total=len(rows),
        deduped=trace.deduped,
        collapse_ratio=round(trace.collapse_ratio, 3),
        cross_deduped=trace.cross_deduped,
        classified=sum(1 for row in rows if row.class_match),
        counts_by_severity=counted(rows),
        provenance=provenance if provenance is not None else provenance_hist(rows),
        scope_misfire=admitted == 0 and scope_dirty(context.repo, context.run.scope),
        source=source or str(context.round_dir / FINDINGS_NAME),
        path=str(context.round_dir / FINDINGS_NAME),
        prior_round=trace.prior_round,
    )


# --- [HARVEST_LEGS]


def cr_epoch(repo: Path, run: Run, now: float, /) -> Option[Path]:
    low, high = run.started - STORE_SLACK_S, now + STORE_SLACK_S
    anchor = Path(os.path.realpath(repo))
    stamped = Block.of_seq(CR_STORE.glob("*/*/reviews/*/git.json")).choose(
        lambda meta_path: shaped(meta_path, CrMeta).bind(
            lambda meta: (
                Some((meta.timestamp, meta_path.parent))
                if meta.working_directory and Path(os.path.realpath(meta.working_directory)) == anchor and low <= meta.timestamp <= high
                else Nothing
            )
        )
    )

    def launch_distance(stamp: tuple[float, Path], /) -> tuple[float, float]:
        at = stamp[0]
        return (0.0 if run.started <= at <= now else min(abs(at - run.started), abs(at - now)), abs(at - run.started))

    ordered = sorted(stamped, key=launch_distance)
    return Some(ordered[0][1]) if ordered else Nothing


def cr_span(rich: CrRich, /) -> Range:
    match rich.line_range:
        case Range(start=start, end=end) if start or end:
            return Range(start=start, end=end)
        case _:
            return Range(start=rich.start_line, end=rich.end_line or rich.start_line)


def cr_admitted(path: Path, /) -> Option[Finding]:
    def projected(rich: CrRich, /) -> Option[Finding]:
        claim = headline(rich.title or rich.comment)
        return minted("coderabbit", rich.file_name, cr_span(rich), claim, rich.codegen_instructions or rich.comment, rich.severity).map(
            lambda row: replace(row, id=rich.id)
        )

    return read_bytes(path).to_option().bind(lambda payload: decoded(payload, CrRich, str(path)).to_option().bind(projected))


def cr_store_rows(epoch: Path, /) -> tuple[Finding, ...]:
    return tuple(Block.of_seq(sorted(epoch.glob("*.json"))).choose(lambda path: Nothing if path.name in CR_META_NAMES else cr_admitted(path)))


CR_LOC_RE: Final[re.Pattern[str]] = re.compile(
    r"In @(?P<file>\S+?)\s+(?:at line (?P<one>\d+)|around lines (?P<low>\d+)\s*-\s*(?P<high>\d+))[,:]?\s*", re.IGNORECASE
)


def cr_stream_rows(log: Path, /) -> tuple[Finding, ...]:
    # Salvage mint for a dead engine: the liveness stream's finding lines carry severity, file, and the whole codegen instruction —
    # the rich store never lands when the service kills the review, so the stream is the only surviving findings source.
    def salvaged(raw: bytes, /) -> Option[Finding]:
        doc = json_value(raw, "<stream-finding>").to_option().map(stringly).default_value({})
        if doc.get("type") != "finding":
            return Nothing
        body = depreambled(str(doc.get("codegenInstructions") or "")).strip()
        met = CR_LOC_RE.search(body)
        span = Range() if met is None else Range(start=int(met["one"] or met["low"] or 0), end=int(met["one"] or met["high"] or 0))
        rest = body[met.end() :].strip() if met else body
        file = str(doc.get("fileName") or "") or (met["file"].lstrip("@") if met else "")
        return minted("coderabbit", file, span, headline(rest), rest, str(doc.get("severity") or "")).map(
            lambda row: replace(row, id=row.fingerprint[:12])
        )

    return tuple(Block.of_seq(read_bytes(log).map(bytes.splitlines).default_with(lambda _f: [])).choose(salvaged))


def cr_harvested(context: Context, /) -> Result[tuple[Finding, ...], Fault]:
    held = cr_epoch(context.repo, context.run, time.time()).map(lambda epoch: Ok(cr_store_rows(epoch)))
    if held.is_some():
        return held.value
    # No store epoch: a run the service killed mid-review never writes one — salvage the stream for a non-completed round only,
    # so a completed run with a missing store still fails loud as the correlation defect it is.
    salvage = cr_stream_rows(context.round_dir / LOG_NAME) if observed(context).phase != "completed" else ()
    if salvage:
        return Ok(salvage)
    return Error(
        Fault(
            code="store-missing",
            detail=f"no {CR_STORE} epoch matched the run window (workingDirectory==repo, timestamp within ±{STORE_SLACK_S:.0f}s)",
        )
    )


def json_offsets(text: str, /) -> tuple[int, ...]:
    starts = accumulate((len(line) for line in text.splitlines(keepends=True)), initial=0)
    return tuple(
        at + len(line) - len(stripped)
        for at, line in zip(starts, text.splitlines(keepends=True), strict=False)
        if (stripped := line.lstrip())[:1] in {"[", "{"}
    )


def json_documents(text: str, /) -> tuple[object, ...]:
    # JSON_SCAN_CAP bounds decoded documents, never candidate lines, so a pretty-printed prelude cannot exhaust the budget before the envelope.
    def stepped(acc: tuple[int, tuple[object, ...]], at: int, /) -> tuple[int, tuple[object, ...]]:
        horizon, docs = acc
        if at < horizon or len(docs) >= JSON_SCAN_CAP:
            return acc
        return json_document(text, at).map(lambda pair: (pair[1], (*docs, pair[0]))).default_value(acc)

    seed: tuple[int, tuple[object, ...]] = (0, ())
    return reduce(stepped, json_offsets(text), seed)[1]


def stringly(raw: object, /) -> dict[str, object]:
    return {str(key): value for key, value in raw.items()} if isinstance(raw, dict) else {}


def greptile_rows(doc: object, /) -> tuple[dict[str, object], ...]:
    match doc:
        case {"comments": list() as items}:
            return tuple(stringly(row) for row in items if isinstance(row, dict))
        case _:
            return ()


def greptile_payload(text: str, origin: str, /) -> Result[tuple[dict[str, object], ...], Fault]:
    docs = Block.of_seq(json_documents(text))
    populated = tuple(docs.choose(lambda doc: Some(held) if (held := greptile_rows(doc)) else Nothing))
    enveloped = docs.choose(lambda doc: Some(doc) if isinstance(doc, dict) and "comments" in doc else Nothing)
    return (
        Ok(populated[-1])  # the final envelope is the settled one; an incremental protocol's earlier envelopes are partials
        if populated
        else Ok(())
        if not enveloped.is_empty()
        else Error(Fault(code="no-payload", detail=f"{origin}: no greptile --json envelope (top-level comments[]) in the stream"))
    )


def gt_admitted(row: dict[str, object], /) -> Result[Option[Finding], Fault]:
    def converted() -> GtComment:
        return msgspec.convert(row, type=GtComment, strict=False)

    def projected(comment: GtComment, /) -> Option[Finding]:
        span = Range(start=comment.start_line, end=comment.end_line or comment.start_line)
        return minted("greptile", comment.path, span, headline(comment.body), comment.suggestion or comment.body, comment.severity).map(
            lambda held: replace(held, id=comment.id)
        )

    return (
        catch(exception=msgspec.ValidationError)(converted)()
        .map(projected)
        .map_error(lambda drift: Fault(code="malformed", detail=f"greptile comment {row.get('id') or '<unnamed>'}: {drift}"))
    )


def greptile_harvested(context: Context, /) -> Result[tuple[Finding, ...], Fault]:
    log = context.round_dir / LOG_NAME

    def kept_lines(text: str, /) -> str:
        return "\n".join(line for line in text.splitlines() if not line.startswith(EXIT_MARK))

    def payload_or_empty(text: str, /) -> Result[tuple[dict[str, object], ...], Fault]:
        return Ok(()) if "no committed code changes to review" in text else greptile_payload(text, str(log))

    return (
        read_bytes(log)
        .map(lambda raw: kept_lines(ANSI_RE.sub("", raw.decode(errors="replace"))))
        .bind(payload_or_empty)
        .bind(lambda rows: traverse(gt_admitted, Block.of_seq(rows)).map(lambda held: tuple(Block.of_seq(held).choose(lambda entry: entry))))
    )


def remote_slug(url: str, /) -> str:
    held = url.strip().removesuffix(".git").replace(":", "/")
    return "/".join(held.split("/")[-2:])


def greptile_trace(context: Context, /) -> str:
    mine = sh(("git", "-C", str(context.repo), "remote", "get-url", "origin")).map(remote_slug).default_with(lambda _f: "")
    return (
        shaped(GREPTILE_LEDGER, GreptileLedger)
        .map(lambda ledger: tuple(row for row in ledger.reviews if remote_slug(row.remote_url) == mine))
        .bind(lambda rows: Some(max(rows, key=lambda row: row.created_at)) if rows else Nothing)
        .map(
            lambda last: (
                f"cli-ledger:{last.run_id}:{last.status}:{last.comment_count}:head={last.head_sha}"
                " (runId is CLI-local; headSha is the MCP codeReviewId join key)"
            )
        )
        .default_value("cli-ledger:absent")
    )


def ms_admitted(text: str, at: int, /) -> Option[Finding]:
    def converted(payload: object, /) -> Option[Finding]:
        def as_issue() -> MsIssue:
            return msgspec.convert(payload, type=MsIssue, strict=False)

        return (
            catch(exception=msgspec.ValidationError)(as_issue)()
            .to_option()
            .bind(
                lambda issue: (
                    minted(
                        "macroscope",
                        issue.path,
                        Range(start=issue.line, end=issue.end_line or issue.line),
                        headline(issue.body),
                        issue.body,
                        issue.severity,
                    )
                    if issue.issue_id or issue.path
                    else Nothing
                )
            )
        )

    return json_document(text, at).map(itemgetter(0)).bind(converted)


def ms_harvested(context: Context, /) -> Result[tuple[Finding, ...], Fault]:
    return (
        read_bytes(context.round_dir / LOG_NAME)
        .map(lambda raw: ANSI_RE.sub("", raw.decode(errors="replace")))
        .map(lambda text: tuple(Block.of_seq(ISSUE_AT_RE.finditer(text)).choose(lambda hit: ms_admitted(text, hit.end()))))
    )


# --- [SLICING]


@dataclass(frozen=True, slots=True, kw_only=True)
class Bundle:
    label: str
    rows: tuple[Finding, ...]
    weight: float


def loc_of(path: Path, /) -> int:
    return read_bytes(path).map(lambda payload: payload.count(b"\n")).default_with(lambda _f: 0)


def row_weigher(balance: Balance, repo: Path, rows: tuple[Finding, ...], /) -> Weigh:
    match balance:
        case "count":
            return lambda _row: 1.0
        case "loc":
            share = Counter(row.file for row in rows)
            cost = {file: float(max(loc_of(repo / file), 1)) for file in share}
            return lambda row: cost[row.file] / share[row.file]


def bundled(label: str, rows: tuple[Finding, ...], weigh: Weigh, /) -> Bundle:
    return Bundle(label=label, rows=rows, weight=sum(weigh(row) for row in rows))


def seam_depth(parts: tuple[tuple[str, ...], ...], /) -> int:
    # Default is the common-prefix length, so a path that is a component-wise prefix of its sibling still yields a real seam.
    return next((at for at, level in enumerate(zip(*parts, strict=False)) if len(set(level)) > 1), min(len(held) for held in parts))


def corpus_label(files: tuple[str, ...], /) -> str:
    parts = tuple(PurePosixPath(file).parts for file in files)
    return files[0] if len(parts) == 1 else "/".join(parts[0][: seam_depth(parts)]) or "."


def seam_split(bundle: Bundle, weigh: Weigh, /) -> tuple[Bundle, ...]:
    files = sorted({row.file for row in bundle.rows})
    if len(files) > 1:
        parts = {file: PurePosixPath(file).parts for file in files}
        depth = seam_depth(tuple(parts[file] for file in files))

        def seam(file: str, /) -> str:
            held = parts[file]
            return held[depth] if depth < len(held) else ""

        ordered = sorted(bundle.rows, key=lambda row: (seam(row.file), row.file, row.range.start))
        cut = tuple(
            bundled("/".join(parts[held[0].file][: depth + 1]) or "<unanchored>", held, weigh)
            for _seam, bunch in groupby(ordered, key=lambda row: seam(row.file))
            if (held := tuple(bunch))
        )
        if len(cut) > 1:  # a degenerate single-group cut falls through to the index halving, so every split proves progress
            return cut
    if len(bundle.rows) > 1:
        halved = tuple(sorted(bundle.rows, key=lambda row: (row.range.start, row.fingerprint)))
        mid = len(halved) // 2
        return tuple(bundled(f"{bundle.label}#{mark}", held, weigh) for mark, held in (("a", halved[:mid]), ("b", halved[mid:])))
    return ()


def partitioned(rows: tuple[Finding, ...], lanes: int, weigh: Weigh, /) -> tuple[Bundle, ...]:
    if not rows:
        return ()
    seed = bundled(corpus_label(tuple(sorted({row.file for row in rows}))), rows, weigh)
    target = seed.weight / max(lanes, 1)
    bundles: tuple[Bundle, ...] = (seed,)
    while True:  # bounded: every pass splits one multi-row bundle, so passes cannot exceed len(rows)
        splittable = tuple(held for held in bundles if len(held.rows) > 1)
        pool = tuple(held for held in splittable if held.weight > target) or (splittable if len(bundles) < lanes else ())
        if not pool:
            return bundles
        victim = max(pool, key=lambda held: held.weight)
        bundles = (*(held for held in bundles if held is not victim), *seam_split(victim, weigh))


def auto_lanes(total: int, /) -> int:
    return min(LANES_CAP, max(1, -(-total // LANE_LOAD)))


def corpus_of(files: tuple[str, ...], /) -> str:
    paths = tuple(
        PurePosixPath(file) for file in files if file
    )  # repo-root markdown is estate prose; libs/** markdown carries code fences and stays code
    return (
        "prose"
        if paths and all(path.suffix in PROSE_SUFFIXES and (len(path.parts) == 1 or path.parts[0] in PROSE_ROOTS) for path in paths)
        else "code"
    )


def rulings_of(registry: Registry, corpus: str, /) -> tuple[str, ...]:
    return tuple(f"{row.class_id}: {row.refuting_citation}".rstrip(": ") for row in registry.classes if not row.corpus or row.corpus == corpus)


def packed_into(bundles: tuple[Bundle, ...], lanes: int, /) -> tuple[tuple[Bundle, ...], ...]:
    def packed(acc: tuple[tuple[float, tuple[Bundle, ...]], ...], entry: Bundle, /) -> tuple[tuple[float, tuple[Bundle, ...]], ...]:
        slot = min(range(len(acc)), key=lambda at: acc[at][0])
        weight, held = acc[slot]
        return (*acc[:slot], (weight + entry.weight, (*held, entry)), *acc[slot + 1 :])

    seeds: tuple[tuple[float, tuple[Bundle, ...]], ...] = tuple((0.0, ()) for _ in range(lanes))
    ordered = sorted(bundles, key=lambda held: held.weight, reverse=True)
    return tuple(held for _weight, held in reduce(packed, ordered, seeds))


def sliced(rows: tuple[Finding, ...], lanes: int, balance: Balance, repo: Path, round_no: int, registry: Registry, /) -> tuple[LaneSlice, ...]:
    weigh = row_weigher(balance, repo, rows)
    packs = packed_into(partitioned(rows, min(lanes, LANES_CAP), weigh), min(lanes, LANES_CAP))

    def lane_carved(at: int, pack: tuple[Bundle, ...], /) -> LaneSlice:
        letter = LANE_ALPHABET[at]
        labels = tuple(sorted(dict.fromkeys(held.label for held in pack)))
        picked_rows = sorted((row for held in pack for row in held.rows), key=finding_order)
        stamped = tuple(replace(row, id=f"r{round_no}{letter}-{index + 1:02d}") for index, row in enumerate(picked_rows))
        criticals = sum(1 for row in stamped if row.severity == "critical")
        files = tuple(sorted({row.file for row in stamped}))
        return LaneSlice(
            manifest=LaneManifest(
                lane=f"lane-{letter}",
                files=files,
                count=len(stamped),
                criticals=criticals,
                suggested_scope_line=f"{', '.join(labels)} — {len(stamped)} findings, {criticals} critical",
            ),
            settled_rulings=rulings_of(registry, corpus_of(files)),
            findings=stamped,
        )

    return tuple(lane_carved(at, pack) for at, pack in enumerate(packs) if pack)


def closer_sliced(rows: tuple[RoutingRow, ...], lanes: int, reviewer: Reviewer, /) -> tuple[LaneSlice, ...]:
    # One bundle per target file keeps closer territories file-disjoint by construction — concurrent closers never share a write target.
    def fabricated(row: RoutingRow, /) -> Finding:
        return Finding(
            id=row.key,
            fingerprint=fingerprinted(row.target_file, Range(), f"{row.key}|{row.needed_change}"),
            reviewer=reviewer,
            file=row.target_file,
            range=Range(),
            severity="major",
            claim=row.needed_change,
            fix_instructions=f"grep lane-{row.lane}-report.json routing[] for this target's full demand before editing",
            class_match="",
        )

    ordered = sorted(rows, key=lambda row: (row.target_file, row.key))
    bundles = tuple(
        bundled(file, tuple(fabricated(row) for row in bunch), lambda _row: 1.0) for file, bunch in groupby(ordered, key=lambda row: row.target_file)
    )
    packs = packed_into(bundles, max(1, min(lanes, len(bundles), LANES_CAP)))

    def carved(at: int, pack: tuple[Bundle, ...], /) -> LaneSlice:
        picked = sorted((row for held in pack for row in held.rows), key=finding_order)
        files = tuple(sorted({row.file for row in picked}))
        return LaneSlice(
            manifest=LaneManifest(
                lane=f"close-{LANE_ALPHABET[at]}",
                files=files,
                count=len(picked),
                criticals=0,
                suggested_scope_line=f"{', '.join(files)} — {len(picked)} routed rows",
            ),
            settled_rulings=(),
            findings=tuple(picked),
        )

    return tuple(carved(at, pack) for at, pack in enumerate(packs) if pack)


def span_of(span: Range, /) -> str:
    return f"{span.start}" if span.end in {0, span.start} else f"{span.start}-{span.end}"


def brief_rendered(pack: LaneSlice, round_no: int, /) -> str:
    manifest = pack.manifest
    ordered = sorted(pack.findings, key=lambda row: (row.file, row.range.start))
    tally = Counter(row.file for row in ordered)

    def entry(row: Finding, /) -> tuple[str, ...]:
        fix = row.fix_instructions.strip()
        head, *rest = fix.splitlines() or ("",)
        return (
            f"- [{row.severity.upper()}] {row.id} L{span_of(row.range)} — {row.claim}",
            *((f"  fix: {head}", *(f"       {line}" for line in rest)) if fix else ()),
        )

    sections = (
        f"# [LANE_BRIEF] round {round_no} — {manifest.lane} — {manifest.suggested_scope_line}",
        "",
        "## [FILES]",
        *(f"- {file} ({count})" for file, count in sorted(tally.items())),
        "",
        "## [FINDINGS]",
        *(
            line
            for file, bunch in groupby(ordered, key=lambda row: row.file)
            for line in (f"### {file}", *(piece for row in bunch for piece in entry(row)))
        ),
        "",
        "## [SETTLED_RULINGS]",
        *(f"- {ruling}" for ruling in pack.settled_rulings),
    )
    return "\n".join(sections) + "\n"


# --- [DIGEST]


def lined(row: Finding, /) -> FindingLine:
    return FindingLine(id=row.id or row.fingerprint[:8], severity=row.severity, file=row.file, range=row.range, claim=row.claim)


def line_rendered(line: FindingLine, /) -> str:
    return f"[{line.severity.upper()}] {line.file}:{span_of(line.range)} {line.id} — {line.claim}"


def digest_built(context: Context, rows: tuple[Finding, ...], top_n: int, /) -> Digest:
    total = len(rows)
    stamped = sorted((row for row in rows if row.class_match), key=lambda row: row.class_match)
    fired = tuple(
        ClassFire(class_id=class_id, count=len(held), ids=tuple(row.id or row.fingerprint[:8] for row in held))
        for class_id, bunch in groupby(stamped, key=lambda row: row.class_match)
        if (held := tuple(bunch))
    )
    cuts = sorted(partitioned(rows, DIGEST_FOLDS, row_weigher("count", context.repo, rows)), key=lambda held: len(held.rows), reverse=True)
    ranked_rows = sorted(rows, key=finding_order)
    top = {
        str(level): tuple(lined(row) for row in islice((row for row in ranked_rows if row.severity == level), top_n))
        for level in SEVERITIES
        if any(row.severity == level for row in rows)
    }
    return Digest(
        round=context.run.round,
        reviewer=context.run.reviewer,
        scope=context.run.scope.line,
        total=total,
        counts_by_severity=counted(rows),
        anchored_share=round(sum(1 for row in rows if row.anchored) / total, 3) if total else 0.0,
        actionable_share=round(sum(1 for row in rows if row.actionable) / total, 3) if total else 0.0,
        corroborated=sum(1 for row in rows if row.corroborators),
        provenance=provenance_hist(rows),
        classes=fired,
        folders=tuple(
            FolderCut(
                folder=held.label,
                count=len(held.rows),
                files=len({row.file for row in held.rows}),
                criticals=sum(1 for row in held.rows if row.severity == "critical"),
            )
            for held in cuts
        ),
        top=top,
    )


def digest_rendered(digest: Digest, /) -> str:
    severity = " ".join(f"{level}={count}" for level, count in digest.counts_by_severity.items())
    provenance = " ".join(f"{key}={count}" for key, count in digest.provenance.items())
    classes = ", ".join(f"{fire.class_id} x{fire.count} ({', '.join(fire.ids)})" for fire in digest.classes)
    lines = (
        f"[DIGEST] round {digest.round} — {digest.reviewer} — {digest.scope} — {digest.total} findings",
        f"severity: {severity or 'none'}",
        f"anchored {digest.anchored_share:.0%}  actionable {digest.actionable_share:.0%}  corroborated {digest.corroborated}",
        f"provenance: {provenance or 'unstamped'}",
        f"classes: {classes or 'none fired'}",
        "folders:",
        *(
            f"  {cut.folder} — {cut.count} findings / {cut.files} files" + (f" / {cut.criticals} critical" if cut.criticals else "")
            for cut in digest.folders
        ),
        *(line for level, held in digest.top.items() for line in (f"top {level}:", *(f"  {line_rendered(row)}" for row in held))),
    )
    return "\n".join(lines)


def queried(
    rows: tuple[Finding, ...], floor: Option[Severity], glob: str, matcher: Option[re.Pattern[str]], searched: Callable[[Finding], str], /
) -> tuple[Finding, ...]:
    def kept(row: Finding, /) -> bool:
        return (
            floor.map(lambda level: RANK[row.severity] <= RANK[level]).default_value(value=True)
            and (not glob or fnmatch(row.file, glob))
            and matcher.map(lambda pattern: pattern.search(searched(row)) is not None).default_value(value=True)
        )

    return tuple(row for row in rows if kept(row))


def query_rendered(receipt: QueryReceipt, /) -> str:
    filters = " ".join(f"{key}={value}" for key, value in receipt.filters.items())
    head = f"[QUERY] round {receipt.round} — {receipt.matched}/{receipt.total} findings" + (f" — {filters}" if filters else "")
    return "\n".join((head, *(line_rendered(row) for row in receipt.rows)))


# --- [RECONCILE]


def lane_slices(round_dir: Path, /) -> tuple[tuple[Path, LaneSlice], ...]:
    return tuple(Block.of_seq(sorted(round_dir.glob("lane-?.json"))).choose(lambda path: shaped(path, LaneSlice).map(lambda held: (path, held))))


def report_pairs(round_dir: Path, /) -> tuple[tuple[str, LaneReport], ...]:
    return tuple(
        Block.of_seq(sorted(round_dir.glob("lane-?-report.json"))).choose(
            lambda path: report_shaped(path, LaneReport).to_option().map(lambda held: (path.name.removesuffix("-report.json"), held))
        )
    )


def lane_reports(round_dir: Path, /) -> tuple[LaneReport, ...]:
    return tuple(report for _lane, report in report_pairs(round_dir))


def closer_reports(round_dir: Path, /) -> tuple[CloserReport, ...]:
    return tuple(Block.of_seq(sorted(round_dir.glob("close-*-report.json"))).choose(lambda path: report_shaped(path, CloserReport).to_option()))


def routing_mined(pairs: tuple[tuple[str, LaneReport], ...], /) -> tuple[RoutingRow, ...]:
    def mined(lane: str, raw: msgspec.Raw, /) -> Option[RoutingRow]:
        body = json_value(bytes(raw), "routing-row").map(stringly).default_with(lambda _f: {})
        target = str(body.get("target_file", ""))
        letter = lane.removeprefix("lane-")
        change = headline(str(body.get("needed_change", "")))
        return Some(RoutingRow(lane=letter, target_file=target, needed_change=change, key=f"{letter}:{target}")) if target else Nothing

    return tuple(Block.of_seq(tuple((lane, raw) for lane, report in pairs for raw in report.routing)).choose(lambda pair: mined(*pair)))


def routing_drained(rows: tuple[RoutingRow, ...], closers: tuple[CloserReport, ...], /) -> RoutingDrain:
    # A verdict row answers by the stamped "<lane-letter>:<target_file>" key, a bare target path in id, or its file field.
    answered = frozenset(name for report in closers for row in report.rows for name in (row.id, row.file) if name)
    pending = tuple(row for row in rows if row.key not in answered and row.target_file not in answered)
    return RoutingDrain(
        total=len(rows),
        drained=len(rows) - len(pending),
        verdicts=dict(Counter(row.verdict or "<blank>" for report in closers for row in report.rows)),
        pending=pending,
    )


def round_drain(round_dir: Path, /) -> RoutingDrain:
    return routing_drained(routing_mined(report_pairs(round_dir)), closer_reports(round_dir))


def reports_complete(round_dir: Path, /) -> Result[tuple[LaneReport, ...], Fault]:
    # An undecodable or absent report must refuse, never shrink the pool — a partial harvest poisons the class census and grades irreversibly.
    slices = lane_slices(round_dir)
    decodable = frozenset(
        path.name.removesuffix("-report.json") for path in round_dir.glob("lane-?-report.json") if report_shaped(path, LaneReport).is_ok()
    )
    missing = tuple(sorted(slice_.manifest.lane for _path, slice_ in slices if slice_.manifest.lane not in decodable))
    if missing:
        return Error(
            Fault(code="no-report", detail=f"lanes without a decodable report: {', '.join(missing)}; repair or re-emit before harvest/round")
        )
    return Ok(lane_reports(round_dir))


def lane_stat(lane_path: Path, slice_: LaneSlice, round_dir: Path, /) -> LaneStat:
    report_path = round_dir / f"{slice_.manifest.lane}-report.json"
    outcome = report_shaped(report_path, LaneReport)
    report = outcome.to_option()
    ids = {row.id for row in slice_.findings}
    ledger_ids = tuple(row.id for row in report.map(lambda held: held.ledger).default_value(()))
    touched = report.map(lambda held: held.files).default_value(())
    sliced_at = catch(exception=OSError)(lane_path.stat)().map(lambda held: held.st_mtime).default_with(lambda _f: 0.0)
    reported_at = catch(exception=OSError)(report_path.stat)().map(lambda held: held.st_mtime).default_with(lambda _f: sliced_at)
    wall = report.bind(lambda held: Some(held.wall_s) if held.wall_s > 0 else Nothing).default_with(lambda: reported_at - sliced_at)
    match report:
        case Option(tag="some", some=held):
            gate: bool | None = held.gate_clean
        case _:
            gate = None
    return LaneStat(
        lane=slice_.manifest.lane,
        model=report.map(lambda held: held.model.strip().casefold()).default_value(""),  # agent-written; case drift must not fork grade cohorts
        findings=slice_.manifest.count,
        verdicts=report.map(lambda held: dict(Counter(row.verdict or "<blank>" for row in held.ledger))).default_value({}),
        missing=tuple(sorted(ids - set(ledger_ids))),
        phantom=tuple(sorted(set(ledger_ids) - ids - {""})),
        wall_s=round(max(wall, 0.0), 1),
        report_valid=report.is_some(),
        gate_clean=gate,
        fault=outcome.swap().to_option().map(lambda held: f"{held.code}: {held.detail}").default_value(""),
        files=tuple(sorted(touched)),
        strays=tuple(sorted(set(touched) - set(slice_.manifest.files))),
        shapes=report.map(lambda held: dict(Counter(row.shape or "unstamped" for row in held.ledger))).default_value({}),
    )


def reconciled(round_dir: Path, /) -> Result[tuple[LaneStat, ...], Fault]:
    slices = lane_slices(round_dir)
    if not slices:
        return Error(Fault(code="no-lanes", detail=f"no lane-?.json under {round_dir}; slice first"))
    return Ok(tuple(lane_stat(path, slice_, round_dir) for path, slice_ in slices))


# --- [SPAWN_AUDIT]


def session_of(events: Path, /) -> str:
    lines = read_bytes(events).map(bytes.splitlines).default_with(lambda _f: [])
    heads = Block.of_seq([line for line in lines if b"thread.started" in line]).choose(lambda line: decoded(line, EventHead, str(events)).to_option())
    return next((head.thread_id for head in heads if head.type == "thread.started" and head.thread_id), "")


def rollout_of(session: str, /) -> str:
    hits = sorted(CODEX_SESSIONS.glob(f"*/*/*/rollout-*-{session}.jsonl")) if session else []
    return str(hits[-1]) if hits else ""


def spawn_scanned(lines: list[bytes], /) -> tuple[int, tuple[str, ...]]:
    # A bare string grep over-matches: the tool name also rides developer-message text and event_msg echoes,
    # while the per-lane events stream records zero spawns outright — only a rollout response_item function_call is a real dispatch.
    def called(line: bytes, /) -> Option[RolloutCall]:
        if SPAWN_TOOL.encode() not in line:
            return Nothing
        return (
            decoded(line, RolloutLine, "<rollout>")
            .to_option()
            .bind(
                lambda row: (
                    Some(row.payload)
                    if row.type == "response_item"
                    and row.payload is not None
                    and row.payload.type == "function_call"
                    and row.payload.name == SPAWN_TOOL
                    else Nothing
                )
            )
        )

    def agent_of(call: RolloutCall, /) -> Option[str]:
        named = json_value(call.arguments.encode(), "<spawn-args>").to_option().map(stringly)
        return named.bind(lambda body: Some(str(body["task_name"])) if body.get("task_name") else Nothing)

    calls = tuple(Block.of_seq(lines).choose(called))
    return len(calls), tuple(Block.of_seq(calls).choose(agent_of))


def spawn_rows(round_dir: Path, /) -> tuple[SpawnRow, ...]:
    def lane_of(events: Path, /) -> str:
        # flat layout: lane-<x>-events.jsonl in the round dir; lane-dir layout: lane-<x>-run/events.jsonl from a codex-lane --dir.
        return events.parent.name.removesuffix("-run") if events.name == "events.jsonl" else events.name.removesuffix("-events.jsonl")

    def audited(events: Path, /) -> SpawnRow:
        lane = lane_of(events)
        session = session_of(events)
        if not session:
            return SpawnRow(lane=lane, fault="no-session")
        rollout = rollout_of(session)
        if not rollout:
            return SpawnRow(lane=lane, session=session, fault="no-rollout")
        spawns, agents = spawn_scanned(read_bytes(Path(rollout)).map(bytes.splitlines).default_with(lambda _f: []))
        return SpawnRow(lane=lane, session=session, rollout=rollout, spawns=spawns, agents=agents)

    events_files = sorted((
        *round_dir.glob("lane-?-events.jsonl"),
        *round_dir.glob("close-*-events.jsonl"),
        *round_dir.glob("harvest-events.jsonl"),
        *round_dir.glob("lane-?-run/events.jsonl"),
        *round_dir.glob("close-*-run/events.jsonl"),
        *round_dir.glob("harvest-run/events.jsonl"),
    ))
    named = {lane_of(path) for path in events_files}
    silent = tuple(
        SpawnRow(lane=slice_.manifest.lane, fault="no-events")
        for _path, slice_ in lane_slices(round_dir)
        if slice_.manifest.lane not in named  # a claude-transport lane writes no events stream; its spawn story is a per-lane fact, not a refusal
    )
    return tuple(sorted((*map(audited, events_files), *silent), key=lambda row: row.lane))


# --- [LANE_FILL]

LANGS: Final[frozenset[str]] = frozenset({"csharp", "python", "typescript"})


def tiers_of(file: str, /) -> tuple[str, str, str]:
    # (package_root, substrate_api, doctrine_root); "" marks a tier the path does not carry — package .api existence resolves at the verb.
    match PurePosixPath(file).parts:
        case ("libs", lang, package, _leaf, *_) if lang in LANGS:
            return (f"libs/{lang}/{package}", f"libs/{lang}/.api", f"docs/stacks/{lang}")
        case ("libs", lang, *_) if lang in LANGS:
            return ("", f"libs/{lang}/.api", f"docs/stacks/{lang}")
        case ("tests", lang, *_) if lang in LANGS:
            return ("", f"tests/{lang}/.api", f"docs/stacks/{lang}")
        case _:
            return ("", "", "")


def lane_filled(repo: Path, manifest: LaneManifest, /) -> LaneFill:
    placed = tuple((file, *tiers_of(file)) for file in manifest.files)
    packages = tuple(
        PackageTier(root=root, api=f"{root}/.api" if (repo / root / ".api").is_dir() else "")
        for root in dict.fromkeys(root for _file, root, _sub, _doc in placed if root)
    )
    return LaneFill(
        lane=manifest.lane,
        files=manifest.files,
        packages=packages,
        substrate=tuple(dict.fromkeys(sub for _file, _root, sub, _doc in placed if sub and (repo / sub).is_dir())),
        doctrine=tuple(dict.fromkeys(doc for _file, _root, _sub, doc in placed if doc)),
        unplaced=tuple(file for file, root, sub, _doc in placed if not root and not sub),
    )


# --- [RECURRENCE]


def recurrence(
    registry: Registry, rows: tuple[Finding, ...], reports: tuple[LaneReport, ...], /
) -> tuple[tuple[tuple[str, tuple[str, ...]], ...], tuple[Refutation, ...]]:
    matchers = compiled(registry)
    flagged = tuple((row.class_match, f"{row.id or row.fingerprint}: {row.claim}") for row in rows if row.class_match)
    refutations = tuple(entry for report in reports for entry in report.refuted)
    matched = tuple((classified(matchers, entry.claim), f"refuted: {entry.claim}") for entry in refutations)
    recurred = {
        class_id: tuple(instance for hit_id, instance in (*flagged, *matched) if hit_id == class_id)
        for class_id in dict.fromkeys(hit_id for hit_id, _ in (*flagged, *matched) if hit_id)
    }
    fresh = tuple(entry for entry, (hit_id, _) in zip(refutations, matched, strict=True) if not hit_id)
    return tuple(recurred.items()), fresh


def raw_text(raw: msgspec.Raw, /) -> str:
    match json_value(bytes(raw), "report-row"):
        case Result(tag="ok", ok=str() as text):
            return text
        case Result(tag="ok", ok=value):
            return ENCODER.encode(value).decode()
        case _:
            return bytes(raw).decode(errors="replace")


def slugged(claim: str, /) -> str:
    return "-".join(stemmed(claim).split()[:4]) or "unnamed"


def proposal_block(fresh: tuple[Refutation, ...], /) -> tuple[str, ...]:
    if not fresh:
        return ()
    rows = [
        {"class_id": slugged(entry.claim), "matchers": [stemmed(entry.claim)], "refuting_citation": "", "landed_surfaces": [], "recurrences": 1}
        for entry in fresh
    ]
    sink = io.StringIO()
    YAML_RT.dump({"classes": rows}, sink)
    return ("```yaml proposed-registry-rows", sink.getvalue().rstrip("\n"), "```")


def improvement_lines(reports: tuple[LaneReport, ...], /) -> tuple[str, ...]:
    rows = tuple((row.axis, f"- {row.page} — {row.pattern} — {row.what}") for report in reports for row in report.improvements)
    if all(not axis for axis, _line in rows):
        return tuple(line for _axis, line in rows)
    ordered = sorted(rows, key=itemgetter(0))
    return tuple(
        line for axis, bunch in groupby(ordered, key=itemgetter(0)) for line in (f"### [{axis or 'general'}]", *(entry for _a, entry in bunch))
    )


def ineffective_of(registry: Registry, recurred_ids: frozenset[str], /) -> tuple[RefutedClass, ...]:
    return tuple(row for row in registry.classes if row.class_id in recurred_ids and row.landed_surfaces and row.recurrences)


def feed_rendered(
    run: Run, recurred: tuple[tuple[str, tuple[str, ...]], ...], fresh: tuple[Refutation, ...], reports: tuple[LaneReport, ...], registry: Registry, /
) -> str:
    citations = {row.class_id: row.refuting_citation for row in registry.classes}
    recurred_ids = frozenset(class_id for class_id, _ in recurred)
    sections = (
        f"# [HARVEST_FEED] round {run.round} — {run.reviewer} — {run.scope.line}",
        *((f"focus: {run.focus}",) if run.focus else ()),
        "## [RECURRED]",
        *(
            f"- `{class_id}` ({citations.get(class_id, '')}) — guard did not bite:\n" + "\n".join(f"  - {instance}" for instance in instances)
            for class_id, instances in recurred
        ),
        "## [GUARD_INEFFECTIVE]",
        *(
            f"- `{row.class_id}` — landed on {', '.join(row.landed_surfaces)}; recurred {row.recurrences} prior rounds and again this"
            " round — the wording failed: harden it, never skip as already-owned"
            for row in ineffective_of(registry, recurred_ids)
        ),
        "## [NEW_REFUTED]",
        *(f"- {entry.claim} — {entry.evidence}" for entry in fresh),
        *proposal_block(fresh),
        "## [IMPROVEMENTS]",
        *improvement_lines(reports),
        "## [CAPABILITY_LANDED]",
        *(f"- {raw_text(row)}" for report in reports for row in report.capability),
        "## [ROUTED]",
        *(f"- {raw_text(row)}" for report in reports for row in report.routing),
        *(f"- (uncertain) {raw_text(row)}" for report in reports for row in report.uncertain),
    )
    return "\n".join(sections) + "\n"


# --- [MEMORY_PROPOSALS]


def roster_row(raw: msgspec.Raw, /) -> Option[tuple[str, tuple[str, ...], str]]:
    def mined(doc: object, /) -> Option[tuple[str, tuple[str, ...], str]]:
        body = stringly(doc)
        members = next((tuple(str(item) for item in value) for key in ROSTER_KEYS if isinstance(value := body.get(key), list) and value), ())
        if not members:
            return Nothing
        label = str(body.get("pattern") or body.get("what") or body.get("page") or members[0])
        return Some((slugged(label), members, bytes(raw).decode(errors="replace")))

    return json_value(bytes(raw), "capability-row").to_option().bind(mined)


def reference_stub(slug: str, members: tuple[str, ...], evidence: str, round_no: int, /) -> str:
    lead = ", ".join(members[:4]).replace('"', "'")
    return "\n".join((
        "---",
        f"name: reference_{slug}",
        f'description: "{lead} — verified member roster from review round {round_no}"',
        "metadata:",
        "  node_type: memory",
        "  type: reference",
        "---",
        *(f"- `{member}`" for member in members),
        "",
        "```json evidence",
        evidence,
        "```",
        "",
        "Proposed MEMORY.md index row:",
        f"- [{slug.replace('-', ' ')}](reference_{slug}.md) — {lead} verified member roster",
        "",
    ))


def feedback_stub(row: RefutedClass, /) -> str:
    rounds = f"{row.recurrences + 1} rounds"
    surfaces = ", ".join(row.landed_surfaces)
    slug = slugged(row.class_id)
    citation = f" Citation: {row.refuting_citation}." if row.refuting_citation else ""
    return "\n".join((
        "---",
        f"name: feedback_{slug}",
        f'description: "{row.class_id} recurs across {rounds} despite guards on {surfaces}"',
        "metadata:",
        "  node_type: memory",
        "  type: feedback",
        "---",
        (
            f"`{row.class_id}` recurs across {rounds} despite landed guards on {surfaces} — the guard mechanism, not the claim, needs a"
            f" process change.{citation}"
        ),
        "",
        "Proposed MEMORY.md index row:",
        f"- [{slug.replace('-', ' ')}](feedback_{slug}.md) — {row.class_id} guard ineffective across {rounds}",
        "",
    ))


def proposals_written(
    context: Context, recurred_ids: frozenset[str], reports: tuple[LaneReport, ...], registry: Registry, /
) -> Result[tuple[str, ...], Fault]:
    refs = tuple(Block.of_seq(tuple(row for report in reports for row in report.capability)).choose(roster_row))
    feds = tuple(row for row in registry.classes if row.recurrences >= 2 and row.landed_surfaces and row.class_id in recurred_ids)
    jobs: tuple[tuple[str, str], ...] = (
        *((f"reference_{slug}.md", reference_stub(slug, members, evidence, context.run.round)) for slug, members, evidence in refs),
        *((f"feedback_{slugged(row.class_id)}.md", feedback_stub(row)) for row in feds),
    )
    if not jobs:
        return Ok(())
    home = context.round_dir / PROPOSALS_DIR
    made = catch(exception=OSError)(home.mkdir)(exist_ok=True).map_error(lambda blocked: Fault(code="unwritable", detail=f"{home}: {blocked}"))
    return made.bind(lambda _made: traverse(lambda job: written(home / job[0], job[1].encode()).map(str), Block.of_seq(jobs)).map(tuple))


# --- [ROUND_LEDGER]


def reviewers_of(context: Context, /) -> tuple[Reviewer, ...]:
    if context.run.kind == "engine":
        return (context.run.reviewer,)
    loaded = Block.of_seq(context.run.sources).choose(lambda n: run_loaded(context.repo / STATE_DIR / f"round-{n:03d}").to_option())
    return tuple(dict.fromkeys(run.reviewer for run in loaded))


def corroboration_hist(repo: Path, rows: tuple[Finding, ...], /) -> dict[str, int]:
    pairs = tuple(
        (row.fingerprint, seen)
        for d in round_dirs(repo)
        for row in shaped(d / FINDINGS_NAME, tuple[Finding, ...]).default_value(())
        for seen in (row.reviewer, *row.corroborators)
    )
    index = {fp: frozenset(seen for _fp, seen in bunch) for fp, bunch in groupby(sorted(pairs), key=itemgetter(0))}
    return dict(Counter(str(len(index.get(row.fingerprint, frozenset({row.reviewer})))) for row in rows))


def lane_graded(lanes: tuple[LaneStat, ...], refuted: tuple[Refutation, ...], /) -> LaneGrade:
    verdicts = sum((Counter(stat.verdicts) for stat in lanes), Counter())
    fixed, upgraded = verdicts.get("fixed", 0), verdicts.get("upgraded", 0)

    def share(kept: int, /) -> float:
        return round(kept / len(lanes), 3)

    return LaneGrade(
        depth_of_fix=round(upgraded / (fixed + upgraded), 3) if fixed + upgraded else 0.0,
        scope_clean=share(sum(1 for stat in lanes if not stat.phantom)),
        refute_cited=round(sum(1 for entry in refuted if entry.evidence) / len(refuted), 3) if refuted else 1.0,
        gate_clean=share(sum(1 for stat in lanes if stat.gate_clean is True)),
        bijective=share(sum(1 for stat in lanes if stat.report_valid and not stat.missing and not stat.phantom)),
    )


def convergence_shares(hist: Mapping[str, int], survivors: int, pushed_back: int, /) -> tuple[float, float]:
    # The cross-round prune drops relitigation rows before findings.json lands, so both shares read the pre-prune histogram, never the survivors.
    dropped = hist.get("relitigation", 0) + hist.get("refuted_remint", 0)
    pool = survivors + dropped
    if pool == 0:
        return 0.0, 0.0
    return round((pushed_back + hist.get("refuted_remint", 0)) / pool, 3), round(hist.get("relitigation", 0) / pool, 3)


def prompt_prints(repo: Path, /) -> dict[str, str]:
    # Content hashes of the dispatch prompt surfaces, so a behavior delta between rounds is attributable to a prompt edit rather than asserted.
    sources = (*((name, BUNDLE / "templates" / name) for name in PROMPT_TEMPLATES), (PurePosixPath(AGENT_DEFINITION).name, repo / AGENT_DEFINITION))
    return {
        name: read_bytes(path).map(lambda payload: hashlib.sha256(payload).hexdigest()[:PROMPT_PRINT_WIDTH]).default_value("absent")
        for name, path in sources
    }


def wall_spread_of(stats: tuple[LaneStat, ...], /) -> WallSpread:
    walls = tuple(stat.wall_s for stat in stats if stat.wall_s > 0)
    if not walls:
        return WallSpread()
    mid = float(median(walls))
    return WallSpread(
        median_s=round(mid, 1),
        max_s=round(max(walls), 1),
        outliers=tuple(stat.lane for stat in stats if mid > 0 and stat.wall_s > WALL_OUTLIER_FACTOR * mid),
    )


def graded(stats: tuple[LaneStat, ...], reports: tuple[LaneReport, ...], /) -> dict[str, LaneGrade]:
    grouped = groupby(sorted((stat for stat in stats if stat.model), key=lambda stat: stat.model), key=lambda stat: stat.model)
    lanes_by_model = {model: tuple(bunch) for model, bunch in grouped}
    return {
        model: lane_graded(lanes, tuple(entry for report in reports if report.model.strip().casefold() == model for entry in report.refuted))
        for model, lanes in lanes_by_model.items()
    }


def row_built(
    context: Context,
    rows: tuple[Finding, ...],
    stats: tuple[LaneStat, ...],
    reports: tuple[LaneReport, ...],
    registry: Registry,
    drain: RoutingDrain,
    /,
) -> RoundRow:
    recurred, fresh = recurrence(registry, rows, reports)
    hist = shaped(context.round_dir / PROVENANCE_NAME, dict[str, int]).default_value({})
    own_ids = frozenset(row.id for row in rows if row.id)
    pushed = frozenset(entry.id for report in reports for entry in report.ledger if entry.verdict == "pushed-back" and entry.id) & own_ids
    fp_share, relitigation_share = convergence_shares(hist, len(rows), len(pushed))
    by_verdict = {entry.id: entry.verdict for report in reports for entry in report.ledger if entry.id}
    novel = tuple(row for row in rows if row.provenance in NOVEL_PROVENANCE)
    grouped = groupby(sorted((stat for stat in stats if stat.model), key=lambda stat: stat.model), key=lambda stat: stat.model)
    by_model = {model: dict(sum((Counter(stat.verdicts) for stat in bunch), Counter())) for model, bunch in grouped}
    return RoundRow(
        round=context.run.round,
        reviewer=context.run.reviewer,
        reviewers=reviewers_of(context),
        scope=context.run.scope.line,
        counts_by_severity=counted(rows),
        total=len(rows),
        lanes=stats,
        recurred_classes=tuple(class_id for class_id, _ in recurred),
        new_classes=len(fresh),
        routed=sum(len(report.routing) + len(report.uncertain) for report in reports),
        capability_rows=sum(len(report.capability) for report in reports),
        provenance_by_kind=hist,
        corroboration_histogram=corroboration_hist(context.repo, rows),
        commit=sh(("git", "-C", str(context.repo), "rev-parse", "--short", "HEAD")).default_with(lambda _f: ""),
        at=round(time.time(), 1),
        focus=context.run.focus,
        fp_share=fp_share,
        relitigation_share=relitigation_share,
        novel_quality=round(sum(1 for row in novel if by_verdict.get(row.id) in ACCEPTED_VERDICTS) / len(novel), 3) if novel else 0.0,
        hunt_axis_fire=dict(Counter(entry.axis for report in reports for entry in report.improvements if entry.axis)),
        by_model=by_model,
        grades=graded(stats, reports),
        shape_fire=dict(Counter(entry.shape for report in reports for entry in report.ledger if entry.shape)),
        routing=drain,
        wall_spread=wall_spread_of(stats),
        prompts=prompt_prints(context.repo),
    )


def delta_of(prior: RoundRow | None, row: RoundRow, /) -> Delta | None:
    if prior is None:
        return None
    return Delta(
        prior_round=prior.round,
        total_delta=row.total - prior.total,
        by_severity={
            level: row.counts_by_severity.get(level, 0) - prior.counts_by_severity.get(level, 0)
            for level in SEVERITIES
            if level in row.counts_by_severity or level in prior.counts_by_severity
        },
        recurred_still=tuple(class_id for class_id in row.recurred_classes if class_id in prior.recurred_classes),
    )


# --- [VERIFY_SURFACES]


def cr_instruction_blocks(node: object, /) -> tuple[tuple[str, str], ...]:
    match node:
        case {"path_instructions": list() as blocks, **rest}:
            own = tuple(
                (str(stringly(entry).get("path", "")), str(stringly(entry).get("instructions", ""))) for entry in blocks if isinstance(entry, dict)
            )
            return (*own, *cr_instruction_blocks(list(rest.values())))
        case dict() as body:
            return cr_instruction_blocks(list(body.values()))
        case list() as items:
            return tuple(pair for item in items for pair in cr_instruction_blocks(item))
        case _:
            return ()


def cr_verified(repo: Path, guard: SurfaceGuard, /) -> VerifyReceipt:
    path = repo / (guard.path or ".coderabbit.yaml")
    blocks = yaml_loaded(path).map(cr_instruction_blocks).default_with(lambda _f: ())
    hit = next(((glob, text) for glob, text in blocks if guard.text and guard.text.casefold() in text.casefold()), None)
    return VerifyReceipt(rule=guard.text, path=str(path), effective=hit is not None, matched=hit[0] if hit else "", source="path_instructions")


def gt_verified(repo: Path, rule: str, path: str, /) -> VerifyReceipt:
    # `greptile config` truncates each rendered rule with an ellipsis and a bare invocation resolves at repo root where scoped rules never apply,
    # so a cascade miss falls through to full-text over the config surfaces; the receipt's source names the oracle that matched.
    needle = rule.casefold()
    argv = ("greptile", "config", *((path,) if path else ()))

    def excerpted(text: str, /) -> Option[str]:
        at = text.casefold().find(needle)
        if at < 0:
            return Nothing
        stop = held if (held := text.find("\n", at)) >= 0 else len(text)
        return Some(plain(text[text.rfind("\n", 0, at) + 1 : stop]))

    oracles: tuple[tuple[str, Callable[[], str]], ...] = (
        (shlex.join(argv), lambda: sh(argv, cwd=repo).map(lambda held: ANSI_RE.sub("", held)).default_with(lambda _f: "")),
        *(
            (name, lambda file=repo / name: read_bytes(file).map(lambda raw: raw.decode(errors="replace")).default_with(lambda _f: ""))
            for name in GT_ORACLE_FILES
        ),
    )

    def probed(source: str, texted: Callable[[], str], /) -> Option[VerifyReceipt]:
        return excerpted(texted()).map(lambda line: VerifyReceipt(rule=rule, path=path, effective=True, matched=line, source=source))

    hit: Option[VerifyReceipt] = next((found for source, texted in oracles if (found := probed(source, texted)).is_some()), Nothing)
    return hit.default_with(
        lambda: VerifyReceipt(rule=rule, path=path, effective=False, matched="", source=" -> ".join(source for source, _texted in oracles))
    )


def ms_verified(repo: Path, guard: SurfaceGuard, /) -> VerifyReceipt:
    # Ledger paths are repo-relative like every other surface; a topic-file path written relative to `.macroscope/` resolves the same target.
    home = repo / MS_HOME

    def texted(target: Path, /) -> str:
        return read_bytes(target).map(lambda raw: raw.decode(errors="replace")).default_with(lambda _f: "") if target.is_file() else ""

    if guard.path:
        held = PurePosixPath(guard.path)
        target = repo / guard.path if held.parts[:1] == (MS_HOME,) else home / guard.path
        effective = guard.text.casefold() in texted(target).casefold()
        return VerifyReceipt(
            rule=guard.text, path=str(target), effective=effective, matched=str(target) if effective else "", source="macroscope-topic-file"
        )
    hits = tuple(path for path in sorted(home.rglob("*.md")) if guard.text.casefold() in texted(path).casefold())
    return VerifyReceipt(rule=guard.text, path=str(home), effective=bool(hits), matched=str(hits[0]) if hits else "", source="macroscope-topic-scan")


def surface_checked(repo: Path, guard: SurfaceGuard, /) -> VerifyReceipt:
    # A textless row proves nothing on any oracle; naming it malformed keeps `effective: false` meaning failed wording alone.
    if not guard.text.strip():
        return VerifyReceipt(rule=guard.text, path=guard.path, effective=False, matched="row carries no guard text", source="surface-ledger")
    match REVIEWER_ALIASES.get(guard.surface.strip().lower()):
        case "coderabbit":
            return cr_verified(repo, guard)
        case "greptile":
            return gt_verified(repo, guard.text, guard.path)
        case "macroscope":
            return ms_verified(repo, guard)
        case _:
            return VerifyReceipt(
                rule=guard.text, path=guard.path, effective=False, matched=f"unknown surface {guard.surface!r}", source="surface-ledger"
            )


def round_verified(context: Context, /) -> Result[tuple[VerifyReceipt, ...], Fault]:
    ledger = context.round_dir / SURFACE_LEDGER_NAME
    if not ledger.is_file():
        return Error(
            Fault(code="no-report", detail=f"{ledger} absent; the orchestrator persists the reviewer-harvest surface ledger before verify --round")
        )
    return (
        read_bytes(ledger)
        .bind(lambda payload: decoded(payload, tuple[SurfaceGuard, ...], str(ledger)))
        .map(lambda guards: tuple(surface_checked(context.repo, guard) for guard in guards))
    )


# --- [REGISTRY_GUARD]

ROW_FIELDS: Final[frozenset[str]] = frozenset(RefutedClass.__struct_fields__)


def class_entries(parsed: object, origin: str, /) -> Result[tuple[object, ...], Fault]:
    match parsed:
        case {"classes": list() as items}:
            return Ok(tuple(items))
        case list() as items:
            return Ok(tuple(items))
        case None:
            return Ok(())
        case _:
            return Error(Fault(code="malformed", detail=f"{origin}: expected a top-level classes: row list (or a bare row list)"))


def entries_of(path: Path, /) -> Result[tuple[object, ...], Fault]:
    return yaml_loaded(path).bind(lambda parsed: class_entries(parsed, str(path)))


def proposed_entries(path: Path, /) -> Result[tuple[object, ...], Fault]:
    return entries_of(path).bind(
        lambda entries: Ok(entries) if entries else Error(Fault(code="no-payload", detail=f"{path}: zero proposed rows under classes:"))
    )


def matcher_faults(row: RefutedClass, /) -> tuple[Fault, ...]:
    # Loud complement of lenient_pattern: classification degrades an invalid matcher to a literal, so this gate is where a broken regex surfaces.
    return tuple(
        Block.of_seq(row.matchers).choose(
            lambda matcher: (
                catch(exception=re.PatternError)(re.compile)(matcher, re.IGNORECASE)
                .swap()
                .to_option()
                .map(lambda broken: Fault(code="bad-matcher", detail=f"{matcher!r}: {broken}"))
            )
        )
    )


def row_checked(at: int, entry: object, taken: frozenset[str], /) -> RowVerdict:
    if not isinstance(entry, dict):
        return RowVerdict(at=at, class_id="", faults=(Fault(code="malformed", detail=f"row {at}: not a class mapping"),))
    try:
        row = msgspec.convert(entry, type=RefutedClass, strict=True)
    except msgspec.ValidationError as drift:
        return RowVerdict(at=at, class_id=str(entry.get("class_id", "")), faults=(Fault(code="malformed", detail=f"row {at}: {drift}"),))
    alien = frozenset(str(key) for key in entry) - ROW_FIELDS  # convert ignores unknown keys, so the field-set difference is the loud check
    return RowVerdict(
        at=at,
        class_id=row.class_id,
        faults=(
            *((Fault(code="unknown-key", detail=", ".join(sorted(alien))),) if alien else ()),
            *((Fault(code="empty-class", detail=f"row {at}: class_id is empty"),) if not row.class_id else ()),
            *((Fault(code="no-matchers", detail=f"{row.class_id}: a row with no matchers never fires"),) if not row.matchers else ()),
            *matcher_faults(row),
            *(
                (Fault(code="duplicate-class", detail=f"{row.class_id}: already registered — a matcher merge is a human edit"),)
                if row.class_id and row.class_id in taken
                else ()
            ),
        ),
    )


def rows_checked(entries: tuple[object, ...], standing: frozenset[str], /) -> tuple[RowVerdict, ...]:
    def stepped(acc: tuple[frozenset[str], tuple[RowVerdict, ...]], pair: tuple[int, object], /) -> tuple[frozenset[str], tuple[RowVerdict, ...]]:
        taken, verdicts = acc
        verdict = row_checked(pair[0], pair[1], taken)
        return taken | ({verdict.class_id} if verdict.class_id else set()), (*verdicts, verdict)

    seed: tuple[frozenset[str], tuple[RowVerdict, ...]] = (standing, ())
    return reduce(stepped, tuple(enumerate(entries, start=1)), seed)[1]


def check_built(path: Path, standing: frozenset[str], entries: tuple[object, ...], /) -> RegistryCheckReceipt:
    verdicts = rows_checked(entries, standing)
    faulted = tuple(verdict for verdict in verdicts if verdict.faults)
    return RegistryCheckReceipt(path=str(path), standing=len(standing), rows=len(entries), clean=len(verdicts) - len(faulted), faulted=faulted)


def registry_checked(rows_spec: str, /) -> Result[RegistryCheckReceipt, Fault]:
    if not rows_spec:
        if not REGISTRY_PATH.is_file():
            return Ok(check_built(REGISTRY_PATH, frozenset(), ()))
        return entries_of(REGISTRY_PATH).map(lambda entries: check_built(REGISTRY_PATH, frozenset(), entries))
    path = Path(rows_spec)
    return registry_loaded().bind(
        lambda registry: proposed_entries(path).map(lambda entries: check_built(path, frozenset(row.class_id for row in registry.classes), entries))
    )


def registry_applied(rows_path: Path, /) -> Result[RegistryApplyReceipt, Fault]:
    def admitted(entries: tuple[object, ...], registry: Registry, /) -> Result[tuple[RefutedClass, ...], Fault]:
        verdicts = rows_checked(entries, frozenset(row.class_id for row in registry.classes))
        faulted = tuple(verdict for verdict in verdicts if verdict.faults)
        if faulted:
            roster = "; ".join(
                f"row {held.at} ({held.class_id or '<unnamed>'}): {', '.join(fault.code for fault in held.faults)}" for held in faulted
            )
            return Error(
                Fault(
                    code="malformed",
                    detail=f"{rows_path}: {len(faulted)}/{len(verdicts)} rows refused — {roster}; `registry --check --rows` details each fault",
                )
            )
        return Ok(tuple(msgspec.convert(entry, type=RefutedClass, strict=True) for entry in entries))

    def landed(rows: tuple[RefutedClass, ...], /) -> Result[RegistryApplyReceipt, Fault]:
        held: Result[object, Fault] = yaml_loaded(REGISTRY_PATH, codec=YAML_RT) if REGISTRY_PATH.is_file() else Ok({"classes": []})

        def grown(doc: object, /) -> Result[RegistryApplyReceipt, Fault]:
            match doc:
                case {"classes": list() as standing}:
                    standing.extend(msgspec.to_builtins(row) for row in rows)  # in-place append on the round-trip tree keeps comments and quotes
                    sink = io.StringIO()
                    YAML_RT.dump(doc, sink)
                    return written(REGISTRY_PATH, sink.getvalue().encode()).map(
                        lambda _path: RegistryApplyReceipt(
                            path=str(REGISTRY_PATH), appended=tuple(row.class_id for row in rows), standing=len(standing)
                        )
                    )
                case _:
                    return Error(Fault(code="malformed", detail=f"{REGISTRY_PATH}: expected a top-level classes: list"))

        return held.bind(grown)

    return registry_loaded().bind(lambda registry: proposed_entries(rows_path).bind(lambda entries: admitted(entries, registry)).bind(landed))


# --- [SELFTEST]


def selftest_fixture() -> tuple[bytes, bytes]:
    # Maximal-shape lane report: every field populated at the richest spelling the templates/fix.md output contract admits, the null variant derived from it —
    # one primary, so a contract change edits one site and both variants follow.
    primary: dict[str, object] = {
        "ledger": [
            {"id": "r9a-01", "file": "docs/<file-a>.md", "severity": "major", "verdict": "fixed", "note": "<repair>", "shape": "substitution"},
            {"id": "r9a-02", "file": "libs/<file-b>.py", "severity": "minor", "verdict": "pushed-back", "note": "<refusal>"},
            {
                "id": "r9a-03",
                "file": "libs/<file-b>.py",
                "severity": "critical",
                "verdict": "already_resolved",
                "note": "<prior>",
                "shape": "completion",
            },
            {"id": "r9a-04", "file": "libs/<file-b>.py", "severity": "trivial", "verdict": "upgraded", "note": "<collapse>", "shape": "collapse"},
        ],
        "improvements": [
            {"page": "docs/<file-a>.md", "pattern": "<pattern-a>", "what": "<upgrade-a>", "axis": "hunt-axis:<axis-a>"},
            {"page": "libs/<file-b>.py", "pattern": "<pattern-b>", "what": "<upgrade-b>", "axis": ""},
        ],
        "refuted": [{"claim": "<claim-a>", "evidence": "<citation-a>"}],
        "capability": [{"page": "docs/<file-a>.md", "pattern": "<roster-a>", "members": ["<member-a>", "<member-b>"]}, "<capability-line>"],
        "routing": [{"target_file": "libs/<file-c>.py", "needed_change": "<change>"}],
        "uncertain": ["<open-question>"],
        "files": ["docs/<file-a>.md", "libs/<file-b>.py"],
        "gate_clean": True,
        "model": "<model>",
        "wall_s": 1.5,
    }
    nulled = {**primary, **dict.fromkeys(("ledger", "improvements", "refuted", "capability", "routing", "uncertain", "files", "gate_clean"))}
    return ENCODER.encode(primary), ENCODER.encode(nulled)


def registry_proofs() -> tuple[tuple[str, bool], ...]:
    template: dict[str, object] = {
        "class_id": "<class-a>",
        "corpus": "code",
        "matchers": [r"claim.{0,20}pattern"],
        "refuting_citation": "<citation-a>",
        "landed_surfaces": [".coderabbit.yaml"],
        "recurrences": 2,
    }
    entries: tuple[object, ...] = (
        template,
        {**template, "class_id": "<class-b>", "matchers": ["broken[("]},
        {**template},
        {**template, "class_id": "<class-c>", "surface": "<alien>"},
        {**template, "class_id": "<standing-a>"},
        "<not-a-mapping>",
    )
    fired = tuple(tuple(fault.code for fault in verdict.faults) for verdict in rows_checked(entries, frozenset({"<standing-a>"})))
    return (
        ("registry-clean-row-passes", fired[0] == ()),
        ("registry-bad-matcher-loud", fired[1] == ("bad-matcher",)),
        ("registry-intra-duplicate-loud", fired[2] == ("duplicate-class",)),
        ("registry-unknown-key-loud", fired[3] == ("unknown-key",)),
        ("registry-standing-duplicate-loud", fired[4] == ("duplicate-class",)),
        ("registry-shape-drift-loud", fired[5] == ("malformed",)),
    )


def mint_proofs() -> tuple[tuple[str, bool], ...]:
    preamble = ENGINE_PREAMBLES[0]
    span = Range(start=3, end=4)

    def fixed_as(fix: str, /) -> Option[Finding]:
        return minted("coderabbit", "libs/<file-b>.py", span, "<claim-a>", fix, "major")

    stripped = fixed_as(f"{preamble}\n\n<repair>")
    bare = fixed_as(preamble)
    clean = fixed_as("<repair>")
    poisoned_claim = minted("coderabbit", "libs/<file-b>.py", span, preamble, "<repair>", "major")
    return (
        ("mint-strips-engine-preamble", stripped.map(lambda row: row.fix_instructions == "<repair>").default_value(value=False)),
        ("mint-preamble-only-fix-inactionable", bare.map(lambda row: not row.fix_instructions and not row.actionable).default_value(value=False)),
        (
            "mint-fingerprint-preamble-blind",
            stripped.map2(lambda left, right: left.fingerprint == right.fingerprint, clean).default_value(value=False),
        ),
        ("mint-preamble-only-claim-empties", poisoned_claim.map(lambda row: not row.claim).default_value(value=False)),
    )


def selftest_finding(file: str, at: int, /) -> Finding:
    return Finding(
        id=f"r9a-{at:02d}",
        fingerprint=f"<fp-{at}>",
        reviewer="coderabbit",
        file=file,
        range=Range(start=at, end=at + 1),
        severity="major",
        claim="<claim-a>",
        fix_instructions="<repair>",
        class_match="",
    )


def query_proofs() -> tuple[tuple[str, bool], ...]:
    row = selftest_finding("libs/<file-b>.py", 1)

    def hit(scope: str, pattern: str, /) -> bool:
        return len(queried((row,), Nothing, "", Some(lenient_pattern(pattern)), SEARCH_SCOPES[scope])) == 1

    return (
        ("query-claim-scope-blind-to-fix", not hit("claim", "repair") and hit("fix", "repair") and hit("both", "repair")),
        ("query-fix-scope-blind-to-claim", not hit("fix", "claim-a") and hit("claim", "claim-a") and hit("both", "claim-a")),
    )


def slice_proofs() -> tuple[tuple[str, bool], ...]:
    weigh = row_weigher("count", Path(), ())
    chain = partitioned((selftest_finding("libs", 1), selftest_finding("libs/x.py", 2), selftest_finding("libs/x.py/y", 3)), 2, weigh)
    fileless = partitioned((selftest_finding("", 1), selftest_finding("libs/x.py", 2)), 2, weigh)
    return (
        ("partition-prefix-chain-terminates", len(chain) >= 2),
        ("partition-fileless-bucketed", len(fileless) == 2 and any(held.label == "<unanchored>" for held in fileless)),
    )


def stream_proofs() -> tuple[tuple[str, bool], ...]:
    prelude = "[\n" + ",\n".join("[1]" for _ in range(JSON_SCAN_CAP + 16)) + "\n]"
    envelope = '{"comments": [{"id": "a", "path": "<p>", "body": "<b>"}]}'
    grown = '{"comments": [{"id": "b", "path": "<p>", "body": "<b>"}, {"id": "c", "path": "<p>", "body": "<b>"}]}'
    return (
        ("stream-pretty-prelude-survives", greptile_payload(f"{prelude}\n{envelope}", "<selftest>").map(len) == Ok(1)),
        ("stream-last-envelope-wins", greptile_payload(f"{envelope}\n{grown}", "<selftest>").map(len) == Ok(2)),
    )


def routing_proofs() -> tuple[tuple[str, bool], ...]:
    pairs = (
        ("lane-a", LaneReport(routing=(msgspec.Raw(b'{"target_file": "libs/<file-c>.py", "needed_change": "<change-a>"}'),))),
        ("lane-b", LaneReport(routing=(msgspec.Raw(b'{"target_file": "docs/<file-d>.md", "needed_change": "<change-b>"}'),))),
    )
    rows = routing_mined(pairs)
    closers = (CloserReport(rows=(LedgerRow(id="a:libs/<file-c>.py", verdict="landed"),), files=("libs/<file-c>.py",)),)
    drain = routing_drained(rows, closers)
    bare = routing_drained(rows, (CloserReport(rows=(LedgerRow(id="docs/<file-d>.md", verdict="refuted"),)),))
    cut = closer_sliced(rows, 2, "coderabbit")
    flat = tuple(file for slice_ in cut for file in slice_.manifest.files)
    deferred = replace(drain, deferred=True)
    return (
        ("routing-rows-mined-keyed", tuple(row.key for row in rows) == ("a:libs/<file-c>.py", "b:docs/<file-d>.md")),
        ("routing-drain-counts", (drain.total, drain.drained) == (2, 1) and tuple(row.key for row in drain.pending) == ("b:docs/<file-d>.md",)),
        ("routing-drain-verdicts", drain.verdicts == {"landed": 1}),
        ("routing-drain-bare-file-id", bare.drained == 1 and tuple(row.key for row in bare.pending) == ("a:libs/<file-c>.py",)),
        ("closer-territories-disjoint", len(cut) == 2 and len(flat) == len(set(flat))),
        ("closer-cut-keeps-keys", tuple(sorted(row.id for slice_ in cut for row in slice_.findings)) == ("a:libs/<file-c>.py", "b:docs/<file-d>.md")),
        ("routing-deferral-recorded", deferred.deferred and deferred.pending == drain.pending),
    )


def spawn_proofs() -> tuple[tuple[str, bool], ...]:
    true_call = (
        b'{"timestamp":"<t>","type":"response_item",'
        b'"payload":{"type":"function_call","name":"spawn_agent","arguments":"{\\"task_name\\":\\"miner_a\\"}"}}'
    )
    echo = b'{"type":"response_item","payload":{"type":"message","text":"plan: call spawn_agent twice"}}'
    event = b'{"type":"event_msg","payload":{"type":"function_call","name":"spawn_agent","arguments":"{}"}}'
    head = decoded(b'{"type":"thread.started","thread_id":"<uuid-a>"}', EventHead, "<selftest>")
    return (
        ("spawn-grep-filters-echoes", spawn_scanned([true_call, echo, event]) == (1, ("miner_a",))),
        ("spawn-thread-head-decodes", head.map(lambda held: held.thread_id) == Ok("<uuid-a>")),
    )


def fill_proofs() -> tuple[tuple[str, bool], ...]:
    return (
        (
            "tiers-package-resolves",
            tiers_of("libs/csharp/<package-a>/<file>.cs") == ("libs/csharp/<package-a>", "libs/csharp/.api", "docs/stacks/csharp"),
        ),
        ("tiers-substrate-only", tiers_of("libs/python/<file>.py") == ("", "libs/python/.api", "docs/stacks/python")),
        ("tiers-tests-substrate", tiers_of("tests/typescript/<file>.ts") == ("", "tests/typescript/.api", "docs/stacks/typescript")),
        ("tiers-unplaced", tiers_of("docs/<file>.md") == ("", "", "")),
    )


def rollup_proofs() -> tuple[tuple[str, bool], ...]:
    def stat_of(lane: str, wall: float, /) -> LaneStat:
        return LaneStat(lane=lane, model="<model-a>", findings=1, verdicts={}, missing=(), phantom=(), wall_s=wall, report_valid=True)

    spread = wall_spread_of((stat_of("lane-a", 10.0), stat_of("lane-b", 12.0), stat_of("lane-c", 40.0)))
    prints = prompt_prints(Path("<no-repo>"))
    hex_digits = set("0123456789abcdef")
    return (
        ("wall-spread-outlier-rule", spread == WallSpread(median_s=12.0, max_s=40.0, outliers=("lane-c",))),
        ("wall-spread-empty-total", wall_spread_of(()) == WallSpread()),
        ("prompt-prints-keyed", set(prints) == {*PROMPT_TEMPLATES, PurePosixPath(AGENT_DEFINITION).name}),
        ("prompt-prints-hash-or-absent", all(v == "absent" or (len(v) == PROMPT_PRINT_WIDTH and set(v) <= hex_digits) for v in prints.values())),
        ("bundle-registry-derives", REGISTRY_PATH == BUNDLE / "templates" / "refuted-classes.yaml"),
    )


def grade_proofs() -> tuple[tuple[str, bool], ...]:
    def stat_of(lane: str, verdicts: dict[str, int], phantom: tuple[str, ...], /, *, gate: bool) -> LaneStat:
        return LaneStat(
            lane=lane, model="<model-a>", findings=2, verdicts=verdicts, missing=(), phantom=phantom, wall_s=1.0, report_valid=True, gate_clean=gate
        )

    stats = (
        stat_of("lane-a", {"fixed": 1, "upgraded": 1}, (), gate=True),
        stat_of("lane-b", {"fixed": 1, "pushed-back": 1}, ("r9b-09",), gate=False),
    )
    reports = (LaneReport(refuted=(Refutation(claim="<claim-a>", evidence="<citation-a>"), Refutation(claim="<claim-b>")), model="<model-a>"),)
    held = graded(stats, reports).get("<model-a>")
    expected = LaneGrade(depth_of_fix=0.333, scope_clean=0.5, refute_cited=0.5, gate_clean=0.5, bijective=0.5)
    vacuous = LaneGrade(depth_of_fix=0.333, scope_clean=0.5, refute_cited=1.0, gate_clean=0.5, bijective=0.5)
    return (
        ("grades-five-axes-computed", held == expected),
        ("grades-vacuous-refute-full-marks", lane_graded(stats, ()) == vacuous),
        ("auto-lanes-clamps", (auto_lanes(1), auto_lanes(LANE_LOAD), auto_lanes(LANE_LOAD + 1), auto_lanes(10_000)) == (1, 1, 2, LANES_CAP)),
        ("convergence-shares-read-histogram", convergence_shares({"relitigation": 30, "refuted_remint": 10, "new_work": 60}, 60, 5) == (0.15, 0.3)),
    )


def selftest_proofs() -> tuple[tuple[str, bool], ...]:
    primary, nulled = selftest_fixture()
    full = report_decoded(primary, LaneReport, "<selftest-primary>")
    empty = report_decoded(nulled, LaneReport, "<selftest-null>")
    broken = report_decoded(b'{"ledger": 7}', LaneReport, "<selftest-broken>")

    def full_proofs(report: LaneReport, /) -> tuple[tuple[str, bool], ...]:
        rosters = tuple(Block.of_seq(report.capability).choose(roster_row))
        recurred, fresh = recurrence(Registry(), (), (report,))
        lines = improvement_lines((report,))
        return (
            ("ledger-verdicts-cover-contract", {row.verdict for row in report.ledger} == ACCEPTED_VERDICTS | {"pushed-back"}),
            ("improvement-axis-duality", {bool(row.axis) for row in report.improvements} == {True, False}),
            ("refuted-populated", bool(report.refuted)),
            ("capability-raw-projects", all(raw_text(row) for row in report.capability)),
            ("capability-roster-mined", len(rosters) == 1),
            ("routing-populated", bool(report.routing)),
            ("uncertain-populated", bool(report.uncertain)),
            ("report-files-surface", report.files == ("docs/<file-a>.md", "libs/<file-b>.py")),
            (
                "ledger-shape-mix",
                dict(Counter(row.shape or "unstamped" for row in report.ledger))
                == {"substitution": 1, "unstamped": 1, "completion": 1, "collapse": 1},
            ),
            ("gate-clean-true", report.gate_clean is True),
            ("fresh-refutations-surface", not recurred and len(fresh) == len(report.refuted)),
            ("improvements-group-by-axis", any(line.startswith("### [hunt-axis:") for line in lines) and "### [general]" in lines),
        )

    def empty_proofs(report: LaneReport, /) -> tuple[tuple[str, bool], ...]:
        drained = (report.ledger, report.improvements, report.refuted, report.capability, report.routing, report.uncertain, report.files)
        return (("null-collections-default-empty", not any(drained)), ("null-gate-clean-none", report.gate_clean is None))

    return (
        ("primary-decodes", full.is_ok()),
        ("null-variant-decodes", empty.is_ok()),
        ("malformed-faults-loud", broken.swap().to_option().map(lambda fault: fault.code == "malformed").default_value(value=False)),
        *full.map(full_proofs).default_value(()),
        *empty.map(empty_proofs).default_value(()),
        *registry_proofs(),
        *mint_proofs(),
        *query_proofs(),
        *slice_proofs(),
        *stream_proofs(),
        *routing_proofs(),
        *spawn_proofs(),
        *fill_proofs(),
        *rollup_proofs(),
        *grade_proofs(),
    )


# --- [COMPOSITION] ----------------------------------------------------------------------


@dataclass(frozen=True, slots=True, kw_only=True)
class Adapter:
    scopes: frozenset[ScopeKind]
    armed: Callable[[Scope], tuple[str, ...]]
    preflight: Callable[[Path, Scope], Result[tuple[str, ...], Fault]]
    focused: Callable[[str, Path], Result[tuple[str, ...], Fault]]
    markers: Markers
    harvested: Callable[[Context], Result[tuple[Finding, ...], Fault]]
    source: Callable[[Context], str]
    accepts_focus: bool = True  # a False row refuses --focus before the preflight's side effects run; `focused` stays the defensive arm


def base_resolved(repo: Path, /) -> Result[str, Fault]:
    git = ("git", "-C", str(repo))

    def real(candidate: str, /) -> Option[str]:
        held = candidate.strip()
        if not held:
            return Nothing
        return Some(held) if sh((*git, "rev-parse", "--verify", "--quiet", held)).map(lambda _sha: True).default_with(lambda _f: False) else Nothing

    ladder = Block.of_seq((
        sh((*git, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")).default_with(lambda _f: ""),
        sh((*git, "symbolic-ref", "--short", "refs/remotes/origin/HEAD")).default_with(lambda _f: ""),
        sh((*git, "config", "coderabbit.baseBranch")).default_with(lambda _f: ""),
        "main",
        "master",
    )).choose(real)
    return Ok(ladder.head()) if not ladder.is_empty() else Error(Fault(code="no-base", detail=CR_BASE_REMEDY))


def cr_argv(scope: Scope, /) -> tuple[str, ...]:
    match scope.kind:
        case "base":
            return ("coderabbit", "review", "--agent", "--base", scope.ref)
        case "base-commit":
            return ("coderabbit", "review", "--agent", "--base-commit", scope.ref)
        case kind:
            return ("coderabbit", "review", "--agent", "-t", str(kind))


def greptile_argv(scope: Scope, /) -> tuple[str, ...]:
    return ("greptile", "review", "--json", *(("-b", scope.ref) if scope.kind in REF_KINDS else ()))


def ms_argv(scope: Scope, /) -> tuple[str, ...]:
    return ("macroscope", "codereview", "--raw", "--in-place", *(("--base", scope.ref) if scope.kind == "base" else ()))


def cr_preflight(repo: Path, scope: Scope, /) -> Result[tuple[str, ...], Fault]:
    if scope.kind in REF_KINDS:
        return Ok(())
    return base_resolved(repo).map(lambda base: ("--base", base))


def gt_preflight(_repo: Path, _scope: Scope, /) -> Result[tuple[str, ...], Fault]:
    return Ok(())


def ms_preflight(repo: Path, _scope: Scope, /) -> Result[tuple[str, ...], Fault]:
    swept_worktrees(repo, None)
    return Ok(())


def cr_focused(text: str, round_dir: Path, /) -> Result[tuple[str, ...], Fault]:
    return written(round_dir / FOCUS_NAME, text.encode()).map(lambda path: ("-c", str(path)))


def greptile_focused(text: str, _round_dir: Path, /) -> Result[tuple[str, ...], Fault]:
    return Ok(("--instructions", text))


def ms_focused(_text: str, _round_dir: Path, /) -> Result[tuple[str, ...], Fault]:
    return Error(
        Fault(code="unsupported-focus", detail="macroscope has no per-run instruction flag; land the concern as .macroscope/ config, then relaunch")
    )


def levers_armed(reviewer: Reviewer, levers: Levers, /) -> Result[tuple[str, ...], Fault]:
    asked = frozenset(name for name, on in (("light", levers.light), ("resume", levers.resume), ("include", bool(levers.include))) if on)
    illegal = asked - LEVER_ROWS[reviewer]
    if illegal:
        flags = "/".join(sorted(f"--{name}" for name in illegal))
        return Error(
            Fault(code="bad-flag", detail=f"{flags} not valid for {reviewer}: --light is coderabbit-only; --resume/--include are greptile-only")
        )
    return Ok((
        *(("--light",) if levers.light else ()),
        *(("--resume",) if levers.resume else ()),
        *(("--include", *levers.include) if levers.include else ()),
    ))


NETWORK_SIG: Final = FaultSig(
    pattern=re.compile(r"ECONN|ETIMEDOUT|websocket|network error", re.IGNORECASE), signature="network", remedy="check connectivity; relaunch"
)
CR_SIGS: Final[tuple[FaultSig, ...]] = (
    FaultSig(
        pattern=re.compile(r"Unable to determine base branch|gitService\.getBranchInfo", re.IGNORECASE),
        signature="base-unresolvable",
        remedy="set --base, git config coderabbit.baseBranch, or origin/HEAD",
        nonzero_only=False,
    ),
    FaultSig(
        pattern=re.compile(r'"type"\s*:\s*"error"'),
        signature="engine-error",
        remedy="read the error message; usually transient — relaunch",
        nonzero_only=False,
    ),
    FaultSig(
        pattern=re.compile(r"rate limit|too many reviews", re.IGNORECASE), signature="rate-limited", remedy="wait the rolling-hour window, relaunch"
    ),
    FaultSig(
        pattern=re.compile(r"unauthorized|auth.*expired|login required", re.IGNORECASE),
        signature="auth-failed",
        remedy="coderabbit auth login --api-key $CODERABBIT_API_KEY",
    ),
    NETWORK_SIG,
)
GT_SIGS: Final[tuple[FaultSig, ...]] = (
    FaultSig(
        pattern=re.compile(r"too large to send|this review touches \d+ files|this review changes \d+ .*config files", re.IGNORECASE),
        signature="oversized",
        remedy=(
            "client-side caps — 500 changed files, 50 config files, 3000000 payload bytes (U3 patches + paths + commit messages + config +"
            " instructions); slice commits and review each vs the prior boundary"
        ),
    ),
    FaultSig(
        pattern=re.compile(r"no committed code changes to review", re.IGNORECASE),
        signature="empty-diff",
        remedy="nothing committed past the base — a clean empty round, zero findings",
    ),
    FaultSig(
        pattern=re.compile(r"every committed change was held back", re.IGNORECASE),
        signature="engine-error",
        remedy="relaunch with --include naming the held-back files",
    ),
    FaultSig(
        pattern=re.compile(r"billing|per-use CLI reviews|require a paid plan|monthly flex usage limit|reviews are not enabled", re.IGNORECASE),
        signature="billing",
        remedy="configure per-use CLI-review billing",
    ),
    FaultSig(
        pattern=re.compile(r"rate limit|too many reviews|daily review limit|Greptile is busy", re.IGNORECASE),
        signature="rate-limited",
        remedy="wait the rolling window, relaunch",
    ),
    FaultSig(
        pattern=re.compile(r"not indexed|not connected to Greptile|could not recognize this repository", re.IGNORECASE),
        signature="not-indexed",
        remedy="connect the repo in the Greptile dashboard, then retry",
    ),
    FaultSig(
        pattern=re.compile(
            r"GREPTILE_API_KEY|unauthorized|not signed in|API key invalid|session expired|authorization expired|sign-in needs permission",
            re.IGNORECASE,
        ),
        signature="auth-failed",
        remedy="re-auth `greptile login`; check GREPTILE_API_KEY",
    ),
    FaultSig(
        pattern=re.compile(r"could not find (?:the )?(?:base|default) branch|does not share history|unknown revision|detached HEAD", re.IGNORECASE),
        signature="base-unresolvable",
        remedy="pass a resolvable -b <base> (any committish) from a checked-out branch",
    ),
    FaultSig(
        pattern=re.compile(r"could not start the review|did not start within \d+ seconds", re.IGNORECASE),
        signature="no-start",
        remedy="transient start failure; relaunch",
    ),
    NETWORK_SIG,
)
MS_SIGS: Final[tuple[FaultSig, ...]] = (
    FaultSig(
        pattern=re.compile(r"^error: no objects found", re.IGNORECASE),
        signature="empty-diff",
        remedy="nothing to review — a clean empty round, zero findings",
    ),
    FaultSig(
        pattern=re.compile(r"FailedPrecondition|force.?requires? latest binary|update.*required", re.IGNORECASE),
        signature="stale-binary",
        remedy="update the BINARY from the GitHub release URL (never `macroscope update`)",
        nonzero_only=False,
    ),
    FaultSig(
        pattern=re.compile(r"A terminal is required", re.IGNORECASE),
        signature="tty-required",
        remedy="run non-interactively; ensure --raw, no updater prompt",
        nonzero_only=False,
    ),
    FaultSig(
        pattern=re.compile(r"issue_status\s*=\s*failed"), signature="engine-error", remedy="read the terminal line; relaunch", nonzero_only=False
    ),
    NETWORK_SIG,
)
ADAPTERS: Final[Mapping[Reviewer, Adapter]] = MappingProxyType({
    "coderabbit": Adapter(
        scopes=frozenset({"all", "committed", "uncommitted", "base", "base-commit"}),
        armed=cr_argv,
        preflight=cr_preflight,
        focused=cr_focused,
        markers=Markers(
            start_grace_s=180.0,
            stall_grace_s=1800.0,
            deadline_s=3600.0,
            keepalive=True,
            done=Some(re.compile(r'"type"\s*:\s*"complete"')),
            pulse=Some(re.compile(r'"type"\s*:\s*"(?:heartbeat|status)"')),
            tick=Some(re.compile(r'"type"\s*:\s*"finding"')),
            signatures=CR_SIGS,
        ),
        harvested=cr_harvested,
        source=lambda context: cr_epoch(context.repo, context.run, time.time()).map(str).default_value("store-missing"),
    ),
    "greptile": Adapter(
        scopes=frozenset({"committed", "base", "base-commit"}),
        armed=greptile_argv,
        preflight=gt_preflight,
        focused=greptile_focused,
        markers=Markers(
            start_grace_s=60.0,
            stall_grace_s=1800.0,
            deadline_s=1800.0,
            keepalive=False,
            done=Some(re.compile(r'"confidenceReasoning"\s*:')),
            signatures=GT_SIGS,
        ),
        harvested=greptile_harvested,
        source=greptile_trace,
    ),
    "macroscope": Adapter(
        scopes=frozenset({"uncommitted", "base"}),
        armed=ms_argv,
        preflight=ms_preflight,
        focused=ms_focused,
        markers=Markers(
            start_grace_s=90.0,
            stall_grace_s=1800.0,
            deadline_s=1800.0,
            keepalive=False,
            done=Some(re.compile(r"issue_status\s*=\s*completed")),
            pulse=Some(re.compile(r"review_id\s*=")),
            tick=Some(re.compile(r"issue_event\s*=")),
            signatures=MS_SIGS,
        ),
        harvested=ms_harvested,
        source=lambda context: str(context.round_dir / LOG_NAME),
        accepts_focus=False,
    ),
})

# --- [ENTRY] ----------------------------------------------------------------------------

type _Dir = Annotated[Path | None, Parameter(name=("--dir", "--directory"))]
type _RoundNo = Annotated[int | None, Parameter(name="--round")]
type _AllLive = Annotated[bool, Parameter(name="--all-live")]


@Parameter(name="*")
@dataclass(frozen=True, slots=True, kw_only=True)
class Lens:
    digest: bool = False
    top: int = DIGEST_TOP
    file: str = ""
    severity: str = ""
    claim: str = ""
    within: Annotated[str, Parameter(name="--in")] = "both"
    as_json: Annotated[bool, Parameter(name="--json")] = False

    @property
    def filtered(self) -> bool:
        return bool(self.file or self.severity or self.claim)


WIDE_LENS: Final = Lens()


@Parameter(name="*")
@dataclass(frozen=True, slots=True, kw_only=True)
class Watch:
    follow: bool = False
    as_json: Annotated[bool, Parameter(name="--json")] = False
    normalize: bool = False

    @property
    def faulted(self) -> Option[Fault]:
        if self.as_json and not self.follow:
            return Some(Fault(code="bad-flag", detail="--json rides --follow; a bare receipt already prints JSON"))
        if self.normalize and not self.follow:
            return Some(Fault(code="bad-flag", detail="--normalize rides --follow; run findings --normalize directly instead"))
        return Nothing


WATCH_OFF: Final = Watch()


def followed_through(context: Context, watch: Watch, /) -> int:
    code = followed(context, watch.as_json)
    if code != 0 or not watch.normalize:
        return code
    return delivered(findings_normalized(context, None))


def focus_resolved(spec: str, /) -> Result[str, Fault]:
    candidate = Path(spec)
    return read_bytes(candidate).map(lambda raw: raw.decode(errors="replace")) if spec and candidate.is_file() else Ok(spec)


def launched(repo: Path, reviewer: Reviewer, scope: Scope, focus: str, levers: Levers, /) -> Result[LaunchReceipt, Fault]:
    adapter = ADAPTERS[reviewer]
    if scope.kind not in adapter.scopes:
        return Error(Fault(code="unsupported-scope", detail=f"{reviewer} accepts {sorted(adapter.scopes)}, not {scope.line!r}"))
    if focus and not adapter.accepts_focus:
        return Error(Fault(code="unsupported-focus", detail=f"{reviewer} has no per-run instruction flag; land the concern as config, then relaunch"))
    clash = next((receipt for _context, receipt in live_pairs(repo) if receipt.reviewer == reviewer), None)
    if clash is not None:
        return Error(
            Fault(
                code="live-run",
                detail=(
                    f"{reviewer} round {clash.round} is still {clash.phase}; kill it or wait — a second concurrent {reviewer} run would race the"
                    " same result store, and a wedged engine converts to stalled/timed-out once its grace lapses"
                ),
            )
        )
    return levers_armed(reviewer, levers).bind(
        lambda lever_argv: adapter.preflight(repo, scope).bind(
            lambda pre_argv: flown_round(repo, reviewer, scope, focus, (*adapter.armed(scope), *pre_argv, *lever_argv))
        )
    )


def flown_round(repo: Path, reviewer: Reviewer, scope: Scope, focus: str, base_argv: tuple[str, ...], /) -> Result[LaunchReceipt, Fault]:
    adapter = ADAPTERS[reviewer]

    def armed_and_spawned(number: int, round_dir: Path, /) -> Result[LaunchReceipt, Fault]:
        def unrounded(fault: Fault, /) -> Fault:
            catch(exception=OSError)(shutil.rmtree)(round_dir)
            return fault

        def flown(argv: tuple[str, ...], pid: int, /) -> Result[LaunchReceipt, Fault]:
            return written(
                round_dir / RUN_NAME,
                ENCODER.encode(
                    Run(
                        round=number,
                        kind="engine",
                        reviewer=reviewer,
                        scope=scope,
                        pid=pid,
                        pgid=pid,
                        started=time.time(),
                        argv=argv,
                        sources=(),
                        focus=focus,
                    )
                ),
            ).map(
                lambda run_path: LaunchReceipt(
                    round=number,
                    reviewer=reviewer,
                    scope=scope.line,
                    pid=pid,
                    pgid=pid,
                    argv=argv,
                    focus=focus,
                    watch_cmd=f"uv run {SELF} status --follow --round {number}",
                    log=str(round_dir / LOG_NAME),
                    run=str(run_path),
                )
            )

        def reaped(fault: Fault, pid: int, /) -> Fault:
            catch(exception=ProcessLookupError)(KILLPG)(pid, SIG_KILL)  # a run.json write failure orphans a live engine; reap it with the dir
            return unrounded(fault)

        def flown_recorded(argv: tuple[str, ...], /) -> Result[LaunchReceipt, Fault]:
            return (
                spawned(argv, round_dir / LOG_NAME, repo)
                .map_error(unrounded)
                .bind(lambda pid: flown(argv, pid).map_error(lambda fault: reaped(fault, pid)))
            )

        focus_argv: Result[tuple[str, ...], Fault] = Ok(()) if not focus else adapter.focused(focus, round_dir)
        return focus_argv.map_error(unrounded).bind(lambda extra: flown_recorded((*base_argv, *extra)))

    return round_minted(repo).bind(lambda pair: armed_and_spawned(*pair))


@APP.command
def launch(
    *,
    reviewer: str,
    scope: str,
    focus: str = "",
    light: bool = False,
    resume: bool = False,
    include: tuple[str, ...] = (),
    watch: Watch = WATCH_OFF,
    directory: _Dir = None,
) -> int:
    """Spawn one engine round at a scope; --follow arms the watcher in-verb, --json streams events, --normalize lands findings on completion."""
    match watch.faulted:
        case Option(tag="some", some=fault):
            return refused(fault)
        case _:
            pass
    levers = Levers(light=light, resume=resume, include=include)
    outcome = repo_root(directory).bind(
        lambda repo: reviewer_resolved(reviewer).bind(
            lambda engine: Scope.of(scope).bind(lambda parsed: focus_resolved(focus).bind(lambda text: launched(repo, engine, parsed, text, levers)))
        )
    )
    match outcome:
        case Result(tag="error", error=fault):
            return refused(fault)
        case Result(tag="ok", ok=LaunchReceipt() as receipt):
            emitted(receipt)
            if not watch.follow:
                return 0
            return context_resolved(directory, receipt.round).map(lambda held: followed_through(held, watch)).default_with(refused)
        case _:
            return 1


def pulsed(receipt: StatusReceipt, as_json: bool, /) -> None:
    print(ENCODER.encode(receipt).decode() if as_json else liveness_line(receipt), flush=True)


def chased(contexts: tuple[Context, ...], /, *, as_json: bool, announce_terminal: bool) -> tuple[StatusReceipt, ...]:
    tracked = [(context, StreamProbe(), 0, "") for context in contexts]
    finals: list[StatusReceipt] = []
    noted = time.time()
    while tracked:  # bounded: each round's phased() deadline is terminal, so the loop cannot outlive the max per-round deadline
        moved: list[tuple[Context, StreamProbe, int, str]] = []
        pulse_due = time.time() - noted > LIVENESS_NOTE_S
        for context, probe, offset, last in tracked:
            receipt, grown, at = stepped_status(context, probe, offset)
            if receipt.phase in TERMINAL:
                finals.append(receipt)
                if announce_terminal:
                    pulsed(receipt, as_json)
            else:
                if receipt.phase != last or pulse_due:
                    pulsed(receipt, as_json)
                moved.append((context, grown, at, receipt.phase))
        if pulse_due:
            noted = time.time()
        tracked = moved
        if tracked:
            time.sleep(POLL_S)
    return tuple(sorted(finals, key=lambda receipt: receipt.round))


def followed(context: Context, as_json: bool, /) -> int:
    receipt = chased((context,), as_json=as_json, announce_terminal=False)[0]
    emitted(receipt)
    return 0 if receipt.phase == "completed" else 1


def followed_all(repo: Path, as_json: bool, /) -> int:
    ordered = chased(tuple(context for context, _receipt in live_pairs(repo)), as_json=as_json, announce_terminal=True)
    emitted(LiveStatus(rounds=ordered, all_terminal=True, live=0))
    return 0 if all(receipt.phase == "completed" for receipt in ordered) else 1


def status_target(repo: Path, round_no: int | None, reviewer_spec: str, /) -> Result[Context, Fault]:
    if round_no is not None:
        return round_context(repo, round_no)
    if reviewer_spec:
        return reviewer_resolved(reviewer_spec).bind(lambda held: latest_of(repo, held))
    pairs = live_pairs(repo)
    match pairs:
        case ():
            return round_context(repo, None)
        case ((context, _receipt),):
            return Ok(context)
        case many:
            roster = ", ".join(f"{receipt.round}({receipt.reviewer})" for _context, receipt in many)
            return Error(Fault(code="ambiguous", detail=f"live rounds: {roster} — pass --round, --reviewer, or --all-live"))


def selector_conflict(round_no: int | None, reviewer_spec: str, all_live: bool, /) -> Option[Fault]:
    picked = sum((round_no is not None, bool(reviewer_spec), all_live))
    return Some(Fault(code="bad-flag", detail="pass at most one of --round, --reviewer, --all-live")) if picked > 1 else Nothing


@APP.command
def status(*, watch: Watch = WATCH_OFF, all_live: _AllLive = False, reviewer: str = "", round_no: _RoundNo = None, directory: _Dir = None) -> int:
    """Read or follow a round's phase receipt; --json streams follow events, --normalize lands findings when the follow completes."""
    match repo_root(directory):
        case Result(tag="error", error=fault):
            return refused(fault)
        case Result(tag="ok", ok=repo):
            pass
        case _:
            return 1
    match watch.faulted.or_else(selector_conflict(round_no, reviewer, all_live)):
        case Option(tag="some", some=fault):
            return refused(fault)
        case _:
            pass
    if all_live:
        if watch.normalize:
            return refused(Fault(code="bad-flag", detail="--normalize rides a single-round follow, not --all-live"))
        if watch.follow:
            return followed_all(repo, watch.as_json)
        pairs = live_pairs(repo)
        return emitted(LiveStatus(rounds=tuple(receipt for _context, receipt in pairs), all_terminal=not pairs, live=len(pairs)))
    match status_target(repo, round_no, reviewer), watch.follow:
        case (Result(tag="error", error=fault), _):
            return refused(fault)
        case (Result(tag="ok", ok=held), True):
            return followed_through(held, watch)
        case (Result(tag="ok", ok=held), False):
            return emitted(observed(held))
        case _:
            return 1


def kill_targets(repo: Path, round_no: int | None, reviewer_spec: str, all_live: bool, /) -> Result[tuple[Context, ...], Fault]:
    if round_no is not None:
        return round_context(repo, round_no).map(lambda context: (context,))
    held = tuple(context for context in contexts_of(repo) if killable(context))
    if all_live:
        return Ok(held)
    if reviewer_spec:

        def latest_killable(name: Reviewer, /) -> Result[tuple[Context, ...], Fault]:
            found = next((context for context in reversed(held) if context.run.reviewer == name), None)
            if found is not None:
                return Ok((found,))
            return Error(Fault(code="no-round", detail=f"no killable {name} round under {repo / STATE_DIR}"))

        return reviewer_resolved(reviewer_spec).bind(latest_killable)
    match held:
        case ():
            return Error(Fault(code="no-round", detail="no killable round; pass --round N to kill a specific one"))
        case (context,):
            return Ok((context,))
        case many:
            roster = ", ".join(f"{context.run.round}({context.run.reviewer})" for context in many)
            return Error(Fault(code="ambiguous", detail=f"killable rounds: {roster} — pass --round, --reviewer, or --all-live"))


@APP.command
def kill(*, round_no: _RoundNo = None, reviewer: str = "", all_live: _AllLive = False, directory: _Dir = None) -> int:
    """Escalate SIGTERM to SIGKILL over a round's process group, sweep engine survivors, and stamp the killed sentinel."""
    match selector_conflict(round_no, reviewer, all_live):
        case Option(tag="some", some=fault):
            return refused(fault)
        case _:
            pass
    outcome = repo_root(directory).bind(
        lambda repo: kill_targets(repo, round_no, reviewer, all_live).bind(lambda held: traverse(killed_round, Block.of_seq(held)).map(tuple))
    )
    match outcome:
        case Result(tag="ok", ok=receipts):
            return emitted(receipts[0] if len(receipts) == 1 and not all_live else receipts)
        case Result(tag="error", error=fault):
            return refused(fault)
        case _:
            return 1


def gather_ready(context: Context, /) -> Result[Context, Fault]:
    receipt = observed(context)
    if receipt.phase != "completed":
        return Error(
            Fault(
                code="not-completed", detail=f"round {context.run.round} ({context.run.reviewer}) is {receipt.phase}; gather needs completed sources"
            )
        )
    if not (context.round_dir / FINDINGS_NAME).is_file():
        return Error(
            Fault(
                code="no-findings",
                detail=f"round {context.run.round} ({context.run.reviewer}) not normalized; run findings --normalize --round {context.run.round} first",
            )
        )
    return Ok(context)


def gather_targets(repo: Path, all_live: bool, reviewer_spec: str, rounds_spec: str, /) -> Result[tuple[Context, ...], Fault]:
    picked = sum((all_live, bool(reviewer_spec), bool(rounds_spec)))
    if picked != 1:
        return Error(Fault(code="bad-flag", detail="pass exactly one of --all-live, --reviewer <names>, --rounds <numbers>"))
    if rounds_spec:
        tokens = tuple(token.strip() for token in rounds_spec.split(",") if token.strip())
        if not tokens or not all(token.isdigit() for token in tokens):
            return Error(Fault(code="bad-flag", detail=f"--rounds takes comma-separated round numbers, got {rounds_spec!r}"))
        return traverse(lambda token: round_context(repo, int(token)), Block.of_seq(tokens)).map(tuple)
    if reviewer_spec:
        names = tuple(token.strip() for token in reviewer_spec.split(",") if token.strip())
        return traverse(lambda name: reviewer_resolved(name).bind(lambda held: latest_of(repo, held)), Block.of_seq(names)).map(tuple)
    closed = {row.round for row in rounds_read(repo)}
    sourced = {number for context in contexts_of(repo) if context.run.kind == "gather" for number in context.run.sources}
    held = tuple(context for context in contexts_of(repo) if context.run.kind == "engine" and context.run.round not in closed | sourced)
    if not held:
        return Error(Fault(code="no-round", detail="no open engine rounds to gather; launch, complete, and normalize first"))
    return Ok(held)


def gathered(repo: Path, sources: tuple[Context, ...], /) -> Result[GatherReceipt, Fault]:
    def landed(srcs: tuple[Context, ...], kept: tuple[Finding, ...], /) -> Result[GatherReceipt, Fault]:
        scope = Scope(kind="union", ref=",".join(f"{REVIEWER_SHORT[src.run.reviewer]}:{src.run.scope.line}" for src in srcs))

        def stored(number: int, round_dir: Path, /) -> Result[GatherReceipt, Fault]:
            run = Run(
                round=number,
                kind="gather",
                reviewer=srcs[0].run.reviewer,
                scope=scope,
                pid=0,
                pgid=0,
                started=time.time(),
                argv=(),
                sources=tuple(src.run.round for src in srcs),
            )
            return written(round_dir / RUN_NAME, ENCODER.encode(run)).bind(
                lambda _run: written(round_dir / FINDINGS_NAME, ENCODER.encode(kept)).map(
                    lambda path: GatherReceipt(
                        round=number,
                        sources=run.sources,
                        total=len(kept),
                        corroborated=sum(1 for row in kept if row.corroborators),
                        counts_by_severity=counted(kept),
                        path=str(path),
                    )
                )
            )

        return round_minted(repo).bind(lambda pair: stored(*pair))

    return (
        traverse(gather_ready, Block.of_seq(sources))
        .map(tuple)
        .bind(
            lambda srcs: registry_loaded().bind(
                lambda registry: (
                    traverse(findings_read, Block.of_seq(srcs))
                    .map(lambda pools: unioned(tuple(pools), registry))
                    .bind(lambda kept: landed(srcs, kept))
                )
            )
        )
    )


@APP.command
def gather(*, all_live: _AllLive = False, reviewer: str = "", rounds: str = "", directory: _Dir = None) -> int:
    """Union completed, normalized engine rounds into one pre-normalized gather round with fingerprint collapse and corroborators."""
    return delivered(repo_root(directory).bind(lambda repo: gather_targets(repo, all_live, reviewer, rounds).bind(lambda held: gathered(repo, held))))


def findings_normalized(context: Context, dedup_against: int | None, /, *, partial: bool = False) -> Result[FindingsReceipt, Fault]:
    adapter = ADAPTERS[context.run.reviewer]
    if context.run.kind == "gather":
        return Error(Fault(code="no-process", detail=f"round {context.run.round} is a gather round; its findings.json lands normalized at gather"))
    if tuple(context.round_dir.glob("lane-?.json")):
        return Error(
            Fault(
                code="already-sliced",
                detail=f"{context.round_dir} carries lane slices; a re-normalize would orphan the stamped ids — re-cut with `slice`, read with `findings --digest`",
            )
        )
    terminal = observed(context)
    if terminal.phase != "completed" and not (partial and terminal.phase in TERMINAL):
        return Error(
            Fault(
                code="not-completed",
                detail=f"round {context.run.round} is {terminal.phase}: "
                + (terminal.detail or "wait for the terminal phase")
                + ("" if terminal.phase in TERMINAL else "; a dead engine's store harvests with --partial once terminal"),
            )
        )

    def landed(
        rows: tuple[Finding, ...], kept: tuple[Finding, ...], collapse: float, prior: Option[tuple[Path, tuple[Finding, ...]]], /
    ) -> Result[FindingsReceipt, Fault]:
        tagged = provenanced(kept, prior)
        # Histogram over the full tagged set before the cross-round prune, so relitigation surfaces even though its rows never reach lanes.
        histogram = provenance_hist(tagged)
        prior_rows: tuple[Finding, ...] = prior.map(itemgetter(1)).default_value(())
        pruned, dropped = pruned_against(prior_rows, tagged)
        return written(context.round_dir / PROVENANCE_NAME, ENCODER.encode(histogram)).bind(
            lambda _hist: written(context.round_dir / FINDINGS_NAME, ENCODER.encode(pruned)).map(
                lambda _path: findings_receipt(
                    context,
                    pruned,
                    admitted=len(rows),
                    trace=DedupTrace(
                        deduped=len(rows) - len(kept),
                        collapse_ratio=collapse,
                        cross_deduped=dropped,
                        prior_round=prior.map(lambda pair: round_number(pair[0])).to_optional(),
                    ),
                    provenance=histogram,
                    source=adapter.source(context),
                )
            )
        )

    def persisted(rows: tuple[Finding, ...], registry: Registry, /) -> Result[FindingsReceipt, Fault]:
        kept = normalized(rows, registry)
        collapse = (len(rows) - len(kept)) / len(rows) if rows else 0.0
        if len(rows) >= DEDUP_GUARD_FLOOR and collapse > DEDUP_GUARD_SHARE:
            return Error(
                Fault(
                    code="dedup-collapse",
                    detail=(
                        f"{len(rows)} admitted rows collapsed to {len(kept)} fingerprint survivors ({collapse:.0%}) on an intra-round pass —"
                        f" degenerate identity inputs mark engine format drift; inspect the raw source ({adapter.source(context)}) before"
                        " trusting this round"
                    ),
                )
            )
        return prior_pool(context.repo, context.run.round, dedup_against).bind(lambda prior: landed(rows, kept, collapse, prior))

    return registry_loaded().bind(lambda registry: adapter.harvested(context).bind(lambda rows: persisted(rows, registry)))


def findings_read(context: Context, /) -> Result[tuple[Finding, ...], Fault]:
    path = context.round_dir / FINDINGS_NAME
    if not path.is_file():
        return Error(Fault(code="no-findings", detail=f"{path} absent; run findings --normalize first"))
    return read_bytes(path).bind(lambda payload: decoded(payload, tuple[Finding, ...], str(path)))


@APP.command
def findings(
    *,
    normalize: bool = False,
    partial: bool = False,
    dedup_against: Annotated[int | None, Parameter(name="--dedup-against")] = None,
    lens: Lens = WIDE_LENS,
    round_no: _RoundNo = None,
    directory: _Dir = None,
) -> int:
    """Normalize a completed round's findings, or read them back: bare summary, --digest round read, --file/--severity/--claim/--in query. --normalize --partial harvests a dead engine's store — whatever landed before a terminal failure."""

    def summarized(context: Context, /) -> Result[FindingsReceipt, Fault]:
        return findings_read(context).map(lambda rows: findings_receipt(context, rows, admitted=len(rows)))

    def floor_resolved() -> Result[Option[Severity], Fault]:
        held = SEVERITY_MAP.get(lens.severity.strip().lower())
        return (
            Ok(Some(held) if held is not None else Nothing)
            if held is not None or not lens.severity
            else Error(Fault(code="bad-flag", detail=f"--severity {lens.severity!r} is not critical|major|minor|trivial|info (or a native alias)"))
        )

    def query_of(context: Context, kept: tuple[Finding, ...], total: int, /) -> QueryReceipt:
        scoped = "" if lens.within == "both" else lens.within
        floor_label = f">={lens.severity}" if lens.severity else ""  # the severity filter is a floor, and the receipt names the relation
        filters = {key: value for key, value in (("file", lens.file), ("severity", floor_label), ("claim", lens.claim), ("in", scoped)) if value}
        return QueryReceipt(round=context.run.round, matched=len(kept), total=total, filters=filters, rows=tuple(lined(row) for row in kept))

    def read_mode(context: Context, /) -> Result[object, Fault]:
        matcher = Some(lenient_pattern(lens.claim)) if lens.claim else Nothing
        searched = SEARCH_SCOPES[lens.within]

        def projected(rows: tuple[Finding, ...], floor: Option[Severity], /) -> object:
            kept = queried(rows, floor, lens.file, matcher, searched)
            if lens.digest:
                built = digest_built(context, kept, lens.top)
                return built if lens.as_json else digest_rendered(built)
            receipt = query_of(context, kept, len(rows))
            return receipt if lens.as_json else query_rendered(receipt)

        return floor_resolved().bind(lambda floor: findings_read(context).map(lambda rows: projected(rows, floor)))

    if lens.within not in SEARCH_SCOPES:
        return refused(Fault(code="bad-flag", detail=f"--in {lens.within!r} is not claim|fix|both"))
    if lens.within != "both" and not lens.claim:
        return refused(Fault(code="bad-flag", detail="--in scopes the --claim regex; pass --claim with it"))
    if dedup_against is not None and not normalize:
        return refused(Fault(code="bad-flag", detail="--dedup-against rides --normalize"))
    if partial and not normalize:
        return refused(Fault(code="bad-flag", detail="--partial rides --normalize"))
    match normalize, lens.digest or lens.filtered, lens.as_json:
        case (True, True, _) | (True, _, True):
            return refused(Fault(code="bad-flag", detail="--normalize excludes --digest, --json, and the query filters; normalize first, then read"))
        case (False, False, True):
            return refused(Fault(code="bad-flag", detail="--json rides --digest or the query filters; the bare summary already prints JSON"))
        case _:
            pass
    outcome = context_resolved(directory, round_no).bind(
        lambda context: (
            findings_normalized(context, dedup_against, partial=partial)
            if normalize
            else read_mode(context)
            if lens.digest or lens.filtered
            else summarized(context)
        )
    )
    match outcome:
        case Result(tag="ok", ok=str() as text):
            print(text)
            return 0
        case held:
            return delivered(held)


@APP.command(name="slice")
def slice_cmd(
    *,
    lanes: Annotated[int | None, Parameter(name="--lanes")] = None,
    balance: Balance = "count",
    recut: bool = False,
    closers: bool = False,
    round_no: _RoundNo = None,
    directory: _Dir = None,
) -> int:
    """Cut normalized findings into balanced per-lane manifests and briefs (--lanes omitted derives the count); --closers instead cuts the lane reports' routing rows into file-disjoint closer territories."""

    def carved_round(context: Context, /) -> Result[SliceReceipt, Fault]:
        if lanes is not None and not 1 <= lanes <= LANES_CAP:
            return Error(Fault(code="bad-lane", detail=f"lanes must be 1..{LANES_CAP}, got {lanes}"))
        reports = tuple(context.round_dir.glob("lane-?-report.json"))
        if reports and not recut:
            return Error(
                Fault(
                    code="already-sliced",
                    detail=f"{len(reports)} lane report(s) exist under {context.round_dir}; a re-cut destroys fixer output — pass --recut to proceed",
                )
            )
        stale = (*context.round_dir.glob("lane-?.json"), *reports, *context.round_dir.glob("lane-?-brief.md"))
        # Registry, findings, and the cut all prove out BEFORE the stale set unlinks, so a refused re-slice leaves the prior lanes intact.
        return registry_loaded().bind(
            lambda registry: findings_read(context).bind(
                lambda rows: unlinked(stale).bind(
                    lambda cleared: slices_written(
                        context,
                        sliced(rows, auto_lanes(len(rows)) if lanes is None else lanes, balance, context.repo, context.run.round, registry),
                        cleared,
                        restamped=True,
                    )
                )
            )
        )

    def carved_closers(context: Context, /) -> Result[SliceReceipt, Fault]:
        if lanes is not None and not 1 <= lanes <= LANES_CAP:
            return Error(Fault(code="bad-lane", detail=f"lanes must be 1..{LANES_CAP}, got {lanes}"))
        landed = tuple(context.round_dir.glob("close-*-report.json"))
        if landed and not recut:
            return Error(
                Fault(
                    code="already-sliced",
                    detail=f"{len(landed)} closer report(s) exist under {context.round_dir}; a re-cut destroys closer output — pass --recut to proceed",
                )
            )
        rows = routing_mined(report_pairs(context.round_dir))
        stale = (*context.round_dir.glob("close-?.json"), *landed, *context.round_dir.glob("close-?-brief.md"))
        return reports_complete(context.round_dir).bind(
            lambda _reports: (
                Error(Fault(code="no-findings", detail=f"round {context.run.round} lane reports carry zero routing rows; nothing to close"))
                if not rows
                else unlinked(stale).bind(
                    lambda cleared: slices_written(
                        context,
                        closer_sliced(rows, auto_lanes(len(rows)) if lanes is None else lanes, context.run.reviewer),
                        cleared,
                        restamped=False,
                    )
                )
            )
        )

    def slices_written(context: Context, packs: tuple[LaneSlice, ...], cleared: int, /, *, restamped: bool) -> Result[SliceReceipt, Fault]:
        if not packs:
            return Error(Fault(code="no-findings", detail=f"round {context.run.round} has zero findings to slice; close it with `round` and rotate"))
        briefed = tuple(
            replace(pack, manifest=replace(pack.manifest, brief=str(context.round_dir / f"{pack.manifest.lane}-brief.md"))) for pack in packs
        )
        stamped = tuple(row for pack in briefed for row in pack.findings)
        writes = (
            *((context.round_dir / f"{pack.manifest.lane}.json", ENCODER.encode(pack)) for pack in briefed),
            *((Path(pack.manifest.brief), brief_rendered(pack, context.run.round).encode()) for pack in briefed),
            *(((context.round_dir / FINDINGS_NAME, ENCODER.encode(stamped)),) if restamped else ()),  # closer cuts never rewrite the finding ids
        )
        outcome: Result[Path, Fault] = reduce(lambda acc, job: acc.bind(lambda _done: written(*job)), writes, Ok(context.round_dir))
        return outcome.map(
            lambda _last: SliceReceipt(
                round=context.run.round,
                lanes=tuple(pack.manifest for pack in briefed),
                stamped=len(stamped),
                settled_rulings=len({ruling for pack in briefed for ruling in pack.settled_rulings}),
                cleared=cleared,
            )
        )

    return delivered(context_resolved(directory, round_no).bind(carved_closers if closers else carved_round))


@APP.command
def reconcile(
    lane: str = "", /, *, all_lanes: Annotated[bool, Parameter(name="--all")] = False, round_no: _RoundNo = None, directory: _Dir = None
) -> int:
    """Prove per-lane id bijection against the lane reports and surface the routing drain; exit 0 only when every covered lane is bijective."""

    def resolved(context: Context, /) -> Result[ReconcileReceipt, Fault]:
        if all_lanes and lane:
            return Error(Fault(code="bad-lane", detail=f"--all excludes a named lane; drop {lane!r} or the flag"))
        wanted = lane.removeprefix("lane-")
        return reconciled(context.round_dir).bind(
            lambda stats: (
                Error(Fault(code="bad-lane", detail=f"lane-{wanted} not among {tuple(stat.lane for stat in stats)}"))
                if wanted and not any(stat.lane == f"lane-{wanted}" for stat in stats)
                else Ok(
                    ReconcileReceipt(
                        round=context.run.round,
                        lanes=(kept := tuple(stat for stat in stats if not wanted or stat.lane == f"lane-{wanted}")),
                        bijective=all(stat.report_valid and not stat.missing and not stat.phantom for stat in kept),
                        routing=round_drain(context.round_dir),
                    )
                )
            )
        )

    return delivered(
        context_resolved(directory, round_no).bind(resolved), clean=lambda receipt: not isinstance(receipt, ReconcileReceipt) or receipt.bijective
    )


@APP.command
def lanes(*, fill: bool = False, spawns: bool = False, lane: str = "", round_no: _RoundNo = None, directory: _Dir = None) -> int:
    """Read per-lane facts: --fill emits each lane's resolved territory tiers (owning packages, .api overlays, substrate, doctrine roots); --spawns audits the codex rollouts for real spawn_agent dispatches."""
    if fill == spawns:
        return refused(Fault(code="bad-flag", detail="pass exactly one of --fill (territory tier data) or --spawns (rollout spawn audit)"))
    wanted = f"lane-{lane}" if len(lane) == 1 else lane

    def empty(round_dir: Path, /) -> Fault:
        named = f" matching {wanted!r}" if wanted else ""
        return Fault(code="no-lanes", detail=f"no lanes{named} under {round_dir}; slice and dispatch first")

    def filled(context: Context, /) -> Result[object, Fault]:
        rows = tuple(
            lane_filled(context.repo, slice_.manifest)
            for _path, slice_ in lane_slices(context.round_dir)
            if not wanted or slice_.manifest.lane == wanted
        )
        return Ok(FillReceipt(round=context.run.round, lanes=rows)) if rows else Error(empty(context.round_dir))

    def audited(context: Context, /) -> Result[object, Fault]:
        rows = tuple(row for row in spawn_rows(context.round_dir) if not wanted or row.lane == wanted)
        oracle = f"{CODEX_SESSIONS} rollout response_item function_call name={SPAWN_TOOL}"
        return Ok(SpawnReceipt(round=context.run.round, oracle=oracle, lanes=rows)) if rows else Error(empty(context.round_dir))

    return delivered(context_resolved(directory, round_no).bind(filled if fill else audited))


def harvest_built(context: Context, /) -> Result[HarvestReceipt, Fault]:
    def fed(registry: Registry, rows: tuple[Finding, ...], reports: tuple[LaneReport, ...], /) -> Result[HarvestReceipt, Fault]:
        recurred, fresh = recurrence(registry, rows, reports)
        recurred_ids = frozenset(class_id for class_id, _ in recurred)
        feed = feed_rendered(context.run, recurred, fresh, reports, registry)
        return proposals_written(context, recurred_ids, reports, registry).bind(
            lambda proposals: written(context.round_dir / FEED_NAME, feed.encode()).map(
                lambda path: HarvestReceipt(
                    round=context.run.round,
                    reports=len(reports),
                    recurred=tuple(class_id for class_id, _ in recurred),
                    new_refuted=len(fresh),
                    improvements=sum(len(report.improvements) for report in reports),
                    capability=sum(len(report.capability) for report in reports),
                    routed=sum(len(report.routing) + len(report.uncertain) for report in reports),
                    proposals=proposals,
                    path=str(path),
                )
            )
        )

    return reports_complete(context.round_dir).bind(
        lambda reports: (
            Error(Fault(code="no-report", detail=f"no lane-?-report.json under {context.round_dir}; fixer lanes write reports first"))
            if not reports
            else registry_loaded().bind(lambda registry: findings_read(context).bind(lambda rows: fed(registry, rows, reports)))
        )
    )


@APP.command
def harvest(*, round_no: _RoundNo = None, directory: _Dir = None) -> int:
    """Assemble the round's harvest feed and memory proposals from the complete lane-report set."""
    return delivered(context_resolved(directory, round_no).bind(harvest_built))


@APP.command(name="round")
def round_cmd(
    *,
    harvest: bool = False,
    defer_routing: Annotated[bool, Parameter(name="--defer-routing")] = False,
    round_no: _RoundNo = None,
    directory: _Dir = None,
) -> int:
    """Close the round: append its rounds.jsonl row with computed grades and print the delta; --harvest runs the feed assembly first, and --defer-routing records undrained routing rows as a deliberate deferral instead of refusing."""

    def closed(context: Context, /) -> Result[RoundReceipt, Fault]:
        if any(row.round == context.run.round for row in rounds_read(context.repo)):
            return Error(Fault(code="already-closed", detail=f"round {context.run.round} already has a {LEDGER_NAME} row"))
        return registry_loaded().bind(lambda registry: findings_read(context).bind(lambda rows: assembled(context, rows, registry)))

    def assembled(context: Context, rows: tuple[Finding, ...], registry: Registry, /) -> Result[RoundReceipt, Fault]:
        if not rows:
            return appended(context, row_built(context, rows, (), (), registry, RoutingDrain()))
        return reports_complete(context.round_dir).bind(
            lambda reports: (
                Error(Fault(code="no-report", detail=f"round {context.run.round} has findings but no lane-?-report.json; fix lanes before closing"))
                if not reports
                else drain_gated(context, rows, reports, registry)
            )
        )

    def drain_gated(
        context: Context, rows: tuple[Finding, ...], reports: tuple[LaneReport, ...], registry: Registry, /
    ) -> Result[RoundReceipt, Fault]:
        # Drain computes only over the proven-complete report set, so a missing lane report never shrinks the routing pool the gate reads.
        drain = round_drain(context.round_dir)
        if drain.pending and not defer_routing:
            roster = ", ".join(row.key for row in drain.pending[:8]) + (" ..." if len(drain.pending) > 8 else "")
            return Error(
                Fault(
                    code="routing-undrained",
                    detail=(
                        f"{len(drain.pending)}/{drain.total} routing rows carry no closer verdict ({roster}); cut territories with"
                        " `slice --closers`, dispatch closers, and re-run — or record the deferral with --defer-routing"
                    ),
                )
            )
        marked = replace(drain, deferred=defer_routing and bool(drain.pending))
        return reconciled(context.round_dir).bind(lambda stats: appended(context, row_built(context, rows, stats, reports, registry, marked)))

    def appended(context: Context, row: RoundRow, /) -> Result[RoundReceipt, Fault]:
        prior = next((held for held in reversed(rounds_read(context.repo)) if held.round < row.round), None)
        return written(context.repo / STATE_DIR / LEDGER_NAME, ENCODER.encode(row) + b"\n", append=True).map(
            lambda _path: RoundReceipt(row=row, delta=delta_of(prior, row))
        )

    match context_resolved(directory, round_no):
        case Result(tag="error", error=fault):
            return refused(fault)
        case Result(tag="ok", ok=Context() as context):
            pass
        case _:
            return 1
    if harvest:
        match harvest_built(context):
            case Result(tag="error", error=fault):
                return refused(fault)
            case Result(tag="ok", ok=receipt):
                emitted(receipt)
            case _:
                return 1
    return delivered(closed(context))


@APP.command
def registry(*, check: bool = False, apply: bool = False, rows: str = "") -> int:
    """Prove proposed refuted-class rows (--check; bare lints the standing yaml) or land a fully clean set append-only (--apply)."""
    match check, apply, bool(rows):
        case (True, False, _):
            match registry_checked(rows):
                case Result(tag="ok", ok=receipt):
                    emitted(receipt)
                    return 0 if not receipt.faulted else 1
                case Result(tag="error", error=fault):
                    return refused(fault)
                case _:
                    return 1
        case (False, True, True):
            return delivered(registry_applied(Path(rows)))
        case (False, True, False):
            return refused(Fault(code="bad-flag", detail="--apply requires --rows <path> naming the proposed classes: rows"))
        case _:
            return refused(Fault(code="bad-flag", detail="pass exactly one of --check [--rows <path>] or --apply --rows <path>"))


@APP.command
def verify(*, rule: str = "", path: str = "", round_no: _RoundNo = None, directory: _Dir = None) -> int:
    """Prove a landed guard in its surface's own oracle: --rule for the greptile cascade, --round for the whole surface ledger."""
    match bool(rule), round_no is not None:
        case (True, False):
            match repo_root(directory).map(lambda repo: gt_verified(repo, rule, path)):
                case Result(tag="ok", ok=receipt):
                    emitted(receipt)
                    return 0 if receipt.effective else 1
                case Result(tag="error", error=fault):
                    return refused(fault)
                case _:
                    return 1
        case (False, True):
            match context_resolved(directory, round_no).bind(round_verified):
                case Result(tag="ok", ok=receipts):
                    emitted(receipts)
                    return 0 if all(receipt.effective for receipt in receipts) else 1
                case Result(tag="error", error=fault):
                    return refused(fault)
                case _:
                    return 1
        case _:
            return refused(
                Fault(code="bad-flag", detail="pass exactly one of --rule <text> (greptile cascade check) or --round N (all-surface ledger check)")
            )


@APP.command
def selftest() -> int:
    """Prove the rail's pure contracts and exit nonzero naming each failed proof."""
    rows = selftest_proofs()
    failures = tuple(name for name, held in rows if not held)
    emitted(SelftestReceipt(proofs=len(rows), passed=len(rows) - len(failures), failures=failures))
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(APP(sys.argv[1:], result_action="return_value"))
