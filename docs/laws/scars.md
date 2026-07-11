# [SCARS]

Regression-proven laws with no other owner, each row standing law whose trigger names the falsifiable failure mode it forecloses. This estate anchors most paid-for law already: `docs/atlas/scars.md` is the trap ledger for failures anchored to an owning surface, and module-local laws ride the owning file's in-situ comments. A row admits here only when no atlas section, owning module, or constitution row carries it, and a scar whose law gains a real owner — a gate, a law page, an atlas section, a skill — moves there and leaves no copy.

## [01]-[ROWS]

| [INDEX] | [LAW]                                                                   | [TRIGGER]                                                     |
| :-----: | :---------------------------------------------------------------------- | :------------------------------------------------------------ |
|  [01]   | a per-event hook hard-caps spawned bodies and detaches background kicks | flock-serialized kicks accumulate faster than they drain      |
|  [02]   | a wrapper deadlines its WHOLE body, never only its inner scan           | the `loc` here-string self-deadlocks on its own pipe          |
|  [03]   | payload-scale data pipes from `printf` or a file, never `<<<`/here-docs | a >512B here-doc wedges pre-exec under pipe-buffer exhaustion |
|  [04]   | a stdio MCP launcher supervises its server via stdin relay + group reap | fleet servers ignore stdin EOF and outlive their closed pipes |
|  [05]   | a positional field read names every emitted field, or projects via jq   | a truncated read folds trailing fields into its last variable |

## [02]-[DEEP_ROWS]

- [LOC_PIPE_DEADLOCK]: bash 5.3 backs every here-doc and here-string under 64K with an anonymous pipe the redirecting process holds BOTH ends of, writing the document before `exec`; when xnu cannot grant the assumed buffer — leaked pipes exhaust pipe KVA and fresh pipes fall back to 512 bytes — that pre-exec write blocks forever with no other holder to deliver EOF (`sample` parks the child in `do_redirection_internal` inside `write`). The wedge is self-amplifying, each wedged body deepening the exhaustion that wedges the next; `loc` accumulated hundreds of callers through `jq ... <<<"$json"` AFTER its deadlined `scc` scan had succeeded. The cure is two-sided — payload-scale data pipes from `printf` to a live reader or lands in a file, and the wrapper's WHOLE body re-execs under `timeout` — landed at the owning master with a re-run of its `--self-test`.
- [MCP_RESIDUE_RELAY]: stdio MCP servers across the fleet ignore stdin EOF, so a killed or reconnecting client strands whole launch chains for hours — one live session held three abandoned generations of the same servers as its own children. `exec` chains cannot fix this (the signal path dies with the client) and a ppid watchdog misses a live client that merely reconnected. The shared supervise lane (`modules/home/programs/shell-tools/supervise-stdio.nix`) is the structural owner: stdin reaches the server through a relay `cat`, ANY client departure ends the relay, and the wrapper reaps the server's process group after an EOF grace.
