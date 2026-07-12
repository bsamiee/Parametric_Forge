// Title         : topology.ts
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : services/topology.ts
// ----------------------------------------------------------------------------
// Services estate as typed rows under one assembled owner: the Doppler topology and the GitHub settings surface, each row family a `const` projected
// onto the `Topology` object. estate.ts materializes rows into resources; driver.ts applies scope rows machine-side. Every row is declared end-state,
// managed forever: an 'adopt' row imports live CLI/gh-born resources, a 'mint' row is created fresh and never carries an import ID. Cross-family
// coordinates derive from their anchors, so a row naming an undeclared project, environment, config, or repository is a compile error.

type _Origin = 'adopt' | 'mint';

// Import IDs: projects by slug, environments by `project.slug`, branch configs by `project.environment.name`.
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

type _ProjectSlug = (typeof _projects)[number]['slug'];

// Every project carries the standard environment triple, and an environment's origin rides its project: API-minted projects mint their
// environments (each environment creates its same-slug root config), adopted projects adopt them.
const _ENV_AXIS = [
    { slug: 'dev', name: 'Development' },
    { slug: 'stg', name: 'Staging' },
    { slug: 'prd', name: 'Production' },
] as const;

type _EnvironmentSlug = (typeof _ENV_AXIS)[number]['slug'];

const _environments: ReadonlyArray<{
    readonly project: _ProjectSlug;
    readonly slug: _EnvironmentSlug;
    readonly name: (typeof _ENV_AXIS)[number]['name'];
    readonly origin: _Origin;
}> = _projects.flatMap((project) => _ENV_AXIS.map((env) => ({ project: project.slug, slug: env.slug, name: env.name, origin: project.origin })));

// Branch configs pair with a declared environment of their own project; Doppler naming law makes a branch name `<env>_<suffix>`.
type _BranchRow = {
    [P in _ProjectSlug]: {
        [E in _EnvironmentSlug]: {
            readonly project: P;
            readonly environment: E;
            readonly name: `${E}_${string}`;
            readonly origin: _Origin;
        };
    }[_EnvironmentSlug];
}[_ProjectSlug];

// Branch configs only; root configs ride their environment. agent-runtime keeps its secrets in the `dev` root config, so no branch row exists.
const _configs = [
    {
        project: 'parametric-forge',
        environment: 'dev',
        name: 'dev_machine',
        origin: 'adopt',
    },
    { project: 'maghz', environment: 'prd', name: 'prd_host', origin: 'adopt' },
    { project: 'rasm', environment: 'dev', name: 'dev_repo', origin: 'adopt' },
] as const satisfies ReadonlyArray<_BranchRow>;

// A config coordinate resolves to a root config (same-slug as its environment) or a declared branch config of the same project.
type _ConfigName<P extends _ProjectSlug = _ProjectSlug> = _EnvironmentSlug | Extract<(typeof _configs)[number], { readonly project: P }>['name'];

type _Coordinate = { [P in _ProjectSlug]: { readonly project: P; readonly config: _ConfigName<P> } }[_ProjectSlug];

// Static Developer-plan tokens; replacement is manual revoke-and-remint: drop the row and `up --target=<project>/<config>/<name>` (revokes),
// restore the row and target again (mints), then hand the fresh key off through 1Password.
// A read grant carries the `-readonly` name suffix as the naming law.
const _tokens = [
    {
        project: 'agent-runtime',
        config: 'dev',
        name: 'agent-readonly',
        access: 'read',
    },
    {
        project: 'parametric-forge',
        config: 'dev_machine',
        name: 'forge-machine-readonly',
        access: 'read',
    },
    {
        project: 'maghz',
        config: 'prd_host',
        name: 'maghz-host-readonly',
        access: 'read',
    },
] as const satisfies ReadonlyArray<
    _Coordinate & ({ readonly name: `${string}-readonly`; readonly access: 'read' } | { readonly name: string; readonly access: 'read/write' })
