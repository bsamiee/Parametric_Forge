# [H1][COMMON-ERRORS]

## [01]-[SYNTAX_ERRORS]

| [INDEX] | [ERROR]                                     | [ACTIONLINT_RULE] | [FIX]                           |
| :-----: | ------------------------------------------- | ----------------- | ------------------------------- |
|  [01]   | `Unable to process file command 'workflow'` | `syntax-check`    | Fix indentation/missing colons  |
|  [02]   | `Required property is missing: name`        | `syntax-check`    | Add required top-level keys     |
|  [03]   | `Unexpected value 'on'`                     | `events`          | Underscore not hyphen in events |
|  [04]   | `Unexpected key`                            | `syntax-check`    | Remove unknown keys             |
|  [05]   | `Duplicate key`                             | `syntax-check`    | Remove duplicate keys           |

## [02]-[EXPRESSION_ERRORS]

| [INDEX] | [ERROR]                              | [ACTIONLINT_RULE] | [FIX]                             |
| :-----: | ------------------------------------ | ----------------- | --------------------------------- |
|  [01]   | `Unrecognized named-value`           | `expression`      | Wrap in `${{ }}` or bare in `if:` |
|  [02]   | `Expected boolean value, got string` | `expression`      | Use boolean literals not strings  |
|  [03]   | `Potential script injection`         | `expression`      | Use `env:` indirection            |
|  [04]   | `Constant condition at "if:"`        | `if-cond`         | Remove constant conditions        |
|  [05]   | `Context access unavailable`         | `expression`      | Check context scope availability  |

### [2.1]-[EXPRESSION_INJECTION_DETECTION]

[CRITICAL] Direct interpolation of `${{ github.event.* }}` in `run:` blocks enables shell command injection from attacker-controlled PR titles, branch names, and commit messages.

**Untrusted fields** (attacker-controlled in fork PRs):

| [INDEX] | [FIELD]                                 | [ATTACK_VECTOR]                        |
| :-----: | --------------------------------------- | -------------------------------------- |
|  [01]   | `github.event.pull_request.title`       | PR title with shell metacharacters.    |
|  [02]   | `github.event.pull_request.body`        | PR body with injected commands.        |
|  [03]   | `github.event.pull_request.head.ref`    | Branch name with shell injection.      |
|  [04]   | `github.event.comment.body`             | Issue/PR comment body.                 |
|  [05]   | `github.event.head_commit.message`      | Commit message with injected commands. |
|  [06]   | `github.event.head_commit.author.name`  | Git author name (user-controlled).     |
|  [07]   | `github.event.head_commit.author.email` | Git author email (user-controlled).    |
|  [08]   | `github.event.discussion.title`         | Discussion title.                      |
|  [09]   | `github.event.discussion.body`          | Discussion body.                       |

```yaml
# UNSAFE: direct interpolation in run: block
- run: printf '%s\n' "${{ github.event.pull_request.title }}"

# SAFE: env var indirection
- env:
    PR_TITLE: ${{ github.event.pull_request.title }}
  run: printf '%s\n' "$PR_TITLE"
```

[REFERENCE] Injection prevention: [expressions-and-contexts.md](./expressions-and-contexts.md).

## [03]-[DEPRECATED_COMMANDS]

| [INDEX] | [COMMAND]                          | [STATUS]            | [REPLACEMENT]                          |
| :-----: | ---------------------------------- | ------------------- | -------------------------------------- |
|  [01]   | **`::set-output name=KEY::VALUE`** | Removed (Jun 2023). | `echo "KEY=VALUE" >> "$GITHUB_OUTPUT"` |
|  [02]   | **`::save-state name=KEY::VALUE`** | Removed (Jun 2023). | `echo "KEY=VALUE" >> "$GITHUB_STATE"`  |
|  [03]   | **`::set-env name=KEY::VALUE`**    | Removed.            | `echo "KEY=VALUE" >> "$GITHUB_ENV"`    |
|  [04]   | **`::add-path::VALUE`**            | Removed.            | `echo "VALUE" >> "$GITHUB_PATH"`       |

**Still valid workflow commands:**
- `::add-mask::VALUE` — dynamically mask a value in subsequent logs.
- `::debug::MESSAGE` — debug-level log output.
- `::notice file=F,line=L::MESSAGE` — annotation on workflow run page.
- `::warning file=F,line=L::MESSAGE` — warning annotation.
- `::error file=F,line=L::MESSAGE` — error annotation.
- `::group::TITLE` / `::endgroup::` — collapsible log groups.

