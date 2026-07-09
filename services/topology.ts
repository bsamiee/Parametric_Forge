// Title         : topology.ts
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : services/topology.ts
// ----------------------------------------------------------------------------
// Doppler estate as typed rows. Every project, environment, branch config,
// service token, and machine directory scope is a row here; estate.ts
// materializes rows into resources, driver.ts applies scope rows machine-side.

/**
 * Row lifecycle:
 * - steady  : declared end-state, managed forever.
 * - retire  : adopted from live state, destroyed when keepRetired flips false.
 * - cutover : adopted from live state, destroyed when keepCutover flips false
 *             (timed after the T3/T4 secrets-consumption cutover proof).
 * Origin: "adopt" rows import live CLI-born resources; "mint" rows are created
 * fresh by the program and never carry an import ID.
 */
type Disposition = "steady" | "retire" | "cutover";
type Origin = "adopt" | "mint";

type ProjectRow = {
  readonly slug: string;
  readonly description: string;
  readonly disposition: Disposition;
  readonly origin: Origin;
};

type EnvironmentRow = {
  readonly project: string;
  readonly slug: string;
  readonly name: string;
  readonly disposition: Disposition;
  readonly origin: Origin;
};

type ConfigRow = {
  readonly project: string;
  readonly environment: string;
  readonly name: string;
  readonly disposition: Disposition;
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

/**
 * Live import IDs: projects import by slug, environments by `project.slug`,
 * branch configs by `project.environment.name`.
 */
const projects = [
  { slug: "agent-runtime", description: "AI agent runtime secrets", disposition: "steady", origin: "mint" },
  { slug: "parametric-forge", description: "macOS machine and Home Manager toolchain secrets", disposition: "steady", origin: "adopt" },
  { slug: "maghz", description: "Maghz VPS runtime secrets", disposition: "steady", origin: "adopt" },
  { slug: "rasm", description: "Rasm repo and service secrets", disposition: "steady", origin: "adopt" },
] as const satisfies readonly ProjectRow[];

/**
 * API-minted projects carry zero environments, so agent-runtime's ride as mint
 * rows; each environment creates its same-slug root config. Retiring projects'
 * environments die with the project row. Personal-configs posture is applied
 * imperatively at migration: the provider omits the field from reads, so a
 * declared `false` here could never plan.
 */
const environments = [
  { project: "agent-runtime", slug: "dev", name: "Development", disposition: "steady", origin: "mint" },
  { project: "agent-runtime", slug: "stg", name: "Staging", disposition: "steady", origin: "mint" },
  { project: "agent-runtime", slug: "prd", name: "Production", disposition: "steady", origin: "mint" },
  { project: "parametric-forge", slug: "dev", name: "Development", disposition: "steady", origin: "adopt" },
  { project: "parametric-forge", slug: "stg", name: "Staging", disposition: "steady", origin: "adopt" },
  { project: "parametric-forge", slug: "prd", name: "Production", disposition: "steady", origin: "adopt" },
  { project: "maghz", slug: "dev", name: "Development", disposition: "steady", origin: "adopt" },
  { project: "maghz", slug: "stg", name: "Staging", disposition: "steady", origin: "adopt" },
  { project: "maghz", slug: "prd", name: "Production", disposition: "steady", origin: "adopt" },
  { project: "rasm", slug: "dev", name: "Development", disposition: "steady", origin: "adopt" },
  { project: "rasm", slug: "stg", name: "Staging", disposition: "steady", origin: "adopt" },
  { project: "rasm", slug: "prd", name: "Production", disposition: "steady", origin: "adopt" },
] as const satisfies readonly EnvironmentRow[];

/**
 * Branch configs only; root configs ride their environment. The agent-runtime
 * secret set lives in its `dev` root config, so no branch row exists for it.
 * maghz/dev_local collapses into the maghz/dev root at cutover so exactly one
 * maghz dev config serves local and remote work.
 */
const configs = [
  { project: "parametric-forge", environment: "dev", name: "dev_machine", disposition: "steady", origin: "adopt" },
  { project: "maghz", environment: "prd", name: "prd_host", disposition: "steady", origin: "adopt" },
  { project: "maghz", environment: "dev", name: "dev_local", disposition: "cutover", origin: "adopt" },
  { project: "rasm", environment: "dev", name: "dev_repo", disposition: "steady", origin: "adopt" },
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

// --- [EXPORTS] ------------------------------------------------------------------

export { configs, environments, projects, scopeRoot, scopes, tokens };
export type { ConfigRow, Disposition, EnvironmentRow, Origin, ProjectRow, ScopeRow, TokenRow };
