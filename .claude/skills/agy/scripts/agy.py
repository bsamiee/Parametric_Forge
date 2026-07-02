#!/usr/bin/env python3
# /// script
# requires-python = ">=3.15"
# dependencies = [
#   "anyio>=4.0",
#   "msgspec>=0.19",
#   "pydantic>=2.0",
#   "pydantic-settings>=2.0",
# ]
# ///
"""Antigravity CLI JSON wrapper for Claude/Codex skills."""

import argparse
from enum import StrEnum
import shutil
import sys
from typing import assert_never

import anyio
import msgspec
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class _Op(StrEnum):
    PROMPT = "prompt"
    MODELS = "models"


class _Fault(StrEnum):
    AUTH = "auth_required"
    BINARY = "binary_not_found"
    PROCESS = "process_error"
    QUOTA = "quota_exceeded"


class _Settings(BaseSettings):
    model_config = SettingsConfigDict(extra="ignore", frozen=True)

    agy_bin: str = Field(default="agy", validation_alias="AGY_BIN")
    agy_model: str = Field(default="Gemini 3.1 Pro (High)", validation_alias="AGY_MODEL")
    agy_print_timeout: str = Field(default="5m", validation_alias="AGY_PRINT_TIMEOUT")


class _Receipt(msgspec.Struct, frozen=True, gc=False):
    op: _Op
    output: str


class _Fail(msgspec.Struct, frozen=True, gc=False):
    op: _Op
    fault: _Fault
    detail: str


def _classify(text: str) -> _Fault:
    lowered = text.lower()
    return (
        _Fault.AUTH
        if any(token in lowered for token in ("sign in", "login", "unauthorized", "please sign in", "auth"))
        else _Fault.QUOTA
        if any(token in lowered for token in ("quota", "rate limit", "exhausted"))
        else _Fault.PROCESS
    )


def _emit(outcome: _Receipt | _Fail) -> int:
    sys.stdout.buffer.write(msgspec.json.encode(outcome))
    sys.stdout.buffer.write(b"\n")
    return 0


async def _run(op: _Op, argv: list[str]) -> int:
    try:
        completed = await anyio.run_process(argv, check=False)
    except FileNotFoundError as exc:
        return _emit(_Fail(op=op, fault=_Fault.BINARY, detail=str(exc)))

    stdout = completed.stdout.decode(errors="replace").strip()
    stderr = completed.stderr.decode(errors="replace").strip()
    return (
        _emit(_Fail(op=op, fault=_classify(stderr or stdout), detail=stderr or stdout))
        if completed.returncode != 0
        else _emit(_Receipt(op=op, output=stdout))
    )


async def _main(argv: list[str] | None = None) -> int:
    settings = _Settings()
    parser = argparse.ArgumentParser(prog="agy.py")
    sub = parser.add_subparsers(dest="op", required=True)

    prompt = sub.add_parser(_Op.PROMPT.value)
    prompt.add_argument("text")
    prompt.add_argument("--timeout", default=settings.agy_print_timeout)
    prompt.add_argument("--add-dir", action="append", default=[])

    sub.add_parser(_Op.MODELS.value)

    ns = parser.parse_args(argv)
    op = _Op(ns.op)
    if shutil.which(settings.agy_bin) is None:
        return _emit(_Fail(op=op, fault=_Fault.BINARY, detail=f"{settings.agy_bin} not found on PATH"))

    match op:
        case _Op.PROMPT:
            cmd = [settings.agy_bin, "--print", ns.text, "--print-timeout", ns.timeout]
            cmd.extend(part for path in ns.add_dir for part in ("--add-dir", path))
            if settings.agy_model:
                cmd.extend(("--model", settings.agy_model))
            return await _run(op, cmd)
        case _Op.MODELS:
            return await _run(op, [settings.agy_bin, "models"])
        case never:
            assert_never(never)


if __name__ == "__main__":
    raise SystemExit(anyio.run(_main))