>;

// Machine directory-scope rows: the replacement for every per-repo doppler.yaml, applied idempotently via `doppler configure set`.
const _scopeRoot = '/Users/bardiasamiee/Documents/99.Github';

const _scopes = [
    {
        dir: `${_scopeRoot}/Parametric_Forge`,
        project: 'parametric-forge',
        config: 'dev_machine',
    },
    { dir: `${_scopeRoot}/Maghz`, project: 'maghz', config: 'dev' },
    { dir: `${_scopeRoot}/Rasm`, project: 'rasm', config: 'dev_repo' },
] as const satisfies ReadonlyArray<
    _Coordinate & {
        readonly dir: `${typeof _scopeRoot}/${string}`;
    }
>;

// Doppler mandates HTTPS delivery (the url type carries it) and signs each delivery with the brokered secret (secretSource
// names the custody coordinate the driver resolves at apply time); no secret names ride the wire, delivery
// is at-least-once, and the consumer owns idempotency. The payload event derives in estate.ts as
// `<project>.<firstEnabledConfig>.secrets.update`, and the provider ships no webhook import, so every row is mint by construction.
type _WebhookRow = {
    [P in _ProjectSlug]: {
        readonly project: P;
        readonly slug: string;
        readonly url: `https://${string}`;
        readonly enabledConfigs: readonly [_ConfigName<P>, ...ReadonlyArray<_ConfigName<P>>];
        readonly secretSource: _Coordinate & { readonly name: string };
        readonly origin: 'mint';
    };
}[_ProjectSlug];

const _webhooks = [
    {
        project: 'maghz',
        slug: 'maghz-prd-redeploy',
        url: 'https://31-97-131-41.sslip.io/hooks/doppler',
        enabledConfigs: ['prd_host'],
        secretSource: {
            project: 'maghz',
            config: 'prd_host',
            name: 'MAGHZ_HOOK__SIGNING_SECRET',
        },
        origin: 'mint',
    },
] as const satisfies ReadonlyArray<_WebhookRow>;

// GitHub settings-as-code: every owned repo carries the shared merge-hygiene policy from estate.ts; branch rulesets are removed, so main takes direct pushes.
const _owner = 'bsamiee';

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

type _RepositoryName = (typeof _repositories)[number]['name'];

type _AppRepositoryName = _RepositoryName | 'Parametric_Portal';

type _AppInstallationRow = {
    readonly identity: string;
    readonly installationId: number;
} & (
    | {
          readonly selectionMode: 'all';
          readonly origin: 'browser';
          readonly selectedRepositories?: never;
      }
    | {
          readonly selectionMode: 'selected';
          readonly selectedRepositories: readonly [_AppRepositoryName, ...ReadonlyArray<_AppRepositoryName>];
          readonly origin: 'browser';
      }
);

// Installation selection remains browser-custodied because Git transport identity cannot authenticate the REST mutation and no broad API token is
// admitted; a selected installation's nonempty repository tuple remains the complete intended grant and drift reference.
const _appInstallations = [
    {
        identity: 'ChatGPT Codex Connector',
        installationId: 67774119,
        selectionMode: 'all',
        origin: 'browser',
    },
    {
        identity: 'Claude',
        installationId: 93086152,
        selectionMode: 'all',
        origin: 'browser',
    },
    {
        identity: 'CodeRabbit',
        installationId: 110036864,
        selectionMode: 'all',
        origin: 'browser',
    },
    {
        identity: 'Google AI Studio',
        installationId: 95565745,
        selectionMode: 'all',
        origin: 'browser',
    },
    {
        identity: 'Greptile Apps',
        installationId: 103134796,
        selectionMode: 'all',
        origin: 'browser',
    },
    {
        identity: 'MacroscopeApp',
        installationId: 142885994,
        selectionMode: 'all',
        origin: 'browser',
    },
    {
        identity: 'Nx Cloud',
        installationId: 96791012,
        selectionMode: 'selected',
        selectedRepositories: ['Parametric_Portal', 'Rasm'],
        origin: 'browser',
    },
] as const satisfies ReadonlyArray<_AppInstallationRow>;

