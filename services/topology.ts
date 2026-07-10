// Title         : topology.ts
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : services/topology.ts
// ----------------------------------------------------------------------------
// Services estate as typed rows under one assembled owner: the Doppler
// topology (projects, environments, branch configs, service tokens, machine
// directory scopes, webhooks) and the GitHub settings surface (repositories,
// main-guard rulesets, reviewer matrix). estate.ts materializes rows into
// resources; driver.ts applies scope rows machine-side. Every row is declared
// end-state, managed forever: 'adopt' rows import live CLI/gh-born resources,
// 'mint' rows are created fresh and never carry an import ID.

type _Origin = 'adopt' | 'mint';

// Import IDs: projects by slug, environments by `project.slug`, branch
// configs by `project.environment.name`.
const _projects = [
    {
        slug: 'agent-runtime',
        description: 'AI agent runtime secrets',
        origin: 'mint',
    },
    {
        slug: 'parametric-forge',
        description: 'macOS machine and Home Manager toolchain secrets',
        origin: 'adopt',
    },
    { slug: 'maghz', description: 'Maghz VPS runtime secrets', origin: 'adopt' },
    {
        slug: 'rasm',
        description: 'Rasm repo and service secrets',
        origin: 'adopt',
    },
] as const satisfies ReadonlyArray<{
    readonly slug: string;
    readonly description: string;
    readonly origin: _Origin;
}>;

// API-minted projects carry zero environments, so agent-runtime's ride as
// mint rows; each environment creates its same-slug root config.
const _environments = [
    {
        project: 'agent-runtime',
        slug: 'dev',
        name: 'Development',
        origin: 'mint',
    },
    { project: 'agent-runtime', slug: 'stg', name: 'Staging', origin: 'mint' },
    { project: 'agent-runtime', slug: 'prd', name: 'Production', origin: 'mint' },
    {
        project: 'parametric-forge',
        slug: 'dev',
        name: 'Development',
        origin: 'adopt',
    },
    {
        project: 'parametric-forge',
        slug: 'stg',
        name: 'Staging',
        origin: 'adopt',
    },
    {
        project: 'parametric-forge',
        slug: 'prd',
        name: 'Production',
        origin: 'adopt',
    },
    { project: 'maghz', slug: 'dev', name: 'Development', origin: 'adopt' },
    { project: 'maghz', slug: 'stg', name: 'Staging', origin: 'adopt' },
    { project: 'maghz', slug: 'prd', name: 'Production', origin: 'adopt' },
    { project: 'rasm', slug: 'dev', name: 'Development', origin: 'adopt' },
    { project: 'rasm', slug: 'stg', name: 'Staging', origin: 'adopt' },
    { project: 'rasm', slug: 'prd', name: 'Production', origin: 'adopt' },
] as const satisfies ReadonlyArray<{
    readonly project: string;
    readonly slug: string;
    readonly name: string;
    readonly origin: _Origin;
}>;

// Branch configs only; root configs ride their environment. agent-runtime's
// secret set lives in its `dev` root config, so no branch row exists for it.
const _configs = [
    {
        project: 'parametric-forge',
        environment: 'dev',
        name: 'dev_machine',
        origin: 'adopt',
    },
    { project: 'maghz', environment: 'prd', name: 'prd_host', origin: 'adopt' },
    { project: 'rasm', environment: 'dev', name: 'dev_repo', origin: 'adopt' },
] as const satisfies ReadonlyArray<{
    readonly project: string;
    readonly environment: string;
    readonly name: string;
    readonly origin: _Origin;
}>;

// Static Developer-plan tokens; replacement is manual revoke-and-remint: drop
// the row and `up --target=<project>/<config>/<name>` (revokes), restore the
// row and target again (mints), then hand the fresh key off through 1Password.
const _tokens = [
    {
        project: 'agent-runtime',
        config: 'dev',
        name: 'agent-readonly',
        access: 'read',
    },
    {
        project: 'maghz',
        config: 'prd_host',
        name: 'maghz-host-readonly',
        access: 'read',
    },
] as const satisfies ReadonlyArray<{
    readonly project: string;
    readonly config: string;
    readonly name: string;
    readonly access: 'read' | 'read/write';
}>;

// Machine directory-scope rows: the replacement for every per-repo
// doppler.yaml, applied idempotently via `doppler configure set`.
const _scopeRoot = '/Users/bardiasamiee/Documents/99.Github';

const _scopes = [
    {
        dir: `${_scopeRoot}/Parametric_Forge`,
        project: 'parametric-forge',
        config: 'dev_machine',
    },
    { dir: `${_scopeRoot}/Maghz`, project: 'maghz', config: 'dev' },
    { dir: `${_scopeRoot}/Rasm`, project: 'rasm', config: 'dev_repo' },
] as const satisfies ReadonlyArray<{
    readonly dir: string;
    readonly project: string;
    readonly config: string;
}>;

