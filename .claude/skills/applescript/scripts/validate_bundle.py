#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.15"
# dependencies = ["anyio", "cyclopts", "expression", "msgspec"]
# ///
# ruff: noqa: T201, D100, D101, D103

# --- [RUNTIME_PRELUDE] ------------------------------------------------------------------

from enum import StrEnum
from pathlib import Path
import re
import tempfile
from typing import assert_never, Literal, TYPE_CHECKING

import anyio
from cyclopts import App
from expression import Error, Nothing, Ok, Some
from expression.collections import Block
import msgspec


if TYPE_CHECKING:
    from expression import Option, Result


# --- [VOCABULARY] -----------------------------------------------------------------------


class Lang(StrEnum):
    APPLESCRIPT = "AppleScript"
    JAVASCRIPT = "JavaScript"


class Check(StrEnum):
    COMPILE = "compile"
    ROUNDTRIP = "roundtrip"
    LINT_TID = "lint-tid"
    LINT_SHELL = "lint-shell"


type CheckFault = Literal[
    "<compile-failed>", "<decompile-failed>", "<recompile-failed>", "<tid-unrestored>", "<shell-unquoted>", "<toolchain-missing>", "<deadline>"
]
type Verdict = Literal["pass", "fail", "skip"]

OSACOMPILE = Path("/usr/bin/osacompile")
OSADECOMPILE = Path("/usr/bin/osadecompile")
EXTENSION: dict[str, str] = {Lang.APPLESCRIPT: "applescript", Lang.JAVASCRIPT: "jxa"}

FENCE = re.compile(r"^```(applescript|javascript)[^\n]*\n(.*?)\n```", re.MULTILINE | re.DOTALL)
PLACEHOLDER = re.compile(r"<[a-z][\w./-]*>|\.\.\.|…|use script \"")
TID_SET = re.compile(r"text item delimiters\s+to\b")
TID_RESTORE = re.compile(r"text item delimiters\s+to\s+(?:old|saved|prior|previous)\w*", re.IGNORECASE)
SHELL_CALL = re.compile(r"do shell script\b[^\n]*")
SHELL_UNQUOTED = re.compile(r"&\s*(?!quoted form of\b|space\b|linefeed\b|return\b|tab\b|\")[A-Za-z_]\w*\b")

ENCODER = msgspec.json.Encoder()
APP = App(name="validate-applescript", help="Compile-check, round-trip, and lint the bundle's OSA artifacts.")

# --- [OWNERS] ---------------------------------------------------------------------------


class Artifact(msgspec.Struct, frozen=True, gc=False):
    lang: Lang
    origin: str
    source: str
    strict: bool


class Skip(msgspec.Struct, frozen=True, gc=False):
    origin: str
    reason: str


type Admitted = Artifact | Skip


class Finding(msgspec.Struct, frozen=True, gc=False):
    origin: str
    check: Check
    verdict: Verdict
    strict: bool
    detail: str


class Report(msgspec.Struct, frozen=True, kw_only=True):
    artifacts: int
    passed: int
    failed: int
    skipped: int
    strict_failed: int
    findings: tuple[Finding, ...]


# --- [BOUNDARY_ADMISSION] ---------------------------------------------------------------


def _lang_of(suffix: str, /) -> Option[Lang]:
    match suffix:
        case ".applescript":
            return Some(Lang.APPLESCRIPT)
        case ".js" | ".jxa":
            return Some(Lang.JAVASCRIPT)
        case _:
            return Nothing


def _fence_lang(tag: str, /) -> Lang:
    return Lang.APPLESCRIPT if tag == "applescript" else Lang.JAVASCRIPT


def _template(path: Path, /) -> Option[Admitted]:
    return _lang_of(path.suffix).map(lambda lang: Artifact(lang=lang, origin=path.name, source=path.read_text(encoding="utf-8"), strict=True))


def _fences(path: Path, /) -> Block[Admitted]:
    text = path.read_text(encoding="utf-8")
    rows = (
        Skip(origin=f"{path.name}#{index}", reason="<placeholder-fragment>")
        if PLACEHOLDER.search(body)
        else Artifact(lang=_fence_lang(tag), origin=f"{path.name}#{index}", source=body, strict=False)
        for index, (tag, body) in enumerate(FENCE.findall(text))
    )
    return Block.of_seq(rows)


def discovered(bundle: Path, /) -> Block[Admitted]:
    templates = Block.of_seq(sorted((bundle / "templates").glob("*"))).choose(_template)
    examples = Block.of_seq(sorted((bundle / "examples").glob("*"))).choose(_template)
    documents = Block.of_seq(sorted((bundle / "references").glob("*.md")))
    return documents.fold(lambda acc, doc: acc.append(_fences(doc)), templates.append(examples))


# --- [PURE_LINTS] -----------------------------------------------------------------------


def _tid(source: str, /) -> Result[None, CheckFault]:
    return Error("<tid-unrestored>") if TID_SET.search(source) and not TID_RESTORE.search(source) else Ok(None)


def _shell(source: str, /) -> Result[None, CheckFault]:
    offending = (call for call in SHELL_CALL.findall(source) if SHELL_UNQUOTED.search(call))
    return Error("<shell-unquoted>") if next(offending, None) is not None else Ok(None)


def _finding(artifact: Artifact, check: Check, outcome: Result[object, CheckFault], /) -> Finding:
    verdict: Verdict = "pass" if outcome.is_ok() else "fail"
    detail = "" if outcome.is_ok() else str(outcome.swap().default_value("<unknown>"))
    return Finding(origin=artifact.origin, check=check, verdict=verdict, strict=artifact.strict, detail=detail)


