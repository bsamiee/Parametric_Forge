---
name: github-actions
description: >-
    Generates and validates GitHub Actions workflows and custom actions (composite/Docker/JavaScript)
    with SHA-pinned supply chain security, SLSA attestation, OIDC federation, and
    harden-runner enforcement. Use when creating, editing, reviewing, or validating
    CI/CD pipelines, reusable workflows, monorepo CI patterns, container build/deploy
    orchestration, or advanced triggers (workflow_run, dispatch, ChatOps).
---

# [GITHUB_ACTIONS]

Generate and validate production-ready GitHub Actions workflows and custom actions.

[TASKS]:

1. Gather requirements — triggers, runners, dependencies, environments, security posture.
2. Read [best-practices.md](./references/best-practices.md) — security hardening, supply chain, performance, anti-patterns.
3. Read [version-discovery.md](./references/version-discovery.md) — SHA resolution protocol, action index, permissions.
4. Read [expressions-and-contexts.md](./references/expressions-and-contexts.md) — contexts, functions, injection prevention.
5. (advanced triggers) Read [advanced-triggers.md](./references/advanced-triggers.md) — workflow_run, dispatch, ChatOps, merge queue.
6. (custom actions) Read [custom-actions.md](./references/custom-actions.md) — composite, Docker, JavaScript action authoring.
7. Resolve action versions — `git ls-remote`, Context7 MCP, or WebSearch for latest SHA.
8. Generate — SHA-pinned actions, minimal permissions, concurrency, caching, timeouts, harden-runner.
9. Validate — Read validation references, run actionlint, apply 11 best practice checks.
10. Fix and re-validate until passing (max 3 iterations).

[SCOPE]:

- Workflow files (`.github/workflows/*.yml`).
- Custom actions — composite, Docker, JavaScript (`.github/actions/*/action.yml`).
- Reusable workflows (`workflow_call`).
- Supply chain — SLSA attestation, SBOM, Cosign signing.
- Monorepo CI — Nx affected detection, sparse checkout, pnpm workspace caching.

## [01]-[ROUTING]

[REFERENCES]:

- [01]-[BEST_PRACTICES](references/best-practices.md): security hardening, supply chain, performance, anti-patterns
- [02]-[VERSION_DISCOVERY](references/version-discovery.md): SHA resolution protocol, common actions index, permissions
- [03]-[EXPRESSIONS](references/expressions-and-contexts.md): contexts, functions, injection prevention
- [04]-[ADVANCED_TRIGGERS](references/advanced-triggers.md): workflow_run, dispatch, ChatOps, merge queue
- [05]-[CUSTOM_ACTIONS](references/custom-actions.md): composite, Docker, JavaScript action authoring
- [06]-[COMMON_ERRORS](references/common_errors.md): syntax, expressions, deprecated commands
- [07]-[SUPPLY_CHAIN](references/supply_chain.md): SHA pinning, OIDC, SBOM, harden-runner
- [08]-[MODERN_FEATURES](references/modern_features.md): reusable workflows, concurrency, matrix, node runtime
- [09]-[RUNNERS](references/runners.md): runner labels, deprecations
- [10]-[ACT_USAGE](references/act_usage.md): actionlint rules, act limitations

[TEMPLATES]:

- [01]-[BASIC_WORKFLOW](templates/basic-workflow.template.yml): lint, test, build, deploy CI pipeline with parameterized runtime
- [02]-[REUSABLE_WORKFLOW](templates/reusable-workflow.template.yml): workflow_call with typed inputs, secrets, version extraction
- [03]-[COMPOSITE_ACTION](templates/composite-action.template.yml): multi-step action with parameterized runtime and error handling
- [04]-[DOCKER_ACTION](templates/docker-action.template.yml): container action with distroless multi-stage Dockerfile pattern
- [05]-[JAVASCRIPT_ACTION](templates/javascript-action.template.yml): Node 24 action with pre/post lifecycle, typed error handling

[EXAMPLES]:

- [01]-[NODEJS_CI](examples/nodejs-ci.yml): matrix testing, caching, artifact upload, coverage, summaries
- [02]-[DOCKER_BUILD_PUSH](examples/docker-build-push.yml): multi-platform builds, GHCR, BuildKit caching, SLSA provenance
- [03]-[MONOREPO_CI](examples/monorepo-ci.yml): Nx affected detection, pnpm workspace, sparse checkout
- [04]-[DEPENDENCY_REVIEW](examples/dependency-review.yml): multi-job security with dep review, CodeQL, Gitleaks, triage
- [05]-[SBOM_ATTESTATION](examples/sbom-attestation.yml): SBOM, Trivy severity gating, Cosign, gh attestation verify
- [06]-[SETUP_NODE_CACHED](examples/setup-node-cached-action.yml): smart caching, corepack detection, cache-dir resolution
- [07]-[CHATOPS_DISPATCH](examples/chatops-dispatch.yml): slash commands, injection guard, App token, env indirection
- [08]-[OIDC_CLOUD_AUTH](examples/oidc-cloud-auth-action.yml): AWS/GCP/Azure OIDC, output normalization
- [09]-[RELEASE_DEPLOY](examples/release-deploy.yml): environment promotion, reusable workflow, concurrency groups
- [10]-[DOCKER_LINT_SCAN](examples/docker-lint-scan-action.yml): Trivy scan, hadolint, SARIF output
- [11]-[PR_CHANGE_ROUTER](examples/pr-change-router-action.yml): paths-filter, dynamic matrix, label sync

