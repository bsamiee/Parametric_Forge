# [CUSTOM_ACTIONS]

## [01]-[ACTION_TYPES]

| [INDEX] | [TYPE]     | [RUNTIME]     | [STARTUP] | [PRE_POST] | [USE_CASE]             |
| :-----: | :--------- | :------------ | :-------- | :--------- | :--------------------- |
|  [01]   | Composite  | Shell/Actions | Fast      | No         | Step orchestration     |
|  [02]   | Docker     | Container     | Slow      | Dockerfile | Isolated environment   |
|  [03]   | JavaScript | `node24`      | Fastest   | Yes        | GitHub API integration |

### [01.1]-[DECISION_TREE]

An affirmative answer selects the type:

| [INDEX] | [QUESTION]                  | [RECOMMENDATION]                              |
| :-----: | :-------------------------- | :-------------------------------------------- |
|  [01]   | Shared steps only?          | Composite action.                             |
|  [02]   | Custom runtime/tools?       | Docker action.                                |
|  [03]   | GitHub API / complex logic? | JavaScript action.                            |
|  [04]   | Full pipeline reuse?        | Reusable workflow (`workflow_call`).          |
|  [05]   | SLSA L3 provenance?         | Reusable workflow (`job_workflow_ref` claim). |

## [02]-[DIRECTORY_STRUCTURE]

[LOCAL_ACTIONS] — monorepo: `.github/actions/<name>/action.yml`

```yaml conceptual
- uses: ./.github/actions/setup-node-cached
```

[STANDALONE_REPOS] — Marketplace: `action.yml` in repo root.

```yaml template
- uses: owner/repo@<SHA> # vN.N.N
```

[IMPORTANT] Monorepo pattern `.github/actions/` keeps actions co-located with consuming workflows. Each action is self-contained with own `action.yml`.

## [03]-[METADATA]

```yaml template
name: 'Action Name'
description: 'Brief description'
author: 'Author'
branding: { icon: 'package', color: 'blue' } # Feather icon set

inputs:
    input-name: { description: 'Description', required: true, default: 'value' }

outputs:
    output-name:
        description: 'Description'
        value: ${{ steps.step-id.outputs.value }} # composite only

runs:
    using: 'composite' # or 'docker' or 'node24'
    steps: [...] # composite
    # image: 'Dockerfile'  # docker
    # main: 'dist/index.js'  # javascript (pre: 'pre.js', post: 'post.js')
```

[OUTPUT_LIMITS]: 1 MiB per job (all outputs combined), 50 MiB per workflow run. Use artifacts for larger data.

[IMPORTANT] Composite inputs are always strings (no `type:` key). JavaScript actions support `pre:` and `post:` lifecycle steps for setup/cleanup.

## [04]-[ERROR_PROPAGATION]

```yaml conceptual
runs:
    using: 'composite'
    steps:
        - id: main
          shell: bash
          continue-on-error: true
          run: [MAIN_CMD]
        - if: always()
          shell: bash
          run: printf '%s\n' "Cleanup" # runs even if main failed
        - if: steps.main.outcome == 'failure'
          shell: bash
          run: exit 1 # propagate failure after cleanup
```

[CRITICAL] Composite actions require `shell:` on every `run:` step. `continue-on-error` behavior with input variables is unpredictable — test thoroughly.

## [05]-[VERSIONING]

```bash conceptual
git tag -a v1.0.0 -m "Release v1.0.0" && git push origin v1.0.0
git tag -fa v1 -m "Update v1 to v1.0.0" && git push origin v1 --force
```

Publish the moving major tag for discoverability; consumers reference `@<SHA> # vN.N.N` only — every tag ref is mutable, and the per-form severity tiers live in `supply_chain.md` [01.1]-[DETECTION_RULES].

## [06]-[RUNTIME]

| [INDEX] | [RUNTIME]   | [STATUS]                                                 |
| :-----: | :---------- | :------------------------------------------------------- |
|  [01]   | `node24`    | Required — use `using: 'node24'` for JavaScript actions. |
|  [02]   | `docker`    | Stable — `using: 'docker'` with `image: 'Dockerfile'`.   |
|  [03]   | `composite` | Stable — `using: 'composite'` with `steps:`.             |

