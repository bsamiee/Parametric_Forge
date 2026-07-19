#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.15"
# dependencies = ["cyclopts>=4", "expression>=5", "msgspec>=0.19", "ruamel.yaml>=0.18"]
# ///
# ruff: noqa: T201, D100, D101, D102, D103

# --- [RUNTIME_PRELUDE] ------------------------------------------------------------------

from collections import Counter
from collections.abc import Callable, Mapping
from copy import replace as evolved
from dataclasses import dataclass
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
type SliceAxis = Literal["folder"]
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
    "no-findings",
    "no-lanes",
    "bad-lane",
    "no-report",
    "store-missing",
    "no-payload",
    "already-sliced",
    "already-closed",
]

# --- [CONSTANTS] ------------------------------------------------------------------------

CLAIM_STEM: Final = 120
FOLDER_DEPTH: Final = 2
HEADLINE: Final = 160
JSON_SCAN_CAP: Final = 64
LANES_CAP: Final = 12
LANE_ALPHABET: Final = "abcdefghijkl"
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
REGISTRY_PATH: Final = SELF.parent.parent / "templates" / "refuted-classes.yaml"
CR_META_NAMES: Final = frozenset({"git.json", "internalState.json", "diff.json", "incrementalDiff.json"})
ROSTER_KEYS: Final = ("members", "roster", "symbols")
SEVERITIES: Final[tuple[Severity, ...]] = ("critical", "major", "minor", "trivial", "info")
RANK: Final[Mapping[Severity, int]] = MappingProxyType({level: rank for rank, level in enumerate(SEVERITIES)})
TERMINAL: Final[frozenset[Phase]] = frozenset({"completed", "failed", "refused", "stalled", "timed-out", "killed"})
REFUSAL_SIGNATURES: Final[frozenset[FaultSignature]] = frozenset({"oversized"})
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
    id: str
    fingerprint: str
    reviewer: Reviewer
    file: str
    range: Range
    severity: Severity
    claim: str
    fix_instructions: str
    class_match: str
    raw: msgspec.Raw
    corroborators: tuple[Reviewer, ...] = ()
    provenance: Provenance = ""


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
    model: str = ""
    wall_s: float = 0.0


class RefutedClass(msgspec.Struct, frozen=True):
    class_id: str
    matchers: tuple[str, ...] = ()
    refuting_citation: str = ""
    landed_surfaces: tuple[str, ...] = ()
    rounds_seen: tuple[int, ...] = ()


class Registry(msgspec.Struct, frozen=True):
    classes: tuple[RefutedClass, ...] = ()


class CrMeta(msgspec.Struct, frozen=True, rename="camel"):
    working_directory: str = ""
    timestamp: float = 0.0


class CrRange(msgspec.Struct, frozen=True):
    start: int = 0
    end: int = 0


class CrRich(msgspec.Struct, frozen=True, rename="camel"):
    id: str = ""
    severity: str = "info"
    file_name: str = ""
    start_line: int = 0
    end_line: int = 0
    line_range: CrRange | None = None
    title: str = ""
    comment: str = ""
    codegen_instructions: str = ""
    fingerprint: str = ""


class GtRange(msgspec.Struct, frozen=True):
    start: int = 0
    lines: int = 0


class GtHunk(msgspec.Struct, frozen=True, rename="camel"):
    header: str = ""
    old_range: GtRange | None = None
    new_range: GtRange | None = None
    before: str | None = None
    after: str | None = None


class GtComment(msgspec.Struct, frozen=True, rename="camel"):
    id: str = ""
    path: str = ""
    start_line: int = 0
    end_line: int = 0
    side: str = ""
    severity: str = ""
    security_issue: bool = False
    category: str = ""
    body: str = ""
    verified_evidence: str | None = None
    suggestion: str | None = None
    hunk: GtHunk | str | None = None


class GreptileRow(msgspec.Struct, frozen=True, rename="camel"):
    run_id: str = ""
    remote_url: str = ""
    base_ref: str = ""
    head_ref: str = ""
    base_sha: str = ""
    head_sha: str = ""
    created_at: str = ""
    completed_at: str = ""
    status: str = ""
    comment_count: int = 0
    confidence: int = 0


class GreptileLedger(msgspec.Struct, frozen=True):
    version: int = 1
    reviews: tuple[GreptileRow, ...] = ()


class MsIssue(msgspec.Struct, frozen=True):
    issue_id: str = ""
    sequence: int = 0
    path: str = ""
    function: str = ""
    line: int = 0
    end_line: int = 0
    severity: str = ""
    category: str = ""
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
    provenance_by_class: dict[str, int]
    corroboration_histogram: dict[str, int]
    commit: str
    at: float
    focus: str = ""


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
    findings_seen: int
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
    total: int
    deduped: int
    cross_deduped: int
    classified: int
    counts_by_severity: dict[str, int]
    provenance: dict[str, int]
    scope_misfire: bool
    source: str
    path: str


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


class ReconcileReceipt(msgspec.Struct, frozen=True):
    round: int
    lanes: tuple[LaneStat, ...]
    bijective: bool


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


class VerifyReceipt(msgspec.Struct, frozen=True):
    rule: str
    path: str
    effective: bool
    matched: str
    source: str