## [02]-[STANDARDS]

Every generated workflow enforces defense-in-depth: supply chain integrity prevents compromised actions from executing, minimal permissions limit blast radius if a job is compromised, and harden-runner detects anomalous behavior at runtime. These layers are independent — failure of one leaves others intact.

[CRITICAL]:

- [ALWAYS]: SHA-pin every `uses:` reference — mutable tags (`@v1`, `@main`) enable supply chain attacks. The tj-actions incident (CVE-2025-30066) compromised 23,000+ repos via tag retargeting.
- [ALWAYS]: `step-security/harden-runner` as first step in every job — detected the tj-actions breach before any other tool.
- [ALWAYS]: Top-level `permissions: {}` (deny-all default); grant minimal per-job permissions.
- [ALWAYS]: `timeout-minutes:` on every job — prevents runaway billing on stuck workflows.

[IMPORTANT]:

- [ALWAYS]: OIDC federation (`id-token: write`) for cloud auth — eliminates static credentials entirely.
- [ALWAYS]: `actions/create-github-app-token` for cross-repo ops — scoped, 1-hour expiry, survives offboarding.
- [ALWAYS]: `>> $GITHUB_OUTPUT` for step outputs; `>> $GITHUB_STEP_SUMMARY` for job summaries.
- [NEVER]: Direct `${{ }}` interpolation of untrusted input in `run:` blocks — route through `env:` indirection.

[REFERENCE] [best-practices.md](./references/best-practices.md) — Security checklist, supply chain controls, anti-patterns.

## [03]-[TEMPLATES]

Templates use `[PLACEHOLDER]` syntax for generation-time substitution. SHA resolution happens at generation time via the discovery protocol — templates contain placeholder SHAs, not static pins.

### [03.1]-[PLACEHOLDER_CONVENTION]

All templates use a unified `[UPPER_SNAKE_CASE]` placeholder convention:

| [INDEX] | [CATEGORY]      | [PLACEHOLDERS]                                                              |
| :-----: | :-------------- | :-------------------------------------------------------------------------- |
|  [01]   | **Identity**    | `[ACTION_NAME]`, `[WORKFLOW_NAME]`, `[DESCRIPTION]`, `[AUTHOR_NAME]`        |
|  [02]   | **Runtime**     | `[RUNTIME_VERSION]`, `[RUNTIME_ENV_KEY]`, `[ENABLE_CMD]`                    |
|  [03]   | **Package Mgr** | `[PACKAGE_MANAGER]`, `[INSTALL_CMD]`                                        |
|  [04]   | **Build/Test**  | `[BUILD_CMD]`, `[LINT_CMD]`, `[TEST_CMD]`, `[BUILD_PATH]`, `[RESULTS_PATH]` |
|  [05]   | **Deploy**      | `[ENV_NAME]`, `[ENV_URL]`, `[DEPLOY_CMD]`, `[VERIFY_CMD]`                   |
|  [06]   | **Secrets**     | `[SECRET_KEY]`, `[SECRET_NAME]`, `[REGISTRY_TOKEN]`                         |
|  [07]   | **Docker**      | `[BASE_IMAGE]`, `[BUILDER_IMAGE]`, `[ENTRYPOINT]`                           |

### [03.2]-[HARDEN_RUNNER_SCOPE]

`harden-runner` is included as the first step in every workflow job template (basic, reusable). Action templates (composite, Docker, JavaScript) do NOT include `harden-runner` — the calling workflow is responsible for adding it as the first step in the job that invokes the action. Actions are steps, not jobs.

[REFERENCE] [custom-actions.md](./references/custom-actions.md) — Action type selection, metadata, runtime deprecation.

## [04]-[EXAMPLES]

Each example demonstrates distinct patterns with minimal overlap. Load relevant examples before generation to match the target scenario.

## [05]-[ACTION_DISCOVERY]

Static SHA catalogs decay — actions release frequently and stale pins miss security patches. Resolve versions at generation time. Never embed hardcoded SHAs in reference docs or templates.

[RESOLUTION_PROTOCOL]:

1. `git ls-remote --tags https://github.com/{owner}/{repo}` — verify tag exists.
2. `gh api repos/{owner}/{repo}/git/ref/tags/{tag} --jq '.object.sha'` — resolve tag to full SHA.
3. Format: `owner/repo@<40-char-SHA> # vX.Y.Z`.

[FALLBACK_METHODS]:

- Context7 MCP: `resolve-library-id` then `get-library-docs` for action documentation.
- WebSearch: `"[owner/repo] [version] github action"` for release notes.

