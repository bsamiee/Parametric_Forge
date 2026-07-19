#!/usr/bin/env python3
"""Join the four PR-feedback surfaces into one deduplicated, severity-normalized finding set.

Reads reviews.json inline.json issue.json threads.json (plus head.txt) from --dir; emits the merged rows as a JSON array, or as a
markdown triage table under --md. Reply chains collapse to their root via in_reply_to_id; cross-reviewer dedup keys on
path:line:issue_class keeping the highest severity with every shadowed reviewer in dups[]. Read-only over the pull-comments.sh
disk snapshots; mutates nothing on GitHub.
"""

import argparse
from collections import Counter
from collections.abc import Iterable, Mapping
from copy import replace
from dataclasses import asdict, dataclass
from enum import IntEnum
from itertools import chain, starmap
import json
from pathlib import Path
import re
import sys
from typing import Final, Literal


# --- [TYPES] ----------------------------------------------------------------------------

type Json = object  # a foreign GitHub payload node; every field read routes through the typed _leaf reader, never direct indexing
type Grade = tuple[Severity, str]
type Freshness = Literal["fresh", "stale", "unknown", "n/a"]
type Surface = Literal["thread", "issue"]


class Severity(IntEnum):
    """Unified scale every reviewer's native grammar folds onto; name is the wire severity, value the rank."""

    CRITICAL = 4
    MAJOR = 3
    MINOR = 2
    NIT = 1
    INFO = 0


# --- [CONSTANTS] ------------------------------------------------------------------------

_BODY_CAP: Final = 2000
_CLASS_WIDTH: Final = 6
_SUMMARY_CAP: Final = 70
_BOT_SUFFIX: Final = "[bot]"
_HEAD_FILE: Final = "head.txt"
_RANK_ANCHOR: Final = "severity"
_SURFACES: Final = ("reviews.json", "inline.json", "issue.json", "threads.json")

_MARKUP: Final[re.Pattern[str]] = re.compile(r"<[^>]+>|`[^`]*`|https?://\S+|[*_#>|🔴🟠🟡🧹⚠️⚡🛠️🏗️]|\bP[0-3]\b")
_SPAN: Final[re.Pattern[str]] = re.compile(r"\s+")
_WORD: Final[re.Pattern[str]] = re.compile(r"[a-z0-9]+")
_STOPWORDS: Final[frozenset[str]] = frozenset(_WORD.findall("the a an is are to of in on and or this that it be should for"))

_HEADER: Final = (
    "| sev | reviewer | path:line | side | state | fresh | native | issue |",
    "| :-- | :------- | :-------- | :--- | :---- | :---- | :----- | :---- |",
)

# --- [MODELS] ---------------------------------------------------------------------------


@dataclass(frozen=True, slots=True, kw_only=True)
class _Cue:
    # One severity probe: pattern searched over body[:window] (0 = whole body); group-1 lowered keys graded, "" when groupless.
    pattern: re.Pattern[str]
    graded: Mapping[str, Grade]
    window: int = 0

    def read(self, body: str, /) -> Grade | None:
        found = self.pattern.search(body[: self.window] if self.window else body)
        return None if found is None else self.graded.get((found.group(1) or "").lower() if self.pattern.groups else "")


@dataclass(frozen=True, slots=True, kw_only=True)
class _Grammar:
    # One reviewer's severity grammar: ordered cues, first hit wins, fallback when none land; prefix widens the login match.
    logins: tuple[str, ...]
    cues: tuple[_Cue, ...]
    fallback: Grade
    prefix: bool = False

    def owns(self, reviewer: str, /) -> bool:
        return any(reviewer.startswith(login) if self.prefix else reviewer == login for login in self.logins)

    def graded(self, body: str, /) -> Grade:
        return next((grade for cue in self.cues if (grade := cue.read(body)) is not None), self.fallback)