# --- [ERRORS] ---------------------------------------------------------------------------


class Fault(msgspec.Struct, frozen=True):
    code: FaultCode
    detail: str = ""


# --- [SERVICES] -------------------------------------------------------------------------

APP: Final = App(
    help="One verb rail over CodeRabbit, Greptile, and Macroscope: launch, status, kill, findings, slice, reconcile, harvest, gather, round, verify."
)
ENCODER: Final = msgspec.json.Encoder()
RAW_JSON: Final = json.JSONDecoder()
YAML_SAFE: Final = YAML(typ="safe")
YAML_RT: Final = YAML(typ="rt")

# --- [BOUNDARIES] -----------------------------------------------------------------------


def emitted(payload: object, /) -> int:
    print(ENCODER.encode(payload).decode())
    return 0


def refused(fault: Fault, /) -> int:
    emitted(fault)
    return 1


def delivered(outcome: Result[object, Fault], /) -> int:
    return outcome.map(emitted).default_with(refused)


def read_bytes(path: Path, /) -> Result[bytes, Fault]:
    return catch(exception=OSError)(path.read_bytes)().map_error(lambda unreachable: Fault(code="unreadable", detail=f"{path}: {unreachable}"))


def written(path: Path, payload: bytes, /, *, append: bool = False) -> Result[Path, Fault]:
    def sunk() -> Path:
        with path.open("ab" if append else "wb") as sink:
            sink.write(payload)
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


def json_document(text: str, at: int, /) -> Option[object]:
    return catch(exception=ValueError)(RAW_JSON.raw_decode)(text, at).to_option().map(itemgetter(0))


def shaped[T](path: Path, shape: type[T], /) -> Option[T]:
    return read_bytes(path).bind(lambda payload: decoded(payload, shape, str(path))).to_option()


def yaml_loaded(path: Path, /) -> Result[object, Fault]:
    try:
        parsed: object = YAML_SAFE.load(path.read_text(encoding="utf-8"))
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

    def stepped(acc: StreamProbe, line: str, /) -> StreamProbe:
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
    return StatusReceipt(
        round=context.run.round,
        reviewer=context.run.reviewer,
        scope=context.run.scope.line,
        phase=phase,
        elapsed_s=round(min(live.elapsed, settled_at) if phase in TERMINAL else live.elapsed, 1),
        last_pulse_age_s=round(live.pulse_age, 1),
        findings_seen=probe.ticks,
        detail=detail,
        signature=sig,
        remedy=remedy,
        exit_code=exit_code,
        alive=live.alive,
        budget_s=round(max(markers.deadline_s - live.elapsed, 0.0), 1),
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

    return sentineled(context).default_with(scanned_status)


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
            return status_of(context, grown, Nothing), grown, moved


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
        leftovers = sh((*git, "branch", "--list", f"{WORKTREE_BRANCH}*", "--format=%(refname:short)")).map(str.splitlines).default_with(lambda _f: [])
        for branch in leftovers:
            if branch.strip():
                sh((*git, "branch", "-D", branch.strip()))
    return tuple(str(path) for path, _branch in victims)


def survivors_swept(repo: Path, needle: str, /) -> tuple[int, ...]:
    anchor = Path(os.path.realpath(repo))
    own = {os.getpid(), os.getppid()}
    listed = sh(("pgrep", "-f", needle)).map(str.splitlines).default_with(lambda _f: [])
    pids = tuple(int(line) for line in listed if line.strip().isdigit() and int(line) not in own)

    def anchored(pid: int, /) -> bool:
        cwd = sh(("lsof", "-a", "-p", str(pid), "-d", "cwd", "-Fn")).default_with(lambda _f: "")
        return any(line.startswith("n") and Path(os.path.realpath(line[1:])) == anchor for line in cwd.splitlines())

    doomed = tuple(pid for pid in pids if anchored(pid))
    for pid in doomed:
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


def minted(reviewer: Reviewer, file: str, span: Range, claim: str, fix: str, severity: str, payload: bytes, /) -> Option[Finding]:
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
            raw=msgspec.Raw(payload),
        )
    )


def counted(rows: tuple[Finding, ...], /) -> dict[str, int]:
    tally = Counter(row.severity for row in rows)
    return {level: tally[level] for level in SEVERITIES if level in tally}


def compiled(registry: Registry, /) -> tuple[tuple[str, tuple[re.Pattern[str], ...]], ...]:
    def pattern(matcher: str, /) -> re.Pattern[str]:
        return catch(exception=re.PatternError)(re.compile)(matcher, re.IGNORECASE).default_with(
            lambda _bad: re.compile(re.escape(matcher), re.IGNORECASE)
        )

    return tuple((row.class_id, tuple(pattern(matcher) for matcher in row.matchers)) for row in registry.classes)


def classified(matchers: tuple[tuple[str, tuple[re.Pattern[str], ...]], ...], claim: str, /) -> str:
    return next((class_id for class_id, patterns in matchers if any(pattern.search(claim) for pattern in patterns)), "")


