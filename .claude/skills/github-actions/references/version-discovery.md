# [H1][VERSION-DISCOVERY]

## [01]-[DISCOVERY_PROTOCOL]

[IMPORTANT]:

- [ALWAYS]: Resolve versions at generation time — never embed static SHAs in reference docs.
- [ALWAYS]: Verify tags exist before pinning.
- [ALWAYS]: Dereference annotated tags with `^{}` — lightweight tags resolve directly.

```bash template
# Fetch latest release tag
gh api repos/{owner}/{repo}/releases/latest --jq '.tag_name'

# Resolve tag to full SHA (dereference annotated tags)
git ls-remote --tags https://github.com/{owner}/{repo} | grep 'refs/tags/{tag}' | tail -1 | cut -f1

# Batch resolve — all actions in workflow
grep -oP 'uses:\s+\K[^@]+' .github/workflows/*.yml | sort -u | while read action; do
  tag=$(gh api "repos/$action/releases/latest" --jq '.tag_name' 2>/dev/null)
  sha=$(git ls-remote --tags "https://github.com/$action" | grep "refs/tags/$tag" | tail -1 | cut -f1)
  printf '%s@%s # %s\n' "$action" "$sha" "$tag"
done
```

## [02]-[SHA_PINNING_FORMAT]

Format: `owner/repo@<40-char-SHA> # vX.Y.Z`

[INCIDENT_TJ_ACTIONS_CHANGED_FILES]:

- Attacker retargeted ALL existing version tags to malicious commit.
- 23,000+ repos affected — secrets extracted from Runner Worker process memory.
- Cascading supply chain: enabled by prior compromise of `reviewdog/action-setup@v1` (CVE-2025-30154).
- CISA advisory issued March 18, 2025.
- `step-security/harden-runner` first detected the anomalous egress.

[CRITICAL]:

- [ALWAYS]: Pin to full 40-character SHA with version comment suffix.
- [NEVER]: Use mutable refs (`@main`, `@latest`, `@v1`) in production workflows.

## [03]-[AUTOMATED_MAINTENANCE]

```yaml conceptual
# .github/dependabot.yml — automated SHA updates
version: 2
updates:
    - package-ecosystem: "github-actions"
      directory: "/"
      schedule: { interval: "weekly" }
      groups:
          actions: { patterns: ["*"] }
```

Dependabot natively parses `# v4.2.2` comments after SHA pins — updates both SHA and comment on new release.

```json conceptual
// renovate.json — alternative with pinDigests
{
    "$schema": "https://docs.renovatebot.com/renovate-schema.json",
    "extends": ["config:recommended", "helpers:pinGitHubActionDigests"]
}
```

Renovate resolves version tag from comment, fetches new SHA, updates both. `helpers:pinGitHubActionDigests` auto-converts tag refs to SHA pins.

## [04]-[IMMUTABLE_ACTIONS]

[STATUS]: OCI immutable publishing paused (not progressing to GA). GitHub pivoted to org-level SHA pinning enforcement as the primary supply chain control.

- [ORIGINAL_PLAN]: Actions packaged as immutable OCI containers in GHCR with version tags that cannot be retargeted. Registry stability issues blocked rollout.
- [CURRENT_APPROACH]: Org/repo setting "Require actions to be pinned to a full-length commit SHA" — enforces `@<40-char-SHA>` format, rejects `@v1`/`@main` refs. Available in GitHub Enterprise Cloud and Server `3.12+`.
- `actions/publish-immutable-action` repo exists but is not usable for external consumers.
- SHA pinning plus Dependabot/Renovate automated updates is the supply chain posture until immutable actions reach GA.

## [05]-[COMMON_ACTIONS_INDEX]

[SETUP]: checkout, cache, artifacts, language runtimes, scripting.

