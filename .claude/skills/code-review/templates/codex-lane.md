# [CODEX_LANE]

Fixer-lane dispatch form: one detached codex CLI process per lane, lane law on the developer channel, the task instance on the user prompt. Codex is maximally literal — every word earns its slot, no intensifiers, no persistence blocks, no chain-of-thought scaffolding, and the completion bar is the enumerated deliverables the lane law's output contract carries. Lane law rides named XML spec blocks (`<role>` through `<output_contract>` last) — the battery-measured highest-adherence prompt form on gpt-5.6; markdown bullets lose that adherence property.

## [01]-[LAUNCH]

One `run_in_background` Bash keeper per lane — batched keepers lose per-lane completion notifications:

```bash template
codex exec [-m <model>] [-c 'model_reasoning_effort="<tier>"'] \
  -c developer_instructions="$(cat <round-dir>/lane-law.md)" \
  -o <round-dir>/lane-<letter>-report.json \
  "$(cat <round-dir>/task-<letter>.md)" </dev/null 2><round-dir>/lane-<letter>-stderr.log >/dev/null
```

- `-c developer_instructions=` is the only CLI path to the developer role; `model_instructions_file` REPLACES codex's base instructions and never carries lane law.
- `</dev/null` is mandatory: codex reads piped stdin to EOF even with a prompt argument, and an open silent stdin hangs the lane forever with zero output.
- Purge stale report and stderr files before launch — a leftover report reads as instant completion carrying the prior run's data.
- Effort inherits the config default; state the tier only to deviate. Run under the full user config — miner spawns need the estate's multi-agent depth row.
- Fix waves run the config default unflagged — fable-parity proven over live rounds once the discernment blocks landed; deviate only for purely mechanical slices.

## [02]-[TASK_MESSAGE]

Every task message carries the instance plus the imperative miner-spawn step on the user prompt, because the injected spawn gate hears ONLY that channel: permissive wording ("you may spawn") fails it, and imperative wording naming the exact tools — `collaboration.spawn_agent`, `collaboration.wait_agent` — passes it.

```markdown template
<task>
Disposition every finding in <round-dir>/lane-<letter>.json. Your write territory is exactly these files:
- <sliced-file-1>
- <sliced-file-2>

Before your first edit, spawn exactly two parallel sub-agents with the collaboration.spawn_agent tool, then collect both with collaboration.wait_agent. Each spawn task must be fully self-contained — spawned agents inherit none of your conversation, so state absolute paths and return shapes explicitly:
- miner-A: census <api-catalog-paths> for host members and package capability that the territory files above under-use; return a candidate roster of rows {member, target_page, why}.
- miner-B: sweep the territory files above for composition seams — repeated shapes two pages could share through one owner, under-parameterized owners, flat case families; return candidate rows {page, seam, opportunity}.
Miners never edit files and never propose code to paste; their rosters are data you judge under your capability mandate.
</task>
```

## [03]-[HEALTH_AND_AUDIT]

- Spawn health reads each lane's stderr banner within a minute of launch — `Reading additional input from stdin...` prints pre-EOF even under `</dev/null` and is notice, not a hang; an empty stderr log marks a dead lane, the log tail carries the reason, and a blind relaunch races a live process.
- Liveness is `pgrep -f "lane-<letter>-report"`; an absent report under a live process is normal — never relaunch a live run.
- A spawn audit runs `rg '"name":"spawn_agent"' ~/.codex/sessions/<YYYY>/<MM>/<DD>/rollout-*.jsonl` against the PARENT rollout — the lane's stderr banner `session id: <uuid>` picks the file; children mint their own rollout files, and `collab_tool_call` is a stale marker yielding false negatives.
- A long-quiet live process with near-zero CPU (`ps -p <pid> -o time=`) is wedged: `pkill -f "lane-<letter>-report"`, relaunch once; a second wedge is the failure.