def normalized(rows: tuple[Finding, ...], registry: Registry, /) -> tuple[Finding, ...]:
    matchers = compiled(registry)
    stamped = tuple(replace(row, class_match=classified(matchers, row.claim)) for row in rows)
    ordered = sorted(stamped, key=lambda row: (row.fingerprint, RANK[row.severity]))
    survivors = tuple(next(iter(bunch)) for _, bunch in groupby(ordered, key=lambda row: row.fingerprint))
    return tuple(sorted(survivors, key=lambda row: (RANK[row.severity], row.file, row.range.start)))


def unioned(pools: tuple[tuple[Finding, ...], ...], registry: Registry, /) -> tuple[Finding, ...]:
    matchers = compiled(registry)
    tagged = tuple(replace(row, class_match=row.class_match or classified(matchers, row.claim)) for pool in pools for row in pool)
    ordered = sorted(tagged, key=lambda row: row.fingerprint)

    def collapsed(bunch: tuple[Finding, ...], /) -> Finding:
        group = sorted(bunch, key=lambda row: RANK[row.severity])
        primary = group[0]
        others = tuple(row.reviewer for row in group[1:] if row.reviewer != primary.reviewer)
        return replace(primary, corroborators=tuple(dict.fromkeys((*primary.corroborators, *others))))

    survivors = tuple(collapsed(tuple(bunch)) for _, bunch in groupby(ordered, key=lambda row: row.fingerprint))
    return tuple(sorted(survivors, key=lambda row: (RANK[row.severity], row.file, row.range.start)))


def pruned_against(prior: tuple[Finding, ...], rows: tuple[Finding, ...], /) -> tuple[tuple[Finding, ...], int]:
    seen = {row.fingerprint for row in prior}
    kept = tuple(row for row in rows if row.fingerprint not in seen)
    return kept, len(rows) - len(kept)


def prior_pool(repo: Path, current: int, dedup_against: int | None, /) -> Result[Option[tuple[Path, tuple[Finding, ...]]], Fault]:
    if dedup_against is not None:
        held = repo / STATE_DIR / f"round-{dedup_against:03d}" / FINDINGS_NAME
        return read_bytes(held).bind(lambda payload: decoded(payload, tuple[Finding, ...], str(held))).map(lambda rows: Some((held.parent, rows)))
    candidates = tuple(
        d for d in round_dirs(repo) if round_number(d) < current and (d / FINDINGS_NAME).is_file() and tuple(d.glob("lane-?-report.json"))
    )
    if not candidates:
        return Ok(Nothing)
    tail = candidates[-1]
    return Ok(shaped(tail / FINDINGS_NAME, tuple[Finding, ...]).map(lambda rows: (tail, rows)))


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
        case CrRange(start=start, end=end) if start or end:
            return Range(start=start, end=end)
        case _:
            return Range(start=rich.start_line, end=rich.end_line or rich.start_line)


def cr_admitted(path: Path, /) -> Option[Finding]:
    def projected(payload: bytes, rich: CrRich, /) -> Option[Finding]:
        span = cr_span(rich)
        claim = headline(rich.title or rich.comment)
        return minted("coderabbit", rich.file_name, span, claim, rich.codegen_instructions or rich.comment, rich.severity, payload).map(
            lambda row: replace(row, id=rich.id, fingerprint=rich.fingerprint or row.fingerprint)
        )

    return (
        read_bytes(path).to_option().bind(lambda payload: decoded(payload, CrRich, str(path)).to_option().bind(lambda rich: projected(payload, rich)))
    )


def cr_store_rows(epoch: Path, /) -> tuple[Finding, ...]:
    return tuple(Block.of_seq(sorted(epoch.glob("*.json"))).choose(lambda path: Nothing if path.name in CR_META_NAMES else cr_admitted(path)))


def cr_harvested(context: Context, /) -> Result[tuple[Finding, ...], Fault]:
    return (
        cr_epoch(context.repo, context.run, time.time())
        .map(lambda epoch: Ok(cr_store_rows(epoch)))
        .default_with(
            lambda: Error(
                Fault(
                    code="store-missing",
                    detail=f"no {CR_STORE} epoch matched the run window (workingDirectory==repo, timestamp within ±{STORE_SLACK_S:.0f}s)",
                )
            )
        )
    )


def json_offsets(text: str, /) -> tuple[int, ...]:
    starts = accumulate((len(line) for line in text.splitlines(keepends=True)), initial=0)
    candidates = (
        at + len(line) - len(stripped)
        for at, line in zip(starts, text.splitlines(keepends=True), strict=False)
        if (stripped := line.lstrip())[:1] in {"[", "{"}
    )
    return tuple(islice(candidates, JSON_SCAN_CAP))


def json_documents(text: str, /) -> tuple[object, ...]:
    def stepped(acc: tuple[int, tuple[object, ...]], at: int, /) -> tuple[int, tuple[object, ...]]:
        horizon, docs = acc
        if at < horizon:
            return acc
        return catch(exception=ValueError)(RAW_JSON.raw_decode)(text, at).to_option().map(lambda pair: (pair[1], (*docs, pair[0]))).default_value(acc)

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
    populated = docs.map(greptile_rows).choose(lambda rows: Some(rows) if rows else Nothing)
    enveloped = docs.choose(lambda doc: Some(doc) if isinstance(doc, dict) and "comments" in doc else Nothing)
    return (
        Ok(populated.head())
        if not populated.is_empty()
        else Ok(())
        if not enveloped.is_empty()
        else Error(Fault(code="no-payload", detail=f"{origin}: no greptile --json envelope (top-level comments[]) in the stream"))
    )