@dataclass(frozen=True, slots=True, kw_only=True)
class Row:
    """One merged finding; field order is the merged.json key order, severity_rank derives beside severity at egress."""

    surface: Surface
    reviewer: str
    author_is_bot: bool
    rest_comment_id: int | None
    thread_node_id: str | None
    review_db_id: int | None
    path: str | None
    line: int | None
    line_current: int | None
    line_original: int | None
    start_line: int | None
    diff_side: str | None
    subject_type: str | None
    severity: Severity
    native_severity: str
    is_resolved: bool | None
    is_outdated: bool | None
    viewer_can_resolve: bool | None
    commit_id: str | None
    freshness: Freshness
    reply_count: int
    url: str | None
    edited: bool | None
    updated_at: str | None
    body: str
    dedup_key: str
    dups: tuple[str, ...] = ()


# --- [TABLES] ---------------------------------------------------------------------------

_P_BADGE: Final[re.Pattern[str]] = re.compile(r"\bP([0-3])\b")
_CATEGORY: Final[re.Pattern[str]] = re.compile(r"\A\s*\*\*(logic|syntax|style)\b", re.IGNORECASE)
_MACRO_BADGE: Final[re.Pattern[str]] = re.compile(r"\*\*(Critical|High|Medium|Low)\*\*")

_P_GRADE: Final[Mapping[str, Severity]] = {"0": Severity.CRITICAL, "1": Severity.MAJOR, "2": Severity.MINOR, "3": Severity.NIT}
_CATEGORY_GRADE: Final[Mapping[str, Severity]] = {"logic": Severity.MAJOR, "syntax": Severity.MINOR, "style": Severity.NIT}
_MACRO_GRADE: Final[Mapping[str, Severity]] = {"Critical": Severity.CRITICAL, "High": Severity.MAJOR, "Medium": Severity.MINOR, "Low": Severity.NIT}
_CODERABBIT_MARKS: Final[tuple[tuple[str, str, Severity], ...]] = (
    ("🔴", "Critical", Severity.CRITICAL),
    ("🟠", "Major", Severity.MAJOR),
    ("🟡", "Minor", Severity.MINOR),
    ("🧹", "Nitpick", Severity.NIT),
)


def _marked(emoji: str, word: str, grade: Severity, /) -> tuple[_Cue, _Cue]:
    # CodeRabbit signals one severity two ways: its dot emoji anywhere in the body, or the severity word inside the first 80 chars.
    native: Mapping[str, Grade] = {"": (grade, f"CodeRabbit:{word}")}
    return _Cue(pattern=re.compile(re.escape(emoji)), graded=native), _Cue(pattern=re.compile(re.escape(word)), window=80, graded=native)


def _badged(label: str, *, window: int, digits: str = "0123") -> _Cue:
    return _Cue(pattern=_P_BADGE, window=window, graded={digit: (_P_GRADE[digit], f"{label}:P{digit}") for digit in digits})


_GRAMMARS: Final[tuple[_Grammar, ...]] = (
    _Grammar(
        logins=("coderabbitai", "coderabbit"),
        cues=tuple(chain.from_iterable(starmap(_marked, _CODERABBIT_MARKS))),
        fallback=(Severity.MINOR, "CodeRabbit:Potential"),
    ),
    _Grammar(
        logins=("greptile",),
        prefix=True,
        cues=(
            _Cue(pattern=_CATEGORY, graded={word: (grade, f"Greptile:{word}") for word, grade in _CATEGORY_GRADE.items()}),
            _badged("Greptile", window=60, digits="123"),
        ),
        fallback=(Severity.MINOR, "Greptile:?"),
    ),
    _Grammar(
        logins=("macroscopeapp",),
        cues=(_Cue(pattern=_MACRO_BADGE, window=80, graded={word.lower(): (grade, f"Macroscope:{word}") for word, grade in _MACRO_GRADE.items()}),),
        fallback=(Severity.MINOR, "Macroscope:?"),
    ),
    _Grammar(logins=("chatgpt-codex-connector",), cues=(_badged("Codex", window=120),), fallback=(Severity.MAJOR, "Codex:?")),
)

# --- [OPERATIONS] -----------------------------------------------------------------------


def _leaf[T](node: object, kind: type[T], /, *path: str) -> T | None:
    probe: object = node
    for key in path:
        probe = probe.get(key) if isinstance(probe, Mapping) else None
    return probe if isinstance(probe, kind) else None