[IMPORTANT]:

- [ALWAYS]: Verify the tag exists before pinning — deleted tags return empty results.
- [ALWAYS]: Include version comment suffix (`# vX.Y.Z`) — Dependabot/Renovate parse these for automated updates.
- [NEVER]: Embed static SHAs in reference files — they decay within weeks.

[REFERENCE] [version-discovery.md](./references/version-discovery.md) — Discovery protocol, SHA pinning format, common actions index, automated maintenance.

## [06]-[VALIDATION]

[VALIDATION_PIPELINE]:

| [INDEX] | [STAGE]             | [TOOL]            | [VALIDATES]                                                          |
| :-----: | :------------------ | :---------------- | :------------------------------------------------------------------- |
|  [01]   | **Static Analysis** | actionlint 1.7.10 | YAML syntax, expressions, runner labels, action inputs, CRON, globs. |
|  [02]   | **Best Practices**  | 11 custom checks  | SHA pinning, permissions, injection, timeouts, harden-runner.        |
|  [03]   | **Local Execution** | act v0.2.84       | Dry-run validation against Docker images (requires Docker).          |

[BEST_PRACTICE_CHECKS]:

| [INDEX] | [CHECK]                  | [TAG]              | [DETECTS]                                                    |
| :-----: | :----------------------- | :----------------- | :----------------------------------------------------------- |
|  [01]   | **Deprecated commands**  | `[DEPRECATED-CMD]` | `::set-output`, `::save-state`, `::set-env`, `::add-path`.   |
|  [02]   | **Missing permissions**  | `[PERMISSIONS]`    | No top-level `permissions: {}` deny-all default.             |
|  [03]   | **Unpinned actions**     | `[UNPINNED]`       | Mutable tags (`@v1`, `@main`), abbreviated SHAs.             |
|  [04]   | **SHA without comment**  | `[SHA-NO-COMMENT]` | SHA-pinned but missing `# vX.Y.Z` version comment.           |
|  [05]   | **Missing timeout**      | `[TIMEOUT]`        | Jobs without `timeout-minutes:` (default is 6 hours).        |
|  [06]   | **Deprecated runners**   | `[RUNNER]`         | `ubuntu-20.04`, `macos-12`, `macos-13`, `windows-2019`.      |
|  [07]   | **Missing concurrency**  | `[CONCURRENCY]`    | No `concurrency:` group or missing `cancel-in-progress`.     |
|  [08]   | **PAT usage**            | `[APP-TOKEN]`      | PATs for cross-repo ops (use `create-github-app-token`).     |
|  [09]   | **No harden-runner**     | `[HARDEN]`         | Missing or not first step in job (CVE-2025-30066 detection). |
|  [10]   | **Expression injection** | `[INJECTION]`      | Direct `${{ github.event.* }}` in `run:` blocks.             |
|  [11]   | **Immutable actions**    | `[IMMUTABLE]`      | Action publishing without immutable OCI (informational).     |

[ERROR_ROUTING]: Match error patterns to reference files — [common_errors.md](references/common_errors.md) (syntax, expressions, deprecated), [runners.md](references/runners.md) (labels, deprecations), [supply_chain.md](references/supply_chain.md) (SHA, OIDC, SBOM, harden-runner), [modern_features.md](references/modern_features.md) (reusable workflows, concurrency, matrix, node runtime), [act_usage.md](references/act_usage.md) (actionlint rules, act limitations).

[TROUBLESHOOTING]:

| [INDEX] | [ISSUE]                     | [SOLUTION]                                     |
| :-----: | :-------------------------- | :--------------------------------------------- |
|  [01]   | **Tools not found**         | Install actionlint + act (see act_usage.md).   |
|  [02]   | **Docker not running**      | Start Docker or validate with actionlint only. |
|  [03]   | **act fails, GitHub works** | See act_usage.md — Limitations.                |
|  [04]   | **ARM Mac arch mismatch**   | Add `--container-architecture linux/amd64`.    |
|  [05]   | **Custom runner labels**    | Declare in `.github/actionlint.yaml`.          |

[VERIFY] Completion:

- [ ] Supply chain: Every `uses:` reference SHA-pinned with `# vX.Y.Z` comment suffix.
- [ ] Security: Top-level `permissions: {}`, per-job minimal grants, `harden-runner` first step.
- [ ] Injection: No direct `${{ github.event.* }}` in `run:` blocks — all through `env:` indirection.
- [ ] Performance: Caching enabled, `concurrency` groups set, `timeout-minutes:` on every job.
- [ ] Structure: Descriptive `name:` on workflow/jobs/steps, lowercase-hyphen filenames.
- [ ] Outputs: `>> $GITHUB_OUTPUT` for data, `>> $GITHUB_STEP_SUMMARY` for summaries.
- [ ] Harden-runner: Workflow jobs include it; action templates note caller responsibility.
- [ ] All errors resolved with reference-backed fixes; warnings documented.

[REFERENCE] [best-practices.md](./references/best-practices.md) — Anti-patterns with specific remediations.