def gt_admitted(row: dict[str, object], /) -> Result[Option[Finding], Fault]:
    def converted() -> GtComment:
        return msgspec.convert(row, type=GtComment, strict=False)

    def projected(comment: GtComment, /) -> Option[Finding]:
        span = Range(start=comment.start_line, end=comment.end_line or comment.start_line)
        return minted(
            "greptile", comment.path, span, headline(comment.body), comment.suggestion or comment.body, comment.severity, ENCODER.encode(row)
        ).map(lambda held: replace(held, id=comment.id))

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
                        ENCODER.encode(payload),
                    )
                    if issue.issue_id or issue.path
                    else Nothing
                )
            )
        )

    return json_document(text, at).bind(converted)


def ms_harvested(context: Context, /) -> Result[tuple[Finding, ...], Fault]:
    return (
        read_bytes(context.round_dir / LOG_NAME)
        .map(lambda raw: ANSI_RE.sub("", raw.decode(errors="replace")))
        .map(lambda text: tuple(Block.of_seq(ISSUE_AT_RE.finditer(text)).choose(lambda hit: ms_admitted(text, hit.end()))))
    )


# --- [SLICING]


def folder_of(file: str, /) -> str:
    parts = PurePosixPath(file).parts
    return "/".join(parts[:FOLDER_DEPTH]) if len(parts) > FOLDER_DEPTH else "/".join(parts[:-1]) or file


GROUPERS: Final[Mapping[SliceAxis, Callable[[str], str]]] = MappingProxyType({"folder": folder_of})


def loc_of(path: Path, /) -> int:
    return read_bytes(path).map(lambda payload: payload.count(b"\n")).default_with(lambda _f: 0)


def rulings_of(registry: Registry, /) -> tuple[str, ...]:
    return tuple(f"{row.class_id}: {row.refuting_citation}".rstrip(": ") for row in registry.classes)


def sliced(
    rows: tuple[Finding, ...], lanes: int, axis: SliceAxis, balance: Balance, repo: Path, round_no: int, rulings: tuple[str, ...], /
) -> tuple[LaneSlice, ...]:
    grouper = GROUPERS[axis]
    ordered = sorted(rows, key=lambda row: grouper(row.file))
    groups = tuple((key, tuple(bunch)) for key, bunch in groupby(ordered, key=lambda row: grouper(row.file)))

    def weighed(bunch: tuple[Finding, ...], /) -> int:
        return len(bunch) if balance == "count" else sum(loc_of(repo / file) for file in {row.file for row in bunch})

    weighted = sorted(((weighed(bunch), key, bunch) for key, bunch in groups), key=itemgetter(0), reverse=True)
    by_folder = dict(groups)

    def packed(
        acc: tuple[tuple[int, tuple[str, ...]], ...], entry: tuple[int, str, tuple[Finding, ...]], /
    ) -> tuple[tuple[int, tuple[str, ...]], ...]:
        slot = min(range(len(acc)), key=lambda at: acc[at][0])
        weight, held = acc[slot]
        return (*acc[:slot], (weight + entry[0], (*held, entry[1])), *acc[slot + 1 :])

    seeds: tuple[tuple[int, tuple[str, ...]], ...] = tuple((0, ()) for _ in range(min(lanes, LANES_CAP)))
    packs = reduce(packed, weighted, seeds)

    def lane_carved(at: int, folders: tuple[str, ...], /) -> LaneSlice:
        letter = LANE_ALPHABET[at]
        picked_rows = sorted(
            (row for folder in folders for row in by_folder[folder]), key=lambda row: (RANK[row.severity], row.file, row.range.start)
        )
        stamped = tuple(replace(row, id=f"r{round_no}{letter}-{index + 1:02d}") for index, row in enumerate(picked_rows))
        criticals = sum(1 for row in stamped if row.severity == "critical")
        return LaneSlice(
            manifest=LaneManifest(
                lane=f"lane-{letter}",
                files=tuple(sorted({row.file for row in stamped})),
                count=len(stamped),
                criticals=criticals,
                suggested_scope_line=f"{', '.join(sorted(folders))} — {len(stamped)} findings, {criticals} critical",
            ),
            settled_rulings=rulings,
            findings=stamped,
        )

    return tuple(lane_carved(at, folders) for at, (_, folders) in enumerate(packs) if folders)


# --- [RECONCILE]


def lane_slices(round_dir: Path, /) -> tuple[tuple[Path, LaneSlice], ...]:
    return tuple(Block.of_seq(sorted(round_dir.glob("lane-?.json"))).choose(lambda path: shaped(path, LaneSlice).map(lambda held: (path, held))))


def lane_reports(round_dir: Path, /) -> tuple[LaneReport, ...]:
    return tuple(Block.of_seq(sorted(round_dir.glob("lane-?-report.json"))).choose(lambda path: shaped(path, LaneReport)))


