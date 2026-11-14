"""Print copied Biome `App.MenuItem` segments as JSON lines `{at, bundle, path}`."""

import json
import sys
from collections.abc import Iterator

import ccl_segb


def _varint(buffer: bytes, index: int) -> tuple[int, int]:
    value = shift = 0
    while True:
        byte = buffer[index]
        index += 1
        value |= (byte & 0x7F) << shift
        shift += 7
        if byte < 0x80:
            return value, index


def _strings(buffer: bytes) -> Iterator[tuple[int, str]]:
    index = 0
    while index < len(buffer):
        key, index = _varint(buffer, index)
        match key & 7:
            case 0:
                _, index = _varint(buffer, index)
            case 1:
                index += 8
            case 2:
                length, index = _varint(buffer, index)
                yield key >> 3, buffer[index : index + length].decode(errors="replace")
                index += length
            case 5:
                index += 4
            case _:
                return


def _rows(paths: list[str]) -> Iterator[dict[str, str | None]]:
    for path in paths:
        for record in ccl_segb.read_segb_file(path):
            fields = dict(_strings(record.data))
            if 1 in fields:
                yield {"at": f"{record.timestamp1.isoformat()}Z", "bundle": fields[1], "path": fields.get(3)}


if __name__ == "__main__":
    for row in sorted(_rows(sys.argv[1:]), key=lambda row: str(row["at"])):
        sys.stdout.write(json.dumps(row, ensure_ascii=False) + "\n")
