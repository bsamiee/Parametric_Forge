#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///
# ruff: noqa: T201, D100, D101, D103

import argparse
from collections.abc import Iterable
from dataclasses import dataclass
from enum import StrEnum
import itertools
import json
from pathlib import Path
import re
import sys
from typing import Literal


type Status = Literal["warn", "fail"]


class Check(StrEnum):
    DESC_BUDGET = "desc-budget"
    FORK = "fork"
    LISTING_SUM = "listing-sum"
    MISSING_FIELD = "missing-field"
    OVERLAP = "overlap"
    SHADOW = "shadow"
    STARVED = "starved"


DESC_CAP = 1024
DESC_CEILING = 1536
DF_CEILING = 0.5
FORK_MIN_CHARS = 60
LISTING_BUDGET = 8000
MIN_DISCRIMINANTS = 2
OVERLAP_THRESHOLD = 0.35

CODE_SPAN = re.compile(r"`[^`]+`")
EXTENSION_TOKEN = re.compile(r"\S*\.\w{2,4}\b")
FENCE = re.compile(r"^ {0,3}(?:`{3,}|~{3,})")
LIST_MARKER = re.compile(r"^\s*(?:[-+*]|\d+[.)])\s+(?:\[[A-Z0-9_]+\][:\s—-]*)?")
QUOTED_SPAN = re.compile(r"\"[^\"]+\"|“[^”]+”")
SCREAMING_TOKEN = re.compile(r"\b[A-Z][A-Z0-9_]{2,}\b")
WORD = re.compile(r"[a-z][a-z0-9]{2,}")
YAML_KEY = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*\s*:")

STOPWORDS = frozenset((
    "and",
    "any",
    "are",
    "atop",
    "based",
    "beat",
    "before",
    "being",
    "belong",
    "belongs",
    "between",
    "both",
    "each",
    "even",
    "every",
    "for",
    "from",
    "has",
    "have",
    "how",
    "into",
    "its",
    "like",
    "more",
    "most",
    "must",
    "never",
    "not",
    "off",
    "one",
    "only",
    "onto",
    "other",
    "out",
    "over",
    "own",
    "owns",
    "per",
    "such",
    "than",
    "that",
    "the",
    "their",
    "them",
    "then",
    "these",
    "this",
    "those",
    "through",
    "under",
    "use",
    "used",
    "uses",
    "using",
    "via",
    "what",
    "when",
    "where",
    "whether",
    "which",
    "while",
    "who",
    "whose",
    "with",
    "within",
    "without",
))


@dataclass(frozen=True, slots=True)
class Row:
    file: str
    line: int
    check: Check
    status: Status
    detail: str


@dataclass(frozen=True, slots=True)
class Bundle:
    scan_root: str
    path: Path
    name: str
    name_line: int
    description: str
    desc_line: int
    prose: tuple[tuple[int, str], ...]


def frontmatter_fields(lines: tuple[str, ...]) -> tuple[int, dict[str, tuple[int, str]]]:
    if not lines or lines[0].rstrip() != "---":
        return 0, {}
    end = next((n for n, line in enumerate(lines[1:], 2) if line.rstrip() == "---"), 0)
    if end == 0 or not any(YAML_KEY.match(body) for body in lines[1 : end - 1]):
        return 0, {}
    fields: dict[str, tuple[int, str]] = {}
    current: str | None = None
    for offset, line in enumerate(lines[1 : end - 1], 2):
        if YAML_KEY.match(line) and not line.startswith((" ", "\t")):
            current = line.split(":", 1)[0].strip()
            fields[current] = (offset, line.split(":", 1)[1].strip().lstrip(">|-").strip())
        elif current and line.startswith((" ", "\t")):
            anchor, value = fields[current]
            fields[current] = (anchor, f"{value} {line.strip()}".strip())
    return end, fields


def body_prose(lines: tuple[str, ...], start: int) -> tuple[tuple[int, str], ...]:
    prose: list[tuple[int, str]] = []
    fenced = False
    for number, line in enumerate(lines[start:], start + 1):
        if FENCE.match(line):
            fenced = not fenced
            continue
        if fenced or line.lstrip().startswith(("#", "|")) or not line.strip():
            continue
        normal = re.sub(r"\s+", " ", LIST_MARKER.sub("", line)).strip().lower()
        if len(normal) >= FORK_MIN_CHARS:
            prose.append((number, normal))
    return tuple(prose)


def load(scan_root: Path, path: Path) -> tuple[Bundle | None, tuple[Row, ...]]:
    try:
        lines = tuple(path.read_text(encoding="utf-8").splitlines())
    except (OSError, UnicodeDecodeError) as exc:
        return None, (Row(str(path), 0, Check.MISSING_FIELD, "fail", type(exc).__name__),)
    end, fields = frontmatter_fields(lines)
    rows = tuple(
        Row(str(path), 1, Check.MISSING_FIELD, "fail", f"frontmatter lacks {required}")
        for required in ("name", "description")
        if not fields.get(required, (0, ""))[1]
    )
    if rows:
        return None, rows
    name_line, name = fields["name"]
    desc_line, description = fields["description"]
    return Bundle(str(scan_root), path, name, name_line, description, desc_line, body_prose(lines, end)), ()


def discriminants(description: str) -> frozenset[str]:
    return frozenset(
        itertools.chain(
            CODE_SPAN.findall(description),
            QUOTED_SPAN.findall(description),
            EXTENSION_TOKEN.findall(CODE_SPAN.sub(" ", description)),
            SCREAMING_TOKEN.findall(CODE_SPAN.sub(" ", description)),
        )
    )