def lane_stat(lane_path: Path, slice_: LaneSlice, round_dir: Path, /) -> LaneStat:
    report_path = round_dir / f"{slice_.manifest.lane}-report.json"
    report = shaped(report_path, LaneReport)
    ids = {row.id for row in slice_.findings}
    ledger_ids = tuple(row.id for row in report.map(lambda held: held.ledger).default_value(()))
    sliced_at = catch(exception=OSError)(lane_path.stat)().map(lambda held: held.st_mtime).default_with(lambda _f: 0.0)
    reported_at = catch(exception=OSError)(report_path.stat)().map(lambda held: held.st_mtime).default_with(lambda _f: sliced_at)
    wall = report.bind(lambda held: Some(held.wall_s) if held.wall_s > 0 else Nothing).default_with(lambda: reported_at - sliced_at)
    return LaneStat(
        lane=slice_.manifest.lane,
        model=report.map(lambda held: held.model).default_value(""),
        findings=slice_.manifest.count,
        verdicts=report.map(lambda held: dict(Counter(row.verdict or "<blank>" for row in held.ledger))).default_value({}),
        missing=tuple(sorted(ids - set(ledger_ids))),
        phantom=tuple(sorted(set(ledger_ids) - ids - {""})),
        wall_s=round(max(wall, 0.0), 1),
        report_valid=report.is_some(),
    )


def reconciled(round_dir: Path, /) -> Result[tuple[LaneStat, ...], Fault]:
    slices = lane_slices(round_dir)
    if not slices:
        return Error(Fault(code="no-lanes", detail=f"no lane-?.json under {round_dir}; slice first"))
    return Ok(tuple(lane_stat(path, slice_, round_dir) for path, slice_ in slices))


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


def proposal_block(fresh: tuple[Refutation, ...], round_no: int, /) -> tuple[str, ...]:
    if not fresh:
        return ()
    rows = [
        {
            "class_id": slugged(entry.claim),
            "matchers": [stemmed(entry.claim)],
            "refuting_citation": "",
            "landed_surfaces": [],
            "rounds_seen": [round_no],
        }
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
    return tuple(row for row in registry.classes if row.class_id in recurred_ids and row.landed_surfaces and row.rounds_seen)


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
            f"- `{row.class_id}` — landed on {', '.join(row.landed_surfaces)}; seen rounds {', '.join(map(str, row.rounds_seen))} and again this"
            " round — the wording failed: harden it, never skip as already-owned"
            for row in ineffective_of(registry, recurred_ids)
        ),
        "## [NEW_REFUTED]",
        *(f"- {entry.claim} — {entry.evidence}" for entry in fresh),
        *proposal_block(fresh, run.round),
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


def feedback_stub(row: RefutedClass, round_no: int, /) -> str:
    rounds = ", ".join(map(str, (*row.rounds_seen, round_no)))
    surfaces = ", ".join(row.landed_surfaces)
    slug = slugged(row.class_id)
    citation = f" Citation: {row.refuting_citation}." if row.refuting_citation else ""
    return "\n".join((
        "---",
        f"name: feedback_{slug}",
        f'description: "{row.class_id} recurs across rounds {rounds} despite guards on {surfaces}"',
        "metadata:",
        "  node_type: memory",
        "  type: feedback",
        "---",
        (
            f"`{row.class_id}` recurs across rounds {rounds} despite landed guards on {surfaces} — the guard mechanism, not the claim, needs a"
            f" process change.{citation}"
        ),
        "",
        "Proposed MEMORY.md index row:",
        f"- [{slug.replace('-', ' ')}](feedback_{slug}.md) — {row.class_id} guard ineffective across rounds {rounds}",
        "",
    ))


def proposals_written(
    context: Context, recurred_ids: frozenset[str], reports: tuple[LaneReport, ...], registry: Registry, /
) -> Result[tuple[str, ...], Fault]:
    refs = tuple(Block.of_seq(tuple(row for report in reports for row in report.capability)).choose(roster_row))
    feds = tuple(row for row in registry.classes if len(row.rounds_seen) >= 2 and row.landed_surfaces and row.class_id in recurred_ids)
    jobs: tuple[tuple[str, str], ...] = (
        *((f"reference_{slug}.md", reference_stub(slug, members, evidence, context.run.round)) for slug, members, evidence in refs),
        *((f"feedback_{slugged(row.class_id)}.md", feedback_stub(row, context.run.round)) for row in feds),
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


def row_built(
    context: Context, rows: tuple[Finding, ...], stats: tuple[LaneStat, ...], reports: tuple[LaneReport, ...], registry: Registry, /
) -> RoundRow:
    recurred, fresh = recurrence(registry, rows, reports)
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
        provenance_by_class=shaped(context.round_dir / PROVENANCE_NAME, dict[str, int]).default_value({}),
        corroboration_histogram=corroboration_hist(context.repo, rows),
        commit=sh(("git", "-C", str(context.repo), "rev-parse", "--short", "HEAD")).default_with(lambda _f: ""),
        at=round(time.time(), 1),
        focus=context.run.focus,
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


def gt_verified(repo: Path, rule: str, path: str, /) -> Result[VerifyReceipt, Fault]:
    argv = ("greptile", "config", *((path,) if path else ()))
    return sh(argv, cwd=repo).map(
        lambda effective: VerifyReceipt(
            rule=rule,
            path=path,
            effective=rule.casefold() in ANSI_RE.sub("", effective).casefold(),
            matched=next((plain(line) for line in effective.splitlines() if rule.casefold() in line.casefold()), ""),
            source=shlex.join(argv),
        )
    )


def ms_verified(repo: Path, guard: SurfaceGuard, /) -> VerifyReceipt:
    home = repo / ".macroscope"
    target = home / guard.path if guard.path else home
    text = read_bytes(target).map(lambda raw: raw.decode(errors="replace")).default_with(lambda _f: "") if target.is_file() else ""
    effective = bool(guard.path) and target.is_file() and (not guard.text or guard.text.casefold() in text.casefold())
    return VerifyReceipt(
        rule=guard.text, path=str(target), effective=effective, matched=str(target) if effective else "", source="macroscope-topic-file"
    )


def surface_checked(repo: Path, guard: SurfaceGuard, /) -> VerifyReceipt:
    match REVIEWER_ALIASES.get(guard.surface.strip().lower()):
        case "coderabbit":
            return cr_verified(repo, guard)
        case "greptile":
            return gt_verified(repo, guard.text, guard.path).default_with(
                lambda fault: VerifyReceipt(rule=guard.text, path=guard.path, effective=False, matched=fault.detail, source="greptile config")
            )
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
        pattern=re.compile(r"Unable to determine base branch", re.IGNORECASE),
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
            stall_grace_s=600.0,
            deadline_s=2700.0,
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
    ),
})

