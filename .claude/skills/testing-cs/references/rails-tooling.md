# [H1][RAILS_TOOLING]
>**Dictum:** *Each rail has one command path and one owner.*

<br>

## [01]-[MANAGED]

| [INDEX] | [COMMAND]                                   | [USE]                                                                               |
| :-----: | ------------------------------------------- | ----------------------------------------------------------------------------------- |
|  [01]   | `<quality-router> static plan <paths...>`   | Route preview for uncertain graph/tooling changes.                                  |
|  [02]   | `<quality-router> static fix <paths...>`    | Scoped whitespace/style/analyzer cleanup; mutates files.                            |
|  [03]   | `<quality-router> static report <paths...>` | Scoped whitespace/style/analyzer diagnostics; does not intentionally mutate source. |
|  [04]   | `<quality-router> static build <paths...>`  | Routed build/analyzer/source-generation proof.                                      |
|  [05]   | `<quality-router> static full`              | Full-solution build/analyzer proof for trigger files.                               |
|  [06]   | `<test-runner>`                             | Default managed target: MTP unit tests only.                                        |
|  [07]   | `<test-runner> --all`                       | All runnable MTP test projects.                                                     |
|  [08]   | `<test-runner> coverage`                    | Managed coverlet.MTP map.                                                           |
|  [09]   | `<test-runner> --mutation changed`          | Changed-file Stryker MTP mutation.                                                  |
|  [10]   | `<test-runner> --mutation full`             | Full managed Stryker MTP mutation.                                                  |
|  [11]   | `<test-runner> --target <project>`          | Focused MTP project run.                                                            |

Managed gates isolate build output under the repo-owned artifact root. Mutation is explicit and fail-fast on the repo-owned mutation lock.

---
## [02]-[MUTATION]

Stryker is owned by the configured pure-managed project/test pair. Thresholds and reporters come from the repo mutation owner. Zero discovery fails the rail.

```bash
<quality-router> self-test
<test-runner> --mutation changed
```

---
## [03]-[RUNTIME]

| [INDEX] | [COMMAND]                                    | [USE]                                       |
| :-----: | -------------------------------------------- | ------------------------------------------- |
|  [01]   | `<runtime-runner> doctor`                    | Runtime health and endpoint proof.          |
|  [02]   | `<runtime-runner> verify <scenario-or-glob>` | Runtime verification against the live host. |
|  [03]   | `<api-router> doctor`                        | Host assembly and reference map.            |

Live host routes may be single-flight when the repo runtime owner declares one endpoint.