def token_sets(bundles: tuple[Bundle, ...]) -> dict[str, frozenset[str]]:
    raw = {bundle.name: frozenset(WORD.findall(bundle.description.lower())) - STOPWORDS for bundle in bundles}
    ceiling = DF_CEILING * max(1, len(raw))
    common = frozenset(
        token for token in frozenset().union(*raw.values() or [frozenset()]) if sum(token in words for words in raw.values()) > ceiling
    )
    return {name: words - common for name, words in raw.items()}


def budget_rows(bundle: Bundle) -> tuple[Row, ...]:
    size = len(bundle.description)
    if size > DESC_CEILING:
        return (Row(str(bundle.path), bundle.desc_line, Check.DESC_BUDGET, "fail", f"{size} chars > listing ceiling {DESC_CEILING}"),)
    if size > DESC_CAP:
        return (Row(str(bundle.path), bundle.desc_line, Check.DESC_BUDGET, "warn", f"{size} chars > portability budget {DESC_CAP}"),)
    return ()


def starved_rows(bundle: Bundle) -> tuple[Row, ...]:
    found = discriminants(bundle.description)
    if len(found) >= MIN_DISCRIMINANTS:
        return ()
    return (Row(str(bundle.path), bundle.desc_line, Check.STARVED, "warn", f"{len(found)} mechanical discriminants < floor {MIN_DISCRIMINANTS}"),)


def overlap_rows(bundles: tuple[Bundle, ...], threshold: float) -> tuple[Row, ...]:
    words = token_sets(bundles)
    rows: list[Row] = []
    for left, right in itertools.combinations(bundles, 2):
        if left.name == right.name:
            continue
        union = words[left.name] | words[right.name]
        shared = words[left.name] & words[right.name]
        score = len(shared) / len(union) if union else 0.0
        if score >= threshold:
            sample = ", ".join(sorted(shared)[:8])
            rows.append(Row(str(left.path), left.desc_line, Check.OVERLAP, "warn", f"{score:.2f} with {right.name}: {sample}"))
    return tuple(rows)


def shadow_rows(bundles: tuple[Bundle, ...]) -> tuple[Row, ...]:
    by_name: dict[str, list[Bundle]] = {}
    for bundle in bundles:
        by_name.setdefault(bundle.name, []).append(bundle)
    return tuple(
        Row(
            str(bundle.path),
            bundle.name_line,
            Check.SHADOW,
            "warn",
            f"{bundle.name} in {len(group)} roots: {', '.join(sorted({peer.scan_root for peer in group}))}",
        )
        for group in by_name.values()
        if len({peer.scan_root for peer in group}) > 1
        for bundle in group
    )


def fork_rows(bundles: tuple[Bundle, ...]) -> tuple[Row, ...]:
    owners: dict[str, list[tuple[Bundle, int]]] = {}
    for bundle in bundles:
        for number, line in bundle.prose:
            owners.setdefault(line, []).append((bundle, number))
    return tuple(
        Row(str(bundle.path), number, Check.FORK, "warn", f"line shared with {', '.join(sorted({peer.name for peer, _ in group} - {bundle.name}))}")
        for group in owners.values()
        if len({peer.name for peer, _ in group}) > 1
        for bundle, number in group
    )


def listing_rows(bundles: tuple[Bundle, ...], budget: int) -> tuple[Row, ...]:
    spend = sum(len(bundle.description) for bundle in bundles)
    if spend <= budget:
        return ()
    top = ", ".join(f"{bundle.name}={len(bundle.description)}" for bundle in sorted(bundles, key=lambda b: -len(b.description))[:5])
    return (
        Row(bundles[0].scan_root if bundles else ".", 0, Check.LISTING_SUM, "warn", f"listing spend {spend} chars > budget {budget}; top: {top}"),
    )


def emit(rows: Iterable[Row], json_mode: bool) -> None:
    for finding in rows:
        if json_mode:
            print(
                json.dumps({"file": finding.file, "line": finding.line, "check": finding.check, "status": finding.status, "detail": finding.detail})
            )
        else:
            print(f"{finding.file}:{finding.line}: {finding.status.upper()} {finding.check} {finding.detail}")


def run(roots: tuple[Path, ...], threshold: float, budget: int, json_mode: bool) -> int:
    rows: list[Row] = []
    bundles: list[Bundle] = []
    for scan_root in roots:
        if not scan_root.is_dir():
            rows.append(Row(str(scan_root), 0, Check.MISSING_FIELD, "fail", "not a directory"))
            continue
        for manifest in sorted(scan_root.resolve().rglob("SKILL.md")):
            bundle, faults = load(scan_root.resolve(), manifest)
            rows.extend(faults)
            if bundle:
                bundles.append(bundle)
    fleet = tuple(bundles)
    rows.extend(itertools.chain.from_iterable(budget_rows(bundle) + starved_rows(bundle) for bundle in fleet))
    rows.extend(overlap_rows(fleet, threshold) + shadow_rows(fleet) + fork_rows(fleet) + listing_rows(fleet, budget))
    emit(rows, json_mode)
    return 1 if any(finding.status == "fail" for finding in rows) else 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit a skill estate: budgets, starved triggers, overlap, forks, shadows, listing spend.")
    parser.add_argument("roots", nargs="+", type=Path, help="skill roots to sweep for SKILL.md bundles")
    parser.add_argument("--json", action="store_true", help="emit JSON rows")
    parser.add_argument("--overlap-threshold", type=float, default=OVERLAP_THRESHOLD, help="pairwise Jaccard floor that flags a collision candidate")
    parser.add_argument("--budget-chars", type=int, default=LISTING_BUDGET, help="fleet listing budget in description characters")
    args = parser.parse_args()
    return run(tuple(args.roots), args.overlap_threshold, args.budget_chars, args.json)


if __name__ == "__main__":
    sys.exit(main())
