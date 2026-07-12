# [ADVANCED_TRIGGERS]

## [01]-[TRIGGER_SELECTION]

| [INDEX] | [SCENARIO]                   | [TRIGGER]                           | [SECRETS] | [PATH_FILTER] |
| :-----: | :--------------------------- | :---------------------------------- | :-------: | :-----------: |
|  [01]   | Standard PR validation       | `pull_request`                      |    No     |      Yes      |
|  [02]   | External PR with secrets     | `workflow_run` after `pull_request` |    Yes    |      No       |
|  [03]   | Deploy after CI              | `workflow_run`                      |    Yes    |      No       |
|  [04]   | External webhook/API         | `repository_dispatch`               |    Yes    |      No       |
|  [05]   | ChatOps slash commands       | `issue_comment`                     |    Yes    |      No       |
|  [06]   | Scheduled tasks              | `schedule`                          |    Yes    |      No       |
|  [07]   | Merge queue validation       | `merge_group`                       |    Yes    |      No       |
|  [08]   | Trusted ops on fork PRs      | `pull_request_target`               |    Yes    |      Yes      |
|  [09]   | Manual parameterized trigger | `workflow_dispatch`                 |    Yes    |      No       |

```yaml conceptual
on:
    push:
        paths: ['src/**', '!src/**/*.md', '!**/__tests__/**']
    pull_request:
        paths: ['packages/frontend/**', 'packages/shared/**']
```

## [02]-[WORKFLOW_RUN]

```yaml conceptual
on:
    workflow_run:
        workflows: ['CI Pipeline']
        types: [completed]
        branches: [main]
jobs:
    deploy:
        if: github.event.workflow_run.conclusion == 'success'
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@<SHA> # v6
            - uses: actions/download-artifact@<SHA> # v7
              with: { run-id: '${{ github.event.workflow_run.id }}', github-token: '${{ secrets.GITHUB_TOKEN }}' }
```

[PROPERTIES]: `.name`, `.conclusion`, `.head_sha`, `.head_branch`, `.id`, `.event`

[IMPORTANT] Max 3 levels of chaining. Artifacts accessible via `run-id` from triggering workflow.

## [03]-[REPOSITORY_DISPATCH]

```yaml conceptual
on:
  repository_dispatch:
    types: [deploy-prod, deploy-staging, run-migration]
jobs:
  deploy:
    if: startsWith(github.event.action, 'deploy-')
    runs-on: ubuntu-latest
    environment: ${{ github.event.client_payload.environment || 'staging' }}
    steps:
      - run: printf 'Version: %s\n' "${{ github.event.client_payload.version }}"
```

```bash template
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/OWNER/REPO/dispatches" \
  -d '{"event_type":"deploy-prod","client_payload":{"version":"v1.2.3"}}'
```

[CRITICAL] Only triggers on default branch. Cross-repo dispatch requires App token or PAT.

## [04]-[CHATOPS]

```yaml conceptual
on:
    issue_comment: { types: [created] }
jobs:
    deploy:
        if: |
            github.event.issue.pull_request &&
            startsWith(github.event.comment.body, '/deploy') &&
            contains(fromJSON('["OWNER","MEMBER","COLLABORATOR"]'), github.event.comment.author_association)
        runs-on: ubuntu-latest
        permissions: { pull-requests: write, deployments: write }
        steps:
            - uses: actions/github-script@<SHA> # v8
              with:
                  script: |
                      await github.rest.reactions.createForIssueComment({
                        owner: context.repo.owner, repo: context.repo.repo,
                        comment_id: context.payload.comment.id, content: 'rocket'
                      });
```

[IMPORTANT] Verify `author_association`. Pass comment content through `env:` indirection.

## [05]-[WORKFLOW_DISPATCH]

```yaml conceptual
on:
    workflow_dispatch:
        inputs:
            environment: { description: 'Deployment target', required: true, type: environment }
            log-level: { description: 'Verbosity', type: choice, default: 'info', options: [debug, info, warn, error] }
            dry-run: { description: 'Simulate', type: boolean, default: false }
            version: { description: 'Release version', required: true, type: string }
```

| [INDEX] | [TYPE]        | [UI_RENDERING]       | [NOTES]                     |
| :-----: | :------------ | :------------------- | :-------------------------- |
|  [01]   | `string`      | Free text            | Default if unspecified.     |
|  [02]   | `boolean`     | Checkbox             | `true` / `false`.           |
|  [03]   | `choice`      | Dropdown             | From `options:` list.       |
|  [04]   | `number`      | Numeric input        | Validated as integer/float. |
|  [05]   | `environment` | Environment selector | Respects protection rules.  |

