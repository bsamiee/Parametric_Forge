# [SERVICES]

External SaaS desired state as typed Pulumi rows: `topology.ts` declares rows, `estate.ts` folds them into resources, `driver.ts` owns stack lifecycle, credential brokering, the machine scope rail, and the reviewer matrix. Boundary law: this directory owns external service/control-plane desired state only — terminal configs, themes, launchd wrappers, and aliases never enter Pulumi. The repo root is the workspace: one `package.json` plus the `pnpm-workspace.yaml` catalog own every pin, and all verbs run from the root.

## [01]-[ADMITTED_PROVIDERS]

| [INDEX] | [PROVIDER]             | [OWNS]                                                                               |
| :-----: | :--------------------- | :----------------------------------------------------------------------------------- |
|  [01]   | `@pulumiverse/doppler` | Projects, environments, branch configs, service tokens, change-notification webhooks |
|  [02]   | `@pulumi/github`       | Repository core and merge hygiene; the ruleset family is dormant                    |

Pins follow the package schema, never registry-page text. `pulumi-command` is admitted as tactical last-mile glue only — it installs with its first real resource, never anticipatorily. Doppler `secretsSync` and service-account rows wait for a real consumer: Actions secret sync is rejected while zero workflows exist, and every webhook row names its live receiver. Cloudflare, Tailscale, Hostinger-bridge, and Cachix Deploy hold behind their annex tripwires.

## [02]-[GITHUB_ROW_FAMILIES]

| [INDEX] | [FAMILY]                 | [STATE]                                                                                                     |
| :-----: | :----------------------- | :---------------------------------------------------------------------------------------------------------- |
|  [01]   | Repository core          | Uniform agent merge hygiene and feature booleans, `protect: true`, adopt-imported                           |
|  [02]   | Rulesets / branch policy | Empty by ruling: `main` takes direct pushes; the dormant policy in `topology.ts` restores on a new row       |
|  [03]   | Environments             | Estate deployment rows stay empty; GitHub-managed agent environments remain platform-owned                  |
|  [04]   | Secret/variable rows     | Empty by ruling: zero workflow consumers; Actions secret sync rejected until a workflow names its exact set |
|  [05]   | Access bindings          | Empty by ruling: sole-owner repos, account-level SSH identity; no collaborators, teams, or deploy keys      |
|  [06]   | Surface rows             | Empty by ruling: no owned repo webhooks, Pages, releases, or GitHub-native config files                     |
|  [07]   | GitHub App census        | Typed installation IDs and selection modes; browser-custodied because SSH cannot authenticate REST control  |

A family leaves EMPTY the moment a real consumer exists; the row lands in `topology.ts`, never through `gh api`. `gh` is operator/discovery/breakglass only — durable GitHub state mutation through `gh api` is retired.

## [03]-[CREDENTIAL_CUSTODY]

The driver brokers the Pulumi passphrase and Doppler IaC token from 1Password when ambient values are absent. `GITHUB_TOKEN` resolves from the ambient agent environment or `agent-runtime/dev` through the brokered Doppler credential; webhook signing secrets resolve from their Doppler custody rows at apply time. The universal ED25519 identity owns Git transport and commit signing only. GitHub App installation selection remains browser-custodied because GitHub exposes no SSH-authenticated REST control surface, and the estate admits no broad classic PAT for that boundary.

## [04]-[REVIEWER_MATRIX]

The app census records ChatGPT Codex Connector, Claude, CodeRabbit, Google AI Studio, Greptile, Macroscope, and Nx Cloud. Reviewer config custody remains repo-owned, and `node services/driver.ts reviewers` separates applicable local artifacts, configuration hashes, default-branch installation evidence, hosted-PR activity, and required-check admission. Codex cloud settings own repository review enablement, and each top-level `AGENTS.md` owns its review focus; neither local `config.toml` nor Pulumi controls that SaaS boundary. `node services/driver.ts apps` emits the declared browser-custodied installation selection without claiming live API verification. Installation evidence never substitutes for a completed hosted review, and required checks enter a restored ruleset row only after a PR proves their stable context and integration identity.

## [05]-[VERBS]

| [INDEX] | [VERB]                                  | [PROVES]                                                                   |
| :-----: | :-------------------------------------- | :------------------------------------------------------------------------- |
|  [01]   | `node services/driver.ts preview`       | Desired-vs-live estate diff; steady state is `{"same":N}`                  |
|  [02]   | `node services/driver.ts up`            | Applies rows; `--target=<p>/<c>/<token>` drives token revoke-and-remint    |
|  [03]   | `node services/driver.ts scopes doctor` | Machine directory scopes match rows; zero stray scopes or `doppler.yaml`   |
|  [04]   | `node services/driver.ts reviewers`     | Reviewer configuration, installation, activity, and requirement evidence   |
|  [05]   | `node services/driver.ts apps`          | Declared GitHub App installation IDs, selection modes, and browser custody |
|  [06]   | `node services/driver.ts outputs`       | Token outputs; `--reveal` is the one-time handoff path                     |
|  [07]   | `node services/driver.ts refresh`       | Reconciles state against live provider reads before a diff                 |

`--refresh` on `preview`/`up` diffs against refreshed live state — the drift probe; `--expect-no-changes` on any stack verb fails the run when a change plans, so `preview --refresh --expect-no-changes` is the machine-checkable steady-state gate.
