// Title         : topology.ts
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : services/topology.ts
// ----------------------------------------------------------------------------
// Services estate as typed rows: the Doppler topology (projects, environments,
// branch configs, service tokens, machine directory scopes) and the GitHub
// settings surface (repository merge hygiene, main-guard rulesets). estate.ts
// materializes rows into resources, driver.ts applies scope rows machine-side.

/**
 * Every row is declared end-state, managed forever. Origin: "adopt" rows
 * import live CLI/gh-born resources; "mint" rows are created fresh by the
 * program and never carry an import ID.
 */
type Origin = "adopt" | "mint";

type ProjectRow = {
  readonly slug: string;
  readonly description: string;
  readonly origin: Origin;
};

type EnvironmentRow = {
  readonly project: string;
  readonly slug: string;
  readonly name: string;
  readonly origin: Origin;
};

type ConfigRow = {
  readonly project: string;
  readonly environment: string;
  readonly name: string;
  readonly origin: Origin;
};

type TokenRow = {
  readonly project: string;
  readonly config: string;
  readonly name: string;
  readonly access: "read" | "read/write";
};

type ScopeRow = {
  readonly dir: string;
  readonly project: string;
  readonly config: string;
};

type SecretSource = {
  readonly project: string;
  readonly config: string;
  readonly name: string;
};

type WebhookRow = {
  readonly project: string;
  readonly slug: string;
  readonly url: string;
  readonly enabledConfigs: readonly string[];
  /** Static custom payload: no secret names ride the wire; the HMAC signature is the auth boundary. */
  readonly payload: string;
  /** Signing-secret custody coordinate; the driver brokers its value at apply time. */
  readonly secretSource: SecretSource;
  readonly origin: Origin;
};

type RepositoryRow = {
  readonly name: string;
  readonly description: string;
  readonly origin: Origin;
};

type RulesetRow = {
  readonly repository: string;
  readonly name: string;
  /** Live ruleset ID; the adopt import ID is `<repository>:<importId>`. */
  readonly importId: number;
  readonly origin: Origin;
};

type ReviewerRow = {
  readonly identity: "coderabbit" | "greptile" | "copilot" | "macroscope";
  /** app = GitHub App with repo-owned config artifacts; ruleset = GitHub-native ruleset rule (no config file). */
  readonly mechanism: "app" | "ruleset";
  readonly posture: "active" | "gated";
  readonly trigger: string;
  readonly statusCheck: boolean;
  /** Overlap class partitions review authority so the matrix stays non-redundant by construction. */
  readonly overlapClass: "line-review" | "semantic-review" | "native-review" | "remediation";
  /** Repo-relative config artifacts hashed by `driver.ts reviewers`; empty for ruleset-native identities. */
  readonly artifacts: readonly string[];
};

/**
 * Live import IDs: projects import by slug, environments by `project.slug`,
 * branch configs by `project.environment.name`.
 */
const projects = [
  { slug: "agent-runtime", description: "AI agent runtime secrets", origin: "mint" },
  { slug: "parametric-forge", description: "macOS machine and Home Manager toolchain secrets", origin: "adopt" },
  { slug: "maghz", description: "Maghz VPS runtime secrets", origin: "adopt" },
  { slug: "rasm", description: "Rasm repo and service secrets", origin: "adopt" },
] as const satisfies readonly ProjectRow[];

/**
 * API-minted projects carry zero environments, so agent-runtime's ride as mint
 * rows; each environment creates its same-slug root config. Personal-configs
 * posture is applied imperatively at migration: the provider omits the field
 * from reads, so a declared `false` here could never plan.
 */
const environments = [
  { project: "agent-runtime", slug: "dev", name: "Development", origin: "mint" },
  { project: "agent-runtime", slug: "stg", name: "Staging", origin: "mint" },
  { project: "agent-runtime", slug: "prd", name: "Production", origin: "mint" },
  { project: "parametric-forge", slug: "dev", name: "Development", origin: "adopt" },
  { project: "parametric-forge", slug: "stg", name: "Staging", origin: "adopt" },
  { project: "parametric-forge", slug: "prd", name: "Production", origin: "adopt" },
  { project: "maghz", slug: "dev", name: "Development", origin: "adopt" },
  { project: "maghz", slug: "stg", name: "Staging", origin: "adopt" },
  { project: "maghz", slug: "prd", name: "Production", origin: "adopt" },
  { project: "rasm", slug: "dev", name: "Development", origin: "adopt" },
  { project: "rasm", slug: "stg", name: "Staging", origin: "adopt" },
  { project: "rasm", slug: "prd", name: "Production", origin: "adopt" },
] as const satisfies readonly EnvironmentRow[];

/**
 * Branch configs only; root configs ride their environment. The agent-runtime
 * secret set lives in its `dev` root config, so no branch row exists for it.
 * Exactly one maghz dev config (the `dev` root) serves local and remote work.
 */
const configs = [
  { project: "parametric-forge", environment: "dev", name: "dev_machine", origin: "adopt" },
  { project: "maghz", environment: "prd", name: "prd_host", origin: "adopt" },
  { project: "rasm", environment: "dev", name: "dev_repo", origin: "adopt" },
] as const satisfies readonly ConfigRow[];

/**
 * Static Developer-plan service tokens; no rotation automation. Replacement
 * for a leaked or aged token is manual revoke-and-remint: drop the row and
 * `up --target=<project>/<config>/<name>` (revokes), restore the row and
 * target again (mints), then hand the fresh key off through 1Password.
 * agent-readonly feeds the macOS agent hook; maghz-host-readonly is the
 * Maghz VPS runtime consumer.
 */
