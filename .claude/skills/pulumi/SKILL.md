---
name: pulumi
description: >-
    Use this skill for any task that creates, modifies, inspects, or destroys cloud infrastructure
    or SaaS configuration, from one-off CLI operations to full multi-resource projects, across
    providers in the Pulumi ecosystem — AWS, Azure, GCP, Kubernetes, Cloudflare, Hostinger, Auth0,
    Datadog, Vercel, and others — driven through one CLI, one state model, and one credential layer.
    Trigger even when the task does not name Pulumi; phrasings like "deploy this app," "provision a
    database," "stand up a VPC," "configure Auth0," or "tear down staging" qualify, as do tasks that
    migrate Terraform, CloudFormation, CDK, Bicep, or ARM code to Pulumi, Automation API embedding,
    ComponentResource authoring, Output/apply questions, and failed pulumi up or preview debugging.
    Do not trigger for application runtime code that reads or writes data via cloud SDKs; that is
    application code, not infrastructure. Interactive Hostinger domain, DNS, and VPS operations
    belong to the hostinger skill.
---

# [PULUMI]

Pulumi creates and manages cloud infrastructure — virtual machines, storage, Kubernetes clusters, databases, DNS, SaaS configuration — from code or CLI commands: it previews the pending change, then applies it. Work enters at the smallest of three levels that fits the task; depth for each concern rides one hop down in a reference.

| [INDEX] | [LEVEL] | [SURFACE]                         | [WHEN]                                        |
| :-----: | :------ | :-------------------------------- | :-------------------------------------------- |
|  [01]   | L1      | `pulumi do` CLI                   | Single resource or multi-vendor bootstrapping |
|  [02]   | L2      | Pulumi project in a host language | Multiple related resources                    |
|  [03]   | L3      | Pulumi Cloud governance layer     | Governance and hosted runs                    |

A single-bucket request in a directory with no Pulumi project is an L1 task — no project scaffolding. A VPC with subnets and a cluster is L2 from the start. Nightly drift detection on an existing stack is L3. Converting Terraform, CloudFormation, CDK, ARM, or Bicep code is `pulumi convert` plus the docs at https://www.pulumi.com/docs/iac/adopting-pulumi/, independent of the level model.

Level choice requires knowing what is already on disk: inspect the filesystem first, and in a restricted context ask before any Pulumi command runs — a command that requires a login silently provisions a new agent account parallel to one the operator already owns.

## [01]-[ROUTING]

- [01]-[CLI_OPERATIONS](references/cli-operations.md): L1 command shape, property input files, `pulumi package info` discovery, output contracts, cross-resource value passing, and `pulumi import` graduation.
- [02]-[BEST_PRACTICES](references/best-practices.md): `Output<T>` and `apply()` law, passing outputs as inputs, secrets hygiene, refactor aliases, preview discipline, and CI wiring before any non-trivial program.
- [03]-[COMPONENTS](references/components.md): `ComponentResource` anatomy, args interface design, multi-language packaging, and distribution.
- [04]-[AUTOMATION_API](references/automation-api.md): embedding Pulumi in a program, multi-stack orchestration, and inline versus local programs.
- [05]-[DEBUGGING](references/debugging.md): reading a failed `up` or `preview` from Pulumi Cloud's record, tracing the cause, and placing the fix.

## [02]-[LEVEL_1]

`pulumi do` runs one-shot, stateless resource operations against any provider — no project files, no `${...}` wiring, no Pulumi state. The canonical invocation is `npx pulumi <command>`; `npx pulumi version` confirms availability without touching Pulumi Cloud, and the resource verbs require CLI `v3.243.0` or newer.

```text
pulumi do <pkg:mod:type> create [flags]
pulumi do <pkg:mod:type> read|patch|delete <id> [flags]
pulumi do <pkg:mod:type> list [flags]
```

- `create` provisions and prints properties as JSON including the cloud `id`; pass `--yes` in non-interactive contexts.
- `read <id>` fetches live provider state; writes nothing.
- `patch <id>` shallow-overlays top-level properties in place; a change requiring replacement fails rather than recreating.
- `delete <id>` is irreversible — explicit operator confirmation of the specific resource precedes `--yes`, never a non-interactive default.
- `list` enumerates existing instances where the resource type implements listing.

First invocation in an agent context without saved credentials may provision an ephemeral agent account and print a claim banner to stderr. Surface the claim URL to the operator immediately and again in the final response — a session ending without it strands resources. On authentication failure, ask the operator to run `pulumi login`; never fall back to `pulumi login --local` or set `PULUMI_CONFIG_PASSPHRASE`. Provider credentials are separate and arrive through the provider's native environment variables (`AWS_PROFILE`, `CLOUDFLARE_API_TOKEN`, `GOOGLE_APPLICATION_CREDENTIALS`); when absent, ask before any command that calls out to the cloud.

When a `Pulumi.yaml` project already manages a resource, changes go through the program — never `pulumi do`.

## [03]-[LEVEL_2]

A Pulumi project is code in Python, TypeScript, Go, C#, or Java describing related resources and their dependencies. Match the codebase language when one is present; default to TypeScript otherwise.

```bash copy-safe
npx pulumi new aws-typescript      # template list: npx pulumi template list
npx pulumi preview                 # show what would change — always before up
npx pulumi up                      # apply
npx pulumi refresh                 # reconcile state with cloud reality
```

`pulumi destroy` tears down every resource in the stack and is generally irreversible; explicit operator confirmation of the stack name precedes it. A stack only touches resources tracked in its state, so removing a resource from the program deletes it from the cloud on the next `up`; `protect: true` guards anything unaffordable to lose.

Stacks isolate instances of a project — one per environment (`dev`, `staging`, `prod`) is the standard pattern:

```bash copy-safe
npx pulumi stack init dev
npx pulumi config set aws:region us-west-2
npx pulumi config set --secret dbPassword "..."
```

## [04]-[LEVEL_3]

Pulumi Cloud layers governance onto a project: ESC composes secrets and configuration from cloud secret managers, OIDC-vended credentials, and other environments into one resolved bundle; policy packs run against the resource graph before any cloud API call; deployments run operations server-side; schedules automate drift detection and rotation.

```bash template
npx pulumi env init my_org/aws/prod
npx pulumi env run my_org/aws/prod -- aws s3 ls     # injects credentials; never capture `env open` output
npx pulumi policy new aws-typescript
npx pulumi deployment run update --stack my_org/proj/prod
npx pulumi refresh --preview-only                    # ad-hoc local drift check
npx pulumi stack schedule new --kind drift --cron "0 0 * * *"
```

A provider with OIDC federation vends cloud credentials through it rather than static keys in environment YAML. A schedule is standing automation that outlives the session — confirm operation, cadence, and stack with the operator first, and default to detection-only: `--kind drift --auto-remediate` and `--kind ttl` act without a human in the loop.

## [05]-[REFERENCE]

An uncertain CLI flag, command shape, or resource property is looked up, never guessed: `npx pulumi <command> --help` documents every flag from the CLI itself; the full reference, provider catalog, and conceptual docs live at https://www.pulumi.com/docs and https://www.pulumi.com/registry/.
