#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["msgspec", "httpx"]
# ///
# Boundary-kernel hook seam: a fail-open observer swallows every fault to a guaranteed exit 0, and focused one-line docstrings carry no Returns section.
# ruff:file-ignore[blind-except, docstring-missing-returns, try-except-pass]
"""Forward every hook firing to a sink after the policy hook decides, without ever touching the verdict.

Chained second on the event array and wired async:true, the transmitter is non-blocking by construction: the whole
body sits under one broad swallow and a guaranteed exit 0, because a narrow catch lets an httpx.InvalidURL or
StreamError escape as a loop-blocking non-zero exit. One short-timeout shot fires and drops — a fire-and-forget
attention stream never retries a down collector into a pile-up. TIER picks the envelope: a private sink takes raw
plus flat hot keys, a bus takes a CloudEvents 1.0 shape.
"""

from datetime import datetime, UTC
from enum import StrEnum
import os
import sys
from time import time_ns

import httpx
import msgspec


SINK_URL = os.environ.get("HOOK_SINK_URL", "http://127.0.0.1:4000/events")  # POLICY: the collector; a dead one never gates
BRAND = os.environ.get("HOOK_PROVIDER", "claude")  # source tag so a dual-provider fleet's events self-identify their origin
NAMESPACE = "com.parametric-forge"  # reverse-DNS root for the CloudEvents type
MAX_PAYLOAD = 8 * 1024 * 1024  # bound the stdin read; a pathological payload never balloons resident memory
TIMEOUT = 2.0


class Tier(StrEnum):
    """The envelope shape as a policy value, never a scatter of format flags."""

    PRIVATE = "private"  # a dashboard or registry: raw payload nested whole, hot keys hoisted flat for indexless query
    BUS = "bus"  # a shared event bus: a CloudEvents 1.0 envelope that self-describes across producers


class Event(msgspec.Struct, frozen=True, rename={"event": "hook_event_name"}):
    """The hot query keys hoisted from the stdin payload."""

    event: str = ""
    session_id: str = ""
    tool_name: str = ""
    agent_id: str = ""


def _private(event: Event, raw: bytes, /) -> dict[str, object]:
    """Build the private-tier envelope: hot query keys flat beside the raw payload nested whole."""
    return {
        "toolname": event.tool_name,
        "sessionid": event.session_id,
        "eventname": event.event,
        "agentid": event.agent_id,
        "source": BRAND,
        "payload": msgspec.json.decode(raw),
    }


def _cloudevent(event: Event, raw: bytes, /) -> dict[str, object]:
    """Build the CloudEvents 1.0 envelope; hook identity rides flat lowercase extensions."""
    return {
        "specversion": "1.0",
        "type": f"{NAMESPACE}.hook.{event.event}",
        "source": BRAND,
        "id": f"{event.session_id}-{time_ns()}",
        "time": datetime.now(UTC).isoformat(),  # true UTC, never a tagged Z
        "sessionid": event.session_id,
        "toolname": event.tool_name,
        "data": msgspec.json.decode(raw),
    }


def envelope(event: Event, raw: bytes, tier: Tier, /) -> dict[str, object]:
    """Select the envelope by tier."""
    match tier:
        case Tier.PRIVATE:
            return _private(event, raw)
        case Tier.BUS:
            return _cloudevent(event, raw)


def main() -> int:
    """Decode, envelope, and post; every fault swallows to a guaranteed exit 0."""
    try:  # one broad swallow over decode, envelope, and POST; a collector fault never gates the loop the gate already ruled
        raw = sys.stdin.buffer.read(MAX_PAYLOAD)
        tier = Tier(os.environ.get("HOOK_SINK_TIER", Tier.PRIVATE))
        body = envelope(msgspec.json.decode(raw, type=Event), raw, tier)
        httpx.post(SINK_URL, json=body, timeout=TIMEOUT)
    except Exception:  # telemetry is advisory; every fault, including non-HTTPError httpx types, swallows to exit 0
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
