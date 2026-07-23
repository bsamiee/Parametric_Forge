# External Lanes

Codex legs run through the codex skill's supervised CLI lane. A native wrapper owns file custody, launches the CLI process in one backgrounded Bash call, reads the receipt after the harness re-invokes it, and exposes the worker through a `codex:<label>` workflow label.

## [01]-[WRAPPER]

Wrapper sequence:

1. Write lane law to `<lane-dir>/law.md` and task content to `<lane-dir>/task.md` verbatim.
2. Run `<repo>/.claude/skills/codex/scripts/codex-lane.sh` once with `run_in_background: true`, passing the lane files, directory, repository root, and sandbox.
3. Read `<lane-dir>/receipt.json` when the harness resumes the wrapper.
4. Verify the product at its declared path and return the typed receipt.

Read lanes materialize the final message through `--out <report>`. Write lanes land their declared product directly and use `jq -e` over the required keys as the acceptance boundary. Wrapper custody stays mechanical: law, task, process, receipt, and product verification.

A `reason: "crash"` receipt resumes the persisted thread with a continuation task. Another failed receipt starts one fresh lane with the original files. A second failure returns the receipt's `reason` and `failure` unchanged.

```js conceptual
const receipt = await agent(codexLane('audit-auth', task), {
    model: 'sonnet',
    effort: 'low',
    label: 'codex:audit-auth',
    schema: RECEIPT,
});
```

Lane law enters `developer_instructions`; task content stays task-only. Deviated reasoning travels through a helper option named `codexEffort`, which the helper maps to the lane script's `--effort` flag.

## [02]-[PRODUCTS]

Heavy products land on disk and receipts cross the workflow boundary. Product contracts name required keys; wrapper validation checks those keys before returning success. Failure belongs to the receipt envelope.

Iterative work continues through `--resume <thread-id>`. Concurrent lanes own distinct lane directories and disjoint write territories. Overlapping writes route through one native writer.

## [03]-[WRITER_REVIEW]

A writing review lane owns one unit's pages and writes its fixlog to the declared report path. Its consuming stage reads that path from disk, verifies every carried claim, and folds forward unresolved rows. Terminal reconciliation drains any fixlog whose consuming stage did not land.

## [04]-[GEMINI_REVIEW]

An agy review leg uses a `gemini:<label>` wrapper and one backgrounded CLI call. Typed findings cross the wire, and the consuming native stage adjudicates them against disk.
