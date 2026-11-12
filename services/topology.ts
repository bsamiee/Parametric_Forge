// Title         : topology.ts
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : services/topology.ts
// ----------------------------------------------------------------------------
// Forge's own external services as typed rows under one assembled owner: its Doppler projects and its GitHub repository, each row family a `const`
// projected onto the `Topology` object. program.ts materializes rows into resources. Every other repository owns its Doppler project and GitHub
// settings in its own IaC and names its Doppler project through a `DOPPLER_PROJECT` row of its own mise `[env]`. Every row is declared end-state,
// managed forever: an 'adopt' row imports live CLI/gh-born resources, a 'mint' row is created fresh and never carries an import ID. Cross-family
// coordinates derive from their anchors, so a row naming an undeclared project, environment, config, or repository is a compile error.

type _Origin = 'adopt' | 'mint';

// One development environment per project: every value here is read by the operator's own processes.
const _DEV_AXIS = [{ slug: 'dev', name: 'Development' }] as const;

// Import IDs: projects by slug, environments by `project.slug`, branch configs by `project.environment.name`.
const _projects = [
    {
        slug: 'parametric-forge',
        description: 'macOS machine and Home Manager toolchain secrets',
        origin: 'adopt',
        environments: _DEV_AXIS,
    },
] as const satisfies ReadonlyArray<{
    readonly slug: string;
    readonly description: string;
    readonly origin: _Origin;
    readonly environments: ReadonlyArray<{ readonly slug: string; readonly name: string }>;
}>;

type _ProjectSlug = (typeof _projects)[number]['slug'];

type _EnvironmentSlug<P extends _ProjectSlug = _ProjectSlug> = Extract<
    (typeof _projects)[number],
    { readonly slug: P }
>['environments'][number]['slug'];

// An environment's origin rides its project: API-minted projects mint their environments (each environment creates its same-slug root config),
// adopted projects adopt them.
const _environments: ReadonlyArray<{
    readonly project: _ProjectSlug;
    readonly slug: _EnvironmentSlug;
    readonly name: string;
    readonly origin: _Origin;
}> = _projects.flatMap((project) =>
    project.environments.map((env) => ({ project: project.slug, slug: env.slug, name: env.name, origin: project.origin })),
);

// Branch configs pair with a declared environment of their own project; Doppler naming law makes a branch name `<env>_<suffix>`.
type _BranchRow = {
    [P in _ProjectSlug]: {
        [E in _EnvironmentSlug<P>]: {
            readonly project: P;
            readonly environment: E;
            readonly name: `${E}_${string}`;
            readonly origin: _Origin;
        };
    }[_EnvironmentSlug<P>];
}[_ProjectSlug];

// Branch configs only; root configs ride their environment.
const _configs = [
    {
        project: 'parametric-forge',
        environment: 'dev',
        name: 'dev_machine',
        origin: 'adopt',
    },
] as const satisfies ReadonlyArray<_BranchRow>;

// A config coordinate resolves to a root config (same-slug as its environment) or a declared branch config of the same project.
type _ConfigName<P extends _ProjectSlug = _ProjectSlug> = _EnvironmentSlug<P> | Extract<(typeof _configs)[number], { readonly project: P }>['name'];

type _Coordinate = { [P in _ProjectSlug]: { readonly project: P; readonly config: _ConfigName<P> } }[_ProjectSlug];

// Static Developer-plan tokens with no origin: the provider imports no service token and reads no key after creation, so every row mints.
// Replacement is revoke-and-remint: drop the row and `up --target=<project>/<config>/<name>` (revokes), restore the row and target again
// (mints), then hand the fresh key off through 1Password.
// A read grant carries the `-readonly` name suffix as the naming law.
const _tokens: ReadonlyArray<
    _Coordinate & ({ readonly name: `${string}-readonly`; readonly access: 'read' } | { readonly name: string; readonly access: 'read/write' })
> = [];

// GitHub settings-as-code: every owned repo carries the shared merge-hygiene policy from program.ts; branch rulesets are removed, so main takes direct pushes.
const _owner = 'bsamiee';

const _repositories = [
    {
        name: 'Parametric_Forge',
        description: 'My Nix based repo for nix-darwin configuration, dotfiles, and more',
        origin: 'adopt',
    },
] as const satisfies ReadonlyArray<{
    readonly name: string;
    readonly description: string;
    readonly origin: _Origin;
}>;

type _RepositoryName = (typeof _repositories)[number]['name'];

type _RulesetRow = {
    readonly repository: _RepositoryName;
    readonly name: string;
    readonly importId: number;
    readonly origin: _Origin;
};

// Branch rulesets removed from every owned repository by decision: main takes direct pushes with no PR, force-push, or deletion guard. A new row restores one.
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

const Topology = {
    projects: _projects,
    environments: _environments,
    configs: _configs,
    tokens: _tokens,
    owner: _owner,
    repositories: _repositories,
    rulesets: _rulesets,
    rulesetPolicy: _rulesetPolicy,
} as const;

declare namespace Topology {
    type Origin = _Origin;
    type Project = (typeof _projects)[number];
    type Environment = (typeof _environments)[number];
    type Config = (typeof _configs)[number];
    type Token = (typeof _tokens)[number];
    type Repository = (typeof _repositories)[number];
    type Ruleset = _RulesetRow;
    type RulesetPolicy = typeof _rulesetPolicy;
}

// --- [EXPORTS] -------------------------------------------------------------------------

export { Topology };