# --- [ENTRY] ----------------------------------------------------------------------------

type _Dir = Annotated[Path | None, Parameter(name=("--dir", "--directory"))]
type _RoundNo = Annotated[int | None, Parameter(name="--round")]
type _AllLive = Annotated[bool, Parameter(name="--all-live")]


def focus_resolved(spec: str, /) -> Result[str, Fault]:
    candidate = Path(spec)
    return read_bytes(candidate).map(lambda raw: raw.decode(errors="replace")) if spec and candidate.is_file() else Ok(spec)


def launched(repo: Path, reviewer: Reviewer, scope: Scope, focus: str, levers: Levers, /) -> Result[LaunchReceipt, Fault]:
    adapter = ADAPTERS[reviewer]
    if scope.kind not in adapter.scopes:
        return Error(Fault(code="unsupported-scope", detail=f"{reviewer} accepts {sorted(adapter.scopes)}, not {scope.line!r}"))
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
    rounds = round_dirs(repo)
    number = (round_number(rounds[-1]) if rounds else 0) + 1
    round_dir = repo / STATE_DIR / f"round-{number:03d}"
    made = catch(exception=OSError)(round_dir.mkdir)(parents=True).map_error(
        lambda unmakeable: Fault(code="unwritable", detail=f"{round_dir}: {unmakeable}")
    )

    def unrounded(fault: Fault, /) -> Fault:
        catch(exception=OSError)(shutil.rmtree)(round_dir)
        return fault

    def armed_and_spawned(_made: object, /) -> Result[LaunchReceipt, Fault]:
        focus_argv: Result[tuple[str, ...], Fault] = Ok(()) if not focus else adapter.focused(focus, round_dir)
        return focus_argv.map_error(unrounded).bind(lambda extra: flown((*base_argv, *extra)))

    def flown(argv: tuple[str, ...], /) -> Result[LaunchReceipt, Fault]:
        return spawned(argv, round_dir / LOG_NAME, repo).bind(
            lambda pid: written(
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
        )

    return made.bind(armed_and_spawned)


@APP.command
def launch(
    *,
    reviewer: Reviewer,
    scope: str,
    focus: str = "",
    light: bool = False,
    resume: bool = False,
    include: tuple[str, ...] = (),
    directory: _Dir = None,
) -> int:
    levers = Levers(light=light, resume=resume, include=include)
    return delivered(
        repo_root(directory).bind(
            lambda repo: Scope.of(scope).bind(lambda parsed: focus_resolved(focus).bind(lambda text: launched(repo, reviewer, parsed, text, levers)))
        )
    )


def followed(context: Context, /) -> int:
    probe, offset = StreamProbe(), 0
    last: Phase | Literal[""] = ""
    noted = time.time()
    while True:  # bounded: phased() converts every hang to a terminal verdict, and the killed sentinel short-circuits, so this loop always exits
        receipt, probe, offset = stepped_status(context, probe, offset)
        if receipt.phase in TERMINAL:
            emitted(receipt)
            return 0 if receipt.phase == "completed" else 1
        now = time.time()
        if receipt.phase != last:
            last, noted = receipt.phase, now
            print(liveness_line(receipt))
        elif now - noted > LIVENESS_NOTE_S:
            noted = now
            print(liveness_line(receipt))
        time.sleep(POLL_S)


def followed_all(repo: Path, /) -> int:
    tracked = [(context, StreamProbe(), 0, "") for context, _receipt in live_pairs(repo)]
    if not tracked:
        emitted(LiveStatus(rounds=(), all_terminal=True, live=0))
        return 0
    finals: list[StatusReceipt] = []
    noted = time.time()
    while tracked:  # bounded: each round's phased() deadline is terminal, so the aggregate loop cannot outlive the max per-round deadline
        moved: list[tuple[Context, StreamProbe, int, str]] = []
        pulse_due = time.time() - noted > LIVENESS_NOTE_S
        for context, probe, offset, last in tracked:
            receipt, grown, at = stepped_status(context, probe, offset)
            if receipt.phase in TERMINAL:
                finals.append(receipt)
                print(liveness_line(receipt))
            else:
                if receipt.phase != last or pulse_due:
                    print(liveness_line(receipt))
                moved.append((context, grown, at, receipt.phase))
        if pulse_due:
            noted = time.time()
        tracked = moved
        if tracked:
            time.sleep(POLL_S)
    ordered = tuple(sorted(finals, key=lambda receipt: receipt.round))
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


@APP.command
def status(*, follow: bool = False, all_live: _AllLive = False, reviewer: str = "", round_no: _RoundNo = None, directory: _Dir = None) -> int:
    match repo_root(directory):
        case Result(tag="error", error=fault):
            return refused(fault)
        case Result(tag="ok", ok=repo):
            pass
        case _:
            return 1
    if all_live:
        if follow:
            return followed_all(repo)
        pairs = live_pairs(repo)
        return emitted(LiveStatus(rounds=tuple(receipt for _context, receipt in pairs), all_terminal=not pairs, live=len(pairs)))
    match status_target(repo, round_no, reviewer), follow:
        case (Result(tag="error", error=fault), _):
            return refused(fault)
        case (Result(tag="ok", ok=held), True):
            return followed(held)
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
        rounds = round_dirs(repo)
        number = (round_number(rounds[-1]) if rounds else 0) + 1
        round_dir = repo / STATE_DIR / f"round-{number:03d}"
        scope = Scope(kind="union", ref=",".join(f"{REVIEWER_SHORT[src.run.reviewer]}:{src.run.scope.line}" for src in srcs))
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
        made = catch(exception=OSError)(round_dir.mkdir)(parents=True).map_error(
            lambda unmakeable: Fault(code="unwritable", detail=f"{round_dir}: {unmakeable}")
        )
        return made.bind(
            lambda _made: written(round_dir / RUN_NAME, ENCODER.encode(run)).bind(
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
        )

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
    return delivered(repo_root(directory).bind(lambda repo: gather_targets(repo, all_live, reviewer, rounds).bind(lambda held: gathered(repo, held))))


def findings_normalized(context: Context, dedup_against: int | None, /) -> Result[FindingsReceipt, Fault]:
    adapter = ADAPTERS[context.run.reviewer]
    if context.run.kind == "gather":
        return Error(Fault(code="no-process", detail=f"round {context.run.round} is a gather round; its findings.json lands normalized at gather"))
    if tuple(context.round_dir.glob("lane-?.json")):
        return Error(Fault(code="already-sliced", detail=f"{context.round_dir} carries lane slices; a re-normalize would orphan the stamped ids"))
    terminal = observed(context)
    if terminal.phase != "completed":
        return Error(
            Fault(code="not-completed", detail=f"round {context.run.round} is {terminal.phase}: {terminal.detail or 'wait for the terminal phase'}")
        )

    def landed(
        rows: tuple[Finding, ...], kept: tuple[Finding, ...], prior: Option[tuple[Path, tuple[Finding, ...]]], /
    ) -> Result[FindingsReceipt, Fault]:
        tagged = provenanced(kept, prior)
        histogram: dict[str, int] = {str(key): count for key, count in Counter(row.provenance for row in tagged if row.provenance).items()}
        prior_rows: tuple[Finding, ...] = prior.map(itemgetter(1)).default_value(())
        pruned, dropped = pruned_against(prior_rows, tagged)
        misfire = not rows and scope_dirty(context.repo, context.run.scope)
        return written(context.round_dir / PROVENANCE_NAME, ENCODER.encode(histogram)).bind(
            lambda _hist: written(context.round_dir / FINDINGS_NAME, ENCODER.encode(pruned)).map(
                lambda path: FindingsReceipt(
                    round=context.run.round,
                    reviewer=context.run.reviewer,
                    total=len(pruned),
                    deduped=len(rows) - len(kept),
                    cross_deduped=dropped,
                    classified=sum(1 for row in pruned if row.class_match),
                    counts_by_severity=counted(pruned),
                    provenance=histogram,
                    scope_misfire=misfire,
                    source=adapter.source(context),
                    path=str(path),
                )
            )
        )

    def persisted(rows: tuple[Finding, ...], registry: Registry, /) -> Result[FindingsReceipt, Fault]:
        kept = normalized(rows, registry)
        return prior_pool(context.repo, context.run.round, dedup_against).bind(lambda prior: landed(rows, kept, prior))

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
    dedup_against: Annotated[int | None, Parameter(name="--dedup-against")] = None,
    round_no: _RoundNo = None,
    directory: _Dir = None,
) -> int:
    def summarized(context: Context, /) -> Result[FindingsReceipt, Fault]:
        return findings_read(context).map(
            lambda rows: FindingsReceipt(
                round=context.run.round,
                reviewer=context.run.reviewer,
                total=len(rows),
                deduped=0,
                cross_deduped=0,
                classified=sum(1 for row in rows if row.class_match),
                counts_by_severity=counted(rows),
                provenance={str(key): count for key, count in Counter(row.provenance for row in rows if row.provenance).items()},
                scope_misfire=not rows and scope_dirty(context.repo, context.run.scope),
                source=str(context.round_dir / FINDINGS_NAME),
                path=str(context.round_dir / FINDINGS_NAME),
            )
        )

    resolved = context_resolved(directory, round_no)
    return delivered(resolved.bind(lambda context: findings_normalized(context, dedup_against) if normalize else summarized(context)))


@APP.command(name="slice")
def slice_cmd(
    *,
    lanes: Annotated[int, Parameter(name="--lanes")] = 3,
    by: SliceAxis = "folder",
    balance: Balance = "count",
    round_no: _RoundNo = None,
    directory: _Dir = None,
) -> int:
    def carved_round(context: Context, /) -> Result[SliceReceipt, Fault]:
        if not 1 <= lanes <= LANES_CAP:
            return Error(Fault(code="bad-lane", detail=f"lanes must be 1..{LANES_CAP}, got {lanes}"))
        stale = (*context.round_dir.glob("lane-?.json"), *context.round_dir.glob("lane-?-report.json"))
        return unlinked(stale).bind(
            lambda cleared: registry_loaded().bind(
                lambda registry: findings_read(context).bind(
                    lambda rows: slices_written(
                        context, sliced(rows, lanes, by, balance, context.repo, context.run.round, rulings_of(registry)), cleared
                    )
                )
            )
        )

    def slices_written(context: Context, packs: tuple[LaneSlice, ...], cleared: int, /) -> Result[SliceReceipt, Fault]:
        if not packs:
            return Error(Fault(code="no-findings", detail=f"round {context.run.round} has zero findings to slice; close it with `round` and rotate"))
        stamped = tuple(row for pack in packs for row in pack.findings)
        writes = (
            *((context.round_dir / f"{pack.manifest.lane}.json", ENCODER.encode(pack)) for pack in packs),
            (context.round_dir / FINDINGS_NAME, ENCODER.encode(stamped)),
        )
        outcome: Result[Path, Fault] = reduce(lambda acc, job: acc.bind(lambda _done: written(*job)), writes, Ok(context.round_dir))
        return outcome.map(
            lambda _last: SliceReceipt(
                round=context.run.round,
                lanes=tuple(pack.manifest for pack in packs),
                stamped=len(stamped),
                settled_rulings=len(packs[0].settled_rulings),
                cleared=cleared,
            )
        )

    return delivered(context_resolved(directory, round_no).bind(carved_round))


@APP.command
def reconcile(
    lane: str = "", /, *, all_lanes: Annotated[bool, Parameter(name="--all")] = False, round_no: _RoundNo = None, directory: _Dir = None
) -> int:
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
                    )
                )
            )
        )

    return delivered(context_resolved(directory, round_no).bind(resolved))