def _lints(artifact: Artifact, /) -> Block[Finding]:
    if not artifact.strict or artifact.lang is not Lang.APPLESCRIPT:
        return Block.empty()
    checks = ((Check.LINT_TID, _tid(artifact.source)), (Check.LINT_SHELL, _shell(artifact.source)))
    return Block.of_seq(_finding(artifact, check, outcome) for check, outcome in checks)


# --- [COMPILE_RAIL] ---------------------------------------------------------------------


async def _osacompile(source: str, lang: Lang, workdir: Path, stem: str, /) -> Result[Path, CheckFault]:
    src = workdir / f"{stem}.{EXTENSION[lang]}"
    src.write_text(source, encoding="utf-8")
    out = workdir / f"{stem}.scpt"
    try:
        completed = await anyio.run_process([str(OSACOMPILE), "-l", lang, "-o", str(out), str(src)], check=False)
    except FileNotFoundError:  # Exemption: boundary-capture of an absent toolchain into the fault vocabulary.
        return Error("<toolchain-missing>")
    return Ok(out) if completed.returncode == 0 else Error("<compile-failed>")


async def _roundtrip(compiled: Path, lang: Lang, workdir: Path, /) -> Result[None, CheckFault]:
    decompiled = await anyio.run_process([str(OSADECOMPILE), str(compiled)], check=False)
    if decompiled.returncode != 0:
        return Error("<decompile-failed>")
    recompiled = await _osacompile(decompiled.stdout.decode("utf-8"), lang, workdir, "roundtrip")
    return recompiled.map(lambda _out: None).map_error(lambda _fault: "<recompile-failed>")


async def checked(artifact: Artifact, /) -> Block[Finding]:
    lints = _lints(artifact)
    with tempfile.TemporaryDirectory() as raw:  # Exemption: sync bracket for compiler scratch outputs.
        compiled = await _osacompile(artifact.source, artifact.lang, Path(raw), "artifact")
        if compiled.is_ok():
            roundtrip = await _roundtrip(compiled.default_value(Path(raw)), artifact.lang, Path(raw))
            staged = (_finding(artifact, Check.COMPILE, Ok(None)), _finding(artifact, Check.ROUNDTRIP, roundtrip))
        else:
            staged = (_finding(artifact, Check.COMPILE, compiled),)
    return lints.append(Block.of_seq(staged))


# --- [DISPOSITION] ----------------------------------------------------------------------


def _tally(findings: Block[Finding], /) -> tuple[int, int, int, int]:
    def step(acc: tuple[int, int, int, int], finding: Finding, /) -> tuple[int, int, int, int]:
        passed, failed, skipped, strict = acc
        match finding.verdict:
            case "pass":
                return (passed + 1, failed, skipped, strict)
            case "fail":
                return (passed, failed + 1, skipped, strict + int(finding.strict))
            case "skip":
                return (passed, failed, skipped + 1, strict)
            case _ as unreachable:
                return assert_never(unreachable)

    return findings.fold(step, (0, 0, 0, 0))


async def validated(bundle: Path, seconds: float, /) -> Report:
    admitted = discovered(bundle)
    artifacts = admitted.choose(lambda row: Some(row) if isinstance(row, Artifact) else Nothing)
    skips = admitted.choose(lambda row: Some(row) if isinstance(row, Skip) else Nothing)

    collected: Block[Finding] = Block.empty()
    with anyio.move_on_after(seconds) as scope:
        for artifact in artifacts:  # Exemption: async sequential fold — no async traverse exists.
            collected = collected.append(await checked(artifact))

    skip_rows = skips.map(lambda row: Finding(origin=row.origin, check=Check.COMPILE, verdict="skip", strict=False, detail=row.reason))
    timeout_rows = (
        Block.singleton(Finding(origin="<run>", check=Check.COMPILE, verdict="fail", strict=True, detail="<deadline>"))
        if scope.cancelled_caught
        else Block.empty()
    )
    findings = collected.append(skip_rows).append(timeout_rows)
    passed, failed, skipped, strict_failed = _tally(findings)
    artifact_count = artifacts.fold(lambda n, _a: n + 1, 0)
    return Report(artifacts=artifact_count, passed=passed, failed=failed, skipped=skipped, strict_failed=strict_failed, findings=tuple(findings))


# --- [EGRESS] ---------------------------------------------------------------------------


def _rendered(report: Report, /) -> str:
    header = f"artifacts={report.artifacts} pass={report.passed} fail={report.failed} skip={report.skipped} strict-fail={report.strict_failed}"
    rows = Block.of_seq(report.findings).choose(
        lambda finding: (
            Some(f"[{finding.verdict:<4}] {finding.origin} :: {finding.check} {finding.detail}".rstrip()) if finding.verdict != "pass" else Nothing
        )
    )
    body = rows.fold(lambda acc, line: f"{acc}\n{line}", header)
    return body if not rows.is_empty() else f"{header}\nall artifacts compile, round-trip, and lint clean"


@APP.default
def main(bundle: Path | None = None, /, *, json_out: bool = False, seconds: float = 240.0) -> None:
    root = bundle if bundle is not None else Path(__file__).resolve().parent.parent
    report = anyio.run(validated, root, seconds)
    print(ENCODER.encode(report).decode("utf-8") if json_out else _rendered(report))
    raise SystemExit(1 if report.strict_failed else 0)


if __name__ == "__main__":
    APP()
