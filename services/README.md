# [SERVICES]

External SaaS desired state as typed Pulumi rows: `topology.ts` declares rows, `estate.ts` folds them into resources, `driver.ts` owns stack lifecycle, credential brokering, the machine scope rail, and the reviewer matrix. Boundary law: this directory owns external service/control-plane desired state only — terminal configs, themes, launchd wrappers, and aliases never enter Pulumi. The repo root is the workspace: one `package.json` plus the `pnpm-workspace.yaml` catalog own every pin, and all verbs run from the root.

## [01]-[ADMITTED_PROVIDERS]

| [INDEX] | [PROVIDER]             | [OWNS]                                                                                          |
| :-----: | :--------------------- | :---------------------------------------------------------------------------------------------- |
|  [01]   | `@pulumiverse/doppler` | Projects, environments, branch configs, service tokens, change-notification webhooks            |
|  [02]   | `@pulumi/github`       | Repository core (merge hygiene, features) and main-guard rulesets incl. Copilot review, 3 repos |

Pins follow the package schema, never registry-page text. `pulumi-command` is admitted as tactical last-mile glue only — it installs with its first real resource, never anticipatorily. Doppler `secretsSync` and service-account rows wait for a real consumer: Actions secret sync is rejected while zero workflows exist, and every webhook row names its live receiver. Cloudflare, Tailscale, Hostinger-bridge, and Cachix Deploy hold behind their annex tripwires.

## [02]-[GITHUB_ROW_FAMILIES]

| [INDEX] | [FAMILY]                 | [STATE]                                                                                                     |
| :-----: | :----------------------- | :---------------------------------------------------------------------------------------------------------- |
|  [01]   | Repository core          | Uniform merge hygiene + feature booleans, `protect: true`, adopt-imported                                   |
|  [02]   | Rulesets / branch policy | `main-guard` on `~DEFAULT_BRANCH`; direct pushes to main stay legal                                         |
|  [03]   | Environments             | Empty by ruling: no real deploy targets exist; symmetry environments are policy theater                     |
|  [04]   | Secret/variable rows     | Empty by ruling: zero workflow consumers; Actions secret sync rejected until a workflow names its exact set |
|  [05]   | Access bindings          | Empty by ruling: sole-owner repos, account-level SSH identity; no collaborators, teams, or deploy keys      |
|  [06]   | Surface rows             | Empty by ruling: no owned repo webhooks, Pages, releases, or GitHub-native config files                     |

A family leaves EMPTY the moment a real consumer exists; the row lands in `topology.ts`, never through `gh api`. `gh` is operator/discovery/breakglass only — durable GitHub state mutation through `gh api` is retired.

## [03]-[CREDENTIAL_CUSTODY]

The driver brokers three credentials from 1Password per invocation (ambient env short-circuits): the Pulumi passphrase, the Doppler IaC token, and `GITHUB_TOKEN`. Webhook signing secrets broker from their Doppler custody rows at apply time. The brokered operator PAT is the durable auth owner; a GitHub App token supersedes it only when org/project surfaces exceed fine-grained-PAT reach — that switch is an admission row, not a config edit.

## [04]-[REVIEWER_MATRIX]

CodeRabbit (line review), Greptile (semantic review), and Copilot (native ruleset rule) are the three active reviewer identities; Macroscope stays gated until check-run names, fix authority, and branch-mutation policy are typed rows. Config custody is repo-owned — each repo tunes its own `.coderabbit.yaml` and `.greptile/` artifacts — and `node services/driver.ts reviewers` is the matrix receipt: presence plus config hash per identity per repo, with gated identities proving absence.

## [05]-[VERBS]

| [INDEX] | [VERB]                                  | [PROVES]                                                                 |
| :-----: | :-------------------------------------- | :----------------------------------------------------------------------- |
|  [01]   | `node services/driver.ts preview`       | Desired-vs-live estate diff; steady state is `{"same":N}`                |
|  [02]   | `node services/driver.ts up`            | Applies rows; `--target=<p>/<c>/<token>` drives token revoke-and-remint  |
|  [03]   | `node services/driver.ts scopes doctor` | Machine directory scopes match rows; zero stray scopes or `doppler.yaml` |
|  [04]   | `node services/driver.ts reviewers`     | Reviewer identity presence + config hashes across all repo roots         |
|  [05]   | `node services/driver.ts outputs`       | Token outputs; `--reveal` is the one-time handoff path                   |
