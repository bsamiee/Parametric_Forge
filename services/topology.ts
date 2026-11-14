type _Origin = 'adopt' | 'mint';

const _DEV_AXIS = [{ slug: 'dev', name: 'Development' }] as const;

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

const _environments: ReadonlyArray<{
    readonly project: _ProjectSlug;
    readonly slug: _EnvironmentSlug;
    readonly name: string;
    readonly origin: _Origin;
}> = _projects.flatMap((project) =>
    project.environments.map((env) => ({ project: project.slug, slug: env.slug, name: env.name, origin: project.origin })),
);

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

const _configs = [
    {
        project: 'parametric-forge',
        environment: 'dev',
        name: 'dev_machine',
        origin: 'adopt',
    },
] as const satisfies ReadonlyArray<_BranchRow>;

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

const Topology = {
    projects: _projects,
    environments: _environments,
    configs: _configs,
    owner: _owner,
    repositories: _repositories,
} as const;

declare namespace Topology {
    type Origin = _Origin;
}

// --- [EXPORTS] -------------------------------------------------------------------------

export { Topology };
