# [SCRIPTING]

Python hooks ship as uv single-file scripts built from frozen constants, typed dispatch tables, and exhaustive pattern matching, with every subprocess boundary shell-free.

## [01]-[SHEBANG]

```python conceptual
#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.15"
# dependencies = ["httpx"]
# ///
```

## [02]-[TYPES]

```python conceptual
from collections.abc import Callable
from typing import Any, Final, NamedTuple

type Frontmatter = dict[str, str]
type ParseState = tuple[Frontmatter, str | None, list[str]]
type Handler = tuple[Callable[[dict], tuple[str, ...]], Callable[[str, dict], dict]]


class SkillEntry(NamedTuple):
    name: str
    trigger: str
```

## [03]-[CONSTANTS]

```python conceptual
from dataclasses import dataclass, field
import re


@dataclass(frozen=True, slots=True)
class _B:
    timeout: int = 60
    blocked: frozenset[str] = frozenset(("rm -rf", "sudo"))
    field_re: re.Pattern[str] = field(default_factory=lambda: re.compile(r"^([^:]+):(.*)$"))


B: Final[_B] = _B()
DEBUG: Final[bool] = os.environ.get("CLAUDE_HOOK_DEBUG", "").lower() in ("1", "true")
_debug = lambda msg: DEBUG and print(f"[hook] {msg}", file=sys.stderr)
```

## [04]-[DISPATCH]

```python conceptual
handlers: dict[str, Handler] = {
    "workspace": (lambda _: ("npx", "nx", "show", "projects", "--json"), lambda o, _: {"projects": json.loads(o)}),
    "project": (lambda a: ("npx", "nx", "show", "project", a["name"], "--json"), lambda o, a: {"name": a["name"], "project": json.loads(o)}),
}

# Decorator registration
_tools: dict[str, tuple[Callable, dict]] = {}


def tool(**cfg: Any) -> Callable[[Callable], Callable]:
    return lambda fn: (_tools.__setitem__(fn.__name__, (fn, {"method": "POST", **cfg})), fn)[1]
```

## [05]-[PATTERN_MATCHING]

```python conceptual
def _fold_line(state: ParseState, line: str) -> ParseState:
    result, field, parts = state
    match_ = B.field_re.match(line)
    match (match_, line.startswith(" "), field):
        case (m, False, _) if m and m.group(2).strip() in (">-", ">"):
            return ({**result, field: " ".join(parts)} if field else result, m.group(1).strip(), [])
        case (m, False, _) if m:
            return ({**result, m.group(1).strip(): m.group(2).strip().strip("'\"")}, None, [])
        case (_, True, f) if f:
            return (result, field, [*parts, line.strip()])
        case _:
            return state


# Exhaustive matching with assert_never
type Action = Literal["allow", "block", "ask"]


def handle(action: Action) -> int:
    match action:
        case "allow" | "ask":
            return 0
        case "block":
            return 2
        case _ as unreachable:
            assert_never(unreachable)
```

## [06]-[EXPRESSIONS]

```python conceptual
# Walrus in comprehension
lines = [line for n, g in B.groups if (line := f'<group name="{n}">{" ".join(g)}</group>')]

# Ternary chain
result = {"status": "success", **fmt(o, a)} if o else {"status": "error", "msg": f"{cmd} failed"}
```

## [07]-[OUTPUT]

```python conceptual
def _format_xml(skills: list[SkillEntry], targets: frozenset[str]) -> str:
    return "\n".join([
        "<session_context>",
        f'  <skills count="{len(skills)}">',
        *[f'    <skill name="{s.name}">{s.trigger}</skill>' for s in skills],
        "  </skills>",
        "</session_context>",
    ])
```

## [08]-[SECURITY]

| [INDEX] | [FORBIDDEN]                | [REQUIRED]                               |
| :-----: | :------------------------- | :--------------------------------------- |
|  [01]   | `os.system(f"...{input}")` | `subprocess.run([...], shell=False)`     |
|  [02]   | `eval()` / `exec()`        | `json.load(sys.stdin)`                   |
|  [03]   | `path.startswith(prefix)`  | `Path(p).resolve().is_relative_to(root)` |

## [09]-[TOOLING]

```toml copy-safe
[tool.ty.environment]
python-version = "3.15"

[tool.ty.rules]
all = "error"

[tool.ruff]
target-version = "py315"

[tool.ruff.lint]
select = ["E", "F", "W", "B", "I", "UP", "ANN", "S", "C90"]
```

| [INDEX] | [GATE] | [COMMAND]                             |
| :-----: | :----- | :------------------------------------ |
|  [01]   | Type   | `ty check`                            |
|  [02]   | Lint   | `ruff check --fix . && ruff format .` |