| [INDEX] | [ACTION]                             | [MAJOR] | [KEY_INPUTS]                            | [REQUIRED_PERMISSIONS] |
| :-----: | :----------------------------------- | :-----: | :-------------------------------------- | :--------------------- |
|  [01]   | `actions/checkout`                   |   v6    | `fetch-depth`, `ref`, `token`           | `contents: read`       |
|  [02]   | `actions/setup-node`                 |   v6    | `node-version`, `cache`, `registry-url` | _(none)_               |
|  [03]   | `actions/setup-python`               |   v5    | `python-version`, `cache`               | _(none)_               |
|  [04]   | `actions/setup-java`                 |   v4    | `distribution`, `java-version`, `cache` | _(none)_               |
|  [05]   | `actions/setup-go`                   |   v5    | `go-version`, `cache`                   | _(none)_               |
|  [06]   | `actions/cache`                      |   v5    | `path`, `key`, `restore-keys`           | _(none)_               |
|  [07]   | `actions/upload-artifact`            |   v6    | `name`, `path`, `retention-days`        | `actions: write`       |
|  [08]   | `actions/download-artifact`          |   v7    | `name`, `path`, `run-id`                | `actions: read`        |
|  [09]   | `actions/github-script`              |   v8    | `script`, `github-token`                | _varies by script_     |
|  [10]   | `google-github-actions/setup-gcloud` |   v2    | `version`, `project_id`                 | _(none)_               |

[BUILD]: docker image build, monorepo affected detection, change routing.

| [INDEX] | [ACTION]                     | [MAJOR] | [KEY_INPUTS]                           | [REQUIRED_PERMISSIONS]                  |
| :-----: | :--------------------------- | :-----: | :------------------------------------- | :-------------------------------------- |
|  [01]   | `nrwl/nx-set-shas`           |   v4    | `main-branch-name`, `workflow-id`      | `contents: read`, `actions: read`       |
|  [02]   | `docker/setup-buildx-action` |   v3    | _(none required)_                      | _(none)_                                |
|  [03]   | `docker/login-action`        |   v3    | `registry`, `username`, `password`     | `packages: write` _(GHCR)_              |
|  [04]   | `docker/build-push-action`   |   v6    | `context`, `push`, `tags`, `platforms` | `packages: write` _(GHCR)_              |
|  [05]   | `docker/metadata-action`     |   v5    | `images`, `tags`                       | _(none)_                                |
|  [06]   | `dorny/paths-filter`         |   v3    | `filters`, `base`                      | `contents: read`, `pull-requests: read` |

[DEPLOY]: cloud OIDC auth, release, PR automation, reporting, notifications.

| [INDEX] | [ACTION]                                | [MAJOR] | [KEY_INPUTS]                         | [REQUIRED_PERMISSIONS]                    |
| :-----: | :-------------------------------------- | :-----: | :----------------------------------- | :---------------------------------------- |
|  [01]   | `aws-actions/configure-aws-credentials` |   v6    | `role-to-assume`, `aws-region`       | `id-token: write` _(OIDC)_                |
|  [02]   | `azure/login`                           |   v2    | `client-id`, `tenant-id`             | `id-token: write` _(OIDC)_                |
|  [03]   | `google-github-actions/auth`            |   v3    | `workload_identity_provider`         | `id-token: write` _(OIDC)_                |
|  [04]   | `actions/create-github-app-token`       |   v2    | `app-id`, `private-key`, `owner`     | _(none — uses app credentials)_           |
|  [05]   | `softprops/action-gh-release`           |   v2    | `tag_name`, `name`, `body`, `files`  | `contents: write`                         |
|  [06]   | `peter-evans/create-pull-request`       |   v7    | `branch`, `title`, `commit-message`  | `contents: write`, `pull-requests: write` |
|  [07]   | `peter-evans/slash-command-dispatch`    |   v4    | `commands`, `permission`             | `contents: read`, `issues: write`         |
|  [08]   | `codecov/codecov-action`                |   v5    | `token`, `files`, `fail_ci_if_error` | _(none)_                                  |
|  [09]   | `slackapi/slack-github-action`          |   v2    | `method`, `token`, `payload`         | _(none — uses Slack token)_               |

[SECURITY]: linting, scanning, attestation, supply chain, runtime hardening.