def _normalized(login: str | None, /) -> str:
    return (login or "").lower().removesuffix(_BOT_SUFFIX)


def _graded(reviewer: str, body: str, /) -> Grade:
    grammar = next((candidate for candidate in _GRAMMARS if candidate.owns(reviewer)), None)
    return grammar.graded(body) if grammar else (Severity.INFO, f"{reviewer}:lint")


def _classified(body: str, /) -> str:
    words = _WORD.findall(_MARKUP.sub(" ", body).lower())
    return "-".join([word for word in words if word not in _STOPWORDS][:_CLASS_WIDTH])


def _freshness(head: str | None, commit: str | None, /) -> Freshness:
    return "stale" if head and commit and commit != head else "fresh" if head else "unknown"


def _edited(node: Json, /) -> tuple[bool | None, str | None]:
    created, updated = _leaf(node, str, "created_at"), _leaf(node, str, "updated_at")
    return (updated > created if created and updated else None), updated


def _rooted(comment: Json, by_id: Mapping[int, Json], /) -> Json:
    node, seen = comment, set[int]()
    while (
        (own := _leaf(node, int, "id")) is not None
        and own not in seen
        and (parent := _leaf(node, int, "in_reply_to_id")) is not None
        and parent in by_id
    ):
        seen.add(own)
        node = by_id[parent]
    return node


def _anchored(thread: Json, /) -> int | None:
    # GraphQL threads join to their REST root through the first comment's databaseId.
    nodes = _leaf(thread, list, "comments", "nodes")
    return _leaf(nodes[0], int, "databaseId") if nodes else None


def _loaded(directory: Path, name: str, /) -> tuple[Json, ...]:
    payload: object = json.loads((directory / name).read_text(encoding="utf-8"))
    return tuple(node for node in payload if isinstance(node, Mapping)) if isinstance(payload, list) else ()


def _thread_row(root: Json, thread: Json, review: Json, head: str | None, replies: int, /) -> Row:
    body = _leaf(root, str, "body") or ""
    reviewer = _normalized(_leaf(root, str, "user", "login"))
    severity, native = _graded(reviewer, body)
    line_current = _leaf(root, int, "line")
    line = line_current if line_current is not None else _leaf(root, int, "original_line")
    commit = _leaf(root, str, "commit_id") or _leaf(review, str, "commit_id")
    edited, updated = _edited(root)
    return Row(
        surface="thread",
        reviewer=reviewer,
        author_is_bot=_leaf(root, str, "user", "type") == "Bot",
        rest_comment_id=_leaf(root, int, "id"),
        thread_node_id=_leaf(thread, str, "id"),
        review_db_id=_leaf(root, int, "pull_request_review_id"),
        path=_leaf(root, str, "path"),
        line=line,
        line_current=line_current,
        line_original=_leaf(root, int, "original_line"),
        start_line=_leaf(root, int, "start_line") or _leaf(root, int, "original_start_line"),
        diff_side=_leaf(root, str, "side"),
        subject_type=_leaf(root, str, "subject_type"),
        severity=severity,
        native_severity=native,
        is_resolved=_leaf(thread, bool, "isResolved"),
        is_outdated=_leaf(thread, bool, "isOutdated"),
        viewer_can_resolve=_leaf(thread, bool, "viewerCanResolve"),
        commit_id=commit,
        freshness=_freshness(head, commit),
        reply_count=replies,
        url=_leaf(root, str, "html_url"),
        edited=edited,
        updated_at=updated,
        body=body[:_BODY_CAP],
        dedup_key=f"{_leaf(root, str, 'path')}:{line}:{_classified(body)}",
    )