type _RulesetRow = {
    readonly repository: _RepositoryName;
    readonly name: string;
    readonly importId: number;
    readonly origin: _Origin;
};

// Branch rulesets removed estate-wide by decision: main takes direct pushes with no PR, force-push, or deletion guard. A new row restores one.
const _rulesets: ReadonlyArray<_RulesetRow> = [];

// Dormant ruleset policy retained for re-enablement only: no ruleset applies it while `_rulesets` is empty, and restoring a ruleset row reactivates it.
const _rulesetPolicy = {
    nonFastForward: true,
    deletion: true,
    requiredLinearHistory: true,
    pullRequest: {
        allowedMergeMethods: ['squash', 'rebase'] satisfies string[],
        dismissStaleReviewsOnPush: false,
        requireCodeOwnerReview: false,
        requireLastPushApproval: false,
        requiredApprovingReviewCount: 0,
        requiredReviewThreadResolution: true,
    },
    copilotCodeReview: { reviewOnPush: true, reviewDraftPullRequests: false },
} as const;

// Reviewer service matrix separates configuration custody from observed live execution. App IDs are the verified check-suite app identities, not
// installation IDs or required-check declarations; repo artifacts remain the local configuration receipt where a reviewer owns them.
const _reviewers = [
    {
        identity: 'coderabbit',
        mechanism: 'app',
        posture: 'active',
        configuration: 'repository-artifacts',
        liveEvidence: { source: 'check-suite', appId: 347564 },
        trigger: 'pr-open+push',
        statusCheck: true,
        overlapClass: 'line-review',
        artifacts: ['.coderabbit.yaml'],
    },
    {
        identity: 'greptile',
        mechanism: 'app',
        posture: 'active',
        configuration: 'repository-artifacts',
        liveEvidence: { source: 'check-suite', appId: 867647 },
        trigger: 'pr-open+push',
        statusCheck: true,
        overlapClass: 'semantic-review',
        artifacts: ['.greptile/config.json', '.greptile/files.json', '.greptile/rules.md'],
    },
    {
        identity: 'copilot',
        mechanism: 'ruleset',
        posture: 'active',
        configuration: 'ruleset-policy',
        liveEvidence: { source: 'ruleset-policy' },
        trigger: 'pr-open',
        statusCheck: false,
        overlapClass: 'native-review',
        artifacts: [],
    },
    {
        identity: 'macroscope',
        mechanism: 'app',
        posture: 'active',
        configuration: 'github-app',
        liveEvidence: { source: 'check-suite', appId: 900172 },
        trigger: 'pr-open',
        statusCheck: false,
        overlapClass: 'remediation',
        artifacts: [],
    },
] as const satisfies ReadonlyArray<{
    readonly identity: 'coderabbit' | 'greptile' | 'copilot' | 'macroscope';
    readonly mechanism: 'app' | 'ruleset';
    readonly posture: 'active';
    readonly configuration: 'repository-artifacts' | 'ruleset-policy' | 'github-app';
    readonly liveEvidence: { readonly source: 'check-suite'; readonly appId: 347564 | 867647 | 900172 } | { readonly source: 'ruleset-policy' };
    readonly trigger: 'pr-open' | 'pr-open+push';
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
    owner: _owner,
    repositories: _repositories,
    appInstallations: _appInstallations,
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
    type AppInstallation = (typeof _appInstallations)[number];
    type Ruleset = _RulesetRow;
    type RulesetPolicy = typeof _rulesetPolicy;
    type Reviewer = (typeof _reviewers)[number];
}

// --- [EXPORTS] -------------------------------------------------------------------------

export { Topology };
