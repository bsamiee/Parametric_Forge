# [TOPOLOGY]

The coupling map: editing a `[SURFACE]` obligates its `[OBLIGATED_COUNTERPARTS]` in the same change. Heavy workflow runs re-prove rows against the live tree — a row whose coupling no longer exists is culled in the same pass, and a coupling discovered mid-run lands as a new row. Rows list only hand-edited counterparts: surfaces the switch projects from their rows — `forge-mcp reconcile`/`drift`, the launchd tunnel supervisors, the `forge-accept` lanes — never appear here.

## [01]-[ROWS]

| [INDEX] | [SURFACE]                             | [OBLIGATED_COUNTERPARTS]                            | [WHY]                                      |
| :-----: | :------------------------------------ | :-------------------------------------------------- | :----------------------------------------- |
|  [01]   | `mcp-fleet.nix` row `envKeys` name    | `setup-env.sh` `_ENV_KEYS` + the Doppler config key | the hook resolves the values rows name     |
|  [02]   | `services/topology.ts` Doppler row    | `setup-env.sh` `DOPPLER_SOURCES`/`SNAPSHOT_KEEP`    | the hook replays the declared coordinates  |
|  [03]   | new loopback service on a server host | its `ssh.nix` `vpsTunnels` forward row              | the tunnel registry is the only reach path |
|  [04]   | harness master tree file              | sibling-repo byte copies                            | propagation is byte-identical copy         |
|  [05]   | law or standards ruling               | `.greptile/rules.md` + `.coderabbit.yaml` twin      | reviewer prose derives from doctrine       |
|  [06]   | `CLAUDE.md` fact                      | `AGENTS.md` cross-reference                         | one fact lands at its acting reader        |
|  [07]   | any `modules/` or `overlays/` file    | `forge-redeploy --switch` + `forge-accept`          | an unswitched edit is invisible            |
|  [08]   | `forge-provision` envelope or verb    | its README contract row + `data/` catalog row       | the envelope is a cross-repo contract      |
|  [09]   | `overlays/manifest.nix` admission row | its consuming roster surface                        | admission requires a real consumer now     |
|  [10]   | `agent-attention.sh` event roster     | the collector fold in `mcp-launchers.nix`           | the hook admits only consumed events       |

The harness master tree is `.claude/{skills,hooks,scripts,agents}`, `commands/docs.md`, `docs/stacks/{python,typescript}/`, and the three prose standards. A shared-home module edit additionally proves the eval pair — the darwin system build plus `nix eval '.#nixosConfigurations.maghz.config.system.build.toplevel.drvPath'` — because `nix flake check` proves neither toplevel. The manifest admission's consuming roster is an HM `rosterRows` row or a flake projection row.