def _issue_row(comment: Json, /) -> Row:
    body = _leaf(comment, str, "body") or ""
    reviewer = _normalized(_leaf(comment, str, "user", "login"))
    severity, native = _graded(reviewer, body)
    edited, updated = _edited(comment)
    return Row(
        surface="issue",
        reviewer=reviewer,
        author_is_bot=True,
        rest_comment_id=_leaf(comment, int, "id"),
        thread_node_id=None,
        review_db_id=None,
        path=None,
        line=None,
        line_current=None,
        line_original=None,
        start_line=None,
        diff_side=None,
        subject_type="summary",
        severity=severity,
        native_severity=native,
        is_resolved=None,
        is_outdated=None,
        viewer_can_resolve=None,
        commit_id=None,
        freshness="n/a",
        reply_count=0,
        url=_leaf(comment, str, "html_url"),
        edited=edited,
        updated_at=updated,
        body=body[:_BODY_CAP],
        dedup_key=f"summary:{reviewer}",
    )


def _deduped(rows: Iterable[Row], /) -> list[Row]:
    best: dict[str, Row] = {}
    for row in rows:
        incumbent = best.get(row.dedup_key)
        best[row.dedup_key] = (
            row
            if incumbent is None
            else replace(row, dups=(*row.dups, incumbent.reviewer, *incumbent.dups))
            if row.severity > incumbent.severity
            else replace(incumbent, dups=(*incumbent.dups, row.reviewer, *row.dups))
        )
    return sorted(best.values(), key=lambda row: (-row.severity, row.path or "~", row.line or 0))


def _merged(directory: Path, head: str | None, /) -> list[Row]:
    reviews, inline, issue, threads = (_loaded(directory, name) for name in _SURFACES)
    by_review: Mapping[int | None, Json] = {rid: review for review in reviews if (rid := _leaf(review, int, "id")) is not None}
    by_thread = {dbid: thread for thread in threads if (dbid := _anchored(thread)) is not None}
    by_id = {cid: comment for comment in inline if (cid := _leaf(comment, int, "id")) is not None}
    roots: dict[int, Json] = {}
    tally: Counter[int] = Counter()
    for comment in inline:
        root = _rooted(comment, by_id)
        if (rid := _leaf(root, int, "id")) is not None:
            tally[rid] += 1
            roots.setdefault(rid, root)
    threaded = (
        _thread_row(root, by_thread.get(rid, {}), by_review.get(_leaf(root, int, "pull_request_review_id"), {}), head, tally[rid] - 1)
        for rid, root in roots.items()
    )
    summaries = (_issue_row(comment) for comment in issue if _leaf(comment, str, "user", "type") == "Bot")
    return _deduped(chain(threaded, summaries))


def _encoded(row: Row, /) -> dict[str, object]:
    encoded: dict[str, object] = {}
    for name, value in asdict(row).items():
        encoded[name] = value.name if isinstance(value, Severity) else value
        if name == _RANK_ANCHOR:
            encoded["severity_rank"] = int(row.severity)
    return encoded


def _tabled(rows: Iterable[Row], /) -> str:
    def lined(row: Row, /) -> str:
        location = f"{row.path}:{row.line}" if row.path else f"({row.subject_type})"
        state = "resolved" if row.is_resolved else "outdated" if row.is_outdated else "open"
        summary = _SPAN.sub(" ", row.body)[:_SUMMARY_CAP]
        return f"| {row.severity.name} | {row.reviewer} | {location} | {row.diff_side or '-'} | {state} | {row.freshness} | {row.native_severity} | {summary} |"

    return "\n".join((*_HEADER, *map(lined, rows)))


# --- [ENTRY] ----------------------------------------------------------------------------


def _main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dir", type=Path, default=Path(), help="pull-comments.sh snapshot directory")
    parser.add_argument("--head", default=None, help="head SHA for freshness tagging; defaults to head.txt beside the snapshots")
    parser.add_argument("--md", action="store_true", help="emit the markdown triage table instead of merged JSON")
    args = parser.parse_args()
    directory: Path = args.dir
    head_path = directory / _HEAD_FILE
    head: str | None = args.head or (head_path.read_text(encoding="utf-8").strip() if head_path.is_file() else None)
    try:
        rows = _merged(directory, head)
    except (OSError, json.JSONDecodeError) as fault:
        sys.stderr.write(f"merge-comments: {fault}\n")
        return 2
    sys.stdout.write((_tabled(rows) if args.md else json.dumps([_encoded(row) for row in rows], indent=2, ensure_ascii=False)) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(_main())
