# [ACT_USAGE]

## [01]-[GATE]

`gha` fronts the local chain: `gha check [PATH...]` runs actionlint, zizmor, and ratchet over discovered workflow files as one envelope (`--json` for machine rows; exit 1 on findings, 2 on usage), `gha pin` rewrites mutable `uses:` refs to SHAs, `gha run [-j JOB] [-e EVENT.json] [ARGS...]` rides act on the deployed runner images, and `gha events` lists simulatable events. The sections below carry per-tool depth.

## [02]-[ACTIONLINT]

```bash copy-safe
actionlint .github/workflows/ci.yml          # Single file
actionlint .github/workflows/*.yml           # All workflows
actionlint                                   # Default location (.github/workflows/)
actionlint -format '{{json .}}'              # JSON output
actionlint -format sarif                     # SARIF (code scanning integration)
```

[VALIDATES]: YAML syntax, schema, expressions, runner labels, action inputs/outputs, job dependencies, CRON syntax, glob patterns, shell scripts (shellcheck integration), security vulnerabilities, YAML anchors/aliases, deprecated inputs, constant conditions.

[EXIT_CODES]: `0` = success, `1` = errors found, `2` = fatal error.

### [02.1]-[CONFIGURATION]

```yaml copy-safe
# .github/actionlint.yaml
shellcheck:
    enable: true
    shell: bash
pyflakes:
    enable: true
ignore:
    - 'SC2086' # Ignore specific shellcheck rule
self-hosted-runner:
    labels: [my-custom-runner, gpu-runner] # Declare custom labels
```

### [02.2]-[CI_INTEGRATION]

```yaml conceptual
name: Lint Workflows
on:
    pull_request:
        paths: ['.github/workflows/**']
jobs:
    actionlint:
        runs-on: ubuntu-latest
        permissions: {}
        steps:
            - uses: actions/checkout@<SHA> # v6.0.2
            - run: bash <(curl https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash)
            - run: ./actionlint -format sarif > actionlint.sarif
            - uses: github/codeql-action/upload-sarif@<SHA> # v4.32.2
              if: always()
              with:
                  sarif_file: actionlint.sarif
```

### [02.3]-[KEY_CHECKS]

| [INDEX] | [CHECK_CATEGORY]    | [WHAT_IT_VALIDATES]                                           |
| :-----: | :------------------ | :------------------------------------------------------------ |
|  [01]   | Syntax              | YAML structure, required fields, duplicate keys.              |
|  [02]   | Expressions         | Type correctness, context availability, injection detection.  |
|  [03]   | Actions             | Input/output validation, deprecated inputs, runtime version.  |
|  [04]   | Runner labels       | Known labels, deprecated labels, `-arm` vs `-arm64` suffix.   |
|  [05]   | CRON                | Field ranges, syntax validity.                                |
|  [06]   | Glob patterns       | Directory separator requirement, valid pattern syntax.        |
|  [07]   | Shell scripts       | ShellCheck integration for `run:` blocks (bash/sh).           |
|  [08]   | YAML anchors        | Undefined aliases, unused anchors, merge key `<<:` rejection. |
|  [09]   | Permissions         | Valid scope names (`models`, `artifact-metadata`).            |
|  [10]   | Constant conditions | `if: true`, `if: false`, and complex constant expressions.    |

## [03]-[ACT]

```bash template
act -l                                         # List all workflows and jobs
act -l push                                    # List workflows for push event
act -n                                         # Dry-run (validate without executing)
act push                                       # Run push event workflows
act -j <job-id>                                # Run specific job
act -W .github/workflows/ci.yml                # Run specific workflow
act -v                                         # Verbose output
act workflow_dispatch --input version=1.2.3    # Trigger with inputs
```

[EXIT_CODES]: `0` = success, `1` = job failed, `2` = parse/execution error.

### [03.1]-[OPTIONS]

| [INDEX] | [FLAG]                                 | [PURPOSE]                                    |
| :-----: | :------------------------------------- | :------------------------------------------- |
|  [01]   | `--container-architecture linux/amd64` | Consistent platform (important on ARM Macs). |
|  [02]   | `-P ubuntu-latest=node:24-bookworm`    | Custom Docker image for runner.              |
|  [03]   | `-s GITHUB_TOKEN=ghp_xxx`              | Pass secret.                                 |
|  [04]   | `--secret-file .secrets`               | Secrets from file (`.secrets` format).       |
|  [05]   | `--env MY_VAR=value`                   | Environment variable.                        |
|  [06]   | `--input myInput=value`                | `workflow_dispatch` input.                   |
|  [07]   | `--action-offline-mode`                | Skip downloading actions (use cached).       |
|  [08]   | `--matrix os:ubuntu-latest`            | Filter matrix to specific combination.       |

### [03.2]-[CONFIGURATION_FILE]

```bash copy-safe
# .actrc (project root or $HOME)
--container-architecture=linux/amd64
--action-offline-mode
-P ubuntu-latest=catthehacker/ubuntu:act-latest
```

## [04]-[LIMITATIONS]

| [INDEX] | [TOOL]     | [LIMITATION]                 | [IMPACT]                                                   |
| :-----: | :--------- | :--------------------------- | :--------------------------------------------------------- |
|  [01]   | actionlint | No cross-file analysis       | Cannot validate reusable workflow caller/callee contracts. |
|  [02]   | actionlint | Popular actions data may lag | New action versions may not be in bundled metadata.        |
|  [03]   | act        | Not 100% GitHub-compatible   | Some features behave differently than real runners.        |
|  [04]   | act        | Docker required              | Must be installed and running for local execution.         |
|  [05]   | act        | GitHub API actions may fail  | No real `GITHUB_TOKEN` context without manual secrets.     |
|  [06]   | act        | Default images differ        | Use `-P` to match GitHub-hosted runner images.             |
|  [07]   | act        | `.github/workflows/` only    | Cannot validate workflows in other directories.            |

## [05]-[TROUBLESHOOTING]

| [INDEX] | [ISSUE]                         | [SOLUTION]                                                    |
| :-----: | :------------------------------ | :------------------------------------------------------------ |
|  [01]   | Cannot connect to Docker daemon | Start Docker Desktop or daemon.                               |
|  [02]   | Workflow file not found         | Run from repo root or use `-W` flag.                          |
|  [03]   | Action not found locally        | Use `-P` for alternative images or `--action-offline-mode`.   |
|  [04]   | Out of disk space               | `docker system prune -a`.                                     |
|  [05]   | ARM Mac architecture mismatch   | Add `--container-architecture linux/amd64` to `.actrc`.       |
|  [06]   | shellcheck not found            | Install shellcheck for `run:` block validation in actionlint. |