| [INDEX] | [ACTION]                           | [MAJOR] | [KEY_INPUTS]                         | [REQUIRED_PERMISSIONS]                    |
| :-----: | :--------------------------------- | :-----: | :----------------------------------- | :---------------------------------------- |
|  [01]   | `super-linter/super-linter`        |   v7    | `validate_all_codebase`              | `contents: read`, `statuses: write`       |
|  [02]   | `sigstore/cosign-installer`        |   v4    | `cosign-release`                     | _(none)_                                  |
|  [03]   | `actions/dependency-review-action` |   v4    | `fail-on-severity`, `allow-licenses` | `contents: read`                          |
|  [04]   | `actions/attest-build-provenance`  |   v3    | `subject-name`, `subject-digest`     | `id-token: write`, `attestations: write`  |
|  [05]   | `actions/attest-sbom`              |   v3    | `subject-name`, `subject-digest`     | `id-token: write`, `attestations: write`  |
|  [06]   | `anchore/sbom-action`              |   v0    | `image`, `format`, `output-file`     | `contents: read`                          |
|  [07]   | `aquasecurity/trivy-action`        |   v0    | `image-ref`, `format`, `severity`    | `security-events: write` _(SARIF)_        |
|  [08]   | `github/codeql-action`             |   v4    | `languages`, `sarif_file`            | `security-events: write`, `actions: read` |
|  [09]   | `step-security/harden-runner`      |   v2    | `egress-policy`, `allowed-endpoints` | _(none)_                                  |
|  [10]   | `gitleaks/gitleaks-action`         |   v2    | `scan_mode`                          | `contents: read`                          |

- Further `[KEY_INPUTS]`: checkout `sparse-checkout`; setup-node `cache` (npm/yarn/pnpm); setup-python `cache` (pip/pipenv/poetry); setup-java `cache` (maven/gradle); upload-artifact `if-no-files-found`; build-push `cache-from`, `cache-to`; auth `service_account`; azure `subscription-id`; dependency-review `deny-licenses`; attest-build-provenance and attest-sbom `push-to-registry`/`sbom-path`; create-app-token `repositories`; create-pull-request `body`; super-linter `default_branch`.
- `[REQUIRED_PERMISSIONS]`: trivy `_(SARIF upload)_`.

[IMPORTANT] Column `[MAJOR]` shows the current major version series. Always resolve exact SHA via discovery protocol at generation time — never use bare `@vN` tags.

## [06]-[ARTIFACTS]

| [INDEX] | [PROPERTY]         | [VALUE]                                                     |
| :-----: | :----------------- | :---------------------------------------------------------- |
|  [01]   | **Immutability**   | Cannot be altered after upload — new upload = new ID.       |
|  [02]   | **Availability**   | Immediately downloadable — no wait for workflow completion. |
|  [03]   | **Retention**      | 1-90 days (default 90); configurable per upload.            |
|  [04]   | **Max size**       | 10 GB per artifact.                                         |
|  [05]   | **Cross-workflow** | Download via `run-id` from `workflow_run` trigger.          |
|  [06]   | **Versions**       | upload-artifact v6, download-artifact v7 (current stable).  |

```yaml template
- uses: actions/upload-artifact@<SHA> # v6
  with:
      name: build-output
      path: dist/
      retention-days: 7
      if-no-files-found: error
```

## [07]-[SIGNING_VERIFICATION]

**`gh attestation verify`** — GA in GitHub CLI. Verifies Sigstore-signed build provenance and SBOM attestations.

```bash template
# Verify binary against repo attestations
gh attestation verify <file-path> --repo owner/repo

# Verify OCI image against org-wide attestations
gh attestation verify oci://ghcr.io/owner/image:tag --owner owner

# Offline verification with downloaded bundle
gh attestation verify <file-path> --bundle /path/to/attestation.jsonl

# Verify non-default predicate type
gh attestation verify <file-path> --repo owner/repo --predicate-type https://spdx.dev/Document/v2.3

# JSON output for CI pipeline consumption
gh attestation verify <file-path> --repo owner/repo --format json
```

Key flags: `--repo` (single repo), `--owner` (org-wide), `--bundle` (offline), `--bundle-from-oci` (registry-stored), `--predicate-type` (non-default SLSA type), `--format json` (machine-readable).