const tokens = [
  { project: "agent-runtime", config: "dev", name: "agent-readonly", access: "read" },
  { project: "maghz", config: "prd_host", name: "maghz-host-readonly", access: "read" },
] as const satisfies readonly TokenRow[];

/**
 * Machine directory-scope rows: the replacement for every per-repo
 * doppler.yaml. driver.ts applies them idempotently via
 * `doppler configure set` and reconciles stray rows under scopeRoot away.
 */
const scopeRoot = "/Users/bardiasamiee/Documents/99.Github";

const scopes = [
  { dir: `${scopeRoot}/Parametric_Forge`, project: "parametric-forge", config: "dev_machine" },
  { dir: `${scopeRoot}/Maghz`, project: "maghz", config: "dev" },
  { dir: `${scopeRoot}/Rasm`, project: "rasm", config: "dev_repo" },
] as const satisfies readonly ScopeRow[];

/**
 * Change-notification webhooks. maghz-prd-redeploy targets the Maghz VPS hook
 * container (the stack-owned redeploy consumer) through the stack's Caddy TLS
 * front — Doppler mandates HTTPS delivery. Doppler signs each delivery with
 * the brokered secret, the consumer verifies and appends one receipt row as
 * the durable redeploy demand. The consumer owns idempotency — delivery is
 * at-least-once.
 */
const webhooks = [
  {
    project: "maghz",
    slug: "maghz-prd-redeploy",
    url: "https://31-97-131-41.sslip.io/hooks/doppler",
    enabledConfigs: ["prd_host"],
    payload: JSON.stringify({ event: "maghz.prd_host.secrets.update" }),
    secretSource: { project: "maghz", config: "prd_host", name: "MAGHZ_HOOK__SIGNING_SECRET" },
    origin: "mint",
  },
] as const satisfies readonly WebhookRow[];

/**
 * GitHub settings-as-code: every owned repo carries the same merge-hygiene
 * policy (estate.ts owns the shared policy values) and one active main-guard
 * ruleset (non-fast-forward + deletion protection on the default branch).
 * Rows adopt the live gh-applied state; graduation replaces `gh api` checks.
 */
const repositories = [
  {
    name: "Parametric_Forge",
    description: "My Nix based repo for NixOS/Darwin configuration, dotfiles, and more",
    origin: "adopt",
  },
  { name: "Rasm", description: "AEC/design-geometry workspace", origin: "adopt" },
  { name: "Maghz", description: "Agent-operated second brain infrastructure", origin: "adopt" },
] as const satisfies readonly RepositoryRow[];

const rulesets = [
  { repository: "Parametric_Forge", name: "main-guard", importId: 18698897, origin: "adopt" },
  { repository: "Rasm", name: "main-guard", importId: 18698898, origin: "adopt" },
  { repository: "Maghz", name: "main-guard", importId: 18698899, origin: "adopt" },
] as const satisfies readonly RulesetRow[];

/**
 * One shared main-guard rule policy: history protection plus Copilot review as
 * the GitHub-native ruleset rule. The bare copilotCodeReview block requests a
 * Copilot review on every new PR; reviewOnPush stays off because CodeRabbit and
 * Greptile already re-review each push — a third per-push pass is spend, not
 * signal. Direct pushes to main stay legal: this is not a pull_request rule.
 */
const rulesetPolicy = {
  nonFastForward: true,
  deletion: true,
  copilotCodeReview: { reviewOnPush: false, reviewDraftPullRequests: false },
} as const;

/**
 * Reviewer service matrix: each identity is one service row; config custody
 * stays repo-owned (each repo tunes its own artifacts), and `driver.ts
 * reviewers` proves presence plus config hash across all repository rows.
 * Macroscope holds at gated: check-run names, fix authority, and
 * branch-mutation policy are not typed rows yet.
 */
const reviewers = [
  {
    identity: "coderabbit",
    mechanism: "app",
    posture: "active",
    trigger: "pr-open+push",
    statusCheck: true,
    overlapClass: "line-review",
    artifacts: [".coderabbit.yaml"],
  },
  {
    identity: "greptile",
    mechanism: "app",
    posture: "active",
    trigger: "pr-open+push",
    statusCheck: true,
    overlapClass: "semantic-review",
    artifacts: [".greptile/config.json", ".greptile/files.json", ".greptile/rules.md"],
  },
  {
    identity: "copilot",
    mechanism: "ruleset",
    posture: "active",
    trigger: "pr-open",
    statusCheck: false,
    overlapClass: "native-review",
    artifacts: [],
  },
  {
    identity: "macroscope",
    mechanism: "app",
    posture: "gated",
    trigger: "pr-open",
    statusCheck: false,
    overlapClass: "remediation",
    artifacts: [],
  },
] as const satisfies readonly ReviewerRow[];

// --- [EXPORTS] ------------------------------------------------------------------

export {
  configs,
  environments,
  projects,
  repositories,
  reviewers,
  rulesetPolicy,
  rulesets,
  scopeRoot,
  scopes,
  tokens,
  webhooks,
};
export type {
  ConfigRow,
  EnvironmentRow,
  Origin,
  ProjectRow,
  RepositoryRow,
  ReviewerRow,
  RulesetRow,
  ScopeRow,
  SecretSource,
  TokenRow,
  WebhookRow,
};