## [04]-[ACTION_ERRORS]

| [INDEX] | [ERROR]                                    | [ACTIONLINT_RULE] | [FIX]                                                              |
| :-----: | ------------------------------------------ | ----------------- | ------------------------------------------------------------------ |
|  [01]   | **`Can't find 'action.yml'`**              | `action`          | Verify spelling: `actions/checkout` not `actions/chekout`.         |
|  [02]   | **`Input required and not supplied`**      | `action`          | Add required inputs per action docs.                               |
|  [03]   | **`Unexpected input`**                     | `action`          | Remove undocumented inputs, check action metadata.                 |
|  [04]   | **Deprecated input**                       | `action`          | Input has `deprecationMessage` — use replacement from action docs. |
|  [05]   | **`Node.js 12/16 actions are deprecated`** | `action`          | Update to current major — node12/16 removed from runners.          |
|  [06]   | **`Node.js 20 actions are deprecated`**    | `action`          | Update to latest major (node24 required March 4, 2026).            |
|  [07]   | **Supply chain compromise**                | —                 | Pin to SHA, verify via `git ls-remote`, enable Dependabot.         |

### [4.1]-[OUTDATED_ACTION_VERSIONS]

| [INDEX] | [ACTION]                  | [OUTDATED] | [CURRENT] | [SHA]                                      |
| :-----: | ------------------------- | :--------: | :-------: | ------------------------------------------ |
|  [01]   | actions/checkout          |   v3, v4   |  v6.0.2   | `de0fac2e4500dabe0009e67214ff5f5447ce83dd` |
|  [02]   | actions/setup-node        |   v3, v4   |  v6.2.0   | `6044e13b5dc448c55e2357c09f80417699197238` |
|  [03]   | actions/cache             |   v3, v4   |  v5.0.3   | `cdf6c1fa76f9f475f3d7449005a359c84ca0f306` |
|  [04]   | actions/upload-artifact   |   v3, v4   |  v6.0.0   | `b7c566a772e6b6bfb58ed0dc250532a479d7789f` |
|  [05]   | actions/download-artifact |   v3, v4   |  v7.0.0   | `37930b1c2abaa49bbe596cd826c3c89aef350131` |
|  [06]   | github/codeql-action      |   v2, v3   |  v4.32.2  | `45cbd0c69e560cd9e7cd7f8c32362050c9b7ded2` |

[REFERENCE] Full SHA map: SHA resolution: use `git ls-remote` discovery protocol at generation time.

## [05]-[JOB_CONFIGURATION]

| [INDEX] | [ERROR]                                               | [ACTIONLINT_RULE] | [FIX]                                                       |
| :-----: | ----------------------------------------------------- | ----------------- | ----------------------------------------------------------- |
|  [01]   | **`label "ubuntu-lastest" is unknown`**               | `runner-label`    | Use valid labels. [REFERENCE] [->runners.md](./runners.md). |
|  [02]   | **`Job 'X' depends on job 'Y' which does not exist`** | `job-needs`       | Match exact job ID in `needs:`.                             |
|  [03]   | **`Circular dependency detected`**                    | `job-needs`       | Break circular `needs:` chain.                              |
|  [04]   | **Missing `timeout-minutes:`**                        | —                 | Default is 6 hours — add explicit timeout to every job.     |
|  [05]   | **`-arm64` suffix on runner label**                   | `runner-label`    | Use `-arm` suffix: `ubuntu-24.04-arm` not `-arm64`.         |

## [06]-[REUSABLE_WORKFLOW_ERRORS]

| [INDEX] | [ERROR]                                      | [ACTIONLINT_RULE] | [FIX]                                                             |
| :-----: | -------------------------------------------- | ----------------- | ----------------------------------------------------------------- |
|  [01]   | **Invalid `type:` in `workflow_call` input** | `workflow-call`   | Use `string`, `number`, or `boolean` only.                        |
|  [02]   | **Missing required input**                   | `workflow-call`   | Caller must supply all `required: true` inputs.                   |
|  [03]   | **Output reference mismatch**                | `workflow-call`   | Caller output path must match `jobs.<id>.outputs.<name>`.         |
|  [04]   | **`secrets: inherit` with explicit secrets** | `workflow-call`   | Cannot combine `secrets: inherit` with named secret declarations. |
|  [05]   | **Nesting exceeds 10 levels**                | —                 | Maximum 10 levels of workflow nesting (caller + 9 deep).          |