// Change-notification webhooks: Doppler mandates HTTPS delivery and signs each
// delivery with the brokered secret (secretSource names the custody coordinate
// the driver resolves at apply time); no secret names ride the wire, delivery
// is at-least-once, and the consumer owns idempotency.
const _webhooks = [
    {
        project: 'maghz',
        slug: 'maghz-prd-redeploy',
        url: 'https://31-97-131-41.sslip.io/hooks/doppler',
        enabledConfigs: ['prd_host'],
        payload: JSON.stringify({ event: 'maghz.prd_host.secrets.update' }),
        secretSource: {
            project: 'maghz',
            config: 'prd_host',
            name: 'MAGHZ_HOOK__SIGNING_SECRET',
        },
        origin: 'mint',
    },
] as const satisfies ReadonlyArray<{
    readonly project: string;
    readonly slug: string;
    readonly url: string;
    readonly enabledConfigs: readonly string[];
    readonly payload: string;
    readonly secretSource: {
        readonly project: string;
        readonly config: string;
        readonly name: string;
    };
    readonly origin: _Origin;
}>;

// GitHub settings-as-code: every owned repo carries the shared merge-hygiene
// policy (estate.ts owns the values) and one active main-guard ruleset.
const _repositories = [
    {
        name: 'Parametric_Forge',
        description: 'My Nix based repo for NixOS/Darwin configuration, dotfiles, and more',
        origin: 'adopt',
    },
    {
        name: 'Rasm',
        description: 'AEC/design-geometry workspace',
        origin: 'adopt',
    },
    {
        name: 'Maghz',
        description: 'Agent-operated second brain infrastructure',
        origin: 'adopt',
    },
] as const satisfies ReadonlyArray<{
    readonly name: string;
    readonly description: string;
    readonly origin: _Origin;
}>;

// importId is the live ruleset ID; the adopt import ID is `<repository>:<importId>`.
const _rulesets = [
    {
        repository: 'Parametric_Forge',
        name: 'main-guard',
        importId: 18698897,
        origin: 'adopt',
    },
    {
        repository: 'Rasm',
        name: 'main-guard',
        importId: 18698898,
        origin: 'adopt',
    },
    {
        repository: 'Maghz',
        name: 'main-guard',
        importId: 18698899,
        origin: 'adopt',
    },
] as const satisfies ReadonlyArray<{
    readonly repository: string;
    readonly name: string;
    readonly importId: number;
    readonly origin: _Origin;
}>;

// One shared main-guard rule policy: history protection plus Copilot review as
// the GitHub-native ruleset rule; reviewOnPush stays off because CodeRabbit and
// Greptile already re-review each push. Direct pushes to main stay legal.
const _rulesetPolicy = {
    nonFastForward: true,
    deletion: true,
    copilotCodeReview: { reviewOnPush: false, reviewDraftPullRequests: false },
} as const;

// Reviewer service matrix: config custody stays repo-owned, `driver.ts
// reviewers` proves presence plus config hash; gated identities prove absence.
// Macroscope holds at gated until its check-run and fix policy are typed rows.
const _reviewers = [
    {
        identity: 'coderabbit',
        mechanism: 'app',
        posture: 'active',
        trigger: 'pr-open+push',
        statusCheck: true,
        overlapClass: 'line-review',
        artifacts: ['.coderabbit.yaml'],
    },
    {
        identity: 'greptile',
        mechanism: 'app',
        posture: 'active',
        trigger: 'pr-open+push',
        statusCheck: true,
        overlapClass: 'semantic-review',
        artifacts: ['.greptile/config.json', '.greptile/files.json', '.greptile/rules.md'],
    },
    {
        identity: 'copilot',
        mechanism: 'ruleset',
        posture: 'active',
        trigger: 'pr-open',
        statusCheck: false,
        overlapClass: 'native-review',
        artifacts: [],
    },
    {
        identity: 'macroscope',
        mechanism: 'app',
        posture: 'gated',
        trigger: 'pr-open',
        statusCheck: false,
        overlapClass: 'remediation',
        artifacts: [],
    },
] as const satisfies ReadonlyArray<{
    readonly identity: 'coderabbit' | 'greptile' | 'copilot' | 'macroscope';
    readonly mechanism: 'app' | 'ruleset';
    readonly posture: 'active' | 'gated';
    readonly trigger: string;
    readonly statusCheck: boolean;
    readonly overlapClass: 'line-review' | 'semantic-review' | 'native-review' | 'remediation';
    readonly artifacts: readonly string[];
}>;

const Topology = {
    projects: _projects,
    environments: _environments,
    configs: _configs,
    tokens: _tokens,
    scopeRoot: _scopeRoot,
    scopes: _scopes,
    webhooks: _webhooks,
    repositories: _repositories,
    rulesets: _rulesets,
    rulesetPolicy: _rulesetPolicy,
    reviewers: _reviewers,
} as const;

declare namespace Topology {
    type Origin = _Origin;
    type Project = (typeof _projects)[number];
    type Environment = (typeof _environments)[number];
    type Config = (typeof _configs)[number];
    type Token = (typeof _tokens)[number];
    type Scope = (typeof _scopes)[number];
    type Webhook = (typeof _webhooks)[number];
    type Repository = (typeof _repositories)[number];
    type Ruleset = (typeof _rulesets)[number];
    type RulesetPolicy = typeof _rulesetPolicy;
    type Reviewer = (typeof _reviewers)[number];
}

// --- [EXPORTS] -------------------------------------------------------------------------

export { Topology };