`ref` parameter: API triggers specify branch/tag/SHA via the `ref` field in the request body; UI triggers use the branch picker. Max 25 inputs, 65,535 chars payload.

## [06]-[SCHEDULE]

[IMPORTANT] All `schedule` cron expressions evaluate in UTC only (no timezone override). Convert local times manually. Schedules only run on the default branch.

## [07]-[MERGE_GROUP]

```yaml conceptual
on:
    pull_request:
    merge_group: { types: [checks_requested] }
jobs:
    validate:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@<SHA> # v6
            - run: npm test
```

[CRITICAL] Add `merge_group` alongside `pull_request` when using merge queue — without it, required checks never report.

[CONTEXT_PROPERTIES]: `base_ref`, `base_sha`, `head_ref`, `head_sha`, `head_commit.*`

## [08]-[PULL_REQUEST_TARGET]

[SECURE_BY_DEFAULT]: Workflow source always comes from default branch — no matter which branch the PR targets. `GITHUB_REF` resolves to `refs/heads/main`; `GITHUB_SHA` points to default branch HEAD at run start. Environment protection rules evaluate against the execution ref. This eliminates "pwn request" attacks where malicious PRs modified workflow definitions.

[CRITICAL]:
- [NEVER]: Checkout PR head without environment protection gate (required reviewers).
- [ALWAYS]: Use for labeling, commenting, triage only.

```yaml conceptual
on:
    pull_request_target: { types: [opened, labeled] }
jobs:
    triage:
        runs-on: ubuntu-latest
        permissions: { pull-requests: write }
        steps:
            - uses: actions/github-script@<SHA> # v8
              with:
                  script: |
                      await github.rest.issues.addLabels({
                        ...context.repo, issue_number: context.issue.number, labels: ['needs-review']
                      });
```

## [09]-[DYNAMIC_MATRIX]

```yaml conceptual
jobs:
    setup:
        runs-on: ubuntu-latest
        outputs:
            matrix: ${{ steps.set-matrix.outputs.matrix }}
        steps:
            - id: set-matrix
              run: |
                  echo "matrix=$(jq -c . <<'EOF'
                  {"include":[{"project":"api","node":"20"},{"project":"web","node":"22"}]}
                  EOF
                  )" >> "$GITHUB_OUTPUT"
    build:
        needs: setup
        strategy:
            fail-fast: true
            max-parallel: 4
            matrix: ${{ fromJSON(needs.setup.outputs.matrix) }}
        runs-on: ubuntu-latest
        steps:
            - run: echo "Building ${{ matrix.project }} on Node ${{ matrix.node }}"
```

| [INDEX] | [KEY]               | [DEFAULT]                   | [BEHAVIOR]                                                          |
| :-----: | :------------------ | :-------------------------- | :------------------------------------------------------------------ |
|  [01]   | `fail-fast`         | `true`                      | Cancels all in-progress/queued matrix jobs when any job fails.      |
|  [02]   | `max-parallel`      | Unlimited (runner pool cap) | Limits concurrent matrix jobs. Omit for maximum parallelism.        |
|  [03]   | `continue-on-error` | `false`                     | Per-job override: `true` shields that job's failure from fail-fast. |

[INTERACTION_SEMANTICS]: `continue-on-error: true` on a matrix job masks its failure from `fail-fast` — remaining matrix jobs continue. However, downstream `needs:` jobs see the failed job's result as `success`, which can hide real failures. The matrix policy: `fail-fast: false` (let all matrix jobs run) without `continue-on-error`, then aggregate results in a downstream job via `needs.*.result`.

[IMPORTANT] `uses:` values are static strings — not dynamically generated. Max 256 jobs per matrix.

## [10]-[ORCHESTRATION_PATTERNS]

- [01]-[ENVIRONMENT_PROMOTION]: Chain stages via `needs:`, each carrying independent protection rules — reviewers, wait timers, branch restrictions.
- [02]-[REUSABLE_WORKFLOWS]: Nest at most 2 levels and 50 unique per run; `secrets: inherit` at each level; `job_workflow_ref` earns SLSA L3.
- [03]-[CONCURRENCY_GROUPS]: One running plus one pending per group; `cancel-in-progress: true` for CI, `false` for deploys to avoid state corruption.