## [07]-[SCHEDULE_ERRORS]

| [INDEX] | [ERROR]                       | [ACTIONLINT_RULE] | [FIX]                                                                            |
| :-----: | ----------------------------- | ----------------- | -------------------------------------------------------------------------------- |
|  [01]   | **`Invalid CRON expression`** | `events`          | Format: `minute(0-59) hour(0-23) day(1-31) month(1-12) weekday(0-6, 0=Sunday)`.  |
|  [02]   | **Too-frequent schedule**     | —                 | Minimum interval is every 5 minutes for public repos (rate limited by GitHub).   |
|  [03]   | **Timezone expectation**      | —                 | All `schedule` cron expressions evaluate in **UTC only** — no timezone override. |

```yaml
# Bad:  cron: '0 0 * * 8'    # Weekday 8 does not exist
# Bad:  cron: '* * * * *'    # Every minute — will be rate-limited
# Good: cron: '0 0 * * 0'    # Sunday at midnight UTC
# Good: cron: '30 6 * * 1-5' # Weekdays at 06:30 UTC
```

## [08]-[PATH_FILTER_ERRORS]

| [INDEX] | [ERROR]                             | [ACTIONLINT_RULE] | [FIX]                             |
| :-----: | ----------------------------------- | ----------------- | --------------------------------- |
|  [01]   | **`Invalid glob pattern: '**.js'`** | `glob`            | Use `**/*.js` not `**.js`.        |
|  [02]   | **No `?` wildcard support**         | —                 | `hashFiles` does not support `?`. |

## [09]-[ENVIRONMENT_AND_SECRETS]

| [INDEX] | [ERROR]                          | [ACTIONLINT_RULE] | [FIX]                                                                         |
| :-----: | -------------------------------- | ----------------- | ----------------------------------------------------------------------------- |
|  [01]   | **`Secret MY_SECRET not found`** | —                 | Verify name in repository settings (case-sensitive).                          |
|  [02]   | **Env var not accessible**       | —                 | Unix: `echo "$MY_VAR"`, Windows: `echo $env:MY_VAR`.                          |
|  [03]   | **Short secret not masked**      | —                 | Secrets shorter than 4 characters are NOT masked in logs.                     |
|  [04]   | **Secret in `run:` block**       | `expression`      | Pass via `env:` indirection — never interpolate `${{ secrets.* }}` in `run:`. |

## [10]-[PERMISSIONS_ERRORS]

| [INDEX] | [ERROR]                             | [ACTIONLINT_RULE] | [FIX]                                                                                                                                                                                                                          |
| :-----: | ----------------------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|  [01]   | **Invalid permission scope**        | `permissions`     | Valid scopes: `actions`, `attestations`, `checks`, `contents`, `deployments`, `id-token`, `issues`, `models`, `packages`, `pages`, `pull-requests`, `repository-projects`, `security-events`, `statuses`, `artifact-metadata`. |
|  [02]   | **`write-all` / no `permissions:`** | —                 | Add top-level `permissions: {}` for least privilege default.                                                                                                                                                                   |
|  [03]   | **Missing `id-token: write`**       | —                 | Required for OIDC federation (AWS/GCP/Azure auth actions).                                                                                                                                                                     |
|  [04]   | **Missing `attestations: write`**   | —                 | Required for `actions/attest-build-provenance` / `attest-sbom`.                                                                                                                                                                |

## [11]-[DEBUGGING]

| [INDEX] | [METHOD]              | [HOW]                                                                |
| :-----: | --------------------- | -------------------------------------------------------------------- |
|  [01]   | **Debug logging**     | Set secrets: `ACTIONS_STEP_DEBUG=true`, `ACTIONS_RUNNER_DEBUG=true`. |
|  [02]   | **Interactive debug** | `uses: mxschmitt/action-tmate@v3` with `if: failure()`.              |
|  [03]   | **Dump context**      | `run: printf '%s\n' '${{ toJSON(github) }}'`.                        |
|  [04]   | **Re-run with debug** | GitHub UI "Re-run all jobs" > "Enable debug logging" checkbox.       |
