"""Save and restore a whole directory tree through APFS clones.

`save <path>` clones the tree in one `clonefile(2)` call. `restore <id>` swaps
every top-level entry but `.git` with its saved twin through
`renamex_np(RENAME_SWAP)`, so the state just undone becomes the saved copy and
a second restore takes it back. `list` prints one JSON line per save and
`drop <id>` deletes a save in the background.
"""

import argparse
import ctypes
import json
import os
import subprocess
import sys
import time
from collections.abc import Iterator
from pathlib import Path

STORE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "savestate"
SYNCED = Path.home() / "Library/CloudStorage"
KEPT = frozenset({".git"})
RENAME_SWAP = 0x2

libsystem = ctypes.CDLL(None, use_errno=True)


def _call(name: str, *arguments: bytes | int) -> None:
    if getattr(libsystem, name)(*arguments) != 0:
        code = ctypes.get_errno()
        raise OSError(code, f"{name}: {os.strerror(code)}")


def _saves() -> Iterator[dict[str, str]]:
    for record in sorted(STORE.glob("*/save.json")):
        yield json.loads(record.read_text())


def _saved(identity: str) -> tuple[Path, dict[str, str]]:
    home = STORE / identity
    return home / "tree", json.loads((home / "save.json").read_text())


def save(path: str) -> dict[str, str | float]:
    source = Path(path).resolve(strict=True)
    if source.is_relative_to(SYNCED):
        raise ValueError(f"{source} is cloud-synced: a clone downloads every file and a restore re-uploads the folder")
    started = time.monotonic()
    identity = f"{source.name}-{time.strftime('%Y%m%dT%H%M%S')}"
    home = STORE / identity
    home.mkdir(parents=True)
    _call("clonefile", os.fsencode(source), os.fsencode(home / "tree"), 0)
    record = {"id": identity, "path": str(source), "saved": time.strftime("%Y-%m-%dT%H:%M:%S%z")}
    (home / "save.json").write_text(json.dumps(record))
    return {**record, "seconds": round(time.monotonic() - started, 2)}


def restore(identity: str) -> dict[str, str | list[str]]:
    tree, record = _saved(identity)
    live = Path(record["path"])
    names = sorted(({entry.name for entry in tree.iterdir()} | {entry.name for entry in live.iterdir()}) - KEPT)
    for name in names:
        saved, current = tree / name, live / name
        if saved.exists() and current.exists():
            _call("renamex_np", os.fsencode(saved), os.fsencode(current), RENAME_SWAP)
        elif saved.exists():
            saved.rename(current)
        else:
            current.rename(saved)
    return {**record, "swapped": names, "kept": sorted(KEPT)}


def drop(identity: str) -> dict[str, str]:
    tree, record = _saved(identity)
    subprocess.Popen(["/bin/rm", "-rf", str(tree.parent)], start_new_session=True)  # noqa: S603
    return {**record, "dropping": str(tree.parent)}


def main() -> int:
    parser = argparse.ArgumentParser(prog="savestate", description=__doc__.splitlines()[0])
    actions = parser.add_subparsers(dest="action", required=True)
    actions.add_parser("save", help="clone a tree, print its id").add_argument("target", metavar="path")
    actions.add_parser("restore", help="swap a tree with its save").add_argument("target", metavar="id")
    actions.add_parser("drop", help="delete a save in the background").add_argument("target", metavar="id")
    actions.add_parser("list", help="print every save as a JSON line")
    arguments = parser.parse_args()
    try:
        rows = _saves() if arguments.action == "list" else [{"save": save, "restore": restore, "drop": drop}[arguments.action](arguments.target)]
        for row in rows:
            sys.stdout.write(json.dumps(row) + "\n")
    except (OSError, ValueError) as fault:
        sys.stdout.write(json.dumps({"error": str(fault)}) + "\n")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