@APP.command
def harvest(*, round_no: _RoundNo = None, directory: _Dir = None) -> int:
    def gathered_feed(context: Context, /) -> Result[HarvestReceipt, Fault]:
        reports = lane_reports(context.round_dir)
        if not reports:
            return Error(Fault(code="no-report", detail=f"no lane-?-report.json under {context.round_dir}; fixer lanes write reports first"))
        return registry_loaded().bind(lambda registry: findings_read(context).bind(lambda rows: fed(context, registry, rows, reports)))

    def fed(context: Context, registry: Registry, rows: tuple[Finding, ...], reports: tuple[LaneReport, ...], /) -> Result[HarvestReceipt, Fault]:
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

    return delivered(context_resolved(directory, round_no).bind(gathered_feed))


@APP.command(name="round")
def round_cmd(*, round_no: _RoundNo = None, directory: _Dir = None) -> int:
    def closed(context: Context, /) -> Result[RoundReceipt, Fault]:
        if any(row.round == context.run.round for row in rounds_read(context.repo)):
            return Error(Fault(code="already-closed", detail=f"round {context.run.round} already has a {LEDGER_NAME} row"))
        return registry_loaded().bind(lambda registry: findings_read(context).bind(lambda rows: assembled(context, rows, registry)))

    def assembled(context: Context, rows: tuple[Finding, ...], registry: Registry, /) -> Result[RoundReceipt, Fault]:
        if not rows:
            return appended(context, row_built(context, rows, (), (), registry))
        reports = lane_reports(context.round_dir)
        if not reports:
            return Error(
                Fault(code="no-report", detail=f"round {context.run.round} has findings but no lane-?-report.json; fix lanes before closing")
            )
        return reconciled(context.round_dir).bind(lambda stats: appended(context, row_built(context, rows, stats, reports, registry)))

    def appended(context: Context, row: RoundRow, /) -> Result[RoundReceipt, Fault]:
        prior = next((held for held in reversed(rounds_read(context.repo)) if held.round < row.round), None)
        return written(context.repo / STATE_DIR / LEDGER_NAME, ENCODER.encode(row) + b"\n", append=True).map(
            lambda _path: RoundReceipt(row=row, delta=delta_of(prior, row))
        )

    return delivered(context_resolved(directory, round_no).bind(closed))


@APP.command
def verify(*, rule: str = "", path: str = "", round_no: _RoundNo = None, directory: _Dir = None) -> int:
    match bool(rule), round_no is not None:
        case (True, False):
            match repo_root(directory).bind(lambda repo: gt_verified(repo, rule, path)):
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


if __name__ == "__main__":
    sys.exit(APP(sys.argv[1:], result_action="return_value"))