Node runtime status and migration history live in `modern_features.md` [08]-[NODE_RUNTIME].

[TOOLKIT]: `@actions/core@3.x`, `@actions/github@9.x`. Bundle with `@vercel/ncc@0.38.x build index.js --minify`.

## [07]-[JAVASCRIPT_ACTIONS]

[LIFECYCLE]: `pre:` runs before job steps (setup). `main:` runs as the action step. `post:` runs after job completes (cleanup, even on failure).

```yaml conceptual
runs:
    using: 'node24'
    pre: 'dist/pre.js'
    pre-if: runner.os == 'linux' # default: always() — runs pre unconditionally
    main: 'dist/index.js'
    post: 'dist/post.js'
    post-if: always() # default: always() — runs post even on failure
```

`pre-if` / `post-if`: Status check functions evaluate against job status, not action status. `step` context is unavailable in `pre-if` (no steps have run yet). Both default to `always()`.

[IO_PATTERNS]:

```javascript conceptual
const core = require('@actions/core');
core.setOutput('result', JSON.stringify({ status: 'ok', version: '1.0.0' }));
core.setSecret(token); // masks in all subsequent logs
```

## [08]-[DOCKER_ACTIONS]

```dockerfile conceptual
FROM golang:1.23 AS builder
COPY . .
RUN CGO_ENABLED=0 go build -o /action ./...

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /action /action
ENTRYPOINT ["/action"]
```

```yaml conceptual
runs:
    using: 'docker'
    image: 'Dockerfile'
    env:
        INPUT_NAME: ${{ inputs.input-name }} # inputs available as INPUT_* env vars
    args: ['--flag', '${{ inputs.param }}'] # passed to ENTRYPOINT, overrides CMD
    entrypoint: '/custom.sh' # overrides Dockerfile ENTRYPOINT
```

[CONSUMER_OVERRIDE]: `entrypoint:` in action.yml overrides Dockerfile `ENTRYPOINT`. `args:` overrides Dockerfile `CMD`. Consumer workflows cannot override action's entrypoint — it is set by the action author.

[IMPORTANT] Docker actions bind Linux runners. Container startup carries 5-30s of runner- and workload-bound overhead; distroless/scratch bases own image footprint and pull cost.

## [09]-[LOCAL_ACTION_CACHING]

```yaml template
# Composite action — split cache for deterministic control
steps:
    - uses: actions/cache/restore@<SHA> # v5
      id: cache
      with:
          path: ~/.local/share/tool
          key: ${{ runner.os }}-tool-${{ hashFiles('**/lockfile') }}
          restore-keys: ${{ runner.os }}-tool-
    - if: steps.cache.outputs.cache-hit != 'true'
      shell: bash
      run: install-tool.sh
    - uses: actions/cache/save@<SHA> # v5
      if: steps.cache.outputs.cache-hit != 'true'
      with:
          path: ~/.local/share/tool
          key: ${{ steps.cache.outputs.cache-primary-key }}
```

[IMPORTANT] Prefix cache keys with action name to avoid collision across actions: `my-action-${{ runner.os }}-...`. Split pattern prevents save on cache hit (avoids redundant uploads).

## [10]-[TESTING]

| [INDEX] | [STRATEGY]           | [TOOL]                     | [SCOPE]                                    |
| :-----: | :------------------- | :------------------------- | :----------------------------------------- |
|  [01]   | Unit test composites | Workflow with known inputs | Test each step outcome in isolation.       |
|  [02]   | Integration test     | `nektos/act`               | Run full action locally against Docker.    |
|  [03]   | CI validation        | Dedicated test workflow    | `.github/workflows/test-action.yml` on PR. |
|  [04]   | Output validation    | `actions/github-script`    | Assert outputs match expected values.      |

## [11]-[MARKETPLACE]

1. Public repository with `action.yml` in root.
2. Branding metadata (icon + color) — Feather icon set.
3. README.md with usage examples.
4. Semantic version tags (`v1`, `v1.0.0`).
5. Node 24 runtime for JavaScript actions — node20 no longer runs.
